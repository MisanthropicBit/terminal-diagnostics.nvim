local new_set = MiniTest.new_set
local eq, neq = MiniTest.expect.equality, MiniTest.expect.no_equality

local CommandSpec = require("terminal-diagnostics.command_spec")
local command_spec = require("terminal-diagnostics.builtins.clang")

local matcher = command_spec:matcher()
local match_spec = matcher:specs()[1]

local parser = command_spec:parser()

local match1 = {
    {
        match = {
            from = {
                col = 0,
                lnum = 2,
            },
            spec = match_spec,
            submatches = {
                "/Users/abc/src/types/type_checker.cpp",
                "85",
                "39",
                "error",
                "no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
            },
            text =
            "/Users/abc/src/types/type_checker.cpp:85:39: error: no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
            to = {
                col = 142,
                lnum = 2,
            },
        },
        spec = match_spec,
    },
}

local match2 = {
    {
        match = {
            from = {
                col = 0,
                lnum = 5,
            },
            spec = match_spec,
            submatches = {
                "/usr/local/Cellar/llvm/21.1.4/bin/../include/c++/v1/__filesystem/path.h",
                "403",
                "8",
                "note",
                "'std::filesystem::path::format' declared here",
            },
            text =
            "/usr/local/Cellar/llvm/21.1.4/bin/../include/c++/v1/__filesystem/path.h:403:8: note: 'std::filesystem::path::format' declared here",
            to = {
                col = 130,
                lnum = 5,
            },
        },
        spec = match_spec,
    },
}

local match3 = {
    {
        match = {
            from = {
                col = 0,
                lnum = 8,
            },
            spec = match_spec,
            submatches = {
                "/Users/abc/src/types/type_checker.cpp",
                "103",
                "35",
                "error",
                "no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
            },
            text =
            "/Users/abc/src/types/type_checker.cpp:103:35: error: no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
            to = {
                col = 143,
                lnum = 8,
            },
        },
        spec = match_spec,
    },
}

local expected_parse_results = { {
    buffer = 0,
    context = {
      lines = {
          "   85 |                 std::string message = std::format(",
          "      |                                       ^    ~~~~~~",
      },
      range = {
        end_ = {
          col = 57,
          lnum = 4
        },
        start = {
          col = 0,
          lnum = 3
        }
      }
    },
    kind = "build",
    matches = { {
        from = {
          col = 0,
          lnum = 2
        },
        spec = match_spec,
        submatches = { "/Users/abc/src/types/type_checker.cpp", "85", "39", "error", "no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?" },
        text = "/Users/abc/src/types/type_checker.cpp:85:39: error: no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
        to = {
          col = 142,
          lnum = 2
        }
      } },
    range = {
      end_ = {
        col = 142,
        lnum = 2
      },
      start = {
        col = 0,
        lnum = 2
      }
    },
    source = "clang",
    values = {
      col = 39,
      lnum = 85,
      message = "no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
      paths = { "/Users/abc/src/types/type_checker.cpp" },
      severity = 1
    }
  }, {
    buffer = 0,
    context = {
      lines = {
          "  403 |   enum format : unsigned char { auto_format, native_format, generic_format };",
          "      |        ^",
      },
      range = {
        end_ = {
          col = 16,
          lnum = 7
        },
        start = {
          col = 0,
          lnum = 6
        }
      }
    },
    kind = "build",
    matches = { {
        from = {
          col = 0,
          lnum = 5
        },
        spec = match_spec,
        submatches = { "/usr/local/Cellar/llvm/21.1.4/bin/../include/c++/v1/__filesystem/path.h", "403", "8", "note", "'std::filesystem::path::format' declared here" },
        text = "/usr/local/Cellar/llvm/21.1.4/bin/../include/c++/v1/__filesystem/path.h:403:8: note: 'std::filesystem::path::format' declared here",
        to = {
          col = 130,
          lnum = 5
        }
      } },
    range = {
      end_ = {
        col = 130,
        lnum = 5
      },
      start = {
        col = 0,
        lnum = 5
      }
    },
    source = "clang",
    values = {
      col = 8,
      lnum = 403,
      message = "'std::filesystem::path::format' declared here",
      paths = { "/usr/local/Cellar/llvm/21.1.4/bin/../include/c++/v1/__filesystem/path.h" },
      severity = "INFO"
    }
  }, {
    buffer = 0,
    context = {
      lines = {
          "  103 |             std::string message = std::format(",
          "      |                                   ^    ~~~~~~",
      },
      range = {
        end_ = {
          col = 53,
          lnum = 10,
        },
        start = {
          col = 0,
          lnum = 9
        }
      }
    },
    kind = "build",
    matches = { {
        from = {
          col = 0,
          lnum = 8
        },
        spec = match_spec,
        submatches = { "/Users/abc/src/types/type_checker.cpp", "103", "35", "error", "no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?" },
        text = "/Users/abc/src/types/type_checker.cpp:103:35: error: no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
        to = {
          col = 143,
          lnum = 8
        }
      } },
    range = {
      end_ = {
        col = 143,
        lnum = 8
      },
      start = {
        col = 0,
        lnum = 8
      }
    },
    source = "clang",
    values = {
      col = 35,
      lnum = 103,
      message = "no member named 'format' in namespace 'std'; did you mean 'std::filesystem::path::format'?",
      paths = { "/Users/abc/src/types/type_checker.cpp" },
      severity = 1
    }
  } }


---@type string[]
local test_lines = {}

local T = new_set({
    hooks = {
        pre_once = function()
            test_lines = vim.fn.readfile("test-files/clang.txt")
        end,
    },
})

T["builtins.clang"] = new_set()
T["builtins.clang"]["CommandSpec"] = new_set()
T["builtins.clang"]["CommandSpec"]["matcher"] = new_set()
T["builtins.clang"]["CommandSpec"]["parser"] = new_set()

T["builtins.clang"]["CommandSpec"]["self"] = function()
    eq(command_spec:name(), "clang")
    eq(command_spec:kind(), CommandSpec.CommandKind.Build)
    neq(command_spec:matcher(), nil)
    neq(command_spec:parser(), nil)
    eq(command_spec:parser():has_context(), true)
end

T["builtins.clang"]["CommandSpec"]["matcher"]["specs"] = function()
    eq(#matcher:specs(), 1)
end

T["builtins.clang"]["CommandSpec"]["matcher"]["match"] = function()
    vim.cmd.edit("test-files/clang.txt")

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    eq(matcher:match({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:match({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:match({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    eq(matcher:match({ buffer = 0 }), match3)

    vim.api.nvim_win_set_cursor(0, { 8, 0 })
    eq(matcher:match({ buffer = 0 }), match3)

    vim.api.nvim_win_set_cursor(0, { 12, 0 })
    eq(matcher:match({ buffer = 0 }), {})
end

T["builtins.clang"]["CommandSpec"]["matcher"]["find_match_start"] = function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match1[1].match)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1].match)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1].match)

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match3[1].match)

    vim.api.nvim_win_set_cursor(0, { 8, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match3[1].match)

    vim.api.nvim_win_set_cursor(0, { 12, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), nil)
end

T["builtins.clang"]["CommandSpec"]["matcher"]["match_at_cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 9, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), match3)

    vim.api.nvim_win_set_cursor(0, { 10, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})
end

T["builtins.clang"]["CommandSpec"]["parser"]["parse"] = function()
    local parse_results = parser:parse(test_lines, { buffer = 0 })

    eq(parse_results, expected_parse_results)
end

T["builtins.clang"]["CommandSpec"]["parser"]["parse_buffer"] = function()
    local parse_results = parser:parse_buffer(0, {})

    eq(parse_results, expected_parse_results)
end

return T
