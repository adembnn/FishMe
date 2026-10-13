---
name: zero-friction-2-taps
description: Budget de friction de Bredouille (2 taps de l'ouverture à la carte révélée), permissions au moment utile, usage en extérieur. Se déclenche dès qu'un parcours, un écran d'accueil, un onboarding, une permission, un paywall ou un contrôle tactile est conçu ou modifié.
---

# Zéro friction, 2 taps (sources : `peche/06`, `07`, `09`)

## Le budget
Ouverture -> **caméra déjà active** (0 tap) -> **obturateur** (tap 1) -> 3 propositions (< 1,5 s cible [I]) -> **tap sur l'espèce** (tap 2, vaut confirmation) -> révélation automatique (2,5 s, passable d'un tap) -> carte enregistrée automatiquement.
Plafond du cahier des charges E1 : <= 4 taps et <= 15 s (médiane) [I]. **La cible est 2 ; 4 est la limite à ne pas dépasser.**
Autres parcours : bredouille 2 taps ; partager 2 taps ; retrouver une carte 2 taps ; corriger une espèce <= 3 taps.

## Règles
1. **Aucun écran avant la caméra** : pas d'onboarding bloquant, pas de compte, pas de quiz, pas de splash > 0,5 s.
2. **Permissions juste-à-temps** : caméra au tap sur l'obturateur (alternative : PhotosPicker sans permission + « Essayer avec une photo d'exemple », lien visible) ; localisation approximative seulement via une action utile (pastille « Affiner pour mon département », `LocationButton` ⚠), repli sélecteur de département ; notifications : pas au MVP (ou après la 1re sortie). Jamais « Toujours » pour la position, jamais ATT.
3. **Proposer, ne pas interroger** : un tap sur une proposition = confirmation, pas de bouton « Continuer ». Toujours « Aucune de ces espèces » / « Je ne sais pas ».
4. **Valeurs par défaut** : département mémorisé (puce modifiable), « relâché » par défaut, taille facultative, aucun champ obligatoire avant la révélation.
5. **Annuler plutôt que confirmer** : toast « Annuler » 5-6 s, jamais de pop-up de confirmation pour les actions courantes.
6. **Le moment de joie est sacré** : ni paywall, ni demande de note, ni permission pendant ou avant la révélation. Le paywall n'apparaît jamais avant la première carte ; il se ferme en 1 tap ; ce qui est obtenu reste visible.
7. **Extérieur** : cibles >= 48 pt, >= 64 pt pour obturateur/confirmer/terminer la sortie, espacement >= 12 pt ; actions dans le tiers bas, une main ; déclencheur bouton volume et Action Button (`AppIntent`) en P0 du cahier des charges ; aucun geste obligatoire sans bouton équivalent ; contraste >= 7:1 sur actions primaires.
8. **Sauvegarde et reprise** : photo écrite avant toute analyse ; kill de l'app = retour au même écran sans perte.
9. **Hors ligne** : aucun spinner bloquant, aucune erreur réseau dans le cœur.

## Compter les taps (méthode)
Compter chaque tap, swipe obligatoire et saisie ; ne pas compter le lancement de l'app ni la révélation automatique. Premier lancement : +1 tap « Autoriser » caméra, éventuellement +1 localisation.

## Mauvais / bon
- Mauvais : Ouverture -> Accueil -> « Nouvelle prise » -> obturateur -> espèce -> « Continuer » -> « Enregistrer » = 5 taps + un écran avant la caméra.
- Bon : Ouverture (caméra) -> obturateur -> espèce = 2 taps.
- Mauvais : écran « Autoriser la localisation ? » au lancement. Bon : pastille sur la carte révélée, ou choix manuel du département.
- Mauvais : paywall à la 3e carte avant la révélation. Bon : feuille fermable en 1 tap après la 15e carte révélée [I, grille à trancher].
