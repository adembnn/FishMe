# Modèle de reconnaissance FishMe (R1, repli à 6 espèces), fabriqué dans le cloud le 15 oct. 2026
Branche de transport, jamais fusionnée dans main (le cloud n'a pas le droit d'écrire dans App/Prise/).
Examen passé (critères 1 à 6) : top-1 83,9 %, top-3 93,0 % ; prises de pêcheurs 98,1 % top-1 ; « pas un poisson » refusé à 98,9 %.
Rapport complet : reports/reconnaissance/cloud-coreml.md sur lot/reconnaissance (ad439f9).

Sur le Mac, depuis le dépôt, dans la copie du lot qui tient App/Prise (lot/prise ou mac/integration) :
    git fetch origin modele/reconnaissance
    mkdir -p App/Prise/Modele && git archive origin/modele/reconnaissance | tar -x -C App/Prise/Modele
    (garder FishMeReco.mlpackage et classes.txt ; README.md et scores.json peuvent rester ou partir)
Le .gitignore exclut *.mlpackage : `git add -f App/Prise/Modele/FishMeReco.mlpackage` si on veut le versionner.

Chargement dans l'app :
- Entrée `image` RGB 224×224 (0-255), normalisation incluse. Vision : VNCoreMLRequest, imageCropAndScaleOption = .scaleFill.
- Sorties : classLabel et classLabel_probs ; avec Vision, VNClassificationObservation triées (identifier = id d'espèce, confidence).
- Classes : autre-poisson, black-bass, brochet, carpe-commune, pas-un-poisson, perche, sandre, truite-commune (= fario).
- Si la 1re observation est pas-un-poisson ou autre-poisson, ou si sa confiance < 0,55 : ouvrir la grille « Autre ».
  Sinon proposer les 3 premières espèces (sans les deux classes de refus) plus la case « Autre ». Le pêcheur confirme toujours.
- À vérifier sur le Mac : exécution Core ML réelle (float16) sur une cinquantaine de photos ; sous Linux seul le réseau PyTorch identique a été mesuré.
