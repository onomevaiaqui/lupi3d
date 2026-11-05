// Normalize FFmpeg GIF output for the catalog's known working GIF layout.
const fs=require('node:fs'),assert=require('node:assert/strict');
const b=fs.readFileSync(process.argv[2]);let p=13;
assert.equal(b.toString('ascii',0,6),'GIF89a');
assert(b[10]&128);const global=b.subarray(p,p+3*2**((b[10]&7)+1));p+=global.length;
const frames=[];let loop;
function blocks(){let start=p;while(b[p]){p+=b[p]+1;assert(p<b.length);}p++;return b.subarray(start,p);}
while(p<b.length){const tag=b[p++];if(tag===59)break;
 if(tag===33){const type=b[p++],data=blocks();if(type===255)loop=Buffer.concat([Buffer.from([33,type]),data]);}
 else {assert.equal(tag,44);const descriptor=Buffer.from(b.subarray(p,p+9));p+=9;let palette=global;if(descriptor[8]&128){const n=3*2**((descriptor[8]&7)+1);palette=b.subarray(p,p+n);p+=n;}assert.equal(b[p],8,'Require 8-bit LZW code size');const min=b[p++],data=blocks();frames.push({descriptor,palette:palette.subarray(0,48),min,data});}
}
const header=Buffer.from(b.subarray(0,13));header[10]=0x83;header[11]=0;header[12]=0;
const out=[header,frames[0].palette,loop];
frames.forEach((f,i)=>{out.push(Buffer.from([33,249,4,4,12,0,0,0]),Buffer.from([44]));f.descriptor[8]=i?0x83:0;out.push(f.descriptor);if(i)out.push(f.palette);out.push(Buffer.from([f.min]),f.data);});out.push(Buffer.from([59]));
fs.writeFileSync(process.argv[3],Buffer.concat(out));
console.log('Catalog GIF encoded:',frames.length,'frames, LZW 8,',Buffer.concat(out).length,'bytes');
