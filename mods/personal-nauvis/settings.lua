data:extend({
  {
    type = "int-setting",
    name = "personal-nauvis-max-players",
    setting_type = "startup",
    default_value = 8,
    minimum_value = 2,
    maximum_value = 16,
    order = "a"
  },
  {
    type = "int-setting",
    name = "personal-nauvis-pvp-grace-minutes",
    setting_type = "runtime-global",
    default_value = 30,
    minimum_value = 0,
    maximum_value = 180,
    order = "b"
  }
})
