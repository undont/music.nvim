-- Minimal init for running tests with plenary.nvim
-- Usage: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/unit/ {minimal_init = 'tests/minimal_init.lua'}"

local plenary_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"

-- Clone plenary if not present
if vim.fn.isdirectory(plenary_path) == 0 then
    vim.fn.system({
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_path,
    })
end

-- Add plenary and the plugin itself to runtimepath
vim.opt.runtimepath:prepend(plenary_path)
vim.opt.runtimepath:prepend(vim.fn.getcwd())

vim.cmd("runtime plugin/plenary.vim")
