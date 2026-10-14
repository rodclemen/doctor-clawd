import Foundation

// Villains: Spider-Man's rogues.

let villains2: [MarvelVillain: Persona] = [
    .greenGoblin: Persona(name: "Green Gobbler", weapon: .blaster, motion: .fly, shot: .thrown(C(0xFF8A1E)), canSit: false,
                  muzzle: (42, 28), headTop: 16, signature: 3, callout: "Ha ha ha ha!",
                  draw: drawGreenGoblin),
    .venom: Persona(name: "Venum", weapon: .saber, bulk: 2, headTop: 22, signature: 2.8, callout: "We are Venum.",
                  draw: drawVenom),
    .carnage: Persona(name: "Carnaige", weapon: .saber, headTop: 20, signature: 2.6,
                  draw: drawCarnage),
    .docOck: Persona(name: "Doctor Octoclawd", weapon: .saber, armoured: true, pivot: ockShoulder, headTop: 21, signature: 3,
                  draw: drawDocOck),
    .mysterio: Persona(name: "Mysterioso", weapon: .lightning, magic: Magic(core: C(0xE0FFE8), glow: C(0x4AE08A), jagged: false),
                  headTop: 15, signature: 3.2,
                  draw: drawMysterio),
    .electro: Persona(name: "Elektro", weapon: .lightning, magic: Magic(core: C(0xFFFFE0), glow: C(0xFFE01E)),
                  headTop: 12, signature: 2.6,
                  draw: drawElectro),
    .vulture: Persona(name: "Vultcher", weapon: .saber, motion: .fly, headTop: 21, signature: 2.8,
                  draw: drawVulture),
    .rhino: Persona(name: "Rhyno", weapon: .saber, armoured: true, canSit: false, pivot: rhinoShoulder, bulk: 2, headTop: 15,
                  signature: 3,
                  draw: drawRhino),
    .sandman: Persona(name: "Sandmann", weapon: .saber, headTop: 22, signature: 3.5,
                  draw: drawSandman),
    .lizard: Persona(name: "The Lizzard", weapon: .saber, headTop: 23, signature: 2.6,
                  draw: drawLizard),
    .kraven: Persona(name: "Craven", weapon: .saber, headTop: 21, signature: 2.6,
                  draw: drawKraven),
]

// MARK: - Helpers

/// A solid round-ended stroke: limbs, tentacles, spear shafts.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.05)
}

/// A bending limb from `from`, setting off at `angle` degrees and turning `bend` degrees along its `length`, tapering
/// from `r0` to `r1`. `joint` dots the segments. Returns where it ends and which way it points there.
@discardableResult
private func tentacle(_ c: PixelCanvas, from: (x: Double, y: Double), angle: Double, bend: Double, length: Double,
                      _ col: Px, joint: Px? = nil, r0: Double = 1.1, r1: Double = 1.1) -> (x: Double, y: Double, a: Double) {
    let n = 10
    var x = from.x, y = from.y, a = angle
    for i in 0..<n {
        let r = a * .pi / 180
        let nx = x + cos(r) * length / Double(n), ny = y + sin(r) * length / Double(n)
        bar(c, x, y, nx, ny, col, r: r0 + (r1 - r0) * Double(i) / Double(n - 1))
        if let joint, i % 2 == 1 { c.px(Int(nx.rounded(.down)), Int(ny.rounded(.down)), joint) }
        x = nx; y = ny; a += bend / Double(n)
    }
    return (x, y, a)
}

/// Claws fanning from a tip at (`x`, `y`) pointing `angle` degrees.
private func claws(_ c: PixelCanvas, _ x: Double, _ y: Double, angle: Double, spread: Double = 28, length: Double = 3.5,
                   _ col: Px, n: Int = 3) {
    for k in 0..<n {
        let a = (angle + (Double(k) - Double(n - 1) / 2) * spread) * .pi / 180
        bar(c, x, y, x + cos(a) * length, y + sin(a) * length, col, r: 0.5)
    }
}

/// A tiny 3×3 letter, for the Goblin's cackle.
private func glyph(_ c: PixelCanvas, _ ch: Character, _ x: Int, _ y: Int, _ col: Px) {
    let rows: [String]
    switch ch {
    case "H": rows = ["X.X", "XXX", "X.X"]
    case "A": rows = [".X.", "XXX", "X.X"]
    default: rows = ["XXX", "XXX", "XXX"]
    }
    c.pattern(x, y, rows, ["X": col])
}

/// Sound rings pushing out to the right from (`x`, `y`), `p` running on.
private func roarRings(_ c: PixelCanvas, x: Int, y: Int, p: Double, col: Px = C(0xF4EEE0)) {
    for i in 0..<3 {
        let f = frac(p * 4 + Double(i) / 3), rx = x + Int(f * 10), a = 0.8 * (1 - f)
        for dy in (-2 - i)...(2 + i) where abs(dy) > 0 || i == 0 { c.px(rx + abs(dy) / 2, y + dy, col.alpha(a)) }
    }
}

// MARK: - Green Goblin

/// Green Goblin: green-skinned Clawd with yellow eyes and a wicked grin, in the purple pointed hood, tunic and gloves,
/// always riding his bat-glider, a jack-o'-lantern pumpkin bomb in his throwing hand. Signature: he cackles ("HA HA"),
/// rocking back and juggling the pumpkin bomb.
private func drawGreenGoblin(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x6CB04A), skinShade = C(0x4E8A36), purple = C(0x6A2A9A), purpleDark = C(0x4A1A72)
    let laugh = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    let rock = laugh > 0.5 && frac((p.signature ?? 0) * 9) < 0.5 ? -1 : 0
    // The glider bobs and banks a little in the air.
    if p.flying { c.oy += sin(p.t * 5) > 0 ? -1 : 0 }
    drawLegs(c, Look(leg: skin), step: -1)
    c.rect(19, 38, 2, 2, purple); c.rect(23, 38, 2, 2, purple); c.rect(31, 38, 2, 2, purple); c.rect(35, 38, 2, 2, purple)
    drawGlider(c, t: p.t, flying: p.flying)
    c.oy += p.breathe + rock
    drawBody(c, Look(body: skin, shade: skinShade, arm: purple, eye: nil))
    // Tunic, with the satchel strap across it.
    c.rect(18, 34, 20, 4, purple)
    c.rect(18, 37, 20, 1, purpleDark)
    for k in 0..<5 { c.px(21 + k * 3, 34 + k / 2 + (k > 3 ? 1 : 0), C(0x8A5A2A)); c.px(22 + k * 3, 34 + k / 2 + (k > 3 ? 1 : 0), C(0x8A5A2A)) }
    // The pointed hood, its tip flopping back.
    c.pattern(16, 16, [
        "PP......................",
        ".PPp....................",
        "..PPPPp.................",
        "...PPPPPPPp.............",
        "...PPPPPPPPPPPp.........",
        "..PPPPPPPPPPPPPPPPp.....",
        ".PPPPPPPPPPPPPPPPPPPPp..",
        ".PPPPPPPPPPPPPPPPPPPPPP.",
        ".PPPPPPPPPPPPPPPPPPPPPP.",
        "..PPPPPPPPPPPPPPPPPPPP..",
        "..PP................PP..",
        "..P..................P..",
    ], ["P": purple, "p": purpleDark])
    // Pointed ears out of the hood.
    c.pattern(15, 26, ["SS..", ".SS."], ["S": skin]); c.pattern(37, 26, ["..SS", ".SS."], ["S": skin])
    // Yellow eyes under heavy, slanted brows.
    let brow = C(0x2E5A22), eye = C(0xFFE23A)
    c.pattern(21, 27, ["BB.......BB", ".BB.....BB."], ["B": brow])
    c.rect(21, 29, 4, 2, eye); c.rect(30, 29, 4, 2, eye)
    c.px(23, 29, ink); c.px(32, 29, ink)
    // The grin: wider and open while he cackles.
    let gape = Int((laugh * 2).rounded())
    c.rect(22, 32, 12, 1 + gape, C(0x3A1020))
    for x in stride(from: 22, to: 34, by: 2) { c.px(x, 32, white) }
    if gape > 0 { for x in stride(from: 23, to: 34, by: 2) { c.px(x, 32 + gape, white) } }
    c.px(21, 31, C(0x3A1020)); c.px(34, 31, C(0x3A1020))
    // The pumpkin bomb: gone from the hand for a moment after each throw, juggled while he laughs.
    var thrown = false
    if let fire = p.fire { thrown = frac(fire.t / blasterPeriod) < 0.25 }
    c.oy += p.gunY
    if thrown {
        c.rect(38, 27, 3, 3, purple)                       // the arm up, mid-throw
    } else {
        let toss = laugh > 0 ? -Int((abs(sin((p.signature ?? 0) * .pi * 6)) * 7 * laugh).rounded()) : 0
        if toss < -1 { c.rect(38, 31, 3, 3, purple) }
        drawPumpkin(c, x: 39, y: 27 + toss)
    }
    c.oy -= p.gunY
    if laugh > 0.6, let s = p.signature {
        for (i, ch) in ["H", "A", "H", "A"].enumerated() {      // the cackle rising off him
            let f = frac(s * 2.2 - Double(i) * 0.12)
            let a = f < 0.8 ? 1 : (1 - f) / 0.2
            glyph(c, Character(ch), 33 + i * 4, 18 - Int(f * 8) + (i % 2), C(0xC8F07A).alpha(a))
        }
    }
}

/// A little jack-o'-lantern bomb, top-left at (`x`, `y`).
private func drawPumpkin(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [".g..", "OOOO", "OkOk", "OOOO", ".OO."],
              ["g": C(0x3A8A2A), "O": C(0xFF8A1E), "k": C(0x5A2A0A)])
}

/// The Goblin's bat-glider under his feet: dark steel bat wings with scalloped edges and yellow headlamp eyes. A jet
/// burns at the back while it flies.
private func drawGlider(_ c: PixelCanvas, t: Double, flying: Bool) {
    let steel = C(0x4A5060), light = C(0x7A8292), dark = C(0x2E323C)
    c.pattern(8, 38, [
        "LL.......................................",
        ".SSL...................................LL",
        "..SSSLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLSS.",
        "...SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSYS",
        "....DDD.DDDD.DDDD.DDDD.DDDD.DDDD.DDDDD...",
    ], ["S": steel, "L": light, "D": dark, "Y": C(0xFFE23A)])
    c.pattern(48, 40, ["SS", "S."], ["S": steel])
    if flying {
        let len = 3 + Int(noise(Int(t * 30)) * 3)
        c.rect(10 - len, 40, len, 2, C(0xFF9A2A))
        c.rect(11 - len, 40, max(1, len - 2), 1, C(0xFFE27A))
    }
}

// MARK: - Venom

/// Venom: a hulking black symbiote Clawd, bigger than most, with huge jagged white eyes, a jaw full of fangs and the
/// white spider sprawled across his chest. He fights with symbiote claws. Signature: his long tongue lolls out and
/// waggles.
private func drawVenom(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x14141C), sheen = C(0x34405E), white = C(0xF4F4F8), maw = C(0x4A0A14), tongue = C(0xE0506A)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    // Bigger and broader than Clawd.
    c.rect(16, 23, 24, 15, black)
    c.rect(17, 22, 22, 1, black)
    c.rect(18, 23, 8, 1, sheen); c.rect(17, 24, 1, 5, sheen)
    c.rect(13, 32, 3, 4, black)                                   // back arm
    // The eyes, slanting down to the middle.
    c.pattern(18, 24, ["WWWWW...........WWWWW.", ".WWWWWW.......WWWWWW..", "..WWWWW.......WWWWW...", "...WWW.........WWW...."],
              ["W": white])
    // The spider on his chest, its legs reaching round the sides.
    c.pattern(18, 33, ["WWW....W.WW.W....WWW", "...WWW..WWWW..WWW...", "......WWWWWWWW......", "...WWW..WWWW..WWW...",
                       "WWW......WW......WWW"], ["W": white])
    // The maw: fangs top and bottom.
    let loll = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    c.rect(20, 29, 18, 4, maw)
    c.px(19, 28, maw); c.px(38, 28, maw)
    for x in stride(from: 20, to: 38, by: 2) { c.px(x, 29, white); c.px(x + 1, 32, white) }
    for x in stride(from: 22, to: 38, by: 4) { c.px(x, 30, white); c.px(x + 1, 31, white) }
    // The tongue: a little lick at rest, a long waggling loll for the signature.
    let wag = sin((p.signature ?? p.lt) * (p.signature == nil ? 1.5 : 30))
    if loll > 0.05 {
        tentacle(c, from: (34, 32), angle: 60 - 40 * loll, bend: 80 * loll + 30 * wag * loll, length: 4 + 10 * loll,
                 tongue, r0: 1.1, r1: 0.8)
    } else {
        c.rect(33, 31, 3, 2, tongue)
    }
    // Symbiote claws: the arm stretches out into a tendril with three white talons.
    if let a = p.melee {
        let r = a * .pi / 180, hx = Sprite.hand.x, hy = Sprite.hand.y
        for (i, ta) in p.trail.enumerated() {
            let tr = ta * .pi / 180
            bar(c, hx + cos(tr) * 4, hy + sin(tr) * 4, hx + cos(tr) * 13, hy + sin(tr) * 13, sheen.alpha(0.4 / Double(i + 1)), r: 1.4)
        }
        bar(c, hx - 3, hy, hx + cos(r) * 10, hy + sin(r) * 10, black, r: 1.6)
        claws(c, hx + cos(r) * 10, hy + sin(r) * 10, angle: a, spread: 30, length: 5, white)
    } else {
        c.rect(40, 32, 3, 4, black)
        claws(c, 41.5, 36, angle: 90, spread: 30, length: 3, white)
    }
}

// MARK: - Carnage

/// Carnage: a blood-red symbiote Clawd marbled with black, jagged white eyes and a needle-toothed grin, tendrils
/// curling off his back, his arm grown into a hooked blade. Signature: the tendrils whip around him in a frenzy.
private func drawCarnage(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC81A1E), dark = C(0x7A0A10), black = C(0x16141A), white = C(0xF6F2F2)
    let frenzy = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    // Tendrils off the back: lazy curls, a whipping frenzy for the signature.
    let speed = 1.6 + 14 * frenzy
    let n = frenzy > 0.3 ? 6 : 4
    for k in 0..<n {
        let ph = Double(k) * 1.9
        let base = -178 + Double(k) * 100 / Double(n - 1) + 25 * frenzy * sin(p.lt * speed * 0.7 + ph)
        tentacle(c, from: (20 + Double(k % 2) * 3, 28 - Double(k % 3)), angle: base, bend: 170 * sin(p.lt * speed + ph),
                 length: 11 + 6 * frenzy + Double(k % 2) * 2, k % 3 == 2 ? black : (k % 2 == 0 ? red : dark), r0: 0.9, r1: 0.4)
    }
    drawLegs(c, Look(leg: red), step: p.step)
    for lx in [19, 23, 31, 35] { c.px(lx, 39, black); c.px(lx + 1, 41, black) }
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: dark, arm: red, eye: nil))
    // Black swirls through the red.
    c.pattern(18, 26, [
        "K....KK........K....",
        "KK.....K......K.....",
        ".K..............KK..",
        "......K.........K..K",
        "...................K",
        "K..............K....",
        "KK...........KK.....",
        ".KK....K..K.........",
        "..K...KK..KK......K.",
        "........K.......KKK.",
        "K.....KK....K.......",
        "KK..KK.......KK..KKK",
    ], ["K": black])
    // Eyes, thinner and more jagged than Venom's.
    c.pattern(19, 26, ["WWWW.............WWW", ".WWWWW........WWWWW.", "...WWW........WWW...", "....W..........W...."],
                  ["W": white])
    // Grin: a wide red slash of needle teeth.
    c.rect(21, 31, 16, 3, black)
    for x in stride(from: 21, to: 37, by: 2) { c.px(x, 31, white); c.px(x + 1, 33, white) }
    c.px(20, 30, black); c.px(37, 30, black)
    // The blade arm: red, black-edged, hooked at the tip.
    let a = p.melee ?? 70, r = a * .pi / 180, ux = cos(r), uy = sin(r)
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    for (i, ta) in p.trail.enumerated() {
        let tr = ta * .pi / 180
        bar(c, hx + cos(tr) * 4, hy + sin(tr) * 4, hx + cos(tr) * 15, hy + sin(tr) * 15, red.alpha(0.35 / Double(i + 1)), r: 1.4)
    }
    let len = p.melee == nil ? 8.0 : 15
    bar(c, hx - 2 * ux, hy - 2 * uy, hx + ux * len, hy + uy * len, red, r: 1.2)
    bar(c, hx + ux * 3 - uy, hy + uy * 3 + ux, hx + ux * len - uy, hy + uy * len + ux, black, r: 0.4)
    let tip = (x: hx + ux * len, y: hy + uy * len)
    bar(c, tip.x, tip.y, tip.x - ux * 3 + uy * 3, tip.y - uy * 3 - ux * 3, red, r: 0.6)     // the hook
}

// MARK: - Doctor Octopus

/// Where Doc Ock's fighting arm comes over his shoulder from the harness: it swings from here (the fight effects use it).
private let ockShoulder = (x: 32.0, y: 27.0)
/// The harness on his back, where the other three tentacles come from.
private let ockHarness = (x: 22.0, y: 28.0)

/// Doctor Octopus: Clawd with the black bowl cut and round dark glasses, in the green jumpsuit with yellow gloves and
/// belt, four steel tentacles on a harness at his back. He fights with the front tentacle; the other three keep
/// waving. Signature: all four rear up and snap their claws.
private func drawDocOck(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3E7A3A), suitDark = C(0x2C5A2A), skin = C(0xE8B890), yellow = C(0xE8C02A), hair = C(0x1E1A18)
    let metal = C(0x8A909C), joint = C(0x5A606C)
    let snap = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    let s = p.signature ?? 0
    // The three spare tentacles, waving behind him.
    for k in 0..<3 {
        let ph = Double(k) * 2.1, speed = 1.2 + 6 * snap
        let base = [-170.0, -130, 160][k] + 18 * sin(p.lt * speed + ph) + snap * [40.0, 30, -60][k]
        let end = tentacle(c, from: ockHarness, angle: base, bend: 70 * sin(p.lt * speed * 0.8 + ph + 1),
                           length: 17 + Double(k) * 2, metal, joint: joint, r0: 1.3, r1: 1.0)
        let open = snap > 0 ? (frac(s * 8 + Double(k) * 0.3) < 0.5 ? 1.0 : 0) : 0.3
        ockClaw(c, end, open: open)
    }
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 42, 2, 2, yellow) } }
    c.oy += p.breathe
    // The fighting tentacle, from the same harness.
    let a = p.melee ?? (-40 + 10 * sin(p.lt * 1.4) - 50 * snap)
    for (i, ta) in p.trail.enumerated() {
        let tr = ta * .pi / 180
        bar(c, ockShoulder.x + cos(tr) * 8, ockShoulder.y + sin(tr) * 8, ockShoulder.x + cos(tr) * 22,
            ockShoulder.y + sin(tr) * 22, C(0xC8CCD4, 0.35 / Double(i + 1)), r: 1.3)
    }
    let end = tentacle(c, from: ockShoulder, angle: a, bend: p.melee == nil ? 30 : 8, length: 21, metal, joint: joint,
                       r0: 1.4, r1: 1.1)
    ockClaw(c, end, open: p.melee != nil ? 0.8 : (snap > 0 ? (frac(s * 8) < 0.5 ? 1 : 0) : 0.3))
    drawBody(c, Look(body: suit, shade: suitDark, arm: yellow, eye: nil))
    c.rect(18, 26, 20, 7, skin)
    c.rect(37, 26, 1, 7, C(0xC8987A))
    c.rect(18, 35, 20, 1, yellow)                                  // belt
    c.rect(26, 35, 4, 1, C(0xB08A1A))
    // Bowl cut.
    c.pattern(17, 22, [
        "....HHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHH",
        "HHHH...........HHHH.",
        "HHH.................",
    ], ["H": hair])
    // Round dark glasses.
    let lens = C(0x22262E), rim = C(0x6A707C)
    c.pattern(20, 28, [".rrr.....rrr.", "rLLLr...rLLLr", "rLlLrrrrrLlLr", ".rrr.....rrr."], ["r": rim, "L": lens, "l": C(0x4A7A8A)])
    c.rect(26, 33, 4, 1, C(0xA0705A))                              // a thin frown
}

/// A tentacle's three-pronged claw at the end of a tentacle, `open` 0…1.
private func ockClaw(_ c: PixelCanvas, _ end: (x: Double, y: Double, a: Double), open: Double) {
    c.rect(Int(end.x) - 1, Int(end.y) - 1, 3, 3, C(0x5A606C))
    claws(c, end.x, end.y, angle: end.a, spread: 22 + 22 * open, length: 3.5, C(0xB4BAC6))
    c.px(Int(end.x), Int(end.y), C(0xFF4A3A))
}

// MARK: - Mysterio

/// Mysterio: Clawd in the green scale-mail suit and purple cape, his head inside the famous glass fishbowl dome, held
/// by a gold collar with the eye-shaped clasps. He casts green mist from his raised hand. Signature: the fishbowl fills
/// with swirling green smoke, then clears.
private func drawMysterio(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3A8A4A), suitDark = C(0x2A6A38), gold = C(0xE0B83A), cape = C(0x5A2A86), capeEdge = C(0x7A44A8)
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: cape, edge: capeEdge)
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 41, 2, 3, C(0x5A2A86)) } }
    c.oy += p.breathe
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: C(0x5A2A86)), armRight: p.armRaise)
    // Scale-mail suit below the collar.
    c.rect(18, 32, 20, 6, suit)
    for y in [33, 35] { for x in stride(from: 19 + (y / 2) % 2 * 2, to: 37, by: 4) { c.px(x, y, suitDark); c.px(x + 1, y + 1, suitDark) } }
    c.rect(18, 37, 20, 1, suitDark)
    // The fishbowl: tinted glass round the head, a rim of light, smoke curling inside.
    let fog = p.signature.map { habitArc($0, hold: 0.45) } ?? 0
    c.ellipse(28, 24, 12, 9, C(0xBFF0FF, 0.16))
    for i in 0..<3 {                                              // wisps of mist drifting in the dome
        let x = 22 + i * 5 + Int(sin(p.lt * 1.3 + Double(i)) * 2), y = 19 + i % 2 * 2 + Int(cos(p.lt * 1.1 + Double(i) * 2) * 1.5)
        c.rect(x - 2, y, 5, 1, C(0x9AF0BA, 0.35)); c.rect(x - 1, y - 1, 2, 1, C(0x9AF0BA, 0.25))
    }
    if fog > 0 {
        for i in 0..<12 {                                         // the dome fills from the bottom up
            let sw = p.lt * 2.4 + Double(i) * 0.9
            let x = 28 + Int(cos(sw) * Double(8 - i % 3)), y = 32 - Int(Double(i % 6) * 2.4 * fog) - 2
            c.circle(x, y, 2 + i % 2, C(0x4AE08A, 0.45 * fog))
        }
        c.ellipse(28, 24, 11, 8, C(0x6AE89A, 0.35 * fog))
    }
    let rim = C(0xE4F8FF, 0.75)
    for k in 0..<64 {
        let a = Double(k) / 64 * 2 * .pi
        c.px(28 + Int((cos(a) * 12.4).rounded()), 24 + Int((sin(a) * 9.4).rounded()), rim)
    }
    c.rect(20, 17, 2, 1, white); c.px(19, 18, white); c.px(19, 19, white.alpha(0.7))   // a highlight
    // The collar and its eye clasps.
    c.rect(16, 32, 25, 2, gold)
    c.rect(16, 33, 25, 1, C(0xB08A1A))
    for x in [17, 36] { c.pattern(x, 31, [".WW.", "WEEW", ".WW."], ["W": white, "E": C(0x2A2A30)]) }
}

// MARK: - Electro

/// Electro: Clawd in the green suit with the yellow lightning bolt across the chest, yellow gloves and boots, and the
/// yellow lightning-star mask whose jagged points shoot up round his head. He throws lightning from his raised hand.
/// Signature: he crackles all over with sparks, the mask's points flaring white-hot.
private func drawElectro(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A9A3A), greenDark = C(0x2A7A2A), yellow = C(0xFFD82A), yellowDark = C(0xD8A81A)
    let flare = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 40, 2, 4, yellow) } }
    c.oy += p.breathe
    // The star mask's points, behind the head.
    // Each point is a little lightning bolt: from the mask's edge, a zig, a zag, out to a sharp tip.
    let points: [(sx: Double, sy: Double, ex: Double, ey: Double)] = [
        (19, 28, 10, 22), (21, 26, 15, 13), (28, 26, 28, 9), (35, 26, 41, 13), (37, 28, 46, 22),
    ]
    let ray = flare > 0.5 && Int(p.lt * 20) % 2 == 0 ? C(0xFFFFE8) : yellow
    let reach = 1 + flare * 0.25
    for pt in points {
        let ex = 28 + (pt.ex - 28) * reach, ey = 28 + (pt.ey - 28) * reach
        let dx = ex - pt.sx, dy = ey - pt.sy, len = max(hypot(dx, dy), 0.01)
        let nx = -dy / len * 2, ny = dx / len * 2
        let k1 = (pt.sx + dx * 0.4 + nx, pt.sy + dy * 0.4 + ny), k2 = (pt.sx + dx * 0.6 - nx, pt.sy + dy * 0.6 - ny)
        if flare > 0 { c.glowLine(k2.0, k2.1, ex, ey, core: ray, glow: C(0xFFE01E, 0.6 * flare), coreR: 0.5, glowR: 2) }
        bar(c, pt.sx, pt.sy, k1.0, k1.1, ray, r: 1.3)
        bar(c, k1.0, k1.1, k2.0, k2.1, ray, r: 0.9)
        bar(c, k2.0, k2.1, ex, ey, ray, r: 0.5)
    }
    drawBody(c, Look(body: green, shade: greenDark, arm: yellow, eye: nil), armRight: p.armRaise)
    // Mask over the face.
    c.rect(18, 26, 20, 6, yellow)
    c.rect(18, 31, 20, 1, yellowDark)
    c.rect(21, 28, 3, 2, ink); c.rect(31, 28, 3, 2, ink)
    // The bolt across the chest.
    c.pattern(18, 32, ["YY.......YY.........", ".YYY...YYYYY....YY..", "...YYYYY...YYYYYY...", "....YY.......YY....."],
              ["Y": yellow])
    if flare > 0.2 {                                              // sparks crackling all over him
        for i in 0..<3 {
            let a = noise(Int(p.lt * 12) + i * 5) * 2 * .pi, r = 10 + noise(Int(p.lt * 12) + i * 9) * 4
            drawSparks(c, x: 28 + cos(a) * r, y: 29 + sin(a) * r * 0.8, t: p.lt + Double(i), size: 2)
        }
    }
}

// MARK: - Vulture

/// Vulture: the bald, hook-nosed old Clawd in the green flight suit with the white feather ruff, big green feathered
/// wings on his back: folded while he walks, spread and flapping in flight. He fights with his talons. Signature: he
/// spreads his wings wide and gives them a shake.
private func drawVulture(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3A7A3A), suitDark = C(0x2A5A2A), skin = C(0xD8C0A0), skinShade = C(0xB89C7C)
    let spreadSig = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    var spread = spreadSig
    if p.flying { spread = 0.75 + 0.25 * sin(p.t * 9) }
    if p.flying { c.oy += sin(p.t * 9) > 0 ? 0 : -1 }
    drawWing(c, spread: spread, shake: p.signature != nil && spreadSig > 0.9 ? sin(p.lt * 40) : 0, far: true)
    if p.flying {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx - 2 + i / 2, 36, 2, 6, suit) }   // legs trailing
    } else {
        drawLegs(c, Look(leg: suit), step: p.step)
    }
    c.oy += p.breathe
    drawWing(c, spread: spread, shake: 0, far: false)
    drawBody(c, Look(body: suit, shade: suitDark, arm: suit, eye: nil))
    // Old bald head: the top of the body is his face.
    c.rect(18, 26, 20, 6, skin)
    c.pattern(19, 21, ["......SSSSSS......", "...SSSSSSSSSSSS...", ".SSSSSSSSSSSSSSSS.", "SSSSSSSSSSSSSSSSSS", "SSSSSSSSSSSSSSSSSS"],
              ["S": skin])
    c.rect(18, 26, 2, 3, skinShade)
    c.px(23, 23, skinShade); c.px(29, 22, skinShade); c.px(26, 24, skinShade)   // wrinkles on the bald dome
    c.rect(22, 28, 2, 2, ink); c.rect(31, 28, 2, 2, ink)
    c.rect(21, 27, 3, 1, C(0x8A7A6A)); c.rect(30, 27, 4, 1, C(0x8A7A6A))   // a scowl
    // The great hooked beak of a nose.
    c.pattern(34, 27, ["SSSS...", "SSSSSS.", "SSSSSSS", "...SSSS", ".....S."], ["S": skinShade])
    // The feather ruff round his neck.
    c.pattern(16, 31, ["WWWWWWWWWWWWWWWWWWWWWWW", ".W.WW.WW.WWW.WW.WW.WW.W"], ["W": C(0xF0EEE6)])
    // Talons: a slash from the hand when fighting, curled at his side otherwise.
    let talon = C(0xE8DCC0)
    if let a = p.melee {
        let r = a * .pi / 180, hx = Sprite.hand.x, hy = Sprite.hand.y
        for (i, ta) in p.trail.enumerated() {
            let tr = ta * .pi / 180
            for k in -1...1 {
                bar(c, hx + cos(tr) * 4, hy + sin(tr) * 4 + Double(k) * 2, hx + cos(tr) * 10, hy + sin(tr) * 10 + Double(k) * 2,
                    talon.alpha(0.3 / Double(i + 1)), r: 0.4)
            }
        }
        bar(c, hx - 2, hy, hx + cos(r) * 5, hy + sin(r) * 5, suit, r: 1.4)
        claws(c, hx + cos(r) * 5, hy + sin(r) * 5, angle: a, spread: 30, length: 5, talon)
    } else {
        claws(c, 41, 35, angle: 80, spread: 30, length: 2.5, talon)
    }
}

/// Vulture's wing, feathers fanning from his shoulder: folded down his back (`spread` 0) to fully spread (1).
/// `far`: the wing on the far side, darker and a little behind.
private func drawWing(_ c: PixelCanvas, spread: Double, shake: Double, far: Bool) {
    let green = far ? C(0x2A5A2A) : C(0x4A9A4A), tip = far ? C(0x3A6A3A) : C(0x7ACA6A), edge = far ? C(0x3A6A3A) : C(0x6AB85A)
    let under = far ? C(0x1E441E) : C(0x2E6A2E)
    let root = (x: far ? 25.0 : 22.0, y: 29.0)
    func dir(_ deg: Double) -> (x: Double, y: Double) { (cos(deg * .pi / 180), sin(deg * .pi / 180)) }
    // The arm of the wing: shoulder to wrist, wrist to tip. Folded it lies down his back; spread it sweeps up and back.
    let arm = 140 + (-110 - 140) * spread + shake * 5 + (far ? 10 : 0), hand = arm - 40 * spread
    let wrist = (x: root.x + dir(arm).x * (5 + 5 * spread), y: root.y + dir(arm).y * (5 + 5 * spread))
    let tipPt = (x: wrist.x + dir(hand).x * (4 + 5 * spread), y: wrist.y + dir(hand).y * (4 + 5 * spread))
    // Feathers hang back off the arm, longest at the tip: a dark underside packed solid, the feathers laid over it.
    func feather(_ f: Double) -> (from: (x: Double, y: Double), to: (x: Double, y: Double)) {
        let g = f < 0.5 ? f * 2 : (f - 0.5) * 2
        let from = f < 0.5 ? (x: root.x + (wrist.x - root.x) * g, y: root.y + (wrist.y - root.y) * g)
                           : (x: wrist.x + (tipPt.x - wrist.x) * g, y: wrist.y + (tipPt.y - wrist.y) * g)
        let u = dir((arm + 15) * (1 - spread) + (165 + 30 * f) * spread), len = 5 + (3 + 8 * f) * spread
        return (from, (from.x + u.x * len, from.y + u.y * len))
    }
    for k in 0...24 {
        let fe = feather(Double(k) / 24)
        bar(c, fe.from.x, fe.from.y, fe.to.x - (fe.to.x - fe.from.x) * 0.12, fe.to.y - (fe.to.y - fe.from.y) * 0.12, under, r: 0.8)
    }
    for k in 0..<7 {
        let fe = feather(Double(k) / 6)
        bar(c, fe.from.x, fe.from.y, fe.to.x, fe.to.y, green, r: 0.7)
        bar(c, fe.to.x + (fe.from.x - fe.to.x) * 0.2, fe.to.y + (fe.from.y - fe.to.y) * 0.2, fe.to.x, fe.to.y, tip, r: 0.6)
    }
    bar(c, root.x, root.y, wrist.x, wrist.y, edge, r: 1.2)
    bar(c, wrist.x, wrist.y, tipPt.x, tipPt.y, edge, r: 0.9)
}

// MARK: - Rhino

/// Where Rhino's punching arm hangs from (the fight effects use it too).
private let rhinoShoulder = (x: 39.5, y: 31.5)

/// Rhino: a big, broad Clawd in grey rhino-hide armour, only his scowling face showing, a great curved horn and a
/// smaller one up on the brow. He fights with his fists; too heavy to sit. Signature: he paws the ground and snorts,
/// ready to charge.
private func drawRhino(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0x8A8C94), dark = C(0x5E6068), light = C(0xAEB0B8), horn = C(0xE8E0CC), hornShade = C(0xB8B09A)
    let charge = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    let paw = charge > 0.5 ? Int(frac((p.signature ?? 0) * 6) * 4) % 4 : -1
    // Thick legs; the front one scrapes back and forth while he paws.
    for (i, lx) in [17, 23, 30, 36].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        var x = lx, up = lifted ? 1 : 0
        if i == 3 && paw >= 0 { x += [0, -2, -3, -1][paw]; up = paw == 0 ? 0 : 1 }
        c.rect(x, 35, 4, 9 - up, hide)
        c.rect(x, 42 - up, 4, 2, dark)
    }
    if paw == 2 { for k in 0..<3 { c.px(41 + k * 2, 42 - k, C(0xA88A5A)) } }   // kicked-up dirt
    c.oy += p.breathe + (charge > 0.3 ? 1 : 0)
    // The hulking body.
    c.rect(15, 22, 26, 16, hide)
    c.rect(16, 21, 22, 1, hide)
    c.rect(15, 37, 26, 1, dark); c.rect(40, 22, 1, 16, dark)
    c.rect(17, 22, 10, 1, light)
    for y in [27, 32] { c.rect(15, y, 10, 1, dark) }                     // hide plates on the back
    c.rect(20, 23, 1, 14, dark)
    c.rect(12, 30, 3, 5, hide)                                            // back arm
    // Face opening.
    c.rect(27, 26, 11, 7, C(0xD8A888))
    c.rect(27, 26, 11, 1, dark)
    c.rect(29, 28, 2, 2, ink); c.rect(34, 28, 2, 2, ink)
    c.rect(28, 27, 3, 1, dark); c.rect(33, 27, 3, 1, dark)                // glowering brows
    c.rect(30, 31, 6, 1, C(0x8A5A4A))
    // The horns.
    c.pattern(33, 13, [
        "........H",
        ".......HH",
        "......HHH",
        ".....HHHh",
        "....HHHh.",
        "...HHHHh.",
        "..HHHHhh.",
        ".HHHHHh..",
        "HHHHHHh..",
        "hhhhhh...",
    ], ["H": horn, "h": hornShade])
    c.pattern(26, 18, ["..H", ".HH", "HHh", "hh."], ["H": horn, "h": hornShade])
    // The fist: hangs at his side, punches out along the swing.
    let a = p.melee ?? 80, r = a * .pi / 180, sx = rhinoShoulder.x, sy = rhinoShoulder.y
    let len = p.melee == nil ? 5.0 : 10
    for (i, ta) in p.trail.enumerated() {
        let tr = ta * .pi / 180
        c.circle(Int(sx + cos(tr) * len), Int(sy + sin(tr) * len), 2, hide.alpha(0.3 / Double(i + 1)))
    }
    bar(c, sx, sy, sx + cos(r) * len, sy + sin(r) * len, hide, r: 1.8)
    let fx = Int((sx + cos(r) * len).rounded()), fy = Int((sy + sin(r) * len).rounded())
    c.circle(fx, fy, 2, hide)
    c.px(fx + Int((cos(r) * 2).rounded()), fy + Int((sin(r) * 2).rounded()), dark)   // knuckles
    c.px(fx + Int((cos(r) * 2 - sin(r)).rounded()), fy + Int((sin(r) * 2 + cos(r)).rounded()), dark)
    if charge > 0.4, let s = p.signature {                               // the snort: steam blasting from his nose
        for i in 0..<2 {
            let f = frac(s * 3 + Double(i) * 0.5)
            c.circle(39 + Int(f * 9), 30 - Int(f * 2), 1 + Int(f * 2.5), white.alpha(1 - f * 0.6))
        }
    }
}

// MARK: - Sandman

/// Sandman: a flat-topped, square-jawed Clawd in the green-and-black zigzag shirt and brown slacks, sandy skin. In a
/// fight his fist swells into a great sand mallet. Signature: he crumbles into a heap of sand, then rises out of it.
private func drawSandman(_ c: PixelCanvas, _ p: Pose) {
    let melt = p.signature.map { habitArc($0, hold: 0.2) } ?? 0
    guard melt > 0 else { drawSandmanFigure(c, p); return }
    // Draw him off to the side, then let the top of him pour away into a heap.
    let tmp = PixelCanvas(c.w, c.h)
    tmp.ox = c.ox; tmp.oy = c.oy; tmp.baseY = c.baseY
    drawSandmanFigure(tmp, p)
    // He slumps down into himself, turning to sand as he goes.
    let sand = C(0xD8B878), sandDark = C(0xB0905A)
    let k = max(0.08, 1 - melt * 0.92)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    for y in 0..<44 {
        let sy = 43 - Int((Double(43 - y) / k).rounded())
        guard sy >= 0 else { continue }
        for x in 0..<tmp.w where tmp.isDrawn(x, sy) {
            let i = (sy * tmp.w + x) * 4
            let col = Px(r: tmp.buf[i], g: tmp.buf[i + 1], b: tmp.buf[i + 2], a: tmp.buf[i + 3])
            c.px(x, y, noise(x * 31 + sy * 7) < melt ? (noise(x + sy) > 0.5 ? sand : sandDark) : col)
        }
    }
    c.ox = ox; c.oy = oy; c.baseY = by
    let cut = 43 - Int(24 * k)
    // Grains streaming down from the crumbling edge.
    let s = p.signature ?? 0
    for i in 0..<14 {
        let f = frac(s * 5 + noise(i) ), x = 19 + Int(noise(i + 40) * 19), y = cut + Int(f * Double(43 - cut))
        if y < 44 { c.px(x, y, noise(i + 3) > 0.5 ? sand : sandDark) }
    }
    // The heap.
    let h = melt * 7
    for dy in 0..<Int(h.rounded()) {
        let w = Int((15 * (1 - Double(dy) / max(h, 1) * 0.7)).rounded())
        c.rect(28 - w, 43 - dy, w * 2, 1, dy % 2 == 0 ? sand : sandDark)
    }
}

private func drawSandmanFigure(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD8B080), sand = C(0xD8B878), sandDark = C(0xB0905A)
    let green = C(0x3A9A4A), black = C(0x1A1A1E), slacks = C(0x6A4A2E)
    drawLegs(c, Look(leg: slacks), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: C(0x2A7A3A), arm: skin, eye: nil))
    // Face and flat-top hair.
    c.rect(18, 26, 20, 6, skin)
    c.rect(37, 26, 1, 6, C(0xB89060))
    c.rect(18, 23, 20, 4, C(0x4A3020))
    c.rect(18, 22, 19, 1, C(0x4A3020))
    c.rect(22, 28, 2, 2, ink); c.rect(32, 28, 2, 2, ink)
    c.rect(29, 30, 6, 1, C(0xA0784A))
    // The zigzag stripes.
    for y in [33, 36] {
        for x in 18...37 { if (x + y) % 4 < 2 { c.px(x, y, black) } else { c.px(x, y - 1, black) } }
    }
    c.rect(18, 37, 20, 1, slacks)
    // The fist, swelling into a sand mallet when he swings.
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    guard let a = p.melee else {
        c.px(39, 35, sandDark); c.px(40, 33, sandDark)
        return
    }
    let r = a * .pi / 180, ux = cos(r), uy = sin(r)
    for (i, ta) in p.trail.enumerated() {
        let tr = ta * .pi / 180
        c.circle(Int(hx + cos(tr) * 14), Int(hy + sin(tr) * 14), 3, sand.alpha(0.3 / Double(i + 1)))
    }
    bar(c, hx - ux, hy - uy, hx + ux * 11, hy + uy * 11, sand, r: 1.3)
    // The mallet head across the end of the arm.
    let mx = hx + ux * 14, my = hy + uy * 14
    bar(c, mx - uy * 4, my + ux * 4, mx + uy * 4, my - ux * 4, sand, r: 2.8)
    for k in 0..<6 {                                                          // grainy, crumbling edges
        let g = Double(k) - 2.5
        c.px(Int(mx + uy * g * 1.4 + ux * 3), Int(my - ux * g * 1.4 + uy * 3), sandDark)
    }
    c.px(Int(mx - uy * 2), Int(my + ux * 2), sandDark)
}

// MARK: - Lizard

/// The Lizard: a green scaly Clawd with a long toothy snout and yellow slit eyes, still in Dr. Connors' white lab coat
/// over a purple shirt and slacks, a thick tail behind. He fights with his claws. Signature: the tail swishes hard and
/// he hisses, forked tongue flicking.
private func drawLizard(_ c: PixelCanvas, _ p: Pose) {
    let scales = C(0x4A9A3A), scalesDark = C(0x2E7028), belly = C(0xC8D87A), coat = C(0xF0F0F4), coatShade = C(0xC0C4CC)
    let purple = C(0x5A3A8A)
    let hiss = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    // The tail, swishing behind him.
    let swish = sin(p.lt * (1.8 + 10 * hiss)) * (12 + 18 * hiss)
    tentacle(c, from: (20, 34), angle: p.seated ? 178 : 165, bend: (p.seated ? 30 : -40) + swish, length: 16, scales, r0: 2.2, r1: 0.6)
    drawLegs(c, Look(leg: purple), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 42, 2, 2, scales); c.px(lx + 2, 43, scales) } }
    c.oy += p.breathe
    drawBody(c, Look(body: scales, shade: scalesDark, arm: coat, eye: nil))
    for (x, y) in [(20, 27), (25, 26), (29, 27), (23, 30), (34, 27), (19, 31)] { c.px(x, y, scalesDark) }   // scales
    // The snout, jaws parted when he hisses.
    let gape = Int((hiss * 2).rounded())
    c.pattern(34, 27, ["SSSSSSSs.", "SSSSSSSSs", "SSSSSSSSS"], ["S": scales, "s": scalesDark])
    c.rect(36, 30, 9, 1, C(0x4A1A1A))
    for x in stride(from: 36, to: 45, by: 2) { c.px(x, 30, white) }
    c.pattern(34, 31 + gape, ["SSSSSSSs", "BBBBBBB."], ["S": scales, "s": scalesDark, "B": belly])
    if gape > 0 { c.rect(36, 31, 8, gape, C(0x4A1A1A)) }
    c.px(42, 27, scalesDark)                                                // nostril
    if hiss > 0.5, let s = p.signature, frac(s * 6) < 0.6 {
        c.rect(45, 30 + gape / 2, 3, 1, C(0xE0506A))
        c.px(48, 29 + gape / 2, C(0xE0506A)); c.px(48, 31 + gape / 2, C(0xE0506A))
    }
    // Yellow slit eyes under a heavy brow.
    c.rect(29, 27, 4, 2, C(0xFFD23A)); c.px(31, 27, ink); c.px(31, 28, ink)
    c.rect(28, 26, 6, 1, scalesDark)
    // The lab coat, purple shirt showing.
    c.rect(18, 32, 20, 6, coat)
    c.rect(18, 37, 20, 1, coatShade)
    c.pattern(24, 32, ["PPPPPP", ".PPPP.", "..PP.."], ["P": purple])
    c.px(23, 32, coatShade); c.px(30, 32, coatShade)
    c.rect(17, 35, 1, 5, coat); c.rect(17, 39, 2, 1, coatShade)              // the coat tail flapping behind
    // Claws.
    let talon = C(0xF0E8C8)
    if let a = p.melee {
        let r = a * .pi / 180, hx = Sprite.hand.x, hy = Sprite.hand.y
        for (i, ta) in p.trail.enumerated() {
            let tr = ta * .pi / 180
            for k in -1...1 {
                bar(c, hx + cos(tr) * 4, hy + sin(tr) * 4 + Double(k) * 2, hx + cos(tr) * 10, hy + sin(tr) * 10 + Double(k) * 2,
                    talon.alpha(0.3 / Double(i + 1)), r: 0.4)
            }
        }
        bar(c, hx - 2, hy, hx + cos(r) * 5, hy + sin(r) * 5, scales, r: 1.4)
        claws(c, hx + cos(r) * 5, hy + sin(r) * 5, angle: a, spread: 30, length: 4.5, talon)
    } else {
        c.rect(39, 35, 2, 1, scales)
        claws(c, 40, 36, angle: 80, spread: 30, length: 2.5, talon)
    }
}

// MARK: - Kraven

/// Kraven the Hunter: Clawd with long black hair and a pointed goatee, bare-armed in the lion's-head vest with its
/// shaggy golden mane, leopard-print trousers, a hunting spear in hand. Signature: he throws his head back and roars,
/// the mane shaking.
private func drawKraven(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD8A070), hair = C(0x1E1814), mane = C(0xD8902A), maneDark = C(0xA8661A), hide = C(0xE8C070)
    let leopard = C(0xE8B848), spot = C(0x4A2A14)
    let roar = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: leopard), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 38 + lx % 3, spot); c.px(lx + 1, 41 - lx % 2, spot) } }
    c.oy += p.breathe
    // Long hair down his back.
    c.rect(16, 22, 6, 12, hair)
    drawBody(c, Look(body: skin, shade: C(0xB88050), arm: skin, eye: nil))
    c.pattern(17, 21, ["...HHHHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH",
                       "HHHHHHHH...........", "HHHHH................"], ["H": hair])
    c.rect(22, 28, 2, 2, ink); c.rect(31, 28, 2, 2, ink)
    c.rect(21, 27, 3, 1, hair); c.rect(30, 27, 4, 1, hair)
    // The mane collar, shaggy and shaking.
    let shake = roar > 0.5 && Int(p.lt * 24) % 2 == 0 ? 1 : 0
    for x in stride(from: 16, through: 38, by: 2) {
        let len = 3 + Int(noise(x) * 2.5)
        c.rect(x + (x % 4 == 0 ? shake : -shake), 32, 2, len, x % 4 == 0 ? mane : maneDark)
    }
    // The lion-hide vest under it, the lion's face on his chest.
    c.rect(18, 35, 20, 3, hide)
    c.rect(18, 37, 20, 1, C(0xB88A40))
    c.pattern(25, 34, ["MMMMMMM", "Mk...kM", ".M.n.M."], ["M": mane, "k": spot, "n": C(0x5A3A2A)])
    // Drooping moustache and pointed goatee; the mouth gapes when he roars.
    let gape = Int((roar * 2).rounded())
    if gape > 0 { c.rect(30, 32, 5, gape, C(0x4A1A14)) }
    c.rect(30, 31, 5, 1, hair)
    c.pattern(30, 32 + gape, [".HHH.", "..H.."], ["H": hair])
    if roar > 0.85, let s = p.signature { roarRings(c, x: 44, y: 30, p: s) }
    // The spear: shouldered upright at rest, swung in a fight.
    let a = p.melee ?? -84, r = a * .pi / 180, ux = cos(r), uy = sin(r)
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    for (i, ta) in p.trail.enumerated() {
        let tr = ta * .pi / 180
        bar(c, hx + cos(tr) * 16, hy + sin(tr) * 16, hx + cos(tr) * 21, hy + sin(tr) * 21, C(0xE4E8EE, 0.3 / Double(i + 1)), r: 1)
    }
    let back = p.seated ? 4.0 : (p.melee == nil ? 9 : 6)
    bar(c, hx - ux * back, hy - uy * back, hx + ux * 17, hy + uy * 17, C(0x7A4A22), r: 0.6)
    c.px(Int(hx + ux * 13), Int(hy + uy * 13), mane)                             // a tuft of mane tied below the head
    c.px(Int(hx + ux * 13 - uy), Int(hy + uy * 13 + ux), maneDark)
    bar(c, hx + ux * 17, hy + uy * 17, hx + ux * 22, hy + uy * 22, C(0xC9CED8), r: 1)
    bar(c, hx + ux * 22, hy + uy * 22, hx + ux * 23.5, hy + uy * 23.5, C(0xE4E8EE), r: 0.4)
    c.rect(39, 33, 3, 3, skin)                                                   // the hand round the shaft
}
