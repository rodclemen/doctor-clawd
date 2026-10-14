import Foundation

// Heroes: War Machine, the Maximoff kids, Wakanda and Sakaar. Every one is Clawd in costume: hair, goggles, helmets,
// armour and props drawn over and around the blocky body; where a face shows, it's Clawd's own orange.

let heroes5: [MarvelHero: Persona] = [
    .warMachine: Persona(name: "War Machina", weapon: .blaster, motion: .fly, shot: .bullet, armoured: true,
                  muzzle: (47, 20), handGun: false, headTop: 17, signature: 3.0,
                  draw: drawWarMachine),
    .wiccan: Persona(name: "Wikkan", weapon: .lightning, motion: .fly, magic: Magic(core: C(0xE8F0FF), glow: C(0x6A8AFF)),
                  headTop: 19, signature: 3.0,
                  draw: drawWiccan),
    .speed: Persona(name: "Speedy", weapon: .saber, headTop: 16, signature: 2.6,
                  draw: drawSpeed),
    .quicksilver: Persona(name: "Quicksliver", weapon: .saber, headTop: 20, signature: 2.6,
                  draw: drawQuicksilver),
    .kateBishop: Persona(name: "Kat Bishopp", weapon: .blaster, shot: .arrow, muzzle: (46, 34), handGun: false,
                  headTop: 20, signature: 3.0,
                  draw: drawKateBishop),
    .yelena: Persona(name: "Yelena Belovna", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 20, signature: 2.8,
                  draw: drawYelena),
    .okoye: Persona(name: "Okoya", weapon: .saber, headTop: 23, signature: 3.0,
                  draw: drawOkoye),
    .shuri: Persona(name: "Shuree", weapon: .blaster, shot: .energy(core: C(0xF0E0FF), glow: C(0x9A4AFF)), muzzle: (45, 34),
                  handGun: false, headTop: 17, signature: 3.0,
                  draw: drawShuri),
    .valkyrie: Persona(name: "Valkyria", weapon: .saber, headTop: 20, signature: 3.2,
                  draw: drawValkyrie),
    .korg: Persona(name: "Kork", weapon: .saber, armoured: true, pivot: korgHand, bulk: 3, headTop: 15, signature: 3.0,
                  callout: "Hey man, I'm Kork.",
                  draw: drawKorg),
]

// MARK: - War Machine

/// War Machine: Iron Man's chunkier gunmetal cousin, a dark grey helmet round a silver faceplate with pale eye slits,
/// a dim arc reactor, and the shoulder-mounted gatling over his right shoulder, which is what he shoots with. In
/// flight he leans into it, boots and gauntlets firing. Signature: the gatling spins up, faster and faster, until the
/// barrels glow hot, then winds down and smokes.
private func drawWarMachine(_ c: PixelCanvas, _ p: Pose) {
    let gun = C(0x4E535E), dark = C(0x33363F), light = C(0x8A909C), face = C(0x9EA4AE), faceDark = C(0x6E7480)
    let glow = C(0xDFFBFF)
    let look = Look(body: gun, shade: dark, leg: gun, arm: gun, eye: nil)
    let spin: Double = p.signature.map { habitArc($0, hold: 0.45) } ?? (p.fire != nil ? 1 : 0)
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            for lx in [21, 31] {
                c.rect(lx, 36, 4, 5, gun); c.rect(lx, 39, 4, 2, light); c.rect(lx + 3, 36, 1, 5, dark)
                drawJet(c, x: lx, y: 41, w: 4, t: p.t, seed: lx)
            }
        } else {
            drawLegs(c, look, step: p.step)
            drawBoots(c, light, step: p.step, rows: 2)
        }
        c.oy += p.breathe
        drawBody(c, look)
        c.pattern(17, 20, [
            "......RRRRRRRRRR......",
            "....RRRRRRRRRRRRRR....",
            "...RRRRRRRRRRRRRRRR...",
            "..RRRRRGGGGGGGGRRRRr..",
            "..RRRRGGGGGGGGGGRRRr..",
            ".RRRRGGGGGGGGGGGGRRRr.",
            ".RRRGGGGGGGGGGGGGGRRr.",
            ".RRRGGGGGGGGGGGGGGRRr.",
            ".RRGGGGGGGGGGGGGGGGRr.",
            ".RRGWWWWGGGGGGWWWWGRr.",
            ".RRGGWWWGGGGGGWWWGGRr.",
            ".RRgGGGGGGGGGGGGGGgRr.",
            ".RRRgGGGkkkkkkGGGgRRr.",
            ".RRRRgGGGGGGGGGGgRRRr.",
            ".RRRRRggggggggggRRRRr.",
        ], ["R": gun, "r": dark, "G": face, "g": faceDark, "W": glow, "k": dark])
        // Chest plates, a dim reactor, rivets on the belt.
        c.rect(19, 35, 7, 2, light); c.rect(30, 35, 7, 2, light)
        c.glowLine(28, 36, 28, 36, core: glow, glow: C(0x6FD8FF, 0.6), coreR: 0.8, glowR: 1.6)
        c.rect(18, 37, 20, 1, dark)
        for x in [20, 24, 32, 36] { c.px(x, 37, light) }
        drawGatling(c, spin: spin, t: p.t, lift: p.gunY)
        if let s = p.signature, s > 0.72 { drawBarrelSmoke(c, x: 47, y: 20, (s - 0.72) / 0.28) }
        if p.flying {
            for x in [15, 38] { c.rect(x, 34, 3, 3, gun); c.rect(x, 36, 3, 1, light); drawJet(c, x: x, y: 37, w: 3, t: p.t + 0.3, seed: x) }
            return
        }
        c.rect(15, 33, 1, 3, light)
        c.rect(38, 33, 3, 3, gun); c.rect(40, 33, 1, 3, light)
    }
}

/// The shoulder gatling: a mount on the right shoulder, three barrels pointing forward ending at x 46, row 20.
/// `spin` 0…1: how fast they turn (a still cannon, a blur, red-hot tips).
private func drawGatling(_ c: PixelCanvas, spin: Double, t: Double, lift: Int) {
    let gun = C(0x4E535E), dark = C(0x2A2D35), light = C(0xA4AAB4), mid = C(0x6E7480)
    c.oy += lift
    defer { c.oy -= lift }
    c.rect(31, 21, 6, 2, dark)                    // the mount on the shoulder
    c.rect(34, 18, 5, 5, gun); c.rect(34, 18, 5, 1, light); c.rect(38, 18, 1, 5, dark)
    let phase = Int(t * (3 + spin * 45)) % 3
    for row in 0..<3 {
        let y = 19 + row
        if spin > 0.55 {
            c.rect(39, y, 6, 1, mid)
            c.px(39 + Int(t * 60 + Double(row) * 2) % 6, y, light)
        } else {
            c.rect(39, y, 6, 1, row == phase ? light : dark)
        }
    }
    c.rect(43, 18, 1, 5, dark)                    // the barrel clamp
    c.rect(45, 18, 2, 5, dark)                    // the muzzle ring
    if spin > 0.6 {
        let heat = (spin - 0.6) / 0.4
        for y in 19...21 { c.px(46, y, C(0xFF8A2A).alpha(heat)) }
        c.px(45, 20, C(0xFFD27A).alpha(heat))
        // A whir of air round the barrels.
        if Int(t * 20) % 2 == 0 { c.px(42, 17, C(0xFFFFFF, 0.5 * heat)); c.px(40, 23, C(0xFFFFFF, 0.5 * heat)) }
    }
}

// MARK: - Wiccan

/// Wiccan: the Young Avengers' sorcerer, black curly hair under a red headband whose tails flutter behind, a dark
/// suit with a red chevron and silver clasps, red boots and a long red cape. He flies, cape streaming, and his magic is
/// blue lightning from the raised hand. Signature: he chants (mouth moving), both hands up, and glowing blue runes
/// circle round him.
private func drawWiccan(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3A3A4C), suitDark = C(0x24242E), cape = C(0xC0202A), capeDark = C(0x80141A)
    let hair = C(0x1A1A22), hairLight = C(0x34343F), silver = C(0xC8CCD4), boot = C(0x9A1A22)
    let chant = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    let look = Look(leg: suitDark, arm: suit)
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: cape, edge: capeDark)
            for lx in [21, 30] { c.rect(lx, 36, 4, 5, suitDark); c.rect(lx, 39, 4, 2, boot) }
        } else {
            drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark)
            drawLegs(c, look, step: p.step)
            drawBoots(c, boot, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        let raise = chant > 0.05 ? 3 : p.armRaise
        drawBody(c, look, armLeft: chant > 0.05 ? 3 : 0, armRight: p.flying ? 2 : raise)
        // Headband tails fluttering behind.
        let flap = Int(p.t * 6) % 2
        c.pattern(12, 24, flap == 0 ? ["BBBBBB", ".bBBB.", "..bB.."] : [".BBBBB", "BBBBb.", "bB...."],
                  ["B": cape, "b": capeDark])
        c.pattern(17, 19, [
            ".......HHHHHHHH.......",
            ".....HHHhHHHHhHHH.....",
            "....HHHHHHhHHHHHHH....",
            "...HHhHHHHHHHHHhHHH...",
            "..HHHHHHHHHHHHHHHHHH..",
            "..BBBBBBBBBBBBBBBBBBB.",
            ".BbbbbbbbbbbbbbbbbbbB.",
            ".HHH.H............HHH.",
            ".HH................HH.",
            ".H..................H.",
        ], ["H": hair, "h": hairLight, "B": cape, "b": capeDark])
        // Mouth: chanting.
        if chant > 0.05 {
            let open = Int(p.t * 7) % 2 == 0
            c.rect(27, 32, 2, open ? 2 : 1, ink)
        }
        // Suit: dark tunic, red chevron, silver cape clasps and belt.
        c.rect(18, 33, 20, 5, suit)
        c.rect(18, 33, 2, 2, silver); c.rect(36, 33, 2, 2, silver)
        c.rect(18, 36, 20, 1, cape); c.rect(27, 36, 2, 1, silver)
        c.rect(18, 37, 20, 1, suitDark)
        if chant > 0.05 { drawRunes(c, k: chant, t: p.t) }
    }
}

/// Wiccan's chant: glowing blue runes orbiting him, fading in with `k`.
private func drawRunes(_ c: PixelCanvas, k: Double, t: Double) {
    let glyphs: [[String]] = [
        ["R...R", ".R.R.", "..R..", ".R.R.", "R...R"],
        ["R.R.R", "R.R.R", "RRRRR", "..R..", "..R.."],
        [".RRR.", "R...R", "R.R.R", "R...R", ".RRR."],
        ["RRR..", "..R..", "..RRR", "....R", "...RR"],
        ["..R..", ".RRR.", "R.R.R", "..R..", ".R.R."],
    ]
    let core = C(0xF0F4FF, 0.95), glow = C(0x6A8AFF)
    for i in 0..<5 {
        let a: Double = t * 1.8 + Double(i) * 2 * .pi / 5
        let x: Double = 28 + cos(a) * 19, y: Double = 27 + sin(a) * 11
        let alpha: Double = k * (0.75 + 0.25 * sin(t * 9 + Double(i)))
        c.glowLine(x, y, x, y, core: glow.alpha(alpha * 0.55), glow: glow.alpha(alpha * 0.5), coreR: 2, glowR: 3.6)
        c.pattern(Int(x) - 2, Int(y) - 2, glyphs[i], ["R": core.alpha(alpha)])
    }
}

// MARK: - Speed

/// Speed (Tommy Shepherd): spiky white hair swept back, green goggles strapped over his eyes, a green suit with a
/// white lightning bolt, green fists and white boots. He fights with a blur of punches. Signature: he zips off the
/// edge of the canvas in a green streak and zips straight back in from the other side.
private func drawSpeed(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.05, s < 0.92 else { speedArt(c, p); return }
    let green = C(0x3AD06A), white = C(0xF0F4F8)
    // Out (accelerating to the right), gone, then in from the left (decelerating).
    var dx: Int?
    if s < 0.3 { dx = Int(pow((s - 0.05) / 0.25, 2) * 72) } else if s > 0.55 { dx = -Int(pow(1 - (s - 0.55) / 0.37, 2) * 72) }
    if let dx {
        layer(c, dx: dx) { speedArt($0, p) }
        // The streak he leaves behind him.
        let from = dx > 0 ? 18 : 0, to = dx > 0 ? 18 + dx : 37 + dx
        for (i, y) in [27, 31, 35].enumerated() where to > from {
            c.rect(from, y, to - from, 1, (i == 1 ? white : green).alpha(0.55))
        }
    } else {
        // Gone: a puff of dust where he stood and the air still settling.
        let k = (s - 0.3) / 0.25
        for i in 0..<4 { c.px(20 + i * 5 + Int(k * 3), 42 - Int(k * 3) - i % 2, C(0xD8D0C0).alpha(0.7 * (1 - k))) }
        for (i, y) in [27, 31, 35].enumerated() {
            c.rect(18 + Int(k * 40), y, 54 - Int(k * 40), 1, (i == 1 ? white : green).alpha(0.4 * (1 - k)))
        }
    }
}

private func speedArt(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2A9A4A), greenDark = C(0x1C6A32), hair = C(0xECEEF2), hairShade = C(0xA8ACB8)
    let frame = C(0x23262C), lens = C(0x8AF0A0), boot = C(0xDCE0E8)
    let look = Look(leg: greenDark, arm: green)
    drawLegs(c, look, step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(14, 16, [
        "H.....H.....H...........",
        ".HH....HH....HH.........",
        "..HHH...HHH...HHH.......",
        "...HHHH..HHHH..HHHH.....",
        "..HHHHHHHHHHHHHHHHHH....",
        ".HHHHhHHHHhHHHHhHHHHH...",
        "HHHHHHhHHHHhHHHHhHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHH.",
        "..HHHHhHHHHHHHHHHHhHHHH.",
        "HHHH...hhh.....hhh.HHHH.",
        "..HH................HH..",
    ], ["H": hair, "h": hairShade])
    // Goggles: dark frames, green lenses, strap round the head; his eyes behind.
    c.pattern(18, 28, [
        "..FFFFFF....FFFFFF..",
        "FFFLKKLFFFFFFLKKLFFF",
        "..FLKKLF....FLKKLF..",
        "..FFFFFF....FFFFFF..",
    ], ["F": frame, "L": lens, "K": C(0x1E5A30)])
    c.rect(26, 33, 4, 1, clawdShade)                       // a grin
    // Suit: green with the white bolt.
    c.rect(18, 34, 20, 4, green)
    c.pattern(25, 34, ["..WWW", ".WWW.", "WWWWW", "..WW."], ["W": boot])
    c.rect(18, 37, 20, 1, greenDark)
    c.rect(15, 33, 3, 3, green)
    if let a = p.melee {
        drawFlurry(c, angle: a, trail: p.trail, t: p.t, arm: green, fist: green, blur: C(0x6AF09A))
    } else {
        c.rect(38, 33, 3, 3, green); c.px(40, 33, greenDark)
    }
}

// MARK: - Quicksilver

/// Quicksilver: silver-white hair swept hard back by the wind, a blue suit with the white lightning bolt across the
/// chest, blue fists and dark boots. He fights with a blur of punches. Signature: he dashes forward and back in a
/// blink, leaving a trail of fading blue afterimages.
private func drawQuicksilver(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { quicksilverArt(c, p); return }
    // Where he is at moment `u` of the move: out fast, a beat there, back fast.
    func pos(_ u: Double) -> Int {
        if u < 0.12 || u > 0.78 { return 0 }
        if u < 0.24 { return Int(((u - 0.12) / 0.12) * 12) }
        if u < 0.62 { return 12 }
        return Int((1 - (u - 0.62) / 0.16) * 12)
    }
    let now = pos(s)
    var seen: Set<Int> = [now]
    for k in stride(from: 5, through: 1, by: -1) {
        let x = pos(s - Double(k) * 0.03)
        guard !seen.contains(x) else { continue }
        seen.insert(x)
        layer(c, alpha: 0.5 / Double(k) + 0.1, dx: x) { quicksilverArt($0, p, ghost: true) }
    }
    layer(c, dx: now) { quicksilverArt($0, p) }
}

private func quicksilverArt(_ c: PixelCanvas, _ p: Pose, ghost: Bool = false) {
    let blue = ghost ? C(0x6AA0FF) : C(0x2A5AC8), blueDark = ghost ? C(0x4A7AE0) : C(0x1C3E8A)
    let hair = C(0xD4D8E0), hairShade = C(0x8A90A0), bolt = C(0xEEF2F8), boot = C(0x23262C)
    let look = Look(leg: blueDark, arm: blue)
    drawLegs(c, look, step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(10, 20, [
        "...............HHHHHHHH.....",
        "........HHHHHHHHHHHHHHHHH...",
        "HHHHHHHHHHHHHhHHHHHHHHHHHH..",
        "....HHHHHHHHHHHHHHHHhHHHHHH.",
        ".HHHHHHHhHHHHHHHHHHHHHHHHHH.",
        "......HHHHHHHHhHHHHHHHHHHHH.",
        "...HHHHHHHH......hhhhhHHHHH.",
        "........HH.............HHH..",
    ], ["H": hair, "h": hairShade])
    c.rect(26, 33, 4, 1, clawdShade)
    // Blue suit, white bolt from the left shoulder down across the chest.
    c.rect(18, 33, 20, 5, blue)
    c.pattern(19, 33, ["WWWW..........", "..WWWWW.......", ".....WWWWWW...", "........WWWWWW"], ["W": bolt])
    c.rect(18, 37, 20, 1, blueDark)
    c.rect(15, 33, 3, 3, blue)
    if let a = p.melee {
        drawFlurry(c, angle: a, trail: p.trail, t: p.t, arm: blue, fist: blue, blur: C(0x8AB8FF))
    } else {
        c.rect(38, 33, 3, 3, blue); c.px(40, 33, blueDark)
    }
}

/// A speedster's punches: the arm out along `angle` with a fist on the end, faint fists where the swing just was,
/// a couple of blurred extra fists flickering round it and speed lines behind.
private func drawFlurry(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double, arm: Px, fist: Px, blur: Px) {
    let h = Sprite.hand
    let k = Int(t * 24)
    for j in 0..<2 {
        let a: Double = angle + (noise(k * 3 + j) - 0.5) * 60
        let e = along(a, 4 + noise(k * 5 + j) * 4)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, blur.alpha(0.4))
    }
    for (i, a) in trail.enumerated() {
        let e = along(a, 6)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, blur.alpha(0.4 / Double(i + 1)))
    }
    let e = along(angle, 6)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
    let r: Double = angle * .pi / 180
    let ux = cos(r), uy = sin(r)
    for j in [-1.0, 1.0] {
        let sx: Double = e.x - ux * 3 - uy * 2.5 * j, sy: Double = e.y - uy * 3 + ux * 2.5 * j
        bar(c, sx, sy, sx - ux * 3, sy - uy * 3, C(0xFFFFFF, 0.6), 0.4)
    }
}

// MARK: - Kate Bishop

/// Kate Bishop: long straight black hair, a purple jacket over a black top, a purple quiver on her back and a
/// purple recurve bow, an arrow nocked when she means business. Signature: a trick arrow, she draws one with a
/// glowing purple head, lets it fly up and away, and it bursts into purple and pink fireworks.
private func drawKateBishop(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x7A34B0), purpleDark = C(0x4E1C72), lavender = C(0xB890E0), top = C(0x1E1A24)
    let hair = C(0x1E1820), hairLight = C(0x3E3248)
    let look = Look(leg: top, arm: purple)
    let sig = p.signature
    c.oy += p.breathe
    // Quiver behind the left shoulder.
    c.pattern(12, 19, [
        "P.P.....",
        "PwPw....",
        ".wPwP...",
        "..QQQQ..",
        "..QQQQ..",
        "...QQQq.",
        "...QQQQ.",
        "....QQQQ",
        "....QQQq",
        ".....QQq",
    ], ["P": C(0xA05AE0), "w": C(0xE8E0D0), "Q": purpleDark, "q": C(0x34124E)])
    c.oy -= p.breathe
    drawLegs(c, look, step: p.step)
    drawBoots(c, purpleDark, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(16, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHhHHHHHHHHHHHHHHhHH..",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHh.....hHHHHHH.",
        ".HHHHh...............HH.",
        ".HHHH................HH.",
        ".HHH.................HH.",
        "HHHH.................HHH",
        "HHHh.................hHH",
        "HHH...................HH",
        "HHH...................HH",
        "Hh.....................H",
    ], ["H": hair, "h": hairLight])
    // Purple jacket: a zip, a lavender stripe down each side, a dark belt.
    c.rect(18, 33, 20, 5, purple)
    c.rect(28, 33, 1, 4, purpleDark)
    c.rect(20, 34, 1, 3, lavender); c.rect(35, 34, 1, 3, lavender)
    c.rect(18, 37, 20, 1, top)
    c.rect(15, 33, 3, 3, purple)

    // The bow: drawn and held for the trick arrow, or the usual shooting and aiming.
    let drawing = sig.map { $0 > 0.06 && $0 < 0.42 } ?? false
    var pull = 0
    if let s = sig, drawing { pull = Int((4 * min(1, (s - 0.06) / 0.14)).rounded()) }
    let firing = p.fire.map { frac($0.t / blasterPeriod) < 0.45 } ?? false
    if let f = p.fire, frac(f.t / blasterPeriod) > 0.6 { pull = Int(((frac(f.t / blasterPeriod) - 0.6) / 0.4 * 3).rounded()) }
    let raise = drawing ? -1 : seatedPose ? -3 : 0
    c.oy += p.gunY + raise
    drawBow(c, pull: pull, limb: C(0x34124E), grip: lavender)
    let nocked = drawing || p.ready || (p.fire != nil && !firing)
    if nocked {
        let tail = 41 - pull
        c.rect(tail, 34, 47 - tail, 1, C(0x8A6A3A))
        if drawing {
            c.glowLine(47.5, 34.5, 47.5, 34.5, core: C(0xF4E0FF), glow: C(0xB04AFF), coreR: 0.8, glowR: 2)
        } else {
            c.px(47, 34, C(0xC8CCD4)); c.px(48, 34, C(0xE8ECF4))
        }
        c.px(tail, 33, purple); c.px(tail, 35, purple)
    }
    c.rect(38 - pull, 33, 3, 3, purple)
    c.oy -= p.gunY + raise
    if let s = sig, s >= 0.42 { drawTrickArrow(c, s: s, t: p.t) }
}

/// Kate's trick arrow after it leaves the string (`s` 0.42…1 of the signature): up and away, then a firework burst.
private func drawTrickArrow(_ c: PixelCanvas, s: Double, t: Double) {
    let start = (x: 47.0, y: 34.0), burst = (x: 62.0, y: 22.0)
    if s < 0.56 {
        let f = (s - 0.42) / 0.14
        let head = (x: start.x + (burst.x - start.x) * f, y: start.y + (burst.y - start.y) * f)
        drawProjectile(c, .arrow, from: start, head: head, t: t)
        c.glowLine(head.x, head.y, head.x, head.y, core: C(0xF4E0FF), glow: C(0xB04AFF), coreR: 0.6, glowR: 1.8)
        return
    }
    let k = (s - 0.56) / 0.44
    if k < 0.2 { c.glowLine(burst.x, burst.y, burst.x, burst.y, core: white, glow: C(0xD07AFF), coreR: 1.2, glowR: 4 * (1 - k)) }
    let cols = [C(0xC07AFF), C(0xFF7AD0), C(0xFFD25A)]
    let r: Double = 2 + sqrt(k) * 7
    for i in 0..<12 {
        let a: Double = Double(i) * .pi / 6 + 0.2
        let x = burst.x + cos(a) * r, y = burst.y + sin(a) * r + k * k * 5
        let col = cols[i % 3].alpha(1 - k * k)
        c.px(Int(x), Int(y), col)
        if k < 0.6 { c.px(Int(x - cos(a) * 1.5), Int(y - sin(a) * 1.5), col.alpha(0.5)) }
    }
}

/// A recurve bow gripped at the hand; `pull` draws the string back that many pixels.
private func drawBow(_ c: PixelCanvas, pull: Int, limb: Px, grip: Px) {
    let string = C(0xE0E0E8)
    for y in 25...43 {
        let d = abs(y - 34)
        let x = d <= 2 ? 44 : d <= 5 ? 43 : d <= 7 ? 42 : 41
        c.px(x, y, d <= 1 ? grip : limb)
        if d == 9 { c.px(x + 1, y, limb) }
    }
    for y in 26...42 {
        let d = Double(abs(y - 34)) / 8
        c.px(41 - Int((Double(pull) * (1 - d)).rounded()), y, string)
    }
}

// MARK: - Yelena Belova

/// Yelena Belova: blonde hair pulled back into a long braid down her back, an off-white tactical vest full of
/// pockets over a dark grey shirt, dark trousers and boots, and a pistol. Signature: the pistol goes in its
/// holster, and she flips a knife up into the air, end over end, and catches it.
private func drawYelena(_ c: PixelCanvas, _ p: Pose) {
    let vest = C(0xDCDAD0), vestShade = C(0xAAA89C), vestDark = C(0x7A786E), shirt = C(0x40444C), trousers = C(0x2C2F36)
    let hair = C(0xE8CC80), hairDark = C(0xB8984A)
    let look = Look(leg: trousers, arm: shirt)
    drawLegs(c, look, step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 2)
    c.oy += p.breathe
    // The braid, hanging down her back.
    c.pattern(12, 27, ["HH.", "hHH", ".Hh", "hH.", ".Hh", "hH.", ".Hh", ".h."], ["H": hair, "h": hairDark])
    drawBody(c, look)
    c.pattern(16, 20, [
        "......HHHHHHHHHH........",
        "....HHHHHHHHHHHHHHH.....",
        "...HHHHhHHHHHHhHHHHH....",
        "..HHHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHH.....hhHHHHHHHH.",
        ".HHH................HHH.",
        ".HHH.................HH.",
        "..H..................H..",
    ], ["H": hair, "h": hairDark])
    // Vest: the shirt collar, a zip, a big pocket each side.
    c.rect(18, 33, 20, 5, vest)
    c.rect(28, 33, 1, 4, vestDark)
    c.rect(37, 33, 1, 5, vestShade)
    for x in [20, 32] { c.rect(x, 34, 4, 3, vestShade); c.px(x + 1, 35, vestDark) }
    c.rect(18, 37, 20, 1, vestDark)
    c.rect(15, 33, 3, 3, shirt)

    let sig = p.signature.flatMap { $0 > 0.08 && $0 < 0.94 ? $0 : nil }
    guard let s = sig else {
        c.oy += p.gunY
        drawPistol(c, x: 40, y: 31)
        c.rect(38, 33, 2, 3, shirt)
        return
    }
    c.rect(19, 37, 3, 1, C(0x2A2A30))                      // the pistol, holstered
    // The knife: up end over end from 0.12 to 0.86, then caught.
    let u = (s - 0.12) / 0.74
    if u > 0 && u < 1 {
        let y: Double = 30.5 - 20 * sin(u * .pi)
        drawKnife(c, at: (42.5, y), angle: -90 + 720 * u)
        c.rect(38, 30, 3, 3, shirt)
    } else {
        c.rect(38, 30, 3, 3, shirt)
        drawKnife(c, at: (40.5, 29.5), angle: -90)
    }
}

/// A combat knife, its grip at `at`, blade out along `angle`.
private func drawKnife(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double) {
    prop(c, at: at, angle: angle) { s in
        s.rect(17, 20, 3, 1, C(0x23232A))
        s.rect(20, 19, 1, 3, C(0x4A4A55))
        s.rect(21, 19, 4, 1, C(0xE8ECF4))
        s.rect(21, 20, 5, 1, C(0xA4AAB4))
        s.px(26, 20, C(0xE8ECF4))
    }
}

// MARK: - Okoye

/// Okoye: bald, with the tattoo across her scalp, gold neck rings, the red Dora Milaje armour with gold chevrons and
/// a gold-shouldered arm, and her vibranium spear, held upright at her side when she isn't fighting with it.
/// Signature: she twirls the spear twice round her hand and plants it, butt down, with a thump of dust.
private func drawOkoye(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB0222C), redDark = C(0x701418), gold = C(0xE0B040), goldDark = C(0xA8802A), tattoo = C(0x4A2418)
    let look = Look(leg: redDark, arm: red)
    drawLegs(c, look, step: p.step)
    drawBoots(c, gold, step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, look)
    // The bald crown and its tattoo.
    c.pattern(18, 23, [
        ".....OOTOTOTOTOO....",
        "..OOOTOOOOOOOOOTOOs.",
        "OOOOOOOOOOOOOOOOOOOs",
    ], ["O": clawdOrange, "T": tattoo, "s": clawdShade])
    c.rect(26, 33, 4, 1, clawdShade)
    c.px(18, 31, gold); c.px(37, 31, gold)                  // earrings
    // Neck rings and the armour.
    c.pattern(18, 32, [
        "...GgGgGgGgGgGgGg...",
        "RRRGGGGGGGGGGGGGGRRR",
        "RRGRRRRGGRRGGRRRRGRR",
        "RRRGRRGRRRRRRGRRGRRR",
        "RRRRGGRRRRRRRRGGRRRR",
        "rrrrrrrrrrrrrrrrrrrr",
    ], ["R": red, "r": redDark, "G": gold, "g": goldDark])
    c.rect(15, 33, 3, 3, red); c.rect(15, 33, 3, 1, gold)

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawSpear(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawSpear(c, at: Sprite.hand, angle: a)
        c.rect(38, 33, 3, 3, red); c.rect(38, 33, 3, 1, gold)
        return
    }
    let grip = (x: 41.5, y: seatedPose ? 28.5 : 31.5)
    if let s = p.signature, s > 0.08, s < 0.96 {
        if s < 0.7 {
            // Two turns round the hand, fastest in the middle.
            let k = (s - 0.08) / 0.62
            let a: Double = -90 - 720 * (0.5 - 0.5 * cos(k * .pi))
            for i in 1...2 { drawSpear(c, at: grip, angle: a + Double(i) * 24, alpha: 0.3 / Double(i)) }
            drawSpear(c, at: grip, angle: a)
        } else {
            // Lifted, then planted with a thump.
            let up = s < 0.76 ? 3.0 : 0.0
            drawSpear(c, at: (grip.x, grip.y - up), angle: -90)
            if s >= 0.76 {
                let k = (s - 0.76) / 0.2
                for i in 0..<3 {
                    let d = 2 + Double(i) * 1.5 + k * 4
                    let col = C(0xD8CCB8).alpha(0.8 * (1 - k))
                    c.px(Int(41 - d), 43 - i % 2, col); c.px(Int(42 + d), 43 - i % 2, col)
                }
            }
        }
    } else {
        drawSpear(c, at: grip, angle: -90)
    }
    c.rect(39, Int(grip.y) - 2, 3, 3, red); c.rect(39, Int(grip.y) - 2, 3, 1, gold)
}

/// Okoye's spear: a dark vibranium shaft with a red grip, a gold collar and a long silver blade, held at `at`,
/// blade out along `angle`.
private func drawSpear(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.rect(11, 20, 22, 1, C(0x3A3A48))
        s.rect(18, 20, 5, 1, C(0x9A1A22))
        s.px(10, 20, C(0xE0B040))
        s.rect(32, 19, 1, 3, C(0xE0B040))
        s.pattern(33, 19, ["LLLL..", "SSSSSW", "dddd.."], ["L": C(0xE8ECF4), "S": C(0xB8BEC8), "d": C(0x7A808C), "W": white])
    }
}

// MARK: - Shuri

/// Shuri: braided hair up in a bun, a black outfit with a purple vibranium triangle pattern and a silver pendant,
/// kimoyo beads on her wrist. To fight she wears a panther-head gauntlet that fires purple sonic blasts from its
/// mouth. Signature: she lifts her wrist and the kimoyo beads project a purple hologram, a panther and a readout.
private func drawShuri(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x22222C), purple = C(0x8A5AE0), silver = C(0xC8CCD4)
    let hair = C(0x1A1A20), hairLight = C(0x3A3440)
    let look = Look(leg: suit, arm: suit)
    drawLegs(c, look, step: p.step)
    drawBoots(c, C(0x5A3AA0), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(17, 16, [
        "........HHHHHH........",
        ".......HHhHHhHH.......",
        ".......HhHHhHHH.......",
        "........HHHHHH........",
        "......HHHHHHHHHH......",
        "....HHhHHhHHhHHhHH....",
        "...HHhHHhHHhHHhHHhH...",
        "..HhHHhHHhHHhHHhHHhH..",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
    ], ["H": hair, "h": hairLight])
    c.rect(26, 33, 4, 1, clawdShade)
    // Black top with a silver pendant and the purple triangle pattern.
    c.rect(18, 33, 20, 5, suit)
    c.rect(18, 33, 20, 1, C(0x16161B)); c.rect(27, 34, 2, 1, silver)
    c.pattern(19, 35, ["P.P.P.P.P.P.P.P.P.", ".P.P.P.P.P.P.P.P.P"].map { $0 }, ["P": purple])
    c.rect(18, 37, 20, 1, C(0x16161B))
    c.rect(15, 33, 3, 3, suit)

    let sig = p.signature.flatMap { $0 > 0.06 && $0 < 0.95 ? $0 : nil }
    if let s = sig {
        // Wrist raised, beads glowing, the hologram flickering above.
        c.rect(37, 29, 3, 3, suit)
        drawBeads(c, x: 36, y: 31, lit: true, t: p.t)
        let k = habitArc((s - 0.06) / 0.89, hold: 0.7)
        drawHologram(c, k: k, t: p.t)
        return
    }
    c.oy += p.gunY
    if p.fire != nil || p.ready || p.cheering || p.hit {
        drawPantherGauntlet(c, glow: p.fire != nil || p.ready)
    } else {
        c.rect(38, 33, 3, 3, suit)
        drawBeads(c, x: 36, y: 35, lit: false, t: p.t)
    }
}

/// Kimoyo beads round the wrist: a row of dark beads, one glowing.
private func drawBeads(_ c: PixelCanvas, x: Int, y: Int, lit: Bool, t: Double) {
    for i in 0..<4 { c.px(x + i, y, i % 2 == 0 ? C(0x5A5A6A) : C(0x2A2A34)) }
    c.px(x + 1, y, lit ? C(0xC8A0FF) : C(0x7A5AC0))
}

/// The panther-head gauntlet on the right hand: ears, a purple eye and the glowing mouth at (44, 34).
private func drawPantherGauntlet(_ c: PixelCanvas, glow: Bool) {
    c.pattern(37, 31, [
        "..k..k.",
        ".KKKKKK",
        "KKKPKKKK",
        "KKKKKKK.",
        "KKKKKK..",
    ], ["K": C(0x2A2A34), "k": C(0x3A3A48), "P": C(0xB08AFF)])
    c.rect(37, 33, 1, 3, C(0x5A5A6A))
    if glow { c.glowLine(44.5, 34.5, 44.5, 34.5, core: C(0xF0E0FF), glow: C(0x9A4AFF), coreR: 0.6, glowR: 1.8) }
}

/// Shuri's hologram, projected up from her wrist: a cone of light, a panel with a panther head and a little bar
/// readout, a scan line running down it. `k` fades it in and out.
private func drawHologram(_ c: PixelCanvas, k: Double, t: Double) {
    let flick: Double = k * (0.85 + 0.15 * noise(Int(t * 20)))
    let edge = C(0xB08AFF).alpha(0.75 * flick), fill = C(0x8A5AFF).alpha(0.2 * flick), art = C(0xE8D8FF).alpha(0.85 * flick)
    let x0 = 33, y0 = 10, w = 16, h = 11
    // The beam.
    c.glowLine(37.5, 30.5, Double(x0) + 1, Double(y0 + h), core: edge.alpha(0.4), glow: C(0, 0), coreR: 0.4, glowR: 0.5)
    c.glowLine(38.5, 30.5, Double(x0 + w) - 1, Double(y0 + h), core: edge.alpha(0.4), glow: C(0, 0), coreR: 0.4, glowR: 0.5)
    c.rect(x0, y0, w, h, fill)
    c.rect(x0, y0, w, 1, edge); c.rect(x0, y0 + h - 1, w, 1, edge)
    c.rect(x0, y0, 1, h, edge); c.rect(x0 + w - 1, y0, 1, h, edge)
    c.pattern(x0 + 2, y0 + 2, [
        "A...A",
        "AAAAA",
        "A.A.A",
        "AAAAA",
        ".AAA.",
    ], ["A": art])
    for (i, hgt) in [3, 5, 2, 4].enumerated() {
        let bh = max(1, Int((Double(hgt) * (0.6 + 0.4 * sin(t * 5 + Double(i)))).rounded()))
        c.rect(x0 + 9 + i * 1, y0 + h - 2 - bh, 1, bh, art)
    }
    let scan = y0 + 1 + Int(t * 10) % (h - 2)
    c.rect(x0 + 1, scan, w - 2, 1, C(0xE8D8FF).alpha(0.35 * flick))
}

// MARK: - Valkyrie

/// Valkyrie: long dark hair with braids, the white war paint streaked across her eyes, the silver-white Valkyrior
/// armour and a long blue cape, and Dragonfang, a long slim sword, sheathed on her back with its hilt over her
/// shoulder. Signature: she pulls out a bottle, tips it back for a long swig and tosses it away over her shoulder.
private func drawValkyrie(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0xD4D8E0), armourShade = C(0x9AA0AC), leather = C(0x2E2A36), cape = C(0x2A4AA8), capeDark = C(0x1A2E70)
    let hair = C(0x2A1C18), hairLight = C(0x4A3428), paint = C(0xF0F0F0), gold = C(0xC8A040)
    let look = Look(leg: leather, arm: armour)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark)
    drawLegs(c, look, step: p.step)
    drawBoots(c, armourShade, step: p.step, rows: 3)
    c.oy += p.breathe
    // Dragonfang's hilt over her shoulder, when it's sheathed.
    if p.melee == nil {
        bar(c, 17, 23, 24, 30, C(0x4A3A2A), 1)
        c.pattern(11, 17, ["G.....", ".LL...", "..LL..", "...LL.", "..GGGG", "....GG"], ["G": gold, "L": leather])
    }
    drawBody(c, look)
    c.pattern(16, 20, [
        "......HHHHHHHHHH........",
        "....HHHHHHHHHHHHHH......",
        "...HHHHHHHhHHHHHHHH.....",
        "..HHhHHHHHHHHHHhHHHH....",
        "..HHHHHHHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHH...........HHHHH..",
        ".HHHh..............HHH..",
        ".HHH................HH..",
        "HHHh....................",
        "HhH.....................",
        "HHh.....................",
        "HH......................",
        "Hh......................",
        ".H......................",
    ], ["H": hair, "h": hairLight])
    // War paint across the eyes, the eyes over it.
    c.rect(20, 29, 16, 1, paint)
    c.px(21, 30, paint); c.px(34, 30, paint)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    // Armour: a breastplate with a centre ridge and a gold boss, a leather belt.
    c.rect(18, 33, 20, 5, armour)
    c.rect(18, 33, 20, 1, armourShade)
    c.rect(28, 34, 1, 3, armourShade)
    c.rect(27, 35, 3, 1, gold)
    c.rect(18, 37, 20, 1, leather); c.rect(27, 37, 2, 1, gold)
    c.rect(15, 33, 3, 3, armour)

    if let a = p.melee {
        drawSword(c, angle: a, trail: p.trail)
        c.rect(38, 33, 3, 3, armour)
        return
    }
    guard let s = p.signature, s > 0.1, s < 0.94 else {
        c.rect(38, 33, 3, 3, armour); c.px(40, 33, armourShade)
        return
    }
    // The bottle: out, up to her lips and tipped back, then flung over her shoulder.
    if s < 0.24 {
        c.rect(37, 31, 3, 3, armour)
        drawBottle(c, at: (38.5, 31.5), angle: -90)
    } else if s < 0.72 {
        let k = (s - 0.24) / 0.48
        let tilt: Double = 120 + 40 * min(1, k * 3)
        drawBottle(c, at: (36.5, 27.5), angle: tilt)
        c.rect(35, 26, 3, 3, armour)
        if Int(p.t * 8) % 2 == 0 { c.px(30, 33, C(0x8A5A2A)) }          // a gulp
    } else {
        let k = (s - 0.72) / 0.22
        let x: Double = 36 - 30 * k, y: Double = 26 - 22 * sin(k * .pi * 0.8)
        drawBottle(c, at: (x, y), angle: -90 - 900 * k)
        c.rect(38, 28, 3, 3, armour)
    }
}

/// Dragonfang: a long slim silver blade, gold guard, dark grip, swung from the hand at `angle`.
private func drawSword(_ c: PixelCanvas, angle: Double, trail: [Double]) {
    for (i, a) in trail.enumerated() {
        let s = along(a, 4), e = along(a, 20)
        c.glowLine(s.x, s.y, e.x, e.y, core: C(0xC8D8FF), glow: C(0x8AA8FF), coreR: 0.4, glowR: 1.4, strength: 0.4 / Double(i + 1))
    }
    prop(c, at: Sprite.hand, angle: angle) { s in
        s.rect(16, 20, 4, 1, C(0x2E2A36))
        s.px(15, 20, C(0xC8A040))
        s.rect(20, 18, 1, 5, C(0xC8A040))
        s.rect(21, 19, 15, 1, C(0xEEF2F8))
        s.rect(21, 20, 16, 1, C(0xA8B0BC))
        s.px(37, 20, C(0xEEF2F8))
    }
}

/// A brown glass bottle held at `at`, its neck out along `angle`.
private func drawBottle(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double) {
    prop(c, at: at, angle: angle) { s in
        let glass = C(0x2E7A3A), shine = C(0x7AD08A)
        s.rect(13, 18, 7, 5, glass)
        s.rect(13, 18, 7, 1, shine)
        s.rect(15, 19, 3, 3, C(0xE8D8A8))
        s.rect(20, 19, 1, 3, glass)
        s.rect(21, 20, 3, 1, glass)
        s.px(24, 20, C(0xC8A040))
    }
}

// MARK: - Korg

private let korgHand = (x: 43.5, y: 33.5)

/// Korg: a big, blocky Kronan made of brown rock slabs, with small kind eyes and a gentle smile, a blue-grey cloth
/// sash and skirt, thick rock legs and a little trident. Signature: a friendly wave, then he holds out a pebble on
/// his palm, offering it to you.
private func drawKorg(_ c: PixelCanvas, _ p: Pose) {
    let rock = C(0xA07A5E), light = C(0xC09878), dark = C(0x6E5240), crack = C(0x4A3628)
    let cloth = C(0x5A6A82), clothDark = C(0x3E4A5E)
    // Thick legs.
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, rock); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 37, 3, lifted ? 6 : 7, rock)
        c.rect(lx + 2, 38, 1, lifted ? 5 : 6, dark)
        c.px(lx, 40, crack)
    }
    c.oy += p.breathe
    let sig = p.signature.flatMap { $0 > 0.06 && $0 < 0.94 ? $0 : nil }
    // The left arm hangs at his side.
    c.rect(11, 27, 5, 10, rock); c.rect(11, 27, 1, 10, dark); c.px(13, 31, crack); c.rect(11, 36, 5, 1, dark)
    // The rock body: a broad torso with a Clawd-square head of rock on it, lit from the top left.
    let headInsets: [Int] = [4, 2, 1]
    for y in 15...25 {
        let i = y - 15, inset = i < headInsets.count ? headInsets[i] : 0
        c.rect(18 + inset, y, 20 - 2 * inset, 1, rock)
        c.rect(36 - inset, y, 2, 1, dark)
    }
    let torsoInsets: [Int] = [2, 1]
    for y in 24...38 {
        let i = y - 24, inset = i < torsoInsets.count ? torsoInsets[i] : 0
        c.rect(15 + inset, y, 26 - 2 * inset, 1, rock)
        c.rect(39 - inset, y, 2, 1, dark)
    }
    c.rect(23, 15, 10, 1, light); c.rect(20, 16, 5, 1, light); c.rect(18, 18, 1, 5, light)
    c.rect(17, 24, 1, 1, light); c.rect(16, 25, 1, 4, light)
    // Cracks between the slabs.
    c.rect(19, 25, 17, 1, crack)
    for (x, y) in [(28, 15), (28, 16), (27, 17), (33, 16), (34, 17), (35, 17), (19, 22), (20, 22),
                   (28, 26), (28, 27), (29, 28), (29, 29), (17, 30), (16, 31), (38, 29), (39, 30), (40, 30)] as [(Int, Int)] {
        c.px(x, y, crack)
    }
    // Brow, small kind eyes, a smile.
    c.rect(21, 18, 6, 1, dark); c.rect(30, 18, 6, 1, dark)
    c.rect(23, 20, 2, 2, ink); c.rect(32, 20, 2, 2, ink)
    c.px(23, 20, C(0x8AB8E0)); c.px(32, 20, C(0x8AB8E0))
    c.rect(25, 23, 7, 1, crack); c.px(24, 22, crack); c.px(32, 22, crack)
    if sig != nil { c.rect(26, 24, 5, 1, crack) }
    // Cloth: a sash over the left shoulder and a skirt.
    for i in 0..<8 { c.rect(17 + i * 2, 27 + i, 3, 2, cloth) }
    c.rect(15, 34, 26, 5, cloth)
    for x in [18, 23, 28, 33, 38] { c.rect(x, 35, 1, 4, clothDark) }
    c.rect(15, 38, 26, 1, clothDark)

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawTrident(c, at: korgHand, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawTrident(c, at: korgHand, angle: a)
        c.rect(41, 32, 4, 4, rock); c.rect(41, 35, 4, 1, dark)
        return
    }
    if let s = sig {
        drawTrident(c, at: (49.5, seatedPose ? 26.5 : 29.5), angle: -90)   // leant beside him
        if s < 0.5 {
            // A big friendly wave.
            let wave = Int((sin(s * 40) * 2).rounded())
            c.rect(41, 18, 4, 12, rock); c.rect(41, 18, 1, 12, crack); c.rect(44, 18, 1, 12, dark)
            c.rect(40 + wave, 12, 6, 6, rock); c.rect(40 + wave, 17, 6, 1, dark); c.rect(41 + wave, 13, 2, 1, light)
        } else {
            // Palm out, a pebble on it.
            c.rect(41, 31, 7, 3, rock); c.rect(41, 31, 1, 3, crack); c.rect(41, 33, 7, 1, dark)
            c.pattern(43, 27, [".PPP.", "PPPPp", "PPPpp", ".ppp."], ["P": C(0x9A9AA4), "p": C(0x6A6A74)])
            c.px(44, 28, C(0xD8D8E0))
            if Int(p.t * 4) % 2 == 0 { twinkle(c, 49, 25) }
        }
        return
    }
    drawTrident(c, at: (43.5, seatedPose ? 26.5 : 29.5), angle: -90)
    c.rect(41, Int(seatedPose ? 27 : 30), 4, 4, rock); c.rect(41, Int(seatedPose ? 30 : 33), 4, 1, dark)
}

/// Korg's little trident: a short wooden shaft, a crossbar and three prongs, held at `at`, prongs out along `angle`.
private func drawTrident(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let wood = C(0x6A4A30), metal = C(0x8A909C), tip = C(0xD4D8E0)
        s.rect(10, 20, 22, 1, wood)
        s.rect(31, 17, 1, 7, metal)
        for y in [17, 20, 23] { s.rect(32, y, 4, 1, metal); s.px(36, y, tip) }
    }
}

// MARK: - Shared helpers

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` (the hand) along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A flickering jet flame pointing down from (`x`, `y`), `w` wide.
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int) {
    let len = 2 + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, C(0xFF9A2A, 0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, C(0xFFE27A))
    c.rect(x, y, w, 1, C(0xF4FCFF))
}

/// A cape streaming out behind (to the left) in flight.
private func drawFlyingCape(_ c: PixelCanvas, t: Double, color: Px, edge: Px) {
    for x in 3...20 {
        let k = Double(20 - x) / 17
        let mid = 29 + k * 4 + sin(t * 9 - k * 5) * k * 1.6
        let half = 3 + k * 2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, color)
        c.px(x, top, edge); c.px(x, bottom, edge)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`, and
/// leaning forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = dx + (lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0)
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i).alpha(alpha))
        }
    }
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

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int) {
    c.px(x, y, white)
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] as [(Int, Int)] { c.px(x + dx, y + dy, C(0xFFFFFF, 0.6)) }
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}
