import Foundation

// Star Wars heroes: Jar Jar to Admiral Ackbar. Ported from Clawd Wars' Recruits.swift.

let starWarsHeroes2: [SWHero: Persona] = [
    .jarjar: Persona(name: "J.J Blinks", headTop: 18,
                  draw: drawJarjar),
    .lando: Persona(name: "Lando Coolrissian", weapon: .blaster, muzzle: (47, 32), headTop: 22,
                  soloFire: (1.0, 0.3),
                  draw: drawLando),
    .zorii: Persona(name: "Zori Blitz", weapon: .blaster, muzzle: (47, 32), headTop: 19,
                  soloFire: (0.85, 0.6),
                  draw: drawZorii),
    .boKatan: Persona(name: "Bo-Kitan Krays", weapon: .blaster, muzzle: (47, 32), headTop: 19,
                  soloFire: (0.8, 0.1),
                  draw: drawBoKatan),
    .maz: Persona(name: "Maz Kanapé", headTop: 22, signature: 2.4,
                  draw: drawMaz),
    .wedge: Persona(name: "Wedge Antlers", weapon: .blaster, muzzle: (47, 32), headTop: 19,
                  soloFire: (0.9, 0.45),
                  draw: drawWedge),
    .l337: Persona(name: "LE-ET", headTop: 17,
                  draw: drawL337),
    .monMothma: Persona(name: "Mon Mothball", canSit: false, headTop: 22,
                  draw: drawMonMothma),
    .padme: Persona(name: "Padmé Amidrama", weapon: .blaster, muzzle: (47, 32), headTop: 22,
                  soloFire: (1.1, 0.2),
                  draw: drawPadme),
    .ackbar: Persona(name: "Admiral Snackbar", headTop: 17,
                  draw: drawAckbar),
]

// MARK: - Shared

/// Legs, then the origin raised for the upper body. Cheering, the legs stay on the ground and only the body hops,
/// as in Clawd Wars.
private func heroLegs(_ c: PixelCanvas, _ p: Pose, _ look: Look) {
    let grounded = p.cheering && !p.walking
    if grounded { c.oy -= p.hop }
    drawLegs(c, look, step: p.step)
    if grounded { c.oy += p.hop }
    c.oy += p.breathe
}

/// A gown or robe from `top` to the floor, widening to the hem (drawn instead of legs).
private func drawSkirt(_ c: PixelCanvas, from top: Int = 38, _ main: Px, _ edge: Px) {
    for y in top...43 {
        let k = (y - top) / 2
        c.rect(18 - k, y, 20 + k * 2, 1, main)
        c.px(18 - k, y, edge); c.px(37 + k, y, edge)
    }
}

/// The pistol in the right hand, raised or kicking as the pose says; its muzzle is at (47, 32).
private func heroPistol(_ c: PixelCanvas, _ p: Pose) {
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 31)
    c.oy -= p.gunY
}

/// A Mandalorian helmet: the T visor, and on Bo-Katan the Nite Owl markings either side of it.
private func drawMandoHelmet(_ c: PixelCanvas, _ main: Px, _ shine: Px, marks: Px? = nil) {
    c.pattern(17, 19, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHhhHHHHHHHHHHHHHH..",
        ".HHhHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHMMMHHHHHHHHHHHHMMMHH",
        "HHHMMKKKKKKKKKKKKMMHHH",
        "HHHHHKKKKKKKKKKKKHHHHH",
        "HHHHHHHHHKKKKHHHHHHHHH",
        "HHHHHHHHHKKKKHHHHHHHHH",
        "HHHHHHHHHKKKKHHHHHHHHH",
        ".HHHHHHHHKKKKHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHH..",
    ], ["H": main, "h": shine, "K": ink, "M": marks ?? main])
}

// MARK: - Heroes

/// Jar Jar Binks: a Gungan, all ears and eyestalks, arms everywhere. Unarmed (mesa no fight).
private func drawJarjar(_ c: PixelCanvas, _ p: Pose) {
    let t = p.t
    let skin = C(0xD9935A), skinDark = C(0xB0703C), cloth = C(0x6E5A3A), clothDark = C(0x54442A)
    let flail = Int(t * 5) % 2
    let look = Look(body: skin, shade: skinDark, leg: cloth, arm: skin, eye: nil)
    heroLegs(c, p, look)
    // Long ears hanging down both sides, under the arms.
    let ear = ["EE..", "EEE.", ".EE.", ".EEE", "..EE", "..EE", "..EE", "..EE", ".EEE", ".EEE", "EEE.", "EE..", "E..."]
    c.pattern(13, 26, ear, ["E": skinDark])
    c.pattern(39, 26, ear.map { String($0.reversed()) }, ["E": skinDark])
    drawBody(c, look, armLeft: flail == 0 ? 3 : 0, armRight: flail == 0 ? 0 : 3)
    // Eyes up on stalks, wobbling.
    let wob = sin(t * 7) > 0 ? 1 : 0
    c.rect(23, 21, 1, 5, skin); c.rect(32, 21, 1, 5, skin)
    for ex in [21 + wob, 30 + wob] {
        c.pattern(ex, 18, [".WWW.", "WWWkW", ".WWW."], ["W": C(0xF2E8C8), "k": ink])
    }
    c.rect(35, 30, 6, 3, skin)                  // the duck bill
    c.rect(36, 32, 5, 1, skinDark)
    c.rect(18, 34, 20, 4, cloth)
    c.rect(18, 34, 20, 1, clothDark)
}

/// Lando Calrissian: neat moustache, sky-blue shirt and a cape lined in gold.
private func drawLando(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0x8FB4D9), hair = C(0x1E1612)
    // The cape's hem is clipped at the feet by `c.oy`: a whole-sprite shift (sitting down, hopping) goes through
    // `baseY` instead, as in Clawd Wars, so the cape still reaches the floor seated. Only a cheer hop moves it.
    let shift = p.cheering && !p.walking ? 0 : p.hop
    c.oy += p.breathe - shift; c.baseY += shift
    drawCape(c, t: p.t, speed: 1.4, color: C(0x24305A), edge: C(0xE0B84A))
    c.oy -= p.breathe - shift; c.baseY -= shift
    let look = Look(leg: C(0x2A2E44), arm: shirt)
    heroLegs(c, p, look)
    drawBody(c, look)
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HH................HH",
    ], ["H": hair])
    c.rect(24, 32, 8, 1, hair)                  // the moustache
    c.rect(18, 34, 20, 4, shirt)
    c.rect(18, 36, 20, 1, C(0x3A2A1C))
    heroPistol(c, p)
}

/// Zorii Bliss: the bronze helmet with its dark visor and an orange glint, maroon flight suit.
private func drawZorii(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x5A2A3A)
    let look = Look(body: suit, shade: C(0x44202C), leg: C(0x3A2A30), arm: suit, eye: nil)
    heroLegs(c, p, look)
    drawBody(c, look)
    c.pattern(17, 19, [
        ".....BBBBBBBBBBBB.....",
        "...BBBBBBBBBBBBBBBB...",
        "..BBhhBBBBBBBBBBBBBB..",
        ".BBhBBBBBBBBBBBBBBBBB.",
        ".BBBBBBBBBBBBBBBBBBBB.",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBVVVVVVVVVVVVVVVVVVBB",
        "BBvvvvvvvvvvvvvvvvvvBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        ".BBBBBBBBGGGGBBBBBBBB.",
        "..BBBBBBBBBBBBBBBBBB..",
    ], ["B": C(0xB8923E), "h": C(0xE8C870), "V": C(0x1A1410), "v": C(0xD86A2A), "G": C(0x5A4420)])
    c.rect(18, 36, 20, 1, C(0x2A1A1E))
    heroPistol(c, p)
}

/// Bo-Katan Kryze: blue Mandalorian armour, the Nite Owl helmet, a blaster in hand.
private func drawBoKatan(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x4A6EA8), suit = C(0x3A3E48)
    let look = Look(body: suit, shade: C(0x2C2F38), leg: C(0x2C2F38), arm: blue, eye: nil)
    heroLegs(c, p, look)
    drawBody(c, look)
    drawMandoHelmet(c, C(0x5A7AB0), C(0x9AB4E0), marks: C(0x24345A))
    c.rect(19, 33, 18, 3, blue)                 // chest plate
    c.rect(19, 33, 18, 1, C(0x7A9AD0))
    c.rect(18, 36, 20, 1, C(0x5A4A3A))
    heroPistol(c, p)
}

/// Maz Kanata: small and orange, with the big round goggles that see right through you.
private func drawMaz(_ c: PixelCanvas, _ p: Pose) {
    let t = p.t
    let skin = C(0xD98E4A), skinDark = C(0xB06E34)
    let look = Look(body: skin, shade: skinDark, leg: C(0x5A4430), arm: skin, eye: nil)
    heroLegs(c, p, look)
    drawBody(c, look)
    c.pattern(18, 22, [
        "...WWWWWWWWWWWWWW...",
        ".WWWWwWWWWWWWWwWWWW.",
        "WWWWWWWWWWWWWWWWWWWW",
    ], ["W": C(0x6A4A32), "w": C(0x8A6A4A)])
    // The goggles: brass rims, dark lenses, eyes swimming behind them (they focus now and then).
    // Signature: she reaches up and twists the rims, and her eyes swim up huge behind the lenses: she sees you.
    let adjust = p.signature.flatMap { $0 > 0.1 && $0 < 0.9 ? ($0 - 0.1) / 0.8 : nil }
    let zoom = adjust.map { $0 > 0.3 } ?? false
    let focus = !zoom && sin(t * 0.9) > 0.85
    for ex in [23, 33] {
        c.circle(ex, 30, zoom ? 4 : 3, C(0x8A6A3A))
        c.circle(ex, 30, zoom ? 3 : 2, C(0x2A3A4A))
        if zoom {                                                    // magnified eyes
            c.circle(ex, 30, 2, C(0xF4ECD8)); c.rect(ex - 1, 29, 2, 3, C(0x1A1008)); c.px(ex - 1, 29, C(0x6A4A2A))
        } else {
            c.rect(ex, 30, focus ? 1 : 2, focus ? 1 : 2, C(0x1A1008))
        }
        c.px(ex - (zoom ? 2 : 1), zoom ? 28 : 29, C(0xBFE0F0))
    }
    c.rect(26, 30, 4, 1, C(0x8A6A3A))
    if let k = adjust {
        let a = k * 8                                                // the rim turning: a bright notch going round
        c.px(33 + Int((cos(a) * (zoom ? 4 : 3)).rounded()), 30 + Int((sin(a) * (zoom ? 4 : 3)).rounded()), C(0xF0D080))
        c.rect(37, 32, 3, 4, skin); c.rect(36, 31, 2, 2, skin)       // her fingers on the rim
    }
    c.rect(18, 34, 20, 4, C(0x8A6A4A))
    c.rect(22, 34, 12, 1, C(0xD8B040))           // beads
}

/// Wedge Antilles: an X-wing pilot, orange flight suit and white helmet with red flashes.
private func drawWedge(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xE0782A), white = C(0xEDEDED)
    let look = Look(leg: suit, arm: suit)
    heroLegs(c, p, look)
    drawBody(c, look)
    c.pattern(17, 19, [
        ".....WWWWWWWWWWWW.....",
        "...WWWWWWWWWWWWWWWW...",
        "..WWRRRWWWWWWWWRRRWW..",
        ".WWWWWWWWWWWWWWWWWWWW.",
        ".WWWWWWWWWWWWWWWWWWWW.",
        "WWGGGGGGGGGGGGGGGGGGWW",
        "WW..................WW",
        "WW..................WW",
        "W....................W",
    ], ["W": white, "R": C(0xD84A2A), "G": C(0x5A5A64)])
    c.rect(18, 33, 20, 5, suit)
    c.rect(21, 33, 2, 5, white); c.rect(33, 33, 2, 5, white)    // harness
    c.rect(18, 35, 20, 1, white)
    c.rect(25, 33, 6, 2, C(0x6A6E78))                           // chest box
    heroPistol(c, p)
}

/// L3-37: Lando's self-made droid, patched together from parts, fist up for droid rights.
private func drawL337(_ c: PixelCanvas, _ p: Pose) {
    let tan = C(0xCBB89A), tanDark = C(0x9E8C70), grey = C(0x5A5C64)
    let protest = !p.walking && Int(p.t * 0.8) % 2 == 0
    let look = Look(body: tan, shade: tanDark, leg: grey, arm: grey, eye: nil)
    heroLegs(c, p, look)
    drawBody(c, look, armRight: protest ? 6 : 0)
    c.rect(18, 30, 20, 1, tanDark)
    c.rect(20, 32, 5, 4, C(0xB06A3A))           // a rusty patch
    c.rect(30, 33, 4, 3, C(0x7A7E88))
    c.rect(24, 24, 2, 2, grey); c.rect(30, 24, 2, 2, grey)     // neck struts
    c.pattern(21, 16, [
        "...TTTTTTTT...",
        ".TTTTTTTTTTTT.",
        "TTTTTTTTTTTTTT",
        "TTTTTTTTTBBBTT",
        "TTTTTTTTBbbbBT",
        "TTTTTTTTBbbbBT",
        "TTTTTTTTTBBBTT",
        ".TTTTTTTTTTTT.",
    ], ["T": C(0xE8DCC4), "B": C(0x3A3A44), "b": C(0x6FC8FF)])
}

/// Mon Mothma: white robes to the floor, short auburn hair, a silver medallion.
private func drawMonMothma(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0xF0EEE6), robeShade = C(0xD2D0C8)
    c.oy += p.breathe
    drawSkirt(c, robe, robeShade)
    var look = Look(arm: robe)
    look.legs = false
    drawBody(c, look)
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHH..............HHH",
        "HH................HH",
    ], ["H": C(0x9A5A30)])
    c.rect(18, 33, 20, 5, robe)
    c.rect(37, 33, 1, 5, robeShade)
    c.rect(26, 34, 4, 2, C(0xC8CCD4))
}

/// Padmé Amidala, as at Geonosis: white suit, dark hair in a bun, a pistol.
private func drawPadme(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xF2F0EA), hair = C(0x4A2A1A)
    let look = Look(leg: suit, arm: suit)
    heroLegs(c, p, look)
    drawBody(c, look)
    c.pattern(18, 22, ["...HHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHH", "HH..............HH"], ["H": hair])
    c.pattern(13, 22, [".HHH.", "HHHHH", "HHHHH", ".HHH."], ["H": hair])      // the bun at the back
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, C(0xD4D2CC))
    c.rect(18, 36, 20, 1, C(0x6A5A4A))
    heroPistol(c, p)
}

/// Admiral Ackbar: a Mon Calamari, salmon dome and big side eyes, in his white admiral's uniform.
private func drawAckbar(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC9724A), shade = C(0xA0583A), uniform = C(0xEDECE6)
    let look = Look(body: skin, shade: shade, leg: C(0xD8D6CE), arm: uniform, eye: nil)
    heroLegs(c, p, look)
    drawBody(c, look)
    c.pattern(17, 17, [
        ".......SSSSSSSS.......",
        ".....SSSSSSSSSSSS.....",
        "....SSSSSSSSSSSSSS....",
        "...SSSSsSSSSSSSSSSS...",
        "...SSSSSSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSS..",
        "..SSSSSSSSSSSSSSSSSS..",
        ".SSSSSSSSSSSSSSSSSSSS.",
        ".SSSSSSSSSSSSSSSSSSSS.",
    ], ["S": skin, "s": C(0xE0946A)])
    let look2 = sin(p.t * 1.3) > 0.7 ? 1 : 2                   // the eyes swivel
    for ex in [15, 36] {
        c.pattern(ex, 25, [".EEE.", "EEEEE", "EEEEE", "EEEEE", ".EEE."], ["E": C(0xE0962E)])
        c.px(ex + look2 + 1, 27, C(0x2A1A10))
    }
    c.rect(24, 31, 8, 1, shade)                 // whiskers
    c.rect(18, 33, 20, 5, uniform)
    c.rect(18, 33, 20, 1, C(0xC8C6BE))
    c.px(21, 35, C(0xD84A2A)); c.px(22, 35, C(0x3A6ED8)); c.px(23, 35, C(0xE0B84A))
}
