const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const input = vm.createContext({});
vm.runInContext(read('lib/Input.js').replace('.pragma library', ''), input);
for (const raw of ['null', '[]', 'true', '42', '"launcher"', '', '{',
  '{"extra":1}', '{"__proto__":{}}', '{"query":{}}', '{"scope":[]}',
  '{"surface":null}', JSON.stringify({ query: 'a'.repeat(257) }),
  JSON.stringify({ scope: 'a'.repeat(33) })]) {
  assert.equal(input.parsePayload(raw).status, 'invalid', raw);
}
assert.equal(input.parsePayload('{"surface":"bad"}').status, 'unknown-surface');
assert.equal(input.parsePayload(undefined).payload.surface, 'launcher');
assert.equal(input.parsePayload(null).status, 'invalid');
const valid = { surface: 'switcher', query: 'a'.repeat(256), scope: 'window' };
assert.deepEqual(JSON.parse(JSON.stringify(input.parsePayload(JSON.stringify(valid)).payload)), valid);
vm.runInContext('JSON.parse = function() { throw new Error("must not parse oversized input") }', input);
for (const raw of [' '.repeat(4097), 'é'.repeat(2049), '😀'.repeat(1025)]) {
  assert.equal(input.parsePayload(raw).status, 'invalid');
}
// A throwing parser must never be called, including for multibyte input.
vm.runInContext('JSON.parse = function() { globalThis.parseCalled = true; return {} }', input);
for (const raw of [' '.repeat(4097), 'é'.repeat(2049), '😀'.repeat(1025)]) input.parsePayload(raw);
assert.equal(input.parseCalled, undefined);
const cleanInput = vm.createContext({});
vm.runInContext(read('lib/Input.js').replace('.pragma library', ''), cleanInput);
const overlay = read('Overlay.qml');
// The host supplies one IPC string; only blank input may reach the pathless service.
let reapplyCalls = 0;
const reapplyContext = vm.createContext({ service: {
  reapply() {
    assert.equal(arguments.length, 0);
    reapplyCalls++;
    return 'started';
  }
} });
vm.runInContext(overlay.match(/  function reapply\([^]*?^  }/m)[0], reapplyContext);
for (const args of [[], [''], [' \t\n']]) {
  const before = reapplyCalls;
  assert.equal(reapplyContext.reapply(...args), 'started');
  assert.equal(reapplyCalls, before + 1);
}
for (const args of [['/tmp/x'], ['gnome'], [' /tmp/x '], [undefined], [null],
  [0], [{}], ['', ''], ['', '/tmp/x']]) {
  const before = reapplyCalls;
  assert.equal(reapplyContext.reapply(...args), 'refused');
  assert.equal(reapplyCalls, before);
}
const context = vm.createContext({ Input: cleanInput, opened: false,
  closeDelay: { stop() {} }, switcher: { visible: true, advance(value) { context.received = value; } },
  launcher: { open(value) { context.received = value; } },
  Qt: { callLater() {} }, profile: {},
  close: () => { context.closed = true; return 'ok'; } });
context.root = context;
for (const name of ['open', 'toggle']) {
  vm.runInContext(overlay.match(new RegExp('  function ' + name + '\\([^]*?^  }', 'm'))[0], context);
  assert.equal(context[name]('{"query":null}'), 'invalid');
  assert.equal(context.received, undefined);
  assert.equal(context[name]('{"query":"hello"}'), 'ok');
  assert.deepEqual(JSON.parse(JSON.stringify(context.received)), { surface: 'launcher', query: 'hello' });
  assert.equal(context.payload, context.received);
  context.received = undefined;
}
context.opened = true;
assert.equal(context.open('{"surface":"switcher","scope":"window"}'), 'ok');
assert.deepEqual(JSON.parse(JSON.stringify(context.received)), { surface: 'switcher', scope: 'window' });
assert.equal(context.toggle('null'), 'invalid');
assert.equal(context.closed, undefined);
assert.equal(context.toggle('{}'), 'ok');
assert.equal(context.closed, true);
// Inherited-looking app IDs remain distinct entries during rebuild.
const windows = ['__proto__', 'constructor', 'toString', '__proto__'].map(appId => ({ appId }));
const switcher = vm.createContext({ ToplevelManager: { toplevels: { values: windows } }, scope: 'app' });
vm.runInContext(read('ui/switcher/SwitcherSurface.qml').match(/  function rebuild\([^]*?^  }/m)[0], switcher);
switcher.rebuild();
assert.equal(switcher.entries.length, 3);
const dock = vm.createContext({ running: windows, pinned: [], showRunning: true,
  normalize: value => value, desktopEntry: () => null, entryId: (_, fallback) => fallback });
dock.root = dock;
vm.runInContext(read('ui/dock/DockSurface.qml').match(/  function rebuild\([^]*?^  }/m)[0], dock);
dock.rebuild();
assert.equal(dock.runningEntries.length, 3);
assert.equal(dock.runningEntries[0].windowCount, 2);
assert.match(overlay, /switcher.advance\(sanitized\)/);
assert.match(overlay, /payload = sanitized/);
for (const file of ['ui/bar/ActiveAppLabel.qml', 'ui/bar/TaskButton.qml',
  'ui/overview/WindowThumb.qml', 'ui/switcher/SwitcherCell.qml',
  'ui/launcher/AppGridCell.qml', 'ui/launcher/ResultRow.qml']) {
  const sinks = read(file).split('\n').filter(line => line.includes('text:') && /(?:entry\.(?:name|description|title)|toplevel.title|activeToplevel \?)/.test(line));
  assert.ok(sinks.length, file);
  for (const line of sinks) {
    assert.match(line, /text: Input.boundedText\(/, file);
    assert.match(read(file), /textFormat: Text.PlainText/, file);
  }
}
assert.match(read('ui/dock/DockIcon.qml'), /PanelToolTip \{/);
assert.match(read('ui/dock/DockIcon.qml'), /text: Input.boundedText\(root.tooltipText\)/);
assert.equal(cleanInput.boundedText('<b>' + 'a'.repeat(1000)).length, 256);
assert.match(read('ui/launcher/SearchField.qml'), /maximumLength: 256/);
// Exercise the exact frecency command shipped in QML, in a disposable home.
const command = read('ui/launcher/LauncherSurface.qml').match(/persistProcess.command = \["bash", "-c", ("(?:[^"\\]|\\.)*"),/)[1];
const script = JSON.parse(command);
fs.mkdirSync(path.join(__dirname, 'out'), { recursive: true });
const temp = fs.mkdtempSync(path.join(__dirname, 'out/.frecency-test-'));
try {
  const state = path.join(temp, '.local/state/familiar');
  fs.mkdirSync(state, { recursive: true });
  const output = path.join(state, 'frecency.json');
  const sentinel = path.join(temp, 'sentinel');
  fs.writeFileSync(sentinel, 'unchanged');
  fs.symlinkSync(sentinel, output);
  const run = () => spawnSync('bash', ['-c', script, 'familiar-frecency', '{"app":1}'], { env: { ...process.env, HOME: temp } });
  assert.notEqual(run().status, 0);
  assert.equal(fs.readFileSync(sentinel, 'utf8'), 'unchanged');
  fs.unlinkSync(output);
  assert.equal(run().status, 0);
  assert.equal(fs.readFileSync(output, 'utf8'), '{"app":1}\n');
  assert.deepEqual(fs.readdirSync(state), ['frecency.json']);
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
console.log('Security regression tests passed');
