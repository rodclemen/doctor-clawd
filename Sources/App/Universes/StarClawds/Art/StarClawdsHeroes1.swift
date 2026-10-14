import Foundation

// Star Wars heroes: the originals. Ported from Clawd Wars' `drawCompanion` and the functions it called, pixel for
// pixel. Those worked out their own pose from the fight role and the session's mood (a saber kata at each hero's own
// speed and offset, a blaster that only kicks, a breathing rhythm of their own), so the art here does the same from
// the `Pose` rather than taking the engine's generic one: `heroRole` rebuilds the role Clawd Wars used.

let starWarsHeroes1: [SWHero: Persona] = [
    .luke: Persona(name: "Luke Skyclawder", weapon: .saber, headTop: 21, signature: 2.6,
                  draw: drawLuke),
    .han: Persona(name: "Han Yolo", weapon: .blaster, muzzle: (53, 32), headTop: 22, signature: 3,
                  soloFire: (0.95, 0),
                  draw: drawHan),
    .leia: Persona(name: "Princess Laya", weapon: .blaster, canSit: false, muzzle: (46, 32), headTop: 23,
                  soloFire: (1.15, 0.4),
                  draw: drawLeia),
    .obiwan: Persona(name: "Obi-Juan Kanoobie", weapon: .saber, headTop: 19, signature: 3.2,
                  draw: drawObiwan),
    .r2d2: Persona(name: "Ahh2-De2", canSit: false, headTop: 17, signature: 4,
                  draw: drawR2d2),
    .c3po: Persona(name: "C-3P-Uh-Oh", headTop: 22, signature: 2,
                  draw: drawC3po),
    .quigon: Persona(name: "Qui-Gone Tonic", weapon: .saber, headTop: 21,
                  draw: { drawJedi($0, $1, .quigon) }),
    .mace: Persona(name: "Mace Window", weapon: .saber, headTop: 26,
                  draw: { drawJedi($0, $1, .mace) }),
    .yoda: Persona(name: "Yodle", weapon: .saber, headTop: 24, signature: 3.4,
                  draw: { drawJedi($0, $1, .yoda) }),
    .jawa: Persona(name: "Clawda", weapon: .blaster, shot: .energy(core: C(0xE6F4FF), glow: C(0x3D9BFF)), canSit: false, muzzle: (46, 32), headTop: 19,
                  soloFire: (0.75, 0.55),
                  draw: { drawGunner($0, $1, .jawa) }),
    .chewie: Persona(name: "Chewbarka", weapon: .blaster, muzzle: (54, 31), headTop: 21, signature: 2,
                  soloFire: (1.3, 0.2),
                  draw: { drawGunner($0, $1, .chewie) }),
    .rey: Persona(name: "Ray", weapon: .saber, headTop: 19,
                  draw: { drawJedi($0, $1, .rey) }),
    .ahsoka: Persona(name: "Asoka Tango", weapon: .saber, headTop: 16,
                  draw: { drawJedi($0, $1, .ahsoka) }),
    .ewok: Persona(name: "Wicker the Furwok", weapon: .saber, headTop: 22,
                  draw: drawEwok),
    .tauntaun: Persona(name: "Snowtaunt", canSit: false, headTop: 14, signature: 2.4,
                  draw: drawTauntaun),
]

// MARK: - How a hero stands

/// The role Clawd Wars' `drawCompanion` gave a hero: a session that isn't working rests (saber off, blaster lowered)
/// or, waiting for you, holds its weapon up. Idle, a saber habit runs through the kata and a gun check holds it ready.
private func heroRole(_ p: Pose) -> FightRole {
    var role = p.role
    if case .none = role, p.mode != .working { role = p.mode == .waiting ? .ready(urgent: p.urgent) : .rest }
    if p.mode == .idle, case .rest = role, let h = idleHabit {
        if h.kind == .flourish, h.p > 0.1, h.p < 0.9 { role = .none }
        if h.kind == .checkWeapon, h.p < 0.75 { role = .ready(urgent: false) }
    }
    return role
}

/// Whole-sprite drop: 4 px sitting down, the hop of an urgent wait. Nothing else moves a hero as a whole.
private func heroBase(_ p: Pose) -> Int {
    if p.seated { return 4 }
    return p.urgent && p.mode == .waiting && !p.walking ? cheerHop(p.t * 1.5) : 0
}

/// Put the origin back where Clawd Wars had it before a hero drew itself: `dx` across, `dy` plus the base drop down.
private func heroOrigin(_ c: PixelCanvas, _ p: Pose, dx: Int = 0, dy: Int = 0) {
    c.ox = dx; c.oy = heroBase(p) + dy
}

/// Saber pose: its own kata (at its own speed and offset), or whatever a fight calls for.
private func heroSaberPose(_ t: Double, walking: Bool, role: FightRole, speed: Double, offset: Double)
    -> (angle: Double, dx: Double, dy: Double, trail: [Double]) {
    if walking { return (-60, 0, 0, []) }
    switch role {
    case .duel:
        let p = duelPose(t)
        return (p.angle, p.dx, p.dy, saberTrail(t, pose: { duelPose($0).angle }))
    case .deflect:
        return (deflectAngle(t), 0, 0, saberTrail(t, pose: deflectAngle))
    case .block:
        return (-60 + 2 * sin(t * 37), -1, 0, [])
    case .hit:
        return (-60, noise(Int(t * 30)) > 0.5 ? 1 : -1, 0, [])
    case .cheer:
        return (-95 + 18 * sin(t * 9), 0, Double(cheerHop(t)), [])
    case .rest:
        return (75, 0, 0, [])                // saber lowered and switched off
    case .ready(let urgent):
        return (urgent ? -90 + 25 * sin(t * 12) : -90 + 2 * sin(t * 3), 0, 0, [])   // held up; waved when urgent
    default:
        let p = kataPose(t * speed + offset)
        return (p.angle, p.dx, p.dy, saberTrail(t + offset / speed, speed: speed))
    }
}

/// Lightsabers are switched off while a hero rests.
private func heroLit(_ role: FightRole) -> Bool { if case .rest = role { return false } else { return true } }

/// A blaster hero's gun: how far to lift it (the kick of a shot, or waved while cheering) and a sideways shake when
/// hit. Only the gun moves; the shot and its flash are the engine's.
private func heroGun(_ p: Pose, _ role: FightRole) -> (recoil: Int, shake: Int) {
    if p.walking { return (0, 0) }
    switch role {
    case .hit: return (0, noise(Int(p.t * 30)) > 0.5 ? 1 : -1)
    case .cheer: return (-cheerHop(p.t) + 1, 0)
    case .rest, .ready: return (0, 0)        // blaster lowered, not firing
    default: return (p.recoil, 0)
    }
}

// MARK: - Luke, Obi-Wan

private func drawLuke(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, role = heroRole(pose)
    let p = heroSaberPose(t, walking: pose.walking, role: role, speed: 0.92, offset: 0)
    let step = pose.step
    heroOrigin(c, pose, dx: Int(p.dx.rounded()), dy: Int(p.dy.rounded()))
    let look = Look(leg: C(0xB89E72))
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)
    c.pattern(17, 21, [
        ".....YYYYYYYYYYYY.....",
        "...YYYYYYYYYYYYYYYY...",
        "..YYYYyYYYYYYYYyYYYY..",
        ".YYYyYYYYYyYYYYYyYYYY.",
        ".YYYYYY.YYYYYY.YYYYYY.",
        ".YY..Y....YY....Y..YY.",
    ], ["Y": C(0xE2C07A), "y": C(0xB8914A)])
    c.rect(18, 33, 19, 5, C(0xEFE9DA))
    c.rect(26, 33, 4, 1, clawdOrange)
    c.rect(18, 36, 19, 1, C(0x6B4A2B))
    // Signature: idle, he spins his father's hilt in his hand, switched off.
    var angle = p.angle
    if case .rest = role, let s = pose.signature, s > 0.1, s < 0.9 {
        let k = (s - 0.1) / 0.8
        angle = 75 - 720 * (0.5 - 0.5 * cos(k * .pi))
    }
    drawSaber(c, t: t, angle: angle, core: C(0xEAFFEA), glow: C(0x3FE85A), lit: heroLit(role), trail: p.trail)
}

private func drawObiwan(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, role = heroRole(pose)
    let p = heroSaberPose(t, walking: pose.walking, role: role, speed: 0.85, offset: 1.3)
    let step = pose.step
    heroOrigin(c, pose, dx: Int(p.dx.rounded()), dy: Int(p.dy.rounded()))
    let robe = C(0x7A5532)
    let look = Look(leg: C(0x8A6A44), arm: robe)
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)
    drawHood(c, robe, C(0x5E3F22))
    c.rect(18, 33, 4, 5, C(0xE4D3B0))
    c.rect(34, 33, 4, 5, C(0xE4D3B0))
    c.pattern(22, 32, [
        ".FFFF..FFFF.",
        "FFFFFFFFFFFF",
        "FFfFFFFFFfFF",
        ".FFFFfFFFFF.",
        "...FFFFFF...",
    ], ["F": C(0xC9A27A), "f": C(0xA9825A)])
    c.rect(18, 37, 20, 1, C(0x5A3A22))
    if case .rest = role, let s = pose.signature, s > 0.1, s < 0.9 {
        // Signature: thoughtfully stroking his beard. The sleeve comes up and the hand runs down the beard, again.
        let stroke = frac((s - 0.1) / 0.8 * 3)
        let hy = 31 + Int(stroke * 5)
        c.rect(34, 30, 4, 5, robe)                                   // sleeve
        c.rect(31, hy, 4, 2, C(0xE8B48A)); c.px(30, hy + 1, C(0xE8B48A))   // fingers on the beard
        c.rect(20, 37, 4, 1, C(0xB9BEC8)); c.px(22, 37, C(0x2A2A2F))     // the hilt hangs on his belt meanwhile
        return
    }
    drawSaber(c, t: t, angle: p.angle, core: C(0xE6F4FF), glow: C(0x3D9BFF), lit: heroLit(role), trail: p.trail)
}

// MARK: - Han, Leia

/// Han's BlasTech DL-44: black heavy pistol, scope on top, conical flash hider, wooden grip.
private func drawDL44(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "....SSSSL....",
        ".....K..K....",
        "GKKKKKKKKKKFF",
        "GGKKKkKkKKKFF",
        "GG...........",
        ".GG..........",
    ], ["S": C(0x2C2C33), "L": C(0x7FC8FF), "K": C(0x26262C), "k": C(0x55555F),
        "F": C(0x3E3E46), "G": C(0x4A3426)])
}

/// Leia's Defender sporting blaster: small, chrome slide over a black frame.
private func drawDefender(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "SSSSSs",
        "KKKKKK",
        "KK....",
        "KK....",
    ], ["S": C(0xD7DCE4), "s": C(0x9BA3AF), "K": C(0x2A2A30)])
}

private func drawHan(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, role = heroRole(pose), base = heroBase(pose)
    let step = pose.step
    let bob = pose.walking ? (step == 0 ? -1 : 0) : (sin(t * 5) > 0.6 ? -1 : 0)
    let look = Look(leg: C(0x2B3550))
    heroOrigin(c, pose)
    drawLegs(c, look, step: step)
    c.oy = base + bob
    drawBody(c, look)
    c.pattern(17, 22, [
        "....HHHHHHHHHHHHH.....",
        "..HHHHHHHHHHHHHHHHH...",
        ".HHHHhHHHHHHHHHHHHHH..",
        ".HHHHHHHHhhHHHHHHHHH..",
        ".HH.HHHHHHH..HHHH.HH..",
    ], ["H": C(0x5A3A1E), "h": C(0x3E2812)])
    c.rect(18, 32, 20, 6, C(0xEDEAE2))
    c.rect(18, 32, 5, 6, C(0x1F1F26))
    c.rect(33, 32, 5, 6, C(0x1F1F26))
    c.rect(18, 37, 20, 1, C(0x5A3A22))
    c.rect(26, 37, 3, 1, C(0xC9A44A))
    c.rect(19, 38, 3, 3, C(0x4A3020))
    let (recoil, shake) = heroGun(pose, role)
    c.oy = base + bob - recoil
    c.ox = shake
    if case .rest = role, let s = pose.signature, s > 0.08, s < 0.9 {
        // Signature: he spins the DL-44 on his trigger finger, twice round, and drops it into the holster, then
        // draws it again, quick as you like.
        if s < 0.52 {
            let k = (s - 0.08) / 0.44
            let gun = PixelCanvas(13, 6)
            drawDL44(gun, x: 0, y: 0)
            let spun = gun.rotated(-720 * (0.5 - 0.5 * cos(k * .pi)), about: (3, 3.5), into: 26, 26, at: (13, 13))
            c.paste(spun, x: 40 - 13 + 3, y: 30 - 13 + 3)
        } else {
            c.rect(19, 36, 2, 3, C(0x4A3426)); c.px(21, 36, C(0x26262C))   // the grip in the holster
        }
        return
    }
    drawDL44(c, x: 40, y: 30)
}

private func drawLeia(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, role = heroRole(pose), base = heroBase(pose)
    let bob = pose.walking ? (Int(t * 8) % 2 == 0 ? -1 : 0) : (sin(t * 4 + 1) > 0.6 ? -1 : 0)
    heroOrigin(c, pose, dy: bob)
    let gown = C(0xF4F4F0), gownShade = C(0xD9DADF)
    var look = Look(arm: gown)
    look.legs = false
    for y in 38...43 {
        let k = (y - 38) / 2
        c.rect(18 - k, y, 20 + k * 2, 1, gown)
        c.px(18 - k, y, gownShade); c.px(37 + k, y, gownShade)
    }
    drawBody(c, look)
    let B = C(0x4A2E18), b = C(0x3A2212)
    let bun = [".BBB.", "BBbBB", "BbBbB", "BBbBB", ".BBB."]
    c.pattern(12, 27, bun, ["B": B, "b": b])
    c.pattern(39, 27, bun, ["B": B, "b": b])
    c.pattern(18, 23, [
        "...BBBBBBBBBBBBBB...",
        "..BBBBBBBbbBBBBBBB..",
        ".BBBBBBB....BBBBBBB.",
    ], ["B": B, "b": b])
    c.rect(18, 33, 20, 5, gown)
    c.rect(37, 33, 1, 5, gownShade)
    c.rect(18, 35, 20, 1, C(0xB8BEC9))
    let (recoil, shake) = heroGun(pose, role)
    c.oy = base + bob - recoil
    c.ox = shake
    drawDefender(c, x: 40, y: 32)
}

// MARK: - The droids

private func drawR2d2(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t
    heroOrigin(c, pose, dx: sin(t * 2 * .pi * (pose.walking ? 3 : 1.6)) > 0 ? 1 : -1)
    let blue = C(0x2E62D6), grey = C(0x9AA3B2)
    let look = Look(body: C(0xEEF1F5), shade: C(0xC9D0DA), leg: C(0xA7B0BF), arm: blue, eye: nil)
    drawLegs(c, look)
    drawBody(c, look)
    let light = Int(t * 2.5) % 2 == 0 ? C(0xFF3B3B) : C(0x4FA8FF)
    c.pattern(18, 17, [
        "......SSSSSSSS......",
        "....SSSSSSSSSSSS....",
        "...SSSSSSSSSSSSSS...",
        "..SSBBSSSEEESSBBSS..",
        ".SSSBBSSSEEESSBBSSS.",
        ".SSSSSSSSSSSSSSSSSS.",
        "SSBBBSSSRSSSSSBBBSSs",
        "ssssssssssssssssssss",
        "ssssssssssssssssssss",
    ], ["S": C(0xC3CAD6), "s": grey, "B": blue, "E": C(0x111118), "R": light])
    c.rect(20, 28, 3, 6, blue)
    c.rect(33, 28, 3, 6, blue)
    c.rect(24, 29, 8, 2, grey)
    c.rect(24, 32, 8, 1, blue)
    c.rect(26, 34, 4, 3, grey)

    c.ox = 0
    if let s = pose.signature {
        // Signature: "Help me, Obi-Wan Kenobi…" A tiny blue Leia flickers up in the beam of his projector.
        drawLeiaHologram(c, t: t, p: s, from: (26, 23))
        return
    }
    // Beep-boop: music notes drifting up
    for i in 0..<2 {
        let f = (t / 1.4 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
        c.pattern(42 + i * 6 + Int(sin(f * 6) * 2), 18 - Int(f * 16),
                  ["..NN", "..N.", "..N.", "NNN.", "NN.."], ["N": blue.alpha(1 - f)])
    }
}

/// Leia's message as R2 plays it: a projector beam from `from` and a small, flickering, scan-lined blue Leia standing
/// in it, kneeling slightly as she pleads. `p` 0…1 through the message: it flickers on, plays, and cuts out.
private func drawLeiaHologram(_ c: PixelCanvas, t: Double, p: Double, from: (x: Int, y: Int)) {
    guard p > 0.06, p < 0.94 else { return }
    let on = min(1, (p - 0.06) / 0.08, (0.94 - p) / 0.08)
    let flicker = noise(Int(t * 18)) > 0.85 ? 0.45 : 1.0
    let a = on * flicker
    let x0 = 45, y0 = 22                                           // the figure's top-left
    // The beam: a faint cone from the projector to her feet and head.
    for k in 0...10 {
        let f = Double(k) / 10
        let top = (x: Double(from.x) + (Double(x0) - Double(from.x)) * f, y: Double(from.y) + (Double(y0) - Double(from.y)) * f)
        let bot = (x: top.x, y: Double(from.y) + (Double(y0 + 15) - Double(from.y)) * f)
        for y in Int(top.y)...Int(bot.y) where (y + k) % 3 == 0 { c.px(Int(top.x), y, C(0x6FB8FF).alpha(0.18 * a)) }
    }
    let art = [
        "..B...B..",
        ".BBHHHBB.",
        "..BHFHB..",
        "...HFH...",
        "...HHH...",
        "..DDDDD..",
        ".DDdDDDD.",
        "DDDdDDDDD",
        ".DDDDdDD.",
        ".DDDDDDD.",
        "DDDDDdDDD",
        "DDDDDDDDD",
        "DDDDDDDDD",
        "DDDDDDDDD",
        ".DDDDDDD.",
    ]
    let glitch = noise(Int(t * 9) + 3) > 0.8 ? Int(t * 9) % art.count : -1    // a row slips sideways now and then
    for (r, row) in art.enumerated() {
        let dim = r % 2 == 1 ? 0.6 : 1.0                           // scan lines
        let dx = r == glitch ? 1 : 0
        for (k, ch) in row.enumerated() {
            let col: Px
            switch ch {
            case "B": col = C(0x7FC8FF)      // the buns
            case "H": col = C(0x9AD4FF)      // hair
            case "F": col = C(0xD8F0FF)      // face
            case "D": col = C(0xB8E2FF)      // the white dress
            case "d": col = C(0x7FC8FF)      // its folds
            default: continue
            }
            c.px(x0 + k + dx, y0 + r, col.alpha(0.85 * a * dim))
        }
    }
    c.rect(x0 - 1, y0 + 15, 11, 1, C(0x6FB8FF).alpha(0.35 * a))   // where the image meets the floor
}

private func drawC3po(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, walking = pose.walking
    let flail = Int(t * 6) % 2
    let step = pose.step
    // Signature: "We're doomed!" Both arms thrown straight up, hands flapping, the whole droid rattling.
    let doomed = pose.signature.map { $0 > 0.08 && $0 < 0.92 } ?? false
    heroOrigin(c, pose, dx: walking ? 0 : doomed ? (Int(t * 16) % 2 == 0 ? 0 : 1) : (Int(t * 1.5) % 2 == 0 ? 0 : 1))
    let gold = C(0xE2B33C), goldShade = C(0xB8862A)
    let look = Look(body: gold, shade: goldShade, leg: C(0xD4A436), arm: gold, eye: nil)
    drawLegs(c, look, step: step)
    drawBody(c, look, armLeft: doomed ? 0 : (flail == 0 ? 4 : 0), armRight: doomed ? 0 : (flail == 0 ? 0 : 4))
    if doomed {
        // Arms straight up from the shoulders, elbows locked, hands splayed and flapping out of step.
        for (side, x) in [(0, 14), (1, 39)] {
            let wave = Int(t * 12 + Double(side)) % 2
            c.rect(x, 21 + wave, 3, 15 - wave, gold)
            c.rect(x + (side == 0 ? 0 : 2), 22 + wave, 1, 13 - wave, goldShade)
            c.rect(x, 28, 3, 1, C(0x8A6420))                        // the elbow joint
            let hx = x + (side == 0 ? -1 : 1) * wave
            c.rect(hx - 1, 18 + wave, 5, 3, gold)                   // splayed hand
            c.px(hx - 1, 17 + wave, gold); c.px(hx + 1, 17 + wave, gold); c.px(hx + 3, 17 + wave, gold)
        }
    }
    c.pattern(20, 22, [
        "....GGGGGGGG....",
        "..GGGGGGGGGGGG..",
        ".GGGgGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGG",
    ], ["G": gold, "g": C(0xFFE08A)])
    let eye = C(0xFFF3A6), eyeRim = C(0x8A6420)
    for ex in [21, 31] {
        c.rect(ex, 28, 4, 4, eyeRim)
        c.rect(ex + 1, 29, 2, 2, eye)
    }
    c.rect(26, 33, 4, doomed ? 2 : 1, eyeRim)                     // the mouth, agape when he's doomed
    c.rect(23, 35, 10, 2, goldShade)
    c.px(25, 35, C(0xE0303A)); c.px(28, 36, C(0x3A7BEA)); c.px(31, 35, C(0x3BD15A))
    c.rect(19, 27, 2, 1, C(0xFFE08A))
}

// MARK: - The Jedi

/// Saber wielders: Qui-Gon, Mace Windu, Yoda, Rey and Ahsoka (twin blades).
private func drawJedi(_ c: PixelCanvas, _ pose: Pose, _ who: SWHero) {
    let t = pose.t, role = heroRole(pose)
    // Each Jedi's kata offset and blade colours (core, glow).
    let offset: Double, core: Px, glow: Px
    switch who {
    case .quigon: (offset, core, glow) = (0.6, C(0xEAFFEA), C(0x3FE85A))
    case .mace: (offset, core, glow) = (2.1, C(0xF6E6FF), C(0xB04CFF))
    case .yoda: (offset, core, glow) = (0.3, C(0xEAFFEA), C(0x3FE85A))
    case .rey: (offset, core, glow) = (1.7, C(0xE6F4FF), C(0x3D9BFF))
    case .ahsoka: (offset, core, glow) = (2.6, C(0xFFFFFF), C(0xC9D6FF))
    default: (offset, core, glow) = (0, C(0xEAFFEA), C(0x3FE85A))
    }
    let p = heroSaberPose(t, walking: pose.walking, role: role, speed: who == .yoda ? 1.15 : 0.9, offset: offset)
    let step = pose.step
    heroOrigin(c, pose, dx: Int(p.dx.rounded()), dy: Int(p.dy.rounded()))
    let cream = C(0xE4D3B0), robe = C(0x7A5532), belt = C(0x5A3A22)
    let look: Look
    switch who {
    case .yoda: look = Look(body: C(0x8DB360), shade: C(0x6E9148), leg: C(0x8DB360), arm: C(0x8DB360))
    case .mace: look = Look(leg: C(0x3A2A1C), arm: C(0x4A3322))
    case .rey: look = Look(leg: C(0x9A8A72), arm: C(0xB5A58A))
    case .ahsoka: look = Look(body: C(0xD9693A), shade: C(0xB0532C), leg: C(0x5A4A3A), arm: C(0xD9693A))
    default: look = Look(leg: C(0x6E5236), arm: robe)
    }
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)

    switch who {
    case .quigon:
        let H = C(0x6A4A2A)
        c.pattern(16, 21, [
            ".....HHHHHHHHHHHH.....",
            "...HHHHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHH..",
            ".HHHH............HHHH.",
            "HHH................HHH",
            "HHH................HHH",
            "HH..................HH",
            "HH..................HH",
        ], ["H": H])
        c.pattern(23, 32, [".HH....HH.", "HHHHHHHHHH", ".HHHHHHHH.", "...HHHH..."], ["H": H])
        c.rect(18, 35, 20, 3, cream); c.rect(18, 36, 20, 1, belt)
    case .mace:
        c.rect(22, 28, 3, 1, C(0x2A1C12)); c.rect(31, 28, 3, 1, C(0x2A1C12))   // stern brows, bald head
        c.rect(18, 33, 20, 5, C(0x5A3A22)); c.rect(25, 33, 6, 5, cream); c.rect(18, 36, 20, 1, C(0x2A1C12))
    case .yoda:
        let ear = C(0x8DB360), earIn = C(0xC98F7A)
        // Signature: he leans on his gimer stick, ears drooping as he ponders, then perking up again. Hmm.
        var droop = 0
        if case .rest = role, let s = pose.signature, s > 0.05, s < 0.95 {
            droop = Int((3 * habitArc((s - 0.05) / 0.9, hold: 0.5)).rounded())
            c.glowLine(12, 30, 11, 43, core: C(0x6E5236), glow: C(0, 0), coreR: 0.8, glowR: 0.9)   // the stick
            c.rect(11, 29, 3, 2, C(0x8A6A48))
            c.rect(14, 31, 3, 2, C(0x8DB360))                        // his hand on it
        }
        c.pattern(9, 26 + droop, droop > 1 ? [".EEEEEEEE", "..EeeeEEE", "....EEEEE"] : ["EEEEEEEEE", ".EeeeEEEE", "...EEEEEE"],
                  ["E": ear, "e": earIn])
        c.pattern(38, 26 + droop, droop > 1 ? ["EEEEEEEE.", "EEEeeeE..", "EEEEE...."] : ["EEEEEEEEE", "EEEEeeeE.", "EEEEEE..."],
                  ["E": ear, "e": earIn])
        if droop > 1 { c.rect(21, 27, 4, 1, C(0x6E9148)); c.rect(31, 27, 4, 1, C(0x6E9148)) }   // eyes half shut
        c.pattern(22, 24, ["W..W..W.W..W", ".W..W...W.W."], ["W": C(0xEDEDED)])
        c.rect(18, 33, 20, 5, robe); c.rect(26, 33, 4, 5, cream)
    case .rey:
        let H = C(0x4A2E18)
        c.pattern(18, 22, ["...HHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHH", "HH..............HH"], ["H": H])
        c.pattern(15, 19, [".HH.", "HHHH", ".HHH"], ["H": H])   // buns at the back of the head
        c.pattern(15, 22, ["HHHH", "HHHH", ".HHH"], ["H": H])
        c.rect(18, 33, 20, 5, C(0xEFE6D2)); c.rect(18, 35, 20, 1, C(0xB5A58A))
    case .ahsoka:
        let W = C(0xF4F4F4), B = C(0x2E62D6)
        // montrals and lekku: white with blue stripes
        c.pattern(17, 16, [
            ".WW..............WW.",
            ".WB..............BW.",
            "WWW..............WWW",
            "WBW..............WBW",
            "WWWW............WWWW",
            "WBWW............WWBW",
            "WWWWWWWWWWWWWWWWWWWW",
            ".WWWWWWWWWWWWWWWWWW.",
            "..BB.BB..BB..BB.BB..",
        ], ["W": W, "B": B])
        c.rect(21, 28, 4, 1, W); c.rect(31, 28, 4, 1, W)        // facial markings
        c.rect(27, 30, 2, 3, W)
        c.rect(18, 33, 20, 5, C(0x4A3A30)); c.rect(18, 35, 20, 1, C(0x8A6A44))
    default:
        break
    }

    if who == .ahsoka {
        // Second, shorter shoto from the other hand, held in reverse grip.
        c.ox -= 24; c.oy += 1
        drawSaber(c, t: t, angle: 180 - p.angle * 0.6 + 40, core: core, glow: glow, lit: heroLit(role), length: 12)
        c.ox += 24; c.oy -= 1
    }
    drawSaber(c, t: t, angle: p.angle, core: core, glow: glow, lit: heroLit(role), trail: p.trail, length: who == .yoda ? 14 : 20)
}

// MARK: - Chewbacca, the Jawa

/// Blaster carriers: Chewbacca (bowcaster) and a Jawa (ion blaster).
private func drawGunner(_ c: PixelCanvas, _ pose: Pose, _ who: SWHero) {
    let t = pose.t, role = heroRole(pose), base = heroBase(pose)
    let step = pose.step
    let bob = pose.walking ? (step == 0 ? -1 : 0) : (sin(t * 4.5) > 0.6 ? -1 : 0)
    heroOrigin(c, pose)
    if who == .chewie {
        let fur = C(0x7A4E2A), furDark = C(0x5C3A1E), furLight = C(0x9A6A3E)
        let look = Look(body: fur, shade: furDark, leg: fur, arm: fur)
        drawLegs(c, look, step: step)
        c.oy = base + bob
        drawBody(c, look)
        c.pattern(18, 21, ["...FFFFFFFFFFFFFF...", ".FFFfFFFFFFFFFfFFFF.", "FFFFFFFFfFFFFFFFFFFF", "FfFFFFFFFFFFFFFFFfFF", "FF................FF"],
                  ["F": fur, "f": furLight])
        for (x, y) in [(20, 33), (24, 35), (30, 34), (34, 33), (22, 30), (35, 29)] { c.px(x, y, furLight) }
        c.rect(25, 33, 6, 1, C(0x3A2412))                       // mouth
        for i in 0..<10 { c.rect(19 + i * 2, 36 - i, 2, 2, i % 3 == 0 ? C(0xB9BEC8) : C(0x4A3020)) }  // bandolier
        if let s = pose.signature, s > 0.08, s < 0.92 {
            // Signature: head back, arms up, a full-throated Wookiee roar.
            let k = habitArc((s - 0.08) / 0.84, hold: 0.6)
            let open = Int((k * 3).rounded())
            c.rect(24, 32 - open / 2, 8, 1 + open, C(0x2A140A))          // mouth wide
            if open > 1 { for x in [24, 26, 29, 31] { c.px(x, 32 - open / 2, C(0xF0E8D8)) } }   // fangs
            c.rect(15, 23, 3, 11, fur); c.rect(15, 23, 1, 11, furDark)    // the free arm thrown up…
            c.rect(14, 20, 5, 3, fur)                                       // …a big hairy hand,
            for x in [14, 16, 18] { c.px(x, 19, furLight) }                 // fingers splayed
            if k > 0.8 {
                for i in 0..<3 {                                     // the roar going up
                    let f = frac(s * 5 + Double(i) / 3)
                    c.rect(22 + i * 5, 17 - Int(f * 6), 1, 2, C(0xF4EEE0).alpha(0.8 * (1 - f)))
                }
            }
        }
    } else {
        let robe = C(0x7A5A3A), robeDark = C(0x5A4028)
        var look = Look(body: robe, shade: robeDark, arm: robe, eye: nil)
        look.legs = false
        for y in 38...43 {
            let k = (y - 38) / 2
            c.rect(18 - k, y, 20 + k * 2, 1, robe)
            c.px(18 - k, y, robeDark); c.px(37 + k, y, robeDark)
        }
        c.oy = base + bob
        drawBody(c, look)
        c.pattern(18, 19, ["......RRRRRRRR......", "....RRRRRRRRRRRR....", "..RRRRRRRRRRRRRRRR..", ".RRRRRRRRRRRRRRRRRR.", "RRRRRRRRRRRRRRRRRRRR",
                           "RRRRRRRRRRRRRRRRRRRR", "RRRRRRRRRRRRRRRRRRRR"], ["R": robe])
        c.rect(21, 27, 15, 6, C(0x14100C))                      // shadowed face
        let glow = sin(t * 3) > -0.8 ? C(0xFFE14A) : C(0x8A7A2A)
        c.rect(24, 29, 2, 2, glow); c.rect(31, 29, 2, 2, glow)
        c.rect(18, 35, 20, 1, C(0x3A2A18))
    }
    let (recoil, shake) = heroGun(pose, role)
    c.oy = base + bob - recoil
    c.ox = shake
    if who == .chewie {
        // Bowcaster: stock, body and the crossbow limbs
        c.pattern(40, 29, ["......SS......", ".......S......", "KKKKKKKKKKKKKK", "KKWWKKKKKKKK..", "...S...S......", "......SS......"],
                  ["K": C(0x3A2A1C), "W": C(0x8A6A44), "S": C(0xB9BEC8)])
    } else {
        c.pattern(40, 32, ["KKKKKK", "KKSSK.", "KK...."], ["K": C(0x4A4A52), "S": C(0x9AA0AE)])
    }
}

// MARK: - Wicket, the tauntaun

/// Wicket: a small furry Clawd in a leather hood, with big dark eyes and a stone-tipped spear.
private func drawEwok(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, role = heroRole(pose)
    let p = heroSaberPose(t, walking: pose.walking, role: role, speed: 1.1, offset: 0.9)
    let step = pose.step
    heroOrigin(c, pose, dx: Int(p.dx.rounded()), dy: Int(p.dy.rounded()))
    let fur = C(0x6E4A2A), furDark = C(0x52361E), furLight = C(0x8A6238)
    let look = Look(body: fur, shade: furDark, leg: furDark, arm: fur, eye: nil)
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)
    for (x, y) in [(20, 33), (27, 35), (33, 32), (23, 30), (31, 36)] { c.px(x, y, furLight) }
    // leather hood with little ears poking through
    c.pattern(17, 22, [
        "..E...............E...",
        ".EEH.HHHHHHHHHHH.HEE..",
        ".HHHHHHHHhHHHHHHHHHH..",
        "HHHHHHhHHHHHHHhHHHHHH.",
        "HH..................HH",
        "HH..................HH",
    ], ["H": C(0xB07A42), "h": C(0x8A5A2E), "E": furDark])
    c.rect(22, 29, 3, 3, C(0x0E0A08)); c.rect(31, 29, 3, 3, C(0x0E0A08))   // big dark eyes
    c.px(23, 29, C(0x6A5A4A)); c.px(32, 29, C(0x6A5A4A))
    c.rect(27, 32, 2, 1, C(0x2A1A10))                                      // little nose
    drawEwokSpear(c, angle: heroLit(role) ? p.angle : -75)   // resting: spear shouldered, not through the floor
}

/// A wooden spear with a stone tip, held like a saber (same pivot, same choreography).
private func drawEwokSpear(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 4, hy - uy * 4, hx + ux * 18, hy + uy * 18, core: C(0x8A6238), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    c.glowLine(hx + ux * 18, hy + uy * 18, hx + ux * 22, hy + uy * 22, core: C(0x9AA0A8), glow: C(0, 0), coreR: 1.1, glowR: 1.2)
    c.glowLine(hx + ux * 16, hy + uy * 16, hx + ux * 17, hy + uy * 17, core: C(0xC8B48A), glow: C(0, 0), coreR: 1.0, glowR: 1.1)  // binding
}

/// A tauntaun from Hoth: a shaggy grey-white biped with curled horns, a long snout and a tail. It doesn't fight: it
/// stomps about, bobs its head and huffs frosty breath.
private func drawTauntaun(_ c: PixelCanvas, _ pose: Pose) {
    let t = pose.t, base = heroBase(pose)
    let fur = C(0xD8D2C4), furShade = C(0xAEA696), furDark = C(0x8A8274), horn = C(0x8A6A48)
    let step = pose.walking ? Int(t * 8) % 2 : (sin(t * 3) > 0.7 ? 0 : -1)   // an impatient stomp now and then
    let bob = Int((sin(t * 2.4) * 1.2).rounded())
    heroOrigin(c, pose)
    // Two strong legs with big feet
    for (i, lx) in [21, 31].enumerated() {
        let up = step == i ? 1 : 0
        c.rect(lx, 34, 4, 9 - up, furShade)
        c.rect(lx - 1, 42 - up, 6, 2, furDark)
    }
    // Tail swishing behind
    let sway = Int((sin(t * 2) * 2).rounded())
    c.glowLine(18, 32, 9, Double(36 + sway), core: furShade, glow: C(0, 0), coreR: 1.4, glowR: 1.5)
    // Body (a shaggy Clawd) with a little arm
    c.rect(18, 22, 18, 13, fur)
    c.rect(18, 33, 18, 2, furShade)
    for (x, y) in [(20, 25), (24, 29), (29, 24), (33, 30), (22, 32), (31, 27)] { c.px(x, y, furShade) }
    c.rect(35, 28, 3, 2, furShade)
    // Neck and head, bobbing; long snout forward, horns curling back.
    // Signature: it shakes its head, then snorts out a great cloud of frosty breath.
    let snort = pose.signature
    let shaking = snort.map { $0 > 0.08 && $0 < 0.45 } ?? false
    c.oy = base + bob
    c.ox = shaking ? (Int(t * 14) % 2 == 0 ? 1 : -1) : 0
    c.rect(30, 16, 6, 7, fur)
    c.rect(32, 11, 10, 7, fur)
    c.rect(42, 13, 5, 4, fur)                    // snout
    c.rect(42, 16, 5, 1, furShade)
    c.px(46, 14, furDark)                         // nostril
    c.rect(36, 13, 2, 2, C(0x1A1612))             // eye
    c.pattern(30, 7, [".HHH.", "H...H", "H....", ".H..."], ["H": horn])   // curled horn
    c.oy = base; c.ox = 0
    if let s = snort, s > 0.45 {
        let k = (s - 0.45) / 0.55
        for i in 0..<4 {                                            // a big two-nostril blast
            let f = k * 1.3 - Double(i) * 0.15
            guard f > 0, f < 1 else { continue }
            let r = 2 + Int(f * 4)
            c.circle(49 + Int(f * 12) + i * 2, 15 + bob + (i % 2) * 2 - Int(f * 3), r, white.alpha(0.8 * (1 - f)))
            c.circle(48 + Int(f * 12) + i * 2, 14 + bob + (i % 2) * 2 - Int(f * 3), max(1, r - 2), C(0xFFFFFF).alpha(0.6 * (1 - f)))
        }
        return
    }
    // Frosty breath
    let f = (t / 1.8).truncatingRemainder(dividingBy: 1)
    if f < 0.6 {
        let k = f / 0.6
        c.circle(48 + Int(k * 7), 15 + bob - Int(k * 3), 1 + Int(k * 2), white.alpha(0.55 * (1 - k)))
    }
}
