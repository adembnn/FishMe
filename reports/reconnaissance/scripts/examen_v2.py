import pickle, numpy as np, pandas as pd, json, collections
coef, b, c, xe, P, photos = pickle.load(open("m.pkl", "rb")); c = np.array(c)
te = pd.read_csv("/root/fishdata/eval8/jeu-test.csv"); te = te.set_index("photo").loc[photos].reset_index()
y = te.classe.values; src = te.source.values
print(collections.Counter(src))
top = np.argsort(-P, 1)[:, :3]; t1 = c[top[:, 0]]; pmax = P.max(1)
in3 = np.array([y[i] in c[top[i]] for i in range(len(y))])
SP = {"pas-un-poisson", "autre-poisson", "gambusie"}
def sc(m): return dict(n=int(m.sum()), top1=round((t1[m] == y[m]).mean() * 100, 1), top3=round(in3[m].mean() * 100, 1))
peche = np.isin(src, ["affine", "peche"]) if "peche" in set(src) else np.array([s in ("affine",) or s.startswith("peche") for s in src])
R = {}
fish = ~np.isin(y, list(SP))
R["tout le test, poissons"] = sc(fish)
R["prises AFFiNe"] = sc((src == "affine") & fish)
R["prises de pêcheurs (AFFiNe + autres)"] = sc(peche & fish)
# refus : la grille s'ouvre (meilleure étiquette sous 0,4, ou classe spéciale en tête)
refus = (pmax < 0.4) | np.isin(t1, list(SP))
npp = y == "pas-un-poisson"
R["pas un poisson refusés (%)"] = round(refus[npp].mean() * 100, 1); R["n pas un poisson"] = int(npp.sum())
R["pas un poisson : une espèce proposée (%)"] = round((~refus[npp]).mean() * 100, 1)
R["vrais poissons (prises) qui ouvrent la grille (%)"] = round(refus[peche & fish].mean() * 100, 1)
ok = ~refus & peche & fish
R["prises proposées : 1re proposition juste (%)"] = round((t1[ok] == y[ok]).mean() * 100, 1)
cls = []
for k in sorted(set(y[fish])):
    m = (y == k) & peche
    if m.sum() < 10: m = (y == k)
    cls.append((k, int(m.sum()), round((t1[m] == k).mean() * 100, 1), round(in3[m].mean() * 100, 1)))
R["classes"] = cls
json.dump(R, open("examen.json", "w"), ensure_ascii=False, indent=1)
for k, v in R.items():
    if k != "classes": print(k, v)
for k, n, a, b3 in cls: print(f"{k:22} {n:5} {a:5} {b3:5}" + ("  <80 top3" if b3 < 80 and n >= 10 else "") + ("  (peu)" if n < 10 else ""))
G = {"able-heckel": "ablette", "carassin-argente": "carassin", "carassin-commun": "carassin", "lamproie-planer": "lamproie", "lamproie-fluviatile": "lamproie", "lamproie-marine": "lamproie", "loche-franche": "loche", "loche-riviere": "loche", "grande-alose": "alose", "alose-feinte": "alose"}
g = lambda a: np.array([G.get(v, v) for v in a])
yg = g(y); tg = np.array([g(c[top[i]]) for i in range(len(y))])
print("\n-- par groupe de sosies (comme l'app propose) --")
grp = []
for k in sorted(set(G.values())):
    m = (yg == k) & peche
    if m.sum() < 10: m = (yg == k)
    if m.sum(): grp.append((k, int(m.sum()), round((tg[m, 0] == k).mean() * 100, 1), round(np.mean([k in tg[i] for i in np.where(m)[0]]) * 100, 1))); print(grp[-1])
R["groupes"] = grp; json.dump(R, open("examen.json", "w"), ensure_ascii=False, indent=1)
