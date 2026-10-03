function admittance(resistance::Float64, reactance::Float64)
    return 1 / (resistance + im * reactance)
end

# builds the admittance matrix from the current state of the elements, including generators and loads
function admittance_matrix(inputs::Inputs)
    n_buses = num_buses(inputs)

    # the matrix is assembled from (row, column, value) triplets, and sparse sums repeated positions.
    # Elements out of service still contribute zero values at their positions, so the sparsity pattern
    # never changes and the symbolic factorization of the LU stays valid after a perturbation
    rows = Int[]
    cols = Int[]
    values = ComplexF64[]
    for circuit_idx in 1:num_circuits(inputs)
        from = circuit_from_bus_idx(inputs, circuit_idx)
        to = circuit_to_bus_idx(inputs, circuit_idx)
        tap = circuit_tap_ratio(inputs, circuit_idx)
        y = 0.0 + 0.0im
        y_shunt = 0.0 + 0.0im
        if circuit_in_service(inputs, circuit_idx)
            y = admittance(circuit_resistance(inputs, circuit_idx), circuit_reactance(inputs, circuit_idx))
            # the circuit shunt is the total of the pi model, so each end gets half of it
            y_shunt = circuit_shunt_conductance(inputs, circuit_idx) + im * circuit_shunt_susceptance(inputs, circuit_idx)
        end
        append!(rows, [from, to, from, to])
        append!(cols, [from, to, to, from])
        append!(values, [y * tap^2 + y_shunt / 2, y + y_shunt / 2, -y * tap, -y * tap])
    end

    for bus_idx in 1:n_buses
        push!(rows, bus_idx)
        push!(cols, bus_idx)
        push!(values, im * bus_shunt_susceptance(inputs, bus_idx) + bus_fault_admittance(inputs, bus_idx))
    end

    for gen_idx in 1:num_generators(inputs)
        if !generator_tripped(inputs, gen_idx)
            bus_idx = generator_bus(inputs, gen_idx)
            push!(rows, bus_idx)
            push!(cols, bus_idx)
            push!(values, generator_admittance(inputs, gen_idx)) # TODO change according to the generator model
        end
    end

    for load_idx in 1:num_loads(inputs)
        bus_idx = load_bus(inputs, load_idx)
        push!(rows, bus_idx)
        push!(cols, bus_idx)
        push!(values, load_admittance(inputs, load_idx))
    end

    return sparse(rows, cols, values, n_buses, n_buses)
end

function initialize_Ybus!(inputs::Inputs)
    inputs.Ybus_cache = admittance_matrix(inputs)
    inputs.Ybus_lu = lu(inputs.Ybus_cache)
    return nothing
end

function cache_Ybus!(inputs::Inputs, ts::Int)
    # the perturbations only change the state of the elements, and the admittance matrix is rebuilt from that state
    current_perturbations = perturbations_at(inputs, ts)
    for perturbation in current_perturbations
        apply_perturbation!(inputs, perturbation)
    end
    if !isempty(current_perturbations)
        inputs.Ybus_cache = admittance_matrix(inputs)
        lu!(inputs.Ybus_lu, inputs.Ybus_cache)
    end

    return nothing
end

function solve_network!(inputs::Inputs, results::Results, ts::Int)
    # The current vector I only includes the E / Zg contributions from generators. Ig = (E - V) / Zg, and
    # V / Zg is already included in the Ybus matrix. Il = - V / Zl,
    # and the load contributions are already included in the Ybus matrix.
    I = zeros(ComplexF64, num_buses(inputs))
    for (gen_idx, gen) in enumerate(inputs.generators)
        if !generator_tripped(inputs, gen_idx)
            bus_idx = generator_bus(inputs, gen_idx)
            delta = results.generator[gen_idx].delta[ts+1]
            E = results.generator[gen_idx].Eq_prime * cis(delta)
            I[bus_idx] += E * generator_admittance(inputs, gen_idx)
        end
    end
    V = inputs.Ybus_lu \ I

    for bus_idx in 1:num_buses(inputs)
        results.bus[bus_idx].Vr[ts+1] = real(V[bus_idx])
        results.bus[bus_idx].Vi[ts+1] = imag(V[bus_idx])
    end

    for gen_idx in 1:num_generators(inputs)
        results.generator[gen_idx].Pele[ts+1] = electrical_power(inputs, results, gen_idx, ts+1)
    end

    return nothing
end
