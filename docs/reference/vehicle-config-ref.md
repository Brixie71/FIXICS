# Vehicle Config Reference

## Purpose

Use this as a source-verified map of Arma 3 ground-vehicle config values relevant to FIXICS. It does not authorize broad config patches by itself.

Primary source: https://community.bohemia.net/wiki/Arma_3_Cars_Config_Guidelines

Additional source: https://community.bohemia.net/wiki/Arma_3:_Vehicle_Handling_Configuration

## Core Vehicle Values

| Config value | Meaning | Source note |
|---|---|---|
| `simulation = "carx"` | PhysX car simulation type | Cars Config Guidelines |
| `mass` | vehicle mass in kg | config-level baseline; runtime mass can be read with `getMass` |
| `centerOfMass[]` | config center-of-mass offset | runtime adjustment exists through `setCenterOfMass` |
| `brakeIdleSpeed` | speed in m/s under which brakes are automatically applied | Cars Config Guidelines |
| `thrustDelay` | seconds for thrust to ramp from 0 to 1 when standing still | Cars Config Guidelines |
| `idleRpm`, `redRpm` | idle and maximum engine RPM values | Cars Config Guidelines |

## Gearbox Values

| Config value | Meaning |
|---|---|
| `complexGearbox` | PhysX gearbox data container |
| `GearboxRatios[]` | includes one reverse ratio, one neutral zero ratio, and ordered forward ratios |
| `TransmissionRatios[]` | gearbox multiplier set |
| `moveOffGear` | gear used when moving off from stationary |
| `changeGearMinEffectivity[]` | gear-hold threshold by gear |
| `switchTime` | duration of a gear change in seconds |
| `latency` | minimum time between automatic gear changes |

FIXICS does not currently patch gearbox config. The local SQF controller works around direction handoff at runtime.

## Tires, Suspension, And Steering

Only use these after class-specific research and SQA approval:

| Area | Values |
|---|---|
| Tire longitudinal behavior | `longitudinalStiffnessPerUnitGravity`, `frictionVsSlipGraph[]` |
| Tire lateral behavior | `latStiffX`, `latStiffY` |
| Suspension | `sprungMass`, `springStrength`, `springDamperRate`, `maxCompression`, `maxDroop` |
| Anti-roll | `antiRollbarForceCoef`, `antiRollbarForceLimit`, `antiRollbarSpeedMin`, `antiRollbarSpeedMax` |
| Player steering | `PlayerSteeringCoefficients` |

## Rules

- Target the narrowest vehicle class that exhibits the defect.
- Do not patch `Car_F`, `Tank_F`, or other broad parents without SQA approval.
- Record before/after class values when a config correction is approved.
- Config values are load-time behavior; use SQF only when runtime adaptation is required.
