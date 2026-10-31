import json,sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent.parent
out=Path(sys.argv[1])
rgb=json.loads((root/'.tools/palette.json').read_text())
rgb += [[int(c*0.68) for c in color] for color in rgb[:16]]
def bgr(c): return (c[2]//8)*1024+(c[1]//8)*32+c[0]//8
palette=[bgr(c) for c in rgb]
lookup={}
for i,c in enumerate(palette): lookup.setdefault(c,i)
(out/'img').mkdir(parents=True,exist_ok=True)
im=Image.open(root/'img/gun.png').convert('RGBA')
assert im.size==(72,96)
data=bytes(0 if p[3]<128 else lookup[bgr(p)] for p in im.getdata())
(out/'img/gun').write_bytes(data)
with (out/'palette.lua').open('w',encoding='utf-8',newline='\n') as target:
    target.write('Palette={'+','.join(map(str,palette))+'}\nreturn Palette\n')
(out/'image-metadata.json').write_text(json.dumps([{'file':'img/gun','metadata':{'type':'bitmap','width':72,'height':96,'tiles':1}},{'file':'palette.lua','metadata':{'type':'lua_code'}}]))
print('Native gun bitmap: 6912 bytes, transparent index 0; shared indexed palette')
