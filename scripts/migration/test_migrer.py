"""Tests : tout se passe sur une copie temporaire, le depot n'est jamais modifie.
   python3 -I scripts/migration/test_migrer.py"""
import importlib.util, os, shutil, subprocess, sys, tempfile, unittest
ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.abspath(os.path.join(ICI, "..", ".."))
spec = importlib.util.spec_from_file_location("migrer", os.path.join(ICI, "migrer-identifiants.py"))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
NEUF = ["--nouveau-bundle-id", "com.titouan.fishme", "--nouveau-team-id", "ABCDE12345",
        "--nouveau-conteneur-icloud", "iCloud.com.titouan.fishme", "--nouveau-app-group", "group.com.titouan.fishme",
        "--nouveau-id-widget", "com.titouan.fishme.widget"]

def mini(d):
    os.makedirs(os.path.join(d, "Config"))
    w = lambda p, t: open(os.path.join(d, p), "w").write(t)
    w("Config/a.entitlements", "iCloud.ai.mwm.build.challenge.team.01 group.ai.mwm.build.challenge.team.01")
    w("p.swift", 'let base = "ai.mwm.build.challenge.team.01"\nlet w="ai.mwm.build.challenge.team.01.widget" // ZUQ3ZP29N4\n'
                 'let id = "ai.mwm.build.challenge.team.01.yearly.00.ft.34.99"\nlet k="pk_prod_' + "a" * 32 + '"\n')
    w("x.pbxproj", "ai.mwm.BuildChallengeTests ai.mwm.BuildChallengeUITests")

class T(unittest.TestCase):
    def test_simulation_n_ecrit_rien(self):
        with tempfile.TemporaryDirectory() as d:
            mini(d); avant = open(d + "/p.swift").read()
            self.assertEqual(m.main(["--depot", d] + NEUF), 0)
            self.assertEqual(open(d + "/p.swift").read(), avant)
    def test_inventaire_types(self):
        with tempfile.TemporaryDirectory() as d:
            mini(d); a, man = m.inventaire(d); t = m.totaux(a)
            self.assertEqual((t["icloud"], t["groupe"], t["widget"], t["produit"], t["app"], t["team"], t["tests"]), (1, 1, 1, 1, 1, 1, 2))
            self.assertEqual(m.totaux(man)["cle_spark (masquee)"], 1)
    def test_appliquer_copie_une_passe_et_spark_intact(self):
        with tempfile.TemporaryDirectory() as d, tempfile.TemporaryDirectory() as o:
            mini(d); c = os.path.join(o, "c")
            self.assertEqual(m.main(["--depot", d, "--appliquer", "--copie", c] + NEUF), 0)
            s = open(c + "/p.swift").read()
            self.assertIn('base = "com.titouan.fishme"', s); self.assertIn("com.titouan.fishme.widget", s)
            self.assertIn("com.titouan.fishme.yearly.00.ft.34.99", s); self.assertIn("pk_prod_" + "a" * 32, s)
            self.assertNotIn("com.titouan.fishme.widget.widget", s); self.assertNotIn("ZUQ3", s)
            self.assertIn("iCloud.com.titouan.fishme group.com.titouan.fishme", open(c + "/Config/a.entitlements").read())
            self.assertIn("com.titouan.fishme.BuildChallengeUITests", open(c + "/x.pbxproj").read())
            self.assertIn("ai.mwm.build", open(d + "/p.swift").read())  # original intact
            a, _ = m.inventaire(c); self.assertEqual(sum(m.totaux(a).values()), 0)
    def test_refus(self):
        with tempfile.TemporaryDirectory() as d:
            mini(d)
            self.assertEqual(m.main(["--depot", d, "--appliquer"] + NEUF), 2)  # ni copie ni depot
            self.assertEqual(m.main(["--depot", d, "--appliquer", "--copie", d + "/z"] + NEUF), 2)  # copie dans le depot
            mauvais = [x if x != "com.titouan.fishme.widget" else "autre.widget" for x in NEUF]
            self.assertEqual(m.main(["--depot", d] + mauvais), 2)
    def test_depot_reel_copie(self):
        with tempfile.TemporaryDirectory() as o:
            c = os.path.join(o, "c")
            self.assertEqual(m.main(["--depot", RACINE, "--portee", "tout", "--appliquer", "--copie", c] + NEUF), 0)
            a, _ = m.inventaire(c)
            self.assertEqual(sum(m.totaux(a).values()), 0)
            self.assertIn("ABCDE12345", open(c + "/BuildChallenge.xcodeproj/project.pbxproj").read())

if __name__ == "__main__":
    unittest.main()
