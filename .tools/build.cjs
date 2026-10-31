const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),cp=require('node:child_process');
const root=path.resolve(__dirname,'..'),out=path.join(root,'.build/fps-release');
fs.mkdirSync(out,{recursive:true});
const runtime=['colors.lua','config.lua','game.lua','gun.lua','level.lua','main.lua'];
const entries=[];
for(const file of runtime) {
  const code=fs.readFileSync(path.join(root,file),'utf8').replace(/\r\n/g,'\n');
  fs.writeFileSync(path.join(out,file),code);
  entries.push({file,metadata:{type:'lua_code'}});
}
const result=cp.spawnSync(process.env.LUPI_PYTHON||'python',[path.join(__dirname,'build-images.py'),out],{encoding:'utf8'});
if(result.status!==0) throw new Error(result.stderr||'Python with Pillow is required; set LUPI_PYTHON to its executable');
process.stdout.write(result.stdout);
entries.push(...JSON.parse(fs.readFileSync(path.join(out,'image-metadata.json'),'utf8')));
fs.unlinkSync(path.join(out,'image-metadata.json'));
let manifest='';
const cursorBase=Math.floor(Date.now()/1000)*10000;
const files=entries.map((entry,i)=>{
  const data=fs.readFileSync(path.join(out,entry.file));
  manifest+=`${cursorBase+i} ${data.length} ${entry.file} ${JSON.stringify(entry.metadata)}\n`;
  return {...entry,bytes:data.length,sha256:crypto.createHash('sha256').update(data).digest('hex')};
});
fs.writeFileSync(path.join(out,'lupi_manifest.txt'),manifest);
const totalBytes=files.reduce((sum,f)=>sum+f.bytes,Buffer.byteLength(manifest));
fs.writeFileSync(path.join(root,'BUILD.json'),JSON.stringify({project:'Lupi FPS 1.1',files,totalBytes},null,2)+'\n');
console.log('FPS release ready:',out,totalBytes,'bytes');
