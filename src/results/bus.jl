mutable struct BusState
    Vr::Vector{Float64} # real part of the bus voltage, in pu
    Vi::Vector{Float64} # imaginary part of the bus voltage, in pu
end

function BusState(num_steps::Int)
    # NaN keeps a step not yet computed from passing a convergence check by accident
    return BusState(fill(NaN, num_steps), fill(NaN, num_steps))
end
