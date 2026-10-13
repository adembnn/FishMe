# Protocole GO / NO-GO de l'identification (jeu test40)

Sources : `peche/01 §3.6`, `peche/04 §4.1` et lot L9/L10. Seuils [I], a valider par l'equipe.

## Jeu de test
- `eval_manifest.csv` : 40 photos = 10 especes x 4. Dossier d'images `Tools/eval/images/test40/<espece>/` (ignore par Git).
- Especes (groupes confondables) : carnassiers = brochet, sandre, perche ; cyprinides argentes = gardon, chevaine,
  breme commune ; carpes = carpe commune, carassin argente ; salmonides = truite fario, truite arc-en-ciel.
  Ecart avec la liste de `peche/04 §4.1` (black-bass, silure) : ces deux especes n'ont pas de confondu dans leur groupe ;
  on prefere des paires confondables. A changer ici si l'equipe prefere la liste du plan.
- Par espece : 2 photos `propre`, 1 `main` (poisson tenu en main), 1 `difficile` ou `herbe_epuisette`.
  Total : 20 propre, 10 main, 6 difficile, 4 herbe_epuisette (>= 4 « main » et >= 2 « herbe/epuisette » : respecte).
- Les 40 photos ne doivent pas appartenir au jeu d'entrainement (autres observateurs). Etat actuel : toutes
  `statut_source=a_sourcer` (aucune photo n'est encore choisie). Sources admises : iNaturalist CC0/CC-BY
  (`fetch_images.py`), photos de pecheurs avec consentement ecrit. Renseigner photo_id_inat, licence, auteur, url_source.

## Passes a faire (Mac + iPhone d'Adem)
1. Froid (1er appel), 2. chaud apres prewarm, 3. mode avion, 4. iPhone chaud apres 20 appels. 3 repetitions par passe pour la
variance. Liste candidate : 25-35 especes d'un departement contenant la bonne espece ; seconde passe avec la liste complete.
L'app exporte un `results.json` conforme a `journal.schema.json` ; ensuite :
`python -I score.py --journal results.json --json-out score.json`.

## Criteres (calcules par `score.py`)
| Critere | Seuil GO |
|---|---|
| top-3 global | >= 85 % |
| top-1 global | >= 60 % |
| top-3 de chaque groupe (carnassiers, cyprinides argentes, carpes, salmonides) | >= 70 % |
| latence mediane (p50) | <= 4 s (p95 rapporte, non bloquant) |

Verdict : **GO** si tous les criteres sont verifies ; **NO-GO** si top-3 global < 70 % ; sinon
**GO_AVEC_CONFIRMATION_OBLIGATOIRE** (l'identification reste une proposition, jamais le moteur « phare »).
NO-GO => plan B (`peche/01 §3.7` : choix manuel assiste, questionnaire de traits).

## Regles de comptage
- Photo absente du journal, en erreur (`guardrailViolation`...) ou sans proposition = echec (top-1 et top-3).
- Latence : reponses sans erreur uniquement ; les erreurs sont comptees a part.
- Propositions hors liste candidate : doit etre 0 (`out_of_list`), sinon defaut a corriger avant tout GO.

## Limites statistiques (a lire avant de conclure)
n = 40 : l'intervalle de confiance a 95 % d'un taux de 85 % est d'environ +/- 11 points ; un groupe a 8-12 photos
vaut +/- 25 points. Le verdict est un signal de decision rapide, pas une mesure de precision. Les photos iNaturalist
« propres » surestiment la performance sur photos de pecheurs : d'ou les 10 photos « main » a lire a part
(`par_condition_top3` dans la sortie de `score.py`).
