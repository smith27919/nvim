return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Required. The default branch is now `main`, which has no `configs` module.
    branch = "master",
    -- packer called this `run`
    build = ":TSUpdate",
    -- nvim-treesitter does not support lazy-loading
    lazy = false,
    -- setup() lives in nvim-treesitter.configs, not nvim-treesitter
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        -- your languages
        "java", "javascript", "typescript", "tsx", "cpp", "c", "python", "lua",

        -- shell and config files you will open constantly
        "bash", "json", "yaml", "toml", "make", "cmake", "dockerfile",

        -- web
        "html", "css",

        -- docs and neovim itself
        "markdown", "markdown_inline", "vim", "vimdoc", "query", "regex", "diff",
      },

      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    },
  },
}
