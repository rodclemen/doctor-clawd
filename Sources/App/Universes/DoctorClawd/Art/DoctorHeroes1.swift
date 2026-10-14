import Foundation

// Heroes: the Doctors. Every one of them is Clawd in costume: the hair, coat and suit drawn over (and around) the blocky
// body, the way the whole cast is done, with Clawd's own orange face showing. They don't carry guns: their weapon is
// the sonic screwdriver, a steady ray from its tip.

let doctorHeroes1: [DoctorHero: Persona] = [
    .doctorTen: Persona(name: "Doctor Ten", weapon: .lightning, magic: Magic(core: C(0xE8F4FF), glow: C(0x3A8CFF), jagged: false),
                  pivot: sonicTip, headTop: 18, signature: 3.0, callout: "Allons-y!",
                  draw: drawDoctorTen),
]

/// Where a Doctor's sonic screwdriver tip is, held out: the ray leaves from there (raised by the pose's `armRaise`).
private let sonicTip = (x: 46.0, y: 30.0)

// MARK: - Shared bits

/// Trainers on the four feet, `upper` canvas over a white sole; the lifted pair a row higher while walking.
private func drawTrainers(_ c: PixelCanvas, step: Int, upper: Px, sole: Px = C(0xF2F0EA)) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let y = step >= 0 && i % 2 == step ? 41 : 42
        c.rect(lx, y, 2, 1, upper); c.rect(lx, y + 1, 2, 1, sole)
    }
}

/// The sonic screwdriver in the right hand. Pointed out (`out`), its tip at `sonicTip`, `lift` higher, lit while it
/// buzzes; at rest, held upright in the fist.
private func drawSonic(_ c: PixelCanvas, out: Bool, lift: Int, lit: Bool, tip: Px, t: Double) {
    let grip = C(0x4A4A52), steel = C(0xC8CCD4), claw = C(0x8A8E98)
    let glow = lit ? tip : tip.alpha(0.55)
    if out {
        let y = 32 - lift
        c.rect(41, y, 2, 1, grip); c.rect(43, y - 1, 2, 1, steel); c.px(45, y - 2, claw); c.px(46, y - 2, glow)
        if lit && sin(t * 30) > 0 { c.px(47, y - 3, tip.alpha(0.5)) }
    } else {
        c.rect(39, 29, 1, 4, grip); c.rect(39, 27, 1, 2, steel); c.px(39, 26, glow)
    }
}

/// Thick black-framed glasses over the eyes.
private func drawSpecs(_ c: PixelCanvas) {
    let frame = C(0x16161B)
    for x0 in [20, 30] {
        c.rect(x0, 28, 6, 1, frame); c.rect(x0, 32, 6, 1, frame); c.rect(x0, 28, 1, 5, frame); c.rect(x0 + 5, 28, 1, 5, frame)
        c.rect(x0 + 1, 29, 4, 3, C(0xE8F4FF, 0.35))
    }
    c.rect(26, 29, 4, 1, frame)
}

// MARK: - Doctor Ten

/// Doctor Ten: Clawd with the tall brown hair pushed up into spikes and long sideburns, a brown pinstripe suit with a
/// thin red tie, the long brown coat over it (its tails behind his legs) and red trainers. He holds the sonic screwdriver
/// upright in his fist and points it to use it, its tip glowing blue. Signature: Allons-y: he puts his glasses on with
/// one finger, then throws a fist up with a little hop.
private func drawDoctorTen(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x6A4A32), suitDark = C(0x4E3624), stripe = C(0x8A6A4E)
    let coat = C(0x8A5E3A), coatDark = C(0x6A4428), hair = C(0x4A2E1A), hairLight = C(0x6A4428)
    let shirt = C(0xEDE6D8), tie = C(0xA8202A)
    let sig = p.signature
    let specs = sig.map { $0 > 0.22 && $0 < 0.95 } ?? false
    let adjusting = sig.map { $0 > 0.08 && $0 < 0.3 } ?? false
    let punch = sig.map { $0 > 0.42 && $0 < 0.86 } ?? false
    if punch { c.oy -= (sig.map { $0 > 0.5 && $0 < 0.7 } ?? false) ? 2 : 0 }

    // The coat's tails, behind the legs.
    if !seatedPose {
        c.rect(17, 36, 22, 4, coatDark)
        c.rect(17, 39, 22, 1, coatDark.alpha(0.8))
    }
    drawLegs(c, Look(leg: suit), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xC8282E))
    c.oy += p.breathe

    let using = p.zap != nil || p.ready || p.cheering || (!p.resting && !p.walking)
    let raise = using ? p.armRaise : 0
    drawBody(c, Look(arm: coat), armRight: 0)
    // The suit: pinstripes, shirt collar and tie, the coat open over it.
    c.rect(18, 33, 20, 5, suit)
    for x in stride(from: 19, to: 37, by: 3) { c.rect(x, 33, 1, 5, stripe) }
    c.rect(37, 33, 1, 5, suitDark)
    c.rect(25, 33, 6, 2, shirt); c.rect(27, 33, 2, 5, tie); c.px(27, 33, C(0x7A1218))
    c.rect(18, 33, 3, 5, coat); c.rect(35, 33, 3, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(21, 33, 1, 3, coatDark); c.rect(34, 33, 1, 3, coatDark)   // the lapels
    c.rect(15, 33, 3, 3, coat)
    // The hair: up in spikes, sideburns down past the eyes.
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
    ], ["H": hair, "l": hairLight])
    if specs { drawSpecs(c) }

    // The right arm: up to his glasses, punched up, pointing the sonic, or holding it at rest.
    if adjusting {
        c.rect(38, 30, 3, 3, coat); c.rect(33, 28, 5, 1, coat)
        c.rect(38, 33, 1, 2, coatDark)
        return
    }
    if punch || p.cheering {
        c.rect(38, 24, 3, 9, coat); c.rect(38, 22, 3, 2, clawdOrange)
        return
    }
    if using {
        c.rect(38, 31 - raise, 3, 3, coat)
        drawSonic(c, out: true, lift: raise, lit: p.zap == true, tip: C(0x6AB8FF), t: p.t)
    } else {
        c.rect(38, 31, 3, 3, coat); c.rect(38, 30, 3, 1, clawdOrange)
        drawSonic(c, out: false, lift: 0, lit: false, tip: C(0x6AB8FF), t: p.t)
    }
}
