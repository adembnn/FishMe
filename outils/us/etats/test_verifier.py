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
        # Le nombre d'États vérifiés évolue avec les relectures (3 le 7 nov. au matin, plus après outils/us/etats/verifs/) :
        # le test vérifie la cohérence du bilan avec les drapeaux, pas un chiffre figé.
        self.assertEqual(b["verifie"], sum(1 for e in D["etats"] if e["verifie"]))

    def test_lot_d6_19_etats_relus(self):
        """D6 (7 nov. 2026) : les 19 États restants ont été relus ; 6 passent à vérifié, 13 restent « à vérifier » avec leur raison."""
        d6 = "AZ CA ID KS KY LA ME MD MA MI MS MT NE NH NJ NM NC RI TN".split()
        par = {e["usps"]: e for e in D["etats"]}
        verifies = {c for c in d6 if par[c]["verifie"]}
        self.assertEqual(verifies, set("LA ME MS NH NJ NM".split()))
        self.assertEqual(sum(1 for e in D["etats"] if e["verifie"]), 38)
        for c in d6:
            e = par[c]
            self.assertTrue(e["url_agence"].startswith("https://"))
            self.assertEqual(e["date_lecture"], "2026-11-07")
            self.assertTrue(any(f"verifs/{c}.json" in x for x in e["sources_rapports"]))
            if not e["verifie"]:
                self.assertTrue(json.loads(Path(__file__).with_name("verifs").joinpath(f"{c}.json").read_text())["raison_non_verifie"])

if __name__ == "__main__":
    unittest.main()
