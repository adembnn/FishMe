import csv, os, sys
rows=[]
for f,k in (("work/train.csv","train"),("work/jeu-test.csv","test")):
    for r in csv.DictReader(open(f)): rows.append((k,r["photo"],r["classe"]))
ex=[r for r in rows if os.path.exists("photos/"+r[1])]
print(len(rows), len(ex))
done=set(l.strip() for l in open("work/done_list.txt")) if os.path.exists("work/done_list.txt") else set()
new=[r[1] for r in ex if r[1] not in done]
n=sys.argv[1]
open(f"work/list_{n}.txt","w").write("\n".join("photos/"+p for p in new)+"\n")
open("work/done_list.txt","a").write("\n".join(new)+"\n")
print("new",len(new))
