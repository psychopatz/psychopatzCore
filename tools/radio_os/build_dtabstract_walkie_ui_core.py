#!/usr/bin/env python3
"""Generate the 1024x1024 PsychopatzCore Walkie UI Core atlas deterministically.

This is a build-time development script; the game uses the produced PNG only.
Requires Pillow. No input concept artwork, fonts, NPC data, or network access.
Coordinate contract: UI sprites declared by DTA_Walkie_Manifest.lua.
"""
import argparse
import json
import random
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = (1024, 1024)
SPRITES = [
 ("screen_bg_green",16,16,224,128),
 ("screen_bg_amber",256,16,224,128),
 ("screen_bg_dark",496,16,224,128),
 ("screen_bg_noise",736,16,224,128),
 ("titlebar_green",16,160,224,32),
 ("titlebar_amber",256,160,224,32),
 ("titlebar_dark",496,160,224,32),
 ("footerbar_green",16,208,224,32),
 ("footerbar_amber",256,208,224,32),
 ("tabbar_green",16,256,224,32),
 ("tabbar_dark",256,256,224,32),
 ("listrow_green_idle",16,304,224,40),
 ("listrow_green_selected",16,352,224,40),
 ("listrow_dark_idle",256,304,224,40),
 ("listrow_dark_selected",256,352,224,40),
 ("dialog_green",16,416,320,208),
 ("dialog_amber",352,416,320,208),
 ("popup_small_dark",688,416,192,128),
 ("home_tile_idle",16,640,104,104),
 ("home_tile_selected",136,640,104,104),
 ("home_tile_disabled",256,640,104,104),
 ("portrait_frame_green",16,760,128,128),
 ("portrait_frame_amber",160,760,128,128),
 ("contact_card_green",304,760,224,96),
 ("status_strip_green",544,760,224,48),
]
# Muted Project Zomboid-inspired UI palette; not a claim of exact vanilla texture matching.
PAL = {
 "green": {"face":(22,45,32), "dark":(9,23,18),"rim":(54,91,65),"hi":(96,135,100),"accent":(136,190,111)},
 "amber": {"face":(61,44,19),"dark":(31,22,10),"rim":(119,82,29),"hi":(182,133,53),"accent":(224,175,75)},
 "dark": {"face":(37,40,40),"dark":(16,20,22),"rim":(73,78,80),"hi":(124,131,133),"accent":(151,163,164)},
}
def rgba(rgb, a=255):
 return (*rgb, a)
def shift(rgb, n):
 return tuple(max(0, min(255, c+n)) for c in rgb)

def texnoise(im, box, rgb, count, seed):
 x0,y0,x1,y1=box
 rng=random.Random(seed)
 draw=ImageDraw.Draw(im)
 for _ in range(count):
  x=rng.randrange(x0+2,x1-2); y=rng.randrange(y0+2,y1-2)
  draw.point((x,y),fill=rgba(shift(rgb,rng.choice([-17,-11,-7,8,12,15])),rng.choice([65,78,95,120])))

def panel(w,h,theme="green",kind="bar",selected=False,noisy=False):
 c=PAL[theme]
 im=Image.new("RGBA",(w,h),(0,0,0,0));d=ImageDraw.Draw(im)
 radius=6 if w>120 or h>70 else 3
 d.rounded_rectangle((1,2,w-2,h-2),radius=radius,fill=rgba(c["dark"]),outline=rgba(shift(c["rim"],-15)))
 d.rounded_rectangle((3,3,w-4,h-4),radius=max(1,radius-2),fill=rgba(c["face"]),outline=rgba(c["rim"]))
 d.line([(6,4),(w-7,4)],fill=rgba(c["hi"],205),width=1)
 d.line([(6,h-5),(w-7,h-5)],fill=rgba(shift(c["dark"],-5)),width=2)
 if kind=="screen":
  d.rounded_rectangle((6,6,w-7,h-7),radius=2,fill=rgba(c["dark"]),outline=rgba(shift(c["rim"],-10)))
  for yy in range(9,h-8,3):
   d.line((9,yy,w-10,yy),fill=rgba(c["rim"],45),width=1)
  if noisy:
   rng=random.Random(48279)
   for _ in range((w*h)//44):
    px=rng.randrange(9,w-9);py=rng.randrange(9,h-9)
    d.point((px,py),fill=rgba(rng.choice((c["hi"],c["rim"],c["dark"])),rng.randint(35,120)))
 elif kind in ("title","footer","tab"):
  d.rectangle((8,7,w-9,h-9),fill=rgba(c["dark"]))
  d.line((9,7,w-10,7),fill=rgba(c["rim"]))
  if kind=="tab":d.line((8,h-9,w-9,h-9),fill=rgba(c["accent"],150))
  for xx,sgn in ((5,1),(w-6,-1)):
   d.line([(xx,9),(xx,7),(xx+sgn*2,7)],fill=rgba(c["accent"],170))
 elif kind=="row":
  d.rectangle((7,7,w-8,h-8),fill=rgba(c["dark"]))
  if selected:
   d.rectangle((7,7,10,h-8),fill=rgba(c["accent"]))
   d.line((12,8,w-9,8),fill=rgba(c["accent"],120))
 elif kind=="dialog":
  d.rounded_rectangle((10,10,w-11,h-11),radius=2,fill=rgba(c["dark"]))
  d.rectangle((13,13,w-14,32),fill=rgba(c["face"]))
  d.line((13,33,w-14,33),fill=rgba(c["rim"]))
  for px in (6,w-7):
   for py in (7,h-8):d.point((px,py),fill=rgba(c["accent"],140))
 elif kind=="tile":
  d.rounded_rectangle((9,9,w-10,h-10),radius=4,fill=rgba(c["dark"]),outline=rgba(c["rim"]))
  if selected:d.rounded_rectangle((6,6,w-7,h-7),radius=5,outline=rgba(c["accent"]),width=2)
  if theme=="dark":d.rounded_rectangle((9,9,w-10,h-10),radius=4,fill=rgba((30,32,32),220),outline=rgba((71,74,74)))
 elif kind=="portrait":
  d.rounded_rectangle((8,8,w-9,h-9),radius=3,fill=(0,0,0,0),outline=rgba(c["rim"]))
  d.rectangle((11,11,w-12,h-12),fill=(0,0,0,0))
  for xx,side in ((6,1),(w-7,-1)):
   for yy,down in ((6,1),(h-7,-1)):
    d.line((xx,yy,xx+side*6,yy),fill=rgba(c["accent"]))
    d.line((xx,yy,xx,yy+down*6),fill=rgba(c["accent"]))
 elif kind=="contact":
  d.rectangle((9,9,w-10,h-10),fill=rgba(c["dark"]))
  d.line((72,12,72,h-13),fill=rgba(c["rim"],110))
 elif kind=="status":
  d.rectangle((7,7,w-8,h-8),fill=rgba(c["dark"]))
  d.line((8,h-10,w-9,h-10),fill=rgba(c["rim"]))
 if kind!="portrait":
  texnoise(im,(4,4,w-4,h-4),c["rim"],max(12,(w*h)//230),w*120+h*13+len(kind))
 return im

def build():
 atlas=Image.new("RGBA",SIZE,(0,0,0,0))
 records={}
 for name,x,y,w,h in SPRITES:
  theme="amber" if "amber" in name else "dark" if "dark" in name or "disabled" in name else "green"
  if name=="screen_bg_noise":theme="dark"
  kind=("screen" if name.startswith("screen_bg_") else
        "title" if name.startswith("titlebar") else
        "footer" if name.startswith("footerbar") else
        "tab" if name.startswith("tabbar") else
        "row" if name.startswith("listrow") else
        "dialog" if "dialog" in name or name.startswith("popup_") else
        "tile" if name.startswith("home_tile") else
        "portrait" if name.startswith("portrait_frame") else
        "contact" if name.startswith("contact_card") else "status")
  atlas.alpha_composite(panel(w,h,theme,kind,selected="selected" in name,noisy=name=="screen_bg_noise"),(x,y))
  records[name]={"sheet":"core","rect":{"x":x,"y":y,"w":w,"h":h}}
 return atlas,records

def verify(im,records):
 assert im.size==SIZE and im.mode=="RGBA"
 assert len(records)==25
 occupied=[]
 for name,item in records.items():
  r=item["rect"];x,y,w,h=[r[k] for k in ("x","y","w","h")]
  assert 0<=x<x+w<=1024 and 0<=y<y+h<=1024,name
  assert im.crop((x,y,x+w,y+h)).getchannel("A").getbbox() is not None,name
  for other,a,b,c,d in occupied:
   assert x>=c or a>=x+w or y>=d or b>=y+h,(name,other)
  occupied.append((name,x,y,x+w,y+h))
 assert im.getpixel((0,0))[3]==0
 for name in ("portrait_frame_green","portrait_frame_amber"):
  r=records[name]["rect"]
  assert im.getpixel((r["x"]+64,r["y"]+64))[3]==0,name

def main():
 p=argparse.ArgumentParser()
 p.add_argument("--output",default="DTA_Walkie_UI_Core.png")
 p.add_argument("--preview",default=None)
 p.add_argument("--map",default=None)
 args=p.parse_args()
 atlas,records=build();verify(atlas,records)
 dest=Path(args.output);dest.parent.mkdir(parents=True,exist_ok=True)
 indexed=atlas.quantize(colors=32,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE)
 indexed.save(dest,optimize=True)
 assert Image.open(dest).convert("RGBA").getpixel((80,820))[3]==0
 assert Image.open(dest).convert("RGBA").getpixel((220,820))[3]==0
 if args.map:Path(args.map).write_text(json.dumps(records,indent=2)+"\n")
 if args.preview:
  bg=Image.new("RGBA",SIZE,(24,26,25,255))
  bg.alpha_composite(atlas)
  bg.convert("RGB").save(args.preview,optimize=True)
 print("PASS: 25 UI Core sprites, 1024x1024 indexed PNG, 2 alpha portrait holes; no overlaps")

if __name__=="__main__":main()
