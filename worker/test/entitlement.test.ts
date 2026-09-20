import { afterEach, beforeEach, describe, it, mock } from "node:test";
import assert from "node:assert/strict";
import { hasProEntitlement } from "../src/entitlement.ts";

const realFetch = globalThis.fetch;
const prod = { ENVIRONMENT: "production", REVENUECAT_SECRET_API_KEY: "sk_test" } as never;

function stubFetch(impl: () => Promise<Response>) {
  globalThis.fetch = mock.fn(impl) as unknown as typeof fetch;
}
function rcResponse(entitlements: Record<string, { expires_date: string | null }>) {
  return () => Promise.resolve(Response.json({ subscriber: { entitlements } }));
}
const future = () => new Date(Date.now() + 86_400_000).toISOString();
const past = () => new Date(Date.now() - 86_400_000).toISOString();

describe("hasProEntitlement", () => {
  beforeEach(() => mock.method(console, "warn", () => {}));
  beforeEach(() => mock.method(console, "error", () => {}));
  afterEach(() => {
    globalThis.fetch = realFetch;
    mock.restoreAll();
  });

  it("allows everything in development without calling RevenueCat", async () => {
    stubFetch(() => Promise.reject(new Error("must not be called")));
    assert.equal(await hasProEntitlement("u", { ENVIRONMENT: "development" } as never), true);
  });

  it("grants an active pro entitlement", async () => {
    stubFetch(rcResponse({ pro: { expires_date: future() } }));
    assert.equal(await hasProEntitlement("u", prod), true);
  });

  it("grants a non-expiring pro entitlement", async () => {
    stubFetch(rcResponse({ pro: { expires_date: null } }));
    assert.equal(await hasProEntitlement("u", prod), true);
  });

  it("refuses an expired pro entitlement", async () => {
    stubFetch(rcResponse({ pro: { expires_date: past() } }));
    assert.equal(await hasProEntitlement("u", prod), false);
  });

  it("refuses a subscriber with no pro entitlement", async () => {
    stubFetch(rcResponse({}));
    assert.equal(await hasProEntitlement("u", prod), false);
  });

  it("fails closed when the RevenueCat secret is missing", async () => {
    stubFetch(() => Promise.reject(new Error("must not be called")));
    assert.equal(await hasProEntitlement("u", { ENVIRONMENT: "production" } as never), false);
  });

  it("fails closed on 401 (revoked or wrong key)", async () => {
    stubFetch(() => Promise.resolve(new Response("nope", { status: 401 })));
    assert.equal(await hasProEntitlement("u", prod), false);
  });

  it("fails closed on a RevenueCat 5xx", async () => {
    stubFetch(() => Promise.resolve(new Response("boom", { status: 503 })));
    assert.equal(await hasProEntitlement("u", prod), false);
  });

  it("fails closed when the network throws", async () => {
    stubFetch(() => Promise.reject(new Error("offline")));
    assert.equal(await hasProEntitlement("u", prod), false);
  });

  it("fails closed on a malformed body", async () => {
    stubFetch(() => Promise.resolve(new Response("not json", { status: 200 })));
    assert.equal(await hasProEntitlement("u", prod), false);
  });
});
