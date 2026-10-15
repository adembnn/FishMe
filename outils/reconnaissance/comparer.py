"""Compare le modèle Create ML à l'IA d'Apple sur 20 photos (test sur iPhone 15 Pro / Mac macOS 27).
  python3 -I comparer.py choisir --manifeste jeu-prepare/manifeste.csv --n 20 > liste.csv
  python3 -I comparer.py compare --createml journal-createml.csv --apple journal-apple.csv --liste liste.csv
Les journaux ont le format de examen.py (fichier,vraie,p1,p2,p3). Clé d'une photo : <classe>/<dossier>__<fichier>."""
import argparse, csv, random, sys
from collections import defaultdict


def choisir(manifeste, n=20, seed=7):
    """n photos du lot test, réparties à tour de rôle entre les classes (pas d'« autre » avant la fin)."""
    par = defaultdict(list)
    with open(manifeste, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            if r["lot"] == "test":
                par[r["classe"]].append(f"{r['classe']}/{r['dossier']}__{r['fichier']}")
    rng = random.Random(seed)
    for v in par.values():
        rng.shuffle(v)
    ordre = sorted(par, key=lambda c: (c == "autre", c))
    out = []
    while len(out) < n and any(par[c] for c in ordre):
        for c in ordre:
            if par[c] and len(out) < n:
                out.append(par[c].pop())
    return out


def lire(chemin):
    with open(chemin, encoding="utf-8", newline="") as f:
        return {r["fichier"]: r for r in csv.DictReader(f)}


def comparer(a, b, cles):
    """Rend (lignes du tableau, résumé) pour les moteurs a et b sur les photos communes de `cles`."""
    lignes, s = [], {"n": 0, "a1": 0, "a3": 0, "b1": 0, "b3": 0, "accord": 0}
    for k in cles:
        if k not in a or k not in b:
            lignes.append((k, "absente d'un des journaux", "", ""))
            continue
        va = a[k]["vraie"]
        pa, pb = [a[k][c] for c in ("p1", "p2", "p3")], [b[k][c] for c in ("p1", "p2", "p3")]
        s["n"] += 1
        s["a1"] += pa[0] == va
        s["a3"] += va in pa
        s["b1"] += pb[0] == va
        s["b3"] += va in pb
        s["accord"] += pa[0] == pb[0]
        lignes.append((k, va, "/".join(pa), "/".join(pb)))
    return lignes, s


def main(argv=None):
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    c = sp.add_parser("choisir")
    c.add_argument("--manifeste", required=True)
    c.add_argument("--n", type=int, default=20)
    k = sp.add_parser("compare")
    k.add_argument("--createml", required=True)
    k.add_argument("--apple", required=True)
    k.add_argument("--liste", required=True)
    a = ap.parse_args(argv)
    if a.cmd == "choisir":
        print("fichier")
        print("\n".join(choisir(a.manifeste, a.n)))
        return 0
    cles = [l.strip() for l in open(a.liste, encoding="utf-8") if l.strip() and l.strip() != "fichier"]
    lignes, s = comparer(lire(a.createml), lire(a.apple), cles)
    print("photo | vraie | Create ML (p1/p2/p3) | IA d'Apple (p1/p2/p3)")
    for l in lignes:
        print(" | ".join(l))
    n = max(1, s["n"])
    print(f"\n{s['n']} photos : Create ML top-1 {s['a1']}/{s['n']} top-3 {s['a3']}/{s['n']} ; "
          f"IA d'Apple top-1 {s['b1']}/{s['n']} top-3 {s['b3']}/{s['n']} ; même 1re réponse {s['accord']}/{s['n']}")
    print("Avec 20 photos, un écart de moins de 3 photos ne prouve rien.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
