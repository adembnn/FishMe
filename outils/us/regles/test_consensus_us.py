"""Tests de consensus_us.py et verifier_us.py, avec des fixtures écrites à la main (État fictif ZZ).
Lancer depuis la racine du dépôt : python3 -I -m unittest discover -s outils/us/regles -p "test_*.py"
"""
import copy
import importlib.util
import json
import os
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))


def charger(nom):
    spec = importlib.util.spec_from_file_location(nom, os.path.join(ICI, nom + ".py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


c = charger("consensus_us")
v = charger("verifier_us")


def fixture(nom):
    with open(os.path.join(ICI, "fixtures", nom), encoding="utf-8") as f:
        return json.load(f)


def regle(type_="limite_jour", valeur=None, especes=("Walleye",), du=None, au=None, **portee):
    p = {"niveau_portee": "etat", "etat": "ZZ"}
    p.update(portee)
    return {"id": "t", "type": type_, "especes": list(especes), "du": du, "au": au, "valeur": valeur or {"nombre": 5},
            "portee": p, "statut": "brouillon"}


class Concordance(unittest.TestCase):
    def setUp(self):
        self.a, self.b = fixture("ZZ-lecture-a.json"), fixture("ZZ-lecture-b.json")
        self.gardees, self.seules_a, self.seules_b = c.comparer(self.a["regles"], self.b["regles"])

    def ids(self, liste):
        return {r["id"] for r in liste}

    def test_fixtures_valides(self):
        self.assertEqual(list(v.defauts(self.a)), [])
        self.assertEqual(list(v.defauts(self.b)), [])

    def test_regles_concordantes_confirmees(self):
        confirmees = self.ids(self.gardees)
        for i in ("ZZ-lmb-limite-etat", "ZZ-pike-saison-etat", "ZZ-walleye-taille_min-etat", "ZZ-walleye-fenetre-fixture-lake"):
            self.assertIn(i, confirmees)

    def test_pouces_et_centimetres_concordent(self):
        self.assertIn("ZZ-walleye-taille_min-etat", self.ids(self.gardees))

    def test_plage_a_cheval_sur_deux_annees(self):
        a = regle("saison", {}, ["Northern Pike"], "2025-12-01", "2026-03-15")
        b = regle("saison", {}, ["northern pike"], "12-01", "03-15")
        self.assertTrue(c.a_cheval(a))
        self.assertTrue(c.confirme(a, b))
        b["au"] = "03-16"
        self.assertFalse(c.confirme(a, b))

    def test_regle_d_un_lac_noms_differents_ecrits(self):
        self.assertIn("ZZ-walleye-fenetre-fixture-lake", self.ids(self.gardees))
        self.assertIn("ZZ-saintclair-bait", self.ids(self.gardees))  # « St. » = « Saint »

    def test_discordance_de_nombre_va_a_verifier(self):
        self.assertIn("ZZ-perch-limite-etat", self.ids(self.seules_a))
        self.assertIn("b-perch-limit", self.ids(self.seules_b))

    def test_regle_vue_d_un_seul_cote_va_a_verifier(self):
        self.assertIn("ZZ-trout-saison-etat", self.ids(self.seules_a))
        self.assertIn("b-gar-min", self.ids(self.seules_b))
        for r in self.seules_a + self.seules_b:
            self.assertEqual(r["verdict"], "a_verifier")

    def test_incertain_reste_incertain(self):
        r = next(r for r in self.gardees if r["id"] == "ZZ-saintclair-bait")
        self.assertEqual(r["statut"], "incertain")

    def test_aucune_regle_hors_des_deux_lectures(self):
        de_a = [r for r in self.gardees if r.get("confirmee_par_lecture") != "A"]
        self.assertEqual(len(de_a) + len(self.seules_a), len(self.a["regles"]))


class SymetrieEtFormes(unittest.TestCase):
    """Défauts trouvés sur les lectures réelles WI et MN (lot us-consensus, 7 nov. 2026)."""

    def test_regle_fine_de_b_ni_perdue_ni_oubliee(self):
        # A : taille d'État ; B : même taille pour une zone. Avant : la règle de B n'était ni confirmée ni « à vérifier ».
        a = dict(regle("taille_min", {"pouces": 15}), id="a1")
        b = dict(regle("taille_min", {"pouces": 15}, zone="Most other inland waters", niveau_portee="zone"), id="b1")
        gardees, seules_a, seules_b = c.comparer([a], [b])
        self.assertEqual([r["id"] for r in gardees], ["b1"])
        self.assertEqual(gardees[0]["confirmee_par_lecture"], "A")
        self.assertEqual([r["id"] for r in seules_a], ["a1"])
        self.assertEqual(seules_b, [])

    def test_toute_regle_de_b_est_quelque_part(self):
        a = [dict(regle("taille_min", {"pouces": 15}), id="a1"), dict(regle("saison", {}, du="05-01", au="03-01"), id="a2")]
        b = [dict(regle("taille_min", {"pouces": 15}, zone="Z", niveau_portee="zone"), id="b1"),
             dict(regle("saison", {}, du="05-01", au="03-01"), id="b2"), dict(regle("limite_jour", {"nombre": 9}), id="b3")]
        gardees, _, seules_b = c.comparer(a, b)
        vus = {r["id"] for r in gardees} | {r["id"] for r in seules_b} | {r["lecture_b"]["id"] for r in gardees if "lecture_b" in r}
        self.assertEqual(vus >= {"b1", "b2", "b3"}, True)

    def test_muskie_tigre_distinct_du_muskellunge(self):
        self.assertEqual(c.espece("Tiger Muskellunge"), "tiger muskellunge")
        self.assertEqual(c.espece("muskellunge"), "muskellunge")
        self.assertFalse(c.confirme(regle(especes=["tiger muskellunge"]), regle(especes=["Muskellunge"])))

    def test_crapets_distincts_et_groupe(self):
        self.assertNotEqual(c.espece("green sunfish"), c.espece("orangespotted sunfish"))
        # Le groupe confirme l'espèce, jamais l'inverse.
        self.assertTrue(c.confirme(regle(especes=["Black crappie"]), regle(especes=["Crappie"])))
        self.assertFalse(c.confirme(regle(especes=["Crappie"]), regle(especes=["Black crappie"])))
        self.assertTrue(c.confirme(regle(especes=["bluegill"]), regle(especes=["Sunfish"])))

    def test_limite_datee_confirmee_par_la_meme_limite_sans_date(self):
        datee = regle("limite_possession", {"nombre": 1}, ["muskellunge"], "2026-06-06", "2026-11-30")
        sans = regle("limite_possession", {"nombre": 1}, ["Muskellunge"])
        self.assertTrue(c.confirme(datee, sans))
        self.assertFalse(c.confirme(sans, datee))
        self.assertFalse(c.confirme(regle("limite_possession", {"nombre": 2}, ["muskellunge"], "06-06", "11-30"), sans))
        # Une saison reste comparée date pour date.
        self.assertFalse(c.confirme(regle("saison", {}, ["muskellunge"], "06-06", "11-30"), regle("saison", {}, ["muskellunge"])))

    def test_mots_de_liaison_d_un_code(self):
        a = regle("relacher", {"code": "catch_release_only"}, du="03-01", au="05-22")
        b = regle("relacher", {"code": "catch_and_release_only"}, du="2026-03-01", au="2026-05-22")
        self.assertTrue(c.confirme(a, b))
        self.assertFalse(c.confirme(a, regle("relacher", {"code": "release_only_above"}, du="03-01", au="05-22")))

    def test_parenthese_d_une_zone_ignoree(self):
        a = regle(zone="Northern Zone", niveau_portee="zone")
        b = regle(zone="Northern Zone (north of US Hwy 10)", niveau_portee="zone")
        self.assertTrue(c.confirme(a, b))
        self.assertFalse(c.confirme(a, regle(zone="Southern Zone (south of US Hwy 10)", niveau_portee="zone")))


class Detail(unittest.TestCase):
    def test_unites(self):
        self.assertEqual(c.nombres({"cm": 38.1}), {"taille": 15.0})
        self.assertEqual(c.nombres({"kg": 1}), {"poids": 2.2})
        self.assertTrue(c.memes_nombres(c.nombres({"pouces": 15}), c.nombres({"cm": 38})))
        self.assertFalse(c.memes_nombres(c.nombres({"pouces": 15}), c.nombres({"cm": 40})))

    def test_noms_d_eau(self):
        self.assertEqual(c.mots_eau("St. Clair Lake"), c.mots_eau("Saint Clair"))
        self.assertEqual(c.mots_eau("Lac Léman"), c.mots_eau("Leman Lake"))

    def test_lac_et_riviere_homonymes_distincts(self):
        a = regle(plan_eau="Big Lake", niveau_portee="plan_eau")
        b = regle(plan_eau="Big River", niveau_portee="plan_eau")
        self.assertFalse(c.confirme(a, b))

    def test_deux_comtes_deux_lacs(self):
        a = regle(plan_eau="Mud Lake", comte="Polk", niveau_portee="plan_eau")
        b = regle(plan_eau="Mud Lake", comte="Dane", niveau_portee="plan_eau")
        self.assertFalse(c.confirme(a, b))

    def test_lac_fin_confirme_par_l_etat_seulement_si_chiffre(self):
        lac = regle(plan_eau="Fixture Lake", niveau_portee="plan_eau", valeur={"nombre": 5})
        etat = regle(valeur={"nombre": 5})
        self.assertTrue(c.confirme(lac, etat))
        self.assertFalse(c.confirme(etat, lac))  # l'État ne dit pas ce que dit le lac
        lac_t = regle("appat", {"code": "pas_appat_vivant"}, plan_eau="Fixture Lake", niveau_portee="plan_eau")
        etat_t = regle("appat", {"code": "pas_appat_vivant"})
        self.assertFalse(c.confirme(lac_t, etat_t))

    def test_espece_differente(self):
        self.assertFalse(c.confirme(regle(especes=["Walleye"]), regle(especes=["Sauger"])))
        self.assertEqual(c.espece("Muskie"), "muskellunge")

    def test_toute_l_annee_equivaut_a_sans_date(self):
        self.assertTrue(c.confirme(regle(du="01-01", au="12-31"), regle()))


class Verificateur(unittest.TestCase):
    def setUp(self):
        self.a = fixture("ZZ-lecture-a.json")

    def defauts(self, donnees):
        return list(v.defauts(donnees))

    def test_mot_interdit_dans_la_phrase(self):
        d = copy.deepcopy(self.a)
        d["regles"][0]["phrase"] = "Tu peux la garder si 15 pouces."
        self.assertTrue(any("mot interdit" in x for x in self.defauts(d)))
        d["regles"][0]["phrase"] = "Taille légale : allowed."
        self.assertTrue(any("mot interdit" in x for x in self.defauts(d)))

    def test_citation_libre_de_mots_interdits(self):
        d = copy.deepcopy(self.a)
        d["regles"][0]["citation"] = "Legal length: 15 inches."
        self.assertEqual(self.defauts(d), [])

    def test_source_et_citation_obligatoires(self):
        d = copy.deepcopy(self.a)
        d["regles"][0]["source"] = {"url": "http://x", "date": "hier"}
        d["regles"][1]["citation"] = ""
        sortie = " ".join(self.defauts(d))
        self.assertIn("source.url", sortie)
        self.assertIn("source.date", sortie)
        self.assertIn("citation manquante", sortie)

    def test_verdict_permissif_refuse(self):
        d = copy.deepcopy(self.a)
        d["regles"][0]["verdict"] = "autorise"
        self.assertTrue(any("verdict" in x for x in self.defauts(d)))

    def test_nombre_en_texte_refuse_et_niveau_incoherent(self):
        d = copy.deepcopy(self.a)
        d["regles"][0]["valeur"] = {"pouces": "15"}
        d["regles"][3]["niveau"] = 2
        sortie = " ".join(self.defauts(d))
        self.assertIn("doit être un nombre", sortie)
        self.assertIn("niveau 2 avec un plan d'eau", sortie)


if __name__ == "__main__":
    unittest.main()
