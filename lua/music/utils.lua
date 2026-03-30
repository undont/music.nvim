-- Pure utility functions for formatting and text processing.
local M = {}

-- Format milliseconds as M:SS
function M.fmt_time(ms)
    local s = math.floor(ms / 1000)
    return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

-- Strips '(feat.)', '[feat.]', '(with ...)' suffixes to save space.
function M.clean_name(name)
    name = name:gsub("%s*%(feat%.?[^%)]*%)", "")
    name = name:gsub("%s*%[feat%.?[^%]]*%]", "")
    name = name:gsub("%s*%(with[^%)]*%)", "")
    return name:match("^%s*(.-)%s*$") -- trim whitespace
end

-- Truncates artist names to fit within max_len.
function M.trim_artist(artist, max_len)
    if #artist <= max_len then
        return artist
    end
    return artist:sub(1, max_len - 3) .. "..."
end

return M
