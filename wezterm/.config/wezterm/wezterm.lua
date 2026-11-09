local wezterm = require 'wezterm'
local config = wezterm.config_builder()
require('shell').apply_to_config(config)
config.front_end = 'WebGpu'

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- Styling
config.font_size = 14
config.line_height = 1.2
config.color_scheme = 'Belge (terminal.sexy)'
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.default_cursor_style = 'BlinkingBar'
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.7,
}

return config
