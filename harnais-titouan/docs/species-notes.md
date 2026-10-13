# Catalogue d'especes : provenance, trous, a valider

Fichiers : `Tools/data-pipeline/species_source.csv` (source editable) -> `python -I Tools/data-pipeline/validate_species.py --build`
-> `PecheCore/Sources/PecheCore/Resources/Data/species.json` (48 especes), controle par `schema/species.schema.json`
et des regles metier (2 phrases par description, 5-6 traits, pas de verdict legal, pas d'emoji, coherence statut/consigne).

## Ce qui est source, ce qui ne l'est pas
| Champ | Source | Niveau |
|---|---|---|
| code Hub'Eau (3 lettres), code SANDRE | API Hub'Eau, `count > 0` verifie le 13/10/2026 (`peche/01 §2`) | verifie |
| nom latin | nom renvoye par Hub'Eau, sauf chevaine (*Squalius cephalus*, nom actuel ; Hub'Eau : *Leuciscus cephalus*) et poisson-chat (Hub'Eau/R432-5 : *Ameiurus*/*Ictalurus melas*, je garde *Ameiurus melas*) | a confirmer INPN/TAXREF |
| statut `protege`, `menace`, `envahissante`, consigne, frayeres 1988 | `peche/03 §2.2` (recherche documentaire, citee [F]) | a confirmer Legifrance |
| famille, categorie, milieu, origine, traits, taille commune, description | **redaction (Claude) a partir de connaissances generales, sans source consultee** (`source_bio = redaction-non-verifiee`) | **non verifie : a relire (Business) et a croiser FishBase/INPN** |
| taille max, anecdote, image | **laisses vides (null)** : rien de source | a faire |

Regle appliquee : pas de valeur de protection ou de statut sans source ; la case reste `null` et la colonne `a_valider`
de la ligne dit quoi verifier. **Cote app, un statut `null` doit se lire « inconnu : relache ou verifie », jamais « aucun »**
(CLAUDE.md regle 1).

## Statuts renseignes (4 sur 48) et pourquoi
- `saumon-atlantique` : `protege` + `relacher` (peche/03 §2.2 (a) : peche fermee au niveau national ; la page cite FNPF 2025 sans texte : **texte a sourcer**).
- `anguille` : `menace` + `verifier` (civelles et argentees interdites en peche de loisir ; anguille jaune : regles qui bougent, **moratoire 2025-2026 non confirme pour la saison 2026-2027**). Volontairement pas `relacher` : consigne exacte a valider.
- `perche-soleil`, `poisson-chat` : `envahissante` + `ne_pas_deplacer` (R432-5 : introduction interdite ; **jamais « a relacher »**, peche/03 §2.2).
- `consigne = verifier` (regle variable) pour brochet, sandre, black-bass, truite fario, ombre (peche/03 §2.2 (b) cite brochet, sandre, truite, black-bass « etc. » ; l'ombre vient de peche/01 : « regles locales strictes », a confirmer).

## A valider (ordre de priorite)
1. **Legifrance, arrete du 8 decembre 1988** : liste exacte et version en vigueur (a-t-il ete remplace ?). `frayeres_1988 = oui` pour 11 especes : brochet, truite fario, saumon, ombre, barbeau meridional, vandoise, ide melanote, bouviere, grande alose, alose feinte, lamproie de Planer. Ce flag signifie « frayeres protegees », **pas** capture interdite. Verifier aussi l'absence de vandoise rostree, loche franche, lamproies marine et fluviatile (non retenues ici).
2. **INPN / liste rouge UICN France / Natura 2000 (annexe II)** pour : lote, hotu, toxostome, blageon, chabot, barbeau meridional, vandoise rostree, bouviere, aloses, lamproie de Planer, saumon, anguille. Aucune de ces especes n'a de `statut` tant que ce n'est pas fait (sauf saumon, anguille ci-dessus). Les notes de peche/01 les marquent « ne pas cibler » en [I] seulement.
3. **Code de l'environnement R432-5 + arrete de liste** : pseudorasbora, carassin argente, carassin dore, silure, perche-soleil, poisson-chat, black-bass, carpe argentee. Seuls poisson-chat et perche-soleil sont sources (peche/03). **Ne pas deduire « envahissante » du caractere introduit.**
4. **Origine (indigene/introduite)** : 12 especes marquees `introduite` (sandre, black-bass, silure, aspe, truite arc-en-ciel, carpe argentee, carassin argente, carassin dore, ide melanote, perche-soleil, poisson-chat, pseudorasbora) d'apres peche/01 [I] ; la carpe commune est mise `indigene` par defaut alors que son statut est discute : a trancher. L'ide est `introduite` ici mais figure sur la liste 1988 : a verifier.
5. **Traits d'identification** (5-6 par espece) : a relire par une personne qui pratique (Business), en particulier les paires confondables : gardon/rotengle, vandoise/chevaine/ide, brème commune/bordelière, carassin commun/argente/carpe, truite fario/arc-en-ciel, barbeau fluviatile/meridional, perche soleil/black-bass jeune. Les cles utilisees : corps, couleur, barbillons, adipeuse, bouche, motif (+ cles libres propres a l'espece).
6. **Tailles communes** : estimations de redaction, non sourcees ; a recouper avec FishBase ou les fiches OFB avant affichage. L'app doit les afficher comme « taille courante » et non comme norme.
7. **Familles** : taxonomie classique (Cyprinidae large ; loche franche en Nemacheilidae). Les revisions recentes (Leuciscidae, Gobionidae, Alosidae...) ne sont pas appliquees : a aligner sur TAXREF.
8. **Regroupements** : `truite-fario` regroupe TRF, TRM (truite de mer) et TRL (truite de lac) de Hub'Eau ; `carpe-*` repose sur trois codes distincts (CCO, CMI, CCU) mais une seule espece biologique : l'identification visuelle les distingue difficilement.

## Hors catalogue (volontairement) : 7 codes de peche/01 §2
Lamproie marine (LPM), lamproie de riviere (LPR), gambusie (GAM), epinochette (EPT), loche italienne (LOB), truite de lac (TRL), truite de mer (TRM) : trop rares ou non photographiables a la canne, ou regroupees. Absents du catalogue : esturgeon europeen, omble chevalier, carpe amour, brochet aquitain (codes Hub'Eau non trouves, `peche/01 §2` fin). **Critere L3** (« toutes les especes des departements pilotes presentes dans les releves sont au catalogue ou listees hors catalogue avec effectif ») : **non verifiable ici** : il faut `rarete.sqlite` / les releves des 10 pilotes pour chiffrer les effectifs. A faire une fois L2 livre.

## Ecarts avec le contrat Swift (`Species.swift`, gele) a signaler a son proprietaire
Le JSON produit contient des `null` et des champs en plus ; il ne se decode pas tel quel avec le contrat actuel :
- `statut` peut valoir `null` (44 especes) alors que `ProtectionStatus` n'a pas de cas « inconnu » ; ne pas le mapper en `aucun`.
- `tailleMaxCm` (toujours `null`), `anecdote` (toujours `null`) et `imageAsset` (toujours `null`) sont non optionnels cote Swift.
- Champs absents du contrat : `codeSandre`, `categorie`, `milieu`, `origine`, `frayeres1988`, `consigne`, `sources`, `aValider`.
- `traits` : cles et valeurs libres (pas de vocabulaire ferme) ; `TraitQuestionnaire` (L8) devra choisir les cles discriminantes.
Pas de modification du contrat ici (`docs/contrats.md`).
