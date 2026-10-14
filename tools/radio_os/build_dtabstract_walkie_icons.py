#!/usr/bin/env python3
"""Build the 512x512 PsychopatzCore Walkie Icons atlas with Pillow.

Source art is drawn as simple, grounded, monochrome 1990s radio LCD icons.
All glyphs are separate, padded, alpha transparent and free of app labels.
The 64x64 grid matches the DTA_Walkie_Manifest.lua 'icons' definitions.
"""
import argparse
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SIZE = 512
CELL = 64
GLYPH = 48
NAMES = [
 ["contacts", "radio_call", "trade", "dossier", "scan", "home", "back", "settings"],
 ["chat", "logs", "faction", "trader", "caravan", "signal", "battery", "mic"],
 ["speaker", "mute", "connecting", "receiving", "transmitting", "offline", "alert", "search"],
 ["plus", "minus", "next", "prev", "up", "down", "left", "right"],
]


def glyph(name):
    m = Image.new("L", (GLYPH, GLYPH), 0)
    d = ImageDraw.Draw(m)
    F = 255
    def ln(points, width=4):
        d.line(points, fill=F, width=width, joint="curve")
    def oval(box, width=0):
        if width: d.ellipse(box, outline=F, width=width)
        else: d.ellipse(box, fill=F)
    def rect(box, width=0):
        if width: d.rectangle(box, outline=F, width=width)
        else: d.rectangle(box, fill=F)
    def poly(points): d.polygon(points, fill=F)
    def arc(box, start, end, width=3): d.arc(box, start, end, fill=F, width=width)
    if name == "contacts":
        oval((10,8,22,20));oval((27,13,38,24))
        d.rounded_rectangle((6,25,26,40), radius=5, fill=F)
        d.rounded_rectangle((26,29,43,40), radius=4, fill=F)
    elif name == "radio_call":
        poly([(9,12),(15,9),(23,16),(20,21),(26,27),(31,25),(38,32),(36,39),(29,40),(15,30),(8,19)])
        arc((24,4,43,24),265,360,3);arc((27,8,40,21),265,360,3)
    elif name == "trade":
        ln([(6,11),(12,11),(16,32),(39,32)],4)
        poly([(15,14),(41,14),(38,27),(18,27)])
        oval((16,35,22,41));oval((32,35,38,41))
    elif name == "dossier":
        d.rounded_rectangle((11,5,37,43),radius=2,outline=F,width=4)
        poly([(27,5),(37,5),(37,15),(27,15)])
        ln([(16,22),(32,22)],3);ln([(16,29),(32,29)],3);ln([(16,36),(28,36)],3)
    elif name == "scan":
        oval((9,9,38,38),3);arc((16,16,31,31),210,330,3)
        ln([(24,24),(39,11)],4);oval((20,20,28,28))
        arc((6,6,41,41),195,240,3)
    elif name == "home":
        poly([(5,22),(24,7),(43,22),(39,26),(37,24),(37,41),(11,41),(11,24),(9,26)])
        rect((20,29,28,41)); d.rectangle((21,30,27,41),fill=0)
    elif name == "back":
        ln([(24,10),(9,24),(24,38)],5);ln([(10,24),(42,24)],5)
    elif name == "settings":
        pts=[]
        for i in range(24):
            a=2*math.pi*i/24-math.pi/2
            radius=20 if i%3==0 else (18 if i%3==1 else 15)
            pts.append((24+math.cos(a)*radius,24+math.sin(a)*radius))
        poly(pts);d.ellipse((18,18,30,30),fill=0)
    elif name == "chat":
        d.rounded_rectangle((5,9,42,36),radius=6,fill=F)
        poly([(11,33),(12,42),(25,34)])
        for x in (14,24,34):d.ellipse((x-2,21,x+2,25),fill=0)
    elif name == "logs":
        rect((10,8,35,39),3);ln([(17,15),(28,15)],3);ln([(17,22),(30,22)],3);ln([(17,29),(29,29)],3)
        ln([(17,43),(41,43),(41,15)],3)
    elif name == "faction":
        ln([(9,7),(9,42)],4);poly([(12,9),(39,11),(32,21),(39,29),(12,27)])
        oval((23,32,29,38));oval((32,31,38,37))
        ln([(19,43),(42,43)],3)
    elif name == "trader":
        rect((11,20,38,42),3)
        poly([(8,12),(41,12),(43,20),(6,20)])
        for x in (12,22,32):ln([(x,13),(x-2,20)],2)
        rect((18,27,27,42),3)
    elif name == "caravan":
        rect((7,13,30,33),3);poly([(29,21),(36,21),(43,29),(43,35),(31,35)])
        ln([(7,35),(44,35)],3);oval((13,34,22,43));oval((32,34,41,43))
    elif name == "signal":
        for i,(x,h) in enumerate(((8,9),(17,15),(26,24),(35,33))):rect((x,41-h,x+5,41))
    elif name == "battery":
        d.rounded_rectangle((5,14,38,35),radius=3,outline=F,width=4);rect((39,20,44,30))
        rect((12,20,18,29));rect((22,20,28,29))
    elif name == "mic":
        d.rounded_rectangle((18,7,30,28),radius=5,fill=F)
        arc((11,14,37,38),5,175,4)
        ln([(24,35),(24,42)],4);ln([(16,43),(32,43)],3)
    elif name == "speaker":
        poly([(7,19),(16,19),(26,10),(26,38),(16,29),(7,29)])
        arc((20,11,40,37),310,50,4);arc((17,5,45,42),310,50,3)
    elif name == "mute":
        poly([(7,19),(16,19),(26,10),(26,38),(16,29),(7,29)])
        ln([(31,17),(42,30)],4);ln([(42,17),(31,30)],4)
    elif name == "connecting":
        oval((6,20,12,26));oval((21,20,27,26));oval((36,20,42,26))
        arc((6,6,42,42),210,300,3)
    elif name == "receiving":
        ln([(6,24),(26,24)],4);poly([(20,16),(30,24),(20,32)])
        rect((35,11,40,38),3)
    elif name == "transmitting":
        rect((8,11,13,38),3)
        ln([(19,24),(41,24)],4);poly([(30,16),(43,24),(30,32)])
    elif name == "offline":
        ln([(24,27),(24,39)],4);ln([(15,39),(33,39)],4)
        arc((13,10,35,30),225,315,3);arc((7,4,41,37),225,315,3)
        ln([(7,7),(42,42)],5)
    elif name == "alert":
        poly([(24,5),(44,41),(4,41)])
        poly([(24,13),(11,37),(37,37)]);d.polygon([(24,13),(11,37),(37,37)],fill=0)
        rect((22,21,26,31));oval((22,33,26,37))
    elif name == "search":
        oval((6,6,32,32),4);ln([(28,28),(43,43)],6)
    elif name == "plus":
        rect((21,7,27,41));rect((7,21,41,27))
    elif name == "minus":
        rect((7,21,41,27))
    elif name == "next":
        poly([(12,10),(35,24),(12,38)]);rect((37,10,42,38))
    elif name == "prev":
        poly([(36,10),(13,24),(36,38)]);rect((6,10,11,38))
    elif name in ("up","down","left","right"):
        arrows={"up":[(24,7),(42,29),(31,29),(31,42),(17,42),(17,29),(6,29)],
                "down":[(17,6),(31,6),(31,19),(42,19),(24,41),(6,19),(17,19)],
                "left":[(7,24),(29,6),(29,17),(42,17),(42,31),(29,31),(29,42)],
                "right":[(41,24),(19,6),(19,17),(6,17),(6,31),(19,31),(19,42)]}
        poly(arrows[name])
    else: raise ValueError(name)
    if m.getbbox() is None: raise AssertionError(name)
    return m


def build():
    out=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    layout={}
    for row,names in enumerate(NAMES):
        for col,name in enumerate(names):
            sid="icon_"+name
            x,y=col*CELL,row*CELL
            mask=glyph(name)
            padded=Image.new("L",(CELL,CELL),0)
            padded.paste(mask,(8,8))
            outline=padded.filter(ImageFilter.MaxFilter(5))
            shadow=Image.new("RGBA",(CELL,CELL),(9,17,13,188))
            out.paste(shadow,(x,y),outline)
            ink=Image.new("RGBA",(CELL,CELL),(195,209,192,255))
            out.paste(ink,(x,y),padded)
            layout[sid]={"sheet":"icons","rect":{"x":x,"y":y,"w":CELL,"h":CELL}}
    return out,layout


def validate(img,layout):
    assert img.mode=="RGBA" and img.size==(SIZE,SIZE)
    assert len(layout)==32
    assert len(set(layout))==32
    for row,names in enumerate(NAMES):
        for col,name in enumerate(names):
            r=layout["icon_"+name]["rect"]
            x,y=col*CELL,row*CELL
            assert r=={"x":x,"y":y,"w":CELL,"h":CELL}
            cell=img.crop((x,y,x+CELL,y+CELL))
            assert cell.getchannel("A").getbbox() is not None,name
            for edge in (cell.crop((0,0,3,64)),cell.crop((61,0,64,64)),
                         cell.crop((0,0,64,3)),cell.crop((0,61,64,64))):
                assert edge.getchannel("A").getbbox() is None,name
    assert img.crop((0,256,512,512)).getchannel("A").getbbox() is None
    preview=img.crop((0,0,512,256)).resize((128,64),Image.Resampling.NEAREST)
    assert preview.getchannel("A").getbbox() is not None
    return True


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",default="DTA_Walkie_Icons.png")
    p.add_argument("--preview",default=None)
    p.add_argument("--layout",default=None)
    args=p.parse_args()
    atlas,layout=build();validate(atlas,layout)
    target=Path(args.output);target.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(target,optimize=True)
    reloaded=Image.open(target).convert("RGBA")
    assert atlas.tobytes()==reloaded.tobytes()
    if args.layout:Path(args.layout).write_text(json.dumps(layout,indent=2)+"\n")
    if args.preview:
        bg=Image.new("RGBA",(SIZE,SIZE),(26,34,30,255))
        bg.alpha_composite(atlas)
        bg.convert("RGB").save(args.preview,optimize=True)
    print("PASS: 32 alpha icons, 512x512, 64x64 cells, zero outer padding bleed")

if __name__=="__main__":main()
