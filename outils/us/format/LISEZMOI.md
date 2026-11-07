# Format des fichiers de règles US (`regles-us/`) et niveau 1

Lot us-format, 7 nov. 2026. Code Swift : `Packages/Core/Sources/Core/RegionUS/` (`FormatReglesUS.swift`, `Niveau1US.swift`, `EvaluateurUS.swift`). Données embarquées : `Packages/Core/Sources/Core/Resources/regles-us/`.

## Ce que contient le dossier `regles-us/`

| Fichier | Rôle |
|---|---|
| `index.json` | États présents, niveau de couverture, date, version de format, somme sha256 de chaque fichier, marque `etat-de-la-donnee` du niveau 1 |
| `<USPS>.json` | Règles d'un État (une fois confirmées par la double lecture ou par une personne) |
| `etats.json` | Niveau 1 : copie **telle quelle** du fichier du lot us-etats (51 entrées ; 32 États relus sur une page officielle le 7 nov. 2026, voir outils/us/etats/verifs/) |

Livrés par le lot us-consensus (7 nov.) : `WI.json` (30 règles) et `MN.json` (55 règles), générés par `python3 -I outils/us/format/vers_regles_us.py WI MN` depuis `outils/us/regles/donnees/<USPS>/consensus.json`.

## `index.json`

```json
{"format": 1, "version": "2026-11-07.1", "date": "2026-11-07",
 "etats": {"WI": {"niveau": 2, "regles": 41, "sha256": "…", "expire_min": "2027-01-01"}},
 "niveau1": {"fichier": "etats.json", "etat_de_la_donnee": "…", "date": "2026-11-07", "sha256": "…"}}
```
`niveau` : 2 (règles par espèce à l'échelle de l'État) ou 3 (jusqu'au plan d'eau). `etat_de_la_donnee` : phrase honnête sur l'état du niveau 1 (qui est relu, qui ne l'est pas). Si `sha256` est présent, le chargeur refuse un fichier modifié.

## `<USPS>.json`

Champs de tête : `format` (1), `etat` (code USPS, égal au nom du fichier), `nom_etat`, `lien_agence` (https, facultatif), `version`, `genere_le` (AAAA-MM-JJ), `couverture` (2 ou 3), `fixture` (true : exemple factice, refusé en production), puis trois listes.

**`juridictions`** (l'État est implicite, id `US-<USPS>`) : `id` (chemin lisible stable, ex. `US-WI/nord/lac-x`), `niveau` (`zone`, `plan_eau`, `troncon`), `nom`, `parent` (défaut : l'État), `huc8` (8 chiffres, facultatif), `alertes` (`reserve_tribale`, `refuge_federal`, `parc_national`, `eau_frontaliere`, `espece_listee_esa`), `lien_agence`.

**`regles`** : une entrée = un `RegleUS`. `id`, `portee` (id de juridiction du fichier), `espece` (id d'espèce de l'app ; absent = toutes), `saison` `{du, au}` en `MM-JJ` (peut enjamber le 31 déc.), `tailles` `{minimale, maximale, fenetre:{basse, haute}}` (chaque longueur a **une seule** unité : `pouces`, `cm` ou `mm`), `limites` `{prise, possession}`, `engins`, `appats`, `fermetures` `[{type, du, au, motif}]` (`peche_interdite`, `remise_a_eau_seulement`, `espece_protegee`), `age` `{min, max}`, `couverture` (défaut : celle du fichier), `valide_jusqua`, `source`, `statut`.
Une valeur absente veut dire « non lue », jamais « sans limite ». Une règle sans aucune contrainte est refusée.

`source` : `url` (**https** obligatoire), `date` (date de lecture, AAAA-MM-JJ), `edition`, `citation` (extrait exact, **3 à 200 caractères**, obligatoire pour une règle).

`statut` (**obligatoire**, jamais de défaut) : `non_relue`, `double_lecture_confirmee`, `lectures_divergentes`, `relue_par_personne`. Seuls les deux statuts confirmés peuvent fonder « interdit » dans le moteur.

**`exigences`** (permis, timbres) : `id`, `portee`, `type` (`permis`, `timbre`, `permis_tribal`), `nom`, `prix_dollars` (absent = non lu), `exempte_moins_de`, `source` (https + date ; citation facultative), `statut`.

Lien avec le pipeline de double lecture (`outils/us/regles/schema-regle-us.json`) : le consensus donne des règles typées (`taille_min`, `saison`, `limite_jour`…), une par contrainte, avec `portee` en texte libre. Le passage vers ce format regroupe les contraintes d'une même (portée, espèce) en une règle, convertit `portee` en id de juridiction, et reprend `source` et `citation` tels quels. Les statuts `brouillon` et `incertain` du pipeline ne produisent jamais `double_lecture_confirmee`. Convertisseur : `outils/us/format/vers_regles_us.py` (lot us-consensus, 7 nov.), une règle par (portée, espèce, famille), règles confirmées sans réserve seulement ; tests `test_vers_regles_us.py`.

## Refus du chargeur (`ErreurReglesUS`)

JSON illisible ou de mauvais type (avec le chemin du champ), `format` inconnu, `fixture: true` hors tests, État différent du nom du fichier, source en http ou sans date, citation de plus de 200 caractères, statut absent ou inconnu, portée absente des juridictions, règle vide, identifiant en double, hiérarchie incohérente, somme sha256 différente de l'index. Les clés inconnues sont ignorées (le format peut s'enrichir). Un fichier refusé n'apporte **aucune** règle, et n'empêche pas les autres États (`ChargementReglesUS.tout()` rend `erreurs` par État).

## Niveau 1 : `Niveau1US`

Lit `etats.json`. Par État : agence, liens (**https seulement** exposés), `prixResident` et `prixNonResident` (montant, année, source, `qualite` : `officiel`, `editeur`, `tiers`), `niveauVise`, `verifie`, `dateLecture`.

Règle produit : **un prix non vérifié n'est jamais présenté comme officiel.** `presentation(de:)` rend `officielVerifie` seulement si l'État est `verifie` ET la source `officiel`. Sinon `indicatifAVerifier(qualite:)`, et `texte(de:)` écrit « environ 17 $ (tarif 2026, source tierce [?]), vérifie sur le site de l'agence ». Une qualité inconnue compte comme `tiers`. `permisRequis` vaut `true` si un prix est lu, `nil` sinon (« non lu », jamais « pas de permis »). Aucun prix n'est corrigé : la copie embarquée est celle de us-etats, octet pour octet.

## Niveau 1 dans le moteur : `EvaluateurUS`

`EvaluateurUS(contenu:niveau1:verdictNiveau1:)` enveloppe `MoteurUS`. Un État du niveau 1 sans aucune règle chargée devient une juridiction racine (lien de l'agence) et reçoit `verdictNiveau1` : `.donneeAbsente` (défaut, décision du 7 nov. non tranchée) ou `.aVerifier`. Jamais « interdit ». Un État qui a des règles, ou un État inconnu, ne change pas.

## Valider un fichier

```
python3 -I outils/us/format/valider.py regles-us/WI.json
python3 -I outils/us/format/valider.py regles-us/index.json          # contrôle aussi les sha256 voisins
python3 -I outils/us/format/valider.py --autoriser-fixture outils/us/format/fixtures/WI-FIXTURE.json
python3 outils/us/format/test_valider.py                              # tests du validateur
```
Sort 0 si tout est valide, 1 sinon. Mêmes contrôles que le chargeur Swift ; le test Swift `decodageEtatDeTest` charge `fixtures/WI-FIXTURE.json`, ce qui garde les deux alignés.

## À faire côté intégration

`Packages/Core/Package.swift` doit déclarer `.copy("Resources/regles-us")` (hors périmètre de ce lot). Tant que ce n'est pas fait, `ChargementReglesUS.embarque()` et `Niveau1US.embarque()` ne trouvent pas le dossier dans le paquet (les tests lisent le dossier du dépôt directement).
