"""D5 : telecharge le trace des cours d'eau (Sandre, BD Carthage, Licence Ouverte) pour les stations OFB. Python 3 seul.

Seules les entites dont le code (`code_eau` des stations) est demande sont telechargees, par paquets, UNE requete a la fois,
avec une pause entre deux et des reprises espacees (le serveur repond parfois 503). Chaque paquet est garde dans le cache :
relancer apres une coupure ne redemande rien de ce qui est deja la.

  python3 outils/hubeau/trace_sandre.py --stations stations-especes.json [--departement 94 80] [--dossier DIR]
Resultat : DIR/paquet-NNNN.geojson (defaut : outils/hubeau/cache/trace). Source : Sandre, service WFS, couche sa:CoursEau_FXX.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
URL = "https://services.sandre.eaufrance.fr/geo/sandre"
COUCHE = "sa:CoursEau_FXX"
TAILLE_PAQUET = 25
PAUSE_S = 2.0
PAS_CELLULE = 0.05
MARGE_CELLULE = 0.005
USER_AGENT = "fishme-d5-trace/1.0 (recalage des stations OFB, Licence Ouverte)"


def filtre_codes(codes) -> str:
    egaux = "".join("<PropertyIsEqualTo><ValueReference>CdEntiteHydrographique</ValueReference>"
                    f"<Literal>{c}</Literal></PropertyIsEqualTo>" for c in codes)
    ou = f"<Or>{egaux}</Or>" if len(codes) > 1 else egaux
    return f'<Filter xmlns="http://www.opengis.net/fes/2.0">{ou}</Filter>'


def url_paquet(codes) -> str:
    q = {"SERVICE": "WFS", "VERSION": "2.0.0", "REQUEST": "GetFeature", "TYPENAMES": COUCHE,
         "outputFormat": "geojson", "srsName": "EPSG:4326", "FILTER": filtre_codes(codes)}
    return URL + "?" + urllib.parse.urlencode(q)


def telecharger_paquet(codes, essais: int = 6, timeout: int = 300, log=print) -> bytes:
    return _obtenir(url_paquet(codes), essais, timeout, log)


def _attente(k: int, e) -> float:
    """Delai avant le prochain essai : croissant ; pour 429 / 503 (serveur surcharge ou qui limite), beaucoup plus long
    et au moins la valeur de `Retry-After` si le serveur la donne."""
    if isinstance(e, urllib.error.HTTPError) and e.code in (429, 503):
        try:
            demande = float(e.headers.get("Retry-After", 0)) if e.headers else 0.0
        except ValueError:
            demande = 0.0
        return max(demande, 30.0 * 2 ** k)
    return 10.0 * (k + 1)


def _obtenir(url: str, essais: int = 6, timeout: int = 300, log=print) -> bytes:
    for k in range(essais):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                corps = r.read()
            if not corps.lstrip().startswith(b"{"):
                raise ValueError("reponse qui n'est pas du JSON : " + corps[:200].decode("utf-8", "replace"))
            return corps
        except (urllib.error.URLError, TimeoutError, ValueError, ConnectionError) as e:
            attente = _attente(k, e)
            log(f"  echec ({e}) ; nouvel essai dans {attente:.0f} s")
            if k == essais - 1:
                raise
            time.sleep(attente)
    raise RuntimeError("inatteignable")


def telecharger(codes, dossier: str, log=print, pause_s: float = PAUSE_S, taille: int = TAILLE_PAQUET) -> list[str]:
    """Telecharge les entites `codes` dans `dossier` (cache par paquet). Retourne les chemins des paquets, dans l'ordre."""
    os.makedirs(dossier, exist_ok=True)
    codes = sorted(set(c for c in codes if c))
    chemins, nouveaux = [], 0
    paquets = [codes[i:i + taille] for i in range(0, len(codes), taille)]
    for i, p in enumerate(paquets):
        # le nom du fichier depend des codes : un autre jeu de stations ne reutilise pas un paquet different
        sig = hashlib.sha1(",".join(p).encode()).hexdigest()[:10]
        chemin = os.path.join(dossier, f"paquet-{sig}.geojson")
        chemins.append(chemin)
        if os.path.exists(chemin):
            continue
        if nouveaux:
            time.sleep(pause_s)
        corps = telecharger_paquet(p, log=log)
        tmp = chemin + ".tmp"
        with open(tmp, "wb") as f:
            f.write(corps)
        os.replace(tmp, chemin)
        nouveaux += 1
        log(f"  trace : paquet {i + 1}/{len(paquets)} ({len(p)} codes, {len(corps) // 1024} Ko)")
    return chemins


def cellule(lat: float, lon: float, pas: float = PAS_CELLULE) -> tuple[int, int]:
    return math.floor(lon / pas), math.floor(lat / pas)


def url_cellule(ix: int, iy: int, pas: float = PAS_CELLULE, marge: float = MARGE_CELLULE) -> str:
    lat0, lat1, lon0, lon1 = iy * pas - marge, (iy + 1) * pas + marge, ix * pas - marge, (ix + 1) * pas + marge
    q = {"SERVICE": "WFS", "VERSION": "2.0.0", "REQUEST": "GetFeature", "TYPENAMES": COUCHE, "outputFormat": "geojson",
         "srsName": "EPSG:4326", "BBOX": f"{lat0:.5f},{lon0:.5f},{lat1:.5f},{lon1:.5f},urn:ogc:def:crs:EPSG::4326"}
    return URL + "?" + urllib.parse.urlencode(q)


def telecharger_cellules(cellules, dossier: str, log=print, pause_s: float = PAUSE_S) -> dict:
    """Pour les stations sans cours d'eau : tout le trace de chaque cellule de 0,05 degre (marge 0,005 degre), une requete
    a la fois. Retourne {(ix, iy): chemin}. Cache : cell-IX_IY.geojson."""
    os.makedirs(dossier, exist_ok=True)
    sortie, nouveaux = {}, 0
    cellules = sorted(set(cellules))
    for i, (ix, iy) in enumerate(cellules):
        chemin = os.path.join(dossier, f"cell-{ix}_{iy}.geojson")
        sortie[(ix, iy)] = chemin
        if os.path.exists(chemin):
            continue
        if nouveaux:
            time.sleep(pause_s)
        corps = _obtenir(url_cellule(ix, iy), log=log)
        tmp = chemin + ".tmp"
        with open(tmp, "wb") as f:
            f.write(corps)
        os.replace(tmp, chemin)
        nouveaux += 1
        if nouveaux % 25 == 0 or i == len(cellules) - 1:
            log(f"  voisinage : {i + 1}/{len(cellules)} cellules")
    return sortie


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--stations", required=True, help="stations-especes.json (le champ code_eau de chaque station)")
    ap.add_argument("--departement", nargs="+", metavar="CODE")
    ap.add_argument("--dossier", default=os.path.join(ICI, "cache", "trace"))
    a = ap.parse_args(argv)
    with open(a.stations, encoding="utf-8") as f:
        st = json.load(f)["stations"]
    if a.departement:
        st = [s for s in st if s["dep"] in a.departement]
    codes = {s["code_eau"] for s in st if s.get("code_eau")}
    print(f"{len(st)} stations, {len(codes)} codes de cours d'eau", file=sys.stderr)
    chemins = telecharger(codes, a.dossier, log=lambda m: print(m, file=sys.stderr, flush=True))
    print(f"{len(chemins)} paquets dans {a.dossier}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
