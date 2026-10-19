"""Geographie en Python pur : Lambert 93 -> WGS84 et point dans un polygone.

Une station est rangee dans UN departement d'apres ses coordonnees et departements.geojson,
jamais d'apres le champ code_departement de l'API (qui range 03082000 tantot en 92, tantot en 93).
"""
from __future__ import annotations

import json
import math

# --- Lambert 93 (RGF93) -> longitude/latitude (RGF93 = WGS84 a ~1 m pres) -----------------------
_A = 6378137.0
_E = 0.0818191910428158
_LON0 = math.radians(3.0)
_PHI0, _PHI1, _PHI2 = (math.radians(x) for x in (46.5, 44.0, 49.0))
_X0, _Y0 = 700000.0, 6600000.0


def _m(phi):
    return math.cos(phi) / math.sqrt(1 - _E ** 2 * math.sin(phi) ** 2)


def _t(phi):
    return math.tan(math.pi / 4 - phi / 2) / (((1 - _E * math.sin(phi)) / (1 + _E * math.sin(phi))) ** (_E / 2))


_N = (math.log(_m(_PHI1)) - math.log(_m(_PHI2))) / (math.log(_t(_PHI1)) - math.log(_t(_PHI2)))
_F = _m(_PHI1) / (_N * _t(_PHI1) ** _N)
_RHO0 = _A * _F * _t(_PHI0) ** _N


def lambert93_vers_wgs84(x: float, y: float) -> tuple[float, float]:
    """(x, y) en metres Lambert 93 -> (longitude, latitude) en degres."""
    dx, dy = x - _X0, _RHO0 - (y - _Y0)
    r = math.hypot(dx, dy)
    gamma = math.atan2(dx, dy)
    lon = _LON0 + gamma / _N
    t = (r / (_A * _F)) ** (1 / _N)
    phi = math.pi / 2 - 2 * math.atan(t)
    for _ in range(12):
        phi = math.pi / 2 - 2 * math.atan(t * ((1 - _E * math.sin(phi)) / (1 + _E * math.sin(phi))) ** (_E / 2))
    return math.degrees(lon), math.degrees(phi)


# --- point dans un polygone ---------------------------------------------------------------------
def _dans_anneau(lon, lat, anneau) -> bool:
    dedans = False
    j = len(anneau) - 1
    for i in range(len(anneau)):
        xi, yi = anneau[i][0], anneau[i][1]
        xj, yj = anneau[j][0], anneau[j][1]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi) + xi:
            dedans = not dedans
        j = i
    return dedans


def _dans_polygone(lon, lat, polygone) -> bool:
    """polygone = [anneau exterieur, trous...]"""
    if not _dans_anneau(lon, lat, polygone[0]):
        return False
    return not any(_dans_anneau(lon, lat, trou) for trou in polygone[1:])


def _dist_segment_km(lon, lat, a, b) -> float:
    k = math.cos(math.radians(lat))
    px, py = lon * k * 111.32, lat * 110.57
    ax, ay = a[0] * k * 111.32, a[1] * 110.57
    bx, by = b[0] * k * 111.32, b[1] * 110.57
    dx, dy = bx - ax, by - ay
    n = dx * dx + dy * dy
    t = 0.0 if n == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / n))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


class Departements:
    """Index des departements a partir d'un GeoJSON (Polygon ou MultiPolygon)."""

    def __init__(self, geojson: dict, cle_code=("code", "code_dep", "code_departement", "INSEE_DEP")):
        self.polys: list[tuple[str, list, tuple]] = []
        self.noms: dict[str, str] = {}
        for f in geojson.get("features", []):
            props = f.get("properties", {})
            code = next((str(props[c]) for c in cle_code if props.get(c) is not None), None)
            if code is None:
                raise ValueError(f"departement sans code dans les proprietes : {list(props)}")
            self.noms[code] = props.get("nom", "")
            g = f["geometry"]
            polys = [g["coordinates"]] if g["type"] == "Polygon" else g["coordinates"]
            for p in polys:
                xs = [pt[0] for pt in p[0]]
                ys = [pt[1] for pt in p[0]]
                self.polys.append((code, p, (min(xs), min(ys), max(xs), max(ys))))

    @classmethod
    def depuis_fichier(cls, chemin: str):
        with open(chemin, encoding="utf-8") as f:
            return cls(json.load(f))

    @property
    def codes(self) -> list[str]:
        return sorted(self.noms)

    def dans(self, lon: float, lat: float) -> str | None:
        """Code du departement dont un polygone contient le point, sinon None."""
        for code, p, (x0, y0, x1, y1) in self.polys:
            if x0 <= lon <= x1 and y0 <= lat <= y1 and _dans_polygone(lon, lat, p):
                return code
        return None

    def plus_proche(self, lon: float, lat: float, max_km: float):
        """(code, distance_km) du polygone le plus proche s'il est a max_km au plus, sinon (None, distance)."""
        meilleur, d_min = None, float("inf")
        marge = max_km / 80.0 + 0.01
        for code, p, (x0, y0, x1, y1) in self.polys:
            if not (x0 - marge <= lon <= x1 + marge and y0 - marge <= lat <= y1 + marge):
                continue
            for anneau in p:
                for i in range(len(anneau) - 1):
                    d = _dist_segment_km(lon, lat, anneau[i], anneau[i + 1])
                    if d < d_min:
                        meilleur, d_min = code, d
        return (meilleur if d_min <= max_km else None), d_min

    def ranger(self, lon: float, lat: float, tolerance_km: float = 0.0):
        """Retourne (code, mode) ; mode = 'polygone' | 'bord' (proche d'un polygone, simplification du trait de cote
        ou de la frontiere) | None si hors de tous les departements."""
        code = self.dans(lon, lat)
        if code:
            return code, "polygone"
        if tolerance_km > 0:
            code, _ = self.plus_proche(lon, lat, tolerance_km)
            if code:
                return code, "bord"
        return None, None
