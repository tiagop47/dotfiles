local keymap = vim.keymap.set
local function map(modes, lhs, rhs, desc, opts)
  opts = opts or {}
  if desc then
    opts.desc = desc
  end
  if opts.silent == nil then
    opts.silent = true
  end
  keymap(modes, lhs, rhs, opts)
end

local function open_path_in_browser(path)
  if vim.ui and vim.ui.open then
    vim.ui.open(path)
    return
  end

  local opener = vim.fn.has("unix") == 1 and "xdg-open" or "open"
  vim.fn.jobstart({ opener, path }, { detach = true })
end

local function preview_lsp_location_or_hover(method)
  local function is_list(value)
    return type(value) == "table" and type(value[1]) ~= "nil"
  end

  if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
    vim.lsp.buf.hover()
    return
  end

  local params = vim.lsp.util.make_position_params(0, "utf-8")
  vim.lsp.buf_request(0, method, params, function(err, result, ctx, _)
    if err then
      local err_msg = type(err) == "table" and err.message or tostring(err)
      vim.notify("Erro ao obter preview LSP: " .. err_msg, vim.log.levels.WARN)
      return
    end

    if not result or (is_list(result) and #result == 0) then
      vim.lsp.buf.hover()
      return
    end

    local location = result
    if is_list(result) then
      location = result[1]
    end

    -- Normalize LocationLink -> Location for Neovim versions without
    -- `vim.lsp.util.location_link_to_location`.
    if location and location.targetUri then
      local range = location.targetSelectionRange or location.targetRange
      if not range then
        vim.lsp.buf.hover()
        return
      end
      location = {
        uri = location.targetUri,
        range = range,
      }
    end

    local ok, preview_err = pcall(vim.lsp.util.preview_location, location, { border = "rounded" }, ctx and ctx.offset_encoding)
    if not ok then
      vim.notify("Falha ao abrir preview: " .. tostring(preview_err), vim.log.levels.WARN)
      vim.lsp.buf.hover()
    end
  end)
end

local function preview_definition_or_hover()
  preview_lsp_location_or_hover("textDocument/definition")
end

local function preview_implementation_or_hover()
  preview_lsp_location_or_hover("textDocument/implementation")
end

-- Navegação Geral
map("n", "<C-k>", "15kzz", "Sobe 15 linhas")
map("n", "<C-j>", "15jzz", "Desce 15 linhas")
map({ 'n', 'v', 'i' }, "<C-s>", "<Esc>:w<CR>", "Guardar ficheiro")
map({ 'n', 'v', 'i' }, "<C-z>", "<Esc>u", "Undo")

-- Multi-Cursor (Estilo VS Code)
map("n", "<C-d>", "<Plug>(VM-Find-Under)", "Selecionar próxima ocorrência", { noremap = true })
map("v", "<C-d>", "<Plug>(VM-Find-Under)", "Selecionar próxima ocorrência", { noremap = true })
map("n", "<C-S-L>", "<Plug>(VM-Select-All)", "Selecionar todas as ocorrências", { noremap = true })

-- Clipboard (Geral - Teclado e Rato)
map({ 'n', 'v' }, "<C-c>", '"+y', "Copiar para clipboard", { noremap = true })
map({ 'n', 'v' }, "<C-v>", '"+p', "Colar do clipboard", { noremap = true })
map("i", "<C-v>", "<C-r>+", "Colar do clipboard", { noremap = true })
map("c", "<C-v>", "<C-r>+", "Colar do clipboard", { noremap = true })

-- Clipboard no TERMINAL
map("t", "<C-v>", [[<C-\><C-n>"+pi]], "Colar no terminal", { noremap = true })

-- Clipboard no TELESCOPE (Ctrl+P e Ctrl+Shift+F)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopePrompt",
  callback = function()
    -- Mapear Ctrl+V para colar do clipboard do sistema
    map("i", "<C-v>", "<C-r>+", "Colar no Telescope", { buffer = true })
    map("n", "<C-v>", '"+p', "Colar no Telescope", { buffer = true })
  end,
})

-- UI / Plugins
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", "Procurar ficheiros")
map("n", "<C-S-F>", "<cmd>Telescope live_grep<CR>", "Pesquisar no projeto")
map("n", "<C-S-E>", "<cmd>NvimTreeToggle<CR>", "Toggle árvore de ficheiros")
map("n", "<M-m>", "<cmd>Trouble diagnostics toggle<CR>", "Toggle diagnostics globais")
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", "Diagnostics do buffer")
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", "Procurar ficheiros")
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", "Pesquisar texto no projeto")
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", "Toggle árvore de ficheiros")

-- LSP & Formatação
map("n", "gd", vim.lsp.buf.definition, "Ir para definição")
map("n", "K", vim.lsp.buf.hover, "Hover docs")
map("n", "<C-q>", preview_definition_or_hover, "Preview definição/hover")
map("n", "<C-S-q>", preview_implementation_or_hover, "Preview implementation/hover")
map("n", "<C-.>", vim.lsp.buf.code_action, "Code action")
map("n", "<F2>", vim.lsp.buf.rename, "Renomear símbolo")
map("n", "<M-S-F>", function()
  require("conform").format({ lsp_fallback = true, async = true })
end, "Formatar buffer")
map("n", "[d", vim.diagnostic.goto_prev, "Diagnóstico anterior")
map("n", "]d", vim.diagnostic.goto_next, "Próximo diagnóstico")
map("n", "<leader>q", vim.diagnostic.setloclist, "Enviar diagnósticos para location list")

-- Debugger (DAP)
map("n", "<F5>", function() require("dap").continue() end, "Debug continue")
map("n", "<F10>", function() require("dap").step_over() end, "Debug step over")
map("n", "<F11>", function() require("dap").step_into() end, "Debug step into")
map("n", "<F12>", function() require("dap").step_out() end, "Debug step out")
map("n", "<leader>b", function() require("dap").toggle_breakpoint() end, "Toggle breakpoint")

-- Testes
map("n", "<leader>tr", function() require("neotest").run.run() end, "Correr teste")
map("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, "Correr testes do ficheiro")
map("n", "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, "Watch testes do ficheiro")
map("n", "<leader>ts", function() require("neotest").summary.toggle() end, "Toggle resumo de testes")
map("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, "Abrir output de teste")

-- Atalho rápido para Gradle Test (Preenche mas não executa)
map("n", "<leader>gt", function()
    local class_name = vim.fn.expand("%:t:r")
    local cmd = "./gradlew test --tests " .. class_name
    
    -- Abre o terminal (ToggleTerm)
    vim.cmd('ToggleTerm')
    
    -- Pequeno atraso para garantir que o terminal está pronto antes de enviar o texto
    vim.defer_fn(function()
        -- Envia o comando sem o Enter (\r ou \n) e entra em modo insert
        vim.api.nvim_feedkeys(cmd, 'n', false)
        vim.cmd('startinsert')
    end, 50)
end, "Preparar comando Gradle test")

-- Terminal
map("n", "<C-ç>", "<cmd>ToggleTerm<CR>", "Toggle terminal")
map("t", "<C-ç>", [[<C-\><C-n><cmd>ToggleTerm<CR>]], "Toggle terminal")
map("n", "<leader>tt", "<cmd>ToggleTerm<CR>", "Toggle terminal")

-- Facilitar a vida no Terminal (Fazer com que pareça um terminal normal)
local terminal_group = vim.api.nvim_create_augroup("UserTerminalKeymaps", { clear = true })
vim.api.nvim_create_autocmd("TermOpen", {
  group = terminal_group,
  pattern = "term://*",
  callback = function()
    local opts = { buffer = 0 }
    map("t", "<esc>", [[<C-\><C-n>]], "Sair do modo terminal", opts)
    map("t", "jk", [[<C-\><C-n>]], "Sair do modo terminal", opts)
    map("t", "<C-h>", [[<C-\><C-n><C-W>h]], "Janela esquerda", opts)
    map("t", "<C-j>", [[<C-\><C-n><C-W>j]], "Janela abaixo", opts)
    map("t", "<C-k>", [[<C-\><C-n><C-W>k]], "Janela acima", opts)
    map("t", "<C-l>", [[<C-\><C-n><C-W>l]], "Janela direita", opts)
  end,
})

-- Auto-insert ao entrar no terminal
local terminal_ui_group = vim.api.nvim_create_augroup("UserTerminalUi", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = terminal_ui_group,
  pattern = "term://*",
  callback = function()
    vim.cmd("startinsert")
    -- Esconder UI que não faz sentido no terminal
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Abrir Report de Testes Gradle instantaneamente (Ctrl + Shift + B)
map({ "n", "i", "v" }, "<C-S-B>", function()
    local report_path = vim.fn.getcwd() .. "/build/reports/tests/test/index.html"
    if vim.fn.filereadable(report_path) == 1 then
        open_path_in_browser(report_path)
        print("Relatório aberto no browser!")
    else
        print("Relatório não encontrado em: " .. report_path)
    end
end, "Abrir report de testes")

-- Abrir links com Ctrl + Clique
map("n", "<C-LeftMouse>", "gx", "Abrir link sob o cursor")
map("i", "<C-LeftMouse>", "<Esc><LeftMouse>gx", "Abrir link sob o cursor")

-- Atalho para abrir o Report HTML atual no browser (Space + r + h)
map("n", "<leader>rh", function()
    local file = vim.fn.expand("%:p")
    if file:match("%.html$") then
        open_path_in_browser(file)
        print("A abrir report no browser...")
    else
        print("O ficheiro atual não é HTML: " .. file)
    end
end, "Abrir HTML atual no browser")

-- Atalho extra: Na NvimTree, Ctrl+Shift+E abre HTML no browser
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function()
    local api = require("nvim-tree.api")
    
    -- Função específica para o comportamento desejado
    local function open_html_browser_or_edit()
        local node = api.tree.get_node_under_cursor()
        
        -- Verifica se é ficheiro e termina em .html
        if node and node.absolute_path and node.absolute_path:match("%.html$") then
            local opener = vim.fn.has("unix") == 1 and "xdg-open" or "open"
            -- Executa comando silencioso em background
            vim.fn.jobstart({opener, node.absolute_path}, {detach = true})
            print("Report aberto no browser: " .. node.name)
        else
            -- Se não for HTML, abre o ficheiro no nvim (comportamento normal)
            api.node.open.edit()
        end
    end

    -- Mapear com 'nowait' para garantir prioridade sobre o global
    map("n", "<C-S-E>", open_html_browser_or_edit, "Abrir HTML no browser", { buffer = true, noremap = true, nowait = true })
    -- Alternativa caso o terminal envie outro código
    map("n", "<C-e>", open_html_browser_or_edit, "Abrir HTML no browser", { buffer = true, noremap = true, nowait = true })

    -- CLIQUE DIREITO NO RATO (Open in Browser se for HTML)
    map("n", "<RightMouse>", function()
        local pos = vim.fn.getmousepos()
        vim.api.nvim_win_set_cursor(0, {pos.line, pos.column - 1})
        open_html_browser_or_edit()
    end, "Abrir com clique direito", { buffer = true, noremap = true })
  end
})
