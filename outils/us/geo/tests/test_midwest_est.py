"""Tests hors réseau des normaliseurs OH, IN et de l'import OpenStreetMap IL (groupe midwest-est).
Lancer : cd outils/us/geo && python3 -I -m unittest discover -s . -p 'test_*.py'
"""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402
import osm_il  # noqa: E402

with open(os.path.join(ICI, "fixtures", "midwest_est.json"), encoding="utf-8") as f:
    FIX = json.load(f)

INTERDITS = ("PHONE", "CONTACT", "ADDRESS", "Comments", "contact", "comments", "lease", "FEATURE")


def normaliser_tous(nom, feats):
    return [n for n in (nz.NORMALISEURS[nom](f, {}) for f in feats) if n]


class TestOhio(unittest.TestCase):
    def test_bateau_garde_les_sites_publics_avec_mise_a_l_eau(self):
        r = normaliser_tous("oh_acces_bateau", FIX["oh_bateau"])
        self.assertEqual([p["properties"]["nom"] for p in r], ["Adams Lake State Park", "Autre site du même ID"])
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[0]["properties"]["rampes"], 1)
        self.assertEqual(r[1]["properties"]["type"], "acces_portage")

    def test_id_unique_meme_quand_l_id_de_l_agence_se_repete(self):
        r = normaliser_tous("oh_acces_bateau", FIX["oh_bateau"])
        self.assertEqual(len({p["properties"]["id"] for p in r}), 2)

    def test_aucun_champ_de_contact(self):
        for nom, cle in (("oh_acces_bateau", "oh_bateau"), ("oh_acces_pagaie", "oh_pagaie")):
            for n in normaliser_tous(nom, FIX[cle]):
                self.assertFalse(set(n["properties"]) & set(INTERDITS), n["properties"])
                self.assertNotIn("555-0100", json.dumps(n))
                self.assertNotIn("Located in Westerville", json.dumps(n))

    def test_pagaie_ecarte_les_obstacles(self):
        r = normaliser_tous("oh_acces_pagaie", FIX["oh_pagaie"])
        self.assertEqual([p["properties"]["id"] for p in r], ["oh-paddle:10", "oh-paddle:12"])
        self.assertEqual([p["properties"]["type"] for p in r], ["rampe", "acces"])
        self.assertEqual(r[0]["properties"]["eau"], "Alum Creek")


class TestIndiana(unittest.TestCase):
    def test_types_et_masquage(self):
        r = normaliser_tous("in_acces_peche", FIX["in_peche"])
        self.assertEqual([p["properties"]["nom"] for p in r], ["Duffy's Landing", "River Bend Park", "Rogers Park"])
        self.assertEqual([p["properties"]["type"] for p in r], ["rampe", "peche_rive", "acces_portage"])
        self.assertEqual([p["properties"]["coin"] for p in r], ["acces", "peche", "acces"])

    def test_accessid_repete_donne_deux_ids(self):
        r = normaliser_tous("in_acces_peche", FIX["in_peche"])
        self.assertEqual(len({p["properties"]["id"] for p in r}), 3)

    def test_aucun_champ_de_contact(self):
        for n in normaliser_tous("in_acces_peche", FIX["in_peche"]):
            self.assertFalse(set(n["properties"]) & set(INTERDITS), n["properties"])


class TestOsmIllinois(unittest.TestCase):
    REP = {"osm3s": {"timestamp_osm_base": "2026-11-07T23:13:38Z"}, "elements": [
        {"type": "node", "id": 1, "lat": 38.92525, "lon": -90.1, "tags": {"leisure": "slipway", "name": "Rampe A", "phone": "555"}},
        {"type": "node", "id": 2, "lat": 39.0, "lon": -90.2, "tags": {"leisure": "slipway", "access": "private"}},
        {"type": "way", "id": 3, "center": {"lat": 40.0, "lon": -89.0}, "tags": {"amenity": "boat_ramp"}},
        {"type": "node", "id": 4, "lat": 41.0, "lon": -88.0, "tags": {"leisure": "slipway", "access": "no"}}]}

    def test_prive_ecarte_et_aucun_tag_copie(self):
        doc = osm_il.construire(self.REP, "2026-11-07")
        feats = doc["couches"][0]["collection"]["features"]
        self.assertEqual([f["properties"]["id"] for f in feats], ["osm-il:n1", "osm-il:w3"])
        self.assertNotIn("555", json.dumps(doc))
        self.assertEqual(doc["couches"][0]["licence"], "ODbL 1.0, © contributeurs OpenStreetMap")

    def test_texte_de_source_ne_dit_pas_agence(self):
        c = osm_il.construire(self.REP, "2026-11-07")["couches"][0]
        self.assertTrue(c["source"].startswith("point cartographié par OpenStreetMap"))
        self.assertNotIn("listé par", c["source"])


if __name__ == "__main__":
    unittest.main()
