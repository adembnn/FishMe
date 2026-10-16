# Poissons du widget : texture cartoon de profil (tête à droite) + gros yeux cartoon, sur 600x174 transparent.
import sys
from PIL import Image, ImageDraw, ImageFilter
SRC = "/mnt/project-files/build/aquarium/3d/textures/propres/"
# slug texture -> (nom xcassets, u œil, v œil, rayon/largeur)
P = {
 "brochet": ("brochet", .868, .36, .011), "sandre": ("sandre", .910, .47, .011),
 "perche": ("perche-commune", .904, .49, .013), "carpe-commune": ("carpe-commune", .893, .49, .011),
 "gardon": ("gardon", .921, .53, .013), "truite-fario": ("truite-fario", .900, .42, .011),
 "tanche": ("tanche", .895, .57, .012), "rotengle": ("rotengle", .925, .50, .013),
 "ablette": ("ablette", .897, .36, .012), "black-bass": ("black-bass", .873, .33, .012),
 "breme-commune": ("breme-commune", .907, .45, .012), "chevesne": ("chevesne", .903, .49, .012),
 "silure": ("silure-glane", .887, .48, .009), "aspe": ("aspe", .923, .43, .012),
 "barbeau": ("barbeau-fluviatile", .863, .50, .011), "breme-bordeliere": ("breme-bordeliere", .917, .57, .012),
 "carassin": ("carassin-commun", .905, .54, .012), "gibele": ("carassin-argente", .91, .47, .012),
 "hotu": ("hotu", .913, .47, .012), "ide-melanote": ("ide-melanote", .923, .51, .012),
 "lavaret": ("coregones", .907, .52, .012), "lotte": ("lotte", .94, .35, .009), "ombre": ("ombre-commun", .91, .50, .012),
}
S = 4  # suréchantillonnage pour des yeux bien ronds
W, H = 600, 174
out = sys.argv[1]
for slug, (nom, u, v, r) in P.items():
    im = Image.open(SRC + slug + "-cartoon.png").convert("RGBA")
    w, h = im.size
    big = im.resize((w * S, h * S), Image.LANCZOS)
    d = ImageDraw.Draw(big)
    cx, cy, R = u * w * S, v * h * S, r * w * S
    def rond(x, y, rr, c): d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=c)
    rond(cx, cy, R * 2.1 + 5 * S / 2, (20, 35, 58, 255))      # filet d'encre
    rond(cx, cy, R * 2.1, (255, 255, 255, 255))               # blanc
    rond(cx + R * 0.35, cy + R * 0.1, R * 1.15, (20, 35, 58, 255))  # pupille vers l'avant
    rond(cx + R * 0.05, cy - R * 0.45, R * 0.42, (255, 255, 255, 255))  # reflet
    im = big.resize((w, h), Image.LANCZOS)
    bb = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    im = im.crop(bb)
    k = min((W - 8) / im.width, (H - 8) / im.height)
    im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    c.paste(im, ((W - im.width) // 2, (H - im.height) // 2), im)
    c.save(f"{out}/{nom}.png", optimize=True)
    print(nom, im.size)
