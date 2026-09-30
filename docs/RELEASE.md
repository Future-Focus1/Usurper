# Usurper Windows release

Version 1.0.0 uses Godot 4.6.3 stable, the GL Compatibility renderer, and an embedded content pack. The output is a Windows x86-64 executable. Debug cheats are disabled. No music or sound effects have been added.

## Rebuild

1. Obtain the official `Godot_v4.6.3-stable_export_templates.tpz` from the [Godot 4.6.3 release](https://github.com/godotengine/godot/releases/tag/4.6.3-stable).
2. Verify the archive against that release's `SHA512-SUMS.txt` before extraction. The template archive used for this release was checked successfully.
3. Extract `windows_release_x86_64.exe` into `build/template-cache/`. The optional debug template belongs beside it.
4. Run `./tools/build_windows.ps1`. Override `-Godot` if the editor is installed elsewhere.

The export preset excludes tests, tools, documentation, build intermediates, and the separate GitHub checkout. It explicitly includes JSON content. Engine and font notices are copied beside the executable, and `SHA256.txt` identifies the output. Export templates and generated binaries are ignored by Git; the source and all game art are tracked.

## Distribution

The playable package is `build/Usurper-Windows-1.0.0.zip`. Extract it before launching `Usurper.exe`. It contains the executable, a short player guide, and dependency notices. There is no installer, online login, live AI service, or network requirement for gameplay. Player saves live under `%APPDATA%\Godot\app_userdata\Usurper`, outside the installation directory.

The build has been tested with the supplied Godot installation and on this Windows machine. Automated campaign, branch, save, battle, frontend, and layout evidence is described in [QA.md](QA.md). No claim is made that every possible ordering of decisions has been enumerated.

## Steam handoff

The Windows build and source are prepared for submission; uploading a depot, creating the store page, pricing, and Valve review take place in the owner's Steamworks account. This work has not submitted or published the game to Steam.

Suggested short description:

> The king is dead. Four claimants remain. Build your right to rule through alliances, evidence, mercy and steel in a political strategy chronicle where every promise leaves a mark, and the crown is only the beginning of your legacy.

Suggested store description:

> Enter Nezrel at the moment its throne falls empty. Govern from Queen Mira's embattled court, return from exile as Ethan Valen, uncover Arlo's disputed bloodline, or march south with Alistair Storm. Each claimant begins with different strengths, relationships and dangers.
>
> Hear petitions, investigate hidden evidence, bargain with the great houses, and choose one decree each week. Feed your army before expanding it. Protect a witness before asking them to speak. Win an estate through negotiation or risk your soldiers in a three-lane battle.
>
> A hundred points of claim will let you attempt the throne. They will not make the kingdom accept you. Seek a crown through military force, public support, sacred authority, inheritance, marriage or a settlement your rivals can survive. Your epilogue remembers the government you built, the promises you kept, and the people you left behind.
>
> Explore an illustrated world atlas and a court of characters with personal histories. Complete different campaigns to uncover the Chronicle of Nezrel, while each new claimant must discover the truth for themselves.

Content includes political violence, bereavement, disputed sexual-assault allegations, coercion, and end-of-life mercy. Depictions are textual rather than graphic. The present build is silent while the owner prepares the final audio.

The shipped portraits and environment paintings use pre-generated AI artwork. The expanded game text and implementation were produced with AI-assisted development and reviewed against the supplied lore. Describe that work accurately in the Steamworks Content Survey. There is no live AI generation at runtime. See the official [Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey) guidance and [store graphical asset requirements](https://partner.steamgames.com/doc/store/assets/standard) when completing the submission. The generated game paintings are not substitutes for Valve's required capsule layouts.
