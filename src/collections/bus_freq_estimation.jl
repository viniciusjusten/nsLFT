abstract type BusFreqEstimation end

# Bus frequency estimation model based on filtered angle derivative
# page 312 of "Power System Modeling and Scripting" by Milano
mutable struct FilteredAngleDerivative <: BusFreqEstimation
    name::String

    # Parameters
    Tf::Float64 # time constant of the filtered derivative of the angle, in s
    Tw::Float64 # time constant of the low pass filter of the frequency, in s
end

function FilteredAngleDerivative(;
    name::String,
    Tf::Float64,
    Tw::Float64,
)
    return FilteredAngleDerivative(
        name,
        Tf,
        Tw,
    )
end

bus_freq_estimation_name(freq_estimation::BusFreqEstimation) = freq_estimation.name

bus_freq_estimation_Tf(freq_estimation::FilteredAngleDerivative) = freq_estimation.Tf

bus_freq_estimation_Tw(freq_estimation::FilteredAngleDerivative) = freq_estimation.Tw
