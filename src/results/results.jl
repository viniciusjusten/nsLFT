mutable struct Results
    generator::Vector{GeneratorState}
    bus::Vector{BusState}
end

function Results(inputs::Inputs)
    num_steps = num_time_steps(inputs) + 1

    generator_states = GeneratorState[generator_state(gen, num_steps) for gen in inputs.generators]
    bus_states = [BusState(num_steps) for _ in inputs.buses]

    return Results(generator_states, bus_states)
end

num_generators(results::Results) = length(results.generator)

num_buses(results::Results) = length(results.bus)
