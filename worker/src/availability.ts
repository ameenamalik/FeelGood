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
const ALWAYS_AVAILABLE_ACTIVITIES = new Set(["qigong", "breathwork", "carries", "agility"]);

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
 */
export function parseAvailability(ctx?: AvailabilityFields): Availability | null {
  if (!ctx) return null;
  const equipment = ctx.availableEquipment ?? ctx.available_equipment;
  const places = ctx.availablePlaces ?? ctx.available_places;
  const activities = ctx.availableActivities ?? ctx.available_activities;
  if (!equipment && !places && !activities) return null;
  return {
    equipment: new Set([...(equipment ?? []), "none"]),
    places: new Set([...(places ?? []), "home"]),
    activities: new Set(activities ?? []),
  };
}

export function isSessionAvailable(s: CatalogSessionItem, a: Availability | null): boolean {
  if (!a) return true;
  if (s.equipment.some((e) => e !== "none" && !a.equipment.has(e))) return false;
  if (!ALWAYS_AVAILABLE_ACTIVITIES.has(s.activity) && !a.activities.has(s.activity)) return false;
  if (s.places.length > 0 && !s.places.some((p) => a.places.has(p))) return false;
  return true;
}
