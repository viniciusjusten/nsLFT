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

circuit_name(circuit::Circuit) = circuit.name

circuit_from_bus_idx(circuit::Circuit) = circuit.from_bus_idx

circuit_to_bus_idx(circuit::Circuit) = circuit.to_bus_idx

circuit_resistance(circuit::Circuit) = circuit.resistance

circuit_reactance(circuit::Circuit) = circuit.reactance

circuit_shunt_conductance(circuit::Circuit) = circuit.shunt_conductance

circuit_shunt_susceptance(circuit::Circuit) = circuit.shunt_susceptance

circuit_tap_ratio(circuit::Circuit) = circuit.tap_ratio

circuit_in_service(circuit::Circuit) = circuit.in_service
