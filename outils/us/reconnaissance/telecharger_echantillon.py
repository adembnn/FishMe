"""Télécharge un TOUT PETIT échantillon de démo (6 espèces, <= 20 photos chacune, <= 50 Mo au total) HORS dépôt.
Photos lues sur le bucket public inaturalist-open-data (taille « medium », ~500 px), une requête par seconde.
Choix : libres (CC0/CC BY) d'abord, puis non libres (« entrainement_seul ») pour compléter ; au plus 2 photos par observateur.
Écrit <sortie>/<espece>/<photo_id>.jpg et <sortie>/licences.csv (licence enregistrée pour chaque photo).
Usage : python3 -I telecharger_echantillon.py [--sortie /private/tmp/claude-501/us-reco/echantillon]"""
import argparse, collections, csv, os, sys, urllib.error
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun, construire_jeu

DEMO = ["largemouth-bass", "bluegill", "channel-catfish", "rainbow-trout", "walleye", "northern-pike"]
MAX_PAR_ESPECE, MAX_OCTETS = 20, 50 * 1024 * 1024


def main():
    ici = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument("--sortie", default=os.path.join(commun.DONNEES, "echantillon"))
    a = ap.parse_args()
    if commun.dans_un_depot_git(a.sortie):
        sys.exit("La sortie ne doit pas être dans un dépôt git : " + a.sortie)
    espèces = {e["slug"]: e for e in construire_jeu.charger_especes(os.path.join(ici, "especes-us.json"), set(DEMO))}
    total, lignes = 0, []
    for slug in DEMO:
        if slug not in espèces:
            print("absent de la liste :", slug)
            continue
        cle = construire_jeu.cle_gbif(espèces[slug]["latin"])
        # on lit large (200 observations) pour avoir assez de photos libres et d'observateurs différents
        photos = construire_jeu.photos_gbif(cle, 200)
        photos.sort(key=lambda p: commun.classe_licence(p["licence"]) != "libre")  # tri stable : libres d'abord
        par_obs, choisies = collections.Counter(), []
        for p in photos:
            if commun.classe_licence(p["licence"]) == "exclue" or par_obs[p["observateur"]] >= 2:
                continue
            par_obs[p["observateur"]] += 1
            choisies.append(p)
            if len(choisies) == MAX_PAR_ESPECE:
                break
        os.makedirs(os.path.join(a.sortie, slug), exist_ok=True)
        n = 0
        for p in choisies:
            if total >= MAX_OCTETS:
                break
            chemin = os.path.join(a.sortie, slug, p["photo_id"] + ".jpg")
            try:
                data = commun.get(p["url"], pause=1.0, binaire=True)
            except urllib.error.HTTPError as e:
                print("  photo", p["photo_id"], "ignorée :", e.code)
                continue
            if total + len(data) > MAX_OCTETS:
                break
            open(chemin, "wb").write(data)
            total += len(data)
            n += 1
            lignes.append([slug, p["photo_id"], p["licence"], commun.classe_licence(p["licence"]), p["auteur"], p["observateur"], p["observation"], p["url"]])
        print(slug, n, "photos,", round(total / 1e6, 1), "Mo cumulés", flush=True)
    with open(os.path.join(a.sortie, "licences.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["espece", "photo_id", "licence", "classe_licence", "auteur", "observateur", "observation", "url"])
        w.writerows(lignes)
    print("total", len(lignes), "photos,", round(total / 1e6, 1), "Mo ->", a.sortie)


if __name__ == "__main__":
    main()
