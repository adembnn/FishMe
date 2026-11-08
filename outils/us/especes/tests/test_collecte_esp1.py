import os, sys, tempfile, unittest, json
ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
sys.path.insert(0, os.path.join(ICI, ".."))
import commun_esp1 as c
import VT, nas_esp1
import verifier_zones as vz

SPORT = "<p>Brook Trout Walleye Rainbow Smelt</p><p>carp, longnose gar, freshwater drum and bowfin</p>"
PAN = "<p>Pumpkinseed Rock Bass Bluegill redbreast sunfish, rock bass and black and white crappie</p>"
SCHED = ("<table><tr><th>Waterbody</th><th>Town</th><th>Week of:</th><th>2YR Rainbow</th><th>2YR Brown Trout</th><th>2YR Brook Trout</th><th>Total</th></tr>"
         "<tr><td>Black River</td><td>X</td><td>5/4</td><td>10</td><td>5</td><td></td><td>15</td></tr></table>"
         "<table><tr><th>Waterbody</th><th>Town</th><th>Species</th><th>Number Planned</th></tr>"
         "<tr><td>Adams Reservoir</td><td>W</td><td>BKT</td><td>250</td></tr></table>")


class T(unittest.TestCase):
    def test_vt(self):
        with tempfile.TemporaryDirectory() as d:
            for n, h in [("vt-sport.html", SPORT), ("vt-pan.html", PAN), ("vt-sched.html", SCHED)]:
                open(os.path.join(d, n), "w").write(h)
            src, ent = VT.construire(d)
        noms = {(e["nom"], e["zone"]["id"]) for e in ent}
        self.assertIn(("Brook Trout", "VT"), noms)
        self.assertIn(("Bowfin", "VT"), noms)
        self.assertIn(("Black Crappie", "VT"), noms)
        self.assertIn(("Rainbow Trout", "Black River"), noms)
        self.assertNotIn(("Brook Trout", "Black River"), noms)
        self.assertIn(("Brook Trout", "Adams Reservoir"), noms)
        doc = {"format": "fishme-especes-us/1", "etat": "VT", "producteur": "agence", "date": c.DATE, "sources": src, "entrees": ent}
        self.assertEqual(vz.verifier_fichier("VT-agence.json", doc), [])

    def test_nas(self):
        occ = [
            {"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "huc8": "01080107", "huc8Name": "X", "year": 2001, "status": "established", "freshMarineIntro": "Freshwater"},
            {"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "huc8": "01080107", "huc8Name": "X", "year": 1990, "status": "failed", "freshMarineIntro": "Freshwater"},
            {"scientificName": "Gadus morhua", "commonName": "Cod", "huc8": "00000000", "status": "established", "freshMarineIntro": "Marine"},
        ]
        _, ent = nas_esp1.construire("VT", occ)
        self.assertEqual(sorted((e["zone"]["type"], e["n"]) for e in ent), [("etat", 1), ("huc8", 1)])


if __name__ == "__main__":
    unittest.main()
