# Bevy API Reference (v0.18.x)

## Transform

```rust
Transform::default()
Transform::from_translation(Vec3::new(x, y, z))
Transform::from_xyz(x, y, z)
Transform::from_rotation(Quat::from_rotation_z(angle))

// Builder methods (chainable)
Transform::from_xyz(0., 0., 0.)
    .with_scale(Vec3::new(w, h, 1.0))
    .with_rotation(Quat::from_rotation_z(0.5))

// Fields
transform.translation: Vec3
transform.rotation: Quat
transform.scale: Vec3

// 2D: z-scale MUST be 1.0 or sprite ordering breaks
// 2D: translation.z controls draw order (higher = in front)
```

---

## Vec Types

```rust
Vec2::new(x, y)
Vec2::splat(v)     // Vec2::new(v, v)
Vec2::ONE          // Vec2::new(1.0, 1.0)
Vec2::ZERO

Vec3::new(x, y, z)
Vec3::splat(v)
Vec3::ZERO
Vec3::Y            // Vec3::new(0.0, 1.0, 0.0)

// Conversions
vec2.extend(z) -> Vec3
vec3.truncate() -> Vec2
vec3.xy() -> Vec2
```

---

## Queries

### Basic Patterns

```rust
Query<(&mut Transform, &Velocity)>
Query<&Name, With<Player>>
Query<&Transform, Without<Player>>
Query<(&Transform, Option<&Health>)>

// Single entity (panics if not exactly one match)
fn system(mut paddle: Single<&mut Transform, With<Paddle>>) { }
// Safe version:
fn system(paddle: Option<Single<&mut Transform, With<Paddle>>>) { }
```

### Fetch Specific Entity

```rust
if let Ok(transform) = query.get(entity) { }
if let Ok(mut transform) = query.get_mut(entity) { }
query.contains(entity) -> bool
```

### ParamSet (Conflicting Queries)

```rust
fn system(mut set: ParamSet<(
    Query<&mut Transform, With<Enemy>>,
    Query<&Transform, With<Player>>,
)>) {
    let player_pos = set.p1().single().translation;
    for mut t in &mut set.p0() { t.translation = player_pos; }
}
```

### Combinations

```rust
for [a, b] in query.iter_combinations() { }
```

---

## Commands

```rust
// Spawn
let entity = commands.spawn((ComponentA, ComponentB)).id();

// Modify
commands.entity(entity)
    .insert(NewComponent)
    .remove::<OldComponent>()
    .despawn();

// Despawn
commands.entity(entity).despawn();
commands.entity(entity).despawn_recursive();  // + children

// Resources
commands.insert_resource(MyResource::default());

// Events
commands.trigger(MyEvent);
commands.trigger_targets(MyEvent, entity);
```

---

## Time

```rust
// Every-frame time
fn system(time: Res<Time>) {
    let dt = time.delta_secs();
    let elapsed = time.elapsed_secs();
}

// Inside FixedUpdate — use Time<Fixed> for the fixed timestep dt
fn fixed_system(time: Res<Time<Fixed>>) {
    let dt = time.delta_secs();
}
```

---

## Input

### Keyboard / Mouse

```rust
fn input(kb: Res<ButtonInput<KeyCode>>) {
    kb.pressed(KeyCode::Space)       // held down
    kb.just_pressed(KeyCode::Space)  // first frame pressed
    kb.just_released(KeyCode::Space) // first frame released
}

fn mouse(mouse: Res<ButtonInput<MouseButton>>) {
    mouse.just_pressed(MouseButton::Left)
    mouse.pressed(MouseButton::Right)
}
```

### Gamepad

```rust
fn gamepad(gamepads: Query<&Gamepad>) {
    for gamepad in &gamepads {
        if gamepad.just_pressed(GamepadButton::South) { }
        let axis_value = gamepad.get(GamepadAxis::LeftStickX).unwrap_or(0.0);
    }
}
```

### Mouse Motion / Scroll

```rust
use bevy::input::mouse::{AccumulatedMouseMotion, AccumulatedMouseScroll};

fn mouse_look(motion: Res<AccumulatedMouseMotion>) {
    let delta = motion.delta;  // Do NOT multiply by delta_time
}

fn scroll(scroll: Res<AccumulatedMouseScroll>) {
    if scroll.delta != Vec2::ZERO { }
}
```

---

## Asset Server

```rust
fn setup(asset_server: Res<AssetServer>) {
    // Paths relative to `assets/` folder
    let image: Handle<Image> = asset_server.load("textures/player.png");
    let sound: Handle<AudioSource> = asset_server.load("sounds/music.ogg");
    let font: Handle<Font> = asset_server.load("fonts/FiraSans-Bold.ttf");
    let scene: Handle<Scene> = asset_server.load("models/thing.gltf#Scene0");
}
```

---

## Audio

Requires the `bevy_audio` feature (enabled by default).

```rust
// Spawn a looping background track
fn play_music(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn((
        AudioPlayer::new(asset_server.load("sounds/music.ogg")),
        PlaybackSettings::LOOP,
    ));
}

// One-shot sound effect
commands.spawn((
    AudioPlayer::new(asset_server.load("sounds/hit.ogg")),
    PlaybackSettings::DESPAWN,  // entity despawns when sound finishes
));
```

**`PlaybackSettings` presets:**

| Preset | Behavior |
|--------|---------|
| `PlaybackSettings::ONCE` | Play once, entity persists after |
| `PlaybackSettings::LOOP` | Loop forever |
| `PlaybackSettings::DESPAWN` | Play once, despawn entity when done |
| `PlaybackSettings::REMOVE` | Play once, remove `AudioPlayer` when done |

```rust
// Custom settings
PlaybackSettings {
    mode: bevy::audio::PlaybackMode::Loop,
    volume: Volume::new(0.5),
    speed: 1.0,
    paused: false,
    ..default()
}
```

**Controlling playback at runtime** — query the `AudioSink` component, which is inserted automatically once playback starts:

```rust
fn toggle_pause(sink: Query<&AudioSink, With<MyMusic>>) {
    if let Ok(sink) = sink.single() {
        sink.toggle();
    }
}
```

`AudioSink` methods: `.pause()`, `.play()`, `.toggle()`, `.stop()`, `.set_volume(f32)`, `.set_speed(f32)`, `.is_paused() -> bool`.

---

## Scene Loading

`SceneRoot` replaces the old `SceneBundle`. Attach it to an entity to instantiate a scene as children.

```rust
// Load and spawn a plain Bevy scene
commands.spawn(SceneRoot(asset_server.load("levels/level1.scn.ron")));

// Load a GLTF scene by index (most common: index 0)
commands.spawn((
    SceneRoot(asset_server.load(
        GltfAssetLabel::Scene(0).from_asset("models/player.gltf"),
    )),
    Transform::from_xyz(0.0, 0.0, 0.0),
));

// Load with named scene label
asset_server.load("models/player.gltf#Scene0")  // string form also works
```

**Other `GltfAssetLabel` variants:**

```rust
GltfAssetLabel::Scene(0)        // scenes
GltfAssetLabel::Mesh(0)         // raw mesh data
GltfAssetLabel::Animation(0)    // animation clips
```

**Reacting when a spawned scene is ready:**

```rust
fn on_scene_ready(
    mut events: EventReader<SceneInstanceReady>,
    children: Query<&Children>,
) {
    for event in events.read() {
        // event.parent — the entity SceneRoot was on
        for child in children.iter_descendants(event.parent) { }
    }
}
```

---

## Sprite

```rust
Sprite::from_color(Color, Vec2)       // colored rectangle
Sprite::from_image(Handle<Image>)     // textured

Sprite {
    color: Color,
    flip_x: bool,
    flip_y: bool,
    custom_size: Option<Vec2>,
    ..default()
}

// Tiling
Sprite {
    image: asset_server.load("tile.png"),
    image_mode: SpriteImageMode::Tiled {
        tile_x: true,
        tile_y: true,
        stretch_value: 1.0,  // 0.5 = tile every half-image-width
    },
    ..default()
}
```

**Texture atlas (sprite sheets):**

```rust
// Build atlas layout
let layout = TextureAtlasLayout::from_grid(UVec2::new(32, 32), 4, 4, None, None);
let layout_handle = texture_atlas_layouts.add(layout);

commands.spawn((
    Sprite::from_image(asset_server.load("spritesheet.png")),
    TextureAtlas { layout: layout_handle, index: 0 },
));

// Animate by changing index each frame
fn animate(mut query: Query<&mut TextureAtlas>, time: Res<Time>) {
    for mut atlas in &mut query {
        atlas.index = (time.elapsed_secs() * 8.0) as usize % 16;
    }
}
```

---

## 2D Mesh + Material

```rust
// Circle
Mesh2d(meshes.add(Circle::default()))
// Scale via Transform to set radius, or:
meshes.add(Circle::new(radius))

// Rectangle
Mesh2d(meshes.add(Rectangle::new(width, height)))

// Material
MeshMaterial2d(materials.add(Color::srgb(r, g, b)))
MeshMaterial2d(materials.add(ColorMaterial { color, ..default() }))
```

---

## 3D Mesh + Material

```rust
commands.spawn((
    Mesh3d(meshes.add(Cuboid::new(1.0, 1.0, 1.0))),
    MeshMaterial3d(materials.add(StandardMaterial {
        base_color: Color::srgb(0.8, 0.7, 0.6),
        ..default()
    })),
    Transform::from_xyz(0.0, 0.5, 0.0),
));

// Primitives
Cuboid::new(x, y, z)
Sphere::new(radius)
Cylinder::new(radius, height)
Plane3d::default()
```

---

## Visibility

```rust
Visibility::Visible   // always visible
Visibility::Hidden    // always hidden
Visibility::Inherited // (default) inherit from parent
```

---

## Bounding / Collision (2D)

```rust
use bevy::math::bounding::*;

Aabb2d::new(center: Vec2, half_extents: Vec2)
BoundingCircle::new(center: Vec2, radius: f32)

ball.intersects(&bounding_box) -> bool
bounding_box.closest_point(point: Vec2) -> Vec2

// AABB from a 2D sprite scaled by size
Aabb2d::new(
    transform.translation.truncate(),
    transform.scale.truncate() / 2.0,
)
```

---

## Text (World Space — Text2d)

`Text2d` renders text as a 2D entity in the world (not UI). Use it for floating labels, health bars, damage numbers, etc.

```rust
commands.spawn((
    Text2d::new("Hello World"),
    TextFont {
        font: asset_server.load("fonts/FiraSans-Bold.ttf"),
        font_size: 24.0,
        ..default()
    },
    TextColor(Color::WHITE),
    Transform::from_xyz(0.0, 1.0, 0.0),
));
```

For UI text inside `Node` hierarchies, see `references/ui.md`.

---

## Camera Configuration

```rust
// 2D camera
commands.spawn(Camera2d);

// 3D camera
commands.spawn((
    Camera3d::default(),
    Transform::from_xyz(-2.5, 4.5, 9.0).looking_at(Vec3::ZERO, Vec3::Y),
));

// Custom clear color
commands.spawn((
    Camera3d::default(),
    Camera {
        clear_color: ClearColorConfig::Custom(Color::BLACK),
        hdr: true,  // required for Bloom
        ..default()
    },
));

// HDR + Bloom (requires hdr: true on Camera)
use bevy::post_process::bloom::Bloom;
commands.spawn((
    Camera3d::default(),
    Camera { hdr: true, ..default() },
    Bloom::default(),
));
```

### Environment Lighting

```rust
// Global ambient light (flat fill, no direction)
commands.insert_resource(GlobalAmbientLight {
    brightness: 750.0,
    ..default()
});

// Image-based environment map (used with Camera3d)
use bevy::pbr::EnvironmentMapLight;
commands.spawn((
    Camera3d::default(),
    EnvironmentMapLight {
        diffuse_map: asset_server.load("env/pisa_diffuse_rgb9e5_zstd.ktx2"),
        specular_map: asset_server.load("env/pisa_specular_rgb9e5_zstd.ktx2"),
        intensity: 2_000.0,
        ..default()
    },
));
```

---

## ZIndex (UI draw order)

Controls draw order among sibling UI nodes. Higher value renders on top.

```rust
// Local z-order: relative to siblings in same parent
commands.spawn((Node::default(), ZIndex(2)));

// Global z-order: relative to all UI nodes regardless of hierarchy
commands.spawn((Node::default(), GlobalZIndex(1)));
```

`ZIndex` default is `0`. `GlobalZIndex` default is `0`. Negative values render below default. `GlobalZIndex` always beats `ZIndex` across different subtrees.

---

## `children![]` Macro

A convenience macro for declaring static child entities inline. Produces the same result as `.with_children(...)` but reads more declaratively.

```rust
commands.spawn((
    Node { width: Val::Percent(100.0), ..default() },
    children![
        (Text::new("Left"), TextColor(Color::WHITE)),
        (Text::new("Right"), TextColor(Color::srgb(1.0, 0.5, 0.0))),
    ]
));
```

Requires `use bevy::prelude::*;` (re-exported from `bevy::ecs`).

---

## Plugin Pattern

```rust
pub struct MyPlugin;

impl Plugin for MyPlugin {
    fn build(&self, app: &mut App) {
        app
            .insert_resource(MyResource::default())
            .add_event::<MyEvent>()
            .add_systems(Startup, setup)
            .add_systems(Update, (system_a, system_b).chain())
            .add_observer(on_my_event);
    }
}

app.add_plugins(MyPlugin);
app.add_plugins((PluginA, PluginB));
```

---

## Deref / DerefMut Pattern (Newtype Components)

```rust
#[derive(Component, Deref, DerefMut)]
struct Velocity(Vec2);

velocity.x += 1.0;   // auto-deref to velocity.0.x
**velocity = Vec2::ZERO;
```

---

## Name Component (Debugging)

```rust
commands.spawn((Name::new("Player"), Transform::default()));
// Appears in error messages and bevy-inspector-egui
```
