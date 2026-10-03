abstract type Generator end

mutable struct ClassicGenerator <: Generator
    name::String
    bus::Int # index of the bus the generator is connected to

    # Ratings
    Sn::Float64 # rated apparent power, in MVA
    Vn::Float64 # rated voltage, in kV

    # Electrical parameters
    Xd_prime::Float64 # direct axis transient reactance, in pu
    Ra::Float64 # armature resistance, in pu

    # Mechanical parameters
    H::Float64 # inertia constant, in seconds
    D::Float64 # damping coefficient, in pu

    # Power flow solution
    P0::Float64 # active power at the terminal, in pu
    Q0::Float64 # reactive power at the terminal, in pu

    # Cache
    tripped::Bool # indicates if the generator has been tripped
end

function ClassicGenerator(;
    name::String,
    bus::Int,
    Sn::Float64,
    Vn::Float64,
    Xd_prime::Float64,
    Ra::Float64,
    H::Float64,
    D::Float64,
    P0::Float64,
    Q0::Float64,
)
    return ClassicGenerator(
        name,
        bus,
        Sn,
        Vn,
        Xd_prime,
        Ra,
        H,
        D,
        P0,
        Q0,
        false,
    )
end

generator_name(inputs, idx::Int) = inputs.generators[idx].name

generator_bus(inputs, idx::Int) = inputs.generators[idx].bus

generator_Sn(inputs, idx::Int) = inputs.generators[idx].Sn

generator_Vn(inputs, idx::Int) = inputs.generators[idx].Vn

generator_Xd_prime(inputs, idx::Int) = inputs.generators[idx].Xd_prime * Sb(inputs) / generator_Sn(inputs, idx)

generator_Ra(inputs, idx::Int) = inputs.generators[idx].Ra * Sb(inputs) / generator_Sn(inputs, idx)

generator_H(inputs, idx::Int) = inputs.generators[idx].H * generator_Sn(inputs, idx) / Sb(inputs)

generator_D(inputs, idx::Int) = inputs.generators[idx].D * generator_Sn(inputs, idx) / Sb(inputs)

generator_P0(inputs, idx::Int) = inputs.generators[idx].P0

generator_Q0(inputs, idx::Int) = inputs.generators[idx].Q0

generator_tripped(inputs, idx::Int) = inputs.generators[idx].tripped

function generator_impedance(inputs, gen_idx::Int)
    return generator_Ra(inputs, gen_idx) + im * generator_Xd_prime(inputs, gen_idx)
end

function generator_admittance(inputs, gen_idx::Int)
    return 1 / generator_impedance(inputs, gen_idx)
end