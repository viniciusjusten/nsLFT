abstract type GeneratorState end

mutable struct ClassicGeneratorState <: GeneratorState
    delta::Vector{Float64} # rotor angle, in rad
    omega::Vector{Float64} # rotor speed, in pu
    Pmec::Vector{Float64} # mechanical power, in pu
    Pele::Vector{Float64} # electrical power, in pu
    Eq_prime::Float64 # internal EMF magnitude, in pu
end

function ClassicGeneratorState(num_steps::Int)
    # NaN keeps a step not yet computed from passing a convergence check by accident
    # Eq_prime is set once initialization computes it
    return ClassicGeneratorState(
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        NaN,
    )
end

function generator_state(::ClassicGenerator, num_steps::Int)
    return ClassicGeneratorState(num_steps)
end
