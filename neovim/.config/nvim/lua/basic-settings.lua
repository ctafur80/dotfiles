

vim.opt.termguicolors = false
-- rose-pine is also great but is only for termguicolors.
pcall(vim.cmd, "colorscheme minicyan")


vim.opt.textwidth = 92

vim.opt.number = false

-- Highlights sotf wrap so that I can unset numbering lines. Indents by 2 additional
-- characters on wrapped lines; when line >= 40 characters puts the showbreak symbol at the
-- left.
vim.opt.breakindent = true
vim.opt.breakindentopt = "shift:2,min:40,sbr"
vim.opt.showbreak = "⤷"


-- Indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = false

vim.opt.scrolloff = 0

vim.g.mapleader = ","

vim.opt.clipboard = "unnamedplus"

vim.opt.conceallevel = 0


-- Netrw. Vim's default integrated file explorer. Maybe Telescope will make it obsolete.
vim.g.netrw_banner = 1
vim.g.netrw_liststyle = 3

vim.opt.path = vim.opt.path + "**"
-- table.insert(vim.opt.path, "**")


vim.opt.cursorline = true


vim.bo.formatoptions = string.gsub(vim.bo.formatoptions, "t", "")
vim.bo.formatoptions = vim.bo.formatoptions .. "2n"



-- Backup and undo
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = nvim_cache_dir
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000



-- Searching (more info at https://stackoverflow.com/a/2288438/7026520)
vim.opt.ignorecase = true
vim.opt.smartcase = true



-- When Neovim opens, it remembers the cursor last position.
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})







-- Loading some mini.nvim modules
-- require("mini.basics").setup()
require("mini.ai").setup()
require("mini.comment").setup()
require("mini.surround").setup()
require("mini.trailspace").setup()














