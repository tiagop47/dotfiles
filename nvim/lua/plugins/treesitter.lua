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
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable = true,
      max_lines = 3, -- No máximo 3 linhas fixas no topo para não roubar espaço
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 1,
      trim_scope = "outer",
      mode = "cursor",
    },
  },
}
