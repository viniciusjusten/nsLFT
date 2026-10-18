@testset "IEEE 14 without perturbation" begin
    data_path = joinpath(@__DIR__, "..", "..", "data", "ieee14")
    inputs = ieee14_inputs(data_path, @__DIR__)
    results = nsLFT.solve(inputs)

    # without a perturbation the system stays at its initial operating point, so every time step
    # of every trajectory is compared with the reference values of the case

    # the network solved with the initialized machines reproduces the power flow
    bus_file_path = joinpath(data_path, "ieee14_buses.csv")
    voltages = read_numbers(bus_file_path, "V_pu")
    angles = read_numbers(bus_file_path, "theta_deg")
    for bus_idx in 1:nsLFT.num_buses(inputs)
        state = results.bus[bus_idx]
        V = state.Vr .+ im .* state.Vi
        voltage_errors = abs.(abs.(V) .- voltages[bus_idx])
        angle_errors = abs.(rad2deg.(angle.(V)) .- angles[bus_idx])
        @test maximum(voltage_errors) < 1e-6
        @test maximum(angle_errors) < 1e-5
    end

    # rotor angles, in degrees, from the PowerDynamics.jl simulation of the same case,
    # in the order of ieee14_generators.csv
    delta0_powerdynamics = [
        20.942285984420202,
        1.4641342940804398,
        -15.68089487965635,
        -18.92899192122492,
        -16.520651677707935,
    ]
    active_powers = read_numbers(joinpath(data_path, "ieee14_generators.csv"), "P_MW")
    for gen_idx in 1:nsLFT.num_generators(inputs)
        state = results.generator[gen_idx]
        Pele_errors = abs.(state.Pele .* nsLFT.Sb(inputs) .- active_powers[gen_idx])
        Pmec_errors = abs.(state.Pmec .* nsLFT.Sb(inputs) .- active_powers[gen_idx])
        delta_errors = abs.(rad2deg.(state.delta) .- delta0_powerdynamics[gen_idx])
        omega_errors = abs.(state.omega .- 1.0)
        @test maximum(Pele_errors) < 1e-4
        @test maximum(Pmec_errors) < 1e-4
        @test maximum(delta_errors) < 1e-5
        @test maximum(omega_errors) < 1e-8
    end
end
