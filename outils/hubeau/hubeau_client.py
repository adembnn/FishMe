"""Client minimal et poli pour l'API Hub'Eau "etat_piscicole".

- pause >= 0,3 s entre deux appels (config api.pause_s)
- reprise sur erreur (retries + backoff), timeouts longs (l'API est lente)
- cache disque gzip : un appel deja en cache n'est JAMAIS refait (idempotence / reprise)
- plafond de requetes par execution (config api.max_requests_par_execution)
Bibliotheque standard uniquement.
"""
from __future__ import annotations

import gzip
import http.client
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

OBS_FIELDS = [
    "code_operation", "date_operation", "code_station", "code_departement",
    "code_alternatif_taxon", "code_taxon", "nom_commun_taxon", "nom_latin_taxon",
    "effectif_lot", "code_type_lot", "taille_individu",
]
OPS_FIELDS = [
    "code_operation", "date_operation", "code_station", "code_departement",
    "libelle_departement", "operation_sans_poisson", "protocole_peche", "code_bassin",
]


class QuotaError(RuntimeError):
    pass


class HubeauClient:
    def __init__(self, cfg: dict, cache_dir: str, log=print):
        self.api = cfg["api"]
        self.cache_dir = cache_dir
        self.log = log
        self.n_requests = 0
        self.total_seconds = 0.0
        self._last_call = 0.0
        os.makedirs(cache_dir, exist_ok=True)

    # -- cache ---------------------------------------------------------
    def cache_path(self, endpoint: str, dep: str, tag: str) -> str:
        return os.path.join(self.cache_dir, endpoint, dep, f"{tag}.json.gz")

    def _read_cache(self, path: str):
        if not os.path.exists(path):
            return None
        try:
            with gzip.open(path, "rt", encoding="utf-8") as f:
                return json.load(f)
        except (OSError, ValueError):
            os.remove(path)  # fichier corrompu : on le refera
            return None

    def _write_cache(self, path: str, payload: dict) -> None:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with gzip.open(tmp, "wt", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
        os.replace(tmp, path)

    # -- HTTP ----------------------------------------------------------
    def _get_json(self, url: str) -> dict:
        last = None
        for attempt in range(self.api["retries"]):
            wait = self.api["pause_s"] - (time.time() - self._last_call)
            if wait > 0:
                time.sleep(wait)
            if self.n_requests >= self.api["max_requests_par_execution"]:
                raise QuotaError("plafond de requetes par execution atteint")
            self.n_requests += 1
            t0 = time.time()
            try:
                req = urllib.request.Request(url, headers={"User-Agent": self.api["user_agent"]})
                with urllib.request.urlopen(req, timeout=self.api["timeout_s"]) as r:
                    data = json.load(r)
                dt = time.time() - t0
                self.total_seconds += dt
                self._last_call = time.time()
                return data
            except (urllib.error.URLError, TimeoutError, ValueError, OSError, http.client.HTTPException) as e:
                last = e
                self._last_call = time.time()
                self.log(f"  [retry {attempt + 1}/{self.api['retries']}] {type(e).__name__}: {e}", file=sys.stderr) \
                    if self.log is print else self.log(f"retry {attempt + 1}: {e}")
                time.sleep(self.api["backoff_s"] * (attempt + 1))
        raise RuntimeError(f"echec apres {self.api['retries']} essais: {url} ({last})")

    def build_url(self, endpoint: str, params: dict) -> str:
        return f"{self.api['base']}/{endpoint}?" + urllib.parse.urlencode(params, safe=",")

    # -- acces haut niveau ---------------------------------------------
    def fetch_range(self, endpoint: str, dep: str, d_min: str, d_max: str, fields: list[str]):
        """Recupere toutes les lignes de [d_min, d_max] (dates ISO). Decoupe en deux si > page_size.
        Retourne (lignes, meta) ; meta = {'requetes_cache', 'requetes_api'}.
        """
        tag = f"{d_min}_{d_max}"
        path = self.cache_path(endpoint, dep, tag)
        cached = self._read_cache(path)
        if cached is not None:
            return cached["data"], {"cache": 1, "api": 0}
        size = self.api["page_size"]
        params = {"code_departement": dep, "date_operation_min": d_min, "date_operation_max": d_max,
                  "size": size, "fields": ",".join(fields)}
        t0 = time.time()
        res = self._get_json(self.build_url(endpoint, params))
        count = res.get("count", len(res["data"]))
        if count > size:
            # trop gros : on decoupe l'intervalle en deux et on recommence (sous-intervalles mis en cache)
            mid = _midpoint(d_min, d_max)
            if mid is None:
                raise RuntimeError(f"intervalle indivisible avec {count} lignes: {dep} {tag}")
            self.log(f"  {dep} {tag}: {count} lignes > {size}, decoupage")
            a, ma = self.fetch_range(endpoint, dep, d_min, mid[0], fields)
            b, mb = self.fetch_range(endpoint, dep, mid[1], d_max, fields)
            return a + b, {"cache": ma["cache"] + mb["cache"], "api": 1 + ma["api"] + mb["api"]}
        data = res["data"]
        self._write_cache(path, {"count": count, "data": data, "fetched": time.strftime("%Y-%m-%dT%H:%M:%S"),
                                 "seconds": round(time.time() - t0, 1)})
        return data, {"cache": 0, "api": 1}

    def count(self, endpoint: str, dep: str, d_min: str, d_max: str) -> int:
        """Nombre total de lignes (requete size=1, mise en cache)."""
        path = self.cache_path(endpoint, dep, f"count_{d_min}_{d_max}")
        cached = self._read_cache(path)
        if cached is not None:
            return cached["count"]
        res = self._get_json(self.build_url(endpoint, {
            "code_departement": dep, "date_operation_min": d_min, "date_operation_max": d_max,
            "size": 1, "fields": "code_operation"}))
        self._write_cache(path, {"count": res.get("count", 0)})
        return res.get("count", 0)


def _midpoint(d_min: str, d_max: str):
    """Coupe [d_min, d_max] (YYYY-MM-DD) en deux intervalles contigus, None si un seul jour."""
    from datetime import date, timedelta
    a, b = date.fromisoformat(d_min), date.fromisoformat(d_max)
    if a >= b:
        return None
    m = a + (b - a) // 2
    return m.isoformat(), (m + timedelta(days=1)).isoformat()
