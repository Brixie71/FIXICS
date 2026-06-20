# Vehicle Behavior Evidence Registry

## Purpose

This folder is the read-only Evidence Registry for FIXICS Phase 1 ground-vehicle behavior work.

It records structured telemetry evidence, vehicle behavior profiles, SQA evidence rows, and controlled behavior classifications before any future Runtime Assist or Config Research work is approved.

## Boundary

No gameplay behavior changes are authorized by this registry.

This registry does not change:

- ABS braking;
- slope rolling;
- ACE/FIXICS handbrake behavior;
- Drive/Reverse direction transition behavior;
- Vehicle Stability Assistance;
- Roll Stability Assist;
- native extension behavior;
- vehicle config values.

## Workflow

1. SQA runs a vehicle test.
2. FIXICS telemetry records the vehicle state.
3. The run is mapped to the telemetry snapshot schema.
4. SQA records an evidence matrix row.
5. The run receives one or more approved behavior classifications.
6. The vehicle behavior profile is updated.
7. The next action is selected:
   - `collect-more-telemetry`;
   - `runtime-assist-tuning`;
   - `config-research`;
   - `no-change`;
   - `blocked`.

## Relationship To Future Work

Runtime Assist work must use this registry to justify how ABS, slope, stability, roll, terrain, and driver-intent systems coordinate.

Config Research work must use this registry to justify any class-specific tire, suspension, anti-roll, mass, center-of-mass, steering, or gearbox investigation.
