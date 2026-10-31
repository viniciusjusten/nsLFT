function initialize_bus_freq_estimation!(
    ::FilteredAngleDerivative,
    estimation_state::FilteredAngleDerivativeState,
    bus_state::BusState,
)
    V0 = bus_state.Vr[1] + im * bus_state.Vi[1]
    estimation_state.theta_estim[1] = angle(V0)
    estimation_state.x_theta[1] = 0.0
    estimation_state.omega[1] = 1.0
    estimation_state.d_omega[1] = 0.0
    return nothing
end

# without a frequency estimation there is no state to initialize
function initialize_bus_freq_estimation!(::Nothing, ::Nothing, ::BusState)
    return nothing
end

function initialize_bus_freq_estimations!(inputs::Inputs, results::Results)
    for (bus, bus_state) in zip(inputs.buses, results.bus)
        freq_estimation = bus_freq_estimation(bus)
        initialize_bus_freq_estimation!(freq_estimation, bus_state.freq_estimation, bus_state)
    end
    return nothing
end
