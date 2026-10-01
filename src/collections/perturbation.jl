abstract type Perturbation end

mutable struct ShortCircuit <: Perturbation
    name::String
    bus_idx::Int # index of the bus where the fault is applied

    time::Float64 # instant the fault is applied, in s
    clearing_time::Float64 # instant the fault is cleared, in s

    fault_conductance::Float64 # shunt conductance added during the fault, in pu
    fault_susceptance::Float64 # shunt susceptance added during the fault, in pu
end

function ShortCircuit(;
    name::String,
    bus_idx::Int,
    time::Float64,
    clearing_time::Float64,
    fault_conductance::Float64,
    fault_susceptance::Float64,
)
    return ShortCircuit(
        name,
        bus_idx,
        time,
        clearing_time,
        fault_conductance,
        fault_susceptance,
    )
end

perturbation_name(inputs, idx::Int) = inputs.perturbations[idx].name

perturbation_bus_idx(inputs, idx::Int) = inputs.perturbations[idx].bus_idx

perturbation_time(inputs, idx::Int) = inputs.perturbations[idx].time

perturbation_clearing_time(inputs, idx::Int) = inputs.perturbations[idx].clearing_time

perturbation_fault_conductance(inputs, idx::Int) = inputs.perturbations[idx].fault_conductance

perturbation_fault_susceptance(inputs, idx::Int) = inputs.perturbations[idx].fault_susceptance

mutable struct CircuitTrip <: Perturbation
    name::String
    circuit_idx::Int # index of the circuit that is tripped

    time::Float64 # instant the circuit is tripped, in s
end

function CircuitTrip(;
    name::String,
    circuit_idx::Int,
    time::Float64,
)
    return CircuitTrip(name, circuit_idx, time)
end

perturbation_circuit_idx(inputs, idx::Int) = inputs.perturbations[idx].circuit_idx

mutable struct GeneratorTrip <: Perturbation
    name::String
    generator_idx::Int # index of the generator that is tripped

    time::Float64 # instant the generator is tripped, in s
end

function GeneratorTrip(;
    name::String,
    generator_idx::Int,
    time::Float64,
)
    return GeneratorTrip(name, generator_idx, time)
end

perturbation_generator_idx(inputs, idx::Int) = inputs.perturbations[idx].generator_idx

mutable struct LoadChange <: Perturbation
    name::String
    load_idx::Int # index of the load that changes

    time::Float64 # instant the load changes, in s

    new_p0::Float64 # new active power at the power flow voltage of the load bus, in pu
    new_q0::Float64 # new reactive power at the power flow voltage of the load bus, in pu
end

function LoadChange(;
    name::String,
    load_idx::Int,
    time::Float64,
    new_p0::Float64,
    new_q0::Float64,
)
    return LoadChange(name, load_idx, time, new_p0, new_q0)
end

perturbation_load_idx(inputs, idx::Int) = inputs.perturbations[idx].load_idx

perturbation_new_p0(inputs, idx::Int) = inputs.perturbations[idx].new_p0

perturbation_new_q0(inputs, idx::Int) = inputs.perturbations[idx].new_q0
