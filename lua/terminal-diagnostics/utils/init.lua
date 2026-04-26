local lazy_require = require("terminal-diagnostics.utils.lazy_require")

return {
    patterns = lazy_require("terminal-diagnostics.utils.patterns"),
    cursor = lazy_require("terminal-diagnostics.utils.cursor"),
    url = lazy_require("terminal-diagnostics.utils.url"),
    timing = lazy_require("terminal-diagnostics.utils.timing"),
    range = lazy_require("terminal-diagnostics.utils.range"),
    lazy_require = lazy_require,
}
