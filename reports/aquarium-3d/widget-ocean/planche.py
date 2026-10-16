"""Planche de contrôle : python3 planche.py <sortie.jpg> <dossier_png> [nom ...] (2 colonnes, fond bleu océan).
Avec --grille : montre les images SOURCE avec une grille u/v tous les 0.05 pour lire la position des yeux."""
import sys, os
from PIL import Image, ImageDraw
args = [a for a in sys.argv[1:] if a != "--grille"]; grille = "--grille" in sys.argv
out, dos, noms = args[0], args[1], args[2:]
if grille:
    ims = []
    for n in noms:
        im = Image.open(os.path.join(dos, n + ".png")).convert("RGBA"); k = 900 / im.width
        im = im.resize((900, round(im.height * k)))
        bg = Image.new("RGB", im.size, (200, 220, 230)); bg.paste(im, (0, 0), im); d = ImageDraw.Draw(bg)
        for i in range(21):
            x = i * 899 / 20; y = i * (bg.height - 1) / 20; c = (255, 0, 0) if i % 2 == 0 else (255, 160, 160)
            d.line([(x, 0), (x, bg.height)], fill=c); d.line([(0, y), (900, y)], fill=c)
            if i % 2 == 0: d.text((x + 2, 2), f"{i/20:.1f}", fill=(0, 0, 0)); d.text((2, y + 1), f"{i/20:.1f}", fill=(0, 0, 0))
        d.text((10, bg.height - 14), n, fill=(0, 0, 0)); ims.append(bg)
    Hh = sum(i.height + 10 for i in ims); s = Image.new("RGB", (900, Hh), (255, 255, 255)); y = 0
    for i in ims: s.paste(i, (0, y)); y += i.height + 10
    s.save(out, quality=85)
else:
    s = Image.new("RGB", (1200, 174 * ((len(noms) + 1) // 2)), (60, 170, 200)); d = ImageDraw.Draw(s)
    for i, n in enumerate(noms):
        im = Image.open(os.path.join(dos, n + ".png")); s.paste(im, ((i % 2) * 600, (i // 2) * 174), im)
        d.text(((i % 2) * 600 + 4, (i // 2) * 174 + 2), n, fill=(255, 255, 255))
    s.save(out, quality=85)
