vim.opt.rtp:append(".")

-- Set up mini.test only when calling headless neovim
if #vim.api.nvim_list_uis() == 0 then
  vim.opt.rtp:append("deps/mini.test")

  require("mini.test").setup()
end
