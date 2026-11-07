#!/usr/bin/env python3
"""Rareté américaine : fréquence d'occurrence par HUC8, repli HUC6 puis État, classes par quantiles.

Même algorithme que Packages/Core/Sources/Core/RareteUS/ (Swift) ; bibliothèque standard seulement (Python 3.9+).

CSV d'entrée, un événement d'échantillonnage par ligne (UTF-8, en-tête obligatoire) :
  evenement_id  identifiant de l'événement (un site, un jour, un engin) ; un identifiant répété réunit les espèces
  huc8          8 chiffres
  etat          code postal de l'État (WI)
  milieu        cours_d_eau | lac | autre
  engin         nom de l'engin tel que la source le donne (mis en minuscules) ; vide = inconnu
  annee         année de l'événement
  source        source des données (NRSA 2018-19, WQP STOCKBRIDGE_MUNSEE, ...)
  especes       espèces trouvées, séparées par « ; » ; vide = événement sans poisson (il compte au dénominateur)
Aucune coordonnée : le HUC8 suffit et les positions d'espèces sensibles ne sortent jamais.

Usage : python3 rarete_us.py evenements.csv [-o sortie.csv] [--min-evenements 20] [--q-peu-commun 0.3333...]
        [--q-commun 0.6666...] [--fixes 0.2 0.5] [--min-cellules 10] [--annee-min 2012]
        [--tous-milieux] [--tous-engins] [--revue-validee]
"""
import argparse
import csv
import math
import sys

COLONNES_ENTREE = ["evenement_id", "huc8", "etat", "milieu", "engin", "annee", "source", "especes"]
COLONNES_SORTIE = ["milieu", "engin", "huc8", "espece", "classe", "motif", "frequence", "n_evenements_espece",
                   "n_evenements_total", "derniere_annee", "echelle", "code_echelle", "sources", "affichage_rarete"]
TOUS = "tous"


class Parametres:
    def __init__(self, minimum_evenements=20, q_peu_commun=1.0 / 3.0, q_commun=2.0 / 3.0, fixes=None,
                 minimum_cellules=10, annee_minimum=None, separer_milieu=True, separer_engin=True, revue_validee=False):
        self.minimum_evenements = minimum_evenements
        self.q_peu_commun = q_peu_commun
        self.q_commun = q_commun
        self.fixes = fixes  # None ou (peu_commun, commun) en fréquence
        self.minimum_cellules = minimum_cellules
        self.annee_minimum = annee_minimum
        self.separer_milieu = separer_milieu
        self.separer_engin = separer_engin
        self.revue_validee = revue_validee


class Compte:
    __slots__ = ("n", "especes", "derniere", "sources", "etats")

    def __init__(self):
        self.n = 0
        self.especes = {}
        self.derniere = {}
        self.sources = set()
        self.etats = {}


def quantile(triee, p):
    """Quantile de type 7 (interpolation linéaire) d'une liste triée."""
    if not triee:
        return 0.0
    h = (len(triee) - 1) * p
    bas = int(math.floor(h))
    haut = min(bas + 1, len(triee) - 1)
    return triee[bas] + (h - bas) * (triee[haut] - triee[bas])


def lire_evenements(chemin):
    """Lit le CSV ; renvoie une liste de dicts (especes : ensemble)."""
    sortie = []
    with open(chemin, newline="", encoding="utf-8") as f:
        lecteur = csv.DictReader(f)
        manquantes = [c for c in COLONNES_ENTREE if c not in (lecteur.fieldnames or [])]
        if manquantes:
            raise SystemExit("colonnes manquantes : " + ", ".join(manquantes))
        for ligne in lecteur:
            try:
                annee = int(ligne["annee"])
            except ValueError:
                annee = 0
            milieu = (ligne["milieu"] or "autre").strip()
            sortie.append({
                "id": ligne["evenement_id"].strip(), "huc8": ligne["huc8"].strip(), "etat": ligne["etat"].strip(),
                "milieu": milieu, "engin": ligne["engin"].strip().lower(), "annee": annee, "source": ligne["source"].strip(),
                "especes": {s.strip() for s in ligne["especes"].split(";") if s.strip()},
            })
    return sortie


class Moteur:
    def __init__(self, evenements, parametres=None):
        self.p = parametres or Parametres()
        ordre, uniques, rejetes = [], {}, 0
        for e in evenements:
            if not e["id"] or len(e["huc8"]) != 8 or not (e["huc8"].isascii() and e["huc8"].isdigit()):
                rejetes += 1
                continue
            if e["id"] in uniques:
                uniques[e["id"]]["especes"] = uniques[e["id"]]["especes"] | e["especes"]
            else:
                uniques[e["id"]] = dict(e)
                ordre.append(e["id"])
        self.n_rejetes = rejetes
        self.par_huc8, self.par_huc6, self.par_etat = {}, {}, {}
        gardes = 0
        for i in ordre:
            e = uniques[i]
            if self.p.annee_minimum is not None and e["annee"] < self.p.annee_minimum:
                continue
            gardes += 1
            strate = (e["milieu"] if self.p.separer_milieu else TOUS, e["engin"] if self.p.separer_engin else TOUS)
            self._ajouter(self.par_huc8.setdefault(strate, {}).setdefault(e["huc8"], Compte()), e, True)
            self._ajouter(self.par_huc6.setdefault(strate, {}).setdefault(e["huc8"][:6], Compte()), e, False)
            self._ajouter(self.par_etat.setdefault(strate, {}).setdefault(e["etat"], Compte()), e, False)
        self.n_evenements = gardes
        self.distributions = {}
        for strate, cases in self.par_huc8.items():
            freqs = []
            for c in cases.values():
                if c.n >= self.p.minimum_evenements:
                    freqs.extend(k / c.n for k in c.especes.values())
            self.distributions[strate] = sorted(freqs)

    @staticmethod
    def _ajouter(c, e, avec_etat):
        c.n += 1
        c.sources.add(e["source"])
        if avec_etat:
            c.etats[e["etat"]] = c.etats.get(e["etat"], 0) + 1
        for sp in e["especes"]:
            c.especes[sp] = c.especes.get(sp, 0) + 1
            c.derniere[sp] = max(c.derniere.get(sp, e["annee"]), e["annee"])

    def strates(self):
        return sorted(self.par_huc8)

    def seuils(self, strate):
        if self.p.fixes is not None:
            return self.p.fixes
        d = self.distributions.get(strate, [])
        if len(d) < self.p.minimum_cellules:
            return None
        return quantile(d, self.p.q_peu_commun), quantile(d, self.p.q_commun)

    def _choisir(self, strate, huc8, etat=None):
        minimum = self.p.minimum_evenements
        c8 = self.par_huc8.get(strate, {}).get(huc8)
        c6 = self.par_huc6.get(strate, {}).get(huc8[:6])
        code_etat = etat
        if code_etat is None and c8 is not None and c8.etats:
            code_etat = sorted(c8.etats.items(), key=lambda kv: (-kv[1], kv[0]))[0][0]
        ce = self.par_etat.get(strate, {}).get(code_etat) if code_etat else None
        if c8 is not None and c8.n >= minimum:
            return "huc8", huc8, c8
        if c6 is not None and c6.n >= minimum:
            return "huc6", huc8[:6], c6
        if ce is not None and ce.n >= minimum:
            return "etat", code_etat, ce
        if c8 is not None and c8.n > 0:
            return "aucune", huc8, c8
        if c6 is not None and c6.n > 0:
            return "aucune", huc8[:6], c6
        if ce is not None and ce.n > 0:
            return "aucune", code_etat, ce
        return None

    def evaluer(self, espece, huc8, strate, etat=None):
        choix = self._choisir(strate, huc8, etat)
        base = {"milieu": strate[0], "engin": strate[1], "huc8": huc8, "espece": espece}
        if choix is None:
            base.update(classe="donnee_insuffisante", motif="pas_assez_evenements", frequence=None, n_evenements_espece=0,
                        n_evenements_total=0, derniere_annee=None, echelle="aucune", code_echelle="", sources=[],
                        affichage_rarete=False)
            return base
        echelle, code, c = choix
        k = c.especes.get(espece, 0)
        freq = k / c.n if c.n > 0 else None
        classe, motif = "donnee_insuffisante", ""
        s = self.seuils(strate)
        if echelle == "aucune":
            motif = "pas_assez_evenements"
        elif k == 0:
            motif = "non_observee"
        elif s is not None:
            classe = "commun" if freq >= s[1] else ("peu_commun" if freq >= s[0] else "rare")
        else:
            motif = "seuils_non_calibres"
        base.update(classe=classe, motif=motif, frequence=freq, n_evenements_espece=k, n_evenements_total=c.n,
                    derniere_annee=c.derniere.get(espece), echelle=echelle, code_echelle=code, sources=sorted(c.sources),
                    affichage_rarete=self.p.revue_validee and classe != "donnee_insuffisante")
        return base

    def toutes(self):
        lignes = []
        for strate in self.strates():
            for huc8 in sorted(self.par_huc8[strate]):
                choix = self._choisir(strate, huc8)
                if choix is None:
                    continue
                for sp in sorted(choix[2].especes):
                    lignes.append(self.evaluer(sp, huc8, strate))
        return lignes


def ligne_csv(r):
    return [r["milieu"], r["engin"], r["huc8"], r["espece"], r["classe"], r["motif"],
            "" if r["frequence"] is None else "%.6f" % r["frequence"], r["n_evenements_espece"], r["n_evenements_total"],
            "" if r["derniere_annee"] is None else r["derniere_annee"], r["echelle"], r["code_echelle"],
            ";".join(r["sources"]), "true" if r["affichage_rarete"] else "false"]


def ecrire(lignes, flux):
    w = csv.writer(flux, lineterminator="\n")
    w.writerow(COLONNES_SORTIE)
    for r in lignes:
        w.writerow(ligne_csv(r))


def main(argv=None):
    a = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    a.add_argument("evenements")
    a.add_argument("-o", "--sortie")
    a.add_argument("--min-evenements", type=int, default=20)
    a.add_argument("--q-peu-commun", type=float, default=1.0 / 3.0)
    a.add_argument("--q-commun", type=float, default=2.0 / 3.0)
    a.add_argument("--fixes", type=float, nargs=2, metavar=("PEU_COMMUN", "COMMUN"))
    a.add_argument("--min-cellules", type=int, default=10)
    a.add_argument("--annee-min", type=int)
    a.add_argument("--tous-milieux", action="store_true")
    a.add_argument("--tous-engins", action="store_true")
    a.add_argument("--revue-validee", action="store_true", help="seulement après la revue d'un biologiste")
    o = a.parse_args(argv)
    p = Parametres(o.min_evenements, o.q_peu_commun, o.q_commun, tuple(o.fixes) if o.fixes else None, o.min_cellules,
                   o.annee_min, not o.tous_milieux, not o.tous_engins, o.revue_validee)
    m = Moteur(lire_evenements(o.evenements), p)
    sys.stderr.write("%d événements gardés, %d rejetés\n" % (m.n_evenements, m.n_rejetes))
    lignes = m.toutes()
    if o.sortie:
        with open(o.sortie, "w", newline="", encoding="utf-8") as f:
            ecrire(lignes, f)
    else:
        ecrire(lignes, sys.stdout)


if __name__ == "__main__":
    main()
