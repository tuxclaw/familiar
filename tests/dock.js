const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
// Row only positions children horizontally; both non-pinned tiles need explicit centering.
const dockSurfaceQml = read('ui/dock/DockSurface.qml');
const runningTile = dockSurfaceQml.match(/model: root\.runningEntries\s+DockIcon \{([^]*?)^      }/m)?.[1];
const applicationsTile = dockSurfaceQml.match(/DockIcon \{\s+entry: root\.launcherEntry([^]*?)^    }/m)?.[1];
for (const [name, tile] of [['running', runningTile], ['Applications', applicationsTile]]) {
  assert.ok(tile, `${name} DockIcon exists`);
  assert.match(tile, /anchors\.verticalCenter: parent\.verticalCenter/, `${name} is centered in the Row`);
  assert.doesNotMatch(tile, /anchors\.(?:top|bottom|fill|centerIn):|\by:/, `${name} cannot override vertical centering`);
}
const iconImage = read('ui/dock/DockIcon.qml').match(/Image \{\s+id: icon([^]*?)^  }/m)[1];
assert.match(iconImage, /anchors\.bottom: parent\.bottom/);
assert.match(iconImage, /anchors\.bottomMargin: 12\s*\n/);
assert.doesNotMatch(iconImage, /anchors\.top:|showRunningIndicator/);
assert.match(applicationsTile, /showRunningIndicator: false/);
function functions(file, names, context) {
  for (const name of names)
    vm.runInContext(read(file).match(new RegExp('  function ' + name + '\\([^]*?^  }', 'm'))[0], context);
}
const DockPins = vm.createContext({});
vm.runInContext(read('lib/DockPins.js').replace(/^\.pragma library\s*/, ''), DockPins);
const dockDoc = pins => ({ pins, widgets: [], widgetSide: "right" });
const plain = value => JSON.parse(JSON.stringify(value));
const folder = { type: 'folder', id: 'tools', name: 'Tools', items: ['b', 'c'] };
const mixed = ['a', folder, 'd'];
assert.deepEqual(plain(DockPins.normalize(mixed)), mixed);
assert.deepEqual(plain(DockPins.merge(['a', 'b', 'd'], 'app:a', null, 'app:b', 'new')),
  [{ type: 'folder', id: 'new', name: 'Folder', items: ['b', 'a'] }, 'd']);
assert.deepEqual(plain(DockPins.merge(mixed, 'app:a', null, 'folder:tools', 'unused')),
  [{ ...folder, items: ['b', 'c', 'a'] }, 'd']);
assert.deepEqual(plain(DockPins.move(mixed, 'b', 'tools', 1)), ['a', 'b', 'c', 'd']);
assert.deepEqual(plain(DockPins.move([folder], 'b', 'tools', 1)), ['c', 'b']);
assert.deepEqual(plain(DockPins.move(mixed, 'b', 'tools', 3)), ['a', 'c', 'd', 'b']);
assert.deepEqual(plain(DockPins.merge(mixed, 'b', 'tools', 'app:d', 'new')),
  ['a', 'c', { type: 'folder', id: 'new', name: 'Folder', items: ['d', 'b'] }]);
const renamed = plain(DockPins.rename(mixed, 'tools', '  My tools  '));
assert.deepEqual(renamed, ['a', { ...folder, name: 'My tools' }, 'd']);
assert.equal(folder.name, 'Tools');
for (const name of ['', '   ', 'a/b', 'a\\b', 'a\n', 'a\x00b', 'a\x7fb', 'x'.repeat(65), '😀'.repeat(33), null])
  assert.throws(() => DockPins.rename(mixed, 'tools', name));
assert.equal(DockPins.rename(mixed, 'tools', '😀'.repeat(32))[1].name, '😀'.repeat(32));
const title = vm.createContext({ DockPins, text: '  My tools  ', root: { dockSurface: {
  pinned: mixed, openFolderId: 'tools', folderName: 'Tools',
  service: { persistPinned(pins) { title.saved = plain(pins); } }
} } });
const titleHandler = read('ui/dock/DockFolderPopup.qml').match(/onEditingFinished: \{([^]*?)^    }/m)[1];
vm.runInContext('var finish = function() {' + titleHandler + '}', title);
title.finish();
assert.deepEqual(title.saved, renamed);
assert.equal(title.text, 'My tools');
title.saved = null;
title.text = 'bad/name';
title.finish();
assert.equal(title.saved, null);
assert.equal(title.text, 'Tools');
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
const service = vm.createContext({ DockPins, storedPinned: [], pendingPinned: null, storedWidgets: [], widgetSide: "right", writingDock: null,
  pinnedPersistProcess: { running: false, stdinEnabled: true }, Qt: { resolvedUrl: () => path.join(root, 'lib/dock-pins.py') }, console });
functions('Service.qml', ['normalizePinned', 'persistPinned', 'flushPinned', 'ingestPinned', 'persistWidgets'], service);
service.root = service;
const started = read('Service.qml').match(/id: pinnedPersistProcess\s+stdinEnabled: true\s+onStarted: \{([^]*?)^    }/m)[1];
assert.doesNotMatch(read('Service.qml'), /\.stdinEnabled\s*=/);
vm.runInContext('var startWriter = function() {' + started + '}', service);
let writerRunning = false;
Object.defineProperty(service.pinnedPersistProcess, 'running', {
  get() { return writerRunning; },
  set(value) {
    writerRunning = value;
    if (!value) return;
    const proc = service.pinnedPersistProcess;
    assert.deepEqual(Array.from(proc.command), ['python3', path.join(root, 'lib/dock-pins.py'),
      service.writingDock === null ? '--read' : '--write']);
    assert.equal(proc.stdinEnabled, true);
    proc.input = '';
    service.startWriter();
    assert.equal(proc.stdinEnabled, true, 'stdin remains open after startup');
    if (service.writingDock !== null)
      assert.equal(proc.input, JSON.stringify(service.writingDock) + '\n');
  }
});
service.pinnedPersistProcess.write = function(data) {
  assert.equal(this.stdinEnabled, true);
  this.input += data;
};
service.flushPinned();
assert.equal(service.pinnedPersistProcess.input, '');
service.pinnedPersistProcess.running = false;
assert.equal(service.persistPinned([42]), 'refused');
assert.equal(service.persistPinned([], '/tmp/elsewhere'), 'refused');
assert.equal(service.persistPinned([' a.desktop ', 'a', 'b']), 'ok');
const command = Array.from(service.pinnedPersistProcess.command);
assert.deepEqual(JSON.parse(service.pinnedPersistProcess.input), dockDoc(['a', 'b']));
service.persistPinned(['later.desktop']);
assert.deepEqual(Array.from(service.pendingPinned.pins), ['later']);
assert.deepEqual(Array.from(service.pinnedPersistProcess.command), command);
service.pinnedPersistProcess.running = false;
service.flushPinned();
assert.deepEqual(JSON.parse(service.pinnedPersistProcess.input), dockDoc(['later']));
service.persistPinned(mixed);
assert.deepEqual(plain(service.pendingPinned.pins), mixed);
for (const invalid of invalidPins) assert.equal(service.persistPinned(invalid), 'refused');
service.ingestPinned(JSON.stringify({ pins: mixed }));
assert.deepEqual(plain(service.storedPinned), mixed);
service.ingestPinned('{"pins":["a.desktop","b"]}');
assert.deepEqual(Array.from(service.storedPinned), ['a', 'b']);
const previous = service.storedPinned;
service.ingestPinned('{"pins":["changed"]}');
assert.notEqual(service.storedPinned, previous);
assert.doesNotMatch(read('Service.qml'), /config\.bar\.dockPinned\s*=/);
// Execute the allowlist/document validators and registry selection contract.
const allowedWidgets = ['omarchy.weather', 'omarchy.audio', 'omarchy.microphone', 'omarchy.bluetooth',
  'omarchy.network', 'omarchy.power', 'omarchy.clock', 'omarchy.monitor', 'omarchy.tailscale'];
assert.deepEqual(plain(DockPins.widgetIds), allowedWidgets);
const widgetDoc = { pins: mixed, widgets: allowedWidgets, widgetSide: 'left' };
assert.deepEqual(plain(DockPins.document(widgetDoc)), widgetDoc);
assert.deepEqual(plain(DockPins.document({ pins: mixed })), dockDoc(mixed));
const sequence = values => Object.assign({ length: values.length }, values);
assert.deepEqual(plain(DockPins.document({ pins: sequence(mixed), widgets: sequence(allowedWidgets), widgetSide: 'left' })), widgetDoc);
for (const invalid of [null, undefined, 'abc', {}, { length: -1 }, { length: 1.5 }, { length: Infinity }, { length: 1 }]) {
  assert.throws(() => DockPins.document({ ...widgetDoc, pins: invalid }));
  assert.throws(() => DockPins.document({ ...widgetDoc, widgets: invalid }));
}
const invalidDocs = [
  { ...widgetDoc, widgets: ['omarchy.unknown'] }, { ...widgetDoc, widgets: ['../omarchy.audio'] },
  { ...widgetDoc, widgets: [42] }, { ...widgetDoc, widgets: [{}] }, { ...widgetDoc, widgets: 'omarchy.audio' },
  { ...widgetDoc, widgetSide: 'top' }, { ...widgetDoc, widgetSide: null },
  { ...widgetDoc, path: '/tmp/elsewhere' }, { ...widgetDoc, extra: true },
  { pins: [], widgets: [] }, { pins: [], widgetSide: 'left' }
];
for (const data of invalidDocs) assert.throws(() => DockPins.document(data));
service.pinnedPersistProcess.running = false;
service.pendingPinned = null;
service.writingDock = null;
service.persistWidgets(['omarchy.audio'], 'left');
assert.deepEqual(JSON.parse(service.pinnedPersistProcess.input),
  { pins: ['changed'], widgets: ['omarchy.audio'], widgetSide: 'left' });
service.persistPinned(mixed);
service.persistWidgets(allowedWidgets, 'right');
assert.deepEqual(plain(service.pendingPinned), { pins: mixed, widgets: allowedWidgets, widgetSide: 'right' });
for (const data of invalidDocs.slice(0, 7)) assert.equal(service.persistWidgets(data.widgets, data.widgetSide), 'refused');
assert.equal(service.persistWidgets([], 'left', '/tmp/elsewhere'), 'refused');
service.ingestPinned(JSON.stringify(widgetDoc));
assert.deepEqual(plain(service.storedWidgets), allowedWidgets);
assert.equal(service.widgetSide, 'left');
const storedBefore = JSON.stringify([service.storedPinned, service.storedWidgets, service.widgetSide]);
const originalConsole = service.console;
service.console = { warn() {} };
for (const data of invalidDocs) service.ingestPinned(JSON.stringify(data));
assert.equal(JSON.stringify([service.storedPinned, service.storedWidgets, service.widgetSide]), storedBefore);
service.console = originalConsole;
const hosted = vm.createContext({ DockPins, bar: { barWidgetRegistry: { revision: 1,
  widgets: { 'omarchy.audio': { component: 'stock-component' } } },
  pluginRegistry: { installedPlugins: { 'omarchy.audio': { id: 'omarchy.audio' } },
    entryPointUrl(manifest, kind) { assert.equal(kind, 'barWidget'); return manifest.id + '/Widget.qml'; } },
  barConfig: { layout: { right: [{ id: 'omarchy.audio', example: true }] } } } });
functions('ui/dock/DockWidgetCluster.qml', ['widgetComponent', 'widgetUrl', 'widgetSettings'], hosted);
assert.equal(hosted.widgetComponent('omarchy.audio'), 'stock-component');
assert.equal(hosted.widgetUrl('omarchy.audio'), '');
assert.equal(hosted.widgetComponent('omarchy.unknown'), null);
for (const registry of [{}, { widgets: {} }, { widgets: { 'omarchy.audio': {} } },
  { widgets: { 'omarchy.audio': { component: null } } }]) {
  hosted.bar.barWidgetRegistry = registry;
  assert.equal(hosted.widgetUrl('omarchy.audio'), 'omarchy.audio/Widget.qml');
  assert.equal(hosted.widgetUrl('omarchy.unknown'), '');
}
hosted.bar.barWidgetRegistry = null;
assert.equal(hosted.widgetUrl('omarchy.audio'), 'omarchy.audio/Widget.qml');
assert.equal(hosted.widgetUrl('omarchy.unknown'), '');
assert.equal(hosted.widgetUrl('omarchy.clock'), '');
const settingsCopy = hosted.widgetSettings('omarchy.audio');
settingsCopy.example = false;
assert.equal(hosted.bar.barConfig.layout.right[0].example, true);
const facade = vm.createContext({ clickTargets: [], hostedStockItems: [], activePopout: null });
functions('ui/dock/DockWidgetBar.qml', ['registerHostedItem', 'unregisterHostedItem', 'registerClickTarget',
  'unregisterClickTarget', 'moduleTargetClickable', 'moduleClickTargetAt', 'pressModuleClickTarget',
  'requestPopout', 'releasePopout'], facade);
let stockPress = 0;
const target = { width: 30, height: 32, triggerPress(button) { stockPress = button; } };
facade.registerHostedItem(target);
facade.registerClickTarget(target);
assert.equal(facade.pressModuleClickTarget({ mapToItem: () => ({ x: 5, y: 5 }) }, 1, 5, 5), true);
assert.equal(stockPress, 1);
facade.unregisterClickTarget(target);
facade.unregisterHostedItem(target);
assert.equal(facade.clickTargets.length, 0);
assert.equal(facade.hostedStockItems.length, 0);
// Model a QML sequence with indexed access and no Array methods.
const pickerWarnings = [];
const picker = vm.createContext({ DockPins, service, console: { warn(message) { pickerWarnings.push(message); } } });
functions('ui/dock/DockWidgetPicker.qml', ['pick', 'save'], picker);
picker.root = picker;
picker.labels = ['Weather'];
picker.parent = { index: 0, modelData: { invalid: 'QML model role' } };
const widgetRows = read('ui/dock/DockWidgetPicker.qml').split('model: DockPins.widgetIds')[1].split('    Row {')[0];
assert.doesNotMatch(widgetRows, /modelData/);
assert.match(widgetRows, /readonly property string widgetId: DockPins\.widgetIds\[index\]/);
assert.match(widgetRows, /root\.pick\(widgetId\)/);
picker.index = 0;
picker.widgetId = vm.runInContext(widgetRows.match(/readonly property string widgetId: ([^\n]*)/)[1], picker);
const pickerClick = widgetRows.match(/onClicked: ([^\n]*?) }/)[1];
const pickerCheckmark = widgetRows.match(/text: ([^\n]*)/)[1];
service.pendingPinned = null;
service.writingDock = null;
service.pinnedPersistProcess.running = false;
service.storedPinned = sequence(mixed);
service.storedWidgets = [];
assert.equal(vm.runInContext(pickerCheckmark, picker), '+  Weather');
vm.runInContext(pickerClick, picker);
assert.deepEqual(JSON.parse(service.pinnedPersistProcess.input),
  { pins: mixed, widgets: ['omarchy.weather'], widgetSide: 'left' });
service.ingestPinned(service.pinnedPersistProcess.input);
assert.equal(vm.runInContext(pickerCheckmark, picker), '✓  Weather');
vm.runInContext(pickerClick, picker);
assert.deepEqual(plain(service.pendingPinned.widgets), []);
service.pendingPinned = null;
service.writingDock = null;
service.pinnedPersistProcess.running = false;
service.storedWidgets = { 0: 'omarchy.clock', length: 1 };
picker.pick('omarchy.audio');
assert.deepEqual(JSON.parse(service.pinnedPersistProcess.input),
  { pins: mixed, widgets: ['omarchy.clock', 'omarchy.audio'], widgetSide: 'left' });
picker.pick('omarchy.clock');
assert.deepEqual(plain(service.pendingPinned.widgets), ['omarchy.audio']);
picker.save({ 0: 'omarchy.audio', length: 1 }, 'right');
assert.equal(service.pendingPinned.widgetSide, 'right');
picker.pick('omarchy.unknown');
assert.equal(pickerWarnings.length, 1);
assert.match(pickerWarnings[0], /persistence refused/);
assert.deepEqual(plain(service.pendingPinned.widgets), ['omarchy.audio']);
const temp = fs.mkdtempSync(path.join(root, 'tests/.dock-test-'));
try {
  const dir = path.join(temp, '.config/omarchy');
  fs.mkdirSync(dir, { recursive: true });
  const shellPath = path.join(dir, 'shell.json');
  const pinPath = path.join(dir, 'familiar-dock.json');
  const legacy = JSON.stringify({ bar: { dockPinned: ' a.desktop,b,a ' }, extra: 42 });
  fs.writeFileSync(shellPath, legacy);
  const raw = (args, input = '') => {
    const result = spawnSync('python3', [path.join(root, 'lib/dock-pins.py'), ...args],
    { cwd: temp, env: { ...process.env, HOME: temp }, encoding: 'utf8', timeout: 5000, input });
    assert.ifError(result.error);
    return result;
  };
  const run = (operation, input = '') => raw([operation], input);
  const ok = (...args) => { const result = run(...args); assert.equal(result.status, 0, result.stderr); return JSON.parse(result.stdout); };
  assert.deepEqual(ok('--read'), dockDoc(['a', 'b']));
  assert.equal(fs.readFileSync(shellPath, 'utf8'), legacy);
  const beforeRefusal = fs.readFileSync(pinPath, 'utf8');
  for (const args of [[], ['--write', '{"pins":[]}'], ['--write', pinPath],
    ['--read', pinPath], [pinPath], ['{"pins":[]}'], ['--write', '--read']]) {
    const result = raw(args, '{"pins":[]}');
    assert.notEqual(result.status, 0, 'extra JSON/path arguments must be refused');
    assert.equal(result.stderr, 'Familiar dock pins: operation refused\n');
    assert.equal(fs.readFileSync(pinPath, 'utf8'), beforeRefusal);
  }
  const limit = 1024 * 1024;
  const emptyDoc = '{"pins":[]}';
  // Keep the child's pipe open until it exits: a newline must suffice without EOF.
  const lineDoc = { pins: ['a'], widgets: ['omarchy.weather'], widgetSide: 'left' };
  const openStdin = spawnSync('python3', ['-c', `
import subprocess, sys
child = subprocess.Popen([sys.executable, sys.argv[1], '--write'],
                         stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
try:
    child.stdin.write(sys.stdin.buffer.read())
    child.stdin.flush()
    child.wait(timeout=3)
    sys.stdout.buffer.write(child.stdout.read())
    sys.stderr.buffer.write(child.stderr.read())
    sys.exit(child.returncode)
finally:
    if child.poll() is None:
        child.kill()
        child.wait()
    child.stdin.close()
`, path.join(root, 'lib/dock-pins.py')],
    { cwd: temp, env: { ...process.env, HOME: temp }, encoding: 'utf8', timeout: 5000,
      input: JSON.stringify(lineDoc) + '\n' });
  assert.ifError(openStdin.error);
  assert.equal(openStdin.status, 0, openStdin.stderr);
  assert.deepEqual(JSON.parse(openStdin.stdout), lineDoc);
  assert.deepEqual(ok('--read'), lineDoc);
  assert.equal(fs.readFileSync(shellPath, 'utf8'), legacy);
  assert.deepEqual(ok('--write', emptyDoc + '\nignored second line'), dockDoc([]));
  assert.deepEqual(ok('--write', emptyDoc + ' '.repeat(limit - Buffer.byteLength(emptyDoc) - 1) + '\n'), dockDoc([]));
  assert.deepEqual(ok('--write', emptyDoc + ' '.repeat(limit - Buffer.byteLength(emptyDoc))), dockDoc([]));
  for (const input of [emptyDoc + ' '.repeat(limit - Buffer.byteLength(emptyDoc) + 1),
    emptyDoc + ' '.repeat(limit - Buffer.byteLength(emptyDoc)) + '\n',
    '', Buffer.from([0xff]), '{"private-folder-name":',
    JSON.stringify({ pins: [{ ...folder, name: 'private-folder-name\ud800' }] }),
    '['.repeat(2000)]) {
    const result = run('--write', input);
    assert.notEqual(result.status, 0);
    assert.equal(result.stderr, 'Familiar dock pins: operation refused\n');
    assert.deepEqual(ok('--read'), dockDoc([]));
  }
  ok('--write', JSON.stringify(dockDoc(['a', 'b'])));
  // Both plain arrays and QML-like sequences must reach the actual isolated writer.
  for (const widgets of [['omarchy.weather'], sequence(['omarchy.weather'])]) {
    service.pendingPinned = null;
    service.writingDock = null;
    service.pinnedPersistProcess.running = false;
    service.storedPinned = sequence(['a', 'b']);
    assert.equal(service.persistWidgets(widgets, 'left'), 'ok');
    const command = Array.from(service.pinnedPersistProcess.command);
    const result = spawnSync(command[0], command.slice(1),
      { cwd: temp, env: { ...process.env, HOME: temp }, encoding: 'utf8', timeout: 5000, input: service.pinnedPersistProcess.input });
    assert.equal(result.status, 0, result.stderr);
    service.ingestPinned(result.stdout);
    const expected = { pins: ['a', 'b'], widgets: ['omarchy.weather'], widgetSide: 'left' };
    assert.deepEqual(ok('--read'), expected);
    assert.deepEqual(JSON.parse(fs.readFileSync(pinPath, 'utf8')), expected);
    assert.deepEqual(plain(service.storedWidgets), ['omarchy.weather']);
    assert.equal(service.widgetSide, 'left');
    assert.equal(fs.readFileSync(shellPath, 'utf8'), legacy);
  }
  ok('--write', JSON.stringify(dockDoc(['a', 'b'])));
  // Execute the command emitted by persistWidgets, then ingest the writer response.
  service.pendingPinned = null;
  service.writingDock = null;
  service.pinnedPersistProcess.running = false;
  service.ingestPinned(JSON.stringify(ok('--read')));
  picker.pick('omarchy.audio');
  const writeCommand = Array.from(service.pinnedPersistProcess.command);
  assert.equal(writeCommand[2], '--write');
  const written = spawnSync(writeCommand[0], writeCommand.slice(1),
    { cwd: temp, env: { ...process.env, HOME: temp }, encoding: 'utf8', timeout: 5000, input: service.pinnedPersistProcess.input });
  assert.equal(written.status, 0, written.stderr);
  service.ingestPinned(written.stdout);
  const persisted = { pins: ['a', 'b'], widgets: ['omarchy.audio'], widgetSide: 'right' };
  assert.deepEqual(JSON.parse(fs.readFileSync(pinPath, 'utf8')), persisted);
  assert.deepEqual(ok('--read'), persisted);
  assert.deepEqual(plain(service.storedWidgets), ['omarchy.audio']);
  assert.equal(fs.readFileSync(shellPath, 'utf8'), legacy);
  ok('--write', JSON.stringify(dockDoc(['a', 'b'])));

  fs.writeFileSync(shellPath, '{"bar":{"dockPinned":"different"}}');
  assert.deepEqual(ok('--read'), dockDoc(['a', 'b']));
  for (const side of ['left', 'right']) {
    const data = { ...widgetDoc, widgetSide: side };
    assert.deepEqual(ok('--write', JSON.stringify(data)), data);
    assert.deepEqual(ok('--read'), data);
    for (const invalid of invalidDocs) {
      assert.notEqual(run('--write', JSON.stringify(invalid)).status, 0);
      assert.deepEqual(ok('--read'), data);
    }
  }
  ok('--write', JSON.stringify({ pins: ['a', 'b'] }));
  fs.writeFileSync(pinPath, JSON.stringify({ pins: mixed }));
  assert.deepEqual(ok('--read'), dockDoc(mixed));
  assert.deepEqual(JSON.parse(fs.readFileSync(pinPath)), dockDoc(mixed));
  ok('--write', JSON.stringify({ pins: ['a', 'b'] }));
  const unusual = 'app$(touch sentinel)`id`"';
  const oldFd = fs.openSync(pinPath, 'r');
  assert.deepEqual(ok('--write', JSON.stringify({ pins: [unusual] })), dockDoc([unusual]));
  assert.deepEqual(JSON.parse(fs.readFileSync(oldFd)), dockDoc(['a', 'b'])); // Atomic replacement.
  fs.closeSync(oldFd);
  assert.deepEqual(JSON.parse(fs.readFileSync(pinPath)), dockDoc([unusual]));
  assert.equal(fs.existsSync(path.join(temp, 'sentinel')), false);
  ok('--write', '{"pins":[]}');
  assert.deepEqual(ok('--read'), dockDoc([])); // Empty pins do not migrate again.
  assert.deepEqual(ok('--write', JSON.stringify({ pins: mixed })), dockDoc(mixed));
  assert.deepEqual(ok('--read'), dockDoc(mixed));
  assert.deepEqual(ok('--write', JSON.stringify({ pins: renamed })), dockDoc(renamed));
  assert.deepEqual(ok('--read'), dockDoc(renamed));
  ok('--write', JSON.stringify({ pins: mixed }));
  for (const pins of invalidPins) {
    assert.notEqual(run('--write', JSON.stringify({ pins })).status, 0);
    assert.deepEqual(ok('--read'), dockDoc(mixed));
  }
  for (const data of ['{"pins":[1]}', '{"pins":[{}]}', '{"pins":"a"}', '{"pins":[],"path":"x"}'])
    assert.notEqual(run('--write', data).status, 0);
  assert.notEqual(raw(['--read', pinPath]).status, 0);
  fs.writeFileSync(pinPath, 'broken');
  assert.notEqual(run('--read').status, 0);
  assert.equal(fs.readFileSync(pinPath, 'utf8'), 'broken');
  fs.unlinkSync(pinPath);
  fs.symlinkSync(shellPath, pinPath);
  assert.notEqual(run('--read').status, 0);
  assert.notEqual(run('--write', JSON.stringify(widgetDoc)).status, 0);
  assert.equal(fs.readFileSync(shellPath, 'utf8'), '{"bar":{"dockPinned":"different"}}');
  fs.unlinkSync(pinPath);
  fs.symlinkSync(path.join(dir, 'missing'), pinPath);
  assert.notEqual(run('--write', JSON.stringify(widgetDoc)).status, 0);
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
assert.equal((dockHost.match(/PanelWindow \{/g) || []).length, 3);
const dockWindowSource = dockHost.slice(dockHost.indexOf('id: dockWindow'), dockHost.indexOf('id: pickerWindow'));
const geometry = ['implicitWidth', 'implicitHeight'].map(name =>
  dockWindowSource.match(new RegExp('^        ' + name + ': (.*)$', 'm'))[1]);
for (const position of ['bottom', 'left', 'right']) {
  const context = vm.createContext({ host: { position },
    dock: { implicitWidth: 160, implicitHeight: 76, widgetPickerOpen: false, folderOpen: false } });
  const size = () => geometry.map(expression => vm.runInContext(expression, context));
  const compact = size();
  context.dock.widgetPickerOpen = true;
  context.dock.widgetPopupWidth = 230;
  context.dock.popupHeight = 400;
  assert.deepEqual(size(), compact);
  context.dock.folderOpen = true;
  context.dock.folderPopupWidth = 500;
  assert.deepEqual(size(), compact);
}
assert.match(dockWindowSource.match(/property bool hovered: (.*)/)[1], /dock\.widgetPickerOpen/);
const pickerWindow = dockHost.slice(dockHost.indexOf('id: pickerWindow'), dockHost.indexOf('id: edgeWindow'));
for (const contract of ['visible: host.enabled && dock.widgetPickerOpen', 'exclusiveZone: 0',
  'exclusionMode: ExclusionMode.Ignore', 'WlrLayershell.namespace: "familiar-dock-picker"',
  'WlrLayershell.layer: WlrLayer.Overlay', 'DockWidgetPicker {']) assert.ok(pickerWindow.includes(contract));
assert.doesNotMatch(read('ui/dock/DockSurface.qml'), /DockWidgetPicker \{|widgetPopupWidth|popupHeight/);
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
// Extracting a child of a two-app folder collapses it and closes its popup.
surface.pinned = [folder];
surface.pinnedEntries = [{ ...folder, pinned: true }];
surface.pinnedRepeater.count = 1;
surface.folderEntries = ['b', 'c'].map(pinId => ({ pinId, folderId: 'tools', pinned: true }));
surface.beginDrag(surface.folderEntries[0]);
surface.finishDrag(surface.folderEntries[0], { x: 180, y: 30 });
assert.deepEqual(surface.saved, ['c', 'b']);
assert.equal(surface.openFolderId, '');
// Pin/unpin uses normalized original pin IDs, including WM-class pins.
assert.deepEqual(plain(DockPins.toggle([' md.obsidian.Obsidian.desktop ', 'chrome-127.0.0.1__-Default'], 'md.obsidian.Obsidian', true)),
  ['md.obsidian.Obsidian', 'chrome-127.0.0.1__-Default']);
assert.deepEqual(plain(DockPins.toggle(['md.obsidian.Obsidian', 'chrome-127.0.0.1__-Default'], ' md.obsidian.Obsidian.desktop ', false)),
  ['chrome-127.0.0.1__-Default']);
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
// Applications remains available for editing an empty dock, without becoming pinnable.
gesture.root.contextMenuEnabled = false;
gesture.root.editable = false;
gesture.root.dockSurface.widgetPickerOpen = false;
gesture.Pressed(mouse(0));
gesture.pressTime = Date.now() - 460;
gesture.Hold();
assert.equal(gesture.root.dockSurface.widgetPickerOpen, true);
gesture.Released(mouse(0));
gesture.Clicked(mouse(0));
assert.equal(activations, 1);
// Stock inline preferences stay local, while stock panel summons retain the shell route.
const shellFacadeSource = read('ui/dock/DockWidgetBar.qml');
assert.doesNotMatch(shellFacadeSource, /hostShell\.updateEntryInline/);
assert.doesNotMatch(read('ui/dock/DockWidgetCluster.qml'), /shellConfigMutator|updateEntryInline/);
assert.match(read('ui/dock/DockHost.qml'), /dockWidgetBar\.activePopout !== null/);
assert.match(read('ui/dock/DockSurface.qml'), /root\.widgetsLeft \? root\.widgetWidth : 0/);
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
console.log('Dock widgets/allowlist/hosting, folders, merge/extract, rails, long-press/drag, PWA, persistence/symlinks, and Loader checks passed');
