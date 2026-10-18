# The reference trajectories are fixed CSV files kept in the repository. The tests only read them and never
# write them, so a reference changes only when it is replaced outside the model after an intended change.

# The largest absolute difference accepted between a trajectory and its reference. It sits above the
# convergence tolerance of the corrector, so a reordering of the floating point operations does not fail the test
trajectory_tolerance() = 1e-8

function add_state_trajectories!(
    column_names::Vector{String},
    columns::Vector{Vector{Float64}},
    class_name::String,
    element_name::String,
    state,
)
    for field in fieldnames(typeof(state))
        if nsLFT.is_time_series(state, field)
            push!(column_names, "$(class_name)_$(element_name)_$(field)")
            push!(columns, getfield(state, field))
        end
    end
    return nothing
end

# The trajectories of every time series stored in the generator and bus states,
# named as class_element_field, for example generator_UG1_delta
function model_trajectories(inputs::nsLFT.Inputs, results::nsLFT.Results)
    column_names = String[]
    columns = Vector{Float64}[]
    for (generator, state) in zip(inputs.generators, results.generator)
        generator_name = nsLFT.generator_name(generator)
        add_state_trajectories!(column_names, columns, "generator", generator_name, state)
    end
    for (bus, state) in zip(inputs.buses, results.bus)
        bus_name = nsLFT.bus_name(bus)
        add_state_trajectories!(column_names, columns, "bus", bus_name, state)
    end
    return column_names, columns
end

function reference_trajectories(reference_trajectories_path::String)
    header_line = readline(reference_trajectories_path)
    header = split(header_line, ",")
    column_names = String[]
    columns = Vector{Float64}[]
    for column_name in header
        push!(column_names, String(column_name))
        push!(columns, read_numbers(reference_trajectories_path, String(column_name)))
    end
    return column_names, columns
end

function test_trajectories(inputs::nsLFT.Inputs, results::nsLFT.Results, reference_trajectories_path::String)
    # the model trajectories come from the simulation results and the reference trajectories from the fixed CSV file
    model_time = nsLFT.time_values(inputs)
    model_names, model_columns = model_trajectories(inputs, results)
    reference_names, reference_columns = reference_trajectories(reference_trajectories_path)

    # the reference has the time followed by exactly the trajectories the model produces
    for hdr in reference_names
        @test hdr in ["time_s"; model_names]
    end
    @test reference_columns[1] ≈ model_time

    for (trajectory_name, model_trajectory) in zip(model_names, model_columns)
        reference_idx = findfirst(==(trajectory_name), reference_names)
        if reference_idx === nothing
            continue
        end
        reference_trajectory = reference_columns[reference_idx]
        @testset "$trajectory_name" begin
            @test length(model_trajectory) == length(reference_trajectory)
            if length(model_trajectory) == length(reference_trajectory)
                max_difference = maximum(abs.(model_trajectory .- reference_trajectory))
                @test max_difference < trajectory_tolerance()
            end
        end
    end
    return nothing
end
