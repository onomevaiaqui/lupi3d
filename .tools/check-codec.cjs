// Reproduce the official codec's ImageMagick color scan, including depth-5 rounding.
const cp=require('node:child_process'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'.build/fps-codec-check');
const palette=[0],seen=new Set([0]);
for(const name of ['img/gun.png','img/palette.png']) {
 const r=cp.spawnSync('magick',[path.join(root,name),'-background','white','-flatten','-unique-colors','-depth','5','txt:-'],{encoding:'utf8'});
 if(r.status!==0) throw new Error(r.stderr||'ImageMagick required for this optional SDK compatibility test');
 for(const m of r.stdout.matchAll(/\((\d+),(\d+),(\d+)/g)) {
  const color=(Number(m[3])>>3)*1024+(Number(m[2])>>3)*32+(Number(m[1])>>3);
  if(!seen.has(color)) {palette.push(color);seen.add(color);}
 }
}
fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,'palette.lua'),'Palette={'+palette.join(',')+'}\nreturn Palette\n');
const code=`package.path='.build/fps-codec-check/?.lua;./?.lua;'..package.path; ui={spr=function() end,btn=function() return false end,palset=function() end,camera=function() end,clip=function() end,cls=function() end,rectfill=function() end,print=function() end}; package.preload.sprites=function() Sprites={img={gun={width=72,height=96,path='img/gun'}}};return Sprites end; require('main');assert(Game.native_weapon and require('colors').native,'codec palette disabled native weapon');Game.draw();print('PASS: native sprite remains active with official depth-5 palette rounding (${palette.length} colors)')`;
const r=cp.spawnSync('lua',['-e',code],{cwd:root,encoding:'utf8'});
if(r.status!==0) throw new Error(r.stderr);process.stdout.write(r.stdout);
