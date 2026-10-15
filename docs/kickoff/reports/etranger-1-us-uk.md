# Étranger 1 : apps US/UK/CA/AU sans équivalent FR correct

Décision débloquée : quelle app anglo-saxonne copier-adapter pour la France en une semaine (équipe de 3, non-devs, IA).
Date de recherche : 12/10/2026. Méthode : articles (TechCrunch, Apple, Appfigures, fintech.ca, SmartCompany), pages App Store US et FR (lues une par une), estimations screensdesign.
Écarté d'office : santé, finance, matériel, musique/photo (MWM). Locket (photo) est gardé dans le tableau pour mémoire seulement.

Limites honnêtes :
- web_fetch Parallel a répondu « Too Many Requests » en boucle ; j'ai lu les fiches `apps.apple.com/fr/...` avec WebFetch à la place. Les notes FR et langues viennent de ces fiches.
- Les « concurrents FR » ne viennent pas d'une recherche : ce sont des noms connus (marqués °), à confirmer avant de s'engager.
- Les chiffres « screensdesign » sont des estimations tierces, pas des mesures.
- Aucun appel LLM payant, aucune clé utilisée.

## Tableau (trié par trou FR décroissant, puis faisabilité)

| App | Pays | Ce qu'elle fait | Chiffres + URL | Équivalent FR ? | Trou FR (1-5) |
|---|---|---|---|---|---|
| Beli | US | Classe ses restaurants par duels (« mieux que… ? »), listes, classement entre amis. « Letterboxd du déjeuner » | 2,5 M+ téléchargements, 18,9 k notes 4,8 (mwm.ai) ; 75 M d'avis loggés en 2024, 80 % des utilisateurs < 35 ans ; abo Supper Club 74,99 $/an. https://www.ypulse.com/newsfeed/2025/09/23/beli-is-gen-z-and-millennial-foodies-new-yelp/ ; https://mwm.ai/apps/beli/1478375386 | Fiche FR : anglais seul, 45 notes (4,8). Pas de traduction. Local°: TheFork, Michelin, Google Maps (pas de ranking social). https://apps.apple.com/fr/app/id1478375386 | 5 |
| Ground News | CA/US | Agrège les articles d'un même sujet et montre le biais politique de chaque source | ~150 k installs, ~400 k$/mois (estimation screensdesign), note 4,7, abo 39,99 $/an. https://screensdesign.com/apps/ground-news/ | Fiche FR : anglais seul, 266 notes (4,6), catégorie Actualités. Local° : aucun équivalent connu. Risque : agrégation d'articles = scraping/droits. https://apps.apple.com/fr/app/id1324203419 | 5 (faisabilité faible) |
| Partiful | US | Invitations de soirée entre amis, RSVP, photos partagées | ~500 k MAU T1 2025, +400 % sur un an (Sensor Tower via CNBC) ; 20 M$ levés (a16z) ; gratuit pour l'instant. https://www.nbcnewyork.com/news/business/money-report/meet-partiful-the-gen-z-party-planning-staple-thats-taking-on-apple/6231135/?amp=1 | Fiche FR : anglais seul, 440 notes (4,9). Concurrent direct : Apple Invites (app par défaut, iCloud+). Local° : Evite, Doodle. | 4 (rejet probable : app par défaut) |
| Goblin Tools | AU | Boîte à outils IA pour neuro-atypiques : découper une tâche, reformuler un ton, estimer le temps | Pro 3,99 €/mois ou 39,99 €/an ; 5,0 sur 30 notes en FR ; pas de chiffres de téléchargement publics. https://apps.apple.com/fr/app/id6449003064 | Fiche FR : marche en français selon les avis, pas localisée, 30 notes. Local° : Tiimo (traduit, voir plus bas). | 4 |
| Focus Friend (Hank Green) | US | Minuteur de concentration façon pomodoro : le téléphone reste posé, un personnage (Bean) gagne des haricots pour décorer sa chambre | ~35 k installs, ~150 k$/mois (estimation screensdesign), 4,8. Pro 3,99 €/mois, 22,99 €/an, 44,99 € à vie. Prix Apple « Cultural Impact » 2025. https://screensdesign.com/apps/focus-friend-by-hank-green/ ; https://www.apple.com/newsroom/2025/12/apple-unveils-the-winners-of-the-2025-app-store-awards | Fiche FR : anglais seul, 163 notes (4,6). Local° : Forest (mondial, traduit). Opal bloque les apps mais n'est pas ludique. | 4 |
| Collectr | CA | Scanne et valorise ses cartes à collectionner (Pokémon, Magic…), suivi de portefeuille | 4 M+ utilisateurs, bootstrappé, ARR « de 5 chiffres à 8 chiffres en 6 mois » (fintech.ca, 22/05/2025). https://www.fintech.ca/2025/05/22/collectr-worlds-fastest-growing-collectibles-app/ | Fiche FR : anglais listé (mention d'une langue FR dans les notes de version), 482 notes (4,7), base de cartes sans cartes FR selon avis. Local° : Cardmarket (marché, pas un carnet). https://apps.apple.com/fr/app/id1603892248 | 4 (données de prix lourdes) |
| Unforgetful (Marco Arment) | US | Rappels insistants et snooze croissant par-dessus Apple Rappels | 19,99 $/an, lancé août 2026, aucun chiffre publié. https://techcrunch.com/2026/08/14/unforgetful-is-a-new-reminders-app-for-people-who-cant-stop-hitting-snooze/ | Fiche FR non vérifiée (page inaccessible). Local° : rien de connu. Tient sur une app par défaut (Rappels). | 3 (non vérifié) |
| Letterboxd | NZ/UK/US | Journal de films, avis, listes, réseau de cinéphiles | 17 M d'utilisateurs fin 2024 (de 1,8 M en 4 ans), ~100 M d'avis en 2024. https://www.forbesargentina.com/negocios/cinefilos-ataque-red-social-tiene-mas-17-millones-usuarios-n69531 | Fiche FR : anglais seul, 3,5 k notes (4,7). Local° : SensCritique, Allociné. | 3 |
| StoryGraph | UK | Suivi de lectures, recommandations par humeur et rythme | Abo Plus 4,99 $/mois, 49,99 $/an ; 3,4 k notes US (4,5) ; Apple « Cultural Impact » 2025. https://apppricinglab.com/app/apple/1570489264 ; https://www.apple.com/newsroom/2025/12/apple-unveils-the-winners-of-the-2025-app-store-awards | Fiche FR : anglais seul, 90 notes (4,6). Local° : Babelio (fort). https://apps.apple.com/fr/app/id1570489264 | 3 |
| Tiimo | DK (iPhone App of the Year 2025) | Planning visuel avec IA pour TDAH/neuro-atypiques | 14 k notes (4,6), 23 langues dont français, Pro 54 $/an. https://apps.apple.com/app/tiimo/id1480220328 | Disponible en FR. Pas un trou, mais prouve la demande. | 2 |
| Opal | US | Bloque les apps distrayantes via l'API Temps d'écran | ~200 k installs, ~600 k$/mois (estimation screensdesign), 4,7 ; 200 M d'heures « sauvées » (mai 2025). https://screensdesign.com/apps/opal-screen-time-control/ | Disponible en FR (« Opal : Temps d'écran et Focus »), 14 k notes (4,7), plan annuel 99,99 €. https://apps.apple.com/fr/app/opal-screen-time-control/id1497465230 | 2 |
| Hallow | US | Prière et méditation catholiques, programmes de Carême | ~40 M$ de revenu 2025 (net), ~1,5 M de téléchargements au Carême 2025, pic de 263 k téléchargements le Mercredi des Cendres 2026. https://appfigures.com/resources/insights/hallow-lent-surge-prayer-app-revenue | Disponible en FR (Rosaire & Bible Catholique), 1,3 k notes (4,8). Local° : Hozana. Sensible côté image (religion). https://apps.apple.com/fr/app/id1405323394 | 2 |
| ReciMe | AU | Enregistre des recettes depuis les réseaux sociaux, planning de repas | 20 k à 400 k utilisateurs en 2023, 60 k$ d'ARR à l'époque, TikTok 100 k abonnés. https://www.smartcompany.com.au/startupsmart/news/recime-sizzles-jumping-20000-400000-users-in-2023/ | Disponible en FR (« Recettes & Idées Repas »), 2,1 k notes (4,6). Local° : Marmiton. | 1 |
| Locket Widget | US | Photos d'amis dans un widget (hors périmètre : photo, MWM) | 91 M d'installs à vie (Appfigures), 2 M d'utilisateurs actifs, 100 k+ abonnés, rentable, 15 personnes (TechCrunch, nov. 2025). https://techcrunch.com/2025/11/03/lockets-social-app-is-picking-up-steam-with-gen-alpha/ | Disponible en FR, 30 k notes (4,7). https://apps.apple.com/fr/app/id1600525061 | 1 |

## Pourquoi elles marchent (lecture transversale)

- Un seul geste, un classement ou un score qui se partage : Beli (duels), Letterboxd, StoryGraph. Le contenu est créé par l'utilisateur, l'app ne fait que le mettre en forme.
- Une mécanique de jeu sur un besoin sérieux : Focus Friend (concentration), Opal (temps d'écran), Goblin Tools (charge mentale).
- Le prix : abonnements de 4 à 5 $/mois ou 40 à 75 $/an, essai d'une semaine. Focus Friend ajoute un achat à vie (44,99 €).
- Les apps anglophones sont souvent juste non traduites en France : 5 des 9 premières lignes ont une fiche FR en anglais seul avec moins de 500 notes.

## Les 5 meilleurs transferts vers la France

1. **Beli-like, restaurants (trou 5).** Phrase : « classer ses restaurants par duels, pour les 20-30 ans qui choisissent où sortir ce soir ». Fiche FR : 45 notes seulement, anglais seul. Monétisation prouvée (Supper Club 74,99 $/an). Risque : contenu utilisateur à modérer et base de lieux (MapKit couvre les lieux). Backend léger (CloudKit possible).
2. **Goblin Tools-like en IA sur l'appareil (trou 4).** « Découper une tâche en étapes pour les gens qui procrastinent, pour le moment où tout paraît trop gros ». Tombe pile sur Foundation Models (aucun serveur). Risque : l'IA doit être le cœur, et Tiimo existe déjà en FR avec 14 k notes.
3. **Focus Friend-like (trou 4).** « Poser son téléphone pour faire pousser une pièce, pour les étudiants en révision ». 150 k$/mois estimés avec 35 k installs seulement. Pas de backend. Prudence : ne pas dépendre de l'API Temps d'écran (droit Apple à obtenir) ; un minuteur + Live Activities suffit. Forest existe en FR.
4. **Collectr-like, cartes Pokémon FR (trou 4).** « Scanner et valoriser sa collection, pour les 15-30 ans qui collectionnent ». Les cartes françaises manquent chez Collectr. Risque : données de prix (source à valider) et droits.
5. **Unforgetful-like, rappels insistants (trou 3, non vérifié).** « Rappels qui insistent tant que ce n'est pas fait, pour ceux qui snoozent ». Zéro backend, App Intents. Risque : repose sur une app par défaut (Rappels) et aucune traction publiée, donc à tester avant.

Réserves : Letterboxd/StoryGraph (Babelio et SensCritique sont des concurrents locaux réels), Partiful (Apple Invites est fourni avec l'iPhone), Ground News (scraping, rejet App Store probable).

## Ce que je ne sais pas

- Les concurrents FR marqués ° viennent de ma mémoire, pas d'une fiche lue.
- Pas de chiffres de revenu pour Beli, Letterboxd, StoryGraph, Goblin Tools.
- Fiche FR non lue : Unforgetful. Tiimo : fiche générale lue, pas la page /fr.
