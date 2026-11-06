Décision débloquée : quels textes de la Haute-Marne les deux lecteurs lisent (état : collecte faite, extraction OCR non terminée).

Textes trouvés (copies hébergées par la fédération, peche52.fr ; curl y marche) :
- Arrêté permanent n° 52-2025-12-00004 du 1er décembre 2025 relatif à l'exercice de la pêche en eau douce (8 pages, scan sans couche texte). Texte qui fait foi. Téléchargé : ap-52-2025-12-00004-peche-2026.pdf (2 957 675 octets). URL : https://www.peche52.fr/wp-content/uploads/2026/01/AP_52-2025-12-00004_PECHE_2026.pdf. Page 1 vue : en-tête Préfet de la Haute-Marne, DDT, daté du 1er décembre 2025.
- Arrêté carpe de nuit (fichier AP_Peche_2025_carpe_de_nuit.pdf, 7 pages, scan) : https://www.peche52.fr/wp-content/uploads/2025/06/AP_Peche_2025_carpe_de_nuit.pdf. Date de signature à lire. La fédération le liste comme « Arrêté Pêche de Nuit 2026 » ; le guide 2026 dit carpe de nuit du vendredi 27 mars au dimanche 1er novembre 2026.
- Affiche pêche 2026 (information seulement) : https://www.peche52.fr/wp-content/uploads/2026/01/Affiche_peche_2026.pdf
- Guide 2026 de la fédération (information seulement) : https://www.peche52.fr/wp-content/uploads/2026/01/guide_2026_fd52-version-internet.pdf
Plus ancien, probablement remplacé par celui du 1er déc. 2025 (à vérifier dans ses articles d'abrogation) : arrêté permanent n° 52-2024-12-00065 du 10 décembre 2024, copie https://www.peche52.fr/wp-content/uploads/2025/06/AP-relatif-a-lexercice-de-la-peche-en-eau-douce-dans-le-departement-de-la-Haute-Marne.pdf (scan), officiel : page haute-marne.gouv.fr « Documents relatifs à l'exercice de la pêche en eau douce ».
Introuvables : le document « Date d'ouverture 2026 » (lien non exposé par la page download), classement des cours d'eau à part, réserves 2026.
Écarté : anciens permanents 2016 (n° 2535 et 2536, abrogés).

Blocage : corpus.py 52 attend l'OCR (Tesseract) sur un conteneur à 4 coeurs saturé par les autres collecteurs (charge 20), aucun .txt écrit au bout de 30 min. Relancer `python3 -I outils/regles/corpus.py 52` (le PDF est déjà téléchargé), puis lire signe_le et etat. Le sources.json actuel a signe_le null et etat « à vérifier » ; il faut y ajouter le permanent 2024 et fixer signe_le 2025-12-01 pour le premier.
