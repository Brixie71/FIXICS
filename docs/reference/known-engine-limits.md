# Known Engine Limits

## Purpose

This file records current FIXICS engine-gap assumptions. Entries that rely on absence from documented commands are marked as project hypotheses and must be re-checked before new implementation.

Primary command index: https://community.bohemia.net/wiki/Category:Scripting_Commands_Arma_3

Vehicle config source: https://community.bohemia.net/wiki/Arma_3_Cars_Config_Guidelines

## Active Limits

### EL-001 - No documented direct gearbox state setter

- **Status:** Project hypothesis, checked against Bohemia command index on 2026-06-07.
- **What exists:** Config gearbox ratios and runtime velocity/brake commands.
- **What is missing:** A documented SQF command to directly set an Arma 3 PhysX car into Drive, Neutral, or Reverse.
- **Impact:** Reverse-to-Drive and Drive-to-Reverse behavior requires a local controller workaround.
- **Workaround direction:** Brake model-space longitudinal velocity, hold a short neutral handoff, then apply controlled launch velocity.

### EL-002 - No documented runtime per-wheel friction setter

- **Status:** Project hypothesis, checked against Bohemia command index on 2026-06-07.
- **What exists:** Config tire values and wheel damage commands.
- **What is missing:** A documented command equivalent to `setWheelFriction`.
- **Impact:** Runtime slope, traction, and ABS behavior must be approximated with velocity or force control.
- **Workaround direction:** Use local velocity corrections, class-specific config research, or damage-state logic only when approved.

### EL-003 - No documented vehicle collision restitution setter

- **Status:** Project hypothesis, checked against Bohemia command index on 2026-06-07.
- **What exists:** Collision event handlers expose collision information.
- **What is missing:** A documented command or config key to set restitution for vehicle collisions at runtime.
- **Impact:** Abnormal collision bounce fixes may need event-driven velocity clamps.
- **Workaround direction:** Detect abnormal post-collision velocity and apply bounded corrections.

### EL-004 - Suspension config is not a normal runtime SQF control surface

- **Status:** Project hypothesis, checked against Bohemia command index and Cars Config Guidelines on 2026-06-07.
- **What exists:** Suspension-related config values.
- **What is missing:** A documented command to adjust the standard car suspension config values during a mission.
- **Impact:** Bounce or suspension-bottoming corrections should start as class-specific config research.
- **Workaround direction:** Use config correction first; consider force-based damping only with SQA approval.

## Retired Or Corrected Claims

### Retired - Angular velocity cannot be read

Incorrect. Bohemia documents `angularVelocity` and `setAngularVelocity`.

Sources:

- https://community.bohemia.net/wiki/angularVelocity
- https://community.bohemia.net/wiki/setAngularVelocity

### Retired - Center of mass cannot be changed at runtime

Incorrect. Bohemia documents `setCenterOfMass`.

Source: https://community.bohemia.net/wiki/setCenterOfMass
