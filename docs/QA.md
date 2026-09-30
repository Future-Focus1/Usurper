# Usurper verification

The game is tested with the user's Godot 4.6.3 Windows executable. The test
launcher redirects `APPDATA` only for its child process and asserts the resulting
Godot `user://` directory is under `tests/.artifacts/userdata`. Test autosaves,
manual slots, settings, and Chronicle discoveries cannot overwrite player saves.

From the project root:

```powershell
./tests/run_qa.ps1 -Suite all -Seeds 24
./tests/run_qa.ps1 -Suite capture -Resolution 1280x720 -SkipImport
./tests/run_qa.ps1 -Suite capture -Resolution 1920x1080 -SkipImport
./tests/run_qa.ps1 -Suite frontend -SkipImport
./tests/run_qa.ps1 -Suite layout -Resolution 1600x900 -SkipImport
```

Add `-RecordEvidence` to retain the successful machine reports and a compact
visual-capture summary under `docs/qa-results/` for the repository. The evidence
snapshot excludes logs, saves, settings, and machine-specific screenshot paths.

Use `-Godot 'absolute\path\to\Godot.exe'` for another installation. The launcher
uses the adjacent console executable when present, waits for process completion,
and rejects nonzero exits or script/resource/runtime errors in engine logs.

## Automated coverage

`release_audit.gd` validates catalogue IDs, supported conditions and effects,
all authored choice condition witnesses, nested random branches, battle-return
branches, generated actions and ledger plays, character starts, and route prose.
Every scheduled-only scene must have an authored or generated action producer. Nested `all` / `any`
conditions and independent-evidence counts are supported by the witness builder.

The producer audit executes source choice/action effects and delivers all 44
scheduled-only scenes through the real schedule ticker and EventDirector,
without injecting the consequence's required flags. It also exercises each
rival's march and coronation-bid producer, then checks that death or captivity
prevents its current scene. Evelyne's promise reaches the optional family hearing,
an actual failed assassination delivers its response two weeks later, and an
empty audience reaches the quiet-week fallback. Producer witnesses are fixtures;
they supplement, rather than replace, the connected campaign runs.

It verifies inclusive resource-condition boundaries, affordable-choice checks,
terminal effects, dead-character continuity, queued/scheduled speaker deaths,
starvation recovery, and the campaign's finite council settlement. It exercises
every battle definition for every claimant, all tactical commands, deterministic
battle resolution, bounded losses, and protection against applying the same
returned battle twice.

Save tests compare every campaign field after writing and loading an actual save,
including pending events and battles. Eight subsequent random draws must match
the original generator exactly. Damaged save data must recover from an intact
backup, while a structurally invalid payload is rejected.
Rapid writes across slots 1, 3, 2, and 0 must select each latest write even within
the same displayed second. Precise timestamps retain their 64-bit integer value
as JSON strings; older saves retain ordering through their legacy datetime field.

The full campaign sweep runs **576 campaigns**: four claimants, six decision
policies, and 24 fixed seeds. Policies cover random, legitimacy, benevolent,
ruthless, diplomacy, and military play. They select only legal choices/actions,
resolve battles through the actual battle engine, and attempt available throne
routes. Resource and living-commander invariants are checked after decisions,
battles, decrees, and weekly resolution. Every run must conclude. Route witnesses
also assemble every supported ending band for each eligible claimant, separately
from the routes attained through connected play.

`interaction_audit.gd` mounts the actual campaign scene for all four claimants.
It makes an opening choice, saves while the consequence receipt is displayed,
reloads the save, and verifies the choice has already been committed. Clicking
Continue must not advance twice. World, Map, Court, Ledger, and Army close
controls must dismiss their overlays.

`frontend_campaign_audit.gd` carries one entire naturally successful seeded
campaign per claimant through the live playable scene transitions. It presses
actual petition, receipt, category, decree, next-week, throne-route, tactical lane
order, command, fight, and battle-return button signals. Each run saves and
reloads during petitions and again during the decree phase. It checks the actual
ending screen reports victory, and separately verifies the final council
settlement reaches its ending from the response button.

The retained week-loop and overlay regressions check that forecasts do not change
resources, rivals earn claim through matching actions, calm realms do not gain
arbitrary foreign pressure, and locked actions explain their requirements.

## Layout and visual review

`layout_audit.gd` checks the principal screens, every authored event, and all 250
eligible claimant/route/band ending screens in contextual campaign states. It
finds controls outside the viewport and button
labels narrower than their text. Content intentionally inside a ScrollContainer
is permitted to extend into its scrolling area.

`visual_capture.gd` uses the real Windows OpenGL renderer, including the finished
art assets and fonts. Captures cover the title menu, settings, claimant selection,
all four campaign openings, petitions, decision receipts, decrees, weekly
responses, map, court biography, army, ledger, world atlas, throne routes, tactical
battle, Chronicle, public and discovered character histories, and the top and
bottom of personal and council epilogues. Each capture has
control/text bounds recorded in `manifest.json` for inspection.

The default project scales its 1280×720 canvas to the window. A layout command with
another resolution deliberately tests that logical canvas size; it is a stronger
layout stress test than merely shrinking a window and scaling the same canvas.

## Final validation snapshot — 30 September 2026

The frozen content passed the full suite with **802,772 assertions**, **178 events**,
**521 choices**, **1,200 independently executed effect branches**, and **576 complete
campaigns**. The sweep naturally encountered 170 events and 477 choices. All 521
choices also received constructive condition witnesses and effect-branch checks.
The unvisited scenes are retained in the machine report rather than counted as
natural play coverage. No run remained unresolved beyond the campaign deadline;
18 concluded through the council settlement.

| Claimant | Victories / 144 runs | Natural routes reached | Route/band prose tested | Distinct paragraphs |
| --- | ---: | ---: | ---: | ---: |
| Mira | 119 | 7 | 65 | 60 |
| Ethan | 103 | 5 | 60 | 60 |
| Arlo | 110 | 7 | 65 | 65 |
| Alistair | 129 | 7 | 60 | 55 |

There are 250 eligible route/band prose combinations and 240 distinct paragraphs
within those claimant catalogues. A small number of intentional route aliases
share paragraphs. Defeat bands and conditional world, relationship, and legacy
aftermaths add further outcome variation.

Decision quality materially changed these seeded outcomes. The legitimacy policy
won 24/24 Mira, 18/24 Ethan, 20/24 Arlo, and 24/24 Alistair campaigns; random choices
won 1/24, 2/24, 0/24, and 9/24 respectively. This measures these specific policy
heuristics and seeds, rather than predicting a new player's success rate.

Four additional connected frontend campaigns won through **738 button signals**
and **five tactical battles**. They concluded at weeks 13, 13, 19, and 16. Save and
reload during petitions, decrees, and choice receipts preserved progress; loading
completed campaigns restored their ending without recording another Chronicle
entry. The final council response reached its ending through the actual response
button. All 178 event layouts, 250 ending layouts, and the principal screens
passed the bounds audit at both 1280×720 and 1920×1080: 441 scans per resolution.
Real renderer captures retained 52 screens at
1280×720 and the same 52 at
1920×1080 for visual review.

The exported Windows executable also completed a separate 60-frame runtime smoke
test with isolated save storage and no engine errors. The actual graphics device
was an NVIDIA GeForce RTX 3090, using OpenGL 3.3 Compatibility (driver 591.86).
This verifies this machine; it does not establish minimum hardware requirements.
The package's six files and the embedded executable hash were checked during the
release build.

## Evidence and limits

The latest machine-readable results are written to
`tests/.artifacts/release_audit.json`. They include the exact engine, catalogue
counts, assertions, branch count, campaign outcomes by claimant and policy,
naturally reached routes, unvisited campaign scenes, and failures. Natural
successful playthrough traces are saved in `winning_replays.json`. Screenshots
and engine logs remain under the ignored `tests/.artifacts` folder.

This is branch execution and deterministic campaign exploration. It does not
enumerate the exponentially growing set of all decision sequences. Constructed
route witnesses prove that their conditions can hold together, while natural
campaign runs demonstrate connected paths from the authored starts. Semantic
lore consistency and image composition also require human visual/editorial
review; automated text and bounds checks do not replace it.
