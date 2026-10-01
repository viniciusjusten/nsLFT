function predict_omega!(inputs::Inputs, results::Results, gen_idx::Int, ts::Int)
    # predict the next omega value using the Euler method
    results.generator[gen_idx].omega[ts+1] =
        results.generator[gen_idx].omega[ts] +
        integration_step(inputs) / (2 * generator_H(inputs, gen_idx)) * (
            results.generator[gen_idx].Pmec[ts] -
            results.generator[gen_idx].Pele[ts] -
            generator_D(inputs, gen_idx) * (
                results.generator[gen_idx].omega[ts] - 1.0
            )
        )
    return nothing
end

function step_omega!(inputs::Inputs, results::Results, gen_idx::Int, ts::Int)
    # compute the next omega value using the trapezoidal rule
    results.generator[gen_idx].omega[ts+1] =
        results.generator[gen_idx].omega[ts] +
        integration_step(inputs) / (4 * generator_H(inputs, gen_idx)) * (
            results.generator[gen_idx].Pmec[ts] -
            results.generator[gen_idx].Pele[ts] -
            generator_D(inputs, gen_idx) * (
                results.generator[gen_idx].omega[ts] - 1.0
            ) +
            results.generator[gen_idx].Pmec[ts+1] -
            results.generator[gen_idx].Pele[ts+1] -
            generator_D(inputs, gen_idx) * (
                results.generator[gen_idx].omega[ts+1] - 1.0
            )
        )
    return nothing
end

function predict_delta!(inputs::Inputs, results::Results, gen_idx::Int, ts::Int)
    # predict the next delta value using the Euler method
    results.generator[gen_idx].delta[ts+1] =
        results.generator[gen_idx].delta[ts] +
        integration_step(inputs) * 2 * pi * fb(inputs) * (
            results.generator[gen_idx].omega[ts] - 1.0
        )
    return nothing
end

function step_delta!(inputs::Inputs, results::Results, gen_idx::Int, ts::Int)
    # compute the next delta value using the trapezoidal rule
    results.generator[gen_idx].delta[ts+1] =
        results.generator[gen_idx].delta[ts] +
        integration_step(inputs) * pi * fb(inputs) * (
            results.generator[gen_idx].omega[ts] - 1.0 +
            results.generator[gen_idx].omega[ts+1] - 1.0
        )
    return nothing
end

function electrical_power(inputs::Inputs, results::Results, gen_idx::Int, ts::Int)
    bus_idx = generator_bus(inputs, gen_idx)
    V = results.bus[bus_idx].Vr[ts] + im * results.bus[bus_idx].Vi[ts]
    delta = results.generator[gen_idx].delta[ts]
    E = results.generator[gen_idx].Eq_prime * cis(delta)
    I = (E - V) * generator_admittance(inputs, gen_idx)
    return real(conj(I) * E)
end
