"""Recadre TOUTES les images d'une espèce (toutes vues, tous battements) dans le MÊME cadre, centré sur le poisson :
on peut ainsi fondre d'un angle à l'autre sans saut. Largeur max 600 px (même échelle pour toutes les vues).
python3 -I recadrer_commun.py <dossier_rendus> <dossier_sortie>"""
import sys, os, glob, re
from PIL import Image
src, out = sys.argv[1:3]; os.makedirs(out, exist_ok=True)
esp = {}
for f in glob.glob(os.path.join(src, "*.png")):
    b = os.path.basename(f); m = re.match(r"(.+?)-(nage|vue-\d|angle-[pm][\d_]+|lacet-m?[\d_]+)-\d+\.png$", b)
    if m: esp.setdefault(m.group(1), []).append(f)
for e, fs in esp.items():
    bb = None
    for f in fs:
        b = Image.open(f).getchannel("A").point(lambda x: 255 if x > 6 else 0).getbbox()
        if b: bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    W0 = Image.open(fs[0]).width; cx = W0 / 2  # le centre du poisson est au centre du rendu : on garde le cadre symétrique
    demi = max(cx - bb[0], bb[2] - cx); bb = (int(cx - demi), bb[1], int(cx + demi), bb[3])
    k = min(1.0, 600 / (bb[2] - bb[0]))
    for f in fs:
        im = Image.open(f).crop(bb)
        if k < 1: im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        im.save(os.path.join(out, os.path.basename(f)), optimize=True)
    print(e, len(fs), "images", (bb[2] - bb[0], bb[3] - bb[1]), "->", round((bb[2] - bb[0]) * k))
