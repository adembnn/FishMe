"""Redresse la queue recourbée du silure (planche de Bloch) : chaque texture est relue le long d'une colonne
vertébrale courbe et déroulée en ligne droite. python3 redresser.py <dossier_src> <dossier_sortie>"""
import sys, os, numpy as np
from PIL import Image
src, out = sys.argv[1:3]; os.makedirs(out, exist_ok=True)
P = np.array(eval(os.environ.get("SPINE", "[(345,560),(330,470),(300,428),(200,395),(100,370),(55,320),(65,250),(120,200),(200,180),(400,180),(600,185),(800,195),(1000,215),(1200,240),(1400,250)]")), float)
# Catmull-Rom dense
def cr(P, n=60):
    Q = np.vstack([2*P[0]-P[1], P, 2*P[-1]-P[-2]]); pts = []
    for i in range(1, len(Q)-2):
        p0, p1, p2, p3 = Q[i-1:i+3]
        for t in np.linspace(0, 1, n, endpoint=False):
            pts.append(0.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t**3))
    pts.append(P[-1]); return np.array(pts)
C = cr(P); d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(C, axis=0), axis=1))]
L = d[-1]; W = int(np.ceil(L)); H = 631; Y0 = int(os.environ.get("Y0", "230"))
s = np.arange(W) + 0.5
cx = np.interp(s, d, C[:, 0]); cy = np.interp(s, d, C[:, 1])
tx = np.gradient(cx); ty = np.gradient(cy); n = np.hypot(tx, ty); tx /= n; ty /= n
# lisse les tangentes pour éviter les à-coups
k = 25; ker = np.ones(k)/k
tx = np.convolve(np.pad(tx, k, mode="edge"), ker, "same")[k:-k]; ty = np.convolve(np.pad(ty, k, mode="edge"), ker, "same")[k:-k]
n = np.hypot(tx, ty); tx /= n; ty /= n
t = (Y0 - (np.arange(H) + 0.5))[:, None]          # t > 0 : vers le dos (haut)
SX = cx[None, :] + t * ty[None, :]; SY = cy[None, :] - t * tx[None, :]
# limite côté ventre dans la boucle : jamais au-delà du centre de courbure (sinon on relit l'autre moitié du corps)
def bil(a, x, y):
    h, w = a.shape[:2]; x = np.clip(x - 0.5, 0, w - 1.001); y = np.clip(y - 0.5, 0, h - 1.001)
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int); fx = x - x0; fy = y - y0
    if a.ndim == 3: fx = fx[..., None]; fy = fy[..., None]
    return (a[y0, x0]*(1-fx)*(1-fy) + a[y0, x0+1]*fx*(1-fy) + a[y0+1, x0]*(1-fx)*fy + a[y0+1, x0+1]*fx*fy)
dedans = (SX >= 0) & (SX < 1400) & (SY >= 0) & (SY < 631)
# propriété : chaque pixel de la planche appartient au point de la colonne le plus proche ; on ne relit un pixel
# que depuis sa propre tranche (sinon, dans la boucle, on relirait l'autre moitié du corps)
Cs = np.c_[np.interp(np.arange(0, L, 3), d, C[:, 0]), np.interp(np.arange(0, L, 3), d, C[:, 1])]
prop = np.zeros((631, 1400), np.float32)
xx = np.arange(1400) + 0.5
for y in range(631):
    dd = (xx[:, None] - Cs[None, :, 0])**2 + (y + 0.5 - Cs[None, :, 1])**2
    prop[y] = np.argmin(dd, axis=1) * 3.0
TOL = float(os.environ.get("TOL", "60"))
pp = prop[np.clip(SY.astype(int), 0, 630), np.clip(SX.astype(int), 0, 1399)]
dedans &= np.abs(pp - s[None, :]) < TOL
for nom in ["couleur", "epaisseur", "nageoires", "normale", "relief"]:
    im = Image.open(os.path.join(src, f"silure-{nom}.png")); mode = im.mode
    a = np.array(im).astype(np.float64)
    r = bil(a, SX, SY)
    if a.ndim == 3: r[~dedans] = 0
    else: r[~dedans] = 0
    if nom == "normale":
        # les normales peintes suivent le flanc : on fait tourner leur composante XY avec la tangente
        nx = r[..., 0]/127.5 - 1; ny = r[..., 1]/127.5 - 1
        c = tx[None, :]; si = -ty[None, :]           # angle de la tangente (image y vers le bas)
        rx = nx*c - ny*si; ry = nx*si + ny*c
        r[..., 0] = (rx + 1)*127.5; r[..., 1] = (ry + 1)*127.5
    if mode == "I;16": res = Image.fromarray(np.clip(r, 0, 65535).astype(np.uint16))
    else: res = Image.fromarray(np.clip(r, 0, 255).astype(np.uint8), mode)
    res.save(os.path.join(out, f"silure-{nom}.png"))
print("longueur", W, "x", H)
# nettoyage : on ne garde que le morceau qui touche le corps (les bouts de nageoire arrachés dans la boucle partent),
# et on coupe la bande sous la queue (bout de nageoire anale relu de travers)
from PIL import ImageDraw
c = Image.open(os.path.join(out, "silure-couleur.png")); a = np.array(c)[..., 3]
m = (a > 6).astype(np.uint8) * 255
X0 = int(os.environ.get("COUPE_X", "520")); Yc = int(os.environ.get("COUPE_Y", "322"))
m[Yc:, :X0] = 0
mi = Image.fromarray(m).copy(); ImageDraw.floodfill(mi, (1200, 250), 128)
garde = np.array(mi) == 128
for nom in ["couleur", "epaisseur", "nageoires", "normale", "relief"]:
    f = os.path.join(out, f"silure-{nom}.png"); im = Image.open(f); mode = im.mode; r = np.array(im)
    r[~garde] = 0
    (Image.fromarray(r) if mode == "I;16" else Image.fromarray(r, mode)).save(f)
print("nettoyé")
# couture de la boucle : la planche y montre le dos sombre vu de biais, coupé net ; on fond la couleur
# horizontalement sur cette bande pour qu'il n'y ait plus de trait vertical
A0, A1 = int(os.environ.get("FONDU_A", "430")), int(os.environ.get("FONDU_B", "640"))
f = os.path.join(out, "silure-couleur.png"); r = np.array(Image.open(f)).astype(np.float64)
rgb = r[..., :3] * (r[..., 3:] / 255.0); al = r[..., 3:] / 255.0
def boite(a, k):
    c = np.cumsum(np.pad(a, ((0, 0), (k, k), (0, 0)), mode="edge"), axis=1)
    return (c[:, 2 * k:] - c[:, :-2 * k]) / (2 * k)
k = int(os.environ.get("FONDU_K", "45"))
br = boite(rgb, k)[:, :r.shape[1]]; ba = boite(al, k)[:, :r.shape[1]]
lisse = np.where(ba > 1e-3, br / np.maximum(ba, 1e-3), rgb / np.maximum(al, 1e-3))
x = np.arange(r.shape[1]); w = np.clip(np.minimum(x - A0, A1 - x) / 50.0, 0, 1)[None, :, None]
couleur = r[..., :3] * (1 - w) + lisse * w
r[..., :3] = np.where(al > 0, couleur, r[..., :3])
Image.fromarray(np.clip(r, 0, 255).astype(np.uint8), "RGBA").save(f)
print("fondu")
