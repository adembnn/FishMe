# Poissons signalés par zone (US16) : format des fichiers

Dossier embarqué : `Packages/Core/Sources/Core/Resources/especes-us/`. Un fichier par État ET par producteur (aucun conflit entre agents ; le chargeur Core fusionne par État) :
`<USPS>-agence.json` (listes et rapports officiels de l'agence), `<USPS>-gbif.json` (occurrences GBIF CC0/CC BY agrégées), `<USPS>-nas.json` (USGS NAS), `<USPS>-biodata.json` (USGS BioData / Water Quality Portal / EPA NRSA), `<USPS>-signalements.json` (forums et sites publics, confiance « non confirmé »).

```json
{"format": "fishme-especes-us/1", "etat": "WI", "producteur": "agence|gbif|nas|biodata|signalements", "date": "2026-11-07",
 "sources": [{"nom": "...", "url": "https://...", "licence": "CC0-1.0 | CC-BY-4.0 | domaine public fédéral | non précisée", "date": "AAAA-MM-JJ", "jeu": "DOI ou identifiant du jeu (GBIF)"}],
 "entrees": [{"slug": "largemouth-bass | null", "nom": "Largemouth bass", "latin": "Micropterus salmoides",
              "zone": {"type": "etat|huc8|plan_eau", "id": "WI | 04030101 | 3dhp:<id> ou nom public", "nom": "Lake Mendota"},
              "preuve": "liste_agence|empoissonnement|enquete_peche_electrique|occurrence_gbif|nas|biodata|signalement_public",
              "src": 0, "confiance": "officielle|enregistrement_scientifique|non confirmé, signalement public",
              "n": 12, "annee_max": 2024}]}
```
- `slug` = slug de `especes-us.json` (80 espèces) ; `null` si l'espèce n'y est pas (alors `latin` obligatoire, pas d'image).
- `src` = indice dans `sources` ; chaque source a url https, licence, date. Licence GBIF : CC0-1.0 ou CC-BY-4.0 seulement ; un enregistrement CC BY NC ou « non précisée » est écarté.
- `n` et `annee_max` : nombre d'enregistrements et année la plus récente quand ils existent (jamais inventés).
- Zone HUC8 : code à 8 chiffres du WBD. Plan d'eau : nom public seulement ; AUCUNE coordonnée d'un coin privé.
- « signalement_public » (forums) : confiance `non confirmé, signalement public`, jamais seul pour affirmer une espèce dans une zone ; pas de nom d'utilisateur, pas de lien vers un message.
- Aucune « rareté », aucun mot de permission.
