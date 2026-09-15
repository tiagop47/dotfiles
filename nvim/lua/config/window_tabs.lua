-- ============================================================================
-- Window Tabs (Editor Groups isolados estilo VS Code)
-- Cada split vertical/horizontal possui a sua própria barra de abas local (winbar)
-- Os buffers pertencem exclusivamente à janela/split onde foram abertos.
-- ============================================================================

local M = {}

-- ---------------------------------------------------------------------------
-- 1. Paleta de Cores e Highlight Groups (Catppuccin Mocha)
-- ---------------------------------------------------------------------------
local function setup_highlights()
  -- Aba ativa no split com FOCO atual
  vim.api.nvim_set_hl(0, "WindowTabActive", {
    fg = "#cdd6f4",
    bg = "#313244",
    bold = true,
  })

  -- Aba ativa num split SEM foco (outro editor group)
  vim.api.nvim_set_hl(0, "WindowTabActiveInactive", {
    fg = "#a6adc8",
    bg = "#262738",
    bold = false,
  })

  -- Abas inativas
  vim.api.nvim_set_hl(0, "WindowTabInactive", {
    fg = "#6c7086",
    bg = "#181825",
  })

  -- Separadores entre abas
  vim.api.nvim_set_hl(0, "WindowTabSeparator", {
    fg = "#313244",
    bg = "#181825",
  })

  -- Preenchimento do restante da winbar (fundo vazio)
  vim.api.nvim_set_hl(0, "WindowTabFill", {
    fg = "#181825",
    bg = "#181825",
  })

  -- Indicador de ficheiro modificado (ponto circular)
  vim.api.nvim_set_hl(0, "WindowTabModActive", {
    fg = "#f9e2af",
    bg = "#313244",
    bold = true,
  })
  vim.api.nvim_set_hl(0, "WindowTabModActiveInactive", {
    fg = "#f9e2af",
    bg = "#262738",
  })
  vim.api.nvim_set_hl(0, "WindowTabModInactive", {
    fg = "#fab387",
    bg = "#181825",
  })

  -- Botão de fechar (x / 󰅖)
  vim.api.nvim_set_hl(0, "WindowTabCloseActive", {
    fg = "#9399b2",
    bg = "#313244",
  })
  vim.api.nvim_set_hl(0, "WindowTabCloseActiveInactive", {
    fg = "#6c7086",
    bg = "#262738",
  })
  vim.api.nvim_set_hl(0, "WindowTabCloseInactive", {
    fg = "#585b70",
    bg = "#181825",
  })
end

-- ---------------------------------------------------------------------------
-- 2. Validação e Filtros de Janelas e Buffers
-- ---------------------------------------------------------------------------
local function is_valid_buffer(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype

  -- Ignora janelas utilitárias e ferramentas
  if bt == "terminal" or bt == "quickfix" or bt == "prompt" or bt == "help" then
    return false
  end
  if ft == "neo-tree" or ft == "NvimTree" or ft == "toggleterm" or ft == "qf"
     or ft == "help" or ft == "diffview" or ft == "Trouble" or ft == "lazy"
     or ft == "mason" or ft == "noice" or ft == "notify" then
    return false
  end

  return vim.bo[bufnr].buflisted or vim.bo[bufnr].modified
end

local function is_editor_window(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  -- Janelas flutuantes (popups, telescope, dressing) não devem ter winbar
  local config = vim.api.nvim_win_get_config(win)
  if config.relative and config.relative ~= "" then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if not is_valid_buffer(buf) then
    local bt = vim.bo[buf].buftype
    local ft = vim.bo[buf].filetype
    if bt ~= "" or ft ~= "" then
      return false
    end
  end

  return true
end

-- Lista todas as janelas de código normais (editor groups)
local function get_all_editor_windows()
  local wins = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if is_editor_window(w) then
      table.insert(wins, w)
    end
  end
  return wins
end

-- ---------------------------------------------------------------------------
-- 3. Gestão de Abas por Janela (Editor Groups Isolados)
-- ---------------------------------------------------------------------------
local function get_window_tabs(win)
  if not vim.api.nvim_win_is_valid(win) then return {} end
  local tabs = vim.w[win].window_tabs or {}
  local cleaned = {}
  local seen = {}
  for _, b in ipairs(tabs) do
    if is_valid_buffer(b) and not seen[b] then
      seen[b] = true
      table.insert(cleaned, b)
    end
  end
  vim.w[win].window_tabs = cleaned
  return cleaned
end

local function set_window_tabs(win, tabs)
  if vim.api.nvim_win_is_valid(win) then
    vim.w[win].window_tabs = tabs
  end
end

-- Regista o buffer na janela atual, garantindo isolamento quando novos splits são criados
local function track_buffer(win, bufnr)
  if not is_editor_window(win) or not is_valid_buffer(bufnr) then
    return
  end

  -- Deteção de novo split: se o window_group_id não for igual a win,
  -- esta janela foi recém-criada por :vsplit/:split. Inicia com grupo isolado!
  local recorded_id = vim.w[win].window_group_id
  if recorded_id ~= win then
    vim.w[win].window_group_id = win
    vim.w[win].window_tabs = { bufnr }
    return
  end

  local tabs = get_window_tabs(win)
  for _, b in ipairs(tabs) do
    if b == bufnr then return end
  end

  table.insert(tabs, bufnr)
  set_window_tabs(win, tabs)
end

-- ---------------------------------------------------------------------------
-- 4. Formatação de Nomes e Ícones (com nvim-web-devicons)
-- ---------------------------------------------------------------------------
local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

-- Desambigua nomes idênticos mostrando a pasta pai, ex: index.ts (components)
local function get_display_name(bufnr, all_tabs)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then return "[Sem Nome]" end

  local name = vim.fn.fnamemodify(path, ":t")
  local has_duplicate = false
  for _, other in ipairs(all_tabs) do
    if other ~= bufnr and vim.api.nvim_buf_is_valid(other) then
      local other_path = vim.api.nvim_buf_get_name(other)
      if vim.fn.fnamemodify(other_path, ":t") == name then
        has_duplicate = true
        break
      end
    end
  end

  if has_duplicate then
    local parent = vim.fn.fnamemodify(path, ":h:t")
    if parent ~= "" and parent ~= "." then
      return name .. " (" .. parent .. ")"
    end
  end

  return name
end

-- Gera highlight dinâmico para o ícone manter o fundo da aba
local icon_hl_cache = {}
local function get_icon_hl(base_hl, bg_hex)
  local key = (base_hl or "Default") .. "_" .. bg_hex:gsub("#", "")
  if not icon_hl_cache[key] then
    local fg = nil
    if base_hl then
      local ok, def = pcall(vim.api.nvim_get_hl, 0, { name = base_hl, link = false })
      if ok and def and def.fg then
        fg = string.format("#%06x", def.fg)
      end
    end
    local group_name = "WindowTabIcon_" .. key
    vim.api.nvim_set_hl(0, group_name, {
      fg = fg or "#cdd6f4",
      bg = bg_hex,
    })
    icon_hl_cache[key] = group_name
  end
  return icon_hl_cache[key]
end

-- ---------------------------------------------------------------------------
-- 5. Renderizador da Winbar (Abas do Split Atual)
-- ---------------------------------------------------------------------------
function M.render(win)
  win = win or vim.g.statusline_winid
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end

  if not is_editor_window(win) then
    return ""
  end

  local current_buf = vim.api.nvim_win_get_buf(win)
  local tabs = get_window_tabs(win)

  -- Se por algum motivo o buffer ativo não estiver na lista, adiciona-o
  if is_valid_buffer(current_buf) and not vim.tbl_contains(tabs, current_buf) then
    table.insert(tabs, current_buf)
    set_window_tabs(win, tabs)
  end

  if #tabs == 0 then
    return ""
  end

  local is_focused_split = (win == vim.api.nvim_get_current_win())
  local tab_parts = {}

  for _, bufnr in ipairs(tabs) do
    if is_valid_buffer(bufnr) then
      local is_active_tab = (bufnr == current_buf)
      local is_modified = vim.bo[bufnr].modified
      local filename = get_display_name(bufnr, tabs)
      local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":e")

      -- Determina destaques de acordo com o foco do split e da aba
      local tab_hl, mod_hl
      if is_active_tab and is_focused_split then
        tab_hl = "%#WindowTabActive#"
        mod_hl = "%#WindowTabModActive#"
      elseif is_active_tab and not is_focused_split then
        tab_hl = "%#WindowTabActiveInactive#"
        mod_hl = "%#WindowTabModActiveInactive#"
      else
        tab_hl = "%#WindowTabInactive#"
        mod_hl = "%#WindowTabModInactive#"
      end

      -- Aba limpa sem símbolos/ícones: apenas o nome do ficheiro e '*' se modificado
      local pick_click = string.format("%%%d@v:lua.WindowTabsPick@", bufnr)
      local mod_part = is_modified and (mod_hl .. " *") or ""
      local tab_text = string.format("%s %s%s ", tab_hl, filename, mod_part)

      tab_parts[#tab_parts + 1] = pick_click .. tab_text .. "%X%*"
    end
  end

  local tabs_rendered = table.concat(tab_parts, " ")
  return " " .. tabs_rendered .. "%#WindowTabFill#%=%*"
end

-- ---------------------------------------------------------------------------
-- 6. Ações Interativas (Clique do Rato e Navegação)
-- ---------------------------------------------------------------------------
function M.pick(minwid, clicks, button, mods)
  local bufnr = minwid
  local win = vim.g.statusline_winid
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end

  if button == "m" then
    -- Clique com a roda do rato fecha a aba (estilo browser / VS Code)
    M.close_tab(win, bufnr)
    return
  end

  if vim.api.nvim_win_is_valid(win) and is_valid_buffer(bufnr) then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_buf(win, bufnr)
    vim.cmd("redrawstatus")
  end
end

function M.close_click(minwid, clicks, button, mods)
  local bufnr = minwid
  local win = vim.g.statusline_winid
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end

  if vim.api.nvim_win_is_valid(win) and bufnr and bufnr > 0 then
    M.close_tab(win, bufnr)
  end
end

-- Fecha uma aba específica dentro de um split específico
function M.close_tab(win, bufnr)
  if not vim.api.nvim_win_is_valid(win) then return end

  local tabs = get_window_tabs(win)
  local index = nil
  for i, b in ipairs(tabs) do
    if b == bufnr then index = i break end
  end

  if not index then return end
  table.remove(tabs, index)
  set_window_tabs(win, tabs)

  -- Se a aba fechada era a que estava visível neste split
  local current_buf = vim.api.nvim_win_get_buf(win)
  if current_buf == bufnr then
    if #tabs > 0 then
      local next_idx = math.min(index, #tabs)
      local next_buf = tabs[next_idx]
      vim.api.nvim_win_set_buf(win, next_buf)
    else
      -- Não restam abas neste split
      local editor_wins = get_all_editor_windows()
      if #editor_wins > 1 then
        -- Fecha este split, exatamente como o VS Code fecha o Editor Group
        pcall(vim.api.nvim_win_close, win, false)
      else
        -- Único split restante: cria buffer vazio para não fechar o Neovim
        local scratch = vim.api.nvim_create_buf(true, false)
        vim.bo[scratch].buftype = ""
        vim.bo[scratch].buflisted = true
        vim.api.nvim_win_set_buf(win, scratch)
        set_window_tabs(win, { scratch })
      end
    end
  end

  -- Se o buffer não estiver aberto em NENHUM outro split, elimina-o da memória
  local used_in_other_split = false
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= win and vim.api.nvim_win_is_valid(w) then
      local other_tabs = vim.w[w].window_tabs or {}
      if vim.tbl_contains(other_tabs, bufnr) then
        used_in_other_split = true
        break
      end
    end
  end

  if not used_in_other_split and vim.api.nvim_buf_is_valid(bufnr) then
    if vim.bo[bufnr].modified and vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= "" then
      pcall(function()
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
      end)
    end
    pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
  end

  vim.cmd("redrawstatus")
end

-- Fecha a aba ativa do split atualmente focado (<leader>x ou <A-w>)
function M.close_current_tab()
  local win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(win)
  M.close_tab(win, current_buf)
end

-- ---------------------------------------------------------------------------
-- 7. Regra Obrigatória 3: Atalho Ctrl + F3 ("Close Others" do Grupo Atual)
-- ---------------------------------------------------------------------------
-- Fecha todas as abas que pertencem ao split focado, EXCETO a aba ativa.
-- Não fecha o buffer ativo, não fecha o split, e NÃO afeta os outros splits.
function M.close_others()
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then return end

  local current = vim.api.nvim_win_get_buf(win)
  local tabs = get_window_tabs(win)

  -- 1. O split focado fica ESTRITAMENTE com a aba ativa
  set_window_tabs(win, { current })

  -- 2. Para cada uma das outras abas que pertenciam a este split:
  for _, bufnr in ipairs(tabs) do
    if bufnr ~= current and vim.api.nvim_buf_is_valid(bufnr) then
      -- Verifica se esta aba pertence a QUALQUER OUTRO split aberto
      local used_elsewhere = false
      for _, other_win in ipairs(vim.api.nvim_list_wins()) do
        if other_win ~= win and vim.api.nvim_win_is_valid(other_win) then
          local other_tabs = vim.w[other_win].window_tabs or {}
          if vim.tbl_contains(other_tabs, bufnr) then
            used_elsewhere = true
            break
          end
        end
      end

      -- Se NÃO estiver em nenhum outro split, elimina o buffer
      if not used_elsewhere then
        if vim.bo[bufnr].modified and vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= "" then
          pcall(function()
            vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
          end)
        end
        pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
      end
    end
  end

  vim.cmd("redrawstatus")
end

-- ---------------------------------------------------------------------------
-- 8. Alternância e Saltos de Abas (Ctrl+Tab, Alt+1..9)
-- ---------------------------------------------------------------------------
function M.cycle(delta)
  local win = vim.api.nvim_get_current_win()
  local current = vim.api.nvim_win_get_buf(win)
  local tabs = get_window_tabs(win)
  if #tabs < 2 then return end

  local index = nil
  for i, b in ipairs(tabs) do
    if b == current then index = i break end
  end
  if not index then return end

  local next_index = ((index - 1 + delta) % #tabs) + 1
  local next_buf = tabs[next_index]
  if is_valid_buffer(next_buf) then
    vim.api.nvim_win_set_buf(win, next_buf)
    vim.cmd("redrawstatus")
  end
end

function M.goto_tab(index)
  local win = vim.api.nvim_get_current_win()
  local tabs = get_window_tabs(win)
  if tabs[index] and is_valid_buffer(tabs[index]) then
    vim.api.nvim_win_set_buf(win, tabs[index])
    vim.cmd("redrawstatus")
  end
end

-- ---------------------------------------------------------------------------
-- 9. Inicialização e Autocomandos
-- ---------------------------------------------------------------------------
setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    icon_hl_cache = {}
    setup_highlights()
  end,
})

_G.WindowTabsRender = M.render
_G.WindowTabsPick = M.pick
_G.WindowTabsClose = M.close_click

-- Garante que a tabline global fica a 0 e a winbar é ativada por janela
vim.opt.showtabline = 0
vim.opt.winbar = "%{%v:lua.WindowTabsRender()%}"

local group = vim.api.nvim_create_augroup("WindowTabsEditorGroups", { clear = true })

-- Regista e atualiza as abas quando se navega ou entra num buffer
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufAdd" }, {
  group = group,
  callback = function(args)
    local win = vim.api.nvim_get_current_win()
    track_buffer(win, args.buf or vim.api.nvim_win_get_buf(win))
    vim.cmd("redrawstatus")
  end,
})

-- Limpa referências a buffers eliminados de todos os splits
vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = group,
  callback = function(args)
    local deleted_buf = args.buf
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(w) then
        local tabs = vim.w[w].window_tabs
        if tabs then
          local new_tabs = {}
          for _, b in ipairs(tabs) do
            if b ~= deleted_buf then
              table.insert(new_tabs, b)
            end
          end
          vim.w[w].window_tabs = new_tabs
        end
      end
    end
    vim.cmd("redrawstatus")
  end,
})

-- Redesenha ao fechar splits
vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function()
    vim.schedule(function()
      vim.cmd("redrawstatus")
    end)
  end,
})

-- ---------------------------------------------------------------------------
-- 10. Keymaps
-- ---------------------------------------------------------------------------
-- Regra Obrigatória 3: Ctrl + F3 para fechar outras abas do grupo atual
vim.keymap.set("n", "<C-F3>", M.close_others, { desc = "Fechar outras abas do grupo atual (VS Code Close Others)" })

-- Navegação estilo VS Code dentro do split
vim.keymap.set("n", "<C-Tab>", function() M.cycle(1) end, { desc = "Próxima aba deste split" })
vim.keymap.set("n", "<C-S-Tab>", function() M.cycle(-1) end, { desc = "Aba anterior deste split" })
vim.keymap.set("n", "<leader>x", M.close_current_tab, { desc = "Fechar aba atual do split" })

for i = 1, 9 do
  vim.keymap.set("n", "<A-" .. i .. ">", function() M.goto_tab(i) end, { desc = "Ir para aba " .. i .. " deste split" })
end

return M
