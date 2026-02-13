local keymap = vim.keymap.set

-- Navegação Geral
keymap("n", "<C-k>", "15kzz")
keymap("n", "<C-j>", "15jzz")
keymap({'n', 'v', 'i'}, '<C-s>', '<Esc>:w<CR>')
keymap({'n', 'v', 'i'}, '<C-z>', '<Esc>u')

-- Multi-Cursor (Estilo VS Code)
keymap("n", "<C-d>", "<Plug>(VM-Find-Under)")
keymap("v", "<C-d>", "<Plug>(VM-Find-Under)")
keymap("n", "<C-S-L>", "<Plug>(VM-Select-All)")

-- Clipboard (Geral)
keymap("v", "<C-c>", '"+y')
keymap("i", "<C-v>", '<C-r>+')
keymap("c", "<C-v>", '<C-r>+')
keymap("n", "<C-v>", '"+p')

-- Clipboard no TERMINAL
keymap('t', '<C-v>', [[<C-\><C-n>"+pi]], { noremap = true })
keymap('t', '<C-c>', [[<C-\><C-n>"+y]], { noremap = true })

-- Clipboard no TELESCOPE (Ctrl+P e Ctrl+Shift+F)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopePrompt",
  callback = function()
    -- Mapear Ctrl+V para colar do clipboard do sistema
    keymap("i", "<C-v>", '<C-r>+', { buffer = true, silent = true })
    keymap("n", "<C-v>", '"+p', { buffer = true, silent = true })
  end,
})

-- UI / Plugins
keymap('n', '<C-p>', ':Telescope find_files<CR>')
keymap('n', '<C-S-F>', ':Telescope live_grep<CR>')
keymap('n', '<C-S-E>', ':NvimTreeToggle<CR>')
keymap('n', '<M-m>', '<cmd>Trouble diagnostics toggle<CR>')
keymap('n', '<leader>xx', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>')

-- LSP & Formatação
keymap("n", "gd", vim.lsp.buf.definition)
keymap("n", "K", vim.lsp.buf.hover)
keymap("n", "<C-.>", vim.lsp.buf.code_action)
keymap("n", "<F2>", vim.lsp.buf.rename)
keymap("n", "<M-S-F>", function() require("conform").format({ lsp_fallback = true, async = true }) end)

-- Debugger (DAP)
keymap("n", "<F5>", function() require("dap").continue() end)
keymap("n", "<F10>", function() require("dap").step_over() end)
keymap("n", "<F11>", function() require("dap").step_into() end)
keymap("n", "<F12>", function() require("dap").step_out() end)
keymap("n", "<leader>b", function() require("dap").toggle_breakpoint() end)

-- Testes
keymap("n", "<leader>tr", function() require("neotest").run.run() end)
keymap("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end)
keymap("n", "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end)
keymap("n", "<leader>ts", function() require("neotest").summary.toggle() end)
keymap("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end)

-- Atalho rápido para Gradle Test (Preenche mas não executa)
keymap("n", "<leader>gt", function()
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
end)

-- Terminal
keymap('n', '<C-ç>', '<cmd>ToggleTerm<CR>')
keymap('t', '<C-ç>', [[<C-\><C-n><cmd>ToggleTerm<CR>]])

-- Abrir Report de Testes Gradle instantaneamente (Ctrl + Shift + B)
keymap({'n', 'i', 'v'}, '<C-S-B>', function()
    local report_path = vim.fn.getcwd() .. "/build/reports/tests/test/index.html"
    if vim.fn.filereadable(report_path) == 1 then
        local opener = vim.fn.has("unix") == 1 and "xdg-open" or "open"
        os.execute(opener .. " " .. report_path .. " > /dev/null 2>&1 &")
        print("Relatório aberto no browser!")
    else
        print("Relatório não encontrado em: " .. report_path)
    end
end)

-- Abrir links com Ctrl + Clique
keymap('n', '<C-LeftMouse>', 'gx')
keymap('i', '<C-LeftMouse>', '<Esc><LeftMouse>gx')

-- Atalho para abrir o Report HTML atual no browser (Space + r + h)
keymap("n", "<leader>rh", function()
    local file = vim.fn.expand("%:p")
    if file:match("%.html$") then
        -- Usar o comando shell direto para garantir que o browser abre
        local opener = vim.fn.has("unix") == 1 and "xdg-open" or "open"
        os.execute(opener .. " " .. file .. " > /dev/null 2>&1 &")
        print("A abrir report no browser...")
    else
        print("O ficheiro atual não é HTML: " .. file)
    end
end)

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
    keymap("n", "<C-S-E>", open_html_browser_or_edit, { buffer = true, noremap = true, silent = true, nowait = true })
    -- Alternativa caso o terminal envie outro código
    keymap("n", "<C-e>", open_html_browser_or_edit, { buffer = true, noremap = true, silent = true, nowait = true })

    -- CLIQUE DIREITO NO RATO (Open in Browser se for HTML)
    keymap("n", "<RightMouse>", function()
        local pos = vim.fn.getmousepos()
        vim.api.nvim_win_set_cursor(0, {pos.line, pos.column - 1})
        open_html_browser_or_edit()
    end, { buffer = true, noremap = true, silent = true })
  end
})
