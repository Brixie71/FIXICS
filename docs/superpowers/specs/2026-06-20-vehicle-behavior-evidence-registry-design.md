# Vehicle Behavior Evidence Registry - Design Spec

## Status

Architecture approved by SQA on 2026-06-20. Implementation requires a
separate approved plan.

## Purpose

Create a read-only Evidence Registry for FIXICS Phase 1 ground-vehicle
behavior work.

The registry standardizes how telemetry, vehicle profiles, settings, SQA
observations, and behavior classifications are recorded before any future
runtime assist tuning or config-class research is approved.

This is an evidence foundation, not a gameplay controller.

## Problem

FIXICS now has several active Phase 1 vehicle systems:

- slope rolling and idle autobrake bypass;
- ACE/FIXICS persistent handbrake;
- local driver-state controller;
- ABS-like service braking;
- optional native advisory math;
- Vehicle Stability Assistance;
- Roll Stability Assist;
- telemetry diagnostics.

These systems work, but future work needs a single source of truth for what
SQA observed and what the vehicle actually did. Without that structure, tire,
suspension, anti-roll, mass, center-of-mass, terrain, or runtime-assist changes
could be chosen from feel alone instead of from repeatable evidence.

## Goals

- Define one official telemetry snapshot schema for vehicle-behavior evidence.
- Define one vehicle behavior profile shape for observed and supported vehicle
  classes.
- Define a controlled behavior-classification vocabulary.
- Define an SQA evidence matrix format that connects telemetry logs to manual
  observations.
- Keep future Runtime Assist and Config Research designs dependent on this
  evidence layer.

## Non-Goals

- Do not change ABS behavior.
- Do not change slope rolling behavior.
- Do not change Vehicle Stability Assistance behavior.
- Do not change Roll Stability Assist behavior.
- Do not patch tires, suspension, anti-roll, mass, center of mass, steering,
  gearbox, or broad vehicle config.
- Do not add native-extension mutation.
- Do not add multiplayer authority or synchronization.
- Do not claim improved gameplay behavior from this registry alone.

## Architecture

The Evidence Registry has four parts.

### 1. Telemetry Snapshot Schema

A telemetry snapshot is one normalized vehicle sample. It should include:

- timestamp or sample index;
- vehicle class and display name when available;
- vehicle support status;
- driver state and input state;
- active preset and assist settings;
- world velocity;
- model-space velocity;
- speed;
- position;
- heading and yaw rate;
- pitch, bank, pitch rate, and bank rate;
- terrain normal and slope evidence;
- ground contact state;
- wheel hitpoint proxy data when available;
- active FIXICS handbrake, ABS, slope, stability, roll, and native-assist
  state values.

The schema may be implemented first as documentation and static validation.
Runtime conversion from existing log lines can be added later if SQA approves
tooling.

### 2. Vehicle Behavior Profile

A vehicle behavior profile records what FIXICS knows about one vehicle class or
family.

Required profile fields:

- vehicle class;
- vehicle family or source mod when known;
- support status;
- tested surfaces;
- tested speed bands;
- tested presets and assist modes;
- known config evidence;
- known behavior classifications;
- current recommendation.

Support status values:

- `observed-only`: vehicle has been seen in telemetry but is not supported;
- `telemetry-supported`: vehicle can be logged and studied;
- `runtime-assist-supported`: vehicle is approved for current runtime assist;
- `config-experiment-candidate`: vehicle has enough evidence for a possible
  class-specific config design.

Profiles do not authorize broad config patches. They only record evidence and
support status.

### 3. Behavior Classification

Each SQA run may be tagged with one or more classifications:

- `input-limitation`: steering or control input appears limited before the
  vehicle response is evaluated;
- `understeer`: steering input exists, but yaw/lateral response is
  insufficient;
- `oversteer`: yaw grows beyond intended path or rear rotation dominates;
- `rollover-risk`: bank angle or bank rate approaches rollover conditions;
- `braking-instability`: braking behavior causes instability or fails to slow
  predictably;
- `slope-autobrake`: slope rolling or low-speed autobrake behavior is the
  observed issue;
- `direction-transition`: Drive/Reverse handoff behavior is the observed issue;
- `terrain-interaction`: behavior changes materially by surface, slope,
  landing, or terrain transition.

New classification names require SQA approval so issue records remain
consistent.

### 4. SQA Evidence Matrix

An evidence matrix row connects one test run to one decision.

Minimum fields:

- date;
- SQA tester;
- vehicle class;
- terrain or surface;
- speed band;
- input pattern;
- active preset;
- assist mode;
- roll preset when relevant;
- telemetry log path;
- observed behavior;
- classification;
- recommended next action.

Recommended next actions:

- `collect-more-telemetry`;
- `runtime-assist-tuning`;
- `config-research`;
- `no-change`;
- `blocked`.

## Data Flow

1. SQA runs a vehicle test.
2. FIXICS captures telemetry through the existing logging path.
3. The run is mapped into the Telemetry Snapshot Schema.
4. SQA records one evidence matrix row with manual observation.
5. The run receives one or more behavior classifications.
6. The relevant Vehicle Behavior Profile is updated.
7. The profile recommends the next action:
   - collect more telemetry;
   - move to Runtime Assist design;
   - move to Config Research design;
   - make no change;
   - mark blocked until better evidence exists.

The registry does not automatically tune settings or change vehicle physics.

## Relationship To Existing Systems

ABS, slope rolling, handbrake, driver-state control, Vehicle Stability
Assistance, Roll Stability Assist, and native advisory math remain independent
runtime systems.

The Evidence Registry may reference their settings and output, but it does not
own their mutations. Each future behavior change still needs its own approved
design and plan.

## Validation

Automated validation should verify:

- the design spec exists;
- the approved support status values are present;
- the approved behavior classification values are present;
- the approved recommended next-action values are present;
- existing referenced functions or settings still exist when the registry names
  them;
- no implementation step in this first pass modifies ABS, slope, stability,
  roll, native, or config behavior.

Manual SQA validation should verify:

- one telemetry log can be mapped into the evidence matrix;
- two runs can be compared with the same fields;
- one vehicle profile can be updated from SQA evidence;
- the next action can be selected without changing gameplay behavior.

## Success Criteria

- FIXICS has one official vocabulary for vehicle behavior evidence.
- ISSUE-001 and later vehicle issues can reference structured observations.
- Runtime Assist design can consume the registry instead of inventing a new
  evidence format.
- Config Research design can use registry output to justify narrow
  class-specific work.
- No gameplay behavior changes occur in this step.

## Approval Boundary

This spec approves the Evidence Registry architecture only. Implementation
requires a separate plan and SQA approval before files are created or changed.
