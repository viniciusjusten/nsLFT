mutable struct Circuit
    name::String

    from_bus_idx::Int # index of the bus at the sending end
    to_bus_idx::Int # index of the bus at the receiving end

    resistance::Float64 # series resistance, in pu
    reactance::Float64 # series reactance, in pu
    shunt_conductance::Float64 # total shunt conductance, in pu
    shunt_susceptance::Float64 # total shunt susceptance, in pu
    tap_ratio::Float64 # transformer tap ratio, in pu

    # Cache
    in_service::Bool # indicates if the circuit is connected, false after a trip
end

function Circuit(;
    name::String,
    from_bus_idx::Int,
    to_bus_idx::Int,
    resistance::Float64,
    reactance::Float64,
    shunt_conductance::Float64,
    shunt_susceptance::Float64,
    tap_ratio::Float64,
)
    return Circuit(
        name,
        from_bus_idx,
        to_bus_idx,
        resistance,
        reactance,
        shunt_conductance,
        shunt_susceptance,
        tap_ratio,
        true,
    )
end

circuit_name(inputs, idx::Int) = inputs.circuits[idx].name

circuit_from_bus_idx(inputs, idx::Int) = inputs.circuits[idx].from_bus_idx

circuit_to_bus_idx(inputs, idx::Int) = inputs.circuits[idx].to_bus_idx

circuit_resistance(inputs, idx::Int) = inputs.circuits[idx].resistance

circuit_reactance(inputs, idx::Int) = inputs.circuits[idx].reactance

circuit_shunt_conductance(inputs, idx::Int) = inputs.circuits[idx].shunt_conductance

circuit_shunt_susceptance(inputs, idx::Int) = inputs.circuits[idx].shunt_susceptance

circuit_tap_ratio(inputs, idx::Int) = inputs.circuits[idx].tap_ratio

circuit_in_service(inputs, idx::Int) = inputs.circuits[idx].in_service
