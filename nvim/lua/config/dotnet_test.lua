local M = {}

local test_ns = vim.api.nvim_create_namespace("dotnet_tests")
local sign_group = "DotnetTestSigns"

-- Cores explícitas e contrastantes estilo Catppuccin Mocha
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

-- Armazena o último output e estado do painel
M.last_output = ""
M.output_buf = nil
M.output_win = nil
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

--- Encontra a linha de um teste no buffer usando busca de texto simples e fiável
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

--- Limpa todos os sinais e diagnósticos de testes em todos os buffers abertos
function M.clear()
  vim.fn.sign_unplace(sign_group)
  for _, bnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bnr) then
      vim.api.nvim_buf_clear_namespace(bnr, test_ns, 0, -1)
      vim.diagnostic.reset(test_ns, bnr)
    end
  end
  if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
    vim.api.nvim_win_close(M.output_win, true)
    M.output_win = nil
  end
  vim.notify("Sinais e resultados dos testes limpos.", vim.log.levels.INFO)
end

--- Abre o painel inferior com o output completo e formatado do PowerShell
function M.show_output()
  if not M.last_output or M.last_output == "" then
    vim.notify("Ainda não há output de testes para mostrar.", vim.log.levels.WARN)
    return
  end

  local main_win = vim.api.nvim_get_current_win()

  if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
    vim.api.nvim_set_current_win(M.output_win)
  else
    vim.cmd("botright 14split")
    M.output_win = vim.api.nvim_get_current_win()
    vim.wo[M.output_win].winfixheight = true
    vim.wo[M.output_win].number = false
    vim.wo[M.output_win].relativenumber = false
    vim.wo[M.output_win].signcolumn = "no"
  end

  if not M.output_buf or not vim.api.nvim_buf_is_valid(M.output_buf) then
    M.output_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.output_buf].buftype = "nofile"
    vim.bo[M.output_buf].bufhidden = "hide"
    vim.bo[M.output_buf].swapfile = false
    vim.bo[M.output_buf].filetype = "dotnettest"

    local opts = { buffer = M.output_buf, silent = true }

    vim.keymap.set("n", "q", function()
      if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
        vim.api.nvim_win_close(M.output_win, true)
        M.output_win = nil
      end
    end, opts)

    vim.keymap.set("n", "<Esc>", function()
      if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
        vim.api.nvim_win_close(M.output_win, true)
        M.output_win = nil
      end
    end, opts)

    -- <CR> salta diretamente para o ficheiro e linha
    vim.keymap.set("n", "<CR>", function()
      local line_str = vim.api.nvim_get_current_line()
      local file, lnum = line_str:match("in%s+([%a]:\\[^:\r\n]+):line%s+(%d+)")
      if not file then
        file, lnum = line_str:match("in%s+(/[^:\r\n]+):line%s+(%d+)")
      end
      if not file then
        file, lnum = line_str:match("([%a]:[%w%._\\/%-]+)%(?(%d+)[,:]?(%d*)%)?")
      end

      if file and vim.fn.filereadable(file) == 1 then
        vim.cmd("wincmd p")
        vim.cmd("edit " .. vim.fn.fnameescape(file))
        if lnum and tonumber(lnum) then
          vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
        end
      end
    end, opts)
  end

  vim.bo[M.output_buf].modifiable = true
  local lines = vim.split(M.last_output, "[\r\n]+")
  vim.api.nvim_buf_set_lines(M.output_buf, 0, -1, false, lines)
  vim.bo[M.output_buf].modifiable = false
  vim.api.nvim_win_set_buf(M.output_win, M.output_buf)

  vim.api.nvim_buf_clear_namespace(M.output_buf, test_ns, 0, -1)
  for idx, line in ipairs(lines) do
    if line:match("^%s*Failed") or line:match("Test Run Failed") or line:match("Build FAILED") then
      vim.api.nvim_buf_add_highlight(M.output_buf, test_ns, "TestFailedSign", idx - 1, 0, -1)
    elseif line:match("^%s*Passed") or line:match("Test Run Successful") then
      vim.api.nvim_buf_add_highlight(M.output_buf, test_ns, "TestPassedSign", idx - 1, 0, -1)
    elseif line:match("^%s*Error Message:") or line:match("^%s*Stack Trace:") then
      vim.api.nvim_buf_add_highlight(M.output_buf, test_ns, "DiagnosticWarn", idx - 1, 0, -1)
    elseif line:match("in%s+[%a]:\\") or line:match("in%s+/") then
      vim.api.nvim_buf_add_highlight(M.output_buf, test_ns, "Underlined", idx - 1, 0, -1)
    end
  end

  if vim.api.nvim_win_is_valid(main_win) then
    vim.api.nvim_set_current_win(main_win)
  end
end

--- Alterna a visualização do painel de output
function M.toggle_output()
  if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
    vim.api.nvim_win_close(M.output_win, true)
    M.output_win = nil
  else
    M.show_output()
  end
end

--- Executa os testes do .NET e coloca os sinais na margem lateral (✘ e ✔)
---@param opts? { nearest?: boolean, file?: boolean, all?: boolean }
function M.run(opts)
  opts = opts or {}

  local current_file = vim.fn.expand("%:p")
  local current_buf = vim.api.nvim_get_current_buf()
  local project_path = find_closest_csproj()

  local cmd = { "dotnet", "test" }

  if project_path then
    table.insert(cmd, project_path)
  end

  table.insert(cmd, "--logger")
  table.insert(cmd, "console;verbosity=normal")

  local filter_desc = "todos os testes"

  if opts.nearest then
    local nearest = get_nearest_test_name()
    if nearest then
      table.insert(cmd, "--filter")
      table.insert(cmd, "FullyQualifiedName~" .. nearest)
      filter_desc = "teste: " .. nearest
    else
      vim.notify("Nenhum método de teste encontrado acima do cursor.", vim.log.levels.WARN)
      return
    end
  elseif opts.file then
    local class_name = vim.fn.expand("%:t:r")
    if class_name and class_name ~= "" then
      table.insert(cmd, "--filter")
      table.insert(cmd, "FullyQualifiedName~" .. class_name)
      filter_desc = "ficheiro: " .. class_name
    end
  end

  vim.notify("🧪 A executar " .. filter_desc .. "...", vim.log.levels.INFO)

  -- Limpa sinais anteriores
  vim.fn.sign_unplace(sign_group)
  for _, bnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bnr) then
      vim.api.nvim_buf_clear_namespace(bnr, test_ns, 0, -1)
      vim.diagnostic.reset(test_ns, bnr)
    end
  end

  -- Execução assíncrona não-bloqueante
  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      local stdout = result.stdout or ""
      local stderr = result.stderr or ""
      local output = stdout .. "\n" .. stderr
      M.last_output = output

      if output:find("Build FAILED") then
        vim.notify("✘ Falha na compilação dos testes. Corrige os erros de compilação primeiro.", vim.log.levels.ERROR)
        M.show_output()
        return
      end

      local passed_tests = {}
      local failed_tests = {}

      local lines = vim.split(output, "[\r\n]+")
      local i = 1
      while i <= #lines do
        -- Remove sequências de escape ANSI e retornos de carro
        local raw_line = lines[i]:gsub("\27%[[0-9;]*m", ""):gsub("\r", "")

        -- 1. Deteta teste que passou:
        -- Ex: "  Passed Unitarios.Application.Tests.ArtigoServiceTests.CriarArtigo_Valido [13 ms]"
        local passed_name_full = raw_line:match("^%s*Passed%s+(.-)%s*%[") or raw_line:match("^%s*Passed%s+(.+)")
        if passed_name_full then
          passed_name_full = passed_name_full:gsub("%s+$", "")
          local method_name = passed_name_full:match("([%w_]+)%s*%(") or passed_name_full:match("([%w_]+)$") or passed_name_full
          table.insert(passed_tests, {
            name = method_name,
            full = passed_name_full,
          })
        end

        -- 2. Deteta teste que falhou:
        -- Ex: "  Failed Unitarios.Application.Tests.ArtigoServiceTests.ObterPorId_Invalido [15 ms]"
        local failed_name_full = raw_line:match("^%s*Failed%s+(.-)%s*%[") or raw_line:match("^%s*Failed%s+(.+)")
        if failed_name_full then
          failed_name_full = failed_name_full:gsub("%s+$", "")
          local method_name = failed_name_full:match("([%w_]+)%s*%(") or failed_name_full:match("([%w_]+)$") or failed_name_full

          local error_msg = ""
          local file_path = nil
          local line_num = nil

          i = i + 1
          while i <= #lines do
            local sub_raw = lines[i]:gsub("\27%[[0-9;]*m", ""):gsub("\r", "")
            if sub_raw:match("^%s*Failed%s+") or sub_raw:match("^%s*Passed%s+") then
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
              if not file_path or matched_file:lower():find("test") or matched_file == current_file then
                file_path = matched_file
                line_num = tonumber(matched_line)
              end
            end

            i = i + 1
          end

          table.insert(failed_tests, {
            name = method_name,
            full = failed_name_full,
            error = error_msg ~= "" and error_msg or "Falha na asserção do teste",
            file = file_path,
            line = line_num,
          })
          i = i - 1
        end

        i = i + 1
      end

      -- =====================================================================
      -- COLOCAÇÃO DOS SINAIS NA MARGEM LATERAL (GUTTER) E TEXTO VIRTUAL
      -- =====================================================================

      -- Lista de buffers relevantes para colocar os sinais
      local buffers_to_check = {}
      if vim.api.nvim_buf_is_valid(current_buf) then
        table.insert(buffers_to_check, current_buf)
      end
      for _, bnr in ipairs(vim.api.nvim_list_bufs()) do
        if bnr ~= current_buf and vim.api.nvim_buf_is_loaded(bnr) and vim.bo[bnr].buftype == "" then
          table.insert(buffers_to_check, bnr)
        end
      end

      -- 1. SINAIS PARA TESTES QUE PASSARAM (✔ verde de lado na margem)
      for _, pt in ipairs(passed_tests) do
        for _, bnr in ipairs(buffers_to_check) do
          local line = find_test_line(bnr, pt.name)
          if line then
            -- Sign clássico na SignColumn (margem lateral esquerda)
            pcall(vim.fn.sign_place, 0, sign_group, "TestPassedSign", bnr, {
              lnum = line,
              priority = 20,
            })

            -- Extmark moderno de Neovim com sign_text + virt_text
            pcall(vim.api.nvim_buf_set_extmark, bnr, test_ns, line - 1, 0, {
              sign_text = "✔",
              sign_hl_group = "TestPassedSign",
              virt_text = { { "✔ passou", "TestPassedSign" } },
              virt_text_pos = "eol",
            })
          end
        end
      end

      -- 2. SINAIS PARA TESTES QUE FALHARAM (✘ vermelho de lado na margem)
      local diags_by_buf = {}
      for _, ft in ipairs(failed_tests) do
        local target_buf = current_buf
        if ft.file and vim.fn.filereadable(ft.file) == 1 then
          target_buf = vim.fn.bufadd(ft.file)
          pcall(vim.fn.bufload, target_buf)
        end

        if target_buf and vim.api.nvim_buf_is_valid(target_buf) then
          local line = ft.line or find_test_line(target_buf, ft.name) or 1

          -- Sign clássico de erro ✘ na SignColumn (margem lateral esquerda)
          pcall(vim.fn.sign_place, 0, sign_group, "TestFailedSign", target_buf, {
            lnum = line,
            priority = 30,
          })

          -- Extmark moderno de Neovim com sign_text ✘ + mensagem de erro
          pcall(vim.api.nvim_buf_set_extmark, target_buf, test_ns, line - 1, 0, {
            sign_text = "✘",
            sign_hl_group = "TestFailedSign",
            virt_text = { { "✘ " .. ft.error, "TestFailedSign" } },
            virt_text_pos = "eol",
          })

          -- Diagnóstico para hover e undercurl
          diags_by_buf[target_buf] = diags_by_buf[target_buf] or {}
          table.insert(diags_by_buf[target_buf], {
            bufnr = target_buf,
            lnum = line - 1,
            col = 0,
            severity = vim.diagnostic.severity.ERROR,
            source = "Test Failure",
            message = "✘ " .. ft.name .. ": " .. ft.error,
          })
        end
      end

      -- Publica diagnósticos para hover e undercurl
      for bnr, diags in pairs(diags_by_buf) do
        pcall(vim.diagnostic.set, test_ns, bnr, diags)
      end

      -- Força o redesenho visual da SignColumn e da janela
      vim.cmd("redraw")

      -- Notificação final
      local total = #passed_tests + #failed_tests
      if #failed_tests > 0 then
        vim.notify(
          string.format("✘ %d teste(s) falharam! (%d passaram)", #failed_tests, #passed_tests),
          vim.log.levels.ERROR
        )
        M.show_output()
      elseif total > 0 then
        vim.notify(
          string.format("✔ Todos os %d teste(s) passaram com sucesso!", total),
          vim.log.levels.INFO
        )
        if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
          vim.api.nvim_win_close(M.output_win, true)
          M.output_win = nil
        end
      else
        vim.notify("Nenhum resultado de teste encontrado na saída.", vim.log.levels.WARN)
      end
    end)
  end)
end

--- Executa os testes diretamente no terminal interativo do PowerShell via ToggleTerm
function M.run_in_terminal(opts)
  opts = opts or {}
  local project_path = find_closest_csproj()
  local cmd = "dotnet test"
  if project_path then
    cmd = cmd .. ' "' .. project_path .. '"'
  end

  if opts.nearest then
    local nearest = get_nearest_test_name()
    if nearest then
      cmd = cmd .. ' --filter "FullyQualifiedName~' .. nearest .. '"'
    end
  elseif opts.file then
    local class_name = vim.fn.expand("%:t:r")
    if class_name and class_name ~= "" then
      cmd = cmd .. ' --filter "FullyQualifiedName~' .. class_name .. '"'
    end
  end

  local ok, toggleterm = pcall(require, "toggleterm")
  if ok then
    toggleterm.exec(cmd, 1, 14)
  else
    vim.cmd("botright 14split | terminal " .. cmd)
  end
end

--- Alterna o modo de execução automática ao salvar ficheiro de teste
function M.toggle_watch()
  M.watch_active = not M.watch_active
  if M.watch_active then
    vim.notify("🧪 Modo Test Watch ATIVADO (executa ao salvar :w)", vim.log.levels.INFO)
  else
    vim.notify("🧪 Modo Test Watch DESATIVADO", vim.log.levels.WARN)
  end
end

-- Configura autocommand para Test Watch
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*Tests.cs", "*Test.cs" },
  callback = function()
    if M.watch_active then
      M.run({ file = true })
    end
  end,
})

-- Comandos de utilizador
vim.api.nvim_create_user_command("Test", function() M.run({ file = true }) end, { desc = "Executar testes do ficheiro atual" })
vim.api.nvim_create_user_command("TestNearest", function() M.run({ nearest = true }) end, { desc = "Executar teste sob o cursor" })
vim.api.nvim_create_user_command("TestAll", function() M.run({ all = true }) end, { desc = "Executar todos os testes do projeto" })
vim.api.nvim_create_user_command("TestClear", M.clear, { desc = "Limpar resultados de testes" })
vim.api.nvim_create_user_command("TestWatch", M.toggle_watch, { desc = "Alternar execução automática de testes ao salvar" })
vim.api.nvim_create_user_command("TestOutput", M.toggle_output, { desc = "Alternar painel de output de testes" })
vim.api.nvim_create_user_command("TestTerminal", function() M.run_in_terminal({ file = true }) end, { desc = "Executar testes no terminal PowerShell interativo" })

return M
