local M = { watch_active = false }

local function neotest()
  return require("neotest")
end

function M.run(opts)
  opts = opts or {}
  local args = opts.all and { suite = true }
    or opts.path and { opts.path }
    or opts.file and { vim.fn.expand("%:p") }
    or {}
  if opts.debug then
    args.strategy = "dap"
    neotest().run.run(args)
    return
  end
  neotest().run.run(args)
  neotest().summary.open({ enter = false })
end

-- Permite escolher interativamente qual projeto de testes (.csproj) carregar/executar
function M.select_project()
  local cwd = vim.fn.getcwd()
  local files = vim.fn.globpath(cwd, "**/*Test*.csproj", false, true)
  if #files == 0 then
    files = vim.fn.globpath(cwd, "**/*.csproj", false, true)
  end

  if #files == 0 then
    vim.notify("Nenhum projeto .csproj encontrado.", vim.log.levels.WARN)
    return
  end

  vim.ui.select(files, {
    prompt = "Escolhe o projeto de testes (.csproj):",
    format_item = function(item)
      local name = vim.fs.basename(item)
      local rel = vim.fn.fnamemodify(item, ":.")
      return string.format("%-30s (%s)", name, rel)
    end,
  }, function(selected)
    if not selected then return end
    local proj_dir = vim.fs.dirname(selected)
    vim.notify("A carregar e executar testes de: " .. vim.fs.basename(selected))
    M.run({ path = proj_dir })
  end)
end

function M.toggle_terminal()
  neotest().output_panel.toggle()
end

function M.clear()
  neotest().output_panel.clear()
  vim.notify("Output limpo; os estados dos testes permanecem no painel.")
end

function M.toggle_watch()
  M.watch_active = not M.watch_active
  vim.notify("Testes ao guardar: " .. (M.watch_active and "ativados" or "desativados"))
end

function M.jump_failed(direction)
  local failures = vim.diagnostic.get(0, { namespace = vim.api.nvim_create_namespace("neotest") })
  if #failures == 0 then
    vim.notify("Sem testes falhados neste ficheiro.")
    return
  end
  table.sort(failures, function(a, b) return a.lnum < b.lnum end)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local target = direction > 0 and failures[1] or failures[#failures]
  if direction > 0 then
    for _, failure in ipairs(failures) do
      if failure.lnum > line then target = failure; break end
    end
  else
    for i = #failures, 1, -1 do
      if failures[i].lnum < line then target = failures[i]; break end
    end
  end
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { target.lnum + 1, target.col or 0 })
  vim.cmd("normal! zv")
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("DotnetTestWatch", { clear = true }),
  pattern = { "*.cs", "*.fs" },
  callback = function(event)
    if M.watch_active then
      neotest().run.run(vim.api.nvim_buf_get_name(event.buf))
    end
  end,
})

local commands = {
  Test = { function() M.run({ file = true }) end, "Executar testes do ficheiro" },
  TestNearest = { function() M.run() end, "Executar teste sob o cursor" },
  TestAll = { function() M.run({ all = true }) end, "Executar todos os testes" },
  TestProject = { M.select_project, "Selecionar e executar testes de um .csproj específico" },
  TestDebug = { function() M.run({ debug = true }) end, "Debug do teste sob o cursor" },
  TestSummary = { function() neotest().summary.toggle() end, "Mostrar/ocultar explorador de testes" },
  TestOutput = { function() neotest().output.open({ enter = true, auto_close = true }) end, "Detalhes do teste sob o cursor" },
  TestTerminal = { M.toggle_terminal, "Mostrar/ocultar output completo dos testes" },
  TestClear = { M.clear, "Limpar output dos testes" },
  TestWatch = { M.toggle_watch, "Alternar testes do ficheiro ao guardar" },
  TestNextFailed = { function() M.jump_failed(1) end, "Proxima falha no ficheiro" },
  TestPrevFailed = { function() M.jump_failed(-1) end, "Falha anterior no ficheiro" },
  TestStop = { function() neotest().run.stop({ suite = true }) end, "Parar testes" },
}
for name, command in pairs(commands) do
  vim.api.nvim_create_user_command(name, command[1], { desc = command[2], force = true })
end

return M
