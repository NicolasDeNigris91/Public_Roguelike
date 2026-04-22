# Roguelike

Turn-based grid roguelike — portfolio piece.

Built with **Godot 4.6 + GDScript**, exports to web (WASM).

## Status

Sprint 3 — procedural dungeons with stairs, field of view, and multi-floor descent. Placeholder rendering via `_draw()`; real tileset arrives in later polish.

**Done:**
- Sprint 0 — initial setup, project skeleton
- Sprint 1 — grid, actor base class, player input, single room render
- Sprint 2 — turn-based combat (formula + crit, bump-to-attack, HP display, Slime enemy)
- Sprint 3a — procgen dungeon (rooms + L-corridors)
- Sprint 3b — stairs and floor descent (enemy count and ATK scale with depth)
- Sprint 3c — FOV (raycasting, memory-dimmed explored tiles, enemy visibility gating turns)

## Development

1. Install [Godot 4.6+](https://godotengine.org/download)
2. Open `project.godot` in the Godot editor
3. Press **F5** to run

## Plan

See full plan at: `~/.claude/plans/eu-to-com-interesse-eager-pudding.md`
