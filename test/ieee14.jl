function read_column(file_path::String, column_name::String)
    lines = readlines(file_path)
    header = split(lines[1], ",")
    column_idx = findfirst(==(column_name), header)
    if column_idx === nothing
        error("Column $column_name not found in $file_path.")
    end

    values = String[]
    for line in lines[2:end]
        if isempty(strip(line))
            continue
        end
        push!(values, String(split(line, ",")[column_idx]))
    end
    return values
end

read_numbers(file_path::String, column_name::String) = parse.(Float64, read_column(file_path, column_name))

read_integers(file_path::String, column_name::String) = parse.(Int, read_column(file_path, column_name))

function ieee14_generators(case_path::String, Sb::Float64)
    file_path = joinpath(case_path, "ieee14_generators.csv")
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
    return generators
end

function ieee14_loads(case_path::String, Sb::Float64)
    file_path = joinpath(case_path, "ieee14_loads.csv")
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

function ieee14_buses(case_path::String, Sb::Float64)
    file_path = joinpath(case_path, "ieee14_buses.csv")
    bus_ids = read_integers(file_path, "bus_id")
    bus_names = read_column(file_path, "name")
    voltages = read_numbers(file_path, "V_pu")
    angles = read_numbers(file_path, "theta_deg")

    # the bus numbers are used directly as indices
    if bus_ids != collect(1:length(bus_ids))
        error("The buses must be numbered 1, 2, ..., n in order.")
    end

    generator_buses = read_integers(joinpath(case_path, "ieee14_generators.csv"), "bus")
    load_buses = read_integers(joinpath(case_path, "ieee14_loads.csv"), "bus")

    # the shunts are given by their reactive power at 1 pu, positive for a capacitor
    shunt_file_path = joinpath(case_path, "ieee14_shunts.csv")
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

function ieee14_circuits(case_path::String)
    file_path = joinpath(case_path, "ieee14_lines.csv")
    circuit_names = read_column(file_path, "name")
    circuit_types = read_column(file_path, "type")
    from_buses = read_integers(file_path, "from_bus")
    to_buses = read_integers(file_path, "to_bus")
    R = read_numbers(file_path, "R_pu")
    X = read_numbers(file_path, "X_pu")
    B = read_numbers(file_path, "B_pu")

    transformer_file_path = joinpath(case_path, "ieee14_transformers.csv")
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

function ieee14_inputs(case_path::String)
    Sb = 100.0
    fb = 60.0
    return nsLFT.Inputs(;
        case_path = case_path,
        Sb = Sb,
        fb = fb,
        integration_step = 0.01,
        simulation_horizon = 10.0,
        tolerance = 1e-10,
        buses = ieee14_buses(case_path, Sb),
        circuits = ieee14_circuits(case_path),
        generators = ieee14_generators(case_path, Sb),
        loads = ieee14_loads(case_path, Sb),
    )
end

@testset "IEEE 14 without perturbation" begin
    case_path = joinpath(@__DIR__, "ieee14")
    inputs = ieee14_inputs(case_path)
    results = nsLFT.solve(inputs)

    # the network solved at t = 0 with the initialized machines reproduces the power flow
    bus_file_path = joinpath(case_path, "ieee14_buses.csv")
    voltages = read_numbers(bus_file_path, "V_pu")
    angles = read_numbers(bus_file_path, "theta_deg")
    for bus_idx in 1:nsLFT.num_buses(inputs)
        V0 = results.bus[bus_idx].Vr[1] + im * results.bus[bus_idx].Vi[1]
        @test abs(V0) ≈ voltages[bus_idx] atol = 1e-6
        @test rad2deg(angle(V0)) ≈ angles[bus_idx] atol = 1e-5
    end

    # rotor angles at t = 0, in degrees, from the PowerDynamics.jl simulation of the same case,
    # in the order of ieee14_generators.csv
    delta0_powerdynamics = [
        20.942285984420202,
        1.4641342940804398,
        -15.68089487965635,
        -18.92899192122492,
        -16.520651677707935,
    ]
    active_powers = read_numbers(joinpath(case_path, "ieee14_generators.csv"), "P_MW")
    for gen_idx in 1:nsLFT.num_generators(inputs)
        state = results.generator[gen_idx]
        @test state.Pele[1] * nsLFT.Sb(inputs) ≈ active_powers[gen_idx] atol = 1e-4
        @test rad2deg(state.delta[1]) ≈ delta0_powerdynamics[gen_idx] atol = 1e-5
    end

    # without a perturbation every state and voltage stays at its initial value
    for state in results.generator
        @test maximum(abs.(state.delta .- state.delta[1])) < 1e-8
        @test maximum(abs.(state.omega .- 1.0)) < 1e-8
    end
    for state in results.bus
        @test maximum(abs.(state.Vr .- state.Vr[1])) < 1e-8
        @test maximum(abs.(state.Vi .- state.Vi[1])) < 1e-8
    end
end
