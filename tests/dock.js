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
const service = vm.createContext({ storedPinned: [], pendingPinned: null,
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
const surface = vm.createContext({ pinned: [' a.desktop ', 'b', 'c'], service: { persistPinned(list) { surface.saved = Array.from(list); } },
  pinnedRepeater: { count: 3, itemAt(i) { return { entry: { pinId: ['a', 'b', 'c'][i] }, width: 48, height: 60, mapToItem() { return { x: 30 + 60 * i }; } }; } } });
surface.root = surface;
functions('ui/dock/DockSurface.qml', ['normalize', 'reorderPinned'], surface);
surface.reorderPinned({ pinned: true, pinId: 'a.desktop' }, { x: 200 });
assert.deepEqual(surface.saved, ['b', 'c', 'a']);
surface.reorderPinned({ pinned: true, pinId: 'c' }, { x: 0 });
assert.deepEqual(surface.saved, ['c', 'a', 'b']);
surface.reorderPinned({ pinned: true, pinId: 'a' }, { x: 120 });
assert.deepEqual(surface.saved, ['b', 'a', 'c']);
surface.saved = null;
surface.reorderPinned({ pinned: false, desktopId: 'running' }, { x: 0 });
assert.equal(surface.saved, null);
// Pin/unpin uses normalized original pin IDs, including WM-class pins.
const host = vm.createContext({ host: { pinned: [' md.obsidian.Obsidian.desktop ', 'chrome-127.0.0.1__-Default'], service: { persistPinned(list) { host.saved = Array.from(list); } } }, dock: surface });
vm.runInContext('var pin = ' + read('ui/dock/DockHost.qml').match(/onPinRequested: (function\([^]*?^\s+})/m)[1], host);
host.pin('md.obsidian.Obsidian', true);
assert.deepEqual(host.saved, ['md.obsidian.Obsidian', 'chrome-127.0.0.1__-Default']);
host.pin(' md.obsidian.Obsidian.desktop ', false);
assert.deepEqual(host.saved, ['chrome-127.0.0.1__-Default']);
// Exercise the shipped pointer handlers: click, threshold, drop, and non-pinned tiles.
let activations = 0;
let drops = 0;
let deferred;
const gesture = vm.createContext({ pressed: true, pressedButtons: 1, reorderGesture: false,
  mapToItem: (_, x, y) => ({ x, y }),
  Qt: { LeftButton: 1, RightButton: 2, styleHints: { startDragDistance: 10 },
    callLater(fn) { deferred = fn; } },
  root: { pinned: true, entry: { pinned: true }, dockSurface: {}, profileId: 'gnome',
    activated() { activations++; }, reorderDropped() { drops++; } } });
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
console.log('Dock persistence, ordering, normalization, and Loader checks passed');
