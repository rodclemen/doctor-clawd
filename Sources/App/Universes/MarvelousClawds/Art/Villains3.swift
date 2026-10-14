import Foundation

// Villains: mutants, monsters and machines.

let villains3: [MarvelVillain: Persona] = [
    .magneto: Persona(name: "Magnetto", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFE8FF), glow: C(0xC83AE0), jagged: false),
                  headTop: 17, signature: 3.2,
                  draw: drawMagneto),
    .juggernaut: Persona(name: "Juggernaught", weapon: .saber, armoured: true, canSit: false, pivot: juggernautShoulder,
                  bulk: 6, headTop: 2, signature: 3.0, callout: "I'm the Juggernaught!",
                  draw: drawJuggernaut),
    .sabretooth: Persona(name: "Sabreclawd", weapon: .saber, headTop: 19, signature: 2.6,
                  draw: drawSabretooth),
    .mystique: Persona(name: "Mistique", weapon: .saber, headTop: 21, signature: 3.4,
                  draw: drawMystique),
    .apocalypse: Persona(name: "Apoclawdlypse", weapon: .saber, armoured: true, canSit: false, pivot: apocalypseShoulder,
                  bulk: 6, headTop: 1, signature: 3.0,
                  draw: drawApocalypse),
    .sentinel: Persona(name: "Sentinal", weapon: .blaster, shot: .beam(core: C(0xFFE0E0), glow: C(0xFF3A3A)), armoured: true, canSit: false,
                  muzzle: (sentinelPalm.x + 1, sentinelPalm.y), handGun: false, headTop: 1, signature: 3.2,
                  draw: drawSentinel),
    .abomination: Persona(name: "Abominator", weapon: .saber, canSit: false, pivot: abominationShoulder,
                  bulk: 9, headTop: 1, signature: 2.8,
                  draw: drawAbomination),
    .finFangFoom: Persona(name: "Fin Fang Fume", weapon: .blaster, shot: .fire, canSit: false, muzzle: (63, 11), handGun: false,
                  headTop: 1, signature: 2.8,
                  draw: drawFinFangFoom),
    .modok: Persona(name: "MOODOK", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFF6C0), glow: C(0xFFB01E), jagged: false), canSit: false,
                  pivot: (modokEmitter.x, modokEmitter.y + 2), headTop: 3, signature: 2.8,
                  draw: drawModok),
    .dormammu: Persona(name: "Dormamoo", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFE8B0), glow: C(0xFF6A1E), jagged: false), canSit: false,
                  headTop: 12, signature: 3.0,
                  draw: drawDormammu),
    .doombot: Persona(name: "Gloombot", weapon: .blaster, shot: .energy(core: C(0xE0FFE0), glow: C(0x3AE05A)), armoured: true,
                  muzzle: (47, 34), handGun: false, headTop: 22, signature: 2.4,
                  draw: drawDoombot),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A thick limb from `s` at `angle` degrees, `len` long and `r` thick. Returns where it ends.
@discardableResult
private func limb(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ angle: Double, len: Double, r: Double,
                  _ col: Px) -> (x: Double, y: Double) {
    let a = angle * .pi / 180
    let e = (x: s.x + cos(a) * len, y: s.y + sin(a) * len)
    c.glowLine(s.x, s.y, e.x, e.y, core: col, glow: clear, coreR: r, glowR: r + 0.1)
    return e
}

/// The smear a fast swing leaves behind: faint arcs at the earlier angles, out to `len` from `s`.
private func smear(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ trail: [Double], len: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * len * 0.5, s.y + sin(r) * len * 0.5, s.x + cos(r) * len, s.y + sin(r) * len,
                   core: col, glow: col, coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
}

/// `n` claws fanning out from `e` along `angle`, each `len` long.
private func claws(_ c: PixelCanvas, _ e: (x: Double, y: Double), _ angle: Double, len: Double, n: Int = 3,
                   spread: Double = 0.35, _ col: Px = C(0xF2ECDC)) {
    let r = angle * .pi / 180
    for k in 0..<n {
        let a = r + (Double(k) - Double(n - 1) / 2) * spread
        c.glowLine(e.x + cos(a), e.y + sin(a), e.x + cos(a) * (len + 1), e.y + sin(a) * (len + 1), core: col, glow: clear, coreR: 0.45, glowR: 0.5)
    }
}

/// A puff of steam or smoke at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px = C(0xE8ECF0)) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2.5).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.75 * (1 - k)))
    c.circle(Int(x.rounded()) - 1, Int(y.rounded()) - 1, max(0, r - 1), white.alpha(0.5 * (1 - k)))
}

/// Draw the `a` look left of column `split` and the `b` look from it on, so one shape can sweep into another.
private func sweep(_ c: PixelCanvas, split: Int, _ a: (PixelCanvas) -> Void, _ b: (PixelCanvas) -> Void) {
    let la = PixelCanvas(c.w, c.h), lb = PixelCanvas(c.w, c.h)
    for l in [la, lb] { l.ox = c.ox; l.oy = c.oy; l.baseY = c.baseY }
    a(la); b(lb)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    for y in 0..<c.h {
        for x in 0..<c.w {
            let src = x - ox < split ? la : lb
            let i = (y * c.w + x) * 4, al = src.buf[i + 3]
            guard al > 0 else { continue }
            let m = 255 / Double(al)
            c.px(x, y, Px(r: UInt8(min(255, Double(src.buf[i]) * m)), g: UInt8(min(255, Double(src.buf[i + 1]) * m)),
                          b: UInt8(min(255, Double(src.buf[i + 2]) * m)), a: al))
        }
    }
    c.ox = ox; c.oy = oy; c.baseY = by
}

// MARK: - Magneto

/// Magneto: a red Clawd in the iconic crested red helmet (open face, cheek guards, the nose point), a red suit with
/// purple gloves, boots and a billowing purple cape; hovers on his own magnetism. Signature: he raises both hands and
/// bits of scrap metal rise off the ground and circle him, held in a violet glow, before he lets them drop.
private func drawMagneto(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC0202E), redDark = C(0x8A1420), redLight = C(0xE8505A), purple = C(0x9A3AC8), cape = C(0x4E2275), capeEdge = C(0x351658)
    let lift = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge)
    drawLegs(c, Look(leg: red), step: p.step)
    for (i, lx) in [19, 23, 31, 35].enumerated() {                      // purple boots
        c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 3, purple)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: purple), armRight: p.armRaise)
    c.rect(18, 34, 20, 4, red)
    c.rect(18, 37, 20, 1, redDark)
    c.rect(37, 34, 1, 3, redDark)
    c.rect(18, 34, 20, 1, cape)                                           // the cape's collar across the shoulders
    c.pattern(16, 17, [
        "........RRRRRRRR........",
        "......RRRRRRRRRRRR......",
        ".....RRRRRRRRRRRRRR.....",
        "....RRRRRRRRRRRRRRRR....",
        "...RRRRRRRRRRRRRRRRRR...",
        "...RRRRRRRRRRRRRRRRRR...",
        "..RRRRRRRRRRRRRRRRRRRR..",
        "..RRRRRRRRRRRRRRRRRRRR..",
        ".RRRRRRRRRRRRRRRRRRRRRR.",
        ".RRRRRRRRRRRRRRRRRRRRRR.",
        ".RRRR..............RRRR.",
        ".RRRR..............RRRR.",
        ".RRR................RRR.",
        ".RRR................RRR.",
        ".RRRR..............RRRR.",
        "..RRR..............RRR..",
        "...RR..............RR...",
    ], ["R": red])
    c.rect(27, 18, 2, 11, redDark)                                        // the crest, down to the nose point
    c.rect(20, 26, 7, 1, redDark); c.rect(29, 26, 7, 1, redDark)          // brow ridges
    c.rect(19, 21, 1, 3, redLight); c.rect(20, 19, 2, 2, redLight)        // shine on the dome
    c.rect(38, 25, 1, 7, redDark)
    c.rect(22, 32, 12, 1, C(0xA85A40))                                    // a stern mouth
    if lift > 0.02 {                                                      // both hands raised high
        let up = Int((lift * 14).rounded())
        for (x, out) in [(14, -1), (39, 1)] {
            for k in 0...up { c.rect(x + out * (k / 5), 33 - k, 3, 1, red) }
            c.rect(x + out * (up / 5), 33 - up, 3, 3, purple)
        }
    }
    // Signature: scrap metal circles him in a magnetic field.
    if let s = p.signature, lift > 0.02 {
        let grey = C(0x9AA0AE), dark = C(0x5A5E68), glow = C(0xC83AE0)
        for i in 0..<6 {
            let a = s * 2 * .pi * 1.6 + Double(i) * .pi / 3
            let ox = 28 + cos(a) * 22, oy = 19 + sin(a) * 5
            let gx = 12 + Double(i) * 8.5, gy = 43.0                       // where it lay on the ground
            let x = Int((gx + (ox - gx) * lift).rounded()), y = Int((gy + (oy - gy) * lift).rounded())
            if sin(a) < -0.2 && lift > 0.9 { continue }                    // passing behind his head
            c.rect(x - 2, y - 2, 6, 6, glow.alpha(0.25)); c.rect(x - 1, y - 1, 4, 4, glow.alpha(0.35))
            switch i % 3 {
            case 0: c.rect(x - 1, y - 1, 3, 3, grey); c.px(x, y, dark); c.px(x - 1, y - 1, white)                         // a nut
            case 1: c.rect(x - 1, y, 4, 2, grey); c.rect(x - 1, y - 1, 2, 4, dark)           // a bolt
            default: c.rect(x - 1, y, 5, 2, dark); c.rect(x + 2, y - 2, 2, 2, grey)              // a bent strip
            }
        }
    }
}

// MARK: - The Juggernaut

/// The Juggernaut's shoulder: his fist swings from here.
private let juggernautShoulder = (x: 40.0, y: 22.0)

/// The Juggernaut: a towering rust-red bruiser with no neck, crowned by the enormous domed helmet, his face framed in
/// its opening; steel bands across his chest, four thick boots. Fights with a huge fist. Signature: he charges on the
/// spot, boots pounding, leaning in, steam snorting from the helmet's vents.
private func drawJuggernaut(_ c: PixelCanvas, _ p: Pose) {
    let rust = C(0xA8482A), rustDark = C(0x6E2A18), rustLight = C(0xD06A40), suit = C(0x6E4A2E)
    let steel = C(0x8A8E98), steelDark = C(0x5A5E68), skin = C(0xE0A07A)
    let charging = p.signature.map { $0 > 0.12 && $0 < 0.88 } ?? false
    var step = p.step
    if charging, let s = p.signature { step = Int(s * 34) % 2 }
    for (i, lx) in [16, 22, 31, 37].enumerated() {
        let up = step >= 0 && i % 2 == step ? 1 : 0
        c.rect(lx, 36, 4, 8 - up, suit)
        c.rect(lx - 1, 40 - up, 6, 4, rustDark)
        c.rect(lx - 1, 40 - up, 6, 1, rust)
    }
    if charging, let s = p.signature {                                    // dust kicked up behind
        for k in 0..<3 { puff(c, x: 13 - Double(k) * 3, y: 42 - Double(k), k: frac(s * 5 + Double(k) / 3), C(0xB8A88A)) }
    }
    c.oy += p.breathe
    if charging { c.ox += 1; c.oy += 1 }
    // the far arm, hanging behind
    c.rect(11, 22, 4, 10, suit); c.rect(10, 31, 6, 5, rust); c.rect(10, 31, 6, 1, rustLight)
    // the barrel of a body
    c.rect(14, 15, 28, 22, rust)
    c.rect(14, 15, 2, 22, rustLight)
    c.rect(40, 15, 2, 22, rustDark)
    c.rect(14, 23, 28, 3, steel); c.rect(14, 25, 28, 1, steelDark)          // chest band
    c.rect(26, 15, 4, 22, steel); c.rect(29, 15, 1, 22, steelDark)          // and the strap down the middle
    for x in [17, 22, 34, 39] { c.px(x, 24, steelDark) }                     // rivets
    for y in [18, 29, 34] { c.px(27, y, steelDark) }
    c.rect(14, 33, 28, 4, suit); c.rect(14, 33, 28, 1, rustDark)            // belt and trunks
    c.rect(26, 33, 4, 3, steel)
    // the helmet
    c.pattern(15, 2, [
        "........HHHHHHHHHH........",
        "......HHHHHHHHHHHHHH......",
        ".....HHHHHHHHHHHHHHHH.....",
        "....HHHHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHHH..",
    ], ["H": rust])
    c.rect(16, 18, 24, 1, rustDark); c.rect(17, 19, 22, 1, rustDark)          // the helmet's rim
    c.rect(19, 4, 2, 6, rustLight); c.rect(18, 7, 1, 5, rustLight)          // shine on the dome
    c.rect(27, 2, 3, 8, rustDark)                                           // the ridge over the top
    c.rect(38, 7, 2, 12, rustDark)
    // the face, set back in the opening
    c.rect(24, 10, 15, 9, rustDark)
    c.rect(25, 11, 13, 7, skin)
    c.rect(25, 11, 13, 1, C(0xB87858))
    c.rect(27, 12, 2, 3, ink); c.rect(33, 12, 2, 3, ink)                    // Clawd's eyes
    c.rect(26, 12, 4, 1, C(0x5A3A2A)); c.rect(32, 12, 4, 1, C(0x5A3A2A))    // heavy brows
    c.rect(29, 16, 5, 1, C(0x8A4A3A))                                       // a scowl
    c.circle(19, 13, 2, steel); c.px(19, 13, steelDark)                     // the ear bolt
    // Signature: steam snorting from the helmet vents.
    if charging, let s = p.signature {
        for k in 0..<3 {
            let f = frac(s * 4 + Double(k) / 3)
            puff(c, x: 41 + f * 6, y: 15 - f * 6, k: f)
            puff(c, x: 15 - f * 5, y: 9 - f * 6, k: frac(f + 0.5))
        }
    }
    // the fist
    let angle = p.melee ?? 80
    smear(c, juggernautShoulder, p.trail, len: 18, C(0xF4E0C8))
    c.rect(37, 17, 7, 7, rust); c.rect(37, 17, 7, 1, rustLight)              // shoulder
    let e = limb(c, juggernautShoulder, angle, len: 12, r: 2.3, suit)
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 7, 7, rust)
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 7, 1, rustLight)
    c.rect(Int(e.x) - 3, Int(e.y) + 3, 7, 1, rustDark)
}

// MARK: - Sabretooth

/// Sabretooth: Clawd with a wild blond mane down his back, bushy sideburns, a fanged snarl, a brown suit with the
/// shaggy fur collar and cuffs, and long claws. Signature: he flexes, both clawed hands up, and bares his fangs.
private func drawSabretooth(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD89A6A), skinShade = C(0xB07A52), suit = C(0x7A4A22), suitDark = C(0x52301A)
    let hair = C(0xE8C860), hairDark = C(0xB8963A), fur = C(0xEADCC0), furDark = C(0xC0B090)
    let flex = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let up = Int((flex * 5).rounded())
    // the mane, flowing down behind him
    c.oy += p.breathe
    c.pattern(12, 21, ["...h.H......", "..HH.HHH....", ".HHHHHHH....", "HHHHHHHH....", "HHHHHHH.....", ".HHHHHH.....",
                       "HHHHHH......", "HHHHHh......", ".HHHHH......", "HHHHH.......", ".HHhH.......", "HHH.........",
                       ".HH.........", "H..........."], ["H": hair, "h": hairDark])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: suit), step: p.step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 41, 2, 3, suitDark) }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit), armLeft: up, armRight: up)
    c.rect(18, 34, 20, 4, suit)
    c.rect(18, 37, 20, 1, suitDark)
    c.pattern(17, 33, ["FfFFfFFFfFFFFfFFFfFFf", "..FF....fF....FF..f.."], ["F": fur, "f": furDark])   // fur collar
    // hair: a ragged mop on top and big sideburns
    c.pattern(16, 20, [
        "...H...H..H....H......",
        "..HHh.HHHHHH.HHHh.H...",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHhHHHHhHHHHHHHH",
        "HHHH..H...H...H.HHHHH.",
        "HHH................HH.",
        "HHH................HH.",
        "HHH................H..",
        ".HH................H..",
    ], ["H": hair, "h": hairDark])
    if flex > 0.5, let s = p.signature {                                   // hackles up
        for (k, x) in [19, 23, 26, 31].enumerated() { c.rect(x, 17 + (Int(s * 20) + k) % 2, 1, 3, hair) }
    }
    c.rect(21, 28, 4, 1, C(0x6A4A1A)); c.rect(31, 28, 4, 1, C(0x6A4A1A))   // brows angled into a glare
    c.px(24, 29, C(0x6A4A1A)); c.px(31, 29, C(0x6A4A1A))
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    let gape = Int((flex * 2).rounded())
    c.rect(25, 32, 7, 1 + gape, C(0x4A1A14))                                // the snarl
    c.px(25, 33 + gape, fur); c.px(31, 33 + gape, fur)                     // fangs
    if gape > 0 { c.px(26, 32, fur); c.px(30, 32, fur); c.px(26, 33 + gape, white); c.px(30, 33 + gape, white) }
    // claws
    if flex > 0.05 {
        claws(c, (16.5, 33.5 - Double(up)), -115, len: 3 + 3 * flex, spread: 0.55, C(0xD0C4A8))
        claws(c, (39.5, 33.5 - Double(up)), -65, len: 3 + 3 * flex, spread: 0.55, C(0xD0C4A8))
        return
    }
    c.rect(15, 35, 3, 1, fur)                                               // fur cuff
    let a = p.melee ?? 75
    smear(c, Sprite.hand, p.trail, len: 10, C(0xF2ECDC))
    let hand = (x: Sprite.hand.x - 1, y: Sprite.hand.y - 1 - Double(p.armRaise))
    c.rect(Int(hand.x) - 1, Int(hand.y) - 1, 3, 3, skin)
    c.rect(Int(hand.x) - 2, Int(hand.y) + 1, 3, 1, fur)
    claws(c, (hand.x + 0.5, hand.y + 0.5), a, len: p.melee == nil ? 5 : 8, spread: 0.5, C(0xD0C4A8))
}

// MARK: - Mystique

/// Mystique (the movie look, which reads best small): a blue-scaled Clawd with slicked-back red hair and yellow eyes,
/// a short knife in hand. Signature: a ripple of scales sweeps across her and she's suddenly plain Clawd, for a
/// moment, before rippling back.
private func drawMystique(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.05, s < 0.95 else { mystique(c, p); return }
    // 0.05…0.35 the ripple sweeps right to left into Clawd; 0.65…0.95 it sweeps back.
    let k = s < 0.5 ? min(1, (s - 0.05) / 0.3) : max(0, 1 - (s - 0.65) / 0.3)
    let split = Int((44 - 33 * k).rounded())                       // columns from `split` on are Clawd
    sweep(c, split: split, { mystique($0, p) }, { plainClawd($0, p) })
    if k > 0, k < 1 {                                              // the shimmering front of the change
        for y in 18...43 where noise(y * 7 + Int(p.t * 20)) > 0.35 {
            let x = split + (y % 3) - 1
            c.px(x, y, (y % 2 == 0 ? C(0x7AB8FF) : C(0xFFE24A)).alpha(0.9))
        }
    }
}

private func plainClawd(_ c: PixelCanvas, _ p: Pose) {
    drawLegs(c, Look(), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look())
}

private func mystique(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2E5AC8), blueDark = C(0x1E3A8A), scale = C(0x4A7AE0), hair = C(0xC8282A), hairDark = C(0x8A1418)
    drawLegs(c, Look(leg: blue), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: blue, shade: blueDark, arm: blue, eye: nil), armRight: p.armRaise)
    // the scales: a ragged pattern of lighter ridges
    for (x, y) in [(19, 27), (25, 27), (34, 28), (20, 33), (28, 34), (35, 33), (24, 36), (31, 31), (29, 27), (36, 36),
                   (18, 30), (21, 36)] {
        c.px(x, y, scale); c.px(x + 1, y + 1, blueDark)
    }
    // slicked-back red hair, swept off the brow into a short tuft behind
    c.pattern(14, 23, [
        "..........RRRRRRR.......",
        "......RRRRRRRRRRRRRRR...",
        "...RRRRrrRRRRRRRRRRRRRR.",
        "RRRRRrrRRRRRRRrrRRRRRRRR",
        ".RRRRRR.................",
        "..RRRR..................",
        "...RRR..................",
        "....RR..................",
    ], ["R": hair, "r": hairDark])
    c.rect(22, 29, 2, 3, C(0xFFD23A)); c.rect(32, 29, 2, 3, C(0xFFD23A))    // yellow eyes…
    c.px(23, 30, ink); c.px(33, 30, ink)                                   // …with dark slits
    c.rect(21, 28, 3, 1, blueDark); c.rect(32, 28, 3, 1, blueDark)
    c.rect(27, 33, 3, 1, blueDark)
    // the knife
    let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(p.armRaise))
    if let a = p.melee {
        smear(c, hand, p.trail, len: 11, C(0xDDE4F0))
        let r = a * .pi / 180
        c.glowLine(hand.x - cos(r) * 1.5, hand.y - sin(r) * 1.5, hand.x + cos(r) * 2, hand.y + sin(r) * 2,
                   core: C(0x2A2A30), glow: clear, coreR: 0.8, glowR: 0.9)
        c.glowLine(hand.x + cos(r) * 2, hand.y + sin(r) * 2, hand.x + cos(r) * 10, hand.y + sin(r) * 10,
                   core: C(0xD8DEE8), glow: clear, coreR: 0.7, glowR: 0.8)
    } else {
        c.rect(36, 35, 1, 3, C(0x2A2A30)); c.rect(36, 37, 1, 1, C(0xB9BEC8))   // sheathed at her hip
    }
}

// MARK: - Apocalypse

/// Apocalypse's shoulder: his arm, reshaped into a blade, swings from here.
private let apocalypseShoulder = (x: 40.0, y: 20.0)

/// Apocalypse: a giant in blue-and-black armour with vast shoulder plates and the tubes snaking from the back of his
/// helmet, a grey face with blue lips and red eyes; his right arm reshapes itself into a great blade. Signature:
/// his eyes and mouth blaze with power.
private func drawApocalypse(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2E44B0), blueDark = C(0x1E2A78), blueLight = C(0x5A76E0), black = C(0x1A1A26), blackLight = C(0x3A3A4E)
    let grey = C(0x9A9CA8), greyDark = C(0x6A6C78), steel = C(0xC8CCD8)
    let glow = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    for (i, lx) in [18, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 32, 7, 12 - up, blue)
        c.rect(lx, 32, 2, 12 - up, blueLight)
        c.rect(lx, 34 - up, 7, 2, black)                                  // knee
        c.rect(lx - 1, 39 - up, 9, 5, black)                              // boots
        c.rect(lx - 1, 39 - up, 9, 1, blackLight)
    }
    c.oy += p.breathe
    // the tubes, from the back of his helmet down to his back
    for (a, b, d) in [((20.0, 5.0), (14.0, 6.0), (11.0, 12.0)), ((20.0, 9.0), (16.0, 10.0), (14.0, 13.0))] {
        c.glowLine(a.0, a.1, b.0, b.1, core: black, glow: clear, coreR: 1.1, glowR: 1.2)
        c.glowLine(b.0, b.1, d.0, d.1, core: black, glow: clear, coreR: 1.1, glowR: 1.2)
        c.px(Int(b.0), Int(b.1) - 1, blackLight); c.px(Int(b.0) + 3, Int(a.1), blackLight)
    }
    // far arm
    c.rect(11, 20, 4, 11, blue); c.rect(10, 30, 6, 5, black)
    // the torso
    c.rect(15, 14, 26, 19, blue)
    c.rect(15, 14, 2, 19, blueLight)
    c.rect(39, 14, 2, 19, blueDark)
    c.rect(21, 21, 14, 11, black)                                         // the black midriff…
    for y in [23, 26, 29] { c.rect(22, y, 12, 1, blackLight) }           // …in segments
    c.rect(27, 21, 2, 11, blackLight)
    c.rect(15, 31, 26, 2, greyDark); c.rect(26, 31, 4, 2, steel)          // belt
    // vast shoulder plates
    for sx in [10, 34] {
        c.pattern(sx, 11, ["..BBBBBBB..", ".BBLLLLBBB.", "BBBBBBBBBBB", "BBBBBBBBBBB", "KKKKKKKKKKK", ".BBBBBBBBB."],
                  ["B": blue, "L": blueLight, "K": black])
    }
    // the head: black helmet with a ridged crest, grey face, blue lips
    c.pattern(19, 0, [
        "......KKKKKKK.....",
        "....KKKKBBKKKKK...",
        "...KKKKKBBKKKKKK..",
        "..KKKKKKBBKKKKKKK.",
        ".KKKKKKGGGGGGGGGGK",
        "KKKKKKGGGGGGGGGGGK",
        "KKBKKKGGGGGGGGGGGK",
        "KKBKKKGGGGGGGGGGGK",
        "KKBKKKGGGGGGGGGGGK",
        "KKKKKKGGGGGGGGGGGK",
        ".KKKKKGGGGGGGGGGG.",
        ".KKKKKKGGGGGGGGGG.",
        "..KKKKKKGGGGGGGG..",
        "...KKKKKKGGGGGG...",
    ], ["K": black, "B": blue, "G": grey])
    c.rect(26, 5, 10, 1, greyDark)                                        // heavy brow
    c.rect(27, 7, 2, 2, ink); c.rect(32, 7, 2, 2, ink)                    // Clawd's eyes…
    c.px(28, 7, C(0xFF3A3A)); c.px(33, 7, C(0xFF3A3A))                    // …glinting red
    c.rect(28, 11, 6, 1, blue)                                            // blue lips
    c.px(29, 12, blue); c.px(32, 12, blue); c.px(26, 9, blue); c.px(26, 10, blue)   // and the stripes
    // Signature: his eyes and mouth blaze.
    if glow > 0.05 {
        let hot = C(0xFF4A2A), core = C(0xFFF0C0), s = p.signature ?? 0
        let flick = 0.8 + 0.2 * noise(Int(s * 60))
        c.glowLine(27.5, 7.5, 29, 7.5, core: core.alpha(glow), glow: hot.alpha(glow), coreR: 0.7, glowR: 2.6, strength: flick)
        c.glowLine(32.5, 7.5, 34, 7.5, core: core.alpha(glow), glow: hot.alpha(glow), coreR: 0.7, glowR: 2.6, strength: flick)
        c.glowLine(28.5, 11.5, 33.5, 11.5, core: core.alpha(glow), glow: C(0x5A7AFF).alpha(glow), coreR: 0.5, glowR: 1.8,
                   strength: flick)
        if glow > 0.9 {
            for k in 0..<3 {
                let f = frac(s * 5 + Double(k) / 3)
                c.px(37 + Int(f * 8), 7 - Int(f * 3) + k, hot.alpha(1 - f))
            }
        }
    }
    // the blade arm
    let angle = p.melee ?? 82
    smear(c, apocalypseShoulder, p.trail, len: 22, C(0xC8D4FF))
    let e = limb(c, apocalypseShoulder, angle, len: 10, r: 2.3, blue)
    let r = angle * .pi / 180, nx = -sin(r), ny = cos(r)
    for k in 0..<10 {                                                     // the blade: broad at the wrist, to a point
        let u = Double(k), w = 2.2 * (1 - u / 11)
        c.glowLine(e.x + cos(r) * u - nx * w, e.y + sin(r) * u - ny * w, e.x + cos(r) * u + nx * w, e.y + sin(r) * u + ny * w,
                   core: k % 3 == 0 ? steel : C(0xA8ACBA), glow: clear, coreR: 0.6, glowR: 0.7)
    }
    c.rect(Int(e.x) - 2, Int(e.y) - 2, 5, 5, black)                       // the gauntlet it grows from
}

// MARK: - Sentinel

/// Where the Sentinel's forward palm is when it's raised to fire.
private let sentinelPalm = (x: 54.0, y: 18.0)

/// A Sentinel: a towering purple robot with magenta joints and midriff, the flared purple helmet over a grey-lilac
/// face with yellow eyes and a slot mouth; its chest is a broad Clawd block. Its palm comes up to fire a red beam.
/// Signature: its eyes sweep a scanning beam over the ground in front.
private func drawSentinel(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2E9E), purpleDark = C(0x46206E), purpleLight = C(0x9058C8)
    let magenta = C(0xD0409A), magentaDark = C(0x9A2A72), face = C(0xB8A8C8), faceDark = C(0x8A7A9C), eye = C(0xFFE24A)
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 28, 6, 7, magenta); c.rect(lx, 28, 1, 7, C(0xE870B8))
        c.rect(lx - 1, 34 - up, 8, 3, purple)                             // knee
        c.rect(lx, 37 - up, 6, 5, purple); c.rect(lx + 5, 37 - up, 1, 5, purpleDark)
        c.rect(lx - 2, 41 - up, 10, 3, purpleDark); c.rect(lx - 2, 41 - up, 10, 1, purple)   // feet
    }
    c.oy += p.breathe
    // the far arm, hanging
    c.rect(13, 17, 4, 6, magentaDark); c.rect(12, 23, 6, 8, purpleDark); c.rect(13, 31, 4, 3, magentaDark)
    // hips and midriff
    c.rect(17, 25, 22, 5, purple); c.rect(17, 29, 22, 1, purpleDark)
    c.rect(19, 19, 18, 6, magenta)
    for y in [20, 22, 24] { c.rect(19, y, 18, 1, magentaDark) }
    // the chest: a big Clawd block
    c.rect(16, 11, 24, 9, purple)
    c.rect(16, 11, 24, 1, purpleLight); c.rect(16, 11, 1, 9, purpleLight)
    c.rect(39, 11, 1, 9, purpleDark)
    c.rect(24, 13, 8, 4, magenta); c.rect(25, 14, 6, 2, magentaDark)       // chest plate
    // shoulders
    c.pattern(11, 9, [".PPPPPP.", "PPLLPPPP", "PPPPPPPP", "PPPPPPPP", ".PPPPPP."], ["P": purple, "L": purpleLight])
    // the head: flared helmet, face plate, collar
    c.pattern(16, 0, [
        "........PPPPPPPP........",
        "......PPPPPPPPPPPP......",
        ".....PPLLPPPPPPPPPP.....",
        "....PPLPPFFFFFFFFPPP....",
        "....PPPPFFFFFFFFFFPP....",
        "...PPPPPFFFFFFFFFFPPP...",
        "...PPPPPFFFFFFFFFFPPP...",
        "..PPPPPPFFFFFFFFFFPPPP..",
        "..PPPPPPFFFFFFFFFFPPPP..",
        ".PPPPPPPPFFFFFFFFPPPPPP.",
        "PPPPPPPPPPPPPPPPPPPPPPPP",
        "DDDDDDDDDDDDDDDDDDDDDDDD",
    ], ["P": purple, "L": purpleLight, "F": face, "D": purpleDark])
    c.rect(24, 3, 10, 1, faceDark)
    c.rect(25, 5, 3, 2, eye); c.rect(30, 5, 3, 2, eye)                    // eyes
    c.rect(26, 8, 5, 1, ink)                                              // the slot mouth
    // Signature: a scanning beam sweeps the ground.
    if let s = p.signature, s > 0.1, s < 0.9 {
        let k = (s - 0.1) / 0.8
        let gx = 46 + 22 * (0.5 - 0.5 * cos(k * 2 * .pi * 1.5))
        let on = min(1, min(k, 1 - k) * 8)
        c.glowLine(33, 6, gx, 43, core: C(0xFFD0D0).alpha(on * 0.6), glow: C(0xFF3A3A).alpha(on * 0.45), coreR: 0.3, glowR: 1.5)
        c.glowLine(gx - 3, 43, gx + 3, 43, core: C(0xFFE0E0).alpha(on), glow: C(0xFF3A3A).alpha(on), coreR: 0.5, glowR: 1.6)
        c.rect(25, 5, 3, 2, C(0xFF4A3A)); c.rect(30, 5, 3, 2, C(0xFF4A3A))
    }
    // the near arm: raised to fire, or hanging
    c.pattern(36, 9, [".PPPPPP.", "PPPLLPPP", "PPPPPPPP", "PPPPPPPD", ".PPPPPD."], ["P": purple, "L": purpleLight, "D": purpleDark])
    if p.fire != nil || p.gunLift != 0 || p.smoke != nil {
        c.oy += p.gunY
        let y = Int(sentinelPalm.y)
        c.rect(40, y - 1, 6, 3, magenta)                                  // upper arm
        c.rect(45, y - 2, 7, 5, purple); c.rect(45, y - 2, 7, 1, purpleLight)
        c.rect(52, y - 2, 2, 5, magenta); c.rect(53, y - 1, 1, 3, C(0xFF8AC0))   // the palm, facing forward
    } else {
        c.rect(39, 14, 4, 7, magenta)
        c.rect(38, 20, 6, 9, purple); c.rect(38, 20, 6, 1, purpleLight); c.rect(43, 20, 1, 9, purpleDark)
        c.rect(39, 29, 4, 4, magenta)
    }
}

// MARK: - The Abomination

/// The Abomination's shoulder: his clawed arm swings from here.
private let abominationShoulder = (x: 39.0, y: 18.0)

/// The Abomination: a hulking green reptilian brute, scaly hide, a bony ridge down his back, the wide head with
/// fin-like ears, a jutting brow, beady yellow eyes and the great lipped mouth; ragged shorts and a long clawed arm.
/// Signature: he throws his head back and roars.
private func drawAbomination(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4E7A44), dark = C(0x34562E), light = C(0x7AA060), belly = C(0x9AB87A), claw = C(0xF2ECDC)
    let shorts = C(0x5A4636), shortsDark = C(0x3E3024)
    let roar = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 30, 7, 13 - up, green); c.rect(lx + 6, 30, 1, 13 - up, dark)
        c.rect(lx - 1, 41 - up, 9, 2, dark)
        for k in 0..<3 { c.px(lx - 1 + k * 4, 43 - up, claw) }
    }
    c.oy += p.breathe
    // far arm
    c.rect(11, 18, 5, 14, dark); c.rect(10, 31, 6, 3, dark)
    for k in 0..<3 { c.px(10 + k * 2, 34, claw) }
    // the torso
    c.rect(15, 13, 25, 19, green)
    c.rect(15, 13, 2, 19, dark)
    c.rect(23, 16, 15, 14, belly)                                        // pale scaly chest and belly
    for y in stride(from: 18, to: 30, by: 3) { c.rect(24, y, 13, 1, light) }
    for (x, y) in [(19, 17), (21, 24), (18, 28), (35, 14), (29, 14)] { c.rect(x, y, 2, 1, light) }
    for k in 0..<5 { c.rect(12 + (k % 2), 14 + k * 4, 3, 2, C(0xC8C0A0)) }   // the bony ridge down his back
    c.rect(15, 28, 25, 6, shorts); c.rect(15, 28, 25, 1, shortsDark)
    for x in stride(from: 16, to: 40, by: 4) { c.rect(x, 34, 2, 1, shorts) }                  // a ragged hem
    // the head, thrown back as he roars
    c.oy -= Int((roar * 2).rounded())
    c.pattern(21, 1, [
        "....GGGGGGGGGG.....",
        "..GGGGGGGGGGGGGG...",
        ".GGGGLGGGLGGGGGGG..",
        "GGGGGGGGGGGGGGGGGG.",
        "BBBBBBBBBBBBBBBBBBB",
        "GGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGG",
        ".GGGGGGGGGGGGGGGGGG",
        ".GGGGGGGGGGGGGGGGG.",
        "..GGGGGGGGGGGGGGG..",
        "....GGGGGGGGGGG....",
    ], ["G": green, "L": light, "B": dark])
    c.pattern(15, 2, ["E.....", "EEE...", ".EEEE.", "..EEEE", "...EEE", "....EE"], ["E": dark])   // fin-like ear
    c.rect(26, 6, 3, 2, C(0xFFE24A)); c.rect(33, 6, 3, 2, C(0xFFE24A))   // beady eyes under the brow
    c.px(27, 7, ink); c.px(34, 7, ink)
    let gape = Int((roar * 4).rounded())
    c.rect(24, 9, 15, 3 + gape, C(0x3A0E10))                             // the great mouth
    c.rect(23, 9, 17, 1, light); c.rect(23, 12 + gape, 17, 1, light)     // thick lips
    for k in 0..<5 { c.px(25 + k * 3, 10, claw); c.px(26 + k * 3, 11 + gape, claw) }
    if roar > 0.9, let s = p.signature {
        for i in 0..<3 {                                                  // the roar
            let f = frac(s * 4 + Double(i) / 3), x = 42 + Int(f * 12), col = C(0xF4EEE0).alpha(0.8 * (1 - f))
            for dy in -2 - i...(2 + i) where abs(dy) > 0 || i == 0 { c.px(x - abs(dy) / 2, 11 + dy, col) }
        }
    }
    c.oy += Int((roar * 2).rounded())
    // the clawed arm
    let angle = p.melee ?? 78
    smear(c, abominationShoulder, p.trail, len: 20, C(0xD8F0C0))
    c.circle(39, 17, 3, green)
    let e = limb(c, abominationShoulder, angle, len: 14, r: 2.3, green)
    c.rect(Int(e.x) - 2, Int(e.y) - 2, 5, 5, dark)
    claws(c, e, angle, len: 6, spread: 0.5, C(0xD0C4A8))
}

// MARK: - Fin Fang Foom

/// Fin Fang Foom: a towering green Chinese dragon standing upright in his purple shorts, yellow belly plates, a
/// curling spiked tail, and a long-snouted head with purple fins, red eyes, a fanged open mouth and drooping
/// whiskers. Breathes fire. Signature: a lazy puff of smoke from his nostrils and a lick of flame.
private func drawFinFangFoom(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A9A4A), dark = C(0x267030), light = C(0x6AC060), belly = C(0xE8D06A), bellyDark = C(0xC0A040)
    let purple = C(0x7A3A9A), purpleDark = C(0x52266E), fin = C(0xB060D0), claw = C(0xF2ECDC)
    // the tail, curling round behind
    c.pattern(1, 29, [
        "..S.S.S.........",
        ".GGGGGG.........",
        "GGG..GGG........",
        "GG.....GG.......",
        "GG......GGG.....",
        ".GG......GGGGG..",
        "..GGG.....GGGGGG",
        "....GGGGGGGGGGGG",
        "......GGGGGGGGGG",
    ], ["G": dark, "S": fin])
    for (i, lx) in [19, 29].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 33, 7, 9 - up, green); c.rect(lx + 6, 33, 1, 9 - up, dark)
        c.rect(lx - 1, 41 - up, 9, 2, dark)
        for k in 0..<3 { c.px(lx + k * 3, 43 - up, claw) }
    }
    c.oy += p.breathe
    // the body
    c.rect(16, 12, 20, 22, green)
    c.rect(16, 12, 2, 22, dark)
    c.rect(28, 13, 8, 17, belly)
    for y in stride(from: 15, to: 30, by: 3) { c.rect(28, y, 8, 1, bellyDark) }
    for k in 0..<5 { c.px(14 + (k % 2), 13 + k * 4, fin); c.px(15, 14 + k * 4, fin) }   // spines on his back
    c.rect(15, 28, 23, 7, purple); c.rect(15, 28, 23, 1, purpleDark)                    // the shorts
    c.rect(15, 34, 23, 1, purpleDark)
    // neck up to the head
    c.glowLine(30, 14, 41, 9, core: green, glow: clear, coreR: 3.2, glowR: 3.3)
    c.glowLine(34, 16, 43, 12, core: belly, glow: clear, coreR: 1, glowR: 1.1)
    // the head
    c.pattern(37, 0, [
        "F...F...F.................",
        "FF..FF..FF................",
        ".FFGGFFGGFF...............",
        "..GGGGGGGGGGGG............",
        ".GGGGGGGGGGGGGGGG.........",
        "GGGGGGGGEEGGGGGGGGGG......",
        "GGGGGGGGGGGGGGGGGGGGGGG...",
        "GGGGGGGGGGGGGGGGGGGGGGGGN.",
        "GGGGGGGGGGGGGGGGGGGGGGGGG.",
        "GGGGGGGGGGWGGWGGWGGWGGWGG.",
        "GGGGGGGGMWMMWMMWMMWMMWMMW.",
        "GGGGGGGGMMMMMMMMMMMMMMMM..",
        "GGGGGGGGGMWMMWMMWMMWMMW...",
        ".GGGGGGGGGGGGGGGGGGGGGG...",
        "..LLLLLLLLLLLLLLLLLLL.....",
    ], ["G": green, "F": fin, "E": C(0xFF3A2A), "W": claw, "M": C(0x5A1418), "N": ink, "L": light])
    c.px(46, 5, C(0xFFE24A))
    c.rect(43, 4, 6, 1, dark)                                            // the brow
    c.pattern(33, 5, ["F.......", ".FF.....", "FFFF....", ".FFFFF..", "FFFFFF..", ".FFFFF..", "FFFF....", ".FF.....", "F......."],
              ["F": fin])                                                // the frill behind his jaw
    // whiskers, drooping from the snout
    for (k, (x, y)) in [(60, 9), (61, 10), (62, 11), (63, 13), (63, 15), (62, 17), (61, 18)].enumerated() {
        c.px(x, y, fin); if k < 5 { c.px(x - 3, y + 6, fin.alpha(k < 3 ? 1 : 0)) }
    }
    c.rect(44, 15, 2, 4, fin); c.rect(43, 18, 2, 2, fin)                 // the chin barbel
    // the little arm, claws out front
    c.glowLine(35, 18, 40, 22, core: green, glow: clear, coreR: 1.5, glowR: 1.6)
    claws(c, (40.5, 22.5), 30, len: 3)
    // Signature: smoke curling from the nostrils, a lick of flame at the lips.
    if let s = p.signature, s > 0.1, s < 0.95 {
        for k in 0..<3 {
            let f = frac(s * 2.5 + Double(k) / 3)
            puff(c, x: 61 - f * 4, y: 6 - f * 7, k: f, C(0x9A9CA4))
        }
        if frac(s * 6) < 0.5 { c.px(62, 10, C(0xFFB02A)); c.px(63, 10, C(0xFFE27A)) }
    }
}

// MARK: - MODOK

/// MODOK's headband emitter: his mental beam fires from here.
private let modokEmitter = (x: 48.5, y: 12.5)

/// MODOK: an enormous head (a tiny scowling face low on the front, the gold headband with its beam emitter) riding
/// in the gold Doomsday Chair, tiny arms on the controls and tiny legs dangling. Signature: his whole face screws up
/// into a furious frown and the headband flickers, sparking.
private func drawModok(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE8C898), skinShade = C(0xC8A070), skinLight = C(0xF6E0BC)
    let gold = C(0xE8B828), goldDark = C(0xA8801A), goldLight = C(0xFFE07A), suit = C(0x3A8A5A)
    let fury = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    c.oy += p.breathe
    // tiny legs dangling under the chair
    for lx in [27, 33] {
        let swing = p.step >= 0 && (lx == 27) == (p.step == 0) ? 1 : 0
        c.rect(lx + swing, 37, 2, 4, suit); c.rect(lx + swing, 41, 3, 1, goldDark)
    }
    // the hover jets
    let flick = noise(Int(p.t * 20))
    c.rect(22, 37, 3, 1 + Int(flick * 2), C(0x7FD8FF)); c.rect(37, 37, 3, 1 + Int((1 - flick) * 2), C(0x7FD8FF))
    // the head
    for y in 3...31 {
        let d = (Double(y) - 18) / 15.5
        let hw = 15.0 * (1 - d * d).squareRoot()
        let l = Int((30.5 - hw).rounded()), r = Int((30.5 + hw).rounded())
        c.rect(l, y, r - l, 1, skin)
        c.px(l, y, skinShade)
    }
    c.rect(22, 5, 6, 1, skinLight); c.rect(20, 7, 3, 2, skinLight)            // shine on the dome
    c.rect(17, 14, 2, 1, skinShade); c.rect(20, 21, 2, 1, skinShade)          // furrows
    // the headband and its emitter
    c.rect(16, 11, 30, 3, gold); c.rect(16, 13, 30, 1, goldDark)
    c.rect(45, 10, 3, 5, goldDark); c.rect(47, 11, 2, 3, C(0x5A5E68))
    let lit = fury > 0.3 ? (noise(Int(p.t * 30)) > 0.4) : true
    c.px(48, 12, lit ? C(0xFFF6C0) : C(0x8A6A1A))
    if fury > 0.3, let s = p.signature, noise(Int(s * 50)) > 0.6 { drawSparks(c, x: 49, y: 12, t: p.t, size: 2) }
    // the tiny face, low on the front
    let frown = Int((fury * 2).rounded())
    c.rect(35, 19, 3, 2, ink); c.rect(41, 19, 3, 2, ink)                      // small eyes
    c.px(36, 19, white); c.px(42, 19, white)
    let brow = C(0x6A4A2A)                                                    // heavy brows, angled down into a scowl
    c.rect(34, 16, 2, 1, brow); c.rect(36, 17, 2, 1, brow); c.rect(41, 17, 2, 1, brow); c.rect(43, 16, 2, 1, brow)
    if frown > 0 { c.rect(37, 18, 1, 1, brow); c.rect(41, 18, 1, 1, brow); c.rect(38, 16, 2, 1, skinShade) }   // knitted, the forehead creased
    c.rect(38, 21, 2, 2, skinShade)                                           // nose
    c.rect(36, 25, 7, 1, C(0x7A3A2A)); c.px(35, 26, C(0x7A3A2A)); c.px(43, 26, C(0x7A3A2A))   // a frown
    if frown > 1 { c.px(34, 27, C(0x7A3A2A)); c.px(44, 27, C(0x7A3A2A)); c.rect(37, 24, 5, 1, skinShade) }
    c.rect(33, 23, 2, 1, skinShade); c.rect(44, 23, 1, 1, skinShade)          // jowls
    if fury > 0.5 { c.rect(31, 21, 2, 1, C(0xE88A6A).alpha(0.8)); c.rect(45, 21, 1, 1, C(0xE88A6A).alpha(0.8)) }
    // the Doomsday Chair
    c.pattern(13, 28, [
        "GG...........................GG.",
        "GGG.........................GGG.",
        "GGGGLLLLLLLLLLLLLLLLLLLLLLLLGGGG",
        "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
        ".GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG.",
        ".DDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.",
        "..GGGGGGGGGGGGGGGGGGGGGGGGGGGG..",
        "....DDDDDDDDDDDDDDDDDDDDDDDD....",
        "........DDDDDDDDDDDDDDDD........",
    ], ["G": gold, "L": goldLight, "D": goldDark])
    c.rect(21, 32, 3, 2, C(0xC83A2A)); c.rect(26, 32, 3, 2, C(0x3A7BEA))       // controls
    // a tiny arm, its hand on the controls up front
    c.rect(44, 27, 4, 1, suit); c.rect(47, 28, 1, 2, suit); c.rect(46, 30, 2, 1, skin)
}

// MARK: - Dormammu

/// Dormammu: a Clawd made of darkness, robed in deep purple with a towering magenta collar, his head a blazing pillar
/// of fire with burning eyes. Signature: the flames flare up, roaring high and white-hot.
private func drawDormammu(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x4A1A7A), robeEdge = C(0x6A2A9A), collar = C(0xB03AD0), collarDark = C(0x7A1E9A), sash = C(0xFF8A1E)
    let flare = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    for y in 36...43 {                                                    // the robe, to the ground
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, robe)
        c.px(17 - k, y, robeEdge); c.px(38 + k, y, robeEdge)
        if y > 38 { c.px(24, y, robeEdge); c.px(31, y, robeEdge) }
    }
    c.oy += p.breathe
    // the flames: tongues rising from the top of his head, licking up the sides
    let t = p.t, tall = 1 + flare * 0.9
    c.rect(18, 22, 20, 6, C(0xFF8A1E)); c.rect(21, 24, 14, 4, C(0xFFE27A))
    for (i, cx) in [18.5, 22.5, 27.5, 32.5, 36.5].enumerated() {
        let base = [8.0, 12, 15, 12, 8][i]
        let h = (base + 2.5 * sin(t * 7 + Double(i) * 1.7)) * tall, hw = i == 2 ? 4 : 3.2
        let sway = sin(t * 5 + Double(i)) * 1.5
        for y in 0..<Int(h.rounded()) {
            let f = Double(y) / h, w = hw * (1 - f), x0 = cx + sway * f
            for x in Int((x0 - w).rounded())...Int((x0 + w).rounded()) {
                let inner = abs(Double(x) - x0) < w * 0.5
                let hot = flare > 0.6 ? C(0xFFF8E0) : C(0xFFE27A)
                let col = inner ? (f < 0.45 ? hot : C(0xFF8A1E)) : (f < 0.55 ? C(0xFF8A1E) : C(0xE0301E))
                c.px(x, 27 - y, col)
            }
        }
    }
    for i in 0..<Int(2 + flare * 4) {                                     // embers flying off
        let f = frac(t * 1.3 + Double(i) * 0.37), x = 18 + Int(noise(i * 31 + Int(t * 1.3 + Double(i) * 0.37)) * 20)
        c.px(x, 20 - Int(f * 10 * tall), C(0xFFB02A).alpha(1 - f))
    }
    var look = Look(body: C(0x2A0A14), shade: C(0x1A060C), arm: robe, eye: nil)
    look.legs = false
    drawBody(c, look, armRight: p.armRaise)
    c.rect(18, 26, 20, 2, C(0xE0301E))                                    // the flames burning down onto his face
    for x in stride(from: 19, to: 37, by: 3) { c.px(x, 28, C(0xE0301E)) }
    let eye = flare > 0.4 ? white : C(0xFFE27A)
    c.rect(22, 29, 2, 3, eye); c.rect(32, 29, 2, 3, eye)
    c.px(22, 29, C(0xFF8A1E)); c.px(32, 29, C(0xFF8A1E))
    // the robe and its high collar
    c.rect(18, 33, 20, 5, robe)
    c.rect(18, 35, 20, 1, sash); c.rect(26, 34, 4, 3, sash)
    var wings = ["CC......................CC", "CCC....................CCC", ".CCC..................CCC."]
    wings += [String](repeating: "..cCC................CCc..", count: 10) + ["..cCCC..............CCCc.."]
    c.pattern(15, 20, wings, ["C": collar, "c": collarDark])
}

// MARK: - Doombot

/// A Doombot: Doctor Doom's robot stand-in, plainer and smaller, green-tinted grey armour, no cloak or hood, the
/// riveted Doom mask with glowing green eye slits and the grille mouth; blasts from its palm. Signature: its eyes
/// glitch and flicker and its head twitches.
private func drawDoombot(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x8A9690), dark = C(0x5E6A64), light = C(0xB8C4BC), green = C(0x3A6A3E), glow = C(0x5AFF7A)
    drawLegs(c, Look(leg: dark), step: p.step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 38, 2, 1, light) }               // knee joints
    c.oy += p.breathe
    let raised = p.fire != nil || p.gunLift != 0
    drawBody(c, Look(body: metal, shade: dark, arm: metal, eye: nil))
    // the domed skull cap and the mask
    c.pattern(18, 22, ["....MMMMMMMMMMMM....", "..MMLLMMMMMMMMMMMM..", ".MMLMMMMMMMMMMMMMMM.", "MMMMMMMMMMMMMMMMMMMM"],
              ["M": metal, "L": light])
    c.rect(18, 26, 20, 1, dark)
    c.rect(20, 27, 1, 6, dark); c.rect(35, 27, 1, 6, dark)                 // the edges of the mask
    c.rect(27, 26, 2, 6, light)                                              // the nose ridge
    for (x, y) in [(19, 27), (36, 27), (19, 32), (36, 32)] { c.px(x, y, dark) }   // rivets
    let twitch = p.signature.map { s in s > 0.1 && s < 0.9 && noise(Int(s * 30)) > 0.7 } ?? false
    if twitch { c.ox += 1 }
    let on = p.signature.map { s in !(s > 0.1 && s < 0.9) || noise(Int(s * 40) + 3) > 0.45 } ?? true
    c.rect(21, 29, 4, 1, ink); c.rect(31, 29, 4, 1, ink)                     // eye slits
    if on {
        c.rect(22, 29, 2, 1, glow); c.rect(32, 29, 2, 1, glow)
        if p.signature != nil {
            c.glowLine(22, 29.5, 24, 29.5, core: glow, glow: glow.alpha(0.5), coreR: 0.4, glowR: 1.6)
            c.glowLine(32, 29.5, 34, 29.5, core: glow, glow: glow.alpha(0.5), coreR: 0.4, glowR: 1.6)
        }
    }
    if twitch { c.ox -= 1 }
    c.rect(24, 32, 8, 2, dark)                                               // the grille
    for x in stride(from: 25, to: 32, by: 2) { c.rect(x, 32, 1, 2, ink) }
    c.rect(18, 34, 20, 4, green); c.rect(18, 37, 20, 1, C(0x2A4A2C))       // a green tunic under the armour…
    c.rect(18, 34, 20, 1, C(0x6A4A2A)); c.rect(26, 34, 4, 2, C(0xC8B04A))   // …belted, with the round buckle
    if let s = p.signature, s > 0.3, s < 0.7, noise(Int(s * 25)) > 0.5 { drawSparks(c, x: 36, y: 25, t: p.t, size: 2) }
    // the gauntlet: raised to fire from the palm
    if raised {
        c.oy += p.gunY
        c.rect(38, 33, 7, 3, metal); c.rect(38, 33, 7, 1, light)
        c.rect(45, 32, 2, 5, dark); c.px(46, 34, glow)
    } else {
        c.rect(38, 35, 3, 1, dark)
    }
}
