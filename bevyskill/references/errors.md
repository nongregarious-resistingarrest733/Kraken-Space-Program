# Bevy Common Errors & Warnings

## B0001 — Conflicting Queries (mutable + immutable on same component)

**Cause:** A system has both `Query<&mut T>` and `Query<&T>` for the same component `T`. Rust's borrow rules prevent this.

**Fix 1 — `Without<>` filter** (when queries target different entities):
```rust
// BROKEN:
fn system(mut enemies: Query<&mut Transform, With<Enemy>>, player: Query<&Transform, With<Player>>) {}

// FIXED — Player will never be an Enemy:
fn system(
    mut enemies: Query<&mut Transform, With<Enemy>>,
    player: Query<&Transform, (With<Player>, Without<Enemy>)>,
) {}
```

**Fix 2 — `ParamSet`** (when you can't guarantee disjoint sets):
```rust
fn system(mut transforms: ParamSet<(
    Query<&mut Transform, With<Enemy>>,
    Query<&Transform, With<Player>>,
)>) {
    let player_pos = transforms.p1().single().translation;
    for mut t in &mut transforms.p0() {
        t.translation = player_pos;
    }
}
```

---

## B0002 — Conflicting Resource Access (Res + ResMut same type)

**Cause:** System takes both `Res<T>` and `ResMut<T>` for same `T`.

**Fix:** Remove the `Res<T>` — `ResMut<T>` already gives you read access:
```rust
// BROKEN:
fn system(mut mats: ResMut<Assets<StandardMaterial>>, current: Res<Assets<StandardMaterial>>) {}

// FIXED:
fn system(mut mats: ResMut<Assets<StandardMaterial>>) {}
```

---

## B0003 — Command Applied to Despawned Entity

**Cause:** Commands are deferred. If system A despawns an entity and system B (running same frame) tries to use it, the command from B will panic on apply.

**Symptoms:**
```
error[B0003]: Could not insert a bundle (of type `MyComponent`) for entity 2v0 because it doesn't exist in this World.
```

**Debug:** Enable `RUST_LOG=bevy_ecs=debug` to see which system issued the despawn.

**Fix:** Coordinate system ordering with `.chain()` or `.before()`/`.after()`, or check entity existence before issuing commands:
```rust
if query.get(entity).is_ok() {
    commands.entity(entity).insert(MyComponent);
}
```

---

## B0004 — Missing Hierarchy Component (Visibility / GlobalTransform)

**Cause:** A child entity has `Visibility` or `GlobalTransform` but its parent doesn't.

**Symptoms:** Children not rendering, or transforms not propagating. Warning in console.

**Hierarchy-inherited components in Bevy:**
- `InheritedVisibility`
- `GlobalTransform`

**Fix:** Add `Visibility::default()` to all ancestor entities. (`GlobalTransform` is auto-added when `Transform` is added.)

```rust
// BROKEN — parent missing Visibility:
commands.spawn(Transform::default()).with_children(|p| {
    p.spawn((Mesh3d(...), Transform::from_xyz(0., 1., 0.)));
});

// FIXED:
commands.spawn((Transform::default(), Visibility::default())).with_children(|p| {
    p.spawn((Mesh3d(...), Transform::from_xyz(0., 1., 0.)));
});
```

---

## B0005 — Dynamic Font Size (Memory Leak Warning)

**Cause:** Each unique `font_size` value creates a new font atlas that is never freed. Animating/interpolating font size leaks memory.

**Fix:** Use `Transform::scale` to visually scale text instead:
```rust
// AVOID:
textfont.font_size = lerp(12.0, 48.0, t);

// PREFER:
transform.scale = Vec3::splat(lerp(1.0, 4.0, t));
```

To suppress the warning if intentional:
```rust
app.insert_resource(TextSettings {
    allow_dynamic_font_size: true,
    ..default()
});
```

---

## B0006 — Software Renderer Detected

**Cause:** GPU driver doesn't support hardware acceleration (missing/outdated driver, or running in a VM).

**Fix options:**
1. Update GPU driver.
2. Switch to OpenGL backend:
```rust
App::new()
    .add_plugins(DefaultPlugins.set(RenderPlugin {
        render_creation: WgpuSettings {
            backends: Some(Backends::GL),
            ..default()
        }.into(),
        ..default()
    }))
    .run();
```
3. Set via env var: `WGPU_BACKEND=gl` (or `vulkan`, `metal`, `dx12`)

---

## Other Common Issues

### "pink / magenta everything"
Tonemapping LUTs are missing. Add the `tonemapping_luts` cargo feature:
```toml
bevy = { version = "0.18.1", features = ["tonemapping_luts"] }
```
Or change tonemapping on the camera:
```rust
Camera3d { tonemapping: Tonemapping::None, ..default() }
```

### `Single<T>` panics at runtime
`Single<T>` panics if there are 0 or 2+ matching entities. Use `Option<Single<T>>` if the entity might not exist:
```rust
fn system(paddle: Option<Single<&mut Transform, With<Paddle>>>) {
    if let Some(paddle) = paddle { }
}
```

### System doesn't run
- Check it's registered with `add_systems`
- Check schedule (`Startup` vs `Update` vs `FixedUpdate`)
- Check run conditions (`run_if(...)`)
- Check it's not in a disabled state

### Assets not loading
- Path is relative to `assets/` folder in project root
- File must exist at `assets/sounds/hit.ogg` to load `"sounds/hit.ogg"`
- Loading is async — handle may not be ready immediately (check `AssetEvent::LoadedWithDependencies`)

### 2D sprite z-fighting / wrong draw order
- Use `translation.z` to control draw order (higher = in front)
- `scale.z` must always be `1.0` in 2D

### Slow compile times
Add to `Cargo.toml`:
```toml
[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3
```
And use `dynamic_linking` feature during dev:
```
cargo run --features bevy/dynamic_linking
```
