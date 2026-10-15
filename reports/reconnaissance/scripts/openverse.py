"""Openverse (photos Flickr sous licence CC), 200 requêtes/jour sans compte. Sortie au format du manifeste GBIF."""
import csv, json, sys, time, urllib.request, urllib.parse
REQ = {"truite-commune": ["brown trout caught", "Salmo trutta"], "truite-arc-en-ciel": ["rainbow trout caught", "Oncorhynchus mykiss"],
 "ombre": ["grayling fish", "Thymallus thymallus"], "brochet": ["pike fish caught", "Esox lucius"], "sandre": ["zander fish", "Sander lucioperca"],
 "perche": ["perch fish caught", "Perca fluviatilis"], "black-bass": ["largemouth bass caught", "Micropterus salmoides"],
 "perche-soleil": ["pumpkinseed sunfish", "Lepomis gibbosus"], "silure": ["wels catfish", "Silurus glanis"],
 "carpe-commune": ["carp fishing", "Cyprinus carpio"], "gardon": ["roach fish", "Rutilus rutilus"], "rotengle": ["rudd fish", "Scardinius erythrophthalmus"],
 "breme-commune": ["bream fish caught", "Abramis brama"], "chevesne": ["chub fish caught", "Squalius cephalus"], "tanche": ["tench fish", "Tinca tinca"],
 "barbeau": ["barbel fish", "Barbus barbus"], "ablette": ["bleak fish", "Alburnus alburnus"], "goujon": ["gudgeon fish", "Gobio gobio"],
 "carassin-argente": ["crucian carp", "Carassius gibelio"], "anguille": ["european eel", "Anguilla anguilla"]}
fo = open(sys.argv[1], "a", newline="", buffering=1); out = csv.writer(fo)
FAITS = set(sys.argv[2:])
vus = set(); n = 0
for classe, qs in REQ.items():
    if classe in FAITS: continue
    for q in qs:
        for page in range(1, 6):
            u = "https://api.openverse.org/v1/images/?" + urllib.parse.urlencode({"q": q, "page_size": 20, "page": page})
            try:
                d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "FishMe-dataset/0.1 (adembanni@gmail.com)"}), timeout=60))
            except Exception as e:
                print("erreur", classe, q, page, e, flush=True); time.sleep(5); break
            n += 1
            for r in d["results"]:
                if r["url"] in vus or "nd" in (r.get("license") or ""): continue
                vus.add(r["url"])
                out.writerow([classe, "ov-" + r["id"], q, "openverse-" + r.get("source", ""), "OPENVERSE", "",
                              r.get("creator") or "", r.get("license") or "", r.get("creator") or "", r["url"], ""])
            time.sleep(3.2)
            if page >= d.get("page_count", 0): break
    print(classe, n, flush=True)
