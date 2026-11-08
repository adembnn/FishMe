"""Tests hors réseau de embarquer.py (US11) et des fichiers réellement embarqués dans Core/Resources/geo-us/."""
import json
import os
import re
import sys
import tempfile
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))

import embarquer as emb  # noqa: E402

RACINE = os.path.abspath(os.path.join(ICI, "..", "..", "..", ".."))
GEO_US = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "geo-us")
DONNEES_MD = os.path.join(RACINE, "docs", "donnees.md")
MOTS_INTERDITS = re.compile(r"autoris|allowed|legal|libre|tu peux la garder|you can keep it", re.I)

CARRE = [[-90.0, 44.0], [-89.0, 44.0], [-89.0, 45.0], [-90.0, 45.0], [-90.0, 44.0]]


def polygone(anneau):
    return dict(type="Polygon", coordinates=[anneau])


def lac(ident, nom, aire, anneau):
    return dict(type="Feature", geometry=polygone(anneau), properties=dict(id3dhp=ident, gnisidlabel=nom, areasqkm=aire))


def doc_acces():
    def feat(i, nom, type_, lon, lat, eau=None):
        p = dict(id=i, nom=nom, type=type_)
        if eau:
            p["eau"] = eau
        return dict(type="Feature", geometry=dict(type="Point", coordinates=[lon, lat]), properties=p)
    return dict(couches=[
        dict(id="acces", role="acces", statut="ok", source="WI DNR, Boat Access Sites", licence="[?] non précisée",
             url_source="https://exemple.test/a", collection=dict(features=[
                 feat("wi-boat:1", "Clear Lake Public Access", "rampe", -89.5, 44.5),
                 feat("wi-boat:2", "", "acces_portage", -89.6, 44.6, eau="Little Lake"),
                 feat("wi-boat:2", "doublon", "rampe", -89.6, 44.6),
                 feat("wi-boat:3", "", "inconnu", -89.7, 44.7)])),
        dict(id="peche_rive", role="acces", statut="ok", source="WI DNR, Shore Fishing Sites", licence="[?] non précisée",
             url_source="https://exemple.test/b", collection=dict(features=[feat("wi-shore:9", "Mauthe Lake Pier", "peche_rive", -88.8, 43.7)])),
        dict(id="traces", role="traces", statut="ok", source="x", licence="x", url_source="x", collection=dict(features=[])),
    ])


class TestGeometrie(unittest.TestCase):
    def test_point_dans_anneau(self):
        self.assertTrue(emb.dans_anneau(-89.5, 44.5, CARRE))
        self.assertFalse(emb.dans_anneau(-88.0, 44.5, CARRE))
        self.assertFalse(emb.dans_anneau(-89.5, 46.0, CARRE))

    def test_contour_absent_ne_filtre_pas(self):
        self.assertTrue(emb.dans_etat(0, 0, None))
        self.assertFalse(emb.dans_etat(-88.0, 44.5, [CARRE]))

    def test_centre_et_rayon(self):
        lat, lon = emb.centre_polygone(polygone(CARRE))
        self.assertAlmostEqual(lat, 44.5, places=6)
        self.assertAlmostEqual(lon, -89.5, places=6)
        # un lac de 1 km2 : le cercle de même surface a un rayon de 564 m
        self.assertAlmostEqual(emb.rayon_metres(1.0), 564.19, places=1)
        self.assertEqual(emb.rayon_metres(-3), 0)


class TestCouches(unittest.TestCase):
    def test_points(self):
        d = emb.construire_points("WI", doc_acces(), "2026-11-07")
        self.assertEqual(d["compte"], 4)
        ids = [r[0] for r in d["points"]]
        self.assertEqual(ids, sorted(ids))
        self.assertEqual(len(ids), len(set(ids)), "pas de doublon")
        par_id = dict((r[0], r) for r in d["points"])
        self.assertEqual(par_id["wi-boat:1"][4], "rampe")
        self.assertEqual(par_id["wi-boat:2"][4], "accesPublic")
        self.assertEqual(par_id["wi-boat:2"][1], "Little Lake", "nom absent : repli sur le nom de l'eau")
        self.assertEqual(par_id["wi-boat:3"][1], "Accès sans nom")
        self.assertEqual(par_id["wi-boat:3"][4], "autre")
        self.assertEqual(par_id["wi-shore:9"][4], "quai")
        self.assertEqual(len(d["sources"]), 2, "les couches de rôle traces sont ignorées")
        for s in d["sources"]:
            self.assertTrue(s["texte"].startswith("accès public listé par Wisconsin DNR"))
            self.assertEqual(s["date"], "2026-11-07")
            self.assertTrue(s["licence"])
        self.assertIsNone(MOTS_INTERDITS.search(json.dumps(d, ensure_ascii=False)))

    def test_plans_eau(self):
        petit = [[-89.5, 44.5], [-89.49, 44.5], [-89.49, 44.51], [-89.5, 44.51], [-89.5, 44.5]]
        dehors = [[-80.5, 40.5], [-80.49, 40.5], [-80.49, 40.51], [-80.5, 40.51], [-80.5, 40.5]]
        feats = [lac("a", "Lac Un", 1.0, petit), lac("b", "", 1.0, petit), lac("c", "Lac Dehors", 1.0, dehors),
                 lac("a", "Lac Un bis", 1.0, petit), lac("d", "Lac Sans Aire", None, petit)]
        cfg = dict(source="USGS", editeur="USGS", url_source="u", licence="[?]", lien_agence="https://exemple.test")
        d = emb.construire_plans_eau("WI", feats, [CARRE], cfg, "2026-11-07")
        self.assertEqual(d["compte"], 1)
        r = d["plans_eau"][0]
        self.assertEqual(r[:2], ["3dhp:a", "Lac Un"])
        self.assertEqual(r[4], 564)
        self.assertEqual(d["lien_agence"], "https://exemple.test")

    def test_lignes(self):
        def ligne(ident, nom, ordre, pts):
            return dict(type="Feature", geometry=dict(type="LineString", coordinates=pts),
                        properties=dict(id3dhp=ident, gnisidlabel=nom, streamorder=ordre))
        droite = [[-89.5 + i * 0.001, 44.5] for i in range(50)]
        feats = [ligne("a", "Wolf River", 5, droite), ligne("b", "Petit Ruisseau", 2, droite), ligne("c", "", 6, droite),
                 ligne("d", "Hors Etat", 5, [[-80.0, 40.0], [-80.1, 40.1]])]
        cfg = dict(source="USGS", editeur="USGS", url_source="u", licence="[?]")
        d = emb.construire_lignes("WI", feats, [CARRE], cfg, "2026-11-07")
        self.assertEqual(d["compte"], 1)
        r = d["lignes"][0]
        self.assertEqual(r[1], "Wolf River")
        self.assertEqual(len(r[3]), 2, "une droite se réduit à ses deux bouts")

    def test_avis_renvoi_sans_epa(self):
        d = emb.construire_avis("WI", doc_acces(), "2026-11-07")
        self.assertEqual(d["compte"], 1)
        planid, texte, date, lien = d["avis"][0]
        self.assertIsNone(planid)
        self.assertEqual(date, "2026-11-07")
        self.assertTrue(lien.startswith("https://"))
        self.assertIsNone(MOTS_INTERDITS.search(texte))
        self.assertIsNone(emb.construire_avis("ZZ", doc_acces(), "2026-11-07"), "État inconnu : pas d'avis inventé")

    def test_etats_json(self):
        with tempfile.TemporaryDirectory() as brut, tempfile.TemporaryDirectory() as sortie:
            with open(os.path.join(brut, "contour-WI.json"), "w") as f:
                json.dump([CARRE], f)
            open(os.path.join(sortie, "WI-points.json"), "w").close()
            e = emb.construire_etats(brut, sortie)
        self.assertEqual(len(e["etats"]), 1)
        self.assertEqual(e["etats"][0]["bbox"], [-90.0, 44.0, -89.0, 45.0])


class TestFichiersEmbarques(unittest.TestCase):
    """Ce qui est réellement dans geo-us/ : taille, mentions de source, licence, date, vocabulaire, une ligne par fichier dans donnees.md."""

    def fichiers(self):
        if not os.path.isdir(GEO_US):
            self.skipTest("geo-us/ absent")
        return sorted(f for f in os.listdir(GEO_US) if f.endswith(".json"))

    def test_taille_totale(self):
        total = sum(os.path.getsize(os.path.join(GEO_US, f)) for f in self.fichiers())
        self.assertLessEqual(total, 60 * 1000 * 1000)  # décision de Titouan (8 nov.) : lignes d'eau réduites à ~30 Mo, le reste (accès, plans d'eau) ~6 Mo

    def test_wi_et_mn_ont_leurs_couches(self):
        noms = self.fichiers()
        for etat in ("WI", "MN"):
            for couche in ("points", "plans-eau", "lignes-eau", "avis"):
                self.assertIn(f"{etat}-{couche}.json", noms)
        self.assertIn("etats.json", noms)

    def test_chaque_fichier_a_source_licence_date(self):
        for nom in self.fichiers():
            with open(os.path.join(GEO_US, nom), encoding="utf-8") as f:
                d = json.load(f)
            self.assertEqual(d["format"], emb.FORMAT, nom)
            if nom == "etats.json":
                self.assertTrue(d["source"] and d["licence"], nom)
                continue
            self.assertRegex(d["date"], r"^\d{4}-\d{2}-\d{2}$", nom)
            if nom.endswith("-points.json"):
                self.assertTrue(d["sources"], nom)
                for s in d["sources"]:
                    self.assertTrue(s["texte"] and s["licence"] and s["url"], nom)
                    self.assertRegex(s["date"], r"^\d{4}-\d{2}-\d{2}$", nom)
                    self.assertTrue(s["texte"].startswith(("accès public listé par", "point cartographié par OpenStreetMap")), nom)
            else:
                self.assertTrue(d["source"] and d["licence"] and d["url_source"], nom)

    def test_aucun_mot_interdit(self):
        for nom in self.fichiers():
            with open(os.path.join(GEO_US, nom), encoding="utf-8") as f:
                texte = f.read()
            # les noms de lieux peuvent contenir { Legal } ou { Free } : on ne contrôle que les champs de mention
            d = json.loads(texte)
            champs = [str(d.get(k, "")) for k in ("mention", "source", "licence")]
            champs += [s["texte"] for s in d.get("sources", [])]
            champs += [r[1] for r in d.get("avis", [])]
            for c in champs:
                self.assertIsNone(MOTS_INTERDITS.search(c), f"{nom} : {c[:80]}")

    def test_donnees_md_a_une_ligne_par_fichier(self):
        with open(DONNEES_MD, encoding="utf-8") as f:
            md = f.read()
        for nom in self.fichiers():
            if nom[:2] not in ("WI", "MN", "MI") and nom != "etats.json":
                continue  # les autres États : lignes générées par generer_donnees_md.py, contrôlées par verifier_couverture.py --donnees
            self.assertIn(f"`geo-us/{nom}`", md, f"{nom} n'est pas décrit dans docs/donnees.md")


if __name__ == "__main__":
    unittest.main()
