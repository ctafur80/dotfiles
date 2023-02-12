

local spell_dicts_dir = nvim_conf_dir .. "/spell"
local dict_add_files = {
    "espanol.utf-8.add",
    "ingles.utf-8.add",
    "compsci.utf-8.add",
}

for k, v in pairs(dict_add_files) do
    vim.opt.spellfile = vim.opt.spellfile + ( spell_dicts_dir .. "/" .. v )
end

vim.opt.complete = vim.opt.complete + "kspell"

local spell_langs = {"es_es", "espanol", "ingles", "compsci"}
for k, v in pairs(spell_langs) do
    vim.opt.spelllang = vim.opt.spelllang + v
end

vim.opt.spell = false


vim.bo.formatoptions = "tcqj2n"

vim.opt.textwidth = 80
vim.opt.wrap = true


