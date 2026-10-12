# Plan de construction de l'app

Tout ce qu'il faut pour construire l'app jeudi et vendredi, vérifié par `python3 verifier.py` (doit afficher « 0 trou »). Version du 12 oct., 17h.

## Les fichiers
| Fichier | Ce qu'il dit | Pour qui |
|---|---|---|
| `parcours-demo.md` | les étapes E1 à E9 que voit le pêcheur, chacune avec son test ; l'ordre de la démo | toute l'équipe, le critère commun |
| `lots.md` | qui construit quoi, dans quel dossier, avec quel test, et le calendrier heure par heure | toute l'équipe |
| `fiches/` | une page par lot, avec la consigne à coller dans Claude Code | la personne du lot |
| `architecture.md` | versions, structure du projet, contrats de `Core`, cas réel de jeudi 9 h | A, B, C |
| `donnees.md` | les fichiers embarqués, leurs sources et licences, la politique de verdict, 5 cas de test | C |
| `app-store.md` | la check-list de soumission et les refus probables, avec le lot qui les corrige | A, C, MWM |
| `avant-jeudi.md` | ce qui doit être fait avant jeudi 9 h, avec la preuve de chaque ligne | toute l'équipe |
| `message-mwm.md` | le message à envoyer à MWM aujourd'hui | Adem |
| `reports/` | les 4 recherches et les 4 évaluations, avec leurs sources | pour vérifier un chiffre |

## Ce que les évaluations ont changé
- Le premier découpage demandait environ deux fois le temps disponible avant le gel de 14 h. D'où un périmètre réduit pour la version soumise jeudi (question 1).
- La structure passe de 12 paquets Swift à un seul paquet `Core`, que l'étudiant sans Mac peut écrire et tester depuis le cloud.
- Le relecteur d'Apple n'a ni poisson ni ami : photo d'exemple dans l'app, choix « pas un poisson », partage entre amis hors de la version soumise.
- Paris n'a que des relevés OFB de 1989 à 2011 : chaque chiffre affiche son nombre de pêches et l'année du dernier relevé.

## Choix pris par défaut (dis-moi si tu veux en changer un)
- Xcode 27.0, iOS 27.0, iPhone seulement ; un paquet `Core` + un dossier par lot ; fusion par script local (`architecture.md`).
- Hors des 5 départements saisis, l'app ne dit jamais « tu peux la garder » (`donnees.md`).
- Rareté sur 10 ans ; sous 20 pêches dans le département, rareté calculée sur la région, et l'écran le dit.
- Tes 4 niveaux de rareté : commun (50 % des pêches OFB et plus), peu commun (20 à 50 %), rare (moins de 20 %), légendaire (jamais relevé dans le département). Dans le 94, ça donne 3 légendaires : les deux truites et l'ombre (`donnees.md`).
- La carte s'ouvre sur l'Île-de-France sans demander la position ; « Autour de moi » la demande.
- Essai affiché « 1 mois » : App Store Connect ne propose pas « 30 jours ».
- Les fichiers fabriqués par le script restent hors de git (ta règle) : publiés en pièce jointe d'une release privée.
- L'outil du partage entre amis (CloudKit recommandé dans `reports/amis.md`) se décide vendredi, quand E8 revient.

## Questions pour Adem
Même en bas de fourchette, tout le parcours ne tient pas avant le gel de 14 h jeudi (`reports/eval-ios.md`), et un refus d'Apple coûte une file d'attente entière. Le paywall n'a pas encore de contenu, et MWM juge sur la valeur payée.

**1.** Que met-on dans la version soumise jeudi ?
a. E1 E2 E5 E6 E7 E9 ; E3, E4 et E8 dans la version suivante, montrée vendredi depuis Xcode
b. Comme a, plus E4 (compte à rebours de fin légale) si elle tourne sur TestFlight à 12 h
c. Le minimum, E1 E2 E5 E6 sans paywall : un peu plus de chances de passer en un tour, mais plus de monétisation
Ma reco : a. Par défaut : a.

**2.** Que bloque le paywall ?
a. Les cartes à partir de la 2e ; la carte, les règles, le verdict et la 1re carte restent gratuits
b. Tout sauf la 1re carte
c. 3 cartes gratuites par mois, puis l'abonnement
Ma reco : a, parce que faire payer la règle de pêche nuit au bouche-à-oreille. Par défaut : a. Il faudra aussi un prix jeudi matin pour App Store Connect.

**3.** Qu'a-t-on le droit de préparer avant jeudi ?
a. Installations, données saisies à la main (dont un export tableur Hub'Eau des 5 départements) et textes de la fiche
b. a, plus le script de données hors de l'app, lancé mercredi sur le 94
c. b, plus un projet Xcode vide de 15 min sur chaque Mac, effacé ensuite, pour tester signature, iPhone et IA
Ma reco : c si la règle « aucun code avant jeudi » vient de l'équipe, b si elle vient des organisateurs, car l'accès MWM et la signature sont le blocage le plus probable de jeudi. Par défaut : a, le plus prudent.
