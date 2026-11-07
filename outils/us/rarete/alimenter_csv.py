#!/usr/bin/env python3
"""Comment alimenter le CSV d'événements de rarete_us.py depuis les sources (bibliothèque standard, Python 3.9+).

  python3 alimenter_csv.py sources                      décrit les sources et les pièges
  python3 alimenter_csv.py wqp RESULT.csv STATION.csv -o evenements.csv
        convertit deux exports du Water Quality Portal (profil « biological » pour Result, Station pour les HUC8)
  python3 alimenter_csv.py generique LONG.csv -o evenements.csv --id COL --huc8 COL --etat COL --espece COL --annee COL
        [--milieu COL] [--engin COL] [--source TEXTE]
        convertit un CSV « une ligne par événement et par espèce » (NRSA, base d'un État) ; ajouter les colonnes
        d'événements sans poisson avec une espèce vide, sinon la fréquence est gonflée

Les coordonnées ne sont jamais copiées dans la sortie.
"""
import argparse
import csv
import sys

SORTIE = ["evenement_id", "huc8", "etat", "milieu", "engin", "annee", "source", "especes"]

FIPS = {
    "01": "AL", "02": "AK", "04": "AZ", "05": "AR", "06": "CA", "08": "CO", "09": "CT", "10": "DE", "11": "DC", "12": "FL",
    "13": "GA", "15": "HI", "16": "ID", "17": "IL", "18": "IN", "19": "IA", "20": "KS", "21": "KY", "22": "LA", "23": "ME",
    "24": "MD", "25": "MA", "26": "MI", "27": "MN", "28": "MS", "29": "MO", "30": "MT", "31": "NE", "32": "NV", "33": "NH",
    "34": "NJ", "35": "NM", "36": "NY", "37": "NC", "38": "ND", "39": "OH", "40": "OK", "41": "OR", "42": "PA", "44": "RI",
    "45": "SC", "46": "SD", "47": "TN", "48": "TX", "49": "UT", "50": "VT", "51": "VA", "53": "WA", "54": "WV", "55": "WI",
    "56": "WY",
}

GUIDE = """\
SOURCES (a verifier avant tout usage ; licences et formats changent)

1. EPA NRSA (National Rivers and Streams Assessment, aussi lacs et zones humides) : plan probabiliste national, cycles
   2008-09, 2013-14, 2018-19. Un site visite = un evenement. Fichiers publics de l'EPA (page « National Aquatic Resource
   Surveys », donnees des poissons) : une ligne par site, visite et taxon. Peu d'evenements par HUC8 : les replis HUC6 et
   Etat serviront souvent. Utiliser `generique` : --id (identifiant de visite), --huc8 (a joindre depuis la table des sites
   si absent : jamais depuis des coordonnees publiees), --espece, --annee. Engin : electropeche, a ecrire dans --engin.
2. Water Quality Portal / BioData (USGS, EPA, agences) : https://www.waterqualitydata.us/data/Result/search et .../Station/search,
   memes filtres dans les deux appels (statecode=US:55, assemblage=Fish/Nekton, startDateLo/Hi, mimeType=csv, zip=no,
   dataProfile=biological pour Result). Le profil Result n'a pas de HUC8 : il vient du Station (HUCEightDigitCode).
   PIEGE : un « Activity » de WQP est souvent un poisson ; l'evenement est ici (organisation, station, date).
   PIEGE : WQP ne contient que des evenements avec des resultats : les peches sans poisson manquent, la frequence est donc
   gonflee. Les ajouter a la main si la source de l'agence les donne.
3. Base d'une agence d'Etat (WI DNR Fisheries, MN DNR, MI DNR...) : c'est la source principale d'un Etat pilote ; chaque
   agence a son format (une ligne par capture ou par evenement) et ses conditions d'usage. Utiliser `generique`.
   Les series s'arretent parfois (le rapport signale 2014 pour le Wisconsin) : le CSV porte l'annee, la derniere annee reste visible.
"""


def ecrire(evenements, chemin):
    flux = open(chemin, "w", newline="", encoding="utf-8") if chemin else sys.stdout
    w = csv.writer(flux, lineterminator="\n")
    w.writerow(SORTIE)
    for cle in sorted(evenements):
        e = evenements[cle]
        w.writerow([e["id"], e["huc8"], e["etat"], e["milieu"], e["engin"], e["annee"], e["source"], ";".join(sorted(e["especes"]))])
    if chemin:
        flux.close()


def milieu_wqp(type_station):
    t = (type_station or "").lower()
    if "stream" in t or "river" in t:
        return "cours_d_eau"
    if "lake" in t or "reservoir" in t:
        return "lac"
    return "autre"


def cmd_wqp(o):
    with open(o.station, newline="", encoding="utf-8") as f:
        stations = {s["MonitoringLocationIdentifier"]: s for s in csv.DictReader(f)}
    evenements, sans_station = {}, set()
    with open(o.result, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r.get("AssemblageSampledName") and r["AssemblageSampledName"] != "Fish/Nekton":
                continue
            lieu = r["MonitoringLocationIdentifier"]
            sta = stations.get(lieu)
            if sta is None or len(sta.get("HUCEightDigitCode", "")) != 8:
                sans_station.add(lieu)
                continue
            taxon = r.get("SubjectTaxonomicName", "").strip()
            if not taxon:
                continue
            if r.get("CharacteristicName") == "Count" and r.get("ResultMeasureValue", "").strip() in ("0", "0.0"):
                continue  # compte zero : pas de presence
            date = r["ActivityStartDate"]
            cle = (r["OrganizationIdentifier"], lieu, date)
            e = evenements.setdefault(cle, {
                "id": "%s|%s|%s" % cle, "huc8": sta["HUCEightDigitCode"],
                "etat": FIPS.get((sta.get("StateCode") or "").split(":")[-1].zfill(2), (sta.get("StateCode") or "")),
                "milieu": milieu_wqp(sta.get("MonitoringLocationTypeName")),
                "engin": (r.get("SampleCollectionEquipmentName") or "").strip().lower() or "inconnu",
                "annee": date[:4], "source": "WQP " + r["OrganizationIdentifier"], "especes": set()})
            e["especes"].add(taxon)
    if sans_station:
        sys.stderr.write("%d stations sans HUC8 ignorees\n" % len(sans_station))
    ecrire(evenements, o.sortie)
    sys.stderr.write("%d evenements\n" % len(evenements))


def cmd_generique(o):
    evenements = {}
    with open(o.long, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            cle = r[o.id].strip()
            e = evenements.setdefault(cle, {
                "id": cle, "huc8": r[o.huc8].strip(), "etat": r[o.etat].strip(),
                "milieu": (r[o.milieu].strip() if o.milieu else "autre") or "autre",
                "engin": (r[o.engin].strip().lower() if o.engin else "") or "inconnu",
                "annee": r[o.annee].strip(), "source": o.source, "especes": set()})
            if r[o.espece].strip():
                e["especes"].add(r[o.espece].strip())
    ecrire(evenements, o.sortie)
    sys.stderr.write("%d evenements\n" % len(evenements))


def main(argv=None):
    a = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = a.add_subparsers(dest="cmd", required=True)
    sp.add_parser("sources")
    w = sp.add_parser("wqp")
    w.add_argument("result")
    w.add_argument("station")
    w.add_argument("-o", "--sortie")
    g = sp.add_parser("generique")
    g.add_argument("long")
    g.add_argument("-o", "--sortie")
    for nom in ("id", "huc8", "etat", "espece", "annee"):
        g.add_argument("--" + nom, required=True)
    g.add_argument("--milieu")
    g.add_argument("--engin")
    g.add_argument("--source", default="source non precisee")
    o = a.parse_args(argv)
    if o.cmd == "sources":
        print(GUIDE)
    elif o.cmd == "wqp":
        cmd_wqp(o)
    else:
        cmd_generique(o)


if __name__ == "__main__":
    main()
