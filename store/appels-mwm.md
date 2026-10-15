# Appels au serveur MCP de MWM, dans l'ordre

Prêt pour le jour où le connecteur MWM est autorisé sur claude.ai (le 15 oct. en fin d'après-midi, `https://mcp.mwm.ai/mcp` répond 401 depuis le cloud : joignable, mais pas encore connecté au compte de l'équipe). Noms d'outils tirés de `docs/fiches/S1.md`. **Lecture** = sans effet, se lance sans demander. **Écrit** = attend le oui d'Adem écrit dans le fil, à chaque appel. **Facturé** = génération payée sur le compte de l'équipe, jamais avant la réponse de MWM sur le quota.

## 1. Vérifier le branchement (lecture)
1. `get_store_text_rules` avec `stores: ["apple_app_store"]`, `locales: ["fr-FR"]` : limites à jour ; corriger les comptes de `fiche-fishme.md` si elles diffèrent.
2. `get_store_connections` : App Store Connect est-il relié côté MWM ?
3. `get_assistant_settings` : `store_send` et `store_publish` doivent être sur `confirm`. Sinon `set_assistant_setting` pour les y mettre (seul appel qui écrit sans oui préalable, car il ne fait que rendre le compte plus prudent).

## 2. Textes de la fiche (lecture)
4. `search_market_apps` (boutique française, « pêche », « pêche carpe », « carnet de pêche ») et `analyze_market_keywords` sur la liste de `fiche-fishme.md` et sa liste de repli. Refaire les mots-clés depuis ces chiffres ; un mot absent des données est « pas relevé ».
5. `review_store_text` sur chaque champ : nom, sous-titre, mots-clés, texte promo, nouveautés, description. Coller le résultat sous chaque champ de `fiche-fishme.md`.

## 3. Confidentialité et conditions
6. `get_legal_questionnaire` (lecture), puis `save_legal_answers` (écrit, brouillon seulement) avec les réponses de `confidentialite-spark-flash.md` §2, `jurisdictions` France et UE.
7. `draft_legal_document` (aperçu) : vérifier les 5 clauses de `confidentialite-spark-flash.md` §1. Une clause manque : arrêt et e-mail à MWM, aucun texte écrit à la place.
8. `publish_legal_document` : **écrit, oui d'Adem**. Les deux URL vont dans la description et dans App Store Connect.

## 4. Icône (facturé, 2 appels au plus)
9. `generate_app_icons`, 4 propositions en `low`, à partir de la piste choisie par Adem sur la page des logos (à plat, sans 3D, rien qui vise les enfants, aucun poisson-mascotte).
10. Adem choisit ; `iterate_app_icon` en `high` sur celle-ci. Fichier 1024 px sans transparence remis à A pour `App/Assets.xcassets/`.

## 5. Fiche et captures (écrit, oui d'Adem à chaque appel)
11. `send_store_listing` : textes de `fiche-fishme.md`, une fois `fonctions-du-build.md` coché et les crochets remplis.
12. Captures : B dépose les écrans bruts (`fastlane captures`), `design_store_screenshots` propose 3 styles (facturé), `apply_screenshot_design` habille la série ; relire chaque titre contre `fonctions-du-build.md` ; la marque Apple Weather jamais recouverte. Puis `update_app_store_screenshots` (écrit).
13. `draft_landing_page`, puis `publish_landing_page` (écrit) : après l'envoi de la fiche ; devient l'URL marketing.

## 6. Soumission (écrit, oui d'Adem)
14. Après l'envoi du build par A (`scripts/envoi.sh`) : `get_store_submission` (lecture) doit ne lister ni `blockers` ni `missing`.
15. `submit_store_version_for_review` : **oui d'Adem**, jamais avant.

L'identifiant `ai.mwm.build.challenge.team.01` ne change jamais. Aucun identifiant de connexion du kit dans ce dossier.
