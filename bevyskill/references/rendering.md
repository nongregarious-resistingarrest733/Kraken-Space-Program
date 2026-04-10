# Bevy Rendering Reference (v0.18.x)

## Camera

```rust
commands.spawn(Camera2d);                // 2D
commands.spawn(Camera3d::default());     // 3D
```

### Orthographic (2D / top-down)

```rust
use bevy::render::camera::ScalingMode;

commands.spawn((
    Camera2d,
    Projection::Orthographic(OrthographicProjection {
        scaling_mode: ScalingMode::AutoMax { max_width: 16.0, max_height: 9.0 },
        ..OrthographicProjection::default_2d()
    }),
));
```

### Perspective / FOV

```rust
commands.spawn((
    Camera3d::default(),
    Projection::from(PerspectiveProjection {
        fov: 90.0_f32.to_radians(),
        ..default()
    }),
));

// Modify at runtime:
fn change_fov(mut proj: Single<&mut Projection, With<MyCamera>>) {
    let Projection::Perspective(p) = proj.as_mut() else { return; };
    p.fov = 70.0_f32.to_radians();
}
```

### Camera Options (clear color, order, tonemapping)

```rust
use bevy::core_pipeline::tonemapping::Tonemapping;

commands.spawn((
    Camera3d::default(),
    Camera {
        clear_color: Color::WHITE.into(),
        order: 1,  // higher = renders on top
        ..default()
    },
    Tonemapping::TonyMcMapface,
));
```

**Tonemapping options:** `None`, `Reinhard`, `ReinhardLuminance`, `AcesFitted`, `AgX`, `SomewhatBoringDisplayTransform`, `TonyMcMapface`, `BlenderFilmic`

### Render Layers (multiple cameras / view models)

```rust
use bevy::camera::visibility::RenderLayers;

const WORLD_LAYER: usize = 0;
const VIEWMODEL_LAYER: usize = 1;

// World camera (layer 0 is default, implicit)
commands.spawn(Camera3d::default());

// Viewmodel camera — renders on top, only sees layer 1
commands.spawn((
    Camera3d::default(),
    Camera { order: 1, ..default() },
    RenderLayers::layer(VIEWMODEL_LAYER),
));

// Entity only on viewmodel layer
commands.spawn((
    Mesh3d(arm_mesh),
    RenderLayers::layer(VIEWMODEL_LAYER),
    light::NotShadowCaster,
));

// Light visible on both layers
commands.spawn((
    PointLight { ..default() },
    RenderLayers::from_layers(&[WORLD_LAYER, VIEWMODEL_LAYER]),
));
```

### HDR + Exposure

```rust
use bevy::render::view::Hdr;
use bevy::camera::Exposure;

commands.spawn((
    Camera3d::default(),
    Hdr,
    Exposure { ev100: 13.0 },
    Tonemapping::AcesFitted,
));

// WebGL: disable MSAA with HDR
#[cfg(target_arch = "wasm32")]
commands.spawn((Camera3d::default(), Hdr, Msaa::Off));
```

### Color Grading

```rust
use bevy::render::view::{ColorGrading, ColorGradingGlobal};

commands.spawn((
    Camera3d::default(),
    ColorGrading {
        global: ColorGradingGlobal { exposure: 0.5, post_saturation: 1.1, ..default() },
        ..default()
    },
));
```

### World ↔ Viewport Conversion

```rust
fn update(camera: Single<(&Camera, &GlobalTransform)>, window: Single<&Window>) {
    let (camera, camera_transform) = *camera;

    // Screen → World (2D)
    if let Some(cursor) = window.cursor_position()
        && let Ok(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor) { }

    // Screen → World ray (3D), intersect with ground plane
    if let Some(cursor) = window.cursor_position()
        && let Ok(ray) = camera.viewport_to_world(camera_transform, cursor)
        && let Some(point) = ray.plane_intersection_point(ground_translation, InfinitePlane3d::new(Vec3::Y)) { }

    // World → Screen
    let screen_pos = camera.world_to_viewport(camera_transform, world_pos).unwrap();
}
```

---

## Sprites (2D)

```rust
// Colored rectangle
commands.spawn((
    Sprite::from_color(Color::srgb(0.3, 0.3, 0.7), Vec2::ONE),
    Transform {
        translation: Vec3::ZERO,
        scale: Vec2::new(120.0, 20.0).extend(1.0),  // z-scale MUST be 1.0
        ..default()
    },
));

// Textured sprite
commands.spawn((
    Sprite::from_image(asset_server.load("player.png")),
    Transform::from_translation(Vec3::ZERO),
));
```

**In 2D:** `translation.z` controls draw order. `scale.z` must always be `1.0`.

### Texture Atlas / Spritesheets

```rust
fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut atlas_layouts: ResMut<Assets<TextureAtlasLayout>>,
) {
    let texture = asset_server.load("spritesheet.png");
    let layout = atlas_layouts.add(TextureAtlasLayout::from_grid(
        UVec2::splat(64), 9, 12, None, None,
    ));
    commands.spawn((
        Sprite::from_atlas_image(texture, TextureAtlas { layout, index: 0 }),
        Transform::from_translation(Vec3::ZERO),
    ));
}

fn animate(mut query: Query<&mut Sprite>) {
    for mut sprite in &mut query {
        if let Some(atlas) = &mut sprite.texture_atlas {
            atlas.index = (atlas.index + 1) % total_frames;
        }
    }
}
```

---

## 3D Meshes

```rust
// Colored mesh
commands.spawn((
    Mesh3d(meshes.add(Cuboid::new(1.0, 1.0, 1.0))),
    MeshMaterial3d(materials.add(StandardMaterial {
        base_color: Color::srgb(0.8, 0.7, 0.6),
        ..default()
    })),
    Transform::from_xyz(0.0, 0.5, 0.0),
));

// Common primitives
Cuboid::new(x, y, z)
Sphere::new(radius)
Cylinder::new(radius, height)
Plane3d::default()
```

### 2D Mesh + Material

```rust
// Circle
commands.spawn((
    Mesh2d(meshes.add(Circle::default())),
    MeshMaterial2d(materials.add(Color::srgb(1.0, 0.5, 0.5))),
    Transform::from_translation(pos).with_scale(Vec2::splat(diameter).extend(1.0)),
));
```

---

## Lights

```rust
// Point light
commands.spawn(PointLight {
    intensity: 1_500_000.0,  // lumens
    shadows_enabled: true,
    ..default()
});

// Spot light
commands.spawn((
    SpotLight {
        intensity: 50_000.0,
        color: Color::WHITE,
        shadows_enabled: true,
        inner_angle: 0.76,
        outer_angle: 0.94,
        ..default()
    },
    Transform::from_xyz(0.0, 5.0, 0.0).looking_at(Vec3::ZERO, Vec3::Y),
));

// Directional light
commands.spawn((
    DirectionalLight {
        illuminance: 15_000.0,
        shadows_enabled: true,
        ..default()
    },
    Transform::from_rotation(Quat::from_euler(EulerRot::ZYX, 0.0, 1.0, -PI / 4.)),
    CascadeShadowConfigBuilder {
        num_cascades: 3,
        maximum_distance: 10.0,
        ..default()
    }.build(),
));

// Directional from a direction vector
Transform::default().looking_to(Vec3::new(-1.0, -3.0, 0.5), Vec3::Y)
```

### Ambient Light

```rust
app.insert_resource(GlobalAmbientLight {
    color: Color::WHITE,
    brightness: 2000.0,
    ..default()
});
app.insert_resource(GlobalAmbientLight::NONE);
```

### Shadow Modifiers

```rust
use bevy::light::{NotShadowCaster, NotShadowReceiver};

commands.spawn((Mesh3d(mesh), NotShadowCaster));
commands.spawn((Mesh3d(mesh), NotShadowReceiver));
```

---

## Materials

### StandardMaterial

```rust
StandardMaterial {
    base_color: Color::srgb(0.8, 0.7, 0.6),
    base_color_texture: Some(asset_server.load("texture.png")),
    normal_map_texture: Some(normal_handle),
    depth_map: Some(depth_handle),
    emissive: LinearRgba::rgb(10., 4., 1.),
    unlit: true,
    alpha_mode: AlphaMode::Blend,
    metallic: 1.0,
    perceptual_roughness: 0.089,
    parallax_depth_scale: 0.09,
    parallax_mapping_method: ParallaxMappingMethod::Relief { max_steps: 4 },
    cull_mode: None,  // render both sides
    ..default()
}

// Normal map — must NOT be sRGB
let normal = asset_server.load_with_settings("normal.png", |s: &mut ImageLoaderSettings| {
    s.is_srgb = false;
});

// Tangents required for normal maps
mesh.generate_tangents().unwrap();
```

### Custom Material (Shader)

```rust
use bevy::{reflect::TypePath, render::render_resource::AsBindGroup, shader::ShaderRef};

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct CustomMaterial {
    #[uniform(0)]
    color: LinearRgba,
    #[texture(1)]
    #[sampler(2)]
    texture: Option<Handle<Image>>,
}

impl Material for CustomMaterial {
    fn fragment_shader() -> ShaderRef { "shaders/my_shader.wgsl".into() }
}

app.add_plugins(MaterialPlugin::<CustomMaterial>::default());
```

### ExtendedMaterial

```rust
use bevy::pbr::{ExtendedMaterial, MaterialExtension};

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct MyExtension {
    #[uniform(100)]
    my_value: f32,
}

impl MaterialExtension for MyExtension {
    fn fragment_shader() -> ShaderRef { "shaders/my_extension.wgsl".into() }
    fn deferred_fragment_shader() -> ShaderRef { "shaders/my_extension.wgsl".into() }
}

app.add_plugins(MaterialPlugin::<ExtendedMaterial<StandardMaterial, MyExtension>>::default());
```

---

## WGSL Shaders

### Fragment Shader (mesh)

```wgsl
#import bevy_pbr::{
    mesh_view_bindings::globals,
    forward_io::VertexOutput,
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let t = globals.time;           // seconds since startup
    let uv = in.uv;                 // 0.0–1.0
    let world_pos = in.world_position.xyz;
    // ...
}
```

### Full-Screen Post-Process Shader

```wgsl
#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;
@group(0) @binding(2) var<uniform> settings: MySettings;

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    return textureSample(screen_texture, texture_sampler, in.uv);
}
```

### ExtractComponent (passing data to shaders)

```rust
#[derive(Component, Default, Clone, Copy, ExtractComponent, ShaderType)]
struct MySettings {
    intensity: f32,
    #[cfg(feature = "webgl2")]
    _webgl2_padding: Vec3,  // WebGL2 requires 16-byte alignment
}

app.add_plugins((
    ExtractComponentPlugin::<MySettings>::default(),
    UniformComponentPlugin::<MySettings>::default(),
));
```

---

## Post-Processing

### Bloom

```rust
use bevy::post_process::bloom::Bloom;
commands.spawn((Camera3d::default(), Bloom::default()));
commands.spawn((Camera3d::default(), Bloom::NATURAL));
```

### Volumetric Fog

```rust
use bevy::light::{FogVolume, VolumetricFog, VolumetricLight};

commands.spawn((Camera3d::default(), VolumetricFog { ambient_intensity: 0.0, ..default() }));
commands.spawn((FogVolume::default(), Transform::from_scale(Vec3::splat(35.0))));
commands.spawn((PointLight { shadows_enabled: true, ..default() }, VolumetricLight));
```

### Distance Fog

```rust
commands.spawn((
    Camera3d::default(),
    DistanceFog {
        color: Color::srgb_u8(43, 44, 47),
        falloff: FogFalloff::Linear { start: 1.0, end: 8.0 },
        ..default()
    },
));
```

### Atmosphere (PBR)

```rust
use bevy::pbr::{Atmosphere, AtmosphereSettings};

commands.spawn((
    Camera3d::default(),
    Atmosphere::earthlike(scattering_mediums.add(ScatteringMedium::default())),
    AtmosphereSettings::default(),
    Exposure { ev100: 13.0 },
    Tonemapping::AcesFitted,
    Bloom::NATURAL,
));
```

### Screen Space Reflections

```rust
use bevy::pbr::ScreenSpaceReflections;
commands.spawn((Camera3d::default(), ScreenSpaceReflections::default()));
// Requires deferred rendering
```

### Skybox

```rust
use bevy::core_pipeline::Skybox;

commands.spawn((
    Camera3d::default(),
    Skybox {
        image: asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
        brightness: 1000.0,
        ..default()
    },
));
```

### Environment Map (IBL)

```rust
commands.spawn((
    Camera3d::default(),
    EnvironmentMapLight {
        diffuse_map: asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
        specular_map: asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
        intensity: 2000.0,
        ..default()
    },
));
```

---

## Anti-Aliasing

```rust
// MSAA (default; incompatible with deferred rendering)
commands.spawn((Camera3d::default(), Msaa::Sample4));
commands.spawn((Camera3d::default(), Msaa::Off));

// FXAA
use bevy::anti_alias::fxaa::Fxaa;
commands.spawn((Camera3d::default(), Msaa::Off, Fxaa::default()));

// SMAA
use bevy::anti_alias::smaa::{Smaa, SmaaPreset};
commands.spawn((Camera3d::default(), Msaa::Off, Smaa { preset: SmaaPreset::High, ..default() }));

// TAA (requires prepasses)
use bevy::anti_alias::taa::TemporalAntiAliasing;
use bevy::core_pipeline::prepass::{DepthPrepass, MotionVectorPrepass};
commands.spawn((Camera3d::default(), Msaa::Off, TemporalAntiAliasing::default(), DepthPrepass, MotionVectorPrepass));

// CAS (sharpening)
use bevy::anti_alias::contrast_adaptive_sharpening::ContrastAdaptiveSharpening;
commands.spawn((Camera3d::default(), ContrastAdaptiveSharpening { enabled: true, sharpening_strength: 0.6, ..default() }));
```

---

## Deferred Rendering

```rust
use bevy::core_pipeline::prepass::{DepthPrepass, NormalPrepass, MotionVectorPrepass, DeferredPrepass};
use bevy::pbr::DefaultOpaqueRendererMethod;

app.insert_resource(DefaultOpaqueRendererMethod::deferred());
// Note: MSAA must be Off for deferred

commands.spawn((Camera3d::default(), Msaa::Off, DepthPrepass, MotionVectorPrepass, DeferredPrepass));

// Per-material override back to forward
StandardMaterial { opaque_render_method: OpaqueRendererMethod::Forward, ..default() }
```

---

## Occlusion Culling

```rust
use bevy::render::experimental::occlusion_culling::OcclusionCulling;
use bevy::core_pipeline::prepass::DepthPrepass;

commands.spawn((Camera3d::default(), DepthPrepass, OcclusionCulling));
```

---

## Texture Sampling Settings

```rust
use bevy::image::{ImageSampler, ImageSamplerDescriptor, ImageAddressMode, ImageFilterMode};

let handle = asset_server.load_with_settings::<Image, ImageLoaderSettings>(
    "texture.png",
    |settings| {
        settings.is_srgb = false;
        settings.sampler = ImageSampler::Descriptor(ImageSamplerDescriptor {
            address_mode_u: ImageAddressMode::Repeat,
            address_mode_v: ImageAddressMode::Repeat,
            mag_filter: ImageFilterMode::Linear,
            min_filter: ImageFilterMode::Linear,
            ..default()
        });
    },
);
```

---

## GLTF / Scene Loading

```rust
commands.spawn(SceneRoot(asset_server.load("models/MyModel.glb#Scene0")));

// With GltfAssetLabel
commands.spawn(SceneRoot(
    asset_server.load(GltfAssetLabel::Scene(0).from_asset("models/MyModel.glb"))
));

// With transform
commands.spawn((
    SceneRoot(asset_server.load("models/player.glb#Scene0")),
    Transform::from_translation(Vec3::new(1.0, 0.0, 0.0)),
));

// Access GLTF data after loading
fn use_gltf(gltfs: Res<Assets<Gltf>>, handle: Res<MyGltfHandle>) {
    if let Some(gltf) = gltfs.get(&handle.0) {
        let scene = gltf.scenes.first().unwrap().clone();
    }
}
```

---

## Transforms

### Rotation

```rust
transform.rotate_y(speed * TAU * time.delta_secs());
transform.rotate_x(0.55 * time.delta_secs());
transform.rotation = Quat::from_euler(EulerRot::YXZ, yaw, pitch, roll);
let (yaw, pitch, roll) = transform.rotation.to_euler(EulerRot::YXZ);
transform.rotate(delta_quat);
```

### First-Person Mouse Look

```rust
use bevy::input::mouse::AccumulatedMouseMotion;

fn rotate_camera(
    mouse_motion: Res<AccumulatedMouseMotion>,
    mut camera: Single<&mut Transform, With<Camera>>,
) {
    let delta = mouse_motion.delta;
    if delta == Vec2::ZERO { return; }

    let (yaw, pitch, roll) = camera.rotation.to_euler(EulerRot::YXZ);
    let yaw = yaw + (-delta.x * sensitivity_x);
    const PITCH_LIMIT: f32 = std::f32::consts::FRAC_PI_2 - 0.01;
    let pitch = (pitch + (-delta.y * sensitivity_y)).clamp(-PITCH_LIMIT, PITCH_LIMIT);
    camera.rotation = Quat::from_euler(EulerRot::YXZ, yaw, pitch, roll);
}
// Do NOT multiply mouse delta by delta_time — it's already a full-frame delta.
```

### Isometry (for primitives/gizmos)

```rust
use bevy::math::Isometry2d;

let rotation = transform.rotation.to_scaled_axis().z;
let isometry = Isometry2d::new(transform.translation.xy(), Rot2::radians(rotation));

gizmos.primitive_2d(&CIRCLE, isometry, Color::WHITE);
let aabb = HEART.aabb_2d(isometry);

// 3D
let isometry = transform.to_isometry();
```

---

## Audio

```rust
// One-shot
commands.spawn((AudioPlayer(sound_handle.clone()), PlaybackSettings::DESPAWN));

// Looping
commands.spawn((AudioPlayer(music_handle.clone()), PlaybackSettings::LOOP));

// Spatial audio emitter
commands.spawn((
    AudioPlayer::new(asset_server.load("sounds/ambient.ogg")),
    PlaybackSettings::LOOP.with_spatial(true),
    Transform::from_xyz(0.0, 0.0, 0.0),
));

// Spatial listener (attach to player/camera)
let listener = SpatialListener::new(gap);
commands.spawn((Transform::default(), Visibility::default(), listener));

// Mute toggle
fn mute(kb: Res<ButtonInput<KeyCode>>, mut sinks: Query<&mut SpatialAudioSink>) {
    if kb.just_pressed(KeyCode::KeyM) {
        for mut sink in &mut sinks { sink.toggle_mute(); }
    }
}
```

---

## Color Utilities

```rust
Color::srgb(r, g, b)       // 0.0–1.0
Color::srgba(r, g, b, a)
Color::srgb_u8(124, 144, 255)

// Palettes
use bevy::color::palettes::css::*;       // RED, BLUE, WHITE, etc.
use bevy::color::palettes::tailwind::*; // TEAL_200, SKY_200, ROSE_300, etc.

Color::from(tailwind::TEAL_200)

// Mix (works in any color space)
let mixed = color_a.mix(&color_b, t);
```

### ops:: (portable math — use for WASM determinism)

```rust
use bevy::math::ops;
ops::sin(t)
ops::cos(t)
// Identical behavior on all platforms including wasm32
```
