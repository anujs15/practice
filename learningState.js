var _learning = {}

function setLearning(appId, attemptedKeysArray) {
    _learning[appId] = attemptedKeysArray
}

function getAll() {
    return _learning
}

function apply(map) {
    if (!map) return
    _learning = map
}

var Learning = {
    setLearning: setLearning,
    getAll: getAll,
    apply: apply
}

Learning
