import Foundation

// Heroes: the street, Defenders, Punisher, Blade and friends. Clawd in costume, classic comic colours: masks, hair,
// leather and armour over the blocky body; where a face shows, it's Clawd's own orange.

let heroes8: [MarvelHero: Persona] = [
    .spiderWoman: Persona(name: "Spider-Lady", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xF0FFE0), glow: C(0x9AE04A)),
                  muzzle: (43, 34), handGun: false, headTop: 20, signature: 2.8,
                  draw: drawSpiderWoman),
    .blackCat: Persona(name: "Black Kat", weapon: .saber, headTop: 19, signature: 2.8,
                  draw: drawBlackCat),
    .lukeCage: Persona(name: "Luke Kage", weapon: .saber, armoured: true, headTop: 23, signature: 2.6, callout: "Sweet holidays!",
                  draw: drawLukeCage),
    .ironFist: Persona(name: "Iron Fyst", weapon: .saber, headTop: 23, signature: 2.8,
                  draw: drawIronFist),
    .jessicaJones: Persona(name: "Jessie Jonez", weapon: .saber, headTop: 20, signature: 3.0,
                  draw: drawJessicaJones),
    .punisher: Persona(name: "The Punnisher", weapon: .blaster, shot: .bullet, muzzle: (56, 32), headTop: 23, signature: 2.8,
                  draw: drawPunisher),
    .elektra: Persona(name: "Elecktra", weapon: .saber, headTop: 20, signature: 2.6,
                  draw: drawElektra),
    .blade: Persona(name: "Blayde", weapon: .saber, headTop: 22, signature: 3.0,
                  draw: drawBlade),
    .blackKnight: Persona(name: "Black Nite", weapon: .saber, armoured: true, headTop: 16, signature: 3.0,
                  draw: drawBlackKnight),
]

// MARK: - Spider-Woman

/// Spider-Woman: Clawd in the red suit and mask with big white lenses, the yellow spider-hourglass across her front,
/// yellow gloves and boots, long black hair down her back. Venom blasts crackle green from her palm; in flight she
/// leans in, fist forward, the glider webbing showing under her arm and her hair streaming. Signature: both hands come
/// up and venom crackles round them.
private func drawSpiderWoman(_ c: PixelCanvas, _ p: Pose) {
    let crackle: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        let red = C(0xC8202A), redDark = C(0x8A1418), yellow = C(0xF2C230)
        let hair = C(0x1A1A22), hairShade = C(0x3A3A4A)
        let core = C(0xF0FFE0), glow = C(0x9AE04A)
        if p.flying {
            for lx in [21, 31] { c.rect(lx, 36, 4, 6, red); c.rect(lx, 40, 4, 2, yellow); c.rect(lx + 3, 36, 1, 4, redDark) }
        } else {
            drawLegs(c, Look(leg: red), step: p.step)
            boots(c, yellow, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        let up = crackle > 0.05 ? 3 : 0
        drawBody(c, Look(body: red, shade: redDark, arm: yellow, eye: nil), armLeft: up, armRight: p.flying ? 0 : up)
        c.pattern(14, 20, [
            "........HHHHHHHHH........",
            ".....HHHHHHHHHHHHHHH.....",
            "...HHHHHHHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHhHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHHHHHhHHHH.",
            "HHHHhhhh..........hhHHHH.",
            "HHHHh...............hHHH.",
            "HHHH.................HHH.",
            "HHHH.................hHH.",
            "HHHh.................hHH.",
            "HHH..................Hh..",
            "HHH......................",
            "HHh......................",
            ".HH......................",
            ".Hh......................",
            "..h......................",
        ], ["H": hair, "h": hairShade])
        if p.flying {
            // Hair streaming out behind.
            for (i, y) in [21, 23, 25, 27, 29].enumerated() {
                let len = 5 - abs(i - 2) + Int(sin(p.t * 9 + Double(i)) * 1.2)
                c.rect(14 - len, y, len, 2, i % 2 == 0 ? hair : hairShade)
            }
        }
        // The mask's big white lenses.
        c.pattern(21, 28, ["KKKKK....KKKKK", "KWWWK....KWWWK", ".KWWK....KWWK.", "..KK......KK.."],
                  ["K": ink, "W": C(0xF4F4F8)])
        // The yellow spider-hourglass.
        c.pattern(22, 32, ["YYY......YYY", ".YYY....YYY.", "..YYYYYYYY..", "..YYYrrYYY..", ".YYY....YYY.", "YYY......YYY"],
                  ["Y": yellow, "r": redDark])
        if p.flying {
            // Left arm swept back over the glider webbing, right fist forward and glowing.
            c.pattern(11, 31, ["YYYYYYY", "rRRRRRR", ".rRRRRR", "..rRRRR", "...rRRR"], ["Y": yellow, "R": red, "r": redDark])
            c.rect(38, 31, 4, 3, yellow)
            c.glowLine(42.5, 32.5, 42.5, 32.5, core: core, glow: glow, coreR: 0.6, glowR: 2)
            return
        }
        c.rect(15, 33 - up, 3, 3, yellow)
        if crackle > 0.05 {
            for (i, hx) in [16.5, 39.5].enumerated() {
                let hy: Double = 31.5
                c.glowLine(hx, hy, hx, hy, core: core.alpha(crackle), glow: glow.alpha(crackle), coreR: 0.7, glowR: 2.6)
                let seed = Int(p.t * 22) + i * 17
                for b in 0..<2 {
                    var prev = (x: hx, y: hy)
                    let a: Double = noise(seed * 3 + b * 5) * 2 * .pi
                    for k in 1...3 {
                        let r = Double(k) * 1.8
                        let q = (x: hx + cos(a) * r + (noise(seed + b * 3 + k) - 0.5) * 2,
                                 y: hy + sin(a) * r + (noise(seed + b * 7 + k) - 0.5) * 2)
                        c.glowLine(prev.x, prev.y, q.x, q.y, core: core, glow: glow.alpha(0.6), coreR: 0.4, glowR: 1.1)
                        prev = q
                    }
                }
            }
            return
        }
        c.oy += p.gunY
        c.rect(38, 33, 4, 3, yellow); c.px(41, 33, C(0xC89A1A))
        if p.fire != nil || p.ready {
            c.glowLine(42.5, 34.5, 42.5, 34.5, core: core, glow: glow, coreR: 0.6, glowR: 1.8)
        }
    }
}

// MARK: - Black Cat

/// Black Cat: a big mane of platinum hair, a black domino mask with green cat's eyes, the black catsuit with white
/// fur at the collar, wrists and boot tops. She fights with a whip that curls behind each swing, coiled at her hip in
/// between. Signature: she holds up a stolen diamond, it sparkles, and she winks.
private func drawBlackCat(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1C1C24), suitLight = C(0x3A3A48), fur = C(0xE8E8F0), furShade = C(0xB4B4C4)
    let hair = C(0xE2E4EE), hairShade = C(0x9098B4), mask = C(0x101014), whip = C(0x6A6478)
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, lifted ? 38 : 39, 2, 1, fur)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: suit, eye: nil))
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, C(0x111116))
    c.rect(27, 34, 2, 3, suitLight)
    c.pattern(20, 32, ["FFFFFFFFFFFFFFFF", "fFFfFFf.fFFfFFfF"], ["F": fur, "f": furShade])
    c.pattern(13, 21, [
        ".......HHHHHHHHHHHH........",
        ".....HHHHHHhHHHHHHHHH......",
        "...HHHHHhHHHhHHHHHHHHHH....",
        "..HHHHHhHHHhHHHHhHHHHHHH...",
        ".HHHHhHHHhHHHHhHHHHhHHHHH..",
        ".HHHHhHh..............hHhH.",
        "HHHHhHh................HhH.",
        "HHHhHh.................HhHH",
        "HHhHH..................HHhH",
        "HhHHh..................HHhH",
        "HhHH...................hHHh",
        "hHHh...................hHHh",
        "HHh.....................Hh.",
        ".Hh.....................h..",
        "..h........................",
    ], ["H": hair, "h": hairShade])
    // Domino mask with cat's eyes; red lips.
    let sig = p.signature
    let wink = sig.map { $0 > 0.45 && $0 < 0.7 } ?? false
    c.pattern(20, 27, ["K..............K", ".KKKKKK..KKKKKK.", "KKEEKKKKKKKKEEKK", ".KEIKK....KEIKK."],
              ["K": mask, "E": C(0xA8F0B8), "I": ink])
    if wink {
        c.rect(32, 29, 2, 2, mask)
        c.px(31, 30, C(0xD8DCE8)); c.px(32, 29, C(0xD8DCE8)); c.px(33, 29, C(0xD8DCE8)); c.px(34, 30, C(0xD8DCE8))
        twinkle(c, 36, 26, C(0xFFF0F8))
    }
    c.rect(27, 31, 2, 1, C(0xC8304A))
    // Fur cuffs.
    c.rect(15, 33, 3, 3, suit); c.rect(17, 33, 1, 3, fur)
    if let a = p.melee {
        var bend: Double = 30
        if let prev = p.trail.first { bend = max(-90, min(90, (prev - a) * 2.5)) }
        for (i, ta) in p.trail.enumerated() { drawWhip(c, angle: ta, bend: bend, col: whip, alpha: 0.35 / Double(i + 1)) }
        drawWhip(c, angle: a, bend: bend, col: whip)
        c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, fur)
    } else if let s = sig, s > 0.08, s < 0.92 {
        // The diamond held up to the light.
        c.rect(38, 29, 3, 3, suit); c.rect(38, 29, 1, 3, fur)
        c.pattern(39, 24, [".CCC.", "CLCCD", ".CCD.", "..D.."], ["C": C(0x6AD8F0), "L": C(0xE0FAFF), "D": C(0x2A8AB0)])
        if s > 0.18 && s < 0.42 { twinkle(c, 40, 24, white, big: Int(s * 30) % 2 == 0) }
    } else {
        ring(c, 36.5, 36, 1.6, whip)                                          // coiled at her hip
        c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, fur)
    }
}

/// Black Cat's whip out from the hand along `angle`, curling `bend` degrees by the tip.
private func drawWhip(_ c: PixelCanvas, angle: Double, bend: Double, col: Px, alpha: Double = 1) {
    var x = hand.x, y = hand.y
    let n = 16
    for k in 0..<n {
        let f = Double(k) / Double(n)
        let a = (angle + bend * f * f) * .pi / 180
        let nx = x + cos(a), ny = y + sin(a)
        c.glowLine(x, y, nx, ny, core: col.alpha(alpha), glow: none, coreR: k < 5 ? 0.8 : 0.6, glowR: 0.9)
        x = nx; y = ny
    }
}

// MARK: - Luke Cage

/// Luke Cage, Hero for Hire: the classic open-collared yellow shirt, the steel tiara round his head, steel bracelets
/// on both wrists, a chain belt and blue trousers. He fights with his fists. Signature: a bullet flies in, bounces off
/// his chest and ricochets away, leaving a smoking hole in his shirt.
private func drawLukeCage(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0xF2C230), shirtShade = C(0xC8961A), steel = C(0xC8CCD4), steelDark = C(0x7A7F8C)
    let pants = C(0x2A4A9A), hair = C(0x16161B)
    drawLegs(c, Look(leg: pants), step: p.step)
    boots(c, C(0x2A2A30), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look())
    c.pattern(18, 23, ["...HHHHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH"], ["H": hair])
    c.pattern(18, 26, ["SSSSSSSSLSSSSSSSSSSd", "h.......SSSS.......h"], ["S": steel, "L": C(0xF0F2F6), "d": steelDark, "h": hair])
    c.rect(22, 28, 3, 1, C(0x8A4A30)); c.rect(31, 28, 3, 1, C(0x8A4A30))         // brows
    c.rect(18, 32, 20, 6, shirt)
    c.rect(37, 32, 1, 6, shirtShade)
    c.pattern(24, 32, [".SSSSSS.", "..SSSS..", "...SS..."], ["S": clawdOrange])
    c.pattern(20, 32, ["ccc..........ccc", "..c..........c.."], ["c": shirtShade])
    for x in 18...37 { c.px(x, 37, x % 2 == 0 ? steel : steelDark) }               // chain belt
    let sig = p.signature
    if let s = sig, s >= 0.36 {
        // The hole the bullet left.
        c.pattern(33, 34, [".k.", "kSk", ".k."], ["k": C(0x5A3A1A), "S": clawdOrange])
        if s < 0.9 {
            for i in 0..<3 {
                let f = frac((s - 0.36) * 3 + Double(i) / 3)
                c.px(34 + Int(sin(f * 7) * 1.2), 33 - Int(f * 6), C(0xD8D8D8).alpha(0.7 * (1 - f)))
            }
        }
    }
    c.rect(15, 33, 3, 3, clawdOrange); c.rect(16, 33, 1, 3, steel)
    if let a = p.melee {
        punch(c, angle: a, trail: p.trail, arm: clawdOrange, fist: clawdOrange, cuff: steel, smearCol: shirt)
    } else {
        c.rect(38, 33, 3, 3, clawdOrange); c.rect(39, 33, 1, 3, steel)
    }
    if let s = sig {
        let hit = (x: 37.5, y: 34.5)
        if s < 0.34 {
            let x = 70 - s / 0.34 * (70 - hit.x)
            drawProjectile(c, .bullet, from: (x + 4, hit.y), head: (x, hit.y), t: p.t)
        } else if s < 0.5 {
            drawSparks(c, x: hit.x, y: hit.y, t: p.t, size: 3)
        }
        if s > 0.38 && s < 0.72 {
            let f = (s - 0.38) / 0.34
            let hx = hit.x + 2 + f * 26, hy = hit.y - 1 - f * 30
            drawProjectile(c, .bullet, from: (hx - 2.6, hy + 3), head: (hx, hy), t: p.t)
        }
    }
}

// MARK: - Iron Fist

/// Iron Fist: the yellow mask with black-rimmed eyes and trailing ties, the green suit with the huge flared yellow
/// collar, the black dragon on his chest and a yellow sash; yellow slippers. He fights bare-fisted, the chi fist
/// glowing gold. Signature: he raises his fist, chi gathers into it and it blazes gold.
private func drawIronFist(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2A9A3A), greenDark = C(0x1A6A28), yellow = C(0xF2C230), yellowDark = C(0xC89A1A)
    let chiCore = C(0xFFF6C8), chiGlow = C(0xFFB82A)
    // Mask ties fluttering behind.
    c.oy += p.breathe
    for k in 0..<5 {
        let y = 26 + k / 2 + Int((sin(p.t * 5 + Double(k) * 0.9) * 0.9).rounded())
        c.px(17 - k, y, yellow); c.px(17 - k, y + 2, yellowDark)
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: green), step: p.step)
    boots(c, yellow, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    c.pattern(18, 24, [
        "....YYYYYYYYYYYY....",
        "..YYYYYYYYYYYYYYYY..",
        "YYYYYYYYYYYYYYYYYYYy",
        "YYYYYYYYYYYYYYYYYYYy",
        "YYKKKKKYYYYYYKKKKKYy",
        "YYYKWWKYYYYYYKWWKYYy",
        "yYYYKKKYYYYYYKKKYYYy",
        ".yyyyyyyyyyyyyyyyyy.",
    ], ["Y": yellow, "y": yellowDark, "K": ink, "W": white])
    c.pattern(16, 31, [
        "YY....................YY",
        "YYY..................YYY",
        ".YYYY..............YYYY.",
        "..YYYYY..........YYYYY..",
        "....YYYYY......YYYYY....",
    ], ["Y": yellow])
    c.pattern(25, 32, [".KK...", "K..KK.", ".KK..K", "...KK."], ["K": C(0x10301A)])   // the dragon
    c.rect(18, 36, 20, 2, yellow); c.rect(18, 37, 20, 1, yellowDark)
    c.rect(20, 38, 2, 2, yellow)                                                       // sash ends
    c.rect(15, 33, 3, 3, green); c.rect(17, 33, 1, 3, yellow)
    let sig = p.signature
    if let a = p.melee {
        punch(c, angle: a, trail: p.trail, arm: green, fist: green, cuff: yellow, smearCol: chiGlow)
        let f = reach(hand, a, 6)
        c.glowLine(f.x, f.y, f.x, f.y, core: chiCore, glow: chiGlow, coreR: 0.8, glowR: 2.2, strength: 0.85)
    } else if let s = sig, s > 0.06, s < 0.94 {
        // Forearm up, fist raised beside his head.
        c.glowLine(39.5, 33.5, 41.5, 27.5, core: green, glow: none, coreR: 1.2, glowR: 1.3)
        c.rect(40, 28, 3, 1, yellow)
        c.rect(40, 23, 4, 4, green); c.rect(43, 23, 1, 4, greenDark); c.px(42, 24, greenDark); c.px(42, 26, greenDark)
        let fx = 42.0, fy = 25.0
        if s < 0.5 {
            // Chi drawn in from all round.
            let f = (s - 0.06) / 0.44
            for i in 0..<6 {
                let a = Double(i) * .pi / 3 + f * 3
                let r = 10 * (1 - f) + 1
                c.px(Int(fx + cos(a) * r), Int(fy + sin(a) * r), (i % 2 == 0 ? chiCore : chiGlow).alpha(0.4 + 0.6 * f))
            }
            c.glowLine(fx, fy, fx, fy, core: chiCore.alpha(f), glow: chiGlow.alpha(f), coreR: 0.6, glowR: 1 + f * 1.5)
        } else {
            let k = habitArc((s - 0.5) / 0.44, hold: 0.6)
            let flick: Double = 0.85 + 0.15 * sin(p.t * 40)
            c.glowLine(fx, fy, fx, fy, core: chiCore, glow: chiGlow, coreR: 1.4 + 0.8 * k, glowR: (2.6 + 2.8 * k) * flick)
            ring(c, fx, fy, 4 + 3 * frac(p.t * 2), chiGlow.alpha(0.6 * k))
            for i in 0..<4 {
                let f = frac(p.t * 2.5 + Double(i) / 4)
                c.px(Int(fx) - 2 + i + Int(sin(f * 6) * 1), Int(fy - 3 - f * 6), chiCore.alpha(k * (1 - f)))
            }
        }
    } else {
        c.rect(38, 33, 3, 3, green); c.rect(38, 33, 1, 3, yellow)
    }
}

// MARK: - Jessica Jones

/// Jessica Jones: messy dark shoulder-length hair swept over one eye, a scarf, the black leather jacket over a grey
/// tee, jeans and boots. Super-strong, she just punches. Signature: she takes a swig from a hip flask, eyes shut, and
/// lets out a weary breath.
private func drawJessicaJones(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x2A1E1A), hairShade = C(0x4A3A30), jacket = C(0x26262C), jacketLight = C(0x484852)
    let tee = C(0x8A8A96), scarf = C(0x7A4A6A), scarfDark = C(0x5A3048), jeans = C(0x3A5A8A)
    drawLegs(c, Look(leg: jeans), step: p.step)
    boots(c, C(0x1E1A18), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket, eye: nil))
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, tee)
    c.rect(24, 34, 1, 4, jacketLight); c.rect(31, 34, 1, 4, jacketLight)
    c.rect(37, 33, 1, 5, C(0x16161B))
    c.pattern(19, 31, ["..SSSSSSSSSSSSSS..", ".SSsSSSSSsSSSSsSS.", "...SS............."], ["S": scarf, "s": scarfDark])
    c.rect(22, 34, 2, 2, scarf); c.px(22, 36, scarfDark); c.px(23, 36, scarf)
    c.pattern(15, 20, [
        "......HHHHHHHHHH........",
        "....HHHHHHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHHH....",
        "..HHHHHHHHhHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHhHHHHHH..",
        ".HHHHHHHHHh.........HHH.",
        ".HHHHHh..............HH.",
        "HHHHH................HH.",
        "HHHH.................HH.",
        "HHHH.................Hh.",
        "HHHh.................HH.",
        "HHH..................hH.",
        ".HH.....................",
        ".Hh.....................",
    ], ["H": hair, "h": hairShade])
    let sig = p.signature
    let drinking = sig.map { $0 > 0.22 && $0 < 0.72 } ?? false
    if drinking {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)                          // eyes shut
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.rect(32, 29, 2, 1, C(0xB85F40))                                               // the usual unimpressed look
    }
    c.rect(15, 33, 3, 3, jacket)
    if let a = p.melee {
        punch(c, angle: a, trail: p.trail, arm: jacket, fist: clawdOrange, cuff: nil, smearCol: C(0xC8C8D8))
    } else if let s = sig, s > 0.1, s < 0.86 {
        // Hand up to her mouth with the flask.
        let tilt = s > 0.22 && s < 0.72
        c.pattern(31, tilt ? 26 : 28, tilt ? ["...SS", "..SSS", ".SSSs", ".SSs.", "Ss..."] : ["SSs", "SSs", "SSs", ".S."],
                  ["S": C(0xC8CCD4), "s": C(0x8A8F9C)])
        c.rect(34, 29, 3, 3, jacket); c.px(36, 29, clawdOrange)
        c.rect(37, 31, 2, 2, jacket)
    } else {
        c.rect(38, 33, 3, 3, jacket); c.rect(40, 33, 1, 3, clawdOrange)
        if let s = sig, s >= 0.86 {
            let f = (s - 0.86) / 0.14
            c.rect(30 + Int(f * 4), 31 - Int(f * 2), 2, 1, C(0xE0E0E8).alpha(0.7 * (1 - f)))   // a weary sigh
        }
    }
}

// MARK: - The Punisher

/// The Punisher: a black-shirted Clawd with a buzz cut and a permanent scowl, the big white skull across his chest,
/// classic white gloves and boots, and an assault rifle. Signature: he reloads, the empty magazine drops, a fresh one
/// slaps in, he racks the bolt and brings the rifle back up.
private func drawPunisher(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0x1A1A20), bone = C(0xECECEE), glove = C(0xE0E0E8), hair = C(0x16161B)
    drawLegs(c, Look(leg: shirt), step: p.step)
    boots(c, glove, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: shirt, eye: nil))
    c.pattern(18, 23, ["..HHHHHHHHHHHHHHHH..", "HHHHHHHHHHHHHHHHHHHH", "HhHhHhHHHHHHHHHHhHhH", "h..................h"],
              ["H": hair, "h": C(0x3A2E28)])
    c.pattern(21, 27, ["KK..........KK", ".KKK......KKK.", "..KK......KK..", "..KK......KK.."], ["K": ink])  // scowl
    c.rect(24, 31, 8, 1, C(0xB85F40))
    c.rect(18, 32, 20, 6, shirt)
    c.pattern(23, 32, ["..WWWWWW..", ".WWWWWWWW.", "WKKKWWKKKW", "WKKKWWKKKW", ".WWWKKWWW.", "..WKWKWW.."], ["W": bone, "K": shirt])
    c.rect(15, 33, 3, 3, glove)
    let sig = p.signature
    var lift = p.gunY
    if let s = sig, s > 0.82 { lift -= 1 }
    c.oy += lift
    let gun = C(0x2A2A30), metal = C(0x5A5E6A)
    c.pattern(35, 30, [
        "........kk...........",
        "kGGGGGGGGGGGGGGGG....",
        "kGGGGGGGGGGGGGGGGGGGG",
        "kk..GGGGGGkkkkk......",
        "......GG.............",
        "......GG.............",
    ], ["G": gun, "k": C(0x15151A)])
    c.rect(43, 31, 7, 1, metal)
    // The magazine, and the reload.
    var magY = 34
    var magAlpha: Double = 1
    var handY: Int? = nil
    if let s = sig {
        if s > 0.12 && s < 0.32 {
            let f = (s - 0.12) / 0.2
            magY = 34 + Int((f * f * 9).rounded()); magAlpha = 1 - max(0, f - 0.6) / 0.4
        } else if s >= 0.32 && s < 0.58 {
            let f = min(1, (s - 0.32) / 0.22)
            magY = 34 + Int(((1 - f) * 7).rounded()); handY = magY + 2
        } else if s >= 0.58 && s < 0.8 {
            let k = habitArc((s - 0.58) / 0.22, hold: 0.2)
            c.rect(43 - Int((k * 2).rounded()), 30, 2, 1, metal)                    // the bolt racked back
            if k > 0.9 { twinkle(c, 41, 29, C(0xFFE27A)) }
        }
    }
    c.rect(46, magY, 3, 3, gun.alpha(magAlpha)); c.px(47, magY + 3, gun.alpha(magAlpha))
    if let hy = handY { c.rect(45, hy, 4, 3, glove) }
    c.rect(40, 33, 3, 3, glove)
}

// MARK: - Elektra

/// Elektra: long black hair under the long red headband whose tails stream out behind, the red wrapped costume with
/// a sash, wraps round the arms and legs, and a sai in each hand, the left held reversed along her forearm, the right
/// for fighting. Signature: she spins the sai round her fingers and snaps it to guard.
private func drawElektra(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC0182A), redDark = C(0x84101A), hair = C(0x1A1418), hairShade = C(0x3A2E34)
    drawLegs(c, Look(leg: red), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            for y in stride(from: 37, through: lifted ? 41 : 42, by: 2) { c.rect(lx, y, 2, 1, redDark) }
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: red, eye: ink))
    c.pattern(14, 20, [
        "........HHHHHHHHH........",
        ".....HHHHHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHh..............hHHH.",
        "HHHHH...............HHH..",
        "HHHHH................HH..",
        "HHHH.................Hh..",
        "HHHh.................HH..",
        "HHH......................",
        "HHH......................",
        ".HH......................",
        ".HH......................",
        "..H......................",
    ], ["H": hair, "h": hairShade])
    // The headband and its tails.
    c.rect(17, 25, 21, 2, red); c.rect(17, 26, 21, 1, redDark)
    for k in 0..<8 {
        let wave = sin(p.t * 6 - Double(k) * 0.8) * Double(k) * 0.18
        let y = 25 + k / 2 + Int(wave.rounded())
        c.rect(16 - k, y, 1, 2, red); c.px(16 - k, y + 2, redDark)
    }
    c.rect(18, 32, 20, 6, red)
    c.pattern(25, 32, ["KKKKKK", ".KKKK."], ["K": clawdOrange])
    c.pattern(19, 33, ["d.........", ".d........", "..d.......", "...d......", "....d....."], ["d": redDark])
    c.rect(18, 36, 20, 1, redDark)
    c.rect(20, 37, 2, 3, red); c.px(21, 39, redDark)                                       // sash end
    // Left sai, held reversed and low.
    c.rect(15, 33, 3, 3, red); c.rect(16, 33, 1, 3, redDark)
    drawSai(c, at: (16, 34.5), angle: 130)
    c.rect(15, 33, 3, 3, red); c.rect(16, 33, 1, 3, redDark)
    if let a = p.melee {
        smear(c, hand, p.trail, from: 1, to: 10, C(0xE0E4EC))
        drawSai(c, at: hand, angle: a)
    } else if let s = p.signature, s > 0.06, s < 0.94 {
        c.rect(38, 31, 3, 3, red)
        let at = (x: 41.5, y: 32.5)
        if s < 0.74 {
            let f = (s - 0.06) / 0.68
            let a = 90 - 1080 * (0.5 - 0.5 * cos(f * .pi))
            for i in 1...2 { drawSai(c, at: at, angle: a + Double(i) * 30, alpha: 0.3 / Double(i)) }
            drawSai(c, at: at, angle: a)
        } else {
            drawSai(c, at: at, angle: -60)
            if s < 0.84 { twinkle(c, Int(at.x + 5), Int(at.y - 9), white) }
        }
        return
    } else {
        drawSai(c, at: hand, angle: 100)
    }
    c.rect(38, 33, 3, 3, red); c.rect(39, 33, 1, 3, redDark)
}

/// A sai held at `at`: a red-wrapped grip behind, a steel spike out along `angle`, two prongs at the guard.
private func drawSai(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    let steel = C(0xC8CCD4).alpha(alpha), wrap = C(0x84101A).alpha(alpha)
    bar(c, h, angle, from: -3, to: 0.5, wrap, r: 0.7)
    bar(c, h, angle, from: 0.5, to: 10, steel, r: 0.55)
    let g = reach(h, angle, 1)
    for side in [-1.0, 1.0] {
        let q = reach(g, angle + 90 * side, 1.8), tip = reach(q, angle, 2.2)
        c.glowLine(g.x, g.y, q.x, q.y, core: steel, glow: none, coreR: 0.5, glowR: 0.6)
        c.glowLine(q.x, q.y, tip.x, tip.y, core: steel, glow: none, coreR: 0.5, glowR: 0.6)
    }
}

// MARK: - Blade

/// Blade: the flat-top with shaved lines, wraparound black shades, a goatee, black body armour and the long leather
/// coat flaring round his legs; his sword sits on his back, hilt over the shoulder, until he draws it. Signature: he
/// draws the sword and twirls it twice, points it at the ground, and a glint runs across his shades.
private func drawBlade(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x24242A), coatLight = C(0x3E3E48), coatDark = C(0x141418), hair = C(0x16161B)
    let steel = C(0xC8CCD4), grip = C(0x2A2A30)
    let sig = p.signature
    let swordOut = p.melee != nil || (sig.map { $0 > 0.05 && $0 < 0.96 } ?? false)
    c.oy += p.breathe
    if !swordOut {
        // On his back: only the hilt shows over his shoulder.
        c.glowLine(12, 18, 16, 23, core: grip, glow: none, coreR: 0.8, glowR: 0.9)
        c.glowLine(14, 25, 18, 22, core: steel, glow: none, coreR: 0.6, glowR: 0.7)
        c.glowLine(16, 24, 26, 36, core: steel, glow: none, coreR: 0.7, glowR: 0.8)
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: coatDark), step: p.step)
    boots(c, C(0x0E0E12), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: coat, eye: nil))
    c.pattern(18, 23, [".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH", "HhHHhHHHHHHHHHHHhHHh", "h..h..............h."],
              ["H": hair, "h": C(0x3A2E28)])
    // Wraparound shades.
    c.pattern(18, 28, ["KKKKKKKKKKKKKKKKKKKK", "..KLKKKK..KKKLKKK...", "...KKKK....KKKK....."],
              ["K": C(0x0C0C10), "L": C(0x5A6A7A)])
    c.rect(25, 31, 6, 1, hair); c.rect(26, 32, 4, 1, hair)                                // goatee
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 6, 5, C(0x2E2E36))
    c.rect(24, 33, 1, 5, coatLight); c.rect(31, 33, 1, 5, coatLight)
    c.rect(18, 37, 20, 1, coatDark); c.px(28, 37, steel)
    // The coat flaring round his legs.
    let bottom = seatedPose ? 39 : 41
    if 38 <= bottom {
        for y in 38...bottom {
            let out = (y - 37) / 2 + (p.step == 0 ? 1 : 0)
            c.rect(18 - out, y, 4 + out, 1, coat); c.px(18 - out, y, coatDark)
            c.rect(34, y, 4 + out, 1, coat); c.px(37 + out, y, coatDark)
        }
    }
    c.rect(15, 33, 3, 3, coat)
    if let a = p.melee {
        smear(c, hand, p.trail, from: 3, to: 17, steel)
        drawSword(c, at: hand, angle: a)
    } else if let s = sig, s > 0.05, s < 0.96 {
        if s < 0.55 {
            let f = (s - 0.05) / 0.5
            let spin = { (u: Double) -> Double in -70 - 720 * (0.5 - 0.5 * cos(u * .pi)) }
            let now = spin(f)
            smear(c, hand, [spin(max(0, f - 0.04)), spin(max(0, f - 0.08))], from: 3, to: 17, steel)
            drawSword(c, at: hand, angle: now)
        } else {
            drawSword(c, at: hand, angle: 30)
            if s > 0.62 && s < 0.86 {
                let f = (s - 0.62) / 0.24
                let gx = 20 + Int(f * 15)
                c.px(gx, 28, white); c.px(gx - 1, 29, C(0xFFFFFF, 0.7)); c.px(gx + 1, 28, C(0xFFFFFF, 0.5))
            }
            if s > 0.8 && s < 0.94 { twinkle(c, 36, 28, white, big: true) }
        }
    }
    c.rect(38, 33, 3, 3, coat)
}

/// Blade's sword: black grip, a short steel guard and a long straight blade out along `angle`.
private func drawSword(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double) {
    bar(c, h, angle, from: -3, to: 0.5, C(0x2A2A30), r: 0.8)
    let g = reach(h, angle, 1)
    let a = reach(g, angle - 90, 2), b = reach(g, angle + 90, 2)
    c.glowLine(a.x, a.y, b.x, b.y, core: C(0x8A8F9C), glow: none, coreR: 0.6, glowR: 0.7)
    bar(c, h, angle, from: 1.5, to: 17, C(0xC8CCD4), r: 0.7)
    bar(c, h, angle, from: 16, to: 17.5, C(0xEEF0F4), r: 0.5)
}

// MARK: - Black Knight

/// Black Knight: Clawd in dark steel plate under a great helm with a T-shaped visor slit (a red glint inside) and a
/// crimson plume, pauldrons, a crimson cape and a gold belt. He wields the Ebony Blade, a black sword with a violet
/// sheen, planted point-down at his side when he's at rest. Signature: he raises the blade high and a dark glint runs
/// up it, ending in a violet flare.
private func drawBlackKnight(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x5A6070), dark = C(0x363A48), light = C(0x9AA2B4)
    let plume = C(0xC0202A), plumeDark = C(0x7A1018), gold = C(0xD8B040)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: plume, edge: plumeDark)
    drawLegs(c, Look(leg: armour), step: p.step)
    boots(c, dark, step: p.step, rows: 2)
    c.oy += p.breathe
    let sig = p.signature.flatMap { $0 > 0.06 && $0 < 0.95 ? $0 : nil }
    let restHand = p.melee == nil && sig == nil
    drawBody(c, Look(body: armour, shade: dark, arm: armour, eye: nil), armRight: restHand || sig != nil ? 4 : 0)
    c.pattern(18, 21, [
        ".....AAAAAAAAAA.....",
        "...AAAAAAAAAAAAAA...",
        "..AAAAAAAAAAAAAAAA..",
        ".AALAAAAAAAAAAAAAAd.",
        ".ALAAAAAAAAAAAAAAAd.",
    ], ["A": armour, "L": light, "d": dark])
    c.pattern(16, 16, [
        ".......PPPPPP...",
        ".....PPPPPPPPp..",
        "...PPPPPPPPPpp..",
        ".PPPPPPPpppp....",
        "PPPpp...........",
    ], ["P": plume, "p": plumeDark])
    c.rect(19, 26, 1, 8, light)                                                            // helm edge catching the light
    c.rect(20, 29, 16, 2, ink); c.rect(27, 31, 2, 3, ink)                                  // the T-slit
    c.px(23, 29, C(0x8A1A1A)); c.px(32, 29, C(0x8A1A1A))
    for (x, y) in [(31, 32), (33, 32), (32, 33), (34, 33)] { c.px(x, y, dark) }           // breathing holes
    c.rect(18, 34, 20, 1, dark)
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, C(0xF0D070))
    c.rect(27, 35, 2, 1, light)
    c.pattern(14, 30, [".LLLL", "LLAAA", "LAAAd", "ddddd"], ["L": light, "A": armour, "d": dark])   // pauldron
    c.rect(15, 34, 3, 2, armour)
    if let a = p.melee {
        smear(c, hand, p.trail, from: 2, to: 17, C(0x8A5ACC))
        drawEbonyBlade(c, at: hand, angle: a)
    } else if let s = sig {
        let at = (x: 41.5, y: 30.5)
        let g: Double? = s > 0.3 && s < 0.72 ? (s - 0.3) / 0.42 : nil
        drawEbonyBlade(c, at: at, angle: -90, glint: g)
        if s >= 0.72 {
            let k = habitArc((s - 0.72) / 0.23, hold: 0.3)
            c.glowLine(at.x, at.y - 2, at.x, at.y - 17, core: C(0x2A1A3A, 0), glow: C(0x8A5ACC).alpha(0.7 * k), coreR: 0.1,
                       glowR: 2.6)
            twinkle(c, Int(at.x), Int(at.y - 17), C(0xD8C0FF).alpha(k), big: true)
        }
        c.rect(38, 29, 3, 3, armour)
    } else {
        drawEbonyBlade(c, at: (41.5, 29.5), angle: 90, length: seatedPose ? 9 : 13)
        c.rect(38, 29, 3, 3, armour)
    }
}

/// The Ebony Blade from the hand at `h` along `angle`: brown grip, gold crossguard, a black blade with a violet edge;
/// `glint` 0…1 runs a light up it.
private func drawEbonyBlade(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, length: Double = 17,
                            glint: Double? = nil) {
    bar(c, h, angle, from: -3, to: 0, C(0x5A3A24), r: 0.7)
    let g = reach(h, angle, 0.8)
    let a = reach(g, angle - 90, 2.6), b = reach(g, angle + 90, 2.6)
    c.glowLine(a.x, a.y, b.x, b.y, core: C(0xD8B040), glow: none, coreR: 0.6, glowR: 0.7)
    bar(c, h, angle, from: 1.5, to: length, C(0x1A1626), r: 1.0)
    bar(c, h, angle, from: 2.5, to: length - 1, C(0x5A3A8A), r: 0.3)
    if let gl = glint {
        let q = reach(h, angle, 2 + (length - 2) * gl)
        c.glowLine(q.x, q.y, q.x, q.y, core: C(0xE8D8FF), glow: C(0x8A5ACC), coreR: 0.6, glowR: 1.8)
    }
}

// MARK: - Shared helpers

private let hand = Sprite.hand
private let none = C(0, 0)

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func boots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A point `d` pixels out from `h` at `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h`.
private func bar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
                 r: Double = 0.8) {
    let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
    c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: none, coreR: r, glowR: r + 0.1)
}

/// The fading smear a fast swing leaves behind.
private func smear(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ trail: [Double], from a: Double, to b: Double, _ col: Px) {
    for (i, angle) in trail.enumerated() {
        let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// A one-pixel ring of radius `r`.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, _ col: Px) {
    let n = max(12, Int(r * 8))
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        c.px(Int((cx + cos(a) * r).rounded()), Int((cy + sin(a) * r).rounded()), col)
    }
}

/// A little four-pointed sparkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px, big: Bool = false) {
    c.px(x, y, col)
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
        c.px(x + dx, y + dy, col.alpha(0.6))
        if big { c.px(x + 2 * dx, y + 2 * dy, col.alpha(0.3)) }
    }
}

/// A punch along `angle` from the hand: the arm out to a square fist, a cuff at the wrist, a smear behind fast swings.
private func punch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, cuff: Px?, smearCol: Px) {
    smear(c, hand, trail, from: 2, to: 7, smearCol)
    bar(c, hand, angle, from: -2, to: 4.5, arm, r: 1.2)
    if let cuff { bar(c, hand, angle, from: 3.5, to: 4.5, cuff, r: 1.3) }
    let f = reach(hand, angle, 6)
    c.rect(Int(f.x.rounded()) - 2, Int(f.y.rounded()) - 2, 4, 4, fist)
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`, leaning forward one pixel every
/// `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, lean: Int = 0, _ art: (PixelCanvas) -> Void) {
    guard lean > 0 else { art(c); return }
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = Int((Double(feet - y) / Double(lean)).rounded(.down))
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            let m = 255 / Double(a)
            c.px(x + shift, y, Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
                                  b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a))
        }
    }
}
