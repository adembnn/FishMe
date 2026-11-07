# Table d'espèces des États-Unis (lot us-especes)

Table d'eau douce propre aux États-Unis, à côté (pas à la place) de `Packages/Core/Sources/Core/Resources/especes.json` (France, 99 entrées). Base : `reports/us/especes-reconnaissance.md` (78 espèces ou hybrides) ; la liste détaillée donne **80 entrées** : le rapport n'en comptait que 78 parce qu'il groupait certaines lignes, et on ajoute le black-bass de Floride (`Micropterus floridanus`, distinct selon l'AFS 2013).

## Fichiers
| Fichier | Rôle |
|---|---|
| `especes-us.json` | 80 entrées : slug, nom_en, nom_fr, latin, famille, statut (native / introduite / invasive), regions (natif / introduit), groupe_confusion, categorie, remarques, correspondance_fr, protection_a_verifier, verifie, source |
| `correspondance-fr.json` / `.md` | 20 espèces identiques à un slug français existant, 18 proches mais distinctes (avec risque de confusion), 4 pièges de nom, 42 sans équivalent |
| `groupes-confusion.json` | 16 groupes pour la grille « Autre » (black bass, sunfish, crappies, catfish, bullheads, truites, saumons...) |
| `verifier.py` | schéma, doublons de slug et de latin, latin non vide, source ou `[?]`, groupes et slugs français valides |
| `recouper_sources.py` | (réseau) recoupe ITIS et USGS NAS et réécrit `verifie`, `source`, `a_verifier` |
| `tests/` | tests de `verifier.py` |

## Commandes
```
cd outils/us/especes
python3 -I verifier.py          # attendu : « 0 trou »
python3 -I -m unittest          # 6 tests
python3 recouper_sources.py     # facultatif, réseau, ~3 min
```

## Ce qui est vérifié
- **Latin** : nom valide dans ITIS (URL de la fiche TSN dans `source`). 77 sur 80.
- **Statut** : l'USGS NAS (base des espèces non indigènes) classe l'espèce « native » ou « exotic », cohérent avec notre `statut` (URL de la fiche dans `source`). 72 sur 80.
- Vérifié = latin + statut confirmés : **72 sur 80**. Les 8 autres portent `a_verifier: "[?] ..."` : 3 hybrides d'élevage (wiper, saugeye, tiger muskie), florida-bass (NAS le range sous M. salmoides), suwannee-bass, longnose-gar, shovelnose-sturgeon (absents du NAS) et redhorse (genre).
- « invasive » = invasive pour l'USGS/USFWS dans l'aire d'introduction ; la carpe commune et le poisson rouge restent « introduite ».

## Non vérifié (à ne pas présenter comme sourcé)
- Noms français : usage courant (Québec, Wikipédia) ; seuls les slugs existants de la table française font foi.
- Régions, remarques de reconnaissance et `critere` des groupes : connaissance générale d'ichtyologie.
- `protection_a_verifier` : liste d'espèces à statut variable (ESA, États) ; aucune n'est une règle. Rien ne doit être affiché « peut être gardé » (règle du dépôt).

## Limites
- Les statuts viennent de l'USGS pour l'ensemble du pays ; une espèce native mais introduite hors de son aire (largemouth, rainbow...) reste « native » avec `regions.introduit` renseigné.
- Les groupes `carpe_cyprin` et `catostomide` partagent les buffalos ; `groupe_confusion` donne le groupe principal.
