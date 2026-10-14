import Foundation

// Villains: aliens, Avengers foes and sorcerers.

let villains7: [MarvelVillain: Persona] = [
    .brood: Persona(name: "The Brude", weapon: .saber, headTop: 15, signature: 2.6,
                  draw: drawBrood),
    .cassandraNova: Persona(name: "Cassandra Supernova", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xFFE0F0), glow: C(0xE84AA0), jagged: false),
                  headTop: 21, signature: 3.0,
                  draw: drawCassandraNova),
    .graviton: Persona(name: "Gravitron", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xF0E0FF), glow: C(0x8A4AFF), jagged: false),
                  headTop: 21, signature: 3.2,
                  draw: drawGraviton),
    .absorbingMan: Persona(name: "Absorbent Man", weapon: .saber, armoured: true,
                  headTop: 21, signature: 3.4,
                  draw: drawAbsorbingMan),
    .crimsonDynamo: Persona(name: "Crimson Dynamite", weapon: .blaster, shot: .energy(core: C(0xFFE0E0), glow: C(0xFF2A2A)), armoured: true, canSit: false,
                  muzzle: (50, 31.5), handGun: false, bulk: 3, headTop: 9, signature: 2.8,
                  draw: drawCrimsonDynamo),
    .wrecker: Persona(name: "Wreckker", weapon: .saber, headTop: 22, signature: 2.8,
                  draw: drawWrecker),
    .baronMordo: Persona(name: "Baron Bordeaux", weapon: .lightning, magic: Magic(core: C(0xE0FFE0), glow: C(0x3AE05A), jagged: false),
                  headTop: 18, signature: 3.2,
                  draw: drawBaronMordo),
    .enchantress: Persona(name: "Enchantrix", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xE0FFE8), glow: C(0x3AD06A), jagged: false),
                  headTop: 18, signature: 3.0,
                  draw: drawEnchantress),
    .arnimZola: Persona(name: "Arnim Zolla", weapon: .blaster, shot: .energy(core: C(0xE0FFE0), glow: C(0x3AE05A)), armoured: true,
                  muzzle: (48, 34), handGun: false, headTop: 12, signature: 2.6,
                  draw: drawArnimZola),
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
        c.glowLine(s.x + cos(r) * len * 0.5, s.y + sin(r) * len * 0.5, s.x + cos(r) * len, s.y + sin(r) * len,
                   core: col, glow: col, coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
}

/// `n` claws fanning out from `e` along `angle`, each `len` long.
private func claws(_ c: PixelCanvas, _ e: (x: Double, y: Double), _ angle: Double, len: Double, n: Int = 3,
                   spread: Double = 0.35, _ col: Px) {
    let r = angle * .pi / 180
    for k in 0..<n {
        let a = r + (Double(k) - Double(n - 1) / 2) * spread
        c.glowLine(e.x + cos(a), e.y + sin(a), e.x + cos(a) * (len + 1), e.y + sin(a) * (len + 1),
                   core: col, glow: clear, coreR: 0.45, glowR: 0.5)
    }
}

/// A puff of steam or smoke at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px = C(0xE8ECF0)) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2.5).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.75 * (1 - k)))
    c.circle(Int(x.rounded()) - 1, Int(y.rounded()) - 1, max(0, r - 1), white.alpha(0.5 * (1 - k)))
}

/// A filled triangle.
private func tri(_ c: PixelCanvas, _ a: (Double, Double), _ b: (Double, Double), _ d: (Double, Double), _ col: Px) {
    let minX = Int(floor(min(a.0, b.0, d.0))), maxX = Int(ceil(max(a.0, b.0, d.0)))
    let minY = Int(floor(min(a.1, b.1, d.1))), maxY = Int(ceil(max(a.1, b.1, d.1)))
    for y in minY...maxY {
        for x in minX...maxX {
            let px = Double(x) + 0.5, py = Double(y) + 0.5
            let d1: Double = (px - b.0) * (a.1 - b.1) - (a.0 - b.0) * (py - b.1)
            let d2: Double = (px - d.0) * (b.1 - d.1) - (b.0 - d.0) * (py - d.1)
            let d3: Double = (px - a.0) * (d.1 - a.1) - (d.0 - a.0) * (py - a.1)
            let neg = d1 < 0 || d2 < 0 || d3 < 0, pos = d1 > 0 || d2 > 0 || d3 > 0
            if !(neg && pos) { c.px(x, y, col) }
        }
    }
}

/// A one-pixel-ish ring of radius `r` round (`cx`, `cy`).
private func ring(_ c: PixelCanvas, _ cx: Int, _ cy: Int, r: Double, _ col: Px, width: Double = 0.55) {
    guard r > 0.5 else { return }
    let n = Int(ceil(r + width + 1))
    for dy in -n...n {
        for dx in -n...n {
            let d = Double(dx * dx + dy * dy).squareRoot()
            if abs(d - r) <= width { c.px(cx + dx, cy + dy, col) }
        }
    }
}

/// Draw the `above` look over canvas rows before `split` and the `below` look from it on, so a change can sweep down.
private func splitRows(_ c: PixelCanvas, split: Int, _ above: (PixelCanvas) -> Void, _ below: (PixelCanvas) -> Void) {
    let la = PixelCanvas(c.w, c.h), lb = PixelCanvas(c.w, c.h)
    for l in [la, lb] { l.ox = c.ox; l.oy = c.oy; l.baseY = c.baseY }
    above(la); below(lb)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    for y in 0..<c.h {
        let src = y - oy - by < split ? la : lb
        for x in 0..<c.w {
            let i = (y * c.w + x) * 4, al = src.buf[i + 3]
            guard al > 0 else { continue }
            let m = 255 / Double(al)
            c.px(x, y, Px(r: UInt8(min(255, Double(src.buf[i]) * m)), g: UInt8(min(255, Double(src.buf[i + 1]) * m)),
                          b: UInt8(min(255, Double(src.buf[i + 2]) * m)), a: al))
        }
    }
    c.ox = ox; c.oy = oy; c.baseY = by
}

/// A bald dome over Clawd's head, rows 21…25, with a shine.
private func baldDome(_ c: PixelCanvas, _ skin: Px, _ shine: Px) {
    c.pattern(18, 21, ["....SSSSSSSSSSSS....", "..SSSSSSSSSSSSSSSS..", ".SSSSSSSSSSSSSSSSSS.",
                       "SSSSSSSSSSSSSSSSSSSS", "SSSSSSSSSSSSSSSSSSSS"], ["S": skin])
    c.rect(21, 22, 3, 1, shine); c.px(20, 23, shine)
}

// MARK: - Brood

/// Brood: Clawd as an insectoid alien queen-spawn, a black carapace with a long crest swept back off the skull, slanted
/// acid-green eyes, bony mandibles, translucent wings folded up on its back and a curling stinger tail; fights with
/// its claws. Signature: it rears and hisses, jaws gaping wide, wings buzzing, drool dripping from the fangs.
private func drawBrood(_ c: PixelCanvas, _ p: Pose) {
    let shell = C(0x3C3C56), dark = C(0x22222E), sheen = C(0x7078A8), belly = C(0x6A6858)
    let eye = C(0xC8F03A), bone = C(0xD8CCA0), maw = C(0x7A1428), drool = C(0xB8E66A)
    let wing = C(0x8AB0C8, 0.5), vein = C(0x5A7A90, 0.85)
    let hiss = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let t = p.lt
    // the stinger tail, swaying behind
    let sway: Double = sin(t * 2.2) * 1.5
    let tail: [(Double, Double)] = [(19, 34), (13, 38), (8, 39 + sway * 0.3), (4 + sway * 0.3, 37), (3 + sway * 0.6, 32)]
    let thick: [Double] = [2.0, 1.7, 1.3, 1.0]
    for i in 0..<(tail.count - 1) {
        c.glowLine(tail[i].0, tail[i].1, tail[i + 1].0, tail[i + 1].1, core: shell, glow: clear, coreR: thick[i], glowR: thick[i] + 0.1)
    }
    for k in 0..<3 {                                                        // ridges along the tail
        let q = tail[k + 1]
        c.px(Int(q.0), Int(q.1) - 1, sheen)
    }
    let tip = (x: Int((3 + sway * 0.6).rounded()), y: 28)
    c.pattern(tip.x - 1, tip.y, [".B.", ".BB", "BBB", ".B."], ["B": bone])
    c.oy += p.breathe
    // wings, folded up behind the crest (buzzing while it hisses)
    let buzz: Double = hiss > 0.2 ? (Int(p.t * 30) % 2 == 0 ? -2 : 1) : sin(t * 1.3) * 0.6
    tri(c, (19, 27), (7, 17 + buzz), (13, 14 + buzz), wing)
    tri(c, (23, 26), (15, 13 + buzz), (21, 15 + buzz), wing)
    c.glowLine(19, 27, 9, 16.5 + buzz, core: vein, glow: clear, coreR: 0.4, glowR: 0.5)
    c.glowLine(23, 26, 17, 14 + buzz, core: vein, glow: clear, coreR: 0.4, glowR: 0.5)
    c.oy -= p.breathe
    drawLegs(c, Look(leg: shell), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {                      // clawed toes
            c.px(lx + 2, p.step >= 0 && i % 2 == p.step ? 42 : 43, bone)
        }
    }
    c.oy += p.breathe
    if hiss > 0.05 { c.oy -= Int((hiss * 1).rounded()) }                    // rears up
    drawBody(c, Look(body: shell, shade: dark, arm: shell, eye: nil))
    for y in [34, 36] { c.rect(21, y, 14, 1, belly) }                      // belly plates
    // the long crest swept back off the skull
    c.pattern(8, 19, [
        ".............SSSSSSSSSSS........",
        ".........SSSSSSSSSSSSSSSSSS.....",
        ".....SSSSSSSSSSSSSSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSSSSSSSSSSSS..",
        "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS..",
        "..SSSSSSSSSSSSSSSSSSSSSSSSSSSSS.",
        ".....SSSSSSSSSSSSSSSSSSSSSSSSSS.",
    ], ["S": shell])
    c.rect(12, 21, 14, 1, sheen); c.rect(22, 20, 8, 1, sheen); c.rect(9, 23, 4, 1, sheen)
    for x in stride(from: 14, to: 34, by: 5) { c.px(x, 24, dark) }          // ridges
    // slanted eyes
    c.pattern(21, 28, ["DEE...", ".DEEE."], ["E": eye, "D": dark])
    c.pattern(30, 28, ["...EED", ".EEED."], ["E": eye, "D": dark])
    c.px(31, 29, eye)
    // the mouth, and the mandibles at its corners
    let gape = Int((hiss * 3).rounded())
    c.rect(25, 32, 11, 1 + gape, maw)
    for x in stride(from: 25, to: 36, by: 2) { c.px(x, 32, bone); if gape > 0 { c.px(x + 1, 32 + gape, bone) } }
    c.pattern(35, 30, ["BB..", ".BBB", "..BB", "...B"], ["B": bone])
    if gape > 0 { c.pattern(35, 33 + gape, ["..BB", "...B"], ["B": bone]) }
    // Signature: the hiss, drool and a rattle of sound in front of it.
    if let s = p.signature, hiss > 0.3 {
        for k in 0..<2 {
            let f = frac(s * 2.5 + Double(k) * 0.5)
            let x = 33 - k * 5, y0 = 33 + gape
            let y = y0 + Int(f * 9)
            c.rect(x, y0, 1, max(1, y - y0), drool.alpha(0.55))
            c.rect(x, y, 1, 2, drool.alpha(1 - f * 0.5))
        }
        let pale = C(0xC8D0A0, 0.8 * hiss)
        for k in 0..<3 where Int(p.t * 12 + Double(k)) % 3 != 0 {
            let x = 43 + k * 3
            c.rect(x, 27 + (k % 2), 1, 3, pale); c.px(x + 1, 26 + (k % 2), pale); c.px(x + 1, 30 + (k % 2), pale)
        }
    }
    // the claw
    let a = p.seated ? 20 : (p.melee ?? 75)
    smear(c, Sprite.hand, p.trail, len: 11, C(0xE8E0C0))
    let hand = (x: Sprite.hand.x - 1, y: Sprite.hand.y - 1 - Double(p.armRaise))
    c.rect(Int(hand.x) - 2, Int(hand.y) - 1, 4, 3, shell)
    claws(c, (hand.x + 0.5, hand.y + 0.5), a, len: p.melee == nil ? 4 : 7, spread: 0.45, bone)
}

// MARK: - Cassandra Nova

/// Cassandra Nova: a pale, bald Clawd with cold, shadowed eyes and a thin smile, in a green bodysuit with a black
/// yoke and boots; hovers, and her psychic power streams pink. Signature: the smile stretches into a wide, toothy,
/// thoroughly unsettling grin as pink psychic ripples pulse out from her forehead.
private func drawCassandraNova(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xEED8C8), skinShade = C(0xCCB0A0), suit = C(0x2E9A46), suitDark = C(0x1E6A30), black = C(0x1E1E26)
    let pink = C(0xF04AA8), shadow = C(0x7A5A6A), lip = C(0x9A4A5A)
    let grin = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 3, black) }
    }
    c.oy += p.breathe
    baldDome(c, skin, C(0xFFF4EC))
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil), armRight: p.armRaise)
    c.rect(18, 33, 20, 5, suit)
    c.rect(18, 37, 20, 1, suitDark); c.rect(37, 33, 1, 5, suitDark)
    c.pattern(18, 33, ["..BBBBBBBBBBBBBBBB..", "....BBB......BBB....", ".........BB........."], ["B": black])
    // cold, shadowed eyes under thin arched brows
    c.rect(21, 28, 4, 1, shadow); c.rect(31, 28, 4, 1, shadow)
    c.px(21, 27, skinShade); c.px(34, 27, skinShade)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    if grin > 0.3 { c.px(22, 29, pink); c.px(32, 29, pink) }
    if grin < 0.3 {
        c.rect(25, 32, 6, 1, lip); c.px(24, 31, lip); c.px(31, 31, lip)       // the thin smile
    } else {
        c.rect(23, 31, 10, 2, C(0x3A1420))                                 // the grin
        c.rect(24, 31, 8, 1, C(0xF0E8DC))
        for x in stride(from: 25, to: 32, by: 2) { c.px(x, 31, C(0xB8A898)) }
        c.px(22, 30, lip); c.px(33, 30, lip); c.px(21, 29, lip); c.px(34, 29, lip)
    }
    // Signature: psychic ripples from her forehead.
    if let s = p.signature, grin > 0.05 {
        c.rect(27, 23, 2, 2, pink.alpha(grin)); c.px(27, 23, C(0xFFC8E8).alpha(grin))
        for k in 0..<3 {
            let f = frac(s * 2.4 + Double(k) / 3)
            ring(c, 28, 24, r: 2 + f * 17, pink.alpha(0.75 * (1 - f) * grin))
        }
    }
}

// MARK: - Graviton

/// Graviton: Clawd with slicked dark hair and a widow's peak, a blue suit with purple gloves, boots and shoulders, the
/// gravity-well rings on the chest; hovers, with a couple of pebbles always floating near him in a purple haze, and
/// his power streams violet. Signature: he raises his hands and a ring of rocks lifts off the ground and orbits him.
private func drawGraviton(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4CB8), blueDark = C(0x1A3080), purple = C(0x8A3AD8), purpleDark = C(0x5A2498)
    let skin = C(0xE4B48E), skinShade = C(0xC09070), hair = C(0x2E241E), glow = C(0x9A5AFF)
    let lift = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    // the orbiting debris (signature): rocks rise from the ground onto an ellipse around him
    let orbit: [(x: Int, y: Int, behind: Bool, kind: Int)] = (p.signature.map { s -> [(x: Int, y: Int, behind: Bool, kind: Int)] in
        guard lift > 0.02 else { return [] }
        return (0..<7).map { i -> (x: Int, y: Int, behind: Bool, kind: Int) in
            let a: Double = s * 2 * .pi * 1.4 + Double(i) * 2 * .pi / 7
            let ox: Double = 28 + cos(a) * 22, oy: Double = 29 + sin(a) * 7
            let gx: Double = 10 + Double(i) * 8, gy: Double = 42
            let x = Int((gx + (ox - gx) * lift).rounded()), y = Int((gy + (oy - gy) * lift).rounded())
            return (x, y, sin(a) < 0 && lift > 0.6, i)
        }
    }) ?? []
    for r in orbit where r.behind { rock(c, r.x, r.y, r.kind, glow) }
    if p.signature == nil {                                                  // ambient pebbles, bobbing
        let b = sin(p.lt * 2) > 0 ? 1 : 0
        rock(c, 11, 33 + b, 2, glow); rock(c, 46, 40 - b, 0, glow)
    }
    drawLegs(c, Look(leg: blue), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 3, purple) }
    }
    c.oy += p.breathe
    let up = Int((lift * 4).rounded())
    drawBody(c, Look(body: skin, shade: skinShade, arm: purple), armLeft: up, armRight: max(up, p.armRaise))
    c.rect(18, 33, 20, 5, blue)
    c.rect(18, 37, 20, 1, blueDark); c.rect(37, 33, 1, 5, blueDark)
    c.rect(18, 33, 4, 2, purple); c.rect(34, 33, 4, 2, purple)              // purple shoulders
    c.rect(18, 33, 20, 1, purpleDark)
    ring(c, 28, 35, r: 1.6, purple, width: 0.5); c.px(28, 35, purpleDark)   // the gravity-well emblem
    // slicked dark hair with a widow's peak
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHHhHHHHHHHHHHHHhHHH",
        "HHHHHHHHHHHHHHHHHHHH",
        "HH.......HH......HHH",
        "H.................HH",
    ], ["H": hair, "h": C(0x5A4A3E)])
    c.rect(21, 28, 4, 1, hair); c.rect(31, 28, 4, 1, hair)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(25, 32, 6, 1, C(0x9A5A40))
    for r in orbit where !r.behind { rock(c, r.x, r.y, r.kind, glow) }
    if lift > 0.3 {                                                          // hands crackling with gravity
        c.rect(14, 32 - up, 5, 5, glow.alpha(0.3)); c.rect(37, 32 - up, 5, 5, glow.alpha(0.3))
    }
}

/// A small rock floating in a purple haze.
private func rock(_ c: PixelCanvas, _ x: Int, _ y: Int, _ kind: Int, _ glow: Px) {
    let stone = C(0x8A7E70), dark = C(0x5A5048), light = C(0xB4A894)
    c.circle(x, y, 2, glow.alpha(0.22))
    let pal: [Character: Px] = ["S": stone, "D": dark, "L": light]
    switch kind % 3 {
    case 0: c.pattern(x - 1, y - 1, [".LS", "SSS", "SDD"], pal)
    case 1: c.pattern(x - 2, y - 1, [".LSS", "SSSD", ".SD."], pal)
    default: c.pattern(x - 1, y - 1, ["LS", "SD"], pal)
    }
}

// MARK: - Absorbing Man

/// What the Absorbing Man's skin is made of right now.
private enum Matter { case flesh, stone, steel }

/// The Absorbing Man: Crusher Creel, a bald, heavy-browed, stubbly Clawd in a black-and-white striped prison shirt
/// and grey trousers, the wrecking ball still chained to his wrist; he swings it as his weapon and drags it about.
/// Signature: his skin turns to stone from the head down, then to steel (with a gleam), then back to flesh.
private func drawAbsorbingMan(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.08, s < 0.97 else { absorbingMan(c, p, .flesh); return }
    // A change sweeps from the head down to the feet over `span`.
    func swept(_ from: Matter, _ to: Matter, _ k: Double) {
        let split = Int((18 + 27 * k).rounded())
        splitRows(c, split: split, { absorbingMan($0, p, to) }, { absorbingMan($0, p, from) })
        if k > 0.02 && k < 0.98 {
            for x in 15...40 where noise(x * 5 + Int(p.t * 20)) > 0.5 { c.px(x, split + c.oy, C(0xFFF0C0, 0.7)) }
        }
    }
    switch s {
    case ..<0.26: swept(.flesh, .stone, (s - 0.08) / 0.18)
    case ..<0.48: absorbingMan(c, p, .stone)
    case ..<0.58: swept(.stone, .steel, (s - 0.48) / 0.1)
    case ..<0.82:
        absorbingMan(c, p, .steel)
        drawGlint(c, p: (s - 0.58) / 0.24, maxX: 44)
    default: swept(.steel, .flesh, (s - 0.82) / 0.15)
    }
}

private func absorbingMan(_ c: PixelCanvas, _ p: Pose, _ m: Matter) {
    let skin: Px, shade: Px, light: Px
    switch m {
    case .flesh: skin = C(0xE0A880); shade = C(0xB88060); light = C(0xF4C8A0)
    case .stone: skin = C(0x948A7C); shade = C(0x62594E); light = C(0xB8AE9E)
    case .steel: skin = C(0xA8B2C0); shade = C(0x5E6878); light = C(0xE0E8F0)
    }
    let stripeLight = C(0xD8D8D0), stripeDark = C(0x2A2A33), pants = C(0x5E626E), pantsDark = C(0x40434C)
    let iron = C(0x3A3C46), ironLight = C(0x7A7E8A)
    drawLegs(c, Look(leg: pants), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 41 : 42, 2, 1, pantsDark) }
    }
    // the ball, when it's resting on the ground (drawn without the breathing bob)
    let restBall = (x: 47, y: p.seated ? 36 : 40)
    if p.melee == nil {
        c.circle(restBall.x, restBall.y, 3, iron)
        c.px(restBall.x - 1, restBall.y - 2, ironLight); c.px(restBall.x - 2, restBall.y - 1, ironLight)
    }
    c.oy += p.breathe
    baldDome(c, skin, light)
    drawBody(c, Look(body: skin, shade: shade, arm: skin, eye: nil))
    for y in 33...37 { c.rect(18, y, 20, 1, y % 2 == 0 ? stripeLight : stripeDark) }   // the prison shirt
    c.rect(37, 34, 1, 3, C(0x8A8A86))
    // heavy brow, small eyes, stubble, a grin
    c.rect(20, 27, 16, 2, shade)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    for (x, y) in [(21, 32), (23, 33), (33, 32), (35, 31), (20, 31), (35, 33), (34, 33)] { c.px(x, y, shade) }
    c.rect(25, 31, 7, 1, C(0x5A3A2A)); c.px(31, 30, C(0x5A3A2A))
    if m == .stone {                                                         // cracks in the stone
        c.pattern(19, 22, ["..D.........D.......", "...D.......D........", "...DD.....D.........", "....D..............."], ["D": shade])
        c.pattern(26, 27, ["......D", ".....D.", "......D"], ["D": shade])
    }
    // the chain from his wrist shackle, out to the ball
    let hand = Sprite.hand
    c.rect(38, 33, 3, 3, skin)
    c.rect(40, 33, 2, 3, iron)
    if let a = p.melee {
        smear(c, hand, p.trail, len: 13, C(0xC8CCD4))
        let r = a * .pi / 180
        let end = (x: hand.x + cos(r) * 10, y: hand.y + sin(r) * 10)
        for k in 1...5 {
            let f = Double(k) / 6
            c.px(Int(hand.x + (end.x - hand.x) * f), Int(hand.y + (end.y - hand.y) * f), k % 2 == 0 ? ironLight : iron)
        }
        c.circle(Int(end.x), Int(end.y), 3, iron)
        c.px(Int(end.x) - 1, Int(end.y) - 2, ironLight); c.px(Int(end.x) - 2, Int(end.y) - 1, ironLight)
    } else {
        c.oy -= p.breathe
        let start = (x: 41.5, y: 35.5 + Double(p.breathe)), end = (x: Double(restBall.x) - 1, y: Double(restBall.y) - 3)
        for k in 1...4 {
            let f = Double(k) / 5
            let sag: Double = sin(f * .pi) * 2
            c.px(Int(start.x + (end.x - start.x) * f), Int(start.y + (end.y - start.y) * f + sag), k % 2 == 0 ? ironLight : iron)
        }
    }
}

// MARK: - Crimson Dynamo

/// Crimson Dynamo: a hulking suit of red Soviet battle armour, a great domed helmet with a T-visor and glowing yellow
/// eye slits, big rounded pauldrons, a slatted steel chest grille, steel fists and boots; fires repulsor blasts from
/// an outstretched palm. Signature: the armour overheats and vents jets of steam from its shoulders and back.
private func drawCrimsonDynamo(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC4202A), redDark = C(0x841420), redLight = C(0xEE5A50), steel = C(0x80848E), steelDark = C(0x4A4D56)
    let gold = C(0xFFD23A), hot = C(0xFF8A2A)
    let venting = p.signature.map { $0 > 0.1 && $0 < 0.9 } ?? false
    for (i, lx) in [16, 22, 32, 38].enumerated() {
        let up = p.step >= 0 && i % 2 == p.step ? 1 : 0
        c.rect(lx, 36, 4, 8 - up, redDark)
        c.rect(lx - 1, 40 - up, 6, 4, steel)
        c.rect(lx - 1, 40 - up, 6, 1, steelDark)
    }
    c.oy += p.breathe
    // the far arm
    c.rect(10, 25, 5, 9, redDark); c.rect(9, 32, 7, 5, steelDark)
    // the torso
    c.rect(14, 21, 28, 16, red)
    c.rect(14, 21, 2, 16, redLight); c.rect(40, 21, 2, 16, redDark)
    c.rect(22, 25, 12, 7, steelDark)                                         // the chest grille
    for y in [26, 28, 30] { c.rect(23, y, 10, 1, steel) }
    c.rect(27, 26, 2, 5, redDark); c.rect(27, 27, 2, 3, gold.alpha(venting ? 1 : 0.75))
    c.rect(14, 33, 28, 3, steelDark); c.rect(26, 33, 4, 3, steel)            // belt
    // pauldrons
    let pad = ["..PPPPP..", ".PPPPPPP.", "PPPPPPPPP", "PPPPPPPPP", "DDDDDDDDD"]
    c.pattern(9, 19, pad, ["P": red, "D": redDark]); c.rect(11, 20, 3, 1, redLight)
    c.pattern(37, 19, pad, ["P": red, "D": redDark]); c.rect(39, 20, 3, 1, redLight)
    if venting { c.rect(11, 23, 5, 1, hot); c.rect(39, 23, 5, 1, hot) }
    // the helmet
    c.pattern(19, 9, [
        ".....HHHHHHHH.....",
        "...HHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        ".HHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHH..",
    ], ["H": red])
    c.rect(26, 9, 4, 5, steel); c.rect(29, 9, 1, 5, steelDark)               // the ridge over the top
    c.rect(21, 11, 2, 3, redLight); c.rect(20, 14, 1, 3, redLight)           // shine
    c.rect(34, 13, 2, 8, redDark)
    c.rect(21, 15, 15, 2, ink)                                                // the T-visor
    c.rect(26, 17, 4, 3, ink)
    let blink = p.signature.map { s in s > 0.4 && s < 0.46 } ?? false
    if !blink { c.rect(23, 15, 3, 1, gold); c.rect(31, 15, 3, 1, gold) }
    c.rect(21, 19, 4, 2, steel); c.rect(31, 19, 4, 2, steel)                 // cheek plates
    c.circle(19, 16, 1, steelDark)                                           // ear bolt
    // Signature: steam jets from the shoulders and the back.
    if venting, let s = p.signature {
        for k in 0..<3 {
            let f = frac(s * 3.2 + Double(k) / 3)
            puff(c, x: 12 - f * 5, y: 18 - f * 9, k: f)
            puff(c, x: 43 + f * 4, y: 18 - f * 9, k: frac(f + 0.33))
            puff(c, x: 13 - f * 6, y: 30 - f * 3, k: frac(f + 0.66))
        }
    }
    // the gun arm: out straight to fire from the palm, otherwise at his side
    if p.fire != nil || p.gunLift != 0 {
        c.oy += p.gunY
        c.rect(38, 28, 10, 6, red); c.rect(38, 28, 10, 1, redLight); c.rect(38, 33, 10, 1, redDark)
        c.rect(46, 27, 3, 8, steel); c.rect(46, 34, 3, 1, steelDark)
        c.rect(49, 30, 1, 3, gold); c.px(50, 31, gold.alpha(0.6))
    } else {
        c.rect(41, 24, 5, 9, red); c.rect(41, 24, 1, 9, redLight)
        c.rect(40, 32, 7, 5, steel); c.rect(40, 36, 7, 1, steelDark)
    }
}

// MARK: - Wrecker

/// The Wrecker: a burly Clawd in a green bodysuit and full green mask (his jaw and eyes showing through), purple
/// gloves, collar, belt and boots, and Loki's enchanted iron crowbar for a weapon. Signature: he hoists the crowbar
/// overhead and it blazes with golden Asgardian magic, throwing sparks.
private func drawWrecker(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A9A3A), greenDark = C(0x26702A), greenLight = C(0x5AC05A), purple = C(0x7A2E9A), purpleDark = C(0x50186A)
    let skin = C(0xE0A880), skinShade = C(0xB88060), iron = C(0x44444E), ironLight = C(0x8A8E9A)
    let charm = C(0xFFC83A), charmCore = C(0xFFF4C0)
    let lift = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 3, purple) }
    }
    c.oy += p.breathe
    // the mask's crown over the head
    c.pattern(18, 23, ["...MMMMMMMMMMMMMM...", ".MMMMMMMMMMMMMMMMMM.", "MMMMMMMMMMMMMMMMMMMM"], ["M": green])
    c.rect(21, 24, 3, 1, greenLight)
    drawBody(c, Look(body: green, shade: greenDark, arm: purple, eye: nil), armRight: p.armRaise)
    c.rect(16, 32, 2, 4, green)                                              // broad shoulders
    // eye holes, the scowl and the bare jaw
    c.rect(21, 28, 4, 4, skin); c.rect(31, 28, 4, 4, skin)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 4, 1, greenDark); c.rect(31, 28, 4, 1, greenDark)        // a heavy frown
    c.px(24, 29, greenDark); c.px(31, 29, greenDark)
    c.rect(23, 32, 10, 2, skin)
    c.rect(25, 32, 6, 1, C(0x7A3A2A))
    for x in [23, 24, 31, 32] { c.px(x, 33, skinShade) }                     // stubble
    c.rect(18, 34, 20, 1, purple)                                            // collar…
    c.rect(18, 36, 20, 1, purpleDark)                                        // …and belt
    c.rect(27, 36, 3, 1, C(0xC8B04A))
    // the crowbar
    let a: Double = p.seated ? 10 : (p.melee ?? 45) * (1 - lift) + -82 * lift
    if p.signature == nil { smear(c, Sprite.hand, p.trail, len: 17, C(0xE0E2E8)) }
    let r = a * .pi / 180, ux = cos(r), uy = sin(r)
    let hx = Sprite.hand.x, hy = Sprite.hand.y - Double(p.armRaise)
    let s0 = (x: hx - ux * 3, y: hy - uy * 3), e = (x: hx + ux * 14, y: hy + uy * 14)
    let glow = lift > 0.5 ? (lift - 0.5) * 2 : 0
    if glow > 0 {
        c.glowLine(s0.x, s0.y, e.x, e.y, core: charmCore, glow: charm, coreR: 0.6, glowR: 3, strength: glow * (0.85 + 0.15 * sin(p.t * 30)))
    }
    c.glowLine(s0.x, s0.y, e.x, e.y, core: iron, glow: clear, coreR: 0.85, glowR: 0.95)
    let hook = (x: e.x - uy * 2.5 - ux * 1.2, y: e.y + ux * 2.5 - uy * 1.2)  // the claw end, curled back
    c.glowLine(e.x, e.y, hook.x, hook.y, core: iron, glow: clear, coreR: 0.8, glowR: 0.9)
    c.px(Int(hx + ux * 6), Int(hy + uy * 6), glow > 0 ? charmCore : ironLight)
    if glow > 0.6, let s = p.signature {
        for k in 0..<3 {
            let f = Double(k + 1) / 4
            if noise(Int(s * 40) + k * 11) > 0.4 { c.px(Int(hx + ux * 14 * f) + 1, Int(hy + uy * 14 * f), charmCore) }
        }
        if noise(Int(s * 25)) > 0.45 { drawSparks(c, x: e.x, y: e.y, t: p.t, size: 2.5) }
    }
    c.rect(Int(hx) - 2, Int(hy) - 1, 3, 3, purple)                           // the fist round the bar
}

// MARK: - Baron Mordo

/// Baron Mordo: a sorcerer Clawd with black hair in a sharp widow's peak, pointed sideburns and a goatee, the
/// towering dark green collar behind his head, and green robes to the floor trimmed in gold; casts green magic.
/// Signature: he raises his hand and conjures a dark spell circle in the air before him, rings, a hexagram and
/// runes turning in green fire, that flares and fades.
private func drawBaronMordo(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x2E6A34), robeDark = C(0x1C4A22), collar = C(0x14381A), gold = C(0xE8B530), goldDark = C(0xA8801E)
    let skin = C(0xE0B890), skinShade = C(0xC0987A), hair = C(0x1E1A1A), magic = C(0x3AE05A), magicCore = C(0xC8FFC8)
    let spell = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: robeDark, edge: collar)
    drawLegs(c, Look(leg: C(0x2A2A22)), step: p.step)
    c.oy += p.breathe
    // the high collar behind his head
    c.pattern(12, 18, [
        "YYYYYYY..................YYYYYYY",
        "YCCCCCC..................CCCCCCY",
        ".YCCCCC..................CCCCCY.",
        ".YCCCCC..................CCCCCY.",
        "..YCCCC..................CCCCY..",
        "..YCCCC..................CCCCY..",
        "...YCCC..................CCCY...",
        "...YCCC..................CCCY...",
        "....YCC..................CCY....",
    ], ["C": collar, "Y": goldDark])
    let raise = max(p.armRaise, Int((spell * 4).rounded()))
    drawBody(c, Look(body: skin, shade: skinShade, arm: robe, eye: nil), armRight: raise)
    // robes, flaring to the ankles
    let hem = seatedPose ? 38 : 40
    for y in 33...hem {
        let w = 20 + (y - 33) / 3 * 2
        c.rect(28 - w / 2, y, w, 1, robe)
    }
    c.rect(28 - 12, hem, 24, 1, gold)
    c.rect(27, 33, 2, hem - 33, gold)                                        // the trimmed front
    c.rect(18, 35, 20, 1, goldDark)                                          // the sash
    c.rect(18, 33, 20, 1, robeDark)
    // hair: widow's peak and pointed sideburns
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHHH....HHHH....HHHH",
        "HHH......HH......HHH",
        "HH.......HH.......HH",
        "H..................H",
        "H..................H",
    ], ["H": hair])
    c.pattern(21, 27, ["HHH.......HHH", "..H.......H.."], ["H": hair])      // arched brows
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.pattern(24, 31, ["HHHHHHHH", "H..HH..H", "...HH..."], ["H": hair])   // moustache and pointed goatee
    // Signature: the spell circle.
    if p.signature != nil, spell > 0.03 {
        let cx = 51, cy = 25
        let R: Double = 8 * spell
        let turn: Double = p.t * 1.6
        c.circle(cx, cy, Int(R.rounded()), C(0x0E2412, 0.55 * spell))
        ring(c, cx, cy, r: R, magic.alpha(spell), width: 0.6)
        ring(c, cx, cy, r: R * 0.62, magic.alpha(0.8 * spell), width: 0.45)
        var pts: [(Double, Double)] = []
        for k in 0..<6 {
            let a: Double = turn + Double(k) * .pi / 3
            pts.append((Double(cx) + 0.5 + cos(a) * R * 0.62, Double(cy) + 0.5 + sin(a) * R * 0.62))
        }
        for k in 0..<6 {                                                     // the hexagram
            let q = pts[(k + 2) % 6]
            c.glowLine(pts[k].0, pts[k].1, q.0, q.1, core: magic.alpha(0.7 * spell), glow: clear, coreR: 0.35, glowR: 0.4)
        }
        for k in 0..<8 {                                                     // runes round the rim
            let a: Double = -turn * 0.7 + Double(k) * .pi / 4
            c.px(cx + Int((cos(a) * (R + 1.5)).rounded()), cy + Int((sin(a) * (R + 1.5)).rounded()), magicCore.alpha(spell))
        }
        c.px(cx, cy, magicCore.alpha(spell))
    }
    if p.signature != nil || p.zap != nil { c.rect(37, 31 - raise, 5, 5, magic.alpha(0.25)) }
}

// MARK: - Enchantress

/// The Enchantress: Amora, a Clawd with long golden hair flowing down her back, a green-and-gold horned headdress,
/// green-shadowed eyes and red lips, in a green gown with a gold belt; hovers and casts green magic. Signature: she
/// lifts her hand to her lips and blows a kiss, a pink heart floats off towards you.
private func drawEnchantress(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2AA04A), greenDark = C(0x1A7034), gold = C(0xF0C040), goldDark = C(0xB8901E)
    let hair = C(0xF4D050), hairDark = C(0xC8A02A), skin = C(0xF4D8C4), skinShade = C(0xD8B8A0)
    let lips = C(0xD8285A), pink = C(0xFF5AA8)
    let sway = sin(p.lt * 1.8)
    // long hair down her back
    c.oy += p.breathe
    c.pattern(13, 24, [
        "....HHHHH",
        "..HHHHHHH",
        ".HHHHHHHH",
        "HHHHHHHHh",
        "HHHHHHHH.",
        "HHHHhHHH.",
        ".HHHHHHH.",
        "HHHHHHH..",
        "HHHhHHH..",
        ".HHHHHH..",
        sway > 0 ? "..HHHHH.." : ".HHHHH...",
        sway > 0 ? "...HHH..." : "HHHH.....",
        sway > 0 ? "....H...." : ".H.......",
    ], ["H": hair, "h": hairDark])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 1, gold) }
    }
    c.oy += p.breathe
    // the kiss: 0…0.4 hand to lips, 0.4…0.55 blown, then the heart drifts off
    let s = p.signature ?? -1
    let toLips = s < 0 ? 0 : (s < 0.4 ? habitArc(min(1, s / 0.4) * 0.5, hold: 0) : max(0, 1 - (s - 0.4) / 0.2))
    drawBody(c, Look(body: skin, shade: skinShade, arm: green, eye: nil), armRight: toLips > 0.05 ? 0 : p.armRaise)
    c.rect(18, 33, 20, 5, green)
    c.rect(18, 37, 20, 1, greenDark); c.rect(37, 33, 1, 5, greenDark)
    c.pattern(18, 33, ["GG................GG", "..GGGGGGGGGGGGGGGG.."], ["G": gold])  // gold neckline…
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, goldDark)              // …and belt
    // hair on top, falling to the shoulders
    c.pattern(16, 21, [
        "......HHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHhHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHH.........HHHHHHH",
        "HHH................HHH",
        "HHH................HH.",
        "HH.................HH.",
        "HH..................H.",
        "HH....................",
        ".H....................",
    ], ["H": hair, "h": hairDark])
    // the horned headdress
    c.pattern(18, 18, ["Y..................Y", "YG................GY", ".GG..............GG.", "..GGGGGGGGGGGGGGGG..",
                       "...DDDDDDYYDDDDDDD.."], ["G": green, "D": greenDark, "Y": gold])
    c.px(27, 22, C(0xFFF0A0))
    // eyes, lashes, lips
    c.rect(22, 28, 2, 1, greenDark); c.rect(32, 28, 2, 1, greenDark)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(21, 28, ink); c.px(34, 28, ink)
    if toLips > 0.5 { c.rect(27, 31, 2, 2, lips) } else { c.rect(26, 32, 4, 1, lips); c.px(25, 31, lips) }
    // Signature: hand to lips, then the heart floats away.
    if toLips > 0.05 {
        let hx = Int((38 - 7 * toLips).rounded()), hy = Int((33 - 3 * toLips).rounded())
        c.rect(38, 33, 3, 3, green.alpha(1 - toLips))
        c.rect(hx, hy, 3, 3, green); c.px(hx, hy, skin)
    }
    if s > 0.45 {
        let f = (s - 0.45) / 0.55
        let x = Int((33 + f * 22).rounded()), y = Int((30 - f * 12 + sin(f * 9) * 1.5).rounded())
        let fade = f > 0.75 ? (1 - f) / 0.25 : 1
        if f < 0.25 {
            c.pattern(x, y, [".H.H.", "HHHHH", ".HHH.", "..H.."], ["H": pink.alpha(fade)])
        } else {
            c.pattern(x, y, [".HH.HH.", "HLHHHHH", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."],
                      ["H": pink.alpha(fade), "L": C(0xFFC8E4).alpha(fade)])
            if Int(s * 30) % 3 == 0 { c.px(x + 8, y - 1, C(0x3AD06A).alpha(fade)); c.px(x - 1, y + 4, C(0x3AD06A).alpha(fade)) }
        }
    }
}

// MARK: - Arnim Zola

/// Arnim Zola: a maroon robot Clawd with no head of his own, a boxy ESP unit with an antenna and green sensor lights
/// sits on his shoulders, and his bespectacled face looks out from a TV screen set in his chest; green collar, gloves
/// and boots; blasts green energy from his palm. Signature: the screen glitches, static, rolling bars, his face
/// jumping about, before it settles.
private func drawArnimZola(_ c: PixelCanvas, _ p: Pose) {
    let body = C(0x9A2E3E), dark = C(0x6A1A28), light = C(0xC8505A), green = C(0x5A9A3A), greenDark = C(0x3A6A24)
    let frame = C(0x2A2A33), screen = C(0x9ABCA0), face = C(0xE0D0A8), faceShade = C(0xB8A880), lens = C(0x8AFF6A)
    let s = p.signature ?? -1
    let glitch = s > 0.1 && s < 0.9
    let seed = Int(p.t * 20)
    drawLegs(c, Look(leg: body), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 3, green) }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: body, shade: dark, arm: body, eye: nil))
    c.rect(18, 26, 1, 11, light)
    // the ESP box on his shoulders
    c.rect(27, 12, 1, 3, frame); c.px(27, 11, glitch && seed % 2 == 0 ? white : lens)   // antenna
    c.pattern(20, 15, [
        "..BBBBBBBBBBBB..",
        ".BBBBBBBBBBBBBB.",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "DDDDDDDDDDDDDDDD",
    ], ["B": body, "D": dark])
    c.rect(21, 16, 3, 1, light); c.rect(20, 18, 1, 3, light)
    c.rect(27, 17, 9, 4, frame)                                              // the sensor panel
    for (k, x) in [28, 31, 34].enumerated() {
        let on = !glitch || noise(seed + k * 7) > 0.4
        c.px(x, 18, on ? lens : greenDark); c.px(x, 19, greenDark)
    }
    c.rect(18, 23, 20, 3, green); c.rect(18, 25, 20, 1, greenDark)          // collar ring
    // the chest screen
    c.rect(20, 27, 16, 9, frame)
    c.rect(21, 28, 14, 7, screen)
    var jx = 0
    if glitch && noise(seed * 3) > 0.5 { jx = noise(seed * 5) > 0.5 ? 1 : -1 }
    let full = glitch && noise(seed * 7 + 1) > 0.8
    if !full {
        c.pattern(23 + jx, 28, [
            "..FFFFFF..",
            ".FFFFFFFF.",
            "FGGGFFGGGF",
            "FGEGGGGEGF",
            "FFFFFFFFFF",
            ".FFFMMFFF.",
            "..SSSSSS..",
        ], ["F": face, "S": faceShade, "G": frame, "E": ink, "M": C(0x8A4A3A)])
    }
    for y in stride(from: 29, to: 35, by: 2) { c.rect(21, y, 14, 1, C(0x203020, 0.18)) }   // scanlines
    if glitch {
        let bar = 28 + Int(frac(s * 4) * 7)                                  // a rolling bar
        c.rect(21, bar, 14, 1, C(0xE8F0E8, 0.6))
        for y in 28...34 {
            for x in 21...34 where noise(seed * 131 + x * 31 + y * 17) > (full ? 0.35 : 0.8) {
                c.px(x, y, noise(seed + x * 3 + y) > 0.5 ? C(0xE8ECE8) : C(0x3A403A))
            }
        }
    }
    c.rect(18, 36, 20, 1, greenDark)
    // the blaster hand: out to fire from the palm, otherwise at his side
    if p.fire != nil || p.gunLift != 0 {
        c.oy += p.gunY
        c.rect(38, 33, 7, 3, body); c.rect(38, 33, 7, 1, light)
        c.rect(45, 32, 2, 5, green); c.px(46, 34, lens)
    } else {
        c.rect(38, 34, 3, 2, green)
    }
}
