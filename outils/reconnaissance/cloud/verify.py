import sys, copy, numpy as np, torch, json
from PIL import Image
sys.path.insert(0, "/home/user/r1"); from convert import Net
torch.set_num_threads(4)
z = np.load("work/all.npz"); names = z["names"]; sp = z["sp"]; F = z["F"]
rng = np.random.RandomState(7); te = np.where(sp == "test")[0]; pick = rng.choice(te, 500, replace=False)
heads = {n: np.load(f"out/{n}_tete.npz", allow_pickle=True) for n in ("six", "full")}
net = Net(*[heads["six"][k].astype(np.float32) for k in ("W1", "b1", "W2", "b2")], float(heads["six"]["T"])).eval()
def feat(net, x):
    e = net.d.embeddings; h = e.patch_embeddings.projection((x - net.m) / net.s).flatten(2).transpose(1, 2)
    h = torch.cat([e.cls_token.expand(len(x), -1, -1), h], 1) + net.pos
    for l in net.d.encoder.layer: h = l(h)
    h = net.d.layernorm(h); f = torch.cat([h[:, 0], h[:, 1:].mean(1)], 1); return f / f.norm(dim=1, keepdim=True)
def fq(w):  # int8 symétrique par canal de sortie, quantifié puis déquantifié
    s = w.abs().amax(dim=tuple(range(1, w.dim())), keepdim=True) / 127; return (w / s).round().clamp(-127, 127) * s
q = copy.deepcopy(net)
for m in q.d.modules():
    if isinstance(m, (torch.nn.Linear, torch.nn.Conv2d)): m.weight.data = fq(m.weight.data)
def load(n):
    im = Image.open("photos/" + n).convert("RGB").resize((224, 224), Image.BILINEAR); return torch.from_numpy(np.asarray(im).copy()).permute(2, 0, 1).float() / 255
Ff, Fq = [], []
for i in range(0, len(pick), 25):
    x = torch.stack([load(names[j]) for j in pick[i:i+25]])
    with torch.no_grad(): Ff.append(feat(net, x).numpy()); Fq.append(feat(q, x).numpy())
Ff, Fq = np.vstack(Ff), np.vstack(Fq); Fs = F[pick] / np.linalg.norm(F[pick], axis=1, keepdims=True)
print("cos(Net fp32, vecteurs du banc) moyen", float((Ff * Fs).sum(1).mean()), "min", float((Ff * Fs).sum(1).min()))
print("cos(int8, fp32) moyen", float((Fq * Ff).sum(1).mean()), "min", float((Fq * Ff).sum(1).min()))
def head(h, X):
    a = torch.tensor(X) @ torch.tensor(h["W1"]).T + torch.tensor(h["b1"]); a = torch.nn.functional.gelu(a)
    return torch.softmax((a @ torch.tensor(h["W2"]).T + torch.tensor(h["b2"])) / float(h["T"]), 1).numpy()
out = {}
for n, h in heads.items():
    P0, P1, P2 = head(h, Fs), head(h, Ff), head(h, Fq)
    out[n] = {"accord_top1_banc_vs_Net": float((P0.argmax(1) == P1.argmax(1)).mean()), "accord_top1_fp32_vs_int8": float((P1.argmax(1) == P2.argmax(1)).mean()),
              "ecart_proba_max": float(np.abs(P1 - P2).max()), "ecart_proba_moyen": float(np.abs(P1 - P2).mean())}
    cls = list(h["classes"]); y = z["y"][pick]; yy = np.where(np.isin(y, cls), y, "autre-poisson"); yi = np.array([cls.index(c) for c in yy])
    for nm, P in (("banc", P0), ("fp32", P1), ("int8", P2)):
        out[n]["top1_" + nm] = float((P.argmax(1) == yi).mean()); out[n]["top3_" + nm] = float((np.argsort(-P, 1)[:, :3] == yi[:, None]).any(1).mean())
print(json.dumps(out, indent=1)); json.dump(out, open("out/verif_quant.json", "w"), indent=1)
