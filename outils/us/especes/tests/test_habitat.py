"""Un poisson marin, d'aquarium ou de récif ne doit jamais entrer dans les listes d'espèces d'un plan d'eau américain."""
import copy, importlib.util, json, os, tempfile, unittest

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)


def charger(nom):
    s = importlib.util.spec_from_file_location(nom, os.path.join(RACINE, nom + ".py"))
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


habitat = charger("habitat")
verif = charger("verifier_zones")
TABLE = {"especes": {
    "Thunnus albacares": {"eau_douce": 0, "marin": 1},
    "Salmo salar": {"eau_douce": 1, "marin": 1},
    "Esox lucius": {"eau_douce": 1, "marin": 0},
    "Esox masquinongy": {"eau_douce": 1, "marin": 0},
    "Alosa alosa": None,
}}


class TestHabitat(unittest.TestCase):
    def test_thon_refuse_brochet_accepte(self):
        self.assertFalse(habitat.eau_douce("Thunnus albacares", TABLE)[0])
        self.assertTrue(habitat.eau_douce("Esox lucius", TABLE)[0])

    def test_inconnu_est_retire(self):
        self.assertFalse(habitat.eau_douce("Alosa alosa", TABLE)[0])
        self.assertFalse(habitat.eau_douce("Poisson inventus", TABLE)[0])

    def test_hybride_et_genre(self):
        self.assertTrue(habitat.eau_douce("Esox lucius × masquinongy", TABLE)[0])
        self.assertFalse(habitat.eau_douce("Esox lucius × Thunnus albacares", TABLE)[0])
        self.assertFalse(habitat.eau_douce("Esox sp.", TABLE)[0])
        self.assertTrue(habitat.eau_douce("Esox sp.", TABLE, {"Esox": True})[0])

    def test_la_table_embarquee_couvre_tous_les_fichiers(self):
        table = json.load(open(os.path.join(RACINE, "habitat-worms.json")))
        for n in habitat.noms_latins():
            for s in habitat.noms_simples(n):
                self.assertIn(s, table["especes"], n)

    def test_le_verificateur_refuse_un_thon_dans_un_fichier(self):
        src = os.path.join(habitat.RES, "WI-agence.json")
        d = json.load(open(src))
        e = copy.deepcopy(d["entrees"][0])
        e.update({"nom": "Yellowfin tuna", "latin": "Thunnus albacares", "slug": None})
        d["entrees"].append(e)
        table = json.load(open(os.path.join(RACINE, "habitat-worms.json")))
        table["especes"]["Thunnus albacares"] = {"eau_douce": 0, "marin": 1}
        with tempfile.TemporaryDirectory() as t:
            json.dump(d, open(os.path.join(t, "WI-agence.json"), "w"))
            ancienne = verif._table_habitat
            verif._table_habitat = lambda: table
            try:
                trous, _ = verif.verifier(t)
            finally:
                verif._table_habitat = ancienne
        self.assertTrue(any("Thunnus albacares" in x and "non eau douce" in x for x in trous), trous)


if __name__ == "__main__":
    unittest.main()
