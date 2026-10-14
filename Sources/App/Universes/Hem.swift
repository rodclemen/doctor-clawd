import Foundation

// HEM: the one character in all four universes, with the same face in each: big buns, wire glasses, a scowl and a
// salt-and-pepper goatee. He's the last hero of every cast (`Universe.hem`), kept out of the regular pools and turning
// up only now and then (`Universe.hemOdds`). Star Clawds: Laya's white robe and a blaster (and a word for her about
// buns, `Overlay`). Marvelous Clawds: a purple-and-gold captain with an H and its shield. Detective Clawds: Harlee's
// jacket, dyed buns and a toy wand. Doctor Clawd: a tweed jacket, a red bow tie, a fez (fezzes are cool) and a sonic
// screwdriver. Signature, everywhere: he shakes his fist at you.

func hemPersona(_ u: Universe) -> Persona {
    switch u {
    case .starWars:
        return Persona(name: "HEM", weapon: .blaster, canSit: false, muzzle: (47, 32), headTop: 21, signature: 2.6,
                       draw: { drawHem($0, $1, .starWars) })
    case .marvel:
        return Persona(name: "HEM", weapon: .saber, headTop: 21, signature: 2.6, draw: { drawHem($0, $1, .marvel) })
    case .dc:
        return Persona(name: "HEM", weapon: .blaster, shot: .energy(core: C(0xFFF6C8), glow: C(0xFF7AC8)), muzzle: (52, 27),
                       headTop: 21, signature: 2.6, draw: { drawHem($0, $1, .dc) })
    case .doctor:
        return Persona(name: "HEM", weapon: .lightning, magic: Magic(core: C(0xE8FFE0), glow: C(0x4ADB5A), jagged: false),
                       pivot: hemSonicTip, headTop: 15, signature: 2.6, draw: { drawHem($0, $1, .doctor) })
    }
}

/// What he says to Princess Laya when he ends up next to her.
let hemBunLines = ["Cute buns. Amateur.", "Nice buns. Mine are bigger.", "Bun for bun, I win."]

private let hemShade = C(0xB85F40)
private let hairMain = C(0x4A2E18), hairDark = C(0x2E1C0E), hairPart = C(0x6E4A2C)
private let wire = C(0xD5DAE2), beard = C(0x2A221C), beardGrey = C(0xA8A8A8)
private let robe = C(0xF4F4F0), robeShade = C(0xD2D4DA)
private let capPurple = C(0x5B2D8E), capPurpleDark = C(0x43206A), capGold = C(0xE8B33A)
private let harleeRed = C(0xC8202A), harleeBlue = C(0x2E5CC9)
private let tweed = C(0x7A5232), tweedDark = C(0x5A3C24), fezRed = C(0xB8202A), fezDark = C(0x7A1218)
/// Where the sonic screwdriver's tip is, held out (its beam leaves from there, raised by the pose's `armRaise`).
private let hemSonicTip = (x: 46.0, y: 30.0)

private func drawHem(_ c: PixelCanvas, _ p: Pose, _ u: Universe) {
    // Signature: the fist goes up by his shoulder and shakes at you while he yells.
    let shaking = p.signature.map { $0 > 0.08 && $0 < 0.92 } ?? false
    let frame = Int(p.t * 9) % 2

    // Legs, or the robe's hem with his shoes peeking out.
    switch u {
    case .starWars:
        for y in 38...43 {
            let q = (y - 38) / 2
            c.rect(17 - q, y, 22 + q * 2, 1, robe); c.px(17 - q, y, robeShade); c.px(38 + q, y, robeShade)
            if y > 39 { c.px(24, y, robeShade); c.px(31, y, robeShade) }
        }
        let lifted = p.step >= 0 ? (p.step == 0 ? 0 : 1) : -1
        c.rect(19, lifted == 0 ? 43 : 44, 4, 1, ink); c.rect(33, lifted == 1 ? 43 : 44, 4, 1, ink)
    case .marvel:
        drawLegs(c, Look(leg: capPurple), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 41 : 42, 2, 2, capGold) }
        }
    case .dc:
        let net = C(0x3A3A44)
        drawLegs(c, Look(leg: net), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
                c.px(lx, top + 3, C(0x6A6A78)); c.px(lx + 1, top + 5, C(0x6A6A78))   // fishnets
                c.rect(lx, top + 6, 2, 1, ink)
            }
        }
    case .doctor:
        drawLegs(c, Look(leg: C(0x2A2A32)), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 41 : 42, 2, 2, C(0x3A2416)) }
        }
    }

    c.oy += p.breathe
    // The body, wider than plain Clawd's, and the top of his costume over it.
    let top: Px, topShade: Px, arm: Px, armRight: Px
    switch u {
    case .starWars: top = robe; topShade = robeShade; arm = robe; armRight = robe
    case .marvel: top = capPurple; topShade = capPurpleDark; arm = capPurple; armRight = capPurple
    case .dc: top = white; topShade = C(0xD8D8DC); arm = harleeRed; armRight = harleeBlue
    case .doctor: top = tweed; topShade = tweedDark; arm = tweed; armRight = tweed
    }
    c.rect(17, 26, 22, 12, clawdOrange); c.rect(38, 26, 1, 12, hemShade)
    c.rect(17, 34, 22, 4, top); c.rect(38, 34, 1, 4, topShade); c.rect(20, 34, 16, 1, topShade)   // the turtleneck's roll
    switch u {
    case .starWars:
        c.rect(17, 37, 22, 1, C(0xB8BEC9)); for x in [20, 23, 32, 35] { c.px(x, 37, C(0xEEF0F4)) }
        c.rect(27, 36, 2, 2, C(0xEEF0F4))
    case .marvel:
        for x in 17...38 { c.px(x, 37, x % 2 == 0 ? capGold : white) }
        c.pattern(18, 34, ["H.H", "HHH", "H.H"], ["H": capGold])
    case .dc:
        c.rect(17, 34, 3, 4, harleeRed); c.rect(36, 34, 3, 4, harleeBlue); c.rect(17, 37, 22, 1, C(0x2A2A32))
    case .doctor:   // the jacket open over a shirt, red braces and the bow tie
        c.rect(24, 34, 8, 4, C(0xE8E2D4)); c.rect(25, 35, 1, 3, fezRed); c.rect(30, 35, 1, 3, fezRed)
        c.pattern(25, 34, ["RRrRR", "R...R"], ["R": fezRed, "r": fezDark])
    }
    // Arms: hands on hips at rest, the right one forward to fight.
    let forward = !shaking && (!p.resting || p.melee != nil)
    c.rect(14, 33, 3, 3, arm)
    let lift = u == .doctor ? p.armRaise : 0
    if !shaking { c.rect(39, (forward ? 31 : 33) - lift, 3, 3, armRight) }
    if !forward { c.px(16, 35, clawdOrange); if !shaking { c.px(39, 35, clawdOrange) } }

    drawHemHead(c, u)
    if u == .marvel {   // the helmet: purple, the H, little white wings
        c.pattern(17, 21, ["....HHHHHHHHHHHHHH....", "..HHHHHHHHHHHHHHHHHH..", ".HHHHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHHHH",
                           "HHHHHHHHHHHHHHHHHHHHHH", "HH..................HH"], ["H": capPurple])
        c.pattern(26, 21, ["H..H", "HHHH", "H..H", "H..H"], ["H": capGold])
        c.pattern(15, 21, ["W.", "WW", ".W"], ["W": white]); c.pattern(39, 21, [".W", "WW", "W."], ["W": white])
    }
    if u == .doctor {   // the fez, a little to the back, its tassel hanging
        c.pattern(22, 15, ["...FFFFFF..", "...FFFFFFK.", "..FFFFFFFFK", "..FFFFFFFF.", ".FFFFFFFFFF", ".ffffffffff"],
                  ["F": fezRed, "f": fezDark, "K": ink])
    }
    drawHemFace(c, yelling: shaking && frame == 1)
    if u == .dc { c.pattern(36, 32, [".R.R", "RRRR", ".RR."], ["R": C(0xE8323A)]) }   // the little heart on his cheek

    if shaking {
        // The fist by his shoulder, a pixel up and over every other frame, with shake ticks; the anger mark.
        let fx = 39 + frame, fy = 27 - frame
        c.pattern(fx, fy, [".FFFF.", "FfFfFF", "FFFFFF", "FFFFFs", ".FFss."], ["F": clawdOrange, "f": hemShade, "s": hemShade])
        let tick = C(0xFFFFFF, 0.85)
        for (dx, dy) in (frame == 0 ? [(7, 0), (7, 3), (2, -2)] : [(-1, -2), (7, -1), (7, 2)]) {
            c.px(fx + dx, fy + dy, tick); c.px(fx + dx, fy + dy + 1, tick)
        }
        c.pattern(33, 21, [".R.R.", "RR.RR", ".....", "RR.RR", ".R.R."], ["R": C(0xE8323A)])
        if u == .marvel { drawHemShield(c, cx: 15, cy: seatedPose ? 33 : 35) }
        return
    }

    switch u {
    case .starWars:   // a little blaster, kicking with each shot
        c.pattern(41, 31 + p.gunY, ["KKKKKK", "KKTKK.", "KK...."], ["K": C(0x2A2A30), "T": C(0x8A8F9C)])
    case .marvel:
        if let a = p.melee {
            for (i, ta) in p.trail.enumerated() {
                let (x, y) = hemShieldAt(ta)
                drawHemShield(c, cx: x, cy: y, alpha: 0.35 / Double(i + 1))
            }
            let (x, y) = hemShieldAt(a)
            drawHemShield(c, cx: x, cy: y)
        } else {
            drawHemShield(c, cx: 44, cy: seatedPose ? 32 : 34)
        }
    case .dc:
        drawWand(c, raised: p.fire != nil || p.ready || p.cheering, gunY: p.gunY, t: p.t)
    case .doctor:
        drawHemSonic(c, out: forward || p.zap != nil, lift: lift)
    }
}

/// His sonic screwdriver: held up in his fist at rest; pointed out, its green tip at `hemSonicTip` (`lift` higher).
private func drawHemSonic(_ c: PixelCanvas, out: Bool, lift: Int) {
    let grip = C(0x3A3A44), steel = C(0xC8CCD4), tip = C(0x7AF08A)
    if out {
        let y = 32 - lift
        c.rect(42, y, 2, 1, grip); c.rect(44, y - 1, 2, 1, steel); c.px(46, y - 2, tip)
    } else {
        c.rect(40, 29, 1, 4, grip); c.px(40, 28, steel); c.px(40, 27, tip.alpha(0.7))
    }
}

/// The buns (bigger than Laya's: his are 7 across) and the centre-parted hair; Harlee's are dyed pink and blue.
private func drawHemHead(_ c: PixelCanvas, _ u: Universe) {
    let bun = ["..BBB..", ".BBbBB.", "BBbBBbB", "BbBBbBB", "BBbBBbB", ".BBbBB.", "..BBB.."]
    if u == .dc {
        c.pattern(10, 24, bun, ["B": C(0xF06AA8), "b": C(0xC84A86)]); c.pattern(39, 24, bun, ["B": C(0x4A8CF0), "b": C(0x2E68C8)])
        c.rect(16, 26, 1, 3, hairMain); c.rect(39, 26, 1, 3, hairMain)   // brown at the roots
    } else {
        c.pattern(10, 24, bun, ["B": hairMain, "b": hairDark]); c.pattern(39, 24, bun, ["B": hairMain, "b": hairDark])
    }
    c.pattern(17, 21, [
        "....BBBBBBlBBBBBBB....",
        "..BBBBBBBBlBBBBBBBBB..",
        ".BBBBbBBBBlBBBBbBBBBB.",
        "BBBBBBB...l....BBBBBBB",
        "BBB................BBB",
    ], ["B": hairMain, "b": hairDark, "l": hairPart])
}

/// Brows sloping in, wire glasses over squinting eyes, the mustache turned down into the frown and the goatee.
private func drawHemFace(_ c: PixelCanvas, yelling: Bool) {
    for (x, y) in [(20, 26), (21, 26), (22, 27), (23, 27), (24, 27), (35, 26), (34, 26), (33, 27), (32, 27), (31, 27)] { c.px(x, y, beard) }
    c.px(27, 27, hemShade); c.px(28, 27, hemShade)
    for x0 in [20, 30] {
        c.rect(x0, 28, 6, 1, wire); c.rect(x0, 31, 6, 1, wire); c.rect(x0, 28, 1, 4, wire); c.rect(x0 + 5, 28, 1, 4, wire)
        c.rect(x0 + 1, 29, 4, 2, C(0xF2E0D4))
    }
    c.rect(26, 29, 4, 1, wire); c.px(19, 29, wire); c.px(36, 29, wire)
    c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    c.pattern(22, 32, [
        "..MMMMMMMM..",
        ".MMMMMMMMMM.",
        yelling ? ".MMppppppMM." : ".MM.pppp.MM.",
        yelling ? "..MpppppMM.." : "..MgMMMgMM..",
        "..gMMgMMgM..",
        "...MgMMgM...",
        "....gMMg....",
    ], ["M": beard, "g": beardGrey, "p": yelling ? C(0x5A2418) : C(0x8E4A38)])
}

/// The shield's centre held out at `angle` degrees from the hand.
private func hemShieldAt(_ angle: Double) -> (Int, Int) {
    let r = angle * .pi / 180
    return (Int((Sprite.hand.x + cos(r) * 5).rounded(.down)), Int((Sprite.hand.y + sin(r) * 5).rounded(.down)))
}

/// The round shield: gold, white, purple, with a gold H in the middle.
private func drawHemShield(_ c: PixelCanvas, cx: Int, cy: Int, alpha: Double = 1) {
    for (r, col) in [(5, capGold), (4, white), (2, capPurple)] { c.ellipse(cx, cy, r, r, col.alpha(alpha)) }
    c.pattern(cx - 1, cy - 1, ["H.H", "HHH", "H.H"], ["H": capGold.alpha(alpha)])
}

/// A pink toy wand with a yellow star, glitter turning round it; tipped forward when he uses it (the star at the
/// persona's muzzle, (52, 27)).
private func drawWand(_ c: PixelCanvas, raised: Bool, gunY: Int, t: Double) {
    let stick = C(0xF7A8D0), star = C(0xFFE14A), starShade = C(0xF2B620)
    let x = 41, y = (raised ? 32 : 35) + gunY
    if raised { for i in 0..<7 { c.px(x + i, y - i / 2, stick) } } else { c.rect(x, y - 6, 1, 7, stick) }
    let sx = raised ? x + 7 : x - 2, sy = raised ? y - 7 : y - 11
    c.pattern(sx, sy, ["..Y..", ".YYY.", "YYyYY", ".YYY.", ".Y.Y."], ["Y": star, "y": starShade])
    if raised { c.px(x + 3, y - 1, C(0x7AD0FF)); c.px(x + 4, y - 2, C(0xC88CFF)) }   // ribbons
    let glitter = [C(0xFF7AC8), C(0x7AD0FF), C(0xFFE14A), white, C(0xC88CFF)]
    let k = Int(t * 6)
    for i in 0..<5 {
        let a = Double(i) * 1.3 + t * 5.4
        c.px(sx + 2 + Int(cos(a) * 5), sy + 2 + Int(sin(a) * 4), glitter[(i + k) % glitter.count])
    }
}
