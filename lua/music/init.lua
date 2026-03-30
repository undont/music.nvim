local M = {}

function M.setup(opts)
    require("music.config").apply(opts)
    require("music.ui").init()

    local backend = require("music.backend")

    vim.keymap.set("n", "<leader>kp", require("music.ui").toggle, { desc = "Music: toggle now playing" })

    vim.keymap.set("n", "<leader>kn", function()
        backend.next_track()
    end, { desc = "Music: next track" })

    vim.keymap.set("n", "<leader>kb", function()
        backend.prev_track()
    end, { desc = "Music: previous track" })

    vim.keymap.set("n", "<leader>ks", function()
        backend.toggle_play()
    end, { desc = "Music: play/pause" })
end

return M
