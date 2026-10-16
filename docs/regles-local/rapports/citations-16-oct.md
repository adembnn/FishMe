# Citations qui ne prouvent pas leur phrase (16 oct., suite du banc passe 3)

Contrôle sur les 20 317 règles de regles/local, hors 75, 77, 92, 93 et 94 (saisis à la main, non modifiés).
Une citation est rejetée si elle est vide, finit par « : » (en-tête de liste), annonce une liste (« ci-après », « suivants ») sans nommer le lieu de la règle, ou ne contient pas le nombre que la règle affirme (taille, quota, lignes).

- 1 481 citations rejetées.
- 193 corrigées par la citation de la seconde lecture, quand elle passe le contrôle et ne sert pas aussi à une autre règle.
- 1 288 restent sans preuve et passent en « incertain » (l'app dit « vérifie l'arrêté »), avec "citation_a_revoir" qui dit pourquoi.
- Aucune règle retirée, aucun identifiant changé.

Cas cités par le banc :
- 16-truite-no_kill-boeme-amont : la citation décrit le parcours sans dire « no-kill » : incertain.
- 68-toutes-interdit-appat-* (4 règles) : citation « Il est interdit d'employer comme appât : » seule : incertain.
- 85-toutes-reserve-frayere-sandre-lac-du-marillet-n1 à n10 (et les autres lacs) : la citation annonce la liste sans nommer la frayère : incertain.
- 28-tous-interdit-huisne : la citation est juste, mais le texte interdit la pêche en marchant dans l'eau, pas toute pêche : type passé de « interdit » à « mode_peche » (statut incertain inchangé).

Ain, truite (01-truite-taille_min-dept) : l'article 5-1 de l'arrêté 2026 signé dit 25 cm sur tout le département sauf les secteurs listés, à 30 cm. Les deux valeurs sont justes. La règle départementale passe en incertain : tant que l'eau n'est pas reconnue, l'app dit « vérifie l'arrêté » au lieu d'afficher 25 cm. Les règles des secteurs à 30 cm restent.

Outil : citations.py (dossier de travail du cloud, non commité), à relancer après chaque nouvelle lecture.
