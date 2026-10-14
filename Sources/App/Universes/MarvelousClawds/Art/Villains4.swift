import Foundation

// Villains: the street, spies and soldiers.

let villains4: [MarvelVillain: Persona] = [
    .kingpin: Persona(name: "Kingping", weapon: .saber, pivot: (43.5, 33.5), bulk: 2, headTop: 20, signature: 3.0,
                  draw: drawKingpin),
    .bullseye: Persona(name: "Bullseyes", weapon: .blaster, shot: .thrown(C(0xC8CCD4)), muzzle: (46, 32), signature: 2.6,
                  draw: drawBullseye),
    .handNinja: Persona(name: "Palm Ninja", weapon: .saber, headTop: 22, signature: 2.6,
                  draw: drawHandNinja),
    .hydraAgent: Persona(name: "Hydrax Agent", weapon: .blaster, shot: .energy(core: C(0xE0F4FF), glow: C(0x3A9AFF)),
                  muzzle: (51, 31), signature: 2.6, callout: "Hail Hydrax!",
                  draw: drawHydraAgent),
    .aimAgent: Persona(name: "M.A.I.M. Agent", weapon: .blaster, shot: .energy(core: C(0xFFFBD0), glow: C(0xFFD21E)),
                  muzzle: (49, 32), headTop: 19, signature: 2.8,
                  draw: drawAimAgent),
    .skrull: Persona(name: "Skrall", weapon: .blaster, shot: .energy(core: C(0xE0FFE0), glow: C(0x3AE05A)),
                  muzzle: (47, 32), headTop: 23, signature: 3.0,
                  draw: drawSkrull),
    .taskmaster: Persona(name: "Taskminder", weapon: .saber, headTop: 19, signature: 2.6,
                  draw: drawTaskmaster),
    .zemo: Persona(name: "Baron Zeemo", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 22, signature: 2.4,
                  draw: drawZemo),
    .whiplash: Persona(name: "Whipcrack", weapon: .saber, headTop: 24, signature: 2.4,
                  draw: drawWhiplash),
    .mandarin: Persona(name: "Mandarine", weapon: .lightning, magic: Magic(core: C(0xFFF0E0), glow: C(0xFF5A3A), jagged: false),
                  pivot: (42, 34.5), headTop: 23, signature: 3.0,
                  draw: drawMandarin),
    .killmonger: Persona(name: "Kilmongre", weapon: .saber, armoured: true, headTop: 22, signature: 3.2,
                  draw: drawKillmonger),
    .batroc: Persona(name: "Batrok", weapon: .saber, pivot: (37, 37.5), headTop: 22, signature: 2.4,
                  draw: drawBatroc),
]

// MARK: - Shared bits

private let clear = C(0x000000, 0)

/// A solid pixel line (no glow), `r` its half-width.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

private func unit(_ degrees: Double) -> (x: Double, y: Double) {
    let r = degrees * .pi / 180
    return (cos(r), sin(r))
}

/// Ground level in the art's own coordinates (it drops out from under a breathing or seated body).
private func groundY(_ p: Pose) -> Double { 43.5 - Double(p.breathe) - (seatedPose ? 4 : 0) }

/// Boots (or shoes) on the bottom of the legs, following the walk cycle.
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

/// A fast swing's smear: faint copies of a `length` long weapon along the earlier angles.
private func drawSmear(_ c: PixelCanvas, at h: (x: Double, y: Double), _ trail: [Double], from r0: Double = 3,
                       length: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let u = unit(a)
        c.glowLine(h.x + u.x * r0, h.y + u.y * r0, h.x + u.x * (r0 + length), h.y + u.y * (r0 + length),
                   core: col.alpha(0.35 / Double(i + 1)), glow: col.alpha(0.18 / Double(i + 1)), coreR: 0.6, glowR: 1.6)
    }
}

/// A straight sword held at `h`: grip behind the fist, a crossguard, the blade, a bright point.
private func drawSword(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, trail: [Double], length: Double,
                       blade: Px, grip: Px, guard guardCol: Px?) {
    drawSmear(c, at: h, trail, length: length, blade)
    let u = unit(angle)
    line(c, h.x - u.x * 2.5, h.y - u.y * 2.5, h.x + u.x * 1.5, h.y + u.y * 1.5, grip, 0.75)
    if let g = guardCol {
        line(c, h.x + u.x * 2 - u.y * 2, h.y + u.y * 2 + u.x * 2, h.x + u.x * 2 + u.y * 2, h.y + u.y * 2 - u.x * 2, g, 0.6)
    }
    line(c, h.x + u.x * 2.5, h.y + u.y * 2.5, h.x + u.x * (2.5 + length), h.y + u.y * (2.5 + length), blade, 0.7)
    c.px(Int(h.x + u.x * (2 + length)), Int(h.y + u.y * (2 + length)), white)
}

/// A puff of smoke, `k` 0…1 from a tight cloud to a wide, faded one.
private func drawSmokePuff(_ c: PixelCanvas, x: Int, y: Int, _ k: Double) {
    let a = 1 - k
    for i in 0..<7 {
        let ang = Double(i) / 7 * 2 * .pi + 0.4
        let r = 2 + k * 9
        c.circle(x + Int(cos(ang) * r), y + Int(sin(ang) * r * 0.8), 3 + Int(k * 2), C(0x8A8A94).alpha(a * 0.85))
    }
    c.circle(x, y, 5 - Int(k * 3), C(0xC8C8D0).alpha(a))
}

// MARK: - Kingpin

/// Kingpin: a huge bald Clawd, wider than anyone, in a white suit with a purple ascot and pocket square, black shoes,
/// leaning on a black cane topped with a diamond. He clubs with the cane. Signature: taps the cane on the floor (the
/// diamond flashing), then tugs his lapels straight.
private func drawKingpin(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xF2F0EA), suitShade = C(0xC8C4BA), lapel = C(0xD8D4CA), purple = C(0x5A2A7A)
    let shoe = C(0x1A1A1E), cane = C(0x1E1E24)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, step: p.step, shoe, rows: 1)
    c.oy += p.breathe
    let sig = p.signature
    let tug = sig.map { $0 > 0.55 && $0 < 0.95 } ?? false

    // The big bald head and the shoulders of the suit, all one block.
    c.pattern(15, 20, [
        ".....SSSSSSSSSSSSSSSS.....",
        "...SSSSSSSSSSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSSSSSSs.",
        ".SSSSSSSSSSSSSSSSSSSSSSSs.",
        "SSSSSSSSSSSSSSSSSSSSSSSSss",
    ], ["S": clawdOrange, "s": clawdShade])
    c.rect(15, 25, 26, 6, clawdOrange)
    c.rect(40, 23, 1, 8, clawdShade)
    c.rect(20, 25, 5, 1, clawdShade); c.rect(31, 25, 5, 1, clawdShade)     // heavy brows
    c.rect(21, 26, 2, 3, ink); c.rect(32, 26, 2, 3, ink)
    c.rect(25, 29, 6, 1, clawdShade)                                     // a stern mouth
    // The white suit.
    c.rect(15, 31, 26, 7, suit)
    c.rect(40, 31, 1, 7, suitShade)
    c.rect(15, 37, 26, 1, suitShade)
    c.pattern(23, 31, ["LPPPPPPPPL", ".LPPPPPPL.", "..LPPPPL..", "...LLLL..."], ["P": purple, "L": lapel])
    c.px(28, 34, C(0x8A80A0)); c.px(28, 36, C(0x8A80A0))                 // buttons
    c.pattern(33, 32, ["PpP", "LLL"], ["P": purple, "p": C(0x8A4AAA), "L": lapel])   // pocket square
    // Arms: the left one goes up to tug a lapel in the signature.
    if tug {
        let y = Int(p.lt * 10) % 2
        c.rect(19, 31 + y, 4, 3, suit); c.rect(19, 31 + y, 1, 3, suitShade)
        c.rect(23, 31 + y, 2, 2, clawdOrange)
    } else {
        c.rect(12, 32, 3, 4, suit); c.rect(12, 35, 3, 1, suitShade)
    }
    c.rect(41, 31, 3, 4, suit); c.rect(41, 34, 3, 1, suitShade)

    let h = (x: 43.5, y: 33.5)
    if let a = p.melee {
        // Swung like a club, the diamond at the business end.
        drawSmear(c, at: h, p.trail, length: 14, C(0xC8D8F0))
        let u = unit(a)
        line(c, h.x - u.x * 2, h.y - u.y * 2, h.x + u.x * 14, h.y + u.y * 14, cane, 0.7)
        drawDiamond(c, x: Int(h.x + u.x * 15), y: Int(h.y + u.y * 15), glint: false)
        c.rect(42, 32, 3, 3, clawdOrange)
    } else {
        // Planted beside him, hand on the diamond. Signature: lifted and tapped down, three times.
        var lift = 0.0
        if let s = sig, s < 0.5 { lift = frac(s * 6) < 0.5 ? 2 : 0 }
        let foot = groundY(p) - lift
        line(c, h.x, h.y - 1 - lift, h.x, foot - 0.5, cane, 0.6)
        c.rect(42, 32 - Int(lift), 3, 3, clawdOrange)
        drawDiamond(c, x: 43, y: 30 - Int(lift), glint: sig != nil && lift == 0)
        if let s = sig, s < 0.5, lift == 0 {
            c.px(41, Int(foot), C(0xB8B0A0)); c.px(46, Int(foot), C(0xB8B0A0))
        }
    }
}

/// The diamond on top of Kingpin's cane, centred at (x, y).
private func drawDiamond(_ c: PixelCanvas, x: Int, y: Int, glint: Bool) {
    c.pattern(x - 1, y - 1, [".D.", "DdD", ".D."], ["D": C(0xBFE8FF), "d": white])
    if glint {
        c.px(x, y - 3, white.alpha(0.8)); c.px(x + 2, y - 2, white.alpha(0.6)); c.px(x - 2, y - 2, white.alpha(0.6))
    }
}

// MARK: - Bullseye

/// Bullseye: black from head to toe with a white bullseye target on the forehead and white eye pieces, a belt of
/// knives, a throwing knife ready in his hand. Signature: flips a playing card up into the air and catches it, twice.
private func drawBullseye(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1C1C24), shade = C(0x101016), grey = C(0x4A4A56), steel = C(0xC8CCD4), w = C(0xF2F2F4)
    drawLegs(c, Look(leg: black), step: p.step)
    drawBoots(c, step: p.step, grey, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(body: black, shade: shade, arm: black, eye: nil), armRight: p.signature != nil ? 1 : 0)
    c.pattern(18, 23, ["...KKKKKKKKKKKKKK...", ".KKKKKKKKKKKKKKKKKK.", "KKKKKKKKKKKKKKKKKKKK"], ["K": black])
    c.pattern(24, 21, [
        "..WWW..",
        ".WKKKW.",
        "WKWWWKW",
        "WKWRWKW",
        "WKWWWKW",
        ".WKKKW.",
        "..WWW..",
    ], ["W": w, "K": black, "R": C(0xE02A2A)])
    c.rect(22, 29, 2, 3, w); c.rect(32, 29, 2, 3, w)                          // white eye pieces
    c.rect(18, 35, 20, 1, grey)
    c.rect(21, 34, 1, 1, steel); c.rect(24, 34, 1, 1, steel)                  // knife handles in the belt
    if let s = p.signature {
        // A card flipped up out of the hand and caught.
        let k = frac(s * 2)
        let x = 41 + Int(sin(k * .pi) * 2), y = 31 - Int((sin(k * .pi) * 13).rounded())
        switch Int(s * 30) % 3 {
        case 0: c.pattern(x - 1, y - 1, ["WWW", "WRW"], ["W": w, "R": C(0xE02A2A)])
        case 1: c.pattern(x - 1, y - 1, ["WW", "WR", "WW"], ["W": w, "R": C(0xE02A2A)])
        default: c.rect(x, y - 1, 1, 3, C(0xB8B8C0))
        }
        return
    }
    guard p.recoil == 0 else { return }                                       // just thrown: the hand's empty
    c.oy += p.gunY
    c.pattern(39, 31, ["KKKSSSSs", "...ssss."], ["K": C(0x2A2A30), "S": steel, "s": C(0x8A909C)])
}

// MARK: - Hand Ninja

/// A ninja of the Hand: red hood and gi with a slit for the eyes, a black sash, hood tails fluttering behind, a katana
/// (stowed on its back). Signature: vanishes in a puff of smoke and reappears in another.
private func drawHandNinja(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xA81C1C), dark = C(0x7A1010), black = C(0x1A1416)
    var hidden = false
    if let s = p.signature {
        if s > 0.22, s < 0.48 { drawSmokePuff(c, x: 28, y: 32, (s - 0.22) / 0.26) }
        if s > 0.6, s < 0.82 { drawSmokePuff(c, x: 28, y: 32, (s - 0.6) / 0.22) }
        hidden = s > 0.27 && s < 0.66
    }
    guard !hidden else { return }
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, step: p.step, black, rows: 2)
    c.oy += p.breathe
    if p.melee == nil {                                                       // katana hilt over the shoulder
        line(c, 13.5, 20.5, 18, 25, black, 0.7)
        c.px(17, 25, C(0xC8A040)); c.px(18, 24, C(0xC8A040))
    }
    let flap = Int(p.lt * 6) % 2
    c.pattern(13, 24 + flap, ["RR...", ".RRR.", "..RRR"], ["R": dark])          // hood tails
    drawBody(c, Look(body: red, shade: dark, arm: red, eye: nil))
    c.pattern(18, 22, ["...RRRRRRRRRRRRRR...", ".RRRRRRRRRRRRRRRRRR.", "RRRRRRRRRRRRRRRRRRRR",
                       "RRRRRRRRRRRRRRRRRRRr"], ["R": red, "r": dark])
    c.rect(19, 28, 18, 4, clawdOrange)                                        // eye slit
    c.rect(36, 28, 1, 4, clawdShade)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, dark); c.rect(31, 28, 3, 1, dark)                    // a frown in the slit
    c.rect(18, 34, 20, 2, black)
    c.rect(20, 36, 1, 2, black); c.rect(22, 36, 1, 1, black)                  // sash knot ends
    if let a = p.melee {
        drawSword(c, at: Sprite.hand, angle: a, trail: p.trail, length: 15, blade: C(0xDDE2EA), grip: black,
                  guard: C(0xC8A040))
    }
}

// MARK: - Hydra Agent

/// A Hydra agent: green jumpsuit and hood, yellow goggles, a yellow belt and the red Hydra skull on the chest, a rifle
/// with a glowing blue power cell. Signature: slings the rifle and throws both arms up in the Hydra salute.
private func drawHydraAgent(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3E5E2A), shade = C(0x2C4620), yellow = C(0xE8C02A), red = C(0xC8202A), black = C(0x1A1A1E)
    let gun = C(0x2A2A30), cell = C(0x5AB8FF)
    let salute = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, step: p.step, black, rows: 2)
    c.oy += p.breathe
    if salute > 0 { line(c, 12, 37, 21, 23, gun, 0.8) }                       // rifle slung on the back
    drawBody(c, Look(body: green, shade: shade, arm: green, eye: nil))
    c.pattern(18, 23, ["...GGGGGGGGGGGGGG...", ".GGGGGGGGGGGGGGGGGG.", "GGGGGGGGGGGGGGGGGGGg"], ["G": green, "g": shade])
    c.rect(19, 28, 18, 4, ink)                                                // goggles
    c.rect(20, 29, 5, 2, yellow); c.rect(31, 29, 5, 2, yellow)
    c.px(20, 29, C(0xFFF2A0)); c.px(31, 29, C(0xFFF2A0))
    c.pattern(25, 32, [".RRRR.", "RKRRKR", ".RRRR.", "R.RR.R"], ["R": red, "K": black])   // the skull and tentacles
    c.rect(18, 36, 20, 1, yellow); c.rect(27, 36, 2, 1, black)
    if salute > 0 {
        // Both arms up, fists clenched: Hail Hydra.
        let up = 11 * salute
        line(c, 39.5, 34, 41 + 3 * salute, 34 - up, green, 1)
        line(c, 16.5, 34, 15 - 3 * salute, 34 - up, green, 1)
        c.rect(Int(41 + 3 * salute) - 1, Int(34 - up) - 2, 3, 3, black)
        c.rect(Int(15 - 3 * salute) - 1, Int(34 - up) - 2, 3, 3, black)
        return
    }
    c.oy += p.gunY
    c.pattern(37, 30, [
        "......SS......",
        "KKKKKKKKKKKKKK",
        "KKKBBBKKKKKKK.",
        "..KK..KK......",
    ], ["K": gun, "S": C(0x6A6E78), "B": cell])
}

// MARK: - A.I.M. Agent

/// An A.I.M. agent: the yellow beekeeper suit, a big boxy hood with a dark mesh visor, black gloves and belt, a
/// yellow ray gun. Signature: fiddles with a beeping gadget that suddenly sparks and makes it jump.
private func drawAimAgent(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xF0C82A), shade = C(0xC0981A), black = C(0x22221E), visor = C(0x24302C), mesh = C(0x41544A)
    drawLegs(c, Look(leg: yellow), step: p.step)
    drawBoots(c, step: p.step, black, rows: 2)
    c.oy += p.breathe
    var spark = false
    if let s = p.signature, s > 0.55, s < 0.75 { spark = true; c.ox += Int(p.lt * 30) % 2 == 0 ? 1 : -1 }
    drawBody(c, Look(body: yellow, shade: shade, arm: black, eye: nil))
    // The boxy hood, flaring over the shoulders.
    c.pattern(16, 19, [
        "..YYYYYYYYYYYYYYYYYY..",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        ".YYYYYYYYYYYYYYYYYYYs.",
        "YYYYYYYYYYYYYYYYYYYYYs",
        "YYYYYYYYYYYYYYYYYYYYYs",
        "ssssssssssssssssssssss",
    ], ["Y": yellow, "s": shade])
    c.rect(20, 22, 16, 7, visor)
    for y in stride(from: 22, through: 28, by: 2) { for x in stride(from: 20, through: 35, by: 2) { c.px(x, y, mesh) } }
    c.rect(23, 25, 2, 1, C(0x7A9A88)); c.rect(31, 25, 2, 1, C(0x7A9A88))     // eyes, dimly, behind the mesh
    c.rect(18, 35, 20, 1, black); c.rect(27, 35, 2, 1, C(0x8A8E98))
    if let s = p.signature {
        // The gadget: a little box with blinking lights and an antenna.
        c.pattern(38, 29, ["...A..", "...A..", "GGGGGG", "GrGgGG", "GGGGGG"],
                  ["G": C(0x6A6E78), "A": C(0x9AA0AE), "r": Int(s * 16) % 2 == 0 ? C(0xFF3A2A) : C(0x5A1A1A),
                   "g": Int(s * 16) % 2 == 1 ? C(0x3AE05A) : C(0x1A4A1A)])
        if spark { drawSparks(c, x: 41.5, y: 28.5, t: p.t, size: 4) }
        return
    }
    c.oy += p.gunY
    c.pattern(39, 30, ["..YYYYY...", "KKKKKKKKSS", "KK.YY.....", "KK........"], ["K": black, "Y": yellow, "S": C(0x8A8E98)])
}

// MARK: - Skrull

/// A Skrull: green skin, big pointed ears, a ridged chin, a purple uniform with a black collar, a green-glowing
/// blaster. Signature: shapeshifts, a ripple running down it until it's plain orange Clawd, then back.
private func drawSkrull(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5AA03A), gShade = C(0x3E7A28), purple = C(0x6A2A8A), pShade = C(0x4A1A62), black = C(0x1A1A22)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, step: p.step, black, rows: 2)
    c.oy += p.breathe
    // How far down the shapeshift has rippled (26 = not at all, 38 = all the way).
    var wave = 26
    if let s = p.signature { wave = 26 + Int((12 * habitArc(s, hold: 0.3)).rounded()) }
    if wave <= 27 {
        c.pattern(14, 24, ["G...", "GG..", ".GGG", ".GGg", "..gg"], ["G": green, "g": gShade])
        c.pattern(38, 24, ["...G", "..GG", "GGG.", "gGG.", "gg.."], ["G": green, "g": gShade])
    }
    drawBody(c, Look(body: green, shade: gShade, arm: purple, eye: nil))
    c.rect(21, 28, 4, 1, gShade); c.rect(31, 28, 4, 1, gShade)               // the heavy brow
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    for x in stride(from: 24, through: 31, by: 2) { c.rect(x, 32, 1, 2, gShade) }   // the ridged chin
    c.rect(18, 34, 20, 4, purple)
    c.rect(18, 34, 20, 1, black)
    c.rect(37, 34, 1, 4, pShade)
    c.rect(26, 35, 4, 1, black)
    if wave > 26 {
        // Everything above the ripple is Clawd already.
        c.rect(18, 26, 20, wave - 26, clawdOrange)
        c.rect(37, 26, 1, wave - 26, clawdShade)
        if wave > 29 { c.rect(22, 29, 2, min(3, wave - 29), ink); c.rect(32, 29, 2, min(3, wave - 29), ink) }
        if wave < 38 {
            for x in 18...37 { c.px(x, wave + (x + Int(p.lt * 12)) % 2 - 1, (x % 3 == 0 ? white : C(0xB8F0A0)).alpha(0.8)) }
        }
    }
    c.oy += p.gunY
    c.pattern(39, 31, [".PPPPPg", "KKKKKKG", "KK.....", "KK....."], ["P": purple, "K": black, "G": C(0x3AE05A), "g": C(0x9AF0A0)])
}

// MARK: - Taskmaster

/// Taskmaster: a white hood and cape framing a grinning skull mask, a navy tunic with orange gloves and boots, a
/// round steel shield on the left arm and a sword. Signature: mimics Captain America, bringing the shield round to
/// the front and setting his stance behind it.
private func drawTaskmaster(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x2A3A8A), nShade = C(0x1E2A66), orange = C(0xE07A1A), bone = C(0xEEE8D6), boneShade = C(0xC8C0AA)
    let hood = C(0xF4F4F6), hoodShade = C(0xC8CCD4)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: C(0xD4D6DE), edge: C(0x9A9EAA))
    drawLegs(c, Look(leg: navy), step: p.step)
    drawBoots(c, step: p.step, orange, rows: 3)
    c.oy += p.breathe
    let capPose = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawBody(c, Look(body: navy, shade: nShade, arm: orange, eye: nil))
    c.rect(18, 26, 20, 8, bone)
    c.rect(37, 26, 1, 8, boneShade)
    c.rect(21, 28, 4, 3, ink); c.rect(31, 28, 4, 3, ink)                      // eye sockets
    c.px(27, 31, ink); c.px(28, 31, ink)
    c.pattern(22, 32, ["KbKbKbKbKbKb", ".K.K.K.K.K.K"], ["K": ink, "b": bone])
    drawHood(c, hood, hoodShade)
    c.rect(18, 35, 20, 1, ink); c.rect(27, 35, 2, 1, C(0xC8CCD4))
    let h = Sprite.hand
    if let a = p.melee, capPose == 0 {
        drawSword(c, at: h, angle: a, trail: p.trail, length: 14, blade: C(0xD8DCE4), grip: C(0x3A2A1A), guard: orange)
    } else {
        // Point down at his side.
        let u = unit(100)
        line(c, h.x - u.x * 2, h.y - u.y * 2, h.x + u.x * 8, h.y + u.y * 8, C(0xD8DCE4), 0.6)
        c.px(Int(h.x), Int(h.y) + 1, orange)
    }
    // The shield: on the left arm, or swung round to the front.
    let sx = Int((14 + 26 * capPose).rounded()), sy = Int((33 - 3 * capPose).rounded())
    c.circle(sx, sy, 4, C(0x5A5E68))
    c.circle(sx, sy, 3, C(0xC8CCD4))
    c.circle(sx, sy, 1, navy)
    c.px(sx, sy, white)
    if capPose > 0.9 { c.px(sx - 2, sy - 2, white); c.px(sx - 1, sy - 3, white.alpha(0.6)) }
}

// MARK: - Baron Zemo

/// Baron Zemo: the purple hooded mask with a gold crown band and eye holes, a tawny fur collar, a purple bodysuit
/// with a gold belt, a Luger pistol. Signature: reaches up and tugs his mask straight.
private func drawZemo(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2A7A), pShade = C(0x4E1A5C), gold = C(0xE8C02A), fur = C(0xC8B48A), furShade = C(0xA08E68)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, step: p.step, pShade, rows: 2)
    c.oy += p.breathe
    var tug = 0, reach = 0
    if let s = p.signature {
        reach = Int((6 * habitArc(s, hold: 0.6)).rounded())
        if s > 0.3, s < 0.75, frac(s * 5) < 0.5 { tug = 1 }
    }
    drawBody(c, Look(body: purple, shade: pShade, arm: purple, eye: nil), armLeft: reach)
    c.oy += tug
    c.pattern(18, 23, ["...PPPPPPPPPPPPPP...", ".PPPPPPPPPPPPPPPPPP.", "PPPPPPPPPPPPPPPPPPPp"], ["P": purple, "p": pShade])
    c.pattern(18, 24, ["....G....G....G....", ".GGGGGGGGGGGGGGGGGG."], ["G": gold])
    c.rect(18, 26, 20, 1, gold)
    for x in [21, 31] { c.rect(x, 28, 4, 3, clawdOrange); c.rect(x + 1, 29, 2, 2, ink) }
    c.oy -= tug
    if reach > 4 { c.rect(16, 26, 2, 3, purple) }                            // fingers on the mask's edge
    c.pattern(17, 32, ["FFfFFfFFfFFfFFfFFfFFfF", ".fFFfFFfFFfFFfFFfFFfF."], ["F": fur, "f": furShade])
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, C(0xFFF2A0))
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 31)
}

// MARK: - Whiplash

/// Whiplash (Ivan Vanko): cropped dark hair and stubble, a grey harness with an arc reactor glowing on the chest,
/// metal gauntlets, and two crackling electric whips that trail on the floor until he swings one. Signature: whirls
/// both whips up overhead and cracks them forward in a burst of sparks.
private func drawWhiplash(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x2A2420), harness = C(0x3A3A40), strap = C(0x22222A), metal = C(0x8A8E98)
    drawLegs(c, Look(leg: harness), step: p.step)
    drawBoots(c, step: p.step, strap, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: metal, eye: nil))
    c.pattern(18, 24, ["..HHHHHHHHHHHHHHHH..", "HHHHHHHHHHHHHHHHHHHH", "HHHHHHHHHHHHHHHHHHHH", "H.H................H"],
              ["H": hair])
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, clawdShade); c.rect(32, 28, 3, 1, clawdShade)
    for x in stride(from: 21, through: 34, by: 2) { c.px(x + (x / 2) % 2, 33, C(0x8A4A30)) }   // stubble
    c.rect(18, 34, 20, 4, harness)
    c.rect(37, 34, 1, 4, strap)
    line(c, 19, 33.5, 26, 35, strap, 0.5); line(c, 36, 33.5, 30, 35, strap, 0.5)
    c.glowLine(28, 35.5, 28, 35.5, core: C(0xE8FAFF), glow: C(0x3AAAFF), coreR: 1, glowR: 2.2,
               strength: 0.85 + 0.15 * sin(p.t * 9))
    c.rect(38, 33, 3, 3, metal); c.rect(40, 34, 1, 1, C(0x5A5E68))

    let right = Sprite.hand, left = (x: 16.0, y: 34.5)
    let floor = groundY(p) - 0.5
    var crack: Double?
    if let s = p.signature, p.melee == nil {
        // Up and round behind, then lashed forward.
        let k = min(1, max(0, (s - 0.1) / 0.45))
        let back = min(1, max(0, (s - 0.75) / 0.25))
        crack = -150 + 165 * (1 - pow(1 - k, 3)) + 100 * back
    }
    if let a = crack ?? p.melee {
        let swing = crack != nil
        for (i, b) in p.trail.enumerated() {
            drawWhip(c, from: right, angle: b, length: 18, curl: 3, t: p.t, strength: 0.3 / Double(i + 1))
        }
        drawWhip(c, from: right, angle: a, length: 18, curl: 3 * sin(p.t * 7), t: p.t)
        if swing {
            drawWhip(c, from: left, angle: a + 12, length: 16, curl: -3, t: p.t + 1)
            if let s = p.signature, s > 0.5, s < 0.68 {
                let u = unit(a)
                drawSparks(c, x: right.x + u.x * 18, y: right.y + u.y * 18, t: p.t, size: 4)
            }
        } else {
            drawRestingWhip(c, from: left, toward: -1, floor: floor, t: p.t)
        }
    } else {
        drawRestingWhip(c, from: right, toward: 1, floor: floor, t: p.t)
        drawRestingWhip(c, from: left, toward: -1, floor: floor, t: p.t + 0.5)
    }
}

/// One of Whiplash's whips, lashed out from `h` at `angle`, bowing sideways by `curl` pixels and crackling.
private func drawWhip(_ c: PixelCanvas, from h: (x: Double, y: Double), angle: Double, length: Double, curl: Double,
                      t: Double, strength: Double = 1) {
    let u = unit(angle), n = (x: -u.y, y: u.x)
    var prev = h
    let n0 = 10, seed = Int(t * 24)
    for i in 1...n0 {
        let f = Double(i) / Double(n0)
        let bow = curl * sin(f * .pi) + (noise(seed + i) - 0.5) * 1.2 * f
        let q = (x: h.x + u.x * length * f + n.x * bow, y: h.y + u.y * length * f + n.y * bow)
        c.glowLine(prev.x, prev.y, q.x, q.y, core: C(0xE8F8FF), glow: C(0x3AAAFF), coreR: 0.45, glowR: 1.7,
                   strength: strength)
        prev = q
    }
}

/// A whip at rest: hanging from the hand and trailing along the floor, faintly crackling. `toward`: ±1, which way.
private func drawRestingWhip(_ c: PixelCanvas, from h: (x: Double, y: Double), toward: Double, floor: Double, t: Double) {
    let pts = [h, (x: h.x + 2 * toward, y: floor - 2), (x: h.x + 5 * toward, y: floor), (x: h.x + 11 * toward, y: floor)]
    for i in 1..<pts.count {
        c.glowLine(pts[i - 1].x, pts[i - 1].y, pts[i].x, pts[i].y, core: C(0xC8E8FF), glow: C(0x3AAAFF),
                   coreR: 0.4, glowR: 1.3, strength: 0.6)
    }
    let i = Int(t * 14)
    if noise(i) > 0.5 {
        let f = noise(i + 3)
        c.px(Int(h.x + (2 + 9 * f) * toward), Int(floor) - 1 - Int(noise(i + 5) * 2), white)
    }
}

// MARK: - Mandarin

/// The Mandarin: swept-back black hair, a dark green tunic with a high gold-edged collar and gold trim, and ten
/// rings of power on his fists, each its own colour; he casts from the right hand. Signature: both fists raised,
/// the ten rings flare one after another.
private func drawMandarin(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x1E5A34), rShade = C(0x143E24), gold = C(0xE8B530), hair = C(0x1A1614)
    let rings = [C(0xFF3A2A), C(0xFF9A2A), C(0xFFE03A), C(0x3AE05A), C(0x3AE0E0),
                 C(0x3A7AFF), C(0xA04AFF), C(0xF4F4F8), C(0xFF6AC8), C(0x8A5A3A)]
    drawLegs(c, Look(leg: rShade), step: p.step)
    drawBoots(c, step: p.step, ink, rows: 2)
    c.oy += p.breathe
    let raise = p.signature.map { Int((3 * habitArc($0, hold: 0.8)).rounded()) } ?? 0
    let rightUp = max(p.armRaise, raise), leftUp = raise
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: robe, eye: ink), armLeft: leftUp, armRight: rightUp)
    c.pattern(18, 23, ["....HHHHHHHHHHHH....", "..HHHHHHHHHHHHHHHH..", ".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH",
                       "HH................HH", "H..................H"], ["H": hair])
    c.rect(21, 28, 3, 1, clawdShade); c.rect(32, 28, 3, 1, clawdShade)
    c.rect(18, 32, 20, 6, robe)
    c.rect(37, 32, 1, 6, rShade)
    c.rect(18, 32, 20, 1, gold)                                               // the high collar
    c.rect(27, 33, 2, 5, gold)
    c.px(25, 34, gold); c.px(30, 34, gold); c.px(25, 36, gold); c.px(30, 36, gold)
    // Fists and their rings: five on each.
    let hands = [(x: 13, y: 33 - leftUp), (x: 41, y: 33 - rightUp)]
    let spots = [(0, 0), (1, 0), (0, 1), (1, 2), (0, 2)]
    let lit = p.signature.map { Int($0 * 11) - 1 }
    for (k, hd) in hands.enumerated() {
        c.rect(hd.x, hd.y, 2, 3, clawdOrange)
        for (j, s) in spots.enumerated() {
            let i = k * 5 + j, x = hd.x + s.0, y = hd.y + s.1
            c.px(x, y, rings[i])
            if lit == i { c.glowLine(Double(x) + 0.5, Double(y) + 0.5, Double(x) + 0.5, Double(y) + 0.5,
                                     core: white, glow: rings[i], coreR: 0.8, glowR: 3.2) }
        }
    }
}

// MARK: - Killmonger

/// Killmonger in his golden-jaguar suit: black panther armour traced with gold, a panther helmet with pointed ears
/// and gold-rimmed white eyes, a gold-tipped vibranium spear. Signature: the helmet slides away to show his face,
/// then slides back on.
private func drawKillmonger(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1A1A20), shade = C(0x101014), gold = C(0xE8B530), goldDark = C(0xB08420), lens = C(0xF4F4F0)
    drawLegs(c, Look(leg: black), step: p.step)
    for lx in [19, 31] where !seatedPose { c.rect(lx, 38, 1, 4, goldDark) }
    c.oy += p.breathe
    drawBody(c, Look(body: black, shade: shade, arm: black, eye: nil))
    // Signature: the face under the helmet, uncovered from the top down.
    var cut = 22
    if let s = p.signature {
        cut = 22 + Int((12 * habitArc(s, hold: 0.45)).rounded())
        c.rect(18, 26, 20, 8, clawdOrange); c.rect(37, 26, 1, 8, clawdShade)
        c.pattern(19, 24, ["..KKKKKKKKKKKKKK..", "KKKKKKKKKKKKKKKKKK", "KKKKKKKKKKKKKKKKKK"], ["K": C(0x16120E)])
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.rect(21, 28, 3, 1, clawdShade); c.rect(32, 28, 3, 1, clawdShade)
        c.px(31, 27, clawdShade); c.px(30, 28, clawdShade)                   // a scar or two
        c.rect(25, 33, 6, 1, C(0x16120E))                                     // goatee
    }
    let helmet = [
        "..K..............K..",
        ".KGK............KGK.",
        ".KKKKKKKKKKKKKKKKKK.",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKGGKKKKKKKKK",
        "KKKKKKKKKGGKKKKKKKKK",
        "KKGGGKKKKKKKKKKGGGKK",
        "KKGLLLGKKKKKKGLLLGKK",
        "KKKGLLLGKKKKGLLLGKKK",
        "KKKKGGGKKKKKKGGGKKKK",
        "KKKKKKKKKGGKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
    ]
    let start = cut - 22
    if start < helmet.count {
        c.pattern(18, cut, Array(helmet[start...]), ["K": black, "G": gold, "L": lens])
        if start > 0 { c.rect(18, cut, 20, 1, gold.alpha(0.8)) }             // the nanite edge
    }
    // The golden necklace pattern and trim.
    c.pattern(19, 34, ["GG.G.G.G.G.G.G.G.GG", "..G.G.G.G.G.G.G.G.."], ["G": gold])
    c.rect(18, 37, 20, 1, goldDark)
    c.px(39, 34, gold); c.px(16, 34, gold)
    // The spear.
    let h = Sprite.hand
    let a = p.melee ?? -84
    drawSmear(c, at: h, p.trail, length: 18, C(0xC8CCD4))
    let u = unit(a)
    line(c, h.x - u.x * 7, h.y - u.y * 7, h.x + u.x * 15, h.y + u.y * 15, C(0x3A3A46), 0.6)
    line(c, h.x + u.x * 15, h.y + u.y * 15, h.x + u.x * 19, h.y + u.y * 19, gold, 0.8)
    c.px(Int(h.x + u.x * 19.5), Int(h.y + u.y * 19.5), C(0xFFF2B0))
    c.rect(40, 33, 2, 3, black)
}

// MARK: - Batroc

/// Batroc the Leaper: a purple hood-mask over the eyes, a magnificent black handlebar moustache, a purple suit with
/// a yellow belt, yellow gloves and boots. He fights with his feet: the melee "weapon" is a savate
/// kick from the hip. Signature: a high kick held at the top, with a little sparkling "Z" flourish and a twirl of the
/// moustache.
private func drawBatroc(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2A8A), pShade = C(0x4A1A62), yellow = C(0xF0C830), yShade = C(0xC09A20)
    let tache = C(0x16120E)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, step: p.step, yellow, rows: 3)
    c.oy += p.breathe
    var kick = p.melee.map { a -> Double in
        var a = a.truncatingRemainder(dividingBy: 360)
        if a > 180 { a -= 360 } else if a < -180 { a += 360 }
        return min(20, max(-55, a < -135 || a > 135 ? -55 : a))
    }
    var flourish: Double?
    if let s = p.signature, kick == nil {
        kick = 20 - 75 * habitArc(s, hold: 0.45)
        if s > 0.35, s < 0.8 { flourish = (s - 0.35) / 0.45 }
    }
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: yellow, eye: nil))
    c.pattern(18, 23, ["...PPPPPPPPPPPPPP...", ".PPPPPPPPPPPPPPPPPP.", "PPPPPPPPPPPPPPPPPPPp"], ["P": purple, "p": pShade])
    c.rect(18, 26, 20, 5, purple)
    c.rect(37, 26, 1, 5, pShade)
    for x in [21, 31] { c.rect(x, 28, 4, 2, white); c.rect(x + 1, 28, 2, 2, ink) }
    let twirl = flourish != nil
    c.pattern(21, 31, twirl ? ["T..........T", "TTTTTTTTTTTT", "...TT..TT..."] : [".TTTTTTTTTT.", "TTTT....TTTT", "T..........T"],
              ["T": tache])
    c.rect(27, 33, 2, 1, tache)
    c.rect(18, 34, 20, 4, purple)
    c.rect(37, 34, 1, 4, pShade)
    c.rect(18, 36, 20, 1, yellow); c.rect(27, 36, 2, 1, yShade)
    guard let a = kick else { return }
    // The kicking leg, from the hip.
    let h = (x: 37.0, y: 37.5)
    drawSmear(c, at: h, p.trail.map { min(20, max(-55, $0)) }, from: 1, length: 10, purple)
    let u = unit(a)
    line(c, h.x, h.y, h.x + u.x * 8, h.y + u.y * 8, purple, 1.1)
    line(c, h.x + u.x * 8, h.y + u.y * 8, h.x + u.x * 11, h.y + u.y * 11, yellow, 1.2)
    if let f = flourish {
        let x = Int(h.x + u.x * 11) + 2 + Int(f * 3), y = Int(h.y + u.y * 11) - 4 - Int(f * 4)
        let col = C(0xFFF2A0).alpha(f > 0.7 ? (1 - f) / 0.3 : 1)
        c.pattern(x, y, ["ZZZZ", "..Z.", ".Z..", "ZZZZ"], ["Z": col])
        c.px(x - 2, y + 1, white.alpha(0.6)); c.px(x + 5, y + 3, white.alpha(0.6))
    }
}
