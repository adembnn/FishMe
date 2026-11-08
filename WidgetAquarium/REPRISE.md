# Widget « Mon aquarium » : reprise (8 nov. soir)

**État** : `lot/widget-fluide` à jour avec `fishme-tout`. Un seul poisson (`limitePoissons` = 1), piste `seul6`, 1 passage de 10 s par boucle, 4 images de queue distinctes (pic 25 Mo, 1 image 22, 8 images 27). Widget vide = texte seul, plus de gardon d'accueil. Skin publié par l'app (`publierAquarium`) et rechargé ; les 7 décors sont dessinés en code, aucun fond manquant. 81 tests logiques verts.

**Ce qui manque** : (1) preuve visuelle du battement de queue : aucune vidéo, voir ci-dessous ; (2) captures de 2 skins app/widget ; (3) `FondsDesSkinsEssais.swift` jamais compilé ni exécuté ; (4) `RenduWidgetsTests` jamais lancé ; (5) bouton « Mon widget » (`ChoixPoissonWidgetView`) non branché dans `RootView`.

**Pourquoi figé au simulateur (8 nov., 17 h)** : captures identiques sur 7 s, widget bien affiché avec un poisson, alors qu'une session précédente avait 53/53 images différentes. Cause non établie : machine à charge 25 à 100+, simulateur réinitialisé (SpringBoard planté), ou défaut réel du nouveau code (4 images de queue). À trancher sur un simulateur au calme ou un iPhone en Release : si figé aussi, remettre `return 1` dans `NageSeule.imagesQueueRetenues` et comparer. Piège : un `piste-widget.txt` oublié dans l'App Group fausse le test.
