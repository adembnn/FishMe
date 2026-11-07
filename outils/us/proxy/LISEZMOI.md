# Conditions US : proxy et clients (lot us-conditions)

Code Swift : `Packages/Core/Sources/Core/ConditionsUS/` (tests : `Packages/Core/Tests/CoreTests/ConditionsUS/`). Ce dossier : le Worker Cloudflare `fishme-us-proxy`.

## Endpoints vérifiés (appel réel le 7 nov. 2026, sauf mention)

| Usage | URL |
|---|---|
| Stations USGS | `https://api.waterdata.usgs.gov/ogcapi/v1/collections/monitoring-locations/items?bbox=O,S,E,N&f=json` ou `?id=USGS-01646500` |
| Dernières mesures | `.../collections/latest-continuous/items?monitoring_location_id=USGS-01646500&parameter_code=00060,00065,00010&f=json` |
| Série | `.../collections/continuous/items?...&datetime=P2D` |
| Alertes NWS | `https://api.weather.gov/alerts/active?area=VA` (ou `?point=lat,lon`) ; User-Agent obligatoire |
| Crue NWPS | `https://api.water.noaa.gov/nwps/v1/gauges/{LID}` et `/gauges/{LID}/stageflow` |

Constats : `value` USGS est une chaîne (« "2120" ») ; unités reçues `ft^3/s`, `ft`, `degC` ; `approval_status` = `Provisional` ou `Approved` ; une station peut renvoyer plusieurs séries 00010. NWPS écrit -999 / -9999 pour « absent » (lu comme `nil`). Les 00060/00065/00010 de la station témoin ont tous répondu. Chemins NWPS vérifiés sur la station WASD2 seulement.

## Garde-fous

- Aucune clé dans git : `npx wrangler secret put USGS_API_KEY` ; côté Swift la clé est un paramètre d'exécution, envoyée en `X-Api-Key`, jamais dans l'URL.
- Le proxy ne lit que le chemin `/station/<id>` (chaîne de requête, en-têtes et IP ignorés) ; `observability` est désactivée ; clé de cache = identifiant de station. Côté app, la position n'existe que sous forme d'identifiant ou de `CelluleUS` (0,1°).
- Chaque `MesureUSGS` porte l'attribution USGS et, si elle est provisoire, l'avertissement officiel ; la réponse du proxy contient le même bloc `fishme`.
- Unités brutes (ft³/s, ft, °C, kcfs) : conversions au lot us-core.

## Lancer

- Tests : `cd outils/us/proxy && python3 banc.py` (node n'est pas installé ici : le banc lance les mêmes cas `test/cas.js` avec `jsc`, le moteur de macOS ; avec node : `node --test`). 6 cas passés.
- Déploiement : `npx wrangler deploy` (compte Cloudflare d'Adem/Titouan, non fait).

## Limites

- `src/index.js` (cache Cloudflare, `fetch`) n'est pas exécuté par les tests (seulement vérifié syntaxiquement) : à essayer avec `npx wrangler dev`.
- Pas de limitation de débit par client dans le proxy ; sans clé USGS, 429 rapides.
- NWS : limites non publiées, nouvel essai possible après environ 5 s ; le client renvoie `limiteAtteinte` sans réessayer seul.
- Cache en mémoire (durée de l'app) ; repli sur la dernière réponse de moins d'une heure si 429, 5xx ou réseau coupé.

## À confirmer

- Dates de retrait de `waterservices.usgs.gov` : la page officielle (waterdata.usgs.gov/blog/api-waterservices-decom/) répond 403 ; dates relevées ailleurs (ralentissement dès le 16 nov. 2026, arrêt autour du 22 févr. 2027) non confirmées. FishMe ne s'appuie pas sur l'ancienne API.
- Quota api.data.gov : la doc USGS ne donne aucun chiffre ; un exemple montre `X-RateLimit-Limit: 1000` sans dire si c'est avec ou sans clé. À mesurer avec une vraie clé (en-têtes `X-RateLimit-*`).
- Part des stations avec température (00010) : à mesurer via `time-series-metadata`.
- WeatherKit : hors de ce lot.
