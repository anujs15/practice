// Logging helper library for QML/JS

function _ts() {
    return new Date().toISOString()
}

function _mk(msg, level) {
    return "[" + _ts() + "] [" + level + "] " + msg
}

function info(msg) {
    try {
        var m = _mk(msg, "INFO")
        console.log(m)
        if (typeof Store !== 'undefined' && Store.appendLog) Store.appendLog(m)
    } catch(e) { console.log("Logging.info failed: " + e) }
}

function warn(msg) {
    try {
        var m = _mk(msg, "WARN")
        console.warn(m)
        if (typeof Store !== 'undefined' && Store.appendLog) Store.appendLog(m)
    } catch(e) { console.log("Logging.warn failed: " + e) }
}

function error(msg) {
    try {
        var m = _mk(msg, "ERROR")
        console.error(m)
        if (typeof Store !== 'undefined' && Store.appendLog) Store.appendLog(m)
    } catch(e) { console.log("Logging.error failed: " + e) }
}

function exportLogs(dstPath) {
    try {
        if (typeof Store !== 'undefined' && Store.exportLogs) {
            return Store.exportLogs(dstPath)
        }
    } catch(e) { console.log("Logging.export failed: " + e) }
    return false
}

function clearLogs() {
    try {
        if (typeof Store !== 'undefined' && Store.clearLogs) {
            Store.clearLogs()
            return true
        }
    } catch(e) { console.log("Logging.clear failed: " + e) }
    return false
}
