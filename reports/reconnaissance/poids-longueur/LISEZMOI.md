# Poids estimé d'après la longueur (W = a · L^b)

Fichier : `poids_longueur.csv` (60 lignes = toutes les classes sauf `pas-un-poisson` et `autre-poisson`). W en grammes, L = longueur totale (TL) en cm. Poids = a × L^b.

## Statut de chaque ligne (colonne `statut`)
- `source` (27) : a et b lus dans un article publié, cité en entier (colonnes `citation`, `doi_ou_url`).
- `proxy` (18) : aucune valeur trouvée ; on prend les coefficients d'une espèce de forme proche (indiqué dans `remarque`). Confiance faible : à afficher comme « estimation ».
- `lacune` (15) : rien de fiable, pas de coefficients. L'app doit proposer « poids non estimable » : poisson-chat, gambusie, loche franche, loche d'étang, épinoche, flet, mulet, grande alose, alose feinte, 3 lamproies, esturgeon, apron, gobie.
- Groupes : corégones = Coregonus lavaretus (proxy truite) ; mulet = mulet porc, gobies = gobie à taches noires (tous deux en lacune) ; goujons = Gobio gobio ; vairons = Phoxinus phoxinus (proxy).

## Méthode
Lecture directe des articles en accès libre (pas FishBase, interdit). Tableaux utilisés :
1. Irz et al. 2022, KMAE 423:25, tableau 4 (base ASPE de l'OFB, pêches électriques en France) : truite, perche, brochet, barbeau, chevesne, gardon, vandoise, hotu, perche soleil, chabot. Seule source française trouvée. Limites : a donné avec 3 décimales seulement (colonne `incertitude_a_arrondi_pct`), gamme de tailles non publiée.
2. Simon et al. 2023, Acta Ichthyol. Piscat. 53 (Elbe, Allemagne), lignes « Total year » : brème, bordelière, ablette, rotengle, ide, aspe, anguille, lotte, grémille, sandre, goujon, loche de rivière.
3. Isolés : tanche (lac Trasimeno, Italie), black-bass (lac Trasimeno, résumé seulement), silure (Turquie, Alp et al. 2011), carpe (Turquie, résumé seulement), pseudorasbora (Tibre, Italie).
Toutes les longueurs sont des TL, aucune conversion faite.

## Écart avec la demande
- L'article de Verreycken et al. 2011 s'intitule en réalité « 40 freshwater fish species from two decades of monitoring in Flanders » (et non 90 espèces), doi 10.1111/j.1439-0426.2011.01815.x. Wiley bloque l'accès (403) et seul le résumé est lisible : **non utilisé**, aucune valeur copiée.
- Pas de source trouvée en accès libre pour : carpe en Europe de l'Ouest, truite arc-en-ciel, ombles, saumon adulte, ombre, huchon, corégones, carassins, poisson-chat. HAL, Zenodo et le reste n'ont rien donné de lisible pour ces espèces en temps imparti.

## Contrôles de plausibilité (colonnes `L_test_cm`, `W_test_g`, `plausibilite`)
Fourchettes de bon sens à partir de tailles usuelles de pêche, pas des mesures. 
- Brochet 80 cm : 3,4 kg (attendu 4-5 kg). **Sous-estime probablement de 10 à 30 %** pour un brochet gras : les ajustements publiés viennent de poissons surtout petits et b < 3. Perche 30 cm = 339 g, carpe 60 cm = 3,4 kg : conformes.
- « limite » (5 à 15 % sous la fourchette) : brème 40 cm, chevesne 40 cm, hotu, ablette, aspe, goujon.
- Sandre : a = 0,002 arrondi, jusqu'à ±25 % d'erreur sur a. Anguille : a = 0,0007 arrondi, erreur possible jusqu'à ±70 % sur a (poids à prendre avec prudence ; 70 cm = 583 g reste plausible).
- Valeurs suspectes : chabot (r² 0,82, b 2,48), pseudorasbora (b 2,67), loche de rivière (b 3,52), carpe (source turque, faible confiance), proxies. Ablette de Irz (b 2,46) rejetée au profit de l'Elbe.
- Silure : 150 cm = 24,5 kg (coherent), mais coefficients turcs, aucune donnee francaise lue. Extrapoler au-delà de L_max (colonne quand connue) est risqué.

## Longueurs néerlandaises (`nl_*`, source `/root/fishdata/affine_longueurs.csv`)
7 482 mesures, 28 classes ; 0 mm retiré (valeur vide) avant calcul. Médiane et percentile 95 en cm, par classe. Absentes du fichier : classes sans photo. À noter : carpe commune a un maximum de 388 cm, **erreur de saisie probable** (3 880 mm), à ignorer ; le p95 (87 cm) reste fiable. Le fichier compte aussi une classe `autre-poisson-vimbe` (n=71, médiane 23 cm, p95 39 cm) hors tableau. Un échantillon de 36 à 70 poissons (bouvière, vandoise) donne un p95 peu stable.

## Limites
Poids estimé = moyenne de la population ; un poisson individuel peut s'en écarter de ±15 %. Ne pas afficher de poids avec plus de deux chiffres significatifs.
