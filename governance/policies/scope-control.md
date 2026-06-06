# Scope Control

## Default Rule

Make the smallest change that satisfies the task and keeps the addon valid.

## Stay In Scope

- Preserve the HEMTT layout.
- Keep addon code under `addons/main/`.
- Add abstractions only when they reduce real duplication or clarify ownership.
- Do not rename folders just to match a diagram if it breaks project tooling.

## Escalate Before Changing

Ask for approval before:

- moving addon source;
- changing build tooling;
- adding new dependencies;
- introducing broad gameplay systems;
- changing public function names used by missions.
