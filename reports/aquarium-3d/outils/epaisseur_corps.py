"""Carte d'épaisseur v2 : le corps bombé, les nageoires fines (16 oct.).
La v1 donnait du volume aux nageoires (distance au bord), d'où des plis pâles à leur base.
Ici, colonne par colonne : on prend le haut et le bas de la silhouette, on retire les pics
(nageoires dorsale, anale, ventrales) par un percentile glissant, on force la queue à s'affiner
jusqu'au pédoncule ; le corps reçoit une section en ellipse, les nageoires 3,5 %.
Usage : python3 -I epaisseur_corps.py <dossier_propres> [slug ...]"""
import sys, os, glob
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

DEG = 4

def carte(alpha):
    m = alpha > 0.5
    H, W = m.shape
    cols = np.where(m.any(axis=0))[0]
    x0, x1 = cols.min(), cols.max()
    haut = np.full(W, np.nan); bas = np.full(W, np.nan)
    for x in range(x0, x1 + 1):
        r = np.where(m[:, x])[0]
        if len(r):
            haut[x], bas[x] = r.min(), r.max()
    L = x1 - x0 + 1
    xs = np.arange(L) / (L - 1) * 2 - 1
    def enveloppe(y, sens):
        # ajustement polynomial qui « passe sous » les pics de nageoires (ils ne font que dépasser vers l'extérieur)
        y = y.copy()
        for _ in range(40):
            c = np.polyfit(xs, y, DEG)
            f = np.polyval(c, xs)
            y = np.maximum(y, f) if sens > 0 else np.minimum(y, f)
        return f
    hh = haut[x0:x1 + 1]; bb = bas[x0:x1 + 1]
    hh = np.where(np.isnan(hh), np.nanmean(hh), hh); bb = np.where(np.isnan(bb), np.nanmean(bb), bb)
    h = enveloppe(hh, +1); b = enveloppe(bb, -1)
    h = np.maximum(h, hh); b = np.minimum(b, bb)
    demi = np.clip((b - h) / 2, 0, None)
    # queue à gauche (tête vers +X) : du pédoncule (plus étroit du tiers gauche) vers le bout, on n'élargit plus
    t = int(L * 0.35)
    ped = int(np.argmin(demi[:t] + (np.arange(t) < L * 0.03) * 1e6))
    for i in range(ped - 1, -1, -1):
        demi[i] = min(demi[i], demi[i + 1] * 0.97)
    milieu = (h + b) / 2
    milieu[:ped] = milieu[ped]
    demi = ndi.gaussian_filter1d(demi, 0.01 * L); milieu = ndi.gaussian_filter1d(milieu, 0.01 * L)
    prof = (demi / max(demi.max(), 1)) ** 0.9          # gros au milieu, fin au pédoncule
    yy = np.arange(H)[:, None]
    s = (yy - milieu[None, :]) / np.maximum(demi[None, :], 1)
    sec = np.sqrt(np.clip(1 - s ** 2, 0, 1))             # section en ellipse
    corps = np.zeros((H, W), np.float32)
    corps[:, x0:x1 + 1] = sec * prof[None, :]
    corps *= m
    ep = np.maximum(corps, 0.035 * m)
    ep = ndi.gaussian_filter(ep, 0.006 * L) * m
    zone_corps = ndi.binary_dilation(corps > 0, iterations=max(1, int(0.008 * L))) & m
    return np.clip(ep / max(ep.max(), 1e-6), 0, 1), zone_corps

def main():
    dos = sys.argv[1]
    slugs = sys.argv[2:] or sorted(os.path.basename(p)[:-12] for p in glob.glob(os.path.join(dos, "*-couleur.png")))
    for s in slugs:
        im = np.asarray(Image.open(os.path.join(dos, s + "-couleur.png")).convert("RGBA")).astype(np.float32) / 255
        ep, corps = carte(im[:, :, 3])
        Image.fromarray((ep * 65535).astype(np.uint16)).save(os.path.join(dos, s + "-epaisseur.png"))
        nag = ndi.gaussian_filter((~corps & (im[:, :, 3] > 0.5)).astype(np.float32), 2)
        Image.fromarray((np.clip(nag, 0, 1) * 255).astype(np.uint8)).save(os.path.join(dos, s + "-nageoires.png"))
        print(s, "ok")

main()
