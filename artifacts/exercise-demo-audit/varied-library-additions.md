# Varied library sessions — 2026-09-28

17 additional sessions use all 35 previously unused demos with glossary entries. The Library now contains 150 built-in sessions. Demo utilization is 145 of 312 sets; the 167 remaining sets need glossary entries and pose review.

| Session | Minutes | Setup |
|---|---:|---|
| Twenty minutes of pushing | 20 | A bench, cables, and an assisted-dip machine |
| Pull, row, and reset | 15 | A barbell, dumbbell bench, fixed bar, and pull-up station |
| Ten minutes at the pull-up bar | 10 | For familiar pull-ups, with generous recovery |
| A steady lower-body barbell session | 20 | Light loads, rack safeties, a bench, and time to reset |
| Eight minutes for your legs | 8 | A loop band, low bench, and clear walking space |
| Four ways to work your core | 10 | A secure hanging bar, light dumbbell, and floor space |
| Five minutes for your back | 5 | A back-extension bench and a comfortable floor space |
| An eight-minute energy break | 8 | Short bursts with time to catch your breath |
| Swings, jumps, and room to recover | 10 | A familiar kettlebell swing and small, controlled jumps |
| Eight minutes on the rowing machine | 8 | Legs, then body, then arms; an unhurried rhythm |
| An easy elliptical break | 10 | A smooth pace with light resistance |
| Twelve minutes on the stairs | 12 | Slow steps, with the rails within reach |
| A steady fifteen-minute bike ride | 15 | On a stationary bike at home or the gym |
| Twenty easy minutes in the pool | 20 | A familiar stroke, with breaks at the wall |
| Ten minutes of gentle incline | 10 | A small incline and a comfortable speed |
| A fifteen-minute walking reset | 15 | Around the block, indoors, or along a familiar route |
| An easy jog with walking breaks | 20 | Four short jogs with a walk between each |

## Validation

- Actual Swift catalog decoder and ContentStore.validate pass for the complete catalog.
- All 31 additions across both batches have exact step-duration totals, valid side-switch timing and three bundled demo frames per movement.
- Worker TypeScript typecheck and git diff whitespace checks pass.
- Full simulator tests remain blocked by pre-existing actor-isolation errors in UI tests; worker test runner needs a Node version with TypeScript support (local Node 21 does not provide it).

## Asset corrections

- Back-extension instructions now describe the bench shown in the demo.
- Blank side-bend frame 1 replaced with existing upright frame 3; original preserved in original-frames/. Attribution notes the sequence repair.
