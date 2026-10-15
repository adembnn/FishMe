import numpy as np, torch, sys
torch.set_num_threads(1)
def train_head(X, y, ncls, kind="linear", hidden=512, epochs=60, wd=1e-4, lr=2e-3, ls=0.1, drop=0.3, seed=0, cw=None):
    torch.manual_seed(seed)
    X = torch.tensor(X); y = torch.tensor(y)
    m = torch.nn.Linear(768, ncls) if kind == "linear" else torch.nn.Sequential(torch.nn.Dropout(drop), torch.nn.Linear(768, hidden), torch.nn.GELU(), torch.nn.Dropout(drop), torch.nn.Linear(hidden, ncls))
    opt = torch.optim.AdamW(m.parameters(), lr=lr, weight_decay=wd)
    n = len(X); steps = epochs * ((n + 255) // 256); sch = torch.optim.lr_scheduler.OneCycleLR(opt, lr, total_steps=steps)
    w = torch.tensor(cw, dtype=torch.float32) if cw is not None else None
    for e in range(epochs):
        m.train(); perm = torch.randperm(n)
        for i in range(0, n, 256):
            b = perm[i:i+256]; xb = X[b] * 12  # échelle : vecteurs unitaires -> logits utilisables
            loss = torch.nn.functional.cross_entropy(m(xb), y[b], weight=w, label_smoothing=ls)
            opt.zero_grad(); loss.backward(); opt.step(); sch.step()
    return m.eval()
