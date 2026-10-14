import Foundation

// Villains: the monsters from the stone, the dark, the deep and the skin suits. Clawd in costume, or Clawd hidden inside
// the costume: the Angle is Clawd turned to stone, the Slitheem's skin suit is Clawd's orange, and there's a little
// orange face inside the Toclafayne's sphere.

let doctorVillains5: [DoctorVillain: Persona] = [
    .weepingAngle: Persona(name: "Weeping Angle", armoured: true, canSit: false, headTop: 9, fidgets: false,
                  draw: drawWeepingAngle),
    .silents: Persona(name: "The Silents", weapon: .lightning, magic: Magic(core: C(0xF0F6FF), glow: C(0x5A9AFF)),
                  pivot: (43, 33), headTop: 12,
                  draw: drawSilents),
    .odd: Persona(name: "The Odd", weapon: .lightning, magic: Magic(core: C(0xFFD8D0), glow: C(0xE8202A)),
                  pivot: (35, 32), headTop: 18,
                  draw: drawOdd),
    .zygone: Persona(name: "Zygone", weapon: .lightning, magic: Magic(core: C(0xFFF4C8), glow: C(0xFF8A2A)),
                  pivot: (45, 33), headTop: 14,
                  draw: drawZygone),
    .silurean: Persona(name: "Silurean", weapon: .blaster, shot: .energy(core: C(0xF4FFC0), glow: C(0x6AD02A)),
                  muzzle: (39, 32), handGun: false, headTop: 17,
                  draw: drawSilurean),
    .seaDevvil: Persona(name: "Sea Devvil", weapon: .blaster, shot: .energy(core: C(0xE8FFF4), glow: C(0x2AC8A0)),
                  muzzle: (49, 33), headTop: 19,
                  draw: drawSeaDevvil),
    .slitheem: Persona(name: "Slitheem", weapon: .saber, bulk: 3, headTop: 5, signature: 3.2,
                  draw: drawSlitheem),
    .sycorex: Persona(name: "Sycorex", weapon: .lightning, magic: Magic(core: C(0xE8F8FF), glow: C(0x3AA0FF)),
                  headTop: 13,
                  draw: drawSycorex),
    .vashtaNerado: Persona(name: "Vashta Nerado", headTop: 16, callout: "Hey, who turned the lights out?",
                  draw: drawVashtaNerado),
    .emptyKid: Persona(name: "The Empty Kid", headTop: 20, callout: "Are you my mummy?",
                  draw: drawEmptyKid),
    .toclafayne: Persona(name: "Toclafayne", motion: .fly, canSit: false, headTop: 20,
                  draw: drawToclafayne),
]

private let clear = C(0x000000, 0)

// MARK: - Weeping Angle

/// The Weeping Angle: Clawd turned to grey stone, a weathered angel statue. Hair gathered in a bun, a long robe to the
/// ground, two great feathered wings folded up behind its back, cracks and lichen. At rest it hides its face, both hands
/// over its eyes. Whenever it's doing anything else (moving, fighting, hit, waiting for you) it has its claws out
/// and its fangs bared, its eyes hollow and furious. Bullets glance off. No fidgets: it never moves while watched.
private func drawWeepingAngle(_ c: PixelCanvas, _ p: Pose) {
    let stone = C(0x9C9B94), light = C(0xBEBDB4), dark = C(0x72716A), deep = C(0x4E4D48), lichen = C(0x7E8A62)
    let attacking = !p.resting || p.hit

    // The wings: the far one rising behind the head, the near one folded down the back.
    drawAngleWing(c, x: 13, y: 1, main: C(0x8A8982), edge: stone, feather: dark, line: deep)
    drawAngleWing(c, x: 1, y: 6, main: stone, edge: light, feather: dark, line: deep)

    // The robe, flaring to the ground (it glides; no legs show).
    for y in 33...43 {
        let k = (y - 33) / 3
        c.rect(18 - k, y, 20 + k * 2, 1, stone)
        c.px(18 - k, y, dark); c.px(37 + k, y, dark)
    }
    for x in [22, 27, 32] { c.rect(x, 36, 1, 7, dark) }                        // the folds
    c.rect(15, 43, 26, 1, dark)
    c.px(23, 40, lichen); c.px(24, 41, lichen); c.px(34, 39, lichen)
    c.oy += p.breathe
    drawBody(c, Look(body: light, shade: stone, arm: stone, eye: nil, legs: false))
    c.rect(18, 33, 20, 5, stone); c.rect(37, 33, 1, 5, dark)
    c.rect(18, 33, 20, 1, dark)                                                // the girdle
    for x in [22, 27, 32] { c.rect(x, 34, 1, 4, dark) }

    // Hair, swept back into a bun.
    c.pattern(16, 21, [
        "....DDDDDDDDDDDDD....",
        "..DDSSSDSSSSDSSSDD...",
        ".DSSSSSSSSSSSSSSSSD..",
        "DSSDSSSSDSSSSSDSSSSD.",
        "DSSD.............DSSD",
        "DSD...............DSD",
        ".D.................D.",
    ], ["S": dark, "D": deep])
    c.pattern(12, 21, [".DDD.", "DSSSD", "DSLSD", "DSSSD", ".DDD."], ["S": dark, "L": stone, "D": deep])   // the bun
    c.px(30, 26, deep); c.px(30, 27, deep); c.px(31, 28, deep)                // a crack down the brow

    if attacking {
        // Hollow eyes under furious brows, the mouth wide on its fangs.
        c.rect(22, 29, 2, 3, deep); c.rect(32, 29, 2, 3, deep)
        c.rect(21, 27, 2, 1, deep); c.rect(23, 28, 2, 1, deep)
        c.rect(33, 27, 2, 1, deep); c.rect(31, 28, 2, 1, deep)
        c.rect(25, 31, 8, 2, C(0x26251F))
        let fang = C(0xEAE8DC)
        c.px(25, 31, fang); c.px(26, 31, fang); c.px(31, 31, fang); c.px(32, 31, fang)
        c.px(26, 32, fang); c.px(31, 32, fang); c.px(28, 32, fang); c.px(29, 32, fang)
        // Both arms out, the stone fingers hooked into claws.
        c.rect(38, 31, 5, 3, stone); c.rect(38, 33, 5, 1, dark)
        c.pattern(43, 29, ["d..", "SSd", "SS.", "SSd", "d.."], ["S": light, "d": deep])
        c.rect(36, 27, 5, 2, dark)
        c.pattern(41, 25, ["d.", "Sd", "S.", "Sd"], ["S": stone, "d": deep])
    } else {
        // Hands over its eyes, the fingers spread a little, the head bowed.
        c.rect(16, 30, 3, 4, stone); c.rect(16, 33, 3, 1, dark)
        c.rect(36, 30, 3, 4, stone); c.rect(38, 30, 1, 4, dark)
        for x0 in [19, 30] {
            c.rect(x0, 27, 7, 5, stone)
            c.rect(x0, 31, 7, 1, dark)
            for k in [2, 4] { c.rect(x0 + k, 28, 1, 3, dark) }; c.rect(x0, 27, 7, 1, light)
        }
        c.rect(26, 32, 4, 1, dark)                                             // a sorrowful mouth
    }
}

/// One folded angel wing at (`x`, `y`): the leading edge up beside the head, long feathers stepping down the back.
private func drawAngleWing(_ c: PixelCanvas, x: Int, y: Int, main: Px, edge: Px, feather: Px, line: Px) {
    c.pattern(x, y, [
        "...............dd..",
        ".............dLLd..",
        "...........dLLLLd..",
        ".........dLLSSSSd..",
        ".......dLLSSSSSSd..",
        "......dLSSSSSSSSd..",
        ".....dLSSSSSSSSSd..",
        "....dLSSSSSSSSSSd..",
        "...dLSSSSSSSSSSSd..",
        "...dSSSSFSSSSSSSSd.",
        "..dSSSSFSSSSSSSSSd.",
        "..dSSSFSSSSFSSSSSd.",
        ".dSSSFSSSSFSSSSSSSd",
        ".dSSFSSSSFSSSSFSSSd",
        ".dSFSSSSFSSSSFSSSSd",
        "dSFSSSSFSSSSFSSSSSd",
        "dFSSSSFSSSSFSSSSSSd",
        "dSSSSFSSSSFSSSSSSSd",
        "dSSSFSSSSFSSSSSSSSd",
        "dSSFdSSSFSSSSFSSSSd",
        ".dFd.dSFSSSSFSSSSSd",
        ".dd..dFdSSSFSSSSSSd",
        ".....dd.dSFSSSSFSSd",
        "........dFdSSSFSSSd",
        "........dd.dSFSSSSd",
        "...........dFdSSSSd",
        "...........dd.dSFSd",
        "..............dFd..",
        "..............dd...",
    ], ["S": main, "L": edge, "F": feather, "d": line])
}

// MARK: - The Silents

/// The Silents: Clawd as a grey alien in a sharp black suit, white shirt and thin black tie. The head is a tall,
/// wrinkled, elongated skull of pale grey leather, the eyes deep black sockets and no mouth at all, just a puckered
/// chin. Long grey fingers. It fights with lightning from its fingertips.
private func drawSilents(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD6D2C6), skinShade = C(0xAAA69A), wrinkle = C(0x8C887E), suit = C(0x26262E), suitLight = C(0x34343C)
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 43 - (p.step >= 0 && ([19, 23, 31, 35].firstIndex(of: lx)! % 2 == p.step) ? 1 : 0), 2, 1, C(0x0E0E12)) } }
    c.oy += p.breathe
    let casting = p.zap != nil || p.ready || p.cheering
    let raise = casting ? p.armRaise : 0
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    // The suit, shirt and tie.
    c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, C(0x0E0E12))
    c.rect(25, 33, 6, 3, white); c.rect(27, 33, 2, 5, C(0x0E0E12))
    c.px(24, 33, suitLight); c.px(31, 33, suitLight); c.px(24, 34, suitLight); c.px(31, 34, suitLight)
    // The long skull, swelling up and back from the face.
    c.pattern(15, 8, [
        "........GGGGGGG.........",
        ".....GGGGGGGGGGGGG......",
        "...GGGGGGGWGGGGGGGGG....",
        "..GGGGWGGGGGGGGGGGGGG...",
        ".GGGGGGGGGGGGGWGGGGGGG..",
        ".GGGGGGGGWGGGGGGGGGGGGs.",
        "GGGWGGGGGGGGGGGGGGGGGGs.",
        "GGGGGGGGGGGGGGWGGGGGGGGs",
        "GGGGGGGWGGGGGGGGGGGGGGGs",
        "GGGGGGGGGGGGGGGGGGGGGGGs",
        ".GGGGGGGGGGGGGGGGGGGGGs.",
        ".GGGGWGGGGGGGGGGGWGGGGs.",
        "..GGGGGGGGGGGGGGGGGGGs..",
        "..GGGGGGGGGGGGGGGGGGGs..",
        "...GGGWGGGGGGGGWGGGGGs..",
        "...GGGGGGGGGGGGGGGGGGs..",
        "...GGGGGGGGGGGGGGGGGGs..",
        "...GGGGGGGGGGGGGGGGGGs..",
    ], ["G": skin, "W": wrinkle, "s": skinShade])
    // Deep sockets, the brow folding over them; the puckered chin where a mouth should be.
    c.rect(21, 28, 4, 4, C(0x2A2622)); c.rect(31, 28, 4, 4, C(0x2A2622))
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(20, 27, 6, 1, wrinkle); c.rect(30, 27, 6, 1, wrinkle)
    c.rect(26, 31, 4, 1, wrinkle); c.px(27, 32, wrinkle); c.px(28, 32, skinShade)
    c.rect(18, 31, 3, 2, suit); c.px(21, 32, suit); c.rect(35, 31, 3, 2, suit); c.px(34, 32, suit)   // the high collar
    // The long-fingered hands.
    c.rect(15, 33, 3, 3, suit); c.rect(15, 36, 2, 2, skin)
    c.rect(38, 32 - raise, 3, 3, suit)
    if casting {
        c.rect(41, 32 - raise, 2, 2, skin); c.px(43, 32 - raise, skin); c.px(43, 34 - raise, skin); c.px(42, 34 - raise, skinShade)
    } else {
        c.rect(39, 35, 2, 2, skin); c.px(39, 37, skinShade); c.px(40, 37, skin)
    }
}

// MARK: - The Odd

/// The Odd: Clawd as a gentle alien servant: a pale, bald domed head, a beard of pinkish tentacles hanging over the
/// front, a dark work suit, and the glowing translation ball held up on its cable. When it turns on you its eyes go red
/// and the red energy comes out of them.
private func drawOdd(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xDDD5C8), skinShade = C(0xB2AA9C), tent = C(0xC89C94), tentDark = C(0x946E68)
    let suit = C(0x34343A), suitDark = C(0x222226)
    drawLegs(c, Look(leg: suit), step: p.step)
    c.oy += p.breathe
    let angry = p.zap != nil || p.hit || p.ready || p.cheering
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    c.rect(18, 34, 20, 4, suit); c.rect(37, 34, 1, 4, suitDark)
    // The bald dome.
    c.pattern(18, 20, [
        "....DDDDDDDDDDDD....",
        "..DDDDDDDDDDDDDDDD..",
        ".DDDDhDDDDDDDDDDDDD.",
        "DDDDhDDDDDDDDDDDDDDs",
        "DDDDDDDDDDDDDDDDDDDs",
        "DDDDDDDDDDDDDDDDDDDs",
    ], ["D": skin, "h": white.alpha(0.6), "s": skinShade])
    c.rect(21, 26, 4, 1, skinShade); c.rect(31, 26, 4, 1, skinShade)            // heavy brows
    // The eyes: small and dark, red when it's turned.
    let eye = angry ? C(0xFF2A2A) : C(0x3A3438)
    c.rect(22, 28, 2, 2, eye); c.rect(32, 28, 2, 2, eye)
    if angry { c.px(22, 28, C(0xFFB0A0)); c.px(32, 28, C(0xFFB0A0)) }
    // The tentacle beard, swaying.
    for (i, x) in [20, 23, 26, 29, 32, 35].enumerated() {
        let len = [6, 8, 7, 8, 6, 5][i]
        let sway = sin(p.lt * 3 + Double(i) * 1.3)
        for k in 0..<len {
            let off = k >= len - 3 ? Int((sway * Double(k - len + 4) * 0.6).rounded()) : 0
            c.rect(x + off, 30 + k, 2, 1, k == len - 1 ? tentDark : tent)
            c.px(x + off + (i % 2), 30 + k, k % 2 == 0 ? tent : tentDark)
        }
    }
    // The far arm, and the near one holding up the translation ball on its cable.
    c.rect(15, 33, 3, 3, suit)
    c.rect(38, 33, 3, 3, suit)
    let glow = angry ? C(0xFFB8A8) : C(0xE8F4FF)
    c.rect(39, 30, 4, 3, glow); c.rect(40, 29, 2, 1, glow); c.rect(40, 33, 2, 1, glow)
    c.px(42, 31, C(0x9AB8D8)); c.px(39, 30, white)
    c.px(38, 31, C(0x5A5A62)); c.px(37, 31, C(0x5A5A62)); c.px(36, 32, C(0x5A5A62))
}

// MARK: - Zygone

/// The Zygone: Clawd as a hulking red-orange shapeshifter covered all over in suckers: a great domed head with a ridge
/// of them down the middle, small sunken eyes, a lipless slit of a mouth. A venomous stinger sprouts from its palm;
/// that's what its sting comes out of.
private func drawZygone(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC4532E), shade = C(0x96391E), sucker = C(0xE8905E), hole = C(0x7A2A16), sting = C(0xF0D8A0)
    drawLegs(c, Look(leg: skin), step: p.step)
    c.oy += p.breathe
    let stinging = p.zap != nil || p.ready || p.cheering
    let raise = stinging ? p.armRaise : 0
    drawBody(c, Look(body: skin, shade: shade, arm: skin, eye: nil), armRight: raise)
    // The domed head, wider than Clawd, and its ridge.
    c.pattern(16, 14, [
        "........RRRR..........",
        "......SSRRRRSS........",
        "....SSSSRRRRSSSS......",
        "...SSSSSRRRRSSSSSS....",
        "..SSSSSSRRRRSSSSSSS...",
        ".SSSSSSSRRRRSSSSSSSS..",
        ".SSSSSSSRRRRSSSSSSSSd.",
        "SSSSSSSSRRRRSSSSSSSSdd",
        "SSSSSSSSRRRRSSSSSSSSdd",
        "SSSSSSSSRRRRSSSSSSSSdd",
        "SSSSSSSSRRRRSSSSSSSSSd",
        "SSSSSSSSRRRRSSSSSSSSSd",
        "SSSSSSSSSSSSSSSSSSSSSd",
    ], ["S": skin, "R": shade, "d": shade])
    // Suckers everywhere: on the ridge, the head, the body.
    func suck(_ x: Int, _ y: Int) {
        c.rect(x, y + 1, 3, 1, sucker); c.rect(x + 1, y, 1, 3, sucker); c.px(x + 1, y + 1, hole)
    }
    for y in [15, 19, 23] { suck(24, y) }
    for (x, y) in [(19, 19), (31, 17), (18, 24), (34, 22), (29, 21), (35, 27), (20, 34), (25, 34), (30, 34),
                   (34, 33)] { suck(x, y) }
    // Sunken little eyes and a slit mouth.
    c.rect(21, 28, 4, 3, shade); c.rect(31, 28, 4, 3, shade)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(26, 32, 6, 1, hole)
    // The far arm, and the near hand with its stinger.
    suck(15, 34)
    if stinging {
        c.rect(41, 33 - raise, 2, 1, sting); c.rect(43, 33 - raise, 2, 1, sting); c.px(45, 33 - raise, white)
        c.px(42, 32 - raise, sting)
    } else {
        c.px(40, 36, sting); c.px(40, 37, sting)
    }
}

// MARK: - Silurean

/// The Silurean: Clawd as a green reptile person: scaled skin, a fan of fins sweeping back off the head, a glowing
/// third eye on the brow, yellow slit eyes and a wide lipless mouth, in dark bronze-trimmed armour. It spits venom from
/// its mouth (which gapes as it does), the third eye flaring.
private func drawSilurean(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5A8C3A), dark = C(0x3C6226), scale = C(0x78AA4C), fin = C(0x8AB85A), finDark = C(0x4A7430)
    let armour = C(0x3A3028), bronze = C(0xA8823A)
    drawLegs(c, Look(leg: armour), step: p.step)
    c.oy += p.breathe
    let spitting = p.fire.map { frac($0.t / p.firePeriod) < 0.3 } ?? false
    drawBody(c, Look(body: green, shade: dark, arm: green, eye: nil))
    // Scales.
    for (x, y) in [(20, 27), (25, 28), (29, 27), (35, 28), (19, 31), (27, 30), (36, 31)] { c.px(x, y, scale) }
    // The fins: a fan sweeping up and back over the head.
    c.pattern(13, 15, [
        "..........F.....F.......",
        ".......F..FF...FF..F....",
        "....F..FF.FFF.FFF.FF....",
        "....FF.FFFFFFFFFFFFF....",
        "..F.FFFFFFFFFFFFFFFF....",
        "..FFFFFFffffffffffffFF..",
        "...FFFfGGGGGGGGGGGGGGfF.",
        ".FFFFfGGGGGGGGGGGGGGGGd.",
        "..FFFfGGGGGGGGGGGGGGGGd.",
        "...FFfGGGGGGGGGGGGGGGGd.",
        ".....FGGGGGGGGGGGGGGGGGd",
        "......F.................",
    ], ["F": fin, "f": finDark, "G": green, "d": dark])
    for x in stride(from: 20, to: 32, by: 3) { c.px(x, 18, finDark); c.px(x, 19, finDark) }
    // The third eye.
    let third = spitting ? C(0xFFF6A0) : C(0xD8A830)
    c.rect(27, 25, 2, 2, third); if spitting { c.px(27, 24, C(0xFFF6A0, 0.6)); c.px(28, 24, C(0xFFF6A0, 0.6)) }
    // Yellow slit eyes.
    c.rect(22, 29, 2, 3, C(0xE8C83A)); c.rect(32, 29, 2, 3, C(0xE8C83A))
    c.rect(23, 29, 1, 3, ink); c.rect(33, 29, 1, 3, ink)
    c.rect(21, 28, 3, 1, dark); c.rect(31, 28, 3, 1, dark)
    // The mouth, gaping as it spits.
    if spitting { c.rect(31, 32, 7, 2, C(0x2A1A1A)); c.px(37, 32, C(0xC8F07A)) }
    else { c.rect(30, 33, 8, 1, dark) }
    // Armour on the body, bronze-edged.
    c.rect(18, 34, 20, 4, armour); c.rect(18, 34, 20, 1, bronze); c.rect(26, 35, 4, 2, bronze)
    c.rect(15, 33, 3, 2, armour); c.rect(38, 33, 3, 2, armour)
}

// MARK: - Sea Devvil

/// The Sea Devvil: Clawd as a green turtle-man from the deep: a broad, ridged turtle head jutting forward to a hooked
/// beak, eyes on the sides, a string-mesh tunic over the scaly body, and a chunky heat gun, which fires a sea-green
/// bolt.
private func drawSeaDevvil(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4C7C52), dark = C(0x335838), light = C(0x6E9E6A), beak = C(0xC8BC6A), mesh = C(0x9AA8B8)
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 42 - (p.step >= 0 && [19, 23, 31, 35].firstIndex(of: lx)! % 2 == p.step ? 1 : 0), 2, 1, dark) } }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: dark, arm: green, eye: nil))
    // The turtle head: a ridged crown, the face jutting forward to the beak.
    c.pattern(17, 19, [
        "....LLLLLLLLLLL..........",
        "..LGGGGGGGGGGGGGLL.......",
        ".GGGGdGGGGdGGGGGGGGG.....",
        "GGGGGGGGGGGGGGGGGGGGGG...",
        "GGGdGGGGdGGGGdGGGGGGGGG..",
        "GGGGGGGGGGGGGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGGGGGGGGGGG",
        "....................GGGGGB",
        "....................GGGBBBB",
        "....................GGBBBBB",
        ".....................dBBBb.",
        "......................dBb..",
    ], ["G": green, "L": light, "d": dark, "B": beak, "b": C(0x5A6A3A)])
    c.rect(36, 31, 4, 1, dark)                                                 // the mouth line under the beak
    // Eyes set wide, ringed.
    c.rect(21, 28, 4, 4, light); c.rect(22, 29, 2, 2, ink)
    c.rect(31, 28, 4, 4, light); c.rect(32, 29, 2, 2, ink)
    // Scaly chest under the mesh tunic.
    c.rect(18, 32, 20, 6, dark)
    for y in 32...37 { for x in 18...37 where (x + y) % 3 == 0 || (x - y) % 3 == 0 { c.px(x, y, mesh) } }
    c.rect(18, 37, 20, 1, C(0x5A6878))
    // The far arm, and the heat gun in the near hand.
    c.rect(15, 33, 3, 3, green)
    let gy = 32 + p.gunY
    c.rect(38, gy + 2, 3, 3, green)
    c.pattern(39, gy, [
        ".MMMMMMMMM",
        "MMMLLLLMMM",
        "MMMMMMMMM.",
        "MM..MM....",
        "MM........",
    ], ["M": C(0x3A4248), "L": C(0x6AE0C0)])
}

// MARK: - Slitheem

/// The Slitheem: a huge green baby-faced alien bursting out of its human disguise. The skin suit is Clawd (orange,
/// with Clawd's eyes, in a straining grey business suit and tie), unzipped across the forehead, light leaking from the
/// zip; out of the top swells the enormous green head, huge black baby eyes and fat cheeks. A long green arm with three
/// black claws bursts from the sleeve to slash. Signature: it giggles, eyes squeezed shut and wobbling, then lets off
/// a fart, green puffs billowing out behind, and giggles some more.
private func drawSlitheem(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x86B444), greenDark = C(0x5E8A2C), greenLight = C(0xA8D068), suit = C(0x5A5E66), suitDark = C(0x40434A)
    let zip = C(0xD8DCE4), leak = C(0xC8F0FF), claw = C(0xDCD4BC)
    let sig = p.signature
    let giggle = sig.map { $0 < 0.4 || $0 > 0.75 } ?? false
    let fart = sig.map { $0 > 0.35 && $0 < 0.95 } ?? false
    if giggle { c.ox += Int(p.t * 14) % 2 == 0 ? 1 : 0 }

    if fart {
        // Green puffs billowing out behind, drifting up and thinning.
        let f = min(1, (sig! - 0.35) / 0.6)
        for i in 0..<3 {
            let k = min(1, max(0, (f - Double(i) * 0.15) / 0.6))
            guard k > 0 else { continue }
            let x = 13.0 - Double(i) * 3 - k * 5, y = 38.0 - Double(i) * 4 - k * 3
            let r = 1.5 + k * (2 + Double(i % 2))
            let col = C(0xA8D05A, 0.85 * (1 - k * 0.45))
            for yy in Int(y - r)...Int(y + r) {
                for xx in Int(x - r)...Int(x + r) {
                    let dx = Double(xx) + 0.5 - x, dy = Double(yy) + 0.5 - y
                    if dx * dx + dy * dy <= r * r { c.px(xx, yy, col) }
                }
            }
        }
    }

    // The suit trousers.
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 43 - (p.step >= 0 && [19, 23, 31, 35].firstIndex(of: lx)! % 2 == p.step ? 1 : 0), 2, 1, C(0x1E1E22)) } }
    c.oy += p.breathe
    drawBody(c, Look(arm: suit, eye: ink))
    // The business suit, buttons straining.
    c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, suitDark)
    c.rect(25, 33, 6, 2, C(0xEDE8DC)); c.rect(27, 33, 2, 5, C(0x2A3A6A))
    c.px(23, 35, suitDark); c.px(32, 35, suitDark)
    // The zip, open across the forehead, light leaking from it.
    c.rect(18, 26, 20, 1, zip)
    for x in stride(from: 19, to: 37, by: 2) { c.px(x, 27, zip) }
    c.rect(36, 27, 2, 2, C(0xA8ACB4))                                          // the zip pull
    if Int(p.lt * 6) % 3 == 0 { c.px(24, 27, leak); c.px(30, 27, leak) }
    // The giant green head swelling out of the top.
    for y in 5...25 {
        let dy = (Double(y) + 0.5 - 15.5) / 10.5
        let hw = Int((15.5 * (1 - dy * dy).squareRoot()).rounded())
        guard hw > 0 else { continue }
        c.rect(28 - hw, y, hw * 2, 1, y > 23 ? greenDark : green)
        c.px(27 + hw, y, greenDark); c.px(26 + hw, y, y > 8 ? greenDark : green)
    }
    c.rect(17, 8, 3, 1, greenLight); c.rect(16, 9, 2, 2, greenLight)              // the shine on its dome
    c.rect(18, 25, 3, 1, C(0xE8A090)); c.rect(35, 25, 3, 1, C(0xE8A090))      // the skin's peeled-back edges
    // Huge baby eyes (squeezed shut while it giggles), fat cheeks, a little mouth.
    if giggle {
        c.pattern(18, 14, ["K....K", ".K..K.", "..KK.."], ["K": ink]); c.pattern(30, 14, ["K....K", ".K..K.", "..KK.."], ["K": ink])
        c.rect(17, 19, 4, 2, C(0xF08AA0)); c.rect(33, 19, 4, 2, C(0xF08AA0))
        c.rect(25, 19, 5, 3, ink); c.rect(26, 21, 3, 1, C(0xE85A6A))
    } else {
        c.rect(17, 12, 6, 7, ink); c.rect(18, 11, 4, 9, ink); c.rect(18, 12, 2, 2, white); c.px(21, 17, white.alpha(0.5))
        c.rect(31, 12, 6, 7, ink); c.rect(32, 11, 4, 9, ink); c.rect(32, 12, 2, 2, white); c.px(35, 17, white.alpha(0.5))
        c.rect(26, 21, 3, 1, greenDark); c.rect(17, 20, 3, 1, C(0xB8D878)); c.rect(35, 20, 3, 1, C(0xB8D878))
    }
    // The far sleeve; the near arm burst out green, with its claws.
    c.rect(15, 33, 3, 3, suit); c.rect(14, 35, 3, 2, green)
    if let a = p.melee {
        let r = a * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
        let hx = Sprite.hand.x, hy = Sprite.hand.y
        for (i, ta) in p.trail.enumerated() {
            let tr = ta * .pi / 180
            c.glowLine(hx + cos(tr) * 4, hy + sin(tr) * 4, hx + cos(tr) * 11, hy + sin(tr) * 11,
                       core: white.alpha(0.3 / Double(i + 1)), glow: greenLight.alpha(0.3 / Double(i + 1)), coreR: 0.8, glowR: 2.2)
        }
        c.glowLine(38, 34, hx + ux * 2, hy + uy * 2, core: green, glow: clear, coreR: 1.4, glowR: 1.5)
        c.rect(Int(hx + ux * 2) - 1, Int(hy + uy * 2) - 1, 3, 3, green)
        for k in [-2.5, 0, 2.5] {
            let bx = hx + ux * 3 + nx * k, by = hy + uy * 3 + ny * k
            c.glowLine(bx, by, bx + ux * 7 - nx * 0.8, by + uy * 7 - ny * 0.8, core: claw, glow: clear, coreR: 0.35, glowR: 0.4)
        }
    } else {
        c.rect(38, 33, 3, 3, suit); c.rect(39, 36, 3, 2, green)
        for x in [39, 41] { c.px(x, 38, claw); c.px(x, 39, claw) }
    }
}

// MARK: - Sycorex

/// The Sycorex: Clawd as a warlord in bone armour and a blood-red cloak: a bone helmet with spiny ridges sweeping back,
/// framing a skinless face of raw red muscle (black eyes, bared teeth); ribs of bone over the chest. It carries a bone
/// whip, the coils hanging from its fist, which cracks out as blue lightning when it fights.
private func drawSycorex(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x8A1C1C), robeDark = C(0x5A1010), bone = C(0xE2D8BE), boneDark = C(0xA89C80)
    let flesh = C(0xB4403A), fleshDark = C(0x7A2420)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: robeDark, edge: C(0x3E0A0A), extra: -2.5)
    drawLegs(c, Look(leg: robe), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 42 - (p.step >= 0 && [19, 23, 31, 35].firstIndex(of: lx)! % 2 == p.step ? 1 : 0), 2, 2, boneDark) } }
    c.oy += p.breathe
    let casting = p.zap != nil || p.ready || p.cheering
    let raise = casting ? p.armRaise : 0
    drawBody(c, Look(body: flesh, shade: fleshDark, arm: robe, eye: nil), armRight: raise)
    // The raw face: muscle grooves, black eyes, bone teeth.
    for (x, y) in [(20, 28), (21, 31), (35, 31), (26, 27), (29, 28)] { c.px(x, y, fleshDark) }
    c.rect(21, 28, 4, 4, fleshDark); c.rect(31, 28, 4, 4, fleshDark)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink); c.px(23, 29, C(0xFFE0A0)); c.px(33, 29, C(0xFFE0A0))
    c.rect(27, 30, 2, 2, C(0x4A1410))                                          // the nose holes
    c.rect(24, 32, 9, 2, C(0x2A0A08))
    for x in stride(from: 24, to: 33, by: 2) { c.px(x, 32, bone); c.px(x + 1, 33, bone) }
    // The bone helmet, ridged, sweeping back into spines.
    c.pattern(9, 15, [
        "...................B.........",
        "..............B...BB..B......",
        "...........B..BB.BBB.BB......",
        "BB.........BB.BBBBBBBBB......",
        ".BBBB.....BBBBBBBBBBBBBB.....",
        "..BBBBBBBBBBBbBBBbBBBBBBBB...",
        "....BBBBBBBBBBBBBBBBBBBBBBB..",
        "......BBBBBBbBBBBBBBBbBBBBBb.",
        "........BBBBBBBBBBBBBBBBBBBb.",
        ".........BBBBbbbbbbbbbbbbBBb.",
        ".........BBB.............BBb.",
        ".........BB...............Bb.",
        ".........BB...............Bb.",
        ".........BB...............Bb.",
        ".........B................Bb.",
    ], ["B": bone, "b": boneDark])
    // Bone ribs over the robe.
    c.rect(18, 34, 20, 4, robe); c.rect(37, 34, 1, 4, robeDark)
    for y in [34, 36] { c.rect(20, y, 16, 1, bone); c.px(35, y, boneDark) }
    c.rect(27, 34, 2, 4, boneDark)
    c.rect(15, 33, 3, 2, bone)
    // The whip: cracking out as lightning, or coiled down from the fist.
    c.rect(39, 32 - raise, 2, 4, boneDark); c.px(39, 32 - raise, bone)
    if !casting && !seatedPose {
        for (i, (x, y)) in [(41, 36), (42, 37), (43, 38), (43, 39), (42, 40), (41, 41), (42, 42)].enumerated() {
            c.px(x, y, i % 2 == 0 ? bone : boneDark); c.px(x + 1, y, boneDark)
        }
    }
}

// MARK: - Vashta Nerado

/// The Vashta Nerado: an empty expedition spacesuit walking on its own, white with orange trim and a chest panel, a
/// grey air pack on its back. Inside the round helmet's dark visor grins a skull. A swarm of living shadows boils
/// round its feet and drifts about it, flecks of darkness that never settle.
private func drawVashtaNerado(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xE6E6E0), shade = C(0xB4B4AE), trim = C(0xE07A2A), pack = C(0x8A8E96), visor = C(0x141A22)
    let t = p.lt
    // The shadows round its feet, a pool spreading under them.
    c.rect(11, 43, 35, 1, C(0x000000, 0.5)); c.rect(14, 42, 29, 1, C(0x000000, 0.35))
    let i0 = Int(t * 8)
    for k in 0..<16 {
        let a = noise(k * 13) * 2 * .pi + t * (0.6 + noise(k * 7) * 0.8)
        let r = 10 + noise(k * 5 + i0 / 6) * 8
        let x = 28 + Int((cos(a) * r).rounded()), y = 36 + Int((sin(a) * r * 0.55).rounded())
        let col = C(0x08080C, 0.55 + 0.4 * noise(k + i0))
        c.rect(x, y, 2, 2, col); if k % 3 == 0 { c.px(x + 2, y - 1, col.alpha(0.6)) }
    }
    // The air pack behind.
    c.rect(13, 25, 5, 11, pack); c.rect(13, 25, 5, 1, C(0xB0B4BC)); c.rect(14, 28, 3, 1, C(0x5A5E66))
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 42 - (p.step >= 0 && [19, 23, 31, 35].firstIndex(of: lx)! % 2 == p.step ? 1 : 0), 2, 2, C(0x6A6E76)) } }
    // Shadows creeping up its legs.
    for k in 0..<7 {
        let x = 18 + Int(noise(k * 17 + i0 / 4) * 20), y = 37 + Int(noise(k * 29 + i0 / 5) * 6)
        c.rect(x, y, 2, 1, C(0x08080C, 0.55 + 0.35 * noise(k * 3 + i0)))
    }
    c.oy += p.breathe
    let reaching = p.ready || p.cheering || p.hit
    drawBody(c, Look(body: suit, shade: shade, arm: suit, eye: nil), armRight: reaching ? 3 : 0)
    // The chest panel and belt.
    c.rect(18, 36, 20, 1, trim)
    c.rect(23, 34, 9, 2, C(0x5A5E66)); c.px(24, 34, C(0x6AE06A)); c.px(26, 34, C(0xFF4A3A)); c.px(28, 35, C(0x6AB8FF))
    // The round helmet, its visor dark, a skull inside.
    c.pattern(16, 15, [
        "......RRRRRRRRRR......",
        "....RRRRRRRRRRRRRR....",
        "...RRRVVVVVVVVVVRRR...",
        "..RRVVVVVVVVVVVVVVRR..",
        ".RRVVVVVVVVVVVVVVVVRR.",
        ".RVVVVVVVVVVVVVVVVVVRs",
        "RRVVVVVVVVVVVVVVVVVVRs",
        "RVVVVVVVVVVVVVVVVVVVVs",
        "RVVVVVVVVVVVVVVVVVVVVs",
        "RVVVVVVVVVVVVVVVVVVVVs",
        "RVVVVVVVVVVVVVVVVVVVVs",
        "RRVVVVVVVVVVVVVVVVVVRs",
        ".RVVVVVVVVVVVVVVVVVVRs",
        ".RRVVVVVVVVVVVVVVVVRR.",
        "..RRVVVVVVVVVVVVVVRR..",
        "...RRRRRRRRRRRRRRRR...",
        "...TTTTTTTTTTTTTTTT...",
        "....TTTTTTTTTTTTTT....",
    ], ["R": suit, "V": visor, "s": shade, "T": trim])
    let skull = C(0xEAE4D0), sk = C(0x9A9484)
    c.pattern(21, 18, [
        "...SSSSSS...",
        "..SSSSSSSS..",
        ".SSSSSSSSSS.",
        ".SSSSSSSSSSs",
        ".SKKSSSSKKSs",
        ".SKKSSSSKKSs",
        ".SSSSSSSSSSs",
        "..SSSKKSSSs.",
        "...SSSSSSs..",
        "...SKSKSKs..",
        "....SSSSs...",
    ], ["S": skull, "K": ink, "s": sk])
    c.rect(19, 18, 2, 3, white.alpha(0.35)); c.px(19, 21, white.alpha(0.2))   // glass glint
    if Int(p.t * 2) % 2 == 0 { c.px(22, 15, C(0xFFF6C8)) }                    // the helmet lamp
    // The near arm, reaching when it's after you.
    if reaching { c.rect(41, 30, 3, 3, suit); c.rect(44, 30, 2, 2, shade) }
}

// MARK: - The Empty Kid

/// The Empty Kid: Clawd as a small boy in a too-big wartime coat, grey shorts and socks, a black rubber gas mask
/// strapped over his face: two round glass eyepieces and a snout with its round filter. Messy hair sticks up over the
/// strap. When he's after you (or waiting, or hit) he holds his arms out, asking for his mummy.
private func drawEmptyKid(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x8C7A5A), coatDark = C(0x6A5A40), rubber = C(0x2A2A2E), rubberLight = C(0x46464C), glass = C(0x8C9EA6)
    let hair = C(0x5A3E24), strap = C(0x6A4A2A)
    drawLegs(c, Look(leg: C(0xC8B8A0)), step: p.step)                          // bare knees
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let up = p.step >= 0 && i % 2 == p.step ? 1 : 0
            c.rect(lx, 39 - up, 2, 3, C(0x8A8A86)); c.rect(lx, 42 - up, 2, 1, C(0x2A2420))   // grey socks, black shoes
        }
    }
    c.oy += p.breathe
    let reaching = p.ready || p.cheering || p.hit || (!p.resting && !p.walking)
    drawBody(c, Look(body: coat, shade: coatDark, arm: coat, eye: nil), armLeft: reaching ? 3 : 0, armRight: reaching ? 3 : 0)
    // The coat: buttons, shorts showing under it.
    c.rect(18, 36, 20, 2, C(0x5A5E64))
    for y in [34, 36] { c.px(28, y, C(0x2A2420)) }
    c.rect(28, 33, 1, 3, coatDark)
    // Messy hair, then the mask over the whole face.
    c.pattern(18, 21, [
        "...H..HH.H..H.......",
        "..HHHHHHHHHHHHH.H...",
        ".HHHHHHHHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHH.",
        "SSSSSSSSSSSSSSSSSSSS",
    ], ["H": hair, "S": strap])
    c.rect(18, 26, 20, 7, rubber); c.rect(37, 26, 1, 7, C(0x1A1A1E))
    c.rect(19, 26, 18, 1, rubberLight)
    for x0 in [20, 30] {
        c.rect(x0, 27, 6, 5, C(0x5A5A62)); c.rect(x0 + 1, 28, 4, 3, glass); c.px(x0 + 1, 28, white.alpha(0.7))
        c.rect(x0, 27, 1, 1, rubber); c.rect(x0 + 5, 27, 1, 1, rubber); c.rect(x0, 31, 1, 1, rubber); c.rect(x0 + 5, 31, 1, 1, rubber)
    }
    // The snout and its filter, hanging forward.
    c.rect(26, 31, 5, 3, rubber); c.rect(27, 33, 3, 1, rubberLight)
    c.rect(25, 34, 7, 4, C(0x6A7060)); c.rect(26, 34, 5, 1, C(0x9AA08C)); c.rect(25, 37, 7, 1, C(0x4A4E42))
    for x in [26, 28, 30] { c.px(x, 35, C(0x2A2A2E)) }
    // Arms out for his mummy.
    if reaching {
        c.rect(38, 30, 6, 3, coat); c.rect(44, 30, 2, 2, C(0xC8B8A0))
        c.rect(15, 30, 3, 2, coatDark)
    }
}

// MARK: - Toclafayne

/// The Toclafayne: a little flying silver sphere, polished and panelled, with a single slot through which a tiny
/// orange Clawd face peers. It bobs in the air; when it's on the move or roused, blades and spikes spin out from its
/// middle and whirl. It never touches the ground.
private func drawToclafayne(_ c: PixelCanvas, _ p: Pose) {
    let silver = C(0xC8CCD4), light = C(0xF0F2F6), dark = C(0x8A8E98), deep = C(0x5A5E68)
    let bob = p.flying ? 0 : Int((sin(p.lt * 2.6) * 1.5).rounded())
    let cx = 28.0, cy = 29.0 + Double(bob), r = 7.5
    let armed = p.flying || p.walking || p.hit || p.ready || p.cheering || !p.resting
    // Its shadow on the ground.
    if !p.flying { c.rect(22, 43, 13, 1, C(0x000000, 0.25)); c.rect(24, 42, 9, 1, C(0x000000, 0.12)) }
    // The blades, spinning round the middle.
    if armed {
        let spin = p.t * 9
        for k in 0..<6 {
            let a = spin + Double(k) * .pi / 3
            let ex = cos(a) * (r + 5), ey = sin(a) * (r + 5) * 0.45
            c.glowLine(cx + cos(a) * r * 0.8, cy + sin(a) * r * 0.36, cx + ex, cy + ey,
                       core: k % 2 == 0 ? light : silver, glow: clear, coreR: 0.5, glowR: 0.55)
        }
    }
    // The sphere, shaded from the top left.
    for y in Int(cy - r)...Int(cy + r) {
        for x in Int(cx - r)...Int(cx + r) {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let d = (dx * dx + dy * dy).squareRoot()
            guard d <= r else { continue }
            let lit = (-dx - dy) / (r * 1.41)
            let col = d > r - 1 ? deep : lit > 0.45 ? light : lit > -0.15 ? silver : dark
            c.px(x, y, col)
        }
    }
    let iy = Int(cy)
    c.rect(Int(cx - r) + 1, iy + 2, Int(r * 2) - 1, 1, deep)                    // the seam
    for x in [23, 28, 33] { c.px(x, iy + 3, deep) }
    // The slot, a tiny orange face peering out.
    c.rect(26, iy - 3, 9, 4, C(0x1A1A20))
    c.rect(27, iy - 2, 7, 3, clawdOrange)
    let fierce = armed && p.hit
    c.px(28, iy - 1, ink); c.px(32, iy - 1, ink)
    if fierce { c.px(28, iy - 2, ink); c.px(32, iy - 2, ink) }
    c.px(23, iy - 5, white)
}
