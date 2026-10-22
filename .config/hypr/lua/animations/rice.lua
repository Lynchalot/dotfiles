local animation = {
    name = "Rice",
    icon = "",
    description = "One calm curve everywhere, snappy: ~0.2s fades, ~0.25s windows, 0.3s workspaces"
}

if not hl then
    return animation
end

-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
-- (Hyprland speed is in 100ms units, so 2.6 = 260ms before scaling.)
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end

-- One family of curves:
--   rice    ease-out (quint-like): things arrive quickly and settle, no bounce
--   riceOut ease-in:              things leave a little faster than they came
--   liner   linear:               only for the looping border gradient
hl.curve("rice", {type = "bezier", points = {{0.22, 1}, {0.36, 1}}})
hl.curve("riceOut", {type = "bezier", points = {{0.55, 0}, {1, 0.45}}})
hl.curve("liner", {type = "bezier", points = {{1, 1}, {1, 1}}})

-- Windows
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(2.6), bezier = "rice", style = "popin 92%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(1.8), bezier = "riceOut", style = "popin 92%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(2.6), bezier = "rice", style = "slide"})

-- Fades (window open/close, focus dim, shadows, DPMS)
hl.animation({leaf = "fade", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(1.6), bezier = "riceOut"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(1.8), bezier = "rice"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(1.5), bezier = "riceOut"})

-- Layers (rofi, swaync, logout menu): slide in from their edge, same curve
hl.animation({leaf = "layersIn", enabled = true, speed = prod(2), bezier = "rice", style = "slide"})
hl.animation({leaf = "layersOut", enabled = true, speed = prod(1.6), bezier = "riceOut", style = "slide"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(2), bezier = "rice"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(1.6), bezier = "riceOut"})

-- Workspaces: horizontal slide (natural on an ultrawide); scratchpad drops in vertically
hl.animation({leaf = "workspaces", enabled = true, speed = prod(3), bezier = "rice", style = "slide"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(3), bezier = "rice", style = "slide"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(3), bezier = "rice", style = "slide"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(2.6), bezier = "rice", style = "slidefadevert 15%"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(2.6), bezier = "rice", style = "slidefadevert 15%"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(2.2), bezier = "riceOut", style = "slidefadevert 15%"})

-- Borders: colour changes on focus use the same curve; gradient themes keep their slow loop
hl.animation({leaf = "border", enabled = true, speed = prod(2.2), bezier = "rice"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(82), bezier = "liner", style = "loop"})

-- Centred launchers should grow in place rather than slide from an edge.
-- pcall so an unsupported key can never break the config.
pcall(hl.layer_rule, {name = "rice_rofi_popin", match = {namespace = "rofi"}, animation = "popin 94%"})
