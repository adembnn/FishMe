import os, sys, unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
import verifier_zones as vz
import CT, NY, DE, PA, nas

SLUGS = None


def slugs():
    import json
    return {e["slug"] for e in json.load(open(os.path.join(ICI, "..", "especes-us.json")))}


# tableau d'empoissonnement mis en page comme le PDF du CT DEEP (une ligne à 10 nombres : colonne BN(Y) vide)
def ligne(nom, ville, valeurs):
    """valeurs : 11 positions (None = case vide), alignées à droite sur des colonnes de 9 caractères."""
    s = f" {nom:<28}{ville:<20}"
    for v in valeurs:
        s += f"{'' if v is None else v:>9}"
    return s


TABLEAU = "\n".join([
    ligne("Beaver Park Pond- North", "New Haven", [None, 450, 100, 750, 0, 0, 0, 0, 0, 0, 1300]),
    ligne("Amos Lake", "Preston", [0, 2100, 2100, 0, 200, 2000, 1000, 0, 0, 0, 7400]),
    ligne("Ligne fausse", "Nulle part", [5, 5, 5, 0, 0, 0, 0, 0, 0, 0, 99]),
])


class T(unittest.TestCase):
    def test_ct_tableau(self):
        lignes = {n: c for n, _, c in CT.trout(TABLEAU)}
        self.assertIn("Beaver Park Pond- North", lignes)
        self.assertEqual(lignes["Beaver Park Pond- North"]["BK_A"], 450)
        self.assertEqual(lignes["Amos Lake"]["BK_12"], 2000)
        self.assertNotIn("Ligne fausse", lignes)  # somme différente du total : écartée

    def test_ct_fichier(self):
        d = CT.construire.__globals__["LISTE_ETAT"]
        self.assertTrue(all(len(x) == 3 for x in d))

    def test_ny(self):
        agg = [{"waterbody": "Lake X", "county": "Essex", "species": "Splake", "max_year": "2024", "count": "3"},
               {"waterbody": "Lake X", "county": "Essex", "species": "Panfish", "max_year": "2024", "count": "1"}]
        d, ecartes = NY.construire(agg)
        self.assertEqual(ecartes, ["Panfish"])
        self.assertEqual(vz.verifier_fichier("NY-agence.json", d, slugs()), [])
        self.assertEqual(sum(1 for e in d["entrees"] if e["zone"]["type"] == "plan_eau"), 1)

    def test_de(self):
        d = DE.construire([{"pond_name": "Andrews Lake", "county": "Kent", "survey_year": "2017", "largemouth_bass": "89",
                            "bluegill": "0", "black_crappie": "8"}])
        self.assertEqual(vz.verifier_fichier("DE-agence.json", d, slugs()), [])
        eaux = [e for e in d["entrees"] if e["zone"]["type"] == "plan_eau"]
        self.assertEqual({e["slug"] for e in eaux}, {"largemouth-bass", "black-crappie"})

    def test_pa(self):
        self.assertEqual(vz.verifier_fichier("PA-agence.json", PA.construire(), slugs()), [])

    def test_nas(self):
        res = {"endOfRecords": "true", "limit": 1000, "results": [
            {"scientificName": "Ictalurus punctatus", "commonName": "Channel Catfish", "huc8": "02040105", "status": "established",
             "freshMarineIntro": "Freshwater", "year": 1990},
            {"scientificName": "Ictalurus punctatus", "commonName": "Channel Catfish", "huc8": "02040105", "status": "established",
             "freshMarineIntro": "Freshwater", "year": 2001},
            {"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "huc8": "02000000", "status": "established",
             "freshMarineIntro": "Freshwater", "year": 1906},
            {"scientificName": "Alosa x", "commonName": "Marin", "huc8": "02040105", "status": "established",
             "freshMarineIntro": "Marine", "year": 2000}]}
        d = nas.collecter("NJ", lire=lambda u: res, aujourdhui="2026-11-08")
        self.assertEqual(len(d["entrees"]), 2)
        self.assertEqual(vz.verifier_fichier("NJ-nas.json", d, slugs()), [])
        c = [e for e in d["entrees"] if e["latin"] == "Ictalurus punctatus"][0]
        self.assertEqual((c["n"], c["annee_max"]), (2, 2001))


if __name__ == "__main__":
    unittest.main()
