function initialize_buses!(inputs::Inputs, results::Results)
    for bus_idx in 1:num_buses(inputs)
        V0 = bus_voltage(inputs, bus_idx) * cis(bus_angle(inputs, bus_idx))
        results.bus[bus_idx].Vr[1] = real(V0)
        results.bus[bus_idx].Vi[1] = imag(V0)
    end
    return nothing
end

function initialization(inputs::Inputs)
    results = Results(inputs)

    initialize_buses!(inputs, results)
    initialize_generators!(inputs, results)
    solve_network!(inputs, results, 0) # V and Pele at t = 0 from the initial states
    initialize_mechanical_powers!(inputs, results)

    return results
end
