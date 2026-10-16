"""Nageoires trop blanches (16 oct.) : sur les planches, la membrane claire laisse voir le papier ;
en 3D sous une lumière du dessus elle sort blanche. On assombrit et on teinte, dans les nageoires
seulement, les pixels clairs et peu saturés, vers la couleur moyenne du dos du poisson.
Usage : python3 -I teinter_nageoires.py <dossier_propres> [slug ...]  (garde une copie -couleur-avant.png)"""
import sys, os, glob, shutil
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

def main():
    dos = sys.argv[1]
    slugs = sys.argv[2:] or sorted(os.path.basename(p)[:-12] for p in glob.glob(os.path.join(dos, "*-couleur.png")))
    for s in slugs:
        f = os.path.join(dos, s + "-couleur.png"); avant = os.path.join(dos, s + "-couleur-avant.png")
        if not os.path.exists(avant):
            shutil.copy(f, avant)
        im = np.asarray(Image.open(avant).convert("RGBA")).astype(np.float32) / 255
        rgb, a = im[:, :, :3], im[:, :, 3]
        nag = np.asarray(Image.open(os.path.join(dos, s + "-nageoires.png"))).astype(np.float32) / 255
        mx, mn = rgb.max(2), rgb.min(2)
        sat = (mx - mn) / np.maximum(mx, 1e-4)
        clair = np.clip((mx - 0.42) / 0.15, 0, 1) * np.clip((0.22 - sat) / 0.12, 0, 1)
        poids = ndi.gaussian_filter(clair * nag * (a > 0.5), 1.5) * 0.85
        corps = (nag < 0.1) & (a > 0.5)
        H = rgb.shape[0]
        haut = corps & (np.arange(H)[:, None] < np.where(corps.any(1))[0].mean())
        teinte = np.median(rgb[haut], axis=0)
        cible = rgb * 0.6 * (0.5 + 0.5 * teinte / max(teinte.max(), 1e-4))
        out = rgb * (1 - poids[..., None]) + cible * poids[..., None]
        Image.fromarray((np.dstack([out, a]) * 255).clip(0, 255).astype(np.uint8)).save(f)
        print(s, "pixels touchés %.1f %%" % (100 * (poids > 0.2).sum() / max((a > 0.5).sum(), 1)))

main()
