abstract type Load end

mutable struct ConstantZLoad <: Load
    name::String
    bus::Int # index of the bus the load is connected to

    # Power flow solution
    P0::Float64 # active power at the bus voltage, in pu
    Q0::Float64 # reactive power at the bus voltage, in pu
end

function ConstantZLoad(;
    name::String,
    bus::Int,
    P0::Float64,
    Q0::Float64,
)
    return ConstantZLoad(name, bus, P0, Q0)
end

load_name(inputs, idx::Int) = inputs.loads[idx].name

load_bus(inputs, idx::Int) = inputs.loads[idx].bus

load_P0(inputs, idx::Int) = inputs.loads[idx].P0

load_Q0(inputs, idx::Int) = inputs.loads[idx].Q0

function load_admittance(inputs, idx::Int)
    # a constant admittance draws S = |V|^2 * conj(Y), so Y = conj(S) / |V|^2
    # evaluated at the power flow voltage magnitude of the load bus
    voltage = bus_voltage(inputs, load_bus(inputs, idx))
    return (load_P0(inputs, idx) - im * load_Q0(inputs, idx)) / voltage^2
end
