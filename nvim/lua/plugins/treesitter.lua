return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    build = ":TSUpdate",
    config = function()
      pcall(function()
        require("nvim-treesitter.install").compilers = { "zig", "clang", "gcc", "cl" }
      end)

      local configs = require("nvim-treesitter.configs")
      configs.setup({
        ensure_installed = { "c", "c_sharp", "lua", "vim", "vimdoc", "javascript", "typescript", "html", "css", "json", "python" },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
          disable = { "html" }, -- O indentador de HTML do Tree-sitter tem um bug crónico que encosta tudo à esquerda
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      -- Não mostrar breadcrumb/contexto (namespace, classe ou método) acima
      -- do código; o cabeçalho fica reservado exclusivamente para as tabs.
      local ok, context = pcall(require, "treesitter-context")
      if ok then
        context.setup({ enable = false })
        context.disable()
      end
    end,
  },
}
