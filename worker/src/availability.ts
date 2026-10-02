// What the person can actually do today, as the app derived it from their
// profile (plus anything they said in this conversation, e.g. "I'm at the
// gym"). Equipment, places and activities carry no health data, so they are
// allowed on the wire; work-arounds still never are.
//
// Mirrors the on-device plan engine's hard filters so Chat and Today agree.

import type { CatalogSessionItem } from "./catalog_index";

export interface Availability {
  equipment: Set<string>;
  places: Set<string>;
  activities: Set<string>;
}

// Activities the engine treats as needing nothing: see Activity.isAlwaysAvailable.
const ALWAYS_AVAILABLE_ACTIVITIES = new Set(["qigong", "breathwork", "carries", "agility", "other"]);

// Mirrors ContentTypes.swift: Place.impliedEquipment and Equipment.impliedEquipment.
const PLACE_IMPLIES: Record<string, string[]> = {
  gym: ["gym", "mat", "weights", "band", "bike"],
  studio: ["mat", "reformer"],
  pool: ["pool"],
  outdoors: ["outdoor"],
};
const EQUIPMENT_IMPLIES: Record<string, string[]> = {
  gym: ["mat", "weights", "band", "bike"],
};

interface PromptRule {
  pattern: RegExp;
  activities?: string[];
  equipment?: string[];
  places?: string[];
}

// What someone asks for in Chat widens their profile for that conversation.
// Every activity in the catalog should be reachable by asking for it plainly;
// test/availability.test.ts checks that.
const PROMPT_RULES: PromptRule[] = [
  { pattern: /\bpilates\b/, activities: ["pilates"], equipment: ["mat"] },
  { pattern: /\breformer\b/, activities: ["pilates"], equipment: ["reformer"], places: ["studio"] },
  { pattern: /\byoga\b/, activities: ["yoga"], equipment: ["mat"] },
  { pattern: /\b(dance|dancing)\b/, activities: ["dance"] },
  { pattern: /\b(stretch|stretches|stretching|flexibility|mobility|foam roll(ing|er)?)\b/, activities: ["stretching"], equipment: ["mat"] },
  { pattern: /\b(breathe|breathing|breathwork|breath|relax|relaxing|wind down)\b/, activities: ["breathwork"], equipment: ["mat"] },
  { pattern: /\b(mat|floor)\b/, equipment: ["mat"] },
  { pattern: /\b(strength|lifting|lift|weights?|dumbbells?)\b/, activities: ["strength"], equipment: ["weights"] },
  { pattern: /\b(resistance bands?|loop bands?|bands?)\b/, activities: ["strength"], equipment: ["band"] },
  { pattern: /\b(gym|kettlebells?|barbells?|cables?|machines?|smith|landmine|pull-?up bar|rack|rowing machine|rower|elliptical|stair ?master|treadmill)\b/, activities: ["strength"], places: ["gym"] },
  { pattern: /\b(walk|walks|walking|stroll|hike|hiking)\b/, activities: ["walking"], places: ["outdoors"] },
  { pattern: /\b(run|running|jog|jogging)\b/, activities: ["running"], places: ["outdoors"] },
  { pattern: /\b(bike|biking|cycle|cycling|ride)\b/, activities: ["biking"], equipment: ["bike"], places: ["outdoors"] },
  { pattern: /\b(swim|swimming|pool)\b/, activities: ["swimming"], places: ["pool"] },
  { pattern: /\b(skate|skates|skating|rollerblad(e|ing))\b/, activities: ["skating"], equipment: ["skates"], places: ["outdoors"] },
  { pattern: /\b(jump rope|jumprope|skipping)\b/, activities: ["jumpRope"], equipment: ["rope"] },
  { pattern: /\b(tennis|pickleball|padel|badminton|squash|racquet|racket)\b/, activities: ["racquet"], places: ["outdoors"] },
  { pattern: /\b(climb|climbing|boulder|bouldering)\b/, activities: ["climbing"], places: ["gym", "outdoors"] },
  { pattern: /\b(outside|outdoors?|park|trail|nature)\b/, places: ["outdoors"] },
  { pattern: /\b(studio|class|sauna|spa)\b/, activities: ["dance", "stretching"], places: ["studio"] },
];

export interface AvailabilityFields {
  availableEquipment?: string[];
  available_equipment?: string[];
  availablePlaces?: string[];
  available_places?: string[];
  availableActivities?: string[];
  available_activities?: string[];
}

/**
 * Returns null when the client sent no availability at all (older app builds),
 * in which case nothing is filtered rather than everything.
 * An optional prompt widens activities and equipment based on user conversation.
 */
export function parseAvailability(ctx?: AvailabilityFields, prompt?: string): Availability | null {
  if (!ctx && !prompt) return null;
  const equipment = ctx?.availableEquipment ?? ctx?.available_equipment;
  const places = ctx?.availablePlaces ?? ctx?.available_places;
  const activities = ctx?.availableActivities ?? ctx?.available_activities;
  if (!equipment && !places && !activities && !prompt) return null;

  const parsedEquipment = new Set([...(equipment ?? []), "none"]);
  const parsedPlaces = new Set([...(places ?? []), "home"]);
  const parsedActivities = new Set(activities ?? []);

  if (prompt) {
    const text = prompt.toLowerCase();
    const hasNegation = /n't|\bno\b|\bnot\b|\bnever\b|\bwithout\b/.test(text);
    if (!hasNegation) {
      for (const rule of PROMPT_RULES) {
        if (!rule.pattern.test(text)) continue;
        rule.activities?.forEach((x) => parsedActivities.add(x));
        rule.equipment?.forEach((x) => parsedEquipment.add(x));
        rule.places?.forEach((x) => parsedPlaces.add(x));
      }
    }
  }

  // Somewhere to be implies what's in it, as in the app's
  // Place.impliedEquipment / Equipment.impliedEquipment — otherwise "I'm
  // outdoors" or "at the gym" still filters out the sessions that need them.
  for (const place of [...parsedPlaces]) {
    PLACE_IMPLIES[place]?.forEach((x) => parsedEquipment.add(x));
  }
  for (const item of [...parsedEquipment]) {
    EQUIPMENT_IMPLIES[item]?.forEach((x) => parsedEquipment.add(x));
  }
  if (parsedEquipment.has("gym") || parsedEquipment.has("weights")) parsedActivities.add("strength");

  return {
    equipment: parsedEquipment,
    places: parsedPlaces,
    activities: parsedActivities,
  };
}

export function isSessionAvailable(s: CatalogSessionItem, a: Availability | null): boolean {
  if (!a) return true;
  if (s.equipment.some((e) => e !== "none" && !a.equipment.has(e))) return false;
  if (s.places.length > 0 && !s.places.some((p) => a.places.has(p))) return false;

  const isFloorSession = s.equipment.every((e) => e === "none" || e === "mat")
    && (s.places.length === 0 || s.places.includes("home"))
    && (s.activity === "pilates" || s.activity === "yoga" || s.activity === "dance");

  if (!ALWAYS_AVAILABLE_ACTIVITIES.has(s.activity) && !a.activities.has(s.activity) && !isFloorSession) return false;
  return true;
}
