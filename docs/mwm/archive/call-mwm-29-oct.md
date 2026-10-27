# Appel CTO de MWM, jeudi 29 octobre 2026 : acquisition de FishMe

Sources lues : decisions-produit.md (bredouille-app), CLAUDE.md, store/ (app-privacy, confidentialite-spark-flash, note-mwm-mesure, mwm-resultats, appels-mwm, etat-du-code, a-trancher, fonctions-du-build), docs/app-store.md, questions-juriste.md, concurrence/06 et FEATURES-MANQUANTES, adem-vers-equipe.md (origin/adem/coordination-capacites). Web : pages Apple sur les pages produit personnalisees (developer.apple.com/app-store/custom-product-pages), conditions du SDK MWM (mwm.ai/sdk-terms-of-service). Aucune doc publique MWM trouvee sur l'A/B test ou les analytics : tout ce qui touche aux outils MWM est une QUESTION, pas un fait.

## 0. A trancher AVANT l'appel (contradictions trouvees)
- Gratuit : decisions-produit.md (Q10, 13 oct.) dit 15 cartes gratuites puis Pro (provisoire) ; CLAUDE.md (15 oct.) dit un spot gratuit de 1 km, sessions illimitees. Q24 (5 leviers Pro) a ete ecartee par A dans store/a-trancher.md. Choisir UNE phrase avant l'appel.
- Classement d'age : Q16 vise 4+ ; app-privacy.md dit que 4+ ne tient plus avec le reseau social (contenu d'utilisateur, chat), seuil de 15 ans dans l'app, pas de Made for Kids. Ne pas dire "4+".
- Mesure Spark : consentement uniquement dans les Reglages, eteint par defaut (decision 7) => mesure MWM quasi vide. A dire a MWM (note-mwm-mesure.md), surtout pour l'objectif "attirer des jeunes".

## 1. Ordre du jour (45 min)
| Min | Bloc | Contenu |
|---|---|---|
| 0-3 | Ouverture | Qui nous sommes, objectif (sortie fin nov.), 3 demandes prioritaires annoncees |
| 3-10 | Demo 2 min + 3 ecrans | Section 3 ; 5 min de questions du CTO |
| 10-15 | Etat reel | Ce qui marche, ce qui est bloque (iCloud/Push), date de soumission visee |
| 15-27 | Acquisition (Q1-Q12) | Ce que fait MWM, ASO, Search Ads, pages produit, pre-lancement, avis, A/B paywall |
| 27-35 | Spark, vie privee, mineurs (Q13-Q18) | Declarations, jeunes, mesure |
| 35-40 | Publicite (Q19-Q20) | Ce qu'ils deconseillent, budget max |
| 40-44 | Demandes concretes | Section 4 |
| 44-45 | Resume | Qui fait quoi, d'ici quand ; relire a voix haute |

## 2. Les 20 questions (classees)
### Acquisition : ce que MWM fait pour ses apps
1. Pour vos apps qui ont decolle, quels ont ete les 3 premiers leviers d'acquisition (organique, ASO, Search Ads, creators, presse), en quelle proportion ?
2. Que pouvez-vous faire concretement pour FishMe : equipe, outils, intros, budget, mise en avant ? Et ce qui est hors de portee ?
3. Pour un loisir de niche (pecheurs, jeunes debutants), quelle cible et quel canal testeriez-vous en premier ?
### Tests et analytics
4. Quels outils MWM permettent de tester le paywall et les ecrans (A/B) : Spark Flash, Console MWM, autre ? Avec quel trafic minimal ?
5. Peut-on tester l'ordre des offres (annuel fondateur 34,99 / mensuel avec 1 semaine d'essai) et la duree d'essai sans nouvelle soumission Apple ?
6. Quels evenements recommandez-vous (fin d'onboarding, premiere carte, premiere session, paywall vu, essai demarre, conversion, annulation), et lesquels le SDK envoie deja ?
7. Votre tableau de bord abonnements/revenus vient-il de Spark ou des donnees d'Apple ? (Si Spark : vide pour FishMe.)
8. Attribution respectueuse de la vie privee : que recommandez-vous sans suivi (AdAttributionKit / AdServices, pages produit par canal, codes d'offre, App Store Connect) ?
### ASO, Search Ads, pre-lancement, avis
9. Apple Search Ads : budget de depart realiste, mots a viser, cout par installation attendu dans la peche en France ? Deja releves par MWM (14 oct.) : "fishing" (demande 4,2, difficulte 6,3), "spot", "fish" ; "peche", especes, "riviere" non releves.
10. Pages produit personnalisees (jusqu'a 70 selon Apple, utilisables avec les pre-commandes) : lesquelles creer (debutant, carpiste, collection, regles) ?
11. Pre-lancement : pre-commande, page web, liste d'attente ? Qu'est-ce qui a marche chez vous, et quand ouvrir ?
12. Notes et avis : quand demander la note (apres la premiere carte, jamais au paywall), comment repondre aux avis negatifs ? Les concurrents perdent surtout sur le paywall (73 % des avis negatifs de 5 apps) : comment l'eviter ?
### Produit : Spark Flash
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
15. Un consentement donne dans les Reglages seulement vous convient-il ? Sinon, quel ecran de choix non intrusif donne assez de mesure ?
### Vie privee et mineurs
16. Les conditions du SDK interdisent les apps visant les moins de 13 ans. Pour une app tout public, seuil 15 ans, sans Made for Kids, quelle position de MWM ? Que font-ils pour les apps visant les jeunes ?
17. Un juriste MWM peut-il relire CGU et politique (15 questions dans questions-juriste.md : age, signalements, conservation, "chiffre") ? Sous quel delai ?
18. Pour attirer des jeunes sans cibler : quelles pratiques MWM pour rester conforme (pas de profilage, pas de pub ciblee) ?
### Publicite
19. Que deconseillez-vous (reseaux payants, influenceurs, installs incitees) pour une app a abonnement et pseudonyme seul ?
20. Budget d'acquisition maximum avant d'avoir des donnees de retention et de conversion ? A quel seuil augmenter ou couper ?

## 3. Montrer, et ne pas promettre
### 3 ecrans
1. Carte : rivieres, "N peches, dernier releve AAAA" (OFB), regles avec source citee d'un toucher.
2. Prise : photo, 3 especes en images, "Autre", jamais de pourcentage ; carte revelee (recto/verso), reflet seulement sur rare et legendaire.
3. Paywall : fermeture visible, prix lisibles, essai 1 semaine sur le mensuel, "Restaurer" (argument : le paywall est le premier motif d'echec des concurrents).
### Demo de 2 minutes (a repeter ; video de secours prete)
0:00 ouverture sur la camera, sans compte - 0:20 photo, 3 propositions, confirmation - 0:50 carte revelee, rarete du departement - 1:15 regles et source - 1:40 paywall qui se ferme. Ne montrer que ce qui a ete vu a l'ecran sur iPhone.
### Chiffres vrais (seulement ceux-la)
- Build Challenge gagne (19 oct.) ; 3 etudiants ; sortie visee fin novembre 2026 (visee, pas garantie).
- Offre : annuel 34,99 (tarif fondateur jusqu'au 31/12/2026, puis 49,99) ; mensuel avec 1 semaine d'essai ; 6 produits dans le kit, 2 montres au paywall. Prix en euros a relire dans App Store Connect.
- Donnees : 32 departements + national charges dans lot/donnees (15 oct.) : relire dans le build final avant de citer un nombre. Regles lues par IA, pas relues par une personne : ne jamais dire "relues".
- Technique (adem-vers-equipe.md, 20 oct.) : integration compilee en Debug sur simulateur iPhone 17, en local, branche non poussee ; Core : 522 tests dont 1 echec connu ; app : 613 tests dont au moins 12 en echec. Reverifier juste avant l'appel.
- Aucun chiffre d'utilisateurs, de telechargements, de retention ou de conversion : il n'y en a pas. Les 73 % et prix concurrents viennent d'une etude d'avis, pas d'une mesure FishMe.
### Ne jamais promettre
- Jamais "termine" ni "pret" : l'app n'est pas compilee de bout en bout ; aucune case de fonctions-du-build.md cochee a l'ecran au dernier etat lu.
- iCloud, Push et conteneur CloudKit bloques cote compte Apple (droits insuffisants dans l'equipe MWM) : fil, chat, clubs, reperes et sauvegarde ne marchent pas sur iPhone reel. C'est une demande a MWM, pas un detail.
- Pas de date ferme, pas d'acceptation Apple garantie (refus R1 a R9 anticipes), pas de "toute la France", pas de nombre d'especes reconnues tant que le modele n'est pas livre (aucun .mlmodel le 15 oct.), pas de verdict legal ("tu peux la garder"), pas "aucun suivi" sans nuance tant que le consentement Spark n'est pas vu dans le build, pas "4+".

## 4. Demandes concretes
1. Acces : Console MWM, outils d'A/B test et analytics ; relier App Store Connect (non relie au 15 oct.) ; confirmer Paid Apps Agreement, statut DSA, delai de grace de facturation.
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
3. Un test A/B de paywall (offre et essai) prevu dans les 2 semaines suivant la sortie.
4. Relecture accelerée Apple demandee par MWM, avec l'evenement dans les notes.
5. Budget de depart Search Ads (montant, seuils d'arret) ou credit.
6. Introductions presse et Apple (mise en avant App Store), createurs de peche.
7. Relecture juridique rapide de politique et CGU ; liste ecrite des donnees Spark (confidentialite-spark-flash.md, section 4).
8. Point hebdomadaire jusqu'a J+30 apres sortie.

## 5. Compte rendu a remplir pendant l'appel
Date/heure : ____  MWM : ____  Equipe : ____
| Sujet | Reponse de MWM | Decision | Qui / quand |
|---|---|---|---|
| Q1-3 Ce que fait MWM | | | |
| Q4-5 A/B paywall (outil, trafic min.) | | | |
| Q6-8 Evenements, attribution | | | |
| Q9 Budget Search Ads | | | |
| Q10-11 Pages produit, pre-lancement | | | |
| Q12 Notes et avis | | | |
| Q13-14 Donnees Spark, App Privacy | | | |
| Q15 Consentement Reglages seulement | | | |
| Q16-18 Mineurs, jeunes | | | |
| Q19-20 Pub deconseillee, budget max | | | |
| Acces (Console, ASC, iCloud) | | | |
| Intros presse / Apple | | | |
| Relecture accelerée | | | |
| Prochain point | | | |
Engagements MWM (mot pour mot) : ____
Engagements de l'equipe : ____
A verifier apres l'appel : ____  Confirmation ecrite envoyee a MWM : [ ]
