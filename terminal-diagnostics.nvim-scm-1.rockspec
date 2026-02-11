rockspec_format = "3.0"
package = "terminal-diagnostics.nvim"
version = "scm-1"

description = {
  summary = "Tools for working with erroneous command output in neovim's builtin terminal",
  detailed = [[]],
  labels = {
    "neovim",
    "terminal",
    "diagnostics",
  },
  homepage = "https://github.com/MisanthropicBit/terminal-diagnostics.nvim",
  issues_url = "https://github.com/MisanthropicBit/terminal-diagnostics.nvim/issues",
  license = "BSD 3-Clause",
}

dependencies = {
  "lua == 5.1",
}

source = {
   url = "git://github.com/MisanthropicBit/terminal-diagnostics.nvim",
}

build = {
   type = "builtin",
   copy_directories = {
     "doc",
     "plugin",
   },
}

test = {
    type = "command",
    command = "./tests/run_tests.sh",
}
