"""Tests de consensus.py : normalisation des lieux, granularité, paires de catégories.
Lancer : python -I -m pytest outils/regles   (aucune donnée de dep/ n'est lue)."""
import importlib.util
import os

_spec = importlib.util.spec_from_file_location("consensus", os.path.join(os.path.dirname(os.path.abspath(__file__)), "consensus.py"))
c = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(c)


def regle(type_, lieu=None, especes=(), categorie="toutes", valeur=None, du=None, au=None, **portee):
    return {"type": type_, "especes": list(especes), "categorie": categorie, "du": du, "au": au,
            "valeur": valeur or {}, "portee": dict({"lieu": lieu}, **portee)}


def categorie(lieu, classe="2"):
    return regle("categorie", lieu, valeur={"classe": classe})


# ---- normalisation du lieu ----------------------------------------------------------------------------------

def test_identifiant_sans_accents_ni_mots_vides():
    r = regle("categorie", "Plan d'eau du château de Broglie (Ferrières-Saint-Hilaire), sur la Charentonne")
    assert c.identifiant_lieu(r) == {"chateau", "broglie", "ferrieres", "saint", "hilaire", "charentonne"}


def test_plan_d_eau_en_tete_ou_apres_le_cours_d_eau_donnent_le_meme_identifiant():
    a = categorie("Plan d'eau du château de Broglie (Ferrières-Saint-Hilaire), sur la Charentonne")
    b = categorie("Charentonne (Ferrières-Saint-Hilaire) : plan d'eau du château de Broglie")
    assert c.identifiant_lieu(a) == c.identifiant_lieu(b)
    assert c.confirme(a, b) and c.confirme(b, a)


def test_limites_et_association_ne_comptent_pas():
    r = regle("no_kill", "Eure (Croth) : AAPPMA « La goujonnette », ensemble de la surface, limites : amont : pont de Croth")
    assert c.identifiant_lieu(r) == {"eure", "croth"}


def test_champs_plan_eau_et_cours_eau_entrent_dans_l_identifiant():
    r = regle("categorie", "Plan d'eau du château de Broglie", plan_eau="château de Broglie", cours_eau="Charentonne")
    assert {"chateau", "broglie", "charentonne"} <= c.identifiant_lieu(r)


def test_deux_cours_d_eau_differents_meme_commune_ne_se_confirment_pas():
    a = regle("no_kill", "Eure (Pacy-sur-Eure) : parcours", especes=["2110"])
    b = regle("no_kill", "Iton (Pacy-sur-Eure) : parcours", especes=["2110"])
    assert not c.confirme(a, b)


def test_deux_plans_d_eau_de_communes_differentes_ne_se_confirment_pas():
    a = categorie("Étang de la Noë (Aulnay-sur-Iton), sur l'Iton")
    b = categorie("Plans d'eau de la Noé et de l'Onglais (Acquigny), sur l'Iton")
    assert not c.confirme(a, b)


def test_classe_differente_ne_se_confirme_pas():
    assert not c.confirme(categorie("Lac de Grosley (Grosley-sur-Risle)", "2"), categorie("Lac de Grosley (Grosley-sur-Risle)", "1"))


# ---- granularité --------------------------------------------------------------------------------------------

def test_lieu_fin_confirme_par_lieu_large_mais_pas_l_inverse():
    fin = regle("no_kill", "Seine (Vernon) : parcours", especes=["2110"])
    large = regle("no_kill", "Seine", especes=["2110"])
    assert c.confirme(fin, large)
    assert not c.confirme(large, fin)


def test_liste_de_communes_contient_une_commune():
    fin = regle("no_kill", "Risle (Neaufles-Auvergny) : parcours mouche", especes=["2221"])
    large = regle("no_kill", "Risle (Rugles, Ambenay, Neaufles-Auvergny, La Neuve-Lyre) : totalité du linéaire", especes=["2221"])
    assert c.confirme(fin, large)
    assert not c.confirme(large, fin)


def test_numeros_de_lots():
    r = regle("carpe_nuit", "Seine (Vernon) : AAPPMA « Le Gardon », lots 53 à 57, de la limite des Yvelines")
    assert c.numeros_lieu(r) == {"53", "54", "55", "56", "57"}
    assert c.numeros_lieu(regle("carpe_nuit", "Seine (Poses) : lots 68 et 69")) == {"68", "69"}
    assert c.numeros_lieu(regle("carpe_nuit", "Seine (Vernon) : lot n° 71 A (1 804 m), de la tête")) == {"71"}
    assert c.numeros_lieu(regle("carpe_nuit", "Étangs E1, E2 et E11 (Toutainville)")) == {"e1", "e2", "e11"}
    assert c.numeros_lieu(regle("carpe_nuit", "Étangs de Saint-Ouen n° 1, 2 (Clef-Vallée) et n° 4 (Cailly-sur-Eure)")) == {"1", "2", "4"}


def test_numeros_de_parcelles_ignores():
    r = regle("carpe_nuit", "Eure (Pacy-sur-Eure) : rive droite, parcelles cadastrées AH n° 50, 52a, 53 (longueur 880 m)")
    assert c.numeros_lieu(r) == set()


def test_lot_fin_confirme_par_lots_larges_si_les_numeros_sont_dedans():
    lot = regle("carpe_nuit", "Seine (Vernon) : lot n° 54", especes=["2110"])
    lots = regle("carpe_nuit", "Seine (Vernon) : lots 53 à 57", especes=["2110"])
    autre = regle("carpe_nuit", "Seine (Vernon) : lot n° 60", especes=["2110"])
    assert c.confirme(lot, lots)
    assert not c.confirme(lots, lot)
    assert not c.confirme(autre, lots)


def test_regle_large_couverte_par_tous_ses_morceaux_seulement():
    large = regle("carpe_nuit", "Seine (Vernon) : lots 53 à 55", especes=["2110"])
    morceaux = [regle("carpe_nuit", f"Seine (Vernon) : lot n° {n}") for n in (53, 54, 55)]
    assert c.couverte_par_morceaux(large, morceaux) == morceaux
    assert c.couverte_par_morceaux(large, morceaux[:2]) == []


def test_etang_numerote_distinct_dans_la_meme_commune():
    e2 = regle("carpe_nuit", "Étang E2 (Toutainville)")
    e5 = regle("carpe_nuit", "Étangs E1, E4 et E5 (Toutainville)")
    assert not c.confirme(e2, e5)
    assert c.confirme(regle("carpe_nuit", "Étang E5 (Toutainville)"), e5)


def test_regle_fine_confirmee_par_regle_du_departement_si_valeur_chiffree():
    fine = regle("taille_min", "Risle (Launay)", especes=["2221"], valeur={"cm": 25}, categorie="1")
    large = regle("taille_min", None, especes=["2221"], valeur={"cm": 25}, categorie="toutes")
    assert c.confirme(fine, large)
    assert not c.confirme(large, fine)
    assert not c.confirme(fine, regle("taille_min", None, especes=["2221"], valeur={"cm": 30}))


def test_regle_fine_sans_chiffre_pas_confirmee_par_le_departement():
    fine = regle("interdit", "Risle (Launay)", especes=["2221"], valeur={"texte": "x"})
    large = regle("interdit", None, especes=["2221"], valeur={"texte": "y"})
    assert not c.confirme(fine, large)


# ---- paires « même valeur, catégorie différente » -----------------------------------------------------------

def test_paire_meme_valeur_categorie_differente():
    a = regle("taille_min", None, especes=["2216"], valeur={"cm": 25}, categorie="1")
    b = regle("taille_min", None, especes=["2216"], valeur={"cm": 25}, categorie="toutes")
    assert not c.confirme(a, b)
    assert c.confirme(a, b, categorie=False)
    paires = c.paires_categorie([a], [b])
    assert len(paires) == 1
    assert paires[0]["a"]["categorie"] == "1" and paires[0]["b"]["categorie"] == "toutes"


def test_pas_de_paire_si_la_valeur_differe():
    a = regle("taille_min", None, especes=["2216"], valeur={"cm": 25}, categorie="1")
    b = regle("taille_min", None, especes=["2216"], valeur={"cm": 30}, categorie="toutes")
    assert c.paires_categorie([a], [b]) == []


def test_pas_de_paire_si_meme_categorie():
    a = regle("taille_min", None, especes=["2216"], valeur={"cm": 25}, categorie="2")
    b = regle("taille_min", None, especes=["2216"], valeur={"cm": 25}, categorie="2")
    assert c.confirme(a, b) and c.paires_categorie([a], [b]) == []


def test_paire_de_categorie_inverse_b_vers_a():
    a = regle("quota_jour", None, especes=["2151"], valeur={"nombre": 1}, categorie="toutes")
    b = regle("quota_jour", None, especes=["2151"], valeur={"nombre": 1}, categorie="2")
    assert len(c.paires_categorie([a], [b])) == 1
