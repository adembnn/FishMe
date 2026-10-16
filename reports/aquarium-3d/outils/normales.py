"""Carte de normales (OpenGL, Y vers le haut) depuis <slug>-relief.png, pour le temps réel.
Usage : python3 -I normales.py <dossier_propres> [force]"""
import sys, os, glob
import numpy as np
from PIL import Image
dos = sys.argv[1]; force = float(sys.argv[2]) if len(sys.argv) > 2 else 3.0
for f in sorted(glob.glob(os.path.join(dos, "*-relief.png"))):
    h = np.asarray(Image.open(f).convert("F")) / 255.0
    gy, gx = np.gradient(h)
    n = np.dstack([-gx * force, gy * force, np.ones_like(h)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save(f.replace("-relief.png", "-normale.png"))
    print(os.path.basename(f))
