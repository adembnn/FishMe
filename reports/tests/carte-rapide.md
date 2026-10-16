# Carte rapide au lancement

Mesure du Mac (simulateur, Debug) : 1er écran en 1,3 à 2,5 s, carte complète après 9 à 10 s, 21 s au 1er lancement. Cible : carte utilisable en moins de 2 s.

## Ce qui coûtait du temps (relu dans le code, pas mesuré)
- `App/Carte/Modele/ModeleCarte.swift` (`demarrer`, ancien): au démarrage la carte chargeait les stations de **toute la France** (`regionVisible = .france`, 11 x 13 degrés). `StationsViaCore.stations(dans:)` (`ServicesCarte.swift:~45`) parcourt toutes les stations, construit leurs espèces, trie, puis le regroupement. C'est le plus gros calcul.
- Le même calcul repartait **deux fois de plus** : quand la position arrive (`appliquer` puis `centrer` puis `charger`) et au premier `onMapCameraChange(.onEnd)` de `VueCarte.swift` (`chargerApresMouvement`). Chaque petit mouvement relisait aussi tout.
- `VueCarte.swift` `.task`: la demande de position attendait `await modele.demarrer()` (espèces puis chargement), donc la position arrivait plus tard.
- Au 1er lancement, rien n'est en cache : s'ajoutent la question de position du système et le chargement du moteur (`Chargement.preparer`, RootView, déjà hors du fil principal).
- Hub'Eau : **pas sur la carte**. Aucun appel Hub'Eau ni regroupement de stations hydro dans `App/Carte/`. Hub'Eau n'est appelé que par `App/Conditions/ConditionsDuSpot.swift:43` (fiche et conditions). Les « clusters » de la carte sont les stations OFB (`Regroupeur`). Si le Mac mesure un retard Hub'Eau, il vient des conditions, pas de la carte : à vérifier avec Instruments.

## Ce qui change
- Nouveau `App/Carte/Modele/CacheCarte.swift`: cache JSON dans Caches (`carte-derniere-vue.json`) de la dernière vue (étendue 3 degrés au plus, 400 stations au plus, centre arrondi à 0,01, ignoré après 60 jours ou si abîmé). Local à l'iPhone.
- `ModeleCarte.demarrer`: relit le cache hors du fil principal, place la caméra sur la dernière vue, affiche les points du cache, puis rafraîchit cette zone. Plus de lecture de la France au départ.
- Premier `onEnd` de la caméra (affichage initial) ignoré tant qu'il n'y a ni position ni cache.
- `chargerApresMouvement`: si la zone tient dans la zone déjà chargée (`ZoneCarte.estCouverte(parChargee:)`), on ne relit pas les stations, on refait seulement le regroupement (hors du fil principal).
- `VueCarte`: la demande de position part avant `demarrer()`.
- Inchangé: 20 stations animées au plus, aucune coordonnée exacte hors de l'iPhone, aucune fausse donnée, le calcul reste hors du fil principal (`@concurrent`).

## À mesurer sur le Mac
1. Lancement à froid sans cache (désinstaller l'app) : temps jusqu'aux tuiles et jusqu'aux premiers points, après la réponse de position.
2. Deuxième lancement : les points du cache doivent apparaître avant la position (cible moins de 2 s).
3. Dézoomer sur la France entière après le lancement : cela relit toutes les stations (non traité, Core n'est pas dans ce lot) ; noter la durée.
4. Instruments (Time Profiler) sur `stationsDans`; vérifier que `Calculs lourds` n'est plus sur le fil principal.
5. Lancer `AppTests/Carte/CarteRapideTests.swift` (non compilé ici, pas de Mac).
