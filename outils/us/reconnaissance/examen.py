"""Examen de la tête US AVANT embarquement. Écrit avant de voir un score ; les seuils ne changent pas ensuite.
Le jeu d'examen = VRAIES prises de pêcheurs (photo en main, au bord de l'eau), jamais vues à l'entraînement ni à la validation,
triées à la main (étiquette = espèce relue par un humain). Les photos iNaturalist/GBIF NE comptent PAS (47,9 % de top-1 sur le
terrain contre 82,5 % sur prises de pêcheurs pour le v2 : reports/etat/reconnaissance.md).

Journal (CSV) : fichier,vraie,p1,p2,p3,conf1,source
  vraie = slug d'espèce, 'autre-poisson' ou 'pas-un-poisson' ; p1..p3 = propositions ordonnées ; conf1 = probabilité brute de p1 ;
  source = 'pecheur' (compte pour l'examen) ou autre (affichée à part, ne compte pas).
Seuils (1 à 3 = au moins égaux au v2 européen mesuré sur 7 062 prises de pêcheurs) :
  1. top-1 sur prises d'espèces >= 82,5 %     2. top-3 >= 91,6 %
  3. au moins 300 prises d'espèces au total ET borne basse de Wilson 95 % affichée (pas de verdict « passe » sous 300)
  4. refus des « pas un poisson » >= 92,9 % (v2 : 342/368) ; refus = p1 'pas-un-poisson'/'autre-poisson' OU conf1 < seuil
  5. par espèce : >= 10 prises, top-3 >= 80 % ; sinon l'espèce sort de la tête (reste dans la grille)
Recalibrage du seuil de confiance (0,4 aujourd'hui) : on balaie 0,10..0,90 ; seuil retenu = le PLUS PETIT dont le top-1 sur les photos
proposées (conf1 >= seuil) est >= 90 %, sans descendre sous 0,30. Si aucun seuil n'y arrive : pas de verdict, on retravaille la tête.
Sortie : code 0 (passe) ou 1 ; écrit examen.json et recalibrage.csv dans --sortie.
Usage : python3 -I examen.py --journal journal.csv [--seuil 0.4] [--sortie dossier]"""
import argparse, collections, csv, json, math, os, sys

V2_TOP1, V2_TOP3, V2_REFUS, MIN_PRISES, MIN_PAR_ESPECE = 0.825, 0.916, 0.929, 300, 10
REFUS = ("pas-un-poisson", "autre-poisson")


def wilson(k, n, z=1.96):
    if n == 0:
        return (float("nan"), float("nan"))
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (c - h, c + h)


def lire(chemin):
    with open(chemin, encoding="utf-8", newline="") as f:
        return [dict(r, conf1=float(r["conf1"] or 0)) for r in csv.DictReader(f)]


def examiner(lignes, seuil=0.4):
    p = [r for r in lignes if r.get("source") == "pecheur"]
    esp = [r for r in p if r["vraie"] not in REFUS]
    pas = [r for r in p if r["vraie"] == "pas-un-poisson"]
    n = len(esp)
    k1 = sum(r["p1"] == r["vraie"] for r in esp)
    k3 = sum(r["vraie"] in (r["p1"], r["p2"], r["p3"]) for r in esp)
    refus = sum(r["p1"] in REFUS or r["conf1"] < seuil for r in pas)
    par = collections.defaultdict(lambda: [0, 0])
    for r in esp:
        par[r["vraie"]][0] += 1
        par[r["vraie"]][1] += r["vraie"] in (r["p1"], r["p2"], r["p3"])
    especes = {c: {"n": a, "top3": round(b / a, 3), "evaluable": a >= MIN_PAR_ESPECE, "sort_de_la_tete": a >= MIN_PAR_ESPECE and b / a < 0.8, "non_evaluable": a < MIN_PAR_ESPECE}
               for c, (a, b) in sorted(par.items())}
    recal = []
    for i in range(10, 91, 5):
        t = i / 100
        prop = [r for r in esp if r["conf1"] >= t]
        recal.append({"seuil": t, "proposees": len(prop), "part_proposee": round(len(prop) / n, 3) if n else 0,
                      "top1_si_proposee": round(sum(r["p1"] == r["vraie"] for r in prop) / len(prop), 3) if prop else None})
    retenu = next((c["seuil"] for c in recal if c["seuil"] >= 0.30 and c["top1_si_proposee"] is not None and c["top1_si_proposee"] >= 0.90), None)
    ok = {
        "top1": n > 0 and k1 / n >= V2_TOP1, "top3": n > 0 and k3 / n >= V2_TOP3,
        "volume": n >= MIN_PRISES, "refus": len(pas) > 0 and refus / len(pas) >= V2_REFUS,
        "especes": all(not v["sort_de_la_tete"] for v in especes.values()),
    }
    return {
        "prises_especes": n, "prises_pas_un_poisson": len(pas),
        "top1": round(k1 / n, 4) if n else None, "top1_wilson95": [round(x, 3) for x in wilson(k1, n)],
        "top3": round(k3 / n, 4) if n else None, "top3_wilson95": [round(x, 3) for x in wilson(k3, n)],
        "refus_pas_un_poisson": round(refus / len(pas), 4) if pas else None, "seuil_applique": seuil,
        "especes": especes, "especes_non_evaluables": [c for c, v in especes.items() if v["non_evaluable"]],
        "recalibrage": recal, "seuil_recommande": retenu, "criteres": ok, "verdict": "passe" if all(ok.values()) else "echoue",
        "hors_examen": {"autres_sources": len(lignes) - len(p)},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--journal", required=True)
    ap.add_argument("--seuil", type=float, default=0.4)
    ap.add_argument("--sortie", default=".")
    a = ap.parse_args()
    r = examiner(lire(a.journal), a.seuil)
    os.makedirs(a.sortie, exist_ok=True)
    json.dump(r, open(os.path.join(a.sortie, "examen.json"), "w"), ensure_ascii=False, indent=1)
    with open(os.path.join(a.sortie, "recalibrage.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, ["seuil", "proposees", "part_proposee", "top1_si_proposee"])
        w.writeheader()
        w.writerows(r["recalibrage"])
    print(json.dumps({k: v for k, v in r.items() if k not in ("especes", "recalibrage")}, ensure_ascii=False, indent=1))
    sys.exit(0 if r["verdict"] == "passe" else 1)


if __name__ == "__main__":
    main()
