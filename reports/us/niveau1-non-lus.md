# Niveau 1 : 13 États dont les prix ne sont pas confirmés (7 nov. 2026)

38 États sur 51 sont `verifie: true` dans `Packages/Core/Sources/Core/Resources/regles-us/etats.json`. Les 13 ci-dessous restent `verifie: false` : leur site officiel répond 403 ou anti-bot, ou ne dit rien d'exploitable. Rien n'a été contourné (aucun proxy, aucun faux navigateur). Détail de chaque lecture : `outils/us/etats/verifs/<USPS>.json`.

Conséquence dans l'app : ces États gardent leur lien d'agence et le verdict « donnée absente » ; le prix affiché est celui du fichier, marqué non vérifié. Aucun verdict de pêche n'en dépend.

| État | Pourquoi non confirmé |
|---|---|
| AZ Arizona | Prix 37/55 d'un tableau d'avril 2024, concordant avec un résumé 2026, sans page officielle lue |
| CA California | Page CDFW injoignable depuis l'outil ; prix en conflit entre tiers |
| ID Idaho | Seul un résumé de moteur de recherche d'une copie de la page officielle |
| KS Kansas | Site officiel en 403, aucune page ou PDF lisible ; 27,50/52,50 (tiers) contredit |
| KY Kentucky | Résident 23 $ ou 24,31 $, non-résident 55 $ ou 58,14 $ selon les tiers ; l'agence dit « inchangé » sans chiffre |
| MA Massachusetts | Barème échelonné 2021-2026 vu dans le titre d'un PDF officiel, à relire depuis un navigateur |
| MI Michigan | Valeurs 26/76 reprises du fichier ; deux dates de début de saison contradictoires (1er avril / 1er mars) ; dnr/Michigan.gov en 403 |
| NE Nebraska | Seul un résumé de moteur de recherche de la page de prix |
| TN Tennessee | tn.gov en 403 ; hausse proposée pour l'exercice FY28 non tranchée |
| RI Rhode Island | Timbres non chiffrables en un seul montant ; année de licence à confirmer |
| NC North Carolina | Prix concordant avec eRegulations (tiers) seulement ; page ncwildlife.gov devinée en 404 |
| MD Maryland | dnr.maryland.gov en 403 sur toutes les pages ; non-résident non lu |
| MT Montana | Licence de conservation préalable, achat en ligne depuis le 1er mars 2026 (tiers) ; prix à ne pas prendre sans la page officielle |

À faire (humain) : ouvrir ces 13 pages dans un navigateur et corriger le prix ou le dire. Même ordre de grandeur pour tout l'écran « prix » : c'est un repère, jamais un verdict.
