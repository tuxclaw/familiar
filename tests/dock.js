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
const service = vm.createContext({ barConfig: { profile: 'macos' }, shell: null,
  pluginRegistry: null, pendingPinned: null, pinnedPersistProcess: { running: false }, console });
functions('Service.qml', ['normalizePinned', 'persistPinned', 'flushPinned'], service);
let shellCalls = 0;
let registryCalls = 0;
let config = {};
service.shell = { mutateShellConfig(fn) { shellCalls++; fn(config); } };
service.pluginRegistry = { shellConfigMutator(fn) { registryCalls++; fn(config); } };
const previous = service.barConfig;
assert.equal(service.persistPinned([' md.obsidian.Obsidian.desktop ', 'md.obsidian.Obsidian', 'chrome-127.0.0.1__-Default', '']), 'ok');
assert.equal(config.bar.dockPinned, 'md.obsidian.Obsidian,chrome-127.0.0.1__-Default');
assert.equal(service.barConfig.dockPinned, config.bar.dockPinned);
assert.notEqual(service.barConfig, previous);
assert.equal(service.barConfig.profile, 'macos');
assert.equal(shellCalls, 1);
assert.equal(registryCalls, 0);
service.shell = {};
assert.equal(service.persistPinned([]), 'ok');
assert.equal(config.bar.dockPinned, '');
assert.equal(registryCalls, 1);
service.pluginRegistry = {}; // Actual third-party registry: no mutator.
const unusual = 'app$(touch sentinel)`id`"';
assert.equal(service.persistPinned([unusual]), 'ok');
const command = Array.from(service.pinnedPersistProcess.command);
assert.equal(service.pinnedPersistProcess.running, true);
service.persistPinned(['later.desktop']);
assert.equal(service.pendingPinned, 'later');
assert.deepEqual(Array.from(service.pinnedPersistProcess.command), command);
service.pinnedPersistProcess.running = false;
service.flushPinned();
assert.equal(service.pinnedPersistProcess.command.at(-1), 'later');
// Execute the shipped fallback only in a disposable repo directory, with IPC stubbed.
const temp = fs.mkdtempSync(path.join(root, 'tests/.dock-test-'));
try {
  const dir = path.join(temp, '.config/omarchy');
  fs.mkdirSync(dir, { recursive: true });
  fs.mkdirSync(path.join(temp, 'bin'));
  fs.writeFileSync(path.join(temp, 'bin/omarchy-shell'), '#!/bin/sh\n[ "$1" = shell ] && [ "$2" = reloadConfig ] || exit 1\nprintf reloaded > "$HOME/reloaded"\n', { mode: 0o755 });
  fs.writeFileSync(path.join(dir, 'shell.json'), JSON.stringify({ bar: { profile: 'macos' }, extra: 42 }));
  const result = spawnSync(command[0], command.slice(1), { cwd: temp, env: { ...process.env, HOME: temp, PATH: path.join(temp, 'bin') + ':' + process.env.PATH } });
  assert.equal(result.status, 0, String(result.stderr));
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(dir, 'shell.json'))), { bar: { profile: 'macos', dockPinned: unusual }, extra: 42 });
  assert.equal(fs.readFileSync(path.join(temp, 'reloaded'), 'utf8'), 'reloaded');
  assert.equal(fs.existsSync(path.join(temp, 'sentinel')), false);
  assert.deepEqual(fs.readdirSync(dir), ['shell.json']);
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
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
vm.runInContext('var pin = ' + read('ui/dock/DockHost.qml').match(/onPinRequested: (function\([^]*?^          })/m)[1], host);
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
