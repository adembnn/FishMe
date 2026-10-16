# Position refusée au premier lancement : parcours vérifié à la lecture du code

Pas compilé (pas de Mac). Les numéros de ligne sont ceux des fichiers après `position.patch`.
Patch et test : `/tmp/claude-0/-home-user-Build-Challenge-Unaite-MWM-Apple-F/f7d3fb38-078a-5ae3-a94e-8d912f20a1dd/scratchpad/position/`
(`position.patch` pour App/, `AppTests/Carte/PositionRefuseeTests.swift` nouveau).

## Ce qui marchait déjà

1. Premier écran de carte : `VueCarte.task` appelle `demanderAuPremierEcran()`. `GestionPosition.swift:36` pose `carte.redemandeFaite` quand la question du système part : un refus à cet instant ne déclenche pas de redemande.
2. Refus : `onChange(statut)` -> `reagirAuStatut()` -> `appliquer(position: nil, refusee: true)` (ModeleCarte.swift:89) -> `afficherChoixDeZone` -> `ChoixDeZoneView` (carte, recherche de commune, tap, « Valider »). « Plus tard » ferme sans bloquer.
3. Zone validée : `choisirZone` (ModeleCarte.swift:97) centre la carte, charge les stations OFB et demande à Core `spotPropose` (station aux relevés récents, espèce ouverte). Départ `.zoneChoisie` ; le filtre d'espèces se règle sur la zone. Hors de France : repli Paris.
4. Redemande unique : `doitRedemanderUneFois()` (GestionPosition.swift:45) ne renvoie vrai qu'une fois, seulement si le statut est refusé sans que la question système ait compté ; lue seulement au premier écran de carte.
5. Session et prise sans GPS : `commencer(spot)` part du centre du spot ; `ajouterPrise` exige `coordonneeSession` ; `contextePrise` n'utilise `gps.position` que si elle existe et reste à 3 km du spot, sinon le centre du spot. Le repli `Coordonnee(0,0)` (RootView.swift:425) est inatteignable : `ajouterPrise` est la seule entrée de `.prise` et refuse sans coordonnée.
6. Règles : `core.geo.lieu(de: spot.centre)` ; relevés OFB : stations de la zone visible ; Mon club lit `moteur.spotGratuit?.departement ?? .inconnu` (liens fédération avec repli `LiensOfficiels`).
7. Pescedex, Mon club, amis, conseils (dos des cartes, carte à essayer) : aucun ne lit la position ni le spot (le lieu est optionnel). La barre d'onglets reste accessible.
8. Refus déjà connu au lancement (`sansPositionAffiche`) : écran « Ta zone » avec Pescedex et Amis ; « Choisir ma zone » ouvre la carte, qui ouvre le choix de zone.

## Ce qui cassait, corrigé (patch)

| # | Problème | Correction |
|---|----------|------------|
| 1 | La question du niveau (feuille de la carte) s'ouvrait 1 s après le lancement, sous la question du système. Un refus ouvrait alors `ChoixDeZoneView` pendant une autre feuille : SwiftUI n'en présente qu'une, le choix pouvait ne jamais apparaître ; le tunnel (feuille de la racine) entrait aussi en conflit. | `ParcoursApp.choixDeZoneOuvert` (RootView.swift:115), exigé par `questionNiveauPermise` (:309) et `proposerSuitePremierLancement` (:312). `VueCarte` le renseigne via `surChoixDeZone` (VueCarte.swift:32, 146) ; à la fermeture la suite du premier lancement reprend (RootView.swift:678). |
| 2 | `positionPassee` passait à vrai après 1 s sans attendre la réponse. | `.task(id: gps.nAPasEteDemandee)` (RootView.swift:611) : attend la réponse du système, puis 1 s (repli 30 s). |
| 3 | `questionNiveau` n'était que sur `VueCarte` : refus connu au lancement et question pas vue = écran « Ta zone » sans question, donc ni tunnel ni consentement. | Modificateur posé sur le volet carte entier (RootView.swift:646). |
| 4 | Après « Plus tard » ou sans spot proposé, aucun moyen de poser un spot : le menu exigeait un spot déjà affiché. | Menu dès que `peutChangerDeSpot`, libellé « Poser mon spot » sans spot (VueCarte.swift:~300-311). |
| 5 | Le spot proposé (`spotLocal`) n'arrivait jamais à la racine : `spotCourant` nul jusqu'à un toucher, donc tunnel sans espèces proches, conseils sans lieu, conditions non lues. | `onChange(of: modele.spotLocal)` -> `onSpotChange` (VueCarte.swift:148). |
| 6 | Zone hors de France : un changement de statut rouvrait le choix de zone. | `appliquer` ne rouvre plus pour `.horsDeFrance` ni `.zoneChoisie` (ModeleCarte.swift:90-93). |
| 7 | `GestionPosition` impossible à tester. | `init(reglages:statutInitial:)` (GestionPosition.swift:17), défaut inchangé. |

## Tests

`AppTests/Carte/PositionRefuseeTests.swift` : redemande unique, aucune après la question système, aucune si accordé ou non demandé, restreint = refusé, refus -> choix de zone, zone -> spot sans GPS, zone posée ne rouvre pas le choix, hors de France sans nouveau choix, spot posable sans spot proposé. Non exécutés (pas de Mac).

## Reste, non corrigé

- La zone choisie n'est pas gardée d'un lancement à l'autre avant la 1re session (le spot gratuit l'est après).
- « Ta zone » n'affiche pas le nom de la zone (`zone: nil`) ni de rangée conseils.
- Deux `GestionPosition` coexistent (carte et racine), même statut système, sans conséquence.
- `contextePrise` garde son repli `Coordonnee(0,0)` (inatteignable, voir 5).
