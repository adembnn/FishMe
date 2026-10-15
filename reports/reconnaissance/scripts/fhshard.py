import re,html,random,time,json,sys,urllib.request,glob
UA="FishMe-dataset/0.1 (contact: adembanni@gmail.com)"
urls=re.findall(r'<loc>([^<]*)</loc>',open('fishing_report-sitemap.xml').read())+re.findall(r'<loc>([^<]*)</loc>',open('fishing_report-sitemap2.xml').read())
random.seed(1); S=random.sample(urls,len(urls))
k,K=int(sys.argv[1]),int(sys.argv[2])
done=set()
for f in glob.glob('fh_sample*.jsonl'):
    for l in open(f):
        try: done.add(json.loads(l)['u'])
        except Exception: pass
S=[u for i,u in enumerate(S) if i%K==k and u not in done]
out=open(f'fh_sample_s{k}.jsonl','a')
for u in S:
    try: t=urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':UA}),timeout=30).read().decode('utf8','ignore')
    except Exception as e: print('ERR',u,e,flush=True); time.sleep(3); continue
    ti=re.search(r'og:title" content="([^"]*)"',t); ti=html.unescape(ti.group(1)) if ti else ''
    imgs=list(dict.fromkeys(re.findall(r'(?:src|href)="(https://www\.fisch-hitparade\.de/wp-content/uploads/[^"]+\.(?:jpg|jpeg|png|webp))"',t)))
    out.write(json.dumps({'u':u,'t':ti,'i':imgs})+'\n'); out.flush()
    time.sleep(1.5)
