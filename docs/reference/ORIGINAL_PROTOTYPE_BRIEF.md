You are the lead developer responsible for building a complete playable prototype of a game called **USURPER** in **Godot 4.x using GDScript**.

The game is a **turn-based, story-driven medieval political strategy game** inspired by the political tension of *Game of Thrones* and the decision-driven structure of *Yes, Your Grace*, while remaining mechanically and narratively original.

Your task is to build the game systems, architecture, UI, data structures, gameplay flow, save system, battle system, event system and enough placeholder content for a fully playable prototype.

A separate agent will later provide final artwork, portraits, backgrounds, icons, music, animation and other assets.

For now:

- Use simple placeholder graphics.
- Use coloured rectangles, labels, silhouettes, icons and basic Godot shapes.
- Keep ALL visual assets easy to replace.
- Never hard-code gameplay logic into artwork.
- Use clear asset paths.
- Make UI panels modular.
- Keep characters, events, factions, territories, items and story content data-driven wherever practical.
- Use reusable scenes and resources.
- Prioritise robust architecture over visual polish.

The end result should feel like a playable narrative strategy game rather than a technical systems demo.

---

# 1. CORE PREMISE

The game takes place in the medieval kingdom of **Nezrel**.

King Erol II has died at age seventy after disappearing from public view for several weeks.

His death is mysterious.

The official explanation is natural causes.

Many people believe Queen Mira was involved.

Erol left no publicly recognised heir.

Four characters may ultimately attempt to seize the throne.

The player chooses one at the beginning of the campaign.

The four playable claimants are:

## QUEEN MIRA VALEN

Widow of King Erol.

Age 54.

Lives in Castle Caerlyn.

Controls the Queen's Guard.

Has access to the royal court, treasury, private royal correspondence and important secrets.

She understands more about Erol's death than anyone else.

Her weakness is legitimacy.

Nezrel has only been ruled by a woman once before, more than two hundred years ago by Queen Aria.

Mira's campaign should focus heavily on:

- Court politics
- Secrets
- Blackmail
- Espionage
- Royal authority
- Political survival
- Controlling information
- Maintaining Caerlyn

Her playstyle should feel like political intrigue.

---

## ETHAN VALEN

King Erol's younger brother.

Age 61.

Former commander of the Queen's Guard.

Once one of the most respected men in Nezrel.

Six years ago Queen Mira accused Ethan of sexually assaulting her.

Ethan denied the accusation.

King Erol offered him execution or exile.

Ethan chose exile.

He severed contact with the throne and became a wandering vagabond.

He remains remembered and respected by many soldiers and common people.

His legal dynastic claim is strong.

His campaign should focus on:

- Reputation
- Honour
- Old friendships
- Veterans
- Popular support
- Rebuilding from nothing
- Deciding whether power corrupts him

Ethan begins poor and largely powerless but possesses considerable latent support.

---

## ARLO

Age 24.

Stable boy raised by wealthy House Maren.

His mother died during childbirth.

It is heavily rumoured that Arlo is King Erol's illegitimate son.

House Maren appears to have received secret royal payments throughout Arlo's childhood.

Erol secretly visited Arlo over many years under another identity.

Arlo begins the game with almost no political power.

His campaign should initially feel partly like a mystery or adventure.

His focus is:

- Discovering his identity
- Finding proof of his parentage
- Building alliances from nothing
- Winning common support
- Deciding what his royal blood actually means
- Potentially being legitimised

Arlo should undergo the largest rise from obscurity to power.

---

## LORD ALISTAIR STORM

Age 46.

Lord of House Storm.

Controls much of northern Nezrel.

Commands a large professional army.

Rules from the fortress Stormhold.

House Storm has controlled the North for centuries.

Alistair claims that Nezrel requires a strong ruler or the kingdom will collapse.

He has already declared that Queen Mira should marry him and make him king.

Otherwise he may take the throne by force.

His campaign focuses on:

- Military strength
- Intimidation
- Territory
- Political coercion
- Order
- Conquest
- Converting fear into legitimacy

Alistair begins with the strongest military position but the weakest legitimate dynastic claim.

---

# 2. CORE GAME OBJECTIVE

The primary campaign objective is:

**Build Claim to 100 and successfully Take the Throne.**

Claim is the central campaign progression meter.

However:

Reaching 100 Claim does NOT automatically mean victory.

When Claim reaches 100, unlock a major action:

**TAKE THE THRONE**

The available methods depend upon the player's campaign choices.

Possible throne-taking methods include:

- Military conquest
- Council recognition
- Noble acclamation
- Religious coronation
- Popular uprising
- Proof of bloodline
- Recovery of King Erol's final will
- Political marriage
- Forced abdication of a rival
- Regency arrangement
- Other hidden routes

When the player chooses Take the Throne, run an endgame resolution sequence.

The result should examine the entire campaign state.

Victory or defeat should be determined using factors including:

- Claim
- Army strength
- Rations
- Treasury
- Support factions
- Noble alliances
- Surviving rivals
- Rival hostility
- Court support
- Religious support
- Popular support
- Territory control
- Major secrets discovered
- Evidence possessed
- Key characters alive or dead
- Fear
- Reputation
- Broken promises
- Important story flags
- Foreign involvement
- State of Nezrel
- Method chosen to take the throne

The player can reach 100 Claim and still fail.

The player may also become monarch yet receive a dark or disastrous ending.

---

# 3. CORE GAME LOOP

The game should be turn based.

One turn approximately represents one week.

Target campaign length:

Approximately **30–40 turns** for a normal campaign.

The exact length may vary based on character, story events and player choices.

Each turn follows this structure:

## PHASE 1 — REALM OVERVIEW

Show:

- Turn number
- Date or seasonal indicator
- Treasury
- Rations
- Forces
- Claim
- Major faction relationships
- Controlled territories
- Current modifiers
- Important warnings
- News from around Nezrel

Example:

TURN 12 — THE FIRST FROSTS

Gold: 1,280
Rations: 19
Forces: 2,850
Claim: 46 / 100

News:

- Alistair's forces crossed the River Dorn.
- Food prices increased in Caerlyn.
- Rumours spread that Ethan has returned.
- A royal messenger was found murdered.

The news feed should make the world feel alive.

---

## PHASE 2 — AUDIENCE / STORY EVENTS

Present approximately 2–3 narrative situations per turn.

These may include:

- Petitions
- Threats
- Opportunities
- Character encounters
- Noble requests
- Refugee crises
- Army disputes
- Religious matters
- Personal dilemmas
- Spy reports
- Prisoners
- Trade proposals
- Criminal cases
- Rumours
- Family matters
- Rival communications
- Foreign envoys
- Assassination threats

Each event should generally provide 2–4 meaningful choices.

Choices should affect multiple systems where possible.

Example:

Northern refugees request food.

Choice A:
Give 5 Rations.

Effects:
Rations -5
People support +8
Possible later volunteer event
Hidden flag set

Choice B:
Give 100 Gold.

Effects:
Gold -100
People +3

Choice C:
Turn them away.

No immediate cost
Hidden resentment flag
Potential later consequence

Choice D:
Recruit able-bodied refugees.

Forces +120
People -5
Fear +2
Possible later mutiny or loyalty event

Avoid having obvious "correct" answers.

---

## PHASE 3 — STRATEGIC ACTION

After story events, allow the player to choose one major strategic action.

Possible actions:

- Recruit soldiers
- Purchase rations
- Raise taxes
- Reduce taxes
- Visit a noble house
- Send an envoy
- Investigate a rumour
- Search royal records
- Spy on a rival
- Spread propaganda
- Host a feast
- Raid enemy territory
- Fortify territory
- Train forces
- Attempt assassination
- Bribe official
- Search for evidence
- Travel personally
- Negotiate alliance
- Arrange marriage
- Blackmail character
- Call in favour
- Open trade agreement
- Recruit mercenaries
- Address troops
- Hold public audience
- Seek religious endorsement

Make strategic actions data-driven so more can be added later.

Different playable characters should have unique strategic actions.

Examples:

Mira:
- Search Erol's chambers
- Seal royal records
- Summon court official
- Use Queen's Guard investigation

Ethan:
- Rally veterans
- Reveal true identity
- Visit former regiment
- Appeal directly to the people

Arlo:
- Investigate royal payments
- Search for witnesses to his birth
- Ask House Maren for support
- Reveal royal evidence

Alistair:
- Demand submission
- Call northern levies
- Occupy territory
- Intimidate lesser lord
- Issue ultimatum

---

## PHASE 4 — WORLD RESPONSE

At the end of the turn:

- Rival AI acts
- Relationships update
- Territories may change
- Events resolve
- Armies may move
- Factions may change allegiance
- New rumours appear
- Story flags trigger
- Long-term consequences occur

Examples:

HOUSE HARROW DECLARES FOR ETHAN.

Storm troops seize the eastern road.

The refugees aided twelve turns earlier return with volunteers.

A lord previously blackmailed betrays the player.

The player's decisions must feel remembered by the game.

---

# 4. PRIMARY RESOURCES

Keep primary resources readable.

The four main visible campaign resources are:

## GOLD

Used for:

- Recruitment
- Bribery
- Rations
- Mercenaries
- Construction
- Gifts
- Spies
- Feasts
- Diplomacy
- Army expenses
- Special events

Gold income may come from:

- Taxes
- Controlled territories
- Trade
- Noble supporters
- Tribute
- Raids
- Special events

---

## RATIONS

Represents food and supplies.

Armies consume rations each turn.

Larger forces consume more.

If Rations become critically low:

- Army morale decreases
- Desertions occur
- Forces decrease
- Commanders become unhappy
- Battle penalties apply

If Rations reach zero for too long:

- Severe desertion
- Mutiny events
- Disease
- Starvation
- Claim penalties

---

## FORCES

Represents total military strength.

This is an abstract number.

Example:

2,840 Forces

Actual battle scenes use a small number of pieces representing larger formations.

---

## CLAIM

Range:

0–100.

Claim represents how believable and politically viable the player's path to monarchy has become.

Claim can increase through:

- Noble support
- Battle victories
- Public support
- Religious endorsement
- Discovering proof
- Defeating rivals
- Capturing important territories
- Controlling Caerlyn
- Political marriage
- Recovering Erol's will
- Great deeds
- Successful diplomacy

Claim can decrease through:

- Defeats
- Scandal
- Broken promises
- Failed political gambits
- Loss of important territory
- Exposure of secrets
- Betrayal
- Famine
- Atrocities
- Failed throne attempt

At 100:

Unlock Take the Throne.

---

# 5. SECONDARY POLITICAL SUPPORT SYSTEM

Track support from five major political blocs.

Each should have a numeric internal value but display descriptive states.

The blocs are:

- Nobility
- Common People
- The Flame
- Military
- Court

Display categories such as:

Hostile
Opposed
Neutral
Supportive
Devoted

Different paths to victory should rely on different support combinations.

Examples:

A military conqueror may have:

Military: Devoted
People: Hostile
Court: Opposed
Nobility: Supportive
Flame: Neutral

A popular claimant may have:

People: Devoted
Flame: Supportive
Court: Supportive
Military: Weak
Nobility: Neutral

Do not make every victory require all factions.

---

# 6. FEAR

Implement a secondary Fear mechanic.

Fear can be increased by:

- Executions
- Intimidation
- Brutal military actions
- Public punishments
- Assassinations
- Threats
- Crushing rebellions

Fear can produce short-term benefits:

- Easier coercion
- Reduced resistance
- Increased tax compliance
- Forced noble support
- Lower chance of open defiance

Excessive Fear can create:

- Secret plots
- Rebellion
- Assassinations
- Lower popular support
- Desertion
- Treachery
- Darker endings

Alistair should interact particularly strongly with Fear.

---

# 7. CHARACTER RELATIONSHIPS

Important NPCs require individual relationship states.

Track an internal number but present readable descriptions.

Example states:

Hostile
Cold
Neutral
Warm
Loyal

Important characters should also store:

- Personal memories
- Grudges
- Favour owed
- Secret known
- Promise made
- Promise broken
- Political alignment
- Current faction
- Alive/dead
- Captured/free
- Married/unmarried where relevant

A character may personally like the player while politically opposing them.

Do not reduce every relationship to a single number.

---

# 8. SECRETS, EVIDENCE, FAVOURS AND LEVERAGE

Build a dedicated system for political information.

The player can obtain:

- Secrets
- Evidence
- Documents
- Favour tokens
- Political debts
- Blackmail material
- Witness testimony
- Royal letters
- Family records
- Military intelligence

Examples:

SECRET:
Ethan was inside Mira's chambers.

EVIDENCE:
House Maren received payments from Erol.

FAVOUR:
Lady Veyne owes you one political favour.

LEVERAGE:
A lord's son has been arrested.

These objects should be stored in a player inventory or political ledger.

They may unlock dialogue choices.

Example:

[USE SECRET]
"Perhaps Lord Harrow would prefer that his correspondence remain private."

Using leverage may gain support while creating resentment.

Secrets should be usable in multiple ways where possible:

- Reveal publicly
- Conceal
- Destroy
- Sell
- Blackmail
- Trade
- Present as legal evidence
- Give to ally

---

# 9. TERRITORY SYSTEM

Build a simplified political map of Nezrel.

Use approximately 12–16 major regions.

Do not make this a full grand strategy game.

Territories should support story and resources.

Possible territories:

- Caerlyn
- Crownlands
- Northern Reach
- Stormlands
- Maren Vale
- Veyne Coast
- Harrowlands
- Western Forest
- Riverlands
- Eastern March
- Southern Ports
- Old Borderlands

Each territory should support data such as:

- Controller
- Local loyalty
- Gold income
- Ration production
- Recruitment potential
- Fortification
- Strategic value
- Special resource
- House allegiance
- Current unrest

Examples:

Caerlyn:
Court influence
Claim bonus
Political importance

Maren Vale:
Rations
Horses
Agriculture

Veyne Coast:
Trade income
Ships
Gold

Northern Reach:
Iron
Strong troops

Allow territory control to change through:

- Diplomacy
- Battle
- Defection
- Rebellion
- Event
- Marriage
- Political agreement

---

# 10. HOUSES AND FACTIONS

Create initial support for major houses.

At minimum:

## HOUSE STORM

Led by Alistair.

Northern military powerhouse.

Resources:
Iron
Timber
Professional soldiers

Motto:
"We Do Not Bend."

---

## HOUSE MAREN

Led by Lord Tomas Maren.

Raised Arlo.

Resources:
Food
Horses
Money

Motto:
"What We Sow Endures."

---

## HOUSE VEYNE

Led by Lady Celene Veyne.

Controls southern trade.

Resources:
Ports
Ships
Money

Motto:
"All Rivers Reach Us."

---

## HOUSE HARROW

Led by Lord Osric Harrow.

Ancient western house.

Economically weakened.

Hates House Storm.

Motto:
"Remember the Old Blood."

---

## HOUSE EDEVANE

Queen Mira's birth family.

Led by Lord Edric Edevane.

Resources:
Court influence
Wealth
Connections

Motto:
"Wisdom Before Steel."

---

# 11. IMPORTANT NPCS

Create data structures and initial placeholder content for:

## Captain Garran Vale

Commander of the Queen's Guard.

Formerly trained under Ethan.

Loyalty divided between Mira and Ethan.

---

## Lady Celene Veyne

Powerful political operator.

Values stability and trade.

Potential major kingmaker.

---

## Master Oren Pell

Royal physician.

Knows about Erol's illness and final night.

Possesses dangerous information.

---

## Nessa Grey

Former royal chamber servant.

Missing.

Potential witness to Erol's final night.

---

## Marshal Bren Tal

Commander of the Royal Army.

Initially refuses to support any claimant.

Potentially one of the most important military allies.

---

## Lord Tomas Maren

Raised Arlo.

Knows information about Arlo's origins.

---

## Lady Evelyne Maren

Arlo's adoptive mother.

Dislikes King Erol.

Protective of Arlo.

---

## Edric Edevane

Mira's nephew.

Ambitious.

Publicly supports Mira but potentially unreliable.

---

## Father Aldren Veil

High Keeper of the Flame.

Powerful religious authority.

Wants to prevent the destruction of Nezrel.

---

# 12. RIVAL CLAIMANT AI

The three claimant characters not selected by the player remain active in the world.

Do not make them passive scripted objects.

Build a simplified rival AI system.

Each rival should track:

- Resources
- Claim
- Army
- Territory
- Allies
- Relationships
- Personality
- Strategy
- Current threat level
- Story state

Rival behaviour should be influenced by personality.

Mira values:

- Control
- Secrets
- Caerlyn
- Court influence

Ethan values:

- Honour
- Reputation
- People
- Former soldiers

Arlo values:

- Family
- Truth
- Justice
- Identity

Alistair values:

- Strength
- Order
- Authority
- Territory

Their personalities can evolve based on events.

For example:

Repeated betrayals might make Ethan harsher.

Repeated humiliation might make Arlo more ruthless.

Military setbacks might force Alistair toward diplomacy.

The rival campaigns do not need to simulate every player mechanic in full.

Use believable abstract simulation.

---

# 13. BATTLE MINI-GAME

Combat should be simple, readable and fast.

Do NOT build a complex real-time strategy system.

Battles should be turn-based.

A handful of units represent much larger formations.

Use a battlefield with three lanes:

LEFT FLANK
CENTRE
RIGHT FLANK

Each army deploys approximately 4–7 unit pieces.

Each visual unit represents hundreds or thousands of troops.

Example:

One Queen's Guard unit may represent 450 soldiers.

---

# 14. UNIT TYPES

Implement basic unit types:

## INFANTRY

Balanced.

Reliable.

---

## SPEARS

Strong against cavalry.

---

## ARCHERS

Ranged support.

Weak if exposed.

---

## CAVALRY

Fast.

Strong against exposed flanks and archers.

---

## HEAVY INFANTRY

Very durable.

Slower.

---

## SKIRMISHERS

Mobile.

Cheap.

Good for harassment.

---

Also support named elite formations such as:

- Queen's Guard
- Storm Knights
- Harrow Longbows
- Maren Riders

Use unit data Resources so future unit types are easy to add.

---

# 15. BATTLE COMMANDS

Each battle round should allow meaningful but simple choices.

Possible commands:

- Advance
- Hold
- Charge
- Flank
- Volley
- Rally
- Withdraw
- Commit Reserve

Units should have:

- Strength
- Morale
- Attack
- Defence
- Unit type
- Traits
- Commander
- Position
- Status effects

---

# 16. MORALE

Morale should be as important as casualties.

If army morale collapses:

THE ARMY BREAKS.

Battle ends.

Morale changes through:

- Casualties
- Flanking
- Commander death
- Successful charge
- Rally
- Elite unit presence
- Army starvation
- Previous defeats
- Character traits

---

# 17. RESERVES

Allow units to remain in reserve.

The player may commit them later.

This creates tactical decisions such as:

Use cavalry immediately.

Or hold them until an enemy flank collapses.

---

# 18. COMMANDERS AND NAMED CHARACTERS

Important NPCs may command units.

Named characters can:

- Provide passive traits
- Rally troops
- Improve certain unit types
- Affect morale
- Be wounded
- Be captured
- Die

Death should be permanent unless explicitly required otherwise by story.

If Captain Garran dies:

- Remove his later events
- Remove his relationship
- Replace him as commander
- Trigger consequences
- Update future narrative

---

# 19. RETREAT

Allow retreat.

Retreat should preserve some forces but have consequences.

Example:

Retreat:
Forces -350
Claim -3

Fighting to destruction:
Forces -1700
Possible commander death
Claim -12

Losing one battle should not automatically end the game.

Recovery from defeat should be possible.

---

# 20. CHARACTER-SPECIFIC CAMPAIGN DESIGN

Each playable claimant must feel significantly different.

## MIRA — POLITICAL INTRIGUE

Starting advantages:

- Caerlyn control
- Court access
- Queen's Guard
- Royal secrets
- Treasury access

Disadvantages:

- Suspicion over Erol's death
- Female succession opposition
- Ethan controversy
- Limited direct military power

Unique systems or bonuses:

- Better spying
- Cheaper court actions
- More starting secrets
- Stronger blackmail
- Access to royal records
- Better intelligence

---

## ETHAN — RETURNED HERO

Starting advantages:

- Popular reputation
- Veteran contacts
- Strong dynastic claim
- Military experience

Disadvantages:

- No territory
- Little money
- Small army
- Exile scandal
- Mira's accusation

Unique strengths:

- Rally veterans
- Popular support growth
- Army morale
- Honour-based options
- Easier recruitment from loyal populations

---

## ARLO — UNDERDOG

Starting advantages:

- Potential direct bloodline
- House Maren protection
- Common background
- Strong potential popular appeal

Disadvantages:

- Almost no political recognition
- Weak army
- Weak treasury
- No recognised title

Unique mechanics:

- Identity investigation
- Evidence collection
- Bloodline proof
- Commoner alliances
- Hidden Erol encounters
- Rapid transformation if legitimacy proven

---

## ALISTAIR — CONQUEROR

Starting advantages:

- Strong army
- Territory
- Gold
- Northern support
- Fortified homeland

Disadvantages:

- Weak legal claim
- Suspicious court
- Fear of military takeover

Unique strengths:

- Strong military
- Demands
- Ultimatums
- Territorial conquest
- Fear
- Coercion

---

# 21. CAMPAIGN ACT STRUCTURE

Use four broad acts.

These do not need to be shown explicitly to the player.

## ACT I — THE KING IS DEAD

Approximately Turns 1–8.

Focus:

- Confusion
- Claimants emerge
- Early alliances
- Erol mystery
- Establishing player position

---

## ACT II — THE GATHERING

Approximately Turns 9–18.

Focus:

- Armies grow
- Houses choose sides
- Major evidence emerges
- First major wars
- Stronger rival actions

---

## ACT III — THE FRACTURE

Approximately Turns 19–28.

Focus:

- Civil war
- Territory shifts
- Foreign involvement
- Hunger
- Betrayal
- Deaths
- Difficult decisions
- Alliances collapse

---

## ACT IV — THE CROWN

Final section.

Focus:

- Rivals surrender or escalate
- Final alliances
- Assassination attempts
- Caerlyn
- Maximum Claim
- Throne attempt
- Resolution

---

# 22. STORY EVENT SYSTEM

Build the story event system to be entirely data driven where practical.

Each event should support:

- Event ID
- Title
- Description
- Character portrait placeholder
- Speaker
- Trigger conditions
- Minimum turn
- Maximum turn
- Required flags
- Forbidden flags
- Required claimant
- Required territory
- Required relationships
- Required resources
- Choices
- Immediate effects
- Delayed effects
- Follow-up event IDs
- Hidden flags
- Probability/weight
- One-time or repeatable
- Priority

Choices should support effects such as:

- Add/remove Gold
- Add/remove Rations
- Add/remove Forces
- Add/remove Claim
- Change faction support
- Change NPC relationship
- Add Fear
- Set flag
- Unlock secret
- Add evidence
- Add favour
- Change territory controller
- Kill character
- Capture character
- Trigger battle
- Add modifier
- Schedule future event
- Change rival behaviour

---

# 23. STORY FLAGS

Use extensive hidden flags.

Examples:

MIRA_HELPED_REFUGEES
ETHAN_EXECUTED_PRISONERS
ARLO_FOUND_FIRST_LETTER
ALISTAIR_SPARED_HARROW
EROL_WILL_DISCOVERED
NESSA_FOUND
GARRAN_DEAD
VEYNES_SUPPORT_PLAYER
MIRA_ETHAN_RECONCILIATION
ARLO_BLOOD_PROVEN

Old decisions should meaningfully influence later story events.

---

# 24. ENDGAME ROUTES

At 100 Claim, determine which throne routes are available.

Possible routes:

## CONQUEST

Requirements may include:

- Strong army
- Access to Caerlyn
- Military support

Triggers final major battle.

---

## ACCLAMATION

Requirements:

- Strong noble support
- Council backing
- Sufficient Claim

May avoid battle.

---

## THE FLAME

Requirements:

- Religious support
- High Keeper endorsement
- Sufficient legitimacy

---

## PEOPLE'S CROWN

Requirements:

- Very high popular support
- Certain story flags
- Weak rival public support

---

## BLOOD OF EROL

Primarily Arlo.

Requirements:

- Strong evidence
- Witnesses
- Documents
- Political recognition

---

## KING'S WILL

Requirements:

- Recover Erol's missing testament
- Prove authenticity

---

## MARRIAGE

Requirements:

- Appropriate claimant alive
- Suitable relationship
- Political agreement

---

## ABDICATION

Requirements:

- Rival sufficiently weakened
- Leverage
- Political support

---

## REGENT / PROTECTOR

Possible arrangements involving:

- Arlo
- Ethan
- Mira
- Other claimant combinations

---

# 25. ENDGAME RESOLUTION

Build a flexible evaluation system rather than a single scripted ending.

When Take the Throne is chosen:

Calculate:

- Route strength
- Claim
- Resources
- Faction support
- Rival positions
- Army strength
- Key NPC relationships
- Kingdom stability
- Fear
- Secrets
- Broken promises
- Story flags
- Territory
- Erol evidence
- Foreign intervention

Produce:

- Successful throne claim
- Pyrrhic victory
- Failed claim
- Betrayal
- Civil war continuation
- Assassination
- Forced exile
- Imprisonment
- Death
- Alternative political settlement

---

# 26. MODULAR ENDING SYSTEM

Do not write endings as only one fixed text block.

Construct them from components.

Track:

## METHOD

How did the player obtain the throne?

- Conquest
- Election/acclamation
- Bloodline
- Religion
- Popular uprising
- Marriage
- Will
- Political compromise

## RIVAL FATES

Each rival may be:

- Dead
- Executed
- Exiled
- Pardoned
- Imprisoned
- Serving player
- Married into regime
- Missing
- Rebel leader

## KINGDOM STATE

Possible states:

- Prosperous
- Stable
- Recovering
- Divided
- Starving
- War-torn
- Occupied
- Rebellious

## PLAYER LEGACY

Possible descriptions:

- Beloved
- Respected
- Feared
- Despised
- Controversial
- Mysterious
- Weak
- Legendary

## NPC EPILOGUES

Show outcomes for major surviving characters.

This allows many combinations without requiring hundreds of handcrafted ending scenes.

---

# 27. FAILURE ENDINGS

Do not simply show GAME OVER.

Create narrative defeat endings.

Examples:

- Execution
- Exile
- Return to obscurity
- Imprisonment
- Death in battle
- Assassination
- Forced abdication
- Escape to foreign kingdom
- Return to wandering
- Stormhold last stand
- Arlo returning to House Maren

Some defeat endings may unlock Chronicle entries.

---

# 28. REPLAYABILITY

Replayability is one of the game's core pillars.

Each campaign should reveal only part of the truth.

The player should gradually learn more by playing different claimants.

Mira reveals more about:

- Erol's illness
- His final night
- Palace secrets

Ethan reveals more about:

- His exile
- Queen Mira
- Old military relationships

Arlo reveals more about:

- Erol's secret journeys
- Arlo's birth
- Royal payments
- House Maren

Alistair reveals more about:

- Northern politics
- Secret correspondence
- Internal royal informants

---

# 29. CHRONICLE OF NEZREL

Create a persistent metaprogression menu called:

**THE CHRONICLE OF NEZREL**

This persists across playthroughs.

Possible categories:

The King's Death — 0 / 7 discoveries
The Exile of Ethan — 0 / 6
The Birth of Arlo — 0 / 8
Queen Aria — 0 / 5
House Storm — 0 / 5
The Missing Testament — 0 / 6

Discoveries unlock lore entries.

Completing campaigns may unlock:

- New events
- Alternate dialogue
- Hidden story routes
- Rare endings
- Additional background information

---

# 30. CROSS-CAMPAIGN SECRET UNLOCKS

Support persistent unlock flags.

Important:

The player CHARACTER should not magically know things learned in previous campaigns.

Instead prior discoveries may unlock new opportunities naturally.

Example:

Playing Mira reveals an old passage under Caerlyn.

Future Ethan campaigns may gain a new event:

"The Forgotten Passage."

The narrative should justify discovering it.

---

# 31. RARE ENDINGS

Leave architecture for secret routes such as:

## THE FOUR BANNERS

All four claimants survive.

Civil war avoided.

A new political system emerges.

---

## ARIA'S HEIR

Discover lost history concerning Queen Aria.

Use legal precedent to reshape succession.

---

## BROTHERS

Ethan recognises Arlo as Erol's son.

Ethan becomes Protector rather than king.

---

## WOLF AND SPIDER

Mira and Alistair unite through marriage.

Depending on relationship and flags, one may later betray the other.

---

## NO KING

The monarchy is abolished.

This should be extremely difficult and hidden.

---

# 32. UI STRUCTURE

Build a clear medieval-inspired placeholder UI without requiring finished art.

Primary screens:

## MAIN MENU

- New Game
- Continue
- Chronicle of Nezrel
- Settings
- Quit

---

## CLAIMANT SELECTION

Four claimant cards.

Each card shows:

- Placeholder portrait
- Name
- Age
- Starting difficulty
- Starting strengths
- Short description
- Starting resource summary

---

## MAIN CAMPAIGN SCREEN

Include:

Top bar:

- Gold
- Rations
- Forces
- Claim

Side panel:

- Faction support
- Current allies
- Main warnings

Main area:

- Character scene / event portrait / background placeholder

Bottom:

- Event text
- Dialogue choices
- Continue

Buttons for:

- Map
- Court / Characters
- Secrets
- Army
- Chronicle
- Strategic Action
- End Turn

---

## MAP SCREEN

Show simplified Nezrel map using placeholder polygons or panels.

Each territory clickable.

Show:

- Controller
- Income
- Food
- Troops
- Loyalty
- Fortification
- Local house

---

## CHARACTER SCREEN

Show major NPC list.

Each entry:

- Portrait placeholder
- Name
- Role
- Relationship
- Political allegiance
- Known secrets
- Status

---

## SECRETS / LEDGER SCREEN

Categories:

- Secrets
- Evidence
- Favours
- Debts
- Documents
- Rumours

---

## ARMY SCREEN

Show:

- Total Forces
- Ration consumption
- Morale
- Units
- Commanders
- Elite formations
- Current modifiers

---

## BATTLE SCREEN

Simple three-lane interface.

Show:

LEFT | CENTRE | RIGHT

Player army bottom.

Enemy top.

Reserve area.

Current morale.

Commands.

Battle log.

---

# 33. PLACEHOLDER VISUAL DESIGN

Until final art exists:

Portraits:
Use solid-colour framed silhouette placeholders labelled with character name.

Backgrounds:
Use simple panels labelled:

CASTLE CAERLYN
STORMHOLD
MAREN ESTATE
BATTLEFIELD
ROYAL COURT

Icons:
Use Godot-native shapes or simple temporary SVGs if convenient.

Map:
Use simplified shapes.

Units:
Use coloured circles, shields or square tokens.

Make every placeholder swappable by changing an asset path or replacing a scene texture.

Do NOT build systems that depend on pixel coordinates of final artwork.

---

# 34. DATA ARCHITECTURE

Prefer Resources, JSON or another clean data-driven structure.

Recommended data types:

ClaimantData
CharacterData
FactionData
HouseData
TerritoryData
StoryEventData
StoryChoiceData
BattleUnitData
ArmyData
SecretData
EvidenceData
StrategicActionData
EndingData
CampaignState
PersistentMetaState

Avoid enormous scripts containing all game content.

---

# 35. PROJECT ARCHITECTURE

Use modular scenes and managers.

Possible structure:

res://
  scenes/
    main_menu/
    campaign/
    events/
    battle/
    map/
    characters/
    claimant_select/
    endings/
    chronicle/

  scripts/
    managers/
    systems/
    ai/
    ui/
    battle/

  data/
    claimants/
    characters/
    factions/
    territories/
    events/
    units/
    endings/
    strategic_actions/

  assets/
    placeholders/
    portraits/
    backgrounds/
    icons/
    units/
    ui/

  saves/

Suggested autoload systems:

GameManager
SaveManager
EventManager
CampaignManager
AudioManager placeholder
MetaProgressManager

Do not overuse autoloads unnecessarily.

---

# 36. SAVE SYSTEM

Support:

- Manual save if appropriate
- Autosave at end of turn
- Continue campaign
- Separate persistent Chronicle progress
- Multiple campaign save slots if reasonable

Campaign save must preserve:

- Turn
- Player claimant
- Resources
- Claim
- Support levels
- NPC states
- Relationships
- Rival states
- Territory controllers
- Story flags
- Secrets
- Evidence
- Favors
- Army
- Dead characters
- Scheduled events
- Modifiers

Meta save preserves:

- Chronicle discoveries
- Campaign completions
- Hidden unlocks
- Endings discovered
- Claimants completed

---

# 37. EVENT AUTHORING

Make future event creation easy.

A developer should be able to add a new event largely through data rather than editing game-system code.

Create several demonstration event chains.

At minimum build enough content for a meaningful prototype.

Aim initially for approximately:

- 30–50 generic events
- 10+ claimant-specific events for each claimant
- Several chained events
- Several delayed consequence events
- Several battle-triggering events
- Several secret-discovery events
- Several alliance events
- Several betrayal events
- Several possible ending routes

These can initially use concise placeholder writing.

Architecture matters more than final prose.

---

# 38. CHOICE DESIGN PRINCIPLE

Most important decisions should influence at least two systems.

Example:

HELP REFUGEES

Rations -5
People +8
House Maren +2
Flag REFUGEES_HELPED

EXECUTE TRAITOR

Fear +5
Military +3
Nobility -4
Flag TRAITOR_EXECUTED
Potential later revenge event

Avoid:

Choice A = obvious good.
Choice B = obvious evil.
Choice C = obvious optimal strategy.

Choices should involve trade-offs.

---

# 39. WORLD PRESSURE

The game should pressure the player.

Systems should create competing needs.

Examples:

Large army:
Strong militarily
Consumes more rations

Heavy taxation:
More gold
Less popular support

Bribing nobles:
Political support
Less treasury

Merciful decisions:
Popular support
May appear weak

Fear:
Immediate compliance
Long-term conspiracy

Territorial expansion:
More resources
More fronts to defend

The player should frequently think:

"What can I afford not to do?"

---

# 40. THE MYSTERY OF EROL

The King's death is the central narrative mystery.

Initial official story:

King Erol died naturally at seventy after illness.

Hidden truth framework:

Erol suffered an incurable neurological illness.

Symptoms included:

- Weakness
- Confusion
- Memory loss
- Headaches
- Paranoia

Only a few people knew.

He produced contradictory instructions about succession.

Documents may support:

- Ethan
- Arlo
- Mira

During his final night:

Present:

- Mira
- Master Oren Pell
- Nessa Grey
- Erol

Erol may have asked Mira to end his suffering.

Mira may have administered enough medicine to kill him.

Whether this constitutes:

- Murder
- Mercy killing
- Natural death
- Assisted death
- Something more complicated

should remain politically and narratively contentious.

Do not reveal the entire truth in one campaign.

---

# 41. THE MISSING TESTAMENT

King Erol dictated a final document.

It vanished.

Different factions believe it:

- Names a successor
- Gives Mira power
- Recognises Ethan
- Legitimises Arlo
- Orders a council decision

Nessa Grey may know part of the truth.

A remembered line:

"The Crown must belong not to the one born nearest it, but to the one who can keep Nezrel whole."

This should support multiple interpretations.

---

# 42. DEVELOPMENT PRIORITIES

Build in stages.

## STAGE 1 — FOUNDATION

Implement:

- Project architecture
- Main menu
- Claimant selection
- Campaign state
- Resources
- Basic UI
- Turn loop
- Basic saving

---

## STAGE 2 — EVENT ENGINE

Implement:

- Data-driven events
- Choices
- Conditions
- Effects
- Flags
- Relationships
- Delayed events

---

## STAGE 3 — POLITICAL SYSTEMS

Implement:

- Faction support
- Houses
- NPC relationships
- Secrets
- Evidence
- Favours
- Claim
- Fear

---

## STAGE 4 — MAP AND TERRITORIES

Implement:

- Territory data
- Map screen
- Control changes
- Resource production
- Territory strategic actions

---

## STAGE 5 — RIVAL AI

Implement simplified rival decisions.

---

## STAGE 6 — BATTLE SYSTEM

Implement:

- Three lanes
- Units
- Morale
- Commands
- Reserves
- Casualties
- Retreat
- Named commanders

---

## STAGE 7 — ENDGAME

Implement:

- Claim 100 trigger
- Route eligibility
- Throne attempt
- Outcome evaluation
- Modular endings

---

## STAGE 8 — REPLAYABILITY

Implement:

- Chronicle
- Persistent discoveries
- Hidden unlocks
- Multiple campaign completion tracking

---

# 43. PROTOTYPE COMPLETION CRITERIA

The initial prototype is considered successful when the player can:

1. Launch the game.
2. Choose one of four claimants.
3. Play through repeated turns.
4. Experience narrative events.
5. Make meaningful decisions.
6. Gain and lose Gold.
7. Gain and consume Rations.
8. Increase and lose Forces.
9. Gain and lose Claim.
10. Change political relationships.
11. Gain and use secrets or evidence.
12. Take strategic actions.
13. Control territory.
14. Observe rival claimant activity.
15. Enter battles.
16. Win or lose battles.
17. Lose important NPCs.
18. Reach 100 Claim.
19. Choose an available throne-taking method.
20. Receive an ending based on campaign state.
21. Save and reload.
22. Start another claimant campaign.
23. Unlock Chronicle information across playthroughs.

---

# 44. CODE QUALITY REQUIREMENTS

Use:

- Typed GDScript where sensible.
- Signals to decouple systems.
- Reusable scenes.
- Clean comments.
- Descriptive names.
- Data-driven design.
- Separation between UI and game state.
- Clear game-state ownership.
- Minimal duplication.

Avoid:

- Giant monolithic scripts.
- Hardcoded event chains.
- UI scripts directly changing unrelated global state.
- Excessive singleton use.
- Magic numbers without constants.
- Final art assumptions.

---

# 45. DEBUG TOOLS

Include a development/debug panel that can be disabled for release.

Allow developer controls such as:

- Add Gold
- Add Rations
- Add Forces
- Add Claim
- Set faction relationship
- Trigger event by ID
- Start battle
- Change territory owner
- Unlock secret
- Kill/revive debug NPC where technically possible
- Advance turn
- Set Claim to 100
- Force specific ending route

This will greatly simplify future development.

---

# 46. BUILD FOR EXPANSION

Design every major system with future content expansion in mind.

Future versions may add:

- Additional playable claimants
- More kingdoms
- Diplomacy with foreign nations
- More battlefield units
- Marriage and children
- Expanded economy
- More houses
- More territories
- Deeper court system
- More endings
- DLC campaigns

Do not implement these unless needed for the prototype.

Simply avoid architecture that would make them impossible.

---

# 47. CORE DESIGN PHILOSOPHY

The player should never feel as though they are simply maximising numbers.

Every campaign should tell the story of what the player was willing to do to obtain power.

The central question is:

**What makes someone the rightful ruler?**

Blood?

Tradition?

Strength?

Religion?

Popular support?

Competence?

The wishes of the previous king?

The game should not answer this for the player.

Different routes should make different arguments.

Every playable claimant should be capable of becoming:

- Heroic
- Pragmatic
- Ruthless
- Tyrannical
- Tragic

depending upon player decisions.

Winning the throne should not necessarily mean achieving a good ending.

Losing the throne should not necessarily make the campaign meaningless.

---

# 48. FINAL PLAYER EXPERIENCE

The intended gameplay loop should feel like:

**Manage household → receive petitions → make political decisions → gather resources → collect secrets → negotiate alliances → strengthen forces → fight occasional decisive battles → watch rivals respond → increase Claim → uncover pieces of the mystery → choose when and how to take the throne → receive an ending based upon everything done along the way.**

Then the player begins again as somebody who may have been their greatest enemy during the previous campaign.

A player who despises Mira during an Ethan campaign may play Mira next and discover information that completely changes their perception of her.

Playing Arlo may reveal that both previous perspectives were incomplete.

Playing Alistair may reveal another hidden conspiracy.

The player gradually constructs the history of Nezrel through multiple conflicting perspectives.

There should be **no single omniscient presentation of the truth during an individual campaign**.

---

# 49. YOUR DEVELOPMENT INSTRUCTIONS

Begin building the game.

Do not wait for final artwork.

Do not block development because an asset is missing.

Use placeholders.

When a feature is ambiguous, choose the simplest implementation that:

1. Preserves the intended design.
2. Is expandable later.
3. Keeps code maintainable.
4. Produces playable results quickly.

Prioritise a complete vertical slice over partially implementing every imaginable feature.

The first vertical slice should ideally allow:

**Claimant selection → 5–10 turns → several narrative events → one strategic action per turn → rival activity → one battle → meaningful consequences → a prototype throne attempt or ending.**

After the vertical slice works reliably, expand toward the full campaign structure.

Maintain a clear TODO list for systems/content not yet implemented.

Whenever placeholder data is required, create believable Nezrel-themed content rather than generic "Character 1 / Event 1" entries.

The finished project should function as a strong technical and gameplay foundation upon which final writing, artwork, sound and additional content can later be layered without major rewrites.