# Harnais de Titouan, à fusionner avec celui d'Adem

Dossier volontairement séparé (`harnais-titouan/`) pour ne rien écraser à la racine : le `CLAUDE.md`, `.claude/` et `docs/` de la racine restent ceux d'Adem. Rien n'est actif ici tant qu'Adem ne l'a pas fusionné.

À savoir pour la fusion :
- 21 agents dans `.claude/agents/` (critique, coupeur, inspecteur-harnais, revue-appstore, revue-ux-2taps, verificateur-wording, auditeur-donnees, reparateur-build, architecte-apple, builder-swiftui, builder-coeur, integrateur-apple, ingenieur-release, gardien-appstore, designer-apple, redacteur-fr, evaluateur-design, testeur-coeur, testeur-parcours, testeur-identification), 9 skills, carte dans `docs/harnais-bredouille.md`.
- Socle Apple (à lire en premier) : `docs/apple-design/00-socle.md`, détail 01 à 04. Build : `docs/modalites-build-apple.md`. App Store : `docs/preflight-appstore.md`. Décisions : `docs/decisions-produit.md`. Flux Windows vers Mac : `docs/flux-windows-mac.md`.
- Lots : `plan/SUIVI.md` et `plan/lots/L0` à `L41`. Parcours : `docs/parcours.md` (20 parcours).
- Cœur Swift pur testable sous Windows : `PecheCore/`. Vérification : `python Tools/check/check_all.py`.
- Hooks : spécification seulement (`.claude/HOOKS-A-INSTALLER.md`), aucun script installé. Adem a déjà des hooks (`garde-lot.py`, etc.), à rapprocher.
- Exclus du dépôt : les 24 Mo de photos d'évaluation (`Tools/eval/images`, manifeste conservé) et le cache Hub'Eau.
- Rien n'a été compilé. Swift n'est pas installé sur le PC de Titouan : tout le Swift est « écrit, non compilé ».
- Le `ios.yml` déclenche sur `main` et `lot/**` ; à aligner avec `verif.yml` d'Adem.
