"""Poissons cartoon du widget pour les 74 espèces restantes (même rendu que les 23 du fil aquarium 3D).
Usage : python3 cartoon_widget.py <yeux.json> <dossier_sortie> [nom ...]
yeux.json : {"<nom>": {"miroir": false, "yeux": [[u, v, r], ...]}}  u, v en fraction de l'image source
(0,0 = haut gauche, AVANT miroir), r = rayon de l'œil peint en fraction de la largeur. "yeux": [] = pas d'œil ajouté.
Clés facultatives :
- "rotation": 0, 90, 180 ou 270 (degrés, sens inverse des aiguilles), appliquée avant le miroir, pour les sources vues
  de dessus (écrevisses : tête en haut -> 270 met la tête à droite).
- "miroir": true si, après rotation, la tête est à gauche (la sortie a toujours la tête à droite).
- "teinte": "#rrggbb" pour colorer une gravure en noir et blanc (couleur plausible de l'espèce), "force": 0 à 1 (défaut 0.8).
Les yeux restent TOUJOURS donnés sur l'image source d'origine (avant rotation et miroir)."""
import sys, os, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from skimage.restoration import denoise_tv_chambolle
from skimage import color
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
ENCRE = np.array([0x14, 0x23, 0x3a]) / 255.0
W, H = 600, 174

def teinter(im, hexa, force):
    a0 = np.asarray(im).astype(np.float32) / 255; rgb, a = a0[..., :3], a0[..., 3:]
    t = np.array([int(hexa[i:i + 2], 16) for i in (1, 3, 5)]) / 255.0
    lab = color.rgb2lab(rgb); tl = color.rgb2lab(t[None, None, :])[0, 0]
    k = np.clip(lab[..., :1] / 75, 0.25, 1.0)
    lab[..., 1:] = lab[..., 1:] * (1 - force) + tl[1:] * k * force
    rgb2 = np.clip(color.lab2rgb(lab), 0, 1)
    return Image.fromarray((np.dstack([rgb2, a]) * 255).astype(np.uint8))

def cartoon(im):
    w, h = im.size; LW = 1024; LH = max(1, round(h * LW / w))
    a0 = np.asarray(im.resize((LW, LH), Image.LANCZOS)).astype(np.float32) / 255
    rgb, a = a0[..., :3], a0[..., 3]
    lisse = denoise_tv_chambolle(rgb, weight=0.06, channel_axis=-1)
    lab = color.rgb2lab(np.clip(lisse, 0, 1))
    lab[..., 1:] *= 1.30
    lab[..., 0] = 8 + lab[..., 0] * 0.92 + 4
    rgb2 = np.clip(color.lab2rgb(lab), 0, 1)
    m = a > 0.5
    m = ndi.binary_opening(m, iterations=1)
    d_ext = ndi.distance_transform_edt(~m)
    trait = (d_ext > 0) & (d_ext <= 5.0)
    a2 = np.clip(np.where(m, 1.0, np.clip(5.6 - d_ext, 0, 1)), 0, 1)
    out = np.where(trait[..., None], ENCRE, rgb2)
    d_int = ndi.distance_transform_edt(m)
    assomb = np.clip(1.6 - d_int, 0, 1)[..., None] * 0.35
    out = out * (1 - assomb) + ENCRE * assomb
    return Image.fromarray((np.dstack([out, a2]) * 255).astype(np.uint8))

def yeux(im, liste):
    S = 4; w, h = im.size
    big = im.resize((w * S, h * S), Image.LANCZOS); d = ImageDraw.Draw(big)
    def rond(x, y, rr, c): d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=c)
    for u, v, r in liste:
        cx, cy, R = u * w * S, v * h * S, r * w * S
        rond(cx, cy, R * 2.1 + 5 * S / 2, (20, 35, 58, 255))
        rond(cx, cy, R * 2.1, (255, 255, 255, 255))
        rond(cx + R * 0.35, cy + R * 0.1, R * 1.15, (20, 35, 58, 255))
        rond(cx + R * 0.05, cy - R * 0.45, R * 0.42, (255, 255, 255, 255))
    return big.resize((w, h), Image.LANCZOS)

def main():
    conf = json.load(open(sys.argv[1])); out = sys.argv[2]; os.makedirs(out, exist_ok=True)
    noms = sys.argv[3:] or list(conf)
    for nom in noms:
        c = conf[nom]
        im = Image.open(os.path.join(SRC, nom + ".png")).convert("RGBA")
        bb = im.getchannel("A").point(lambda x: 255 if x > 8 else 0).getbbox()
        sw, sh = im.size; im = im.crop(bb)
        # yeux en pixels du recadrage
        ys = [[u * sw - bb[0], v * sh - bb[1], r * sw] for u, v, r in c.get("yeux", [])]
        rot = c.get("rotation", 0) % 360
        for _ in range(rot // 90):  # 90° sens inverse des aiguilles : (x, y) -> (y, w - x)
            w0 = im.width; im = im.transpose(Image.ROTATE_90); ys = [[y, w0 - x, r] for x, y, r in ys]
        if c.get("miroir"):
            im = im.transpose(Image.FLIP_LEFT_RIGHT); ys = [[im.width - x, y, r] for x, y, r in ys]
        if c.get("teinte"): im = teinter(im, c["teinte"], c.get("force", 0.8))
        ys = [[x / im.width, y / im.height, r / im.width] for x, y, r in ys]
        im = yeux(cartoon(im), ys)
        bb = im.getchannel("A").point(lambda x: 255 if x > 8 else 0).getbbox(); im = im.crop(bb)
        k = min((W - 8) / im.width, (H - 8) / im.height)
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
        cv = Image.new("RGBA", (W, H), (0, 0, 0, 0)); cv.paste(im, ((W - im.width) // 2, (H - im.height) // 2), im)
        cv.save(os.path.join(out, nom + ".png"), optimize=True); print(nom)

main()
