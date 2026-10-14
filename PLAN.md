# Plan: a fourth universe, Doctor Clawd (Doctor Who parody)

## Context

Clawd Clash has three parody universes: Star Clawds, Marvelous Clawds and Detective Clawds. This plan adds a fourth, a Doctor Who parody, as a full ensemble on the `doctor_who` branch. "Full ensemble" here means every character, place, move and transition carries the show. Nothing is added just to grow the count.

- **Name: Doctor Clawd.** Inside the code it is `case doctor = 3` with key `"doctor"`, in the folder `Sources/App/Universes/DoctorClawd/`, with file prefix `Doctor…`. The code avoids the franchise name, as the last commit did for the other universes.
- **Naming style** follows the other universes: light puns on the on-screen names (Darth Vapor, Thorr, Superb-Man). Generic titles like "The Doctor" and "The Master" are numbered or given a nickname. Actors' names are never used.
- **Size:** about **98 characters** (56 heroes including HEM, 42 villains including 3 agent-only) and **20 places**. That sits between Star Clawds (82) and the comic universes (194/208).

## How a universe plugs in (from exploring the code)

**New code: `Sources/App/Universes/DoctorClawd/`**
- `DoctorRoster.swift`:
  - `enum DoctorVillain` and `enum DoctorHero`, append-only, with `hem` as the last hero.
  - The persona dictionaries, with `.merging([.hem: hemPersona(.doctor)])`.
  - `Location.doctorHome(of:)`, the `doctorNemeses`, the ride closure and `let doctorTheme = Theme(...)`.
- Character art goes in `Art/DoctorHeroes1…N.swift` and `Art/DoctorVillains1…N.swift`, about 8–10 personas per file, in the same pattern as `StarClawdsHeroes1.swift`.
- Places go in `Places/DoctorScenes1…N.swift` as `let doctorPlacesN: [Location: Place]`, plus `static let` keys. Keys must be unique across universes, for example `skarro` and `gallifray`.
- `DoctorIcon.swift` holds the menu bar icon, a 28×26 police box in colour and mono.
- `DoctorWipes.swift` holds the place-to-place transitions (see below).

**Wiring into existing code.** `build.sh` and the tools already pick up `Universes/**`.
- **`Sources/Shared/Universe.swift`:** the new case, plus `key`, `title`, `villainCount`, `heroCount` and `agentOnly`. `claudeSide` stays the default, so Claude's sessions are heroes, i.e. Doctors and companions.
- **`Sources/Shared/Universe.swift`, rivals:** `rivals` pairs the Doctor and the Master like Han and Greedo, so they face off first when both are on stage.
- **`Theme.swift`:** a `Theme.of` case, plus `Ride.tardis`.
- **`Locations.swift:69`:** merge `doctorPlaces`.
- **`Universes/ComicTransition.swift`:** a `.doctor(DoctorTrip)` case in `duration`, `draw` and `pick`.
- **`Universes/Hem.swift`:** HEM's costume in every switch: a fez, a bow tie, and a sonic screwdriver as his weapon.
- **`Rides.swift`:** `drawTardis`.
- **`Sources/Saver/SaverView.swift:82, 200-205`:** add `"doctor"` to the Options choices and to the switch. This list is easy to miss: the build won't complain if it's left out.
- **`Tools/Preview/main.swift`:** add batches `doctorHeroes1…` and the enum lookups. Lookups by on-screen name already work.
- **`Tools/Transitions/main.swift:71`:** add the doctor branch.
- **`Pose.swift:77`, `Drills.swift:53/142`, `Habits.swift:119`, `Overlay.swift:1421`:** these are universe-specific `if`s. Check each one and decide whether the new universe should join it.

## Cast

Each entry gives: parody name — weapon / motion — signature move.

The engine's weapons map onto the show like this:
- `.lightning` with `Magic(jagged: false)` is a steady ray, used for the **sonic screwdriver**. The Doctors don't use guns, which suits the show, and steady-ray magic also unlocks the portal practice drill.
- `.saber` is melee and blocks shots.
- `.blaster` with a `ShotStyle` is ranged.
- `armoured: true` makes shots ricochet off, which suits Daleks and Cybermen.

### Heroes (56)

**The Doctors (17).** All of them use a sonic screwdriver, except the War Doctor and the Fugitive Doctor. Each is drawn with their own outfit; Fourteen reuses Ten's base drawing.

| # | Name | Look | Signature |
|---|---|---|---|
| 1 | Doctor One | frock coat, white hair, cane | grips lapels, "Hmm!" |
| 2 | Doctor Two | mop hair, baggy coat | plays the recorder |
| 3 | Doctor Three | velvet jacket, frilled shirt, cape | Venusian aikido chop (melee, saber) |
| 4 | Doctor Four | hat, endless scarf | offers a bag of jelly babies; scarf twirl |
| 5 | Doctor Five | cricket whites, celery | bowls a cricket ball (thrown) |
| 6 | Doctor Six | patchwork coat | coat flare, cat badge glint |
| 7 | Doctor Seven | question-mark umbrella | umbrella spin, plays the spoons |
| 8 | Doctor Eight | Edwardian coat, long hair | pocket watch swing |
| 9 | Doctor Nine | leather jacket, crop | "Fantastic!" grin and arms wide |
| 10 | Doctor Ten | brown pinstripe, trainers | glasses on, "Allons-y!" |
| 11 | Doctor Eleven | bow tie, fez | puts on the fez, straightens the bow tie |
| 12 | Doctor Twelve | hoodie, guitar | electric guitar riff (sonic sunglasses) |
| 13 | Doctor Thirteen | rainbow stripe, braces | builds a sonic from bits, "Brilliant!" |
| 14 | Doctor Fourteen | Ten's build, long coat, waistcoat | hands-in-pockets lean, "Oh!" |
| 15 | Doctor Fifteen | coat over kilt-style trousers | dance break |
| — | The War Doctor | bandolier, beard; blaster | scratches NO MORE on the wall |
| — | The Fugitive Doctor | utility coat; blaster | draws, spins and holsters |

**Companions and allies (38), plus HEM.** Their usual weapon is `.none`, for running and pointing, unless the table says otherwise.

| Name | Weapon | Signature |
|---|---|---|
| Susan Foreclaw | — | — |
| Ian Chesterclawd | — (melee punch) | — |
| Barbara Rite | — | — |
| Jamie McCrabmon | saber (dirk) | Highland charge |
| Zoe Hairiot | — | computes on her fingers |
| Brigadier Lethbridge-Stewed | blaster (bullet) | "Five rounds rapid" |
| Jo Grunt | — | — |
| Sarah Jane Smythe | — | — |
| Leelah | thrown (Janis thorn) | knife throw |
| K-Canine (dog robot, `.hover`-style glide) | blaster (beam, nose laser) | "Affirmative" |
| Romanah | — | — |
| Nyssa of Trakken | — | — |
| Tegan Jovanko | — | "Brave heart" |
| Pery Brown | — | — |
| Mel Shrub | — | screams |
| Ace | thrown (Nitro-9) | baseball-bat swing |
| Rose Tiler | — | **Bad Wolf**: golden vortex glow |
| Captain Jack Harkless | blaster | dies and gasps back to life |
| Martha Bones | — | — |
| Donna Nobble | — | "Oi!" |
| Wilf Moth | — | salutes with paintball gun |
| Amy Puddle | — | — |
| Rory Willjams | saber (centurion) | the Last Centurion stands guard |
| River Tune | blaster | "Hello, sweetie" |
| Clara Oswalt | — | soufflé |
| Madame Vasta | saber (katana) | tongue flick |
| Jenny Flynt | saber | — |
| Stracks | blaster | grenade "for later" |
| Bill Pans | — | — |
| Nardoll | — | — |
| Yaz Kahn | — | — |
| Graham O'Brine | — | — |
| Ryan Sinclare | — | — |
| Dan Louis | — | — |
| Ruby Monday | — | snow falls around her |
| Belinda Chandler | — | — |
| Kate Stewed | blaster (bullet) | — |
| Osgoode | — | inhaler and scarf |

Plus **HEM**, last as always, in a fez and bow tie with a sonic screwdriver.

"—" means no signature. A move goes in only where there is a clearly recognisable one.

### Villains (42)

**Time Lords and named villains (15)**

| Name | Weapon / motion | Signature |
|---|---|---|
| The Master | blaster (green beam, shrinking ray) | hypnotic "I am the Master" stare |
| The Burnt Master | blaster | — |
| The Velvet Master | blaster | — |
| The Snakeskin Master | lightning (green spit) | — |
| Mister Sexton | lightning steady (laser screwdriver) | drums, four beats |
| Missy | blaster (umbrella) | umbrella twirl, Mary Poppins float (`.hover`) |
| The Spy Master | lightning | — |
| Davross | lightning (blue fingers), hover chair | — |
| The Ranee | blaster | — |
| Omegah | lightning | — |
| Rascilon | lightning (gauntlet) | — |
| The Celestial Toyfaker | blaster `.card` | deals cards |
| Sootekh | lightning (death dust) | — |
| The Grate Intelligence | blaster `.ice` (snow) | — |
| The Valeyarn | lightning | — |

**Monsters (24)**

| Name | Weapon / motion | Notes |
|---|---|---|
| Dalick | blaster `.beam`, `.hover`, armoured | "EXTERMINATE!" callout |
| Supreme Dalick (red) | blaster `.beam`, `.hover`, armoured | — |
| Dalick Emperor | huge, `bulk`, armoured | — |
| Mondasian Cyberperson | blaster `.energy`, armoured | — |
| Cyberperson | blaster `.energy`, armoured | "DELETE" |
| Cyber Controller | blaster, armoured | — |
| Sontaron | blaster | "Sontar-ha!" |
| Weeping Angle | `.none` | moves only when nobody faces it (bespoke habit) |
| The Silents | lightning | — |
| The Odd | lightning (red eyes) | — |
| Zygone | lightning (stinger) | — |
| Silurean | blaster (venom) | — |
| Sea Devvil | blaster | — |
| Ice Warior | blaster `.beam` (sonic gun) | — |
| Autom | blaster (wrist) | — |
| Judoom | blaster | "Bo! Ko! To!" |
| Slitheem | saber (claws) | farts and giggles |
| Sycorex | lightning (bone whip) | — |
| Vashta Nerado | `.none` | "Hey, who turned the lights out?" |
| The Empty Kid | `.none` | "Are you my mummy?" |
| Clockwork Droid | saber (wrist blade) | ticking |
| The Candyman | `.none` | — |
| Lady Cassandro | `.none`, `.hover`, `canSit: false` | "Moisturise me!" |
| The Maestro | lightning steady (music notes) | conducts |

**Agent-only small fry (3).** Like the MSE-6, these only ever appear as agents: Adipoze (fly), Cybermite and Toclafayne (fly).

### Nemeses

Each pair faces off on the same stage:
- One ↔ Toyfaker
- Two ↔ Cyber Controller
- Three ↔ Master
- Four ↔ Davross
- Five ↔ Burnt Master
- Six ↔ Valeyarn
- Seven ↔ Candyman
- Eight ↔ Snakeskin Master
- Nine ↔ Autom
- Ten ↔ Sexton
- Eleven ↔ Silents
- Twelve ↔ Missy
- Thirteen ↔ Spy Master
- Fourteen ↔ Supreme Dalick
- Fifteen ↔ Maestro
- War ↔ Dalick Emperor
- Rose ↔ Dalick Emperor
- Amy ↔ Angle
- Clara ↔ Grate Intelligence
- Stracks ↔ Sontaron
- River ↔ Vashta Nerado
- Martha ↔ Sexton
- Brigadier ↔ Cyberperson
- Kate ↔ Zygone
- Ruby ↔ Maestro
- Jack ↔ Empty Kid

## Places (20)

Each is a `Place` with a still picture and a moving layer. Each also needs tall-canvas extras for the screen saver.

1. **TARDIS Console Room:** glowing rotor that pumps. This is the default place.
2. **Gallifray, the Citadel:** a glass dome, red grass, two suns.
3. **Skarro, the Dalick City:** pylons and a patrol.
4. **Totter's Yard, 1963:** fog and a police box.
5. **Powell Estate:** washing lines.
6. **Roald Doll Plass:** the water tower and Torchwood lift.
7. **UNIT HQ:** a Tower of London vault.
8. **Victorian Paternoster Row:** gaslight and snow.
9. **Trenzalore:** the graveyard and a giant TARDIS.
10. **The Library:** shadows that move.
11. **Satellite Five / Game Station:** screens.
12. **New Earth:** flying cars.
13. **Starship UK:** Smiler booths.
14. **Pompeii:** an erupting volcano.
15. **Café in Arles:** a starry-night sky.
16. **Bad Wolf Bay:** waves.
17. **Telos, the Cyber Tombs:** ice and frost.
18. **The Dalick Asylum:** snow.
19. **Sanctuary Base 6:** a black hole overhead.
20. **Christmas London:** the Sycorax ship overhead.

Each character gets a home among these, for example Daleks on Skaro, Cybermen on Telos, Vastra in Paternoster Row and Jack at the Plass.

## Mechanics that make it its own universe

1. **TARDIS (`Ride.tardis`).** Flyers' sorties and arrivals use a materialising box: it fades in and out with a pulsing lamp. Doctors and companions ride it.
2. **Transitions (`DoctorTrip`, 5).** Like the DC trips, each is weighted by who is on screen:
   - **Time vortex tunnel:** the classic title sequence.
   - **TARDIS dematerialise:** the old scene fades out with the box.
   - **Regeneration flare:** golden, picked when a Doctor is on screen.
   - **Blink:** the screen blinks and an Angle is closer each time; picked when an Angle is about.
   - **Dalick eyestalk iris:** picked when Daleks are on screen.
3. **Regeneration.** When a Claude session compacts its context, its Doctor regenerates into the next Doctor with a golden flare: same session, new face.
   - This needs the hook to register Claude Code's `PreCompact` event (`HookInstaller.swift`, `Sources/Hook/main.swift`). `StatusStore` would then move the session's leader to the next Doctor id and set a flag that the overlay plays as a flare.
   - Non-Doctor characters ignore it.
   - This is the riskiest item, so it is done last and in a way that can be left out cleanly.
4. **Weeping Angle habit.** The Angle stays frozen while anyone faces it and only moves when everyone is turned away, using the existing facing state.
5. **Practice drills (bespoke):**
   - Dalick "Elevate!" floats up a step.
   - Cyberpersons march in step.
   - Sontaron does drill chants.
   - Four throws jelly babies.
   - Twelve plays the guitar.
   - K-Canine plays fetch.

## Phases

Each phase builds, is checked with Preview sheets, and is shown to you before the next one.

1. **Skeleton.** The universe case, theme, Doctor Ten and a Dalick, the console room, the menu icon, HEM's costume, the saver option and Preview support. It runs end to end in the app, the window and the screen saver.
2. **Core ensemble.** About 40 characters: all 17 Doctors, 12 companions (Sarah Jane, K-Canine, Rose, Jack, Martha, Donna, Amy, Rory, River, Clara, Yaz, Ruby) and 11 villains (the Master, Missy, Sexton, Davross, Dalick ×2, Cyberperson, Sontaron, Angle, Silents, Autom). Also 8 places and the nemeses for these.
3. **Rest of the cast and places.** Up to 98 characters and 20 places, with the homes complete.
4. **Mechanics.** The TARDIS ride, the 5 transitions, the Angle habit, the bespoke drills, then regeneration.
5. **Docs and release.**
   - Add a column to the README universe table and the roster and location sheets (`Tools/RenderDocs`: a desktop lineup and a social preview).
   - The four-panel app icon (`Tools/MakeIcon`), `Tools/MakeSocial`, and `llms.txt` ("three" becomes "four" in several places).
   - A `CHANGELOG.md` entry in each phase.
   - A trailer, `REEL=doctor`, in `Tools/RenderPromo`.
   - **Needs your OK first, since it's public:** the `doctor-clawd` showcase repo (made private on 2026-10-14, holding this plan) goes public, and a `doctor-clawd` cask is added in `release.sh` (`write_cask` plus the `others` list).

Ids are append-only, so the enum order is the order characters are added, and phases never renumber.

## Verification

- **Build and install:** `./build.sh`. Every exhaustive switch makes a missing case a compile error. The cast-size assert at `Overlay.swift:175` catches a wrong `heroCount` or `villainCount`.
- **Characters:** `Tools/Preview/build.sh`, then:
  - `build/preview cast out.png "Doctor Ten"` shows every pose.
  - `build/preview fight out.png "Doctor Ten" "Dalick"`.
  - `build/preview drills …`.
  - `build/preview place out.png "Doctor Clawd"` shows all the places.
- **Sheets:** check them visually, one batch per Art file.
- **Transitions:** `Tools/Transitions` renders the frames.
- **In the app:** Settings → Universe → Doctor Clawd. Check that a new Claude session is cast as a Doctor or companion, that a subagent can be a villain or agent-only character, that the screen saver's Options include it, and that Random cycles through all four.
- **Regeneration:** run `/compact` in a Claude session and watch the flare and the next Doctor.
