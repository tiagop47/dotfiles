-- Configurações específicas para Neovide (GUI)
if vim.g.neovide then
  -- O buffer inicial vazio do Neovim não deve aparecer como um ficheiro
  -- [No Name] no BufferLine quando o Neovide é aberto sem argumentos.
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" then
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        vim.bo.buflisted = false
        vim.bo.swapfile = false
        pcall(vim.cmd, "Neotree filesystem show left")
      end
    end,
  })

  -- Fonte FiraCode Nerd Font Mono em itálico
  vim.o.guifont = "FiraCode Nerd Font Mono:h10:i"
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.3
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_padding_top = 4
  vim.g.neovide_padding_bottom = 4
  vim.g.neovide_padding_left = 6
  vim.g.neovide_padding_right = 6

  -- Garante que o Alt (Meta) é sempre enviado ao Neovim e não intercetado pelo Windows/Neovide
  -- Sem isto, Alt+1..5 podem ser capturados como atalhos de sistema operativo
  vim.g.neovide_input_use_logo = false -- não usar Win/Cmd como modificador
  vim.keymap.set("n", "<A-1>", function() vim.cmd("BufferLineGoToBuffer 1") end, { desc = "Ir para tab 1 (Neovide)" })
  vim.keymap.set("n", "<A-2>", function() vim.cmd("BufferLineGoToBuffer 2") end, { desc = "Ir para tab 2 (Neovide)" })
  vim.keymap.set("n", "<A-3>", function() vim.cmd("BufferLineGoToBuffer 3") end, { desc = "Ir para tab 3 (Neovide)" })
  vim.keymap.set("n", "<A-4>", function() vim.cmd("BufferLineGoToBuffer 4") end, { desc = "Ir para tab 4 (Neovide)" })
  vim.keymap.set("n", "<A-5>", function() vim.cmd("BufferLineGoToBuffer 5") end, { desc = "Ir para tab 5 (Neovide)" })

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
