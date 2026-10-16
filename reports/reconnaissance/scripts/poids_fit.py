"""Recale a, b (W g = a·L cm^b) sur les prises pesées et mesurées de fisch-hitparade. Régression log-log robuste (Huber), écarte les points à plus de 3 écarts."""
import glob, json, csv, collections, numpy as np
from sklearn.linear_model import HuberRegressor
DE = {"Bachforelle":"truite-commune","Meerforelle":"truite-commune","Seeforelle":"truite-commune","Regenbogenforelle":"truite-arc-en-ciel","Lachs":"saumon","Bachsaibling":"omble-fontaine","Seesaibling":"omble-chevalier","Amerikanischer Seesaibling":"cristivomer","Äsche":"ombre","Huchen":"huchon","Renke":"coregones","Maräne":"coregones","Hecht":"brochet","Zander":"sandre","Barsch":"perche","Kaulbarsch":"gremille","Schwarzbarsch":"black-bass","Forellenbarsch":"black-bass","Sonnenbarsch":"perche-soleil","Wels":"silure","Zwergwels":"poisson-chat","Schuppenkarpfen":"carpe-commune","Spiegelkarpfen":"carpe-commune","Wildkarpfen":"carpe-commune","Zeilenkarpfen":"carpe-commune","Lederkarpfen":"carpe-commune","Graskarpfen":"carpe-amour","Silberkarpfen":"carpe-argentee","Marmorkarpfen":"carpe-grosse-tete","Rotauge":"gardon","Rotfeder":"rotengle","Brasse":"breme-commune","Güster":"breme-bordeliere","Döbel (Aitel)":"chevesne","Döbel":"chevesne","Schleie":"tanche","Barbe":"barbeau","Hasel":"vandoise","Aland":"ide","Nase":"hotu","Ukelei":"ablette","Gründling":"goujon","Karausche":"carassin-commun","Giebel":"carassin-argente","Rapfen":"aspe","Quappe":"lotte","Aal":"anguille","Stör":"esturgeon","Flunder":"flet","Meeräsche":"mulet"}
pts = collections.defaultdict(list); autres = collections.Counter()
for f in glob.glob("/tmp/claude-0/pl/fhw_*.jsonl"):
    for l in open(f):
        j = json.loads(l)
        if not j["art"] or not j["kg"]: continue
        c = DE.get(j["art"])
        if not c: autres[j["art"]] += 1; continue
        try: kg, cm = float(j["kg"].replace(",", ".")), float(j["cm"].replace(",", "."))
        except ValueError: continue
        if kg > 0 and cm > 5: pts[c].append((cm, kg * 1000))
res = {}
for c, P in sorted(pts.items()):
    P = np.array(P)
    if len(P) < 15: res[c] = (len(P), None); continue
    x, y = np.log10(P[:, 0]), np.log10(P[:, 1])
    m = HuberRegressor().fit(x[:, None], y); r = y - m.predict(x[:, None]); k = np.abs(r) < 3 * np.std(r)
    m = HuberRegressor().fit(x[k, None], y[k])
    b, a = m.coef_[0], 10 ** m.intercept_
    res[c] = (int(k.sum()), (a, b, P[k, 0].min(), P[k, 0].max(), float(np.std(y[k] - m.predict(x[k, None])))))
json.dump({c: v for c, v in res.items()}, open("/tmp/claude-0/pl/fit.json", "w"))
lit = {r["id"]: r for r in csv.DictReader(open("/mnt/project-files/build/reconnaissance/poids-longueur/poids_longueur.csv"))}
for c, (n, v) in res.items():
    if not v: print(f"{c:20} n={n} trop peu"); continue
    a, b, lo, hi, s = v; L = (lo + hi) / 2
    li = lit.get(c, {}); la, lb = li.get("a"), li.get("b")
    w_lit = float(la) * L ** float(lb) if la else None
    print(f"{c:20} n={n:4} a={a:.5g} b={b:.3f} L {lo:.0f}-{hi:.0f} sd10={s:.3f} | à {L:.0f} cm : nous {a*L**b/1000:.2f} kg, lit {w_lit/1000 if w_lit else float('nan'):.2f} kg ({li.get('statut')})")
print("non reliés :", autres.most_common(15))
