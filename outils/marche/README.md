# Outils d'étude de marché (gratuits, sans clé)

Données : `reports/marche/donnees/` (jamais commitées).
Venv : `python3 -m venv outils/marche/.venv && outils/marche/.venv/bin/pip install requests google-play-scraper`
Préfixe : `PY=outils/marche/.venv/bin/python3`

- `$PY outils/marche/fiche_appstore.py 6739852593 fr` — fiche App Store (iTunes lookup).
- `$PY outils/marche/avis_appstore.py 6739852593 fr de` — avis App Store par pays (RSS, 10 pages max).
- `$PY outils/marche/avis_play.py fr.fnpf.mapeche fr fr 500` — fiche + avis Google Play.
- `$PY outils/marche/reddit.py "fishing app" fishing` — recherche Reddit (subreddit optionnel).
- `$PY outils/marche/classer_avis.py reports/marche/donnees/avis-….csv` — tri grossier par thèmes.
- `$PY outils/marche/verifier.py reports/marche [--sans-reseau]` — vérifie les rapports.
- `python3 outils/marche/test_verifier.py` — tests du vérificateur (hors venv, stdlib).
