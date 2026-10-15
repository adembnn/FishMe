# Mots interdits dans l'app et sur sa fiche App Store

Le banc d'essai et les relecteurs cherchent ces formulations dans tout texte affiché (vues SwiftUI, données, fiche App Store). Repris de la liste de Titouan (`harnais-titouan/Tools/check/wording_forbidden.json`) et des décisions d'Adem (`CLAUDE.md`). Ce fichier cite les mots interdits pour les définir : il est exclu de la recherche.

| Formulation | Pourquoi | À la place |
|---|---|---|
| Poké, Pokémon, Pokédex | marques de Nintendo | Pescedex (le nom de la collection) |
| « reconnu à 94 % », tout pourcentage de confiance de l'IA | l'IA propose, elle ne certifie pas | « Est-ce l'une de ces espèces ? » |
| « 100 % fiable », « notre IA identifie » | promesse fausse | « proposé par l'IA, confirmé par toi » |
| « meilleur coin », « meilleures chances », « garanti » | aucune donnée ne le prouve | « Choisir un autre spot », « relevé ici par l'OFB » |
| « probabilité de capture » | la rareté est une présence dans les relevés OFB | « relevée dans N pêches sur M » |
| « tu as le droit de garder » | l'app montre la loi, elle n'accorde rien | selon la forme de verdict choisie par Adem (question du 15 oct.) |
| un chiffre OFB sans « N pêches, dernier relevé AAAA » | aucune fausse donnée | ajouter N et l'année |
| une règle de pêche sans sa source et sa date de lecture | l'arrêté fait foi | ajouter la source |
| 373 891, 1,39 million, 22,5 % | chiffres faux ou non vérifiés (mémoire du projet) | ne pas citer |
