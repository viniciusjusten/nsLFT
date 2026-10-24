# Static 1st order voltage regulator model
function initialize_voltage_regulator!(inputs::Inputs, generator::Generator, regulator::Static1stOrder, state::GeneratorState)
    Vt = bus_voltage(get_bus(inputs, generator_bus(generator)))
    state.Vt[1] = Vt
    state.efd[1] = clamp(state.efd[1], regulator_Lmn(regulator), regulator_Lmx(regulator))
    state.Vref[1] = Vt + state.efd[1] / regulator_K(regulator)
    for ts in 2:length(state.Vref)
        state.Vref[ts] = state.Vref[1]
    end
    return nothing
end

# without voltage regulator
function initialize_voltage_regulator!(inputs::Inputs, generator::Generator, ::Nothing, state::GeneratorState)
    return nothing
end

function initialize_voltage_regulators!(inputs::Inputs, results::Results)
    for (generator, state) in zip(inputs.generators, results.generator)
        initialize_voltage_regulator!(inputs, generator, generator_voltage_regulator(generator), state)
    end
    return nothing
end
