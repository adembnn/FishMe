#!/usr/bin/env python3 -I
"""Fabrique un cycle de nage de 8 images (vue de profil) pour chaque espèce.

Le poisson est tourné vers la droite. On reprend l'ondulation de l'aquarium 3D
(reports/aquarium-3d/temps-reel/nage.js, lot/aquarium ecbe9a9), vue de profil.

Le long du corps, t vaut 0 à la tête et 1 au bout de la queue. Le corps se
décale vers nous ou loin de nous, en fraction de sa longueur :
    env(t) = 0,03 + 0,97 * t^2,2          (la tête bouge à peine, la queue beaucoup)
    z(t)   = A * (env(t) * sin(phase - 2*pi*t/1,05) - 0,12 * sin(phase) * (1 - t))
    phase  = 2*pi*k/8                     (k = 0..7, les 8 images du cycle)
A est l'amplitude de l'espèce (table AMPLITUDES ci-dessous).

Pour dessiner ça de profil, trois effets, sur tout le corps :
 1. raccourci : chaque colonne est inclinée d'un angle theta = arctan(dz/dt) ;
    elle prend la largeur cos(theta). On recolle les colonnes de la tête vers
    la queue, la tête reste ancrée au bord droit ;
 2. un léger décalage vertical : la caméra est un peu au-dessus, donc ce qui
    vient vers nous (z > 0) descend de 0,35 * z * longueur du poisson ;
 3. la lumière : le RVB est multiplié par (1 - 0,18 * sin(theta)).

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
# Poissons cartoon du fil aquarium 3D (lot/aquarium 7a7e7fc, reports/aquarium-3d/widget-ocean/poissons/) : ils
# remplacent la planche de PoissonsWidget.xcassets pour les espèces qu'ils couvrent.
CARTOON = ICI / "PoissonsOcean"

# Amplitude du battement par espèce (fraction de la longueur). Table reprise de
# ESPECES dans reports/aquarium-3d/temps-reel/nage.js (lot/aquarium ecbe9a9).
AMPLITUDES = {
    "brochet": 0.05, "carpe-commune": 0.07, "truite-fario": 0.07, "sandre": 0.06,
    "tanche": 0.07, "perche": 0.07, "perche-commune": 0.07, "gardon": 0.08,
    "rotengle": 0.08, "chevesne": 0.07, "black-bass": 0.06, "breme-commune": 0.06,
    "ablette": 0.08,
}
AMPLITUDE_DEFAUT = 0.07

NB_IMAGES = 8
LARGEUR_SORTIE = 300
DECALAGE_VERTICAL = 0.35
LUMIERE = 0.18
SEUIL_ALPHA = 10


def decalage_z(t, phase, amp):
    """Décalage latéral z (fraction de la longueur) au point t du corps."""
    env = 0.03 + 0.97 * t ** 2.2
    return amp * (env * np.sin(phase - 2 * np.pi * t / 1.05) - 0.12 * np.sin(phase) * (1 - t))


def cycle_image(rgba, k, amp):
    """Retourne l'image RGBA de la phase k (alpha prémultiplié pendant le calcul)."""
    a = np.asarray(rgba, dtype=np.float64) / 255.0
    h, w, _ = a.shape
    cols = np.where((a[..., 3] * 255 > SEUIL_ALPHA).any(axis=0))[0]
    xmin, xmax = int(cols[0]), int(cols[-1])
    etendue = xmax - xmin
    phase = 2 * np.pi * k / NB_IMAGES
    # alpha prémultiplié pour que l'interpolation ne bave pas
    p = a.copy()
    p[..., :3] *= p[..., 3:4]

    # colonnes sources de la tête (xmax) vers la gauche ; t = 0 à la tête, 1 à la queue
    ix = np.arange(0, xmax + 1)[::-1]
    d = (xmax - ix).astype(np.float64)                  # distance à la tête, en pixels
    t = np.clip(d / etendue, 0.0, 1.0)
    z = decalage_z(t, phase, amp)
    pente = np.gradient(z, d / etendue)                          # dz/dt, en longueurs
    th = np.arctan(pente)
    largeur = np.cos(th)                                # largeur projetée de chaque colonne
    cumul = np.concatenate([[0.0], np.cumsum(largeur[:-1])])   # position de sortie de la colonne
    total = cumul[-1] + largeur[-1]

    # pour chaque colonne de sortie (distance u à la tête), quelle colonne source ?
    u = d
    d_src = np.interp(u, cumul, d)
    hors = u > total
    xsrc = xmax - d_src
    x0 = np.clip(np.floor(xsrc).astype(int), 0, w - 1)
    x1 = np.clip(x0 + 1, 0, w - 1)
    f = (xsrc - x0)[None, :, None]
    ech = p[:, x0] * (1 - f) + p[:, x1] * f
    ech[:, hors] = 0.0
    # lumière : plus sombre d'un côté, plus clair de l'autre (alpha intact)
    th_s = np.interp(d_src, d, th)
    ech[..., :3] *= (1 - LUMIERE * np.sin(th_s))[None, :, None]
    sortie = np.zeros_like(p)
    sortie[:, ix] = ech
    sortie[:, xmax + 1:] = p[:, xmax + 1:]

    # --- léger décalage vertical par colonne (z > 0 : vers nous, un peu plus bas) ---
    dy = np.zeros(w)
    z_s = np.interp(d_src, d, z)
    dy[ix] = DECALAGE_VERTICAL * z_s * etendue
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
        src = CARTOON / f"{slug}.png"
        if not src.exists():
            src = ENTREE / f"{slug}.imageset" / f"{slug}.png"
        if not src.exists():
            print("absent :", src, file=sys.stderr)
            continue
        base = Image.open(src).convert("RGBA")
        if src.parent == CARTOON:
            # Les planches cartoon gardent la taille relative des espèces dans un cadre fixe : on recadre sur le
            # poisson (comme les planches d'origine), le widget règle lui-même la taille à l'écran.
            boite = base.getchannel("A").point(lambda a: 255 if a > SEUIL_ALPHA else 0).getbbox()
            if boite:
                m = 6
                base = base.crop((max(boite[0] - m, 0), max(boite[1] - m, 0),
                                  min(boite[2] + m, base.width), min(boite[3] + m, base.height)))
        for k in range(NB_IMAGES):
            nom = f"{slug}-nage-{k}"
            dossier = SORTIE / f"{nom}.imageset"
            dossier.mkdir()
            img, palette = reduire(cycle_image(base, k, AMPLITUDES.get(slug, AMPLITUDE_DEFAUT)))
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
