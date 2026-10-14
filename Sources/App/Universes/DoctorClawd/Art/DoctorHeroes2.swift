import Foundation

// Heroes: the first eight Doctors, Clawd in each one's coat, hair and hat. Most point the sonic screwdriver (each with
// their own tip colour); Doctor Three fights with a Venusian aikido chop and Doctor Five bowls cricket balls.

let doctorHeroes2: [DoctorHero: Persona] = [
    .doctorOne: Persona(name: "Doctor One", weapon: .lightning, magic: Magic(core: C(0xFFFBEA), glow: C(0xE8C860), jagged: false),
                  pivot: sonicTip, headTop: 21, signature: 3.0, callout: "Hmm!",
                  draw: drawDoctorOne),
    .doctorTwo: Persona(name: "Doctor Two", weapon: .lightning, magic: Magic(core: C(0xE8FFFF), glow: C(0x3AD0D8), jagged: false),
                  pivot: sonicTip, headTop: 20, signature: 3.2, callout: "Oh, crumbs!",
                  draw: drawDoctorTwo),
    .doctorThree: Persona(name: "Doctor Three", weapon: .saber, headTop: 19, signature: 2.8, callout: "Hai!",
                  draw: drawDoctorThree),
    .doctorFour: Persona(name: "Doctor Four", weapon: .lightning, magic: Magic(core: C(0xFFF6D8), glow: C(0xFFB21E), jagged: false),
                  pivot: sonicTip, headTop: 16, signature: 3.6, callout: "Jelly baby?",
                  draw: drawDoctorFour),
    .doctorFive: Persona(name: "Doctor Five", weapon: .blaster, shot: .thrown(C(0xB4202A)), muzzle: (45, 31),
                  handGun: false, headTop: 21, signature: 3.0, callout: "Howzat!",
                  draw: drawDoctorFive),
    .doctorSix: Persona(name: "Doctor Six", weapon: .lightning, magic: Magic(core: C(0xF6E8FF), glow: C(0xB46AFF), jagged: false),
                  pivot: sonicTip, headTop: 19, signature: 2.8, callout: "Change, my dear!",
                  draw: drawDoctorSix),
    .doctorSeven: Persona(name: "Doctor Seven", weapon: .lightning, magic: Magic(core: C(0xFFE8E8), glow: C(0xFF4A4A), jagged: false),
                  pivot: sonicTip, headTop: 17, signature: 3.4, callout: "Spoons at dawn!",
                  draw: drawDoctorSeven),
    .doctorEight: Persona(name: "Doctor Eight", weapon: .lightning, magic: Magic(core: C(0xE8FFF6), glow: C(0x3AE0B0), jagged: false),
                  pivot: sonicTip, headTop: 20, signature: 3.0, callout: "About time!",
                  draw: drawDoctorEight),
]

// MARK: - Shared bits

private let clear = C(0x000000, 0)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `from` along `angle` degrees (0 forward, -90 straight up).
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// The ground row under the feet (sitting, the whole sprite is drawn 4 px lower, so it's higher in the art's terms).
private var groundRow: Int { seatedPose ? 39 : 43 }

/// Whether a Doctor has the sonic out: using it, waiting on you, cheering, or just busy.
private func sonicOut(_ p: Pose) -> Bool { p.zap != nil || p.ready || p.cheering || (!p.resting && !p.walking) }

/// A long coat's tails behind the legs, `flare` pixels wider on each side.
private func drawTails(_ c: PixelCanvas, _ col: Px, flare: Int = 0, long: Bool = false) {
    guard !seatedPose else { return }
    c.rect(17 - flare, 36, 22 + flare * 2, long ? 5 : 4, col)
    c.rect(17 - flare, long ? 41 : 39, 22 + flare * 2, 1, col.alpha(0.8))
}

/// The right arm with the sonic: thrown up when cheering, pointing it (lit while it buzzes) when it's out; at rest
/// `rest` draws what's in the hand, or the sonic held upright.
private func drawSonicArm(_ c: PixelCanvas, _ p: Pose, sleeve: Px, tip: Px, rest: ((PixelCanvas) -> Void)? = nil) {
    if p.cheering {
        c.rect(38, 24, 3, 9, sleeve); c.rect(38, 22, 3, 2, clawdOrange)
    } else if sonicOut(p) {
        c.rect(38, 31 - p.armRaise, 3, 3, sleeve)
        drawSonic(c, out: true, lift: p.armRaise, lit: p.zap == true, tip: tip, t: p.t)
    } else if let rest {
        rest(c)
    } else {
        c.rect(38, 31, 3, 3, sleeve); c.rect(38, 30, 3, 1, clawdOrange)
        drawSonic(c, out: false, lift: 0, lit: false, tip: tip, t: p.t)
    }
}

/// A floating musical note, `f` 0…1 through its rise from (x, y) (it drifts up and fades).
private func drawNote(_ c: PixelCanvas, x: Int, y: Int, f: Double, _ col: Px) {
    let k = col.alpha(1 - f)
    c.pattern(x + Int(sin(f * 9) * 1.5), y - Int(f * 10), [".kk", ".k.", "kk.", "kk."], ["k": k])
}

// MARK: - Doctor One

/// Doctor One: Clawd with swept-back white hair, receding at the front and long at the sides, a black frock coat with
/// grey lapels over a waistcoat (a gold watch chain across it), a wing collar and dark cravat, checked trousers. He
/// leans on a black cane with a silver knob, and moves it to his other hand to point the sonic (pale gold tip).
/// Signature: he grips his lapels and rocks up on his heels, "Hmm!", the cane leant against him.
private func drawDoctorOne(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x22222A), coatDark = C(0x16161C), lapel = C(0x4A4A54), vest = C(0x5E5848), vestDark = C(0x46412F)
    let check = C(0x707074), checkDark = C(0x505054), shirt = C(0xF0ECE2), gold = C(0xE0B848)
    let hair = C(0xF2F2F4), hairShade = C(0xC0C0CC), cane = C(0x2E2018), knob = C(0xD8DCE4)
    let tip = C(0xFFE07A)
    let grip = p.signature.map { $0 > 0.08 && $0 < 0.92 } ?? false
    if let s = p.signature, grip, sin((s - 0.08) * .pi * 7) > 0.4 { c.oy -= 1 }   // up on his heels: "Hmm!"

    drawTails(c, coat)
    drawLegs(c, Look(leg: check), step: p.step)
    if !seatedPose {
        for lx in [19, 23, 31, 35] { for y in stride(from: 37, to: 42, by: 2) { c.px(lx + (y / 2) % 2, y, checkDark) } }
    }
    drawTrainers(c, step: p.step, upper: C(0x141418), sole: C(0x2E2E34))
    c.oy += p.breathe

    drawBody(c, Look(arm: coat))
    // The frock coat open over the waistcoat, collar and cravat.
    c.rect(18, 33, 20, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(23, 33, 10, 5, vest); c.rect(23, 37, 10, 1, vestDark)
    c.px(28, 35, gold); c.px(28, 37, gold)
    c.rect(24, 35, 3, 1, gold); c.px(27, 36, gold)                 // the watch chain
    c.rect(25, 33, 6, 1, shirt); c.rect(27, 33, 2, 2, ink)          // wing collar and cravat
    c.rect(21, 33, 2, 4, lapel); c.rect(33, 33, 2, 4, lapel)
    c.rect(15, 33, 3, 3, coat)
    // The hair: back off the forehead, long down the sides.
    c.pattern(17, 21, [
        "......WWWWWWWWW.......",
        "...WWWWWWWWWWWWWW.....",
        "..WWWwWWWWWWWWWWWWW...",
        "..WWWWWWWWWwWWWWWWWW..",
        ".WWWWWWwWWWWWWWWWWWWW.",
        ".WWWWWW........wWWWWW.",
        ".WWWW.............WWW.",
        ".WWW...............WW.",
        ".WWw...............WW.",
        ".WW................Ww.",
        ".Ww................WW.",
        "..W................W..",
    ], ["W": hair, "w": hairShade])

    let g = groundRow
    if grip {
        // Hands on the lapels; the cane leans on him.
        c.rect(20, 33, 2, 2, clawdOrange); c.rect(34, 33, 2, 2, clawdOrange)
        bar(c, 41.5, Double(g) + 0.5, 38.5, 31, cane, 0.55)
        c.rect(38, 30, 2, 1, knob)
        return
    }
    if sonicOut(p) && !p.cheering {
        c.rect(14, 33, 1, g - 33 + 1, cane); c.rect(13, 32, 2, 1, knob)   // the cane in the other hand
    }
    drawSonicArm(c, p, sleeve: coat, tip: tip) { c in
        c.rect(41, 32, 1, g - 32 + 1, cane); c.rect(40, 31, 3, 1, knob)
        c.rect(38, 32, 2, 3, coat); c.rect(40, 32, 2, 2, clawdOrange)
    }
}

// MARK: - Doctor Two

/// Doctor Two: Clawd under a black mop of hair with a ragged fringe down to the eyes, a baggy black frock coat a size
/// too big (it hangs wide of the body), a white shirt with a little red bow tie, check trousers. His sonic glows
/// cyan. Signature: he plays the recorder, both hands on it, notes floating off.
private func drawDoctorTwo(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x24222A), coatDark = C(0x18161C), coatLight = C(0x3A3644), hair = C(0x16120E), hairLight = C(0x3A3028)
    let check = C(0x7A6E5E), checkDark = C(0x5A5044), shirt = C(0xEEE8DC), bow = C(0xA8283A)
    let recorder = C(0xC8955A), recorderDark = C(0x6A4424), tip = C(0x5AE8F0)
    let playing = p.signature.map { $0 > 0.06 && $0 < 0.94 } ?? false

    // The coat's baggy skirts.
    if !seatedPose { c.rect(15, 36, 26, 5, coatDark); c.rect(15, 40, 26, 1, coat) }
    drawLegs(c, Look(leg: check), step: p.step)
    if !seatedPose {
        for lx in [19, 23, 31, 35] { for y in stride(from: 41, to: 43, by: 1) { c.px(lx + y % 2, y, checkDark) } }
    }
    drawTrainers(c, step: p.step, upper: C(0x141416), sole: C(0x2A2A2E))
    c.oy += p.breathe

    drawBody(c, Look(arm: coat))
    // The coat: hanging off him, wider than he is, sleeves down over the hands.
    c.rect(16, 33, 24, 5, coat); c.rect(16, 37, 24, 1, coatDark); c.rect(39, 33, 1, 5, coatDark)
    c.rect(24, 33, 8, 4, shirt)
    c.rect(26, 33, 1, 2, bow); c.rect(29, 33, 1, 2, bow); c.rect(27, 33, 2, 1, bow)
    c.rect(22, 33, 2, 5, coatLight); c.rect(32, 33, 2, 5, coatLight)
    c.rect(14, 33, 4, 4, coat)
    // The mop.
    c.pattern(17, 20, [
        ".....HHHHHHHHHHH......",
        "...HHHHHHlHHHHHHHH....",
        "..HHHHlHHHHHHHlHHHH...",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHlHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHlHHHH",
        "HHHlHHHHHHHHHHHHHHHHHH",
        "HHHH.H.HH.H..H.HH.HHHH",
        "HHH................HHH",
        "HH..................HH",
        "HH..................HH",
        ".H..................H.",
    ], ["H": hair, "l": hairLight])

    if playing, let s = p.signature {
        // The recorder down from his mouth, both hands on it; notes drift off.
        bar(c, 28.5, 32, 34.5, 41.5, recorder, 0.75)
        c.rect(28, 31, 2, 1, C(0xF2E6CC)); c.px(33, 39, recorderDark); c.px(34, 41, recorderDark)
        c.rect(27, 34, 2, 2, clawdOrange); c.rect(32, 36, 2, 2, clawdOrange)
        let wiggle = Int(s * 24) % 2
        c.oy -= wiggle
        for i in 0..<3 {
            let f = frac(s * 2.2 + Double(i) / 3)
            drawNote(c, x: 36 + i * 3, y: 28, f: f, i == 1 ? C(0x5AE8F0) : C(0xF2EEE0))
        }
        return
    }
    drawSonicArm(c, p, sleeve: coat, tip: tip)
}

// MARK: - Doctor Three

/// Doctor Three: Clawd with a big bouffant of white hair, a plum velvet smoking jacket over a white frilled shirt, and
/// a black opera cape lined red billowing behind. No sonic in a fight: Venusian aikido, an open-hand chop (melee),
/// the frilled cuff showing. Signature: he raises the flat hand high, "Hai!", and chops it down with a snap.
private func drawDoctorThree(_ c: PixelCanvas, _ p: Pose) {
    let velvet = C(0x7A1A34), velvetDark = C(0x56102A), velvetLight = C(0x9A2C4A), frill = C(0xF6F2EA), frillShade = C(0xC8C0B4)
    let hair = C(0xECECF0), hairShade = C(0xB4B4C2), cape = C(0x1A1820), lining = C(0xB0202E)

    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: lining)
    drawLegs(c, Look(leg: C(0x5E5A66)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x141418), sole: C(0x24242A))
    c.oy += p.breathe

    drawBody(c, Look(arm: velvet))
    // The velvet jacket and the frills down the front.
    c.rect(18, 33, 20, 5, velvet); c.rect(37, 33, 1, 5, velvetDark); c.rect(18, 37, 20, 1, velvetDark)
    c.rect(22, 33, 2, 4, velvetLight); c.rect(32, 33, 2, 4, velvetLight)
    c.pattern(24, 33, ["FFFFFFFF", ".FfFFfF.", "FFFFFFFF", ".FfFFfF.", "..FFFF.."], ["F": frill, "f": frillShade])
    c.rect(18, 32, 2, 1, lining); c.rect(36, 32, 2, 1, lining)        // the cape's clasp edges
    c.rect(15, 33, 3, 3, velvet)
    // The bouffant.
    c.pattern(16, 19, [
        "......WWWWWWWWWW........",
        "....WWWWWWWWWWWWWW......",
        "...WWWWwWWWWWWWWWWWW....",
        "..WWWWWWWWWWwWWWWWWWWW..",
        "..WWwWWWWWWWWWWWWWWwWWW.",
        ".WWWWWWWWWWWWWWWWWWWWWW.",
        ".WWWWWWwWWWWWWWwWWWWWWW.",
        ".WWWWWW..........WWWWWW.",
        ".WWWW..............WWWW.",
        ".WWw................WWW.",
        "..WW................wW..",
        "..Ww................WW..",
        "..W..................W..",
    ], ["W": hair, "w": hairShade])

    // The chop: the fight's swing, or the signature.
    var angle = p.melee
    var trail = p.trail
    var snap = false
    if let s = p.signature {
        if s < 0.32 { angle = -40 - 60 * min(1, s / 0.2) }
        else if s < 0.44 { let k = (s - 0.32) / 0.12; angle = -100 + 125 * k; trail = [-100 + 125 * k - 25, -100 + 125 * k - 50] }
        else if s < 0.8 { angle = 25; snap = s < 0.62 }
        else { angle = 25 - 60 * (s - 0.8) / 0.2 }
        if s > 0.4 && s < 0.62 { c.oy += 1 }
    }
    if p.cheering { angle = -95 }
    guard let a = angle else {
        c.rect(38, 33, 3, 3, velvet); c.rect(41, 33, 1, 3, frill)
        return
    }
    for (i, t) in trail.enumerated() {
        let m = along(t, 6), e = along(t, 10)
        bar(c, m.x, m.y, e.x, e.y, clawdOrange.alpha(0.4 / Double(i + 1)), 0.9)
    }
    let h = Sprite.hand
    let s0 = along(a, 4), m = along(a, 6), e = along(a, 10)
    bar(c, h.x - 3, h.y - 0.5, s0.x, s0.y, velvet, 1.3)
    bar(c, s0.x, s0.y, m.x, m.y, frill, 1.3)
    bar(c, m.x, m.y, e.x, e.y, clawdOrange, 0.75)                  // the flat hand, edge on
    let th = along(a - 70, 2, from: m)
    c.px(Int(th.x), Int(th.y), clawdOrange)                         // the thumb
    if snap {
        let k = along(a, 12)
        for d in [-60.0, 0, 60] {
            let q = along(a + d, 2.5, from: k), r = along(a + d, 4.5, from: k)
            bar(c, q.x, q.y, r.x, r.y, C(0xFFF4C8), 0.4)
        }
    }
}

// MARK: - Doctor Four

/// The colours of Doctor Four's scarf, in its stripe order.
private let scarfStripes = [C(0x7A3A62), C(0xD8A030), C(0xB0502A), C(0x5E7A3A), C(0x8A6A4A), C(0xE0C890)]

/// One stripe of the scarf, `n` stripes along it.
private func scarf(_ n: Int) -> Px { scarfStripes[((n % scarfStripes.count) + scarfStripes.count) % scarfStripes.count] }

/// Doctor Four: Clawd under a wide-brimmed brown felt hat with a big shock of dark curls puffing out below it, a long
/// rust coat, and the endless striped scarf: wound round his neck, one end hanging to his feet in front and the other
/// trailing far behind along the ground. His sonic glows amber. Signature: he offers a paper bag of jelly babies, then
/// twirls the scarf's long end round over his head.
private func drawDoctorFour(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x7A3E2A), coatDark = C(0x5A2C1E), shirt = C(0xE8DCC0), hat = C(0x6A4A2E), hatDark = C(0x4E3420)
    let band = C(0x2E2018), curl = C(0x3A2416), curlLight = C(0x5E3E26), tip = C(0xFFC23A)
    let offering = p.signature.map { $0 > 0.05 && $0 < 0.45 } ?? false
    let twirl: Double? = p.signature.flatMap { $0 >= 0.5 && $0 < 0.98 ? ($0 - 0.5) / 0.48 : nil }
    let g = groundRow

    // The scarf's long end, trailing behind along the ground (unless it's being twirled).
    if twirl == nil {
        for y in 33...(g - 1) { c.rect(15, y, 3, 1, scarf((y - 33) / 2)) }
        let run = seatedPose ? 6 : 10 + Int(sin(p.lt * 1.3) * 1)
        for i in 0..<run { c.rect(14 - i, g - 1, 1, 2, scarf((g - 33) / 2 + i / 2)) }
        c.px(14 - run, g, scarf(0)); c.px(14 - run, g - 1, scarf(0))
    }
    drawTails(c, coatDark, long: true)
    drawLegs(c, Look(leg: C(0x5A4636)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x3A2618), sole: C(0x24180E))
    c.oy += p.breathe

    drawBody(c, Look(arm: coat))
    c.rect(18, 33, 20, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(24, 34, 8, 4, shirt); c.rect(22, 34, 2, 4, coatDark); c.rect(32, 34, 2, 4, coatDark)
    c.rect(15, 33, 3, 3, coat)
    // The scarf round his neck, and its front end down to his feet.
    for x in 18...37 { c.rect(x, 32, 1, 2, scarf(x / 2)) }
    for y in 34...(g - 1) { c.rect(23, y, 3, 1, scarf((y - 34) / 2 + 3)) }
    for x in [23, 25] { c.px(x, g, scarf(1)) }

    // The curls, then the hat.
    c.pattern(15, 22, [
        "..CCcCCCCcCCCCCCcCCCCcC...",
        ".CCCCCcCCCCCCCcCCCCCCCcC..",
        "CCcCCCCCCCCCCCCCCCCCCCcCC.",
        "CCCCCCcCCCCCcCCCCCcCCCCCCC",
        "CCCcCC.CC.C..C.CC.C.CcCCC.",
        "CCCCC..............CCCCcC.",
        "CcCCC..............CCCCC..",
        "CCCc................cCCC..",
        "CCCC................CCCC..",
        ".CCC................CCC...",
        "..C..................C....",
    ], ["C": curl, "c": curlLight])
    c.pattern(15, 16, [
        "........HHHHHHHHHH........",
        ".......HHHHhHHHHHHH.......",
        ".......HHHHHHHHHHHH.......",
        ".......BBBBBBBBBBBB.......",
        "..HHHHHHHHHHHHHHHHHHHHHH..",
        "hHHHHHHHHHHHHHHHHHHHHHHHHh",
    ], ["H": hat, "h": hatDark, "B": band])

    if offering {
        // A paper bag of jelly babies held out.
        c.rect(38, 31, 4, 3, coat); c.rect(42, 31, 2, 2, clawdOrange)
        c.pattern(41, 25, [".rgy.", "WbWpW", "WWWWW", "WWWWW", ".WWW."],
                  ["W": C(0xF2EEE2), "r": C(0xE0303A), "g": C(0x3AC04A), "y": C(0xF0D030), "b": C(0x3A6AE0), "p": C(0xE06AC0)])
        return
    }
    if let k = twirl {
        // The long end swung round over his head.
        let base = 225 + 75 * sin(k * 2 * .pi * 2)
        for i in 0..<20 {
            let a = (base - Double(i) * 2.2) * .pi / 180
            let x = 17 + cos(a) * Double(i), y = 33 + sin(a) * Double(i)
            c.rect(Int(x.rounded()), Int(y.rounded()), 2, 2, scarf(i / 2))
        }
        c.rect(38, 30, 3, 3, coat); c.rect(38, 29, 3, 1, clawdOrange)
        return
    }
    drawSonicArm(c, p, sleeve: coat, tip: tip)
}

// MARK: - Doctor Five

/// Doctor Five: Clawd with a floppy fair fringe, in a cream cricket coat piped red, a V-neck cricket jumper with a red
/// and green stripe, and a stick of celery pinned to his lapel; pale striped trousers, cricket shoes. He fights by
/// bowling cricket balls. Signature: he polishes the ball on his trousers, then winds his arm right over and bowls it.
private func drawDoctorFive(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xEAE4D0), coatShade = C(0xC8C0A6), piping = C(0xC8402A), jumper = C(0xF4F0E4)
    let hair = C(0xE8C878), hairShade = C(0xC49E52), celery = C(0x8AD04A), leaf = C(0x4E9A2E)
    let ball = C(0xB4202A), seam = C(0xF0E0C0), stripe = C(0xC4BEB0)

    drawTails(c, coatShade)
    drawLegs(c, Look(leg: C(0xE4E0D2)), step: p.step)
    if !seatedPose { for lx in [20, 24, 32, 36] { c.rect(lx, 37, 1, 4, stripe) } }
    drawTrainers(c, step: p.step, upper: C(0xF2EEE4), sole: C(0x8A6A4A))
    c.oy += p.breathe

    drawBody(c, Look(arm: coat))
    // The coat with its red piping, the V of the jumper, the celery.
    c.rect(18, 33, 20, 5, coat); c.rect(37, 33, 1, 5, coatShade)
    c.rect(23, 33, 10, 5, jumper)
    c.rect(26, 33, 4, 2, C(0xFFFFFF))
    c.pattern(25, 33, ["rg..gr", ".rggr."], ["r": C(0xC8302A), "g": C(0x3A8A3A)])
    c.rect(22, 33, 1, 5, piping); c.rect(33, 33, 1, 5, piping)
    c.rect(35, 33, 1, 4, celery); c.px(34, 33, leaf); c.px(36, 33, leaf); c.px(35, 32, leaf)
    c.rect(15, 33, 3, 3, coat)
    c.pattern(17, 21, [
        ".....HHHHHHHHHH.......",
        "...HHHHHHHHHHHHHHH....",
        "..HHHHhHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHhHHH.",
        ".HHHHHHHhHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHhHHHHH..HH...HHH.",
        ".HHH...HH.........HHH.",
        ".HH................HH.",
        ".H..................H.",
    ], ["H": hair, "h": hairShade])

    func drawBall(_ x: Int, _ y: Int) { c.rect(x, y, 2, 2, ball); c.px(x, y, seam) }

    if let s = p.signature {
        if s < 0.3 {
            // Polishing the ball on his trouser leg.
            let rub = Int(sin(s * 60))
            c.rect(37, 33, 2, 4, coat); drawBall(37, 36 + rub); c.px(39, 36 + rub, clawdOrange)
            return
        }
        if s < 0.58 {
            // The arm windmills over: down, back, over the top, released in front.
            let k = (s - 0.3) / 0.28
            let a = 90 + 270 * k
            let sh = (x: 37.0, y: 31.0), e = along(a, 8, from: sh)
            bar(c, sh.x, sh.y, e.x, e.y, coat, 1.2)
            drawBall(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1)
            return
        }
        // Bowled: the arm follows through and the ball bounces away.
        let k = (s - 0.58) / 0.42
        c.rect(38, 33, 4, 2, coat); c.rect(42, 33, 2, 2, clawdOrange)
        let x = 44 + k * 26
        let y = k < 0.5 ? 28 + (k / 0.5) * 14 : 42 - sin((k - 0.5) / 0.5 * .pi) * 6
        drawBall(Int(x), Int(y))
        return
    }
    if p.cheering {
        c.rect(38, 24, 3, 9, coat); drawBall(38, 22)
        return
    }
    if p.recoil > 0 {
        // Just bowled: the hand's empty, thrown forward.
        c.rect(38, 31, 4, 3, coat); c.rect(42, 31, 2, 2, clawdOrange)
        return
    }
    c.oy += p.gunY
    let busy = !p.resting && !p.walking
    if busy || p.ready {
        c.rect(38, 30, 3, 3, coat); drawBall(41, 29)
    } else {
        c.rect(38, 33, 2, 3, coat); drawBall(40, 34)
    }
}

// MARK: - Doctor Six

/// Doctor Six: Clawd with a bush of bright blond curls, in a garish patchwork frock coat (yellow, red, green, blue,
/// pink and orange patches, broad green lapels) with a little silver cat badge on the lapel and a spotted cravat;
/// yellow trousers, green and cream shoes. His sonic glows violet. Signature: he flares the coat tails out wide with
/// a flourish and the cat badge glints.
private func drawDoctorSix(_ c: PixelCanvas, _ p: Pose) {
    let patches = [C(0xE8C020), C(0xC8302A), C(0x2E9A4A), C(0x3A6AC8), C(0xE06AA0), C(0xE8802A), C(0x8A3AAA)]
    let lapel = C(0x2A8A3A), hair = C(0xF4D24A), hairShade = C(0xD0A42A), badge = C(0xD0D4DC)
    let trousers = C(0xD8B840), trouserStripe = C(0xA88A2A), tip = C(0xC07AFF)
    let flare = p.signature.map { s -> Int in s < 0.5 ? Int(sin(s / 0.5 * .pi) * 6) : 0 } ?? 0
    let glint = p.signature.map { $0 > 0.5 && $0 < 0.85 } ?? (frac(p.lt / 5) < 0.05)

    // Patchwork tails behind the legs, flared out in the signature.
    if !seatedPose {
        for x in (17 - flare)..<(39 + flare) {
            for y in 36..<(40 + flare / 3) { c.px(x, y, patches[((x + 40) / 4 * 3 + (y / 3) * 5) % patches.count]) }
        }
    }
    drawLegs(c, Look(leg: trousers), step: p.step)
    if !seatedPose { for lx in [20, 24, 32, 36] { c.rect(lx, 37, 1, 4, trouserStripe) } }
    drawTrainers(c, step: p.step, upper: C(0x2A8A3A), sole: C(0xE8E0C8))
    c.oy += p.breathe

    drawBody(c, Look(arm: patches[3]))
    // The patchwork.
    for y in 33...37 { for x in 18...37 { c.px(x, y, patches[((x - 18) / 4 * 3 + (y - 33) / 3 * 5 + 1) % patches.count]) } }
    c.rect(18, 37, 20, 1, C(0x000000, 0.2))
    c.rect(26, 33, 4, 2, C(0xF4F0E8)); c.px(27, 34, C(0xC8302A)); c.px(28, 33, C(0xC8302A))
    c.rect(22, 33, 3, 5, lapel); c.rect(31, 33, 3, 5, lapel)
    c.pattern(31, 33, ["b.b", "bbb"], ["b": badge])                  // the cat badge
    c.rect(15, 33, 3, 3, patches[0])
    c.pattern(16, 20, [
        ".....HHHhHHHHhHHH.......",
        "...HHhHHHHHHHHHHHhH.....",
        "..HHHHHHhHHHhHHHHHHH....",
        ".HHhHHHHHHHHHHHHhHHHHH..",
        ".HHHHHhHHHHHHHhHHHHHHHH.",
        "HHhHHHHHHhHHHHHHHHHhHHH.",
        "HHHHHH.hH.HH.hHH.HHHHHH.",
        ".HHHh............hHHHH..",
        ".HHH..............HHHH..",
        "HHhH...............HhH..",
        ".HH................HHH..",
        "..H.................H...",
    ], ["H": hair, "h": hairShade])
    if glint {
        c.px(33, 32, white); c.px(32, 31, white.alpha(0.6)); c.px(34, 31, white.alpha(0.6))
        c.px(33, 30, white.alpha(0.5)); c.px(35, 32, white.alpha(0.5))
    }
    if flare > 0 {
        c.rect(38, 30, 3, 3, patches[3]); c.rect(38, 29, 3, 1, clawdOrange)   // a hand flung up with the flourish
        return
    }
    drawSonicArm(c, p, sleeve: patches[3], tip: tip)
}

// MARK: - Doctor Seven

/// The question-mark umbrella's handle, its foot at (x, y): a red hook in the shape of a question mark.
private func drawQuestionHandle(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x - 2, y - 5, [".RRR.", "R...R", "....R", "...R.", "..R.."], ["R": C(0xD0202A)])
}

/// Doctor Seven: Clawd under a cream panama hat with a dark band, in a cream linen jacket over a red pullover with
/// question marks, brown check trousers and two-tone shoes. He carries the black umbrella with the red question-mark
/// handle, leaning on it at rest and moving it to the other hand to point the sonic (red tip). Signature: he spins the
/// umbrella like a baton, then rattles out a tune on the spoons.
private func drawDoctorSeven(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0xD8CCAA), jacketShade = C(0xB4A886), vest = C(0xA8282E), mark = C(0xF0C83A)
    let hat = C(0xEDE4C6), hatShade = C(0xC8BE9E), band = C(0x3A2A20), hair = C(0x3A2818)
    let canopy = C(0x1E1E26), shaft = C(0x34343C), tip = C(0xFF5A5A), spoon = C(0xD8DCE4)
    let g = groundRow

    drawLegs(c, Look(leg: C(0x7A5A3A)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx + 1, 38, C(0x5A402A)); c.px(lx, 40, C(0x5A402A)) } }
    drawTrainers(c, step: p.step, upper: C(0x5A3A22), sole: C(0xF0EAD8))
    c.oy += p.breathe

    drawBody(c, Look(arm: jacket))
    c.rect(18, 33, 20, 5, jacket); c.rect(37, 33, 1, 5, jacketShade); c.rect(18, 37, 20, 1, jacketShade)
    c.rect(23, 33, 10, 5, vest)
    for x in [24, 30] { c.pattern(x, 33, ["mm", ".m", "m.", "..", "m."], ["m": mark]) }   // question marks
    c.rect(27, 33, 2, 3, C(0x5A2A4A))                                  // the tie
    c.rect(22, 33, 1, 5, jacketShade); c.rect(33, 33, 1, 5, jacketShade)
    c.rect(15, 33, 3, 3, jacket)
    c.pattern(17, 23, [
        "..DDDDDDDDDDDDDDDDDD..",
        ".DDDDDDDDDDDDDDDDDDDD.",
        ".DDDDDDDDDDDDDDDDDDDD.",
        ".DD................DD.",
        ".D..................D.",
    ], ["D": hair])
    c.pattern(16, 17, [
        "........HHHHHHHH........",
        ".......HHHHHHHHHH.......",
        ".......HHHHhHHHHH.......",
        ".......BBBBBBBBBB.......",
        "...HHHHHHHHHHHHHHHHHH...",
        "..hHHHHHHHHHHHHHHHHHHh..",
    ], ["H": hat, "h": hatShade, "B": band])

    if let s = p.signature {
        if s < 0.5 {
            // Spun like a baton about the hand.
            let a = -90 + s / 0.5 * 720
            let h = (x: 41.0, y: 31.0), e1 = along(a, 7, from: h), e2 = along(a + 180, 7, from: h)
            bar(c, e1.x, e1.y, e2.x, e2.y, canopy, 0.8)
            let hk = along(a + 180, 6, from: h)
            c.rect(Int(hk.x) - 1, Int(hk.y) - 1, 2, 2, C(0xD0202A))
            c.rect(38, 30, 3, 3, jacket); c.rect(40, 30, 2, 2, clawdOrange)
            return
        }
        // The spoons, rattled between hand and knee.
        let clack = Int(s * 30) % 2
        c.rect(38, 33, 2, 3, jacket); c.rect(40, 34 + clack, 2, 2, clawdOrange)
        c.rect(42, 33 + clack, 1, 3, spoon); c.rect(43, 34 - clack + 1, 1, 3, spoon)
        c.px(42, 32 + clack, spoon); c.px(43, 34 - clack, spoon)
        if clack == 0 { c.px(45, 34, white.alpha(0.8)); c.px(44, 37, white.alpha(0.6)) }
        // The umbrella leant against him meanwhile.
        bar(c, 16.5, Double(g) + 0.5, 15, 30, canopy, 0.7); drawQuestionHandle(c, x: 15, y: 30)
        return
    }
    if sonicOut(p) && !p.cheering {
        c.rect(13, 31, 1, g - 31 + 1, shaft); c.rect(12, 34, 3, 6, canopy); drawQuestionHandle(c, x: 13, y: 31)
    }
    drawSonicArm(c, p, sleeve: jacket, tip: tip) { c in
        c.rect(42, 31, 1, g - 31 + 1, shaft); c.rect(41, 34, 3, 6, canopy); c.px(42, 40, canopy)
        drawQuestionHandle(c, x: 42, y: 31)
        c.rect(38, 32, 3, 3, jacket); c.rect(40, 31, 2, 2, clawdOrange)
    }
}

// MARK: - Doctor Eight

/// Doctor Eight: Clawd with long wavy chestnut hair falling past his shoulders, a bottle-green velvet Edwardian frock
/// coat (long tails) over a silver-grey waistcoat with a gold watch chain, a wing collar and cream cravat, grey
/// trousers. His sonic glows sea-green. Signature: he holds up his pocket watch by the chain and lets it swing.
private func drawDoctorEight(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x2A4A34), coatDark = C(0x1C3424), coatLight = C(0x3E6448), vest = C(0x9A9A8C), vestDark = C(0x74746A)
    let hair = C(0x6A3A1E), hairLight = C(0x8E5432), cravat = C(0xEADCC0), gold = C(0xE8C040), goldDark = C(0xB08A24)
    let tip = C(0x4AF0C0)

    drawTails(c, coatDark, long: true)
    drawLegs(c, Look(leg: C(0x5A5A62)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x141418), sole: C(0x2A2A30))
    c.oy += p.breathe

    drawBody(c, Look(arm: coat))
    c.rect(18, 33, 20, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(23, 33, 10, 5, vest); c.rect(23, 37, 10, 1, vestDark)
    for x in stride(from: 24, to: 33, by: 2) { c.px(x, 36, vestDark) }
    c.rect(25, 32, 6, 2, cravat); c.rect(27, 34, 2, 2, cravat)
    c.rect(29, 35, 3, 1, gold)
    c.rect(21, 33, 2, 5, coatLight); c.rect(33, 33, 2, 5, coatLight)
    c.rect(15, 33, 3, 3, coat)
    c.pattern(15, 20, [
        ".......HHHHHHHHHHH.......",
        ".....HHHHHHHHHHHHHHH.....",
        "....HHHlHHHHHHHlHHHHH....",
        "...HHHHHHHHHHHHHHHHHHH...",
        "...HHHHHHHlHHHHHHHHlHHH..",
        "..HHHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHH..HHHH....HHHHH.",
        "..HHHHH.............HHHH.",
        ".HHHH...............HHHHH",
        ".HHHl...............lHHH.",
        ".HHHH...............HHHH.",
        "HHHH.................HHH.",
        ".HHHH...............HHHH.",
        "HHHl.................HHHH",
        ".HHH.................HHH.",
        "..H...................H..",
    ], ["H": hair, "l": hairLight])

    if let s = p.signature, s > 0.06, s < 0.94 {
        // The pocket watch held up by its chain, swinging.
        c.rect(38, 30, 5, 3, coat); c.rect(43, 29, 2, 2, clawdOrange)
        let swing = sin(s * .pi * 7) * 0.6
        let len = 7.0, top = (x: 44.0, y: 31.0)
        let end = (x: top.x + sin(swing) * len, y: top.y + cos(swing) * len)
        for i in 1..<Int(len) {
            let f = Double(i) / len
            c.px(Int((top.x + (end.x - top.x) * f).rounded()), Int((top.y + (end.y - top.y) * f).rounded()), goldDark)
        }
        let wx = Int(end.x.rounded()) - 1, wy = Int(end.y.rounded())
        c.pattern(wx, wy, [".g.", "gWg", ".g."], ["g": gold, "W": C(0xF4EEDC)])
        c.px(wx + 1, wy + 1, ink.alpha(0.6))
        return
    }
    drawSonicArm(c, p, sleeve: coat, tip: tip)
}
