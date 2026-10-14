import Foundation

// Villains: cosmic powers and more of Spider-Man's rogues.

let villains5: [MarvelVillain: Persona] = [
    .galactus: Persona(name: "Galacticus", weapon: .lightning, magic: Magic(core: C(0xF0E0FF), glow: C(0xA060FF), jagged: false), armoured: true, canSit: false,
                  pivot: galactusPalm, bulk: 6, headTop: 0, signature: 3.2, callout: "I'm peckish.",
                  draw: drawGalactus),
    .kang: Persona(name: "Kangg the Conqueror", weapon: .blaster, shot: .energy(core: C(0xF0E0FF), glow: C(0xA04AFF)), muzzle: (49, 31),
                  headTop: 14, signature: 2.8,
                  draw: drawKang),
    .mephisto: Persona(name: "Mefisto", weapon: .lightning, magic: Magic(core: C(0xFFE0D0), glow: C(0xFF3A1E), jagged: false),
                  headTop: 13, signature: 3.0,
                  draw: drawMephisto),
    .knull: Persona(name: "Knul", weapon: .saber, headTop: 20, signature: 3.0,
                  draw: drawKnull),
    .annihilus: Persona(name: "Annihilux", weapon: .lightning, magic: Magic(core: C(0xF0FFE0), glow: C(0x8AE04A), jagged: false), armoured: true,
                  pivot: annihilusRod, headTop: 13, signature: 2.6,
                  draw: drawAnnihilus),
    .highEvolutionary: Persona(name: "High Evolutionist", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xF0E8FF), glow: C(0xC88AFF), jagged: false),
                  headTop: 16, signature: 2.8,
                  draw: drawHighEvolutionary),
    .morganLeFay: Persona(name: "Morgana", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xE0FFE8), glow: C(0x3AD06A), jagged: false),
                  headTop: 18, signature: 3.2,
                  draw: drawMorganLeFay),
    .scorpion: Persona(name: "The Scorpyon", weapon: .saber, armoured: true, pivot: scorpionTail, headTop: 14, signature: 3.0,
                  draw: drawScorpion),
    .shocker: Persona(name: "Shockr", weapon: .blaster, shot: .beam(core: C(0xF0F8FF), glow: C(0x8AC8FF)), muzzle: (46, 33),
                  handGun: false, headTop: 21, signature: 2.6,
                  draw: drawShocker),
    .hobgoblin: Persona(name: "Hobgobbler", weapon: .blaster, motion: .fly, shot: .thrown(C(0xFF8A1E)), canSit: false,
                  muzzle: (42, 28), headTop: 15, signature: 3.0, callout: "Ha ha ha!",
                  draw: drawHobgoblin),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A solid round-ended stroke: limbs, tails, blades.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.05)
}

/// The smear a fast swing leaves behind: faint strokes at the earlier angles, from `inner` to `len` out of `s`.
private func smear(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ trail: [Double], len: Double, _ col: Px,
                   inner: Double = 0.4) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * len * inner, s.y + sin(r) * len * inner, s.x + cos(r) * len, s.y + sin(r) * len,
                   core: col, glow: col, coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
}

/// A bending limb from `from`, setting off at `angle` degrees and turning `bend` degrees along its `length`, tapering
/// from `r0` to `r1`, its segments alternating between `cols`. Returns where it ends and which way it points there.
@discardableResult
private func tentacle(_ c: PixelCanvas, from: (x: Double, y: Double), angle: Double, bend: Double, length: Double,
                      _ cols: [Px], r0: Double = 1.1, r1: Double = 1.1, n: Int = 10) -> (x: Double, y: Double, a: Double) {
    var x = from.x, y = from.y, a = angle
    for i in 0..<n {
        let r = a * .pi / 180
        let nx = x + cos(r) * length / Double(n), ny = y + sin(r) * length / Double(n)
        bar(c, x, y, nx, ny, cols[i % cols.count], r: r0 + (r1 - r0) * Double(i) / Double(max(1, n - 1)))
        x = nx; y = ny; a += bend / Double(n)
    }
    return (x, y, a)
}

/// A puff of smoke or mist at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2.5).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.6 * (1 - k)))
}

/// A tiny 3×3 letter, for a cackle.
private func glyph(_ c: PixelCanvas, _ ch: Character, _ x: Int, _ y: Int, _ col: Px) {
    let rows: [String]
    switch ch {
    case "H": rows = ["X.X", "XXX", "X.X"]
    case "A": rows = [".X.", "XXX", "X.X"]
    default: rows = ["XXX", "XXX", "XXX"]
    }
    c.pattern(x, y, rows, ["X": col])
}

/// A ring of pixels of radius `r` round (`x`, `y`): a shock wave.
private func ring(_ c: PixelCanvas, _ x: Double, _ y: Double, r: Double, _ col: Px) {
    let n = max(8, Int(r * 6))
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        c.px(Int((x + cos(a) * r).rounded(.down)), Int((y + sin(a) * r).rounded(.down)), col)
    }
}

/// Draw `art` into a scratch canvas with the same offsets as `c`, to stamp it back in copies.
private func layer(_ c: PixelCanvas, _ art: (PixelCanvas) -> Void) -> PixelCanvas {
    let l = PixelCanvas(c.w, c.h)
    l.ox = c.ox; l.oy = c.oy; l.baseY = c.baseY
    art(l)
    return l
}

/// Stamp layer `l` onto `c`, shifted by `dx`, `dy` (and each row by `slice(row)`), tinted `mix` of the way to `tint`,
/// at `alpha` opacity.
private func stamp(_ c: PixelCanvas, _ l: PixelCanvas, dx: Int = 0, dy: Int = 0, tint: Px? = nil, mix: Double = 0,
                   alpha: Double = 1, slice: (Int) -> Int = { _ in 0 }) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    for y in 0..<l.h {
        let sx = slice(y)
        for x in 0..<l.w {
            let i = (y * l.w + x) * 4, a = l.buf[i + 3]
            guard a > 0 else { continue }
            let m: Double = 255 / Double(a)
            var r: Double = Double(l.buf[i]) * m, g: Double = Double(l.buf[i + 1]) * m, b: Double = Double(l.buf[i + 2]) * m
            if let tint {
                r += (Double(tint.r) - r) * mix; g += (Double(tint.g) - g) * mix; b += (Double(tint.b) - b) * mix
            }
            c.px(x + dx + sx, y + dy, Px(r: UInt8(max(0, min(255, r))), g: UInt8(max(0, min(255, g))),
                                         b: UInt8(max(0, min(255, b))), a: UInt8(Double(a) * alpha)))
        }
    }
    c.ox = ox; c.oy = oy; c.baseY = by
}

// MARK: - Galactus

/// Galactus's forward palm, held out to cast.
private let galactusPalm = (x: 53.0, y: 22.0)

/// Galactus: the giant of the cast, filling the canvas top to bottom, blue bodysuit under purple armour, the V-shaped
/// chest plate with the big G, purple boots and gloves, and the great purple helmet with the blue crest, the ear discs
/// and a forked horn on each side, his stern pale face in its opening. Casts cosmic power from his outstretched palm.
/// Signature: his eyes blaze and cosmic energy spirals in to a growing orb over his palm.
private func drawGalactus(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x3050C0), blueDark = C(0x1E3484), blueLight = C(0x5A7AE8)
    let purple = C(0x7A2EA8), purpleDark = C(0x52207A), purpleLight = C(0xA860D8)
    let skin = C(0xE8D0B8), skinShade = C(0xB89C84)
    let power = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 30, 7, 12, blue); c.rect(lx, 30, 1, 12, blueLight)
        c.rect(lx - 1, 35 - up, 9, 9, purple)                             // tall boots
        c.rect(lx - 1, 35 - up, 9, 1, purpleLight); c.rect(lx + 7, 35 - up, 1, 9, purpleDark)
        c.rect(lx - 1, 43 - up, 9, 1, purpleDark)
    }
    c.oy += p.breathe
    // the far arm
    c.rect(11, 16, 5, 11, blueDark); c.rect(10, 26, 7, 6, purpleDark)
    // the torso
    c.rect(15, 12, 26, 19, blue)
    c.rect(15, 12, 2, 19, blueLight); c.rect(39, 12, 2, 19, blueDark)
    c.pattern(18, 13, [
        "PPPPPPPPPPPPPPPPPPPP",
        "PPPPPPPPPPPPPPPPPPPP",
        ".PPPBBBBBBBBBBBBPPP.",
        "..PPBBBBBBBBBBBBPP..",
        "..PPPBBBBBBBBBBPPP..",
        "...PPBBBBBBBBBBPP...",
        "....PPBBBBBBBBPP....",
        ".....PPPBBBBPPP.....",
        "........PPPP........",
    ], ["P": purple, "B": blueDark])
    c.pattern(25, 15, ["PPPPP", "P....", "P..PP", "P...P", "PPPPP"], ["P": purpleLight])   // the G
    c.rect(15, 26, 26, 5, purple); c.rect(15, 26, 26, 1, purpleLight); c.rect(15, 30, 26, 1, purpleDark)   // belt
    c.rect(26, 27, 4, 3, blueLight)
    // shoulder pads
    c.pattern(10, 9, [".PPPPPPP.", "PPLLPPPPP", "PPPPPPPPP", "PPPPPPPPP", ".DDDDDDD."],
              ["P": purple, "L": purpleLight, "D": purpleDark])
    // the forked horns on the sides of the helmet
    for (x0, dir) in [(18.5, -1.0), (37.5, 1.0)] {
        bar(c, x0, 7, x0 + dir * 5, 4, purple, r: 1.3)
        bar(c, x0 + dir * 5, 4, x0 + dir * 7, 0.5, purple, r: 0.9)
        bar(c, x0 + dir * 5, 4, x0 + dir * 3, 0.5, purple, r: 0.9)
        c.px(Int(x0 + dir * 7), 0, purpleLight); c.px(Int(x0 + dir * 3), 0, purpleLight)
    }
    // the helmet and his face
    c.pattern(17, 0, [
        ".....PPPPPPPPPPPP.....",
        "...PPPPPPPPBBPPPPPP...",
        "..PPPPPPPPPBBPPPPPPP..",
        ".PPPPPPPPPPBBPPPPPPPP.",
        ".PPPPPPPPPPBBPPPPPPPP.",
        ".PPPPPPDDDDDDDDDDDDPP.",
        ".PPPPPDFFFFFFFFFFFFPP.",
        ".PPPPPDFFFFFFFFFFFFPP.",
        ".PPPPPDFFFFFFFFFFFFPP.",
        ".PPPPPDFFFFFFFFFFFFPP.",
        ".PPPPPPFFFFFFFFFFFPPP.",
        "..PPPPPPFFFFFFFFFPPP..",
        "...BBBBBBBBBBBBBBBB...",
    ], ["P": purple, "B": blue, "D": purpleDark, "F": skin])
    c.rect(21, 1, 2, 3, purpleLight)                                       // shine on the dome
    c.circle(20, 8, 2, blue); c.px(20, 8, blueLight)                       // the ear disc
    if power > 0.1 {
        let hot = C(0xF0E0FF), glow = C(0xA060FF)
        c.glowLine(27, 7.5, 29, 7.5, core: hot.alpha(power), glow: glow.alpha(power), coreR: 0.8, glowR: 2.4)
        c.glowLine(32, 7.5, 34, 7.5, core: hot.alpha(power), glow: glow.alpha(power), coreR: 0.8, glowR: 2.4)
    } else {
        c.rect(27, 7, 2, 2, ink); c.rect(32, 7, 2, 2, ink)
    }
    c.rect(26, 6, 3, 1, skinShade); c.rect(31, 6, 3, 1, skinShade)         // stern brows
    c.rect(28, 10, 5, 1, skinShade)                                         // the mouth
    // the near arm: out to cast, or hanging
    c.pattern(35, 9, [".PPPPPPP.", "PPLLPPPPP", "PPPPPPPPP", "PPPPPPPPD", ".DDDDDDD."],
              ["P": purple, "L": purpleLight, "D": purpleDark])
    if p.zap != nil || power > 0.05 {
        let py = galactusPalm.y - Double(p.armRaise)
        bar(c, 40, 15, 46, py + 1, blue, r: 2.2)
        bar(c, 46, py + 1, galactusPalm.x - 2, py, purple, r: 2.5)
        c.rect(Int(galactusPalm.x) - 1, Int(py) - 2, 2, 5, purpleLight)
    } else {
        c.rect(38, 14, 5, 13, blue); c.rect(42, 14, 1, 13, blueDark)
        c.rect(37, 26, 7, 6, purple); c.rect(37, 26, 7, 1, purpleLight); c.rect(43, 26, 1, 6, purpleDark)
    }
    // Signature: cosmic power spirals in to an orb over his palm.
    if let s = p.signature, power > 0.05 {
        let o = (x: galactusPalm.x + 4, y: galactusPalm.y - 6)
        for i in 0..<12 {
            let f = frac(s * 2.5 + Double(i) / 12)
            let r: Double = 12 * (1 - f), a: Double = Double(i) * 2.4 + f * 4
            let col = i % 2 == 0 ? C(0xF0E0FF) : C(0xB070FF)
            c.px(Int(o.x + cos(a) * r), Int(o.y + sin(a) * r * 0.8), col.alpha(power * (0.4 + 0.6 * f)))
        }
        c.glowLine(o.x, o.y, o.x, o.y, core: C(0xF8F0FF).alpha(power), glow: C(0xA060FF).alpha(power),
                   coreR: 0.4 + 1.4 * power, glowR: 2 + 2.5 * power, strength: 0.85 + 0.15 * sin(s * 40))
    }
}

// MARK: - Kang

/// Kang the Conqueror: a green-suited Clawd with the blue mask face, framed by the purple helmet with its green ear
/// discs, and a towering purple collar fanned out behind his head; purple gloves, boots and belt, a ray gun in hand.
/// Signature: he glitches through time, cyan and violet afterimages split off him and rows of him slip sideways.
private func drawKang(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.06, s < 0.94 else { kang(c, p); return }
    let k = habitArc((s - 0.06) / 0.88, hold: 0.6)
    let l = layer(c) { kang($0, p) }
    let j = Int(s * 26)
    let spread = Int((k * 5).rounded())
    stamp(c, l, dx: -spread - (noise(j) > 0.6 ? 1 : 0), tint: C(0x3AE0FF), mix: 0.75, alpha: 0.45)
    stamp(c, l, dx: spread + (noise(j + 9) > 0.6 ? 1 : 0), tint: C(0xC83AFF), mix: 0.75, alpha: 0.45)
    let band = 18 + Int(noise(j + 3) * 22), shift = noise(j + 5) > 0.5 ? 2 : -2
    stamp(c, l, slice: { y in k > 0.3 && y >= band && y < band + 3 ? shift : 0 })
}

private func kang(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A9A3A), greenDark = C(0x266E2A), greenLight = C(0x6AC85A)
    let purple = C(0x6A2A8A), purpleDark = C(0x4A1A66), purpleLight = C(0x9450B8)
    let mask = C(0x4A86E0), maskDark = C(0x2A5AA8)
    // the high collar, fanned out behind his head
    c.oy += p.breathe
    c.pattern(11, 17, [
        "PPP..........................PPP",
        "PPPPP......................PPPPP",
        ".PpppPP..................PPpppP.",
        "..PppppPP..............PPppppP..",
        "...PpppppP............PpppppP...",
        "....PpppppP..........PpppppP....",
        ".....PppppP..........PppppP.....",
        "......PPPPPPPPPPPPPPPPPPPPP.....",
    ], ["P": purple, "p": purpleDark])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 40, 2, 4, purple) } }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: purple, eye: nil))
    c.rect(18, 34, 20, 1, greenLight)
    c.rect(18, 35, 20, 2, purple); c.rect(26, 35, 4, 2, C(0xE8C02A))      // belt and buckle
    // the helmet round the blue mask
    c.pattern(18, 20, [
        ".....PPPPPPPPPP.....",
        "...PPPPPPPPPPPPPP...",
        "..PPLLPPPPPPPPPPPP..",
        ".PPLPPPPPPPPPPPPPPP.",
        "PPPPPPPPPPPPPPPPPPPP",
        "PPPPPPPPPPPPPPPPPPPP",
        "PPPPPPPPPPPPPPPPPPPP",
        "PP................PP",
        "PP................PP",
        "PP................PP",
        "PP................PP",
        "PP................PP",
        "PP................PP",
        "PPP..............PPP",
    ], ["P": purple, "L": purpleLight])
    c.rect(20, 27, 16, 6, mask)
    c.rect(20, 27, 16, 1, maskDark)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, purpleDark); c.rect(32, 28, 3, 1, purpleDark)     // a hard brow
    c.rect(26, 32, 4, 1, maskDark)
    for x in [16, 37] { c.rect(x, 26, 3, 5, green); c.rect(x + 1, 27, 1, 3, greenLight) }   // the ear discs
    // the ray gun
    c.oy += p.gunY
    c.pattern(39, 30, ["..GG.....", "SSSSSSSSW", "SDSSSS...", "SS.......", "SS......."],
              ["G": C(0x5AFF7A), "S": C(0x9AA0B0), "D": C(0x5A5E68), "W": C(0xD8DCE8)])
    c.rect(38, 32, 3, 3, purple)
}

// MARK: - Mephisto

/// Mephisto: a red-skinned devil Clawd in a horned black cowl, yellow eyes under a wicked brow and a toothy grin; the
/// huge flared red collar rises behind his head, a dark red cape behind him, black trunks and boots. Casts hellfire.
/// Signature: his grin splits wide, his eyes blaze and hellfire licks up around his feet.
private func drawMephisto(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A1218), redLight = C(0xE8505A), black = C(0x1E1A22), blackLight = C(0x3E3448)
    let grin = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: redDark, edge: black)
    drawLegs(c, Look(leg: red), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 40, 2, 4, black) } }
    c.oy += p.breathe
    // the great collar, two flared wings rising behind his head
    for y in 13...30 {
        let k = Double(y - 13) / 17
        let xo = Int((11 + k * 6).rounded()), w = 2 + Int((k * 3).rounded())
        c.rect(xo, y, w, 1, red); c.px(xo + w - 1, y, black)
        c.rect(56 - xo - w, y, w, 1, red); c.px(56 - xo - w, y, black)
    }
    drawBody(c, Look(body: red, shade: redDark, arm: red, eye: nil), armRight: p.armRaise)
    c.rect(19, 27, 1, 5, redLight)
    c.rect(18, 34, 20, 4, black); c.rect(18, 34, 20, 1, blackLight)       // black trunks
    c.rect(26, 34, 4, 2, C(0xE8B530))
    // the horned cowl
    c.pattern(17, 17, [
        "..H..................H",
        "..HH................HH",
        "...HH..............HH.",
        "...HHKKKKKKKKKKKKKKHH.",
        "..KKKKKKKKKKKKKKKKKKK.",
        ".KKKKLKKKKKKKKKKKKKKKK",
        ".KKKLKKKKKKKKKKKKKKKKK",
        ".KKKKKKKKKKKKKKKKKKKKK",
        ".KKKKKKKKKKKKKKKKKKKKK",
        ".KKKKKKKKKKKKKKKKKKKKK",
        ".KKKK......KK......KKK",
        ".KKK................KK",
        ".KK.................KK",
        ".KK.................KK",
        ".KK.................KK",
        ".KK.................KK",
        "..K.................K.",
    ], ["K": black, "H": black, "L": blackLight])
    // yellow eyes under a wicked brow
    let eye = grin > 0.4 ? C(0xFFF6C0) : C(0xFFD23A)
    c.rect(22, 29, 2, 2, eye); c.rect(32, 29, 2, 2, eye)
    c.pattern(21, 28, ["K.........K", ".KK.....KK."], ["K": black])
    if grin > 0.4 {
        c.glowLine(22.5, 29.5, 23.5, 29.5, core: eye, glow: C(0xFF3A1E).alpha(grin), coreR: 0.5, glowR: 2)
        c.glowLine(32.5, 29.5, 33.5, 29.5, core: eye, glow: C(0xFF3A1E).alpha(grin), coreR: 0.5, glowR: 2)
    }
    // the grin, wider and open as it splits
    let gape = Int((grin * 2).rounded())
    let half = 5 + Int((grin * 2).rounded())
    c.rect(28 - half, 32, half * 2, 1 + gape, C(0x3A0610))
    for x in stride(from: 28 - half, to: 28 + half, by: 2) { c.px(x, 32, white) }
    if gape > 0 { for x in stride(from: 29 - half, to: 28 + half, by: 2) { c.px(x, 32 + gape, white) } }
    c.px(27 - half, 31, C(0x3A0610)); c.px(28 + half, 31, C(0x3A0610))
    // Signature: hellfire licks up round his feet.
    if grin > 0.05 {
        c.oy -= p.breathe
        for i in 0..<9 {
            let cx = 14 + i * 4
            let h = (3 + 3 * abs(sin(p.t * 6 + Double(i) * 1.9))) * grin
            for y in 0..<Int(h.rounded()) {
                let f = Double(y) / max(1, h), w = Int((1.5 * (1 - f)).rounded())
                let col = f < 0.35 ? C(0xFFE27A) : (f < 0.7 ? C(0xFF8A1E) : C(0xE0301E))
                c.rect(cx - w, 43 - y, 2 * w + 1, 1, col.alpha(0.9))
            }
        }
    }
}

// MARK: - Knull

/// Knull: the pale god of the symbiotes, ash-grey Clawd with long black hair down his back, dark eyes and a sneer,
/// black symbiote armour with white tendril markings, and the All-Black necrosword: a jagged black blade with a pale
/// edge (slung on his back when put away). Signature: symbiote tendrils burst from his back and writhe.
private func drawKnull(_ c: PixelCanvas, _ p: Pose) {
    let pale = C(0xC4C4CE), paleShade = C(0x9494A2), black = C(0x16161C), blackLight = C(0x34343E)
    let mark = C(0xD8D8E2), hair = C(0x0C0C10)   // `mark`: the tendrils' pale tips
    let writhe = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    c.oy += p.breathe
    // the sword slung across his back, hilt over the shoulder
    if p.melee == nil { knullSword(c, at: (15, 22), angle: 115, length: 15) }
    // Signature: tendrils burst from his back.
    if writhe > 0.02 {
        let s = p.signature ?? 0
        for k in 0..<5 {
            let base = [-160.0, -130, -105, 170, -185][k]
            let wob = 40 * sin(s * 14 + Double(k) * 1.7)
            let end = tentacle(c, from: (21, 30), angle: base + wob * 0.4, bend: wob, length: 5 + 13 * writhe,
                               [black, blackLight], r0: 1.4, r1: 0.6)
            c.px(Int(end.x), Int(end.y), mark)
        }
    }
    // the long hair down his back
    c.pattern(13, 26, ["HHHHH", "HHHHH", "HHHH.", "HHHHH", ".HHHH", "HHHH.", "HHHH.", "HHH..", ".HHH.", "HH.H.",
                       "H..H.", "...H."], ["H": hair])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: pale, shade: paleShade, arm: black, eye: nil))
    // the symbiote armour, its edge ragged
    c.rect(18, 33, 20, 5, black)
    for x in stride(from: 18, to: 38, by: 3) { c.px(x, 32, black); c.px(x + 1, 32, black) }
    c.pattern(21, 34, ["W.....WW.....W", ".WW..W..W..WW.", "...WW....WW..."], ["W": C(0x7A7A8C)])
    c.rect(18, 33, 1, 5, blackLight)
    // hair on top, falling past his face
    c.pattern(16, 21, [
        ".......HHHHHHHHH.....",
        ".....HHHHHHHHHHHHHH..",
        "...HHHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHH",
        ".HHHHHHHHH.HHHHHHHHHH",
        "HHHHHH.....H......HHH",
        "HHHH...............HH",
        "HHH.................H",
        "HHH..................",
        "HH...................",
    ], ["H": hair])
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, black); c.rect(32, 28, 3, 1, black)               // hard black brows
    c.px(23, 32, paleShade); c.px(33, 32, paleShade)                       // hollow cheeks
    c.rect(26, 32, 5, 1, C(0x4A3A4A)); c.px(31, 31, C(0x4A3A4A))           // a sneer
    // the necrosword in hand
    if let a = p.melee {
        smear(c, Sprite.hand, p.trail, len: 18, C(0xD8D8E2))
        knullSword(c, at: Sprite.hand, angle: a, length: 15)
        c.rect(40, 33, 3, 3, black)
    }
}

/// The All-Black necrosword with its grip at `at`, pointing `angle` degrees, its blade `length` long.
private func knullSword(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, length: Double) {
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    bar(c, h.x - ux * 2, h.y - uy * 2, h.x + ux * 1.5, h.y + uy * 1.5, C(0x3A3440), r: 0.7)            // the grip
    bar(c, h.x + ux * 2 - nx * 2.5, h.y + uy * 2 - ny * 2.5, h.x + ux * 2 + nx * 2.5, h.y + uy * 2 + ny * 2.5,
        C(0x16161C), r: 0.8)                                                                           // the guard
    let tip = (x: h.x + ux * (3 + length), y: h.y + uy * (3 + length))
    bar(c, h.x + ux * 3 + nx * 0.4, h.y + uy * 3 + ny * 0.4, tip.x, tip.y, C(0x24242E), r: 1.2)          // the black blade
    bar(c, h.x + ux * 3 + nx * 1.4, h.y + uy * 3 + ny * 1.4, tip.x - ux * 1.5 + nx * 0.6, tip.y - uy * 1.5 + ny * 0.6,
        C(0xD0D0DC), r: 0.35)                                                                          // its pale edge
    for k in [5.0, 10.0] {                                                                             // jagged notches
        c.px(Int((h.x + ux * k - nx * 1.8).rounded(.down)), Int((h.y + uy * k - ny * 1.8).rounded(.down)), C(0x24242E))
    }
}

// MARK: - Annihilus

/// The tip of Annihilus's Cosmic Control Rod, where his power leaves it.
private let annihilusRod = (x: 44.5, y: 30.5)

/// Annihilus: an insectoid green Clawd with a bony backswept crest, antennae, glaring yellow eyes and a mandibled
/// mouth; purple armour below a gold collar, translucent purple wings on his back, and the gold Cosmic Control Rod in
/// his fist. Signature: his wings buzz into a blur and he lifts off the ground.
private func drawAnnihilus(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4A8A3A), greenDark = C(0x2E6226), greenLight = C(0x7AB85A)
    let purple = C(0x6A2A8A), purpleDark = C(0x4A1A66), gold = C(0xE8C02A), goldDark = C(0xA8801A)
    let buzz = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let s = p.signature ?? 0
    let lift = -Int((buzz * 3).rounded())
    c.oy += lift
    // the wings
    c.oy += p.breathe
    let flaps: [Double] = buzz > 0.1 ? [-1, 1] : [0]
    for f in flaps {
        let a: Double = f * 9 * buzz * (frac(s * 18) < 0.5 ? 1 : -1) + 3 * sin(p.lt * 1.5)
        let alpha: Double = buzz > 0.1 ? 0.45 : 0.7
        for (tip, w) in [((5.0, 12.0), 3.0), ((3.0, 24.0), 2.6)] {
            let r = a * .pi / 180
            let dx = tip.0 - 21, dy = tip.1 - 28
            let tx = 21 + dx * cos(r) - dy * sin(r), ty = 28 + dx * sin(r) + dy * cos(r)
            c.glowLine(21, 28, tx, ty, core: C(0xB070E0, alpha), glow: C(0x7A3AB0, alpha), coreR: w, glowR: w + 1)
            bar(c, 21, 28, tx, ty, C(0x4A1A66, alpha + 0.2), r: 0.4)
        }
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: greenDark), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 42, 2, 2, purpleDark) } }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil), armRight: p.armRaise)
    for (x, y) in [(20, 28), (34, 27), (19, 31)] { c.rect(x, y, 2, 1, greenLight) }
    c.rect(18, 34, 20, 4, purple); c.rect(18, 37, 20, 1, purpleDark)       // purple armour
    for x in stride(from: 20, to: 37, by: 4) { c.rect(x, 35, 2, 2, purpleDark) }
    c.rect(18, 33, 20, 1, gold); c.rect(18, 33, 20, 1, gold)               // the gold collar
    c.rect(26, 33, 4, 2, goldDark)
    // the bony crest, swept back, and antennae
    c.pattern(16, 18, [
        "..........GGGG.......",
        "....GGGGGGGGGGGG.....",
        ".GGGGGGGLGGGGGGGGG...",
        "GGGGGGLGGGGGGGGGGGGG.",
        "DGGGGGGGGGGGGGGGGGGGG",
        "DDGGGGGGGGGGGGGGGGGGG",
        ".DDDGGGGGGGGGGGGGGGGG",
        "..DDDDDDDDDDDDDDDDDD.",
    ], ["G": green, "D": greenDark, "L": greenLight])
    c.pattern(9, 19, ["DD......", ".DDD....", "..DDDD..", "...DDDDD"], ["D": greenDark])   // spikes off the back
    bar(c, 31, 19, 37, 12, greenDark, r: 0.45); bar(c, 34, 19, 41, 14, greenDark, r: 0.45)
    c.px(37, 11, gold); c.px(41, 13, gold)
    // eyes and mandibles
    let eye = C(0xFFE23A)
    c.pattern(21, 28, ["YYY.......YYY", ".YYY.....YYY."], ["Y": eye])
    c.px(23, 29, ink); c.px(32, 29, ink)
    c.pattern(24, 31, ["K......K", ".KKKKKK.", "W.W..W.W"], ["K": C(0x1E2A14), "W": greenLight])
    // the Cosmic Control Rod in his fist
    let ry = Double(-p.armRaise)
    bar(c, 39.5, 35.5 + ry, annihilusRod.x - 0.5, annihilusRod.y + 0.5 + ry, gold, r: 0.7)
    c.rect(38, 33 - p.armRaise, 3, 3, green)
    c.glowLine(annihilusRod.x, annihilusRod.y + ry, annihilusRod.x, annihilusRod.y + ry,
               core: C(0xF0FFE0), glow: C(0x8AE04A), coreR: 0.6, glowR: 1.8)
    if buzz > 0.1 { c.rect(17 - Int(noise(Int(s * 40)) * 3), 41 - lift, 1, 1, C(0xB070E0, 0.5)) }
}

// MARK: - The High Evolutionary

/// The High Evolutionary (the movie look): a purple-armoured Clawd under a smooth purple helmet with a sculpted
/// lavender face plate (slit eyes, no mouth) a tall white collar, and a long purple coat flaring to the hem. Hovers;
/// casts from a white-gloved hand. Signature: the face plate glitches, flickering to show the raw, scarred face beneath.
private func drawHighEvolutionary(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x8A2A9A), purpleDark = C(0x5E1A6E), purpleLight = C(0xB04AC8)
    let face = C(0xD8B8E0), faceShade = C(0xA888B8), collar = C(0xE0E0E8), collarShade = C(0xA8A8B8)
    drawLegs(c, Look(leg: purpleDark), step: p.step)
    c.oy += p.breathe
    // the high white collar behind the helmet
    c.pattern(15, 20, ["W........................W", "WW......................WW", "WdW....................WdW",
                       "WddW..................WddW", ".WddW................WddW.", ".WddW................WddW.",
                       "..WdW................WdW..", "..WWW................WWW.."], ["W": purpleLight, "d": purpleDark])
    drawBody(c, Look(body: purple, shade: purpleDark, arm: collar, eye: nil), armRight: p.armRaise)
    // the coat, flaring out over his legs
    for y in 34...40 where y + c.oy <= 43 {
        let k = (y - 34) / 2
        c.rect(18 - k, y, 20 + k * 2, 1, purple)
        c.px(18 - k, y, purpleLight); c.px(37 + k, y, purpleDark)
    }
    c.rect(27, 34, 2, 7, purpleDark)                                       // the coat's opening
    c.rect(18, 34, 20, 1, collarShade)
    c.rect(26, 33, 4, 2, collar)                                           // the chest clasp
    // the smooth helmet
    c.pattern(17, 18, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHLLHHHHHHHHHHHH...",
        "..HHLHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        ".HH................HH.",
        "..H................H..",
    ], ["H": purple, "L": purpleLight])
    let glitch = p.signature.map { s in s > 0.12 && s < 0.88 && noise(Int(s * 34)) > 0.45 } ?? false
    if glitch {
        // the raw face under the mask
        let flesh = C(0xC8504A), raw = C(0x8A2A2A)
        c.rect(20, 26, 16, 7, flesh)
        c.rect(21, 27, 3, 1, raw); c.rect(30, 26, 2, 3, raw); c.px(34, 31, raw)
        c.rect(22, 28, 3, 3, white); c.px(23, 29, C(0xC81E1E))
        c.rect(31, 28, 3, 3, white); c.px(32, 29, C(0xC81E1E))
        c.rect(24, 32, 8, 1, C(0x3A0E10)); for x in stride(from: 24, to: 32, by: 2) { c.px(x, 32, C(0xF0E8D0)) }
        let row = 26 + Int(noise(Int((p.signature ?? 0) * 34) + 7) * 7)
        c.rect(19, row, 18, 1, C(0xE8C8F0, 0.7))                           // a scanline tear
    } else {
        c.rect(20, 26, 16, 7, face)
        c.rect(20, 26, 16, 1, faceShade)
        c.rect(22, 29, 3, 1, purpleDark); c.rect(31, 29, 3, 1, purpleDark)   // slit eyes
        c.rect(21, 28, 4, 1, faceShade); c.rect(31, 28, 4, 1, faceShade)     // sculpted brows
        c.rect(27, 28, 2, 3, faceShade)                                     // the nose ridge
        c.rect(26, 32, 4, 1, faceShade)
    }
    c.rect(36, 26, 1, 7, purpleDark)
}

// MARK: - Morgan le Fay

/// Morgan le Fay: a sorceress Clawd in a long green gown with gold trim, sleeves flaring at the cuff, long black hair
/// down her back and a gold tiara set with a green jewel; she floats, the gown's hem never quite touching the ground,
/// and casts green magic. Signature: her tiara glints and a green mist curls up around her.
private func drawMorganLeFay(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2A8A4A), greenDark = C(0x1A5E32), greenLight = C(0x4AB86A), gold = C(0xE8B530), goldDark = C(0xB08420)
    let hair = C(0x1E1418), hairLight = C(0x3A2A34), skin = C(0xF0C8A8), skinShade = C(0xD0A080)
    let mist = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let s = p.signature ?? 0
    // Signature: the mist behind her.
    if mist > 0 {
        for i in 0..<6 {
            let f = frac(s * 1.8 + Double(i) / 6)
            let a: Double = Double(i) * 1.05 + s * 6
            puff(c, x: 28 + cos(a) * 15, y: 40 - f * 14, k: f, C(0x3AD06A).alpha(mist))
        }
    }
    c.oy += p.breathe
    c.pattern(12, 25, ["..HHHH", ".HHHHH", "HHHHHH", "HHHHH.", "HHHHH.", ".HHHH.", "HHHHH.", "HHHH..", ".HHH..", "HHH...",
                       "HH....", "H....."], ["H": hair])
    // the gown, down to the ground
    var look = Look(body: green, shade: greenDark, arm: green, eye: nil)
    look.legs = false
    for y in 36...43 where y + c.oy <= 43 {
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, green)
        c.px(17 - k, y, greenLight); c.px(38 + k, y, greenDark)
        if y > 38 { c.px(24, y, greenDark); c.px(31, y, greenDark) }
    }
    drawBody(c, look, armRight: p.armRaise)
    c.rect(18, 33, 20, 1, gold)                                            // the neckline
    c.rect(18, 36, 20, 1, gold); c.rect(26, 35, 4, 3, goldDark); c.px(27, 36, C(0x3AD06A))   // girdle and clasp
    c.rect(20, 26, 16, 7, skin)
    c.rect(37, 26, 1, 7, skinShade)
    c.rect(37, 34 - p.armRaise, 4, 1, gold)                                // the cuff
    c.rect(41, 33 - p.armRaise, 1, 3, skin)
    // hair framing her face
    c.pattern(16, 20, [
        "......HHHHHHHHH......",
        "....HHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH.",
        "..HHHHLHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHH",
        ".HHHH.............HHH",
        ".HHH...............HH",
        "HHHH...............HH",
        "HHHH...............H.",
        "HHHH.................",
        "HHH..................",
        "HHH..................",
    ], ["H": hair, "L": hairLight])
    // the tiara
    c.pattern(19, 22, ["..G.....GGG.....G.", ".GGG...GGEGG...GGG", "GGGGGGGGGGGGGGGGGG"],
              ["G": gold, "E": C(0x3AD06A)])
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(21, 29, ink); c.px(34, 29, ink)                                   // lashes
    c.rect(22, 28, 2, 1, C(0x2A8A4A)); c.rect(32, 28, 2, 1, C(0x2A8A4A))     // green eye shadow
    c.rect(27, 32, 3, 1, C(0xB8283A))                                      // red lips
    // Signature: a glint on the tiara.
    if mist > 0.3 {
        let g = frac(s * 2.2)
        if g < 0.6 {
            let k = 1 - abs(g - 0.3) / 0.3
            let gx = 28, gy = 22
            c.glowLine(Double(gx) + 0.5, Double(gy) - 2 * k, Double(gx) + 0.5, Double(gy) + 1 + 2 * k, core: white.alpha(0.9), glow: gold.alpha(0.6),
                       coreR: 0.35, glowR: 1.2)
            c.glowLine(Double(gx) - 2 * k, Double(gy) + 0.5, Double(gx) + 1 + 2 * k, Double(gy) + 0.5, core: white.alpha(0.9), glow: gold.alpha(0.6),
                       coreR: 0.35, glowR: 1.2)
        }
        for i in 0..<4 {                                                   // and mist curling at her hem, in front
            let f = frac(s * 1.4 + Double(i) / 4)
            puff(c, x: 16 + Double(i) * 8 + sin(f * 6) * 2, y: 43 - f * 6, k: f, C(0x7AF0A0).alpha(mist))
        }
    }
}

// MARK: - Scorpion

/// Where the Scorpion's tail strikes from, as the fight effects see it: where it arches over his back.
private let scorpionTail = (x: 24.0, y: 22.0)
/// The base of the tail, at the small of his back.
private let scorpionTailBase = (x: 16.0, y: 31.0)

/// The Scorpion: Clawd in the green armoured suit with lighter ridged bands, a green helmet with a crest ridge, a dark
/// face plate and big yellow lenses, and the long segmented mechanical tail ending in a gold stinger, curled up over
/// his head. He fights with the tail. Signature: the tail coils tighter, quivering, then lashes forward and back.
private func drawScorpion(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A8A3A), greenDark = C(0x266E2A), greenLight = C(0x6AC060), face = C(0x1E3A22)
    let lens = C(0xE8D84A), metal = C(0x4E9A4A), metalDark = C(0x2E6A2E), sting = C(0xE8C02A)
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 38, 2, 1, greenLight); c.rect(lx, 41, 2, 3, greenDark) } }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: greenDark, eye: nil))
    for y in [34, 36] { c.rect(18, y, 20, 1, greenLight) }                // ridged bands
    c.rect(18, 37, 20, 1, greenDark)
    // the helmet with its crest
    c.pattern(17, 21, [
        ".......GGGGGGGG.......",
        ".....GGGGGLLGGGGGG....",
        "...GGGGGGGLLGGGGGGGG..",
        "..GGGGGGGGLLGGGGGGGGG.",
        ".GGGGGGGGGGGGGGGGGGGGG",
        ".GGGGGGGGGGGGGGGGGGGGG",
    ], ["G": green, "L": greenLight])
    c.rect(20, 27, 16, 6, face)
    c.pattern(21, 28, ["YYYY......YYYY", "YYYYY....YYYYY", ".YYY......YYY."], ["Y": lens])
    c.rect(26, 32, 5, 1, greenDark)
    // the tail, rising from the small of his back
    let s = p.signature ?? 0
    var start: Double, bend: Double
    if let a = p.melee {
        start = -100 + 0.4 * (a + 90); bend = a - start + 20      // always arched over his back, its tip toward `a`
    } else if s > 0.08 && s < 0.92 {
        if s > 0.62 && s < 0.78 {                                          // the strike
            let k = sin((s - 0.62) / 0.16 * .pi)
            start = -120 + 85 * k; bend = 170 - 140 * k
        } else {
            let coil = min(1, (s - 0.08) / 0.2) * (s > 0.78 ? max(0, 1 - (s - 0.78) / 0.14) : 1)
            start = -125 - 10 * coil + 5 * sin(s * 70) * coil; bend = 165 + 25 * coil
        }
    } else {
        start = -122 + 4 * sin(p.lt * 1.6); bend = 160 + 8 * sin(p.lt * 1.3)
    }
    for (i, ta) in p.trail.enumerated() {
        let tr = ta * .pi / 180
        bar(c, scorpionTail.x + cos(tr) * 8, scorpionTail.y + sin(tr) * 8, scorpionTail.x + cos(tr) * 20,
            scorpionTail.y + sin(tr) * 20, C(0xC8F0B0, 0.35 / Double(i + 1)), r: 1.3)
    }
    let end = tentacle(c, from: scorpionTailBase, angle: start, bend: bend, length: 30, [metal, metalDark], r0: 2.0, r1: 1.1, n: 13)
    let r = end.a * .pi / 180, ux = cos(r), uy = sin(r)
    c.rect(Int(end.x) - 1, Int(end.y) - 1, 3, 3, metalDark)
    bar(c, end.x, end.y, end.x + ux * 4, end.y + uy * 4, sting, r: 0.9)
    bar(c, end.x + ux * 4, end.y + uy * 4, end.x + ux * 4.5 + uy * 2, end.y + uy * 4.5 - ux * 2, sting, r: 0.5)
    c.px(Int(end.x + ux * 2), Int(end.y + uy * 2), C(0xFFF2A0))
}

// MARK: - Shocker

/// Where the Shocker's forward gauntlet emitter is.
private let shockerGauntlet = (x: 44.0, y: 33.0)

/// The Shocker: Clawd in the yellow suit quilted with brown diamond stitching, a quilted hood with black goggles, brown
/// gloves, boots and belt, and the bulky steel vibro-gauntlets with blue emitters that fire his shock beams.
/// Signature: both gauntlets thrum, he shudders as shock rings ripple out of them.
private func drawShocker(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xE8C02A), yellowDark = C(0xB8901A), brown = C(0x8A5A2A), brownDark = C(0x5E3A1A)
    let steel = C(0x9AA0AE), steelDark = C(0x5E6470), emitter = C(0x8AC8FF)
    let thrum = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let s = p.signature ?? 0
    if thrum > 0.3 { c.ox += noise(Int(s * 50)) > 0.5 ? 1 : 0 }
    drawLegs(c, Look(leg: yellow), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 40, 2, 4, brown) } }
    c.oy += p.breathe
    drawBody(c, Look(body: yellow, shade: yellowDark, arm: brown, eye: nil))
    // the quilting
    for y in 26...36 {
        for x in 18...36 where (x + y) % 6 == 0 || (x - y + 120) % 6 == 0 { c.px(x, y, brown) }
    }
    c.rect(18, 35, 20, 1, brown); c.rect(26, 35, 4, 1, brownDark)         // belt
    // the quilted hood
    c.pattern(18, 22, ["....YYYYYYYYYYYY....", "..YYYYYYYYYYYYYYYY..", ".YYYYYYYYYYYYYYYYYY.", "YYYYYYYYYYYYYYYYYYYY"],
              ["Y": yellow])
    for y in 22...25 {
        for x in 18...37 where c.isDrawn(x + c.ox, y + c.oy + c.baseY) && ((x + y) % 6 == 0 || (x - y + 120) % 6 == 0) {
            c.px(x, y, brown)
        }
    }
    // black goggles
    c.pattern(20, 28, [".bbbb....bbbb.", "bKKKKb..bKKKKb", "bKLKKbbbbKLKKb", ".bbbb....bbbb."],
                  ["b": brownDark, "K": ink, "L": C(0x5A6A8A)])
    c.rect(26, 32, 4, 1, brownDark)
    c.rect(15, 33, 1, 3, steelDark)                                       // the far gauntlet's rim, behind
    // the near gauntlet, forward and ready to fire
    c.oy += p.gunY
    c.rect(38, 30, 6, 6, steel); c.rect(38, 30, 6, 1, C(0xC8CCD8)); c.rect(38, 35, 6, 1, steelDark)
    c.rect(40, 31, 1, 4, steelDark)
    c.rect(44, 31, 2, 5, steelDark); c.rect(45, 32, 1, 3, C(0x3A5A8A)); c.px(45, 33, emitter)
    let hum = thrum > 0 ? 1 : (p.fire != nil ? 0.6 : 0)
    if hum > 0 { c.glowLine(45.5, 33.5, 45.5, 33.5, core: white.alpha(hum), glow: emitter.alpha(hum), coreR: 0.5, glowR: 2) }
    c.oy -= p.gunY
    // Signature: shock rings ripple out of both gauntlets.
    if thrum > 0.05 {
        for i in 0..<3 {
            let f = frac(s * 3 + Double(i) / 3)
            let col = C(0xC8E8FF).alpha(thrum * (1 - f) * 0.9)
            ring(c, shockerGauntlet.x + 2 + f * 4, shockerGauntlet.y + 0.5, r: 1.5 + f * 6, col)
            ring(c, 14 - f * 3, 34.5, r: 1 + f * 3, col)
        }
    }
}

// MARK: - Hobgoblin

/// The Hobgoblin: a yellow-green goblin mask with yellow eyes and a fanged grin under the pointed orange hood, an orange
/// cape, a blue chain-mail tunic, gloves and boots, a brown satchel strap; he rides his bat-glider wherever he goes and
/// throws jack-o'-lantern pumpkin bombs. Signature: he cackles ("HA HA"), holding up a pumpkin bomb wreathed in flame.
private func drawHobgoblin(_ c: PixelCanvas, _ p: Pose) {
    let orange = C(0xE8862A), orangeDark = C(0xB05E16), blue = C(0x3A4AB0), blueDark = C(0x262E7A)
    let mask = C(0xC8C060), maskShade = C(0x9A9440)
    let laugh = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    let s = p.signature ?? 0
    let rock = laugh > 0.5 && frac(s * 9) < 0.5 ? -1 : 0
    if p.flying { c.oy += sin(p.t * 5) > 0 ? -1 : 0 }
    // the cape, streaming out behind
    c.oy += p.breathe
    for y in 27...37 {
        let k = Double(y - 27) / 10
        let flap = sin(p.lt * (p.flying ? 9 : 3) - k * 3) * k * 1.5
        let back = Int((k * (p.flying ? 9 : 5) + flap).rounded())
        c.rect(17 - back, y, back + 2, 1, orangeDark); c.px(17 - back, y, C(0x8A4410))
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: blue), step: -1)
    for lx in [19, 23, 31, 35] { c.rect(lx, 37, 2, 3, blueDark) }
    hobGlider(c, t: p.t, flying: p.flying)
    c.oy += p.breathe + rock
    drawBody(c, Look(body: mask, shade: maskShade, arm: blue, eye: nil))
    // the chain-mail tunic and satchel strap
    c.rect(18, 33, 20, 5, blue); c.rect(18, 37, 20, 1, blueDark)
    for y in [34, 36] { for x in stride(from: 19 + (y % 4 == 0 ? 0 : 1), to: 37, by: 2) { c.px(x, y, blueDark) } }
    for k in 0..<6 { c.px(20 + k * 3, 33 + k / 2, C(0x7A4A1E)); c.px(21 + k * 3, 33 + k / 2, C(0x7A4A1E)) }
    // the pointed hood, its tip flopping back
    c.pattern(15, 15, [
        "OO.......................",
        ".OOo.....................",
        "..OOOOo..................",
        "...OOOOOOOo..............",
        "...OOOOOOOOOOOo..........",
        "..OOOOOOOOOOOOOOOOo......",
        ".OOOOOOOOOOOOOOOOOOOOOo..",
        ".OOOOOOOOOOOOOOOOOOOOOOO.",
        ".OOOOOOOOOOOOOOOOOOOOOOO.",
        "..OOOOOOOOOOOOOOOOOOOOO..",
        "..OOO..............OOOO..",
        "..OO................OOO..",
        "..OO.................O...",
        "..OO.....................",
        "...O.....................",
    ], ["O": orange, "o": orangeDark])
    // pointed ears, yellow eyes under heavy brows
    c.pattern(36, 27, ["..MM", ".MM."], ["M": mask])
    let brow = C(0x5A5420), eye = C(0xFFE23A)
    c.pattern(21, 26, ["BBB.......BBB", "..BB.....BB.."], ["B": brow])
    c.rect(21, 28, 4, 2, eye); c.rect(31, 28, 4, 2, eye)
    c.px(23, 28, ink); c.px(33, 28, ink)
    c.rect(27, 29, 2, 2, maskShade)                                        // the hooked nose
    // the grin, wider while he cackles
    let gape = Int((laugh * 2).rounded())
    c.rect(22, 31, 12, 1 + gape, C(0x3A1020))
    for x in stride(from: 22, to: 34, by: 2) { c.px(x, 31, white) }
    if gape > 0 { for x in stride(from: 23, to: 34, by: 2) { c.px(x, 31 + gape, white) } }
    c.px(21, 30, C(0x3A1020)); c.px(34, 30, C(0x3A1020))
    // the pumpkin bomb: thrown, held, or held high and blazing as he laughs
    var thrown = false
    if let fire = p.fire { thrown = frac(fire.t / blasterPeriod) < 0.25 }
    c.oy += p.gunY
    if thrown {
        c.rect(38, 27, 3, 3, blue)                                          // the arm up, mid-throw
    } else if laugh > 0.1 {
        let up = Int((laugh * 8).rounded())
        c.rect(38, 33 - up, 3, up + 3, blue)
        let py = 27 - up
        hobPumpkin(c, x: 38, y: py)
        for k in 0..<4 {                                                    // flames licking up off it
            let f = frac(s * 5 + Double(k) / 4)
            let x = 38 + k + Int(sin(s * 30 + Double(k)) * 1.2)
            c.px(x, py - 1 - Int(f * 4), (f < 0.4 ? C(0xFFE27A) : C(0xFF6A1E)).alpha(laugh * (1 - f * 0.7)))
        }
        c.glowLine(39.5, Double(py) - 1, 40.5, Double(py) - 1, core: C(0xFFE27A).alpha(laugh), glow: C(0xFF6A1E).alpha(laugh * 0.8),
                   coreR: 0.6, glowR: 2.2)
    } else {
        hobPumpkin(c, x: 39, y: 27)
        c.rect(38, 31, 3, 3, blue)
    }
    c.oy -= p.gunY
    if laugh > 0.6 {
        for (i, ch) in ["H", "A", "H", "A"].enumerated() {                 // the cackle rising off him
            let f = frac(s * 2.2 - Double(i) * 0.12)
            let a = f < 0.8 ? 1 : (1 - f) / 0.2
            glyph(c, Character(ch), 22 + i * 4, 12 - Int(f * 8) + (i % 2), C(0xFFB04A).alpha(a))
        }
    }
}

/// A jack-o'-lantern bomb, top-left at (`x`, `y`).
private func hobPumpkin(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [".g..", "OOOO", "OkOk", "OOOO", ".OO."],
              ["g": C(0x3A8A2A), "O": C(0xFF8A1E), "k": C(0x5A2A0A)])
}

/// The Hobgoblin's bat-glider: dark steel bat wings with scalloped edges, orange trim and yellow headlamps; a jet
/// burns at the back while it flies.
private func hobGlider(_ c: PixelCanvas, t: Double, flying: Bool) {
    let steel = C(0x3E3A48), light = C(0x6A6478), dark = C(0x24222C), trim = C(0xE8862A)
    c.pattern(7, 37, [
        "LL.........................................",
        ".SSL......................................L",
        "..SSSOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOSS",
        "...SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSYS",
        "....DDD.DDDD.DDDD.DDDD.DDDD.DDDD.DDDD.DDD..",
    ], ["S": steel, "L": light, "D": dark, "O": trim, "Y": C(0xFFE23A)])
    c.pattern(47, 39, ["SS", "S."], ["S": steel])
    if flying {
        let len = 3 + Int(noise(Int(t * 30)) * 3)
        c.rect(9 - len, 39, len, 2, C(0xFF9A2A))
        c.rect(10 - len, 39, max(1, len - 2), 1, C(0xFFE27A))
    }
}
