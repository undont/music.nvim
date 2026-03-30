-- Backend dispatcher — routes to Spotify or Apple Music based on config and app availability.
local M = {}
local config = require("music.config")

local _active_backend = nil
local _detecting = false

local is_macos = vim.fn.has("macunix") == 1

--- Check if a macOS app is running via System Events.
--- cb(is_running) — boolean.
local function is_app_running(app_name, cb)
    local stdout_chunks = {}
    local stdout_pipe = vim.loop.new_pipe(false)
    local handle

    handle = vim.loop.spawn("osascript", {
        args = { "-e", ('tell application "System Events" to (name of processes) contains "%s"'):format(app_name) },
        stdio = { nil, stdout_pipe, nil },
    }, function(code, _)
        stdout_pipe:close()
        if handle and not handle:is_closing() then
            handle:close()
        end
        vim.schedule(function()
            local output = table.concat(stdout_chunks):gsub("%s+$", "")
            cb(code == 0 and output == "true")
        end)
    end)

    if not handle then
        stdout_pipe:close()
        vim.schedule(function()
            cb(false)
        end)
        return
    end

    stdout_pipe:read_start(function(_, data)
        if data then
            table.insert(stdout_chunks, data)
        end
    end)
end

--- Resolve the Spotify module — use AppleScript on macOS, Web API elsewhere.
local function resolve_spotify()
    if is_macos then
        return require("music.spotify_local")
    end
    return require("music.spotify")
end

--- Detect which backend to use based on config and running apps.
--- cb(backend_module) — the resolved backend, or nil if nothing is available.
local function detect_backend(cb)
    local pref = config.options.preferred_backend or "auto"

    -- If user explicitly chose a backend, use it directly
    if pref == "apple_music" then
        cb(require("music.apple_music"))
        return
    elseif pref == "spotify" then
        cb(resolve_spotify())
        return
    end

    -- Auto-detect: check which apps are running
    -- Check Apple Music first (preferred when both are running)
    is_app_running("Music", function(music_running)
        if music_running then
            cb(require("music.apple_music"))
            return
        end
        is_app_running("Spotify", function(spotify_running)
            if spotify_running then
                cb(resolve_spotify())
            else
                cb(nil)
            end
        end)
    end)
end

--- Resolve the active backend, caching the result.
--- Re-detects if no backend is cached.
local function with_backend(cb)
    if _active_backend then
        cb(_active_backend)
        return
    end
    if _detecting then
        return
    end
    _detecting = true
    detect_backend(function(backend)
        _detecting = false
        _active_backend = backend
        cb(backend)
    end)
end

--- Force re-detection on the next call (e.g., when user switches app).
function M.invalidate_cache()
    _active_backend = nil
end

--- Returns the currently active backend module, or nil if not yet detected.
function M.active_backend()
    return _active_backend
end

function M.get_now_playing(cb)
    with_backend(function(backend)
        if not backend then
            cb(nil)
            return
        end
        backend.get_now_playing(function(track)
            -- If the active backend returns nil, try the other one
            if not track then
                M.invalidate_cache()
                detect_backend(function(alt)
                    if alt and alt ~= backend then
                        _active_backend = alt
                        alt.get_now_playing(cb)
                    else
                        cb(nil)
                    end
                end)
            else
                cb(track)
            end
        end)
    end)
end

function M.play()
    with_backend(function(b)
        if b then
            b.play()
        end
    end)
end

function M.pause()
    with_backend(function(b)
        if b then
            b.pause()
        end
    end)
end

function M.next_track()
    with_backend(function(b)
        if b then
            b.next_track()
        end
    end)
end

function M.prev_track()
    with_backend(function(b)
        if b then
            b.prev_track()
        end
    end)
end

function M.toggle_play(cb)
    with_backend(function(b)
        if b then
            b.toggle_play(cb)
        end
    end)
end

return M
