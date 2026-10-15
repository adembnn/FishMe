# Reprise du chantier maquettes (15 oct.)

Toile de commentaires (artefact Design, privé, à partager via Partager) : https://claude.ai/artifact/RaADxKs61qxNQFNGx5B6Nf
Sources de la toile : `maquettes/toile/project/` (canvas.json + un .dc.html par écran, chaque écran = une image PNG uploadée). Outils de capture : `maquettes/toile/shot.mjs` (`node shot.mjs <html> <png> 2500` → « no console errors »), `taps.mjs` (cibles ≥ 44 pt).

## Décisions d'Adem
- Navigation : **piste A, iOS natif** (barre d'onglets en verre Pescedex / Carte / Club). Maquette finale : `trois-volets/A2/` (5 écrans).
- **Pescedex global** par défaut (tous mes poissons), puis **filtre par spot** (pastilles). Compteur par spot : « 3 espèces trouvées sur 11 présentes ici » + « Hors liste · 1 » (légendaire).
- **Un spot gratuit**, les autres en abonnement. Spot dessiné comme un tronçon de rivière surligné « Ton spot », autres coins avec cadenas.
- Bouton « **Où chercher ?** » (« meilleur » interdit). Mot « **session** », pas « sortie ».
- **Aucune barre de défilement** visible.
- Règle projet : **token maxing** (pas d'économie), plusieurs pistes + critique Opus.

## Questions ouvertes (posées à Adem, avec ma reco)
1. Récap sur la carte : X vignette BeReal / Y « Ta saison » Wrapped / Z carte postale (`trois-volets/recap/`). Reco : X après chaque session, Y en fin de saison.
2. Zone du Pescedex filtré : rivière avec repli département (reco) / département / rayon (`reports/pescedex-par-zone.md`).
3. Choix du spot au 1er lancement : X arènes / Y lignes à l'eau / Z cartes retournées (`trois-volets/choix-spot/`). Reco : Z.
Défauts appliqués : « présentes » = vues par l'OFB ; récap partageable sans lieu précis ; une page par zone.

## Définition du spot (défaut du fil « Plan de construction », posé à Adem en question 4)
Vendredi : un **cercle de 1 km** figé à sa création, nommé d'après l'eau la plus proche, règles du département de son centre ; tronçon ou lac entier dans la mise à jour. Règles et fiche de tout spot gratuites ; payant = session et carte hors du spot gratuit. À faire : passer les maquettes (carte A2, choix du spot) du tronçon surligné au cercle. Questions encore à moi : rayon, changement de spot, mer. Recherches : `reports/spot-reglementation.md`, `reports/spot-technique.md`.

## Prochaines étapes
- Appliquer les 3 réponses d'Adem : refaire A2 avec le récap et le choix de spot retenus.
- Correctifs connus de A2 : étiquette « Ton spot » décalée, distances de D et A inconnues, menu « ··· » du Club non dessiné, écran « spot verrouillé touché », mode sombre, texte agrandi.
- Explorations précédentes (gardées pour l'historique) : `niveau-1/` (parcours 16 écrans), `trois-volets/` A-F + `critique-trois-volets.md`.
