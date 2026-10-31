const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),out=path.join(root,'.build/fps-release');
for(const file of ['lupi.yaml','game.lua','main.lua','config.lua','colors.lua','level.lua','gun.lua','img/gun.png','img/palette.png']) assert(fs.existsSync(path.join(root,file)),'Missing '+file);
const yaml=fs.readFileSync(path.join(root,'lupi.yaml'),'utf8');
assert.match(yaml,/^public:\s*true\s*$/m);assert.match(yaml,/^version:\s*1\.1\s*$/m);
const info=JSON.parse(fs.readFileSync(path.join(root,'BUILD.json'),'utf8'));
const lines=fs.readFileSync(path.join(out,'lupi_manifest.txt'),'utf8').trim().split('\n');
assert.equal(lines.length,info.files.length);
for(const line of lines) {
 const m=line.match(/^(\d+) (\d+) (\S+) (.+)$/);assert(m,'Invalid manifest');
 const data=fs.readFileSync(path.join(out,m[3]));assert.equal(data.length,Number(m[2]));
 const record=info.files.find(f=>f.file===m[3]);assert(record);
 assert.equal(crypto.createHash('sha256').update(data).digest('hex'),record.sha256);
 const meta=JSON.parse(m[4]);
 if(meta.type==='bitmap') assert.equal(data.length,meta.width*meta.height);
 assert(!/models|character_frames|platform/.test(m[3]),'Old 3D assets in FPS release');
}
assert.equal(fs.readFileSync(path.join(out,'img/gun')).length,72*96);
assert(!fs.readFileSync(path.join(root,'main.lua'),'utf8').includes('ui.trisfill'),'Native triangles in FPS renderer');
console.log('PASS: root catalog metadata, FPS entry point, native bitmap metadata/size, file hashes and isolated release');
