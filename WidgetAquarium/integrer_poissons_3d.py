#!/usr/bin/env python3
"""Range les poissons rendus en volume (fil Aquarium) dans NagePoissons.xcassets, à la place des anciens.

Usage : python3 integrer_poissons_3d.py <dossier poissons-3d> [slug ...]
Le dossier contient un sous-dossier par espèce : <slug>-nage-k.png, <slug>-lacet-<a>-k.png, <slug>-lacet-m<a>-k.png.
Les images sont réduites à LARGEUR px (assez pour le grand widget en @3x) et réduites en 256 couleurs avec
transparence : la mémoire du widget est petite. Même cadre pour tous les angles : aucun recadrage par image.
"""
import json, re, shutil, sys
from pathlib import Path
from PIL import Image

LARGEUR = 320
ICI = Path(__file__).resolve().parent
CATALOGUE = ICI / "NagePoissons.xcassets"
# Dossier du fil Aquarium -> identifiant de l'espèce dans l'app (especes.json).
ALIAS = {"silure": "silure-glane", "perche": "perche-commune", "barbeau": "barbeau-fluviatile", "ombre": "ombre-commun", "carassin": "carassin-commun"}
ESPECES = ICI.parent / "Packages/Core/Sources/Core/Resources/especes.json"


def identifiant(source: str) -> str:
    """Le dossier s'appelle comme l'espèce, ou en abrégé (silure pour silure-glane) : on retrouve l'identifiant."""
    if source in ALIAS:
        return ALIAS[source]
    try:
        ids = {e["id"] for e in json.loads(ESPECES.read_text())}
    except (OSError, ValueError, KeyError, TypeError):
        return source
    if source in ids:
        return source
    proches = [i for i in ids if i.startswith(source + "-")]
    if len(proches) == 1:
        return proches[0]
    print(f"attention : {source} n'est pas une espèce de especes.json", file=sys.stderr)
    return source


def ranger(dossier: Path, source: str) -> int:
    slug = identifiant(source)
    # Les anciens cycles de l'espèce partent (pas ceux d'une espèce dont le nom commence pareil).
    motif = re.compile(rf"^{re.escape(slug)}-(nage|vue-[12]|lacet-m?\d+)-\d+\.imageset$")
    for ancien in CATALOGUE.iterdir():
        if motif.match(ancien.name):
            shutil.rmtree(ancien)
    fichiers = [png for png in sorted(dossier.glob(f"{source}-*.png"))
                if re.match(rf"^{re.escape(source)}-(nage|lacet-m?\d+)-\d+$", png.stem)]
    # Un seul cadre pour toute l'espèce (l'union des contours de tous les angles, 4 px de marge) : le poisson
    # remplit sa largeur comme les autres, et il ne bouge pas d'un angle à l'autre.
    boite = None
    for png in fichiers:
        b = Image.open(png).getchannel("A").getbbox()
        if b:
            boite = b if boite is None else (min(boite[0], b[0]), min(boite[1], b[1]),
                                             max(boite[2], b[2]), max(boite[3], b[3]))
    n = 0
    for png in fichiers:
        nom = slug + png.stem[len(source):]
        image = Image.open(png).convert("RGBA")
        if boite:
            image = image.crop((max(boite[0] - 4, 0), max(boite[1] - 4, 0),
                                min(boite[2] + 4, image.width), min(boite[3] + 4, image.height)))
        hauteur = round(image.height * LARGEUR / image.width)
        image = image.resize((LARGEUR, hauteur), Image.LANCZOS).quantize(256, method=Image.Quantize.FASTOCTREE)
        cible = CATALOGUE / f"{nom}.imageset"
        cible.mkdir()
        image.save(cible / f"{nom}.png", optimize=True)
        (cible / "Contents.json").write_text(json.dumps(
            {"images": [{"filename": f"{nom}.png", "idiom": "universal"}],
             "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
        n += 1
    return n


if __name__ == "__main__":
    racine = Path(sys.argv[1])
    slugs = sys.argv[2:] or sorted(p.name for p in racine.iterdir() if p.is_dir())
    for slug in slugs:
        print(slug, "->", identifiant(slug), ranger(racine / slug, slug), "images")
