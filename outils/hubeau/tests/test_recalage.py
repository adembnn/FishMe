"""Tests de D5 (recalage sur le trace) : python3 -m unittest discover -s outils/hubeau/tests. Aucun reseau, jeux d'essai minuscules."""
import json
import os
import sys
import tempfile
import unittest
from unittest import mock

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ICI)

import recalage as R  # noqa: E402
import trace_sandre  # noqa: E402

M_LAT = 1 / R.M_PAR_DEGRE  # un metre en degres de latitude


def feature(code, nom, *lignes):
    g = {"type": "LineString", "coordinates": lignes[0]} if len(lignes) == 1 else {"type": "MultiLineString", "coordinates": list(lignes)}
    return {"type": "Feature", "properties": {"CdEntiteHydrographique": code, "NomEntiteHydrographique": nom}, "geometry": g}


def trace_de(*features):
    return R.Trace().ajouter_geojson({"type": "FeatureCollection", "features": list(features)})


# Un fleuve horizontal a la latitude 48,5 de la longitude 2,0 a 2,1 (une seule corde de 7 km : on projette sur le segment)
MARNE = feature("F---0100", "La Marne", [[2.0, 48.5], [2.1, 48.5]])


class TestNoms(unittest.TestCase):
    def test_normaliser(self):
        self.assertEqual(R.normaliser("L'Avre"), "avre")
        self.assertEqual(R.normaliser("La Marne"), R.normaliser("marne"))
        self.assertEqual(R.normaliser("Ruisseau de Péri"), "ruisseau de peri")
        self.assertEqual(R.normaliser(None), "")

    def test_plan_d_eau(self):
        self.assertTrue(R.est_plan_d_eau("Lac de Créteil"))
        self.assertTrue(R.est_plan_d_eau("Étang de Saint-Quentin"))
        self.assertFalse(R.est_plan_d_eau("La Marne"))
        self.assertFalse(R.est_plan_d_eau("Le Lacour"))


class TestProjection(unittest.TestCase):
    def test_projection_sur_le_segment_pas_sur_un_sommet(self):
        t = trace_de(MARNE)
        r = R.recaler_station(48.5 + 100 * M_LAT, 2.05, "La Marne", "F---0100", t)
        self.assertTrue(r["recalee"])
        self.assertAlmostEqual(r["ecart_m"], 100, delta=1)
        self.assertAlmostEqual(r["lat"], 48.5, places=4)
        self.assertAlmostEqual(r["lon"], 2.05, places=4)  # le milieu, a 3,5 km des deux sommets

    def test_300_m_au_plus(self):
        t = trace_de(MARNE)
        dedans = R.recaler_station(48.5 + 299 * M_LAT, 2.05, "La Marne", "F---0100", t)
        dehors = R.recaler_station(48.5 + 310 * M_LAT, 2.05, "La Marne", "F---0100", t)
        self.assertTrue(dedans["recalee"])
        self.assertFalse(dehors["recalee"])

    def test_non_recalee_garde_l_arrondi_et_le_nom(self):
        t = trace_de(MARNE)
        r = R.recaler_station(48.51234, 2.05678, "La Marne", "F---0100", t)
        self.assertEqual((r["lat"], r["lon"], r["eau"], r["recalee"]), (48.51, 2.06, "La Marne", False))

    def test_recalee_a_5_decimales_et_nom_du_trace(self):
        t = trace_de(feature("A1", "L'Avre", [[2.0, 48.5], [2.1, 48.5]]))
        r = R.recaler_station(48.50007, 2.0512345, "Avre", "A1", t)
        self.assertTrue(r["recalee"])
        self.assertEqual(r["eau"], "L'Avre")
        self.assertEqual(r["lon"], round(r["lon"], 5))
        self.assertEqual(r["lon"], 2.05123)

    def test_multilinestring_prend_la_ligne_la_plus_proche(self):
        t = trace_de(feature("B1", "Le Bras", [[2.0, 48.5], [2.01, 48.5]], [[2.0, 48.502], [2.01, 48.502]]))
        r = R.recaler_station(48.5019, 2.005, "Le Bras", "B1", t)
        self.assertAlmostEqual(r["lat"], 48.502, places=4)

    def test_pas_de_deux_decimales_parmi_les_true(self):
        # le trace passe exactement sur 48,50 : la projection tomberait sur 48.50000 (= un arrondi a 0,01)
        t = trace_de(feature("C1", "Le Ru", [[2.0, 48.5], [2.1, 48.5]]))
        r = R.recaler_station(48.5002, 2.0537, "Le Ru", "C1", t)
        self.assertTrue(r["recalee"])
        self.assertFalse(R.a_deux_decimales_ou_moins(r["lat"]))
        self.assertLess(abs(r["lat"] - 48.5), 2e-5)


class TestChoixDuCoursDEau(unittest.TestCase):
    def test_le_code_d_abord_meme_si_un_homonyme_est_plus_proche(self):
        # deux cours d'eau « Le Ru » ; la station est a 20 m de l'un (code X) mais son code est celui de l'autre (Y), a 150 m
        t = trace_de(feature("X", "Le Ru", [[2.0, 48.5], [2.1, 48.5]]),
                     feature("Y", "Le Ru", [[2.0, 48.5 - 170 * M_LAT], [2.1, 48.5 - 170 * M_LAT]]))
        r = R.recaler_station(48.5 - 20 * M_LAT, 2.05, "Le Ru", "Y", t)
        self.assertTrue(r["recalee"])
        self.assertAlmostEqual(r["ecart_m"], 150, delta=1)
        self.assertEqual(r["regle"], "code")

    def test_code_connu_mais_trop_loin_donc_false_sans_essayer_le_nom(self):
        t = trace_de(feature("X", "Le Ru", [[2.0, 48.5], [2.1, 48.5]]),
                     feature("Y", "Le Ru", [[2.0, 48.6], [2.1, 48.6]]))
        r = R.recaler_station(48.5 + 10 * M_LAT, 2.05, "Le Ru", "Y", t)  # tout pres de X mais Y est a 11 km
        self.assertFalse(r["recalee"])

    def test_repli_par_le_nom_quand_le_code_manque_au_trace(self):
        t = trace_de(MARNE)
        r = R.recaler_station(48.5 + 50 * M_LAT, 2.05, "Marne", "CODE-INCONNU", t)
        self.assertTrue(r["recalee"])
        self.assertEqual(r["regle"], "nom")
        self.assertEqual(r["eau"], "La Marne")

    def test_pas_de_repli_par_le_nom_pour_un_plan_d_eau(self):
        t = trace_de(feature("L1", "Lac de Créteil", [[2.0, 48.5], [2.1, 48.5]]))
        r = R.recaler_station(48.5 + 50 * M_LAT, 2.05, "Lac de Créteil", None, t)
        self.assertFalse(r["recalee"])
        self.assertEqual(r["eau"], "Lac de Créteil")

    def test_station_sans_cours_d_eau_sans_voisinage(self):
        r = R.recaler_station(48.5 + 5 * M_LAT, 2.05, None, None, trace_de(MARNE))
        self.assertFalse(r["recalee"])
        self.assertEqual((r["lat"], r["lon"]), (48.5, 2.05))


class TestVoisinage(unittest.TestCase):
    def voisinage(self, *features):
        v = R.Voisinage()
        v.cellules[R.cellule(48.5, 2.05)] = trace_de(*features)
        return v

    def test_station_sans_cours_d_eau_rattachee_a_moins_de_50_m(self):
        v = self.voisinage(MARNE)
        r = R.recaler_station(48.5 + 30 * M_LAT, 2.05, None, None, trace_de(), voisinage=v)
        self.assertTrue(r["recalee"])
        self.assertEqual((r["eau"], r["regle"]), ("La Marne", "voisin"))

    def test_station_sans_cours_d_eau_a_100_m_reste_false(self):
        v = self.voisinage(MARNE)
        r = R.recaler_station(48.5 + 100 * M_LAT, 2.05, None, None, trace_de(), voisinage=v)
        self.assertFalse(r["recalee"])

    def test_trace_voisin_sans_nom_donne_recalee_false_avec_motif(self):
        sans_nom = feature("F---0200", None, [[2.0, 48.5], [2.1, 48.5]])
        v = self.voisinage(sans_nom)
        r = R.recaler_station(48.5 + 30 * M_LAT, 2.05, None, None, trace_de(), voisinage=v)
        self.assertFalse(r["recalee"])
        self.assertEqual((r["lat"], r["lon"], r["eau"]), (48.5, 2.05, None))  # arrondi a 0,01, pas de nom invente
        self.assertEqual(r["motif"], "voisin_sans_nom")
        st = [{"id": "1", "lat": 48.5 + 30 * M_LAT, "lon": 2.05, "dep": "94", "eau": None, "code_eau": None}]
        rap = R.recaler_stations(st, trace_de(), voisinage=v)
        self.assertEqual((rap["recalees"], rap["raisons_false"]["voisin_sans_nom"], rap["raisons_false"]["sans_cours_d_eau"]), (0, 1, 0))
        self.assertIs(st[0]["recalee"], False)

    def test_le_voisinage_ne_sert_pas_aux_stations_qui_ont_un_cours_d_eau(self):
        v = self.voisinage(MARNE)
        r = R.recaler_station(48.5 + 10 * M_LAT, 2.05, "Autre", "ZZ", trace_de(), voisinage=v)
        self.assertFalse(r["recalee"])


class TestFichier(unittest.TestCase):
    def stations(self):
        return [{"id": "1", "lat": 48.5001, "lon": 2.0512, "dep": "94", "eau": "La Marne", "code_eau": "F---0100"},
                {"id": "2", "lat": 48.9, "lon": 2.0512, "dep": "94", "eau": "La Marne", "code_eau": "F---0100"},
                {"id": "3", "lat": 48.4, "lon": 2.0, "dep": "94", "eau": None, "code_eau": None}]

    def test_compte_et_champ_recalee_sur_toutes(self):
        st = self.stations()
        rap = R.recaler_stations(st, trace_de(MARNE))
        self.assertTrue(all("recalee" in s for s in st))
        self.assertEqual((rap["recalees"], rap["non_recalees"]), (1, 2))
        self.assertEqual(rap["raisons_false"]["trop_loin"], 1)
        self.assertEqual(rap["raisons_false"]["sans_cours_d_eau"], 1)
        self.assertEqual([s["id"] for s in st], ["1", "2", "3"])  # aucune station supprimee

    def test_ligne_de_commande_et_refus_d_un_fichier_deja_recale(self):
        with tempfile.TemporaryDirectory() as d:
            entree, sortie, trace = (os.path.join(d, n) for n in ("in.json", "out.json", "trace.geojson"))
            with open(entree, "w") as f:
                json.dump({"stations": self.stations()}, f)
            with open(trace, "w") as f:
                json.dump({"type": "FeatureCollection", "features": [MARNE]}, f)
            with mock.patch("sys.stdout"):
                self.assertEqual(R.main([entree, sortie, "--trace", trace]), 0)
                with open(sortie) as f:
                    doc = json.load(f)
                self.assertEqual([s["recalee"] for s in doc["stations"]], [True, False, False])
                self.assertEqual(R.main([sortie, os.path.join(d, "bis.json"), "--trace", trace]), 2)


class TestTelechargement(unittest.TestCase):
    def test_filtre_et_url(self):
        u = trace_sandre.url_paquet(["F---0100", "A1"])
        self.assertIn("CoursEau_FXX", u)
        self.assertIn("F---0100", trace_sandre.filtre_codes(["F---0100", "A1"]))
        self.assertIn("<Or>", trace_sandre.filtre_codes(["F---0100", "A1"]))
        self.assertNotIn("<Or>", trace_sandre.filtre_codes(["A1"]))

    def test_cache_par_paquet_une_requete_a_la_fois_sans_reseau(self):
        appels = []

        def faux(url, *a, **k):
            appels.append(url)
            return b'{"type":"FeatureCollection","features":[]}'

        with tempfile.TemporaryDirectory() as d, mock.patch.object(trace_sandre, "_obtenir", faux), \
                mock.patch.object(trace_sandre.time, "sleep") as dodo:
            codes = [f"C{i:03d}" for i in range(60)]
            ch = trace_sandre.telecharger(codes, d, log=lambda m: None)
            self.assertEqual(len(ch), 3)  # 25 + 25 + 10
            self.assertEqual(len(appels), 3)
            self.assertEqual(dodo.call_count, 2)  # pause entre deux requetes, pas avant la premiere
            trace_sandre.telecharger(codes, d, log=lambda m: None)
            self.assertEqual(len(appels), 3)  # relance : tout vient du cache

    def test_attente_longue_et_croissante_sur_429_503(self):
        import email.message
        import urllib.error
        h = email.message.Message()
        h["Retry-After"] = "120"
        e429 = urllib.error.HTTPError("u", 429, "Too Many", h, None)
        e503 = urllib.error.HTTPError("u", 503, "Unavail", email.message.Message(), None)
        self.assertEqual(trace_sandre._attente(0, e429), 120.0)
        self.assertEqual([trace_sandre._attente(k, e503) for k in range(3)], [30.0, 60.0, 120.0])
        self.assertEqual(trace_sandre._attente(1, ValueError("x")), 20.0)

    def test_cellule(self):
        self.assertEqual(trace_sandre.cellule(48.52, 2.07), (41, 970))
        for lat, lon in ((48.5, 2.05), (43.123, -1.4), (48.8199, 2.4999)):
            self.assertEqual(trace_sandre.cellule(lat, lon), R.cellule(lat, lon))


if __name__ == "__main__":
    unittest.main()
