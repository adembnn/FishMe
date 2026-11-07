# Consigne de lecture : règles de pêche d'un État américain

Tu es le lecteur {A ou B} des règles de pêche en eau douce de l'État {ETAT}. Un autre lecteur lit les mêmes textes sans toi ; ne lis jamais son fichier.

## Ce que tu reçois
Un PDF ou une page HTML d'agence (livret, tableau d'espèces, fiche d'un plan d'eau), déjà téléchargé dans `corpus/{ETAT}/`, avec son URL, son édition et sa date de lecture.

## Ce que tu écris
UN fichier `lecture-a/{ETAT}.json` (ou `lecture-b/`) conforme à `schema-regle-us.json`. Rien d'autre.

## Règles
1. **Une règle par espèce et par disposition** : jamais plusieurs espèces, plusieurs lieux ni plusieurs types dans une règle.
2. **Portée** : niveau_portee `etat` (niveau 2), `zone`, `plan_eau` ou `troncon` (niveau 3). Écris le nom du plan d'eau comme dans le texte (« Lake Fixture », « St. Clair »), le comté s'il distingue deux eaux homonymes, et `lieu` en toutes lettres. Une règle spécifique à un plan d'eau est une règle à part, jamais fondue dans celle de l'État.
3. **Citation** : chaque règle porte une citation exacte du texte (200 caractères au plus, au mot près, anglais d'origine), l'URL de la source et la date de lecture. Pas de citation, pas de règle. Si une ligne de tableau est illisible, mets `statut: incertain` et dis pourquoi dans `raison_incertain`.
4. **Nombres comme nombres, dans l'unité du texte** : pouces (`pouces`), livres (`livres`), nombre de poissons (`nombre`). Ne convertis pas. Une fenêtre protégée : `pouces_min`, `pouces_max` et `mode`.
5. **Dates** : AAAA-MM-JJ ou MM-JJ ; une saison à cheval sur deux années (1er décembre au 15 mars) s'écrit `du` 12-01, `au` 03-15 ; ne la coupe pas. Toute l'année = 01-01 à 12-31 ou null.
6. **Incertitude** : au moindre doute (renvoi à une note, exception de plan d'eau non lue, tableau flou, édition ancienne), `statut: incertain` et `raison_incertain`. Une règle incertaine ne sera jamais chargée.
7. **Jamais de permission déduite** : n'écris que ce que le texte dit. Le silence du texte n'est pas une règle ; « rien n'est dit » ne devient jamais « c'est permis ». Pas de règle qui commence par « on peut ». Dans `phrase`, `raison_incertain` et `valeur.texte`, n'emploie jamais « legal », « allowed », « permitted », « authorized », « autorisé », « tu peux la garder » : décris la mesure (« taille minimale 15 pouces »). La citation, elle, reste mot pour mot.
8. Une règle de fermeture ou d'interdiction explicite (« closed to fishing », « no harvest ») s'écrit telle quelle ; `verdict` vaut `interdit` seulement pour elle. Sinon omets `verdict`.
9. Un texte de réciprocité, de tribu ou de parc : note-le dans `textes` avec `lu`, sans en tirer de règle d'État.
10. Vérifie : `python3 -I outils/us/regles/verifier_us.py outils/us/regles/lecture-a/{ETAT}.json` doit afficher OK.
