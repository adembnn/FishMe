"""Client poli pour les API Hub'Eau (etat_piscicole v1, hydrometrie v2).

Repris du client de Titouan, adapte pour D2 :
- suit le lien `next` (code HTTP 206 = suite a venir) page apres page ;
- chaque page est mise en cache sur disque (gzip) : un lancement interrompu reprend a la page pres,
  un appel deja en cache n'est jamais refait (tant qu'il a moins de `cache_validite_jours`) ;
- pause minimale entre deux appels (partagee entre les threads), reprises avec attente croissante ;
- size reduit et `fields` reduit (voir config.json) ; plafond de `size` mesure le 15 oct. 2026 : voir README.
Bibliotheque standard uniquement.
"""
from __future__ import annotations

import gzip
import hashlib
import http.client
import json
import os
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request


class HubeauError(RuntimeError):
    pass


class QuotaError(HubeauError):
    """Plafond optionnel de requetes (--max-requetes) atteint."""


class Client:
    def __init__(self, cfg: dict, cache_dir: str, max_requetes: int = 0, log=None, hors_ligne: bool = False):
        self.hors_ligne = hors_ligne
        self.api = cfg["api"]
        self.cache_dir = cache_dir
        self.max_requetes = max_requetes
        self.log = log or (lambda msg: print(msg, file=sys.stderr, flush=True))
        self.n_requetes = 0
        self.n_cache = 0
        self.secondes_api = 0.0
        self._lock = threading.Lock()
        self._prochain_appel = 0.0
        os.makedirs(cache_dir, exist_ok=True)

    # -- cache ---------------------------------------------------------
    def chemin_cache(self, url: str) -> str:
        h = hashlib.sha1(url.encode("utf-8")).hexdigest()
        return os.path.join(self.cache_dir, h[:2], f"{h}.json.gz")

    def _lire_cache(self, chemin: str):
        if not os.path.exists(chemin):
            return None
        validite = self.api.get("cache_validite_jours")
        if validite and time.time() - os.path.getmtime(chemin) > validite * 86400:
            return None
        try:
            with gzip.open(chemin, "rt", encoding="utf-8") as f:
                return json.load(f)
        except (OSError, ValueError, EOFError):
            try:
                os.remove(chemin)  # fichier corrompu : on le refera
            except OSError:
                pass
            return None

    def _ecrire_cache(self, chemin: str, contenu: dict) -> None:
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        tmp = f"{chemin}.{threading.get_ident()}.tmp"
        with gzip.open(tmp, "wt", encoding="utf-8") as f:
            json.dump(contenu, f, ensure_ascii=False, separators=(",", ":"))
        os.replace(tmp, chemin)

    # -- HTTP ----------------------------------------------------------
    def _attendre_tour(self) -> None:
        with self._lock:
            maintenant = time.time()
            attente = self._prochain_appel - maintenant
            self._prochain_appel = max(maintenant, self._prochain_appel) + self.api["pause_s"]
        if attente > 0:
            time.sleep(attente)

    def _get_json(self, url: str) -> dict:
        derniere = None
        for essai in range(self.api["retries"]):
            self._attendre_tour()
            with self._lock:
                if self.max_requetes and self.n_requetes >= self.max_requetes:
                    raise QuotaError(f"plafond de {self.max_requetes} requetes atteint")
                self.n_requetes += 1
            t0 = time.time()
            try:
                req = urllib.request.Request(url, headers={"User-Agent": self.api["user_agent"],
                                                           "Accept": "application/json"})
                with urllib.request.urlopen(req, timeout=self.api["timeout_s"]) as r:
                    donnees = json.load(r)
                with self._lock:
                    self.secondes_api += time.time() - t0
                return donnees
            except urllib.error.HTTPError as e:
                derniere = e
                if e.code in (400, 403, 404):  # inutile de reessayer : requete refusee
                    corps = ""
                    try:
                        corps = e.read().decode("utf-8", "replace")[:300]
                    except Exception:
                        pass
                    raise HubeauError(f"HTTP {e.code} sur {url} : {corps}") from e
                self.log(f"  [reprise {essai + 1}/{self.api['retries']}] HTTP {e.code} : {url[:120]}")
            except (urllib.error.URLError, TimeoutError, ValueError, OSError, http.client.HTTPException) as e:
                derniere = e
                self.log(f"  [reprise {essai + 1}/{self.api['retries']}] {type(e).__name__} : {e} ({url[:100]}...)")
            time.sleep(self.api["backoff_s"] * (essai + 1))
        raise HubeauError(f"echec apres {self.api['retries']} essais : {url} ({derniere})")

    def url(self, base: str, endpoint: str, params: dict) -> str:
        return f"{base}/{endpoint}?" + urllib.parse.urlencode(params, safe=",:")

    # -- acces haut niveau ---------------------------------------------
    def page(self, url: str) -> dict:
        """Une page, depuis le cache si possible. Retourne la reponse complete de l'API."""
        chemin = self.chemin_cache(url)
        en_cache = self._lire_cache(chemin)
        if en_cache is not None:
            with self._lock:
                self.n_cache += 1
            return en_cache
        if self.hors_ligne:
            raise HubeauError(f"page absente du cache (mode --cache-seulement) : {url}")
        reponse = self._get_json(url)
        self._ecrire_cache(chemin, reponse)
        return reponse

    def toutes_les_lignes(self, base: str, endpoint: str, params: dict):
        """Generateur de lignes : suit `next` jusqu'a la derniere page (HTTP 206 = suite a venir)."""
        url = self.url(base, endpoint, params)
        vues = set()
        while url:
            if url in vues:
                raise HubeauError(f"boucle de pagination : {url}")
            vues.add(url)
            rep = self.page(url)
            for ligne in rep.get("data", []):
                yield ligne
            url = rep.get("next")

    def compte(self, base: str, endpoint: str, params: dict) -> int:
        p = dict(params)
        p["size"] = 1
        return self.page(self.url(base, endpoint, p)).get("count", 0)
