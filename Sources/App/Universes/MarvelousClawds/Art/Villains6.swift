import Foundation

// Villains: the street and the mutant foes.

let villains6: [MarvelVillain: Persona] = [
    .morbius: Persona(name: "Morbidus", weapon: .saber, motion: .fly,
                  headTop: 17, signature: 3.0,
                  draw: drawMorbius),
    .misterNegative: Persona(name: "Mister Negatory", weapon: .lightning, magic: Magic(core: C(0x1E1E26), glow: C(0xF0F0F4), jagged: false),
                  headTop: 20, signature: 3.0,
                  draw: drawMisterNegative),
    .chameleon: Persona(name: "Kameleon", weapon: .blaster, shot: .bullet,
                  muzzle: (47, 32), headTop: 22, signature: 3.2,
                  draw: drawChameleon),
    .tombstone: Persona(name: "Gravestone", weapon: .saber,
                  headTop: 22, signature: 2.6,
                  draw: drawTombstone),
    .misterSinister: Persona(name: "Mister Sinistre", weapon: .lightning, magic: Magic(core: C(0xFFE0E0), glow: C(0xFF2A3A), jagged: false),
                  headTop: 19, signature: 2.8,
                  draw: drawMisterSinister),
    .omegaRed: Persona(name: "Omega Read", weapon: .saber, armoured: true,
                  headTop: 20, signature: 3.0,
                  draw: drawOmegaRed),
    .toad: Persona(name: "Toadie", weapon: .saber, pivot: toadMouth,
                  headTop: 21, signature: 3.2,
                  draw: drawToad),
    .pyro: Persona(name: "Pyroh", weapon: .blaster, shot: .fire,
                  muzzle: (44, 33), handGun: false, headTop: 19, signature: 3.2,
                  draw: drawPyro),
    .blob: Persona(name: "The Blobb", weapon: .saber, canSit: false, pivot: blobFist,
                  bulk: 6, headTop: 14, signature: 2.6,
                  draw: drawBlob),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A thick limb from `s` at `angle` degrees, `len` long and `r` thick. Returns where it ends.
@discardableResult
private func limb(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ angle: Double, len: Double, r: Double,
                  _ col: Px) -> (x: Double, y: Double) {
    let a = angle * .pi / 180
    let e = (x: s.x + cos(a) * len, y: s.y + sin(a) * len)
    c.glowLine(s.x, s.y, e.x, e.y, core: col, glow: clear, coreR: r, glowR: r + 0.1)
    return e
}

/// The smear a fast swing leaves behind: faint arcs at the earlier angles, out to `len` from `s`.
private func smear(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ trail: [Double], len: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * len * 0.4, s.y + sin(r) * len * 0.4, s.x + cos(r) * len, s.y + sin(r) * len,
                   core: col, glow: col, coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
}

/// `n` claws fanning out from `e` along `angle`, each `len` long.
private func claws(_ c: PixelCanvas, _ e: (x: Double, y: Double), _ angle: Double, len: Double, n: Int = 3,
                   spread: Double = 0.4, _ col: Px) {
    let r = angle * .pi / 180
    for k in 0..<n {
        let a = r + (Double(k) - Double(n - 1) / 2) * spread
        c.glowLine(e.x + cos(a), e.y + sin(a), e.x + cos(a) * (len + 1), e.y + sin(a) * (len + 1), core: col, glow: clear,
                   coreR: 0.45, glowR: 0.5)
    }
}

/// A puff of smoke at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.7 * (1 - k)))
}

/// Legs swept back behind a flyer.
private func flyingLegs(_ c: PixelCanvas, _ leg: Px, boot: Px) {
    let sweep = [(0, 36), (0, 37), (-1, 38), (-2, 39), (-3, 40)]
    for lx in [19, 23, 31, 35] {
        for (i, s) in sweep.enumerated() { c.rect(lx + s.0, s.1, 2, 1, i >= 3 ? boot : leg) }
    }
}

/// Draw the `a` look left of column `split` and the `b` look from it on, so one look can sweep into another.
private func sweep(_ c: PixelCanvas, split: Int, _ a: (PixelCanvas) -> Void, _ b: (PixelCanvas) -> Void) {
    let la = PixelCanvas(c.w, c.h), lb = PixelCanvas(c.w, c.h)
    for l in [la, lb] { l.ox = c.ox; l.oy = c.oy; l.baseY = c.baseY }
    a(la); b(lb)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    for y in 0..<c.h {
        for x in 0..<c.w {
            let src = x - ox < split ? la : lb
            let i = (y * c.w + x) * 4, al = src.buf[i + 3]
            guard al > 0 else { continue }
            let m = 255 / Double(al)
            c.px(x, y, Px(r: UInt8(min(255, Double(src.buf[i]) * m)), g: UInt8(min(255, Double(src.buf[i + 1]) * m)),
                          b: UInt8(min(255, Double(src.buf[i + 2]) * m)), a: al))
        }
    }
    c.ox = ox; c.oy = oy; c.baseY = by
}

/// Boots (or shoes) `rows` tall ending on the feet's row `bottom`, following the walk; tucked under when sitting.
private func boots(_ c: PixelCanvas, _ p: Pose, rows: Int, bottom: Int = 43, wide: Bool = false, _ col: Px) {
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 39, 4, 1, col) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(wide ? lx - 1 : lx, (lifted ? bottom - 1 : bottom) - rows + 1, wide ? 4 : 2, rows, col)
    }
}

/// A fist on a short arm from the shoulder at `angle` (nil: hanging at the side), with a swing smear.
private func punch(_ c: PixelCanvas, _ p: Pose, arm: Px, fist: Px, knuckle: Px) {
    guard let a = p.melee else { return }
    let shoulder = (x: 37.5, y: 33.5)
    smear(c, shoulder, p.trail, len: 9, C(0xF2ECDC))
    let e = limb(c, shoulder, a, len: 5, r: 1.3, arm)
    c.rect(Int(e.x) - 1, Int(e.y) - 1, 3, 3, fist)
    c.rect(Int(e.x) - 1, Int(e.y) - 1, 3, 1, knuckle)
}

// MARK: - Morbius

/// Morbius, the Living Vampire (the comics look): a chalk-pale Clawd with red eyes and fangs, black hair slicked into
/// a widow's peak, a black suit with a deep V and his towering red-lined collar; he flies, leaning into it, and slashes
/// with clawed fingers. Signature: he bares his fangs and a flurry of bats bursts out from behind his collar.
private func drawMorbius(_ c: PixelCanvas, _ p: Pose) {
    morbius(c, p)
}

private func morbius(_ c: PixelCanvas, _ p: Pose) {
    let pale = C(0xC4CAD6), paleShade = C(0x98A0B0), black = C(0x1C1C26), blackLight = C(0x3A3A4A)
    let red = C(0xC41E2C), redDark = C(0x7E1018), eye = C(0xE0202E)
    let bare = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if p.flying { flyingLegs(c, black, boot: redDark) } else {
        drawLegs(c, Look(leg: black), step: p.step)
    }
    c.oy += p.breathe
    // the high collar, flaring up behind his head
    c.pattern(10, 19, [
        "KK................................KK",
        "KRKK............................KKRK",
        ".KRRKK........................KKRRK.",
        ".KRRRRK......................KRRRRK.",
        "..KRRRRK....................KRRRRK..",
        "..KRrRRRK..................KRRRrRK..",
        "...KRrRRK..................KRRrRK...",
        "...KRRRRRK................KRRRRRK...",
        "....KRRRRK................KRRRRK....",
        "....KKRRRK................KRRRKK....",
    ], ["K": blackLight, "R": red, "r": redDark])
    drawBody(c, Look(body: pale, shade: paleShade, arm: black, eye: eye))
    // the suit, with its deep V and red piping
    c.pattern(18, 33, [
        "KKKKKKKR......RKKKKK",
        "KKKKKKKKR....RKKKKKK",
        "KKKKKKKKKR..RKKKKKKK",
        "KKKKKKKKKKRRKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
    ], ["K": black, "R": red])
    c.rect(37, 33, 1, 5, C(0x101016))
    // hair slicked back to a widow's peak
    c.pattern(17, 21, [
        ".....HHHHHHHHHH.......",
        "...HHHHHHHHHHHHHHH....",
        "..HHHHHHHHhHHHHHHHH...",
        ".HHHHHHHhHHHHHHhHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHH......HHHH......HHH",
        "HH........HH........HH",
        "H....................H",
    ], ["H": black, "h": blackLight])
    c.rect(21, 28, 3, 1, paleShade); c.rect(32, 28, 3, 1, paleShade)      // hollow brows
    // mouth and fangs
    let gape = Int((bare * 2).rounded())
    c.rect(25, 32, 6, 1 + gape, C(0x3A0E14))
    c.px(25, 33 + gape, white); c.px(30, 33 + gape, white)
    if gape > 0 { c.px(25, 32 + gape, white); c.px(30, 32 + gape, white) }
    // the clawed hand
    let hand = (x: Sprite.hand.x - 1, y: Sprite.hand.y - 1)
    c.rect(Int(hand.x) - 1, Int(hand.y) - 1, 3, 3, pale)
    let a = p.melee ?? (p.flying ? 0 : 70)
    smear(c, hand, p.trail, len: 10, C(0xF0D8DC))
    claws(c, (hand.x + 0.5, hand.y + 0.5), a, len: p.melee == nil ? 3 : 6, spread: 0.45, C(0x5A5E6E))
    // Signature: bats burst out from behind the collar.
    if let s = p.signature, s > 0.2 {
        let bat = C(0x2A1A30)
        for i in 0..<5 {
            let f = (s - 0.2) / 0.8 * 1.3 - Double(i) * 0.08
            guard f > 0, f < 1 else { continue }
            let dir: Double = i % 2 == 0 ? 1 : -1
            let x = 28 + dir * (4 + f * (12 + Double(i) * 3)) + sin(f * 9 + Double(i)) * 2
            let y = 20 - f * (14 + Double(i % 3) * 3) + Double(i)
            let up = Int(s * 40 + Double(i)) % 2 == 0
            c.pattern(Int(x) - 2, Int(y) - 1, up ? ["K...K", "KK.KK", ".KKK."] : [".....", ".KKK.", "KK.KK"],
                      ["K": bat.alpha(f < 0.8 ? 1 : (1 - f) / 0.2)])
            c.px(Int(x), Int(y), red.alpha(f < 0.8 ? 1 : 0.4))
        }
    }
}

// MARK: - Mister Negative

/// Mister Negative (Martin Li, comics): a photographic negative of a man, near-black skin, white hair and white eyes,
/// a white suit over a black shirt and white tie; he casts a black-and-white stream of negative energy. Signature: the
/// negative flickers off and he is plain Martin Li for a moment (tan skin, black hair, black suit), then flickers back.
private func drawMisterNegative(_ c: PixelCanvas, _ p: Pose) {
    var normal = false
    var flicker = false
    if let s = p.signature {
        normal = s > 0.22 && s < 0.78
        if (s > 0.1 && s < 0.3) || (s > 0.7 && s < 0.9) {
            flicker = true
            normal = noise(Int(p.t * 16)) > 0.5
        }
    }
    misterNegative(c, p, normal: normal)
    if flicker {                                                          // black-and-white static round him
        for k in 0..<8 {
            let i = Int(p.t * 30) * 11 + k
            let x = 14 + Int(noise(i) * 28), y = 18 + Int(noise(i + 3) * 24)
            c.rect(x, y, 2, 1, k % 2 == 0 ? C(0xF0F0F4) : C(0x1E1E26))
        }
    }
}

private func misterNegative(_ c: PixelCanvas, _ p: Pose, normal: Bool) {
    let skin = normal ? C(0xE2B48A) : C(0x2C2C36), skinShade = normal ? C(0xBC8E66) : C(0x1C1C24)
    let hair = normal ? C(0x1A1A20) : C(0xEEEEF2), hairShade = normal ? C(0x34343E) : C(0xB8B8C4)
    let suit = normal ? C(0x24242E) : C(0xC4C4CE), suitShade = normal ? C(0x121218) : C(0x9696A4)
    let shirt = normal ? C(0xF0F0F4) : C(0x14141A), tie = normal ? C(0x1A1A20) : C(0xEEEEF2)
    let eye = normal ? ink : C(0xF6F6FA)
    drawLegs(c, Look(leg: suit), step: p.step)
    boots(c, p, rows: 2, tie)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: eye), armRight: p.armRaise)
    // the suit: lapels open over the shirt and tie
    c.pattern(18, 33, [
        "LSSSSSSSWWWWSSSSSSSS",
        "SLSSSSSSSWTWSSSSSSSs",
        "SSLSSSSSSWTWSSSSSSSs",
        "SSSSSSSSSSTSSSSSSSSs",
        "ssssssssssssssssssss",
    ], ["S": suit, "s": suitShade, "W": shirt, "T": tie, "L": suitShade])
    c.rect(38, 33 - p.armRaise, 3, 1, shirt)                              // shirt cuff
    c.rect(39, 34 - p.armRaise, 2, 2, skin)                               // the casting hand
    // swept-back hair
    c.pattern(17, 22, [
        "....H..H..H..H..H.....",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHhHHHHHhHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHH..HHHHHHH...HHHHH",
        "HH..................HH",
        "H....................H",
    ], ["H": hair, "h": hairShade])
    c.rect(21, 28, 3, 1, hairShade); c.rect(32, 28, 3, 1, hairShade)      // brows
    c.rect(26, 32, 4, 1, normal ? C(0x8A5A40) : C(0x6A6A78))              // a thin, calm mouth
}

// MARK: - Chameleon

/// The Chameleon (classic comics): a smooth, blank white mask for a face, an egg-dome with two small eyes and no
/// mouth, over a purple tunic with a high collar and gold buttons; he carries a pistol. Signature: a shimmer sweeps
/// over his face and he's suddenly wearing a Spider-Man mask, before it sweeps back to blank.
private func drawChameleon(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.08, s < 0.92 else { chameleon(c, p, disguised: false); return }
    let k: Double = s < 0.5 ? min(1, (s - 0.08) / 0.25) : max(0, 1 - (s - 0.67) / 0.25)
    let split = Int((16 + 24 * k).rounded())                              // columns left of `split` are disguised
    sweep(c, split: split, { chameleon($0, p, disguised: true) }, { chameleon($0, p, disguised: false) })
    if k > 0, k < 1 {
        c.oy += p.breathe
        for y in 20...36 where noise(y * 5 + Int(p.t * 24)) > 0.4 {
            c.px(split, y, C(0xE8D8FF).alpha(0.8))
            if noise(y + 9) > 0.6 { c.px(split + 1, y, C(0xB07AE0).alpha(0.6)) }
        }
        c.oy -= p.breathe
    }
}

private func chameleon(_ c: PixelCanvas, _ p: Pose, disguised: Bool) {
    let mask = C(0xDCDCE4), maskShade = C(0xA8A8B6), purple = C(0x6A2A8A), purpleDark = C(0x461A60), purpleLight = C(0x8A4AAA)
    let gold = C(0xE8C02A)
    drawLegs(c, Look(leg: purple), step: p.step)
    boots(c, p, rows: 2, purpleDark)
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: maskShade, arm: purple, eye: nil))
    // the blank dome of the mask
    c.pattern(19, 22, [
        "......MMMMMMMM......",
        "...MMMMMMMMMMMMMM...",
        ".MMMMMMMMMMMMMMMMMMs",
        "MMMMMMMMMMMMMMMMMMMs",
    ], ["M": mask, "s": maskShade])
    c.rect(37, 24, 1, 2, maskShade)
    // the tunic and its high collar
    c.rect(18, 33, 20, 5, purple)
    c.rect(37, 33, 1, 5, purpleDark)
    c.pattern(16, 30, [
        "PP....................PP",
        "PPP..................PPP",
        "PLPP................PPLP",
        ".PPPPPPPPPPPPPPPPPPPPPP.",
    ], ["P": purpleDark, "L": purpleLight])
    for y in [34, 36] { c.px(27, y, gold) }
    c.rect(18, 37, 20, 1, purpleDark)
    if disguised {
        // a Spider-Man mask: red, webbed, with the big white lenses
        let red = C(0xD02030), web = C(0x7A1018), lens = C(0xF4F4F8)
        c.pattern(18, 22, [
            ".......RRRRRR.......",
            "....RRRRRRRRRRRR....",
            "..RRRRRRRRRRRRRRRR..",
            ".RRRRRRRRRRRRRRRRRR.",
            "RRRRRRRRRRRRRRRRRRRR",
            "RRRRRRRRRRRRRRRRRRRR",
            "RRRRRRRRRRRRRRRRRRRR",
            "RRRRRRRRRRRRRRRRRRRR",
            "RRRRRRRRRRRRRRRRRRRR",
            "RRRRRRRRRRRRRRRRRRRR",
            "RRRRRRRRRRRRRRRRRRRR",
        ], ["R": red])
        for x in [22, 27, 32] { c.rect(x, 23, 1, 10, web) }
        for y in [25, 28, 31] { c.rect(18, y, 20, 1, web) }
        c.pattern(20, 27, [".KKKK.....KKKK.", "KLLLLK...KLLLLK", "KLLLLK...KLLLLK", ".KLLK.....KLLK."],
                  ["K": ink, "L": lens])
        c.rect(38, 33, 3, 3, red)
    } else {
        c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)              // small, dead eyes in the blank mask
        c.rect(21, 28, 3, 1, maskShade); c.rect(32, 28, 3, 1, maskShade)
        c.px(27, 31, maskShade)                                           // the hint of a nose
        c.rect(38, 33, 3, 3, purpleDark)                                  // gloved hand
    }
    drawPistol(c, x: 40, y: 31 + p.gunY, body: C(0x2A2A30), trim: C(0x8A8F9C))
}

// MARK: - Tombstone

/// Tombstone (Lonnie Lincoln): an albino Clawd (chalky pink-white skin, a flat white crew cut, pink eyes) in a
/// charcoal suit with a white shirt and red tie, grinning with teeth filed to points; he fights with his fists.
/// Signature: the grin spreads, wide and slow, showing every sharpened tooth.
private func drawTombstone(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xEADCD8), skinShade = C(0xC0ACA8), hair = C(0xC8C8D2), hairShade = C(0x9A9AA8)
    let suit = C(0x2E2E36), suitShade = C(0x1A1A20), shirt = C(0xEEEEF2), tie = C(0x16161B)
    let grin = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    boots(c, p, rows: 2, C(0x101014))
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: ink))
    c.pattern(18, 33, [
        "SSSSSSSSWTTWSSSSSSSs",
        "SSSSSSSSSWTWSSSSSSSs",
        "SSSSSSSSSSTSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "ssssssssssssssssssss",
    ], ["S": suit, "s": suitShade, "W": shirt, "T": tie])
    c.rect(21, 35, 3, 1, suitShade)                                      // pocket
    // a flat-topped crew cut
    c.pattern(18, 23, [
        "HHHHHHHHHHHHHHHHHHHH",
        "HhHHHhHHHHhHHHHhHHHH",
        "HHHHHHHHHHHHHHHHHHHh",
        "HH................Hh",
    ], ["H": hair, "h": hairShade])
    c.rect(18, 26, 20, 1, skinShade.alpha(0.5))
    c.px(23, 30, C(0xE04A6A)); c.px(33, 30, C(0xE04A6A))                 // pink irises
    c.rect(21, 28, 4, 1, hairShade); c.rect(31, 28, 4, 1, hairShade)
    // the grin: a dark mouth lined with pointed teeth
    let half = 3 + Int((grin * 4).rounded())
    let open = grin > 0.4 ? 2 : 1
    let mx = 28 - half
    c.rect(mx, 32, half * 2, open + 1, C(0x3A1418))
    for x in stride(from: mx, to: mx + half * 2, by: 2) {
        c.px(x, 32, white)
        if open > 1 { c.px(x + 1, 32 + open, white) }
    }
    c.px(mx - 1, 31, C(0x8A5A5A)); c.px(mx + half * 2, 31, C(0x8A5A5A)) // the corners curl up
    // fist
    if p.melee == nil { c.rect(38, 33, 3, 3, skin) }
    punch(c, p, arm: suit, fist: skin, knuckle: skinShade)
}

// MARK: - Mister Sinister

/// Mister Sinister (Nathaniel Essex, classic comics): chalk-white skin, red eyes, black hair to a widow's peak and the
/// red diamond on his forehead; black armour with red trim, spiked shoulder plates and a long dark cape with a red
/// edge; he casts red energy. Signature: the diamond on his brow flares, his eyes glowing with it.
private func drawMisterSinister(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD0D2DC), skinShade = C(0xA4A8B6), black = C(0x1C1C2A), blackLight = C(0x3A3A52)
    let red = C(0xD01E2C), redDark = C(0x8A1420), eye = C(0xE8202E)
    let glow = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawCape(c, t: p.t, speed: p.capeSpeed, color: C(0x4A1828), edge: C(0x2A0C16), extra: -1)
    drawLegs(c, Look(leg: black), step: p.step)
    boots(c, p, rows: 1, bottom: 41, red)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: black, eye: eye), armRight: p.armRaise)
    // armour: black with a red diamond and trim
    c.rect(18, 33, 20, 5, black)
    c.rect(37, 33, 1, 5, C(0x101018))
    c.rect(18, 33, 20, 1, red)
    c.pattern(26, 34, ["..R..", ".RrR.", "..R.."], ["R": red, "r": C(0xFF8A90)])
    c.rect(18, 37, 20, 1, redDark)
    // spiked shoulder plates
    c.pattern(13, 27, ["K......", "KK.....", "KKK....", "KKKKK..", "KKKKKK.", ".KKKKKK"], ["K": blackLight])
    c.pattern(36, 27, ["......K", ".....KK", "....KKK", "..KKKKK", ".KKKKKK", "KKKKKK."], ["K": blackLight])
    c.rect(38, 33 - p.armRaise, 3, 3, redDark)                            // red gauntlet
    // black hair, slicked back to a sharp widow's peak, long at the back
    c.pattern(16, 20, [
        "......HHHHHHHHHH.......",
        "...HHHHHHHHHHHHHHHH....",
        "..HHHHHHhHHHHHhHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHH",
        "HHHH.......HH.......HHH",
        "HHH.........H........HH",
        "HH...................H.",
        "HH.....................",
        "H......................",
    ], ["H": black, "h": blackLight])
    c.rect(21, 28, 3, 1, skinShade); c.rect(32, 28, 3, 1, skinShade)
    c.rect(25, 32, 6, 1, C(0x5A4A5A))                                     // a thin cruel smile
    c.px(31, 31, C(0x5A4A5A))
    // the diamond on his forehead (just under the widow's peak)
    c.pattern(27, 27, [".D.", "DdD", ".D."], ["D": red, "d": C(0xFF6A72)])
    if glow > 0.05, let s = p.signature {
        let pulse = 0.85 + 0.15 * sin(s * 40)
        c.glowLine(28.5, 28.5, 28.5, 28.5, core: C(0xFFE0E0).alpha(glow), glow: red.alpha(glow), coreR: 1,
                   glowR: 1.5 + 4 * glow, strength: pulse)
        for x in [22.5, 32.5] {
            c.glowLine(x, 30, x + 1, 30, core: C(0xFFD0D0).alpha(glow), glow: red.alpha(glow * 0.7), coreR: 0.6, glowR: 2)
        }
        if glow > 0.9 {                                                   // rays from the diamond
            for k in 0..<4 {
                let a = Double(k) * .pi / 2 + .pi / 4 + s * 3
                c.px(28 + Int((cos(a) * 6).rounded()), 28 + Int((sin(a) * 6).rounded()), red.alpha(0.8))
            }
        }
    }
}

// MARK: - Omega Red

/// Omega Red (comics): a red-armoured Clawd with the yellow hammer-and-sickle on his chest, long white hair and a
/// grey, grim face; steel carbonadium tentacles uncoil from his wrists and lash out as his melee weapon. Signature:
/// both tentacles rise and whip about over his head.
private func drawOmegaRed(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB81E28), redDark = C(0x7A1018), redLight = C(0xE04A50), face = C(0xCCB4AC), faceShade = C(0x9E8A86)
    let hair = C(0xE2E2E8), hairShade = C(0xA8A8B4), steel = C(0x9AA0AC), steelDark = C(0x5A5E6A), gold = C(0xF2C21E)
    let whip = p.signature.map { habitArc($0, hold: 0.65) } ?? 0
    // long white hair hanging down his back
    c.oy += p.breathe
    c.pattern(15, 25, ["HHHH", "HHHh", "HHHh", "HHh.", "HHh.", "Hh..", "H..."], ["H": hair, "h": hairShade])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: red), step: p.step)
    boots(c, p, rows: 1, bottom: 41, redDark)
    c.oy += p.breathe
    drawBody(c, Look(body: face, shade: faceShade, arm: red, eye: ink))
    c.rect(18, 32, 20, 6, red)
    c.rect(18, 32, 20, 1, redLight)
    c.rect(37, 32, 1, 6, redDark)
    c.rect(18, 37, 20, 1, redDark)
    c.pattern(25, 33, [".HH..", "H..S.", "H.S..", ".HSH.", "S..H."], ["H": gold, "S": gold])   // hammer and sickle
    c.rect(18, 26, 20, 1, redDark)                                        // the armour's high collar edge at the scalp
    // the white mane
    c.pattern(17, 21, [
        ".....HHHHHHHHHH.......",
        "...HHHHHHHHHHHHHHH....",
        "..HHHHHhHHHHHHhHHHH...",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHH..H......H..HHHHHH",
        "HHH..............HHHHH",
        "HHh...............HHh.",
        "HH................HH..",
        "HH.................H..",
    ], ["H": hair, "h": hairShade])
    c.rect(21, 28, 4, 1, faceShade); c.rect(31, 28, 4, 1, faceShade)
    c.rect(26, 31, 4, 1, C(0x5A4A50))                                     // grim mouth
    // the gauntlets
    c.rect(15, 33, 3, 3, redDark); c.rect(38, 33, 3, 3, redDark)
    // tentacles
    let tip = p.signature.map { $0 * 22 } ?? p.t * 3
    if whip > 0.02 {
        tentacle(c, from: (16.5, 34.5), angle: 180 + (-60 * whip), len: 8 + 8 * whip, phase: tip, amp: 70 * whip, steel, steelDark)
        tentacle(c, from: (39.5, 34.5), angle: -60 * whip, len: 8 + 8 * whip, phase: tip + 1.7, amp: -70 * whip, steel, steelDark)
        return
    }
    tentacle(c, from: (16.5, 35.5), angle: 105, len: 7, phase: p.lt * 2, amp: 25, steel, steelDark)
    if let a = p.melee {
        smear(c, Sprite.hand, p.trail, len: 16, C(0xD8DCE6))
        tentacle(c, from: (39.5, 34.5), angle: a, len: 16, phase: p.t * 9, amp: 25, steel, steelDark)
    } else {
        tentacle(c, from: (39.5, 35.5), angle: 75, len: 7, phase: p.lt * 2 + 2, amp: -25, steel, steelDark)
    }
}

/// A carbonadium tentacle from `s`, writhing (`amp` degrees of wave, moving with `phase`), segmented, with a spike.
private func tentacle(_ c: PixelCanvas, from s: (x: Double, y: Double), angle: Double, len: Double, phase: Double,
                      amp: Double, _ steel: Px, _ dark: Px) {
    var x = s.x, y = s.y
    let n = max(2, Int(len))
    var a: Double = angle
    for i in 0..<n {
        let k = Double(i) / Double(n)
        a = (angle + amp * k * sin(phase + k * 5)) * .pi / 180
        let nx = x + cos(a), ny = y + sin(a)
        let r: Double = 1.1 - 0.5 * k
        c.glowLine(x, y, nx, ny, core: i % 3 == 2 ? dark : steel, glow: clear, coreR: r, glowR: r + 0.1)
        x = nx; y = ny
    }
    c.glowLine(x, y, x + cos(a) * 2, y + sin(a) * 2, core: C(0xE0E4EC), glow: clear, coreR: 0.4, glowR: 0.5)
}

// MARK: - Toad

/// Where Toad's tongue lashes out from: his mouth.
private let toadMouth = (x: 37.5, y: 32.5)

/// Toad (Mortimer Toynbee, comics): a hunched green Clawd with a lumpy back, bulging yellow eyes, a scruffy brown mop
/// and a wide frog mouth, in a ragged brown tunic; his long pink tongue is his whip. Signature: a fly buzzes past,
/// his tongue snaps out, catches it, and he swallows it with a pleased gulp.
private func drawToad(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x7A9A3A), greenDark = C(0x56722A), greenLight = C(0x9ABA5A), tunic = C(0x8A6A3A), tunicDark = C(0x5E4626)
    let hair = C(0x5A3A1E), tongue = C(0xE0607A), tongueDark = C(0xA83A52)
    drawLegs(c, Look(leg: green), step: p.step)
    boots(c, p, rows: 1, wide: true, greenDark)                          // big flat feet
    c.oy += p.breathe
    // the hunched back
    c.pattern(14, 23, ["...GGG", ".GGGGG", "GGgGGG", "GGGGGG", "GGGGG.", "GGG..."], ["G": green, "g": greenDark])
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    c.px(20, 27, greenDark); c.px(35, 27, greenDark); c.px(19, 31, greenLight)   // warts
    // ragged tunic
    c.pattern(18, 33, [
        "TTTTTTTTTTTTTTTTTTTt",
        "TTTtTTTTTTTTTTtTTTTt",
        "TTTTTTTTTTTTTTTTTTTt",
        "TTTTTTTTTTTTTTTTTTTt",
        "T.TT.TTT.TTTT.TT.TT.",
    ], ["T": tunic, "t": tunicDark])
    c.rect(21, 35, 3, 2, C(0x6E7A3A))                                     // a patch
    // scruffy hair
    c.pattern(18, 23, ["...H..H.H..H.H......", ".HHHHHHHHHHHHHHHH...", "HHHHhHHHHHHhHHHHHH..", "HH.H.........H.HH..."],
              ["H": hair, "h": C(0x3A2412)])
    // the eyes bulge up out of his face
    let blink = p.signature.map { $0 > 0.82 && $0 < 0.95 } ?? false
    for x in [21, 31] {
        c.rect(x, 26, 4, 4, greenDark)
        if blink {
            c.rect(x, 28, 4, 1, ink)
        } else {
            c.rect(x, 26, 4, 3, C(0xF2D23A))
            c.rect(x + 2, 27, 1, 2, ink)
        }
    }
    // the wide frog mouth
    let gulp = p.signature.map { $0 > 0.78 && $0 < 0.95 } ?? false
    c.rect(22, 32, 15, 1, C(0x2A3418))
    c.px(21, 31, C(0x2A3418))
    if gulp { c.rect(20, 30, 3, 2, greenLight); c.rect(34, 30, 3, 2, greenLight) }   // cheeks puffed
    c.rect(38, 33, 3, 3, green)                                           // webbed hand
    // the tongue
    var out: (angle: Double, len: Double)? = p.melee.map { ($0, 14) }
    var fly: (x: Double, y: Double)? = nil
    if let s = p.signature {
        // the fly zigzags in, the tongue strikes at 0.4, reels it back by 0.7
        let target = (x: 52.0, y: 18.0)
        if s < 0.4 {
            fly = (target.x + 6 * cos(s * 30), target.y + 4 * sin(s * 47) - (0.4 - s) * 10)
        } else if s < 0.72 {
            let k = s < 0.48 ? (s - 0.4) / 0.08 : 1 - (s - 0.48) / 0.24
            let dx = target.x - toadMouth.x, dy = target.y - toadMouth.y
            let full = (dx * dx + dy * dy).squareRoot()
            out = (atan2(dy, dx) * 180 / .pi, full * k)
            if s >= 0.48 { fly = (toadMouth.x + dx * k, toadMouth.y + dy * k) } else if k < 1 { fly = target }
        }
    }
    if let o = out, o.len > 0.5 {
        smear(c, toadMouth, p.trail, len: o.len, tongue)
        let r = o.angle * .pi / 180
        let e = (x: toadMouth.x + cos(r) * o.len, y: toadMouth.y + sin(r) * o.len)
        c.glowLine(toadMouth.x, toadMouth.y, e.x, e.y, core: tongue, glow: clear, coreR: 0.7, glowR: 0.8)
        c.rect(Int(e.x) - 1, Int(e.y) - 1, 3, 3, tongue)
        c.px(Int(e.x), Int(e.y), tongueDark)
    }
    if let f = fly {
        let flap = Int((p.signature ?? 0) * 60) % 2 == 0
        c.px(Int(f.x), Int(f.y), ink)
        c.px(Int(f.x) - 1, Int(f.y) - (flap ? 1 : 0), C(0x9AB0C8))
        c.px(Int(f.x) + 1, Int(f.y) - (flap ? 1 : 0), C(0x9AB0C8))
    }
}

// MARK: - Pyro

/// Pyro (St. John Allerdyce, classic comics): an orange-and-yellow bodysuit and hood with a face opening, the twin
/// fuel tanks on his back feeding a hose to the flamethrower nozzle at his wrist, a pilot flame always lit. Signature:
/// he coaxes a stream of fire up from the nozzle and shapes it into a little dragon that flaps once round his head and
/// bursts into smoke.
private func drawPyro(_ c: PixelCanvas, _ p: Pose) {
    let orange = C(0xE8862A), orangeDark = C(0xB45E18), yellow = C(0xF2C21E), yellowDark = C(0xC8961A)
    let skin = C(0xE8B88A), tank = C(0x8A8E98), tankDark = C(0x5A5E68), hose = C(0x2E2E36)
    let fy = p.gunY
    // the fuel tanks on his back
    c.oy += p.breathe
    c.pattern(11, 25, [".RR..RR.", "TTTTTTTT", "TtTTtTTT", "TtTTtTTT", "TtTTtTTT", "TtTTtTTT", "TtTTtTTT", "TtTTtTTT",
                       "TtTTtTTT", "TTTTTTTT", ".DD..DD."], ["T": tank, "t": C(0xB8BCC6), "D": tankDark, "R": C(0xC8202A)])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: orange), step: p.step)
    boots(c, p, rows: 3, bottom: 42, yellow)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: C(0xC0906A), arm: orange, eye: ink))
    c.rect(18, 33, 20, 5, orange)
    c.rect(37, 33, 1, 5, orangeDark)
    c.rect(18, 35, 20, 1, yellow); c.rect(18, 36, 20, 1, yellowDark)      // belt
    c.rect(18, 33, 3, 2, hose)                                            // harness strap
    // the hood, with its face opening
    c.pattern(16, 20, [
        "......OOOOOOOOOOO......",
        "....OOOOOOOOOOOOOOO....",
        "...OOOOOYYYYYYYOOOOO...",
        "..OOOOOYYYYYYYYYOOOOO..",
        "..OOOOOOOOOOOOOOOOOOOO.",
        ".OOOOOOOOOOOOOOOOOOOOOO",
        ".OOOO.............OOOOo",
        ".OOO...............OOOo",
        ".OOO...............OOOo",
        ".OOO...............OOOo",
        ".OOOO.............OOOOo",
        "..OOOO...........OOOOo.",
        "..OOOOOOOOOOOOOOOOOOOo.",
    ], ["O": orange, "o": orangeDark, "Y": yellow])
    c.rect(22, 30, 2, 1, skin); c.rect(32, 30, 2, 1, skin)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(26, 30, 4, 1, C(0xA86A4A))                                     // a cocky smirk
    c.px(30, 29, C(0xA86A4A))
    // the hose from the tanks round to the wrist nozzle
    c.glowLine(18, 31, 16, 36, core: hose, glow: clear, coreR: 0.6, glowR: 0.7)
    c.glowLine(16, 36, 30, 38.5, core: hose, glow: clear, coreR: 0.6, glowR: 0.7)
    c.glowLine(30, 38.5, 39, Double(35 + fy), core: hose, glow: clear, coreR: 0.6, glowR: 0.7)
    // glove and nozzle
    c.rect(38, 33 + fy, 3, 3, orangeDark)
    c.rect(40, 32 + fy, 4, 2, tankDark); c.rect(40, 32 + fy, 4, 1, tank)
    // the pilot flame
    if p.fire == nil {
        let fl = noise(Int(p.t * 14)) > 0.5
        c.px(44, 32 + fy, fl ? yellow : orange); c.px(44, 31 + fy, C(0xFF6A1E).alpha(fl ? 0.8 : 0.4))
    }
    // Signature: a little fire dragon.
    if let s = p.signature {
        let flame = C(0xFF7A1E), hot = C(0xFFD23A), core = C(0xFFF6C8)
        if s < 0.25 {                                                     // the stream rising from the nozzle
            let k = s / 0.25
            c.glowLine(44, 32, 44 + 4 * k, 32 - 14 * k, core: core, glow: flame, coreR: 0.6, glowR: 2)
        }
        if s > 0.2 && s < 0.88 {
            let k = (s - 0.2) / 0.68
            let a = -.pi / 2 + k * 2 * .pi
            let x = 30 + cos(a) * 16, y = 15 + sin(a) * 4
            let up = Int(s * 24) % 2 == 0
            let left = cos(a + .pi / 2) < 0                               // the way it's flying
            let rows: [String] = up
                ? ["....WW........", "....WWW.......", ".....WWW...hh.", "......WW..hHHk", "fffFFFFFFFFHh.",
                   "..fFFFFFFFF...", "....F..F......"]
                : ["..............", "...........hh.", "..........hHHk", "fffFFFFFFFFHh.", "..fFFFWWFFF...",
                   "....F.WWWF....", ".......WW....."]
            let flipped = left ? rows.map { String($0.reversed()) } : rows
            c.pattern(Int(x) - 7, Int(y) - 3, flipped, ["F": flame, "f": flame.alpha(0.7), "W": hot, "h": hot, "H": core, "k": C(0xB8301A)])
        }
        if s >= 0.86 {
            let k = (s - 0.86) / 0.14
            for i in 0..<3 { puff(c, x: 44 + Double(i) * 3, y: 15 - k * 4 + Double(i), k: k, C(0x8A8A96)) }
        }
    }
}

// MARK: - Blob

/// Where the Blob's slapping fist swings from.
private let blobFist = (x: 44.5, y: 31.5)

/// The Blob (Fred Dukes, comics): an enormous round Clawd (all belly) with a little buzz-cut on top, beady eyes,
/// stubby arms and legs, blue trunks under a yellow belt with the red X buckle. He fights by bouncing his gut forward
/// with a stubby slap. Signature: he pats his belly and it jiggles in waves.
private func drawBlob(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xF0B890), shade = C(0xC88A68), light = C(0xFFD8BC), trunks = C(0x2A3A8A), trunksDark = C(0x1A2660)
    let belt = C(0xE8C02A), beltDark = C(0xB08A1A)
    var wobble: Double = 0
    if let s = p.signature, s > 0.25 { wobble = sin((s - 0.25) * 34) * 2.2 * (1 - (s - 0.25) / 0.75) }
    let lunge: Double = p.melee.map { max(0, cos($0 * .pi / 180)) * 3 } ?? 0
    // stubby legs
    for (i, lx) in [17, 23, 30, 36].enumerated() {
        let up = p.step >= 0 && i % 2 == p.step ? 1 : 0
        c.rect(lx, 38, 4, 6 - up, skin)
        c.rect(lx - 1, 42 - up, 5, 2, C(0x3A2A20))
    }
    c.oy += p.breathe
    let cx = 28 + Int(lunge.rounded()), cy = 28
    let rx = 16 + Int(wobble.rounded()), ry = 13 - Int((wobble * 0.5).rounded())
    // the far arm, behind
    c.rect(cx - rx - 2, 26, 4, 5, shade)
    // the vast round body
    c.ellipse(cx, cy, rx, ry, skin)
    c.ellipse(cx - 4, cy - 4, rx - 7, ry - 6, light.alpha(0.5))
    for y in (cy - ry)...(cy + ry) {                                      // a shaded rim on the right
        let k = 1 - Double((y - cy) * (y - cy)) / Double(ry * ry)
        guard k > 0 else { continue }
        let half = Int((Double(rx) * k.squareRoot()).rounded())
        c.px(cx + half, y, shade)
    }
    // trunks and the X belt
    for y in (cy + 6)...(cy + ry) {
        let k = 1 - Double((y - cy) * (y - cy)) / Double(ry * ry)
        guard k > 0 else { continue }
        let half = Int((Double(rx) * k.squareRoot()).rounded())
        c.rect(cx - half, y, half * 2 + 1, 1, y < cy + 8 ? belt : trunks)
        if y >= cy + 8 { c.px(cx + half, y, trunksDark) }
    }
    c.rect(cx - rx + 1, cy + 7, rx * 2 - 1, 1, beltDark)
    c.pattern(cx - 2, cy + 5, [".RRR.", "RKRKR", "RRKRR", "RKRKR", ".RRR."], ["R": C(0xC8202A), "K": ink])
    c.px(cx, cy + 2, shade)                                               // belly button
    // waves rolling across the belly
    if abs(wobble) > 0.4 {
        for dx in [-8, 0, 8] { c.rect(cx + dx + Int(wobble), cy - 1, 3, 1, shade.alpha(0.6)) }
    }
    // face, up top: beady eyes, a buzz cut, a big grin
    c.pattern(cx - 9, cy - ry - 1, ["....HHHHHHHHHH....", "..HHHHHHHHHHHHHH..", ".HhHHhHHHhHHHhHHH.", "..H............H.."],
              ["H": C(0x3A2A1E), "h": C(0x5A4430)])
    c.rect(cx - 5, cy - 8, 2, 2, ink); c.rect(cx + 4, cy - 8, 2, 2, ink)
    c.rect(cx - 6, cy - 9, 3, 1, shade); c.rect(cx + 4, cy - 9, 3, 1, shade)
    c.rect(cx - 3, cy - 4, 8, 1, C(0x8A4A3A)); c.px(cx - 4, cy - 5, C(0x8A4A3A)); c.px(cx + 5, cy - 5, C(0x8A4A3A))
    c.rect(cx - 5, cy - 6, 2, 1, C(0xF09A88).alpha(0.7)); c.rect(cx + 5, cy - 6, 2, 1, C(0xF09A88).alpha(0.7))   // rosy cheeks
    // the near arm: patting the belly in the signature, slapping when fighting
    if p.signature != nil && p.melee == nil {
        let pat = Int(((p.signature ?? 0) * 10).rounded()) % 2
        c.rect(cx + rx - 3, cy + 1 - pat, 4, 4, shade); c.rect(cx + rx - 3, cy + 1 - pat, 4, 1, skin)
        return
    }
    if let a = p.melee {
        let s = (x: blobFist.x + lunge, y: blobFist.y)
        smear(c, s, p.trail, len: 7, C(0xF8E4D0))
        let e = limb(c, s, a, len: 3, r: 1.6, skin)
        c.rect(Int(e.x) - 1, Int(e.y) - 2, 4, 4, skin)
        c.rect(Int(e.x) - 1, Int(e.y) - 2, 4, 1, light)
        c.rect(Int(e.x) - 1, Int(e.y) + 1, 4, 1, shade)
    } else {
        c.rect(cx + rx - 1, cy - 2, 4, 5, skin); c.rect(cx + rx + 2, cy - 2, 1, 5, shade)
    }
}
