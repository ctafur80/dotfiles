
-- CSS specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "css",
    callback = function()
        vim.opt.syntax = "css"
        vim.opt.iskeyword = vim.opt.iskeyword + "-"
    end,
})

