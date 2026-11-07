"""Contrôle un fichier regles-us (<USPS>.json ou index.json) contre le format du chargeur Swift (ChargementReglesUS).

Usage : python3 -I valider.py <fichier.json> [<fichier.json> ...] [--autoriser-fixture] [--json]
Sort 0 si tous les fichiers sont valides, 1 sinon (chaque erreur est dite avec le fichier, la règle et le champ).

Mêmes contrôles que le chargeur : version de format 1, État = nom du fichier, source https + date AAAA-MM-JJ, citation de 3 à 200
caractères, statut de relecture obligatoire, portée connue dans les juridictions du fichier, règle non vide, identifiants uniques,
fichier "fixture": true refusé sauf --autoriser-fixture. Un fichier nommé index.json est contrôlé comme index (sommes sha256
des fichiers voisins comprises). Aucune dépendance hors de la bibliothèque standard.
"""
import hashlib
import json
import os
import re
import sys

VERSION_FORMAT = 1
CITATION_MAX = 200
CODES = set("AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD "
            "TN TX UT VT VA WA WV WI WY".split())
STATUTS = {"non_relue", "double_lecture_confirmee", "lectures_divergentes", "relue_par_personne"}
FERMETURES = {"peche_interdite", "remise_a_eau_seulement", "espece_protegee"}
EXIGENCES = {"permis", "timbre", "permis_tribal"}
NIVEAUX = {"zone": 1, "plan_eau": 2, "troncon": 3}
ALERTES = {"reserve_tribale", "refuge_federal", "parc_national", "eau_frontaliere", "espece_listee_esa"}
JOUR = re.compile(r"^(\d{4})-(\d{2})-(\d{2})$")
MOIS_JOUR = re.compile(r"^(\d{2})-(\d{2})$")


def jour_valide(s):
    m = JOUR.match(s) if isinstance(s, str) else None
    if not m:
        return False
    a, mo, j = map(int, m.groups())
    bissextile = a % 4 == 0 and (a % 100 != 0 or a % 400 == 0)
    dans = [31, 29 if bissextile else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return a >= 1 and 1 <= mo <= 12 and 1 <= j <= dans[mo - 1]


def mois_jour_valide(s):
    m = MOIS_JOUR.match(s) if isinstance(s, str) else None
    if not m:
        return False
    mo, j = map(int, m.groups())
    return 1 <= mo <= 12 and 1 <= j <= [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][mo - 1]


def nombre(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def entier(v):
    return isinstance(v, int) and not isinstance(v, bool)


def https(url):
    return isinstance(url, str) and re.match(r"^https://[^/\s]+", url) is not None


class Erreurs:
    def __init__(self):
        self.liste = []

    def ajouter(self, contexte, message):
        self.liste.append(f"{contexte} : {message}")


def periode(obj, contexte, e):
    if obj is None:
        return
    du, au = obj.get("du"), obj.get("au")
    if (du is None) != (au is None):
        e.ajouter(contexte, "« du » et « au » vont ensemble")
    for nom, v in (("du", du), ("au", au)):
        if v is not None and not mois_jour_valide(v):
            e.ajouter(contexte, f"« {nom} » : MM-JJ attendu ({v!r})")


def longueur(obj, contexte, e):
    if obj is None:
        return
    cles = [k for k in ("pouces", "cm", "mm") if k in obj]
    if len(cles) != 1 or not nombre(obj[cles[0]]) or obj[cles[0]] <= 0:
        e.ajouter(contexte, "une seule unité (pouces, cm ou mm), valeur positive")


def source(s, contexte, e, citation_obligatoire):
    if not isinstance(s, dict):
        e.ajouter(contexte, "source manquante")
        return
    if not s.get("url"):
        e.ajouter(contexte, "source.url manquante")
    elif not https(s["url"]):
        e.ajouter(contexte, f"source non https ({s['url']})")
    if "date" not in s:
        e.ajouter(contexte, "source.date manquante")
    elif not jour_valide(s["date"]):
        e.ajouter(contexte, f"source.date : AAAA-MM-JJ attendu ({s['date']!r})")
    c = (s.get("citation") or "").strip()
    if len(c) > CITATION_MAX:
        e.ajouter(contexte, f"citation de {len(c)} caractères ({CITATION_MAX} au plus)")
    if citation_obligatoire and len(c) < 3:
        e.ajouter(contexte, "source.citation manquante (3 caractères au moins)")


def valider_fichier(d, nom_fichier, autoriser_fixture, e):
    code = os.path.splitext(os.path.basename(nom_fichier))[0].removesuffix("-FIXTURE")
    if d.get("format") != VERSION_FORMAT:
        e.ajouter("fichier", f"version de format non gérée ({d.get('format')!r})")
        return
    if d.get("fixture") is True and not autoriser_fixture:
        e.ajouter("fichier", "fichier FIXTURE refusé hors des tests (--autoriser-fixture)")
    if d.get("etat") not in CODES:
        e.ajouter("fichier", f"État inconnu ({d.get('etat')!r})")
    elif d["etat"] != code:
        e.ajouter("fichier", f"État {d['etat']} dans un fichier nommé {code}")
    etat = d.get("etat")
    for champ in ("version", "nom_etat"):
        if not d.get(champ):
            e.ajouter("fichier", f"« {champ} » manquant")
    if not jour_valide(d.get("genere_le")):
        e.ajouter("fichier", "genere_le : AAAA-MM-JJ attendu")
    if d.get("couverture") not in (2, 3):
        e.ajouter("fichier", "couverture : 2 ou 3 attendu")
    if d.get("lien_agence") is not None and not https(d["lien_agence"]):
        e.ajouter("fichier", "lien_agence non https")

    connues = {f"US-{etat}": 0}
    for i, j in enumerate(d.get("juridictions") or []):
        ctx = f"juridiction[{i}]"
        jid = j.get("id")
        if not jid or re.search(r"\s", jid):
            e.ajouter(ctx, "id manquant ou avec espaces")
            continue
        if jid in connues:
            e.ajouter(ctx, f"identifiant en double ({jid})")
        if j.get("niveau") not in NIVEAUX:
            e.ajouter(ctx, "niveau : zone, plan_eau ou troncon attendu")
            continue
        if not j.get("nom"):
            e.ajouter(ctx, "nom manquant")
        if j.get("huc8") is not None and not re.match(r"^\d{8}$", str(j["huc8"])):
            e.ajouter(ctx, "huc8 : 8 chiffres attendus")
        for a in j.get("alertes") or []:
            if a not in ALERTES:
                e.ajouter(ctx, f"alerte inconnue ({a})")
        if j.get("lien_agence") is not None and not https(j["lien_agence"]):
            e.ajouter(ctx, "lien_agence non https")
        connues[jid] = NIVEAUX[j["niveau"]]
    for i, j in enumerate(d.get("juridictions") or []):
        jid, parent = j.get("id"), j.get("parent") or f"US-{etat}"
        if jid in connues and j.get("niveau") in NIVEAUX:
            if parent not in connues:
                e.ajouter(f"juridiction[{i}]", f"parent inconnu ({parent})")
            elif connues[parent] >= NIVEAUX[j["niveau"]]:
                e.ajouter(f"juridiction[{i}]", "un enfant doit être plus précis que son parent")

    ids = set()
    for i, r in enumerate(d.get("regles") or []):
        rid = r.get("id")
        if not rid:
            e.ajouter(f"regle[{i}]", "id manquant")
            continue
        ctx = f"règle {rid}"
        if "r:" + rid in ids:
            e.ajouter(ctx, "identifiant en double")
        ids.add("r:" + rid)
        if r.get("portee") not in connues:
            e.ajouter(ctx, f"portée « {r.get('portee')} » absente des juridictions du fichier")
        if "espece" in r and (not isinstance(r["espece"], str) or not r["espece"].strip()):
            e.ajouter(ctx, "espece vide (omettre le champ pour « toutes espèces »)")
        source(r.get("source"), ctx, e, True)
        if not r.get("statut"):
            e.ajouter(ctx, "statut de relecture manquant")
        elif r["statut"] not in STATUTS:
            e.ajouter(ctx, f"statut inconnu ({r['statut']})")
        if "couverture" in r and r["couverture"] not in (2, 3):
            e.ajouter(ctx, "couverture : 2 ou 3 attendu")
        contenu = False
        if r.get("saison") is not None:
            periode(r["saison"], ctx + " saison", e)
            contenu = True
        t = r.get("tailles") or {}
        longueur(t.get("minimale"), ctx + " tailles.minimale", e)
        longueur(t.get("maximale"), ctx + " tailles.maximale", e)
        if t.get("fenetre") is not None:
            w = t["fenetre"]
            longueur(w.get("basse"), ctx + " fenetre.basse", e)
            longueur(w.get("haute"), ctx + " fenetre.haute", e)
            try:
                if "cm" in w["basse"]:
                    b = w["basse"]["cm"] / 2.54
                elif "mm" in w["basse"]:
                    b = w["basse"]["mm"] / 25.4
                else:
                    b = w["basse"]["pouces"]
                if "cm" in w["haute"]:
                    h = w["haute"]["cm"] / 2.54
                elif "mm" in w["haute"]:
                    h = w["haute"]["mm"] / 25.4
                else:
                    h = w["haute"]["pouces"]
                if not b < h:
                    e.ajouter(ctx, "fenetre : basse < haute attendu")
            except (KeyError, TypeError):
                e.ajouter(ctx, "fenetre : basse et haute attendues")
        if any(t.get(k) for k in ("minimale", "maximale", "fenetre")):
            contenu = True
        lim = r.get("limites") or {}
        for k in ("prise", "possession"):
            if k in lim:
                if not entier(lim[k]) or lim[k] < 0:
                    e.ajouter(ctx, f"limites.{k} : entier positif ou nul attendu")
                else:
                    contenu = True
        if r.get("engins") or r.get("appats"):
            contenu = True
        for k, f in enumerate(r.get("fermetures") or []):
            if f.get("type") not in FERMETURES:
                e.ajouter(f"{ctx} fermeture[{k}]", f"type inconnu ({f.get('type')!r})")
            if not f.get("motif"):
                e.ajouter(f"{ctx} fermeture[{k}]", "motif manquant")
            periode(f, f"{ctx} fermeture[{k}]", e)
            contenu = True
        a = r.get("age")
        if a is not None:
            lo, hi = a.get("min"), a.get("max")
            if (lo is not None and (not entier(lo) or lo < 0)) or (hi is not None and not entier(hi)) or (lo is not None and hi is not None and lo > hi):
                e.ajouter(ctx, "age : min <= max, entiers positifs")
        if r.get("valide_jusqua") is not None and not jour_valide(r["valide_jusqua"]):
            e.ajouter(ctx, "valide_jusqua : AAAA-MM-JJ attendu")
        if not contenu:
            e.ajouter(ctx, "règle sans aucune contrainte")
    for i, x in enumerate(d.get("exigences") or []):
        xid = x.get("id")
        if not xid:
            e.ajouter(f"exigence[{i}]", "id manquant")
            continue
        ctx = f"exigence {xid}"
        if "e:" + xid in ids:
            e.ajouter(ctx, "identifiant en double")
        ids.add("e:" + xid)
        if x.get("portee") not in connues:
            e.ajouter(ctx, f"portée « {x.get('portee')} » absente des juridictions du fichier")
        if x.get("type") not in EXIGENCES:
            e.ajouter(ctx, f"type inconnu ({x.get('type')!r})")
        if not x.get("nom"):
            e.ajouter(ctx, "nom manquant")
        if x.get("prix_dollars") is not None and (not nombre(x["prix_dollars"]) or x["prix_dollars"] < 0):
            e.ajouter(ctx, "prix_dollars : nombre positif attendu")
        source(x.get("source"), ctx, e, False)
        if not x.get("statut"):
            e.ajouter(ctx, "statut de relecture manquant")
        elif x["statut"] not in STATUTS:
            e.ajouter(ctx, f"statut inconnu ({x['statut']})")


def valider_index(d, chemin, e):
    if d.get("format") != VERSION_FORMAT:
        e.ajouter("index", f"version de format non gérée ({d.get('format')!r})")
        return
    if not d.get("version"):
        e.ajouter("index", "« version » manquant")
    if not jour_valide(d.get("date")):
        e.ajouter("index", "date : AAAA-MM-JJ attendu")
    dossier = os.path.dirname(os.path.abspath(chemin))
    for code, ent in (d.get("etats") or {}).items():
        ctx = f"etats.{code}"
        if code not in CODES:
            e.ajouter(ctx, "code USPS inconnu")
        if ent.get("niveau") not in (2, 3):
            e.ajouter(ctx, "niveau : 2 ou 3 attendu")
        if ent.get("expire_min") is not None and not jour_valide(ent["expire_min"]):
            e.ajouter(ctx, "expire_min : AAAA-MM-JJ attendu")
        verifier_somme(dossier, f"{code}.json", ent.get("sha256"), ctx, e, obligatoire_si_absent_du_dossier=True)
    n1 = d.get("niveau1")
    if n1 is not None:
        if not n1.get("fichier"):
            e.ajouter("niveau1", "« fichier » manquant")
        if not n1.get("etat_de_la_donnee"):
            e.ajouter("niveau1", "« etat_de_la_donnee » manquant")
        if not jour_valide(n1.get("date")):
            e.ajouter("niveau1", "date : AAAA-MM-JJ attendu")
        if n1.get("fichier"):
            verifier_somme(dossier, n1["fichier"], n1.get("sha256"), "niveau1", e, obligatoire_si_absent_du_dossier=True)


def verifier_somme(dossier, nom, attendue, ctx, e, obligatoire_si_absent_du_dossier):
    chemin = os.path.join(dossier, nom)
    if not os.path.exists(chemin):
        if obligatoire_si_absent_du_dossier:
            e.ajouter(ctx, f"fichier {nom} absent du dossier de l'index")
        return
    if attendue:
        with open(chemin, "rb") as f:
            if hashlib.sha256(f.read()).hexdigest() != attendue.lower():
                e.ajouter(ctx, f"somme sha256 différente de celle de l'index pour {nom}")


def valider(chemin, autoriser_fixture=False):
    """Liste des erreurs du fichier (vide si valide)."""
    e = Erreurs()
    try:
        with open(chemin, "rb") as f:
            d = json.loads(f.read().decode("utf-8"))
    except (OSError, ValueError) as ex:
        e.ajouter("fichier", f"illisible ({ex})")
        return e.liste
    if not isinstance(d, dict):
        e.ajouter("fichier", "un objet JSON est attendu")
    elif os.path.basename(chemin) == "index.json":
        valider_index(d, chemin, e)
    else:
        valider_fichier(d, chemin, autoriser_fixture, e)
    return e.liste


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 2
    autoriser = "--autoriser-fixture" in argv
    sortie = {}
    for chemin in args:
        sortie[chemin] = valider(chemin, autoriser)
    if "--json" in argv:
        print(json.dumps(sortie, ensure_ascii=False, indent=1))
    else:
        for chemin, erreurs in sortie.items():
            print(f"{'OK    ' if not erreurs else 'ERREUR'} {chemin}")
            for m in erreurs:
                print(f"   - {m}")
    return 0 if all(not v for v in sortie.values()) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
