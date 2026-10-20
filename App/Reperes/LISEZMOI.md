# Repères privés (lot N6)

Code écrit sans Mac et sans compilateur Swift : **tests écrits, non exécutés ; rien n'a été compilé**. S ou A compile `App/Reperes/` avant toute fusion (`docs/compiler-sur-mac.md`).

## Décisions appliquées par défaut (à confirmer par Adem, `docs/fiches/N6.md`)
1. Coordonnées exactes : sur l'iPhone, et dans l'iCloud privé du pêcheur (zone « Reperes », tous les champs dans `encryptedValues`). `CLAUDE.md` n'est PAS modifié : sa phrase « aucun coin de pêche exact ne quitte l'iPhone » est à rouvrir par A/Adem. Si Adem dit non : supprimer `SauvegardeReperes.swift`, rien d'autre ne change.
2. Offre : 3 repères gratuits, illimité en Pro, plafond technique 300. Un repère déjà posé n'est jamais caché si Pro s'arrête.
3. Aucun partage. `ZoneFloue.arrondi` (0,01°) existe pour un lot futur, sans appelant.
4. « Y aller » : Plans sans question ; Waze et Google Maps après « X saura où se trouve ce repère. Continuer ? », à chaque fois.
5. Réserve : « signalée sur cette eau dans les textes lus », « N réserves du département non placées : vérifie sur place », « aucune connue dans nos textes, vérifie sur place ». Jamais vert, jamais « hors réserve » (les règles n'ont aucun contour).
6. Icônes : parking, poste, danger, amorçage. Dessin maison en SwiftUI pur (`IconeRepereView.swift`, vue `IconeRepereView(type:taille:)` ; le nom `IconeRepere` reste l'énumération de Core) : épingle goutte (jeu B de la planche) et pictogramme blanc plein, sauf le poste de pêche, hameçon au trait (jeu C). Ni image ni SF Symbol. Couleurs : ardoise (`Palette.encreDouce`), marine, orange (`Palette.alerte`), ambre (`CouleursCarte.frequentationMoyenne`). Tailles : 32 pt sur la carte (fixe, cadre tactile de 44 pt aligné en bas, ancre `.bottom` = pointe), 44 pt sur la fiche, 24 pt en liste et dans le choix du type (ces trois suivent le texte).
7. N6 livre les vues ; le calque, l'appui long et les entrées de menu sont à brancher (accroches 1 à 8).

## Écarts à la fiche, voulus
- `ReserveConnue.sources` est un tableau (une réserve peut citer plusieurs textes), pas une source unique.
- `AvertissementReserve.surCetteEau` et `.nonPlaceesDansLeDepartement` portent aussi `lueLe` (date de lecture, exigée par le contrat « Réserve »).
- `SauvegardeReperes` a ses propres `EtatICloudReperes` et `BilanSauvegardeReperes` : ce dossier n'importe rien de `App/Compte/`. Il copie l'identifiant du conteneur et la clé Info `FishMeICloud` ; à garder identiques.
- Photos des repères en enregistrements séparés (`PhotoRepere`, un `CKAsset` chiffré chacun, envoyé une fois) : la liste d'iCloud ne télécharge jamais d'asset.
- Fichier `reperes.json` illisible : copié en `reperes.illisible.json` avant de repartir de zéro ; fichier d'une version plus récente : lecture seule, jamais écrasé.
- Pas d'appareil photo direct : photos par `PhotosPicker` (aucune permission). Caméra : à ajouter si Adem le veut.

## Branchements restants (accroches)
Voir la section « Accroches » de `docs/fiches/N6.md` (1 à 9). Ce que N6 fournit : `CalqueReperes`, `InterrupteurCalqueReperes`, `NouveauRepereView(position:)`, `FicheRepereView(repere:)`, `ListeReperesView()`, `RepereProche.plusProche`, `ReglesReperes.peutAjouter`, `SauvegardeReperes.synchroniser()` / `effacerTout()`, `ModeleReperes.partage`. Au lancement : `ContexteReperes.courant.configurer(geo:chargeur:prises:...)` et `ContexteReperes.courant.abonne = suivi.abonne`.

## À vérifier sur Mac
Compilation de tout le dossier ; `ForEach` et `Annotation` dans `CalqueReperes` (`MapContent`) ; `CLLocationUpdate.liveUpdates()` et sa demande de permission ; `encryptedValues` avec `CKAsset` et `.changedKeys` ; création du type d'enregistrement dans la console CloudKit puis déploiement en production ; isolation de la fermeture de `openURL` ; rendu des chemins de `IconeRepereView` (arcs en Bézier, hameçon lisible à 24 pt) et pointe de la goutte exactement sur la coordonnée du repère (ancre `.bottom`).
