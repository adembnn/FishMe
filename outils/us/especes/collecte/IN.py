#!/usr/bin/env python3
"""US16 vague 2 : Indiana, producteur « agence » (Indiana DNR, « Fishes of Indiana List », révisée juin 2024).
Niveau État seulement : la liste porte toutes les espèces de poissons de l'État ; on ne garde que celles de la table `especes-us.json`
(les espèces disparues de l'État, statut EX, sont écartées). Le statut du tableau n'est pas recopié.
Usage : python3 -I IN.py"""
import html, json, os, re, sys, time, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
URL = "https://www.in.gov/dnr/fish-and-wildlife/nongame-and-endangered-wildlife/fish-and-freshwater-mussels/fishes-of-indiana-list"
DATE = "2026-11-08"
ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us", "IN-agence.json")
BRUT = "/private/tmp/claude-501/brut-us/especes/in-list.html"
TABLE = os.path.join(ICI, "..", "especes-us.json")


def texte(h):
    h = re.sub(r"(?s)<(script|style).*?</\1>", "", h)
    h = re.sub(r"<[^>]+>", "\n", h)
    return re.sub(r"\n\s*\n+", "\n", html.unescape(h))


def lignes_liste(h):
    """-> [(nom, latin, statut)] d'après le tableau de l'agence."""
    t = texte(h)
    return re.findall(r"\n([A-Z][A-Za-z' .-]+)\n ([A-Z][a-z]+ [a-z]+(?: [a-z]+)?) ?\n(-|SC|SE|EX|X)?", t)


def construire(h):
    table = {e["latin"]: e for e in json.load(open(TABLE, encoding="utf-8"))}
    entrees = []
    for nom, latin, statut in lignes_liste(h):
        if nom == "Largemouth Bass" and latin == "Micropterus nigricans":
            # l'agence emploie Micropterus nigricans (taxonomie récente) ; la table garde M. salmoides : on rapproche par le nom courant
            latin_table = "Micropterus salmoides"
        else:
            latin_table = latin
        if statut == "EX" or latin_table not in table:
            continue
        e = table[latin_table]
        entrees.append({"slug": e["slug"], "nom": nom, "latin": latin, "zone": {"type": "etat", "id": "IN", "nom": "Indiana"},
                        "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    return {"format": "fishme-especes-us/1", "etat": "IN", "producteur": "agence", "date": DATE,
            "sources": [{"nom": "Indiana DNR : Fishes of Indiana List (révisée juin 2024)", "url": URL, "licence": "non précisée", "date": DATE}],
            "entrees": entrees}


COMTES = ["St. Joseph", "Greene", "Kosciusko", "LaGrange", "Lake", "Lawrence", "Marion", "Noble", "Steuben", "Tippecanoe", "Vigo", "Whitley",
          "Allen", "Elkhart", "Fulton", "Howard", "LaPorte", "Porter", "Randolph", "Franklin", "Henry", "Parke"]
URL_TRUITE = "https://www.in.gov/dnr/fish-and-wildlife/files/fw-trout-stocking-plan.pdf"
URL_SILURE = "https://www.in.gov/dnr/fish-and-wildlife/files/fw-urban-channel-catfish-stocking-plan.pdf"
ESPECES_TRUITE = {"Rainbow Trout": ("Oncorhynchus mykiss", "rainbow-trout"), "Brown Trout": ("Salmo trutta", "brown-trout")}


def plans_truite(t):
    """Lacs et cours d'eau du plan de truites : [(plan d'eau, espèce)]. S'arrête avant « May Stockings » (lieux précis)."""
    t = t.split("May Stockings")[0]
    sortie, courant = [], None
    for l in t.splitlines():
        m = re.match(r"^(?:(?P<pre>.+?) )?(?P<n>\d[\d,]*) (?P<sp>Rainbow Trout|Brown Trout)$", l.strip())
        if not m:
            continue
        pre = m.group("pre")
        if pre:
            for c in COMTES:
                if pre.startswith(c + " "):
                    courant = pre[len(c) + 1:].strip()
                    break
            else:
                continue
        if courant:
            sortie.append((courant, m.group("sp")))
    return sortie


def plans_silure(t):
    return sorted({m.group(1).strip() for m in re.finditer(r"^([A-Z][^\n]*?) \d[\d,]*$", t, re.M) if not m.group(1).startswith(("Total", "Stocking"))})


def ajouter_empoissonnements(d, t_truite, t_silure):
    d["sources"].append({"nom": "Indiana DNR : 2026 Inland Trout Stocking Plan (plan, mis à jour 2026-03-20)", "url": URL_TRUITE, "licence": "non précisée", "date": DATE})
    d["sources"].append({"nom": "Indiana DNR : 2026 Urban Channel Catfish Stocking Plan", "url": URL_SILURE, "licence": "non précisée", "date": DATE})
    for lieu, sp in sorted(set(plans_truite(t_truite))):
        lat, slug = ESPECES_TRUITE[sp]
        d["entrees"].append({"slug": slug, "nom": sp, "latin": lat, "zone": {"type": "plan_eau", "id": lieu, "nom": lieu},
                             "preuve": "empoissonnement", "src": len(d["sources"]) - 2, "confiance": "officielle", "annee_max": 2026})
    for lieu in plans_silure(t_silure):
        d["entrees"].append({"slug": "channel-catfish", "nom": "Channel Catfish", "latin": "Ictalurus punctatus", "zone": {"type": "plan_eau", "id": lieu, "nom": lieu},
                             "preuve": "empoissonnement", "src": len(d["sources"]) - 1, "confiance": "officielle", "annee_max": 2026})


if __name__ == "__main__":
    if os.path.exists(BRUT):
        h = open(BRUT, encoding="utf-8", errors="ignore").read()
    else:
        time.sleep(0.3)
        h = urllib.request.urlopen(urllib.request.Request(URL, headers={"User-Agent": UA}), timeout=40).read().decode("utf-8", "ignore")
        open(BRUT, "w", encoding="utf-8").write(h)
    d = construire(h)
    lire = lambda n: open("/private/tmp/claude-501/brut-us/especes/" + n, encoding="utf-8").read()
    ajouter_empoissonnements(d, lire("in-trout.txt"), lire("in-cat.txt"))
    json.dump(d, open(SORTIE, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("IN :", len(d["entrees"]), "espèces de la table signalées par l'agence")
