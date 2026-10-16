#!/usr/bin/env python3 -I
"""Fabrique un cycle de nage de 8 images (vue de profil) pour chaque espèce.

Le poisson est tourné vers la droite. Vu de profil, il bat de la queue vers
nous puis loin de nous : l'arrière du corps se raccourcit puis s'élargit
horizontalement (raccourci de perspective), avec une légère variation de
lumière. Rien ne monte ni ne descend (sauf un très léger souffle du corps).

Entrée  : PoissonsWidget.xcassets/<slug>.imageset/<slug>.png
Sortie  : NagePoissons.xcassets/<slug>-nage-<k>.imageset/<slug>-nage-<k>.png
Relançable : le catalogue de sortie est reconstruit à chaque lancement.
Usage   : python3 -I fabriquer_cycle_nage.py
"""
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ICI = Path(__file__).resolve().parent
ENTREE = ICI / "PoissonsWidget.xcassets"
SORTIE = ICI / "NagePoissons.xcassets"

NB_IMAGES = 8
PIVOT = 0.55          # s au-delà duquel le corps tourne
THETA_MAX = np.radians(55.0)
RETARD = 1.4          # retard de phase : l'onde file vers la queue
LARGEUR_SORTIE = 300
SOUFFLE = 0.006       # ±0,6 % de la hauteur
SOUFFLE_DEBUT = 0.4
LUMIERE = 0.18
SEUIL_ALPHA = 10


def theta(s, k):
    """Angle de chaque colonne (rad) ; nul en avant du pivot."""
    t = np.clip((s - PIVOT) / (1.0 - PIVOT), 0.0, None)
    return THETA_MAX * t ** 1.6 * np.sin(2 * np.pi * k / NB_IMAGES - RETARD * (s - PIVOT)) * (s > PIVOT)


def cycle_image(rgba, k):
    """Retourne l'image RGBA (float, alpha prémultiplié -> non prémultiplié) de la phase k."""
    a = np.asarray(rgba, dtype=np.float64) / 255.0
    h, w, _ = a.shape
    cols = np.where((a[..., 3] * 255 > SEUIL_ALPHA).any(axis=0))[0]
    xmin, xmax = int(cols[0]), int(cols[-1])
    etendue = xmax - xmin
    # alpha prémultiplié pour que l'interpolation ne bave pas
    p = a.copy()
    p[..., :3] *= p[..., 3:4]

    xs = np.arange(w, dtype=np.float64)
    s_src = (xmax - xs) / etendue
    x_pivot = xmax - PIVOT * etendue

    # --- remappage horizontal de la zone qui tourne (colonnes x < x_pivot) ---
    sortie = p.copy()
    ix = np.arange(0, int(np.floor(x_pivot)) + 1)[::-1]       # du pivot vers la queue
    d = x_pivot - ix.astype(np.float64)                        # distance au pivot, source
    th = theta(s_src[ix], k)
    largeur = np.cos(th)                                       # largeur projetée par colonne
    cumul = np.concatenate([[0.0], np.cumsum(largeur)[:-1] + largeur[:-1] * 0.0])
    # position de sortie de chaque colonne source : cumul des largeurs précédentes
    cumul = np.concatenate([[0.0], np.cumsum(largeur[:-1])])
    total = cumul[-1]
    # colonnes de sortie : de x_pivot vers la gauche, distance u au pivot
    ox = np.arange(0, int(np.floor(x_pivot)) + 1)[::-1]
    u = x_pivot - ox.astype(np.float64)
    d_src = np.interp(u, cumul, d)                             # interpolation inverse
    hors = u > total                                           # au-delà du bout raccourci
    xsrc = x_pivot - d_src
    x0 = np.clip(np.floor(xsrc).astype(int), 0, w - 1)
    x1 = np.clip(x0 + 1, 0, w - 1)
    f = (xsrc - x0)[None, :, None]
    ech = p[:, x0] * (1 - f) + p[:, x1] * f
    ech[:, hors] = 0.0
    # lumière : plus sombre d'un côté, plus clair de l'autre (alpha intact)
    th_src = np.interp(d_src, d, th)
    ech[..., :3] *= (1 - LUMIERE * np.sin(th_src))[None, :, None]
    sortie[:, ox] = ech
    # le bord de sortie reste du vide dans la zone libérée (déjà mis à 0)

    # --- souffle vertical, uniquement à l'arrière ---
    s_out = (xmax - xs) / etendue
    t = np.clip((s_out - SOUFFLE_DEBUT) / (1.0 - SOUFFLE_DEBUT), 0, None)
    dy = SOUFFLE * h * t * np.sin(2 * np.pi * k / NB_IMAGES - RETARD * (s_out - PIVOT))
    lignes = np.arange(h, dtype=np.float64)[:, None] - dy[None, :]
    l0 = np.floor(lignes).astype(int)
    fl = (lignes - l0)[..., None]
    l0c, l1c = np.clip(l0, 0, h - 1), np.clip(l0 + 1, 0, h - 1)
    cj = np.arange(w)[None, :]
    sortie = sortie[l0c, cj] * (1 - fl) + sortie[l1c, cj] * fl

    # dé-prémultiplication
    al = sortie[..., 3:4]
    rgb = np.where(al > 1e-6, sortie[..., :3] / np.maximum(al, 1e-6), 0.0)
    out = np.concatenate([np.clip(rgb, 0, 1), np.clip(al, 0, 1)], axis=-1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA")


def reduire(img):
    """Redimensionne à 300 px de large puis allège (palette si la transparence tient)."""
    w, h = img.size
    img = img.resize((LARGEUR_SORTIE, max(1, round(h * LARGEUR_SORTIE / w))), Image.LANCZOS)
    pal = img.quantize(colors=256, method=Image.Quantize.FASTOCTREE)
    ecart = np.abs(np.asarray(pal.convert("RGBA"), dtype=int)[..., 3] - np.asarray(img)[..., 3].astype(int))
    if (ecart > 32).mean() < 0.002:
        return pal, True
    return img, False


def ecrire_contents(dossier, nom):
    contenu = {"images": [{"filename": f"{nom}.png", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1}}
    (dossier / "Contents.json").write_text(json.dumps(contenu, indent=2) + "\n")


def main():
    if SORTIE.exists():
        shutil.rmtree(SORTIE)
    SORTIE.mkdir()
    (SORTIE / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    slugs = sorted(p.name[:-len(".imageset")] for p in ENTREE.glob("*.imageset")
                   if not p.name.endswith("-silhouette.imageset"))
    total = nb_pal = nb = 0
    gros = []
    for slug in slugs:
        src = ENTREE / f"{slug}.imageset" / f"{slug}.png"
        if not src.exists():
            print("absent :", src, file=sys.stderr)
            continue
        base = Image.open(src).convert("RGBA")
        for k in range(NB_IMAGES):
            nom = f"{slug}-nage-{k}"
            dossier = SORTIE / f"{nom}.imageset"
            dossier.mkdir()
            img, palette = reduire(cycle_image(base, k))
            chemin = dossier / f"{nom}.png"
            img.save(chemin, optimize=True)
            ecrire_contents(dossier, nom)
            taille = chemin.stat().st_size
            total += taille
            nb += 1
            nb_pal += palette
            if taille > 25_000:
                gros.append((nom, taille))
    print(f"{len(slugs)} espèces, {nb} images ({nb_pal} en palette, {nb - nb_pal} en RGBA)")
    print(f"taille totale du catalogue : {total / 1e6:.2f} Mo ; moyenne {total / max(nb, 1) / 1000:.1f} Ko")
    print(f"images > 25 Ko : {len(gros)}")
    for nom, t in sorted(gros, key=lambda x: -x[1])[:10]:
        print("  ", nom, t)


if __name__ == "__main__":
    main()
