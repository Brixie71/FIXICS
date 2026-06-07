# PhysX Command Reference

## Purpose

Use this as a quick map from FIXICS vehicle-physics questions to source-verified SQF commands. Verify current behavior against Bohemia documentation before designing a new fix.

Primary command index: https://community.bohemia.net/wiki/Category:Scripting_Commands_Arma_3

## Motion

| Command | Use | Locality | Source |
|---|---|---|---|
| `velocity _object` | world-space linear velocity in m/s | read anywhere | https://community.bohemia.net/wiki/velocity |
| `_object setVelocity _vector` | set world-space linear velocity in m/s | object local; global effect | https://community.bohemia.net/wiki/setVelocity |
| `velocityModelSpace _object` | model-space velocity; Y is forward | read anywhere | https://community.bohemia.net/wiki/velocityModelSpace |
| `_object setVelocityModelSpace _vector` | set model-space velocity | object local; global effect | https://community.bohemia.net/wiki/setVelocityModelSpace |
| `speed _object` | forward Y-axis speed in km/h | read anywhere | https://community.bohemia.net/wiki/speed |
| `angularVelocity _object` | world-space angular velocity in rad/s | read anywhere | https://community.bohemia.net/wiki/angularVelocity |
| `_object setAngularVelocity _vector` | set world-space angular velocity in rad/s | object local; global effect | https://community.bohemia.net/wiki/setAngularVelocity |
| `_object setAngularVelocityModelSpace _vector` | set model-space angular velocity | object local; global effect | https://community.bohemia.net/wiki/setAngularVelocityModelSpace |

## Mass And Center Of Mass

| Command | Use | Locality | Source |
|---|---|---|---|
| `getMass _object` | mass of a PhysX object | read anywhere | https://community.bohemia.net/wiki/getMass |
| `_object setMass _mass` | immediate mass change | local vehicle applies globally | https://community.bohemia.net/wiki/setMass |
| `_object setMass [_mass, _time]` | gradual mass change | local vehicle; remote clients only receive final mass unless executed there | https://community.bohemia.net/wiki/setMass |
| `getCenterOfMass _object` | center-of-mass offset from model center | read anywhere | https://community.bohemia.net/wiki/getCenterOfMass |
| `_object setCenterOfMass _offset` | immediate center-of-mass change | object local; global effect | https://community.bohemia.net/wiki/setCenterOfMass |
| `_object setCenterOfMass [_offset, _time]` | smooth center-of-mass transition | object local; global effect | https://community.bohemia.net/wiki/setCenterOfMass |

## Brakes And Forces

| Command | Use | Locality | Source |
|---|---|---|---|
| `_vehicle disableBrakes true` | disable stationary autobrake | local PhysX car/tank; global effect | https://community.bohemia.net/wiki/disableBrakes |
| `brakesDisabled _vehicle` | read autobrake-disabled state | read anywhere | https://community.bohemia.net/wiki/brakesDisabled |
| `_object addForce [_force, _position]` | apply force at model-space position | object local | https://community.bohemia.net/wiki/addForce |
| `_object addTorque _torque` | apply torque | object local | https://community.bohemia.net/wiki/addTorque |

`disableBrakes true` disables the stationary autobrake. It does not apply service braking. Bohemia documents that the autobrake can be re-enabled if the driver uses brakes.

## Terrain And Orientation

| Command | Use | Source |
|---|---|---|
| `surfaceNormal _position` | terrain normal for slope calculations | https://community.bohemia.net/wiki/surfaceNormal |
| `surfaceType _position` | surface class at a position | https://community.bohemia.net/wiki/surfaceType |
| `vectorDir _object` | world-space forward vector | https://community.bohemia.net/wiki/vectorDir |
| `vectorUp _object` | world-space up vector | https://community.bohemia.net/wiki/vectorUp |

## Project Notes

- Prefer model-space velocity for forward/reverse vehicle corrections.
- Use world-space velocity for downhill slope vectors or terrain-relative effects.
- Never mutate non-local vehicles directly.
- Commands not linked here are not accepted as supported FIXICS APIs until researched.
