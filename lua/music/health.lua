local M = {}

M.check = function()
    vim.health.start("music.nvim")

    -- Check for chafa (album art rendering)
    if vim.fn.executable("chafa") == 1 then
        vim.health.ok("chafa found")
    else
        vim.health.warn("chafa not found — album art will not render", {
            "Install via: brew install chafa",
            "Or visit: https://hpjansson.org/chafa/",
        })
    end

    -- Check for osascript (Apple Music backend, macOS only)
    if vim.fn.executable("osascript") == 1 then
        vim.health.ok("osascript found (Apple Music backend available)")
    else
        vim.health.info("osascript not found — Apple Music backend unavailable (macOS only)")
    end

    -- Check for curl (Spotify backend)
    if vim.fn.executable("curl") == 1 then
        vim.health.ok("curl found (Spotify backend available)")
    else
        vim.health.warn("curl not found — Spotify backend will not work")
    end

    -- Check for Spotify tokens
    local tokens_path = vim.fn.expand("~/.spotify_nvim_tokens.json")
    if vim.fn.filereadable(tokens_path) == 1 then
        vim.health.ok("Spotify tokens file found")
    else
        vim.health.info("Spotify tokens file not found — run scripts/get_token.py to set up Spotify")
    end
end

return M
