"""Classe chaque désaccord entre les lectures A et B d'un État et écrit <USPS>/desaccords.md.

Usage (depuis la racine du dépôt) : python3 -I outils/us/regles/donnees/analyser_desaccords.py WI MN

Lit <USPS>/lecture-a.json, <USPS>/lecture-b.json et <USPS>/consensus.json (sortie de consensus_us.py --sortie).
Un désaccord est : une règle confirmée mais « incertain » d'un côté, ou une règle d'une seule lecture (appariée, si possible, à la
règle la plus proche de l'autre lecture : même famille de type, même espèce, citation voisine). Classes :
  (i)   forme sans conséquence : mêmes valeurs, écriture différente (type, code, portée plus large, date attachée, groupe d'espèces)
  (ii)  conflit de fond : valeur différente des deux côtés, deux lectures sans réserve
  (iii) couverture : une lecture a lu une règle que l'autre n'a pas lue
  (iv)  incertain d'un côté : l'un des deux lecteurs a marqué la règle « incertain »
Le classement est automatique, puis corrigé à la main par REVUE (identifiant -> (classe, avis sur l'outil)).
"""
import importlib.util
import json
import os
import re
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("consensus_us", os.path.join(os.path.dirname(ICI), "consensus_us.py"))
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)

FAMILLES = [{"limite_jour", "limite_possession", "autre"}, {"taille_min", "taille_max", "fenetre", "autre"},
            {"saison", "fermeture", "relacher"}, {"engin", "interdit", "appat", "autre"}]

# Relecture à la main (lot us-consensus, 7 nov. 2026) : (classe, avis sur l'outil). Clé : id de la règle A, sinon id de la règle B.
REVUE = {
    # Wisconsin
    "WI-sturgeon-fermeture-autres": ("i", "trop strict, sans correction possible sûre : même fermeture des autres eaux intérieures, codes libres "
                                     "différents ; A la met à l'échelle de l'État, ce qui serait faux sur les eaux listées"),
    "WI-engin-pas_sinker_release": ("i", "juste : B a réuni deux alinéas (armes à feu, largage de plomb) en une règle ; rien n'est comparable code à code"),
    "wi-b-084": ("iii", "juste : règle (conservation des filets, preuve photo) lue par B seulement"),
}


def jetons(texte):
    return {m for m in c.norm(texte).split() if len(m) > 2}


def jaccard(x, y):
    return len(x & y) / len(x | y) if x | y else 0.0


def meme_famille(ta, tb):
    return ta == tb or any(ta in f and tb in f for f in FAMILLES)


def especes_liees(a, b):
    ea, eb = c.especes(a), c.especes(b)
    return bool(ea & eb) or c.especes_couvertes(ea, eb) or c.especes_couvertes(eb, ea)


def score(a, b):
    if not meme_famille(a["type"], b["type"]) or not especes_liees(a, b):
        return 0.0
    na, nb = c.nombres(a.get("valeur")), c.nombres(b.get("valeur"))
    proche = jaccard(jetons(a.get("citation")), jetons(b.get("citation")))
    if {a["type"], b["type"]} <= {"engin", "interdit", "appat", "autre"} and proche < 0.25 and not (na and c.memes_nombres(na, nb)):
        return 0.0  # engins, appâts : sans nombre commun, seule une citation voisine dit que c'est le même alinéa
    s = 3.0 * (a["type"] == b["type"])
    s += 2.0 * (bool(na) and c.memes_nombres(na, nb))
    s += 1.0 * (c.dates(a) == c.dates(b) and c.dates(a) != (None, None))
    s += c.proximite(a, b)
    s += 4.0 * jaccard(jetons(a.get("citation")), jetons(b.get("citation")))
    return s


def ecart(a, b):
    """Ce qui diffère entre a et b, en mots ; liste vide si rien de comparé ne diffère."""
    d = []
    if a["type"] != b["type"]:
        d.append(f"type {a['type']} / {b['type']}")
    if c.especes(a) != c.especes(b):
        d.append(f"espèces {sorted(c.especes(a))} / {sorted(c.especes(b))}")
    if c.dates(a) != c.dates(b):
        d.append(f"dates {c.dates(a)} / {c.dates(b)}")
    na, nb = c.nombres(a.get("valeur")), c.nombres(b.get("valeur"))
    if not c.memes_nombres(na, nb):
        d.append(f"nombres {na} / {nb}")
    for cle in c.TEXTUELS:
        va, vb = (a.get("valeur") or {}).get(cle), (b.get("valeur") or {}).get(cle)
        if va != vb and (va is not None or vb is not None):
            d.append(f"{cle} {va} / {vb}")
    pa, pb = c.portee(a), c.portee(b)
    if (pa["niveau"], pa["zone"], pa["eau"]) != (pb["niveau"], pb["zone"], pb["eau"]):
        d.append(f"portée « {lieu(a)} » / « {lieu(b)} »")
    return d


def lieu(r):
    p = r.get("portee") or {}
    return p.get("troncon") or p.get("plan_eau") or p.get("zone") or "État"


def valeurs_conflit(a, b):
    """Vrai si une valeur comparable diffère vraiment (nombre de même clé, date d'une saison, code d'une même famille chiffrée)."""
    na, nb = c.nombres(a.get("valeur")), c.nombres(b.get("valeur"))
    communes = na.keys() & nb.keys()
    if any(abs(na[k] - nb[k]) > 0.15 for k in communes):
        return True
    ma, mb = (a.get("valeur") or {}).get("mode"), (b.get("valeur") or {}).get("mode")
    if ma and mb and ma != mb:
        return True
    if a["type"] == b["type"] and a["type"] in ("saison", "fermeture", "relacher"):
        da, db = c.dates(a), c.dates(b)
        if da != (None, None) and db != (None, None) and da != db and c.portee(a)["zone"] == c.portee(b)["zone"]:
            return True
    return False


def classer(a, b):
    """(classe, cause, avis sur l'outil) pour une paire (a de A, b de B), l'un des deux pouvant manquer."""
    seul = a or b
    cle = (a or {}).get("id") if a else b.get("id")
    if cle in REVUE or (b and b.get("id") in REVUE):
        classe, avis = REVUE.get(cle) or REVUE[b["id"]]
        return classe, "; ".join(ecart(a, b)) if a and b else "", avis
    if not (a and b):
        cote = "A" if a else "B"
        autre = "B" if a else "A"
        inc = " (marquée incertain)" if seul.get("statut") == "incertain" else ""
        return "iii", f"lue par {cote} seulement{inc}", f"juste : rien à comparer dans la lecture {autre}"
    d = ecart(a, b)
    if a.get("statut") == "incertain" or b.get("statut") == "incertain":
        return "iv", "; ".join(d) or "valeurs identiques", "juste : une lecture incertaine ne fonde jamais « interdit »"
    na, nb = c.nombres(a.get("valeur")), c.nombres(b.get("valeur"))
    if a["type"] != b["type"] and na and nb and not c.memes_nombres(na, nb):
        return "iii", "faits différents du même passage : " + "; ".join(d), \
            "juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)"
    if valeurs_conflit(a, b):
        return "ii", "; ".join(d), "juste : deux valeurs différentes"
    causes = "; ".join(d) or "identiques sur tout ce qui est comparé"
    if any(x.startswith("portée") for x in d) and not any(x.startswith(("nombres", "type", "code", "dates")) for x in d):
        return "i", causes, "juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée"
    if any(x.startswith("dates") for x in d) and a["type"] == b["type"]:
        return "i", causes, ("juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, "
                             "la version sans date (plus large) reste à vérifier")
    if any(x.startswith("code") for x in d) and not any(x.startswith(("nombres", "type")) for x in d):
        return "i", causes, "trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)"
    if any(x.startswith("type") for x in d):
        return "i", causes, "trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)"
    if any(x.startswith("espèces") for x in d):
        return "i", causes, "juste : espèces écrites différemment (groupe d'un côté)"
    if any(x.startswith("nombres") for x in d):
        return "i", causes, "trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)"
    return "i", causes, "à revoir"


def court(texte, n=200):
    texte = re.sub(r"\s+", " ", texte or "").strip()
    return texte if len(texte) <= n else texte[: n - 1] + "…"


def apparier(seules_a, seules_b, tous_a, tous_b):
    """Paires (a, b) : chaque règle d'une seule lecture avec la plus proche de l'autre (une règle de l'autre côté peut servir deux fois
    si elle est elle-même confirmée ou seule) ; None quand rien n'est proche."""
    paires, pris_b = [], set()
    for a in seules_a:
        cand = sorted(((score(a, b), i) for i, b in enumerate(tous_b)), reverse=True)
        if cand and cand[0][0] >= 3.0:
            b = tous_b[cand[0][1]]
            paires.append((a, b))
            pris_b.add(b["id"])
        else:
            paires.append((a, None))
    for b in seules_b:
        if b["id"] in pris_b:
            continue
        cand = sorted(((score(a, b), i) for i, a in enumerate(tous_a)), reverse=True)
        paires.append((tous_a[cand[0][1]], b) if cand and cand[0][0] >= 3.0 else (None, b))
    return paires


def decrire(r):
    if not r:
        return "—"
    v = {k: x for k, x in (r.get("valeur") or {}).items() if k != "texte"}
    dates = f" {r.get('du')}→{r.get('au')}" if r.get("du") or r.get("au") else ""
    st = " [incertain]" if r.get("statut") == "incertain" else ""
    return f"`{r['id']}` {r['type']} {', '.join(r.get('especes') or ['toutes'])} ({lieu(r)}){dates} {json.dumps(v, ensure_ascii=False)}{st}"


def analyser(etat):
    lire = lambda n: json.load(open(os.path.join(ICI, etat, n), encoding="utf-8"))
    la, lb, cons = lire("lecture-a.json")["regles"], lire("lecture-b.json")["regles"], lire("consensus.json")
    par_id_a = {r["id"]: r for r in la}
    par_id_b = {r["id"]: r for r in lb}
    lignes = []
    # Confirmées mais incertaines.
    for r in cons["incertaines"]:
        if r.get("confirmee_par_lecture") == "A":
            a, b = par_id_a[r["lecture_a"]["id"]], par_id_b[r["id"]]
        else:
            a, b = par_id_a[r["id"]], par_id_b[r["lecture_b"]["id"]]
        lignes.append(("iv", a, b, "valeurs concordantes, mais un lecteur a écrit « incertain »" + (" (la règle confirmée est celle de B, plus fine)" if r.get("confirmee_par_lecture") == "A" else ""),
                       "juste : concordance gardée hors du chargement (incertaine)", "confirmée incertaine"))
    seules_a = [par_id_a[r["id"]] for r in cons["a_verifier"]["seulement_a"]]
    seules_b = [par_id_b[r["id"]] for r in cons["a_verifier"]["seulement_b"]]
    for a, b in apparier(seules_a, seules_b, la, lb):
        classe, cause, avis = classer(a, b)
        etat_paire = "A seule" if a in seules_a and b not in seules_b else "B seule" if b in seules_b and a not in seules_a else "A et B seules"
        if a in seules_a and b and b not in seules_b:
            etat_paire = "A seule (B appariée est confirmée ailleurs)"
        if b in seules_b and a and a not in seules_a:
            etat_paire = "B seule (A appariée est confirmée ailleurs)"
        lignes.append((classe, a, b, cause, avis, etat_paire))
    return la, lb, cons, lignes


NOTES_LAXISTE = {
    "MN": ["Relecture : les limites de truite de B (lacs l'été et l'hiver, ruisseaux du Sud-Est : 5) sont confirmées par "
           "`MN-brook-ruisseau-limite` de A, écrite à l'échelle de l'État alors que A parle des ruisseaux (le mot n'est que dans "
           "l'identifiant). La valeur est juste partout (5 dans le livret, cité par B), mais l'appui est fortuit : **trop laxiste en "
           "principe**, sans erreur ici. Même chose pour le touladi d'hiver (2) confirmé par la limite d'été de A (2).", ""],
    "WI": ["Relecture : les règles de zone de B (« Most other inland waters », « Southern Bass Management Zone ») confirmées par des "
           "règles d'État de A ont la même valeur dans le livret : appuis justes. Les espèces de crapet (black, white) confirmées par "
           "« Crappie » de A : justes (le livret donne une seule ligne crappie).", ""],
}


def confirmees_par_plus_large(etat, cons):
    lire = lambda n: json.load(open(os.path.join(ICI, etat, n), encoding="utf-8"))
    par_id = {r["id"]: r for r in lire("lecture-a.json")["regles"] + lire("lecture-b.json")["regles"]}
    sortie = []
    for r in cons["regles"] + cons["incertaines"]:
        autre = par_id.get((r.get("lecture_b") or r.get("lecture_a") or {}).get("id"))
        if not autre:
            continue
        motifs = []
        if c.portee(r)["niveau"] > c.portee(autre)["niveau"]:
            motifs.append("portée plus fine")
        if c.dates(r) != c.dates(autre):
            motifs.append("valeur datée")
        if c.especes(r) != c.especes(autre):
            motifs.append("espèce d'un groupe")
        if motifs:
            sortie.append((r, autre, ", ".join(motifs)))
    return sortie


NOMS = {"i": "(i) forme sans conséquence", "ii": "(ii) conflit de fond", "iii": "(iii) couverture", "iv": "(iv) incertain d'un côté"}


def ecrire(etat):
    la, lb, cons, lignes = analyser(etat)
    compte = {k: sum(1 for l in lignes if l[0] == k) for k in NOMS}
    conf = len(cons["regles"]) + len(cons["incertaines"])
    out = [f"# {etat} : désaccords entre les lectures A et B", "",
           f"Généré par `outils/us/regles/donnees/analyser_desaccords.py {etat}` (lot us-consensus, 7 nov. 2026), à partir de "
           f"`consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.", "",
           f"- Lecture A : {len(la)} règles ({sum(r['statut'] == 'incertain' for r in la)} incertain) ; lecture B : {len(lb)} règles "
           f"({sum(r['statut'] == 'incertain' for r in lb)} incertain).",
           f"- Confirmées par les deux : {conf}, dont {len(cons['regles'])} sans réserve (chargées dans l'app) et "
           f"{len(cons['incertaines'])} incertaines (non chargées).",
           f"- À vérifier : seulement A {len(cons['a_verifier']['seulement_a'])}, seulement B {len(cons['a_verifier']['seulement_b'])}.",
           f"- Désaccords listés : {len(lignes)} — " + ", ".join(f"{NOMS[k]} : {compte[k]}" for k in NOMS) + ".", "",
           "Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une "
           "règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.", ""]
    for k in NOMS:
        sel = [l for l in lignes if l[0] == k]
        if not sel:
            continue
        out += [f"## {NOMS[k]} ({len(sel)})", ""]
        for n, (_, a, b, cause, avis, statut) in enumerate(sel, 1):
            out.append(f"{n}. **{statut}** — {cause}")
            out.append(f"   - A : {decrire(a)}")
            if a:
                out.append(f"     > {court(a.get('citation'))}")
            out.append(f"   - B : {decrire(b)}")
            if b:
                out.append(f"     > {court(b.get('citation'))}")
            out.append(f"   - Avis sur l'outil : {avis}")
        out.append("")
    larges = confirmees_par_plus_large(etat, cons)
    out += [f"## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture ({len(larges)})", "",
            "Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite "
            "plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large "
            "était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.", ""]
    for n, (r, autre, motif) in enumerate(larges, 1):
        out.append(f"{n}. {motif} — gardée : {decrire(r)} ; appui : {decrire(autre)}")
    out.append("")
    out += NOTES_LAXISTE.get(etat, [])
    with open(os.path.join(ICI, etat, "desaccords.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"{etat} : {len(lignes)} désaccords — " + ", ".join(f"{k} {compte[k]}" for k in NOMS))


if __name__ == "__main__":
    for e in sys.argv[1:] or ["WI", "MN"]:
        ecrire(e)
