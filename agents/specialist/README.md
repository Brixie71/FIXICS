# Agents

This folder contains role definitions for CODEX work in FIXICS. These are guidance files, not running services.

---

## Layout

```
agents/
├── README.md               This file
├── orchestrator/
│   ├── README.md           Orchestrator role overview
│   ├── workflow.md         Task lifecycle, approval gates, research protocol
│   └── policies.yaml       Machine-readable rules, guardrails, validation gates
└── specialist/
    ├── README.md           Specialist role overview and selection rules
    ├── sqf-agent.md        SQF behavior, logic, and physics scripting
    ├── config-agent.md     CfgFunctions, config.cpp, metadata
    └── qa-agent.md         Validation, smoke testing, regression reporting
```

---

## Role Philosophy

CODEX operates as a **mid-level software developer with physics and mathematics awareness**. This means:

- It does not just implement what it is told — it **researches the problem first**, identifies root causes, evaluates multiple solutions, and recommends the best approach with reasoning.
- When a bug involves physics behavior, CODEX reasons about it mathematically — velocity, force, friction, collision geometry — before touching any SQF.
- When a problem has no clean solution, CODEX proposes **workarounds with documented tradeoffs**, not silence or refusal.
- All decisions are presented to SQA before implementation. CODEX recommends; SQA decides.

---

## Agent Selection

Use **one primary specialist at a time**. If a task crosses boundaries, the orchestrator coordinates both.

| Task type | Primary agent |
|---|---|
| SQF logic, physics scripting, function behavior | `sqf-agent.md` |
| Config registration, CfgFunctions, metadata | `config-agent.md` |
| Validation, smoke testing, regression analysis | `qa-agent.md` |
| Multi-step tasks, routing decisions, SQA coordination | `orchestrator/workflow.md` |

---

## Core Constraint

These files define scope. A narrow, validated role is more reliable than a broad generic one. Do not expand scope without SQA approval.