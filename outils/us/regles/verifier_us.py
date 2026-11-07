"""Vérifie un fichier de lecture de règles américaines : schéma, sources, mots interdits.

Usage : python3 -I verifier_us.py <fichier.json> [--prod]
Affiche OK ou une ligne par défaut (sort 1). `--prod` refuse un fichier marqué fixture.
Sans bibliothèque externe : le contrôle de forme reprend schema-regle-us.json à la main.
Mots interdits (hors `citation`, qui reste mot pour mot) : autorisé, allowed, legal, permitted, authorized,
« tu peux la garder », « you can keep ».
"""
import json
import os
import re
import sys

TYPES = {"saison", "taille_min", "taille_max", "fenetre", "limite_jour", "limite_possession", "engin", "appat",
         "fermeture", "relacher", "interdit", "autre"}
CLES = {"pouces", "pouces_min", "pouces_max", "cm", "cm_min", "cm_max", "mm", "livres", "kg", "nombre", "lignes_max",
        "hamecons_max", "mode", "code", "texte"}
MODES = {"relacher_entre", "relacher_au_dessus", "relacher_en_dessous", "autre"}
EXIGE = {"taille_min": {"pouces", "cm", "mm"}, "taille_max": {"pouces", "cm", "mm"},
         "fenetre": {"pouces_min", "cm_min"}, "limite_jour": {"nombre"}, "limite_possession": {"nombre"},
         "engin": {"code", "lignes_max", "hamecons_max"}, "appat": {"code"}, "fermeture": {"code"}, "relacher": {"code"}}
VERDICTS = {"interdit", "a_verifier", "donnee_absente"}
NIVEAUX = ["etat", "zone", "plan_eau", "troncon"]
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
DATE_SAISON = re.compile(r"^(\d{4}-)?\d{2}-\d{2}$")
INTERDITS = re.compile(r"autoris|\ballowed?\b|\blegal(ly)?\b|\bpermitt?ed\b|\bauthori[sz]ed\b|tu peux (la )?garder|you can keep|ok to keep",
                       re.I)


def _textes(regle):
    """Les champs libres que le produit pourrait afficher : tout sauf la citation."""
    for cle in ("phrase", "raison_incertain", "raison_a_verifier"):
        if isinstance(regle.get(cle), str):
            yield cle, regle[cle]
    v = regle.get("valeur")
    if isinstance(v, dict) and isinstance(v.get("texte"), str):
        yield "valeur.texte", v["texte"]


def defauts(donnees):
    if not isinstance(donnees, dict) or not isinstance(donnees.get("regles"), list) or not isinstance(donnees.get("textes"), list):
        yield "il manque la liste « textes » ou « regles »"
        return
    if not re.match(r"^[A-Z]{2}$", str(donnees.get("etat"))):
        yield "etat doit être le code postal de deux lettres"
    if donnees.get("lecteur") not in ("A", "B"):
        yield "lecteur doit valoir A ou B"
    if not DATE.match(str(donnees.get("genere_le"))):
        yield "genere_le n'est pas une date AAAA-MM-JJ"
    for i, t in enumerate(donnees["textes"]):
        if not str(t.get("url", "")).startswith("https://"):
            yield f"texte {i} : url https manquante"
    vus = set()
    for i, r in enumerate(donnees["regles"]):
        q = f"règle {i} ({r.get('id')})"
        if not r.get("id") or r["id"] in vus:
            yield f"{q} : id absent ou en double"
        vus.add(r.get("id"))
        if r.get("niveau") not in (2, 3):
            yield f"{q} : niveau doit valoir 2 ou 3"
        if r.get("type") not in TYPES:
            yield f"{q} : type inconnu « {r.get('type')} »"
        if not isinstance(r.get("especes"), list) or not all(isinstance(e, str) for e in r["especes"]):
            yield f"{q} : especes doit être une liste de noms (vide = toutes)"
        p = r.get("portee")
        if not isinstance(p, dict) or p.get("niveau_portee") not in NIVEAUX:
            yield f"{q} : portee.niveau_portee absent ou inconnu"
        else:
            if p.get("etat") and p["etat"] != donnees.get("etat"):
                yield f"{q} : portee.etat « {p['etat']} » différent de l'État du fichier"
            deepest = max((k for k, c in (("zone", 1), ("plan_eau", 2), ("troncon", 3)) if p.get(k)), key=lambda k: NIVEAUX.index(k), default="etat")
            if NIVEAUX.index(p["niveau_portee"]) != NIVEAUX.index(deepest):
                yield f"{q} : niveau_portee « {p['niveau_portee']} » ne colle pas aux noms écrits (le plus fin est « {deepest} »)"
            if r.get("niveau") == 3 and p["niveau_portee"] in ("etat", "zone") and not p.get("plan_eau"):
                yield f"{q} : niveau 3 sans plan d'eau"
            if r.get("niveau") == 2 and p["niveau_portee"] in ("plan_eau", "troncon"):
                yield f"{q} : niveau 2 avec un plan d'eau"
        for champ in ("du", "au"):
            if r.get(champ) is not None and not DATE_SAISON.match(str(r[champ])):
                yield f"{q} : {champ} n'est ni AAAA-MM-JJ ni MM-JJ"
        if r.get("type") == "saison" and not (r.get("du") and r.get("au")):
            yield f"{q} : une saison demande du et au"
        v = r.get("valeur")
        if not isinstance(v, dict):
            yield f"{q} : valeur doit être un objet"
        else:
            for k, x in v.items():
                if k not in CLES:
                    yield f"{q} : clé de valeur « {k} » non prévue"
                elif k in ("texte", "code", "mode"):
                    if not isinstance(x, str) or (k == "mode" and x not in MODES):
                        yield f"{q} : valeur.{k} invalide"
                elif isinstance(x, bool) or not isinstance(x, (int, float)):
                    yield f"{q} : valeur.{k} doit être un nombre"
            if r.get("type") in EXIGE and not EXIGE[r["type"]] & v.keys():
                yield f"{q} : le type {r['type']} demande l'une des clés {', '.join(sorted(EXIGE[r['type']]))}"
        if r.get("statut") not in ("brouillon", "incertain"):
            yield f"{q} : statut « {r.get('statut')} »"
        if r.get("statut") == "incertain" and not r.get("raison_incertain"):
            yield f"{q} : incertain sans raison_incertain"
        s = r.get("source")
        if not isinstance(s, dict) or not str(s.get("url", "")).startswith("https://"):
            yield f"{q} : source.url (https) manquante"
        if not isinstance(s, dict) or not DATE.match(str(s.get("date"))):
            yield f"{q} : source.date manquante ou pas AAAA-MM-JJ"
        c = r.get("citation")
        if not isinstance(c, str) or len(c.strip()) < 3:
            yield f"{q} : citation manquante"
        elif len(c) > 200:
            yield f"{q} : citation de plus de 200 caractères"
        if not r.get("phrase"):
            yield f"{q} : phrase manquante"
        if r.get("verdict") is not None and r["verdict"] not in VERDICTS:
            yield f"{q} : verdict « {r['verdict']} » hors des trois valeurs"
        if r.get("verdict") == "interdit" and r.get("type") not in ("fermeture", "interdit", "relacher"):
            yield f"{q} : verdict « interdit » réservé à une fermeture, une interdiction ou une remise à l'eau écrites"
        for champ, texte in _textes(r):
            m = INTERDITS.search(texte)
            if m:
                yield f"{q} : mot interdit « {m.group(0)} » dans {champ}"


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    try:
        with open(argv[0], encoding="utf-8") as f:
            donnees = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print(f"illisible : {e}")
        return 1
    liste = list(defauts(donnees))
    if "--prod" in argv and donnees.get("fixture"):
        liste.append("fichier FIXTURE refusé en production")
    for d in liste[:60]:
        print(d)
    if liste:
        print(f"{len(liste)} défauts")
        return 1
    marque = " (FIXTURE, factice)" if donnees.get("fixture") else ""
    print(f"OK{marque} : {len(donnees['regles'])} règles, {len(donnees['textes'])} textes")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
