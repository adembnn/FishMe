"""Forme de stations-temperature.json (verifier_donnees.py) : python3 -m unittest discover -s outils/hubeau/tests. Aucun reseau."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

import verifier_donnees as V  # noqa: E402


def station(**kw):
    s = {"code": "03112480", "nom": "LA MARNE A CHARENTON-LE-PONT 2", "eau": "La Marne", "code_eau": "F---0100",
         "lat": 48.816895, "lon": 2.41963, "dep": "94", "en_service": True}
    s.update(kw)
    return s


class FormeTemperature(unittest.TestCase):
    def test_fichier_valide(self):
        self.assertEqual(V.problemes_stations_temperature([station(), station(code="2", en_service=False)]), [])

    def test_eau_et_code_eau_peuvent_etre_null(self):
        self.assertEqual(V.problemes_stations_temperature([station(eau=None, code_eau=None)]), [])

    def test_pas_un_tableau_ou_vide(self):
        self.assertTrue(V.problemes_stations_temperature({"stations": []}))
        self.assertTrue(V.problemes_stations_temperature([]))

    def test_champ_absent(self):
        s = station()
        del s["dep"]
        pb = V.problemes_stations_temperature([s, station(code="2")])
        self.assertTrue(any("dep" in p for p in pb))

    def test_aucune_station_en_service(self):
        pb = V.problemes_stations_temperature([station(en_service=False)])
        self.assertTrue(any("en service" in p for p in pb))

    def test_types_et_position(self):
        self.assertTrue(V.problemes_stations_temperature([station(en_service="oui")]))
        self.assertTrue(V.problemes_stations_temperature([station(lat="48.8")]))
        self.assertTrue(V.problemes_stations_temperature([station(lat=0.0, lon=0.0)]))
        self.assertTrue(V.problemes_stations_temperature([station(), station()]))  # code en double


if __name__ == "__main__":
    unittest.main()
