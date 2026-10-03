# the swing equation is the same for every synchronous machine model, so the omega and delta steps
# work on any generator whose state stores omega, delta, Pmec and Pele

function predict_omega!(inputs::Inputs, generator::Generator, state::GeneratorState, ts::Int)
    # predict the next omega value using the Euler method
    state.omega[ts+1] =
        state.omega[ts] +
        integration_step(inputs) / (2 * generator_H(inputs, generator)) * (
            state.Pmec[ts] -
            state.Pele[ts] -
            generator_D(inputs, generator) * (
                state.omega[ts] - 1.0
            )
        )
    return nothing
end

function step_omega!(inputs::Inputs, generator::Generator, state::GeneratorState, ts::Int)
    # compute the next omega value using the trapezoidal rule
    state.omega[ts+1] =
        state.omega[ts] +
        integration_step(inputs) / (4 * generator_H(inputs, generator)) * (
            state.Pmec[ts] -
            state.Pele[ts] -
            generator_D(inputs, generator) * (
                state.omega[ts] - 1.0
            ) +
            state.Pmec[ts+1] -
            state.Pele[ts+1] -
            generator_D(inputs, generator) * (
                state.omega[ts+1] - 1.0
            )
        )
    return nothing
end

function predict_delta!(inputs::Inputs, state::GeneratorState, ts::Int)
    # predict the next delta value using the Euler method
    state.delta[ts+1] =
        state.delta[ts] +
        integration_step(inputs) * 2 * pi * fb(inputs) * (
            state.omega[ts] - 1.0
        )
    return nothing
end

function step_delta!(inputs::Inputs, state::GeneratorState, ts::Int)
    # compute the next delta value using the trapezoidal rule
    state.delta[ts+1] =
        state.delta[ts] +
        integration_step(inputs) * pi * fb(inputs) * (
            state.omega[ts] - 1.0 +
            state.omega[ts+1] - 1.0
        )
    return nothing
end

function electrical_power(
    inputs::Inputs,
    results::Results,
    generator::ClassicGenerator,
    state::ClassicGeneratorState,
    ts::Int,
)
    if generator_tripped(generator)
        return 0.0
    end
    bus_state = results.bus[generator_bus(generator)]
    V = bus_state.Vr[ts] + im * bus_state.Vi[ts]
    E = state.Eq_prime * cis(state.delta[ts])
    I = (E - V) * generator_admittance(inputs, generator)
    return real(conj(I) * E)
end
