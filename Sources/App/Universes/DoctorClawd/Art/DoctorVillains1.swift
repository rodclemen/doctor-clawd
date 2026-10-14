import Foundation

// Villains: the monsters. Clawd in costume here too, or Clawd inside the costume: a Dalick's casing is Clawd orange.

let doctorVillains1: [DoctorVillain: Persona] = [
    .dalick: Persona(name: "Dalick", weapon: .blaster, motion: .hover, shot: .beam(core: C(0xF0FAFF), glow: C(0x4AB8FF)),
                  armoured: true, canSit: false, muzzle: (46, 29), handGun: false, headTop: 12, signature: 2.4,
                  callout: "EXTERMINATE!",
                  draw: drawDalick),
]

// MARK: - Dalick

/// A Dalick: Clawd's orange as the casing. The skirt flares down to the base, studded with rows of hemispheres; the
/// shoulder section carries the gunstick and the plunger arm; the slatted neck rings turn under the dome, with its two
/// lamps and the eyestalk's blue eye. It glides (never walks) and bullets glance off it. The lamps flash as it fires and
/// as it shouts. Signature: it looks about, the eyestalk sweeping up and down, and shouts, the lamps flashing.
private func drawDalick(_ c: PixelCanvas, _ p: Pose) {
    let casing = clawdOrange, shade = clawdShade, dark = C(0x8A3E26), bronze = C(0xC8A04A), bronzeDark = C(0x8E6E2A)
    let metal = C(0x3A3A42), metalLight = C(0x6A6A78), eye = C(0x6AC8FF)
    let sig = p.signature
    let shouting = (sig.map { $0 > 0.5 && $0 < 0.95 } ?? false) || p.fire.map { frac($0.t / p.firePeriod) < 0.3 } ?? false
    let flash = shouting && Int(p.t * 8) % 2 == 0
    // The eyestalk: a little up and down while it looks about.
    let look: Int = sig.map { s -> Int in s < 0.5 ? Int(sin(s / 0.5 * 2 * .pi).rounded()) : 0 } ?? 0

    // The base and the skirt, wider at the bottom.
    c.rect(15, 42, 27, 2, metal); c.rect(15, 42, 27, 1, metalLight)
    for y in 31...41 {
        let k = (y - 31) / 4
        c.rect(19 - k, y, 19 + k * 2, 1, casing)
        c.px(37 + k, y, shade); c.px(38 + k, y, shade)
    }
    // Hemispheres: three rows of four.
    for (row, y) in [33, 36, 39].enumerated() {
        for col in 0..<4 {
            let x = 20 - row + col * (5 + (row + 1) / 2)
            c.rect(x, y, 2, 2, dark); c.px(x, y, bronze)
        }
    }
    // The shoulder section and its bronze band.
    c.rect(19, 26, 19, 5, casing); c.rect(37, 26, 1, 5, shade)
    c.rect(19, 30, 19, 1, bronzeDark); c.rect(19, 26, 19, 1, bronze)
    // The plunger arm and the gunstick, forward.
    c.rect(38, 27, 6, 1, metalLight); c.rect(44, 26, 2, 3, metal); c.px(45, 27, C(0x1E1E24))
    c.rect(38, 29, 8, 1, metal); c.px(46, 29, metalLight)
    for x in [40, 42] { c.px(x, 28, metalLight); c.px(x, 30, metalLight) }
    // The neck: slats over a dark mesh.
    c.rect(21, 20, 15, 6, C(0x2A2A30))
    for y in [20, 22, 24] { c.rect(20, y, 17, 1, bronze); c.px(36, y, bronzeDark) }
    for x in stride(from: 22, to: 36, by: 3) { c.rect(x, 21, 1, 5, C(0x46464E)) }
    // The dome, its lamps and the eyestalk.
    for dy in 0...6 {   // the top half of an ellipse, over the neck
        let hw = Int((7 * (1 - Double(dy * dy) / 36).squareRoot()).rounded())
        c.rect(28 - hw, 19 - dy, hw * 2 + 1, 1, casing)
    }
    c.rect(21, 19, 15, 1, shade)
    c.rect(20, 20, 17, 1, bronze)
    c.px(25, 14, C(0xF0A080)); c.px(26, 14, C(0xF0A080))
    let lamp = flash ? C(0xFFF6C8) : C(0xC8A87A)
    for x in [22, 34] {
        c.rect(x, 13, 1, 3, lamp); if flash { c.px(x, 12, C(0xFFF6C8, 0.6)) }
    }
    // The eyestalk leaves the dome at row 16 and tips up or down at its far end; two rings round it.
    let tipY = 16 + look
    for x in 35...41 { c.px(x, x > 38 ? tipY : 16, metal) }
    for x in [37, 39] { c.px(x, 15, metalLight); c.px(x, 17, metalLight) }
    c.rect(42, tipY - 1, 2, 3, metal); c.px(43, tipY, p.hit ? C(0xFF4A4A) : eye)
}
