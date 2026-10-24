# Static 1st order voltage regulator model
function deriv_efd(inputs::Inputs, generator::Generator, voltage_regulator::Static1stOrder, state::GeneratorState, ts::Int)
    return 1 / voltage_regulator_T(inputs, generator, voltage_regulator) * (
        voltage_regulator_K(inputs, generator, voltage_regulator) *
        (voltage_regulator_Vref(inputs, generator, voltage_regulator) - state.Vt[ts]) -
        state.efd[ts]
    )
end

function clamp_efd!(inputs::Inputs, generator::Generator, voltage_regulator::Static1stOrder, state::GeneratorState, ts::Int)
    state.efd[ts] = clamp(
        state.efd[ts],
        voltage_regulator_Lmn(inputs, generator, voltage_regulator),
        voltage_regulator_Lmx(inputs, generator, voltage_regulator)
    )
    return nothing
end

function predict_efd!(inputs::Inputs, generator::Generator, voltage_regulator::Static1stOrder, state::GeneratorState, ts::Int)
    # predict the next efd value using the Euler method
    state.efd[ts+1] =
        state.efd[ts] +
        integration_step(inputs) * deriv_efd(inputs, generator, voltage_regulator, state, ts)
    clamp_efd!(inputs, generator, voltage_regulator, state, ts+1)
    return nothing
end

function step_efd!(inputs::Inputs, generator::Generator, voltage_regulator::Static1stOrder, state::GeneratorState, ts::Int)
    # compute the next efd value using the trapezoidal rule
    state.efd[ts+1] =
        state.efd[ts] +
        integration_step(inputs) / 2 * (
            deriv_efd(inputs, generator, voltage_regulator, state, ts) +
            deriv_efd(inputs, generator, voltage_regulator, state, ts+1)
        )
    clamp_efd!(inputs, generator, voltage_regulator, state, ts+1)
    return nothing
end

# without a voltage regulator the field voltage stays constant
function predict_efd!(::Inputs, ::ClassicGenerator, ::Nothing, state::GeneratorState, ts::Int)
    return nothing
end

function step_efd!(::Inputs, ::ClassicGenerator, ::Nothing, state::GeneratorState, ts::Int)
    return nothing
end

function predict_efd!(::Inputs, ::OneDOneQGenerator, ::Nothing, state::GeneratorState, ts::Int)
    state.efd[ts+1] = state.efd[ts]
    return nothing
end

function step_efd!(::Inputs, ::OneDOneQGenerator, ::Nothing, state::GeneratorState, ts::Int)
    state.efd[ts+1] = state.efd[ts]
    return nothing
end

# terminal voltage of the generator is the voltage at the bus to which it is connected
function update_terminal_voltage!(inputs::Inputs, generator::Generator, results::Results, ts::Int)
    bus_idx = generator_bus(generator)
    Vr = results.bus[bus_idx].Vr[ts+1]
    Vi = results.bus[bus_idx].Vi[ts+1]
    gen_idx = findfirst(isequal(generator), inputs.generators)
    results.generator[gen_idx].Vt[ts+1] = sqrt(Vr^2 + Vi^2)
    return nothing
end
