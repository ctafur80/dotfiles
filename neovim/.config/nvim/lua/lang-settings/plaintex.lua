
vim.api.nvim_create_autocmd({"BufNewFile", "BufFilePre", "BufRead"}, {
    pattern = "*.ptex",
    callback = function()
        vim.opt.filetype = "plain"
        vim.opt.syntax = "plaintex"
        require("prose")
    end,
})

