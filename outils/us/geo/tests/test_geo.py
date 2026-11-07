"""Tests hors réseau (fixtures = réponses réelles minuscules enregistrées le 2026-11-07).
Lancer : cd outils/us/geo && python3 -m unittest discover -s tests -v
Test réseau facultatif : FISHME_GEO_RESEAU=1 (interroge le service MN, quelques objets).
"""
import copy
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import arcgis  # noqa: E402
import construire_etat as ce  # noqa: E402
import normaliser as nz  # noqa: E402
import verifier_geo as vg  # noqa: E402

with open(os.path.join(ICI, "fixtures", "reponses.json"), encoding="utf-8") as f:
    FIX = json.load(f)


def faux_http(corpus):
    """corpus : {sous-chaîne d'URL : liste de features}. Imite returnCountOnly, returnIdsOnly, objectIds et la fiche de couche."""
    appels = []

    def http(url, params=None, post=False, **kw):
        appels.append((url, dict(params or {}), post))
        feats = None
        for cle, v in corpus.items():
            if cle in url:
                feats = v
        if feats is None:
            raise RuntimeError("URL inconnue " + url)
        p = params or {}
        if not url.endswith("/query"):
            return {"fields": FIX["mn_meta"]["fields"] if "loc_water" in url else []}
        if p.get("returnCountOnly"):
            return {"count": len(feats)}
        if p.get("returnIdsOnly"):
            return {"objectIds": list(range(1, len(feats) + 1))}
        ids = [int(x) for x in p["objectIds"].split(",")]
        assert post, "les objets se demandent en POST"
        return {"type": "FeatureCollection", "features": [feats[i - 1] for i in ids]}
    http.appels = appels
    return http


class TestNormaliser(unittest.TestCase):
    def test_acces_mn(self):
        dom = {x["name"]: x["domain"]["codedValues"] for x in FIX["mn_meta"]["fields"]}
        n = nz.acces_mn_swas(FIX["mn_acces"][0], dom)
        p = n["properties"]
        self.assertTrue(p["id"].startswith("mn-swas:WAS"))
        self.assertEqual(p["coin"], "acces")
        self.assertEqual(p["type"], "rampe")  # boat_launch_method 2 = Trailer Launch (domaine lu dans la fiche)
        self.assertNotIn("directions", p)
        self.assertNotIn("comments", p)

    def test_acces_wi_et_mi(self):
        n = nz.acces_wi_bateau(FIX["wi_acces"][0])
        self.assertTrue(n["properties"]["id"].startswith("wi-boat:"))
        self.assertNotIn("OWNERSHIP_MANAGER_PHONE_TEXT", n["properties"])
        self.assertFalse(any(vg.RE_TEL.search(str(v)) for v in n["properties"].values()))
        m = nz.acces_mi_prd(FIX["mi_acces"][0])
        self.assertTrue(m["properties"]["id"].startswith("mi-bas:"))
        self.assertNotIn("phone", m["properties"])

    def test_wi_abandonne_ignore(self):
        f = copy.deepcopy(FIX["wi_acces"][0])
        f["properties"]["ABANDON_FLAG"] = "Yes"
        self.assertIsNone(nz.acces_wi_bateau(f))

    def test_trace_plan_pad(self):
        self.assertTrue(nz.trace_3dhp(FIX["3dhp_traces"][0])["properties"]["id"].startswith("3dhp:"))
        self.assertIn("surface_km2", nz.plan_eau_3dhp(FIX["3dhp_plans"][0])["properties"])
        pad = nz.terre_publique_pad(FIX["pad_main"][0])["properties"]
        self.assertEqual(pad["acces"], "restreint")
        self.assertEqual(pad["id"], "padus:04a07cee-7ce7-4b2f-8a08-adc64d6fd6e3")

    def test_empoissonnement_wi(self):
        p = nz.empoissonnement_wi(FIX["wi_stock"][0])["properties"]
        self.assertEqual(p["type"], "empoissonnement")
        self.assertIsInstance(p["derniere_annee"], int)
        self.assertNotIn("STOCKING_RECORDS_JSON", p)

    def test_arrondi_et_doublons(self):
        g = nz.arrondir({"type": "LineString", "coordinates": [[-94.123456789, 46.1234567], [-94.12346, 46.12346], [-94.2, 46.3]]}, 4)
        self.assertEqual(g["coordinates"], [[-94.1235, 46.1235], [-94.2, 46.3]])
        self.assertEqual(nz.arrondir({"type": "Point", "coordinates": [-94.1234567, 46.1234567]}, 5)["coordinates"], [-94.12346, 46.12346])

    def test_simplifier_et_rogner(self):
        ligne = {"type": "LineString", "coordinates": [[0, 0], [1, 0.0001], [2, 0], [3, 5]]}
        self.assertEqual(len(nz.simplifier(ligne, 0.01)["coordinates"]), 3)
        mp = {"type": "MultiPolygon", "coordinates": [
            [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]], [[[50, 50], [51, 50], [51, 51], [50, 51], [50, 50]]]]}
        self.assertEqual(len(nz.rogner_aux_parties(mp, (-1, -1, 2, 2))["coordinates"]), 1)
        self.assertIsNone(nz.rogner_aux_parties(mp, (10, 10, 11, 11)))


class TestArcgis(unittest.TestCase):
    def test_pagination_par_identifiants(self):
        feats = [{"type": "Feature", "geometry": None, "properties": {"i": i}} for i in range(7)]
        http = faux_http({"/MapServer/0": feats})
        sortie, total = arcgis.telecharger("https://x/MapServer", 0, (-1, -1, 1, 1), paquet=3, http=http, pause=0, log=lambda *a: None)
        self.assertEqual((len(sortie), total), (7, 7))
        posts = [a for a in http.appels if a[2]]
        self.assertEqual(len(posts), 3)  # 3 + 3 + 1
        self.assertEqual(posts[0][1]["outSR"], 4326)
        self.assertEqual(posts[0][1]["f"], "geojson")

    def test_max_objets(self):
        feats = [{"type": "Feature", "geometry": None, "properties": {}} for _ in range(10)]
        sortie, total = arcgis.telecharger("https://x/MapServer", 0, None, max_objets=4, http=faux_http({"/0": feats}), pause=0, log=lambda *a: None)
        self.assertEqual((len(sortie), total), (4, 10))


class TestConstruction(unittest.TestCase):
    def corpus(self):
        return {"loc_water_access_sites": FIX["mn_acces"], "3DHP_all/MapServer/50": FIX["3dhp_traces"],
                "3DHP_all/MapServer/60": FIX["3dhp_plans"], "US_PAD": FIX["pad_main"]}

    def test_etat_complet_et_verification(self):
        doc = ce.construire("MN", emprise=[-94.30, 46.50, -94.24, 46.56], http=faux_http(self.corpus()), log=lambda *a: None, dormir=lambda s: None)
        par_id = {c["id"]: c for c in doc["couches"]}
        self.assertEqual(par_id["acces"]["compte"], 4)
        self.assertEqual(par_id["avis_consommation"]["statut"], "absent_du_service")  # l'EPA ne couvre pas le MN
        self.assertEqual(par_id["empoissonnement"]["statut"], "absent")
        err, avert = vg.verifier_doc(doc)
        self.assertEqual(err, [], err)
        self.assertTrue(any("licence" in a for a in avert))
        err_strict, _ = vg.verifier_doc(doc, strict=True)
        self.assertTrue(err_strict)  # licences [?] : refus en mode strict

    def test_ecriture_petit_fichier(self):
        import tempfile
        doc = ce.construire("MN", emprise=[-94.30, 46.50, -94.24, 46.56], http=faux_http(self.corpus()), log=lambda *a: None, dormir=lambda s: None)
        with tempfile.TemporaryDirectory() as d:
            chemin = ce.ecrire(doc, d)
            self.assertLess(os.path.getsize(chemin), 200_000)
            self.assertEqual(vg.main([chemin]), 0)

    def test_configs_etats(self):
        for u in ("MN", "WI", "MI"):
            cfg = ce.charger_config(u)
            ids = [c["id"] for c in cfg["couches"]]
            self.assertEqual(len(ids), len(set(ids)))
            roles = {c["role"] for c in cfg["couches"]}
            self.assertTrue({"traces", "plans_eau", "acces", "terres_publiques", "avis_consommation", "empoissonnement"} <= roles, u)
            for c in cfg["couches"]:
                if c.get("statut", "ok") == "ok":
                    for k in ("source", "licence", "date_source", "date_lecture", "url_source", "normaliseur"):
                        self.assertTrue(c.get(k), f"{u}/{c['id']} : {k}")
                    self.assertIn(c["normaliseur"], nz.NORMALISEURS)
            self.assertTrue(vg.dans_us(cfg["emprise"][0], cfg["emprise"][1]) and vg.dans_us(cfg["emprise"][2], cfg["emprise"][3]))


class TestVerificateur(unittest.TestCase):
    def base(self):
        return ce.construire("MN", emprise=[-94.30, 46.50, -94.24, 46.56], http=faux_http({
            "loc_water_access_sites": FIX["mn_acces"], "3DHP_all/MapServer/50": FIX["3dhp_traces"],
            "3DHP_all/MapServer/60": FIX["3dhp_plans"], "US_PAD": FIX["pad_main"]}), log=lambda *a: None, dormir=lambda s: None)

    def acces(self, doc):
        return next(c for c in doc["couches"] if c["id"] == "acces")

    def test_licence_manquante(self):
        d = self.base()
        self.acces(d)["licence"] = ""
        self.assertTrue(any("licence" in e for e in vg.verifier_doc(d)[0]))

    def test_hors_etats_unis(self):
        d = self.base()
        self.acces(d)["collection"]["features"][0]["geometry"]["coordinates"] = [2.35, 48.85]  # Paris
        self.assertTrue(any("hors des États-Unis" in e for e in vg.verifier_doc(d)[0]))

    def test_hors_emprise_etat(self):
        d = self.base()
        self.acces(d)["collection"]["features"][0]["geometry"]["coordinates"] = [-100.0, 40.0]  # Nebraska, aux US mais pas au MN
        self.assertTrue(any("emprise de l'État" in e for e in vg.verifier_doc(d)[0]))

    def test_compte_incoherent_et_precision(self):
        d = self.base()
        a = self.acces(d)
        a["compte"] += 1
        a["collection"]["features"][1]["geometry"]["coordinates"] = [-94.2812345678, 46.5359293127]
        e = vg.verifier_doc(d)[0]
        self.assertTrue(any("compte" in x for x in e))
        self.assertTrue(any("trop précises" in x for x in e))

    def test_donnee_personnelle(self):
        d = self.base()
        p = self.acces(d)["collection"]["features"][0]["properties"]
        p["gestionnaire"] = "Mairie 262-538-0820"
        self.assertTrue(any("personnelle" in e for e in vg.verifier_doc(d)[0]))
        d = self.base()
        self.acces(d)["collection"]["features"][0]["properties"]["spot"] = "mon coin"
        self.assertTrue(any("personnelle" in e for e in vg.verifier_doc(d)[0]))

    def test_minimum_et_emprise_invalide(self):
        d = self.base()
        self.assertTrue(any("minimum" in e for e in vg.verifier_doc(d, minimums={"acces": 99})[0]))
        d["emprise_etat"] = [10, 40, 11, 41]
        self.assertTrue(any("hors des États-Unis" in e for e in vg.verifier_doc(d)[0]))

    def test_absente_avec_objets(self):
        d = self.base()
        c = next(c for c in d["couches"] if c["id"] == "empoissonnement")
        c["compte"] = 1
        self.assertTrue(any("absente" in e for e in vg.verifier_doc(d)[0]))


@unittest.skipUnless(os.environ.get("FISHME_GEO_RESEAU"), "FISHME_GEO_RESEAU non défini")
class TestReseau(unittest.TestCase):
    def test_mn_reel(self):
        doc = ce.construire("MN", emprise=[-94.35, 46.45, -94.20, 46.60], ids=["acces"], max_objets=5, log=lambda *a: None)
        self.assertGreater(doc["couches"][0]["compte"], 0)
        self.assertEqual(vg.verifier_doc(doc)[0], [])


if __name__ == "__main__":
    unittest.main()
