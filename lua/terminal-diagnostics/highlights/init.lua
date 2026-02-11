local highlights = {}

function highlights.setup()
    vim.cmd([[
        hi default link TerminalDiagnosticsFloatTitle Title
        hi default link TerminalDiagnosticsPath       Title
        hi default link TerminalDiagnosticsLnum       String
        hi default link TerminalDiagnosticsCol        Character
        hi default link TerminalDiagnosticsCode       Label
        hi default link TerminalDiagnosticsMessage    Keyword
    ]])
end

-- TODO: Better name
---@param name string
---@return string
function highlights.hl_group_for_spec_key(name)
    return "TerminalDiagnostics" .. name:sub(1, 1):upper() .. name:sub(2)
end

return highlights
