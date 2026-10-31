// Deterministic Lua-only release: no textures, desktop renderer or source GLB.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),out=path.join(root,'.build/release');
fs.mkdirSync(out,{recursive:true});
const files=fs.readdirSync(root).filter(f=>f.endsWith('.lua')).sort();
for(const required of ['game.lua','main.lua','config.lua','colors.lua','models.lua','lupi.yaml']) {
  if(!fs.existsSync(path.join(root,required))) throw new Error('Missing root file: '+required);
}
let manifest='';
for(const [i,name] of files.entries()) {
  const data=fs.readFileSync(path.join(root,name));
  fs.writeFileSync(path.join(out,name),data);
  manifest+=`${17934048000000+i} ${data.length} ${name} {"type":"lua_code"}\n`;
}
fs.writeFileSync(path.join(out,'lupi_manifest.txt'),manifest);
const details=files.map(name=>{
  const b=fs.readFileSync(path.join(out,name));
  return {file:name,bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')};
});
fs.writeFileSync(path.join(root,'BUILD.json'),JSON.stringify({files:details,totalBytes:details.reduce((s,f)=>s+f.bytes,Buffer.byteLength(manifest))},null,2)+'\n');
console.log('Release ready:',out,details.reduce((s,f)=>s+f.bytes,Buffer.byteLength(manifest)),'bytes');
