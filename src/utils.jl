# network frame (R, I) to rotor frame (d, q), Kundur, Power System Stability and Control, p. 852
function ri_to_dq(x::Float64)
    return [
        sin(x) -cos(x)
        cos(x) sin(x)
    ]
end

# rotor frame (d, q) to network frame (R, I), inverse of ri_to_dq, Kundur p. 852
function dq_to_ri(x::Float64)
    return [
        sin(x) cos(x)
        -cos(x) sin(x)
    ]
end
