# the generator model is "classic" or "one_d_one_q", and the same model is used for every generator of the case
function ieee14_generators(data_path::String, Sb::Float64, generator_model::String, gov::Bool = false)
    file_path = joinpath(data_path, "ieee14_generators.csv")
    generator_names = read_column(file_path, "name")
    generator_buses = read_integers(file_path, "bus")
    Sn = read_numbers(file_path, "Sbase_MVA")
    Xd_prime = read_numbers(file_path, "Xd1_pu")
    Ra = read_numbers(file_path, "Ra_pu")
    H = read_numbers(file_path, "H_s")
    D = read_numbers(file_path, "D_pu")
    P = read_numbers(file_path, "P_MW")
    Q = read_numbers(file_path, "Q_Mvar")

    generators = nsLFT.Generator[]
    if generator_model == "classic"
        for gen_idx in eachindex(generator_names)
            push!(generators, nsLFT.ClassicGenerator(;
                name = generator_names[gen_idx],
                bus = generator_buses[gen_idx],
                Sn = Sn[gen_idx],
                Vn = NaN, # the case gives no rated voltage and the model does not use it yet
                Xd_prime = Xd_prime[gen_idx],
                Ra = Ra[gen_idx],
                H = H[gen_idx],
                D = D[gen_idx],
                P0 = P[gen_idx] / Sb,
                Q0 = Q[gen_idx] / Sb,
            ))
        end
    elseif generator_model == "one_d_one_q"
        Xd = read_numbers(file_path, "Xd_pu")
        Xq = read_numbers(file_path, "Xq_pu")
        Xq_prime = read_numbers(file_path, "Xq1_pu")
        Td0_prime = read_numbers(file_path, "Td01_s")
        Tq0_prime = read_numbers(file_path, "Tq01_s")
        for gen_idx in eachindex(generator_names)
            push!(generators, nsLFT.OneDOneQGenerator(;
                name = generator_names[gen_idx],
                bus = generator_buses[gen_idx],
                Sn = Sn[gen_idx],
                Vn = NaN, # the case gives no rated voltage and the model does not use it yet
                Xd = Xd[gen_idx],
                Xd_prime = Xd_prime[gen_idx],
                Xq = Xq[gen_idx],
                Xq_prime = Xq_prime[gen_idx],
                Ra = Ra[gen_idx],
                Td0_prime = Td0_prime[gen_idx],
                Tq0_prime = Tq0_prime[gen_idx],
                H = H[gen_idx],
                D = D[gen_idx],
                P0 = P[gen_idx] / Sb,
                Q0 = Q[gen_idx] / Sb,
            ))
        end
    else
        error("Unknown generator model $generator_model.")
    end
    if gov
        for gen_idx in eachindex(generators)
            generators[gen_idx].governor = nsLFT.Droop1stOrder("gov", 0.05, 2.0, 60.0)
        end
    end
    return generators
end

function ieee14_loads(data_path::String, Sb::Float64)
    file_path = joinpath(data_path, "ieee14_loads.csv")
    load_names = read_column(file_path, "name")
    load_buses = read_integers(file_path, "bus")
    P = read_numbers(file_path, "P_MW")
    Q = read_numbers(file_path, "Q_Mvar")

    loads = nsLFT.Load[]
    for load_idx in eachindex(load_names)
        push!(loads, nsLFT.ConstantZLoad(;
            name = load_names[load_idx],
            bus = load_buses[load_idx],
            P0 = P[load_idx] / Sb,
            Q0 = Q[load_idx] / Sb,
        ))
    end
    return loads
end

function ieee14_buses(data_path::String, Sb::Float64)
    file_path = joinpath(data_path, "ieee14_buses.csv")
    bus_ids = read_integers(file_path, "bus_id")
    bus_names = read_column(file_path, "name")
    voltages = read_numbers(file_path, "V_pu")
    angles = read_numbers(file_path, "theta_deg")

    # the bus numbers are used directly as indices
    if bus_ids != collect(1:length(bus_ids))
        error("The buses must be numbered 1, 2, ..., n in order.")
    end

    generator_buses = read_integers(joinpath(data_path, "ieee14_generators.csv"), "bus")
    load_buses = read_integers(joinpath(data_path, "ieee14_loads.csv"), "bus")

    # the shunts are given by their reactive power at 1 pu, positive for a capacitor
    shunt_file_path = joinpath(data_path, "ieee14_shunts.csv")
    shunt_buses = read_integers(shunt_file_path, "bus")
    shunt_Q = read_numbers(shunt_file_path, "Q_Mvar_at_1pu")
    shunt_susceptances = zeros(length(bus_ids))
    for shunt_idx in eachindex(shunt_buses)
        shunt_susceptances[shunt_buses[shunt_idx]] += shunt_Q[shunt_idx] / Sb
    end

    buses = nsLFT.Bus[]
    for bus_idx in eachindex(bus_ids)
        push!(buses, nsLFT.Bus(;
            name = bus_names[bus_idx],
            voltage = voltages[bus_idx],
            angle = deg2rad(angles[bus_idx]),
            shunt_susceptance = shunt_susceptances[bus_idx],
            generator_idx = findfirst(==(bus_idx), generator_buses),
            load_idx = findfirst(==(bus_idx), load_buses),
        ))
    end
    return buses
end

function ieee14_circuits(data_path::String)
    file_path = joinpath(data_path, "ieee14_lines.csv")
    circuit_names = read_column(file_path, "name")
    circuit_types = read_column(file_path, "type")
    from_buses = read_integers(file_path, "from_bus")
    to_buses = read_integers(file_path, "to_bus")
    R = read_numbers(file_path, "R_pu")
    X = read_numbers(file_path, "X_pu")
    B = read_numbers(file_path, "B_pu")

    transformer_file_path = joinpath(data_path, "ieee14_transformers.csv")
    transformer_names = read_column(transformer_file_path, "name")
    transformer_taps = read_numbers(transformer_file_path, "tap_pu")

    circuits = nsLFT.Circuit[]
    for circuit_idx in eachindex(circuit_names)
        tap_ratio = 1.0
        if circuit_types[circuit_idx] == "transformer"
            # the tap a sits on the from side, so the series current is (V_from / a - V_to) / Z,
            # which in the admittance matrix of nsLFT means tap_ratio = 1 / a
            transformer_idx = findfirst(==(circuit_names[circuit_idx]), transformer_names)
            tap_ratio = 1.0 / transformer_taps[transformer_idx]
        end
        push!(circuits, nsLFT.Circuit(;
            name = circuit_names[circuit_idx],
            from_bus_idx = from_buses[circuit_idx],
            to_bus_idx = to_buses[circuit_idx],
            resistance = R[circuit_idx],
            reactance = X[circuit_idx],
            shunt_conductance = 0.0,
            shunt_susceptance = B[circuit_idx],
            tap_ratio = tap_ratio,
        ))
    end
    return circuits
end

# the case data is read from data_path and the results are written to case_path
function ieee14_inputs(
    data_path::String,
    case_path::String;
    perturbations::Vector{<:nsLFT.Perturbation} = nsLFT.Perturbation[],
    generator_model::String = "classic",
    gov::Bool = false,
)
    Sb = 100.0
    fb = 60.0
    return nsLFT.Inputs(;
        case_path = case_path,
        Sb = Sb,
        fb = fb,
        integration_step = 0.01,
        simulation_horizon = 10.0,
        tolerance = 1e-10,
        buses = ieee14_buses(data_path, Sb),
        circuits = ieee14_circuits(data_path),
        generators = ieee14_generators(data_path, Sb, generator_model, gov),
        loads = ieee14_loads(data_path, Sb),
        perturbations = perturbations,
    )
end

# perturbations = [nsLFT.ShortCircuit("curto-b14", 14, 1.0, 99999, 0), nsLFT.ShortCircuitRemoval("rm-curto-b14", 1, 1.2), nsLFT.CircuitTrip("trip-linha-b14-13", 17, 1.2)]
# inputs = ieee14_inputs("data/ieee14", "results/ieee14_classic-curto-b14-trip-linha-b14-13", perturbations = perturbations, generator_model = "classic")
# results = nsLFT.solve(inputs)

# perturbations = [nsLFT.GeneratorTrip(; name = "UG2 trip", generator_idx = 2, time = 1.0)]
# inputs = ieee14_inputs("data/ieee14", "results/ieee14_classic-trip-ug2", perturbations = perturbations, generator_model = "classic")
# results = nsLFT.solve(inputs)

# perturbations = [nsLFT.ShortCircuit("curto-b14", 14, 1.0, 99999, 0), nsLFT.ShortCircuitRemoval("rm-curto-b14", 1, 1.2), nsLFT.CircuitTrip("trip-linha-b14-13", 17, 1.2)]
# inputs = ieee14_inputs("data/ieee14", "results/ieee14_1d1q-curto-b14-trip-linha-b14-13", perturbations = perturbations, generator_model = "one_d_one_q")
# results = nsLFT.solve(inputs)

# perturbations = [nsLFT.GeneratorTrip(; name = "UG2 trip", generator_idx = 2, time = 1.0)]
# inputs = ieee14_inputs("data/ieee14", "results/ieee14_1d1q-trip-ug2", perturbations = perturbations, generator_model = "one_d_one_q")
# results = nsLFT.solve(inputs)

# perturbations = [nsLFT.ShortCircuit("curto-b14", 14, 1.0, 99999, 0), nsLFT.ShortCircuitRemoval("rm-curto-b14", 1, 1.2), nsLFT.CircuitTrip("trip-linha-b14-13", 17, 1.2)]
# inputs = ieee14_inputs("data/ieee14", "results/ieee14_1d1q-gov-curto-b14-trip-linha-b14-13", perturbations = perturbations, generator_model = "one_d_one_q", gov = true)
# results = nsLFT.solve(inputs)

# perturbations = [nsLFT.GeneratorTrip(; name = "UG2 trip", generator_idx = 2, time = 1.0)]
# inputs = ieee14_inputs("data/ieee14", "results/ieee14_1d1q-gov-trip-ug2", perturbations = perturbations, generator_model = "one_d_one_q", gov = true)
# results = nsLFT.solve(inputs)