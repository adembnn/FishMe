# Prototype R2 : mesurer CloudKit avant de construire le réseau social

Pour : Sullyvan, sur son Mac. Durée : environ 2 h (estimation), dont l'attente des envois. Coût : 0 € (CloudKit gratuit dans la limite du quota, rien à payer).
Le code n'a jamais été compilé (l'auteur est sur PC Windows). Si Xcode refuse une ligne, ne la répare pas en silence : copie l'erreur dans `RESULTATS.md`. Les lignes douteuses portent « ⚠ à vérifier ».
**Aucun chiffre de ce dossier n'est une mesure tant que `RESULTATS.md` n'est pas rempli avec les sorties collées.**

## Ce que ça mesure (la fiche R2)
1. Quota : le tableau de bord CloudKit avant, puis après 1 000 photos de 300 Ko et 100 vidéos de 15 s en 720p.
2. La taille réelle d'une vidéo de 15 s après `AVAssetExportSession` 720p.
3. La lecture d'un fil de 50 publications (temps, octets).
4. La latence de 20 abonnements `CKQuerySubscription` sur la base publique (écriture -> notification).
4c. La latence sur une **zone partagée** avec `CKRecordZoneSubscription` et `CKDatabaseSubscription` : le chemin réel du chat de club et d'ami (L24).

## Règle d'or : un conteneur d'essai, pas celui de la vraie app
Utilise un identifiant à toi (ou un conteneur `iCloud.<ton-id>.r2essai`). Si A te donne le conteneur de FishMe, n'écris que dans l'environnement **Development**. Jamais Production.

## 1. Créer le projet (10 min)
1. Xcode, File > New > Project > **Multiplatform > App** (ou iOS > App). Nom : `ReseauR2`. Interface SwiftUI, langage Swift.
2. Build Settings : cherche « Swift Language Version » et mets **Swift 5** (le code n'est pas écrit pour le mode strict de Swift 6).
3. Supprime `ContentView.swift` et le fichier `...App.swift` créés par Xcode. Glisse les 4 fichiers de `Prototype/` (`FishMeReseauApp.swift`, `Mesures.swift`, `MesuresLatence.swift`, `Mesures4c.swift`) dans le projet (« Copy items if needed » coché).
4. Signing & Capabilities, pour chaque plateforme que tu utilises : équipe de développement ; `+ Capability` > **iCloud** > coche **CloudKit** > bouton `+` pour créer un conteneur `iCloud.<ton-id>.r2essai` ; `+ Capability` > **Push Notifications** ; sur iOS, `+ Capability` > **Background Modes** > coche **Remote notifications**.
5. macOS seulement : dans « App Sandbox », coche **Outgoing Connections (Client)** et **User Selected File : Read Only**.
6. Lance sur ton Mac (« My Mac ») : une fenêtre avec des boutons. Appuie sur « 0. Vérifier iCloud » : il faut lire « disponible ». Sinon : Réglages Système > ton nom > iCloud, connecte-toi.

## 2. Préparer le tableau de bord (10 min, une seule fois)
1. Ouvre https://icloud.developer.apple.com/dashboard, choisis ton conteneur, environnement **Development**.
2. Les types `Publication` et `Like` n'existent qu'après la première écriture : lance d'abord « 1. Écrire » avec 10 enregistrements (change `nombre: Int = 1000` en `10` le temps du test, puis remets 1000).
3. Schema > Indexes, pour **Publication** : `departement` Queryable ; `creeLe` Queryable et Sortable ; `marqueur` Queryable ; `recordName` Queryable. Pour **Like** : `publication` Queryable ; `marqueur` Queryable ; `recordName` Queryable. Sauvegarde.
4. Une erreur « Field … is not marked queryable » veut dire qu'un index manque : ajoute-le, relance. Note chaque cas dans `RESULTATS.md`.

## 3. Relever le compteur AVANT (5 min)
Dans le tableau de bord, ouvre les pages de **Telemetry / Usage** de ton conteneur (⚠ les noms exacts des onglets varient selon la version du tableau de bord ; cherche stockage des assets, stockage de la base de données, requêtes). Fais une capture d'écran par page et note les valeurs dans `RESULTATS.md`, section « Avant », avec la date et l'heure.

## 4. Lancer les mesures (dans cet ordre)
1. **Bouton 1** : 1 000 photos de 300 Ko (fichiers d'octets aléatoires). Laisse l'app ouverte et le Mac éveillé. Colle les lignes « PHOTOS FINI ».
2. **Bouton 2a** : choisis une vidéo de l'iPhone d'au moins 15 s (AirDrop vers le Mac). **Bouton 2b** : exporte en 720p et écrit 100 vidéos. Colle « VIDÉO EXPORTÉE » (taille réelle) et « VIDÉOS FINI ».
   Contrôle de vie privée : retrouve le fichier exporté dans le dossier temporaire de l'app et lance `exiftool` dessus (`brew install exiftool`) ; colle la sortie. Aucune ligne de lieu ne doit apparaître.
3. **Boutons 3a et 3b** : le fil de 50 sans, puis avec les médias. Lance chacun 3 fois et colle les 3 lignes (le premier appel est souvent plus lent).
4. **Latence** (il faut 2 appareils, par exemple le Mac et un iPhone, même compte iCloud ; les horloges en réglage automatique) :
   - Sur l'appareil récepteur, **bouton 4a** (crée les 20 abonnements). Mets l'app au premier plan.
   - Sur l'appareil écrivain, **bouton 4b** : 20 écritures, une toutes les 8 s. Le récepteur écrit des lignes « REÇU (…) délai = X s » ; l'écrivain « ÉCRIT #k ».
   - Premier passage : app **ouverte** sur le récepteur. Deuxième passage : app **en arrière-plan** (bouton Accueil, sans la fermer de force). Troisième passage : app **fermée de force** (balayage vers le haut) : Apple ne réveille normalement pas une app fermée de force avec une notification silencieuse ⚠ ; si rien n'arrive, note-le : c'est le résultat.
   - Colle les 20 lignes de chaque passage telles quelles. Pas de moyenne calculée à la main : le rapport le fera.
5. **Test 4c** (zone partagée ; il faut **deux comptes iCloud** différents, un par appareil, c'est le cas réel d'une paire d'amis) :
   - Appareil 1, compte A (propriétaire) : **4c-A**. Le journal affiche un lien ; envoie-le à l'appareil 2 (AirDrop, Messages).
   - Appareil 2, compte B (invité) : colle le lien dans le champ, **4c-B**. Lis les deux lignes « ACCEPTÉ » ou « REFUSÉ » : c'est déjà un résultat (quel abonnement la base partagée accepte). Mets l'app au premier plan.
   - Appareil 1 : **4c-C1** (20 messages, un toutes les 8 s). Appareil 2 écrit des lignes « REÇU 4c … délai = X s ». Mêmes trois passages que pour le test 4 : ouverte, arrière-plan, fermée de force.
   - Puis dans l'autre sens : **4c-C2** sur l'appareil 2, lecture sur l'appareil 1.
   - Le délai part de l'appel à `save` et inclut l'envoi ; la ligne « ÉCRIT » donne aussi la durée du `save`. Colle tout dans `RESULTATS.md`, section 4c.
6. Attends 15 à 30 min (les compteurs du tableau de bord ont du retard), puis relève le compteur **APRÈS** : mêmes pages, mêmes captures.
7. **Bouton 5** (nettoyage, borné à 50 passages par type ; il supprime aussi la zone 4c côté propriétaire) quand tout est collé. Ou, dans le tableau de bord, « Reset Development Environment ».

## 5. Renvoyer
Remplis `RESULTATS.md` (modèle fourni) et donne-le à Titouan : il recopie les sorties, datées, dans `docs/reports/reseau/quota.md` et `latence.md`. Rien n'est calculé ni arrondi avant cela.

## Ce que le prototype ne couvre pas
La modération et les droits (« Security Roles ») ne se mesurent pas ici. Les messages en zone partagée (ami, club) sont couverts par le test 4c, avec un `CKShare` de zone ouvert par lien (simplification : le chat réel nomme ses participants). Il écrit toujours avec le même compte : le quota « par utilisateur actif » d'Apple dépend du nombre d'utilisateurs actifs, que ce prototype ne simule pas (voir `quota.md`).
