Décision débloquée : quels textes de Pyrénées-Atlantiques (64) les deux lecteurs lisent

État : 0 texte gardé en texte intégral. Les 5 références sont identifiées, aucun PDF signé n'a pu être téléchargé ni lu.

Source de référence : page officielle « Règlementation pêche en eau douce » (préfecture 64, mise à jour 11/05/2026), lue via Exa et web_fetch (pas via curl depuis ce Mac).
Textes identifiés, sans texte lu :
- AP 64-2025-12-22-00008, pêche 2026 hors migrateurs (HMIG), publié 06/01/2026. Date lue sur le numéro seulement.
- AP 64-2026-05-05-00019, pêche 2026 migrateurs (MIG), publié 11/05/2026. Date lue sur le numéro seulement.
- AP permanent 2008-347-21 du 12/12/2008 (espèces non migratrices), avec modifs 2010, 2011, 2012 et 2024. Permanent.
- AP 64-2024-05-22-00006 du 22/05/2024, lacs de montagne au-dessus de 1000 m. Modifie le permanent.
- AP 64-2022-11-09-00019, réserves de pêche 2023-2027.
- Arrêté lac de Saint-Pé-sur-Nivelle 2015-247-004 (modifié 2017) : identifié, non intégré dans sources.json.
- Anguille (points de débarquement et de collecte, 2018) : écarté, pêche professionnelle.

Bloquants techniques :
- Les PDF de pyrenees-atlantiques.gouv.fr ne répondent ni par curl (ce Mac), ni par Wayback (absents de l'index), ni par Exa (CRAWL_UNKNOWN_ERROR), ni par web_fetch.
- Aucune copie trouvée chez la fédération ou une AAPPMA lors de la recherche (WebSearch).
- Le guide de la fédération n'a pas été ouvert.
- Pas de fichier brut, donc corpus.py n'a pas été lancé : il ferait des appels curl vers gouv.fr, interdits sur ce Mac.

Ce qu'il faut savoir :
- Texte qui fait foi pour l'année : les deux AP 2025-2026 (HMIG et MIG), avec le permanent 2008 modifié.
- Un document « Synthese observations_AP peche MIG 2026_SIGNE.pdf » (préfecture) existe dans l'index Wayback, mais c'est une synthèse de consultation, pas le texte de règle. Non téléchargé.
- Une note et un projet d'AP HMIG 2026 V2 (novembre 2025) existent, mais ce sont des projets : à ne pas utiliser.

Prochaine action pour débloquer : Adem récupère les deux PDF 2026 et le permanent 2008 depuis un navigateur sur son PC, ou la fédération 64 les fournit. Les fichiers vont dans outils/regles/corpus/64/ avec le nom indiqué dans sources.json, puis corpus.py 64 et le rapport se finissent.
