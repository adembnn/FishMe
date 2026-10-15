# Check-list de soumission : état au 15 oct. 2026 (S1 avancé par Sullyvan)

Reprend les lignes de `docs/app-store.md` et les prérequis de `docs/fiches/S1.md`. Case cochée = fait **et prouvé**. « Brouillon prêt » = texte écrit dans `store/`, pas encore validé. Tout le reste : « à faire ». Cette session n'a ni le serveur MCP de MWM, ni App Store Connect, ni le build TestFlight : aucune ligne qui les demande n'est cochée. **[?]** = non confirmé.

## Prérequis de la fiche S1 (« Avant de commencer »)

| Case | Prérequis | État | Preuve |
|---|---|---|---|
| [x] | Nom de l'app choisi | fait : FishMe (Adem, 15 oct. 12h36) | `CLAUDE.md`, ligne « Nom de l'app » |
| [ ] | Serveur MCP de MWM connecté (`get_store_text_rules` répond ; `get_store_connections`) | à faire (non branché ici) | |
| [ ] | `store_send` et `store_publish` sur `confirm` | à faire (`get_assistant_settings`) | |
| [ ] | Quota de génération demandé à MWM | à faire : question n° 11 de `confidentialite-spark-flash.md` | réponse de MWM à ranger dans `store/` |
| [x] | Aucun identifiant de connexion du kit dans git | fait pour `store/` : recherche des deux mots du compte (anglais et français) dans `store/` : zéro résultat (relancée avant chaque commit) | sortie vide, le 15 oct. |
| [ ] | Questionnaire d'âge et « App Privacy » : réponses préparées | **brouillon prêt** : `confidentialite-spark-flash.md` §2 et §3 ; clic dans App Store Connect (rôle App Manager) à faire | |
| [ ] | Liste des fonctions réellement dans le build, refaite à la porte 3, validée par Adem | à faire ; liste provisoire = les 9 étapes E1 à E9 de `parcours-demo.md` avec les fonctions du 15 oct. après-midi, **non vérifiées dans un build** [?] | |
| [ ] | Vendeur légal, contact, prix en euros (colonne France) | à faire : question n° 8 à MWM + lecture de la colonne France | |
| [ ] | Bouton « photo d'exemple » dans TestFlight | à faire : B le confirme à l'écran | |
| [ ] | Liste écrite de MWM sur Spark Flash | à faire : questions n° 1 à 7 de `confidentialite-spark-flash.md` | message de MWM à ranger dans `store/` |

## Check-list de `docs/app-store.md`

| Case | # | Point | État | Preuve ou reste à faire |
|---|---|---|---|---|
| [ ] | 0 | Accès MWM (Paid Apps Agreement, invitations, DSA, délai de grâce) | à faire (A, avant L0) | réponse de MWM |
| [ ] | 1 | Xcode 27.0, iPhone seul, portrait | hors `store/` (A) | |
| [ ] | 2 | Textes de fiche | **brouillon prêt**, pas validé : `fiche-fishme.md` (comptes faits à la main) ; reste : `review_store_text`, mots-clés tirés de `search_market_apps` / `analyze_market_keywords`, couverture des règles, nombre d'espèces reconnues, fonctions Pro à la porte 3, ligne de prix, catégorie | voir `a-trancher.md` |
| [ ] | 3 | Pages web : confidentialité et conditions par le questionnaire de MWM | **réponses préparées** : `confidentialite-spark-flash.md` §1 ; questionnaire, brouillon et vérification des 5 clauses à faire | |
| [ ] | 4 | Captures (écrans bruts par B, habillage par S1) | à faire, après le build ; une capture avec météo garde la marque Apple Weather visible | |
| [ ] | 5 | Questionnaire d'âge | **réponses préparées** (§3 de `confidentialite-spark-flash.md`), clic à faire | |
| [ ] | 6 | Étiquettes « App Privacy » | **réponses préparées** (§2), à confirmer avec la liste de MWM, puis clic | |
| [ ] | 7 | `PrivacyInfo.xcprivacy` de l'app | hors `store/` (A) | |
| [ ] | 8 | Textes d'autorisation en français | hors `store/` (A, L0) ; à relire sur le build [?] | |
| [ ] | 9 | `ITSAppUsesNonExemptEncryption` = NON | hors `store/` ; confirmation du SDK : question n° 7 à MWM | |
| [ ] | 10 | Abonnements : seuls les produits montrés sont joints | hors `store/` ; texte de paywall vu seulement dans le code de `origin/lot/abonnement` (non fusionné, non vu sur iPhone) [?] ; mensuel retenu : pas choisi | |
| [ ] | 11 | Notes pour le relecteur, en anglais | **brouillon prêt**, 2755 octets : `notes-relecteur-en.md` ; manquent : coordonnées du quai de Charenton, lien de la vidéo (B), couverture des règles, contact, vérification sur le build | |
| [ ] | 12 | Disponibilité France, droits, sortie manuelle | à faire avec MWM | |
| [ ] | 13 | TestFlight | hors `store/` (A) | |
| [ ] | 14 | Envoi à la relecture | à faire sur le oui d'Adem ; `get_store_submission` doit ne lister ni `blockers` ni `missing` | |
| [ ] | 15 | E-mail d'Apple, publication à la main | vendredi dès 7 h | |
| [ ] | 16 | Projet MWM, identifiant jamais changé | hors `store/` (A) | |
| [ ] | 17 | SDK : rien avant le consentement | hors `store/` (A, L0 et L6) ; à relire sur le build [?] | |
| [ ] | 18 | Publication des pages par le MCP | à faire sur le oui d'Adem | |
| [ ] | 19 | « Generate Privacy Report » | hors `store/` (A) | |
| [ ] | 20 | Retrait du produit à 34,99 le 1er janv. 2027 | rappel au nom d'Adem [?] | |
| [ ] | 21 | WeatherKit : capacité et service sur l'identifiant | hors `store/` (A, avec MWM) | |

## Tests « fini » de `fiches/S1.md` : ce qui est déjà vérifiable dans `store/`

| Test | Résultat au 15 oct. |
|---|---|
| 4. Notes ≤ 4000 octets | 2755 octets (Python) : OK pour le brouillon |
| 5. `grep` des marques, des mots interdits, de les autres mots interdits sur `store/` | zéro résultat à chaque commit ; la recherche des marqueurs provisoires de la commande du test 5 est aussi vide, mais les crochets `[...]` et `[?]` du texte restent à remplir avant l'envoi |
| 5. Dernier `grep` sur `App/` (« viendra », « bientôt », « prochainement ») | hors `store/`, à faire à l'archive |
| 6. Relecture par S, phrase par phrase contre les captures | à faire après le build ; son nom ira dans le message du commit |
| 7. « Première minute » sur TestFlight | à faire sur l'iPhone |
| 8. Icône (2 appels de génération au plus) | à faire, aucun appel lancé |
| 9. Soumission | à faire sur le oui d'Adem |

## Refus probables (rappel R1 à R9) et ce que cette fiche en tient

- R7 (la fiche promet plus que le build) : la description a trois blocs conditionnels marqués ; rien n'est affirmé sur la couverture, les espèces reconnues ni les fonctions Pro avant la porte 3.
- R6 (météo sans Apple Weather) : « Apple Weather » est cité dans la description et la page Sources ; captures à contrôler.
- R9 (SDK sans consentement) : notes et déclarations nomment Spark Flash ; le consentement reste à vérifier dans le build.
- R4 (achat) : la ligne de prix est laissée en décision (point 2 de `a-trancher.md`).
