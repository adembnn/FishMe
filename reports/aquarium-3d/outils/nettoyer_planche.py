"""Nettoie une planche détourée pour en faire une texture de poisson 3D propre.

python3 -I nettoyer_planche.py <entree.png> <dossier_sortie> [nom]
Sorties : <nom>-couleur.png (RGBA, bord net, couleurs étendues hors silhouette),
          <nom>-nageoires.png (1 = nageoire fine, 0 = corps), <nom>-relief.png (écailles).
"""
import sys, os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
from skimage import color, restoration

src, out = sys.argv[1], sys.argv[2]
nom = sys.argv[3] if len(sys.argv) > 3 else os.path.splitext(os.path.basename(src))[0]
os.makedirs(out, exist_ok=True)

im = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32) / 255.0
rgb, a = im[..., :3], im[..., 3]

# 1. silhouette : plus grande pièce, trous bouchés, rognée de 3 px (liseré papier + trait gravé), bord lissé
m = a > 0.5
lab, n = ndi.label(m)
if n > 1:
    tailles = ndi.sum(m, lab, range(1, n + 1))
    m = lab == (1 + int(np.argmax(tailles)))
m = ndi.binary_fill_holes(m)
m = ndi.binary_erosion(m, iterations=3)
doux = ndi.gaussian_filter(m.astype(np.float32), 1.6)
alpha = np.clip((doux - 0.5) * 3.0 + 0.5, 0, 1)  # bord anticrénelé, ~1 px
interieur = doux > 0.5

# 2. couleur : on retire la dominante jaune du papier, un peu plus de contraste et de saturation
lab_ = color.rgb2lab(rgb)
L, A, B = lab_[..., 0], lab_[..., 1], lab_[..., 2]
B = B - 0.35 * np.median(B[interieur])  # papier jauni -> neutre
A = A - 0.20 * np.median(A[interieur])
lo, hi = np.percentile(L[interieur], [1.5, 99.5])
L = np.clip((L - lo) / max(hi - lo, 1e-3) * 92 + 4, 0, 100)
A *= 1.12; B *= 1.12
rgb2 = np.clip(color.lab2rgb(np.stack([L, A, B], -1)), 0, 1)

# 3. adoucir la trame gravée sans perdre les écailles (rendu « peint », pas « imprimé »)
rgb2 = restoration.denoise_tv_chambolle(rgb2, weight=0.025, channel_axis=-1)

# 4. étendre les couleurs du bord vers l'extérieur (pas de frange sombre au filtrage)
_, (iy, ix) = ndi.distance_transform_edt(~interieur, return_indices=True)
rgb3 = rgb2[iy, ix]

Image.fromarray(np.dstack([rgb3, alpha]).__mul__(255).astype(np.uint8), "RGBA").save(os.path.join(out, nom + "-couleur.png"))

# 5. nageoires : zones fines de la silhouette (distance au bord faible, ouverture morphologique)
d = ndi.distance_transform_edt(interieur)
# épaisseur locale = rayon du plus grand disque inscrit qui couvre le point
lt = np.zeros_like(d)
for t in np.linspace(2, d.max(), 24):
    couvert = ndi.distance_transform_edt(~(d >= t)) <= t
    lt[couvert & interieur] = t
t = np.clip((lt / d.max() - 0.22) / (0.42 - 0.22), 0, 1)
nag = (1 - t * t * (3 - 2 * t)) * interieur
nag = ndi.gaussian_filter(nag.astype(np.float32), 1.5)
Image.fromarray((np.clip(nag, 0, 1) * 255).astype(np.uint8), "L").save(os.path.join(out, nom + "-nageoires.png"))

# 5 bis. épaisseur (profil en lentille : corps bombé, nageoires presque plates), 16 bits
ep = np.power(np.clip(d / d.max(), 0, 1), 1.5)
ep = ndi.gaussian_filter(ep, 0.02 * d.max() + 1) * interieur
ep = ep / max(ep.max(), 1e-6)
Image.fromarray((ep * 65535).astype(np.uint16)).save(os.path.join(out, nom + "-epaisseur.png"))

# 6. relief des écailles : passe-haut de la luminance, centré sur 0.5
lum = L / 100.0
hp = lum - ndi.gaussian_filter(lum, 5)
hp = np.clip(0.5 + hp * 2.5, 0, 1)
hp[~interieur] = 0.5
Image.fromarray((hp * 255).astype(np.uint8), "L").save(os.path.join(out, nom + "-relief.png"))
print(nom, rgb.shape[1], "x", rgb.shape[0], "épaisseur max (px)", round(float(d.max()), 1))
