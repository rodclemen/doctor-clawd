import Foundation

let scenes3: [Location: Place] = [
    .egosPlanet: Place(name: "Egon's Planet", panel: 0x1E2416, still: Scenes.egosPlanet, moving: Scenes.egosMotes),
    .kamarTaj: Place(name: "Kamar-Tajj", panel: 0x241C14, still: Scenes.kamarTaj, moving: Scenes.kamarTajLife),
    .raft: Place(name: "The Raft", panel: 0x16181D, still: Scenes.raft, moving: Scenes.raftLights),
    .battleOfNewYork: Place(name: "Battle of New York", panel: 0x1E1814, still: Scenes.battleOfNewYork,
                            moving: Scenes.battleOfNewYorkInvasion),
    .darkDimension: Place(name: "Darker Dimension", panel: 0x1E0A24, still: Scenes.darkDimension, moving: Scenes.darkDimensionShift),
    .attilan: Place(name: "Atillan", panel: 0x1A1E2A, still: Scenes.attilan, moving: Scenes.attilanMist),
    .savageLand: Place(name: "Savage Lands", panel: 0x14231A, still: Scenes.savageLand, moving: Scenes.savageLandLife),
]

// MARK: - Shared shapes for this file

/// Fills a polygon given in canvas pixels (scanline, even-odd).
fileprivate func s3Poly(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
    guard pts.count >= 3 else { return }
    let ys = pts.map { $0.1 }
    let y0 = max(0, Int(floor(ys.min() ?? 0))), y1 = min(c.h - 1, Int(ceil(ys.max() ?? 0)))
    guard y1 >= y0 else { return }
    for y in y0...y1 {
        let sy = Double(y) + 0.5
        var xs: [Double] = []
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            if (a.1 <= sy && b.1 > sy) || (b.1 <= sy && a.1 > sy) {
                xs.append(a.0 + (sy - a.1) / (b.1 - a.1) * (b.0 - a.0))
            }
        }
        xs.sort()
        var k = 0
        while k + 1 < xs.count {
            let xa = Int(xs[k].rounded()), xb = Int(xs[k + 1].rounded())
            c.rect(xa, y, xb - xa, 1, col)
            k += 2
        }
    }
}

/// A mountain range standing on row `base`: peaks `lo`…`hi` rows tall about `spacing` apart, lit on their left flanks,
/// with a snow cap reaching `snow` of the way down (none when `snow` is 0).
fileprivate func s3Range(_ c: PixelCanvas, base: Int, lo: Int, hi: Int, spacing: Int, slope: Double = 0.8, seed: Int,
                         lit: Px, shade: Px, snowLit: Px, snowShade: Px, snow: Double) {
    var peaks: [(x: Int, h: Int)] = []
    var x = -spacing / 2, i = 0
    while x < c.w + spacing {
        peaks.append((x, lo + Int(noise(i * 3 + seed) * Double(max(1, hi - lo)))))
        x += spacing / 2 + Int(noise(i * 3 + seed + 1) * Double(spacing)); i += 1
    }
    for x in 0..<c.w {
        var top = base, isLit = true, ph = 1
        for p in peaks {
            let y = base - p.h + Int(Double(abs(x - p.x)) * slope)
            if y < top { top = y; isLit = x < p.x; ph = p.h }
        }
        let fx = Double(x)
        top += Int(noise(x * 5 + seed) * 2) + Int(abs(sin(fx * 0.11 + Double(seed))) * Double(ph) * 0.03)
        guard top < base else { continue }
        c.rect(x, top, 1, base - top, isLit ? lit : shade)
        if snow > 0 {
            // The snow line wanders slowly (gullies and ridges), not column by column.
            let wander = sin(fx * 0.13 + Double(seed)) * 0.25 + sin(fx * 0.37 + Double(seed) * 2) * 0.15
            let depth = Int(Double(ph) * snow * (0.85 + wander)) - (top - (base - ph))
            if depth > 0 { c.rect(x, top, 1, depth, isLit ? snowLit : snowShade) }
        }
    }
}

extension Scenes {

    // MARK: - Ego's Planet

    /// Ego's Planet (Guardians of the Galaxy Vol. 2): the living planet's garden under a bright pastel sky with Ego's
    /// own face faintly formed in it; lavender and mint hills, his white-and-gold palace of spires on a rise, bulbous
    /// candy-coloured trees, and motes of light hanging in the air (they drift upward in `egosMotes`).
    static func egosPlanet(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x5AA6DA), C(0xF8E4CC), bands: 7)
        if tall { egosSky(c, g) }
        egosFace(c, g)
        // Far hills, lavender, then the mint rise the palace stands on.
        c.dunes(base: g - 18 * s, amp: 5 * Double(s), freq: 0.021 / Double(s), phase: 0.4, bottom: g, C(0xC6B4E4), shade: C(0xDCD0F2))
        for i in 0..<(c.w / 22) {                                            // tiny far trees along the ridge
            let x = Int(noise(i * 5 + 40) * Double(c.w)), r = 1 + Int(noise(i * 5 + 41) * 2)
            let col = [C(0xE8A8D0), C(0xA8D8E0), C(0xF0DC98), C(0xB8A0E8)][i % 4]
            c.circle(x, g - 15 * s - r * s - Int(noise(i * 5 + 42) * 4), r * s, col)
        }
        let px = c.w * 63 / 100
        c.ellipse(px, g - 8, 60 * s, 9 * s, C(0xA6DCB4))
        egosPalace(c, x: px, base: g - 12 * s, k: tall ? max(2, g / 110) : 1)
        c.dunes(base: g - 7 * s, amp: 2 * Double(s), freq: 0.04 / Double(s), phase: 2.1, bottom: g, C(0x94D0A4), shade: C(0xB8E8C4))
        // Trees: a row of middling ones on the meadow, then big ones framing the edges.
        let mids: [(Double, Int)] = [(0.08, 0), (0.2, 2), (0.36, 1), (0.47, 3), (0.8, 4), (0.9, 2)]
        for (i, (fx, hue)) in mids.enumerated() {
            let r = (4 + Int(noise(i * 3 + 60) * 3)) * s
            egosTree(c, x: Int(fx * Double(c.w)), base: g - 3 * s, h: r * 2 + 6 * s, r: r, hue: hue, seed: i)
        }
        egosTree(c, x: c.w / 40, base: g + 1, h: 30 * s + (tall ? g / 7 : 0), r: 11 * s + (tall ? g / 22 : 0), hue: 0, seed: 20)
        egosTree(c, x: c.w - c.w / 30, base: g + 1, h: 26 * s + (tall ? g / 9 : 0), r: 10 * s + (tall ? g / 26 : 0), hue: 1, seed: 21)
        egosTree(c, x: c.w * 57 / 100 - 50 * s, base: g, h: 20 * s, r: 7 * s, hue: 3, seed: 22)
        // Motes of light hanging still in the air.
        for i in 0..<(c.w * g / (500 * s * s)) {
            let x = Int(noise(i * 4 + 80) * Double(c.w)), y = Int(noise(i * 4 + 81) * Double(g - 4))
            c.rect(x, y, s, s, (i % 3 == 0 ? C(0xFFF4C0) : white).alpha(0.35 + noise(i * 4 + 82) * 0.4))
        }
        // The meadow: soft lime grass, pastel flowers.
        c.ground(g, C(0x86C266), edge: C(0xB4E28A), speck: C(0x74B058), seed: 31)
        for i in 0..<(c.w / 5) {
            let x = Int(noise(i * 3 + 90) * Double(c.w)), y = g + 1 + Int(noise(i * 3 + 91) * Double(max(1, c.h - g - 2)))
            c.px(x, y, [C(0xF8B8D8), C(0xFFF0A0), C(0xC8B8F8), white][i % 4])
        }
        for i in 0..<(c.w / 9) {                                             // grass tufts along the edge
            let x = Int(noise(i * 3 + 95) * Double(c.w))
            c.px(x, g - 1, C(0x9AD47A)); c.px(x + 1, g - 2, C(0xB4E28A)); c.px(x + 2, g - 1, C(0x9AD47A))
        }
    }

    /// Ego's face, faintly formed in the sky like light caught in haze: swept hair, arched brows over shadowed eyes,
    /// the line of the nose, moustache and beard.
    static func egosFace(_ c: PixelCanvas, _ g: Int) {
        let fh = Int(Double(g) * (isTall(c) ? 0.5 : 0.72)), fw = fh * 3 / 4
        let cx = c.w * 28 / 100, cy = Int(Double(g) * (isTall(c) ? 0.36 : 0.44))
        let ink = C(0x3A5C98)
        c.ellipse(cx, cy, fw / 2, fh / 2, white.alpha(0.07))                   // the face
        c.ellipse(cx, cy, fw * 2 / 5, fh * 2 / 5, white.alpha(0.04))
        c.ellipse(cx - fw / 10, cy - fh * 2 / 5, fw / 2, fh / 6, white.alpha(0.07))   // swept hair
        c.ellipse(cx, cy + fh / 3, fw * 3 / 10, fh / 6, ink.alpha(0.05))        // the beard
        for side in [-1, 1] {
            let ex = cx + side * fw / 5, ey = cy - fh / 14
            for k in -fw / 8...fw / 8 {                                         // an arched brow
                let u = Double(k) / Double(max(1, fw / 8))
                c.rect(ex + k, ey - fh / 10 + Int(u * u * Double(fh) / 30), 1, max(1, fh / 40), ink.alpha(0.13))
            }
            c.ellipse(ex, ey, max(1, fw / 10), max(1, fh / 24), ink.alpha(0.08))            // eye socket
            c.ellipse(ex, ey, max(1, fw / 22), max(1, fh / 60), white.alpha(0.28))          // the eye's light
        }
        for k in 0..<(fh / 6) { c.px(cx + k / 12, cy - fh / 20 + k, ink.alpha(0.10)) }   // nose
        c.ellipse(cx, cy + fh / 8, fw / 14, max(1, fh / 60), ink.alpha(0.10))
        c.ellipse(cx, cy + fh / 5, fw / 6, max(1, fh / 40), ink.alpha(0.10))               // moustache
        c.ellipse(cx, cy + fh / 4 + 1, fw / 10, max(1, fh / 80), white.alpha(0.12))         // a smile
    }

    /// Ego's palace: a white hall with gold trim, a tall central spire and lesser spires around it; `k` pixels a unit.
    static func egosPalace(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let stone = C(0xF4F0F4), shade = C(0xD0C8DC), gold = C(0xE8C060), dark = C(0x6A7AB0)
        func spire(_ dx: Int, _ h: Int, _ w: Int) {
            let x0 = Double(x + dx * k), top = Double(base - h * k), hw = Double(w * k) / 2
            s3Poly(c, [(x0 - hw, Double(base)), (x0 + hw, Double(base)), (x0 + hw, top + Double(h * k) / 3),
                       (x0, top), (x0 - hw, top + Double(h * k) / 3)], stone)
            c.rect(Int(x0 + hw) - k, Int(top) + h * k / 3, k, h * k * 2 / 3, shade)
            c.rect(Int(x0) - k / 2, Int(top) - 2 * k, max(1, k), 2 * k, gold)
            c.rect(Int(x0 - hw), Int(top) + h * k / 3, Int(hw * 2), max(1, k), gold)
            c.rect(Int(x0) - k / 2, Int(top) + h * k / 2, max(1, k), 2 * k, dark)
        }
        for (dx, h, w) in [(-24, 18, 4), (24, 18, 4), (-16, 26, 5), (16, 26, 5), (-8, 34, 5), (8, 34, 5)] { spire(dx, h, w) }
        c.rect(x - 22 * k, base - 12 * k, 44 * k, 12 * k, stone)            // the hall
        c.rect(x - 22 * k, base - 12 * k, 44 * k, k, gold)
        c.rect(x - 22 * k, base - 2 * k, 44 * k, 2 * k, shade)
        for ax in stride(from: -18, through: 16, by: 6) {                   // arched windows
            c.rect(x + ax * k, base - 9 * k, 2 * k, 5 * k, dark); c.px(x + ax * k, base - 10 * k, dark.alpha(0.6))
        }
        c.ellipse(x, base - 12 * k, 9 * k, 6 * k, shade)                     // the dome and the great spire on it
        c.ellipse(x - k, base - 13 * k, 8 * k, 5 * k, stone)
        spire(0, 50, 6)
        c.circle(x, base - 30 * k, 2 * k, gold)
    }

    /// One of Ego's bulbous trees: a pale curving trunk under clustered pastel bulbs. `hue` picks the colour.
    static func egosTree(_ c: PixelCanvas, x: Int, base: Int, h: Int, r: Int, hue: Int, seed: Int) {
        let tones: [(Px, Px, Px)] = [(C(0xF09CC6), C(0xFCCCE2), C(0xC876A6)), (C(0xB89CEC), C(0xDCCAFA), C(0x8E74CA)),
                                     (C(0x7CD6CE), C(0xB8F0EA), C(0x52ACA6)), (C(0xF4D676), C(0xFCEEB4), C(0xCCA84E)),
                                     (C(0xF8A888), C(0xFCD0BC), C(0xD07E62))]
        let (main, light, dark) = tones[hue % tones.count]
        let bend = (noise(seed * 13 + 1) - 0.5) * 2, tw = max(1, r / 3)
        for y in 0..<h {
            let u = Double(y) / Double(max(1, h))
            let dx = Int(sin(u * .pi) * bend * Double(r) / 2)
            c.rect(x + dx - tw / 2, base - y, tw, 1, C(0xEDE4F2)); c.px(x + dx + tw - tw / 2 - 1, base - y, C(0xBFB2CE))
        }
        let top = base - h
        c.circle(x + 1, top + 1, r, dark)
        c.circle(x, top, r, main)
        for b in 0..<(r > 6 ? 5 : 3) {                                       // smaller bulbs clustered round it
            let a = -Double.pi * (0.1 + 0.8 * noise(seed * 13 + b + 3)) + (b % 2 == 0 ? 0 : .pi * 0.9), rr = max(1, r / 2 + Int(noise(seed * 13 + b + 6) * Double(r / 3)))
            let bx = x + Int(cos(a) * Double(r)), by = top + Int(sin(a) * Double(r) * 0.6) - r / 4
            c.circle(bx + 1, by + 1, rr, dark); c.circle(bx, by, rr, main)
            c.circle(bx - rr / 3, by - rr / 3, max(0, rr / 3), light)
        }
        c.circle(x - r / 3, top - r / 3, max(1, r / 3), light)
        c.px(x - r / 2, top - r / 2, white)
    }

    /// Full screen: pastel wisps, a pale ringed moon and floating islands with their own little trees.
    static func egosSky(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        s3Range(c, base: g - 16, lo: g * 14 / 100, hi: g * 32 / 100, spacing: 100 * s, slope: 0.55, seed: 690,
                lit: C(0xE6BCDC), shade: C(0xC8A4CE), snowLit: C(0xFFF2E6), snowShade: C(0xEADAE8), snow: 0.25)
        for i in 0..<8 {
            let x = Int(noise(i * 5 + 700) * Double(c.w)), y = Int(Double(g) * (0.05 + noise(i * 5 + 701) * 0.45))
            wisp(c, x, y, (50 + Int(noise(i * 5 + 702) * 90)) * s, (i % 2 == 0 ? C(0xFCD8E8) : C(0xFFFFFF)).alpha(0.55), s: s)
        }
        let mx = c.w * 82 / 100, my = g / 7, mr = max(8, g / 14)
        c.ellipse(mx, my, mr * 2, max(1, mr / 4), C(0xF8E8C8, 0.5))
        c.circle(mx, my, mr, C(0xF4E6F0)); c.circle(mx + mr / 4, my + mr / 5, mr * 4 / 5, C(0xE4D0E8))
        c.ellipse(mx, my + 1, mr * 2, max(1, mr / 5), C(0xFFF4D8, 0.4))
        for (i, (fx, fy)) in [(0.58, 0.18), (0.9, 0.42), (0.12, 0.62)].enumerated() {
            let x = Int(fx * Double(c.w)), y = Int(fy * Double(g)), w = (18 + i * 6) * s
            s3Poly(c, [(Double(x - w), Double(y)), (Double(x + w), Double(y)), (Double(x + w / 4), Double(y + w)),
                       (Double(x - w / 5), Double(y + w * 2 / 3))], C(0xB0A0D0))
            c.rect(x - w, y - 2 * s, w * 2, 2 * s, C(0x9CD4AC))
            egosTree(c, x: x - w / 3, base: y - 2 * s, h: 8 * s, r: 4 * s, hue: i + 1, seed: 40 + i)
            egosTree(c, x: x + w / 3, base: y - 2 * s, h: 12 * s, r: 5 * s, hue: i + 3, seed: 50 + i)
        }
    }

    /// Ego's motes of light, rising and swaying, glinting as they go.
    static func egosMotes(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g)
        for i in 0..<max(24, c.w * g / (900 * s * s)) {
            let speed = 2.5 + noise(i * 7 + 2) * 4
            let y = Double(g) - (t * speed + noise(i * 7 + 3) * Double(g)).truncatingRemainder(dividingBy: Double(g))
            let x = noise(i * 7 + 1) * Double(c.w) + sin(t * 0.7 + Double(i)) * 4
            let glint = 0.5 + 0.5 * sin(t * 3 + Double(i) * 1.9)
            let col = [C(0xFFF2B0), white, C(0xFFC8E8), C(0xC8F4FF)][i % 4]
            c.rect(Int(x), Int(y), s, s, col.alpha(0.4 + glint * 0.5))
            if glint > 0.9 { c.px(Int(x) - 1, Int(y), col.alpha(0.3)); c.px(Int(x) + s, Int(y), col.alpha(0.3)) }
        }
    }

    // MARK: - Kamar-Taj

    /// Kamar-Taj (Doctor Strange): the monastery courtyard high in the Himalayas. Snowy peaks behind; red-pillared halls
    /// under dark tiled roofs with upturned eaves and gold finials; prayer flags strung between them; a weapon rack of
    /// training staves; flagstones underfoot; and a sling-ring portal open on the right, a glimpse of New York's night
    /// through it. The flags flutter and the portal's ring sparks in `kamarTajLife`.
    static func kamarTaj(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x5A8ACC), C(0xE0E8F2), bands: 6)
        if tall { kamarTajFar(c, g) }
        s3Range(c, base: g - 14, lo: g * 30 / 100, hi: g * 55 / 100, spacing: 60 * s, slope: 0.9, seed: 300,
                lit: C(0x9AA8C2), shade: C(0x7484A4), snowLit: C(0xF4F8FC), snowShade: C(0xC4D0E2), snow: 0.45)
        s3Range(c, base: g - 10, lo: g * 12 / 100, hi: g * 24 / 100, spacing: 40 * s, slope: 0.7, seed: 330,
                lit: C(0x7A7C86), shade: C(0x62646E), snowLit: C(0xE8EEF4), snowShade: C(0xB4BECC), snow: 0.25)
        if tall { kamarTajUpper(c, g) }
        // The halls along the back of the courtyard.
        let k = s
        kamarTajHall(c, x: c.w * 6 / 100, w: 70 * k, base: g - 6, h: 18 * k, tiers: 1)
        kamarTajHall(c, x: c.w * 30 / 100, w: 92 * k, base: g - 6, h: 22 * k, tiers: 2)
        kamarTajHall(c, x: c.w * 62 / 100, w: 60 * k, base: g - 6, h: 16 * k, tiers: 1)
        // The courtyard wall, cream with a red band.
        c.rect(0, g - 7, c.w, 7, C(0xD8C8A6)); c.rect(0, g - 7, c.w, 1, C(0xF0E4C8)); c.rect(0, g - 5, c.w, 1, C(0xA8382C))
        for x in stride(from: 4, to: c.w, by: 9) { c.rect(x, g - 3, 1, 3, C(0xBCAA88)) }
        // A rack of training staves (left), a stone lantern (middle).
        let rx = c.w * 3 / 100 + 2
        c.rect(rx, g - 12, 16, 1, C(0x6A3A22)); c.rect(rx, g - 5, 16, 1, C(0x6A3A22))
        c.rect(rx, g - 13, 1, 13, C(0x5A2E1A)); c.rect(rx + 15, g - 13, 1, 13, C(0x5A2E1A))
        for k in 0..<5 { c.rect(rx + 2 + k * 3, g - 16 + k % 2, 1, 16 - k % 2, C(0xB08850)) }
        let lx = c.w * 52 / 100
        c.rect(lx - 1, g - 6, 3, 6, C(0x8A8478)); c.rect(lx - 3, g - 10, 7, 4, C(0x9A9488))
        c.rect(lx - 1, g - 9, 3, 2, C(0xFFC860)); c.rect(lx - 4, g - 11, 9, 1, C(0x6A665E)); c.px(lx, g - 12, C(0x6A665E))
        kamarTajPortal(c, g)
        // Flagstones.
        c.ground(g, C(0x9C968A), edge: C(0xC8C2B4), speck: C(0x8A8478), seed: 33)
        for (row, y) in stride(from: g + 3, to: c.h, by: 3).enumerated() {
            c.rect(0, y, c.w, 1, C(0x847E72))
            for x in stride(from: (row % 2) * 7, to: c.w, by: 14) { c.rect(x, y - 2, 1, 2, C(0x847E72)) }
        }
        kamarTajFlagStrings(c, g)
    }

    /// The courtyard's prayer-flag lines: two ends and how far the line sags.
    static func kamarTajFlagLines(_ c: PixelCanvas, _ g: Int) -> [(x0: Int, y0: Int, x1: Int, y1: Int, sag: Int)] {
        let s = unit(g), top = isTall(c) ? g - 46 * s : 6
        return [(c.w * 6 / 100, g - 23 * s, c.w * 30 / 100, top + 2 * s, 8 * s),
                (c.w * 30 / 100 + 92 * s, top + 4 * s, c.w * 62 / 100 + 30 * s, g - 22 * s, 7 * s),
                (c.w * 62 / 100 + 60 * s, g - 22 * s, c.w - 2, top + 8 * s, 6 * s)]
    }

    /// Where a flag line runs at fraction `u` along it.
    static func kamarTajFlagPoint(_ l: (x0: Int, y0: Int, x1: Int, y1: Int, sag: Int), _ u: Double) -> (Int, Int) {
        (l.x0 + Int(Double(l.x1 - l.x0) * u), l.y0 + Int(Double(l.y1 - l.y0) * u + sin(u * .pi) * Double(l.sag)))
    }

    static func kamarTajFlagStrings(_ c: PixelCanvas, _ g: Int) {
        for l in kamarTajFlagLines(c, g) where l.x1 > l.x0 {
            for x in l.x0...l.x1 {
                let (px, py) = kamarTajFlagPoint(l, Double(x - l.x0) / Double(l.x1 - l.x0))
                c.px(px, py, C(0x4A3A2A, 0.8))
            }
        }
    }

    /// A temple hall: cream walls between red pillars, a dark tiled roof (two tiers for the main hall) with upturned
    /// eave tips and a gold finial, and a red door in the middle.
    static func kamarTajHall(_ c: PixelCanvas, x: Int, w: Int, base: Int, h: Int, tiers: Int) {
        let s = max(1, w / 60)
        let wallTop = base - h
        c.rect(x, wallTop, w, h, C(0xE4D6B8))
        c.rect(x, wallTop, w, 2 * s, C(0x7A2A20))                             // beam under the eaves
        c.rect(x, wallTop + 2 * s, w, s, C(0x3A6A5A))                         // painted green-blue band
        for px in stride(from: x + 1, to: x + w - 2, by: max(6, w / 7)) {
            c.rect(px, wallTop + 3 * s, 2 * s, h - 3 * s, C(0xA8302A)); c.rect(px, wallTop + 3 * s, s, h - 3 * s, C(0xC84838))
        }
        for wx in stride(from: x + max(6, w / 7) / 2 + 2, to: x + w - 4, by: max(6, w / 7)) where abs(wx - (x + w / 2)) > 6 {
            c.rect(wx, wallTop + 6 * s, 3 * s, 4 * s, C(0x5A3A28)); c.rect(wx, wallTop + 6 * s, 3 * s, s, C(0xE0B050))
        }
        c.rect(x + w / 2 - 4 * s, base - 10 * s, 8 * s, 10 * s, C(0x8A2418))   // the door
        c.rect(x + w / 2, base - 10 * s, max(1, s / 2), 10 * s, C(0x5A1810))
        c.px(x + w / 2 - 2 * s, base - 5 * s, C(0xE0B050)); c.px(x + w / 2 + 2 * s, base - 5 * s, C(0xE0B050))
        var rw = w + 10 * s, ry = wallTop
        for tier in 0..<tiers {
            let rh = 7 * s
            for k in 0..<rh {                                                  // eaves widest at the bottom
                let half = rw / 2 - (rh - k) * 2
                c.rect(x + w / 2 - half, ry - rh + k, half * 2, 1, k == rh - 1 ? C(0x24242C) : C(0x3A3C48))
            }
            for tx in stride(from: x + w / 2 - rw / 2 + 4, to: x + w / 2 + rw / 2 - 4, by: 3) {
                c.rect(tx, ry - 4 * s, 1, 3 * s, C(0x2C2E38))                  // tile ridges
            }
            c.rect(x + w / 2 - rw / 2 - s, ry - 3 * s, 2 * s, s, C(0x3A3C48))   // upturned eave tips
            c.rect(x + w / 2 + rw / 2 - s, ry - 3 * s, 2 * s, s, C(0x3A3C48))
            c.px(x + w / 2 - rw / 2 - s, ry - 4 * s, C(0xE0B050)); c.px(x + w / 2 + rw / 2, ry - 4 * s, C(0xE0B050))
            c.rect(x + w / 2 - rw / 2 + 6, ry - rh, rw - 12, s, C(0x5A5C68))   // ridge line
            ry -= rh
            if tier + 1 < tiers {                                             // the upper storey
                let uw = rw * 3 / 5
                c.rect(x + w / 2 - uw / 2, ry - 6 * s, uw, 6 * s, C(0xE4D6B8))
                c.rect(x + w / 2 - uw / 2, ry - 6 * s, uw, s, C(0x7A2A20))
                for px in stride(from: x + w / 2 - uw / 2, to: x + w / 2 + uw / 2, by: 5) { c.rect(px, ry - 5 * s, s, 5 * s, C(0xA8302A)) }
                ry -= 6 * s; rw = uw + 8 * s
            }
        }
        c.rect(x + w / 2 - s / 2, ry - 4 * s, max(1, s), 4 * s, C(0xE0B050))      // finial
        c.circle(x + w / 2, ry - 4 * s, s, C(0xF0C860))
    }

    /// Where the sling-ring portal stands: its centre and half-sizes.
    static func kamarTajPortalBox(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, rx: Int, ry: Int) {
        let s = unit(g)
        return (c.w * 84 / 100, g - 16 * s, 10 * s, 14 * s)
    }

    /// The portal's still part: New York at night seen through it, and the faint glow of its ring.
    static func kamarTajPortal(_ c: PixelCanvas, _ g: Int) {
        let p = kamarTajPortalBox(c, g)
        c.ellipse(p.x, p.y, p.rx + 4, p.ry + 4, C(0xFF9A30, 0.15))
        c.ellipse(p.x, p.y, p.rx + 1, p.ry + 1, C(0xFF8A20))
        func inside(_ x: Int, _ y: Int) -> Bool {
            let dx = Double(x - p.x) / Double(p.rx), dy = Double(y - p.y) / Double(p.ry)
            return dx * dx + dy * dy < 0.82
        }
        let street = p.y + p.ry / 2
        for y in (p.y - p.ry)...(p.y + p.ry) {                                // a sunny Greenwich Village street
            for x in (p.x - p.rx)...(p.x + p.rx) where inside(x, y) {
                let col = (x - p.x + 40) / 4
                let roof = p.y - p.ry / 2 + Int(noise(col + 700) * Double(p.ry) / 2)
                var px = y < p.y - p.ry / 3 ? C(0x7AB4E8) : C(0xA8CCF0)
                if y > roof { px = col % 2 == 0 ? C(0x9A5A42) : C(0x7A4A3A) }   // brownstones
                if y > roof + 1, y < street - 1, (x + 1) % 3 == 0, y % 3 == 0 { px = C(0xE8E0D0) }
                if y >= street { px = C(0x6A6A70) }
                if y == street + 2, x % 4 < 2 { px = C(0xE8D060) }
                c.px(x, y, px)
            }
        }
    }

    /// Full screen: towering Himalayan summits and a streak of cloud.
    static func kamarTajFar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<6 {
            let x = Int(noise(i * 5 + 800) * Double(c.w)), y = Int(Double(g) * (0.05 + noise(i * 5 + 801) * 0.25))
            wisp(c, x, y, (60 + Int(noise(i * 5 + 802) * 80)) * s, C(0xF2F6FA, 0.6), s: s)
        }
        s3Range(c, base: g - 30 * s, lo: g * 45 / 100, hi: g * 75 / 100, spacing: 120 * s, slope: 1.1, seed: 820,
                lit: C(0xA8B8D2), shade: C(0x8696B6), snowLit: C(0xF8FAFE), snowShade: C(0xCCD8EA), snow: 0.6)
    }

    /// Full screen: more of the monastery climbing the slope behind, a pagoda tower and outbuildings.
    static func kamarTajUpper(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let y = g - 40 * s
        c.ellipse(c.w / 2, y + 22 * s, c.w / 3, 14 * s, C(0x6E7078))
        kamarTajHall(c, x: c.w * 38 / 100, w: 60 * s, base: y, h: 16 * s, tiers: 3)
        kamarTajHall(c, x: c.w * 18 / 100, w: 50 * s, base: y + 10 * s, h: 12 * s, tiers: 1)
        kamarTajHall(c, x: c.w * 62 / 100, w: 50 * s, base: y + 8 * s, h: 12 * s, tiers: 2)
    }

    /// Prayer flags fluttering on their lines, and the sling ring's spinning sparks.
    static func kamarTajLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g)
        let colors = [C(0x3A6ACC), white, C(0xD0302A), C(0x3A9A4A), C(0xF0C830)]
        for (j, l) in kamarTajFlagLines(c, g).enumerated() where l.x1 > l.x0 {
            let len = Double(abs(l.x1 - l.x0) + abs(l.y1 - l.y0))
            let n = max(3, Int(len / Double(6 * s)))
            for i in 0..<n {
                let (x, y) = kamarTajFlagPoint(l, (Double(i) + 0.5) / Double(n))
                let wave = sin(t * 4 + Double(i) * 0.9 + Double(j))
                let col = colors[i % colors.count]
                c.rect(x - 2 * s, y + s, 4 * s, 3 * s, col)
                c.rect(x - 2 * s + Int(wave * Double(s)), y + 4 * s, 4 * s, s, col.alpha(0.8))   // the loose hem flaps
                c.rect(x - 2 * s, y + s, 4 * s, max(1, s / 2), lerp(col, C(0x000000), 0.25))
            }
        }
        let p = kamarTajPortalBox(c, g)
        let n = 30
        for i in 0..<n {                                                       // the ring
            let a = Double(i) / Double(n) * .pi * 2 + t * 3
            let jitter = noise(Int(t * 20) * 31 + i) * 1.6
            let x = p.x + Int(cos(a) * (Double(p.rx) + jitter)), y = p.y + Int(sin(a) * (Double(p.ry) + jitter))
            c.rect(x, y, s, s, i % 3 == 0 ? C(0xFFF0A0) : C(0xFFA030))
        }
        for i in 0..<10 {                                                      // sparks flung off it
            let ph = (t * 1.6 + noise(i * 9)).truncatingRemainder(dividingBy: 1)
            let a = noise(i * 9 + 1) * .pi * 2 + t * 3
            let r = 1 + ph * 0.5
            let x = p.x + Int(cos(a) * Double(p.rx) * r + sin(a) * ph * 6), y = p.y + Int(sin(a) * Double(p.ry) * r + ph * ph * 8)
            c.rect(x, y, s, s, C(0xFFC040, 1 - ph))
        }
    }

    // MARK: - The Raft

    /// The Raft (Captain America: Civil War): the super-max prison's cell block. A long window onto the grey North
    /// Atlantic up top, a tier of steel cells behind a railed walkway with their glass doors glowing cold blue,
    /// stencilled numbers, warning stripes and a heavy floor grating below. The status lights blink, a door flickers and
    /// the sea glints in `raftLights`.
    static func raft(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x262C34), C(0x3A424C), bands: 4)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, 0, 1, g, C(0x20252C)) }   // wall panels
        let win = raftWindow(c, g)
        // The window band: overcast sky, the sea, a horizon, mullions.
        c.rect(0, win.y - 2, c.w, win.h + 4, C(0x14181E))
        c.gradient(win.y, win.y + win.h * 2 / 5, C(0x8A9CB2), C(0xC2CCD8), bands: 3)
        c.gradient(win.y + win.h * 2 / 5, win.y + win.h, C(0x3A5A78), C(0x1C344C), bands: 3)
        c.rect(0, win.y + win.h * 2 / 5, c.w, 1, C(0xD8E0E8))
        for i in 0..<(c.w / 6) {                                              // whitecaps
            let x = Int(noise(i * 3 + 400) * Double(c.w)), y = win.y + win.h * 2 / 5 + 2 + Int(noise(i * 3 + 401) * Double(win.h * 3 / 5 - 3))
            c.rect(x, y, 2 + i % 3, 1, C(0x8AA4BC, 0.6))
        }
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, win.y - 2, 3 * s, win.h + 4, C(0x14181E)); c.rect(x + 1, win.y, s, win.h, C(0x2A3038)) }
        // The cell tiers, and steel columns running up through them on a big screen.
        for tier in raftTiers(c, g) { raftTier(c, tier, g) }
        if tall {
            let k = raftScale(c, g), top = win.y + win.h + 2
            for x in stride(from: c.w / 6, to: c.w, by: c.w / 3) {
                c.rect(x - 4 * k, top, 8 * k, g - top, C(0x3A424C)); c.rect(x - 4 * k, top, 2 * k, g - top, C(0x5A6470))
                c.rect(x + 3 * k, top, k, g - top, C(0x1A1E24))
                for y in stride(from: top + 10 * k, to: g - 10 * k, by: 40 * k) {
                    for j in 0..<4 { c.rect(x - 4 * k, y + j * 2 * k, 8 * k, k, j % 2 == 0 ? C(0xC8A030) : C(0x1A1E24)) }
                }
                c.rect(x - 2 * k, top + 2 * k, 4 * k, 3 * k, C(0x14181E)); c.px(x, top + 3 * k, C(0xE0303A))   // a camera
            }
        }
        // Floor level: plain wall, a warning stripe, a sealed blast door to the right.
        for x in stride(from: -4, to: c.w, by: 8) {
            for k in 0..<3 { c.rect(x + k, g - 3 + k / 2, 4, 1, k % 2 == 0 ? C(0xC8A030) : C(0xC8A030, 0.85)) }
        }
        c.rect(0, g - 3, c.w, 3, C(0x1A1E24, 0.55))
        let dx = c.w * 86 / 100, dw = 26 * s, dh = 20 * s
        c.rect(dx - 2, g - dh - 2, dw + 4, dh + 2, C(0x14181E))
        c.rect(dx, g - dh, dw, dh, C(0x4A525C)); c.rect(dx + dw / 2, g - dh, 1, dh, C(0x262C34))
        for y in stride(from: g - dh + 3, to: g - 3, by: 4) {
            c.rect(dx + 2, y, dw / 2 - 4, 2, C(0xC8A030)); c.rect(dx + dw / 2 + 2, y, dw / 2 - 4, 2, C(0xC8A030))
        }
        c.rect(dx + dw + 4, g - 12 * s, 3 * s, 5 * s, C(0x2A3038))           // the keypad
        // The floor: dark grating.
        c.ground(g, C(0x22272E), edge: C(0x6A7480), speck: C(0x2E343C), seed: 34)
        for x in stride(from: 0, to: c.w, by: 4) { c.rect(x, g + 1, 1, c.h - g - 1, C(0x1A1E24)) }
        for y in stride(from: g + 3, to: c.h, by: 3) { c.rect(0, y, c.w, 1, C(0x1A1E24)) }
    }

    /// The window band near the top: first row and height.
    static func raftWindow(_ c: PixelCanvas, _ g: Int) -> (y: Int, h: Int) {
        isTall(c) ? (6, g * 22 / 100) : (3, 11)
    }

    /// Pixels per unit of the cell tiers: bigger, nearer cells on a big screen.
    static func raftScale(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(2, g / 140) : 1 }

    /// The tiers of cells: each tier's walkway row (cells stand on it).
    static func raftTiers(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = raftScale(c, g), win = raftWindow(c, g), pitch = 24 * s
        var rows: [Int] = []
        var y = g - 25 * s
        while y - 21 * s >= win.y + win.h + 1 { rows.append(y); y -= pitch }
        return rows
    }

    /// Where each cell door is on a tier, and its size.
    static func raftDoors(_ c: PixelCanvas, _ g: Int, walk: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = raftScale(c, g), pitch = 28 * s, dw = 14 * s, dh = 16 * s
        var out: [(x: Int, y: Int, w: Int, h: Int)] = []
        var x = (walk / 3) % pitch + 6 * s
        while x + dw < c.w { out.append((x, walk - dh, dw, dh)); x += pitch }
        return out
    }

    /// A tier: cell frames with glowing glass doors and numbers, and the railed walkway in front.
    static func raftTier(_ c: PixelCanvas, _ walk: Int, _ g: Int) {
        let s = raftScale(c, g)
        for (i, d) in raftDoors(c, g, walk: walk).enumerated() {
            c.rect(d.x - 3 * s, d.y - 3 * s, d.w + 6 * s, d.h + 3 * s, C(0x4A525E))
            c.rect(d.x - 3 * s, d.y - 3 * s, d.w + 6 * s, s, C(0x6A7480))
            c.rect(d.x - s, d.y - s, d.w + 2 * s, d.h + s, C(0x14181E))
            c.rect(d.x, d.y, d.w, d.h, C(0x2A5A78))                            // the glass, lit from inside
            c.rect(d.x + s, d.y + s, d.w - 2 * s, d.h - s, C(0x5AA8D0, 0.5))
            for y in stride(from: d.y + 3 * s, to: d.y + d.h, by: 4 * s) { c.rect(d.x, y, d.w, max(1, s / 2), C(0x9AD8F0, 0.7)) }
            c.rect(d.x + d.w / 2 - 2 * s, d.y + d.h / 2, 4 * s, 6 * s, C(0x1A2A3A, 0.5))   // someone inside
            c.circle(d.x + d.w / 2, d.y + d.h / 2 - 2 * s, 2 * s, C(0x1A2A3A, 0.5))
            for k in 0..<(1 + i % 3) { c.rect(d.x + k * 2 * s, d.y - 5 * s, s, 2 * s, C(0xE8ECF0, 0.7)) }   // its number
        }
        c.rect(0, walk, c.w, 2 * s, C(0x5A6470)); c.rect(0, walk, c.w, max(1, s / 2), C(0x8A949E))   // the walkway
        c.rect(0, walk + 2 * s, c.w, s, C(0x14181E))
        c.rect(0, walk - 7 * s, c.w, s, C(0x7A8490))                           // the railing
        for x in stride(from: 0, to: c.w, by: 7 * s) { c.rect(x, walk - 7 * s, s, 7 * s, C(0x6A7480)) }
        c.rect(0, walk - 4 * s, c.w, max(1, s / 2), C(0x6A7480, 0.7))
    }

    /// Status lights blinking by each cell, one door's glow flickering, and the sea glinting through the window.
    static func raftLights(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = raftScale(c, g)
        for (j, walk) in raftTiers(c, g).enumerated() {
            for (i, d) in raftDoors(c, g, walk: walk).enumerated() {
                let n = noise(i * 7 + j * 31)
                let on = sin(t * (1.5 + n * 2) + n * 10) > -0.2
                let col = n > 0.85 ? C(0xE0303A) : C(0x3BD15A)
                c.rect(d.x + d.w + s, d.y + 2 * s, s, s, on ? col : col.alpha(0.25))
                if n > 0.88, noise(Int(t * 12) + i) > 0.6 { c.rect(d.x, d.y, d.w, d.h, C(0xBFF0FF, 0.25)) }
            }
        }
        let u = unit(g), win = raftWindow(c, g), sea = win.y + win.h * 2 / 5
        for i in 0..<(c.w / 10) {
            let x = Int((noise(i * 5 + 10) * Double(c.w) + t * (2 + noise(i * 5 + 11) * 3)).truncatingRemainder(dividingBy: Double(c.w)))
            let y = sea + 2 + Int(noise(i * 5 + 12) * Double(max(1, win.h * 3 / 5 - 3)))
            let a = 0.5 + 0.5 * sin(t * 2 + Double(i))
            if x % (30 * u) > 3 * u { c.rect(x, y, 2 + i % 3, 1, C(0xE0ECF4, a * 0.7)) }
        }
        let beacon = (t * 0.8).truncatingRemainder(dividingBy: 1)               // the alarm beacon over the blast door
        let bx = c.w * 86 / 100 + 13 * u, by = g - 24 * u
        c.rect(bx - u, by, 3 * u, 2 * u, beacon < 0.5 ? C(0xFF5030) : C(0x8A2A20))
        if beacon < 0.5 { c.circle(bx, by + u, 5 * u, C(0xFF5030, 0.15)) }
    }

    // MARK: - Battle of New York

    /// The Battle of New York (The Avengers): midtown mid-invasion. The Chitauri portal torn open in the sky with the
    /// Tesseract's beam running up into it from Stark Tower; the skyline with the Chrysler Building and the MetLife
    /// slab; a Leviathan coiling between the towers; smoke rising from fires; Grand Central's facade behind the Park
    /// Avenue viaduct; and a street of wrecked taxis and cars. Chitauri chariots stream across and the portal churns in
    /// `battleOfNewYorkInvasion`.
    static func battleOfNewYork(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g / 2, C(0x2E3852), C(0x6E6478), bands: 4)
        c.gradient(g / 2, g, C(0x8A6E74), C(0xE0A070), bands: 4)
        let p = battleOfNewYorkPortal(c, g)
        // The portal: a disc of black space with a cold glowing rim.
        c.circle(p.x, p.y, p.r + 4 * s, C(0x9AD0FF, 0.15))
        c.circle(p.x, p.y, p.r + 2 * s, C(0xC8E8FF, 0.35))
        c.circle(p.x, p.y, p.r, C(0x06081A))
        c.stars(p.y - p.r, p.y + p.r, density: 10, seed: 11, x0: p.x - p.r, x1: p.x + p.r) { x, y in
            (x - p.x) * (x - p.x) + (y - p.y) * (y - p.y) < (p.r - 1) * (p.r - 1)
        }
        c.circle(p.x + p.r / 3, p.y - p.r / 4, max(1, p.r / 4), C(0x3A2A6A, 0.6))   // the Chitauri fleet's mothership
        if tall { battleOfNewYorkLeviathan(c, x: c.w * 6 / 100, y: g * 40 / 100, k: max(2, g / 150), flip: false) }
        // The skyline: far towers, the Chrysler Building, Stark Tower, then near towers, with lit and blown-out windows.
        battleOfNewYorkSkyline(c, g, base: g - 8, lo: g * 22 / 100, hi: g * 45 / 100, col: C(0x5A5468), seed: 1)
        battleOfNewYorkChrysler(c, x: c.w * 14 / 100, base: g - 8, h: g * (tall ? 66 : 62) / 100)
        battleOfNewYorkLeviathan(c, x: c.w * 74 / 100, y: g * 36 / 100, k: s, flip: true)
        battleOfNewYorkStarkTower(c, g, p)
        battleOfNewYorkSkyline(c, g, base: g - 4, lo: g * 15 / 100, hi: g * 32 / 100, col: C(0x3A3644), seed: 2)
        battleOfNewYorkSmoke(c, g)
        battleOfNewYorkGrandCentral(c, x: c.w * 35 / 100, base: g - 2, k: s)
        battleOfNewYorkStreet(c, g)
    }

    /// The portal's centre and radius.
    static func battleOfNewYorkPortal(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let r = isTall(c) ? g * 14 / 100 : 11
        return (c.w * 56 / 100, isTall(c) ? g * 16 / 100 : r + 1, r)
    }

    /// Stark Tower: the tall slab with its curved crown and landing pad, the claw emblem lit near the top, and the Tesseract's
    /// beam shooting from its roof into the portal.
    static func battleOfNewYorkStarkTower(_ c: PixelCanvas, _ g: Int, _ p: (x: Int, y: Int, r: Int)) {
        let s = unit(g), x = p.x, top = g * (isTall(c) ? 36 : 30) / 100, w = (isTall(c) ? 22 : 16) * s
        c.glowLine(Double(x), Double(top - 3 * s), Double(x), Double(p.y + p.r), core: C(0xE8F8FF), glow: C(0x5AB8FF),
                   coreR: 0.8 * Double(s), glowR: 3 * Double(s))
        let glass = C(0x5A6680), lite = C(0x8A9AB4), seam = C(0x3A4254)
        c.rect(x - w / 2, top, w, g - top, glass)
        c.rect(x - w / 2, top, 3 * s, g - top, lite)                            // the lit edge
        c.rect(x + w / 4, top + 10 * s, max(1, s), g - top - 10 * s, seam)       // a vertical fin
        for y in stride(from: top + 12 * s, to: g, by: 3 * s) {
            c.rect(x - w / 2 + s, y, w - 2 * s, max(1, s / 2), seam)
            if noise(y * 7 + 515) > 0.7 { c.rect(x - w / 2 + 4 * s, y + s, w / 3, s, C(0xF0D8A0, 0.6)) }
        }
        let fw = Double(w), fx = Double(x), ft = Double(top), ss = Double(s)
        s3Poly(c, [(fx - fw / 2, ft), (fx + fw / 2 + 5 * ss, ft - 2 * ss), (fx + fw / 2, ft + 11 * ss),
                   (fx - fw / 2 - 3 * ss, ft + 11 * ss)], C(0x7A8EAA))           // the glass crown, flaring out
        c.rect(x - w / 2 - 3 * s, top + 11 * s, w + 3 * s, s, seam)
        c.rect(x - w / 2 - 9 * s, top + 13 * s, 10 * s, s, C(0xA8B2C2))           // the landing pad, cantilevered
        c.rect(x - w / 2 - 3 * s, top + 14 * s, 3 * s, s, seam)
        c.rect(x - w / 2 - 2 * s, top - 3 * s, w + 4 * s, 3 * s, seam)           // the roof
        // the arc-lit Clawdvengers emblem: a C, open to the right
        let ex = Double(x + w / 2 - 5 * s), ey = Double(top) + 5.5 * ss
        let arc = stride(from: 45.0, through: 315.0, by: 45.0).map { (ex + 2.3 * ss * cos($0 * .pi / 180), ey + 2.3 * ss * sin($0 * .pi / 180)) }
        for (p, q) in zip(arc, arc.dropFirst()) {
            c.glowLine(p.0, p.1, q.0, q.1, core: C(0x8ADCFF), glow: C(0x8ADCFF, 0), coreR: 0.4 * ss, glowR: 0.45 * ss)
        }
        c.glowLine(ex - 0.5 * ss, ey, ex + 4 * ss, ey, core: C(0x8ADCFF), glow: C(0x8ADCFF, 0), coreR: 0.4 * ss, glowR: 0.45 * ss)   // the bar
    }

    /// A row of buildings standing on `base`.
    static func battleOfNewYorkSkyline(_ c: PixelCanvas, _ g: Int, base: Int, lo: Int, hi: Int, col: Px, seed: Int) {
        let s = unit(g), p = battleOfNewYorkPortal(c, g)
        var x = -Int(noise(seed * 7) * 10), i = 0
        while x < c.w {
            let bw = (10 + Int(noise(seed * 100 + i * 3) * 18)) * s
            let bh = lo + Int(noise(seed * 100 + i * 3 + 1) * Double(hi - lo))
            if abs(x + bw / 2 - p.x) > bw / 2 + 10 * s {                         // keep Stark Tower clear
                c.rect(x, base - bh, bw, bh, col)
                c.rect(x, base - bh, bw, max(1, s), lerp(col, white, 0.15))
                if noise(seed * 100 + i * 3 + 2) > 0.6 { c.rect(x + bw / 3, base - bh - 4 * s, max(1, s), 4 * s, col) }   // a mast
                for wy in stride(from: base - bh + 3 * s, to: base - 2, by: 3 * s) {
                    for wx in stride(from: x + 2 * s, to: x + bw - s, by: 3 * s) {
                        let n = noise(wx * 13 + wy * 7 + seed)
                        if n > 0.82 { c.rect(wx, wy, s, s, C(0xF0C878, 0.8)) } else if n < 0.05 { c.rect(wx, wy, s, s, C(0xFF7A30)) }
                    }
                }
                if noise(seed * 100 + i * 3 + 9) > 0.7 {                        // a chunk blown out of the top
                    c.rect(x + bw / 2, base - bh, bw / 3, 3 * s, C(0x6E6478)); c.px(x + bw / 2, base - bh + 3 * s, C(0xFF8A30))
                }
            }
            x += bw + Int(noise(seed * 100 + i * 3 + 5) * 4); i += 1
        }
    }

    /// The Chrysler Building: stepped arches of its crown with triangular windows, and the needle.
    static func battleOfNewYorkChrysler(_ c: PixelCanvas, x: Int, base: Int, h: Int) {
        let s = unit(base), w = 14 * s, steel = C(0xA8AEBC), dark = C(0x5A5E6E)
        let crown = base - h + 12 * s
        c.rect(x - w / 2, crown, w, base - crown, C(0x6A6678))
        c.rect(x - w / 2, crown, 2 * s, base - crown, C(0x7E7A8E))
        for k in 0..<4 {                                                        // the stepped crown
            let half = w / 2 - k * 2 * s, y = crown - k * 3 * s
            c.ellipse(x, y, half, 3 * s, steel)
            for tx in stride(from: x - half + s, to: x + half - s, by: 2 * s) { c.px(tx, y, dark) }
        }
        c.rect(x - s / 2, base - h, max(1, s), 6 * s, steel)                    // the needle
    }

    /// A Leviathan: an armoured whale-worm of the Chitauri, plated segments arching through the air, `k` pixels a unit.
    static func battleOfNewYorkLeviathan(_ c: PixelCanvas, x: Int, y: Int, k: Int, flip: Bool) {
        let d = flip ? -1 : 1, plate = C(0x6A7068), lite = C(0x9AA096), dark = C(0x3A3E3A)
        for i in 0..<14 {                                                       // tail to head
            let u = Double(i) / 13
            let sx = x + d * Int(u * 44) * k, sy = y + Int(sin(u * .pi * 1.4) * 8) * k
            let r = (2 + Int(sin(u * .pi * 0.9) * 5)) * k
            c.ellipse(sx, sy, r + k, r, dark)
            c.ellipse(sx, sy - k, r, max(1, r - k), plate)
            c.rect(sx - r / 2, sy - r, max(1, r), k, lite)
            if i % 2 == 0 { c.rect(sx, sy - r - k, k, 2 * k, dark) }            // spines
        }
        let hx = x + d * 46 * k, hy = y + Int(sin(1.4 * .pi) * 8) * k
        let fx = Double(hx), fy = Double(hy), kd = Double(k * d), kk = Double(k)
        s3Poly(c, [(fx - kd * 5, fy - kk * 5), (fx + kd * 9, fy - kk * 1), (fx + kd * 4, fy + kk * 1), (fx - kd * 5, fy + kk * 2)], plate)
        s3Poly(c, [(fx - kd * 4, fy + kk * 2), (fx + kd * 8, fy + kk * 2), (fx + kd * 7, fy + kk * 5), (fx - kd * 4, fy + kk * 5)], dark)
        c.rect(min(hx - 4 * k * d, hx + 7 * k * d), hy + 2 * k, 11 * k, max(1, k / 2), C(0xE8C890))   // teeth
        c.rect(hx - 4 * k * d - (d < 0 ? 12 * k : 0), hy - 5 * k, 12 * k, k, lite)
        c.px(hx + d * 3 * k, hy - 2 * k, C(0xFFC040))
    }

    /// Columns of smoke rising from burning buildings.
    static func battleOfNewYorkSmoke(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for (i, fx) in [0.06, 0.27, 0.45, 0.66, 0.88].enumerated() {
            let x = Int(fx * Double(c.w)), base = g - 10 - Int(noise(i + 500) * Double(g) * 0.2)
            c.circle(x, base, 3 * s, C(0xFF8A30, 0.5))
            for k in 0..<(isTall(c) ? 22 : 14) {
                let y = base - k * 4 * s, r = (3 + k / 2) * s
                let dx = Int(Double(k * k) * 0.25) * s
                guard y > -r else { break }
                c.circle(x + dx, y, r, (k % 2 == 0 ? C(0x3A363A) : C(0x4E484C)).alpha(0.55 - Double(k) * 0.03))
            }
        }
    }

    /// Grand Central's facade: three tall arched windows between columns, the clock and statues on top.
    static func battleOfNewYorkGrandCentral(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let stone = C(0xC8B89A), shade = C(0x9A8C74), glass = C(0x4A4A58)
        let w = 50 * k, h = 22 * k, top = base - h
        c.rect(x - w / 2, top, w, h, stone)
        c.rect(x - w / 2, top, w, 2 * k, C(0xE0D2B4))
        for (i, ax) in [-14, 0, 14].enumerated() {
            let wx = x + ax * k - 5 * k
            c.rect(wx, top + 6 * k, 10 * k, 12 * k, glass)
            c.ellipse(wx + 5 * k, top + 6 * k, 5 * k, 3 * k, glass)
            for gx in stride(from: wx + 2 * k, to: wx + 10 * k, by: 3 * k) { c.rect(gx, top + 4 * k, max(1, k / 2), 14 * k, C(0x6A6A78)) }
            c.rect(wx - 2 * k, top + 3 * k, 2 * k, 15 * k, shade)                // columns
            if i == 2 { c.rect(wx + 10 * k, top + 3 * k, 2 * k, 15 * k, shade) }
        }
        c.rect(x - 8 * k, top - 4 * k, 16 * k, 4 * k, stone)                     // the sculpture group and clock
        c.circle(x, top - k, 2 * k, C(0xE8D890)); c.px(x, top - k, C(0x2A2A2A))
        c.rect(x - 7 * k, top - 7 * k, 3 * k, 3 * k, C(0x5A8A7A)); c.rect(x + 4 * k, top - 7 * k, 3 * k, 3 * k, C(0x5A8A7A))
        c.rect(x - 2 * k, top - 8 * k, 4 * k, 4 * k, C(0x5A8A7A))
        c.rect(0, base - 3 * k, c.w, 3 * k, C(0x5A5458))                         // the Park Avenue viaduct
        c.rect(0, base - 3 * k, c.w, k, C(0x7A7478))
    }

    /// The street: asphalt with lane markings, an overturned taxi, a crushed car, rubble and a fallen sign.
    static func battleOfNewYorkStreet(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.ground(g, C(0x3A383C), edge: C(0x6A6468), speck: C(0x2E2C30), seed: 35)
        for x in stride(from: 0, to: c.w, by: 16) { c.rect(x, g + (c.h - g) / 2, 8, 1, C(0xD8B040, 0.7)) }
        // An overturned taxi, wheels up (left).
        let tx = c.w * 8 / 100 + 20
        c.rect(tx, g - 7 * s, 22 * s, 5 * s, C(0xE8B820)); c.rect(tx + 4 * s, g - 2 * s, 14 * s, 2 * s, C(0xC89A10))
        c.rect(tx, g - 7 * s, 22 * s, s, C(0xF8D860)); c.rect(tx + 2 * s, g - 5 * s, 18 * s, s, C(0x2A2A2A))
        for wx in [tx + 3 * s, tx + 16 * s] { c.circle(wx, g - 8 * s, 2 * s, C(0x1A1A1E)); c.px(wx, g - 8 * s, C(0x8A8A8A)) }
        c.rect(tx + 8 * s, g - 1, 6 * s, s, C(0x1A1A1E))
        c.rect(tx + 22 * s, g - 5 * s, 2 * s, 2 * s, C(0xFF8A30))               // burning
        c.circle(tx + 23 * s, g - 6 * s, 3 * s, C(0xFF8A30, 0.25))
        // A crushed car and rubble (right).
        let cx = c.w * 80 / 100
        c.rect(cx, g - 5 * s, 20 * s, 5 * s, C(0x4A6A8A)); c.rect(cx + 4 * s, g - 8 * s, 10 * s, 3 * s, C(0x3A5A7A))
        c.rect(cx + 5 * s, g - 7 * s, 8 * s, s, C(0x8AA8C0, 0.6))
        c.rect(cx + 8 * s, g - 11 * s, 9 * s, 6 * s, C(0x8A8278))              // the slab that landed on it
        c.rect(cx + 8 * s, g - 11 * s, 9 * s, s, C(0xA89E92))
        for wx in [cx + 4 * s, cx + 16 * s] { c.circle(wx, g, 2 * s, C(0x1A1A1E)) }
        for i in 0..<8 {
            let x = Int(noise(i * 3 + 520) * Double(c.w)), w = (2 + Int(noise(i * 3 + 521) * 4)) * s
            c.rect(x, g - w / 2, w, w / 2 + 1, C(0x7A7268)); c.px(x, g - w / 2, C(0x9A9288))
        }
        let sx = c.w * 58 / 100                                                  // a toppled street sign
        c.rect(sx, g - s, 14 * s, s, C(0x8A8E92)); c.rect(sx + 10 * s, g - 3 * s, 8 * s, 3 * s, C(0x2A7A4A))
    }

    /// Chitauri chariots streaming out of the portal and weaving over the city, their blue bolts, and the portal's rim
    /// churning.
    static func battleOfNewYorkInvasion(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g), p = battleOfNewYorkPortal(c, g)
        for i in 0..<24 {                                                        // the rim swirling
            let a = Double(i) / 24 * .pi * 2 - t * 1.5
            let r = Double(p.r) + 1.5 * Double(s) + sin(t * 3 + Double(i)) * Double(s)
            c.rect(p.x + Int(cos(a) * r), p.y + Int(sin(a) * r), s, s, i % 4 == 0 ? white : C(0x9AD0FF, 0.8))
        }
        let n = isTall(c) ? 9 : 5
        for i in 0..<n {
            let speed = 0.05 + noise(i * 5 + 1) * 0.05
            let q = (t * speed + noise(i * 5)).truncatingRemainder(dividingBy: 1)
            let dir = i % 2 == 0 ? 1 : -1
            let x0 = Double(p.x), y0 = Double(p.y + p.r)
            let x1 = dir > 0 ? Double(c.w + 20) : -20.0, y1 = Double(g) * (0.3 + noise(i * 5 + 2) * 0.45)
            let x = Int(x0 + (x1 - x0) * q), y = Int(y0 + (y1 - y0) * q + sin(q * 9 + Double(i)) * 4)
            battleOfNewYorkChariot(c, x: x, y: y, k: s, dir: dir)
            let f = (t * 0.9 + noise(i * 5 + 3) * 3).truncatingRemainder(dividingBy: 1)
            if f < 0.2 {                                                         // a shot down at the street
                let d = Int(f / 0.2 * 30)
                c.rect(x + dir * (4 + d) * s, y + d / 2 + 2 * s, 3 * s, s, C(0x7AD0FF))
            }
        }
    }

    /// A Chitauri chariot: a grey hover-sled with its rider, thruster glowing, facing `dir`.
    static func battleOfNewYorkChariot(_ c: PixelCanvas, x: Int, y: Int, k: Int, dir: Int) {
        c.rect(x - 4 * k, y, 8 * k, 2 * k, C(0x7A7E86)); c.rect(x - 4 * k, y, 8 * k, k, C(0x9AA0A8))
        c.rect(x + dir * 4 * k - (dir < 0 ? k : 0), y + k, k, k, C(0x5A5E66))
        c.rect(x - k, y - 3 * k, 2 * k, 3 * k, C(0x4A4E46)); c.rect(x - k, y - 4 * k, 2 * k, k, C(0x8A8E7A))
        c.rect(x - dir * 5 * k - (dir > 0 ? 0 : k), y, k, 2 * k, C(0x7AD0FF))
    }

    // MARK: - Dark Dimension

    /// The Dark Dimension (Doctor Strange): Dormammu's realm. A kaleidoscope of violet and magenta fractal light with
    /// thin seams of molten orange, angular rocks floating in it, and Dormammu's immense burning face looming over all,
    /// eyes ablaze. The floor is a dark crystal shelf veined with fire. Rings of the fractal turn, the flames flicker
    /// and the eyes pulse in `darkDimensionShift`.
    static func darkDimension(_ c: PixelCanvas, _ g: Int) {
        let f = darkDimensionCentre(c, g)
        let pal = [C(0x0E0418), C(0x1E0A32), C(0x34124E), C(0x5A1A6E), C(0x9A2A8A), C(0xE8783A)]
        for y in 0..<g {
            for x in 0..<c.w {
                let dx = Double(x - f.x), dy = Double(y - f.y) * 1.3
                let r = (dx * dx + dy * dy).squareRoot()
                var a = atan2(dy, dx)
                let wedge = Double.pi / 6
                a = abs((a + .pi).truncatingRemainder(dividingBy: wedge * 2) - wedge)   // fold: a kaleidoscope
                let rr = r / Double(max(48, g / 3))
                let v = sin(rr * 9 - a * 7) * 0.5 + sin(a * 13 + rr * 4) * 0.3 + sin(rr * 2.3) * 0.4
                let q = (v + 1.2) / 2.4
                var idx = Int(q * 5)
                if abs(sin(rr * 9 - a * 7)) < 0.06 { idx = 5 }                   // the molten seams
                c.px(x, y, pal[max(0, min(5, idx))])
            }
        }
        for y in 0..<g {                                                         // darken away from the centre
            let e = abs(Double(y - f.y)) / Double(g)
            c.rect(0, y, c.w, 1, C(0x06020C, min(0.5, e * 0.6)))
        }
        for i in 0..<(isTall(c) ? 18 : 9) {
            let x = Int(noise(i * 4 + 600) * Double(c.w)), y = Int(noise(i * 4 + 601) * Double(g - 10))
            guard abs(x - f.x) > f.r * 3 / 2 else { continue }
            darkDimensionRock(c, x: x, y: y, r: (3 + Int(noise(i * 4 + 602) * 6)) * unit(g) * (isTall(c) ? 2 : 1), seed: i)
        }
        darkDimensionFace(c, g)
        // Floor: a dark crystal shelf veined with fire.
        c.ground(g, C(0x1E0C28), edge: C(0xC84A9A), speck: C(0x2E1440), seed: 36)
        var x = 0, i = 0
        while x < c.w {
            let len = 6 + Int(noise(i * 3 + 640) * 18), y = g + 2 + Int(noise(i * 3 + 641) * Double(max(1, c.h - g - 3)))
            for k in 0..<len { c.px(x + k, y + Int(sin(Double(k) * 0.7) * 1.2), C(0xE8783A, 0.7)) }
            x += len + 10 + Int(noise(i * 3 + 642) * 20); i += 1
        }
        for i in 0..<(c.w / 30) {                                                // crystal shards along the edge
            let x = Int(noise(i * 3 + 660) * Double(c.w)), h = 2 + Int(noise(i * 3 + 661) * 5)
            s3Poly(c, [(Double(x), Double(g)), (Double(x + 2), Double(g - h)), (Double(x + 4), Double(g))], C(0x3A1A52))
            c.px(x + 2, g - h, C(0xE88ACA))
        }
    }

    /// Where Dormammu's face hangs: its centre and half-height.
    static func darkDimensionCentre(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let r = isTall(c) ? g * 30 / 100 : g * 40 / 100
        return (c.w / 2, isTall(c) ? g * 38 / 100 : g * 44 / 100, r)
    }

    /// Dormammu's face: a head of violet fire with flames streaming up off its crown and temples, a long jaw, deep
    /// sockets under a scowling brow with slanted burning eyes, and a glowing maw.
    static func darkDimensionFace(_ c: PixelCanvas, _ g: Int) {
        let f = darkDimensionCentre(c, g), hw = f.r * 7 / 10
        let fx = Double(f.x), fy = Double(f.y), w = Double(hw), r = Double(f.r)
        c.ellipse(f.x, f.y, hw + f.r / 3, f.r + f.r / 4, C(0xC83A9A, 0.18))     // the aura
        for i in 0..<48 {                                                       // flames streaming off the head
            let a = Double.pi * (0.95 + 1.1 * Double(i) / 47)                   // round the top, ear to ear
            let ox = fx + cos(a) * w * 0.92, oy = fy + sin(a) * r * 0.88
            let len = r * (0.18 + noise(i * 7 + 610) * 0.4) * (0.5 + 0.5 * abs(sin(a)))
            let bend = (noise(i * 7 + 611) - 0.5) * len * 0.5
            let mx = ox + cos(a) * len * 0.3 + bend, my = oy + sin(a) * len * 0.35 - len * 0.3
            let tx = mx + cos(a) * len * 0.2 - bend, ty = my - len * 0.45
            let wide = max(0.6, r / 22)
            c.glowLine(ox, oy, mx, my, core: C(0xE85AAA), glow: C(0xA82A8A), coreR: wide, glowR: wide * 2.4)
            c.glowLine(mx, my, tx, ty, core: i % 3 == 0 ? C(0xF0985A) : C(0xE86AB0), glow: C(0xA82A8A, 0.6),
                       coreR: wide * 0.6, glowR: wide * 1.6)
        }
        c.ellipse(f.x, f.y, hw, f.r, C(0x7A1E7A))                               // cranium, then a long jaw to the chin
        s3Poly(c, [(fx - w, fy), (fx + w, fy), (fx + w * 0.55, fy + r * 0.85), (fx, fy + r * 1.12), (fx - w * 0.55, fy + r * 0.85)],
               C(0x7A1E7A))
        c.ellipse(f.x, f.y + f.r / 10, hw * 85 / 100, f.r * 85 / 100, C(0x4A1056))
        s3Poly(c, [(fx - w * 0.85, fy + r * 0.1), (fx + w * 0.85, fy + r * 0.1), (fx + w * 0.45, fy + r * 0.85),
                   (fx, fy + r * 1.02), (fx - w * 0.45, fy + r * 0.85)], C(0x4A1056))
        c.ellipse(f.x, f.y + f.r / 4, hw * 55 / 100, f.r * 6 / 10, C(0x34083E))   // the hollow of the face
        for side in [-1.0, 1.0] {
            let ex = fx + side * w * 0.4, ey = fy - r * 0.12
            c.ellipse(Int(ex), Int(ey), hw / 4 + 1, f.r / 7, C(0x12020E))       // socket
            s3Poly(c, [(ex - side * w * 0.22, ey + r * 0.05), (ex, ey - r * 0.04), (ex + side * w * 0.26, ey - r * 0.1),
                       (ex + side * w * 0.05, ey + r * 0.06)], C(0xFFA030))     // the eye, slanting up and out
            c.rect(Int(ex - w * 0.08), Int(ey - r * 0.02), max(1, hw / 6), max(1, f.r / 24), C(0xFFF0A0))
            s3Poly(c, [(ex - side * w * 0.3, ey - r * 0.06), (ex + side * w * 0.34, ey - r * 0.26),
                       (ex + side * w * 0.34, ey - r * 0.18), (ex - side * w * 0.3, ey + r * 0.0)], C(0xA82E8E))   // scowling brow
        }
        c.rect(f.x - max(1, hw / 20), f.y - f.r / 10, max(2, hw / 10), f.r / 3, C(0x5A1460))     // nose ridge
        s3Poly(c, [(fx - w * 0.38, fy + r * 0.5), (fx + w * 0.38, fy + r * 0.5), (fx + w * 0.2, fy + r * 0.66),
                   (fx - w * 0.2, fy + r * 0.66)], C(0x12020E))                                    // the maw
        c.rect(f.x - hw / 4, f.y + f.r * 55 / 100, hw / 2, max(1, f.r / 24), C(0xE8783A))
        for k in 0..<6 {                                                         // fiery cracks down the cheeks
            let side = k % 2 == 0 ? -1 : 1, x = f.x + side * (hw / 3 + k * hw / 18)
            c.rect(x, f.y + f.r / 8, 1, f.r / 4 + k * 2, C(0xE8783A, 0.45))
        }
    }

    /// A floating geometric rock: an angular slab, lit top face, glowing seam underneath.
    static func darkDimensionRock(_ c: PixelCanvas, x: Int, y: Int, r: Int, seed: Int) {
        let tilt = (noise(seed * 5 + 620) - 0.5) * Double(r)
        let top: [(Double, Double)] = [(Double(x - r), Double(y) + tilt / 2), (Double(x), Double(y - r / 2)),
                                       (Double(x + r), Double(y) - tilt / 2), (Double(x), Double(y + r / 3))]
        s3Poly(c, [(Double(x - r), Double(y) + tilt / 2), (Double(x), Double(y + r / 3)), (Double(x + r), Double(y) - tilt / 2),
                   (Double(x + r / 4), Double(y + r * 2))], C(0x24102E))
        s3Poly(c, top, C(0x4A2A62))
        c.rect(x - r / 2, y + r / 3, r, 1, C(0xE8783A, 0.6))
        c.px(x, y - r / 2, C(0xF0A8E0))
    }

    /// Rings of the fractal turning around Dormammu, his flames flickering and his eyes pulsing, embers rising.
    static func darkDimensionShift(_ c: PixelCanvas, _ g: Int, t: Double) {
        let f = darkDimensionCentre(c, g), s = unit(g)
        for ring in 0..<4 {                                                      // hexagons turning, alternate ways
            let r = Double(f.r) * (1.25 + Double(ring) * 0.45), sides = 6
            let rot = t * (ring % 2 == 0 ? 0.12 : -0.09) + Double(ring)
            for k in 0..<sides {
                let a0 = rot + Double(k) / Double(sides) * .pi * 2, a1 = rot + Double(k + 1) / Double(sides) * .pi * 2
                let steps = Int(r * 0.6)
                for j in 0..<steps where j % 3 == 0 {
                    let u = Double(j) / Double(steps)
                    let x = Double(f.x) + (cos(a0) * (1 - u) + cos(a1) * u) * r
                    let y = Double(f.y) + (sin(a0) * (1 - u) + sin(a1) * u) * r / 1.3
                    guard Int(y) < g else { continue }
                    c.rect(Int(x), Int(y), s, s, (ring % 2 == 0 ? C(0xE8783A) : C(0xD86AC0)).alpha(0.55))
                }
            }
        }
        let hw = f.r * 7 / 10
        for x in stride(from: f.x - hw, through: f.x + hw, by: 2) {               // the flames flicker
            let u = Double(x - f.x) / Double(hw)
            let edge = Int(Double(f.r) * (1 - u * u).squareRoot())
            let lick = Int(noise(x * 7 + Int(t * 8) * 131) * Double(f.r) * 0.35 * (1 - abs(u)))
            c.rect(x, f.y - edge - lick - 2, 1, lick, C(0xF08A5A, 0.6))
        }
        let pulse = 0.5 + 0.5 * sin(t * 2.2)
        for side in [-1, 1] {
            c.ellipse(f.x + side * hw * 2 / 5, f.y - f.r / 6, hw / 4 + 2, f.r / 8 + 1, C(0xFFC040, 0.12 + pulse * 0.18))
        }
        for i in 0..<16 {                                                        // embers drifting up
            let y = Double(g) - (t * (4 + noise(i * 3) * 6) + noise(i * 3 + 1) * Double(g)).truncatingRemainder(dividingBy: Double(g))
            let x = noise(i * 3 + 2) * Double(c.w) + sin(t + Double(i)) * 3
            c.rect(Int(x), Int(y), s, s, C(0xFFA040, 0.7))
        }
    }

    // MARK: - Attilan

    /// Attilan, the Inhumans' city, set down in the Blue Area of the Moon: black sky thick with stars and the Earth
    /// hanging in it, grey lunar hills, the city's ivory towers with gold crowns, onion domes and teal-lit windows,
    /// linked by arching sky-bridges, a great column of glowing Terrigen mist rising behind them, Terrigen crystals jutting
    /// from the blue-grey regolith. The mist billows, motes rise and stars twinkle in `attilanMist`.
    static func attilan(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x04050C), C(0x141A30), bands: 5)
        c.stars(0, g - 6, density: tall ? 70 : 26, seed: 7)
        attilanEarth(c, g)
        // Lunar hills, far crater walls on a big screen.
        if tall { attilanHigh(c, g) }
        c.dunes(base: g - 14, amp: 5, freq: 0.018, phase: 1.3, bottom: g, C(0x4A4E5E), shade: C(0x6A6E7E))
        // The Terrigen mist: a great glowing column rising behind the city.
        let mx = c.w * 58 / 100, k = tall ? max(2, g / 110) : 1
        let mh = tall ? g * 70 / 100 : g - 6
        for i in 0..<14 {
            let u = Double(i) / 13
            let y = g - 10 - Int(u * Double(mh) * 0.85), r = Int((0.3 + 0.25 * sin(u * .pi)) * Double(mh) * 0.5)
            let x = mx + Int(sin(u * 6 + 1) * Double(r) * 0.35)
            c.ellipse(x, y, r, r * 3 / 4, C(0x7AE8E0, 0.09))
            c.ellipse(x - r / 5, y - r / 5, r / 2, r * 3 / 8, C(0xD8FFF8, 0.07))
        }
        c.ellipse(mx, g - 12, mh / 2, mh / 5, C(0xC8FFF8, 0.12))
        attilanCity(c, x: mx, base: g - 7, k: k)
        c.dunes(base: g - 5, amp: 2, freq: 0.03, phase: 0.2, bottom: g, C(0x5E6A86), shade: C(0x8A98B8))
        // Terrigen mist pooled at the city's foot.
        for i in 0..<9 {
            let dx = Int((noise(i * 3 + 720) - 0.5) * 100) * s, r = (8 + Int(noise(i * 3 + 721) * 8)) * s
            c.ellipse(mx + dx, g - 5 - Int(noise(i * 3 + 722) * 5) * s, r * 2, r, C(0xA8F0F0, 0.12))
        }
        // Terrigen crystals jutting from the ground (left and right).
        attilanCrystals(c, x: c.w * 14 / 100, base: g, k: s)
        attilanCrystals(c, x: c.w * 94 / 100, base: g, k: s)
        // The Blue Area: blue-grey regolith with craters.
        c.ground(g, C(0x5A6684), edge: C(0x9AAACC), speck: C(0x4A5470), seed: 37)
        for i in 0..<(c.w / 40) {
            let x = Int(noise(i * 3 + 740) * Double(c.w)), y = g + 2 + Int(noise(i * 3 + 741) * Double(max(1, c.h - g - 4)))
            c.ellipse(x, y, 4, 1, C(0x46506A)); c.rect(x - 3, y - 1, 6, 1, C(0x7A88A8))
        }
    }

    /// The Earth hanging in the black sky: oceans, continents and cloud, the night side in shadow, a thin halo of air.
    static func attilanEarth(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c)
        let ex = c.w * (tall ? 20 : 16) / 100, ey = g * (tall ? 22 : 32) / 100, r = tall ? max(12, g / 9) : 10
        c.circle(ex, ey, r + max(1, r / 7), C(0x6AAAF0, 0.25))
        for y in (ey - r)...(ey + r) {
            for x in (ex - r)...(ex + r) {
                let dx = x - ex, dy = y - ey
                guard dx * dx + dy * dy <= r * r else { continue }
                let u = Double(dx) / Double(r), v = Double(dy) / Double(r)
                let land = sin(u * 5 + 1) * cos(v * 4 - 0.5) + sin(u * 9 + v * 7) * 0.4
                let cloud = sin(u * 3 + v * 11 + 2) + sin(u * 13 - v * 3) * 0.3
                var col = land > 0.45 ? (v > 0.75 || v < -0.8 ? C(0xE8F0F8) : C(0x5A8A4A)) : C(0x2A64C0)
                if land > 0.45, land < 0.6, col.g < 0xE0 { col = C(0x9A8A5A) }
                if cloud > 0.95 { col = C(0xF0F4F8) }
                let lx = dx + r / 2                                                // the night side, to the right
                if lx * lx + dy * dy > r * r * 9 / 10 { col = lerp(col, C(0x04050C), 0.78) }
                c.px(x, y, col)
            }
        }
    }

    /// The city: ivory towers on a terraced base, the tallest in the middle crowned with a gold fan, the rest with
    /// gold rings, needles and onion domes, teal-lit windows, and sky-bridges arching between them; `k` pixels a unit.
    static func attilanCity(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let ivory = C(0xE6E2D6), lit = C(0xF8F6EE), shade = C(0xA8A49C), gold = C(0xE0B850), teal = C(0x5AD8D8)
        c.rect(x - 64 * k, base - 5 * k, 128 * k, 5 * k, shade)                   // terraces
        c.rect(x - 64 * k, base - 5 * k, 128 * k, k, ivory)
        c.rect(x - 52 * k, base - 9 * k, 104 * k, 4 * k, ivory)
        c.rect(x - 52 * k, base - 9 * k, 104 * k, k, lit)
        for d in stride(from: -48, through: 46, by: 8) { c.rect(x + d * k, base - 7 * k, 2 * k, 2 * k, teal.alpha(0.8)) }
        let towers: [(dx: Int, h: Int, w: Int, crown: Int)] = [(-46, 12, 7, 2), (-35, 20, 8, 1), (-23, 27, 9, 2),
                                                               (-11, 34, 9, 1), (0, 44, 12, 0), (12, 31, 9, 2),
                                                               (24, 24, 8, 1), (35, 17, 8, 2), (46, 10, 7, 1)]
        func top(_ t: (dx: Int, h: Int, w: Int, crown: Int)) -> Int { base - 9 * k - height(t) }
        func height(_ t: (dx: Int, h: Int, w: Int, crown: Int)) -> Int { k == 1 ? t.h * 4 / 5 : t.h * k }   // squatter in the strip
        // Sky-bridges first, so the towers stand in front of their ends.
        for i in 0..<(towers.count - 1) {
            let a = towers[i], b = towers[i + 1]
            let y0 = max(top(a), top(b)) + 4 * k, x0 = x + a.dx * k, x1 = x + b.dx * k
            for xx in x0...x1 {
                let u = Double(xx - x0) / Double(max(1, x1 - x0))
                c.rect(xx, y0 - Int(sin(u * .pi) * 3 * Double(k)), 1, k, ivory)
            }
        }
        for t in towers {
            let tx = x + t.dx * k, tp = top(t), h = height(t)
            for y in 0..<h {                                                       // a gently tapering shaft
                let half = max(k, t.w * k * 3 / 8 + (y * t.w * k) / (h * 8))
                c.rect(tx - half, tp + y, half * 2, 1, ivory)
                c.rect(tx - half, tp + y, max(1, half / 3), 1, lit)
                c.rect(tx + half - max(1, half / 3), tp + y, max(1, half / 3), 1, shade)
            }
            for wy in stride(from: tp + 4 * k, to: base - 10 * k, by: 4 * k) {      // windows
                c.rect(tx - t.w * k / 5, wy, max(1, k), 2 * k, teal); c.rect(tx + t.w * k / 5, wy, max(1, k), 2 * k, teal)
            }
            c.rect(tx - t.w * k / 2, tp + 2 * k, t.w * k, k, gold)                 // a gold band below the crown
            switch t.crown {
            case 0:                                                                // the great crescent fan
                for a in stride(from: -70.0, through: 70.0, by: 14.0) {
                    let r = Double(t.w * k) * 1.2, ang = (a - 90) * .pi / 180
                    c.glowLine(Double(tx), Double(tp), Double(tx) + cos(ang) * r, Double(tp) + sin(ang) * r,
                               core: gold, glow: C(0, 0), coreR: 0.7 * Double(k), glowR: 0.8 * Double(k))
                }
                c.circle(tx, tp, 2 * k, gold); c.circle(tx, tp, k, C(0xFFF0B0))
            case 1:                                                                // a ring and a needle
                c.ellipse(tx, tp, t.w * k * 2 / 3, k, gold)
                c.rect(tx - k / 2, tp - 7 * k, max(1, k), 7 * k, gold)
            default:                                                               // an onion dome
                c.ellipse(tx, tp - 2 * k, t.w * k / 2 + k, t.w * k / 2, ivory)
                c.ellipse(tx - k, tp - 3 * k, t.w * k / 4, t.w * k / 4, lit)
                c.rect(tx - k / 2, tp - 2 * k - t.w * k / 2 - 3 * k, max(1, k), 3 * k, gold)
            }
        }
    }

    /// A cluster of Terrigen crystals: pale blue-white shards with glowing hearts.
    static func attilanCrystals(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        for (dx, h, lean) in [(-5, 7, -2), (0, 12, 0), (5, 9, 2), (9, 5, 3)] {
            let bx = Double(x + dx * k)
            s3Poly(c, [(bx - 2 * Double(k), Double(base)), (bx + 2 * Double(k), Double(base)),
                       (bx + Double(lean * k) + Double(k) / 2, Double(base - h * k)), (bx + Double(lean * k) - Double(k) / 2, Double(base - h * k))],
                   C(0x8AD8F0))
            c.rect(Int(bx) - k / 2 + lean * k / 2, base - h * k * 2 / 3, max(1, k), h * k / 2, C(0xE8FFFF))
        }
        c.ellipse(x, base - 4 * k, 14 * k, 6 * k, C(0xA8F0FF, 0.15))
    }

    /// Full screen: a ring of far crater walls and a few rocks in the sky's foreground.
    static func attilanHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        s3Range(c, base: g - 12, lo: g * 10 / 100, hi: g * 18 / 100, spacing: 90 * s, slope: 0.5, seed: 760,
                lit: C(0x5A5E70), shade: C(0x3E4252), snowLit: C(0x7A7E90), snowShade: C(0x5A5E70), snow: 0.15)
        for i in 0..<5 {
            let x = Int(noise(i * 3 + 770) * Double(c.w)), r = (6 + Int(noise(i * 3 + 771) * 10)) * s
            c.ellipse(x, g - 14 - r / 3, r, max(1, r / 4), C(0x3A3E4E))
        }
    }

    /// The Terrigen mist billowing at the city's foot, motes of it rising, and the towers' lights glimmering.
    static func attilanMist(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g), mx = c.w * 58 / 100
        for i in 0..<7 {
            let ph = t * 0.25 + Double(i) * 0.9
            let x = mx + Int(sin(ph) * 50 * Double(s)) + Int((noise(i * 3 + 780) - 0.5) * 60) * s
            let r = (6 + Int(noise(i * 3 + 781) * 6) + Int(sin(ph * 1.3) * 2)) * s
            c.ellipse(x, g - 8 * s - Int(cos(ph) * 2), r * 2, r, C(0xC8FFFF, 0.10))
        }
        for i in 0..<14 {
            let p = (t * 0.06 + noise(i * 5)).truncatingRemainder(dividingBy: 1)
            let x = mx + Int((noise(i * 5 + 1) - 0.5) * 120) * s + Int(sin(t + Double(i)) * 4), y = g - 6 - Int(p * Double(g) * 0.5)
            c.rect(x, y, s, s, C(0xC8FFFF, 0.6 * sin(p * .pi)))
        }
        for i in 0..<12 {                                                        // stars twinkling
            let x = Int(noise(i * 7 + 790) * Double(c.w)), y = Int(noise(i * 7 + 791) * Double(g - 20))
            let a = max(0, sin(t * 1.7 + Double(i) * 2.1))
            c.px(x, y, white.alpha(a * 0.9))
        }
    }

    // MARK: - Savage Land

    /// The Savage Land: the hidden prehistoric valley in Antarctica. A ring of glacier cliffs walls in a warm, hazy
    /// jungle, tallest at the edges; a volcano smokes in the middle distance (it's what keeps the valley warm);
    /// sauropods browse in the far treetops; a waterfall pours off a mossy cliff into a pool; palms and cycads frame the
    /// scene and ferns crowd the floor. Pterodactyls glide over, the waterfall flows and the crater glows in
    /// `savageLandLife`.
    static func savageLand(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x7EAED2), C(0xF0E2B8), bands: 6)
        if tall { savageLandSky(c, g) }
        savageLandIce(c, g, base: g - 12 * s)
        c.gradient(g - 26 * s, g - 12 * s, C(0xF0E2B8, 0), C(0xF0E2B8, 0.55), bands: 4)    // warm haze over the valley
        savageLandVolcano(c, g)
        // The far jungle, with tree ferns standing out of it and sauropods browsing.
        savageLandCanopy(c, base: g - 8 * s, top: g - 17 * s, k: s, col: C(0x6E9A72), lite: C(0x8AB48A), seed: 1)
        for i in 0..<(c.w / 60) {
            let x = Int(noise(i * 3 + 940) * Double(c.w)), h = (12 + Int(noise(i * 3 + 941) * 10)) * s
            savageLandTreeFern(c, x: x, base: g - 12 * s, h: h, k: s, col: C(0x5E8A62))
        }
        let dk = tall ? 2 * s : s
        savageLandSauropod(c, x: c.w * 37 / 100, base: g - 11 * s, k: dk, col: C(0x56705C), flip: true)
        savageLandSauropod(c, x: c.w * 47 / 100, base: g - 10 * s, k: dk, col: C(0x4E6854), flip: false)
        savageLandCanopy(c, base: g - 3 * s, top: g - 10 * s, k: s, col: C(0x3E6E40), lite: C(0x5A8E50), seed: 2)
        savageLandFallCliff(c, g)
        // Palms and cycads framing the scene.
        savageLandPalm(c, x: c.w * 30 / 100, base: g, h: 26 * s + (tall ? g / 8 : 0), lean: 3, k: s)
        savageLandPalm(c, x: c.w * 82 / 100, base: g, h: 30 * s + (tall ? g / 6 : 0), lean: -4, k: s)
        savageLandPalm(c, x: c.w * 96 / 100, base: g, h: 20 * s + (tall ? g / 10 : 0), lean: -2, k: s)
        for fx in [0.24, 0.6, 0.9] { savageLandCycad(c, x: Int(fx * Double(c.w)), base: g, k: s) }
        // Floor: dark loam, ferns crowding the edge.
        c.ground(g, C(0x3E3220), edge: C(0x5A6A30), speck: C(0x4A3E28), seed: 38)
        for (i, x) in stride(from: 3, to: c.w, by: 9).enumerated() where noise(i * 3 + 930) > 0.35 {
            let fh = 3 + Int(noise(i * 3 + 931) * 5)
            let col = i % 3 == 0 ? C(0x3E7A30) : C(0x5A9A3A)
            for k in 0..<fh {
                c.px(x - k / 2, g - k, col); c.px(x + k / 2, g - k, col)
                if k % 2 == 0 { c.px(x - k / 2 - 1, g - k + 1, col); c.px(x + k / 2 + 1, g - k + 1, col) }
            }
        }
    }

    /// The glacier wall ringing the valley: sheer ice cliffs, low in the middle and towering at the edges, with a snow
    /// lip along the top, shadowed faces, blue crevasses and strata.
    static func savageLandIce(_ c: PixelCanvas, _ g: Int, base: Int) {
        let tall = isTall(c)
        for x in 0..<c.w {
            let e = abs(Double(x) / Double(max(1, c.w)) - 0.5) * 2
            let h = Double(g) * (tall ? 0.22 + 0.32 * e * e : 0.26 + 0.34 * e * e)
            let fx = Double(x)
            let jag = sin(fx * 0.05 + 1) * h * 0.08 + sin(fx * 0.23) * h * 0.03
            let top = base - Int(h + jag) - Int(noise(x * 3 + 900) * 2)
            guard top < base else { continue }
            let face = sin(fx * 0.12 + sin(fx * 0.03) * 3)
            let col = face > 0.35 ? C(0x98B4D0) : (face > -0.5 ? C(0xBCD2E6) : C(0xDCEAF4))
            c.rect(x, top, 1, base - top, col)
            for y in stride(from: top + 6 + (x / 5) % 3, to: base, by: 9) { c.px(x, y, C(0xE8F2FA, 0.35)) }   // strata
            if noise(x / 3 + 905) > 0.88 { c.rect(x, top + 3, 1, (base - top) * 2 / 3, C(0x7AA0C8)) }  // crevasses
            c.rect(x, top, 1, 2 + Int(noise(x / 2 + 910) * 2), C(0xF8FCFF))
        }
    }

    /// The volcano: a smoking cone with a glowing crater and lava runs down its flank.
    static func savageLandVolcano(_ c: PixelCanvas, _ g: Int) {
        let v = savageLandVolcanoPeak(c, g), s = unit(g), base = g - 10 * s
        let h = base - v.y
        for y in v.y..<base {                                                       // concave flanks
            let u = Double(y - v.y) / Double(max(1, h))
            let half = v.w / 6 + Int(Double(v.w - v.w / 6) * pow(u, 1.7))
            c.rect(v.x - half, y, half, 1, C(0x6A564C))
            c.rect(v.x, y, half, 1, C(0x4E3E38))
            if y % 4 == 0 { c.px(v.x - half / 2, y, C(0x5A4840)); c.px(v.x + half / 3, y, C(0x403230)) }
        }
        for k in 0..<3 {                                                            // lava runs
            var lx = Double(v.x - v.w / 10 + k * v.w / 10)
            for y in v.y..<(v.y + h * (2 + k) / 5) {
                lx += (noise(y * 3 + k * 50) - 0.5) * 1.2 + Double(k - 1) * 0.35
                c.px(Int(lx), y, C(0xE8602A, 0.85))
            }
        }
        c.rect(v.x - v.w / 6, v.y, v.w / 3, max(1, s), C(0xFF9A40))
        c.ellipse(v.x, v.y, v.w / 5, 2 * s, C(0xFF7A30, 0.25))
        let big = isTall(c) ? 2 : 1
        for k in 0..<9 {                                                            // the smoke plume
            let r = (2 + k) * s * big
            c.circle(v.x + k * k * s * big / 3, v.y - 3 - k * 3 * s * big, r,
                     (k % 2 == 0 ? C(0x6A6466) : C(0x7A7476)).alpha(0.55 - Double(k) * 0.04))
        }
    }

    /// The volcano's crater: centre, row, and half-width at the base.
    static func savageLandVolcanoPeak(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, w: Int) {
        let h = isTall(c) ? g * 26 / 100 : g * 42 / 100
        return (c.w * 66 / 100, g - 10 * unit(g) - h, h * 8 / 5)
    }

    /// The waterfall: its column and the row it falls from.
    static func savageLandFall(_ c: PixelCanvas, _ g: Int) -> (x: Int, top: Int) {
        (c.w * 10 / 100, isTall(c) ? g * 50 / 100 : g * 32 / 100)
    }

    /// The mossy cliff on the left the waterfall pours from, the falling water, and the pool at its foot.
    static func savageLandFallCliff(_ c: PixelCanvas, _ g: Int) {
        let w = savageLandFall(c, g), s = unit(g), right = w.x + 12 * s
        for x in 0..<right {                                                        // the rock, crumbling at its right edge
            let fromEdge = right - x
            let slump = fromEdge < 8 * s ? (8 * s - fromEdge) * (8 * s - fromEdge) / (4 * s) : 0
            let top = w.top - 2 * s + Int(noise(x / 2 + 945) * 3) + slump
            guard top < g else { continue }
            c.rect(x, top, 1, g - top, (x / (3 * s)) % 3 == 0 ? C(0x4E4E46) : C(0x5E5E54))
            for y in stride(from: top + 4 + x % 4, to: g, by: 6 * s) { c.px(x, y, C(0x3E3E38)) }
            c.rect(x, top, 1, 2 * s + Int(noise(x + 946) * 3) * s, C(0x4E8A3A))       // moss on top
            if noise(x + 947) > 0.8 { c.rect(x, top, 1, (4 + Int(noise(x + 948) * 10)) * s, C(0x3E7A30)) }   // hanging vines
        }
        c.rect(w.x - 3 * s, w.top - 2 * s, 7 * s, g - w.top + 1, C(0xA8D8F0))        // the falling water
        c.rect(w.x - 2 * s, w.top - 2 * s, 2 * s, g - w.top + 1, C(0xE8F8FF))
        c.rect(w.x + 3 * s, w.top - 2 * s, s, g - w.top + 1, C(0x7AB8E0))
        c.ellipse(w.x + 4 * s, g - 1, 18 * s, 2 * s, C(0x5AA0C8))                    // the pool
        c.ellipse(w.x, g - 2, 9 * s, 3 * s, white.alpha(0.55))
    }

    /// A band of rounded jungle treetops from `top` down to `base`.
    static func savageLandCanopy(_ c: PixelCanvas, base: Int, top: Int, k: Int, col: Px, lite: Px, seed: Int) {
        c.rect(0, (base + top) / 2, c.w, base - (base + top) / 2 + 1, col)
        let dark = lerp(col, C(0x102010), 0.3)
        var x = 0, i = 0
        while x < c.w + 10 {
            let r = (2 + Int(noise(seed * 50 + i) * 6)) * k, y = top + Int(noise(seed * 50 + i + 20) * Double(max(1, base - top - r)))
            c.circle(x + k, y + r + k, r, dark)
            c.circle(x, y + r, r, col); c.circle(x - r / 3, y + r - r / 3, max(1, r / 2), lite)
            x += r + k + Int(noise(seed * 50 + i + 40) * 3) * k; i += 1
        }
    }

    /// A tree fern standing out of the canopy: a thin trunk under a star of drooping fronds.
    static func savageLandTreeFern(_ c: PixelCanvas, x: Int, base: Int, h: Int, k: Int, col: Px) {
        c.rect(x, base - h, k, h, lerp(col, C(0x3A2A1A), 0.4))
        for dir in [-3, -2, -1, 1, 2, 3] {
            for j in 0..<(5 * k) {
                c.px(x + dir * j / 2, base - h + j * j / (6 * k) - (abs(dir) == 1 ? j / 3 : 0), col)
            }
        }
    }

    /// A sauropod: body, long neck raised to the treetops, small head, tail trailing.
    static func savageLandSauropod(_ c: PixelCanvas, x: Int, base: Int, k: Int, col: Px, flip: Bool) {
        let d = flip ? -1 : 1, lite = lerp(col, white, 0.15)
        for lx in [-5, -2, 3, 6] { c.rect(x + lx * k, base - 3 * k, 2 * k, 4 * k, col) }
        c.ellipse(x, base - 6 * k, 8 * k, 4 * k, col)
        c.ellipse(x - k, base - 8 * k, 6 * k, k, lite)
        for i in 0..<28 {                                                           // neck, curving up
            let u = Double(i) / 27
            c.rect(x + d * (6 + Int(u * 9)) * k - (d < 0 ? 2 * k : 0), base - (7 + Int(u * u * 15)) * k, 2 * k, 2 * k, col)
        }
        c.rect(x + d * 15 * k - (d < 0 ? 3 * k : 0), base - 23 * k, 3 * k, 2 * k, col)   // head
        for i in 0..<12 {                                                           // tail
            c.rect(x - d * (7 + i) * k - (d < 0 ? k : 0), base - 6 * k + i * k / 3, k, max(1, k - i / 8), col)
        }
    }

    /// A palm tree: a ringed, leaning trunk and drooping fronds.
    static func savageLandPalm(_ c: PixelCanvas, x: Int, base: Int, h: Int, lean: Int, k: Int) {
        for y in 0..<h {
            let u = Double(y) / Double(h)
            let tx = x + Int(u * u * Double(lean * k * 3))
            c.rect(tx - k, base - y, 2 * k + 1, 1, (y / (2 * k)) % 2 == 0 ? C(0x7A5A3A) : C(0x5A4228))
        }
        let topX = x + lean * k * 3, topY = base - h
        for (i, dir) in [-1.0, -0.7, -0.35, 0.35, 0.7, 1.0].enumerated() {
            let len = Double((12 + i % 2 * 4) * k)
            for j in 0..<Int(len) {
                let u = Double(j) / len
                let fx = topX + Int(dir * Double(j))
                let fy = topY - Int(sin(u * .pi * 0.7) * len * 0.3 * (1.2 - abs(dir) * 0.5)) + Int(u * u * len * 0.45)
                c.rect(fx, fy, k, k, C(0x3A7A30))
                if j % 2 == 0 { c.rect(fx, fy + k, k, k, C(0x2E6426)); c.rect(fx - Int(dir), fy + 2 * k, k, k, C(0x2E6426, 0.7)) }
            }
        }
        c.circle(topX, topY, k + 1, C(0x5A4228))
    }

    /// A cycad: a squat scaly trunk under a fan of stiff fronds.
    static func savageLandCycad(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        c.rect(x - 2 * k, base - 5 * k, 4 * k, 5 * k, C(0x6A5432))
        for y in stride(from: base - 5 * k, to: base, by: 2 * k) { c.rect(x - 2 * k, y, 4 * k, max(1, k / 2), C(0x4A3A22)) }
        for dir in [-4, -3, -2, -1, 0, 1, 2, 3, 4] {
            for j in 0..<(6 * k) {
                let y = base - 5 * k - j + (abs(dir) >= 3 ? j * j / (5 * k) : 0)
                c.px(x + dir * j / 3, y, abs(dir) % 2 == 0 ? C(0x4E8A3A) : C(0x3E7A30))
            }
        }
    }

    /// Full screen: high ice peaks beyond the ring and steam clouds drifting over the valley.
    static func savageLandSky(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        s3Range(c, base: g - 40 * s, lo: g * 35 / 100, hi: g * 55 / 100, spacing: 110 * s, slope: 1.2, seed: 960,
                lit: C(0xC0D4E8), shade: C(0x96B0CC), snowLit: C(0xF4F8FC), snowShade: C(0xC4D4E6), snow: 0.55)
        for i in 0..<6 {
            let x = Int(noise(i * 5 + 970) * Double(c.w)), y = Int(Double(g) * (0.08 + noise(i * 5 + 971) * 0.3))
            cloud(c, x, y, (4 + Int(noise(i * 5 + 972) * 4)) * s, seed: i + 60, top: C(0xF8F4EA), base: C(0xE0DCD0))
        }
    }

    /// Pterodactyls gliding over the valley, the waterfall pouring, spray, and the volcano's crater flickering.
    static func savageLandLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g)
        let w = savageLandFall(c, g)
        let len = g - w.top
        for i in 0..<10 {                                                           // streaks running down the fall
            let p = (t * 0.9 + Double(i) / 10).truncatingRemainder(dividingBy: 1)
            let y = w.top - 2 * s + Int(p * Double(len)), x = w.x - 3 * s + (i * 3 % 7) * s
            c.rect(x, y, s, 3 * s, white.alpha(0.85))
        }
        for i in 0..<10 {                                                           // spray at the foot
            let a = noise(i * 3 + 980) * .pi, r = (4 + sin(t * 3 + Double(i)) * 3) * Double(s)
            c.rect(w.x + Int(cos(a) * r * 2), g - 3 - Int(sin(a) * r), s, s, white.alpha(0.6))
        }
        let v = savageLandVolcanoPeak(c, g)
        c.ellipse(v.x, v.y, v.w / 5 + Int(noise(Int(t * 6)) * 2), (2 + Int(noise(Int(t * 6) + 1) * 2)) * s, C(0xFF7A30, 0.3))
        for i in 0..<4 {                                                            // sparks thrown from the crater
            let p = (t * 0.7 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
            let x = v.x + Int((noise(i * 3 + 985) - 0.5) * Double(v.w) * 0.4 * p), y = v.y - Int(sin(p * .pi) * 8 * Double(s))
            c.rect(x, y, s, s, C(0xFFB040, 1 - p))
        }
        let n = isTall(c) ? 5 : 3
        for i in 0..<n {                                                            // pterodactyls
            let speed = 0.03 + noise(i * 5 + 990) * 0.03
            let q = (t * speed + noise(i * 5 + 991)).truncatingRemainder(dividingBy: 1)
            let dir = i % 2 == 0 ? 1 : -1
            let span = Double(c.w + 60)
            let x = dir > 0 ? Int(q * span) - 30 : c.w + 30 - Int(q * span)
            let y = Int(Double(g) * (0.12 + noise(i * 5 + 992) * 0.3)) + Int(sin(t * 0.8 + Double(i)) * 3)
            let k = s * (i == 0 && isTall(c) ? 2 : 1)
            savageLandPterodactyl(c, x: x, y: y, k: k, dir: dir, flap: sin(t * 2.5 + Double(i) * 2))
        }
    }

    /// A pterodactyl gliding, `dir` its heading: swept membrane wings flexing with `flap`, a long beak and the crest
    /// sweeping back from its head.
    static func savageLandPterodactyl(_ c: PixelCanvas, x: Int, y: Int, k: Int, dir: Int, flap: Double) {
        let body = C(0x5A3A34), wing = C(0x8A5A4A), kk = Double(k), fx = Double(x), fy = Double(y), f = flap * 2 * kk
        for side in [-1.0, 1.0] {                                                  // each wing: shoulder, swept tip
            s3Poly(c, [(fx - kk, fy), (fx + side * 6 * kk, fy - 2 * kk + f * 0.5), (fx + side * 11 * kk, fy - kk + f),
                       (fx + side * 4 * kk, fy + 1.5 * kk)], wing)
            c.rect(Int(fx + side * 6 * kk), Int(fy - 2 * kk + f * 0.5), k, k, body)
        }
        c.rect(x - 2 * k, y, 4 * k, k + k / 2 + 1, body)                            // body
        c.rect(x + dir * 2 * k - (dir < 0 ? 2 * k : 0), y - k, 2 * k, k + 1, body)  // head
        c.rect(x + dir * 4 * k - (dir < 0 ? 3 * k : 0), y - k / 2, 3 * k, max(1, k / 2 + 1), C(0xC8A060))   // beak
        c.rect(x + dir * k - (dir < 0 ? 2 * k : 0), y - 2 * k, 2 * k, k, body)      // crest, sweeping back
        c.rect(x - dir * 3 * k - (dir < 0 ? 0 : k), y + k / 2, k, k, body)          // tail
    }
}
