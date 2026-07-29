local error_pattern = [[\v^(%(%(\/)?%([.A-Za-z0-9-_+]+\/)+[.A-Za-z0-9-_+]+\.\w+)):(\d+):in: `(\w+)`: (.+) (.+)\n\s+ from %(%(%(\/)?%([.A-Za-z0-9-_+]+\/)+[.A-Za-z0-9-_+]+\.\w+)):\d+:in `\w+`$]]

local error_spec = {
    pattern = error_pattern,
    path_kind = "relative",
    path = 1,
    lnum = 2,
    message = 3,
    code = 3,
}

