# Consigne : extraire les règles de pêche en eau douce d'un département (saison 2026)

Le « dossier des règles » est `outils/regles/` sur un ordinateur (variable `REGLES_DIR` si les lectures sont ailleurs), `/mnt/project-files/build/regles/` dans le cloud. Les chemins ci-dessous en partent.

Décision débloquée : quelles règles de ce département l'app peut afficher, ligne par ligne, avec leur source. Adem veut toutes les règles de France, à la granularité la plus fine (département, cours d'eau, tronçon, parcours), pour toutes les espèces, et aucune valeur supposée. Deux lecteurs lisent chaque département sans se voir ; `consensus.py` garde les règles où ils disent la même chose sur le fond. Pour qu'il puisse comparer, suis la forme ci-dessous à la lettre. Version 2, après les pilotes 01, 87 et 44 ; corrigée après le pilote de l'Eure (27) : lieu structuré et granularité.

## Ce que tu lis, dans cet ordre de force juridique
1. Le Code de l'environnement (R436-6 à R436-23, R436-70 à R436-74) : le socle national, lu à part (lecture `FR`). N'écris pas une règle identique au Code. Écris toute règle qui le précise, le durcit, l'assouplit ou le situe sur un lieu.
2. L'arrêté préfectoral permanent signé en vigueur en 2026 (il fait foi), puis l'arrêté ou l'avis annuel 2026. Certains départements n'ont qu'un arrêté annuel : alors `expire_le` vaut 2026-12-31 partout.
3. Les arrêtés de tronçon et de lac : classement en catégories, réserves, carpe de nuit, no-kill ou graciation, fenêtres de capture, interdictions de consommation (PCB, mercure).
4. Le guide de la fédération : pour trouver les textes, jamais comme seule source d'une règle `brouillon`.
Un texte signé l'emporte sur un avis, un avis sur la fédération. Deux textes signés ou avis qui se contredisent : écris une règle par valeur, chacune avec sa source, `statut` `incertain`, et dis dans le rapport lequel devrait primer.

## Où trouver les textes
**Sur un ordinateur (la voie choisie par Adem le 15 oct.)** : `curl` marche. Pour chaque texte signé trouvé (préfecture, recueil des actes administratifs, DDT, ou copie du même PDF chez la fédération), télécharge le PDF dans `corpus/<code>/`, et note dans `corpus/<code>/manifeste.json` son titre, son URL, sa date de signature, la date du téléchargement et son empreinte SHA-256. Extrais le texte : la couche texte du PDF, sinon une reconnaissance de caractères (OCR) en français ; garde le texte à côté du PDF (`.txt`). Cite depuis ce texte, au mot près. Un outil à installer se demande à Adem avant.
**Dans le cloud (leçons des pilotes)** :
- `curl` vers l'État et les fédérations est refusé : n'essaie pas. WebFetch est refusé par certains sites de préfecture (robots).
- Le même PDF signé est souvent hébergé par la fédération ou une AAPPMA (même nom de fichier) : cherche « arrêté pêche 2026 <département> pdf », le site de la fédération (rubrique réglementation ou arrêtés), la DDT, le recueil des actes administratifs (RAA), les copies Pappers ou Doctrine des RAA.
- WebFetch résume avec un petit modèle et ne rend que des extraits de 125 caractères environ. Demande-lui l'article précis et la phrase avec le chiffre ; pour un tableau, demande ligne par ligne.
- `mcp__Parallel_Search__web_fetch` avec `full_content: true` lit les scans quand il répond. S'il dit « Too Many Requests », réessaie une fois après les autres lectures, puis passe.
**Partout** :
- Un scan illisible par tous les outils : titre seul dans `textes`, et pas de règle tirée de lui.
- Le Code de l'environnement au mot près : une copie GitHub se lit par curl, par exemple `curl -sS "https://raw.githubusercontent.com/francois76/legifrance/HEAD/code_de_l%27environnement/Partie%20r%C3%A9glementaire/Livre%20IV/Titre%20III/Chapitre%20VI/Section%201/Article%20R436-19.md"` (date de copie inconnue).

## Le fichier que tu écris
Le chemin que te donne ta demande (`dep/<code>.json` ou `dep-b/<code>.json`), rien d'autre. Forme :
```json
{"version": 2, "departement": "<code>", "genere_le": "2026-10-15",
 "textes": [{"titre": "...", "url": "...", "signe_le": "AAAA-MM-JJ ou null", "lu": "entier | partie | titre seul"}],
 "regles": [{"id": "<code>-<espece>-<type>-<lieu court>", "type": "...", "especes": ["..."], "categorie": "1 | 2 | toutes",
   "portee": {"niveau": "departement | cours_eau | troncon | plan_eau", "code": "<code>", "lieu": "... ou null",
     "plan_eau": "nom du plan d'eau ou null", "cours_eau": "nom du cours d'eau ou null"},
   "du": "AAAA-MM-JJ ou null", "au": "AAAA-MM-JJ ou null", "valeur": {},
   "phrase": "la règle en une phrase simple pour un pêcheur",
   "source": {"texte": "nom exact du texte et article", "url": "...", "lu_le": "2026-10-15", "version": "date de signature"},
   "citation": "extrait exact contenant le chiffre ou la date décisive, 200 caractères au plus, ou null",
   "statut": "brouillon | incertain", "expire_le": "AAAA-MM-JJ ou null", "remplace": "id nat-* modifié ou null"}]}
```
Règles de forme, chacune vient d'un écart entre deux lecteurs pilotes :
- **Granularité : une règle par espèce et par disposition.** Jamais de regroupement de plusieurs espèces, de plusieurs modes de pêche ni de plusieurs lieux numérotés dans une règle. Une disposition = une règle : la remise à l'eau du brochet, la remise à l'eau de la carpe, les techniques autorisées sur un parcours, la carpe de nuit sur un lot, l'interdiction des vifs, chacune a sa règle, même quand le texte les écrit dans la même phrase ou la même ligne de tableau. Un parcours no-kill avec trois espèces donne trois règles `no_kill` plus, si le texte limite les techniques, une règle `mode_peche` du même lieu. Une carpe de nuit en 5 lots (« lots 53 à 57 ») donne 5 règles (« lot n° 53 » à « lot n° 57 »), pas une. Une catégorie de 13 plans d'eau donne 13 règles `categorie`. Les deux lecteurs découpent pareil : en cas de doute, découpe plus fin, `consensus.py` sait confirmer une règle large par ses morceaux, pas l'inverse.
- **Une règle par espèce.** Jamais deux espèces dans une règle, sauf un quota commun (« 3 carnassiers dont 2 brochets ») : alors `especes` liste le groupe et `valeur.nombre` le total, et une deuxième règle donne le sous-quota de l'espèce.
- **Espèces** : le code Sandre pour les 14 de la collection (brochet 2151, sandre 2195, perche 2193, black-bass 2053, silure 2238, truite fario 2221, truite arc-en-ciel 2216, carpe 2110, gardon 2133, brème 2086, chevesne 31041, tanche 2137, barbeau 2096, ombre 2247). Sinon un de ces noms, tel quel : anguille, anguille-jaune, anguille-argentee, anguille-civelle, truite, truite-de-mer, truite-de-lac, saumon-atlantique, omble-fontaine, omble-chevalier, cristivomer, huchon, coregone, grande-alose, alose-feinte, lamproie-marine, lamproie-fluviatile, mulet, goujon, salmonides, ecrevisse, ecrevisse-pattes-rouges, ecrevisse-torrents, ecrevisse-pattes-blanches, ecrevisse-pattes-greles, ecrevisse-americaine, ecrevisse-californie, ecrevisse-louisiane, grenouille-verte, grenouille-rousse, grenouilles-autres, perche-soleil, poisson-chat, ablette, rotengle, vandoise, hotu, lote, carassin, aspe. Une autre espèce : `autre:<nom français>`. Liste vide seulement pour une règle qui vise toutes les espèces (réserve, no-kill, carpe de nuit, catégorie, mode de pêche général, interdit général, horaire).
- **Lieu** : `portee.lieu` est une phrase d'une ligne, et `portee.plan_eau` et `portee.cours_eau` donnent les noms seuls. Le nom du plan d'eau est toujours en tête de `lieu` quand la règle vise un plan d'eau (étang, lac, ballastière, base de loisirs, plan d'eau), sans article ; sinon le nom du cours d'eau. Puis les communes entre parenthèses, puis deux-points et les limites telles qu'écrites. Si le texte donne les deux (« la Charentonne : plan d'eau du château de Broglie »), remplis les deux champs et mets le plan d'eau en tête de `lieu` : `plan_eau` = `château de Broglie`, `cours_eau` = `Charentonne`, `lieu` = `Plan d'eau du château de Broglie (Ferrières-Saint-Hilaire), sur la Charentonne`. Si le texte ne donne que l'un des deux, l'autre vaut `null` : n'invente jamais le cours d'eau d'un plan d'eau. Exemple de tronçon : `lieu` = `Valserine (Bellegarde-sur-Valserine, Lancrans) : de 155 m en amont du barrage Métral à l'aval de la centrale Métral`, `cours_eau` = `Valserine`, `plan_eau` = `null`. Un lot ou un étang numéroté écrit son numéro dans `lieu` (`lot n° 53`, `étang E2`) : `consensus.py` s'en sert pour distinguer deux étangs d'une même commune. Une ligne de tableau = une règle. `null` partout pour tout le département. Un nom écrit pareil par les deux lecteurs (même orthographe du nom propre) se confirme ; une commune seule ne suffit pas.
- **Catégorie** : celle que le texte donne à la règle ; `toutes` si le texte ne distingue pas.
- **Dates** : `du` et `au` toujours en dates 2026 calculées. Deux périodes = deux règles. Une formule du texte va dans `valeur.formule`. Dates de 2026 : dernier dimanche de janvier 25/01 ; 2e samedi de mars 14/03 ; dernier vendredi d'avril 24/04 ; dernier samedi d'avril 25/04 ; 1er samedi de mai 02/05 ; dernier samedi de mai 30/05 ; 3e dimanche de septembre 20/09 ; dernier dimanche de septembre 27/09 ; 2e dimanche d'octobre 11/10. Une règle valable toute l'année : `du` et `au` à `null`.
- **Valeur** : les chiffres en nombres, sous ces clés seulement, et le reste en texte sous `texte`.
  - `ouverture` : `{"formule": "..."}` (période ouverte ; une fermeture s'écrit comme les périodes ouvertes qui restent)
  - `taille_min` : `{"cm": 60}` ; `fenetre_capture` : `{"min_cm": 60, "max_cm": 80}`
  - `quota_jour` : `{"nombre": 3}` ; `mode_peche` : `{"lignes_max": 2, "hamecons_max": 3, "mouches_max": 3, "maille_mm_min": 27, "texte": "..."}` (les clés utiles seulement)
  - `interdit`, `reserve`, `no_kill`, `carpe_nuit`, `consommation`, `horaire`, `remise_eau`, `transport_vivant`, `limite_eau_douce`, `autre` : `{"texte": "..."}`
  - `categorie` : `{"classe": "1"}` ou `{"classe": "2"}`
- **Statut** : `brouillon` si la règle est lue dans un texte signé (arrêté ou avis) et que la citation contient le chiffre ou la date décisive. Sinon `incertain` (fédération seule, scan illisible, contradiction, citation absente). Jamais de valeur devinée : une règle qu'aucun texte ne donne n'existe pas.
- **Fin** : `expire_le` 2026-12-31 pour un arrêté annuel ou un avis 2026, la date écrite pour un arrêté qui en a une, sinon `null`.

## Vérifie avant de finir
`python3 -I outils/regles/valider.py <ton fichier>` (dans le cloud : `python3 -I /mnt/project-files/build/regles/valider.py <ton fichier>`) doit afficher `OK`. Corrige chaque ligne qu'il signale.

## Le rapport que tu écris
Le chemin que te donne ta demande, 50 lignes au plus, première ligne « Décision débloquée : … ». Contenu : les textes trouvés (titre, date de signature, URL, lu en entier ou non), le nombre de règles par type et par statut, les contradictions et lequel devrait primer, ce qui manque, les 3 règles les plus risquées. Français simple, sans tiret cadratin ni demi-cadratin.

## Limites
Environ 35 minutes : passé ce temps, écris ce que tu as, avec ce qui manque dans le rapport. N'installe rien. N'écris nulle part ailleurs que tes deux fichiers. Ne lis pas l'autre lecture du même département.
