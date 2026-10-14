import Foundation

// Villains: the renegade Time Lords. The Master in every face he's worn, and the Ranee. Clawd in costume each time, but
// no two alike at a glance: the suit, the hair and beard, the collar and the weapon's colour tell them apart. Most of
// them carry the tissue compression eliminator, a short black rod with a glowing tip; Sexton has his laser
// screwdriver and the Snakeskin Master spits venom.

let doctorVillains2: [DoctorVillain: Persona] = [
    .master: Persona(name: "The Master", weapon: .blaster, shot: .beam(core: C(0xE8FFE8), glow: C(0x3AE85A)),
                  muzzle: (47, 33), headTop: 22, signature: 3.0, callout: "I am the Master",
                  draw: drawMaster),
    .burntMaster: Persona(name: "The Burnt Master", weapon: .blaster, shot: .energy(core: C(0xFFF0C8), glow: C(0xFF6A1E)),
                  muzzle: (47, 33), headTop: 15,
                  draw: drawBurntMaster),
    .velvetMaster: Persona(name: "The Velvet Master", weapon: .blaster, shot: .beam(core: C(0xF0FFD8), glow: C(0x9AE83A)),
                  muzzle: (47, 33), headTop: 21,
                  draw: drawVelvetMaster),
    .snakeskinMaster: Persona(name: "The Snakeskin Master", weapon: .blaster, shot: .energy(core: C(0xE8FFD0), glow: C(0x4ADA2A)),
                  muzzle: (38, 33), handGun: false, headTop: 21,
                  draw: drawSnakeskinMaster),
    .sexton: Persona(name: "Mister Sexton", weapon: .lightning, magic: Magic(core: C(0xFFE8C8), glow: C(0xFF2A1E), jagged: false),
                  pivot: sonicTip, headTop: 23, signature: 2.6,
                  draw: drawSexton),
    .missy: Persona(name: "Missy", weapon: .blaster, motion: .hover, shot: .energy(core: C(0xFFE0F4), glow: C(0xE03AB8)),
                  muzzle: (53, 33), headTop: 15, signature: 3.4,
                  draw: drawMissy),
    .spyMaster: Persona(name: "The Spy Master", weapon: .blaster, shot: .beam(core: C(0xFFF8D0), glow: C(0xE8B020)),
                  muzzle: (47, 33), headTop: 21,
                  draw: drawSpyMaster),
    .ranee: Persona(name: "The Ranee", weapon: .blaster, shot: .energy(core: C(0xE0FFF8), glow: C(0x2AC8B0)),
                  muzzle: (47, 33), headTop: 14,
                  draw: drawRanee),
]

// MARK: - Shared bits

/// Plain shoes on the four feet, `rows` high; the lifted pair a row higher while walking.
private func drawShoes(_ c: PixelCanvas, step: Int, _ col: Px = C(0x101014), rows: Int = 1) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// The tissue compression eliminator held out in the right fist: a short two-pixel rod, a band round it and the tip
/// at (46, 33), lit while it fires. Muzzle (47, 33).
private func drawEliminator(_ c: PixelCanvas, body: Px, band: Px, tip: Px, lit: Bool) {
    c.rect(40, 33, 5, 2, body); c.px(45, 33, body)
    c.rect(43, 33, 1, 2, band)
    c.px(46, 33, lit ? tip : tip.alpha(0.6))
    if lit { c.px(47, 33, tip.alpha(0.45)) }
}

/// Arched, sinister eyebrows over Clawd's eyes, high at the outside and down to the bridge.
private func drawBrows(_ c: PixelCanvas, _ col: Px) {
    c.rect(21, 27, 2, 1, col); c.rect(23, 28, 2, 1, col)
    c.rect(31, 28, 2, 1, col); c.rect(33, 27, 2, 1, col)
}

/// Is a ranged character's shot leaving the barrel this frame?
private func firing(_ p: Pose) -> Bool {
    p.fire.map { frac($0.t / p.firePeriod) < 0.18 } ?? false
}

// MARK: - The Master

/// The Master: Clawd in the black Nehru suit, its high band collar buttoned to the throat, slick black hair with a
/// widow's peak, arched brows and a neat pointed goatee. He holds the tissue compression eliminator out, its green tip
/// shrinking whatever it hits. Signature: the hypnotic stare: his eyes light green and rings of will pulse out from
/// them ("I am the Master"), his free hand raised, fingers spread.
private func drawMaster(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1C1C22), suitLight = C(0x34343E), hair = C(0x121216), hairLight = C(0x2E2E38)
    let button = C(0x8A8E98), green = C(0x3AE85A)
    let stare = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawShoes(c, step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armLeft: stare > 0.3 ? 3 : 0)
    // The Nehru jacket: the band collar standing round the neck, a row of buttons.
    c.rect(18, 34, 20, 4, suit)
    c.rect(37, 34, 1, 4, C(0x101014))
    c.rect(24, 33, 9, 1, suit); c.rect(24, 33, 9, 1, suitLight.alpha(0.6)); c.px(28, 33, C(0x0A0A0E))
    for y in [35, 37] { c.px(28, y, button) }
    c.rect(19, 34, 1, 4, suitLight)
    // The hair: slicked back, a widow's peak.
    c.pattern(17, 21, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHlllHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHH....HHH.....HHHH.",
        ".HHH......H.......HHH.",
        ".HH................HH.",
    ], ["H": hair, "l": hairLight])
    drawBrows(c, hair)
    // Moustache and pointed goatee.
    c.rect(25, 32, 7, 1, hair); c.rect(26, 33, 5, 1, hair); c.rect(27, 34, 3, 1, hair); c.px(28, 35, hair)
    // The hypnotic stare.
    if stare > 0.3 {
        for x in [22, 32] {
            c.rect(x, 29, 2, 3, C(0xD8FFE0))
            c.glowLine(Double(x) + 1, 30.5, Double(x) + 1, 30.5, core: white, glow: green, coreR: 0.5, glowR: 1.5 + stare)
        }
        let s = p.signature ?? 0
        for k in 0..<3 {
            let f = frac(s * 5 + Double(k) / 3), r = 3 + f * 13
            for i in 0..<6 {
                let a0 = (-50 + Double(i) * 100 / 6) * .pi / 180, a1 = (-50 + Double(i + 1) * 100 / 6) * .pi / 180
                c.glowLine(36 + cos(a0) * r, 30 + sin(a0) * r, 36 + cos(a1) * r, 30 + sin(a1) * r,
                           core: C(0xD8FFE0).alpha((1 - f) * stare), glow: green.alpha(0.5 * (1 - f) * stare), coreR: 0.3, glowR: 1)
            }
        }
        c.rect(15, 28, 1, 2, clawdOrange); c.rect(17, 28, 1, 2, clawdOrange)   // the raised hand's spread fingers
    }
    // The right arm and the eliminator.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, suit)
    drawEliminator(c, body: C(0x18181C), band: C(0x8A8E98), tip: green, lit: firing(p))
}

// MARK: - The Burnt Master

/// The Burnt Master: Clawd charred to the bone, the face a scorched skull (dark, cracked, raw red in the seams, a
/// lipless grin and sunken sockets with a yellow glint for eyes) under the tall black collar of a Time Lord's robe,
/// sweeping up behind his head, its gold edge gone dull. The robe hangs to his feet. He fires the eliminator, an
/// orange-tipped one.
private func drawBurntMaster(_ c: PixelCanvas, _ p: Pose) {
    let char = C(0x3A2A24), charLight = C(0x5A4032), raw = C(0x8A2A1A), bone = C(0xB8A890)
    let robe = C(0x16141A), robeLight = C(0x2A2630), gold = C(0x8A6A2A)
    // The robe falls past the legs.
    if !seatedPose {
        for y in 36...41 { let k = (y - 36) / 2; c.rect(17 - k, y, 22 + k * 2, 1, robe) }
        c.rect(18, 41, 20, 1, robeLight)
    }
    drawLegs(c, Look(leg: robe), step: p.step)
    drawShoes(c, step: p.step, C(0x0A0A0C))
    c.oy += p.breathe
    // The collar: tall, sweeping up behind the head.
    c.pattern(12, 15, [
        "..........ggggggggggg..........",
        "......gggggCCCCCCCCCggggg......",
        "....ggCCCCCrCCCCCCCrCCCCCgg....",
        "...gCCCCrCCCCCCrCCCCCCrCCCCg...",
        "..gCCrCCCCCCCCCCCCCCCCCCCrCCg..",
        ".gCCCCCCCrCCCCCCCCCCCrCCCCCCg..",
        ".gCCrCCCCCCCCCCCCCCCCCCCCrCCCg.",
        "gCCCCCCC..............CCCCCCCg.",
        "gCCrCCC................CCCrCCg.",
        "gCCCCC..................CCCCCg.",
        ".gCCC....................CCCg..",
        "..gCC....................CCg...",
    ], ["C": robe, "g": gold, "r": C(0x4A1418)])
    // The bald, scorched dome of the skull above the face.
    c.pattern(18, 22, [
        ".....cCCCCCCCCc.....",
        "..cCCCCrCCCCCCCCCc..",
        ".CCCCCCCCCCCrCCCCCC.",
        "CCCrCCCCCCCCCCCCCCCC",
    ], ["C": char, "c": charLight, "r": raw])
    drawBody(c, Look(body: char, shade: C(0x241A16), arm: robe, eye: nil))
    // The scorched skull: cracks, raw seams, cheekbones, sockets and a grin.
    c.pattern(18, 26, [
        "..c....rr.....c...c.",
        ".cc..c...c...rr..c..",
        "...SSSS....SSSS.....",
        "..SSyySB..SSyySB.r..",
        ".cSSSSSBccSSSSSBcc..",
        "..BSSSB.r..BSSSB....",
        "...BBB.TTTTTTB.B..c.",
        "..r....T.T.T.T..r...",
    ], ["c": charLight, "r": raw, "S": C(0x0E0A0A), "y": C(0xFFD24A), "B": bone.alpha(0.55), "T": bone])
    if Int(p.lt * 3) % 7 == 0 { c.px(22, 29, C(0xFFF0A0)); c.px(32, 29, C(0xFFF0A0)) }   // the glint flares
    // The robe over the body, a dull gold clasp.
    c.rect(18, 34, 20, 4, robe)
    c.rect(22, 34, 1, 4, robeLight); c.rect(33, 34, 1, 4, robeLight)
    c.rect(27, 34, 2, 1, gold)
    c.rect(15, 33, 3, 3, robe); c.px(15, 35, char)
    // The right arm, a charred claw round the eliminator.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, robe); c.px(40, 35, char)
    drawEliminator(c, body: C(0x1A1416), band: gold, tip: C(0xFF8A2A), lit: firing(p))
}

// MARK: - The Velvet Master

/// The Velvet Master: Clawd in a black velvet tunic with a plum sheen, its stiff standing collar flared up either side
/// of the face and edged in silver; curly black hair going grey at the temples and a full pointed beard down onto the
/// chest. A silver ring on his finger. He carries a long silver-banded eliminator with a yellow-green tip.
private func drawVelvetMaster(_ c: PixelCanvas, _ p: Pose) {
    let velvet = C(0x221A28), sheen = C(0x4A3258), velvetDark = C(0x120E16), silver = C(0xC8CCD8)
    let hair = C(0x16141A), grey = C(0x8A8A96)
    drawLegs(c, Look(leg: velvet), step: p.step)
    drawShoes(c, step: p.step, C(0x0A0A0C), rows: 2)
    c.oy += p.breathe
    // The standing collar behind the face.
    c.pattern(15, 26, [
        "s.......................s",
        "Ss.....................sS",
        "VSs...................sSV",
        "VVS...................SVV",
        "VVS...................SVV",
        "VVVS.................SVVV",
        ".VVVS...............SVVV.",
        "..VVVS.............SVVV..",
    ], ["V": velvet, "S": sheen, "s": silver])
    drawBody(c, Look(arm: velvet))
    // The tunic: velvet with a soft sheen down the front, silver trim at the collar's meeting.
    c.rect(18, 34, 20, 4, velvet)
    c.rect(20, 34, 1, 4, sheen); c.rect(24, 35, 1, 3, sheen); c.rect(34, 34, 1, 4, sheen)
    c.rect(37, 34, 1, 4, velvetDark)
    c.rect(22, 33, 12, 1, silver.alpha(0.8))
    // The hair: curly, greying at the temples.
    c.pattern(17, 21, [
        "......H.HH.H.H.H......",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHgHHHHHgHHHHHHHH..",
        ".HHgHHHHHgHHHHHHHgHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".gHHHH.HHH..HHH.HHHHg.",
        ".gg................gg.",
        ".g..................g.",
    ], ["H": hair, "g": grey])
    drawBrows(c, hair)
    // The full pointed beard, down over the tunic.
    c.rect(24, 32, 9, 1, hair)
    c.rect(24, 33, 9, 2, hair); c.rect(25, 35, 7, 1, hair); c.rect(26, 36, 5, 1, hair); c.rect(27, 37, 3, 1, hair)
    c.px(28, 38, hair)
    c.px(26, 34, grey); c.px(30, 35, grey)
    // The right arm, the ring and the long eliminator.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, velvet); c.px(40, 35, silver)
    drawEliminator(c, body: C(0x1A161E), band: silver, tip: C(0xB8FF4A), lit: firing(p))
    c.px(41, 33, silver)
}

// MARK: - The Snakeskin Master

/// The Snakeskin Master: Clawd with slicked-back black hair, black wraparound sunglasses with a glint, and a
/// snakeskin jacket (olive diamonds on dark scales) over a black shirt. He has no gun: he spits gobs of acid-green
/// venom from his mouth, his jaw dropping open as he does.
private func drawSnakeskinMaster(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x4A5230), scale = C(0x7A8A48), scaleDark = C(0x2A3018), shirt = C(0x141418)
    let hair = C(0x101014), hairLight = C(0x34343E), lens = C(0x0A0A0E), green = C(0x4ADA2A)
    drawLegs(c, Look(leg: C(0x18181E)), step: p.step)
    drawShoes(c, step: p.step, C(0x2A2018))
    c.oy += p.breathe
    drawBody(c, Look(arm: skin))
    // The jacket: diamonds of scales, open over the black shirt.
    c.rect(18, 33, 20, 5, skin)
    for y in 33...37 {
        for x in 18...37 where (x + y * 2) % 4 == 0 { c.px(x, y, (x + y) % 3 == 0 ? scale : scaleDark) }
    }
    c.rect(25, 33, 6, 5, shirt); c.rect(24, 33, 1, 3, scaleDark); c.rect(31, 33, 1, 3, scaleDark)
    c.rect(37, 33, 1, 5, scaleDark)
    c.rect(15, 33, 3, 3, skin); c.px(16, 34, scale)
    // The hair: slicked straight back.
    c.pattern(17, 21, [
        "......HHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHlllllllllllHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
    ], ["H": hair, "l": hairLight])
    // The sunglasses.
    c.rect(19, 28, 18, 1, lens)
    c.rect(20, 29, 6, 3, lens); c.rect(30, 29, 6, 3, lens); c.rect(26, 29, 4, 1, lens)
    c.px(21, 29, C(0x8A8E98)); c.px(31, 29, C(0x8A8E98))
    // The venom: jaw open, a drip of green.
    if firing(p) {
        c.rect(33, 32, 5, 2, C(0x1A0A0A)); c.rect(34, 33, 3, 1, C(0x5A1A1A))
        c.px(36, 34 + Int(p.t * 6) % 2, green)
    } else if p.fire != nil {
        c.rect(34, 32, 4, 1, C(0x1A0A0A)); c.px(36, 33, green.alpha(0.7))
    } else {
        c.rect(32, 32, 4, 1, C(0x5A2A1A))   // a sneer
    }
    c.rect(38, 33, 3, 3, skin); c.px(39, 34, scale)
}

// MARK: - Mister Sexton

/// Mister Sexton: Clawd with a bleached-blond crop, a sharp dark suit, white shirt and black tie, grinning. His weapon
/// is the laser screwdriver: gold, with a red tip, and a steady red ray. Signature: the drumming: he taps four beats
/// on his chest with his fingers (da-da-da-DUM), a red beat lighting above his head with each, nodding along.
private func drawSexton(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E2230), suitLight = C(0x30364A), shirt = C(0xF0EEE8), tie = C(0x101014)
    let hair = C(0xF0E2A8), hairDark = C(0xC8B478), red = C(0xFF3A2A)
    let sig = p.signature
    // The four beats: at 0.12, 0.26, 0.40 and 0.58 (the last one hardest).
    let beats = [0.12, 0.26, 0.40, 0.58]
    let count = sig.map { s in beats.filter { s >= $0 }.count } ?? 0
    let tapping = sig.map { s in beats.contains { s >= $0 && s < $0 + 0.06 } } ?? false
    let drumming = sig.map { $0 > 0.04 && $0 < 0.9 } ?? false
    drawLegs(c, Look(leg: suit), step: p.step)
    drawShoes(c, step: p.step)
    c.oy += p.breathe
    if tapping { c.oy += 1 }
    drawBody(c, Look(arm: suit))
    // The suit: jacket open over a white shirt and a thin black tie.
    c.rect(18, 33, 20, 5, suit)
    c.rect(24, 33, 8, 5, shirt); c.rect(27, 33, 2, 5, tie)
    c.rect(23, 33, 1, 3, suitLight); c.rect(32, 33, 1, 3, suitLight)
    c.rect(37, 33, 1, 5, C(0x121420))
    // The crop: short, bleached, the roots a shade darker.
    c.pattern(18, 23, [
        "...hHHHHHHHHHHHHh...",
        ".hHHHHHHHHHHHHHHHHh.",
        "hHHHhHHHHHHHHHhHHHHh",
        "HH................HH",
        "H..................H",
    ], ["H": hair, "h": hairDark])
    c.rect(31, 32, 4, 1, C(0x5A2A1A)); c.px(35, 31, C(0x5A2A1A))   // the grin
    if drumming {
        // Both hands on his chest, fingers tapping.
        c.rect(15, 33, 3, 3, suit); c.rect(18, 34, 3, 2, suit)
        c.rect(30, 34, 6, 2, suit)
        let fy = tapping ? 34 : 33
        for x in [30, 32, 34] { c.px(x, fy, clawdOrange) }
        for x in [20, 22] { c.px(x, fy, clawdOrange) }
        if tapping { c.glowLine(32, 34, 32, 34, core: white, glow: red, coreR: 0.4, glowR: 1.8) }
        for i in 0..<count {
            let big = i == 3
            c.rect(19 + i * 5, big ? 14 : 15, big ? 3 : 2, big ? 3 : 2, red)
        }
        return
    }
    let using = p.zap != nil || p.ready || p.cheering || (!p.resting && !p.walking)
    let raise = using ? p.armRaise : 0
    c.rect(38, 31 - raise, 3, 3, suit)
    drawLaser(c, out: using, lift: raise, lit: p.zap == true, t: p.t)
    if !using { c.rect(38, 31, 3, 3, suit); c.rect(38, 30, 3, 1, clawdOrange) }
}

/// The laser screwdriver: Sexton's gold one with a red tip. Out, the tip at `sonicTip` `lift` higher, lit while it
/// fires; at rest, upright in the fist.
private func drawLaser(_ c: PixelCanvas, out: Bool, lift: Int, lit: Bool, t: Double) {
    let gold = C(0xE0B040), goldDark = C(0x8A6A1E), tip = C(0xFF3A2A)
    let glow = lit ? tip : tip.alpha(0.6)
    if out {
        let y = 32 - lift
        c.rect(41, y, 2, 1, goldDark); c.rect(43, y - 1, 2, 1, gold); c.px(45, y - 2, goldDark); c.px(46, y - 2, glow)
        if lit && sin(t * 30) > 0 { c.px(47, y - 3, tip.alpha(0.5)) }
    } else {
        c.rect(39, 29, 1, 4, goldDark); c.rect(39, 27, 1, 2, gold); c.px(39, 26, glow)
    }
}

// MARK: - Missy

/// Missy: Clawd as a Victorian lady in a plum-purple coat with black frogging over a white lace jabot and a cameo, a
/// long dark skirt to the ground, dark hair pinned up under a small tilted black hat with a feather. She glides rather
/// than walks, and fires from the tip of her furled umbrella. Signature: the umbrella pops open over her head and
/// twirls, and she floats up like a nanny on the wind, then lets herself down.
private func drawMissy(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x5A2260), coatLight = C(0x7A3A82), coatDark = C(0x3A1440), skirt = C(0x241A2A), skirtLight = C(0x3A2A42)
    let lace = C(0xF4F0EA), hair = C(0x3A2218), hairLight = C(0x5A3A28), hat = C(0x141016)
    let brolly = C(0x1A1220), brollyLight = C(0x3A2A48)
    let sig = p.signature
    let open = sig.map { $0 > 0.06 && $0 < 0.94 } ?? false
    let float = sig.map { habitArc($0, hold: 0.55) } ?? 0
    c.oy -= Int((float * 3).rounded())

    // The long skirt, swaying as she glides; boots peep from under it.
    let hem = seatedPose ? 39 : 42
    if !seatedPose {
        for (i, lx) in [20, 33].enumerated() {
            let y = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, y, 3, 1, C(0x0E0A10))
        }
    }
    let sway = p.walking ? (p.step == 0 ? 1 : 0) : 0
    for y in 34...hem {
        let k = (y - 34) / 3
        c.rect(18 - k + (y > 39 ? sway : 0), y, 20 + k * 2, 1, skirt)
    }
    c.rect(18 - (hem - 34) / 3 + sway, hem, 20 + (hem - 34) / 3 * 2, 1, skirtLight)
    c.oy += p.breathe
    drawBody(c, Look(arm: coat))
    // The coat: fitted, frogging across the front, the lace jabot and cameo at the throat.
    c.rect(18, 33, 20, 4, coat)
    c.rect(18, 36, 4, 3, coat); c.rect(34, 36, 4, 3, coat)   // the coat's tails over the skirt
    c.rect(37, 33, 1, 6, coatDark)
    for y in [34, 36] { c.rect(23, y, 3, 1, C(0x1A0A1C)); c.rect(30, y, 3, 1, C(0x1A0A1C)) }
    c.rect(26, 33, 4, 4, lace); c.px(27, 36, lace.alpha(0.6)); c.px(28, 37, lace.alpha(0.5))
    c.px(27, 34, C(0xE0B0A0)); c.px(28, 34, C(0xC88A7A))   // the cameo
    c.rect(19, 33, 1, 3, coatLight)
    // The hair: pinned up in a bun, wisps at the sides.
    c.pattern(17, 20, [
        "........HHHH..........",
        "......HHHlHHHHHHHHHH..",
        "....HHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHlHHHHHHHHHHHlHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH...............HH.",
        ".HH.................H.",
        ".H....................",
    ], ["H": hair, "l": hairLight])
    // The hat: small, black, tilted forward, a feather curling back.
    c.pattern(23, 15, [
        "F.............",
        ".FF...........",
        "..FFf.........",
        "...ffTTTTT....",
        "....TTTTTTT...",
        "..TTTTTTTTTTTT",
    ], ["T": hat, "F": C(0x8A4A9A), "f": C(0x5A2A6A)])
    c.px(32, 19, C(0xC83A6A))   // a hatpin's bead
    c.rect(31, 32, 3, 1, C(0x8A2A3A))   // a dark painted smile

    if open {
        // The umbrella up over her head, twirling; her arm raised to hold it.
        c.rect(38, 25, 3, 9, coat); c.rect(38, 24, 3, 1, clawdOrange)
        c.rect(39, 13, 1, 11, C(0x2A2A30))
        let spin = Int(p.lt * 10)
        for dy in 0...5 {
            let hw = [3, 8, 12, 14, 15, 16][dy]
            for x in (39 - hw)...(39 + hw) {
                let panel = ((x - 39 + 32 + spin) / 4) % 2 == 0
                c.px(x, 8 + dy, panel ? brolly : brollyLight)
            }
        }
        for x in stride(from: 23, through: 55, by: 4) { c.px(x + spin % 4 - 2, 14, brolly) }   // the scalloped hem
        c.px(39, 7, C(0x8A8E98))
        return
    }
    // The furled umbrella held out like a rifle: the crook in her fist, the tip forward.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, coat)
    let crook = C(0x6A4A2A)
    c.rect(36, 32, 3, 1, crook); c.px(36, 33, crook); c.px(36, 34, crook)
    c.rect(41, 33, 12, 1, C(0x2A2A30)); c.px(53, 33, C(0x8A8E98))
    c.rect(42, 34, 7, 1, brolly); c.rect(44, 35, 3, 1, brollyLight); c.px(43, 32, brollyLight)
    if firing(p) { c.px(53, 33, C(0xFFE0F4)) }
}

// MARK: - The Spy Master

/// The Spy Master: Clawd in a brown suit with a purple shirt and pocket square, short dark hair swept up at the front
/// and a full, close-trimmed beard round the jaw. He carries the tissue compression eliminator too, gold-tipped.
private func drawSpyMaster(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x6A4A30), suitDark = C(0x4A321E), suitLight = C(0x8A6444), shirt = C(0x6A2A8A), shirtLight = C(0x8A4AAA)
    let hair = C(0x16120E), hairLight = C(0x3A2A1E)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawShoes(c, step: p.step, C(0x2A1A10))
    c.oy += p.breathe
    drawBody(c, Look(arm: suit))
    // The suit: jacket over the purple shirt, a purple pocket square.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 5, shirt); c.rect(27, 33, 2, 1, shirtLight)
    c.rect(23, 33, 2, 3, suitLight); c.rect(31, 33, 2, 3, suitLight)
    c.rect(37, 33, 1, 5, suitDark); c.rect(18, 37, 20, 1, suitDark)
    c.rect(33, 35, 2, 1, shirtLight)
    c.rect(15, 33, 3, 3, suit)
    // The hair: short, swept up into a quiff at the front.
    c.pattern(17, 21, [
        "...............HHH....",
        "......HHHHHHHHHHHHH...",
        "...HHHHHHHHHHHlllHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH..............HHH.",
        ".HHH...............HH.",
        ".HH................HH.",
    ], ["H": hair, "l": hairLight])
    drawBrows(c, hair)
    // The full beard: down the jaw from the sideburns and round the chin.
    c.rect(18, 29, 2, 4, hair); c.rect(36, 29, 2, 4, hair)
    c.rect(19, 32, 18, 2, hair); c.rect(25, 31, 7, 1, hair)
    c.rect(26, 32, 5, 1, C(0x5A2A1A))   // the smirk inside it
    c.px(20, 33, hairLight); c.px(34, 33, hairLight)
    // The right arm and his eliminator, gold-tipped.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, suit)
    drawEliminator(c, body: C(0x18181C), band: C(0xC89A2A), tip: C(0xE8B020), lit: firing(p))
}

// MARK: - The Ranee

/// The Ranee: a Time Lady, Clawd in a crimson gown-coat with gold-braided shoulders and a high gold collar, dark red
/// hair swept up into a tall sculpted crown, a gold diadem with a green stone, black trousers and knee boots. She fires
/// a small gold pistol of her own making, its shots teal.
private func drawRanee(_ c: PixelCanvas, _ p: Pose) {
    let crimson = C(0x8A1A2A), crimsonDark = C(0x5A0E1A), crimsonLight = C(0xB02A3A), gold = C(0xE0B040)
    let goldDark = C(0x9A7428), hair = C(0x6A1A14), hairLight = C(0x9A2E1E), boot = C(0x141016)
    drawLegs(c, Look(leg: boot), step: p.step)
    drawShoes(c, step: p.step, C(0x0A080C), rows: 1)
    // The gown-coat's skirts, behind the legs.
    if !seatedPose {
        c.rect(16, 36, 3, 5, crimson); c.rect(37, 36, 3, 5, crimson)
        c.px(16, 40, gold); c.px(39, 40, gold)
    }
    c.oy += p.breathe
    // The high collar behind the head.
    c.pattern(16, 27, [
        "gg..................gg",
        "Ggg................ggG",
        "GGg................gGG",
        ".GGg..............gGG.",
        "..GG..............GG..",
    ], ["G": gold, "g": goldDark])
    drawBody(c, Look(arm: crimson))
    // The gown-coat: crimson with a gold seam, braided shoulders.
    c.rect(18, 33, 20, 5, crimson)
    c.rect(27, 33, 2, 5, gold); c.px(27, 35, C(0x2AC8B0)); c.px(28, 35, C(0x2AC8B0))
    c.rect(18, 37, 20, 1, crimsonDark); c.rect(37, 33, 1, 5, crimsonDark)
    c.rect(20, 34, 1, 3, crimsonLight)
    c.rect(15, 32, 4, 1, gold); c.rect(15, 33, 3, 3, crimson)
    // The hair: swept up into a tall sculpted crown.
    c.pattern(17, 14, [
        "........HHHHH.........",
        ".......HHHlHHH........",
        "......HHHlHHHHH.......",
        "......HHlHHHHHH.......",
        ".....HHHHHHHHHHH......",
        "....HHHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHlHHHHHHHHlHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHH........HHHHHH.",
        ".HHHH............HHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
        ".H..................H.",
    ], ["H": hair, "l": hairLight])
    // The diadem.
    c.rect(19, 25, 18, 1, gold); c.rect(26, 24, 4, 1, gold); c.px(27, 23, gold); c.px(28, 23, gold)
    c.rect(27, 24, 2, 2, C(0x3AE87A)); c.px(27, 24, C(0xC8FFD8))
    c.px(19, 32, gold); c.px(36, 32, gold)   // earrings
    c.rect(31, 32, 3, 1, C(0x6A0E1A))   // a thin cold smile
    // The right arm and the gold pistol.
    c.oy += p.gunY
    c.rect(37, 32, 4, 1, gold); c.rect(38, 33, 3, 3, crimson)
    c.pattern(40, 32, ["..GGGGg", "GGGGGGg", "GGd....", ".Gd...."], ["G": gold, "g": goldDark, "d": goldDark])
    c.px(46, 33, firing(p) ? C(0xE0FFF8) : C(0x2AC8B0))
}
