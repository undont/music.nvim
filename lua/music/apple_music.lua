-- Apple Music backend via osascript (macOS only)
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

    if #parts < 6 then
        return nil
    end

    local duration_s = tonumber(parts[4]) or 0
    local position_s = tonumber(parts[5]) or 0

    return {
        name = parts[1],
        artist = parts[2],
        album = parts[3],
        art_url = nil, -- no URL; art handled separately via extract_artwork
        progress_ms = math.floor(position_s * 1000),
        duration_ms = math.floor(duration_s * 1000),
        is_playing = (parts[6] == "playing"),
    }
end

--- Fetch current track metadata from Music.app.
--- cb(track_table, err) — track_table matches the shape ui.lua expects.
function M.get_now_playing(cb)
    local script = [[
    tell application "Music"
      if player state is stopped then return "STOPPED"
      if not (exists current track) then return "STOPPED"
      set t to current track
      set trackName to name of t
      set artistName to artist of t
      set albumName to album of t
      set dur to duration of t
      set pos to player position
      set stateStr to player state as string
      return trackName & " ||| " & artistName & " ||| " & albumName & " ||| " & dur & " ||| " & pos & " ||| " & stateStr
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

--- Send a simple command to Music.app.
local function send_command(cmd, cb)
    local script = ('tell application "Music" to %s'):format(cmd)
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

--- Extract album artwork from current track to a temp file.
--- cb(file_path, err) — file_path is the path to the written image, or nil.
function M.extract_artwork(cb)
    local tmp = vim.fn.tempname() .. ".jpg"
    -- AppleScript to write raw artwork data to a file
    local script = ([[
    tell application "Music"
      if player state is stopped then return "NONE"
      if not (exists current track) then return "NONE"
      set t to current track
      try
        set artData to raw data of artwork 1 of t
      on error
        return "NONE"
      end try
    end tell
    set outFile to POSIX file "%s"
    set fh to open for access outFile with write permission
    set eof fh to 0
    write artData to fh
    close access fh
    return "OK"
  ]]):format(tmp)

    run_osascript(script, function(output, err)
        if err or not output then
            cb(nil, err or "no output")
            return
        end
        output = output:gsub("%s+$", "")
        if output == "NONE" then
            cb(nil, "no artwork")
            return
        end
        cb(tmp, nil)
    end)
end

--- No-op for API compatibility (Spotify needed cache invalidation for tokens).
function M.invalidate_cache() end

return M
