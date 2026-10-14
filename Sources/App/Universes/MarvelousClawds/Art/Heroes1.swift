import Foundation

// Heroes: the Avengers. Every one of them is Clawd in costume: the mask, hair, helmet and armour drawn over (and
// around) the blocky body, the way the Star Wars cast was done. Where the hero shows a face, it's Clawd's own orange.

let heroes1: [MarvelHero: Persona] = [
    .ironMan: Persona(name: "Iron Clawd", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xF4FCFF), glow: C(0x6FD8FF)), armoured: true,
                  muzzle: (43, 34), handGun: false, headTop: 20, signature: 3.0, callout: "I am Iron Clawd.",
                  draw: drawIronMan),
    .captainAmerica: Persona(name: "Captain Americlawd", weapon: .saber, headTop: 20, signature: 2.8, callout: "Clawdvengers, gather round!",
                  draw: drawCaptainAmerica),
    .thor: Persona(name: "Thorr", weapon: .saber, motion: .fly, headTop: 14, signature: 3.2, callout: "For Asgaard!",
                  draw: drawThor),
    .hulk: Persona(name: "The Bulk", weapon: .saber, pivot: hulkShoulder, bulk: 5, headTop: 18, signature: 3.0, callout: "BULK SQUASH!",
                  draw: drawHulk),
    .blackWidow: Persona(name: "Black Window", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 20, signature: 2.6,
                  draw: drawBlackWidow),
    .hawkeye: Persona(name: "Hawk-I", weapon: .blaster, shot: .arrow, muzzle: (46, 34), handGun: false, headTop: 18, signature: 3.0,
                  draw: drawHawkeye),
    .spiderMan: Persona(name: "Spider-Clawd", weapon: .blaster, motion: .swing, shot: .web, muzzle: (42, 34), handGun: false,
                  headTop: 26, signature: 2.8,
                  draw: drawSpiderMan),
    .blackPanther: Persona(name: "Black Panthah", weapon: .saber, armoured: true, headTop: 22, signature: 2.6, callout: "Wakandu forever!",
                  draw: drawBlackPanther),
    .doctorStrange: Persona(name: "Doctor Stranger", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFE8B0), glow: C(0xFF8A1E), jagged: false),
                  headTop: 21, signature: 3.2,
                  draw: drawDoctorStrange),
    .scarletWitch: Persona(name: "Scarlet Glitch", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFD0DA), glow: C(0xFF2A4A), jagged: false),
                  headTop: 16, signature: 3.0,
                  draw: drawScarletWitch),
    .vision: Persona(name: "Vizion", weapon: .lightning, motion: .fly, magic: Magic(core: C(0xFFF6C0), glow: C(0xFFC81E), jagged: false),
                  pivot: visionGem, headTop: 24, signature: 3.0,
                  draw: drawVision),
    .captainMarvel: Persona(name: "Captain Marvelous", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFF4D0), glow: C(0xFF9A2A)),
                  muzzle: (43, 34), handGun: false, headTop: 20, signature: 2.8,
                  draw: drawCaptainMarvel),
]

// MARK: - Iron Man

/// Iron Man: Clawd in the red-and-gold armour, a red helmet round a gold faceplate with glowing eye slits, the arc
/// reactor on his chest and gold gauntlets; the right palm is the repulsor. In flight he leans into it, legs together,
/// boots and palms burning. Signature: the faceplate flips up to show Tony (goatee and all), he blinks, and it snaps
/// back down.
private func drawIronMan(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB3202A), dark = C(0x7A1018), gold = C(0xE8B530), goldShade = C(0xB88A1E), glow = C(0xDFFBFF)
    let look = Look(body: red, shade: dark, leg: red, arm: red, eye: nil)
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            // Legs together, boots firing.
            for lx in [21, 31] {
                c.rect(lx, 36, 4, 5, red); c.rect(lx, 39, 4, 2, gold); c.rect(lx + 3, 36, 1, 5, dark)
                drawJet(c, x: lx, y: 41, w: 4, t: p.t, seed: lx)
            }
        } else {
            drawLegs(c, look, step: p.step)
            drawBoots(c, gold, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        drawBody(c, look)
        let open = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
        let skin = open > 0.05
        c.pattern(17, 20, [
            "......RRRRRRRRRR......",
            "....RRRRRRRRRRRRRR....",
            "...RRRRRRRRRRRRRRRR...",
            "..RRRRRGGGGGGGGRRRRr..",
            "..RRRRGGGGGGGGGGRRRr..",
            ".RRRRGGGGGGGGGGGGRRRr.",
            ".RRRGGGGGGGGGGGGGGRRr.",
            ".RRRGGGGGGGGGGGGGGRRr.",
            ".RRGGGGGGGGGGGGGGGGRr.",
            ".RRGWWWWGGGGGGWWWWGRr.",
            ".RRGGWWWGGGGGGWWWGGRr.",
            ".RRgGGGGGGGGGGGGGGgRr.",
            ".RRRgGGGkkkkkkGGGgRRr.",
            ".RRRRgGGGGGGGGGGgRRRr.",
            ".RRRRRggggggggggRRRRr.",
        ], ["R": red, "r": dark, "G": skin ? clawdOrange : gold, "g": skin ? clawdShade : goldShade,
            "W": skin ? clawdOrange : glow, "k": skin ? clawdOrange : C(0x5A3A10)])
        if skin {
            // Tony underneath: eyes (one blink), goatee; the faceplate hinged up over the brow.
            let blink = p.signature.map { $0 > 0.48 && $0 < 0.53 } ?? false
            c.rect(22, blink ? 30 : 29, 2, blink ? 1 : 2, ink); c.rect(32, blink ? 30 : 29, 2, blink ? 1 : 2, ink)
            c.rect(25, 32, 6, 1, C(0x3A2416)); c.rect(26, 33, 4, 2, C(0x3A2416)); c.rect(27, 33, 2, 1, C(0x8A3A2A))
            let h = max(3, Int((12 * (1 - open)).rounded())), top = 23 - Int((5 * open).rounded())
            c.rect(20, top, 16, h, gold); c.rect(20, top + h - 1, 16, 1, goldShade)
            if h > 6 { c.rect(21, top + h - 5, 4, 1, glow); c.rect(31, top + h - 5, 4, 1, glow) }
        }
        // Arc reactor, gold trim, gauntlets.
        c.glowLine(28, 36, 28, 36, core: glow, glow: C(0x6FD8FF), coreR: 1, glowR: 2.2)
        c.rect(19, 37, 6, 1, gold); c.rect(31, 37, 6, 1, gold)
        if p.flying {
            for x in [15, 38] { c.rect(x, 34, 3, 3, red); c.rect(x, 36, 3, 1, gold); drawJet(c, x: x, y: 37, w: 3, t: p.t + 0.3, seed: x) }
            return
        }
        c.rect(15, 33, 1, 3, gold)
        c.oy += p.gunY
        c.rect(38, 33, 4, 3, red); c.rect(41, 33, 1, 3, gold); c.rect(40, 33, 1, 3, goldShade)
        if p.fire != nil || p.ready || p.gunLift > 0 {
            c.glowLine(42.5, 34.5, 42.5, 34.5, core: glow, glow: C(0x6FD8FF), coreR: 0.6, glowR: 1.8)
        }
    }
}

// MARK: - Captain America

/// Captain America: the classic blue cowl with the white "A" and little wings at the temples, red gloves and boots,
/// a white star on the chest over red-and-white stripes. The round shield is the weapon: it bashes and blocks from his
/// hand, and hangs on his left arm when it's put away. Signature: he tosses the shield straight up, it flips over and
/// over, and he catches it.
private func drawCaptainAmerica(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4FA0), dark = C(0x1C3878), wht = C(0xF2F2F4), red = C(0xC8202A)
    let look = Look(body: blue, shade: dark, leg: blue, arm: blue, eye: ink)
    drawLegs(c, look, step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, look)
    // Signature: 0.12…0.86 the shield is in the air.
    let air = p.signature.map { ($0 - 0.12) / 0.74 }.flatMap { $0 > 0 && $0 < 1 ? $0 : nil }
    c.pattern(17, 20, [
        "......BBBBBBBBBB......",
        "....BBBBBBWWBBBBBB....",
        "...BBBBBBWBBWBBBBBB...",
        "..BBBBBBBWWWWBBBBBBB..",
        "W.BBBBBBBWBBWBBBBBBb.W",
        "WWBBBBBBBBBBBBBBBBBbWW",
        ".WWBBBBBBBBBBBBBBBBWW.",
        "..WBBBBBBBBBBBBBBBBW..",
        ".bBBBSSSSBBBBBBSSSSBb.",
        ".bBBBSKKSBBBBBBSKKSBb.",
        ".bBBBSKKSBBBBBBSKKSBb.",
        ".bBBBSKKSBBBBBBSKKSBb.",
        ".bBBSSSSSSSSSSSSSSSBb.",
        ".bBBBSSSSSSkkSSSSSBBb.",
    ], ["B": blue, "b": dark, "W": wht, "S": clawdOrange, "K": ink, "k": clawdShade])
    if air != nil { c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink); c.rect(22, 31, 2, 1, clawdOrange); c.rect(32, 31, 2, 1, clawdOrange) }
    // Star over the stripes.
    c.pattern(25, 34, ["..W..", "WWWWW", ".WWW.", "W...W"], ["W": wht])
    for x in stride(from: 19, to: 37, by: 2) where x < 24 || x > 31 { c.rect(x, 35, 1, 3, red) }
    c.rect(18, 37, 20, 1, dark)
    c.rect(15, 33, 3, 3, red)
    c.rect(38, 33, 3, 3, red)

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            let (x, y) = shieldAt(ta)
            drawShield(c, cx: x, cy: y, alpha: 0.35 / Double(i + 1))
        }
        let (x, y) = shieldAt(a)
        drawShield(c, cx: x, cy: y)
    } else if let u = air {
        let y = 32 - Int((23 * sin(u * .pi)).rounded())
        drawShield(c, cx: 44, cy: y, squash: abs(cos(u * 5 * .pi)))
        c.rect(38, 30, 3, 3, red)                         // hand up, ready to catch
    } else if let s = p.signature, s >= 0.86 {
        c.rect(38, 30, 3, 3, red)
        drawShield(c, cx: 44, cy: 32)                     // caught
    } else {
        drawShield(c, cx: 15, cy: seatedPose ? 33 : 35)   // on his left arm
    }
}

/// The shield's centre held out at `angle` degrees from the hand.
private func shieldAt(_ angle: Double) -> (Int, Int) {
    let r = angle * .pi / 180
    return (Int((Sprite.hand.x + cos(r) * 5).rounded(.down)), Int((Sprite.hand.y + sin(r) * 5).rounded(.down)))
}

/// Cap's round shield: red, white, red rings round a blue centre with a white star. `squash` turns it edge-on.
private func drawShield(_ c: PixelCanvas, cx: Int, cy: Int, squash: Double = 1, alpha: Double = 1) {
    let red = C(0xC8202A).alpha(alpha), wht = C(0xF2F2F4).alpha(alpha), blue = C(0x2A4FA0).alpha(alpha)
    let rings: [(Int, Px)] = [(5, C(0x8A1218).alpha(alpha)), (5, red), (4, wht), (3, red), (2, blue)]
    for (i, (r, col)) in rings.enumerated() {
        let rx = Int((Double(r) * squash).rounded())
        if rx < 1 { c.rect(cx, cy - r, 1, 2 * r + 1, col); continue }
        c.ellipse(cx + (i == 0 ? 1 : 0), cy, rx, r, col)
    }
    guard squash > 0.55 else { return }
    c.px(cx, cy, wht); c.px(cx - 1, cy, wht); c.px(cx + 1, cy, wht); c.px(cx, cy - 1, wht)
    c.px(cx - 1, cy + 1, wht); c.px(cx + 1, cy + 1, wht)
}

// MARK: - Thor

/// Thor: Clawd under the classic winged silver helmet, long blond hair, a red cape, dark armour with the silver discs
/// across the chest and a gold belt. Mjolnir rests head-down on the ground under his hand; it swings from the hand
/// when he fights. Flying, the cape streams out behind and the hammer leads. Signature: he twirls Mjolnir by its
/// strap, then raises it and the lightning comes down.
private func drawThor(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x2E3448), armourDark = C(0x1E2232), silver = C(0xC8CCD4), silverDark = C(0x8A8F9C)
    let hair = C(0xE8C860), hairDark = C(0xB8963A), cape = C(0xB01E24), capeDark = C(0x7A1018)
    let look = Look(leg: C(0x3A3E58), arm: armour)
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: cape, edge: capeDark)
        } else {
            drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark)
        }
        drawLegs(c, look, step: p.step)
        drawBoots(c, C(0x6A6E7A), step: p.step, rows: 3)
        c.oy += p.breathe
        drawBody(c, look)
        c.pattern(15, 14, [
            "W........................W",
            "WW......................WW",
            "WwW....................WwW",
            "WWwW..................WwWW",
            "wWWwW................WwWWw",
            ".wWWWW...SSSSSSSS...WWWWw.",
            "..wWWW.SSSSSSSSSSSS.WWWw..",
            "...wWWSSSSSSSSSSSSSSWWw...",
            "....wWSSSSSSSSSSSSSSWw....",
            "..YYYSSSSSSSSSSSSSSSSYYY..",
            "..YYYssssssssssssssssYYY..",
            ".YYYYy..............yYYYY.",
            ".YYYy................yYYY.",
            ".YYy..................yYY.",
            ".YYy..................yYY.",
            ".YYY..................YYY.",
            ".YyY..................YyY.",
            "..YY..................YY..",
            "..Yy..................yY..",
        ], ["W": C(0xF0F0F4), "w": C(0xB8BCC8), "S": silver, "s": silverDark, "Y": hair, "y": hairDark])
        c.rect(19, 19, 3, 1, white)                                   // helmet shine
        c.rect(18, 33, 20, 4, armour)
        c.rect(18, 37, 20, 1, C(0xD8B040))
        for x in [19, 34] {                                         // the discs, in two columns down the chest
            c.pattern(x, 33, ["WS.", "Ss.", ".WS", ".Ss"].map { x < 28 ? $0 : String($0.reversed()) },
                      ["S": silver, "s": silverDark, "W": white])
        }
        c.rect(37, 33, 1, 4, armourDark)

        if p.flying {
            c.rect(38, 31, 4, 3, armour)
            drawMjolnir(c, at: (42.5, 32.5), angle: -12)
            return
        }
        if let a = p.melee {
            for (i, ta) in p.trail.enumerated() { drawMjolnir(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
            drawMjolnir(c, at: Sprite.hand, angle: a)
        } else if let s = p.signature, s > 0.06, s < 0.96 {
            if s < 0.66 {
                // Twirled by the strap: three turns, faster in the middle.
                let k = (s - 0.06) / 0.6
                let a = 90 - 1080 * (0.5 - 0.5 * cos(k * .pi))
                for i in 1...2 { drawMjolnir(c, at: Sprite.hand, angle: a + Double(i) * 28, alpha: 0.3 / Double(i)) }
                drawMjolnir(c, at: Sprite.hand, angle: a)
            } else {
                // Raised high, and the sky answers.
                c.rect(38, 30, 3, 3, armour)
                drawMjolnir(c, at: (41.5, 31.5), angle: -90)
                let strike = (s - 0.66) / 0.3
                if strike > 0.15 && Int(p.t * 30) % 3 != 0 {
                    var prev = (x: 42.0 + (noise(Int(p.t * 20)) - 0.5) * 6, y: -2.0)
                    for i in 1...4 {
                        let y = -2 + Double(i) * 5.5
                        let next = (x: i == 4 ? 42.0 : 42 + (noise(Int(p.t * 20) + i) - 0.5) * 7, y: y)
                        c.glowLine(prev.x, prev.y, next.x, next.y, core: C(0xF4F8FF), glow: C(0x7FB2FF), coreR: 0.5, glowR: 1.8)
                        prev = next
                    }
                    drawSparks(c, x: 42, y: 19, t: p.t, size: 3)
                }
            }
        } else {
            drawMjolnir(c, at: (41.5, seatedPose ? 28.5 : 32.5), angle: 90)   // standing on its head by his hand
        }
    }
}

/// Mjolnir, its handle in the hand at `at`, head out along `angle` degrees.
private func drawMjolnir(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let wood = C(0x6A4428), wrap = C(0x9A6A3A), head = C(0xA4AAB4), light = C(0xD4D8E0), dark = C(0x6A707C)
        s.rect(17, 20, 9, 1, wood)
        for x in [18, 21, 24] { s.px(x, 20, wrap) }
        s.px(16, 21, C(0x4A3020)); s.px(16, 22, C(0x4A3020)); s.px(15, 22, C(0x4A3020))   // the strap
        s.rect(26, 17, 5, 7, head)
        s.rect(26, 17, 5, 1, light); s.rect(26, 17, 1, 7, light)
        s.rect(30, 18, 1, 6, dark); s.rect(27, 23, 4, 1, dark)
        s.px(28, 20, dark)
    }
}

// MARK: - Hulk

private let hulkShoulder = (x: 40.5, y: 26.5)

/// Hulk: a much bigger, broader Clawd in green, messy black hair, a heavy scowling brow and gritted teeth, torn purple
/// shorts and thick legs; one huge arm hangs at his side and the other swings from the shoulder as a giant fist.
/// Signature: he pounds his chest, left, right, left, then throws both fists up and roars.
private func drawHulk(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5AA03A), shade = C(0x3E7A28), deep = C(0x2C5A1C), hair = C(0x1A1A1E)
    let purple = C(0x6A3A8A), purpleDark = C(0x4A2466)
    // Thick legs (folded when sitting, like everyone's).
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, green); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, green)
        c.rect(lx + 2, 38, 1, lifted ? 5 : 6, shade)
    }
    c.oy += p.breathe
    let sig = p.signature
    let pound = sig.map { $0 > 0.08 && $0 < 0.6 } ?? false
    let roar = sig.map { $0 >= 0.6 && $0 < 0.95 } ?? false
    let beat = sig.map { Int(($0 - 0.08) / 0.13) % 2 } ?? 0     // which fist is on the chest

    // The left arm hangs behind the body's edge (or comes up to the chest, or up in the air).
    if roar {
        c.rect(10, 15, 5, 11, green); c.rect(9, 11, 6, 6, green); c.rect(9, 12, 1, 4, shade)
    } else if pound && beat == 1 {
        c.rect(11, 24, 5, 6, green); c.rect(16, 27, 7, 6, green); c.rect(16, 32, 7, 1, shade)
    } else {
        c.rect(10, 24, 5, 9, green); c.rect(9, 32, 6, 6, green)
        c.rect(9, 34, 6, 1, shade); c.rect(9, 36, 6, 1, shade); c.rect(10, 24, 1, 9, shade)
    }
    // The big body.
    c.rect(15, 22, 26, 16, green)
    c.rect(40, 22, 1, 16, shade)
    c.rect(15, 22, 1, 3, shade); c.rect(39, 22, 1, 2, shade)
    c.pattern(15, 18, [
        "....K..KK.K..KK..K.K......",
        "..KKKKKKKKKKKKKKKKKKKKK...",
        ".KKKKKKKKKKKKKKKKKKKKKKKK.",
        "KKKKKKKKKKKKKKKKKKKKKKKKKK",
        "KKK.KKK.KKKK.KKKK.KKK.KKKK",
        "K.....K....K....K.....K..K",
    ], ["K": hair])
    // Scowl: brow, eyes, teeth.
    c.pattern(19, 25, [
        "dd..............dd",
        "dddd..........dddd",
        "..dddd......dddd..",
        "...KKK......KKK...",
        "...KKK......KKK...",
    ], ["d": deep, "K": ink])
    if roar || (pound && Int((sig ?? 0) * 40) % 2 == 0) {
        c.pattern(22, 30, ["KKKKKKKKKKKK", "KWWKWWKWWKWK", "KKKKKKKKKKKK", "KKKKKKKKKKKK", "KWKWWKWWKWWK", ".KKKKKKKKKK."],
                  ["K": C(0x2A0E10), "W": C(0xF2F0E0)])
    } else {
        c.pattern(23, 31, ["KKKKKKKKKK", "KWKWKWKWWK", "KKKKKKKKKK"], ["K": C(0x1E2A14), "W": C(0xF2F0E0)])
    }
    // Pecs and the torn shorts.
    c.rect(19, 35, 7, 1, shade); c.rect(30, 35, 7, 1, shade)
    c.rect(15, 36, 26, 3, purple)
    c.rect(15, 38, 26, 1, purpleDark)
    if !seatedPose {
        for x in [16, 19, 22, 26, 29, 33, 36, 39] { c.px(x, 39, purple); c.px(x + 1, 39, purpleDark) }
    }
    if roar {
        // Both fists up; the roar shakes the air.
        c.rect(40, 15, 5, 11, green); c.rect(41, 11, 6, 6, green); c.rect(46, 12, 1, 4, shade)
        let k = Int(p.lt * 12) % 3
        for i in 0..<3 where (i + k) % 3 != 0 {
            let r = 5 + i * 3
            for d in -1...1 { c.px(34 + r, 31 + d * (1 + i), C(0xFFFFFF, 0.7)) }
        }
        return
    }
    if pound && beat == 0 {
        drawHulkArm(c, angle: 160)
    } else {
        let angle = p.melee ?? 80
        for (i, ta) in p.trail.enumerated() { drawHulkArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawHulkArm(c, angle: angle)
    }
}

/// Hulk's right arm, swung from the shoulder, ending in a huge fist.
private func drawHulkArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: hulkShoulder, angle: angle, alpha: alpha) { s in
        let green = C(0x5AA03A), shade = C(0x3E7A28)
        s.rect(18, 18, 9, 5, green)
        s.rect(18, 22, 9, 1, shade)
        s.rect(26, 16, 7, 8, green)
        s.rect(32, 17, 1, 6, shade); s.rect(26, 23, 7, 1, shade)
        s.px(29, 17, shade); s.px(29, 19, shade); s.px(29, 21, shade)
    }
}

// MARK: - Black Widow

/// Black Widow: Clawd with the long, side-swept red hair, a black catsuit with a silver belt and the red hourglass
/// buckle, gold widow's-bite bracelets on both wrists and a pistol. Signature: the pistol goes away, she brings both
/// wrists up and the widow's bites crackle blue.
private func drawBlackWidow(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x23232A), suitLight = C(0x3A3A46), hair = C(0xC8402A), hairDark = C(0x8A2418), gold = C(0xE0B040)
    let look = Look(leg: suit, arm: suit)
    drawLegs(c, look, step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, look)
    c.rect(18, 32, 20, 6, suit)
    c.rect(27, 32, 1, 3, suitLight)
    c.rect(18, 35, 20, 1, C(0x8A8F9C))
    c.pattern(26, 34, ["RRR", ".R.", "RRR"], ["R": C(0xE0302A)])
    c.pattern(16, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHhHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHhhhHHHHHHH.",
        ".HHHHHHHHHHHh.....hHHHH.",
        ".HHHHHHHHh.........HHHH.",
        ".HHHHHh............hHHH.",
        ".HHHH...............HHH.",
        ".HHHH...............HHH.",
        "HHHHh...............hHHH",
        "HHHH.................HHH",
        "HHHh.................hHH",
        "HHh...................HH",
        "Hh.....................H",
    ], ["H": hair, "h": hairDark])
    let sig = p.signature.flatMap { $0 > 0.1 && $0 < 0.92 ? $0 : nil }
    let lift = sig != nil ? 4 : 0, out = sig != nil ? 1 : 0
    c.rect(15 - out, 33 - lift, 3, 3, suit); c.rect(17 - out, 33 - lift, 1, 3, gold)
    c.rect(38 + out, 33 - lift, 3, 3, suit); c.rect(38 + out, 33 - lift, 1, 3, gold)
    if sig != nil {
        // Widow's bites: the bracelets glow and blue sparks jump off them.
        for (i, x) in [16.0, 39.0].enumerated() {
            let seed = Int(p.t * 24) + i * 9
            c.glowLine(x, 30.5, x, 30.5, core: C(0xE8F8FF), glow: C(0x4AB8FF), coreR: 0.6, glowR: 2.2)
            var prev = (x, 30.5)
            let a = (noise(seed) - 0.5) * 2.4 - .pi / 2
            for k in 1...3 {
                let r = Double(k) * 1.6
                let q = (x + cos(a) * r + (noise(seed + k) - 0.5) * 2, 30.5 + sin(a) * r)
                c.glowLine(prev.0, prev.1, q.0, q.1, core: C(0xE8F8FF), glow: C(0x4AB8FF, 0.6), coreR: 0.35, glowR: 1)
                prev = q
            }
            for k in 0..<3 {
                let b = noise(seed * 3 + k) * 2 * .pi, r = 2 + noise(seed * 5 + k) * 2.5
                c.px(Int(x + cos(b) * r), Int(30.5 + sin(b) * r), k == 0 ? white : C(0x7AD0FF))
            }
        }
        c.rect(19, 36, 2, 2, C(0x2A2A30))                      // the pistol, holstered
        return
    }
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 31)
}

// MARK: - Hawkeye

/// Hawkeye: the classic purple cowl with the "H" on the brow, a dark eye mask, a quiver of red-fletched arrows over
/// his shoulder and a purple recurve bow in his hand, an arrow nocked when he means business. Signature: he pulls an
/// arrow from the quiver, nocks it, draws and holds his aim.
private func drawHawkeye(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2A8A), purpleDark = C(0x4A1A62), lavender = C(0xB08AD8), mask = C(0x1E1424)
    let look = Look(body: purple, shade: purpleDark, leg: purpleDark, arm: purple)
    let sig = p.signature
    // Quiver behind the left shoulder.
    let pulled = sig.map { $0 > 0.08 && $0 < 0.4 ? ($0 - 0.08) / 0.32 : 0 } ?? 0
    c.oy += p.breathe
    c.pattern(12, 19, [
        "R.R.....",
        "RwRw....",
        ".wRwR...",
        "..QQQQ..",
        "..QQQQ..",
        "...QQQq.",
        "...QQQQ.",
        "....QQQQ",
        "....QQQQ",
        ".....QQq",
        ".....QQQ",
    ], ["R": C(0xC83A2A), "w": C(0xE8E0D0), "Q": C(0x7A4A2A), "q": C(0x5A3420)])
    if pulled > 0 {
        let y = 19 - Int((pulled * 6).rounded())
        c.rect(14, y, 1, 6, C(0x8A6A3A)); c.px(14, y - 1, C(0xC8CCD4)); c.px(13, y + 5, C(0xC83A2A)); c.px(15, y + 5, C(0xC83A2A))
    }
    c.oy -= p.breathe
    drawLegs(c, look, step: p.step)
    drawBoots(c, purple, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(17, 20, [
        ".......PPPPPPPP.......",
        ".....PPPPPPPPPPPP.....",
        "....PPPPPPPPPPPPPP....",
        "...PPPPPPLPPLPPPPPP...",
        "..PPPPPPPLLLLPPPPPPP..",
        "..PPPPPPPLPPLPPPPPPd..",
        ".PPPPPPPPPPPPPPPPPPd..",
        ".PPPPPPPPPPPPPPPPPPPd.",
        ".PPMMMMMMMMMMMMMMMMPd.",
        ".PPMMWWMMMMMMMMWWMMPd.",
        ".PPMMWKMMMMMMMMWKMMPd.",
        ".PPPSSSSSSSSSSSSSSPPd.",
        ".PPPSSSSSSSSSSSSSSPPd.",
        ".PPPPSSSSSSkkSSSSPPPd.",
    ], ["P": purple, "d": purpleDark, "L": lavender, "M": mask, "W": white, "K": ink, "S": clawdOrange, "k": clawdShade])
    // Tunic: the quiver strap across the chest, a dark belt.
    for i in 0..<5 { c.rect(21 + i * 3, 37 - i, 3, 1, C(0x7A4A2A)) }
    c.rect(18, 37, 20, 1, purpleDark)

    // The bow, and an arrow on the string when he's shooting or aiming.
    let drawing = sig.map { $0 > 0.4 && $0 < 0.95 } ?? false
    var pull = 0
    if drawing { pull = Int((4 * habitArc(((sig ?? 0) - 0.4) / 0.55, hold: 0.6)).rounded()) }
    let firing = p.fire.map { frac($0.t / blasterPeriod) < 0.45 } ?? false
    if let f = p.fire, frac(f.t / blasterPeriod) > 0.6 { pull = Int(((frac(f.t / blasterPeriod) - 0.6) / 0.4 * 3).rounded()) }
    let raise = drawing ? -1 : seatedPose ? -3 : 0
    c.oy += p.gunY + raise
    drawBow(c, pull: pull)
    let nocked = drawing || p.ready || (p.fire != nil && !firing)
    if nocked {
        let tail = 41 - pull
        c.rect(tail, 34, 47 - tail, 1, C(0x8A6A3A))
        c.px(47, 34, C(0xC8CCD4)); c.px(48, 34, C(0xE8ECF4))
        c.px(tail, 33, C(0xC83A2A)); c.px(tail, 35, C(0xC83A2A))
    }
    c.rect(38 - pull, 33, 3, 3, purple)
}

/// Hawkeye's recurve bow, gripped at the hand; `pull` draws the string back that many pixels.
private func drawBow(_ c: PixelCanvas, pull: Int) {
    let limb = C(0x3A1A4A), grip = C(0x9A6AC8), string = C(0xE0E0E8)
    for y in 25...43 {
        let d = abs(y - 34)
        let x = d <= 2 ? 44 : d <= 5 ? 43 : d <= 7 ? 42 : 41
        c.px(x, y, d <= 1 ? grip : limb)
        if d == 9 { c.px(x + 1, y, limb) }
    }
    // String from tip to tip, pulled back at the middle.
    for y in 26...42 {
        let d = Double(abs(y - 34)) / 8
        c.px(41 - Int((Double(pull) * (1 - d)).rounded()), y, string)
    }
}

// MARK: - Spider-Man

/// Spider-Man: Clawd in the red mask and suit with the black web lines, the huge white eyes outlined in black, blue
/// sides and legs, red boots and the black spider on his chest. Travelling, he swings: right hand up on the web line,
/// legs trailing. Signature: he drops into a crouch and his spider-sense tingles round his head.
private func drawSpiderMan(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD02A2A), redDark = C(0x9A1A1E), blue = C(0x2A4FB0), blueDark = C(0x1C3880), web = C(0x3A0A10)
    let look = Look(body: red, shade: redDark, leg: blue, arm: red, eye: nil)
    let swinging = p.walking
    let crouch = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let low = Int((3 * crouch).rounded())
    if swinging {
        // Legs trailing back and down as he swings.
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let kick = (i + p.step) % 2
            for r in 0..<7 { c.rect(lx - r / 2 - kick, 36 + r, 2, 1, r >= 5 ? red : blue) }
        }
    } else if low > 0 {
        // Crouched low: legs bent out to the sides.
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let out = i < 2 ? -1 : 1
            c.rect(lx + out * (i == 0 || i == 3 ? 2 : 1), 36 + low, 2, 8 - low, blue)
            c.rect(lx + out * (i == 0 || i == 3 ? 2 : 1), 42, 2, 2, red)
        }
    } else {
        drawLegs(c, look, step: p.step)
        drawBoots(c, red, step: p.step, rows: 2)
    }
    c.oy += p.breathe + low
    drawBody(c, look)
    c.pattern(18, 26, [
        "RRRkRRRRRkkRRRRRkRRR",
        "kRKKKKKRRkkRRKKKKKRk",
        "RkKWWWWKRkkRKWWWWKkR",
        "RRKWWWWKkkkkKWWWWKRR",
        "RkRKWWWKRkkRKWWWKRkR",
        "kRRRKKKkRkkRkKKKRRRk",
        "RkRRkRRRkkkkRRRkRRkR",
        "BBkRRkRRRkkRRRkRRkBB",
        "BBBRRRRRRRRRRRRRRBBB",
        "BBBBRRRRRRRRRRRRBBBb",
        "BBBBRRRRRRRRRRRRBBBb",
        "bbbbbbbbbbbbbbbbbbbb",
    ], ["R": red, "k": web, "K": ink, "W": white, "B": blue, "b": blueDark])
    c.pattern(25, 33, ["K.KK.K", ".KKKK.", "K.KK.K", ".K..K."], ["K": ink])
    c.rect(15, 33, 3, 3, red)
    if low > 0 {
        // Spider-sense: jagged lines flickering round his head.
        let on = Int(p.lt * 10) % 2
        for i in 0..<7 where (i + on) % 2 == 0 || crouch > 0.9 {
            let a = (-170 + Double(i) * 27) * .pi / 180
            let (x0, y0) = (28 + cos(a) * 12, 29 + sin(a) * 10), (x1, y1) = (28 + cos(a) * 15.5, 29 + sin(a) * 13)
            c.glowLine(x0, y0, x1, y1, core: C(0xFFFFFF, 0.9), glow: C(0, 0), coreR: 0.5, glowR: 0.55)
        }
    }
    if swinging {
        // Right hand up on the web line at (41, 22).
        c.glowLine(39, 32, 41, 23, core: red, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
        c.rect(40, 21, 3, 3, red); c.px(42, 21, redDark)
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 4, 3, red)
    c.px(41, 33, redDark)
    if p.fire != nil || p.ready {          // thwip: two fingers folded, the web-shooter showing
        c.px(41, 34, C(0xC8CCD4))
    }
}

// MARK: - Black Panther

/// Black Panther: Clawd in the black vibranium suit with pointed cat ears, silver slanted eye lenses and the silver
/// claw necklace. The claws come out of his right hand to fight, leaving a purple smear. Signature: he raises his hand
/// and the claws snick out, a glint runs over the helmet and the suit's kinetic charge glows purple.
private func drawBlackPanther(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1E26), suitLight = C(0x34343F), silver = C(0xC8CCD4), silverDark = C(0x7A7F8C)
    let violet = C(0xA67AFF)
    let look = Look(body: suit, shade: C(0x121218), leg: suit, arm: suit, eye: nil)
    drawLegs(c, look, step: p.step)
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(18, 22, [
        "...K............K...",
        "..KsK..........KsK..",
        ".KKsKK........KKsKK.",
        ".KKKKKKKKKKKKKKKKKK.",
        "KKKKLLLLLLLLLLLLKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKWWKKKKKKKKKKWWKKK",
        "KKKWWWWKKKKKKWWWWKKK",
        "KKKKKWWKKKKKKWWKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KSKKKKKKKKKKKKKKKKSK",
        "KKSKKKKKKKKKKKKKKSKK",
        "KKKSKSKKKKKKKKSKSKKK",
        "KKKKKKSKSSSSKSKKKKKK",
    ], ["K": suit, "L": suitLight, "s": silverDark, "W": silver, "S": silver])
    let sig = p.signature
    let charge = sig.map { $0 > 0.4 ? habitArc(($0 - 0.4) / 0.6, hold: 0.3) : 0 } ?? 0
    if charge > 0 {
        // Kinetic energy running along the suit's lines.
        let col = violet.alpha(0.4 + 0.6 * charge)
        for (x, y) in [(19, 33), (21, 34), (23, 35), (36, 33), (34, 34), (32, 35), (27, 36), (28, 36), (24, 30), (31, 30)] {
            c.px(x, y, col)
        }
        c.glowLine(28, 36, 28, 36, core: C(0xE8DAFF).alpha(charge), glow: violet.alpha(charge), coreR: 0.5, glowR: 2)
    }
    c.rect(15, 33, 3, 3, suit)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawClaws(c, angle: ta, alpha: 0.4 / Double(i + 1), smear: violet) }
        drawClaws(c, angle: a)
    } else if let s = sig, s > 0.08, s < 0.94 {
        // Hand up, claws out.
        let out = min(1, (s - 0.08) / 0.12)
        c.rect(38, 29, 3, 3, suit)
        for (i, dy) in [-1, 0, 1].enumerated() {
            let len = Int((Double(3 + (i == 1 ? 1 : 0)) * out).rounded())
            for k in 0..<len { c.px(41 + k, 29 + dy * 1 - k / 2 + 1, k == len - 1 ? white : silver) }
        }
        if s > 0.2 && s < 0.6 { drawGlint(c, p: (s - 0.2) / 0.4, maxX: 46) }
    } else {
        c.rect(38, 33, 3, 3, suit)
        c.px(40, 34, suitLight)
    }
}

/// Panther's forearm and three silver claws, out from the hand at `angle` degrees.
private func drawClaws(_ c: PixelCanvas, angle: Double, alpha: Double = 1, smear: Px? = nil) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        let silver = smear ?? C(0xC8CCD4), tip = smear ?? white
        if smear == nil { s.rect(17, 19, 5, 3, C(0x1E1E26)) }
        for dy in [-1, 0, 1] {
            let len = dy == 0 ? 6 : 5
            for k in 0..<len { s.px(22 + k, 20 + dy * (1 + k / 3), k == len - 1 ? tip : silver) }
        }
    }
}

// MARK: - Doctor Strange

/// Doctor Strange: Clawd with slicked-back black hair going white at the temples and a goatee, the blue tunic and
/// sash, the red Cloak of Levitation with its tall gold-edged collar (it hangs beneath him as he hovers) and the Eye of
/// Agamotto at his throat. Casting, an orange mandala spins round his hand. Signature: the Eye opens and glows green,
/// and a green time mandala turns round his raised hand.
private func drawDoctorStrange(_ c: PixelCanvas, _ p: Pose) {
    let tunic = C(0x2A3A7A), tunicDark = C(0x1C285A), cloak = C(0xB02A2A), cloakDark = C(0x7A1A1A)
    let gold = C(0xE0A030), hair = C(0x1A1A22), grey = C(0xD8D8E0)
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.7, color: cloak, edge: cloakDark, extra: 1.5)
    drawLegs(c, Look(leg: tunicDark), step: p.step)
    drawBoots(c, C(0x3A2A20), step: p.step, rows: 2)
    c.oy += p.breathe
    let sig = p.signature
    let timeStone = sig.map { habitArc($0, hold: 0.6) } ?? 0
    let handUp = p.armRaise + (timeStone > 0.05 ? 3 : 0)
    drawBody(c, Look(arm: tunic), armRight: handUp)
    // Collar standing up behind the head.
    c.pattern(13, 22, [
        "..CCC......................CCC..",
        ".CCCCC....................CCCCC.",
        "CCCCCgg..................ggCCCCC",
        ".CCCCCg..................gCCCCC.",
        "..CCCCg..................gCCCC..",
        "...CCCg..................gCCC...",
        "....CCg..................gCC....",
        ".....Cg..................gC.....",
    ], ["C": cloak, "g": gold])
    c.pattern(18, 22, [
        "....HHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHH.",
        "GGHHHH.HHHHHH.HHHHGG",
        "GH................HG",
        "H..................H",
    ], ["H": hair, "G": grey])
    // Goatee and moustache.
    c.rect(25, 32, 6, 1, hair); c.rect(26, 33, 4, 1, hair)
    // Tunic, sash, the Eye of Agamotto.
    c.rect(18, 34, 20, 4, tunic)
    c.rect(18, 34, 2, 4, cloak); c.rect(36, 34, 2, 4, cloak)
    c.rect(20, 36, 16, 1, C(0xD8B040))
    c.rect(18, 37, 20, 1, tunicDark)
    c.rect(15, 33, 3, 3, tunic)
    let eye = timeStone > 0.2 ? C(0x5CFF7A) : C(0x2A5A3A)
    c.pattern(26, 34, [".GG.", "GEEG", ".GG."], ["G": gold, "E": eye])
    if timeStone > 0.2 { c.glowLine(28, 35.5, 28, 35.5, core: C(0xD8FFE0), glow: C(0x3AE85A), coreR: 0.6, glowR: 2.4 * timeStone) }
    let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(handUp))
    if timeStone > 0.2 {
        drawMandala(c, at: hand, r: 5 * min(1, timeStone * 1.4), t: p.t, core: C(0xD8FFE0), glow: C(0x3AE85A))
    } else if p.zap != nil {
        drawMandala(c, at: hand, r: 4, t: p.t, core: C(0xFFE8B0), glow: C(0xFF8A1E))
    }
}

/// A sorcerer's spinning mandala: a glowing ring with a turning inner square, centred on `at`.
private func drawMandala(_ c: PixelCanvas, at: (x: Double, y: Double), r: Double, t: Double, core: Px, glow: Px) {
    guard r >= 1 else { return }
    let n = 12
    for i in 0..<n {
        let a0 = Double(i) / Double(n) * 2 * .pi + t * 2, a1 = Double(i + 1) / Double(n) * 2 * .pi + t * 2
        c.glowLine(at.x + cos(a0) * r, at.y + sin(a0) * r, at.x + cos(a1) * r, at.y + sin(a1) * r,
                   core: core.alpha(0.9), glow: glow.alpha(0.6), coreR: 0.35, glowR: 1.2)
    }
    for i in 0..<4 {
        let a0 = Double(i) * .pi / 2 - t * 3, a1 = Double(i + 1) * .pi / 2 - t * 3
        let r2 = r * 0.62
        c.glowLine(at.x + cos(a0) * r2, at.y + sin(a0) * r2, at.x + cos(a1) * r2, at.y + sin(a1) * r2,
                   core: core.alpha(0.7), glow: glow.alpha(0.4), coreR: 0.3, glowR: 0.9)
    }
}

// MARK: - Scarlet Witch

/// Scarlet Witch: Clawd with long auburn hair under the pointed scarlet tiara, a crimson corset and a long dark-red
/// coat that hangs below her as she hovers. Red hex wisps curl round her casting hand. Signature: both hands come up,
/// her eyes glow and the hex magic swirls round her in a ring.
private func drawScarletWitch(_ c: PixelCanvas, _ p: Pose) {
    let crimson = C(0xB81E40), crimsonDark = C(0x7A0E22), coat = C(0x8A1430), coatEdge = C(0xC02A48)
    let hair = C(0x7A2A1E), hairDark = C(0x5A1A12), tiara = C(0xE02848), tiaraLight = C(0xFF8A9A)
    let hex = (core: C(0xFFD0DA), glow: C(0xFF2A4A))
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.8, color: coat, edge: coatEdge, extra: 1)
    drawLegs(c, Look(leg: C(0x2A1018)), step: p.step)
    drawBoots(c, C(0xD02848), step: p.step, rows: 3)
    c.oy += p.breathe
    let sig = p.signature
    let power = sig.map { habitArc($0, hold: 0.6) } ?? 0
    let lift = power > 0.05 ? 4 : 0
    drawBody(c, Look(arm: crimson), armLeft: lift, armRight: max(p.armRaise, lift))
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHhHHHHHHHHhHHHHH..",
        ".HHHHh............hHHHH.",
        ".HHHh..............hHHH.",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HH..................HH.",
        "HHH..................HHH",
        "HHh..................hHH",
        "HH....................HH",
        "Hh....................hH",
    ], ["H": hair, "h": hairDark])
    c.pattern(18, 16, [
        ".........TT.........",
        "........TLLT........",
        "........TLLT........",
        "..TT...TTLLTT...TT..",
        "...TT.TTTLLTTT.TT...",
        "...TTTTTTTTTTTTTT...",
        "....dddddddddddd....",
    ], ["T": tiara, "L": tiaraLight, "d": crimsonDark])
    if power > 0.3 {
        c.rect(22, 29, 2, 3, C(0xFF3A5A)); c.rect(32, 29, 2, 3, C(0xFF3A5A))
        c.px(22, 29, C(0xFFD0DA)); c.px(32, 29, C(0xFFD0DA))
    }
    c.rect(18, 33, 20, 5, crimson)
    c.pattern(22, 33, ["KK......KK", ".KK....KK.", "..KKKKKK.."], ["K": crimsonDark])
    c.rect(18, 37, 20, 1, crimsonDark)
    if power > 0.05 {
        drawHex(c, at: (16.5, 34.5 - Double(lift)), t: p.t, r: 3, core: hex.core, glow: hex.glow)
        drawHex(c, at: (39.5, 34.5 - Double(lift)), t: p.t + 1, r: 3, core: hex.core, glow: hex.glow)
        // The ring of chaos magic round her.
        let r = 15 * power
        for i in 0..<3 {
            let a = p.t * 3 + Double(i) * 2 * .pi / 3
            c.glowLine(28 + cos(a) * r, 31 + sin(a) * r * 0.6, 28 + cos(a + 0.6) * r, 31 + sin(a + 0.6) * r * 0.6,
                       core: hex.core, glow: hex.glow, coreR: 0.4, glowR: 1.6)
        }
    } else if p.zap != nil {
        drawHex(c, at: (Sprite.hand.x, Sprite.hand.y - Double(p.armRaise)), t: p.t, r: 3, core: hex.core, glow: hex.glow)
    }
}

/// Hex wisps: two little glowing strands curling round a hand.
private func drawHex(_ c: PixelCanvas, at: (x: Double, y: Double), t: Double, r: Double, core: Px, glow: Px) {
    for k in 0..<2 {
        var prev: (Double, Double)? = nil
        for i in 0...5 {
            let a = t * 5 + Double(k) * .pi + Double(i) * 0.45
            let rr = r * (0.6 + Double(i) * 0.12)
            let q = (at.x + cos(a) * rr, at.y + sin(a) * rr * 0.8)
            if let pv = prev {
                c.glowLine(pv.0, pv.1, q.0, q.1, core: core.alpha(0.9), glow: glow.alpha(0.8), coreR: 0.35, glowR: 1.3)
            }
            prev = q
        }
    }
}

// MARK: - Vision

private let visionGem = (x: 29.5, y: 29.0)

/// Vision: the comic-book synthezoid, a red Clawd face with dark grooves, the yellow Mind Stone set in his brow,
/// green suit with a yellow diamond and belt, a tall-collared yellow cape. His beam fires from the gem in his brow. In
/// flight he leans in, cape streaming. Signature: he phases, fading half see-through while an after-image drifts off behind him.
private func drawVision(_ c: PixelCanvas, _ p: Pose) {
    let phase = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    if phase > 0.05 {
        // Ghost images either side, then the faded body.
        layer(c, alpha: 0.25 * phase, dx: -Int((3 * phase).rounded())) { drawVisionBody($0, p) }
        layer(c, alpha: 1 - 0.65 * phase) { drawVisionBody($0, p) }
        return
    }
    layer(c, lean: p.flying ? 4 : 0) { drawVisionBody($0, p) }
}

private func drawVisionBody(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD8344A), redDark = C(0x8A1A30), green = C(0x2E8A3E), greenDark = C(0x1E5A2A)
    let yellow = C(0xE8C030), yellowDark = C(0xB08A1A), cape = C(0xC89A28), capeEdge = C(0x8A6A18)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: cape, edge: capeEdge)
    } else {
        drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge)
    }
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, yellow, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: redDark, arm: green), armRight: p.flying ? 0 : p.armRaise)
    // Tall cape collar.
    c.pattern(15, 27, [
        "YY......................YY",
        "YYy....................yYY",
        "YYYy..................yYYY",
        ".YYy..................yYY.",
        "..Yy..................yY..",
    ], ["Y": yellow, "y": yellowDark])
    // Face grooves and the gem.
    c.pattern(17, 26, [
        "dd..................dd",
        ".d..................d.",
        "....................d.",
    ], ["d": redDark])
    c.pattern(26, 25, [".dGGd.", "dGWGGd", ".dGGd."], ["d": redDark, "G": yellow, "W": C(0xFFF8D0)])
    if p.zap != nil || p.flying {
        c.glowLine(28.5, 26.5, 28.5, 26.5, core: C(0xFFF8D0), glow: C(0xFFC81E), coreR: 0.6, glowR: 2.6)
    }
    // Green suit with the yellow diamond and belt.
    c.rect(18, 33, 20, 5, green)
    c.rect(37, 33, 1, 5, greenDark)
    c.pattern(24, 32, ["...YY...", "..YYYY..", ".YYggYY.", "..YYYY..", "...YY..."], ["Y": yellow, "g": green])
    c.rect(18, 37, 20, 1, yellowDark)
    if p.flying { c.rect(38, 31, 4, 3, green); c.glowLine(42, 32, 42, 32, core: C(0xFFF8D0), glow: C(0xFFC81E), coreR: 0.5, glowR: 1.6) }
}

// MARK: - Captain Marvel

/// Captain Marvel: Clawd with long blonde hair, the blue-and-red suit with the gold eight-pointed star on her chest,
/// red gloves and boots; photon blasts from her fist. In flight she punches forward, fists glowing, legs trailing.
/// Signature: she goes binary, a fiery gold aura flares round her, her hair lifts and her eyes blaze.
private func drawCaptainMarvel(_ c: PixelCanvas, _ p: Pose) {
    let binary = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    if binary > 0.05 {
        let flick = 0.85 + 0.15 * sin(p.t * 30)
        c.oy += p.breathe
        c.ellipse(28, 30, Int(14 * binary), Int(15 * binary), C(0xFF9A2A, 0.18 * binary * flick))
        c.ellipse(28, 31, Int(11 * binary), Int(12 * binary), C(0xFFD04A, 0.22 * binary * flick))
        c.oy -= p.breathe
    }
    layer(c, lean: p.flying ? 4 : 0) { c in
        let blue = C(0x2A3A8A), blueDark = C(0x1C2860), red = C(0xC8202A), gold = C(0xF0C040)
        let hair = binary > 0.4 ? C(0xFFE890) : C(0xE8C860), hairDark = binary > 0.4 ? C(0xFFC040) : C(0xB8963A)
        drawLegs(c, Look(leg: blue), step: p.step)
        drawBoots(c, red, step: p.step, rows: 3)
        if p.flying {
            for x in [19, 23, 31, 35] { c.glowLine(Double(x) + 1, 44, Double(x) + 1, 46, core: C(0xFFF4D0, 0.8), glow: C(0xFF9A2A, 0.6), coreR: 0.4, glowR: 1.3) }
        }
        c.oy += p.breathe
        drawBody(c, Look(arm: red))
        let up = Int((3 * binary).rounded())
        c.pattern(16, 21 - up, [
            "......HHHHHHHHHHHH......",
            "....HHHHHHHHHHHHHHHH....",
            "...HHHHHHHHHHHHHHHHHH...",
            "..HHHhHHHHHHHHHHHHHHHH..",
            "..HHHHHHHHHhHHHHHHHHHH..",
            ".HHHHHHHH......hHHHHHH..",
            ".HHHHh..........hHHHHH..",
        ], ["H": hair, "h": hairDark])
        c.pattern(16, 26, [
            "HHHh................hHHH",
            ".HHh................hHH.",
            ".HHH................HHH.",
            ".HHh................hHH.",
            "HHH..................HH.",
            "HHh..................hHH",
            "HH....................HH",
        ], ["H": hair, "h": hairDark])
        if binary > 0.4 {
            c.rect(22, 29, 2, 3, C(0xFFF4C0)); c.rect(32, 29, 2, 3, C(0xFFF4C0))
            for i in 0..<5 {                                   // the hair burns up into a crest
                let x = 20.5 + Double(i) * 3.6, h = 2 + noise(Int(p.t * 14) + i * 5) * 3 + (i == 2 ? 2 : 0)
                let y0 = Double(22 - up) + abs(Double(i) - 2) * 0.8
                c.glowLine(x, y0, x + 0.5, y0 - h * binary, core: C(0xFFF4C0), glow: C(0xFF9A2A), coreR: 0.6, glowR: 1.6)
            }
        }
        c.rect(18, 33, 20, 5, blue)
        c.rect(18, 33, 3, 5, red); c.rect(35, 33, 3, 5, red)
        c.rect(37, 33, 1, 5, C(0x8A1218))
        c.pattern(25, 33, ["G.G.G", ".GGG.", "GGWGG", ".GGG.", "G.G.G"], ["G": gold, "W": C(0xFFF4C0)])
        c.rect(18, 37, 20, 1, blueDark)
        c.rect(15, 33, 3, 3, red)
        let fistGlow = binary > 0.2 || p.fire != nil || p.flying || p.ready
        if p.flying {
            c.rect(38, 31, 5, 3, red)
            c.glowLine(43, 32, 43, 32, core: C(0xFFF4D0), glow: C(0xFF9A2A), coreR: 0.8, glowR: 2.4)
            return
        }
        c.oy += p.gunY
        c.rect(38, 33, 4, 3, red)
        if fistGlow {
            c.glowLine(42, 34.5, 42, 34.5, core: C(0xFFF4D0), glow: C(0xFF9A2A), coreR: 0.6, glowR: 2)
            if binary > 0.2 { c.glowLine(16, 34.5, 16, 34.5, core: C(0xFFF4D0), glow: C(0xFF9A2A), coreR: 0.6, glowR: 2) }
        }
    }
}

// MARK: - Shared helpers

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A flickering jet flame pointing down from (`x`, `y`), `w` wide.
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int) {
    let len = 2 + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, C(0xFF9A2A, 0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, C(0xFFE27A))
    c.rect(x, y, w, 1, C(0xF4FCFF))
}

/// A cape streaming out behind (to the left) in flight.
private func drawFlyingCape(_ c: PixelCanvas, t: Double, color: Px, edge: Px) {
    for x in 3...20 {
        let k = Double(20 - x) / 17
        let mid = 29 + k * 4 + sin(t * 9 - k * 5) * k * 1.6
        let half = 3 + k * 2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, color)
        c.px(x, top, edge); c.px(x, bottom, edge)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`, and
/// leaning forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = dx + (lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0)
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i).alpha(alpha))
        }
    }
}

/// A prop drawn pointing right from pixel (20, 20) of a scratch canvas, turned to `angle` degrees (0 forward, -90 up)
/// and placed with that point on `at`.
private func prop(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(41, 41)
    art(s)
    let r = s.rotated(angle, about: (20.5, 20.5), into: 41, 41, at: (20.5, 20.5))
    let x0 = Int(floor(at.x - 20.5)), y0 = Int(floor(at.y - 20.5))
    for y in 0..<r.h {
        for x in 0..<r.w {
            let i = (y * r.w + x) * 4
            guard r.buf[i + 3] > 0 else { continue }
            c.px(x0 + x, y0 + y, unpremultiplied(r, i).alpha(alpha))
        }
    }
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}
