-- Familiar shared Hyprland behavior.
-- Future installer hook: require("hypr.familiar") belongs immediately after
-- require("hypr.looknfeel"), never after require("hypr.bindings").
local familiar = "omarchy-shell shell"
local id = "io.github.tuxclaw.familiar"
local function surface(name, extra)
  return familiar .. " toggle " .. id .. " '{\"surface\":\"" .. name .. "\"" .. (extra or "") .. "}'"
end

hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Familiar: cycle desktop profile",
  familiar .. " call " .. id .. " cycleProfile ''")

hl.layer_rule({ match = { namespace = "familiar-bar" }, blur = true })
hl.layer_rule({ match = { namespace = "familiar-dock" }, blur = true })
hl.layer_rule({ match = { namespace = "familiar-switcher" }, no_anim = true, animation = "none" })
