"""Offline PsychopatzCore walkie atlas builder for the approved concept image.

Authoring dependency: Pillow. Not loaded by the game.
Run: python tools/build_dtabstract_walkie_shells.py --source concept.png
The original concept image is not bundled in this commit.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw

ATLAS = (1024, 1024)
DATA = [
    ("walkie_toys_shell","Base.WalkieTalkie1",(6,2,219,523),(63,285,169,366),(65,115,164)),
    ("walkie_valutech_shell","Base.WalkieTalkie2",(222,2,435,523),(273,285,380,366),(280,328,374)),
    ("walkie_premium_shell","Base.WalkieTalkie3",(439,2,659,523),(489,285,597,366),(494,543,594)),
    ("walkie_tactical_shell","Base.WalkieTalkie4",(671,2,894,523),(744,297,849,370),(748,795,842)),
    ("walkie_usarmy_shell","Base.WalkieTalkie5",(913,2,1115,523),(986,299,1080,372),(980,1026,1073)),
    ("walkie_makeshift_shell","Base.WalkieTalkieMakeShift",(1150,2,1414,523),(1228,299,1331,372),(1232,1287,1337)),
]

def rectangle(x, y, w, h):
    return {"x": int(x), "y": int(y), "w": int(w), "h": int(h)}

def build(source, output):
    image = Image.open(source).convert("RGBA")
    if image.size != (1448, 1086):
        raise ValueError("Input must be the approved 1448x1086 concept PNG")
    atlas = Image.new("RGBA", ATLAS, (0, 0, 0, 0))
    layout = []
    for i, (name, item_type, crop, cutout, centers) in enumerate(DATA):
        x0, y0, _, _ = crop
        art = image.crop(crop)
        alpha = art.getchannel("A")
        ImageDraw.Draw(alpha).rectangle((
            cutout[0]-x0, cutout[1]-y0,
            cutout[2]-x0-1, cutout[3]-y0-1
        ), fill=0)
        art.putalpha(alpha.point(lambda v: 0 if v < 12 else v))
        scale = min(420/art.height, 238/art.width)
        w, h = round(art.width*scale), round(art.height*scale)
        art = art.resize((w, h), Image.Resampling.LANCZOS)
        cx, cy = 32+(i%3)*288, 32+(i//3)*464
        dx, dy = (256-w)//2, round((432-h)/2)
        atlas.alpha_composite(art, (cx+dx, cy+dy))
        sx = round((cutout[0]-x0)*scale)+dx+2
        sy = round((cutout[1]-y0)*scale)+dy+2
        sw = round((cutout[2]-cutout[0])*scale)-4
        sh = round((cutout[3]-cutout[1])*scale)-4
        assert sw > 0 and sh > 0
        a = atlas.getchannel("A")
        ImageDraw.Draw(a).rectangle((cx+sx, cy+sy, cx+sx+sw-1, cy+sy+sh-1), fill=0)
        atlas.putalpha(a)
        buttons=[]
        for bx in centers:
            bx=round((bx-x0)*scale)+dx
            by=round((415-y0)*scale)+dy
            bw,bh=round(39*scale),round(32*scale)
            buttons.append(rectangle(bx-bw//2, by-bh//2, bw, bh))
        layout.append({
            "id": name, "fullType": item_type,
            "atlas": rectangle(cx,cy,256,432),
            "screen": rectangle(sx,sy,sw,sh),
            "controls": dict(zip(("left","center","right"),buttons))
        })
    out=Path(output)
    out.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(out,optimize=True)
    return layout

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--source",required=True)
    p.add_argument("--output",default="Contents/mods/PsychopatzCore/42.20/media/ui/psychopatz/radio/shells/DTA_Walkie_Shells.png")
    p.add_argument("--layout",help="Optional JSON verification report")
    args=p.parse_args()
    layout=build(args.source,args.output)
    if args.layout:
        Path(args.layout).write_text(json.dumps({"width":1024,"height":1024,"sprites":layout},indent=2)+"\n")
    print("Wrote 1024x1024 walkie shell atlas, skins="+str(len(layout)))

if __name__ == "__main__":
    main()
