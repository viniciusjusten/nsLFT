# Static 1st order voltage regulator model
function initialize_voltage_regulator!(inputs::Inputs, generator::Generator, voltage_regulator::Static1stOrder, state::GeneratorState)
    efd = state.efd[1]
    if !(efd >= voltage_regulator_Lmn(voltage_regulator) && efd <= voltage_regulator_Lmx(voltage_regulator))
        error("Initial field voltage (efd = $efd) is outside the limits of the voltage regulator (Lmn = $(voltage_regulator_Lmn(voltage_regulator)), Lmx = $(voltage_regulator_Lmx(voltage_regulator)))")
    end
    state.efdu[1] = efd
    state.Vref[1] = state.Vt[1] + efd / voltage_regulator_K(voltage_regulator)
    for ts in 2:length(state.Vref)
        state.Vref[ts] = state.Vref[1]
    end
    return nothing
end

# without a voltage regulator the field voltage stays at its initial value
function initialize_voltage_regulator!(inputs::Inputs, generator::ClassicGenerator, ::Nothing, state::GeneratorState)
    return nothing
end

function initialize_voltage_regulator!(inputs::Inputs, generator::OneDOneQGenerator, ::Nothing, state::GeneratorState)
    state.efdu[1] = state.efd[1]
    state.Vref .= state.Vt[1]
    return nothing
end

function initialize_voltage_regulators!(inputs::Inputs, results::Results)
    for (generator, state) in zip(inputs.generators, results.generator)
        initialize_voltage_regulator!(inputs, generator, generator_voltage_regulator(generator), state)
    end
    return nothing
end
