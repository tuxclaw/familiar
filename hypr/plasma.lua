hl.config({
  general = { gaps_in = 4, gaps_out = 6, border_size = 2 },
  decoration = {
    rounding = 6,
    blur = { enabled = true, size = 5, passes = 1 },
    shadow = { enabled = false },
  },
})

hl.curve("familiarLinear", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "familiarLinear", style = "popin 95%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "familiarLinear", style = "slide" })

hl.unbind("ALT + F1")
o.bind("ALT + F1", "Familiar application launcher", surface("launcher"))
hl.unbind("SUPER")
o.bind("SUPER", "Familiar application launcher", surface("launcher"), { release = true })
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Familiar present windows", surface("overview"))
hl.unbind("ALT + TAB")
o.bind("ALT + TAB", "Familiar window switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"window\"}'")
hl.unbind("SUPER + D")
o.bind("SUPER + D", "Show desktop", "hyprctl dispatch togglespecialworkspace familiar-desktop")

hl.unbind("CTRL + F1")
o.bind("CTRL + F1", "Workspace 1", "hyprctl dispatch workspace 1")
hl.unbind("CTRL + F2")
o.bind("CTRL + F2", "Workspace 2", "hyprctl dispatch workspace 2")
hl.unbind("CTRL + F3")
o.bind("CTRL + F3", "Workspace 3", "hyprctl dispatch workspace 3")
hl.unbind("CTRL + F4")
o.bind("CTRL + F4", "Workspace 4", "hyprctl dispatch workspace 4")
