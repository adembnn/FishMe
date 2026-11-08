"""Tests hors réseau du groupe ouest-int (AZ, NV, OR) : normaliseurs fédéraux et OSMB, couche OpenStreetMap, filtre de contour."""
import json
import os
import sys
import tempfile
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))

import normaliser  # noqa: E402
import ouest_int  # noqa: E402
import embarquer  # noqa: E402

PT = {"type": "Point", "coordinates": [-122.5, 45.5]}


def feat(**p):
    return {"type": "Feature", "geometry": PT, "properties": p}


class TestNormaliseursOuest(unittest.TestCase):
    def test_enregistres_sans_doublon(self):
        for k in ("az_blm", "az_usfs", "az_nps", "nv_blm", "nv_usfs", "nv_nps", "or_blm", "or_usfs", "or_nps", "or_osmb"):
            self.assertIn(k, normaliser.NORMALISEURS)

    def test_osmb_garde_les_rampes_publiques_sans_contact(self):
        f = normaliser.NORMALISEURS["or_osmb"](feat(
            globalid="{A}", name="Rampe X", waterway_name="Columbia River", county="Multnomah", facility_type="Boat Ramp",
            launch_type="Trailered Boat Launch", public_display="Yes", ramp_lanes="2", manager_phone="503-000-0000", oa_status=None), None)
        p = f["properties"]
        self.assertEqual((p["type"], p["voies"], p["eau"]), ("rampe", 2, "Columbia River"))
        self.assertNotIn("manager_phone", p)
        self.assertFalse(any("503" in str(v) for v in p.values()))

    def test_osmb_exclut_marina_ferme_non_affiche(self):
        n = normaliser.NORMALISEURS["or_osmb"]
        base = dict(globalid="{A}", name="X", facility_type="Boat Ramp", public_display="Yes")
        self.assertIsNone(n(feat(**dict(base, facility_type="Marina")), None))
        self.assertIsNone(n(feat(**dict(base, public_display="No")), None))
        self.assertIsNone(n(feat(**dict(base, oa_status="Closed")), None))
        self.assertIsNotNone(n(feat(**base), None))

    def test_blm_seulement_rampes(self):
        n = normaliser.NORMALISEURS["nv_blm"]
        self.assertEqual(n(feat(GlobalID="g", FET_SUBTYPE="Boat Ramp", FET_NAME="Lac", WEB_DISPLAY="YES"), None)["properties"]["type"], "rampe")
        self.assertIsNone(n(feat(GlobalID="g", FET_SUBTYPE="Staging Area", FET_NAME="Z", WEB_DISPLAY="YES"), None))

    def test_usfs_navigation_et_peche(self):
        n = normaliser.NORMALISEURS["az_usfs"]
        self.assertEqual(n(feat(recareaid="1", markeractivity="Boating - Motorized", recareaname="A"), None)["properties"]["coin"], "acces")
        self.assertEqual(n(feat(recareaid="2", markeractivity="Lake and Pond Fishing", recareaname="B"), None)["properties"]["type"], "peche_rive")
        self.assertIsNone(n(feat(recareaid="3", markeractivity="Day Hiking", recareaname="C"), None))

    def test_nps_exige_donnees_sans_restriction(self):
        n = normaliser.NORMALISEURS["nv_nps"]
        self.assertEqual(n(feat(GEOMETRYID="x", POINAME="Rampe", POITYPE="Boat Launch", DATAACCESS="Unrestricted"), None)["properties"]["type"], "rampe")
        self.assertIsNone(n(feat(GEOMETRYID="x", POINAME="Rampe", POITYPE="Boat Launch", DATAACCESS="Restricted"), None))
        self.assertIsNone(n(feat(GEOMETRYID="y", POINAME="Banc", POITYPE="Bench", DATAACCESS="Unrestricted"), None))


class TestOsmEtPoints(unittest.TestCase):
    def test_objets_osm_excluent_prive_et_ne_gardent_que_nom_et_type(self):
        brut = {"elements": [
            {"type": "node", "id": 1, "lat": 36.0, "lon": -115.0, "tags": {"leisure": "slipway", "name": "Rampe A", "phone": "123"}},
            {"type": "way", "id": 2, "center": {"lat": 36.1, "lon": -115.1}, "tags": {"amenity": "boat_ramp", "access": "private"}},
            {"type": "way", "id": 3, "center": {"lat": 36.2, "lon": -115.2}, "tags": {"leisure": "slipway"}}]}
        fs = ouest_int.objets_osm(brut, "NV")
        self.assertEqual([f["properties"]["id"] for f in fs], ["osm:n1", "osm:w3"])
        self.assertEqual(set(fs[0]["properties"]), {"id", "type", "coin", "nom"})

    def test_texte_osm_ne_dit_jamais_liste_par_l_agence_et_points_hors_etat_retires(self):
        with tempfile.TemporaryDirectory() as d:
            contour = [[[-116.0, 35.0], [-114.0, 35.0], [-114.0, 37.0], [-116.0, 37.0], [-116.0, 35.0]]]
            json.dump(contour, open(os.path.join(d, "contour-NV.json"), "w"))
            osm = {"id": "acces_osm", "role": "acces", "statut": "ok", "source": ouest_int.COUCHE_OSM["source"], "editeur": "OpenStreetMap",
                   "url_source": "https://www.openstreetmap.org/copyright", "licence": ouest_int.COUCHE_OSM["licence"],
                   "collection": {"features": [
                       {"geometry": {"type": "Point", "coordinates": [-115.0, 36.0]}, "properties": {"id": "osm:n1", "nom": "Dedans", "type": "rampe"}},
                       {"geometry": {"type": "Point", "coordinates": [-110.0, 36.0]}, "properties": {"id": "osm:n2", "nom": "Dehors", "type": "rampe"}}]}}
            blm = {"id": "acces_blm", "role": "acces", "statut": "ok", "source": "BLM, X", "editeur": "Bureau of Land Management",
                   "url_source": "https://gis.blm.gov", "licence": "[?] non précisée",
                   "collection": {"features": [
                       {"geometry": {"type": "Point", "coordinates": [-115.5, 36.5]}, "properties": {"id": "blm-rec:1", "nom": "R", "type": "rampe"}}]}}
            original = embarquer.construire_points
            try:
                ouest_int.construire_points_corrige(d)
                res = embarquer.construire_points("NV", {"couches": [blm, osm]}, "2026-11-07")
            finally:
                embarquer.construire_points = original
            self.assertEqual([p[0] for p in res["points"]], ["blm-rec:1", "osm:n1"])
            textes = [s["jeu"] for s in res["sources"]]
            self.assertEqual(res["sources"][0]["genre"], "agence")
            self.assertTrue(textes[0].startswith("Bureau of Land Management"))
            self.assertTrue(textes[1].startswith("OpenStreetMap"))
            self.assertEqual(res["sources"][1]["genre"], "osm")


if __name__ == "__main__":
    unittest.main()
