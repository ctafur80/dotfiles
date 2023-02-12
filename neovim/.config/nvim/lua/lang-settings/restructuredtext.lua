
-- Pandoc's flavored Markdown settings
vim.api.nvim_create_autocmd({"BufNewFile", "BufFilePre", "BufRead"}, {
    pattern = {"*.rst"},
    callback = function()
        vim.opt.filetype = "rst"
        vim.opt.syntax = "rst"

        -- vim.bo.formatoptions = "tcqj2n"
        require("prose")
    end,
})

