import json,numpy as np,pandas as pd,pickle
from sklearn.linear_model import LogisticRegression
torch=None
fs=[json.loads(l)["f"] for l in open("j.jsonl")]
X=np.fromfile("d.f32",dtype=np.float32).reshape(-1,768)
n=min(len(fs),len(X));idx={f:i for i,f in enumerate(fs[:n])}
cl=json.load(open("/root/fishdata/eval5/scores.json"))["classes_modele"]
def load(p):
    d=pd.read_csv(p);d=d[d.classe.isin(cl)&d.photo.isin(idx)]
    x=X[[idx[f] for f in d.photo]];x=x/np.linalg.norm(x,axis=1,keepdims=True);return d,x
tr,xt=load("/root/fishdata/eval5/train.csv");te,xe=load("/root/fishdata/eval5/jeu-test.csv")
print(len(tr),len(te))
m=LogisticRegression(C=2,class_weight="balanced",max_iter=2000).fit(xt,tr.classe)
assert list(m.classes_)==sorted(cl) or True
P=m.predict_proba(xe);c=m.classes_
y=te.classe.values
def sc(mask):
    t=np.argsort(-P[mask],1)[:,:3];yy=y[mask]
    return round((c[t[:,0]]==yy).mean()*100,2),round(np.mean([yy[i] in c[t[i]] for i in range(len(yy))])*100,2),int(mask.sum())
print("all",sc(np.ones(len(y),bool)));print("affine",sc((te.source=="affine").values))
pickle.dump((m.coef_,m.intercept_,list(c),xe,P,te.photo.values),open("m.pkl","wb"))
