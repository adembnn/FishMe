# Résultats des appels MWM (15 oct. 2026, vers 18h30, heure de Paris)

Fil « Fiche App Store avec MWM », suite de `appels-mwm.md`. Seuls des appels en lecture ont été faits ; rien n'a été écrit chez MWM ni dans App Store Connect.

## 1. Branchement
- `get_store_text_rules` (fr-FR, version 2026-10, vérifiée le 13 oct.) : nom 2 à 30 car., sous-titre 30, mots-clés 100 **caractères** virgules comprises, promo 170, description et nouveautés 4000. `fr-FR` est le bon code. Nouveautés non exigées pour une première version.
- `get_store_connections` : **App Store Connect non relié** côté MWM (`connected: false`). À faire par Adem dans la console MWM : https://console.mwm.ai/mcp.
- `list_analytics_apps` : aucune app visible pour ce compte. `get_legal_questionnaire` sur `ai.mwm.build.challenge.team.01` répond « app access denied » : l'app n'est pas encore liée à l'organisation. Tant que ce n'est pas fait, confidentialité, publication, envoi de la fiche et soumission sont bloqués.
- `get_assistant_settings` n'existe pas dans le serveur MWM branché (outil absent de la liste) : impossible de vérifier `store_send` et `store_publish` ; chaque écriture reste soumise au oui d'Adem.

## 2. Mots-clés (boutique française, iPhone, chiffres du 14 oct.)
Marché : 28 apps de pêche iOS (recherches « pêche en eau douce » et « fishing » classées par téléchargements en France), dont FishMan, Fishing Points, FishFriender, Fishbrain, Decathlon Fishing, Génération Pêche.
Seuls 32 mots sont suivis pour ce marché, presque tous des marques (interdites). Ceux qui servent :

| Mot | Demande /10 | Difficulté | Qui est classé |
|---|---|---|---|
| fishing | 4,2 | 6,3 | 9 apps sur 28 (Fishing Points 2e) |
| fish | 4,6 | 7,0 | 9 apps ; « FishMe » est un seul mot, donc pas indexé comme « fish » [?] |
| spot | 4,2 | 7,4 | FishMan 12e |
| lake | 3,9 | 5,0 | anglais, non retenu |
| marée(s) | 4,7 à 4,9 | 5,4 | mer, hors sujet (eau douce) |

« pêche », les espèces, « rivière », « étang », « carnet », « réglementation » : **pas relevés** (aucune des 28 apps n'y est dans les 100 premiers selon MWM). Gardés par jugement.
Nouvelle liste : `pêche,fishing,brochet,carpe,truite,sandre,perche,rivière,étang,lac,spot,carnet,réglementation` (93 car.). « taille » sort ; il tient encore pile à 100 car. si Adem le veut.

## 3. Contrôle des textes
`review_store_text` (et `lint_store_text`) sur nom, sous-titre, mots-clés, promo, nouveautés, description avec la liste des concurrents : **aucune remarque sur aucun champ**. Le serveur renvoie alors une erreur de format (« findings must be array ») au lieu d'une liste vide ; un essai avec un nom piégé (« Android », « le meilleur ») ramène bien des remarques sur ce champ, donc l'absence de remarque est réelle. À signaler à MWM.

## Reste à faire
- Adem : relier App Store Connect dans la console MWM (lien ci-dessus), puis l'app `ai.mwm.build.challenge.team.01` doit apparaître dans l'organisation.
- Ensuite, dans l'ordre de `appels-mwm.md` : questionnaire de confidentialité, brouillon, publication (oui d'Adem), captures (après les écrans de B), icône (après le logo), envoi de la fiche et soumission (oui d'Adem à chaque fois).

## Icône (15 oct. 18h56)
**En attente (18h58)** : Adem a refusé cette version retouchée ; le fil « Logo de FishMe » réexporte le F1 exact qu'il a validé. Ne pas poser le fichier ci-dessous.

Ancien fichier du fil « Logo de FishMe » (logo F1) : `/mnt/project-files/maquettes/logo/final/fishme-icone-1024.png`, vérifié 1024 × 1024 px, RGB sans transparence, conforme à Apple. Aucune génération MWM. A le pose dans `App/Assets.xcassets/` (dossier de A, pas de S1).
