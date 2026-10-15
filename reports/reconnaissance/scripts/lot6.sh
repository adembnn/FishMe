set -e
cd /tmp/claude-0/reco; F=/root/fishdata
python3 - <<'P'
import csv,json
F='/root/fishdata'; vus=set(json.loads(l)['f'] for l in open(F+'/traite.jsonl'))
out=[]
for m in ['peche_europe','public_us','peche_fisch-hitparade']:
    for r in csv.reader(open(f'{F}/manifeste_{m}.telecharge.csv')):
        if len(r)>2 and r[2]=='ok':
            f=f"{r[0]}/{r[1]}.jpg"
            if f not in vus: out.append(f)
out=list(dict.fromkeys(out)); open(F+'/liste6.txt','w').write('\n'.join(out)+'\n'); print('liste6', len(out))
P
NT=4 python3 scripts/traiter.py $F/photos $F/traite $F/liste6.txt > $F/traiter6.log 2>&1
python3 scripts/evaluer.py $F/traite $F/manifeste_gbif.csv $F/manifeste_unsplash.csv $F/manifeste_affine.csv $F/manifeste_ov1.csv $F/manifeste_ov2.csv $F/manifeste_peche_chytej.csv $F/manifeste_public_eol.csv $F/manifeste_peche_europe.csv $F/manifeste_public_us.csv $F/manifeste_peche_fisch-hitparade.csv --sortie $F/eval4 > $F/eval4.log 2>&1
python3 scripts/seuils.py $F/eval4 > $F/seuils4.log 2>&1
echo FINI
