-- Spotify backend via osascript (macOS only, no API key required)
local M = {}

--- Run an AppleScript string asynchronously, call cb(output, err) when done.
local function run_osascript(script, cb)
    local stdout_pipe = vim.loop.new_pipe(false)
    local stderr_pipe = vim.loop.new_pipe(false)
    local stdout_chunks = {}
    local stderr_chunks = {}
    local handle

    handle = vim.loop.spawn("osascript", {
        args = { "-e", script },
        stdio = { nil, stdout_pipe, stderr_pipe },
    }, function(code, _)
        stdout_pipe:close()
        stderr_pipe:close()
        if handle and not handle:is_closing() then
            handle:close()
        end

        vim.schedule(function()
            local output = table.concat(stdout_chunks)
            local err_output = table.concat(stderr_chunks)
            if code ~= 0 then
                cb(nil, "osascript error: " .. err_output)
            else
                cb(output, nil)
            end
        end)
    end)

    if not handle then
        stdout_pipe:close()
        stderr_pipe:close()
        vim.schedule(function()
            cb(nil, "failed to spawn osascript")
        end)
        return
    end

    stdout_pipe:read_start(function(_, data)
        if data then
            table.insert(stdout_chunks, data)
        end
    end)
    stderr_pipe:read_start(function(_, data)
        if data then
            table.insert(stderr_chunks, data)
        end
    end)
end

--- Parse raw osascript output into a track table.
--- Returns track table or nil if output is invalid/stopped.
function M._parse_output(output)
    if not output or output == "" then
        return nil
    end

    output = output:gsub("%s+$", "")
    if output == "STOPPED" then
        return nil
    end

    local raw_parts = vim.split(output, "|||", { plain = true })
    local parts = {}
    for _, part in ipairs(raw_parts) do
        local trimmed = vim.trim(part)
        if trimmed ~= "" then
            table.insert(parts, trimmed)
        end
    end

    if #parts < 7 then
        return nil
    end

    local duration_ms = tonumber(parts[4]) or 0 -- Spotify returns ms
    local position_s = tonumber(parts[5]) or 0 -- player position is seconds

    return {
        name = parts[1],
        artist = parts[2],
        album = parts[3],
        art_url = parts[7] ~= "missing value" and parts[7] or nil,
        progress_ms = math.floor(position_s * 1000),
        duration_ms = math.floor(duration_ms),
        is_playing = (parts[6] == "playing"),
    }
end

--- Fetch current track metadata from Spotify.app.
--- cb(track_table, err) — track_table matches the shape ui.lua expects.
function M.get_now_playing(cb)
    local script = [[
    tell application "Spotify"
      if player state is stopped then return "STOPPED"
      if not (exists current track) then return "STOPPED"
      set t to current track
      set trackName to name of t
      set artistName to artist of t
      set albumName to album of t
      set dur to duration of t
      set pos to player position
      set stateStr to player state as string
      set artUrl to artwork url of t
      return trackName & " ||| " & artistName & " ||| " & albumName & " ||| " & dur & " ||| " & pos & " ||| " & stateStr & " ||| " & artUrl
    end tell
  ]]

    run_osascript(script, function(output, err)
        if err then
            cb(nil)
            return
        end
        cb(M._parse_output(output))
    end)
end

--- Send a simple command to Spotify.app.
local function send_command(cmd, cb)
    local script = ('tell application "Spotify" to %s'):format(cmd)
    run_osascript(script, function(_, _)
        if cb then
            cb()
        end
    end)
end

function M.play()
    send_command("play")
end

function M.pause()
    send_command("pause")
end

function M.next_track()
    send_command("next track")
end

function M.prev_track()
    send_command("previous track")
end

function M.toggle_play(cb)
    send_command("playpause", cb)
end

--- No-op for API compatibility.
function M.extract_artwork() end
function M.invalidate_cache() end

return M
