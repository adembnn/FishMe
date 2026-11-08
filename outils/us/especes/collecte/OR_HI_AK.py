"""US16 esp-10 : Oregon (ODFW), Hawaii (DLNR/DAR), Alaska (ADF&G), niveau État. Usage : python3 -I OR_HI_AK.py
Chaque espèce n'est retenue que si son nom figure dans la page lue ; le latin d'Oregon vient de la taxonomie standard (les pages ODFW n'en donnent pas)."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

OR_PAGES = {
    "bass": [("Largemouth bass", "Micropterus salmoides"), ("Smallmouth bass", "Micropterus dolomieu"), ("Striped bass", "Morone saxatilis")],
    "catfish": [("Channel catfish", "Ictalurus punctatus"), ("Black bullhead", "Ameiurus melas"), ("Brown bullhead", "Ameiurus nebulosus"), ("Yellow bullhead", "Ameiurus natalis")],
    "crappie": [("Black crappie", "Pomoxis nigromaculatus"), ("White crappie", "Pomoxis annularis")],
    "sunfish": [("Bluegill sunfish", "Lepomis macrochirus"), ("Green sunfish", "Lepomis cyanellus"), ("Pumpkinseed sunfish", "Lepomis gibbosus"),
                ("Redear sunfish", "Lepomis microlophus"), ("Sacramento perch", "Archoplites interruptus"), ("Warmouth sunfish", "Lepomis gulosus")],
    "trout": [("Cutthroat trout", "Oncorhynchus clarkii"), ("Lake trout", "Salvelinus namaycush"), ("Rainbow trout", "Oncorhynchus mykiss"),
              ("Brook trout", "Salvelinus fontinalis"), ("Brown trout", "Salmo trutta"), ("Bull trout", "Salvelinus confluentus")],
    "salmon": [("Chinook salmon", "Oncorhynchus tshawytscha"), ("Coho salmon", "Oncorhynchus kisutch"), ("Kokanee salmon", "Oncorhynchus nerka"),
               ("Sockeye salmon", "Oncorhynchus nerka"), ("Chum salmon", "Oncorhynchus keta"), ("Pink salmon", "Oncorhynchus gorbuscha")],
    "sturgeon": [("White sturgeon", "Acipenser transmontanus"), ("Green sturgeon", "Acipenser medirostris")],
    "walleye": [("Walleye", "Sander vitreus")], "yellow-perch": [("Yellow perch", "Perca flavescens")],
    "american-shad": [("American shad", "Alosa sapidissima")], "common-carp": [("Common carp", "Cyprinus carpio")],
    "mountain-whitefish": [("Mountain whitefish", "Prosopium williamsoni")],
}

AK_PAGES = [("arcticgrayling", "Arctic grayling", "Thymallus arcticus"), ("northernpike", "Northern pike", "Esox lucius"),
            ("dollyvarden", "Dolly Varden", "Salvelinus malma"), ("laketrout", "Lake trout", "Salvelinus namaycush"),
            ("burbot", "Burbot", "Lota lota"), ("rainbowtrout", "Rainbow trout", "Oncorhynchus mykiss"),
            ("cutthroattrout", "Cutthroat trout", "Oncorhynchus clarkii"), ("arcticchar", "Arctic char", "Salvelinus alpinus"),
            ("sheefish", "Sheefish", "Stenodus leucichthys"), ("chinook", "Chinook salmon", "Oncorhynchus tshawytscha"),
            ("kingsalmon", "Chinook salmon", "Oncorhynchus tshawytscha"), ("cohosalmon", "Coho salmon", "Oncorhynchus kisutch"),
            ("sockeyesalmon", "Sockeye salmon", "Oncorhynchus nerka"), ("pinksalmon", "Pink salmon", "Oncorhynchus gorbuscha"),
            ("chumsalmon", "Chum salmon", "Oncorhynchus keta"), ("steelhead", "Steelhead", "Oncorhynchus mykiss"),
            ("brooktrout", "Brook trout", "Salvelinus fontinalis")]


def oregon():
    sources, ent, vu = [], [], set()
    for page, lst in OR_PAGES.items():
        url = f"https://myodfw.com/fishing/species/{page}"
        c, h = commun.lire(url, "or-" + page)
        if c != 200:
            continue
        t = commun.texte(h).lower()
        ok = [(n, l) for n, l in lst if n.lower() in t and (n, l) not in vu]
        if not ok:
            continue
        sources.append({"nom": f"ODFW, page d'espèce : {page}", "url": url, "licence": "non précisée", "date": commun.DATE})
        for n, l in ok:
            vu.add((n, l))
            ent.append(commun.entree(n, l, commun.zone_etat("OR", "Oregon"), "liste_agence", len(sources) - 1))
    print("OR", commun.ecrire("OR", "agence", sources, ent), len(ent))


def hawaii():
    sources, ent = [], []
    for k, url in (("hi-sport", "https://dlnr.hawaii.gov/dar/fishing/freshwater-fishing/introduced-sport-fishes/"),
                   ("hi-autres", "https://dlnr.hawaii.gov/dar/fishing/freshwater-fishing/other-introduced-fishes/")):
        c, h = commun.lire(url, k)
        if c != 200:
            continue
        L = commun.texte(h).split("\n")
        sources.append({"nom": "DLNR Division of Aquatic Resources, poissons d'eau douce introduits", "url": url, "licence": "non précisée", "date": commun.DATE})
        for i in range(len(L) - 1):
            if re.fullmatch(r"[A-Z][a-z]+ [a-z]+", L[i + 1].strip()) and L[i].strip() and L[i + 2].strip() == "Description" if i + 2 < len(L) else False:
                nom, lat = L[i].strip(), L[i + 1].strip()
                lat = {"Oreachromis mossambicus": "Oreochromis mossambicus"}.get(lat, lat)  # coquille de la page
                ent.append(commun.entree(nom, lat, commun.zone_etat("HI", "Hawaii"), "liste_agence", len(sources) - 1))
    print("HI", commun.ecrire("HI", "agence", sources, ent), len(ent))


def alaska():
    sources, ent, vu = [], [], set()
    for page, nom, lat in AK_PAGES:
        url = f"https://www.adfg.alaska.gov/index.cfm?adfg={page}.main"
        c, h = commun.lire(url, "ak-" + page)
        if c != 200 or lat.lower() not in commun.texte(h).lower() or (nom, lat) in vu:
            continue
        vu.add((nom, lat))
        sources.append({"nom": f"ADF&G, page d'espèce : {nom}", "url": url, "licence": "non précisée", "date": commun.DATE})
        ent.append(commun.entree(nom, lat, commun.zone_etat("AK", "Alaska"), "liste_agence", len(sources) - 1))
    print("AK", commun.ecrire("AK", "agence", sources, ent), len(ent))


if __name__ == "__main__":
    oregon()
    hawaii()
    alaska()
