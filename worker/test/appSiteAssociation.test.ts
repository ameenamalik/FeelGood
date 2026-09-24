import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ID, appSiteAssociationResponse } from "../src/appSiteAssociation.ts";

describe("appSiteAssociationResponse", () => {
  it("names the app for Password AutoFill, as JSON", async () => {
    const response = appSiteAssociationResponse();
    assert.equal(response.status, 200);
    assert.equal(response.headers.get("Content-Type"), "application/json");
    assert.deepEqual(await response.json(), { webcredentials: { apps: [APP_ID] } });
  });

  it("uses the team and bundle ID the app is signed with", () => {
    assert.equal(APP_ID, "322ZGVD4Z7.com.ameenamalik.FeelGood");
  });
});
