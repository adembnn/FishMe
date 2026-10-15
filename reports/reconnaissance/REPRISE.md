# Reprise de la reconnaissance (pause du 15 oct. 2026, 18h)

Adem a tout mis en pause à 17h56 UTC pour environ 1h30. Rien n'est perdu : tout ce qui ne se retélécharge pas est ici.

## Où on en est
- Scores du soir (cloud, 23 595 photos) : `banc-essai/README.md`, section « Mise à jour du 15 oct. au soir », et `banc-essai/eval3/`.
- Vecteurs des 23 595 photos : `banc-essai/vecteurs/` (traite.jsonl + .f32, 768 nombres par photo). Avec eux, `scripts/evaluer.py` et `scripts/seuils.py` refont les scores sans les photos.
- Photos : jamais ici. Elles se retéléchargent avec `scripts/telecharger.py` et les manifestes de `banc-essai/manifestes/`.

## À relancer
1. **fisch-hitparade.de** : 2 747 pages lues sur environ 8 054. Copier `sauvegarde/agent-peche/` dans un dossier de travail, puis lancer 6 flux : `for k in 0 1 2 3 4 5; do python3 -I fhshard.py $k 6 & done` (ils sautent les pages déjà lues dans fh_sample*.jsonl). Manifeste : `python3 -I build.py` → /root/fishdata/manifeste_peche_fisch-hitparade.csv (2 331 photos pour l'instant). Puis télécharger, `traiter.py`, `evaluer.py` avec le manifeste en plus.
2. **Nouvelles listes de photos, pas encore téléchargées** (dans `banc-essai/manifestes/`) : `manifeste_peche_europe.csv` (978 photos : carnet de pêche hongrois haldorado, nachytano.cz, Flickr CC ; hotu 150, carpe argentée 171, black-bass 127, grande alose 40, lamproie marine 47, saumon 35, huchon 11, brochet 207, silure 82) et `manifeste_public_us.csv` (89 photos du domaine public USGS/USFWS). Les télécharger avec `telecharger.py`, `traiter.py`, puis `evaluer.py` avec ces manifestes en plus. Attention : « Busa » de haldorado peut mêler carpe argentée et carpe à grosse tête. Pistes non finies : Petri-Heil.net et alpines-angeln.de (huchon). Scripts des recherches dans `sauvegarde/agent-us/` et `sauvegarde/agent-eu/`.
3. **Mac d'Adem** (~/FishMe-reco) : AFFiNe rangé dans createml/ (5 560 entraînement, 1 851 test, sans segmenteur). prep_gbif.py arrêté (2 745 photos GBIF brutes dans brut/, 10 classes sur 46 ; il saute désormais celles déjà présentes). Dans l'ordre : finir prep_gbif.py, `swift entrainer.swift` sur AFFiNe seul, `swift recadrer_vision.swift`, `swift entrainer.swift` sur tout. Scripts aussi dans `banc-essai/mac/`.
4. Décision d'Adem toujours en attente : iNaturalist.
