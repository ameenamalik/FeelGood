// Display labels for catalog `bodyFocus` values. Mirrors `BodyFocus.label` in
// FeelGood/Features/Display.swift — the iOS enum is the source of truth, so a
// new case there needs a row here (the test below fails on an unmapped value).
const BODY_FOCUS_LABELS: Record<string, string> = {
  full: "Full Body",
  core: "Core",
  lowerBody: "Lower Body",
  upperBody: "Upper Body",
  back: "Spine & Back",
  hips: "Hips",
  neckShoulders: "Neck & Shoulders",
};

export function bodyFocusLabel(focus: string): string {
  return BODY_FOCUS_LABELS[focus] ?? focus;
}
