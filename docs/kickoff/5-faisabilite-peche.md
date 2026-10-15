# 5. Faisabilité : l'app de pêche en eau douce

Synthèse de `reports/faisa-donnees.md`, `faisa-tech.md`, `faisa-marche.md`, `concurrence-peche.md`. Statut : DISPO = existe et utilisable ; MAIN = à saisir ou créer nous-mêmes d'ici mercredi ; BLOQUANT = pas pour vendredi.
Contrainte : aucun code avant jeudi ; build jeudi + vendredi matin ; soumission à Apple jeudi soir.

## La carte des briques

| Brique | Statut | Source | Version vendredi | Version idéale |
|---|---|---|---|---|
| Règles (tailles, ouvertures, quotas) | MAIN | socle national (Code de l'environnement) + arrêté du département ; ~20 lignes par département | table saisie pour le département pilote, chaque règle avec sa source | tous les départements, mise à jour annuelle |
| Catégorie du cours d'eau (1re/2e) | MAIN | pas de couche nationale ; quelques départements en données ouvertes ; en Île-de-France, 2e catégorie par défaut + liste de rivières en 1re | liste du pilote | couches départementales |
| Rivières et plans d'eau autour de moi | DISPO | BD TOPAGE (Licence Ouverte) | extrait du département pilote, hors ligne | France entière |
| Parcours, réserves, no-kill | BLOQUANT | Géopêche (fermé) | absent, lien vers la fédération | partenariat avec une fédération |
| Rareté des espèces | DISPO | Hub'Eau Poissons (OFB) : appel réel réussi, 70 876 observations en Seine-et-Marne | fichier espèce × département précalculé | mis à jour chaque saison |
| Liste des espèces | DISPO | TAXREF (Licence Ouverte) | 10-12 espèces jouables | ~80 espèces |
| Images des cartes | MAIN | FishBase interdit (non commercial), Wikimedia risqué | 10-12 illustrations maison | toutes les espèces |
| Reconnaître l'espèce | DISPO, précision inconnue | IA d'Apple avec image (iOS 27), sur l'iPhone, gratuite | 3 propositions dans une liste fermée, l'utilisateur confirme | reconnaissance directe |
| Mesurer le poisson | DISPO | curseur à l'écran | saisie manuelle | LiDAR sur iPhone Pro |
| Carte Pokémon | DISPO | détourage photo Apple + mise en page + texte par l'IA d'Apple | carte personnelle, partage en image (Instagram, WhatsApp) | animations, cartes rares, saisons |
| Pokédex public | BLOQUANT pour vendredi | règle App Store 1.2 : filtre, signalement, blocage, contact | non : Pokédex personnel | public, spot jamais exact |
| Météo et conditions | DISPO | WeatherKit (500 000 appels/mois) ; vérifier que le compte MWM y donne droit | météo du jour au moment de la prise | indice de pêche, débits, température de l'eau |
| Paywall | DISPO | StoreKit + SDK Spark Flash (MWM) | Pro 14,99 €/an, essai 7 jours, prix affiché clairement | tests de prix, pack saison |

## Ce que dit le terrain
- 1,43 M de cartes de pêche en 2025 (+2,9 %), dont 26 % de jeunes (FNPF : 373 891), voir reports/chiffres-cible.md ; en 2026, cartes jeunes +10 % et cartes journée/semaine +33 %.
- Segment à tester : le street fishing urbain en Île-de-France (spots publics, matériel léger, poisson visible). C'est une hypothèse, pas un fait.
- Saison : les carnassiers (brochet, sandre, perche) sont ouverts maintenant et ferment de fin janvier à fin avril en 2e catégorie. Les poissons blancs et la carpe restent pêchables toute l'année. Lancer en octobre tombe bien.
- Concurrents sur les prix : Fishbrain 17,99 € à 89,99 €/an, Fishing Points ~19,99 €/an, Fish AI 22,99 € à 89,99 €.
- YouTubeurs FR : Bapt Fish 168 k, Korda France Carp 56,5 k, Paradise Fishing 38 k, Matys Fishing 18,4 k.
- Risques d'image : no-kill dans beaucoup de villes (relâcher), photo hors de l'eau à faire vite et mains mouillées, ne jamais dévoiler un spot (supprimer le GPS des photos).

## Tests sans code d'ici mercredi
1. Reconnaissance : photographier ou récupérer 20 vraies photos de prises et les passer dans la Recherche visuelle de l'iPhone (Visual Look Up / Visual Intelligence). C'est un bon indice de ce que fera l'IA d'Apple.
2. Entretiens : 5 pêcheurs sur les quais (Seine, Marne, canal de l'Ourcq, Saint-Denis), script dans `reports/faisa-marche.md`.
3. Règles : saisir à la main les ~20 lignes du département pilote et les relire contre l'arrêté.
4. Vérifier avec MWM : WeatherKit sur leur compte, ce que fait le SDK Spark Flash.
