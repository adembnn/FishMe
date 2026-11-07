"""Tests de valider.py : python3 test_valider.py."""
import copy
import json
import os
import tempfile
import unittest

import valider

ICI = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(ICI, "fixtures", "WI-FIXTURE.json")


def base():
    with open(FIXTURE, encoding="utf-8") as f:
        return json.load(f)


class TestValider(unittest.TestCase):
    def erreurs(self, d, nom="WI.json", fixture=True):
        with tempfile.TemporaryDirectory() as t:
            chemin = os.path.join(t, nom)
            with open(chemin, "w", encoding="utf-8") as f:
                json.dump(d, f)
            return valider.valider(chemin, fixture)

    def test_fixture_valide(self):
        self.assertEqual(valider.valider(FIXTURE, True), [])

    def test_fixture_refusee_hors_tests(self):
        self.assertTrue(any("FIXTURE" in m for m in valider.valider(FIXTURE, False)))

    def test_source_http(self):
        d = base()
        d["regles"][0]["source"]["url"] = "http://exemple.test/x"
        self.assertTrue(any("non https" in m for m in self.erreurs(d)))

    def test_citation_trop_longue(self):
        d = base()
        d["regles"][0]["source"]["citation"] = "a" * 201
        self.assertTrue(any("201 caractères" in m for m in self.erreurs(d)))
        d["regles"][0]["source"]["citation"] = "a" * 200
        self.assertEqual(self.erreurs(d), [])

    def test_statut_manquant(self):
        d = base()
        del d["regles"][0]["statut"]
        self.assertTrue(any("statut" in m for m in self.erreurs(d)))

    def test_date_impossible(self):
        d = base()
        d["regles"][0]["source"]["date"] = "2026-02-30"
        self.assertTrue(any("source.date" in m for m in self.erreurs(d)))

    def test_portee_inconnue_et_regle_vide(self):
        d = base()
        d["regles"][0]["portee"] = "US-WI/fantome"
        self.assertTrue(any("absente des juridictions" in m for m in self.erreurs(d)))
        d = base()
        d["regles"][0] = {k: v for k, v in d["regles"][0].items() if k != "tailles"}
        self.assertTrue(any("sans aucune contrainte" in m for m in self.erreurs(d)))

    def test_mauvais_etat_et_format(self):
        d = base()
        d["etat"] = "MI"
        self.assertTrue(any("MI" in m for m in self.erreurs(d)))
        d = base()
        d["format"] = 2
        self.assertTrue(any("version de format" in m for m in self.erreurs(d)))

    def test_fenetre_inversee(self):
        d = base()
        d["regles"][2]["tailles"]["fenetre"] = {"basse": {"pouces": 18}, "haute": {"pouces": 14}}
        self.assertTrue(any("basse < haute" in m for m in self.erreurs(d)))

    def test_index_embarque(self):
        index = os.path.join(ICI, "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "regles-us", "index.json")
        self.assertEqual(valider.valider(index), [])


if __name__ == "__main__":
    unittest.main()
