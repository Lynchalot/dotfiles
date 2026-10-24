local layout = {
    name = "Dwindle Centred",
    icon = "",
    description = "Dwindle, but a lone window sits centred at 60% width (for ultrawides)"
}
if not hl then
    return layout
end

-- Same as HyDE's Dwindle preset, minus its bare ALT+letter binds (those clash with
-- apps and games; Super+J still toggles the split).
hl.config(
    {
        general = {
            layout = "dwindle"
        },
        dwindle = {
            force_split = 2
        }
    }
)

-- Centre a lone window: when a workspace has exactly one tiled, visible window, its
-- outer gaps grow on the left and right so the window sits in the middle at
-- CENTRE_WIDTH of the screen. The moment a second window opens, the rule no longer
-- matches and dwindle splits the full width as usual.
local CENTRE_WIDTH = 0.60
local GAP = 8 -- your normal outer gap

local widest = 0
for _, m in ipairs(hl.get_monitors() or {}) do
    local w = math.floor((tonumber(m.width) or 0) / (tonumber(m.scale) or 1))
    if w > widest then
        widest = w
    end
end
local side = math.max(GAP, math.floor(widest * (1 - CENTRE_WIDTH) / 2))

hl.workspace_rule(
    {
        workspace = "w[tv1]s[false]",
        gaps_out = {top = GAP, right = side, bottom = GAP, left = side}
    }
)

hl.gesture({fingers = 4, direction = "horizontal", action = "workspace"})
hl.gesture({fingers = 4, direction = "vertical", action = "workspace"})
