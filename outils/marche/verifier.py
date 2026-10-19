"""Vérificateur des rapports de marché dans un dossier (reports/marche/).
Usage : python3 verifier.py <dossier> [--sans-reseau]
Règles : 200 lignes max ; en-tête avec « Décision débloquée : » et une date
« Recherche du JJ/MM/AAAA » ou « Lu le JJ/MM/AAAA » ; tout chiffre avec unité
de marché cite sa source (http, (§, [S, « estimation » ou [?]) ; toute ligne de
section « Recommandation »/« Décision » cite un fait ; chaque URL est testée
(2xx/3xx ok, 401/403/429 bloqué non vérifié, 404/5xx/timeout échec), avec cache
dans donnees/liens-cache.json. Affiche « N trou(s) », code 0 si 0 trou."""
import json
import pathlib
import re
import sys
import time

import requests

CHIFFRE_UNITE = re.compile(
    r"\d[\d\s  .,]*\s?(%|€|\$|£|k\b|M\b|avis|notes|abonnés|téléchargements|"
    r"installs|utilisateurs|pêcheurs|cartes|membres|vues)", re.IGNORECASE)
URL_RE = re.compile(r"https?://[^\s)\]>\"']+")
DATE_RE = re.compile(r"(Recherche du|Lu le)\s+\d{2}/\d{2}/\d{4}")
UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/126.0 Safari/537.36"}

def verifier_fichier(f, sans_reseau, cache, cache_path):
    trous = []
    lignes = f.read_text(encoding="utf-8").splitlines()
    if len(lignes) > 200:
        trous.append(f"{f.name}:1 : {len(lignes)} lignes (> 200)")
    entete = "\n".join(lignes[:10])
    if "Décision débloquée :" not in entete or not DATE_RE.search(entete):
        trous.append(f"{f.name}:1 : en-tête sans « Décision débloquée : » "
                     f"ou sans date « Recherche du JJ/MM/AAAA » / « Lu le JJ/MM/AAAA »")
    urls, section_sourcee, en_code = set(), False, False
    for n, l in enumerate(lignes, 1):
        if l.strip().startswith("```"):
            en_code = not en_code
            continue
        if en_code:
            continue
        if l.startswith("#"):
            titre = l.lstrip("#").strip().lower()
            section_sourcee = "recommandation" in titre or "décision" in titre
        for u in URL_RE.findall(l):
            urls.add(u.rstrip(".,;"))
        if l.strip().startswith("|---"):
            continue
        if section_sourcee and re.match(r"\s*(-|\||\d)", l) and "http" not in l \
                and "(§" not in l and "[S" not in l:
            trous.append(f"{f.name}:{n} : ligne de section Recommandation/Décision sans source")
            continue
        if not CHIFFRE_UNITE.search(l):
            continue
        if "http" not in l and "(§" not in l and "[S" not in l \
                and "estimation" not in l.lower() and "[?]" not in l:
            trous.append(f"{f.name}:{n} : chiffre avec unité de marché sans source ni [?]")
    if not sans_reseau:
        for u in sorted(urls):
            statut = cache.get(u)
            if statut is None:
                statut = tester_url(u)
                cache[u] = statut
                cache_path.write_text(json.dumps(cache, ensure_ascii=False, indent=2),
                                      encoding="utf-8")
            if statut == "echec":
                trous.append(f"{f.name} : lien mort {u}")
    return trous

def tester_url(u):
    for _ in range(2):
        try:
            r = requests.get(u, headers=UA, timeout=10, allow_redirects=True)
            if 200 <= r.status_code < 400:
                return "ok"
            if r.status_code in (401, 403, 429):
                return "bloque"
            code = r.status_code
        except requests.RequestException:
            code = 0
        time.sleep(1)
    if code in (401, 403, 429):
        return "bloque"
    return "echec"

def main():
    args = [a for a in sys.argv[1:] if a != "--sans-reseau"]
    sans_reseau = "--sans-reseau" in sys.argv
    dossier = pathlib.Path(args[0])
    donnees = pathlib.Path(__file__).resolve().parents[2] / "reports" / "marche" / "donnees"
    donnees.mkdir(parents=True, exist_ok=True)
    cache_path = donnees / "liens-cache.json"
    cache = json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.exists() else {}

    trous = []
    for f in sorted(dossier.glob("*.md")):
        if f.name == "README.md":
            continue
        trous.extend(verifier_fichier(f, sans_reseau, cache, cache_path))
    bloques = [u for u, s in cache.items() if s == "bloque"]
    for t in trous:
        print(t)
    if bloques:
        print(f"liens bloqués, non vérifiés : {len(bloques)}")
    print(f"{len(trous)} trou(s)")
    sys.exit(0 if not trous else 1)

if __name__ == "__main__":
    main()
