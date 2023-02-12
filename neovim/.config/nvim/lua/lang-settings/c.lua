



-- C specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "c",
    callback = function()
        vim.opt.filetype = "c"
        vim.opt.syntax = "c"


        vim.bo.formatoptions = "tcqj2n"

        -- vim.bo.formatoptions = string.gsub(vim.bo.formatoptions, )

        -- vim.cmd [[set formatoptions=cqj2n]]



        -- vim.bo.formatoptions = "cqj2n"
        -- vim.opt.tabstop = 2
        -- vim.opt.tabstop = 2
        -- vim.opt.shiftwidth = 2
    end,
})




