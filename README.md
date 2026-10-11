# BlockyDungeons: Shards of the Prism

An endless, Minecraft Dungeons-inspired blocky action-RPG made in **Godot 4.3**. Every model, texture, level, sound and music track is generated in code, so the project has no external asset dependencies.

> Before the first block was laid, there was the Prism of Ages. Malric, first of the Wayfinders, tried to hold it alone and was hollowed out into **Malgrath, the Hollow Crown**. The Prism shattered into five Shards, and each Shard twisted a realm around itself. In the village of Oakhollow, a sleeper wakes with the mark of a Wayfinder glowing on their hand...

## Running the game

1. Install [Godot 4.3+](https://godotengine.org/download) (the standard build; .NET is not needed).
2. Open `project.godot` in the Godot editor, or run `godot --path .` from this folder.
3. Press **F5** to play.

Saves go to Godot's user data folder (`user://blockydungeons_save.json`). The game autosaves every minute and when you travel, beat a boss, or quit from the pause menu.

## Playing on a phone (Android)

The game detects phones automatically. On a phone or a low-RAM device (under 3 GB) it starts on the **Low (Phone)** graphics preset. This preset is tuned for budget hardware such as the **Samsung Galaxy A03 Core** (Unisoc SC9863A, PowerVR GE8322, 2 GB RAM). It uses:

- The OpenGL compatibility renderer and a 60 FPS cap.
- A 70% render scale with no MSAA.
- No shadows, glow, SSAO, procedural sky or dynamic lights. Glowing blocks still glow.
- Shorter view distance, fewer enemies (22) and particles, and a smaller, slower-updating minimap.
- Chunk generation spread over many frames, one row at a time, with new enemies and villagers spawned one per frame, so exploring never hitches.
- The "see-through" occlusion shader only on trees and buildings, never on the ground. Shader `discard` is expensive on PowerVR GPUs.

You can change the preset at any time in **Settings** (title screen or pause menu), with Auto, Low, Medium, High or Ultra. Settings also has a FPS counter toggle.

**Touch controls:**
- Drag anywhere on the left half of the screen for a floating joystick.
- The right side has buttons for Attack, Bow, Roll, artifacts 1, 2 and 3, Potion and Use.
- Menu buttons on the left open the Bag, Quests, Skills, Map, Codex and Menu.
- Attacks automatically aim at the nearest enemy.

**Auto-Attack (phone only):** turn it on in Settings. Your hero automatically swings at enemies in melee reach and shoots the nearest enemy within 12 blocks.

To try the phone experience on a desktop, run `godot --path . -- --force-mobile`.

**Building the APK:**
1. Install the Godot 4.3 Android export templates.
2. In Editor Settings, set the Android SDK path and a debug keystore.
3. Use the included **Android** export preset (Project -> Export). It builds for armeabi-v7a and arm64-v8a, in landscape and immersive mode.

## Controls

| Action | Keyboard / Mouse | Gamepad |
| --- | --- | --- |
| Move | WASD / arrows | Left stick |
| Melee (3-hit combo, heavy finisher) | Left mouse / J | X |
| Ranged (aims at cursor) | Right mouse / K | RB |
| Dodge roll | Space | A |
| Artifacts (magic powers) | 1 / 2 / 3 | Y / B / LB |
| Health potion | Q | D-pad up |
| Interact / talk | E or F | D-pad down |
| Inventory | I or Tab | Back |
| Quests / Skills / Map / Codex | L / P / M / C | |
| Zoom | Mouse wheel, + / - | |
| Pause menu | Esc | Start |

Follow the **golden compass arrow** next to your hero to reach the tracked quest objective.

## What's in it

- **An infinite open world.** Deterministic chunked voxel terrain streams in around you in every direction. Enemies (and their loot) get stronger the farther you travel from the Realm Gate.
- **Five realms with 20 biomes:**
  - **Verdant Reach:** meadows, birchwood, dunes, swamp, highlands.
  - **Ashen Underrealm:** lava, crimson forest, basalt spires, soulfire.
  - **Frostfall Wastes:** tundra, taiga, ice spikes, glaciers.
  - **Sporelight Hollows:** glowing fungal forests, toxic pools.
  - **Hollow Void:** floating islands over the abyss.
- **Villages in every realm.** Each realm has its own architecture: houses, lamps, farms, a plaza centerpiece, a Realm Gate and a bounty board. Villagers fill 10 roles: Elder, Blacksmith, Merchant, Enchanter, Mystic, Alchemist, Farmer, Guard, Cartographer and Bard. Each role offers its own services and quests.
- **42 creature types and 20 bosses.**
  - Creature AI covers melee, ranged, casters, summoners, exploders, chargers, teleporters and turrets, plus elite variants.
  - Each realm has four boss lairs. Bosses fight in phases, with telegraphed slams, meteors, novas, volleys, charges, teleports, poison pools and summons. Bosses return for rematches.
- **Caves:** procedural room-and-corridor dungeons with ore veins, treasure chests, an elite guardian and an exit portal.
- **The story:**
  - 47 main story quests across 5 chapters, with dialogue, a prologue and an epilogue.
  - 225 generated side quests from villagers, plus endless bounties from village boards (272+ quests in total).
  - 40 lore entries found at Lore Stones, plus boss lore in the Codex.
- **Loot:**
  - 5 rarities (Common to Mythic), 25 melee weapons and 14 ranged weapons.
  - 18 armors, 22 artifacts and 26 accessories (rings, amulets, charms).
  - 18 enchantments and 35 resources.
  - Sources: chests, ore veins, supply crates, enemies, elites and bosses.
- **Magic:**
  - **22 artifacts:** fireball, frost nova, chain lightning, meteor, void beam, summon wolves or an iron golem, vortex, starfall, time slow, spirit blades and more.
  - **7 shrine power-ups:** Rage, Wind Walker, Arcane Surge, Giant's Might, Spectral Form and more.
- **Progression:**
  - Levels (up to 100) grant attribute points (Might, Vitality, Arcana, Agility, Fortune), enchantment points and perk points. There are 16 perks.
  - Leveling also unlocks equipment slots: artifact slots 2-3, an amulet, a second ring and a charm.
  - Village services: Blacksmiths upgrade (+10) and reforge gear, Enchanters add and level enchantments, and Mystics empower artifacts.
  - After the finale, **Ascension** ranks raise difficulty and loot further.
- **Character creator:** pick an origin (Warrior, Ranger or Mystic) and customize skin, hair style and color, eyes, outfit, boots, headwear and cape, with a live 3D preview.
- **Presentation:**
  - An isometric camera that shows the hero through anything in the way.
  - Day and night cycles, per-realm skies, fog, glow and ambient particles.
  - Damage numbers, swing arcs, screen shake and loot beams colored by rarity.
  - A minimap, a progressively drawn world map, and synthesized sound effects and music for each realm.

## Project layout

```
scenes/main.tscn           Entry scene
scripts/autoload/          Data (content), Story (lore), State (player/save), Quests, Sfx, Game (runtime hub)
scripts/world/             World streaming, terrain/realm generator, cave generator, voxel mesher
scripts/entities/          Player, enemies, bosses, villagers, projectiles, pickups, interactables, abilities, models, FX
scripts/ui/                HUD, menus, creator, inventory, skills, quests, codex, map, dialogue, gate, bounty board
tests/                     Headless test scenes
```

## Tests

The `tests/` scenes run headless:

```sh
godot --headless --path . tests/smoke_test.tscn   # world gen, combat, all artifacts, all bosses, caves, travel, save/load
godot --headless --path . tests/flow_test.tscn    # full UI flow: menu -> creator -> game -> every screen -> death -> travel -> continue
godot --headless --path . tests/story_test.tscn   # entire main story chain and side-quest generation
godot --headless --path . tests/mobile_test.tscn -- --force-mobile   # phone preset, touch joystick/buttons, auto-attack, streaming budget
```

`tests/screenshot.tscn` captures screenshots, and it needs a display. On Linux:
`xvfb-run godot --rendering-driver opengl3 --path . tests/screenshot.tscn -- /tmp/shots`.
