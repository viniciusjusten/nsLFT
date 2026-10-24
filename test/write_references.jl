# Writes the reference trajectories of the IEEE 14 cases with perturbations from the current model.
# The tests never run this script. It is run by hand, only after a change that is meant to alter the results:
#   julia --project test/write_references.jl

using Test
using nsLFT

include(joinpath(@__DIR__, "..", "scripts", "read_csv.jl"))
include(joinpath(@__DIR__, "..", "scripts", "ieee14.jl"))
include(joinpath(@__DIR__, "trajectories.jl"))
include(joinpath(@__DIR__, "ieee14_perturbations.jl"))

# each case is the test folder, its perturbations, its generator model and whether it has governors
cases = [
    ("ieee14_ug2_trip", ieee14_ug2_trip_perturbations(), "classic", false),
    ("ieee14_short_circuit", ieee14_short_circuit_perturbations(), "classic", false),
    ("ieee14_one_d_one_q_ug2_trip", ieee14_ug2_trip_perturbations(), "one_d_one_q", false),
    ("ieee14_one_d_one_q_short_circuit", ieee14_short_circuit_perturbations(), "one_d_one_q", false),
    ("ieee14_one_d_one_q_governor_ug2_trip", ieee14_ug2_trip_perturbations(), "one_d_one_q", true),
    ("ieee14_one_d_one_q_governor_short_circuit", ieee14_short_circuit_perturbations(), "one_d_one_q", true),
]

for (case_name, perturbations, generator_model, gov) in cases
    case_path = joinpath(@__DIR__, case_name)
    inputs = ieee14_inputs(case_path; perturbations = perturbations, generator_model = generator_model, gov = gov)
    results = nsLFT.solve(inputs)

    trajectory_names, trajectories = model_trajectories(inputs, results)
    time = nsLFT.time_values(inputs)
    reference_path = joinpath(case_path, "reference")
    mkpath(reference_path)
    nsLFT.write_csv(joinpath(reference_path, "trajectories.csv"), time, trajectory_names, trajectories)
    println("Reference of $case_name written to $reference_path")
end
