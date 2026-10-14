import Foundation

// Villains: gamma, Asgard's enemies and foot soldiers.

let villains8: [MarvelVillain: Persona] = [
    .countNefaria: Persona(name: "Count Nefarius", weapon: .blaster, shot: .energy(core: C(0xFFE0E0), glow: C(0xFF4A2A)),
                  muzzle: nefariaPalm, handGun: false, headTop: 22, signature: 2.8,
                  draw: drawCountNefaria),
    .theLeader: Persona(name: "The Leeder", weapon: .lightning, magic: Magic(core: C(0xF0FFE0), glow: C(0x8AE04A), jagged: false),
                  headTop: 4, signature: 3.0,
                  draw: drawTheLeader),
    .maestro: Persona(name: "Maestroh", weapon: .saber, canSit: false, pivot: maestroShoulder,
                  bulk: 5, headTop: 1, signature: 3.0,
                  draw: drawMaestro),
    .malekith: Persona(name: "Malekeith", weapon: .lightning, magic: Magic(core: C(0xF0F0FF), glow: C(0x6A6AFF), jagged: false),
                  headTop: 20, signature: 3.0,
                  draw: drawMalekith),
    .surtur: Persona(name: "Surt", weapon: .saber, armoured: true, canSit: false, pivot: surturShoulder,
                  bulk: 6, headTop: 1, signature: 3.2, callout: "I am the end of days.",
                  draw: drawSurtur),
    .kurse: Persona(name: "Kursed", weapon: .saber, armoured: true, pivot: kurseShoulder,
                  bulk: 3, headTop: 13, signature: 2.8,
                  draw: drawKurse),
    .frostGiant: Persona(name: "Frost Jötunn", weapon: .saber, canSit: false, pivot: frostShoulder,
                  bulk: 5, headTop: 1, signature: 3.0,
                  draw: drawFrostGiant),
    .hydraSuperSoldier: Persona(name: "Hydrax Super Soldier", weapon: .saber, armoured: true,
                  headTop: 20, signature: 2.8,
                  draw: drawHydraSuperSoldier),
    .kreeSoldier: Persona(name: "Kreek Soldier", weapon: .blaster, shot: .energy(core: C(0xE0F4FF), glow: C(0x3A9AFF)),
                  muzzle: (53, 31), headTop: 15, signature: 3.0,
                  draw: drawKreeSoldier),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A round-ended stroke from (`x0`, `y0`) to (`x1`, `y1`), `r` thick.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// A thick limb from `s` at `angle` degrees, `len` long and `r` thick. Returns where it ends.
@discardableResult
private func limb(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ angle: Double, len: Double, r: Double,
                  _ col: Px) -> (x: Double, y: Double) {
    let a = angle * .pi / 180
    let e = (x: s.x + cos(a) * len, y: s.y + sin(a) * len)
    line(c, s.x, s.y, e.x, e.y, col, r)
    return e
}

/// The smear a fast swing leaves behind: faint strokes at the earlier angles, from `r0` out to `len` from `s`.
private func smear(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ trail: [Double], from r0: Double, len: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * r0, s.y + sin(r) * r0, s.x + cos(r) * len, s.y + sin(r) * len,
                   core: col, glow: col, coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
}

/// A puff of breath, steam or smoke at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2.5).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.7 * (1 - k)))
}

/// Boots on the bottom of Clawd's four legs, following the walk cycle.
private func drawBoots(_ c: PixelCanvas, step: Int, _ col: Px, rows: Int = 2) {
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx + 2, 38, 1, 2, col) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// Roar lines: arcs spreading out from (`x`, `y`) to the right, `s` the signature clock.
private func roarLines(_ c: PixelCanvas, x: Int, y: Int, s: Double, _ col: Px) {
    for i in 0..<3 {
        let f = frac(s * 4 + Double(i) / 3), px = x + Int(f * 12), a = col.alpha(0.8 * (1 - f))
        for dy in -2 - i...(2 + i) where abs(dy) > 0 || i == 0 { c.px(px - abs(dy) / 2, y + dy, a) }
    }
}

// MARK: - Count Nefaria

/// Where Nefaria's ionic blasts leave his palm.
private let nefariaPalm = (x: 45.0, y: 33.5)

/// Count Nefaria: the aristocrat of crime, pale Clawd with slicked black hair (grey at the temples, a widow's peak),
/// a thin curled moustache, a dark three-piece suit with a white shirt-front and red cravat, and a black opera cape
/// with a red lining and a high collar. Fires ionic blasts from his bare hand. Signature: he lifts a hand and twirls
/// the tip of his moustache, which curls tighter and catches the light.
private func drawCountNefaria(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x26262F), suitDark = C(0x17171D), skin = C(0xEAC0A0), skinShade = C(0xC89878), trousers = C(0x44444F)
    let hair = C(0x16161B), grey = C(0x9A9AA4), cape = C(0x1C1C26), lining = C(0xB01E2A), shirt = C(0xC8C4BC)
    let ion = C(0xFF5A3A)
    let twirl = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: lining)
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, step: p.step, C(0x0E0E12))
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    // the suit, the shirt-front and cravat
    c.rect(18, 34, 20, 4, suit); c.rect(18, 37, 20, 1, suitDark); c.rect(37, 34, 1, 3, suitDark)
    c.pattern(26, 34, ["SRRS", "SRRS", ".RR."], ["S": shirt, "R": lining])
    c.px(25, 34, suitDark); c.px(30, 34, suitDark)                              // lapels
    // the high collar of the cape, standing up behind his head
    c.rect(15, 23, 3, 11, cape); c.rect(16, 24, 2, 9, lining)
    c.rect(38, 23, 2, 10, cape); c.rect(38, 24, 1, 8, lining)
    // slicked-back hair with a widow's peak and grey temples
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "GHHHHHHHHHHHHHHHHHHG",
        "GH......HHHH......HG",
        "G.........HH.......G",
    ], ["H": hair, "G": grey])
    c.rect(21, 28, 3, 1, hair); c.rect(32, 28, 3, 1, hair)                     // arched brows
    c.px(24, 27, hair); c.px(31, 27, hair)
    c.rect(22, 29, 2, 3, ink)
    if twirl > 0.5 { c.rect(32, 30, 2, 1, ink) } else { c.rect(32, 29, 2, 3, ink) }   // a knowing wink
    // the moustache: thick in the middle, waxed out to fine points
    c.rect(23, 32, 10, 1, hair); c.rect(25, 31, 6, 1, hair)
    c.px(22, 32, hair)
    if twirl > 0.05, let s = p.signature {
        // He rolls the right tip between finger and thumb; it winds tighter and catches the light.
        c.px(32, 32, hair); c.px(33, 32, hair)
        let tips: [(Int, Int)] = [(34, 31), (35, 30), (34, 30), (35, 31)]
        let k = tips[Int(s * 16) % 4]
        c.px(k.0, k.1, hair)
        let hx = Int((39 - 3 * twirl).rounded()), hy = Int((34 - 4 * twirl).rounded())
        line(c, 39.5, 34.5, Double(hx) + 1.5, Double(hy) + 1.5, suit, 1.1)      // the sleeve
        c.rect(hx, hy, 3, 2, skinShade); c.rect(hx + 1, hy, 2, 1, skin)        // finger and thumb
        c.px(hx + 1, hy + 2, shirt)                                             // a cuff
        if twirl > 0.6, Int(s * 10) % 3 == 0 { c.px(k.0 - 1, k.1 - 1, C(0xFFF2C0)) }
        return
    }
    c.px(33, 32, hair)
    // the hand: thrust forward crackling with ionic energy when he fires or stands ready
    let ready = p.fire != nil || p.gunLift != 0
    if ready {
        c.oy += p.gunY
        c.rect(38, 33, 5, 3, suit); c.rect(38, 35, 5, 1, suitDark)
        c.rect(42, 32, 3, 3, skin); c.px(45, 32, skin); c.px(45, 34, skin)
        let pulse = 0.6 + 0.4 * sin(p.t * 18)
        c.glowLine(nefariaPalm.x, nefariaPalm.y, nefariaPalm.x, nefariaPalm.y, core: C(0xFFE0D0).alpha(pulse),
                   glow: ion.alpha(0.8), coreR: 0.5, glowR: 2.2)
    } else {
        c.rect(38, 35, 3, 1, skin)
        if noise(Int(p.lt * 6)) > 0.8 { c.px(41, 34, ion.alpha(0.8)) }
    }
}

// MARK: - The Leader

/// The Leader: a green-skinned Clawd crowned by his enormous, elongated cranium, the brain's folds faintly showing
/// through, a smug narrow-eyed look and a purple jumpsuit with a high collar. Casts green psionic rays.
/// Signature: his brain pulses, the dome swells, its folds glow and rings of thought ripple out.
private func drawTheLeader(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x6AB04A), shade = C(0x4E8A36), light = C(0x9AD878), suit = C(0x5A2A7A), suitDark = C(0x3E1C56)
    let glow = C(0xC8FF7A)
    let pulse: Double = p.signature.map { s in habitArc(s, hold: 0.6) * (0.5 + 0.5 * sin(s * .pi * 10)) } ?? 0
    let swell = pulse > 0.5 ? 1 : 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, step: p.step, suitDark)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: shade, arm: suit, eye: nil), armRight: p.armRaise)
    // the great domed cranium, rising out of the body
    for y in (4 - swell)...27 {
        let hw: Double
        if y < 12 {
            let d = Double(12 - y) / Double(8 + swell)
            hw = (12 + Double(swell)) * max(0, 1 - d * d).squareRoot()
        } else {
            hw = 12 + Double(swell) - Double(y - 12) * (2 + Double(swell)) / 14
        }
        let l = Int((28 - hw).rounded()), r = Int((28 + hw).rounded())
        c.rect(l, y, r - l, 1, skin)
        c.px(r - 1, y, shade)
    }
    c.rect(19, 8, 2, 4, light); c.rect(21, 6, 3, 2, light)                     // shine
    // the brain's folds, faintly showing (glowing as it pulses)
    let fold = pulse > 0.05 ? glow.alpha(0.5 + 0.5 * pulse) : shade
    let folds: [(Int, Int, Int, Int)] = [(24, 7, 4, 1), (23, 8, 1, 2), (30, 6, 5, 1), (35, 7, 1, 2), (27, 11, 1, 3),
                                         (28, 14, 3, 1), (33, 11, 1, 3), (31, 10, 2, 1), (20, 15, 3, 1), (23, 16, 1, 2),
                                         (36, 15, 1, 3), (34, 18, 2, 1), (25, 19, 4, 1), (29, 20, 1, 2), (21, 20, 1, 2)]
    for f in folds { c.rect(f.0, f.1, f.2, f.3, fold) }
    if pulse > 0.05, let s = p.signature {                                      // rings of thought
        for i in 0..<2 {
            let f = frac(s * 3 + Double(i) * 0.5), r = 13 + f * 8
            for k in 0..<14 {
                let a = -.pi * (0.15 + 0.7 * Double(k) / 13)
                c.px(Int(28 + cos(a) * r), Int(14 + sin(a) * r * 0.85), glow.alpha(0.6 * (1 - f)))
            }
        }
    }
    // narrowed, superior eyes and a thin smile
    c.rect(21, 28, 4, 1, shade); c.rect(31, 28, 4, 1, shade)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(25, 32, 6, 1, C(0x2E5A22)); c.px(31, 31, C(0x2E5A22))
    // the jumpsuit and its high collar
    c.rect(18, 34, 20, 4, suit); c.rect(18, 37, 20, 1, suitDark); c.rect(37, 34, 1, 3, suitDark)
    c.rect(18, 33, 20, 1, suitDark)
    c.rect(26, 34, 4, 2, C(0xD8B040))                                           // a gold clasp
    c.rect(38, 35 - p.armRaise, 3, 1, skin)                                     // the casting hand
}

// MARK: - Maestro

/// Maestro's shoulder: his fist swings from here.
private let maestroShoulder = (x: 39.0, y: 17.0)

/// Maestro: the Hulk of a ruined future, old and gone bad, a huge green body, long grey hair and a full grey beard,
/// an open black leather coat over his bare chest, a belt with a heavy buckle, leather bracers. Fights with his fists.
/// Signature: a slow, nasty grin, then he cracks his neck to one side and the other.
private func drawMaestro(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5E9A48), dark = C(0x3E6E30), light = C(0x86BE6A), coat = C(0x24201E), coatLight = C(0x46403A)
    let hair = C(0xB4B4BC), hairDark = C(0x82828C), pants = C(0x3A3438), brown = C(0x6A4A2E)
    let grin = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    var tilt = 0, crack = false
    if let s = p.signature {
        if s > 0.35 && s < 0.55 { tilt = -2; crack = s < 0.43 }
        if s > 0.6 && s < 0.8 { tilt = 2; crack = s < 0.68 }
    }
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 30, 7, 13 - up, pants); c.rect(lx + 6, 30, 1, 13 - up, C(0x26222A))
        c.rect(lx - 1, 39 - up, 9, 5, C(0x16141A)); c.rect(lx - 1, 39 - up, 9, 1, coatLight)
    }
    c.oy += p.breathe
    // far arm
    c.rect(11, 17, 5, 15, dark); c.rect(10, 26, 6, 3, brown); c.rect(10, 31, 6, 4, dark)
    // the torso: a bare green chest in the open coat
    c.rect(15, 13, 25, 19, green)
    c.rect(24, 14, 10, 8, light); c.rect(28, 14, 1, 8, dark)                    // pecs
    c.rect(25, 23, 8, 1, dark); c.rect(25, 26, 8, 1, dark); c.rect(28, 22, 1, 8, dark)
    c.rect(15, 12, 9, 26, coat); c.rect(34, 12, 6, 26, coat)                     // the coat
    c.rect(23, 13, 1, 22, coatLight); c.rect(34, 13, 1, 22, coatLight)          // its lapels' edges
    c.rect(15, 12, 2, 26, coatLight)
    c.rect(15, 30, 25, 2, brown); c.rect(26, 29, 5, 4, C(0xA8A8B0)); c.rect(27, 30, 3, 2, brown)   // belt and buckle
    // the head, framed by long grey hair and the beard
    c.ox += tilt
    c.pattern(17, 0, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHGGGGGGGGGGGGGGHH.",
        ".HHHGGGGGGGGGGGGGGGGH.",
        "HHHHGGGGGGGGGGGGGGGGH.",
        "HHHHGGGGGGGGGGGGGGGGGH",
        "HHHHGGGGGGGGGGGGGGGGGH",
        "HHHHGGBBBBBBBBBBBBBGGH",
        "HHHHBBBBBBBBBBBBBBBBBH",
        "HHHHBBBBBBBBBBBBBBBBBH",
        "HhHH.BBBBBBBBBBBBBBB..",
        "HhHH..BBBBBBBBBBBBB...",
        "HhH....BBBBBBBBBBB....",
        "hh.......BBBBBBB......",
        "h..........BBB........",
    ], ["H": hair, "h": hairDark, "G": green, "B": hair])
    c.rect(23, 5, 4, 1, hairDark); c.rect(31, 5, 4, 1, hairDark)                // heavy brows
    c.rect(24, 6, 2, 2, ink); c.rect(32, 6, 2, 2, ink)
    c.rect(28, 3, 2, 1, dark)                                                   // a frown line
    if grin > 0.1 {                                                            // a wide, nasty grin
        let w = 6 + 2 * Int((grin * 2).rounded()), l = 29 - w / 2
        c.rect(l, 9, w, 3, C(0x3A1A14)); c.rect(l, 9, w, 1, C(0xF0E8D0)); c.rect(l + 1, 11, w - 2, 1, C(0xD8D0B8))
        c.px(l - 1, 8, C(0x3A1A14)); c.px(l + w, 8, C(0x3A1A14))
    } else {
        c.rect(26, 10, 6, 1, C(0x5A5A60))
    }
    c.rect(21, 13, 1, 3, hairDark); c.rect(25, 14, 1, 2, hairDark); c.rect(32, 13, 1, 3, hairDark)   // beard strands
    c.ox -= tilt
    if crack {                                                                 // *crack*
        let x = tilt < 0 ? 13 : 42, d = tilt < 0 ? -1 : 1
        for k in 0..<3 {
            let a = Double(k - 1) * 0.6
            line(c, Double(x), 9, Double(x) + Double(d) * cos(a) * 3, 9 + sin(a) * 3, C(0xFFE27A), 0.4)
        }
    }
    // the fist
    let angle = p.melee ?? 80
    smear(c, maestroShoulder, p.trail, from: 6, len: 20, C(0xD8F0C0))
    c.circle(38, 16, 3, coat)
    let e = limb(c, maestroShoulder, angle, len: 13, r: 2.3, green)
    let u = (x: cos(angle * .pi / 180), y: sin(angle * .pi / 180))
    line(c, e.x - u.x * 5, e.y - u.y * 5, e.x - u.x * 2, e.y - u.y * 2, brown, 2.4)   // the bracer
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 6, 6, green)
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 6, 1, light); c.rect(Int(e.x) - 3, Int(e.y) + 2, 6, 1, dark)
}

// MARK: - Malekith

/// Malekith the Accursed (the comics): a dark elf whose face is split down the middle, one half pale, one half a
/// deep midnight blue with a glowing eye, under a wild mane of white hair, pointed ears, a high-collared black and
/// violet tunic and a cape. Casts dark magic. Signature: the line where his face divides shimmers, light rippling
/// down the scar and across the dark half.
private func drawMalekith(_ c: PixelCanvas, _ p: Pose) {
    let pale = C(0xE6E4EC), paleShade = C(0xB8B4C4), night = C(0x283070), nightDark = C(0x1A1E4A)
    let hair = C(0xE8E8F0), hairShade = C(0xA8A8BC), tunic = C(0x1E1A2A), violet = C(0x5A3A9A), cape = C(0x161420)
    let shimmer = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    // the mane down his back
    c.oy += p.breathe
    c.pattern(11, 22, ["..HhH.......", ".HHHHHH.....", "HHHHHHH.....", "HHHhHHH.....", ".HHHHH......", "HHHHHh......",
                       ".HHHHH......", "HHhHH.......", ".HHH........", "HH.H........", ".H.........."],
              ["H": hair, "h": hairShade])
    c.oy -= p.breathe
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: violet)
    drawLegs(c, Look(leg: tunic), step: p.step)
    drawBoots(c, step: p.step, violet)
    c.oy += p.breathe
    drawBody(c, Look(body: pale, shade: paleShade, arm: tunic, eye: nil), armRight: p.armRaise)
    c.rect(28, 26, 10, 8, night); c.rect(37, 26, 1, 8, nightDark)                 // the dark half of his face
    c.px(28, 33, pale); c.px(29, 32, night)
    // pointed ears
    c.pattern(13, 26, ["PP...", ".PPP.", "..PPP"], ["P": paleShade])
    c.pattern(38, 26, ["...NN", ".NNN.", "NNN.."], ["N": nightDark])
    // wild white hair
    c.pattern(16, 19, [
        "....H..H....H...H.....",
        "...HHH.HHH.HHH.HHH.H..",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHhHHHHHHHHH",
        "HHHHHHHHhHHHHHHHHHhHHH",
        "HHH..HH.......HH...HHH",
        "HHH................HH.",
        "HH.................H..",
    ], ["H": hair, "h": hairShade])
    // eyes: an ordinary one, and a pale glowing one in the dark half
    c.rect(21, 28, 3, 1, C(0x5A5A6A)); c.rect(32, 28, 3, 1, C(0x8A8AE0))
    c.rect(22, 29, 2, 3, ink)
    c.rect(32, 29, 2, 3, C(0xE8E8FF)); c.glowLine(33, 30, 33, 30, core: C(0xE8E8FF), glow: C(0x6A6AFF).alpha(0.5), coreR: 0.4, glowR: 1.6)
    if shimmer > 0.05, let s = p.signature {
        // The scar line glows and light ripples across the dark half, ending in a flash from the eye.
        let beat: Double = 0.6 + 0.4 * sin(s * .pi * 12)
        c.glowLine(28, 26, 28, 33.5, core: C(0xD8D8FF).alpha(shimmer * beat), glow: C(0x6A6AFF).alpha(0.7 * shimmer),
                   coreR: 0.5, glowR: 1.8)
        let band = 28 + frac(s * 2.5) * 12
        for y in 26...33 {
            for x in 29...37 where abs(Double(x) + Double(y - 26) * 0.4 - band) < 1.2 {
                c.px(x, y, C(0xA8A8FF).alpha(0.75 * shimmer))
            }
        }
        for k in 0..<4 where noise(Int(s * 24) * 5 + k) > 0.45 {
            let x = 29 + Int(noise(Int(s * 24) * 7 + k) * 8), y = 26 + Int(noise(Int(s * 24) * 11 + k) * 8)
            c.px(x, y, C(0xE0E0FF).alpha(shimmer))
        }
        if shimmer > 0.9 { c.glowLine(33, 30, 33, 30, core: white, glow: C(0x8A8AFF), coreR: 0.6, glowR: 2.6 * beat) }
    }
    // the tunic, its high violet collar and belt
    c.rect(18, 34, 20, 4, tunic); c.rect(18, 37, 20, 1, C(0x0E0C16))
    c.rect(18, 34, 20, 1, violet); c.rect(27, 34, 2, 4, violet)
    c.rect(38, 35 - p.armRaise, 3, 1, pale)                                      // the casting hand
}

// MARK: - Surtur

/// Surtur's shoulder: the Twilight Sword swings from here.
private let surturShoulder = (x: 41.0, y: 21.0)
/// The same shoulder in his drawing coordinates (everything above the legs is drawn 3 px lower).
private let surturArm = (x: 41.0, y: 18.0)

/// Surtur: a fire demon filling the canvas, a body of black rock cracked through with molten lava, burning eyes and
/// mouth, a crown of great horns with flames licking between its spikes, and the Twilight Sword, a huge blade glowing
/// like a forge. Signature: his crown flares up into a tower of fire, embers whirling up off it.
private func drawSurtur(_ c: PixelCanvas, _ p: Pose) {
    let rock = C(0x2E2628), rockDark = C(0x1A1418), rockLight = C(0x4E4040)
    let lava = C(0xFF6A1E), hot = C(0xFFC23A), core = C(0xFFF0A0)
    let flare = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let beat: Double = 0.65 + 0.35 * sin(p.t * 3)
    let crackCol = (flare > 0.3 ? hot : lava).alpha(min(1, beat + flare))
    // legs
    for (i, lx) in [17, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 33, 8, 11 - up, rock); c.rect(lx + 7, 33, 1, 11 - up, rockDark)
        c.rect(lx - 1, 40 - up, 10, 4, rockDark); c.rect(lx - 1, 40 - up, 10, 1, rockLight)
        line(c, Double(lx) + 2, 35, Double(lx) + 4, 37, crackCol, 0.45); line(c, Double(lx) + 4, 36, Double(lx) + 3, 39, crackCol, 0.45)
    }
    c.oy += p.breathe + 3                          // the upper body sits lower, leaving room for the crown to flare
    // far arm
    c.rect(8, 16, 6, 14, rockDark); c.rect(7, 29, 8, 6, rock); c.rect(7, 29, 8, 1, rockLight)
    line(c, 10, 19, 11, 24, crackCol, 0.45)
    // the torso
    c.rect(13, 13, 30, 20, rock)
    c.rect(13, 13, 2, 20, rockLight); c.rect(41, 13, 2, 20, rockDark)
    c.rect(13, 31, 30, 3, rockDark)
    let cracks: [(Double, Double, Double, Double)] = [
        (18, 16, 22, 21), (22, 21, 20, 26), (20, 26, 23, 30), (22, 21, 27, 23), (31, 15, 29, 19), (29, 19, 33, 24),
        (33, 24, 31, 29), (33, 24, 38, 26), (37, 16, 39, 20), (26, 27, 28, 31), (15, 20, 17, 23),
    ]
    for k in cracks { line(c, k.0, k.1, k.2, k.3, crackCol, 0.5) }
    for k in cracks.prefix(4) where flare > 0.3 { line(c, k.0, k.1, k.2, k.3, core.alpha(flare * 0.8), 0.2) }
    // the head
    c.rect(20, 6, 17, 10, rock); c.rect(21, 15, 15, 2, rock)
    c.rect(35, 6, 2, 11, rockDark); c.rect(20, 6, 1, 10, rockLight)
    c.rect(22, 9, 4, 2, hot); c.rect(31, 9, 4, 2, hot)                            // burning eyes
    c.rect(23, 9, 2, 1, core); c.rect(32, 9, 2, 1, core)
    c.rect(21, 8, 5, 1, rockDark); c.rect(31, 8, 5, 1, rockDark)
    c.rect(24, 13, 9, 1, lava); c.rect(25, 14, 7, 1, hot.alpha(beat))            // the molten mouth
    // the crown: a band of spikes and two great horns
    c.rect(19, 5, 19, 2, rockLight)
    for x in [21, 24, 28, 32, 35] { c.rect(x, x == 28 ? 1 : 3, 1, x == 28 ? 4 : 2, rockLight); c.px(x, x == 28 ? 0 : 2, rock) }
    line(c, 20, 6, 15, 4, rockLight, 1.2); line(c, 15, 4, 12, 0.5, rockLight, 0.8)
    line(c, 37, 6, 42, 4, rockLight, 1.2); line(c, 42, 4, 45, 0.5, rockLight, 0.8)
    // flames licking between the spikes (a tower of them when the crown flares)
    for (k, x) in [22, 26, 30, 33].enumerated() {
        let h = 2 + Int(noise(Int(p.t * 10) + k * 7) * 2) + Int(flare * 8)
        for j in 0..<h {
            let w = max(1, 2 - j / 3), sway = Int((sin(p.t * 9 + Double(k + j)) * Double(j) / 4).rounded())
            c.rect(x + sway, 4 - j, w, 1, j < h / 3 ? core : (j < 2 * h / 3 ? hot : lava))
        }
    }
    if flare > 0.2, let s = p.signature {                                           // embers
        for i in 0..<6 {
            let f = frac(s * 3 + Double(i) / 6)
            let x = 18 + Int(noise(i * 13) * 22) + Int(sin(f * 9 + Double(i)) * 2), y = Int(6 - f * 7)
            if y >= 0 { c.px(x, y, (i % 2 == 0 ? hot : lava).alpha(1 - f)) }
        }
    }
    // the Twilight Sword
    let angle = p.melee ?? 78
    let r = angle * .pi / 180, u = (x: cos(r), y: sin(r))
    let arm = 6.0
    let blade = p.melee == nil ? 14.0 : 18.0 - 6 * max(0, -u.y)
    smear(c, surturArm, p.trail, from: arm + 3, len: arm + 3 + blade, hot)
    c.circle(40, 17, 3, rock)
    let h = limb(c, surturArm, angle, len: arm, r: 2.4, rock)
    c.rect(Int(h.x) - 2, Int(h.y) - 2, 5, 5, rockDark)
    line(c, h.x - u.y * 3, h.y + u.x * 3, h.x + u.y * 3, h.y - u.x * 3, rockLight, 0.7)   // the cross-guard
    c.glowLine(h.x + u.x * 2, h.y + u.y * 2, h.x + u.x * (2 + blade), h.y + u.y * (2 + blade),
               core: hot, glow: lava, coreR: 1.1, glowR: 2.6, strength: 0.9 + 0.1 * sin(p.t * 30))
    line(c, h.x + u.x * 3, h.y + u.y * 3, h.x + u.x * (blade - 1), h.y + u.y * (blade - 1), core, 0.3)
}

// MARK: - Kurse

/// Kurse's shoulder: his fist swings from here.
private let kurseShoulder = (x: 42.0, y: 27.0)

/// Kurse: the dark elf Algrim made into a brute, a broad, hulking Clawd in heavy blue-grey plate, a great horned
/// helmet with only a glowing red eye-slit and a fanged grille showing, a tattered dark red loincloth and an
/// armoured fist. Signature: he throws his head back and roars, eyes blazing.
private func drawKurse(_ c: PixelCanvas, _ p: Pose) {
    let plate = C(0x5A6070), dark = C(0x3A3E4A), light = C(0x8A92A4), red = C(0x8A1E22), eye = C(0xFF3A2A)
    let roar = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawLegs(c, Look(leg: dark), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {                            // heavy greaves
            let b = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx - 1, b - 3, 4, 4, plate); c.rect(lx - 1, b - 3, 4, 1, light)
        }
    }
    c.oy += p.breathe
    // the far arm
    c.rect(12, 28, 4, 7, plate); c.rect(11, 33, 5, 4, dark)
    // the bulky body
    c.rect(15, 24, 26, 14, plate)
    c.rect(15, 24, 2, 14, light); c.rect(39, 24, 2, 14, dark); c.rect(15, 37, 26, 1, dark)
    c.rect(18, 30, 20, 1, dark); c.rect(28, 25, 1, 5, dark)                     // plate seams
    c.rect(15, 33, 26, 2, C(0x2A2A30)); c.rect(26, 33, 4, 2, light)               // belt
    c.pattern(19, 35, ["RRRRRRRRRRRRRRRRR", ".RR.RRRR..RRRR.R.", "..R..RR....RR...."], ["R": red])
    // the helmet, tilted back as he roars
    let lift = Int((roar * 2).rounded())
    c.oy -= lift
    c.pattern(17, 14, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        "...HHHHHHHHHHHHHHHH...",
        "....HHHHHHHHHHHHHH....",
    ], ["H": plate])
    c.rect(20, 15, 3, 3, light); c.rect(27, 14, 2, 10, dark)                     // shine and ridge
    // horns sweeping out and forward
    line(c, 19, 17, 14, 15, light, 1.1); line(c, 14, 15, 12, 10, light, 0.8); line(c, 12, 10, 13, 7, light, 0.5)
    line(c, 37, 17, 42, 15, light, 1.1); line(c, 42, 15, 44, 10, light, 0.8); line(c, 44, 10, 43, 7, light, 0.5)
    // the eye-slit
    c.rect(20, 18, 16, 3, ink)
    let bright = 0.7 + 0.3 * roar
    c.rect(21, 19, 4, 1, eye.alpha(bright)); c.rect(31, 19, 4, 1, eye.alpha(bright))
    if roar > 0.3 {
        c.glowLine(22, 19.5, 24, 19.5, core: C(0xFFC8A0), glow: eye, coreR: 0.4, glowR: 1.5 + roar)
        c.glowLine(32, 19.5, 34, 19.5, core: C(0xFFC8A0), glow: eye, coreR: 0.4, glowR: 1.5 + roar)
    }
    // the fanged grille, gaping as he roars
    let gape = Int((roar * 3).rounded())
    c.rect(23, 22, 10, 2 + gape, C(0x2A0E10))
    for x in stride(from: 23, to: 33, by: 2) { c.px(x, 22, light); c.px(x + 1, 23 + gape, light) }
    if roar > 0.9, let s = p.signature { roarLines(c, x: 44, y: 23, s: s, C(0xF4EEE0)) }
    c.oy += lift
    // the armoured fist
    let angle = p.melee ?? 85
    smear(c, kurseShoulder, p.trail, from: 4, len: 13, C(0xD8DCE8))
    c.rect(38, 23, 6, 6, plate); c.rect(38, 23, 6, 1, light)                      // pauldron
    let e = limb(c, kurseShoulder, angle, len: 8, r: 1.8, dark)
    c.rect(Int(e.x) - 2, Int(e.y) - 2, 5, 5, plate)
    c.rect(Int(e.x) - 2, Int(e.y) - 2, 5, 1, light); c.rect(Int(e.x) - 2, Int(e.y) + 2, 5, 1, dark)
}

// MARK: - Frost Giant

/// The Frost Giant's shoulder: his ice club swings from here.
private let frostShoulder = (x: 39.0, y: 16.0)

/// A Frost Giant of Jotunheim (the movie look): a huge blue-skinned brute with raised tribal ridges on his skin, a
/// bald ridged head, burning red eyes, a dark leather kilt and fur boots, swinging a jagged club of ice.
/// Signature: he breathes out a long plume of frost glittering with ice crystals.
private func drawFrostGiant(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x5A8AC8), dark = C(0x3A62A0), light = C(0x8AB4E8), leather = C(0x3E2E26), leatherDark = C(0x2A1E18)
    let fur = C(0x8A7A68), eye = C(0xE8202A)
    let ice = C(0x9EE0F8), iceDark = C(0x5AA8D8), iceLight = C(0xD8F6FF)
    let breath = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 30, 7, 13 - up, blue); c.rect(lx + 6, 30, 1, 13 - up, dark)
        c.rect(lx + 2, 33, 1, 3, light)
        c.rect(lx - 1, 39 - up, 9, 5, fur); c.rect(lx - 1, 39 - up, 9, 1, C(0xA8988A))
    }
    c.oy += p.breathe
    // far arm
    c.rect(11, 17, 5, 16, dark); c.rect(10, 31, 6, 4, dark); c.rect(11, 22, 4, 3, leather)
    // the torso, with its ridged markings
    c.rect(15, 12, 25, 20, blue)
    c.rect(15, 12, 2, 20, dark); c.rect(38, 12, 2, 20, dark)
    for (x, y) in [(21, 15), (29, 15), (21, 19), (29, 19)] { c.rect(x, y, 5, 1, light); c.px(x + 2, y + 1, light) }
    c.rect(27, 14, 1, 14, light)
    for y in stride(from: 22, to: 29, by: 3) { c.rect(23, y, 9, 1, light) }
    // the leather kilt
    c.rect(15, 28, 25, 4, leather); c.rect(15, 28, 25, 1, leatherDark)
    for x in stride(from: 16, to: 40, by: 3) { c.rect(x, 32, 2, 3, leather) }
    // the head: bald and ridged, red eyes under a heavy brow
    c.pattern(20, 0, [
        "....BBBBBBBBBB....",
        "..BBBBBBBBBBBBBB..",
        ".BBBBBBBBBBBBBBBB.",
        "BBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBB",
        ".BBBBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBBBB..",
        "....BBBBBBBBBB....",
    ], ["B": blue])
    c.rect(37, 2, 1, 9, dark)
    c.rect(28, 0, 2, 3, light); c.rect(24, 1, 1, 2, light); c.rect(33, 1, 1, 2, light)   // ridges on the scalp
    c.rect(23, 4, 5, 1, dark); c.rect(31, 4, 5, 1, dark)                        // the brow
    c.rect(24, 5, 3, 2, eye); c.rect(32, 5, 3, 2, eye)
    c.px(25, 5, C(0xFF8A7A)); c.px(33, 5, C(0xFF8A7A))
    let gape = Int((breath * 2).rounded())
    c.rect(26, 9, 7, 1 + gape, C(0x1E2A4A))
    if breath > 0.2, let s = p.signature {
        // A plume of frost rolling out of his mouth, glittering.
        for i in 0..<7 {
            let f = frac(s * 3 + Double(i) / 7)
            let x = 34 + f * 30, y = 9.5 + Double(gape) / 2 + sin(f * 6 + Double(i)) * f * 3
            let r = 1 + f * 3.5
            c.glowLine(x, y, x, y, core: iceLight.alpha(0.55 * breath * (1 - f)), glow: ice.alpha(0.5 * breath * (1 - f)),
                       coreR: r * 0.5, glowR: r)
        }
        for k in 0..<5 where noise(Int(s * 20) * 3 + k) > 0.4 {
            c.px(38 + Int(noise(Int(s * 20) * 7 + k) * 22), 6 + Int(noise(Int(s * 20) * 5 + k) * 8), iceLight.alpha(0.9))
        }
    }
    // the ice club
    let angle = p.melee ?? 78
    let r = angle * .pi / 180, u = (x: cos(r), y: sin(r))
    smear(c, frostShoulder, p.trail, from: 10, len: 29, ice)
    c.circle(38, 15, 3, blue)
    let h = limb(c, frostShoulder, angle, len: 10, r: 2.2, blue)
    c.rect(Int(h.x) - 2, Int(h.y) - 2, 5, 5, dark)
    let len = p.melee == nil ? 14.0 : 18.0 - 4 * max(0, -u.y)
    for k in 0..<4 {                                                             // a thickening shaft of ice
        let a = 2 + len * Double(k) / 4, b = 2 + len * Double(k + 1) / 4
        line(c, h.x + u.x * a, h.y + u.y * a, h.x + u.x * b, h.y + u.y * b, k == 0 ? iceDark : ice, 0.8 + Double(k) * 0.55)
    }
    for k in 1...3 {                                                             // jagged spikes off the head
        let a = 2 + len * (0.5 + Double(k) * 0.15), side: Double = k % 2 == 0 ? 1 : -1
        let bx = h.x + u.x * a, by = h.y + u.y * a
        line(c, bx, by, bx - u.y * side * 4 + u.x * 2, by + u.x * side * 4 + u.y * 2, iceDark, 0.5)
    }
    line(c, h.x + u.x * (len * 0.5), h.y + u.y * (len * 0.5), h.x + u.x * (len + 1), h.y + u.y * (len + 1), iceLight, 0.3)
}

// MARK: - Hydra Super Soldier

/// A Hydra super soldier: a heavier, elite trooper in black body armour with red shoulder plates, a full black
/// helmet with a red T-visor, the red Hydra skull on the chest, and an electrified stun baton crackling red.
/// Signature: baton tucked away, both fists thrown up (Hail Hydra) as the visor flares.
private func drawHydraSuperSoldier(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1E1E24), dark = C(0x121216), light = C(0x4A4A56), armour = C(0x3A3A46), red = C(0xC8202A), redDark = C(0x8A141C)
    let glow = C(0xFF3A2A)
    let salute = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: armour), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 38, 2, 1, redDark) } }               // knee guards
    drawBoots(c, step: p.step, dark, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: armour, shade: dark, arm: armour, eye: nil))
    c.rect(18, 26, 20, 2, black); c.rect(19, 28, 18, 3, black); c.rect(25, 31, 6, 2, black)   // the faceplate
    // the helmet
    c.pattern(17, 20, ["....HHHHHHHHHHHH....", "..HHHHHHHHHHHHHHHH..", ".HHHHHHHHHHHHHHHHHH.", ".HHHHHHHHHHHHHHHHHHH",
                       "HHHHHHHHHHHHHHHHHHHHH", "HHHHHHHHHHHHHHHHHHHHH"], ["H": black])
    c.rect(20, 21, 4, 2, light)
    // the T-visor
    let flare = salute > 0.3 ? 0.6 + 0.4 * sin(p.t * 20) : 0
    c.rect(20, 28, 16, 2, red); c.rect(27, 30, 2, 3, red)
    c.rect(20, 28, 16, 1, glow.alpha(0.6 + 0.4 * flare))
    if flare > 0 { c.glowLine(20, 28.5, 35, 28.5, core: C(0xFFB0A0), glow: glow, coreR: 0.4, glowR: 1.8, strength: flare) }
    // armour: chest plate with the Hydra skull, red pauldrons, a belt
    c.rect(19, 33, 18, 1, light)
    c.pattern(25, 34, [".RRRR.", "RKRRKR", ".RRRR.", "R.RR.R"], ["R": red, "K": dark])
    c.rect(16, 31, 4, 3, red); c.rect(16, 33, 4, 1, redDark)
    c.rect(18, 37, 20, 1, C(0x3A3A44))
    if salute > 0 {
        // Both fists up: Hail Hydra.
        c.rect(15, 35, 3, 2, C(0x2A2A30)); c.rect(14, 34, 1, 4, glow.alpha(0.7))      // baton on the hip
        let up = 11 * salute
        line(c, 39.5, 34, 41 + 3 * salute, 34 - up, black, 1)
        line(c, 16.5, 34, 15 - 3 * salute, 34 - up, black, 1)
        c.rect(Int(41 + 3 * salute) - 1, Int(34 - up) - 2, 3, 3, red)
        c.rect(Int(15 - 3 * salute) - 1, Int(34 - up) - 2, 3, 3, red)
        return
    }
    c.rect(36, 31, 4, 3, red); c.rect(36, 33, 4, 1, redDark)
    // the stun baton
    let angle = p.melee ?? 80
    let r = angle * .pi / 180, u = (x: cos(r), y: sin(r)), hnd = Sprite.hand
    smear(c, hnd, p.trail, from: 3, len: 13, glow)
    line(c, hnd.x - u.x * 2, hnd.y - u.y * 2, hnd.x + u.x * 11, hnd.y + u.y * 11, C(0x34343C), 0.7)
    line(c, hnd.x - u.x * 2, hnd.y - u.y * 2, hnd.x + u.x * 1.5, hnd.y + u.y * 1.5, light, 0.75)
    let lit = p.melee != nil
    let tip = (x: hnd.x + u.x * 11, y: hnd.y + u.y * 11)
    c.glowLine(tip.x - u.x * 3, tip.y - u.y * 3, tip.x, tip.y, core: C(0xFFC8B8), glow: glow, coreR: 0.6,
               glowR: lit ? 1.8 + noise(Int(p.t * 25)) : 1.2, strength: lit ? 1 : 0.6)
    if lit && noise(Int(p.t * 20)) > 0.6 {
        let a = noise(Int(p.t * 20) + 3) * 2 * .pi
        c.px(Int(tip.x + cos(a) * 3), Int(tip.y + sin(a) * 3), C(0xFFB0A0))
    }
    c.rect(38, 33, 3, 3, red)                                                       // the gloved hand
}

// MARK: - Kree Soldier

/// A Kree soldier in the green-and-blue uniform of Captain Marvel's original Kree: a blue-skinned Clawd in a green
/// helmet with the tall Kree fin, a green tunic with blue chest and shoulder armour, a blue belt and boots, and a
/// long energy rifle with a glowing power cell. Signature: he stands the rifle up and checks its charge, the cell's
/// bars light up one by one, then flash full.
private func drawKreeSoldier(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A8A4A), greenDark = C(0x266A34), greenLight = C(0x5AB06A)
    let blue = C(0x2A4AB0), blueDark = C(0x1C3480), skin = C(0x6A9AD8), skinShade = C(0x4A78B8)
    let gun = C(0x3A3E48), gunDark = C(0x24262E), gunLight = C(0x8A90A0), cell = C(0x5AC8FF)
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, step: p.step, blue, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: green, eye: nil))
    // the helmet, with its tall fin, and the face opening below it
    c.pattern(17, 22, ["...GGGGGGGGGGGGGG...", ".GGGGGGGGGGGGGGGGGG.", "GGGGGGGGGGGGGGGGGGGG", "GGGGGGGGGGGGGGGGGGGG",
                       "GGG..............GGG", "GG................GG", "GG................GG"], ["G": green])
    c.rect(19, 23, 4, 1, greenLight)
    c.pattern(25, 15, ["..FF..", ".FFFF.", ".FFFF.", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF"], ["F": blue])
    c.rect(26, 16, 1, 6, C(0x4A6AD0))
    c.rect(17, 25, 21, 1, blueDark)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, skinShade); c.rect(32, 28, 3, 1, skinShade)
    // the tunic, blue chest armour with its Kree star and belt
    c.rect(18, 33, 20, 5, green); c.rect(18, 37, 20, 1, greenDark)
    c.rect(21, 33, 14, 3, blue); c.rect(21, 35, 14, 1, blueDark)
    c.pattern(27, 33, [".Y.", "YYY"], ["Y": C(0xE8C83A)])
    c.rect(16, 32, 4, 3, blue); c.rect(36, 32, 4, 3, blue)
    c.rect(18, 36, 20, 1, blueDark)
    if let s = p.signature, s > 0.08, s < 0.92 {
        // The rifle stood upright before him, its cell filling bar by bar.
        let k = min(1, max(0, (s - 0.2) / 0.5))
        c.rect(41, 13, 1, 6, gunDark); c.px(41, 12, cell)                         // the barrel, pointing up
        c.rect(40, 19, 3, 12, gun); c.rect(40, 19, 1, 12, gunLight); c.rect(38, 21, 2, 3, gunDark)   // body and scope
        c.rect(40, 31, 4, 5, gunDark); c.rect(42, 29, 2, 2, gunDark)              // grip and stock
        c.rect(43, 21, 2, 10, gunDark)                                             // the power cell housing
        let bars = Int((k * 4).rounded(.down))
        let full = s > 0.72
        for b in 0..<4 {
            let on = b < bars || full
            c.rect(43, 29 - b * 2, 1, 1, on ? (full && Int(s * 20) % 2 == 0 ? C(0xE0F8FF) : cell) : C(0x1A2A3A))
        }
        if full { c.glowLine(43.5, 23, 43.5, 29.5, core: cell.alpha(0.7), glow: cell.alpha(0.4), coreR: 0.4, glowR: 1.8) }
        c.rect(38, 33, 3, 3, green); c.rect(39, 32, 2, 2, skin)
        return
    }
    // the energy rifle
    c.oy += p.gunY
    c.pattern(36, 29, [
        ".....SSSS.........",
        "GGGGGGGGGGGGGGGGG.",
        "GGGGCCCCGGGGGGGGGG",
        "..GG...GG.........",
        "..GG..............",
    ], ["G": gun, "S": gunDark, "C": cell])
    c.rect(36, 30, 17, 1, gunLight.alpha(0.5))
    c.px(53, 31, cell)
    c.rect(38, 32, 3, 2, skin)
}
