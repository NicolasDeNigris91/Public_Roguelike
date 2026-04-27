# Architecture

A short tour of how the runtime is wired. The companion to `CLAUDE.md`
(which is the working agreement); this file is for someone opening the
repo for the first time and wanting the mental model in 10 minutes.

## Scene tree

```
Main (Node2D, scripts/main.gd)
├── World (Node2D)
│   ├── Dungeon (TileMapLayer)         scripts/dungeon.gd
│   ├── DecorationsLayer (Node2D)      torches, future props
│   ├── AltarsLayer (Node2D)           Altar instances
│   ├── ItemsLayer (Node2D)            ItemEntity instances
│   ├── EntityLayer (Node2D)
│   │   └── Player (Actor)             scripts/player.gd
│   └── EffectsLayer (Node2D)          damage numbers, projectiles, halo
├── TurnManager (Node)                 scripts/turn_manager.gd
├── Hotbar (CanvasLayer)               scripts/hotbar.gd
├── PauseMenu / GameOverScreen / DialogueOverlay (CanvasLayer)
├── CinematicsController (Node, runtime)   scripts/cinematics_controller.gd
└── FloorPopulator (Node, runtime)         scripts/floor_populator.gd
```

`main.gd` is the orchestrator. It owns the signal wiring between Player /
TurnManager / Hotbar / UI overlays and delegates two heavy concerns out:

- **CinematicsController** plays the rosary ending and the Lich-ending
  whisper hold. It owns the `awaiting_rosary_victory` / `victory_portal_pos`
  state so main can ask "did the player just step into the portal?".
- **FloorPopulator** spawns enemies, items, altars, the floor-28 shrine,
  the boss arena, and the Lich-ending ascension floors. It exposes
  `item_at(pos)`, `altar_at(pos)`, and `refresh_entity_visibility()` so
  main doesn't iterate the layer children directly.

Both controllers are `Node`s instantiated in `Main._ready()` and held as
fields. Main wires their signals (e.g. `floor_populator.boss_spawned ->
_on_boss_spawned`) and passes references in. Neither controller owns its
collaborators' lifecycle.

## Turn flow

The game is strictly turn-based. One player action = one full turn.

```
Player input (KEY_W/A/S/D, KEY_Q smite, KEY_E weapon ability)
  ├── Player._unhandled_input()
  ├── Combat.attack() OR move_to() OR try_smite() OR try_weapon_ability()
  └── Player._end_turn()
        └── emits turn_done

TurnManager._on_player_turn_done()
  ├── player.turn_active = false
  ├── for enemy in enemies:
  │     enemy.take_turn()                # may call Combat.attack
  └── player.turn_active = true
        (next input cycle starts)
```

Enemies outside the player's FOV are skipped each tick *unless* their
`always_takes_turn` flag is set (used by bosses so they don't freeze when
the player breaks line of sight).

`Player.turn_active` is the input gate. It is reset to `true` at the end
of every enemy phase. Scripted sequences (`CinematicsController`) need an
**orthogonal** lockout because TurnManager would otherwise stomp the
`false` they set; that lockout is `Player.in_cinematic`, checked first in
`Player._unhandled_input()`.

## Combat

`scripts/combat.gd` is a *static* class - no instance, no allocation per
turn. Two static fields hold scene-level references populated once at
boot (`Combat.effects_layer`, `Combat.world_node`) so spawn helpers can
reach the right Node2D for damage numbers and screen shake.

Damage formula:

```
dmg = max(1, attacker.atk - target.def + randi_range(-1, 1))
crit = randf() < 0.10  # then dmg *= 2
```

`ignore_def` skips the `target.def` term. This is reserved for explicitly
*magical* attacks: the Lich's phase 2/3 spells, the Demon Lord's infernal
fire ranged hurl, and the spectral ranged bolts of Wraith / Flayed Ghost
/ Mage / Salamander / Hellwing. Their *melee* counterparts respect DEF -
the player's armor investment has to matter when they close the distance.

## Autoloads

Five singletons declared in `project.godot [autoload]`:

| Autoload      | Backing scene/script                  | Purpose                                                  |
|---------------|---------------------------------------|----------------------------------------------------------|
| `AudioManager`| `scenes/audio_manager.tscn`           | SFX one-shots + music crossfade + mute                  |
| `RunStats`    | `scenes/run_stats.tscn`               | Per-run counters (kills, dmg, floor, ending flags)      |
| `SaveManager` | `scenes/save_manager.tscn`            | JSON read/write to `user://savegame.json`               |

`Combat`, `EnemyStats`, `ItemDB`, `SpriteDB`, and `ActConfig` are *not*
autoloads - they are `class_name` static-only classes, accessed as
`Combat.attack(...)` / `EnemyStats.STATS["wraith"]` / etc. They register
themselves in the GDScript class cache and are available from any script
without instantiation.

## Data flow

Stat tables are kept out of behaviour code so balance passes are
single-file diffs:

- `scripts/data/enemy_stats.gd` (`EnemyStats.STATS`): every non-boss
  enemy's hp / atk / def / vision plus a per-enemy `atk_per_act` scaling
  curve. `Enemy._ready()` calls `EnemyStats.apply(self, sprite_key)`,
  and `FloorPopulator._spawn_enemy()` reads
  `EnemyStats.atk_bonus_for(sprite_key, floor)` to apply the curve.
- `scripts/items/item_db.gd` (`ItemDB`): factory functions per item id
  (`ItemDB.short_sword()` etc.) plus `ItemDB.from_id(id)` for save
  restoration and `ItemDB.random_*` for spawn pools that are themselves
  act-aware (different drop tables in act 1 vs act 4).
- `scripts/sprite_db.gd` (`SpriteDB`): single source of `preload(...)`
  paths for actor / item / tile / effect / ability-icon textures. Keys
  are stable strings so the rest of the codebase doesn't carry asset
  paths.
- `scripts/act_config.gd` (`ActConfig`): floor → act / biome / boss
  mapping + altar caps per act. The only place that knows boss floors
  are 6/12/18/24/30.

## Save / load

Single slot at `user://savegame.json` (which Godot maps to
`localStorage` in the web export). Written by `SaveManager.save()` after
every successful descent; cleared on player death or final-boss victory.

```
{
  "version": 2,
  "floor": 12,
  "player": { hp, max_hp, faith, weapon_ability_cooldown, vision_range,
              vision_debuff_turns, bonus_atk, bonus_def, bonus_max_hp,
              altar_gains_this_act, timed_buffs,
              equipped: {weapon, armor, shield, ring, amulet} (item ids),
              bag: [item_ids],
              potion_stacks: [{item_id, count}] },
  "run_stats": {...},
  "altars": [{x, y, consumed}]
}
```

Mid-floor state (visible enemies, dropped items, FOV, the dungeon
itself) is **not** serialised. The next floor regenerates fresh on load.
This is intentional - saves are a "checkpoint at the staircase", not a
"freeze the entire scene" feature.

`CURRENT_VERSION` lives in `save_manager.gd`. A version mismatch silently
clears the save and starts a new run rather than risking a corrupt
restore. `_validate_item_paths()` also nukes the save if any equipped or
bagged item id no longer resolves through `ItemDB.from_id()` - a renamed
or removed item would otherwise crash on load.

## Deploy pipeline

The repo ships its own production build via Railway:

```
GitHub push to main
  └── Railway pulls
        └── Dockerfile (multi-stage)
              ├── stage 1: debian:bookworm-slim
              │   ├── installs Godot 4.6.2 + export templates
              │   └── runs `godot --headless --export-release "Web"`
              └── stage 2: caddy:2-alpine
                    └── COPY web_build/ + Caddyfile
        └── deploys container
```

`Caddyfile` sets the `Cross-Origin-Embedder-Policy: require-corp` and
`Cross-Origin-Opener-Policy: same-origin` headers that Godot 4 needs to
enable `SharedArrayBuffer` for the WASM runtime. Without those headers
the WASM bootstrap throws.

CI (`.github/workflows/ci.yml`) runs the four headless test scripts in
`scripts/tests/` on every push and every PR into `main`. It downloads the
same pinned Godot 4.6.2 binary so behaviour matches local.

## Gotchas

- **`class_name` rescan**: adding a new `class_name` Foo script and
  immediately running `--headless -s` may fail with "Identifier 'Foo' not
  declared". Fix: run `--headless --import --quit-after 2` once to prime
  the script class cache, or close + reopen the editor.
- **Editor cache vs runtime**: Godot can hold an old compiled version of
  a script in the running game even after a save. After significant
  refactors, close the editor (not just the game) before retesting.
- **`AudioManager` in `-s` tests**: autoloads are not registered when
  running headless test scripts via `-s`. The four tests tolerate the
  resulting compile-time stderr noise (the test still asserts and
  prints `PASS`); CI greps for the `PASS` line, not the exit code.
- **Pre-committed `.import` files**: Godot regenerates these on every
  `--import`. They show up modified after a fresh import even when no
  asset changed. Safe to commit or to leave dirty between sessions.
