


vim.bo.formatoptions = string.gsub(vim.bo.formatoptions, "o", "")
vim.bo.formatoptions = string.gsub(vim.bo.formatoptions, "l", "")
vim.bo.formatoptions = vim.bo.formatoptions .. "2n"

