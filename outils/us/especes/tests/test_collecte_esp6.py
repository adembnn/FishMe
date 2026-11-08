import os, sys, unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
import verifier_zones
import esp6_nas as nas, esp6_agence as agence

# fixture : trois occurrences NAS (une espèce hors table, une « failed » à ignorer)
OCC = [
    {"genus": "Cyprinus", "species": "carpio", "status": "established", "year": 1990, "huc8": "07040006", "huc8Name": "La Crosse-Pine"},
    {"genus": "Cyprinus", "species": "carpio", "status": "established", "year": 2001, "huc8": "07040006", "huc8Name": "La Crosse-Pine"},
    {"genus": "Cyprinus", "species": "carpio", "status": "failed", "year": 2010, "huc8": "07040006", "huc8Name": "La Crosse-Pine"},
    {"genus": "Neogobius", "species": "melanostomus", "status": "established", "year": 2005, "huc8": "04010201", "huc8Name": "St. Louis"},
]


class TestCollecteEsp6(unittest.TestCase):
    def test_nas_agrege_et_passe_le_verificateur(self):
        doc, ignores = nas.construire("WI", OCC, nas.table_latin(), "2026-11-08")
        self.assertEqual(ignores["Neogobius melanostomus"], 1)
        etat = [e for e in doc["entrees"] if e["zone"]["type"] == "etat"]
        huc = [e for e in doc["entrees"] if e["zone"]["type"] == "huc8"]
        self.assertEqual((len(etat), len(huc)), (1, 1))
        self.assertEqual((etat[0]["n"], etat[0]["annee_max"], etat[0]["slug"]), (2, 2001, "common-carp"))
        self.assertEqual(verifier_zones.verifier_fichier("WI-nas.json", doc), [])

    def test_agence_entree_slug_et_hors_table(self):
        z = {"type": "etat", "id": "MO", "nom": "Missouri"}
        a = agence.entree("walleye", z, "liste_agence", 0)
        self.assertEqual((a["slug"], a["latin"], a["confiance"]), ("walleye", "Sander vitreus", "officielle"))
        b = agence.entree("emerald-bowfin", z, "liste_agence", 0)
        self.assertIsNone(b["slug"])
        self.assertEqual(b["latin"], "Amia ocellicauda")
        doc = {"format": "fishme-especes-us/1", "etat": "MO", "producteur": "agence", "date": "2026-11-08",
               "sources": [agence.src("test", "https://mdc.mo.gov/fishing/species/walleye-sauger")], "entrees": [a, b]}
        self.assertEqual(verifier_zones.verifier_fichier("MO-agence.json", doc), [])

    def test_fichiers_embarques_du_groupe(self):
        dossier = verifier_zones.DEFAUT
        for usps in ("MI", "WI", "MN", "IA", "MO"):
            for prod in ("agence", "nas"):
                p = os.path.join(dossier, f"{usps}-{prod}.json")
                if os.path.exists(p):
                    import json
                    d = json.load(open(p, encoding="utf-8"))
                    self.assertEqual(verifier_zones.verifier_fichier(os.path.basename(p), d, None), [])
                    self.assertLessEqual(os.path.getsize(p), 400 * 1024)


if __name__ == "__main__":
    unittest.main()
