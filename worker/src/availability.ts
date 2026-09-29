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
      if (/\bpilates\b/.test(text)) {
        parsedActivities.add("pilates");
        parsedEquipment.add("mat");
      }
      if (/\byoga\b/.test(text)) {
        parsedActivities.add("yoga");
        parsedEquipment.add("mat");
      }
      if (/\b(dance|dancing)\b/.test(text)) {
        parsedActivities.add("dance");
      }
      if (/\b(stretch|stretching|flexibility|mobility)\b/.test(text)) {
        parsedActivities.add("stretching");
      }
      if (/\b(strength|lifting|lift|weights?|dumbbells?)\b/.test(text)) {
        parsedActivities.add("strength");
        parsedEquipment.add("weights");
      }
      if (/\b(run|running|jog|jogging)\b/.test(text)) {
        parsedActivities.add("running");
        parsedEquipment.add("outdoor");
        parsedPlaces.add("outdoors");
      }
      if (/\b(bike|biking|cycle|cycling)\b/.test(text)) {
        parsedActivities.add("biking");
        parsedEquipment.add("bike");
        parsedPlaces.add("outdoors");
      }
      if (/\b(swim|swimming|pool)\b/.test(text)) {
        parsedActivities.add("swimming");
        parsedEquipment.add("pool");
        parsedPlaces.add("pool");
      }
      if (/\b(skate|skating)\b/.test(text)) {
        parsedActivities.add("skating");
        parsedEquipment.add("skates");
      }
      if (/\b(jump rope|jumprope|skipping)\b/.test(text)) {
        parsedActivities.add("jumpRope");
        parsedEquipment.add("rope");
      }
    }
  }

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
