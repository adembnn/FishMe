# Parcours de démo (le critère commun de tous les lots)

Statut : version du 12 oct., 17h (premier jet à 14h50, corrigé après les évaluations de `reports/eval-*.md`), écrit à partir des décisions d'Adem (mémoire du projet, `kickoff/dossier-organisateurs.md`, `kickoff/reports/critique-pendant-peche.md`) et de ses réponses de 14h43 (2 Mac, collections visibles par les amis seulement, kit MWM jeudi).
Nom de l'app : à trouver. « Pescedex » est le nom de la collection dans l'app, jamais celui de l'app. « Poké » (marque de Nintendo) n'apparaît nulle part dans l'app ni sur l'App Store.

Chaque lot de jeudi-vendredi sert une ou plusieurs étapes ci-dessous. Une étape est finie quand son test passe sur l'iPhone de test, pas dans le simulateur.

## Les étapes

| # | Ce que voit le pêcheur | Ce qui le rend possible | Test qui dit « fini » |
|---|---|---|---|
| E1 | Il ouvre l'app sans créer de compte. La carte s'ouvre sur l'Île-de-France sans demander la position ; « Autour de moi » la demande. Chaque coin montre les poissons relevés à proximité par l'OFB, avec « N pêches, dernier relevé AAAA ». | carte Apple (MapKit), position, fichier des coins de pêche, fichier des espèces par zone | lancement à froid sur un quai de Paris : au moins un coin avec sa liste d'espèces en moins de 10 s |
| E2 | Il touche un coin. La fiche donne les espèces probables avec leur rareté dans le département, et la règle du jour en une phrase avec sa source (catégorie, ouvertures, tailles, quotas). | table des règles (socle national + départements saisis), table de rareté | sur 5 coins connus (75, 92, 93, 94, 77), la règle affichée correspond au texte source |
| E3 | Mission première prise : l'app propose le coin, l'heure et le montage qui donnent les meilleures chances, sans promettre de prise. | calcul sur l'abondance OFB, la saison et la météo Apple (WeatherKit) ; aucun coin testé à la main (refus d'Adem) | à une position et une date données, une proposition complète en 3 écrans au plus |
| E4 | Il démarre la session. L'écran verrouillé et la Dynamic Island affichent « fin légale dans 1 h 12 » et le nombre de prises. | Live Activity (ActivityKit, extension widget), heures de lever et de coucher calculées sur l'iPhone | iPhone verrouillé : le compte à rebours tourne et passe à « fin légale » à l'heure calculée |
| E5 | Il attrape un poisson et le photographie (ou essaie avec une photo d'exemple). L'IA d'Apple, sur l'iPhone, propose 3 espèces dans une liste fermée, plus « pas un poisson » ; sans IA, une grille des 14 espèces. Il confirme, règle la taille au curseur, et lit le verdict « tu peux la garder », « relâche-la » ou « vérifie l'arrêté », avec la source. | Foundation Models avec entrée image, liste fermée d'espèces, table des règles. L'IA propose, l'humain confirme, la table décide. | en mode avion : 3 propositions affichées, verdict juste sur 5 cas (espèce, taille, date) préparés d'avance |
| E6 | La carte se révèle : le poisson détouré, sa rareté dans le département, puis elle rejoint le Pescedex (« 4 espèces sur les 11 relevées dans le 94 » : la liste jouable compte 14 espèces, dont 11 relevées par l'OFB dans le 94, voir `reports/donnees.md`). | détourage Apple (Vision), vue SwiftUI rendue en image, stockage local (SwiftData), position floutée | la carte est toujours là après avoir tué et relancé l'app ; la photo enregistrée ne contient pas de GPS |
| E7 | Après la première carte, le paywall propose l'essai gratuit (30 jours décidés le 12 oct. à 12h40, affichés « 1 mois » car App Store Connect ne propose pas « 30 jours » ; prix à fixer par Adem). | StoreKit 2 + SDK Spark Flash de MWM (doc reçue jeudi) | achat de test réussi avec le fichier StoreKit de MWM, puis « Restaurer les achats » qui marche |
| E8 | Il invite un ami par un lien. Chacun voit le Pescedex de l'autre : les cartes, jamais les coins exacts. | partage entre amis (outil à choisir par Adem après le rapport `reports/amis.md`) | deux iPhones : une carte créée sur A apparaît sur B, sans coordonnées exactes |
| E9 | Il rentre bredouille et touche « je rentre sans poisson ». Il reçoit quand même sa carte de sortie : lieu flouté, date, phase de lune. Elle a son propre dos et aucune rareté. La météo et la durée s'ajoutent avec la session (E4, version suivante). | mêmes briques que E6, phase de lune calculée sur l'iPhone (`Core`) | le bouton « je rentre sans poisson » crée une carte bredouille, rangée à part dans le Pescedex |

En réserve si tout le reste passe : « Dis Siri, j'en ai un » (App Intent) qui ouvre l'appareil photo de E5.

## Version soumise jeudi et version suivante
Périmètre par défaut (question 1 de `README.md`) : E1, E2, E5, E6, E7, E9 dans la version soumise jeudi ; E3, E4 et E8 dans la version suivante, montrée depuis Xcode vendredi et soumise après l'approbation de la première.

## Les règles qui ne bougent pas
- L'IA ne décide jamais si un poisson peut être gardé. Le verdict vient d'une table saisie et sourcée ; l'IA ne fait que proposer l'espèce.
- Aucun coin exact ne quitte l'iPhone. Ce qui est partagé avec un ami est arrondi (département ou zone large).
- Aucune fausse donnée d'utilisateur. Un coin sans pêcheur affiche les relevés OFB, présentés comme tels.
- E5 et E6 marchent sans réseau. La carte de E1 peut demander du réseau.

## L'ordre de la démo de 2 minutes (proposition de `reports/eval-mwm.md` §4, à valider par Adem)
| Temps | Étape | Ce que le jury voit |
|---|---|---|
| 0:00 à 0:15 | E1, E2 | lancement à froid, un coin, ses espèces avec « N pêches, AAAA », la règle du jour |
| 0:15 à 0:50 | E5 | mode avion basculé devant le jury, photo d'une vraie prise, 3 propositions, curseur, verdict avec source |
| 0:50 à 1:20 | E6 | la carte se révèle : le moment fort |
| 1:20 à 1:35 | E7 | paywall juste après, achat test |
| 1:35 à 1:50 | E9 | carte bredouille, même révélation |
| 1:50 à 2:00 | E4, E8 | une phrase chacune, marquées « prochaine version » |
Plan B : une vidéo de secours par étape, car la carte de E1 demande du réseau.
