return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "williamboman/mason.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        automatic_installation = true,
        ensure_installed = { "netcoredbg", "codelldb" },
      })

      dapui.setup({
        layouts = {
          {
            elements = { "scopes", "breakpoints", "stacks", "watches" },
            size = 40,
            position = "left",
          },
          {
            elements = { "repl", "console" },
            size = 10,
            position = "bottom",
          },
        },
      })

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- Breakpoints e estados visuais na margem, como no VS Code.
      vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DapBreakpoint",
        linehl = "DapBreakpointLine",
        numhl = "DapBreakpoint",
      })
      vim.fn.sign_define("DapBreakpointCondition", {
        text = "◆",
        texthl = "DapBreakpointCondition",
        linehl = "DapBreakpointConditionLine",
        numhl = "DapBreakpointCondition",
      })
      vim.fn.sign_define("DapStopped", {
        text = "▶",
        texthl = "DapStopped",
        linehl = "DapStoppedLine",
        numhl = "DapStopped",
      })

      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#f38ba8" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#f9e2af" })
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#a6e3a1" })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#263b2b" })

      local map = vim.keymap.set
      map("n", "<F5>", dap.continue, { desc = "Debug: iniciar/continuar" })
      map("n", "<S-F5>", dap.terminate, { desc = "Debug: parar" })
      map("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug: breakpoint" })
      map("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
      map("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
      map("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })
      map("n", "<leader>du", dapui.toggle, { desc = "Debug: interface" })
      map("n", "<leader>dr", dap.repl.open, { desc = "Debug: consola" })
      map("n", "<leader>db", function()
        dap.set_breakpoint(vim.fn.input("Condição: "))
      end, { desc = "Debug: breakpoint condicional" })
    end,
  },
}
