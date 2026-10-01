function initialize_generator!(inputs::Inputs, results::Results, gen_idx::Int, ::ClassicGenerator)
    state = results.generator[gen_idx]

    bus_idx = generator_bus(inputs, gen_idx)
    V0 = bus_voltage(inputs, bus_idx) * cis(bus_angle(inputs, bus_idx))
    S0 = generator_P0(inputs, gen_idx) + im * generator_Q0(inputs, gen_idx)
    I0 = conj(S0 / V0)
    E = V0 + (generator_Ra(inputs, gen_idx) + im * generator_Xd_prime(inputs, gen_idx)) * I0

    state.Eq_prime = abs(E)
    state.delta[1] = angle(E)
    state.omega[1] = 1.0

    return nothing
end

function initialize_generators!(inputs::Inputs, results::Results)
    for gen_idx in 1:num_generators(inputs)
        initialize_generator!(inputs, results, gen_idx, generator(inputs, gen_idx))
    end
    return nothing
end

function initialize_mechanical_power!(inputs::Inputs, results::Results, gen_idx::Int, ::ClassicGenerator)
    state = results.generator[gen_idx]
    # without a governor the mechanical power stays at the value that balances the initial electrical power
    state.Pmec .= state.Pele[1]
    return nothing
end

function initialize_mechanical_powers!(inputs::Inputs, results::Results)
    for gen_idx in 1:num_generators(inputs)
        initialize_mechanical_power!(inputs, results, gen_idx, generator(inputs, gen_idx))
    end
    return nothing
end
