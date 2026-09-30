# Usurper 1.0.0

The original succession prototype has been expanded into four complete illustrated campaigns. The player can pursue a crown, negotiate a different government, lose their claim, or reach the Council's final settlement. The release is silent while the owner prepares audio.

## Presentation and world

- Fourteen finished image assets supply all four claimant portraits, eleven named court portraits, tactical units, Caerlyn, Stormhold, Maren, the Temple, the coast, and the world map.
- A redesigned title screen, claimant cards, contextual scene backdrops, framed portraits, readable campaign panels, a world atlas, and illustrated epilogues share a charcoal and aged-gold palette.
- Fifteen biographies and twenty-four public lore entries establish personal histories, faith, geography, and institutions. Private details remain gated by discoveries in the current campaign.
- The Chronicle records forty-nine discoveries separately from each claimant's knowledge.

## Campaigns and consequences

- The catalogue contains 178 scenes and 521 choices. Forty-three new scenes develop civic government, family obligations, veterans, mines, trade, hospitals, harvests, and testimony.
- Decisions show immediate authored feedback. Their costs and conditions are rechecked when selected, and saving during feedback cannot apply the same choice twice.
- Two hundred and fifty claimant-specific route and outcome paragraphs have authored titles, with sixty or sixty-five outcomes per claimant before additional world, legacy, and character variations. Twenty decision milestones preserve important achievements or betrayals in the epilogue.
- Successful diplomacy can secure estates and their income. Promises, prisoner treatment, witness protection, military outcomes, and outside influence retain consequences.
- Common throne routes explain missing conditions. Claimant-specific and unusual routes appear only when relevant to the character's current discoveries.
- Every campaign has a finite conclusion. Warnings precede the final Council settlement, and its last report leads to an ending.

## Reliability and distribution

- Dead or captive characters no longer appear in incompatible scenes. Queued and scheduled audiences are checked against current state before presentation.
- Battle losses, prisoner status, and terminal outcomes propagate to the campaign once. Losing a final siege cannot produce a victorious coronation. Defending an already-held Caerlyn has appropriate battle and ending text.
- The lore-fixed forty-eight Queen's Guards remain a distinct elite company; larger household forces are auxiliaries.
- Saves retain random-generator state, pending battles and final epilogues, write atomically, and keep a recovery backup. Continuing a completed campaign does not duplicate Chronicle records.
- Debug tools are disabled, a Windows export preset is tracked, dependency notices accompany the playable package, and build/QA scripts reproduce the output.

See [QA.md](QA.md) and the retained machine reports under `docs/qa-results/` for exact final validation results and coverage limits.
