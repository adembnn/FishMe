#!/usr/bin/env python3
"""US16 CT : rapport d'empoissonnement 2025 du CT DEEP (PDF officiel) -> couples (plan d'eau, espèce).
Usage : PYTHONPATH=<pypdf> python3 CT.py <stocking.pdf> -> JSON (stdout). Dépend de pypdf (hors dépôt)."""
import re, sys, json

COLS = ["BN_Y", "BK_A", "BN_A", "RW_A", "TIGER_A", "BK_12", "BN_12", "RW_12", "TIGER_12", "BROOD"]
ESP = {"BN": ("brown-trout", "Brown trout", "Salmo trutta"), "BK": ("brook-trout", "Brook trout", "Salvelinus fontinalis"),
       "RW": ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss"),
       "TIGER": (None, "Tiger trout", "Salmo trutta x Salvelinus fontinalis")}
AUTRES = {
    "Lake Trout Adults": ("lake-trout", "Lake trout", "Salvelinus namaycush"),
    "Channel Catfish": ("channel-catfish", "Channel catfish", "Ictalurus punctatus"),
    "Northern Pike": ("northern-pike", "Northern pike", "Esox lucius"),
    "Tiger Muskie": ("tiger-muskie", "Tiger muskie", "Esox masquinongy x Esox lucius"),
    "Walleye": ("walleye", "Walleye", "Sander vitreus"),
    "Atlantic Salmon Adults": ("atlantic-salmon", "Atlantic salmon", "Salmo salar"),
    "American Shad": ("american-shad", "American shad", "Alosa sapidissima"),
    "Brown Trout": ("brown-trout", "Brown trout", "Salmo trutta"),
    "Kokanee": (None, "Kokanee salmon", "Oncorhynchus nerka"),
}
NUM = re.compile(r"(?<![\w.,])(\d[\d,]*)(?![\w])")


def lignes_nombres(t):
    """[{nom, nums:[(texte, position de fin)]}] pour les lignes d'un tableau mis en page."""
    out, prev = [], None
    for ln in t.split("\n"):
        parts = re.split(r"\s{2,}", ln.strip())
        nums = [(m.group(1), m.end()) for m in NUM.finditer(ln)]
        if not nums or len(parts) < 3 or NUM.fullmatch(parts[0]):
            if prev is not None and prev["nom"].count("(") > prev["nom"].count(")") and ")" in parts[0] and not nums:
                prev["nom"] += " " + parts[0]
            continue
        nom = parts[0]
        if re.search(r"\d", nom):
            continue
        prev = {"nom": nom, "ville": parts[1], "nums": nums}
        out.append(prev)
    return out


def trout(t, defaut=None):
    lg = lignes_nombres(t)
    bords = defaut
    for r in lg:
        if len(r["nums"]) == 11:
            bords = [p for _, p in r["nums"]]
            break
    trout.dernier = bords
    res = []
    for r in lg:
        vals = [(int(v.replace(",", "")), p) for v, p in r["nums"]]
        if len(vals) < 2:
            continue
        total = vals[-1][0]
        corps = vals[:-1]
        if sum(v for v, _ in corps) != total:
            continue  # lecture douteuse : ligne écartée
        if len(corps) == 10:
            cols = dict(zip(COLS, [v for v, _ in corps]))
        elif bords:
            cols = {}
            for v, p in corps:
                i = min(range(11), key=lambda k: abs(bords[k] - p))
                if i < 10:
                    cols[COLS[i]] = v
        elif len(corps) == 9:
            cols = dict(zip(COLS[1:], [v for v, _ in corps]))  # sans repère de colonnes : BN(Y) vide
        else:
            continue
        res.append((r["nom"], r["ville"], cols))
    return res


def main(pdf):
    import pypdf
    rd = pypdf.PdfReader(pdf)
    ent = {}
    prec = None
    for i in range(11, 21):
        lus = trout(rd.pages[i].extract_text(extraction_mode="layout"), prec)
        prec = trout.dernier
        for nom, ville, cols in lus:
            for c, v in cols.items():
                if v > 0 and c != "BROOD":
                    ent.setdefault((re.sub(r"\s+", " ", nom).strip(" *"), ville), set()).add(c.split("_")[0])
    sortie = []
    for (nom, ville), cles in sorted(ent.items()):
        for c in sorted(cles):
            sortie.append((f"{nom} ({ville})", ESP[c]))
    txt = "\n".join(rd.pages[i].extract_text(extraction_mode="layout") for i in range(21, 26))
    section = None
    for ln in txt.split("\n"):
        s = ln.strip()
        m = re.match(r"^(Atlantic Salmon (?:Adults|Juveniles)|Lake Trout, Adults|Channel Catfish|Northern Pike|Tiger Muskie|Walleye|American Shad|Sea Lamprey|Alewife|Brown Trout|Kokanee[^(]*)\s*\(\d+\)", s)
        if not m and re.match(r"^Brown Trout\s{2,}Fry$", s):
            section = "Brown Trout"
            continue
        if m:
            k = m.group(1)
            if k.startswith("Lake Trout"):
                section = "Lake Trout Adults"
            elif k.startswith("Kokanee"):
                section = "Kokanee"
            elif k.startswith("Atlantic"):
                section = "Atlantic Salmon Adults"
            elif k in ("Sea Lamprey", "Alewife"):
                section = None
            else:
                section = k
            continue
        if s.startswith("Total") or section is None:
            continue
        parts = re.split(r"\s{2,}", s)
        if len(parts) >= 3 and NUM.fullmatch(parts[-1]):
            nom = re.sub(r"\s+", " ", parts[0]).strip(" *")
            if nom and not nom.startswith("Total"):
                sortie.append((f"{nom} ({parts[1]})", AUTRES[section]))
    return sortie


JOUR = "2026-11-08"
LISTE_ETAT = [  # guide officiel des poissons d'eau douce pêchés au Connecticut (liste telle que publiée)
    ("brook-trout", "Brook trout", "Salvelinus fontinalis"), ("brown-trout", "Brown trout", "Salmo trutta"),
    (None, "Tiger trout", "Salmo trutta x Salvelinus fontinalis"), ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss"),
    (None, "Kokanee salmon", "Oncorhynchus nerka"), ("atlantic-salmon", "Atlantic salmon", "Salmo salar"),
    ("largemouth-bass", "Largemouth bass", "Micropterus salmoides"), ("smallmouth-bass", "Smallmouth bass", "Micropterus dolomieu"),
    ("striped-bass", "Striped bass", "Morone saxatilis"), ("white-perch", "White perch", "Morone americana"),
    ("yellow-perch", "Yellow perch", "Perca flavescens"), ("walleye", "Walleye", "Sander vitreus"),
    ("pumpkinseed", "Pumpkinseed", "Lepomis gibbosus"), ("redbreast-sunfish", "Redbreast sunfish", "Lepomis auritus"),
    ("rock-bass", "Rock bass", "Ambloplites rupestris"), ("black-crappie", "Black crappie (calico bass)", "Pomoxis nigromaculatus"),
    ("yellow-bullhead", "Yellow bullhead", "Ameiurus natalis"), ("channel-catfish", "Channel catfish", "Ictalurus punctatus"),
    ("brown-bullhead", "Brown bullhead", "Ameiurus nebulosus"), ("white-catfish", "White catfish", "Ameiurus catus"),
    ("northern-pike", "Northern pike", "Esox lucius"), ("chain-pickerel", "Chain pickerel", "Esox niger"),
    ("white-sucker", "White sucker", "Catostomus commersonii"), ("common-carp", "Common carp", "Cyprinus carpio"),
]


def construire(pdf):
    e = []
    for slug, nom, lat in LISTE_ETAT:
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "etat", "id": "CT", "nom": "Connecticut"},
                  "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    vus = set()
    for eau, (slug, nom, lat) in main(pdf):
        if (eau, lat) in vus:
            continue
        vus.add((eau, lat))
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "plan_eau", "id": eau, "nom": eau},
                  "preuve": "empoissonnement", "src": 1, "confiance": "officielle", "annee_max": 2025})
    return {"format": "fishme-especes-us/1", "etat": "CT", "producteur": "agence", "date": JOUR,
            "sources": [
                {"nom": "Guide des poissons d'eau douce pêchés au Connecticut (guide officiel du CT DEEP, publié sur eRegulations)",
                 "url": "https://www.eregulations.com/connecticut/fishing/a-guide-to-catchable-freshwater-fish-in-connecticut",
                 "licence": "non précisée", "date": JOUR},
                {"nom": "CT DEEP Fisheries Division, Fish Stocking Report 2025 (empoissonnement par plan d'eau)",
                 "url": "https://portal.ct.gov/-/media/deep/fishing/general_information/annual-fish-stocking-report.pdf",
                 "licence": "non précisée", "date": JOUR}],
            "entrees": e}


if __name__ == "__main__":
    if len(sys.argv) > 2:
        d = construire(sys.argv[1])
        json.dump(d, open(sys.argv[2], "w"), ensure_ascii=False)
        print("CT", len(d["entrees"]), "entrées")
    else:
        json.dump(main(sys.argv[1]), sys.stdout, ensure_ascii=False)
