"""Variété de carpe (commune / miroir / cuir) depuis les prises allemandes étiquetées, sur les vecteurs DINOv2-S. Test par pêcheur."""
import csv, glob, json, re, hashlib, collections, numpy as np
from sklearn.linear_model import LogisticRegression
F = "/root/fishdata"
V = {"Schuppenkarpfen": "commune", "Wildkarpfen": "commune", "Spiegelkarpfen": "miroir", "Zeilenkarpfen": "miroir", "Lederkarpfen": "cuir"}
var = {}
for f in glob.glob("/tmp/claude-0/agent-peche/fh_sample*.jsonl"):
    for l in open(f):
        try: p = json.loads(l)
        except Exception: continue
        s = re.split(r"\s+[–-]\s+", p["t"])[0].strip()
        if s in V and len(p["i"]) >= 1:
            for u in p["i"]: var[u] = V[s]
lab = {}
for r in csv.reader(open(F + "/manifeste_peche_fisch-hitparade.telecharge.csv")):
    if len(r) >= 7 and r[2] == "ok" and r[3] in var: lab[f"{r[0]}/{r[1]}.jpg"] = (var[r[3]], r[4])
fs = [json.loads(l)["f"] for l in open(F + "/traite.jsonl")]
X = np.fromfile(F + "/traite.dino.f32", np.float32)[: len(fs) * 768].reshape(-1, 768)
rows = [(i, *lab[f]) for i, f in enumerate(fs[: len(X)]) if f in lab]
print("photos étiquetées :", len(rows), collections.Counter(r[1] for r in rows))
x = X[[r[0] for r in rows]]; x = x / np.linalg.norm(x, axis=1, keepdims=True); y = np.array([r[1] for r in rows])
te = np.array([int(hashlib.sha1(r[2].encode()).hexdigest(), 16) % 4 == 0 for r in rows])
m = LogisticRegression(C=2, class_weight="balanced", max_iter=3000).fit(x[~te], y[~te])
p = m.predict(x[te])
print("test :", int(te.sum()), "photos, juste :", round((p == y[te]).mean() * 100, 1), "%")
for c in m.classes_:
    k = y[te] == c
    print(" ", c, int(k.sum()), round((p[k] == c).mean() * 100, 1), "%", collections.Counter(p[k]).most_common(3))
