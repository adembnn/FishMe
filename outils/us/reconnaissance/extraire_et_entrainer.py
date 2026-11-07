"""Caractéristiques DINOv2-small (tronc partagé avec l'Europe) puis TÊTE US (régression logistique), évaluation, taille de la tête.
Chaîne identique à outils/reconnaissance/cloud/feats.py : image -> 224x224 -> DINOv2-small -> [CLS ; moyenne des patchs] (768) -> L2.
Entrée : <racine>/<espece>/<photo_id>.jpg + <racine>/licences.csv (colonnes espece, photo_id, classe_licence, observateur).
Dossiers possibles en plus des espèces : autre-poisson, pas-un-poisson (classes de la tête US).
Découpe PAR OBSERVATEUR (même règle que construire_jeu.py) ; test = photos « libre » seulement, sauf --test-toutes-licences (démo).
Sorties dans --sortie (hors dépôt) : caracteristiques.npz (cache), tete-us.npz (W, b, classes), rapport.json.
Environnement : venv hors dépôt (voir LISEZMOI.md) avec torch, transformers, scikit-learn, pillow, numpy.
Usage : venv/bin/python -I extraire_et_entrainer.py --racine /private/tmp/claude-501/us-reco/echantillon"""
import argparse, csv, json, os, sys, time
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun


def lire(racine):
    with open(os.path.join(racine, "licences.csv"), encoding="utf-8", newline="") as f:
        return [r for r in csv.DictReader(f) if os.path.exists(os.path.join(racine, r["espece"], r["photo_id"] + ".jpg"))]


def extraire(lignes, racine, cache):
    import torch
    from PIL import Image
    from transformers import AutoModel
    torch.set_num_threads(4)
    deja = dict(np.load(cache, allow_pickle=True)["F"].item()) if os.path.exists(cache) else {}
    a_faire = [r for r in lignes if r["photo_id"] not in deja]
    if a_faire:
        dino = AutoModel.from_pretrained("facebook/dinov2-small").eval()
        M = torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1)
        S = torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1)
        t = time.time()
        for i in range(0, len(a_faire), 16):
            lot, xs = a_faire[i:i + 16], []
            for r in lot:
                im = Image.open(os.path.join(racine, r["espece"], r["photo_id"] + ".jpg")).convert("RGB").resize((224, 224), Image.BILINEAR)
                xs.append(torch.from_numpy(np.asarray(im).copy()).permute(2, 0, 1).float() / 255)
            with torch.no_grad():
                o = dino(pixel_values=(torch.stack(xs) - M) / S)
            f = torch.cat([o.pooler_output, o.last_hidden_state[:, 1:].mean(1)], 1).numpy()
            f /= np.linalg.norm(f, axis=1, keepdims=True)
            for r, v in zip(lot, f):
                deja[r["photo_id"]] = v.astype(np.float32)
            print("  extrait", min(i + 16, len(a_faire)), "/", len(a_faire), round(time.time() - t), "s", flush=True)
        np.savez(cache, F=np.array(deja, dtype=object))
    return deja


def top_k(P, y, k):
    return float(np.mean([y[i] in np.argsort(-P[i])[:k] for i in range(len(y))])) if len(y) else float("nan")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--racine", required=True)
    ap.add_argument("--sortie", default=os.path.join(commun.DONNEES, "modele"))
    ap.add_argument("--test-toutes-licences", action="store_true")
    ap.add_argument("--parts", default="0.70,0.15,0.15", help="train,val,test (démo : 0.6,0,0.4)")
    ap.add_argument("--C", type=float, default=10.0)
    a = ap.parse_args()
    if commun.dans_un_depot_git(a.sortie):
        sys.exit("La sortie ne doit pas être dans un dépôt git")
    os.makedirs(a.sortie, exist_ok=True)
    pt, pv, pe = (float(x) for x in a.parts.split(","))
    parts = (("train", pt), ("val", pv), ("test", pe))
    lignes = [r for r in lire(a.racine) if r["classe_licence"] != "exclue"]
    F = extraire(lignes, a.racine, os.path.join(a.sortie, "caracteristiques.npz"))
    classes = sorted({r["espece"] for r in lignes})
    idx = {c: i for i, c in enumerate(classes)}
    lots = {"train": [], "val": [], "test": []}
    for r in lignes:
        lot = commun.decoupe_observateur(r["observateur"], parts=parts)
        if lot != "train" and r["classe_licence"] != "libre" and not (lot == "test" and a.test_toutes_licences):
            continue  # écartée, jamais versée dans train
        lots[lot].append(r)
    X = {k: np.stack([F[r["photo_id"]] for r in v]) if v else np.zeros((0, 768), np.float32) for k, v in lots.items()}
    y = {k: np.array([idx[r["espece"]] for r in v]) for k, v in lots.items()}
    print({k: len(v) for k, v in lots.items()}, "classes :", len(classes))
    if len(set(y["train"])) < 2:
        sys.exit("moins de 2 classes en entraînement")
    from sklearn.linear_model import LogisticRegression
    t = time.time()
    clf = LogisticRegression(C=a.C, max_iter=2000, class_weight="balanced").fit(X["train"] * 12, y["train"])
    # classes absentes de train : colonnes à -inf pour ne jamais les proposer
    W = np.full((len(classes), 768), 0, np.float32); b = np.full(len(classes), -30, np.float32)
    W[clf.classes_] = clf.coef_ * 12; b[clf.classes_] = clf.intercept_
    rapport = {"classes": classes, "effectifs": {k: len(v) for k, v in lots.items()}, "duree_entrainement_s": round(time.time() - t, 2),
               "avertissement": "Échantillon minuscule : ces chiffres prouvent que la chaîne marche, ils n'ont AUCUNE valeur statistique."}
    for k in ("val", "test"):
        if len(y[k]):
            Z = X[k] @ W.T + b
            P = np.exp(Z - Z.max(1, keepdims=True)); P /= P.sum(1, keepdims=True)
            rapport[k] = {"n": len(y[k]), "top1": round(top_k(P, y[k], 1), 3), "top3": round(top_k(P, y[k], 3), 3),
                          "confiance_moyenne_juste": round(float(np.mean([P[i].max() for i in range(len(y[k])) if P[i].argmax() == y[k][i]] or [0])), 3)}
    # tête quantifiée int8 (symétrique, par classe) : c'est la taille réellement livrée par région
    echelle = np.abs(W).max(1) / 127 + 1e-12
    Wq = np.round(W / echelle[:, None]).astype(np.int8)
    rapport["tete"] = {"classes": len(classes), "octets_int8": int(Wq.size + 4 * len(classes) * 2),
                       "octets_float16": int(W.size * 2 + len(classes) * 2),
                       "formule": "classes x 768 octets (int8) + 8 octets par classe (échelle + biais)"}
    np.savez(os.path.join(a.sortie, "tete-us.npz"), W=W, b=b, classes=np.array(classes), echelle=echelle, Wq=Wq)
    json.dump(rapport, open(os.path.join(a.sortie, "rapport.json"), "w"), ensure_ascii=False, indent=1)
    print(json.dumps(rapport, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
