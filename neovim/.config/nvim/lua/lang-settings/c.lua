



-- C specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "c",
    callback = function()
        vim.opt.syntax = "c"
    end,
})




