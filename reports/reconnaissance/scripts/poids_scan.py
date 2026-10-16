import sys, json, glob, re, urllib.request, time
k, n = int(sys.argv[1]), int(sys.argv[2])
urls = sorted({json.loads(l)["u"] for f in glob.glob("/tmp/claude-0/agent-peche/fh_sample*.jsonl") for l in open(f) if l.strip().startswith("{")})
out = open(f"/tmp/claude-0/pl/fhw_{k}.jsonl", "a")
done = set()
try: done = {json.loads(l)["u"] for l in open(f"/tmp/claude-0/pl/fhw_{k}.jsonl")}
except Exception: pass
for i, u in enumerate(urls):
    if i % n != k or u in done: continue
    try:
        h = urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"}), timeout=20).read().decode("utf8", "ignore")
        t = re.sub(r"<script.*?</script>|<style.*?</style>", " ", h, flags=re.S); t = re.sub(r"<[^>]+>", " ", t); t = re.sub(r"\s+", " ", t)
        a = re.search(r"Fischart (.+?) Gewichtung ([0-9.,]+) kg Länge ([0-9.,]+) cm", t)
        out.write(json.dumps({"u": u, "art": a and a.group(1), "kg": a and a.group(2), "cm": a and a.group(3)}) + "\n"); out.flush()
    except Exception as e:
        time.sleep(2)
print("FINI")
