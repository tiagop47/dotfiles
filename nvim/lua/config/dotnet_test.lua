local M = {}

local test_ns = vim.api.nvim_create_namespace("dotnet_tests")
local sign_group = "DotnetTestSigns"

-- Cores explícitas e contrastantes (Catppuccin Mocha)
vim.api.nvim_set_hl(0, "TestPassedSign", { fg = "#a6e3a1", bold = true }) -- Verde
vim.api.nvim_set_hl(0, "TestFailedSign", { fg = "#f38ba8", bold = true }) -- Vermelho

-- Define os sinais na margem lateral (Gutter / SignColumn)
vim.fn.sign_define("TestPassedSign", {
  text = "✔",
  texthl = "TestPassedSign",
  linehl = "",
  numhl = "",
})

vim.fn.sign_define("TestFailedSign", {
  text = "✘",
  texthl = "TestFailedSign",
  linehl = "",
  numhl = "",
})

-- Terminal de testes atual (ToggleTerm)
local test_term = nil
M.watch_active = false

--- Encontra o ficheiro .csproj mais próximo a partir do diretório atual
local function find_closest_csproj(start_dir)
  local current = start_dir or vim.fn.expand("%:p:h")
  while current and current ~= "" do
    local matches = vim.fn.glob(current .. "/*.csproj", false, true)
    if #matches > 0 then
      return matches[1]
    end
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then break end
    current = parent
  end
  return nil
end

--- Encontra a linha de um teste no buffer usando busca simples de texto
local function find_test_line(bufnr, method_name)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:find(method_name, 1, true) then
      return i
    end
  end
  return nil
end

--- Encontra o nome do teste mais próximo acima do cursor
local function get_nearest_test_name()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_line, false)

  for i = #lines, 1, -1 do
    local line = lines[i]
    local name = line:match("public%s+async%s+Task%s+([%w_]+)")
      or line:match("public%s+void%s+([%w_]+)")
      or line:match("public%s+[%w<>]+%s+([%w_]+)%s*%(")
    if name and not name:match("^class") and not name:match("^new") then
      return name
    end
  end
  return nil
end

--- Limpa todos os sinais e diagnósticos de testes em todos os buffers
function M.clear()
  vim.fn.sign_unplace(sign_group)
  for _, bnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bnr) then
      vim.api.nvim_buf_clear_namespace(bnr, test_ns, 0, -1)
      vim.diagnostic.reset(test_ns, bnr)
    end
  end
  if test_term then
    pcall(function() test_term:close() end)
  end
  vim.cmd("redraw")
  vim.notify("Sinais de testes limpos.", vim.log.levels.INFO)
end

--- Analisa as linhas do terminal e aplica os sinais ✔ e ✘ no código
local function parse_and_apply_terminal_output(term_bufnr, target_file, fallback_method)
  if not term_bufnr or not vim.api.nvim_buf_is_valid(term_bufnr) then return end

  local lines = vim.api.nvim_buf_get_lines(term_bufnr, 0, -1, false)
  local passed_tests = {}
  local failed_tests = {}

  local i = 1
  while i <= #lines do
    -- Remove códigos de cor ANSI e retornos de carro \r
    local raw_line = lines[i]:gsub("\27%[[0-9;]*m", ""):gsub("\r", "")

    -- 1. Deteta teste que passou:
    -- Ex: "  Passed Unitarios.Application.Tests.ArtigoServiceTests.ObterPorId_Valido [13 ms]"
    local passed_full = raw_line:match("^%s*Passed%s+(.-)%s*%[") or raw_line:match("^%s*Passed%s+(.+)")
    if passed_full then
      passed_full = passed_full:gsub("%s+$", "")
      local method = passed_full:match("([%w_]+)%s*%(") or passed_full:match("([%w_]+)$") or passed_full
      table.insert(passed_tests, { name = method, full = passed_full })
    end

    -- 2. Deteta teste que falhou:
    -- Ex: "  Failed Unitarios.Application.Tests.ArtigoServiceTests.ObterPorId_Invalido [15 ms]"
    local failed_full = raw_line:match("^%s*Failed%s+(.-)%s*%[") or raw_line:match("^%s*Failed%s+(.+)")
    if failed_full then
      failed_full = failed_full:gsub("%s+$", "")
      local method = failed_full:match("([%w_]+)%s*%(") or failed_full:match("([%w_]+)$") or failed_full

      local error_msg = ""
      local file_path = nil
      local line_num = nil

      i = i + 1
      while i <= #lines do
        local sub_raw = lines[i]:gsub("\27%[[0-9;]*m", ""):gsub("\r", "")
        if sub_raw:match("^%s*Failed%s+") or sub_raw:match("^%s*Passed%s+") or sub_raw:match("^%s*Test Run") then
          break
        end

        if sub_raw:match("^%s*Error Message:") then
          i = i + 1
          local msg_lines = {}
          while i <= #lines do
            local msg_raw = lines[i]:gsub("\27%[[0-9;]*m", ""):gsub("\r", "")
            if msg_raw:match("^%s*Stack Trace:") or msg_raw:match("^%s*Failed%s+") or msg_raw:match("^%s*Passed%s+") then
              break
            end
            table.insert(msg_lines, msg_raw:gsub("^%s+", ""))
            i = i + 1
          end
          error_msg = table.concat(msg_lines, " "):gsub("%s+", " ")
        end

        local matched_file, matched_line = sub_raw:match("in%s+([%a]:\\[^:\r\n]+):line%s+(%d+)")
        if not matched_file then
          matched_file, matched_line = sub_raw:match("in%s+(/[^:\r\n]+):line%s+(%d+)")
        end

        if matched_file and matched_line then
          if not file_path or matched_file:lower():find("test") or matched_file == target_file then
            file_path = matched_file
            line_num = tonumber(matched_line)
          end
        end

        i = i + 1
      end

      table.insert(failed_tests, {
        name = method,
        full = failed_full,
        error = error_msg ~= "" and error_msg or "Falha na asserção do teste",
        file = file_path,
        line = line_num,
      })
      i = i - 1
    end

    i = i + 1
  end

  -- Se foi executado um teste específico e ele passou com sucesso
  if #passed_tests == 0 and #failed_tests == 0 and fallback_method then
    -- Verifica se no terminal diz Test Run Successful
    for _, l in ipairs(lines) do
      if l:find("Passed%!") or l:find("Test Run Successful") then
        table.insert(passed_tests, { name = fallback_method, full = fallback_method })
        break
      end
    end
  end

  -- Buffers abertos para desenhar os sinais
  local buffers = {}
  for _, bnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bnr) and vim.bo[bnr].buftype == "" then
      table.insert(buffers, bnr)
    end
  end

  -- 1. Sinais para testes que PASSARAM (✔ verde de lado na margem + texto virtual)
  for _, pt in ipairs(passed_tests) do
    for _, bnr in ipairs(buffers) do
      local line = find_test_line(bnr, pt.name)
      if line then
        -- Sign na margem lateral esquerda (SignColumn)
        pcall(vim.fn.sign_place, 0, sign_group, "TestPassedSign", bnr, {
          lnum = line,
          priority = 20,
        })
        -- Extmark com texto virtual ao fim da linha
        pcall(vim.api.nvim_buf_set_extmark, bnr, test_ns, line - 1, 0, {
          sign_text = "✔",
          sign_hl_group = "TestPassedSign",
          virt_text = { { "✔ passou", "TestPassedSign" } },
          virt_text_pos = "eol",
        })
      end
    end
  end

  -- 2. Sinais para testes que FALHARAM (✘ vermelho de lado na margem + texto virtual)
  local diags_by_buf = {}
  for _, ft in ipairs(failed_tests) do
    for _, bnr in ipairs(buffers) do
      local line = ft.line
      local bname = vim.api.nvim_buf_get_name(bnr)
      if not line or (ft.file and bname ~= ft.file) then
        line = find_test_line(bnr, ft.name)
      end

      if line then
        -- Sign de erro na margem lateral esquerda (SignColumn)
        pcall(vim.fn.sign_place, 0, sign_group, "TestFailedSign", bnr, {
          lnum = line,
          priority = 30,
        })
        -- Extmark com mensagem de erro ao fim da linha
        pcall(vim.api.nvim_buf_set_extmark, bnr, test_ns, line - 1, 0, {
          sign_text = "✘",
          sign_hl_group = "TestFailedSign",
          virt_text = { { "✘ " .. ft.error, "TestFailedSign" } },
          virt_text_pos = "eol",
        })
        -- Diagnóstico para hover <C-q> e undercurl
        diags_by_buf[bnr] = diags_by_buf[bnr] or {}
        table.insert(diags_by_buf[bnr], {
          bufnr = bnr,
          lnum = line - 1,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          source = "Test Failure",
          message = "✘ " .. ft.name .. ": " .. ft.error,
        })
      end
    end
  end

  for bnr, diags in pairs(diags_by_buf) do
    pcall(vim.diagnostic.set, test_ns, bnr, diags)
  end

  vim.cmd("redraw")

  local total = #passed_tests + #failed_tests
  if #failed_tests > 0 then
    vim.notify(
      string.format("✘ %d teste(s) falharam! (%d passaram) — Vê os detalhes no terminal abaixo.", #failed_tests, #passed_tests),
      vim.log.levels.ERROR
    )
  elseif total > 0 then
    vim.notify(
      string.format("✔ Todos os %d teste(s) passaram com sucesso!", total),
      vim.log.levels.INFO
    )
  end
end

--- Executa os testes SEMPRE no terminal PowerShell (ToggleTerm) e atualiza os sinais no código
---@param opts? { nearest?: boolean, file?: boolean, all?: boolean }
function M.run(opts)
  opts = opts or {}

  local current_file = vim.fn.expand("%:p")
  local current_win = vim.api.nvim_get_current_win()
  local project_path = find_closest_csproj()

  local cmd_parts = { "dotnet", "test" }

  if project_path then
    table.insert(cmd_parts, string.format('"%s"', project_path))
  end

  table.insert(cmd_parts, '--logger "console;verbosity=normal"')

  local fallback_nearest = nil
  local desc = "todos os testes"

  if opts.nearest then
    local nearest = get_nearest_test_name()
    if nearest then
      fallback_nearest = nearest
      table.insert(cmd_parts, string.format('--filter "FullyQualifiedName~%s"', nearest))
      desc = "teste: " .. nearest
    else
      vim.notify("Nenhum método de teste encontrado acima do cursor.", vim.log.levels.WARN)
      return
    end
  elseif opts.file then
    local class_name = vim.fn.expand("%:t:r")
    if class_name and class_name ~= "" then
      table.insert(cmd_parts, string.format('--filter "FullyQualifiedName~%s"', class_name))
      desc = "ficheiro: " .. class_name
    end
  end

  local full_cmd = table.concat(cmd_parts, " ")

  -- Limpa sinais anteriores de testes
  vim.fn.sign_unplace(sign_group)
  for _, bnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bnr) then
      vim.api.nvim_buf_clear_namespace(bnr, test_ns, 0, -1)
      vim.diagnostic.reset(test_ns, bnr)
    end
  end

  vim.notify("🧪 A correr no terminal: " .. desc .. "...", vim.log.levels.INFO)

  -- Fecha terminal de teste anterior se aberto
  if test_term then
    pcall(function() test_term:shutdown() end)
    test_term = nil
  end

  local ok, term_mod = pcall(require, "toggleterm.terminal")
  if ok and term_mod.Terminal then
    test_term = term_mod.Terminal:new({
      cmd = full_cmd,
      direction = "horizontal",
      size = 14,
      close_on_exit = false,
      auto_scroll = true,
      on_open = function()
        -- Devolve o foco à janela de código para poderes continuar a editar
        if vim.api.nvim_win_is_valid(current_win) then
          vim.api.nvim_set_current_win(current_win)
        end
      end,
      on_exit = function(t, job, exit_code, name)
        vim.schedule(function()
          parse_and_apply_terminal_output(t.bufnr, current_file, fallback_nearest)
        end)
      end,
    })
    test_term:open(14, "horizontal")
  else
    -- Fallback nativo do terminal
    vim.cmd("botright 14split")
    local term_buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, term_buf)
    vim.fn.termopen(full_cmd, {
      on_exit = function()
        vim.schedule(function()
          parse_and_apply_terminal_output(term_buf, current_file, fallback_nearest)
        end)
      end,
    })
  end

  -- Mantém o foco no código
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

--- Alterna visibilidade do terminal de testes
function M.toggle_terminal()
  if test_term then
    test_term:toggle()
  else
    M.run({ nearest = true })
  end
end

--- Modo Watch (auto-run ao guardar)
function M.toggle_watch()
  M.watch_active = not M.watch_active
  if M.watch_active then
    vim.notify("🧪 Modo Test Watch ATIVADO (corre no terminal ao guardar :w)", vim.log.levels.INFO)
  else
    vim.notify("🧪 Modo Test Watch DESATIVADO", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*Tests.cs", "*Test.cs" },
  callback = function()
    if M.watch_active then
      M.run({ file = true })
    end
  end,
})

-- Comandos de utilizador
vim.api.nvim_create_user_command("Test", function() M.run({ file = true }) end, { desc = "Executar testes do ficheiro no terminal" })
vim.api.nvim_create_user_command("TestNearest", function() M.run({ nearest = true }) end, { desc = "Executar teste sob o cursor no terminal" })
vim.api.nvim_create_user_command("TestAll", function() M.run({ all = true }) end, { desc = "Executar todos os testes no terminal" })
vim.api.nvim_create_user_command("TestClear", M.clear, { desc = "Limpar resultados e fechar terminal de testes" })
vim.api.nvim_create_user_command("TestWatch", M.toggle_watch, { desc = "Alternar execução automática ao salvar" })
vim.api.nvim_create_user_command("TestTerminal", M.toggle_terminal, { desc = "Mostrar/Ocultar terminal de testes" })

return M
