function initialize_generator!(inputs::Inputs, generator::ClassicGenerator, state::ClassicGeneratorState)
    bus = get_bus(inputs, generator_bus(generator))
    V0 = bus_voltage(bus) * cis(bus_angle(bus))
    S0 = generator_P0(generator) + im * generator_Q0(generator)
    I0 = conj(S0 / V0)
    E = V0 + generator_impedance(inputs, generator) * I0

    state.Eq_prime = abs(E)
    state.delta[1] = angle(E)
    state.omega[1] = 1.0

    return nothing
end

function initialize_generators!(inputs::Inputs, results::Results)
    for (generator, state) in zip(inputs.generators, results.generator)
        initialize_generator!(inputs, generator, state)
    end
    return nothing
end

function initialize_mechanical_power!(::ClassicGenerator, state::ClassicGeneratorState)
    # without a governor the mechanical power stays at the value that balances the initial electrical power
    state.Pmec .= state.Pele[1]
    return nothing
end

function initialize_mechanical_powers!(inputs::Inputs, results::Results)
    for (generator, state) in zip(inputs.generators, results.generator)
        initialize_mechanical_power!(generator, state)
    end
    return nothing
end
