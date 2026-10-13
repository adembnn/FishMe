---
name: anti-sur-ingenierie
description: Réflexes à éviter pour tenir 2 jours — abstractions inutiles, fonctionnalités hors MVP, premier jet trop complexe. Se déclenche avant d'écrire du code, en revue, ou face à un choix d'architecture ou de périmètre.
---

# Anti-sur-ingénierie (Bredouille, 2 jours)

Le temps est le vrai budget : environ 20 h par personne sur l'événement [F, descriptif]. Chaque abstraction coûte une heure qu'on n'a pas.

## À éviter
- Une abstraction (protocole, factory, générique) pour un seul cas. Exception : les protocoles du contrat gelé de `PecheCore` (`SpeciesIdentifier`, `CollectionStoring`…), qui existent pour permettre à Titouan de travailler sans Mac.
- Une dépendance externe : **aucune dépendance tierce dans l'app** [F, `peche/05`]. 20 lignes de code valent mieux qu'un paquet.
- Du social, des comptes, un backend, CloudKit, des notifications push : **feuille de route, pas MVP**.
- Un système de design maison, un moteur d'animation, des shaders avant que la chaîne capture -> carte -> collection marche de bout en bout.
- Gérer des erreurs impossibles. Mais **garder** les replis exigés par le produit : « Aucune de ces espèces », sans réseau, permission refusée, Reduce Motion.
- Refactorer hors périmètre (règle 16).

## Question avant de complexifier
Ce besoin s'est-il posé **concrètement** (test, revue, bug) ? Sinon : le noter dans `plan/IDEES.md`, ne pas le coder.

## Bon / mauvais
- Mauvais : `RarityStrategyFactory` + 3 stratégies pour des seuils qui tiennent dans un tableau.
- Bon : une fonction `tier(forFrequency:thresholds:)` qui lit un tableau de seuils en config, avec 5 tests.
- Mauvais : ajouter un onglet « Communauté » la veille de la soumission.
- Bon : couper les albums Pro et garder bredouille + révélation (voir agent `coupeur`).
