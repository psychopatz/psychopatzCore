#!/usr/bin/env python3
"""Deterministically generate PsychopatzCore's 512x256 Walkie Indicators atlas.

Build-time only: uses Pillow. All states and captions are runtime decisions;
status chips contain *blank* faceplates, not English strings or NPC data.
Coordinates exactly match the current DTA_Walkie_Manifest.lua.
"""
import argparse
import json
import random
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = (512, 256)
TONE = {
    "green":  {"border": (70, 108, 75), "edge": (110, 155, 102), "light": (152, 199, 125), "dark": (14, 35, 24), "face": (25, 51, 33)},
    "amber":  {"border": (129, 94, 44), "edge": (171, 123, 57), "light": (225, 169, 75), "dark": (48, 34, 16), "face": (73, 50, 22)},
    "red":    {"border": (130, 64, 52), "edge": (169, 82, 67), "light": (225, 116, 97), "dark": (56, 24, 24), "face": (77, 33, 30)},
    "grey":   {"border": (77, 89, 89), "edge": (117, 129, 123), "light": (160, 176, 163), "dark": (21, 26, 27), "face": (38, 43, 43)},
}

RECTS = []
for theme, y in (("green", 16), ("amber", 40)):
    for level in range(5):
        RECTS.append((f"ind_signal_{theme}_{level}", 16 + level*56, y, 48, 16, "signal", theme, level))
for level in range(5):
    RECTS.append((f"ind_battery_green_{level}",16 + level*48,72,40,16,"battery","green",level))
for name, x, kind, theme in (("ind_rx",16,"rx","green"),
                             ("ind_tx",96,"tx","amber"),
                             ("ind_muted",176,"muted","grey"),
                             ("ind_offline",256,"offline","red")):
    RECTS.append((name,x,112,64,20,kind,theme,0))
for name, x, y, theme in (("standby",16,160,"grey"),
                          ("receiving",144,160,"green"),
                          ("transmitting",272,160,"amber"),
                          ("signal_lost",16,200,"red"),
                          ("offline",144,200,"grey"),
                          ("connecting",272,200,"amber")):
    RECTS.append(("chip_"+name,x,y,112,28,"chip",theme,0))


def rgba(c,a=255): return (*c,a)


def canvas(w,h):return Image.new("RGBA",(w,h),(0,0,0,0))


def plate(w,h,theme,seed,has_glow=False):
    c=TONE[theme]
    im=canvas(w,h);d=ImageDraw.Draw(im)
    d.rounded_rectangle((1,2,w-2,h-2),radius=4 if h>20 else 2,
                        fill=rgba((8,13,11),240),outline=rgba(c["border"],205))
    d.rounded_rectangle((3,3,w-4,h-4),radius=2,
                        fill=rgba(c["face"],235),outline=rgba(c["edge"],180))
    d.line([(6,4),(w-7,4)],fill=rgba(c["light"],190 if has_glow else 75))
    d.line([(6,h-5),(w-7,h-5)],fill=rgba(c["dark"],220),width=2)
    rng=random.Random(seed)
    for _ in range(max(2,round(w*h/410))):
        px=rng.randint(7,w-8)
        py=rng.choice((5,h-6))
        d.point((px,py),fill=rgba(c["edge"],rng.randint(35,105)))
    return im


def draw_signal(w,h,theme,level):
    im=canvas(w,h); d=ImageDraw.Draw(im);c=TONE[theme]
    # Four bars in increasing height. Unlit bars retain a low-contrast frame.
    for i in range(4):
        tall=(i+1)*2+2
        x=11+i*7
        y=h-4-tall
        active=i<level
        d.rectangle((x,y,x+4,h-4),fill=rgba(c["light"] if active else c["border"],255 if active else 80))
        if active:d.point((x,y),fill=rgba((231,232,190),155))
    return im


def draw_battery(w,h,level):
    im=canvas(w,h);d=ImageDraw.Draw(im);c=TONE["green"]
    d.rounded_rectangle((6,3,33,13),radius=2,outline=rgba(c["edge"]),width=2)
    d.rectangle((34,6,37,10),fill=rgba(c["edge"]))
    for i in range(4):
        x=10+i*5
        if i<level:d.rectangle((x,6,x+3,10),fill=rgba(c["light"]))
        else:d.rectangle((x,6,x+3,10),fill=rgba(c["border"],45))
    return im


def state_indicator(w,h,kind,theme):
    im=plate(w,h,theme,sum(map(ord,kind)))
    d=ImageDraw.Draw(im);c=TONE[theme];fg=rgba(c["light"])
    if kind=="rx":
        # Arrow into an antenna/radio receiver; no English letters baked in.
        d.line((13,10,29,10),fill=fg,width=3)
        d.polygon(((23,6),(23,14),(31,10)),fill=fg)
        d.rectangle((42,6,45,14),fill=fg)
        d.arc((38,3,49,18),80,280,fill=rgba(c["edge"]),width=2)
    elif kind=="tx":
        d.rectangle((13,6,16,14),fill=fg)
        d.arc((10,3,21,18),260,100,fill=rgba(c["edge"]),width=2)
        d.line((27,10,47,10),fill=fg,width=3)
        d.polygon(((40,6),(40,14),(48,10)),fill=fg)
    elif kind=="muted":
        d.polygon(((17,8),(23,8),(28,5),(28,16),(23,13),(17,13)),fill=fg)
        d.line((36,5,43,16),fill=rgba(c["light"]),width=3)
    elif kind=="offline":
        d.arc((22,2,45,18),200,340,fill=fg,width=3)
        d.line((20,5,44,16),fill=rgba(c["light"]),width=3)
    return im


def status_chip(w,h,theme,seed):
    im=plate(w,h,theme,seed,has_glow=True)
    d=ImageDraw.Draw(im);c=TONE[theme]
    # Icon-sized marker, leaving the bulk of the chip BLANK for localized text.
    d.rounded_rectangle((8,9,15,17),radius=1,fill=rgba(c["dark"]),outline=rgba(c["edge"]),width=1)
    d.point((11,12),fill=rgba(c["light"]))
    return im


def render():
    atlas=canvas(*SIZE)
    entries={}
    for index,(name,x,y,w,h,kind,theme,level) in enumerate(RECTS):
        sprite=(draw_signal(w,h,theme,level) if kind=="signal" else
                draw_battery(w,h,level) if kind=="battery" else
                status_chip(w,h,theme,100+index) if kind=="chip" else
                state_indicator(w,h,kind,theme))
        atlas.alpha_composite(sprite,(x,y))
        rect={"x":x,"y":y,"w":w,"h":h}
        entries[name]={"sheet":"indicators","rect":rect}
    return atlas,entries


def validate(atlas,entries):
    assert atlas.size==SIZE and atlas.mode=="RGBA"
    assert len(RECTS)==25 and len(entries)==25
    assert atlas.getpixel((0,0))[3]==0
    boxes=[]
    for name,entry in entries.items():
        r=entry["rect"];x,y,w,h=[r[k] for k in ("x","y","w","h")]
        assert 0<=x and 0<=y and x+w<=SIZE[0] and y+h<=SIZE[1],name
        a=atlas.crop((x,y,x+w,y+h)).getchannel("A")
        assert a.getbbox() is not None,name
        assert all(a.getpixel(pt)==0 for pt in ((0,0),(w-1,0),(0,h-1),(w-1,h-1))),name
        for other,xx,yy,xx1,yy1 in boxes:
            assert x>=xx1 or xx>=x+w or y>=yy1 or yy>=y+h,(name,other)
        boxes.append((name,x,y,x+w,y+h))
    for kind,theme in (("signal","green"),("signal","amber"),("battery","green")):
        bitmaps=[]
        for level in range(5):
            tag=f"ind_{kind}_{theme}_{level}"
            r=entries[tag]["rect"];x,y,w,h=[r[k] for k in ("x","y","w","h")]
            bitmaps.append(atlas.crop((x,y,x+w,y+h)).tobytes())
        assert len(set(bitmaps))==5,(kind,theme,"level art not distinct")
    # Reserved/unallocated zones must stay fully transparent.
    assert atlas.crop((400,0,512,256)).getchannel("A").getbbox() is None
    assert atlas.crop((0,236,512,256)).getchannel("A").getbbox() is None


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",default="DTA_Walkie_Indicators.png")
    p.add_argument("--preview",default=None)
    p.add_argument("--layout",default=None)
    args=p.parse_args()
    img,layout=render();validate(img,layout)
    out=Path(args.output);out.parent.mkdir(parents=True,exist_ok=True)
    img.save(out,optimize=True)
    reloaded=Image.open(out).convert("RGBA")
    assert reloaded.tobytes()==img.tobytes(),"PNG round-trip mismatch"
    if args.layout:Path(args.layout).write_text(json.dumps(layout,indent=2)+"\n")
    if args.preview:
        bg=Image.new("RGBA",SIZE,(24,29,26,255))
        bg.alpha_composite(img)
        bg.resize((1024,512),resample=Image.Resampling.NEAREST).convert("RGB").save(args.preview,optimize=True)
    print("PASS: 25 indicators; 10 signal, 5 battery, 4 connection icons, 6 status chips; alpha/no overlap")


if __name__=="__main__":main()
