-- Controls floating window, timer, and display logic.
local M = {}
local config = require("music.config")
local utils = require("music.utils")
local fmt_time = utils.fmt_time
local clean_name = utils.clean_name
local trim_artist = utils.trim_artist

-- All runtime states
local state = {
    buf = nil, -- Buffer holding content
    win = nil, -- Floating window handle
    poll_timer = nil, -- Fires every polling interval to check Spotify
    shrink_timer = nil, -- Fires after expansion to minimize window
    current_track = nil, -- Last track received
    expanded = false,
}

-- Checks if floating window exists, countering potential user close.
local function win_valid()
    if state.win ~= nil and not vim.api.nvim_win_is_valid(state.win) then
        state.win = nil -- clean up stale handle so we don't keep checking it
    end
    return state.win ~= nil
end

-- Ensures the scratch buffer exists, recreating it if wiped.
local function ensure_buf()
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].modifiable = false
end

-- Builds window
local function get_win_cfg(height)
    local w = config.options.window.width
    local pos = config.options.position
    local row, col

    -- Calculates row / col based on user corner choice.
    if pos == "top-right" then
        row = 1
        col = vim.o.columns - w - 3
    elseif pos == "top-left" then
        row = 1
        col = 1
    elseif pos == "bottom-left" then
        row = vim.o.lines - height - 4 -- -4 accounts for statusline + cmdline
        col = 1
    elseif pos == "bottom-right" then
        row = vim.o.lines - height - 4
        col = vim.o.columns - w - 3
    else
        -- fallback to top-right
        row = 1
        col = vim.o.columns - w - 3
    end

    return {
        relative = "editor",
        row = row,
        col = col,
        width = w,
        height = height,
        style = "minimal",
        border = "rounded",
        focusable = false, -- To prevent cursor jumping to window
        zindex = 50, -- To render on top of other elements
    }
end

-- Writes to buffer, keeping it unmodifiable until we have to change it.
local function set_lines(lines)
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modifiable = false
end

-- Builds the 3 line view after minimizing
local function compact_lines(track)
    if not track then
        return { "  ♪  Nothing playing" }
    end
    local icon = track.is_playing and "▶" or "||"
    local name = clean_name(track.name)
    local max = config.options.window.width - 9
    local artist = trim_artist(track.artist, max)
    return {
        ("  %s  %s"):format(icon, name),
        ("     %s"):format(artist),
        ("     %s / %s"):format(fmt_time(track.progress_ms), fmt_time(track.duration_ms)),
    }
end

-- Collapses window to 3 line format.
local function shrink()
    if not win_valid() then
        return
    end
    state.expanded = false
    local lines = compact_lines(state.current_track)
    set_lines(lines)
    vim.api.nvim_win_set_config(state.win, get_win_cfg(#lines))
end

-- Expands window to show album art + full info.
local function expand(track)
    state.expanded = true
    local opts = config.options.window

    -- Determine how to get artwork based on what's available
    local function render_expanded(art_lines)
        if not win_valid() then
            return
        end

        local lines = {}
        for _, l in ipairs(art_lines) do
            table.insert(lines, l)
        end
        table.insert(lines, "  " .. ("─"):rep(opts.width - 4))
        if track then
            table.insert(lines, ("  ♪  %s"):format(track.name))
            table.insert(lines, ("     %s"):format(track.artist))
            table.insert(lines, ("     %s · %s"):format(track.album, fmt_time(track.duration_ms)))
        else
            table.insert(lines, "  Nothing playing right now.")
        end

        if win_valid() then
            vim.api.nvim_win_set_config(state.win, get_win_cfg(opts.expanded_height))
        else
            ensure_buf()
            state.win = vim.api.nvim_open_win(state.buf, false, get_win_cfg(opts.expanded_height))
            local hl = config.options.highlights
            vim.wo[state.win].winhl = ("Normal:%s,FloatBorder:%s,NormalFloat:%s"):format(
                hl.background,
                hl.border,
                hl.text
            )
        end
        set_lines(lines)

        if state.shrink_timer then
            state.shrink_timer:stop()
            state.shrink_timer:close()
        end
        state.shrink_timer = vim.loop.new_timer()
        state.shrink_timer:start(opts.expand_duration, 0, vim.schedule_wrap(shrink))
    end

    -- If track has an art_url (Spotify), use URL-based download
    if track and track.art_url then
        local art = require("music.art").get_lines(track.art_url, opts.width)
        render_expanded(art)
        return
    end

    -- Otherwise try local artwork extraction (Apple Music / Spotify local)
    local backend = require("music.backend")
    local active = backend.active_backend()
    if active and active.extract_artwork then
        active.extract_artwork(function(art_path, _)
            local art_mod = require("music.art")
            local art
            if art_path then
                art = art_mod.get_lines_from_file(art_path, opts.width)
                vim.fn.delete(art_path)
            else
                art = {}
            end
            render_expanded(art)
        end)
    else
        render_expanded({})
    end
end

local function on_tick()
    if not win_valid() then
        return
    end

    require("music.backend").get_now_playing(function(track)
        -- Nothing playing — always update to compact nil view
        if not track then
            state.current_track = nil
            if state.shrink_timer then
                state.shrink_timer:stop()
                state.shrink_timer:close()
                state.shrink_timer = nil
            end
            state.expanded = false
            set_lines(compact_lines(nil))
            vim.api.nvim_win_set_config(state.win, get_win_cfg(1))
            return
        end

        -- Same song — just update timestamp
        if state.current_track and state.current_track.name == track.name then
            local old_secs = math.floor(state.current_track.progress_ms / 1000)
            local new_secs = math.floor(track.progress_ms / 1000)
            state.current_track.progress_ms = track.progress_ms
            state.current_track.is_playing = track.is_playing
            if not state.expanded and win_valid() and old_secs ~= new_secs then
                set_lines(compact_lines(state.current_track))
            end
            return
        end

        -- New song
        state.current_track = track
        if win_valid() then
            expand(track)
        end
    end)
end
-- Creates buffer once when plugin started.
function M.init()
    ensure_buf()
end

function M.toggle()
    if win_valid() then
        vim.api.nvim_win_close(state.win, true)
        state.win = nil
        state.current_track = nil
        state.expanded = false
        if state.poll_timer then
            state.poll_timer:stop()
            state.poll_timer:close()
            state.poll_timer = nil
        end
        if state.shrink_timer then
            state.shrink_timer:stop()
            state.shrink_timer:close()
            state.shrink_timer = nil
        end
    else
        ensure_buf()
        state.win = vim.api.nvim_open_win(state.buf, false, get_win_cfg(config.options.window.compact_height))
        local hl = config.options.highlights
        vim.wo[state.win].winhl = ("Normal:%s,FloatBorder:%s,NormalFloat:%s"):format(hl.background, hl.border, hl.text)
        set_lines({ "  ♪  Loading..." })

        state.poll_timer = vim.loop.new_timer()
        state.poll_timer:start(0, config.options.poll_interval, vim.schedule_wrap(on_tick))
    end
end

return M
