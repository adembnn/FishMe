import copy, json, unittest
from pathlib import Path
import verifier

D = json.loads(Path(__file__).with_name("etats.json").read_text())

class TestEtats(unittest.TestCase):
    def test_fichier_valide(self):
        self.assertEqual(verifier.verifier(D), [])

    def test_51_etats(self):
        self.assertEqual(len(D["etats"]), 51)
        self.assertIn("DC", [e["usps"] for e in D["etats"]])

    def test_etat_manquant(self):
        d = copy.deepcopy(D); d["etats"] = d["etats"][1:]
        self.assertTrue(any("manquant" in x for x in verifier.verifier(d)))

    def test_prix_sans_source(self):
        d = copy.deepcopy(D)
        e = next(e for e in d["etats"] if e["usps"] == "TX")
        e["prix_resident"]["source"] = ""
        self.assertTrue(any("sans source" in x for x in verifier.verifier(d)))

    def test_url_http_refusee(self):
        d = copy.deepcopy(D); d["etats"][0]["url_agence"] = "http://exemple.org/"
        self.assertTrue(any("https" in x for x in verifier.verifier(d)))

    def test_verifie_exige_prix_officiel(self):
        d = copy.deepcopy(D)
        e = next(e for e in d["etats"] if e["usps"] == "CA"); e["verifie"] = True
        self.assertTrue(any("officiel" in x for x in verifier.verifier(d)))

    def test_mot_permissif(self):
        d = copy.deepcopy(D); d["etats"][0]["notes"] = "autorisé"
        self.assertTrue(any("verdict" in x for x in verifier.verifier(d)))

    def test_bilan(self):
        b = verifier.bilan(D)
        self.assertEqual(b["complets"] + b["partiels"] + b["vides"], 51)
        self.assertEqual(b["verifie"], 3)

if __name__ == "__main__":
    unittest.main()
