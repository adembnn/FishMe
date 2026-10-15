"""Tests de v1_vers_v2.py : python3 -I outils/regles/test_v1_vers_v2.py (ou pytest)."""
import collections
import importlib.util
import os

_spec = importlib.util.spec_from_file_location("v1_vers_v2", os.path.join(os.path.dirname(os.path.abspath(__file__)), "v1_vers_v2.py"))
c = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(c)

BASE = {"categorie": "toutes", "portee": {"niveau": "departement", "code": "87", "lieu": None}, "du": None, "au": None,
        "phrase": "p", "source": {"texte": "t"}, "citation": "c", "statut": "brouillon", "expire_le": None, "remplace": None}


def regle(id_, type_, valeur, **autres):
    return {**BASE, "id": id_, "type": type_, "especes": autres.pop("especes", []), "valeur": valeur, **autres}


def un(r):
    m = collections.Counter()
    return c.convertir_regle(r, m), m


def test_ouverture_formule_et_texte():
    r = regle("87-ouv-generale-1e", "ouverture", {"regle": "du 14 mars au 20 septembre 2026 inclus",
              "periodes": [{"du": "2026-03-14", "au": "2026-09-20"}], "note": "identique au socle (R436-6)"},
              du="2026-03-14", au="2026-09-20")
    s, _ = un(r)
    assert s["valeur"] == {"formule": "du 14 mars au 20 septembre 2026 inclus", "texte": "note : identique au socle (R436-6)"}
    assert s["du"] == "2026-03-14" and s["id"] == r["id"]


def test_quota_total_devient_nombre():
    s, _ = un(regle("87-bro-quota", "quota_jour", {"total": 2, "pour": "brochets"}, especes=["2151"]))
    assert s["valeur"] == {"nombre": 2, "texte": "pour : brochets"}


def test_fenetre_devient_fenetre_capture():
    s, _ = un(regle("01-bro-fenetre-priay", "taille_min", {"cm": 60, "fenetre_cm": [60, 80], "note": "expérimentation"}, especes=["2151"]))
    assert s["type"] == "fenetre_capture" and s["valeur"]["min_cm"] == 60 and s["valeur"]["max_cm"] == 80
    assert "note : expérimentation" in s["valeur"]["texte"]


def test_mode_peche_cles_v2_et_texte():
    s, _ = un(regle("87-mode-lignes-1e", "mode_peche", {"lignes_max": 1, "hamecons_max": 2, "mouches_artificielles_max": 3, "visee": "AAPPMA"}))
    assert s["valeur"] == {"lignes_max": 1, "hamecons_max": 2, "mouches_max": 3, "texte": "visee : AAPPMA"}


def test_categorie_et_reserve():
    s, _ = un(regle("87-cat-vienne-2e", "categorie", {"categorie": 2}))
    assert s["valeur"] == {"classe": "2"}
    s, _ = un(regle("87-res", "reserve", {"interdit": "toute pêche dans les passes", "distance_m": 50}))
    assert s["valeur"] == {"texte": "interdit : toute pêche dans les passes ; distance m : 50"} or s["valeur"]["texte"].startswith("toute pêche")


def test_especes_sans_supposition():
    assert c.espece("Anguille européenne (jaune)") == "anguille-jaune"
    assert c.espece("Écrevisse de Californie (Pacifastacus leniusculus)") == "ecrevisse-californie"
    assert c.espece("Grenouilles autres que la verte") == "grenouilles-autres"
    assert c.espece("2151") == "2151"
    assert c.espece("Écrevisse américaine (Pacifastacus leniusculus, Faxonius limosus, Procambarus clarkii)").startswith("autre:")
    assert c.espece("Alose").startswith("autre:")


def test_non_traduisible_ecarte_et_compte():
    m = collections.Counter()
    res = [c.convertir_regle(r, m) for r in [
        regle("a", "taille_min", {"brochet_cm": 60, "sandre_cm": 60}),
        regle("b", "quota_jour", {"kg": 2}),
        regle("c", "ouverture", {"candidats": [{"fin": "2026-09-20"}, {"fin": "2026-12-31"}]}),
        regle("d", "quota_jour", {"total": 3}, citation="x" * 401),
        regle("e", "quota_jour", {"total": 3}),
    ]]
    assert [x is None for x in res] == [True, True, True, True, False]
    assert sum(m.values()) == 4


def test_convertir_fichier():
    d = {"version": 0, "departement": "87", "note": "n", "genere_le": "2026-10-15", "a_saisir": [],
         "textes": [{"titre": "T", "url": "u", "signe_le": None, "lu": "partie", "ocr": True, "remarque": "r"}],
         "regles": [regle("e", "quota_jour", {"total": 3}), regle("f", "taille_min", {"cm": None})]}
    out, avant, motifs = c.convertir(d)
    assert out["version"] == 2 and avant == 2 and len(out["regles"]) == 1 and sum(motifs.values()) == 1
    assert set(out["textes"][0]) == {"titre", "url", "signe_le", "lu"}
    assert out["regles"][0]["portee"]["plan_eau"] is None


if __name__ == "__main__":
    for nom, f in list(globals().items()):
        if nom.startswith("test_"):
            f()
    print("OK")
