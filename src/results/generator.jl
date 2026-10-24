abstract type GeneratorState end

mutable struct ClassicGeneratorState <: GeneratorState
    delta::Vector{Float64} # rotor angle, in rad
    omega::Vector{Float64} # rotor speed, in pu
    Pmec_1::Vector{Float64} # mechanical power after the regulator and valves, in pu
    Pmec::Vector{Float64} # mechanical power after the reheater (final Pmec), in pu
    Pref::Vector{Float64} # reference power of the governor, in pu
    Pele::Vector{Float64} # electrical power, in pu
    Eq_prime::Float64 # internal EMF magnitude, in pu
    id::Vector{Float64} # stator current along the d-axis, in pu
    iq::Vector{Float64} # stator current along the q-axis, in pu
    Vt::Vector{Float64} # terminal voltage, in pu
end

function ClassicGeneratorState(num_steps::Int)
    # NaN keeps a step not yet computed from passing a convergence check by accident
    # Eq_prime is set once initialization computes it
    return ClassicGeneratorState(
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        NaN,
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
    )
end

function generator_state(::ClassicGenerator, num_steps::Int)
    return ClassicGeneratorState(num_steps)
end

mutable struct OneDOneQGeneratorState <: GeneratorState
    delta::Vector{Float64} # rotor angle, in rad
    omega::Vector{Float64} # rotor speed, in pu
    Pmec_1::Vector{Float64} # mechanical power after the regulator and valves, in pu
    Pmec::Vector{Float64} # mechanical power after the reheater (final Pmec), in pu
    Pref::Vector{Float64} # reference power of the governor, in pu
    Pele::Vector{Float64} # electrical power, in pu
    ed_prime::Vector{Float64} # internal EMF along the d-axis, in pu
    eq_prime::Vector{Float64} # internal EMF along the q-axis, in pu
    id::Vector{Float64} # stator current along the d-axis, in pu
    iq::Vector{Float64} # stator current along the q-axis, in pu
    efd::Vector{Float64} # excitation voltage, in pu
    efdu::Vector{Float64} # excitation voltage before the limiter, in pu
    Vt::Vector{Float64} # terminal voltage, in pu
    Vref::Vector{Float64} # reference voltage of the voltage regulator, in pu
end

function OneDOneQGeneratorState(num_steps::Int)
    # NaN keeps a step not yet computed from passing a convergence check by accident
    return OneDOneQGeneratorState(
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
        fill(NaN, num_steps),
    )
end

function generator_state(::OneDOneQGenerator, num_steps::Int)
    return OneDOneQGeneratorState(num_steps)
end
