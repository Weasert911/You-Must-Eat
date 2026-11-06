# X

Working repository for **YOU MUST EAT** — a single-player narrative stealth-FPS set in Dharavi, Mumbai. The design suite defines the game; the playable slice grows toward it.

## What's here

- `docs/` — the design suite: [Master GDD](docs/MASTER_GDD.md) (v4.0), [Demo Design Document](docs/DEMO_DESIGN_DOCUMENT.md) (vertical-slice scope), [Gameplay Spec](docs/GAMEPLAY_SPEC.md), [Technical Art Spec](docs/TECHNICAL_ART_SPEC.md). Superseded revisions live in `docs/archive/`.
- `GAME/game-files/` — the playable slice: first-person movement, weapon and pickup systems (pistol / SMG resources, weapon manager, hit feedback, crosshair), interaction prompts, FPS meter, and GameManager + save-system autoloads.

## Design pillars

- **Shadow Merge ("Hashing Shadows")** — shadows are sanctuary, light is exposure
- **High-contrast look** — black, white, and blood red; bold outlines through the comic-ink post-process pipeline
- **Underdog tension** — stealth first, combat optional and risky; not a power fantasy

## Status

Prototype. The slice proves weapon and movement systems while design work continues.

Built with **Godot 4.7** (Forward+), GDScript and GDShader.
