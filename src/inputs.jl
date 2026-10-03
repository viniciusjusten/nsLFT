mutable struct Inputs
    case_path::String

    Sb::Float64 # system base power, in MVA
    fb::Float64 # system base frequency, in Hz

    integration_step::Float64 # integration time step, in s
    simulation_horizon::Float64 # total simulated time, in s
    tolerance::Float64 # convergence tolerance of the numerical solvers
    max_iterations::Int # maximum number of corrector iterations per time step

    buses::Vector{Bus}
    circuits::Vector{Circuit}
    generators::Vector{Generator}
    loads::Vector{Load}
    perturbations::Vector{Perturbation}

    base_Ybus::Matrix{ComplexF64} # admittance matrix of the base network topology, without any perturbation
    Ybus_cache::Matrix{ComplexF64} # admittance matrix of the current network topology, overwritten at each event
    Zbus_cache::Matrix{ComplexF64} # impedance matrix of the current network topology, overwritten at each event
end

function Inputs(;
    case_path::String,
    Sb::Float64,
    fb::Float64,
    integration_step::Float64,
    simulation_horizon::Float64,
    tolerance::Float64,
    max_iterations::Int = 50,
    buses::Vector{Bus} = Bus[],
    circuits::Vector{Circuit} = Circuit[],
    generators::Vector{Generator} = Generator[],
    loads::Vector{Load} = Load[],
    perturbations::Vector{Perturbation} = Perturbation[],
    base_Ybus::Matrix{ComplexF64} = Matrix{ComplexF64}(undef, 0, 0),
    Ybus_cache::Matrix{ComplexF64} = Matrix{ComplexF64}(undef, 0, 0),
    Zbus_cache::Matrix{ComplexF64} = Matrix{ComplexF64}(undef, 0, 0),
)
    return Inputs(
        case_path,
        Sb,
        fb,
        integration_step,
        simulation_horizon,
        tolerance,
        max_iterations,
        buses,
        circuits,
        generators,
        loads,
        perturbations,
        base_Ybus,
        Ybus_cache,
        Zbus_cache,
    )
end

case_path(inputs::Inputs) = inputs.case_path

Sb(inputs::Inputs) = inputs.Sb

fb(inputs::Inputs) = inputs.fb

integration_step(inputs::Inputs) = inputs.integration_step

simulation_horizon(inputs::Inputs) = inputs.simulation_horizon

tolerance(inputs::Inputs) = inputs.tolerance

max_iterations(inputs::Inputs) = inputs.max_iterations

function num_time_steps(inputs::Inputs)
    return round(Int, simulation_horizon(inputs) / integration_step(inputs))
end

base_Ybus(inputs::Inputs) = inputs.base_Ybus

Ybus_cache(inputs::Inputs) = inputs.Ybus_cache

Zbus_cache(inputs::Inputs) = inputs.Zbus_cache

bus(inputs::Inputs, idx::Int) = inputs.buses[idx]

circuit(inputs::Inputs, idx::Int) = inputs.circuits[idx]

generator(inputs::Inputs, idx::Int) = inputs.generators[idx]

load(inputs::Inputs, idx::Int) = inputs.loads[idx]

perturbation(inputs::Inputs, idx::Int) = inputs.perturbations[idx]

num_buses(inputs::Inputs) = length(inputs.buses)

num_circuits(inputs::Inputs) = length(inputs.circuits)

num_generators(inputs::Inputs) = length(inputs.generators)

num_loads(inputs::Inputs) = length(inputs.loads)

num_perturbations(inputs::Inputs) = length(inputs.perturbations)

function perturbations_at(inputs::Inputs, ts::Int)
    # round instead of comparing floats, since time / integration_step is rarely an exact integer
    return filter(
        perturbation -> round(Int, perturbation_time(perturbation) / integration_step(inputs)) == ts,
        inputs.perturbations,
    )
end
