# 🦑 Kraken Space Program (KSP)

> *The space game the community actually deserved.*

**Kraken Space Program** is an open-source, community-built aerospace sandbox — a spiritual successor to the game we all loved, rebuilt from scratch the right way. Fast. Moddable. Cross-platform. With multiplayer baked in from day one.

Named after the ancient evil that has claimed more rockets than any Kármán line ever will.

---

## Why does this exist?

Because we've been waiting long enough.

KSP1 was a miracle of indie development — a beautiful, physics-accurate sandbox built by a small passionate team that accidentally became one of the greatest games ever made. It was also held together with duct tape, running on an ancient Unity version, single-threaded, and slowly abandoned.

KSP2 promised to fix all of that. It didn't. It's dead now.

So we're doing it ourselves.

---

## What is this, exactly?

A from-scratch reimplementation of the KSP formula, built on a modern stack:

- **Rust** core engine — no garbage collector, no runtime overhead, actual multithreading
- **Bevy** game engine — ECS architecture that maps perfectly to part-based rocket simulation
- **wgpu** rendering — native Vulkan/Metal/DirectX/WebGL, cross-platform by default
- **Lua** modding API — every gameplay system scriptable, Factorio-style
- **Built-in multiplayer** — not a mod, not an afterthought, a first-class architectural decision

---

## Features (goals)

### The basics, done right
- Rocket building, orbital mechanics, atmospheric flight — all of it, accurate and satisfying
- N-body gravity as stock
- Realistic aerodynamics as stock (FAR-inspired)
- Life support as stock
- A solar system that is actually large

### The things KSP never delivered
- **Native multiplayer** — fly together, race, collaborate, destroy each other's rockets
- **Combat** — BD Armory-style weapons and vehicles built into the base game
- **A galaxy** — procedurally generated star systems, not just one tiny solar system
- **Performance** — 1000 parts without a slideshow. Multiple vessels on screen. Actual frames.

### The modding ecosystem KSP deserved
- Full Lua API — write your entire mod in Lua, no Rust required
- Stable API contracts — your mod doesn't break every update
- Open invitation — if your mod is good enough, it becomes stock

### Platform support
- Linux, Windows, macOS — all first-class, not afterthoughts
- No Unity, no .NET runtime, no garbage collector pausing your launch window

---

## The philosophy

**This project belongs to the community.**

There is no corporation here. There is no roadmap that gets abandoned. There is no early access where you pay $50 for a broken promise. The code is here, the issues are here, the decisions are made in public.

If the original contributors disappear, someone forks it and continues. That's the point.

Mod authors: your work doesn't have to live as a patch on top of a broken engine anymore. Come build it into the foundation. You'll be credited forever.

---

## Built on the shoulders of giants

This project stands on over a decade of community knowledge:

- The aerodynamics work pioneered by **Ferram Aerospace Research**
- The n-body physics of **Principia**
- The visual bar set by **Blackrack's** volumetric clouds and scatterer
- The realism pipeline built by the **Realism Overhaul** team
- Every mod author who ever loved this game enough to fix it themselves

The open-source mod ecosystem isn't a reference — it's a foundation.

---

## Current status

🚧 **Early development — Phase 0 mostly complete.**

The foundation is real. The architecture is established. A ball falls under gravity and bounces. It's not much to look at yet, but everything underneath it is built to last.

**Phase 0 — Foundation** *(mostly done)*
- [x] Bevy project skeleton — window opens, nothing crashes
- [x] Coordinate system types — `SimPosition` (f64), `WorldOrigin`, `LocalOrigin`, `render_sync.rs` as the single f64→f32 conversion point
- [x] Rapier physics integration — rigid bodies, fixed 50 Hz timestep, gravity
- [x] Module directory structure matching the full architecture in `DESIGN.md`
- [x] CI pipeline — `cargo fmt`, `cargo clippy`, `cargo test` on every push
- [ ] Physics interpolation — fixed timestep running, render interpolation between ticks pending
- [ ] wgpu pipeline smoke test

**Phase 1 — A Rocket Goes Up** *(not started)*

Part entities, joints, thrust, drag, staging, Krakensbane origin shifting, camera tracking, crash detection. A hardcoded multi-stage rocket launches, reaches space, and stages. No Lua yet.

The full roadmap lives in [`DESIGN.md`](DESIGN.md). Current tasks and decisions live in [`EXECUTION.md`](EXECUTION.md).

---

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first. It's short.

The quick version: the architecture is in `DESIGN.md`, the current tasks are in `EXECUTION.md`, and `CHECKLIST.md` is where you log tech debt when you cut corners. CI must be green before anything merges.

If you know Rust, Bevy, Lua, orbital mechanics, game networking, 3D art, or you just care about this existing — open an issue, start a discussion, submit a PR.

If you're a KSP mod author — your knowledge is more valuable than you know. Come talk to us.

If you're blackrack — please.

---

## Legal

Kraken Space Program is an original work. It is not a port of any existing game. It does not use assets, code, or proprietary content from any commercial product.

The name "KSP" is not owned by anyone. The Kraken is public domain. Space is free.

---

## License

This software is licensed under the Kraken License v1.0 — Tier 1

Copyright (c) 2026 Seraphina

Full license text: see [KRAKEN_LICENSE.md](KRAKEN_LICENSE.md)

---

*The Kraken takes everything eventually. We just named the game after it.*