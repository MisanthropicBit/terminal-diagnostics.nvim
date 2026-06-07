local lazy_require = require("terminal-diagnostics.utils.lazy_require")

return {
    cursor = lazy_require("terminal-diagnostics.utils.cursor"),
    url = lazy_require("terminal-diagnostics.utils.url"),
    lazy_require = lazy_require,
}
