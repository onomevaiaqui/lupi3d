const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),out=path.join(root,'.build/race-3d-release');
fs.mkdirSync(out,{recursive:true});
const runtime=['colors.lua','config.lua','game.lua','geometry.lua','car.lua','track.lua','main.lua','renderer.lua'];
const entries=[];
for(const file of runtime) {
  const code=fs.readFileSync(path.join(root,file),'utf8').replace(/\r\n/g,'\n');
  fs.writeFileSync(path.join(out,file),code);
  entries.push({file,metadata:{type:'lua_code'}});
}
let manifest='';
const cursorBase=Math.floor(Date.now()/1000)*10000;
const files=entries.map((entry,i)=>{
  const data=fs.readFileSync(path.join(out,entry.file));
  manifest+=`${cursorBase+i} ${data.length} ${entry.file} ${JSON.stringify(entry.metadata)}\n`;
  return {...entry,bytes:data.length,sha256:crypto.createHash('sha256').update(data).digest('hex')};
});
fs.writeFileSync(path.join(out,'lupi_manifest.txt'),manifest);
const totalBytes=files.reduce((sum,f)=>sum+f.bytes,Buffer.byteLength(manifest));
fs.writeFileSync(path.join(root,'BUILD.json'),JSON.stringify({project:'Lupi Oval 3D 2.1',files,totalBytes},null,2)+'\n');
console.log('3D race release ready:',out,totalBytes,'bytes');
