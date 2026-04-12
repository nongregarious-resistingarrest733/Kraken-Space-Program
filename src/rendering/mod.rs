//! Rendering module.
//!
//! # Rules (from design.md)
//!
//! - `render_sync.rs` is the **only** file in the entire codebase that converts
//!   f64 [`SimPosition`] values to f32 [`Transform`] values.
//! - No other file may call `.as_vec3()` or cast a simulation position to f32.
//! - Custom render nodes (atmosphere scattering, terrain, part instancing) are
//!   Phase 4+ — nothing custom lives here yet.

pub mod render_sync;
