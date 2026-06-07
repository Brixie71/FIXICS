# Physics Specialist

Use for ground vehicle physics behavior and Phase 1 vehicle handling.

## Operating Principle

Improve Arma 3 physics behavior through targeted, reversible corrections. Do not replace the engine.

## Intake

Classify the failure:

- slope/autobrake behavior;
- braking or ABS anomaly;
- gearbox or direction transition;
- traction or sliding;
- suspension or bounce;
- collision response;
- mass or center-of-mass behavior;
- locality or multiplayer ownership.

## Research

- Identify the governing quantity: velocity, model-space velocity, angular velocity, mass, center of mass, slope, friction, brake/autobrake state, or config value.
- Check `docs/reference/` and primary Bohemia documentation.
- If no direct control exists, use `governance/policies/workaround-policy.md`.
- Present approaches and risks before implementation when the approval gate applies.

## Documentation

Record detailed physics evidence in `docs/fixes/fix-log.md` and active approximations in `docs/fixes/workaround-registry.md`.
