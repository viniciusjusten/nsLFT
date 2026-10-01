# Classical Synchronous Machine + Network Model

Reference derivation for implementation. Constant impedance (Z) loads, classical
(2nd order) synchronous machine model, no AVR, no governor.

This is meant as the first working version of the dynamic model. Batteries as
VSM and GFL renewables as constant P negative loads come next, built on top of
this same interface structure. Two axis machine models, exciters, turbines and
switched converter models come later.

---

## 1. State variables

Only two differential states per synchronous machine, nothing else is dynamic
at this stage.

```
delta_i  : rotor angle of machine i
omega_i  : rotor speed of machine i
```

Everything else (currents, voltages, electrical power) is algebraic, solved
instantaneously at every time point from delta and omega.

---

## 2. Machine parameters (fixed, from data)

```
Ra       : armature resistance
Xd_p     : direct axis transient reactance (X'd)
H        : inertia constant
D        : damping coefficient (can be set to zero if no primary response is modeled)
omega_s  : synchronous speed (constant, reference)
```

Classical model assumption: Xd' = Xq' = X'. This is what allows using a single
reactance in both stator equations below instead of two different ones. It is
also what forces Ed' to be identically zero, since the machine model keeps the
internal voltage aligned with the q axis at all times. Eq' is treated as
constant, not as a free variable and not as a state.

```
Eq_p     : constant internal voltage magnitude (Eq'), fixed after initialization
Pm       : constant mechanical power, fixed after initialization
```

---

## 3. Park transformation

Rotates network frame (real, imaginary) into the machine own rotating frame
(d, q), using the machine rotor angle delta.

Forward transform, network to machine frame

```
Vd =  cos(delta) * Vr + sin(delta) * Vi
Vq = -sin(delta) * Vr + cos(delta) * Vi
```

Inverse transform, machine frame to network, needed to inject the stator
current back into the network equations

```
Ir_gen =  cos(delta) * Id - sin(delta) * Iq
Ii_gen =  sin(delta) * Id + cos(delta) * Iq
```

Same rotation matrix, one direction is the transpose of the other since it is
an orthogonal rotation.

---

## 4. Stator algebraic equations (machine frame)

General form, before the classical simplification

```
Ed - Vd = Ra*Id - X*Iq
Eq - Vq = X*Id  + Ra*Iq
```

This comes directly from Ohm law across the impedance R + jX between the
internal voltage and the terminal voltage, written in the d and q axes.

Applying the classical model simplification, Ed = 0 and X = Xd_p

```
0     - Vd = Ra*Id - Xd_p*Iq
Eq_p - Vq = Xd_p*Id + Ra*Iq
```

These two real equations, together with Vd and Vq coming from the Park
transform above, define Id and Iq given delta, Eq_p and the network voltage at
that bus.

---

## 5. Electrical power and reactive power

```
Pe = Ed*Id + Eq*Iq
Qe = Eq*Id - Ed*Iq
```

With Ed = 0 in the classical model, this reduces to

```
Pe = Eq_p * Iq
Qe = Eq_p * Id
```

Pe is what enters the swing equation. Qe is not needed for the classical
dynamics itself but is useful for consistency checks against the power flow
solution.

---

## 6. Swing equation (the only differential equations)

```
d(delta)/dt = omega - omega_s

d(omega)/dt = (1 / (2*H)) * (Pm - Pe - D*(omega - omega_s))
```

Pm is constant, no governor at this stage. Pe comes from section 5, which
depends on delta and on the network voltage at that bus through Id, Iq.

---

## 7. Network equations (Kirchhoff, real and imaginary components)

For every bus k, with neighbors m in the set of buses connected to k

```
Ikr = gkk*Vkr - bkk*Vki + sum_m [ gkm*(Vkr - Vmr) - bkm*(Vki - Vmi) ]
Iki = bkk*Vkr + gkk*Vki + sum_m [ bkm*(Vkr - Vmr) + gkm*(Vki - Vmi) ]
```

gkk, bkk are the self conductance and susceptance of bus k. gkm, bkm are the
mutual conductance and susceptance between bus k and neighbor m, both coming
from the bus admittance matrix.

---

## 8. Constant impedance load

For a load bus with equivalent impedance Zload = R_L + j X_L

```
Ir_load = -(R_L*Vr + X_L*Vi) / (R_L^2 + X_L^2)
Ii_load =  (X_L*Vr - R_L*Vi) / (R_L^2 + X_L^2)
```

In practice this constant admittance is usually folded directly as a shunt
term into gkk, bkk of that bus in the Y bus matrix, so the load does not need
to appear as a separate current injection equation at simulation time. It only
needs to be computed once, during initialization, see section 10.

---

## 9. Interface equation, closing the algebraic loop

This is the equation that ties the machine side and the network side together
and is easy to forget when writing the model down. At every generator bus k,
the current coming out of the stator, once rotated back into the network
frame, has to equal the current given by the Kirchhoff equation at that same
bus.

```
Ir_gen_k(delta_k, Eq_p_k, Vr_k, Vi_k) = Ikr(V)
Ii_gen_k(delta_k, Eq_p_k, Vr_k, Vi_k) = Iki(V)
```

Without writing this equality explicitly, Id and Iq computed from the stator
equations and Ikr, Iki computed from Kirchhoff would be two independent
expressions for the same physical current, with nothing forcing them to agree.
This is what actually eliminates current as an independent unknown and leaves
the whole algebraic system written purely in terms of the voltages V and the
machine states delta.

---

## 10. Initialization from the power flow solution

Before the dynamic simulation starts, solve the regular power flow to get V0,
theta0 at every bus and I0 out of every generator terminal.

For each generator

```
Eq_p = magnitude of ( V0 + j*Xd_p*I0 )
delta_0 = angle of ( V0 + j*Xd_p*I0 )
Pm = Pe evaluated at t = 0 minus, so the machine starts in equilibrium
```

Eq_p and Pm are then held fixed for the rest of the simulation, they are
parameters from this point on, not variables.

For each constant impedance load, with S0 = P0 + j*Q0 the power flow solution
at that bus

```
Zload = |V0|^2 / conj(S0)
```

giving R_L and X_L to be used in section 8, or folded directly into the shunt
part of the Y bus as mentioned above.

---

## 11. Summary of the full DAE system

Differential, two per machine

```
delta_i dot = omega_i - omega_s
omega_i dot = (Pm_i - Pe_i - D_i*(omega_i - omega_s)) / (2*H_i)
```

Algebraic, per machine

```
Vd_i, Vq_i     from Park forward transform on Vr_i, Vi_i
Id_i, Iq_i     from stator equations with Ed=0, X=Xd_p
Pe_i           from Eq_p_i * Iq_i
Ir_gen_i, Ii_gen_i   from Park inverse transform on Id_i, Iq_i
```

Algebraic, network wide

```
Ikr, Iki for every bus k, from Kirchhoff with the Y bus (loads folded in as shunt)
Ir_gen_k = Ikr, Ii_gen_k = Iki, for every generator bus k
```

This whole algebraic block is solved simultaneously with the differential
equations at each time step, following the simultaneous implicit scheme
discussed earlier, not a partitioned scheme with a lagged network solution.

---

## 12. Planned extensions, not part of this version

```
Battery as VSM        adds a machine like model with its own delta, omega, similar
                       interface equations, but Pm coming from a controllable
                       reference instead of a fixed mechanical input

Renewables as GFL      modeled as negative constant P loads for now, no internal
                       dynamic states, injected directly into the network current
                       balance like a load with the sign flipped

Two axis machines      Xd different from Xq, adds Ed as a real state instead of
                       being fixed at zero, plus the field flux dynamics

Exciters and turbines  add their own differential states, AVR changes Eq_p from a
                       constant parameter into a controlled variable, governor
                       changes Pm from constant into a controlled variable

Switched devices       full converter models, no longer expressed only through
                       the classical dq machine interface used here
```
