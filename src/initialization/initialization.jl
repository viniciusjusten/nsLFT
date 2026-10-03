function initialize_buses!(inputs::Inputs, results::Results)
    for bus_idx in 1:num_buses(inputs)
        V0 = bus_voltage(inputs, bus_idx) * cis(bus_angle(inputs, bus_idx))
        results.bus[bus_idx].Vr[1] = real(V0)
        results.bus[bus_idx].Vi[1] = imag(V0)
    end
    return nothing
end

# brings the elements back to the base case, undoing the perturbations of a previous simulation of the same inputs
function reset_element_states!(inputs::Inputs)
    for bus in inputs.buses
        bus.fault_admittance = 0.0 + 0.0im
    end
    for circuit in inputs.circuits
        circuit.in_service = true
    end
    for generator in inputs.generators
        generator.tripped = false
    end
    for load in inputs.loads
        load.P = load.P0
        load.Q = load.Q0
    end
    return nothing
end

function initialization(inputs::Inputs)
    results = Results(inputs)

    reset_element_states!(inputs)
    initialize_buses!(inputs, results)
    initialize_generators!(inputs, results)
    initialize_Ybus!(inputs)
    solve_network!(inputs, results, 0) # V and Pele at t = 0 from the initial states
    initialize_mechanical_powers!(inputs, results)

    return results
end
