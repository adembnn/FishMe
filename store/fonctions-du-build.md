# Fonctions promises par la fiche, à cocher sur le build (porte 3)

La fiche, les notes et les captures ne promettent que ce qui est coché ici, vu sur l'iPhone dans le build TestFlight de la porte 3 (L0 + 4 h). Liste de départ : E1 à E9 de `docs/parcours-demo.md` et les décisions d'Adem du 15 oct. après-midi (`CLAUDE.md`), plus, depuis le 16 oct., Amis, le widget « Mon aquarium » et l'écran verrouillé (une seule soumission, décision d'Adem ; code lu sur `mac/integration`, lignes citées dans `fiche-fishme.md`, « Qui prouve quoi »). Rien n'est coupé d'avance (Adem, 15 oct. 14h42) ; une ligne non cochée à la porte 3 sort de `fiche-fishme.md`, de `notes-relecteur-en.md` et des captures. Qui coche : A ou B, à l'écran ; Adem valide la liste.

| Vu | Fonction | Étape, lot | Phrase de la fiche qui en dépend |
|---|---|---|---|
| [ ] | Carte autour du pêcheur, espèces en images, « N pêches, dernier relevé AAAA » | E1, L2 | LA CARTE, 1re ligne |
| [ ] | Position refusée : choix du département ou de la commune, sans blocage | E1, L2 | notes, étape 1 |
| [ ] | Question du niveau, qu'on peut passer | E1, L13 | notes, étape 1 |
| [ ] | Cartes à glisser au premier lancement, cartes « déclarées » à part | `CLAUDE.md` 16h, L13 | LE PESCEDEX, 4e ligne ; notes, étape 1 |
| [ ] | Vigilance orage et crue en bandeau, gratuite | E1, L12 | LA CARTE, 5e ligne ; GRATUIT |
| [ ] | Fiche d'un coin : rareté, conditions du moment, jauge de la rivière | E2, L2, L12 | LA CARTE, 2e ligne |
| [ ] | Règles du jour, source et citation d'un toucher | E2, L2, D1 | LA CARTE, 3e ligne |
| [ ] | Départements couverts, lus par `departementsCouverts()` : ____ | E2, D1, D3 | `[COUVERTURE]` ; notes, LEGAL NOTICE |
| [ ] | Session : chrono, fin légale, prises, carte « à essayer » | E4, L5, D4 | LA SESSION, 1re ligne |
| [ ] | Photo : 3 espèces en images, « Autre », « Pas un poisson », sans pourcentage | E5, L3, R1 | LA SESSION, 2e ligne |
| [ ] | Bouton de photo d'exemple | E5, L3 | notes, étape 4 |
| [ ] | Nombre d'espèces du modèle livré : ____ (ou grille seule) | R1 | aucune phrase tant que N n'est pas lu |
| [ ] | Toise lue, taille confirmée, poids « estimé » | E5, L3 | LA SESSION, 3e ligne |
| [ ] | Carte révélée : recto, dos avec photo et conditions | E6, L4 | LE PESCEDEX, 1re ligne |
| [ ] | Reflet sur rare et légendaire seulement | L4 | LE PESCEDEX, 2e ligne |
| [ ] | Toutes les espèces en images, compteur par zone | E6, L4 | LE PESCEDEX, 3e ligne |
| [ ] | Carte de sortie quand on rentre bredouille | E9, L4, L5 | LE PESCEDEX, 5e ligne |
| [ ] | Partage d'une image sans coin exact | E8, L9 | LE PESCEDEX, 6e ligne |
| [ ] | Paywall : fin de 1re session qui se ferme, 2e spot qui bloque, « 7 jours » qui l'ouvre | E7, L6 | GRATUIT, FISHME PRO ; notes, étape 5 |
| [ ] | Météo du jour et niveau de l'eau sur son spot, avec Apple Weather | E2, L12 | GRATUIT ; « Météo : Apple Weather » |
| [ ] | Pro : 7 jours, courbe de 48 h, « Préviens-moi », tous les conseils, « Tes conditions » | E2, E6, E7, L12, D4 | FISHME PRO, une fonction par fonction |
| [ ] | Consentement avant Spark Flash, refus = SDK éteint | L6 | notes, EXTERNAL SERVICES |
| [ ] | Amis : « Mes amis » dans Mon club, invitation par le partage Apple (`ShareLink`), l'ami voit la collection en lecture seule, « Inviter en retour » | L8, `RootView.swift:619`, `AmisView.swift:133` | AMIS, 1re ligne |
| [ ] | Amis : lieu d'une carte limité au département, image sans GPS, rien en public | L8, `ConstructeurCartes.swift:20-26` | AMIS, 2e ligne |
| [ ] | Amis : supprimer ses cartes partagées, signaler une carte | L8, `AmisView.swift:204`, `PescedexAmiView.swift:107` | AMIS, 2e ligne |
| [ ] | Amis : marche par iCloud, message clair si iCloud est absent, aucun compte FishMe | L8, `AmisView.swift:86` | AMIS, 3e ligne ; RESPECTUEUX |
| [ ] | Écran verrouillé et Dynamic Island pendant une session : compte à rebours jusqu'à la fin légale, nombre de prises, sans nom de coin | L10, `SessionLiveActivity.swift:61` | ÉCRAN VERROUILLÉ ET WIDGET, 1re ligne |
| [ ] | Widget « Mon aquarium » : petit sur l'écran d'accueil (gratuit), état vide sans faux poisson | L15, `AquariumWidget.swift:36` | ÉCRAN VERROUILLÉ ET WIDGET, 2e ligne ; GRATUIT |
| [ ] | Widget « Mon aquarium » moyen, grand, très grand : verrouillé (flou et pastille Pro) sans abonnement, ouvre le paywall | L15, `VuesAquariumWidget.swift:301-308`, `RootView.swift:244` | FISHME PRO, dernière ligne |

Hors de la version soumise (jamais dans la fiche) : coins publics, tronçons, téléchargement des règles, aquarium dans l'app (bouton « Voir mon aquarium » absent, `RootView.swift:239`), widget « Ma carte » (sur `lot/widget-aquarium`, pas dans `mac/integration`), collections visibles en public.

Si une ligne Amis, écran verrouillé ou widget n'est pas cochée à la porte 3, on retire la section correspondante de la description (AMIS, ÉCRAN VERROUILLÉ ET WIDGET), la ligne « Gratuit » ou « Pro » qui la cite, la phrase des Nouveautés et la phrase du texte promo.

Points à décider par Adem : le paywall (`TextesPaywall.gratuit` / `.pro`) ne cite ni Amis ni les widgets ; la description dit Amis gratuit, petit widget gratuit, grands widgets Pro, parce que c'est ce que fait le code.
