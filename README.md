# Roguelike

Turn-based grid roguelike — portfolio piece.

Built with **Godot 4.6 + GDScript**, exports to web (WASM).

## Status

Sprint 5 — full enemy roster (Slime, Skeleton, Archer, Mage) with ranged attacks and line-of-sight.

**Done:**
- Sprint 0 — initial setup, project skeleton
- Sprint 1 — grid, actor base class, player input, single room render
- Sprint 2 — turn-based combat (formula + crit, bump-to-attack, HP display, Slime enemy)
- Sprint 3a — procgen dungeon (rooms + L-corridors)
- Sprint 3b — stairs and floor descent (enemy count and ATK scale with depth)
- Sprint 3c — FOV (raycasting, memory-dimmed explored tiles, enemy visibility gating turns)
- Sprint 4a — item pickup and equip (Item/Weapon/Armor Resources, ItemEntity, Inventory)
- Sprint 4b — consumables and inventory UI (Healing + Greater Potion, CanvasLayer overlay, keys 1-8)
- Sprint 4c — special items (Ring of Life, Teleport Scroll, Long Sword, Plate Armor)
- Sprint 5a — Skeleton enemy + spawn progression + Hammer weapon
- Sprint 5b — line-of-sight + Archer (ranged kiter)
- Sprint 5c — Mage (ranged magic, ignores DEF) + Combat.ignore_def parameter

## Development

1. Install [Godot 4.6+](https://godotengine.org/download)
2. Open `project.godot` in the Godot editor
3. Press **F5** to run

## Plan

See full plan at: `~/.claude/plans/eu-to-com-interesse-eager-pudding.md`
