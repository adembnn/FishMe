# Fonds du widget : pleine eau sans décor, point de fuite et horizon à 50 % / 45 % du haut.
import sys, numpy as np
from PIL import Image, ImageFilter
AMB = {"lagon": (0x9df3ec, 0x2fb7d0, 0x0a5d8f, 0x34a9c6),
       "bleu":  (0x5cc4f2, 0x1670b8, 0x061f52, 0x1560a8),
       "aube":  (0xffd3a8, 0x7cc2e2, 0x2b4f94, 0x8fb8d8)}
TAILLES = {"fond-petit": (510, 510), "fond-moyen": (1092, 510), "fond-grand": (1092, 1146)}
def rgb(h): return np.array([(h >> 16) & 255, (h >> 8) & 255, h & 255], float) / 255
def fond(amb, W, H, graine=7):
    haut, mil, bas, brume = map(rgb, AMB[amb])
    rng = np.random.default_rng(graine)
    y, x = np.mgrid[0:H, 0:W].astype(float)
    S = max(W, H)                      # échelle commune pour que les 3 tailles se ressemblent
    fx, fy = W * .5, H * .45
    dx, dy = (x - fx) / S, (y - fy) / S
    t = y / H
    # dégradé vertical : clair en surface, profond en bas, palier doux à l'horizon
    a = np.clip(t / .45, 0, 1)[..., None]; b = np.clip((t - .45) / .55, 0, 1)[..., None]
    c = np.where(t[..., None] < .45, haut * (1 - a) + mil * a, mil * (1 - b) + bas * b)
    # brume lumineuse au point de fuite (la profondeur)
    r = np.sqrt(dx ** 2 + (dy * 1.6) ** 2)
    halo = np.exp(-(r / .28) ** 2)[..., None]
    c = c * (1 - .55 * halo) + (brume * .5 + haut * .5) * .55 * halo
    # rayons qui partent de la surface et convergent vers le point de fuite
    ang = np.arctan2(dx, -(dy - .9))
    ray = np.zeros_like(ang)
    for k, (f, ph, w) in enumerate([(9, 0.3, .5), (14, 1.7, .35), (23, 2.9, .2)]):
        ray += w * np.clip(np.sin(ang * f + ph) * 1.6 - .6, 0, 1)
    ray *= np.clip(1 - t / .8, 0, 1) ** 1.5 * .22
    c = c + ray[..., None] * (haut - c) * 1.2
    # vignette en perspective : les bords et le bas s'assombrissent vers le large
    vig = np.clip(1 - .55 * (np.abs(dx) * 1.1 + np.clip(dy, 0, None) * 1.2) ** 1.4, .45, 1)
    c = c * vig[..., None]
    # reflets de surface tout en haut
    vag = np.clip(1 - t / .12, 0, 1) * (0.5 + 0.5 * np.sin(x / S * 60 + np.sin(x / S * 17) * 3))
    c = c + vag[..., None] * .12
    img = Image.fromarray((np.clip(c, 0, 1) * 255).astype(np.uint8))
    # neige marine : particules plus grosses et plus nettes près du spectateur (bords), fines au loin
    from PIL import ImageDraw
    calque = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(calque)
    for _ in range(int(W * H / 2500)):
        px, py = rng.uniform(0, W), rng.uniform(0, H)
        prox = min(1, np.hypot((px - fx) / S, (py - fy) / S) * 2.2)
        rr = .6 + prox * 2.4 * S / 1100 * rng.uniform(.6, 1.4)
        al = int(40 + 90 * prox * rng.uniform(.4, 1))
        d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=(255, 255, 255, al))
    calque = calque.filter(ImageFilter.GaussianBlur(.6 * S / 1100))
    img = Image.alpha_composite(img.convert("RGBA"), calque).convert("RGB")
    return img.filter(ImageFilter.GaussianBlur(.4))
out = sys.argv[1]
import os
for amb in AMB:
    os.makedirs(f"{out}/{amb}", exist_ok=True)
    for nom, (W, H) in TAILLES.items():
        im = fond(amb, W, H)
        im.save(f"{out}/{amb}/{nom}.jpg", quality=88, optimize=True, progressive=True)
        if amb == "lagon": im.save(f"{out}/{nom}.jpg", quality=88, optimize=True, progressive=True)
