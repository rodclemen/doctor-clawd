import Foundation

let doctorScenes1: [Location: Place] = [
    .consoleRoom: Place(name: "The Console Room", panel: 0x0C1A20, still: Scenes.consoleRoom, moving: Scenes.consoleRoomLife),
]

// MARK: - The TARDIS console room

extension Scenes {
    /// Where the console stands: its centre, the top of its deck and its half-width; the rotor's glass column rises
    /// from the deck to `rotorTop`.
    static func consoleFrame(_ c: PixelCanvas, _ g: Int) -> (cx: Int, deck: Int, half: Int, rotorTop: Int, rotorHalf: Int) {
        let s = unit(g), tall = isTall(c)
        let deck = g - 12 * s
        return (c.w / 2, deck, 30 * s, tall ? g / 3 : max(2 * s, deck - 30 * s), 4 * s)
    }

    /// The TARDIS console room: bigger on the inside. Round walls of glowing roundels in a teal gloom, two great coral
    /// struts curving up into the dark, a metal grating underfoot. In the middle stands the six-sided console, its
    /// panels studded with switches, and out of it rises the glass column of the time rotor. On the screen saver the
    /// roundels climb on up to a gallery running round the room.
    static func consoleRoom(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = consoleFrame(c, g)
        c.gradient(0, g, C(0x08141A), C(0x16323C), bands: 8)
        // The roundels, in staggered rows, dimmer further up.
        let step = 14 * s
        var row = 0
        for y in stride(from: g - 8 * s, to: -step, by: -step) {
            let fade = max(0.35, 1 - Double(g - y) / Double(max(g, 1)) * 0.8)
            for x in stride(from: (row % 2) * step / 2 - step, to: c.w + step, by: step) {
                c.circle(x, y, 5 * s, C(0x1E3E48).alpha(fade))
                c.circle(x, y, 4 * s, C(0x2E6A76).alpha(fade))
                c.circle(x, y, 2 * s, C(0x8AE0E8).alpha(fade * 0.55))
            }
            row += 1
        }
        if tall {
            // The gallery: a walkway with its railing round the room, two thirds of the way down.
            let gy = g * 2 / 3
            c.rect(0, gy, c.w, 3 * s, C(0x24424C)); c.rect(0, gy, c.w, s, C(0x5A9AA4))
            c.rect(0, gy - 8 * s, c.w, s, C(0x5A9AA4))
            for x in stride(from: 0, to: c.w, by: 6 * s) { c.rect(x, gy - 8 * s, s, 8 * s, C(0x3E727C)) }
        }
        // The coral struts, curving in from the sides.
        for side in [-1, 1] {
            let baseX = side < 0 ? c.w / 8 : c.w - c.w / 8
            for y in 0..<g {
                let k = Double(g - y) / Double(g)
                let x = baseX - side * Int(k * k * Double(c.w) * 0.12)
                c.rect(x - 3 * s, y, 6 * s, 1, C(0xB8683A))
                c.rect(x - 3 * s, y, s, 1, C(0xE89A62))
                c.rect(x + 2 * s, y, s, 1, C(0x7A4224))
            }
        }
        // The console: six sides seen from the front, three panels showing.
        let deck = f.deck, half = f.half, cx = f.cx
        c.rect(cx - half / 2, deck + 4 * s, half, g - deck - 4 * s, C(0x2A3A40))   // the pedestal
        for (i, x0) in [cx - half, cx - half / 3, cx + half / 3].enumerated() {
            let w = half * 2 / 3
            let col = i == 1 ? C(0x5A7A82) : C(0x46626A)
            c.rect(x0, deck, w, 5 * s, col)
            c.rect(x0, deck, w, s, C(0x9AC8D0))
            c.rect(x0 + w - s, deck, s, 5 * s, C(0x2E444A))
        }
        c.rect(cx - half, deck + 5 * s, half * 2, s, C(0x1E2C32))
        // The rotor's glass column and the ceiling fitting it rises into.
        let rh = f.rotorHalf
        c.rect(cx - rh - s, f.rotorTop, s, deck - f.rotorTop, C(0x8AE0E8, 0.55))
        c.rect(cx + rh, f.rotorTop, s, deck - f.rotorTop, C(0x8AE0E8, 0.55))
        c.rect(cx - rh, f.rotorTop, rh * 2, deck - f.rotorTop, C(0x2E8A9A, 0.25))
        c.rect(cx - rh - 2 * s, f.rotorTop - 2 * s, rh * 2 + 4 * s, 2 * s, C(0x46626A))
        if tall { c.rect(cx - rh, 0, rh * 2, f.rotorTop - 2 * s, C(0x24424C)) }
        // The grating underfoot.
        c.ground(g, C(0x22343A), edge: C(0x6A9AA4), speck: C(0x1A282E), seed: 9)
        for x in stride(from: 0, to: c.w, by: 4 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x1A282E)) }
    }

    /// What moves in the console room: the rotor pumping up and down in its glass column with the glow breathing,
    /// and the console's lights blinking.
    static func consoleRoomLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = consoleFrame(c, g)
        let cx = f.cx, rh = f.rotorHalf, span = f.deck - f.rotorTop
        guard span > 4 * s else { return }
        let pump = 0.5 - 0.5 * cos(t * 2 * .pi / 2.6)
        // The glow, brighter as the rotor rises.
        c.rect(cx - rh, f.rotorTop, rh * 2, span, C(0x6AE8F4, 0.12 + 0.18 * pump))
        // Two stacks of crystal rings, the upper one coming down as the lower one goes up.
        let travel = Double(span) * 0.3
        for (k, base) in [(0, f.deck - 2 * s), (1, f.rotorTop + 2 * s)] {
            let off = Int((k == 0 ? -1.0 : 1.0) * travel * pump)
            for i in 0..<3 {
                let y = base + off + (k == 0 ? -i * 3 * s : i * 3 * s)
                guard y > f.rotorTop, y < f.deck else { continue }
                c.rect(cx - rh + s, y, rh * 2 - 2 * s, s, C(0xC8F4F8, 0.85))
                c.rect(cx - rh + 2 * s, y + s, rh * 2 - 4 * s, s, C(0x4AB8C8, 0.7))
            }
        }
        // The console's lights.
        let deck = f.deck, half = f.half
        for i in 0..<12 {
            let x = cx - half + 2 * s + Int(noise(i * 5 + 1) * Double(half * 2 - 4 * s))
            let y = deck + 2 * s + Int(noise(i * 5 + 2) * Double(2 * s))
            let on = noise(i * 13 + Int(t * (1.5 + noise(i) * 2))) > 0.45
            let col = [C(0xFF6A4A), C(0x6AFF8A), C(0xFFD24A), C(0x6AC8FF)][i % 4]
            if on { c.rect(x, y, s, s, col) }
        }
    }
}
