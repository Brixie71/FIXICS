# Adaptive Player Steering - Research And Design

## Status

Architecture and settings design approved by SQA. Implementation requires a
separate approved plan.

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

### Assessment Of The Suggested Technologies

| Suggested technology | Real vehicle purpose | Useful FIXICS concept | Not directly portable |
|---|---|---|---|
| EPS | Reduces steering effort with electric motor assistance | Speed-dependent steering response | Physical torque assistance and road feel |
| Torque/angle/position sensors | Measure driver effort, steering position, and actuator state | Observe input magnitude, requested direction, and actual steering animation | Adding unavailable wheel-torque sensors |
| Lightweight materials | Reduce mass and steering/suspension inertia | None for a player input curve | Carbon-fiber or alloy effects cannot be simulated by steering coefficients |
| ADAS integration | Adds lane, yaw, stability, and collision assistance | Optional future stability research | Automatic countersteer should not be bundled with steering sensitivity |
| Steer-by-wire | Electronically maps input to wheel angle with configurable ratio | Nonlinear, speed-adaptive input mapping | Claiming an SQF/config profile is actual steer-by-wire |

Materials innovation is therefore outside ISSUE-001. It may affect a real vehicle's mass and inertia, but it does not explain Arma's keyboard steering lock.

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

### Keyboard Versus Analog

Bohemia documents `inputAction` as returning the state of mapped input devices. It can return analog values rather than only zero or one; joystick axes return values between zero and one.

Source: https://community.bohemia.net/wiki/inputAction

This gives the reproduction test a meaningful split:

- Keyboard: digital request that the engine must turn into a steering ramp.
- Controller/wheel: continuous magnitude that already carries partial steering intent.

If the defect is keyboard-only, the likely problem is input buildup, speed sensitivity, or maximum-angle limiting. If analog input produces the same wheel angle and the same failure, the likely problem moves toward class configuration, tire force, suspension, or load transfer.

### Initial Parameter Strategy

Exact values require inheritance inspection and SQA testing. The initial experiment should:

- raise `turnIncreaseConst` modestly if steering builds too slowly;
- reduce `turnIncreaseLinear` if high-speed sensitivity is being suppressed too aggressively;
- increase `turnIncreaseTime` moderately to retain smooth center response while allowing stronger response near steering lock;
- tune `turnDecreaseConst` and `turnDecreaseLinear` so release does not snap or remain stuck;
- increase `maxTurnHundred` only if measured wheel angle is being limited too severely at high speed.

No value should be applied broadly to all `LandVehicle` classes. Use an opt-in class list or narrowly inherited vehicle families after reproduction identifies affected classes.

### Controlled Profile Experiments

Do not search for one final profile immediately. Compare profiles against the affected class's inherited values.

1. **Baseline**
   - Record all seven inherited `PlayerSteeringCoefficients`.
   - Do not change tire or suspension parameters.
2. **Response profile**
   - Increase only `turnIncreaseConst` by a small relative amount.
   - Purpose: determine whether steering buildup is simply too slow.
3. **High-speed authority profile**
   - Restore baseline buildup.
   - Increase only `maxTurnHundred` modestly or reduce `turnIncreaseLinear` modestly.
   - Purpose: determine whether high-speed steering is limited too aggressively.
4. **Progressive profile**
   - Restore baseline.
   - Increase `turnIncreaseTime` moderately.
   - Purpose: keep a stable center while making sustained input stronger near maximum angle.
5. **Recentering profile**
   - Change only `turnDecreaseConst`, `turnDecreaseLinear`, or `turnDecreaseTime`.
   - Purpose: isolate slow release, snap-back, or oscillation from turn-in behavior.

Change one coefficient family per experiment. Do not combine successful values until each effect is understood.

Suggested safety bounds for the first experimental pass are relative to inherited values:

- sensitivity and recentering coefficients: no more than approximately 10-20% per step;
- `maxTurnHundred`: no more than 0.05 per step;
- no coefficient below zero;
- no test profile applied to an untested broad parent class.

These are project test limits, not Bohemia-prescribed values.

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

## Diagnostic Method

### Config Inspection

For each vehicle, record `typeOf _vehicle`, then inspect the inherited `PlayerSteeringCoefficients` under:

```sqf
configFile >> "CfgVehicles" >> typeOf _vehicle >> "PlayerSteeringCoefficients"
```

`configProperties` can include inherited entries. `getNumber` can read each numeric coefficient, but a missing entry returns zero, so the test tooling must distinguish missing config from a real zero value.

Sources:

- https://community.bohemia.net/wiki/typeOf
- https://community.bohemia.net/wiki/configProperties
- https://community.bohemia.net/wiki/getNumber

### Runtime Observation

Record at a fixed interval:

- input magnitude from the mapped left/right `inputAction`;
- speed;
- `velocityModelSpace`, especially lateral X and longitudinal Y;
- vehicle heading change or yaw-rate estimate;
- visible steering animation source or phase when available;
- throttle and brake intent;
- ground surface and slope.

`velocityModelSpace` reports left/right, backward/forward, and down/up velocity in the vehicle's local frame. Changes in lateral velocity help separate a wheel-angle command from actual lateral movement.

Source: https://community.bohemia.net/wiki/velocityModelSpace

### Diagnostic Executable

Bohemia's diagnostic executable exposes:

- `AnimSrcUnit` for animation sources on the player's vehicle;
- `EPEVehicle` for gearbox, friction, thrust, brake, and other PhysX vehicle values;
- `EPEForce` and `Force` for applied forces;
- `Suspension` for per-wheel suspension state.

It also supports `diag_mergeConfigFile` for development-only config iteration. This should be used only in an isolated diagnostic workflow because Bohemia warns of limitations and possible exit crashes.

Sources:

- https://community.bohemia.net/wiki/Arma_3:_Diagnostics_Exe
- https://community.bohemia.net/wiki/diag_mergeConfigFile

### Classification Metrics

Use observations to classify the run:

- **Input limitation**: full input but steering animation/angle stops below expected authority.
- **Buildup limitation**: steering angle eventually arrives, but too late for the corner.
- **Understeer**: steering angle increases while yaw and lateral response remain insufficient.
- **Oversteer**: yaw grows faster than the intended path and the rear rotates outward.
- **Recentering defect**: input releases but steering animation or yaw persists too long.
- **Oscillation**: rapid sign changes or recentering cause repeated yaw correction.

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

## Recommended Implementation Sequence

1. Add read-only steering diagnostics and a manual reproduction mission/procedure.
2. Record inherited coefficients for representative vanilla vehicles.
3. Test keyboard and analog input without ABS/native steering changes.
4. Approve a narrow config experiment for one or two affected vehicle families.
5. Compare controlled profiles one coefficient family at a time.
6. Only if steering angle is correct, open a separate tire/suspension handling design.
7. Only after both stages fail should scripted or native steering assistance be considered.

## Approved Handling Architecture

### Goals

FIXICS will provide realistic, stable handling while preserving controlled,
recoverable sliding. The system must reduce abrupt body roll and rollover risk
without globally increasing tire grip or suppressing deliberate driver input.

### Compatibility Boundary

Handling profiles apply only to explicitly registered vehicle families.
Unsupported vehicles retain their original configuration and runtime behavior.
The first compatibility target is `EMP_Polaris_DAGOR`; additional families
require separate SQA validation before registration.

Passive profiles may tune:

- `PlayerSteeringCoefficients` for progressive turn-in, high-speed authority,
  and recentering;
- vehicle-specific anti-roll values to reduce excessive lateral load transfer;
- suspension or tire values only after diagnostics show steering and anti-roll
  tuning are insufficient.

No broad `Car_F` or `LandVehicle` patch is permitted.

### Presets

The server-global handling preset is one of:

- `Realistic Stable`: progressive steering, controlled body roll, and
  recoverable passive sliding;
- `Rally`: quicker response and greater permitted slip while retaining bounded
  rollover control;
- `Custom`: administrator-defined values within project safety bounds.

Custom values cover steering response, recentering, high-speed authority,
anti-roll strength, assistance activation speed, slip threshold, assistance
strength, and maximum correction.

### Assistance Modes

The server-global assisted handling mode is one of:

- `Off`: passive profile only;
- `Yaw damping`: reduce excessive yaw while preserving lateral slip;
- `Yaw + lateral damping`: reduce excessive yaw and lateral velocity;
- `Countersteering`: apply bounded corrective steering against excessive yaw.

Assistance is separate from ABS, slope rolling, handbrake, and direction
transition control. It cannot inject longitudinal speed.

### Runtime Controller

The stability controller runs only when:

- the vehicle is in the compatibility registry;
- the vehicle is local;
- the local player is the driver;
- the vehicle is grounded;
- the persistent handbrake is released;
- speed and slip exceed their configured activation thresholds.

The controller performs no correction while airborne or stationary. Each
correction is bounded by elapsed time, configured strength, and a maximum
per-update limit. Countersteering uses the most conservative preset strength
because it has the highest risk of conflicting with driver intent.

Initial implementation remains local. The CBA settings are server-global so
clients use the same selected preset and assistance mode. Multiplayer
authority and synchronization beyond the existing locality boundary remain
deferred.

### Data Flow

1. Resolve the driven vehicle against the compatibility registry.
2. Resolve the server-global preset and assistance mode.
3. Read steering input, speed, model-space velocity, heading change, grounded
   state, and handbrake state.
4. Estimate yaw rate and lateral slip from consecutive samples.
5. Reject the update when any activation guard fails.
6. Calculate one bounded recommendation for the selected assistance mode.
7. Apply only the permitted lateral/yaw correction; preserve longitudinal
   velocity and driver throttle/brake intent.
8. Emit optional diagnostic telemetry without altering controller behavior.

### Validation

Automated validation must verify:

- only registered vehicle families are eligible;
- presets resolve to bounded values;
- each assistance mode has isolated behavior tests;
- all activation guards fail closed;
- corrections preserve longitudinal velocity;
- no ABS, handbrake, slope, or direction-transition ownership is duplicated.

Manual SQA validation must cover:

- paved roads, dirt, grass, and slopes;
- gradual and sudden turns across low, medium, and high speeds;
- passive controlled slides and recovery;
- body-roll and rollover tendency;
- braking during turns;
- Drive/Reverse transitions;
- handbrake activation;
- each preset and assistance mode.

No claim of improved gameplay behavior is valid until SQA records the
corresponding in-game result.

## Out Of Scope

- Simulating physical steering torque or road feedback.
- Claiming actual EPS, ADAS, or steer-by-wire functionality.
- Global tire-grip increases.
- Native input injection.
- Multiplayer authority.
