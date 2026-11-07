import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import verifier_couverture as vc


class TestCouverture(unittest.TestCase):
    def test_trois_etats_de_depart_sont_conformes(self):
        trous, lignes, _ = vc.verifier()
        propres = [t for t in trous if t.split(" :")[0] in ("WI", "MN", "MI")]
        self.assertEqual(propres, [])

    def test_liste_de_51(self):
        self.assertEqual(len(vc.ETATS), 51)
        self.assertEqual(len(set(vc.ETATS)), 51)

    def test_mots_interdits(self):
        self.assertTrue(vc.MOTS.search("pêche autorisée ici"))
        self.assertFalse(vc.MOTS.search("accès public listé par WI DNR"))


if __name__ == "__main__":
    unittest.main()
