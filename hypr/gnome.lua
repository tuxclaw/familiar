hl.config({
  general = { gaps_in = 8, gaps_out = 12, border_size = 1 },
  decoration = {
    rounding = 12,
    blur = { enabled = true, size = 6, passes = 2 },
    shadow = { enabled = false },
  },
})

hl.curve("familiarOut", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "familiarOut", style = "popin 90%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "familiarOut", style = "slide" })

hl.unbind("SUPER")
o.bind("SUPER", "Familiar overview", surface("overview"), { release = true })
hl.unbind("SUPER + A")
o.bind("SUPER + A", "Familiar app grid", surface("launcher"))
hl.unbind("ALT + TAB")
o.bind("ALT + TAB", "Familiar app switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"app\"}'")
hl.unbind("ALT + GRAVE")
o.bind("ALT + GRAVE", "Familiar window switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"window\"}'")
hl.unbind("ALT + F4")
o.bind("ALT + F4", "Close window", hl.dsp.window.close())

hl.unbind("SUPER + S")
o.bind("SUPER + S", "Familiar overview", surface("overview"))
hl.unbind("SUPER + PAGE_UP")
o.bind("SUPER + PAGE_UP", "Previous workspace", "hyprctl dispatch workspace e-1")
hl.unbind("SUPER + PAGE_DOWN")
o.bind("SUPER + PAGE_DOWN", "Next workspace", "hyprctl dispatch workspace e+1")
