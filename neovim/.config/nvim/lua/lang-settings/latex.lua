
vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    callback = function()
        -- vim.opt.filetype = "tex"
        vim.opt.syntax = "tex"
        require("prose")
    end,
})

