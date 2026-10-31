"""Offline import of the free Rekkimaru FPS sprite into merged palette rectangles."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parent.parent
rgb=json.loads((root/'.tools/palette.json').read_text())
rgb+= [[int(c*0.68) for c in color] for color in rgb[:16]]
# Idle pistol frame only. Remove the uniform blue sheet background before sampling.
im=Image.open(root/'.assets-source/fps/PIST1.png').convert('RGBA').crop((30,24,106,123))
pixels=im.load()
for y in range(im.height):
    for x in range(im.width):
        r,g,b,a=pixels[x,y]
        if (r-91)**2+(g-110)**2+(b-225)**2<1600: pixels[x,y]=(0,0,0,0)
im=im.resize((24,32),Image.Resampling.NEAREST)
palette={i:rgb[i] for i in (26,10,11,12,13,14)}
grid=[]
for y in range(32):
    row=[]
    for x in range(24):
        p=im.getpixel((x,y))
        row.append(0 if p[3]<128 else min(palette,key=lambda i:sum((p[k]-palette[i][k])**2 for k in range(3))))
    grid.append(row)
native=Image.new('RGBA',(24,32))
for y in range(32):
    for x in range(24):
        c=grid[y][x]
        native.putpixel((x,y),(*rgb[c],255) if c else (0,0,0,0))
(root/'img').mkdir(exist_ok=True)
native.resize((72,96),Image.Resampling.NEAREST).save(root/'img/gun.png')
swatch=Image.new('RGB',(32,1));swatch.putdata([tuple(c) for c in rgb]);swatch.save(root/'img/palette.png')
rects=[]
for y in range(32):
    for x in range(24):
        c=grid[y][x]
        if c==0: continue
        w=1
        while x+w<24 and grid[y][x+w]==c: w+=1
        h=1
        while y+h<32 and all(grid[y+h][xx]==c for xx in range(x,x+w)): h+=1
        for yy in range(y,y+h):
            for xx in range(x,x+w): grid[yy][xx]=0
        rects.extend((x,y,w,h,c))
with (root/'gun.lua').open('w',encoding='utf-8',newline='\n') as out:
    out.write('-- Rekkimaru FPS Gun Sprites, permission and source in CREDITS.md.\nreturn {width=24,height=32,rects={'+','.join(map(str,rects))+'}}\n')
print(f'Gun: 24x32, 6 colors, {len(rects)//5} merged rectangles')
