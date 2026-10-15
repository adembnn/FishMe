"""Modèle retenu (Fishial + DINOv2-S, tête logistique) : calibration, seuil pour 95 % de 1res propositions justes, refus, top-20."""
import json, csv, numpy as np, collections, hashlib, sys
from sklearn.linear_model import LogisticRegression
pre = "/root/fishdata/traite"; ev = sys.argv[1]
L = [json.loads(l) for l in open(pre + ".jsonl")]; n = len(L)
VF = np.fromfile(pre + ".fishial.f32", np.float32).reshape(n, -1); VD = np.fromfile(pre + ".dino.f32", np.float32).reshape(n, -1)
VD /= np.linalg.norm(VD, axis=1, keepdims=True); V = np.hstack([VF, VD])
test = {r["photo"]: r["classe"] for r in csv.DictReader(open(ev + "/jeu-test.csv"))}
res = json.load(open(ev + "/scores.json")); classes = res["classes_modele"]
# reconstituer l'entraînement exactement comme evaluer.py : relancer evaluer garde la même logique ; ici on réutilise ses étiquettes
lab = {}
for r in csv.DictReader(open(ev + "/train.csv")): lab[r["photo"]] = r["classe"]
idx = {x["f"]: i for i, x in enumerate(L)}
tr = [(idx[f], c) for f, c in lab.items() if c in classes]; te = [(idx[f], c) for f, c in test.items() if c in classes]
Xtr = V[[i for i, _ in tr]]; ytr = np.array([c for _, c in tr]); Xte = V[[i for i, _ in te]]; yte = np.array([c for _, c in te])
# validation = 1/5 de l'entraînement, par empreinte de photo, pour la température
val = np.array([int(hashlib.sha1(L[i]["f"].encode()).hexdigest(), 16) % 5 == 0 for i, _ in tr])
clf = LogisticRegression(max_iter=3000, C=2, class_weight="balanced").fit(Xtr[~val], ytr[~val])
lv = clf.decision_function(Xtr[val]); yv = ytr[val]; K = list(clf.classes_)
def nll(T):
    z = lv / T; z -= z.max(1, keepdims=True); p = np.exp(z); p /= p.sum(1, keepdims=True)
    return -np.mean(np.log(p[np.arange(len(yv)), [K.index(c) for c in yv]] + 1e-12))
T = min(np.linspace(0.3, 5, 95), key=nll)
clf = LogisticRegression(max_iter=3000, C=2, class_weight="balanced").fit(Xtr, ytr)
z = clf.decision_function(Xte) / T; z -= z.max(1, keepdims=True); P = np.exp(z); P /= P.sum(1, keepdims=True)
K = list(clf.classes_); pred = np.array(K)[P.argmax(1)]; conf = P.max(1)
poissons = ~np.isin(yte, ["pas-un-poisson", "autre-poisson"])
out = {"temperature": round(float(T), 2)}
# seuil tau : plus petit seuil donnant 95 % de justes parmi les poissons au-dessus du seuil
for tau in np.linspace(0, 0.99, 100):
    m = poissons & (conf >= tau)
    if m.sum() and (pred[m] == yte[m]).mean() >= 0.95:
        out["seuil_95"] = {"tau": round(float(tau), 2), "part_des_photos_au_dessus": round(float(m.sum() / poissons.sum()), 3)}; break
npp = yte == "pas-un-poisson"
out["pas_un_poisson_refuses"] = round(float(np.isin(pred[npp], ["pas-un-poisson", "autre-poisson"]).mean()), 3)
out["poissons_pris_pour_pas_un_poisson"] = round(float((pred[poissons] == "pas-un-poisson").mean()), 3)
top20 = [r["id"] for r in csv.DictReader(open("/tmp/claude-0/reco/classes.tsv"), delimiter="\t") if r["top20"] == "1"]
m20 = np.isin(yte, top20); o = np.argsort(-P, 1)[:, :3]; t3 = np.array([[K[j] for j in row] for row in o])
out["top20"] = {"n": int(m20.sum()), "top1": round(float((pred[m20] == yte[m20]).mean()), 3), "top3": round(float((t3[m20] == yte[m20, None]).any(1).mean()), 3)}
srcs = {r["photo"]: r["source"] for r in csv.DictReader(open(ev + "/jeu-test.csv"))}
st = np.array([srcs[L[i]["f"]] for i, _ in te]); aff = (st == "affine") & poissons
for tau in np.linspace(0, 0.99, 100):
    m = aff & (conf >= tau)
    if m.sum() and (pred[m] == yte[m]).mean() >= 0.95:
        out["seuil_95_prises_affine"] = {"tau": round(float(tau), 2), "part_au_dessus": round(float(m.sum() / aff.sum()), 3)}; break
out["prises_affine"] = {"n": int(aff.sum()), "top1": round(float((pred[aff] == yte[aff]).mean()), 3), "top3": round(float((t3[aff] == yte[aff, None]).any(1).mean()), 3)}
print(json.dumps(out, ensure_ascii=False, indent=1)); json.dump(out, open(ev + "/seuils.json", "w"), ensure_ascii=False, indent=1)
