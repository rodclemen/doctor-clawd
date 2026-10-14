import Foundation

// Heroes: the Fantastic Four, the street and the rest.

let heroes4: [MarvelHero: Persona] = [
    .humanTorch: Persona(name: "Human Blowtorch", weapon: .blaster, motion: .fly, shot: .fire, muzzle: (44, 32), handGun: false,
                  headTop: 15, signature: 3.2, callout: "Fire it up!",
                  draw: drawHumanTorch),
    .thing: Persona(name: "The Thingamajig", weapon: .saber, armoured: true, pivot: (41.5, 33.5), bulk: 2, headTop: 22, signature: 2.6,
                  callout: "It's thumpin' time!",
                  draw: drawThing),
    .mrFantastic: Persona(name: "Mr. Fanclawdstic", weapon: .saber, headTop: 21, signature: 2.8,
                  draw: drawMrFantastic),
    .invisibleWoman: Persona(name: "Invisibelle", weapon: .lightning, magic: Magic(core: C(0xE8F8FF), glow: C(0x6AC8FF), jagged: false),
                  pivot: (41.5, 34.5), headTop: 20, signature: 3.0,
                  draw: drawInvisibleWoman),
    .silverSurfer: Persona(name: "Silver Server", weapon: .lightning, motion: .fly, magic: Magic(core: C(0xFFFFFF), glow: C(0xA8E8FF), jagged: false), armoured: true,
                  canSit: false, pivot: (41.5, 31.5), headTop: 20, signature: 2.6,
                  draw: drawSilverSurfer),
    .daredevil: Persona(name: "Daredemon", weapon: .saber, headTop: 23, signature: 2.8,
                  draw: drawDaredevil),
    .deadpool: Persona(name: "Deadpond", weapon: .saber, headTop: 19, signature: 3.4, callout: "Maximum effortness!",
                  draw: drawDeadpool),
    .shangChi: Persona(name: "Shang-Chee", weapon: .saber, headTop: 22, signature: 3.0,
                  draw: drawShangChi),
    .msMarvel: Persona(name: "Ms. Marvelous", weapon: .saber, headTop: 21, signature: 2.6,
                  draw: drawMsMarvel),
    .moonKnight: Persona(name: "Moon Night", weapon: .saber, headTop: 19, signature: 2.6,
                  draw: drawMoonKnight),
    .ghostRider: Persona(name: "Ghost Biker", weapon: .saber, headTop: 14, signature: 2.6,
                  draw: drawGhostRider),
]

// MARK: - Shared bits

private let hand = Sprite.hand
private let none = C(0, 0)
private let ffBlue = C(0x2E5BC8), ffBlueShade = C(0x1E3E90)

/// A point `d` pixels out from `h` at `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h` (sticks, blades, arms).
private func bar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
                 r: Double = 0.8) {
    let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
    c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: none, coreR: r, glowR: r + 0.1)
}

/// The fading smear a fast swing leaves behind.
private func smear(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ trail: [Double], from a: Double, to b: Double, _ col: Px) {
    for (i, angle) in trail.enumerated() {
        let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// A one-pixel ring of radius `r`.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, _ col: Px) {
    var seen = Set<Int>()
    let n = max(12, Int(r * 8))
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        let x = Int((cx + cos(a) * r).rounded()), y = Int((cy + sin(a) * r).rounded())
        if seen.insert(x * 1000 + y).inserted { c.px(x, y, col) }
    }
}

/// A square fist of side `s` centred on `p`, knuckles to the front.
private func fist(_ c: PixelCanvas, _ p: (x: Double, y: Double), size s: Int, skin: Px, dark: Px, light: Px) {
    let x = Int(p.x.rounded()) - s / 2, y = Int(p.y.rounded()) - s / 2
    c.rect(x, y, s, s, skin)
    c.rect(x, y + s - 1, s, 1, dark)
    c.rect(x + s - 1, y, 1, s, dark)
    c.rect(x, y, s - 1, 1, light)
    if s >= 5 { for k in stride(from: 1, to: s - 1, by: 2) { c.px(x + s - 2, y + k, dark) } }   // knuckles
}

/// Boots over the bottom of standing legs (seated legs fold away under the body, so they get none).
private func drawBoots(_ c: PixelCanvas, step: Int, _ col: Px, height: Int = 2) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = step >= 0 && i % 2 == step
        c.rect(lx, (lifted ? 43 : 44) - height, 2, height, col)
    }
}

/// Draws `draw` on a layer of its own and lays it over `c` at `alpha` (offsets as for any drawing), with a `rim`
/// outline round it if given: for a figure fading out of sight.
private func overlay(_ c: PixelCanvas, alpha: Double, rim: Px? = nil, _ draw: (PixelCanvas) -> Void) {
    let layer = PixelCanvas(c.w, c.h)
    draw(layer)
    let w = layer.w, h = layer.h, b = layer.buf
    func solid(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && b[(y * w + x) * 4 + 3] > 200 }
    for y in 0..<h {
        for x in 0..<w {
            let i = (y * w + x) * 4, a = b[i + 3]
            if a > 0 {
                let m = 255 / Double(a)
                c.px(x, y, Px(r: UInt8(min(255, Double(b[i]) * m)), g: UInt8(min(255, Double(b[i + 1]) * m)),
                              b: UInt8(min(255, Double(b[i + 2]) * m)), a: a).alpha(alpha))
            } else if let rim, solid(x - 1, y) || solid(x + 1, y) || solid(x, y - 1) || solid(x, y + 1) {
                c.px(x, y, rim)
            }
        }
    }
}

private struct Fire { let tip, outer, mid, core: Px }
private let torchFire = Fire(tip: C(0xC8281A), outer: C(0xF0561A), mid: C(0xFF9A2A), core: C(0xFFE27A))
private let hellFire = Fire(tip: C(0xA01C0C), outer: C(0xE8461A), mid: C(0xFF8A1E), core: C(0xFFD84A))

/// Flame tongues licking up from row `base` over columns x0…x1, at most `height` tall, bending back by `lean` pixels a
/// row, flickering on clock `t`.
private func drawFlames(_ c: PixelCanvas, x0: Int, x1: Int, base: Int, height: Double, lean: Double, t: Double,
                        seed: Int = 0, _ fire: Fire, alpha: Double = 1) {
    let tick = Int(t * 10)
    let half = Double(x1 - x0) / 2 + 1, mid = Double(x0 + x1) / 2 - half * 0.25   // tallest a little behind the middle
    for x in x0...x1 {
        let d = (Double(x) - mid) / half
        let env = max(0.2, 1 - d * d)
        let n = 0.7 * noise(seed + (x / 2) * 13 + tick * 71) + 0.3 * noise(seed + x * 7 + tick * 29)
        let h = Int((height * env * (0.45 + 0.55 * n)).rounded())
        guard h > 0 else { continue }
        for k in 0..<h {
            let f = Double(k) / Double(h)
            let col = f > 0.72 ? fire.tip : f > 0.42 ? fire.outer : f > 0.18 ? fire.mid : fire.core
            c.px(x - Int(Double(k) * lean), base - 1 - k, col.alpha(alpha))
        }
    }
}

/// The Fantastic Four's emblem: a white ring round a blue 4, on the chest.
private func drawFFEmblem(_ c: PixelCanvas, x: Int = 26, y: Int = 33) {
    c.pattern(x, y, [".WWW.", "WBWBW", "WBBBW", "WWWBW", ".WWW."], ["W": white, "B": ffBlueShade])
}

/// The blue Fantastic Four uniform over Clawd's lower half, emblem on the chest.
private func drawFFSuit(_ c: PixelCanvas) {
    c.rect(18, 33, 20, 5, ffBlue)
    c.rect(37, 33, 1, 5, ffBlueShade)
    c.rect(18, 37, 20, 1, ffBlueShade)
    c.rect(18, 33, 20, 1, C(0x16161C))                 // the black collar line
    drawFFEmblem(c, y: 33)
}

// MARK: - Fantastic Four

/// Human Torch: Clawd as a living flame, red-orange body with a white-hot core, flames streaming off his head and back,
/// a fireball in his hand; in flight his legs become a comet's tail. Signature: he flames off (Johnny in the blue FF suit,
/// blond hair) and bursts back alight, bigger than before, "Flame on!".
private func drawHumanTorch(_ c: PixelCanvas, _ p: Pose) {
    var flame = 1.0, burst = 0.0
    if let s = p.signature {
        if s < 0.25 { flame = 1 - s / 0.25 } else if s < 0.55 { flame = 0 } else {
            flame = min(1, (s - 0.55) / 0.06)
            burst = habitArc((s - 0.55) / 0.45, hold: 0.25)
        }
    }
    if flame < 1 { drawJohnny(c, p, ember: flame < 0.05 && p.signature.map { $0 > 0.4 } == true) }
    if flame > 0 { overlay(c, alpha: flame) { drawTorchAflame($0, p, size: max(0.35, flame) + burst) } }
}

/// Johnny Storm with the fire off.
private func drawJohnny(_ c: PixelCanvas, _ p: Pose, ember: Bool) {
    drawLegs(c, Look(leg: ffBlue), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: ffBlue))
    c.pattern(17, 21, [
        "......Y...Y..Y........",
        "...YYYYYYYYYYYYYYYY...",
        "..YYYYyYYYYYYYYyYYYY..",
        ".YYYyYYYYYyYYYYYyYYYY.",
        ".YYYYYYYYYYYYYYYYYYYY.",
        ".YY..Y...YYY....Y..YY.",
    ], ["Y": C(0xF2D06A), "y": C(0xC8A040)])
    drawFFSuit(c)
    if ember { c.px(41, 33, C(0xFFB02A)); c.px(40, 32, C(0xFF6A1A).alpha(0.7)) }   // a spark on his fingertip
}

/// The Torch alight. `size` scales his flames (1 normally, up to 2 as he bursts back on).
private func drawTorchAflame(_ c: PixelCanvas, _ p: Pose, size: Double) {
    let red = C(0xE8461A), shade = C(0xB8300E), gold = C(0xFFB02A), hot = C(0xFFE89A)
    let t = p.t
    if p.flying {
        // No legs: a comet's tail of fire streaming back from his hips.
        for i in 0..<5 {
            let y = 30.0 + Double(i) * 2, len = 14 + 6 * noise(Int(t * 12) + i * 5)
            c.glowLine(22, y + 1, 22 - len, y - 3 + Double(i), core: i == 2 ? hot : gold, glow: red, coreR: 0.6, glowR: 2.0,
                       strength: 0.9)
        }
        c.rect(18, 36, 20, 3, red)
        drawFlames(c, x0: 18, x1: 37, base: 41, height: 3, lean: 0, t: t, seed: 5, torchFire)
    } else {
        drawLegs(c, Look(leg: red), step: p.step)
        for lx in [19, 23, 31, 35] where !seatedPose { c.rect(lx, 37, 1, 4, gold) }
    }
    c.oy += p.breathe
    // Flames off his back and head, streaming behind him (more so in flight).
    let lean = p.flying ? 1.1 : 0.35
    drawFlames(c, x0: 14, x1: 22, base: 36, height: 5 * size, lean: lean + 0.4, t: t, seed: 11, torchFire)
    drawFlames(c, x0: 17, x1: 38, base: 27, height: 11 * size, lean: lean, t: t, seed: 3, torchFire)
    let raise = p.fire != nil ? 2 : 0
    drawBody(c, Look(body: red, shade: shade, arm: gold, eye: nil), armRight: raise)
    c.ellipse(28, 32, 7, 4, C(0xFF7A1E))                 // the heat inside, brightest at the heart
    c.ellipse(27, 33, 4, 2, gold)
    c.rect(22, 29, 2, 3, hot); c.rect(32, 29, 2, 3, hot) // white-hot eyes
    c.rect(18, 26, 20, 1, C(0xFF7A1E))
    // A fireball cupped in his hand.
    let fy = 34.0 - Double(raise)
    let flick = noise(Int(t * 14))
    c.glowLine(42, fy, 42, fy, core: hot, glow: C(0xFF6A1A), coreR: 0.9, glowR: 2 + flick)
    if size > 1.2 {                                      // bursting back on: sparks thrown off
        for i in 0..<8 {
            let a = noise(Int(t * 20) * 3 + i) * 2 * .pi, r = 12 + noise(i * 7 + Int(t * 20)) * 8
            c.px(28 + Int(cos(a) * r), 28 + Int(sin(a) * r * 0.8), i % 2 == 0 ? hot : gold)
        }
    }
}

/// The Thing: a bigger Clawd built of orange rock plates, heavy brow over small blue eyes, a grim crack of a mouth,
/// blue shorts, fists like boulders. Signature: he cracks his rocky knuckles, one fist in the other, pop, pop.
private func drawThing(_ c: PixelCanvas, _ p: Pose) {
    let rock = C(0xE0803A), dark = C(0x9A4A1C), light = C(0xF6AA62), shorts = C(0x2A4FB0)
    // Thick stubby legs.
    if seatedPose {
        drawLegs(c, Look(leg: rock), step: p.step)
    } else {
        for (i, lx) in [17, 22, 31, 36].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 3, lifted ? 7 : 8, rock)
            c.rect(lx + 2, 36, 1, lifted ? 7 : 8, dark)
            c.rect(lx, 39, 3, 1, dark)
        }
    }
    c.oy += p.breathe
    let cracking = p.signature.map { $0 > 0.08 && $0 < 0.92 } ?? false
    // The far arm, behind him.
    if !cracking {
        c.rect(12, 29, 4, 7, dark)
        fist(c, (13.5, 37), size: 5, skin: rock, dark: dark, light: light)
    }
    // The body: rock plates in a brick bond.
    c.rect(17, 22, 22, 16, rock)
    c.rect(16, 23, 24, 14, rock)
    for (band, y) in [22, 26, 30, 34].enumerated() {
        c.rect(16, y + 3, 24, 1, dark)
        for x in stride(from: 17 + (band % 2) * 3, to: 39, by: 6) {
            c.rect(x, y, 1, 3, dark)
            c.rect(x + 1, y, 3, 1, light)
        }
    }
    c.rect(39, 23, 1, 14, dark)
    // Brow, eyes and a grim mouth.
    c.rect(19, 26, 19, 2, C(0xC8642A))
    c.rect(19, 26, 19, 1, light)
    c.rect(22, 28, 3, 2, C(0x16161B)); c.rect(32, 28, 3, 2, C(0x16161B))
    c.px(23, 28, C(0x6AB4FF)); c.px(33, 28, C(0x6AB4FF))
    c.rect(25, 32, 9, 1, dark); c.px(24, 33, dark); c.px(34, 33, dark)
    // Blue shorts with a belt.
    c.rect(16, 34, 24, 4, shorts)
    c.rect(16, 34, 24, 1, C(0x1A2E70))
    c.rect(39, 35, 1, 3, C(0x1E3A8A))
    if cracking, let s = p.signature {
        // Both fists together in front of him, squeezing; a pop of grit with every crack.
        let k = (s - 0.08) / 0.84, squeeze = Int(k * 10) % 2
        c.glowLine(17, 31, 28, 32, core: dark, glow: none, coreR: 1.6, glowR: 1.7)
        c.glowLine(39, 31, 34, 32, core: rock, glow: none, coreR: 1.6, glowR: 1.7)
        fist(c, (29 + Double(squeeze), 32), size: 6, skin: rock, dark: dark, light: light)
        fist(c, (34, 31), size: 6, skin: rock, dark: dark, light: light)
        let pop = frac(k * 4)
        if pop < 0.35 {
            let r = 3 + pop * 10
            for a in stride(from: -2.6, through: -0.5, by: 0.7) {
                c.px(32 + Int(cos(a) * r), 29 + Int(sin(a) * r), C(0xFFF2C8))
            }
            c.px(32, 26 - Int(pop * 6), C(0xF6AA62))
        }
        return
    }
    if let m = p.melee {
        smear(c, hand, p.trail, from: 4, to: 9, light)
        bar(c, hand, m, from: -2, to: 6, rock, r: 1.6)
        fist(c, reach(hand, m, 8), size: 6, skin: rock, dark: dark, light: light)
    } else {
        c.rect(38, 29, 4, 7, rock)                      // the near arm hangs, fist by his knee
        c.rect(41, 29, 1, 7, dark)
        fist(c, (40.5, 37), size: 6, skin: rock, dark: dark, light: light)
    }
}

/// Mr. Fantastic: Clawd with Reed's dark side-parted hair greying at the temples, the blue FF suit with its emblem. His
/// punch is a long rubbery arm with a black glove on the end, stretching further on the fast swings. Signature: he
/// stretches his arm right out across the screen, waves, and lets it snap back.
private func drawMrFantastic(_ c: PixelCanvas, _ p: Pose) {
    drawLegs(c, Look(leg: ffBlue), step: p.step)
    drawBoots(c, step: p.step, C(0x16161C))
    c.oy += p.breathe
    drawBody(c, Look(arm: ffBlue))
    c.pattern(17, 21, [
        "....HHHHHHHHHHHHH.....",
        "..HHHHHHHHHHHHHHHHH...",
        ".gHHHhhHHHHHHHHHHHHg..",
        ".gHHHHHHhHHHHHHHHHHg..",
        ".gg.HHHHHHHH.HHHHH.gg.",
    ], ["H": C(0x4A3020), "h": C(0x2E1C10), "g": C(0xD8D8DE)])
    drawFFSuit(c)
    if let s = p.signature, s > 0.05, s < 0.95 {
        let k = (s - 0.05) / 0.9
        let len = 5 + 24 * habitArc(k, hold: 0.45)
        drawStretchArm(c, angle: -8, length: len, t: p.t, wave: habitArc(k, hold: 0.45) > 0.95)
        return
    }
    if let m = p.melee {
        let len = p.trail.isEmpty ? 11.0 : 19.0
        smear(c, hand, p.trail, from: 3, to: len, ffBlue)
        drawStretchArm(c, angle: m, length: len, t: p.t, wave: false)
    }
}

/// Reed's arm, stretched `length` pixels along `angle`, rippling like rubber; `wave`: the hand waves on the end.
private func drawStretchArm(_ c: PixelCanvas, angle: Double, length: Double, t: Double, wave: Bool) {
    let r = angle * .pi / 180, nx = -sin(r), ny = cos(r)
    var prev = (x: hand.x - 2, y: hand.y)
    let n = max(2, Int(length / 2))
    for i in 1...n {
        let d = length * Double(i) / Double(n), f = Double(i) / Double(n)
        let off = sin(d * 0.55 - t * 14) * 1.1 * f * (1 - f) * 2
        let q = (x: hand.x + cos(r) * d + nx * off, y: hand.y + sin(r) * d + ny * off)
        c.glowLine(prev.x, prev.y, q.x, q.y, core: ffBlue, glow: none, coreR: 0.9, glowR: 1.0)
        prev = q
    }
    let tip = reach(hand, angle, length + 1.5)
    if wave {
        let up = Int(t * 8) % 2 == 0
        c.rect(Int(tip.x) - 1, Int(tip.y) - 2, 3, 4, C(0x16161C))
        c.rect(Int(tip.x) + (up ? 0 : -1), Int(tip.y) - 4, 1, 2, C(0x16161C))
        c.rect(Int(tip.x) + (up ? 1 : 0), Int(tip.y) - 4, 1, 2, C(0x16161C))
    } else {
        fist(c, tip, size: 3, skin: C(0x2A2A32), dark: C(0x101014), light: C(0x4A4A56))
    }
}

/// Invisible Woman: Clawd with Sue's long blonde hair, in the blue FF suit; she raises a hand and pushes out a pale-blue
/// force stream, a faint force-field bubble round her while she works. Signature: she fades out of sight until only a
/// shimmering outline is left, then fades back.
private func drawInvisibleWoman(_ c: PixelCanvas, _ p: Pose) {
    var seen = 1.0
    if let s = p.signature { seen = 1 - 0.92 * habitArc(s, hold: 0.4) }
    if seen < 1 {
        overlay(c, alpha: seen, rim: C(0xBFE8FF).alpha(0.9 * (1 - seen))) { drawSue($0, p) }
        if let s = p.signature, seen < 0.3 {                       // a glint or two in the air where she stands
            for i in 0..<2 {
                let f = frac(s * 5 + Double(i) * 0.5)
                c.px(20 + Int(noise(Int(s * 5 + Double(i) * 0.5) + i * 9) * 16), 24 + Int(f * 12), white.alpha(1 - f))
            }
        }
    } else {
        drawSue(c, p)
    }
    if p.mode == .working, p.zap != nil {                          // the force field, faint round her
        let shimmer = 0.22 + 0.08 * sin(p.t * 9)
        ring(c, 28, 31 + Double(p.breathe), 15, C(0x9ADCFF).alpha(shimmer))
    }
}

private func drawSue(_ c: PixelCanvas, _ p: Pose) {
    let blonde = C(0xF4D47A), streak = C(0xD0A848)
    drawLegs(c, Look(leg: ffBlue), step: p.step)
    drawBoots(c, step: p.step, C(0x16161C))
    c.oy += p.breathe
    c.pattern(15, 26, ["YY", "YY", "YY", "Yy", "YY", "Y.", "y."], ["Y": blonde, "y": streak])   // hair down her back
    drawBody(c, Look(arm: ffBlue), armRight: p.armRaise)
    c.pattern(15, 20, [
        "......YYYYYYYYYYYY......",
        "....YYYYYYYYYYYYYYYY....",
        "...YYYyYYYYYYYYYYyYYY...",
        "..YYYyYYYYYYYYYYYYyYYY..",
        "..YYYYYYYYYYyYYYYYYYYY..",
        "..YYYYYYYYYYYYYYYYYYYY..",
        "..YYYY.YYY....YYY..YYY..",
        "..YYY...............YY..",
        "..YYy...............YY..",
        "..YYY...............Yy..",
        "..YY.................Y..",
    ], ["Y": blonde, "y": streak])
    drawFFSuit(c)
}

// MARK: - The cosmic

/// Silver Surfer: a chrome Clawd with a smooth bald dome, always standing on his gleaming surfboard (never sits);
/// in flight the board trails cosmic sparkle. Power cosmic streams from his raised hand. Signature: a kickflip, he
/// hops up, the board flips over twice under him, and he lands back on it.
private func drawSilverSurfer(_ c: PixelCanvas, _ p: Pose) {
    let chrome = C(0xC8D2E0), shade = C(0x7E8AA2), shine = C(0xF8FBFF), line = C(0x98A4B8)
    var lift = 0, boardUp = 0.0, spin = 0.0
    if let s = p.signature {
        let arc = habitArc(s, hold: 0.3)
        lift = Int((11 * arc).rounded())
        boardUp = 8 * arc
        let k = max(0, min(1, (s - 0.2) / 0.6))
        spin = 180 * k * k * (3 - 2 * k)
    }
    let base = c.oy
    if p.flying {                                          // cosmic wake behind the board
        for i in 0..<6 {
            let f = frac(p.t * 2.5 + Double(i) / 6)
            let x = 8 - Int(f * 10), y = 41 + Int(noise(i * 5) * 3)
            c.px(x, y, (i % 2 == 0 ? shine : C(0xA8E8FF)).alpha(1 - f))
        }
        c.glowLine(1, 42, 9, 42, core: C(0xE8F8FF, 0.6), glow: C(0xA8E8FF, 0.3), coreR: 0.4, glowR: 1.4)
    }
    let board: [String] = [
        "....hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh.....",
        "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.",
        "SWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "..sssssssssssssssssssssssssssssssssss...",
    ]
    let boardColours: [Character: Px] = ["h": shine, "W": C(0xDDE4EE), "S": line, "s": shade]
    let by = 40 - Int(boardUp.rounded())
    let roll = cos(spin * .pi / 180 * 4)                   // a double kickflip: the board rolls over twice
    if roll > 0.45 {
        c.pattern(8, by, board, boardColours)
    } else if roll > -0.45 {
        c.rect(9, by + 2, 38, 1, line)                     // edge-on
        c.rect(12, by + 1, 30, 1, shine.alpha(0.6))
    } else {
        c.pattern(8, by, board.reversed(), boardColours)   // underside up
        c.rect(10, by + 1, 34, 1, shade)
    }
    c.oy = base - 4 - lift                                 // standing on the board
    drawLegs(c, Look(leg: line), step: -1)
    for lx in [19, 23, 31, 35] { c.rect(lx, 37, 1, 6, chrome) }
    c.oy += p.breathe
    drawBody(c, Look(body: chrome, shade: shade, arm: chrome, eye: C(0x1E2838)), armRight: p.armRaise)
    c.rect(20, 24, 16, 1, chrome); c.rect(19, 25, 18, 1, chrome)   // the smooth dome of his head
    c.rect(22, 24, 6, 1, shine); c.rect(20, 25, 3, 1, shine)
    c.rect(19, 27, 1, 8, shine)                            // chrome catching the light
    c.rect(22, 33, 12, 1, line)                            // a little sculpted muscle
    c.px(27, 34, line); c.px(28, 35, line)
}

// MARK: - The street

/// Daredevil: a red Clawd in the horned cowl, dark lenses, the double-D on his chest; he fights with a red billy club,
/// holstered on his thigh between fights. Signature: his radar sense, red rings pulse out from his head.
private func drawDaredevil(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC0141E), shade = C(0x84101A), dark = C(0x5A0A10)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, step: p.step, shade, height: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: shade, arm: red, eye: nil))
    c.pattern(19, 22, ["h..............h", "hh............hh", ".hh..........hh.", ".RR..........RR."], ["h": red, "R": red])   // horns
    c.rect(18, 26, 20, 1, C(0xE0303A))
    c.pattern(21, 29, ["KKKK......KKKK", ".KKK......KKK."], ["K": C(0x2A0408)])                   // lenses
    c.pattern(25, 33, ["DD.DD.", "D.DD.D", "D.DD.D", "DD.DD."], ["D": dark])                      // the DD
    c.rect(18, 37, 20, 1, dark)
    if let s = p.signature {
        let on = habitArc(s, hold: 0.7)
        for i in 0..<3 {
            let f = frac(s * 2.5 + Double(i) / 3)
            ring(c, 28, 29, 4 + f * 24, C(0xFF3A3A).alpha(0.85 * (1 - f) * on))
        }
        c.pattern(21, 29, ["KKKK......KKKK"], ["K": C(0xFF5A4A).alpha(on)])
    }
    let club = C(0xA01820), cap = C(0x2A2A30)
    if let m = p.melee {
        smear(c, hand, p.trail, from: 1, to: 10, C(0xFF3A3A))
        bar(c, hand, m, from: -2, to: 10, club, r: 0.9)
        bar(c, hand, m, from: 9, to: 10.5, cap, r: 0.9)
        bar(c, hand, m, from: -2.5, to: -1, cap, r: 0.9)
    } else {
        c.rect(37, 33, 2, 9, club); c.rect(37, 41, 2, 1, cap); c.rect(36, 36, 4, 1, dark)   // in his thigh holster
    }
}

/// Deadpool: a red Clawd with the black eye patches and white eyes, a round red-and-black buckle and two katana hilts
/// over his shoulder. Swings a katana. Signature: waves at the camera, then rolls up his mask and munches a chimichanga.
private func drawDeadpool(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC01A22), shade = C(0x861016), black = C(0x1A1A1E)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, step: p.step, black, height: 3)
    c.oy += p.breathe
    let swinging = p.melee != nil
    for (x, y) in [(13.0, 18.0), (17.0, 17.0)] where !(swinging && x == 17) {   // katana hilts over his back
        c.glowLine(x, y, x + 6, y + 9, core: black, glow: none, coreR: 0.8, glowR: 0.9)
        c.px(Int(x) + 1, Int(y) + 1, red); c.px(Int(x) + 2, Int(y) + 3, red)
        c.rect(Int(x) + 3, Int(y) + 4, 2, 1, C(0xB9BEC8))
    }
    drawBody(c, Look(body: red, shade: shade, arm: red, eye: nil))
    c.rect(18, 26, 2, 12, black); c.rect(36, 26, 2, 12, black)          // black side panels
    let patch = [".KKKK.", "KKKKKK", "KKWWKK", "KKWWKK", ".KKKK."]
    c.pattern(20, 27, patch, ["K": black, "W": white])
    c.pattern(30, 27, patch, ["K": black, "W": white])
    c.rect(18, 35, 20, 2, C(0x5A4A3A))                                   // belt with pouches
    c.rect(20, 35, 2, 2, C(0x7A6450)); c.rect(33, 35, 2, 2, C(0x7A6450))
    c.pattern(26, 34, [".KK.", "KRRK", "KRRK", ".KK."], ["K": black, "R": C(0xE02A2A)])
    if let s = p.signature, s > 0.05, s < 0.96 {
        if s < 0.48 {                                                    // a big wave at you
            let k = Int(s * 30) % 2
            c.rect(38, 26, 3, 9, red)
            c.rect(37 + k, 22, 4, 4, red); c.rect(37 + k, 22, 4, 1, C(0xE03A40))
            c.px(37 + k, 21, red); c.px(39 + k, 21, red)
        } else {                                                         // chimichanga time
            let bites = Int((s - 0.5) / 0.46 * 4)
            c.rect(24, 31, 9, 2, C(0xE8A884))                             // mask rolled up: a scarred chin
            c.px(26, 31, C(0xC07868)); c.px(30, 32, C(0xC07868))
            let chew = Int(s * 20) % 2
            c.rect(27, 32 + chew, 3, 1, C(0x5A1A1A))
            let len = max(1, 6 - bites)
            c.rect(38, 30, 3, 5, red)                                    // hand up to his mouth
            c.rect(33, 29, len, 3, C(0xE8C47A)); c.rect(33, 31, len, 1, C(0xB88A44))
            c.px(33, 30, C(0x8A5A2A))
            if bites > 0 && chew == 0 { c.px(31, 28, C(0xE8C47A)); c.px(34, 27, C(0xE8C47A)) }   // crumbs
        }
        return
    }
    if let m = p.melee {
        smear(c, hand, p.trail, from: 3, to: 18, C(0xE8ECF4))
        bar(c, hand, m, from: 3, to: 18, C(0xD8DCE4), r: 0.7)
        bar(c, hand, m, from: 17, to: 18.5, white, r: 0.6)
        bar(c, hand, m, from: -2, to: 2, black, r: 0.8)
        bar(c, hand, m, from: 2, to: 3, C(0x8A8E98), r: 1.4)            // the guard
    }
}

/// Shang-Chi: Clawd with short black hair in a red jacket with gold trim and a black belt, the Ten Rings stacked on his
/// forearm. He lashes out with a chain of glowing rings. Signature: all ten rings lift off and orbit him, glowing blue.
private func drawShangChi(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB8202A), shade = C(0x861418), gold = C(0xE8B83A), black = C(0x1E1E24)
    let glow = C(0x6AD8FF)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    let orbit = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let spin = (p.signature ?? 0) * 2 * .pi * 2.5
    func orbitRings(front: Bool) {
        guard orbit > 0 else { return }
        for i in 0..<10 {
            let a = spin + Double(i) / 10 * 2 * .pi
            guard (sin(a) > 0) == front else { continue }
            let x = 28 + cos(a) * (6 + 12 * orbit), y = 31 - 6 * orbit + sin(a) * 4 * orbit
            drawTenRing(c, x, y, glow: glow.alpha(front ? 1 : 0.6), metal: front ? gold : C(0xA8822A), strength: orbit)
        }
    }
    orbitRings(front: false)
    drawBody(c, Look(arm: red))
    c.pattern(17, 22, [
        "......KKKKKKKKKK......",
        "...KKKKKKKKKKKKKKKK...",
        "..KKKkKKKKKKKKKKkKKK..",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KK.KKK.KKKKK.KKK.KK..",
    ], ["K": C(0x16161A), "k": C(0x3A3A44)])
    c.rect(18, 32, 20, 6, red)
    c.rect(37, 32, 1, 6, shade)
    c.rect(18, 32, 20, 1, gold)                                          // mandarin collar
    c.rect(27, 33, 1, 3, gold)
    c.rect(18, 36, 20, 1, black); c.rect(27, 36, 2, 1, gold)
    orbitRings(front: true)
    if let m = p.melee {
        smear(c, hand, p.trail, from: 3, to: 17, glow)
        let tip = reach(hand, m, 17)
        c.glowLine(hand.x, hand.y, tip.x, tip.y, core: C(0xE8FCFF, 0.7), glow: glow.alpha(0.5), coreR: 0.3, glowR: 1.5)
        for k in 0..<4 { let q = reach(hand, m, 5 + Double(k) * 4); drawTenRing(c, q.x, q.y, glow: glow, metal: gold, strength: 1) }
    } else if orbit == 0 {
        for x in [38, 40] { c.rect(x, 33, 1, 3, gold) }                // rings stacked on his forearm
        c.px(39, 32, glow.alpha(0.7)); c.px(41, 34, glow.alpha(0.5))
    }
}

/// One of the Ten Rings: a little metal hoop with a blue glow.
private func drawTenRing(_ c: PixelCanvas, _ x: Double, _ y: Double, glow: Px, metal: Px, strength: Double) {
    c.glowLine(x, y, x, y, core: glow.alpha(0.4 * strength), glow: glow, coreR: 1.2, glowR: 2.4, strength: 0.5 * strength)
    c.pattern(Int(x.rounded()) - 1, Int(y.rounded()) - 1, [".M.", "M.M", ".M."], ["M": metal.alpha(max(0.3, strength))])
}

/// Ms. Marvel: Clawd with Kamala's dark hair, in her navy tunic with the gold lightning bolt and the red scarf, red
/// boots; she punches with a fist that embiggens on the big swings. Signature: she raises her fist and embiggens it,
/// huge, then shrinks it back.
private func drawMsMarvel(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x24306E), navyShade = C(0x18204A), red = C(0xC8202A), gold = C(0xF2C230)
    let skin = clawdOrange, dark = clawdShade, light = C(0xEE9A7A)
    drawLegs(c, Look(leg: navy), step: p.step)
    drawBoots(c, step: p.step, red, height: 3)
    c.oy += p.breathe
    let flutter = Int(p.t * 5) % 2
    c.pattern(13, 32, ["RRRRR", ".RRRR", "..RR" + (flutter == 0 ? "." : "R")], ["R": red])    // scarf tail
    c.pattern(15, 21, ["......HHHHHHHHHHHH......", "....HHHHHHHHHHHHHHHH....", "...HHHhHHHHHHHHHHHhHH...",
                       "..HHHHHHHHHHHHHHHHHHHHH.", "..HHHH.HHHHHH..HHHH.HH..", "..HHH................H..",
                       "..HHH...................", "..HHh...................", "..HH....................",
                       "...H...................."], ["H": C(0x2A1A14), "h": C(0x4A3020)])
    drawBody(c, Look(arm: navy))
    c.rect(18, 32, 20, 6, navy)
    c.rect(37, 32, 1, 6, navyShade)
    c.rect(18, 32, 20, 2, red)                                           // scarf
    c.pattern(26, 34, [".YYY", "YYY.", "..YY", ".Y.."], ["Y": gold])     // the bolt
    c.rect(18, 37, 20, 1, navyShade)
    if let s = p.signature, s > 0.05, s < 0.95 {
        let big = habitArc((s - 0.05) / 0.9, hold: 0.4)
        let size = 4 + Int((8 * big).rounded())
        let at = reach(hand, -50, 6 + 3 * big)
        bar(c, hand, -50, from: -2, to: 6 + 3 * big - Double(size) / 2, skin, r: 0.9 + big)
        c.rect(Int(at.x) - 3, Int(at.y) + size / 2 - 1, 4, 1, gold)
        fist(c, at, size: size, skin: skin, dark: dark, light: light)
        if big > 0.95 { c.px(Int(at.x) + size / 2 + 2, Int(at.y) - size / 2 - 1, white); c.px(Int(at.x) + size / 2 + 3, Int(at.y) - size / 2, gold) }
        return
    }
    if let m = p.melee {
        let size = p.trail.isEmpty ? 4 : 7
        smear(c, hand, p.trail, from: 3, to: 8, skin)
        bar(c, hand, m, from: -2, to: 5, skin, r: 0.9)
        bar(c, hand, m, from: 2, to: 3, gold, r: 1.1)
        fist(c, reach(hand, m, 5 + Double(size) / 2), size: size, skin: skin, dark: dark, light: light)
    }
}

/// Moon Knight: a white-hooded Clawd with a pale mask and black eyes, a white cape and a dark crescent on his chest;
/// he swings a crescent-headed truncheon. Signature: his cape flares out wide behind him like a crescent moon.
private func drawMoonKnight(_ c: PixelCanvas, _ p: Pose) {
    let cloth = C(0xF4F4F6), clothShade = C(0xB4BAC8), mask = C(0x8E96A8), crescent = C(0x3A4254)
    let flare = p.signature.map { habitArc($0, hold: 0.45) } ?? 0
    // The cape: billows, or flares out to a crescent.
    for y in 24...43 where y + c.oy <= 43 {
        let k = Double(y - 24) / 19
        let hw = 10.5 + k * 4.5 + flare * 14 * sin(k * .pi) * (0.6 + 0.4 * k)
        let sway = sin(p.t * p.capeSpeed + k * 2.2) * k * 1.6 * (1 - flare)
        let l = Int((Sprite.bodyCenterX - 2 - hw + sway).rounded()), r = Int((Sprite.bodyCenterX + hw * 0.55 + sway).rounded())
        c.rect(max(0, l), y, r - max(0, l) + 1, 1, C(0xDCE0E8))
        c.px(l, y, clothShade)
        for fold in [0.35, 0.7] { c.px(l + Int(Double(r - l) * fold * (0.5 + 0.5 * k)), y, clothShade) }   // folds
        if flare > 0.3 { c.px(l + 1, y, clothShade) }
    }
    drawLegs(c, Look(leg: C(0xC4C9D4)), step: p.step)
    drawBoots(c, step: p.step, C(0x8E96A8), height: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: C(0x6E7688), arm: cloth, eye: white))
    drawHood(c, cloth, clothShade)
    c.rect(18, 32, 20, 6, cloth)
    c.rect(37, 32, 1, 6, clothShade)
    c.pattern(26, 32, ["..CC", ".C..", "C...", ".C..", "..CC"], ["C": crescent])
    c.rect(18, 37, 20, 1, C(0x9AA0AC))
    if let m = p.melee {
        smear(c, hand, p.trail, from: 2, to: 13, cloth)
        bar(c, hand, m, from: -2, to: 10, C(0xB8BCC6), r: 0.8)
        let tip = reach(hand, m, 11.5), r = m * .pi / 180
        for a in stride(from: -1.5, through: 1.5, by: 0.25) {               // the crescent head
            let ang = r + a
            c.px(Int((tip.x + cos(ang) * 2.5).rounded()), Int((tip.y + sin(ang) * 2.5).rounded()), white)
        }
        c.px(Int(tip.x.rounded()), Int(tip.y.rounded()), clothShade)
    } else {
        c.rect(37, 34, 2, 7, C(0xB8BCC6)); c.px(36, 34, white); c.px(39, 34, white)
    }
}

/// Ghost Rider: a flaming skull on a black leather jacket with studs and spiked shoulders; he lashes a burning chain.
/// Signature: hellfire, the skull's flames roar up twice as high, the eye sockets blazing, embers flying.
private func drawGhostRider(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x1E1E24), leatherShade = C(0x101014), bone = C(0xEDE6D2), boneShade = C(0xBEB49A)
    let stud = C(0xB8BCC6), socket = C(0x16100C)
    let flare = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawLegs(c, Look(leg: C(0x2A2A32)), step: p.step)
    drawBoots(c, step: p.step, leatherShade, height: 3)
    c.oy += p.breathe
    drawFlames(c, x0: 18, x1: 37, base: 25, height: 10 * (1 + 0.9 * flare), lean: 0.3, t: p.t, seed: 17, hellFire)
    drawBody(c, Look(body: leather, shade: leatherShade, arm: leather, eye: nil))
    c.pattern(19, 22, [
        "....SSSSSSSSSS....",
        "..SSSSSSSSSSSSSS..",
        ".SSSSSSSSSSSSSSSS.",
        "SSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSs",
        "SSKKKKSSSSSSKKKKSs",
        "SSKKKKSSSSSSKKKKSs",
        "SSSKKSSSSSSSSKKSSs",
        ".SSSSSSSKKSSSSSSs.",
        "..SSSSSSSSSSSSSs..",
        "...STSTSTSTSTSTS..",
        "....SSSSSSSSSSS...",
    ], ["S": bone, "s": boneShade, "K": socket, "T": C(0x5A5048)])
    let ember = Int(p.t * 9) % 2 == 0 ? C(0xFF8A1E) : C(0xFFC23A)
    c.px(23, 28, ember); c.px(33, 28, ember)
    if flare > 0.4 { c.rect(22, 27, 3, 2, C(0xFFB02A).alpha(flare)); c.rect(32, 27, 3, 2, C(0xFFB02A).alpha(flare)) }
    // Jacket: collar, studs, spiked shoulders.
    c.pattern(17, 33, ["LLLL..........LLLL", ".LL............LL."], ["L": C(0x2E2E36)])
    for x in stride(from: 20, through: 35, by: 3) { c.px(x, 36, stud) }
    c.px(15, 32, stud); c.px(16, 31, stud); c.px(39, 32, stud); c.px(40, 31, stud)
    if flare > 0.2, let s = p.signature {                            // embers flying up
        for i in 0..<6 {
            let f = frac(s * 3 + Double(i) / 6)
            c.px(19 + Int(noise(i * 11) * 18), 22 - Int(f * 20), C(0xFFC23A).alpha((1 - f) * flare))
        }
    }
    if let m = p.melee {
        smear(c, hand, p.trail, from: 3, to: 18, C(0xFF8A1E))
        drawChain(c, angle: m, length: 18, t: p.t)
    } else {
        drawChainLoop(c)
    }
}

/// Ghost Rider's chain whipped out along `angle`, sagging a little, burning.
private func drawChain(_ c: PixelCanvas, angle: Double, length: Double, t: Double) {
    let r = angle * .pi / 180, nx = -sin(r), ny = cos(r)
    var pts: [(x: Double, y: Double)] = []
    for i in 0...Int(length / 2) {
        let d = Double(i) * 2, f = d / length
        let sag = sin(f * .pi) * 1.5 * (ny > 0 ? 1 : -1)
        pts.append((hand.x + cos(r) * d + nx * sag, hand.y + sin(r) * d + ny * sag))
    }
    for (i, q) in pts.enumerated() {
        c.glowLine(q.x, q.y, q.x, q.y, core: C(0xFF8A1E, 0.5), glow: C(0xFF4A1A), coreR: 0.5, glowR: 1.8 + noise(i + Int(t * 20)),
                   strength: 0.55)
    }
    for (i, q) in pts.enumerated() {
        let x = Int(q.x.rounded()), y = Int(q.y.rounded())
        c.px(x, y, i % 2 == 0 ? C(0xC8CCD4) : C(0x6A6E78))
        if i % 2 == 0 { c.px(x + 1, y, C(0x8A8E98)) }
    }
    let tip = pts[pts.count - 1]
    c.glowLine(tip.x, tip.y, tip.x, tip.y, core: C(0xFFE27A), glow: C(0xFF6A1A), coreR: 0.8, glowR: 2.2)
}

/// The chain looped from his hand to his belt, at rest.
private func drawChainLoop(_ c: PixelCanvas) {
    for i in 0..<14 {
        let a = Double(i) / 13 * .pi
        let x = 39 - Int((cos(a) * 3).rounded()), y = 34 + Int((sin(a) * 6).rounded())
        c.px(x, y, i % 2 == 0 ? C(0xC8CCD4) : C(0x6A6E78))
    }
}
