"""Tests des collecteurs du groupe esp-5 (TN KY OH IN IL) sur de petites fixtures (aucun réseau)."""
import os, sys, unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
sys.path.insert(0, os.path.join(ICI, ".."))

import IL, IN, NAS, OH  # noqa: E402
import verifier_zones  # noqa: E402

HTML_IL = """<html><body><div>Sign In</div><h2>Sign In
Moorman Park Lake
 Back to Lakes &amp; Reservoirs</h2>
<div>Info /
Adams County</div>
<div>Fishing Outlook</div>
<div>Largemouth Bass</div><div>Average</div><p>In 2026, Largemouth Bass were collected at a rate of 32 fish per hour of electrofishing. Fish ranged from 4.0 - 16.1.</p>
<div>Channel Catfish</div><div>Average</div><p>No Channel Catfish were sampled during the 2026 survey; however, they are hard to sample. 159 were stocked on 9/4/2025.</p>
<div>Redear Sunfish</div><div>Average</div><p>Redear Sunfish were collected at a rate of 32 fish per hour. Redear Sunfish ranged from 2.8 - 6.9. The State Hatchery stocked 604 on 9/11/2025.</p>
<div>Recent Stocking History</div>
<div>2026</div><div>Rainbow Trout</div><div>Adult</div><div>712</div>
<div>2025</div><div>Channel Catfish</div><div>Advanced Fingerling</div><div>159</div>
<div>Contact</div></body></html>"""

LISTE_IN = """
Family: Centrarchidae
Smallmouth Bass
 Micropterus dolomieu
-
Largemouth Bass
 Micropterus nigricans
-
Family: Bidule
Alabama Shad
 Alosa alabamae
EX
Family: Esocidae
Northern Pike
 Esox lucius
-
"""

GUIDE_OH = "texte\n■10 Bowfin\n■30 Hybrid-Striped Bass\n■26 Bullhead Catfish\n■34 Saugeye\n■39 Rainbow Trout\nautre\n"

TRUITE = """Lakes
Greene Airline Pit 1,000 Rainbow Trout
LaGrange Oliver Lake 4,200 Rainbow Trout
3,245 Brown Trout
St. Joseph Pinhook Park 400 Rainbow Trout
Rainbow Trout Total 14,150
May Stockings
Steuben Pigeon River CR 175 North 250 Rainbow Trout
"""


class TestEsp5(unittest.TestCase):
    def test_il_plan_eau(self):
        nom, comte, enq, stk = IL.parse_plan_eau(HTML_IL)
        self.assertEqual(nom, "Moorman Park Lake")
        self.assertEqual(comte, "Adams County")
        self.assertEqual(enq, [("Largemouth Bass", 2026), ("Redear Sunfish", None)])  # année seulement si la 1re phrase la donne
        self.assertIn(("Channel Catfish", 2025), stk)
        self.assertNotIn("Channel Catfish", [e for e, _ in enq])  # « No ... were sampled » : absent

    def test_in_liste(self):
        d = IN.construire("<html>" + "".join(f"<p>{l}</p>" for l in LISTE_IN.splitlines()) + "</html>")
        noms = [e["nom"] for e in d["entrees"]]
        self.assertIn("Largemouth Bass", noms)
        self.assertNotIn("Alabama Shad", noms)
        self.assertEqual(verifier_zones.verifier_fichier("IN-agence.json", d), [])

    def test_oh_guide(self):
        d, ec = OH.construire(GUIDE_OH)
        slugs = {e["slug"] for e in d["entrees"]}
        self.assertTrue({"wiper", "saugeye", "yellow-bullhead", "rainbow-trout"} <= slugs)
        self.assertEqual(verifier_zones.verifier_fichier("OH-agence.json", d), [])

    def test_in_truite(self):
        self.assertEqual(sorted(set(IN.plans_truite(TRUITE))),
                         [("Airline Pit", "Rainbow Trout"), ("Oliver Lake", "Brown Trout"), ("Oliver Lake", "Rainbow Trout"), ("Pinhook Park", "Rainbow Trout")])

    def test_nas_agreger(self):
        lignes = [{"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "huc8": "05130205", "huc8Name": "Lower Cumberland", "year": 1960, "status": "established"},
                  {"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "huc8": "05130205", "huc8Name": "Lower Cumberland", "year": 1999, "status": "collected"},
                  {"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "huc8": "05130205", "huc8Name": "Lower Cumberland", "year": 2001, "status": "failed"}]
        d = NAS.agreger("TN", lignes)
        self.assertEqual(len(d["entrees"]), 1)
        self.assertEqual((d["entrees"][0]["n"], d["entrees"][0]["annee_max"], d["entrees"][0]["slug"]), (2, 1999, "common-carp"))
        self.assertEqual(verifier_zones.verifier_fichier("TN-nas.json", d), [])


if __name__ == "__main__":
    unittest.main()
