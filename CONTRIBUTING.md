# Contributing

This is a portfolio piece - a turn-based grid roguelike built with Godot 4.6.
Contributions that move it forward:

- **Bug fixes.** Anything where the implementation diverges from the documented
  combat / FOV / procgen rules in the README.
- **Sprint additions.** New enemies, items, or floors that fit the existing
  systems (combat formula, AI base classes, item/weapon/armor resources).
- **Performance.** Frame-rate or web-export improvements.
- **Quality of life.** UI clarity, accessibility (color-blind palette,
  screen-reader friendly text where possible).

If you are reporting a security issue, do **not** open a public PR or issue;
follow [SECURITY.md](./SECURITY.md).

## Local environment

Prerequisites:

- [Godot 4.6+](https://godotengine.org/download)

```text
1. Open project.godot in the Godot editor
2. F5 to run
```

For headless test runs, see `.github/workflows/ci.yml` - it downloads
Godot, opens the project headless, and runs the smoke + unit suite.

## Test bar

| Change touches                  | Required                                     |
| ------------------------------- | -------------------------------------------- |
| Combat / FOV / procgen / AI     | New unit tests covering the rule change      |
| UI / scenes                     | Manual playthrough through at least one floor |
| Web export pipeline             | Local web export builds and loads             |

CI runs the smoke + unit suite on every PR.

## Style

- GDScript: typed everywhere (`var x: int = 0`), `_ready()` over `_init()` for
  scene setup, signals lower-snake-case.
- Resources for data (Item, Weapon, Armor, Enemy stats). No hard-coded
  numbers in scripts where a Resource exists.
- Combat math goes through `Combat.*` so future tuning changes one file.
- Commits: conventional commits (`type(scope): summary`), lower-case,
  imperative mood. Match the existing log style. No AI-attribution
  trailers.

## License

By submitting a PR, you agree that your contribution is licensed under the
[MIT License](./LICENSE) of this project.
