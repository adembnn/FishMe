"""US16 esp-10 : Washington, WDFW (pages d'espèce : nom, latin, « Lakes where this species may be found »).
Usage : python3 -I WA.py ; écrit WA-agence.json. Lecture polie (0,3 s), robots.txt de wdfw.wa.gov lu : /species-habitats/ non exclu."""
import html, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

BASE = "https://wdfw.wa.gov/species-habitats/species/"
CANDIDATS = ["Micropterus salmoides", "Micropterus dolomieu", "Lepomis macrochirus", "Lepomis gibbosus", "Lepomis gulosus",
             "Lepomis cyanellus", "Ambloplites rupestris", "Pomoxis annularis", "Pomoxis nigromaculatus", "Perca flavescens",
             "Sander vitreus", "Ictalurus punctatus", "Ameiurus nebulosus", "Ameiurus natalis", "Ameiurus melas", "Pylodictis olivaris",
             "Oncorhynchus mykiss", "Oncorhynchus clarkii", "Oncorhynchus tshawytscha", "Oncorhynchus kisutch", "Oncorhynchus nerka",
             "Oncorhynchus gorbuscha", "Oncorhynchus keta", "Salmo trutta", "Salvelinus fontinalis", "Salvelinus namaycush",
             "Salvelinus confluentus", "Prosopium williamsoni", "Cyprinus carpio", "Acipenser transmontanus", "Lota lota",
             "Morone saxatilis", "Thymallus arcticus", "Esox lucius", "Esox masquinongy", "Salmo salar", "Coregonus clupeaformis",
             "Ctenopharyngodon idella", "Oncorhynchus mykiss irideus"]


def titre(h):
    m = re.search(r"<title>([^<|]+)", h)
    return html.unescape(m.group(1)).strip() if m else ""


def parse_espece(h):
    """(nom commun, latin, [lacs]) d'une page d'espèce WDFW."""
    t = commun.texte(h)
    m = re.search(r"Category\s*\n:\s*Fish", t)
    lat = re.search(r"\n\(([A-Z][a-z]+ [a-z]+(?: [a-z]+)?)\)\s*\n", t)
    if not m or not lat:
        return None
    return titre(h), lat.group(1), commun.lacs_wdfw(h)


def main():
    sources, entrees = [], []
    for latin in CANDIDATS:
        c, h = commun.lire(BASE + latin.lower().replace(" ", "-"), "wa-" + latin.replace(" ", "-"))
        if c != 200:
            continue
        r = parse_espece(h)
        if not r:
            continue
        nom, lat, lacs = r
        url = BASE + latin.lower().replace(" ", "-")
        sources.append({"nom": f"WDFW, page d'espèce : {nom}", "url": url, "licence": "non précisée", "date": commun.DATE})
        i = len(sources) - 1
        entrees.append(commun.entree(nom, lat, commun.zone_etat("WA", "Washington"), "liste_agence", i))
        for lac in lacs:
            entrees.append(commun.entree(nom, lat, {"type": "plan_eau", "id": lac}, "liste_agence", i))
    p = commun.ecrire("WA", "agence", sources, entrees)
    print(p, len(sources), "espèces", len(entrees) - len(sources), "entrées plan d'eau")


if __name__ == "__main__":
    main()
