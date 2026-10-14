import Foundation

/// How long a regeneration's golden flare plays over the new Doctor, in seconds.
let regenerationFlare = 3.0

/// A regeneration, `k` 0…1 through it, drawn over a Doctor already in the next face: golden fire streaming up out of
/// the head and the hands, brightest early on (hiding the change of face) and dying away to a few sparks.
func drawRegeneration(_ c: PixelCanvas, k: Double, t: Double) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let strength = k < 0.15 ? k / 0.15 : max(0, 1 - (k - 0.15) / 0.85)
    guard strength > 0.02 else { return }
    let core = C(0xFFF6D8), gold = C(0xFFC84A), amber = C(0xFF8A2A)
    // The body lit gold.
    for y in 18..<44 {
        for x in 12..<44 where c.isDrawn(x, y) && noise(x * 31 + y * 17 + Int(t * 12)) < 0.5 * strength {
            c.px(x, y, gold.alpha(0.55 * strength))
        }
    }
    // The streams: up out of the head, and out and up from each hand, flickering.
    let sources: [(x: Double, y: Double, dx: Double, dy: Double)] = [(28, 20, 0, -1), (16, 34, -0.7, -0.7), (40, 34, 0.7, -0.7)]
    for (n, s) in sources.enumerated() {
        for i in 0..<5 {
            let wobble = sin(t * 18 + Double(i * 3 + n)) * 0.35
            let len = (n == 0 ? 16.0 : 11.0) * strength * (0.6 + 0.4 * noise(i * 7 + n + Int(t * 10)))
            let a = atan2(s.dy, s.dx) + (Double(i) - 2) * 0.22 + wobble * 0.3
            let end = (s.x + cos(a) * len, s.y + sin(a) * len)
            c.glowLine(s.x, s.y, end.0, end.1, core: i == 2 ? core : gold, glow: amber.alpha(0.6 * strength),
                       coreR: 0.6, glowR: 1.6, strength: strength)
        }
    }
    // Sparks drifting up.
    for i in 0..<6 {
        let f = frac(t * 0.9 + Double(i) / 6)
        let x = 18 + Int(noise(i * 13) * 20) + Int(sin(f * 6 + Double(i)) * 2), y = 30 - Int(f * 26)
        c.px(x, y, (i % 2 == 0 ? core : gold).alpha(strength * (1 - f)))
    }
}
