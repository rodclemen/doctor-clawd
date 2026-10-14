import Foundation

// Heroes: mystics, cosmic and the funny ones. Clawd in costume again, except Jeff and Lockjaw, who are a shark and
// a dog (blocky ones, at least).

let heroes9: [MarvelHero: Persona] = [
    .monicaRambeau: Persona(name: "Monika Rambeaux", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFFFFF), glow: C(0x8AC8FF)),
                  muzzle: (43, 34), handGun: false, headTop: 17, signature: 3.0,
                  draw: drawMonicaRambeau),
    .clea: Persona(name: "Kleah", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xF0E0FF), glow: C(0xC04AFF), jagged: false),
                  headTop: 20, signature: 3.0,
                  draw: drawClea),
    .doctorVoodoo: Persona(name: "Doctor Hoodoo", weapon: .lightning, magic: Magic(core: C(0xF0FFE0), glow: C(0x6AE04A), jagged: false),
                  headTop: 22, signature: 3.2,
                  draw: drawDoctorVoodoo),
    .howardTheDuck: Persona(name: "Harold the Duck", weapon: .blaster, shot: .bullet, muzzle: (47, 33), headTop: 19, signature: 3.0,
                  draw: drawHowardTheDuck),
    .squirrelGirl: Persona(name: "Squirrel Gal", weapon: .saber, headTop: 19, signature: 3.2,
                  draw: drawSquirrelGirl),
    .jeffTheLandShark: Persona(name: "Geoff the Land Shark", weapon: .saber, canSit: false, bulk: 2, headTop: 24, signature: 2.6,
                  draw: drawJeffTheLandShark),
    .throg: Persona(name: "Frogg of Thunder", weapon: .saber, headTop: 19, signature: 3.2, callout: "For Asgaard! Ribbit.",
                  draw: drawThrog),
    .lockjaw: Persona(name: "Lockjaws", bulk: 8, headTop: 9, signature: 3.0,
                  draw: drawLockjaw),
    .forbushMan: Persona(name: "Furbush Man", headTop: 20, signature: 3.2,
                  draw: drawForbushMan),
]

// MARK: - Monica Rambeau

/// Monica Rambeau: the classic Captain Marvel/Photon look, a big round afro, a black bodysuit with the white
/// starburst across the chest and white gloves; light blasts from her fist. In flight she punches forward, legs
/// trailing light. Signature: she turns into light, a glow swells round her and she goes bright white-blue, then back.
private func drawMonicaRambeau(_ c: PixelCanvas, _ p: Pose) {
    let light = p.signature.map { habitArc($0, hold: 0.45) } ?? 0
    let core = C(0xF4FAFF), glow = C(0x8AC8FF)
    if light > 0.05 {
        let flick: Double = 0.85 + 0.15 * sin(p.t * 30)
        c.oy += p.breathe
        c.ellipse(28, 31, Int(15 * light), Int(15 * light), glow.alpha(0.2 * light * flick))
        c.ellipse(28, 32, Int(11 * light), Int(12 * light), core.alpha(0.22 * light * flick))
        if light > 0.6 {
            for i in 0..<8 {
                let a: Double = Double(i) * .pi / 4 + p.t * 1.5
                c.glowLine(28 + cos(a) * 12, 31 + sin(a) * 12, 28 + cos(a) * 16, 31 + sin(a) * 16,
                           core: core.alpha(0.8), glow: glow.alpha(0.5), coreR: 0.4, glowR: 1.2)
            }
        }
        c.oy -= p.breathe
    }
    layer(c, lean: p.flying ? 4 : 0, tint: light > 0.05 ? 0.95 * light : nil) { c in
        let suit = C(0x1C1C26), suitDark = C(0x0C0C12), skin = C(0x7A4A30), skinShade = C(0x5A3420)
        let star = C(0xE8ECF2), hair = C(0x1A1412), hairLight = C(0x3A2C26)
        drawLegs(c, Look(leg: suit), step: p.step)
        drawBoots(c, star, step: p.step, rows: 1)
        if p.flying {
            for x in [19, 23, 31, 35] {
                c.glowLine(Double(x) + 1, 44, Double(x) + 1, 46, core: core.alpha(0.8), glow: glow.alpha(0.6), coreR: 0.4, glowR: 1.3)
            }
        }
        c.oy += p.breathe
        drawBody(c, Look(body: skin, shade: skinShade, arm: suit))
        c.pattern(15, 17, [
            "........HHHHHHHHHH........",
            ".....HHHHHhHHHHHHHHHH.....",
            "...HHHHHHHHHHHHHhHHHHHH...",
            "..HHHhHHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHhHHHHHHHHhHHH.",
            ".HHHHHHHHHHHHHHHHHHHHHHHH.",
            "HHHHHhHHHHHHHHHHHHHHHHHHHH",
            "HHHHHHHHHHHHHHHHHHHHHhHHHH",
            "HHHHHHHHhHHHHHHHHHHHHHHHHH",
            "HHHHHHHHHHHHHHHHHHHHHHHHHH",
            "HHHhHH..............HHhHHH",
            ".HHHh................hHHH.",
            ".HHH..................HHH.",
            "..HH..................HH..",
        ], ["H": hair, "h": hairLight])
        // The suit and the starburst.
        c.rect(18, 33, 20, 5, suit)
        c.rect(18, 37, 20, 1, suitDark)
        c.pattern(19, 33, [
            "WWWWWWWWWWWWWWWWWW",
            ".W.WWWWWWWWWWWW.W.",
            "....W.WWWWWW.W....",
            ".......WWWW.......",
            "........WW........",
        ], ["W": star])
        c.rect(15, 33, 3, 3, suit); c.rect(15, 35, 3, 1, star)
        let fistGlow = light > 0.2 || p.fire != nil || p.flying || p.ready
        if p.flying {
            c.rect(38, 31, 5, 3, star); c.rect(38, 31, 2, 3, suit)
            c.glowLine(43, 32, 43, 32, core: core, glow: glow, coreR: 0.8, glowR: 2.4)
            return
        }
        c.oy += p.gunY
        c.rect(38, 33, 4, 3, star); c.rect(38, 33, 1, 3, suit)
        if fistGlow { c.glowLine(42.5, 34.5, 42.5, 34.5, core: core, glow: glow, coreR: 0.6, glowR: 2) }
    }
}

// MARK: - Clea

/// Clea: the Dark Dimension's sorceress, long white hair, a purple bodysuit with a magenta V and a gold belt; she
/// hovers on a faint purple shimmer and purple wisps curl round her casting hand. Signature: her hair flares up into
/// purple-white Dark Dimension flame and her eyes glow.
private func drawClea(_ c: PixelCanvas, _ p: Pose) {
    let flare = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let suit = C(0x5A2A9A), suitDark = C(0x3A1A6A), trim = C(0xD04AC8), gold = C(0xE8C02A)
    let hair = flare > 0.4 ? C(0xF0E4FF) : C(0xECECF4), hairShade = flare > 0.4 ? C(0xC08AF0) : C(0xB0B0C8)
    let core = C(0xF0E0FF), glow = C(0xC04AFF)
    if flare > 0.05 {
        let flick: Double = 0.85 + 0.15 * sin(p.t * 30)
        c.oy += p.breathe
        c.ellipse(28, 28, Int(13 * flare), Int(14 * flare), glow.alpha(0.18 * flare * flick))
        c.oy -= p.breathe
    }
    if !seatedPose {
        for x in [20, 28, 36] {          // the shimmer she floats on
            let a: Double = 0.35 + 0.25 * sin(p.t * 5 + Double(x))
            c.glowLine(Double(x) - 2, 45, Double(x) + 2, 45, core: core.alpha(a), glow: glow.alpha(a), coreR: 0.3, glowR: 1.2)
        }
    }
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, suitDark, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: p.armRaise)
    let up = Int((2 * flare).rounded())
    c.pattern(16, 20 - up, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHhHHHHHHHHHHHHHH...",
        "..HHHHHHHHHhHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHhHHH..",
        ".HHHHHHHH......hHHHHHH..",
        ".HHHHh..........hHHHHH..",
    ], ["H": hair, "h": hairShade])
    c.pattern(16, 27, [
        "HHHh................hHH.",
        ".HHh................hHH.",
        ".HHH................HHH.",
        ".HHh................hHHH",
        "HHHh................hHHH",
        "HHh..................hHH",
        "HH....................HH",
        "H......................H",
    ], ["H": hair, "h": hairShade])
    if flare > 0.4 {
        for x in [23.0, 33.0] { c.glowLine(x, 30.5, x, 30.5, core: core, glow: glow, coreR: 1, glowR: 2.2) }
        for i in 0..<6 {                       // the hair burns up into Dark Dimension flame
            let x: Double = 19.5 + Double(i) * 3.4
            let h: Double = 3 + noise(Int(p.t * 14) + i * 5) * 4 + (i == 2 || i == 3 ? 2 : 0)
            let y0: Double = Double(21 - up) + abs(Double(i) - 2.5) * 0.8
            c.glowLine(x, y0, x + sin(p.t * 9 + Double(i)) * 0.8, y0 - h * flare, core: core, glow: glow, coreR: 0.6, glowR: 1.7)
        }
    }
    // Suit: purple with a magenta V and a gold belt.
    c.rect(18, 33, 20, 5, suit)
    c.pattern(23, 33, ["MM......MM", ".MM....MM.", "..MM..MM..", "...MMMM..."], ["M": trim])
    c.rect(18, 36, 20, 1, gold)
    c.rect(18, 37, 20, 1, suitDark)
    c.rect(15, 33, 3, 3, suit)
    c.rect(38, 33 - p.armRaise, 3, 3, suit); c.rect(40, 33 - p.armRaise, 1, 3, clawdOrange)
    if p.zap != nil || flare > 0.3 {
        let hx = Sprite.hand.x, hy = Sprite.hand.y - Double(p.armRaise)
        for i in 0..<3 {
            let a: Double = p.t * 6 + Double(i) * 2.1
            c.glowLine(hx + cos(a) * 3, hy + sin(a) * 3, hx + cos(a + 0.6) * 3, hy + sin(a + 0.6) * 3,
                       core: core.alpha(0.9), glow: glow.alpha(0.6), coreR: 0.35, glowR: 1.2)
        }
    }
}

// MARK: - Doctor Voodoo

/// Doctor Voodoo: Jericho Drumm as Sorcerer Supreme, skull face paint (white sockets, a painted grin), a purple suit
/// with gold trim, a tall gold-edged collar and purple cape, and a gold amulet with a green eye at his throat; green
/// magic. Signature: the spirit of his brother Daniel rises beside him, a green ghost with the same skull face, while
/// Jericho's eyes and amulet glow green.
private func drawDoctorVoodoo(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2A8A), purpleDark = C(0x45185E), gold = C(0xE8C02A), goldDark = C(0xB08A1A)
    let skin = C(0x4A2E20), skinShade = C(0x34201A), bone = C(0xE8E2D2)
    let green = C(0x6AE04A), greenCore = C(0xF0FFE0)
    let spirit = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if spirit > 0.02 { drawDaniel(c, p, k: spirit) }
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.7, color: purpleDark, edge: gold, extra: 1)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, purpleDark, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: purple, eye: nil), armRight: p.armRaise)
    // Collar standing up behind the head.
    c.pattern(13, 22, [
        "..PPP......................PPP..",
        ".PPPPP....................PPPPP.",
        "PPPPPgg..................ggPPPPP",
        ".PPPPPg..................gPPPPP.",
        "..PPPPg..................gPPPP..",
        "...PPPg..................gPPP...",
        "....PPg..................gPP....",
    ], ["P": purple, "g": gold])
    // Skull paint: white sockets, a painted nose and teeth.
    c.rect(21, 28, 4, 4, bone); c.rect(31, 28, 4, 4, bone)
    c.rect(22, 27, 2, 1, bone); c.rect(32, 27, 2, 1, bone)
    let eye = spirit > 0.3 ? green : ink
    c.rect(22, 29, 2, 2, eye); c.rect(32, 29, 2, 2, eye)
    c.px(27, 31, ink); c.px(28, 31, ink)
    c.rect(24, 32, 8, 2, bone)
    for x in [25, 27, 29] { c.rect(x, 32, 1, 2, skinShade) }
    // Suit and amulet.
    c.rect(18, 34, 20, 4, purple)
    c.rect(18, 34, 20, 1, gold)
    c.rect(18, 37, 20, 1, purpleDark)
    c.pattern(26, 34, [".GG.", "GEEG", ".GG."], ["G": gold, "E": spirit > 0.3 ? green : C(0x2A5A3A)])
    c.px(25, 35, goldDark); c.px(30, 35, goldDark)
    if spirit > 0.3 { c.glowLine(28, 35.5, 28, 35.5, core: greenCore, glow: green, coreR: 0.6, glowR: 2.2 * spirit) }
    c.rect(15, 33, 3, 3, purple); c.rect(15, 35, 3, 1, gold)
    c.rect(38, 33 - p.armRaise, 3, 3, purple); c.rect(38, 35 - p.armRaise, 3, 1, gold)
    if p.zap != nil {
        let hx = Sprite.hand.x, hy = Sprite.hand.y - Double(p.armRaise)
        c.glowLine(hx, hy, hx, hy, core: greenCore.alpha(0.8), glow: green.alpha(0.6), coreR: 0.5, glowR: 2.2)
    }
}

/// Daniel Drumm's ghost: a small green Clawd with a skull face and a wisp for legs, rising behind Jericho's shoulder.
private func drawDaniel(_ c: PixelCanvas, _ p: Pose, k: Double) {
    let rise = Int((6 * (1 - k)).rounded()), bob = sin(p.t * 3) > 0 ? -1 : 0
    let y0 = 17 + rise + bob + p.breathe
    c.glowLine(9, Double(y0 + 7), 9, Double(y0 + 7), core: C(0xC8FFC8, 0.2 * k), glow: C(0x6AE04A, 0.3 * k), coreR: 4, glowR: 9)
    layer(c, alpha: 0.7 * k) { s in
        s.pattern(2, y0, [
            "...GGGGGGGG...",
            ".GGGGGGGGGGGG.",
            "GGGGGGGGGGGGGg",
            "GWWWGGGGGWWWGg",
            "GWKWGGGGGWKWGg",
            "GWKWGGGGGWKWGg",
            "GGGGGGKKGGGGGg",
            "GGGWWWWWWWGGGg",
            "GGGWKWKWKWGGGg",
            "GGGGGGGGGGGGGg",
            ".GGGGGGGGGGGg.",
            "..GGGG.GGGGg..",
            "...GG...GGg...",
            "....G....g....",
        ], ["G": C(0x7AF09A), "g": C(0x4AB86A), "W": C(0xD8FFE0), "K": C(0x1A5A2A)])
    }
}

// MARK: - Howard the Duck

/// Howard the Duck: a white duck under a blue fedora, a big orange bill with a cigar in the corner, a blue suit jacket
/// over a white shirt and red tie, orange webbed feet and a little pistol; he always looks fed up. Signature: he
/// takes a long puff (the cigar glows, smoke rises) and grumbles a grawlix.
private func drawHowardTheDuck(_ c: PixelCanvas, _ p: Pose) {
    let feather = C(0xF2EEE6), featherShade = C(0xC4BCB0), bill = C(0xF0A030), billDark = C(0xC07418)
    let blue = C(0x2A4A9A), blueDark = C(0x1A2E6A), red = C(0xC8202A), shirt = C(0xE0E4EC)
    let sig = p.signature
    drawLegs(c, Look(leg: bill), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom, 3, 1, billDark)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: feather, shade: featherShade, arm: blue, eye: nil))
    // Fedora.
    c.pattern(16, 19, [
        "....BBBBBBB..BBBBBBB....",
        "....BBBBBBBBBBBBBBBBb...",
        "....BBBBBBBBBBBBBBBBb...",
        "....BBBBBBBBBBBBBBBBb...",
        "....kkkkkkkkkkkkkkkkk...",
        "BBBBBBBBBBBBBBBBBBBBBBBb",
        ".bbbbbbbbbbbbbbbbbbbbbb.",
    ], ["B": blue, "b": blueDark, "k": C(0x101830)])
    // Grumpy eyes: heavy brows, and half-shut while he grumbles.
    let grumble = sig.map { $0 > 0.55 && $0 < 0.95 } ?? false
    c.px(21, 27, ink); c.rect(22, 28, 2, 1, ink); c.rect(32, 28, 2, 1, ink); c.px(34, 27, ink)
    c.rect(22, grumble ? 30 : 29, 2, grumble ? 1 : 2, ink); c.rect(32, grumble ? 30 : 29, 2, grumble ? 1 : 2, ink)
    // Bill.
    c.pattern(24, 31, [
        "..OOOOOOOOOOO..",
        ".OOOOOOOOOOOOOO",
        ".oooooooooooooO",
        "..ooooooooooo..",
    ], ["O": bill, "o": billDark])
    c.px(36, 31, billDark)
    // Cigar in the corner of the bill.
    let puff = sig.map { $0 > 0.1 && $0 < 0.4 } ?? false
    c.rect(19, 33, 6, 2, C(0x8A5A30)); c.rect(19, 34, 6, 1, C(0x5A3A1E)); c.rect(23, 33, 1, 2, C(0xC8A040))
    c.rect(18, 33, 1, 2, puff ? C(0xFFE27A) : C(0xE04A1A))
    if puff { c.glowLine(19.5, 34.5, 19.5, 34.5, core: C(0xFFE27A), glow: C(0xFF6A1A), coreR: 0.5, glowR: 1.6) }
    // Jacket, shirt and tie.
    c.rect(18, 35, 20, 3, blue)
    c.pattern(25, 35, ["SSSSSS", ".SRRS.", "..RR.."], ["S": shirt, "R": red])
    c.rect(18, 37, 20, 1, blueDark)
    c.rect(15, 33, 3, 3, blue); c.rect(15, 35, 3, 1, feather)
    // Smoke drifting up off the cigar, and the grumble.
    if let s = sig {
        if s > 0.2 {
            for i in 0..<3 {
                let f: Double = (s - 0.2) * 1.6 - Double(i) * 0.18
                guard f > 0, f < 1 else { continue }
                let x = 17 - Int(f * 5) + (i % 2), y = 32 - Int(f * 16)
                let col = C(0xB8BCC4, 0.75 * (1 - f))
                c.rect(x - 1, y, 3, 1, col); c.px(x - 2, y + 1, col); c.px(x + 2, y + 1, col); c.rect(x - 1, y + 2, 3, 1, col)
            }
        }
        if grumble {
            c.pattern(38, 13, [
                ".KKKKKKKKKK.",
                "KWWWWWWWWWWK",
                "KWaWbWWcWdWK",
                "KWaWbbWcWdWK",
                "KWWWbWWcWWWK",
                "KWaWWWccWdWK",
                ".KKKKKWKKKK.",
                "......KK....",
                ".....K......",
            ], ["K": C(0x3A3A44), "W": white, "a": red, "b": C(0x2A4A9A), "c": C(0x2A2A30), "d": C(0xE8A020)])
        }
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, blue); c.rect(40, 34, 1, 2, feather)
    drawPistol(c, x: 40, y: 32)
}

// MARK: - Squirrel Girl

/// Squirrel Girl: Doreen Green with a brown bob, a headband with squirrel ears, a buck-toothed grin, a brown jacket
/// with tan fur trim and a huge bushy squirrel tail curling up behind her; she fights with her fists. Signature:
/// Tippy-Toe (pink bow and all) hops in and sits on her head, flicks her tail, and hops off again.
private func drawSquirrelGirl(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x9A5E2E), furLight = C(0xC8925A), furDark = C(0x6A3E1E)
    let hair = C(0x5A341C), hairLight = C(0x7A4A2A), jacket = C(0x7A4A2A), trim = C(0xE0BC8A), pink = C(0xF08AB0)
    // The tail: up the back and curled over at the top.
    let wag = sin(p.lt * 2.2) > 0.6 ? 1 : 0
    c.oy += p.breathe
    c.pattern(2 + wag, 12, [
        ".....TTTTTT.....",
        "...TTTTTTTTTT...",
        "..TTTlllllTTTT..",
        ".TTTll....TTTTT.",
        ".TTll......TTTT.",
        ".TTT.......TTT..",
        "..TTT...........",
        "..TTTT..........",
        "...TTTT.........",
        "...TTTTT........",
        "..TTTlTTT.......",
        ".TTTTlTTTT......",
        ".TTTTllTTTTT....",
        "TTTTTTllTTTTT...",
        "TTTTTTTlTTTTTT..",
        "TTTTTTTllTTTTTT.",
        "TTTTTTTTlTTTTTTT",
        ".TTTTTTTllTTTTTT",
        ".TTTTTTTTlTTTTTT",
        "..TTTTTTTTTTTTTT",
        "...dTTTTTTTTTTTT",
        "....ddTTTTTTTTTT",
        "......dddTTTTTTT",
        ".........ddddddd",
    ], ["T": fur, "l": furLight, "d": furDark])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: C(0x3A2416)), step: p.step)
    drawBoots(c, jacket, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    // Bob, headband ears.
    c.pattern(17, 22, [
        "...HHHHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHhHHHHHHHHHHHHH",
        "HHHHhHHHHHHHHHHhHHHHHH",
        "HHHH..............HHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HH..................HH",
        "HH..................HH",
    ], ["H": hair, "h": hairLight])
    for x in [19, 33] { c.pattern(x, 19, [".E..", "EPE.", "EPEE"], ["E": fur, "P": pink]) }
    c.rect(18, 23, 20, 1, furDark)
    // Eyes (happy arcs while Tippy-Toe visits), the buck-toothed grin.
    let visit = p.signature.map { $0 > 0.3 && $0 < 0.85 } ?? false
    if visit {
        for x in [22, 32] { c.px(x, 30, ink); c.rect(x, 29, 2, 1, ink); c.px(x + 1, 30, ink) }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.px(23, 31, ink); c.rect(24, 32, 8, 1, ink); c.rect(25, 33, 6, 1, C(0x5A1A1A)); c.px(32, 31, ink)
    c.rect(27, 32, 2, 2, C(0xF4F0E0)); c.px(27, 33, C(0xE0DCC8))
    // Jacket with fur trim over a dark suit, yellow belt.
    c.rect(18, 34, 20, 4, C(0x3A2416))
    c.rect(18, 34, 5, 4, jacket); c.rect(33, 34, 5, 4, jacket)
    c.rect(18, 34, 5, 1, trim); c.rect(33, 34, 5, 1, trim)
    c.rect(22, 35, 1, 3, trim); c.rect(33, 35, 1, 3, trim)
    c.rect(23, 36, 10, 1, C(0xE8C02A))
    c.rect(18, 37, 20, 1, C(0x2A1A10))
    c.rect(15, 33, 3, 3, jacket); c.rect(15, 33, 1, 3, clawdOrange)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawFist(c, angle: ta, alpha: 0.35 / Double(i + 1), sleeve: jacket) }
        drawFist(c, angle: a, sleeve: jacket)
    } else {
        c.rect(38, 33, 3, 3, jacket); c.rect(40, 33, 1, 3, clawdOrange)
    }
    if let s = p.signature { drawTippyToe(c, s: s, t: p.t) }
}

/// Squirrel Girl's punch: a sleeve and a balled fist out from the hand at `angle` degrees.
private func drawFist(_ c: PixelCanvas, angle: Double, alpha: Double = 1, sleeve: Px) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        s.rect(18, 19, 5, 3, sleeve)
        s.rect(23, 18, 4, 5, clawdOrange)
        s.rect(26, 18, 1, 5, clawdShade)
        s.px(24, 19, clawdShade); s.px(24, 21, clawdShade)
    }
}

/// Tippy-Toe, `s` (0…1) through her visit: a hop in from the right onto Doreen's head, a sit and a tail flick, and a
/// hop back off.
private func drawTippyToe(_ c: PixelCanvas, s: Double, t: Double) {
    let ground = (x: 56.0, y: 37.0), perch = (x: 27.0, y: 14.0)
    var pos = perch
    var lift = 0.0
    if s < 0.3 {
        let f = s / 0.3
        pos = (ground.x + (perch.x - ground.x) * f, ground.y + (perch.y - ground.y) * f)
        lift = sin(f * .pi) * 8
    } else if s > 0.85 {
        let f = (s - 0.85) / 0.15
        pos = (perch.x + (ground.x - perch.x) * f, perch.y + (ground.y - perch.y) * f)
        lift = sin(f * .pi) * 8
    }
    let flick = s > 0.45 && s < 0.75 && Int(t * 8) % 2 == 0
    let brown = C(0xA06A3A), tail = C(0xC08A50), pink = C(0xF06AA0)
    c.pattern(Int(pos.x.rounded()), Int((pos.y - lift).rounded()), [
        "..pp....T" + (flick ? "T" : "."),
        ".HHH..TTT" + (flick ? "T" : "."),
        "HKHHH.TTT.",
        "HHHHHHTT..",
        ".HHHHHT...",
        ".H..H.....",
    ], ["H": brown, "T": tail, "K": ink, "p": pink])
}

// MARK: - Jeff the Land Shark

/// Jeff the Land Shark: a tiny, very good shark, blue-grey on top, white belly, a dorsal fin, a forked tail and four
/// stubby legs, with a big toothy grin. He fights by biting: the jaw drops open and he lunges. Signature: chomp chomp,
/// then his eyes go happy and a little heart floats up.
private func drawJeffTheLandShark(_ c: PixelCanvas, _ p: Pose) {
    let top = C(0x6E8EB4), dark = C(0x4A6890), belly = C(0xE8ECF2), mouth = C(0x8A2A3A)
    let sig = p.signature
    var open: Double = p.melee.map { a in max(0, 1 - abs(a - 5) / 45) } ?? 0
    if let s = sig, s < 0.45 { open = abs(sin(s / 0.45 * .pi * 2)) }
    let happy = sig.map { $0 > 0.45 } ?? false
    let lunge = p.melee != nil ? Int((2 * open).rounded()) : 0
    for (i, lx) in [21, 25, 31, 35].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx + lunge, 40, 3, lifted ? 3 : 4, dark)
    }
    c.oy += p.breathe
    c.ox += lunge
    // Tail and fin.
    c.pattern(7, 27, [
        "TT......",
        "TTT.....",
        ".TTT....",
        "..TTT...",
        "...TTTTT",
        "...TTTTT",
        "..TTT...",
        ".TTT....",
        "TTT.....",
    ], ["T": dark])
    c.pattern(24, 23, [
        "....F",
        "...FF",
        "..FFF",
        ".FFFF",
        ".FFFF",
        "FFFFF",
        "FFFFFF",
        "FFFFFFF",
    ], ["F": dark])
    // Body: blue-grey back, white belly.
    c.ellipse(29, 35, 13, 5, top)
    c.ellipse(31, 38, 10, 2, belly)
    c.rect(16, 34, 3, 2, top)
    for x in [27, 29] { c.rect(x, 34, 1, 3, dark) }        // gills
    // Eye.
    if happy {
        c.px(35, 33, ink); c.px(36, 32, ink); c.px(37, 33, ink)
    } else {
        c.rect(35, 32, 2, 2, ink); c.px(35, 32, white)
    }
    // Mouth: a grin, or the jaw dropped open.
    let o = Int((3 * open).rounded())
    if o > 0 {
        c.rect(33, 37, 9, o, mouth)
        c.rect(33, 37 + o, 9, 2, belly)
        for x in [34, 36, 38, 40] { c.px(x, 37, white); c.px(x + 1, 36 + o, white) }
    } else {
        c.px(33, 36, ink); c.rect(34, 37, 7, 1, ink); c.px(41, 36, ink)
        for x in [35, 37, 39] { c.px(x, 38, white) }
    }
    c.ox -= lunge
    if let s = sig, s > 0.45 {
        let f = (s - 0.45) / 0.55
        let y = 24 - Int(f * 8), a = f < 0.75 ? 1 : (1 - f) / 0.25
        c.pattern(37, y, [".HH.HH.", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."],
                  ["H": C(0xF04A7A, a)])
        c.px(38, y + 1, C(0xFFC0D4, a))
    }
}

// MARK: - Throg

/// Throg, the Frog of Thunder: a green frog-Clawd with big gold frog eyes and a wide mouth, under a winged silver
/// helmet, in a dark tunic with a gold belt and a red cape; he fights with Frogjolnir, a tiny hammer. Signature: a fly
/// buzzes past, his tongue snaps it up, gulp, then he raises the hammer and lightning strikes it.
private func drawThrog(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5AA83A), greenDark = C(0x3A7A26), cape = C(0xC8202A), capeDark = C(0x7A1018)
    let silver = C(0xC8CCD4), silverDark = C(0x8A8F9C), tunic = C(0x2A3050), gold = C(0xE8C02A)
    let sig = p.signature
    // A little red cape fluttering off his back.
    let flap = sin(p.t * p.capeSpeed * 1.5) > 0 ? 1 : 0
    c.oy += p.breathe
    c.pattern(10 - flap, 27, [
        "........CC",
        ".......CCC",
        "......CCCC",
        ".....CCCCc",
        "....CCCCCc",
        "...CCCCCCc",
        "..CCCCCCcc",
        ".CCCCCCcc.",
        "CCCCCCc...",
        ".cccc.....",
    ], ["C": cape, "c": capeDark])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx - (i % 2 == 0 ? 1 : 0), bottom, 3, 1, greenDark)
        }
    }
    c.oy += p.breathe
    let raise = sig.map { $0 > 0.62 && $0 < 0.97 } ?? false
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil), armRight: raise ? 4 : 0)
    // Winged helmet.
    c.pattern(19, 17, [
        "W................W",
        "WW..............WW",
        "wWW....SSSS....WWw",
        ".wWW.SSSSSSSS.WWw.",
        "..wWSSSSSSSSSSWw..",
        "...SSSSSSSSSSSS...",
        "...ssssssssssss...",
    ], ["W": C(0xF0F0F4), "w": C(0xB8BCC8), "S": silver, "s": silverDark])
    c.px(25, 20, white)
    // Big bulging frog eyes either side of the helmet: gold, with black pupils (squeezed shut as he gulps).
    let gulp = sig.map { $0 > 0.5 && $0 < 0.62 } ?? false
    for x in [16, 34] {
        c.pattern(x, 22, gulp ? [".GGGG.", "GGGGGG", "GGGGGG", "GKKKKG", "GGGGGG", "GGGGGG"]
                              : [".GGGG.", "GYYYYG", "GYYKKG", "GYYKKG", "GGYYGG", "GGGGGG"],
                  ["G": green, "Y": gold, "K": ink])
    }
    // Wide frog mouth.
    c.px(19, 32, greenDark); c.rect(20, 33, 16, 1, greenDark); c.px(36, 32, greenDark)
    // Tunic and belt.
    c.rect(18, 34, 20, 4, tunic)
    c.rect(18, 36, 20, 1, gold)
    c.rect(18, 37, 20, 1, C(0x1A1E34))
    c.rect(15, 33, 3, 3, green)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawFrogjolnir(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawFrogjolnir(c, at: Sprite.hand, angle: a)
    } else if let s = sig, raise {
        drawFrogjolnir(c, at: (41.5, 30.5), angle: -90)
        if s > 0.68 && Int(p.t * 30) % 3 != 0 {
            var prev = (x: 42.0 + (noise(Int(p.t * 20)) - 0.5) * 6, y: -2.0)
            for i in 1...3 {
                let y: Double = -2 + Double(i) * 6.5
                let next = (x: i == 3 ? 42.0 : 42 + (noise(Int(p.t * 20) + i) - 0.5) * 7, y: y)
                c.glowLine(prev.x, prev.y, next.x, next.y, core: C(0xF4F8FF), glow: C(0x7FB2FF), coreR: 0.5, glowR: 1.8)
                prev = next
            }
            drawSparks(c, x: 42, y: 21, t: p.t, size: 2.5)
        }
    } else {
        drawFrogjolnir(c, at: (41.5, seatedPose ? 30.5 : 33.5), angle: 90)
    }
    // The fly, and the tongue that catches it.
    if let s = sig, s < 0.5 {
        let tongue: Double = s > 0.3 ? sin((s - 0.3) / 0.2 * .pi) : 0
        let flyX: Double = s < 0.3 ? 62 - s / 0.3 * 12 + sin(p.t * 9) * 2 : 50
        let flyY: Double = s < 0.3 ? 25 + cos(p.t * 11) * 2 : 27
        let mouthX = 36.0, mouthY = 32.5
        let tip = (x: mouthX + (flyX - mouthX) * tongue, y: mouthY + (flyY - mouthY) * tongue)
        if tongue > 0.02 {
            c.glowLine(mouthX, mouthY, tip.x, tip.y, core: C(0xE85A7A), glow: C(0xE85A7A, 0), coreR: 0.7, glowR: 0.8)
            c.rect(Int(tip.x) - 1, Int(tip.y) - 1, 2, 2, C(0xE85A7A))
        }
        let caught = s > 0.4
        let fx = caught ? Int(tip.x) : Int(flyX), fy = caught ? Int(tip.y) : Int(flyY)
        c.px(fx, fy, C(0x1A1A22)); c.px(fx + 1, fy, C(0x1A1A22))
        if Int(p.t * 20) % 2 == 0 { c.px(fx, fy - 1, C(0xB8D0F0, 0.8)); c.px(fx + 1, fy - 1, C(0xB8D0F0, 0.8)) }
    }
}

/// Frogjolnir, a sliver of Mjolnir made frog-sized: a short handle in the hand at `at`, its head out along `angle`.
private func drawFrogjolnir(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let head = C(0xA4AAB4), light = C(0xD4D8E0), dark = C(0x6A707C)
        s.rect(18, 20, 6, 1, C(0x6A4428))
        s.px(20, 20, C(0x9A6A3A))
        s.rect(24, 18, 4, 5, head)
        s.rect(24, 18, 4, 1, light); s.rect(24, 18, 1, 5, light)
        s.rect(27, 19, 1, 4, dark); s.rect(25, 22, 3, 1, dark)
    }
}

// MARK: - Lockjaw

/// Lockjaw: the Inhumans' giant teleporting bulldog, a big blocky grey-brown body, a huge head with a jutting
/// underbite and two fangs, tiny eyes, a dark nose, folded ears and the gold tuning-fork antenna on his brow. He doesn't
/// fight. Signature: the fork glows and crackles, he vanishes in a flash and pops back in another.
private func drawLockjaw(_ c: PixelCanvas, _ p: Pose) {
    var alpha = 1.0, fork = 0.0, flash = 0.0
    if let s = p.signature {
        fork = s < 0.3 ? s / 0.3 : (s < 0.8 ? 1 : max(0, 1 - (s - 0.8) / 0.2))
        if s >= 0.3 && s < 0.38 { alpha = 1 - (s - 0.3) / 0.08 }
        else if s >= 0.38 && s < 0.62 { alpha = 0 }
        else if s >= 0.62 && s < 0.7 { alpha = (s - 0.62) / 0.08 }
        flash = max(max(0, 1 - abs(s - 0.34) / 0.07), max(0, 1 - abs(s - 0.66) / 0.07))
    }
    if alpha > 0 { layer(c, alpha: alpha) { s in drawLockjawBody(s, p, fork: fork) } }
    if flash > 0 {
        c.oy += p.breathe
        let r: Double = 4 + 14 * flash
        c.ellipse(29, 30, Int(r), Int(r * 0.85), C(0xBFE8FF, 0.25 * flash))
        c.ellipse(29, 30, Int(r * 0.55), Int(r * 0.5), C(0xF4FCFF, 0.5 * flash))
        for i in 0..<8 {
            let a: Double = Double(i) * .pi / 4 + 0.3
            c.glowLine(29 + cos(a) * r * 0.7, 30 + sin(a) * r * 0.6, 29 + cos(a) * (r + 3), 30 + sin(a) * (r * 0.85 + 2),
                       core: C(0xF4FCFF, flash), glow: C(0x7FC8FF, flash), coreR: 0.4, glowR: 1.3)
        }
    } else if alpha == 0 {
        // Gone: a few sparkles where he was.
        let i = Int(p.t * 20)
        for k in 0..<4 {
            c.px(14 + Int(noise(i + k * 3) * 32), 20 + Int(noise(i + k * 7 + 1) * 20), C(0xBFE8FF, 0.8))
        }
    }
}

private func drawLockjawBody(_ c: PixelCanvas, _ p: Pose, fork: Double) {
    let coat = C(0x9A8670), coatDark = C(0x6E5C48), coatLight = C(0xB8A48C), muzzle = C(0x7A6A58)
    let gold = C(0xE8C02A), goldDark = C(0xB08A1A)
    // Legs: thick and stubby; folded flat when he sits.
    if seatedPose {
        for lx in [11, 17, 30, 37] { c.rect(lx - 1, 38, 6, 2, coat); c.rect(lx + 3, 39, 2, 1, coatDark) }
    } else {
        for (i, lx) in [11, 17, 30, 37].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            let w = i < 2 ? 4 : 5                       // front legs thicker, bulldog-bowed
            c.rect(lx, 36, w, lifted ? 6 : 7, coat)
            c.rect(lx + w - 1, 36, 1, lifted ? 6 : 7, coatDark)
            c.rect(lx, lifted ? 41 : 42, w + 1, 1, coatDark)
            if i >= 2 { c.px(lx + 2, lifted ? 41 : 42, coat) }
        }
    }
    c.oy += p.breathe
    // Tail stub and the big blocky body, broad at the shoulders.
    c.rect(6, 26, 4, 2, coat); c.px(6, 26, coatDark)
    c.rect(9, 26, 24, 13, coat)
    c.rect(10, 25, 22, 1, coat)
    c.rect(24, 23, 10, 3, coat)
    c.rect(30, 28, 13, 11, coat); c.rect(32, 33, 9, 4, coatLight)       // a deep chest under the head
    c.rect(9, 38, 34, 1, coatDark)
    for (x, y) in [(12, 28), (16, 31), (13, 34), (20, 28), (24, 34), (27, 30), (19, 36)] as [(Int, Int)] { c.px(x, y, coatDark) }
    // Head, turned to face us: a great wide skull with a wrinkled brow, a flat pug nose, heavy jowls either side and
    // an underbite showing two fangs.
    c.pattern(29, 16, [
        "..EEE.HHHHHHHHHH.EEE..",
        ".EEEEHHHHHHHHHHHHEEEE.",
        ".EEHHHHHwHHHHwHHHHHEE.",
        "..HHHHHHHwHHwHHHHHHH..",
        ".HHHHwwHHHHHHHHwwHHHH.",
        ".HHHKKHHHHHHHHHHKKHHH.",
        "HHHHKKHHHMMMMHHHKKHHHH",
        "HHHHHHHHMMNNNNMMHHHHHH",
        "HHHHHHHMMMNNNNMMMHHHHH",
        "HHHHHJJMMMMwwMMMMJJHHH",
        "HHHHJJJJJJJJJJJJJJJJHH",
        "HHHJJJJJFLLLLLLFJJJJJH",
        ".HJJJJJJFLLLLLLFJJJJJ.",
        ".JJJJJJ.LLLLLLLL.JJJJ.",
        "..JJJJ...dddddd...JJ..",
    ], ["H": coat, "E": coatDark, "w": coatDark, "K": ink, "M": muzzle, "N": C(0x1A1A22), "J": C(0x5A4A3A),
        "L": coatLight, "d": coatDark, "F": C(0xF4F0E0)])
    c.px(33, 21, white.alpha(0.6)); c.px(45, 21, white.alpha(0.6))
    // The tuning fork on his brow.
    let g = fork > 0.1 ? C(0xFFF0A0) : gold
    c.rect(39, 13, 1, 3, goldDark)
    c.rect(37, 12, 5, 1, g)
    c.rect(37, 9, 1, 3, g); c.rect(41, 9, 1, 3, g)
    if fork > 0.1 {
        let a: Double = 0.6 + 0.4 * sin(p.t * 30)
        c.glowLine(37.5, 9.5, 37.5, 11.5, core: C(0xF4FCFF, fork * a), glow: C(0x7FC8FF, fork * a), coreR: 0.5, glowR: 1.8)
        c.glowLine(41.5, 9.5, 41.5, 11.5, core: C(0xF4FCFF, fork * a), glow: C(0x7FC8FF, fork * a), coreR: 0.5, glowR: 1.8)
        let i = Int(p.t * 20)
        c.px(36 + Int(noise(i) * 7), 6 + Int(noise(i + 1) * 4), C(0xBFE8FF, fork))
    }
}

// MARK: - Forbush Man

/// Forbush Man, Not Brand Echh's "hero": a dented cooking pot jammed on his head with two eye holes and the handle
/// sticking out the back, and red long johns with a big "F" on the chest. Unarmed and not much use. Signature: the pot
/// slips down over his eyes, he staggers about blind (?), then shoves it back up.
private func drawForbushMan(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A1218), pot = C(0x9AA0AC), potDark = C(0x6A707C), potLight = C(0xD0D4DC)
    let sig = p.signature
    let slip: Double = sig.map { s in
        if s < 0.12 { return 0 }
        if s < 0.22 { return (s - 0.12) / 0.1 }
        if s < 0.78 { return 1 }
        if s < 0.86 { return 1 - (s - 0.78) / 0.08 }
        return 0
    } ?? 0
    let blind = slip > 0.9
    let pushing = sig.map { $0 > 0.7 && $0 < 0.9 } ?? false
    let stagger = blind ? (sin(p.t * 7) > 0 ? 1 : -1) : 0
    c.ox += stagger
    drawLegs(c, Look(leg: red), step: blind ? Int(p.t * 6) % 2 : p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: redDark, arm: red, eye: nil), armRight: pushing ? 6 : 0)
    // The eyes under the pot (only seen through the holes).
    let dy = Int((3 * slip).rounded())
    c.rect(22, 26, 2, 2, ink); c.rect(32, 26, 2, 2, ink)
    // The pot, upside down: handle out the back, a rolled rim, two eye holes.
    c.rect(4, 23 + dy, 14, 2, potDark); c.rect(4, 23 + dy, 14, 1, pot); c.rect(3, 23 + dy, 2, 2, C(0x3A3A44))
    c.pattern(17, 18 + dy, [
        "..ppppppppppppppppppp.",
        ".PlPPPPPPPPPPPPPPPPPp.",
        ".PlPPPPPPPPPPPPPPPPPp.",
        ".PlPPPPPPPPPPPPPPPPPp.",
        ".PlPPPPPPPPPPPPPPPPPp.",
        ".PlPPPPPPPPPPPPPPPPPp.",
        ".PlPPPPPPPPPPPPPPPPPp.",
        ".PPPPPPPPPPPPPPPPPPPp.",
        ".PPPPPPPPPPPPPPPPPPPp.",
        "RRRRRRRRRRRRRRRRRRRRRR",
        "pppppppppppppppppppppp",
    ], ["P": pot, "p": potDark, "l": potLight, "R": potLight])
    c.px(30, 19 + dy, potDark); c.px(31, 20 + dy, potDark)            // a dent
    for x in [21, 31] {
        c.rect(x, 25 + dy, 4, 3, C(0x1A1A22))
        if dy == 0 { c.rect(x + 1, 26, 2, 2, C(0xF4E8C8)); c.px(x + 2, 26, ink); c.px(x + 2, 27, ink) }
    }
    // Long johns: the big F, a row of buttons.
    c.pattern(25, 30 + max(0, dy - 1), ["FFFF", "F...", "FFF.", "F...", "F..."], ["F": C(0xF4F0E0)])
    c.rect(18, 37, 20, 1, redDark)
    if blind && !pushing {
        let q = C(0xF4F0E0)
        c.pattern(39, 14, [".qq.", "q..q", "...q", "..q.", "....", "..q."], ["q": q])
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

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, turned to light by
/// `tint` (0…1: darks go sky blue, lights go white), and leaning forward one pixel every `lean` rows above the feet
/// (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, tint: Double? = nil, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            var col = unpremultiplied(s, i)
            if let k = tint {
                let lum: Double = (0.3 * Double(col.r) + 0.59 * Double(col.g) + 0.11 * Double(col.b)) / 255
                col = mix(col, lum < 0.3 ? C(0x8ACDFF) : (lum < 0.6 ? C(0xC8E8FF) : C(0xF8FCFF)), k)
            }
            c.px(x + shift, y, col.alpha(alpha))
        }
    }
}

/// `a` washed towards `b` by `k` (0…1), keeping `a`'s opacity.
private func mix(_ a: Px, _ b: Px, _ k: Double) -> Px {
    let r: Double = Double(a.r) + (Double(b.r) - Double(a.r)) * k
    let g: Double = Double(a.g) + (Double(b.g) - Double(a.g)) * k
    let bl: Double = Double(a.b) + (Double(b.b) - Double(a.b)) * k
    return Px(r: UInt8(r), g: UInt8(g), b: UInt8(bl), a: a.a)
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
