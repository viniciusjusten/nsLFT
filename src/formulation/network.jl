function admittance(resistance::Float64, reactance::Float64)
    return 1 / (resistance + im * reactance)
end

function admittance_matrix(inputs::Inputs)
    n_buses = num_buses(inputs)

    Y = zeros(ComplexF64, n_buses, n_buses)
    for circuit_idx in 1:num_circuits(inputs)
        from = circuit_from_bus_idx(inputs, circuit_idx)
        to = circuit_to_bus_idx(inputs, circuit_idx)
        tap = circuit_tap_ratio(inputs, circuit_idx)
        y = admittance(circuit_resistance(inputs, circuit_idx), circuit_reactance(inputs, circuit_idx))
        # the circuit shunt is the total of the pi model, so each end gets half of it
        y_shunt = circuit_shunt_conductance(inputs, circuit_idx) + im * circuit_shunt_susceptance(inputs, circuit_idx)
        Y[from, from] += y * tap^2 + y_shunt / 2
        Y[to, to] += y + y_shunt / 2
        Y[from, to] -= y * tap
        Y[to, from] -= y * tap
    end

    for bus_idx in 1:n_buses
        Y[bus_idx, bus_idx] += im * bus_shunt_susceptance(inputs, bus_idx)
    end

    return Y
end

function solve_network!(inputs::Inputs, results::Results, ts::Int)
    # if there is no admittance matrix cached, compute and cache it
    if isempty(inputs.Ybus_cache)
        Ybus = admittance_matrix(inputs)
        # sum generators and loads to the diagonal of the admittance matrix
        for gen_idx in 1:num_generators(inputs)
            bus_idx = generator_bus(inputs, gen_idx)
            Ybus[bus_idx, bus_idx] += generator_admittance(inputs, gen_idx) # TODO change according to the generator model
        end
        for load_idx in 1:num_loads(inputs)
            bus_idx = load_bus(inputs, load_idx)
            Ybus[bus_idx, bus_idx] += load_admittance(inputs, load_idx)
        end
        inputs.Ybus_cache[ts] = Ybus
        inputs.Zbus_cache[ts] = inv(Ybus)
    end

    # TODO - check if current time step is at an event, and if so, update the admittance matrix
    # Ybus = admittance_matrix(inputs)

    # The current vector I only includes the E / Zg contributions from generators. Ig = (E - V) / Zg, and
    # V / Zg is already included in the Ybus matrix. Il = - V / Zl,
    # and the load contributions are already included in the Ybus matrix.
    I = zeros(ComplexF64, num_buses(inputs))
    for (gen_idx, gen) in enumerate(inputs.generators)
        bus_idx = generator_bus(inputs, gen_idx)
        delta = results.generator[gen_idx].delta[ts+1]
        E = results.generator[gen_idx].Eq_prime * cis(delta)
        I[bus_idx] += E * generator_admittance(inputs, gen_idx)
    end
    matrix_indices = sort(collect(keys(inputs.Ybus_cache)))
    matrix_idx = findlast(x -> x <= ts, matrix_indices)
    Zbus = inputs.Zbus_cache[matrix_indices[matrix_idx]]
    V = Zbus * I

    for bus_idx in 1:num_buses(inputs)
        results.bus[bus_idx].Vr[ts+1] = real(V[bus_idx])
        results.bus[bus_idx].Vi[ts+1] = imag(V[bus_idx])
    end

    for gen_idx in 1:num_generators(inputs)
        results.generator[gen_idx].Pele[ts+1] = electrical_power(inputs, results, gen_idx, ts+1)
    end

    return nothing
end
