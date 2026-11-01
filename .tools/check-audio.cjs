const fs=require('node:fs'),path=require('node:path'),zlib=require('node:zlib'),cp=require('node:child_process'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),files=fs.readdirSync(path.join(root,'music')).filter(f=>f.endsWith('.fur'));
assert.equal(files.length,18);
const exe=process.env.FURNACE_EXE;
let minRms=1;
const out=path.join(root,'.build/audio-check');fs.mkdirSync(out,{recursive:true});
for(const name of files){
 const b=zlib.inflateSync(fs.readFileSync(path.join(root,'music',name)));
 assert.equal(b.subarray(0,16).toString(),'-Furnace module-');assert.equal(b.readUInt16LE(16),173);
 const ptr=b.readUInt32LE(20);assert.equal(b.subarray(ptr,ptr+4).toString(),'INFO');
 if(!exe)continue;
 const wav=path.join(out,name+'.wav');
 cp.execFileSync(exe,['-console','-noreport','-nostatus','-loglevel','error','-loops','0','-output',wav,path.join(root,'music',name)],{stdio:'pipe',timeout:15000,windowsHide:true});
 const w=fs.readFileSync(wav);let fmt,data;
 for(let p=12;p+8<=w.length;){const id=w.subarray(p,p+4).toString(),len=w.readUInt32LE(p+4);if(id==='fmt ')fmt=w.subarray(p+8,p+8+len);if(id==='data')data=w.subarray(p+8,p+8+len);p+=8+len+(len%2)}
 assert(fmt&&data,'WAV chunks missing');const bits=fmt.readUInt16LE(14),format=fmt.readUInt16LE(0);let sum=0,n=0;
 for(let i=0;i<data.length;i+=bits/8){let v;if(format===1&&bits===16)v=data.readInt16LE(i)/32768;else if(format===3&&bits===32)v=data.readFloatLE(i);else throw new Error('Unexpected WAV format');sum+=v*v;n++}
 const rms=Math.sqrt(sum/n);assert(rms>0.0001,name+' rendered silent');minRms=Math.min(minRms,rms);
}
console.log('PASS: '+files.length+' Furnace modules'+(exe?' independently decoded/rendered to non-silent PCM by Furnace; minimum RMS '+minRms.toFixed(4):' have valid compressed headers; set FURNACE_EXE for independent decode/render verification'));
