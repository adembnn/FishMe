#!/usr/bin/env python3
"""Tests du chargeur de verifier_donnees.py sur un petit jeu d'essai en mémoire (pas de fichier du dépôt).
Lancer : python3 outils/test_verifier_donnees.py
"""
import os
import sys
import unittest

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

    def test_protege(self):
        for code in vd.PROTEGES:
            with self.assertRaises(vd.Refus):
                vd.refuser_ecrasement(code, "/nonexistent")


if __name__ == "__main__":
    unittest.main(verbosity=1)
