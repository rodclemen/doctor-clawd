import Foundation

// Companions and allies, the later lot: the Sontaran butler, the friends who travelled after him, and UNIT. Clawd in
// costume, every one: hair, jackets and uniforms drawn over (and around) the blocky body, Clawd's own orange face
// showing. Most of them carry nothing: they run, and point, and wave.

let doctorHeroes7: [DoctorHero: Persona] = [
    .stracks: Persona(name: "Stracks", weapon: .blaster, armoured: true, muzzle: (50, 32), headTop: 20, signature: 3.0,
                  draw: drawStracks),
    .bill: Persona(name: "Bill Pans", headTop: 14, draw: drawBill),
    .nardoll: Persona(name: "Nardoll", headTop: 25, draw: drawNardoll),
    .yaz: Persona(name: "Yaz Kahn", headTop: 20, draw: drawYaz),
    .graham: Persona(name: "Graham O'Brine", headTop: 25, draw: drawGraham),
    .ryan: Persona(name: "Ryan Sinclare", headTop: 22, draw: drawRyan),
    .dan: Persona(name: "Dan Louis", headTop: 22, draw: drawDan),
    .ruby: Persona(name: "Ruby Monday", headTop: 20, signature: 3.4, draw: drawRuby),
    .belinda: Persona(name: "Belinda Chandler", headTop: 16, draw: drawBelinda),
    .kate: Persona(name: "Kate Stewed", weapon: .blaster, shot: .bullet, muzzle: (47, 32), headTop: 21,
                  draw: drawKate),
    .osgoode: Persona(name: "Osgoode", headTop: 20, signature: 3.4, draw: drawOsgoode),
]

// MARK: - Shared bits

/// What an unarmed companion's arms are doing: down, pointing the way, waving you over, or both up cheering.
private enum Gesture { case rest, point, wave, cheer }

private func gesture(_ p: Pose) -> Gesture {
    if p.cheering { return .cheer }
    if p.ready { return p.urgent ? .wave : .point }
    if !p.resting && !p.walking && !p.hit { return .point }
    return .rest
}

/// The arms in `sleeve` for a gesture (resting arms are drawBody's).
private func drawGesture(_ c: PixelCanvas, _ g: Gesture, t: Double, sleeve: Px) {
    switch g {
    case .rest: break
    case .point:
        c.rect(38, 32, 4, 3, sleeve); c.rect(42, 32, 2, 2, clawdOrange); c.px(44, 32, clawdOrange)
    case .wave:
        let k = Int(t * 6) % 2
        c.rect(38, 28, 3, 6, sleeve); c.rect(38 + k, 25, 3, 3, clawdOrange)
    case .cheer:
        for x in [15, 38] { c.rect(x, 25, 3, 8, sleeve); c.rect(x, 23, 3, 2, clawdOrange) }
    }
}

/// Shoes: the bottom `rows` of each leg (not when sitting, when the legs are folded).
private func drawShoes(_ c: PixelCanvas, step: Int, _ col: Px, rows: Int = 2) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A bald head's shine and the ears either side.
private func drawBaldHead(_ c: PixelCanvas) {
    c.rect(20, 26, 3, 1, C(0xF0A080)); c.px(20, 27, C(0xF0A080))
    c.rect(17, 29, 1, 2, clawdShade)
}

// MARK: - Stracks

/// Stracks: a Sontaran butler, so Clawd is the potato: the orange body rises into a lumpy dome, heavy-browed, little
/// ears, a thin mouth. Below it the dark quilted armour with its silver collar ring and the probic vent at the back of
/// the neck, black boots, a grenade on the belt. He carries a stubby blaster rifle and shots glance off his armour.
/// Signature: a grenade, "for later": he takes it off his belt, holds it up and admires it lovingly, then puts it back.
private func drawStracks(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x2E3648), armourDark = C(0x1E2432), armourLight = C(0x4A5670)
    let ring = C(0x9AA2B4), ringDark = C(0x5E6678), boot = C(0x16161B)
    let grenade = C(0x4A6A2E), grenadeDark = C(0x2E4A1A), metal = C(0xC8CCD4)
    let sig = p.signature
    let reaching = sig.map { ($0 > 0.06 && $0 < 0.2) || ($0 > 0.82 && $0 < 0.94) } ?? false
    let admiring = sig.map { $0 >= 0.2 && $0 <= 0.82 } ?? false

    drawLegs(c, Look(leg: armour), step: p.step)
    drawShoes(c, step: p.step, boot, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: armour))
    // The potato dome on top of the body, a few lumps on it.
    c.pattern(18, 20, [
        "......oooooooo......",
        "...ooooooooooooooS..",
        ".ooooooooooooooooooS",
        "oooooooooooooooooooS",
        "oooooooooooooooooooS",
        "oooooooooooooooooooS",
    ], ["o": clawdOrange, "S": clawdShade])
    c.px(25, 21, C(0xF0A080)); c.px(26, 21, C(0xF0A080)); c.px(21, 23, C(0xF0A080))
    c.px(31, 22, clawdShade); c.px(28, 24, clawdShade)
    // The heavy brow, the ears, the mouth.
    c.rect(20, 27, 5, 1, clawdShade); c.rect(30, 27, 5, 1, clawdShade)
    c.rect(17, 28, 1, 3, clawdShade)
    c.rect(26, 31, 4, 1, clawdShade)
    // The armour: collar ring, quilted suit, the probic vent.
    c.rect(17, 33, 21, 2, ring); c.rect(17, 34, 21, 1, ringDark)
    c.rect(18, 35, 20, 3, armour)
    for x in [21, 25, 29, 33] { c.rect(x, 35, 1, 3, armourLight) }
    c.rect(37, 35, 1, 3, armourDark)
    c.rect(15, 32, 2, 2, C(0xB8A060)); c.px(15, 32, C(0xE8D890))
    if !(reaching || admiring) { c.rect(32, 36, 2, 2, grenade); c.px(32, 36, grenadeDark); c.px(33, 35, metal) }

    if let s = sig, admiring {
        // Held up near his face, gazed at fondly; a glint now and then.
        c.rect(38, 29, 3, 4, armour)
        c.rect(39, 25, 3, 3, grenade); c.px(39, 27, grenadeDark); c.px(41, 25, C(0x6A8A4A))
        c.px(40, 24, metal); c.px(41, 23, metal)
        if Int(s * 20) % 3 == 0 { c.px(43, 24, white); c.px(43, 22, white.alpha(0.6)) }
        return
    }
    if reaching {
        c.rect(35, 34, 3, 4, armour); c.rect(33, 36, 2, 2, grenade)
        return
    }
    // The blaster rifle, stock under the arm.
    c.oy += p.gunY
    let gun = C(0x3A3A42), gunLight = C(0x6A6A78)
    c.rect(35, 33, 4, 2, gun)
    c.rect(38, 33, 3, 3, armour)
    c.rect(39, 32, 10, 2, gun); c.rect(40, 32, 8, 1, gunLight); c.rect(41, 34, 2, 2, gun)
    c.px(49, 32, C(0xE84A2A))
}

// MARK: - Bill Pans

/// Bill Pans: Clawd under a big round afro, a denim jacket open over a bright yellow tee, white trainers. She points the
/// way, waves you over and cheers with both arms up.
private func drawBill(_ c: PixelCanvas, _ p: Pose) {
    let denim = C(0x4A6A9A), denimDark = C(0x34507A), stitch = C(0x8AA8D0), tee = C(0xF0C83A)
    let hair = C(0x241610), hairLight = C(0x46301E)
    let g = gesture(p)
    drawLegs(c, Look(leg: C(0x2A2A34)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xE8E8EC), sole: C(0xB8B8C0))
    c.oy += p.breathe
    drawBody(c, Look(arm: denim), armRight: g == .point ? 1 : 0)
    // The jacket.
    c.rect(18, 33, 20, 5, denim)
    c.rect(24, 33, 8, 5, tee)
    c.rect(22, 33, 2, 2, denimDark); c.rect(32, 33, 2, 2, denimDark)     // collar
    c.rect(23, 33, 1, 5, stitch); c.rect(32, 33, 1, 5, stitch)
    c.rect(19, 35, 3, 1, stitch); c.rect(34, 35, 3, 1, stitch)            // pockets
    c.rect(37, 33, 1, 5, denimDark); c.rect(18, 37, 20, 1, denimDark)
    // The afro.
    c.pattern(15, 14, [
        "........HHHHHHHHHH........",
        ".....HHHHHHhHHHHHHHH......",
        "...HHHhHHHHHHHHHhHHHHH....",
        "..HHHHHHHHHhHHHHHHHHHHH...",
        ".HHHhHHHHHHHHHHHHHHhHHHH..",
        ".HHHHHHHHhHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHhHHHHHHHHH",
        "HHhHHHHHHHHHHHHHHHHHHHhHHH",
        "HHHHHHHHhHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHhHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHH...HHHHHHHHHHHHHHHHHH",
        "HHHH...............HHHHHHH",
        "HHHH.................HHHHH",
        ".HHH.................HHHH.",
        "..HH..................HH..",
        "...H..................H...",
    ], ["H": hair, "h": hairLight])
    drawGesture(c, g, t: p.t, sleeve: denim)
}

// MARK: - Nardoll

/// Nardoll: the butler. Bald Clawd with a gingery beard along the jaw, a black frock coat over a grey waistcoat, a crisp
/// white collar and a little black bow tie, a white napkin folded over his left arm.
private func drawNardoll(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x23232C), coatDark = C(0x15151B), waist = C(0x5A5A66), shirt = C(0xF2F0EA), beard = C(0x9A5A2A)
    let g = gesture(p)
    drawLegs(c, Look(leg: coat), step: p.step)
    drawShoes(c, step: p.step, C(0x0E0E12))
    c.oy += p.breathe
    drawBody(c, Look(arm: coat), armRight: g == .point ? 1 : 0)
    drawBaldHead(c)
    // The beard: sideburns into a short beard round the jaw.
    c.rect(18, 29, 2, 4, beard); c.rect(36, 29, 2, 4, beard)
    c.rect(20, 32, 16, 1, beard); c.rect(25, 31, 6, 1, beard.alpha(0.7))
    // The coat, waistcoat, collar and bow tie.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 33, 8, 5, waist)
    c.rect(25, 33, 6, 1, shirt)
    c.rect(26, 34, 4, 1, ink); c.rect(27, 34, 2, 1, C(0x3A3A44))
    c.px(27, 36, C(0xB8B8C0)); c.px(28, 36, C(0xB8B8C0))
    c.rect(23, 33, 1, 5, coatDark); c.rect(32, 33, 1, 5, coatDark)
    c.rect(37, 33, 1, 5, coatDark)
    // The napkin over his arm.
    c.rect(14, 34, 4, 2, shirt); c.rect(14, 36, 2, 2, shirt); c.px(15, 37, C(0xD0CEC8))
    drawGesture(c, g, t: p.t, sleeve: coat)
}

// MARK: - Yaz Kahn

/// Yaz Kahn: the police officer. Clawd with long black hair swept to one side and falling past her shoulders, a navy
/// uniform under a hi-vis yellow vest with silver bands, a radio clipped at her chest, black boots.
private func drawYaz(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x1E2840), vis = C(0xD8E83A), visDark = C(0xA8B828), band = C(0xD0D4DC)
    let hair = C(0x16100C), hairLight = C(0x34261C)
    let g = gesture(p)
    drawLegs(c, Look(leg: navy), step: p.step)
    drawShoes(c, step: p.step, C(0x0E0E12))
    c.oy += p.breathe
    drawBody(c, Look(arm: navy), armRight: g == .point ? 1 : 0)
    // The vest over the uniform.
    c.rect(18, 33, 20, 5, vis)
    c.rect(26, 33, 4, 2, navy); c.px(27, 35, navy)
    c.rect(18, 36, 20, 1, band)
    c.rect(37, 33, 1, 5, visDark); c.rect(18, 37, 20, 1, visDark)
    c.rect(31, 33, 2, 3, C(0x22222A)); c.px(31, 32, C(0x22222A)); c.px(32, 34, C(0x6A6A78))   // radio
    // The hair.
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "...HHHHHhHHHHHHHHHHH....",
        "..HHHHHHHHHHHhHHHHHHH...",
        ".HHHhHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHhHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHH......HHHHHHH",
        "HHHHH...............HHHH",
        "HHH..................HHH",
        "HHH..................HHH",
        "HHH..................HHH",
        "HHH..................HHH",
        "HhH..................HHH",
        "HHH..................HhH",
        ".HH..................HH.",
        ".HH...................H.",
    ], ["H": hair, "h": hairLight])
    drawGesture(c, g, t: p.t, sleeve: navy)
}

// MARK: - Graham O'Brine

/// Graham O'Brine: bald Clawd, older, with a trim grey beard and grey tufts over the ears, thin half-rim glasses, a
/// navy bomber jacket zipped open over a pale pink shirt.
private func drawGraham(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x34425E), jacketDark = C(0x232E44), shirt = C(0xE8C8C4), grey = C(0xC8C8C2), frame = C(0x3A3A42)
    let g = gesture(p)
    drawLegs(c, Look(leg: C(0x5A5248)), step: p.step)
    drawShoes(c, step: p.step, C(0x3A2A1E))
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: g == .point ? 1 : 0)
    drawBaldHead(c)
    // Grey tufts and the beard.
    c.rect(18, 27, 1, 3, grey); c.rect(19, 28, 1, 1, grey)
    c.rect(18, 30, 2, 3, grey); c.rect(36, 29, 2, 4, grey)
    c.rect(20, 32, 16, 1, grey); c.rect(25, 31, 6, 1, grey)
    // The glasses: top rims and sides, a bridge.
    for x0 in [21, 31] {
        c.rect(x0, 28, 4, 1, frame); c.rect(x0, 28, 1, 3, frame); c.rect(x0 + 3, 28, 1, 3, frame)
    }
    c.rect(25, 29, 6, 1, frame)
    // The bomber jacket.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, shirt); c.rect(26, 33, 4, 1, C(0xD0A8A4))
    c.rect(18, 33, 20, 1, jacketDark); c.rect(25, 33, 6, 1, shirt)
    c.rect(24, 34, 1, 4, C(0x8A8E98)); c.rect(31, 34, 1, 4, C(0x8A8E98))   // the zip
    c.rect(18, 37, 20, 1, jacketDark); c.rect(37, 33, 1, 5, jacketDark)
    drawGesture(c, g, t: p.t, sleeve: jacket)
}

// MARK: - Ryan Sinclare

/// Ryan Sinclare: Clawd with close-cropped black hair, an olive bomber jacket over a grey hoodie (the hood round his
/// neck, its strings hanging), jeans and white trainers.
private func drawRyan(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x5E6640), jacketDark = C(0x444A2C), hood = C(0x8A8A94), hoodDark = C(0x6A6A74)
    let hair = C(0x141010), hairLight = C(0x2E2622)
    let g = gesture(p)
    drawLegs(c, Look(leg: C(0x3A4A6A)), step: p.step)
    drawTrainers(c, step: p.step, upper: C(0xF2F2F4), sole: C(0xC8C8CE))
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: g == .point ? 1 : 0)
    // The crop.
    c.pattern(17, 22, [
        "...HHHHHHHHHHHHHH....",
        ".HHHHhHHHHHHHhHHHHH..",
        "HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHH",
        "HHH...............HHH",
        "HH.................HH",
    ], ["H": hair, "h": hairLight])
    // The jacket over the hoodie, the hood round his neck.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(24, 33, 8, 5, hood)
    c.rect(20, 32, 16, 2, hood); c.rect(20, 33, 16, 1, hoodDark)
    c.px(26, 34, white); c.px(26, 35, white); c.px(29, 34, white); c.px(29, 35, white); c.px(29, 36, white)
    c.rect(23, 34, 1, 4, jacketDark); c.rect(32, 34, 1, 4, jacketDark)
    c.rect(18, 37, 20, 1, jacketDark); c.rect(37, 33, 1, 5, jacketDark)
    drawGesture(c, g, t: p.t, sleeve: jacket)
}

// MARK: - Dan Louis

/// Dan Louis, from Liverpool: Clawd with short dark hair and a dark beard, a brown suede jacket over a cream jumper,
/// and a red scarf, its ends hanging down his front.
private func drawDan(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x7A5A3A), jacketDark = C(0x5A4028), jumper = C(0xE6DCC6), scarf = C(0xC8202A), scarfDark = C(0x8A1418)
    let hair = C(0x2A1E18), hairLight = C(0x46342A)
    let g = gesture(p)
    drawLegs(c, Look(leg: C(0x2E3448)), step: p.step)
    drawShoes(c, step: p.step, C(0x2A1E16))
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: g == .point ? 1 : 0)
    // The hair, the beard.
    c.pattern(17, 22, [
        "....HHHHHHHHHHHHH....",
        "..HHHHhHHHHHHHHhHHH..",
        ".HHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHhHHHHHHHHHHHHH",
        "HHHHHH.........HHHHHH",
        "HHH...............HHH",
        "HH.................HH",
    ], ["H": hair, "h": hairLight])
    c.rect(18, 29, 2, 4, hair); c.rect(36, 29, 2, 4, hair)
    c.rect(20, 32, 16, 1, hair); c.rect(25, 31, 6, 1, hair)
    // The jacket, jumper and scarf.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(24, 33, 8, 5, jumper)
    c.rect(22, 33, 12, 1, scarf); c.rect(22, 33, 12, 1, scarf)
    c.rect(25, 34, 2, 4, scarf); c.rect(29, 34, 2, 3, scarf)
    c.px(25, 36, white); c.px(26, 36, white); c.px(29, 35, white); c.px(30, 35, white)   // the stripes
    c.rect(25, 37, 2, 1, scarfDark)
    c.rect(23, 33, 1, 5, jacketDark); c.rect(32, 34, 1, 4, jacketDark)
    c.rect(18, 37, 20, 1, jacketDark); c.rect(37, 33, 1, 5, jacketDark)
    drawGesture(c, g, t: p.t, sleeve: jacket)
}

// MARK: - Ruby Monday

/// Ruby Monday: Clawd with a dark brown bob and a blunt fringe, a red coat over a cream jumper, little black boots.
/// Signature: snow falls around her: she looks up, one hand held out to catch it, and the flakes settle on her hair.
private func drawRuby(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xA02A30), coatDark = C(0x6E1A1E), jumper = C(0xEDE4D2)
    let hair = C(0x3A2418), hairLight = C(0x5A3A26)
    let snowing = p.signature.map { $0 > 0.04 && $0 < 0.96 } ?? false
    var g = gesture(p)
    if snowing { g = .rest }
    drawLegs(c, Look(leg: C(0x2A2A30)), step: p.step)
    drawShoes(c, step: p.step, C(0x101014), rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: coat, eye: snowing ? nil : ink), armRight: g == .point ? 1 : 0)
    if snowing {
        // Looking up.
        c.rect(22, 28, 2, 2, ink); c.rect(32, 28, 2, 2, ink)
    }
    // The coat and jumper.
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 6, 5, jumper); c.rect(25, 33, 6, 1, C(0xD6CCB8))
    c.rect(24, 33, 1, 5, coatDark); c.rect(31, 33, 1, 5, coatDark)
    c.px(33, 35, C(0x2A1414)); c.px(33, 37, C(0x2A1414))
    c.rect(18, 37, 20, 1, coatDark); c.rect(37, 33, 1, 5, coatDark)
    // The bob.
    c.pattern(16, 20, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHhHHHHHHHHHH...",
        "..HHHHHHHHHHHhHHHHHH..",
        ".HHHhHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHhHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHH..............HHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHh................hHH",
        ".Hh................hH.",
    ], ["H": hair, "h": hairLight])
    guard let s = p.signature, snowing else {
        drawGesture(c, g, t: p.t, sleeve: coat)
        return
    }
    // A hand out, palm up.
    c.rect(38, 32, 4, 2, coat); c.rect(42, 31, 2, 2, clawdOrange)
    // Snow on her hair, building up.
    let settled = Int(min(1, s / 0.6) * 6)
    for i in 0..<settled { c.px(19 + i * 3, 20 + (i % 2 == 0 ? 1 : 0), white) }
    // The flakes falling around her.
    let fade = s < 0.12 ? s / 0.12 : (s > 0.85 ? (0.96 - s) / 0.11 : 1)
    for i in 0..<16 {
        let x = 6 + Int(noise(i * 3 + 1) * 56) + Int((sin(p.t * 1.6 + Double(i)) * 1.5).rounded())
        let y = Int(frac(noise(i * 5 + 2) + p.t * (0.18 + 0.12 * noise(i))) * 46)
        let a = max(0, fade) * (0.6 + 0.4 * noise(i + 9))
        c.px(x, y, white.alpha(a))
        if i % 3 == 0 { c.px(x - 1, y, white.alpha(a * 0.4)); c.px(x + 1, y, white.alpha(a * 0.4)) }
    }
}

// MARK: - Belinda Chandler

/// Belinda Chandler: the nurse. Clawd with dark hair pulled back into a high bun, a navy nurse's tunic with white
/// piping round the collar and pocket, a silver fob watch pinned at her chest, dark trousers and white clogs.
private func drawBelinda(_ c: PixelCanvas, _ p: Pose) {
    let tunic = C(0x1E3A7A), tunicDark = C(0x142A5A), piping = C(0xF2F0EA)
    let hair = C(0x1A120E), hairLight = C(0x34241A)
    let g = gesture(p)
    drawLegs(c, Look(leg: C(0x1E2232)), step: p.step)
    drawShoes(c, step: p.step, C(0xF2F2F4))
    c.oy += p.breathe
    drawBody(c, Look(arm: tunic), armRight: g == .point ? 1 : 0)
    // The tunic.
    c.rect(18, 33, 20, 5, tunic)
    c.rect(24, 33, 8, 1, piping); c.px(25, 34, piping); c.px(30, 34, piping); c.rect(26, 35, 4, 1, piping)
    c.rect(26, 34, 4, 1, clawdOrange)
    c.rect(19, 35, 4, 1, piping)
    c.px(33, 34, C(0xC8CCD4)); c.rect(33, 35, 2, 2, C(0xD8DCE4)); c.px(33, 35, C(0x6A6E78))   // fob watch
    c.rect(18, 37, 20, 1, tunicDark); c.rect(37, 33, 1, 5, tunicDark)
    // The hair, scraped back, and the bun.
    c.pattern(17, 16, [
        ".....BBBBBB..........",
        "....BBBbBBBB.........",
        "....BBBBBBbB.........",
        ".....BBBBBB..........",
        "......BBBB...........",
        "....HHHHHHHHHHHH.....",
        "..HHHHHhHHHHHHHHHH...",
        ".HHHHHHHHHHHHhHHHHH..",
        "HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHH",
        "HHHH............HHHHH",
        "HH...............HHHH",
        "HH.................HH",
    ], ["H": hair, "h": hairLight, "B": hair, "b": hairLight])
    drawGesture(c, g, t: p.t, sleeve: tunic)
}

// MARK: - Kate Stewed

/// Kate Stewed of UNIT: Clawd with a blonde side-parted bob, a black trouser suit over a white shirt, the UNIT badge
/// on her lapel, and a pistol in her hand.
private func drawKate(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1E26), suitDark = C(0x121218), shirt = C(0xF2F0EA)
    let hair = C(0xE0C47E), hairLight = C(0xF4E0A8), hairDark = C(0xB8984E)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawShoes(c, step: p.step, C(0x0A0A0E))
    c.oy += p.breathe
    drawBody(c, Look(arm: suit))
    // The suit.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 5, shirt); c.rect(27, 35, 2, 3, C(0xE0DED8))
    c.rect(24, 33, 1, 4, C(0x3A3A46)); c.rect(31, 33, 1, 4, C(0x3A3A46))   // lapels
    c.rect(21, 34, 2, 2, C(0xC8CCD4)); c.px(21, 34, C(0x3A5AA8))           // UNIT badge
    c.rect(18, 37, 20, 1, suitDark); c.rect(37, 33, 1, 5, suitDark)
    // The bob, parted on the left, longer at the front.
    c.pattern(16, 21, [
        "....hHHHHHHHHHHHH.....",
        "..HHHhHHHHHHhhHHHHH...",
        ".HHHHHhHHHHHHHHHHHHH..",
        "HHHHHHhHHHHHHHHHHhHHH.",
        "HHHHHHH.hHHHHHHHHHHHHH",
        "HHHHH........hHHHHHHHH",
        "HHH...............HHHH",
        "HHH................HHH",
        "HHH................HHH",
        "HHd................dHH",
        "HHd................dHH",
        ".Hd.................H.",
    ], ["H": hair, "h": hairLight, "d": hairDark])
    if p.cheering {
        c.rect(15, 25, 3, 8, suit); c.rect(15, 23, 3, 2, clawdOrange)
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, suit)
    drawPistol(c, x: 40, y: 31)
}

// MARK: - Osgoode

/// Osgoode: Clawd with a brown ponytail and fringe, thick black glasses, a white lab coat, and the long multicolour
/// striped scarf wound round her neck, one end down her front and the other trailing to the ground behind.
/// Signature: a puff on her inhaler, then she flings the scarf's end back over her shoulder.
private func drawOsgoode(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xEEEEF2), coatShade = C(0xC8C8D2), top = C(0x3A3A4A)
    let hair = C(0x5A3A24), hairLight = C(0x7A5234)
    let stripes = [C(0x8A3A2A), C(0xC8A040), C(0x6A7A3A), C(0xB89A70), C(0x5A3A5A), C(0xC86A3A)]
    let sig = p.signature
    let puffing = sig.map { $0 > 0.06 && $0 < 0.5 } ?? false
    let tossT: Double? = sig.flatMap { $0 >= 0.54 && $0 < 0.94 ? ($0 - 0.54) / 0.4 : nil }
    var g = gesture(p)
    if puffing || tossT != nil { g = .rest }

    // The back end of the scarf, trailing behind her to the ground.
    let backLen = tossT.map { $0 > 0.5 ? 2 : 0 } ?? 0
    if !seatedPose {
        for y in 33...(43 - backLen) {
            let x = 15 - (y - 33) / 4 - backLen
            c.rect(x, y, 2, 1, stripes[(y / 2) % stripes.count])
        }
    } else {
        c.rect(14, 33, 2, 5, stripes[0]); c.rect(14, 35, 2, 1, stripes[1])
    }
    drawLegs(c, Look(leg: C(0x2A2A36)), step: p.step)
    drawShoes(c, step: p.step, C(0x4A2A1E))
    c.oy += p.breathe
    drawBody(c, Look(arm: coat), armRight: g == .point ? 1 : 0)
    // The lab coat over a dark top.
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 6, 5, top)
    c.rect(24, 34, 1, 4, coatShade); c.rect(31, 34, 1, 4, coatShade)
    c.rect(33, 35, 3, 1, coatShade); c.px(34, 34, C(0x3A5AA8))   // a pen in the pocket
    c.rect(18, 37, 20, 1, coatShade); c.rect(37, 33, 1, 5, coatShade)
    // The scarf round her neck.
    for x in 19...36 { c.px(x, 33, stripes[(x / 2) % stripes.count]) }
    // The front end, hanging down, lifted, or flung back.
    if let k = tossT {
        if k < 0.5 {
            let lift = Int(k / 0.5 * 4)
            for i in 0..<6 { c.rect(27 + i, 34 - (i * lift) / 5, 1, 2, stripes[i % stripes.count]) }
        }
    } else {
        for y in 34...40 { c.rect(27, y, 2, 1, stripes[(y + 1) % stripes.count]) }
        c.px(27, 41, stripes[0]); c.px(28, 41, stripes[2])
    }
    // The hair: fringe and a ponytail out the back.
    c.pattern(13, 20, [
        "........HHHHHHHHHHHH.....",
        "......HHHHHhHHHHHHHHHH...",
        ".....HHHHHHHHHHHhHHHHHH..",
        "....HHHHhHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHhHHHHHHHHHHHHHHHHHHHHHH",
        ".HHHHHHHH.hHHHHHHH..HHHHH",
        ".HhH.HHH.............HHHH",
        "..HH.HH...............HHH",
        "..H..HH...............HHH",
        "......H................HH",
    ], ["H": hair, "h": hairLight])
    drawSpecs(c)

    if let s = sig, puffing {
        // The inhaler up to her mouth, a puff of mist.
        c.rect(38, 30, 3, 3, coat); c.rect(37, 31, 1, 2, coat)
        c.rect(34, 31, 3, 2, C(0x3A6AC8)); c.px(36, 30, C(0x8AA8E0))
        if s > 0.22 && s < 0.4 {
            let f = (s - 0.22) / 0.18
            for i in 0..<4 {
                let x = 35 + Int(Double(i) * 2 * f), y = 30 - Int(f * 3) - (i % 2)
                c.px(x, y, white.alpha(0.7 * (1 - f)))
            }
        }
        return
    }
    if let k = tossT {
        if k < 0.5 {
            c.rect(38, 32, 3, 3, coat); c.rect(41, 32, 2, 2, clawdOrange)
        } else {
            // Flung back: a loop over the shoulder.
            let f = (k - 0.5) / 0.5
            c.rect(38, 28, 3, 5, coat); c.rect(38, 26, 3, 2, clawdOrange)
            if f < 0.6 {
                // An arc from her hand, up over her head, down behind.
                for i in 0..<12 {
                    let y = 26 - Int((sin(Double(i) / 11 * .pi) * 10).rounded())
                    c.rect(38 - i * 2, y, 2, 2, stripes[i % stripes.count])
                }
            }
        }
        return
    }
    drawGesture(c, g, t: p.t, sleeve: coat)
}
