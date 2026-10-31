// Regression check for the root layout expected by official Lupi projects.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const names=fs.readdirSync(root);
for(const f of ['lupi.yaml','game.lua','main.lua','models.lua','config.lua','colors.lua']) {
  assert(names.includes(f),'Missing root entry: '+f);
}
const yaml=fs.readFileSync(path.join(root,'lupi.yaml'),'utf8');
assert.match(yaml,/^public:\s*true\s*$/m);
assert.match(yaml,/^version:\s*0\.5\s*$/m);
const requires=names.filter(n=>n.endsWith('.lua'));
for(const f of requires) {
  const text=fs.readFileSync(path.join(root,f),'utf8');
  for(const m of text.matchAll(/require\s*[('" ]+["']?([a-z_]+)["']/g)) {
    assert(fs.existsSync(path.join(root,m[1]+'.lua')),'Unresolved module '+m[1]+' from '+f);
  }
}
// Mirror the codec's rule: dot-prefixed entries are skipped recursively.
function runtimeLua(dir) {
  return fs.readdirSync(dir).filter(n=>!n.startsWith('.')).flatMap(n=>{
    const p=path.join(dir,n);
    return fs.statSync(p).isDirectory()?runtimeLua(p):(n.endsWith('.lua')?[path.relative(root,p)]:[]);
  });
}
assert.deepEqual(runtimeLua(root).sort(),requires.sort(),'Nested Lua files leak into the codec input');
const manifest=fs.readFileSync(path.join(root,'.build/release/lupi_manifest.txt'),'utf8').trim().split('\n');
assert.equal(manifest.length,requires.length);
for(const line of manifest) {
  const m=line.match(/^(\d+) (\d+) (\S+) (.+)$/);assert(m,'Invalid manifest line');
  assert.equal(fs.statSync(path.join(root,'.build/release',m[3])).size,Number(m[2]));
  assert.equal(JSON.parse(m[4]).type,'lua_code');
}
console.log('PASS: public root metadata, root entry point, local modules, codec source discovery, release manifest sizes');
