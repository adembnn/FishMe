# Critique des textes (auto-relecture, 13 octobre 2026)

Limite : relecture faite par l'auteur des textes, sans test utilisateur ni relecture juridique. Les textes marqués (V) dans les fichiers sont ceux de la liste « à valider ». Un passage du vérificateur de formulations (`verificateur-wording`) est encore à faire.

## 1. Trop longs (à raccourcir si l'écran manque de place)
- `prop.warning` (3 phrases) : sur l'écran des propositions, garder la 1re phrase en clair et reléguer le reste derrière « i ». Le texte complet reste obligatoire quelque part de visible.
- `pay.terms` : la mention de facturation automatique est exigée pour 3.1.2(c), donc ne pas couper ; en revanche, `pay.timeline.*` et `pay.stays` peuvent passer sous un « Détails » si la feuille déborde en Dynamic Type.
- `rev.rarity.note` + `rev.rarity.line` + `rev.rarity.weak` : trois lignes empilées sous la carte. Si c'est trop, `rev.rarity.weak` ne s'affiche que pour les espèces de plans d'eau.
- `onb.safety.body` et `onb.dept.body` : deux phrases chacune, lisibles au bord de l'eau seulement si la police suit Dynamic Type. À tester en plein soleil.
- `trip.end.short` : trois idées en une phrase.

## 2. Trop promettants ou à risque
- `pay.promise` « Ce qui est gratuit aujourd'hui le reste » : engagement de l'équipe, à n'afficher que si Titouan, Adem et le business s'y engagent. Retirer sinon.
- `pay.stays` : dépend de la grille gratuit/Pro, non tranchée (descriptif : 15 cartes ; plan de build : 1 département et 30 prises). `pay.subtitle` et `pay.banner` parlent de « cartes gratuites » : à changer si la grille change. Le chiffre doit venir d'une constante, pas du texte.
- `pay.cta` « Essayer 7 jours » : le mot « gratuit » est volontairement absent du bouton ; `pay.year.sub` dit « 7 jours offerts ». Vérifier que la durée de l'essai affichée est celle configurée dans App Store Connect (7 jours, et non 3).
- `pay.timeline.reminder` « Jour 5 : rappel avant facturation » : à n'afficher que si le rappel est réellement programmé (il suppose l'accord notifications). Sinon retirer la ligne.
- `rules.asof` « vérifiées le … » : suggère un contrôle humain daté. Vrai seulement si la date est maintenue pour chaque fiche.
- `prot.body` « protégée en France » : affirmation de statut sur l'espèce. Les statuts du catalogue sont des inférences à valider sur Légifrance (descriptif §5). Si une espèce n'est pas confirmée, utiliser « Cette espèce est sensible : si c'est bien elle, relâche-la immédiatement. »
- `prep.foot` « Carte de pêche obligatoire, hors eaux closes » : règle générale correcte d'après les sources, mais c'est une affirmation légale ; à faire relire par la fédération.
- `rev.rarity.5` « Exceptionnelle » et tout le vocabulaire de rareté : les seuils et les noms des 5 classes ne sont pas tranchés (voir CLAUDE.md, décision ouverte a). Les noms viennent de la maquette (Commune, Peu commune, Rare, Très rare) plus un cinquième inventé ici.
- `cam.analyzing` « Je regarde ta photo... » : ne promet rien, mais parle à la première personne ; à harmoniser avec le reste de l'app (qui parle peu de « je »). Si le go/no-go identification est négatif, les textes de `prop.*` restent valables (propositions par fréquence), mais `err.nofish` et `err.ai.unavailable` ne doivent pas suggérer que l'app « reconnaît » quoi que ce soit.
- `best.more` « Encore %lld à découvrir » et `notif.friday` : légère incitation à collectionner. Gardés parce qu'ils ne contiennent ni urgence ni rareté, mais à surveiller (règle : pas de pression).

## 3. À valider (décisions produit ou juridiques)
1. `spec.record` « Taille notée » : le descriptif liste « Record personnel » ; la règle « pas de chasse au gros » plaide pour supprimer cette carte ou pour ce libellé neutre.
2. `none.unknown` (enregistrer sans nom d'espèce) : nouveau flux, non prévu dans le descriptif ; à décider ou à couper.
3. `det.kept` « Non relâché » : la maquette dit « Gardé ». Choix volontairement neutre ; vérifier qu'il ne se lit pas comme un encouragement à garder.
4. Les 14 phrases `bred.q.*` : tonalité à faire valider par au moins deux testeurs ; `bred.q.13` (« jour de congé ») et `bred.q.9` sont les plus fantaisistes. La phrase de la maquette (« Le poisson t'a vu avant toi. ») est conservée en n° 1.
5. Les 30 titres de niveau : purement décoratifs, aucun lien avec la taille ou la rareté ; à relire pour les doublons de sens (par ex. 8 et 12).
6. `ach.observe.desc` : formulation un peu obscure ; à reformuler quand le déclencheur du succès sera défini.
7. Mode débutant : `set.beginner.sub` décrit l'intention, mais le contenu réel du mode (ce qui change) n'est pas défini ailleurs.
8. Article du département : `{dans}` et `{du}` supposent une table de données avec la forme correcte pour les 101 départements (« dans le Loiret », « en Isère », « dans les Yvelines »). « En » n'est pas géré par le gabarit actuel ; prévoir un champ complet « dans/en + nom ».
9. Pluriels et accords (« 1 cartes ») : à régler par variations du String Catalog avant l'envoi.
10. Anglais : le CLAUDE.md et la revue App Store prévoient FR/EN pour les chaînes d'usage ; aucun texte anglais n'est écrit ici.

## 4. Points conformes (vérifiés à la relecture)
- Aucun verdict légal ; `rules.warning` et `prop.warning` reprennent les textes fixes du projet. Aucun pourcentage d'identification, aucune probabilité de capture, aucune marque tierce, aucun emoji, aucune urgence ou fausse rareté. Le prix annuel est le premier élément de prix du paywall, l'équivalent mensuel et la durée d'essai sont en petit.
- Non vérifié : rendu réel (longueurs sur iPhone, Dynamic Type, VoiceOver), validité des placeholders dans un String Catalog compilé, relecture juridique, test avec de vrais pêcheurs.
