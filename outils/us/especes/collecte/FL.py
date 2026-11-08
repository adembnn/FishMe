"""FL : table « Fish Information » du service ouvert Fish Range Map de la FWC (niveau État).
Les pages myfwc.com répondent 403 (anti-bot) : non lues ; le service ArcGIS public gis.myfwc.com l'est.
Usage : python3 -I FL.py [especes.json]"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

URL = "https://gis.myfwc.com/hosting/rest/services/Projects_FWC/Fish_Range_Map/MapServer/2"
REQ = URL + "/query?where=1%3D1&outFields=SpeciesID,Species,Type&resultRecordCount=200&f=json"
# la FWC écrit « Redbreast Sunfish » ; « Sunshine Bass » = hybride d'élevage, « Florida Gar » = espèce distincte
LATIN_FL = {"florida gar": "Lepisosteus platyrhincus"}


def construire(d):
    sl = commun.slugs_par_latin()
    vus, entrees = set(), []
    for f in d["features"]:
        a = f["attributes"]
        nom = a["Species"].strip()
        lat = commun.latin_de(nom) or LATIN_FL.get(nom.lower())
        if lat is None:
            raise SystemExit(f"nom scientifique inconnu : {nom}")
        if lat in vus:
            continue
        vus.add(lat)
        entrees.append(commun.entree(nom, lat, {"type": "etat", "id": "FL", "nom": "Florida"}, "liste_agence", 0, slugs=sl))
    return entrees


def main(fichier=None):
    d = json.load(open(fichier, encoding="utf-8")) if fichier else json.loads(commun.telecharger(REQ))
    sources = [{"nom": "FWC (FWRI), Fish Range Map, table Fish Information", "url": URL, "licence": "non précisée", "date": commun.DATE}]
    entrees = construire(d)
    print("FL", len(entrees), commun.ecrire("FL", "agence", sources, entrees))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
