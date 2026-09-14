-- Abas por janela (editor group), como os grupos de editores do VS Code.
-- A tabline nativa é global; a winbar é renderizada independentemente em cada split.
local M = {}

local function setup_highlights()
  vim.api.nvim_set_hl(0, "WindowTabActive", {
    fg = "#0d1117",
    bg = "#79c0ff",
    bold = true,
  })
  vim.api.nvim_set_hl(0, "WindowTabInactive", {
    fg = "#c9d1d9",
    bg = "#30363d",
  })
  vim.api.nvim_set_hl(0, "WindowTabSeparator", {
    fg = "#484f58",
    bg = "#161b22",
  })
end

local function valid_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].buflisted
    and vim.bo[bufnr].buftype == ""
    and (vim.api.nvim_buf_get_name(bufnr) ~= "" or vim.bo[bufnr].modified)
end

local function remember_buffer(win, bufnr)
  if not valid_buffer(bufnr) then return end
  local tabs = vim.w[win].window_tabs or {}
  for _, existing in ipairs(tabs) do
    if existing == bufnr then
      vim.w[win].window_tabs = tabs
      return
    end
  end
  tabs[#tabs + 1] = bufnr
  vim.w[win].window_tabs = tabs
end

local function display_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return "[No Name]" end
  return vim.fn.fnamemodify(name, ":t")
end

function M.render(win)
  local current = vim.api.nvim_win_get_buf(win)
  local tabs = vim.w[win].window_tabs or {}
  local parts = {}
  for _, bufnr in ipairs(tabs) do
    if valid_buffer(bufnr) then
      local hl = bufnr == current and "%#WindowTabActive#" or "%#WindowTabInactive#"
      parts[#parts + 1] = string.format("%%%d@v:lua.WindowTabsPick@ %s ", bufnr, hl .. display_name(bufnr) .. "%*")
    end
  end
  return table.concat(parts, "%#WindowTabSeparator#│%*")
end

function M.pick(bufnr, minwid, clicks, button, mods)
  local win = vim.g.statusline_winid
  if vim.api.nvim_win_is_valid(win) and valid_buffer(bufnr) then
    vim.api.nvim_win_set_buf(win, bufnr)
  end
end

function M.close_others()
  local win = vim.api.nvim_get_current_win()
  local current = vim.api.nvim_get_current_buf()
  local tabs = vim.w[win].window_tabs or {}
  vim.w[win].window_tabs = { current }

  for _, bufnr in ipairs(tabs) do
    if bufnr ~= current and valid_buffer(bufnr) then
      local used_elsewhere = false
      for _, other_win in ipairs(vim.api.nvim_list_wins()) do
        if other_win ~= win and vim.api.nvim_win_get_buf(other_win) == bufnr then
          used_elsewhere = true
          break
        end
      end
      if not used_elsewhere then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
      end
    end
  end
  vim.cmd("redrawstatus")
end

function M.cycle(delta)
  local win = vim.api.nvim_get_current_win()
  local current = vim.api.nvim_get_current_buf()
  local tabs = vim.w[win].window_tabs or {}
  local index
  for i, bufnr in ipairs(tabs) do
    if bufnr == current then index = i break end
  end
  if not index or #tabs < 2 then return end
  local next_index = ((index - 1 + delta) % #tabs) + 1
  local bufnr = tabs[next_index]
  if valid_buffer(bufnr) then vim.api.nvim_win_set_buf(win, bufnr) end
end

setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = setup_highlights,
})

_G.WindowTabsPick = M.pick
vim.opt.showtabline = 0
vim.opt.winbar = "%{%v:lua.WindowTabsRender(win_getid())%}"
_G.WindowTabsRender = M.render

local group = vim.api.nvim_create_augroup("WindowTabs", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufAdd" }, {
  group = group,
  callback = function(args)
    remember_buffer(vim.api.nvim_get_current_win(), args.buf)
    vim.cmd("redrawstatus")
  end,
})
vim.api.nvim_create_autocmd({ "BufDelete", "WinClosed" }, {
  group = group,
  callback = function() vim.cmd("redrawstatus") end,
})

vim.keymap.set("n", "<C-F3>", M.close_others, { desc = "Fechar outras abas deste split" })
vim.keymap.set("n", "<C-Tab>", function() M.cycle(1) end, { desc = "Próxima aba deste split" })
vim.keymap.set("n", "<C-S-Tab>", function() M.cycle(-1) end, { desc = "Aba anterior deste split" })

return M
