const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
function functions(file, names, context) {
  for (const name of names)
    vm.runInContext(read(file).match(new RegExp('  function ' + name + '\\([^]*?^  }', 'm'))[0], context);
}
const DockPins = vm.createContext({});
vm.runInContext(read('lib/DockPins.js').replace(/^\.pragma library\s*/, ''), DockPins);
const plain = value => JSON.parse(JSON.stringify(value));
const folder = { type: 'folder', id: 'tools', name: 'Tools', items: ['b', 'c'] };
const mixed = ['a', folder, 'd'];
assert.deepEqual(plain(DockPins.normalize(mixed)), mixed);
assert.deepEqual(plain(DockPins.merge(['a', 'b', 'd'], 'app:a', null, 'app:b', 'new')),
  [{ type: 'folder', id: 'new', name: 'Folder', items: ['b', 'a'] }, 'd']);
assert.deepEqual(plain(DockPins.merge(mixed, 'app:a', null, 'folder:tools', 'unused')),
  [{ ...folder, items: ['b', 'c', 'a'] }, 'd']);
assert.deepEqual(plain(DockPins.move(mixed, 'b', 'tools', 1)), ['a', 'b', { ...folder, items: ['c'] }, 'd']);
assert.deepEqual(plain(DockPins.move([{ ...folder, items: ['b'] }, 'd'], 'b', 'tools', 1)), ['d', 'b']);
assert.deepEqual(plain(DockPins.reorderFolder(mixed, 'tools', 'b', 1)), ['a', { ...folder, items: ['c', 'b'] }, 'd']);
assert.deepEqual(plain(DockPins.dissolve(mixed, 'tools')), ['a', 'b', 'c', 'd']);
assert.deepEqual(plain(DockPins.move(mixed, 'folder:tools', null, 2)), ['a', 'd', folder]);
assert.deepEqual(plain(DockPins.merge(mixed, 'folder:tools', null, 'app:a', 'new')), mixed);
assert.deepEqual(plain(DockPins.toggle(mixed, 'b', false)), ['a', { ...folder, items: ['c'] }, 'd']);
assert.deepEqual(plain(DockPins.insert(['a', 'b', 'c', 'd', 'e'], 'a', 4)), ['b', 'c', 'd', 'e', 'a']);
assert.equal(DockPins.railIndex(-50, 0, 3, 4, 60, 60), 0);
assert.equal(DockPins.railIndex(95, 0, 3, 4, 60, 60), 2);
assert.equal(DockPins.railIndex(0, 65, 7, 4, 60, 60), 4);
assert.equal(DockPins.railIndex(500, 500, 7, 4, 60, 60), 7);
assert.equal(DockPins.isLongPress(449, 0, 0, 10), false);
assert.equal(DockPins.isLongPress(450, 9, 0, 10), true);
assert.equal(DockPins.isLongPress(450, 10, 0, 10), false);
const invalidPins = [[1], [{}], ['../app'], ['/tmp/app'], ['C:\\app'],
  [{ ...folder, path: 'x' }], [{ ...folder, items: [1] }], [{ ...folder, items: ['a/b'] }],
  [{ ...folder, items: [folder] }], [{ ...folder, id: '../x' }], [{ ...folder, name: 'x'.repeat(65) }],
  [{ ...folder, name: '' }], [{ ...folder, name: 'a/b' }], [{ ...folder, name: 'a\n' }], [folder, folder]];
for (const invalid of invalidPins) assert.throws(() => DockPins.normalize(invalid));
const service = vm.createContext({ DockPins, storedPinned: [], pendingPinned: null,
  pinnedPersistProcess: { running: false }, Qt: { resolvedUrl: () => path.join(root, 'lib/dock-pins.py') }, console });
functions('Service.qml', ['normalizePinned', 'persistPinned', 'flushPinned', 'ingestPinned'], service);
assert.equal(service.persistPinned([42]), 'refused');
assert.equal(service.persistPinned([], '/tmp/elsewhere'), 'refused');
assert.equal(service.persistPinned([' a.desktop ', 'a', 'b']), 'ok');
const command = Array.from(service.pinnedPersistProcess.command);
assert.deepEqual(JSON.parse(command.at(-1)), { pins: ['a', 'b'] });
service.persistPinned(['later.desktop']);
assert.deepEqual(Array.from(service.pendingPinned), ['later']);
assert.deepEqual(Array.from(service.pinnedPersistProcess.command), command);
service.pinnedPersistProcess.running = false;
service.flushPinned();
assert.deepEqual(JSON.parse(service.pinnedPersistProcess.command.at(-1)), { pins: ['later'] });
service.persistPinned(mixed);
assert.deepEqual(plain(service.pendingPinned), mixed);
for (const invalid of invalidPins) assert.equal(service.persistPinned(invalid), 'refused');
service.ingestPinned(JSON.stringify({ pins: mixed }));
assert.deepEqual(plain(service.storedPinned), mixed);
service.ingestPinned('{"pins":["a.desktop","b"]}');
assert.deepEqual(Array.from(service.storedPinned), ['a', 'b']);
const previous = service.storedPinned;
service.ingestPinned('{"pins":["changed"]}');
assert.notEqual(service.storedPinned, previous);
assert.doesNotMatch(read('Service.qml'), /config\.bar\.dockPinned\s*=/);
const temp = fs.mkdtempSync(path.join(root, 'tests/.dock-test-'));
try {
  const dir = path.join(temp, '.config/omarchy');
  fs.mkdirSync(dir, { recursive: true });
  const shellPath = path.join(dir, 'shell.json');
  const pinPath = path.join(dir, 'familiar-dock.json');
  const legacy = JSON.stringify({ bar: { dockPinned: ' a.desktop,b,a ' }, extra: 42 });
  fs.writeFileSync(shellPath, legacy);
  const run = (...args) => spawnSync('python3', [path.join(root, 'lib/dock-pins.py'), ...args],
    { cwd: temp, env: { ...process.env, HOME: temp }, encoding: 'utf8' });
  const ok = (...args) => { const result = run(...args); assert.equal(result.status, 0, result.stderr); return JSON.parse(result.stdout); };
  assert.deepEqual(ok('--read'), { pins: ['a', 'b'] });
  assert.equal(fs.readFileSync(shellPath, 'utf8'), legacy);
  fs.writeFileSync(shellPath, '{"bar":{"dockPinned":"different"}}');
  assert.deepEqual(ok('--read'), { pins: ['a', 'b'] });
  const unusual = 'app$(touch sentinel)`id`"';
  const oldFd = fs.openSync(pinPath, 'r');
  assert.deepEqual(ok('--write', JSON.stringify({ pins: [unusual] })), { pins: [unusual] });
  assert.deepEqual(JSON.parse(fs.readFileSync(oldFd)), { pins: ['a', 'b'] }); // Atomic replacement.
  fs.closeSync(oldFd);
  assert.deepEqual(JSON.parse(fs.readFileSync(pinPath)), { pins: [unusual] });
  assert.equal(fs.existsSync(path.join(temp, 'sentinel')), false);
  ok('--write', '{"pins":[]}');
  assert.deepEqual(ok('--read'), { pins: [] }); // Empty pins do not migrate again.
  assert.deepEqual(ok('--write', JSON.stringify({ pins: mixed })), { pins: mixed });
  assert.deepEqual(ok('--read'), { pins: mixed });
  for (const pins of invalidPins) {
    assert.notEqual(run('--write', JSON.stringify({ pins })).status, 0);
    assert.deepEqual(ok('--read'), { pins: mixed });
  }
  for (const data of ['{"pins":[1]}', '{"pins":[{}]}', '{"pins":"a"}', '{"pins":[],"path":"x"}'])
    assert.notEqual(run('--write', data).status, 0);
  assert.notEqual(run('--read', pinPath).status, 0);
  fs.writeFileSync(pinPath, 'broken');
  assert.notEqual(run('--read').status, 0);
  assert.equal(fs.readFileSync(pinPath, 'utf8'), 'broken');
  fs.unlinkSync(pinPath);
  fs.symlinkSync(shellPath, pinPath);
  assert.notEqual(run('--read').status, 0);
  assert.notEqual(run('--write', '{"pins":[]}').status, 0);
  assert.equal(fs.readFileSync(shellPath, 'utf8'), '{"bar":{"dockPinned":"different"}}');
  fs.unlinkSync(pinPath);
  fs.symlinkSync(path.join(dir, 'missing'), pinPath);
  assert.notEqual(run('--write', '{"pins":[]}').status, 0);
  fs.unlinkSync(pinPath);
  const lockPath = path.join(dir, '.familiar-dock.lock');
  fs.unlinkSync(lockPath);
  fs.symlinkSync(shellPath, lockPath);
  assert.notEqual(run('--read').status, 0);
  assert.notEqual(run('--write', JSON.stringify({ pins: mixed })).status, 0);
  fs.unlinkSync(lockPath);
  fs.renameSync(dir, dir + '-real');
  fs.symlinkSync(dir + '-real', dir);
  assert.notEqual(run('--read').status, 0);
  assert.notEqual(run('--write', JSON.stringify({ pins: mixed })).status, 0);
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
const dockHost = read('ui/dock/DockHost.qml');
assert.match(dockHost, /WlrLayershell.layer: host.autohide \? WlrLayer.Overlay : WlrLayer.Top/);
assert.match(dockHost, /visible: dockShown/); // Unmapped dock cannot intercept fullscreen clicks.
assert.match(dockHost, /namespace: "familiar-dock-edge"/);
assert.match(dockHost, /visible: host.autohide/);
assert.match(dockHost, /onHoveredChanged: if \(hovered\) dockWindow.autoHidden = false/);
assert.equal((dockHost.match(/PanelWindow \{/g) || []).length, 2);
assert.doesNotMatch(dockHost, /screen\.(width|height)|revealStrip/);
const edge = dockHost.slice(dockHost.indexOf('id: edgeWindow'));
assert.match(edge, /exclusiveZone: 0/);
assert.match(edge, /exclusionMode: ExclusionMode.Ignore/);
assert.match(edge, /implicitWidth: host.position === "bottom" \? dockWindow.implicitWidth : 2/);
assert.match(edge, /implicitHeight: host.position === "bottom" \? 2 : dockWindow.implicitHeight/);
// Execute the actual preview/drop functions against stable slots.
const surface = vm.createContext({ DockPins, pinned: ['a', 'b', 'c'], pinnedEntries: ['a', 'b', 'c'].map(pinId => ({ pinId, pinned: true })),
  height: 80, width: 240, cellWidth: 60, cellHeight: 60, folderOpen: false, openFolderId: '',
  folderPopup: { mapFromItem: (_, x, y) => ({ x, y }) },
  pinnedRail: { width: 180, mapFromItem: (_, x, y) => ({ x, y }) },
  pinnedRepeater: { count: 3, itemAt(i) { return { entry: surface.pinnedEntries[i], x: i * 60, width: 57 }; } }, rebuild() {},
  service: { persistPinned(list) { surface.saved = plain(list); } } });
surface.root = surface;
functions('ui/dock/DockSurface.qml', ['normalize', 'entryKey', 'beginDrag', 'updateDrag', 'railSlot', 'finishDrag', 'cancelDrag'], surface);
surface.beginDrag(surface.pinnedEntries[0]);
surface.updateDrag(surface.pinnedEntries[0], { x: 170, y: 30 });
assert.equal(surface.dragPlan.kind, 'rail');
assert.deepEqual(plain(surface.railKeys), ['app:b', 'app:c', 'app:a']);
assert.equal(surface.railSlot(surface.pinnedEntries[1], 1), 0); // Gap opens before drop.
assert.equal(surface.saved, undefined);
surface.finishDrag(surface.pinnedEntries[0], { x: 170, y: 30 });
assert.deepEqual(surface.saved, ['b', 'c', 'a']);
surface.beginDrag(surface.pinnedEntries[0]);
surface.finishDrag(surface.pinnedEntries[0], { x: 90, y: 30 });
assert.equal(surface.saved[0].type, 'folder');
assert.deepEqual(surface.saved[0].items, ['b', 'a']);
surface.saved = null;
surface.beginDrag(surface.pinnedEntries[0]);
surface.finishDrag(surface.pinnedEntries[0], { x: 90, y: -100 });
assert.equal(surface.saved, null); // Off-dock releases cancel.
// Folder pointer routing previews a second grid row, then extracts onto the rail.
surface.pinned = ['a', { ...folder, items: ['b', 'c', 'd', 'e', 'f', 'g'] }, 'z'];
surface.pinnedEntries = [{ pinId: 'a', pinned: true }, { ...folder, pinned: true }, { pinId: 'z', pinned: true }];
surface.folderOpen = true;
surface.openFolderId = 'tools';
surface.folderEntries = ['b', 'c', 'd', 'e', 'f', 'g'].map(pinId => ({ pinId, folderId: 'tools', pinned: true }));
surface.folderPopup = { width: 264, height: 180, gridTop: 48, columns: 4, mapFromItem: (_, x, y) => ({ x, y: y + 200 }) };
const child = surface.folderEntries[0];
surface.beginDrag(child);
surface.updateDrag(child, { x: 12, y: -85 });
assert.equal(surface.dragPlan.kind, 'grid');
assert.equal(surface.dragPlan.index, 4);
const popupOrder = read('ui/dock/DockFolderPopup.qml').match(/readonly property var order: \{([^]*?)^  }/m)[1];
const gridContext = vm.createContext({ DockPins, dockSurface: surface });
vm.runInContext('var order = (function() {' + popupOrder + '})()', gridContext);
assert.deepEqual(plain(gridContext.order), ['c', 'd', 'e', 'f', 'b', 'g']);
surface.finishDrag(child, { x: 12, y: -85 });
assert.deepEqual(surface.saved[1].items, ['c', 'd', 'e', 'f', 'b', 'g']);
surface.beginDrag(child);
surface.updateDrag(child, { x: 180, y: 30 });
assert.equal(surface.dragPlan.kind, 'rail');
assert.deepEqual(plain(surface.railKeys), ['app:a', 'folder:tools', 'app:z', 'app:b']);
surface.finishDrag(child, { x: 180, y: 30 });
assert.deepEqual(surface.saved, ['a', { ...folder, items: ['c', 'd', 'e', 'f', 'g'] }, 'z', 'b']);
// Pin/unpin uses normalized original pin IDs, including WM-class pins.
const host = vm.createContext({ DockPins, host: { pinned: [' md.obsidian.Obsidian.desktop ', 'chrome-127.0.0.1__-Default'], service: { persistPinned(list) { host.saved = Array.from(list); } } }, dock: surface });
vm.runInContext('var pin = ' + read('ui/dock/DockHost.qml').match(/onPinRequested: (function\([^]*?^\s+})/m)[1], host);
host.pin('md.obsidian.Obsidian', true);
assert.deepEqual(host.saved, ['md.obsidian.Obsidian', 'chrome-127.0.0.1__-Default']);
host.pin(' md.obsidian.Obsidian.desktop ', false);
assert.deepEqual(host.saved, ['chrome-127.0.0.1__-Default']);
// PWA matching runs before browser heuristics, using the actual surface functions.
const matcher = vm.createContext({});
vm.runInContext(read('lib/PwaMatcher.js').replace(/^\.pragma library\s*/, ''), matcher);
for (const browser of ['chrome', 'chromium', 'brave', 'edge']) {
  assert.equal(matcher.parse(`${browser}-maps.google.com__-Default`).host, 'maps.google.com');
  assert.equal(matcher.parse(`${browser}-LOCALHOST:3000__-Profile 2.desktop`).host, 'localhost');
}
assert.equal(matcher.parse('chrome-127.0.0.1__-Default').host, '127.0.0.1');
assert.equal(matcher.parse('chrome-messages.google.com__web_conversations-Default').host, 'messages.google.com');
for (const id of ['google-chrome', 'chrome-maps.google.com', 'other-maps.google.com__-Default'])
  assert.equal(matcher.parse(id), null);
assert.deepEqual(Array.from(matcher.hosts('omarchy-launch-webapp "https://maps.google.com:443/path?q=1"')), ['maps.google.com']);
const maps = { id: 'Google Maps', name: 'Google Maps', icon: 'google-maps',
  execString: 'omarchy-launch-webapp https://maps.google.com' };
const browser = { id: 'google-chrome', name: 'Google Chrome', icon: 'google-chrome' };
const pwaId = 'chrome-maps.google.com__-Default';
assert.equal(matcher.matchEntry(pwaId, [browser, maps]), maps);
assert.equal(matcher.matchEntry(pwaId, [{ id: 'custom', name: 'Custom', icon: 'google-maps' }]).icon, 'google-maps');
assert.equal(matcher.matchEntry(pwaId, [{ id: 'Google Maps', name: 'Google Maps' }]).name, 'Google Maps');
assert.equal(matcher.matchEntry(pwaId, [{ ...maps, execString: 'app https://maps.google.com.evil.test' }]), null);
assert.equal(matcher.matchEntry(pwaId, [maps, { ...maps, id: 'duplicate' }]), null);
assert.equal(matcher.matchEntry('chrome-127.0.0.1__-Default', [maps, browser]), null);
const messages = { id: 'Google Messages', name: 'Google Messages', icon: 'google-messages',
  execString: 'omarchy-launch-webapp https://messages.google.com/web/conversations' };
assert.equal(matcher.matchEntry('chrome-messages.google.com__web_conversations-Default', [browser, messages]), messages);
const pwaSurface = vm.createContext({ draggingPinned: false, refreshFolder() {}, PwaMatcher: matcher, pinned: ['google-chrome', pwaId],
  running: [{ appId: 'google-chrome' }, { appId: pwaId }], showRunning: true,
  DesktopEntries: { applications: { values: [browser, maps] },
    byId(id) { return id === browser.id ? browser : null; }, heuristicLookup() { return browser; } } });
pwaSurface.root = pwaSurface;
functions('ui/dock/DockSurface.qml', ['normalize', 'desktopEntry', 'entryId', 'entryIcon', 'rebuild'], pwaSurface);
pwaSurface.rebuild();
assert.equal(pwaSurface.pinnedEntries.length, 2);
assert.equal(pwaSurface.pinnedEntries[0].windowCount, 1);
assert.equal(pwaSurface.pinnedEntries[1].icon, 'google-maps');
assert.equal(pwaSurface.pinnedEntries[1].windowCount, 1);
assert.equal(pwaSurface.pinnedEntries[1].pinId, pwaId);
pwaSurface.pinned = ['google-chrome'];
pwaSurface.rebuild();
assert.equal(pwaSurface.runningEntries[0].desktopId, 'Google Maps');
pwaSurface.DesktopEntries.applications.values = [browser];
pwaSurface.running.push({ appId: 'chrome-127.0.0.1__-Default' });
pwaSurface.rebuild();
assert.equal(pwaSurface.pinnedEntries[0].windowCount, 1);
assert.equal(pwaSurface.runningEntries.length, 2);
assert.equal(pwaSurface.runningEntries[0].desktopId, pwaId);
assert.equal(pwaSurface.runningEntries[1].icon, 'google-chrome');
for (const [prefix, browserId] of [['chromium', 'chromium'], ['brave', 'brave-browser'], ['edge', 'microsoft-edge']]) {
  const generic = { id: browserId, name: browserId, icon: browserId };
  pwaSurface.pinned = [browserId];
  pwaSurface.running = [{ appId: `${prefix}-maps.google.com__-Default` }];
  pwaSurface.DesktopEntries = { applications: { values: [generic, maps] },
    byId: id => id === browserId ? generic : null, heuristicLookup: () => generic };
  pwaSurface.rebuild();
  assert.equal(pwaSurface.pinnedEntries[0].windowCount, 0);
  assert.equal(pwaSurface.runningEntries[0].icon, 'google-maps');
}
// Folder children retain PWA matching and keep their windows out of the running rail.
pwaSurface.pinned = [{ type: 'folder', id: 'web', name: 'Web', items: [pwaId] }];
pwaSurface.running = [{ appId: pwaId }];
pwaSurface.DesktopEntries = { applications: { values: [browser, maps] }, byId() { return null; }, heuristicLookup() { return browser; } };
pwaSurface.rebuild();
assert.equal(pwaSurface.pinnedEntries[0].items[0].icon, 'google-maps');
assert.equal(pwaSurface.pinnedEntries[0].items[0].windowCount, 1);
assert.equal(pwaSurface.runningEntries.length, 0);
const iconContext = vm.createContext({ executableIcon: 'fallback',
  appLibrary: { iconSource() { throw Error('GTK icons must use Quickshell'); } },
  Quickshell: { iconPath: name => 'gtk:' + name }, Util: { fileUrl: file => 'file://' + file } });
functions('ui/dock/DockIcon.qml', ['iconSource'], iconContext);
assert.equal(iconContext.iconSource('google-maps'), 'gtk:google-maps');
assert.equal(iconContext.iconSource('/tmp/icon.png'), 'file:///tmp/icon.png');
assert.equal(iconContext.iconSource('image://icon/test'), 'image://icon/test');
// Exercise the shipped pointer handlers: click, threshold, drop, and non-pinned tiles.
let activations = 0;
let drops = 0;
let deferred;
const gesture = vm.createContext({ DockPins, holdTimer: { restart() {}, stop() {} }, pressed: true, pressedButtons: 1, reorderGesture: false,
  mapToItem: (_, x, y) => ({ x, y }), mapToGlobal: (x, y) => ({ x, y }),
  Qt: { LeftButton: 1, RightButton: 2, styleHints: { startDragDistance: 10 },
    callLater(fn) { deferred = fn; } },
  root: { pinned: true, editable: true, entry: { pinned: true }, dockSurface: { beginDrag() { this.draggingPinned = true; }, updateDrag() {} }, profileId: 'gnome',
    activated() { activations++; }, reorderDropped() { drops++; this.dockSurface.draggingPinned = false; } } });
gesture.iconMouse = gesture;
for (const name of ['Pressed', 'PositionChanged', 'Released', 'Clicked']) {
  vm.runInContext('var ' + name + ' = ' + read('ui/dock/DockIcon.qml').match(
    new RegExp('on' + name + ': (function\\([^]*?^    })', 'm'))[1], gesture);
}
const mouse = x => ({ x, y: 0, button: 1 });
gesture.Pressed(mouse(0));
gesture.PositionChanged(mouse(9));
gesture.Released(mouse(9));
gesture.Clicked(mouse(9));
assert.equal(activations, 1);
assert.equal(drops, 0);
gesture.Pressed(mouse(0));
gesture.PositionChanged(mouse(10));
assert.equal(gesture.root.dockSurface.draggingPinned, true);
gesture.Released(mouse(100));
gesture.Clicked(mouse(100));
assert.equal(activations, 1);
deferred();
assert.equal(drops, 1);
assert.equal(gesture.reorderGesture, false);
assert.equal(gesture.root.dockSurface.draggingPinned, false);
gesture.root.pinned = false;
gesture.Pressed(mouse(0));
gesture.PositionChanged(mouse(100));
assert.equal(gesture.reorderGesture, false);
// Long press enters edit mode and consumes click; moving first cancels it even after returning.
const holdBody = read('ui/dock/DockIcon.qml').match(/id: holdTimer[^]*?onTriggered: \{([^]*?)^    }/m)[1];
vm.runInContext('var Hold = function() {' + holdBody + '}', gesture);
gesture.root.pinned = true;
gesture.Pressed(mouse(0));
gesture.pressTime = Date.now() - 460;
gesture.Hold();
assert.equal(gesture.root.dockSurface.editMode, true);
gesture.Released(mouse(0));
gesture.Clicked(mouse(0));
assert.equal(activations, 1);
gesture.root.dockSurface.editMode = false;
gesture.Pressed(mouse(0));
gesture.PositionChanged(mouse(10));
gesture.PositionChanged(mouse(0));
gesture.pressTime = Date.now() - 460;
gesture.Hold();
assert.equal(gesture.root.dockSurface.editMode, false);
gesture.Released(mouse(0));
deferred();
// Ban direct implicit size assignments on every Loader, while permitting child sizing.
function scan(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) { scan(file); continue; }
    if (!file.endsWith('.qml')) continue;
    const source = fs.readFileSync(file, 'utf8').replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\/\/[^\n]*|\/\*[^]*?\*\//g, '');
    const tokens = source.match(/\bLoader\s*\{|[{}]|\bimplicit(?:Height|Width)\s*:/g) || [];
    const stack = [];
    for (const token of tokens) {
      if (token.endsWith('{')) stack.push(token.startsWith('Loader'));
      else if (token === '}') stack.pop();
      else assert.ok(!stack.at(-1), 'Loader implicit size assignment: ' + file);
    }
  }
}
scan(root);
console.log('Dock folders, merge/extract, rails, long-press/drag, PWA, persistence/symlinks, and Loader checks passed');
