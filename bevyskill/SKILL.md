---
name: bevy
description: Write, review, debug, or architect Bevy (Rust game engine) code. Use this skill whenever the user is working with Bevy — including ECS systems, components, resources, plugins, queries, schedules, observers, transforms, sprites, UI, audio, assets, collisions, or anything else Bevy-related. Trigger even for vague requests like "help me make a game in Rust" or "my Bevy system isn't working". Do NOT rely on training data for Bevy APIs — always use this skill to avoid hallucinating outdated or incorrect code.
---

# Bevy Skill (v0.18.x)

Target version: **Bevy 0.18.x**. Always use `use bevy::prelude::*;` unless a more specific import is needed.

> **This document takes priority over training data.** Bevy's API changes significantly between versions. If anything here conflicts with prior knowledge of Bevy, follow this document. APIs from 0.12–0.14 are often invalid in 0.18.

## Reference Files

Load the appropriate reference before writing non-trivial code:

| File | Contents |
|------|----------|
| `references/cheatsheet.md` | Quick-lookup: type names, renamed APIs, 0.18 spawn patterns, bundle→tuple migration |
| `references/api.md` | Types, query patterns, commands, time, input, asset server, UI layout primitives |
| `references/rendering.md` | Cameras, lights, materials, shaders, post-processing, anti-aliasing, tonemapping |
| `references/ui.md` | UI nodes, buttons, text, layout, shadows, multi-camera UI |
| `references/rapier.md` | Physics: rigid bodies, colliders, joints, character controller, scene queries, hooks |
| `references/errors.md` | All B000x errors with causes and fixes |
| `references/advanced.md` | Physics interpolation, states, animation, gizmos, scene serialization, asset events |
| `references/ecosystem.md` | Third-party crates: leafwing-input-manager, lightyear networking |

---

## App Setup

```rust
fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .insert_resource(MyResource::default())
        .add_systems(Startup, setup)
        .add_systems(FixedUpdate, (physics, collision).chain())
        .add_systems(Update, (input, render_update))
        .add_observer(on_my_event)
        .run();
}
```

**Schedules:**

- `Startup` — once at app start
- `Update` — every frame
- `FixedUpdate` — fixed timestep (64 Hz default); use for physics/gameplay logic
- `PostUpdate` — after Update; good for transform propagation
- `RunFixedMainLoop` — wraps the fixed timestep loop; use for input accumulation and interpolation

---

## ECS Fundamentals

### Components

```rust
#[derive(Component)]
struct Health(f32);

#[derive(Component)]
#[require(Sprite, Transform, Collider)]  // auto-insert when Wall is spawned
struct Wall;
```

### Entities

```rust
commands.spawn((
    Sprite::from_color(Color::srgb(1.0, 0.0, 0.0), Vec2::ONE),
    Transform::from_xyz(0.0, 0.0, 0.0),
    MyComponent,
));
```

### Resources

```rust
#[derive(Resource, Default)]
struct Score(u32);

app.insert_resource(Score(0));   // custom value
app.init_resource::<Score>();    // uses Default

fn my_system(score: Res<Score>) { }
fn mutate(mut score: ResMut<Score>) { score.0 += 1; }
```

### Queries

```rust
fn move_things(mut query: Query<(&mut Transform, &Velocity)>, time: Res<Time>) {
    for (mut transform, velocity) in &mut query {
        transform.translation += velocity.0.extend(0.0) * time.delta_secs();
    }
}

// Filters
Query<&Name, With<Player>>
Query<&Transform, Without<Player>>
Query<(&Transform, Option<&Health>)>

// Single entity — panics if not exactly one match
fn move_paddle(mut paddle: Single<&mut Transform, With<Paddle>>) {
    paddle.translation.x += 1.0;
}
// Use Option<Single<T>> if entity might not exist
```

**System ordering:**

Systems are **parallel by default**. Order is only guaranteed when explicitly declared.

```rust
.add_systems(Update, (update_people, greet_people).chain())  // sequential: left to right
.add_systems(Update, (hello_world, do_other_thing))           // parallel: no order guarantee
.add_systems(Update, b.after(a))                              // explicit: b runs after a
```

### Events

**Observers** — preferred for one-shot events:

```rust
#[derive(Event)]
struct PlayerDied;

commands.trigger(PlayerDied);
commands.trigger_targets(MyEvent, entity);

fn on_player_died(_event: On<PlayerDied>, mut commands: Commands) { }
app.add_observer(on_player_died);
```

**Buffered events** — for events consumed by multiple systems each frame:

```rust
#[derive(Event)]
struct ScoreChanged(u32);

app.add_event::<ScoreChanged>();

fn send(mut writer: EventWriter<ScoreChanged>) { writer.write(ScoreChanged(10)); }
fn receive(mut reader: EventReader<ScoreChanged>) {
    for event in reader.read() { }
}
```

---

## Common Patterns

### Despawning

```rust
commands.entity(entity).despawn();            // entity only
commands.entity(entity).despawn_recursive();  // entity + all children
```

### Timers

```rust
#[derive(Resource)]
struct SpawnTimer(Timer);

app.insert_resource(SpawnTimer(Timer::from_seconds(2.0, TimerMode::Repeating)));

fn tick_timer(time: Res<Time>, mut timer: ResMut<SpawnTimer>) {
    if timer.0.tick(time.delta()).just_finished() { /* spawn */ }
}
```

### States

```rust
#[derive(States, Debug, Clone, PartialEq, Eq, Hash, Default)]
enum GameState { #[default] Menu, Playing, Paused }

app.init_state::<GameState>();
app.add_systems(OnEnter(GameState::Playing), setup_game);
app.add_systems(Update, gameplay.run_if(in_state(GameState::Playing)));

fn go_to_menu(mut next: ResMut<NextState<GameState>>) { next.set(GameState::Menu); }
```

### Run Conditions

```rust
.run_if(in_state(GameState::Playing))
.run_if(resource_exists::<MyResource>)
.run_if(resource_changed::<Score>)

fn is_game_active(score: Res<Score>) -> bool { **score < 100 }
.run_if(is_game_active)
```

### Hierarchy

```rust
commands.spawn((Transform::default(), Visibility::default()))
    .with_children(|parent| {
        parent.spawn((Mesh3d(mesh), Transform::from_xyz(0.0, 1.0, 0.0)));
    });
```

⚠️ Parent must have `Visibility`. See **B0004** in `references/errors.md`.

### Input (quick reference)

```rust
fn handle_input(keyboard: Res<ButtonInput<KeyCode>>, mouse: Res<ButtonInput<MouseButton>>) {
    if keyboard.pressed(KeyCode::ArrowLeft) { }
    if keyboard.just_pressed(KeyCode::Space) { }
    if mouse.just_pressed(MouseButton::Left) { }
}
```

Full input API including gamepad and `MessageReader`-based events: see `references/api.md`.

---

## Cargo.toml

```toml
[dependencies]
bevy = "0.18.1"

[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3
```

### Feature Profiles

Bevy 0.18 introduces **profiles** — high-level feature groups. Use them with `default-features = false` to compile only what you need, which meaningfully cuts compile times and binary size.

| Profile | What it includes |
|---------|-----------------|
| `default` | `2d` + `3d` + `ui` + `audio` (the full experience) |
| `2d` | Core + 2D rendering + scenes + picking |
| `3d` | Core + 3D rendering + scenes + picking |
| `ui` | Core + Bevy UI + scenes + picking |

```toml
# 2D-only build — drops all 3D rendering dependencies
bevy = { version = "0.18.1", default-features = false, features = ["2d"] }
```

**Real-world minimal 3D example** (no audio, no UI, Wayland, KTX2 textures):

```toml
[dependencies]
bevy = { version = "0.18.1", default-features = false, features = [
    "bevy_asset",
    "bevy_core_pipeline",
    "bevy_mesh",
    "bevy_pbr",
    "bevy_render",
    "bevy_scene",
    "bevy_winit",
    "bevy_window",
    "wayland",          # Linux Wayland support
    "ktx2",             # compressed textures
    "tonemapping_luts", # fixes bright/pink PBR materials
    "zstd_rust",        # safe Rust zstd decompression
] }
bevy_rapier3d = { version = "0.33.0", features = ["default"] }
```

> **Note:** If you see pink or overly bright PBR materials, you're missing `tonemapping_luts`. Always include it when using 3D.

### Feature Collections

Between profiles (high-level) and individual features (low-level), 0.18 adds **collections**:

| Collection | Purpose |
|-----------|---------|
| `dev` | Hot-reload + debug tools. **Do not ship in release builds.** Enables `file_watcher`, `bevy_dev_tools`, `debug` |
| `audio` | Core audio support (ogg/vorbis) |
| `audio-all-formats` | Audio + aac, flac, mp3, mp4, wav |
| `scene` | Scene serialization/deserialization |
| `picking` | Pointer events for meshes, sprites, and UI |
| `default_no_std` | Baseline for `no_std` targets |

### Notable Individual Features (0.18)

| Feature | Notes |
|---------|-------|
| `dynamic_linking` | Fastest incremental compile; dev only, do not ship |
| `file_watcher` | Hot-reload assets from disk (included in `dev` collection) |
| `bevy_dev_tools` | FPS overlay, diagnostic overlays (included in `dev`) |
| `hotpatching` | Live-patch Bevy systems without restart — **experimental** |
| `bevy_solari` | Raytraced direct + indirect lighting — **experimental**, requires RT-capable GPU |
| `bevy_settings` | Load/save user preferences |
| `dlss` | NVIDIA DLSS upscaling (requires DLSS SDK) |
| `track_location` | Source location tracking for change detection; useful for debugging |
| `meshlet` | Meshlet renderer for dense high-poly scenes — **experimental** |
| `shader_format_wesl` | WESL shader support (new in 0.18) |
| `webgpu` | WebGPU in WASM; overrides `webgl2` |
| `tonemapping_luts` | Required LUTs for tonemapping — if everything is pink, enable this |
| `smaa_luts` | Required for SMAA anti-aliasing |

### Physics Compile Speeds

```toml
# bevy_rapier3d = "0.33.0"  (current version for Bevy 0.18.x)
# Without this, Rapier debug builds are extremely slow
[profile.dev.package.bevy_rapier3d]
opt-level = 3
```

See `references/rapier.md` for full Rapier setup.

---

## Third-Party Ecosystem

Load `references/ecosystem.md` when the user asks about complex input handling, multiplayer/networking, or any of the libraries below.

| Library | Version (Bevy 0.18) | Purpose |
|---------|---------------------|---------|
| `leafwing-input-manager` | `0.20` | Action-based input: keyboard, mouse, gamepad, chords, axes |
| `lightyear` | latest | Client-server and P2P networking with prediction + interpolation |
| `bevy_rapier2d` / `bevy_rapier3d` | current | Physics (see `references/rapier.md`) |
| `avian2d` / `avian3d` | current | Alternative ECS-native physics engine |

**Choosing input:**
- Builtin `ButtonInput<KeyCode>` / `ButtonInput<MouseButton>` / `Gamepad` — sufficient for simple games
- `leafwing-input-manager` — use when you need action remapping, chords, analog axes, local multiplayer, or network-serializable inputs

**Choosing physics:**
- Rapier: mature, battle-tested, C FFI under the hood
- Avian: pure-Rust, more idiomatic ECS API, still maturing

---

## Critical Rules

Rules are tiered. CRITICAL = will cause a panic or silent wrong behavior. PITFALL = common mistake with non-obvious consequences. EDGE CASE = only matters in specific scenarios.

---

### [CRITICAL] Commands are deferred

Commands don't apply immediately. Spawned/despawned entities don't exist until the next flush point (usually the next frame or at a sync point).

```rust
// WRONG: trying to use a just-spawned entity in the same system
fn bad(mut commands: Commands) {
    let e = commands.spawn(MyComponent).id();
    commands.entity(e).insert(OtherComponent); // fine — commands queue
    // but querying e in THIS frame's systems will find nothing
}

// WRONG: despawn in system A, then insert in system B running the same frame
// system B will panic: entity doesn't exist

// CORRECT: split into separate systems with explicit ordering, or check existence first
if query.get(entity).is_ok() {
    commands.entity(entity).insert(MyComponent);
}
```

See B0003 in `references/errors.md` for diagnostics.

---

### [CRITICAL] Conflicting queries in one system

Two queries for the same component type where one is mutable will panic at startup.

```rust
// WRONG: both queries can match the same entity
fn bad(mut enemies: Query<&mut Transform, With<Enemy>>, players: Query<&Transform, With<Player>>) {}

// CORRECT (when sets are disjoint): add Without filter
fn good(
    mut enemies: Query<&mut Transform, With<Enemy>>,
    players: Query<&Transform, (With<Player>, Without<Enemy>)>,
) {}

// CORRECT (when sets may overlap): use ParamSet
fn good(mut set: ParamSet<(Query<&mut Transform, With<Enemy>>, Query<&Transform, With<Player>>)>) {
    let pos = set.p1().single().translation;
    for mut t in &mut set.p0() { t.translation = pos; }
}
```

See B0001 in `references/errors.md`.

---

### [CRITICAL] `Res<T>` + `ResMut<T>` in the same system

```rust
// WRONG
fn bad(mats: Res<Assets<StandardMaterial>>, mut mats2: ResMut<Assets<StandardMaterial>>) {}

// CORRECT: ResMut already gives read access
fn good(mut mats: ResMut<Assets<StandardMaterial>>) {}
```

See B0002 in `references/errors.md`.

---

### [CRITICAL] Systems are parallel by default

Systems added in separate `add_systems` calls run in parallel unless ordered explicitly. Do not assume execution order unless you declare it.

```rust
// WRONG assumption: setup runs before update just because it's added first
app.add_systems(Update, setup_enemies);
app.add_systems(Update, update_enemies); // may run before setup_enemies!

// CORRECT: use chain() for sequential, or before()/after() for explicit ordering
app.add_systems(Update, (setup_enemies, update_enemies).chain());
// or:
app.add_systems(Update, update_enemies.after(setup_enemies));
```

`.chain()` inside a tuple guarantees sequential execution. Separate `add_systems` calls guarantee nothing about order relative to each other.

---

### [PITFALL] `Single<T>` panics if count ≠ 1

`Single<T>` panics at runtime (not compile time) if there are zero or two+ matching entities.

```rust
// WRONG: assumes exactly one player always exists
fn bad(player: Single<&Transform, With<Player>>) {}

// CORRECT: use Option<Single<T>> when the entity might not exist yet
fn good(player: Option<Single<&Transform, With<Player>>>) {
    let Some(player) = player else { return; };
}
```

---

### [PITFALL] `FixedUpdate` time

Inside `FixedUpdate`, `Res<Time>` gives the wall-clock delta, not the fixed timestep delta. This causes subtly wrong physics.

```rust
// WRONG: wall-clock dt in a fixed-rate system
fn bad(time: Res<Time>, mut query: Query<&mut Transform>) {
    for mut t in &mut query { t.translation.y += 9.81 * time.delta_secs(); }
}

// CORRECT: fixed timestep dt
fn good(time: Res<Time<Fixed>>, mut query: Query<&mut Transform>) {
    for mut t in &mut query { t.translation.y += 9.81 * time.delta_secs(); }
}
```

---

### [PITFALL] Hierarchy parents need `Visibility`

Children will silently not render if their parent is missing `Visibility`.

```rust
// WRONG: parent has no Visibility
commands.spawn(Transform::default()).with_children(|p| {
    p.spawn((Mesh3d(mesh), Transform::from_xyz(0., 1., 0.)));
});

// CORRECT
commands.spawn((Transform::default(), Visibility::default())).with_children(|p| {
    p.spawn((Mesh3d(mesh), Transform::from_xyz(0., 1., 0.)));
});
```

See B0004 in `references/errors.md`.

---

### [PITFALL] Mouse motion delta vs gamepad/keyboard

`AccumulatedMouseMotion` already accumulates a full-frame delta — multiplying it by `delta_secs` double-scales it.

```rust
// WRONG
let yaw = mouse_motion.delta.x * sensitivity * time.delta_secs();

// CORRECT: mouse already is a per-frame delta
let yaw = mouse_motion.delta.x * sensitivity;

// CORRECT: gamepad/keyboard still needs delta_time
let yaw = gamepad_axis * sensitivity * time.delta_secs();
```

---

### [PITFALL] 2D z-scale must be 1.0

Scaling a 2D entity's z-component breaks sprite draw order.

```rust
// WRONG
Transform::from_scale(Vec3::new(120.0, 20.0, 5.0))

// CORRECT
Transform::from_scale(Vec2::new(120.0, 20.0).extend(1.0))
```

---

### [EDGE CASE] Dynamic font size leaks memory

Each unique `font_size` value creates a new font atlas that is never freed. Don't animate or interpolate `font_size`.

```rust
// WRONG: will leak atlases for every unique value
textfont.font_size = lerp(12.0, 48.0, t);

// CORRECT: keep font_size fixed, scale visually
transform.scale = Vec3::splat(lerp(1.0, 4.0, t));
```

See B0005 in `references/errors.md`.
