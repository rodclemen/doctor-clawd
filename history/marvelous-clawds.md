# Marvelous Clawds history: Avengers: Clawd Wars 0.1.0

Avengers: Clawd Wars is the sister app of Clawd Wars, and grew out of Clawd Wars 2.28.1. It became the Marvelous Clawds universe of Clawd Clash in 3.0.0 (see [CHANGELOG.md](../CHANGELOG.md)). Their shared history up to then is in [star-clawds.md](star-clawds.md).

## 0.1.0 (unreleased)

### Changed
- **New name and identity: Avengers: Clawd Wars.** It installs as `Avengers Clawd Wars.app` (bundle ID `com.rodclemen.avengersclawdwars`) and can sit on the same Mac as Clawd Wars. Its hook binary is `avengers-hook`, and each app only adds, replaces or removes hook entries whose command contains its own binary name, so the two never strip each other's hooks from `~/.claude/settings.json` or the other AIs' settings. Session state lives in `~/.claude/avengers-status`, the screen-saver feed in `~/Library/Application Support/Avengers Clawd Wars`, and the Copilot hook file is `~/.copilot/hooks/avengers-clawd-wars.json`. The cast and locations are still Star Wars for now.

### Added
- **The Marvel cast: 46 heroes and 46 villains** (`Sources/App/Roster.swift`, art in `Sources/App/Art/`). Avengers, Guardians of the Galaxy, X-Men, the Fantastic Four and street-level heroes against Thanos, Loki, Ultron, Doom, Magneto, Spider-Man's rogues, Hydra and more. The Ultron Sentry and the Doombot only ever turn up as agents. Their art is a plain coloured stand-in for now.
- **Fighting styles.** Melee fighters (shields, hammers, claws, fists, blades) duel and knock shots aside; ranged fighters each have their own kind of shot: repulsor and photon blasts, Cyclops' and the Sentinels' beams, Spider-Man's webs, Hawkeye's arrows, bullets, the Human Torch's fireballs, Iceman's ice, Gambit's charged cards, Bullseye's knives and the Goblin's pumpkin bombs. Magic users stream forked lightning or a steady ray in their own colours: Doctor Strange orange, Scarlet Witch red, Loki green, Thanos purple, Storm white.
- **Flight.** Iron Man, Thor, Captain Marvel, Vision, Storm and the other flyers take off when they move along the line and land where they're going, and fly up and away when their agent is done. Doctor Strange, Magneto, MODOK and other hoverers float a few pixels off the ground. Spider-Man swings in arcs on a web line.
- **Arch-enemies face off first**: Captain America and Red Skull, Thor and Loki, Spider-Man and the Green Goblin or Venom, Wolverine and Sabretooth, Black Panther and Killmonger and more are paired with each other whenever both are fighting, in the overlay and the screen saver. This replaces Han and Greedo.
- **Ships pick people up.** When Captain America, Black Widow, Hawkeye, Nick Fury or the Hulk finish, the Quinjet lands for them; the Guardians get the Milano. This replaces the Millennium Falcon.
- **22 Marvel locations** as places for the window and the screen saver, from Avengers Tower to the Savage Land (`Sources/App/Places/`). Stand-in skies for now.
- **`Tools/Preview`**: contact sheets of every character in every pose, of two characters fighting, of the locations at window and screen-saver size, and of the ships.

### Changed
- **Claude Code plays the heroes.** When another AI (Codex, Qwen, Gemini, Copilot) is running, Claude Code's sessions and agents are heroes and the other AI's are villains; with only Claude running, anyone can turn up.
- **One drawing pipeline for everyone** (`Sources/App/Pose.swift`): heroes and villains now share the same moods, fight poses, idle habits and sitting rules, and each character is a `Persona` with its drawing function, so adding one is one entry in an art file.
- **The menu bar icon is Captain America's shield**, in colour or monochrome.

### Removed
- The Star Wars cast, locations, Han shooting first and the cantina band.
- The Star Wars promo video and `Tools/RenderPromo` (they live on in Clawd Wars).

### Changed (tools)
- **`Tools/MakeIcon`** now renders Captain America holding his shield into Thanos' gauntlet blast, and **`Tools/RenderDocs`** draws the roster as heroes and villains with the new pipeline.

### Added (art)
- **All 92 characters are drawn**, each one Clawd in costume, replacing the stand-ins, and nearly every one has a signature move: Iron Man flips his faceplate up, Cap tosses his shield and catches it, Thor twirls Mjolnir and calls lightning, the Hulk pounds his chest and roars, Wolverine pops his claws, Nightcrawler BAMFs away and back, Star-Lord dances with his Walkman, Ant-Man shrinks to ant size, Drax "goes invisible", Deadpool eats a chimichanga, the Torch flames off and on, Thanos snaps, Loki turns into a snake, Mystique and the Skrull turn into plain Clawd and back, the Grandmaster dances and laughs, Doc Ock's tentacles snap, Sandman crumbles and rises, Kingpin taps his cane, Batroc high-kicks. Flyers have proper flight poses (Iron Man's boot jets, Thor's cape, Falcon's wings, the Goblin and the Surfer on their glider and board), Spider-Man swings with his hand up on the web line, Professor X rides his hover-chair, and the giants (Sentinel, Fin Fang Foom, Juggernaut, Apocalypse, Abomination, Thanos, Groot) are drawn big.
- **The Quinjet and the Milano**, drawn properly with lowering ramps, landing gear and thrusters.
- **All 22 places are drawn**, each with a moving layer and extra scenery at screen-saver size: Avengers Tower over the Manhattan skyline, the Sanctum Sanctorum's seal window and staircase, Wakanda's Golden City at sunset, Asgard and the Bifrost, the Sakaar arena, Knowhere's neon streets, ruined Titan, the Helicarrier's flight deck above the clouds, Xavier's School, rainy Hell's Kitchen rooftops, Vormir, the Quantum Realm, Castle Doom over Latveria, a Hydra base, the Daily Bugle's roof, Ego's planet, Kamar-Taj, the Raft, the Battle of New York, the Dark Dimension, Attilan and the Savage Land.
- **New app icon** (Captain America holding his shield into Thanos' gauntlet blast), roster and location sheets, social preview and screen-saver thumbnail, all rendered from the art.

### Fixed
- **Giants no longer duel face-first into each other**: `Persona.bulk` says how far a body reaches past plain Clawd, and duels stand that much further apart (overlay, screen saver and preview).
- **No muzzle flash from a bow**: Hawkeye's arrows leave quietly, like webs, beams and ice.
- Callouts rise with a flying character; the over-the-head speech lines only Han and Greedo used are gone.

### Docs
- **README and `llms.txt` rewritten** for the Marvel version: cast, fights, flight, places, living next to Clawd Wars, building, and the preview tool. Out-of-date Star Wars screenshots are removed until new ones are taken.

### Added (second and third waves)
- **85 more characters, drawn**, taking the cast to 94 heroes and 83 villains: War Machine, Wiccan, Speed, Quicksilver, Kate Bishop, Yelena, Okoye, Shuri, Valkyrie, Korg, Wong, Hercules, Sentry, Cosmo, Kraglin, Adam Warlock, Nova, Kitty Pryde (with Lockheed), Jubilee, Psylocke, Bishop, Cable, Havok, Emma Frost, Banshee, Angel, Domino, X-23, Miles Morales, Spider-Gwen, Spider-Woman, Black Cat, Luke Cage, Iron Fist, Jessica Jones, the Punisher, Elektra, Blade, Black Knight, Monica Rambeau, Clea, Doctor Voodoo, Howard the Duck, Squirrel Girl, Throg, Lockjaw, Forbush Man and Jeff the Land Shark (agent-only); Galactus (canvas-high), Kang, Mephisto, Knull, Annihilus, the High Evolutionary, Morgan le Fay, Scorpion, Shocker, Hobgoblin, Morbius, Mister Negative, Chameleon, Tombstone, Mister Sinister, Omega Red, Toad, Pyro, Blob, the Brood, Cassandra Nova, Graviton, Absorbing Man, Crimson Dynamo, Wrecker, Baron Mordo, Enchantress, Arnim Zola, Count Nefaria, the Leader, Maestro, Malekith, Surtur, Kurse, a Frost Giant, a Hydra super soldier and a Kree soldier. Every one has a signature move.
- **16 more from new places** (art on the way): Mobius, Sylvie, Kid Loki, Alligator Loki, Hunter B-15, Red Guardian, Ka-Zar, Rescue, and Zabu, Morris and Dum-E as agent-only small fry; Miss Minutes, Callisto, Exodus, a Soul Eater and a Red Room Widow.
- **21 more places**: Baxter Building (the Fantastic Four's home now), Jotunheim, Muspelheim, Hala, Genosha, Madripoor, Sokovia, Galactus' Worldship, Harlem and K'un-Lun are drawn; Xandar, the Avengers Compound, the TVA, Krakoa, the Morlock Tunnels, Asteroid M, New York City's streets, the Savage Land Citadel, Tony Stark's workshop, the Red Room and Ta Lo are on the way. Iron Man, Spider-Man, Shang-Chi, Magneto, Apocalypse, Emma Frost, War Machine, Yelena and Nova move into their new homes.
- **30 more arch-enemy pairs** (the Surfer and Galactus, Ant-Man and Kang, Ghost Rider and Mephisto, the Punisher and the Kingpin, Sylvie and Miss Minutes…), and more ship pickups (Kate Bishop and Yelena on the Quinjet, Kraglin and Cosmo on the Milano).
- **Flyers take to the air now and then**: every half minute or so a flyer takes off where it stands, hangs in the air for a few seconds and lands; in a fight, ranged and magic flyers go up every few seconds and keep shooting or casting from up there, with the shots and streams following them. Melee flyers stay down to duel. In the overlay, the window and the screen saver.

### Fixed (from Clawd Wars)
- **"Needs you" waits as long as it takes**: a session waiting for your answer no longer gives up after 15 minutes and falls asleep; it keeps its "!" until you answer, and goes idle at once if you press Esc (read from the session's transcript). Brought over from a fix in Clawd Wars.

### Docs (later)
- **The promo**: a 50-second 1080p trailer with its own soundtrack (`promo/avengers-clawd-wars-promo.mp4`) and its storyboard, rendered by `Tools/RenderPromo` from the app's art. The top of the README plays a 720p upload of it inline (GitHub's web uploads stop at 10 MB), with the full 1080p file linked under it. The inline copy opens on the end card for a moment, so its thumbnail isn't a black frame.
- **A desktop shot under the video**, like Clawd Wars': sessions with name tags and agents with task labels fighting along the bottom of the screen (Thanos blasting Iron Man in the air, Spider-Man and the Green Goblin, Wolverine and Sabretooth, Red Skull against Cap's shield), rendered by `Tools/RenderDocs` as `docs/desktop.png`.
- **A centred social preview**: four heroes facing four villains under the title, instead of a line running off one side.
- **"Sister app", not "fork"**: the README, changelog, llms.txt and the GitHub description describe Avengers: Clawd Wars as Clawd Wars' sister app.
- **No em dashes** anywhere in the docs, menus, hover cards, banners or code comments.
- **The README's roster and places cover everyone**: all 105 heroes and 88 villains are listed, the place count is 43, and the roster and location sheets are re-rendered.
- **The last five places are drawn**: New York City's streets, the Savage Land Citadel, Tony Stark's workshop, the Red Room and Ta Lo. Nothing is a stand-in any more.

Eleven artists drew ninety-two Clawds in an afternoon, and all of them argued about whose hammer was coolest.
