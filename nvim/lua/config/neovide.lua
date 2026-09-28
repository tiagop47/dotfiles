-- Configurações específicas para Neovide (GUI)
if vim.g.neovide then
  -- O buffer inicial vazio do Neovim não deve aparecer como um ficheiro
  -- [Sem Nome] nas abas quando o Neovide é aberto sem argumentos.
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

  -- Fonte profissional Nerd Font: FiraCode Nerd Font (alta resolução de ícones e ligaduras limpas)
  vim.o.guifont = "FiraCode Nerd Font,Cascadia Code:h10.5"
  vim.g.neovide_opacity = 1.0
  vim.g.neovide_window_blurred = false
  vim.g.neovide_blur = 0
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.3
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_padding_top = 2
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_left = 6
  vim.g.neovide_padding_right = 6

  -- Garante que o Alt (Meta) é sempre enviado ao Neovim e não intercetado pelo Windows/Neovide
  -- Sem isto, Alt+1..5 podem ser capturados como atalhos de sistema operativo
  vim.g.neovide_input_use_logo = false -- não usar Win/Cmd como modificador
  vim.keymap.set("n", "<A-1>", function() require("config.window_tabs").goto_tab(1) end, { desc = "Ir para tab 1 deste split (Neovide)" })
  vim.keymap.set("n", "<A-2>", function() require("config.window_tabs").goto_tab(2) end, { desc = "Ir para tab 2 deste split (Neovide)" })
  vim.keymap.set("n", "<A-3>", function() require("config.window_tabs").goto_tab(3) end, { desc = "Ir para tab 3 deste split (Neovide)" })
  vim.keymap.set("n", "<A-4>", function() require("config.window_tabs").goto_tab(4) end, { desc = "Ir para tab 4 deste split (Neovide)" })
  vim.keymap.set("n", "<A-5>", function() require("config.window_tabs").goto_tab(5) end, { desc = "Ir para tab 5 deste split (Neovide)" })

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

  -- Garante que Ctrl+Espaço no Neovide apenas abre o menu de completamento/hints LSP sem passar de linha
  local trigger_lsp_hints = function()
    local mode = vim.fn.mode()
    local ok, cmp = pcall(require, "cmp")

    if mode:find("n") then
      vim.cmd("startinsert")
      vim.schedule(function()
        local ok_inner, cmp_inner = pcall(require, "cmp")
        if ok_inner then
          cmp_inner.complete()
        else
          pcall(vim.lsp.buf.completion)
        end
      end)
      return
    end

    if ok then
      if not cmp.visible() then
        cmp.complete()
      end
    else
      vim.lsp.buf.completion()
    end
  end
  vim.keymap.set({ "n", "i", "s" }, "<C-Space>", trigger_lsp_hints, { silent = true, desc = "Mostrar hints/completamento LSP" })
  vim.keymap.set({ "n", "i", "s" }, "<C-@>", trigger_lsp_hints, { silent = true, desc = "Mostrar hints/completamento LSP" })
end
