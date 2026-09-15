-- Clipboard & Ações básicas
vim.keymap.set({ "n", "v" }, "<C-c>", '"+y', { desc = "Copiar" })
vim.keymap.set("i", "<C-v>", "<C-r><C-o>+", { desc = "Colar sem autoindent" })
vim.keymap.set("n", "<C-s>", ":write<CR>", { desc = "Guardar" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Sair do modo insert" })
vim.keymap.set("i", "<C-BS>", "<C-W>", { desc = "Apagar palavra anterior" })
vim.keymap.set("i", "<C-H>", "<C-W>", { desc = "Apagar palavra anterior" })

-- Undo & Redo (Ctrl+Z para desfazer, Ctrl+Shift+Z para refazer estilo VS Code)
vim.keymap.set({ "n", "i", "v" }, "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
vim.keymap.set({ "n", "i", "v" }, "<C-S-z>", "<Cmd>redo<CR>", { desc = "Redo" })
vim.keymap.set({ "n", "i", "v" }, "<C-S-Z>", "<Cmd>redo<CR>", { desc = "Redo" })
-- <C-y> fica 100% NATIVO do Vim (Scroll da janela para cima, o inverso exato de <C-e>)

-- Navegação no histórico (Jump list)
vim.keymap.set("n", "<A-Left>", "<C-o>", { desc = "Voltar" })
vim.keymap.set("n", "<A-Right>", "<C-i>", { desc = "Avançar" })

-- Source Control estilo VS Code (Neogit & Diffview)
vim.keymap.set({ "n", "v" }, "<C-S-g>", "<Cmd>Neogit<CR>", { desc = "Source Control (Neogit)" })
vim.keymap.set({ "n", "v" }, "<C-S-G>", "<Cmd>Neogit<CR>", { desc = "Source Control (Neogit)" })
vim.keymap.set({ "n", "v" }, "<leader>gs", "<Cmd>Telescope git_status<CR>", { desc = "Pesquisar alterações do Git estilo Ctrl+P (git status)" })
vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Comparador Diff lado a lado (todas as changes)" })
vim.keymap.set("n", "<leader>gc", "<Cmd>DiffviewClose<CR>", { desc = "Fechar comparador Diffview" })
vim.keymap.set("n", "<leader>gh", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Histórico de commits do ficheiro atual" })
vim.keymap.set("n", "<leader>gl", "<Cmd>DiffviewFileHistory<CR>", { desc = "Histórico de commits do projeto (log)" })

-- Fecho seguro de abas por split com Auto-Save (estilo Editor Groups do VS Code)
local function close_current_buffer()
  local current = vim.api.nvim_get_current_buf()
  local ft = vim.bo[current].filetype
  local bt = vim.bo[current].buftype

  -- Se for janela de ferramentas (Neo-tree, ToggleTerm, etc.), apenas fecha essa janela sem tocar no resto
  if ft == "neo-tree" or bt == "terminal" or ft == "trouble" or ft == "qf" or ft == "help" then
    pcall(vim.cmd, "close")
    return
  end

  -- Se tiver alterações não guardadas e for um ficheiro normal, guarda automaticamente!
  if vim.bo[current].modified and bt == "" and vim.api.nvim_buf_get_name(current) ~= "" then
    pcall(vim.cmd, "silent write")
  end

  local ok, wt = pcall(require, "config.window_tabs")
  if ok and wt.close_current_tab then
    wt.close_current_tab()
  else
    pcall(vim.api.nvim_buf_delete, current, { force = false })
  end
end

vim.keymap.set({ "n", "i", "v" }, "<A-w>", close_current_buffer, { desc = "Fechar aba atual do split" })
vim.keymap.set({ "n", "i", "v" }, "<M-w>", close_current_buffer, { desc = "Fechar aba atual do split" })
vim.keymap.set({ "n", "i", "v" }, "<C-A-w>", close_current_buffer, { desc = "Fechar aba atual do split" })
vim.keymap.set({ "n", "i", "v" }, "<C-M-w>", close_current_buffer, { desc = "Fechar aba atual do split" })
vim.keymap.set("n", "<leader>x", close_current_buffer, { desc = "Fechar aba atual do split" })
vim.api.nvim_create_user_command("Q", close_current_buffer, {})
vim.api.nvim_create_user_command("Quit", close_current_buffer, {})
vim.api.nvim_create_user_command("Wq", close_current_buffer, {})

vim.keymap.set("c", "<CR>", function()
  if vim.fn.getcmdtype() == ":" then
    local command = vim.fn.getcmdline():gsub("%s+$", "")
    if command == "q" or command == "q!" or command == "wq" or command == "wq!" or command == "x" or command == "x!" then
      vim.schedule(close_current_buffer)
      return "<C-c>"
    end
  end
  return "<CR>"
end, { expr = true, desc = "Fechar apenas o buffer atual" })
vim.cmd([[
  cnoreabbrev <expr> q (getcmdtype() == ':' && getcmdline() ==# 'q') ? 'Q' : 'q'
  cnoreabbrev <expr> q! (getcmdtype() == ':' && getcmdline() ==# 'q!') ? 'Q' : 'q!'
  cnoreabbrev <expr> quit (getcmdtype() == ':' && getcmdline() ==# 'quit') ? 'Quit' : 'quit'
  cnoreabbrev <expr> quit! (getcmdtype() == ':' && getcmdline() ==# 'quit!') ? 'Quit' : 'quit!'
  cnoreabbrev <expr> wq (getcmdtype() == ':' && getcmdline() ==# 'wq') ? 'Wq' : 'wq'
  cnoreabbrev <expr> wq! (getcmdtype() == ':' && getcmdline() ==# 'wq!') ? 'Wq' : 'wq!'
  cnoreabbrev <expr> x (getcmdtype() == ':' && getcmdline() ==# 'x') ? 'Wq' : 'x'
  cnoreabbrev <expr> x! (getcmdtype() == ':' && getcmdline() ==# 'x!') ? 'Wq' : 'x!'
]])

-- Turbo Scroll com a tecla Alt (avança 15 linhas por clique da roda do rato)
vim.keymap.set({ "n", "v", "i" }, "<A-ScrollWheelUp>", "15<C-y>", { desc = "Scroll rápido para cima" })
vim.keymap.set({ "n", "v", "i" }, "<A-ScrollWheelDown>", "15<C-e>", { desc = "Scroll rápido para baixo" })
vim.keymap.set({ "n", "v", "i" }, "<M-ScrollWheelUp>", "15<C-y>", { desc = "Scroll rápido para cima" })
vim.keymap.set({ "n", "v", "i" }, "<M-ScrollWheelDown>", "15<C-e>", { desc = "Scroll rápido para baixo" })

-- F3 e Shift+F3: Próxima / Anterior ocorrência de pesquisa (estilo Windows/VS Code)
vim.keymap.set({ "n", "v", "i" }, "<F3>", "<Cmd>silent! normal! nzv<CR>", { desc = "Próxima ocorrência (F3)" })
vim.keymap.set({ "n", "v", "i" }, "<S-F3>", "<Cmd>silent! normal! Nzv<CR>", { desc = "Ocorrência anterior (Shift+F3)" })
