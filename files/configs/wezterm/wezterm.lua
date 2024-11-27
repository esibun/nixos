local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.front_end = "WebGpu"

-- Colors & Appearance
config.color_scheme = "Catppuccin Mocha"
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_background_opacity = 0.95
config.hide_mouse_cursor_when_typing = false

-- Fonts
config.font = wezterm.font_with_fallback({
  {
    family = "Fira Code",
    harfbuzz_features = { "zero=1", "ss01=1", "ss02=1", "ss04=1", "ss05=1" }
  },
  {
    family = "Symbols Nerd Font"
  },
  {
    family = "Font Awesome 5 Free"
  },
  {
    family = "Font Awesome 5 Brands"
  },
})
config.font_size = 10.0

-- Key Binding
config.keys = {
  {
    key = "q",
    mods = "CTRL|SHIFT",
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
}

return config
