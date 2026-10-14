import Foundation

// Heroes: the companions from the robot dog to the Time Agent. Clawd in costume like everyone else (K-Canine is Clawd
// inside a boxy robot dog, its casing Clawd orange). Most of them don't fight: they run, point and cheer.

let doctorHeroes5: [DoctorHero: Persona] = [
    .kCanine: Persona(name: "K-Canine", weapon: .blaster, motion: .hover, shot: .beam(core: C(0xFFE8E0), glow: C(0xFF2A2A)),
                  armoured: true, canSit: false, muzzle: (50, 28), handGun: false, bulk: 8, headTop: 19,
                  callout: "Affirmative",
                  draw: drawKCanine),
    .romanah: Persona(name: "Romanah", headTop: 20,
                  draw: drawRomanah),
    .nyssa: Persona(name: "Nyssa of Trakken", headTop: 20,
                  draw: drawNyssa),
    .tegan: Persona(name: "Tegan Jovanko", headTop: 18, signature: 2.6, callout: "Brave heart!",
                  draw: drawTegan),
    .pery: Persona(name: "Pery Brown", headTop: 17,
                  draw: drawPery),
    .mel: Persona(name: "Mel Shrub", headTop: 16, signature: 2.2,
                  draw: drawMel),
    .ace: Persona(name: "Ace", weapon: .blaster, shot: .thrown(C(0xE04A2A)), muzzle: (41, 30), headTop: 20, signature: 2.4,
                  draw: drawAce),
    .rose: Persona(name: "Rose Tiler", headTop: 20, signature: 3.2,
                  draw: drawRose),
    .jack: Persona(name: "Captain Jack Harkless", weapon: .blaster, muzzle: (47, 32), headTop: 20, signature: 3.4,
                  draw: drawJack),
]

// MARK: - Shared bits

/// A companion's right arm, `sleeve` over a Clawd-orange hand: up and waving while cheering or waiting for you,
/// pointing ahead while busy, at the side (the body's own nub) otherwise.
private func drawCompanionArm(_ c: PixelCanvas, _ p: Pose, sleeve: Px) {
    if p.cheering || p.ready {
        let wave = p.ready && Int(p.t * 6) % 2 == 0 ? 1 : 0
        c.rect(38 + wave, 25, 3, 8, sleeve); c.rect(38 + wave, 23, 3, 2, clawdOrange)
    } else if !p.resting && !p.walking && !p.hit {
        c.rect(38, 32, 5, 2, sleeve); c.rect(43, 32, 2, 2, clawdOrange)
    }
}

/// A skirt over the top of the legs, flaring a pixel every two rows; `pleats` in a darker shade.
private func drawSkirt(_ c: PixelCanvas, _ col: Px, _ dark: Px, pleats: Bool = false) {
    for y in 36...39 {
        let k = (y - 36) / 2
        c.rect(18 - k, y, 20 + 2 * k, 1, col); c.px(37 + k, y, dark)
    }
    if pleats { for x in stride(from: 19, to: 37, by: 3) { c.rect(x, 37, 1, 3, dark) } }
}

/// A small pixel heart, its top-left at (x, y).
private func drawHeart(_ c: PixelCanvas, x: Int, y: Int, _ col: Px) {
    c.pattern(x, y, [".R.R.", "RRRRR", "RRRRR", ".RRR.", "..R.."], ["R": col])
}

// MARK: - K-Canine

/// K-Canine: Clawd inside a boxy robot dog, the casing Clawd orange. A long low body with a grey side panel of
/// blinking lights, the head pushed forward with a grey snout and grille, two ear sensors that twitch, a tail antenna
/// that wags, and a tartan collar with a brass tag. It glides low (never walks) and fires a red laser from its nose.
private func drawKCanine(_ c: PixelCanvas, _ p: Pose) {
    let casing = clawdOrange, shade = clawdShade, light = C(0xE8957A)
    let metal = C(0x5A5E68), metalLight = C(0x9AA0AC), screen = C(0x1E2A24)
    let firing = p.fire.map { frac($0.t / p.firePeriod) < 0.4 } ?? false
    let wag = p.walking || p.cheering || p.ready ? Int(p.t * 8) % 2 : 0

    // The tail antenna, from the back of the casing up to its bulb.
    let tip = wag == 0 ? (x: 11, y: 21) : (x: 14, y: 20)
    for k in 0...6 {
        let f = Double(k) / 6
        c.px(17 + Int((Double(tip.x - 17) * f).rounded()), 28 + Int((Double(tip.y - 28) * f).rounded()), metalLight)
    }
    c.rect(tip.x - 1, tip.y - 1, 2, 2, metal); c.px(tip.x - 1, tip.y - 1, C(0xFF6A5A))

    // The base it glides on.
    c.rect(18, 39, 18, 2, metal); c.rect(18, 39, 18, 1, metalLight)
    c.rect(19, 41, 16, 1, C(0x2A2A30))
    // The body: a long box, with the side panel and its lights.
    c.rect(16, 28, 21, 11, casing); c.rect(16, 28, 21, 1, light)
    c.rect(36, 28, 1, 11, shade); c.rect(16, 38, 21, 1, shade)
    c.rect(19, 31, 13, 5, metal); c.rect(20, 32, 11, 3, screen)
    for i in 0..<5 {
        let on = noise(Int(p.lt * 3) * 7 + i) > 0.45
        let col = [C(0xFF4A3A), C(0x4AE07A), C(0xFFD24A), C(0x4AB8FF), C(0x4AE07A)][i]
        c.px(21 + i * 2, 33, on ? col : col.alpha(0.3))
    }
    for x in [17, 34] { c.px(x, 30, shade); c.px(x, 36, shade) }   // rivets

    c.oy += p.breathe
    // The tartan collar and its tag.
    c.pattern(34, 25, ["RGRY", "GGGG", "RGRR", "RGRY", "GGGG", "RGRR", "RGRR"],
              ["R": C(0xB8202A), "G": C(0x1E5A32), "Y": C(0xE8C84A)])
    c.rect(36, 32, 2, 2, C(0xD4AA4A))
    // The head, forward of the collar, with its snout, grille and the nose laser.
    c.rect(38, 22, 9, 9, casing); c.rect(38, 22, 9, 1, light); c.rect(38, 30, 9, 1, shade)
    for y in stride(from: 24, to: 30, by: 2) { c.rect(45, y, 2, 1, metal) }       // the grille
    c.rect(47, 26, 3, 4, metal); c.rect(47, 26, 3, 1, metalLight)
    c.px(50, 28, firing ? C(0xFFE0D8) : C(0xC82A2A))
    if firing { c.px(50, 27, C(0xFF2A2A, 0.5)); c.px(50, 29, C(0xFF2A2A, 0.5)) }
    // Its eye: Clawd's own, or a red X when it's hit.
    if p.hit {
        c.px(41, 24, C(0xFF4A3A)); c.px(43, 24, C(0xFF4A3A)); c.px(42, 25, C(0xFF4A3A))
        c.px(41, 26, C(0xFF4A3A)); c.px(43, 26, C(0xFF4A3A))
    } else {
        c.rect(41, 24, 2, 3, ink)
    }
    // The ear sensors: pricked up when it's on alert.
    let perk = firing || p.ready || p.cheering ? 1 : 0
    for x in [39, 43] {
        c.rect(x, 20 - perk, 2, 2 + perk, metal); c.px(x + 1, 19 - perk, metalLight)
    }
}

// MARK: - Romanah

/// Romanah: Clawd with long straight honey-blonde hair under a pink hair band, a white blouse and pleated pink
/// schoolgirl skirt, black shoes, and a very long cream, pink and violet striped scarf wound once round the neck, one
/// end hanging down the front and the other trailing out behind her (further when she's on the move).
private func drawRomanah(_ c: PixelCanvas, _ p: Pose) {
    let blouse = C(0xF4F0EA), blouseShade = C(0xD4CEC6), skirt = C(0xE89AB8), skirtDark = C(0xC0708E)
    let stripes = [C(0xF2E2C8), C(0xC8507A), C(0x7A4A8A), C(0xC8507A)]
    drawLegs(c, Look(), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x2A2A30), sole: C(0x16161B))
    c.oy += p.breathe

    // The scarf's long end, trailing behind.
    let lift = p.walking ? 1.2 : 0.4
    for i in 0..<14 {
        let y = 33 + i / 3 + Int((sin(p.t * 5 - Double(i) * 0.6) * Double(i) / 10 * lift - Double(i) / 6 * lift).rounded())
        c.rect(17 - i, y, 1, 2, stripes[(i / 2) % 4])
    }
    c.rect(4, 37 - Int(lift * 2), 1, 1, stripes[0])
    drawBody(c, Look(arm: blouse))
    drawSkirt(c, skirt, skirtDark, pleats: true)
    c.rect(18, 32, 20, 4, blouse); c.rect(37, 32, 1, 4, blouseShade)
    // Wound round the neck, the front end hanging down to the hem with a fringe.
    for x in 18...37 { c.px(x, 32, stripes[(x / 2) % 4]); c.px(x, 33, stripes[(x / 2 + 1) % 4]) }
    for y in 34...38 { c.rect(33, y, 2, 1, stripes[(y / 2) % 4]) }
    c.px(33, 39, stripes[0]); c.px(34, 40, stripes[0])
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..bbbbbbbbbbbbbbbbbbbb..",
        "..HHHHHHhHHHHHHHHhHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHhHHHHHHHHHHHHhHHH.",
        ".HHHHH............HHHHH.",
        ".HHHH..............HHHH.",
        ".HHH................HHH.",
        ".HhH................HHH.",
        ".HHH................HhH.",
        "HHHH................HHH.",
        "HHhH................HH..",
        "HHHH....................",
        "HhHH....................",
        ".HH.....................",
    ], ["H": C(0xE8C870), "h": C(0xC09A44), "b": C(0xD8507A)])
    drawCompanionArm(c, p, sleeve: blouse)
}

// MARK: - Nyssa

/// Nyssa of Trakken: Clawd with a cloud of dark brown curls to the shoulders and a little silver tiara with a pink
/// stone, in a burgundy velvet jacket and trousers (the velvet catching the light here and there), trimmed in gold,
/// and soft gold-brown boots.
private func drawNyssa(_ c: PixelCanvas, _ p: Pose) {
    let velvet = C(0x7A1E3A), velvetDark = C(0x5A1228), sheen = C(0xA8486A), gold = C(0xD4AA4A)
    let silver = C(0xD8DCE4)
    drawLegs(c, Look(leg: velvet), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x8A6A3A), sole: C(0x5A4426))
    c.oy += p.breathe
    drawBody(c, Look(arm: velvet))
    c.rect(18, 32, 20, 6, velvet); c.rect(37, 32, 1, 6, velvetDark); c.rect(18, 37, 20, 1, velvetDark)
    for (x, y) in [(20, 34), (21, 35), (26, 33), (31, 35), (32, 36), (35, 33)] { c.px(x, y, sheen) }
    c.rect(18, 32, 20, 1, gold)                                    // the collar trim
    c.rect(28, 33, 1, 5, gold)                                     // down the front
    c.rect(18, 37, 20, 1, C(0xA8843A))                             // and round the hem
    c.pattern(16, 20, [
        "......hHHhHHhHHhH.......",
        "....HhHHHhHHHhHHHhH.....",
        "...HHHhHHHHhHHHHhHHH....",
        "..hHHHHHhHHHHHhHHHHHh...",
        "..HHhHHHHHHhHHHHHhHHHH..",
        ".hHHHHhHHHHHHHhHHHHhHHh.",
        ".HHhHHHHHhHHHHHHhHHHHHH.",
        ".HHHHhH..........hHHHHh.",
        ".hHHHH............HHhHH.",
        ".HHhH..............hHHh.",
        "HhHHH..............HHhH.",
        "HHhHh...............hHH.",
        "hHHHH...............HH..",
        ".hHh....................",
    ], ["H": C(0x4A2A1A), "h": C(0x6A402A)])
    // The tiara.
    c.rect(20, 23, 16, 1, silver)
    for x in [22, 25, 31, 34] { c.px(x, 22, silver) }
    c.rect(27, 21, 2, 2, silver); c.px(27, 22, C(0xFF7AB8))
    if Int(p.lt * 2) % 5 == 0 { c.px(28, 20, white.alpha(0.8)) }
    drawCompanionArm(c, p, sleeve: velvet)
}

// MARK: - Tegan Jovanko

/// Tegan Jovanko: Clawd in her air-hostess uniform, a plum jacket and pencil skirt with gold buttons and a gold wing
/// badge, a white collar with a red neckerchief, plum heels, a dark brown bob and the little plum pillbox hat with its
/// gold badge. Signature: Brave heart: she puts a hand on her heart, a red heart rising over her, then throws a fist
/// in the air with a hop.
private func drawTegan(_ c: PixelCanvas, _ p: Pose) {
    let plum = C(0x5E2A5E), plumDark = C(0x421A42), plumLight = C(0x7A407A), gold = C(0xD4AA4A)
    let sig = p.signature
    let onHeart = sig.map { $0 > 0.06 && $0 < 0.46 } ?? false
    let punch = sig.map { $0 > 0.46 && $0 < 0.92 } ?? false
    if punch, let s = sig, s > 0.5 && s < 0.68 { c.oy -= 2 }
    drawLegs(c, Look(), step: p.step)
    drawTrainers(c, step: p.step, upper: plumDark, sole: plumDark)
    c.oy += p.breathe
    drawBody(c, Look(arm: plum))
    drawSkirt(c, plum, plumDark)
    c.rect(18, 32, 20, 5, plum); c.rect(37, 32, 1, 5, plumDark)
    c.rect(25, 32, 6, 2, white); c.rect(27, 32, 2, 3, C(0xC82A32))   // the collar and neckerchief
    c.rect(24, 32, 1, 5, plumDark); c.rect(31, 32, 1, 5, plumDark)   // the jacket's front
    for y in [34, 36] { c.px(23, y, gold); c.px(32, y, gold) }
    c.rect(19, 33, 3, 1, gold); c.px(20, 34, gold)                    // the wing badge
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHhHHHHHHHHhHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHhHHHHHHHHHhHHHHH.",
        ".HHHHHHHHH......HHHHHHH.",
        ".HHHH.............HHHHH.",
        ".HHH...............HHHH.",
        ".HHH...............HHHH.",
        ".HHhH..............HHHh.",
        "..HHH...............HH..",
    ], ["H": C(0x3A2418), "h": C(0x5A3A26)])
    c.pattern(21, 18, [
        "..PPPPPPPP..",
        ".PlPPPPPPPP.",
        "PPPPPPPPGPPP",
        "pppppppppppp",
    ], ["P": plum, "l": plumLight, "G": gold, "p": plumDark])

    if let s = sig, s > 0.08 && s < 0.95 {                            // the heart, rising and swelling
        let rise = Int((min(1, (s - 0.08) / 0.4) * 6).rounded())
        let a = s > 0.85 ? (0.95 - s) / 0.1 : 1
        drawHeart(c, x: 26, y: 13 - rise, C(0xE8283A).alpha(a))
        c.px(27, 14 - rise, C(0xFFB0B8).alpha(a))
    }
    if onHeart {
        c.rect(30, 33, 8, 2, plum); c.rect(28, 33, 2, 2, clawdOrange)
        return
    }
    if punch {
        c.rect(38, 24, 3, 9, plum); c.rect(38, 22, 3, 2, clawdOrange)
        return
    }
    drawCompanionArm(c, p, sleeve: plum)
}

// MARK: - Pery Brown

/// Pery Brown: Clawd with a great mane of chestnut curls, a pink vest top with a white stripe (bare arms), short blue
/// denim shorts, bare legs and white trainers.
private func drawPery(_ c: PixelCanvas, _ p: Pose) {
    let top = C(0xE85AA0), topDark = C(0xC03C80), denim = C(0x3A6AB0), denimDark = C(0x284E86)
    drawLegs(c, Look(), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xF2F0EA), sole: C(0xC8C4BC))
    c.oy += p.breathe
    drawBody(c, Look())
    c.rect(18, 32, 20, 3, top); c.rect(37, 32, 1, 3, topDark); c.rect(18, 33, 20, 1, C(0xF8E8F0))
    c.rect(18, 35, 20, 3, denim); c.rect(37, 35, 1, 3, denimDark); c.rect(18, 35, 20, 1, denimDark)
    if !seatedPose { c.rect(18, 38, 8, 1, denim); c.rect(30, 38, 8, 1, denim) }
    c.px(27, 36, C(0xD4AA4A))
    c.pattern(14, 17, [
        "........HhHHhHHhHH..........",
        "......HHHHHhHHHHHhHHH.......",
        "....hHHHhHHHHHhHHHHHhHH.....",
        "...HHHHHHHhHHHHHHHhHHHHH....",
        "..HhHHhHHHHHHhHHHHHHHhHHh...",
        "..HHHHHHHhHHHHHHhHHHHHHHHH..",
        ".hHHHhHHHHHHhHHHHHHhHHHHhH..",
        ".HHHHHHhHHHHHHHHhHHHHHHHHHh.",
        ".HHhHHHHHHHhHHHHHHHHHhHHHHH.",
        "hHHHHHhHHHHHHHHHhHHHHHHHhHH.",
        "HHHhHHH.hHH.H.HhH.HHHHhHHHH.",
        "HhHHHH..............HHHHhH..",
        ".HHHhH...............HhHHH..",
        ".HhHH................HHHhH..",
        "..HHH................HhHH...",
        "..hH..................HH....",
    ], ["H": C(0x6A3A20), "h": C(0x8E5432)])
    drawCompanionArm(c, p, sleeve: clawdOrange)
}

// MARK: - Mel Shrub

/// Mel Shrub: Clawd under a big round perm of bright red curls, in a candy-striped blouse (pink, white and mint) with
/// puffed sleeves and a wide white collar, white leggings and pink flats. Signature: she screams: eyes wide, mouth
/// open, both hands up by her face, her curls shaking and the scream ringing out in front of her.
private func drawMel(_ c: PixelCanvas, _ p: Pose) {
    let pink = C(0xF0A0C0), mint = C(0xA8E8C8), blouse = C(0xFAF6F0), legging = C(0xF2F0EA)
    let screaming = p.signature.map { $0 > 0.1 && $0 < 0.88 } ?? false
    let shake = screaming && Int(p.t * 30) % 2 == 0 ? 1 : 0
    drawLegs(c, Look(leg: legging), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xE8709A), sole: C(0xC0507A))
    c.oy += p.breathe
    c.ox += shake
    drawBody(c, Look(arm: pink, eye: screaming ? nil : ink))
    for y in 32...37 { c.rect(18, y, 20, 1, [pink, blouse, mint, blouse][(y - 32) % 4]) }
    c.rect(37, 32, 1, 6, C(0xC8B8C0))
    c.rect(22, 32, 12, 1, blouse); c.px(21, 33, blouse); c.px(34, 33, blouse)   // the wide collar
    c.rect(14, 32, 4, 4, pink); c.rect(14, 33, 4, 1, blouse)                     // the puffed sleeve
    if screaming {
        c.rect(22, 28, 2, 4, ink); c.rect(32, 28, 2, 4, ink)                     // eyes wide
        c.pattern(26, 32, [".KK.", "KRRK", "KRRK", ".KK."], ["K": ink, "R": C(0xC83A4A)])
    }
    c.oy -= screaming ? 1 : 0
    c.pattern(15, 16, [
        ".......RrRRrRRrR.........",
        ".....rRRRrRRRRrRRr.......",
        "...RRrRRRRRrRRRRRrRR.....",
        "..rRRRRrRRRRRrRRRRRRr....",
        ".RRRrRRRRRrRRRRRRrRRRR...",
        ".RrRRRRRrRRRRRrRRRRRrRR..",
        "rRRRRrRRRRRRrRRRRRrRRRRr.",
        "RRrRRRRRrRRRRRRrRRRRRrRR.",
        "RRRRRrRRRRRRrRRRRRRRRRrR.",
        "RrRRRRRRRrRRRRRRRrRRRRRR.",
        ".RRRrRRrRRRRrRRRRRRrRRRR.",
        ".RRRRRR.rR.R..rR.RRRrRRR.",
        ".RrRR...............RRrR.",
        "..RRR...............RRR..",
        "..rR.................Rr..",
    ], ["R": C(0xB8281E), "r": C(0xE0583A)])
    c.oy += screaming ? 1 : 0
    if screaming {
        c.rect(38, 26, 3, 7, pink); c.rect(38, 24, 3, 2, clawdOrange)            // hands up by her face
        c.rect(15, 26, 3, 7, pink); c.rect(15, 24, 3, 2, clawdOrange)
        c.ox -= shake
        let ring = Int(p.t * 10) % 3
        for i in 0..<3 {
            let a = i == ring ? 1.0 : 0.45, x = 43 + i * 3
            c.rect(x, 27 - i, 1, 2, white.alpha(a)); c.rect(x + 1, 31, 2, 1, white.alpha(a))
            c.rect(x, 34 + i, 1, 2, white.alpha(a))
        }
        return
    }
    c.ox -= shake
    drawCompanionArm(c, p, sleeve: pink)
}

// MARK: - Ace

/// Ace: Clawd in a black satin bomber jacket covered in badges, black leggings and Doc Martens, dark brown hair
/// scraped back into a ponytail that swings as she runs. She lobs cans of Nitro-9, one ready in her fist (gone just
/// after she's thrown it). Signature: she pulls out her baseball bat, winds it back over her shoulder and swings it
/// through with a crackle at the end.
private func drawAce(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x1E1E26), jacketDark = C(0x101016), jacketLight = C(0x3A3A48), rib = C(0x4A4A56)
    let hair = C(0x3A2214), hairLight = C(0x5A3622)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x2A1414), sole: C(0x3A2A1E))
    c.oy += p.breathe
    // The ponytail, behind; it swings while she runs.
    let swing = p.walking ? (p.step == 0 ? 1 : -1) : 0
    c.pattern(12, 23 + swing, ["..HHH", ".HHhH", "HHHH.", "HhH..", "HH...", "H...."], ["H": hair, "h": hairLight])
    drawBody(c, Look(arm: jacket))
    c.rect(18, 32, 20, 6, jacket); c.rect(37, 32, 1, 6, jacketDark)
    c.rect(18, 37, 20, 1, rib); c.rect(18, 32, 20, 1, jacketLight)
    c.rect(28, 33, 1, 4, C(0x9A9EA8))                               // the zip
    for (x, y, col) in [(20, 34, C(0xE04A3A)), (24, 35, C(0xFFD24A)), (33, 34, C(0x4AB8FF)), (35, 36, white),
                        (31, 33, C(0xFF7AC8)), (22, 36, C(0x4AE07A))] {
        c.px(x, y, col)
    }
    c.rect(19, 35, 2, 2, C(0xE8E0D0)); c.px(19, 35, C(0xE04A3A))    // a round badge
    c.pattern(16, 20, [
        ".....HHHHHHHHHHH........",
        "...HHHHHHHHHHHHHHH......",
        "..HHHhHHHHHHHHhHHHH.....",
        ".HHHHHHHHHHHHHHHHHHHH...",
        ".HHhHHHHHHhHHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHhHHHHHHHHHHhHHHHH.",
        ".HHHHH...........HHHHHH.",
        "..HHH..............HHHH.",
        "...H...............HHH..",
    ], ["H": hair, "h": hairLight])

    if let s = p.signature {
        // The bat: down by her side, wound back over the shoulder, swung through and lowered.
        let ease = { (u: Double) -> Double in let v = min(1, max(0, u)); return v * v * (3 - 2 * v) }
        let angle: Double
        if s < 0.1 { angle = 70 }
        else if s < 0.4 { angle = 70 - 230 * ease((s - 0.1) / 0.3) }
        else if s < 0.5 { let u = (s - 0.4) / 0.1; angle = -160 + 190 * (1 - pow(1 - u, 3)) }
        else if s < 0.75 { angle = 30 }
        else { angle = 30 + 40 * ease((s - 0.75) / 0.25) }
        let hx = 40.0, hy = 33.0 - (angle < -60 ? 4 : 0)
        let r = angle * .pi / 180
        if s > 0.4 && s < 0.5 {
            for back in [30.0, 60.0] {
                let rb = (angle - back) * .pi / 180
                c.glowLine(hx, hy, hx + cos(rb) * 13, hy + sin(rb) * 13, core: C(0xC8E4FF, 0.4), glow: C(0x6AB8FF, 0.3),
                           coreR: 0.6, glowR: 1.6, strength: 0.6)
            }
        }
        c.glowLine(hx + cos(r) * 2, hy + sin(r) * 2, hx + cos(r) * 13, hy + sin(r) * 13,
                   core: C(0xD8DCE4), glow: C(0x6AB8FF, s > 0.4 && s < 0.75 ? 0.7 : 0.15), coreR: 0.9, glowR: 1.7)
        c.glowLine(hx, hy, hx + cos(r) * 3, hy + sin(r) * 3, core: C(0x2A2A30), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
        if s > 0.48 && s < 0.7 { drawSparks(c, x: hx + cos(r) * 13, y: hy + sin(r) * 13, t: p.t, size: 3) }
        c.rect(38, Int(hy) - 1, 3, 3, jacket)
        return
    }
    // The can of Nitro-9 in her fist; gone for a moment just after she throws it.
    guard p.recoil == 0 else { return }
    c.oy += p.gunY
    c.pattern(39, 29, ["sSs", "RRR", "RWR", "RRR"], ["s": C(0x9AA0AC), "S": C(0xD8DCE4), "R": C(0xD8382A), "W": C(0xF2E8D0)])
    c.rect(38, 32, 3, 2, clawdOrange)
}

// MARK: - Rose Tiler

/// Rose Tiler: Clawd with shoulder-length blonde hair (dark at the roots), a pink hoodie with its hood bunched behind
/// her neck, its drawstrings and a pocket, blue jeans and white trainers. Signature: Bad Wolf: the vortex fills her,
/// a golden glow swelling round her, her eyes and hair turning gold, gold motes wheeling about her as she rises off the
/// ground, then it all fades.
private func drawRose(_ c: PixelCanvas, _ p: Pose) {
    let hoodie = C(0xD8487A), hoodieDark = C(0xB0305E), denim = C(0x3A5A8A), gold = C(0xFFD25A)
    let s = p.signature
    let glow = s.map { u -> Double in u < 0.08 || u > 0.94 ? 0 : min(1, (u - 0.08) / 0.2, (0.94 - u) / 0.15) } ?? 0
    let lift = Int((glow * 3).rounded())

    // The vortex behind her: a golden haze, and the motes that wheel round the back.
    if glow > 0 {
        for dy in -16...12 {
            for dx in -16...16 {
                let d = (Double(dx * dx) / 256 + Double(dy * dy) / 196).squareRoot()
                guard d < 1 else { continue }
                let a = (1 - d).squareRoot() * 0.6 * glow * (0.8 + 0.2 * sin(p.t * 6 + Double(dx + dy) * 0.5))
                c.px(28 + dx, 31 + dy - lift, C(0xFFE27A).alpha(((a * 5).rounded(.up) / 5)))
            }
        }
    }
    let motes = (0..<12).map { i -> (x: Int, y: Int, front: Bool) in
        let a = p.t * 3 + Double(i) * .pi / 6
        return (28 + Int((cos(a) * 17).rounded()), 30 - lift + Int((sin(a) * 6).rounded()) - (i % 3) * 3, sin(a) > 0)
    }
    if glow > 0 { for m in motes where !m.front { c.px(m.x, m.y, gold.alpha(0.6 * glow)) } }

    c.oy -= lift
    drawLegs(c, Look(leg: denim), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xF2F0EA), sole: C(0xC8C4BC))
    c.oy += p.breathe
    c.pattern(15, 29, ["..HH", ".HHH", "HHHH", "HHHh", ".HHh"], ["H": hoodie, "h": hoodieDark])   // the hood
    drawBody(c, Look(arm: hoodie, eye: glow > 0.5 ? gold : ink))
    c.rect(18, 32, 20, 6, hoodie); c.rect(37, 32, 1, 6, hoodieDark); c.rect(18, 37, 20, 1, hoodieDark)
    c.rect(22, 36, 12, 1, hoodieDark); c.px(22, 35, hoodieDark); c.px(33, 35, hoodieDark)   // the pocket
    c.px(25, 33, C(0xF08AAE)); c.px(30, 33, C(0xF08AAE))          // the drawstrings
    let hair = lerp(C(0xF0D890), C(0xFFF0A0), glow), roots = lerp(C(0x9A7A4A), C(0xFFD25A), glow)
    c.pattern(16, 20, [
        "......rrrrrrrrrrrr......",
        "....HHHHHHrrHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHhHHHHHHHHHHhHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHhHHHHHHHHHHhHHHH.",
        ".HHHHH............HHHHH.",
        ".HHHH..............HHHH.",
        ".HHH................HHH.",
        ".HhH................HHH.",
        ".HHH................HhH.",
        "HHHH................HHH.",
        "HHH.....................",
    ], ["H": hair, "h": lerp(C(0xC8A858), C(0xFFD25A), glow), "r": roots])
    if glow > 0.5 {                                                   // the eyes alight
        c.px(21, 30, gold.alpha(0.5)); c.px(24, 30, gold.alpha(0.5)); c.px(31, 30, gold.alpha(0.5)); c.px(34, 30, gold.alpha(0.5))
    }
    if glow > 0 {
        c.rect(38, 26, 3, 7, hoodie); c.rect(38, 24, 3, 2, clawdOrange)   // a hand raised to the vortex
        c.rect(15, 26, 3, 7, hoodie); c.rect(15, 24, 3, 2, clawdOrange)
        c.oy -= p.breathe; c.oy += lift
        for m in motes where m.front { c.px(m.x, m.y, gold.alpha(glow)); c.px(m.x, m.y - 1, white.alpha(0.5 * glow)) }
        for i in 0..<4 {                                              // motes rising off her
            let f = frac(p.t * 0.8 + Double(i) / 4)
            c.px(20 + i * 5, 26 - lift - Int(f * 12), gold.alpha((1 - f) * glow))
        }
        return
    }
    drawCompanionArm(c, p, sleeve: hoodie)
}

// MARK: - Captain Jack Harkless

/// Captain Jack Harkless: Clawd in a long navy wartime greatcoat (collar up, double row of brass buttons, the belt
/// and buckle, its tails behind his legs) over a blue shirt and braces, with a swept-up brown quiff and a revolver in
/// his hand. Signature: he drops dead, flat on his back with crosses for eyes, lies there a moment, then gasps back to
/// life and springs up.
private func drawJack(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.1, s < 0.72 else {
        drawJackStanding(c, p, gasp: p.signature.map { $0 >= 0.72 && $0 < 0.86 } ?? false)
        return
    }
    // Toppling over, lying dead, then the gasp that sits him straight back up.
    var q = p
    q.signature = nil
    let fig = PixelCanvas(Sprite.width, Sprite.height)
    drawJackStanding(fig, q, dead: s > 0.16 && s < 0.66, gasp: s >= 0.66)
    let k: Double
    if s < 0.18 { let u = (s - 0.1) / 0.08; k = u * u }
    else if s < 0.66 { k = 1 }
    else { k = 1 - (s - 0.66) / 0.06 }
    let flat = fig.rotated(-90 * k, about: (28, 43), into: Sprite.width, Sprite.height, at: (28 + 8 * k, 43 - 13 * k))
    c.paste(flat)
    if s >= 0.62 && s < 0.66 {                                        // a twitch before he comes round
        c.px(10, 28, white.alpha(0.6))
    }
}

/// Jack upright (also drawn into a separate canvas and laid flat for his signature). `dead`: crosses for eyes and the
/// revolver dropped; `gasp`: eyes wide, mouth open, a jolt of shock lines above his head.
private func drawJackStanding(_ c: PixelCanvas, _ p: Pose, dead: Bool = false, gasp: Bool = false) {
    let coat = C(0x2E3A54), coatDark = C(0x1E2840), coatLight = C(0x46546E), brass = C(0xD4AA4A)
    let shirt = C(0x8AA8C8), braces = C(0x6A2A2A)
    if !seatedPose {
        c.rect(16, 36, 23, 5, coatDark)
        c.rect(16, 40, 23, 1, coatDark.alpha(0.8))
    }
    drawLegs(c, Look(leg: C(0x2A2A30)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0x1A1A1E), sole: C(0x101014))
    c.oy += p.breathe
    if gasp { c.oy -= 1 }
    drawBody(c, Look(arm: coat, eye: dead ? nil : ink))
    c.rect(18, 32, 20, 6, coat); c.rect(37, 32, 1, 6, coatDark)
    c.rect(26, 32, 4, 4, shirt); c.px(26, 33, braces); c.px(29, 33, braces); c.px(26, 34, braces); c.px(29, 34, braces)
    c.rect(24, 32, 2, 4, coatLight); c.rect(30, 32, 2, 4, coatLight)  // the lapels
    for y in [33, 35] { c.px(22, y, brass); c.px(33, y, brass) }
    c.rect(18, 36, 20, 1, coatDark); c.rect(27, 36, 2, 1, brass)      // the belt
    c.rect(18, 30, 3, 3, coat); c.rect(35, 30, 3, 3, coat)            // the collar, turned up
    c.px(18, 30, coatLight); c.px(37, 30, coatDark)
    c.pattern(17, 20, [
        "...........hHHHH......",
        "......HHHHHHHHHHHHH...",
        "....HHHHHHhHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHHhHHHHHHHHHhHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHH",
        ".HHHHH...........HHHHH",
        ".HHH...............HHH",
        ".HH.................HH",
    ], ["H": C(0x5A3A22), "h": C(0x7A5232)])
    if dead {
        for x0 in [22, 32] {
            c.px(x0, 29, ink); c.px(x0 + 1, 30, ink); c.px(x0 + 2, 31, ink)
            c.px(x0 + 2, 29, ink); c.px(x0, 31, ink)
        }
        c.rect(38, 33, 3, 3, coat)
        return
    }
    if gasp {
        c.rect(22, 28, 2, 4, ink); c.rect(32, 28, 2, 4, ink)
        c.rect(27, 31, 2, 2, ink)
        for (x, y) in [(22, 16), (28, 14), (34, 16)] { c.rect(x, y, 1, 3, white) }
        c.px(20, 18, white.alpha(0.6)); c.px(36, 18, white.alpha(0.6))
    }
    c.oy += p.gunY
    c.rect(38, 32, 3, 3, coat); c.rect(40, 32, 1, 2, clawdOrange)
    drawPistol(c, x: 40, y: 31, body: C(0x3A3A40), trim: C(0x9AA0AC))
}
