import os, sys, unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
sys.path.insert(0, os.path.join(ICI, ".."))
import AL, FL, GA, MS, SC, commun  # noqa: E402

SC_HTML = "<p>Fish Species - Freshwater Guide to Freshwater Fishes (Adobe PDF - 3MB) --> Temperate Bass Striped bass White perch Black Bass Largemouth bass Spotted (Alabama) bass Sunfish Bluegill Redear sunfish (Shellcracker) Research and Education x</p>"
MS_HTML = "<p>Fish Species White Crappie Largemouth Bass Chain/Redfin Pickerel Downloadable Resources</p>"
GA_HTML = ("<p>Fish Identification Bass, Largemouth Scientific Name : Micropterus salmoides Description : x Range : Common. Current State Record Information "
           "Sunfish, Bluegill Scientific Name : Lepomis macrochirus Description : y</p>")
LAC_HTML = "<p>Fish Species Largemouth bass, bluegill, and crappie. Facilities x</p>"


class TestCollecteEsp4(unittest.TestCase):
    def test_sc(self):
        e = SC.construire(SC_HTML)
        self.assertEqual([x["nom"] for x in e], ["Striped bass", "White perch", "Largemouth bass", "Spotted (Alabama) bass", "Bluegill", "Redear sunfish"])
        self.assertEqual(e[2]["slug"], "largemouth-bass")

    def test_ms_scinde_pickerel(self):
        e = MS.construire(MS_HTML)
        self.assertEqual([x["latin"] for x in e], ["Pomoxis annularis", "Micropterus salmoides", "Esox niger", "Esox americanus americanus"])

    def test_ga(self):
        e = GA.construire(GA_HTML)
        self.assertEqual([(x["nom"], x["latin"]) for x in e], [("Largemouth bass", "Micropterus salmoides"), ("Bluegill", "Lepomis macrochirus")])

    def test_fl(self):
        d = {"features": [{"attributes": {"Species": "Florida Gar"}}, {"attributes": {"Species": "Bluegill"}}]}
        self.assertEqual([x["latin"] for x in FL.construire(d)], ["Lepisosteus platyrhincus", "Lepomis macrochirus"])

    def test_al_lac(self):
        self.assertEqual(AL.especes_lac(LAC_HTML), ["Largemouth bass", "bluegill", "crappie"])

    def test_aucun_mot_interdit(self):
        import verifier_zones
        e = SC.construire(SC_HTML) + MS.construire(MS_HTML)
        for x in e:
            self.assertIsNone(verifier_zones.INTERDITS.search(x["nom"] + x["latin"]))


if __name__ == "__main__":
    unittest.main()
