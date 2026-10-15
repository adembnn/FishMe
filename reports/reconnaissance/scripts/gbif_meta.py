"""Liste les photos GBIF par classe, hors iNaturalist, Observation.org, ADN Kenai et musées.
Sortie : manifeste_gbif.csv (une ligne par photo)."""
import csv, json, sys, time, urllib.request, urllib.parse
API = "https://api.gbif.org/v1"
EXCLUS = {"50c9509d-22c7-4a22-a47d-8c48425ef4a7": "inaturalist",
          "8a863029-f435-446a-821e-275f4f641165": "observation.org",
          "b88e40a8-c39e-4f8f-962a-7f6d93a977a4": "kenai-adn"}
BASES = ["HUMAN_OBSERVATION", "MACHINE_OBSERVATION", "OCCURRENCE", "MATERIAL_SAMPLE"]

def get(path, **params):
    q = urllib.parse.urlencode(params, doseq=True)
    for essai in range(5):
        try:
            with urllib.request.urlopen(f"{API}{path}?{q}", timeout=60) as r:
                return json.load(r)
        except Exception as e:
            time.sleep(2 ** essai)
    raise RuntimeError(path)

def cle(latin):
    m = get("/species/match", name=latin, kingdom="Animalia", strict="true")
    return m.get("usageKey"), m.get("rank"), m.get("matchType")

classes = list(csv.DictReader(open(sys.argv[1]), delimiter="\t"))
out = csv.writer(open(sys.argv[2], "w", newline=""))
out.writerow(["classe", "gbif_id", "taxon", "dataset", "base", "pays", "photographe", "licence", "createur", "url", "type_media"])
bilan = []
for c in classes:
    total = 0; exclus = {}
    for latin in c["latins"].split("|"):
        k, rank, mt = cle(latin)
        if not k:
            print("pas de clé", latin, file=sys.stderr); continue
        geo = {"continent": "EUROPE"} if rank == "GENUS" else {}
        f = get("/occurrence/search", taxonKey=k, mediaType="StillImage", basisOfRecord=BASES,
                limit=0, facet="datasetKey", facetLimit=500, **geo)
        for fc in (f.get("facets") or [{"counts": []}])[0]["counts"]:
            ds = fc["name"]
            if ds in EXCLUS:
                exclus[EXCLUS[ds]] = exclus.get(EXCLUS[ds], 0) + fc["count"]; continue
            off = 0
            while off < fc["count"] and off < 20000:
                p = get("/occurrence/search", taxonKey=k, mediaType="StillImage", basisOfRecord=BASES,
                        datasetKey=ds, limit=300, offset=off, **geo)
                for o in p["results"]:
                    for m in o.get("media", []):
                        if m.get("type") != "StillImage" or not m.get("identifier"): continue
                        out.writerow([c["id"], o["key"], o.get("species") or o.get("scientificName"), ds,
                                      o.get("basisOfRecord"), o.get("countryCode"),
                                      o.get("recordedBy") or m.get("rightsHolder") or m.get("creator") or "",
                                      m.get("license") or o.get("license") or "", m.get("creator") or "",
                                      m["identifier"], m.get("format") or ""])
                        total += 1
                off += 300
                if p.get("endOfRecords"): break
    bilan.append((c["id"], total, exclus))
    print(c["id"], total, exclus, flush=True)
json.dump(bilan, open(sys.argv[2] + ".bilan.json", "w"), ensure_ascii=False)
