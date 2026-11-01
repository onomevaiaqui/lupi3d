// Convert the selected KayKit CC0 OBJ into genuine XYZ triangles (offline only).
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),v=[],faces=[];
for(const line of fs.readFileSync(path.join(root,'.assets-source/Rock_1_A_Color1.obj'),'utf8').split(/\r?\n/)) {
 const p=line.trim().split(/\s+/);
 if(p[0]==='v') v.push(...p.slice(1,4).map(n=>+Number(n*2).toFixed(5)));
 if(p[0]==='f') {
  const ids=p.slice(1).map(s=>Number(s.split('/')[0]));
  for(let i=1;i<ids.length-1;i++) {
   const tri=[ids[0],ids[i],ids[i+1]],pts=tri.map(id=>v.slice((id-1)*3,id*3));
   const a=pts[1].map((n,k)=>n-pts[0][k]),b=pts[2].map((n,k)=>n-pts[0][k]);
   const nx=a[1]*b[2]-a[2]*b[1],ny=a[2]*b[0]-a[0]*b[2],nz=a[0]*b[1]-a[1]*b[0];
   faces.push(...tri,(-nx*.4+ny*.8-nz*.45)/Math.hypot(nx,ny,nz)<.2?27:11);
  }
 }
}
fs.writeFileSync(path.join(root,'rock.lua'),'-- KayKit Forest Nature Pack / Kay Lousberg, CC0. See CREDITS.md.\nreturn {v={'+v.join(',')+'},f={'+faces.join(',')+'}}\n');
console.log('Imported rock:',v.length/3,'XYZ vertices,',faces.length/4,'triangles');
