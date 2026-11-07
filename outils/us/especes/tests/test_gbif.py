"""Tests de gbif_zones.py hors réseau (fixtures réduites)."""
import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import gbif_zones as g
import verifier_zones as vz

FACETTES = {"offset": 0, "limit": 0, "count": 30, "results": [],
            "facets": [{"field": "SPECIES_KEY", "counts": [{"name": "2394563", "count": 20}, {"name": "5210000", "count": 1},
                                                           {"name": "2350000", "count": 9}]}]}


class Faux:
    """Client factice : répond aux facettes par tranche d'années d'après une table {speciesKey: [années]}."""

    def __init__(self, annees):
        self.annees, self.requetes = annees, 0

    def json(self, url):
        import urllib.parse as up
        self.requetes += 1
        q = up.parse_qs(up.urlparse(url).query)
        lo, hi = (-1, 9999)
        if "year" in q:
            lo, hi = (int(x) for x in q["year"][0].split(","))
        counts = []
        for k, ys in self.annees.items():
            n = sum(1 for y in ys if lo <= y <= hi)
            if n:
                counts.append({"name": str(k), "count": n})
        return {"facets": [{"field": "SPECIES_KEY", "counts": counts}]}


class T(unittest.TestCase):
    def test_analyse_facettes(self):
        self.assertEqual(g.analyser_facettes(FACETTES), {2394563: 20, 5210000: 1, 2350000: 9})

    def test_facettes_zone_vide(self):
        self.assertEqual(g.analyser_facettes({"facets": []}), {})

    def test_facettes_invalides(self):
        with self.assertRaises(ValueError):
            g.analyser_facettes({"erreur": "x"})

    def test_seuil(self):
        self.assertEqual(g.garder({1: 1, 2: 2, 3: 9}, 2), {2: 2, 3: 9})
        self.assertEqual(g.garder({1: 1, 2: 2, 3: 9}, 5), {3: 9})

    def test_filtre_famille(self):
        self.assertTrue(g.famille_retenue("Centrarchidae", "Micropterus"))
        self.assertFalse(g.famille_retenue("Centrarchidae", "Enneacanthus"))
        self.assertTrue(g.famille_retenue("Percidae", "Sander"))
        self.assertFalse(g.famille_retenue("Percidae", "Etheostoma"))   # darters écartés
        self.assertTrue(g.famille_retenue("Sciaenidae", "Aplodinotus"))
        self.assertFalse(g.famille_retenue("Sciaenidae", "Cynoscion"))  # marin
        self.assertTrue(g.famille_retenue("Cyprinidae", "Cyprinus"))
        self.assertFalse(g.famille_retenue("Cyprinidae", "Pimephales"))  # petit cyprin
        self.assertFalse(g.famille_retenue("Pomatomidae", "Pomatomus"))  # famille marine
        self.assertFalse(g.famille_retenue("Ictaluridae", "Noturus"))

    def test_attribution_aux_etats(self):
        self.assertEqual(g.etats_du_huc8("WI,MI"), ["MI", "WI"])
        self.assertEqual(g.etats_du_huc8("MN,CN"), ["MN"])   # Canada ignoré
        self.assertEqual(g.etats_du_huc8("PR"), [])
        self.assertEqual(g.etats_du_huc8(None), [])
        self.assertEqual(len(g.ETATS), 51)

    def test_annee_max_exacte(self):
        faux = Faux({1: [1999, 2003, 2021], 2: [2026], 3: [1950, 1951], 4: [2015, 2014]})
        c = g.Comptage(faux, [("country", "US")])
        self.assertEqual(c.annees_max({1, 2, 3, 4}), {1: 2021, 2: 2026, 3: 1951, 4: 2015})

    def test_annee_max_absente_si_inconnue(self):
        faux = Faux({1: [2020]})
        self.assertEqual(g.Comptage(faux, []).annees_max({1, 99}), {1: 2020})

    def test_zone_entrees(self):
        faux = Faux({10: [2020, 2022], 11: [2024], 12: [2010, 2011, 2012]})
        infos = {10: {"retenue": True, "slug": "walleye", "nom": "Walleye", "latin": "Sander vitreus"},
                 11: {"retenue": True, "slug": None, "nom": "X", "latin": "Genus rareus"},
                 12: {"retenue": False}}
        stats = {"facettes_totales": 0, "ecartees_liste_blanche": 0, "sans_annee": 0, "saturees": []}
        zone = {"type": "huc8", "id": "04030101", "nom": "Test"}
        e = g.zone_entrees(faux, [], 2, {}, infos, stats, zone)
        self.assertEqual([(x["latin"], x["n"], x["annee_max"]) for x in e], [("Sander vitreus", 2, 2022)])
        self.assertEqual(stats["ecartees_liste_blanche"], 1)  # 12 écartée ; 11 sous le seuil

    def test_wkt_sans_coordonnee_hors_polygone_et_sens(self):
        anneau_horaire = [[0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]  # horaire (ArcGIS)
        w = g.rings_vers_wkt([anneau_horaire], aire_min=0)
        self.assertTrue(w.startswith("MULTIPOLYGON((("))
        self.assertIn("0.0000 0.0000", w)
        pts = [tuple(float(v) for v in p.split()) for p in w[len("MULTIPOLYGON((("):-3].split(",")]
        self.assertGreater(g.aire_signee(pts[:-1]), 0)  # antihoraire pour GBIF

    def test_simplification_limite_sommets(self):
        import math
        cercle = [(math.cos(i / 300 * 6.2832) * 0.3, math.sin(i / 300 * 6.2832) * 0.3) for i in range(300)][::-1]
        self.assertLessEqual(len(g.simplifier_anneau(cercle, 60)), 60)

    def test_url_facette(self):
        u = g.url_facette(g.parametres_base([1, 2], gadm="USA.50_1"), (2020, 2022))
        for morceau in ("license=CC0_1_0", "license=CC_BY_4_0", "occurrenceStatus=PRESENT", "facet=speciesKey", "year=2020%2C2022",
                        "gadmGid=USA.50_1", "familyKey=1", "familyKey=2"):
            self.assertIn(morceau, u)
        self.assertNotIn("inaturalist", u.lower())

    def test_sortie_passe_le_verificateur(self):
        entrees = [dict(slug="walleye", nom="Walleye", latin="Sander vitreus", zone={"type": "etat", "id": "WI", "nom": "Wisconsin"},
                        preuve="occurrence_gbif", n=5, annee_max=2024),
                   dict(slug=None, nom="X", latin="Y z", zone={"type": "huc8", "id": "04030101", "nom": "T"},
                        preuve="occurrence_gbif", n=2, annee_max=2020)]
        d = g.fichier_etat("WI", entrees[:1], entrees[1:], g.sources_gbif([1, 2], "USA.50_1"))
        self.assertEqual(vz.verifier_fichier("WI-gbif.json", d), [])
        self.assertTrue(all(s["licence"] in ("CC0-1.0", "CC-BY-4.0") for s in d["sources"]))
        self.assertIn("GBIF.org", d["sources"][0]["nom"])
        self.assertNotIn("lat", d["entrees"][0])


if __name__ == "__main__":
    unittest.main()
