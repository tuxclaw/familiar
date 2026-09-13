.pragma library

function parse(id) {
  var match = /^(chrome|chromium|brave|edge)-([^\s/]+)__-(.+)$/i.exec(
    String(id || "").trim().replace(/\.desktop$/, ""))
  if (!match) return null
  var host = match[2].toLowerCase().replace(/:\d+$/, "").replace(/\.$/, "")
  if (!/^[a-z0-9]+(?:[.-][a-z0-9]+)*$/.test(host)) return null
  return { browser: match[1].toLowerCase(), host: host, profile: match[3] }
}

function hosts(text) {
  var result = []
  var pattern = /https?:\/\/([a-z0-9.-]+)(?=[:/\s?#"']|$)/gi
  var match
  while ((match = pattern.exec(String(text || ""))) !== null)
    result.push(match[1].toLowerCase().replace(/\.$/, ""))
  return result
}

function words(text) {
  return String(text || "").toLowerCase().split(/[^a-z0-9]+/).filter(Boolean).sort().join(" ")
}

function matchEntry(id, entries) {
  var pwa = parse(id)
  if (!pwa) return null
  var labels = pwa.host.replace(/^www\./, "").split(".")
  // Never infer a localhost/IP app from its display name.
  var nameKey = labels.length > 1 && !/^\d+(?:\.\d+)+$/.test(pwa.host)
    ? words(labels.slice(0, -1).join(" ")) : ""
  var best = null
  var bestScore = 0
  var tied = false
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (/^(?:google-chrome(?:-stable|-beta|-unstable)?|chromium(?:-browser)?|brave(?:-browser)?|microsoft-edge(?:-stable|-beta|-dev)?|chrome|edge)$/i.test(
        String(entry.id || "").replace(/\.desktop$/, ""))) continue
    var entryPwa = parse(entry.startupClass) || parse(entry.id)
    var score = entryPwa && entryPwa.host === pwa.host ? 3 : 0
    var urls = hosts(entry.execString).concat(hosts(entry.url))
    if (urls.indexOf(pwa.host) !== -1) score = Math.max(score, 2)
    // Explicit URLs for another host override guesses from names/icons.
    if (!score && !urls.length && !entryPwa && nameKey) {
      var entryId = String(entry.id || "").replace(/\.desktop$/, "")
      if (words(entry.name) === nameKey || words(entry.icon) === nameKey || words(entryId) === nameKey)
        score = 1
    }
    if (score > bestScore) {
      best = entry
      bestScore = score
      tied = false
    } else if (score && score === bestScore) tied = true
  }
  return tied ? null : best
}

function fallbackIcon(id) {
  var pwa = parse(id)
  if (!pwa) return ""
  return { chrome: "google-chrome", chromium: "chromium", brave: "brave-browser", edge: "microsoft-edge" }[pwa.browser]
}
