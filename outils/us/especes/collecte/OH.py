#!/usr/bin/env python3
"""US16 vague 2 : Ohio, producteur « agence » (ODNR Division of Wildlife, « Sport Fish of Ohio » pub 334, table des matières).
Niveau État seulement. Faits seulement (noms) ; la publication est protégée (« unauthorized reproduction is prohibited »), aucun texte recopié, licence « non précisée ».
« Bullhead Catfish » (Ameiurus spp.) : le guide nomme dans la fiche les trois espèces (yellow, black, brown bullhead) ; on les compte comme signalées.
Le texte du PDF vient de `swift pdf2txt.swift oh.pdf oh.txt` (PDFKit, macOS). Usage : python3 -I OH.py [oh.txt]"""
import json, os, re, sys, time

DATE = "2026-11-08"
ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us", "OH-agence.json")
TABLE = os.path.join(ICI, "..", "especes-us.json")
URL = "https://dam.assets.ohio.gov/image/upload/ohiodnr.gov/documents/wildlife/backyard-wildlife/Sport%20Fish%20of%20Ohio%20Field%20Guide%20pub334.pdf"
EXTRA = {  # nom du guide -> liste de (latin, slug)
    "hybrid-striped bass": [("Morone chrysops x Morone saxatilis", "wiper")],
    "saugeye": [("Sander vitreus x Sander canadensis", "saugeye")],
    "bullhead catfish": [("Ameiurus melas", "black-bullhead"), ("Ameiurus natalis", "yellow-bullhead"), ("Ameiurus nebulosus", "brown-bullhead")],
}


def noms_du_guide(t):
    return [m.group(1).strip() for m in re.finditer(r"^■\d+ ([A-Z][A-Za-z -]+)$", t, re.M)]


def construire(t):
    table = {re.sub(r" \(.*\)$", "", e["nom_en"]).lower(): e for e in json.load(open(TABLE, encoding="utf-8"))}
    entrees, ecartes = [], []
    for n in noms_du_guide(t):
        paires = EXTRA.get(n.lower())
        if paires is None:
            e = table.get(n.lower())
            if not e:
                ecartes.append(n)
                continue
            paires = [(e["latin"], e["slug"])]
        for latin, slug in paires:
            nom = n if len(paires) == 1 else next(re.sub(r" \(.*\)$", "", e["nom_en"]) for e in table.values() if e["slug"] == slug)
            entrees.append({"slug": slug, "nom": nom, "latin": latin, "zone": {"type": "etat", "id": "OH", "nom": "Ohio"},
                            "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    return {"format": "fishme-especes-us/1", "etat": "OH", "producteur": "agence", "date": DATE,
            "sources": [{"nom": "ODNR Division of Wildlife : Sport Fish of Ohio (pub 334)", "url": URL, "licence": "non précisée", "date": DATE}],
            "entrees": entrees}, ecartes


URL_STOCK = "https://www.arcgis.com/sharing/rest/content/items/153a5bbdbf4e433b89513fd9952b2e7f"
ALIAS_STOCK = {"hybrid-striped bass": "Wiper", "tiger muskie": "Tiger muskie", "steelhead": "Rainbow trout", "steelhead trout": "Rainbow trout", "striped bass (male) x white bass (female)": "Wiper"}


def empoissonnements(csv_texte, d):
    """Ajoute espèce x plan d'eau x année (CSV ODNR, copie OGRIP arrêtée au 31 mai 2022 ; l'agence l'a publié sur data.ohio.gov, page introuvable aujourd'hui)."""
    import csv, io
    table = {re.sub(r" \(.*\)$", "", e["nom_en"]).lower(): e for e in json.load(open(TABLE, encoding="utf-8"))}
    d["sources"].append({"nom": "ODNR Division of Wildlife : Ohio fish stocking records (copie OGRIP, arrêtée au 31 mai 2022)", "url": URL_STOCK,
                         "licence": "non précisée", "date": DATE})
    si, agg, ecartes = len(d["sources"]) - 1, {}, {}
    for r in csv.DictReader(io.StringIO(csv_texte)):
        nom = (r["species_name"] or "").strip()
        cle = ALIAS_STOCK.get(nom.lower(), nom).lower()
        e = table.get(cle) or table.get(nom.lower())
        if not e:
            ecartes[nom] = ecartes.get(nom, 0) + 1
            continue
        lieu = " ".join(w.capitalize() if w.isalpha() and len(w) > 2 else w for w in r["location_name"].strip().split())
        k = (e["slug"], lieu)
        a = agg.setdefault(k, [0, 0, e])
        a[0] += 1
        a[1] = max(a[1], int(r["year"] or 0))
    for (slug, lieu), (n, an, e) in sorted(agg.items()):
        d["entrees"].append({"slug": slug, "nom": re.sub(r" \(.*\)$", "", e["nom_en"]), "latin": e["latin"],
                             "zone": {"type": "plan_eau", "id": lieu, "nom": lieu}, "preuve": "empoissonnement", "src": si,
                             "confiance": "officielle", "n": n, "annee_max": an})
    return ecartes


if __name__ == "__main__":
    p = sys.argv[1] if len(sys.argv) > 1 else "/private/tmp/claude-501/brut-us/especes/oh.txt"
    d, ec = construire(open(p, encoding="utf-8").read())
    pc = "/private/tmp/claude-501/brut-us/especes/oh-stock.csv"
    if not os.path.exists(pc):
        import urllib.request
        time.sleep(0.3)
        open(pc, "wb").write(urllib.request.urlopen(urllib.request.Request(URL_STOCK + "/data", headers={"User-Agent": "FishMe-data/1.0 (fishme.app@gmail.com)"}), timeout=60).read())
    ec2 = empoissonnements(open(pc, encoding="utf-8-sig").read(), d)
    json.dump(d, open(SORTIE, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print("OH :", len(d["entrees"]), "entrées ; écartées (guide) :", ec, "; écartées (empoissonnement) :", ec2, os.path.getsize(SORTIE), "octets")
