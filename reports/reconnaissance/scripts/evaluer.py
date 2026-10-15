"""Jeu de test par photographe (fixé avant tout entraînement), têtes logistiques sur vecteurs, scores top-1/top-3 et confusions.
usage: evaluer.py prefixe_traite manifestes... --sortie dossier"""
import sys, json, csv, hashlib, collections, numpy as np, os
from sklearn.linear_model import LogisticRegression
pre = sys.argv[1]; sortie = sys.argv[-1]; mans = sys.argv[2:-2]
os.makedirs(sortie, exist_ok=True)
CL = {r["id"]: r for r in csv.DictReader(open("/tmp/claude-0/reco/classes.tsv"), delimiter="\t")}
# photographe et source de chaque photo (par empreinte d'URL)
meta = {}
for m in mans:
    for r in csv.reader(open(m.replace(".csv", ".telecharge.csv"))):
        classe, h, st, url, phot, lic, ds = r
        if st in ("ok", "deja"): meta[classe + "/" + h + ".jpg"] = (phot.strip().lower() or url, ds)
lignes = [json.loads(l) for l in open(pre + ".jsonl")]
n = len(lignes)
VF = np.fromfile(pre + ".fishial.f32", np.float32).reshape(n, -1)
VD = np.fromfile(pre + ".dino.f32", np.float32).reshape(n, -1)
VD = VD / np.linalg.norm(VD, axis=1, keepdims=True)
# nom latin Fishial -> classe
lat2c = {}
for cid, r in CL.items():
    for l in r["latins"].split("|"): lat2c[l] = cid
def fishial_classe(lbl):
    for l, c in lat2c.items():
        if lbl == l or lbl.startswith(l + " "): return c
    return None
NOTRES = set(CL)
garde, y, grp, src = [], [], [], []
for i, L in enumerate(lignes):
    c = L["classe"]; ph, ds = meta.get(L["f"], ("?", "?"))
    if c == "autre-poisson-vimbe": c = "autre-poisson-unsplash"
    if c == "autre-poisson-unsplash":
        if fishial_classe(L["fishial"][0][0]) in NOTRES: continue   # c'est peut-être un de nos poissons
        c = "autre-poisson"
    if ds.startswith("openverse"):   # étiquettes bruitées (mot-clé) : gardées seulement si Fishial est d'accord
        if not L["poisson"] or c not in {fishial_classe(l) for l, p in L["fishial"]}: continue
    garde.append(i); y.append(c); grp.append(ph); src.append(ds)
y = np.array(y); grp = np.array(grp); src = np.array([("affine" if s == "affine" else "unsplash" if s.startswith("unsplash") else "openverse" if s.startswith("openverse") else "peche" if s.startswith(("chytej", "fisch-hitparade")) else "public" if s.startswith("EOL") or "eol" in s.lower() else "gbif") for s in src])
# TEST FIXÉ : un photographe sur 4 (empreinte de son nom), jamais vu à l'entraînement
test = np.array([int(hashlib.sha1(g.encode()).hexdigest(), 16) % 4 == 0 and s != "openverse" for g, s in zip(grp, src)])
# fuites : une photo de test presque identique à une photo d'entraînement est retirée du test
Vg = VD[np.array(garde)]; tr_i = np.where(~test)[0]; fuites = 0
for k in np.where(test)[0]:
    if (Vg[tr_i] @ Vg[k]).max() > 0.95: test[k] = False; fuites += 1
print("fuites retirées du test :", fuites)
cnt_tr = collections.Counter(y[~test]); cnt_te = collections.Counter(y[test])
classes = sorted(c for c in set(y) if cnt_tr[c] >= 30 and cnt_te[c] >= 5)
grille = sorted(c for c in set(y) if c not in classes)
with open(os.path.join(sortie, "jeu-test.csv"), "w", newline="") as f:
    w = csv.writer(f); w.writerow(["photo", "classe", "photographe_empreinte", "source"])
    for k, i in enumerate(garde):
        if test[k]: w.writerow([lignes[i]["f"], y[k], hashlib.sha1(grp[k].encode()).hexdigest()[:10], src[k]])
with open(os.path.join(sortie, "train.csv"), "w", newline="") as f:
    w = csv.writer(f); w.writerow(["photo", "classe"])
    for k, i in enumerate(garde):
        if not test[k]: w.writerow([lignes[i]["f"], y[k]])
sel = np.isin(y, classes)
idx = np.array(garde)
res = {"classes_modele": classes, "classes_grille": {c: [cnt_tr[c], cnt_te[c]] for c in grille},
       "photos_entrainement": int((sel & ~test).sum()), "photos_test": int((sel & test).sum()), "fuites_retirees": fuites, "modeles": {}}
def noter(nom, P, lab):
    yt = y[sel & test]; src_t = src[sel & test]; order = np.argsort(-P, 1); top = np.array(lab)[order[:, :3]]
    t1 = (top[:, 0] == yt); t3 = (top == yt[:, None]).any(1)
    par = {}
    for c in classes:
        m = yt == c
        conf = collections.Counter(top[m & ~t1, 0]).most_common(3)
        par[c] = {"n": int(m.sum()), "top1": round(float(t1[m].mean()), 3), "top3": round(float(t3[m].mean()), 3), "confusions": conf}
    poissons = ~np.isin(yt, ["pas-un-poisson", "autre-poisson"])
    res["modeles"][nom] = {"top1": round(float(t1.mean()), 3), "top3": round(float(t3.mean()), 3),
        "top1_poissons": round(float(t1[poissons].mean()), 3), "top3_poissons": round(float(t3[poissons].mean()), 3),
        "par_source": {s: [int((src_t == s).sum()), round(float(t1[src_t == s].mean()), 3), round(float(t3[src_t == s].mean()), 3)] for s in set(src_t)},
        "top1_moyenne_par_classe": round(float(np.mean([par[c]["top1"] for c in classes])), 3), "par_classe": par}
    print(nom, res["modeles"][nom]["top1"], res["modeles"][nom]["top3"], "moy/classe", res["modeles"][nom]["top1_moyenne_par_classe"], res["modeles"][nom]["par_source"], flush=True)
for nom, V in [("dinov2-s", VD[idx]), ("fishial", VF[idx]), ("fishial+dinov2-s", np.hstack([VF[idx], VD[idx]]))]:
    clf = LogisticRegression(max_iter=3000, C=float(os.environ.get("C", "2")), class_weight="balanced")
    clf.fit(V[sel & ~test], y[sel & ~test])
    noter(nom, clf.predict_proba(V[sel & test]), list(clf.classes_))
# Fishial seul, sans entraînement (ses 866 espèces ramenées aux nôtres)
P = np.zeros(((sel & test).sum(), len(classes)))
for r, k in enumerate(np.where(sel & test)[0]):
    for rang, (lbl, p) in enumerate(lignes[idx[k]]["fishial"]):
        c = fishial_classe(lbl)
        if c in classes: P[r, classes.index(c)] = max(P[r, classes.index(c)], 10 - rang)
noter("fishial-sans-entrainement", P, classes)
json.dump(res, open(os.path.join(sortie, "scores.json"), "w"), ensure_ascii=False, indent=1, default=str)
