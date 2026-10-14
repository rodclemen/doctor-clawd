import Foundation

// Heroes: the Doctor's later companions and friends. Clawd in costume like everyone else: hair, hats, jackets, armour
// and veils drawn over (and around) the blocky body, Clawd's own orange face showing (green-scaled, for Madame Vasta).
// Most of them don't fight: they run, point the way and cheer. Rory, River, Vasta and Jenny do.

let doctorHeroes6: [DoctorHero: Persona] = [
    .martha: Persona(name: "Martha Bones", headTop: 19,
                  draw: drawMartha),
    .donna: Persona(name: "Donna Nobble", headTop: 17, signature: 2.4, callout: "Oi!",
                  draw: drawDonna),
    .wilf: Persona(name: "Wilf Moth", headTop: 15, signature: 3.2,
                  draw: drawWilf),
    .amy: Persona(name: "Amy Puddle", headTop: 18,
                  draw: drawAmy),
    .rory: Persona(name: "Rory Willjams", weapon: .saber, headTop: 12, signature: 3.6,
                  draw: drawRory),
    .river: Persona(name: "River Tune", weapon: .blaster, shot: .energy(core: C(0xFFF4E0), glow: C(0xFF8A3A)),
                  muzzle: (48, 32), headTop: 14, callout: "Hello, sweetie.",
                  draw: drawRiver),
    .clara: Persona(name: "Clara Oswalt", headTop: 19, signature: 3.2,
                  draw: drawClara),
    .vasta: Persona(name: "Madame Vasta", weapon: .saber, headTop: 16, signature: 2.2,
                  draw: drawVasta),
    .jenny: Persona(name: "Jenny Flynt", weapon: .saber, headTop: 20,
                  draw: drawJenny),
]

// MARK: - Shared helpers

private let hand = Sprite.hand
private let none = C(0, 0)

/// A point `d` pixels out from `h` at `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid line `r` pixels thick.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: none, coreR: r, glowR: r + 0.1)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h`.
private func bar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
                 r: Double = 0.8) {
    let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
    line(c, p0.x, p0.y, p1.x, p1.y, col, r)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func boots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

/// A companion's right arm: pointing the way while working or waiting, punched up cheering, flung up when hit, down
/// at the side otherwise.
private func companionArm(_ c: PixelCanvas, _ p: Pose, sleeve: Px) {
    if p.cheering {
        c.rect(38, 24, 3, 9, sleeve); c.rect(38, 22, 3, 2, clawdOrange)
    } else if p.hit {
        c.rect(38, 29, 3, 4, sleeve); c.rect(39, 27, 3, 2, clawdOrange)
    } else if p.ready || (!p.resting && !p.walking) {
        c.rect(38, 31, 5, 2, sleeve); c.rect(43, 31, 2, 2, clawdOrange); c.px(45, 31, clawdOrange)
    }
}

/// A blade in the hand at `angle`: the grip, a guard across it, and `length` of steel whose tip bends back `curve`
/// pixels (a katana's sweep); `trail` smears a fast swing.
private func drawBlade(_ c: PixelCanvas, angle: Double, trail: [Double], length: Double, grip: Px, guardCol: Px,
                       curve: Double = 0, width: Double = 0.8) {
    let steel = C(0xB4BAC4), edge = C(0xF0F4F8)
    for (i, a) in trail.enumerated() {
        let s = reach(hand, a, 3), e = reach(hand, a, 2.5 + length)
        c.glowLine(s.x, s.y, e.x, e.y, core: edge.alpha(0.5), glow: edge.alpha(0.5), coreR: 0.4, glowR: 1.4,
                   strength: 0.45 / Double(i + 1))
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    bar(c, hand, angle, from: -2.5, to: 1.5, grip, r: 0.8)
    line(c, hand.x + ux * 2 - nx * 1.5, hand.y + uy * 2 - ny * 1.5, hand.x + ux * 2 + nx * 1.5, hand.y + uy * 2 + ny * 1.5,
         guardCol, 0.6)
    var prev = (x: hand.x + ux * 2.5, y: hand.y + uy * 2.5)
    for i in 1...4 {
        let f = Double(i) / 4, bend = curve * f * f
        let q = (x: hand.x + ux * (2.5 + length * f) - nx * bend, y: hand.y + uy * (2.5 + length * f) - ny * bend)
        line(c, prev.x, prev.y, q.x, q.y, steel, width)
        prev = q
    }
    line(c, hand.x + ux * 3 + nx * 0.4, hand.y + uy * 3 + ny * 0.4, prev.x, prev.y, edge, 0.45)
}

// MARK: - Martha Bones

/// Martha Bones: Clawd with short black hair swept back into a bun, a zipped red leather jacket over a black top, dark
/// jeans and black boots. She doesn't fight: she points the way and cheers.
private func drawMartha(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0xB0202A), leatherL = C(0xD4434C), leatherD = C(0x72121A), top = C(0x1E1E24)
    let jeans = C(0x2E3A52), hair = C(0x1A1210), hairL = C(0x3A2A20)
    drawLegs(c, Look(leg: jeans), step: p.step)
    boots(c, C(0x141418), step: p.step, rows: 2)
    c.oy += p.breathe
    c.pattern(13, 21, [".HH.", "HHlH", "HHHH", ".HH."], ["H": hair, "l": hairL])   // the bun
    drawBody(c, Look(arm: leather))
    c.pattern(17, 19, [
        "......HHHHHHHHH.......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHlHHHHHHlHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHlHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHlHHHHH",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHH........HHH.",
        ".HHH..............HH..",
        ".HH...................",
    ], ["H": hair, "l": hairL])
    // The jacket, zipped up, the collar turned out over the black top's neckline.
    c.rect(18, 32, 20, 6, leather)
    c.rect(26, 32, 4, 1, top)
    c.pattern(23, 32, ["LLL....LLL", ".LL....LL."], ["L": leatherL])
    c.rect(28, 33, 1, 4, C(0xC8CCD4)); c.px(28, 33, C(0x8A8E98))   // the zip
    c.rect(20, 35, 3, 1, leatherD); c.rect(33, 35, 3, 1, leatherD)  // pockets
    c.rect(19, 33, 1, 3, leatherL)
    c.rect(37, 32, 1, 6, leatherD); c.rect(18, 37, 20, 1, leatherD)
    c.rect(15, 33, 3, 3, leather); c.rect(15, 35, 3, 1, leatherD)
    companionArm(c, p, sleeve: leather)
}

// MARK: - Donna Nobble

/// Donna Nobble: Clawd with a big swoop of ginger-red hair down past her shoulders, a charcoal jacket over a white
/// blouse, dark trousers. She doesn't fight: she points and cheers. Signature: Oi!: a hop, a finger wagged high, and
/// an OI! that fills its speech bubble.
private func drawDonna(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xA8341A), hairL = C(0xD0582A), hairD = C(0x6E200E)
    let jacket = C(0x2E2A36), jacketL = C(0x46404E), blouse = C(0xF2EEE6), trousers = C(0x26242C)
    let s = p.signature ?? -1
    let oi = s > 0.12 && s < 0.9
    if s > 0.12 && s < 0.22 { c.oy -= 2 }
    drawLegs(c, Look(leg: trousers), step: p.step)
    boots(c, C(0x121216), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    c.pattern(14, 17, [
        ".......HHHHHHHHHHH.........",
        ".....HHHHHlHHHHHHHHH.......",
        "...HHHHHHHHHHHHlHHHHHH.....",
        "..HHHlHHHHHHHHHHHHHHHHH....",
        ".HHHHHHHHHHlHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHHHlHH..",
        "HHHHlHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHlHHHHH",
        "HHHHHdHHHHHd.......dHHHHHHH",
        "HHHHHH..............dHHHHH.",
        "HHHHH................dHHHH.",
        "HHHHH.................dHHH.",
        "HHHH...................HHH.",
        "HHHH...................dH..",
        "HHHd....................H..",
        ".HHH.......................",
        ".HHd.......................",
        "..H........................",
    ], ["H": hair, "l": hairL, "d": hairD])
    // The jacket over the blouse.
    c.rect(18, 32, 20, 6, jacket)
    c.pattern(25, 32, ["WWWWWW", ".WWWW.", "..WW.."], ["W": blouse])
    c.rect(24, 32, 1, 4, jacketL); c.rect(31, 32, 1, 4, jacketL)
    c.rect(37, 32, 1, 6, C(0x1E1A24)); c.rect(18, 37, 20, 1, C(0x1E1A24))
    c.rect(15, 33, 3, 3, jacket)
    if oi {
        // Finger up and wagging, and the bubble.
        let wag = Int(p.t * 10) % 2
        c.rect(38, 26, 3, 7, jacket); c.rect(38, 24, 3, 2, clawdOrange)
        c.rect(39 + wag, 21, 1, 3, clawdOrange)
        if s > 0.16 {
            c.pattern(42, 8, [
                ".KKKKKKKKKKKKK.",
                "KWWWWWWWWWWWWWK",
                "KWWKKKWKKKWWKWK",
                "KWWKWKWWKWWWKWK",
                "KWWKWKWWKWWWKWK",
                "KWWKWKWWKWWWWWK",
                "KWWKKKWKKKWWKWK",
                "KWWWWWWWWWWWWWK",
                ".KWWKKKKKKKKKK.",
                ".KWK...........",
                "KK.............",
            ], ["K": ink, "W": white])
        }
    } else {
        companionArm(c, p, sleeve: jacket)
    }
}

// MARK: - Wilf Moth

/// Wilf Moth: Clawd in a red woolly bobble hat with a ribbed band, white tufts of hair under it, a zipped beige anorak
/// and brown trousers. He doesn't fight: he points and cheers. Signature: he presents his paintball gun, upright and
/// proper, then grounds it beside him and salutes.
private func drawWilf(_ c: PixelCanvas, _ p: Pose) {
    let hat = C(0xC0262C), hatD = C(0x8A161C), bobble = C(0xF0E8DC), tuft = C(0xE8E8EE)
    let anorak = C(0xC2AE84), anorakD = C(0x96825E), trousers = C(0x5E564A)
    let s = p.signature ?? -1
    let present = s > 0.08 && s < 0.45
    let salute = s >= 0.45 && s < 0.95
    drawLegs(c, Look(leg: trousers), step: p.step)
    boots(c, C(0x3A2A1E), step: p.step, rows: 1)
    if salute { drawPaintballGun(c, x: 43, y: 22) }   // grounded beside him
    c.oy += salute ? 0 : p.breathe
    drawBody(c, Look(arm: anorak))
    c.pattern(17, 14, [
        "..........bb..........",
        ".........bbbb.........",
        "........bbbbbb........",
        "......RRRRRRRRRR......",
        "....RRRRRRRRRRRRRR....",
        "...RRrRRRRRrRRRRRRR...",
        "..RRRRRRRRRRRRRRRRRR..",
        "..RRRRRrRRRRRRRrRRRR..",
        ".RRRRRRRRRRRRRRRRRRRR.",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BrBrBrBrBrBrBrBrBrBrBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
    ], ["b": bobble, "R": hat, "r": hatD, "B": hatD])
    c.rect(17, 25, 2, 1, hat)
    c.pattern(16, 26, ["TTT", "TT.", "T.."], ["T": tuft])
    c.pattern(37, 26, ["TT", "T."], ["T": tuft])
    // The anorak, zipped up, its collar high.
    c.rect(18, 32, 20, 6, anorak)
    c.rect(27, 32, 1, 6, anorakD)
    c.rect(18, 32, 20, 1, anorakD)
    c.rect(20, 35, 3, 1, anorakD); c.rect(33, 35, 3, 1, anorakD)   // pocket flaps
    c.rect(37, 32, 1, 6, anorakD); c.rect(17, 37, 22, 1, anorakD)
    c.rect(15, 33, 3, 3, anorak)
    if present {
        c.rect(38, 30, 3, 3, anorak)
        drawPaintballGun(c, x: 39, y: 13)
        c.rect(38, 29, 3, 2, clawdOrange)
    } else if salute {
        // Hand up to the brim.
        c.rect(38, 27, 3, 6, anorak); c.rect(35, 25, 5, 2, anorak); c.rect(33, 24, 3, 2, clawdOrange)
    } else {
        companionArm(c, p, sleeve: anorak)
    }
}

/// Wilf's paintball gun, upright, its muzzle at (x + 1, y), 22 px tall: a black barrel, a lime body, a big blue hopper
/// full of paintballs and a silver air tank at the bottom.
private func drawPaintballGun(_ c: PixelCanvas, x: Int, y: Int) {
    let barrel = C(0x1E1E24), body = C(0x6AC83A), bodyD = C(0x3E8A22), hopper = C(0x3A7AD8), tank = C(0xC8CCD4)
    c.rect(x + 1, y, 2, 8, barrel); c.px(x + 1, y, C(0x4A4A52))
    c.rect(x, y + 8, 4, 7, body); c.rect(x + 3, y + 8, 1, 7, bodyD)
    c.pattern(x + 4, y + 5, [".HHH.", "HHHHH", "HPHYH", "HHHHH", ".HHH."],
              ["H": hopper, "P": C(0xFF5A8A), "Y": C(0xF0D040)])
    c.px(x + 5, y + 6, C(0x8AC0FF))
    c.rect(x, y + 15, 3, 1, barrel)
    c.rect(x, y + 16, 3, 5, tank); c.rect(x + 2, y + 16, 1, 5, C(0x8A8E98)); c.rect(x, y + 21, 3, 1, barrel)
}

// MARK: - Amy Puddle

/// Amy Puddle: Clawd with long straight copper-red hair and a side fringe, a blue denim jacket over a white top, a
/// short black skirt, black tights and brown knee boots. She doesn't fight: she points the way and cheers.
private func drawAmy(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xC04420), hairL = C(0xE66A34), hairD = C(0x7E2A12)
    let denim = C(0x4A6A9A), denimD = C(0x34507A), denimL = C(0x6A8ABA), skirt = C(0x1E1E26), tights = C(0x2A2630)
    drawLegs(c, Look(leg: tights), step: p.step)
    boots(c, C(0x6A4226), step: p.step, rows: 4)
    c.oy += p.breathe
    drawBody(c, Look(arm: denim))
    c.pattern(15, 18, [
        "......HHHHHHHHHHH........",
        "....HHHHHHHHHHHHHHH......",
        "...HHHHlHHHHHHHHHHHH.....",
        "..HHHHHHHHHHHHlHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH..",
        ".HHHlHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHlHHHHH.",
        ".HHHHHHHHHHHHHHHdddHHHHH.",
        ".HHHHHHHHHd.........dHHH.",
        ".HHHHHd..............dHH.",
        ".HHHH................HHH.",
        ".HHHd................HH..",
        ".HHHH................dH..",
        ".HHHd.................H..",
        ".HHHH....................",
        ".HHHd....................",
        ".HHHH....................",
        "..HHd....................",
        "..Hd.....................",
    ], ["H": hair, "l": hairL, "d": hairD])
    // The denim jacket over a white top, the short skirt.
    c.rect(19, 32, 19, 4, denim)
    c.pattern(25, 32, ["WWWWWW", ".WWWW.", "..WW.."], ["W": C(0xF2F0EA)])
    c.rect(24, 32, 1, 4, denimL); c.rect(31, 32, 1, 4, denimL)
    c.px(21, 33, denimL); c.px(34, 33, denimL)   // buttons on the breast pockets
    c.rect(37, 32, 1, 4, denimD); c.rect(19, 35, 19, 1, denimD)
    c.rect(18, 36, 20, 2, skirt); c.rect(17, 38, 22, 1, skirt)
    c.rect(15, 33, 3, 3, denim)
    companionArm(c, p, sleeve: denim)
}

// MARK: - Rory Willjams

/// Rory Willjams as the Last Centurion: Clawd in a Roman helmet with a red brush crest, cheek and neck guards, the
/// banded steel armour over a red tunic with leather strips, a red cloak behind, bare legs in sandals. Fights with a
/// gladius, sheathed at his hip between fights. Signature: the Last Centurion stands guard: his tall red shield comes
/// up, the gladius held upright, and he doesn't move while the sun and moon go round over him.
private func drawRory(_ c: PixelCanvas, _ p: Pose) {
    let crest = C(0xC0202A), crestD = C(0x861218), steel = C(0xB8BCC4), steelD = C(0x7A7E88), steelL = C(0xE0E4EA)
    let bronze = C(0xC89A48), bronzeD = C(0x8E6A2A), tunic = C(0xB0202A), cloak = C(0x9A1A22), cloakD = C(0x6A1016)
    let leather = C(0x6A4428)
    let s = p.signature ?? -1
    let guarding = s > 0.06 && s < 0.94
    // The sun and the moon go over while he stands there.
    if guarding {
        let k = (s - 0.06) / 0.88, f = frac(k * 2)
        let x = Int((6 + f * 58).rounded()), y = Int((11 - sin(f * .pi) * 9).rounded())
        if k < 0.5 {
            c.rect(x, y, 3, 3, C(0xFFD24A)); c.px(x + 1, y + 1, C(0xFFF2B0))
            for (dx, dy) in [(1, -2), (1, 4), (-2, 1), (4, 1)] { c.px(x + dx, y + dy, C(0xFFD24A, 0.6)) }
        } else {
            c.rect(x, y, 3, 3, C(0xE8ECF4)); c.rect(x + 2, y, 1, 2, none); c.px(x + 2, y, C(0x9AA4B8, 0.4))
        }
    }
    // The cloak, behind him.
    c.pattern(12, 26, [
        "....CC",
        "...CCC",
        "..CCCC",
        "..CCCC",
        ".CCcCC",
        ".CCcCC",
        ".CCcCC",
        "CCCcCC",
        "CCcCCC",
        "CCcCCC",
        "CCcCCC",
        "CcCCCC",
        "CcCCC.",
        "cCCC..",
        "cCC...",
    ], ["C": cloak, "c": cloakD])
    // The gladius in its scabbard at his hip, between fights.
    if p.melee == nil && !guarding {
        line(c, 34, 35, 40, 41, leather, 0.9); c.px(40, 41, bronze); c.px(39, 40, bronze)
        line(c, 33, 34, 32, 33, bronzeD, 0.8)
    }
    drawLegs(c, Look(), step: p.step)
    // Sandals: straps up the shins.
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, b, 2, 1, leather); c.rect(lx, b - 2, 2, 1, leather); c.px(lx, b - 4, leather)
        }
    }
    c.oy += guarding ? 0 : p.breathe
    drawBody(c, Look(arm: steel))
    // The tunic and the leather strips below the armour.
    c.rect(18, 37, 20, 2, tunic)
    for x in stride(from: 18, to: 38, by: 3) { c.rect(x, 37, 2, 3, leather); c.px(x, 39, bronze) }
    // Banded armour.
    c.rect(18, 32, 20, 5, steel)
    for y in [33, 35] { c.rect(18, y, 20, 1, steelD) }
    c.rect(18, 32, 20, 1, steelL)
    c.rect(27, 32, 2, 5, bronze); c.rect(27, 34, 2, 1, bronzeD)
    c.rect(37, 32, 1, 5, steelD)
    c.pattern(15, 32, ["SSS", "sss", "SSS", "sss"], ["S": steel, "s": steelD])   // pauldron
    // The helmet: crest, dome, brow band, neck guard behind, cheek guard in front.
    c.pattern(16, 12, [
        ".......CCCCCCCCCC......",
        ".....CCCcCCcCCcCCCC....",
        "....CCCCCCCCCCCCCCCC...",
        "....cCCCcCCCCcCCCCCc...",
        "........bbbbbbbb.......",
        "......SSSSSSSSSSSS.....",
        "....SSSSSSSSSSSSSSSS...",
        "...SSSSSlSSSSSSSSSSSS..",
        "..SSSSSlSSSSSSSSSSSSSS.",
        "..SSSSSSSSSSSSSSSSSSSSS",
        "..SSSSSSSSSSSSSSSSSSSSs",
        ".SSSSSSSSSSSSSSSSSSSSSs",
        ".bbbbbbbbbbbbbbbbbbbbbb",
        "SSSs...............Sss.",
        "SSSs...............SSs.",
        "SSSSs..............SSs.",
        "SSSSs..............SSs.",
        "sSSSs..............Ss..",
        ".sss...............b...",
    ], ["C": crest, "c": crestD, "b": bronze, "S": steel, "s": steelD, "l": steelL])
    if guarding {
        // The gladius held up, and the shield.
        c.rect(38, 27, 3, 6, steel); c.rect(39, 25, 3, 2, clawdOrange)
        c.rect(40, 14, 1, 9, C(0xD4D8E0)); c.px(40, 13, steelL); c.rect(39, 23, 3, 1, bronze); c.px(40, 24, leather)
        c.pattern(39, 26, [
            ".GGGGGG",
            "GRRRRRRG",
            "GRRRRRRG",
            "GRRYRRRG",
            "GRYRRRRG",
            "GRRRYRRG",
            "GRRBBRRG",
            "GRBbbBRG",
            "GRRBBRRG",
            "GRRRYRRG",
            "GRRYRRRG",
            "GRYRRRRG",
            "GRRRRRRG",
            "GRRRRRRG",
            "GRRRRRRG",
            "GRRRRRRG",
            ".GGGGGG",
        ], ["G": bronze, "R": C(0xA81820), "Y": C(0xE8C050), "B": bronzeD, "b": C(0xF0D47A)])
        return
    }
    if let a = p.melee {
        drawBlade(c, angle: a, trail: p.trail, length: 9, grip: leather, guardCol: bronze, width: 1.0)
        let pommel = reach(hand, a, -3)
        c.px(Int(pommel.x), Int(pommel.y), bronze)
        c.rect(38, 33, 3, 3, steel)
    } else if p.cheering {
        c.rect(38, 24, 3, 9, steel); c.rect(38, 22, 3, 2, clawdOrange)
    }
}

// MARK: - River Tune

/// River Tune: Clawd under a huge cloud of curly blonde hair, a khaki field jacket with a brown belt, dark trousers
/// and boots. Fights with her energy pistol, its emitter glowing orange. Says "Hello, sweetie."
private func drawRiver(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xE2BE62), hairL = C(0xF8E08A), hairD = C(0xB08A38)
    let jacket = C(0xBFA678), jacketD = C(0x8E784E), belt = C(0x5A3A22), trousers = C(0x4A3A2A)
    drawLegs(c, Look(leg: trousers), step: p.step)
    boots(c, C(0x2A1E16), step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    c.rect(18, 32, 20, 6, jacket)
    c.rect(27, 33, 1, 3, jacketD); c.rect(21, 34, 3, 1, jacketD); c.rect(32, 34, 3, 1, jacketD)
    c.rect(18, 36, 20, 1, belt); c.rect(26, 36, 2, 1, C(0xC8A048))
    c.rect(37, 32, 1, 6, jacketD)
    c.rect(15, 33, 3, 3, jacket)
    c.pattern(12, 14, [
        "..........HHlHHHHlHH...........",
        ".......HHHHHHHdHHHHHHHlH.......",
        ".....HHlHHHdHHHHHlHHHHHHHH.....",
        "....HHHHHHHHHHlHHHHHHdHHHHH....",
        "...HHdHHHlHHHHHHHHHHHHHHlHHH...",
        "..HHHHHHHHHHHdHHHHlHHHHHHHHHH..",
        "..HHlHHHHdHHHHHHHHHHHHdHHHlHHH.",
        ".HHHHHHHHHHHHlHHHHdHHHHHHHHHHH.",
        ".HHHHdHHlHHHHHHHHHHHHHHlHHHdHH.",
        "HHlHHHHHHHHHdHHHHlHHHHHHHHHHHHH",
        "HHHHHHHlHHHHHHHHHHHHHHdHHHHlHHH",
        "HHHHdHHHHHHHHlHHHHHdHHHHHHHHHHH",
        "HHHHHHHHlHHdHH......dHHHHHHHdHH",
        "HHlHHHHHd..............HHHlHHH.",
        "HHHHHdH................dHHHHH..",
        "HHHHHH..................HHlHH..",
        "HHlHHH..................HHHH...",
        "HHHHdH..................dHHH...",
        ".HHHHH...................HH....",
        ".HHlHH.........................",
        "..HHHd.........................",
        "..HHH..........................",
        "...H...........................",
    ], ["H": hair, "l": hairL, "d": hairD])
    // The pistol.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, jacket)
    let lit = p.fire != nil || p.ready
    c.pattern(40, 31, [
        "..SSSSs.",
        "KKKKKKKL",
        "KK.k....",
        "KK......",
    ], ["S": C(0xC8CCD4), "s": C(0x8A8E98), "K": C(0x2A2A32), "k": C(0x5A5A66),
        "L": lit ? C(0xFFB06A) : C(0xC87A3A)])
}

// MARK: - Clara Oswalt

/// Clara Oswalt: Clawd with a glossy dark-brown bob and a swept fringe, a burgundy polka-dot dress with a thin black
/// belt, black tights and shoes. She doesn't fight: she points the way and cheers. Signature: the soufflé: out comes a
/// ramekin, the soufflé rises tall and golden, she shows it off, and it sinks with a sad puff.
private func drawClara(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x3A2418), hairL = C(0x5E3C28), hairD = C(0x22140C)
    let dress = C(0x8A2234), dressD = C(0x5E1624), collar = C(0xE8C8D0), tights = C(0x1E1C24)
    let s = p.signature ?? -1
    let baking = s > 0.06 && s < 0.96
    drawLegs(c, Look(leg: tights), step: p.step)
    boots(c, C(0x121214), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(arm: dress))
    c.pattern(16, 19, [
        "......HHHHHHHHHH.......",
        "....HHHHHHHHHHHHHH.....",
        "...HHHHHlHHHHHHHHHH....",
        "..HHHHHHHHHHHHlHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHH..",
        ".HHHlHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHlhhHHH.",
        ".HHHHHHHHHH.......hHHH.",
        ".HHHHH.............HHH.",
        ".HHHH..............HH..",
        ".HHHH..............HH..",
        ".HHHh..............hH..",
        ".hhhh..................",
    ], ["H": hair, "l": hairL, "h": hairD])
    // The dress, the collar, the hem flaring a little.
    c.rect(18, 32, 20, 6, dress)
    for (x, y) in [(20, 33), (24, 36), (29, 33), (33, 36), (36, 33), (19, 37), (27, 38), (35, 38)] { c.px(x, y, collar) }
    c.rect(18, 35, 20, 1, C(0x1E1C24)); c.px(28, 35, C(0xC8A048))
    c.rect(17, 38, 22, 1, dress); c.rect(37, 32, 1, 6, dressD)
    c.rect(15, 33, 3, 3, dress)
    guard baking else { companionArm(c, p, sleeve: dress); return }
    // The soufflé: out, up, admired, down.
    c.rect(38, 32, 3, 2, dress); c.rect(41, 33, 1, 2, clawdOrange)
    let ram = C(0xF4F4F0), ramD = C(0xC8C8D0), gold = C(0xE8B850), goldL = C(0xF8DC8A), brown = C(0xB07A2A)
    let rise: Double
    if s < 0.18 { rise = 0 } else if s < 0.5 { rise = (s - 0.18) / 0.32 } else if s < 0.76 { rise = 1 }
    else { rise = max(0, 1 - (s - 0.76) / 0.06) }
    let h = Int((rise * 5).rounded())
    c.rect(42, 31, 7, 4, ram)
    for x in stride(from: 42, to: 49, by: 2) { c.rect(x, 32, 1, 3, ramD) }
    if h > 0 {
        for i in 0..<h {
            let inset = i == h - 1 && h > 2 ? 1 : 0
            c.rect(42 + inset, 30 - i, 7 - inset * 2, 1, i == h - 1 ? brown : gold)
        }
        c.px(44, 31 - h + 1, goldL)
    } else {
        c.rect(42, 31, 7, 1, gold); c.rect(44, 31, 3, 1, brown)
    }
    if s > 0.56 && s < 0.74 && Int(p.t * 8) % 2 == 0 { twinkle(c, 50, 24, C(0xFFE27A)) }
    if s > 0.8 {
        // The sad puff of steam.
        let k = (s - 0.8) / 0.16, y = Int(29 - k * 8)
        let col = C(0xE8E8F0, 0.7 * (1 - k))
        c.rect(44, y, 3, 2, col); c.px(43, y + 1, col); c.px(47, y, col)
    }
}

// MARK: - Madame Vasta

/// Madame Vasta: a Silurian lady: Clawd with green scaled skin and the ridged crest of her kind, a little black hat
/// with a lace veil down to her brow, a high-collared black Victorian dress with a full skirt down to the ground.
/// Fights with a katana, sheathed across her back between fights. Signature: the tongue flick: a long red tongue
/// darts out, twice.
private func drawVasta(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5E9A4A), skinD = C(0x3E7232), skinL = C(0x86BE6A), crestD = C(0x2E5A26)
    let dress = C(0x22202A), dressL = C(0x3A3644), dressD = C(0x141218), lace = C(0x16141A)
    let s = p.signature ?? -1
    // The katana's saya across her back, the hilt over her shoulder while the sword's in it.
    line(c, 15, 23, 29, 40, C(0x1A1418), 0.9)
    if p.melee == nil {
        line(c, 12, 19, 15, 23, C(0x2A2A30), 0.8)
        line(c, 13, 24, 16, 21, C(0xB8A040), 0.6)
    }
    // The skirt, to the ground; boot tips peek out under it as she walks.
    if seatedPose {
        c.rect(16, 37, 24, 3, dress); c.rect(16, 39, 24, 1, dressD)
    } else {
        for y in 37...42 {
            let k = (y - 37) / 2
            c.rect(18 - k, y, 20 + k * 2, 1, dress)
            c.px(37 + k, y, dressD)
        }
        for x in [21, 27, 33] { c.rect(x, 39, 1, 4, dressL) }
        let lift = p.step == 0 ? -1 : 0
        c.rect(22, 43 + lift, 3, 1, C(0x0E0E12)); c.rect(32, 43 + (p.step == 1 ? -1 : 0), 3, 1, C(0x0E0E12))
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: dress))
    // Scales on the face.
    for (x, y) in [(20, 27), (25, 28), (29, 27), (35, 28), (19, 31), (27, 30), (35, 31), (24, 32), (30, 32)] {
        c.px(x, y, skinD); c.px(x + 1, y, skinL)
    }
    // The crest: three ridged lobes over the head.
    c.pattern(18, 19, [
        "........GGGG........",
        "...GGG.GGgGGG.GGG...",
        "..GGgGGGGgGGGGGgGG..",
        ".GGGgGGGGgGGGGGgGGG.",
        "GGGGgGGGGgGGGGGgGGGG",
        "GGGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGGG",
    ], ["G": skin, "g": crestD])
    // The little hat, tipped forward, and its veil.
    c.pattern(23, 17, [
        "....KKKK..",
        "..KKKKKKKK",
        ".KKKKKKKKK",
        "KKKKKKKKKKKK",
        ".KKKKKKKKKKKKK",
    ], ["K": dressD])
    c.px(25, 18, C(0x6A2A5A)); c.px(26, 17, C(0x8A3A7A))   // a feather
    for y in 24...28 {
        for x in 21...38 where (x + y) % 2 == 0 && (y < 27 || x % 3 != 0) || y == 28 {
            c.px(x, y, lace.alpha(y == 28 ? 0.75 : 0.35))
        }
    }
    // The dress: high collar, bodice.
    c.rect(18, 32, 20, 5, dress)
    c.rect(21, 31, 14, 2, dress); c.rect(22, 31, 12, 1, dressL)
    c.rect(28, 33, 1, 4, dressL); c.px(28, 34, C(0x8A3A7A))   // the brooch
    c.rect(37, 32, 1, 5, dressD)
    c.rect(15, 33, 3, 3, dress)
    // The tongue: out and back, twice.
    if s > 0.1 && s < 0.9 {
        let k = frac((s - 0.1) / 0.8 * 2)
        let len = Int((sin(k * .pi) * 9).rounded())
        if len > 0 {
            c.rect(38, 31, len, 1, C(0xC8304A))
            if len > 6 { c.px(38 + len, 30, C(0xC8304A)); c.px(38 + len, 32, C(0xC8304A)) }
        }
    }
    if let a = p.melee {
        drawBlade(c, angle: a, trail: p.trail, length: 15, grip: C(0x1A1418), guardCol: C(0xB8A040), curve: 1.2)
        c.rect(38, 33, 3, 3, dress)
    } else if p.cheering {
        c.rect(38, 24, 3, 9, dress); c.rect(38, 22, 3, 2, skin)
    }
}

// MARK: - Jenny Flynt

/// Jenny Flynt: Clawd with brown hair pinned up in a bun under a frilled white maid's cap, in a sleek black catsuit
/// with a sheen, a black belt and boots. Fights with a sabre, its brass knuckle-bow round her hand; between fights it
/// hangs in its scabbard at her hip.
private func drawJenny(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1A1A22), suitL = C(0x3A3A48), hair = C(0x4A2E1E), hairL = C(0x6A4430), cap = C(0xF4F2EC)
    let brass = C(0xC8A040)
    if p.melee == nil {
        line(c, 30, 35, 42, 41, C(0x121216), 0.9); c.px(42, 41, brass)
        line(c, 29, 34, 27, 32, brass, 0.6)
    }
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx, 38, 1, 3, suitL) }
    }
    c.oy += p.breathe
    c.pattern(13, 21, [".HH.", "HHlH", "HHHH", ".HH."], ["H": hair, "l": hairL])   // the bun
    drawBody(c, Look(arm: suit))
    c.pattern(17, 19, [
        "....WWWWWWWWWWWW......",
        "...WwWwWwWwWwWwWW.....",
        "..HHHHHHHHHHHHHHHH....",
        ".HHHHHHHlHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHlHHHH..",
        "HHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHH.HHHH.........HHH.",
        "HHH...............HH..",
        "HH....................",
    ], ["H": hair, "l": hairL, "W": cap, "w": C(0xC8C4BC)])
    // The catsuit, its sheen and belt.
    c.rect(18, 32, 20, 6, suit)
    c.rect(20, 32, 1, 5, suitL); c.rect(26, 32, 4, 1, suitL)
    c.rect(18, 36, 20, 1, C(0x0E0E12)); c.rect(27, 36, 2, 1, brass)
    c.rect(15, 33, 3, 3, suit)
    if let a = p.melee {
        drawBlade(c, angle: a, trail: p.trail, length: 13, grip: C(0x2A1E16), guardCol: brass, curve: 0.8)
        // The knuckle-bow round the hand.
        let g = reach(hand, a, 2), b = reach(hand, a, -2.5)
        let r = a * .pi / 180, nx = -sin(r), ny = cos(r)
        line(c, g.x + nx * 1.5, g.y + ny * 1.5, b.x + nx * 1.5, b.y + ny * 1.5, brass, 0.5)
        c.rect(38, 33, 3, 3, suit)
    } else if p.cheering {
        c.rect(38, 24, 3, 9, suit); c.rect(38, 22, 3, 2, clawdOrange)
    }
}
