# Usurper

A turn-based political strategy game set in the kingdom of Nezrel, after the death of King Erol II. You play one of four claimants and spend each week on petitions, one strategic move, and the consequences. Claim is the path to the throne. Reaching 100 does not crown you. It only unlocks the attempt, and the attempt can still fail.

The four claimants are Queen Mira Valen, Ethan Valen, Arlo, and Lord Alistair Storm. Each starts in a different place, with different resources, and with a different argument for why the crown should be theirs. The other three keep acting while you play.

## Play

You need Godot 4.6.3. Open the folder that contains `project.godot`, then press F5.

If you keep the project at `C:\Projects\Usurper`, put this folder there and open `project.godot` from that path. The Godot editor for this build is the 4.6.3 stable editor.

From the main menu:

- New Game asks you to choose a claimant.
- Continue loads the latest save.
- Chronicle of Nezrel keeps discoveries across campaigns. Your character does not remember them. Later campaigns can stumble into events those discoveries make possible.
- Settings covers fullscreen and volume.

Each week is four steps, in this order. The briefing tells you what your lands should pay and what the army will eat. The petitions are the week's scenes; you answer each one. The decree is the single order you are allowed to give. The realm's answer is income, hunger, pay, and what the other claimants actually did. The next briefing does not repeat that answer. The map, court, ledger, and army are references on that screen, not extra turns. Esc pauses and can save into a manual slot. F12 opens the developer panel while debug tools are enabled.

Battles are a short three-lane fight. Retreat is allowed and costs less than fighting until the army breaks. Named people can be wounded, captured, or killed, and a death stays dead.

When Claim reaches 100, Take the Throne lists only the routes your campaign has actually opened. Conquest, acclamation, the Flame, a popular rising, blood, Erol's will, marriage, abdication, a regency, and a handful of rarer settlements all read the whole campaign, not a single number.

## Saves

Campaign saves and the Chronicle are written by Godot into the user data folder, not into this repository.

- Autosave is slot 0, written at the end of each week and when you return to the menu.
- Manual slots are 1, 2, and 3, from the pause menu.
- The Chronicle is a separate file, so starting another claimant does not wipe what you have already uncovered.

## What you are looking at

Portraits, maps, and units are coloured placeholders with labels. Gameplay does not depend on the final art. Replacing a portrait or background later should be a texture swap, not a rewrite.

Story, claimants, houses, territories, battles, and throne routes live in the data folder as JSON. A new petition should be a new event entry, with requirements and effects, rather than a change to the turn loop.

There is no music yet. If a click sound is added later at the expected audio path, the game will use it. Until then the buttons stay silent.

The interface fonts are Source Sans 3 (Adobe) and Cinzel (Natanael Gama and contributors), both under the SIL Open Font License. The license text is in `assets/fonts/OFL.txt`.

## Still placeholder

The prototype is playable from claimant choice through an ending, including saves and the Chronicle. It is not a finished campaign. The writing is a foundation, the art is temporary, and several later ideas are only shaped in the data so they can be added without a new architecture: foreign courts, children, a deeper economy, more houses, and more endings.

Debug tools are on. They add gold, claim, battles, and endings so content can be tested quickly. Turn them off before a release build.
