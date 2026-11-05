const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path');
const b=fs.readFileSync(path.join(__dirname,'../icon.gif'));
assert.equal(b.toString('ascii',0,6),'GIF89a');
assert.equal(b.readUInt16LE(6),64);assert.equal(b.readUInt16LE(8),32);
assert.equal(b[10],0x83,'Expected 16-entry global palette matching Trumpsrun');
let p=13+48,frames=0,controls=0,loop=false;
function blocks(){const chunks=[];while(b[p]){const n=b[p++];chunks.push(b.subarray(p,p+n));p+=n;assert(p<b.length);}p++;return Buffer.concat(chunks);}
while(p<b.length){const tag=b[p++];if(tag===0x3b)break;
 if(tag===0x21){const kind=b[p++],data=blocks();if(kind===0xf9){assert.equal(data[0],4,'Expected keep-frame disposal without transparency');assert.equal(data.readUInt16LE(1),12);controls++;}if(kind===0xff&&data.toString('ascii',0,11)==='NETSCAPE2.0'){assert.equal(data.readUInt16LE(12),0);loop=true;}}
 else if(tag===0x2c){const packed=b[p+8];p+=9;if(packed&128)p+=3*(2**((packed&7)+1));p++;blocks();frames++;}
 else assert.fail('Unexpected GIF block '+tag);
}
assert.equal(frames,16);assert.equal(controls,16);assert(loop);
console.log('PASS: catalog GIF 64x32, 16 colors, 16 frames, 120ms, infinite loop, no transparency');
