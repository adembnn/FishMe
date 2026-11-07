# Niveau 1 des États-Unis (50 États + DC)

Lot `us-etats`. Fichier : `etats.json` (51 entrées). Lecture : 7 nov. 2026. Niveau 1 = repères sourcés, jamais un verdict de pêche.

## Contenu par État
Code USPS, nom, agence, `url_agence`, `url_regles_eau_douce`, `url_permis`, `prix_resident` et `prix_non_resident` (montant USD annuel adulte eau douce, année, source URL, `qualite`), `timbres`, appli officielle, `format_regles` (pdf / site_interactif / donnees_ouvertes, avec URL du service), `licence_reutilisation`, `eaux_tribales_reciprocite`, `niveau_vise` (1 à 3), `verifie`, `notes`.

`qualite` d'un prix : `officiel` (page ou document d'agence lu), `editeur` (eRegulations, © éditeur : seuls les chiffres sont repris, jamais le texte), `tiers` (guide ou agrégateur, toujours à confirmer [?]).

## Méthode
1. Reprise de `reports/us/reglementation-etats.md` et `-passe2.md` (18 États déjà sourcés).
2. Pour les autres : recherche web, puis URL d'agence testées par `liens.py` (statut `ok`, `bloque_robots` quand l'hôte refuse un robot, `injoignable`, `404` : une URL devinée en 404 est mise à null).
3. `verifie = true` seulement si les deux prix sont officiels, lus sur la page de l'agence le jour même, et l'agence joignable : VA, TX, NY (7 nov. 2026).
4. `verifier.py` (hors réseau) : schéma, https, aucun prix sans source, 51 États, mots de verdict permissifs interdits, décompte. Tests : `python3 -I -m unittest` dans ce dossier.

## Définitions du bilan
Complet : deux prix sourcés et URL règles et permis présentes. Partiel : au moins une de ces pièces. Vide : aucune. « Complet » ne veut pas dire « vérifié ».

## Limites
- Sur 96 prix : 10 officiels, 16 éditeur, 70 tiers (dont 46 d'un tableau tiers daté d'avril 2024, probablement périmé, pour 23 États) ; les conflits entre sources sont dits dans `notes`.
- Les sites de l'agence répondent souvent 403 aux robots (MN, MI, FL, CA, ID, TN…) : les statuts `bloque_robots` et `injoignable` ne disent rien de la validité de l'URL.
- Les URL de règles et de permis sont en grande partie devinées à partir du site de l'agence et seulement testées pour l'existence, pas pour le contenu.
- `eaux_tribales_reciprocite` : null partout, non instruit. `licence_reutilisation` : renseignée pour 15 États, [?] ailleurs ; écrire aux agences avant tout usage commercial.
- Appli officielle : renseignée seulement pour les États déjà instruits.
- Aucun prix n'est une recommandation d'achat ; les prix changent chaque année (surtaxes, frais de vente en plus).
- Volumes de permis (USFWS 2021) : 10 États, via presse (voir passe 2).
