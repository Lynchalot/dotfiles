-- ~/.config/hypr/hyprland.lua
-- Loaded LAST by ~/.local/share/hypr/hyde.lua via check_require("hyprland"),
-- so everything here overrides HyDE's defaults.
--
-- Ported from the pre-Lua hyprlang configs on 2026-07-28:
--   keybindings.conf / windowrules.conf / userprefs.conf / monitors.conf
-- Only the deltas from HyDE's defaults are here; anything HyDE already
-- provides in lua/key_binds.lua etc. is intentionally not repeated.

local MOD = hyde.config.modifiers.main
local _F

-- ─────────────────────────────────────────────────────────────
-- Monitor
-- ─────────────────────────────────────────────────────────────
-- Old monitors.conf asked for 240Hz, which DP-1 does not advertise, so
-- Hyprland silently fell back to 180Hz @ scale 1.0. That fallback is what
-- you have been running. nwg-displays' monitors.lua said scale 1.1 but was
-- never sourced. Pinning the real values here; change scale to 1.1 if that
-- is what you actually wanted.
hl.monitor({
    output = "DP-1",
    mode = "3440x1440@180.0",
    position = "0x0",
    scale = 1.0
})

-- ─────────────────────────────────────────────────────────────
-- Environment (from userprefs.conf)
-- ─────────────────────────────────────────────────────────────
hl.env("TERMINAL", "kitty")        -- so rofi-sensible-terminal picks themed kitty
hl.env("__GL_VRR_ALLOWED", "1")

-- ─────────────────────────────────────────────────────────────
-- Misc config (from userprefs.conf)
-- ─────────────────────────────────────────────────────────────
hl.config({
    misc = {
        vrr = 2                    -- fullscreen-only VRR, good default for gaming
    },
    input = {
        kb_options = "compose:ralt",   -- Right Alt is the Compose key (e.g. Compose - a -> ā)
        touchpad = {
            natural_scroll = false
        }
    },
    cursor = {
        -- NVIDIA (RTX 3060) hardware cursors go invisible over some surfaces --
        -- GTK file choosers drawn by xdg-desktop-portal-gtk in particular.
        -- INT, not BOOL: 0 = hardware cursors on, 1 = off, 2 = auto.
        -- ~/.config/hypr/nvidia.conf sets this too but is a hyprlang orphan
        -- that nothing reads under the Lua config; this is the live one.
        no_hardware_cursors = 1
    }
})

-- ─────────────────────────────────────────────────────────────
-- Animations
-- ─────────────────────────────────────────────────────────────
-- Nothing here on purpose. MOD+SHIFT+Y is authoritative: the selector writes
-- ~/.local/state/hyde/lua_state/animations.lua and dynamic.lua requires it.
--
-- Do NOT re-add `require("animations.<name>")` here. This file loads last, so
-- it would silently override every selector choice. The earlier need for that
-- line was a stale ~/.local/lib/hyde/animations.sh shadowing animations.lua
-- (hyde-shell resolved .sh before .lua); the v26.7.4 migration moved it aside.

-- ─────────────────────────────────────────────────────────────
-- Layer rules (from userprefs.conf)
-- ─────────────────────────────────────────────────────────────
-- Re-declaring hyde_layer_blur by the same name replaces HyDE's version,
-- which includes waybar. This is the override that keeps waybar unblurred.
hl.layer_rule(
    {
        name = "hyde_layer_blur",
        match = {
            namespace = "^(rofi|notifications|swaync-(notification-window|control-center)|logout_dialog)$"
        },
        blur = true
    }
)

-- ─────────────────────────────────────────────────────────────
-- Window rules (from windowrules.conf)
-- ─────────────────────────────────────────────────────────────
-- opacity takes a hyprlang string: "<active> <inactive> <fullscreen>"
-- (it is CLuaConfigString in the bindings, not a numeric table)
-- Plain values MULTIPLY with HyDE's global 0.90/0.75, so they can never reach
-- solid. `override` after a value sets it absolutely instead. Solid when
-- focused; inactive matches HyDE's global inactive_opacity (0.75).
hl.window_rule({
    name = "user_opacity_zen",
    match = {class = "^(zen)$"},
    opacity = "1 override 0.75 override 1 override"
})

hl.window_rule({
    name = "user_opacity_firefox",
    match = {class = "^(firefox)$"},
    opacity = "1 override 0.75 override 1 override"
})

hl.window_rule({
    name = "user_opacity_claude",
    match = {class = "^(claude-desktop)$"},
    opacity = "0.90 0.90 1"
})

hl.window_rule({
    name = "user_opacity_qbittorrent",
    match = {class = "^(org.qbittorrent.qBittorrent)$"},
    opacity = "1 1 1"
})

hl.window_rule({
    name = "user_opacity_polkit_kde",
    match = {class = "^(org.kde.polkit-kde-authentication-agent-1)$"},
    opacity = "0.80 0.70 1"
})

hl.window_rule({
    name = "user_opacity_polkit_gnome",
    match = {class = "^(polkit-gnome-authentication-agent-1)$"},
    opacity = "0.80 0.70 1"
})

-- Celluloid - open windowed, not maximised
hl.window_rule({
    name = "user_celluloid_no_maximize",
    match = {class = "^(io.github.celluloid_player.Celluloid)$"},
    suppress_event = "maximize"
})

-- Autostart workspace assignments
hl.window_rule({
    name = "user_ws_zen",
    match = {class = "^(zen)$"},
    workspace = "1 silent"
})

hl.window_rule({
    name = "user_ws_vesktop",
    match = {class = "^(vesktop)$"},
    workspace = "special silent"
})

-- ─────────────────────────────────────────────────────────────
-- Startup (from userprefs.conf exec-once)
-- ─────────────────────────────────────────────────────────────

-- Notification daemon: swaync, not HyDE's dunst default.
-- HyDE hardcodes dunst in ~/.local/share/hypr/lua/variables.lua (hc.start.notifications).
-- Only one process can own the org.freedesktop.Notifications DBus name, so when dunst
-- wins the race swaync exits 1 on startup, systemd retries it 4x, hits the start limit,
-- and every MOD+N then leaves a swaync-client hanging on a daemon that isn't there.
-- Overriding here works because start_up.lua reads hyde.config.start.notifications when
-- the hyprland.start event fires, and this file loads after variables.lua (see
-- ~/.local/share/hypr/hyde.lua: require("variables") at 41, check_require("hyprland") at 59).
-- Setting it here rather than editing variables.lua keeps it through HyDE updates.
-- NOTE: the [hyprland-start] notifications key in ~/.config/hyde/config.toml is inert
-- under the Lua config -- config.lua lists "hyprland-start" as an ignored key.
hyde.config.start.notifications =
    "hyde-shell app -u hyde-" ..
    (os.getenv("XDG_SESSION_DESKTOP") or "Hyprland") .. "-notifications.service -t service -- swaync"

hl.on(
    "hyprland.start",
    function()
        hl.exec_cmd("otd daemon")
        hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/update-splash.sh")

        -- Autostarted apps. These have .desktop files in ~/.config/autostart/,
        -- but XDG autostart NEVER FIRES on this machine: the session is started
        -- by /usr/bin/start-hyprland (the plain hyprland.desktop session), not by
        -- uwsm. Without uwsm, wayland-session-xdg-autostart@Hyprland.target stays
        -- inactive, so xdg-desktop-autostart.target never activates and every
        -- app-*@autostart.service sits dead. Launching them here instead also
        -- guarantees they start AFTER this file's window_rules are registered,
        -- so the workspace assignments below actually match.
        hl.exec_cmd("zen-browser")            -- -> workspace 1  (user_ws_zen)
        hl.exec_cmd("vesktop")                -- -> special      (user_ws_vesktop)
        -- NB: do NOT add `thunar --daemon` here. On Thunar 4.20 it returns
        -- immediately (exit 0) and leaves no process -- the daemon role is handled
        -- by D-Bus activation via org.xfce.Thunar.service. It is a silent no-op.
        -- To keep Thunar warm it has to be launched normally (`thunar`), which
        -- opens a window.
    end
)

-- ─────────────────────────────────────────────────────────────
-- Keybinds
-- ─────────────────────────────────────────────────────────────

-- Plain fullscreen toggle, mirroring HyDE's own cycle helper.
local toggle_fullscreen = function()
    local w = assert(hl.get_active_window(), "No active window to toggle fullscreen")
    local next_state = (tonumber(w.fullscreen) or 0) == 0 and 2 or 0
    hl.dispatch(
        hl.dsp.window.fullscreen_state({internal = next_state, client = next_state, window = w})
    )
end

-- ── Window management overrides ──
-- Your old config routed MOD+Q and ALT+F4 through dontkillsteam.sh. That
-- script is deprecated upstream (its own header says so — Hyprland no longer
-- fully kills Steam) and it calls `hyprctl dispatch killactive`, which the
-- Lua config manager rejects. Using the normal close dispatcher instead.
_F = {description = "[Window Management] close focused window"}
hl.bind(MOD .. " + Q", hl.dsp.window.close(), _F)
_F = {description = "[Window Management] close focused window"}
hl.bind("ALT + F4", hl.dsp.window.close(), _F)

-- HyDE default is CTRL+Delete; you use MOD+Delete.
_F = {description = "[Window Management] kill hyprland session"}
hl.bind(MOD .. " + Delete", hl.dsp.exit(), _F)

_F = {description = "[Window Management] toggle fullscreen"}
hl.bind("ALT + grave", toggle_fullscreen, _F)

-- HyDE default binds MOD+SHIFT+F to nothing and MOD+F to window pin.
-- You want MOD+F for Steam (below), so pin moves to MOD+SHIFT+F.
_F = {description = "[Window Management] toggle pin on focused window"}
hl.bind(MOD .. " + SHIFT + F", hl.dsp.exec_cmd(hyde.sh.window.pin()), _F)

-- ── Personal app launchers ──
-- NOTE: MOD+F overrides HyDE's window-pin default. Pin is on MOD+SHIFT+F.
_F = {description = "[Launcher|Apps] steam"}
hl.bind(MOD .. " + F", hl.dsp.exec_cmd("steam"), _F)
_F = {description = "[Launcher|Apps] vesktop"}
hl.bind(MOD .. " + D", hl.dsp.exec_cmd("vesktop"), _F)
_F = {description = "[Launcher|Apps] spotify"}
hl.bind(MOD .. " + M", hl.dsp.exec_cmd("spotify"), _F)
_F = {description = "[Launcher|Apps] claude"}
hl.bind(MOD .. " + ALT + C", hl.dsp.exec_cmd("claude-desktop"), _F)

-- Your dropdown terminal is a floating window, not HyDE's pypr console on MOD+grave.
_F = {description = "[Launcher|Apps] dropdown terminal"}
hl.bind(
    MOD .. " + ALT + T",
    hl.dsp.exec_cmd("[float; move 20% 5%; size 60% 60%] " .. (os.getenv("TERMINAL") or "kitty")),
    _F
)

_F = {description = "[Launcher|Apps] notification center"}
hl.bind(MOD .. " + N", hl.dsp.exec_cmd("swaync-client -t"), _F)
_F = {description = "[Utilities] system update"}
-- `systemupdate.sh` is retired by the v26.7.4 migration; system.update.py replaces it.
hl.bind(MOD .. " + U", hl.dsp.exec_cmd("hyde-shell system.update up"), _F)

-- ── Media keys on the nav cluster ──
-- Print / Scroll_Lock / Pause repurposed as transport controls.
_F = {description = "[Hardware Controls|Media] previous media", locked = true}
hl.bind("Print", hl.dsp.exec_cmd("playerctl previous"), _F)
_F = {description = "[Hardware Controls|Media] play/pause media", locked = true}
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("playerctl play-pause"), _F)
_F = {description = "[Hardware Controls|Media] stop media", locked = true}
hl.bind("SHIFT + Scroll_Lock", hl.dsp.exec_cmd("playerctl stop"), _F)
_F = {description = "[Hardware Controls|Media] next media", locked = true}
hl.bind("Pause", hl.dsp.exec_cmd("playerctl next"), _F)

-- ── Media on the home row ──
_F = {description = "[Hardware Controls|Media] previous media", locked = true}
hl.bind(MOD .. " + CONTROL + Z", hl.dsp.exec_cmd("playerctl previous"), _F)
_F = {description = "[Hardware Controls|Media] play/pause media", locked = true}
hl.bind(MOD .. " + CONTROL + X", hl.dsp.exec_cmd("playerctl play-pause"), _F)
_F = {description = "[Hardware Controls|Media] next media", locked = true}
hl.bind(MOD .. " + CONTROL + C", hl.dsp.exec_cmd("playerctl next"), _F)
_F = {description = "[Hardware Controls|Media] rewind media", locked = true}
hl.bind(MOD .. " + CONTROL + SHIFT + Z", hl.dsp.exec_cmd("playerctl position 5-"), _F)
_F = {description = "[Hardware Controls|Media] stop media", locked = true}
hl.bind(MOD .. " + CONTROL + SHIFT + X", hl.dsp.exec_cmd("playerctl stop"), _F)
_F = {description = "[Hardware Controls|Media] fast-forward media", locked = true}
hl.bind(MOD .. " + CONTROL + SHIFT + C", hl.dsp.exec_cmd("playerctl position 5+"), _F)

-- ── Screenshots on P, not HyDE's S ──
_F = {description = "[Utilities] snip screen", locked = true}
hl.bind(MOD .. " + P", hl.dsp.exec_cmd(hyde.sh.screenshot.snip()), _F)
_F = {description = "[Utilities] freeze and snip screen", locked = true}
hl.bind(MOD .. " + CONTROL + P", hl.dsp.exec_cmd(hyde.sh.screenshot.freeze()), _F)
_F = {description = "[Utilities] print monitor", locked = true}
hl.bind(MOD .. " + ALT + P", hl.dsp.exec_cmd(hyde.sh.screenshot.monitor()), _F)
_F = {description = "[Utilities] print all monitors", locked = true}
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(hyde.sh.screenshot.full()), _F)

-- ── Screen recording (your own script, kept at ~/.config/hypr/scripts) ──
local screenrecord = os.getenv("HOME") .. "/.config/hypr/scripts/screenrecord.sh"
_F = {description = "[Utilities] toggle screen recording"}
hl.bind(MOD .. " + ALT + R", hl.dsp.exec_cmd(screenrecord), _F)
_F = {description = "[Utilities] toggle region screen recording"}
hl.bind(MOD .. " + CONTROL + R", hl.dsp.exec_cmd(screenrecord .. " region"), _F)

-- ── Game launcher ──
_F = {description = "[Utilities] open game launcher"}
hl.bind(MOD .. " + SHIFT + G", hl.dsp.exec_cmd(hyde.sh.gamelauncher("2")), _F)

-- ── Theming: wallpaper / waybar cycling ──
-- HyDE ships these commented out and uses MOD+ALT+Left/Right for group nav,
-- so these two lines take those keys back for wallpaper cycling.
_F = {description = "[Theming and Wallpaper] next global wallpaper"}
hl.bind(MOD .. " + ALT + Right", hl.dsp.exec_cmd(hyde.sh.wallpaper("--next")), _F)
_F = {description = "[Theming and Wallpaper] previous global wallpaper"}
hl.bind(MOD .. " + ALT + Left", hl.dsp.exec_cmd(hyde.sh.wallpaper("--prev")), _F)
-- `wbarconfgen.sh` is retired by the v26.7.4 migration with no drop-in
-- replacement; layout cycling moved into the waybar CLI itself.
_F = {description = "[Theming and Wallpaper] next waybar layout"}
hl.bind(MOD .. " + ALT + Up", hl.dsp.exec_cmd("hyde-shell waybar --update --next"), _F)
_F = {description = "[Theming and Wallpaper] previous waybar layout"}
hl.bind(MOD .. " + ALT + Down", hl.dsp.exec_cmd("hyde-shell waybar --update --prev"), _F)

-- ── Selector menus HyDE no longer binds ──
_F = {description = "[Theming and Wallpaper] select animations"}
hl.bind(MOD .. " + SHIFT + Y", hl.dsp.exec_cmd(hyde.sh.animations("--select")), _F)
_F = {description = "[Theming and Wallpaper] select hyprlock layout"}
hl.bind(MOD .. " + SHIFT + U", hl.dsp.exec_cmd(hyde.sh.hyprlock("--select")), _F)
