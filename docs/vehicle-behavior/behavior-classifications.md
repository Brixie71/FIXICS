# Behavior Classifications

## Purpose

Behavior classifications provide one controlled vocabulary for SQA vehicle behavior evidence.

New classification names require SQA approval before use in issue records, profiles, or evidence matrices.

## Approved Classifications

| Classification | Meaning | Typical Evidence |
|---|---|---|
| `input-limitation` | Steering or control input appears limited before vehicle response is evaluated. | Full input is present, but steering angle or response stops building earlier than expected. |
| `understeer` | Steering input exists, but yaw or lateral response is insufficient. | Vehicle continues forward despite visible or logged steering input. |
| `oversteer` | Yaw grows beyond the intended path or rear rotation dominates. | Rear rotation increases faster than the desired turn path. |
| `rollover-risk` | Bank angle or bank rate approaches rollover conditions. | High bank angle, high bank rate, wheel lift, tumble, or rollover event. |
| `braking-instability` | Braking behavior causes instability or fails to slow predictably. | ABS or service braking produces unwanted yaw, slide, or delayed stop. |
| `slope-autobrake` | Slope rolling or low-speed autobrake behavior is the observed issue. | Vehicle sticks on slope, rolls only after W/S input, or autobrake holds near zero speed. |
| `direction-transition` | Drive/Reverse handoff behavior is the observed issue. | W while reversing or S while driving does not enter expected service-brake/neutral/launch flow. |
| `terrain-interaction` | Behavior changes materially by surface, slope, landing, or terrain transition. | Same vehicle/settings behave differently across paved, dirt, grass, slope, airborne, or landing conditions. |

## Rules

- Use one or more approved classifications per evidence row.
- Record uncertainty in the observed behavior field, not by inventing a new classification.
- If no classification fits, set recommended next action to `blocked` and ask SQA to approve a new classification name.
