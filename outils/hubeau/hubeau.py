#!/usr/bin/env python3
"""D2 Donnees Hub'Eau : fabrique stations-especes.json, rarete-departements.json et stations-hydro.json.

Exemples :
  python3 outils/hubeau/hubeau.py --departement 94          # le 94 de bout en bout
  python3 outils/hubeau/hubeau.py --departement 75 77 78   # un groupe de departements
  python3 outils/hubeau/hubeau.py                           # la France entiere (reprise par le cache)
  python3 outils/hubeau/hubeau.py --verifier-especes        # compare chaque code Sandre au nom latin de Hub'Eau

Source : OFB via Hub'Eau (etat_piscicole), Hub'Eau hydrometrie (Vigicrues). Licence Ouverte 2.0.
Les 3 fichiers produits et le cache sont ignores par git (outils/hubeau/.gitignore).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date, datetime, timedelta, timezone

import comptes
import recalage
import especes as esp
import geo
from hubeau_client import Client, HubeauError, QuotaError

ICI = os.path.dirname(os.path.abspath(__file__))
CHAMPS_STATIONS = ("code_station,coordonnee_x_station,coordonnee_y_station,code_entite_hydrographique,"
                   "libelle_entite_hydrographique,code_departement,code_region")
CHAMPS_OPERATIONS = "code_operation,date_operation,code_station,operation_sans_poisson"
CHAMPS_OBSERVATIONS = "code_operation,code_taxon"
CHAMPS_HYDRO = ("code_station,code_site,libelle_station,code_cours_eau,libelle_cours_eau,latitude_station,"
                "longitude_station,en_service,code_departement,code_region")


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def charger_config(chemin=None) -> dict:
    chemin = chemin or os.path.join(ICI, "config.json")
    with open(chemin, encoding="utf-8") as f:
        cfg = json.load(f)
    cfg["_dir"] = os.path.dirname(os.path.abspath(chemin))
    return cfg


def resoudre(cfg: dict, chemin: str) -> str:
    return os.path.normpath(os.path.join(cfg["_dir"], chemin))


def ecrire_json(chemin: str, doc) -> int:
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    tmp = chemin + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    os.replace(tmp, chemin)
    return os.path.getsize(chemin)


# --- stations piscicoles ---------------------------------------------------------------------
def recuperer_stations(client: Client, cfg: dict) -> list[dict]:
    p = {"size": cfg["piscicole"]["size_stations"], "fields": CHAMPS_STATIONS}
    return list(client.toutes_les_lignes(cfg["piscicole"]["base"], "stations", p))


def preparer_stations(lignes: list[dict], dep_index: geo.Departements, tolerance_km: float):
    """Une ligne par code_station (l'API en renvoie une par point de prelevement). Retourne
    (stations, ecartees, infos). stations[id] = {id, lat, lon, dep, mode, eau, code_eau, dep_api, region_api}."""
    stations: dict[str, dict] = {}
    ecartees: list[dict] = []
    conflits_eau = []
    for r in lignes:
        sid = r.get("code_station")
        if not sid:
            continue
        x, y = r.get("coordonnee_x_station"), r.get("coordonnee_y_station")
        eau = r.get("libelle_entite_hydrographique") or None
        code_eau = r.get("code_entite_hydrographique") or None
        if sid in stations:
            s = stations[sid]
            if s["eau"] is None and eau:
                s["eau"], s["code_eau"] = eau, code_eau
            elif eau and s["eau"] != eau:
                conflits_eau.append({"id": sid, "gardee": s["eau"], "autre": eau})
            continue
        if not x or not y:
            ecartees.append({"id": sid, "raison": "sans coordonnees", "dep_api": r.get("code_departement")})
            continue
        lon, lat = geo.lambert93_vers_wgs84(float(x), float(y))
        dep, mode = dep_index.ranger(lon, lat, tolerance_km)
        if dep is None:
            ecartees.append({"id": sid, "raison": "hors de tous les departements du fichier (DOM, etranger ou erreur de coordonnees)",
                             "dep_api": r.get("code_departement"), "lat": round(lat, 5), "lon": round(lon, 5)})
            continue
        stations[sid] = {"id": sid, "lat": round(lat, 5), "lon": round(lon, 5), "dep": dep, "mode": mode,
                         "eau": eau, "code_eau": code_eau, "dep_api": r.get("code_departement"),
                         "region_api": r.get("code_region")}
    return stations, ecartees, {"conflits_eau": conflits_eau}


# --- recuperation des peches par lot de stations -------------------------------------------------
def recuperer_lot(client: Client, cfg: dict, codes_especes: list[str], ids: list[str]):
    """Operations + (operation, espece) pour un lot de stations. Suit `next`."""
    pc = cfg["piscicole"]
    lst = ",".join(ids)
    ops = list(client.toutes_les_lignes(pc["base"], "operations", {
        "code_station": lst, "size": pc["size_operations"], "fields": CHAMPS_OPERATIONS}))
    paires = set()
    for r in client.toutes_les_lignes(pc["base"], "observations", {
            "code_station": lst, "code_taxon": ",".join(codes_especes),
            "size": pc["size_observations"], "fields": CHAMPS_OBSERVATIONS}):
        paires.add((str(r["code_operation"]), str(r["code_taxon"])))
    return ops, paires


def lots_par_dep(stations: dict, deps: list[str], taille: int) -> dict:
    par = {d: [] for d in deps}
    for sid, s in sorted(stations.items()):
        if s["dep"] in par:
            par[s["dep"]].append(sid)
    return {d: [ids[i:i + taille] for i in range(0, len(ids), taille)] for d, ids in par.items()}


def recuperer_tout(client, cfg, codes_especes, lots, workers):
    """Lance tous les lots en parallele. Retourne (ops, paires, deps_echoues)."""
    taches = [(d, i, ids) for d, ls in lots.items() for i, ids in enumerate(ls)]
    ops_all, paires_all, echecs = [], set(), {}
    fait, t0 = 0, time.time()
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(recuperer_lot, client, cfg, codes_especes, ids): (d, i) for d, i, ids in taches}
        for fu in as_completed(futs):
            d, i = futs[fu]
            try:
                ops, paires = fu.result()
                ops_all.extend(ops)
                paires_all |= paires
            except QuotaError:
                raise
            except Exception as e:  # le departement sera ecarte, on continue avec les autres
                echecs.setdefault(d, []).append(f"lot {i}: {e}")
                log(f"[{d}] ECHEC lot {i}: {e}")
            fait += 1
            if fait % 10 == 0 or fait == len(taches):
                log(f"  {fait}/{len(taches)} lots, {client.n_requetes} appels API, {client.n_cache} pages en cache, "
                    f"{int(time.time() - t0)} s")
    return ops_all, paires_all, echecs


# --- hydrometrie ----------------------------------------------------------------------------
def fabriquer_hydro(client: Client, cfg: dict, dep_index: geo.Departements, maj: str, tol: float):
    h = cfg["hydrometrie"]
    lignes = list(client.toutes_les_lignes(h["base"], "referentiel/stations", {
        "size": h["size_stations"], "fields": CHAMPS_HYDRO}))
    debut = (datetime.now(timezone.utc) - timedelta(hours=h["fenetre_debit_heures"])).strftime("%Y-%m-%dT%H:%M:%SZ")
    st_q, site_q = set(), set()
    for r in client.toutes_les_lignes(h["base"], "observations_tr", {
            "grandeur_hydro": "Q", "date_debut_obs": debut, "size": h["size_observations_tr"],
            "fields": "code_station,code_site"}):
        if r.get("code_station"):
            st_q.add(r["code_station"])
        elif r.get("code_site"):
            site_q.add(r["code_site"])
    out, ecartees, vus = [], [], set()
    for r in lignes:
        code = r.get("code_station")
        if not code or code in vus:
            continue
        vus.add(code)
        lat, lon = r.get("latitude_station"), r.get("longitude_station")
        if lat is None or lon is None:
            ecartees.append({"code": code, "raison": "sans coordonnees"})
            continue
        dep, mode = dep_index.ranger(lon, lat, tol)
        if dep is None:
            ecartees.append({"code": code, "raison": "hors des departements du fichier (DOM ou etranger)",
                             "dep_api": r.get("code_departement")})
            continue
        out.append({"code": code, "nom": r.get("libelle_station"), "eau": r.get("libelle_cours_eau") or None,
                    "code_eau": r.get("code_cours_eau") or None, "lat": round(lat, 5), "lon": round(lon, 5),
                    "dep": dep, "en_service": bool(r.get("en_service")),
                    "debit": code in st_q, "debit_site": (code not in st_q) and (r.get("code_site") in site_q)})
    out.sort(key=lambda s: s["code"])
    doc = {"source": cfg["source_hydro"], "licence": cfg["licence"], "mis_a_jour": maj,
           "note": "Metadonnees seulement : aucune hauteur ni aucun debit. `debit` = la station a publie un debit "
                   f"dans les {h['fenetre_debit_heures']} dernieres heures a la date de mise a jour ; `debit_site` = "
                   "seul le site (pas la station) en publie. L'app lit les niveaux en direct.",
           "stations": out}
    return doc, ecartees


# --- verification des codes Sandre ---------------------------------------------------------------
def verifier_especes(client, cfg, liste, workers):
    pc = cfg["piscicole"]

    def un(e):
        p = {"code_taxon": e["code"], "size": 1, "fields": "code_taxon,nom_latin_taxon,nom_commun_taxon"}
        rep = client.page(client.url(pc["base"], "observations", p))
        d = (rep.get("data") or [{}])[0]
        return e, rep.get("count", 0), d.get("nom_latin_taxon"), d.get("nom_commun_taxon")

    res = []
    with ThreadPoolExecutor(max_workers=workers) as ex:
        for e, n, latin, commun in ex.map(un, liste):
            if n == 0:
                etat = "jamais_vue_par_hubeau"
            elif esp.comparer_latin(e.get("latin") or "", latin or ""):
                etat = "ok"
            else:
                etat = "ecart_de_nom"
            res.append({"code": e["code"], "id": e.get("id"), "nom": e.get("nom"), "latin_attendu": e.get("latin"),
                        "latin_hubeau": latin, "commun_hubeau": commun, "lignes_hubeau": n, "etat": etat})
    return res


# --- main ----------------------------------------------------------------------------------------
def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--departement", nargs="+", metavar="CODE", help="seulement ces departements (ex. 94 ou 75 92 93)")
    ap.add_argument("--especes", help="especes.json de D1 (ou especes-national.json, ou un CSV avec code_sandre)")
    ap.add_argument("--departements-geojson", dest="geojson", help="departements.geojson (D1)")
    ap.add_argument("--sortie", help="dossier des 3 fichiers (defaut : outils/hubeau/sortie)")
    ap.add_argument("--config")
    ap.add_argument("--workers", type=int)
    ap.add_argument("--max-requetes", type=int, default=0, help="plafond optionnel d'appels (0 = aucun)")
    ap.add_argument("--cache-seulement", action="store_true", help="aucun appel reseau : echoue si une page manque")
    ap.add_argument("--recuperer-seulement", action="store_true", help="remplit le cache sans ecrire les fichiers")
    ap.add_argument("--verifier-especes", action="store_true")
    ap.add_argument("--sans-hydro", action="store_true")
    ap.add_argument("--trace", nargs="+", metavar="GEOJSON", help="D5 : trace des cours d'eau deja telecharge (sinon Sandre, dans le cache)")
    ap.add_argument("--sans-recalage", action="store_true", help="D5 : ne recale rien (toutes les stations arrondies, recalee: false)")
    ap.add_argument("--aujourdhui", help="AAAA-MM-JJ (tests)")
    a = ap.parse_args(argv)

    cfg = charger_config(a.config)
    aujourdhui = date.fromisoformat(a.aujourdhui) if a.aujourdhui else date.today()
    maj = aujourdhui.isoformat()
    cache = resoudre(cfg, cfg["cache_dir"])
    client = Client(cfg, os.path.join(cache, "pages"), a.max_requetes, log, hors_ligne=a.cache_seulement)
    workers = a.workers or cfg["workers"]
    chemins = cfg["chemins_defaut"]

    # espèces
    chemin_esp, avert = esp.trouver(a.especes, resoudre(cfg, chemins["especes"]), resoudre(cfg, cfg["especes_repli_csv"]))
    if avert:
        log("ATTENTION : " + avert)
    liste = esp.charger(chemin_esp)
    codes = [e["code"] for e in liste]
    log(f"{len(codes)} especes avec code Sandre ({chemin_esp})")
    rapports = resoudre(cfg, cfg["rapport_dir"])

    if a.verifier_especes:
        res = verifier_especes(client, cfg, liste, workers)
        ecrire_json(os.path.join(rapports, "especes-verifiees.json"), res)
        for r in res:
            if r["etat"] != "ok":
                print(f"{r['etat']:24} {r['code']:>6} {r['nom']} ({r['latin_attendu']}) -> Hub'Eau : "
                      f"{r['latin_hubeau']} / {r['commun_hubeau']} ({r['lignes_hubeau']} lignes)")
        print(f"{sum(r['etat'] == 'ok' for r in res)} codes concordants sur {len(res)}")
        return 0

    # polygones
    chemin_geo = a.geojson or resoudre(cfg, chemins["departements"])
    if not a.geojson:
        ok = False
        if os.path.exists(chemin_geo):
            with open(chemin_geo, encoding="utf-8") as f:
                ok = bool(json.load(f).get("features"))
        if not ok:
            chemin_geo = resoudre(cfg, chemins["departements_repli"])
            log(f"ATTENTION : departements.geojson de D1 absent ou vide : repli sur {chemin_geo} "
                "(polygones simplifies de la maquette, plus grossiers)")
    dep_index = geo.Departements.depuis_fichier(chemin_geo)
    with open(resoudre(cfg, cfg["regions"]), encoding="utf-8") as f:
        regions = json.load(f)["regions"]
    region_de = {d: r for r, v in regions.items() for d in v["departements"]}

    deps = a.departement or dep_index.codes
    inconnus = [d for d in deps if d not in dep_index.noms]
    if inconnus:
        log(f"Departement inconnu du geojson : {inconnus}")
        return 2

    try:
        log("Stations piscicoles...")
        lignes = recuperer_stations(client, cfg)
        stations, st_ecartees, infos = preparer_stations(lignes, dep_index, cfg["tolerance_bord_km"])
        log(f"{len(stations)} stations rangees, {len(st_ecartees)} ecartees")
        lots = lots_par_dep(stations, deps, cfg["piscicole"]["stations_par_lot"])
        ops, paires, echecs = recuperer_tout(client, cfg, codes, lots, workers)
    except QuotaError as e:
        log(f"ARRET : {e} (relancer : le cache reprend a la page pres)")
        return 3
    except HubeauError as e:
        log(f"ARRET : {e}")
        return 1
    if a.recuperer_seulement:
        log(f"Cache rempli pour {deps} ({len(echecs)} departements en echec).")
        return 1 if echecs else 0

    # comptes
    debut = comptes.debut_fenetre(aujourdhui, cfg["fenetre_annees"])
    complets = [d for d in deps if d not in echecs]
    stations_ok = {k: v for k, v in stations.items() if v["dep"] in complets}
    agr = comptes.agreger(stations_ok, ops, comptes.paires_vers_par_op(paires, set(codes)), debut)
    par_dep = {d: agr["departements"].get(d, {"dix_ans": comptes._vide(), "historique": comptes._vide()}) for d in complets}
    reg = comptes.comptes_regions(par_dep, regions, complets)

    # D5 : recalage sur le trace du cours d'eau (decision 8) ; chaque station porte `recalee`
    liste_st = [v for _, v in sorted(stations_ok.items()) if v["id"] in agr["stations"]]
    try:
        if a.sans_recalage:
            log("ATTENTION : --sans-recalage : toutes les stations arrondies a 0,01 degre, recalee: false")
            trace, vois = recalage.Trace(), None
        elif a.trace:
            trace, vois = recalage.Trace.depuis_fichiers(*a.trace), None
        else:
            trace, vois = recalage.preparer_trace(liste_st, os.path.join(cache, "trace"), log)
    except Exception as e:  # reseau ou service Sandre : on s'arrete, on n'ecrit pas un fichier a moitie recale
        log(f"ARRET : trace des cours d'eau indisponible ({e}) ; relancer (le cache reprend) ou donner --trace")
        return 4
    rap_recalage = recalage.recaler_stations(liste_st, trace, voisinage=vois)
    log(f"Recalage : {rap_recalage['recalees']}/{rap_recalage['stations']} stations sur le trace "
        f"(ecart median {rap_recalage['ecart_median_m']} m) ; non recalees : {rap_recalage['raisons_false']}")

    entete = {"source": cfg["source_piscicole"], "licence": cfg["licence"], "mis_a_jour": maj,
              "dix_ans_depuis": debut, "dix_ans_jusqu_a": maj}
    recs = []
    for sid, s in sorted(stations_ok.items()):
        c = agr["stations"].get(sid)
        if not c:
            continue
        recs.append({"id": sid, "lat": s["lat"], "lon": s["lon"], "dep": s["dep"], "eau": s["eau"], "code_eau": s["code_eau"],
                     "recalee": s["recalee"],
                     "peches": c["dix_ans"]["peches"],
                     "derniere": c["derniere_dix_ans"],
                     "vues": {k: v["peches"] for k, v in sorted(c["dix_ans"]["especes"].items())},
                     "historique": {"peches": c["historique"]["peches"], "derniere": c["derniere"],
                                    "vues": {k: v["peches"] for k, v in sorted(c["historique"]["especes"].items())}}})
    doc_s = dict(entete, note="peches, derniere, vues : fenetre de 10 ans ; historique : toutes les annees. Une peche = "
                 "une operation OFB avec au moins un poisson ; vues = code Sandre -> nombre de peches ou l'espece est vue. "
                 "recalee : true = position (5 decimales) projetee sur le trace Sandre du cours d'eau (300 m au plus), eau = nom du trace ; "
                 "false = aucun trace ne la recoit, position arrondie a 0,01 degre (la carte dessine un halo, pas une epingle).",
                 stations=recs)
    doc_r = dict(entete, departements={d: {"region": region_de.get(d), **par_dep[d]} for d in complets},
                 regions={r: v for r, v in reg.items()},
                 table_regions="INSEE, code officiel geographique (outils/hubeau/regions.json)")

    sortie = a.sortie or resoudre(cfg, cfg["sortie_dir"])
    tailles = {"stations-especes.json": ecrire_json(os.path.join(sortie, "stations-especes.json"), doc_s),
               "rarete-departements.json": ecrire_json(os.path.join(sortie, "rarete-departements.json"), doc_r)}
    hydro_ecart = []
    if not a.sans_hydro:
        try:
            doc_h, hydro_ecart = fabriquer_hydro(client, cfg, dep_index, maj, cfg["tolerance_bord_km"])
            if a.departement:
                doc_h["stations"] = [s for s in doc_h["stations"] if s["dep"] in deps]
            tailles["stations-hydro.json"] = ecrire_json(os.path.join(sortie, "stations-hydro.json"), doc_h)
        except HubeauError as e:
            log(f"hydrometrie : ECHEC {e}")
            echecs["hydro"] = [str(e)]

    # rapport
    desaccords = [s for s in stations_ok.values() if s["dep_api"] and s["dep_api"] != s["dep"]]
    region_ko = [s["id"] for s in stations_ok.values()
                 if s["region_api"] and region_de.get(s["dep"]) != str(s["region_api"])]
    rap = {"date": maj, "departements_demandes": deps, "departements_en_echec": echecs,
           "departements_sans_peche": [d for d in complets if par_dep[d]["historique"]["peches"] == 0],
           "departements_sans_peche_10_ans": [d for d in complets if par_dep[d]["dix_ans"]["peches"] == 0],
           "stations_ecartees": st_ecartees, "stations_hydro_ecartees": hydro_ecart,
           "stations_rangees_par_bord": [s["id"] for s in stations_ok.values() if s["mode"] == "bord"],
           "stations_dep_api_different_du_polygone": len(desaccords),
           "exemples_dep_api_different": [{"id": s["id"], "polygone": s["dep"], "api": s["dep_api"]} for s in desaccords[:30]],
           "stations_region_api_differente_de_la_table": region_ko[:30],
           "conflits_cours_d_eau": infos["conflits_eau"][:30],
           "operations": agr["ecartees"] | {"lues": len(ops)},
           "recalage": rap_recalage, "stations_dans_le_fichier": len(recs), "octets": tailles,
           "appels_api": client.n_requetes, "pages_en_cache": client.n_cache, "secondes_api": round(client.secondes_api)}
    ecrire_json(os.path.join(rapports, "rapport.json"), rap)
    log(f"Fichiers dans {sortie} : {tailles}")
    log(f"Rapport : {os.path.join(rapports, 'rapport.json')}")
    log(f"Departements sans peche : {rap['departements_sans_peche']} ; stations ecartees : {len(st_ecartees)}")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
