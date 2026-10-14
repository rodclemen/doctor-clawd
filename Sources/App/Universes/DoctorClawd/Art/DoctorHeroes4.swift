import Foundation

// Heroes: the companions of the early years, the schoolteachers, the Highlander, the Brigadier and Leelah. Clawd in
// costume, every one of them, with Clawd's own orange face showing. Most don't fight at all: they run, and point at
// whatever the Doctor ought to be looking at. Ian punches, Jamie has his dirk, the Brigadier his service pistol and
// Leelah her knives.

let doctorHeroes4: [DoctorHero: Persona] = [
    .susan: Persona(name: "Susan Foreclaw", headTop: 21,
                  draw: drawSusan),
    .ian: Persona(name: "Ian Chesterclawd", weapon: .saber, headTop: 22,
                  draw: drawIan),
    .barbara: Persona(name: "Barbara Rite", headTop: 15,
                  draw: drawBarbara),
    .jamie: Persona(name: "Jamie McCrabmon", weapon: .saber, headTop: 20, signature: 2.8,
                  draw: drawJamie),
    .zoe: Persona(name: "Zoe Hairiot", headTop: 21, signature: 3.0,
                  draw: drawZoe),
    .brigadier: Persona(name: "Brigadier Lethbridge-Stewed", weapon: .blaster, shot: .bullet, muzzle: (47, 33),
                  headTop: 20, signature: 2.6, callout: "Five rounds rapid",
                  draw: drawBrigadier),
    .jo: Persona(name: "Jo Grunt", headTop: 21,
                  draw: drawJo),
    .sarahJane: Persona(name: "Sarah Jane Smythe", headTop: 21,
                  draw: drawSarahJane),
    .leelah: Persona(name: "Leelah", weapon: .blaster, shot: .thrown(C(0xDCE0E8)), muzzle: (45, 31), headTop: 20,
                  signature: 2.6,
                  draw: drawLeelah),
]

// MARK: - Shared bits

private let clear = C(0x000000, 0)

/// Shoes (or boots, `rows` high) on the bottom of the legs, following the walk cycle; tucked forward when sitting.
private func drawShoes(_ c: PixelCanvas, step: Int, _ col: Px, rows: Int = 1) {
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx + 2, 38, 1, 2, col) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// Clawd's eyes, blinking now and then, screwed shut when hit.
private func drawEyes(_ c: PixelCanvas, _ p: Pose) {
    if p.hit {
        for x in [22, 32] { c.rect(x, 30, 2, 1, ink) }
        return
    }
    let blink = !p.walking && frac(p.lt / 4.7) < 0.03
    for x in [22, 32] { c.rect(x, blink ? 31 : 29, 2, blink ? 1 : 3, ink) }
}

private enum Arm { case up, point, down }

/// What a companion's free right arm is doing: thrown up cheering, pointing ahead while busy or waiting, or down.
private func companionArm(_ p: Pose) -> Arm {
    if p.cheering { return .up }
    if p.ready || (p.mode == .working && !p.walking) { return .point }
    return .down
}

/// Draws a companion's right arm in `sleeve` (the body's arm nub was drawn raised to match with `armLift`).
private func drawArm(_ c: PixelCanvas, _ p: Pose, _ arm: Arm, sleeve: Px) {
    switch arm {
    case .up:
        c.rect(38, 24, 3, 9, sleeve); c.rect(38, 22, 3, 2, clawdOrange)
    case .point:
        let wave = p.urgent && Int(p.t * 6) % 2 == 0 ? 1 : 0
        c.rect(38, 31 - wave, 4, 3, sleeve)
        c.rect(42, 31 - wave, 2, 3, clawdOrange); c.rect(44, 31 - wave, 2, 1, clawdOrange)
    case .down:
        c.rect(38, 33, 3, 3, sleeve); c.rect(38, 35, 3, 1, clawdOrange)
    }
}

private func armLift(_ arm: Arm) -> Int { arm == .down ? 0 : 2 }

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

// MARK: - Susan Foreclaw

/// Susan Foreclaw: the Doctor's granddaughter, a 1960s schoolgirl. A short black pixie crop with a ragged fringe, a
/// dark pullover with a white Peter Pan collar, grey checked slacks and black flats; a red school book under her hand
/// when she isn't pointing at something.
private func drawSusan(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x1A1618), hairLight = C(0x3A3236), jumper = C(0x34384E), jumperDark = C(0x24283A)
    let collar = C(0xF2EFE8), slacks = C(0x5A5A66), check = C(0x74747E)
    drawLegs(c, Look(leg: slacks), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 38, check); c.px(lx + 1, 40, check) } }
    drawShoes(c, step: p.step, C(0x141418))
    c.oy += p.breathe
    let arm = companionArm(p)
    drawBody(c, Look(arm: jumper, eye: nil), armRight: armLift(arm))
    // The pullover, ribbed at the hem, and its round white collar.
    c.rect(18, 33, 20, 5, jumper); c.rect(37, 33, 1, 5, jumperDark)
    c.rect(18, 37, 20, 1, jumperDark)
    for x in stride(from: 19, to: 37, by: 2) { c.px(x, 37, jumper) }
    c.pattern(23, 33, ["WWW..WWW", ".WWWWWW.", "..W..W.."], ["W": collar])
    c.rect(15, 33, 3, 3, jumper); c.rect(15, 35, 3, 1, clawdOrange)
    // The crop.
    c.pattern(17, 21, [
        "....HHHHHHHHHHHHH.....",
        "..HHHHHHHHHHHHHHHHH...",
        ".HHHHhHHHHHHHHHHhHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHhHHHHHHHHHHH",
        "HHHHHH.HHH.HHH..HHHHHH",
        "HHH..H...H.........HHH",
        "HH..................HH",
        "HH..................HH",
        ".H..................H.",
    ], ["H": hair, "h": hairLight])
    drawEyes(c, p)
    drawArm(c, p, arm, sleeve: jumper)
    if arm == .down {
        // The school book, held against her side.
        c.rect(40, 31, 2, 7, C(0xA82A2A)); c.rect(41, 31, 1, 7, C(0x7A1A1A)); c.px(40, 33, C(0xE8D8A8))
        c.rect(39, 34, 2, 2, clawdOrange)
    }
}

// MARK: - Ian Chesterclawd

/// Ian Chesterclawd: the science master, neat short dark hair with a side parting, a brown tweed sports jacket over a
/// white shirt and a dark knitted tie, grey flannels and brown brogues. He fights the old-fashioned way, with a
/// straight right: a tweed sleeve and a balled fist.
private func drawIan(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x2A1E16), hairLight = C(0x4A382A), tweed = C(0x7A6648), tweedDark = C(0x5A4A32), fleck = C(0x9A845E)
    let shirt = C(0xF2EFE8), tie = C(0x22283E), flannel = C(0x5E5E68)
    drawLegs(c, Look(leg: flannel), step: p.step)
    drawShoes(c, step: p.step, C(0x5A341C), rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: tweed, eye: nil))
    // The jacket: flecked tweed, open over the shirt and tie.
    c.rect(18, 33, 20, 5, tweed)
    for k in 0..<9 { c.px(19 + Int(noise(k * 3 + 1) * 18), 33 + Int(noise(k * 5 + 2) * 5), fleck) }
    c.rect(37, 33, 1, 5, tweedDark); c.rect(18, 37, 20, 1, tweedDark)
    c.pattern(24, 33, ["SSSSSSSS", ".SSTTSS.", "..STTS..", "...TT..."], ["S": shirt, "T": tie])
    c.rect(23, 33, 1, 3, tweedDark); c.rect(32, 33, 1, 3, tweedDark)          // the lapels
    c.px(29, 36, C(0x3A2A1A))                                                  // a button
    c.rect(15, 33, 3, 3, tweed); c.rect(15, 35, 3, 1, clawdOrange)
    // Short back and sides, parted on the left.
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHH....",
        ".HHHHpHHHHhHHHHHHH..",
        "HHHHHpHHHHHHHHHHHHHH",
        "HHhHHHHHHHHHHHHHHHHH",
        "HH...............HHH",
        "H..................H",
    ], ["H": hair, "h": hairLight, "p": hairLight])
    drawEyes(c, p)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawFist(c, angle: ta, alpha: 0.35 / Double(i + 1), sleeve: tweed) }
        drawFist(c, angle: a, sleeve: tweed)
    } else {
        c.rect(38, 33, 3, 3, tweed); c.rect(38, 35, 3, 1, clawdOrange)
    }
}

/// Ian's punch: a tweed sleeve, a white cuff and a balled fist out from the hand at `angle` degrees.
private func drawFist(_ c: PixelCanvas, angle: Double, alpha: Double = 1, sleeve: Px) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        s.rect(17, 19, 5, 3, sleeve)
        s.rect(22, 19, 1, 3, C(0xF2EFE8))
        s.rect(23, 18, 4, 5, clawdOrange)
        s.rect(26, 18, 1, 5, clawdShade)
        s.px(24, 19, clawdShade); s.px(24, 21, clawdShade)
    }
}

// MARK: - Barbara Rite

/// Barbara Rite: the history mistress, a tall dark-brown beehive with a pale-blue band and the ends flicked out at the
/// neck, a powder-blue twin-set with a string of pearls, a grey pencil skirt and black court shoes. A handbag on her
/// arm when she isn't pointing.
private func drawBarbara(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x4A2E1E), hairLight = C(0x6E4A30), band = C(0xA8C8F0), twin = C(0x86A6D4), twinDark = C(0x6484B4)
    let skirt = C(0x5A5A64), skirtDark = C(0x46464E), pearl = C(0xF6F2E6)
    drawLegs(c, Look(), step: p.step)
    drawShoes(c, step: p.step, C(0x141418))
    c.oy += p.breathe
    let arm = companionArm(p)
    drawBody(c, Look(arm: twin, eye: nil), armRight: armLift(arm))
    // The twin-set, the pearls, the pencil skirt (to just above the knee).
    c.rect(18, 33, 20, 3, twin); c.rect(37, 33, 1, 3, twinDark)
    c.rect(24, 33, 8, 1, twinDark)
    for x in stride(from: 24, through: 31, by: 2) { c.px(x, 34, pearl) }
    c.rect(18, 36, 20, seatedPose ? 2 : 3, skirt); c.rect(37, 36, 1, seatedPose ? 2 : 3, skirtDark)
    c.rect(18, 36, 20, 1, skirtDark)
    c.rect(15, 33, 3, 3, twin); c.rect(15, 35, 3, 1, clawdOrange)
    // The beehive.
    c.pattern(17, 15, [
        ".......HHHHHHHH.......",
        ".....HHHHHHHHHHHH.....",
        "....HHHHHhHHHHHHHH....",
        "....HHHHHHHHHHhHHH....",
        "...HHHhHHHHHHHHHHHH...",
        "...HHHHHHHHHHHHHhHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".BBBBBBBBBBBBBBBBBBBB.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHhHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHhHHHH",
        "HHHHHH..........HHHHHH",
        "HHHH..............HHHH",
        "HHH................HHH",
        "HHH................HHH",
        ".HH................HH.",
        "HHH................HHH",
    ], ["H": hair, "h": hairLight, "B": band])
    drawEyes(c, p)
    drawArm(c, p, arm, sleeve: twin)
    if arm == .down {
        // The handbag, hanging from her wrist.
        c.px(40, 35, C(0x2A1A12)); c.px(42, 35, C(0x2A1A12))
        c.rect(39, 36, 5, 4, C(0x3A2418)); c.rect(39, 36, 5, 1, C(0x5A3A26)); c.px(41, 37, C(0xC8A040))
    }
}

// MARK: - Jamie McCrabmon

/// Jamie McCrabmon: the young Highlander, a shaggy black mop, a loose white shirt, a red tartan kilt with a white
/// sporran, bare knees, cream hose with red flashes and black brogues; he fights with his dirk. Signature: the
/// Highland charge: the dirk goes up overhead, he yells and pelts forward, then strolls back.
private func drawJamie(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x16141A), hairLight = C(0x34303A), shirt = C(0xEEE8D6), shirtDark = C(0xC8C0A8)
    let tartan = C(0xB8242A), tartanDark = C(0x7A141A), sett = C(0x1E3E2A), stripe = C(0xE8C84A)
    let hose = C(0xE8DFC8), flash = C(0xC8282E)
    let s = p.signature
    var charging = false, yell = false, raised = false
    if let s = s {
        raised = s > 0.08 && s < 0.7
        yell = s > 0.12 && s < 0.66
        charging = s > 0.2 && s < 0.6
        // Out and back: a dash forward, a held pose, then a walk back to his place.
        let out: Double = s < 0.2 ? 0 : s < 0.5 ? (s - 0.2) / 0.3 : s < 0.7 ? 1 : max(0, 1 - (s - 0.7) / 0.3)
        c.ox += Int((7 * out).rounded())
    }
    let step = charging ? Int(p.t * 14) % 2 : (s.map { $0 > 0.7 && $0 < 0.98 } ?? false) ? Int(p.t * 8) % 2 : p.step
    drawLegs(c, Look(), step: step)
    if !seatedPose {
        // Hose to below the knee, flashes at the garters.
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = step >= 0 && i % 2 == step ? 39 : 40
            c.rect(lx, top, 2, 3, hose); c.px(lx, top, flash)
        }
    }
    drawShoes(c, step: step, C(0x141418))
    c.oy += p.breathe
    if charging { c.oy -= Int(p.t * 14) % 2 }
    drawBody(c, Look(arm: shirt, eye: nil))
    // The shirt, open at the neck, and the belt.
    c.rect(18, 33, 20, 2, shirt); c.rect(37, 33, 1, 2, shirtDark)
    c.pattern(26, 33, ["O..O", ".OO."], ["O": clawdOrange])
    c.rect(15, 33, 3, 3, shirt); c.rect(15, 35, 3, 1, clawdOrange)
    // The kilt: red tartan, a pleated swing at the back, the sporran in front.
    let hem = seatedPose ? 38 : 39
    c.rect(17, 35, 21, hem - 34, tartan)
    for x in [20, 25, 30, 35] { c.rect(x, 35, 1, hem - 34, sett) }
    c.rect(17, 37, 21, 1, tartanDark)
    for x in [22, 32] { c.rect(x, 35, 1, hem - 34, stripe.alpha(0.7)) }
    c.rect(17, hem, 21, 1, tartanDark)
    c.rect(17, 35, 21, 1, C(0x3A2416))                                         // the belt
    c.rect(26, 36, 4, 3, C(0xF2EEE4)); c.rect(26, 36, 4, 1, C(0x5A3A22))
    for x in [26, 28] { c.px(x + 1, 38, C(0x1A1A1A)) }                         // the sporran's tassels
    // The mop.
    c.pattern(17, 20, [
        "....HHHHHHHHHHHH......",
        "..HHHHHHHHHHHHHHHH....",
        ".HHHHHhHHHHHHhHHHHH...",
        "HHHHHHHHHHHHHHHHHHHH..",
        "HHHHHHHHHhHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHH.HH.HHH.HH....HHHH",
        "HHH..H...H.........HHH",
        "HHH................HHH",
        "HH..................HH",
        "HH..................HH",
        ".H..................H.",
    ], ["H": hair, "h": hairLight])
    drawEyes(c, p)
    if yell {
        c.rect(26, 31, 4, 2, C(0x5A1A1A)); c.rect(26, 31, 4, 1, ink)
        if Int(p.t * 10) % 2 == 0 { c.px(40, 27, white.alpha(0.6)); c.px(41, 25, white.alpha(0.5)); c.px(42, 28, white.alpha(0.4)) }
    }
    if raised {
        c.rect(38, 24, 3, 9, shirt)
        drawDirk(c, at: (39.5, 23.5), angle: -100)
    } else if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawDirk(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
        c.rect(38, 33, 3, 3, shirt)
        drawDirk(c, at: Sprite.hand, angle: a)
    } else {
        // The dirk sheathed at his belt, his hand by it.
        c.rect(36, 34, 2, 1, C(0x2A1A12)); c.rect(38, 34, 5, 1, C(0x1E1E22)); c.px(35, 34, C(0xC8A040))
        c.rect(38, 33, 3, 3, shirt); c.rect(38, 35, 3, 1, clawdOrange)
    }
}

/// Jamie's dirk at `angle` degrees from `at`: a fist round the black grip, a brass pommel, a long steel blade.
private func drawDirk(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.px(16, 20, C(0xC8A040))
        s.rect(17, 20, 4, 1, C(0x1E1E22))
        s.rect(21, 19, 1, 3, C(0x8A8F9C))
        s.rect(22, 20, 9, 1, C(0xD8DCE4)); s.rect(22, 19, 8, 1, C(0xA8ADB8)); s.px(31, 20, C(0xA8ADB8))
        s.rect(18, 19, 3, 3, clawdOrange)
    }
}

// MARK: - Zoe Hairiot

/// Zoe Hairiot: the astrophysicist from the Wheel, a glossy black bob with a heavy straight fringe and a glittery
/// silver catsuit that sparkles as she moves, silver boots to match. Signature: she computes on her fingers, a hand up
/// by her face ticking off digits while little binary figures rise over her head, and a bright spark when she has it.
private func drawZoe(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x121016), hairLight = C(0x3A3446), suit = C(0xC8CCD8), suitDark = C(0x8E94A6), boot = C(0xA8AEBE)
    let s = p.signature
    let computing = s.map { $0 > 0.06 && $0 < 0.86 } ?? false
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose { for lx in [20, 24, 32, 36] { c.rect(lx, 38, 1, 4, suitDark) } }
    drawShoes(c, step: p.step, boot, rows: 2)
    c.oy += p.breathe
    let arm: Arm = computing ? .down : companionArm(p)
    drawBody(c, Look(arm: suit, eye: nil), armRight: armLift(arm))
    // The catsuit, glittering.
    c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, suitDark); c.rect(18, 37, 20, 1, suitDark)
    c.rect(25, 33, 6, 1, suitDark)
    c.rect(15, 33, 3, 3, suit); c.rect(15, 35, 3, 1, clawdOrange)
    let glint = Int(p.lt * 6)
    for k in 0..<8 {
        let x = 18 + Int(noise(k * 7 + 3) * 20), y = 33 + Int(noise(k * 11 + 5) * 5)
        let on = noise(glint * 13 + k * 29) > 0.55
        c.px(x, y, on ? white : C(0xE8ECF8))
        if on && noise(glint + k) > 0.7 { c.px(x, y - 1, C(0xFFB8E8, 0.7)); c.px(x + 1, y, C(0xA8D8FF, 0.7)) }
    }
    // The bob and its fringe.
    c.pattern(17, 21, [
        "....HHHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHhHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHhHHHH",
        "HHHhHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHhhhhhhhhhhhhhhhhHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        ".HHH..............HHH.",
    ], ["H": hair, "h": hairLight])
    drawEyes(c, p)
    if computing, let s = s {
        // The hand up by her chin, fingers flicking as she counts.
        c.rect(38, 28, 3, 6, suit); c.rect(38, 33, 1, 1, suitDark)
        c.rect(38, 25, 3, 3, clawdOrange)
        let tick = Int(p.t * 6) % 3
        c.px(38 + tick, 24, clawdOrange)
        // Binary rising over her head, then the spark.
        for k in 0..<4 {
            let f = frac(s * 3 + Double(k) / 4)
            let x = 22 + k * 4, y = 18 - Int(f * 8)
            let col = C(0x8AE8FF).alpha(1 - f)
            if (k + Int(s * 12)) % 2 == 0 { c.rect(x, y, 1, 3, col) } else { c.pattern(x - 1, y, ["CCC", "C.C", "CCC"], ["C": col]) }
        }
    } else {
        drawArm(c, p, arm, sleeve: suit)
    }
    if let s = s, s > 0.78 && s < 0.98 {
        let f = (s - 0.78) / 0.2
        c.glowLine(40.5, 20.5, 40.5, 20.5, core: C(0xFFFFFF).alpha(1 - f), glow: C(0x8AE8FF).alpha(1 - f), coreR: 0.6,
                   glowR: 2 + f * 2)
        c.rect(38, 25, 3, 9, suit); c.rect(38, 22, 3, 3, clawdOrange)
    }
}

// MARK: - Brigadier Lethbridge-Stewed

/// Brigadier Lethbridge-Stewed: the commanding officer, in a khaki service dress with brass buttons, brass pips on the
/// shoulders and a Sam Browne belt, a peaked cap with a red band and a black peak, a clipped grey moustache, a swagger
/// stick tucked under his left arm and polished brown boots; his service pistol in his right hand. Signature: he brings
/// the pistol up to sight along it and barks the order, the moustache bristling.
private func drawBrigadier(_ c: PixelCanvas, _ p: Pose) {
    let khaki = C(0x8A7E52), khakiDark = C(0x6A5E3A), khakiLight = C(0xA89A68), red = C(0xB8242A), brass = C(0xD8B04A)
    let leather = C(0x6A3E1E), leatherDark = C(0x4A2A12), peak = C(0x1A1A1E), tache = C(0xD0CCC0)
    let s = p.signature
    let aim: Double = s.map { habitArc($0, hold: 0.6) } ?? 0
    let barking = s.map { $0 > 0.3 && $0 < 0.8 } ?? false
    drawLegs(c, Look(leg: khaki), step: p.step)
    drawShoes(c, step: p.step, leather, rows: 3)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 41, C(0x8A5A2E)) } }
    c.oy += p.breathe
    drawBody(c, Look(arm: khaki, eye: nil))
    // The tunic, collar tabs, buttons, Sam Browne.
    c.rect(18, 33, 20, 5, khaki); c.rect(37, 33, 1, 5, khakiDark); c.rect(18, 37, 20, 1, khakiDark)
    c.pattern(24, 33, ["LL....LL", ".LL..LL.", "..LLLL.."], ["L": khakiLight])
    c.px(19, 33, brass); c.px(36, 33, brass)                                   // the shoulder pips
    for y in [35, 37] { c.px(28, y, brass) }
    c.rect(18, 36, 20, 1, leather); c.px(27, 36, brass)
    for k in 0..<4 { c.px(33 - k, 33 + k, leatherDark) }
    c.rect(15, 33, 3, 3, khaki)
    // The swagger stick, tucked under the left arm.
    c.rect(8, 34, 12, 1, C(0x5A3418)); c.px(8, 34, brass); c.px(19, 34, brass)
    c.rect(15, 35, 3, 1, clawdOrange)
    // The cap: khaki crown, red band, badge, the peak out over the eyes; grey at the temples.
    c.pattern(17, 20, [
        "...CCCCCCCCCCCCCCC.....",
        "..CCCCCCCCCCCCCCCCCC...",
        "..CCCCCCCCCCCCCGGCCC...",
        "..RRRRRRRRRRRRRRRRRR...",
        "..RRRRRRRRRRRRRRRRRR...",
        "..........KKKKKKKKKKKK.",
    ], ["C": khaki, "R": red, "G": brass, "K": peak])
    c.rect(18, 26, 1, 3, C(0x9A968C)); c.px(36, 26, C(0x9A968C))
    c.rect(18, 26, 20, 1, khakiDark.alpha(0.35))                                // the peak's shadow
    drawEyes(c, p)
    if aim > 0.5 { c.rect(22, 29, 2, 1, clawdOrange) }                           // squinting along the sights
    // The moustache, bristling while he barks.
    let bristle = barking && Int(p.t * 10) % 2 == 0 ? 1 : 0
    c.rect(25, 32 - bristle, 6, 1, tache); c.rect(26, 31 - bristle, 4, 1, tache)
    if barking { c.rect(27, 33, 3, 1, C(0x5A1A1A)) }
    // The pistol.
    let up = Int((3 * aim).rounded())
    c.oy += p.gunY - up
    c.rect(38, 33, 3, 3, khaki)
    drawPistol(c, x: 40, y: 32)
    c.rect(39, 33, 2, 2, clawdOrange)
}

// MARK: - Jo Grunt

/// Jo Grunt: the mod girl at the base, long straight honey-blonde hair parted in the middle, a purple mini dress with a
/// big white collar and a wide white belt, and white go-go boots.
private func drawJo(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xD0A060), hairDark = C(0xA87A3E), dress = C(0x8A3AA8), dressDark = C(0x642A7E), dressLight = C(0xB060D0)
    let collar = C(0xF6F2EC), boot = C(0xF2F0EC), bootShade = C(0xC8C4C0)
    // Hair down her back, behind everything.
    c.oy += p.breathe
    c.rect(15, 27, 4, 11, hair); c.rect(15, 27, 1, 11, hairDark); c.rect(16, 38, 2, 1, hairDark)
    c.oy -= p.breathe
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 39 : 40
            c.rect(lx, top, 2, 4, boot); c.px(lx + 1, top, bootShade)
        }
    } else {
        drawShoes(c, step: p.step, boot)
    }
    c.oy += p.breathe
    let arm = companionArm(p)
    drawBody(c, Look(arm: dress, eye: nil), armRight: armLift(arm))
    // The dress: a flared mini, the collar and the belt.
    c.rect(18, 33, 20, 5, dress); c.rect(37, 33, 1, 5, dressDark)
    if !seatedPose { c.rect(17, 38, 22, 1, dress); c.rect(17, 38, 1, 1, dressDark); c.rect(38, 38, 1, 1, dressDark) }
    for x in [21, 26, 31] { c.rect(x, 36, 1, seatedPose ? 2 : 3, dressLight) }
    c.pattern(22, 33, ["WWWW..WWWW", ".WW....WW."], ["W": collar])
    c.rect(18, 35, 20, 1, dressDark); c.rect(27, 35, 2, 1, collar)
    c.rect(15, 33, 3, 3, dress); c.rect(15, 35, 3, 1, clawdOrange)
    // The hair: parted down the middle, falling straight.
    c.pattern(17, 21, [
        "....HHHHHHHHHHHHHH....",
        "..HHHHHHHHHdHHHHHHHH..",
        ".HHHHHHHHHHdHHHHHHHHH.",
        "HHHHHHHHHHddHHHHHHHHHH",
        "HHHHHHHHddddddHHHHHHHH",
        "HHHHHH..........HHHHHH",
        "HHHH..............HHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        "HH.................HH.",
        "HH.................HH.",
    ], ["H": hair, "d": hairDark])
    drawEyes(c, p)
    drawArm(c, p, arm, sleeve: dress)
}

// MARK: - Sarah Jane Smythe

/// Sarah Jane Smythe: the journalist, a feathered brown bob flicked out at the ends, candy-striped pink-and-white
/// dungarees with straps over a pale-blue top, and red shoes. A reporter's notebook in her hand when she isn't pointing.
private func drawSarahJane(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x6A3E22), hairLight = C(0x8E5A34), pink = C(0xE0607E), stripeW = C(0xF6EEF0), top = C(0x9AC0E4)
    let topDark = C(0x7AA0C8)
    drawLegs(c, Look(leg: pink), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx + 1, 36, 1, 6, stripeW) } }
    drawShoes(c, step: p.step, C(0xB82A2A))
    c.oy += p.breathe
    let arm = companionArm(p)
    drawBody(c, Look(arm: top, eye: nil), armRight: armLift(arm))
    // The top, and the striped dungarees over it: bib, straps, a pocket.
    c.rect(18, 33, 20, 5, top); c.rect(37, 33, 1, 5, topDark)
    c.rect(22, 33, 12, 5, pink); c.rect(18, 36, 20, 2, pink)
    for x in stride(from: 19, to: 38, by: 2) { c.rect(x, 33, 1, 5, stripeW) }
    c.rect(18, 33, 4, 3, top); c.rect(34, 33, 4, 3, top); c.rect(37, 33, 1, 3, topDark)
    c.rect(22, 33, 1, 3, pink); c.rect(33, 33, 1, 3, pink)                     // the straps
    c.px(22, 33, C(0xC8A040)); c.px(33, 33, C(0xC8A040))
    c.rect(26, 34, 4, 2, C(0xC84866))                                          // the bib pocket
    c.rect(15, 33, 3, 3, top); c.rect(15, 35, 3, 1, clawdOrange)
    // The feathered bob, the ends flicked out.
    c.pattern(17, 21, [
        "....HHHHHHHHHHHHH.....",
        "..HHHHHhHHHHHHhHHHH...",
        ".HHHHHHHHHHHHHHHHHHH..",
        "HHHHHHHHhHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHH.hHHHH.HHH...HHHH",
        "HHH....h...........HHH",
        "HHH................HHH",
        "HHH................HHH",
        "HH..................HH",
        "HHH................HHH",
        "HHHH..............HHHH",
    ], ["H": hair, "h": hairLight])
    c.px(16, 31, hair); c.px(16, 32, hair); c.px(39, 32, hair)
    drawEyes(c, p)
    drawArm(c, p, arm, sleeve: top)
    if arm == .down {
        // The notebook and a pencil.
        c.rect(40, 31, 3, 4, C(0xF2EEDC)); c.rect(40, 31, 3, 1, C(0x5A6A8A))
        c.rect(40, 32, 1, 3, C(0xC8C4B0))
        c.rect(43, 30, 1, 4, C(0xE8C02A)); c.px(43, 34, C(0x3A3A3A))
        c.rect(39, 33, 2, 2, clawdOrange)
    }
}

// MARK: - Leelah

/// Leelah: the warrior of the Sevateem, long dark-brown hair, a fringed tan leather top and a short leather skirt with
/// a jagged hem, bare arms and legs, soft wrapped leather boots, a knife sheathed on her thigh. She fights by
/// throwing knives (and the odd Janis thorn). Signature: the knife throw: the knife goes back behind her head, her arm
/// snaps forward and it spins away; then she draws another from her thigh.
private func drawLeelah(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x3A2214), hairLight = C(0x5A3620), leather = C(0xA8784A), leatherDark = C(0x7A5230)
    let fringe = C(0x8A6038), steel = C(0xDCE0E8), steelDark = C(0x9AA0AC), hilt = C(0x3A2A1A)
    let s = p.signature
    // Hair down her back.
    c.oy += p.breathe
    c.rect(15, 27, 4, 10, hair); c.rect(15, 27, 1, 10, C(0x24140C)); c.px(16, 37, hair)
    c.oy -= p.breathe
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 40 : 41
            c.rect(lx, top, 2, 3, leatherDark); c.px(lx, top + 1, leather)
        }
    } else {
        drawShoes(c, step: p.step, leatherDark)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: clawdOrange, eye: nil))
    // The leather: a fringed top, bare midriff, a jagged skirt and the thigh sheath.
    c.rect(18, 33, 20, 2, leather); c.rect(37, 33, 1, 2, leatherDark)
    for x in stride(from: 19, to: 38, by: 2) { c.px(x, 35, fringe) }
    c.rect(18, 36, 20, seatedPose ? 2 : 2, leather); c.rect(18, 36, 20, 1, leatherDark)
    if !seatedPose { for x in stride(from: 18, to: 38, by: 3) { c.rect(x, 38, 2, 1, leather) } }
    c.rect(37, 36, 1, 2, leatherDark)
    c.rect(33, 37, 2, 2, hilt)
    // The hair, with a strand forward over the shoulder.
    c.pattern(17, 20, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHhHHHHHH...",
        "..HHHHhHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHhHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHH.HHHHH.HHHHHHHH",
        "HHHH.H.....H......HHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HH.",
        "HH.................HH.",
        "HH.................H..",
    ], ["H": hair, "h": hairLight])
    drawEyes(c, p)
    // The fierce brow.
    if !p.hit { c.rect(21, 28, 3, 1, hair); c.rect(31, 28, 3, 1, hair) }

    if let s = s {
        if s < 0.35 {
            // Wound back: the knife behind her head.
            c.rect(38, 23, 3, 10, clawdOrange)
            c.rect(31, 18, 5, 1, steel); c.rect(32, 19, 4, 1, steelDark); c.px(30, 18, steelDark)
            c.rect(36, 18, 2, 2, hilt); c.rect(38, 18, 3, 5, clawdOrange)
        } else if s < 0.5 {
            // The arm snapped forward.
            c.rect(38, 30, 6, 3, clawdOrange)
        } else if s < 0.85 {
            c.rect(38, 33, 3, 3, clawdOrange)
        } else {
            // Drawing the next one from the sheath.
            c.rect(36, 34, 3, 3, clawdOrange)
        }
        if s >= 0.38 && s < 0.75 {
            let f = (s - 0.38) / 0.37
            let x = 45 + f * 26
            drawProjectile(c, .thrown(steel), from: (45, 30.5), head: (x, 30.5), t: p.t)
        }
        return
    }
    if p.cheering {
        c.rect(38, 24, 3, 9, clawdOrange)
        c.rect(39, 19, 1, 5, steel); c.px(39, 18, steelDark); c.rect(38, 24, 3, 1, hilt)
        return
    }
    // The knife in her fist, blade forward; gone for an instant as it's thrown.
    c.oy += p.gunY
    if p.recoil > 0 {
        c.rect(38, 31, 5, 3, clawdOrange)
        return
    }
    c.rect(38, 32, 3, 3, clawdOrange)
    c.rect(40, 32, 2, 1, hilt)
    c.rect(42, 31, 3, 1, steel); c.rect(42, 32, 2, 1, steelDark); c.px(45, 31, steelDark)
}
