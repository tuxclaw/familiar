.pragma library

function boundedText(value) {
  return String(value || "").slice(0, 256)
}

function parsePayload(raw) {
  if (raw === undefined) raw = "{}"
  if (typeof raw !== "string" || raw.length > 4096) return { status: "invalid" }
  // Count UTF-8 bytes before parsing, with at most 4096 code units to inspect.
  var bytes = 0
  for (var i = 0; i < raw.length; i++) {
    var code = raw.charCodeAt(i)
    if (code < 0x80) bytes++
    else if (code < 0x800) bytes += 2
    else if (code >= 0xd800 && code <= 0xdbff && i + 1 < raw.length
             && raw.charCodeAt(i + 1) >= 0xdc00 && raw.charCodeAt(i + 1) <= 0xdfff) {
      bytes += 4
      i++
    } else bytes += 3
    if (bytes > 4096) return { status: "invalid" }
  }
  var parsed
  try { parsed = JSON.parse(raw) } catch (error) { return { status: "invalid" } }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed))
    return { status: "invalid" }
  var sanitized = { surface: "launcher" }
  var keys = Object.keys(parsed)
  for (var k = 0; k < keys.length; k++) {
    var key = keys[k]
    if (["surface", "query", "scope"].indexOf(key) < 0) return { status: "invalid" }
    // String-only fields enforce a maximum schema depth of one.
    if (typeof parsed[key] !== "string" || parsed[key].length > (key === "query" ? 256 : 32))
      return { status: "invalid" }
    sanitized[key] = parsed[key]
  }
  if (["launcher", "overview", "switcher"].indexOf(sanitized.surface) < 0)
    return { status: "unknown-surface" }
  return { status: "ok", payload: sanitized }
}
