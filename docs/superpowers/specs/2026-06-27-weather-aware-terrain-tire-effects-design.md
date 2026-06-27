# Weather-Aware Terrain Tire Effects - Design

## Objective

Extend Terrain Tire Behavior with weather and wet-surface effects while keeping
Terrain Tire as the traction authority and Runtime Assist as the coordination
layer.

## Architecture

SQF gathers Arma weather and wind state:

- `rain`;
- `overcast`;
- `wind`;
- `windStr`.

Terrain Tire receives the weather state and maintains vehicle-local wetness
state:

- `FIXICS_weatherTerrainSaturation`;
- `FIXICS_weatherTerrainLastUpdate`.

The recommendation function returns weather multipliers and telemetry. Existing
Terrain Tire multipliers consume the weather values before Runtime Assist,
Controlled Slip, Stability, and Slope Assist read them.

## Saturation And Drying

Rain saturation changes gradually:

- when `rainLevel > 0`, saturation moves toward rain intensity over
  `FIXICS_weatherSaturationTime`, default `30s`;
- when `rainLevel == 0`, saturation dries toward zero over
  `FIXICS_weatherDryingTime`, default `180s`;
- drying never runs under active rain.

The state is local to the vehicle and is telemetry-visible.

## Terrain Effects

Wetness modifies traction by terrain:

- paved: wet grip reduction and hydroplaning risk;
- dirt/grass: shifts toward mud-like traction;
- sand: wet compaction slightly improves grip;
- rock: wet rock loses predictable grip;
- unknown: conservative reduction.

Hydroplaning applies only when:

- hydroplaning is enabled;
- terrain is paved;
- surface wetness is meaningful;
- speed exceeds `FIXICS_hydroplaningSpeedKmh`, default `70`.

## Wind First Pass

Wind is minimal in this phase:

- compute crosswind component against vehicle right vector;
- scale by vehicle profile approximation;
- expose `windHandlingMultiplier`;
- apply a small lateral delta through the existing stability path only.

No yaw moment, steering input changes, or gust timing are included.

## Settings

Add under `["FIXICS", "Terrain Tire"]`:

- `FIXICS_weatherTerrainEnabled`, default `true`;
- `FIXICS_weatherSaturationTime`, default `30`;
- `FIXICS_weatherDryingTime`, default `180`;
- `FIXICS_hydroplaningEnabled`, default `true`;
- `FIXICS_hydroplaningSpeedKmh`, default `70`;
- `FIXICS_windHandlingEnabled`, default `true`;
- `FIXICS_windHandlingStrength`, default `0.05`;
- `FIXICS_weatherDebugLogging`, default `false`.

## Telemetry

Add:

- `weatherTerrainEnabled`;
- `rainLevel`;
- `overcastLevel`;
- `surfaceWetness`;
- `terrainSaturation`;
- `weatherGripMultiplier`;
- `hydroplaningRisk`;
- `windStrength`;
- `windCrossComponent`;
- `windHandlingMultiplier`;
- `weatherReason`.

## SQA Validation

SQA should verify:

- 30s saturation is noticeable but not jarring;
- 180s drying only starts after rain stops;
- hydroplaning is visible around 70 km/h on wet paved roads;
- wet grass/dirt feels lower grip;
- wet sand feels slightly more compact;
- wind lateral delta does not fight WA-001 slope rolling.
