@testset "IEEE 14 without perturbation" begin
    data_path = joinpath(@__DIR__, "..", "..", "data", "ieee14")
    inputs = ieee14_inputs(data_path, @__DIR__)
    results = nsLFT.solve(inputs)

    # the network solved at t = 0 with the initialized machines reproduces the power flow
    bus_file_path = joinpath(data_path, "ieee14_buses.csv")
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
    active_powers = read_numbers(joinpath(data_path, "ieee14_generators.csv"), "P_MW")
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
