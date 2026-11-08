#!/usr/bin/env python3
"""VT (Vermont Fish & Wildlife Department) : espèces signalées par l'agence, niveau État + plan de mise à l'eau 2026.
Usage : python3 -I VT.py [dossier des pages brutes]   (pages : vt-sport.html, vt-pan.html, vt-sched.html)"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun_esp1 as c

BASE = "https://vtfishandwildlife.com/fish/fishing-opportunities/sportfish-of-vermont"
SOURCES = [
    {"nom": "Vermont Fish & Wildlife : Sportfish of Vermont", "url": BASE, "licence": "non précisée", "date": c.DATE},
    {"nom": "Vermont Fish & Wildlife : Panfish", "url": BASE + "/panfish", "licence": "non précisée", "date": c.DATE},
    {"nom": "Vermont Fish & Wildlife : plan de mise à l'eau 2026 (proposé, dates et nombres indicatifs)",
     "url": "https://anrweb.vt.gov/FWD/FW/FishStockingSchedule.aspx", "licence": "non précisée", "date": c.DATE},
]
ABREV = {"BKT": "brook trout", "RBT": "rainbow trout"}
COLONNES = {"2YR Rainbow": "rainbow trout", "2YR Brown Trout": "brown trout", "2YR Brook Trout": "brook trout"}
LISTE_SPORT = ["brook trout", "rainbow trout", "brown trout", "lake trout", "landlocked atlantic salmon", "rainbow smelt",
               "brown bullhead", "smallmouth bass", "largemouth bass", "yellow perch", "walleye", "northern pike",
               "chain pickerel"]
AUTRES_CITEES = ["common carp", "longnose gar", "freshwater drum", "bowfin"]


def lire(brut, nom):
    return open(os.path.join(brut, nom), encoding="utf-8", errors="ignore").read()


def construire(brut):
    etat = {"type": "etat", "id": "VT", "nom": "Vermont"}
    sport = c.texte(lire(brut, "vt-sport.html")).lower()
    pan = c.texte(lire(brut, "vt-pan.html")).lower()
    E = []
    for n in LISTE_SPORT:
        if n in sport:
            E.append(c.entree(n, etat, "liste_agence", 0))
    # la page des sportfish cite d'autres espèces dans un texte courant
    if re.search(r"carp, longnose gar, freshwater drum and bowfin", sport):
        for n in AUTRES_CITEES:
            E.append(c.entree(n, etat, "liste_agence", 0))
    # panfish : la description nomme bluegill, redbreast sunfish, rock bass, crappies noir et blanc
    for n in ["pumpkinseed", "rock bass", "bluegill"]:
        if n in pan:
            E.append(c.entree(n, etat, "liste_agence", 1))
    if "redbreast sunfish" in pan:
        E.append(c.entree("redbreast sunfish", etat, "liste_agence", 1))
    if "black and white crappie" in pan:
        E.append(c.entree("black crappie", etat, "liste_agence", 1))
        E.append(c.entree("white crappie", etat, "liste_agence", 1))
    # plan de mise à l'eau 2026
    tabs = c.tableaux(lire(brut, "vt-sched.html"))
    for rows in tabs:
        if not rows:
            continue
        h = rows[0]
        if h[:2] == ["Waterbody", "Town"] and "Week of:" in h:
            for r in rows[1:]:
                z = {"type": "plan_eau", "id": r[0], "nom": r[0]}
                for col, nom in COLONNES.items():
                    i = h.index(col)
                    if i < len(r) and r[i].strip():
                        E.append(c.entree(nom, z, "empoissonnement", 2, annee_max=2026))
        elif h[:3] == ["Waterbody", "Town", "Species"]:
            for r in rows[1:]:
                nom = ABREV.get(r[2])
                if nom:
                    z = {"type": "plan_eau", "id": r[0], "nom": r[0]}
                    E.append(c.entree(nom, z, "empoissonnement", 2, annee_max=2026))
    vus, out = set(), []
    for e in E:
        k = (e["latin"], e["zone"]["type"], e["zone"]["id"])
        if k not in vus:
            vus.add(k)
            out.append(e)
    return SOURCES, out


if __name__ == "__main__":
    brut = sys.argv[1] if len(sys.argv) > 1 else c.BRUT
    s, e = construire(brut)
    print(c.ecrire("VT", "agence", s, e), len(e), "entrées")
