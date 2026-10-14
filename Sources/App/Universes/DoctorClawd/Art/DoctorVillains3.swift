import Foundation

// Villains: the Time Lords gone bad, the old gods and the oddities. Clawd in costume here too: robes, masks, wigs and
// collars over the orange body, or Clawd turned into the costume itself (stretched on a frame, packed in snow, made
// of sweets).

let doctorVillains3: [DoctorVillain: Persona] = [
    .davross: Persona(name: "Davross", weapon: .lightning, motion: .hover, magic: Magic(core: C(0xE8F6FF), glow: C(0x3A9CFF)),
                  canSit: false, pivot: (42.5, 31), headTop: 18,
                  draw: drawDavross),
    .omegah: Persona(name: "Omegah", weapon: .lightning, magic: Magic(core: C(0xFFF0D8), glow: C(0xFF5A1E)),
                  headTop: 12,
                  draw: drawOmegah),
    .rascilon: Persona(name: "Rascilon", weapon: .blaster, shot: .beam(core: C(0xFFFFFF), glow: C(0xF0B82A)),
                  muzzle: (43, 32), handGun: false, headTop: 9,
                  draw: drawRascilon),
    .toyfaker: Persona(name: "The Celestial Toyfaker", weapon: .blaster, shot: .card, muzzle: (42, 31.5), headTop: 15,
                  signature: 2.8,
                  draw: drawToyfaker),
    .sootekh: Persona(name: "Sootekh", weapon: .lightning, magic: Magic(core: C(0xF6ECC8), glow: C(0xB8964E), jagged: false),
                  headTop: 7,
                  draw: drawSootekh),
    .grateIntelligence: Persona(name: "The Grate Intelligence", weapon: .blaster, shot: .ice, muzzle: (45, 30),
                  headTop: 15,
                  draw: drawGrateIntelligence),
    .valeyarn: Persona(name: "The Valeyarn", weapon: .blaster, shot: .energy(core: C(0xF4E8FF), glow: C(0x9A4AE8)),
                  muzzle: (47, 32), headTop: 12,
                  draw: drawValeyarn),
    .maestro: Persona(name: "The Maestro", weapon: .lightning, magic: Magic(core: C(0xFFF4FF), glow: C(0xE84AC8), jagged: false),
                  pivot: maestroBaton, headTop: 15, signature: 3.2,
                  draw: drawMaestro),
    .cassandro: Persona(name: "Lady Cassandro", motion: .hover, canSit: false, headTop: 13, callout: "Moisturise me!",
                  draw: drawCassandro),
    .clockworkDroid: Persona(name: "Clockwork Droid", weapon: .saber, headTop: 17, signature: 2.4,
                  draw: drawClockworkDroid),
    .candyman: Persona(name: "The Candyman", headTop: 18,
                  draw: drawCandyman),
]

/// The tip of the Maestro's baton, held out: the music leaves from there (raised by the pose's `armRaise`).
private let maestroBaton = (x: 46.5, y: 28.5)

// MARK: - Shared bits

private let clear = C(0, 0)

/// Long robes down over the legs to just above the feet (not when sitting: the legs fold out from under them).
private func drawRobeSkirt(_ c: PixelCanvas, _ main: Px, _ edge: Px) {
    guard !seatedPose else { return }
    for y in 36...40 {
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, main)
        c.px(17 - k, y, edge); c.px(38 + k, y, edge)
    }
}

/// A little music note, its head at the bottom left.
private func drawNote(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.rect(x, y + 3, 2, 1, col); c.px(x, y + 4, col); c.px(x + 1, y + 4, col.alpha(0.6))
    c.rect(x + 1, y, 1, 3, col); c.px(x + 2, y, col); c.px(x + 2, y + 1, col.alpha(0.7))
}

/// A cog, `phase` 0/1 turning it a tooth on.
private func drawCog(_ c: PixelCanvas, _ x: Int, _ y: Int, phase: Int, _ col: Px, _ dark: Px) {
    c.rect(x, y, 3, 3, col); c.px(x + 1, y + 1, dark)
    if phase % 2 == 0 {
        c.px(x + 1, y - 1, col); c.px(x + 1, y + 3, col); c.px(x - 1, y + 1, col); c.px(x + 3, y + 1, col)
    } else {
        c.px(x - 1, y - 1, col); c.px(x + 3, y - 1, col); c.px(x - 1, y + 3, col); c.px(x + 3, y + 3, col)
    }
}

// MARK: - Davross

/// Davross: what's left of him is Clawd from the chest up, in a black tunic, sat in the lower half of a gunmetal Dalick
/// (studs and all) that glides about for him. A wrinkled, scarred grey bald cap over his head, his eyes half shut, and
/// the single blue lamp in his forehead that pulses. One withered hand on the chair's console; he raises it to throw
/// blue lightning from his fingertips.
private func drawDavross(_ c: PixelCanvas, _ p: Pose) {
    let casing = C(0x3E3E48), casingLight = C(0x62626E), casingDark = C(0x26262E), stud = C(0xA8B4C4), studDark = C(0x5E6878)
    let skin = C(0x9A8C84), skinDark = C(0x6E6058), skinLight = C(0xB8AAA0), scar = C(0x5A4644)
    let tunic = C(0x1E1E24), tunicLight = C(0x3A3A44), blue = C(0x6AC8FF)

    // Clawd from the chest up, sunk in the chair.
    c.oy += p.breathe
    c.rect(18, 26, 20, 8, clawdOrange); c.rect(37, 26, 1, 8, clawdShade)
    c.rect(18, 32, 20, 2, tunic)
    for x in [20, 24, 31, 35] { c.px(x, 32, tunicLight) }
    c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)              // half-shut eyes
    c.rect(22, 29, 2, 1, skinDark); c.rect(32, 29, 2, 1, skinDark)    // heavy lids
    // The bald cap, wrinkled and scarred, down the sides of his face.
    c.pattern(18, 19, [
        "......SSSSSSSS......",
        "....SSSLLLSSSSSS....",
        "...SSLLSSSSSSxSSSS..",
        "..SSSSSSxxSSSSSSSSS.",
        ".SSSSxSSSSSSSSSSxSSS",
        ".SSSSSSSSSSSSSSSSxSS",
        "SSdSSSSSSSSSSSSSSdSS",
        "SddSSSSSSSSSSSSSSSdS",
        "SS................dS",
        "Sd.................S",
        "S..................d",
    ], ["S": skin, "L": skinLight, "x": scar, "d": skinDark])
    c.rect(19, 23, 3, 1, scar); c.px(22, 24, scar)
    // The lamp in his forehead.
    let pulse = 0.6 + 0.4 * sin(p.t * 4)
    c.rect(27, 22, 2, 2, blue); c.px(27, 22, white)
    c.glowLine(28, 23, 28, 23, core: clear, glow: blue.alpha(pulse * 0.7), coreR: 0.1, glowR: 2.6)
    c.oy -= p.breathe

    // The chair: a Dalick's skirt from the waist down, studded, on its base.
    c.rect(14, 42, 29, 2, casingDark); c.rect(14, 42, 29, 1, casingLight)
    for y in 34...41 {
        let k = (y - 34) / 3
        c.rect(18 - k, y, 21 + k * 2, 1, casing)
        c.px(37 + k, y, casingDark); c.px(38 + k, y, casingDark)
    }
    for (row, y) in [35, 38].enumerated() {
        for col in 0..<4 {
            let x = 19 - row + col * (5 + row)
            c.rect(x, y, 2, 2, studDark); c.px(x, y, stud)
        }
    }
    c.rect(16, 33, 25, 1, casingLight); c.rect(16, 34, 25, 1, casingDark)   // the rim round his waist
    // The console in front of him, its lights blinking.
    c.rect(37, 31, 5, 3, casing); c.rect(37, 31, 5, 1, casingLight)
    let blink = Int(p.t * 3)
    c.px(38, 32, noise(blink) > 0.5 ? C(0xFF4A3A) : C(0x7A2A22))
    c.px(40, 32, noise(blink + 9) > 0.4 ? C(0x5AE06A) : C(0x2A6A32))

    // His one hand: on the console, or raised, its fingertips blue.
    c.oy += p.breathe
    let raise = p.armRaise
    c.rect(37, 30 - raise, 3, 2, tunic)
    c.rect(40, 30 - raise, 2, 2, skin); c.px(40, 31 - raise, skinDark)
    let lit = p.zap != nil
    c.px(42, 30 - raise, lit ? blue : skinDark); c.px(42, 31 - raise, lit ? white : skin)
}

// MARK: - Omegah

/// Omegah: the forgotten engineer of time, in a crimson cloak with a black-iron helmet crowned with gold spikes and a
/// smooth silver mask over his face, Clawd's eyes staring out through it. Antimatter crackles red-orange from his hand.
private func drawOmegah(_ c: PixelCanvas, _ p: Pose) {
    let cloak = C(0x8A1A22), cloakDark = C(0x5A0E14), iron = C(0x2E2E36), ironLight = C(0x4E4E5A)
    let gold = C(0xE0B040), goldDark = C(0x9A7426), silver = C(0xD0CCC0), silverDark = C(0x9A968C)

    // The cloak, behind him.
    let sway = Int((sin(p.t * p.capeSpeed) * 1).rounded())
    for y in 27...41 {
        let k = (y - 27) / 3
        c.rect(15 - k + (y > 36 ? sway : 0), y, 26 + k, 1, y % 4 == 0 ? cloakDark : cloak)
    }
    drawLegs(c, Look(leg: C(0x24242C)), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: cloak, eye: nil), armRight: p.armRaise)
    // The tunic: crimson, gold chain and medallion.
    c.rect(18, 33, 20, 5, cloak); c.rect(37, 33, 1, 5, cloakDark)
    c.rect(18, 33, 20, 1, gold)
    c.rect(27, 34, 2, 2, gold); c.px(27, 34, C(0xFFE89A))
    c.rect(18, 33, 3, 5, cloakDark); c.rect(35, 33, 3, 5, cloakDark)
    // The mask.
    c.rect(19, 26, 18, 7, silver); c.rect(36, 26, 1, 7, silverDark); c.rect(19, 32, 18, 1, silverDark)
    c.rect(28, 28, 1, 4, C(0xE8E4DA))
    for x in [21, 31] { c.rect(x, 28, 4, 5, goldDark) }
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(25, 32, 6, 1, C(0x5A5650))
    // The helmet, crowned in spikes.
    c.pattern(17, 12, [
        "..G...G....G....G...G.",
        "..G...G....G....G...G.",
        "..GG..GG...G...GG..GG.",
        "...G...G..GGG..G...G..",
        "...GG..GG.GGG.GG..GG..",
        "....GGGGGGGGGGGGGGGG..",
        ".....IIIIIIIIIIIII....",
        "...IIIiIIIIIIIIIIII...",
        "..IIIIIIIIIIIIIIIIII..",
        ".IIIIiIIIIIIIIIIIIIII.",
        ".IIIIIIIIIIIIIIIIIIII.",
        ".IIIIIIIIIIIIIIIIIIII.",
        ".IIIggggggggggggggIII.",
        ".IIg..............gII.",
        ".II................II.",
        ".I..................I.",
    ], ["G": gold, "g": goldDark, "I": iron, "i": ironLight])
    // The hand.
    c.px(40, 33 - p.armRaise, C(0xC8C0B0))
}

// MARK: - Rascilon

/// Rascilon: the founder of the Time Lords, in scarlet robes with the great round collar fanned up behind his head,
/// scarlet and gold and ribbed, a gold skullcap, the Seal on his chest and the gold gauntlet on his right hand, which
/// fires a white-gold beam that unmakes whoever it hits.
private func drawRascilon(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0xB0242A), robeDark = C(0x7A161C), gold = C(0xE8C04A), goldDark = C(0xA8842A), goldLight = C(0xFFE89A)
    c.oy += p.breathe
    // The collar, fanned up behind him.
    for y in 9...31 {
        let d = Double(31 - y) / 22
        let hw = Int((15 * (1 - d * d).squareRoot()).rounded())
        c.rect(28 - hw, y, hw * 2, 1, gold)
        if y > 9 {
            let d2 = Double(31 - y) / 21
            let iw = Int((14 * max(0, 1 - d2 * d2).squareRoot()).rounded())
            c.rect(28 - iw, y, iw * 2, 1, robe)
        }
    }
    for a in stride(from: -165.0, through: -15.0, by: 18.75) {
        let r = a * .pi / 180
        c.glowLine(28 + cos(r) * 7, 31 + sin(r) * 8, 28 + cos(r) * 13, 31 + sin(r) * 18, core: robeDark, glow: clear,
                   coreR: 0.45, glowR: 0.5)
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: robeDark), step: p.step)
    drawRobeSkirt(c, robe, robeDark)
    c.oy += p.breathe
    drawBody(c, Look(arm: robe))
    // The robe, the collar's points down his front, the Seal.
    c.rect(18, 33, 20, 5, robe); c.rect(37, 33, 1, 5, robeDark)
    c.pattern(17, 31, [
        "GGGG..............GGGG",
        ".GGGG............GGGG.",
        "..GGG............GGG..",
        "...GG............GG...",
        "....G............G....",
    ], ["G": gold])
    c.rect(26, 34, 4, 3, goldDark); c.rect(27, 34, 2, 3, gold); c.px(26, 35, gold); c.px(29, 35, gold)
    // The skullcap.
    c.pattern(18, 22, [
        "......GGGGGGGG......",
        "...GGGGGLLGGGGGGG...",
        ".GGGGGGGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGGGGGG",
        "gggggggggggggggggggg",
    ], ["G": gold, "L": goldLight, "g": goldDark])
    // The gauntlet.
    let r = -p.gunY, lit = p.fire.map { frac($0.t / p.firePeriod) < 0.18 } ?? false
    c.rect(38, 31 - r, 4, 4, gold); c.rect(38, 34 - r, 4, 1, goldDark); c.rect(41, 31 - r, 1, 3, goldDark)
    c.px(39, 32 - r, goldLight)
    if lit { c.px(42, 32 - r, goldLight); c.px(43, 32 - r, C(0xFFFFFF, 0.6)) }
}

// MARK: - The Celestial Toyfaker

/// The Celestial Toyfaker: a harlequin in red, yellow and blue diamonds with a white ruff, odd-coloured tights and a
/// three-pointed jester's cap with gold bells; a red clown nose and a white diamond painted over one eye. He flicks
/// glowing playing cards. Signature: he deals a hand, the cards spinning out one by one to land face up in a row.
private func drawToyfaker(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD8303A), yellow = C(0xF0C830), blue = C(0x2E5AC8), purple = C(0x6A2E9A), bell = C(0xF6D24A)
    // Harlequin tights, one pair red, one blue.
    drawLegs(c, Look(leg: red), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where i % 2 == 1 {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 2, lifted ? 7 : 8, blue)
        }
    }
    c.oy += p.breathe
    let dealing = p.signature.map { $0 > 0.08 && $0 < 0.85 } ?? false
    drawBody(c, Look(arm: yellow), armRight: p.cheering ? 6 : 0)
    // The diamonds.
    for y in 33...37 {
        for x in 18...37 {
            let u = (x - 18 + (y - 33) + 40) / 3, v = (x - 18 - (y - 33) + 40) / 3
            let col = (u + v) % 2 == 0 ? red : (u % 2 == 0 ? yellow : blue)
            c.px(x, y, col)
        }
    }
    // The ruff.
    c.rect(18, 32, 20, 1, white)
    for x in stride(from: 18, to: 38, by: 2) { c.px(x, 33, white); c.px(x + 1, 33, C(0xD8D8E0)) }
    // Face paint: the red nose, a white diamond over the left eye.
    c.rect(27, 30, 2, 2, C(0xE8222A)); c.px(27, 30, C(0xFF8A8A))
    c.px(22, 26, white); c.rect(21, 27, 3, 1, white); c.px(22, 28, white)
    // The jester's cap.
    let jig = p.walking && p.step == 0 ? 1 : 0
    c.pattern(14, 15 + jig, [
        "...........o...............",
        "..........RRR..............",
        "..o......RRRR.........o....",
        "...B.....RRRRR.......Y.....",
        "...BB....RRRRR......YY.....",
        "....BBB..RRRRR....YYY......",
        "....BBBBBRRRRRRYYYYYY......",
        ".....BBBBRRRRRRYYYYY.......",
        "......BBBRRRRRRYYYY........",
        "....PPPPPPPPPPPPPPPPPPPP...",
        "....PPPPPPPPPPPPPPPPPPPP...",
    ], ["R": red, "B": blue, "Y": yellow, "P": purple, "o": bell])
    for x in stride(from: 19, to: 38, by: 4) { c.px(x, 24 + jig, bell) }

    // The hand: dealing, or a card held up ready to flick.
    if let s = p.signature, dealing {
        c.rect(38, 31, 3, 3, yellow)
        let k = (s - 0.08) / 0.77
        for i in 0..<4 {
            let start = Double(i) * 0.2, f = (k - start) / 0.2
            let land = (x: 45 + i * 5, y: 41)
            if f >= 1 {
                c.rect(land.x, land.y, 3, 2, white); c.px(land.x + 1, land.y, i % 2 == 0 ? red : ink)
            } else if f > 0 {
                let x = 41 + Double(land.x - 41) * f, y = 31 + Double(land.y - 31) * f - sin(f * .pi) * 6
                if Int(p.t * 20) % 2 == 0 { c.rect(Int(x), Int(y), 2, 2, white) } else { c.rect(Int(x), Int(y), 1, 3, white) }
                c.px(Int(x), Int(y), red)
            }
        }
        return
    }
    if let s = p.signature {   // the dealt hand, still on the ground
        let fade = s >= 0.85 ? 1 - (s - 0.85) / 0.15 : 1
        for i in 0..<4 { c.rect(45 + i * 5, 41, 3, 2, white.alpha(fade)); c.px(46 + i * 5, 41, (i % 2 == 0 ? red : ink).alpha(fade)) }
    }
    if p.cheering { return }
    c.oy += p.gunY
    c.rect(41, 30, 2, 3, white); c.px(41, 30, red); c.px(42, 32, red)
    c.glowLine(42, 31.5, 42, 31.5, core: C(0xFFE8F8, 0.5), glow: C(0xFF3AC8, 0.45), coreR: 0.5, glowR: 2.4)
}

// MARK: - Sootekh

/// Sootekh, the last of the old gods: a jackal's head, black with gold-lined ears and a burning red eye, over a striped
/// gold-and-lapis headdress whose lappets hang down his front; a broad jewelled collar and a white linen kilt below.
/// From his hand pours a sandy stream of death dust.
private func drawSootekh(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1C1C22), blackLight = C(0x34343E), gold = C(0xE8C04A), goldDark = C(0xA8842A), lapis = C(0x2A4AA8)
    let linen = C(0xEEE8D8), linenShade = C(0xC8C0AC), carnelian = C(0xC8482A)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: black), armRight: p.armRaise)
    c.rect(38, 33 - p.armRaise, 3, 1, gold)                              // the armlet
    // The headdress, striped, behind the jackal's head.
    for y in 13...27 {
        let w = min(14, 8 + (y - 13))
        c.rect(30 - w - 2, y, w + 4, 1, y % 2 == 0 ? gold : lapis)
    }
    // The jackal's head.
    c.pattern(18, 7, [
        "...KK....KK.............",
        "..KKK...KKK.............",
        "..KgK...KgK.............",
        "..KgK...KgK.............",
        "..KgKK..KgKK............",
        "..KKKKKKKKKK............",
        ".KKKKKKKKKKKK...........",
        ".KKKKKKKKKKKKKK.........",
        "KKKKKKKKKKKRRKKKKK......",
        "KKKKKKKKKKyyyKKKKKKKKK..",
        "KKKKKKKKKKKKKKKKKKKKKKKN",
        "KKKKKKKKKKKKKkKKKKKKKKK.",
        "KKKKKKKKKKKKKkkkkkkkkk..",
        "KKKKKKKKKKKKKKKKKKKKK...",
        "KKKKKKKKKKKKKKKK........",
        ".KKKKKKKKKKKKK..........",
        "..KKKKKKKKKK............",
        "..KKKKKKKKKK............",
        "..KKKKKKKKKK............",
    ], ["K": black, "k": blackLight, "g": gold, "y": gold, "R": C(0xFF3A2A), "N": blackLight])
    if Int(p.t * 2) % 3 == 0 { c.px(29, 15, C(0xFFB09A)) }
    // The lappets, down his front, and the collar.
    for y in 24...33 {
        let col = y % 2 == 0 ? gold : lapis
        c.rect(17, y, 3, 1, col); c.rect(36, y, 3, 1, col)
    }
    c.rect(18, 32, 20, 1, gold); c.rect(18, 33, 20, 1, lapis); c.rect(18, 34, 20, 1, carnelian)
    for x in stride(from: 19, to: 37, by: 2) { c.px(x, 33, gold) }
    c.rect(18, 35, 20, 1, goldDark)
    c.rect(18, 36, 20, 2, linen); c.rect(18, 37, 20, 1, linenShade)
    for x in [21, 25, 29, 33] { c.px(x, 36, linenShade) }
}

// MARK: - The Grate Intelligence

/// The Grate Intelligence, as a snowman with a grudge: Clawd packed in snow, coal eyes glinting icy blue, a carrot nose
/// and a grin of jagged ice teeth, a black Victorian top hat, twig arms, and a snow globe in one twig hand that shoots
/// the snow. Flakes drift down round him.
private func drawGrateIntelligence(_ c: PixelCanvas, _ p: Pose) {
    let snow = C(0xF4F8FC), snowShade = C(0xC8D8EA), twig = C(0x6A4A2A), hat = C(0x1C1C22)
    let ice = C(0x7FD8FF)
    // Flakes.
    for i in 0..<4 {
        let f = frac(p.lt * 0.25 + Double(i) * 0.27)
        let x = 12 + i * 12 + Int(sin(f * 6 + Double(i)) * 2), y = 8 + Int(f * 34)
        c.px(x, y, white.alpha(0.8 * (1 - f)))
    }
    drawLegs(c, Look(leg: snowShade), step: p.step)
    c.oy += p.breathe
    // The snow body, lumpy at the corners.
    c.rect(19, 26, 18, 12, snow); c.rect(18, 27, 20, 10, snow)
    c.rect(36, 27, 2, 10, snowShade); c.rect(19, 37, 18, 1, snowShade)
    c.px(20, 28, snowShade); c.px(25, 35, snowShade); c.px(31, 27, snowShade); c.px(34, 34, snowShade)
    // Coal eyes, glinting.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    let glint = 0.7 + 0.3 * sin(p.t * 5)
    c.px(23, 29, ice.alpha(glint)); c.px(33, 29, ice.alpha(glint))
    // The carrot and the grin.
    c.rect(27, 31, 3, 1, C(0xE8782A)); c.px(30, 31, C(0xC85A1A))
    c.rect(22, 33, 12, 2, C(0x2A1E28))
    for x in 22...33 { c.px(x, x % 2 == 0 ? 33 : 34, white) }
    // The top hat.
    c.rect(17, 25, 22, 1, hat); c.rect(17, 25, 22, 1, hat)
    c.rect(21, 16, 14, 9, hat); c.rect(21, 22, 14, 1, C(0x5A1A24))
    c.rect(22, 16, 2, 6, C(0x34343E))
    // The far twig arm.
    c.glowLine(18, 31, 12, 26, core: twig, glow: clear, coreR: 0.5, glowR: 0.55)
    c.px(13, 25, twig); c.px(11, 27, twig)
    // The near twig arm and the snow globe, the shot leaving from the globe.
    if p.cheering {
        c.glowLine(37, 31, 41, 22, core: twig, glow: clear, coreR: 0.5, glowR: 0.55)
        c.px(42, 22, twig); c.px(40, 21, twig)
        return
    }
    c.oy += p.gunY
    c.glowLine(37, 32, 41, 31, core: twig, glow: clear, coreR: 0.5, glowR: 0.55)
    c.rect(42, 32, 4, 1, C(0x5A3A22))
    c.rect(42, 28, 4, 4, C(0xBFE8FF, 0.8)); c.rect(43, 27, 2, 1, C(0xBFE8FF, 0.8))
    c.px(43, 29, white); c.px(44, 30, snow)
    if p.fire != nil || p.zap != nil {
        c.glowLine(44, 29.5, 44, 29.5, core: clear, glow: ice.alpha(0.6), coreR: 0.1, glowR: 3)
    }
}

// MARK: - The Valeyarn

/// The Valeyarn, the Doctor's darkest side: black robes with a tall stiff collar standing up square behind his head,
/// flaring to points at the top, trimmed silver and lined in plum, a black skullcap over a sharp widow's peak, and a cold stare.
/// He has no powers of his own to throw: he carries a black Gallifreyan pistol that fires violet bolts.
private func drawValeyarn(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x1C1C22), robeLight = C(0x34343E), silver = C(0xA8ACB8), silverDark = C(0x6A6E7A)
    let lining = C(0x3A2242), liningLight = C(0x4E3058)
    c.oy += p.breathe
    // The collar, standing up stiff behind his head, wider at the top, its corners pointed.
    c.pattern(13, 13, [
        "S............................S",
        "SS..........................SS",
        "SBSSSSSSSSSSSSSSSSSSSSSSSSSSBS",
        "SBBBBBBBBBBBBBBBBBBBBBBBBBBBBS",
        ".SBBbBBBBbBBBBBBBBBBbBBBBbBBS.",
        ".SBBbBBBBbBBBBBBBBBBbBBBBbBBS.",
        ".SBBbBBBBbBBBBBBBBBBbBBBBbBBS.",
        "..SBbBBBBbBBBBBBBBBBbBBBBbBS..",
        "..SBbBBBBbBBBBBBBBBBbBBBBbBS..",
        "..SBbBBBBbBBBBBBBBBBbBBBBbBS..",
        "...SbBBBBbBBBBBBBBBBbBBBBbS...",
        "...SbBBBBbBBBBBBBBBBbBBBBbS...",
        "...SBBBBBbBBBBBBBBBBbBBBBBS...",
        "....SBBBBBBBBBBBBBBBBBBBBS....",
        "....SBBBBBBBBBBBBBBBBBBBBS....",
        "....SSBBBBBBBBBBBBBBBBBBSS....",
        ".....SBBBBBBBBBBBBBBBBBBS.....",
    ], ["S": silverDark, "B": lining, "b": liningLight])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: robe), step: p.step)
    drawRobeSkirt(c, robe, robeLight)
    c.oy += p.breathe
    drawBody(c, Look(arm: robe, eye: nil))
    c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)              // narrowed eyes
    c.rect(21, 28, 3, 1, C(0x8A3E26)); c.rect(32, 28, 3, 1, C(0x8A3E26))   // brows, down at the middle
    c.px(24, 29, C(0x8A3E26)); c.px(31, 29, C(0x8A3E26))
    // The robe, silver-edged, the collar's points down his front.
    c.rect(18, 33, 20, 5, robe)
    c.rect(26, 33, 1, 5, silver); c.rect(29, 33, 1, 5, silver)
    c.pattern(18, 31, [
        "SSSS............SSSS",
        ".SSS............SSS.",
        "..SS............SS..",
    ], ["S": silverDark])
    // The skullcap and the widow's peak.
    c.pattern(18, 21, [
        ".....CCCCCCCCCC.....",
        "...CCCCCCcCCCCCCC...",
        "..CCCCCCCCCCCCCCCC..",
        ".CCCCCCCCCCCCCCCCCC.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHH",
        "HH.......HH.......HH",
        "H.........H........H",
    ], ["C": robe, "c": robeLight, "H": C(0x2A2420)])
    c.rect(18, 25, 20, 1, silverDark)
    // The pistol in his right hand.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, robe)
    drawPistol(c, x: 40, y: 31, body: C(0x16161C), trim: silver)
}

// MARK: - The Maestro

/// The Maestro: a flamboyant conductor with a big cloud of dark curls, a black tailcoat with glittering gold lapels and
/// long tails, a magenta bow tie, and a white baton. The music pours from the baton's tip, notes and all. Signature:
/// conducts, both arms up, the baton beating out four to the bar, notes rising.
private func drawMaestro(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1C1C24), coatLight = C(0x34343E), hair = C(0x2A1A16), hairLight = C(0x4A322A), gold = C(0xF0C84A)
    let shirt = C(0xF4F0EA), tie = C(0xD83A9A)
    // The tails, behind.
    if !seatedPose {
        c.rect(14, 33, 5, 8, coat); c.rect(14, 33, 1, 8, coatLight)
    }
    drawLegs(c, Look(leg: coat), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x0E0E12), sole: C(0x5A5A66))
    c.oy += p.breathe
    drawBody(c, Look(arm: coat), armRight: 0)
    // Shirt, bow tie, the glittering lapels.
    c.rect(18, 33, 20, 5, coat); c.rect(37, 33, 1, 5, coatLight)
    c.rect(25, 33, 6, 5, shirt)
    c.rect(26, 33, 4, 2, tie); c.px(27, 33, C(0xA82A78)); c.px(28, 34, C(0xA82A78))
    for y in 33...37 {
        for x in [22, 23, 24, 31, 32, 33] where (x < 28 ? x - 22 : 33 - x) <= y - 33 + 1 {
            let sparkle = noise(x * 13 + y * 7 + Int(p.t * 6)) > 0.8
            c.px(x, y, sparkle ? white : gold)
        }
    }
    // The curls.
    c.pattern(14, 15, [
        ".......HhHHHhHHH.........",
        ".....HHHHHHHHHHHhHH......",
        "...HHhHHHHhHHHHHHHHHH....",
        "..HHHHHHHHHHHHHhHHHHHH...",
        ".HHHhHHHHHHHHHHHHHHHhHH..",
        ".HHHHHHHhHHHHHHhHHHHHHHH.",
        "HHhHHHHHHHHHHHHHHHHHHhHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHhHHHHHHHHHHHHHHhHHHHH",
        "HhHHHHHHHHHHHHHHHHHHHHHhH",
        "HHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHhH..............HHhHHH",
        "HHHHH...............HHHHH",
        ".HhHH...............HHHH.",
        "HHHHH...............HhHH.",
        ".HHH................HHHH.",
        "..HH.................HH..",
    ], ["H": hair, "h": hairLight])
    c.rect(26, 30, 3, 1, C(0xC82A5A))                                 // lipstick
    // The arm and the baton.
    if let s = p.signature {
        let k = habitArc(s, hold: 0.8)
        let beat = sin(s * 2 * .pi * 6) * k
        c.rect(13, 28, 3, 4, coat); c.rect(13, 27, 3, 1, clawdOrange)   // the other hand up
        let hy = 30 - Int((3 * k).rounded())
        c.rect(38, hy, 3, 3, coat); c.rect(38, hy + 2, 3, 1, shirt)
        let a = (-50 + 30 * beat) * .pi / 180
        c.glowLine(41, Double(hy) + 0.5, 41 + cos(a) * 7, Double(hy) + 0.5 + sin(a) * 7, core: white, glow: clear,
                   coreR: 0.45, glowR: 0.5)
        for i in 0..<3 {
            let f = frac(s * 2 + Double(i) / 3)
            drawNote(c, 44 + i * 4 + Int(sin(f * 5) * 1.5), 24 - Int(f * 14), [gold, tie, C(0x6AC8FF)][i].alpha(1 - f))
        }
        return
    }
    if p.cheering {
        c.rect(38, 24, 3, 9, coat); c.rect(38, 23, 3, 1, clawdOrange)
        c.rect(39, 18, 1, 5, white)
        return
    }
    let using = p.zap != nil || p.ready || (!p.resting && !p.walking)
    if using {
        let r = p.armRaise
        c.rect(38, 31 - r, 3, 3, coat); c.rect(38, 33 - r, 3, 1, shirt)
        c.glowLine(41, 32.5 - Double(r), 46.5, 28.5 - Double(r), core: white, glow: clear, coreR: 0.45, glowR: 0.5)
        if p.zap == true {
            let f = frac(p.t * 0.8)
            drawNote(c, 48 + Int(f * 10), 22 - r - Int(sin(f * .pi) * 4), (Int(p.t * 0.8) % 2 == 0 ? gold : tie).alpha(1 - f))
        }
    } else {
        c.rect(38, 33, 3, 3, coat); c.rect(38, 35, 3, 1, shirt)
        c.glowLine(41, 35.5, 44, 38.5, core: white, glow: clear, coreR: 0.45, glowR: 0.5)
    }
}

// MARK: - Lady Cassandro

/// Lady Cassandro, the last human, so many times nipped and tucked that she's a flat sheet of skin stretched on a brass
/// frame: Clawd's own orange, pinned taut by little clamps, with Clawd's eyes, fine arched brows, long lashes, a beauty
/// spot and red lips. The frame rides a pole on a little wheeled stand that glides along. She chatters while she
/// waits, and the skin ripples when she's hit.
private func drawCassandro(_ c: PixelCanvas, _ p: Pose) {
    let brass = C(0xC8A85A), brassDark = C(0x8A6E32), brassLight = C(0xF0D88A), steel = C(0x8A8E98)
    let lips = C(0xC8202E), brow = C(0x5A2E1E)
    // The stand.
    c.rect(27, 38, 2, 4, steel); c.rect(22, 42, 12, 1, brassDark)
    for x in [22, 32] { c.rect(x, 43, 2, 1, C(0x2A2A30)) }
    c.rect(25, 41, 6, 1, brass)
    // The frame.
    c.rect(14, 15, 28, 24, brass)
    c.rect(16, 17, 24, 20, C(0x2A2420))                            // the dark behind the skin
    c.rect(14, 15, 28, 1, brassLight); c.rect(41, 15, 1, 24, brassDark); c.rect(14, 38, 28, 1, brassDark)
    for (x, y) in [(14, 15), (40, 15), (14, 37), (40, 37)] { c.rect(x, y, 2, 2, brassDark) }   // the corner bolts
    // The skin, stretched, the clamps pinning it to the frame.
    let ripple = p.hit ? Int((noise(Int(p.t * 30)) - 0.5) * 3) : 0
    c.ox += ripple
    c.oy += p.breathe
    c.rect(18, 18, 20, 18, clawdOrange); c.rect(17, 19, 22, 16, clawdOrange)
    c.rect(37, 19, 2, 16, clawdShade); c.rect(18, 35, 20, 1, clawdShade)
    for x in [21, 28, 35] { c.px(x, 17, clawdOrange); c.px(x, 16, steel); c.px(x, 36, clawdShade); c.px(x, 37, steel) }
    for y in [21, 27, 33] { c.px(16, y, clawdOrange); c.px(15, y, steel); c.px(39, y, clawdShade); c.px(40, y, steel) }
    // The face.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(21, 28, ink); c.px(34, 28, ink)                          // lashes
    let up = p.hit || p.urgent ? 1 : 0
    c.rect(21, 26 - up, 3, 1, brow); c.px(24, 27 - up, brow)
    c.rect(32, 26 - up, 3, 1, brow); c.px(31, 27 - up, brow)
    c.px(34, 32, C(0x4A2418))                                     // beauty spot
    let talking = p.ready && Int(p.t * 6) % 2 == 0
    if p.hit || talking {
        c.rect(26, 33, 4, 1, lips); c.rect(26, 35, 4, 1, lips); c.px(25, 34, lips); c.px(30, 34, lips)
        c.rect(26, 34, 4, 1, C(0x5A1018))
    } else if p.cheering {
        c.rect(25, 33, 6, 1, lips); c.rect(26, 34, 4, 1, lips); c.px(24, 32, lips); c.px(31, 32, lips)
    } else {
        c.rect(25, 33, 6, 1, lips); c.rect(26, 34, 4, 1, C(0xA81824)); c.px(27, 33, C(0xE85A6A))
    }
    c.rect(19, 31, 2, 1, C(0xE88A7A, 0.6)); c.rect(35, 31, 2, 1, C(0xE88A7A, 0.6))   // rouge
    c.ox -= ripple
}

// MARK: - Clockwork Droid

/// A Clockwork Droid from an eighteenth-century spaceship: a powdered white wig with rolled curls and a black ribbon
/// at the queue, a gilt carnival mask over the eyes, a crack in the cheek showing the cogs turning inside, a teal frock
/// coat with gold trim and a lace jabot, white stockings and buckled shoes. A blade slides out of its wrist to fight.
/// Signature: it ticks, jerking with each tick, the cogs in its cheek jumping on.
private func drawClockworkDroid(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x2A6670), coatDark = C(0x1C4A52), gold = C(0xE0B84A), goldDark = C(0x9A7A2A), wig = C(0xF2F0EC)
    let wigShade = C(0xC8C8CC), lace = C(0xF6F4EE), mask = C(0xF4EEE0), cog = C(0xE8C050), stocking = C(0xEEEAE0)
    let tick = p.signature.map { Int($0 * 12) } ?? Int(p.t * 2)
    let jerk = p.signature != nil && tick % 2 == 1 ? 1 : 0
    if !seatedPose { c.rect(16, 36, 24, 3, coatDark) }              // the coat's skirts, behind
    drawLegs(c, Look(leg: stocking), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x1A1A1E), sole: C(0x2A2A30))
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, p.step >= 0 && i % 2 == p.step ? 41 : 42, C(0xD8DCE4)) } }
    c.oy += p.breathe - jerk
    c.ox += jerk
    drawBody(c, Look(arm: coat, eye: nil), armRight: 0)
    // The coat, the jabot.
    c.rect(18, 33, 20, 5, coat); c.rect(37, 33, 1, 5, coatDark)
    c.rect(18, 33, 1, 5, gold); c.rect(36, 33, 1, 5, gold); c.rect(18, 37, 20, 1, goldDark)
    for y in [34, 36] { c.px(21, y, gold); c.px(34, y, gold) }
    c.pattern(25, 32, ["LLLLLL", ".LLLL.", "LLLLLL", ".LLLL.", "..LL.."], ["L": lace])
    // The crack in the cheek and the cogs behind it.
    c.pattern(33, 30, [".KK..", "KKKK.", "KKKKK", ".KKK."], ["K": C(0x1A1418)])
    drawCog(c, 34, 31, phase: tick, cog, goldDark)
    // The mask.
    c.pattern(18, 27, [
        "MM................MM",
        "MMMMGGGGMMMMGGGGMMMM",
        ".MMG....GMMG....GMM.",
        ".MMG....GMMG....GMM.",
        "..MMGGGGMMMMGGGGMM..",
    ], ["M": mask, "G": gold])
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    // The wig.
    c.pattern(16, 17, [
        "......WWWWWWWWWW......",
        "....WWWWWWWWWWWWWW....",
        "...WWWsWWWWWWWWsWWW...",
        "..WWWWWWWWWWWWWWWWWW..",
        "..WWWWWWWWWWWWWWWWWW..",
        ".WWWWWWWWWWWWWWWWWWWW.",
        ".WWsWWWWWWWWWWWWWWsWW.",
        "WWWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWWW",
        "WWsW..............WsWW",
        "WWWW..............WWWW",
        "WsWW...............WsW",
        "WWWW...............WWW",
    ], ["W": wig, "s": wigShade])
    c.rect(13, 27, 3, 3, C(0x1A1A1E)); c.px(12, 26, C(0x1A1A1E)); c.px(12, 30, C(0x1A1A1E))   // the ribbon at the queue
    if p.signature != nil && tick % 2 == 1 { c.px(38, 24, white); c.px(39, 23, white.alpha(0.6)) }   // tick
    // The wrist blade.
    if let a = p.melee {
        let hx = Sprite.hand.x, hy = Sprite.hand.y
        for (i, t) in p.trail.enumerated() {
            let r = t * .pi / 180
            c.glowLine(hx + cos(r) * 2, hy + sin(r) * 2, hx + cos(r) * 13, hy + sin(r) * 13,
                       core: white.alpha(0.3 / Double(i + 1)), glow: C(0xBFD8FF).alpha(0.2 / Double(i + 1)), coreR: 0.5, glowR: 1.6)
        }
        let r = a * .pi / 180
        c.glowLine(hx, hy, hx + cos(r) * 13, hy + sin(r) * 13, core: C(0xDDE2EA), glow: clear, coreR: 0.5, glowR: 0.55)
        c.px(Int(hx + cos(r) * 7), Int(hy + sin(r) * 7), white)
    }
    c.rect(38, 33, 3, 3, coat); c.rect(40, 33, 1, 3, lace)
}

// MARK: - The Candyman

/// The Candyman, a confectioner's monster built out of liquorice allsorts: Clawd in sugary layers of pink, black,
/// orange, white and yellow, liquorice-roll arms and legs, and a pink coconut wheel with a liquorice middle for a hat,
/// scattered with blue sprinkles.
private func drawCandyman(_ c: PixelCanvas, _ p: Pose) {
    let pink = C(0xF28AB8), pinkDark = C(0xC8648E), liquorice = C(0x1E161A), liqLight = C(0x3E2E34)
    let yellow = C(0xF6D84A), cream = C(0xF6F0E2), sprinkle = C(0x4A8AE8)
    drawLegs(c, Look(leg: liquorice), step: p.step)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, 37, 1, p.step >= 0 && i % 2 == p.step ? 5 : 6, liqLight) } }
    c.oy += p.breathe
    drawBody(c, Look(arm: liquorice, eye: nil), armRight: p.cheering ? 6 : 0)
    // The layers.
    let layers: [(Int, Int, Px)] = [(26, 2, pink), (28, 1, liquorice), (29, 3, clawdOrange), (32, 1, liquorice),
                                     (33, 2, cream), (35, 1, liquorice), (36, 2, yellow)]
    for (y, h, col) in layers { c.rect(18, y, 20, h, col) }
    c.rect(37, 26, 1, 12, C(0x000000, 0.18))
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(23, 29, white); c.px(33, 29, white)
    // Liquorice-roll arms, their coiled ends.
    let r = p.cheering ? 6 : 0
    c.px(39, 34 - r, cream); c.px(16, 34, cream)
    // The coconut wheel.
    c.pattern(19, 19, [
        "....PPPPPPPP....",
        "..PPPPPPPPPPPP..",
        ".PPPPPPLLPPPPPP.",
        "PPPPPPLLLLPPPPPP",
        "PPPPPPLLLLPPPPPP",
        ".PPPPPPLLPPPPPP.",
        "..pppppppppppp..",
    ], ["P": pink, "p": pinkDark, "L": liquorice])
    for (x, y) in [(21, 21), (24, 20), (32, 21), (30, 23), (22, 23), (34, 22), (27, 19), (26, 24)] { c.px(x, y, sprinkle) }
    if p.hit {
        for i in 0..<3 {
            let f = frac(p.t * 2 + Double(i) / 3)
            c.px(30 + i * 4 + Int(f * 6), 28 - Int(f * 8) + Int(f * f * 14), [pink, yellow, cream][i])
        }
    }
}
