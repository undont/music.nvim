-- Downloads album art and renders as unicode using chafa.
local M = {}
-- Caches rendered art lines, persists for whole session until M.clear_cache().
local cache = {}

-- Render a local image file with chafa.
-- Returns array of strings (one per line).
local function render_with_chafa(path, width)
    if vim.fn.executable("chafa") == 0 then
        return { "  [install chafa for album art]" }
    end

    local devnull = vim.fn.has("win32") == 1 and "2>nul" or "2>/dev/null"
    local lines = vim.fn.systemlist(
        ('chafa --size %dx12 --symbols braille --colors none --format symbols "%s" %s'):format(width - 4, path, devnull)
    )

    for i, line in ipairs(lines) do
        line = line:gsub("\r$", "")
        lines[i] = "  " .. line
    end

    return #lines > 0 and lines or { "  [art unavailable]" }
end

-- Fetches and renders album art from a URL (Spotify).
function M.get_lines(url, width)
    if not url then
        return {}
    end
    if cache[url] then
        return cache[url]
    end

    local tmp = (vim.fn.tempname() .. ".jpg"):gsub("\\", "/")
    vim.fn.system(('curl -s -o "%s" "%s"'):format(tmp, url))

    local lines = render_with_chafa(tmp, width)
    vim.fn.delete(tmp)

    cache[url] = lines
    return cache[url]
end

-- Renders album art from a local file path.
-- The caller is responsible for cleaning up the temp file afterwards.
function M.get_lines_from_file(path, width)
    if not path then
        return {}
    end
    if cache[path] then
        return cache[path]
    end

    local lines = render_with_chafa(path, width)
    cache[path] = lines
    return cache[path]
end

-- Useful for resizing window.
function M.clear_cache()
    cache = {}
end

return M
