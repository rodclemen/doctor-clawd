import Foundation

// Heroes: the TVA, the Red Room, the Savage Land, Stark's workshop and Ta Lo. Clawd in costume, except the alligator,
// the sabretooth, the faceless hundun and the robot arm, who keep only a hint of him.

let heroes10: [MarvelHero: Persona] = [
    .mobius: Persona(name: "Moebius", weapon: .saber, headTop: 21, signature: 3.2,
                  draw: drawMobius),
    .sylvie: Persona(name: "Sylvi", weapon: .saber, headTop: 15, signature: 3.0,
                  draw: drawSylvie),
    .kidLoki: Persona(name: "Kid Lokee", weapon: .lightning, magic: Magic(core: C(0xE0FFE8), glow: C(0x3AD06A), jagged: false),
                  pivot: (37.5, 36.5), headTop: 19, signature: 3.0,
                  draw: drawKidLoki),
    .alligatorLoki: Persona(name: "Alligator Lokee", weapon: .saber, canSit: false, bulk: 4, headTop: 22, signature: 2.8,
                  draw: drawAlligatorLoki),
    .hunterB15: Persona(name: "Hunter C-16", weapon: .saber, headTop: 22, signature: 2.6,
                  draw: drawHunterB15),
    .redGuardian: Persona(name: "Red Guardsman", weapon: .saber, bulk: 3, headTop: 18, signature: 3.0, callout: "I am Red Guardsman!",
                  draw: drawRedGuardian),
    .kaZar: Persona(name: "Ka-Zarr", weapon: .saber, headTop: 19, signature: 3.4,
                  draw: drawKaZar),
    .rescue: Persona(name: "Rescuer", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xE8F0FF), glow: C(0x6A9AFF)), armoured: true,
                  muzzle: (43, 34), handGun: false, headTop: 20, signature: 3.0,
                  draw: drawRescue),
    .zabu: Persona(name: "Zabo", weapon: .saber, canSit: false, bulk: 9, headTop: 19, signature: 2.6,
                  draw: drawZabu),
    .morris: Persona(name: "Morrie", motion: .hover, canSit: false, headTop: 19, signature: 2.8,
                  draw: drawMorris),
    .dumE: Persona(name: "Dumb-E", canSit: false, headTop: 12, signature: 3.0,
                  draw: drawDumE),
]

private let tvaOrange = C(0xF08A2A), tvaGlow = C(0xFFE0A0)

// MARK: - Mobius

/// Mobius M. Mobius: the TVA analyst: slicked-back silver hair, a grey moustache, a tan-brown suit over a cream
/// shirt and brown tie, and a TVA time-stick for a weapon. Signature: out comes his jet ski magazine; he gazes at the
/// cover, eyes down, and a little heart floats up.
private func drawMobius(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x9A7A54), suitDark = C(0x6E5638), shirt = C(0xE4DCC8), tie = C(0x6A3A22)
    let hair = C(0xB8B8BE), hairDark = C(0x82828C)
    let read = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: C(0x806446)), step: p.step)
    drawBoots(c, C(0x3A2A1E), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(arm: suit, eye: nil))
    c.pattern(17, 21, [
        "......HHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHhHHHHHHHhHHHH..",
        ".HHHHHHHHHhHHHHHHHHHh.",
        ".HHhHHHHHHHHHHHHHHHHh.",
        ".HH................hH.",
        ".Hh.................h.",
    ], ["H": hair, "h": hairDark])
    // Brows, eyes (down at the magazine while he reads), the moustache.
    c.rect(21, 27, 3, 1, hairDark); c.rect(32, 27, 3, 1, hairDark)
    if read > 0.3 {
        c.rect(23, 30, 2, 2, ink); c.rect(33, 30, 2, 2, ink)
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.pattern(23, 32, [".MMMMMMMM.", "MMMMMMMMMM"], ["M": hair, "m": hairDark])
    // Suit, shirt and tie.
    c.rect(18, 34, 20, 4, suit)
    c.pattern(24, 34, ["dSSTTSSd", ".dSTTSd.", "..dTTd.."], ["S": shirt, "T": tie, "d": suitDark])
    c.rect(18, 37, 20, 1, suitDark)
    c.rect(15, 33, 3, 3, suit); c.rect(15, 33, 1, 3, clawdOrange)
    if read > 0.05 {
        drawJetSkiMagazine(c, lift: Int(((1 - read) * 9).rounded()))
        if let s = p.signature, s > 0.4, s < 0.92 {
            let f: Double = (s - 0.4) / 0.52
            let a: Double = f < 0.7 ? 1 : (1 - f) / 0.3
            c.pattern(28, 19 - Int(f * 8), [".HH.HH.", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."], ["H": C(0xF04A7A, a)])
        }
    } else if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawTimeStick(c, angle: ta, alpha: 0.35 / Double(i + 1), lit: 0) }
        drawTimeStick(c, angle: a, lit: 0.5)
        c.rect(38, 33, 3, 3, suit); c.rect(40, 33, 1, 3, clawdOrange)
    } else {
        drawTimeStick(c, angle: seatedPose ? 15 : 95, lit: 0, at: (41.5, 31.5))
        c.rect(38, 33, 3, 3, suit); c.rect(40, 33, 1, 3, clawdOrange)
    }
}

/// A glossy jet ski magazine held up in his right hand, `lift` pixels below where it's read.
private func drawJetSkiMagazine(_ c: PixelCanvas, lift: Int) {
    let y = 22 + lift
    c.rect(37, y + 9, 3, 3, C(0x9A7A54))
    c.pattern(35, y, [
        "RRRRRRRRRRRR",
        "RYYRYRYYYRYR",
        "RRRRRRRRRRRR",
        "bbbbbbbbbbbp",
        "bbbbbbbKbbbp",
        "bbbbbJJJJbbp",
        "bwwJJJJJJJbp",
        "wwWWWWWWWwwp",
        "WWwWWWWWwWWp",
        "WWWWWWWWWWWp",
        "pppppppppppp",
    ], ["R": C(0xC8202A), "Y": C(0xFFD23A), "b": C(0x8ACCF0), "J": C(0xE8C02A), "K": C(0x2A2A30),
        "w": C(0xC8E4F4), "W": C(0x2A7AC8), "p": C(0xC8BCA0)])
    c.rect(40, y + 9, 3, 2, clawdOrange)
}

/// A TVA time-stick: a black baton with orange bands, held at the hand and pointing along `angle`; `lit` (0…1) makes
/// its tip glow.
private func drawTimeStick(_ c: PixelCanvas, angle: Double, alpha: Double = 1, lit: Double, at: (x: Double, y: Double) = Sprite.hand) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.rect(18, 20, 15, 2, C(0x2A2A30))
        s.rect(18, 20, 4, 2, C(0x4A4A54))
        s.rect(23, 20, 1, 2, tvaOrange); s.rect(27, 20, 1, 2, tvaOrange)
        s.rect(31, 20, 2, 2, lit > 0 ? tvaGlow : tvaOrange)
    }
    guard lit > 0, alpha > 0.9 else { return }
    let r: Double = angle * .pi / 180
    let tx: Double = Sprite.hand.x + cos(r) * 11.5, ty: Double = Sprite.hand.y + sin(r) * 11.5
    c.glowLine(tx, ty, tx, ty, core: tvaGlow.alpha(lit), glow: tvaOrange.alpha(lit), coreR: 0.6, glowR: 1.4 + lit)
}

// MARK: - Sylvie

/// Sylvie: the Variant: messy blonde hair, the gold headband with its horns (the left one snapped off short), a
/// green-black cloak over dark leathers, and a short sword. Signature: enchantment. Her hand goes to her temple,
/// her eyes and a gold-green glow flare round her head and sparks spiral in.
private func drawSylvie(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xE8C870), hairShade = C(0xB8944A), gold = C(0xD8A830), goldDark = C(0x9A7420), goldLight = C(0xFFE08A)
    let cloak = C(0x1E3A2A), cloakEdge = C(0x0E1E16), leather = C(0x2A2620), leatherLight = C(0x4A4034)
    let core = C(0xFFF6C8), glow = C(0xF0C838)
    let ench = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if ench > 0.05 {
        c.oy += p.breathe
        let flick: Double = 0.85 + 0.15 * sin(p.t * 25)
        c.ellipse(28, 25, Int(14 * ench), Int(11 * ench), glow.alpha(0.3 * ench * flick))
        c.ellipse(28, 25, Int(10 * ench), Int(8 * ench), core.alpha(0.3 * ench * flick))
        c.oy -= p.breathe
    }
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.8, color: cloak, edge: cloakEdge)
    drawLegs(c, Look(leg: leather), step: p.step)
    drawBoots(c, C(0x4A3424), step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: leather, eye: nil))
    // Horns first (the right one whole, the left one snapped), then the hair and the headband over their roots.
    for (a, b, r) in [((34.5, 23.5), (37.5, 20.0), 1.2), ((37.5, 20.0), (38.5, 16.5), 1.0), ((38.5, 16.5), (37.0, 14.0), 0.7),
                      ((21.5, 23.5), (19.0, 21.0), 1.2)] as [((Double, Double), (Double, Double), Double)] {
        stick(c, a.0, a.1, b.0, b.1, gold, r)
    }
    stick(c, 36.5, 20.5, 37.5, 17.5, goldLight, 0.4)
    c.px(18, 20, goldDark); c.px(19, 19, goldDark)                    // the broken end
    c.pattern(16, 20, [
        "......hHH.HHHHH.HH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHhHHHHHHHHhHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        ".HHHHHHHHHhHHHHHHHHHHHH.",
        ".HHHhHH.HHH...HHhH.HHHH.",
        ".HHH..H..............HHH",
        ".HHh.................hHH",
        "HHH...................HH",
        "HHh..................hHH",
        "HHH..................HHH",
        ".HH..................hH.",
        ".Hh...................H.",
        "..h...................h.",
    ], ["H": hair, "h": hairShade, "G": gold])
    c.rect(18, 24, 20, 1, gold); c.px(27, 24, goldLight); c.px(28, 24, goldLight)
    let eye = ench > 0.35 ? C(0xE8D040) : ink
    c.rect(22, 29, 2, 3, eye); c.rect(32, 29, 2, 3, eye)
    if ench > 0.35 { for x in [23.0, 33.0] { c.glowLine(x, 30.5, x, 30.5, core: core, glow: glow, coreR: 0.7, glowR: 2) } }
    c.rect(26, 33, 4, 1, clawdShade)
    // Leathers: a dark tunic with a lighter belt and a strap.
    c.rect(18, 34, 20, 4, leather)
    c.rect(18, 36, 20, 1, leatherLight); c.rect(27, 36, 2, 1, gold)
    c.rect(18, 37, 20, 1, C(0x16130F))
    c.rect(15, 33, 3, 3, leather); c.rect(15, 33, 1, 3, clawdOrange)
    if ench > 0.05 {
        // Hand to her temple, sparks spiralling in.
        c.rect(36, 27, 3, 3, leather); c.rect(36, 27, 1, 3, clawdOrange); c.rect(38, 30, 2, 4, leather)
        for i in 0..<5 {
            let a: Double = p.t * 4 + Double(i) * 1.26
            let r: Double = 6 + 7 * (1 - ench) + 2 * sin(p.t * 3 + Double(i))
            c.glowLine(28 + cos(a) * (r + 3), 25 + sin(a) * (r * 0.7 + 2), 28 + cos(a + 0.3) * r, 25 + sin(a + 0.3) * r * 0.7,
                       core: core.alpha(ench), glow: glow.alpha(ench * 0.7), coreR: 0.4, glowR: 1.2)
        }
        drawSylvieSword(c, angle: 100, at: (41.5, 29.5))
        return
    }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawSylvieSword(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawSylvieSword(c, angle: a)
    } else {
        drawSylvieSword(c, angle: seatedPose ? 15 : 100, at: (41.5, 29.5))
    }
    c.rect(38, 33, 3, 3, leather); c.rect(40, 33, 1, 3, clawdOrange)
}

/// Sylvie's short sword along `angle` from her hand.
private func drawSylvieSword(_ c: PixelCanvas, angle: Double, alpha: Double = 1, at: (x: Double, y: Double) = Sprite.hand) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.rect(17, 20, 4, 2, C(0x3A2A1E))
        s.rect(21, 18, 2, 6, C(0x6A6A74))
        s.rect(23, 20, 12, 1, C(0xC8CCD4)); s.rect(23, 21, 12, 1, C(0x8A8F9C))
        s.px(35, 20, C(0xA4AAB4))
    }
}

// MARK: - Kid Loki

/// Kid Loki: a smaller Clawd (well short of the others) in green with gold trim, a tiny helmet with big curling
/// horns, black hair peeking out and a mischievous grin; green magic. Signature: he winks, and a translucent green
/// illusion of himself pops up beside him, grins, and pops away again.
private func drawKidLoki(_ c: PixelCanvas, _ p: Pose) {
    var wink = false
    if let s = p.signature {
        wink = s > 0.08 && s < 0.3
        let shown: Double = s < 0.2 ? 0 : (s < 0.3 ? (s - 0.2) / 0.1 : (s < 0.82 ? 1 : max(0, 1 - (s - 0.82) / 0.1)))
        if shown > 0 {
            layer(c, alpha: 0.55 * shown, dx: -16, tint: (C(0x6AF08A), 0.45)) { s in drawKid(s, p, wink: false, armUp: 0) }
        }
        for pop in [0.25, 0.87] where abs(s - pop) < 0.06 {
            let k: Double = 1 - abs(s - pop) / 0.06
            c.oy += p.breathe
            for i in 0..<6 {
                let a: Double = Double(i) * .pi / 3 + 0.4
                let r: Double = 4 + 5 * (1 - k)
                c.glowLine(13 + cos(a) * r, 33 + sin(a) * r, 13 + cos(a) * (r + 2), 33 + sin(a) * (r + 2),
                           core: C(0xE0FFE8, k), glow: C(0x3AD06A, k), coreR: 0.4, glowR: 1.3)
            }
            c.oy -= p.breathe
        }
    }
    drawKid(c, p, wink: wink, armUp: p.armRaise)
}

/// Kid Loki himself: a 14×9 Clawd on short legs.
private func drawKid(_ c: PixelCanvas, _ p: Pose, wink: Bool, armUp: Int) {
    let green = C(0x1E7A3A), greenDark = C(0x145A2A), gold = C(0xE8B530), goldDark = C(0xA8801E), goldLight = C(0xFFE08A)
    let leg = C(0x1A2A1E)
    if seatedPose {
        for lx in [22, 25, 30, 33] { c.rect(lx - 1, 37, 3, 2, leg) }
    } else {
        for (i, lx) in [22, 25, 30, 33].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 39, 2, lifted ? 4 : 5, leg)
            c.rect(lx, lifted ? 41 : 42, 2, 1, gold)
        }
    }
    c.oy += p.breathe
    // A little green cape behind.
    let flap = sin(p.t * p.capeSpeed * 1.5) > 0 ? 1 : 0
    c.pattern(16 - flap, 33, ["....CC", "...CCC", "..CCCC", ".CCCCc", "CCCCcc", ".cccc."], ["C": green, "c": greenDark])
    c.rect(21, 30, 14, 9, clawdOrange)
    c.rect(21, 38, 14, 1, clawdShade); c.rect(34, 30, 1, 9, clawdShade)
    // Horns, then the helmet cap.
    let horns: [[(Double, Double)]] = [
        [(23.5, 29.0), (20.5, 26.0), (19.5, 22.5), (20.5, 19.5)],
        [(31.5, 29.0), (34.5, 26.0), (35.5, 22.5), (34.5, 19.5)],
    ]
    for h in horns {
        for i in 0..<(h.count - 1) { stick(c, h[i].0, h[i].1, h[i + 1].0, h[i + 1].1, gold, [1.1, 0.9, 0.6][i]) }
    }
    stick(c, 20.5, 25.5, 20.0, 23.0, goldLight, 0.4)
    c.pattern(20, 27, [
        "...GGGGGGGGGG...",
        "..GGLGGGGGGGGG..",
        ".GGGGGGGGGGGGGG.",
        ".gggggggggggggg.",
        ".gK..........Kg.",
        ".gK..........Kg.",
        "..K..........K..",
    ], ["G": gold, "g": goldDark, "L": goldLight, "K": C(0x16161B)])
    // Eyes (one winks), cheeky brows and a lopsided grin.
    c.rect(24, 31, 2, 2, ink)
    if wink { c.rect(30, 32, 2, 1, ink); c.px(29, 31, ink) } else { c.rect(30, 31, 2, 2, ink) }
    c.px(23, 30, goldDark); c.px(32, 30, goldDark)
    c.pattern(25, 33, ["K....K", ".KKKK."], ["K": ink])
    c.px(31, 32, ink)
    // Green tunic with a gold collar.
    c.rect(21, 35, 14, 3, green)
    c.rect(21, 35, 14, 1, gold); c.rect(27, 36, 2, 2, gold)
    c.rect(21, 37, 14, 1, greenDark)
    c.rect(19, 35, 2, 2, green)
    c.rect(35, 35 - armUp, 2, 2, green); c.px(36, 35 - armUp, clawdOrange)
}

// MARK: - Alligator Loki

/// Alligator Loki: a little green alligator (long snout, bumpy back, stubby legs and a swishing tail) wearing
/// Loki's gold horned helmet. He bites: the jaw drops open and he lunges. Signature: chomp, chomp, then a proud
/// tail swish.
private func drawAlligatorLoki(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4E8A36), dark = C(0x2E5E22), belly = C(0xC8D890), mouth = C(0x8A2A3A)
    let gold = C(0xE8B530), goldDark = C(0xA8801E), goldLight = C(0xFFE08A)
    let sig = p.signature
    var open: Double = p.melee.map { a in max(0, 1 - abs(a - 5) / 45) } ?? 0
    if let s = sig, s < 0.6 { open = abs(sin(s / 0.6 * .pi * 3)) }
    let swish: Double = sig.map { $0 > 0.6 ? sin(($0 - 0.6) / 0.4 * .pi * 3) * sin(($0 - 0.6) / 0.4 * .pi) : 0 } ?? 0
    let lunge = p.melee != nil ? Int((2 * open).rounded()) : 0
    for (i, lx) in [17, 22, 31, 36].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx + lunge, 39, 3, lifted ? 3 : 4, green)
        c.rect(lx + lunge - 1, lifted ? 41 : 42, 4, 1, dark)
    }
    c.oy += p.breathe
    c.ox += lunge
    // Tail, tapering back to the left (and swishing up and down in the signature).
    for x in 2...15 {
        let k: Double = Double(15 - x) / 13
        let mid: Double = 37 - k * 2 + swish * k * k * 6 + sin(p.lt * 2 + k * 3) * k * 0.8
        let half: Double = 2.6 - k * 1.9
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, green)
        c.px(x, bottom, dark)
        if x % 3 == 0 { c.px(x, top - 1, dark) }
    }
    // Body: a long low block with a pale belly and ridges along the back.
    c.rect(15, 32, 26, 8, green)
    c.rect(16, 31, 24, 1, green)
    c.rect(17, 38, 22, 2, belly)
    c.rect(15, 39, 26, 1, dark)
    for x in stride(from: 17, through: 37, by: 3) { c.rect(x, 30, 2, 1, dark); c.px(x, 33, dark) }
    // Head and snout: the upper jaw, then the lower one dropped open by `o`.
    let o = Int((3 * open).rounded())
    c.pattern(38, 29, [
        "..EEE..........",
        ".EKKEGGG.......",
        "GGKKGGGGGGGGGG.",
        "GGGGGGGGGGGGGGN",
        "GGGGGGGGGGGGGGG",
        "GGGGgTgTgTgTgTg",
    ], ["G": green, "E": dark, "K": ink, "N": dark, "g": dark, "T": C(0xF0ECE0)])
    if o > 0 { c.rect(41, 35, 12, o, mouth) }
    c.pattern(38, 35 + o, [
        "GGGgTgTgTgTgT.",
        "GGBBBBBBBBBBB.",
        ".GBBBBBBBBBB..",
    ], ["G": green, "g": dark, "B": belly, "T": C(0xF0ECE0)])
    if o == 0 { c.rect(41, 35, 12, 1, dark) }
    // Loki's helmet, perched between the eyes and the back of the head.
    for (a, b, r) in [((39.5, 28.5), (37.0, 25.5), 1.0), ((37.0, 25.5), (37.5, 22.5), 0.7),
                      ((45.5, 28.5), (48.0, 25.5), 1.0), ((48.0, 25.5), (47.5, 22.5), 0.7)] as [((Double, Double), (Double, Double), Double)] {
        stick(c, a.0, a.1, b.0, b.1, gold, r)
    }
    c.pattern(38, 27, ["..GGLGGG..", ".GGGGGGGG.", "gggggggggg"], ["G": gold, "g": goldDark, "L": goldLight])
    c.ox -= lunge
}

// MARK: - Hunter B-15

/// Hunter B-15: a TVA Minuteman: close-cropped dark hair, black tactical gear with orange piping and shoulder pads,
/// and a time-stick that glows orange when it's drawn. Signature: she twirls the baton (three fast turns) and snaps
/// it forward, its tip flaring.
private func drawHunterB15(_ c: PixelCanvas, _ p: Pose) {
    let gear = C(0x26262C), gearLight = C(0x3E3E48), gearDark = C(0x16161A), hair = C(0x1A1412)
    drawLegs(c, Look(leg: C(0x34343C)), step: p.step)
    drawBoots(c, gearDark, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: gear))
    c.pattern(17, 22, [
        "....HHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHH.",
        ".HH..............HH.",
        ".H................H.",
    ], ["H": hair])
    c.rect(18, 29, 1, 2, gear); c.rect(17, 29, 1, 2, tvaOrange)          // earpiece
    c.rect(25, 33, 6, 1, clawdShade)                                      // a straight, no-nonsense mouth
    // Tactical vest: high collar, orange piping, shoulder pads.
    c.rect(18, 34, 20, 4, gear)
    c.rect(18, 34, 20, 1, tvaOrange)
    c.rect(22, 35, 1, 3, tvaOrange); c.rect(33, 35, 1, 3, tvaOrange)
    c.rect(24, 36, 8, 1, gearLight)
    c.rect(18, 37, 20, 1, gearDark)
    c.rect(15, 32, 4, 2, gearLight); c.rect(15, 34, 3, 2, gear)
    var angle = p.melee, trail = p.trail
    var flare: Double = 0
    if let s = p.signature {
        if s < 0.78 {
            let e: Double = s / 0.78
            let a: Double = 95 - 1175 * (e * e * (3 - 2 * e))
            angle = a; trail = [a + 30, a + 60]
        } else {
            angle = -10; trail = []
            flare = 1 - (s - 0.78) / 0.22
        }
    }
    if let a = angle {
        for (i, ta) in trail.enumerated() { drawTimeStick(c, angle: ta, alpha: 0.35 / Double(i + 1), lit: 0) }
        drawTimeStick(c, angle: a, lit: 1)
        if flare > 0 {
            let r: Double = -10 * .pi / 180
            let tx: Double = Sprite.hand.x + cos(r) * 11.5, ty: Double = Sprite.hand.y + sin(r) * 11.5
            c.ellipse(Int(tx), Int(ty), Int(2 + 5 * (1 - flare)), Int(2 + 5 * (1 - flare)), tvaOrange.alpha(0.35 * flare))
            c.glowLine(tx, ty, tx, ty, core: tvaGlow.alpha(flare), glow: tvaOrange.alpha(flare), coreR: 1, glowR: 3)
        }
    } else {
        drawTimeStick(c, angle: seatedPose ? 15 : 95, lit: 0, at: (41.5, 31.5))
    }
    c.rect(37, 32, 4, 2, gearLight); c.rect(38, 34, 3, 2, gear)
}

// MARK: - Red Guardian

/// Red Guardian: Alexei, burly and proud: a red helmet with a white star, a bushy beard, a red suit stretched over a
/// barrel chest with the white star, and a round red shield with a star in the middle that he bashes with (it hangs
/// on his left arm when it's put away). Signature: he thrusts the shield high overhead, roaring, the star glinting.
private func drawRedGuardian(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), dark = C(0x8A1018), star = C(0xF0ECE4), beard = C(0x5A3A22), beardDark = C(0x3A2416)
    let boot = C(0x2A1A1A)
    let raise = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 3)
    c.oy += p.breathe
    // A bigger body than plain Clawd.
    c.rect(16, 25, 23, 13, red)
    c.rect(16, 37, 23, 1, dark); c.rect(38, 25, 1, 13, dark)
    // Helmet round an open face.
    c.pattern(15, 18, [
        "......RRRRRRRRRRRRR......",
        "....RRRRRRRRRRRRRRRRR....",
        "...RRRRRRRRRWRRRRRRRRR...",
        "..RRRRRRRRRWWWRRRRRRRRr..",
        "..RRRRRRWWWWWWWWWRRRRRr..",
        "..RRRRRRRRWWWWWRRRRRRRr..",
        "..RRRRRRRRWWRWWRRRRRRRr..",
        ".RRRRRRRRRRRRRRRRRRRRRRr.",
        ".rrrrrrrrrrrrrrrrrrrrrrr.",
    ], ["R": red, "r": dark, "W": star])
    c.rect(19, 27, 18, 7, clawdOrange)
    c.rect(19, 27, 1, 7, dark); c.rect(36, 27, 1, 7, dark)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, beardDark); c.rect(32, 28, 3, 1, beardDark)
    // Beard, with the mouth wide open while he roars.
    c.pattern(20, 31, [
        "B..............B",
        "BB..BBBBBBBB..BB",
        "BBBBBBBBBBBBBBBB",
        ".BBBBBBBBBBBBBB.",
        "..bBBBBBBBBBBb..",
    ], ["B": beard, "b": beardDark])
    if raise > 0.3 { c.rect(25, 33, 6, 2, C(0x5A1A1A)); c.rect(25, 33, 6, 1, C(0xE8E0D0)) }
    // Chest star.
    c.pattern(25, 34, ["..W..", "WWWWW", ".WWW.", "W...W"], ["W": star])
    c.rect(13, 32, 3, 4, red); c.rect(13, 32, 1, 4, clawdOrange)
    if raise > 0.05 {
        let up: Double = 12 * raise
        c.rect(37, Int(33 - up), 4, Int(up) + 3, red)
        drawGuardianShield(c, cx: 39, cy: Int((33 - up - 4).rounded()))
        if raise > 0.6 { drawGlint(c, p: ((p.signature ?? 0) - 0.3) / 0.4, maxX: 48) }
        return
    }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            let r: Double = ta * .pi / 180
            drawGuardianShield(c, cx: Int((Sprite.hand.x + cos(r) * 5).rounded()), cy: Int((Sprite.hand.y + sin(r) * 5).rounded()),
                               alpha: 0.3 / Double(i + 1))
        }
        c.rect(39, 32, 3, 4, red)
        let r: Double = a * .pi / 180
        drawGuardianShield(c, cx: Int((Sprite.hand.x + cos(r) * 5).rounded()), cy: Int((Sprite.hand.y + sin(r) * 5).rounded()))
    } else {
        c.rect(39, 32, 3, 4, red); c.rect(41, 32, 1, 4, clawdOrange)
        drawGuardianShield(c, cx: 14, cy: 33)
    }
}

/// The round red shield with the white star, centred on (`cx`, `cy`).
private func drawGuardianShield(_ c: PixelCanvas, cx: Int, cy: Int, alpha: Double = 1) {
    c.circle(cx, cy, 6, C(0x6A0C14, alpha))
    c.circle(cx, cy, 5, C(0xD8303A, alpha))
    c.circle(cx, cy, 3, C(0xB01C26, alpha))
    c.pattern(cx - 2, cy - 2, ["..W..", "WWWWW", ".WWW.", ".W.W."], ["W": C(0xF0ECE4, alpha)])
    c.px(cx - 3, cy - 5, C(0xF08A8A, alpha * 0.8)); c.px(cx - 4, cy - 4, C(0xF08A8A, alpha * 0.8))
}

// MARK: - Ka-Zar

/// Ka-Zar, Lord of the Savage Land: a shaggy blond mane, bare chest, a sabretooth-fur loincloth (orange, black
/// stripes) with fur on one shoulder, fur-wrapped boots and a hunting knife. Signature: two fingers to his mouth, he whistles
/// (notes fly) and Zabu's striped head pops up behind him with a roar.
private func drawKaZar(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xE8C860), hairShade = C(0xB8944A), fur = C(0xE08A30), stripe = C(0x2A1A10), furLight = C(0xF0C890)
    let sig = p.signature
    if let s = sig, s > 0.42 { drawZabuPeek(c, p, s: (s - 0.42) / 0.58) }
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 3, fur); c.px(lx, bottom - 1, stripe)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(eye: nil))
    c.pattern(15, 18, [
        ".......HHHHHHHHHH.......",
        "....HHHHHHHhHHHHHHHH....",
        "..HHHHhHHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHhHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHhHHHHHHHHhHHHHHHHHHH",
        "HHHHHHHhHHHHHHHHHHHhHHHH",
        "HHHHHHHHHHhHHHHHHHHHHHHH",
        "HHHHHHH.HHHHH.HHHH.HhHHH",
        "HHHh..H.....H......H.HHH",
        "HHHh.................HHH",
        "HHH..................hHH",
        "HHh..................HHH",
        ".HH...................HH",
        ".Hh...................hH",
        "..H...................H.",
        "..h...................h.",
    ], ["H": hair, "h": hairShade])
    let whistle = sig.map { $0 > 0.05 && $0 < 0.5 } ?? false
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, hairShade); c.rect(32, 28, 3, 1, hairShade)
    if whistle {
        c.rect(27, 32, 2, 2, C(0x5A1A1A)); c.rect(26, 31, 4, 1, clawdShade)
    } else {
        c.rect(25, 33, 6, 1, clawdShade); c.px(31, 32, clawdShade)
    }
    // The sabretooth-skin loincloth and a fur shoulder piece.
    c.pattern(18, 35, [
        "FFFsFFFFFsFFFFsFFFFF",
        "FsFFFFsFFFFFFsFFFFsF",
        "FFFFsFFFFFsFFFFFsFFF",
    ], ["F": fur, "s": stripe])
    c.pattern(15, 32, ["FsF", "FFs"], ["F": fur, "s": stripe])
    c.pattern(25, 38, ["FsFFsF", ".FFFF.", "..ff.."], ["F": fur, "s": stripe, "f": furLight])
    c.rect(15, 33, 3, 3, clawdOrange); c.rect(15, 35, 3, 1, fur)
    if whistle {
        c.rect(30, 31, 6, 2, clawdOrange); c.rect(30, 31, 1, 2, clawdShade)
        c.rect(36, 31, 3, 4, clawdOrange)
        if let s = sig {
            for i in 0..<3 {
                let f: Double = (s - 0.1) * 3 - Double(i) * 0.35
                guard f > 0, f < 1 else { continue }
                let x = 36 + Int(f * 10) + i * 3, y = 26 - Int(f * 12)
                let col = C(0x1E2A5A)
                c.pattern(x, y, ["..KKK", "..K.K", "..K..", "KKK..", "KKK.."], ["K": col])
            }
        }
        drawKnife(c, angle: 100, at: (41.5, 32.5))
        return
    }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawKnife(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawKnife(c, angle: a)
    } else {
        drawKnife(c, angle: seatedPose ? 15 : 100, at: (41.5, 32.5))
    }
    c.rect(38, 33, 3, 3, clawdOrange); c.rect(38, 35, 3, 1, fur)
}

/// Ka-Zar's hunting knife along `angle` from the hand.
private func drawKnife(_ c: PixelCanvas, angle: Double, alpha: Double = 1, at: (x: Double, y: Double) = Sprite.hand) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.rect(17, 20, 4, 2, C(0x6A4428)); s.px(18, 20, C(0x9A6A3A))
        s.rect(21, 19, 1, 4, C(0x4A4A54))
        s.rect(22, 20, 7, 1, C(0xC8CCD4)); s.rect(22, 21, 6, 1, C(0x8A8F9C)); s.px(29, 20, C(0xA4AAB4))
    }
}

/// Zabu's head rising up behind Ka-Zar's left shoulder, `s` (0…1) through his visit; the jaw drops in a roar.
private func drawZabuPeek(_ c: PixelCanvas, _ p: Pose, s: Double) {
    let up: Double = s < 0.2 ? s / 0.2 : (s > 0.85 ? max(0, 1 - (s - 0.85) / 0.15) : 1)
    let roar = s > 0.3 && s < 0.75
    let y = 19 + Int(((1 - up) * 16).rounded()) + p.breathe
    let o = roar ? 2 : 0
    let rows: [String] = [
        ".ee.......ee.",
        "eOOOOOOOOOOOe",
        "OOKOOKOOOKOOO",
        "OOOOOOKOOOOOO",
        "OkkOOOOOOOkkO",
        "OOOOOWWWOOOOO",
        "OOOWWWNWWWOOO",
        ".OWWWWWWWWWO.",
    ]
    let pal: [Character: Px] = ["O": C(0xE88A30), "e": C(0xB86420), "K": C(0x2A1A10), "k": ink, "W": C(0xF0E0C0),
                                "N": C(0x5A2A2A), "F": C(0xF0ECE0)]
    c.pattern(3, y, rows, pal)
    if o > 0 { c.rect(5, y + 8, 9, o, C(0x7A1A1A)) }
    c.pattern(3, y + 8 + o, [".OWFWWWWWFWO.", "..WFWWWWWFW..", "....F...F...."], pal)
    if roar {
        for i in 0..<3 {
            let r: Double = 9 + Double(i) * 2.5 + frac(p.t * 3) * 2
            c.glowLine(9 - r * 0.2, Double(y) - r * 0.35, 9 + r * 0.2, Double(y) - r * 0.5,
                       core: C(0xFFFFFF, 0.5), glow: C(0xFFFFFF, 0), coreR: 0.4, glowR: 0.5)
        }
    }
}

// MARK: - Rescue

/// Rescue: Pepper Potts' armour: deep blue with silver plates, a silver faceplate with glowing blue eye slits, a
/// glowing chest disc and the silver thruster vanes on her back; repulsors from the right palm. In flight she leans
/// in, legs together, boots and palms burning. Signature: the faceplate lifts to show Pepper (strawberry-blonde
/// hair and a smile), then closes again.
private func drawRescue(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x3A5AA8), dark = C(0x24387A), silver = C(0xB8BCC4), silverDark = C(0x80869A)
    let glow = C(0xDFF0FF), glowBlue = C(0x6A9AFF)
    let look = Look(body: blue, shade: dark, leg: blue, arm: blue, eye: nil)
    layer(c, lean: p.flying ? 4 : 0) { c in
        // Back vanes.
        c.oy += p.breathe
        let spread: Double = p.flying ? 2 : 0
        for (a, b) in [((19.0, 27.0), (10.0, 19.0 - spread)), ((18.0, 30.0), (8.0, 26.0 - spread)), ((18.0, 33.0), (9.0, 33.0))]
            as [((Double, Double), (Double, Double))] {
            stick(c, a.0, a.1, b.0, b.1, silverDark, 1.3)
            stick(c, a.0, a.1 - 0.5, b.0 + 1, b.1 - 0.5, silver, 0.6)
            c.glowLine(b.0, b.1, b.0, b.1, core: glow, glow: glowBlue, coreR: 0.5, glowR: 1.5)
        }
        c.oy -= p.breathe
        if p.flying {
            for lx in [21, 31] {
                c.rect(lx, 36, 4, 5, blue); c.rect(lx, 39, 4, 2, silver); c.rect(lx + 3, 36, 1, 5, dark)
                drawJet(c, x: lx, y: 41, w: 4, t: p.t, seed: lx)
            }
        } else {
            drawLegs(c, look, step: p.step)
            drawBoots(c, silver, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        drawBody(c, look)
        let open = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
        let skin = open > 0.05
        c.pattern(17, 20, [
            "......BBBBBBBBBB......",
            "....BBBBBBSSBBBBBB....",
            "...BBBBBBSSSSBBBBBB...",
            "..BBBBBSSSSSSSSBBBBb..",
            "..BBBBSSSSSSSSSSBBBb..",
            ".BBBBSSSSSSSSSSSSBBBb.",
            ".BBBSSSSSSSSSSSSSSBBb.",
            ".BBSSSSSSSSSSSSSSSSBb.",
            ".BBSWWWWSSSSSSWWWWSBb.",
            ".BBSSWWWSSSSSSWWWSSBb.",
            ".BBsSSSSSSSSSSSSSSsBb.",
            ".BBBsSSSSSSSSSSSSsBBb.",
            ".BBBBsSSSkkkkSSSsBBBb.",
            ".BBBBBsssssssssBBBBBb.",
            ".BBBBBBBBBBBBBBBBBBBb.",
        ], ["B": blue, "b": dark, "S": skin ? clawdOrange : silver, "s": skin ? clawdShade : silverDark,
            "W": skin ? clawdOrange : glow, "k": skin ? clawdOrange : silverDark])
        if skin {
            // Pepper: strawberry-blonde fringe and a smile; the faceplate hinged up over the brow.
            let hair = C(0xE0A060)
            c.rect(21, 25, 14, 2, hair); c.rect(20, 26, 2, 5, hair); c.rect(34, 26, 2, 5, hair)
            c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
            c.pattern(25, 32, ["K....K", ".KKKK."], ["K": C(0x8A2A3A)])
            let h = max(3, Int((12 * (1 - open)).rounded())), top = 23 - Int((5 * open).rounded())
            c.rect(20, top, 16, h, silver); c.rect(20, top + h - 1, 16, 1, silverDark)
            if h > 6 { c.rect(21, top + h - 5, 4, 1, glow); c.rect(31, top + h - 5, 4, 1, glow) }
        }
        // Chest disc, silver trim.
        c.glowLine(28, 36, 28, 36, core: glow, glow: glowBlue, coreR: 1, glowR: 2.2)
        c.rect(19, 37, 6, 1, silver); c.rect(31, 37, 6, 1, silver)
        if p.flying {
            for x in [15, 38] { c.rect(x, 34, 3, 3, blue); c.rect(x, 36, 3, 1, silver); drawJet(c, x: x, y: 37, w: 3, t: p.t + 0.3, seed: x) }
            return
        }
        c.rect(15, 33, 1, 3, silver)
        c.oy += p.gunY
        c.rect(38, 33, 4, 3, blue); c.rect(41, 33, 1, 3, silver); c.rect(40, 33, 1, 3, silverDark)
        if p.fire != nil || p.ready || p.gunLift > 0 {
            c.glowLine(42.5, 34.5, 42.5, 34.5, core: glow, glow: glowBlue, coreR: 0.6, glowR: 1.8)
        }
    }
}

/// A thruster's flame: `w` wide, flickering down from (`x`, `y`).
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int) {
    let len = 2 + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, C(0x6A9AFF, 0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, C(0xBFE0FF))
    c.rect(x, y, w, 1, C(0xF4FCFF))
}

// MARK: - Zabu

/// Zabu: Ka-Zar's sabretooth tiger: a big orange cat with black stripes, a cream muzzle and belly, a curling tail
/// and two huge fangs. He fights with a bite, jaw dropping open as he lunges. Signature: he throws his head back
/// and roars.
private func drawZabu(_ c: PixelCanvas, _ p: Pose) {
    let orange = C(0xE88A30), dark = C(0xB86420), stripe = C(0x2A1A10), cream = C(0xF0E0C0), fang = C(0xF0ECE0)
    let mouth = C(0x7A1A1A)
    let sig = p.signature
    let roar: Double = sig.map { habitArc($0, hold: 0.5) } ?? 0
    var open: Double = p.melee.map { a in max(0, 1 - abs(a - 5) / 45) } ?? 0
    open = max(open, roar)
    let lunge = p.melee != nil ? Int((2 * open).rounded()) : 0
    for (i, lx) in [11, 17, 30, 36].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx + lunge, 36, 4, lifted ? 6 : 7, orange)
        c.rect(lx + lunge + 3, 36, 1, lifted ? 6 : 7, dark)
        c.rect(lx + lunge, lifted ? 41 : 42, 5, 1, cream)
        if i % 2 == 0 { c.px(lx + lunge + 1, 38, stripe) }
    }
    c.oy += p.breathe
    c.ox += lunge
    // Tail, curling up at the tip.
    let flick: Double = sin(p.lt * 2.5)
    for (a, b, r) in [((10.0, 28.0), (5.0, 31.0), 1.3), ((5.0, 31.0), (2.0, 27.0), 1.1), ((2.0, 27.0), (3.0 + flick, 22.0), 1.0)]
        as [((Double, Double), (Double, Double), Double)] {
        stick(c, a.0, a.1, b.0, b.1, orange, r)
    }
    c.rect(2 + Int(flick.rounded()), 21, 3, 2, stripe)
    c.px(3, 30, stripe); c.px(2, 26, stripe)
    // Body.
    c.rect(9, 26, 30, 12, orange)
    c.rect(10, 25, 26, 1, orange)
    c.rect(12, 34, 24, 3, cream)
    c.rect(9, 37, 30, 1, dark)
    for x in [13, 17, 21, 25, 29] { c.rect(x, 25, 1, 4, stripe); c.px(x + 1, 29, stripe); c.px(x - 1, 31, stripe) }
    // Head in profile: the upper part tilts back while he roars, the lower jaw drops.
    let back = Int((2 * roar).rounded())
    let o = Int((4 * open).rounded())
    let hx = 33, hy = 19 - back
    c.pattern(hx, hy, [
        "...ee.............",
        "..eOOe..ee........",
        "..OOOOOOOOe.......",
        ".OOKOOKOOOOO......",
        ".OOOOOOOOOOOO.....",
        "OOOOKOOOkkOOOO....",
        "OOOOOOOOkkOOOOO...",
        "OOOKOOOOOOOOOOOOO.",
        "OOOOOOOOOOOOOOOWWN",
        "OOOOOOOOOWWWWWWWWW",
        "OOOOOOOOWWWWWWWWWW",
    ], ["O": orange, "e": dark, "K": stripe, "k": ink, "W": cream, "N": C(0x5A2A2A)])
    let jaw = hy + 11
    if o > 0 { c.rect(hx + 8, jaw, 10, o + back, mouth) }
    c.pattern(hx, jaw + o + back, [
        "OOOOOOOWWWWWWWWW..",
        "OOOOOOWWWWWWWWW...",
        ".OOOOOWWWWWWW.....",
    ], ["O": orange, "W": cream])
    c.rect(hx, jaw, 8, o + back, orange)
    // The sabre fangs hang from the upper jaw.
    for (x, h, col) in [(hx + 10, 5, fang.alpha(0.85)), (hx + 14, 6, fang)] as [(Int, Int, Px)] {
        c.rect(x, jaw, 2, h - 1, col); c.px(x, jaw + h - 1, col)
    }
    if roar > 0.4 {
        for i in 0..<3 {
            let r: Double = 4 + Double(i) * 3 + frac(p.t * 3) * 2
            for k in -2...2 {
                let a: Double = Double(k) * 0.3
                c.px(Int(49 + cos(a) * r), Int(Double(jaw) + sin(a) * r), C(0xF4E8D0, 0.8 - Double(i) * 0.2))
            }
        }
    }
    c.ox -= lunge
}

// MARK: - Morris

/// Morris: the faceless hundun from Ta Lo: a round ball of cream fur with no face at all, four little red-feathered
/// wings that never stop flapping and six spindly legs dangling as it hovers. Signature: it flaps extra hard and
/// flutters up in a happy little bob, a heart popping above it.
private func drawMorris(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xEAD2A2), furShade = C(0xC8A870), tuft = C(0xA88450), wing = C(0xD8503A), wingDark = C(0x9A2A1A)
    let leg = C(0x8A6A48)
    let sig = p.signature
    let happy: Double = sig.map { habitArc($0, hold: 0.6) } ?? 0
    let lift = Int((4 * happy).rounded())
    let wiggle = happy > 0.3 ? (sin(p.t * 14) > 0 ? 1 : -1) : 0
    c.oy -= lift
    c.ox += wiggle
    // Six thin legs dangling.
    for (i, lx) in [19, 23, 26, 30, 33, 37].enumerated() {
        let sway = Int((sin(p.lt * 3 + Double(i)) * 0.6).rounded())
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 37, 2, lifted ? 4 : 5, leg)
        c.rect(lx + sway, lifted ? 41 : 42, 2, 1, C(0x5A4430))
    }
    c.oy += p.breathe
    // Back wings, then the round furry body, then the front wings.
    let speed: Double = 9 + 18 * happy
    let flap: Double = sin(p.lt * speed)
    drawMorrisWing(c, root: (22, 25), angle: -125 + 35 * flap, len: 6, wing: wingDark, tip: wing)
    drawMorrisWing(c, root: (34, 25), angle: -55 - 35 * flap, len: 6, wing: wingDark, tip: wing)
    // A fluffy ball: tufts sticking out all round, shaded underneath.
    for i in 0..<16 {
        let a: Double = Double(i) * .pi / 8 + 0.2
        c.rect(Int((28 + cos(a) * 10.5).rounded()) - 1, Int((30.5 + sin(a) * 8.8).rounded()) - 1, 2, 2, i % 3 == 0 ? furShade : fur)
    }
    c.ellipse(28, 31, 10, 8, furShade)
    c.ellipse(28, 30, 10, 8, fur)
    c.ellipse(30, 27, 4, 2, C(0xF6E6C4))
    for (x, y) in [(22, 33), (26, 35), (33, 34), (30, 31), (23, 28), (35, 30), (19, 31), (37, 34)] as [(Int, Int)] {
        c.px(x, y, tuft); c.px(x + 1, y - 1, tuft)
    }
    drawMorrisWing(c, root: (20, 28), angle: -150 + 30 * flap, len: 8, wing: wing, tip: C(0xF08A5A))
    drawMorrisWing(c, root: (36, 28), angle: -30 - 30 * flap, len: 8, wing: wing, tip: C(0xF08A5A))
    if let s = sig, s > 0.35, s < 0.95 {
        let f: Double = (s - 0.35) / 0.6
        let a: Double = f < 0.7 ? 1 : (1 - f) / 0.3
        c.pattern(32, 17 - Int(f * 7), [".HH.HH.", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."], ["H": C(0xF04A7A, a)])
    }
}

/// One of Morris' wings: three feathers fanning out from `root` around `angle` degrees.
private func drawMorrisWing(_ c: PixelCanvas, root: (Double, Double), angle: Double, len: Double, wing: Px, tip: Px) {
    for (k, d) in [(0.75, -18.0), (1.0, 0.0), (0.8, 18.0)] as [(Double, Double)] {
        let r: Double = (angle + d) * .pi / 180
        let l: Double = len * k
        stick(c, root.0, root.1, root.0 + cos(r) * l, root.1 + sin(r) * l, wing, 0.9)
        c.px(Int(root.0 + cos(r) * l), Int(root.1 + sin(r) * l), tip)
    }
}

// MARK: - Dum-E

/// Dum-E: Tony's well-meaning, hopeless workshop robot: a grey robot arm on a wheeled base (Clawd's block, with two
/// status lights for eyes), a two-fingered claw clutching a red fire extinguisher. Signature: the extinguisher goes
/// off by accident, the arm jerks about spraying foam everywhere, and then droops, ashamed.
private func drawDumE(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x6A6E78), metalLight = C(0x9A9EA8), dark = C(0x3A3C44), black = C(0x1E1F24)
    let sig = p.signature
    // Wheels, then the base block.
    let spin = p.walking ? Int(p.t * 8) % 2 : 0
    if !seatedPose {
        for lx in [19, 23, 31, 35] {
            c.circle(lx + 1, 41, 2, black)
            c.px(lx + 1 + (spin == 0 ? 0 : 1), 41, metalLight)
        }
    }
    c.oy += p.breathe
    c.rect(18, 31, 20, 9, metal)
    c.rect(18, 31, 20, 1, metalLight)
    c.rect(18, 39, 20, 1, dark); c.rect(37, 31, 1, 9, dark)
    c.rect(20, 36, 16, 2, dark)
    for x in [21, 25, 29, 33] { c.px(x, 36, C(0xE8C02A)) }               // hazard stripes
    let blink = Int(p.lt * 2) % 5 == 0
    let lamp = sig.map { $0 > 0.15 && $0 < 0.75 } ?? false ? C(0xFF4A3A) : C(0x6AE0FF)
    if !blink { c.rect(22, 33, 2, 2, lamp); c.rect(32, 33, 2, 2, lamp) }
    // The arm: shoulder on the base, elbow up high, wrist and claw out front.
    var elbow: (Double, Double) = (33, 16 + sin(p.lt * 1.4))
    var wrist: (Double, Double) = (43, 23 + sin(p.lt * 1.4 + 0.8))
    var droop: Double = 0
    if let s = sig {
        if s > 0.15 && s < 0.75 {
            let j: Double = (s - 0.15) / 0.6
            elbow = (33 + 2 * sin(p.t * 9), 15 + 2 * sin(p.t * 7))
            wrist = (44 + 3 * sin(p.t * 11 + j * 4), 21 + 4 * sin(p.t * 8 + 1))
        } else if s >= 0.75 {
            droop = min(1, (s - 0.75) / 0.12)
            elbow = (33, 16 + 5 * droop)
            wrist = (40, 23 + 9 * droop)
        }
    }
    stick(c, 23, 31, 23, 23, dark, 2)
    c.circle(23, 23, 2, black)
    stick(c, 23, 23, elbow.0, elbow.1, metal, 1.6)
    stick(c, 23, 22.5, elbow.0, elbow.1 - 0.5, metalLight, 0.5)
    c.circle(Int(elbow.0), Int(elbow.1), 2, black)
    stick(c, elbow.0, elbow.1, wrist.0, wrist.1, metal, 1.3)
    c.circle(Int(wrist.0), Int(wrist.1), 1, black)
    // Claw holding the extinguisher.
    let wx = Int(wrist.0), wy = Int(wrist.1)
    c.pattern(wx - 3, wy + 1, ["RRRR.", "RRRRk", "rRRRk", "rRRR.", "rRRR.", "rRRR.", ".rr.."],
              ["R": C(0xD8282A), "r": C(0x9A1418), "k": black])
    c.rect(wx - 2, wy + 1, 2, 1, C(0xE8C02A))
    c.rect(wx - 4, wy + 2, 1, 3, dark); c.rect(wx + 1, wy, 1, 3, dark)
    c.px(wx + 2, wy + 2, black)
    // The foam, spraying wildly out of the nozzle.
    if let s = sig, s > 0.15, s < 0.82 {
        let j: Double = (s - 0.15) / 0.67
        let dir: Double = -0.5 + 0.9 * sin(p.t * 6)
        for i in 0..<8 {
            let f: Double = frac(p.t * 2.5 + Double(i) / 8)
            let d: Double = 2 + f * 18
            let x: Double = Double(wx + 2) + cos(dir + noise(i * 7 + Int(p.t * 3)) * 0.6 - 0.3) * d
            let y: Double = Double(wy + 2) + sin(dir + noise(i * 5 + Int(p.t * 3)) * 0.6 - 0.3) * d
            let r = 1 + Int(f * 2.5)
            let a: Double = (1 - f * 0.6) * (j < 0.85 ? 1 : (1 - j) / 0.15)
            c.circle(Int(x), Int(y), r, C(0xEEF2F6, min(1, a * 1.2)))
        }
    }
}

// MARK: - Shared helpers

/// A thick line from (x0, y0) to (x1, y1), `r` pixels round: horns, arms, tails.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0x000000, 0), coreR: r, glowR: r + 0.05)
}

private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`
/// pixels, washed towards `tint`'s colour by its amount, and leaning forward one pixel every `lean` rows above the
/// feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, dx: Int = 0, lean: Int = 0, tint: (Px, Double)? = nil,
                   _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            var col = unpremultiplied(s, i)
            if let (t, k) = tint { col = mix(col, t, k) }
            c.px(x + shift + dx, y, col.alpha(alpha))
        }
    }
}

/// `a` washed towards `b` by `k` (0…1), keeping `a`'s opacity.
private func mix(_ a: Px, _ b: Px, _ k: Double) -> Px {
    let r: Double = Double(a.r) + (Double(b.r) - Double(a.r)) * k
    let g: Double = Double(a.g) + (Double(b.g) - Double(a.g)) * k
    let bl: Double = Double(a.b) + (Double(b.b) - Double(a.b)) * k
    return Px(r: UInt8(r), g: UInt8(g), b: UInt8(bl), a: a.a)
}

/// Draws `art` (pointing right from (20.5, 20.5) on a 41×41 scratch canvas) turned to `angle` degrees about `at`.
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
