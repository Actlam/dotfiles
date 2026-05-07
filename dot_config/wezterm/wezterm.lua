local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.color_scheme = "nord"
config.window_background_opacity = 0.93

config.font = wezterm.font("JetBrains Mono", {weight="Bold", stretch="Normal", style="Normal"})
config.font_size = 13.0

config.disable_default_key_bindings = true
local keybind = require 'keybinds'
config.keys = keybind.keys
config.key_tables = keybind.key_tables
config.leader = { key = ",", mods = "CTRL", timeout_milliseconds = 2000 }

return config

