
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt.syntax = "markdown"
        require("prose")
    end,
})

