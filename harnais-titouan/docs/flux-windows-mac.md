# Flux Windows → Mac → App Store

Titouan code sur Windows sans compilateur Swift Apple ; Adem compile sur Mac. Le dépôt GitHub est le point de passage.

```
Titouan (Windows)                GitHub                       Adem (Mac)
 Claude Code écrit Swift  ──push──>  branche lot/Lxx  ──CI macos-26──> build.log
 PecheCore testé (swift test        │                         │
  si Swift installé)                │  rouge ?                 │ vert ?
                                    └─> reparateur-build  <────┘      pull + Xcode + iPhone
                                         (gh run view --log-failed)       │
                                                                          v
                                                         ingenieur-release : archive
                                                                          v
                                                      App Store Connect > TestFlight > revue
                                                                 (gardien-appstore veille)
```

## Règles

1. Une branche par lot : `lot/Lxx`. La CI compile à chaque push (`.github/workflows/ios.yml`). Dépôt privé : les minutes macOS coûtent ×10, donc pas de push à chaque ligne ; pousser par lot terminé.
2. Rouge : lancer `reparateur-build` (3 essais max), puis escalade à Adem avec le journal.
3. Vert ≠ fonctionne : seul un iPhone valide caméra, modèle d'Apple, mouvement, achats. Adem teste ces parties.
4. Fusion sur `main` uniquement CI verte + `python Tools/check/check_all.py` OK.
5. Envoi App Store Connect : toujours depuis le Mac d'Adem (Xcode ou Transporter, Mac seulement).
6. Aucun secret dans le dépôt.

## Ce que Titouan peut vérifier seul

`python Tools/check/check_all.py` (vocabulaire interdit, données, imports purs de PecheCore) et, une fois Swift installé via winget, `swift test` dans `PecheCore`.
