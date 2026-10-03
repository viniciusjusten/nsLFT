using Test
using nsLFT

include(joinpath(@__DIR__, "..", "scripts", "read_csv.jl"))
include(joinpath(@__DIR__, "..", "scripts", "ieee14.jl"))

@testset "nsLFT" begin
    include(joinpath("ieee14_no_perturbation", "ieee14.jl"))
    include(joinpath("ieee14_ug2_trip", "ieee14.jl"))
end
