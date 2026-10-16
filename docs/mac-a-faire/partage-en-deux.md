# Partage de la compilation en deux (16 oct., 9h30)

Quand le partage est arrivé, le Mac A avait déjà fusionné **les deux moitiés** dans `mac/integration`, et l'ensemble compile (`** TEST BUILD SUCCEEDED **`, simulateur iPhone 18 Pro, iOS 27). Il n'y a donc rien à compiler en double.

## Lot A (Mac A) : fusionné sur mac/integration
Widget `lot/widget-aquarium` 16c0ebd, `lot/design-systeme` bea70da, `claude/animations-sons-213bkk` 9b6be93.

## Lot B : déjà fusionné par le Mac A
CGU `claude/cgu-03635x` 0d2e4d2, compte `claude/compte-sauvegarde-mv4tgb` 7a14269, retours (`claude/navigation-retour-7s97rl`, plus les branches de `navigation-retour.md` : carte a4473c8, ou-chercher 7a14522, collection fb83510, amis 3389db7, prise d95a4cd, abonnement ed3b987, premier-pas 1dcf91f). `racine-retour.patch` n'est pas appliqué : il attend l'accord d'Adem.

Conflits résolus en gardant les deux côtés : révélation de la carte (fond nuit et croix), lecture de la prise (bouchon animé et retour), réglages (croix et « Mon compte »). Les `LISEZMOI.md` de `App/Mouvement` et `App/Style` sont exclus du bundle : sinon, deux fichiers du même nom se copient au même endroit et le build échoue.

## Ce qui reste à vérifier (une seule personne suffit)
Compiler :
```
xcodebuild -project BuildChallenge.xcodeproj -scheme BuildChallenge -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build-for-testing
```
Ensuite, dans le simulateur, vérifier les points « À vérifier » de `navigation-retour.md`, `cgu.md`, `compte-sauvegarde.md` et `L15-widget-aquarium.md`. Pour l'aperçu du widget, lancer l'app avec `-FishMeApercuWidget YES`.
