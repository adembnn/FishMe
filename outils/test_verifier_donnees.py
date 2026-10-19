#!/usr/bin/env python3
"""Tests du chargeur de verifier_donnees.py sur un petit jeu d'essai en mémoire (pas de fichier du dépôt).
Lancer : python3 outils/test_verifier_donnees.py
"""
import os
import sys
import unittest
import unittest.mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import verifier_donnees as vd  # noqa: E402

AVIS = {"texte": "Avis annuel 2026 Val-de-Marne", "url": "http://exemple.test/avis.pdf", "lu_le": "2026-10-15", "version": "avis 2026"}
ARRETE = {"texte": "Arrêté préfectoral 2025/00727, art. 2", "url": "http://exemple.test/arrete.pdf", "lu_le": "2026-10-15", "version": "arrêté 2025"}


def regle(id_, source, cm=None, cat="2", espece="2151", type_="taille_min", niveau="departement", lieu=None, **plus):
    r = {"id": id_, "type": type_, "especes": [espece], "categorie": cat,
         "portee": {"niveau": niveau, "code": "94", "lieu": lieu}, "du": None, "au": None,
         "valeur": {"cm": cm} if cm is not None else {"texte": "x"}, "phrase": f"{id_}", "source": source,
         "citation": f"citation de {id_}", "statut": "brouillon", "expire_le": None, "remplace": None}
    r.update(plus)
    return r


def lecture(regles, lu="entier"):
    return {"version": 2, "departement": "94", "textes": [{"titre": "t", "url": "u", "signe_le": None, "lu": lu}], "regles": regles}


class Chargeur(unittest.TestCase):
    def test_brochet_94_60_vu_par_une_seule_lecture(self):
        """D1.md, test fini 10 : 50 cm confirmé, 60 cm vu par une lecture (catégorie « toutes ») : l'entrée a_verifier existe."""
        r50 = regle("94-bro-50", ARRETE, cm=50)
        cons = {"departement": "94", "regles": [r50],
                "desaccords": {"seulement_a": [], "seulement_b": [regle("94b-bro-60", AVIS, cm=60, cat="toutes")]}}
        f, _ = vd.assembler("94", cons, [lecture([r50]), lecture([r50])], {}, set(), "v")
        self.assertEqual([r["valeur"]["cm"] for r in f["regles"]], [50])
        self.assertEqual(len(f["a_verifier"]), 1)
        a = f["a_verifier"][0]
        self.assertEqual((a["type"], a["especes"], a["categorie"]), ("taille_min", ["2151"], "toutes"))
        self.assertNotIn("valeur", a)
        self.assertNotIn("citation", a)
        self.assertTrue(all(t in {x["id"] for x in f["textes"]} for t in a["textes"]))

    def test_deux_valeurs_confirmees_donnent_candidats(self):
        cons = {"regles": [regle("a", ARRETE, cm=50), regle("b", AVIS, cm=60)], "desaccords": {}}
        f, avert = vd.assembler("94", cons, [lecture([])], {}, set(), "v")
        self.assertEqual(len(f["regles"]), 1)
        r = f["regles"][0]
        self.assertEqual(r["valeur"], {"cm": None, "candidats_cm": [50, 60]})
        self.assertEqual(r["statut"], "incertain")
        self.assertEqual(len(r["textes"]), 2)
        self.assertLessEqual(len(r["citation"]), 300)
        self.assertTrue(avert)

    def test_deux_tailles_du_meme_texte_restent_separees(self):
        """Deux tronçons de la même rivière dans un seul texte : pas de candidats_cm, deux règles."""
        cons = {"regles": [regle("a", ARRETE, cm=23, niveau="troncon", lieu="Maronne : amont"),
                           regle("b", ARRETE, cm=30, niveau="troncon", lieu="Maronne : aval")], "desaccords": {}}
        f, _ = vd.assembler("19", cons, [], {}, set(), "v")
        self.assertEqual(sorted(r["valeur"]["cm"] for r in f["regles"]), [23, 30])

    def test_refus_forme_v1(self):
        r = regle("v1", AVIS, cm=50)
        r["valeur"] = {"periodes": [1, 2]}
        with self.assertRaises(vd.Refus) as e:
            vd.assembler("94", {"regles": [r], "desaccords": {}}, [lecture([])], {}, set(), "v")
        self.assertIn("v1", str(e.exception))

    def test_refus_id_deja_pris(self):
        with self.assertRaises(vd.Refus):
            vd.assembler("94", {"regles": [regle("nat-x", AVIS, cm=50)], "desaccords": {}}, [lecture([])], {}, {"nat-x"}, "v")
        with self.assertRaises(vd.Refus):
            vd.assembler("94", {"regles": [regle("75-x", AVIS, cm=50)], "desaccords": {}}, [lecture([])], {"75-x": "75"}, set(), "v")

    def test_citation_coupee_a_300(self):
        r = regle("long", AVIS, cm=50)
        r["citation"] = "mot " * 200
        f, _ = vd.assembler("94", {"regles": [r], "desaccords": {}}, [lecture([])], {}, set(), "v")
        c = f["regles"][0]["citation"]
        self.assertLessEqual(len(c), 300)
        self.assertTrue(c.endswith("[...]"))

    def test_eau_et_portee(self):
        r = regle("m", AVIS, type_="categorie", niveau="troncon", lieu="Mauldre (Mareil-sur-Mauldre) : en amont du pont-route", cat="1")
        r["valeur"] = {"classe": "1"}
        f, _ = vd.assembler("78", {"regles": [r], "desaccords": {}}, [lecture([])], {}, set(), "v")
        self.assertEqual(f["regles"][0]["portee"]["eau"], "mauldre")
        self.assertEqual(f["eaux"], [{"cle": "mauldre", "nom": "Mauldre", "code": None}])
        self.assertIsNone(f["regles"][0]["portee"]["geometrie"])
        self.assertEqual(f["regles"][0]["verifie_par"], None)

    def test_une_lecture_tout_en_a_verifier(self):
        lec = lecture([regle("x", AVIS, cm=50), regle("y", AVIS, type_="quota_jour")])
        f, _ = vd.assembler_une_lecture("60", lec, set(), "v")
        self.assertEqual((f["regles"], f["niveau"], len(f["a_verifier"])), ([], "partiel", 2))
        for a in f["a_verifier"]:
            self.assertFalse({"valeur", "citation"} & set(a))

    def test_niveau(self):
        sures = [regle(f"s{i}", AVIS, cm=30 + i, espece=str(i)) for i in range(5)]
        f, _ = vd.assembler("78", {"regles": sures, "desaccords": {}}, [lecture([]), lecture([])], {}, set(), "v")
        self.assertEqual(f["niveau"], "complet")
        f, _ = vd.assembler("78", {"regles": sures, "desaccords": {}}, [lecture([]), lecture([], lu="titre seul")], {}, set(), "v")
        self.assertEqual(f["niveau"], "partiel")

    def test_consensus_seul_sans_lectures(self):
        """Mode regles/local : pas de dep/ ni dep-b/, textes tirés des source, niveau partiel."""
        sures = [regle(f"s{i}", AVIS if i % 2 else ARRETE, cm=30 + i, espece=str(i)) for i in range(5)]
        cons = {"regles": sures, "desaccords": {"seulement_a": [regle("z", AVIS, cm=70, espece="99")], "seulement_b": []}}
        f, _ = vd.assembler("78", cons, [], {}, set(), "v")
        self.assertEqual((f["niveau"], len(f["regles"]), len(f["a_verifier"])), ("partiel", 5, 1))
        self.assertEqual({t["titre"] for t in f["textes"]}, {AVIS["texte"], ARRETE["texte"]})
        for t in f["textes"]:
            self.assertTrue(t["url"] and t["lu_le"] and t["signe_le"] is None)

    def test_protege(self):
        for code in vd.PROTEGES:
            with self.assertRaises(vd.Refus):
                vd.refuser_ecrasement(code, "/nonexistent")


class StationsRecalees(unittest.TestCase):
    """D5 : règles sur stations-especes.json (fichier et tracé minuscules, en dossier temporaire, aucun réseau)."""

    def setUp(self):
        import json
        import tempfile
        self.json = json
        self.dossier = tempfile.TemporaryDirectory()
        self.addCleanup(self.dossier.cleanup)
        self.trace = os.path.join(self.dossier.name, "trace")
        os.makedirs(self.trace)
        f = {"type": "Feature", "properties": {"CdEntiteHydrographique": "F---0100", "NomEntiteHydrographique": "La Marne"},
             "geometry": {"type": "LineString", "coordinates": [[2.0, 48.5], [2.1, 48.5]]}}
        with open(os.path.join(self.trace, "paquet-x.geojson"), "w") as h:
            json.dump({"type": "FeatureCollection", "features": [f]}, h)
        vd.erreurs.clear()
        vd.manques.clear()

    def fichier(self, stations):
        chemin = os.path.join(self.dossier.name, "stations-especes.json")
        with open(chemin, "w") as h:
            self.json.dump({"stations": stations}, h)
        return chemin

    @staticmethod
    def st(i, recalee=True, lat=48.50003, lon=2.05123, eau="La Marne", code="F---0100"):
        return {"id": str(i), "lat": lat, "lon": lon, "dep": "94", "eau": eau, "code_eau": code, "recalee": recalee}

    def lancer(self, stations):
        vd.verifier_stations(self.fichier(stations), self.trace)
        return list(vd.erreurs)

    def test_fichier_conforme(self):
        with unittest.mock.patch("sys.stdout"):
            self.assertEqual(self.lancer([self.st(i, lon=2.0512 + i / 1e5) for i in range(30)]), [])

    def test_station_sans_recalee(self):
        s = self.st(1)
        del s["recalee"]
        e = self.lancer([s, self.st(2)])
        self.assertEqual(len(e), 1)
        self.assertIn("sans champ recalee", e[0])

    def test_moins_de_90_pour_cent(self):
        stations = [self.st(i) for i in range(8)] + [self.st(9, recalee=False, lat=48.5, lon=2.05), self.st(10, recalee=False, lat=48.5, lon=2.05)]
        with unittest.mock.patch("sys.stdout"):
            e = self.lancer(stations)
        self.assertTrue(any("80.0%" in m and "90%" in m for m in e), e)

    def test_true_a_deux_decimales(self):
        with unittest.mock.patch("sys.stdout"):
            e = self.lancer([self.st(i) for i in range(19)] + [self.st(99, lat=48.5, lon=2.05)])
        self.assertTrue(any("2 décimales" in m and "99" in m for m in e), e)

    def test_echantillon_a_plus_de_50_m(self):
        # 100 m au nord du tracé : c'est un true, mais pas à 50 m du tracé
        with unittest.mock.patch("sys.stdout"):
            e = self.lancer([self.st(i, lat=48.50090) for i in range(25)])
        self.assertTrue(e and all("à plus de 50 m" in m for m in e), e)

    def test_nom_different_du_trace(self):
        with unittest.mock.patch("sys.stdout"):
            e = self.lancer([self.st(i, eau="Le Lac") for i in range(25)])
        self.assertTrue(e and all("le tracé s'appelle « La Marne »" in m for m in e), e)

    def test_trace_sans_nom_et_station_sans_eau_sont_egaux(self):
        """Une station rattachée à un tracé sans nom (eau: null) ne doit pas être refusée parce que None != \"\"."""
        f = {"type": "Feature", "properties": {"CdEntiteHydrographique": "F---0200", "NomEntiteHydrographique": ""},
             "geometry": {"type": "LineString", "coordinates": [[2.0, 48.6], [2.1, 48.6]]}}
        with open(os.path.join(self.trace, "paquet-sans-nom.geojson"), "w") as h:
            self.json.dump({"type": "FeatureCollection", "features": [f]}, h)
        stations = [self.st(i, lat=48.60003, lon=2.0512 + i / 1e5, eau=None, code="F---0200") for i in range(25)]
        with unittest.mock.patch("sys.stdout"):
            e = self.lancer(stations)
        self.assertFalse([m for m in e if "le tracé s'appelle" in m], e)

    def test_sans_trace_l_echantillon_est_un_manque(self):
        vd.verifier_stations(self.fichier([self.st(i) for i in range(25)]), os.path.join(self.dossier.name, "vide"))
        self.assertEqual(vd.erreurs, [])
        self.assertEqual(len(vd.manques), 1)

    def test_echantillon_de_20_graine_fixe(self):
        import random
        ids = sorted(str(i) for i in range(50))
        self.assertEqual(random.Random(vd.GRAINE).sample(ids, 20), random.Random(vd.GRAINE).sample(ids, 20))
        self.assertEqual(vd.ECHANTILLON, 20)


if __name__ == "__main__":
    unittest.main(verbosity=1)
