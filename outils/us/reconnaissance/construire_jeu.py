"""Construit la LISTE de photos d'entraînement américaines (aucune photo téléchargée ici).

Sorties (hors dépôt, dans --sortie, par défaut /private/tmp/claude-501/us-reco/jeu) :
  manifeste.csv : une ligne par photo (espèce, url, licence, classe de licence, observateur, découpe, source, date du relevé)
  volumes.json  : volumes réels mesurés par l'API (observations avec photo par espèce et par licence)

Sources :
  --source gbif (défaut) : API GBIF, jeu « iNaturalist Research-grade Observations », États-Unis, images ; chaque média porte sa
        licence et son auteur ; les images sont ensuite lues sur le bucket public inaturalist-open-data (pas sur inaturalist.org).
        robots.txt de api.gbif.org : accès permis. Limite : ne contient que les photos sous licence CC (pas « tous droits réservés »).
  --source inat-api : API v1 d'iNaturalist (quality_grade=research, photo_license). BLOQUÉE par défaut : api.inaturalist.org/robots.txt
        contient « Disallow: / » et le robots.txt du site déclare « ai-train=no ». Ne s'active que par la variable
        FISHME_INAT_API_OK=1, à ne poser qu'après décision écrite de Titouan sur la réserve juridique.
Classes de licence : libre (CC0, CC BY) ; entrainement_seul (CC BY-NC, BY-SA, NC-SA… jamais publiées ni vendues) ; exclue (ND, inconnue).
Découpe 70/15/15 PAR OBSERVATEUR ; val et test ne gardent que des photos « libre » (les autres photos de ces observateurs sont écartées,
jamais versées dans train : sinon fuite).
Usage : python3 -I construire_jeu.py [--especes especes-us.json] [--slugs a,b] [--max-par-espece 300] [--compter]"""
import argparse, csv, datetime, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun


def charger_especes(chemin, slugs):
    esp = json.load(open(chemin, encoding="utf-8"))
    esp = [e for e in esp if e.get("type") == "poisson"]
    if slugs:
        esp = [e for e in esp if e["slug"] in slugs]
    return esp


def cle_gbif(latin):
    """Clé GBIF d'une espèce ; None pour un hybride (pas de taxon propre)."""
    if " x " in latin or "×" in latin:
        return None
    r = commun.get(commun.GBIF + "/species/match", {"name": latin, "kingdom": "Animalia"})
    return r.get("usageKey") if r.get("matchType") in ("EXACT", "HIGHERRANK") and r.get("rank") == "SPECIES" else None


BASE = {"datasetKey": commun.DATASET_INAT_GBIF, "country": "US", "mediaType": "StillImage"}


def volumes_gbif(cle):
    r = commun.get(commun.GBIF + "/occurrence/search", dict(BASE, taxonKey=cle, limit=0, facet="license", facetLimit=20))
    par = {c["name"]: c["count"] for f in r.get("facets", []) for c in f["counts"]}
    return {"observations_avec_photo": r["count"], "par_licence": par}


def photos_gbif(cle, maximum):
    """Liste de dicts photo ; au plus `maximum` observations (ordre GBIF)."""
    sortie, offset = [], 0
    while offset < maximum:
        r = commun.get(commun.GBIF + "/occurrence/search", dict(BASE, taxonKey=cle, limit=min(300, maximum - offset), offset=offset))
        for o in r["results"]:
            obs = o.get("recordedBy") or ""
            for m in o.get("media", []):
                ident = m.get("identifier", "")
                if "inaturalist-open-data" not in ident:
                    continue
                lic = commun.code_licence(m.get("license") or o.get("license"))
                sortie.append({
                    "photo_id": ident.split("/photos/")[1].split("/")[0],
                    "observation": o.get("occurrenceID", ""),
                    "observateur": obs or "inconnu:%s" % o["key"],
                    "licence": lic, "auteur": m.get("creator") or m.get("rightsHolder") or obs,
                    "url": ident.replace("/original.", "/medium."),  # 500 px, suffit pour DINOv2 en 224
                })
        offset += len(r["results"])
        if r.get("endOfRecords") or not r["results"]:
            break
    return sortie


def api_inat_autorisee():
    if os.environ.get("FISHME_INAT_API_OK") != "1":
        sys.exit("Source inat-api refusée : api.inaturalist.org/robots.txt interdit tout (Disallow: /) et le site déclare ai-train=no.\n"
                 "Utilise --source gbif, ou pose FISHME_INAT_API_OK=1 après décision écrite de Titouan.")


def photos_inat_api(taxon_nom, maximum):
    api_inat_autorisee()
    sortie, page = [], 1
    while len(sortie) < maximum:
        r = commun.get("https://api.inaturalist.org/v1/observations",
                       {"taxon_name": taxon_nom, "quality_grade": "research", "place_id": 1, "photos": "true",
                        "per_page": 200, "page": page, "order_by": "id"}, pause=1.1)  # <= 60 requêtes/min
        if not r["results"]:
            break
        for o in r["results"]:
            for p in o.get("photos", []):
                lc = (p.get("license_code") or "").lower()  # 'cc0', 'cc-by', 'cc-by-nc'... ; vide = tous droits réservés
                lic = "CC0_1_0" if lc == "cc0" else ("CC_" + lc[3:].upper().replace("-", "_") + "_4_0" if lc else "TOUS_DROITS_RESERVES")
                sortie.append({"photo_id": str(p["id"]), "observation": "https://www.inaturalist.org/observations/%s" % o["id"],
                               "observateur": o["user"]["login"], "licence": lic, "auteur": o["user"]["login"],
                               "url": p["url"].replace("square", "medium")})
        page += 1
    return sortie[:maximum]


def main():
    ici = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument("--especes", default=os.path.join(ici, "especes-us.json"))
    ap.add_argument("--slugs", default="")
    ap.add_argument("--source", choices=["gbif", "inat-api"], default="gbif")
    ap.add_argument("--max-par-espece", type=int, default=300)
    ap.add_argument("--sortie", default=os.path.join(commun.DONNEES, "jeu"))
    ap.add_argument("--compter", action="store_true", help="volumes seulement, pas de liste de photos")
    a = ap.parse_args()
    if commun.dans_un_depot_git(a.sortie):
        sys.exit("La sortie ne doit pas être dans un dépôt git : " + a.sortie)
    os.makedirs(a.sortie, exist_ok=True)
    esp = charger_especes(a.especes, set(filter(None, a.slugs.split(","))))
    quand = datetime.date.today().isoformat()
    volumes, lignes, vus = {}, [], set()
    for e in esp:
        cle = cle_gbif(e["latin"])
        if cle is None:
            volumes[e["slug"]] = {"note": "hybride ou nom non reconnu par GBIF : à traiter à la main", "latin": e["latin"]}
            print("saute", e["slug"], "(pas de taxon GBIF)")
            continue
        volumes[e["slug"]] = dict(volumes_gbif(cle), latin=e["latin"], gbif_taxon=cle, releve=quand, source="API GBIF occurrence/search")
        print(e["slug"], volumes[e["slug"]]["observations_avec_photo"], volumes[e["slug"]]["par_licence"], flush=True)
        if a.compter:
            continue
        liste = photos_gbif(cle, a.max_par_espece) if a.source == "gbif" else photos_inat_api(e["latin"], a.max_par_espece)
        for p in liste:
            if p["photo_id"] in vus:
                continue
            vus.add(p["photo_id"])
            classe = commun.classe_licence(p["licence"])
            lot = commun.decoupe_observateur(p["observateur"])
            if classe == "exclue":
                lot = "ecarte"
            elif lot != "train" and classe != "libre":
                lot = "ecarte"  # val/test : uniquement des photos libres ; jamais reversée dans train (fuite)
            lignes.append(dict(p, espece=e["slug"], classe_licence=classe, decoupe=lot, source=a.source, releve=quand))
    with open(os.path.join(a.sortie, "volumes.json"), "w", encoding="utf-8") as f:
        json.dump({"releve": quand, "volumes": volumes}, f, ensure_ascii=False, indent=1)
    if not a.compter:
        cols = ["espece", "photo_id", "url", "licence", "classe_licence", "observateur", "auteur", "observation", "decoupe", "source", "releve"]
        with open(os.path.join(a.sortie, "manifeste.csv"), "w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, cols)
            w.writeheader()
            w.writerows({c: l[c] for c in cols} for l in lignes)
        print("manifeste :", len(lignes), "photos ->", a.sortie)


if __name__ == "__main__":
    main()
