# Usurper art direction and provenance

All fourteen final PNG assets are in `assets/art/`. They were generated with the built-in ImageGen tool in this chat, inspected, and copied into the project. No fallback CLI or paid API runner was used. The exact final prompt set, including the four character and four environment subjects expanded from shared templates, is retained in [ART_PROMPTS.txt](ART_PROMPTS.txt).

The visual direction is restrained medieval realism: charcoal stone, umber cloth, weathered brass, muted regional colours, and warm light against a cold kingdom. Portraits represent people at their lore ages. Arlo remains a practical horseman rather than a crowned prince; Mira is an experienced fifty-four-year-old widow; Ethan carries six years of exile; Alistair wears northern armour. The map puts northern iron mountains above central Caerlyn, eastern Maren farmland, western woodland, and the southern ports.

| Final asset | Use |
| --- | --- |
| `throne.png` | Castle Caerlyn, title menu, court, endings |
| `mira.png` | Queen Mira Valen |
| `ethan.png` | Ethan Valen |
| `arlo.png` | Arlo |
| `alistair.png` | Lord Alistair Storm |
| `lucan_rook.png` | Chancellor Lucan Rook |
| `npcs.png` | Ten named court portraits, five columns by two rows |
| `units.png` | Ten tactical unit portraits, five columns by two rows |
| `map.png` | World atlas and political territory map |
| `battle.png` | Three-lane battlefield |
| `maren.png` | Eastern horse estates and Arlo's opening |
| `stormhold.png` | Northern fortress and Alistair's opening |
| `temple.png` | Temple of the Flame |
| `coast.png` | Southern Veyne harbour |

NPC atlas order, left to right: Garran Vale, Celene Veyne, Oren Pell, Nessa Grey, Bren Tal; then Tomas Maren, Evelyne Maren, Edric Edevane, Aldren Veil, Osric Harrow. Unit atlas order: infantry, spears, archers, cavalry, heavy infantry; then skirmishers, Queen's Guard, Storm Knights, Harrow longbows, Maren riders. The veteran band uses the infantry illustration. Atlas cells are selected at runtime without destructive cropping of the original sheet.

`ArtLibrary` resolves the assets, and `PortraitFrame` preserves faces across card proportions. Finished artwork replaces the old coloured portrait/unit placeholders. Existing native SVG crown iconography was edited directly to match the palette. JSON portrait metadata references the actual assets and atlas cells.

The original generated files are also preserved under `C:\Users\ademk\.codex\generated_images\01a0f3e4-d296-7110-b0ae-4c020add8afa\`. The project PNGs are byte-for-byte copies. The game ships pre-generated assets and does not request generated art at runtime. Engine-rendered screenshots at 1280×720 and 1920×1080 were inspected for portrait framing, contrast, typography, and placement alongside the narrative.
