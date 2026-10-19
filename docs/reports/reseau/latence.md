# Latence : ce que le chat peut promettre
Décision débloquée : fixer ce que l'écran de chat de L24 affiche (« à la minute » ou mieux) et quel type d'abonnement la base partagée accepte ; ouvre L24 une fois les cases « à mesurer » remplies. Le chat de club et le chat d'ami sont tous deux en zone partagée (décision du 19 oct.) : c'est le test 4c qui les concerne.
Lu le 19/10/2026 (pages Apple citées). Mesuré le : à mesurer (test 4 sur la base publique et test 4c sur zone partagée, prototype `outils/reseau/`, sorties à coller de Sullyvan).

**État honnête : aucune latence n'est mesurée.** Ce fichier dit comment on la mesure, quoi conclure selon le résultat, et les doutes à lever.

## En bref
Image : un abonnement CloudKit est une sonnette : quand quelqu'un écrit chez le voisin, CloudKit envoie un coup de sonnette (notification silencieuse) à ton iPhone, qui va relire. Le facteur (le service de notifications d'Apple) ne promet pas l'heure d'arrivée.
Ce que la documentation d'Apple permet de dire : la notification passe par le service de notifications push d'Apple, dont la livraison n'est pas garantie immédiate ni certaine ; les apps rechargent aussi à l'ouverture ([CKQuerySubscription](https://developer.apple.com/documentation/cloudkit/ckquerysubscription)) ⚠ la page n'a pas pu être lue en entier ; énoncé de mémoire, à confirmer sur le prototype. Aucun délai garanti n'est donc promis à l'écran.

## Protocole
Deux chemins, deux tests. Seul le second est celui du chat.
- **Test 4 (base publique)** : 20 `CKQuerySubscription` sur `Publication`, un par valeur de `departement` (« lat-0 » à « lat-19 »), `firesOnRecordCreation`, notification silencieuse (`shouldSendContentAvailable`), champ `ecritA` demandé dans la notification. Chemin du fil et des notifications de publication, pas du chat.
- **Test 4c (zone partagée, chemin réel du chat de club et d'ami)** : deux comptes iCloud, deux appareils. Le propriétaire crée une zone dans sa base privée, la partage par `CKShare`, et s'abonne par `CKRecordZoneSubscription`. L'invité accepte le lien, puis pose sur la base partagée **les deux** abonnements, `CKRecordZoneSubscription` (choix de L24) et `CKDatabaseSubscription` (choix de la première version de R2) : le journal dit lequel est accepté ou refusé. 20 messages, un toutes les 8 s, dans chaque sens. À la notification, l'app lit les changements de la zone (`recordZoneChanges`) et note le délai.
- Écrivain : 20 enregistrements, un toutes les 8 s. Récepteur : un autre appareil (CloudKit ne notifie en principe pas l'appareil qui écrit ⚠ à confirmer).
- Trois passages pour chaque test : app ouverte, app en arrière-plan, app fermée de force.
- Délai = heure de réception - `ecritA`. `ecritA` est pris **juste avant l'appel à `save`** : le délai inclut donc l'envoi. La ligne « ÉCRIT » du journal donne l'heure de retour de `save` et sa durée ; pour un délai « depuis le retour du save », soustraire cette durée. Dans le test 4c, l'heure de réception est prise avant la lecture des changements. Les deux horloges en réglage automatique (erreur de quelques dizaines de millisecondes, estimation).

## Résultats collés
| Passage | Reçus sur 20 | Délai minimal | Médiane | Délai maximal |
|---|---|---|---|---|
| App ouverte | à mesurer | à mesurer | à mesurer | à mesurer |
| Arrière-plan | à mesurer | à mesurer | à mesurer | à mesurer |
| Fermée de force | à mesurer | à mesurer | à mesurer | à mesurer |
Test 4c, zone partagée :
| Passage | Abonnement | Reçus sur 20 | Délai minimal | Médiane | Délai maximal |
|---|---|---|---|---|---|
| Ouverte | `CKRecordZoneSubscription` / `CKDatabaseSubscription` | à mesurer | à mesurer | à mesurer | à mesurer |
| Arrière-plan | idem | à mesurer | à mesurer | à mesurer | à mesurer |
| Fermée de force | idem | à mesurer | à mesurer | à mesurer | à mesurer |
- Abonnement accepté sur la base partagée (`CKRecordZoneSubscription`, `CKDatabaseSubscription`) : à mesurer.
Les 20 lignes brutes de chaque passage sont dans `outils/reseau/RESULTATS.md` ; les min, médiane et max se calculent à partir de ces lignes, jamais à la main sur des valeurs recopiées de mémoire.
- Notifications perdues : à mesurer.
- Doublons : à mesurer.
- Notification sur l'appareil écrivain : à mesurer.

## Comment lire le résultat
| Si le délai maximal, app ouverte, est... | L'écran du chat dit... | Change avec un budget |
|---|---|---|
| sous 10 s, 20 reçus sur 20 (test 4c) | « envoyé » et rafraîchissement toutes les 10 s en plus (fiche L24) | non |
| au-delà ou des pertes | « envoyé », tirer pour rafraîchir, rafraîchissement périodique obligatoire | non |
| des pertes en arrière-plan | pas de promesse de notification, seulement à l'ouverture | non |
| app fermée de force : rien reçu | attendu ; dire dans l'app que la notification demande que l'app n'ait pas été fermée à la main ⚠ | non |
| notification visible fiable nécessaire | notification avec texte (push visible) : demande un serveur ou une notification locale, hors périmètre CloudKit seul | oui |
La fiche L24 impose déjà : « envoyé », jamais « lu » ; permission de notifier au premier message ; un abonnement par conversation, pas par message.

## Conseils sur ce que le chat promet
- Écrire à l'écran « envoyé » et jamais « lu » ni « en ligne » : CloudKit ne sait pas si l'autre a lu. Appui : fiche L24, piège « Promettre lu » (docs/fiches/L24.md). Change avec un budget : non.
- Un chat « à la minute » est le plus honnête tant que la mesure n'est pas faite. Appui : décision 6 du 19 oct. (CLAUDE.md). Change avec un budget : non.
- Si les mesures montrent des pertes en arrière-plan, passer à un chat « tirer pour rafraîchir + rafraîchissement toutes les 10 s app ouverte » et retirer la promesse de notification. Appui : fiche L24, ligne « Réception ». Change avec un budget : non.
- Un chat « à la seconde » exige un service temps réel (WebSocket) : un fournisseur externe, repli de la décision 2. Appui : CLAUDE.md, décision 2. Change avec un budget : oui.

## Doutes à lever sur le Mac (⚠)
1. Quel abonnement la base partagée accepte-t-elle : `CKRecordZoneSubscription` (code de L24), `CKDatabaseSubscription` (R2, sans type d'enregistrement), les deux ? `CKQuerySubscription` n'est pas le chemin du chat. Test 4c ; selon le résultat, L24 change d'abonnement pour l'invité (le propriétaire garde l'abonnement de zone sur sa zone privée).
2. Le plafond du nombre d'abonnements par utilisateur n'est pas lu : ⚠ non lu.
3. Les notifications silencieuses sont limitées par iOS (économie de batterie) : le prototype mesure ce qui arrive vraiment sur l'iPhone de test, pas un cas général.
4. Les messages d'un club et d'une paire d'amis sont tous deux en zone partagée : même chemin, une latence attendue comparable, mais le propriétaire et l'invité ne reçoivent pas par le même abonnement ; le rapport donne les deux sens (4c-C1 et 4c-C2).
