"""Prépare le jeu d'entraînement Create ML à partir de <jeu>/<espece_id>/*.jpg (+ licences*.csv).
Usage : python3 -I preparer_jeu.py --jeu reports/photos/jeu --sortie ../jeu-prepare [--especes liste.json | --repli] [--copier]
- découpe 70/15/15 par espèce, PAR PHOTOGRAPHE (toutes les photos d'un auteur dans le même lot) ;
- exclut les images de moins de 299x299 (minimum Create ML) ;
- écrit manifeste.csv, rapport-desequilibre.txt, et (avec --copier) train/ val/ test/ <espece>/.
Dossier `autre` du jeu = classe « autre ». --repli : 6 espèces, toutes les autres photos -> « autre ».
La sortie doit rester HORS du dépôt (jamais de photo dans git)."""
import argparse, csv, glob, json, os, random, shutil, struct, sys
from collections import defaultdict

REPLI = ["brochet", "sandre", "perche-commune", "truite-fario", "carpe-commune", "black-bass"]
MIN_PX = 299
PARTS = (("train", 0.70), ("val", 0.15), ("test", 0.15))
EXT = (".jpg", ".jpeg", ".png")


def taille_image(chemin):
    """(largeur, hauteur) lue dans l'en-tête, sans dépendance ; None si illisible."""
    try:
        with open(chemin, "rb") as f:
            d = f.read(32)
            if d[:8] == b"\x89PNG\r\n\x1a\n":
                return struct.unpack(">II", d[16:24])
            if d[:2] != b"\xff\xd8":
                return None
            f.seek(2)
            while True:
                b = f.read(1)
                if not b:
                    return None
                if b != b"\xff":
                    continue
                m = f.read(1)
                while m == b"\xff":
                    m = f.read(1)
                if m in (b"\x00", b"\x01") or b"\xd0" <= m <= b"\xd9":
                    continue
                n = struct.unpack(">H", f.read(2))[0]
                if m[0] in range(0xC0, 0xD0) and m[0] not in (0xC4, 0xC8, 0xCC):
                    h, w = struct.unpack(">HH", f.read(5)[1:5])
                    return (w, h)
                f.seek(n - 2, 1)
    except (OSError, struct.error):
        return None


def lire_licences(jeu):
    infos = {}
    for chemin in glob.glob(os.path.join(jeu, "licences*.csv")):
        with open(chemin, encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                infos[(r.get("espece_id", ""), os.path.basename(r.get("fichier", "")))] = r
    return infos


def decouper(groupes, rng):
    """groupes : {auteur: [photos]} -> {'train': [...], 'val': [...], 'test': [...]}.
    Les groupes entiers vont dans un seul lot ; on remplit le lot le plus en retard sur sa cible."""
    total = sum(len(v) for v in groupes.values())
    out = {p: [] for p, _ in PARTS}
    cles = list(groupes)
    rng.shuffle(cles)
    cles.sort(key=lambda k: -len(groupes[k]))  # gros groupes d'abord, ordre aléatoire à taille égale
    for k in cles:
        retard = {p: out_cible - len(out[p]) for p, c in PARTS for out_cible in [c * total]}
        meilleur = max(retard, key=lambda p: (retard[p], p == "train"))
        out[meilleur].extend(groupes[k])
    return out


def preparer(jeu, especes, sortie=None, seed=42, repli=False, copier=False, max_autre=None):
    rng = random.Random(seed)
    infos = lire_licences(jeu)
    classes = set(especes)
    par_classe = defaultdict(lambda: defaultdict(list))  # classe -> auteur -> [ligne]
    rejets, inconnus = [], []
    for dossier in sorted(os.listdir(jeu)):
        chemin_d = os.path.join(jeu, dossier)
        if not os.path.isdir(chemin_d):
            continue
        if dossier == "autre":
            classe = "autre"
        elif dossier in classes:
            classe = dossier
        elif repli:
            classe = "autre"
        else:
            inconnus.append(dossier)
            continue
        for nom in sorted(os.listdir(chemin_d)):
            if not nom.lower().endswith(EXT):
                continue
            p = os.path.join(chemin_d, nom)
            dim = taille_image(p)
            if dim is None or min(dim) < MIN_PX:
                rejets.append((p, dim))
                continue
            info = infos.get((dossier, nom), {})
            auteur = (info.get("auteur") or "").strip() or f"inconnu:{dossier}/{nom}"  # inconnu = groupe seul
            par_classe[classe][auteur].append({
                "chemin": p, "dossier": dossier, "fichier": nom, "classe": classe, "auteur": auteur,
                "licence": info.get("licence", ""), "source": info.get("source", ""),
                "largeur": dim[0], "hauteur": dim[1]})
    lignes = []
    for classe, groupes in sorted(par_classe.items()):
        for part, items in decouper(groupes, rng).items():
            for it in items:
                it["lot"] = part
                lignes.append(it)
    # classe « autre » en mode repli : on plafonne l'entraînement/validation à la taille moyenne d'une classe gardée
    if repli or max_autre:
        tailles = [sum(1 for l in lignes if l["classe"] == c and l["lot"] == "train") for c in classes]
        cap = max_autre or (max(1, round(sum(tailles) / max(1, len(tailles)))) if tailles else 1)
        autres_train = [l for l in lignes if l["classe"] == "autre" and l["lot"] == "train"]
        rng.shuffle(autres_train)
        for l in autres_train[cap:]:
            lignes.remove(l)
    manifeste = [{k: l[k] for k in ("classe", "lot", "dossier", "fichier", "auteur", "licence", "source", "largeur", "hauteur")} for l in lignes]
    rapport = rapport_desequilibre(manifeste, rejets, inconnus)
    if sortie:
        os.makedirs(sortie, exist_ok=True)
        with open(os.path.join(sortie, "manifeste.csv"), "w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, list(manifeste[0].keys()) if manifeste else ["classe"])
            w.writeheader()
            w.writerows(manifeste)
        with open(os.path.join(sortie, "rapport-desequilibre.txt"), "w", encoding="utf-8") as f:
            f.write(rapport)
        if copier:
            for l in lignes:
                dest = os.path.join(sortie, l["lot"], l["classe"])
                os.makedirs(dest, exist_ok=True)
                shutil.copy2(l["chemin"], os.path.join(dest, f"{l['dossier']}__{l['fichier']}"))
    return manifeste, rapport


def rapport_desequilibre(manifeste, rejets, inconnus):
    n = defaultdict(lambda: {"train": 0, "val": 0, "test": 0})
    for l in manifeste:
        n[l["classe"]][l["lot"]] += 1
    tot = {c: sum(v.values()) for c, v in n.items()}
    out = ["classe                        train  val  test  total"]
    for c in sorted(n, key=lambda c: -tot[c]):
        out.append(f"{c:28s} {n[c]['train']:5d} {n[c]['val']:4d} {n[c]['test']:5d} {tot[c]:6d}")
    especes = {c: t for c, t in tot.items() if c != "autre"}
    if especes:
        mx, mn = max(especes, key=especes.get), min(especes, key=especes.get)
        out.append(f"\ndéséquilibre : plus grosse {mx}={especes[mx]}, plus petite {mn}={especes[mn]}, rapport {especes[mx] / max(1, especes[mn]):.1f}")
        out.append("espèces avec moins de 10 photos de test (non évaluables à l'examen) : " + (", ".join(sorted(c for c in especes if n[c]['test'] < 10)) or "aucune"))
        out.append("espèces avec moins de 80 photos au total : " + (", ".join(sorted(c for c in especes if especes[c] < 80)) or "aucune"))
    out.append(f"images exclues (< {MIN_PX}x{MIN_PX} ou illisibles) : {len(rejets)}")
    out.append("dossiers ignorés (espèce hors liste) : " + (", ".join(inconnus) or "aucun"))
    return "\n".join(out) + "\n"


def charger_especes(chemin):
    with open(chemin, encoding="utf-8") as f:
        return [e["id"] for e in json.load(f)["especes"]]


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--jeu", required=True)
    ap.add_argument("--sortie", required=True)
    ap.add_argument("--especes", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs", "regles", "especes-national.json"))
    ap.add_argument("--repli", action="store_true", help="6 espèces, le reste devient « autre »")
    ap.add_argument("--copier", action="store_true", help="copie les photos dans train/val/test")
    ap.add_argument("--seed", type=int, default=42)
    a = ap.parse_args(argv)
    especes = REPLI if a.repli else charger_especes(a.especes)
    _, rapport = preparer(a.jeu, especes, a.sortie, a.seed, a.repli, a.copier)
    print(rapport)
    return 0


if __name__ == "__main__":
    sys.exit(main())
