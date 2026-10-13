---
name: donnees-ofb-rarete
description: Méthode de calcul, biais et formulation de la rareté issue des relevés OFB (Hub'Eau Poisson), catalogue d'espèces, statuts. Se déclenche dès qu'on écrit ou modifie le pipeline Python, un JSON de rareté ou d'espèces, le moteur de rareté de PecheCore, ou un texte qui parle de rareté.
---

# Données OFB et rareté (sources : `peche/01`, `02` §2.3, `03` §2.5, `04` §1.6)

## Source [F]
API Hub'Eau Poisson (`/api/v1/etat_piscicole/`), pêches électriques scientifiques OFB (ASPE). Filtre `code_departement` vérifié. Pagination `size` <= 20 000 et profondeur <= 20 000 par requête : découper par année. CSV en vrac data.gouv.fr (~246 Mo) plus fiables que l'API lente [I, non testés]. Jeu de données sous Licence Ouverte 2.0 [F] ; licence de l'API non explicite [I] : attribution dans l'écran « Sources ».

## Méthode [I, décisions à figer]
- Unité : l'**opération de pêche** (`build_rarete.py`, fréquence = ops où l'espèce est présente / ops du département depuis 2010) ou la **station** (`peche/04`). **Choisir une seule unité et la nommer dans le libellé** : le libellé impose « stations » ; si le calcul est par opérations, le dire ou convertir. Décision à prendre avant gel des contrats.
- 5 classes. Seuils de départ **divergents entre rapports** (30/12/4/1 % ; 50/25/10/3 % ; 30/10/3/1 %) : ce sont des paramètres dans un fichier de config, à recalibrer sur la distribution réelle (cible ~35/25/20/12/8 % des espèces d'un département).
- Fiabilité faible : moins de 10 stations (ou moins de 30 opérations selon la version) -> avertissement « fiabilité faible » et repli sur le bassin. Petit département : risque de saturation en « commune ».
- Espèces de plan d'eau (carpe, sandre, black-bass, silure, brème…) : plafonnées à « commune » / « peu commune », mention « mal couvert par les relevés ». Exemple mesuré en Isère : truite 40 %, brochet 11 %, carpe 3 %, sandre 2 % [F].
- Exotiques (silure, poisson-chat, perche-soleil…) : carte « Exotique », sans rareté ni points ni bonus. Protégées / à statut (anguille, saumon, esturgeon…) : « À observer et relâcher », pas de rareté à chasser, jamais proposées dans « Préparer ». Les statuts sont des inférences à valider sur Légifrance [I].
- Catalogue : 55 espèces avec codes Hub'Eau/SANDRE vérifiés (esturgeon, omble chevalier : codes introuvables) [F]. Jamais de bonus de rareté pour une envahissante.

## Formulation
- Seul libellé autorisé : « Présent sur X % des stations scientifiques de l'OFB du/de [territoire] » + mention permanente « Rareté d'après les relevés scientifiques de l'OFB. Ce n'est pas une mesure de la pêche. »
- Jamais : probabilité de capture, chance de prise, poisson rare en général.
- Afficher la date des données et le nombre de stations/opérations quand fiabilité faible.

## Contrôles qu'un script doit faire
Bornes 0 <= fréquence <= 1 ; stations_présentes <= stations_total ; classes cohérentes avec les seuils ; chaque espèce a code, nom, statut ; départements pilotes présents (95 pour la démo) ; taille totale < 6 Mo [I, G6] ; aucune sortie `NaN`. L'agent `auditeur-donnees` juge le reste (biais, sources).

## Bon / mauvais
- Mauvais : `"label": "Rare : 3 % de chances"`. Bon : `"label": "Présent sur 3 % des stations scientifiques de l'OFB du Loiret"`.
- Mauvais : sandre « légendaire » en Isère. Bon : plafonné + « mal couvert par les relevés ».
