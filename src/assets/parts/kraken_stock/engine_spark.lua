part {
  id = "kraken.engine.spark",
  author = "Seraphina",

  geometry = "assets/parts/engine_spark.glb",
  
  display_name = "48-7S \"Spark\" RP-1 engine",
  manufacturer = "Seraphina Aerospace Industries",
  description = "After a rash of incidents involving their fuel-rich engine designs running engine-rich, SAI obtained a Spark engine from a sketchy short green guy. While reverse-engineering, it was discovered that the engine ran far too fuel-rich, resulting in this modification.",
  categories = {"engine", "RP-1", "0.625m"},

  
  mass = 0.13,  -- tonnes, dry
  
  attach_nodes = {

    top = {
      position         = vec3(0, 0, 0),  -- model not produced yet, centered at top of engine.
      size             = 1,  -- 0.625m size
      tensile_strength = 90.0,  -- kN before joint breaks under pull
      shear_strength   = 67.5,  -- kN before joint breaks under shear
    },

    bottom = {
      position         = vec3(0, -0.5, 0),
      size             = 1,
      tensile_strength = 67.5,  -- connection on bottom is weaker
      shear_strength   = 45.0,
    },
  },
  
  modules = {
    engine {
      thrust      = 20,    -- kN, vacuum
      isp_vac     = 320,   -- s
      isp_sl      = 265,   -- s
      propellants = { RP1 = 0.3, Oxidizer = 0.7 },
    },
  },
}