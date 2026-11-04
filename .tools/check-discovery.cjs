const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),out=path.join(root,'.build/race-3d-release');
const required=['lupi.yaml','game.lua','main.lua','config.lua','colors.lua','track.lua','car.lua','geometry.lua','renderer.lua','race.lua','combat.lua','save.lua','audio.lua','scenery.lua'];
for(const file of required) assert(fs.existsSync(path.join(root,file)),'Missing '+file);
const yaml=fs.readFileSync(path.join(root,'lupi.yaml'),'utf8');
assert.match(yaml,/^public:\s*true\s*$/m);assert.match(yaml,/^version:\s*8\.4\s*$/m);
const info=JSON.parse(fs.readFileSync(path.join(root,'BUILD.json'),'utf8'));
const lines=fs.readFileSync(path.join(out,'lupi_manifest.txt'),'utf8').trim().split('\n');
assert.equal(lines.length,31);assert.equal(info.files.length,31);
for(const line of lines) {
 const m=line.match(/^(\d+) (\d+) (\S+) (.+)$/);assert(m,'Invalid manifest');
 const data=fs.readFileSync(path.join(out,m[3]));assert.equal(data.length,Number(m[2]));
 const record=info.files.find(f=>f.file===m[3]);assert(record);
 assert.equal(crypto.createHash('sha256').update(data).digest('hex'),record.sha256);
 if(m[3].endsWith('.lua')) assert.equal(JSON.parse(m[4]).type,'lua_code'); else {assert(m[3].endsWith('.fur'));assert.deepEqual(JSON.parse(m[4]),{});}
}
const main=fs.readFileSync(path.join(root,'main.lua'),'utf8');
assert(main.includes('renderer.submit'),'3D scene not submitted');
assert(!/wallDepth|columns|ui\.spr/.test(main),'2.5D rendering remains');
assert(fs.readFileSync(path.join(root,'renderer.lua'),'utf8').includes('ui.trisfill'),'Missing triangle rasterization');
console.log('PASS: root catalog metadata, genuine 3D modules, Lua and Furnace release, manifest sizes and hashes');
