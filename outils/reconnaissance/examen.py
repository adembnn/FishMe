"""Examen d'acceptation (voir EXAMEN.md). Usage :
python3 -I examen.py --journal journal.csv [--modele Poissons.mlmodel] [--sortie sortie]
Code de sortie 0 = le modèle passe, 1 = il échoue."""
import argparse, csv, os, sys
from collections import defaultdict

SEUILS = {
    "top3_moyen": 0.90, "top1_moyen": 0.70, "top3_par_espece": 0.80,
    "min_photos_test": 10, "refus_autre": 0.90, "taille_max_mo": 30,
}
AUTRE = "autre"


def taille_mo(chemin):
    if os.path.isfile(chemin):
        return os.path.getsize(chemin) / 1e6
    total = 0
    for racine, _, fichiers in os.walk(chemin):
        total += sum(os.path.getsize(os.path.join(racine, f)) for f in fichiers)
    return total / 1e6


def lire_journal(chemin):
    with open(chemin, encoding="utf-8", newline="") as f:
        lignes = list(csv.DictReader(f))
    for col in ("fichier", "vraie", "p1", "p2", "p3"):
        if lignes and col not in lignes[0]:
            raise ValueError(f"colonne manquante : {col}")
    return lignes


def evaluer(lignes, seuils=SEUILS, taille=None):
    """Rend (résultats, liste des échecs)."""
    par = defaultdict(lambda: {"n": 0, "top1": 0, "top3": 0})
    autre = {"n": 0, "refus": 0}
    confusion = defaultdict(int)
    for l in lignes:
        props = [l["p1"], l["p2"], l["p3"]]
        confusion[(l["vraie"], l["p1"])] += 1
        if l["vraie"] == AUTRE:
            autre["n"] += 1
            autre["refus"] += props[0] == AUTRE
            continue
        e = par[l["vraie"]]
        e["n"] += 1
        e["top1"] += props[0] == l["vraie"]
        e["top3"] += l["vraie"] in props
    echecs, non_evaluables, faibles, evaluees = [], [], [], {}
    for esp, e in sorted(par.items()):
        if e["n"] < seuils["min_photos_test"]:
            non_evaluables.append(esp)
            continue
        evaluees[esp] = (e["top1"] / e["n"], e["top3"] / e["n"], e["n"])
        if evaluees[esp][1] < seuils["top3_par_espece"]:
            faibles.append(esp)
    res = {"par_espece": evaluees, "non_evaluables": non_evaluables, "faibles": faibles}
    if evaluees:
        res["top1_moyen"] = sum(v[0] for v in evaluees.values()) / len(evaluees)
        res["top3_moyen"] = sum(v[1] for v in evaluees.values()) / len(evaluees)
        if res["top3_moyen"] < seuils["top3_moyen"]:
            echecs.append(f"top-3 moyen {res['top3_moyen']:.1%} < {seuils['top3_moyen']:.0%}")
        if res["top1_moyen"] < seuils["top1_moyen"]:
            echecs.append(f"top-1 moyen {res['top1_moyen']:.1%} < {seuils['top1_moyen']:.0%}")
    else:
        echecs.append("aucune espèce évaluable")
    if faibles:
        echecs.append(f"top-3 sous {seuils['top3_par_espece']:.0%} : {', '.join(faibles)} (à sortir du modèle)")
    if non_evaluables:
        echecs.append(f"moins de {seuils['min_photos_test']} photos de test : {', '.join(non_evaluables)} (à sortir)")
    if autre["n"]:
        res["refus_autre"] = autre["refus"] / autre["n"]
        if res["refus_autre"] < seuils["refus_autre"]:
            echecs.append(f"refus des photos hors liste {res['refus_autre']:.1%} < {seuils['refus_autre']:.0%}")
    else:
        echecs.append("aucune photo « autre » dans le test : refus non mesuré")
    if taille is not None:
        res["taille_mo"] = taille
        if taille > seuils["taille_max_mo"]:
            echecs.append(f"taille {taille:.1f} Mo > {seuils['taille_max_mo']} Mo")
    else:
        echecs.append("taille du modèle non vérifiée (--modele)")
    res["confusion"] = dict(confusion)
    return res, echecs


def ecrire_confusion(confusion, chemin):
    classes = sorted({k[0] for k in confusion} | {k[1] for k in confusion})
    os.makedirs(os.path.dirname(chemin) or ".", exist_ok=True)
    with open(chemin, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["vraie\\predite"] + classes)
        for v in classes:
            w.writerow([v] + [confusion.get((v, p), 0) for p in classes])


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--journal", required=True)
    ap.add_argument("--modele")
    ap.add_argument("--sortie", default="sortie")
    a = ap.parse_args(argv)
    res, echecs = evaluer(lire_journal(a.journal), taille=taille_mo(a.modele) if a.modele else None)
    for esp, (t1, t3, n) in res["par_espece"].items():
        print(f"{esp:28s} n={n:3d} top1={t1:6.1%} top3={t3:6.1%}")
    for cle in ("top1_moyen", "top3_moyen", "refus_autre", "taille_mo"):
        if cle in res:
            print(f"{cle}: {res[cle]:.3f}")
    ecrire_confusion(res["confusion"], os.path.join(a.sortie, "confusion.csv"))
    if echecs:
        print("VERDICT : ECHEC\n- " + "\n- ".join(echecs))
        return 1
    print("VERDICT : PASSE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
