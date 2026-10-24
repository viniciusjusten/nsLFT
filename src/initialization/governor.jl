function initialize_mechanical_power!(::Generator, state::GeneratorState)
    state.Pmec .= state.Pele[1]
    state.Pmec_1 .= state.Pele[1]
    return nothing
end

# Pref is chosen so that the mechanical power starts in steady state, dPmec_1/dt = 0 at t = 0,
# which gives Pref = Pmec_1 - (omega_ref - omega) / R
function initialize_reference_power!(inputs::Inputs, generator::Generator, governor::Droop1stOrder, state::GeneratorState)
    R = governor_R(inputs, generator, governor)
    omega_ref = governor_omega_ref(inputs, governor)
    state.Pref .= state.Pmec_1[1] - (omega_ref - state.omega[1]) / R
    return nothing
end

# without a governor the mechanical power stays at its reference
function initialize_reference_power!(::Inputs, ::Generator, ::Nothing, state::GeneratorState)
    state.Pref .= state.Pmec_1[1]
    return nothing
end

function initialize_mechanical_powers!(inputs::Inputs, results::Results)
    for (generator, state) in zip(inputs.generators, results.generator)
        initialize_mechanical_power!(generator, state)
        initialize_reference_power!(inputs, generator, generator_governor(generator), state)
    end
    return nothing
end
