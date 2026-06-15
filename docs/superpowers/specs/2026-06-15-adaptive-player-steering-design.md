# Adaptive Player Steering - Research And Design

## Status

Research recommendation only. No implementation is authorized by this document.

## Problem

At high speed, sharp keyboard steering can appear to stop increasing or lock while the vehicle continues forward and oversteers. Moderate turns remain acceptable. The symptom must be separated into:

1. player steering input shaping;
2. maximum steering-angle limiting at speed;
3. tire lateral-force saturation or loss of grip;
4. yaw/oversteer after lateral grip is exceeded;
5. differences between digital keyboard and analog input.

## Arma Evidence

Bohemia's Arma 3 Cars Config Guidelines document a player-only `PlayerSteeringCoefficients` class:

- `turnIncreaseConst`: base steering sensitivity; higher values steer faster.
- `turnIncreaseLinear`: speed-dependent sensitivity; higher values reduce high-speed sensitivity while increasing low-speed sensitivity.
- `turnIncreaseTime`: nonlinear steering build-up; higher values smooth steering near center and increase sensitivity closer to maximum steering angle.
- `turnDecreaseConst`: base wheel-recentering rate.
- `turnDecreaseLinear`: speed-dependent recentering.
- `turnDecreaseTime`: nonlinear recentering across steering angle.
- `maxTurnHundred`: fraction of maximum steering angle available at 100 km/h, interpolated from full angle at 0 km/h.

Source: https://community.bohemia.net/wiki/Arma_3:_Cars_Config_Guidelines#Steering_properties_for_player

The same Bohemia source documents tire behavior:

- `latStiffX` and `latStiffY` govern lateral stiffness and saturation under tire load.
- More lateral stiffness may improve initial turning response, but total force remains load-limited.
- Increasing lateral force can reduce longitudinal force because the tire has a finite force budget.
- `frictionVsSlipGraph` scales surface friction as longitudinal slip changes.
- Suspension force application points, spring behavior, and anti-roll bars also affect load transfer and cornering.

Source: https://community.bohemia.net/wiki/Arma_3:_Cars_Config_Guidelines#Tire_parameters

## Automotive Research

### Electric Power Steering

EPS uses electric assistance and sensor feedback to vary steering effort. Torque, angle, and position sensors improve measurement and control, but these are hardware concepts. FIXICS cannot add physical steering torque or road feel to a keyboard.

Useful transferable concept: adjust assistance and response according to speed and driver input rather than applying one constant ratio.

### Variable-Ratio And Active Steering

Modern active steering changes the relationship between driver input and road-wheel angle. Low-speed steering can be quicker, while high-speed response is moderated for stability. Corrective steering may also counter unwanted yaw, but it is distinct from ordinary steering-ratio control.

Transferable concept: a nonlinear input curve with speed-dependent limits, not a direct one-to-one keyboard command.

### Steer-By-Wire Direction

Current production development is moving toward electronically mapped steering response, redundancy, configurable feedback, and integration with driver assistance. Recent reporting in 2026 describes Mercedes introducing optional steer-by-wire on the EQS after extensive testing. This supports adaptive response as an industry direction, but FIXICS must not describe an SQF/config approximation as actual EPS or steer-by-wire.

Recent context:

- https://www.theverge.com/transportation/906539/mercedes-steer-by-wire-steering-yoke-eqs
- https://www.automotive-technology.com/articles/driving-innovation-steering-and-automotive-components-in-the-modern-era

## Recommendation

Use a config-first adaptive steering profile based on `PlayerSteeringCoefficients`.

Do not begin with scripted velocity rotation, yaw correction, tire-friction inflation, or a native steering injector.

### Desired Keyboard Response

Keyboard input should behave like a rate-controlled steering request:

1. Initial key press produces a deliberate but not instantaneous steering ramp.
2. Continued hold increases steering progressively.
3. Near maximum requested angle, the curve becomes more responsive so sharp turns remain available.
4. High speed reduces maximum available steering angle enough to prevent twitchiness, but not so strongly that steering appears locked.
5. Key release recenters progressively, with faster recentering at speed.

This is nonlinear steering build-up. It is not a linear WASD-to-wheel-angle mapping.

### Initial Parameter Strategy

Exact values require inheritance inspection and SQA testing. The initial experiment should:

- raise `turnIncreaseConst` modestly if steering builds too slowly;
- reduce `turnIncreaseLinear` if high-speed sensitivity is being suppressed too aggressively;
- increase `turnIncreaseTime` moderately to retain smooth center response while allowing stronger response near steering lock;
- tune `turnDecreaseConst` and `turnDecreaseLinear` so release does not snap or remain stuck;
- increase `maxTurnHundred` only if measured wheel angle is being limited too severely at high speed.

No value should be applied broadly to all `LandVehicle` classes. Use an opt-in class list or narrowly inherited vehicle families after reproduction identifies affected classes.

## Tire Grip Decision

Do not change tire grip during the first steering experiment.

If wheel-angle response is correct but the vehicle still travels forward:

- probable understeer/front lateral-force saturation: inspect `latStiffX`, `latStiffY`, load transfer, suspension force points, and surface friction;
- probable oversteer/rear lateral-force loss: inspect rear tire stiffness, throttle state, yaw rate, and rear load transfer;
- both require vehicle-class-specific handling work and separate approval.

Increasing grip globally would hide input defects, alter braking/acceleration balance, and risk unrealistic cornering.

## Reproduction Matrix

Record each run with Native Driver Assist and ABS both enabled and disabled:

| Variable | Values |
|---|---|
| Vehicle | Offroad, SUV, Hatchback/Sport, Van/Truck, affected mod vehicle |
| Speed | 30, 50, 70, 90, 110 km/h |
| Turn input | short tap, 0.25 s hold, 0.5 s hold, full hold |
| Direction | left and right |
| Input device | keyboard and analog controller |
| Throttle | released, partial, full |
| Surface | dry paved road, dirt, grass |
| Assist | ABS/native on and off |

Capture:

- vehicle class name;
- speed at steering onset;
- whether visual front-wheel angle continues increasing;
- yaw direction and approximate severity;
- understeer versus oversteer;
- time from key release to recentering;
- whether analog input reproduces the problem.

## Decision Tree

1. Wheel angle stops increasing too early at speed:
   tune `PlayerSteeringCoefficients`, especially `maxTurnHundred` and speed sensitivity.
2. Wheel angle responds correctly but vehicle continues straight:
   investigate front tire lateral-force saturation.
3. Rear rotates while front responds:
   investigate rear grip, throttle-induced slip, load transfer, and yaw stability.
4. Keyboard fails but analog is acceptable:
   prioritize digital input shaping.
5. Both input devices fail identically:
   prioritize vehicle config and tire/suspension behavior.

## Validation

Automated:

- static checks for narrow class scope and approved coefficient names;
- HEMTT config validation;
- no change to ABS, handbrake, or direction-transition code.

Manual:

- complete the reproduction matrix before and after each profile;
- compare keyboard and analog steering;
- verify low-speed maneuverability and high-speed stability;
- test adjacent braking and slope behavior;
- record vehicle-specific results rather than declaring global success.

## Out Of Scope

- Simulating physical steering torque or road feedback.
- Claiming actual EPS, ADAS, or steer-by-wire functionality.
- Global tire-grip increases.
- Automatic countersteering or stability control.
- Native input injection.
- Multiplayer authority.
