"""Tests hors réseau : MT, ID, WY (US15, groupe rocheuses-nord)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402
import osm_acces  # noqa: E402

with open(os.path.join(ICI, "fixtures", "rocheuses-nord.json"), encoding="utf-8") as f:
    FIX = json.load(f)


class TestIdaho(unittest.TestCase):
    def test_types_et_filtre(self):
        r = [nz.NORMALISEURS["acces_id_idfg"](f) for f in FIX["id_idfg"]]
        self.assertEqual(r[2], None)  # site fermé
        self.assertEqual(r[0]["properties"]["type"], "acces")
        self.assertEqual(r[0]["properties"]["coin"], "peche")
        self.assertEqual(r[1]["properties"]["type"], "rampe")
        self.assertEqual(r[0]["properties"]["id"], "id-idfg:1")

    def test_pas_de_note_libre(self):
        texte = json.dumps(nz.NORMALISEURS["acces_id_idfg"](FIX["id_idfg"][0]))
        self.assertNotIn("Primitive", texte)
        self.assertNotIn("idahofishandgame", texte)
        self.assertNotIn("11-0221", texte)


class TestWyoming(unittest.TestCase):
    def test_installations(self):
        n = nz.NORMALISEURS["acces_wy_installations"]
        r = [n(f) for f in FIX["wy_installations"]]
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertIsNone(r[1])  # station de nettoyage
        self.assertIsNone(r[2])  # privé
        self.assertEqual(r[3]["properties"]["coin"], "peche")

    def test_riviere_sans_notes_ni_utm(self):
        r = nz.NORMALISEURS["acces_wy_riviere"](FIX["wy_riviere"][0])
        texte = json.dumps(r)
        self.assertEqual(r["properties"]["eau"], "Bighorn River")
        self.assertNotIn("texte libre", texte)
        self.assertNotIn("724797", texte)


class TestMontanaOSM(unittest.TestCase):
    def test_exclusions_et_doublons(self):
        feats = osm_acces.points(FIX["mt_osm"], "MT")
        ids = [f["properties"]["id"] for f in feats]
        self.assertEqual(ids, ["mt-osm:n32290074", "mt-osm:n43705654"])  # chemin à 1 m écarté, privé exclu
        self.assertEqual(feats[1]["properties"]["nom"], "Rampe du lac")
        self.assertNotIn("0000", json.dumps(feats))

    def test_source_et_licence(self):
        cfg = {"nom": "Montana", "emprise": [-116, 44, -104, 49]}
        doc = osm_acces.construire_doc("MT", FIX["mt_osm"], cfg, "2026-11-07")
        c = doc["couches"][0]
        self.assertIn("OpenStreetMap", c["source"])
        self.assertIn("ODbL", c["licence"])
        self.assertEqual(c["date_source"], "2026-11-07")
        self.assertNotRegex(c["source"].lower(), r"agence|agency|listé")


class TestConfigs(unittest.TestCase):
    def test_etats_ont_leur_bloc(self):
        for u in ("MT", "ID", "WY"):
            with open(os.path.join(os.path.dirname(ICI), "etats", f"{u}.json"), encoding="utf-8") as f:
                cfg = json.load(f)
            self.assertEqual(cfg["etat"], u)
            self.assertIn("couverture", cfg)


if __name__ == "__main__":
    unittest.main()
