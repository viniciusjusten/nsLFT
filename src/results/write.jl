function time_values(inputs::Inputs)
    return [ts * integration_step(inputs) for ts in 0:num_time_steps(inputs)]
end

function is_time_series(state, field::Symbol)
    if !hasfield(typeof(state), field)
        return false
    end
    return fieldtype(typeof(state), field) == Vector{Float64}
end

# collects the time series fields of all states, so element types with different models
# can share a file for the quantities they have in common
function time_series_fields(states::Vector)
    fields = Symbol[]
    for state in states
        for field in fieldnames(typeof(state))
            if is_time_series(state, field) && !(field in fields)
                push!(fields, field)
            end
        end
    end
    return fields
end

function write_csv(file_path::String, time::Vector{Float64}, column_names::Vector{String}, columns::Vector{Vector{Float64}})
    io = open(file_path, "w")
    try
        println(io, join(["time"; column_names], ","))
        for step in eachindex(time)
            row = [time[step]; [column[step] for column in columns]]
            println(io, join(row, ","))
        end
    finally
        close(io)
    end
    return nothing
end

function write_class_results(
    output_path::String,
    class_name::String,
    time::Vector{Float64},
    element_names::Vector{String},
    states::Vector,
)
    for field in time_series_fields(states)
        column_names = String[]
        columns = Vector{Float64}[]
        for (element_idx, state) in enumerate(states)
            if is_time_series(state, field)
                push!(column_names, element_names[element_idx])
                push!(columns, getfield(state, field))
            end
        end
        write_csv(joinpath(output_path, "$(class_name)_$(field).csv"), time, column_names, columns)
    end
    return nothing
end

function write_results(inputs::Inputs, results::Results, output_path::String = joinpath(case_path(inputs), "results"))
    mkpath(output_path)
    time = time_values(inputs)

    bus_names = [bus_name(inputs, bus_idx) for bus_idx in 1:num_buses(inputs)]
    write_class_results(output_path, "bus", time, bus_names, results.bus)

    generator_names = [generator_name(inputs, gen_idx) for gen_idx in 1:num_generators(inputs)]
    write_class_results(output_path, "generator", time, generator_names, results.generator)

    return nothing
end
