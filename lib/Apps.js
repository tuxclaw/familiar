.pragma library

function normalizeId(id) {
  var value = String(id || "").trim()
  return value.slice(-8) === ".desktop" ? value.slice(0, -8) : value
}

function words(value) {
  return String(value || "").toLowerCase().split(/[^a-z0-9]+/).filter(Boolean)
}

function fuzzyScore(text, query) {
  var at = 0
  var gap = 0
  for (var i = 0; i < query.length; i++) {
    var found = text.indexOf(query.charAt(i), at)
    if (found < 0) return -1
    gap += found - at
    at = found + 1
  }
  return 1000 - gap - Math.max(0, text.length - query.length)
}

function matchScore(entry, query) {
  var q = String(query || "").slice(0, 256).trim().toLowerCase()
  if (!q.length) return 0
  var name = String(entry.name || "").toLowerCase()
  var haystack = name + " " + String(entry.description || "").toLowerCase()
    + " " + String(entry.categories || "").toLowerCase()
  if (name.indexOf(q) === 0) return 300000
  var nameWords = words(name)
  for (var i = 0; i < nameWords.length; i++)
    if (nameWords[i].indexOf(q) === 0) return 200000
  var fuzzy = fuzzyScore(haystack, q)
  return fuzzy < 0 ? -1 : 100000 + fuzzy
}

function rank(entries, query, frecency) {
  query = String(query || "").slice(0, 256)
  var scored = []
  var usage = frecency || ({})
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    var score = matchScore(entry, query)
    if (score < 0) continue
    scored.push({ entry: entry, score: score, frequent: Number(usage[entry.id] || 0) })
  }
  scored.sort(function(a, b) {
    if (a.score !== b.score) return b.score - a.score
    if (a.frequent !== b.frequent) return b.frequent - a.frequent
    return String(a.entry.name).localeCompare(String(b.entry.name))
  })
  return scored.map(function(value) { return value.entry })
}

function stripJsonComments(text) {
  return String(text || "")
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/(^|[^:])\/\/.*$/gm, "$1")
    .replace(/,\s*([}\]])/g, "$1")
}

function menuCommands(text) {
  if (!String(text || "").trim().length) return []
  try {
    var parsed = JSON.parse(stripJsonComments(text))
    var result = []
    function visit(value, fallbackLabel) {
      if (!value || typeof value !== "object") return
      if (value.action) result.push({
        kind: "command",
        id: "command:" + String(value.action),
        name: String(value.label || fallbackLabel || value.action),
        description: String(value.description || "Omarchy command"),
        categories: "Commands Omarchy",
        action: String(value.action),
        icon: String(value.icon || "system-run")
      })
      if (Array.isArray(value.items))
        for (var i = 0; i < value.items.length; i++) visit(value.items[i], "")
      for (var key in value)
        if (key !== "items" && value[key] && typeof value[key] === "object")
          visit(value[key], key.split(".").pop())
    }
    visit(parsed, "")
    return result
  } catch (error) {
    console.warn("Familiar: unable to parse omarchy-menu.jsonc: " + error)
    return []
  }
}
