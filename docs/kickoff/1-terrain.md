# 1. Fiche terrain — Build Challenge Apple

Sources détaillées : `reports/terrain-1-apple.md`, `terrain-2-cas.md`, `terrain-3-jury.md`, `terrain-4-communautes.md` (une URL par affirmation). Synthèse du 12 oct. 2026.

## La douleur, chiffrée
Le vrai obstacle n'est pas de builder, c'est de gagner de l'argent : seules **4,6 % des apps à abonnement atteignent 10 k$/mois en 2 ans** (RevenueCat 2026, 115 000 apps). Ce qui sépare les gagnantes : paywall tôt après la valeur (conversion d'essai à J35 : **10,7 % en paywall dur contre 2,1 % en freemium**), et une raison de revenir (rétention J30 médiane : 3,9 %, guide MWM).

## Les 5 enjeux
1. **Promesse en une phrase** « [quoi] pour [qui], pour [quand] » (slide MWM), compréhensible sans démo.
2. **Premier moment utile en secondes** : 55 % des annulations d'essai de 3 jours se font le jour 0 (RevenueCat).
3. **Raison de revenir** : usage quotidien ou hebdomadaire, pas saisonnier (HabitKit très saisonnier ; logement étudiant = pic d'été).
4. **Offre** : médianes 34,80 $/an, 10 $/mois, 5,99 $/sem. Fatigue des abonnements forte : pass ponctuel ou achat unique acceptés quand l'usage est rare (avis Splitwise/Tricount).
5. **IA au cœur, pas en décor** : Cal AI (photo → calories) fait ~30 M$ ARR parce que l'IA est le produit.

## Ce que l'existant couvre déjà (à ne pas refaire)
- Natif iOS 26/27 : résumés, réécriture, traduction en direct, Visual Intelligence (nutrition, cartes de visite, étiquettes), recherche perso Siri. Tout chatbot ou résumeur sera écrasé.
- Créneaux de MWM (organisateur) : musique/DJ, instruments, coloriage, nettoyage photo, créateurs d'apps.
- Marchés encombrés : captures d'écran à ranger (Stash, Sorti), reçus/garanties (Warranty Pad), suivi d'abonnements, flashcards (Quizlet…), habit trackers.

## Les 3 réponses réelles qui ont le mieux marché
1. **Opal** : a saisi une API Apple neuve (Screen Time, 2022) avant les autres → ~10 M$ ARR, 11 salariés.
2. **Cal AI** : un geste (photo) → un résultat chiffré, IA indispensable, paywall dur → ~30 M$ ARR.
3. **Habit Pixel / HabitKit** : niche étroite, design soigné, prix par pays et localisation → de 28 $ à 1 k$ MRR (Habit Pixel), ~600 k$/an (HabitKit).
Côté Apple : les ADA 2024-26 (grug, Tide Guide, CapWords, Watch Duty, Gentler Streak) sont des **outils étroits, très soignés, d'usage quotidien** ; aucun ne se vend comme « app IA ».

## Leviers techniques disponibles
- Foundation Models on-device (FR inclus, 4096 tokens, sortie typée @Generable, tool calling) ; entrée image annoncée à la WWDC26.
- **Private Cloud Compute gratuit sous 2 M de téléchargements** → coût IA nul, marge intacte.
- App Intents 2026 (Siri agit sur l'écran, entités indexées dans Spotlight), Live Activities, widgets.
- Kit MWM : compte App Store Connect, SDK Spark Flash (analytics + achats), StoreKit de test, iPhone de test.
- Limite : Siri AI est en anglais d'abord, liste d'attente en UE, iPhone 15 Pro minimum → prévoir un repli.

## Les 10 questions qu'un expert poserait
1. Qui paie, combien, et pourquoi cette semaine plutôt que jamais ?
2. Que fait l'utilisateur dans les 30 premières secondes ?
3. Pourquoi rouvrir l'app demain ?
4. Qu'est-ce qu'Apple fera nativement dans 12 mois ?
5. Si on retire l'IA, que reste-t-il ?
6. Comment trouvez-vous vos 100 premiers utilisateurs sans payer de pub ?
7. Qu'est-ce qui se partage (capture, carte, lien) et fait venir d'autres utilisateurs ?
8. Que se passe-t-il sur un iPhone sans Apple Intelligence ?
9. Quel risque de rejet App Store (santé, finance, scraping, contenu utilisateur) ?
10. Que maintiendrez-vous après vendredi, et avec quel temps ?

## Faux bons sujets
- Alertes de RDV en préfecture : paiement prouvé (2 €/alerte) mais repose sur du scraping d'un site d'État → rejet probable.
- Agrégateur budget/banque : réglementé, lourd.
- Rappels de médicaments : santé, risque de review.
- Tout ce qui ressemble à « assistant », « résumé » ou « coach IA » : déjà natif ou interdit par la carte de rejet.
- Projets à pic saisonnier unique (logement, candidatures) : pas de raison de revenir.

## Inconnu à lever au kick-off
Aucun jury, grille ni prix n'est publié pour cette 2e édition (luma.com/cmdf-bc2). Build les 15-16 oct. chez MWM (Boulogne). Demander aux organisateurs comment les apps seront jugées.
