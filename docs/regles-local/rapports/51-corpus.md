Décision débloquée : les deux lecteurs de la Marne lisent l'AP 08-2026-PE du 12 mars 2026 (texte rendu par Parallel) et l'avis aux pêcheurs 2026 du 12 mars (couche texte), avec les no-kill et la carpe de nuit en annexe de l'avis.

Textes gardés dans corpus/51/ (manifeste.json : 3 textes, 0 échec)
- ap-2026-08-parallel.html : AP n° 08-2026-PE du 12 mars 2026 (signé Thibaut Felix, DDT 51), texte qui fait foi, permanent, remplace 73-2019-PE, 72-2020-PE et 93-2025-PE (art. 13). Texte lu via Parallel, fichier signé non obtenu en texte : le PDF est un scan sans couche texte (ap-2026-08.pdf, 8 p., même fichier chez peche51.fr et suippes.fr). Le .html est une reprise des articles 1 à 13 mot pour mot, visas abrégés, annexe des parcours de carpe de nuit omise. URL : https://www.peche51.fr/cms_viewFile.php?idtf=53971&path=arrete-permanent-relatif-a-l-exercice-de-la-peche-2026.pdf
- avis-2026-12mars.pdf : avis aux pêcheurs 2026 (version du 12 mars, vise 08-2026-PE), couche texte, contient ouvertures, no-kill (Noblette, Vesle, canal latéral à la Marne, Champ Fleury, étang Renaudin, Blaise), tailles et annexe carpe de nuit. Non daté de signature. Source suippes.fr.
- parcours-recip.pdf : parcours de réciprocité URNE 2026, information seulement.

Cherchés et téléchargés mais NON passés dans le manifeste (scans, OCR non faite)
- reserves-2023-2027.pdf : AP 28-2023-PE du 3 mai 2023, réserves 2023-2027, en vigueur (visé par l'AP). 18 p. scannées. Les réserves manquent donc au corpus tant que l'OCR n'est pas faite. Liste complète des sources : sources-complet.json.
- lac-der-2019.pdf : réglementation spéciale du lac du Der (12 août 2019, prorogée par 45-2024-LE du 25 oct. 2024 d'après marne.gouv.fr) ; l'art. 10 de l'AP renvoie à un arrêté interdépartemental spécifique. Scan.
- carpe-nuit-mod.pdf (AP 25-2025-PE, réserve naturelle Seine Champenoise, carpe de nuit interdite dans son périmètre) : modifie 73-2019, abrogé a priori ; l'interdiction pourrait survivre, à vérifier dans l'annexe de l'avis.
- ap-2019-73.pdf, ap-mod-2021.pdf : abrogés par 08-2026-PE, écartés.

Pourquoi pas d'OCR : le conteneur est saturé (charge 16 à 20 sur 4 coeurs, une page Tesseract dure plus de 10 min). Relancer `python3 -I outils/regles/corpus.py 51` avec sources-complet.json recopié en sources.json quand la machine est libre.

Introuvables ou non cherchés : arrêtés de partage de droit de pêche (hors règles), frayères (marne.gouv.fr, 2023), PCB/mercure (aucune interdiction de consommation repérée).

Ce qu'un lecteur doit savoir
- Dates de 2026 : le brochet 2e cat. rouvre le dernier samedi d'avril (25/04), le sandre le dernier samedi de mai (30/05, nouveauté 2026), fermeture 1ère cat. au 3e dimanche de septembre (20/09).
- Tailles : brochet 0,60 m (1re et 2e cat.), sandre 0,50, black-bass 0,30, truite fario 0,25 sauf Suippe 0,30 et Saulx/Ornain 0,35 (dérogation R436-19 motivée), ombre 0,35.
- Quota : 3 sandres/brochets/black-bass dont 2 brochets au plus (2e cat.), 2 brochets (1re cat.), 4 salmonidés.
- Contradiction : l'avis téléchargé sur peche51.fr (idtf 52403) est l'ancien (vise 73-2019 et 93-2025) ; ne pas l'utiliser. L'AP porte le numéro lu « 006 » par l'OCR, l'avis dit 08-2026-PE.
- Le Code reste plancher; l'AP seul relève le brochet à 60 cm.
