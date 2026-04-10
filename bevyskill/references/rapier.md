# Bevy Rapier 3D Reference (bevy_rapier3d)

Rapier is the standard physics integration for Bevy. Always use `bevy_rapier3d` for 3D. Always `use bevy_rapier3d::prelude::*;`.

---

## Cargo Setup

```toml
[dependencies]
bevy = "*"
bevy_rapier3d = "*"

# With optional features:
bevy_rapier3d = { version = "*", features = ["simd-stable", "debug-render-3d"] }
```

**Feature flags:**
- `debug-render-3d` — visual debug overlay showing collider shapes
- `simd-stable` — SIMD optimizations (stable compiler, limited platform support)
- `simd-nightly` — SIMD optimizations (nightly compiler, wider platform support)
- `parallel` — rayon-based parallelism; cannot combine with `enhanced-determinism`
- `serde-serialize` — serde support for all physics structures
- `enhanced-determinism` — cross-platform determinism; cannot combine with simd or parallel features
- `wasm-bindgen` — for WASM targets

**Dev build optimization** (Rapier is very slow without this):

```toml
[profile.dev.package.bevy_rapier3d]
opt-level = 3
```

---

## Plugin Setup

```rust
use bevy::prelude::*;
use bevy_rapier3d::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(RapierPhysicsPlugin::<NoUserData>::default())
        .add_plugins(RapierDebugRenderPlugin::default())  // optional
        .run();
}
```

`NoUserData` is the standard type arg when you don't need physics hooks. If you define custom hooks, replace it with your hooks type.

---

## Rigid Bodies

### Types

```rust
RigidBody::Dynamic          // affected by forces and contacts
RigidBody::Fixed            // immovable; infinite mass
RigidBody::KinematicPositionBased  // user controls position; velocity computed automatically
RigidBody::KinematicVelocityBased  // user controls velocity; position integrated automatically
```

**Kinematic bodies ignore all contact forces.** They go where you tell them. Manual obstacle handling (via scene queries or the character controller) is the user's responsibility.

### Spawning

```rust
commands
    .spawn(RigidBody::Dynamic)
    .insert(Transform::from_xyz(0.0, 4.0, 0.0))
    .insert(Velocity {
        linvel: Vec3::new(0.0, 2.0, 0.0),
        angvel: Vec3::new(0.2, 0.0, 0.0),
    })
    .insert(GravityScale(0.5))
    .insert(Ccd::enabled())
    .insert(Sleeping::disabled());
```

### Position

```rust
// Set at spawn
commands.spawn(RigidBody::Dynamic).insert(Transform::from_xyz(0.0, 0.0, 0.0));

// Modify in a system — this is a teleport, not physically realistic for dynamic bodies
fn modify_position(mut transforms: Query<&mut Transform, With<RigidBody>>) {
    for mut t in &mut transforms {
        t.translation.y += 0.1;
    }
}
```

⚠️ For **dynamic** bodies: prefer setting velocity or applying forces/impulses rather than setting Transform directly. For **KinematicPositionBased**: set Transform. For **KinematicVelocityBased**: set `Velocity`.

### Velocity

```rust
// At spawn
commands.spawn(RigidBody::Dynamic).insert(Velocity {
    linvel: Vec3::new(0.0, 2.0, 0.0),
    angvel: Vec3::new(0.2, 0.4, 0.8),
});

// In a system
fn set_velocity(mut velocities: Query<&mut Velocity>) {
    for mut vel in &mut velocities {
        vel.linvel = Vec3::new(0.0, 2.0, 0.0);
        vel.angvel = Vec3::new(3.2, 0.4, 0.8);
    }
}
```

Velocity is ignored on Fixed bodies and auto-computed for kinematic bodies.

### Gravity

Global gravity is set on `RapierConfiguration`:

```rust
// Changing gravity doesn't auto-wake sleeping bodies — wake them manually if needed
fn setup(mut rapier_config: ResMut<RapierConfiguration>) {
    rapier_config.gravity = Vec3::new(0.0, -9.81, 0.0);
}
```

Per-body gravity scale:

```rust
commands.spawn(RigidBody::Dynamic).insert(GravityScale(2.0));  // 2x gravity
// 0.0 = no gravity, negative = flipped gravity
```

Fixed and kinematic bodies are immune to gravity. A body with zero mass is also immune.

### Forces and Impulses

```rust
// At spawn
commands.spawn(RigidBody::Dynamic)
    .insert(ExternalForce {
        force: Vec3::new(10.0, 20.0, 30.0),
        torque: Vec3::new(1.0, 2.0, 3.0),
    })
    .insert(ExternalImpulse {
        impulse: Vec3::new(1.0, 2.0, 3.0),
        torque_impulse: Vec3::new(0.1, 0.2, 0.3),
    });

// In a system
fn apply_forces(
    mut forces: Query<&mut ExternalForce>,
    mut impulses: Query<&mut ExternalImpulse>,
) {
    for mut f in &mut forces {
        f.force = Vec3::new(1000.0, 0.0, 0.0);
        f.torque = Vec3::ZERO;
    }
    for mut i in &mut impulses {
        i.impulse = Vec3::new(100.0, 0.0, 0.0);
    }
}
```

`ExternalForce` is persistent across steps; `ExternalImpulse` is applied once per step then cleared. Both require a non-zero mass. Forces affect acceleration; impulses affect velocity directly.

### Mass Properties

```rust
// Explicit mass (collider density contributions still add on top)
commands.spawn(RigidBody::Dynamic).insert(AdditionalMassProperties::Mass(10.0));

// Zero out collider contributions and set all mass props manually
commands.spawn(RigidBody::Dynamic)
    .insert(Collider::ball(1.0))
    .insert(ColliderMassProperties::Density(0.0))  // zero out collider
    .insert(AdditionalMassProperties::Mass(5.0));
```

A mass of zero → treated as infinite mass (body won't move from forces). Body with no collider has zero mass unless set explicitly.

⚠️ Triangle mesh colliders don't auto-compute mass properties. Set mass manually if using trimesh.

### Locking Axes

```rust
commands.spawn(RigidBody::Dynamic)
    .insert(LockedAxes::TRANSLATION_LOCKED | LockedAxes::ROTATION_LOCKED_X);

// Common: prevent player from tilting
.insert(LockedAxes::ROTATION_LOCKED)  // locks all rotation axes
```

Available flags: `TRANSLATION_LOCKED`, `TRANSLATION_LOCKED_X/Y/Z`, `ROTATION_LOCKED`, `ROTATION_LOCKED_X/Y/Z`.

### Damping

Simulates air friction or drag:

```rust
commands.spawn(RigidBody::Dynamic).insert(Damping {
    linear_damping: 0.5,
    angular_damping: 1.0,
});
```

Default is `0.0` (no damping). Larger values = stronger slowdown.

### Dominance

Non-physical but useful: makes one body immune to forces from contacts with lower-dominance bodies.

```rust
commands.spawn(RigidBody::Dynamic).insert(Dominance::group(10));
// Range: -127 to 127, default 0
// Higher dominance = acts as infinite mass against lower-dominance bodies
// Fixed/kinematic always outrank dynamic bodies regardless of dominance
```

### CCD (Continuous Collision Detection)

Prevents fast-moving objects from tunneling through thin colliders:

```rust
commands.spawn(RigidBody::Dynamic).insert(Ccd::enabled());
```

Disabled by default (performance cost). Only useful for fast-moving bodies. Useless on fixed bodies.

### Sleeping

Bodies that stop moving are automatically put to sleep (skipped in simulation). They wake automatically when another body interacts with them, or when their components change. Gravity changes don't auto-wake — wake manually if needed.

```rust
// Force awake at spawn
commands.spawn(RigidBody::Dynamic).insert(Sleeping::disabled());

// Wake manually in a system
fn wake_bodies(mut sleeping: Query<&mut Sleeping>) {
    for mut s in &mut sleeping {
        s.sleeping = false;
    }
}
```

---

## Colliders

### Basic Shapes

```rust
Collider::ball(radius)
Collider::cuboid(half_x, half_y, half_z)
Collider::capsule_y(half_height, radius)   // capsule along Y axis
Collider::capsule_x(half_height, radius)
Collider::capsule_z(half_height, radius)
Collider::cylinder(half_height, radius)
Collider::cone(half_height, radius)
Collider::halfspace(Vec3::Y)               // infinite floor/wall
```

### Attaching to Rigid Bodies

```rust
// Same entity — single collider
commands.spawn(RigidBody::Dynamic).insert(Collider::ball(0.5));

// Child entity — multiple colliders, positioned relative to body
commands
    .spawn((RigidBody::Dynamic, GlobalTransform::default()))
    .with_children(|children| {
        children
            .spawn(Collider::ball(0.5))
            .insert(Transform::from_xyz(0.0, 0.0, -1.0));
        children
            .spawn(Collider::ball(0.5))
            .insert(Transform::from_xyz(0.0, 0.0, 1.0));
    });
```

A collider without a rigid body is treated as Fixed.

### Complex Shapes

```rust
// Convex hull (auto-computed from points)
Collider::convex_hull(&points).unwrap()

// Pre-validated convex mesh (you guarantee it's convex)
Collider::convex_mesh(points, &indices).unwrap()

// Triangle mesh (for static environment geometry)
Collider::trimesh(vertices, indices)
// With flags (e.g. fix ghost collisions):
Collider::trimesh_with_flags(vertices, indices, TrimeshFlags::FIX_INTERNAL_EDGES)

// Heightfield
Collider::heightfield(heights_matrix, scale_vec3)

// Compound shape
Collider::compound(vec![
    (pos1, rot1, shape1),
    (pos2, rot2, shape2),
])

// Convex decomposition (auto-splits non-convex mesh into convex parts)
Collider::convex_decomposition(&vertices, &indices)
```

⚠️ **Do not use trimesh/polyline on dynamic bodies** — no interior means objects get stuck. Use convex decomposition or compound shapes instead.

### Sensors

Sensors detect intersection but generate no contact forces:

```rust
commands.spawn(Collider::ball(0.5)).insert(Sensor);
```

Sensors still contribute to the mass of attached rigid bodies (by default). Use `ColliderMassProperties::Density(0.0)` if that's undesired.

### Mass Properties

```rust
// Density-based (automatic inertia computation)
commands.spawn(Collider::ball(0.5)).insert(ColliderMassProperties::Density(2.0));

// Mass-based
commands.spawn(Collider::ball(0.5)).insert(ColliderMassProperties::Mass(0.8));

// Fully manual (use only if you know the real-world values)
commands.spawn(Collider::ball(0.5)).insert(ColliderMassProperties::MassProperties(MassProperties {
    local_center_of_mass: Vec3::new(0.0, 1.0, 0.0),
    mass: 0.5,
    principal_inertia_local_frame: Quat::IDENTITY,
    principal_inertia: Vec3::new(0.3, 0.4, 0.5),
}));
```

### Friction

```rust
commands.spawn(Collider::ball(0.5)).insert(Friction {
    coefficient: 0.7,
    combine_rule: CoefficientCombineRule::Min,
});
```

Combine rules (precedence when two colliders differ: `Max > Multiply > Min > Average`): `Average` (default), `Min`, `Multiply`, `Max`.

### Restitution (Bounciness)

```rust
commands.spawn(Collider::ball(0.5)).insert(Restitution {
    coefficient: 0.7,   // 0.0 = no bounce, 1.0 = fully elastic
    combine_rule: CoefficientCombineRule::Max,
});
```

Same combine rule system as friction.

### Collision Groups / Solver Groups

Filter which pairs of colliders interact:

```rust
// CollisionGroups: filters narrow-phase contact computation (preferred, skips more work)
// SolverGroups: computes contacts but skips force computation

commands.spawn(Collider::ball(0.5))
    .insert(CollisionGroups::new(
        Group::GROUP_1 | Group::GROUP_3,  // memberships (what groups this collider is in)
        Group::GROUP_3,                   // filters (what groups it can interact with)
    ))
    .insert(SolverGroups::new(
        Group::GROUP_1 | Group::GROUP_2,
        Group::GROUP_1 | Group::GROUP_2 | Group::GROUP_4,
    ));
```

Interaction occurs only if: `(A.memberships & B.filter) != 0 && (B.memberships & A.filter) != 0`.

32 groups available (`Group::GROUP_1` through `Group::GROUP_32`). All bits set by default.

### Active Collision Types

By default, collision is disabled between two non-dynamic bodies. Enable explicitly:

```rust
// Enable kinematic ↔ static collisions
commands.spawn(Collider::ball(0.5))
    .insert(ActiveCollisionTypes::default() | ActiveCollisionTypes::KINEMATIC_STATIC);

// Enable kinematic ↔ fixed + dynamic
.insert(ActiveCollisionTypes::default() | ActiveCollisionTypes::KINEMATIC_FIXED)
```

### Active Events

Events are not generated by default. Opt in per collider:

```rust
commands.spawn(Collider::ball(0.5)).insert(ActiveEvents::COLLISION_EVENTS);
commands.spawn(Collider::ball(0.5)).insert(ActiveEvents::CONTACT_FORCE_EVENTS);
```

Reading events:

```rust
fn handle_events(
    mut collision_events: EventReader<CollisionEvent>,
    mut force_events: EventReader<ContactForceEvent>,
) {
    for event in collision_events.read() {
        // CollisionEvent::Started(entity1, entity2, flags)
        // CollisionEvent::Stopped(entity1, entity2, flags)
        // flags: CollisionEventFlags::SENSOR, CollisionEventFlags::REMOVED
    }
    for event in force_events.read() { }
}
```

Contact force events are only triggered when the total contact force exceeds `ContactForceEventThreshold` (default: 0, meaning all forces trigger). Set the threshold to avoid noise:

```rust
commands.spawn(Collider::ball(0.5))
    .insert(ActiveEvents::CONTACT_FORCE_EVENTS)
    .insert(ContactForceEventThreshold(10.0));
```

---

## Joints

Joints constrain relative motion between two rigid bodies.

### Approach: Impulse vs Multibody

`ImpulseJoint` (constraints-based):
- Fast add/remove
- Can violate constraints under heavy load
- Supports any graph topology
- Joint forces are retrievable

`MultibodyJoint` (reduced-coordinates):
- More stable and accurate
- Slow add/remove
- Tree structure only (no loops)
- Joint forces not computed

For games: prefer `ImpulseJoint`. For robotics/precise simulation: `MultibodyJoint`.

### Fixed Joint

```rust
let joint = FixedJointBuilder::new()
    .local_anchor1(Vec3::new(0.0, 0.0, -2.0));

commands.spawn(RigidBody::Dynamic)
    .insert(Collider::cuboid(0.5, 0.5, 0.5))
    .insert(ImpulseJoint::new(parent_entity, joint));
```

### Spherical Joint (Ball-in-Socket)

Prevents relative translation at anchors. Allows all rotations.

```rust
let joint = SphericalJointBuilder::new()
    .local_anchor1(Vec3::new(0.0, 0.0, 1.0))
    .local_anchor2(Vec3::new(0.0, 0.0, -3.0));

commands.spawn(RigidBody::Dynamic)
    .insert(ImpulseJoint::new(parent_entity, joint));
```

### Revolute Joint (Hinge)

One axis of rotation only. Used for wheels, doors, hinges.

```rust
let joint = RevoluteJointBuilder::new(Vec3::X)  // rotation axis
    .local_anchor1(Vec3::new(0.0, 0.0, 1.0))
    .local_anchor2(Vec3::new(0.0, 0.0, -3.0));

commands.spawn(RigidBody::Dynamic)
    .insert(ImpulseJoint::new(parent_entity, joint));
```

### Prismatic Joint (Sliding)

One axis of translation only. Supports limits.

```rust
let joint = PrismaticJointBuilder::new(Vec3::X)
    .local_anchor1(Vec3::new(0.0, 0.0, 1.0))
    .local_anchor2(Vec3::new(0.0, 1.0, -3.0))
    .limits([-2.0, 5.0]);

commands.spawn(RigidBody::Dynamic)
    .insert(ImpulseJoint::new(parent_entity, joint));
```

### Joint Motors

Spherical, revolute, and prismatic joints support motors (PD controller):

```rust
// Target velocity with damping
let joint = PrismaticJointBuilder::new(Vec3::X)
    .motor_velocity(0.1, 0.05);  // (target_vel, damping)

// Target position
// joint.configure_motor_position(target_pos, stiffness, damping)

// Full control
// joint.configure_motor(target_pos, target_vel, stiffness, damping)
```

---

## Character Controller

High-level move-and-slide controller. Handles slopes, stairs, snap-to-ground, platform interactions. Does **not** handle rotation.

### Setup

```rust
fn setup(mut commands: Commands) {
    commands
        .spawn(RigidBody::KinematicPositionBased)
        .insert(Collider::capsule_y(1.0, 0.3))
        .insert(Transform::default())
        .insert(KinematicCharacterController::default());
}

fn update(time: Res<Time>, mut controllers: Query<&mut KinematicCharacterController>) {
    for mut controller in &mut controllers {
        // Set desired translation each frame — you handle gravity manually
        controller.translation = Some(Vec3::new(0.0, -9.81 * time.delta_secs(), 0.0));
    }
}

fn read_output(controllers: Query<(Entity, &KinematicCharacterControllerOutput)>) {
    for (entity, output) in &controllers {
        // output.effective_translation: Vec3 — actual movement after obstacle resolution
        // output.grounded: bool — true if touching ground at final position
        // output.collisions: Vec<CharacterCollision>
    }
}
```

You are responsible for providing the full movement vector including gravity.

### Configuration

```rust
KinematicCharacterController {
    // Small gap between character and environment (increase if getting stuck)
    offset: CharacterLength::Absolute(0.01),

    // Up direction (default Y)
    up: Vec3::Y,

    // Slope handling
    max_slope_climb_angle: 45_f32.to_radians(),
    min_slope_slide_angle: 30_f32.to_radians(),

    // Stair climbing
    autostep: Some(CharacterAutostep {
        max_height: CharacterLength::Absolute(0.5),
        min_width: CharacterLength::Absolute(0.2),
        include_dynamic_bodies: true,
    }),

    // Snap to ground when walking downhill/downstairs
    snap_to_ground: Some(CharacterLength::Absolute(0.5)),

    // Automatically push dynamic bodies the character walks into
    apply_impulse_to_dynamic_bodies: true,

    // Filter obstacles
    filter_flags: QueryFilterFlags::EXCLUDE_SENSORS,
    filter_groups: None,

    ..default()
}
```

`CharacterLength::Relative(f)` scales by collider height/width. `CharacterLength::Absolute(f)` is a fixed world-space value.

### Collisions

```rust
fn read_collisions(outputs: Query<&KinematicCharacterControllerOutput>) {
    for output in &outputs {
        for collision in &output.collisions {
            // collision.entity, collision.toi, collision.hit, etc.
        }
    }
}
```

---

## Scene Queries

Access via `ReadRapierContext`:

```rust
fn my_system(rapier_context: ReadRapierContext) {
    let ctx = rapier_context.single().unwrap();
    // ... use ctx
}
```

### Ray-Casting

```rust
fn cast_ray(rapier_context: ReadRapierContext) {
    let ctx = rapier_context.single().unwrap();
    let ray_pos = Vec3::new(1.0, 2.0, 3.0);
    let ray_dir = Vec3::new(0.0, -1.0, 0.0);
    let max_toi = 100.0;
    let solid = true;
    let filter = QueryFilter::default();

    // First hit only
    if let Some((entity, toi)) = ctx.cast_ray(ray_pos, ray_dir, max_toi, solid, filter) {
        let hit_point = ray_pos + ray_dir * toi;
    }

    // First hit + normal
    if let Some((entity, intersection)) = ctx.cast_ray_and_get_normal(ray_pos, ray_dir, max_toi, solid, filter) {
        let hit_point = intersection.point;
        let hit_normal = intersection.normal;
    }

    // All hits (callback returns false to stop early)
    ctx.intersections_with_ray(ray_pos, ray_dir, max_toi, solid, filter, |entity, intersection| {
        true  // continue
    });
}
```

`solid`: if `true`, ray origin inside a shape returns `toi = 0.0` (shape is solid). If `false`, returns the shape boundary exit point.

### Shape-Casting (Sweep Test)

```rust
fn cast_shape(rapier_context: ReadRapierContext) {
    let ctx = rapier_context.single().unwrap();
    let shape = Collider::cuboid(1.0, 2.0, 3.0);
    let shape_pos = Vec3::new(1.0, 2.0, 3.0);
    let shape_rot = Quat::IDENTITY;
    let shape_vel = Vec3::new(0.0, -1.0, 0.0);
    let options = ShapeCastOptions {
        max_time_of_impact: 100.0,
        target_distance: 0.0,
        stop_at_penetration: false,
        compute_impact_geometry_on_penetration: false,
    };
    let filter = QueryFilter::default();

    if let Some((entity, hit)) = ctx.cast_shape(shape_pos, shape_rot, shape_vel, &shape, options, filter) {
        // hit.toi: time of impact (shape_vel * hit.toi = distance to contact)
        // hit.witness1: contact point in collider local space
        // hit.witness2: contact point in shape local space
        // hit.normal1 / hit.normal2: contact normals
    }
}
```

### Point Projection / Intersection

```rust
// Project point onto nearest collider
if let Some((entity, projection)) = ctx.project_point(point, solid, filter) {
    let closest = projection.point;
    let was_inside = projection.is_inside;
}

// All colliders containing a point
ctx.intersections_with_point(point, filter, |entity| {
    true  // return false to stop
});
```

### Shape Intersection Test

```rust
// All colliders intersecting a shape
ctx.intersections_with_shape(shape_pos, shape_rot, &shape, filter, |entity| {
    true
});

// Approximate (AABB only, cheaper)
ctx.colliders_with_aabb_intersecting_aabb(aabb, |entity| true);
```

### Contact / Intersection Pair Queries

```rust
// Check if two specific entities are in contact
if let Some(contact_pair) = ctx.contact_pair(entity1, entity2) {
    if contact_pair.has_any_active_contact() { }

    for manifold in contact_pair.manifolds() {
        for contact_point in manifold.points() {
            let impulse = contact_point.raw.data.impulse;
        }
    }
}

// Iterate all contacts for one entity
for contact_pair in ctx.contact_pairs_with(entity) { }

// Sensor intersection check
if ctx.intersection_pair(entity1, entity2) == Some(true) { }
for (e1, e2, intersecting) in ctx.intersection_pairs_with(entity) { }
```

### Query Filters

```rust
let filter = QueryFilter::default()
    .exclude_dynamic()
    .exclude_sensors()
    .exclude_rigid_body(player_entity)
    .groups(CollisionGroups::new(Group::GROUP_1, Group::GROUP_1))
    .predicate(&|handle| {
        // custom filtering logic
        true
    });
```

---

## Physics Hooks

For custom contact filtering or modification beyond collision groups:

```rust
fn main() {
    App::new()
        .add_plugins(RapierPhysicsPlugin::<MySameTagFilter>::default())
        .run();
}

#[derive(Component, PartialEq, Eq, Clone, Copy)]
enum FilterTag { GroupA, GroupB }

#[derive(SystemParam)]
struct MySameTagFilter<'w, 's> {
    tags: Query<'w, 's, &'static FilterTag>,
}

impl BevyPhysicsHooks for MySameTagFilter<'_, '_> {
    fn filter_contact_pair(&self, context: PairFilterContextView) -> Option<SolverFlags> {
        if self.tags.get(context.collider1()).ok() == self.tags.get(context.collider2()).ok() {
            Some(SolverFlags::COMPUTE_IMPULSES)
        } else {
            None
        }
    }

    fn filter_intersection_pair(&self, context: PairFilterContextView) -> bool {
        self.tags.get(context.collider1()).ok() == self.tags.get(context.collider2()).ok()
    }
}

// Colliders must opt in:
commands.spawn((
    Collider::ball(0.5),
    ActiveHooks::FILTER_CONTACT_PAIRS | ActiveHooks::FILTER_INTERSECTION_PAIR,
    FilterTag::GroupA,
));
```

### Contact Modification

```rust
impl BevyPhysicsHooks for MyHooks {
    fn modify_solver_contacts(&self, context: ContactModificationContextView) {
        for solver_contact in &mut *context.raw.solver_contacts {
            solver_contact.friction = 0.3;
            solver_contact.restitution = 0.0;
            solver_contact.tangent_velocity.x = 10.0;  // conveyor belt effect
        }
        // Remove contacts (one-way platforms):
        context.raw.solver_contacts.retain(|c| c.point.y > 0.0);
    }
}

// Collider must opt in:
commands.spawn((Collider::ball(0.5), ActiveHooks::MODIFY_SOLVER_CONTACTS));
```

---

## Common Pitfalls

**Body doesn't fall / gravity ignored:**
- Must be `RigidBody::Dynamic`
- Must have non-zero mass (attach a collider with non-zero density, or set `AdditionalMassProperties::Mass`)
- Check `LockedAxes` isn't locking translations
- Check `GravityScale` isn't 0.0

**Force/impulse does nothing:**
- Body must be Dynamic
- Must have non-zero mass
- Try a very large value to verify (e.g., `Vec3::new(100_000.0, 0.0, 0.0)`)
- Torques additionally require non-zero angular inertia

**Simulation panics with `proxy.aabb.maxs`:**
- Two dynamic bodies with zero mass are touching → give them mass

**Everything moves in slow motion (especially 2D):**
- Using pixel units directly. Rapier expects SI units (meters).
- Use `RapierPhysicsPlugin::<NoUserData>::pixels_per_meter(50.0)` to set a scale factor.
- Default gravity is `-9.81` m/s² — a 100-unit object would be 100 meters tall.

**Objects tunneling through each other:**
- Enable `Ccd::enabled()` on fast-moving bodies.

**Ghost collisions on trimesh terrain:**
- Use `Collider::trimesh_with_flags(verts, indices, TrimeshFlags::FIX_INTERNAL_EDGES)`.

**Build is very slow or simulation runs slowly in dev:**
```toml
[profile.dev.package.bevy_rapier3d]
opt-level = 3
```
