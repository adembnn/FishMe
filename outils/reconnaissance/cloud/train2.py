"""Tête MLP (768-512-K) sur DINOv2-S plein cadre ; examen d'EXAMEN.md. usage: train2.py sortie [especes,séparées,par,virgule]"""
import sys, json, collections, numpy as np, torch
sys.path.insert(0, "/home/user/r1"); from head import train_head
out = sys.argv[1]; fixes = sys.argv[2].split(",") if len(sys.argv) > 2 else None
z = np.load("work/all.npz"); F = z["F"] / np.linalg.norm(z["F"], axis=1, keepdims=True); F = F.astype(np.float32)
y0 = z["y"]; sp = z["sp"]; sr = z["src"]
y0 = np.where(np.isin(y0, ["autre-poisson-unsplash", "autre-poisson-vimbe"]), "autre-poisson", y0)
tr, te = sp == "train", sp == "test"; AUTRE = ["pas-un-poisson", "autre-poisson"]
ctr, cte = collections.Counter(y0[tr]), collections.Counter(y0[te])
esp = fixes or sorted(c for c in set(y0) if c not in AUTRE and ctr[c] >= 30 and cte[c] >= 10)
idx = np.where(tr)[0]; rng = np.random.RandomState(1); rng.shuffle(idx); v = idx[:len(idx)//6]; t = idx[len(idx)//6:]
def prep(esp):
    cls = sorted(esp + AUTRE); y = np.where(np.isin(y0, cls), y0, "autre-poisson"); yi = np.array([cls.index(c) for c in y])
    cnt = np.bincount(yi[tr], minlength=len(cls)); cw = cnt.sum() / (len(cls) * np.maximum(cnt, 1))
    return cls, y, yi, cw
def logits(m, X):
    with torch.no_grad(): return m(torch.tensor(X) * 12).numpy()
def softmax(Z):
    Z = Z - Z.max(1, keepdims=True); P = np.exp(Z); return P / P.sum(1, keepdims=True)
while True:
    cls, y, yi, cw = prep(esp)
    m = train_head(F[tr], yi[tr], len(cls), "mlp", hidden=512, epochs=40, cw=cw)
    Z = logits(m, F[te]); top = np.argsort(-Z, 1)[:, :3]; yt = y0[te]
    rep = {}
    for c in esp:
        k = cls.index(c); mk = yt == c
        rep[c] = (int(mk.sum()), float((top[mk, 0] == k).mean()), float((top[mk] == k).any(1).mean()))
    mauvais = [c for c in esp if rep[c][2] < 0.8 or rep[c][0] < 10]
    print("espèces", len(esp), "top1 moy", round(np.mean([rep[c][1] for c in esp]), 3), "top3 moy", round(np.mean([rep[c][2] for c in esp]), 3), "sortent:", mauvais, flush=True)
    if not mauvais or fixes: break
    esp = [c for c in esp if c not in mauvais]
# calibration sur validation interne (modèle d'essai entraîné sans la validation)
mv = train_head(F[t], yi[t], len(cls), "mlp", hidden=512, epochs=40, cw=cw)
Zv = logits(mv, F[v]); yv = y[v]; best = (1e9, 1)
for T in (0.5, 0.65, 0.8, 1, 1.25, 1.5, 2, 2.5, 3):
    lp = np.log(softmax(Zv / T) + 1e-12); nll = -np.mean(lp[np.arange(len(v)), yi[v]]); best = min(best, (nll, T))
T = best[1]; Pv = softmax(Zv / T); pv = np.array(cls)[Pv.argmax(1)]; cv = Pv.max(1)
hors_v = ~np.isin(yv, esp); tau = 0.0
for th in np.arange(0.0, 0.99, 0.01):    # plus petit seuil refusant >= 92 % des photos hors liste de la validation
    ref = np.isin(pv, AUTRE) | (cv < th)
    if ref[hors_v].mean() >= 0.92: tau = float(round(th, 2)); break
print("T", T, "tau", tau, flush=True)
P = softmax(Z / T); top = np.argsort(-P, 1)[:, :3]; cl = np.array(cls); ytk = np.array([cls.index(c) if c in cls else -1 for c in yt])
isesp = np.isin(yt, esp); st = sr[te]
res = {"classes": cls, "especes": esp, "T": T, "tau": tau, "n_train": int(tr.sum()), "n_test": int(te.sum())}
pe = {}
for c in esp:
    k = cls.index(c); mk = yt == c
    pe[c] = {"n": int(mk.sum()), "top1": round(float((top[mk, 0] == k).mean()), 3), "top3": round(float((top[mk] == k).any(1).mean()), 3)}
res["par_espece"] = pe
res["top1_moy"] = round(float(np.mean([a["top1"] for a in pe.values()])), 3); res["top3_moy"] = round(float(np.mean([a["top3"] for a in pe.values()])), 3)
res["micro"] = {"n": int(isesp.sum()), "top1": round(float((top[isesp, 0] == ytk[isesp]).mean()), 3), "top3": round(float((top[isesp] == ytk[isesp, None]).any(1).mean()), 3)}
res["par_source"] = {}
for s in sorted(set(st)):
    mk = isesp & (st == s)
    if mk.sum(): res["par_source"][s] = {"n": int(mk.sum()), "top1": round(float((top[mk, 0] == ytk[mk]).mean()), 3), "top3": round(float((top[mk] == ytk[mk, None]).any(1).mean()), 3)}
refus = np.isin(cl[top[:, 0]], AUTRE) | (P.max(1) < tau); hl = ~isesp
res["refus"] = {"pas_un_poisson": {"n": int((yt == "pas-un-poisson").sum()), "refuses": round(float(refus[yt == "pas-un-poisson"].mean()), 3)},
                "autre_poisson_et_especes_sorties": {"n": int((hl & (yt != "pas-un-poisson")).sum()), "refuses": round(float(refus[hl & (yt != "pas-un-poisson")].mean()), 3)},
                "hors_liste_total": {"n": int(hl.sum()), "refuses": round(float(refus[hl].mean()), 3)},
                "vrais_poissons_refuses_a_tort": round(float(refus[isesp].mean()), 3)}
keep = isesp & ~refus
res["avec_seuil"] = {"couverture": round(float((~refus[isesp]).mean()), 3), "justesse_top1_des_gardees": round(float((top[keep, 0] == ytk[keep]).mean()), 3)}
ex = {"1_top3_moy>=0.90": res["top3_moy"] >= 0.90, "2_top1_moy>=0.70": res["top1_moy"] >= 0.70, "3_top3_chaque>=0.80": all(a["top3"] >= 0.8 for a in pe.values()),
      "4_n_test>=10": all(a["n"] >= 10 for a in pe.values()), "5_hors_liste_refuses>=0.90": res["refus"]["hors_liste_total"]["refuses"] >= 0.90}
res["examen"] = ex; res["examen_passe"] = all(ex.values())
json.dump(res, open(out + "_scores.json", "w"), ensure_ascii=False, indent=1)
sd = m.state_dict(); W1, b1, W2, b2 = [sd[k].numpy() for k in ("1.weight", "1.bias", "4.weight", "4.bias")]
np.savez(out + "_tete.npz", W1=W1 * 12, b1=b1, W2=W2, b2=b2, T=np.float32(T), classes=np.array(cls))
open(out + "_classes.txt", "w").write("\n".join(cls) + "\n")
print(json.dumps({k: res[k] for k in ("top1_moy", "top3_moy", "micro", "par_source", "refus", "avec_seuil", "examen")}, ensure_ascii=False))
