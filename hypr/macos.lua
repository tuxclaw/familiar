hl.config({
  general = { gaps_in = 6, gaps_out = 10, border_size = 0 },
  decoration = {
    rounding = 10,
    blur = { enabled = true, size = 8, passes = 2 },
    shadow = { enabled = true, range = 24, render_power = 3 },
  },
})

hl.curve("familiarSpring", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "familiarSpring", style = "popin 85%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "familiarSpring", style = "slide" })

o.window({ class = ".*" }, { float = true })
o.window({ class = "^(chromium|Alacritty|code)$" }, { tile = true })

hl.unbind("SUPER + SPACE")
o.bind("SUPER + SPACE", "Familiar launcher", surface("launcher"))
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Familiar app switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"app\"}'")
hl.unbind("SUPER + GRAVE")
o.bind("SUPER + GRAVE", "Familiar window switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"window\"}'")
hl.unbind("CTRL + UP")
o.bind("CTRL + UP", "Familiar overview", surface("overview"))

hl.unbind("SUPER + Q")
o.bind("SUPER + Q", "Quit app", hl.dsp.killactive)
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", hl.dsp.killactive)
hl.unbind("CTRL + LEFT")
o.bind("CTRL + LEFT", "Previous workspace", "hyprctl dispatch workspace e-1")
hl.unbind("CTRL + RIGHT")
o.bind("CTRL + RIGHT", "Next workspace", "hyprctl dispatch workspace e+1")
hl.unbind("SUPER + CTRL + Q")
o.bind("SUPER + CTRL + Q", "Lock screen", "omarchy-system-lock")
