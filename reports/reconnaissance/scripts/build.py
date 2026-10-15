import json,csv,re,collections
H='classe,gbif_id,taxon,dataset,base,pays,photographe,licence,createur,url,type_media'.split(',')
cls={l.split('\t')[0]:l.rstrip('\n').split('\t')[2] for l in open('/tmp/claude-0/reco/classes.tsv') if not l.startswith('id\t')}
# chytej
rows=json.load(open('chy_rows.json')); seen=set(); out=[]
for c,s,y,im,au in rows:
    k=(y,im)
    if k in seen or c not in cls: continue
    seen.add(k)
    out.append([c,f'ch-{y}-{im[3:-4]}',cls[c].split('|')[0],'chytej.cz trofejni ulovky','PECHE','CZ',au,'tous droits réservés',au,f'https://www.chytej.cz/foto/trofeje/{y}/{im}','StillImage'])
w=csv.writer(open('/root/fishdata/manifeste_peche_chytej.csv','w',newline='')); w.writerow(H); w.writerows(out)
print('chytej',len(out),collections.Counter(r[0] for r in out).most_common())
# fisch-hitparade
D={'Regenbogenforelle':'truite-arc-en-ciel','Bachforelle':'truite-commune','Meerforelle':'truite-commune','Seeforelle':'truite-commune','Äsche':'ombre','Huchen':'huchon','Lachs':'saumon','Hecht':'brochet','Zander':'sandre','Barsch':'perche','Kaulbarsch':'gremille','Wels / Waller':'silure','Spiegelkarpfen':'carpe-commune','Schuppenkarpfen':'carpe-commune','Zeilenkarpfen':'carpe-commune','Lederkarpfen':'carpe-commune','Wildkarpfen':'carpe-commune','Karpfen':'carpe-commune','Graskarpfen':'carpe-amour','Silberkarpfen':'carpe-argentee','Marmorkarpfen':'carpe-grosse-tete','Rotauge':'gardon','Rotfeder':'rotengle','Brasse':'breme-commune','Güster':'breme-bordeliere','Döbel':'chevesne','Schleie':'tanche','Barbe':'barbeau','Aland':'ide','Nase':'hotu','Laube / Ukelei':'ablette','Moderlieschen':'able-heckel','Giebel':'carassin-argente','Karausche':'carassin-commun','Rapfen':'aspe','Gründling':'goujon','Quappe':'lotte','Aal':'anguille','Hasel':'vandoise','Döbel (Aitel)':'chevesne','Maräne':'coregones','Seesaibling / Saibling':'omble-chevalier','Bachsaibling':'omble-fontaine','Katzenwels / Zwergwels':'poisson-chat','Grundel':'gobie-invasif','Flunder':'flet','Meeräsche':'mulet'}
import glob
pages=[json.loads(l) for f in sorted(glob.glob('fh_sample*.jsonl')) for l in open(f) if l.strip()]
cnt=collections.Counter(i for p in pages for i in p['i'])
out=[];sp=collections.Counter();unk=collections.Counter()
for p in pages:
    s=re.split(r'\s+[–-]\s+',p['t'])[0].strip(); sp[s]+=1
    imgs=[i for i in p['i'] if cnt[i]==1] if len(p['i'])>1 else p['i']
    if len(imgs)!=1: continue
    c=D.get(s)
    if not c:
        unk[s]+=1; continue
    slug=p['u'].rstrip('/').split('/')[-1]
    user=slug
    out.append([c,f'fh-{slug}',cls[c].split('|')[0],'fisch-hitparade.de Fangmeldungen','PECHE','DE','inconnu',"tous droits réservés",'inconnu',imgs[0],'StillImage'])
w=csv.writer(open('/root/fishdata/manifeste_peche_fisch-hitparade.csv','w',newline='')); w.writerow(H); w.writerows(out)
print('fh pages',len(pages),'rows',len(out),collections.Counter(r[0] for r in out).most_common()); print('unmapped',unk.most_common(15)); print(sp.most_common(40))
