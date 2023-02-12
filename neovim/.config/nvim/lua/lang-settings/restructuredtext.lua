
-- Pandoc's flavored Markdown settings
vim.api.nvim_create_autocmd({"BufNewFile", "BufFilePre", "BufRead"}, {
    pattern = {"*.rst"},
    callback = function()
        vim.opt.filetype = "rst"
        vim.opt.syntax = "rst"

        vim.bo.formatoptions = "tcqj2n"
        vim.opt.textwidth = 80
        vim.opt.wrap = true
        vim.opt.conceallevel = 0
        -- vim.opt.foldcolumn = 2

        vim.opt.spell = false
    end,
})

