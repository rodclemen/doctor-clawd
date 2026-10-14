import Foundation

// Heroes: the later Doctors (Nine, Eleven to Fifteen) and the two off the count, the War Doctor and the Fugitive Doctor.
// Clawd in costume, as in DoctorHeroes1: the hair, coat and props over the blocky body. The numbered ones use the sonic
// screwdriver, each with a tip colour of their own; the War Doctor and the Fugitive Doctor carry guns.

let doctorHeroes3: [DoctorHero: Persona] = [
    .doctorNine: Persona(name: "Doctor Nine", weapon: .lightning, magic: Magic(core: C(0xE8F4FF), glow: C(0x3A8CFF), jagged: false),
                  pivot: sonicTip, headTop: 23, signature: 2.6, callout: "Fantastic!",
                  draw: drawDoctorNine),
    .doctorEleven: Persona(name: "Doctor Eleven", weapon: .lightning, magic: Magic(core: C(0xEAFFE4), glow: C(0x3ACC4A), jagged: false),
                  pivot: sonicTip, headTop: 19, signature: 3.2, callout: "Geronimo!",
                  draw: drawDoctorEleven),
    .doctorTwelve: Persona(name: "Doctor Twelve", weapon: .lightning, magic: Magic(core: C(0xEAFFE4), glow: C(0x3ACC4A), jagged: false),
                  pivot: (37, 31), headTop: 17, signature: 3.2, callout: "Pudding brains!",
                  draw: drawDoctorTwelve),
    .doctorThirteen: Persona(name: "Doctor Thirteen", weapon: .lightning, magic: Magic(core: C(0xFFF4DC), glow: C(0xFFA028), jagged: false),
                  pivot: sonicTip, headTop: 20, signature: 3.4, callout: "Brilliant!",
                  draw: drawDoctorThirteen),
    .doctorFourteen: Persona(name: "Doctor Fourteen", weapon: .lightning, magic: Magic(core: C(0xE8F4FF), glow: C(0x3A8CFF), jagged: false),
                  pivot: sonicTip, headTop: 18, signature: 2.8, callout: "Oh!",
                  draw: drawDoctorFourteen),
    .doctorFifteen: Persona(name: "Doctor Fifteen", weapon: .lightning, magic: Magic(core: C(0xFBEAFF), glow: C(0xB060FF), jagged: false),
                  pivot: sonicTip, headTop: 20, signature: 3.0, callout: "Let's dance!",
                  draw: drawDoctorFifteen),
    .warDoctor: Persona(name: "The War Doctor", weapon: .blaster, shot: .energy(core: C(0xFFE8C8), glow: C(0xFF6A2A)),
                  muzzle: (48, 32), headTop: 22, signature: 3.6, callout: "No more.",
                  draw: drawWarDoctor),
    .fugitiveDoctor: Persona(name: "The Fugitive Doctor", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 21,
                  signature: 2.8, callout: "Don't make me use this.",
                  draw: drawFugitiveDoctor),
]

// MARK: - Bits shared by this file

/// The right arm of a sonic-carrying Doctor: pointing the sonic while working, fighting or waiting, otherwise holding
/// it upright in the fist (as Doctor Ten does).
private func drawSonicArm(_ c: PixelCanvas, _ p: Pose, sleeve: Px, tip: Px) {
    let using = p.zap != nil || p.ready || p.cheering || (!p.resting && !p.walking)
    if using {
        let raise = p.armRaise
        c.rect(38, 31 - raise, 3, 3, sleeve)
        drawSonic(c, out: true, lift: raise, lit: p.zap == true, tip: tip, t: p.t)
    } else {
        c.rect(38, 31, 3, 3, sleeve); c.rect(38, 30, 3, 1, clawdOrange)
        drawSonic(c, out: false, lift: 0, lit: false, tip: tip, t: p.t)
    }
}

/// A sonic screwdriver held straight up in a raised fist (hand at y 22…23), its tip shining.
private func drawSonicHeldUp(_ c: PixelCanvas, sleeve: Px, tip: Px, t: Double) {
    c.rect(38, 24, 3, 9, sleeve); c.rect(38, 22, 3, 2, clawdOrange)
    c.rect(39, 18, 1, 4, C(0x4A4A52)); c.rect(39, 16, 1, 2, C(0xC8CCD4)); c.px(39, 15, tip)
    if sin(t * 30) > 0 { c.px(39, 14, tip.alpha(0.6)); c.px(38, 15, tip.alpha(0.4)); c.px(40, 15, tip.alpha(0.4)) }
}

/// A long coat's tails, hanging behind the legs.
private func drawCoatTails(_ c: PixelCanvas, _ coat: Px, down: Int = 3) {
    guard !seatedPose else { return }
    c.rect(17, 36, 22, down + 1, coat)
    c.rect(17, 36 + down + 1, 22, 1, coat.alpha(0.8))
}

/// An arm as a thick line of sleeve from the shoulder at (`x0`, `y0`) to a Clawd-orange hand at (`x1`, `y1`).
private func drawLimb(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, sleeve: Px) {
    let n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in 0...n {
        let x = x0 + (x1 - x0) * i / n, y = y0 + (y1 - y0) * i / n
        c.rect(x - 1, y - 1, 3, 3, sleeve)
    }
    c.rect(x1 - 1, y1 - 1, 3, 2, clawdOrange)
}

/// A quaver floating up, its head at (`x`, `y`).
private func drawNote(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.rect(x, y, 2, 1, col); c.rect(x + 1, y - 3, 1, 3, col); c.px(x + 2, y - 3, col); c.px(x + 3, y - 2, col)
}

/// Doctor Ten's hair, as Doctor Fourteen wears it again: tall brown spikes and long sideburns.
private func drawSpikyHair(_ c: PixelCanvas, hair: Px, light: Px) {
    c.pattern(17, 18, [
        "...........H.H........",
        "........HHHHHHHH......",
        ".....HHHHHHlHHHHHH....",
        "...HHHHHlHHHHHHlHHHH..",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHlHHHHHHHHHHHlHHHH",
        ".HHHH...........HHHHHH",
        ".HHH...............HHH",
        ".HH.................HH",
        ".H...................H",
    ], ["H": hair, "l": light])
}

// MARK: - Doctor Nine

/// Doctor Nine: Clawd with a close dark crop, ears sticking out, a battered black leather jacket over a dark plum
/// V-neck jumper, black trousers and boots. The sonic glows blue. Signature: "Fantastic!": both arms flung wide, a big
/// toothy grin and a bounce.
private func drawDoctorNine(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x1E1E23), shine = C(0x45454F), crease = C(0x101013)
    let jumper = C(0x5A2638), jumperDark = C(0x401A28), trousers = C(0x24242A)
    let hair = C(0x2A1E16), hairLight = C(0x44342A)
    let sig = p.signature
    let wide = sig.map { $0 > 0.1 && $0 < 0.9 } ?? false
    if let s = sig, s > 0.3, s < 0.5 { c.oy -= 2 }

    drawLegs(c, Look(leg: trousers), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x141416), sole: C(0x2E2E34))
    c.oy += p.breathe
    drawBody(c, Look(arm: leather), armLeft: wide ? 3 : 0, armRight: wide ? 3 : 0)
    // The ears.
    c.rect(16, 28, 2, 3, clawdOrange); c.px(16, 29, clawdShade)
    c.rect(38, 28, 2, 3, clawdOrange); c.px(39, 29, clawdShade)
    // The jacket, zipped open on the V-neck jumper.
    c.rect(18, 33, 20, 5, leather)
    c.pattern(23, 33, [
        "KJJJJJJJJK",
        ".KJJJJJJK.",
        "..KJJJJK..",
        "...KjjK...",
    ], ["J": jumper, "j": jumperDark, "K": crease])
    c.rect(19, 34, 1, 3, shine); c.rect(21, 33, 1, 2, shine); c.rect(34, 33, 1, 2, shine)
    c.rect(18, 37, 20, 1, crease); c.rect(37, 33, 1, 5, crease)
    // The crop: short all over, barely there at the temples.
    c.pattern(18, 23, [
        "..HHHHHHlHHHHHHHHH..",
        ".HHHHlHHHHHHHHlHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "Hl................lH",
    ], ["H": hair, "l": hairLight])

    if wide || p.cheering {
        // Fantastic! Arms out and up either side, and the grin.
        c.rect(12, 28, 3, 3, leather); c.rect(10, 26, 3, 2, clawdOrange)
        c.rect(41, 28, 3, 3, leather); c.rect(44, 26, 3, 2, clawdOrange)
        c.pattern(24, 31, ["KWWWWWWK", ".KKKKKK."], ["K": ink, "W": white])
        return
    }
    drawSonicArm(c, p, sleeve: leather, tip: C(0x6AB8FF))
}

// MARK: - Doctor Eleven

/// Doctor Eleven: Clawd with a floppy brown fringe swept across his forehead, a brown tweed jacket over a white shirt
/// with red braces and a red bow tie, black trousers and boots. The sonic glows green. Signature: he puts on a fez
/// (bow ties and fezzes are cool), then straightens the bow tie.
private func drawDoctorEleven(_ c: PixelCanvas, _ p: Pose) {
    let tweed = C(0x7A5638), tweedDark = C(0x5A3E26), fleck = C(0x9A7650)
    let shirt = C(0xEDE6D8), bow = C(0xB01E2E), bowDark = C(0x781420), braces = C(0xA82030)
    let hair = C(0x5A3A22), hairLight = C(0x7A5232)
    let fez = C(0xB4202C), fezDark = C(0x821620)
    let sig = p.signature
    let fezInHand = sig.map { $0 > 0.06 && $0 < 0.3 } ?? false
    let fezOn = sig.map { $0 >= 0.3 && $0 < 0.97 } ?? false
    let straighten = sig.map { $0 > 0.45 && $0 < 0.85 } ?? false

    drawLegs(c, Look(leg: C(0x2A2A30)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x2A1C14), sole: C(0x16100C))
    c.oy += p.breathe
    drawBody(c, Look(arm: tweed))
    // The tweed jacket, open on the shirt and braces, the bow tie at the collar.
    c.rect(18, 33, 20, 5, tweed)
    for (x, y) in [(19, 34), (21, 36), (20, 33), (34, 35), (36, 33), (35, 37), (19, 37), (22, 34)] { c.px(x, y, fleck) }
    c.rect(37, 33, 1, 5, tweedDark)
    c.rect(24, 33, 8, 5, shirt)
    c.rect(24, 34, 1, 4, braces); c.rect(31, 34, 1, 4, braces)
    c.rect(23, 33, 1, 4, tweedDark); c.rect(32, 33, 1, 4, tweedDark)   // the lapels
    c.pattern(25, 33, ["BBbbBB", ".B..B."], ["B": bow, "b": bowDark])
    // The hair: a big floppy fringe swept down across the forehead.
    c.pattern(16, 19, [
        "......HHHHHHHHHH........",
        "....HHHHHHHHHHHHHH......",
        "..HHHHHHlHHHHHHHHHHH....",
        ".HHHHHlHHHHHHHHlHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHlHHHHHHHHHHlHHHH.",
        "HHHHHHHHHHHHHH...HHHHHH.",
        "HHlHHHHHH........HHHHH..",
        ".HHHHH..............HHH.",
        ".HHH................HH..",
    ], ["H": hair, "l": hairLight])

    if fezOn {
        c.rect(26, 14, 6, 2, fez); c.rect(25, 16, 8, 2, fez); c.rect(25, 18, 8, 1, fezDark)
        c.rect(27, 13, 4, 1, fez); c.px(29, 12, ink)
        c.px(30, 12, ink); c.px(31, 12, ink); c.px(32, 13, ink); c.rect(33, 14, 1, 2, ink)   // the tassel
    }
    if fezInHand {
        // The fez held up high, about to go on.
        c.rect(38, 24, 3, 9, tweed); c.rect(38, 22, 3, 2, clawdOrange)
        c.rect(37, 18, 6, 4, fez); c.rect(38, 17, 4, 1, fez); c.rect(37, 21, 6, 1, fezDark); c.px(40, 16, ink)
        c.rect(41, 16, 2, 1, ink); c.px(43, 17, ink)
        return
    }
    if straighten {
        // A hand up to the bow tie.
        c.rect(38, 33, 3, 3, tweed); c.rect(33, 34, 5, 2, tweed); c.rect(31, 33, 2, 2, clawdOrange)
        return
    }
    drawSonicArm(c, p, sleeve: tweed, tip: C(0x7CFF6A))
}

// MARK: - Doctor Twelve

/// Doctor Twelve: Clawd with a shock of swept-back grey hair, big frowning grey eyebrows and black sonic sunglasses, a
/// long dark navy coat with a red lining over a grey hoodie, black trousers and boots. His sonic is the sunglasses: he
/// touches the frame and the ray (green) leaves from the lens. Signature: an electric guitar riff, notes flying.
private func drawDoctorTwelve(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1E2232), coatDark = C(0x13151F), lining = C(0x8A1E24)
    let hoodie = C(0x4A4A52), hoodieDark = C(0x38383E)
    let hair = C(0xC8C8CE), hairDark = C(0x9A9AA4), brow = C(0x7E7E88)
    let green = C(0x7CFF6A)
    let sig = p.signature
    let riff = sig.map { $0 > 0.06 && $0 < 0.94 } ?? false
    let beat = Int(p.t * 8) % 2
    if riff, let s = sig, s > 0.6, beat == 0 { c.oy -= 1 }

    drawCoatTails(c, coatDark, down: 3)
    drawLegs(c, Look(leg: C(0x1C1C22)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x141416), sole: C(0x26262C))
    c.oy += p.breathe
    drawBody(c, Look(arm: coat), armLeft: riff ? 3 : 0)
    // The hoodie, the coat open over it, its red lining at the lapels.
    c.rect(18, 33, 20, 5, hoodie)
    c.rect(18, 37, 20, 1, hoodieDark)
    c.rect(26, 34, 1, 3, white.alpha(0.85)); c.rect(29, 34, 1, 3, white.alpha(0.85))   // hood strings
    c.rect(18, 33, 4, 5, coat); c.rect(34, 33, 4, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(22, 33, 1, 3, lining); c.rect(33, 33, 1, 3, lining)
    c.rect(15, 33, 3, 3, coat)
    // The hair: swept back and up, wild at the top.
    c.pattern(16, 17, [
        "..h..hH..h.............",
        ".hHh.HHh.HHh...........",
        "hHHHHHHHHHHHHHh........",
        "HHHHHhHHHHHHhHHHHHh....",
        "HHHHHHHHHHHHHHHHHHHHh..",
        "HHHHHHHHhHHHHHHHHHhHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH",
        ".HHHHHhHHHHHHHHHHHHHHHH",
        "..HHHHHHHHHHHHHHHHHHHH.",
        "..HHH..............HHH.",
        "..Hh................hH.",
    ], ["H": hair, "h": hairDark])
    // The eyebrows: big, grey, cross.
    c.rect(20, 27, 5, 1, brow); c.px(25, 28, brow)
    c.rect(31, 27, 5, 1, brow); c.px(30, 28, brow)
    // The sonic sunglasses.
    let lit = p.zap == true || (riff && beat == 0)
    c.rect(20, 28, 6, 3, ink); c.rect(30, 28, 6, 3, ink); c.rect(26, 28, 4, 1, ink)
    c.rect(36, 28, 2, 1, ink)
    c.px(21, 29, C(0x5A5A68)); c.px(31, 29, C(0x5A5A68))
    if lit {
        c.rect(21, 29, 4, 1, green.alpha(0.55)); c.rect(31, 29, 4, 1, green.alpha(0.55))
        if sin(p.t * 30) > 0 { c.px(37, 29, green) }
    }

    if riff {
        // The electric guitar slung across him: red body, neck up to the left hand, the right hand strumming.
        let neck = C(0x6A4428)
        for i in 0...15 { c.px(27 - i, 35 - i * 7 / 16, neck); c.px(27 - i, 34 - i * 7 / 16, C(0x8A6038)) }
        c.rect(10, 27, 3, 2, ink); c.px(12, 26, ink)
        c.rect(14, 29, 3, 2, clawdOrange)                      // fretting hand
        c.pattern(27, 33, [
            "..bbbb...",
            ".bRRRRb.b",
            "bRRWRRRbb",
            "bRRWRRRb.",
            ".bbRRbb..",
        ], ["b": C(0x2A1008), "R": C(0xC8321E), "W": C(0xEDE6D8)])
        c.rect(38, 33, 3, 3, coat); c.rect(35, 34, 3, 2, coat)
        c.rect(33, 34 + beat, 2, 2, clawdOrange)              // strumming
        if let s = sig {
            for i in 0..<3 {
                let f = (s * 3 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let x = 42 + i * 5 + Int(sin(f * 6 + Double(i)) * 2), y = 30 - Int(f * 14)
                drawNote(c, x, y, (i == 1 ? green : white).alpha(1 - f * 0.7))
            }
        }
        return
    }
    let using = p.zap != nil || p.ready || p.cheering || (!p.resting && !p.walking)
    if using {
        // A finger to the frame of the sunglasses.
        c.rect(38, 30, 3, 4, coat); c.rect(38, 28, 2, 2, clawdOrange)
    } else {
        c.rect(38, 33, 3, 3, coat)
    }
}

// MARK: - Doctor Thirteen

/// Doctor Thirteen: Clawd with a blonde bob and a short fringe, a navy top with a rainbow stripe across the chest,
/// mustard braces, high-waisted navy trousers rolled at the ankle, brown lace-up boots and a long blue-grey coat with
/// a purple lining. The sonic glows amber-gold. Signature: she builds a new sonic out of bits and sparks, then holds
/// it up: "Brilliant!"
private func drawDoctorThirteen(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x62748C), coatDark = C(0x4A5A70), lining = C(0x5E3E80)
    let navy = C(0x262E4C), braces = C(0xD8A838)
    let hair = C(0xE8CC78), hairDark = C(0xC4A452)
    let gold = C(0xFFB040)
    let sig = p.signature
    let building = sig.map { $0 > 0.05 && $0 < 0.6 } ?? false
    let showing = sig.map { $0 >= 0.6 && $0 < 0.95 } ?? false
    if let s = sig, s > 0.62, s < 0.72 { c.oy -= 1 }

    drawCoatTails(c, coatDark, down: 3)
    drawLegs(c, Look(leg: navy), step: p.step)
    if !seatedPose {
        // Rolled-up cuffs showing a stripe of sock.
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let y = p.step >= 0 && i % 2 == p.step ? 39 : 40
            c.rect(lx, y, 2, 1, C(0xB43A3A))
        }
    }
    drawTrainers(c, step: p.step, upper: C(0x7A4E2C), sole: C(0x4A2E18))
    c.oy += p.breathe
    drawBody(c, Look(arm: coat))
    // The top: navy with the rainbow band, braces over it, the coat open either side.
    c.rect(18, 33, 20, 5, navy)
    c.rect(21, 33, 14, 1, C(0xD84A3C)); c.rect(21, 34, 14, 1, C(0xF0C434))
    c.rect(21, 35, 14, 1, C(0x4AA864)); c.rect(21, 36, 14, 1, C(0x3C8AD0))
    c.rect(24, 33, 1, 5, braces); c.rect(31, 33, 1, 5, braces)
    c.rect(18, 33, 3, 5, coat); c.rect(35, 33, 3, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(20, 33, 1, 4, lining); c.rect(35, 33, 1, 4, lining)
    c.rect(15, 33, 3, 3, coat)
    // The bob: a short choppy fringe and the sides down to the jaw.
    c.pattern(17, 20, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHHhHHHHHHHHH...",
        "..HHHHHHHHHHHHHHhHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH.HH.HHHH.HHH.HHHH.",
        ".HHH..............HHH.",
        ".HHH..............HHH.",
        ".HHh..............hHH.",
        ".HHh..............hHH.",
        "..Hh..............hH..",
    ], ["H": hair, "h": hairDark])

    if building, let s = sig {
        // Both hands busy in front of her, bits of copper and wire coming together, sparks off them.
        let k = (s - 0.05) / 0.55
        c.rect(38, 32, 4, 3, coat); c.rect(41, 31, 2, 2, clawdOrange)
        c.rect(15, 32, 3, 3, coat)
        let spread = Int((1 - k) * 5)
        let bits: [(Int, Int, Px)] = [(-2, -1, C(0xC87A3A)), (2, -2, C(0xC8CCD4)), (0, 2, C(0x4A4A52)),
                                      (3, 1, C(0xE09048)), (-3, 2, C(0x8A8E98))]
        for (i, b) in bits.enumerated() {
            let bob = Int(sin(p.t * 6 + Double(i)))
            c.px(44 + b.0 * spread / 3, 28 + b.1 * spread / 3 + bob, b.2)
        }
        c.rect(44, 27, 1, 2, C(0xC8CCD4))
        let n = Int(p.t * 24)
        for i in 0..<3 where noise(n + i * 13) > 0.45 {
            c.px(43 + Int(noise(n + i * 7) * 5) - 2, 26 + Int(noise(n + i * 5) * 4) - 2, i == 0 ? white : gold)
        }
        return
    }
    if showing || p.cheering {
        drawSonicHeldUp(c, sleeve: coat, tip: gold, t: p.t)
        c.pattern(25, 31, ["KWWWWK", ".KKKK."], ["K": ink, "W": white])
        return
    }
    drawSonicArm(c, p, sleeve: coat, tip: gold)
}

// MARK: - Doctor Fourteen

/// Doctor Fourteen: Doctor Ten's build and spiky brown hair back again, now with a long blue-grey coat over a patterned
/// brown waistcoat and a white open-necked shirt, dark blue trousers and white trainers. The sonic glows blue.
/// Signature: "Oh!": hands in his coat pockets, leaning back on his heels, mouth an O.
private func drawDoctorFourteen(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x5C6E8E), coatDark = C(0x45546E), waistcoat = C(0x7A5A3A), weave = C(0x9A7A52)
    let shirt = C(0xF2F0EA), hair = C(0x4A2E1A), hairLight = C(0x6A4428)
    let sig = p.signature
    let lean = sig.map { $0 > 0.1 && $0 < 0.9 } ?? false
    let oh = sig.map { $0 > 0.25 && $0 < 0.8 } ?? false

    drawCoatTails(c, coatDark, down: 4)
    drawLegs(c, Look(leg: C(0x2A3452)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xE8EAEE), sole: C(0xB8BCC4))
    c.oy += p.breathe
    if lean { c.ox -= 1 }
    drawBody(c, Look(arm: coat), armLeft: lean ? -2 : 0, armRight: lean ? -2 : 0)
    // The waistcoat, the shirt open at the neck, the long coat open over them.
    c.rect(18, 33, 20, 5, waistcoat)
    for x in stride(from: 22, to: 34, by: 2) { c.px(x, 35, weave); c.px(x + 1, 36, weave) }
    c.rect(25, 33, 6, 2, shirt); c.px(27, 35, shirt); c.px(28, 35, shirt)
    c.px(28, 36, C(0x3A2818)); c.px(28, 37, C(0x3A2818))   // buttons
    c.rect(18, 33, 3, 5, coat); c.rect(35, 33, 3, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(21, 33, 1, 3, coatDark); c.rect(34, 33, 1, 3, coatDark)
    if lean {
        // Hands in his pockets: the sleeves go down into the coat.
        c.rect(15, 35, 3, 3, coat); c.rect(38, 35, 3, 3, coat)
        c.rect(15, 37, 3, 1, coatDark); c.rect(38, 37, 3, 1, coatDark)
        c.ox -= 1
    }
    drawSpikyHair(c, hair: hair, light: hairLight)
    if lean { c.ox += 1 }
    if oh { c.rect(27, 31, 2, 2, ink) }
    if lean { return }

    drawSonicArm(c, p, sleeve: coat, tip: C(0x6AB8FF))
}

// MARK: - Doctor Fifteen

/// The tartan of Doctor Fifteen's trousers at (`x`, `y`): red, crossed with green bands and a thin gold line.
private func tartan(_ x: Int, _ y: Int) -> Px {
    let gx = x % 4 == 0, gy = y % 4 == 0
    if gx && gy { return C(0x1E3A2A) }
    if gx || gy { return C(0x2E6040) }
    if x % 4 == 2 && y % 4 == 2 { return C(0xE0B848) }
    return C(0xA82A2E)
}

/// Doctor Fifteen: Clawd with short dark curls, a long camel coat over a teal shirt, wide red tartan kilt-style
/// trousers and brown boots. The sonic glows violet. Signature: a dance break, arms pointing up and down in turn,
/// hopping on the beat.
private func drawDoctorFifteen(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xB08050), coatDark = C(0x86603A), shirt = C(0x2A6A6E), shirtDark = C(0x1E4E52)
    let hair = C(0x1E140E), hairLight = C(0x3E2C20)
    let violet = C(0xC07CFF)
    let sig = p.signature
    let dancing = sig.map { $0 > 0.06 && $0 < 0.94 } ?? false
    let beat = sig.map { Int($0 * 12) % 2 } ?? 0
    if dancing && beat == 1 { c.oy -= 2 }
    let step = dancing ? beat : p.step

    drawCoatTails(c, coatDark, down: dancing && beat == 1 ? 2 : 3)
    // The tartan trousers, wide at the hem.
    if seatedPose {
        for lx in [19, 23, 31, 35] { for y in 38..<40 { for x in (lx - 1)..<(lx + 3) { c.px(x, y, tartan(x, y)) } } }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = step >= 0 && i % 2 == step
            for y in 36..<(lifted ? 41 : 42) { for x in lx..<(lx + 2) { c.px(x, y, tartan(x, y)) } }
            let hem = lifted ? 40 : 41
            c.px(lx - 1, hem, tartan(lx - 1, hem)); c.px(lx + 2, hem, tartan(lx + 2, hem))
        }
    }
    drawTrainers(c, step: step, upper: C(0x6A4428), sole: C(0x3A2416))
    c.oy += p.breathe
    let up = dancing ? (beat == 0 ? 0 : 1) : -1   // which arm points up: 0 left, 1 right
    drawBody(c, Look(arm: coat), armLeft: up == 0 ? 8 : 0)
    // The shirt, the coat open over it.
    c.rect(18, 33, 20, 5, shirt)
    c.rect(25, 33, 6, 1, shirtDark); c.px(27, 34, shirtDark); c.px(28, 34, shirtDark)
    c.rect(18, 33, 4, 5, coat); c.rect(34, 33, 4, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(22, 33, 1, 3, coatDark); c.rect(33, 33, 1, 3, coatDark)
    // Short dark curls, a little height on top.
    c.pattern(18, 20, [
        "....hHhHHhHHhHh.....",
        "..HhHHHHhHHHHhHHH...",
        ".HHHHhHHHHHHhHHHHHH.",
        ".HHHHHHHhHHHHHHHhHHH",
        "HHhHHHHHHHHHHhHHHHHH",
        "HHHHHHhHHHHHHHHHHhHH",
        "HHh...............HH",
        "Hh.................H",
    ], ["H": hair, "h": hairLight])

    if dancing {
        // Disco points, up and down in turn, and the beat in the air.
        if up == 0 {
            c.rect(15, 21, 3, 4, clawdOrange)
            c.rect(38, 33, 3, 3, coat); c.rect(41, 35, 3, 2, coat); c.rect(44, 36, 2, 2, clawdOrange)
        } else {
            c.rect(12, 35, 3, 2, coat); c.rect(10, 36, 2, 2, clawdOrange)
            c.rect(38, 23, 3, 10, coat); c.rect(38, 20, 3, 3, clawdOrange)
        }
        c.pattern(25, 31, ["KWWWWK", ".KKKK."], ["K": ink, "W": white])
        if let s = sig {
            for i in 0..<2 {
                let f = (s * 2.5 + Double(i) / 2).truncatingRemainder(dividingBy: 1)
                let x = (i == 0 ? 46 : 6) + Int(sin(f * 6) * 2), y = 30 - Int(f * 14)
                drawNote(c, x, y, (i == 0 ? violet : C(0xFFD25A)).alpha(1 - f * 0.7))
            }
        }
        return
    }
    drawSonicArm(c, p, sleeve: coat, tip: violet)
}

// MARK: - The War Doctor

/// The 3×5 (M: 5×5) scratched letters of NO MORE.
private let scratchFont: [Character: [String]] = [
    "N": ["X..X", "XX.X", "X.XX", "X..X", "X..X"],
    "O": ["XXX", "X.X", "X.X", "X.X", "XXX"],
    "M": ["X...X", "XX.XX", "X.X.X", "X...X", "X...X"],
    "R": ["XX.", "X.X", "XX.", "X.X", "X.X"],
    "E": ["XXX", "X..", "XX.", "X..", "XXX"],
]

/// The War Doctor: Clawd with swept-back white hair, bushy white eyebrows and a short white beard, a battered, scuffed
/// brown leather coat with a bandolier of brass-buckled pouches across it, a rust scarf, dark trousers and boots, and
/// a chunky gun. Signature: he scratches NO MORE into a stone wall with the end of his gun.
private func drawWarDoctor(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x5E4430), leatherDark = C(0x42301E), scuff = C(0x7E6248)
    let strap = C(0x2A1E14), brass = C(0xC0983E), scarf = C(0x8A3E2A)
    let hair = C(0xDCD8D0), hairShade = C(0xB0AAA0)
    let sig = p.signature
    let scratching = sig.map { $0 > 0.04 && $0 < 0.97 } ?? false

    drawCoatTails(c, leatherDark, down: 3)
    drawLegs(c, Look(leg: C(0x2E2A28)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x2A1C12), sole: C(0x16100A))
    c.oy += p.breathe
    drawBody(c, Look(arm: leather))
    // The coat, worn through in patches, the scarf at the neck and the bandolier across.
    c.rect(18, 33, 20, 5, leather)
    for (x, y) in [(19, 35), (20, 34), (35, 36), (34, 34), (22, 37), (36, 33)] { c.px(x, y, scuff) }
    c.rect(37, 33, 1, 5, leatherDark); c.rect(18, 37, 20, 1, leatherDark)
    c.rect(24, 33, 8, 2, scarf); c.rect(29, 35, 2, 2, scarf)
    for i in 0..<5 {
        let x = 33 - i * 3, y = 33 + i
        c.rect(x - 1, y, 4, 1, strap)
        if i % 2 == 1 { c.rect(x, y - 1, 2, 2, brass) }
    }
    // The hair, swept back, and the eyebrows.
    c.pattern(18, 22, [
        "....hHHHHHHHHHh.....",
        "..HHHHHHHhHHHHHHHH..",
        ".HHHHhHHHHHHHHHhHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHh..............hHH",
        "Hh................hH",
    ], ["H": hair, "h": hairShade])
    c.rect(21, 27, 4, 1, hair); c.rect(31, 27, 4, 1, hair)
    // The beard: a moustache and a short white beard down over the scarf.
    c.pattern(21, 31, [
        ".hHHHHHHHHHh.",
        "HHHHHHHHHHHHH",
        ".HHHHhHhHHHH.",
        "...HHHHHHH...",
    ], ["H": hair, "h": hairShade])
    c.rect(26, 32, 4, 1, C(0x8A5A48))

    let gun = C(0x34343A), trim = C(0xB8903A)
    if scratching, let s = sig {
        // The wall comes up beside him; the letters scratch in one by one.
        let fade = min(1, min(s, 1 - s) / 0.06)
        let stone = C(0x6A6560, fade), mortar = C(0x4A4642, fade), scratch = C(0xF0E8D8, fade)
        c.rect(43, 11, 21, 16, stone)
        for y in [15, 19, 23] { c.rect(43, y, 21, 1, mortar) }
        for (i, y) in [11, 15, 19, 23].enumerated() {
            for x in stride(from: 45 + (i % 2) * 4, to: 63, by: 8) { c.rect(x, y, 1, 4, mortar) }
        }
        let letters: [(Character, Int, Int)] = [("N", 49, 13), ("O", 54, 13),
                                                ("M", 45, 20), ("O", 51, 20), ("R", 55, 20), ("E", 59, 20)]
        let k = max(0, min(1, (s - 0.12) / 0.7))
        let done = Int(k * Double(letters.count))
        for (i, l) in letters.enumerated() where i < done || (i == done && k < 1) {
            let rows = scratchFont[l.0] ?? []
            let shown = i < done ? rows.count : Int((k * Double(letters.count) - Double(done)) * Double(rows.count))
            c.pattern(l.1, l.2, Array(rows.prefix(shown)), ["X": scratch])
        }
        // His arm up to the wall, the gun's muzzle doing the scratching.
        let cur = letters[min(done, letters.count - 1)]
        let jiggle = Int(p.t * 14) % 2
        let hx = cur.1 - 2, hy = cur.2 + 4 + jiggle
        drawLimb(c, 39, 32, hx, hy, sleeve: leather)
        c.rect(hx, hy - 2, 2, 1, gun); c.rect(hx + 1, hy - 3, 2, 1, gun)
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, leather)
    c.pattern(40, 31, ["KKKKKKKK", "KTTKKKK.", "KK......", "KK......"], ["K": gun, "T": trim])
}

// MARK: - The Fugitive Doctor

/// The Fugitive Doctor: Clawd with short dark curls, a tan utility coat with a pocket on each side and a collar turned
/// up, a dark top, dark trousers and boots, a holster on her hip and a black pistol. Signature: she draws, spins the
/// pistol round her finger and holsters it again.
private func drawFugitiveDoctor(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x9A8458), coatDark = C(0x74603C), pocket = C(0x84703F), top = C(0x2A2A30)
    let hair = C(0x1A1210), hairLight = C(0x3A2A22), holster = C(0x4A3020)
    let gun = C(0x1E1E24), trim = C(0xC8A040)
    let sig = p.signature
    let phase: Int = {
        guard let s = sig else { return -1 }
        switch s {
        case 0.04..<0.14: return 0    // hand on the holster
        case 0.14..<0.3: return 1     // drawn and aimed
        case 0.3..<0.74: return 2     // spinning
        case 0.74..<0.92: return 3    // holstering
        default: return -1
        }
    }()

    drawLegs(c, Look(leg: C(0x26262C)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x2A1E16), sole: C(0x140E0A))
    c.oy += p.breathe
    drawBody(c, Look(arm: coat))
    // The utility coat open over the dark top, a pocket each side, the collar up.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 33, 8, 5, top)
    c.rect(19, 35, 4, 2, pocket); c.rect(19, 35, 4, 1, coatDark)
    c.rect(33, 35, 3, 2, pocket); c.rect(33, 35, 3, 1, coatDark)
    c.rect(23, 33, 1, 5, coatDark); c.rect(32, 33, 1, 5, coatDark); c.rect(37, 33, 1, 5, coatDark)
    c.rect(20, 32, 3, 2, coat); c.rect(33, 32, 3, 2, coat)   // the collar
    // Belt and holster on the right hip.
    c.rect(18, 37, 20, 1, C(0x2A1E14))
    c.rect(35, 36, 3, 4, holster)
    if phase == 0 { c.rect(35, 35, 3, 1, gun); c.px(36, 34, gun) }
    // Short dark curls.
    c.pattern(18, 21, [
        "....hHhHHhHHhH......",
        "..HHHHHHhHHHHHHHH...",
        ".HHHHHhHHHHHHhHHHH..",
        ".HHhHHHHHHHHHHHHHHH.",
        "HHHHHHHHhHHHHHHhHHHH",
        "Hh................hH",
    ], ["H": hair, "h": hairLight])

    switch phase {
    case 0:
        c.rect(38, 33, 3, 3, coat); c.rect(37, 35, 2, 2, clawdOrange)
        return
    case 2:
        // The spin: the pistol turns round her trigger finger.
        c.rect(38, 33, 3, 3, coat); c.rect(40, 32, 2, 2, clawdOrange)
        let k = Int((sig! - 0.3) / 0.44 * 12) % 4
        switch k {
        case 0: c.pattern(41, 30, ["KKKKKK", "KTKK..", "K....."], ["K": gun, "T": trim])
        case 1: c.pattern(41, 25, ["K.", "K.", "K.", "KK", "KT", "KK", ".K"], ["K": gun, "T": trim])
        case 2: c.pattern(36, 31, ["KKKKK.", "..KKTK", ".....K"], ["K": gun, "T": trim])
        default: c.pattern(42, 33, ["KK", "TK", "KK", ".K", ".K", ".K"], ["K": gun, "T": trim])
        }
        c.px(44 + (k % 2) * 2, 27 + k, white.alpha(0.5))
        return
    case 3:
        // Back down into the holster, barrel first.
        c.rect(38, 33, 3, 3, coat); c.rect(37, 33, 2, 2, clawdOrange)
        c.rect(36, 31, 2, 2, gun); c.rect(36, 33, 1, 3, gun); c.px(37, 31, trim)
        return
    case 1:
        c.oy -= 1
    default:
        c.oy += p.gunY
    }
    c.rect(38, 33, 3, 3, coat)
    drawPistol(c, x: 40, y: 31, body: gun, trim: trim)
}
