import Foundation

// Villains: cosmic and Avengers foes.

let villains1: [MarvelVillain: Persona] = [
    .thanos: Persona(name: "Thanoz", weapon: .lightning, magic: Magic(core: C(0xF4E0FF), glow: C(0xA040FF), jagged: false),
                  pivot: (42.5, 31.5), bulk: 2, headTop: 12, signature: 3.2, callout: "I am unavoidable.",
                  draw: drawThanos),
    .loki: Persona(name: "Lokee", weapon: .lightning, magic: Magic(core: C(0xE0FFE8), glow: C(0x3AD06A), jagged: false),
                  pivot: (41.5, 24.5), headTop: 5, signature: 3.0, callout: "I am weighed down by magnificent intent.",
                  draw: drawLoki),
    .ultron: Persona(name: "Ultraton", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFE0E0), glow: C(0xFF2A2A)), armoured: true,
                  muzzle: (44, 33), handGun: false, headTop: 18, signature: 2.6,
                  draw: drawUltron),
    .redSkull: Persona(name: "Red Skulk", weapon: .blaster, shot: .energy(core: C(0xE0F4FF), glow: C(0x3A9AFF)),
                  muzzle: (47, 32), headTop: 22, signature: 3.0,
                  draw: drawRedSkull),
    .doctorDoom: Persona(name: "Doctor Gloom", weapon: .lightning, magic: Magic(core: C(0xE0FFE0), glow: C(0x3AE05A), jagged: false), armoured: true,
                  headTop: 19, signature: 2.8, callout: "Kneel before Gloom!",
                  draw: drawDoctorDoom),
    .hela: Persona(name: "Hel", weapon: .saber, headTop: 10, signature: 3.2,
                  draw: drawHela),
    .ronan: Persona(name: "Ronnan the Accuser", weapon: .saber, headTop: 13, signature: 2.6,
                  draw: drawRonan),
    .nebula: Persona(name: "Nebulah", weapon: .saber, headTop: 22, signature: 2.4,
                  draw: drawNebula),
    .ebonyMaw: Persona(name: "Ebony Jaw", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xF0F0FF), glow: C(0xA8A0FF), jagged: false),
                  headTop: 12, signature: 3.0,
                  draw: drawEbonyMaw),
    .chitauri: Persona(name: "Chitari", weapon: .blaster, shot: .energy(core: C(0xE8F8FF), glow: C(0x5AC8FF)), armoured: true,
                  muzzle: (58, 32), headTop: 18,
                  draw: drawChitauri),
    .grandmaster: Persona(name: "Grandmeister", headTop: 18, signature: 3.2, callout: "Ha ha! Adore it!",
                  draw: drawGrandmaster),
    .ultronSentry: Persona(name: "Ultraton Sentry", weapon: .blaster, motion: .hover, shot: .energy(core: C(0xFFE0E0), glow: C(0xFF2A2A)), armoured: true, canSit: false,
                  muzzle: (43, 32), handGun: false, headTop: 22,
                  draw: drawUltronSentry),
]

// MARK: - Helpers

private let clear = C(0, 0)

/// A solid line `r` thick: staffs, shafts, horns.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// Faint smears behind a fast melee swing, `from`…`to` pixels out from `pivot`.
private func swingTrail(_ c: PixelCanvas, _ pivot: (x: Double, y: Double), _ trail: [Double], from: Double, to: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(pivot.x + cos(r) * from, pivot.y + sin(r) * from, pivot.x + cos(r) * to, pivot.y + sin(r) * to,
                   core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// Tints a scatter of everything drawn so far: a magical shimmer running over the sprite.
private func shimmer(_ c: PixelCanvas, _ col: Px, amount: Double, seed: Int) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<c.h {
        for x in 0..<c.w where c.isDrawn(x, y) && noise(seed * 977 + y * 72 + x) < amount {
            c.px(x, y, col.alpha(0.8))
        }
    }
}

/// "HA" in a tiny 3×5 pixel font, its top-left at (x, y).
private func drawHa(_ c: PixelCanvas, x: Int, y: Int, _ col: Px) {
    c.pattern(x, y, ["H.H.AAA", "H.H.A.A", "HHH.AAA", "H.H.A.A", "H.H.A.A"], ["H": col, "A": col])
}

// MARK: - Thanos

/// Thanos: a big purple Clawd in the comics' blue and gold, the finned gold helmet, the grooved chin, gold boots
/// and the Infinity Gauntlet on his casting hand. Signature: he raises the Gauntlet high, the six stones light one
/// after another, and he snaps.
private func drawThanos(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8E62B0), skinDark = C(0x6A4490), suit = C(0x2E4FA8), suitDark = C(0x1E3878)
    let gold = C(0xF0BE3A), goldDark = C(0xB8862A), goldLight = C(0xFFE49A)
    for (i, lx) in [17, 22, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, gold); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, suitDark)
        c.rect(lx, lifted ? 40 : 41, 3, 3, gold)
        c.px(lx, lifted ? 40 : 41, goldLight)
    }
    c.oy += p.breathe

    var raise = p.armRaise, lit = 0
    var snap: Double?
    if let s = p.signature {
        raise = Int((habitArc(s, hold: 0.62) * 19).rounded())
        lit = max(0, min(6, Int((s - 0.24) / 0.045)))
        if s > 0.56 && s < 0.8 { snap = (s - 0.56) / 0.24 }
    }

    // The big body: purple face, blue armour, gold belt.
    c.rect(16, 20, 24, 18, skin)
    c.rect(39, 20, 1, 11, skinDark)
    c.rect(16, 31, 24, 7, suit)
    c.rect(16, 31, 24, 1, suitDark)
    c.rect(39, 31, 1, 7, suitDark)
    c.rect(16, 34, 24, 2, gold); c.rect(16, 35, 24, 1, goldDark)
    c.rect(26, 34, 4, 2, goldLight)
    c.rect(16, 37, 24, 1, suitDark)
    c.rect(21, 23, 2, 3, ink); c.rect(33, 23, 2, 3, ink)                 // eyes under the heavy brow
    c.rect(20, 22, 4, 1, skinDark); c.rect(32, 22, 4, 1, skinDark)
    c.rect(25, 27, 7, 1, skinDark)                                      // the grim mouth…
    for x in [23, 26, 29, 32] { c.rect(x, 29, 1, 2, skinDark) }         // …and the grooved chin
    // Shoulder plates and the bare left fist.
    c.rect(13, 30, 4, 3, gold); c.rect(13, 30, 4, 1, goldLight)
    c.rect(12, 33, 4, 3, suit); c.rect(12, 35, 4, 1, suitDark)
    c.rect(39, 30, 3, 2, gold)

    // The helmet: a gold dome with swept fins and cheek guards.
    c.pattern(14, 12, [
        "..........GGGGGGGG..........",
        "........GGGGLLGGGGGG........",
        "......GGGLLGGGGGGGGGGG......",
        ".....GGGLLGGGGGGGGGGGGG.....",
        "G...GGGGLGGGGGGGGGGGGGGG...G",
        "GG..GGGGGGGGGGGGGGGGGGGG..GG",
        ".GG.GGGGGGGGGGGGGGGGGGGG.GG.",
        "..GGGGGGGGGGGGGGGGGGGGGGGG..",
        "..GGGDDDDDDDDDDDDDDDDDDGGG..",
        "..GGG..................GGG..",
        "..GGG..................GGG..",
        "..GGG..................GGG..",
        "..GGD..................DGG..",
        "...GD..................DG...",
    ], ["G": gold, "D": goldDark, "L": goldLight])
    c.rect(27, 20, 2, 2, goldDark)                                      // the brow ridge's point

    // The Infinity Gauntlet, raised `raise` px (the arm shows when it's lifted high).
    let hx = 40, hy = 30 - raise
    if raise > 3 { c.rect(40, hy + 4, 3, 30 - hy - 2, suit); c.rect(42, hy + 4, 1, 30 - hy - 2, suitDark) }
    c.rect(hx, hy, 5, 5, gold)
    c.rect(hx, hy + 4, 5, 1, goldDark)
    c.rect(hx + 4, hy, 1, 5, goldDark)
    let stones = [C(0x3A7BFF), C(0xFF2A3A), C(0xB040FF), C(0xFFE03A), C(0x3AE060), C(0xFF9A2A)]
    let spots = [(hx, hy), (hx + 1, hy), (hx + 2, hy), (hx + 2, hy + 2), (hx + 3, hy), (hx, hy + 3)]
    for (i, s) in stones.enumerated() {
        let (x, y) = spots[i]
        c.px(x, y, s)
        if i < lit { c.glowLine(Double(x) + 0.5, Double(y) + 0.5, Double(x) + 0.5, Double(y) + 0.5, core: white, glow: s, coreR: 0.4, glowR: 2) }
    }
    if let f = snap {
        // The snap: a white flash bursting from the fingers.
        let cx = Double(hx) + 2.5, cy = Double(hy) + 0.5
        c.glowLine(cx, cy, cx, cy, core: white.alpha(1 - f), glow: C(0xFFE08A).alpha(1 - f), coreR: 1 + f * 3, glowR: 3 + f * 6)
        for k in 0..<8 {
            let a = Double(k) * .pi / 4, r0 = 3 + f * 5, r1 = 5 + f * 9
            c.glowLine(cx + cos(a) * r0, cy + sin(a) * r0, cx + cos(a) * r1, cy + sin(a) * r1,
                       core: white.alpha(1 - f), glow: clear, coreR: 0.5, glowR: 0.6)
        }
    }
}

// MARK: - Loki

/// Loki: the classic green and gold, a pale face framed by black hair and the gold helmet with its long curling
/// horns, a green cape, and the sceptre's blue gem as his casting point. Signature: a green shimmer runs over him
/// and he turns into a snake (it was him, he was the snake), then back.
private func drawLoki(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x1E7A3A), greenDark = C(0x145A2A), gold = C(0xE8B530), goldDark = C(0xA8801E), goldLight = C(0xFFE08A)
    let skin = C(0xEAD9C6), skinDark = C(0xC8B49E), hair = C(0x16161B)
    let seed = Int(p.t * 24)
    if let s = p.signature, s > 0.28, s < 0.78 {
        drawLokiSnake(c, t: p.lt)
        if s < 0.36 || s > 0.7 { shimmer(c, C(0x6AF08A), amount: 0.45, seed: seed) }
        return
    }
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: greenDark, edge: C(0x0C3418))
    drawLegs(c, Look(leg: C(0x1A2A1E)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {             // gold boots
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, lifted ? 40 : 41, 2, 3, gold)
        }
    }
    c.oy += p.breathe
    c.rect(16, 25, 3, 10, hair); c.rect(37, 25, 3, 8, hair)            // long black hair to the shoulders
    drawBody(c, Look(body: skin, shade: skinDark, arm: green))
    c.rect(18, 33, 20, 5, green)
    c.rect(18, 33, 20, 1, gold)
    c.rect(37, 33, 1, 5, greenDark)
    c.rect(27, 34, 2, 4, gold)
    c.rect(18, 37, 20, 1, greenDark)
    c.rect(24, 32, 8, 1, skinDark)                                     // the smirk
    c.px(31, 31, skinDark)

    // Horns, then the helmet over them.
    let horns: [[(Double, Double)]] = [
        [(21, 22), (17, 18), (15, 13), (15, 9), (17, 5)],
        [(35, 22), (39, 18), (41, 13), (41, 9), (39, 5)],
    ]
    for h in horns {
        for i in 0..<(h.count - 1) {
            let r = [1.3, 1.1, 0.8, 0.6][i]
            stick(c, h[i].0, h[i].1, h[i + 1].0, h[i + 1].1, gold, r)
        }
        stick(c, h[1].0, h[1].1 - 1, h[2].0, h[2].1 - 1, goldLight, 0.4)
    }
    c.pattern(17, 20, [
        "....GGGGGGGGGGGGGG....",
        "..GGGGGGGGGGGGGGGGGG..",
        ".GGGLLGGGGGGGGGGGGGGG.",
        ".GGLLGGGGGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGGGGGGGG",
        "GGGDDDDDDDGGDDDDDDDGGG",
        "GGG.......GG.......GGG",
        "GGG.......GG.......GGG",
        ".GG................GG.",
        ".GG................GG.",
        "..G................G..",
    ], ["G": gold, "D": goldDark, "L": goldLight])

    // The sceptre in his hand, gem at the top.
    let r = p.armRaise
    stick(c, 41.5, Double(26 - r), 41.5, Double(41 - r), gold, 0.6)
    c.pattern(39, 22 - r, ["G...G", "GG.GG", ".GBG.", "..G.."], ["G": gold, "B": C(0x5AB8FF)])
    c.px(41, 24 - r, C(0xC8ECFF))
    c.rect(38, 33 - r, 3, 3, green)
    if let s = p.signature, s > 0.18 && s < 0.28 || s > 0.78 && s < 0.88 {
        shimmer(c, C(0x6AF08A), amount: 0.4, seed: seed)
    }
}

/// Loki as a little green snake, coiled on the floor with its head raised and tongue flicking.
private func drawLokiSnake(_ c: PixelCanvas, t: Double) {
    let flick = Int(t * 6) % 3 != 0
    c.pattern(18, 31, [
        "................SSSS....",
        "...............SSYSSS...",
        "...............SSSSSSS..",
        "...............SSS......",
        "..............SSS.......",
        ".............SSs........",
        ".............SSs........",
        "......SSSSSSSSSs........",
        "...SSSsssssssSSSSS......",
        "..SSsSSSSSSSSSSsSSS.....",
        "..SSSSSSgSSSgSSSSSSs....",
        "...SSSSSSSSSSSSSSSS.....",
        "....ssssssssssssss......",
    ], ["S": C(0x2E9A4A), "s": C(0xC8D87A), "Y": C(0xFFE03A), "g": C(0x1E6A32)])
    if flick { c.pattern(41, 32, ["..R", "RR.", "..R"], ["R": C(0xE0303A)]); }
}

// MARK: - Ultron

/// Ultron: a chrome Clawd with the comic robot's domed, ridged head, slanted red eyes and a jagged glowing mouth;
/// he blasts from his palm and flies on jets in his feet. Signature: he tilts his head, and his eyes and mouth
/// flare up red.
private func drawUltron(_ c: PixelCanvas, _ p: Pose) {
    let chrome = C(0xB8BEC8), dark = C(0x7A808C), light = C(0xE6EAF0), red = C(0xFF2A2A), hot = C(0xFFD8D0)
    if p.flying {
        for lx in [19, 23, 31, 35] { c.rect(lx, 36, 2, 4, dark) }
        let flick = Int(p.t * 20) % 2
        for lx in [19, 23, 31, 35] {
            c.glowLine(Double(lx) + 1, 40.5, Double(lx) + 1, 42.5 + Double(flick), core: C(0xFFF0C0), glow: C(0xFF8A2A), coreR: 0.5, glowR: 1.4)
        }
    } else {
        drawLegs(c, Look(leg: dark), step: p.step)
    }
    c.oy += p.breathe
    let k = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let tilt = k > 0.5 ? 1 : 0

    c.rect(16, 27, 2, 5, dark); c.rect(38, 27, 2, 5, dark)              // the ear pieces
    drawBody(c, Look(body: chrome, shade: dark, arm: chrome, eye: nil))
    c.pattern(18 - tilt, 18 + tilt, [
        "........dddd........",
        "......ddCLLCdd......",
        ".....dCCLLCCCCd.....",
        "....dCCLCCdCCCCd....",
        "...dCCCCCCdCCCCCd...",
        "..dCCCCCCCdCCCCCCd..",
        ".dCCCCCCCCdCCCCCCCd.",
        "dCCCCCCCCCdCCCCCCCCd",
    ], ["C": chrome, "d": dark, "L": light])
    c.rect(20, 31, 1, 5, dark); c.rect(35, 31, 1, 5, dark)               // the cheek grooves
    c.rect(19, 27, 3, 1, light)
    // Slanted eyes (one higher when his head tilts) and the jagged mouth.
    let eyeL = [(21, 29), (22, 29), (23, 30), (24, 30)], eyeR = [(31, 30), (32, 30), (33, 29), (34, 29)]
    let glowS = 0.35 + 0.65 * k
    for (i, e) in (eyeL + eyeR).enumerated() {
        let y = e.1 + (i < 4 ? -tilt : tilt)
        c.glowLine(Double(e.0) + 0.5, Double(y) + 0.5, Double(e.0) + 0.5, Double(y) + 0.5, core: red, glow: red, coreR: 0.5, glowR: 1.2 + k, strength: glowS)
        c.px(e.0, y, k > 0.3 && i % 4 != 0 && i % 4 != 3 ? white : red)
        if i == 1 || i == 6 { c.px(e.0, y, hot) }
    }
    let open = Int((k * 2).rounded())
    c.rect(23, 33, 10, 1 + open, C(0x5A0A0A))
    for x in stride(from: 23, to: 33, by: 2) { c.px(x, 33 + (x / 2) % 2 * open, red); c.px(x + 1, 33, hot) }
    if k > 0 { c.glowLine(28, 33.5 + Double(open) / 2, 28, 33.5 + Double(open) / 2, core: clear, glow: red, coreR: 0, glowR: 4 * k, strength: 0.5) }

    // The blasting hand: thrust out with the palm glowing when firing or ready.
    if p.fire != nil || p.ready {
        c.rect(38, 32 + p.gunY, 5, 3, chrome); c.rect(38, 34 + p.gunY, 5, 1, dark)
        c.rect(43, 32 + p.gunY, 1, 3, red); c.px(43, 33 + p.gunY, hot)
    } else {
        c.px(40, 34, red)
    }
}

// MARK: - Red Skull

/// Red Skull: the grinning red skull (black sockets, a nose hole and bared teeth) on a black officer's coat,
/// with a Hydra pistol that fires blue Tesseract energy. Signature: he holds the Tesseract up, glowing blue.
private func drawRedSkull(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8322A), redDark = C(0x9A221C), redLight = C(0xE45A48), coat = C(0x1E1E24), coatLight = C(0x3A3A44)
    drawLegs(c, Look(leg: coat), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: redDark, arm: coat, eye: nil))
    c.pattern(18, 23, [
        "...RRRRRRRRRRRRRR...",
        ".RRRLLRRRRRRRRRRRRR.",
        "RRRLRRRRRRRRRRRRRRRR",
    ], ["R": red, "L": redLight])
    c.rect(37, 24, 1, 3, redDark)
    c.rect(20, 27, 5, 1, redDark); c.rect(30, 27, 5, 1, redDark)         // brow ridges
    c.pattern(20, 28, ["KKKKK.....KKKKK", "KKrKK.....KKKrK", ".KKK.......KKK."], ["K": ink, "r": C(0xFF6A3A)])
    c.rect(26, 31, 3, 1, ink); c.px(27, 32, ink)                        // the nose hole
    c.rect(20, 31, 3, 1, redDark); c.rect(33, 31, 3, 1, redDark)        // cheekbones
    c.pattern(22, 33, ["KWKWKWKWKWK", ".KKKKKKKKK."], ["K": ink, "W": C(0xF0E6D0)])   // the grin
    c.rect(18, 33, 2, 2, coat); c.rect(36, 33, 2, 2, coat); c.px(20, 34, coat); c.px(35, 34, coat)   // the jaw narrows
    // The coat: black, high collar.
    c.rect(18, 35, 20, 3, coat)
    c.pattern(18, 34, ["CC................CC", ".CC..............CC."], ["C": coatLight])
    c.rect(21, 36, 1, 1, C(0x8A8F9C)); c.rect(34, 36, 1, 1, C(0x8A8F9C))
    c.rect(15, 33, 3, 3, coat)

    if let s = p.signature {
        // Signature: the Tesseract, lifted high in his right hand.
        let k = habitArc(s, hold: 0.55)
        let hy = 33 - Int((k * 12).rounded())
        c.rect(38, hy, 3, 36 - hy, coat)
        if k > 0.2 {
            let pulse = 0.7 + 0.3 * sin(p.t * 9)
            let cx = 40.0, cy = Double(hy) - 2
            c.glowLine(cx, cy, cx, cy, core: clear, glow: C(0x3A9AFF), coreR: 0, glowR: 6 * k, strength: 0.6 * pulse)
            c.pattern(38, hy - 4, ["BLLB", "LWWL", "LWWL", "BLLB"], ["B": C(0x2A6AE0), "L": C(0x7AC8FF), "W": C(0xE8F8FF)])
            c.rect(23, 28, 1, 1, C(0x7AC8FF).alpha(k * 0.6)); c.rect(33, 29, 1, 1, C(0x7AC8FF).alpha(k * 0.6))
        }
        return
    }
    c.rect(38, 33, 3, 3, coat)
    drawPistol(c, x: 40, y: 31 + p.gunY, body: C(0x2A2A30), trim: C(0x3A9AFF))
}

// MARK: - Doctor Doom

/// Doctor Doom: the iron mask (eye slits, a riveted mouth grille) under a green hood and cloak, a green tunic
/// belted with a gold buckle over grey armour. Signature: he sweeps his cloak round in a grand flourish, green
/// sorcery crackling in his gauntlet.
private func drawDoctorDoom(_ c: PixelCanvas, _ p: Pose) {
    let iron = C(0x9AA0AA), ironDark = C(0x6A707C), ironLight = C(0xCCD0D8)
    let green = C(0x2E7A3A), greenDark = C(0x1E5428), greenEdge = C(0x123A1A)
    let k = p.signature.map { habitArc($0, hold: 0.4) } ?? 0
    drawCape(c, t: p.lt, speed: p.capeSpeed + 6 * k, color: greenDark, edge: greenEdge, extra: 5 * k)
    drawLegs(c, Look(leg: ironDark), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: iron, shade: ironDark, arm: iron, eye: nil), armRight: p.armRaise)
    c.rect(20, 28, 16, 1, ironLight)                                   // brow
    c.pattern(21, 29, ["KKKK......KKKK", ".KK........KK."], ["K": ink])  // eye slits
    c.rect(27, 29, 2, 4, ironDark)                                     // the nose ridge
    c.rect(28, 29, 1, 3, ironLight)
    c.rect(23, 33, 10, 1, ink)                                         // the mouth grille
    for x in [22, 25, 28, 31, 33] { c.px(x, 32, ironLight) }
    drawHood(c, green, greenDark)
    c.rect(18, 34, 20, 4, green)
    c.rect(37, 34, 1, 4, greenDark)
    c.rect(18, 35, 20, 1, C(0x5A3A1E))
    c.rect(27, 34, 3, 3, C(0xE8B530)); c.px(28, 35, C(0xFFE08A))       // the buckle
    c.rect(15, 33, 3, 3, iron)
    if k > 0.05 {
        // The cloak swept forward over his front, its hem flaring out.
        let reach = Int((k * 9).rounded())
        for y in 28...42 {
            let f = Double(y - 28) / 14
            let w = Int((Double(reach) * (0.4 + f)).rounded())
            if w > 0 { c.rect(37, y, w, 1, greenDark); c.px(37 + w - 1, y, greenEdge) }
        }
        let i = Int(p.t * 20)
        for n in 0..<3 {
            c.px(40 + Int(noise(i + n) * 4), 29 + Int(noise(i + n + 9) * 4) - 3, n == 0 ? C(0xE0FFE0) : C(0x3AE05A))
        }
    }
}

// MARK: - Hela

/// Hela: the films' goddess of death, pale face, smoky black eyes, black and green suit and cape, and the great
/// antlered headdress. She fights with a black necrosword. Signature: the headdress melts to slicked-back hair,
/// then grows back out of black wisps, tine by tine.
private func drawHela(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x15181A), sheen = C(0x34403A), green = C(0x2E9A52), greenDark = C(0x1A5A30)
    let skin = C(0xDAD8D0), skinDark = C(0xB4B2AA)
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: C(0x0E2A18), edge: greenDark)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: black, eye: nil))
    c.pattern(21, 28, ["SSSS......SSSS", ".KK........KK.", ".KK........KK.", ".KKS......SKK."],
              ["S": C(0x6A6A70), "K": ink])                             // dark, smoky eyes
    c.rect(26, 33, 4, 1, C(0x3A2A34))                                  // dark lips
    c.rect(18, 34, 20, 4, black)
    c.pattern(18, 34, ["GGGGGGGGGGGGGGGGGGGG", "....G..........G....", "....G..........G....", "....G..........G...."], ["G": green])
    c.rect(37, 34, 1, 4, greenDark)

    // The headdress (k = how far it has grown), else slicked-back black hair.
    var grow = 1.0
    if let s = p.signature {
        grow = s < 0.15 ? 1 - s / 0.15 : s < 0.3 ? 0 : min(1, (s - 0.3) / 0.45)
    }
    c.pattern(17, 21, [
        ".....KKKKKKKKKKKK.....",
        "...KKKKKKKKKKKKKKKK...",
        "..KKKsKKKKKKKKKKKKKK..",
        ".KKKsKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        "KKKK..............KKKK",
        "KKK................KKK",
        "KKK................KKK",
        "KK..................KK",
    ], ["K": black, "s": sheen])
    let tines: [(a: Double, l: Double)] = [(-162, 9), (-136, 13), (-110, 15), (-84, 14), (-58, 12), (-32, 8)]
    for (i, tn) in tines.enumerated() {
        let local = min(1, max(0, grow * 1.5 - Double(i) * 0.1))
        guard local > 0 else { continue }
        let r = tn.a * .pi / 180, l = tn.l * local
        let x0 = 28 + cos(r) * 7, y0 = 26 + sin(r) * 4.5
        let mx = x0 + cos(r) * l * 0.5, my = y0 + sin(r) * l * 0.5 - l * 0.08
        let ex = x0 + cos(r) * l, ey = y0 + sin(r) * l - l * 0.25    // tips curl up a little
        stick(c, x0, y0, mx, my, black, 1.5)
        stick(c, mx, my, ex, ey, black, 0.9)
        stick(c, x0 + cos(r) * 2, y0 + sin(r) * 2, mx, my, sheen, 0.35)
    }
    if let s = p.signature, s > 0.25, s < 0.85 {
        // Black wisps curling up into the antlers.
        for n in 0..<7 {
            let f = frac(p.t * 1.3 + Double(n) / 7)
            let a = (-170 + Double(n) * 26) * .pi / 180
            let d = 4 + f * 13
            c.px(28 + Int(cos(a) * d + sin(f * 9) * 1.5), 25 + Int(sin(a) * d * 0.8), (n % 2 == 0 ? black : C(0x2A4A34)).alpha(1 - f * 0.6))
        }
    }

    // The necrosword: black blade, a green edge.
    if let a = p.melee {
        let pv = Sprite.hand
        swingTrail(c, pv, p.trail, from: 3, to: 17, C(0x3AE07A))
        let r = a * .pi / 180, ux = cos(r), uy = sin(r)
        stick(c, pv.x - ux * 2, pv.y - uy * 2, pv.x + ux * 1.5, pv.y + uy * 1.5, greenDark, 0.8)
        stick(c, pv.x + ux * 2 - uy * 2, pv.y + uy * 2 + ux * 2, pv.x + ux * 2 + uy * 2, pv.y + uy * 2 - ux * 2, green, 0.5)
        stick(c, pv.x + ux * 2, pv.y + uy * 2, pv.x + ux * 16, pv.y + uy * 16, black, 1.0)
        stick(c, pv.x + ux * 3 - uy, pv.y + uy * 3 + ux, pv.x + ux * 15 - uy, pv.y + uy * 15 + ux, C(0x3AB86A), 0.35)
    }
}

// MARK: - Ronan

/// Ronan the Accuser, as in the film: blue-grey skin streaked with black paint under a tall black cowl, dark navy
/// armour, and the huge Universal Weapon hammer (stood upright beside him when he isn't swinging it). Signature:
/// he lifts the hammer and slams its butt down, and the floor shakes.
private func drawRonan(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5E72A0), skinDark = C(0x485A84), cowl = C(0x16161C), cowlEdge = C(0x2E2E3A)
    let armour = C(0x262A40), armourLight = C(0x4A5070)
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: cowl, edge: cowlEdge)
    drawLegs(c, Look(leg: armour), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: armour))
    c.rect(22, 32, 1, 2, ink); c.rect(33, 32, 1, 2, ink)               // black streaks down the cheeks
    c.rect(25, 32, 6, 2, ink)                                          // black lips and chin
    c.rect(26, 34, 4, 1, ink)
    c.pattern(16, 12, [
        "..KK......................",
        "..KKKK....................",
        "...KKKKKK.................",
        "...KKKKKKKKK..............",
        "....KKKKKKKKKKKK..........",
        "....KKKKKKKKKKKKKKK.......",
        "...KKKKKKKKKKKKKKKKKKK....",
    ], ["K": cowl])
    drawHood(c, cowl, cowlEdge)
    c.rect(18, 34, 20, 4, armour)
    c.rect(18, 34, 20, 1, armourLight)
    c.rect(22, 35, 12, 1, armourLight)
    c.rect(37, 35, 1, 3, C(0x1A1C2C))

    // The Universal Weapon.
    var angle = p.melee ?? -90, back = p.melee == nil ? (seatedPose ? 4.0 : 8.0) : 6.0, lift = 0.0
    var slam: Double?
    if let s = p.signature {
        angle = -90; back = 8
        if s < 0.42 { lift = habitArc(min(1, s / 0.42 * 0.5 + 0), hold: 0) * 7 }
        else if s < 0.5 { lift = 7 * (1 - (s - 0.42) / 0.08) }
        else { slam = (s - 0.5) / 0.5 }
    }
    drawUniversalWeapon(c, angle: angle, back: back, lift: lift, trail: p.trail)
    if let f = slam, f < 0.8 {
        // The shockwave: rings racing out along the floor from the hammer's butt, dust kicked up.
        let col = C(0x9AC8FF)
        for i in 0..<2 {
            let g = min(1, f * 1.6 - Double(i) * 0.3)
            guard g > 0 else { continue }
            let d = Int(g * 22)
            c.glowLine(41.5 - Double(d), 42.5 - Double(c.oy - p.hop), 41.5 + Double(d), 42.5 - Double(c.oy - p.hop),
                       core: col.alpha(1 - g), glow: col.alpha(0.6 * (1 - g)), coreR: 0.4, glowR: 1.5)
        }
        for n in 0..<6 {
            let x = 41 + Int((noise(n * 3) - 0.5) * 20 * f), y = 42 - Int(noise(n * 3 + 1) * 5 * f)
            c.px(x, y, C(0xB8AC90).alpha(1 - f))
        }
        if f < 0.15 { c.ox += Int(p.t * 40) % 2 }
    }
}

/// Ronan's hammer at `angle`, gripped at the hand, the shaft running `back` px behind the grip; `lift` raises it.
private func drawUniversalWeapon(_ c: PixelCanvas, angle: Double, back: Double, lift: Double, trail: [Double]) {
    let pv = (x: Sprite.hand.x, y: Sprite.hand.y - lift)
    swingTrail(c, pv, trail, from: 10, to: 17, C(0xC8D4F0))
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    stick(c, pv.x - ux * back, pv.y - uy * back, pv.x + ux * 14, pv.y + uy * 14, C(0x4A4E5A), 0.65)
    stick(c, pv.x - ux * back, pv.y - uy * back, pv.x - ux * (back - 1.5), pv.y - uy * (back - 1.5), C(0x9AA0AE), 0.8)
    let hx = pv.x + ux * 16, hy = pv.y + uy * 16
    stick(c, hx - nx * 5, hy - ny * 5, hx + nx * 5, hy + ny * 5, C(0x5A6070), 2.0)
    stick(c, hx - nx * 5 - ux * 0.8, hy - ny * 5 - uy * 0.8, hx + nx * 5 - ux * 0.8, hy + ny * 5 - uy * 0.8, C(0xA8B0C0), 0.6)
    stick(c, hx - nx * 1.2, hy - ny * 1.2, hx + nx * 1.2, hy + ny * 1.2, C(0x2A2E3A), 2.1)
}

// MARK: - Nebula

/// Nebula, as in the films: blue skin and a bald head patched with purple-grey cybernetic plates, black eyes, a
/// dark suit, and a crackling electric baton. Signature: her cyber plates glitch and flicker, circuits flashing red.
private func drawNebula(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x4A78C8), skinDark = C(0x35589A), metal = C(0x8C8496), metalDark = C(0x5C5468)
    let suit = C(0x2A2230), suitLight = C(0x4A3A50)
    drawLegs(c, Look(leg: suit), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: suit))
    let glitch = p.signature.map { $0 > 0.1 && $0 < 0.9 } ?? false
    let i = Int(p.t * 16)
    let jx = glitch && noise(i) > 0.6 ? 1 : 0
    c.pattern(18, 22, [
        "...SSSSSSSSSSSSSS...",
        ".SSSSSSSSSSSSSSSSSS.",
        "SSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSS",
    ], ["S": skin])
    c.rect(37, 23, 1, 3, skinDark)
    // The plates: the scalp, a seam line over the head, round the right eye.
    let plateCol = glitch && noise(i + 3) > 0.5 ? C(0xC8B8D8) : metal
    c.pattern(18 + jx, 22, [
        "...MMMMMMm..........",
        ".MMMMMMMMMm.........",
        "MMMmMMMMMMMm........",
        "MMMMMMMMMMm.........",
        "MMMMMMMMm...........",
        "MMMMMm..............",
    ], ["M": plateCol, "m": metalDark])
    c.rect(30 - jx, 23, 1, 5, metalDark)                               // the seam over her scalp
    c.pattern(30, 27, ["mMMMMm", "M....M", "M....M", "M....M", "mMMMMm"], ["M": plateCol, "m": metalDark])
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(25, 33, 6, 1, skinDark)
    if glitch {
        let red = C(0xFF4A3A)
        if noise(i + 5) > 0.4 { c.px(32, 29, red); c.px(33, 30, C(0xFFB0A0)) }
        for n in 0..<4 where noise(i * 3 + n) > 0.5 { c.px(19 + n * 2, 23 + n % 3, red) }
        if noise(i + 8) > 0.7 { drawSparks(c, x: 31, y: 24, t: p.t, size: 2) }
    }
    c.rect(18, 34, 20, 4, suit)
    c.rect(18, 34, 20, 1, suitLight)
    c.rect(18, 36, 20, 1, C(0x5A3A2A))
    c.rect(37, 34, 1, 4, C(0x1A141E))

    // The electric baton (clipped to her belt when put away).
    guard let a = p.melee else {
        stick(c, 21, 36.5, 31, 36.5, C(0x5A5E6A), 0.5); c.rect(19, 36, 3, 1, C(0x2A2A30)); c.px(31, 36, C(0x9AD8FF))
        return
    }
    let pv = Sprite.hand, r = a * .pi / 180, ux = cos(r), uy = sin(r)
    swingTrail(c, pv, p.trail, from: 3, to: 13, C(0x7AC8FF))
    stick(c, pv.x - ux * 2, pv.y - uy * 2, pv.x + ux * 3, pv.y + uy * 3, C(0x2A2A30), 0.75)
    stick(c, pv.x + ux * 3, pv.y + uy * 3, pv.x + ux * 11, pv.y + uy * 11, C(0x5A5E6A), 0.6)
    let tip = (pv.x + ux * 12, pv.y + uy * 12)
    c.glowLine(tip.0, tip.1, tip.0, tip.1, core: C(0xE8F8FF), glow: C(0x5AB8FF), coreR: 0.7, glowR: 2.2,
               strength: 0.75 + 0.25 * noise(Int(p.t * 30)))
}

// MARK: - Ebony Maw

/// Ebony Maw, as in the film: grey skin, the long bald cranium swept back, a tiny flat-nosed face, and a black
/// robe with a tall collar; he floats and works by telekinesis. Signature: he lifts a hand and a ring of needles
/// floats round his fingers.
private func drawEbonyMaw(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xA4A6AC), skinDark = C(0x7E8088), skinLight = C(0xC4C6CC)
    let robe = C(0x1C1C24), collar = C(0x4A4A66), trim = C(0x9A9CB4)
    for y in 36...41 {                                                 // the robe hanging to a point, no feet
        let k = (y - 36) / 2
        c.rect(18 + k, y, 20 - k * 2, 1, robe)
        c.px(37 - k, y, collar)
    }
    c.oy += p.breathe
    // The tall collar behind his head.
    c.pattern(14, 20, ["C......................C", "CC....................CC", "CCC..................CCC", "CCCC................CCCC",
                       ".CCC................CCC.", ".CCC................CCC.", "..CCC..............CCC..", "..CCC..............CCC..",
                       "...CC..............CC..."], ["C": collar])
    var look = Look(body: skin, shade: skinDark, arm: robe, eye: nil)
    look.legs = false
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let raise = max(p.armRaise, Int((k * 7).rounded()))
    drawBody(c, look, armRight: raise)
    c.pattern(17, 12, [
        "....SSSSSS..........",
        "..SSLLSSSSSS........",
        ".SSLLSSSSSSSSS......",
        ".SLSSSSSSSSSSSS.....",
        "SSSSSSSSSSSSSSSS....",
        "SSSSSSSSSSSSSSSSS...",
        "SSSSSSSSSSSSSSSSSS..",
        "SSSSSSSSSSSSSSSSSSS.",
        ".SSSSSSSSSSSSSSSSSSS",
        ".SSSSSSSSSSSSSSSSSSS",
        "..SSSSSSSSSSSSSSSSSs",
        "..SSSSSSSSSSSSSSSSSs",
        "..SSSSSSSSSSSSSSSSSs",
        "..SSSSSSSSSSSSSSSSSs",
        ".SSSSSSSSSSSSSSSSSSs",
    ], ["S": skin, "s": skinDark, "L": skinLight])
    c.rect(20, 19, 6, 1, skinDark); c.rect(22, 22, 5, 1, skinDark)     // the ridges of that long skull
    c.rect(24, 29, 2, 2, ink); c.rect(31, 29, 2, 2, ink)               // small, close eyes
    c.rect(23, 28, 3, 1, skinDark); c.rect(31, 28, 3, 1, skinDark)
    c.px(27, 31, skinDark); c.px(29, 31, skinDark)                     // the flat nose
    c.rect(26, 33, 5, 1, skinDark)
    c.rect(18, 34, 20, 4, robe)
    c.rect(26, 34, 4, 4, collar)
    c.rect(27, 34, 2, 4, trim)
    if k > 0.3 {
        // The needles, circling his raised fingers.
        let cx = 40.5, cy = 32.5 - Double(raise)
        c.rect(39, 30 - raise, 1, 3, skin); c.rect(41, 30 - raise, 1, 3, skin)
        for n in 0..<6 {
            let a = p.t * 3.2 + Double(n) * 2 * .pi / 6
            let x = cx + 1 + cos(a) * 8, y = cy - 4 + sin(a) * 4
            let tx = -sin(a) * 2.2, ty = cos(a) * 1.1
            stick(c, x - tx, y - ty, x + tx, y + ty, C(0xD8DCE6).alpha(k), 0.4)
            c.px(Int(x + tx), Int(y + ty), white.alpha(k))
        }
        c.glowLine(cx, cy - 3, cx, cy - 3, core: clear, glow: C(0xA8A0FF), coreR: 0, glowR: 4, strength: 0.4 * k)
    }
}

// MARK: - Chitauri

/// A Chitauri foot soldier: grey-brown armour plates over grey hide, a hooked, swept-back helmet crest, a slatted
/// metal jaw and pale glowing eyes, carrying the long spear-gun with its blue power cell and front blade.
private func drawChitauri(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x6E6C60), dark = C(0x44433C), light = C(0x9C9A88), hide = C(0x7C8486), eye = C(0xE8F4C8)
    drawLegs(c, Look(leg: dark), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 38, light) } }
    c.oy += p.breathe
    drawBody(c, Look(body: hide, shade: C(0x5A6264), arm: armour, eye: nil))
    c.pattern(14, 17, [
        "KK....................",
        ".KKK..................",
        "..KKKKK...............",
        "...KAAAAAAAAAAAA......",
        "..KAAALLAAAAAAAAAA....",
        ".KAAALAAAAAAAAAAAAAA..",
        ".KAAAAAAAAAAAAAAAAAAA.",
        "KAAAAAAAAAAAAAAAAAAAAA",
        "KAAAADDDDDDDDDDDDDDAAA",
        ".AAAA..............AAA",
        "..AAA..............AA.",
    ], ["K": dark, "A": armour, "L": light, "D": dark])
    c.pattern(21, 28, ["EEE.......EEE", ".EE.......EE."], ["E": eye])
    c.pattern(21, 31, ["DLDLDLDLDLDLD", "LDLDLDLDLDLDL", ".DLDLDLDLDLD."], ["D": dark, "L": light])   // slatted jaw
    c.rect(18, 35, 20, 3, armour)
    c.rect(18, 35, 20, 1, light)
    c.rect(24, 36, 8, 1, dark)
    c.rect(15, 32, 3, 2, light)

    // The spear-gun, held level.
    let y = 32 + p.gunY
    c.rect(35, y + 1, 21, 2, C(0x3A3A36))
    c.rect(35, y + 1, 21, 1, C(0x5A5A52))
    c.rect(44, y, 5, 4, C(0x2A2A28))
    c.rect(45, y + 1, 3, 2, C(0x5AC8FF))
    c.px(46, y + 1, C(0xE8F8FF))
    c.rect(38, y + 1, 3, 3, armour)                                    // the hand
    c.pattern(55, y - 1, ["LL..", "LLLL", "LLLL", "LL.."], ["L": C(0xB8BCC4)])   // the blade at the front
}

// MARK: - Grandmaster

/// The Grandmaster of Sakaar, as in the film: tanned, grey hair swept back, the blue stripe down his chin, and a
/// flowing gold robe with blue and red trim. He doesn't fight; he laughs. Signature: he dances, arms waving, and
/// "HA"s float up.
private func drawGrandmaster(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE2B48E), skinDark = C(0xC0926E), hair = C(0xB4B4BA), hairLight = C(0xE0E0E6)
    let robe = C(0xE0A82E), robeDark = C(0xB07E1E), blue = C(0x2E64D0), red = C(0xC83A2A)
    var dance = 0.0, sway = 0
    if let s = p.signature, s > 0.05, s < 0.95 {
        dance = s
        sway = Int((sin(s * 2 * .pi * 4) * 1.5).rounded())
    }
    // Feet peeking out under the hem as he walks.
    if p.step >= 0 && !seatedPose { c.rect(p.step == 0 ? 22 : 32, 42, 3, 2, C(0x3A2A1E)) }
    c.ox += sway
    for y in 35...43 where !(seatedPose && y > 39) {
        let k = (y - 35) / 3
        c.rect(17 - k, y, 22 + k * 2, 1, robe)
        c.px(17 - k, y, robeDark); c.px(38 + k, y, robeDark)
    }
    c.rect(15, seatedPose ? 39 : 42, 26, 1, blue)
    c.oy += p.breathe + (dance > 0 && sin(dance * 2 * .pi * 8) > 0 ? -1 : 0)
    var look = Look(body: skin, shade: skinDark, arm: robe, eye: ink)
    look.legs = false
    let armL = dance > 0 ? (sin(dance * 2 * .pi * 4) > 0 ? 9 : 0) : 0
    let armR = dance > 0 ? (sin(dance * 2 * .pi * 4) > 0 ? 0 : 9) : 0
    drawBody(c, look, armLeft: armL, armRight: armR)
    c.rect(22, 28, 2, 1, blue); c.rect(32, 28, 2, 1, blue)             // a touch of blue liner
    if dance > 0 {
            c.rect(25, 31, 6, 2, C(0x4A1A1A)); c.rect(25, 31, 6, 1, white)   // laughing
    } else {
        c.rect(25, 31, 6, 1, skinDark); c.px(31, 30, skinDark)
    }
    c.rect(27, 32 + (dance > 0 ? 1 : 0), 2, 3, blue)                     // the chin stripe
    c.pattern(17, 18, [
        ".......HHHHHHHH.......",
        "....HHHLHHHLHHHHH.....",
        "..HHLHHHLHHHLHHHHHH...",
        ".HLHHHLHHHLHHHHHHHHH..",
        "HLHHHLHHHLHHHHHHHHHHH.",
        "HHHHLHHHLHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHH...............HHHH",
        "HH.................HH.",
    ], ["H": hair, "L": hairLight])
    c.rect(18, 35, 20, 3, robe)
    c.pattern(18, 34, ["RBBBBBR......RBBBBBR", ".RBBR..........RBBR.", "..R..............R.."], ["B": blue, "R": red])
    c.rect(37, 35, 1, 3, robeDark)
    if dance > 0 {
        for n in 0..<2 {
            let f = frac(dance * 3 + Double(n) * 0.5)
            drawHa(c, x: n == 0 ? 40 : 9, y: 20 - Int(f * 10), (n == 0 ? C(0xFFD25A) : C(0x7AB8FF)).alpha(1 - f * 0.8))
        }
    }
}

// MARK: - Ultron Sentry

/// An Ultron Sentry drone: a small chrome head-shaped pod with Ultron's slanted red eyes and glowing mouth, a stub
/// cannon on one side and a jet burning underneath. Hovers; can't sit.
private func drawUltronSentry(_ c: PixelCanvas, _ p: Pose) {
    let chrome = C(0xB8BEC8), dark = C(0x7A808C), light = C(0xE6EAF0), red = C(0xFF2A2A), hot = C(0xFFD8D0)
    let bob = Int((sin(p.lt * 3) * 1).rounded())
    c.rect(22, 43, 12, 1, C(0x000000).alpha(0.22))                      // its shadow
    c.oy += bob
    let flick = noise(Int(p.t * 20))
    c.pattern(24, 36, ["KKKKKKKK", ".KKKKKK.", "..KKKK.."], ["K": dark])
    c.glowLine(28, 39.5, 28, 41 + flick * 2, core: C(0xFFF0C0), glow: C(0xFF5A2A), coreR: 0.8, glowR: 1.8)
    c.pattern(18, 22, [
        ".......dddddd.......",
        ".....ddCCLLCCdd.....",
        "....dCCLLCCCCCCd....",
        "...dCCLCCCCCCCCCd...",
        "..dCCCCCCCCCCCCCCd..",
        "..CCCCCCCCCCCCCCCC..",
        ".CCCCCCCCCCCCCCCCCC.",
        ".CCCCCCCCCCCCCCCCCCd",
        ".CCCCCCCCCCCCCCCCCCd",
        ".CCCCCCCCCCCCCCCCCCd",
        ".CCCCCCCCCCCCCCCCCCd",
        "..CCCCCCCCCCCCCCCCd.",
        "..dCCCCCCCCCCCCCCd..",
        "...ddCCCCCCCCCCdd...",
        ".....dddddddddd.....",
    ], ["C": chrome, "d": dark, "L": light])
    c.rect(28, 22, 1, 6, dark)
    for (x, y) in [(22, 28), (23, 28), (24, 29), (25, 29), (31, 29), (32, 29), (33, 28), (34, 28)] {
        c.glowLine(Double(x) + 0.5, Double(y) + 0.5, Double(x) + 0.5, Double(y) + 0.5, core: red, glow: red, coreR: 0.5, glowR: 1.2, strength: 0.4)
        c.px(x, y, x == 23 || x == 33 ? hot : red)
    }
    c.rect(24, 32, 9, 1, C(0x5A0A0A))
    for x in stride(from: 24, to: 33, by: 2) { c.px(x, 32, red) }
    // The stub cannon.
    let y = 31 + p.gunY
    c.rect(37, y, 6, 3, dark); c.rect(37, y, 6, 1, chrome)
    c.px(42, y + 1, p.fire != nil ? hot : red)
    c.rect(16, 30, 3, 3, dark)
}
