#!/usr/bin/env python3
"""US15 : réduit les lignes d'eau embarquées (décision de Titouan, 8 nov. : ~30 Mo pour tous les États).
Pour chaque <USPS>-lignes-eau.json : simplification plus forte (Douglas-Peucker, --tolerance degrés), coordonnées à 3 décimales, puis, tant que le
fichier dépasse --budget-mo, retrait des tronçons de plus faible ordre (on garde d'abord les cours d'eau principaux). Rien d'autre ne change :
accès, plans d'eau et avis restent intacts. Idempotent. Usage : python3 -I reduire_lignes.py [--budget-mo 0.6] [--tolerance 0.004] [dossier geo-us]"""
import argparse, glob, json, os, sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)
import normaliser  # noqa: E402

DEFAUT = os.path.join(ICI, "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "geo-us")


def ecrire(d, chemin):
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return os.path.getsize(chemin)


def simplifier(lignes, tol):
    out = []
    for cle, nom, ordre, pts in lignes:
        s = normaliser._rdp([(p[0], p[1]) for p in pts], tol)
        if len(s) >= 2:
            out.append([cle, nom, ordre, [[round(x, 3), round(y, 3)] for x, y in s]])
    return out


def reduire(chemin, budget, tol):
    d = json.load(open(chemin, encoding="utf-8"))
    avant = os.path.getsize(chemin)
    lignes = simplifier(d["lignes"], tol)
    d["lignes"] = lignes
    d["compte"] = len(lignes)
    taille = ecrire(d, chemin)
    seuil = min((l[2] for l in lignes), default=1)
    while taille > budget * 1e6 and lignes:
        seuil += 1
        lignes = [l for l in lignes if l[2] >= seuil]
        d["lignes"], d["compte"] = lignes, len(lignes)
        taille = ecrire(d, chemin)
    d["mention"] = ("Tracés USGS 3DHP très simplifiés (environ 400 m), cours d'eau nommés les plus importants de l'État : "
                    "repère visuel seulement.")
    taille = ecrire(d, chemin)
    return avant, taille, seuil, len(lignes)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dossier", nargs="?", default=DEFAUT)
    ap.add_argument("--budget-mo", type=float, default=0.6)
    ap.add_argument("--tolerance", type=float, default=0.004)
    a = ap.parse_args()
    tot_a = tot_b = 0
    for f in sorted(glob.glob(os.path.join(a.dossier, "??-lignes-eau.json"))):
        av, ap_, seuil, n = reduire(f, a.budget_mo, a.tolerance)
        tot_a += av; tot_b += ap_
        print(f"{os.path.basename(f)[:2]} {av/1e6:.2f} -> {ap_/1e6:.2f} Mo, ordre >= {seuil}, {n} tronçons")
    print(f"total {tot_a/1e6:.1f} -> {tot_b/1e6:.1f} Mo")


if __name__ == "__main__":
    main()
