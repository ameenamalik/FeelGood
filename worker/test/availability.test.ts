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

test("asking for pilates opens pilates sessions even if not in profile", () => {
  const pilatesSessions = CATALOG_SESSIONS.filter((s) => s.activity === "pilates" && s.equipment.every((e) => e === "none" || e === "mat"));
  assert.ok(pilatesSessions.length > 0);
  const withPilatesPrompt = parseAvailability({
    availableEquipment: ["none", "mat"],
    availablePlaces: ["home"],
    availableActivities: ["walking"],
  }, "Can I do a 15-minute pilates session?");
  assert.ok(pilatesSessions.some((s) => isSessionAvailable(s, withPilatesPrompt)));
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

const homeWalker = { availableEquipment: ["none", "mat"], availablePlaces: ["home"], availableActivities: ["walking"] };

test("asking about bands opens band sessions even if bands aren't in the profile", () => {
  const bandSessions = CATALOG_SESSIONS.filter((s) => s.equipment.includes("band"));
  assert.ok(bandSessions.length > 0);
  assert.ok(bandSessions.every((s) => !isSessionAvailable(s, parseAvailability(homeWalker))));
  const asked = parseAvailability(homeWalker, "do u have any exercises with bands");
  assert.ok(bandSessions.every((s) => isSessionAvailable(s, asked)));
});

test("asking for a kettlebell or the gym opens gym sessions even if not in the profile", () => {
  const gymSessions = CATALOG_SESSIONS.filter((s) => s.activity === "strength" && s.equipment.includes("gym"));
  assert.ok(gymSessions.length > 0);
  for (const prompt of ["I'm at the gym today", "anything with a kettlebell?"]) {
    const asked = parseAvailability(homeWalker, prompt);
    assert.ok(gymSessions.some((s) => isSessionAvailable(s, asked)), prompt);
  }
});

test("saying you have no band doesn't add band sessions", () => {
  const asked = parseAvailability(homeWalker, "I don't have a band");
  assert.ok(!asked!.equipment.has("band"));
});

test("every session in the catalog can be reached by plainly asking for it", () => {
  const bare = { availableEquipment: ["none"], availablePlaces: ["home"], availableActivities: [] as string[] };
  const ask: Record<string, string> = {
    strength: "a strength workout", stretching: "some stretching", breathwork: "breathing", pilates: "pilates",
    walking: "a walk", agility: "agility", dance: "dance", running: "a run", yoga: "yoga", carries: "carries",
    qigong: "qi gong", biking: "a bike ride", swimming: "a swim", jumpRope: "jump rope", skating: "skating",
    racquet: "tennis", climbing: "climbing", other: "something",
  };
  const extras = ["", " at the gym", " outside", " with a band", " at a studio class", " on a reformer"];
  const unreachable = CATALOG_SESSIONS.filter((s) => {
    const what = ask[s.activity];
    assert.ok(what, `no plain ask for activity "${s.activity}" — add a prompt rule and an entry here`);
    return !extras.some((extra) => isSessionAvailable(s, parseAvailability(bare, `can I do ${what}${extra}`)));
  });
  assert.deepEqual(unreachable.map((s) => s.id), []);
});
