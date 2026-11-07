// Cas de test partagés (node --test et jsc). Une assertion qui échoue lève une exception.
import { analyserChemin, urlAmont, enTetesAmont, enrichir, erreurPourAmont, AVERTISSEMENT_PROVISOIRE, ATTRIBUTION } from "../src/logique.js";

function egal(a, b, msg) {
  if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${msg || "différent"} : ${JSON.stringify(a)} != ${JSON.stringify(b)}`);
}
function vrai(c, msg) { if (!c) throw new Error(msg || "faux"); }

// FIXTURE : GeoJSON écrit à la main d'après la doc OGC API USGS.
const FIXTURE_PROVISOIRE = { type: "FeatureCollection", features: [
  { properties: { monitoring_location_id: "USGS-01646500", parameter_code: "00060", value: "2120", approval_status: "Provisional" } },
  { properties: { monitoring_location_id: "USGS-01646500", parameter_code: "00065", value: "2.85", approval_status: "Approved" } } ] };
const FIXTURE_APPROUVEE = { type: "FeatureCollection", features: [{ properties: { approval_status: "Approved" } }] };

export const cas = [
  ["chemin : identifiant complet ou numéro seul, normalisé", () => {
    egal(analyserChemin("/station/USGS-01646500"), { route: "station", id: "USGS-01646500" });
    egal(analyserChemin("/station/01646500/"), { route: "station", id: "USGS-01646500" });
    egal(analyserChemin("/station/usgs-01646500"), { route: "station", id: "USGS-01646500" });
  }],
  ["chemin : identifiants invalides et autres routes refusés", () => {
    for (const c of ["/station/", "/station/abc", "/station/USGS-1", "/station/USGS-01646500/x", "/station/../x", "/", "/lat/38.9/lon/-77.1", "/station/USGS-01646500%3Fapi_key"])
      egal(analyserChemin(c), null, c);
    egal(analyserChemin("/sante"), { route: "sante" });
  }],
  ["adresse USGS : seulement l'identifiant, pas de clé", () => {
    const u = urlAmont("USGS-01646500");
    vrai(u.startsWith("https://api.waterdata.usgs.gov/ogcapi/v1/collections/latest-continuous/items?"));
    vrai(u.includes("monitoring_location_id=USGS-01646500") && u.includes("parameter_code=00060,00065,00010"));
    vrai(!/api_key/i.test(u));
    let leve = false;
    try { urlAmont("USGS-01646500&x=1"); } catch { leve = true; }
    vrai(leve, "identifiant invalide accepté");
  }],
  ["en-têtes amont : clé en X-Api-Key seulement si présente, aucun en-tête client", () => {
    egal(enTetesAmont("K")["X-Api-Key"], "K");
    egal("X-Api-Key" in enTetesAmont(undefined), false);
    egal(Object.keys(enTetesAmont("K")).sort(), ["Accept", "User-Agent", "X-Api-Key"]);
  }],
  ["enrichir : avertissement si une valeur est provisoire, aucun sinon ; données conservées", () => {
    const a = enrichir(FIXTURE_PROVISOIRE, "2026-11-07T10:00:00Z");
    egal(a.fishme.avertissement, AVERTISSEMENT_PROVISOIRE);
    egal(a.fishme.attribution, ATTRIBUTION);
    egal(a.features.length, 2);
    egal(enrichir(FIXTURE_APPROUVEE, "x").fishme.avertissement, null);
    egal(enrichir({}, "x").fishme.avertissement, null);
  }],
  ["erreurs amont : 429 relayé avec Retry-After, 403 masqué en 502", () => {
    egal(erreurPourAmont(429, "5"), { statut: 429, corps: { erreur: "limite_atteinte" }, retryApres: "5" });
    egal(erreurPourAmont(429, null).retryApres, "60");
    egal(erreurPourAmont(403).statut, 502);
    egal(erreurPourAmont(404).statut, 404);
    egal(erreurPourAmont(500).corps, { erreur: "source_indisponible" });
  }],
];
