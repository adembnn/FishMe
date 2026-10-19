import datetime
import io
import json
import os
import tempfile
import unittest
import urllib.error

import stations_temperature as st

FICHE = {"code_station": "03112480", "libelle_station": "LA MARNE A CHARENTON-LE-PONT 2", "longitude": 2.41962979,
         "latitude": 48.816895156, "code_departement": "94", "code_cours_eau": "F---0100",
         "libelle_cours_eau": "La Marne", "date_mise_hors_service": None}
JOUR = datetime.date(2026, 9, 19)


class Convertir(unittest.TestCase):
    def test_format_attendu_par_n3(self):
        e = st.convertir(FICHE, True)
        self.assertEqual(e, {"code": "03112480", "nom": "LA MARNE A CHARENTON-LE-PONT 2", "eau": "La Marne",
                             "code_eau": "F---0100", "lat": 48.816895, "lon": 2.41963, "dep": "94", "en_service": True})

    def test_sans_cours_d_eau(self):
        e = st.convertir({**FICHE, "libelle_cours_eau": None, "code_cours_eau": None}, False)
        self.assertIsNone(e["eau"]); self.assertIsNone(e["code_eau"]); self.assertFalse(e["en_service"])

    def test_sans_coordonnees_ou_code(self):
        self.assertIsNone(st.convertir({**FICHE, "latitude": None}, True))
        self.assertIsNone(st.convertir({**FICHE, "code_station": None}, True))

    def test_nom_par_defaut_le_code(self):
        self.assertEqual(st.convertir({**FICHE, "libelle_station": ""}, True)["nom"], "03112480")


class Construire(unittest.TestCase):
    def test_regle_en_service(self):
        fiches = [FICHE, {**FICHE, "code_station": "A1"}, {**FICHE, "code_station": "A2", "date_mise_hors_service": "2015-01-01"},
                  FICHE]  # doublon ignore
        appels = []
        def mesures(code, depuis):
            appels.append(code); return code == "03112480"
        r = st.construire(fiches, JOUR, a_mesures=mesures, log=lambda *_: None, dormir=lambda s: None)
        self.assertEqual([(s["code"], s["en_service"]) for s in r], [("03112480", True), ("A1", False), ("A2", False)])
        self.assertEqual(appels, ["03112480", "A1"])  # la station hors service n'est pas interrogee

    def test_url_mesures(self):
        u = st.url_mesures_depuis("03112480", JOUR)
        self.assertIn("code_station=03112480", u); self.assertIn("date_debut_mesure=2026-09-19", u); self.assertIn("size=1", u)


class Reseau(unittest.TestCase):
    def test_pages_de_stations(self):
        pages = {1: {"count": 3, "data": [FICHE, FICHE], "next": "x"}, 2: {"count": 3, "data": [FICHE], "next": None}}
        n = []
        def fn(url):
            n.append(url); return pages[len(n)]
        self.assertEqual(len(st.telecharger_stations(log=lambda *_: None, obtenir_fn=fn)), 3)

    def test_attente_croissante(self):
        e429 = urllib.error.HTTPError("u", 429, "x", {}, io.BytesIO())
        e503 = urllib.error.HTTPError("u", 503, "x", {"Retry-After": "40"}, io.BytesIO())
        self.assertLess(st._attente(0, e429), st._attente(1, e429))
        self.assertEqual(st._attente(0, e503), 40.0)
        self.assertLess(st._attente(0, OSError()), st._attente(0, e429))
        self.assertLessEqual(st._attente(20, e429), 300.0)

    def test_ecrire_relisible(self):
        with tempfile.TemporaryDirectory() as d:
            c = os.path.join(d, "a", "s.json")
            st.ecrire([st.convertir(FICHE, True)], c)
            self.assertEqual(json.load(open(c, encoding="utf-8"))[0]["code"], "03112480")


if __name__ == "__main__":
    unittest.main()
