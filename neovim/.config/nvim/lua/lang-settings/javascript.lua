
-- JavaScript specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "javascript",
    callback = function()
        vim.opt.syntax = "javascript"
        -- vim.opt.formatoptions = "jql2n"
        vim.opt.tabstop = 2
        vim.opt.softtabstop = 2
        vim.opt.shiftwidth = 2
    end,
})

