// worker/scripts/sync_catalog.js
// Reads FeelGood/Content/catalog.json as the single source of truth and writes worker/src/catalog_index.ts

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const catalogPath = path.resolve(__dirname, "../../FeelGood/Content/catalog.json");
const outputPath = path.resolve(__dirname, "../src/catalog_index.ts");

if (!fs.existsSync(catalogPath)) {
  console.error(`Catalog not found at: ${catalogPath}`);
  process.exit(1);
}

const rawData = fs.readFileSync(catalogPath, "utf-8");
const catalog = JSON.parse(rawData);

function mapIntensity(val) {
  if (val <= 1) return "gentle";
  if (val <= 3) return "moderate";
  return "dynamic";
}

const sessions = catalog.sessions.map((s) => ({
  id: s.id,
  title: s.title,
  subtitle: s.subtitle,
  durationMin: s.durationMin,
  intensity: mapIntensity(s.intensity),
  course: s.course,
  activity: s.activity,
  places: s.places || [],
  bodyFocus: s.bodyFocus || [],
  intents: s.intents || [],
  equipment: s.equipment || [],
}));

const header = `// Auto-generated catalog index from FeelGood/Content/catalog.json
// DO NOT EDIT DIRECTLY. Run 'npm run sync:catalog' to regenerate.

export interface CatalogSessionItem {
  id: string;
  title: string;
  subtitle: string;
  durationMin: number;
  intensity: "gentle" | "moderate" | "dynamic";
  course: "appetizer" | "main" | "side" | "dessert" | "special";
  activity: string;
  places: string[];
  bodyFocus: string[];
  intents: string[];
  equipment: string[];
}

export const CATALOG_SESSIONS: CatalogSessionItem[] = ${JSON.stringify(sessions, null, 2)};

export function findSessionById(id?: string): CatalogSessionItem | undefined {
  if (!id) return undefined;
  return CATALOG_SESSIONS.find(s => s.id === id);
}

export function matchBestSession(params: {
  targetDuration?: number;
  intensity?: "gentle" | "moderate" | "dynamic";
  bodyFocus?: string;
  intent?: string;
  place?: string;
  excludeId?: string;
  likedActivities?: string[];
  recoveryOwed?: boolean;
  lastFeel?: "lovedIt" | "fine" | "tooMuch";
  hiddenSessionIds?: string[];
  preferredIntensityTier?: "gentle" | "moderate" | "dynamic";
  topExploredActivities?: string[];
  fatigueSensitivity?: number;
}): CatalogSessionItem {
  let best: CatalogSessionItem = CATALOG_SESSIONS[0]!;
  let bestScore = -999;

  for (const s of CATALOG_SESSIONS) {
    if (params.hiddenSessionIds && params.hiddenSessionIds.includes(s.id)) continue;
    if (params.excludeId && s.id === params.excludeId) continue;
    let score = 0;

    if (params.targetDuration) {
      if (s.durationMin > params.targetDuration) {
        score -= (s.durationMin - params.targetDuration) * 10;
      } else {
        const diff = params.targetDuration - s.durationMin;
        if (diff === 0) score += 25;
        else if (diff <= 3) score += 15;
        else if (diff <= 5) score += 10;
        else score -= diff;
      }
    }

    if (params.intensity && s.intensity === params.intensity) {
      score += 10;
    }

    if (params.bodyFocus && s.bodyFocus.includes(params.bodyFocus)) {
      score += 15;
    }

    if (params.intent && s.intents.includes(params.intent)) {
      score += 10;
    }

    if (params.place && s.places.includes(params.place)) {
      score += 5;
    }

    if (s.course === "main") {
      score += 3;
    }

    // Feedback & Affinity influence
    if (params.likedActivities && params.likedActivities.includes(s.activity)) {
      score += 12;
    }

    // Contextual Bandit Learned Preference alignment
    if (params.preferredIntensityTier && s.intensity === params.preferredIntensityTier) {
      score += 8;
    }

    if (params.topExploredActivities && params.topExploredActivities.includes(s.activity)) {
      score += 10;
    }

    if (params.fatigueSensitivity && params.fatigueSensitivity > 0.6) {
      if (s.intensity === "gentle") {
        score += 8;
      } else if (s.intensity === "dynamic") {
        score -= 10;
      }
    }

    if (params.recoveryOwed || params.lastFeel === "tooMuch") {
      if (s.intensity === "gentle") {
        score += 15;
      } else if (s.intensity === "dynamic") {
        score -= 20;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      best = s;
    }
  }

  return best;
}
`;

fs.writeFileSync(outputPath, header, "utf-8");
console.log(`Successfully synced ${sessions.length} sessions from catalog.json -> worker/src/catalog_index.ts`);
