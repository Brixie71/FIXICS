# Telemetry Snapshot Schema

## Purpose

A telemetry snapshot is one normalized vehicle sample from a FIXICS vehicle behavior test.

This schema standardizes fields already produced or implied by the current telemetry logger so future analysis does not depend on one raw RPT line format.

## Required Fields

| Field | Meaning |
|---|---|
| `sampleIndex` | Sequential sample number inside one capture. |
| `sampleTime` | Runtime timestamp or elapsed seconds when available. |
| `vehicleClass` | `typeOf` class name for the tested vehicle. |
| `vehicleDisplayName` | Human-readable vehicle name when available. |
| `supportStatus` | Registry support state for this vehicle class. |
| `driverState` | Current FIXICS driver state such as Drive, Reverse, Coast, Service Brake, Neutral, or Handbrake. |
| `inputState` | Driver input evidence: forward, reverse, brake, handbrake, steering left/right, and throttle-related values when available. |
| `activeSettings` | Relevant FIXICS settings for ABS, slope, native assist, stability assist, roll assist, presets, and debug flags. |
| `worldVelocity` | World-space velocity from Arma. |
| `modelVelocity` | Vehicle model-space velocity, including lateral X, longitudinal Y, and vertical Z. |
| `speedKmh` | Vehicle speed in kilometers per hour. |
| `position` | World and/or ASL position when available. |
| `headingDeg` | Vehicle heading in degrees. |
| `yawRateDegPerSecond` | Derived yaw-rate estimate. |
| `pitchDeg` | Vehicle pitch angle. |
| `bankDeg` | Vehicle bank angle. |
| `pitchRateDegPerSecond` | Derived pitch-rate estimate. |
| `bankRateDegPerSecond` | Derived bank-rate estimate. |
| `terrainNormal` | Terrain normal under or near the vehicle. |
| `slopeEvidence` | Derived slope magnitude or downhill alignment evidence. |
| `isTouchingGround` | Ground contact state from Arma. |
| `wheelHitpointEvidence` | Wheel hitpoint proxy data from available hitpoint damage information. |

## Rules

- Missing values must be recorded as `not recorded`, not invented.
- A snapshot is evidence, not a correction command.
- The schema does not authorize vehicle mutation.
- New fields may be proposed during SQA review, but existing field names should remain stable once used by issue records.
