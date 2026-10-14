import Foundation

// Heroes: the X-Men, in their 90s animated-series colours. Clawd in costume, as ever: the body is the face (Clawd
// orange where the hero shows skin), with cowls, hair and suits drawn over it.

let heroes3: [MarvelHero: Persona] = [
    .wolverine: Persona(name: "Clawdverine", weapon: .saber, headTop: 16, signature: 2.6,
                  draw: drawWolverine),
    .cyclops: Persona(name: "Cyclopz", weapon: .blaster, shot: .beam(core: C(0xFFE0E0), glow: C(0xFF2A3A)),
                  muzzle: (37, 28.5), handGun: false, headTop: 22, signature: 2.4,
                  draw: drawCyclops),
    .storm: Persona(name: "Stormy", weapon: .lightning, motion: .fly, magic: Magic(core: C(0xFFFFFF), glow: C(0x8AC8FF)),
                  headTop: 18, signature: 3.2,
                  draw: drawStorm),
    .jeanGrey: Persona(name: "Jeanne Grae", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFE0F4), glow: C(0xFF4AC8), jagged: false),
                  headTop: 19, signature: 3.2,
                  draw: drawJeanGrey),
    .professorX: Persona(name: "Professor Why", motion: .hover, canSit: false, headTop: 22, signature: 3.2,
                  draw: drawProfessorX),
    .beast: Persona(name: "The Beest", weapon: .saber, pivot: (41.5, 33.5), bulk: 2, headTop: 18, signature: 3.5,
                  draw: drawBeast),
    .nightcrawler: Persona(name: "Nightclawdler", weapon: .saber, headTop: 21, signature: 2.8,
                  draw: drawNightcrawler),
    .gambit: Persona(name: "Gamblit", weapon: .blaster, shot: .card, muzzle: (41, 31.5), headTop: 21, signature: 2.8,
                  draw: drawGambit),
    .rogue: Persona(name: "Rouge", weapon: .saber, motion: .fly, headTop: 18, signature: 3.0,
                  draw: drawRogue),
    .iceman: Persona(name: "Ice Dude", weapon: .blaster, motion: .fly, shot: .ice, muzzle: (40, 33.5), handGun: false,
                  headTop: 22, signature: 2.8,
                  draw: drawIceman),
    .colossus: Persona(name: "Colossos", weapon: .saber, armoured: true, pivot: (42.5, 33.5), bulk: 2, headTop: 20, signature: 3.2,
                  draw: drawColossus),
]

// MARK: - Shared pieces

private let skin = clawdOrange, skinShade = clawdShade
private let steelBlade = C(0xDCE0E8), clear = C(0, 0)

/// Legs, standing or walking (with boots in `boot`), or swept back in flight.
private func drawSuitLegs(_ c: PixelCanvas, _ p: Pose, _ leg: Px, boot: Px? = nil, bootRows: Int = 2) {
    if p.flying {
        let sweep = [(0, 36), (0, 37), (-1, 38), (-2, 39), (-3, 40)]
        for lx in [19, 23, 31, 35] {
            for (i, s) in sweep.enumerated() {
                let col = boot != nil && i >= sweep.count - bootRows ? boot! : leg
                c.rect(lx + s.0, s.1, 2, 1, col)
            }
        }
        return
    }
    drawLegs(c, Look(leg: leg), step: p.step)
    guard let boot else { return }
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx + 1, 38, 2, 2, boot) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, (lifted ? 42 : 43) - bootRows + 1, 2, bootRows, boot)
    }
}

/// A punch: the arm reaching out from the shoulder `s` at `angle`, a fist on the end; a fast swing smears.
private func drawFist(_ c: PixelCanvas, angle: Double, trail: [Double], from s: (x: Double, y: Double),
                      reach: Double = 6, arm: Px, fist: Px, size: Int = 3) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * (reach - 2), s.y + sin(r) * (reach - 2), s.x + cos(r) * (reach + 1), s.y + sin(r) * (reach + 1),
                   core: white.alpha(0.35 / Double(i + 1)), glow: white.alpha(0.2 / Double(i + 1)), coreR: 0.8, glowR: 1.8)
    }
    let r = angle * .pi / 180
    let ex = s.x + cos(r) * reach, ey = s.y + sin(r) * reach
    c.glowLine(s.x, s.y, ex, ey, core: arm, glow: clear, coreR: 1.1, glowR: 1.2)
    let x0 = Int((ex - Double(size) / 2).rounded()), y0 = Int((ey - Double(size) / 2).rounded())
    c.rect(x0, y0, size, size, fist)
}

/// Three blades out of the fist at `angle`; `out` 0…1 how far they're unsheathed.
private func drawClaws(_ c: PixelCanvas, angle: Double, out: Double, trail: [Double]) {
    let hx = Sprite.hand.x - 1, hy = Sprite.hand.y - 0.5
    let len = 1 + 8 * out
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(hx + cos(r) * 3, hy + sin(r) * 3, hx + cos(r) * (2 + len), hy + sin(r) * (2 + len),
                   core: white.alpha(0.3 / Double(i + 1)), glow: C(0xBFD8FF).alpha(0.3 / Double(i + 1)), coreR: 0.8, glowR: 2.2)
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    for k in [-1.0, 1.0] {                                            // dark between the blades, so they read apart
        let bx = hx + ux * 1.5 + nx * k, by = hy + uy * 1.5 + ny * k
        c.glowLine(bx, by, bx + ux * (len - 1.5), by + uy * (len - 1.5), core: C(0x2A2E3A), glow: clear, coreR: 0.5, glowR: 0.55)
    }
    for k in [-2.0, 0, 2.0] {
        let bx = hx + ux * 1.5 + nx * k, by = hy + uy * 1.5 + ny * k
        c.glowLine(bx, by, bx + ux * len, by + uy * len, core: steelBlade, glow: clear, coreR: 0.4, glowR: 0.45)
    }
}

/// An outline ellipse, `n` dots round it.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px, n: Int = 40) {
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        c.px(Int((cx + cos(a) * rx).rounded()), Int((cy + sin(a) * ry).rounded()), col)
    }
}

/// A four-pointed twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

// MARK: - Wolverine

/// Wolverine: yellow and blue, the cowl's two black-edged fins sweeping up off his head, blue gloves, yellow legs in
/// tall blue boots. Fights with his claws, which stay retracted when he's not using them. Signature: SNIKT, he
/// raises a fist and the three claws shoot out, glinting, then slide back in.
private func drawWolverine(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xF2C230), yShade = C(0xC89A1A), blue = C(0x2A4FB0), blueDark = C(0x1C3478), black = C(0x16161B)
    drawSuitLegs(c, p, yellow, boot: blue, bootRows: 4)
    c.oy += p.breathe
    drawBody(c, Look(body: yellow, shade: yShade, arm: blue, eye: nil))
    c.pattern(16, 16, [
        "K......................K",
        "BK....................KB",
        "BBK..................KBB",
        ".BBK................KBB.",
        ".BBBK..............KBBB.",
        "..BBBK............KBBB..",
        "..BBBBKBBBBBBBBBBKBBBB..",
        "..BBBBBBBBBBBBBBBBBBBB..",
        "..BBBBBBBBBBBBBBBBBBBB..",
        "..BBKKKKKBBBBBBKKKKKbB..",
        "..BKKKKKKKYYYYKKKKKKKB..",
        "..KKKKWWKKYYYYKKKWWKKK..",
        "..YKKKWWKKYYYYKKKWWKKY..",
        "..YYKKKKYYYYYYYKKKKYYY..",
    ], ["B": blue, "b": blueDark, "K": black, "W": white, "Y": yellow])
    c.rect(18, 31, 3, 6, blue)                                       // blue flanks, black tiger stripes
    c.rect(35, 31, 3, 6, blue)
    for y in [32, 34] { c.rect(20, y, 2, 1, black); c.rect(34, y, 2, 1, black) }
    c.rect(18, 36, 20, 1, C(0xB8862A))                               // belt
    c.rect(26, 36, 4, 1, C(0xC8202A))
    // Claws: out when he's fighting; SNIKT for the signature.
    if let s = p.signature, p.melee == nil {
        let out = habitArc(min(1, max(0, (s - 0.1) / 0.8)), hold: 0.55)
        c.rect(38, 30, 3, 4, yellow); c.rect(38, 27, 3, 3, blue)     // forearm up, fist raised
        c.oy -= 4
        drawClaws(c, angle: -55, out: out, trail: [])
        if out > 0.95 {                                              // the glint along the blades
            let g = frac(s * 5)
            let gx = 41 + Int(g * 6), gy = 31 - Int(g * 7)
            twinkle(c, gx, gy, C(0xFFFFFF))
        }
        c.oy += 4
    } else if let a = p.melee {
        drawClaws(c, angle: a, out: 1, trail: p.trail)
    }
}

// MARK: - Cyclops

/// Cyclops: navy suit and cowl, brown hair poking out on top, the gold-framed ruby visor right across his face,
/// yellow gloves, boots and harness. His optic blast comes out of the visor, a hand raised to it as he fires.
/// Signature: two fingers to the side of the visor, and it flares.
private func drawCyclops(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x24346E), navyShade = C(0x18244E), gold = C(0xE8C02A), ruby = C(0xD8202A), hair = C(0x6A4424)
    drawSuitLegs(c, p, navy, boot: gold, bootRows: 3)
    c.oy += p.breathe
    let firing = p.fire != nil || p.gunY != 0 || p.signature != nil
    drawBody(c, Look(body: navy, shade: navyShade, arm: gold, eye: nil), armRight: firing ? 5 : 0)
    c.pattern(19, 22, [
        "...HH.HHH.HH.....",
        "..HHHHHHHHHHHH...",
        ".NNNNNNNNNNNNNNN.",
        "NNNNNNNNNNNNNNNNN",
    ], ["H": hair, "N": navy])
    c.rect(19, 25, 17, 1, navy)
    // The visor.
    c.rect(18, 27, 21, 1, gold)
    c.rect(18, 30, 21, 1, gold)
    c.rect(18, 28, 1, 2, gold)
    c.rect(19, 28, 20, 2, ruby)
    c.rect(21, 28, 5, 1, C(0xFF7A7A))
    c.px(38, 28, C(0xFF9A9A))
    c.pattern(25, 31, ["GG..GG", ".GGGG.", ".G..G."], ["G": gold])  // harness meeting on his chest
    c.rect(19, 32, 2, 4, gold); c.rect(35, 32, 2, 4, gold)
    c.rect(18, 36, 20, 1, gold)
    c.rect(26, 36, 4, 1, C(0xC8202A))
    if let s = p.signature {
        // Two fingers on the side of the visor; it glows hot, flares, then cools.
        let k = habitArc(s, hold: 0.4)
        c.rect(39, 26, 1, 2, gold)
        c.glowLine(20, 28.5, 37.5, 28.5, core: C(0xFFE0E0).alpha(k), glow: C(0xFF2A3A).alpha(k), coreR: 0.5, glowR: 2)
        if k > 0.9 {
            let flick = 0.8 + 0.2 * sin(s * 80)
            c.glowLine(38, 28.5, 42, 28.5, core: white, glow: C(0xFF2A3A), coreR: 0.8, glowR: 2.6 * flick)
        }
    } else if p.fire != nil {
        c.glowLine(20, 28.5, 37.5, 28.5, core: C(0xFFC0C0).alpha(0.7), glow: C(0xFF2A3A).alpha(0.5), coreR: 0.4, glowR: 1.5)
    }
}

// MARK: - Storm

/// Storm: a great white mane, a gold tiara, a black suit and a billowing black cape. She flies with her hair and cape
/// streaming behind her, and throws lightning. Signature: her eyes go white and the wind lifts her hair, crackling.
private func drawStorm(_ c: PixelCanvas, _ p: Pose) {
    let hairW = C(0xF2F2F6), hairS = C(0xC8CCD8), suit = C(0x24242C), suitEdge = C(0x5A5A6E), cape = C(0x3A3A4C), gold = C(0xF0C030)
    let tan = C(0x9A5A3A), tanShade = C(0x7A4428)
    let lift = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let up = Int((lift * 3).rounded())
    // Cape and the long fall of hair, behind her.
    if p.flying {
        for y in 27...36 {
            let len = 7 + (y - 27) / 2 + Int((sin(p.t * 12 + Double(y) * 0.7) * 1.5).rounded())
            c.rect(18 - len, y, len, 1, y == 36 ? suitEdge : cape)
            c.px(18 - len, y, suitEdge)
        }
        for y in 20...28 {
            let len = 6 + (y % 3) + Int((sin(p.t * 14 + Double(y)) * 1.2).rounded())
            c.rect(17 - len, y, len + 2, 1, y % 4 == 0 ? hairS : hairW)
        }
    } else {
        drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: suitEdge)
        let fall = 36 - Int((lift * 7).rounded())
        for (x, w) in [(15 - up / 2, 3), (38 + up / 2, 3)] {          // the long fall, ragged at the ends
            c.rect(x, 25, w, fall - 25, hairW)
            c.rect(x + (x < 28 ? 0 : 2), 27, 1, fall - 28, hairS)
            c.px(x + (x < 28 ? 1 : 1), fall, hairW); c.px(x + (x < 28 ? 0 : 2), fall + 1, hairS)
        }
    }
    drawSuitLegs(c, p, suit, boot: C(0x16161B), bootRows: 4)
    c.oy += p.breathe
    drawBody(c, Look(body: tan, shade: tanShade, arm: suit, eye: nil), armRight: p.armRaise)
    c.pattern(15, 18 - up, [
        ".......WWWWWWWWWWWW.......",
        ".....WWWWWWWWWWWWWWWW.....",
        "...WWWWWWWWWSWWWWWWWWWW...",
        "..WWWWWSWWWWWWWWWWSWWWWW..",
        ".WWWWWWWWWWWWWWWWWWWWWWWW.",
        ".WWWSWWWWWWWWWWWWWWWWSWWW.",
        "WWWWWWWWWWWWWWWWWWWWWWWWWW",
        "WWWWWW..............WWWWWW",
    ], ["W": hairW, "S": hairS])
    if up > 0 {
        for k in 0..<up { c.rect(18, 26 - k, 20, 1, hairW) }         // the hairline as the mane lifts
        for i in 0..<5 {                                              // strands flicking up
            let x = 17 + i * 5, h = 2 + Int(noise(Int(p.t * 12) + i) * 3)
            c.rect(x, 18 - up - h, 1, h, i % 2 == 0 ? hairW : hairS)
        }
    }
    c.rect(19, 26, 18, 1, gold)                                      // tiara
    c.rect(27, 25, 2, 1, gold); c.px(27, 24, gold)
    // Eyes: white and glowing while she calls the storm.
    if lift > 0.3 {
        for x in [22, 32] {
            c.glowLine(Double(x) + 1, 29.5, Double(x) + 1, 30.5, core: white, glow: C(0x8AC8FF).alpha(lift), coreR: 1, glowR: 2.2)
        }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.rect(18, 33, 20, 5, suit)                                      // black suit, gold clasp and belt
    c.rect(18, 33, 20, 1, suitEdge)
    c.rect(26, 33, 4, 1, gold)
    c.rect(18, 36, 20, 1, C(0x3A3A46))
    if p.flying { c.rect(38, 31, 5, 2, suit); c.rect(42, 30, 2, 3, suit) }   // an arm thrust forward
    if let s = p.signature, lift > 0.5 {
        // Wind swirling round her, and a crackle overhead.
        for i in 0..<3 {
            let a = s * 18 + Double(i) * 2.1
            let x = 28 + cos(a) * 15, y = 30 + sin(a) * 4
            c.glowLine(x, y, x + 3, y - 0.5, core: white.alpha(0.6), glow: C(0x8AC8FF, 0.4), coreR: 0.4, glowR: 1)
        }
        if noise(Int(s * 30)) > 0.5 {
            drawMagicSpark(c, x: 28, y: 12 - up, seed: Int(s * 30))
        }
    }
}

/// A tiny forked spark at (`x`, `y`): a few pixels of lightning.
private func drawMagicSpark(_ c: PixelCanvas, x: Int, y: Int, seed: Int) {
    var px = x
    for k in 0..<4 {
        px += Int(noise(seed + k) * 3) - 1
        c.px(px, y + k, k % 2 == 0 ? white : C(0xBFE0FF))
    }
}

// MARK: - Jean Grey

/// Jean Grey as Phoenix: a long fall of red hair, green suit with a gold sash, gold gloves and boots and the
/// firebird on her chest. She hovers, and her telekinesis is a pink stream. Signature: the Phoenix Force flares and
/// flames lick up all round her.
private func drawJeanGrey(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD8401E), redDark = C(0xA02A14), green = C(0x2E9A3A), greenDark = C(0x1E7A2A), gold = C(0xF0C030)
    let fire = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    if fire > 0 {
        // Flames rising off her, behind the figure, flickering frame to frame.
        let seed = Int(p.t * 14)
        for i in 0..<12 {
            let x = 14 + i * 2 + (i > 5 ? 3 : 0)
            let h = Int((fire * (5 + noise(seed + i) * 8)).rounded())
            let top = (i == 0 || i == 11 ? 30 : (i == 1 || i == 10 ? 24 : 20)) - h
            let base = i == 0 || i == 11 ? 42 : 36
            c.rect(x, top, 2, base - top, C(0xFF5A1A).alpha(0.85))
            c.rect(x, top + 2, 1, max(0, base - top - 4), C(0xFFC23A).alpha(0.9))
            c.px(x + (noise(seed + i * 3) > 0.5 ? 1 : 0), top, C(0xFFF0A0))
        }
    }
    for x in [15, 38] { c.rect(x, 25, 3, 13, red); c.rect(x + (x < 28 ? 0 : 2), 28, 1, 10, redDark) }   // the long hair
    var dangle = p; dangle.step = -1                                 // hovering: legs dangle, toes down
    drawSuitLegs(c, dangle, green, boot: gold, bootRows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: gold, eye: ink), armRight: p.armRaise)
    c.pattern(15, 19, [
        "......RRRRRRRRRRRR......",
        "....RRRRRRRRRRRRRRRR....",
        "...RRRRRRrRRRRRRRRRRR...",
        "..RRRRRRRRRRRRRRrRRRRR..",
        ".RRRRrRRRRRRRRRRRRRRRRR.",
        ".RRRRRRRRRR..RRRRRRRRRRR",
        "RRRRRR............RRRRRR",
        "RRRR................RRRR",
    ], ["R": red, "r": redDark])
    c.rect(18, 33, 20, 5, green)                                     // suit
    c.rect(37, 33, 1, 5, greenDark)
    c.pattern(24, 33, ["G.G.G.G", ".GGGGG.", "..GGG..", "...G..."], ["G": fire > 0 ? C(0xFF8A2A) : gold])   // the firebird
    c.rect(18, 37, 20, 1, gold)                                      // the sash: round the waist, a tail at the hip
    c.rect(20, 37, 2, 4, gold); c.px(22, 40, gold)
    if fire > 0.6 {
        for x in [22, 32] { c.glowLine(Double(x) + 1, 29.5, Double(x) + 1, 30.5, core: C(0xFFF0A0), glow: C(0xFF5A1A), coreR: 1, glowR: 2) }
    }
}

// MARK: - Professor X

/// Professor X: bald (with a shine), a dark green suit and red tie, riding his yellow hover-chair on a little glowing
/// thruster. Never sits on the floor: he's sitting already. Signature: two fingers to his temple, psychic rings
/// spreading out from his head.
private func drawProfessorX(_ c: PixelCanvas, _ p: Pose) {
    let chair = C(0xF0C030), chairShade = C(0xC0901A), chairDark = C(0x6A5A3A), suit = C(0x2E5A3A), suitDark = C(0x1E4028)
    // The thruster's glow under the chair.
    let flick = noise(Int(p.t * 20))
    c.glowLine(27, 44, 29, 44, core: C(0xC8F0FF).alpha(0.8), glow: C(0x5AB8FF).alpha(0.6 + 0.3 * flick), coreR: 0.6, glowR: 2.2 + flick)
    if p.walking {
        for i in 0..<3 { c.rect(8 + i * 3 - Int(frac(p.t * 3) * 3), 34 + i * 3, 4, 1, C(0xC8F0FF).alpha(0.35)) }   // whoosh
    }
    c.oy += p.breathe
    // Chair: back, seat shell, thruster pod.
    c.rect(14, 22, 5, 18, chair); c.rect(14, 22, 5, 1, C(0xFFE07A)); c.rect(14, 22, 1, 18, chairShade)
    c.rect(14, 38, 26, 3, chair); c.rect(14, 40, 26, 1, chairShade)
    c.pattern(20, 41, ["DDDDDDDDDDDDDDD", ".DDDDDDDDDDDDD.", "...DDDDDDDDD..."], ["D": chairDark])
    // Legs folded on the seat, shins down to the footrest.
    c.rect(33, 36, 9, 2, suitDark); c.rect(40, 38, 2, 4, suitDark); c.rect(40, 42, 4, 1, ink)
    c.rect(38, 43, 7, 1, chairShade)
    let temple = p.signature != nil
    drawBody(c, Look(arm: suit, eye: ink), armRight: temple ? 5 : 0)
    c.rect(19, 26, 15, 1, C(0xF0A07A))                               // the shine on his dome
    c.rect(21, 25, 11, 1, skin)
    c.rect(22, 25, 4, 1, C(0xF4B08E))
    c.rect(18, 32, 20, 6, suit)                                      // suit, shirt, tie
    c.rect(37, 32, 1, 6, suitDark)
    c.pattern(25, 32, ["WW..WW", ".WRRW.", "..RR..", "..RR.."], ["W": white, "R": C(0xB8202A)])
    c.rect(36, 34, 5, 2, chair)                                      // the armrest
    if let s = p.signature {
        c.rect(38, 27, 2, 2, skin)                                   // two fingers on his temple
        let k = min(1, max(0, (s - 0.12) / 0.8))
        guard k > 0, k < 1 else { return }
        for i in 0..<3 {
            let f = frac(k * 2 + Double(i) / 3)
            let col = (i % 2 == 0 ? C(0xC87AFF) : C(0xFF7AE0)).alpha(0.9 * (1 - f))
            ring(c, 28, 26, 6 + f * 16, 3 + f * 9, col, n: 48)
        }
    }
}

// MARK: - Beast

/// Beast: big, blue and furry, a mop of dark hair, fangs, black trunks, huge hands and feet. Fights with his fists.
/// Signature: the scholar, tiny round glasses on, a book open in his paws, a page turned.
private func drawBeast(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x3A4ABA), furShade = C(0x2A3488), furLight = C(0x5A6AD8), hair = C(0x1A1E4A), trunks = C(0x1E1E26)
    if seatedPose {
        for lx in [18, 23, 31, 36] { c.rect(lx - 1, 38, 5, 2, fur); c.rect(lx + 3, 38, 2, 2, furShade) }
    } else {
        for (i, lx) in [18, 23, 31, 36].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 3, lifted ? 6 : 7, fur)
            c.rect(lx, lifted ? 42 : 43, 4, 1, furShade)              // big feet
        }
    }
    c.oy += p.breathe
    // A bigger, hunched Clawd.
    c.rect(16, 25, 23, 13, fur)
    c.rect(17, 24, 21, 1, fur)
    c.rect(16, 37, 23, 1, furShade); c.rect(38, 25, 1, 13, furShade)
    for (x, y) in [(18, 27), (24, 26), (35, 28), (20, 33), (29, 25), (33, 33)] { c.rect(x, y, 2, 1, furLight) }
    c.rect(12, 32, 4, 4, fur)                                        // the far paw
    c.pattern(15, 18, [
        "...H..H.HH...H.......",
        "..HHH.HHHHH.HHH.H....",
        ".HHHHHHHHHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHH.HHHHHH.HHHHHH.",
        "HH..H.......H....HHH.",
        "H.................HH.",
    ], ["H": hair])
    c.rect(20, 28, 5, 1, furShade); c.rect(30, 28, 5, 1, furShade)   // heavy brows
    c.rect(21, 29, 2, 3, ink); c.rect(31, 29, 2, 3, ink)
    c.rect(24, 32, 8, 1, furShade)                                   // a wide grin, fangs down
    c.px(25, 33, white); c.px(30, 33, white)
    c.rect(16, 35, 23, 3, trunks)
    if let s = p.signature {
        // Spectacles and a book.
        let glass = C(0xE8E8F0)
        for x in [20, 30] { c.pattern(x, 28, ["GGGG", "G..G", "GGGG"], ["G": glass]) }
        c.rect(24, 29, 6, 1, glass)
        c.rect(21, 32, 15, 6, C(0x8A2A1E))                          // the cover
        c.rect(22, 32, 6, 5, C(0xF4ECD8)); c.rect(29, 32, 6, 5, C(0xF4ECD8))
        c.rect(28, 32, 1, 5, C(0xC8BCA0))
        for y in [33, 35] { c.rect(23, y, 4, 1, C(0x9A9AA6)); c.rect(30, y, 4, 1, C(0x9A9AA6)) }
        let turn = frac(s * 2)
        if turn > 0.6, turn < 0.9 {                                   // a page lifting over
            let w = Int(((turn - 0.6) / 0.3 * 6).rounded())
            c.rect(28 - w, 31, max(1, w), 3, white)
        }
        c.rect(18, 33, 4, 4, furLight); c.rect(35, 33, 4, 4, furLight)   // paws holding it open
        return
    }
    if let a = p.melee {
        drawFist(c, angle: a, trail: p.trail, from: (39.5, 33.5), reach: 6, arm: fur, fist: furLight, size: 4)
        let r = a * .pi / 180
        c.px(Int((39.5 + cos(r) * 8.5).rounded()), Int((33.5 + sin(r) * 8.5).rounded()), white)   // a claw tip
    } else {
        c.rect(39, 31, 4, 4, fur)                                    // the near paw
        c.px(42, 34, white)
    }
}

// MARK: - Nightcrawler

/// Nightcrawler: indigo skin, pointed ears, glowing yellow eyes and a fanged grin; red and black suit with white
/// gloves and a spade-tipped tail that never keeps still. He fences with a rapier, swashbuckler that he is.
/// Signature: BAMF, he vanishes in a puff of brimstone smoke and pops back out of another.
private func drawNightcrawler(_ c: PixelCanvas, _ p: Pose) {
    let indigo = C(0x3A3F8A), indigoShade = C(0x2A2E6A), hair = C(0x16163A), red = C(0xB8202A), black = C(0x1A1A22)
    let eye = C(0xF5E04A)
    var gone = false
    if let s = p.signature {
        // Out in a puff at 0.2, gone, back in another at 0.5.
        for (start, cx) in [(0.2, 28.0), (0.5, 28.0)] {
            let f = (s - start) / 0.38
            guard f > 0, f < 1 else { continue }
            for i in 0..<7 {
                let a = Double(i) / 7 * 2 * .pi + start * 10
                let r = 4 + f * 9
                let x = cx + cos(a) * r * 1.2, y = 31 + sin(a) * r * 0.8 - f * 4
                let col = (i % 2 == 0 ? C(0x6A5A80) : C(0x9A8AB0)).alpha(0.9 * (1 - f * f))
                c.circle(Int(x.rounded()), Int(y.rounded()), Int(4 - f * 2), col)
            }
            c.circle(Int(cx), 31, Int(6 - f * 5), C(0x5A4A70).alpha(1 - f))
        }
        gone = s > 0.26 && s < 0.6
    }
    if gone { return }
    // The tail, swishing behind him.
    let sw = sin(p.lt * 3)
    let tip = (x: 9.0 + sw * 1.5, y: 27.0 - sw * 2)
    c.glowLine(19, 36, 13, 37, core: indigo, glow: clear, coreR: 0.6, glowR: 0.7)
    c.glowLine(13, 37, 10, 33, core: indigo, glow: clear, coreR: 0.6, glowR: 0.7)
    c.glowLine(10, 33, tip.x, tip.y + 2, core: indigo, glow: clear, coreR: 0.6, glowR: 0.7)
    c.pattern(Int(tip.x.rounded()) - 1, Int(tip.y.rounded()) - 1, [".S.", "SSS", ".S."], ["S": indigo])
    drawSuitLegs(c, p, black, boot: white, bootRows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: indigo, shade: indigoShade, arm: white, eye: nil))
    c.pattern(16, 21, [
        "...HH.HHHH.HH.HH......",
        "..HHHHHHHHHHHHHHH.....",
        ".HHHHHHHHHHHHHHHHHHH..",
        "IHHHH.HHHHHHHHH.HHHHHI",
        "II..H...........H...II",
        ".I..................I.",
    ], ["H": hair, "I": indigo])
    for x in [22, 32] {                                              // glowing yellow eyes
        c.rect(x, 29, 2, 2, eye); c.px(x, 31, C(0xC8A82A)); c.px(x + 1, 31, C(0xC8A82A))
    }
    c.rect(25, 32, 6, 1, ink); c.px(25, 33, white); c.px(30, 33, white)   // the grin
    c.rect(18, 34, 20, 4, black)                                     // the suit: red over the shoulders and down
    c.pattern(18, 33, ["RRR..............RRR", ".RRR............RRR.", "..RRR..........RRR..", "...RRR........RRR..."], ["R": red])
    if let a = p.melee {
        drawRapier(c, angle: a, trail: p.trail)
    } else {
        c.glowLine(36, 37, 44, 42, core: C(0xC8CCD4), glow: clear, coreR: 0.4, glowR: 0.5)   // sheathed at his hip
        c.rect(35, 36, 2, 2, C(0xD8A830))
    }
}

/// A slim swept-hilt rapier from the hand at `angle`.
private func drawRapier(_ c: PixelCanvas, angle: Double, trail: [Double]) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(hx + cos(r) * 4, hy + sin(r) * 4, hx + cos(r) * 18, hy + sin(r) * 18,
                   core: white.alpha(0.3 / Double(i + 1)), glow: C(0xBFD8FF).alpha(0.25 / Double(i + 1)), coreR: 0.5, glowR: 1.8)
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    c.glowLine(hx - ux * 1.5, hy - uy * 1.5, hx + ux * 1.5, hy + uy * 1.5, core: C(0x5A3A22), glow: clear, coreR: 0.6, glowR: 0.7)
    c.glowLine(hx + ux * 2 - nx * 2, hy + uy * 2 - ny * 2, hx + ux * 2 + nx * 2, hy + uy * 2 + ny * 2,
               core: C(0xD8A830), glow: clear, coreR: 0.55, glowR: 0.6)
    c.glowLine(hx + ux * 2.5, hy + uy * 2.5, hx + ux * 18, hy + uy * 18, core: steelBlade, glow: clear, coreR: 0.4, glowR: 0.5)
}

// MARK: - Gambit

/// Gambit: brown trench coat, magenta cowl framing his face, red-on-black eyes, a pink chest plate, his bo staff
/// slung across his back and a kinetically charged card between his fingers. Signature: he shuffles the deck, the
/// cards springing hand to hand in an arc.
private func drawGambit(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x7A4E2A), coatShade = C(0x5A3820), cowl = C(0xC83A8A), suit = C(0x2A2E5A), hair = C(0x4A2E18)
    c.glowLine(10, 41, 20, 23, core: C(0x8A8E99), glow: clear, coreR: 0.6, glowR: 0.7)   // the staff on his back
    for x in [15, 36] {                                              // the long coat-tails, open at the front
        c.rect(x, 30, 5, 12, coat)
        c.rect(x == 15 ? 15 : 40, 32, 1, 10, coatShade)
    }
    drawSuitLegs(c, p, suit, boot: cowl, bootRows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: coat, eye: nil))
    c.pattern(16, 21, [
        "...HHHHHHHHHHHH.....",
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHMMMMMMMMMMMMMMHHH",
        "HHMMMMMMMMMMMMMMMMHH",
        "..MM............MM..",
        "..MM............MM..",
        "..MM............MM..",
        "..MM............MM..",
        "..MM............MM..",
        "...MMMMMMMMMMMMMM...",
    ], ["H": hair, "M": cowl])
    for x in [22, 32] { c.rect(x, 29, 2, 3, ink); c.px(x + 1, 30, C(0xFF2A2A)) }   // red-on-black eyes
    c.rect(18, 32, 20, 6, C(0xB03A80))                              // chest plate
    c.rect(22, 34, 12, 1, C(0x8A2A60))
    c.rect(18, 31, 3, 7, coat); c.rect(35, 31, 3, 7, coat)          // the open coat
    c.rect(17, 30, 3, 3, coatShade); c.rect(36, 30, 3, 3, coatShade)   // collar
    if let s = p.signature {
        // Hands together in front, the deck springing from one to the other.
        c.rect(37, 35, 12, 2, coatShade)                             // the far arm reaching across
        c.rect(38, 33, 3, 3, coat); c.rect(48, 33, 3, 3, coat)       // both hands out front, a span apart
        let k = min(1, max(0, (s - 0.1) / 0.8))
        for i in 0..<7 {
            let f = frac(k * 3 + Double(i) / 7)
            let x = 40.5 + f * 7, y = 33 - sin(f * .pi) * 6
            c.rect(Int(x.rounded()), Int(y.rounded()), 1, 2, i % 2 == 0 ? white : C(0xC82A2A))
        }
        return
    }
    c.oy += p.gunY
    c.rect(40, 30, 2, 3, white)                                     // the card, glowing
    c.px(40, 30, C(0xC82A2A))
    c.glowLine(41, 31.5, 41, 31.5, core: C(0xFFE8F8, 0.6), glow: C(0xFF3AC8, 0.5), coreR: 0.5, glowR: 2.6)
}

// MARK: - Rogue

/// Rogue: big auburn hair with the white streak, green and yellow suit, brown bomber jacket, yellow gloves and boots.
/// Flies fist-first, and fights with her fists. Signature: she peels off a glove, careful, that touch is dangerous.
private func drawRogue(_ c: PixelCanvas, _ p: Pose) {
    let hairC = C(0x7A3A1E), hairDark = C(0x5A2814), streak = C(0xF4F4F4), green = C(0x2E8A3A), yellow = C(0xF0C830)
    let jacket = C(0x7A4A28), jacketShade = C(0x5A3418)
    if p.flying {
        for y in 22...30 {
            let len = 5 + (y % 3) + Int((sin(p.t * 14 + Double(y)) * 1.2).rounded())
            c.rect(17 - len, y, len + 2, 1, y % 3 == 0 ? hairDark : hairC)
        }
    } else {
        for x in [15, 38] { c.rect(x, 24, 3, 10, hairC); c.rect(x + (x < 28 ? 0 : 2), 27, 1, 7, hairDark) }
    }
    drawSuitLegs(c, p, green, boot: yellow, bootRows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: yellow, eye: ink))
    c.pattern(15, 18, [
        ".......HHHHHHHHHHH........",
        ".....HHHHHHHHHHHHHHHH.....",
        "...HHHHHHHhHHHHHWWHHHHH...",
        "..HHHHHHHHHHHHHWWHHHHHHH..",
        ".HHHHhHHHHHHHHWWHHHHhHHHH.",
        ".HHHHHHHHHHHHHWWHHHHHHHHH.",
        "HHHHHHHHHHHHHWW.HHHHHHHHHH",
        "HHHHHH.......WW....HHHHHHH",
        "HHHH.........W.......HHHHH",
    ], ["H": hairC, "h": hairDark, "W": streak])
    c.rect(18, 33, 20, 5, green)                                     // suit: green, yellow down the middle
    c.rect(25, 33, 6, 5, yellow)
    c.rect(18, 32, 4, 6, jacket); c.rect(34, 32, 4, 6, jacket)      // jacket
    c.rect(18, 37, 4, 1, jacketShade); c.rect(34, 37, 4, 1, jacketShade)
    if let s = p.signature {
        // Arm out, the glove sliding off the fingers, a bare hand that shimmers, then the glove back on.
        let k = habitArc(s, hold: 0.45)
        c.rect(38, 33, 3, 3, skin)
        let off = Int((k * 5).rounded())
        c.rect(38 + off, 33, 3, 3, yellow)
        if k > 0.95 {
            twinkle(c, 41, 32, C(0xC8FF7A).alpha(frac(s * 6) < 0.5 ? 1 : 0.5))
        }
        return
    }
    if let a = p.melee {
        drawFist(c, angle: a, trail: p.trail, from: (39.5, 34.5), reach: 5, arm: jacket, fist: yellow)
    } else if p.flying {
        c.rect(38, 31, 6, 2, jacket); c.rect(43, 30, 3, 3, yellow)   // fist first
    }
}

// MARK: - Iceman

/// Iceman: a Clawd made of ice, pale glowing eyes, frost highlights and a crown of icicles. Flies on an ice slide
/// that grows under his feet; fires frost from his hand. Signature: he ices over even harder, spikes of ice bristle
/// up across his head and shoulders, sparkle, and melt away.
private func drawIceman(_ c: PixelCanvas, _ p: Pose) {
    let ice = C(0xA8E0F8), iceShade = C(0x6AB8E0), frost = C(0xE8FAFF), deep = C(0x3A88B8)
    if p.flying {
        // The slide: a ramp of ice from under his feet down and back to the ground.
        for x in 2...42 {
            let y = 44 + Int(Double(42 - x) / 5)
            c.rect(x, y, 1, 3, ice)
            c.px(x, y, frost)
            if x % 5 == 0 { c.px(x, y + 2, iceShade) }
        }
    }
    var surf = p; surf.flying = false                                // riding the slide, standing up
    if p.flying { surf.step = -1 }
    drawSuitLegs(c, surf, ice, boot: iceShade, bootRows: 1)
    c.oy += p.breathe
    drawBody(c, Look(body: ice, shade: iceShade, arm: ice, eye: nil))
    for (x, y, l) in [(19, 27, 4), (30, 34, 5), (21, 35, 3), (34, 27, 2)] {   // facets catching the light
        for k in 0..<l { c.px(x + k, y - k / 2, frost) }
    }
    c.pattern(18, 22, [
        "..F...F.....F....F..",
        ".FI..FI..F.FI...FI..",
        ".II.FII.FI.II..FII.F",
        "IIIIIIIIIIIIIIIIIIII",
    ], ["F": frost, "I": ice])
    for x in [22, 32] { c.rect(x, 29, 2, 3, deep); c.px(x, 29, frost) }           // deep blue, a glint of frost
    c.rect(24, 33, 8, 1, iceShade)
    if let s = p.signature {
        let k = habitArc(s, hold: 0.5)
        let n = Int((k * 5).rounded())
        for (i, x) in [17, 21, 26, 30, 35, 38].enumerated() {
            let h = n + (i % 2 == 0 ? 1 : 0)
            guard h > 0 else { continue }
            c.rect(x, 22 - h, 1, h, frost)
            c.px(x + 1, 22 - h + 1, ice)
        }
        if n > 0 {
            for x in [15, 40] { c.rect(x, 31 - n / 2, 2, n, frost) }   // shoulder spikes
        }
        if k > 0.95 { drawGlint(c, p: frac(s * 1.4), maxX: 42) }
        return
    }
    if p.fire != nil {
        c.oy += p.gunY
        c.glowLine(41, 34, 41, 34, core: frost, glow: C(0x7FD8FF, 0.7), coreR: 0.8, glowR: 2.4)
    }
}

// MARK: - Colossus

/// Colossus: a big steel Clawd, rivet-seamed, short black hair, red suit with a yellow trim and belt, red legs and
/// steel feet. Armoured (shots ring off him) and fights with his fists. Signature: he armours up, flesh turning to
/// steel from the head down, with a gleam to finish.
private func drawColossus(_ c: PixelCanvas, _ p: Pose) {
    let steel = C(0xB8BEC8), steelShade = C(0x8A909C), seam = C(0x6A707C), red = C(0xC8202A), yellow = C(0xF0C030)
    if seatedPose {
        for lx in [18, 23, 31, 36] { c.rect(lx - 1, 38, 5, 2, red); c.rect(lx + 2, 38, 2, 2, steel) }
    } else {
        for (i, lx) in [18, 23, 31, 36].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 3, lifted ? 7 : 8, red)
            c.rect(lx, lifted ? 41 : 42, 3, 2, steel)
        }
    }
    c.oy += p.breathe
    // A broad, square Clawd, in steel.
    let body = (x: 16, y: 23, w: 24, h: 15)
    c.rect(body.x, body.y, body.w, body.h, steel)
    c.rect(body.x, body.y + body.h - 1, body.w, 1, steelShade); c.rect(body.x + body.w - 1, body.y, 1, body.h, steelShade)
    for (x, y, w) in [(17, 27, 4), (34, 26, 5), (24, 25, 4), (18, 31, 3), (35, 31, 3)] { c.rect(x, y, w, 1, seam) }
    c.rect(12, 32, 4, 4, steel); c.rect(12, 33, 4, 1, seam)          // far fist
    // Signature: below the line he's flesh; the line sweeps down as the steel comes over him.
    var steelTo = 99
    if let s = p.signature {
        steelTo = s < 0.25 ? 22 : (s < 0.7 ? 22 + Int((s - 0.25) / 0.45 * 16) : 99)
        if steelTo < 99 {
            for y in max(steelTo, body.y)..<(body.y + body.h) { c.rect(body.x, y, body.w, 1, y == body.y + body.h - 1 ? skinShade : skin) }
            if steelTo > body.y { c.rect(body.x, steelTo, body.w, 1, C(0xE8ECF2)) }   // the shining edge
            c.rect(12, 32, 4, 4, steelTo > 32 ? steel : skin)
        }
    }
    c.pattern(16, 20, [
        "....HHHHHHHHHHHHH.......",
        "..HHHHHHHHHHHHHHHHHH....",
        ".HHHHHHHHHHHHHHHHHHHHH..",
        ".HHHH..HHHHHHHHH..HHHH..",
    ], ["H": C(0x1E1E24)])
    c.rect(21, 28, 3, 3, ink); c.rect(32, 28, 3, 3, ink)
    c.rect(16, 32, 24, 6, red)                                       // the suit
    c.rect(16, 32, 24, 1, yellow)
    c.rect(16, 36, 24, 1, yellow)
    c.rect(26, 36, 4, 1, C(0xFFE07A))
    if let s = p.signature, s > 0.7, s < 0.95 { drawGlint(c, p: (s - 0.7) / 0.25, maxX: 40) }
    let fistCol = steelTo > 34 ? steel : skin
    if let a = p.melee {
        drawFist(c, angle: a, trail: p.trail, from: (40, 33.5), reach: 6, arm: steel, fist: steelShade, size: 4)
    } else {
        c.rect(40, 32, 4, 4, fistCol)
        if fistCol.r == steel.r { c.rect(40, 33, 4, 1, seam) }
    }
}
