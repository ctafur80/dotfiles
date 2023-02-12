
-- Downloads Lazy (a Neovim package manager) just from Neovim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)




-- Loading packages
require("lazy").setup({
    {'echasnovski/mini.nvim', version = false},

    {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"},
    "nvim-treesitter/playground",

    -- "folke/which-key.nvim",
    {"folke/neoconf.nvim", cmd = "Neoconf"},
    "folke/neodev.nvim",

    -- "huyvohcmc/atlas.vim",
    -- {'rose-pine/neovim', as = 'rose-pine'},

    -- "lewis6991/gitsigns.nvim",

    -- "lukas-reineke/indent-blankline.nvim",

    "vim-pandoc/vim-pandoc-syntax",

    "neovim/nvim-lspconfig",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    -- "L3MON4D3/LuaSnip",


    -- LSP
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v1.x",
        dependencies = {
            -- LSP Support
            "neovim/nvim-lspconfig",             -- Required
            -- "williamboman/mason.nvim",           -- Optional
            -- "williamboman/mason-lspconfig.nvim", -- Optional

            -- Autocompletion
            "hrsh7th/nvim-cmp",         -- Required
            "hrsh7th/cmp-nvim-lsp",     -- Required
            "hrsh7th/cmp-buffer",       -- Optional
            "hrsh7th/cmp-path",         -- Optional
            -- {"saadparwaiz1/cmp_luasnip"}, -- Optional
            "hrsh7th/cmp-nvim-lua",     -- Optional

            -- Snippets
            -- "L3MON4D3/LuaSnip",             -- Required
            -- "rafamadriz/friendly-snippets", -- Optional
        },
    },



    "onsails/lspkind-nvim",

    -- Telescope -- For moving quickly in a project
    "nvim-lua/popup.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
})

