# Accroches de « Mes envies » (N2) dans le Pescedex

Posées sur la branche `lot/envies-accroches`, écrites sans compilateur (a verifier sur Mac).

## Fait
- `ProfilSauvegarde.envies` (Core, `FusionSauvegarde.swift`) : décodeur tolérant, `estVide`, fusion par espèce via `ListeEnvies.fusionner`.
- `PescedexView(envies: EnviesModele? = nil)` : ligne « Mes envies · N » sous « Voir mon aquarium » (N >= 1), page `MesEnviesView`,
  `BoutonEnvieView` sous la tuile de `FicheEspeceView`, `.menuEnvie` (appui long) sur les emplacements « à trouver »,
  `envies?.charger(cartes:)` après chaque `modele.charger()` / `modele.choisir(...)`.
- `RootView.swift`, `Config/` et le projet Xcode ne sont pas touchés.

## À passer par L25
1. Créer un seul `EnviesModele(stockage: StockageEnviesFichier(url: ...), especes: <especes pechables>, externes: ...)` pour l'app
   (le garder en `@State` / dans l'environnement de `RootView`) et le passer : `PescedexView(modele: ..., envies: enviesModele)`.
   Tant que ce n'est pas passé, aucune accroche n'apparaît (aucun changement visible).
2. `EnviesExternes` : `controle` = `ServiceRegles.controle(espece:tailleCm: nil, mesure: nil, date:, lieu:, prisesDuJour: [])`,
   `conseil` via `ContexteConseils.parType` (déjà filtré par l'abonnement), `reouverture` si les règles la donnent,
   `choisirSpot` = ouvrir le choix d'un spot.
3. `ProfilLocal.lire()` : ajouter `envies: <modele.liste.envies>` (ou lire `StockageEnviesFichier.lire().envies`) dans le `ProfilSauvegarde`.
   `ProfilLocal.ecrire(_:)` : écrire `ListeEnvies(envies: profil.envies)` dans le stockage des envies.
   `memeContenu` compare déjà le profil entier (le champ `envies` est inclus).
4. Après une restauration / synchro iCloud (`SauvegardeICloud`), appeler `enviesModele.relire()` pour que la liste affichée suive le stockage.
5. Tuple de navigation : « Mes envies » s'ouvre dans la pile du Pescedex ; ouvrir la fiche depuis la liste ne marche que si l'espèce
   est dans la zone affichée du Pescedex (sinon rien ne s'ouvre).
