-- Auto-save transparente ao mudar de buffer ou perder o foco da janela
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
      pcall(vim.cmd, "silent update")
    end
  end,
})

-- Indentação oficial de 4 espaços para C#, Razor e Python (estilo VS Code / Visual Studio)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cs", "razor", "cshtml", "python" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
    vim.bo.expandtab = true
  end,
})

-- Restaura sempre a posição anterior do cursor ao abrir/guardar ficheiros
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Cores de alto contraste e realces da interface
local function apply_high_contrast()
  vim.api.nvim_set_hl(0, "Cursor", { fg = "#1e1e1e", bg = "#ff8800", bold = true })
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#c9d1d9" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffb347", bold = true })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#21262d" })
  vim.api.nvim_set_hl(0, "StatusLine", { fg = "#f0f6fc", bg = "#30363d", bold = true })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "#8b949e", bg = "#161b22" })

  -- Realce do Multi-Cursor (Vim-Visual-Multi): cores vibrantes e cursores bem visíveis
  vim.api.nvim_set_hl(0, "VM_Mono",   { fg = "#ffffff", bg = "#1f6feb", bold = true })
  vim.api.nvim_set_hl(0, "VM_Extend", { fg = "#ffffff", bg = "#238636", bold = true })
  vim.api.nvim_set_hl(0, "VM_Cursor", { fg = "#0d1117", bg = "#ff9f43", bold = true })
  vim.api.nvim_set_hl(0, "VM_Insert", { fg = "#0d1117", bg = "#58a6ff", bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_high_contrast })
apply_high_contrast()
