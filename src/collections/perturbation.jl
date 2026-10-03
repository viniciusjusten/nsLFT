abstract type Perturbation end

mutable struct ShortCircuit <: Perturbation
    name::String
    bus_idx::Int # index of the bus where the fault is applied

    time::Float64 # instant the fault is applied, in s

    fault_conductance::Float64 # shunt conductance added by the fault, in pu
    fault_susceptance::Float64 # shunt susceptance added by the fault, in pu
end

function ShortCircuit(;
    name::String,
    bus_idx::Int,
    time::Float64,
    fault_conductance::Float64,
    fault_susceptance::Float64,
)
    return ShortCircuit(
        name,
        bus_idx,
        time,
        fault_conductance,
        fault_susceptance,
    )
end

perturbation_name(perturbation::Perturbation) = perturbation.name

perturbation_bus_idx(perturbation::ShortCircuit) = perturbation.bus_idx

perturbation_time(perturbation::Perturbation) = perturbation.time

perturbation_fault_conductance(perturbation::ShortCircuit) = perturbation.fault_conductance

perturbation_fault_susceptance(perturbation::ShortCircuit) = perturbation.fault_susceptance

function apply_perturbation!(inputs, perturbation::ShortCircuit)
    bus_idx = perturbation_bus_idx(perturbation)
    inputs.Ybus_cache[bus_idx, bus_idx] += perturbation_fault_conductance(perturbation) + im * perturbation_fault_susceptance(perturbation)
    return nothing
end

mutable struct ShortCircuitRemoval <: Perturbation
    name::String
    short_circuit_idx::Int # index in inputs.perturbations of the ShortCircuit that is removed

    time::Float64 # instant the fault is cleared, in s
end

function ShortCircuitRemoval(;
    name::String,
    short_circuit_idx::Int,
    time::Float64,
)
    return ShortCircuitRemoval(name, short_circuit_idx, time)
end

perturbation_short_circuit_idx(perturbation::ShortCircuitRemoval) = perturbation.short_circuit_idx

function apply_perturbation!(inputs, perturbation::ShortCircuitRemoval)
    # the removal of a short circuit is the same as rewriting the admittance matrix without the short circuit
    return nothing
end

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

perturbation_circuit_idx(perturbation::CircuitTrip) = perturbation.circuit_idx

function apply_perturbation!(inputs, perturbation::CircuitTrip)
    circuit_idx = perturbation_circuit_idx(perturbation)
    from_bus_idx = circuit_from_bus_idx(inputs, circuit_idx)
    to_bus_idx = circuit_to_bus_idx(inputs, circuit_idx)
    tap = circuit_tap_ratio(inputs, circuit_idx)
    y = admittance(circuit_resistance(inputs, circuit_idx), circuit_reactance(inputs, circuit_idx))
    y_shunt = circuit_shunt_conductance(inputs, circuit_idx) + im * circuit_shunt_susceptance(inputs, circuit_idx)
    inputs.Ybus_cache[from_bus_idx, from_bus_idx] -= y * tap^2 + y_shunt / 2
    inputs.Ybus_cache[to_bus_idx, to_bus_idx] -= y + y_shunt / 2
    inputs.Ybus_cache[from_bus_idx, to_bus_idx] += y * tap
    inputs.Ybus_cache[to_bus_idx, from_bus_idx] += y * tap
    return nothing
end

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

perturbation_generator_idx(perturbation::GeneratorTrip) = perturbation.generator_idx

function apply_perturbation!(inputs, perturbation::GeneratorTrip)
    generator_idx = perturbation_generator_idx(perturbation)
    bus_idx = generator_bus(inputs, generator_idx)
    inputs.Ybus_cache[bus_idx, bus_idx] -= generator_admittance(inputs, generator_idx) # TODO change according to the generator model
    inputs.generators[generator_idx].tripped = true
    return nothing
end

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

perturbation_load_idx(perturbation::LoadChange) = perturbation.load_idx

perturbation_new_p0(perturbation::LoadChange) = perturbation.new_p0

perturbation_new_q0(perturbation::LoadChange) = perturbation.new_q0

function apply_perturbation!(inputs, perturbation::LoadChange)
    load_idx = perturbation_load_idx(perturbation)
    bus_idx = load_bus(inputs, load_idx)
    inputs.Ybus_cache[bus_idx, bus_idx] -= load_admittance(inputs, load_idx)
    new_admittance = load_constant_admittance(
        perturbation_new_p0(perturbation),
        perturbation_new_q0(perturbation),
        bus_voltage(inputs, bus_idx),
    )
    inputs.Ybus_cache[bus_idx, bus_idx] += new_admittance
    return nothing
end
