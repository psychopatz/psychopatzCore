#!/usr/bin/env python3
"""Build PsychopatzCore's modular Walkie Buttons atlas with exact manifest geometry.

Build-time only; depends on Pillow. All buttons are empty backgrounds: labels,
icons, keyboard focus and click behavior are drawn by the live Radio OS.
Coordinate origin is top left. The 1024x512 atlas uses straight RGBA alpha.
"""
import argparse
import json
import random
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = (1024, 512)
PALETTES = {
    "green": {"top": (50, 88, 58), "face": (27, 56, 36), "bottom": (12, 31, 21), "edge": (89, 125, 86), "light": (149, 191, 127)},
    "dark": {"top": (63, 68, 70), "face": (42, 46, 48), "bottom": (17, 22, 24), "edge": (99, 107, 110), "light": (151, 161, 164)},
    "amber": {"top": (113, 79, 28), "face": (74, 49, 20), "bottom": (38, 27, 14), "edge": (156, 111, 42), "light": (226, 169, 69)},
    "red": {"top": (126, 49, 43), "face": (92, 37, 34), "bottom": (42, 21, 22), "edge": (164, 74, 64), "light": (218, 119, 98)},
}
STATES = ("idle", "hover", "pressed", "disabled")
SPRITES = []
for theme, y in (("green",16), ("dark",64), ("amber",112), ("red",160)):
    for n, state in enumerate(STATES):
        SPRITES.append((f"btn_sq_{theme}_{state}",16+n*80,y,64,32,theme,state,6))
for theme, y in (("green",224), ("dark",280)):
    for n, state in enumerate(STATES):
        SPRITES.append((f"btn_wide_{theme}_{state}",16+n*160,y,144,40,theme,state,8))
for family, start, theme in (("call",16,"green"),("hangup",416,"red")):
    for n, state in enumerate(STATES):
        SPRITES.append((f"btn_{family}_{state}",start+n*96,336,80,40,theme,state,8))
for n, state in enumerate(("idle", "hover", "active", "disabled")):
    SPRITES.append((f"btn_tab_{state}",16+n*128,400,112,36,"dark",state,8))


def blend(a, b, t):
    return tuple(round(x*(1-t)+y*t) for x,y in zip(a,b))


def rgba(rgb, alpha=255):
    return (*rgb,alpha)


def draw_button(w,h,theme,state,cap,seed):
    """Draw square-cornered layered, non-glossy survival-UI button chrome."""
    p=PALETTES[theme]
    img=Image.new("RGBA", (w,h), (0,0,0,0))
    d=ImageDraw.Draw(img)
    disabled=state=="disabled"
    pressed=state=="pressed"
    hot=state in ("hover","active")
    accent=p["light"] if hot else p["edge"]
    face=p["face"]
    if hot: face=blend(face,p["top"],0.34 if state=="hover" else 0.53)
    if pressed: face=blend(face,p["bottom"],0.42)
    if disabled: face=blend(face,(26,27,26),0.64)
    yoff=1 if pressed else 0
    left,right=2,w-3
    top,bottom=2+yoff,h-4+yoff
    # Black outer safety shadow, clear 2px gutter. Corners are mechanically clipped.
    d.polygon(((left+4,top-2),(right-4,top-2),(right,top+2),(right,bottom-2),
               (right-4,bottom+2),(left+4,bottom+2),(left,bottom-2),(left,top+2)),
              fill=(9,12,11,210 if disabled else 250))
    d.polygon(((left+5,top),(right-5,top),(right-1,top+4),(right-1,bottom-3),
               (right-5,bottom),(left+5,bottom),(left+1,bottom-3),(left+1,top+4)),
              fill=rgba(p["bottom"],210 if disabled else 255))
    d.polygon(((left+6,top+2),(right-6,top+2),(right-3,top+5),(right-3,bottom-5),
               (right-6,bottom-2),(left+6,bottom-2),(left+3,bottom-5),(left+3,top+5)),
              fill=rgba(face,190 if disabled else 255))
    # Matte, slightly scuffed bevel. Flat interior kept uncluttered for runtime labels.
    bevel=blend(p["edge"],(49,52,50),0.65) if disabled else accent
    d.line((left+7,top+2,right-7,top+2),fill=rgba(bevel,100 if disabled else 230),width=1)
    d.line((left+5,top+5,left+5,bottom-6),fill=rgba(bevel,100 if disabled else 195))
    d.line((left+7,bottom-2,right-7,bottom-2),fill=rgba(p["bottom"],225),width=2)
    d.line((right-4,top+6,right-4,bottom-6),fill=rgba(p["bottom"],210))
    # Unintrusive scratched edges; deterministic, never under center text.
    rng=random.Random(seed)
    for _ in range(max(3,w//17)):
        if rng.random()<0.65:
            x=rng.randint(left+7,right-7)
            y=rng.choice((top+3,bottom-3))
        else:
            x=rng.choice((left+6,right-5))
            y=rng.randint(top+6,bottom-6)
        d.point((x,y),fill=rgba(bevel,65 if disabled else 115))
    if hot and not disabled:
        # Illuminated corner ticks denote hover/focus without baking iconography.
        tick=rgba(p["light"],225)
        for x,dx in ((left+6,1),(right-6,-1)):
            for y,dy in ((top+5,1),(bottom-5,-1)):
                d.line((x,y,x+dx*3,y),fill=tick)
                d.line((x,y,x,y+dy*3),fill=tick)
    if pressed:
        d.line((left+9,top+5,right-9,top+5),fill=rgba(p["bottom"],200),width=2)
    if state=="active":
        d.line((left+10,bottom-4,right-10,bottom-4),fill=rgba(p["light"],225),width=2)
    return img


def make():
    atlas=Image.new("RGBA",SIZE,(0,0,0,0))
    layout={}
    for idx,(name,x,y,w,h,theme,state,cap) in enumerate(SPRITES):
        atlas.alpha_composite(draw_button(w,h,theme,state,cap,idx+80421),(x,y))
        layout[name]={"sheet":"buttons","rect":{"x":x,"y":y,"w":w,"h":h},"capInsets":cap}
    return atlas,layout


def validate(atlas,layout):
    assert atlas.size==SIZE and atlas.mode=="RGBA"
    assert len(layout)==36 and len(set(layout))==36
    rects=[]
    for name,v in layout.items():
        r=v["rect"]
        x,y,w,h=(r[k] for k in ("x","y","w","h"))
        assert x>=0 and y>=0 and x+w<=SIZE[0] and y+h<=SIZE[1],name
        assert 2*v["capInsets"]<min(w,h),name
        a=atlas.crop((x,y,x+w,y+h)).getchannel("A")
        assert a.getbbox() is not None,name
        assert a.getpixel((0,0))==0 and a.getpixel((w-1,h-1))==0,name
        for other,a0,b0,a1,b1 in rects:
            assert (x>=a1 or a0>=x+w or y>=b1 or b0>=y+h),(name,other)
        rects.append((name,x,y,x+w,y+h))
    assert atlas.getpixel((0,0))[3]==0
    # All four states need genuinely distinct pixels, not merely different IDs.
    for kind in ("sq_green", "sq_red", "wide_dark", "call", "hangup", "tab"):
        states=("idle","hover","pressed","disabled") if kind!="tab" else ("idle","hover","active","disabled")
        bitmaps=[atlas.crop(tuple(layout[f"btn_{kind}_{state}"]["rect"][k] for k in ("x","y")) +
                    tuple(layout[f"btn_{kind}_{state}"]["rect"][k]+layout[f"btn_{kind}_{state}"]["rect"][d] for k,d in (("x","w"),("y","h")))).tobytes() for state in states]
        assert len(set(bitmaps))==len(bitmaps),(kind,"states are visually identical")
    return True


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",default="Contents/mods/PsychopatzCore/common/media/ui/psychopatz/radio/ui/DTA_Walkie_Buttons.png")
    p.add_argument("--preview",default=None)
    p.add_argument("--map",default=None)
    args=p.parse_args()
    atlas,layout=make()
    validate(atlas,layout)
    dest=Path(args.output)
    dest.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(dest,optimize=True)
    reopened=Image.open(dest).convert("RGBA")
    assert reopened.tobytes()==atlas.tobytes(),"PNG round trip failed"
    if args.map: Path(args.map).write_text(json.dumps(layout,indent=2)+"\n")
    if args.preview:
        bg=Image.new("RGBA",SIZE,(24,27,27,255))
        bg.alpha_composite(atlas)
        bg.convert("RGB").save(args.preview,optimize=True)
    print("PASS: 36 button-state backgrounds, 1024x512 RGBA, no overlaps")


if __name__=="__main__":
    main()
