function deriv_Pmec(inputs::Inputs, generator::Generator, governor::Droop1stOrder, state::GeneratorState, ts::Int)
    R = governor_R(inputs, generator, governor)
    omega_ref = governor_omega_ref(inputs, governor)
    return 1 / governor_T(governor) * (
        state.Pref[ts] +
        (omega_ref - state.omega[ts]) / R -
        state.Pmec[ts]
    )
end

function predict_Pmec!(inputs::Inputs, generator::Generator, governor::Droop1stOrder, state::GeneratorState, ts::Int)
    # predict the next Pmec value using the Euler method
    state.Pmec[ts+1] =
        state.Pmec[ts] +
        integration_step(inputs) * deriv_Pmec(inputs, generator, governor, state, ts)
    return nothing
end

function step_Pmec!(inputs::Inputs, generator::Generator, governor::Droop1stOrder, state::GeneratorState, ts::Int)
    # compute the next Pmec value using the trapezoidal rule
    state.Pmec[ts+1] =
        state.Pmec[ts] +
        integration_step(inputs) / 2 * (
            deriv_Pmec(inputs, generator, governor, state, ts) +
            deriv_Pmec(inputs, generator, governor, state, ts+1)
        )
    return nothing
end

# without a governor the mechanical power stays constant
function predict_Pmec!(::Inputs, ::Generator, ::Nothing, state::GeneratorState, ts::Int)
    state.Pmec[ts+1] = state.Pmec[ts]
    return nothing
end

function step_Pmec!(::Inputs, ::Generator, ::Nothing, state::GeneratorState, ts::Int)
    state.Pmec[ts+1] = state.Pmec[ts]
    return nothing
end
