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

mutable struct OneDOneQGenerator <: Generator
    name::String
    bus::Int # index of the bus the generator is connected to

    # Ratings
    Sn::Float64 # rated apparent power, in MVA
    Vn::Float64 # rated voltage, in kV

    # Electrical parameters
    Xd::Float64 # direct axis permanent reactance, in pu
    Xd_prime::Float64 # direct axis transient reactance, in pu
    Xq::Float64 # quadrature axis permanent reactance, in pu
    Xq_prime::Float64 # quadrature axis transient reactance, in pu
    Ra::Float64 # armature resistance, in pu

    # Delay parameters
    Td0_prime::Float64 # direct axis open circuit transient time constant, in seconds
    Tq0_prime::Float64 # quadrature axis open circuit transient time constant, in seconds

    # Mechanical parameters
    H::Float64 # inertia constant, in seconds
    D::Float64 # damping coefficient, in pu

    # Power flow solution
    P0::Float64 # active power at the terminal, in pu
    Q0::Float64 # reactive power at the terminal, in pu

    # Cache
    tripped::Bool # indicates if the generator has been tripped
end

generator_name(generator::Generator) = generator.name

generator_bus(generator::Generator) = generator.bus

generator_Sn(generator::Generator) = generator.Sn

generator_Vn(generator::Generator) = generator.Vn

# the parameters are given in the machine base and returned in the system base
generator_Xd(inputs, generator::OneDOneQGenerator) = generator.Xd * Sb(inputs) / generator_Sn(generator)

generator_Xd_prime(inputs, generator::Generator) = generator.Xd_prime * Sb(inputs) / generator_Sn(generator)

generator_Xq(inputs, generator::OneDOneQGenerator) = generator.Xq * Sb(inputs) / generator_Sn(generator)

generator_Xq_prime(inputs, generator::OneDOneQGenerator) = generator.Xq_prime * Sb(inputs) / generator_Sn(generator)

generator_Ra(inputs, generator::Generator) = generator.Ra * Sb(inputs) / generator_Sn(generator)

generator_Td0_prime(generator::OneDOneQGenerator) = generator.Td0_prime

generator_Tq0_prime(generator::OneDOneQGenerator) = generator.Tq0_prime

generator_H(inputs, generator::Generator) = generator.H * generator_Sn(generator) / Sb(inputs)

generator_D(inputs, generator::Generator) = generator.D * generator_Sn(generator) / Sb(inputs)

generator_P0(generator::Generator) = generator.P0

generator_Q0(generator::Generator) = generator.Q0

generator_tripped(generator::Generator) = generator.tripped

function generator_impedance(inputs, generator::ClassicGenerator)
    return generator_Ra(inputs, generator) + im * generator_Xd_prime(inputs, generator)
end

function generator_admittance(inputs, generator::ClassicGenerator)
    return 1 / generator_impedance(inputs, generator)
end

function generator_impedance(inputs, generator::OneDOneQGenerator)
    # The one q one d generator has a fictitious impedance to add to the Ybus matrix and to the generator's current injection
    # In the end of the day, this impedance is added equally to Y * V and to I, so this is only a mathematical trick to make the system of equations solvable
    return generator_Ra(inputs, generator) + im * (generator_Xd_prime(inputs, generator) + generator_Xq_prime(inputs, generator))
end

function generator_admittance(inputs, generator::OneDOneQGenerator)
    return 1 / generator_impedance(inputs, generator)
end
