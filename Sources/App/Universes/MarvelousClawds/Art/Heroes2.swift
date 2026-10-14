import Foundation

// Heroes: more Avengers and the Guardians of the Galaxy.

let heroes2: [MarvelHero: Persona] = [
    .antMan: Persona(name: "Aunt-Man", weapon: .saber, headTop: 13, signature: 3.0,
                  draw: drawAntMan),
    .wasp: Persona(name: "The Waspette", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFFBD0), glow: C(0xFFC81E)),
                   muzzle: (42, 33), handGun: false, headTop: 17, signature: 2.4,
                  draw: drawWasp),
    .falcon: Persona(name: "Falconer", weapon: .blaster, motion: .fly, shot: .bullet, muzzle: (50, 32), headTop: 23,
                     signature: 2.8,
                  draw: drawFalcon),
    .winterSoldier: Persona(name: "Winter Trooper", weapon: .blaster, shot: .bullet, muzzle: (52, 32), headTop: 20,
                            signature: 2.8,
                  draw: drawWinterSoldier),
    .starLord: Persona(name: "Star-Laird", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFE8C0), glow: C(0xFF6A2A)),
                       muzzle: (49, 32), headTop: 18, signature: 3.4,
                  draw: drawStarLord),
    .gamora: Persona(name: "Gamura", weapon: .saber, headTop: 21, signature: 2.4,
                  draw: drawGamora),
    .drax: Persona(name: "Drex the Destroyer", weapon: .saber, headTop: 24, signature: 3.4,
                  draw: drawDrax),
    .rocket: Persona(name: "Racket", weapon: .blaster, shot: .energy(core: C(0xF0E0FF), glow: C(0x9A4AFF)),
                     muzzle: (54, 37), headTop: 24, signature: 2.8,
                  draw: drawRocket),
    .groot: Persona(name: "Grout", weapon: .saber, pivot: (40.5, 25.5), headTop: 7, signature: 3.4, callout: "I am Grout.",
                  draw: drawGroot),
    .mantis: Persona(name: "Mantys", headTop: 12, signature: 2.6,
                  draw: drawMantis),
    .nickFury: Persona(name: "Nick Furie", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 25, signature: 2.4,
                  draw: drawNickFury),
    .sheHulk: Persona(name: "She-Bulk", weapon: .saber, headTop: 19, signature: 2.6,
                  draw: drawSheHulk),
]

// MARK: - Shared bits

private let clear = C(0x000000, 0)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from the hand along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// A punch: the arm thrown out along `angle` (nil: nothing, the arm stays a nub), a fist on the end and faint
/// fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double?, trail: [Double], arm: Px, fist: Px, reach: Double = 7,
                       size: Int = 3, from h: (x: Double, y: Double) = Sprite.hand) {
    guard let angle else { return }
    for (i, a) in trail.enumerated() {
        let e = along(a, reach, from: h)
        c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = along(angle, reach, from: h)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist)
}

/// A straight sword or knife in the hand at `angle`: grip, guard, blade with a bright edge, and a smear for a
/// fast swing.
private func drawBlade(_ c: PixelCanvas, angle: Double, trail: [Double], length: Double, blade: Px, edge: Px, grip: Px,
                       guardWidth: Double = 2, curve: Double = 0) {
    let h = Sprite.hand
    for (i, a) in trail.enumerated() {
        let s = along(a, 3), e = along(a, 3 + length)
        c.glowLine(s.x, s.y, e.x, e.y, core: edge.alpha(0.5), glow: edge.alpha(0.5), coreR: 0.4, glowR: 1.4,
                   strength: 0.45 / Double(i + 1))
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    bar(c, h.x - ux * 2, h.y - uy * 2, h.x + ux * 1.5, h.y + uy * 1.5, grip, 0.8)
    bar(c, h.x + ux * 2 - nx * guardWidth, h.y + uy * 2 - ny * guardWidth,
        h.x + ux * 2 + nx * guardWidth, h.y + uy * 2 + ny * guardWidth, grip, 0.6)
    // The blade in a few short pieces, so it can bend a little (`curve` pixels at the tip, to the back edge).
    var prev = (x: h.x + ux * 2.5, y: h.y + uy * 2.5)
    let n = 4
    for i in 1...n {
        let f = Double(i) / Double(n), bend = curve * f * f
        let q = (x: h.x + ux * (2.5 + length * f) - nx * bend, y: h.y + uy * (2.5 + length * f) - ny * bend)
        bar(c, prev.x, prev.y, q.x, q.y, blade, 0.85)
        prev = q
    }
    let tip = (x: h.x + ux * (2.5 + length) - nx * curve, y: h.y + uy * (2.5 + length) - ny * curve)
    bar(c, h.x + ux * 3 + nx * 0.4, h.y + uy * 3 + ny * 0.4, tip.x, tip.y, edge, 0.45)
}

/// Draws `art` on a fresh canvas of sprite size, its origin at (0, 0).
private func offscreen(_ art: (PixelCanvas) -> Void) -> PixelCanvas {
    let o = PixelCanvas(Sprite.width, Sprite.height)
    art(o)
    return o
}

/// The colour drawn at (`x`, `y`) on `o`, or nil where nothing is.
private func colour(_ o: PixelCanvas, _ x: Int, _ y: Int) -> Px? {
    guard x >= 0, y >= 0, x < o.w, y < o.h else { return nil }
    let i = (y * o.w + x) * 4, a = o.buf[i + 3]
    guard a > 0 else { return nil }
    let m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(o.buf[i]) * m)), g: UInt8(min(255, Double(o.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(o.buf[i + 2]) * m)), a: a)
}

/// `o` drawn onto `c` faded to `alpha`, scaled by `scale` so that its point `from` lands on `to`.
private func stamp(_ c: PixelCanvas, _ o: PixelCanvas, alpha: Double = 1, scale: Double = 1,
                   from: (x: Double, y: Double) = (28, 43.5), to: (x: Double, y: Double)? = nil) {
    let to = to ?? from
    for y in 0..<o.h {
        for x in 0..<o.w {
            let sx = Int(floor(from.x + (Double(x) + 0.5 - to.x) / scale))
            let sy = Int(floor(from.y + (Double(y) + 0.5 - to.y) / scale))
            guard let col = colour(o, sx, sy) else { continue }
            c.px(x, y, col.alpha(alpha))
        }
    }
}

/// A flyer on the move: the whole figure leant forward into its flight by `degrees`.
private func tilted(_ c: PixelCanvas, _ degrees: Double, _ art: (PixelCanvas) -> Void) {
    let o = offscreen(art)
    stamp(c, o.rotated(degrees, about: (28, 34), into: o.w, o.h, at: (28, 34)))
}

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

// MARK: - Ant-Man

/// Ant-Man (Scott Lang): Clawd in the red-and-black suit under the round red helmet with its silver crest, two big
/// red lenses, the breather across the mouth and a pair of feelers; he fights with his fists. Signature: he shrinks
/// to ant size in a burst of Pym particles, scurries about on the floor, and pops back up.
private func drawAntMan(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.1, s < 0.9 else { antMan(c, p); return }
    var q = p
    q.signature = nil; q.breathe = 0
    // 1 = full size: down fast, a while tiny, back up fast.
    let k = s < 0.2 ? 1 - (s - 0.1) / 0.1 : s > 0.8 ? (s - 0.8) / 0.1 : 0
    let run = s > 0.2 && s < 0.8 ? sin((s - 0.2) / 0.6 * 2 * .pi) * 7 : 0
    stamp(c, offscreen { antMan($0, q) }, scale: 0.18 + 0.82 * k * k, to: (28 + run, 43.5))
    if k > 0, k < 1 {                                     // Pym particles at the change
        for i in 0..<8 {
            let a = Double(i) / 8 * 2 * .pi + s * 9, r = 4 + (1 - k) * 9 * noise(i + 3)
            let col = i % 2 == 0 ? C(0x9AD8FF) : C(0xFF5A6A)
            c.px(28 + Int((cos(a) * r).rounded()), 36 + Int((sin(a) * r * 0.7).rounded()), col)
        }
    }
}

private func antMan(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB8232B), dark = C(0x7C161C), black = C(0x1E1E24), silver = C(0xAEB4BE), lens = C(0xE0303C)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: dark, arm: black, eye: nil))
    c.rect(25, 33, 6, 5, black)                                       // black chest panel
    c.rect(18, 36, 20, 1, C(0x3A3A42)); c.rect(26, 36, 4, 1, silver)  // belt and buckle
    // Feelers
    bar(c, 23, 18, 20, 13, silver, 0.45); bar(c, 32, 18, 35, 13, silver, 0.45)
    c.pattern(16, 17, [
        ".......RRRRRRRRRR.......",
        ".....RRRRRRssRRRRRR.....",
        "....RRRRRRRssRRRRRRR....",
        "...RRRRRRRRssRRRRRRRR...",
        "..RRRRRRRRRssRRRRRRRRR..",
        "..RRRRRRRRRssRRRRRRRRR..",
        ".RRRRRRRRRRssRRRRRRRRRR.",
        ".RSSSSSSSSSSSSSSSSSSSSR.",
        ".RKKKSSSKKKKKKKKSSSKKKR.",
        ".RKKSLLLSKKKKKKSLLLSKKR.",
        ".RKKSLlLSKKKKKKSLlLSKKR.",
        ".RKKSLLLSKKKKKKSLLLSKKR.",
        ".RKKKSSSKKKKKKKKSSSKKKR.",
        ".RRKKKKKKSSSSSSKKKKKKRR.",
        ".RRTTTTTTSMMMMSTTTTTTRR.",
        "..RRRRRRRSSSSSSRRRRRRR..",
    ], ["R": red, "s": silver, "S": silver, "K": black, "L": lens, "l": C(0xFFC8C8), "T": C(0x5A5E68),
        "M": C(0x3A3E48)])
    c.px(20, 19, C(0xE05A60)); c.px(19, 20, C(0xE05A60))                // a shine on the dome
    drawPunch(c, angle: p.melee, trail: p.trail, arm: red, fist: black)
}

// MARK: - Wasp

/// The Wasp (Janet van Dyne, comics): a sleek black bob, a yellow-and-black striped suit, little feelers and gauzy
/// wings; she stings from her gloves. Flying, she leans into it and her wings blur. Signature: her wings buzz and she
/// zips straight up into the air and drops back down.
private func drawWasp(_ c: PixelCanvas, _ p: Pose) {
    if p.flying { tilted(c, 22) { wasp($0, p, buzz: true) }; return }
    if let s = p.signature {
        let lift = habitArc(s, hold: 0.35)
        c.oy -= Int((lift * 11).rounded())
        if lift > 0.2, lift < 0.95 {                                        // speed lines under her
            for x in [22, 28, 34] { c.rect(x, 45, 1, 3, white.alpha(0.5)) }
        }
        wasp(c, p, buzz: true)
        return
    }
    wasp(c, p, buzz: false)
}

private func wasp(_ c: PixelCanvas, _ p: Pose, buzz: Bool) {
    let black = C(0x23232B), yellow = C(0xF2C21E), yellowD = C(0xC8961A), hair = C(0x16131A)
    waspWings(c, t: p.t, buzz: buzz, lift: p.breathe)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: black))
    c.rect(18, 33, 20, 5, yellow); c.rect(37, 33, 1, 5, yellowD)
    c.rect(18, 35, 20, 1, black); c.rect(18, 37, 20, 1, black)        // the wasp stripes
    // Feelers, curling up and out of the bob
    bar(c, 24, 21, 22, 16, black, 0.45); bar(c, 31, 21, 33, 16, black, 0.45)
    c.px(21, 15, yellow); c.px(34, 15, yellow)
    c.pattern(17, 20, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHhHHHHHHHHhHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHH...........HHHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
        ".HH................HH.",
        ".HHH..............HHH.",
        "..HH..............HH..",
    ], ["H": hair, "h": C(0x3A3446)])
    c.rect(38, 33, 3, 3, black); c.rect(40, 33, 1, 3, yellow)          // gloves with the stingers
    if let f = p.fire, frac(f.t / blasterPeriod) < 0.25 {
        c.oy += p.gunY
        c.glowLine(40.5, 34, 40.5, 34, core: C(0xFFFBD0), glow: yellow, coreR: 0.7, glowR: 2)
    }
}

/// Two pairs of see-through wings on her back; blurred into a buzz while she flies.
private func waspWings(_ c: PixelCanvas, t: Double, buzz: Bool, lift: Int) {
    let film = C(0xD4F0FF, 0.55), vein = C(0x9ED2EE, 0.85)
    let root = (x: 19.0, y: 26.0 + Double(lift))
    let tips: [(Double, Double, Double)] = buzz
        ? (Int(t * 24) % 2 == 0 ? [(5, 13, 0.55), (4, 21, 0.35), (9, 26, 0.5)] : [(6, 18, 0.55), (8, 10, 0.35), (10, 23, 0.5)])
        : [(6, 14, 1), (9, 25, 0.9)]
    for (i, tip) in tips.enumerated() {
        let r = i == tips.count - 1 ? 1.8 : 2.4
        c.glowLine(root.x, root.y + Double(i), tip.0, tip.1 + Double(lift), core: film.alpha(tip.2), glow: vein.alpha(tip.2),
                   coreR: r, glowR: r + 0.9)
    }
}

// MARK: - Falcon

/// Falcon (Sam Wilson, the films): the grey flight suit with red chevrons, red goggles, and the steel wing pack
/// folded down his back; two compact machine pistols. Flying, he leans in with his wings spread wide. Signature: he
/// stands and spreads his wings, feather by feather, then folds them away again.
private func drawFalcon(_ c: PixelCanvas, _ p: Pose) {
    if p.flying { tilted(c, 16) { falcon($0, p, spread: 1) }; return }
    falcon(c, p, spread: p.signature.map { habitArc($0, hold: 0.45) } ?? 0)
}

private func falcon(_ c: PixelCanvas, _ p: Pose, spread: Double) {
    let grey = C(0x4A4F5A), greyD = C(0x30333B), red = C(0xCC2630), skin = C(0x6E4630)
    falconWing(c, spread: spread, far: true, lift: p.breathe)
    falconWing(c, spread: spread, far: false, lift: p.breathe)
    drawLegs(c, Look(leg: greyD), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: C(0x553522), arm: grey, eye: nil))
    c.pattern(18, 24, ["...KKKKKKKKKKKKKK...", ".KKKKKKKKKKKKKKKKKK.", "KKKKKKKKKKKKKKKKKKKK"], ["K": C(0x1A1412)])  // close crop
    c.rect(18, 29, 20, 1, greyD)                                          // goggle strap
    c.pattern(20, 28, ["FFFFFF....FFFFFF", "FRRRRF....FRRRRF", "FRrRRF....FRrRRF", "FFFFFF....FFFFFF"],
              ["F": greyD, "R": red, "r": C(0xFF9A9A)])
    c.rect(18, 32, 20, 6, grey); c.rect(37, 32, 1, 6, greyD)
    c.pattern(18, 32, ["RR................RR", ".RR..............RR.", "..RR....KKKK....RR..", "...RR...KKKK...RR...",
                       "....RR..........RR.."], ["R": red, "K": greyD])
    c.rect(18, 37, 20, 1, greyD)
    c.oy += p.gunY
    c.pattern(40, 31, ["...SS....", "KKKKKKKKK", "KKKKkK...", "KK.MM....", "KK.MM...."],
              ["K": C(0x24262C), "k": C(0x5A5E68), "S": C(0x5A5E68), "M": C(0x3A3C44)])
}

/// One of the steel wings, as six long feathers fanned from the shoulder: lying down his back (`spread` 0) or swung
/// out behind him (1). The far wing is darker and sits a little higher.
private func falconWing(_ c: PixelCanvas, spread k: Double, far: Bool, lift: Int) {
    let root = far ? (x: 20.0, y: 25.0 + Double(lift)) : (x: 18.0, y: 26.0 + Double(lift))
    let steel = far ? C(0x5A606C) : C(0x9AA2AE), steelD = far ? C(0x464B55) : C(0x737B88)
    for i in 0..<6 {
        let fi = Double(i)
        let folded = 104 + fi * 3, open = (far ? 196 : 178) + fi * 9
        let a = (folded + (open - folded) * k) * .pi / 180
        let len = 11 + k * (far ? 7 : 10) - fi * k * 1.2
        let tip = (x: root.x + cos(a) * len, y: root.y + sin(a) * len)
        bar(c, root.x, root.y, tip.x, tip.y, i % 2 == 0 ? steel : steelD, 0.9)
        if !far && k > 0.5 { c.px(Int(tip.x.rounded()), Int(tip.y.rounded()), C(0xCC2630)) }
    }
}

// MARK: - Winter Soldier

/// The Winter Soldier (Bucky Barnes, the films): long dark hair, the black muzzle mask, dark tactical gear with
/// straps, and the silver bionic arm with its red star at the shoulder; an assault rifle. Signature: he slings the
/// rifle and flexes the metal arm, its plates rippling and catching the light.
private func drawWinterSoldier(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x23232A), strap = C(0x3E3E48), hair = C(0x3A2A1E), hairD = C(0x261A12)
    let metal = C(0xB4BAC4), metalD = C(0x7E8590), star = C(0xD0202A)
    let flex = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    if flex > 0 { bar(c, 13, 17, 18, 34, C(0x24262C), 0.9) }             // the rifle slung on his back
    drawBody(c, Look(arm: black, eye: nil))
    c.rect(21, 27, 4, 3, C(0x9A4E34)); c.rect(31, 27, 4, 3, C(0x9A4E34))  // dark round the eyes
    c.rect(22, 27, 2, 2, ink); c.rect(32, 27, 2, 2, ink)
    c.pattern(20, 31, ["KKKKKKKKKKKKKKKK", "KKKKKgKgKgKKKKKK", ".KKKKKKKKKKKKKK."], ["K": C(0x16161B), "g": C(0x4A4A54)])
    c.rect(18, 34, 20, 4, black); c.rect(18, 36, 20, 1, strap)
    bar(c, 19, 34, 25, 37.5, strap, 0.5)
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHhHHHHHHHH...",
        "..HHHHHHHHHhHHHHHHHHHH..",
        "..HHHHHHHHhHHHHHHHHHHH..",
        "..HHHHHHhhHHHHhhHHHHHH..",
        "..HHHhh...........HHHH..",
        "..HHH..............HHH..",
        "..HHH..............HHH..",
        "..HHH..............HHH..",
        "..HHHH............HHHH..",
        "..HHHH............HHHH..",
        "...HHH............HHH...",
        "...hH..............Hh...",
    ], ["H": hair, "h": hairD])
    // The metal shoulder with its star, and the arm
    c.rect(35, 32, 4, 3, metal); c.rect(35, 34, 4, 1, metalD)
    c.px(37, 32, star); c.px(36, 33, star); c.px(37, 33, star); c.px(38, 33, star)
    if flex > 0 {
        let up = Int((flex * 8).rounded())
        c.rect(38, 32, 6, 3, metal); c.rect(38, 34, 6, 1, metalD)          // upper arm out from the shoulder…
        c.rect(41, 32 - up, 3, up, metal)                                  // …the forearm curled up…
        c.rect(40, 29 - up, 5, 3, metal); c.rect(40, 31 - up, 5, 1, metalD)   // …and the clenched fist
        let shift = Int(p.t * 10) % 3                                      // plates sliding over each other
        for y in stride(from: 32 - up + shift, to: 32, by: 3) { c.rect(41, y, 3, 1, metalD) }
        for x in stride(from: 38 + shift, to: 44, by: 3) { c.px(x, 33, metalD) }
        if flex > 0.9, let s = p.signature { drawGlint(c, p: (s - 0.25) / 0.5, maxX: 44) }
        return
    }
    c.rect(38, 33, 3, 3, metal); c.rect(38, 34, 3, 1, metalD)
    c.oy += p.gunY
    c.pattern(37, 30, ["......SSS......", ".......K.......", "KK.KKKKKKKKKKKK", "KKKKKKkKkKKKKK.", "....KK..MM.....",
                       "....KK..MM....."],
              ["S": C(0x3A3C44), "K": C(0x24262C), "k": C(0x5A5E68), "M": C(0x3A3C44)])
    c.rect(38, 33, 3, 2, metal)                                            // the silver hand on the grip
}

// MARK: - Star-Lord

/// Star-Lord (Peter Quill, the films): the red-brown leather jacket and, in action, the gunmetal mask with its
/// glowing red eyes; resting, his face shows, sandy hair and the orange Walkman headphones round his neck. Twin
/// element blasters; jet boots when he flies. Signature: headphones on, he dances, notes floating up.
private func drawStarLord(_ c: PixelCanvas, _ p: Pose) {
    if p.flying { tilted(c, 14) { starLord($0, p) }; return }
    starLord(c, p)
}

private func starLord(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x8E2A22), jacketD = C(0x5E1A16), shirt = C(0x5A5A62), pants = C(0x3A2E26)
    let phones = C(0xE8862A), band = C(0x9AA0AA)
    let dance = p.signature.flatMap { $0 > 0.06 && $0 < 0.94 ? ($0 - 0.06) / 0.88 : nil }
    let masked = dance == nil && !(p.resting || p.seated)
    var beat = 0
    if let d = dance {
        beat = Int(d * 12) % 2
        c.ox += Int(d * 6) % 2 == 0 ? -1 : 1
        c.oy -= beat
    }
    drawLegs(c, Look(leg: pants), step: p.step)
    if p.flying {                                                         // jet boots
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let len = 2 + Int(noise(Int(p.t * 30) + i) * 3)
            c.rect(lx, 44, 2, len, C(0xFF8A2A)); c.rect(lx, 44, 2, 1, C(0xFFE8A0))
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket, eye: masked ? nil : ink), armLeft: dance != nil && beat == 0 ? 4 : 0,
             armRight: dance != nil && beat == 1 ? 4 : 0)
    c.rect(18, 32, 20, 6, jacket); c.rect(37, 32, 1, 6, jacketD)
    c.rect(25, 32, 6, 5, shirt)
    c.pattern(22, 32, ["KK......KK", ".KK....KK.", "..K....K..", "..K....K.."], ["K": jacketD])   // lapels
    c.rect(18, 37, 20, 1, C(0x3A2A1E)); c.rect(20, 36, 3, 2, phones)    // belt and the Walkman
    if masked {
        c.pattern(16, 18, [
            ".......MMMMMMMMMM.......",
            ".....MMMMMMssMMMMMM.....",
            "....MMMMMMMssMMMMMMM....",
            "...MMMMMMMMssMMMMMMMM...",
            "..MMMMMMMMMssMMMMMMMMM..",
            "..MMsMMMMMMssMMMMMMsMM..",
            ".MMMsMMMMMMssMMMMMMsMMM.",
            ".MMMsMMMMMMssMMMMMMsMMM.",
            ".MMMMMMMMMMssMMMMMMMMMM.",
            ".MMEEEEEMMMssMMMEEEEEMM.",
            ".MMMEEEEEMMssMMEEEEEMMM.",
            ".MMMMEEEMMMssMMMEEEMMMM.",
            ".MMMMMMMMMMssMMMMMMMMMM.",
            ".MMMMMMGGGGGGGGGGMMMMMM.",
            "..MMMMMGgGgGgGgGGMMMMM..",
            "...MMMMMMMMMMMMMMMMMM...",
        ], ["M": C(0x3A3E48), "s": C(0x8A909C), "E": C(0xFF3A2A), "G": C(0x26282E), "g": C(0x8A909C)])
    } else {
        c.pattern(17, 22, [
            "....HHHHHHHHHHHHH.....",
            "..HHHHHHHHhHHHHHHHH...",
            ".HHHHhHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHhHHHHHH.",
            ".HH.HHHHHHH...HHHH.HH.",
            ".H...H...........H..H.",
        ], ["H": C(0x9A6A3A), "h": C(0x7A4A26)])
        if dance != nil {                                                 // headphones on
            c.pattern(15, 20, [".....BBBBBBBBBBBBBBBB.....", "...BB................BB...", "..B....................B..",
                               ".B......................B.", ".B......................B.", "OOO....................OOO",
                               "OOO....................OOO", "OOO....................OOO", "OOO....................OOO"],
                      ["B": band, "O": phones])
        } else {                                                          // round his neck
            c.rect(19, 32, 18, 1, band); c.rect(18, 31, 3, 3, phones); c.rect(35, 31, 3, 3, phones)
        }
    }
    if let d = dance {
        for i in 0..<2 {                                                  // notes floating up
            let f = frac(d * 2 + Double(i) * 0.5)
            let x = 42 + i * 5 + Int(sin(f * 6) * 2), y = 22 - Int(f * 12)
            c.pattern(x, y, ["..K", "..K", "KKK", "KK."], ["K": (i == 0 ? C(0xFFE27A) : C(0xFF9AC8)).alpha(min(1, 2.2 - 2 * f))])
        }
        return
    }
    c.oy += p.gunY
    c.pattern(40, 30, [".SSSS....", "KKKKKKKKK", "KOKKKKKK.", "KK.......", "KK......."],
              ["K": C(0x3A3C44), "O": phones, "S": C(0xB08A4A)])
}

// MARK: - Gamora

/// Gamora (the films): green skin with silver marks under the eyes, dark hair falling to her shoulders with
/// magenta ends, black leather; the Godslayer sword, slung on her back when it's away. Signature: she twirls the
/// sword in her hand, three times round, and catches it.
private func drawGamora(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5FA05A), skinD = C(0x467C42), hair = C(0x2A1620), tips = C(0xC8305E), leather = C(0x26222A)
    var angle = p.melee, trail = p.trail, raise = 0
    if let s = p.signature, s > 0.1, s < 0.9 {
        raise = 7                                                         // twirled up high, clear of the floor
        let len = p.who.persona.signature ?? 2.4, t0 = p.t
        let spin = { (u: Double) -> Double in
            let k = min(1, max(0, (s + (u - t0) / len - 0.1) / 0.8))
            return -60 - 1080 * (0.5 - 0.5 * cos(k * .pi))
        }
        angle = spin(p.t); trail = saberTrail(p.t, pose: spin)
    }
    drawLegs(c, Look(leg: leather), step: p.step)
    c.oy += p.breathe
    if angle == nil {                                                    // the sword on her back, hilt up
        bar(c, 15, 21, 30, 40, C(0x9AA0AA), 0.7)
        bar(c, 13, 19, 16, 22, C(0x3A3040), 0.8); bar(c, 13, 23, 17, 20, C(0x3A3040), 0.6)
    }
    drawBody(c, Look(body: skin, shade: skinD, arm: leather), armRight: raise)
    c.px(21, 32, C(0xC8D0D8)); c.px(22, 33, C(0xC8D0D8)); c.px(34, 32, C(0xC8D0D8)); c.px(33, 33, C(0xC8D0D8))
    c.rect(18, 34, 20, 4, leather); c.rect(18, 35, 20, 1, C(0x4A4452))
    c.pattern(24, 33, ["K......K", ".KKKKKK."], ["K": leather])
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHhhHHH..",
        "..HHHHHhh........HHHH...",
        "..HHH..............HHH..",
        "..HHH..............HH...",
        "..HHH..............HH...",
        "..HHH..............HHT..",
        "..HHH..............HTT..",
        ".HHHT...............T...",
        ".HHTT...................",
        ".TTT....................",
        "..T.....................",
    ], ["H": hair, "h": C(0x4A2A3A), "T": tips])
    if let angle {
        c.oy -= raise
        drawBlade(c, angle: angle, trail: trail, length: raise > 0 ? 12 : 15, blade: C(0x9AA0AA), edge: C(0xE8ECF2),
                  grip: C(0x3A3040), curve: 1.5)
    }
}

// MARK: - Drax

/// Drax the Destroyer (the films): a bald, broad grey-green bruiser with red tribal markings carved over his head and
/// chest, bare-chested above dark trousers; a knife in each hand. Signature: he stands perfectly still, believing
/// himself invisible, and fades a little.
private func drawDrax(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { drax(c, p); return }
    var q = p
    q.breathe = 0
    stamp(c, offscreen { drax($0, q) }, alpha: 1 - 0.6 * habitArc(s, hold: 0.55))
}

private func drax(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8A989C), skinD = C(0x6A777B), mark = C(0xA8322A), pants = C(0x3A2E26), blade = C(0xC8CCD4)
    drawLegs(c, Look(leg: pants), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: skin))
    c.rect(16, 31, 2, 4, skin); c.rect(38, 31, 2, 2, skinD)               // broad shoulders
    c.rect(14, 32, 4, 4, skin); c.rect(38, 32, 4, 4, skin); c.rect(41, 32, 1, 4, skinD)
    c.rect(21, 28, 4, 1, skinD); c.rect(31, 28, 4, 1, skinD)              // heavy brow
    c.pattern(18, 26, ["...MMMM......MMMM...", "..M....M....M....M.."], ["M": mark])   // carved over the scalp
    c.pattern(17, 32, [                                                   // and across the chest
        ".MMMM..........MMMM...",
        ".....MM......MM.......",
        ".......MM..MM.........",
    ], ["M": mark])
    c.rect(18, 35, 20, 3, pants); c.rect(18, 35, 20, 1, C(0x5A4430)); c.rect(26, 35, 4, 1, C(0x8A7A5A))
    if let angle = p.melee {
        // The second knife, held up in the other hand
        bar(c, 15.5, 33, 15.5, 27, blade, 0.5); c.rect(14, 33, 3, 1, C(0x4A3A2A))
        drawBlade(c, angle: angle, trail: p.trail, length: 8, blade: blade, edge: white, grip: C(0x4A3A2A), curve: 1.5)
    } else {
        c.rect(20, 36, 1, 4, blade); c.rect(20, 35, 1, 1, C(0x4A3A2A))   // tucked in his belt
        c.rect(35, 36, 1, 4, blade); c.rect(35, 35, 1, 1, C(0x4A3A2A))
    }
}

// MARK: - Rocket

/// Rocket (the films): a raccoon, small and scruffy: pointed ears, the dark mask across his eyes, a pale muzzle, a
/// ringed tail, the navy flight suit with orange trim, and a gun much too big for him. Signature: he tips the gun up,
/// racks it, and grins.
private func drawRocket(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x8E6440), furD = C(0x6A4628), pale = C(0xE6D4B2), mask = C(0x3A2A20)
    let suit = C(0x2E3C68), suitD = C(0x222C4E), orange = C(0xE07A2A)
    if seatedPose { c.oy -= 2 }                                          // he's short: sits on the floor, not below it
    // The ringed tail, curling up behind him
    let tail: [(Double, Double)] = [(20, 39), (16, 38), (12, 35), (10, 31), (11, 27)]
    for i in 0..<tail.count - 1 {
        bar(c, tail[i].0, tail[i].1, tail[i + 1].0, tail[i + 1].1, i % 2 == 0 ? fur : mask, 1.8)
    }
    c.rect(10, 26, 2, 2, mask)
    // Short legs
    if seatedPose {
        for lx in [20, 24, 30, 34] { c.rect(lx - 1, 40, 4, 2, suitD) }
    } else {
        for (i, lx) in [21, 24, 31, 34].enumerated() {
            c.rect(lx, 39, 2, p.step >= 0 && i % 2 == p.step ? 4 : 5, suitD)
        }
    }
    c.oy += p.breathe
    c.pattern(20, 24, [
        "XX............XX",
        "XXX..........XXX",
        "XiXX........XXiX",
        "XiiXX......XXiiX",
        "XXXXX......XXXXX",
    ], ["X": fur, "i": C(0xC89A80)])
    c.rect(20, 29, 16, 11, fur); c.rect(35, 29, 1, 11, furD)
    c.rect(27, 29, 2, 2, pale)                                           // light stripe on the brow
    c.pattern(20, 31, [".MMMMMMMMMMMMMM.", "MMEEMMMMMMMEEMMM", "MMEkMMMMMMMEkMMM", ".MMMMMMMMMMMMMM."],
              ["M": mask, "E": C(0xF0E2C8), "k": ink])
    c.rect(21, 35, 15, 2, pale)                                          // cheeks
    c.rect(33, 33, 5, 3, pale); c.rect(37, 33, 2, 2, ink)               // muzzle and nose
    let s = p.signature
    if let s, s > 0.55, s < 0.95 { c.rect(32, 36, 5, 1, white); c.px(34, 36, C(0xB0A090)) }   // the grin
    else { c.rect(33, 36, 3, 1, furD) }
    c.rect(20, 37, 16, 3, suit); c.rect(20, 37, 16, 1, orange); c.rect(35, 37, 1, 3, suitD)
    // The big gun, and the paw under it
    let tip = s.map { habitArc($0, hold: 0.4) } ?? 0
    let rack = s.map { $0 > 0.4 && $0 < 0.55 } ?? false
    let gun = PixelCanvas(26, 8)
    c.oy += p.gunY
    rocketGun(gun, rack: rack)
    if tip > 0 {
        c.paste(gun.rotated(-28 * tip, about: (5, 4.5), into: 34, 34, at: (17, 17)), x: 33 - 17, y: 22)
    } else {
        c.paste(gun, x: 28, y: 35)
    }
    c.rect(31, 38, 3, 3, fur)
}

/// Rocket's oversized blaster rifle: scope, long barrel with a violet-glowing tip, grip and power cell.
private func rocketGun(_ c: PixelCanvas, rack: Bool) {
    c.pattern(0, 0, [
        ".......SSSSS..............",
        "........K..K..............",
        "KKKKKKKKKKKKKKKKKKKKKKKKPP",
        "KKKkKkKKGGGKKKKKKKKKKKKKKP",
        "...KKK....CC..KKKK........",
        "...KK.....CC..............",
    ], ["S": C(0x3A3C44), "K": C(0x4A4E58), "k": C(0x8A909C), "G": C(0xE07A2A), "P": C(0xC89AFF), "C": C(0x9A4AFF)])
    c.rect(rack ? 12 : 14, 4, 4, 1, C(0x2A2C32))                           // the pump slide, racked back
}

// MARK: - Groot

/// Groot (the films): a tall tree-man, taller than Clawd: a domed bark head with twigs on top, deep-set eyes,
/// broad shoulders with moss, long branch arms and root feet, bark grain all over. He lashes out with a branch arm
/// that grows as it swings. Signature: he sprouts leaves and little flowers and sways in a happy dance.
private func drawGroot(_ c: PixelCanvas, _ p: Pose) {
    let bark = C(0x7A5634), barkD = C(0x573A20), barkL = C(0x9A7448), moss = C(0x6A9A3A)
    var bloom = 0.0
    if let s = p.signature {
        bloom = habitArc(s, hold: 0.6)
        if s > 0.15, s < 0.85 { c.ox += sin((s - 0.15) / 0.7 * 6 * .pi) > 0 ? 1 : -1 }
    }
    drawLegs(c, Look(leg: barkD), step: p.step)
    c.oy += p.breathe
    // The left arm, hanging behind
    c.rect(14, 23, 3, 13, barkD); c.rect(13, 35, 1, 2, barkD); c.rect(15, 36, 1, 2, barkD)
    c.rect(16, 22, 24, 4, bark)                                          // shoulders
    c.rect(18, 22, 20, 16, bark); c.rect(37, 22, 1, 16, barkD); c.rect(18, 37, 20, 1, barkD)
    for (x, y, h) in [(20, 25, 7), (23, 29, 6), (26, 24, 5), (29, 31, 6), (32, 26, 8), (35, 29, 5), (21, 33, 4)] {
        c.rect(x, y, 1, h, barkD)                                        // grain
    }
    c.rect(27, 34, 2, 2, barkD); c.px(27, 34, barkL)                     // a knot
    c.rect(16, 22, 5, 1, moss); c.rect(35, 22, 4, 1, moss); c.px(17, 23, moss)
    c.pattern(21, 7, [
        "..t.....t..t..",
        "..t..t..t.t...",
        "...tt.t.tt....",
        "...BBBBBBBB...",
        "..BBBBBBBBBB..",
        ".BBBBdBBBBBBB.",
        ".BBBBBBBBBdBBB",
        "BBBdBBBBBBBBBB",
        "BWWWBBBBBBWWWB",
        "BBEEBBBBBBEEBB",
        "BBEEBBBBBBEEBB",
        "BBBBBBBBBBBBBB",
        "BBBBBdddBBBBBB",
        "BBBBBBBBBBBBBB",
        ".BBBBBBBBBBBBd",
        "..BBBBBBBBBB..",
    ], ["t": barkD, "B": bark, "d": barkD, "W": barkL, "E": ink])
    c.px(23, 16, C(0x8A5A2A)); c.px(31, 16, C(0x8A5A2A))                 // amber glints in the eyes
    // Leaves and flowers, sprouting as he blooms (one little leaf always)
    let buds: [(Int, Int, Bool)] = [(25, 8, false), (30, 6, true), (19, 22, false), (36, 21, true), (22, 10, true),
                                    (34, 10, false), (17, 25, true), (28, 5, false), (38, 24, false), (24, 22, true)]
    let shown = 1 + Int(bloom * Double(buds.count - 1) + 0.5)
    for (x, y, flower) in buds.prefix(shown) {
        if flower {
            c.pattern(x - 1, y - 1, [".P.", "PYP", ".P."], ["P": C(0xFFB0D0), "Y": C(0xFFE27A)])
        } else {
            c.rect(x, y, 2, 1, C(0x7CC04A)); c.px(x + 1, y - 1, C(0x9AE060))
        }
    }
    // The right arm: hanging, or a branch lashing out from the shoulder
    if let angle = p.melee {
        let sh = (x: 40.5, y: 25.5)
        for (i, a) in p.trail.enumerated() {
            let e = along(a, 15, from: sh)
            bar(c, sh.x, sh.y, e.x, e.y, bark.alpha(0.3 / Double(i + 1)), 1.2)
        }
        let e = along(angle, 15, from: sh)
        bar(c, sh.x - 1, sh.y, e.x, e.y, bark, 1.3)
        for spread in [-35.0, 0, 35] {                                    // twig fingers
            let f = along(angle + spread, 3.5, from: e)
            bar(c, e.x, e.y, f.x, f.y, barkD, 0.5)
        }
    } else {
        c.rect(39, 23, 3, 12, bark); c.rect(41, 23, 1, 12, barkD)
        c.px(39, 35, barkD); c.px(41, 35, barkD); c.px(39, 36, barkD); c.px(42, 36, barkD)
    }
}

// MARK: - Mantis

/// Mantis (the films): pale skin, big black eyes, long straight black hair with a fringe, the green outfit, and two
/// antennae with glowing tips. Signature: her antennae light up and pulse as she senses the feelings around her.
private func drawMantis(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xEDE2C8), skinD = C(0xC8BCA0), green = C(0x3E7A4A), greenD = C(0x2C5A36), hair = C(0x16141A)
    let glow = C(0xEFFF9A)
    drawLegs(c, Look(leg: greenD), step: p.step)
    c.oy += p.breathe
    c.rect(16, 27, 3, 10, hair); c.rect(37, 27, 3, 10, hair)             // hair falling behind her shoulders
    drawBody(c, Look(body: skin, shade: skinD, arm: green, eye: nil))
    c.rect(22, 28, 3, 3, ink); c.rect(31, 28, 3, 3, ink)                 // big black eyes
    c.px(22, 28, C(0x7A7A88)); c.px(31, 28, C(0x7A7A88))
    c.rect(18, 33, 20, 5, green); c.rect(37, 33, 1, 5, greenD)
    c.pattern(23, 33, ["G........G", ".GGGGGGGG."], ["G": C(0xC8A84A)])   // gold collar
    c.rect(18, 37, 20, 1, greenD)
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHhhHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHH..............HHH..",
        "..HH................HH..",
        "..HH................HH..",
        "..HH................HH..",
        "..HH................HH..",
    ], ["H": hair, "h": C(0x3A3446)])
    // Antennae, and their glowing tips
    let pulse = p.signature.map { s -> Double in s > 0.1 && s < 0.9 ? 0.5 + 0.5 * sin((s - 0.1) * 30) : 0 } ?? 0
    let lit = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    for (a, b, tip) in [((24.0, 21.0), (21.0, 15.0), (20.0, 13.0)), ((31.0, 21.0), (34.0, 15.0), (35.0, 13.0))] {
        bar(c, a.0, a.1, b.0, b.1, hair, 0.45); bar(c, b.0, b.1, tip.0, tip.1, hair, 0.45)
        if lit > 0 {
            c.glowLine(tip.0 + 0.5, tip.1, tip.0 + 0.5, tip.1, core: white, glow: glow, coreR: 0.8 + lit * 0.4,
                       glowR: 1.8 + lit * (1.5 + pulse * 1.5), strength: 0.6 + 0.4 * lit)
        }
        c.rect(Int(tip.0), Int(tip.1) - 1, 2, 2, lit > 0.3 ? white : glow)
    }
    if lit > 0.5, let s = p.signature {                                  // sparkles drifting off
        for i in 0..<3 {
            let f = frac(s * 3 + Double(i) / 3)
            twinkle(c, 18 + i * 9 + Int(sin(f * 5) * 2), 14 - Int(f * 8), glow.alpha(1 - f))
        }
    }
}

// MARK: - Nick Fury

/// Nick Fury (the films): bald, the black eyepatch with its strap across his head, a goatee, a black turtleneck and
/// the long black leather coat; a pistol. Signature: he puts a gloved finger to the eyepatch and sets it straight.
private func drawNickFury(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x7A5038), skinD = C(0x5E3C28), coat = C(0x1C1C22), coatL = C(0x3A3A44), patch = C(0x0E0E12)
    drawLegs(c, Look(leg: C(0x34343C)), step: p.step)
    c.oy += p.breathe
    for y in 36...40 where y + c.oy <= 43 {                               // the coat's skirt, flaring a little
        let k = (y - 36) / 2
        c.rect(18 - k, y, 20 + k * 2, 1, coat); c.px(18 - k, y, coatL); c.px(37 + k, y, coatL)
    }
    c.rect(27, 38, 1, 3, coatL)                                           // the coat's opening
    drawBody(c, Look(body: skin, shade: skinD, arm: coat, eye: nil))
    c.rect(23, 26, 3, 1, C(0x9A6A4A))                                     // a shine on the bald head
    c.rect(21, 28, 4, 1, skinD); c.rect(22, 29, 2, 3, ink)
    let adjust = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let nudge = adjust > 0.9 && Int((p.signature ?? 0) * 14) % 2 == 0 ? 1 : 0
    bar(c, 18, 26.5, 31, 28.5 + Double(nudge), patch, 0.5)                // the strap…
    c.rect(31, 28 + nudge, 4, 4, patch)                                   // …and the patch
    c.pattern(25, 32, ["K....K", "KKKKKK", ".KKKK."], ["K": C(0x2A1E18)])  // goatee
    c.rect(26, 33, 4, 1, C(0x5A3424))
    c.rect(18, 35, 20, 3, coat); c.rect(37, 35, 1, 3, coatL)
    c.pattern(18, 34, ["LLL..KKKKKKKKKK..LLL", ".LLL.KKKKKKKKKK.LLL.", "..LL...........LL..."],
              ["L": coatL, "K": patch])                                   // collar and turtleneck
    if adjust > 0 {                                                       // the hand comes up to the patch
        let up = Int((adjust * 6).rounded())
        c.rect(37, 33 - up, 3, 3 + up, coat)
        c.rect(34, 33 - up, 4, 3, coat); c.rect(34, 33 - up, 4, 1, coatL)   // the gloved fingers, knuckles lit
        return
    }
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 31, body: C(0x1E1E24), trim: C(0x9AA0AA))
}

// MARK: - She-Hulk

/// She-Hulk (Jennifer Walters, the classic comics): green skin, a mane of dark green hair, the purple-and-white
/// leotard; she fights with her fists. Signature: she laces her fingers and cracks her knuckles.
private func drawSheHulk(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x55AE4C), greenD = C(0x3E8A3A), hair = C(0x24502A), hairL = C(0x3A7A40)
    let purple = C(0x6E2E92), purpleD = C(0x4E1E6E), suitWhite = C(0xF0EEF4)
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose {                                                      // purple boots
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 41 : 42, 2, 2, purple) }
    }
    c.oy += p.breathe
    c.rect(15, 25, 4, 12, hair); c.rect(14, 28, 1, 8, hair); c.rect(37, 25, 3, 9, hair)   // the mane, behind
    drawBody(c, Look(body: green, shade: greenD, arm: green))
    c.rect(18, 32, 20, 6, purple); c.rect(37, 32, 1, 6, purpleD)
    c.rect(18, 32, 3, 6, suitWhite); c.rect(35, 32, 2, 6, suitWhite)      // white side panels
    c.rect(18, 36, 20, 1, suitWhite)                                      // white belt
    c.rect(14, 32, 4, 4, green); c.rect(38, 32, 4, 4, green); c.rect(41, 32, 1, 4, greenD)   // strong arms
    c.pattern(15, 20, [
        "........HHHHHHHHHH........",
        ".....HHHHHHHHHHHHHHHH.....",
        "...HHHHHHHLLLHHHHHHHHH....",
        "..HHHHHHHHHHHLLLHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHLLHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHH.........HHHHHH..",
        "HHHHH...............HHH...",
        "HHHH.................HH...",
        "HHH..................HH...",
    ], ["H": hair, "L": hairL])
    if let s = p.signature, s > 0.1, s < 0.9 {
        // Fingers laced in front of her, a pop on every crack
        c.rect(16, 33, 10, 2, green); c.rect(30, 33, 9, 2, green)
        c.rect(25, 31, 7, 4, green); c.rect(25, 31, 7, 1, greenD); c.rect(28, 31, 1, 4, greenD)
        c.rect(22, 30, 3, 1, ink); c.rect(32, 30, 3, 1, ink)             // eyes narrowed
        c.rect(22, 29, 3, 1, green); c.rect(32, 29, 3, 1, green); c.rect(22, 31, 3, 1, green); c.rect(32, 31, 3, 1, green)
        for pop in [0.3, 0.5, 0.7] where abs(s - pop) < 0.05 {
            c.px(28, 28, white); c.px(25, 29, white); c.px(31, 29, white); c.px(24, 28, white.alpha(0.6))
            c.px(32, 28, white.alpha(0.6))
        }
        return
    }
    drawPunch(c, angle: p.melee, trail: p.trail, arm: green, fist: green, reach: 8, size: 4)
}
