# CGU : ce que le Mac doit faire (branche claude/cgu-03635x, non compilée)

Texte source : `docs/legal/conditions-fishme.md`. Il est copié dans l'app par `python3 outils/legal/generer_conditions.py` (écrit `App/Abonnement/TexteConditions.swift`) : ne jamais modifier le fichier Swift à la main.

1. Fusionner `claude/cgu-03635x` dans `mac/integration`, compiler (Debug simulateur).
2. Lancer `ConditionsUtilisationTests` (AppTests/Abonnement).
3. Réglages, « Conditions d'utilisation » : la page s'ouvre dans l'app (feuille, bouton OK), sans réseau, lisible en très grande taille de texte, sans barre de défilement. Capture dans `reports/ecrans/cgu/`.
4. Création du compte (fil « Compte et sauvegarde des cartes ») : poser `LigneAccordConditions(confidentialite:)` sous le bouton qui crée le compte, et appeler `SuiviConditions().accepter()` quand il est touché. Au lancement, si `SuiviConditions().doitDemander` et qu'un compte existe déjà, remontrer la ligne avant de continuer (cas d'une nouvelle version des CGU).
5. À vérifier à la compilation : `AttributedString(markdown:options:)` avec `.inlineOnlyPreservingWhitespace`, et l'interception du lien interne `fishme://conditions` par `.environment(\.openURL, OpenURLAction { ... })`.
6. Avant l'envoi à Apple : plus aucun crochet `[...]` dans les CGU (éditeur, contact, médiateur, à demander à MWM et à Adem), puis regénérer le fichier Swift. Le générateur affiche le nombre de crochets restants.
7. Le paywall garde son lien vers l'EULA d'Apple (règle 3.1.2) ; quand la version web des CGU sera publiée par MWM (après le oui d'Adem), passer son adresse dans `LiensLegaux.conditions` et dans la fiche App Store.
8. Ce que les CGU promettent et que l'app doit tenir (relecture juridique du 16 oct.) : un vrai bouton « Supprimer mon compte » dans Réglages (règle Apple 5.1.1(v), fil Compte) qui efface aussi les cartes partagées ; « Signaler » une carte ou une personne et « Bloquer » un ami dans Amis (règle Apple 1.2), avec un traitement des signalements sous 24 h à l'adresse de contact ; aucun lien vers la plateforme européenne de litiges (fermée en juillet 2025).
9. `store/conditions.md` (lot/store) est l'ancien brouillon : la source est maintenant `docs/legal/conditions-fishme.md`. La version anglaise de la fiche est à refaire depuis ce texte si MWM la demande.
