import Foundation

// Villains: the TVA, the Morlock Tunnels, Asteroid M, Ta Lo and the Red Room.

let villains9: [MarvelVillain: Persona] = [
    .missMinutes: Persona(name: "Miss Seconds", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFF0D0), glow: C(0xFF9A1E), jagged: false), canSit: false,
                  headTop: 17, signature: 3.0, callout: "Hey y'all!",
                  draw: drawMissMinutes),
    .callisto: Persona(name: "Kallisto", weapon: .saber, headTop: 17, signature: 3.0,
                  draw: drawCallisto),
    .exodus: Persona(name: "Exodos", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFE0F0), glow: C(0xE84A9A), jagged: false),
                  headTop: 16, signature: 3.0,
                  draw: drawExodus),
    .soulEater: Persona(name: "Soul Muncher", weapon: .saber, motion: .fly, canSit: false, headTop: 15, signature: 3.2,
                  draw: drawSoulEater),
    .redRoomWidow: Persona(name: "Red Room Window", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 20, signature: 2.8,
                  draw: drawRedRoomWidow),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A round-ended stroke from (`x0`, `y0`) to (`x1`, `y1`), `r` thick.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// Faint smears behind a fast melee swing, `from`…`to` pixels out from `pivot`.
private func swingTrail(_ c: PixelCanvas, _ pivot: (x: Double, y: Double), _ trail: [Double], from: Double, to: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(pivot.x + cos(r) * from, pivot.y + sin(r) * from, pivot.x + cos(r) * to, pivot.y + sin(r) * to,
                   core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// Clawd's four legs, each `col`, with `boot` rows of `boot` colour at the bottom.
private func legsWithBoots(_ c: PixelCanvas, _ p: Pose, _ col: Px, boot: Px, rows: Int) {
    drawLegs(c, Look(leg: col), step: p.step)
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, boot)
    }
}

// MARK: - Miss Minutes

/// Miss Minutes, the TVA's cartoon mascot: Clawd rounded off into a big orange desk clock, a cream dial for a face
/// with hour ticks round the rim and a winding knob on top, huge lashed cartoon eyes, rosy cheeks and a red-lipped
/// southern-belle smile; spindly black arms and legs, white cartoon gloves and shoes. She floats, casting orange TVA
/// magic from her glove. Signature: her clock hands appear and spin round her face, and she gives you a wink.
private func drawMissMinutes(_ c: PixelCanvas, _ p: Pose) {
    let orange = C(0xF08A1E), rim = C(0xB85A10), dial = C(0xFFC25A), tick = C(0x8A4010)
    let limb = C(0x1E1A1A), glove = C(0xF4EEE2), gloveEdge = C(0xA8A090)
    let sig = p.signature
    // Spindly legs and little white shoes.
    for (i, lx) in [24, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 38, 1, 5 - up, limb)
        c.rect(lx - 1, 42 - up, 4, 2, glove); c.rect(lx - 1, 43 - up, 4, 1, gloveEdge)
    }
    c.oy += p.breathe
    let cx = 28, cy = 29
    // Arms: thin black lines out to the gloves.
    let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(p.armRaise))
    stick(c, 19, 31, 14, 35, limb, 0.5)
    stick(c, 37, 31, hand.x - 1, hand.y, limb, 0.5)
    c.rect(12, 34, 3, 3, glove); c.px(12, 36, gloveEdge); c.px(14, 36, gloveEdge)
    c.rect(Int(hand.x) - 1, Int(hand.y) - 1, 3, 3, glove)
    c.px(Int(hand.x) - 1, Int(hand.y) + 1, gloveEdge); c.px(Int(hand.x) + 1, Int(hand.y) + 1, gloveEdge)
    // The winding knob, then the clock body: rim, case, dial.
    c.rect(cx - 1, 16, 3, 2, rim); c.rect(cx - 2, 15, 5, 1, orange)
    c.circle(cx, cy, 11, rim)
    c.circle(cx, cy, 10, orange)
    c.circle(cx, cy, 8, dial)
    c.rect(cx - 6, cy - 7, 3, 1, C(0xFFE0A0)); c.rect(cx - 7, cy - 6, 1, 2, C(0xFFE0A0))     // shine on the dial
    for (x, y, w, h) in [(cx, cy - 8, 1, 2), (cx + 7, cy, 2, 1), (cx, cy + 7, 1, 2), (cx - 8, cy, 2, 1)] as [(Int, Int, Int, Int)] {
        c.rect(x, y, w, h, tick)
    }
    // Signature: clock hands spinning round her face (under the eyes, so she stays readable).
    if let s = sig {
        let k: Double = s < 0.75 ? s / 0.75 : 1
        let spin: Double = 1 - pow(1 - k, 2)
        let minute: Double = (-90 + spin * 1080) * .pi / 180, hour: Double = (-90 + spin * 270) * .pi / 180
        let o = (x: Double(cx) + 0.5, y: Double(cy) + 0.5)
        stick(c, o.x, o.y, o.x + cos(minute) * 7, o.y + sin(minute) * 7, tick, 0.45)
        stick(c, o.x, o.y, o.x + cos(hour) * 4.5, o.y + sin(hour) * 4.5, tick, 0.6)
        c.rect(cx, cy, 1, 1, C(0xC8202A))
    }
    // Big cartoon eyes looking your way, lashes flicked up at the outer corners.
    let wink = sig.map { $0 > 0.62 && $0 < 0.9 } ?? false
    let blink = !wink && !p.walking && frac(p.lt / 4.1) < 0.03
    for (i, ex) in [23, 30].enumerated() {
        if (wink && i == 1) || blink {
            c.rect(ex, 28, 4, 1, limb); c.px(ex - 1, 27, limb); c.px(ex + 4, 27, limb)
        } else {
            c.rect(ex, 24, 4, 5, C(0xFFFFFF)); c.rect(ex, 24, 4, 1, C(0xE8E0D0))
            c.rect(ex + 1, 25, 1, 4, C(0xFFFFFF))
            c.rect(ex + 2, 26, 2, 3, limb)
            c.px(ex + 2, 26, C(0xFFFFFF))
            c.rect(i == 0 ? ex : ex + 1, 23, 3, 1, limb)                     // the upper lid
        }
        let outer = i == 0 ? ex - 1 : ex + 4
        c.px(outer, 23, limb); c.px(outer, 22, limb)
        c.px(i == 0 ? ex - 2 : ex + 5, 22, limb)
    }
    c.rect(21, 30, 2, 1, C(0xFF7A6A)); c.rect(34, 30, 2, 1, C(0xFF7A6A))             // rosy cheeks
    // The red-lipped smile.
    c.rect(25, 33, 7, 1, C(0xC8202A)); c.px(24, 32, C(0xC8202A)); c.px(32, 32, C(0xC8202A))
    c.rect(26, 34, 5, 1, C(0xE84A4A))
    c.rect(26, 33, 5, 1, C(0x6A1018))
    if p.zap != nil {
        c.glowLine(hand.x, hand.y, hand.x, hand.y, core: C(0xFFF0D0), glow: C(0xFF9A1E), coreR: 0.6, glowR: 2.4)
    }
}

// MARK: - Callisto

/// Callisto, leader of the Morlocks: a pale Clawd in black leather (a studded vest, a belt with a knife sheath) under
/// a wild mane of black hair, a black patch over her front eye on a strap across her brow, and a long knife. Signature:
/// she sniffs the air, scent curling into her nose, then flips the knife up spinning and catches it.
private func drawCallisto(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE2C2AA), skinDark = C(0xB8987E), leather = C(0x2A2428), leatherLight = C(0x4A4046), stud = C(0x9A9AA6)
    let hair = C(0x16141A), hairLight = C(0x34303C)
    legsWithBoots(c, p, C(0x4A3E44), boot: C(0x111014), rows: 3)
    c.oy += p.breathe
    let sig = p.signature
    let sniffing = sig.map { $0 > 0.05 && $0 < 0.45 } ?? false
    let tilt = sniffing && sin((sig ?? 0) * 60) > 0 ? -1 : 0                 // her head twitches as she sniffs
    drawBody(c, Look(body: skin, shade: skinDark, arm: leather, eye: nil))
    // Leather vest with studs, and the belt.
    c.rect(18, 34, 20, 4, leather)
    c.rect(18, 34, 20, 1, leatherLight)
    for x in stride(from: 20, through: 36, by: 4) { c.px(x, 35, stud) }
    c.rect(18, 36, 20, 1, C(0x5A3A26)); c.rect(27, 36, 2, 1, stud)
    c.rect(37, 34, 1, 4, C(0x18161A))
    // Eyes: one fierce eye, the front one under the patch.
    if tilt != 0 { c.rect(19, 25, 18, 1, hair) }                            // no gap under the mane as her head lifts
    c.oy += tilt
    c.rect(22, 29, 2, 3, ink)
    c.px(21, 28, ink); c.px(22, 28, ink)                                     // a scowling brow
    c.pattern(30, 28, ["PPPPP", "PPPPP", ".PPP."], ["P": C(0x0C0C10)])
    c.rect(19, 27, 19, 1, C(0x0C0C10))                                       // the strap
    c.rect(25, 32, 5, 1, C(0xA86A5A))
    // The mane: wild, spiky, falling past her shoulders.
    c.pattern(13, 17, [
        "........H..H....H.........",
        "......HHH.HHH..HHH..H.....",
        "....H.HHHHHHHHHHHHHHHH.H..",
        "...HHHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHhHHHHHHHhHHHHHHHH.",
        ".HHHHHhHHHHHHHHHHHHHhHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHH...........HHHHHHH.",
        "HHHHHH..............HHHH..",
        ".HHHHH...............HH...",
        "HHHHH.....................",
        ".HHHH.....................",
        "HHHH......................",
        ".HHH......................",
        "..HH......................",
        "..H.......................",
    ], ["H": hair, "h": hairLight])
    c.oy -= tilt
    if sniffing, let s = sig {
        // Scent drifting in to her nose.
        for k in 0..<3 {
            let f: Double = frac(s * 4 + Double(k) / 3)
            let x: Double = 50 - f * 11, y: Double = 26 + Double(k) * 2
            let w: Double = sin(f * 8 + Double(k) * 2) * 1.2
            let col = C(0xC8D88A).alpha(0.9 * (1 - f * 0.5))
            c.glowLine(x, y + w, x + 3, y - w, core: col, glow: C(0x8AA84A).alpha(0.4), coreR: 0.4, glowR: 1.2)
        }
    }
    // Signature, second half: the knife goes up spinning and comes back down into her hand.
    if let s = sig, s >= 0.45 && s < 0.95 {
        let f: Double = (s - 0.45) / 0.5
        let up: Double = sin(f * .pi) * 14
        let h = (x: Sprite.hand.x, y: Sprite.hand.y - up)
        c.rect(38, 31, 3, 3, leather)                                        // hand up to catch it
        drawKnife(c, at: h, angle: -90 + f * 720, trail: [])
        return
    }
    guard let a = p.melee else {
        c.rect(19, 35, 2, 5, C(0x3A2A20)); c.rect(19, 35, 2, 1, C(0x8A8E98))   // the knife in its sheath
        return
    }
    swingTrail(c, Sprite.hand, p.trail, from: 3, to: 10, C(0xD8DCE4))
    drawKnife(c, at: Sprite.hand, angle: a, trail: p.trail)
}

/// Callisto's long knife, its grip at `at`, pointing `angle` degrees.
private func drawKnife(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, trail: [Double]) {
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    stick(c, h.x - ux * 1.5, h.y - uy * 1.5, h.x + ux * 1.5, h.y + uy * 1.5, C(0x4A3020), 0.7)
    stick(c, h.x - uy * 1.5 + ux * 2, h.y + ux * 1.5 + uy * 2, h.x + uy * 1.5 + ux * 2, h.y - ux * 1.5 + uy * 2, C(0x6A6E78), 0.45)
    stick(c, h.x + ux * 2.5, h.y + uy * 2.5, h.x + ux * 9, h.y + uy * 9, C(0xB8BCC8), 0.65)
    stick(c, h.x + ux * 3, h.y + uy * 3, h.x + ux * 8, h.y + uy * 8, C(0xE8ECF4), 0.3)
}

// MARK: - Exodus

/// Exodus, Magneto's fanatical acolyte: a tall, bald, stern Clawd (the dome rises high) with a long dark ponytail
/// sprouting from his crown and streaming down his back, in maroon armour with a high flared gold collar framing his
/// jaw, gold shoulder plates, a gold chevron on the chest and gold boots. He floats and casts pink psionic force.
/// Signature: a pink psionic halo blooms over his head and his eyes blaze.
private func drawExodus(_ c: PixelCanvas, _ p: Pose) {
    let maroon = C(0x6A1A3A), maroonDark = C(0x4A1028), maroonLight = C(0x8E2A50), gold = C(0xE8B530), goldDark = C(0xB0841E)
    let skin = C(0xE6C0A0), skinDark = C(0xC09A7C), hair = C(0x2A1E1A), hairLight = C(0x5A4232)
    let glow = C(0xE84A9A), glowCore = C(0xFFE0F0)
    let sig = p.signature
    let halo: Double = sig.map { habitArc($0, hold: 0.5) } ?? 0
    legsWithBoots(c, p, maroon, boot: gold, rows: 3)
    c.oy += p.breathe
    // The ponytail: from the crown, arching back and down behind him.
    let sway: Double = sin(p.lt * 2.2) * 1.2 + (p.flying ? -2 : 0)
    let pts: [(Double, Double)] = [(26, 17), (22, 16.5), (18, 18), (15, 21), (13, 25), (12, 29), (12, 33), (13, 36)]
    for k in 0..<(pts.count - 1) {
        let f0 = Double(k) / Double(pts.count - 1), f1 = Double(k + 1) / Double(pts.count - 1)
        let a = (x: pts[k].0 + sway * f0 * f0, y: pts[k].1), b = (x: pts[k + 1].0 + sway * f1 * f1, y: pts[k + 1].1)
        stick(c, a.x, a.y, b.x, b.y, hair, 1.25 - f1 * 0.45)
        if k % 2 == 1 { c.px(Int(a.x), Int(a.y), hairLight) }
    }
    drawBody(c, Look(body: maroon, shade: maroonDark, arm: maroon, eye: nil), armRight: p.armRaise)
    // The tall bald head, down to the collar.
    c.pattern(18, 17, [
        "......SSSSSSSS......",
        "....SSSSSSSSSSSS....",
        "...SSSSSSSSSSSSSSS..",
        "..SSSSSSSSSSSSSSSSs.",
        ".SSSSSSSSSSSSSSSSSs.",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
        "SSSSSSSSSSSSSSSSSSSs",
    ], ["S": skin, "s": skinDark])
    c.rect(23, 18, 4, 1, C(0xF6DCC4)); c.rect(21, 19, 2, 2, C(0xF6DCC4))         // shine on the dome
    c.rect(25, 16, 3, 2, gold)                                                  // the band round the topknot
    // Stern brows over deep-set eyes, which blaze pink in the signature.
    c.rect(21, 23, 4, 1, hair); c.rect(31, 23, 4, 1, hair)
    if halo > 0.3 {
        for ex in [22, 32] {
            c.glowLine(Double(ex) + 1, 26.5, Double(ex) + 1, 26.5, core: glowCore, glow: glow, coreR: 1.2, glowR: 2.6 * halo)
        }
    } else {
        c.rect(22, 25, 2, 3, ink); c.rect(32, 25, 2, 3, ink)
    }
    c.rect(26, 29, 5, 1, C(0x9A6A5A))                                           // a hard mouth
    // Armour: the flared collar round the jaw, shoulder plates, the chest chevron.
    c.pattern(15, 25, [
        "GG.....................GG",
        "GGg...................gGG",
        ".Gg...................gG.",
        ".Gg...................gG.",
        ".Gg...................gG.",
        "..GGGGGGGGGGGGGGGGGGGGG..",
        "MMMggggggggggggggggggMMMM",
    ], ["G": gold, "g": goldDark, "M": maroon])
    c.rect(18, 32, 20, 6, maroon)
    c.rect(18, 37, 20, 1, maroonDark); c.rect(37, 32, 1, 6, maroonDark)
    c.rect(18, 32, 1, 5, maroonLight)
    c.pattern(23, 32, ["G........G", ".G......G.", "..GG..GG..", "....GG...."], ["G": gold])
    c.rect(18, 36, 20, 1, goldDark)
    c.rect(15, 32, 3, 3, gold); c.rect(15, 34, 3, 1, goldDark)                    // shoulder plates over the arms
    c.rect(38, 32 - p.armRaise, 3, 2, gold)
    // Signature: the psionic halo blooms over his head, sparks drifting up off it.
    if halo > 0.02 {
        let r: Double = 4 + halo * 6
        let hy: Double = 13 - halo * 2
        let n = 18
        for i in 0..<n {
            let a0 = Double(i) / Double(n) * 2 * .pi + p.t * 1.5, a1 = Double(i + 1) / Double(n) * 2 * .pi + p.t * 1.5
            c.glowLine(28 + cos(a0) * r, hy + sin(a0) * r * 0.32, 28 + cos(a1) * r, hy + sin(a1) * r * 0.32,
                       core: glowCore.alpha(halo), glow: glow.alpha(0.8 * halo), coreR: 0.4, glowR: 1.5)
        }
        for k in 0..<4 {
            let f: Double = frac(p.t * 0.9 + Double(k) / 4)
            let x = 28 + cos(Double(k) * 1.7) * r * 0.9
            c.px(Int(x), Int(hy - 1 - f * 8), glow.alpha(halo * (1 - f)))
        }
    }
    if p.zap != nil {
        let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(p.armRaise))
        c.glowLine(hand.x, hand.y, hand.x, hand.y, core: glowCore, glow: glow, coreR: 0.7, glowR: 2.6)
    }
}

// MARK: - Soul Eater

/// A soul eater from Ta Lo, the Dweller-in-Darkness's swarm: a faceless, ink-dark Clawd with a ridged dome where
/// a face should be, bat wings folded on its back (spread wide in flight), and writhing tentacles for legs; it lashes
/// out with a hooked tentacle. Signature: it unfolds its wings, its front splits into a glowing maw and pale wisps of
/// souls stream in.
private func drawSoulEater(_ c: PixelCanvas, _ p: Pose) {
    let body = C(0x26242E), shade = C(0x16151C), ridge = C(0x4A4458), membrane = C(0x4A2E48), bone = C(0x7A6A88)
    let sig = p.signature
    let unfold: Double = sig.map { habitArc($0, hold: 0.55) } ?? 0
    let spread: Double = p.flying ? 1 : unfold
    let flap: Double = p.flying ? sin(p.t * 14) * 4 : sin(p.lt * 1.7) * 0.6
    // Bat wings on its back: folded into two tall hooked peaks, or unfolded wide.
    typealias Pt = (x: Double, y: Double)
    let wings: [(root: Pt, folded: Pt, open: Pt, foldedLow: Pt, openLow: Pt, side: Double)] = [
        ((22, 25), (11, 12), (1, 15), (8, 33), (12, 32), -1), ((30, 24), (21, 9), (50, 12), (14, 28), (40, 31), 1),
    ]
    for w in wings {
        let tip = (x: w.folded.x + (w.open.x - w.folded.x) * spread, y: w.folded.y + (w.open.y - w.folded.y) * spread + flap * spread)
        let low = (x: w.foldedLow.x + (w.openLow.x - w.foldedLow.x) * spread, y: w.foldedLow.y + (w.openLow.y - w.foldedLow.y) * spread)
        // membrane: a fan between the arm and the lower edge, scalloped between three finger bones
        for k in 0...10 {
            let f = Double(k) / 10
            let scallop: Double = abs(sin(f * .pi * 3)) * 2.2 * (0.4 + spread)
            let ex = tip.x + (low.x - tip.x) * f, ey = tip.y + (low.y - tip.y) * f - scallop * 0.4
            stick(c, w.root.x, w.root.y, ex, ey, membrane, 0.9)
        }
        for f in [0.0, 0.34, 0.67] {
            let ex = tip.x + (low.x - tip.x) * f, ey = tip.y + (low.y - tip.y) * f
            stick(c, w.root.x, w.root.y, ex, ey, f == 0 ? bone : ridge, f == 0 ? 0.65 : 0.4)
        }
        c.px(Int(tip.x), Int(tip.y) - 1, bone); c.px(Int(tip.x) + Int(w.side), Int(tip.y) - 2, bone)   // the hooked claw
    }
    // Tentacles for legs: thick, writhing, curling at the tips.
    for (i, lx) in [20, 24, 31, 35].enumerated() {
        let ph = p.lt * 4 + Double(i) * 1.3
        var prev = (x: Double(lx), y: 35.0)
        let len: Double = p.flying ? 7 : 8
        for k in 1...5 {
            let f = Double(k) / 5
            let q = (x: Double(lx) + sin(ph + f * 3) * 1.6 * f - (p.flying ? f * 4 : 0), y: 35 + f * len)
            stick(c, prev.x, prev.y, q.x, q.y, k < 4 ? body : ridge, 2.0 - f * 1.2)
            prev = q
        }
    }
    c.oy += p.breathe
    // The body, faceless: a ridged, spiny dome where a face should be.
    c.rect(18, 26, 20, 11, body)
    c.rect(18, 36, 20, 1, shade); c.rect(37, 26, 1, 11, shade)
    c.pattern(18, 18, [
        "......R....R....R...",
        ".....RRRRRRRRRRRR...",
        "...RRBBBBBBBBBBBBRR.",
        "..RBBBBBBBBBBBBBBBBR",
        ".RBBBBBBBBBBBBBBBBBB",
        "RBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBB",
    ], ["B": body, "R": ridge])
    for x in [24, 29, 34] { c.rect(x, 20, 1, 9, ridge) }                         // ribbing over the head
    c.rect(19, 21, 3, 1, C(0x5A5270)); c.rect(18, 22, 2, 1, C(0x5A5270))          // a dull sheen
    c.rect(30, 30, 7, 1, shade); c.rect(31, 31, 6, 1, shade)                      // the seam where its maw splits
    // Signature: the front splits into a maw and souls stream in.
    if let s = sig, unfold > 0.15 {
        let open: Double = min(1, unfold * 1.4)
        let h = max(1, Int((open * 6).rounded()))
        let top = 31 - h / 2
        c.rect(29, top, 9, h, C(0x5A1424))
        c.rect(31, top + 1, 7, max(1, h - 2), C(0x0A0A0E))
        for x in stride(from: 30, through: 36, by: 2) { c.px(x, top, C(0xB8AEC0)); c.px(x + 1, top + h - 1, C(0xB8AEC0)) }   // teeth
        c.glowLine(36, 31, 37, 31, core: C(0xE8F4FF).alpha(0.8 * open), glow: C(0x6AC8E8).alpha(0.6 * open), coreR: 0.5, glowR: 2)
        for k in 0..<5 {
            let f: Double = frac(s * 2.5 + Double(k) / 5)
            let x: Double = 68 - f * 31, y: Double = 31 + sin(f * 7 + Double(k) * 2) * (1 - f) * 6
            let y2: Double = 31 + sin((f - 0.12) * 7 + Double(k) * 2) * (1.12 - f) * 6
            let col = C(0xE8F8FF).alpha(open * (0.5 + f * 0.5))
            c.glowLine(x, y, x + 5, y2, core: col, glow: C(0x5AC8F0).alpha(open * 0.7), coreR: 0.5, glowR: 1.8)
            c.px(Int(x) - 1, Int(y), C(0xFFFFFF).alpha(open * 0.9))
        }
    }
    // Its arm: a hooked tentacle, coiled at its side or lashing out.
    guard let a = p.melee else {
        stick(c, 38, 33, 40, 36, body, 0.9); stick(c, 40, 36, 41, 38, ridge, 0.6); c.px(42, 38, bone)
        return
    }
    let pv = Sprite.hand, r = a * .pi / 180, ux = cos(r), uy = sin(r)
    swingTrail(c, pv, p.trail, from: 2, to: 12, C(0x6A5A7A))
    let bend: Double = sin(p.t * 9) * 1.2
    let mid = (x: pv.x + ux * 6 - uy * bend, y: pv.y + uy * 6 + ux * bend)
    let tip = (x: pv.x + ux * 11, y: pv.y + uy * 11)
    stick(c, 37, 32, pv.x, pv.y, body, 1.1)
    stick(c, pv.x, pv.y, mid.x, mid.y, body, 0.9)
    stick(c, mid.x, mid.y, tip.x, tip.y, ridge, 0.6)
    stick(c, tip.x, tip.y, tip.x + ux * 2 - uy * 2, tip.y + uy * 2 + ux * 2, bone, 0.45)   // the hook
}

// MARK: - Red Room Widow

/// A Red Room Widow: a Clawd agent in a black tactical suit with red panels, a black hood and a red-trimmed half
/// mask over the lower face (the eyes showing through), a red hourglass buckle, wrist gauntlets, and a pistol.
/// Signature: the Red Room's red dust swirls over her face and her eyes flicker red as the conditioning takes hold.
private func drawRedRoomWidow(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1E24), suitLight = C(0x34343E), red = C(0xC8202A), redDark = C(0x8A141C)
    let skin = C(0xE8BFA0), skinDark = C(0xC09A7C)
    legsWithBoots(c, p, C(0x2E2E38), boot: C(0x0E0E12), rows: 3)
    for lx in [19, 23, 31, 35] where !seatedPose { c.rect(lx, 38, 2, 1, red) }    // red knee straps
    c.oy += p.breathe
    drawBody(c, Look(body: suit, shade: C(0x101014), arm: suit, eye: nil))
    // Hood over the head and a half mask; the eyes show in the gap.
    c.pattern(16, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
    ], ["H": suit])
    c.rect(18, 22, 3, 1, suitLight); c.rect(17, 23, 2, 2, suitLight)
    c.pattern(14, 21, [".AA.", "AAAA", "AaAA", ".AA."], ["A": C(0xB8542A), "a": C(0x8A3A1A)])   // auburn bun out the back
    c.rect(19, 25, 18, 1, red)                                                  // red trim on the hood
    c.rect(19, 28, 18, 4, skin)                                                  // the eye band
    c.rect(19, 31, 18, 1, skinDark)
    let sig = p.signature
    let dust: Double = sig.map { habitArc($0, hold: 0.5) } ?? 0
    let i = Int(p.t * 14)
    let redEyes = dust > 0.3 && noise(i) > 0.35
    for ex in [22, 32] {
        if redEyes {
            c.glowLine(Double(ex) + 1, 29.5, Double(ex) + 1, 29.5, core: C(0xFFB0A0), glow: C(0xFF2A2A), coreR: 0.8, glowR: 2)
        } else {
            c.rect(ex, 28, 2, 3, ink)
        }
    }
    c.rect(19, 32, 18, 3, suitLight)                                             // the half mask
    c.rect(19, 32, 18, 1, red)
    for x in [24, 27, 30] { c.rect(x, 33, 2, 1, C(0x0E0E12)) }                    // respirator vents
    c.rect(36, 32, 2, 3, redDark)
    // Suit: red shoulder panel, belt with the hourglass buckle.
    c.rect(18, 35, 20, 3, suit)
    c.rect(18, 36, 20, 1, C(0x3A3A44))
    c.pattern(26, 35, ["RRR", ".R.", "RRR"], ["R": red])
    c.rect(15, 33, 3, 3, suit); c.rect(17, 33, 1, 3, red)
    c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, red)
    // Signature: red dust swirling across her face.
    if dust > 0.02 {
        for k in 0..<22 {
            let f: Double = frac(p.t * 0.8 + noise(k * 7))
            let a: Double = noise(k * 3) * 2 * .pi + p.t * 1.6
            let x: Double = 28 + cos(a) * (6 + noise(k) * 7)
            let y: Double = 30 + sin(a) * (2 + noise(k + 9) * 3) - f * 4
            let col = (k % 3 == 0 ? C(0xFF6A5A) : red).alpha(dust * (0.9 - f * 0.6))
            c.px(Int(x), Int(y), col)
            if k % 2 == 0 { c.px(Int(x) + 1, Int(y), col.alpha(0.6)); c.px(Int(x), Int(y) - 1, col.alpha(0.4)) }
        }
        c.rect(19, 28, 18, 4, C(0xFF2A2A).alpha(0.22 * dust))
    }
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 31, body: C(0x16161B), trim: red)
}
