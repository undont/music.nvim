local M = {}

M.options = {
    poll_interval = 1000, -- check for playing track every second (ms)
    preferred_backend = "apple_music", -- 'apple_music' | 'spotify' | 'auto'
    position = "bottom-left", -- options: 'top-right', 'top-left', 'bottom-right', 'bottom-left'
    window = {
        width = 30,
        expanded_height = 16, -- tall: album art + track info
        compact_height = 3, -- slim: just name, artist, time
        expand_duration = 1500, -- ms before shrinking down
    },
    highlights = {
        background = "Normal",
        border = "FloatBorder", -- control border color
        text = "NormalFloat", -- control text color
    },
}

function M.apply(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
