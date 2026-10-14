import Foundation

// Star Wars villains: the originals.

let starWarsVillains1: [SWVillain: Persona] = [
    .vader: Persona(name: "Darth Vapor", weapon: .saber, headTop: 14, signature: 2.6,
                  draw: drawVader),
    .kylo: Persona(name: "Kylo Rant", weapon: .saber, headTop: 15, signature: 1.8,
                  draw: drawKylo),
    .maul: Persona(name: "Darth Mall", weapon: .saber, headTop: 23,
                  draw: drawMaul),
    .boba: Persona(name: "Boba Feta", weapon: .blaster, armoured: true, muzzle: (52, 32), headTop: 11, signature: 2.6,
                  draw: drawBoba),
    .trooper: Persona(name: "Stormtrouper", weapon: .blaster, armoured: true, muzzle: (52, 32), headTop: 16, signature: 2.6,
                  draw: drawTrooper),
    .emperor: Persona(name: "The Emperor", weapon: .lightning, canSit: false, headTop: 19,
                  draw: drawEmperor),
    .rogr: Persona(name: "R0-DG3R", weapon: .blaster, armoured: true, muzzle: (52, 32), headTop: 15, callout: "Roger roger!",
                  draw: drawRogr),
    .dooku: Persona(name: "Count Duku", weapon: .saber, headTop: 21,
                  draw: drawDooku),
    .gamorrean: Persona(name: "Gamoink Guard", weapon: .saber, headTop: 17,
                  draw: drawGamorrean),
    .jabba: Persona(name: "Jabbo the Glutt", canSit: false, headTop: 19, signature: 2.4, callout: "Ho ho ho!",
                  draw: drawJabba),
    .ig88: Persona(name: "IG-Ate-Ate", weapon: .blaster, armoured: true, muzzle: (52, 32), headTop: 9, signature: 2.4,
                  draw: drawIg88),
    .atst: Persona(name: "Chicken Walker", weapon: .blaster, armoured: true, canSit: false, muzzle: (47, 22), handGun: false, headTop: 10,
                  draw: drawAtst),
    .atat: Persona(name: "AT-ACK", weapon: .blaster, armoured: true, canSit: false, muzzle: (64, 21), handGun: false, headTop: 11,
                  draw: drawAtat),
    .rancor: Persona(name: "Rancor", weapon: .saber, canSit: false, pivot: rancorShoulder, headTop: 8, signature: 2,
                  draw: drawRancor),
    .greedo: Persona(name: "Greedy-O", weapon: .blaster, muzzle: (47, 32), headTop: 19,
                  draw: drawGreedo),
    .royalGuard: Persona(name: "Royal Guard", weapon: .saber, canSit: false, headTop: 13, fidgets: false,
                  draw: drawRoyalGuard),
]

// MARK: - Helpers

private let clear = C(0, 0)

/// The idle habit playing now, if this pose is the one it's played in (idle, standing, not fighting).
private func idlePlay(_ p: Pose) -> HabitPlay? {
    guard !p.walking, p.mode == .idle, let h = idleHabit else { return nil }
    switch p.role { case .none, .rest: return h; default: return nil }
}

/// An axe, claw or pike's idle flourish: swung up from `from` degrees and back, instead of spun round.
private func swungUp(_ p: Pose, from: Double) -> Double? {
    guard let h = idlePlay(p), h.kind == .flourish else { return p.melee }
    return from - 70 * habitArc(h.p, hold: 0.1)
}

/// Where a held gun sits: the villains only raise it to check it (idle), not while waiting or cheering.
private func gunY(_ p: Pose) -> Int { -p.recoil - (p.mode == .idle ? p.gunLift : 0) }

/// A plain red saber, or its hilt at the belt when it's off.
private func drawRedSaber(_ c: PixelCanvas, _ p: Pose) {
    if let a = p.melee {
        drawSaber(c, t: p.t, angle: a, core: C(0xFFE3E3), glow: C(0xFF1E2D), lit: true, trail: p.trail)
    } else {
        c.rect(36, 37, 2, 5, C(0xB9BEC8)); c.rect(36, 39, 2, 1, C(0x2A2A2F))
    }
}

/// Stormtrooper E-11: black carbine with scope, cooling holes and a side magazine.
private func drawE11(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "......SSSL.....",
        ".......K.K.....",
        "KK.KKKKKKKKKKKK",
        "KKKKKKkKkKkKKK.",
        "....KK..MM.....",
        "....KK..MM.....",
    ], ["S": C(0x2C2C33), "L": C(0x7FC8FF), "K": C(0x1E1E24), "k": C(0x5A5A64), "M": C(0x3A3A42)])
}

/// Boba Fett's EE-3 carbine: short dark rifle with brass fittings and a scope.
private func drawEE3(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        ".....SSSSL....",
        "......B..B....",
        "BKKKKKKKKKKKKK",
        "KKKKBBKKKKKK..",
        "...KK.........",
        "...KK.........",
    ], ["S": C(0x2C2C33), "L": C(0xFF6A3A), "K": C(0x2A2A2E), "B": C(0xB08D57)])
}

/// The B1's E-5 blaster: slim tan-brown rifle with a shoulder stock.
private func drawE5(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "..BBBBBBBBBBB",
        "BBBBBBbBb....",
        "BB...BB......",
    ], ["B": C(0x5A4A32), "b": C(0x8A7652)])
}

private func drawJetpack(_ c: PixelCanvas, t: Double, burning: Bool) {
    let pack = C(0x7D8A6E), packShade = C(0x5E6A52)
    for x in [13, 38] {
        c.rect(x, 23, 5, 11, pack)
        c.rect(x + 4, 23, 1, 11, packShade)
        c.rect(x, 34, 5, 1, C(0x4A4A52))
    }
    c.rect(13, 21, 5, 2, C(0xC8402A))   // the missile
    c.rect(14, 20, 3, 1, C(0xC8402A))
    if burning {
        for x in [14, 39] {
            let len = 3 + Int(noise(Int(t * 30) + x) * 3)
            c.rect(x, 35, 3, len, C(0xFF9A2A))
            c.rect(x + 1, 35, 1, len + 1, C(0xFFE27A))
        }
    }
}

// MARK: - Darth Vader

/// Darth Vader. Signature: his gloved hand goes to the chest panel and works the switches.
private func drawVader(_ c: PixelCanvas, _ p: Pose) {
    drawCape(c, t: p.t, speed: p.capeSpeed, color: C(0x0E0E12), edge: C(0x2C2C36))
    drawLegs(c, Look(leg: C(0x2E2F36)), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look())
    c.rect(15, 33, 1, 3, ink)
    c.rect(40, 33, 1, 3, ink)
    c.pattern(15, 14, [
        ".........KKKKKKKK.........",
        ".......KKKKKKKKKKKK.......",
        "......KKKHHKKKKKKKKK......",
        ".....KKKHHKKKKKKKKKKK.....",
        ".....KKHHKKKKKKKKKKKK.....",
        "....KKKHKKKKKKKKKKKKKK....",
        "....KKKKKKKKKKKKKKKKKK....",
        "....KKKKKKKKKKKKKKKKKK....",
        "...KKKKKKKKKKKKKKKKKKKK...",
        "...KKKKKKKKKKKKKKKKKKKK...",
        "..KKKKKKKKKKKKKKKKKKKKKK..",
        "..KKKGGGGGGGGGGGGGGGGKKK..",
        ".KKKK................KKKK.",
        ".KKK..................KKK.",
        "KKKK..................KKKK",
        "KKK....................KKK",
        "KK......................KK",
        "K........................K",
    ], ["K": ink, "H": C(0x5C6070), "G": C(0x3A3D46)])
    c.pattern(25, 32, [".GGGG.", "GSGGSG", ".GSSG."], ["G": C(0x3A3D46), "S": C(0x9AA0AE)])
    if let s = p.signature, s > 0.12, s < 0.88 {
        // His gloved hand goes to the chest panel and works the switches; the lights flicker through.
        let lights = [C(0xE0303A), C(0x3BD15A), C(0x3A7BEA), C(0x2A2B31)]
        let k = Int(s * 20)
        c.pattern(31, 34, ["GGGGG", "G...G", "GGGGG"], ["G": C(0x3A3D46)])
        for i in 0..<3 { c.px(32 + i, 35, lights[(k + i * 3 + (k / 3)) % lights.count]) }
        c.rect(37, 33, 3, 3, C(0x0E0E12))                   // the arm swings in…
        c.rect(34, 33, 3, 2, ink)                            // …the glove on the panel's top edge
        c.rect(34, 33, 3, 1, C(0x5C6070))                    // knuckles catching the light
        c.px(34 + (k % 2), 34, C(0x5C6070))                  // a finger pressing, pressing
    } else {
        c.pattern(31, 34, ["GGGGG", "GRgBG", "GGGGG"],
                  ["G": C(0x3A3D46), "R": C(0xE0303A), "g": C(0x3BD15A), "B": C(0x3A7BEA)])
    }
    c.rect(18, 37, 20, 1, C(0x2A2B31))
    c.rect(26, 37, 4, 1, C(0x9AA0AE))
    drawRedSaber(c, p)
}

// MARK: - Kylo Ren

/// Kylo Ren: the unstable, cross-guarded blade. Signature: a tantrum, wild slashes at nothing.
private func drawKylo(_ c: PixelCanvas, _ p: Pose) {
    var melee = p.melee, trail = p.trail, breathe = p.breathe
    if let s = p.signature, s > 0.06, s < 0.94 {
        let t = p.t
        let slash = { (u: Double) -> Double in -150 + 200 * noise(Int(u * 7) + 11) }
        melee = slash(t); trail = saberTrail(t, pose: slash)
        c.ox += noise(Int(t * 14)) > 0.5 ? 1 : -1; c.oy += noise(Int(t * 7) + 5) > 0.7 ? -1 : 0
        breathe = 0
    }
    drawCape(c, t: p.t, speed: p.capeSpeed, color: C(0x0E0E12), edge: C(0x2C2C36))
    let black = C(0x1E1E24), silver = C(0xA9AEB8)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += breathe
    drawBody(c, Look(arm: black))
    c.pattern(16, 15, [
        "......KKKKKKKKKKKK......",
        "....KKKKKKKKKKKKKKKK....",
        "...KKKKKKKKKKKKKKKKKK...",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKSSSSSSSSSSSSSSSSKK..",
        "..KKKKKKKKKSSKKKKKKKKK..",
        "..KKKKKKKKKSSKKKKKKKKK..",
        ".KKKKKKKKKKSSKKKKKKKKKK.",
        ".KKKKKKKKKKSSKKKKKKKKKK.",
        ".KKK.......SS.......KKK.",
        "KKKK................KKKK",
        "KKK..................KKK",
        "KK....................KK",
    ], ["K": C(0x16161B), "S": silver])
    c.rect(27, 27, 2, 4, silver)
    c.rect(21, 28, 4, 1, silver)
    c.rect(31, 28, 4, 1, silver)
    c.rect(18, 33, 20, 5, black)
    c.rect(18, 35, 20, 1, C(0x3A3A42))
    if let a = melee {
        drawSaber(c, t: p.t, angle: a, core: C(0xFFD6D6), glow: C(0xFF2A1A), lit: true, trail: trail,
                  crossguard: true, unstable: true)
    } else {
        c.rect(36, 37, 2, 5, C(0x3A3A42)); c.rect(35, 38, 4, 1, C(0x3A3A42))
    }
}

// MARK: - Darth Maul

/// Darth Maul: red and black tattoos, horns, and the double-bladed saber.
private func drawMaul(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x1A1A1F)
    drawLegs(c, Look(leg: robe), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: C(0xC0262D), shade: C(0x8E1A20), arm: robe, eye: C(0xF5D547)))
    let K: [Character: Px] = ["K": C(0x111114)]
    c.pattern(18, 26, ["KK...K..KKKK..K...KK", "K....KK..KK..KK....K"], K)
    c.pattern(18, 32, ["..KK....KKKK....KK..", "...KKK..KKKK..KKK..."], K)
    c.px(21, 29, C(0x111114)); c.px(34, 29, C(0x111114))
    c.pattern(18, 23, ["..h..h...hh...h..h..", "..H..H...HH...H..H..", "..H..H..H..H..H..H.."], ["H": C(0xF0E6CC), "h": C(0xFFF8E6)])
    c.rect(18, 34, 20, 4, robe)
    c.rect(18, 35, 20, 1, C(0x3A3A42))
    if let a = p.melee {
        drawSaber(c, t: p.t, angle: a + 180, core: C(0xFFE3E3), glow: C(0xFF1E2D), lit: true, length: 15)
        drawSaber(c, t: p.t, angle: a, core: C(0xFFE3E3), glow: C(0xFF1E2D), lit: true, trail: p.trail, length: 15)
    } else {
        c.rect(36, 34, 2, 8, C(0x2A2A2F)); c.rect(36, 37, 2, 2, C(0xB9BEC8))
    }
}

// MARK: - Boba Fett

/// Boba Fett: jetpack (firing as he shoots), the T visor and the EE-3. Signature: the rangefinder swings down and
/// blinks red.
private func drawBoba(_ c: PixelCanvas, _ p: Pose) {
    drawJetpack(c, t: p.t, burning: p.fire.map { frac($0.t / blasterPeriod) > 0.7 } ?? false)
    let armor = C(0x6B7A5E), armorShade = C(0x4E5A44)
    drawLegs(c, Look(leg: C(0x6E6A5A)), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: armor, shade: armorShade, arm: C(0x9A8F72), eye: nil))
    c.pattern(16, 17, [
        "......GGGGGGGGGGGG......",
        "....GGGGGGGGGGGGGGGG....",
        "...GGGGGRRGGGGGGGGGGG...",
        "..GGGGGGRRGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        ".GGGGGGGGGGGGGGGGGGGGGG.",
        ".GGGGGGGGGGGGGGGGGGGGGG.",
    ], ["G": armor, "R": C(0xA8442E)])
    c.rect(20, 28, 16, 2, ink)       // T visor
    c.rect(27, 30, 2, 5, ink)
    // Rangefinder antenna, up beside the helmet. Signature: it swings down in front of the visor and blinks red.
    let swing = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let a = (-90 + 207 * swing) * .pi / 180, len = 8 + 3 * swing   // lowered, it ends over the visor's eye slot
    for k in 0..<Int(len) {
        c.px(38 + Int((cos(a) * Double(k)).rounded()), 18 + Int((sin(a) * Double(k)).rounded()), C(0x9AA0AE))
    }
    c.rect(37, 17, 2, 2, C(0x9AA0AE))
    if swing > 0.95, let s = p.signature {
        let end = (x: 38 + Int((cos(a) * (len - 1)).rounded()), y: 18 + Int((sin(a) * (len - 1)).rounded()))
        c.rect(end.x - 1, end.y, 2, 2, C(0x5A5E68))         // the scope
        if Int(s * 14) % 2 == 0 { c.px(end.x - 1, end.y, C(0xFF3A2A)) }
    }
    c.rect(18, 35, 20, 1, armorShade)
    c.rect(18, 37, 20, 1, C(0x6B4A2B))
    c.rect(21, 37, 2, 1, C(0xB08D57)); c.rect(32, 37, 2, 1, C(0xB08D57))
    c.oy += gunY(p)
    drawEE3(c, x: 38, y: 30)
}

// MARK: - Stormtrooper

/// A Stormtrooper. Signature: he bumps his head (on a door that isn't there): a jolt back, stars round the helmet,
/// a rub.
private func drawTrooper(_ c: PixelCanvas, _ p: Pose) {
    let armor = C(0xF2F3F5), edge = C(0x8C93A0)
    let bump = p.signature
    if let s = bump, s > 0.1, s < 0.2 { c.ox -= 1 }
    // Faint outline so the white armour still reads on a white window.
    c.rect(18, 36, 2, 1, edge)
    drawLegs(c, Look(leg: C(0xC3C9D2)), step: p.step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 39, 2, 1, edge) }
    c.oy += p.breathe
    c.rect(17, 25, 22, 14, edge)
    drawBody(c, Look(body: armor, shade: C(0xC9CED6), arm: armor, eye: nil))
    c.pattern(15, 16, [
        ".......oooooooooooo.......",
        ".....ooWWWWWWWWWWWWoo.....",
        "....oWWWWWWWWWWWWWWWWo....",
        "...oWWWWWWWWWWWWWWWWWWo...",
        "..oWWWWWWWWWWWWWWWWWWWWo..",
        "..oWWWWWWWWWWWWWWWWWWWWo..",
        "..oWWWWWWWWWWWWWWWWWWWWo..",
        "..oggggggggggggggggggggo..",
        ".oWWWWWWWWWWWWWWWWWWWWWWo.",
        ".oWWWWWWWWWWWWWWWWWWWWWWo.",
    ], ["W": armor, "g": C(0x9AA0AE), "o": edge])
    c.rect(21, 28, 4, 3, ink)
    c.rect(31, 28, 4, 3, ink)
    c.rect(25, 32, 6, 2, C(0x9AA0AE))
    c.px(26, 32, ink); c.px(28, 32, ink); c.px(30, 32, ink)
    c.rect(18, 36, 20, 1, ink)
    c.rect(27, 36, 2, 1, armor)
    if let s = bump, s > 0.15, s < 0.92 {
        for i in 0..<3 {                                   // stars circling the helmet
            let a = s * 14 + Double(i) * 2.1
            let x = 28 + Int((cos(a) * 9).rounded()), y = 13 + Int((sin(a) * 2).rounded())
            let col = (i == 1 ? C(0xFFF2A0) : C(0xFFD25A)).alpha(s > 0.8 ? (0.92 - s) / 0.12 : 1)
            c.px(x, y, col); c.px(x - 1, y, col.alpha(0.5)); c.px(x + 1, y, col.alpha(0.5))
            c.px(x, y - 1, col.alpha(0.5)); c.px(x, y + 1, col.alpha(0.5))
        }
        if s > 0.3 {                                       // a hand up to rub the side of the helmet
            let rub = Int(s * 16) % 2
            c.rect(38, 24 + rub, 3, 10 - rub, edge)        // the forearm bent up from the elbow
            c.rect(39, 25 + rub, 1, 8 - rub, armor)
        }
    }
    c.oy += gunY(p)
    drawE11(c, x: 37, y: 30)
}

// MARK: - The Emperor

/// The Emperor: hooded robe, no legs showing, lightning from his raised hand.
private func drawEmperor(_ c: PixelCanvas, _ p: Pose) {
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.6, color: C(0x111116), edge: C(0x2A2A33), extra: 1.5)
    let robe = C(0x1A1A20), robeEdge = C(0x2E2E38)
    for y in 36...43 {
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, robe)
        c.px(17 - k, y, robeEdge); c.px(38 + k, y, robeEdge)
    }
    c.oy += p.breathe
    var look = Look(body: C(0xD08A6C), shade: C(0xA86A50), arm: robe, eye: C(0xF5D547))
    look.legs = false
    // Waiting for you, the lightning crackles in his hand without his raising it.
    let raise = p.mode == .waiting && !p.walking ? 0 : p.armRaise
    drawBody(c, look, armRight: raise)
    drawHood(c, robe, robeEdge)
    c.rect(18, 33, 20, 5, robe)
    c.rect(26, 33, 4, 1, C(0xA86A50))
}

// MARK: - R0-GR

/// R0-GR, a B1 battle droid: tan, skinny-limbed, with the long forward-pointing snout head.
private func drawRogr(_ c: PixelCanvas, _ p: Pose) {
    let tan = C(0xD4C08F), tanShade = C(0xA8946A), dark = C(0x6E5E3E)
    let look = Look(body: tan, shade: tanShade, leg: C(0xC2AE7E), arm: tan, eye: nil)
    // Thin droid legs: draw them, then carve them narrower.
    drawLegs(c, look, step: p.step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 38, 1, 4, dark) }
    c.oy += p.breathe
    drawBody(c, look)
    c.rect(20, 28, 16, 1, tanShade)          // chest plates
    c.rect(20, 31, 16, 1, tanShade)
    c.rect(26, 27, 4, 8, C(0xC7B282))
    c.rect(24, 34, 8, 2, dark)               // backpack strap / power unit
    c.rect(27, 22, 2, 4, dark)               // neck
    c.pattern(21, 15, [
        "....HHHHHH......",
        "..HHHHHHHHHHH...",
        ".HHEEHHHHHHHHHHH",
        ".HHEEHHHHHHHHHHs",
        "..HHHHHHHHHHHss.",
        "....hhhhhhhh....",
        ".....hhhhh......",
    ], ["H": tan, "h": tanShade, "s": tanShade, "E": C(0x2A2418)])
    c.oy += gunY(p)
    drawE5(c, x: 39, y: 31)
}

// MARK: - Count Dooku

/// Count Dooku: brown cape, white hair and pointed beard, a red saber.
private func drawDooku(_ c: PixelCanvas, _ p: Pose) {
    drawCape(c, t: p.t, speed: p.capeSpeed, color: C(0x2A1A14), edge: C(0x4A3024))
    let robe = C(0x2A1A14)
    drawLegs(c, Look(leg: C(0x1E1410)), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: robe))
    let W = C(0xDCDCDC), w = C(0xB4B4B4)
    c.pattern(18, 22, ["....WWWWWWWWWWWW....", "..WWwWWWWWWWWWWwWW..", ".WW..............WW.", "WW................WW"], ["W": W, "w": w])
    c.pattern(24, 32, ["WW....WW", ".WWWWWW.", "..WWWW..", "...WW..."], ["W": W])   // pointed beard
    c.rect(18, 33, 20, 5, robe)
    c.pattern(24, 32, ["WW....WW", ".WWWWWW.", "..WWWW..", "...WW..."], ["W": W])
    c.rect(18, 36, 20, 1, C(0x8A6A3A))
    c.rect(26, 35, 4, 1, C(0xC9A44A))   // cape clasp chain
    drawRedSaber(c, p)
}

// MARK: - Gamorrean Guard

/// A Gamorrean guard: green, horned leather cap, snout and tusks, and a vibro-axe shouldered at rest.
private func drawGamorrean(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x6E8B3D), greenDark = C(0x55702C), leather = C(0x5A3A22)
    drawLegs(c, Look(leg: greenDark), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    c.pattern(17, 18, ["H..................H", "HH..LLLLLLLLLLLL..HH", ".HLLLLLLLLLLLLLLLLH.", "..LLLLLLLLLLLLLLLL..",
                       ".LLLLLLLLLLLLLLLLLL.", "LLLLLLLLLLLLLLLLLLLL", "LL................LL"],
              ["L": leather, "H": C(0xE8DCC0)])                 // leather cap with horns
    c.rect(23, 28, 2, 2, C(0x1A1A10)); c.rect(32, 28, 2, 2, C(0x1A1A10))   // small piggy eyes
    c.pattern(25, 30, [".PPPPP.", "PPkPkPP", ".PPPPP."], ["P": C(0x9AB070), "k": C(0x2A2A18)])   // snout
    c.px(23, 34, C(0xF4EEDC)); c.px(33, 34, C(0xF4EEDC))      // tusks
    c.rect(18, 35, 20, 3, C(0x6A4A2A))                          // fur loincloth
    for x in stride(from: 19, to: 38, by: 3) { c.px(x, 37, C(0x4A3020)) }
    drawAxe(c, angle: swungUp(p, from: -78) ?? -75)            // resting: axe shouldered, not through the floor
}

/// The Gamorrean guard's vibro-axe: a long haft with a heavy blade at the end.
private func drawAxe(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 3, hy - uy * 3, hx + ux * 17, hy + uy * 17, core: C(0x5A3A22), glow: clear, coreR: 0.8, glowR: 0.9)
    // Blade: a wedge on one side of the haft near the end
    let px = -uy, py = ux
    for i in 0..<6 {
        let along = 12.0 + Double(i)
        let width = 4.5 - abs(Double(i) - 2.5) * 0.6
        c.glowLine(hx + ux * along, hy + uy * along, hx + ux * along + px * width, hy + uy * along + py * width,
                   core: C(0xA9AEB8), glow: clear, coreR: 0.7, glowR: 0.8)
    }
    c.glowLine(hx + ux * 12 + px * 4.5, hy + uy * 12 + py * 4.5, hx + ux * 17 + px * 4.5, hy + uy * 17 + py * 4.5,
               core: C(0xE4E8EE), glow: clear, coreR: 0.6, glowR: 0.7)
}

// MARK: - Jabba the Hutt

/// Jabba: the big slug, laughing. Signature: his eyes narrow and the fat tongue slides out and licks his lips.
private func drawJabba(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8E8B4E), dark = C(0x6E6B38), belly = C(0xB0A86A)
    let laugh = sin(p.t * 9) > 0 ? -1 : 0
    // Tail curling off behind, then the big slug body (no legs).
    c.pattern(4, 36, ["......SSSS", "...SSSSSSS", ".SSSSSSSSS", "SSSSSSSSSS", "SS........"], ["S": dark])
    // the belly stays planted on the floor; only the upper body bobs as he laughs
    for y in 40...43 {
        let hw = 10 + Double(y - 22) / 21 * 7
        let l = Int((Sprite.bodyCenterX - hw).rounded()), r = Int((Sprite.bodyCenterX + hw).rounded())
        c.rect(l, y, r - l, 1, skin)
    }
    c.oy += p.breathe + laugh
    for y in 22...43 {
        let k = Double(y - 22) / 21
        let hw = 10 + k * 7
        let l = Int((Sprite.bodyCenterX - hw).rounded()), r = Int((Sprite.bodyCenterX + hw).rounded())
        c.rect(l, y, r - l, 1, skin)
        c.px(l, y, dark); c.px(r - 1, y, dark)
    }
    c.rect(20, 34, 18, 9, belly)
    for y in stride(from: 35, to: 43, by: 2) { c.rect(21, y, 16, 1, C(0x9A925A)) }
    c.pattern(21, 26, ["OOO.....OOO", "OKO.....OKO"], ["O": C(0xE08A2A), "K": C(0x2A1A0A)])   // slit eyes
    c.rect(19, 31, 20, 1, C(0x4A4626))                          // the enormous mouth
    c.rect(20, 32, 18, 1, laugh < 0 ? C(0x7A3A3A) : dark)
    c.rect(38, 33, 4, 2, skin)                                  // tiny arm
    if let s = p.signature, s > 0.1, s < 0.9 {
        let k = (s - 0.1) / 0.8
        c.rect(21, 26, 3, 1, skin); c.rect(29, 26, 3, 1, skin)  // heavy lids
        c.rect(20, 31, 18, 2, C(0x4A2A26))                      // mouth open
        let tx = 21 + Int((0.5 - 0.5 * cos(k * 2 * .pi)) * 12)
        c.rect(tx, 32, 5, 2, C(0xC86A72)); c.rect(tx + 1, 34, 3, 1, C(0xC86A72))
        c.px(tx + 2, 32, C(0xA84A54))
        if frac(k * 3) < 0.5 { c.px(tx + 4, 35, C(0xD8E8F0).alpha(0.8)) }   // a drip
    }
}

// MARK: - IG-88

/// IG-88: the tall cylindrical sensor head. Signature: the sensor bands light up and spin round it, scanning.
private func drawIg88(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x6F747C), metalDark = C(0x4C5058), metalLight = C(0x9AA0A8)
    drawLegs(c, Look(leg: metalDark), step: p.step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 39, 2, 1, metalLight) }
    c.oy += p.breathe
    drawBody(c, Look(body: metal, shade: metalDark, arm: metalDark, eye: nil))
    c.rect(20, 28, 16, 2, metalDark); c.rect(22, 31, 12, 4, metalDark)    // chest plating
    c.rect(24, 32, 2, 2, C(0xE0303A)); c.rect(30, 32, 2, 2, C(0xE0303A))
    c.rect(27, 22, 2, 4, metalDark)                                       // neck
    // Tall cylindrical sensor head
    c.pattern(23, 9, ["..MMMMMM..", ".MMLMMMMM.", "MMLMMMMMMM", "MMLMMMMMMM", "RRRRRRRRRR", "MMLMMMMMMM",
                      "MMLMMMMMMM", "MMLMMMMMMM", "RRRRRRRRRR", "MMLMMMMMMM", "MMMMMMMMMM", ".MMMMMMMM.", "..MMMMMM.."],
              ["M": metal, "L": metalLight, "R": C(0xC0392B)])
    if let s = p.signature, s > 0.08, s < 0.92 {
        for (row, phase) in [(13, 0), (17, 5)] {
            c.rect(23, row, 10, 1, C(0x5A1A14))                      // the band dims…
            let k = Int(s * 46) + phase
            for j in 0..<4 {                                         // …and a bright segment runs round it
                let x = 23 + (k + j) % 10
                c.px(x, row, j == 1 || j == 2 ? C(0xFFF0E8) : C(0xFF4A30))
                c.px(x, row - 1, C(0xFF6A50).alpha(0.5)); c.px(x, row + 1, C(0xFF6A50).alpha(0.5))   // glow
            }
        }
    }
    c.oy += gunY(p)
    drawE11(c, x: 37, y: 30)
}

// MARK: - AT-ST

/// AT-ST: a grey cockpit Clawd on two long jointed legs, chin guns forward.
private func drawAtst(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x8A8F9C), dark = C(0x5C616C), light = C(0xB4BAC6)
    // Legs: hip, backward knee, ankle, wide foot. The lifted leg steps up a pixel.
    for (i, hx) in [22, 32].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(hx, 24, 3, 8 - up, dark)                    // thigh
        c.rect(hx - 3, 31 - up, 4, 2, metal)               // knee joint (bends back)
        c.rect(hx - 2, 32 - up, 3, 10, metal)              // shin
        c.rect(hx - 5, 42 - up, 10, 2, dark)               // foot
        c.rect(hx - 5, 42 - up, 2, 1, light)
    }
    c.oy += p.breathe
    // The cockpit: Clawd-shaped head with a viewport slit, side guns and chin cannons.
    c.rect(18, 12, 20, 12, metal)
    c.rect(18, 12, 20, 2, light)
    c.rect(37, 12, 1, 12, dark)
    c.rect(22, 16, 13, 2, C(0x1A1C21))                     // viewport
    c.px(24, 16, C(0xE0303A))
    c.rect(16, 15, 2, 6, dark); c.rect(38, 17, 3, 3, dark) // side pods
    c.rect(38, 21, 9, 1, C(0x3A3D46)); c.rect(38, 23, 7, 1, C(0x3A3D46))   // chin guns
    c.rect(24, 24, 8, 2, dark)                             // hip block
}

// MARK: - AT-AT

/// AT-AT: Clawd as the walker's body (it already has four legs), with the neck, the head and chin cannons.
private func drawAtat(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x9A9EA8), dark = C(0x6A6F7A), light = C(0xC4C8D0)
    for (i, lx) in [16, 22, 34, 40].enumerated() {
        let up = p.step >= 0 && i % 2 == p.step ? 1 : 0
        c.rect(lx, 26, 3, 7 - up, metal)                   // upper leg
        c.rect(lx - 1, 32 - up, 5, 2, dark)                // knee
        c.rect(lx, 34 - up, 3, 8, metal)                   // lower leg
        c.rect(lx - 1, 42 - up, 5, 2, dark)                // round foot
    }
    c.oy += p.breathe
    // Body
    c.rect(13, 14, 32, 12, metal)
    c.rect(13, 14, 32, 2, light)
    c.rect(13, 24, 32, 2, dark)
    for x in stride(from: 17, to: 44, by: 6) { c.rect(x, 17, 1, 6, dark) }   // armour plates
    // Neck and head
    c.rect(45, 17, 4, 4, dark)
    c.rect(49, 13, 13, 9, metal)
    c.rect(49, 13, 13, 2, light)
    c.rect(52, 16, 6, 2, C(0x1A1C21))                      // viewport
    c.rect(62, 15, 2, 5, dark)                             // snout
    c.rect(56, 21, 8, 1, C(0x3A3D46)); c.rect(58, 22, 4, 1, C(0x3A3D46))  // chin cannons
}

// MARK: - Rancor

/// The Rancor's shoulder, below the jaw: its claw arm pivots here (the fight effects need it too).
private let rancorShoulder = (x: 35.0, y: 25.0)

/// The rancor: a towering, hunched reptile that stands upright on two short, stubby legs, with a flat face
/// that's mostly fanged mouth, tiny eyes, spines over its back and shoulders, and very long arms.
/// Signature: it throws its head up and roars, jaws gaping, the air shaking in front of it.
private func drawRancor(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0x8A7A62), shade = C(0x6A5C48), light = C(0xA89878), spine = C(0x4A3E30), claw = C(0xE8DCC0)
    for (i, lx) in [21, 31].enumerated() {                          // two short, stubby legs
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 35, 6, 8 - up, shade)
        c.rect(lx - 1, 42 - up, 8, 2, C(0x54483A))
        for k in 0..<3 { c.px(lx - 1 + k * 3, 43 - up, claw) }      // three toes
    }
    c.oy += p.signature == nil ? p.breathe : 0                      // it holds still to roar
    // tall torso, hunched forward (shoulders lean right)
    for y in 14...36 {
        let lean = (36 - y) / 4                                     // top leans toward the head
        c.rect(19 + lean, y, 18, 1, hide)
        c.px(19 + lean, y, shade)
    }
    c.rect(21, 33, 16, 3, shade)                                    // belly fold
    for (x, y) in [(24, 20), (29, 25), (23, 29), (32, 18), (27, 31), (33, 28)] { c.rect(x, y, 2, 1, light) }   // scales
    for k in 0..<5 { c.px(21 + k * 3 + (5 - k) / 2, 13 - k % 2, spine); c.px(21 + k * 3 + (5 - k) / 2, 14, spine) }  // back spines
    // the near arm hangs almost to the ground: they're long
    c.rect(16, 19, 4, 20, shade)
    c.rect(15, 38, 6, 2, shade)
    for k in 0..<3 { c.px(15 + k * 2, 40, claw) }
    c.px(17, 22, spine); c.px(17, 26, spine)
    // flat face dominated by the mouth, thrust forward on the hunch
    c.rect(34, 9, 13, 14, hide)
    c.rect(34, 9, 13, 2, light)
    c.px(37, 11, spine); c.px(41, 10, spine)                        // brow ridges
    c.px(38, 12, C(0xFFD23D)); c.px(43, 12, C(0xFFD23D))            // tiny eyes
    let roar = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let gape = Int((roar * 4).rounded())
    if gape > 0 { c.rect(34, 22, 13, gape, hide) }                  // the jaw drops
    c.rect(35, 15, 12, 7 + gape, C(0x3A1A12))                       // the mouth
    for k in 0..<6 { c.px(35 + k * 2, 15, claw); c.px(36 + k * 2, 21 + gape, claw) }   // fangs top and bottom
    c.rect(35, 22 + gape, 12, 1, shade)                             // jaw
    if roar > 0.9, let s = p.signature {
        for i in 0..<3 {                                             // the roar: arcs pushing out from the mouth
            let f = frac(s * 4 + Double(i) / 3), x = 49 + Int(f * 10), col = C(0xF4EEE0).alpha(0.8 * (1 - f))
            for dy in -2 - i...(2 + i) where abs(dy) > 0 || i == 0 { c.px(x + abs(dy) / 2, 18 + gape / 2 + dy, col) }
        }
        if frac(s * 14) < 0.5 { c.px(41, 12, C(0xFFF07A)) }         // a mad glint
    }
    drawClaw(c, angle: swungUp(p, from: 30) ?? 30)                  // resting: arm hangs forward, claws above the floor
}

/// The rancor's reaching arm: very long, thick, ending in three claws.
private func drawClaw(_ c: PixelCanvas, angle: Double) {
    let (hx, hy) = rancorShoulder
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx, hy, hx + ux * 20, hy + uy * 20, core: C(0x7A6A54), glow: clear, coreR: 1.8, glowR: 1.9)
    let tx = hx + ux * 20, ty = hy + uy * 20
    for k in -1...1 {
        let a = r + Double(k) * 0.35
        c.glowLine(tx, ty, tx + cos(a) * 5, ty + sin(a) * 5, core: C(0xE8DCC0), glow: clear, coreR: 0.6, glowR: 0.7)
    }
}

// MARK: - Greedo

/// Greedo: a green Rodian Clawd: huge glossy black eyes, a tapir snout, spines on top, a vest and a pistol.
private func drawGreedo(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5E9A4A), skinShade = C(0x467A36), skinLight = C(0x7AB860)
    drawLegs(c, Look(leg: C(0x4A4A52)), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: skin, eye: nil))
    // head spines and the little ear fans
    c.pattern(19, 21, ["...S..S..S...S..S...", "..SSS.SS.SS..SS.SSS.", ".SSSSSSSSSSSSSSSSSS."], ["S": skinShade])
    c.pattern(14, 27, ["EE", "EEE", "EE"], ["E": skinLight]); c.pattern(39, 27, [".EE", "EEE", ".EE"], ["E": skinLight])
    for (x, y) in [(20, 27), (35, 26), (24, 35), (31, 34)] { c.px(x, y, skinLight) }
    // the big multifaceted eyes
    for ex in [20, 31] {
        c.rect(ex, 27, 5, 5, C(0x0A0C10)); c.rect(ex + 1, 26, 3, 7, C(0x0A0C10))
        c.px(ex + 1, 28, C(0x6A8AB0)); c.px(ex + 2, 27, C(0xBFD8F0))
    }
    // tapir snout
    c.rect(26, 31, 4, 3, skinShade); c.rect(27, 34, 2, 2, skinShade); c.px(27, 35, C(0x2A3A20))
    // vest over a pale tunic
    c.rect(18, 33, 20, 5, C(0xC8BCA0))
    c.rect(18, 33, 5, 5, C(0x3A3A2E)); c.rect(33, 33, 5, 5, C(0x3A3A2E))
    c.rect(18, 37, 20, 1, C(0x5A4A32))
    c.oy += gunY(p)
    c.pattern(40, 31, [".KKKKK", "KKKKSK", "KK....", "KK...."], ["K": C(0x2A2A30), "S": C(0x8A8F9C)])
}

// MARK: - Royal Guard

/// The Emperor's Royal Guard: crimson from head to foot, a floor-length robe over a smooth, tall helmet with a
/// black T-shaped visor slit, and a force pike held upright.
private func drawRoyalGuard(_ c: PixelCanvas, _ p: Pose) {
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.5, color: C(0x6E0C10), edge: C(0x8E1418), extra: 0.5)
    let red = C(0xB3161B), dark = C(0x7E0E12), shine = C(0xE0484C)
    for y in 36...43 {
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, red)
        c.px(17 - k, y, dark); c.px(38 + k, y, dark)
        if y > 38 { c.px(23, y, dark); c.px(32, y, dark) }       // folds
    }
    c.oy += p.breathe
    var look = Look(body: red, shade: dark, arm: red, eye: nil)
    look.legs = false
    drawBody(c, look)
    c.pattern(16, 13, [
        ".........RRRRRR.........",
        ".......RRRRRRRRRR.......",
        "......RRSSRRRRRRRR......",
        "......RSSRRRRRRRRRD.....",
        ".....RRSRRRRRRRRRRRD....",
        ".....RSSRRRRRRRRRRRD....",
        ".....RSRRRRRRRRRRRRD....",
        ".....RSRRRRRRRRRRRRD....",
        "....RRRRRRRRRRRRRRRRD...",
        "....RRRRRRRRRRRRRRRRD...",
        "...RRRRRRRRRRRRRRRRRRD..",
        "..RRRRRRRRRRRRRRRRRRRRD.",
        ".RRRRRRRRRRRRRRRRRRRRRRD",
        "DDDDDDDDDDDDDDDDDDDDDDDD",
    ], ["R": red, "S": shine, "D": dark])
    c.rect(21, 29, 14, 1, ink)          // the visor: a narrow slit across…
    c.rect(27, 29, 2, 4, ink)           // …and down the middle
    c.rect(18, 35, 20, 1, dark)         // where the robe falls from the shoulders
    drawPike(c, angle: swungUp(p, from: -78) ?? -84)   // resting: held upright at its side, as they stand guard
}

/// The Royal Guard's force pike: a long dark staff with a silver head, the tip crackling when it's swung.
private func drawPike(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 7, hy - uy * 7, hx + ux * 17, hy + uy * 17, core: C(0x8A8E99), glow: clear, coreR: 0.7, glowR: 0.8)
    c.glowLine(hx + ux * 17, hy + uy * 17, hx + ux * 21, hy + uy * 21, core: C(0xC9CED8), glow: clear, coreR: 0.8, glowR: 0.9)
    c.glowLine(hx + ux * 21, hy + uy * 21, hx + ux * 22.5, hy + uy * 22.5, core: C(0xFFF2C0), glow: clear, coreR: 0.6, glowR: 0.7)
}
