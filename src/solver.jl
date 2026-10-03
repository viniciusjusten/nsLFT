# values at ts + 1 from the previous corrector iteration, used to check convergence
mutable struct StepCache
    delta::Vector{Float64}
    omega::Vector{Float64}
    Vr::Vector{Float64}
    Vi::Vector{Float64}
end

function StepCache(inputs::Inputs)
    n_generators = num_generators(inputs)
    n_buses = num_buses(inputs)
    return StepCache(zeros(n_generators), zeros(n_generators), zeros(n_buses), zeros(n_buses))
end

function cache_step!(inputs::Inputs, results::Results, ts::Int, caches::StepCache)
    for gen_idx in 1:num_generators(inputs)
        caches.delta[gen_idx] = results.generator[gen_idx].delta[ts+1]
        caches.omega[gen_idx] = results.generator[gen_idx].omega[ts+1]
    end
    for bus_idx in 1:num_buses(inputs)
        caches.Vr[bus_idx] = results.bus[bus_idx].Vr[ts+1]
        caches.Vi[bus_idx] = results.bus[bus_idx].Vi[ts+1]
    end
    return nothing
end

function step_converged(inputs::Inputs, results::Results, ts::Int, caches::StepCache)
    max_dif = 0.0

    # the first index in results corresponds to the initial state (t = 0),
    # so the current time step is ts + 1
    for gen_idx in 1:num_generators(inputs)
        max_dif = max(max_dif, abs(caches.delta[gen_idx] - results.generator[gen_idx].delta[ts+1]))
        max_dif = max(max_dif, abs(caches.omega[gen_idx] - results.generator[gen_idx].omega[ts+1]))
    end
    for bus_idx in 1:num_buses(inputs)
        max_dif = max(max_dif, abs(caches.Vr[bus_idx] - results.bus[bus_idx].Vr[ts+1]))
        max_dif = max(max_dif, abs(caches.Vi[bus_idx] - results.bus[bus_idx].Vi[ts+1]))
    end

    return max_dif < tolerance(inputs)
end

function step!(inputs::Inputs, results::Results, ts::Int)
    caches = StepCache(inputs)

    cache_Ybus!(inputs, ts) # update the Ybus cache and its LU factorization if there are any perturbations at this time step

    for (generator, state) in zip(inputs.generators, results.generator)
        predict_omega!(inputs, generator, state, ts)
        predict_delta!(inputs, state, ts)
    end
    solve_network!(inputs, results, ts) # V[ts+1] and Pele[ts+1] from the predicted delta

    for iteration in 1:max_iterations(inputs)
        cache_step!(inputs, results, ts, caches) # delta, omega, Vr and Vi at ts+1

        for (generator, state) in zip(inputs.generators, results.generator)
            step_omega!(inputs, generator, state, ts)
            step_delta!(inputs, state, ts)
        end
        solve_network!(inputs, results, ts)

        if step_converged(inputs, results, ts, caches)
            return nothing
        end
    end
    error("Time step $ts did not converge after $(max_iterations(inputs)) iterations.")
end

function solve(inputs::Inputs)
    results = initialization(inputs)

    for ts in 1:num_time_steps(inputs)
        step!(inputs, results, ts)
    end

    write_results(inputs, results)

    return results
end
