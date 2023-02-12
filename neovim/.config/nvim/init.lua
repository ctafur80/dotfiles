

-- Neovim settings

-- It is done in Lua language. You can learn to make your Neovim settings in Lua at
-- <https://www.notonlycode.org/neovim-lua-config/>.


nvim_conf_dir = os.getenv("HOME") .. "/.config/nvim"
nvim_cache_dir = os.getenv("HOME") .. "/.config/cache/neovim"
--TODO The Lua way doesn't work. vim.opt.undodir = vim.g.stdpath.config .. "/.config/cache/neovim"

require("plugins")

require("basic-settings")

require("prettier-neovim")

require("setup/treesitter")

require("completion")

require("setup/lspconfig")


-- Language-specific settings
require("lang-settings/c")
require("lang-settings/pandoc")
require("lang-settings/css")
require("lang-settings/html")
require("lang-settings/javascript")
require("lang-settings/lua")
require("lang-settings/make")
require("lang-settings/markdown")
require("lang-settings/python")
require("lang-settings/latex")
require("lang-settings/plaintex")








