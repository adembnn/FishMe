# Consignes communes : audit des trous de l'App Store France

Contexte : hackathon, une équipe de 3 étudiants doit publier une app iPhone monétisée en une semaine. Critère d'Adem : choisir une niche où le terrain est vide ou où les apps existantes sont très mal faites. Ta mission n'est PAS de proposer des idées d'app, seulement de mesurer les trous.

Ne jamais appeler d'outil mcp__hearthbot__. Ne lis pas les autres fichiers du dossier kickoff.

Méthode, pour chaque niche :
1. Trouve les 3 à 5 apps iPhone en tête pour cette niche en France (recherche web, par ex. « site:apps.apple.com/fr <mot-clé> », ou classements).
2. Lis leur fiche App Store France avec l'outil mcp__Parallel_Search__web_fetch (plusieurs URL par appel, objective : « note, nombre de notes, date de dernière version, prix et achats intégrés, avis négatifs récents »). Note pour chaque app : note moyenne, nombre de notes, date de la dernière version, modèle de prix.
3. Relève les 2-3 plaintes qui reviennent (pub, bugs, design daté, abonnement abusif, pas en français, fonction clé manquante, abandonnée).
4. Note la niche :
   - Demande (1-5) : volume de notes cumulé des apps leaders (1 = < 500, 3 = ~10 k, 5 = > 100 k) et signe qu'on paie.
   - Faiblesse (1-5) : 5 = notes basses (< 4,0), apps non mises à jour depuis > 12 mois, plaintes lourdes, ou aucune app correcte ; 1 = leader excellent et récent.
   - Score trou = Demande × Faiblesse.
   - Drapeau rouge éventuel : santé/finance réglementée, scraping, matériel, contenu utilisateur à modérer, territoire de MWM (musique, photo).

Budget : environ 2 appels par niche, pas plus. Si une fiche ne se lit pas, note [bloqué] et passe.

Format de sortie (Markdown, 200 lignes max) : un tableau, une ligne par niche :
| Niche | Apps leaders (note, nb notes, dernière MAJ) avec URL | Plaintes | Demande | Faiblesse | Score | Drapeau |
Puis les 3 meilleurs trous de ton lot en 3 lignes chacun : pourquoi c'est un trou, preuve, risque.
