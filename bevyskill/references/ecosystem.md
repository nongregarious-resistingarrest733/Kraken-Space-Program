# Bevy Ecosystem Reference (v0.18.x)

Third-party crates that integrate tightly with Bevy. Version numbers are pinned to **Bevy 0.18**.

---

## leafwing-input-manager (`0.20`)

An action-based input layer. Instead of polling `ButtonInput<KeyCode>` directly, you define an enum of logical actions and bind inputs to them. This decouples game logic from specific hardware and supports remapping, chords, analog axes, and networked input out of the box.

```toml
[dependencies]
leafwing-input-manager = "0.20"
```

### Core Concepts

| Type | Role |
|------|------|
| `Actionlike` | Trait (and derive macro) for your action enum |
| `InputMap<A>` | Component — maps inputs → actions for one entity |
| `ActionState<A>` | Component — holds the current state of every action |
| `InputManagerPlugin<A>` | Plugin — drives the whole system |

### Quickstart

```rust
use bevy::prelude::*;
use leafwing_input_manager::prelude::*;

#[derive(Actionlike, PartialEq, Eq, Hash, Clone, Copy, Debug, Reflect)]
enum Action {
    Move,
    Jump,
    Attack,
}

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(InputManagerPlugin::<Action>::default())
        .add_systems(Startup, spawn_player)
        .add_systems(Update, handle_actions)
        .run();
}

fn spawn_player(mut commands: Commands) {
    let input_map = InputMap::new([
        (Action::Jump, KeyCode::Space),
        (Action::Attack, MouseButton::Left),
    ]);
    commands.spawn((Player, input_map));
}

fn handle_actions(query: Query<&ActionState<Action>, With<Player>>) {
    let Ok(state) = query.single() else { return };
    if state.just_pressed(&Action::Jump) {
        info!("jump!");
    }
    if state.pressed(&Action::Attack) {
        info!("attacking");
    }
}
```

### Axis / Dual-Axis Inputs

Analog inputs use a separate trait. Declare your action's output type when deriving:

```rust
// For single-axis (e.g., scroll wheel, trigger)
// For dual-axis (e.g., stick, WASD as virtual joystick):
let input_map = InputMap::new([])
    .with_dual_axis(Action::Move, KeyboardVirtualDPad::WASD)
    .with_dual_axis(Action::Move, GamepadStick::LEFT);

fn read_move(query: Query<&ActionState<Action>>) {
    let Ok(state) = query.single() else { return };
    if let Some(axis_data) = state.axis_pair(&Action::Move) {
        let direction: Vec2 = axis_data.xy();
        // direction is already normalized to [-1, 1]
    }
}
```

### Chords

Chords trigger only when all inputs are held simultaneously:

```rust
use leafwing_input_manager::user_input::ButtonlikeChord;

input_map.insert(
    Action::Dodge,
    ButtonlikeChord::new([KeyCode::ControlLeft, KeyCode::KeyD]),
);
```

### ActionState Methods

```rust
state.pressed(&Action::Jump)           // held this frame
state.just_pressed(&Action::Jump)      // first frame down
state.just_released(&Action::Jump)     // first frame up
state.instant_started(&Action::Jump)   // Option<Instant> of last press/release
```

### Local Multiplayer

Each player entity carries its own `InputMap` component. Assign a specific gamepad to a map:

```rust
input_map.set_gamepad(gamepad_entity);
```

### Network Serialization

`ActionState` can be serialized to `ActionDiff` for sending on the wire (used by lightyear integration). Enable the `serialize` feature:

```toml
leafwing-input-manager = { version = "0.20", features = ["serialize"] }
```

---

## lightyear (networking)

A Bevy-native networking library for client-server games. Supports UDP, WebTransport, WebSocket, and Steam as IO layers. Ships client-side prediction, rollback, and interpolation.

```toml
[dependencies]
lightyear = { version = "*", features = ["client", "server", "udp"] }
```

### Architecture

Lightyear uses a **component-based** approach. The client and server are Bevy entities with specific components rather than global singletons.

**Key plugin groups:**

```rust
use lightyear::prelude::*;

fn main() {
    let fixed_hz = 64.0;
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(client::ClientPlugins {
            tick_duration: Duration::from_secs_f64(1.0 / fixed_hz),
        })
        .add_plugins(server::ServerPlugins {
            tick_duration: Duration::from_secs_f64(1.0 / fixed_hz),
        })
        .run();
}
```

### Defining the Protocol

Both peers must share the same protocol definition. A protocol declares which types travel over the wire.

```rust
// Shared module (compiled into both client and server)

// 1. Messages
#[derive(Serialize, Deserialize)]
struct ChatMessage(String);

// 2. Components to replicate
#[derive(Component, Serialize, Deserialize, Clone)]
struct PlayerPosition(Vec2);

// 3. Channels (reliability/ordering)
struct ReliableChannel;
```

### Sending and Receiving Messages

```rust
// Server → client
fn send(mut sender: Single<&mut MessageSender<ChatMessage>>) {
    let _ = sender.send::<ReliableChannel>(ChatMessage("hello".into()));
}

// Client receiving
fn receive(mut receivers: Query<&mut MessageReceiver<ChatMessage>>) {
    for mut r in &mut receivers {
        for msg in r.receive() {
            info!("got: {}", msg.0);
        }
    }
}
```

### Replication

Add `Replicate` to any entity to start sending its components to the remote peer:

```rust
commands.spawn((PlayerPosition(Vec2::ZERO), Replicate::default()));
```

On the receiver, replicated entities carry the `Replicated` marker. React to them with normal Bevy queries:

```rust
fn on_player_joined(query: Query<Entity, (With<Replicated>, Added<PlayerPosition>)>) {
    for entity in &query {
        info!("new remote player: {entity:?}");
    }
}
```

### Connection Lifecycle

```rust
// Trigger connection / disconnection
commands.trigger(Connect);
commands.trigger(Disconnect);

// Query connection state
// Disconnected | Connecting | Connected components on the link entity
```

### IO Layers (Feature Flags)

| Feature | Transport |
|---------|-----------|
| `udp` | UDP (fastest, no ordering) |
| `webtransport` | WebTransport (WASM-compatible, requires TLS) |
| `websocket` | WebSocket (WASM-compatible, wider firewall support) |
| `crossbeam` | In-process channels (testing / listen server) |
| `steam` | Steam networking sockets |

### Integration with leafwing-input-manager

Enable the `leafwing` feature to serialize `ActionState` diffs for authoritative input:

```toml
lightyear = { version = "*", features = ["client", "server", "udp", "leafwing"] }
```

### Integration with Avian Physics

```toml
lightyear = { version = "*", features = ["avian2d"] }  # or "avian3d"
```

This sets up the correct system ordering between lightyear's prediction tick and Avian's physics step.

---

## avian2d / avian3d (physics alternative to Rapier)

A pure-Rust ECS-native physics engine. Less mature than Rapier but integrates more naturally with Bevy's ECS.

```toml
[dependencies]
avian3d = { version = "*", features = ["f32"] }  # or f64
```

```rust
use avian3d::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(PhysicsPlugins::default())
        .run();
}

// Rigid body + collider
commands.spawn((
    RigidBody::Dynamic,
    Collider::capsule(0.5, 1.0),
    Transform::from_xyz(0.0, 5.0, 0.0),
));

// Static ground
commands.spawn((
    RigidBody::Static,
    Collider::cuboid(10.0, 0.1, 10.0),
));
```

For Rapier (the more commonly used option), see `references/rapier.md`.
