"""USGS NAS (espèces non indigènes) : poissons signalés par État, agrégés par bassin HUC8.
Une entrée par (espèce, HUC8) avec n = nombre d'enregistrements, annee_max ; plus une entrée État par espèce.
Domaine public fédéral (USGS). Faits seulement : aucun point GPS conservé, aucun texte de référence.
Usage : python3 -I NAS.py WY MT ID UT NV"""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun as C

API = "https://nas.er.usgs.gov/api/v2/occurrence/search?state={s}&group=Fishes&limit=300&offset={o}"
NOMS = {"WY": "Wyoming", "MT": "Montana", "ID": "Idaho", "UT": "Utah", "NV": "Nevada"}


def especes_us():
    p = os.path.join(C.ICI, "..", "especes-us.json")
    return {e["latin"]: e for e in json.load(open(p, encoding="utf-8"))}


def agreger(enregistrements, table):
    """enregistrements : dicts NAS. Rend (entrées huc8, entrées état) sans coordonnées."""
    huc, etat = {}, {}
    for r in enregistrements:
        latin = r.get("scientificName")
        if not latin or r.get("freshMarineIntro") not in ("Freshwater", None, ""):
            continue
        an = r.get("year") if isinstance(r.get("year"), int) else None
        e = table.get(latin)
        nom = e["nom_en"] if e else (r.get("commonName") or latin)
        esp = (e["slug"] if e else None, nom, latin)
        h = str(r.get("huc8") or "")
        if len(h) == 8 and h.isdigit():
            a = huc.setdefault((latin, h), [esp, r.get("huc8Name") or h, 0, 0])
            a[2] += 1
            a[3] = max(a[3], an or 0)
        s = etat.setdefault(latin, [esp, 0, 0])
        s[1] += 1
        s[2] = max(s[2], an or 0)
    return huc, etat


def main(usps):
    table = especes_us()
    enr, o = [], 0
    while True:
        h = C.lire(API.format(s=usps, o=o), f"nas-{usps}-{o}.json", pause=0.3)
        d = json.loads(h)
        enr += d.get("results", [])
        if str(d.get("endOfRecords")) == "true" or not d.get("results"):
            break
        o += d.get("limit", 300)
    huc, etat = agreger(enr, table)
    src = {"nom": f"USGS NAS, occurrences de poissons non indigènes ({NOMS[usps]})", "url": "https://nas.er.usgs.gov/api/v2/", "licence": "domaine public fédéral", "date": C.DATE}
    entrees = []
    for latin, (esp, n, an) in sorted(etat.items()):
        entrees.append(C.entree(esp, "etat", usps, NOMS[usps], "nas", 0, n=n, annee_max=an or None, confiance="enregistrement_scientifique"))
    for (latin, h), (esp, nom, n, an) in sorted(huc.items()):
        entrees.append(C.entree(esp, "huc8", h, nom, "nas", 0, n=n, annee_max=an or None, confiance="enregistrement_scientifique"))
    p, taille = C.ecrire(usps, "nas", [src], entrees)
    print(f"{usps} NAS : {len(enr)} enregistrements, {len(etat)} espèces, {len(huc)} couples espèce-HUC8, {taille} octets")


if __name__ == "__main__":
    for u in sys.argv[1:]:
        main(u)
