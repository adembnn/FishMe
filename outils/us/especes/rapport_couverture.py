#!/usr/bin/env python3
"""US15/US16 : écrit reports/us/couverture.md (par État : géographie et poissons, fait / partiel / absent et pourquoi).
Lit outils/us/geo/etats/<USPS>.json (bloc `couverture`), Resources/geo-us et Resources/especes-us ; rien n'est inventé.
Usage : python3 -I rapport_couverture.py [--sortie reports/us/couverture.md] [--reprise fichier.md]"""
import argparse, glob, json, os, sys

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.normpath(os.path.join(ICI, "..", "..", ".."))
GEO = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "geo-us")
ESP = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
CFG = os.path.join(RACINE, "outils", "us", "geo", "etats")


def lire(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def taille(prefixe, dossier):
    return sum(os.path.getsize(f) for f in glob.glob(os.path.join(dossier, prefixe + "-*.json"))) / 1e6


def especes_etat(u):
    prod, lieux, etat_esp = {}, 0, set()
    for f in glob.glob(os.path.join(ESP, f"{u}-*.json")):
        d = lire(f)
        p = d.get("producteur") or os.path.basename(f).split("-")[1].split(".")[0]
        n_etat = n_lieu = 0
        for e in d.get("entrees", []):
            z = e["zone"]["type"]
            if z == "etat":
                n_etat += 1
                etat_esp.add(e.get("latin"))
            else:
                n_lieu += 1
        prod[p] = (n_etat, n_lieu, len(d.get("sources", [])))
        lieux += n_lieu
    return prod, lieux, len(etat_esp)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sortie", default=os.path.join(RACINE, "reports", "us", "couverture.md"))
    ap.add_argument("--reprise")
    a = ap.parse_args()
    lignes = ["# Couverture des États-Unis (50 États + DC) : géographie et poissons signalés", "",
              "Généré par `outils/us/especes/rapport_couverture.py` à partir des fichiers embarqués et des configs `outils/us/geo/etats/`. "
              "Rien n'est dit « complet » : fait = fichier embarqué non vide ; partiel = une partie seulement, raison donnée ; absent = rien, raison donnée. "
              "Les poissons sont des « espèces signalées » (liste d'agence, relevé, empoissonnement, enregistrement GBIF CC0/CC BY, USGS NAS), jamais une rareté ni une permission.", "",
              "## Géographie", "",
              "| État | Accès publics | Plans d'eau nommés | Lignes d'eau | Mo | Licences à confirmer | Ce qui manque |", "|---|---|---|---|---|---|---|"]
    tot_geo = tot_esp = 0.0
    sp = []
    for f in sorted(glob.glob(os.path.join(CFG, "??.json"))):
        c = lire(f)
        u, cv = c["etat"], c.get("couverture", {})
        mo = taille(u, GEO)
        tot_geo += mo

        def cell(k, suf):
            b = cv.get(k, {})
            ex = os.path.exists(os.path.join(GEO, f"{u}-{suf}.json"))
            n = lire(os.path.join(GEO, f"{u}-{suf}.json")).get("compte") if ex else None
            st = b.get("statut", "?")
            if ex and n and st == "absent":
                st = "fait (config non mise à jour)"   # le fichier existe : la réalité l'emporte sur un statut périmé
            r = f" ({b['raison'][:110]})" if b.get("raison") and st in ("partiel", "absent") else ""
            return f"{'fichier ' + str(n) if ex else 'AUCUN fichier'} [{st}]{r}"
        lignes.append(f"| {u} {c.get('nom','')} | {cell('acces','points')} | {cell('plans_eau','plans-eau')} | {cell('lignes_eau','lignes-eau')} | {mo:.1f} | "
                      f"{len(cv.get('licences_a_confirmer', []))} | {'; '.join(m for m in cv.get('manque', []) if not any(x in m.lower() for x in ('non fabriqu', 'reste à lancer', 'pause', 'embarquer.py'))) or '—'} |")
        prod, lieux, ne = especes_etat(u)
        tot_esp += taille(u, ESP)
        sp.append((u, c.get("nom", ""), prod, lieux, ne))
    lignes += ["", f"Taille géographique embarquée : {tot_geo:.1f} Mo (budget indicatif 150 Mo).", "",
               "## Poissons signalés", "",
               "| État | Producteurs (entrées niveau État / entrées zone / sources) | Espèces distinctes niveau État | Entrées plan d'eau ou bassin | Verdict |", "|---|---|---|---|---|"]
    for u, nom, prod, lieux, ne in sp:
        pr = "; ".join(f"{k} {v[0]}/{v[1]}/{v[2]}" for k, v in sorted(prod.items())) or "aucun"
        if "agence" in prod and prod["agence"][1]:
            v = "liste d'agence + plans d'eau (autres zones : GBIF/NAS partiels)"
        elif "agence" in prod:
            v = "partiel (liste d'agence niveau État, sans plans d'eau)"
        elif prod:
            v = "partiel (sans liste d'agence : GBIF/NAS seulement)"
        else:
            v = "absent"
        lignes.append(f"| {u} {nom} | {pr} | {ne} | {lieux} | {v} |")
    lignes += ["", f"Taille des fichiers d'espèces : {tot_esp:.1f} Mo.", ""]
    if a.reprise and os.path.exists(a.reprise):
        lignes += [open(a.reprise, encoding="utf-8").read().rstrip(), ""]
    with open(a.sortie, "w", encoding="utf-8") as f:
        f.write("\n".join(lignes))
    print("écrit", a.sortie, f"({len(sp)} juridictions)")


if __name__ == "__main__":
    sys.exit(main())
