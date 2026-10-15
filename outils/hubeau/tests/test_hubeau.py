"""Tests unitaires de D2 : python3 -m unittest discover -s outils/hubeau/tests (ou pytest). Aucun reseau."""
import json
import os
import sys
import unittest
from datetime import date

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ICI)

import comptes  # noqa: E402
import especes  # noqa: E402
import geo  # noqa: E402


def carre(code, x0, y0, x1, y1, trou=None):
    anneaux = [[[x0, y0], [x1, y0], [x1, y1], [x0, y1], [x0, y0]]]
    if trou:
        anneaux.append(trou)
    return {"type": "Feature", "properties": {"code": code, "nom": code},
            "geometry": {"type": "Polygon", "coordinates": anneaux}}


class TestGeo(unittest.TestCase):
    def test_lambert93_point_connu(self):
        # station hydrometrique F468000101 : coordonnees Lambert 93 et lon/lat donnees par Hub'Eau
        lon, lat = geo.lambert93_vers_wgs84(657046.0, 6846533.0)
        self.assertAlmostEqual(lon, 2.416139463, places=4)
        self.assertAlmostEqual(lat, 48.717501657, places=4)

    def test_point_dans_un_seul_departement(self):
        d = geo.Departements({"features": [carre("92", 0, 0, 1, 1), carre("93", 1, 0, 2, 1)]})
        self.assertEqual(d.dans(0.9, 0.5), "92")
        self.assertEqual(d.dans(1.1, 0.5), "93")
        self.assertIsNone(d.dans(3, 3))

    def test_trou_exclu(self):
        d = geo.Departements({"features": [carre("A", 0, 0, 4, 4, trou=[[1, 1], [3, 1], [3, 3], [1, 3], [1, 1]]),
                                            carre("B", 1, 1, 3, 3)]})
        self.assertEqual(d.dans(2, 2), "B")
        self.assertEqual(d.dans(0.5, 0.5), "A")

    def test_proche_bord_avec_tolerance(self):
        d = geo.Departements({"features": [carre("92", 0, 0, 1, 1)]})
        self.assertEqual(d.ranger(1.005, 0.5, 1.5), ("92", "bord"))  # ~0,4 km hors du trace
        self.assertEqual(d.ranger(1.5, 0.5, 1.5), (None, None))
        self.assertEqual(d.ranger(0.5, 0.5, 0), ("92", "polygone"))

    def test_03082000_sans_ambiguite(self):
        """03082000 est range par ses coordonnees dans UN departement, quel que soit le champ
        code_departement de l'API (93 ou 92 selon l'appel)."""
        lon, lat = geo.lambert93_vers_wgs84(643477.0, 6863240.0)
        d = geo.Departements({"features": [carre("92", lon - 0.01, lat - 0.01, lon + 0.01, lat + 0.01),
                                            carre("93", lon + 0.01, lat - 0.01, lon + 0.05, lat + 0.01)]})
        for _dep_api in ("93", "92"):
            self.assertEqual(d.dans(lon, lat), "92")

    def test_vrai_geojson_si_present(self):
        chemin = os.path.join(ICI, "..", "..", "docs", "maquettes", "assets", "geo", "departements-simplifie.geojson")
        if not os.path.exists(chemin):
            self.skipTest("geojson de la maquette absent")
        d = geo.Departements.depuis_fichier(chemin)
        lon, lat = geo.lambert93_vers_wgs84(643477.0, 6863240.0)  # 03082000, la Seine a Suresnes
        self.assertEqual(d.dans(lon, lat), "92")
        lon, lat = geo.lambert93_vers_wgs84(657384.0, 6857582.0)  # 03112480, la Marne a Charenton
        self.assertEqual(d.dans(lon, lat), "94")


def op(i, station, jour, sans=False):
    return {"code_operation": i, "date_operation": f"{jour}T10:00:00Z", "code_station": station,
            "operation_sans_poisson": sans}


class TestComptes(unittest.TestCase):
    def setUp(self):
        self.stations = {"S1": {"dep": "94"}, "S2": {"dep": "94"}, "S3": {"dep": "75"}}
        self.ops = [op(1, "S1", "2025-09-01"), op(2, "S1", "2020-05-01"), op(3, "S2", "2012-06-01"),
                    op(4, "S2", "2024-06-01", sans=True), op(5, "S3", "2011-06-01"), op(6, "X", "2024-01-01"),
                    op(1, "S1", "2025-09-01")]  # doublon
        # code_operation en texte cote observations, entier cote operations
        paires = {("1", "2133"), ("1", "2193"), ("2", "2133"), ("3", "2133"), ("5", "2151"), ("1", "9999")}
        self.par_op = comptes.paires_vers_par_op(paires, {"2133", "2193", "2151"})
        self.agr = comptes.agreger(self.stations, self.ops, self.par_op, comptes.debut_fenetre(date(2026, 10, 15)))

    def test_fenetre(self):
        self.assertEqual(comptes.debut_fenetre(date(2026, 10, 15)), "2016-01-01")

    def test_comptes_departement(self):
        d = self.agr["departements"]["94"]
        self.assertEqual(d["dix_ans"]["peches"], 2)       # ops 1 et 2 ; 3 est de 2012, 4 sans poisson
        self.assertEqual(d["historique"]["peches"], 3)
        self.assertEqual(d["dix_ans"]["especes"]["2133"], {"peches": 2, "derniere": 2025})
        self.assertEqual(d["dix_ans"]["especes"]["2193"], {"peches": 1, "derniere": 2025})
        self.assertEqual(d["historique"]["especes"]["2133"], {"peches": 3, "derniere": 2025})
        self.assertNotIn("9999", d["historique"]["especes"])  # espece hors liste ignoree

    def test_operation_texte_ou_entier(self):
        self.assertIn("1", self.par_op)

    def test_ecartes(self):
        e = self.agr["ecartees"]
        self.assertEqual((e["sans_poisson"], e["station_inconnue"], e["doublons"]), (1, 1, 1))

    def test_station_une_seule_fois(self):
        self.assertEqual(set(self.agr["stations"]), {"S1", "S2", "S3"})
        s1 = self.agr["stations"]["S1"]
        self.assertEqual((s1["dix_ans"]["peches"], s1["derniere"], s1["derniere_dix_ans"]), (2, 2025, 2025))
        self.assertIsNone(self.agr["stations"]["S3"]["derniere_dix_ans"])

    def test_aucune_classe_de_rarete(self):
        texte = json.dumps(self.agr)
        for mot in ("classe", "fiab", "plafond", "commune", "remarquable", "seuil"):
            self.assertNotIn(mot, texte)

    def test_regions(self):
        regions = {"11": {"nom": "IDF", "departements": ["75", "94"]}, "24": {"nom": "CVL", "departements": ["18"]}}
        r = comptes.comptes_regions(self.agr["departements"], regions, ["75", "94"])
        self.assertEqual(r["11"]["historique"]["peches"], 4)
        self.assertEqual(r["11"]["historique"]["especes"]["2133"]["peches"], 3)
        self.assertTrue(r["11"]["complete"])
        self.assertFalse(r["24"]["complete"])
        self.assertEqual(r["24"]["historique"]["peches"], 0)


class TestEspeces(unittest.TestCase):
    def test_csv_titouan(self):
        liste = especes.charger(os.path.join(ICI, "species_source.csv"))
        codes = {e["code"] for e in liste}
        self.assertIn("2151", codes)
        self.assertEqual(len(codes), len(liste))  # pas de doublon de code

    def test_comparer_latin(self):
        self.assertTrue(especes.comparer_latin("Salmo trutta fario", "Salmo trutta"))
        self.assertFalse(especes.comparer_latin("Squalius cephalus", "Leuciscus cephalus"))

    def test_regions_json(self):
        with open(os.path.join(ICI, "regions.json"), encoding="utf-8") as f:
            r = json.load(f)["regions"]
        deps = [d for v in r.values() for d in v["departements"]]
        self.assertEqual(len(deps), 96)
        self.assertEqual(len(set(deps)), 96)
        self.assertEqual(len(r), 13)


if __name__ == "__main__":
    unittest.main()
