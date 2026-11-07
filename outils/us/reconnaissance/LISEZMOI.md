# Reconnaissance États-Unis : jeu de photos, tête US, examen (lot us-reco, 7 nov. 2026)

Aucune photo n'est dans git. Données et venv : `/private/tmp/claude-501/us-reco/` (effacées au redémarrage du Mac).
Réserve juridique NON levée : conditions d'iNaturalist non vérifiées (voir « Risques »). Rien ici ne vaut avis juridique.

## Architecture : un tronc, une tête par région
- Tronc partagé : DINOv2-small (image 224x224, sortie 768 nombres = CLS + moyenne des patchs, normalisée), ~22 Mo en int8. Inchangé.
- Tête Europe : inchangée (55 classes). Tête US : 78 espèces + « autre poisson » + « pas un poisson » = 80 classes. L'app choisit la tête selon la région ; une seule inférence du tronc.
- Taille de la tête US : 80 x 768 octets en int8 = 61 440 octets + 8 octets par classe = **environ 62 Ko** (float16 : ~123 Ko), contre ~22 Mo pour le tronc. Mesuré sur la démo à 6 classes : 4 656 octets (formule dans `rapport.json`). Ajouter une région coûte donc des Ko, pas des Mo.
- Export Core ML : deux options. (a) Tronc exporté seul (sortie : 768 nombres, `outils/reconnaissance/cloud/convert.py` sans la tête) + tête en petit fichier de poids lu par Swift (produit matriciel Accelerate) : Europe ne change pas, une région = un fichier. (b) Un modèle Core ML par région (tronc + tête) : simple mais 22 Mo par région, à éviter. Recommandation : (a). Non essayé ici : `coremltools` n'est pas installé (installation lourde, hors mission) ; la sortie Vision actuelle de l'app (classes dans le modèle) devrait être remplacée par un lecteur de tête, **changement dans App/ qui n'est pas de ce lot**. Équivalence numérique tronc seul + tête Swift vs modèle tout-en-un : à tester.

## Scripts (Python 3.9 du Mac, `python3 -I`)
| Script | Rôle | Vérifié |
|---|---|---|
| `construire_jeu.py` | liste de photos par espèce (manifeste.csv : licence, classe de licence, observateur, découpe, source, date) et volumes réels (`--compter`) | oui, 74 espèces comptées, 116 photos listées pour 2 espèces |
| `telecharger_echantillon.py` | 6 espèces de démo, 120 photos, 16,9 Mo, `licences.csv` | oui |
| `extraire_et_entrainer.py` | caractéristiques DINOv2-small, tête (régression logistique), taille de la tête | oui, sur les 120 photos |
| `examen.py` | protocole d'examen sur vraies prises (ci-dessous) | tests sur données fabriquées seulement (`tests/test_us_reco.py`, 3 tests verts) |

Installer l'environnement : `python3 -m venv /private/tmp/claude-501/us-reco/venv && venv/bin/pip install -r requirements.txt` (fait ici : torch 2.8, transformers 4.57, scikit-learn 1.6 ; DINOv2-small téléchargé depuis Hugging Face ~90 Mo ; ~1 Go de disque).

Source des listes : **API GBIF** (jeu « iNaturalist Research-grade Observations », pays US, avec images ; licence et auteur par média), images lues sur le bucket public `inaturalist-open-data` en taille « medium » (une requête par seconde, User-Agent déclaré). Raison : le robots.txt de `api.inaturalist.org` contient `Disallow: /` et celui de `inaturalist.org` déclare `ai-train=no` (lus le 7 nov.). L'accès par l'API iNaturalist est codé mais **bloqué** tant que `FISHME_INAT_API_OK=1` n'est pas posé (décision de Titouan). Quatre requêtes de comptage ont été faites sur api.inaturalist.org avant la lecture de ce robots.txt (per_page=1) ; aucune depuis. Le bucket complet (métadonnées mensuelles, plusieurs Go) n'est pas implémenté : à faire si l'on préfère ce chemin. GBIF ne contient que des photos sous licence CC : les photos « tous droits réservés » ne sont pas accessibles par cette voie.

Classes de licence : `libre` (CC0, CC BY), `entrainement_seul` (CC BY-NC, BY-SA, NC-SA : jamais publiées ni vendues), `exclue` (ND, inconnue). Découpe 70/15/15 par observateur (hachage stable) ; val et test ne gardent que des photos libres, les autres photos de ces observateurs sont écartées (jamais reversées dans l'entraînement).

## Volumes réels (API GBIF, 7 nov. 2026, `volumes-gbif-2026-11-07.json`)
Observations de qualité « research » avec photo aux États-Unis, 74 espèces comptées sur 80 entrées (hybrides wiper, saugeye, tiger muskie : pas de taxon ; grass pickerel, redfin pickerel, redhorse : nom non reconnu à reprendre) : **221 679 observations, dont 20 274 en CC0/CC BY (9 %)**, le reste surtout CC BY-NC. Les 6 démos : bluegill 44 395, rainbow trout 12 857, channel catfish 7 576, largemouth 3 345 (le rapport citait 35 303 : GBIF est un instantané partiel), northern pike 2 317, walleye 1 616. Espèces libres < 100 photos : **32 sur 74** (< 30 : 17), par exemple bull trout 2, cisco 3, bighead carp 3, arctic char 4, burbot 10 ; florida bass 0 (nom fusionné avec le largemouth). Avec les photos non libres, seules 5 espèces ont moins de 100 observations. Une observation peut avoir plusieurs photos. [?] Nombre d'observateurs distincts non mesuré.

## Démo sur 120 photos : preuve de chaîne, aucune valeur statistique
66 photos en entraînement, 54 en test (observateurs distincts), 6 classes : top-1 63 %, top-3 85 %. 54 photos de terrain iNaturalist, tête de 6 classes : ce chiffre ne dit rien du modèle final et ne se compare pas au v2 européen. Entraînement : 0,02 s ; extraction de 120 photos : ~3 s sur ce Mac.

## Examen avant embarquement (`examen.py`, seuils écrits avant tout score)
Jeu : **vraies prises de pêcheurs** étiquetées à la main, jamais vues à l'entraînement (les photos iNaturalist ne comptent pas : photos de terrain 47,9 % de top-1 contre 82,5 % sur prises, pour le v2). Journal : `fichier,vraie,p1,p2,p3,conf1,source`. Le modèle passe s'il tient TOUT :
1. top-1 sur prises d'espèces >= 82,5 % et 2. top-3 >= 91,6 % (le v2 européen sur 7 062 prises de pêcheurs) ;
3. au moins 300 prises d'espèces (sinon pas de verdict ; borne de Wilson 95 % affichée) ;
4. refus des « pas un poisson » >= 92,9 % (v2 : 342/368 ; refus = étiquette pas-un-poisson/autre-poisson en tête ou confiance sous le seuil) ;
5. par espèce : >= 10 prises et top-3 >= 80 %, sinon l'espèce sort de la tête (reste dans la grille).
Recalibrage du seuil 0,4 : balayage 0,10 à 0,90 ; on retient le plus petit seuil dont le top-1 sur les photos proposées est >= 90 % (plancher 0,30), tableau `recalibrage.csv`. Le 0,4 actuel vient d'une mesure v1 (confiance moyenne 0,68 si juste, 0,35 si faux).

## Plan de collecte du jeu de test de prises (à lancer par Titouan, rien n'est fait)
- Cible : 300 prises d'espèces au minimum (un verdict à +/- 4 points), idéalement 10 à 15 par espèce pour les 20 espèces les plus pêchées (nord-américaines : largemouth, smallmouth, bluegill, crappie, channel catfish, rainbow/brown/brook trout, walleye, northern pike, striped bass...), plus 50 « pas un poisson » (mains, bateau, cannes, paysages, appâts) et 30 « autre poisson ».
- Sources : (1) photos prêtées avec accord écrit par des pêcheurs américains (groupes de pêche, guides, amis ; accord par photo, usage test interne) ; (2) photos prises par Titouan ; (3) pas de photos aspirées de réseaux sociaux. Licence ou accord enregistré par photo.
- Étiquette : l'espèce est relue par une seconde personne qui connaît la région (cas ambigus : black bass entre eux, truites, crappies) ; photo douteuse = exclue, pas devinée.
- Tenue à l'écart : le jeu d'examen n'entre jamais dans `construire_jeu.py` ; observateurs distincts de l'entraînement.
- Conditions de prise variées : en main, sur épuisette, sur le sol, flou, nuit.

## Risques
1. **Juridique** : CGU d'iNaturalist non lues (403 au rapport du 7 nov.) ; robots.txt du site : `ai-train=no` ; robots.txt de l'API : tout interdit. Le contenu GBIF est sous licence CC par photo mais les CC BY-NC interdisent l'usage commercial : un modèle commercial entraîné dessus est une zone grise. Décision n°4 du 7 nov. (toutes photos, jamais publiées ni vendues) prise ; la réserve reste ouverte. Piste : écrire à help@inaturalist.org.
2. **Biais de domaine** : photos d'observation (poisson dans l'eau, de loin) contre prises en main ; baisse attendue de plusieurs dizaines de points avant examen.
3. **Raretés** : 17 espèces avec moins de 30 photos libres ; entraînement possible avec photos NC, test seulement libre.
4. **Espèces proches** (black bass, crappies, redhorses, truites) : confusions ; regroupements possibles par classe de groupe.
5. Instantané GBIF partiel et décalé ; choisir entre GBIF et bucket complet avant le grand téléchargement.

## Ce qui reste sur la machine (`/private/tmp/claude-501/us-reco/`)
`venv/` (~1 Go), `echantillon/` (120 photos, 16,9 Mo, `licences.csv`), `jeu/volumes.json`, `jeu-test/manifeste.csv`, `modele/` (caractéristiques, `tete-us.npz`, `rapport.json`), cache Hugging Face (`~/.cache/huggingface`, ~90 Mo). Supprimer à la fin si besoin d'espace.
