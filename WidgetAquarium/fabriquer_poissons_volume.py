# Usage : python3 -I fabriquer_poissons_volume.py <espèce> <sortie.png> <dossier textures/propres du fil Aquarium>
# (textures : /mnt/project-files/build/aquarium/3d/textures/propres/). Sprites « en volume » pour les widgets : couleur nettoyée + ombrage d'un corps en ellipse (colonne par colonne)
# + relief des écailles + reflet. Sortie : PNG transparent, poisson vers la droite, recadré, largeur LARG.
import sys, numpy as np
from PIL import Image, ImageFilter
SRC = sys.argv[3] if len(sys.argv) > 3 else 'texsrc'
slug, out = sys.argv[1], sys.argv[2]
LARG = 600
def lire(k, mode): return np.asarray(Image.open(f'{SRC}/{slug}-{k}.png').convert(mode)).astype(np.float32) / 255
c = lire('couleur', 'RGBA'); rgb, a = c[..., :3], c[..., 3]
nag = lire('nageoires', 'L')
rel = lire('relief', 'L') - 0.5
corps = (a > 0.5) & (nag < 0.5)
H, W = a.shape
# Épaisseur : pour chaque colonne, position relative entre le haut et le bas du corps -> demi-ellipse.
z = np.zeros((H, W), np.float32)
ys = np.arange(H, dtype=np.float32)
for x in range(W):
    col = np.nonzero(corps[:, x])[0]
    if len(col) < 3: continue
    h0, h1 = col[0], col[-1]
    t = (ys - (h0 + h1) / 2) / max((h1 - h0) / 2, 1)
    zz = np.sqrt(np.clip(1 - t * t, 0, 1)) * (h1 - h0) / 2
    z[:, x] = np.where(corps[:, x], zz, 0)
# Lissage horizontal (évite les marches d'une colonne à l'autre).
def flou(m, taps, axe):
    k = np.exp(-np.linspace(-2, 2, taps) ** 2); k /= k.sum()
    return np.apply_along_axis(lambda r: np.convolve(r, k, mode='same'), axe, m)
z = flou(flou(z, 81, 1), 15, 0) * corps
gy, gx = np.gradient(z)
gx = gx * 0.6 + rel * 0.9; gy = gy + rel * 0.9
n = np.stack([-gx, -gy, np.ones_like(z)], -1); n /= np.linalg.norm(n, axis=-1, keepdims=True)
L = np.array([-0.25, -0.75, 0.62]); L /= np.linalg.norm(L)
diff = np.clip((n * L).sum(-1), 0, 1)
Hh = L + np.array([0, 0, 1.0]); Hh /= np.linalg.norm(Hh)
spec = np.clip((n * Hh).sum(-1), 0, 1) ** 40
ombre = 0.55 + 0.6 * diff                      # dos éclairé, ventre dans l'ombre
k = np.where(corps, ombre, 1.0)[..., None]
out_rgb = rgb * k + np.where(corps, spec * 0.35, 0)[..., None]
# Nageoires : un peu translucides et plus sombres à la base.
fin = (a > 0.02) & ~corps
alpha = np.where(fin, a * 0.88, a)
out_rgb = np.clip(out_rgb, 0, 1)
img = Image.fromarray((np.dstack([out_rgb, alpha]) * 255).astype(np.uint8), 'RGBA')
img = img.crop(img.getbbox())
r = LARG / img.width
img = img.resize((LARG, round(img.height * r)), Image.LANCZOS)
img.save(out, optimize=True)
