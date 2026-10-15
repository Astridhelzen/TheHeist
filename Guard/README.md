# Guard (`guard.gd`)

The guard is a `CharacterBody3D` controlled by a **finite state machine**. It patrols, reacts to noise, and chases the player when it sees them. Pathfinding uses `NavigationAgent3D`, which finds the shortest path with **A\*** over the level's navmesh.

## Required child nodes

| Node | Type | Used for |
|---|---|---|
| `NavigationAgent3D` | NavigationAgent3D | Pathfinding (A* on the navmesh) |
| `AnimationPlayer` | AnimationPlayer | Needs the animations `Idle`, `Walk`, `Run`, `Attack` |
| `VisionRay` | RayCast3D | Line-of-sight check to the player |
| `Flashlight` | SpotLight3D | The guard's vision cone in the dark |

## States

| State | What the guard does | Leaves when… |
|---|---|---|
| **IDLE** | Stands still. Used when it has no patrol points. | Sees the player → CHASE |
| **PATROL** | Walks between `patrol_points`, stops and looks around at each one. | Sees the player → CHASE · Hears a noise → INVESTIGATE |
| **INVESTIGATE** | Walks to a position (a noise, or where it lost the player), then looks around. | Sees the player → CHASE · Done looking → RETURN |
| **CHASE** | Runs after the player while it can see them. | Close enough → ATTACK · Loses sight → PURSUE |
| **PURSUE** | Keeps running after the player for a short time without seeing them. | Sees the player → CHASE · Time runs out → INVESTIGATE (player's last position) |
| **ATTACK** | Stops and faces the player. If the player stays close for `catch_time`, the player is caught. | Player escapes → CHASE |
| **RETURN** | Walks back to where it left its patrol route. | Arrives → PATROL · Sees the player → CHASE |
| **RUSH** | The alarm went off: runs to the vault (where the loot was). Does not know where the player is. | Sees the player → CHASE · Arrives → INVESTIGATE |

### Hearing

When the guard hears a noise (`hear_noise()`), it first **stops and turns towards the sound**. If it sees the player after turning → CHASE. Otherwise it goes to INVESTIGATE the noise. Noise is ignored during CHASE, PURSUE and ATTACK. During RUSH the guard turns towards the sound but then keeps running to the vault.

### Alarm

When the loot is taken, `alert()` is called. The bank lights turn on, so the guard can now see in a **wide field of view**, not only in its flashlight cone. Walls still block sight. If `rush_to_vault_on_alarm` is on, the guard enters RUSH.

## Variables (Inspector)

### General

| Variable | Default | Description |
|---|---|---|
| `patrol_points` | `[]` | The points the guard walks between. Empty = IDLE. |
| `speed_walk` | `1.7` | Walking speed (PATROL, INVESTIGATE, RETURN). |
| `speed_run` | `3.0` | Running speed (CHASE, PURSUE, RUSH). |
| `attack_range` | `2.0` | How close the player must be for ATTACK. |
| `investigate_wait_time` | `4.0` | Seconds spent looking around when investigating. |
| `patrol_wait_time` | `3.0` | Seconds spent looking around at each patrol point. |
| `patrol_look_angle` | `40.0` | How far (degrees) it looks to each side at patrol points. |
| `update_interval` | `0.2` | How often (seconds) the path target is updated. |
| `look_around_angle` | `70.0` | How far (degrees) it looks to each side when investigating. |
| `pursue_time` | `2.5` | Seconds it keeps following the player after losing sight. |
| `aim_height` | `0.8` | Height on the player that the vision ray aims at. |
| `catch_time` | `0.4` | Seconds the player must stay within range to be caught. |
| `escape_margin` | `1.2` | The player escapes ATTACK beyond `attack_range × escape_margin`. |

### Ficklampa (flashlight)

| Variable | Default | Description |
|---|---|---|
| `spotted_color` | red | Flashlight colour when the player is in the light. |
| `color_fade_speed` | `8.0` | How fast the colour changes. Higher = faster. |

### Hörsel (hearing)

| Variable | Default | Description |
|---|---|---|
| `hear_turn_time` | `0.8` | Seconds the guard stops and looks towards a noise. |
| `hear_turn_speed` | `8.0` | How fast it turns towards the noise. Higher = faster. |
| `hear_turn_min_angle` | `30.0` | If already facing within this angle (degrees), it doesn't turn again. |

### När lamporna tänds (when the lights turn on)

| Variable | Default | Description |
|---|---|---|
| `lit_view_angle` | `75.0` | Field of view to each side (degrees) after the alarm. `180` = sees all around. |
| `lit_view_range` | `20.0` | How far (metres) it can see after the alarm. |
| `rush_to_vault_on_alarm` | `true` | Run to the vault when the alarm goes off. |

## Signals and functions used by other scripts

| Name | Description |
|---|---|
| `signal player_caught` | Emitted when the player is caught. `caught.gd` listens to it. |
| `hear_noise(pos)` | Called by the player's `noise_emitter.gd` on each audible footstep. |
| `alert(loot_position)` | Connected automatically to every node in the `loot` group (`taken` signal). |

The guard adds itself to the group **`guards`**, which other scripts use to find all guards.
