// Simple profile helper for packing/unpacking user data

function collect(appsdata, attemptedByApp, alias) {
    // compute minimal overall stats from attemptedByApp
    var stats = { totalApps: 0, totalTests: 0, attempted: 0, correct: 0 }
    var completedObjectives = {}
    try {
        var learning = attemptedByApp || {}
        var appIds = Object.keys(learning)
        stats.totalApps = appIds.length
        appIds.forEach(function(appId) {
            var arr = learning[appId] || []
            stats.totalTests += arr.length || 0
            completedObjectives[appId] = []
            for (var i = 0; i < arr.length; i++) {
                var it = arr[i]
                if (it && it.attempt) stats.attempted += 1
                if (it && it.correct) {
                    stats.correct += 1
                    completedObjectives[appId].push(i)
                }
            }
        })
    } catch(e) { /* ignore */ }

    return {
        version: 1,
        alias: alias || "",
        apps: appsdata, // static shortcuts structure
        learning: attemptedByApp || {}, // map appId -> attemptedKeys array (from Testground)
        completedObjectives: completedObjectives, // map appId -> list of completed test indices
        addedApps: [], // placeholder if user adds custom apps later
        overall: stats
    }
}

function apply(profile, out) {
    if (!profile) return
    // We only restore learning now
    if (profile.learning && out) {
        out.learning = profile.learning
    }
}

function stringify(obj) {
    try { return JSON.stringify(obj, null, 2) } catch (e) { return "{}" }
}

function parse(json) {
    try { return JSON.parse(json) } catch (e) { return null }
}

// Exported names
var api = {
  collect: collect,
  apply: apply,
  stringify: stringify,
  parse: parse
}

// For QML import
api
