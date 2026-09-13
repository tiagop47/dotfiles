local o = vim.opt

o.number = true
o.relativenumber = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.termguicolors = true
o.signcolumn = "yes"
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true
o.wrap = false
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.updatetime = 250
o.timeoutlen = 400
o.undofile = true
o.cursorline = true
o.report = 99999 -- Não mostra notificações/mensagens de "1 line less", "1 line deleted", etc.
o.shortmess:append("sI") -- Silencia mensagens desnecessárias do intro e escrita

vim.api.nvim_set_hl(0, "Cursor", { fg = "#1e1e1e", bg = "#ff8800" })
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor,i-ci:ver25-Cursor,r-cr:hor20-Cursor"

-- Shell integrado: PowerShell com o perfil pessoal (aliases como ls, cd, nv, fzf)
if vim.fn.executable("powershell.exe") == 1 then
  vim.opt.shell = "powershell.exe"
  vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.opt.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end
