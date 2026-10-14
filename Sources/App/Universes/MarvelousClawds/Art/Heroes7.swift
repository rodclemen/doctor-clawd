import Foundation

// Heroes: more X-Men and the Spider-heroes. Clawd in costume, as ever: the body is the face (Clawd orange where the
// hero shows skin), with cowls, hair, masks and suits drawn over it.

let heroes7: [MarvelHero: Persona] = [
    .bishop: Persona(name: "Bisshop", weapon: .blaster, shot: .energy(core: C(0xFFE8D0), glow: C(0xFF8A3A)),
                  muzzle: (54, 32), headTop: 21, signature: 3.0,
                  draw: drawBishop),
    .cable: Persona(name: "Kable", weapon: .blaster, shot: .energy(core: C(0xE0F4FF), glow: C(0x3A9AFF)),
                  muzzle: (56, 33), headTop: 22, signature: 3.0,
                  draw: drawCable),
    .havok: Persona(name: "Havoc", weapon: .lightning, magic: Magic(core: C(0xFFFBD0), glow: C(0xFFE01E), jagged: false),
                  headTop: 21, signature: 2.8,
                  draw: drawHavok),
    .emmaFrost: Persona(name: "Emma Frosty", weapon: .saber, armoured: true,
                  headTop: 18, signature: 3.2,
                  draw: drawEmmaFrost),
    .banshee: Persona(name: "Bansheen", weapon: .lightning, motion: .fly, magic: Magic(core: C(0xF0FFF0), glow: C(0x8AE08A), jagged: false),
                  pivot: (37, 35), headTop: 21, signature: 2.8,
                  draw: drawBanshee),
    .angel: Persona(name: "Angell", weapon: .saber, motion: .fly, pivot: angelShoulder, headTop: 15, signature: 3.0,
                  draw: drawAngel),
    .domino: Persona(name: "Dominoe", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 21, signature: 2.8,
                  draw: drawDomino),
    .x23: Persona(name: "Y-23", weapon: .saber, headTop: 21, signature: 2.6,
                  draw: drawX23),
    .milesMorales: Persona(name: "Myles Moralez", weapon: .blaster, motion: .swing, shot: .web, muzzle: (42, 34), handGun: false,
                  headTop: 26, signature: 3.0,
                  draw: drawMilesMorales),
    .spiderGwen: Persona(name: "Spider-Gwyn", weapon: .blaster, motion: .swing, shot: .web, muzzle: (42, 34), handGun: false,
                  headTop: 19, signature: 2.8,
                  draw: drawSpiderGwen),
]

// MARK: - Shared pieces

private let skin = clawdOrange, skinShade = clawdShade
private let steelBlade = C(0xDCE0E8), clear = C(0, 0)

/// Legs, standing or walking (with boots in `boot`), or swept back in flight.
private func drawSuitLegs(_ c: PixelCanvas, _ p: Pose, _ leg: Px, boot: Px? = nil, bootRows: Int = 2) {
    if p.flying {
        let sweep = [(0, 36), (0, 37), (-1, 38), (-2, 39), (-3, 40)]
        for lx in [19, 23, 31, 35] {
            for (i, s) in sweep.enumerated() {
                let col = boot != nil && i >= sweep.count - bootRows ? boot! : leg
                c.rect(lx + s.0, s.1, 2, 1, col)
            }
        }
        return
    }
    drawLegs(c, Look(leg: leg), step: p.step)
    guard let boot else { return }
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx + 1, 38, 2, 2, boot) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, (lifted ? 42 : 43) - bootRows + 1, 2, bootRows, boot)
    }
}

/// A spider-hero's legs trailing back and down while swinging on a web line, `foot` on the last rows.
private func drawSwingLegs(_ c: PixelCanvas, _ p: Pose, leg: Px, foot: Px) {
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let kick = (i + max(0, p.step)) % 2
        for r in 0..<7 { c.rect(lx - r / 2 - kick, 36 + r, 2, 1, r >= 5 ? foot : leg) }
    }
}

/// An outline ellipse, `n` dots round it, only where it falls inside `clip` (x0, y0, x1, y1), if given.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px, n: Int = 40,
                  clip: (Int, Int, Int, Int)? = nil) {
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        let x = Int((cx + cos(a) * rx).rounded(.down)), y = Int((cy + sin(a) * ry).rounded(.down))
        if let k = clip, x < k.0 || y < k.1 || x > k.2 || y > k.3 { continue }
        c.px(x, y, col)
    }
}

/// A one-pixel circle outline of radius `r` round (`cx`, `cy`), only inside `clip` (x0, y0, x1, y1).
private func circle(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, _ col: Px, clip: (Int, Int, Int, Int)) {
    for y in clip.1...clip.3 {
        for x in clip.0...clip.2 {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            if abs((dx * dx + dy * dy).squareRoot() - r) < 0.5 { c.px(x, y, col) }
        }
    }
}

/// A four-pointed twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

/// A short forked crackle of energy jumping off (`x`, `y`), new every frame.
private func crackle(_ c: PixelCanvas, x: Double, y: Double, seed: Int, core: Px, glow: Px, reach: Double = 1.6) {
    var prev = (x, y)
    let a = (noise(seed) - 0.5) * 2.4 - .pi / 2
    for k in 1...3 {
        let r = Double(k) * reach
        let q = (x + cos(a) * r + (noise(seed + k) - 0.5) * 2, y + sin(a) * r)
        c.glowLine(prev.0, prev.1, q.0, q.1, core: core, glow: glow.alpha(0.6), coreR: 0.35, glowR: 1)
        prev = q
    }
    for k in 0..<3 {
        let b = noise(seed * 3 + k) * 2 * .pi, r = 2 + noise(seed * 5 + k) * 2.5
        c.px(Int(x + cos(b) * r), Int(y + sin(b) * r), k == 0 ? white : glow)
    }
}

/// A solid triangle (pixel centres inside it).
private func fillTriangle(_ c: PixelCanvas, _ a: (Double, Double), _ b: (Double, Double), _ d: (Double, Double), _ col: Px) {
    let x0 = Int(floor(min(a.0, b.0, d.0))), x1 = Int(ceil(max(a.0, b.0, d.0)))
    let y0 = Int(floor(min(a.1, b.1, d.1))), y1 = Int(ceil(max(a.1, b.1, d.1)))
    func side(_ p: (Double, Double), _ q: (Double, Double), _ x: Double, _ y: Double) -> Double {
        (q.0 - p.0) * (y - p.1) - (q.1 - p.1) * (x - p.0)
    }
    for y in y0...y1 {
        for x in x0...x1 {
            let px = Double(x) + 0.5, py = Double(y) + 0.5
            let s1 = side(a, b, px, py), s2 = side(b, d, px, py), s3 = side(d, a, px, py)
            if (s1 >= 0 && s2 >= 0 && s3 >= 0) || (s1 <= 0 && s2 <= 0 && s3 <= 0) { c.px(x, y, col) }
        }
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`, and
/// leaning forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = scratch(like: c)
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = dx + (lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0)
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i).alpha(alpha))
        }
    }
}

/// Draws `top` and `bottom` on scratch canvases and copies `top` above row `cut` (sprite rows, moving with it) and
/// `bottom` from there down: a change sweeping over a figure.
private func split(_ c: PixelCanvas, cut: Int, top: (PixelCanvas) -> Void, bottom: (PixelCanvas) -> Void) {
    let a = scratch(like: c), b = scratch(like: c)
    top(a); bottom(b)
    let row = cut + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<c.h {
        let s = y < row ? a : b
        for x in 0..<c.w {
            let i = (y * c.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(s, i))
        }
    }
}

private func scratch(like c: PixelCanvas) -> PixelCanvas {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    return s
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

// MARK: - Bishop

/// Bishop: the 90s look, dark brown skin, long black hair swept back to his shoulders, the red "M" tattooed over his
/// right eye, a navy vest with gold straps and a pouch belt, and a big plasma rifle with a glowing orange cell.
/// Signature: he soaks up energy, orange motes stream in from all round him into his chest, which glows, until his
/// eyes burn with it.
private func drawBishop(_ c: PixelCanvas, _ p: Pose) {
    let brown = C(0x7A4A2E), brownShade = C(0x5A3420), hair = C(0x16161B), hairHi = C(0x3A3A46)
    let suit = C(0x2A3048), suitDark = C(0x1C2034), gold = C(0xE8B530), goldDark = C(0xA87A1A), red = C(0xD8202A)
    let pouch = C(0x5A4A3A), orange = C(0xFF8A3A), hot = C(0xFFE8D0)
    let charge = p.signature.map { habitArc($0, hold: 0.35) } ?? 0
    drawSuitLegs(c, p, suit, boot: C(0x3A2A20), bootRows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: brown, shade: brownShade, arm: suit, eye: ink))
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHhHHHHHHhHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHhHHHHHHHHHHHHhHHH..",
        ".HHHH...............HHH.",
        ".HHH................HHH.",
        ".HH..................HH.",
        "HHH..................HHH",
        "HH....................HH",
        "HH....................HH",
        "H......................H",
    ], ["H": hair, "h": hairHi])
    c.pattern(20, 26, ["R...R", "RR.RR", "R.R.R"], ["R": red])          // the M over his right eye
    c.rect(22, 29, 2, 3, C(0x0E0E10)); c.rect(32, 29, 2, 3, C(0x0E0E10))
    c.px(23, 29, C(0xE8E0D0)); c.px(33, 29, C(0xE8E0D0))
    if charge > 0.7 {
        for x in [22, 32] { c.glowLine(Double(x) + 1, 30, Double(x) + 1, 30.5, core: hot, glow: orange.alpha(charge), coreR: 1, glowR: 2) }
    }
    // Vest, gold straps, pouch belt; a shoulder pad on the left arm.
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitDark)
    c.rect(20, 33, 2, 3, gold); c.rect(34, 33, 2, 3, gold)
    c.rect(18, 36, 20, 1, gold); c.rect(18, 37, 20, 1, goldDark)
    c.rect(22, 35, 3, 3, pouch); c.rect(31, 35, 3, 3, pouch)
    c.rect(14, 32, 4, 2, gold); c.rect(15, 34, 3, 2, suit)
    if charge > 0, let s = p.signature {
        // Energy drawn in from all round him, into the chest.
        if s < 0.8 {
            for i in 0..<10 {
                let f = frac(s * 2.5 + Double(i) / 10)
                let a = Double(i) * 2.4, r = 3 + 15 * (1 - f)
                let x = 28 + cos(a) * r, y = 33 + sin(a) * r * 0.75
                c.glowLine(x, y, x, y, core: hot.alpha(charge), glow: orange.alpha(0.8 * charge), coreR: 0.5, glowR: 1.4)
            }
        }
        c.glowLine(28, 34.5, 28, 34.5, core: hot, glow: orange, coreR: 0.4 + 0.8 * charge, glowR: 1 + 2.5 * charge)
    }
    // The plasma rifle, its cell glowing.
    c.oy += p.gunY
    let cell = charge > 0.3 ? hot : orange
    c.pattern(35, 30, [
        "....DDDDDDDD.......",
        "DDDGGGGGGGGGGDDDDDL",
        "DDDGGGOOOGGGGDDDDDL",
        "...gggggggggg......",
        ".....DD.DDD........",
        ".....DD.DDD........",
    ], ["D": C(0x2E3038), "G": C(0x5A5E6A), "g": C(0x3E424C), "L": C(0x9A9FAC), "O": cell])
    c.rect(39, 33, 3, 3, suit)
}

// MARK: - Cable

/// Cable: grizzled, a white buzz-cut and stubble, the techno-organic patch round his glowing left eye and a metal
/// left arm, a blue-grey combat suit with a bandolier of pouches, and a huge rifle. Signature: the eye flares and a
/// ripple of techno-organic light runs up the metal arm and spreads over his cheek.
private func drawCable(_ c: PixelCanvas, _ p: Pose) {
    let hairW = C(0xE4E4EA), hairS = C(0xA8ACB8), suit = C(0x3A4A6A), suitDark = C(0x283450)
    let strap = C(0x6A4A2A), pouch = C(0x8A6A3A), steel = C(0xA8B0BC), steelD = C(0x5A6270), steelL = C(0xE8F0FF)
    let eyeGlow = C(0xFFC83A), eyeHalo = C(0xFF9A2A)
    let sig = p.signature
    let flare = sig.map { habitArc($0, hold: 0.5) } ?? 0
    drawSuitLegs(c, p, suit, boot: C(0x2A2A30), bootRows: 4)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    c.pattern(18, 22, [
        "..SWSWSWSWSWSWSWSW..",
        ".WWWWWWWWWWWWWWWWWW.",
        "WWWWWWWWWWWWWWWWWWWW",
        "WWSWWWWWWWWWWWWWWSWW",
        "WWW..............WWW",
        "WW................WW",
    ], ["W": hairW, "S": hairS])
    c.rect(22, 29, 2, 3, ink)
    c.rect(21, 28, 4, 1, C(0x8A5A40))                                  // a hard brow
    // The techno-organic patch round the left eye.
    c.pattern(30, 27, [
        "..m.m.",
        ".mMMMm",
        "mM..Mm",
        "mM..M.",
        "mM..Mm",
        ".mMMm.",
        "..m...",
    ], ["m": steelD, "M": steel])
    c.rect(32, 29, 2, 3, eyeGlow)
    c.glowLine(33, 30.5, 33, 30.5, core: C(0xFFF4C0), glow: eyeHalo, coreR: 0.6, glowR: 1.8 + 1.2 * flare)
    if flare > 0.3 {
        let k = (flare - 0.3) / 0.7
        c.glowLine(33 - 6 * k, 30.5, 33 + 6 * k, 30.5, core: C(0xFFF4C0).alpha(k), glow: eyeHalo.alpha(0.7 * k), coreR: 0.4, glowR: 1.2)
        c.glowLine(33, 30.5 - 3 * k, 33, 30.5 + 3 * k, core: C(0xFFF4C0).alpha(k), glow: eyeHalo.alpha(0.7 * k), coreR: 0.3, glowR: 1)
    }
    for x in stride(from: 21, through: 34, by: 2) { c.px(x, 32, C(0xB86A50)) }   // stubble
    // Suit, bandolier and pouches.
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitDark)
    for i in 0..<5 { c.rect(20 + i * 3, 33 + i, 3, 1, strap) }
    c.rect(23, 34, 2, 2, pouch); c.rect(29, 36, 2, 2, pouch)
    c.rect(18, 37, 20, 1, strap)
    // The metal left arm, a shoulder plate over it.
    c.rect(14, 31, 5, 2, suitDark)
    c.rect(14, 33, 4, 4, steel); c.rect(14, 33, 1, 4, steelD); c.rect(15, 35, 3, 1, steelD)
    if flare > 0, let s = sig {
        // The ripple: a band of light climbing the arm, then circuit lines lighting across the cheek.
        let b = frac(s * 3)
        let row = 36 - Int((b * 6).rounded())
        if row >= 31 { c.rect(14, row, 4, 1, steelL.alpha(flare)) }
        let path: [(Int, Int)] = [(35, 33), (36, 32), (36, 31), (37, 30), (36, 28), (35, 26), (29, 32), (28, 31), (27, 31), (28, 28)]
        let lit = Int((Double(path.count) * flare).rounded())
        for (i, q) in path.prefix(lit).enumerated() {
            let hot = abs(Double(i) / Double(path.count) - b) < 0.2
            c.px(q.0, q.1, hot ? steelL : steel)
        }
    }
    // The big gun.
    c.oy += p.gunY
    c.pattern(34, 31, [
        "........LLLLL.........",
        "..GGGGGGDDDDDGGGGGG...",
        "GGGGGGGGGGGGGGGGGGGGGT",
        "GgggGGGGGBGGGGgggggggT",
        "....KK...MMMM.........",
        "....KK...MMMM.........",
        ".........MMM..........",
    ], ["G": C(0x4A4E58), "g": C(0x2E3038), "D": C(0x6A707C), "L": C(0x3A3E48), "T": C(0x9A9FAC),
        "K": C(0x2E3038), "M": C(0x5A4A3A), "B": C(0x3A9AFF)])
    c.rect(37, 35, 3, 3, suit)
}

// MARK: - Havok

/// Havok: the black suit with the concentric rings on his chest, the black cowl round his face and his blond hair
/// spilling over the top. His plasma pours from his hand, and the rings glow as he fires. Signature: the rings pulse
/// from the centre outwards, faster and faster, and throw a shockwave ring off round him.
private func drawHavok(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1E1E26), dark = C(0x121218), hair = C(0xE8C860), hairDark = C(0xB8963A)
    let ringGrey = C(0xA8A8B6), core = C(0xFFFBD0), glow = C(0xFFE01E)
    drawSuitLegs(c, p, black, boot: dark, bootRows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: black, shade: dark, arm: black, eye: nil), armRight: p.armRaise)
    c.pattern(17, 20, [
        ".....H..HH.HH..H.....",
        "...HHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHH.",
        ".HHHHHHhHHHHHHhHHHHHH",
        ".HHhHHHHHHHHHHHHHHhHH",
        "..hHHHHHHHHHHHHHHHHh.",
    ], ["H": hair, "h": hairDark])
    // His face, framed by the cowl.
    c.pattern(19, 26, [
        "..SSSSSSSSSSSSSS..",
        ".SSSSSSSSSSSSSSSS.",
        ".SSSSSSSSSSSSSSSS.",
        "..SSSSSSSSSSSSSS..",
    ], ["S": skin])
    c.rect(22, 27, 2, 2, ink); c.rect(32, 27, 2, 2, ink)
    // The rings: grey on black, lit by his power.
    let sig = p.signature
    let casting = p.zap != nil
    let radii: [Double] = [1.0, 3.6, 6.2]
    let centre = (x: 28.0, y: 34.0)
    for (i, r) in radii.enumerated() {
        var lit: Double = casting ? 0.7 + 0.3 * sin(p.t * 14 - Double(i) * 1.5) : 0
        if let s = sig {
            let speed: Double = 2 + 4 * s
            let wave = frac(s * speed) * 4
            lit = max(lit, max(0, 1 - abs(wave - Double(i) - 0.5)))
        }
        circle(c, centre.x, centre.y, r, ringGrey, clip: (18, 30, 37, 37))
        if lit > 0.05 { circle(c, centre.x, centre.y, r, core.alpha(lit), clip: (18, 30, 37, 37)) }
    }
    if casting || sig != nil {
        c.glowLine(centre.x, centre.y, centre.x, centre.y, core: clear, glow: glow.alpha(0.35), coreR: 0, glowR: 5)
    }
    c.rect(18, 37, 20, 1, dark)
    if let s = sig, s > 0.55 {
        // The shockwave.
        let f = (s - 0.55) / 0.45
        let r = 6 + f * 16
        for i in 0..<24 {
            let a0 = Double(i) / 24 * 2 * .pi, a1 = Double(i) + 0.5
            let a1r = a1 / 24 * 2 * .pi
            c.glowLine(27.5 + cos(a0) * r, 33 + sin(a0) * r * 0.7, 27.5 + cos(a1r) * r, 33 + sin(a1r) * r * 0.7,
                       core: core.alpha(1 - f), glow: glow.alpha(0.6 * (1 - f)), coreR: 0.35, glowR: 1.3)
        }
    }
    if casting {
        let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(p.armRaise))
        ring(c, hand.x, hand.y, 2.5, 2.5, glow.alpha(0.7), n: 14)
    }
}

// MARK: - Emma Frost

/// Emma Frost: the White Queen, a big blonde bouffant swept to one side, a white corset with the X-belt, white
/// gloves and a white cape. A telepath with no blasts to throw: she fights hand to hand in her diamond form, which
/// she's in whenever she's at work. Signature: she turns to diamond, the change sweeping down her from head to toe
/// (hair, skin and costume all faceted crystal, glinting), holds it, and sweeps back.
private func drawEmmaFrost(_ c: PixelCanvas, _ p: Pose) {
    if p.mode == .working && !p.walking && !p.flying { drawEmma(c, p, diamond: true); return }
    let d = p.signature.map { habitArc($0, hold: 0.45) } ?? 0
    guard d > 0.01 else { drawEmma(c, p, diamond: false); return }
    let cut = 14 + Int((d * 32).rounded())
    split(c, cut: cut, top: { drawEmma($0, p, diamond: true) }, bottom: { drawEmma($0, p, diamond: false) })
    // A bright seam where the change is.
    if d < 0.98 {
        let (ox, oy, by) = (c.ox, c.oy, c.baseY)
        c.ox = 0; c.oy = 0; c.baseY = 0
        let row = cut + oy + by
        for x in 0..<c.w where c.isDrawn(x, row) { c.px(x, row, C(0xE8F8FF, 0.8)) }
        c.ox = ox; c.oy = oy; c.baseY = by
    }
}

private func drawEmma(_ c: PixelCanvas, _ p: Pose, diamond: Bool) {
    let suit = diamond ? C(0xC8E8FF) : C(0xF4F4F8), suitShade = diamond ? C(0x7AB0E0) : C(0xB8BCC8)
    let face = diamond ? C(0xB0DCFF) : skin, faceShade = diamond ? C(0x6AA0D8) : skinShade
    let hair = diamond ? C(0xD8F0FF) : C(0xF0D890), hairShade = diamond ? C(0x8AC0E8) : C(0xC8A850)
    let cape = diamond ? C(0xB8E0FF) : C(0xDDE2EC), capeEdge = diamond ? C(0x5A90C8) : C(0x7A8296)
    let eye = diamond ? C(0x2A5A8A) : ink, leg = diamond ? C(0x9ACCF0) : C(0xD8DCE6)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge)
    drawSuitLegs(c, p, leg, boot: suit, bootRows: 3)
    c.oy += p.breathe
    // The cape's tall collar, standing up behind her hair.
    c.pattern(11, 19, [
        "CC..................................CC",
        "CCC................................CCC",
        "eCCC..............................CCCe",
        ".eCCC............................CCCe.",
        ".eCCCC..........................CCCCe.",
        "..eCCC..........................CCCe..",
        "..eCCCC........................CCCCe..",
        "...eCCC........................CCCe...",
        "....eCC........................CCe....",
        ".....eC........................Ce.....",
    ], ["C": cape, "e": capeEdge])
    drawBody(c, Look(body: face, shade: faceShade, arm: suit, eye: eye), armRight: p.armRaise)
    c.pattern(15, 18, [
        ".......HHHHHHHHHHH........",
        ".....HHHHHHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHHHHHH...",
        "..HHHHHHhHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHhHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHhhhhhHHHHHHHHHHH",
        "HHHHHHHHh.........hHHHHHHH",
        "HHHHHh.............hHHHHH.",
        "HHHHh...............hHHHH.",
        "HHHH................HHHH..",
        "HHHh................hHHH..",
        ".HHH................HHHh..",
        ".HHh................hHH...",
        "..Hh.................hH...",
    ], ["H": hair, "h": hairShade])
    if !diamond { c.rect(27, 32, 2, 1, C(0xA83A5A)) }                 // lipstick
    // Bare shoulders over the corset, and the X-belt.
    c.pattern(18, 34, [
        "SSSSSSSSSsSSSSSSSSSs",
        "SSSSSSSSSsSSSSSSSSSs",
        "bbbbbbbbbbbbbbbbbbbb",
        "ssssssssssssssssssss",
    ], ["S": suit, "s": suitShade, "b": diamond ? C(0x5A90C8) : C(0x3A3A46)])
    c.pattern(26, 35, ["X.X", ".X.", "X.X"], ["X": diamond ? C(0xE8F8FF) : C(0xD8DCE6)])
    if diamond {
        // Facets and glints.
        let facet = C(0x8AC0E8, 0.7)
        for (a, b) in [((19.0, 27.0), (24.0, 32.0)), ((24.0, 32.0), (30.0, 26.5)), ((30.0, 26.5), (36.0, 32.0)),
                       ((20.0, 22.0), (26.0, 19.0)), ((30.0, 19.0), (35.0, 23.0))] as [((Double, Double), (Double, Double))] {
            c.glowLine(a.0, a.1, b.0, b.1, core: facet, glow: clear, coreR: 0.35, glowR: 0.4)
        }
        let k = Int(p.t * 6)
        let spots: [(Int, Int)] = [(21, 23), (34, 21), (20, 34), (35, 35), (27, 28), (17, 30)]
        for (i, s) in spots.enumerated() where (i + k) % 3 == 0 { twinkle(c, s.0, s.1, C(0xFFFFFF)) }
    }
    // A punch: the arm thrown out along the melee angle, a fist on the end, faint fists where a fast swing just was.
    if let a = p.melee {
        let h = Sprite.hand, fist = diamond ? C(0xE8F8FF) : suit
        func reach(_ angle: Double) -> (x: Double, y: Double) {
            let r = angle * .pi / 180
            return (h.x + cos(r) * 6, h.y + sin(r) * 6)
        }
        for (i, ta) in p.trail.enumerated() {
            let e = reach(ta)
            c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist.alpha(0.35 / Double(i + 1)))
        }
        let e = reach(a)
        c.glowLine(h.x - 2, h.y - 0.5, e.x, e.y, core: suit, glow: clear, coreR: 1.2, glowR: 1.3)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
        if diamond { c.px(Int(e.x.rounded()), Int(e.y.rounded()) - 1, white) }
    }
}

// MARK: - Banshee

/// Banshee: Sean Cassidy, swept-back red hair and a bushy moustache, the green suit with the yellow gloves, boots
/// and the yellow wing-flaps from wrist to hip. His sonic scream pours from his mouth; flying, he spreads his arms and
/// glides on the flaps. Signature: he throws his arms out and screams, rings of sound rolling out ahead of him.
private func drawBanshee(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E8A3A), greenDark = C(0x1E5A28), yellow = C(0xE8C02A), yellowDark = C(0xA8841A)
    let hair = C(0xC8502A), hairDark = C(0x8A3018)
    let sig = p.signature
    let scream = sig.map { habitArc($0, hold: 0.7) } ?? 0
    let open = p.zap != nil || scream > 0.3
    layer(c, lean: p.flying ? 4 : 0) { c in
        drawSuitLegs(c, p, green, boot: yellow, bootRows: 3)
        c.oy += p.breathe
        drawBody(c, Look(body: skin, shade: skinShade, arm: yellow, eye: ink), armRight: p.armRaise)
        // Wing-flaps: wrist to armpit to hip, spread with the arms in flight or screaming.
        let spread: Double = p.flying ? 1 : scream
        let lh: (Double, Double) = (16 - 7 * spread, 34.5 - 5 * spread)
        let rh: (Double, Double) = (39.5 + 6 * spread, 34.5 - 5 * spread - Double(p.armRaise) * (1 - spread))
        fillTriangle(c, (18.5, 28), lh, (18.5, 37.5), yellow)
        fillTriangle(c, (37.5, 28), rh, (37.5, 37.5), yellow)
        c.glowLine(lh.0, lh.1, 18.5, 37.5, core: yellowDark, glow: clear, coreR: 0.4, glowR: 0.45)
        c.glowLine(rh.0, rh.1, 37.5, 37.5, core: yellowDark, glow: clear, coreR: 0.4, glowR: 0.45)
        c.rect(Int(lh.0) - 1, Int(lh.1) - 1, 3, 3, yellow)
        c.rect(Int(rh.0) - 1, Int(rh.1) - 1, 3, 3, yellow)
        c.pattern(16, 20, [
            "......HHHHHHHHHHH.......",
            "...HHHHHHHHHHHHHHHH.....",
            ".HHHHHHHhHHHHHHHHHHH....",
            "HHHHHHHHHHHHHhHHHHHHHH..",
            "HHHHhHHHHHHHHHHHHHHHHHH.",
            "HHHHHHHHHHHHHHHHHHHHHH..",
            "HHHHH...............HH..",
            ".HHH..................",
            ".HH...................",
        ], ["H": hair, "h": hairDark])
        // The moustache, and the mouth, open in a scream.
        c.rect(27, 31, 10, 1, hair); c.rect(26, 32, 2, 2, hair); c.rect(36, 32, 1, 1, hair)
        if open {
            c.pattern(32, 32, [".KK.", "KRRK", ".KK."], ["K": C(0x3A0E10), "R": C(0x8A2020)])
        } else {
            c.rect(30, 32, 4, 1, skinShade)
        }
        c.rect(18, 33, 20, 5, green)
        c.rect(37, 33, 1, 5, greenDark)
        c.pattern(18, 33, ["YYYYYYY......YYYYYYY", "..YYYYYY....YYYYYY..", "....YYYY....YYYY...."], ["Y": yellow])
        c.rect(18, 37, 20, 1, greenDark)
        c.rect(26, 36, 4, 1, yellow)
    }
    if scream > 0.3, let s = sig {
        // Sound rings rolling out from his mouth.
        let mouth = (x: 36.0, y: Double(33 + p.breathe))
        for i in 0..<3 {
            let f = frac(s * 3 + Double(i) / 3)
            let r = 2 + f * 16
            let alpha = (1 - f) * scream
            var prev: (Double, Double)? = nil
            for k in 0...6 {
                let a = (-55 + Double(k) * 110 / 6) * .pi / 180
                let q = (mouth.x + cos(a) * r, mouth.y + sin(a) * r * 0.9)
                if let pv = prev {
                    c.glowLine(pv.0, pv.1, q.0, q.1, core: C(0xF0FFF0).alpha(alpha), glow: C(0x8AE08A).alpha(0.7 * alpha), coreR: 0.35, glowR: 1.3)
                }
                prev = q
            }
        }
    }
}

// MARK: - Angel

private let angelShoulder = (x: 37.5, y: 29.5)

/// Angel: Warren Worthington III in the classic blue-and-white, blond hair, a blue suit with the white wing-shaped
/// yoke and red belt, and the great white feathered wings, folded up behind his shoulders. He slashes with his right
/// wing, and flies with both beating. Signature: he spreads his wings to their full span, beats them twice, and a few
/// loose feathers drift down.
private func drawAngel(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4FB0), blueDark = C(0x1C3478), wht = C(0xF2F2F6), red = C(0xC8202A)
    let hair = C(0xE8C860), hairDark = C(0xB8963A)
    let sig = p.signature
    let show = sig.map { habitArc($0, hold: 0.6) } ?? 0
    var spread: Double = show
    if let s = sig, show > 0.95 { spread = 0.8 + 0.2 * cos((s - 0.2) * 4 * 2 * .pi) }
    if p.flying { spread = 0.55 + 0.45 * sin(p.t * 9) }
    layer(c, lean: p.flying ? 4 : 0) { c in
        c.oy += p.breathe
        drawWing(c, root: (20, 29), spread: spread, right: false)
        if p.melee == nil { drawWing(c, root: (36, 29), spread: spread, right: true) }
        c.oy -= p.breathe
        drawSuitLegs(c, p, blue, boot: blueDark, bootRows: 2)
        c.oy += p.breathe
        drawBody(c, Look(body: skin, shade: skinShade, arm: blue, eye: ink))
        c.pattern(17, 21, [
            ".....HHHHHHHHHH.....",
            "...HHHHHHHHHHHHHHH..",
            "..HHHHHhHHHHHHhHHHH.",
            ".HHHHHHHHHHHHHHHHHHH",
            ".HHHhHHHHHHhHHHHHHHH",
            ".HHH.H...........HHH",
            "..H...............H.",
        ], ["H": hair, "h": hairDark])
        c.rect(18, 33, 20, 5, blue)
        c.pattern(18, 33, ["WWWWWWW......WWWWWWW", "..WWWWWW....WWWWWW..", "....WWWW....WWWW....", "......WW....WW......"],
                  ["W": wht])
        c.rect(37, 33, 1, 4, blueDark)
        c.rect(18, 37, 20, 1, red)
        c.rect(27, 37, 2, 1, C(0xF0C040))
    }
    if let a = p.melee {
        c.oy += p.breathe
        for (i, ta) in p.trail.enumerated() { drawWingBlade(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawWingBlade(c, angle: a)
    }
    if let s = sig, s > 0.35 {
        // Loose feathers drifting down.
        for i in 0..<3 {
            let f = (s - 0.35 - Double(i) * 0.12) / 0.5
            guard f > 0, f < 1 else { continue }
            let x = Double(8 + i * 19) + sin(f * 9 + Double(i)) * 2, y = 22 + f * 20
            c.glowLine(x, y, x + 1.5, y - 0.7, core: C(0xF4F4F8).alpha(1 - f * 0.6), glow: C(0x9098A8, 0.5), coreR: 0.5, glowR: 0.9)
        }
    }
}

/// One of Angel's wings from the shoulder `root`: folded up behind him at `spread` 0, out wide at 1.
private func drawWing(_ c: PixelCanvas, root: (Double, Double), spread: Double, right: Bool) {
    let folded: [Double] = [-95, -101, -109, -119, -131, -146]
    let open: [Double] = [-128, -142, -156, -170, -184, -198]
    let lenF: [Double] = [15, 14, 12, 10, 8, 7]
    let lenO: [Double] = [17, 17, 15, 13, 11, 9]
    for i in (0..<folded.count).reversed() {
        var a = folded[i] + (open[i] - folded[i]) * spread
        if right { a = 180 - a }
        let l = lenF[i] + (lenO[i] - lenF[i]) * spread
        drawFeather(c, from: root, angle: a, length: l)
    }
}

/// A long white feather from `from`, out along `angle` degrees: grey-edged so overlapping feathers read apart.
private func drawFeather(_ c: PixelCanvas, from: (Double, Double), angle: Double, length: Double, alpha: Double = 1) {
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    let tip = (from.0 + ux * length, from.1 + uy * length)
    c.glowLine(from.0, from.1, tip.0, tip.1, core: C(0x9098A8).alpha(alpha), glow: clear, coreR: 1.25, glowR: 1.3)
    c.glowLine(from.0, from.1, tip.0 - ux * 0.8, tip.1 - uy * 0.8, core: C(0xF4F4F8).alpha(alpha), glow: clear, coreR: 0.75, glowR: 0.8)
}

/// Angel's right wing swung as a blade from the shoulder, its feathers fanned behind the leading edge.
private func drawWingBlade(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    let offsets: [Double] = [-14, -9, -5, -1, 3]
    let lengths: [Double] = [8, 11, 13, 15, 16]
    for (o, l) in zip(offsets, lengths) {
        drawFeather(c, from: (angelShoulder.x - 1.5, angelShoulder.y), angle: angle + o, length: l, alpha: alpha)
    }
}

// MARK: - Domino

/// Domino: chalk-white skin with the black patch round her left eye, a sleek black bob, a black tactical suit and a
/// pistol. Signature: luck, she flips a gold coin off her thumb, it spins up high and drops back into her hand, and
/// she winks.
private func drawDomino(_ c: PixelCanvas, _ p: Pose) {
    let chalk = C(0xE6E6EC), chalkShade = C(0xB8B8C4), suit = C(0x1E1E26), suitLight = C(0x4A4A58), hair = C(0x16161B)
    let gold = C(0xF0C040), goldDark = C(0xB88A1E)
    drawSuitLegs(c, p, suit, boot: C(0x3A3A46), bootRows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: chalk, shade: chalkShade, arm: suit, eye: nil))
    c.pattern(16, 21, [
        "......HHHHHHHHHHH.......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHH..HHHHHH....HHHHH.",
        ".HHH...............HHHH.",
        ".HHH................HHH.",
        ".HH.................HHH.",
        ".HH..................HH.",
        "..H..................H..",
    ], ["H": hair])
    // The patch, the eye open inside it.
    c.pattern(20, 27, [".KKKK.", "KKKKKK", "KKWWKK", "KKWPKK", "KKWPKK", ".KKKK."], ["K": ink, "W": C(0xF0F0F4), "P": C(0x3A6AA8)])
    let sig = p.signature
    let wink = sig.map { $0 > 0.84 && $0 < 0.98 } ?? false
    if wink { c.rect(32, 30, 2, 1, ink) } else { c.rect(32, 29, 2, 3, ink) }
    c.rect(26, 32, 3, 1, chalkShade)
    // Suit, belt, a thigh holster strap.
    c.rect(18, 34, 20, 4, suit)
    c.rect(18, 34, 20, 1, suitLight)
    c.rect(18, 36, 20, 1, suitLight)
    c.rect(26, 36, 3, 1, C(0x8A8F9C))
    // The coin flip, off her left thumb.
    if let s = sig, s > 0.06, s < 0.84 {
        c.rect(15, 30, 3, 3, suit)
        let u = (s - 0.06) / 0.72
        let y = 29 - Int((17 * sin(u * .pi)).rounded())
        let widths = [3, 2, 1, 2]
        let w = widths[Int(u * 18) % 4]
        c.rect(17 - w / 2, y - 1, w, 3, w == 1 ? goldDark : gold)
        if w == 3 { c.px(16, y, goldDark) }
    } else if let s = sig, s >= 0.84 {
        c.rect(15, 30, 3, 3, suit)
        c.rect(16, 28, 2, 2, gold)
        twinkle(c, 18, 26, C(0xFFE890))
    }
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 31)
    c.rect(38, 33, 3, 3, suit)
}

// MARK: - X-23

/// X-23: Laura Kinney in her dark X-Force suit, long straight black hair parted in the middle, green eyes, a black
/// suit with a grey belt (two claws from each fist and one from her foot. Signature: SNIKT) both fists come up and
/// the claws shoot out, the foot claw too, a glint running up the blades.
private func drawX23(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x26262E), suitDark = C(0x16161B), trim = C(0x5A5A6E), hair = C(0x1A1A22), hairHi = C(0x3A3A4C)
    let sig = p.signature
    let out = sig.map { habitArc(min(1, max(0, ($0 - 0.08) / 0.84)), hold: 0.6) } ?? 0
    drawSuitLegs(c, p, suit, boot: suitDark, bootRows: 3)
    // The foot claw, from the front foot.
    let foot = p.melee != nil && !p.walking ? 1 : out
    if foot > 0.05 && !seatedPose && !p.flying {
        let bottom: Double = p.step == 1 ? 41.5 : 42.5
        c.glowLine(37, bottom, 37 + 4 * foot, bottom - 1.5 * foot, core: steelBlade, glow: clear, coreR: 0.4, glowR: 0.45)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: ink))
    c.px(23, 30, C(0x3AB85A)); c.px(33, 30, C(0x3AB85A))
    c.pattern(15, 21, [
        ".......HHHHHlHHHHH........",
        ".....HHHHHHHlHHHHHHH......",
        "....HHHHHHHHlHHHHHHHH.....",
        "...HHHHHHHHH.HHHHHHHHHH...",
        "...HHHHHHHH...HHHHHHHHH...",
        "..HHHHHHHh.....hHHHHHHHH..",
        "..HHHHHh.........hHHHHHH..",
        "..HHHHH...........hHHHHH..",
        "..HHHH.............HHHHH..",
        "..HHHH..............HHHH..",
        "..HHH...............HHHH..",
        ".HHHH...............HHHH..",
        ".HHH.................HHH..",
        ".HHH.................HHH..",
        ".HH...................HH..",
        ".HH...................HH..",
    ], ["H": hair, "h": hairHi, "l": hairHi])
    c.rect(19, 33, 18, 5, suit)
    c.rect(18, 36, 20, 1, trim)
    c.pattern(26, 35, ["X.X", ".X.", "X.X"], ["X": C(0xA8ACB8)])
    c.rect(18, 37, 20, 1, suitDark)
    if let a = p.melee {
        c.rect(15, 33, 3, 3, suit)
        drawTwinClaws(c, at: (Sprite.hand.x - 1, Sprite.hand.y - 0.5), angle: a, out: 1, trail: p.trail)
    } else if out > 0.01, let s = sig {
        // Both fists up, claws out.
        c.rect(15, 28, 3, 4, suit); c.rect(38, 28, 3, 4, suit)
        drawTwinClaws(c, at: (39.5, 28.5), angle: -60, out: out, trail: [])
        drawTwinClaws(c, at: (16.5, 28.5), angle: -120, out: out, trail: [])
        if out > 0.95 {
            let g = frac(s * 4)
            twinkle(c, 41 + Int(g * 4), 27 - Int(g * 6), C(0xFFFFFF))
        }
    }
}

/// Two blades out of the fist at `at`, pointing along `angle`; `out` 0…1 how far they're unsheathed.
private func drawTwinClaws(_ c: PixelCanvas, at h: (Double, Double), angle: Double, out: Double, trail: [Double]) {
    let len = 1 + 8 * out
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(h.0 + cos(r) * 3, h.1 + sin(r) * 3, h.0 + cos(r) * (2 + len), h.1 + sin(r) * (2 + len),
                   core: white.alpha(0.3 / Double(i + 1)), glow: C(0xBFD8FF).alpha(0.3 / Double(i + 1)), coreR: 0.8, glowR: 2.2)
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    let bx = h.0 + ux * 1.5, by = h.1 + uy * 1.5
    c.glowLine(bx, by, bx + ux * (len - 1.5), by + uy * (len - 1.5), core: C(0x2A2E3A), glow: clear, coreR: 0.5, glowR: 0.55)
    for k in [-1.2, 1.2] {
        let sx = bx + nx * k, sy = by + ny * k
        c.glowLine(sx, sy, sx + ux * len, sy + uy * len, core: steelBlade, glow: clear, coreR: 0.4, glowR: 0.45)
    }
}

// MARK: - Miles Morales

/// Miles Morales: the black suit with the red web lines over the mask and shoulders, white eye lenses, the big red
/// spider on his chest and red soles. Travelling, he swings on a web line. Signature: he goes invisible, the
/// camouflage fades him almost out, shimmering, then snaps back with his venom blast crackling yellow round his fists.
private func drawMilesMorales(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { drawMiles(c, p, venom: 0); return }
    let fade = s < 0.62 ? habitArc(s / 0.62, hold: 0.45) : 0
    let venom = s >= 0.62 ? habitArc((s - 0.62) / 0.38, hold: 0.5) : 0
    if fade > 0.01 {
        layer(c, alpha: 1 - 0.85 * fade) { drawMiles($0, p, venom: 0) }
        // A shimmer passing down over him.
        let y = 24 + Int(frac(s * 4) * 19)
        for x in stride(from: 16, through: 40, by: 3) where noise(x + Int(s * 60)) > 0.4 {
            c.px(x, y + c.oy, C(0xFFFFFF, 0.35 * fade))
        }
        return
    }
    drawMiles(c, p, venom: venom)
}

private func drawMiles(_ c: PixelCanvas, _ p: Pose, venom: Double) {
    let black = C(0x1E1E26), dark = C(0x101016), red = C(0xD8202A), redDark = C(0x8A1218)
    let swinging = p.walking
    if swinging {
        drawSwingLegs(c, p, leg: black, foot: red)
    } else {
        drawLegs(c, Look(leg: black), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                c.rect(lx, p.step >= 0 && i % 2 == p.step ? 42 : 43, 2, 1, red)
            }
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: black, shade: dark, arm: black, eye: nil))
    c.pattern(18, 26, [
        "BBBrBBBBBrrBBBBBrBBB",
        "rBBBBBBBBrrBBBBBBBBr",
        "BrBWWWWBBrrBBWWWWBrB",
        "BBBWWWWWrrrrWWWWWBBB",
        "BrBBWWWWBrrBWWWWBBrB",
        "rBBBBWWBBrrBBWWBBBBr",
        "BrBBrBBBrrrrBBBrBBrB",
        "BBrBBBBBBBBBBBBBBrBB",
        "BBBrBBBBBBBBBBBBrBBB",
        "BBBBBBBBBBBBBBBBBBBb",
        "BBBBBBBBBBBBBBBBBBBb",
        "bbbbbbbbbbbbbbbbbbbb",
    ], ["B": black, "b": dark, "r": red, "W": white])
    c.pattern(24, 33, ["R.RRRR.R", ".R.RR.R.", "R.RRRR.R", ".R.RR.R."], ["R": red])
    c.rect(15, 33, 3, 3, black); c.px(17, 34, redDark)
    if venom > 0.05 {
        let seed = Int(p.t * 24)
        for (i, x) in [16.5, 39.5].enumerated() {
            c.glowLine(x, 32.5, x, 32.5, core: C(0xFFFBD0).alpha(venom), glow: C(0xFFD21E).alpha(venom), coreR: 0.6, glowR: 2.4)
            crackle(c, x: x, y: 32.5, seed: seed + i * 9, core: C(0xFFFBD0), glow: C(0xFFD21E))
        }
        c.rect(15, 31, 3, 3, black); c.rect(38, 31, 3, 3, black)
        return
    }
    if swinging {
        c.glowLine(39, 32, 41, 23, core: black, glow: clear, coreR: 1.1, glowR: 1.2)
        c.rect(40, 21, 3, 3, black); c.px(42, 21, red)
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 4, 3, black)
    c.px(41, 33, red)
    if p.fire != nil || p.ready { c.px(41, 34, C(0xC8CCD4)) }
}

// MARK: - Spider-Gwen

/// Spider-Gwen: Ghost-Spider in the white hood with its magenta lining, a white web-lined mask with big black-rimmed
/// lenses, a white top over a black suit, black legs and teal ballet-shoe feet. Travelling, she swings on a web line.
/// Signature: she flips her hood back, showing the mask's web-lined crown, then flicks it up again.
private func drawSpiderGwen(_ c: PixelCanvas, _ p: Pose) {
    let hood = C(0xF0F0F4), hoodShade = C(0xB8BCC8), lining = C(0xE04A9A), liningDark = C(0x9A2A6A)
    let mask = C(0xE6E6EE), web = C(0x6A6A7A), black = C(0x1E1E26), teal = C(0x3AC8C8)
    let swinging = p.walking
    if swinging {
        drawSwingLegs(c, p, leg: black, foot: teal)
    } else {
        drawSuitLegs(c, p, black, boot: teal, bootRows: 2)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: hoodShade, arm: hood, eye: nil))
    let back = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let top = 19 + Int((back * 14).rounded())                       // the hood's top row as it slides back
    if back > 0.05 {
        // The mask's crown.
        c.pattern(18, 21, [
            "....MMMMMMMMMMMM....",
            "..MMMMMMwMMwMMMMMM..",
            ".MMMMMwMMMMMMwMMMMM.",
            "MMMMwMMMMwwMMMMwMMMM",
            "MMMwMMMMMwwMMMMMwMMM",
        ], ["M": mask, "w": web])
    }
    let rows: [String] = [
        ".......HHHHHHHHHHHH.......",
        ".....HHHHHHHHHHHHHHHH.....",
        "....HHHHHHhHHHHhHHHHHH....",
        "...HHHHHHHHHHHHHHHHHHHH...",
        "...HHHHHHHHHHHHHHHHHHHH...",
        "..HHHHHHPPPPPPPPPPHHHHHH..",
        "..HHHHPP..........PPHHHH..",
        ".HHHHP..............PHHHH.",
        ".HHHP................PHHH.",
        ".HHP..................PHH.",
        ".HHP..................PHH.",
        "HHHP..................PHHH",
        "HHp....................pHH",
        "HHp....................pHH",
        "Hh......................hH",
    ]
    for (i, row) in rows.enumerated() where 19 + i >= top {
        c.pattern(15, 19 + i, [row], ["H": hood, "h": hoodShade, "P": lining, "p": liningDark])
    }
    if back > 0.5 {
        // Bunched behind her neck.
        c.rect(16, 31, 3, 3, hood); c.rect(37, 31, 3, 3, hood); c.rect(16, 33, 3, 1, hoodShade); c.rect(37, 33, 3, 1, hoodShade)
    }
    // Web lines and the lenses.
    c.rect(27, 26, 2, 7, mask)
    for (a, b) in [((28.0, 26.0), (28.0, 33.0)), ((28.0, 30.0), (19.0, 26.5)), ((28.0, 30.0), (37.0, 26.5)),
                   ((28.0, 31.0), (19.0, 33.0)), ((28.0, 31.0), (37.0, 33.0))] as [((Double, Double), (Double, Double))] {
        c.glowLine(a.0, a.1, b.0, b.1, core: web, glow: clear, coreR: 0.35, glowR: 0.4)
    }
    c.pattern(20, 27, [
        ".KKK........KKK.",
        "KWWWK......KWWWK",
        "KWWWWK....KWWWWK",
        ".KWWWK....KWWWK.",
        "..KKK......KKK..",
    ], ["K": ink, "W": white])
    // White top over the black suit.
    c.rect(18, 33, 20, 5, black)
    c.pattern(18, 33, ["WWWWWWWWWWWWWWWWWWWW", "WWWwWWWWWWWWWWWWwWWW", ".WWWWWWWWWWWWWWWWWW."], ["W": hood, "w": web])
    c.rect(18, 35, 20, 1, hoodShade)
    c.rect(15, 33, 3, 3, hood); c.rect(15, 35, 3, 1, lining)
    if swinging {
        c.glowLine(39, 32, 41, 23, core: hood, glow: clear, coreR: 1.1, glowR: 1.2)
        c.rect(40, 21, 3, 3, hood); c.rect(40, 23, 3, 1, lining)
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 4, 3, hood)
    c.rect(38, 35, 4, 1, lining)
    if p.fire != nil || p.ready { c.px(41, 34, C(0x8A8F9C)) }
}
