import Foundation

// The ships that come to pick someone up when their agent is done (`Cast.ride`): the Millennium Falcon for Han, the
// Quinjet for the Avengers, the Milano for the Guardians, the Javelin for the Justice League, the Batwing for the
// Bat-family, the TARDIS for the Doctors and their companions. Drawn nose to the right on a `Ride.width`×`Ride.height` canvas, sitting on its bottom row when landed;
// the boarding ramp comes down to the left of centre, its foot about 14 px left of the middle.

extension Ride {
    static let width = 66, height = 29
}

/// `ramp` 0…1 lowers the boarding ramp, `engines` lights the thrusters, `gear`: landing gear down.
func drawRide(_ c: PixelCanvas, _ ride: Ride, ramp: Double, engines: Bool, gear: Bool) {
    switch ride {
    case .falcon: drawFalcon(c, ramp: ramp, engines: engines, gear: gear)
    case .quinjet: drawQuinjet(c, ramp: ramp, engines: engines, gear: gear)
    case .milano: drawMilano(c, ramp: ramp, engines: engines, gear: gear)
    case .javelin: drawJavelin(c, ramp: ramp, engines: engines, gear: gear)
    case .batwing: drawBatwing(c, ramp: ramp, engines: engines, gear: gear)
    case .tardis: drawTardis(c, door: ramp, lamp: engines)
    }
}

/// The hull's outline at column `x`, read off a polyline of (x, y) points (straight between them).
private func profile(_ x: Int, _ pts: [(Double, Double)]) -> Int {
    let fx = Double(x)
    for i in 1..<pts.count where fx <= pts[i].0 {
        let (a, b) = (pts[i - 1], pts[i])
        return Int((a.1 + (b.1 - a.1) * (fx - a.0) / (b.0 - a.0)).rounded())
    }
    return Int(pts[pts.count - 1].1.rounded())
}

/// A hull filled column by column between the `top` and `bottom` outlines, lit along its spine and shaded
/// along its belly.
private func hull(_ c: PixelCanvas, x0: Int, x1: Int, top: [(Double, Double)], bottom: [(Double, Double)],
                  body: Px, light: Px, dark: Px) {
    for x in x0...x1 {
        let t = profile(x, top), b = profile(x, bottom)
        guard b >= t else { continue }
        c.rect(x, t, 1, b - t + 1, body)
        c.px(x, t, light)
        c.px(x, b, dark)
        if b - t > 4 { c.px(x, b - 1, dark) }
    }
}

/// The boarding ramp, hinged under the hull at (`hx`, `hy`) and swinging down to its foot on the ground about 14 px
/// left of centre; a warm light spills from the hold behind it.
private func drawRamp(_ c: PixelCanvas, ramp: Double, hx: Double, hy: Double, plate: Px, edge: Px) {
    guard ramp > 0 else { return }
    let foot = (x: 19.0, y: 27.5)
    let closed = atan2(0.0, -1.0), open = atan2(foot.y - hy, foot.x - hx)
    let a = closed + (open - closed) * ramp, len = hypot(foot.x - hx, foot.y - hy)
    let tip = (x: hx + cos(a) * len, y: hy + sin(a) * len)
    c.rect(Int(tip.x) + 1, Int(hy) - 3, Int(hx - tip.x) - 1, 3, C(0xFFD890, 0.35 + 0.5 * ramp))   // the lit hold
    c.glowLine(hx, hy, tip.x, tip.y, core: plate, glow: C(0x000000, 0), coreR: 1, glowR: 1.1)
    c.glowLine(hx, hy - 0.6, tip.x, tip.y - 0.6, core: edge, glow: C(0x000000, 0), coreR: 0.35, glowR: 0.4)
}

/// Landing legs with wide feet, standing on the bottom row.
private func drawGear(_ c: PixelCanvas, xs: [Int], from y: Int, strut: Px, foot: Px) {
    for x in xs {
        c.rect(x, y, 1, 27 - y, strut)
        c.rect(x - 1, 27, 3, 1, foot); c.rect(x - 2, 28, 5, 1, foot)
    }
}

/// The Avengers' Quinjet (the films): a matt dark-grey stealth wedge with a sloping glass canopy, a swept wing with
/// its big lift-fan nacelle, twin canted tail fins with the Avengers "A", and blue thrusters at the tail.
private func drawQuinjet(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    let body = C(0x3E434E), light = C(0x6A717E), dark = C(0x252830), panel = C(0x30343D), steel = C(0x8A929E)
    if gear { drawGear(c, xs: [12, 50], from: 22, strut: dark, foot: steel) }
    // The far tail fin, behind
    for y in 4...13 {
        let f = Double(y - 4) / 9
        let l = Int(9 + f * 4), r = Int(13 + f * 9)
        c.rect(l, y, r - l + 1, 1, panel)
    }
    hull(c, x0: 4, x1: 65, top: [(4, 15), (14, 12), (34, 10), (48, 11), (58, 15), (65, 18)],
         bottom: [(4, 20), (9, 23), (50, 23), (59, 21), (65, 19)], body: body, light: light, dark: dark)
    // The near tail fin, canted back, with the "A" in a white roundel
    for y in 2...12 {
        let f = Double(y - 2) / 10
        let l = Int(4 + f * 4), r = Int(8 + f * 10)
        c.rect(l, y, r - l + 1, 1, body)
        c.px(l, y, light)
    }
    c.circle(11, 8, 2, C(0xE8ECF2))
    c.pattern(10, 7, [".K.", "KKK", "K.K"], ["K": C(0x2A3A6A)])
    // Canopy: dark glass along the nose, with a sky-blue glint
    for x in 46...59 {
        let t = profile(x, [(4, 15), (14, 12), (34, 10), (48, 11), (58, 15), (65, 18)])
        c.rect(x, t + 1, 1, 2, C(0x1E2A3A))
        if x > 48 && x < 55 { c.px(x, t + 1, C(0x8AC8F0)) }
    }
    c.rect(14, 17, 34, 1, panel)                                     // panel line down the flank
    for x in stride(from: 18, through: 44, by: 6) { c.px(x, 15, panel) }
    // Wing root and the lift-fan nacelle
    c.pattern(18, 17, [
        "......LLLLLLLLLLLLLLLL......",
        "....BBBBBBBBBBBBBBBBBBBBK...",
        "..BBBBBBBBBBBBBBBBBBBBBBKK..",
        "DDDDDDDDDDDDDDDDDDDDDDDDDDDD",
    ], ["L": light, "B": steel, "K": dark, "D": dark])
    c.rect(41, 18, 2, 2, C(0x16181E))                                // the fan intake
    drawRamp(c, ramp: ramp, hx: 33, hy: 23, plate: panel, edge: steel)
    if engines {
        c.rect(1, 15, 3, 5, C(0x6FB8FF)); c.rect(0, 16, 1, 3, C(0xBFE0FF))
        c.rect(25, 21, 14, 1, C(0x6FB8FF, 0.8))                       // the fan's downwash glow
    }
}

/// The Guardians' Milano (the films): a long blue hull with orange stripes, the bubble cockpit up front, a swept
/// wing rising behind with an engine pod at its tip, a ventral fin, and orange thrusters.
private func drawMilano(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    let body = C(0x2E5AA8), light = C(0x6A96E0), dark = C(0x1C366E), orange = C(0xE8782A), orangeD = C(0xB0561A)
    let steel = C(0x9AA2AE)
    if gear { drawGear(c, xs: [14, 50], from: 22, strut: dark, foot: steel) }
    // The far wing, behind, rising up and back with its engine pod
    c.pattern(14, 2, [
        "..PPPPPP..............",
        ".PPPPPPPP.............",
        "..PPPPPP..............",
        "...WWW................",
        "....WWWWW.............",
        ".....WWWWWWW..........",
        "......WWWWWWWWW.......",
        ".......WWWWWWWWWWW....",
        "........WWWWWWWWWWWWW.",
    ], ["W": dark, "P": C(0x24304A)])
    hull(c, x0: 6, x1: 65, top: [(6, 14), (16, 11), (40, 11), (50, 12), (58, 15), (65, 18)],
         bottom: [(6, 20), (11, 23), (48, 23), (58, 21), (65, 19)], body: body, light: light, dark: dark)
    // Orange stripes down the flank and the nose tip
    for x in 8...62 { c.px(x, profile(x, [(6, 14), (16, 11), (40, 11), (50, 12), (58, 15), (65, 18)]) + 5, orange) }
    for x in 12...56 { c.px(x, profile(x, [(6, 14), (16, 11), (40, 11), (50, 12), (58, 15), (65, 18)]) + 6, orangeD) }
    c.rect(63, 18, 3, 1, orange)
    // The bubble cockpit
    c.ellipse(52, 12, 5, 2, C(0x1E2A3A))
    c.rect(49, 11, 4, 1, C(0xF0C870)); c.px(54, 11, C(0xF0C870))
    c.rect(47, 13, 11, 1, orange)
    // The near wing: swept up and back from the hull, orange on its leading edge, engine pod at the tip
    c.pattern(9, 0, [
        "..PPPPPPPP..............",
        ".PPpppppPPP.............",
        "PPPPPPPPPPPP............",
        ".PPPPPPPPPP.............",
        "...OOOO.................",
        "....WWWOO...............",
        ".....WWWWOO.............",
        "......WWWWWOO...........",
        ".......WWWWWWOO.........",
        "........WWWWWWWOO.......",
        ".........WWWWWWWWOOO....",
        "..........WWWWWWWWWWOOO.",
    ], ["W": body, "O": orange, "P": C(0x3A4458), "p": steel])
    // Ventral fin
    c.pattern(10, 21, ["FFFFFF", ".FFFF.", "..FF.."], ["F": dark])
    for x in stride(from: 20, through: 44, by: 8) { c.rect(x, 16, 1, 3, dark) }   // hull panel seams
    drawRamp(c, ramp: ramp, hx: 33, hy: 23, plate: dark, edge: orange)
    if engines {
        c.rect(3, 15, 3, 5, C(0xFF9A4A)); c.rect(2, 16, 1, 3, C(0xFFE0A0))
        c.rect(6, 2, 3, 3, C(0xFF9A4A)); c.px(5, 3, C(0xFFE0A0))      // the wing pod's thruster
    }
}

/// The Millennium Falcon, nose to the right: the disc, the forward mandibles, the offset cockpit, the radar
/// dish. `ramp` 0…1 lowers the boarding ramp (down and to the left), `engines` lights the blue glow.
private func drawFalcon(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    // Seen slightly from above, so the round saucer, the central hatch and the split front read clearly.
    let hull = C(0xB8B6AC), hullLight = C(0xD2D0C6), hullDark = C(0x8A8880), panel = C(0x6E6C66)
    if gear {
        for gx in [18, 44] { c.rect(gx, 24, 1, 3, hullDark); c.rect(gx - 1, 27, 3, 1, panel) }
    }
    if ramp > 0 {                                                       // boarding ramp, toward the left
        let len = Int((ramp * 9).rounded())
        for k in 0..<len { c.rect(31 - k, 24 + k / 3, 2, 1, hullDark) }
    }
    c.ellipse(32, 18, 28, 7, hullDark)                                  // rim / underside
    c.ellipse(32, 16, 28, 8, hull)                                      // the saucer, seen from above
    c.ellipse(30, 15, 22, 6, hullLight)
    c.circle(30, 15, 4, hull); c.circle(30, 15, 2, panel)               // central hatch
    for (x, y) in [(12, 15), (18, 11), (40, 11), (46, 16), (20, 20), (40, 20), (24, 14), (36, 18)] { c.rect(x, y, 3, 1, panel) }
    // the split front: two mandibles with the cargo gap between them
    c.rect(55, 11, 10, 3, hull); c.rect(55, 18, 10, 3, hull)
    c.rect(55, 14, 7, 4, C(0x2A2A28))
    c.rect(63, 11, 2, 3, hullLight); c.rect(63, 18, 2, 3, hullLight)
    // cockpit off to the side, and the radar dish
    c.rect(46, 6, 10, 3, hull); c.circle(56, 7, 2, hull); c.rect(56, 6, 2, 2, C(0x3A5A7A))
    c.rect(22, 6, 1, 4, panel); c.ellipse(21, 5, 4, 1, hullLight)
    if engines {                                                        // the blue engine glow along the back
        c.rect(3, 12, 2, 9, C(0x6FB8FF)); c.rect(2, 14, 1, 5, C(0xBFE0FF))
    }
}

/// The Justice League's Javelin (the animated series): a sleek silver-grey and white wedge with a big canopy over the
/// nose, angular swept wings with red leading edges, a blue stripe down the flank, a tall swept tail fin with the CL
/// badge, and blue thrusters.
private func drawJavelin(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    let body = C(0xB8BEC8), light = C(0xF2F4F8), dark = C(0x6A727E), panel = C(0x8E96A2), white = C(0xFFFFFF)
    let red = C(0xC8202A), blue = C(0x2A5CC8), glass = C(0x16243C)
    let top: [(Double, Double)] = [(3, 15), (10, 13), (40, 12), (56, 15), (65, 19)]
    if gear { drawGear(c, xs: [13, 50], from: 22, strut: dark, foot: panel) }
    // The far wing, behind: its swept tip shows above the hull
    for k in 0...4 {
        let l = 22 - k * 3, r = 34 - k * 4
        c.rect(l, 13 - k, r - l + 1, 1, panel)
        c.px(r, 13 - k, red); c.px(l, 13 - k, dark)
    }
    hull(c, x0: 3, x1: 65, top: top, bottom: [(3, 20), (8, 23), (52, 23), (60, 21), (65, 19)],
         body: body, light: light, dark: dark)
    // The tail fin, swept back, white on its leading edge, with the CL badge
    for y in 1...13 {
        let f = Double(y - 1) / 12
        let l = Int(3 + f * 2), r = Int(8 + f * 12)
        c.rect(l, y, r - l + 1, 1, body)
        c.px(r, y, light); c.px(l, y, dark)
    }
    c.pattern(5, 6, [
        "RRRRRRR",
        "RWWBWBR",
        "RWBBWBR",
        "RWWBWWR",
        "RRRRRRR",
    ], ["R": red, "B": blue, "W": white])
    // A blue stripe down the flank, and red on the canopy sill and the nose tip
    c.rect(6, 17, 52, 1, blue)
    for x in 41...61 { c.px(x, profile(x, top) + 2, red) }
    c.rect(63, 18, 3, 1, red)
    // The big canopy bubbling up over the nose, with a white frame and a sky glint
    let canopy: [(Double, Double)] = [(40, 12), (44, 9), (52, 9), (61, 17)]
    for x in 41...59 {
        let t = profile(x, canopy), b = profile(x, top) + 1
        guard b >= t else { continue }
        c.rect(x, t, 1, b - t + 1, glass)
        c.px(x, t, light)
    }
    for x in 45...50 { c.px(x, 10, C(0x8AC8F0)) }
    c.px(52, 11, C(0x8AC8F0)); c.px(53, 12, C(0x8AC8F0))
    // The near wing: an angular swept plate, red on its leading edge
    for y in 18...23 {
        let f = Double(y - 18) / 5
        let l = Int(30 - f * 18), r = Int(48 - f * 30)
        c.rect(l, y, r - l + 1, 1, y == 18 ? light : C(0xD8DCE2))
        c.px(l, y, dark)
    }
    c.glowLine(48.5, 18.5, 18.5, 23.5, core: red, glow: C(0x000000, 0), coreR: 0.6, glowR: 0.7)
    for x in stride(from: 16, through: 40, by: 8) { c.px(x, 15, panel) }    // hull panel seams
    drawRamp(c, ramp: ramp, hx: 33, hy: 23, plate: panel, edge: light)
    if engines {
        c.rect(0, 14, 3, 6, C(0x6FB8FF)); c.rect(0, 15, 2, 4, C(0xBFE0FF))
    } else {
        c.rect(2, 15, 1, 5, dark)
    }
}

/// The Batwing: a black jet with a bat-wing silhouette raised over the hull, scalloped along its trailing edge between
/// the bones, a black cowl mask in a yellow oval on the wing, a slit canopy, and amber jets with a blue core.
private func drawBatwing(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    let body = C(0x26282F), light = C(0x4A4F5C), dark = C(0x121317), wing = C(0x2C2F38), bone = C(0x464B58)
    let yellow = C(0xF2C230), steel = C(0x7A808C)
    let top: [(Double, Double)] = [(4, 17), (14, 15), (40, 14), (52, 15), (60, 17), (65, 19)]
    if gear { drawGear(c, xs: [14, 50], from: 22, strut: dark, foot: steel) }
    // The bat wing: leading edge sweeping up and back from the hull to a hooked tip, the trailing edge cut into
    // scallops between the bones
    let lead: [(Double, Double)] = [(0, 0), (8, 1), (24, 4), (40, 9), (50, 15)]
    let base: [(Double, Double)] = [(1, 1), (19, 17)]
    let points: [Int] = [1, 7, 13, 19]                          // where the bones meet the trailing edge
    for x in 0...50 {
        let t = profile(x, lead)
        var b = profile(x, base)
        if x < 1 {
            b = t
        } else if x < 19 {
            let i = min(2, (x - 1) / 6), u = Double(x - points[i]) / Double(points[i + 1] - points[i])
            b -= Int((sin(u * Double.pi) * (i == 0 ? 2.2 : 4.4)).rounded())
        } else {
            b = 17
        }
        guard b >= t else { continue }
        c.rect(x, t, 1, b - t + 1, wing)
        c.px(x, t, light)
    }
    // The bones, from the wing root out to each point of the trailing edge
    for p in points.dropFirst().dropLast() {
        c.glowLine(38, 12, Double(p) + 0.5, Double(profile(p, base)) + 0.2, core: bone, glow: C(0x000000, 0),
                   coreR: 0.45, glowR: 0.5)
    }
    hull(c, x0: 4, x1: 65, top: top, bottom: [(4, 21), (9, 23), (50, 23), (58, 22), (65, 20)],
         body: body, light: light, dark: dark)
    // The emblem on the wing: a black cowl mask in a yellow oval
    c.pattern(19, 5, [
        "..YYYYYYY..",
        ".YYKYYYKYY.",
        "YYKKKKKKKYY",
        ".YKKYKYKKY.",
        "..YYYYYYY..",
    ], ["Y": yellow, "K": dark])
    // Slit canopy with a blue glint, and a yellow pinstripe along the flank
    for x in 46...57 { c.px(x, profile(x, top) + 1, C(0x10161E)) }
    for x in 48...52 { c.px(x, profile(x, top) + 1, C(0x4A90D8)) }
    for x in 8...60 { c.px(x, max(profile(x, top) + 4, 18), x % 6 == 0 ? body : C(0x30333C)) }
    c.rect(62, 19, 3, 1, yellow)
    drawRamp(c, ramp: ramp, hx: 33, hy: 23, plate: dark, edge: yellow)
    if engines {
        c.rect(0, 16, 4, 5, C(0xFFA030)); c.rect(0, 17, 3, 3, C(0xFFE0A0)); c.rect(3, 18, 1, 1, C(0x6FB8FF))
        c.rect(24, 24, 14, 1, C(0x6FB8FF, 0.7))                       // the belly jets' blue downwash
    } else {
        c.rect(3, 17, 1, 4, dark)
    }
}

/// The TARDIS: a blue police box standing on the bottom row, left of centre so whoever boards walks up to its doors
/// (it never flies in: the overlay fades it in and out where it stands, `Ride.materialises`). The lamp on the roof,
/// the POLICE BOX sign, the frosted windows and the panelled doors; `door` 0…1 swings the right-hand door open on the
/// lit interior, `lamp` lights the roof lamp.
private func drawTardis(_ c: PixelCanvas, door: Double, lamp: Bool) {
    let blue = C(0x1C3F94), dark = C(0x15306E), edge = C(0x2E58B8), sign = C(0x101820), glass = C(0xE8F0FF)
    let x0 = 13, w = 18, top = 3
    // The roof stack and the lamp.
    c.rect(x0 + 6, top - 1, 6, 1, blue)
    c.rect(x0 + 8, top - 3, 2, 2, lamp ? C(0xFFF6C8) : C(0xC8D0E0))
    if lamp { c.rect(x0 + 7, top - 4, 4, 1, C(0xFFF6C8, 0.45)); c.rect(x0 + 7, top - 2, 1, 1, C(0xFFF6C8, 0.4)); c.rect(x0 + 10, top - 2, 1, 1, C(0xFFF6C8, 0.4)) }
    c.rect(x0 - 1, top, w + 2, 2, blue); c.rect(x0 - 1, top, w + 2, 1, edge)
    // The body, its corner posts and the sign.
    c.rect(x0, top + 2, w, 29 - top - 4, blue)
    c.rect(x0, top + 2, 2, 29 - top - 4, edge); c.rect(x0 + w - 2, top + 2, 2, 29 - top - 4, dark)
    c.rect(x0 + 1, top + 3, w - 2, 2, sign)
    for x in stride(from: x0 + 2, to: x0 + w - 2, by: 2) { c.px(x, top + 3, glass.alpha(0.85)) }
    // The doors: windows over three panels each, split down the middle.
    let doorY = top + 6, doorH = 29 - doorY - 2
    for side in 0..<2 {
        let dx = x0 + 2 + side * 7
        c.rect(dx + 1, doorY + 1, 5, 3, glass)
        c.rect(dx + 3, doorY + 1, 1, 3, blue); c.rect(dx + 1, doorY + 2, 5, 1, blue)
        for k in 0..<3 { c.rect(dx + 1, doorY + 5 + k * 5, 5, 4, dark) }
    }
    c.rect(x0 + 8, doorY, 2, doorH, dark)
    if door > 0 {
        // The right-hand door swings in on the warm light inside.
        let open = Int((Double(7) * door).rounded())
        c.rect(x0 + 9, doorY, 7, doorH, C(0xFFE8A8, 0.9))
        c.rect(x0 + 9, doorY, 7, 2, C(0xFFF6D8))
        c.rect(x0 + 16 - max(1, 7 - open), doorY, max(1, 7 - open), doorH, blue)
    }
    // The base.
    c.rect(x0 - 1, 27, w + 2, 2, blue); c.rect(x0 - 1, 28, w + 2, 1, dark)
}

extension Ride {
    /// Fades in and out where it stands instead of flying in and away.
    var materialises: Bool { self == .tardis }
}
