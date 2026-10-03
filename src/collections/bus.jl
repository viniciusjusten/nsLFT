mutable struct Bus
    name::String

    generator_idx::Union{Int, Nothing} # index of the generator connected to this bus, if any
    load_idx::Union{Int, Nothing} # index of the load connected to this bus, if any

    voltage::Float64 # voltage magnitude at the power flow solution, in pu
    angle::Float64 # voltage angle at the power flow solution, in rad
    shunt_susceptance::Float64 # shunt susceptance, in pu

    # Cache
    fault_admittance::ComplexF64 # shunt admittance of an applied short circuit, zero without a fault, in pu
end

function Bus(;
    name::String,
    voltage::Float64,
    angle::Float64,
    shunt_susceptance::Float64,
    generator_idx::Union{Int, Nothing} = nothing,
    load_idx::Union{Int, Nothing} = nothing,
)
    return Bus(
        name,
        generator_idx,
        load_idx,
        voltage,
        angle,
        shunt_susceptance,
        0.0 + 0.0im,
    )
end

bus_name(inputs, idx::Int) = inputs.buses[idx].name

bus_generator_idx(inputs, idx::Int) = inputs.buses[idx].generator_idx

bus_load_idx(inputs, idx::Int) = inputs.buses[idx].load_idx

bus_voltage(inputs, idx::Int) = inputs.buses[idx].voltage

bus_angle(inputs, idx::Int) = inputs.buses[idx].angle

bus_shunt_susceptance(inputs, idx::Int) = inputs.buses[idx].shunt_susceptance

bus_fault_admittance(inputs, idx::Int) = inputs.buses[idx].fault_admittance
