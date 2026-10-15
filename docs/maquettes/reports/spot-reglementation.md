# Définir un « spot de pêche » : règles à superposer (France, état au 15/10/2026)

Décision débloquée : comment délimiter un spot pour afficher espèces + règles de façon fiable.
Légende : [à vérifier] = non confirmé sur source primaire. Les sources sont entre parenthèses.

## Résumé en 5 lignes (version simple)
- Un spot n'est pas « un rayon ». Les règles dépendent de ce qu'il y a DANS le rayon : quel cours d'eau, quelle catégorie, quel lot d'association, quelle réserve, mer ou eau douce.
- En eau douce, la règle nationale est un socle. Le préfet de chaque département l'ajuste chaque année, et l'association locale (AAPPMA) ajoute ses parcours.
- En mer, il n'y a pas de carte de pêche. Les règles viennent du Ministère de la Mer (national), de la DIRM / DDTM (façade, département) et d'arrêtés locaux.
- Une ligne invisible sépare les deux mondes dans les estuaires : la limite de salure des eaux (LSE).
- Recommandation : le spot = un point + une zone dessinée, puis l'app interroge des couches géographiques. Un rayon seul donnerait des règles fausses.

## 1. Eau douce

### 1.1 Qui possède le droit de pêche (domaine public / privé)
- Domaine public fluvial (DPF = cours d'eau et canaux appartenant à l'État ou à une collectivité) : le droit de pêche appartient à l'État, qui le loue par lots (cahier des charges, 5 ans) (DDT/DRIEAT : https://www.drieat.ile-de-france.developpement-durable.gouv.fr/IMG/pdf/cdc_fusionne.pdf).
- Cours d'eau non domaniaux : chaque riverain a le droit de pêche jusqu'au milieu du cours d'eau (Code env. L435-4 : https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006176583/2026-06-11). Les riverains le cèdent le plus souvent à une AAPPMA (https://www.federation-peche64.fr/cartes-de-peche).
- Sur le DPF, un membre d'AAPPMA peut pêcher à une seule ligne (2 hameçons simples max) gratuitement, de la rive ou dans l'eau (1re cat.), avec bateau en 2e cat. (Code env. L435-1 et suivants, texte Légifrance : https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006159269). Détail exact des articles [à vérifier].
- Conséquence app : « domaine public ou privé » n'est pas une propriété du département mais du tronçon. Il se lit lot par lot (annuaire cartedepeche.fr, exemple : lots de l'AAPPMA de Schiltigheim, « canal domaine public », « gravière domaine privé » : https://www.cartedepeche.fr/association/2836/124-annuaire-des-associations.htm).

### 1.2 Catégories piscicoles 1 et 2
- 1re catégorie : eaux surtout peuplées de truites (salmonidés). 2e catégorie : toutes les autres (cyprinidés, carnassiers). Le préfet classe chaque cours d'eau, canal et plan d'eau par arrêté (https://www.drieat.ile-de-france.developpement-durable.gouv.fr/encadrement-reglementaire-de-la-peche-en-eau-douce-a13172.html ; base légale L436-5, 10°, via https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006159269).
- Un plan d'eau est classé par le préfet sur demande du propriétaire (R431 à R437, https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006143783/2025-01-26). Un même cours d'eau peut changer de catégorie d'un tronçon à l'autre (exemple : Bruche en 1re et 2e cat. sur une même AAPPMA : https://www.cartedepeche.fr/association/2773/124-annuaire-des-associations.htm).
- Eaux closes et piscicultures sont hors champ (data.gouv, jeu Bas-Rhin : https://www.data.gouv.fr/datasets/lineaire-des-categories-piscicoles-des-cours-deau-et-plan-deau).

### 1.3 Carte de pêche, AAPPMA, réciprocité
- AAPPMA = association locale agréée qui gère les lots. La carte est obligatoire (L436-1) et fait de vous un adhérent d'une AAPPMA (https://www.cartedepeche.fr/184-conditions-generales-adhesion.htm). Sans carte : amende jusqu'à 450 € (https://www.service-public.gouv.fr/particuliers/vosdroits/F2117).
- La carte donne droit : aux lots de son association, aux lots des associations réciprocitaires, et à une seule ligne sur tout le domaine public (https://www.cartedepeche.fr/TPL_CODE/TPL_FAQLISTE/61-renouveler-ma-carte.htm).
- Trois niveaux de réciprocité sur cartedepeche.fr : interdépartementale, entre AAPPMA du département, ou aucune (https://www.cartedepeche.fr/association/2836/124-annuaire-des-associations.htm).
- Ententes : URNE (Nord-Est), EHGO (Grand Ouest), CHI ; carte « interfédérale » valable dans 91 départements (source secondaire : https://peche-assistant.fr/carte-de-peche ; FD64 confirme « CHI, 91 départements » : https://www.federation-peche64.fr/cartes-de-peche). Liste officielle des départements par entente [à vérifier].
- Des lots restent hors réciprocité (exemple : étangs « réservés aux membres », https://www.cartedepeche.fr/association/2773/124-annuaire-des-associations.htm). Les cartes de bateau ou d'option sont parfois en plus (lac du Bourget : https://aappma-aix-les-bains.fr/cartes-de-peche/type-de-cartes).
- Conséquence app : l'app ne peut pas dire « votre carte est valable ici » sans connaître la carte de l'utilisateur ET le lot. Au minimum, afficher le nom de l'AAPPMA du lot et un lien vers sa fiche.

### 1.4 Périodes, heures, tailles, quotas : le socle national
- Ouverture 1re cat. : du 2e samedi de mars au 3e dimanche de septembre ; ombre : du 3e samedi de mai à la même date ; brochet remis à l'eau jusqu'au vendredi avant le dernier samedi d'avril. Le préfet peut prolonger de 1 à 3 semaines en haute montagne (R436-6 : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006838556).
- 2e catégorie : pas de fermeture générale, mais des fermetures par espèce (brochet, sandre, black-bass) fixées par le préfet [à vérifier : R436-7]. Exemple Côtes-d'Armor 2026 : 2e cat. ouverte du 1er janvier au 31 décembre (https://aappmastbrieuc.fr/wp-content/uploads/2026/01/251211_AP-peche_eau_douce_2026.pdf).
- Heures légales : de ½ h avant le lever à ½ h après le coucher du soleil, avec exceptions (truite de mer, carpe de nuit) (R436-5 et suivants : https://www.legifrance.gouv.fr/codes/id/LEGISCTA000006159415).
- Tailles minimales nationales (R436-18) : brochet 50 cm, sandre 40 cm (2e cat.), black-bass 30 cm (2e cat.), truite 23 cm, ombre 30 cm, huchon 70 cm, mulet 20 cm, écrevisses 9 cm (https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006838568).
- Quotas nationaux (R436-21) : 10 salmonidés/jour ; 1re cat. : 2 brochets/jour ; 2e cat. : 3 sandres+brochets+black-bass dont 2 brochets max. Le préfet peut réduire (https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006838571).
- Les préfets durcissent le socle : Côtes-d'Armor 2026 impose brochet 60 cm, sandre 50 cm, black-bass 40 cm en 2e cat. (https://aappmastbrieuc.fr/wp-content/uploads/2026/01/251211_AP-peche_eau_douce_2026.pdf). Donc une taille « nationale » affichée seule peut être fausse.
- Interdiction de pêche à moins de 50 m en aval d'un barrage ou d'une écluse, sauf une seule ligne (R436-71, cité dans https://www.drieat.ile-de-france.developpement-durable.gouv.fr/IMG/pdf/cdc_fusionne.pdf).

### 1.5 Arrêté préfectoral annuel : où, quel format
- Deux textes par département : un arrêté permanent (toutes les dispositions) + un avis annuel (dates d'ouverture/fermeture) (https://www.drieat.ile-de-france.developpement-durable.gouv.fr/encadrement-reglementaire-de-la-peche-en-eau-douce-a13172.html).
- Publication : site de la préfecture / DDT(M), en PDF. Exemples : Essonne (https://www.essonne.gouv.fr/Publications/Arretes/Peche-arretes-prefectoraux), Pas-de-Calais (https://www.pas-de-calais.gouv.fr/Actions-de-l-Etat/Environnement-developpement-durable/Peche). Les fédérations republient souvent un guide PDF (ex. FD64 : https://www.federation-peche64.fr/wp-content/uploads/2017/12/fd64_mememto_2025.pdf).
- Aucun format machine unifié trouvé ; pas de jeu national « arrêtés de pêche » sur data.gouv.fr [à vérifier par une recherche exhaustive].
- Annexes à part : cours d'eau à migrateurs (arrêté migrateurs séparé, Côtes-d'Armor), carpe de nuit (arrêté séparé), réserves temporaires (arrêté sur 5 ans, Nord/Pas-de-Calais), no-kill (arrêté, Nord).

### 1.6 Réserves, interdictions, parcours spéciaux
- Interdictions permanentes et réserves : le préfet fixe l'emplacement, les limites amont/aval et la durée, jusqu'à 5 ans (R436-69 et suivants : https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006176938). Elles sont listées dans les arrêtés, avec limites décrites en texte (exemple : réserve en aval du pont de la RD 281, FD64).
- Carpe de nuit : autorisée seulement sur des parcours listés par arrêté préfectoral, commune par commune (Nord : https://www.thumeries.fr/wp-content/uploads/2023/01/ARRETE-RELATIF-A-LEXERCICE-DE-LA-PECHE-EN-EAU-DOUCE-DANS-LE-NORD-POUR-2023.pdf ; Pas-de-Calais 2026 : https://www.peche62.fr/wp-content/uploads/2016/01/251230-AP-Carpe-de-Nuit-Annexes.pdf ; Eure : https://www.eure.gouv.fr/Actions-de-l-Etat/Environnement/eau-et-nature/Peche/Autorisation-de-peche-a-la-carpe-de-nuit). Base légale : R436-14, 5° (carpe à toute heure en 2e cat., sur période fixée).
- No-kill (remise à l'eau obligatoire, hameçon sans ardillon) : fixé par arrêté préfectoral (Nord) ou par le règlement de l'AAPPMA/du plan d'eau (FD64 ; AAPPMA Brumath : http://aappmabrumath.wifeo.com/exemple-de-page-2.php).
- Règles de plan d'eau ou de lot : périodes de pêche carnassier, gilet obligatoire, distance aux baignades, réservation de poste (AAPPMA Brumath ; Var : https://www.pechevar.fr/1052-peche-de-la-carpe-de-nuit.htm). Ces règles sont dans des pages web ou des PDF, jamais en données ouvertes à ce jour.

### 1.7 Ce qui varie en dessous du département
| Échelle | Exemple | Source |
|---|---|---|
| Tronçon de cours d'eau | catégorie 1 puis 2 sur la même rivière | arrêté de classement (Essonne 2024-DDT-SE-98) |
| Lot de pêche | réciprocité ou non, domaine public ou privé | cartedepeche.fr, fiche AAPPMA |
| Réserve / interdiction | amont-aval de chaque barrage | arrêté préfectoral |
| Plan d'eau | no-kill, carpe de nuit, bateau, horaires | FD / AAPPMA / arrêté municipal (FD64 : « arrêté municipal ») |
| Commune | circulation sur chemin de halage | arrêtés municipaux (Pas-de-Calais carpe de nuit) |
Les arrêtés municipaux n'ont aucune source centrale [à vérifier].

## 2. Mer (pêche de loisir)

### 2.1 Cadre général
- Pas de carte de pêche. Les prises sont destinées à la consommation familiale ; la vente est interdite (https://www.mer.gouv.fr/peche-de-loisir-en-mer).
- Enregistrement obligatoire (nouveau) : depuis le 12/02/2026, les pêcheurs de 16 ans et plus s'enregistrent au moins la veille, via l'appli RecFishing (ou Catchmachine en Méditerranée), pour certaines espèces : bar, lieu jaune, dorade rose, maquereau selon la zone CIEM (zone de gestion européenne 4, 7, 8). Pêcheurs à pied : seulement dorade rose et coryphène. En Méditerranée : tous, sauf pêcheurs à pied. Enregistrement valable 12 mois ; déclaration des captures sous 24 h (https://www.service-public.gouv.fr/particuliers/vosdroits/F2118 ; arrêté du 7 novembre 2025 modifié le 1er avril 2026 : https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053790651).
- Thon rouge : autorisation préalable (demandes du 1er avril au 31 mai 2026) + déclaration de débarquement sous 48 h (https://www.dirm.nord-atlantique-manche-ouest.developpement-durable.gouv.fr/peche-de-loisir-du-thon-rouge-depot-des-demandes-d-a1141.html ; Cerfa : https://www.formulaires.service-public.gouv.fr/gf/cerfa_14938.do). Quota annuel par arrêté.

### 2.2 Tailles minimales et marquage
- Arrêté du 26 octobre 2012 modifié (annexe I tailles, annexe II mesure). Seul son texte fait foi (https://www.legifrance.gouv.fr/loda/id/JORFTEXT000026582115 ; modifs 2024 : https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000049893961 et https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000050853394).
- Valeurs Atlantique/Manche/mer du Nord : bar 42 cm, cabillaud 42 cm, alose 30 cm, barbue 30 cm (https://www.dirm.nord-atlantique-manche-ouest.developpement-durable.gouv.fr/IMG/pdf/taille_minimale_de_captures_des_poissons_crustaces_et_mollusques_06-2026_cle78ad81.pdf). Les tailles diffèrent en Méditerranée (même source).
- S'applique en bateau, en nage/plongée et à pied sur le domaine public maritime et sur la partie salée des fleuves (https://www.dirm.nord-atlantique-manche-ouest.developpement-durable.gouv.fr/peche-de-loisir-taille-minimale-de-capture-et-a288.html).
- Marquage : ablation de la partie inférieure de la nageoire caudale, captures gardées entières jusqu'au débarquement (service-public F2118).

### 2.3 Quotas (exemples)
- Bar, zone CIEM 4 : 3 spécimens/jour/pêcheur du 01/04 au 31/12/2026, pas de filet. Manche : 3 bars/jour (1er janvier au 31 janvier et 1er avril au 31 décembre 2026) (service-public F2118 ; https://www.dirm.nord-atlantique-manche-ouest.developpement-durable.gouv.fr/peche-de-loisir-du-bar-du-lieu-jaune-et-du-a585.html). Golfe de Gascogne : règle exacte [à vérifier].
- Maquereau, mer du Nord : 10/jour (service-public F2118).
- Cabillaud : listé parmi les espèces interdites dans le Calvados, lecture de la plaquette à confirmer (plaquette DDTM : https://www.versurmer.fr/ver-sur-mer/fichiers/260630_plaquette_peche_loisir.pdf). Règle générale par zone [à vérifier].
- Les règles changent chaque année (règlements UE de possibilités de pêche), donc elles doivent porter une date de validité.

### 2.4 Par façade, par département
- La DIRM (une par façade) publie fiches et arrêtés. Les DDTM/DML publient des arrêtés par département : filets, pêche à pied, secteurs (Calvados : engins limités à 12 hameçons par navire, tailles supérieures au minimum national pour certaines espèces ; salicorne cueillie du 10/06 au 20/08, 1 kg/jour : plaquette DDTM Calvados ci-dessus ; Finistère : https://www.finistere.gouv.fr/Actions-de-l-Etat/Mer-littoral-et-securite-maritime/Peche-de-loisir/Reglementation-departementale/Tailles-minimales-de-capture ; Seine-Maritime/Eure : arrêté DIRM Manche Est-mer du Nord n°69/2016, filet fixe interdit depuis la LSE de la Seine : https://www.dirm.memn.developpement-durable.gouv.fr/IMG/pdf/arrete_no069-2016.pdf).
- Zones nommées avec liste de pêcheurs autorisés : île de Porquerolles (Var), arrêté DIRM Méditerranée 364/2026 (https://www.dirm.mediterranee.developpement-durable.gouv.fr/IMG/pdf/364_2026.pdf).
- Engins dormants (casiers, filets) : marquage de l'engin au nom du pêcheur (arrêté du 7 novembre 2025 modifié).
- Pêche sous-marine : bouée de signalisation obligatoire (R921-91 : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000029978121).
- Interdits de principe : ports, chenaux, aires marines protégées, parcs nationaux : règles propres à chaque site [à vérifier ; aucune source primaire trouvée dans cette session pour la liste générale].
- Pêche à pied : classement sanitaire des zones coquillières (ARS) et arrêtés préfectoraux [à vérifier]. Les espèces et tailles de l'arrêté de 2012 s'appliquent aussi à pied (DIRM, voir 2.2).

### 2.5 Limite de salure des eaux et estuaires
- LSE : frontière entre pêche maritime (Code rural, livre IX) et pêche fluviale (Code env.). Fixée par décret, tableau annexé à D911-2 du Code rural (https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000029977459 ; https://www.eaufrance.fr/glossaire/limite-de-salure-des-eaux).
- Aval de la LSE : règles maritimes (tailles de l'arrêté de 2012, y compris sur la « partie des fleuves où les eaux sont salées »). Amont : Code de l'environnement, carte de pêche (arrêté Côtes-d'Armor cite D911-2 : https://aappmastbrieuc.fr/wp-content/uploads/2026/01/251211_AP-peche_eau_douce_2026.pdf).
- Limite transversale de la mer (LTM) : autre ligne, distingue domaine public maritime et domaine public fluvial (https://www.eaufrance.fr/glossaire/limite-transversale-de-la-mer). Autorité du préfet maritime en aval de la LTM (https://cnig.gouv.fr/IMG/documents_wordpress/2021/10/LIMLATPREF_reunion_gimel_20210610.pdf). LTM et LSE ne coïncident pas toujours : superposer les deux.
- Migrateurs (saumon, truite de mer, anguille, alose, lamproie) : règles propres, souvent interdites en estuaire (Calvados, plaquette ci-dessus) ; en eau douce, arrêté migrateurs annuel (Côtes-d'Armor).

## 3. Ce qui engage l'éditeur de l'app
Aucune décision de justice sur une app de pêche trouvée [à vérifier avec un avocat]. Ce qui est sourcé :
- Responsabilité civile : « tout fait quelconque de l'homme qui cause à autrui un dommage oblige celui par la faute duquel il est arrivé à le réparer » (Code civil 1240 : https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006070721/LEGISCTA000032021486/2025-10-01). Une règle fausse affichée peut donc être une faute. Une amende pour taille ou quota non respecté est supportée par le pêcheur (contraventions de 4e classe pour tailles, quotas, réserves : R436-3x et R436-7x dans https://www.legifrance.gouv.fr/codes/id/LEGISCTA000006159415).
- Données publiques sous Licence Ouverte 2.0 : réutilisation commerciale permise, avec obligation de citer la source (nom du producteur) et la date de mise à jour ; la mention ne doit pas laisser croire à un caractère officiel ; le producteur ne garantit pas l'absence d'erreurs ; le réutilisateur est seul responsable ; la réutilisation ne doit pas induire en erreur sur le contenu, la source, la date (https://www.data.gouv.fr/pages/legal/licences/etalab-2.0).
- Les administrations elles-mêmes écrivent « seul le texte de l'arrêté fait foi » (DIRM : liens ci-dessus).
- Bonnes pratiques proposées (mon avis, non sourcé) : mention « indicatif, vérifiez l'arrêté en vigueur » + lien vers la source + date de mise à jour sur chaque règle ; formulations à éviter : « autorisé », « garanti », « vous pouvez pêcher ici » ; préférer « selon l'arrêté du [date], X est fixé à Y » ; afficher « règle non disponible pour ce lieu » plutôt que deviner ; ne jamais fusionner le socle national quand un arrêté local existe. Conditions générales (CGU) à faire relire par un juriste.

## 4. Conclusion : couches par type de spot

### 4.1 Couches à superposer
| Type de spot | Couches de règles |
|---|---|
| Rivière 1re cat. | classement piscicole du tronçon ; lot AAPPMA + domaine public/privé ; réserves et interdictions ; arrêté préfectoral annuel (ouverture, tailles, quotas) ; migrateurs ; no-kill / parcours ; socle R436 |
| Rivière 2e cat. | idem + carpe de nuit, brochet/sandre (fermetures par espèce) ; DPF ou non |
| Plan d'eau | classement du plan d'eau ; propriétaire / AAPPMA ; règlement du lot (no-kill, bateau, nuit) ; arrêtés municipaux ; eaux closes hors champ |
| Canal | domaine public (cahier des charges État, lots) ; 50 m en aval d'écluse ; chemins de halage (arrêtés municipaux) ; carpe de nuit |
| Estuaire | position par rapport à LSE et LTM ; eau douce amont / maritime aval ; migrateurs ; arrêtés DIRM/DDTM sur filets |
| Mer | façade / zone CIEM ; arrêté 2012 tailles ; quotas annuels ; enregistrement RecFishing ; thon rouge ; aires marines protégées ; zones interdites ; pêche à pied (sanitaire) ; arrêtés locaux |

### 4.2 Ce qui existe en données machine, ce qui n'est qu'en PDF
| Couche | État | Source |
|---|---|---|
| Cours d'eau (géométrie) | OUVERT : BD Topage 2023, Licence Ouverte | https://www.data.gouv.fr/datasets/cours-deau-metropole-2023-bd-topage-r |
| Catégorie piscicole | PARTIEL : jeux par département (Ardennes, Bas-Rhin, Isère…) en shapefile/WMS/WFS ; pas de jeu national [à vérifier] ; certains anciens (Ardennes : 2017) | https://www.data.gouv.fr/datasets/categorie-piscicole-des-cours-deau-lineaire |
| Limite transversale de la mer | OUVERT (Shom, Licence Ouverte) | https://www.data.gouv.fr/datasets/limite-transversale-de-la-mer-1/community-resources |
| Limite de salure des eaux | Shom publie des fiches PDF (ex. Rance) ; jeu géographique national [à vérifier] | https://services.data.shom.fr/static/imagettes/LIMAR/LSE_RANCE.pdf |
| Limites maritimes / pêche | OUVERT (Shom) : mer territoriale, ZEE, 3/6 milles | https://www.data.gouv.fr/datasets/delimitations-maritimes |
| Espaces protégés (terre) | OUVERT : INPN | https://www.data.gouv.fr/datasets/inpn-donnees-du-programme-espaces-proteges |
| Aires marines protégées | portail OFB/Géolittoral [à vérifier le jeu exact] | https://ofb.gouv.fr/donnees-systemes-information-et-valorisation |
| Lots AAPPMA, réciprocité | SITE WEB seulement (cartedepeche.fr), cartes PDF par association ; pas d'API trouvée | https://www.cartedepeche.fr/association/2790/124-annuaire-des-associations.htm |
| Arrêtés préfectoraux (dates, tailles, quotas) | PDF seulement | préfectures (liens §1.5) |
| Réserves, no-kill, carpe de nuit | PDF seulement | arrêtés + guides FD |
| Tailles minimales mer | texte Légifrance + fiches PDF DIRM ; saisie à faire à la main | https://www.legifrance.gouv.fr/loda/id/JORFTEXT000026582115 |
| Quotas bar etc. | pages web (service-public, DIRM), à ressaisir chaque année | https://www.service-public.gouv.fr/particuliers/vosdroits/F2118 |
| Zones conchylicoles | quelques jeux locaux (ex. Manche, 2022) | https://www.data.gouv.fr/datasets/zones-conchylicoles |

### 4.3 Définition de spot recommandée
1. Un spot = un point choisi sur la carte + un tronçon (cours d'eau) ou un polygone (plan d'eau, côte), accroché à des objets officiels (id de cours d'eau BD Topage, département, lot).
2. Le rayon sert seulement à chercher les objets proches. L'app liste les règles de chaque objet touché et signale « plusieurs règles possibles » quand le rayon coupe une frontière (catégorie, LSE, réserve, département).
3. Pour un spot en bord d'estuaire : exiger de l'utilisateur de choisir « amont » ou « aval » de la LSE, ou calculer avec la couche (si elle existe).
4. Premier périmètre fiable : couche nationale (socle R436, arrêté 2012) + 1 à 3 départements saisis à la main avec date de l'arrêté. Étendre ensuite département par département.
5. Question ouverte pour vous (design/périmètre) : un abonnement vendu « par spot » promet une fiabilité de règles que, hors départements saisis, l'app ne peut pas tenir. Option à décider avec vous, ma recommandation : limiter la promesse à une liste de départements couverts.
