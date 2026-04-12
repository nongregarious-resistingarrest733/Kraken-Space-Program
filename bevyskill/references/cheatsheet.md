# Bevy 0.18 Cheat Sheet

Quick-lookup index of types, traits, and system params. For full patterns with code, see the other reference files.

> Bundles were removed in Bevy 0.15. Never use `SpriteBundle`, `Camera3dBundle`, `NodeBundle`, `DirectionalLightBundle`, etc. Spawn component tuples directly instead.

---

## App

| Item | What it does |
|------|--------------|
| `App::new()` | Entry point |
| `.add_plugins(DefaultPlugins)` | Standard plugin group (window, rendering, assets, input, ...) |
| `.add_plugins(MinimalPlugins)` | Headless / server builds |
| `.add_systems(Schedule, systems)` | Register systems |
| `.init_resource::<T>()` | Insert resource via `Default` or `FromWorld` |
| `.insert_resource(T)` | Insert specific resource instance |
| `.add_event::<T>()` | Register a buffered event type |
| `.add_observer(fn)` | Register a triggered (observer) event handler |
| `.init_state::<S>()` | Register a state machine |
| `.add_computed_state::<S>()` | Register a computed state |
| `.register_type::<T>()` | Register for reflection (scenes, inspectors) |

---

## Schedules

| Schedule | When |
|----------|------|
| `Startup` | Once at startup |
| `PreUpdate` | Before `Update` |
| `Update` | Every frame (main logic) |
| `PostUpdate` | After `Update` |
| `FixedPreUpdate` | Before fixed step |
| `FixedUpdate` | Fixed timestep (64 Hz default) |
| `FixedPostUpdate` | After fixed step |
| `RunFixedMainLoop` | Wraps the fixed loop; use for input accumulation / interpolation |
| `OnEnter(State)` | On state entry |
| `OnExit(State)` | On state exit |
| `OnTransition { from, to }` | On specific state transition |
| `First` / `Last` | Frame boundaries |

---

## ECS Core

| Item | Notes |
|------|-------|
| `#[derive(Component)]` | Marks a struct as a component |
| `#[derive(Resource)]` | Marks a struct as a resource |
| `#[derive(Event)]` | Marks a struct as an event |
| `#[derive(Bundle)]` | Groups components for spawning; mostly unnecessary in 0.18 |
| `#[require(A, B)]` on Component | Auto-inserts A and B when this component is spawned |
| `Entity` | A unique ID (handle to a set of components) |
| `World` | The actual data store; accessible in exclusive systems (`&mut World`) |
| `Commands` | Deferred queue for structural changes (spawn/despawn/insert/remove) |

---

## System Parameters

| Param | What you get |
|-------|-------------|
| `Query<T, F>` | Entities matching filter F, with access to components T |
| `Single<T, F>` | Exactly one matching entity; panics if 0 or 2+ |
| `Option<Single<T, F>>` | Safe version of `Single` |
| `Res<T>` | Shared read access to resource T |
| `ResMut<T>` | Mutable access to resource T |
| `Commands` | Deferred structural changes |
| `EventWriter<T>` | Write buffered events via `.write(T)` |
| `EventReader<T>` | Read buffered events via `.read()` |
| `Local<T>` | Per-system private state, persists across frames |
| `Gizmos` | Draw debug shapes |
| `Time` | Frame time; `.delta_secs()` for dt |
| `Time<Fixed>` | Fixed timestep dt; use inside `FixedUpdate` |
| `RealTime` | Unscaled wall-clock time, unaffected by time scaling/pause |
| `AssetServer` | Load assets from disk |
| `Assets<T>` | Storage for loaded assets; `.get(handle)`, `.add(asset)` |
| `ButtonInput<KeyCode>` | Keyboard state |
| `ButtonInput<MouseButton>` | Mouse button state |
| `AccumulatedMouseMotion` | Mouse delta this frame (do NOT multiply by delta_secs) |
| `AccumulatedMouseScroll` | Scroll delta this frame |

---

## Query Filters

| Filter | Selects |
|--------|---------|
| `With<T>` | Has component T |
| `Without<T>` | Does not have component T |
| `Added<T>` | T was added this frame |
| `Changed<T>` | T was mutated this frame (includes Added) |
| `AssetChanged<T>` | Component present AND its referenced asset changed |
| `Option<&T>` | May or may not have T (not a filter, included in data) |

Change detection on individual component refs:
```rust
for item: Ref<MyComp> in &query {
    if item.is_changed() { }
    if item.is_added() { }
}
```

---

## Spawning (0.18 style — no Bundles)

```rust
// 2D camera
commands.spawn(Camera2d);

// 3D camera
commands.spawn((Camera3d::default(), Transform::from_xyz(0., 5., 10.).looking_at(Vec3::ZERO, Vec3::Y)));

// 2D sprite (colored)
commands.spawn((
    Sprite::from_color(Color::srgb(1., 0., 0.), Vec2::splat(32.)),
    Transform::from_xyz(0., 0., 0.),
));

// 2D sprite (textured)
commands.spawn((
    Sprite::from_image(asset_server.load("player.png")),
    Transform::default(),
));

// 3D mesh
commands.spawn((
    Mesh3d(meshes.add(Cuboid::new(1., 1., 1.))),
    MeshMaterial3d(materials.add(StandardMaterial { base_color: Color::WHITE, ..default() })),
    Transform::default(),
));

// UI node
commands.spawn((
    Node { width: Val::Px(200.), height: Val::Px(50.), ..default() },
    BackgroundColor(Color::BLACK),
));

// Audio (looping music)
commands.spawn((
    AudioPlayer::new(asset_server.load("music.ogg")),
    PlaybackSettings::LOOP,
));

// GLTF scene
commands.spawn(SceneRoot(asset_server.load(
    GltfAssetLabel::Scene(0).from_asset("models/thing.gltf"),
)));

// World-space 2D text (not UI)
commands.spawn((
    Text2d::new("Label"),
    TextFont { font_size: 24.0, ..default() },
    TextColor(Color::WHITE),
    Transform::from_xyz(0., 1., 0.),
));
```

---

## Events

| Approach | Use when |
|----------|----------|
| `commands.trigger(E)` + `app.add_observer(fn)` | One-shot, targeted, immediate-ish; preferred for game events |
| `EventWriter<E>` + `EventReader<E>` | Consumed by multiple systems in the same frame |

---

## States

```rust
#[derive(States, Debug, Clone, PartialEq, Eq, Hash, Default)]
enum AppState { #[default] Menu, InGame }

// Computed state (derived from another state)
#[derive(Debug, Clone, Eq, PartialEq, Hash)]
struct InGame;
impl ComputedStates for InGame {
    type SourceStates = AppState;
    fn compute(src: AppState) -> Option<Self> {
        matches!(src, AppState::InGame).then_some(Self)
    }
}

// SubStates (only active when parent is in specific variant)
#[derive(SubStates, Debug, Clone, PartialEq, Eq, Hash, Default)]
#[source(AppState = AppState::InGame)]
enum PauseState { #[default] Running, Paused }
```

---

## Hierarchy

```rust
// Parent ← Child relationship
commands.spawn((Transform::default(), Visibility::default()))
    .with_children(|p| {
        p.spawn((Mesh3d(mesh), Transform::from_xyz(0., 1., 0.)));
    });

// 0.18 relationship component (alternative)
commands.spawn((MyChild, ChildOf(parent_entity)));

// Query hierarchy
fn sys(children: Query<&Children>, parent: Query<&Parent>) { }
fn sys(query: Query<Entity, With<MyComp>>, children_query: Query<&Children>) {
    for entity in &query {
        for child in children_query.iter_descendants(entity) { }
    }
}
```

---

## Visibility

```rust
Visibility::Visible    // always shown
Visibility::Hidden     // always hidden
Visibility::Inherited  // (default) follows parent
```

Requires `Visibility` on **all ancestors** in the hierarchy chain, or children silently won't render.

---

## Asset Loading

```rust
// Load (async, handle is valid immediately but data may not be ready yet)
let h: Handle<Image> = asset_server.load("textures/player.png");

// Check readiness
asset_server.is_loaded_with_dependencies(&handle)

// Access loaded data
fn sys(images: Res<Assets<Image>>, h: Res<MyHandle>) {
    if let Some(image) = images.get(&h.0) { }
}

// React to load events
fn sys(mut events: MessageReader<AssetEvent<Image>>) {
    for e in events.read() {
        if let AssetEvent::LoadedWithDependencies { id } = e { }
    }
}

// Load with settings (e.g. normal maps, repeat sampling)
asset_server.load_with_settings("normal.png", |s: &mut ImageLoaderSettings| {
    s.is_srgb = false;
});
```

---

## Reflection

```rust
#[derive(Component, Reflect, Default)]
#[reflect(Component)]
struct MyComp { pub x: f32 }

app.register_type::<MyComp>();

// Skip non-serializable fields
#[reflect(skip_serializing)]
pub runtime_handle: SomeHandle,
```

---

## Common Type Quick-Reference

| Type | Module / Notes |
|------|----------------|
| `Vec2`, `Vec3`, `Vec4` | `glam`; re-exported via `bevy::prelude` |
| `Quat` | `glam`; unit quaternion for rotation |
| `Transform` | Local position/rotation/scale |
| `GlobalTransform` | World-space; read-only for users |
| `Color` | `Color::srgb(r,g,b)`, `Color::srgba(r,g,b,a)` |
| `LinearRgba` | Linear color; used in emissive, shaders |
| `Val` | `Val::Px(f)`, `Val::Percent(f)`, `Val::Auto`, `Val::Vw(f)`, `Val::Vh(f)` |
| `px(f)` / `percent(f)` | Shorthand helpers for `Val::Px` / `Val::Percent` |
| `Timer` | `Timer::from_seconds(t, TimerMode::Repeating)` |
| `Stopwatch` | Elapsed time; `.tick(delta)`, `.elapsed_secs()` |
| `Name` | Debug label: `Name::new("Player")` |
| `Handle<T>` | Pointer to an asset |
| `Mesh` | Geometry data |
| `StandardMaterial` | Default PBR material |
| `AudioSource` | Audio asset |
| `AudioPlayer` | Component to play audio; pair with `PlaybackSettings` |
| `AudioSink` | Auto-inserted after playback starts; use to control playback |
| `Font` | Font asset |
| `Scene` / `DynamicScene` | Scene assets for serialization |
| `SceneRoot` | Spawns a scene as children of an entity (replaces `SceneBundle`) |
| `GltfAssetLabel` | `GltfAssetLabel::Scene(0).from_asset("path.gltf")` |
| `Text2d` | World-space 2D text component (not UI) |
| `ZIndex` | Local draw order among siblings in UI hierarchy |
| `GlobalZIndex` | Global draw order across entire UI tree |
| `Bloom` | HDR bloom post-processing; requires `Camera { hdr: true, .. }` |
| `EnvironmentMapLight` | IBL lighting component on Camera3d |
| `GlobalAmbientLight` | Resource for flat ambient light fill |

---

## Picking (bevy_picking, core in 0.18)

bevy_picking is integrated into Bevy core in 0.18. Use observers for pointer events:

```rust
commands.spawn((Mesh3d(mesh), MeshMaterial3d(mat)))
    .observe(|trigger: On<Pointer<Click>>| {
        println!("clicked entity {:?}", trigger.entity());
    });
```

---

## Commonly Confused / Renamed APIs

| Old / Wrong | Correct in 0.18 |
|-------------|-----------------|
| `Camera2dBundle` | `Camera2d` (component only) |
| `Camera3dBundle` | `Camera3d::default()` |
| `SpriteBundle` | `(Sprite, Transform)` tuple |
| `DirectionalLightBundle` | `(DirectionalLight, Transform)` tuple |
| `NodeBundle` | `Node` (component only) |
| `SceneBundle` | `SceneRoot(handle)` |
| `AudioBundle` | `(AudioPlayer::new(handle), PlaybackSettings::LOOP)` |
| `TextBundle` | `(Text, TextFont, TextColor, Node)` tuple |
| `Text2dBundle` | `(Text2d::new("..."), TextFont { .. }, TextColor(..), Transform)` |
| `time.delta_seconds()` | `time.delta_secs()` |
| `writer.send(e)` | `writer.write(e)` |
| `FogSettings` | `DistanceFog` |
| `Handle<Mesh>` on entity | `Mesh3d(handle)` |
| `Handle<StandardMaterial>` on entity | `MeshMaterial3d(handle)` |
| `despawn_recursive()` on non-children | `despawn()` is fine; `despawn_recursive()` for hierarchies |
| `Children` / `Parent` traversal | `children_query.iter_descendants(entity)` |
