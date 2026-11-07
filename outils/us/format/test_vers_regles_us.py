"""Tests de vers_regles_us.py. Lancer depuis la racine du dépôt : python3 -I outils/us/format/test_vers_regles_us.py
Les consensus d'essai sont écrits dans un dossier temporaire (jamais dans le dépôt) ; leurs URL sont inventées (exemple.test).
"""
import copy
import hashlib
import importlib.util
import json
import os
import shutil
import tempfile
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))


def charger(nom):
    spec = importlib.util.spec_from_file_location(nom, os.path.join(ICI, nom + ".py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


v = charger("vers_regles_us")
val = charger("valider")

SOURCE = {"url": "https://agence.exemple.test/regs.pdf", "date": "2026-11-07", "edition": "Essai 2026"}


def regle(id_, type_, valeur=None, especes=("Walleye",), du=None, au=None, zone=None, statut="brouillon", **extra):
    p = {"niveau_portee": "zone" if zone else "etat", "etat": "WI"}
    if zone:
        p["zone"] = zone
    r = {"id": id_, "niveau": 2, "portee": p, "especes": list(especes), "type": type_, "du": du, "au": au,
         "valeur": valeur or {}, "phrase": "essai", "source": SOURCE, "citation": f"Citation d'essai {id_}.", "statut": statut,
         "lecture_b": {"id": "b-" + id_, "citation": f"Citation B {id_}."}}
    r.update(extra)
    return r


class Conversion(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.cons = os.path.join(self.tmp, "donnees")
        self.sortie = os.path.join(self.tmp, "regles-us")
        os.makedirs(os.path.join(self.cons, "WI"))
        os.makedirs(self.sortie)
        with open(os.path.join(self.sortie, "index.json"), "w") as f:
            json.dump({"format": 1, "version": "x", "date": "2026-11-01", "etats": {}}, f)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def convertir(self, regles, incertaines=(), **tete):
        d = {"etat": "WI", "fixture": False, "regles": regles, "incertaines": list(incertaines),
             "a_verifier": {"seulement_a": [], "seulement_b": []}}
        d.update(tete)
        with open(os.path.join(self.cons, "WI", "consensus.json"), "w") as f:
            json.dump(d, f)
        return v.ecrire("WI", "2026-11-07", self.sortie, self.cons)

    def test_limites_regroupees_et_statut(self):
        donnees, _ = self.convertir([regle("j", "limite_jour", {"nombre": 3}), regle("p", "limite_possession", {"nombre": 10})])
        self.assertEqual(len(donnees["regles"]), 1)
        r = donnees["regles"][0]
        self.assertEqual(r["limites"], {"prise": 3, "possession": 10})
        self.assertEqual(r["statut"], "double_lecture_confirmee")
        self.assertEqual(r["espece"], "walleye")
        self.assertIn(" / ", r["source"]["citation"])
        self.assertEqual(len(r["constituants"]), 2)

    def test_incertaine_et_a_verifier_jamais_converties(self):
        donnees, journal = self.convertir([regle("t", "taille_min", {"pouces": 15})],
                                          incertaines=[regle("i", "limite_jour", {"nombre": 3}, statut="incertain")])
        self.assertEqual([list(r.get("tailles", {})) for r in donnees["regles"]], [["minimale"]])
        self.assertTrue(any(l.startswith("i :") for l in journal))

    def test_conflit_dans_une_case_retire_les_deux(self):
        donnees, journal = self.convertir([regle("a", "limite_jour", {"nombre": 3}), regle("b", "limite_jour", {"nombre": 5})])
        self.assertEqual(donnees["regles"], [])
        self.assertEqual(sum("retirée" in l for l in journal), 2)

    def test_dates_d_une_limite_non_recopiees_relacher_en_fermeture(self):
        donnees, _ = self.convertir([
            regle("p", "limite_possession", {"nombre": 6}, ["largemouth bass"], "2026-05-23", "2027-02-28", zone="Southern Zone"),
            regle("r", "relacher", {"code": "catch_and_release_only"}, ["largemouth bass"], "03-01", "05-22", zone="Southern Zone")])
        par_famille = {("limites" if "limites" in r else "ouverture"): r for r in donnees["regles"]}
        self.assertNotIn("saison", par_famille["limites"])
        self.assertEqual(par_famille["ouverture"]["fermetures"][0]["type"], "remise_a_eau_seulement")
        self.assertEqual(par_famille["ouverture"]["fermetures"][0]["du"], "03-01")
        self.assertEqual([j["id"] for j in donnees["juridictions"]], ["US-WI/southern-zone"])

    def test_saison_annee_entiere_groupe_et_autre_ignores(self):
        donnees, journal = self.convertir([regle("s", "saison", {}, ["Bluegill"], "01-01", "12-31"),
                                           regle("g", "limite_jour", {"nombre": 25}, ["Crappie"]),
                                           regle("o", "autre", {}, ["Lake sturgeon"])])
        self.assertEqual(donnees["regles"], [])
        self.assertEqual(len(journal), 3)

    def test_zone_avec_parenthese_une_seule_juridiction(self):
        donnees, _ = self.convertir([regle("a", "saison", {}, ["Northern pike"], "05-02", "03-07", zone="Northern Zone"),
                                     regle("b", "limite_jour", {"nombre": 5}, ["Northern pike"], zone="Northern Zone (north of US Hwy 10)")])
        self.assertEqual([j["nom"] for j in donnees["juridictions"]], ["Northern Zone"])
        self.assertEqual({r["portee"] for r in donnees["regles"]}, {"US-WI/northern-zone"})

    def test_citation_jamais_au_dela_de_200(self):
        longue = regle("l", "limite_jour", {"nombre": 3}, citation="x" * 190)
        donnees, _ = self.convertir([longue, regle("p", "limite_possession", {"nombre": 10}, citation="y" * 150)])
        c = donnees["regles"][0]["source"]["citation"]
        self.assertLessEqual(len(c), 200)
        self.assertTrue(c.startswith("x"))
        self.assertIn("…", c)

    def test_fixture_refusee(self):
        with self.assertRaises(ValueError):
            self.convertir([regle("t", "taille_min", {"pouces": 15})], fixture=True)

    def test_sortie_valide_et_index_a_jour(self):
        donnees, _ = self.convertir([regle("t", "taille_min", {"pouces": 15}), regle("e", "engin", {"code": "trois_hamecons"}, [])])
        chemin = os.path.join(self.sortie, "WI.json")
        self.assertEqual(val.valider(chemin), [])
        self.assertEqual(val.valider(os.path.join(self.sortie, "index.json")), [])
        with open(os.path.join(self.sortie, "index.json")) as f:
            idx = json.load(f)
        with open(chemin, "rb") as f:
            self.assertEqual(idx["etats"]["WI"]["sha256"], hashlib.sha256(f.read()).hexdigest())
        self.assertEqual(idx["etats"]["WI"]["regles"], len(donnees["regles"]))


class FichiersDuDepot(unittest.TestCase):
    """Les fichiers générés et livrés passent le validateur, et l'index porte leur somme."""

    def test_wi_mn_valides(self):
        dossier = v.SORTIE
        with open(os.path.join(dossier, "index.json")) as f:
            idx = json.load(f)
        for etat in idx["etats"]:
            self.assertEqual(val.valider(os.path.join(dossier, f"{etat}.json")), [], etat)
        self.assertEqual(val.valider(os.path.join(dossier, "index.json")), [])
        for etat in ("WI", "MN"):
            with open(os.path.join(dossier, f"{etat}.json")) as f:
                d = json.load(f)
            self.assertFalse(d.get("fixture"))
            self.assertTrue(all(r["statut"] == "double_lecture_confirmee" for r in d["regles"]))


if __name__ == "__main__":
    unittest.main()
