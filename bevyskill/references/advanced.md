# Bevy Advanced Patterns Reference (v0.18.x)

## Physics Interpolation (FixedUpdate + Smooth Rendering)

The problem: `FixedUpdate` runs at 64 Hz by default, but frames render at variable rates. Without interpolation, physics-driven objects will jitter visually.

The pattern: store both current and previous physics positions, then lerp the visual transform using `overstep_fraction()`.

```rust
#[derive(Component, Default, Deref, DerefMut)]
struct PhysicalTranslation(Vec3);

#[derive(Component, Default, Deref, DerefMut)]
struct PreviousPhysicalTranslation(Vec3);

// FixedUpdate: advance physics state
fn advance_physics(
    fixed_time: Res<Time<Fixed>>,
    mut query: Query<(&mut PhysicalTranslation, &mut PreviousPhysicalTranslation, &Velocity)>,
) {
    for (mut current, mut previous, velocity) in &mut query {
        previous.0 = current.0;
        current.0 += velocity.0 * fixed_time.delta_secs();
    }
}

// RunFixedMainLoop / AfterFixedMainLoop: interpolate visual transform
fn interpolate_rendered_transform(
    fixed_time: Res<Time<Fixed>>,
    mut query: Query<(&mut Transform, &PhysicalTranslation, &PreviousPhysicalTranslation)>,
) {
    let alpha = fixed_time.overstep_fraction(); // 0.0–1.0 between fixed steps
    for (mut transform, current, previous) in &mut query {
        transform.translation = previous.lerp(*current, alpha);
    }
}

app.add_systems(FixedUpdate, advance_physics);
app.add_systems(
    RunFixedMainLoop,
    interpolate_rendered_transform.in_set(RunFixedMainLoopSystems::AfterFixedMainLoop),
);
```

---

## States

### Basic States

```rust
#[derive(States, Debug, Clone, PartialEq, Eq, Hash, Default)]
enum AppState { #[default] Menu, InGame { paused: bool }, Splash }

app.init_state::<AppState>();
app.add_systems(OnEnter(AppState::InGame { paused: false }), setup_game);
app.add_systems(OnExit(AppState::Menu), cleanup_menu);
app.add_systems(Update, gameplay.run_if(in_state(AppState::InGame { paused: false })));

fn transition(mut next: ResMut<NextState<AppState>>) {
    next.set(AppState::InGame { paused: false });
}
```

### Computed States

Derive one state from another automatically:

```rust
#[derive(Debug, Clone, Copy, Eq, PartialEq, Hash)]
struct InGame;

impl ComputedStates for InGame {
    type SourceStates = AppState;
    fn compute(source: AppState) -> Option<Self> {
        match source {
            AppState::InGame { .. } => Some(Self),
            _ => None,
        }
    }
}

// Computed from multiple source states
impl ComputedStates for Tutorial {
    type SourceStates = (TutorialState, InGame, Option<IsPaused>);
    fn compute((tutorial, _in_game, is_paused): (TutorialState, InGame, Option<IsPaused>)) -> Option<Self> {
        // Option<IsPaused> means this runs even when IsPaused doesn't exist yet
        if !matches!(tutorial, TutorialState::Active) { return None; }
        match is_paused? {
            IsPaused::NotPaused => Some(Tutorial::MovementInstructions),
            IsPaused::Paused => Some(Tutorial::PauseInstructions),
        }
    }
}

app.add_computed_state::<InGame>();
app.add_systems(OnEnter(InGame), setup_game);
app.add_systems(Update, movement.run_if(in_state(IsPaused::NotPaused)));
```

### DespawnOnExit

```rust
// Entity is auto-despawned when the specified state exits
commands.spawn((DespawnOnExit(IsPaused::Paused), Node { ..default() }, /* ... */));
```

---

## System Scheduling — Advanced

```rust
// Full schedule labels:
// PreUpdate, Update, PostUpdate
// FixedPreUpdate, FixedUpdate, FixedPostUpdate
// RunFixedMainLoop (wraps the fixed loop)
// OnEnter(State), OnExit(State), OnTransition { from, to }

// Input accumulation / interpolation pattern
app.add_systems(
    RunFixedMainLoop,
    accumulate_input.in_set(RunFixedMainLoopSystems::BeforeFixedMainLoop),
);
app.add_systems(
    RunFixedMainLoop,
    interpolate_transforms.in_set(RunFixedMainLoopSystems::AfterFixedMainLoop),
);
```

---

## Changed / Added Query Filters

```rust
// Only entities whose component changed this frame
fn react_to_changes(query: Query<&Transform, Changed<Transform>>) { }

// Only newly-added components
fn on_new_enemy(query: Query<Entity, Added<Enemy>>) { }
```

---

## Local\<T\> (Per-System State)

```rust
// Each system instance gets its own T, initialized with Default, persists across frames
fn cursor_cycle(mut index: Local<usize>, cursor_icons: Res<CursorIcons>) {
    *index = (*index + 1) % cursor_icons.0.len();
}
```

---

## Timers and Stopwatches

### Timer

```rust
#[derive(Resource)]
struct SpawnTimer(Timer);

app.insert_resource(SpawnTimer(Timer::from_seconds(2.0, TimerMode::Repeating)));

fn tick_timer(time: Res<Time>, mut timer: ResMut<SpawnTimer>) {
    if timer.0.tick(time.delta()).just_finished() { /* spawn */ }
}
```

### Stopwatch

```rust
use bevy::time::Stopwatch;

#[derive(Component, Default)]
struct Emitter { stopwatch: Stopwatch }

fn update(time: Res<Time>, mut query: Query<&mut Emitter>) {
    for mut emitter in &mut query {
        emitter.stopwatch.tick(time.delta());
        let t = emitter.stopwatch.elapsed_secs();
    }
}

stopwatch.pause();
stopwatch.unpause();
stopwatch.is_paused()
```

---

## Plugins

### Plugin with Configuration

```rust
pub struct MyPlugin {
    pub speed: f32,
    pub message: String,
}

impl Plugin for MyPlugin {
    fn build(&self, app: &mut App) {
        app.insert_resource(MyConfig {
            speed: self.speed,
            message: self.message.clone(),
        })
        .add_systems(Update, my_system);
    }
}
```

### PluginGroup

```rust
pub struct MyPluginGroup;

impl PluginGroup for MyPluginGroup {
    fn build(self) -> PluginGroupBuilder {
        PluginGroupBuilder::start::<Self>()
            .add(PluginA)
            .add(PluginB)
    }
}

// Disable/reorder within a group
app.add_plugins(
    DefaultPlugins.build()
        .disable::<bevy::log::LogPlugin>()
);
```

---

## Window Management

### Configuration at Startup

```rust
app.add_plugins(DefaultPlugins.set(WindowPlugin {
    primary_window: Some(Window {
        title: "My Game".to_string(),
        resolution: (1280.0, 720.0).into(),
        fit_canvas_to_parent: true,
        prevent_default_event_handling: false,
        window_theme: Some(WindowTheme::Dark),
        transparent: true,
        decorations: false,
        visible: false,
        ..default()
    }),
    ..default()
}));
```

### Runtime Window Modification

```rust
fn update(mut window: Single<&mut Window>, time: Res<Time>) {
    window.title = format!("Time: {:.0}", time.elapsed_secs());
    window.resolution.set(1280.0, 720.0);
    window.present_mode = PresentMode::AutoNoVsync;
    window.visible = true;
}
```

### Cursor Control

```rust
fn lock_cursor(mut cursor: Single<&mut CursorOptions>) {
    cursor.visible = false;
    cursor.grab_mode = CursorGrabMode::Locked;
}
```

### Drag/Resize (Borderless)

```rust
fn drag(mut windows: Query<&mut Window>, input: Res<ButtonInput<MouseButton>>) {
    if input.just_pressed(MouseButton::Left) {
        for mut window in &mut windows {
            window.start_drag_move();
            // window.start_drag_resize(CompassOctant::NorthWest);
        }
    }
}
```

### Multiple Windows

```rust
let second_window = commands.spawn(Window { title: "Second".into(), ..default() }).id();
commands.spawn((
    Camera3d::default(),
    Camera {
        target: RenderTarget::Window(WindowRef::Entity(second_window)),
        ..default()
    },
));
```

### React to Resize

```rust
fn on_resize(mut reader: MessageReader<WindowResized>) {
    for e in reader.read() { println!("{} x {}", e.width, e.height); }
}
```

---

## MessageReader (Built-in Events)

```rust
fn handle_keyboard(mut reader: MessageReader<KeyboardInput>) {
    for input in reader.read() {
        if input.state.is_pressed() {
            match &input.logical_key {
                Key::Enter => { }
                Key::Backspace => { }
                _ => { }
            }
        }
    }
}

fn handle_mouse_buttons(mut reader: MessageReader<MouseButtonInput>) {
    for e in reader.read() {
        match e.state {
            ButtonState::Pressed => { }
            ButtonState::Released => { }
        }
    }
}

fn handle_cursor(mut reader: MessageReader<CursorMoved>) {
    if let Some(e) = reader.read().last() {
        let pos = e.position; // Vec2 in viewport coords
    }
}
```

### Mouse Scroll

```rust
use bevy::input::mouse::AccumulatedMouseScroll;

fn scroll(scroll: Res<AccumulatedMouseScroll>) {
    if scroll.delta != Vec2::ZERO { }
}
```

---

## Animation

### Keyframe / Clip Animation

```rust
use bevy::animation::AnimationEvent;

fn setup(
    mut commands: Commands,
    mut animations: ResMut<Assets<AnimationClip>>,
    mut graphs: ResMut<Assets<AnimationGraph>>,
) {
    let mut clip = AnimationClip::default();
    clip.set_duration(2.0);
    clip.add_event(0.0, MyEvent { value: "start".into() });
    clip.add_event(1.0, MyEvent { value: "midpoint".into() });

    let (graph, index) = AnimationGraph::from_clip(animations.add(clip));
    let mut player = AnimationPlayer::default();
    player.play(index).repeat();

    commands.spawn((AnimationGraphHandle(graphs.add(graph)), player));
}

#[derive(AnimationEvent, Clone)]
struct MyEvent { value: String }

fn on_event(trigger: On<MyEvent>) { println!("{}", trigger.value); }
app.add_observer(on_event);
```

### GLTF Animations

```rust
fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut graphs: ResMut<Assets<AnimationGraph>>,
) {
    let (graph, index) = AnimationGraph::from_clip(
        asset_server.load(GltfAssetLabel::Animation(0).from_asset("model.glb")),
    );
    commands.spawn((
        AnimationToPlay { graph_handle: graphs.add(graph), index },
        SceneRoot(asset_server.load(GltfAssetLabel::Scene(0).from_asset("model.glb"))),
    )).observe(play_animation_when_ready);
}

fn play_animation_when_ready(
    trigger: On<SceneInstanceReady>,
    mut commands: Commands,
    children: Query<&Children>,
    anim_data: Query<&AnimationToPlay>,
    mut players: Query<&mut AnimationPlayer>,
) {
    if let Ok(data) = anim_data.get(trigger.entity) {
        for child in children.iter_descendants(trigger.entity) {
            if let Ok(mut player) = players.get_mut(child) {
                player.play(data.index).repeat();
                commands.entity(child).insert(AnimationGraphHandle(data.graph_handle.clone()));
            }
        }
    }
}
```

---

## Easing / Curves

```rust
use bevy::math::cubic_splines::*;

// Cubic bezier
let curve = CubicBezier::new([points]).to_curve().unwrap();
let pos = curve.position(t);  // t: 0.0–1.0

// Hermite spline (points + tangents)
let spline = CubicHermite::new(points, tangents);
let curve = spline.to_curve().ok();
let cyclic_curve = spline.to_curve_cyclic().ok();

// Catmull-Rom
let spline = CubicCardinalSpline::new_catmull_rom(points);

// Easing functions
let f = EasingCurve::new(0.0, 1.0, EaseFunction::CubicInOut);
let value = f.sample(t).unwrap();
// Available: SineIn/Out/InOut, QuadraticIn/Out/InOut, CubicIn/Out/InOut,
// ElasticIn/Out/InOut, BounceIn/Out/InOut, BackIn/Out/InOut,
// CircularIn/Out/InOut, ExponentialIn/Out/InOut, Linear, SmoothStep, Steps(n, JumpAt::End)

// Color interpolation
let curve = CubicBezier::new([colors]).to_curve().unwrap();
sprite.color = curve.position(t).into(); // works with LinearRgba, Oklaba, Xyza
```

---

## Gizmos (Debug Drawing)

```rust
fn draw(mut gizmos: Gizmos) {
    // 2D
    gizmos.line_2d(Vec2::ZERO, Vec2::new(100., 0.), Color::WHITE);
    gizmos.circle_2d(Vec2::ZERO, 50., Color::RED);
    gizmos.rect_2d(center, size, Color::GREEN);
    gizmos.arrow_2d(from, to, Color::YELLOW);
    gizmos.linestrip_2d([p1, p2, p3, p4], Color::WHITE);
    gizmos.primitive_2d(&Circle::new(50.), isometry, Color::WHITE);

    // 3D
    gizmos.line(Vec3::ZERO, Vec3::Y, Color::WHITE);
    gizmos.sphere(center, radius, Color::WHITE);
    gizmos.primitive_3d(&Cuboid::new(1., 1., 1.), isometry, Color::WHITE);

    // Curves
    gizmos.curve_2d(&curve, curve.domain().spaced_points(100).unwrap(), Color::WHITE);
}
```

---

## Scene Serialization (Reflect)

```rust
// Make a component serializable
#[derive(Component, Reflect, Default)]
#[reflect(Component)]
struct MyComponent { pub x: f32, pub y: f32 }

// Skip non-serializable fields
#[derive(Component, Reflect)]
#[reflect(Component)]
struct MyComponent {
    pub name: String,
    #[reflect(skip_serializing)]
    pub runtime_data: SomeNonSerializableType,
}

app.register_type::<MyComponent>();

// Load a scene
commands.spawn(DynamicSceneRoot(asset_server.load("scene.scn.ron")));

// Save a scene (exclusive system)
fn save(world: &mut World) {
    let scene = DynamicScene::from_world(world);
    let registry = world.resource::<AppTypeRegistry>().read();
    let serialized = scene.serialize(&registry).unwrap();
    // write serialized to file
}
```

---

## Asset Events / Reacting to Load

```rust
fn on_mesh_loaded(
    mut events: MessageReader<AssetEvent<Mesh>>,
    meshes: Res<Assets<Mesh>>,
) {
    for event in events.read() {
        if let AssetEvent::<Mesh>::Added { id } = event {
            if let Some(mesh) = meshes.get(*id) { /* ready */ }
        }
    }
}

// AssetChanged query filter: runs when component OR its referenced asset changes
fn react_to_asset_change(query: Query<Entity, (With<MyComp>, AssetChanged<MyComp>)>) { }
```

### Completion Detection Pattern

```rust
fn on_load(asset_server: Res<AssetServer>, my_handle: Res<MyHandle>) {
    if asset_server.is_loaded_with_dependencies(&my_handle.0) { /* ready */ }
}

app.add_systems(Update, setup_scene.run_if(assets_are_ready));

fn assets_are_ready(barrier: Option<Res<AssetBarrier>>) -> bool {
    barrier.map(|b| b.is_ready()) == Some(true)
}
```

### AssetPlugin (Custom Asset Path)

```rust
app.add_plugins(DefaultPlugins.set(AssetPlugin {
    file_path: "src/assets".into(),  // default is "assets"
    ..default()
}));
```

---

## init_resource vs insert_resource

```rust
app.init_resource::<MyResource>();           // uses Default::default()
app.insert_resource(MyResource { value: 42 }); // custom value

// FromWorld for resources that need world access at initialization
impl FromWorld for MyResource {
    fn from_world(world: &mut World) -> Self {
        let time = world.resource::<Time>();
        MyResource { started_at: time.elapsed() }
    }
}
```
