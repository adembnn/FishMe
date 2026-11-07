import os, random, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import commun, examen


class T(unittest.TestCase):
    def test_licences(self):
        self.assertEqual(commun.code_licence("http://creativecommons.org/licenses/by-nc/4.0/legalcode"), "CC_BY_NC_4_0")
        self.assertEqual(commun.code_licence("http://creativecommons.org/publicdomain/zero/1.0/"), "CC0_1_0")
        self.assertEqual(commun.classe_licence("CC_BY_4_0"), "libre")
        self.assertEqual(commun.classe_licence("CC_BY_NC_4_0"), "entrainement_seul")
        self.assertEqual(commun.classe_licence("CC_BY_ND_4_0"), "exclue")
        self.assertEqual(commun.classe_licence("INCONNUE"), "exclue")

    def test_decoupe_stable_et_proche_de_70_15_15(self):
        n = [commun.decoupe_observateur("u%d" % i) for i in range(5000)]
        self.assertEqual(n[7], commun.decoupe_observateur("u7"))
        self.assertAlmostEqual(n.count("train") / 5000, 0.70, delta=0.03)

    def test_examen_passe_et_echoue(self):
        random.seed(1)
        L = []
        for i in range(400):
            v = random.choice(["a", "b"])
            L.append({"vraie": v, "p1": v if i % 10 else "b" if v == "a" else "a", "p2": v, "p3": "a", "conf1": 0.8 if i % 10 else 0.2, "source": "pecheur"})
        L += [{"vraie": "pas-un-poisson", "p1": "pas-un-poisson", "p2": "a", "p3": "b", "conf1": 0.9, "source": "pecheur"}] * 20
        r = examen.examiner(L)
        self.assertEqual(r["verdict"], "passe")
        self.assertEqual(r["seuil_recommande"], 0.30)
        self.assertEqual(examen.examiner(L[:50])["verdict"], "echoue")  # moins de 300 prises


if __name__ == "__main__":
    unittest.main()
