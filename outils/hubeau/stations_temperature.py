#!/usr/bin/env python3
"""D2 : fabrique `stations-temperature.json` (stations de temperature des cours d'eau, Hub'Eau).

Source : API Hub'Eau « Temperature des cours d'eau » (reseau Naiades),
  https://hubeau.eaufrance.fr/api/v1/temperature/station   (872 stations, metadonnees)
  https://hubeau.eaufrance.fr/api/v1/temperature/chronique (53 millions de mesures)
Licence : Licence Ouverte / Open Licence v2.0 (Etalab), voir LISEZMOI. A citer : « Source : Hub'Eau / Naiades ».

Sortie : un tableau JSON, une entree par station, lu par `StationTemperatureDonnee.decoder` (lot N3) :
  {"code": "03112480", "nom": "LA MARNE A CHARENTON-LE-PONT 2", "eau": "La Marne", "code_eau": "F---0100",
   "lat": 48.816895, "lon": 2.41963, "dep": "94", "en_service": true}
`eau` et `code_eau` valent null quand Hub'Eau n'a pas de cours d'eau pour la station.

Regle « en service » (documentee, a confirmer par Adem) : la station n'a pas de `date_mise_hors_service` ET elle a
au moins une mesure datee des JOURS derniers jours (30 par defaut). Hub'Eau ne donne pas la date de derniere mesure
dans la fiche station ; on demande donc a la chronique toutes les mesures depuis la date limite, code_station seul
(environ 10 000 lignes, une requete) et on garde les codes vus. Une requete par station est trop lente : Hub'Eau cale
souvent. Le tri `sort=desc` de la chronique n'est pas fiable (verifie sur l'API reelle), on ne s'en sert pas.
Les donnees ne sont pas en temps reel : l'API peut avoir plusieurs jours de retard.

Usage : python3 stations_temperature.py [--sortie sortie/stations-temperature.json] [--jours 30]
Une requete a la fois, pause entre deux, attente croissante sur 429/503 (comme trace_sandre.py du lot D5).
Bibliotheque standard seulement.
"""
import argparse
import datetime
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://hubeau.eaufrance.fr/api/v1/temperature"
USER_AGENT = "FishMe-D2/1.0 (stations-temperature)"
PAUSE_S = 0.3
TAILLE_PAGE = 1000
JOURS_PAR_DEFAUT = 30


def _attente(k: int, e) -> float:
    """Delai avant le prochain essai : croissant ; beaucoup plus long pour 429/503 (serveur surcharge ou qui limite)."""
    if isinstance(e, urllib.error.HTTPError) and e.code in (429, 503):
        ra = e.headers.get("Retry-After") if e.headers else None
        if ra and ra.isdigit():
            return min(float(ra), 300.0)
        return min(15.0 * (2 ** k), 300.0)
    return min(2.0 * (2 ** k), 60.0)


def obtenir(url: str, essais: int = 6, timeout: int = 120, log=print, dormir=time.sleep) -> dict:
    for k in range(essais):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, OSError, ConnectionError, json.JSONDecodeError) as e:
            if k == essais - 1:
                raise
            attente = _attente(k, e)
            log(f"  essai {k + 1}/{essais} rate ({e}) ; nouvel essai dans {attente:.0f} s")
            dormir(attente)
    raise RuntimeError("inatteignable")


def url_stations(page: int) -> str:
    return f"{BASE}/station?" + urllib.parse.urlencode({"size": TAILLE_PAGE, "page": page})


def url_mesures_depuis(depuis: datetime.date, page: int = 1) -> str:
    """Toutes les mesures depuis la date, code_station seul : environ 10 000 lignes pour 30 jours sur la France entiere."""
    return f"{BASE}/chronique?" + urllib.parse.urlencode(
        {"date_debut_mesure": depuis.isoformat(), "size": 20000, "page": page, "fields": "code_station"})


def telecharger_stations(log=print, obtenir_fn=obtenir) -> list:
    """Toutes les fiches station, page par page."""
    out, page = [], 1
    while True:
        j = obtenir_fn(url_stations(page))
        out.extend(j.get("data") or [])
        log(f"stations : {len(out)} / {j.get('count')}")
        if not j.get("next") or not j.get("data"):
            return out
        page += 1


def convertir(s: dict, en_service: bool):
    """Une fiche Hub'Eau -> une entree du format N3. None si la station n'a pas de code ou de coordonnees."""
    code, lat, lon = s.get("code_station"), s.get("latitude"), s.get("longitude")
    if not code or lat is None or lon is None:
        return None
    return {
        "code": str(code),
        "nom": s.get("libelle_station") or str(code),
        "eau": s.get("libelle_cours_eau") or None,
        "code_eau": s.get("code_cours_eau") or None,
        "lat": round(float(lat), 6),
        "lon": round(float(lon), 6),
        "dep": s.get("code_departement") or None,
        "en_service": bool(en_service),
    }


def stations_avec_mesures(depuis: datetime.date, log=print, obtenir_fn=obtenir) -> set:
    """Codes des stations qui ont au moins une mesure depuis la date : une requete (quelques pages au plus) pour tout le reseau."""
    codes, page = set(), 1
    while True:
        j = obtenir_fn(url_mesures_depuis(depuis, page))
        codes.update(d["code_station"] for d in j.get("data") or [] if d.get("code_station"))
        log(f"mesures depuis le {depuis} : {j.get('count')} lignes, {len(codes)} stations")
        if not j.get("next") or not j.get("data"):
            return codes
        page += 1
        time.sleep(PAUSE_S)


def construire(fiches: list) -> list:
    """`fiches` : fiches station, chacune avec la cle `_actif` (vrai si mesure recente). Doublons ignores, tri par code."""
    res, vus = [], set()
    for s in fiches:
        code = s.get("code_station")
        if code in vus:
            continue
        vus.add(code)
        e = convertir(s, bool(s.get("_actif")))
        if e:
            res.append(e)
    res.sort(key=lambda e: e["code"])
    return res


def ecrire(stations: list, chemin: str) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(chemin)), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(stations, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")


def main(argv=None) -> int:
    ici = os.path.dirname(os.path.abspath(__file__))
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--sortie", default=os.path.join(ici, "sortie", "stations-temperature.json"))
    p.add_argument("--jours", type=int, default=JOURS_PAR_DEFAUT, help="fenetre « en service » en jours")
    a = p.parse_args(argv)
    depuis = datetime.date.today() - datetime.timedelta(days=a.jours)
    fiches = telecharger_stations()
    actives = stations_avec_mesures(depuis)
    for s in fiches:
        s["_actif"] = s["code_station"] in actives and not s.get("date_mise_hors_service")
    stations = construire(fiches)
    ecrire(stations, a.sortie)
    n = sum(1 for s in stations if s["en_service"])
    print(f"{len(stations)} stations, {n} en service (mesure depuis le {depuis}) -> {a.sortie}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
