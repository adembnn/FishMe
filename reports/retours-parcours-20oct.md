# Retours du parcours dans le simulateur (20 oct. 2026)

Écrit par la session qui joue le parcours E1 à E9 avec le regard d'un pêcheur. Simulateur iPhone 17 / 17e, iOS 27.0, build Debug de `lot/compile-20oct` (commit `ea60c67f` plus corrections non commitées), iCloud coupé (`FISHME_ICLOUD=NO`), position simulée à Charenton (94). Chaque ligne dit si elle est **vue à l'écran** ou **déduite du code ou des tests**. Rien ici n'est une note ni une validation.

## Bugs (envoyés en correction)
| # | Où | Ce qui se passe | Source | État |
|---|---|---|---|---|
| B1 | Bloc de règles (L19) | 12 cas sur 13 de `CasDOrAffichageTests/aucuneAutorisation` échouaient : la ligne d'horaires de 94 et de 75 contient « secteurs autorisés », mot interdit par la décision 10. Reformulé en « secteurs prévus » (`94-hor-horaire`, `75-hor-horaire`) ; `MoteurRegles.swift` idem. Après reconstruction du paquet de règles, il restait 2 cas (cas-06 et cas-08, Rhône) : même défaut dans `69-toutes-horaire-amateur`, reformulé en « parcours prévus ». | test | corrigé, **à relancer** |
| B1bis | Lignes d'horaires de 5 autres départements | Même défaut non corrigé, cinq formulations différentes : `09-toutes-horaire-art8-horaire`, `58-toutes-horaire-demi-heure`, `62-toutes-horaire-generale`, `91-toutes-horaire-carpe_nuit`, et `85-anguille-jaune-horaire-vermee-jour` (« autorisée de jour seulement », qui est une vraie permission). | lecture des règles | **à décider** (mots à choisir) |
| B2 | Tunnel des 12 cartes (L16) | Après 4 touchers sur « Jamais / Déjà pêché », la carte avait changé mais le compteur disait encore « 1 / 12 » ; quelques secondes plus tard « 2 / 12 » sur une autre carte, dont la rareté passait de « commun » à « peu commun ». Soit le deck est reclassé quand la position arrive et des réponses se perdent, soit le simulateur est en retard. | vu à l'écran | **non confirmé** |
| B3 | Fenêtre de position | La fenêtre iOS a mis plusieurs dizaines de secondes à apparaître après « Utiliser ma position » ; le bouton ne donne aucun retour pendant l'attente. Machine très chargée au même moment (charge 15), donc cause mal établie. | vu à l'écran | non confirmé |

## Sujet de produit à trancher (Adem)
- **3 075 phrases de règles affichables contiennent « autoris… » dans 86 fichiers de départements** (par exemple « Carpe de nuit autorisée sur la Seine, lot n° 1/92 »). La décision 10 (jamais « autorisé ») ne s'applique aujourd'hui qu'aux 13 cas d'or testés. Le test n'attrape que ceux-là. Choix : (a) reformuler partout par un mot qui n'est pas une autorisation (« prévu », « possible »), (b) ne l'interdire que dans l'état de tête du bloc, (c) laisser pour les règles de carpe de nuit, qui décrivent une exception réglementaire.

## Remarques d'utilisateur
- Écran « Où pêches-tu ? » : clair, une seule action principale ; trois poissons illustrés ; deux boutons. **Vu.**
- Fenêtre de position : texte rassurant (« Ton coin exact ne quitte jamais ton iPhone »). **Vu.** À rapprocher de la décision du 19 oct. qui remet en cause cette phrase (les repères exacts partent dans l'iCloud privé chiffré).
- Écran « Tu pêches depuis… » : une seule question, trois choix en images. **Vu.**
- Tunnel : une carte à la fois, un poisson illustré, un nom, une rareté en mot. **Vu.** Le sous-titre dit « Glisse », les deux boutons ne montrent pas de geste : seulement testé aux boutons, pas au glissement.

## À faire / pas encore vu
E2 à E9 : fiche d'un coin, choix d'espèce, session, prise, carte, paywall, club, bredouille.
