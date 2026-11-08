import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import verifier_zones as vz

BON = {"format": "fishme-especes-us/1", "etat": "WI", "producteur": "gbif", "date": "2026-11-07",
       "sources": [{"nom": "x", "url": "https://gbif.org/d/1", "licence": "CC0-1.0", "date": "2026-11-07"}],
       "entrees": [{"slug": None, "nom": "Walleye", "latin": "Sander vitreus", "zone": {"type": "etat", "id": "WI"},
                    "preuve": "occurrence_gbif", "src": 0, "confiance": "enregistrement_scientifique"}]}


class T(unittest.TestCase):
    def test_bon(self):
        self.assertEqual(vz.verifier_fichier("WI-gbif.json", BON), [])

    def test_licence_gbif(self):
        import copy
        d = copy.deepcopy(BON); d["sources"][0]["licence"] = "CC-BY-NC-4.0"
        self.assertTrue(vz.verifier_fichier("WI-gbif.json", d))

    def test_sans_source(self):
        import copy
        d = copy.deepcopy(BON); d["entrees"][0]["src"] = 3
        self.assertTrue(vz.verifier_fichier("WI-gbif.json", d))

    def test_rarete_interdite(self):
        import copy
        d = copy.deepcopy(BON); d["entrees"][0]["rarete"] = "rare"
        self.assertTrue(vz.verifier_fichier("WI-gbif.json", d))

    def test_forum_confiance(self):
        import copy
        d = copy.deepcopy(BON); d["producteur"] = "signalements"; d["entrees"][0]["preuve"] = "signalement_public"
        self.assertTrue(vz.verifier_fichier("WI-signalements.json", d))


if __name__ == "__main__":
    unittest.main()
