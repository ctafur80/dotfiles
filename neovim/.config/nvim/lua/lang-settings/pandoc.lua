
-- Pandoc's flavored Markdown settings
vim.api.nvim_create_autocmd({"BufNewFile", "BufFilePre", "BufRead"}, {
    pattern = {"*.mkd", "*.pandoc"},
    callback = function()
        vim.opt.filetype = "markdown.pandoc"
        vim.opt.syntax = "markdown.pandoc"
        require("prose")

        -- vim.opt.foldcolumn = 2

        vim.opt.conceallevel = 0
        vim.g["pandoc#syntax#conceal#use"] = 0
        vim.g["pandoc#syntax#codeblocks#embeds#use"] = 1
        vim.g["pandoc#syntax#stype#emphases"] = 1
        vim["pandoc#syntax#style#underline_special"] = 0
        vim["pandoc#syntax#style#roman_lists"] = 1

        vim.g["pandoc#syntax#codeblocks#embeds#langs"] = {
            "c", "ruby", "literatehaskell=lhaskell", "bash=sh", "javascript",
            "tex", "markdown", "vimscript=vim", "xml", "html", "css", "python",
            "sql", "yaml", "json", "systemd", "dockerfile", "lua", "liquid",
            "asterisk",
        }
    end,
})

