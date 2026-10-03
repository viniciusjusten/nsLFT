abstract type Load end

mutable struct ConstantZLoad <: Load
    name::String
    bus::Int # index of the bus the load is connected to

    # Power flow solution
    P0::Float64 # active power at the bus voltage, in pu
    Q0::Float64 # reactive power at the bus voltage, in pu

    # Cache
    P::Float64 # current active power at the power flow voltage of the bus, changed by load perturbations, in pu
    Q::Float64 # current reactive power at the power flow voltage of the bus, changed by load perturbations, in pu
end

function ConstantZLoad(;
    name::String,
    bus::Int,
    P0::Float64,
    Q0::Float64,
)
    return ConstantZLoad(name, bus, P0, Q0, P0, Q0)
end

load_name(load::Load) = load.name

load_bus(load::Load) = load.bus

load_P0(load::Load) = load.P0

load_Q0(load::Load) = load.Q0

load_P(load::Load) = load.P

load_Q(load::Load) = load.Q

function load_constant_admittance(P::Float64, Q::Float64, V::Float64)
    # a constant admittance draws S = |V|^2 * conj(Y), so Y = conj(S) / |V|^2
    return (P - im * Q) / V^2
end

function load_admittance(inputs, load::ConstantZLoad)
    # evaluated with the current powers at the power flow voltage magnitude of the load bus
    return load_constant_admittance(load_P(load), load_Q(load), bus_voltage(get_bus(inputs, load_bus(load))))
end
