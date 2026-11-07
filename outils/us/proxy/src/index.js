// Worker Cloudflare « fishme-us-proxy » : garde la clé api.data.gov, met en cache les mesures USGS par station.
// Secret : `npx wrangler secret put USGS_API_KEY` (jamais dans git). Aucune position n'est reçue ni enregistrée.
import { analyserChemin, urlAmont, enTetesAmont, enrichir, erreurPourAmont, TTL_SECONDES } from "./logique.js";

const JSON_ENTETES = { "Content-Type": "application/json; charset=utf-8" };

function json(corps, statut = 200, extra = {}) {
  return new Response(JSON.stringify(corps), { status: statut, headers: { ...JSON_ENTETES, ...extra } });
}

export default {
  async fetch(requete, env, ctx) {
    if (requete.method !== "GET") return json({ erreur: "methode_refusee" }, 405, { Allow: "GET" });
    // Seul le chemin est lu : la chaîne de requête est ignorée.
    const route = analyserChemin(new URL(requete.url).pathname);
    if (!route) return json({ erreur: "introuvable" }, 404);
    if (route.route === "sante") return json({ ok: true });

    // Clé de cache synthétique : elle ne contient que l'identifiant de station.
    const cle = new Request(`https://cache.fishme.invalid/station/${route.id}`);
    const cache = caches.default;
    const enCache = await cache.match(cle);
    if (enCache) return enCache;

    let amont;
    try {
      amont = await fetch(urlAmont(route.id), { headers: enTetesAmont(env.USGS_API_KEY) });
    } catch {
      return json({ erreur: "source_indisponible" }, 502);
    }
    if (!amont.ok) {
      const e = erreurPourAmont(amont.status, amont.headers.get("Retry-After"));
      return json(e.corps, e.statut, e.retryApres ? { "Retry-After": e.retryApres } : {});
    }
    let corps;
    try {
      corps = enrichir(await amont.json(), new Date().toISOString());
    } catch {
      return json({ erreur: "source_illisible" }, 502);
    }
    const reponse = json(corps, 200, { "Cache-Control": `public, max-age=${TTL_SECONDES}` });
    ctx.waitUntil(cache.put(cle, reponse.clone()));
    return reponse;
  },
};
