@testset "IEEE 14 with one d one q generators, governors, voltage regulators and UG2 trip" begin
    trip_time = 1.0
    inputs = ieee14_inputs(
        @__DIR__;
        perturbations = ieee14_ug2_trip_perturbations(),
        generator_model = "one_d_one_q",
        gov = true,
        avr = true,
    )
    results = nsLFT.solve(inputs)

    # every trajectory matches the one stored in the reference file
    test_trajectories(inputs, results, joinpath(@__DIR__, "reference", "trajectories.csv"))

    # before the trip the system stays at its initial operating point, since the reference power of each governor
    # and the reference voltage of each regulator are initialized at the power flow solution
    test_initial_operating_point_kept(inputs, results, trip_time)

    # the reference power and the reference voltage are setpoints, so they stay constant during the whole simulation
    for state in results.generator
        @test all(state.Pref .== state.Pref[1])
        @test all(state.Vref .== state.Vref[1])
    end

    # UG3, UG6 and UG8 are synchronous condensers without governor, so their mechanical power stays constant
    for gen_idx in (3, 4, 5)
        generator = nsLFT.get_generator(inputs, gen_idx)
        state = results.generator[gen_idx]
        @test !nsLFT.has_governor(generator)
        @test all(state.Pmec .== state.Pmec[1])
    end

    # after the trip the governor of UG1 moves its mechanical power against the speed deviation, as the droop requires
    ug1 = results.generator[1]
    @test nsLFT.has_governor(nsLFT.get_generator(inputs, 1))
    @test ug1.Pmec[end] != ug1.Pmec[1]
    @test (ug1.Pmec[end] - ug1.Pmec[1]) * (ug1.omega[end] - 1.0) < 0.0

    # every machine has a voltage regulator, including the synchronous condensers UG3, UG6 and UG8, and the field
    # voltage is the limited output of the lag at every instant
    for (generator, state) in zip(inputs.generators, results.generator)
        @test nsLFT.has_voltage_regulator(generator)
        voltage_regulator = nsLFT.generator_voltage_regulator(generator)
        Lmn = nsLFT.voltage_regulator_Lmn(voltage_regulator)
        Lmx = nsLFT.voltage_regulator_Lmx(voltage_regulator)
        limited_efdu = clamp.(state.efdu, Lmn, Lmx)
        @test all(state.efd .== limited_efdu)
    end

    # UG2 supplied reactive power before the trip, so the terminal voltages of the machines left in service drop and
    # their regulators end with a higher field voltage to make up for it
    for gen_idx in (1, 3, 4, 5)
        state = results.generator[gen_idx]
        @test minimum(state.Vt) < state.Vt[1]
        @test state.efd[end] > state.efd[1]
    end
end
