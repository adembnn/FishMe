# Reprise du Mac A (pause du 16 oct., 7h30)

État : `mac/integration` compile (Debug simulateur et Release iPhone). Carte rapide (5e32b1c) fusionnée et compilée, pas encore testée.
Tests au moment de la pause : cœur 231 verts ; app 196 sur 197 (adresse du club, attendue d'Adem) ; abonnement 5 sur 6.

À faire, dans l'ordre :
1. **Carte rapide 5e32b1c** : lancer `CarteRapideTests`, puis mesurer trois cas dans le simulateur (lancement à froid sans cache, 2e lancement avec cache — cible : carte avec des points en moins de 2 s —, dézoom jusqu'à la France). Mesure précédente : 1er écran en 1 à 2,5 s, carte remplie en 9 à 21 s.
2. **Widget aquarium sur l'écran d'accueil** (89d3caf, puis la couche fixe annoncée par le fil widgets) : `AquariumDepuisJSONTests.renduAnimeMontreLePoisson` rend 0 pixel opaque (même avec `Date() - 60`). Reposer le widget (la réinstallation l'enlève), lancer avec `-FishMeForcerPro YES`, 2 captures à 0,5 s d'écart, vidéo de 10 s dans `reports/ecrans/L15/widget-aquarium-pro.mp4`.
3. **StoreKit, délai de grâce 910f93c** : fusionner, lancer `AchatsStoreKitTests` seule ; si rouge, vérifier « Billing Grace Period » dans `TestConfig.storekit`.
4. **lot/aquarium 193cf87** : fusionner, compiler, lancer « Voir mon aquarium » une fois, capture (pas encore validé par Adem).
5. **Curseur de taille** : glisser depuis la poignée pendant au moins 0,5 s ; s'il ne bouge pas, le signaler au fil Finir (curseur maison).

Pièges : simulateur tué au lancement (chien de garde de 30 s) quand la charge du Mac dépasse ~150 ; lancer les tests seulement quand la charge est basse. La suite StoreKit se lance seule (le lanceur reste bloqué après elle).
