# Usurper — The Crown Is Empty

Four lives. One crown. A kingdom that will remember.

King Erol II is dead. Queen Mira has the castle but no recognised right to rule. Ethan returns from exile with a prince's blood and a disputed reputation. Arlo is a stable hand whose birth may change the succession. Alistair Storm commands the largest army, and must decide what strength is for.

Usurper is a single-player political strategy game for Windows, made with Godot 4.6.3. Four distinct campaigns combine court petitions, an evolving realm, three-lane battles, evidence, alliances, and a final settlement. The illustrated court, world atlas, character biographies, and Chronicle of Nezrel accompany the campaign from its first audience to its epilogue.

## Play the Windows build

Run `build/windows/Usurper.exe`, or extract the release archive and run `Usurper.exe`. The exported game includes its engine and content; the Godot editor is only needed for development. Use the mouse to choose petitions, decrees, battle orders, and reference screens. Press **Esc** to pause during a campaign. Fullscreen is available under Settings.

Each week has four steps:

1. **Briefing:** review resources, support, rival movements, and the next week's income and upkeep.
2. **Petitions:** make decisions and read their immediate consequences. Costs, unmet conditions, and risks are shown before choosing.
3. **Decree:** issue one strategic order. Supplies, negotiations, military campaigns, investigations, and governance compete for the same week.
4. **The realm's response:** collect income, pay the army, and discover what the other claimants did.

The World, Map, Court, Ledger, and Army screens can be consulted without spending a decree. Support and territory matter beyond the claim score: recognising a house can bring its estates into your economy, peaceful borders can reduce outside pressure, and promises or betrayals survive into later petitions and endings. Protecting witnesses preserves the evidence they can supply.

**Claim 100 opens a throne attempt.** It does not guarantee a crown. Each method needs its own coalition, proof, pact, or military position. Common methods remain visible as goals; unusual settlements appear when your current character discovers them. Death, capture, ruin, a failed attempt, and a finite council settlement can also close a campaign. The epilogue reflects the route, the claimant, the condition of the realm, and the people who survived your decisions.

Battles resolve over three lanes. Inspect unit strengths, assign orders, commit reserves, and decide when preserving the army is worth retreating. Named commanders can be wounded, captured, or killed. These outcomes carry back into the court.

## Saves and Chronicle

Player files are stored separately from the project in `%APPDATA%\Godot\app_userdata\Usurper\`.

- Autosave uses slot 0 at weekly resolution, before and after battles, when completing a campaign, and when returning to the menu.
- Three manual slots are available from the campaign pause screen. A save during a decision receipt already contains that decision.
- Saves retain event queues, pending battles, random-generator state, relationships, promises, evidence, and completed endings. Writes use a temporary file and retain a backup.
- The Chronicle remembers discovered lore and completed campaigns across playthroughs. A new claimant must still learn information inside their own campaign.

The release is silent. Music and sound effects are reserved for later integration of the owner's supplied audio.

## Develop and verify

Open `project.godot` with Godot 4.6.3 and press F5. Release debug tools are disabled in `scripts/balance.gd`.

```powershell
./tests/run_qa.ps1 -Suite all -Seeds 24
./tests/run_qa.ps1 -Suite capture -Resolution 1280x720 -SkipImport
./tools/build_windows.ps1
```

Both scripts accept `-Godot` with an absolute executable path. The build uses the official 4.6.3 Windows export template in `build/template-cache`; see [the release guide](docs/RELEASE.md). Tests isolate their user data from player saves. The [verification report](docs/QA.md) describes coverage, reproduction steps, and the limits of automated exploration.

Story and gameplay content live in `data/`. Systems are separated from the interface under `scripts/systems/`; reusable UI and portrait rendering live under `scripts/ui/`. The [art direction record](docs/ART_DIRECTION.md) describes the generated assets, their provenance, and atlas positions.

## Dependencies

Godot is distributed under the MIT license, with its third-party notices in `docs/licenses/`. Cinzel and Source Sans 3 use the SIL Open Font License in `assets/fonts/OFL.txt`. The Windows package includes these notices.
