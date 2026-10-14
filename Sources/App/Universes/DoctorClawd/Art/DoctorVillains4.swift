import Foundation

// Villains: the big monster families. The Supreme Dalick and the Emperor, the Cyberpersons old and new and their
// Controller, the Sontaron, the Judoom, the Autom and the Ice Warior; and two of the small fry that only ever turn up as
// agents, an Adipoze and a Cybermite. Clawd is inside every costume: the Dalicks' casing and the Sontaron's potato head
// are Clawd orange, the Emperor keeps him in its dome, and the rest wear their armour over his blocky body.

let doctorVillains4: [DoctorVillain: Persona] = [
    .supremeDalick: Persona(name: "Supreme Dalick", weapon: .blaster, motion: .hover,
                  shot: .beam(core: C(0xFFF2F0), glow: C(0xFF4A3A)), armoured: true, canSit: false, muzzle: (46, 29),
                  handGun: false, headTop: 12,
                  draw: drawSupremeDalick),
    .dalickEmperor: Persona(name: "Dalick Emperor", motion: .hover, armoured: true, canSit: false, bulk: 9, headTop: 3,
                  draw: drawDalickEmperor),
    .mondasianCyberperson: Persona(name: "Mondasian Cyberperson", weapon: .blaster, shot: cyberShot, armoured: true,
                  canSit: false, muzzle: (47, 33), headTop: 15,
                  draw: drawMondasianCyberperson),
    .cyberperson: Persona(name: "Cyberperson", weapon: .blaster, shot: cyberShot, armoured: true, canSit: false,
                  muzzle: (46, 34), handGun: false, headTop: 21, callout: "DELETE",
                  draw: drawCyberperson),
    .cyberController: Persona(name: "Cyber Controller", weapon: .blaster, shot: cyberShot, armoured: true, canSit: false,
                  muzzle: (47, 33), headTop: 13,
                  draw: drawCyberController),
    .sontaron: Persona(name: "Sontaron", weapon: .blaster, shot: .energy(core: C(0xFFF2D8), glow: C(0xFF7A2A)),
                  armoured: true, muzzle: (50, 33), headTop: 19, callout: "Sontar-ha!",
                  draw: drawSontaron),
    .judoom: Persona(name: "Judoom", weapon: .blaster, shot: .energy(core: C(0xF0FFF4), glow: C(0x3AD88A)),
                  armoured: true, muzzle: (48, 33), headTop: 19, callout: "Bo! Ko! To!",
                  draw: drawJudoom),
    .autom: Persona(name: "Autom", weapon: .blaster, shot: .energy(core: C(0xFFF6DA), glow: C(0xFFB23A)),
                  muzzle: (45, 34), handGun: false, headTop: 21,
                  draw: drawAutom),
    .iceWarior: Persona(name: "Ice Warior", weapon: .blaster, shot: .beam(core: C(0xF0FFF0), glow: C(0x6AE08A)),
                  armoured: true, canSit: false, muzzle: (47, 34), handGun: false, headTop: 18,
                  draw: drawIceWarior),
    .adipoze: Persona(name: "Adipoze", motion: .fly, canSit: false, headTop: 30,
                  draw: drawAdipoze),
    .cybermite: Persona(name: "Cybermite", armoured: true, canSit: false, headTop: 33,
                  draw: drawCybermite),
]

/// The Cyberpersons' guns: a pale blue-white bolt.
private let cyberShot = ShotStyle.energy(core: C(0xF0FAFF), glow: C(0x7FC8FF))

// MARK: - The Dalicks

/// A Dalick's colours: casing, its shade, the hemispheres and their shine, the bands and the dome's highlight.
private struct DalickPaint {
    var casing: Px, shade: Px, stud: Px, studShine: Px, band: Px, bandDark: Px, shine: Px
    var metal = C(0x3A3A42), metalLight = C(0x6A6A78), eye = C(0x6AC8FF)
}

/// The Supreme Dalick: a Dalick in red and black, its gold bands and its hemispheres black with a gold shine. It glides,
/// bullets glance off it, and its lamps flash as it fires.
private func drawSupremeDalick(_ c: PixelCanvas, _ p: Pose) {
    drawDalickCasing(c, p, DalickPaint(casing: C(0xB8202A), shade: C(0x82141C), stud: C(0x1A161A), studShine: C(0xD8B04A),
                                       band: C(0xD8B04A), bandDark: C(0x1E1A1E), shine: C(0xF08A80),
                                       metal: C(0x1E1E24), metalLight: C(0x5A5A66)))
}

/// The Dalick shape (the same as the plain Dalick's, in `paint`): the flared, studded skirt, the shoulder section with
/// the gunstick and plunger, the slatted neck, the dome with its lamps and the eyestalk. The lamps flash while it fires.
private func drawDalickCasing(_ c: PixelCanvas, _ p: Pose, _ paint: DalickPaint) {
    let casing = paint.casing, shade = paint.shade, metal = paint.metal, metalLight = paint.metalLight
    let shouting = p.fire.map { frac($0.t / p.firePeriod) < 0.3 } ?? false
    let flash = shouting && Int(p.t * 8) % 2 == 0

    c.rect(15, 42, 27, 2, metal); c.rect(15, 42, 27, 1, metalLight)
    for y in 31...41 {
        let k = (y - 31) / 4
        c.rect(19 - k, y, 19 + k * 2, 1, casing)
        c.px(37 + k, y, shade); c.px(38 + k, y, shade)
    }
    for (row, y) in [33, 36, 39].enumerated() {
        for col in 0..<4 {
            let x = 20 - row + col * (5 + (row + 1) / 2)
            c.rect(x, y, 2, 2, paint.stud); c.px(x, y, paint.studShine)
        }
    }
    c.rect(19, 26, 19, 5, casing); c.rect(37, 26, 1, 5, shade)
    c.rect(19, 30, 19, 1, paint.bandDark); c.rect(19, 26, 19, 1, paint.band)
    c.rect(38, 27, 6, 1, metalLight); c.rect(44, 26, 2, 3, metal); c.px(45, 27, C(0x101014))
    c.rect(38, 29, 8, 1, metal); c.px(46, 29, metalLight)
    for x in [40, 42] { c.px(x, 28, metalLight); c.px(x, 30, metalLight) }
    c.rect(21, 20, 15, 6, C(0x2A2A30))
    for y in [20, 22, 24] { c.rect(20, y, 17, 1, paint.band); c.px(36, y, paint.bandDark) }
    for x in stride(from: 22, to: 36, by: 3) { c.rect(x, 21, 1, 5, C(0x46464E)) }
    for dy in 0...6 {
        let hw = Int((7 * (1 - Double(dy * dy) / 36).squareRoot()).rounded())
        c.rect(28 - hw, 19 - dy, hw * 2 + 1, 1, casing)
    }
    c.rect(21, 19, 15, 1, shade)
    c.rect(20, 20, 17, 1, paint.band)
    c.px(25, 14, paint.shine); c.px(26, 14, paint.shine)
    let lamp = flash ? C(0xFFF6C8) : C(0xC8A87A)
    for x in [22, 34] {
        c.rect(x, 13, 1, 3, lamp); if flash { c.px(x, 12, C(0xFFF6C8, 0.6)) }
    }
    for x in 35...41 { c.px(x, 16, metal) }
    for x in [37, 39] { c.px(x, 15, metalLight); c.px(x, 17, metalLight) }
    c.rect(42, 15, 2, 3, metal); c.px(43, 16, p.hit ? C(0xFF4A4A) : paint.eye)
}

/// The Dalick Emperor: a giant. A broad bronze-and-gold casing, its flared skirt studded with four rows of gold
/// hemispheres, on a wide base; a gunstick at the collar; and over it a huge glass dome, where Clawd himself sits wired
/// in, the Emperor's mutant. It hovers and bullets glance off it. It never fires a shot itself (its Dalicks do that):
/// its collar lamps blaze when it's roused, and Clawd's eyes go red when it's hit.
private func drawDalickEmperor(_ c: PixelCanvas, _ p: Pose) {
    let bronze = C(0xB8863A), bronzeShade = C(0x8A6024), gold = C(0xE8C860), goldDark = C(0x7A541C)
    let metal = C(0x34343C), metalLight = C(0x6A6A78), glass = C(0xBEE6F0)
    let roused = p.ready || p.cheering || p.hit
    let flash = roused && Int(p.t * 8) % 2 == 0

    // The base and the skirt, flaring out to the ground.
    c.rect(6, 42, 46, 2, metal); c.rect(6, 42, 46, 1, metalLight)
    for y in 28...41 {
        let k = (y - 28) / 3
        c.rect(12 - k, y, 34 + k * 2, 1, bronze)
        c.rect(43 + k, y, 3, 1, bronzeShade)
    }
    for (row, y) in [29, 32, 35, 38].enumerated() {
        for col in 0..<6 {
            let x = 14 - row + col * (5 + row / 2)
            c.rect(x, y, 3, 2, goldDark); c.rect(x, y, 2, 1, gold)
        }
    }
    // The collar, banded in gold, with the gunstick and its lamps.
    c.rect(11, 23, 36, 5, bronze); c.rect(44, 23, 3, 5, bronzeShade)
    c.rect(10, 23, 38, 1, gold); c.rect(11, 27, 36, 1, goldDark)
    for x in stride(from: 14, to: 44, by: 4) { c.rect(x, 24, 1, 3, bronzeShade) }
    c.rect(47, 25, 4, 1, metal); c.rect(47, 27, 5, 1, metal); c.rect(51, 26, 1, 3, metal); c.px(52, 27, metalLight)
    c.rect(47, 24, 2, 4, metalLight)
    let lamp = flash ? C(0xFFF6C8) : C(0xC8A87A)
    for x in [13, 43] { c.rect(x, 20, 2, 3, lamp); if flash { c.rect(x, 19, 2, 1, C(0xFFF6C8, 0.6)) } }

    // Inside the dome: Clawd, wired in.
    let eyes = p.hit ? C(0xFF4A4A) : ink
    c.rect(20, 11, 16, 11, clawdOrange); c.rect(35, 11, 1, 11, clawdShade); c.rect(20, 21, 16, 1, clawdShade)
    c.rect(23, 14, 2, 3, eyes); c.rect(31, 14, 2, 3, eyes)
    for (x, y) in [(17, 14), (16, 18), (39, 13), (40, 18)] {      // the wires
        c.px(x, y, C(0x5A3A4A)); c.px(x + (x < 28 ? 1 : -1), y + 1, C(0x5A3A4A)); c.px(x + (x < 28 ? 2 : -2), y + 1, C(0x5A3A4A))
    }
    // The dome: glass over him, rimmed in gold.
    for dy in 0...17 {
        let hw = Int((15 * (1 - Double(dy * dy) / 324).squareRoot()).rounded())
        let y = 22 - dy
        c.rect(28 - hw, y, hw * 2 + 1, 1, glass.alpha(0.4))
        c.px(28 - hw, y, glass.alpha(0.8)); c.px(28 + hw, y, glass.alpha(0.8))
        if dy == 17 { c.rect(28 - hw, y, hw * 2 + 1, 1, glass.alpha(0.8)) }
    }
    for (x, y) in [(18, 9), (19, 8), (20, 7), (17, 11), (17, 12)] { c.px(x, y, white.alpha(0.75)) }
    c.rect(12, 22, 33, 1, gold); c.rect(12, 22, 33, 1, gold); c.px(44, 22, goldDark)
}

// MARK: - The Cyberpersons

/// Cyber legs: they march stiffly, the lifted pair raised two pixels straight up from the hip, boots flat.
private func drawMarchingLegs(_ c: PixelCanvas, step: Int, leg: Px, knee: Px, boot: Px) {
    if seatedPose { drawLegs(c, Look(leg: leg)); return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let h = step >= 0 && i % 2 == step ? 6 : 8
        c.rect(lx, 36, 2, h, leg)
        c.rect(lx, 32 + h, 2, 1, knee)
        c.rect(lx, 34 + h, 2, 2, boot)
    }
}

/// The far arm swinging in time with the march: up on one step, down on the other.
private func marchArm(_ p: Pose) -> Int { p.step == 0 ? 1 : (p.step == 1 ? -1 : 0) }

/// A cyber gun held in the right hand: a boxy grip and a long barrel, its muzzle at (x + 6, y).
private func drawCyberGun(_ c: PixelCanvas, x: Int, y: Int, body: Px, trim: Px, lit: Bool) {
    c.rect(x, y, 6, 2, body); c.rect(x + 1, y, 4, 1, trim); c.rect(x, y + 2, 2, 1, body)
    c.px(x + 6, y, lit ? C(0xBFE8FF) : trim)
}

/// The Cyberperson: Clawd sealed in silver. The helmet's crown sits on top of the block, the handlebars loop from the
/// ear discs up onto it, and the face has the teardrop eye holes and the slot of a mouth; the chest plate below carries
/// a round emblem between two cables. The gun is built into the right forearm. It marches stiffly, never bobbing, the far
/// arm swinging in time.
private func drawCyberperson(_ c: PixelCanvas, _ p: Pose) {
    let silver = C(0xC4C8D0), light = C(0xE6E9EE), dark = C(0x8A909C), steel = C(0x50555F), hole = C(0x16161B)
    drawMarchingLegs(c, step: p.step, leg: silver, knee: dark, boot: dark)
    if !p.walking { c.oy += p.breathe }
    drawBody(c, Look(body: silver, shade: dark, arm: silver, eye: nil), armLeft: marchArm(p))
    // The face plate and the chest.
    c.rect(19, 26, 1, 7, light)
    c.rect(20, 27, 1, 6, dark); c.rect(35, 27, 1, 6, dark)
    for x in [22, 32] { c.rect(x, 29, 2, 3, hole); c.px(x + 1, 32, hole); c.px(x + 1, 33, hole.alpha(0.6)) }
    c.rect(25, 33, 6, 1, hole); c.rect(26, 34, 4, 1, steel)
    c.rect(18, 35, 20, 1, dark)
    c.rect(26, 36, 4, 1, steel); c.px(27, 36, light)
    c.rect(20, 36, 1, 2, steel); c.rect(35, 36, 1, 2, steel)
    // The crown and the handlebars, ear disc to crown.
    c.rect(20, 24, 16, 2, silver); c.rect(21, 24, 14, 1, light); c.rect(35, 24, 1, 2, dark)
    c.rect(26, 23, 4, 1, silver)
    let bar = C(0x6A707C)
    c.rect(15, 23, 1, 5, bar); c.rect(16, 22, 5, 1, bar); c.px(16, 23, light)
    c.rect(40, 23, 1, 5, bar); c.rect(35, 22, 5, 1, bar); c.px(39, 23, silver)
    c.rect(14, 28, 4, 4, dark); c.rect(15, 29, 2, 2, steel); c.px(15, 29, light)
    c.rect(38, 28, 3, 4, dark); c.px(39, 29, light)
    // The right arm and its forearm gun.
    c.oy += p.gunY
    let lit = p.fire != nil || p.ready
    c.rect(38, 33, 3, 3, silver); c.rect(38, 35, 3, 1, dark)
    c.rect(41, 33, 4, 2, steel); c.rect(41, 33, 4, 1, dark); c.px(45, 33, lit ? C(0xBFE8FF) : steel)
}

/// The Mondasian Cyberperson, the first of them: a cloth mask stitched over Clawd's face with round eye holes and a
/// hinged mouth, a lamp on top of the metal hoop that runs over his head ear to ear, grey fabric overalls, the boxy
/// chest unit with its dials and the tubes to its arms, and bare hands holding a gun. It marches stiffly too.
private func drawMondasianCyberperson(_ c: PixelCanvas, _ p: Pose) {
    let cloth = C(0xC4BEB2), clothDark = C(0x9A9488), stitch = C(0x6E685C), suit = C(0xA4A8AE), suitDark = C(0x767A82)
    let metal = C(0x5E626C), metalLight = C(0x9AA0AA), hand = C(0xE6C6A6), hole = C(0x16161B)
    drawMarchingLegs(c, step: p.step, leg: suit, knee: suitDark, boot: C(0xD8D8D2))
    if !p.walking { c.oy += p.breathe }
    drawBody(c, Look(body: cloth, shade: clothDark, arm: suit, eye: nil), armLeft: marchArm(p))
    // The mask: stitched seams, round eye holes, the mouth slot with its hinge pins.
    for x in [22, 32] {
        c.rect(x, 29, 2, 3, hole); c.px(x - 1, 30, stitch); c.px(x + 2, 30, stitch)
        c.px(x, 28, stitch); c.px(x + 1, 28, stitch)
    }
    c.rect(25, 32, 6, 1, hole); c.px(24, 32, metalLight); c.px(31, 32, metalLight)
    for y in stride(from: 26, through: 31, by: 2) { c.px(28, y, stitch) }
    c.rect(19, 24, 18, 2, cloth); c.rect(20, 23, 16, 1, cloth); c.rect(36, 24, 1, 2, clothDark)
    // The overalls and the chest unit, with tubes out to the arms.
    c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, suitDark); c.rect(18, 37, 20, 1, suitDark)
    c.rect(21, 33, 13, 4, metal); c.rect(21, 33, 13, 1, metalLight)
    c.px(23, 35, C(0xE8D04A)); c.px(26, 35, C(0x6AC8FF)); c.rect(29, 34, 3, 2, C(0x2A2A30)); c.px(30, 34, metalLight)
    c.rect(18, 34, 3, 1, metalLight); c.rect(34, 34, 4, 1, metalLight)
    // The hoop over the head, with the lamp on top.
    c.rect(15, 22, 1, 7, metal); c.rect(40, 22, 1, 7, metal)
    c.rect(16, 21, 24, 1, metal); c.rect(16, 21, 24, 1, metalLight.alpha(0.4))
    c.rect(14, 28, 3, 3, metalLight); c.px(15, 29, metal); c.rect(39, 28, 3, 3, metalLight); c.px(40, 29, metal)
    c.rect(25, 16, 7, 5, metal); c.rect(25, 16, 7, 1, metalLight); c.rect(26, 15, 5, 1, metalLight)
    c.rect(32, 17, 1, 3, p.fire != nil ? C(0xFFF6C8) : C(0xE8D890))
    if p.fire != nil { c.rect(33, 17, 1, 3, C(0xFFF6C8, 0.5)) }
    // The right hand and its gun.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, suit); c.rect(40, 33, 1, 3, hand)
    drawCyberGun(c, x: 41, y: 33, body: C(0x3A3A42), trim: metalLight, lit: p.fire != nil)
}

/// The Cyber Controller: a Cyberperson grown a great bulbous brain dome, silver ridged like the brain inside it, which
/// pulses blue as it gives orders (fires). Round eye holes, the mouth slot, little handlebars at the temples, a heavy
/// chest unit, and a gun in its hand. It marches stiffly like the rest.
private func drawCyberController(_ c: PixelCanvas, _ p: Pose) {
    let silver = C(0xBEC2CA), light = C(0xE6E9EE), dark = C(0x868C98), steel = C(0x50555F), hole = C(0x16161B)
    drawMarchingLegs(c, step: p.step, leg: silver, knee: dark, boot: dark)
    if !p.walking { c.oy += p.breathe }
    drawBody(c, Look(body: silver, shade: dark, arm: silver, eye: nil), armLeft: marchArm(p))
    // The dome: half an ellipse rising off the head, with the brain's folds in it.
    let pulse = p.fire.map { frac($0.t / p.firePeriod) < 0.4 } ?? false
    let fold = pulse ? C(0x7FC8FF) : dark
    for dy in 0...12 {
        let hw = Int((11 * (1 - Double(dy * dy) / 169).squareRoot()).rounded())
        c.rect(28 - hw, 26 - dy, hw * 2 + 1, 1, silver)
        c.px(28 + hw, 26 - dy, dark)
    }
    c.rect(22, 15, 6, 1, light); c.rect(20, 17, 3, 1, light)
    for (x, y, w) in [(24, 17, 4), (30, 16, 3), (21, 20, 3), (26, 19, 5), (33, 19, 3), (19, 23, 4), (25, 22, 3),
                      (30, 22, 5), (23, 25, 4), (32, 25, 3)] {
        c.rect(x, y, w, 1, fold)
    }
    for (x, y) in [(28, 18), (24, 21), (34, 21), (29, 23), (22, 24)] { c.px(x, y, fold) }
    c.rect(17, 26, 22, 1, dark)
    // The face: round eye holes, the mouth slot; the chest unit.
    c.rect(20, 28, 1, 5, dark); c.rect(35, 28, 1, 5, dark)
    for x in [22, 32] { c.rect(x, 29, 2, 3, hole); c.px(x, 29, steel) }
    c.rect(25, 33, 6, 1, hole)
    c.rect(18, 35, 20, 1, dark)
    c.rect(22, 36, 12, 2, steel); c.rect(23, 36, 2, 1, light); c.rect(29, 36, 3, 1, C(0x3A3A42))
    // Handlebars at the temples.
    c.rect(15, 28, 3, 4, dark); c.px(16, 29, light)
    c.rect(16, 24, 1, 4, light); c.px(17, 23, light)
    c.rect(38, 28, 2, 4, dark); c.rect(39, 24, 1, 4, silver); c.px(38, 23, silver)
    // The right hand and its gun.
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, silver); c.rect(38, 35, 3, 1, dark)
    drawCyberGun(c, x: 41, y: 33, body: steel, trim: light, lit: p.fire != nil)
}

// MARK: - Sontaron

/// The Sontaron: Clawd's orange as the great bald potato of a head, wider than the body, lumpy, with a heavy brow; the
/// thick armour collar ringing his neck with the probic vent at the back; dark blue quilted armour, black gloves and
/// boots, and a stubby blaster.
private func drawSontaron(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x26365E), quilt = C(0x3C5088), armourDark = C(0x18223E), collar = C(0x4A5A8A), black = C(0x1A1A20)
    drawLegs(c, Look(leg: armour), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 41 : 42, 2, 2, black)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: armour))
    // The potato: a dome over the top, wider than the body, lumps and a brow.
    c.pattern(16, 19, [
        "......OOOOOOOOOO......",
        "....OOOOOOOOOOOOOOS...",
        "..OOOOOOOOOOOOOOOOOSS.",
        ".OOOOOOOOOOOOOOOOOOOS.",
        ".OOOOOOOOOOOOOOOOOOOSS",
        "OOOOOOOOOOOOOOOOOOOOSS",
        "OOOOOOOOOOOOOOOOOOOOSS",
        "OOOOOOOOOOOOOOOOOOOOSS",
        "OOOOOOOOOOOOOOOOOOOOSS",
        "OOOOOOOOOOOOOOOOOOOOSS",
        ".OOOOOOOOOOOOOOOOOOOS.",
        ".OOOOOOOOOOOOOOOOOOOS.",
        ".OOOOOOOOOOOOOOOOOOOS.",
    ], ["O": clawdOrange, "S": clawdShade])
    for (x, y) in [(24, 21), (30, 20), (21, 23), (33, 23), (27, 24)] { c.px(x, y, clawdShade) }
    c.rect(21, 27, 4, 1, clawdShade); c.rect(31, 27, 4, 1, clawdShade)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(16, 28, 2, 2, clawdShade)   // the ear
    // The collar, the armour and the gloves.
    c.rect(15, 32, 26, 3, collar); c.rect(15, 32, 26, 1, C(0x6A7AAA)); c.rect(15, 34, 26, 1, armourDark)
    for x in [18, 24, 30, 36] { c.px(x, 33, C(0xA8B0C8)) }
    c.rect(14, 30, 3, 3, collar); c.px(15, 31, C(0xC8CCD4))   // the probic vent
    c.rect(18, 35, 20, 3, armour); c.rect(37, 35, 1, 3, armourDark)
    for y in [35] { for x in stride(from: 19 + (y / 2) % 2 * 2, to: 37, by: 4) { c.px(x, y, quilt); c.px(x + 1, y + 1, quilt) } }
    c.rect(15, 35, 3, 2, black)
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, armour); c.rect(40, 33, 1, 3, black)
    // The blaster: a stubby black body, silver fittings, a hot orange tip.
    c.pattern(41, 32, [
        "..SSSS...",
        "KKKKKKKKT",
        "KKKSKKKK.",
        "KK.......",
    ], ["K": C(0x2A2A30), "S": C(0x9AA0AA), "T": p.fire != nil ? C(0xFFD08A) : C(0xC86A2A)])
}

// MARK: - Judoom

/// The Judoom: a rhino in space-police black. A black helmet over the top and back of the grey rhino head, the snout
/// pushed out front with its great horn curving up through the helmet's slot and a small one behind; black armour
/// plating with silver trim and a badge on the chest; a chunky black energy pistol.
private func drawJudoom(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1C1C22), plate = C(0x34343E), silver = C(0xA8ACB6), skin = C(0x8A847C), skinDark = C(0x625D56)
    let horn = C(0xC2BAA8), hornDark = C(0x8E8676)
    drawLegs(c, Look(leg: black), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: plate, eye: nil))
    // The helmet: over the top and down the back, a silver rim.
    c.pattern(16, 19, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHRRRRRRRRRRRRRR",
        "HHHHHHR...............",
        "HHHHHR................",
        "HHHHHR................",
        "HHHHHR................",
        "HHHHHR................",
        "HHHHHR................",
    ], ["H": black, "R": silver])
    c.rect(19, 21, 14, 1, plate)
    // The rhino face: wrinkles, small eyes, the snout and the horns.
    c.rect(25, 28, 1, 1, skinDark); c.rect(27, 31, 3, 1, skinDark)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(36, 28, 3, 5, skin); c.rect(38, 29, 3, 4, skin); c.rect(38, 32, 3, 1, skinDark); c.px(40, 30, ink)
    c.pattern(37, 21, [
        "...H",
        "..HH",
        "..Hh",
        ".HHh",
        "HHHh",
        "HHh.",
        "Hh..",
    ], ["H": horn, "h": hornDark])
    c.rect(34, 25, 2, 2, horn)
    // The armour: plates, silver bands, the badge.
    c.rect(18, 33, 20, 5, black); c.rect(18, 33, 20, 1, silver)
    c.rect(19, 35, 18, 1, plate); c.rect(26, 34, 3, 3, silver); c.px(27, 35, C(0x3AD88A))
    c.rect(15, 33, 3, 3, plate); c.rect(15, 33, 3, 1, silver)
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, plate); c.rect(38, 33, 3, 1, silver)
    c.pattern(40, 32, [
        "..SSSS..",
        "KKKKKKKG",
        "KKKSKK..",
        ".KK.....",
    ], ["K": C(0x26262C), "S": silver, "G": p.fire != nil ? C(0xC8FFE0) : C(0x3AD88A)])
}

// MARK: - Autom

/// The Autom: a shop-window mannequin come to life. Smooth, glossy beige plastic with moulded hair and brows, blank
/// hollows for eyes, seams at the neck, shoulders, wrists and knees, and the shop's price tag still dangling from its
/// far wrist. When it means business its right hand drops open on a hinge and the gun
/// slides out of the wrist.
private func drawAutom(_ c: PixelCanvas, _ p: Pose) {
    let plastic = C(0xE8D2B4), shade = C(0xC8AE8E), seam = C(0xA88E70), hair = C(0xC8A47A), hairLight = C(0xE0C092)
    drawLegs(c, Look(leg: plastic), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 38 : 39, 2, 1, seam)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: plastic, shade: shade, arm: plastic, eye: nil))
    // Blank eyes, a moulded nose-line, the neck seam and the moulded hair.
    c.rect(22, 29, 2, 3, shade); c.rect(32, 29, 2, 3, shade); c.px(22, 29, seam); c.px(32, 29, seam)
    c.rect(27, 30, 1, 2, shade)
    c.rect(18, 33, 20, 1, seam); c.rect(18, 34, 20, 1, C(0xF4E4CC))
    c.rect(18, 36, 1, 1, seam); c.rect(15, 33, 1, 3, seam)
    c.rect(21, 27, 4, 1, seam); c.rect(31, 27, 4, 1, seam)                     // moulded brows
    c.px(19, 27, white.alpha(0.8)); c.px(19, 28, white.alpha(0.6)); c.px(35, 30, white.alpha(0.5))   // the gloss
    // The price tag still hanging off its far wrist, on a string.
    c.px(15, 36, C(0x8A8070)); c.px(14, 37, C(0x8A8070))
    c.rect(12, 38, 4, 3, C(0xF4F0E6)); c.px(12, 38, C(0x8A8070)); c.rect(13, 39, 2, 1, C(0xC8322E))
    c.pattern(17, 21, [
        ".....HHHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHhhhhHHHHHHHHHHH..",
        ".HHHHHHHHHHHhhhhHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HH...............HHH.",
        ".H.................HH.",
    ], ["H": hair, "h": hairLight])
    // The right arm: a hand, or the hand dropped open and the gun out.
    c.oy += p.gunY
    let armed = p.fire != nil || p.ready || p.cheering || p.gunLift > 0 || (!p.resting && !p.walking)
    c.rect(38, 33, 3, 3, plastic); c.rect(38, 33, 1, 3, seam); c.rect(40, 33, 1, 3, seam)
    if armed {
        c.rect(41, 33, 3, 2, C(0x5A5E68)); c.rect(41, 33, 3, 1, C(0x8A8F9A)); c.px(44, 33, C(0x2A2A30))
        c.rect(40, 35, 2, 3, plastic); c.px(41, 37, shade)
    } else {
        c.rect(41, 33, 2, 3, plastic); c.px(42, 35, shade)
    }
}

// MARK: - Ice Warior

/// The Ice Warior: Clawd in a green reptilian shell. The bulbous ridged helmet over his head, its brow jutting over the
/// dark goggle eyes, a scaly jaw below; ridged plates down the body, heavy shoulder pads, a pincer on the far hand and
/// the sonic gun built into the right forearm, its muzzle a green disc.
private func drawIceWarior(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4E7A3E), light = C(0x729E56), dark = C(0x2E4E26), scale = C(0x3C6230), lens = C(0x14201A)
    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let y = p.step >= 0 && i % 2 == p.step ? 38 : 39
            c.px(lx, y, dark); c.px(lx + 1, y + 2, dark); c.rect(lx - 1, y + 3 + (y == 38 ? 1 : 1), 4, 1, dark)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: dark, arm: green, eye: nil))
    // The helmet: a ridged dome, brow over the goggles.
    c.pattern(16, 18, [
        ".......GGGGGGGG.......",
        ".....GGLGGGLGGGGG.....",
        "...GGGLGGGLGGGLGGGG...",
        "..GGGLGGGLGGGLGGGLGGd.",
        ".GGGGLGGGLGGGLGGGLGGGd",
        ".GGGLGGGLGGGLGGGLGGGGd",
        "GGGGLGGGLGGGLGGGLGGGGd",
        "GGGGGGGGGGGGGGGGGGGGGd",
        "GGddddddddddddddddddddd",
        "GGG...................",
        "GG....................",
    ], ["G": green, "L": light, "d": dark])
    // The goggles and the jaw.
    for x in [21, 31] {
        c.rect(x, 28, 4, 4, lens); c.px(x + 1, 29, C(0x9AE0A0)); c.rect(x, 28, 4, 1, dark)
    }
    c.rect(24, 32, 9, 1, dark); c.rect(25, 31, 7, 1, scale); c.px(32, 32, C(0x1A2A14))
    // The shell: ridged plates and scales; the shoulder pads; the pincer.
    for y in [34, 36] { c.rect(18, y, 20, 1, scale) }
    for x in stride(from: 20, to: 37, by: 3) { c.px(x, 35, dark); c.px(x + 1, 37, dark) }
    c.rect(14, 30, 5, 3, light); c.rect(14, 32, 5, 1, dark)
    c.rect(14, 34, 2, 3, dark); c.px(13, 36, dark)
    // The right forearm and its sonic gun.
    c.oy += p.gunY
    c.rect(37, 30, 5, 3, light); c.rect(37, 32, 5, 1, dark)
    c.rect(38, 33, 4, 3, green); c.rect(38, 35, 4, 1, dark)
    c.rect(42, 33, 3, 2, dark); c.rect(45, 32, 1, 4, scale)
    let firing = p.fire.map { frac($0.t / p.firePeriod) < 0.4 } ?? false
    c.px(46, 34, firing ? C(0xC8FFD0) : C(0x6AE08A)); c.px(46, 33, C(0x6AE08A, 0.6))
}

// MARK: - Small fry

/// An Adipoze: a little white blob of fat, walking on two stubby feet with a side-to-side waddle, waving a tiny hand
/// now and then; a dot of a mouth with one tooth. It flies off with its arms up.
private func drawAdipoze(_ c: PixelCanvas, _ p: Pose) {
    let fat = C(0xF6F4EE), shade = C(0xD6D2C8), line = C(0xB8B2A6)
    if p.walking && !p.flying { c.ox += p.step == 0 ? -1 : 1 }
    if p.flying { c.oy -= Int(p.t * 6) % 2 }
    // The feet.
    if !p.flying {
        let lift = p.walking ? p.step : -1
        c.rect(24, lift == 0 ? 41 : 42, 3, 2, fat); c.rect(30, lift == 1 ? 41 : 42, 3, 2, shade)
    } else {
        c.rect(25, 41, 2, 1, fat); c.rect(30, 41, 2, 1, shade)
    }
    c.oy += p.breathe
    // The blob.
    c.pattern(21, 30, [
        "....FFFFFF....",
        "..FFFFFFFFFF..",
        ".FFFFFFFFFFFS.",
        ".FFFFFFFFFFFS.",
        "FFFFFFFFFFFFSS",
        "FFFFFFFFFFFFSS",
        "FFFFFFFFFFFFSS",
        "FFFFFFFFFFFFSS",
        ".FFFFFFFFFFSS.",
        ".FFFFFFFFFSSS.",
        "..SSSSSSSSSS..",
    ], ["F": fat, "S": shade])
    c.px(24, 31, white); c.px(25, 31, white)
    if p.hit {
        c.px(26, 34, ink); c.px(27, 35, ink); c.px(26, 36, ink)
        c.px(32, 34, ink); c.px(31, 35, ink); c.px(32, 36, ink)
    } else {
        c.rect(26, 34, 1, 2, ink); c.rect(31, 34, 1, 2, ink)
    }
    c.px(27, 37, line); c.rect(28, 38, 3, 1, line); c.px(31, 37, line)
    // The arms: waving, up in the air, or by its sides.
    let wave = !p.walking && sin(p.lt * 1.3) > 0.7
    if p.flying || p.cheering {
        c.rect(19, 31, 2, 3, fat); c.rect(34, 31, 2, 3, shade)
        if Int(p.t * 6) % 2 == 0 { c.px(18, 30, fat); c.px(36, 30, shade) }
    } else if wave {
        c.rect(19, 36, 2, 2, fat)
        let up = Int(p.lt * 8) % 2 == 0
        c.rect(34, up ? 32 : 33, 2, 3, shade); c.px(up ? 36 : 35, up ? 31 : 32, shade)
    } else {
        c.rect(19, 36, 2, 2, fat); c.rect(34, 36, 2, 2, shade)
    }
}

/// A Cybermite: a little silver insect, segmented, with feelers, buzzing wings and a red eye; it scuttles back and forth.
private func drawCybermite(_ c: PixelCanvas, _ p: Pose) {
    let silver = C(0xC4C8D0), light = C(0xE6E9EE), dark = C(0x7A808C), leg = C(0x50555F)
    let run = sin(p.t * 1.4)
    c.ox += Int((run * 5).rounded())
    let scurry = Int(p.t * 12) % 2
    // Six legs, scuttling.
    for (i, x) in [24, 28, 32].enumerated() {
        let a = (i + scurry) % 2
        c.px(x - a, 41, leg); c.px(x - 1 - a, 42, leg); c.px(x + 1 + a, 41, leg); c.px(x + 2 + a, 42, leg)
    }
    // The body: three segments and the head.
    c.rect(21, 38, 5, 3, silver); c.rect(26, 37, 5, 4, silver); c.rect(31, 37, 4, 4, silver)
    c.rect(21, 38, 5, 1, light); c.rect(26, 37, 5, 1, light); c.rect(31, 37, 4, 1, light)
    c.rect(21, 40, 14, 1, dark); c.px(26, 38, dark); c.px(31, 38, dark); c.px(20, 39, dark)
    c.rect(35, 37, 3, 3, silver); c.px(37, 37, light); c.rect(35, 39, 3, 1, dark)
    c.px(37, 38, Int(p.t * 4) % 2 == 0 ? C(0xFF3A3A) : C(0x9A2A20))
    // The feelers and the wings.
    c.px(37, 36, dark); c.px(38, 35, dark); c.px(39, 34, dark); c.px(40, 34, dark)
    c.px(35, 36, dark); c.px(35, 35, dark); c.px(36, 34, dark)
    let buzz = Int(p.t * 20) % 2 == 0
    c.rect(24, buzz ? 35 : 36, 6, 1, C(0xE8F4FF, 0.55)); c.rect(25, buzz ? 34 : 35, 4, 1, C(0xE8F4FF, 0.35))
}
