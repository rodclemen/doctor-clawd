import Foundation

let doctorScenes4: [Location: Place] = [
    .cafeArles: Place(name: "Café in Arles", panel: 0x0E1838, still: Scenes.doc4Cafe, moving: Scenes.doc4CafeLife),
    .badWolfBay: Place(name: "Bad Wolf Bay", panel: 0x262A2E, still: Scenes.doc4Bay, moving: Scenes.doc4BayLife),
    .telos: Place(name: "Telos", panel: 0x141C28, still: Scenes.doc4Telos, moving: Scenes.doc4TelosLife),
    .dalickAsylum: Place(name: "The Dalick Asylum", panel: 0x1C1A26, still: Scenes.doc4Asylum, moving: Scenes.doc4AsylumLife),
    .sanctuaryBase: Place(name: "Sanctuary Base 6", panel: 0x1C1612, still: Scenes.doc4Sanctuary, moving: Scenes.doc4SanctuaryLife),
    .christmasLondon: Place(name: "Christmas London", panel: 0x0E1224, still: Scenes.doc4London, moving: Scenes.doc4LondonLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func doc4Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// A straight line, `th` pixels thick.
    static func doc4Line(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: Px, th: Int = 1) {
        let n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in 0...n {
            c.rect(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, th, th, col)
        }
    }

    /// Snow falling through rows `y0..<y1`, blown sideways by `wind` (pixels a second), each flake wobbling as it goes;
    /// `skip` leaves out the spots something solid stands in front of.
    static func doc4Snow(_ c: PixelCanvas, _ t: Double, y0: Int, y1: Int, density: Int, fall: Double, wind: Double,
                         seed: Int, s: Int, col: Px = C(0xF4F8FC), skip: ((Int, Int) -> Bool)? = nil) {
        guard y1 > y0, c.w > 0 else { return }
        let span = Double(y1 - y0)
        for i in 0..<(c.w * (y1 - y0) / max(1, density)) {
            let r0 = noise(seed * 977 + i * 3), r1 = noise(seed * 977 + i * 3 + 1), r2 = noise(seed * 977 + i * 3 + 2)
            let speed = 0.6 + r2 * 0.8
            let y = y0 + Int((r1 * span + t * fall * speed).truncatingRemainder(dividingBy: span))
            let drift = t * wind * speed + sin(t * 1.3 + Double(i)) * Double(2 * s)
            var x = Int(r0 * Double(c.w) + drift) % c.w
            if x < 0 { x += c.w }
            if let skip, skip(x, y) { continue }
            let size = r2 > 0.86 ? 2 * s : s
            c.rect(x, y, size, size, col.alpha(0.5 + r2 * 0.5))
        }
    }

    /// The rows of an ellipse at or below row `minY` only (the near half of a ring seen edge on).
    static func doc4LowerEllipse(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, minY: Int, _ col: Px) {
        guard rx > 0, ry > 0 else { return }
        for dy in -ry...ry where cy + dy >= minY {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded())
            c.rect(cx - half, cy + dy, half * 2 + 1, 1, col)
        }
    }

    /// The rows of an ellipse above row `maxY` only.
    static func doc4UpperEllipse(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, maxY: Int, _ col: Px) {
        guard rx > 0, ry > 0 else { return }
        for dy in -ry...ry where cy + dy < maxY {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded())
            c.rect(cx - half, cy + dy, half * 2 + 1, 1, col)
        }
    }
}

// MARK: - Café in Arles

extension Scenes {
    /// The café's layout: the unit, its right edge, the top of its wall, the awning's row, where the dark houses on the
    /// right begin, and the far end of the street.
    static func doc4CafeFrame(_ c: PixelCanvas, _ g: Int) -> (u: Int, cafeR: Int, wallTop: Int, awnY: Int, streetR: Int, horizon: Int) {
        let u = unit(g) * (isTall(c) ? 2 : 1)
        return (u, c.w * 36 / 100, g - 46 * u, g - 30 * u, c.w * 64 / 100, g - 14 * u)
    }

    /// The top of whatever stands at column `x` (open sky above it).
    static func doc4CafeRoof(_ c: PixelCanvas, _ g: Int, _ x: Int) -> Int {
        let f = doc4CafeFrame(c, g), u = f.u
        if x < f.cafeR { return f.wallTop }
        if x < f.cafeR + 10 * u { return f.awnY }
        if x >= f.streetR {
            let k = (x - f.streetR) / (22 * u)
            return g - (34 + Int(noise(k * 7 + 4400) * 12)) * u
        }
        let k = x / (9 * u)
        return f.horizon - (3 + Int(noise(k * 5 + 4410) * 6)) * u
    }

    /// The great swirls of the sky: centre and radii.
    static func doc4CafeSwirls(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, rx: Int, ry: Int)] {
        let w = Double(c.w), h = Double(g)
        if isTall(c) {
            return [(Int(w * 0.5), Int(h * 0.36), Int(w * 0.17), Int(h * 0.16)),
                    (Int(w * 0.8), Int(h * 0.18), Int(w * 0.12), Int(h * 0.11)),
                    (Int(w * 0.2), Int(h * 0.16), Int(w * 0.1), Int(h * 0.09))]
        }
        return [(Int(w * 0.5), Int(h * 0.32), Int(w * 0.1), Int(h * 0.22)),
                (Int(w * 0.8), Int(h * 0.16), Int(w * 0.07), Int(h * 0.12)),
                (Int(w * 0.18), Int(h * 0.13), Int(w * 0.05), Int(h * 0.1))]
    }

    /// The big haloed stars, wherever they're in open sky.
    static func doc4CafeStars(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let u = doc4CafeFrame(c, g).u
        var out: [(x: Int, y: Int)] = []
        for i in 0..<(isTall(c) ? 26 : 14) {
            let x = Int(noise(i * 3 + 4420) * Double(c.w)), y = 3 * u + Int(noise(i * 3 + 4421) * Double(g) * 0.8)
            if y < doc4CafeRoof(c, g, x) - 4 * u { out.append((x, y)) }
        }
        return out
    }

    /// The café terrace at night, as the painter saw it: under a deep blue sky laid on in thick strokes, with great
    /// swirls and stars ringed in yellow halos and a crescent moon, the café glows gold on the left under its yellow
    /// awning, round tables out on the terrace and a lamp hanging over them. Down the middle the cobbled street runs
    /// off to low houses; on the right the tall houses stand dark blue, a few windows lit.
    static func doc4Cafe(_ c: PixelCanvas, _ g: Int) {
        let f = doc4CafeFrame(c, g), u = f.u
        c.gradient(0, g, C(0x0C1A52), C(0x2E52A6), bands: 8)
        // The brush strokes.
        let strokes = [C(0x1A2E7A), C(0x3A5CB4), C(0x24428E), C(0x4A70C4)]
        for i in 0..<(c.w * g / 22) {
            let x = Int(noise(i * 3 + 4500) * Double(c.w)), y = Int(noise(i * 3 + 4501) * Double(g))
            c.rect(x, y, (2 + Int(noise(i * 3 + 4502) * 3)) * u, 1, strokes[i % 4].alpha(0.7))
        }
        // The rings the swirls turn on.
        for (k, sw) in doc4CafeSwirls(c, g).enumerated() {
            for ring in 1...4 {
                let q = Double(ring) / 4.2
                for a in stride(from: 0.0, to: 2 * Double.pi, by: 0.09) {
                    let x = sw.x + Int(cos(a + Double(ring)) * Double(sw.rx) * q)
                    let y = sw.y + Int(sin(a + Double(ring)) * Double(sw.ry) * q)
                    guard y < doc4CafeRoof(c, g, x) - 1, noise(k * 400 + ring * 90 + Int(a * 30)) > 0.3 else { continue }
                    c.rect(x, y, 2 * u, 1, C(ring % 2 == 0 ? 0x6A90D8 : 0x4E78C8, 0.75))
                }
            }
        }
        // The stars and their halos.
        for st in doc4CafeStars(c, g) {
            c.circle(st.x, st.y, 3 * u, C(0xE8D870, 0.18))
            c.circle(st.x, st.y, 2 * u, C(0xF4E48A, 0.45))
            c.circle(st.x, st.y, u, C(0xFFF6C8))
        }
        // The moon, a thick crescent.
        let mx = c.w * 90 / 100, my = max(4 * u, g * 10 / 100), mr = 3 * u
        c.circle(mx, my, mr + 3 * u, C(0xE8D870, 0.2))
        c.circle(mx, my, mr, C(0xF8E49A))
        c.circle(mx + u + u / 2 + 1, my - u, mr - 1, lerp(C(0x0C1A52), C(0x2E52A6), Double(my) / Double(g)))
        // The far end of the street: low houses and the road running down to them.
        for x in f.cafeR..<f.streetR {
            let top = doc4CafeRoof(c, g, x)
            c.rect(x, top, 1, f.horizon - top, C(0x26346E))
        }
        for k in 0..<((f.streetR - f.cafeR) / (5 * u)) {
            if noise(k * 3 + 4430) > 0.55 { c.rect(f.cafeR + k * 5 * u, f.horizon - 3 * u, u, u, C(0xF0C860, 0.8)) }
        }
        for y in f.horizon..<g {
            let k = Double(y - f.horizon) / Double(max(1, g - f.horizon))
            c.rect(f.cafeR, y, f.streetR - f.cafeR, 1, lerp(C(0x3A447A), C(0x5A5A86), k))
        }
        // Cobbles in the street, warm near the café and blue further off.
        for i in 0..<((f.streetR - f.cafeR) * (g - f.horizon) / (6 * u * u)) {
            let x = f.cafeR + Int(noise(i * 3 + 4440) * Double(f.streetR - f.cafeR))
            let y = f.horizon + u + Int(noise(i * 3 + 4441) * Double(max(1, g - f.horizon - u)))
            let warm = x < f.cafeR + 16 * u
            c.rect(x, y, 2 * u, max(1, u / 2), warm ? C(0xD8A048, 0.7) : C(0x7A86B8, 0.6))
        }
        doc4CafeHouses(c, g)
        doc4CafeFront(c, g)
        // The terrace and street underfoot.
        c.ground(g, C(0x2E3A70), edge: C(0x6A78B0), speck: C(0x22305E), seed: 44)
        for i in 0..<(c.w * (c.h - g) / (5 * u * u)) {
            let x = Int(noise(i * 3 + 4460) * Double(c.w)), y = g + u + Int(noise(i * 3 + 4461) * Double(max(1, c.h - g - u)))
            let warm = Double(x) < Double(f.cafeR) * 1.25
            c.rect(x, y, 2 * u, u, warm ? C(0xE0A848, 0.8) : C(0x5A68A8, 0.8))
        }
        c.rect(0, g, f.cafeR + 14 * u, 1, C(0xF4C860))
    }

    /// The dark houses on the right, blue against the blue night, a few windows lit.
    static func doc4CafeHouses(_ c: PixelCanvas, _ g: Int) {
        let f = doc4CafeFrame(c, g), u = f.u
        var x = f.streetR, k = 0
        while x < c.w {
            let top = doc4CafeRoof(c, g, x), bw = 22 * u
            c.rect(x, top, bw, g - top, k % 2 == 0 ? C(0x1C2858) : C(0x222E64))
            c.rect(x, top, bw, u, C(0x121A40))
            c.rect(x, top - u, bw, u, C(0x3A4A88, 0.6))
            for wy in stride(from: top + 4 * u, to: g - 6 * u, by: 7 * u) {
                for wx in stride(from: x + 3 * u, to: x + bw - 4 * u, by: 6 * u) {
                    let lit = noise(wx * 3 + wy * 7 + 4470) > 0.62
                    c.rect(wx, wy, 3 * u, 4 * u, lit ? C(0xF0C858) : C(0x2E3C7C))
                    if lit { c.rect(wx, wy + 4 * u, 3 * u, u, C(0xF0C858, 0.25)) }
                }
            }
            c.rect(x + bw / 2 - u, g - 6 * u, 3 * u, 6 * u, noise(k + 4480) > 0.5 ? C(0xC89040) : C(0x141C44))
            x += bw; k += 1
        }
    }

    /// The café itself: ochre upper floors, the yellow awning, the glowing terrace under it with its door, tables and
    /// chairs, and the lamp.
    static func doc4CafeFront(_ c: PixelCanvas, _ g: Int) {
        let f = doc4CafeFrame(c, g), u = f.u, r = f.cafeR
        // The upper floors, lit from below.
        for y in f.wallTop..<f.awnY {
            let k = Double(y - f.wallTop) / Double(max(1, f.awnY - f.wallTop))
            c.rect(0, y, r, 1, lerp(C(0x5A4A3A), C(0xC8903A), k))
        }
        c.rect(0, f.wallTop, r, 2 * u, C(0x3A2C22))
        for wy in stride(from: f.wallTop + 4 * u, to: f.awnY - 6 * u, by: 9 * u) {
            for wx in stride(from: 5 * u, to: r - 5 * u, by: 12 * u) {
                c.rect(wx - 2 * u, wy, 2 * u, 6 * u, C(0x3A6A54))
                c.rect(wx, wy, 4 * u, 6 * u, noise(wx + wy * 3 + 4490) > 0.5 ? C(0xE8B858) : C(0x2A2A3A))
                c.rect(wx + 4 * u, wy, 2 * u, 6 * u, C(0x3A6A54))
            }
        }
        // The terrace under the awning, glowing gold.
        for y in f.awnY..<g {
            let k = Double(y - f.awnY) / Double(max(1, g - f.awnY))
            c.rect(0, y, r, 1, lerp(C(0xF4D460), C(0xD8A038), k))
        }
        c.rect(r - 16 * u, f.awnY + 7 * u, 7 * u, g - f.awnY - 7 * u, C(0xA0581E))
        c.rect(r - 15 * u, f.awnY + 8 * u, 5 * u, g - f.awnY - 8 * u, C(0xFFE698))
        for wx in stride(from: 4 * u, to: r - 22 * u, by: 14 * u) {
            c.rect(wx, f.awnY + 8 * u, 8 * u, 7 * u, C(0xFFEAA8))
            c.rect(wx + 4 * u, f.awnY + 8 * u, u, 7 * u, C(0xB87A2A))
        }
        // The awning, its stripes and its scalloped edge.
        let aw = r + 10 * u
        c.rect(0, f.awnY, aw, 5 * u, C(0xF2BC2E))
        c.rect(0, f.awnY, aw, u, C(0xFFE08A))
        for x in stride(from: 0, to: aw, by: 6 * u) { c.rect(x, f.awnY + u, 2 * u, 4 * u, C(0xE0A422)) }
        for x in stride(from: 0, to: aw, by: 4 * u) { c.rect(x, f.awnY + 5 * u, 3 * u, u, C(0xD89A1E)) }
        c.rect(aw - u, f.awnY, u, 6 * u, C(0xB07A18))
        // The lamp under the awning.
        let lx = r - 2 * u, ly = f.awnY + 7 * u
        c.circle(lx, ly + u, 7 * u, C(0xFFE27A, 0.18))
        c.circle(lx, ly + u, 4 * u, C(0xFFEC9A, 0.3))
        c.rect(lx, f.awnY + 5 * u, max(1, u / 2), 2 * u, C(0x3A2A1A))
        c.rect(lx - u, ly, 3 * u, 3 * u, C(0xFFF6CC))
        // Tables and chairs out on the terrace.
        for tx in stride(from: 8 * u, to: r + 8 * u, by: 17 * u) {
            c.rect(tx - 4 * u, g - 4 * u, u, 4 * u, C(0x6A4424))
            c.rect(tx - 4 * u, g - 6 * u, 2 * u, u, C(0x6A4424))
            c.rect(tx + 4 * u, g - 4 * u, u, 4 * u, C(0x6A4424))
            c.rect(tx + 3 * u, g - 6 * u, 2 * u, u, C(0x6A4424))
            c.rect(tx, g - 5 * u, u, 5 * u, C(0x4A3A28))
            c.ellipse(tx, g - 5 * u, 3 * u, u, C(0xF0E8C8))
            c.rect(tx - 3 * u, g - 5 * u, 6 * u, max(1, u / 2), C(0xFFFFFF, 0.6))
        }
    }

    /// What moves at the café: the swirls turning slowly round in the sky, the star halos breathing and the lamp's
    /// glow flickering.
    static func doc4CafeLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = doc4CafeFrame(c, g), u = f.u
        let cols = [C(0xF4ECA8), C(0xB8D4F4), C(0x7AA4E4), C(0xFFFFFF)]
        for (k, sw) in doc4CafeSwirls(c, g).enumerated() {
            let spin = t * (0.22 + 0.05 * Double(k)) * (k == 1 ? -1 : 1)
            for arm in 0..<3 {
                for i in 0..<40 {
                    let q = 0.12 + Double(i) / 40 * 0.95
                    let a = spin + Double(arm) * 2.094 + q * 5.2 * (k == 1 ? -1 : 1)
                    let x = sw.x + Int(cos(a) * Double(sw.rx) * q), y = sw.y + Int(sin(a) * Double(sw.ry) * q)
                    guard y >= 0, y < doc4CafeRoof(c, g, x) - 1 else { continue }
                    c.rect(x, y, 2 * u, u, cols[(i + arm) % 4].alpha(0.9 - q * 0.35))
                }
            }
            c.circle(sw.x, sw.y, u, C(0xFFF6C8, 0.8))
        }
        for (i, st) in doc4CafeStars(c, g).enumerated() {
            let p = 0.5 + 0.5 * sin(t * 1.7 + Double(i) * 1.3)
            c.circle(st.x, st.y, Int(Double(3 * u) + p * Double(2 * u)), C(0xF4E48A, 0.08 + 0.12 * p))
        }
        let flick = 0.5 + 0.5 * sin(t * 9) * sin(t * 2.3)
        c.circle(f.cafeR - 2 * u, f.awnY + 8 * u, 9 * u, C(0xFFE27A, 0.05 + 0.06 * flick))
    }
}

// MARK: - Bad Wolf Bay

extension Scenes {
    /// The bay's layout: the unit, the horizon and the line where the sea meets the sand.
    static func doc4BayFrame(_ c: PixelCanvas, _ g: Int) -> (u: Int, hy: Int, sy: Int) {
        let tall = isTall(c), u = unit(g) * (tall ? 2 : 1)
        return (u, tall ? g * 52 / 100 : g - 26 * u, g - 8 * u)
    }

    /// The top of the dunes at column `x` (`g` where there are none).
    static func doc4BayDune(_ c: PixelCanvas, _ g: Int, _ x: Int) -> Int {
        let u = doc4BayFrame(c, g).u
        var top = g
        for (cx, half, h) in [(c.w * 4 / 100, c.w * 22 / 100, 17 * u), (c.w * 98 / 100, c.w * 14 / 100, 11 * u)] {
            let d = Double(x - cx) / Double(max(1, half))
            guard abs(d) < 1 else { continue }
            let bump = sin(Double(x) * 0.11) * Double(u)
            top = min(top, g - Int(Double(h) * (1 - d * d) + bump))
        }
        return top
    }

    /// Bad Wolf Bay: a cold grey Norwegian beach. A low sky of layered cloud, far blue hills and a dark headland on the
    /// horizon, the grey sea rolling in to a strip of wet sand, and pale dunes tufted with marram grass at either end.
    static func doc4Bay(_ c: PixelCanvas, _ g: Int) {
        let f = doc4BayFrame(c, g), u = f.u, tall = isTall(c)
        c.gradient(0, f.hy, C(0x767F87), C(0xC6CAC8), bands: 8)
        // Layers of cloud.
        for i in 0..<(tall ? 26 : 12) {
            let x = Int(noise(i * 4 + 4600) * Double(c.w)), y = Int(noise(i * 4 + 4601) * Double(f.hy) * 0.85)
            let rx = (24 + Int(noise(i * 4 + 4602) * 50)) * u, ry = (2 + Int(noise(i * 4 + 4603) * 3)) * u
            c.ellipse(x, y, rx, ry, (i % 3 == 0 ? C(0x666F78) : C(0xA2A9AE)).alpha(0.55))
            c.ellipse(x + rx / 4, y - ry / 2, rx / 2, max(1, ry / 2), C(0xB8BEC0, 0.4))
        }
        // Far hills across the water on the left, a dark headland on the right.
        for x in 0..<c.w {
            let xf = Double(x)
            if x < c.w * 50 / 100 {
                let fade = min(1, Double(c.w / 2 - x) / Double(max(1, c.w / 8)))
                let hgt = ((sin(xf * 0.025 + 1) * 0.5 + 0.5) * Double(6 * u) + sin(xf * 0.09) * Double(u) + Double(2 * u)) * fade
                c.rect(x, f.hy - Int(hgt), 1, Int(hgt), C(0x7C8892))
            }
            if x > c.w * 64 / 100 {
                let k = Double(x - c.w * 64 / 100) / Double(c.w * 36 / 100)
                let hgt = min(1, k * 4) * Double(5 * u) + k * Double(4 * u) + sin(xf * 0.2) * Double(u) * 0.5
                c.rect(x, f.hy - Int(hgt), 1, Int(hgt), C(0x58646E))
            }
        }
        c.rect(0, f.hy - 2 * u, c.w, 2 * u, C(0xC6CAC8, 0.35))
        // The sea.
        for y in f.hy..<f.sy {
            let k = Double(y - f.hy) / Double(max(1, f.sy - f.hy))
            c.rect(0, y, c.w, 1, lerp(C(0x56656E), C(0x7E8E94), (k * 5).rounded(.down) / 5))
        }
        for i in 0..<(c.w * (f.sy - f.hy) / 30) {
            let x = Int(noise(i * 3 + 4610) * Double(c.w)), y = f.hy + Int(noise(i * 3 + 4611) * Double(f.sy - f.hy))
            let k = Double(y - f.hy) / Double(max(1, f.sy - f.hy))
            c.rect(x, y, Int(1 + k * 4 * noise(i + 4612)) * u + 1, 1, (i % 3 == 0 ? C(0x44525A) : C(0xA8B4B8)).alpha(0.3))
        }
        // Wet sand, then dry.
        c.rect(0, f.sy, c.w, 2 * u, C(0x8C8880))
        for y in (f.sy + 2 * u)..<g {
            let k = Double(y - f.sy) / Double(max(1, g - f.sy))
            c.rect(0, y, c.w, 1, lerp(C(0xA29C90), C(0xB8B09E), k))
        }
        c.rect(c.w * 40 / 100, g - 3 * u, 9 * u, u, C(0x6A5A48))       // a bit of driftwood
        c.rect(c.w * 40 / 100 + 2 * u, g - 4 * u, 2 * u, u, C(0x6A5A48))
        // The dunes and their grass.
        for x in 0..<c.w {
            let top = doc4BayDune(c, g, x)
            guard top < g else { continue }
            c.rect(x, top, 1, g - top, C(0xC4BAA2))
            c.rect(x, top, 1, u, C(0xD8D0BA))
            if (x / u) % 5 == 0 { c.rect(x, top + 3 * u, 1, g - top - 3 * u, C(0xB0A68E, 0.5)) }
        }
        let blades = [C(0x7C7C52), C(0x9A9862), C(0x5E6040)]
        for i in 0..<(c.w / 3) {
            let x = Int(noise(i * 3 + 4620) * Double(c.w)), top = doc4BayDune(c, g, x)
            guard top < g - 2 * u else { continue }
            let len = (3 + Int(noise(i * 3 + 4621) * 4)) * u
            for b in -1...1 { doc4Line(c, x, top + u, x + b * 2 * u, top + u - len, blades[(i + b + 1) % 3]) }
        }
        c.ground(g, C(0xBCB4A2), edge: C(0xD2CBB8), speck: C(0xA49C8A), seed: 46)
    }

    /// What moves at the bay: lines of surf rolling in, a wash of foam running up the sand and sliding back, and a
    /// couple of gulls on the wind.
    static func doc4BayLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = doc4BayFrame(c, g), u = f.u
        let period = 7.0
        for k in 0..<5 {
            let off = Double(k) * period / 5
            let p = doc4Phase(t, period, offset: off)
            let cycle = Int((t + off) / period)
            let y = f.hy + Int(Double(f.sy - f.hy) * p * p)
            let th = p > 0.6 ? 2 * u : u
            let amp = Double(u) * (0.5 + 1.5 * p)
            for x in 0..<c.w {
                // broken crests of uneven length, rising and falling along the line
                let seg = Double(x) / Double(4 * u) + noise(x / (13 * u) + k * 50) * 3
                guard noise(Int(seg) + cycle * 97 + k * 1000) > 0.25 + 0.35 * (1 - p) else { continue }
                let yy = y + Int(sin(Double(x) * 0.045 + Double(k) * 1.7 + t * 0.3) * amp)
                guard yy + th < doc4BayDune(c, g, x), yy < f.sy else { continue }
                c.rect(x, yy - u, 1, u, C(0x4A5A64, 0.3 * p))
                c.rect(x, yy, 1, th, C(0xE8ECEC, 0.15 + 0.7 * p))
            }
        }
        // The wash, up and back.
        let w = doc4Phase(t, period, offset: 0.4)
        let reach = sin(Double.pi * min(1, w * 1.4))
        let wy = f.sy + Int(reach * Double(g - f.sy - 2 * u))
        if wy > f.sy {
            for x in 0..<c.w {
                guard wy < doc4BayDune(c, g, x) else { continue }
                let edge = wy + Int(sin(Double(x) * 0.15) * Double(u))
                c.rect(x, f.sy, 1, max(0, edge - f.sy), C(0x9AA8AC, 0.35))
                c.rect(x, edge, 1, u, C(0xF0F2F0, 0.75))
            }
        }
        // Gulls.
        for i in 0..<2 {
            let span = Double(c.w + 40 * u)
            let x = Int((Double(i) * 0.5 * span + t * Double(6 + 3 * i) * Double(u)).truncatingRemainder(dividingBy: span)) - 20 * u
            let y = f.hy * (25 + 20 * i) / 100 + Int(sin(t * 0.8 + Double(i)) * Double(2 * u))
            let up = doc4Phase(t, 0.6, offset: Double(i) * 0.3) < 0.5 ? -u : 0
            let col = C(0xE8ECEC)
            c.rect(x, y, u, u, col)
            c.rect(x - u, y + up, u, u, col); c.rect(x + u, y + up, u, u, col)
            let tip = up == 0 ? -u : up
            c.rect(x - 2 * u, y + tip, u, u, col); c.rect(x + 2 * u, y + tip, u, u, col)
        }
    }
}

// MARK: - Telos

extension Scenes {
    /// The tombs' layout: the unit, where the cliff tops out, and the great gate's centre, width and height.
    static func doc4TelosFrame(_ c: PixelCanvas, _ g: Int) -> (u: Int, top: Int, gx: Int, gw: Int, gh: Int) {
        let tall = isTall(c), u = unit(g) * (tall ? 2 : 1)
        return (u, tall ? g * 30 / 100 : g - 54 * u, c.w / 2, 28 * u, 36 * u)
    }

    /// The tomb hatches set into the cliff, as boxes.
    static func doc4TelosHatches(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let f = doc4TelosFrame(c, g), u = f.u, hw = 10 * u, hh = 7 * u
        var out: [(x: Int, y: Int, w: Int, h: Int)] = []
        var row = 0
        let lowest = isTall(c) ? f.top + (g - f.top) * 35 / 100 : f.top + 6 * u
        for y in stride(from: g - 9 * u - hh, to: lowest, by: -12 * u) {
            for x in stride(from: (row % 2) * 9 * u - 4 * u, to: c.w, by: 18 * u) {
                if abs(x + hw / 2 - f.gx) < f.gw / 2 + 12 * u, y > g - f.gh - 14 * u { continue }
                if noise(x / u * 3 + row * 71 + 4760) < 0.3 { continue }
                out.append((x, y, hw, hh))
            }
            row += 1
        }
        return out
    }

    /// The tombs of the Cyberpersons on Telos: a wall of blue ice and frozen rock rising under a dim sky, rimed with
    /// snow along its top and hung with icicles, its face set with row on row of steel tomb hatches. In the middle,
    /// the great gate: two steel doors under a stepped lintel, the Cyber emblem with its handles on them.
    static func doc4Telos(_ c: PixelCanvas, _ g: Int) {
        let f = doc4TelosFrame(c, g), u = f.u
        c.gradient(0, g, C(0x121828), C(0x4A5470), bands: 8)
        c.stars(0, f.top, density: 70, seed: 47)
        if isTall(c) {
            // A pale aurora over the cliff.
            for x in 0..<c.w {
                let y = f.top / 3 + Int(sin(Double(x) * 0.02) * Double(8 * u) + sin(Double(x) * 0.05) * Double(3 * u))
                c.rect(x, y, 1, 10 * u, C(0x6AE8C0, 0.08))
                c.rect(x, y + 3 * u, 1, 4 * u, C(0x8AF4D0, 0.08))
            }
        }
        // Ice peaks behind.
        for x in 0..<c.w {
            let hgt = abs(sin(Double(x) * 0.031)) * Double(9 * u) + abs(sin(Double(x) * 0.083 + 1)) * Double(4 * u)
            c.rect(x, f.top - Int(hgt), 1, Int(hgt) + 2 * u, C(0x3A4660))
            c.rect(x, f.top - Int(hgt), 1, u, C(0x8A9CB8))
        }
        // The cliff face.
        for x in 0..<c.w {
            let top = f.top + Int(noise(x / (3 * u) + 4700) * Double(3 * u))
            c.rect(x, top, 1, g - top, C(0x6E8098))
            let n = noise(x / (2 * u) + 4710)
            if n > 0.72 { c.rect(x, top, 1, g - top, C(0x8AA0B8)) }
            if n < 0.08 { c.rect(x, top, 1, g - top, C(0x52627A)) }
            c.rect(x, top, 1, 2 * u, C(0xE6EEF6))
            if noise(x + 4720) > 0.86 {
                c.rect(x, top + 2 * u, 1, (1 + Int(noise(x + 4721) * 4)) * u, C(0xC8DCEC))
            }
        }
        // Ledges of snow across the face.
        for i in 0..<(c.w * (g - f.top) / (160 * u * u)) {
            let x = Int(noise(i * 3 + 4730) * Double(c.w)), y = f.top + 6 * u + Int(noise(i * 3 + 4731) * Double(g - f.top - 6 * u))
            c.rect(x, y, (6 + Int(noise(i * 3 + 4732) * 14)) * u, u, C(0xD8E4F0, 0.8))
        }
        for h in doc4TelosHatches(c, g) { doc4TelosHatch(c, h, u) }
        doc4TelosGate(c, g)
        // Ice underfoot, snow banked against the cliff.
        c.ground(g, C(0xB8C6D4), edge: C(0xEEF4FA), speck: C(0x98A8BA), seed: 47)
        for i in 0..<(c.w / (24 * u)) {
            let x = Int(noise(i * 3 + 4740) * Double(c.w))
            c.ellipse(x, g, (6 + Int(noise(i * 3 + 4741) * 8)) * u, 2 * u, C(0xDCE6F0))
        }
    }

    /// One tomb hatch: a steel plate in its recess, a locking bar across and a boss in the middle, frosted on top.
    static func doc4TelosHatch(_ c: PixelCanvas, _ h: (x: Int, y: Int, w: Int, h: Int), _ u: Int) {
        c.rect(h.x - u, h.y - u, h.w + 2 * u, h.h + 2 * u, C(0x2E3846))
        c.rect(h.x, h.y, h.w, h.h, C(0xA8B4C0))
        c.rect(h.x, h.y, h.w, u, C(0xD8E2EA))
        c.rect(h.x + h.w - u, h.y, u, h.h, C(0x7A8696))
        c.rect(h.x + u, h.y + h.h / 2, h.w - 2 * u, u, C(0x5A6676))
        c.rect(h.x + h.w / 2 - u, h.y + h.h / 2 - u, 2 * u, 3 * u, C(0x6A7686))
        c.rect(h.x - u, h.y - 2 * u, h.w + 2 * u, u, C(0xF0F6FA, 0.85))
    }

    /// The great gate in the middle of the cliff.
    static func doc4TelosGate(_ c: PixelCanvas, _ g: Int) {
        let f = doc4TelosFrame(c, g), u = f.u, x0 = f.gx - f.gw / 2, y0 = g - f.gh
        // Pillars and the stepped lintel.
        c.rect(x0 - 6 * u, y0 - 4 * u, f.gw + 12 * u, f.gh + 4 * u, C(0x8A98AA))
        c.rect(x0 - 6 * u, y0 - 4 * u, f.gw + 12 * u, u, C(0xE6EEF6))
        c.rect(x0 - 3 * u, y0 - 8 * u, f.gw + 6 * u, 4 * u, C(0x7A889A))
        c.rect(x0 - 3 * u, y0 - 8 * u, f.gw + 6 * u, u, C(0xE6EEF6))
        c.rect(x0, y0 - 11 * u, f.gw, 3 * u, C(0x6A788A))
        c.rect(x0, y0 - 11 * u, f.gw, u, C(0xF0F6FA))
        for x in stride(from: x0 - 4 * u, to: x0 + f.gw + 4 * u, by: 4 * u) { c.rect(x, y0 - 2 * u, 2 * u, u, C(0x4A5666)) }
        for side in [x0 - 6 * u, x0 + f.gw + 4 * u] {
            c.rect(side, y0 - 4 * u, 2 * u, f.gh + 4 * u, C(0x6A788A))
        }
        // The doors.
        c.rect(x0, y0, f.gw, f.gh, C(0x141A24))
        c.rect(x0 + u, y0 + u, f.gw - 2 * u, f.gh - u, C(0x9AA6B4))
        c.rect(f.gx, y0 + u, max(1, u / 2), f.gh - u, C(0x3A4656))
        for y in stride(from: y0 + 4 * u, to: g, by: 6 * u) {
            c.rect(x0 + 2 * u, y, f.gw - 4 * u, u, C(0x7A8696))
        }
        c.rect(x0 + u, y0 + u, f.gw - 2 * u, u, C(0xC8D2DC))
        // The Cyber emblem: a round head with handles either side.
        let ex = f.gx, ey = y0 + f.gh * 2 / 5
        c.rect(ex - 8 * u, ey - 2 * u, 3 * u, 5 * u, C(0x3A4656))
        c.rect(ex + 5 * u + 1, ey - 2 * u, 3 * u, 5 * u, C(0x3A4656))
        c.circle(ex, ey, 6 * u, C(0x3A4656))
        c.circle(ex, ey, 5 * u, C(0xC8D2DC))
        for exx in [ex - 3 * u, ex + u + 1] {
            c.rect(exx, ey - 2 * u, 2 * u, 2 * u, C(0x2A3442))
            c.rect(exx + u / 2, ey, u, u, C(0x2A3442))
        }
        c.rect(ex - 2 * u, ey + 2 * u, 4 * u + 1, u, C(0x2A3442))
        c.rect(ex - 6 * u, ey - 6 * u, 13 * u, u, C(0xF0F6FA, 0.6))
    }

    /// What moves on Telos: frost glittering on the cliff, a fine snow drifting down on the wind and a cold mist
    /// creeping along the foot of the tombs.
    static func doc4TelosLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = doc4TelosFrame(c, g), u = f.u
        for i in 0..<(isTall(c) ? 120 : 50) {
            let x = Int(noise(i * 3 + 4750) * Double(c.w))
            let y = f.top + 3 * u + Int(noise(i * 3 + 4751) * Double(g - f.top - 3 * u))
            let v = noise(i * 7 + Int(t * 2.5 + noise(i * 3 + 4752) * 10))
            guard v > 0.78 else { continue }
            let a = (v - 0.78) / 0.22
            c.rect(x, y, u, u, C(0xFFFFFF, 0.6 + 0.4 * a))
            if v > 0.88 {
                c.rect(x - u, y, u, u, C(0xE8F4FF, 0.6)); c.rect(x + u, y, u, u, C(0xE8F4FF, 0.6))
                c.rect(x, y - u, u, u, C(0xE8F4FF, 0.6)); c.rect(x, y + u, u, u, C(0xE8F4FF, 0.6))
            }
        }
        doc4Snow(c, t, y0: 0, y1: g + 4 * u, density: 140, fall: Double(7 * u), wind: Double(9 * u), seed: 47, s: u,
                 col: C(0xF0F6FC, 0.8))
        for i in 0..<5 {
            let span = Double(c.w + 80 * u)
            let x = Int((Double(i) / 5 * span + t * Double(4 * u)).truncatingRemainder(dividingBy: span)) - 40 * u
            c.ellipse(x, g - 2 * u, 30 * u, 3 * u, C(0xDCE8F4, 0.12))
        }
    }
}

// MARK: - The Dalick Asylum

extension Scenes {
    /// The asylum's layout: the unit, the dome's centre, its foot, its radii, and where the old Dalick stands.
    static func doc4AsylumFrame(_ c: PixelCanvas, _ g: Int) -> (u: Int, dx: Int, db: Int, rx: Int, ry: Int, kx: Int) {
        let tall = isTall(c), u = unit(g) * (tall ? 2 : 1)
        return (u, c.w * 66 / 100, g - 2 * u, (tall ? 62 : 46) * u, (tall ? 44 : 36) * u, c.w * 22 / 100)
    }

    /// The Dalick Asylum: a frozen planet under a bruised sky, jagged peaks white with snow. The asylum's great
    /// riveted dome lies half buried in the drifts, ribbed and ringed, a few of its slit windows still glowing and a
    /// breach torn in its shell. In the foreground an old Dalick stands half sunk in the snow, rusted, dented and
    /// leaning, its eyestalk drooping.
    static func doc4Asylum(_ c: PixelCanvas, _ g: Int) {
        let f = doc4AsylumFrame(c, g), u = f.u, tall = isTall(c)
        c.gradient(0, g, C(0x1E1A2C), C(0x7A7088), bands: 8)
        c.circle(c.w * 30 / 100, g * 22 / 100, 6 * u, C(0xD0C8DA, 0.35))
        for i in 0..<(tall ? 24 : 11) {
            let x = Int(noise(i * 4 + 4800) * Double(c.w)), y = Int(noise(i * 4 + 4801) * Double(g) * 0.6)
            c.ellipse(x, y, (30 + Int(noise(i * 4 + 4802) * 50)) * u, (2 + Int(noise(i * 4 + 4803) * 3)) * u,
                      (i % 2 == 0 ? C(0x2A2638) : C(0x4A4458)).alpha(0.65))
        }
        // Jagged peaks.
        let mb = g - 10 * u
        for x in 0..<c.w {
            let xf = Double(x)
            let tri = abs((xf * 0.021 + sin(xf * 0.006) * 0.8).truncatingRemainder(dividingBy: 2) - 1)
            let tri2 = abs((xf * 0.053 + 0.3).truncatingRemainder(dividingBy: 2) - 1)
            let tall = 0.55 + 0.45 * sin(xf * 0.013 + 2)
            let hgt = Int((1 - tri) * Double(18 * u) * tall + (1 - tri2) * Double(5 * u) + noise(x / u + 4830) * Double(u))
            c.rect(x, mb - hgt, 1, hgt + u, C(0x4A4658))
            c.rect(x, mb - hgt, 1, max(1, hgt / 3), C(0xC8C6D4))
        }
        c.dunes(base: g - 8 * u, amp: Double(2 * u), freq: 0.02, phase: 0.7, bottom: g, C(0xC8CAD6), shade: C(0xEEF0F6))
        doc4AsylumDome(c, g)
        doc4Dalick(c, f.kx, g - u, u)
        // The drifts that bury them.
        c.dunes(base: g - 4 * u, amp: Double(3 * u), freq: 0.03, phase: 0.4, bottom: g, C(0xE2E4EC), shade: C(0xFAFBFD))
        c.ground(g, C(0xD8DAE4), edge: C(0xF4F6FA), speck: C(0xB8BAC8), seed: 48)
    }

    /// The asylum's dome, half buried.
    static func doc4AsylumDome(_ c: PixelCanvas, _ g: Int) {
        let f = doc4AsylumFrame(c, g), u = f.u, cx = f.dx, b = f.db
        for dy in stride(from: -f.ry, through: 0, by: 1) {
            let k = 1 - Double(dy * dy) / Double(f.ry * f.ry)
            let half = Int(Double(f.rx) * k.squareRoot())
            let y = b + dy
            c.rect(cx - half, y, half * 2 + 1, 1, C(0x5E5C6A))
            c.rect(cx - half, y, half * 2 / 5, 1, C(0x75738A))
            c.rect(cx + half * 2 / 3, y, half / 3 + 1, 1, C(0x4A4856))
            // the meridian ribs
            for m in [-0.8, -0.5, -0.2, 0.15, 0.45, 0.75] {
                c.rect(cx + Int(m * Double(half)), y, u, 1, C(0x3E3C48))
            }
        }
        // Rings round it, with snow lying along them, and a band of slit windows.
        for ring in [0.35, 0.7] {
            let y = b - Int(Double(f.ry) * ring)
            let half = Int(Double(f.rx) * (1 - ring * ring).squareRoot())
            c.rect(cx - half, y, half * 2, u, C(0x3A3846))
            c.rect(cx - half + u, y - u, half * 2 - 2 * u, u, C(0xE6E8F0, 0.8))
        }
        let wy = b - Int(Double(f.ry) * 0.52)
        let wh = Int(Double(f.rx) * (1 - 0.52 * 0.52).squareRoot())
        for (i, x) in stride(from: cx - wh + 4 * u, to: cx + wh - 4 * u, by: 7 * u).enumerated() {
            c.rect(x, wy, 3 * u, 2 * u, noise(i + 4810) > 0.35 ? C(0xC8502A) : C(0x1A1820))
        }
        // The snow cap.
        doc4UpperEllipse(c, cx, b, f.rx * 45 / 100, f.ry, maxY: b - f.ry * 82 / 100, C(0xE8EAF0))
        // The breach.
        let hx = cx + f.rx / 3, hy = b - f.ry * 3 / 5
        c.ellipse(hx, hy, 6 * u, 4 * u, C(0x2A2834))
        c.ellipse(hx, hy + u, 4 * u, 3 * u, C(0x121018))
        for k in 0..<5 { c.rect(hx - 5 * u + k * 2 * u, hy - 4 * u + (k % 2) * u, u, 2 * u, C(0x2A2834)) }
        // The mast with its warning light.
        let top = b - f.ry
        c.rect(cx - 4 * u, top - 12 * u, u, 12 * u, C(0x3E3C48))
        c.rect(cx - 6 * u, top - 9 * u, 5 * u, u, C(0x3E3C48))
    }

    /// An old Dalick, half sunk in the snow: rusted bronze casing, rows of bumps (a few gone), a slatted shoulder
    /// band, its plunger arm stiff, its gun stick bent down, the dome dented and the eyestalk drooping, snow on top.
    /// It leans a little to the right; `x` is its middle at the foot `b`.
    static func doc4Dalick(_ c: PixelCanvas, _ x: Int, _ b: Int, _ u: Int) {
        func lean(_ y: Int) -> Int { (b - y) / 6 }
        let bronze = C(0x8A6838), light = C(0xB08A50), dark = C(0x5A4224)
        // The skirt.
        let sk = 12 * u
        for k in 0..<sk {
            let y = b - 1 - k, wd = 14 * u - 4 * u * k / sk, lx = x - wd / 2 + lean(y)
            c.rect(lx, y, wd, 1, bronze)
            c.rect(lx, y, u, 1, light)
            c.rect(lx + wd - u, y, u, 1, dark)
        }
        for r in 0..<3 {
            let y = b - 3 * u - r * 3 * u
            let wd = 14 * u - 4 * u * (b - y) / sk
            for j in 0..<4 {
                let bx = x + lean(y) + Int((Double(j) - 1.5) * Double(wd) / 4.4)
                if noise(r * 4 + j + 4820) > 0.8 {
                    c.rect(bx - u / 2, y - u / 2, u, u, C(0x2A2018))
                } else {
                    c.circle(bx, y, u, C(0x4E3A22))
                    c.px(bx - u / 2, y - u / 2, C(0xC8A060))
                }
            }
        }
        // The shoulders, slatted, and the arms.
        let sy = b - sk - 3 * u, sx = x + lean(sy)
        c.rect(sx - 5 * u, sy, 10 * u, 3 * u, C(0x7A5C30))
        for k in stride(from: -4 * u, to: 5 * u, by: 2 * u) { c.rect(sx + k, sy, max(1, u / 2), 3 * u, C(0x4A3820)) }
        c.rect(sx + 5 * u, sy + u, 4 * u, u, C(0x3A3A3A))
        c.rect(sx + 9 * u, sy - u / 2, 2 * u, 3 * u, C(0x2A2A2A))
        doc4Line(c, sx + 5 * u, sy + 2 * u, sx + 7 * u, sy + 3 * u, C(0x4A4A4A), th: max(1, u / 2))
        doc4Line(c, sx + 7 * u, sy + 3 * u, sx + 8 * u, sy + 6 * u, C(0x4A4A4A), th: max(1, u / 2))
        // The head: dome, eyestalk and lights.
        let ny = sy - 3 * u, nx = x + lean(ny)
        let hx = x + lean(ny - 2 * u)
        c.ellipse(hx, ny, 4 * u, 3 * u, bronze)
        c.rect(hx - 3 * u, ny - 2 * u, u, u, light)
        c.rect(hx + u, ny - u, u, u, C(0x3A2818))                 // a dent
        c.rect(hx - 4 * u, ny - 2 * u, u, u, C(0xE8D8A0, 0.6))
        c.rect(hx + 4 * u, ny - 2 * u, u, u, C(0x2A2018))
        doc4Line(c, hx + 3 * u, ny, hx + 8 * u, ny + 2 * u, C(0x3A3A3A), th: max(1, u / 2))
        c.circle(hx + 8 * u, ny + 2 * u, u, C(0x1E1E24))
        c.rect(nx - 4 * u, ny, 8 * u, 3 * u, C(0x5A4A30))
        for k in stride(from: 0, to: 3 * u, by: 2) { c.rect(nx - 4 * u, ny + k, 8 * u, 1, C(0x2A2218)) }
        // Snow on top.
        c.ellipse(hx - u / 2, ny - 3 * u, 3 * u, u, C(0xF0F2F6))
        c.rect(sx - 5 * u, sy - u, 4 * u, u, C(0xF0F2F6))
        c.rect(sx + u, sy - u, 3 * u, u, C(0xE8EAF0))
    }

    /// What moves at the asylum: snow driving across on a hard wind, a few of the dome's windows flickering, the
    /// mast's red light blinking and the old Dalick's eye glowing now and then.
    static func doc4AsylumLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = doc4AsylumFrame(c, g), u = f.u
        let wy = f.db - Int(Double(f.ry) * 0.52)
        let wh = Int(Double(f.rx) * (1 - 0.52 * 0.52).squareRoot())
        for (i, x) in stride(from: f.dx - wh + 4 * u, to: f.dx + wh - 4 * u, by: 7 * u).enumerated()
            where noise(i + 4810) > 0.35 {
            let v = noise(i * 11 + Int(t * 3))
            if v > 0.7 { c.rect(x, wy, 3 * u, 2 * u, C(0xFF7A4A, 0.8)) } else if v < 0.15 { c.rect(x, wy, 3 * u, 2 * u, C(0x1A1820, 0.8)) }
        }
        if doc4Phase(t, 1.6) < 0.4 {
            let top = f.db - f.ry
            c.circle(f.dx - 4 * u, top - 13 * u, 2 * u, C(0xFF3A2A, 0.3))
            c.rect(f.dx - 4 * u, top - 13 * u, u, u, C(0xFF5A3A))
        }
        let eye = doc4Phase(t, 4.5)
        if eye > 0.6, eye < 0.85 {
            let ny = g - u - 12 * u - 6 * u, hx = f.kx + (g - u - (ny - 2 * u)) / 6
            c.rect(hx + 8 * u, ny + 2 * u, u, u, C(0x8AD4FF))
            c.circle(hx + 8 * u, ny + 2 * u, 2 * u, C(0x8AD4FF, 0.25))
        }
        doc4Snow(c, t, y0: 0, y1: c.h, density: isTall(c) ? 120 : 80, fall: Double(16 * u), wind: Double(-22 * u), seed: 48, s: u)
    }
}

// MARK: - Sanctuary Base 6

extension Scenes {
    /// The base's layout: the unit, the viewport's box, the black hole's centre and radius, and the two struts.
    static func doc4SanctuaryFrame(_ c: PixelCanvas, _ g: Int)
        -> (u: Int, x0: Int, y0: Int, x1: Int, y1: Int, cx: Int, cy: Int, r: Int, struts: [Int]) {
        let tall = isTall(c), u = unit(g) * (tall ? 2 : 1)
        let x0 = c.w * (tall ? 10 : 22) / 100, x1 = c.w - x0
        let y0 = (tall ? 6 : 4) * u, y1 = tall ? g * 62 / 100 : g - 22 * u
        let cy = (y0 + y1) / 2, r = tall ? (y1 - y0) / 6 : 7 * u
        let span = x1 - x0
        return (u, x0, y0, x1, y1, c.w / 2, cy, r, [x0 + span * 16 / 100, x1 - span * 16 / 100])
    }

    /// Whether a point is out in space, through the viewport's glass (not on its frame or struts).
    static func doc4SanctuaryPane(_ c: PixelCanvas, _ g: Int, _ x: Int, _ y: Int) -> Bool {
        let f = doc4SanctuaryFrame(c, g), u = f.u, ch = 6 * u
        guard x >= f.x0, x < f.x1, y >= f.y0, y < f.y1 else { return false }
        if (x - f.x0) + (y - f.y0) < ch || (f.x1 - 1 - x) + (y - f.y0) < ch { return false }
        for s in f.struts where abs(x - s) <= u { return false }
        return true
    }

    /// Sanctuary Base 6: a mining base on a world that should not be there, inside, in the warm gloom of riveted
    /// panels and pipes. Through the great viewport overhead hangs the black hole, a perfect black disc ringed by its
    /// blazing accretion disc, the light of the far side bent up over the top. Consoles with green screens line the
    /// wall below, hazard stripes along the sill, a big stencilled 6 by the bulkhead.
    static func doc4Sanctuary(_ c: PixelCanvas, _ g: Int) {
        let f = doc4SanctuaryFrame(c, g), u = f.u
        c.gradient(0, g, C(0x24201E), C(0x3E3832), bands: 6)
        // Panels and rivets.
        for y in stride(from: 0, to: g, by: 12 * u) {
            c.rect(0, y, c.w, u, C(0x1C1A18))
            c.rect(0, y + u, c.w, max(1, u / 2), C(0x4E4842, 0.6))
            for x in stride(from: (y / (12 * u)) % 2 * 10 * u, to: c.w, by: 20 * u) {
                c.rect(x, y, u, 12 * u, C(0x1C1A18))
                c.rect(x + 2 * u, y + 2 * u, u, u, C(0x5A544C))
                c.rect(x + 2 * u, y + 9 * u, u, u, C(0x5A544C))
            }
        }
        // The viewport: frame, then space.
        c.rect(f.x0 - 4 * u, f.y0 - 4 * u, f.x1 - f.x0 + 8 * u, f.y1 - f.y0 + 8 * u, C(0x1A1816))
        c.rect(f.x0 - 3 * u, f.y0 - 3 * u, f.x1 - f.x0 + 6 * u, f.y1 - f.y0 + 6 * u, C(0x5A5650))
        c.rect(f.x0 - 3 * u, f.y0 - 3 * u, f.x1 - f.x0 + 6 * u, u, C(0x8A847A))
        for y in f.y0..<f.y1 {
            for x in f.x0..<f.x1 where doc4SanctuaryPane(c, g, x, y) || f.struts.contains(where: { abs(x - $0) <= u }) {
                c.px(x, y, C(0x05040A))
            }
        }
        c.stars(f.y0, f.y1, density: 26, seed: 49, x0: f.x0, x1: f.x1) { doc4SanctuaryPane(c, g, $0, $1) }
        // The black hole and its disc.
        let cx = f.cx, cy = f.cy, r = f.r
        let rx = r * 34 / 10, ry = max(2 * u, r * 6 / 10)
        c.ellipse(cx, cy, rx * 13 / 10, ry * 3, C(0x5A2A10, 0.35))
        c.circle(cx, cy, r * 2, C(0x6A3214, 0.3))
        doc4SanctuaryDisc(c, cx, cy, rx, ry, minY: Int.min)
        doc4UpperEllipse(c, cx, cy, r + 3 * u, r + 3 * u, maxY: cy, C(0xE8903A))
        doc4UpperEllipse(c, cx, cy, r + 2 * u, r + 2 * u, maxY: cy, C(0xFFD890))
        c.circle(cx, cy, r + u, C(0x6A3010))
        c.circle(cx, cy, r, C(0x000000))
        doc4SanctuaryDisc(c, cx, cy, rx, ry, minY: cy)
        // The struts, the sill's hazard stripes and the frame's bolts.
        for s in f.struts {
            c.rect(s - u, f.y0, 2 * u + 1, f.y1 - f.y0, C(0x4A4642))
            c.rect(s - u, f.y0, u, f.y1 - f.y0, C(0x6A6660))
        }
        for y in f.y1..<(f.y1 + 3 * u) {
            for x in (f.x0 - 3 * u)..<(f.x1 + 3 * u) {
                c.px(x, y, ((x + y) / (2 * u)) % 2 == 0 ? C(0xD8A820) : C(0x1A1A1A))
            }
        }
        for x in stride(from: f.x0, to: f.x1, by: 12 * u) { c.rect(x, f.y0 - 2 * u, u, u, C(0xA09A8E)) }
        c.rect(f.x0 - 3 * u, f.y0, 3 * u, f.y1 - f.y0, C(0x4A4642))
        c.rect(f.x1, f.y0, 3 * u, f.y1 - f.y0, C(0x4A4642))
        // Pipes along the wall under the sill.
        let py = f.y1 + 5 * u
        c.rect(0, py, c.w, 2 * u, C(0x5A5048)); c.rect(0, py, c.w, max(1, u / 2), C(0x8A7E70))
        c.rect(0, py + 3 * u, c.w, 2 * u, C(0x6A3A2A)); c.rect(0, py + 3 * u, c.w, max(1, u / 2), C(0x9A5A40))
        for x in stride(from: 6 * u, to: c.w, by: 30 * u) { c.rect(x, py - u, 2 * u, 7 * u, C(0x2A2622)) }
        // Bulkheads either side, with the stencilled 6.
        for bx in [f.x0 - 18 * u, f.x1 + 12 * u] {
            c.rect(bx, 0, 6 * u, g, C(0x2E2A26))
            c.rect(bx, 0, u, g, C(0x56504A))
            for y in stride(from: g - 10 * u, to: g, by: 1) {
                c.rect(bx, y, 6 * u, 1, ((y / (2 * u)) % 2 == 0) ? C(0xD8A820) : C(0x1A1A1A))
            }
        }
        let six = [".###", "#...", "####", "#..#", "####"]
        let sx = max(2 * u, f.x0 - 34 * u), sy = g - 34 * u, ss = 2 * u
        for (rr, row) in six.enumerated() {
            for (k, ch) in row.enumerated() where ch == "#" { c.rect(sx + k * ss, sy + rr * ss, ss, ss, C(0xC89A3A, 0.85)) }
        }
        // Consoles along the bottom.
        let cx0 = c.w * 18 / 100, cx1 = c.w - cx0
        c.rect(cx0, g - 9 * u, cx1 - cx0, 9 * u, C(0x3A3E42))
        c.rect(cx0, g - 9 * u, cx1 - cx0, u, C(0x6A7076))
        for x in stride(from: cx0 + 4 * u, to: cx1 - 10 * u, by: 16 * u) {
            c.rect(x, g - 7 * u, 8 * u, 4 * u, C(0x102A1C))
            c.rect(x + u, g - 6 * u, 5 * u, max(1, u / 2), C(0x4AE08A, 0.8))
            c.rect(x + u, g - 4 * u - 1, 3 * u, max(1, u / 2), C(0x4AE08A, 0.6))
        }
        // A warm cast of the disc's light over everything.
        c.rect(0, 0, c.w, g, C(0xFF7A2A, 0.05))
        c.ground(g, C(0x2E2C2A), edge: C(0x8A8478), speck: C(0x22201E), seed: 49)
        for x in stride(from: 0, to: c.w, by: 5 * u) { c.rect(x, g + 1, max(1, u / 2), c.h - g - 1, C(0x1E1C1A)) }
    }

    /// The accretion disc's layers, from the dull outer rim to the white-hot inner edge (rows from `minY` down).
    static func doc4SanctuaryDisc(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, minY: Int) {
        let layers: [(Double, Px)] = [(1, C(0xA8441A)), (0.8, C(0xE07028)), (0.6, C(0xFFA848)), (0.4, C(0xFFE0A0))]
        for (k, col) in layers {
            doc4LowerEllipse(c, cx, cy, Int(Double(rx) * k), max(1, Int(Double(ry) * k)), minY: minY, col)
        }
    }

    /// What moves at the base: the accretion disc swirling round the black hole, faster towards the middle, the
    /// consoles' readouts blinking and an amber warning beacon turning on the bulkhead.
    static func doc4SanctuaryLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = doc4SanctuaryFrame(c, g), u = f.u
        let rx = Double(f.r * 34 / 10), ry = Double(max(2 * u, f.r * 6 / 10))
        let cols = [C(0xFFF4D0), C(0xFFC060), C(0xE0702A), C(0xFFFFFF)]
        for i in 0..<(isTall(c) ? 200 : 80) {
            let q = 0.4 + noise(i * 3 + 4900) * 0.65
            let a = noise(i * 3 + 4901) * 2 * Double.pi + t * 0.9 / q
            let x = f.cx + Int(cos(a) * rx * q), y = f.cy + Int(sin(a) * ry * q)
            let dx = x - f.cx, dy = y - f.cy
            if sin(a) < 0, dx * dx + dy * dy <= (f.r + u) * (f.r + u) { continue }
            guard doc4SanctuaryPane(c, g, x, y) else { continue }
            c.rect(x, y, 2 * u, max(1, u / 2 + (q < 0.6 ? 1 : 0)), cols[Int(q * 3.3) % 4].alpha(0.85))
        }
        // The photon ring shimmering.
        let sh = 0.5 + 0.5 * sin(t * 2.2)
        for k in 0..<24 {
            let a = Double.pi + Double(k) / 23 * Double.pi
            let x = f.cx + Int(cos(a) * Double(f.r + 2 * u)), y = f.cy + Int(sin(a) * Double(f.r + 2 * u))
            if noise(k + Int(t * 4)) > 0.6 { c.rect(x, y, u, u, C(0xFFF6D8, 0.5 + 0.5 * sh)) }
        }
        // Console readouts.
        let cx0 = c.w * 18 / 100, cx1 = c.w - cx0
        for (i, x) in stride(from: cx0 + 4 * u, to: cx1 - 10 * u, by: 16 * u).enumerated() {
            let n = Int(noise(i * 7 + Int(t * 3)) * 6)
            c.rect(x + u, g - 5 * u, n * u, max(1, u / 2), C(0x8AFFB0, 0.8))
            if noise(i * 5 + Int(t * 2)) > 0.5 { c.rect(x + 6 * u, g - 4 * u, u, u, C(0xFF5A3A)) }
        }
        // The beacon on the right bulkhead.
        let bx = f.x1 + 15 * u, by = g - 16 * u
        let p = doc4Phase(t, 1.4)
        c.rect(bx - u, by, 2 * u + 1, 2 * u, C(0x8A5A10))
        c.circle(bx, by, Int(2 + 4 * (1 - abs(p * 2 - 1))) * u, C(0xFFB02A, 0.15 + 0.3 * (1 - abs(p * 2 - 1))))
        c.rect(bx - u, by - u, 2 * u + 1, u, C(0xFFC84A, 0.5 + 0.5 * (1 - abs(p * 2 - 1))))
    }
}

// MARK: - Christmas London

extension Scenes {
    /// The city's layout: the unit, the ship's centre, its deepest row and its half width, and the clock tower's
    /// middle and top.
    static func doc4LondonFrame(_ c: PixelCanvas, _ g: Int) -> (u: Int, sx: Int, sb: Int, srx: Int, tx: Int, tt: Int) {
        let tall = isTall(c), u = unit(g) * (tall ? 2 : 1)
        return (u, c.w * 54 / 100, tall ? g * 36 / 100 : g * 30 / 100, c.w * (tall ? 46 : 42) / 100,
                c.w * 85 / 100, g - (tall ? 80 : 46) * u)
    }

    /// The underside of the ship at column `x` (0 where it isn't).
    static func doc4LondonShip(_ c: PixelCanvas, _ g: Int, _ x: Int) -> Int {
        let f = doc4LondonFrame(c, g), u = f.u
        let d = Double(x - f.sx) / Double(max(1, f.srx))
        guard abs(d) < 1 else { return 0 }
        let jag = (noise(x / (3 * u) + 5000) - 0.5) * Double(4 * u) + sin(Double(x) * 0.07) * Double(2 * u)
        let spike = noise(x / (4 * u) + 5010) > 0.88 ? Double((3 + Int(noise(x / (4 * u) + 5011) * 6)) * u) : 0
        return max(0, Int(Double(f.sb) * (1 - d * d).squareRoot() + jag + spike * (1 - abs(d))))
    }

    /// The houses of one row of roofs, as left edge, width, eave and ridge.
    static func doc4LondonHouses(_ c: PixelCanvas, _ g: Int, eave: Int, seed: Int) -> [(x: Int, w: Int, e: Int, r: Int)] {
        let u = doc4LondonFrame(c, g).u
        var out: [(x: Int, w: Int, e: Int, r: Int)] = []
        var x = -Int(noise(seed) * Double(10 * u)), k = 0
        while x < c.w {
            let w = (20 + Int(noise(seed + k * 5 + 1) * 16)) * u
            let e = eave - Int(noise(seed + k * 5 + 2) * 5) * u
            out.append((x, w, e, e - (6 + Int(noise(seed + k * 5 + 3) * 4)) * u))
            x += w + u; k += 1
        }
        return out
    }

    /// Where the fairy lights hang along the near row of eaves, and what colour each is.
    static func doc4LondonLights(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, col: Px)] {
        let u = doc4LondonFrame(c, g).u
        let cols = [C(0xFF4A4A), C(0x4AE07A), C(0x5A9AFF), C(0xFFD04A)]
        var out: [(x: Int, y: Int, col: Px)] = []
        for (hk, h) in doc4LondonHouses(c, g, eave: g - 14 * u, seed: 5030).enumerated() {
            let n = max(2, h.w / (3 * u))
            for k in 0...n {
                let y = h.e + u + Int(sin(Double.pi * Double(k) / Double(n)) * Double(2 * u))
                out.append((h.x + h.w * k / n, y, cols[(k + hk) % 4]))
            }
        }
        return out
    }

    /// Christmas in London: snowy rooftops at night. Row behind row of slate roofs, white with snow, chimney pots
    /// smoking into the cold, warm windows lit, fairy lights strung along the eaves, the clock tower standing over it
    /// all with its face aglow. And hanging over the city, filling the sky, the vast craggy rock of the Sycorax ship,
    /// its underside lit orange.
    static func doc4London(_ c: PixelCanvas, _ g: Int) {
        let f = doc4LondonFrame(c, g), u = f.u
        c.gradient(0, g, C(0x080C22), C(0x3A3456), bands: 8)
        c.stars(0, g / 2, density: 90, seed: 50)
        c.rect(0, g - 30 * u, c.w, 30 * u, C(0x8A5A4A, 0.12))
        if isTall(c) { doc4LondonSkyline(c, g) }
        doc4LondonTower(c, g)
        // Far roofs in silhouette.
        for h in doc4LondonHouses(c, g, eave: g - 24 * u, seed: 5020) {
            c.rect(h.x, h.e, h.w, g - h.e, C(0x1A1E36))
            doc4RoofTop(c, h, C(0x1A1E36), snow: C(0x8A90A8), u: u)
            for wy in stride(from: h.e + 3 * u, to: g - 14 * u, by: 6 * u) {
                for wx in stride(from: h.x + 3 * u, to: h.x + h.w - 3 * u, by: 6 * u) where noise(wx + wy * 7 + 5021) > 0.7 {
                    c.rect(wx, wy, 2 * u, 3 * u, C(0xE8B860, 0.7))
                }
            }
        }
        // The near roofs, with their windows and lights.
        for h in doc4LondonHouses(c, g, eave: g - 14 * u, seed: 5030) {
            c.rect(h.x, h.e, h.w, g - h.e, C(0x3A2A2E))
            for wy in stride(from: h.e + 4 * u, to: g - 3 * u, by: 7 * u) {
                for wx in stride(from: h.x + 3 * u, to: h.x + h.w - 4 * u, by: 7 * u) {
                    let lit = noise(wx * 3 + wy + 5031) > 0.45
                    c.rect(wx, wy, 3 * u, 4 * u, lit ? C(0xF0C060) : C(0x1A1626))
                    c.rect(wx, wy + 4 * u, 3 * u, u, C(0xE8ECF4))
                }
            }
            doc4RoofTop(c, h, C(0x2A2C40), snow: C(0xDCE2EE), u: u)
            c.rect(h.x, h.e - u, h.w, u, C(0xE8ECF4))
        }
        for l in doc4LondonLights(c, g) {
            c.px(l.x, l.y - 1, C(0x101018))
            c.rect(l.x, l.y, u, u, l.col.alpha(0.45))
        }
        doc4LondonShipDraw(c, g)
        c.ground(g, C(0xC8D0DC), edge: C(0xF0F4F8), speck: C(0xA8B2C2), seed: 50)
    }

    /// A roof on a house: slate sloping in from both ends to the ridge, snow over the top, a chimney stack with pots.
    static func doc4RoofTop(_ c: PixelCanvas, _ h: (x: Int, w: Int, e: Int, r: Int), _ slate: Px, snow: Px, u: Int) {
        let rh = h.e - h.r
        for k in 0..<rh {
            let inset = k * 3 / 2
            c.rect(h.x + inset, h.e - 1 - k, max(1, h.w - 2 * inset), 1, k >= rh - 2 * u ? snow : slate)
            c.rect(h.x + inset, h.e - 1 - k, u, 1, snow.alpha(0.7))
        }
        let cx = h.x + h.w * 7 / 10
        c.rect(cx, h.r - 4 * u, 4 * u, 6 * u, C(0x5A3428))
        c.rect(cx, h.r - 4 * u, 4 * u, u, snow)
        c.rect(cx + u / 2, h.r - 6 * u, u, 2 * u, C(0x8A5A3A))
        c.rect(cx + 2 * u + u / 2, h.r - 6 * u, u, 2 * u, C(0x8A5A3A))
    }

    /// On the screen saver, the far city beyond the roofs: towers and blocks dotted with windows, and the great
    /// cathedral dome.
    static func doc4LondonSkyline(_ c: PixelCanvas, _ g: Int) {
        let u = doc4LondonFrame(c, g).u, base = g - 20 * u
        var x = 0, k = 0
        while x < c.w {
            let bw = (8 + Int(noise(k * 3 + 5070) * 14)) * u, bh = (10 + Int(noise(k * 3 + 5071) * 26)) * u
            c.rect(x, base - bh, bw, bh + 20 * u, C(0x1C2240))
            for wy in stride(from: base - bh + 2 * u, to: base, by: 4 * u) {
                for wx in stride(from: x + u, to: x + bw - u, by: 3 * u) where noise(wx * 5 + wy + 5072) > 0.78 {
                    c.rect(wx, wy, u, u, C(0xE8B860, 0.5))
                }
            }
            x += bw; k += 1
        }
        let dx = c.w * 24 / 100, db = base - 18 * u
        c.rect(dx - 14 * u, db, 28 * u, 20 * u, C(0x1C2240))
        c.rect(dx - 9 * u, db - 6 * u, 18 * u, 6 * u, C(0x1A1E36))
        doc4UpperEllipse(c, dx, db - 6 * u, 9 * u, 9 * u, maxY: db - 6 * u, C(0x1A1E36))
        c.rect(dx - u, db - 19 * u, 2 * u, 4 * u, C(0x1A1E36))
        c.rect(dx - 20 * u, db + 2 * u, 4 * u, 10 * u, C(0x1C2240)); c.rect(dx - 19 * u, db - 2 * u, 2 * u, 4 * u, C(0x1C2240))
        c.rect(dx + 16 * u, db + 2 * u, 4 * u, 10 * u, C(0x1C2240)); c.rect(dx + 17 * u, db - 2 * u, 2 * u, 4 * u, C(0x1C2240))
    }

    /// The clock tower, far off, its face lit.
    static func doc4LondonTower(_ c: PixelCanvas, _ g: Int) {
        let f = doc4LondonFrame(c, g), u = f.u, x = f.tx, top = f.tt
        let shaft = C(0x262840), edge = C(0x3A3C58)
        c.rect(x - 3 * u, top + 14 * u, 6 * u, g - top - 14 * u, shaft)
        c.rect(x - 3 * u, top + 14 * u, u, g - top - 14 * u, edge)
        c.rect(x - 4 * u, top + 7 * u, 8 * u, 7 * u, C(0x2E3048))
        c.circle(x, top + 10 * u, 2 * u, C(0xF0E0A0))
        c.rect(x, top + 9 * u, max(1, u / 2), u + 1, C(0x3A2A1A))
        c.rect(x, top + 10 * u, u, max(1, u / 2), C(0x3A2A1A))
        c.rect(x - 3 * u, top + 4 * u, 6 * u, 3 * u, shaft)
        c.rect(x - 2 * u, top + 5 * u, u, u, C(0xE8B860, 0.6)); c.rect(x + u, top + 5 * u, u, u, C(0xE8B860, 0.6))
        for k in 0..<(4 * u) {
            let wd = max(1, 6 * u - k * 6 / 4)
            c.rect(x - wd / 2, top + 4 * u - 1 - k, wd, 1, shaft)
        }
        c.rect(x, top - 2 * u, max(1, u / 2), 2 * u, shaft)
        c.rect(x - 4 * u, top + 6 * u, u, 2 * u, shaft); c.rect(x + 3 * u, top + 6 * u, u, 2 * u, shaft)
    }

    /// The Sycorax ship: a mountain of rock hanging in the sky.
    static func doc4LondonShipDraw(_ c: PixelCanvas, _ g: Int) {
        let f = doc4LondonFrame(c, g), u = f.u
        for x in 0..<c.w {
            let b = doc4LondonShip(c, g, x)
            guard b > 0 else { continue }
            c.rect(x, 0, 1, b, C(0x3A322C))
            if noise(x / (2 * u) + 5040) > 0.6 { c.rect(x, 0, 1, b - 3 * u, C(0x463C34)) }
            if noise(x / (5 * u) + 5041) < 0.15 { c.rect(x, 0, 1, b - 4 * u, C(0x2A2420)) }
            c.rect(x, b - 2 * u, 1, 2 * u, C(0x6A5646))
            c.rect(x, b - u, 1, u, C(0x8A6A50))
        }
        // Craters and crags across the face.
        for i in 0..<(c.w * f.sb / (90 * u * u)) {
            let x = Int(noise(i * 3 + 5050) * Double(c.w)), y = Int(noise(i * 3 + 5051) * Double(f.sb))
            guard y < doc4LondonShip(c, g, x) - 5 * u else { continue }
            let r = (1 + Int(noise(i * 3 + 5052) * 3)) * u
            c.ellipse(x, y, r * 2, r, C(0x241E1A))
            c.rect(x - r * 2, y + r, r * 4, max(1, u / 2), C(0x5A4C40))
        }
        // Glowing ports on the underside.
        for i in 0..<(isTall(c) ? 26 : 12) {
            let x = f.sx + Int((noise(i * 2 + 5060) - 0.5) * 1.6 * Double(f.srx))
            let b = doc4LondonShip(c, g, x)
            guard b > 6 * u else { continue }
            c.rect(x, b - 4 * u, 2 * u, u, C(0xFF8A3A, 0.85))
        }
    }

    /// What moves in London: snow falling over the rooftops, the fairy lights twinkling, the ship's ports pulsing and
    /// smoke curling from the chimney pots.
    static func doc4LondonLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = doc4LondonFrame(c, g), u = f.u
        for (i, l) in doc4LondonLights(c, g).enumerated() where noise(i * 13 + Int(t * 2)) > 0.35 {
            c.rect(l.x - u, l.y - u, 3 * u, 3 * u, l.col.alpha(0.25))
            c.rect(l.x, l.y, u, u, l.col)
        }
        let pulse = 0.5 + 0.5 * sin(t * 1.4)
        for i in 0..<(isTall(c) ? 26 : 12) {
            let x = f.sx + Int((noise(i * 2 + 5060) - 0.5) * 1.6 * Double(f.srx))
            let b = doc4LondonShip(c, g, x)
            guard b > 6 * u else { continue }
            c.rect(x - u, b - 5 * u, 4 * u, 3 * u, C(0xFFA05A, 0.15 + 0.3 * pulse))
        }
        for h in doc4LondonHouses(c, g, eave: g - 14 * u, seed: 5030) {
            let cx = h.x + h.w * 7 / 10 + u
            for k in 0..<4 {
                let p = doc4Phase(t, 3, offset: Double(k) * 0.75 + noise(h.x) * 3)
                let y = h.r - 7 * u - Int(p * Double(10 * u))
                let x = cx + Int(sin(p * 5 + t) * Double(u)) + Int(p * Double(4 * u))
                c.rect(x, y, 2 * u, 2 * u, C(0xB8BCCC, 0.3 * (1 - p)))
            }
        }
        doc4Snow(c, t, y0: 0, y1: c.h, density: 110, fall: Double(9 * u), wind: Double(3 * u), seed: 50, s: u)
    }
}
