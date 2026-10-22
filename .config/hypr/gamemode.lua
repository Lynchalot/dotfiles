-- Automatic game mode (adapted from github.com/electrocrem/gits, hypr/gits/gamemode.lua).
--
-- While a game is fullscreen on the workspace you're looking at, animations, blur and
-- shadows switch off; they come back exactly as they were as soon as you switch
-- workspace, open a scratchpad over the game, leave fullscreen or close it.
-- No config reload, so no hitch. Notifications / Do Not Disturb are left alone.
--
-- A game = a fullscreen window that says so (content type "game") or whose class looks
-- like one: Steam / Proton (steam_app_*), gamescope, Wine (*.exe).
-- Loaded from hyprland.lua. Set RICE_GAMEMODE=0 in the environment to disable.
if os.getenv("RICE_GAMEMODE") == "0" then
    return
end

local patterns = {"^steam_app_%d+$", "^gamescope$", "%.exe$"}
local KEYS = {"animations.enabled", "decoration.blur.enabled", "decoration.shadow.enabled"}
local saved -- values from before the game, while game mode is on

local function is_game(w)
    if w.content_type == "game" then
        return true
    end
    for _, class in ipairs({w.class or "", w.initial_class or ""}) do
        for _, pat in ipairs(patterns) do
            if class:match(pat) then
                return true
            end
        end
    end
    return false
end

-- a fullscreen game on the workspace its monitor is showing, with no scratchpad open over it
local function game_on_screen()
    for _, w in ipairs(hl.get_windows() or {}) do
        local m = w.monitor
        if (tonumber(w.fullscreen) or 0) > 0 and w.workspace and m and m.active_workspace
            and w.workspace.id == m.active_workspace.id and not m.active_special_workspace
            and is_game(w) then
            return w
        end
    end
end

-- set("decoration.blur.enabled", false) -> hl.config({decoration = {blur = {enabled = false}}})
local function set(key, value)
    local t = {}
    local node = t
    local parts = {}
    for part in key:gmatch("[^.]+") do
        parts[#parts + 1] = part
    end
    for i = 1, #parts - 1 do
        node[parts[i]] = {}
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
    hl.config(t)
end

local function check()
    local game = game_on_screen()
    if game and not saved then
        saved = {}
        for _, k in ipairs(KEYS) do
            saved[k] = hl.get_config(k)
            set(k, false)
        end
    elseif not game and saved then
        for _, k in ipairs(KEYS) do
            if saved[k] ~= nil then
                set(k, saved[k])
            end
        end
        saved = nil
    end
end

-- Check now, and once more shortly after: when "window.fullscreen" fires, the window's
-- fullscreen state isn't updated yet, so the immediate check alone misses it.
local function safe_check()
    pcall(check)
    pcall(hl.timer, function()
        pcall(check)
    end, {timeout = 100, type = "oneshot"})
end

for _, ev in ipairs({
    "window.fullscreen", "window.active", "window.close", "window.destroy",
    "window.move_to_workspace", "workspace.active", "workspace.special_active"
}) do
    hl.on(ev, safe_check)
end
safe_check() -- after a config reload: a game still on screen turns the effects off again
