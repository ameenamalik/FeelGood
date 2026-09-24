import { test } from "node:test";
import assert from "node:assert/strict";
import { CATALOG_SESSIONS, matchBestSession } from "../src/catalog_index.ts";
import { aliasSnakeCaseFields } from "../src/payloadKeys.ts";
import { isSessionAvailable, parseAvailability } from "../src/availability.ts";

const homeOnly = parseAvailability({
  availableEquipment: ["none", "mat"],
  availablePlaces: ["home"],
  availableActivities: ["stretching", "walking", "yoga"],
});

const withGym = parseAvailability({
  availableEquipment: ["none", "mat", "weights", "band", "bike", "gym"],
  availablePlaces: ["home", "gym"],
  availableActivities: ["stretching", "strength"],
});

test("no availability sent means nothing is filtered", () => {
  assert.equal(parseAvailability(undefined), null);
  assert.ok(CATALOG_SESSIONS.every((s) => isSessionAvailable(s, null)));
});

test("someone with no gym or weights is never offered gym or weights sessions", () => {
  const offered = CATALOG_SESSIONS.filter((s) => isSessionAvailable(s, homeOnly));
  assert.ok(offered.length > 0);
  for (const s of offered) {
    assert.ok(!s.equipment.includes("gym"), `${s.id} needs a gym`);
    assert.ok(!s.equipment.includes("weights"), `${s.id} needs weights`);
  }
});

test("saying you are at the gym opens gym sessions back up", () => {
  const gymSessions = CATALOG_SESSIONS.filter((s) => s.equipment.includes("gym") || s.equipment.includes("weights"));
  assert.ok(gymSessions.length > 0);
  assert.ok(gymSessions.some((s) => !isSessionAvailable(s, homeOnly)));
  assert.ok(gymSessions.some((s) => isSessionAvailable(s, withGym)));
});

test("matchBestSession never returns an unavailable session when one exists", () => {
  const pick = matchBestSession({ targetDuration: 30, intensity: "dynamic", isAvailable: (s) => isSessionAvailable(s, homeOnly) });
  assert.ok(isSessionAvailable(pick, homeOnly));
});

test("the app's snake_case user_context and todays_menu reach the handler", () => {
  const body: Record<string, unknown> = {
    user_context: { available_equipment: ["none"], available_places: ["home"], available_activities: ["walking"] },
    todays_menu: [],
  };
  aliasSnakeCaseFields(body);
  assert.deepEqual(body.userContext, body.user_context);
  assert.ok(parseAvailability(body.userContext as never));
  assert.ok(Array.isArray(body.todaysMenu));
});
