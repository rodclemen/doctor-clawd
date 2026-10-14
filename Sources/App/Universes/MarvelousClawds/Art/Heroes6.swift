import Foundation

// Heroes: Kamar-Taj, the cosmos and the younger X-Men. Each one is Clawd in costume (Cosmo is a dog in a spacesuit,
// but she keeps Clawd's block of a body and its four legs).

let heroes6: [MarvelHero: Persona] = [
    .wong: Persona(name: "Wonk", weapon: .lightning, magic: Magic(core: C(0xFFE8B0), glow: C(0xFF8A1E), jagged: false),
                  headTop: 22, signature: 3.2,
                  draw: drawWong),
    .hercules: Persona(name: "Herakles", weapon: .saber, bulk: 1, headTop: 18, signature: 2.8,
                  draw: drawHercules),
    .sentry: Persona(name: "Sentree", weapon: .saber, motion: .fly, headTop: 20, signature: 3.2,
                  draw: drawSentry),
    .cosmo: Persona(name: "Kosmo the Space Dog", weapon: .lightning, magic: Magic(core: C(0xF0E8FF), glow: C(0xA08AFF), jagged: false),
                  pivot: (44.5, 21.5), bulk: 3, headTop: 15, signature: 2.8,
                  draw: drawCosmo),
    .kraglin: Persona(name: "Kraglen", weapon: .blaster, shot: .energy(core: C(0xFFE0E0), glow: C(0xFF4A2A)),
                  muzzle: (49, 31.5), headTop: 18, signature: 3.4,
                  draw: drawKraglin),
    .adamWarlock: Persona(name: "Adam Warlocke", weapon: .lightning, motion: .fly, magic: Magic(core: C(0xFFF6D0), glow: C(0xFFC81E), jagged: false),
                  headTop: 20, signature: 3.2,
                  draw: drawAdamWarlock),
    .nova: Persona(name: "Novah", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFF6D0), glow: C(0xFFC81E)),
                  muzzle: (43, 34), handGun: false, headTop: 15, signature: 2.6,
                  draw: drawNova),
    .kittyPryde: Persona(name: "Kitty Pride", weapon: .saber, headTop: 13, signature: 2.8,
                  draw: drawKittyPryde),
    .jubilee: Persona(name: "Jubilette", weapon: .blaster, shot: .energy(core: C(0xFFF0FF), glow: C(0xFF5AC8)),
                  muzzle: (43, 34), handGun: false, headTop: 20, signature: 3.0,
                  draw: drawJubilee),
    .psylocke: Persona(name: "Psyloque", weapon: .saber, headTop: 20, signature: 3.0,
                  draw: drawPsylocke),
]

// MARK: - Wong

/// Wong: a bald Clawd with stern brows in the dark Kamar-Taj robes, a tan under-robe in the V of the crossed collar
/// and an orange sash; the robe falls to his knees. Casting, an orange mandala shield spins round his raised hand.
/// Signature: headphones on, eyes shut, he nods along to the music while little notes float up.
private func drawWong(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x5A2A22), robeDark = C(0x3C1A16), under = C(0xC89A5A), sash = C(0xE08A1E), sashDark = C(0xA85E12)
    let gold = C(0xE8B530), brow = C(0x3A2416)
    let music = p.signature.map { habitArc($0, hold: 0.8) } ?? 0
    let nod = music > 0.5 && sin(p.lt * 2 * .pi * 2.2) > 0 ? 1 : 0
    drawLegs(c, Look(leg: C(0x2A1C18)), step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 2)
    c.oy += p.breathe
    // The robe's skirt, down over the knees, with the sash ends hanging in front.
    let hem = seatedPose ? 1 : 3
    c.rect(17, 37, 22, hem + 1, robe)
    c.rect(17, 37 + hem, 22, 1, robeDark)
    c.rect(32, 37, 2, hem + 1, sash); c.rect(33, 37, 1, hem + 1, sashDark)
    c.oy += nod
    drawBody(c, Look(arm: robe, eye: nil), armRight: p.armRaise)
    // The bald dome.
    c.pattern(18, 23, [
        "....SSSSSSSSSSSS....",
        "..SSLLSSSSSSSSSSss..",
        ".SSLSSSSSSSSSSSSSSs.",
    ], ["S": clawdOrange, "L": C(0xF0A07A), "s": clawdShade])
    if music > 0.5 {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)          // eyes shut, enjoying it
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.rect(21, 27, 3, 1, brow); c.rect(32, 27, 3, 1, brow)
    }
    c.pattern(18, 32, [
        "RRRRRGuuuuuuuuGRRRRr",
        "RRRRRRGuuuuuuGRRRRRr",
        "RRRRRRRGuuuuGRRRRRRr",
        "RRRRRRRRGuuGRRRRRRRr",
        "OOOOOOOOOOOOOOOOOOOo",
        "rrrrrrrrrrrrrrrrrrrr",
    ], ["R": robe, "r": robeDark, "u": under, "G": gold, "O": sash, "o": sashDark])
    c.rect(15, 35, 3, 1, gold)                                      // sleeve cuffs
    c.rect(38, 35 - p.armRaise, 3, 1, gold)
    if music > 0.05 {
        // Headphones: the band over his dome, a cup on each side.
        let band = C(0xA8ACB8), cup = C(0xD8303A), pad = C(0x2A2A30)
        c.pattern(17, 22, [
            ".......BBBBBBBB.......",
            ".....BB........BB.....",
            "...BB............BB...",
            "..B................B..",
            ".B..................B.",
        ], ["B": band])
        for x in [16, 37] { c.rect(x, 27, 3, 5, cup); c.rect(x + (x < 20 ? 2 : 0), 28, 1, 3, pad) }
        let clock = p.lt * 0.5 + (p.signature ?? 0) * 3
        for i in 0..<3 {
            let f = frac(clock + Double(i) / 3)
            let x = 41 + i * 2 + Int((sin(f * 6 + Double(i)) * 1.5).rounded()), y = 28 - Int(f * 14)
            drawNote(c, x, y, (i % 2 == 0 ? C(0xFFD25A) : C(0xFF9A3A)).alpha(0.95 * music * (1 - f * f)))
        }
    }
    if p.zap != nil {
        drawMandala(c, at: (Sprite.hand.x, Sprite.hand.y - Double(p.armRaise)), r: 4.5, t: p.t,
                    core: C(0xFFE8B0), glow: C(0xFF8A1E))
    }
}

// MARK: - Hercules

/// Hercules: the comic-book Prince of Power, Clawd with a mop of black curls and a big curly beard, bare-chested over
/// a gold belt and the blue-and-gold Greek war skirt, gold armbands and laced sandals. His golden mace rests on his
/// shoulder and swings from the hand. Signature: the mace goes down and he flexes both arms, biceps pumping, with a
/// twinkle.
private func drawHercules(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x1A1A22), curl = C(0x3A3A48), blue = C(0x2A4FA0), blueDark = C(0x1C3878)
    let gold = C(0xE8B530), goldDark = C(0xB0841E), sandal = C(0x6A4428)
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, b, 2, 1, sandal); c.rect(lx, b - 2, 2, 1, sandal)
        }
    }
    c.oy += p.breathe
    let flex = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawBody(c, Look())
    // The Greek skirt: blue and gold strips below the belt.
    let strips = seatedPose ? 1 : 3
    for i in 0..<11 {
        let x = 17 + i * 2
        c.rect(x, 38, 2, strips, i % 2 == 0 ? blue : gold)
        c.px(x + 1, 38 + strips - 1, i % 2 == 0 ? blueDark : goldDark)
    }
    c.rect(18, 37, 20, 1, gold); c.rect(27, 37, 2, 1, C(0xFFE27A))
    // Curls on top, running down into the beard.
    c.pattern(16, 19, [
        "......HH.HHH.HH.HHH.....",
        "....HHHHHHHHHHHHHHHHHH..",
        "...HHcHHHcHHHHcHHHcHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHHH",
        "..HHcHHHHcHHHHHcHHHcHHHH",
        ".HHHHHHHHHHHHHHHHHHHHHHH",
        ".HHHH.H..H..H..H..H.HHHH",
        "..HHH..............HHHH.",
        "..HH................HH..",
        "..HH................HH..",
        "..HH................HH..",
        "..HHH..............HHH..",
        "...HHHH..HHHHHH..HHHH...",
        "...HHcHHHH....HHHHcHH...",
        "....HHHHHHcHHHHcHHHH....",
        ".....HHcHHHHHcHHHHH.....",
        ".......HHHHHHHHHH.......",
    ], ["H": hair, "c": curl])
    c.rect(18, 36, 3, 1, clawdShade); c.rect(35, 36, 3, 1, clawdShade)

    if flex > 0.3 {
        let pump = sin(p.t * 9) > 0 ? 1 : 0
        drawMace(c, at: (45.5, 30.5), angle: 90)
        drawFlexArm(c, left: false, pump: pump, skin: clawdOrange, shade: clawdShade, band: gold)
        drawFlexArm(c, left: true, pump: pump, skin: clawdOrange, shade: clawdShade, band: gold)
        if flex > 0.9 { twinkle(c, 45, 25 - pump, C(0xFFE27A)) }
        return
    }
    c.rect(15, 33, 3, 1, gold); c.rect(38, 33, 3, 1, gold)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawMace(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawMace(c, at: Sprite.hand, angle: a)
    } else {
        drawMace(c, at: Sprite.hand, angle: seatedPose ? -100 : -118)            // resting on his shoulder
    }
}

/// Hercules' mace, its handle in the hand at `at` and the spiked golden head out along `angle` degrees.
private func drawMace(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let wood = C(0x7A4A24), gold = C(0xE8B530), goldDark = C(0xB0841E), light = C(0xFFE27A), spike = C(0xC8CCD4)
        s.rect(17, 20, 10, 1, wood)
        s.px(19, 20, gold); s.px(21, 20, gold)
        s.rect(15, 19, 2, 3, gold)
        s.pattern(26, 16, [
            "...SS...",
            "..GGGG..",
            ".GLLGGg.",
            "SGLGGGgS",
            "SGGGGGgS",
            ".GGGGgg.",
            "..gggg..",
            "...SS...",
        ], ["G": gold, "g": goldDark, "L": light, "S": spike])
    }
}

/// One of Hercules' arms flexed up, bicep bulging (`pump` adds a pixel to it).
private func drawFlexArm(_ c: PixelCanvas, left: Bool, pump: Int, skin: Px, shade: Px, band: Px) {
    var rows = [
        "...FFF.",
        "..FFFFF",
        "..FFFFF",
        "...AAA.",
        "...AAA.",
        "..AAAs.",
        pump > 0 ? "AAAAAAs" : ".AAAAs.",
        "AAAAAAs",
        "BBBBBs.",
        "AAAs...",
        "AAs....",
    ]
    if left { rows = rows.map { String($0.reversed()) } }
    c.pattern(left ? 11 : 38, 23, rows, ["F": skin, "A": skin, "s": shade, "B": band])
}

// MARK: - Sentry

/// Sentry: Clawd with neat swept blond hair in the golden suit with the blue "S" on the chest, blue gloves, boots and
/// belt and a long blue cape; he fights with his fists and flies leaning into it, cape streaming. Signature: a golden
/// glow flares round him, rays and all, then for a moment it all goes dark (the Void, eyes burning) and the light
/// comes back.
private func drawSentry(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let flare = s >= 0 ? (s < 0.55 ? habitArc(min(1, s / 0.55 * 0.5), hold: 0) : (s > 0.8 ? 1 - (s - 0.8) / 0.2 : 1)) : 0
    let void = s > 0.58 && s < 0.8 && Int(p.t * 14) % 5 != 0
    if flare > 0.05 && !void {
        for i in 0..<14 {
            let a = Double(i) / 14 * 2 * .pi + p.t * 0.6
            let r0: Double = 12, r1: Double = 12 + (4 + noise(i * 7 + Int(p.t * 8)) * 3) * flare
            c.glowLine(28 + cos(a) * r0, 31 + sin(a) * r0 * 0.8, 28 + cos(a) * r1, 31 + sin(a) * r1 * 0.8,
                       core: C(0xFFF6C8).alpha(0.8 * flare), glow: C(0xFFC81E).alpha(0.7 * flare), coreR: 0.4, glowR: 1.4)
        }
    }
    layer(c, lean: p.flying ? 4 : 0) { c in drawSentryBody(c, p) }
    if void {
        wash(c, C(0x0E0A18), 0.85)
        c.oy += p.breathe
        c.rect(22, 29, 2, 3, C(0xFF4A2A)); c.rect(32, 29, 2, 3, C(0xFF4A2A))
        for i in 0..<5 {
            let a = Double(i) * 1.3 + p.t * 2
            let x0 = 28 + cos(a) * 9, y0 = 31 + sin(a) * 6
            c.glowLine(x0, y0, x0 + cos(a) * 6 + sin(p.t * 9 + Double(i)) * 2, y0 + sin(a) * 5,
                       core: C(0x2A1A3A, 0.8), glow: C(0x1A0E2A, 0.6), coreR: 0.6, glowR: 1.6)
        }
    } else if flare > 0.05 {
        wash(c, C(0xFFE27A), 0.3 * flare)
    }
}

private func drawSentryBody(_ c: PixelCanvas, _ p: Pose) {
    let gold = C(0xE8C02A), goldDark = C(0xB8901A), blue = C(0x2A3A9A), blueDark = C(0x1C2870)
    let hair = C(0xF4DC7A), hairDark = C(0xC0A048)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: blue, edge: blueDark)
        for lx in [21, 31] { c.rect(lx, 36, 4, 5, gold); c.rect(lx, 39, 4, 2, blue); c.rect(lx + 3, 36, 1, 3, goldDark) }
    } else {
        drawCape(c, t: p.t, speed: p.capeSpeed, color: blue, edge: blueDark)
        drawLegs(c, Look(leg: gold), step: p.step)
        drawBoots(c, blue, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: gold))
    c.pattern(17, 21, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHhhHHHHHH..",
        "..HHHHHHHHHhSShHHHHHH.",
        ".HHHHHHHHHhSSSSShHHHH.",
        ".HHHh.............hHH.",
        ".HH................hH.",
    ], ["H": hair, "h": hairDark, "S": clawdOrange])
    c.rect(18, 33, 20, 5, gold)
    c.rect(37, 33, 1, 5, goldDark)
    c.pattern(25, 33, [".BBBB", "B....", ".BBB.", "....B", "BBBB."], ["B": blue])
    c.rect(18, 37, 20, 1, blueDark)
    c.rect(15, 33, 3, 3, blue)
    if p.flying {
        c.rect(38, 31, 4, 3, blue)
        return
    }
    if let a = p.melee {
        drawPunch(c, angle: a, trail: p.trail, arm: gold, fist: blue)
    } else {
        c.rect(38, 33, 3, 3, blue)
    }
}

// MARK: - Cosmo

/// Cosmo the Spacedog: a golden retriever in a red cosmonaut suit (Clawd's block of a body on Clawd's four legs, with
/// golden paws), her head out front under the white helmet with "CCCP" in red, a floppy ear and a black nose, and a
/// fluffy tail behind. Her telekinesis glows lavender from her head. Signature: tail going like mad, tongue out,
/// and up float a heart and a sparkle, good dog.
private func drawCosmo(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xD8A048), furDark = C(0xA8742A), furLight = C(0xF0CC80), suit = C(0xC8282A), suitDark = C(0x8A1418)
    let helm = C(0xE2E4EA), helmDark = C(0xA8ACB8), letters = C(0xC8202A)
    let tk = (core: C(0xF0E8FF), glow: C(0xA08AFF))
    let happy = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, fur, step: p.step, rows: 2)
    c.oy += p.breathe
    // The tail, wagging.
    let fast = happy > 0.1 || p.cheering
    let wag = sin(p.lt * (fast ? 24 : (p.walking ? 10 : 4))) * (fast ? 32 : 14)
    let ta = (-150 + wag) * .pi / 180
    let tx = 18.5 + cos(ta) * 7, ty = 29.0 + sin(ta) * 7
    bar(c, 18.5, 29.5, tx, ty, fur, 1.4)
    bar(c, 18.5 + cos(ta) * 4, 29.5 + sin(ta) * 4, tx, ty, furLight, 0.7)
    // The suit.
    c.rect(18, 26, 20, 12, suit)
    c.rect(18, 37, 20, 1, suitDark)
    c.rect(18, 31, 14, 1, helmDark)                                 // harness strap
    c.rect(22, 32, 4, 3, helmDark); c.rect(23, 33, 2, 1, letters)   // a patch
    // Head under the helmet.
    c.pattern(30, 15, [
        "....WWWWWWW......",
        "..WWWWWWWWWWW....",
        ".WWWWWWWWWWWWW...",
        ".WWWWWWWWWWWWWw..",
        "WWWWWWWWWWWWWWw..",
        "WWWWWWWWWWWWWWw..",
        "wwwwwwwwwwwwwww..",
        "EEFFFFFFFFFFFl...",
        "EEFFFFFFFFFFFFl..",
        "EEEFFFFFFFFFFFFFF",
        "EEEFFFFFFFFFFFFNN",
        "EEEFFFFFFFFFFFFNN",
        ".EEFFFFFFFFFmmmm.",
        ".EE.FFFFFFFFFFF..",
        "...FFFFFFFFFF....",
        "..CCCCCCCCCCC....",
    ], ["W": helm, "w": helmDark, "E": furDark, "F": fur, "l": furLight, "N": ink, "m": furDark, "C": helmDark])
    c.pattern(33, 18, ["RR.RR.RR.RR", "R..R..R..RR", "RR.RR.RR.R."], ["R": letters])
    let glowing = p.zap != nil
    c.rect(38, 23, 2, 2, glowing ? tk.core : ink)
    if glowing {
        c.glowLine(39, 23.5, 39, 23.5, core: tk.core, glow: tk.glow, coreR: 0.6, glowR: 2.2)
        c.glowLine(Double(44.5), 21.5 - Double(p.armRaise), 44.5, 21.5 - Double(p.armRaise), core: tk.core, glow: tk.glow,
                   coreR: 0.6, glowR: 2)
    }
    if happy > 0.2 || p.walking || p.cheering {
        c.rect(42, 28, 2, 2, C(0xE8607A)); c.px(43, 29, C(0xC8405A))       // tongue out
    }
    if happy > 0.05 {
        let f = frac((p.signature ?? 0) * 1.6)
        let hx = 37, hy = 11 - Int(f * 6)
        c.pattern(hx, hy, ["HH.HH", "HHHHH", ".HHH.", "..H.."], ["H": C(0xFF4A7A).alpha(0.95 * happy)])
        twinkle(c, 46, 13 - Int(f * 4), C(0xFFE27A).alpha(happy))
    }
}

// MARK: - Kraglin

/// Kraglin: a scrawny Clawd in the red-brown Ravager leathers, a bandolier across the coat and the Ravager badge on
/// the chest, thin receding hair, a droopy moustache and the little red fin he inherited from Yondu; a Ravager
/// blaster in his hand. Signature: the blaster goes in its holster, he whistles, and Yondu's yaka arrow rises and
/// wobbles shakily in the air in front of him before swooping back.
private func drawKraglin(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x8A2A22), coatDark = C(0x5A1814), shirt = C(0x3A3438), hair = C(0x5A3A22), fin = C(0xC8302A)
    let finDark = C(0x8A1A14), metal = C(0x8A8F9C)
    drawLegs(c, Look(leg: C(0x3A3438)), step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 2)
    c.oy += p.breathe
    // Coat tails.
    if !seatedPose {
        c.rect(16, 37, 6, 4, coat); c.rect(16, 40, 6, 1, coatDark)
        c.rect(34, 37, 5, 3, coat); c.rect(34, 39, 5, 1, coatDark)
    }
    drawBody(c, Look(arm: coat))
    c.pattern(22, 16, [
        "F.........",
        "FfF.......",
        "FfFfF.....",
        "FfFfFfF...",
        "FfFfFfFfF.",
        "FfFfFfFfFf",
        "MMMMMMMMMMM",
    ], ["F": fin, "f": finDark, "M": metal])
    c.pattern(18, 24, [
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHH........HHHHH.",
        "HHH..............HHH",
        "HH................HH",
        "H..................H",
    ], ["H": hair])
    let sig = p.signature ?? -1
    let whistle = sig > 0.05 && sig < 0.95
    // The coat over a dark shirt, the Ravager flame on the chest.
    c.pattern(18, 33, [
        "CCCCCCCCCCCCCSSCCCCc",
        "CCCCCCCCCCCCSSCCCCCc",
        "CCCCCCCCCCCSSCCCCCCc",
        "CCCCCCCCCCSSCCCCCCCc",
        "ccccccccccccccccccc.",
    ], ["C": coat, "c": coatDark, "S": shirt])
    c.pattern(20, 34, [".m.", "mmm", ".m."], ["m": metal])
    // The moustache, droopy; puckered to whistle.
    c.pattern(23, 32, ["HHHHHHHHHH", "H........H", "H........H"], ["H": hair])
    if whistle { c.rect(27, 33, 2, 2, C(0x5A2A1E)) }
    c.rect(18, 37, 20, 1, C(0x1A1A1E)); c.px(28, 37, metal)          // belt and buckle
    c.rect(15, 33, 3, 3, coat)
    if whistle {
        c.rect(36, 35, 3, 3, shirt)                                 // holstered
        let a = sig < 0.25 ? (sig - 0.05) / 0.2 : (sig > 0.8 ? (0.95 - sig) / 0.15 : 1)
        let k = p.t + sig * 3.4
        let hx = 47 + sin(k * 3.1) * 4 + (noise(Int(k * 9)) - 0.5) * 2
        let hy = 22 + sin(k * 5.3) * 3
        let x = 30 + (hx - 30) * a, y = 37 + (hy - 37) * a
        let ang = a < 0.99 ? -90 * (1 - a) : sin(k * 7) * 40 + (noise(Int(k * 6)) - 0.5) * 30
        drawYaka(c, x: x, y: y, angle: ang, t: p.t)
        for i in 0..<2 {
            let f = frac(k * 0.8 + Double(i) / 2)
            drawNote(c, 37 + i * 3 + Int(f * 4), 28 - Int(f * 10), C(0xFFD0C8).alpha(0.95 * (1 - f * f)))
        }
        return
    }
    // The blaster.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, coat)
    c.pattern(38, 31, [
        "..KKKKKKKKK",
        "GGKKRRKKKKK",
        "GGKK.......",
        "..KK.......",
    ], ["K": C(0x2A2A30), "R": C(0xC8302A), "G": metal])
}

/// Yondu's yaka arrow, glowing red, centred on (`x`, `y`) and pointing along `angle` degrees.
private func drawYaka(_ c: PixelCanvas, x: Double, y: Double, angle: Double, t: Double) {
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(x - ux * 4, y - uy * 4, x + ux * 3, y + uy * 3, core: C(0xFF8A7A), glow: C(0xFF2A1A, 0.8), coreR: 0.5,
               glowR: 1.6 + 0.3 * sin(t * 30))
    c.px(Int((x + ux * 4).rounded()), Int((y + uy * 4).rounded()), C(0xFFE0E0, 0.9))
    for side in [-1.0, 1.0] {
        c.px(Int((x - ux * 4 - uy * side * 1.5).rounded()), Int((y - uy * 4 + ux * side * 1.5).rounded()), C(0xC8302A, 0.9))
    }
}

// MARK: - Adam Warlock

/// Adam Warlock: Clawd with golden skin and pale blond hair, the green Soul Gem in his brow, the red tunic with its
/// black lightning-bolt collar edged in yellow, and a dark red cape; he flies and casts golden energy, the gem
/// glowing. Signature: a golden cocoon weaves up round him from the feet, pulses, then cracks open and he's back.
private func drawAdamWarlock(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 4 : 0) { c in drawWarlockBody(c, p) }
    guard let s = p.signature, s > 0.02 else { return }
    c.oy += p.breathe
    let gold = C(0xE8B040), vein = C(0xB07A20), light = C(0xFFE890)
    let grow = min(1, s / 0.28), open = s > 0.72 ? (s - 0.72) / 0.28 : 0
    let pulse = 0.5 + 0.5 * sin(p.t * 12)
    let alpha = (1 - open) * (s > 0.28 && s < 0.72 && Int(p.t * 20) % 7 == 0 ? 0.8 : 1)
    let top = 43 - Int((Double(43 - 16) * grow).rounded())
    for y in max(16, top)...43 {
        let k = (Double(y) - 30) / 14
        guard abs(k) < 1 else { continue }
        let hw = Int((13 * sqrt(1 - k * k)).rounded())
        guard hw > 0 else { continue }
        for x in (28 - hw)...(27 + hw) {
            let d = Double(x - 28) / Double(hw)
            var col = gold
            if (x + y * 2) % 7 == 0 || abs(d) > 0.85 { col = vein }
            if d < -0.4 && d > -0.6 && y < 34 { col = light }
            c.px(x, y, col.alpha(alpha))
        }
    }
    if s > 0.28 && s < 0.72 {
        c.glowLine(28, 22, 28, 40, core: light.alpha(0.5 * pulse), glow: C(0xFFC81E).alpha(0.4 * pulse), coreR: 0.5, glowR: 3)
    }
    if open > 0 {
        // The crack, bright light spilling out.
        var prev = (x: 28.0, y: 16.0)
        for i in 1...6 {
            let q = (x: 28 + (i % 2 == 0 ? -1.5 : 1.5), y: 16 + Double(i) * 4.5)
            c.glowLine(prev.x, prev.y, q.x, q.y, core: C(0xFFFBE8).alpha(1 - open), glow: C(0xFFC81E).alpha(1 - open),
                       coreR: 0.5 + open, glowR: 2 + open * 3)
            prev = q
        }
    }
}

private func drawWarlockBody(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE0A030), skinDark = C(0xB07A1E), red = C(0xB8202A), redDark = C(0x7A1018)
    let cape = C(0x8A1420), capeEdge = C(0xE8B530), hair = C(0xF8E890), hairDark = C(0xC8B058)
    let bolt = C(0x1A1A22), yellow = C(0xF4D040)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: cape, edge: capeEdge)
        for lx in [21, 31] { c.rect(lx, 36, 4, 5, red); c.rect(lx + 3, 36, 1, 5, redDark); c.rect(lx, 40, 4, 1, redDark) }
    } else {
        drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge)
        drawLegs(c, Look(leg: red), step: p.step)
        drawBoots(c, redDark, step: p.step, rows: 2)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: red), armRight: p.flying ? 0 : p.armRaise)
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHhHHHHHHHHHHhHHHHH..",
        "..HHHHHH........HHHHHH..",
        ".HHHHh............hHHHH.",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HH..................HH.",
        ".Hh..................hH.",
    ], ["H": hair, "h": hairDark])
    let glowing = p.zap != nil || p.flying
    c.pattern(27, 26, ["GG", "Gg"], ["G": glowing ? C(0x9AFFAA) : C(0x3AC85A), "g": C(0x1E7A34)])
    if glowing { c.glowLine(28, 27, 28, 27, core: C(0xD8FFE0), glow: C(0x3AE85A), coreR: 0.5, glowR: 2) }
    c.pattern(18, 32, [
        "YRRRRRRRRRRRRRRRRRRY",
        "KYRRRYRRRRRRRRYRRRYK",
        "RKYRYKYRRRRRRYKYRYKR",
        "RRKYKRKYRRRRYKRKYKRr",
        "RRRKRRRKYRRYKRRRKRRr",
        "rrrrrrrrKYYKrrrrrrrr",
    ], ["K": bolt, "Y": yellow, "R": red, "r": redDark])
    c.rect(15, 33, 3, 3, red)
    if p.flying {
        c.rect(38, 31, 4, 3, red)
        c.glowLine(42, 32, 42, 32, core: C(0xFFF6D0), glow: C(0xFFC81E), coreR: 0.5, glowR: 1.8)
        return
    }
    if p.zap != nil {
        c.glowLine(41.5, 34.5 - Double(p.armRaise), 41.5, 34.5 - Double(p.armRaise), core: C(0xFFF6D0), glow: C(0xFFC81E),
                   coreR: 0.7, glowR: 2.4)
    }
}

// MARK: - Nova

/// Nova (Richard Rider): Clawd under the gold Nova Corps helmet with its three-finned crest, a dark visor with
/// glowing eye slits and gold cheek plates, the dark blue suit with gold shoulders and a gold star; gold gloves, the
/// right fist glowing for his blasts. In flight he punches forward and leaves a golden cosmic trail. Signature: a
/// gleam runs over the helmet and the visor glints.
private func drawNova(_ c: PixelCanvas, _ p: Pose) {
    if p.flying {
        // The cosmic trail: a golden comet tail thinning out behind him.
        for k in 0..<6 {
            let x0 = 18.0 - Double(k) * 3, x1 = x0 - 3
            let y0 = 33.0 + Double(k) * 0.9 + sin(p.t * 8 - Double(k)) * 0.6, y1 = y0 + 0.9
            let fade = 1 - Double(k) / 6
            c.glowLine(x0, y0, x1, y1, core: C(0xFFF6D0).alpha(0.8 * fade), glow: C(0xFFC81E).alpha(0.6 * fade),
                       coreR: 0.3 + 0.4 * fade, glowR: 0.9 + 1.4 * fade)
        }
        for i in 0..<4 {
            let f = frac(p.t * 1.8 + Double(i) / 4)
            twinkle(c, 16 - Int(f * 16), 30 + (i * 5) % 11, C(0xFFE27A).alpha(0.9 * (1 - f)))
        }
    }
    layer(c, lean: p.flying ? 4 : 0) { c in drawNovaBody(c, p) }
    if let s = p.signature {
        drawGlint(c, p: s, maxX: 39)
        let k = habitArc(s, hold: 0.2)
        if s > 0.45 && s < 0.85 { twinkle(c, 34, 28 + p.breathe, C(0xBFEFFF).alpha(k)) }
    }
}

private func drawNovaBody(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x24346E), blueDark = C(0x18224A), gold = C(0xE8B530), goldDark = C(0xB0841E), slit = C(0xBFEFFF)
    if p.flying {
        for lx in [21, 31] { c.rect(lx, 36, 4, 5, blue); c.rect(lx, 39, 4, 2, gold); c.rect(lx + 3, 36, 1, 3, blueDark) }
    } else {
        drawLegs(c, Look(leg: blue), step: p.step)
        drawBoots(c, gold, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: clawdOrange, arm: blue, eye: nil))
    c.pattern(17, 15, [
        "..........GG..........",
        ".........GGGG.........",
        "..G......GgGG......G..",
        "..GG.....GgGG.....GG..",
        "..GGG....GgGG....GGG..",
        "...GGGGGGGgGGGGGGGG...",
        "..GGGGGGGGgGGGGGGGGG..",
        ".GGLLGGGGGgGGGGGGGGGG.",
        ".GLLGGGGGGGGGGGGGGGGg.",
        ".GGGGGGGGGGGGGGGGGGGg.",
        "GGGGGGGGGGGGGGGGGGGGgg",
        "GGBBBBBBBBBBBBBBBBBBgg",
        "GBBBBBBBBBBBBBBBBBBBBg",
        "GBBBEEBBBBBBBBBEEBBBBg",
        "GBBBBBBBBBBBBBBBBBBBBg",
        "GGBBBBBBBBBBBBBBBBBBgg",
        "GG..................gg",
        ".G..................g.",
    ], ["G": gold, "g": goldDark, "L": C(0xFFE27A), "B": blueDark, "E": slit])
    c.rect(18, 33, 20, 5, blue)
    c.rect(18, 33, 4, 2, gold); c.rect(34, 33, 4, 2, gold)
    c.pattern(25, 33, ["..G..", "GGGGG", ".GGG.", "G...G"], ["G": gold])
    c.rect(18, 37, 20, 1, gold)
    c.rect(37, 35, 1, 2, blueDark)
    c.rect(15, 33, 3, 3, gold)
    if p.flying {
        c.rect(38, 31, 4, 3, gold)
        c.glowLine(42.5, 32, 42.5, 32, core: C(0xFFF6D0), glow: C(0xFFC81E), coreR: 0.6, glowR: 2.2)
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 4, 3, gold); c.rect(41, 33, 1, 3, goldDark)
    if p.fire != nil || p.ready || p.gunLift > 0 {
        c.glowLine(42.5, 34.5, 42.5, 34.5, core: C(0xFFF6D0), glow: C(0xFFC81E), coreR: 0.6, glowR: 2)
    }
}

// MARK: - Kitty Pryde

/// Kitty Pryde: Clawd with a brown ponytail and bangs in the blue-and-yellow X-Men suit (yellow shoulders, gloves,
/// boots and belt with the red X), with Lockheed, her little purple dragon, perched on her head. She fights with her
/// fists, and phases see-through when she's hit, so it goes through her. Signature: she phases right out, faded,
/// shimmering, while Lockheed stays put, solid.
private func drawKittyPryde(_ c: PixelCanvas, _ p: Pose) {
    let phase = max(p.signature.map { habitArc($0, hold: 0.5) } ?? 0, p.hit ? 0.7 : 0)
    if phase > 0.05 {
        phased(c, alpha: 1 - 0.45 * phase, t: p.t) { drawKittyBody($0, p) }
    } else {
        drawKittyBody(c, p)
    }
    c.oy += p.breathe
    drawLockheed(c, t: p.lt, startled: phase > 0.5 && !p.hit)
}

private func drawKittyBody(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4AA8), blueDark = C(0x1C3478), yellow = C(0xE8C02A), yellowDark = C(0xB8901A)
    let hair = C(0x6A3A1E), hairDark = C(0x4A2614)
    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, yellow, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: blue))
    c.pattern(12, 20, [
        "........HHHHHHHHHHHH......",
        "......HHHHHHHHHHHHHHHH....",
        ".....HHHHHhHHHHHHHHhHHH...",
        "...TTHHHHHHHHHHHHHHHHHHH..",
        "..HHTHHHH.hHH.HHHhHH.HHH..",
        ".HHHHHHh..............hH..",
        "HHHHH.H...............HH..",
        "HHHh..h...............h...",
        "HHH.......................",
        "HHh.......................",
        ".Hh.......................",
    ], ["H": hair, "h": hairDark, "T": yellow])
    c.rect(18, 33, 20, 5, blue)
    c.rect(18, 33, 4, 2, yellow); c.rect(34, 33, 4, 2, yellow)
    c.rect(18, 36, 20, 1, yellow)
    c.pattern(26, 35, [".RR.", "RKKR", ".RR."], ["R": C(0xC8202A), "K": ink])
    c.rect(18, 37, 20, 1, blueDark)
    c.rect(37, 33, 1, 3, yellowDark)
    c.rect(15, 34, 3, 2, yellow)
    if let a = p.melee {
        drawPunch(c, angle: a, trail: p.trail, arm: blue, fist: yellow)
    } else {
        c.rect(38, 34, 3, 2, yellow)
    }
}

/// Lockheed, Kitty's little purple dragon, sitting on her head; `startled`: wings up, eyes wide.
private func drawLockheed(_ c: PixelCanvas, t: Double, startled: Bool) {
    let purple = C(0x7A4AB0), dark = C(0x523080), wing = C(0xA07AD8)
    let flap = startled ? (sin(t * 30) > 0 ? -1 : 0) : (sin(t * 1.3) > 0.85 ? -1 : 0)
    c.pattern(18, 13 + flap, [
        ".W.....",
        "WWW....",
        "WWWW...",
        ".WWW...",
    ], ["W": wing])
    c.pattern(18, 16, [
        ".....PPP.",
        "..PPPPPeP",
        ".PPPPPPPPN",
        "PPPPPPPP..",
        "P..d...d..",
    ], ["P": purple, "d": dark, "e": startled ? C(0xFFF4C0) : C(0xFFC81E), "N": dark])
}

// MARK: - Jubilee

/// Jubilee: Clawd with a black bob and her pink sunglasses, the big yellow trench coat with the collar popped, open
/// over a red top and blue shorts, pink sneakers. Fireworks crackle in every colour from her hand. Signature: she
/// blows a pink bubblegum bubble, bigger and bigger, until it pops all over her face.
private func drawJubilee(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xF0C020), coatDark = C(0xC0901A), hair = C(0x1A1A22), pink = C(0xFF5AB0), lens = C(0x7A1A4A)
    let top = C(0xD8304A), shorts = C(0x2A4FA0)
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, C(0xE0408A), step: p.step, rows: 2)
    c.oy += p.breathe
    if !seatedPose {
        c.rect(16, 37, 7, 4, coat); c.rect(16, 40, 7, 1, coatDark)
        c.rect(33, 37, 6, 3, coat); c.rect(33, 39, 6, 1, coatDark)
    }
    drawBody(c, Look(arm: coat, eye: nil))
    c.pattern(16, 20, [
        ".......HHHHHHHHHH.......",
        ".....HHHHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHH.HH.HH.HH.HH.HHHH..",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HH..................HH.",
        ".HH..................HH.",
    ], ["H": hair])
    c.pattern(20, 28, [
        ".PPPP......PPPP.",
        "PPLLPPPPPPPPLLPP",
        ".PLLP......PLLP.",
        "..PP........PP..",
    ], ["P": pink, "L": lens])
    c.px(22, 29, C(0xFF9AD0))
    // The coat, open over the top and shorts; the collar popped.
    c.pattern(16, 30, [
        "CC..................CC",
        "CCC................CCC",
        ".CCCCCCTTTTTTTTCCCCCc.",
        "..CCCCCTTTTTTTTCCCCc..",
        "..CCCCCTTTTTTTTCCCCc..",
        "..CCCCCSSSSSSSSCCCCc..",
        "..CCCCCSSSSSSSSCCCCc..",
        "..cccccSSSSSSSScccc...",
    ], ["C": coat, "c": coatDark, "T": top, "S": shorts])
    c.rect(15, 33, 3, 3, coat)
    if let s = p.signature, s > 0.05 {
        drawBubble(c, s)
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, coat); c.rect(41, 34, 1, 1, clawdOrange)
    if p.fire != nil || p.ready || p.gunLift > 0 || p.cheering {
        drawFireworks(c, x: 42.5, y: 34.5, t: p.t, size: 3.5)
    }
}

/// A pink bubblegum bubble blown from Jubilee's mouth, `s` 0…1: it grows, wobbles and pops.
private func drawBubble(_ c: PixelCanvas, _ s: Double) {
    let pink = C(0xFF8AC8), edge = C(0xE0509A), shine = C(0xFFE0F0)
    if s < 0.78 {
        let r = 1 + 4 * min(1, s / 0.7)
        let ri = Int(r.rounded())
        c.ellipse(28, 34, ri, ri, edge)
        if ri > 1 { c.ellipse(28, 34, ri - 1, ri - 1, pink) }
        if ri > 2 { c.px(28 - ri / 2, 34 - ri / 2, shine); c.px(27 - ri / 2, 34 - ri / 2 + 1, shine.alpha(0.7)) }
    } else {
        // Popped: gum all over the face.
        let k = (s - 0.78) / 0.22
        for i in 0..<9 {
            let a = Double(i) / 9 * 2 * .pi
            let r = 2.5 + noise(i * 13) * 3.5
            c.px(28 + Int((cos(a) * r).rounded()), 34 + Int((sin(a) * r * 0.8).rounded()), pink.alpha(1 - k * 0.5))
        }
        c.rect(26, 33, 5, 2, pink.alpha(1 - k * 0.6))
    }
}

/// Jubilee's fireworks: little sparks of every colour popping round (`x`, `y`).
private func drawFireworks(_ c: PixelCanvas, x: Double, y: Double, t: Double, size: Double) {
    let cols = [C(0xFF5AC8), C(0xFFE27A), C(0x7AE8FF), C(0x9AFF7A), C(0xFFFFFF)]
    let seed = Int(t * 18)
    c.glowLine(x, y, x, y, core: C(0xFFF0FF), glow: C(0xFF5AC8), coreR: 0.6, glowR: 1.8)
    for i in 0..<7 {
        let a = noise(seed * 7 + i) * 2 * .pi, r = 1.5 + noise(seed * 11 + i) * size
        let col = cols[(seed + i) % cols.count]
        let px = Int((x + cos(a) * r).rounded()), py = Int((y + sin(a) * r).rounded())
        c.px(px, py, col.alpha(0.95))
        if i % 2 == 0 { c.px(px + 1, py, col.alpha(0.5)); c.px(px, py - 1, col.alpha(0.5)) }
    }
}

// MARK: - Psylocke

/// Psylocke: Clawd with long purple hair streaming back, the red mark over her eye, the purple ninja suit with a red
/// sash knotted at the waist (its ends fluttering behind) and red arm wraps. Her psychic katana glows pink when she
/// fights; at rest a little psi-glow sits in her fist. Signature: her eyes glow and a pink psychic butterfly forms in
/// her hand, beats its wings and flutters up and away.
private func drawPsylocke(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x4A2A9A), suitDark = C(0x321A6E), red = C(0xC8202A), redDark = C(0x8A1218)
    let hair = C(0x8A3AD8), hairDark = C(0x5E22A0), psiCore = C(0xFFE0F6), psiGlow = C(0xE040C0)
    // Hair streaming back, behind everything.
    for i in 0..<4 {
        let y = 24.0 + Double(i) * 3, len = 6.0 - Double(i)
        let wave = sin(p.t * 5 + Double(i)) * 1.2
        bar(c, 18, y, 18 - len, y + 2 + wave, i % 2 == 0 ? hair : hairDark, 1)
    }
    drawLegs(c, Look(leg: suitDark), step: p.step)
    drawBoots(c, C(0x1C1230), step: p.step, rows: 3)
    c.oy += p.breathe
    // Sash ends fluttering behind.
    let flutter = sin(p.t * 6) > 0 ? 1 : 0
    c.pattern(15 - flutter, 36, ["...RR", "..RRr", ".RRr.", "Rr.r.", ".r..."], ["R": red, "r": redDark])
    let s = p.signature ?? -1
    let psi = s > 0 ? habitArc(s, hold: 0.6) : 0
    drawBody(c, Look(arm: suit, eye: psi > 0.3 ? C(0xFF7AE0) : ink))
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHH.......hHHHHHH..",
        ".HHHHh..........hHHHHH..",
        ".HHH..............hHHH..",
        ".HHh...............HHH..",
        ".HH................hHH..",
        "HHH.................HH..",
        "HHh.................hH..",
        "HH..................HH..",
        "Hh...................H..",
        "H....................h..",
    ], ["H": hair, "h": hairDark])
    c.px(33, 28, red); c.px(34, 27, red); c.px(32, 32, red)          // the mark over her eye
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitDark)
    c.rect(18, 36, 20, 1, red); c.rect(18, 37, 20, 1, redDark)
    c.rect(19, 35, 2, 2, red)                                       // the knot
    c.rect(15, 33, 3, 1, red)
    c.rect(38, 33, 3, 1, red)
    if let a = p.melee {
        drawSaber(c, t: p.t, angle: a, core: psiCore, glow: psiGlow, lit: true, trail: p.trail, length: 15)
    } else if psi > 0.05 {
        let rise = s < 0.25 ? 0 : (s - 0.25) / 0.75
        let bx = 42 + rise * 6, by = 31 - rise * 20
        drawButterfly(c, x: bx, y: by, t: p.t, size: min(1, s / 0.2), alpha: psi, core: psiCore, glow: psiGlow)
    } else {
        c.glowLine(41.5, 34.5, 41.5, 34.5, core: psiCore.alpha(0.8), glow: psiGlow.alpha(0.6), coreR: 0.4, glowR: 1.3)
    }
}

/// Psylocke's psychic butterfly at (`x`, `y`), wings beating.
private func drawButterfly(_ c: PixelCanvas, x: Double, y: Double, t: Double, size: Double, alpha: Double, core: Px, glow: Px) {
    let beat = 0.35 + 0.65 * abs(cos(t * 9))
    let w = 3.5 * beat * size, h = 3 * size
    let cr = core.alpha(alpha), gl = glow.alpha(alpha * 0.9)
    for side in [-1.0, 1.0] {
        c.glowLine(x, y, x + side * w, y - h, core: cr, glow: gl, coreR: 0.5, glowR: 1.4)
        c.glowLine(x + side * w, y - h, x + side * w * 0.8, y, core: cr, glow: gl, coreR: 0.5, glowR: 1.4)
        c.glowLine(x, y, x + side * w * 0.7, y + h * 0.7, core: cr, glow: gl, coreR: 0.4, glowR: 1.2)
    }
    c.glowLine(x, y - 1.5, x, y + 2, core: cr, glow: gl, coreR: 0.4, glowR: 1)
}

// MARK: - Shared helpers

private let clear = C(0x000000, 0)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from the hand along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// A punch: the arm thrown out along `angle`, a fist on the end and faint fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, reach: Double = 6) {
    let h = Sprite.hand
    for (i, a) in trail.enumerated() {
        let e = along(a, reach)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = along(angle, reach)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
}

/// A sorcerer's spinning mandala: a glowing ring with a turning inner square, centred on `at`.
private func drawMandala(_ c: PixelCanvas, at: (x: Double, y: Double), r: Double, t: Double, core: Px, glow: Px) {
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

/// A small eighth note, its top-left at (`x`, `y`).
private func drawNote(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.pattern(x, y, ["..NN", "..N.", "..N.", "NNN.", "NN.."], ["N": col])
}

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255 * 0.95))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
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

/// A wash of `col` at `amount` over everything drawn so far (a glow, or the Void's darkness).
private func wash(_ c: PixelCanvas, _ col: Px, _ amount: Double) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<c.h { for x in 0..<c.w where c.isDrawn(x, y) { c.px(x, y, col.alpha(amount)) } }
}

/// Draws `art` on a scratch canvas and copies it onto `c` faded to `alpha`, its rows shimmering sideways and tinted
/// pale blue: phasing.
private func phased(_ c: PixelCanvas, alpha: Double, t: Double, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let tick = Int(t * 12)
    for y in 0..<s.h {
        let shift = (y + tick) % 5 == 0 ? 1 : ((y + tick) % 5 == 2 ? -1 : 0)
        let rowAlpha = (y + tick) % 3 == 0 ? alpha * 0.7 : alpha
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            let col = lerp(unpremultiplied(s, i), C(0xBFE4FF), 0.3)
            c.px(x + shift, y, col.alpha(rowAlpha * Double(s.buf[i + 3]) / 255))
            // A pale ghostly rim where the figure meets the air.
            let edge = x == 0 || y == 0 || x == s.w - 1 || y == s.h - 1 || s.buf[i - 4 + 3] == 0 || s.buf[i + 4 + 3] == 0
                || s.buf[i - s.w * 4 + 3] == 0 || s.buf[i + s.w * 4 + 3] == 0
            if edge && s.buf[i + 3] > 200 { c.px(x + shift, y, C(0xBFE4FF, 0.8)) }
        }
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`, leaning forward one pixel every
/// `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, lean: Int = 0, _ art: (PixelCanvas) -> Void) {
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
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i))
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
