# Latence : ce que le chat peut promettre
Décision débloquée : fixer ce que l'écran de chat de L24 affiche (« à la minute » ou mieux) et si les messages d'amis restent en zone partagée ; ouvre L24 une fois les cases « à mesurer » remplies.
Lu le 19/10/2026 (pages Apple citées). Mesuré le : à mesurer (20 abonnements, prototype `outils/reseau/`, sortie à coller de Sullyvan).

**État honnête : aucune latence n'est mesurée.** Ce fichier dit comment on la mesure, quoi conclure selon le résultat, et les doutes à lever.

## En bref
Image : un abonnement CloudKit est une sonnette : quand quelqu'un écrit chez le voisin, CloudKit envoie un coup de sonnette (notification silencieuse) à ton iPhone, qui va relire. Le facteur (le service de notifications d'Apple) ne promet pas l'heure d'arrivée.
Ce que la documentation d'Apple permet de dire : la notification passe par le service de notifications push d'Apple, dont la livraison n'est pas garantie immédiate ni certaine ; les apps rechargent aussi à l'ouverture ([CKQuerySubscription](https://developer.apple.com/documentation/cloudkit/ckquerysubscription)) ⚠ la page n'a pas pu être lue en entier ; énoncé de mémoire, à confirmer sur le prototype. Aucun délai garanti n'est donc promis à l'écran.

## Protocole
- 20 `CKQuerySubscription` sur `Publication`, un par valeur de `departement` (« lat-0 » à « lat-19 »), `firesOnRecordCreation`, notification silencieuse (`shouldSendContentAvailable`), champ `ecritA` demandé dans la notification.
- Écrivain : 20 enregistrements, un toutes les 8 s. Récepteur : un autre appareil du même compte iCloud (CloudKit ne notifie en principe pas l'appareil qui écrit ⚠ à confirmer).
- Trois passages : app ouverte, app en arrière-plan, app fermée de force.
- Délai = heure de réception - `ecritA`. Les deux horloges en réglage automatique (erreur de quelques dizaines de millisecondes, estimation).
- Un 4e essai, dans la même séance : écriture sur la zone partagée du lot Amis, avec un `CKDatabaseSubscription` sur la base partagée (le chemin de `MessageAmi`) ⚠ non couvert par le prototype actuel : à ajouter si `CKQuerySubscription` est refusé sur la base partagée.

## Résultats collés
| Passage | Reçus sur 20 | Délai minimal | Médiane | Délai maximal |
|---|---|---|---|---|
| App ouverte | à mesurer | à mesurer | à mesurer | à mesurer |
| Arrière-plan | à mesurer | à mesurer | à mesurer | à mesurer |
| Fermée de force | à mesurer | à mesurer | à mesurer | à mesurer |
Les 20 lignes brutes de chaque passage sont dans `outils/reseau/RESULTATS.md` ; les min, médiane et max se calculent à partir de ces lignes, jamais à la main sur des valeurs recopiées de mémoire.
- Notifications perdues : à mesurer.
- Doublons : à mesurer.
- Notification sur l'appareil écrivain : à mesurer.

## Comment lire le résultat
| Si le délai maximal, app ouverte, est... | L'écran du chat dit... | Change avec un budget |
|---|---|---|
| sous 10 s, 20 reçus sur 20 | « envoyé » et rafraîchissement toutes les 10 s en plus (fiche L24) | non |
| au-delà ou des pertes | « envoyé », tirer pour rafraîchir, rafraîchissement périodique obligatoire | non |
| des pertes en arrière-plan | pas de promesse de notification, seulement à l'ouverture | non |
| app fermée de force : rien reçu | attendu ; dire dans l'app que la notification demande que l'app n'ait pas été fermée à la main ⚠ | non |
| notification visible fiable nécessaire | notification avec texte (push visible) : demande un serveur ou une notification locale, hors périmètre CloudKit seul | oui |
La fiche L24 impose déjà : « envoyé », jamais « lu » ; permission de notifier au premier message ; un abonnement par conversation, pas par message.

## Recommandations sur ce que le chat promet
- Écrire à l'écran « envoyé » et jamais « lu » ni « en ligne » : CloudKit ne sait pas si l'autre a lu. Appui : fiche L24, piège « Promettre lu » (docs/fiches/L24.md). Change avec un budget : non.
- Un chat « à la minute » est le plus honnête tant que la mesure n'est pas faite. Appui : décision 6 du 19 oct. (CLAUDE.md). Change avec un budget : non.
- Si les mesures montrent des pertes en arrière-plan, passer à un chat « tirer pour rafraîchir + rafraîchissement toutes les 10 s app ouverte » et retirer la promesse de notification. Appui : fiche L24, ligne « Réception ». Change avec un budget : non.
- Un chat « à la seconde » exige un service temps réel (WebSocket) : un fournisseur externe, repli de la décision 2. Appui : CLAUDE.md, décision 2. Change avec un budget : oui.

## Doutes à lever sur le Mac (⚠)
1. `CKQuerySubscription` est-elle acceptée sur la base partagée ? Si non, `MessageAmi` utilise `CKDatabaseSubscription`, et la fiche L24 change.
2. Le plafond du nombre d'abonnements par utilisateur n'est pas lu : ⚠ non lu.
3. Les notifications silencieuses sont limitées par iOS (économie de batterie) : le prototype mesure ce qui arrive vraiment sur l'iPhone de test, pas un cas général.
4. Les messages d'un club (base publique) et d'amis (zone partagée) n'ont pas forcément la même latence : le rapport définitif donne les deux.
