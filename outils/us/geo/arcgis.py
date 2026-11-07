"""Client minimal des services ArcGIS REST (bibliothèque standard seulement).

Interroge une couche (MapServer/FeatureServer) par emprise, récupère d'abord les identifiants (returnIdsOnly)
puis les objets par paquets (POST, objectIds) : marche même quand la pagination resultOffset n'est pas offerte.
Sortie : GeoJSON (f=geojson, WGS84).
"""
import json
import time
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = "FishMe-geo/1.0 (outils/us/geo; fishme.app@gmail.com)"
PAUSE_S = 0.25  # politesse envers les services d'État : une requête au plus tous les 0,25 s


def http_json(url, params=None, post=False, essais=4, timeout=90, dormir=time.sleep):
    """GET ou POST avec réessais exponentiels ; renvoie le JSON décodé. Une erreur ArcGIS (corps {"error":...}) lève RuntimeError."""
    donnees = urllib.parse.urlencode(params or {}).encode("utf-8")
    for k in range(essais):
        try:
            if post:
                req = urllib.request.Request(url, data=donnees, headers={"User-Agent": USER_AGENT})
            else:
                u = url + ("?" + donnees.decode() if donnees else "")
                req = urllib.request.Request(u, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                j = json.loads(r.read().decode("utf-8"))
            if isinstance(j, dict) and "error" in j:
                raise RuntimeError(f"erreur ArcGIS : {j['error']}")
            return j
        except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError, RuntimeError) as e:  # erreurs ArcGIS souvent passagères
            if k == essais - 1:
                raise
            dormir(min(2.0 * 2 ** k, 30.0))
    raise RuntimeError("inatteignable")


def url_couche(service, couche):
    return f"{service.rstrip('/')}/{couche}"


def _filtre(emprise, where):
    p = {"where": where or "1=1", "inSR": 4326, "outSR": 4326}
    if emprise:
        p.update({"geometry": ",".join(str(x) for x in emprise), "geometryType": "esriGeometryEnvelope",
                  "spatialRel": "esriSpatialRelIntersects"})
    return p


def compter(service, couche, emprise=None, where="1=1", http=http_json):
    p = _filtre(emprise, where)
    p.update({"returnCountOnly": "true", "f": "json"})
    return int(http(url_couche(service, couche) + "/query", p)["count"])


def identifiants(service, couche, emprise=None, where="1=1", http=http_json):
    p = _filtre(emprise, where)
    p.update({"returnIdsOnly": "true", "f": "json"})
    j = http(url_couche(service, couche) + "/query", p)
    return sorted(j.get("objectIds") or [])


def metadonnees(service, couche, http=http_json):
    """Fiche de la couche : champs, maxRecordCount, copyrightText, etc."""
    return http(url_couche(service, couche), {"f": "json"})


def telecharger(service, couche, emprise=None, where="1=1", champs="*", generalisation=None,
                paquet=None, max_objets=None, http=http_json, pause=PAUSE_S, dormir=time.sleep, log=print):
    """Liste de features GeoJSON de la couche dans l'emprise (minLon, minLat, maxLon, maxLat)."""
    ids = identifiants(service, couche, emprise, where, http)
    total = len(ids)
    if max_objets:
        ids = ids[:max_objets]
    if paquet is None:
        paquet = 200  # prudent : tolère aussi les couches à maxRecordCount de 1000, géométries lourdes comprises
    sortie = []
    for i in range(0, len(ids), paquet):
        lot = ids[i:i + paquet]
        p = {"objectIds": ",".join(str(x) for x in lot), "outFields": champs, "returnGeometry": "true",
             "outSR": 4326, "f": "geojson"}
        if generalisation:
            p["maxAllowableOffset"] = generalisation
        j = http(url_couche(service, couche) + "/query", p, post=True)
        sortie.extend(j.get("features") or [])
        log(f"  {len(sortie)} / {len(ids)} objets (total dans l'emprise : {total})")
        dormir(pause)
    return sortie, total
