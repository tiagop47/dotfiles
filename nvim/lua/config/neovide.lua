-- Configurações específicas para Neovide (GUI)
if vim.g.neovide then
  -- Ajusta aqui o tamanho da fonte (ex: :h10, :h11, :h12)
  vim.o.guifont = "FiraCode Nerd Font Mono:h11"
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.3
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_padding_top = 4
  vim.g.neovide_padding_bottom = 4
  vim.g.neovide_padding_left = 6
  vim.g.neovide_padding_right = 6

  -- Atalhos estilo VS Code: Ctrl + e Ctrl - para aumentar/diminuir o zoom da fonte na hora!
  vim.keymap.set({ "n", "v" }, "<C-=>", function()
    vim.g.neovide_scale_factor = (vim.g.neovide_scale_factor or 1.0) + 0.05
  end, { desc = "Aumentar zoom da fonte" })
  vim.keymap.set({ "n", "v" }, "<C-->", function()
    vim.g.neovide_scale_factor = math.max(0.5, (vim.g.neovide_scale_factor or 1.0) - 0.05)
  end, { desc = "Diminuir zoom da fonte" })
  vim.keymap.set({ "n", "v" }, "<C-0>", function()
    vim.g.neovide_scale_factor = 1.0
  end, { desc = "Repor zoom da fonte" })
end
