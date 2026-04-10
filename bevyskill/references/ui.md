# Bevy UI Reference (v0.18.x)

## Node Layout

`Node` is the core UI component. Uses flexbox layout.

```rust
Node {
    width: Val::Px(200.0),
    height: Val::Percent(100.0),
    position_type: PositionType::Absolute,
    top: Val::Px(10.0),
    left: Val::Px(10.0),
    display: Display::Flex,
    flex_direction: FlexDirection::Column,
    align_items: AlignItems::Center,
    justify_content: JustifyContent::Center,
    border: UiRect::all(Val::Px(2.0)),
    border_radius: BorderRadius::all(Val::Px(12.0)),
    ..default()
}
```

**Val variants:** `Val::Px(f32)`, `Val::Percent(f32)`, `Val::Auto`, `Val::Vw(f32)`, `Val::Vh(f32)`

---

## Styling Components

```rust
// Background and border
BackgroundColor(Color::srgb(0.12, 0.12, 0.12))
BorderColor::all(Color::WHITE.with_alpha(0.15))
BorderRadius::all(Val::Px(12.0))

// Z-layering
ZIndex(10)
GlobalZIndex(i32::MAX)  // always on top
```

### Box Shadow

```rust
commands.spawn((
    Node { width: Val::Px(164.0), height: Val::Px(164.0), ..default() },
    BackgroundColor(Color::srgb(0.21, 0.21, 0.21)),
    BoxShadow(vec![ShadowStyle {
        color: Color::BLACK.with_alpha(0.8),
        x_offset: Val::Px(20.0),
        y_offset: Val::Px(20.0),
        spread_radius: Val::Px(15.0),
        blur_radius: Val::Px(10.0),
    }]),
));

// Shadow quality (attach to Camera2d)
commands.spawn((Camera2d, BoxShadowSamples(6)));
```

### UiTransform (rotate/scale UI elements)

```rust
commands.spawn((
    Button,
    Node { width: Val::Px(80.0), height: Val::Px(80.0), ..default() },
    UiTransform::from_rotation(Rot2::radians(std::f32::consts::FRAC_PI_2)),
));

fn rotate_ui(mut query: Query<&mut UiTransform, With<TargetNode>>) {
    for mut transform in &mut query {
        transform.rotation *= Rot2::radians(0.1);
        transform.scale = Vec2::splat(1.5).clamp(Vec2::splat(0.25), Vec2::splat(3.0));
        transform.translation = Val2::px(x, y);
    }
}
```

---

## Text

### UI Text (screen-space)

```rust
commands.spawn((
    Text::new("Score: "),
    TextFont { font_size: 32.0, ..default() },
    TextColor(Color::WHITE),
    Node {
        position_type: PositionType::Absolute,
        top: Val::Px(5.0),
        left: Val::Px(5.0),
        ..default()
    },
    children![(
        TextSpan::default(),
        TextFont { font_size: 32.0, ..default() },
        TextColor(Color::srgb(1.0, 0.5, 0.5)),
    )],
));

// Update a text span
fn update_score(
    score: Res<Score>,
    root: Single<Entity, (With<ScoreUi>, With<Text>)>,
    mut writer: TextUiWriter,
) {
    *writer.text(*root, 1) = score.to_string();
}
```

### Text2d (in-world text)

```rust
commands.spawn((
    Text2d::new("@"),
    TextFont { font_size: 32.0, ..default() },
    TextColor(Color::WHITE),
    Transform::from_translation(Vec3::ZERO),
));

// Multi-span
commands.spawn((
    Text2d::default(),
    children![
        (TextSpan::new("Hello "), TextFont { font_size: 24.0, ..default() }),
        (TextSpan::new("World"), TextColor(Color::srgb(1., 0., 0.))),
    ]
));

// Update content
fn update(mut query: Query<&mut Text2d>) {
    for mut text in &mut query {
        **text = "new content".to_string();
    }
}

// Multi-span writer
fn update(query: Query<Entity, With<Text2d>>, mut writer: Text2dWriter) {
    for entity in &query {
        *writer.text(entity, 1) = "span content".to_string();
    }
}
```

**Do not interpolate `font_size` dynamically** — each unique value creates a font atlas that leaks memory. Use `Transform::scale` instead (see B0005).

---

## Buttons

```rust
const NORMAL: Color = Color::srgb(0.15, 0.15, 0.15);
const HOVERED: Color = Color::srgb(0.25, 0.25, 0.25);
const PRESSED: Color = Color::srgb(0.35, 0.75, 0.35);

fn button_system(
    mut interaction_query: Query<
        (&Interaction, &mut BackgroundColor),
        (Changed<Interaction>, With<Button>),
    >,
) {
    for (interaction, mut color) in &mut interaction_query {
        match *interaction {
            Interaction::Pressed => *color = PRESSED.into(),
            Interaction::Hovered => *color = HOVERED.into(),
            Interaction::None => *color = NORMAL.into(),
        }
    }
}

// Spawn a button
commands.spawn((
    Button,
    Node {
        width: Val::Px(150.0),
        height: Val::Px(65.0),
        justify_content: JustifyContent::Center,
        align_items: AlignItems::Center,
        ..default()
    },
    BackgroundColor(NORMAL),
    children![(
        Text::new("Play"),
        TextFont { font_size: 33.0, ..default() },
        TextColor(Color::WHITE),
    )],
));
```

---

## Multi-Camera UI

When multiple cameras exist, specify which one renders each UI root:

```rust
commands.spawn((
    Node {
        position_type: PositionType::Absolute,
        top: Val::Px(12.0),
        left: Val::Px(12.0),
        ..default()
    },
    UiTargetCamera(camera_entity),
    children![(Text::new("First window"), TextShadow::default())],
));
```

---

## children! Macro

```rust
commands.spawn((
    Text::new("Label: "),
    children![(
        TextSpan::default(),
        TextColor(Color::WHITE),
    )],
));
```

---

## Diagnostics / FPS Counter

```rust
use bevy::diagnostic::{DiagnosticsStore, FrameTimeDiagnosticsPlugin};

app.add_plugins(FrameTimeDiagnosticsPlugin::default());

fn update_fps(
    diagnostics: Res<DiagnosticsStore>,
    mut query: Query<&mut TextSpan, With<FpsText>>,
) {
    for mut span in &mut query {
        if let Some(fps) = diagnostics.get(&FrameTimeDiagnosticsPlugin::FPS)
            && let Some(value) = fps.smoothed()
        {
            **span = format!("{value:.2}");
        }
    }
}
```
