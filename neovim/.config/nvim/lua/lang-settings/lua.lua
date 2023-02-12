
-- Lua specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
        vim.opt.filetype = "lua"
        vim.opt.syntax = "lua"
    end,
})

