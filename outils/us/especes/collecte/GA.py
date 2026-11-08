"""GA : page « Fish Identification » de la Georgia WRD (poissons de pêche sportive, niveau État).
La page imprime le nom scientifique ; quelques graphies obsolètes sont corrigées par CORRECTIONS (listées dans le rapport).
Usage : python3 -I GA.py [page.html]"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

URL = "https://georgiawildlife.com/fishing/identification"
CORRECTIONS = {
    "Micropterus dolomieui": "Micropterus dolomieu",
    "Oncorhyncus mykiss": "Oncorhynchus mykiss",
    "Morone saxatilis X chrysops": "Morone chrysops x Morone saxatilis",
    "Esox americanus": "Esox americanus americanus",
}
# la page donne le même nom scientifique à Altamaha et Bartram's ; Bartram's est Micropterus sp. cf. coosae (graphie de la page non reprise)
SPECIAL = {"Bass, Bartram's": "Micropterus sp. cf. coosae"}


def nom_usuel(brut):
    n = re.sub(r"\(.*?\)", "", brut.split(" Common Names")[0]).strip()
    if n.startswith("Alabama Bass "):
        n = n[len("Alabama Bass "):]
    if "," in n:
        a, b = [x.strip() for x in n.split(",", 1)]
        if a == "Sunfish":
            return b if b.lower().endswith("bass") or b in ("Bluegill", "Flier", "Warmouth") else b + " sunfish"
        if a == "Bass" and b.startswith("Hybrid"):
            return "Hybrid striped bass"
        return f"{b} {a.lower()}"
    return n


def blocs(html):
    t = commun.texte(html)
    t = t[t.find("Fish Identification"):]
    t = re.sub(r"Current State Record(?: Information)?:?(?: None currently on file| No current state record)?", " | ", t)
    p = t.split("Scientific Name :")
    res = []
    for i in range(1, len(p)):
        avant = p[i - 1].strip()
        m = re.search(r"(?:\||Range ?:[^.]*\.|Fish Identification)\s*([A-Z][^.:|]{2,120})$", avant)
        brut = m.group(1).strip() if m else avant.split("|")[-1].strip()
        latin = re.split(r" Description ?:", p[i])[0].strip()
        res.append((brut, latin))
    return res


def construire(html):
    sl = commun.slugs_par_latin()
    entrees, vus = [], set()
    for brut, latin in blocs(html):
        brut = brut.replace("Information ", "").strip()
        base = nom_usuel(brut)
        paires = []
        if "," in latin and "Micropterus punctulatus" in latin:
            paires = [("Spotted bass", "Micropterus punctulatus"), ("Alabama bass", "Micropterus henshalli")]
        else:
            paires = [(base, SPECIAL.get(brut, CORRECTIONS.get(latin, latin)))]
        for nom, lat in paires:
            if lat in vus:
                continue
            vus.add(lat)
            entrees.append(commun.entree(nom, lat, {"type": "etat", "id": "GA", "nom": "Georgia"}, "liste_agence", 0, slugs=sl))
    return entrees


def main(page=None):
    html = open(page, encoding="utf-8", errors="replace").read() if page else commun.telecharger(URL)
    sources = [{"nom": "Georgia DNR WRD, Fish Identification", "url": URL, "licence": "non précisée", "date": commun.DATE}]
    entrees = construire(html)
    print("GA", len(entrees), commun.ecrire("GA", "agence", sources, entrees))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
