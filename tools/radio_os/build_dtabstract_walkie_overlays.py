#!/usr/bin/env python3
"""Build transparent PsychopatzCore Radio OS screen overlays (512x512 PNG).

Build-time only: requires Pillow; no PZ game dependencies. Coordinates are
locked to the existing DTA_Walkie_Manifest.lua overlay atlas declarations.
Overlay IDs named 'mask' are decorative edge frames, NOT GPU clipping masks.
"""
import argparse
import json
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SIZE = (512, 512)
SPRITES = [
    ('overlay_scanlines_green',16,16,160,160,'scanlines','green'),
    ('overlay_scanlines_amber',192,16,160,160,'scanlines','amber'),
    ('overlay_noise_light',16,192,160,160,'noise_light','grey'),
    ('overlay_noise_heavy',192,192,160,160,'noise_heavy','grey'),
    ('overlay_glare_soft',16,368,160,96,'glare','grey'),
    ('overlay_glow_green',192,368,160,96,'glow','green'),
    ('overlay_mask_square',368,16,128,128,'frame','green'),
    ('overlay_mask_wide',368,160,128,64,'frame','amber'),
]
COLORS = {
    'green':(133,190,132),
    'amber':(215,171,91),
    'grey':(188,205,197),
}

def bound(n): return max(0,min(255,round(n)))

def draw_tile(w,h,kind,theme):
    im=Image.new('RGBA',(w,h),(0,0,0,0))
    pix=im.load(); d=ImageDraw.Draw(im)
    rgb=COLORS[theme]
    rng=random.Random(7241+sum(ord(c) for c in kind+theme))
    if kind=='scanlines':
        for y in range(h):
            if y%3!=0: continue
            alpha=23 if y%6==0 else 15
            d.line((1,y,w-2,y),fill=(*rgb,alpha),width=1)
        for i in range(80):
            x=rng.randrange(2,w-2);y=rng.randrange(2,h-2)
            d.point((x,y),fill=(*rgb,rng.randrange(6,15)))
    elif kind in ('noise_light','noise_heavy'):
        heavy=kind=='noise_heavy'
        density=1750 if heavy else 450
        for i in range(density):
            x=rng.randrange(2,w-2);y=rng.randrange(2,h-2)
            shade=rng.choice(((213,224,211),(111,152,132),(188,189,168),(103,119,118)))
            a=rng.randrange(25,105) if heavy else rng.randrange(10,46)
            pix[x,y]=(*shade,a)
        if heavy:
            for _ in range(14):
                y=rng.randrange(2,h-2);x=rng.randrange(2,w-45)
                d.line((x,y,x+rng.randrange(8,46),y),fill=(175,208,181,rng.randrange(20,80)),width=1)
    elif kind=='glare':
        # Pale diagonal reflection without a solid background: peak alpha 29.
        for y in range(h):
            for x in range(w):
                distance=abs(x-(0.95*y+53))
                band=max(0.0,1.0-distance/21)
                head=max(0.0,1.0-abs(y-h*0.39)/(h*0.67))
                strength=(band**1.7)*head
                a=bound(29*strength)
                if a>0: pix[x,y]=(204,217,211,a)
    elif kind=='glow':
        # Gentle rim of green light, center completely transparent for portrait.
        for y in range(h):
            for x in range(w):
                dist=min(x,y,w-1-x,h-1-y)
                edge=max(0.,1.-dist/15.)
                alpha=bound(31*(edge**2))
                if alpha:pix[x,y]=(*rgb,alpha)
        d.rectangle((3,3,w-4,h-4),outline=(*rgb,23),width=1)
    elif kind=='frame':
        # Optional decorated screen corner/frame overlay, not a clipping mask.
        col=(*rgb,135)
        dark=(*rgb,54)
        d.rounded_rectangle((2,2,w-3,h-3),radius=4,outline=dark,width=1)
        tick=10 if h>=100 else 8
        for x,sx in ((5,1),(w-6,-1)):
            for y,sy in ((5,1),(h-6,-1)):
                d.line((x,y,x+sx*tick,y),fill=col,width=2)
                d.line((x,y,x,y+sy*tick),fill=col,width=2)
                d.point((x+sx*2,y+sy*2),fill=(*rgb,220))
        # subtle edge marks, no center pixels
        for x in range(22,w-21,13):
            d.point((x,3),fill=(*rgb,62))
            d.point((x,h-4),fill=(*rgb,62))
    else: raise ValueError(kind)
    return im


def build():
    atlas=Image.new('RGBA',SIZE,(0,0,0,0))
    meta={}
    for name,x,y,w,h,kind,theme in SPRITES:
        tile=draw_tile(w,h,kind,theme)
        atlas.alpha_composite(tile,(x,y))
        meta[name]={'sheet':'overlays','rect':{'x':x,'y':y,'w':w,'h':h}}
    return atlas,meta


def validate(atlas,meta):
    assert atlas.mode=='RGBA' and atlas.size==SIZE
    assert len(meta)==len(SPRITES)==8 and len(set(meta))==8
    positions=[]
    for name,x,y,w,h,kind,theme in SPRITES:
        assert x>=0 and y>=0 and x+w<=SIZE[0] and y+h<=SIZE[1],name
        crop=atlas.crop((x,y,x+w,y+h))
        a=crop.getchannel('A')
        assert a.getbbox() is not None,name
        for old,ox,oy,ox1,oy1 in positions:
            assert x>=ox1 or ox>=x+w or y>=oy1 or oy>=y+h,(name,old)
        positions.append((name,x,y,x+w,y+h))
        # Screen overlays must not erase readable content or create an opaque tile.
        max_alpha=max(a.getdata())
        if kind in ('scanlines','noise_light','noise_heavy','glare','glow'):
            assert max_alpha<=115,(name,max_alpha)
        if kind=='frame':
            assert crop.getpixel((w//2,h//2))[3]==0,name
        if kind=='glow': assert crop.getpixel((w//2,h//2))[3]==0,name
        if kind=='glare': assert max_alpha<=29,name
    assert atlas.getpixel((0,0))[3]==0
    assert atlas.crop((0,480,512,512)).getchannel('A').getbbox() is None
    assert atlas.crop((368,232,512,512)).getchannel('A').getbbox() is None
    assert atlas.getchannel('A').getbbox() is not None


def preview(atlas,path):
    view=Image.new('RGBA',SIZE,(13,28,22,255))
    draw=ImageDraw.Draw(view)
    # Blank, muted LCD background for each tile to demonstrate subtle opacity.
    for idx,(name,x,y,w,h,kind,theme) in enumerate(SPRITES):
        base=(21,48,33,255) if theme=='green' else (57,43,21,255) if theme=='amber' else (33,37,35,255)
        draw.rectangle((x,y,x+w-1,y+h-1),fill=base)
        # Sample radio OS content to visually check readability under overlays.
        if kind in ('scanlines','noise_light','noise_heavy','glare','glow'):
            draw.line((x+14,y+20,x+w-15,y+20),fill=(116,145,112,255),width=2)
            for j in range(3):
                yy=y+32+j*14
                if yy<y+h-7:draw.line((x+14,yy,x+w-25-12*j,yy),fill=(81,116,89,255),width=2)
    view.alpha_composite(atlas)
    p=Path(path);p.parent.mkdir(parents=True,exist_ok=True)
    view.convert('RGB').save(p,optimize=True)


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--output',default='DTA_Walkie_Overlays.png')
    p.add_argument('--preview',default=None)
    p.add_argument('--map',default=None)
    args=p.parse_args()
    image,meta=build();validate(image,meta)
    target=Path(args.output);target.parent.mkdir(parents=True,exist_ok=True)
    image.save(target,optimize=True)
    assert Image.open(target).convert('RGBA').tobytes()==image.tobytes()
    if args.preview:preview(image,args.preview)
    if args.map:Path(args.map).write_text(json.dumps(meta,indent=2)+'\n')
    print('PASS: 8 alpha overlays; geometry, transparency, opacity caps, zero overlap, PNG round-trip')

if __name__=='__main__':main()
