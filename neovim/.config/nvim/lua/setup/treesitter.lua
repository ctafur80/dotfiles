
require'nvim-treesitter.configs'.setup {
    ensure_installed = { "c", "latex", "lua", "python", "json", "yaml", "vim", "rst",
        "markdown", "javascript", "rust", "go", "sql", "bash" },
    sync_install = false,

    auto_install = true,

    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },

    indent = {
        enable = true,
    },

    folding = {
        enable = true,
    }

}

