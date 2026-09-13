return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter")
      if not ok then return end

      pcall(function()
        require("nvim-treesitter.install").compilers = { "zig", "clang", "gcc", "cl" }
      end)

      local configs_ok, ts_configs = pcall(require, "nvim-treesitter.configs")
      if configs_ok then
        ts_configs.setup({
          ensure_installed = { "c", "c_sharp", "lua", "vim", "vimdoc", "javascript", "typescript", "html", "css", "json", "python" },
          auto_install = true,
          highlight = { enable = true },
          indent = { enable = true },
        })
      end
    end,
  },
}
