"""Fonds océan v2 (Adem 08h35 : « ça fait pas assez océan ») : on est sous l'eau et on regarde au loin.
Au-dessus de l'horizon (45 % du haut) : le dessous de la surface vu en perspective, vagues et réseau de caustiques
lumineuses, grosses près de nous, serrées au loin, fondues dans le bleu. Rayons de soleil qui plongent.
En dessous : le grand bleu qui s'assombrit vers les profondeurs. Particules en suspension, plus grosses près de nous.
python3 ocean2.py <dossier_sortie>"""
import sys, os, numpy as np
from PIL import Image, ImageFilter, ImageDraw
TAILLES = {"fond-petit": (510, 510), "fond-moyen": (1092, 510), "fond-grand": (1092, 1146)}
def hexa(h): return np.array([(h >> 16) & 255, (h >> 8) & 255, h & 255], float) / 255
SURF, BRUME, MI, PROF, ABY = hexa(0xbff6ff), hexa(0x2fa6d6), hexa(0x157fbf), hexa(0x0a3f7d), hexa(0x041a3d)
def caustiques(X, Z, t=0.0):
    a = np.sin(X * 2.1 + np.sin(Z * 1.7 + t) * 1.3) + np.sin(Z * 2.6 + np.sin(X * 1.3 - t) * 1.1)
    b = np.sin((X + Z) * 1.9 + np.sin(X * 0.8) * 2.0) + np.sin((X - Z) * 2.3 + np.sin(Z * 0.9) * 1.6)
    c = np.exp(-(a ** 2) * 2.2) + np.exp(-(b ** 2) * 2.2)
    return np.clip(c * 0.6, 0, 1.4)
def fond(W, H, graine=3):
    rng = np.random.default_rng(graine)
    S = max(W, H); y, x = np.mgrid[0:H, 0:W].astype(float)
    hz = H * 0.45; cx = W * 0.5; f = S * 0.9
    c = np.zeros((H, W, 3))
    # sous l'horizon : profondeur
    t = np.clip((y - hz) / (H - hz + 1e-6), 0, 1)[..., None]
    bas = np.where(t < 0.5, BRUME * (1 - t / 0.5) + MI * (t / 0.5), MI * (1 - (t - 0.5) / 0.5) + PROF * ((t - 0.5) / 0.5))
    bas = bas * (1 - 0.35 * t ** 1.5) + ABY * 0.35 * t ** 1.5
    # au-dessus : la surface vue de dessous, en perspective
    dy = np.maximum(hz - y, 1.0); d = (f * 0.35) / dy        # distance de la surface (le haut de l'image = tout près)
    X = (x - cx) / f * d * 6; Z = d * 6
    ca = caustiques(X, Z)
    loin = np.clip(1 - np.exp(-d * 0.55), 0, 1)               # 0 près, 1 loin -> fondu dans la brume
    pres = 1 - loin
    surf = SURF * (0.55 + 0.45 * pres[..., None]) * 0.9 + BRUME * 0.1
    vague = 0.5 + 0.5 * np.sin(X * 0.9 + np.sin(Z * 0.6) * 2)  # grandes ondulations de la surface
    haut = surf * (0.62 + 0.25 * vague[..., None]) + ca[..., None] * pres[..., None] * 0.55
    haut = haut * pres[..., None] + BRUME * loin[..., None] * 1.05
    # fenêtre de Snell : plus clair juste au-dessus de nous
    fen = np.exp(-(((x - cx) / (W * 0.55)) ** 2 + (y / (hz * 1.1)) ** 2) * 1.2)[..., None]
    haut = haut + fen * 0.18
    k = np.clip((y - (hz - H * 0.07)) / (H * 0.12), 0, 1); k = (k * k * (3 - 2 * k))[..., None]   # raccord sans marche
    c = haut * (1 - k) + bas * k
    # raccord doux à l'horizon (brume)
    r = np.exp(-((y - hz) / (H * 0.06)) ** 2)[..., None]
    c = c * (1 - r * 0.35) + BRUME * 1.1 * r * 0.35
    # rayons de soleil : partent de la surface, plongent en s'écartant, s'éteignent en profondeur
    ang = np.arctan2(x - cx * 1.15, y + H * 0.6)
    ray = np.zeros_like(ang)
    for fr, ph, w in ((11, 0.4, 0.55), (17, 2.1, 0.35), (29, 4.0, 0.22), (7, 1.0, 0.4)):
        ray += w * np.clip(np.sin(ang * fr + ph) * 1.8 - 0.9, 0, 1)
    ray *= np.clip(1 - y / (H * 0.95), 0, 1) ** 1.6 * np.clip(y / (hz * 0.4), 0, 1)
    c = c + ray[..., None] * 0.16 * (SURF - c * 0.5)
    # vignette douce
    v = 1 - 0.28 * (((x - cx) / (W * 0.75)) ** 2 + ((y - H * 0.5) / (H * 0.9)) ** 2)
    c = np.clip(c * v[..., None], 0, 1)
    img = Image.fromarray((c * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(S / 900))
    # particules
    cal = Image.new("RGBA", (W, H), (0, 0, 0, 0)); dr = ImageDraw.Draw(cal)
    for _ in range(int(W * H / 1800)):
        px, py = rng.uniform(0, W), rng.uniform(0, H)
        pr = min(1, np.hypot((px - cx) / S, (py - hz) / S) * 2.4)
        rr = (0.5 + pr * 2.2 * rng.uniform(0.5, 1.4)) * S / 1100
        al = int(25 + 110 * pr * rng.uniform(0.3, 1))
        dr.ellipse([px - rr, py - rr, px + rr, py + rr], fill=(230, 250, 255, al))
    cal = cal.filter(ImageFilter.GaussianBlur(0.7 * S / 1100))
    return Image.alpha_composite(img.convert("RGBA"), cal).convert("RGB")
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
for n, (W, H) in TAILLES.items():
    fond(W, H).save(os.path.join(out, n + ".jpg"), quality=90, optimize=True, progressive=True)
