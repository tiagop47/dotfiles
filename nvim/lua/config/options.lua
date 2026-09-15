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
o.updatetime = 100 -- Resposta quase instantânea (100ms) para diagnósticos e erros
o.timeoutlen = 400
o.showcmd = true
o.undofile = true
o.swapfile = false -- Desativa ficheiros .swp (evita avisos W325; undofile e auto-save tratam da segurança)
o.cursorline = true
o.showtabline = 0 -- Desativa a tabline global do topo (cada split tem a sua barra de abas local no topo via winbar)
o.cmdheight = 0 -- Cola a statusline diretamente ao fundo da janela (estilo VS Code, sem linha vazia em baixo)
o.report = 99999 -- Não mostra notificações/mensagens de "1 line less", "1 line deleted", etc.
o.shortmess:append("sI") -- Silencia mensagens desnecessárias do intro e escrita

vim.api.nvim_set_hl(0, "Cursor", { fg = "#1e1e1e", bg = "#ff8800" })
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor,i-ci:ver25-Cursor,r-cr:hor20-Cursor"

-- Configuração da Shell para Windows / PowerShell (UTF-8, NoProfile, RemoteSigned)
if vim.fn.has("win32") == 1 then
  local powershell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell.exe"
  vim.opt.shell = powershell
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

-- Configuração global de diagnósticos:
-- Apenas ERROS reais que partem o código aparecem inline ao lado da linha!
-- Boas práticas, style hints, ArgumentNullException e avisos ficam no Ctrl+Shift+M
vim.diagnostic.config({
  virtual_text = {
    severity = { min = vim.diagnostic.severity.ERROR },
    prefix = "●",
    spacing = 4,
  },
  signs = {
    severity = { min = vim.diagnostic.severity.WARN },
    text = {
      [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN] = "▲",
      [vim.diagnostic.severity.HINT] = "⚑",
      [vim.diagnostic.severity.INFO] = "»",
    },
  },
  underline = {
    severity = { min = vim.diagnostic.severity.ERROR },
  },
  update_in_insert = true, -- Atualiza os erros IMEDIATAMENTE enquanto estás a escrever, sem esperar que saias do modo Insert!
  severity_sort = true,
  float = { border = "rounded", source = "always" },
})
