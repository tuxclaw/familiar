.pragma library

// Desktop IDs are opaque (including PWA WM classes), never filesystem paths.
function appId(value) {
    if (typeof value !== "string") throw new Error("expected app id")
    var id = value.trim().replace(/\.desktop$/, "")
    if (!id || id === "." || id === ".." || /[/\\\x00-\x1f\x7f]/.test(id))
        throw new Error("invalid app id")
    return id
}

function normalize(list) {
    if (!Array.isArray(list)) throw new Error("expected pins array")
    var seen = Object.create(null)
    var folders = Object.create(null)
    function unique(value) {
        var id = appId(value)
        if (seen[id]) return null
        seen[id] = true
        return id
    }
    var result = []
    list.forEach(function(pin) {
        if (typeof pin === "string") {
            var id = unique(pin)
            if (id !== null) result.push(id)
        } else {
            if (!pin || Array.isArray(pin) || Object.keys(pin).sort().join(",") !== "id,items,name,type"
                || pin.type !== "folder" || typeof pin.id !== "string"
                || !/^[A-Za-z0-9_-]{1,80}$/.test(pin.id) || folders[pin.id]
                || typeof pin.name !== "string" || !pin.name.trim() || pin.name.length > 64
                || /[/\\\x00-\x1f\x7f]/.test(pin.name) || !Array.isArray(pin.items))
                throw new Error("invalid folder")
            folders[pin.id] = true
            var items = pin.items.map(unique).filter(function(id) { return id !== null })
            result.push({ type: "folder", id: pin.id, name: pin.name.trim(), items: items })
        }
    })
    return result
}

function key(pin) { return typeof pin === "string" ? "app:" + appId(pin) : "folder:" + pin.id }
function clone(pins) { return JSON.parse(JSON.stringify(normalize(pins))) }

// Insert indexes refer to the remaining rail, with the source removed.
function insert(list, source, index) {
    var next = list.slice()
    var from = next.indexOf(source)
    if (from >= 0) next.splice(from, 1)
    next.splice(Math.max(0, Math.min(next.length, index)), 0, source)
    return next
}

function railIndex(x, y, count, columns, cellWidth, cellHeight) {
    var row = Math.max(0, Math.floor(y / cellHeight))
    var column = Math.max(0, Math.min(columns, Math.floor(x / cellWidth + 0.5)))
    return Math.max(0, Math.min(count, row * columns + column))
}

function take(pins, id, folderId) {
    if (folderId) {
        var folder = pins.filter(function(pin) { return pin.type === "folder" && pin.id === folderId })[0]
        if (!folder || folder.items.indexOf(id) < 0) return null
        folder.items.splice(folder.items.indexOf(id), 1)
        if (!folder.items.length) pins.splice(pins.indexOf(folder), 1)
        return id
    }
    var index = pins.map(key).indexOf(id)
    return index < 0 ? null : pins.splice(index, 1)[0]
}

function move(pins, sourceKey, folderId, index) {
    var next = clone(pins)
    var source = take(next, sourceKey, folderId)
    if (source === null) return next
    next.splice(Math.max(0, Math.min(next.length, index)), 0, source)
    return next
}

function merge(pins, sourceKey, folderId, targetKey, newId) {
    var next = clone(pins)
    var target = next.filter(function(pin) { return key(pin) === targetKey })[0]
    if (!target || sourceKey === targetKey || (folderId && target.id === folderId)) return next
    var source = take(next, sourceKey, folderId)
    if (typeof source !== "string") return clone(pins)
    if (typeof target === "string") {
        next[next.indexOf(target)] = { type: "folder", id: newId, name: "Folder", items: [target, source] }
    } else if (target.items.indexOf(source) < 0) target.items.push(source)
    return normalize(next)
}

function reorderFolder(pins, folderId, id, index) {
    var next = clone(pins)
    next.forEach(function(pin) {
        if (pin.type === "folder" && pin.id === folderId && pin.items.indexOf(id) >= 0)
            pin.items = insert(pin.items, id, index)
    })
    return next
}

function dissolve(pins, folderId) {
    var next = []
    clone(pins).forEach(function(pin) {
        if (pin.type === "folder" && pin.id === folderId) next = next.concat(pin.items)
        else next.push(pin)
    })
    return next
}

function toggle(pins, id, pin) {
    var next = clone(pins)
    id = appId(id)
    var found = false
    next = next.filter(function(item) {
        if (typeof item === "string") { if (item === id) { found = true; return pin } }
        else {
            item.items = item.items.filter(function(app) {
                if (app === id) { found = true; return pin }
                return true
            })
            return item.items.length > 0
        }
        return true
    })
    if (pin && !found) next.push(id)
    return next
}

function isDrag(dx, dy, threshold) { return Math.hypot(dx, dy) >= threshold }
function isLongPress(elapsed, dx, dy, threshold) { return elapsed >= 450 && !isDrag(dx, dy, threshold) }
