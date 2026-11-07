// Logique pure du proxy FishMe US : aucune dépendance à Cloudflare, testable sous node et sous jsc.
// Règle de confidentialité : la seule donnée lue dans une requête est le chemin /station/<identifiant>.
// Ni la chaîne de requête, ni les en-têtes, ni l'adresse IP ne sont lus, transmis ou enregistrés.

export const BASE_USGS = "https://api.waterdata.usgs.gov/ogcapi/v1";
export const PARAMETRES = "00060,00065,00010"; // débit (ft³/s), hauteur (ft), température de l'eau (°C)
export const TTL_SECONDES = 300;
export const ATTRIBUTION = "Données : U.S. Geological Survey (USGS), Water Data APIs";
export const AVERTISSEMENT_PROVISOIRE =
  "Donnée provisoire : elle n'a pas été validée par l'USGS et peut être révisée ou supprimée.";

const MOTIF_STATION = /^USGS-[0-9]{8,15}$/;

/** « /station/USGS-01646500 » (ou « /station/01646500 ») donne l'identifiant normalisé ; tout le reste donne null. */
export function analyserChemin(chemin) {
  if (chemin === "/sante") return { route: "sante" };
  const m = /^\/station\/([A-Za-z0-9-]{1,32})\/?$/.exec(chemin);
  if (!m) return null;
  const brut = m[1].toUpperCase();
  const id = /^[0-9]{8,15}$/.test(brut) ? "USGS-" + brut : brut;
  return MOTIF_STATION.test(id) ? { route: "station", id } : null;
}

/** L'adresse USGS pour une station : seul l'identifiant y figure. La clé part en en-tête, jamais dans l'adresse. */
export function urlAmont(id) {
  if (!MOTIF_STATION.test(id)) throw new Error("identifiant invalide");
  return `${BASE_USGS}/collections/latest-continuous/items?f=json&limit=50&monitoring_location_id=${id}&parameter_code=${PARAMETRES}`;
}

export function enTetesAmont(cle) {
  const h = { Accept: "application/geo+json", "User-Agent": "FishMe-proxy/1.0" };
  if (cle) h["X-Api-Key"] = cle;
  return h;
}

/** Le GeoJSON USGS tel quel, plus un bloc `fishme` : attribution, avertissement si une valeur est provisoire, heure de mise en cache. */
export function enrichir(json, maintenantISO) {
  const features = Array.isArray(json && json.features) ? json.features : [];
  const provisoire = features.some((f) => !f.properties || f.properties.approval_status !== "Approved");
  return {
    ...json,
    fishme: {
      attribution: ATTRIBUTION,
      avertissement: provisoire ? AVERTISSEMENT_PROVISOIRE : null,
      mis_en_cache_le: maintenantISO,
      ttl_secondes: TTL_SECONDES,
    },
  };
}

/** Code renvoyé à l'app selon la réponse USGS. 403 (clé refusée) n'est jamais répété tel quel : le détail reste côté serveur. */
export function erreurPourAmont(statut, retryApres) {
  if (statut === 429) return { statut: 429, corps: { erreur: "limite_atteinte" }, retryApres: retryApres || "60" };
  if (statut === 404) return { statut: 404, corps: { erreur: "station_inconnue" } };
  return { statut: 502, corps: { erreur: "source_indisponible" } };
}
