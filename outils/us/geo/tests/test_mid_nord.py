"""Tests hors réseau des normaliseurs de NY, NJ et PA (groupe mid-nord, US15)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
import normaliser  # noqa: E402

with open(os.path.join(ICI, "fixtures", "mid_nord.json"), encoding="utf-8") as _f:
    FIX = json.load(_f)

INTERDITS = ("ne pas copier",)


def sortie(nom, cle):
    n = normaliser.NORMALISEURS[nom]
    return [r for r in (n(f) for f in FIX[cle]) if r]


class TestMidNord(unittest.TestCase):
    def test_ny_trout_polygone_vers_point(self):
        (r,) = sortie("peche_ny_trout", "ny_trout")
        self.assertEqual(r["geometry"]["type"], "Point")
        lon, lat = r["geometry"]["coordinates"]
        self.assertTrue(-73.684 < lon < -73.6838 and 44.9295 < lat < 44.9305)
        self.assertEqual(r["properties"]["id"], "ny-trout:1")
        self.assertEqual(r["properties"]["coin"], "peche")

    def test_ny_lancement_prive_ecarte_et_types(self):
        rs = sortie("acces_ny_lancement", "ny_lancement")
        self.assertEqual([r["properties"]["id"] for r in rs], ["ny-launch:1", "ny-launch:2"])
        self.assertEqual([r["properties"]["type"] for r in rs], ["rampe", "acces_portage"])

    def test_nj_lacs(self):
        rs = sortie("acces_nj_lacs", "nj_lacs")
        self.assertEqual([r["properties"]["type"] for r in rs], ["acces_portage", "rampe"])
        self.assertEqual(rs[0]["properties"]["id"], "nj-lac:28")

    def test_nj_marees_filtre_et_nom(self):
        rs = sortie("acces_nj_marees", "nj_marees")
        self.assertEqual([r["properties"]["id"] for r in rs], ["nj-maree:HART00215", "nj-maree:X1"])
        self.assertEqual(rs[0]["properties"]["nom"], "Sussex St, Harrison Township")
        self.assertEqual(rs[0]["properties"]["type"], "peche_rive")
        self.assertEqual(rs[1]["properties"]["type"], "rampe")

    def test_pa_pfbc_identifiants_uniques_malgre_id_no_zero(self):
        rs = sortie("acces_pa_pfbc", "pa_pfbc")
        ids = [r["properties"]["id"] for r in rs]
        self.assertEqual(len(set(ids)), 3)
        self.assertEqual([r["properties"]["type"] for r in rs], ["rampe", "peche_rive", "acces_portage"])
        self.assertEqual(rs[1]["properties"]["nom"], "Wisecarver Reservoir")

    def test_aucun_champ_libre_copie(self):
        for nom, cle in (("peche_ny_trout", "ny_trout"), ("acces_nj_lacs", "nj_lacs"), ("acces_nj_marees", "nj_marees")):
            for r in sortie(nom, cle):
                self.assertNotIn("ne pas copier", json.dumps(r, ensure_ascii=False))

    def test_configs_sans_mot_interdit(self):
        import verifier_couverture as vc
        for u in ("NY", "NJ", "PA"):
            with open(os.path.join(ICI, "..", "etats", f"{u}.json"), encoding="utf-8") as f:
                cfg = json.load(f)
            for c in cfg["couches"]:
                self.assertIsNone(vc.MOTS.search(c.get("source", "")), (u, c["id"]))


if __name__ == "__main__":
    unittest.main()
