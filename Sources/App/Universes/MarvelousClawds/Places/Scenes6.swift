import Foundation

let scenes6: [Location: Place] = [
    .xandar: Place(name: "Xandarr", panel: 0x161E2A, still: Scenes.xandar, moving: Scenes.xandarLife),
    .avengersCompound: Place(name: "Clawdvengers Compound", panel: 0x16201A, still: Scenes.avengersCompound,
                             moving: Scenes.compoundLife),
    .tva: Place(name: "Time Variation Agency", panel: 0x221A12, still: Scenes.tva, moving: Scenes.tvaLife),
    .krakoa: Place(name: "Krakova", panel: 0x142016, still: Scenes.krakoa, moving: Scenes.krakoaLife),
    .morlockTunnels: Place(name: "Morlock Tunnels", panel: 0x141410, still: Scenes.morlockTunnels,
                           moving: Scenes.morlockLife),
    .asteroidM: Place(name: "Asteroid M2", panel: 0x161420, still: Scenes.asteroidM, moving: Scenes.asteroidMLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes6Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes6Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// A tiny 3×5 pixel alphabet for the signs and the graffiti.
    static let scenes6Font: [Character: [String]] = [
        "A": [".#.", "#.#", "###", "#.#", "#.#"], "C": ["###", "#..", "#..", "#..", "###"],
        "E": ["###", "#..", "##.", "#..", "###"], "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
        "L": ["#..", "#..", "#..", "#..", "###"], "M": ["#.#", "###", "###", "#.#", "#.#"],
        "O": ["###", "#.#", "#.#", "#.#", "###"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
        "S": ["###", "#..", "###", "..#", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."],
        "V": ["#.#", "#.#", "#.#", "#.#", ".#."], "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
        "X": ["#.#", "#.#", ".#.", "#.#", "#.#"], "I": ["###", ".#.", ".#.", ".#.", "###"],
    ]

    /// Pixel letters from `scenes6Font`, each pixel `s` square; returns the width drawn.
    @discardableResult
    static func scenes6Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, s: Int) -> Int {
        var cx = x
        for ch in text {
            if let rows = scenes6Font[ch] { scenes6Stamp(c, cx, y, rows, ["#": col], s: s) }
            cx += 4 * s
        }
        return cx - x - s
    }

    /// A jagged ridge of rock from `x0` to `x1`, up to `h` rows above `base`.
    static func scenes6Ridge(_ c: PixelCanvas, x0: Int, x1: Int, base: Int, h: Int, _ col: Px, top: Px, seed: Int) {
        guard x1 > x0 else { return }
        for x in x0..<x1 {
            let u = Double(x - x0) / Double(x1 - x0)
            let env = sin(u * .pi)
            let j = sin(Double(x) * 0.21 + Double(seed)) * 0.25 + sin(Double(x) * 0.077 + Double(seed) * 2.3) * 0.35
            let y = base - Int(Double(h) * max(0, env * (0.7 + j)))
            if y < base { c.rect(x, y, 1, base - y, col); c.px(x, y, top) }
        }
    }
}

// MARK: - Xandar

extension Scenes {
    /// The Nova Corps headquarters: centre, dome radii and the plaza row its podium stands on.
    static func xandarHQ(_ c: PixelCanvas, _ g: Int) -> (x: Int, rx: Int, ry: Int, base: Int) {
        let s = unit(g), ry = Int(Double(g) * (isTall(c) ? 0.26 : 0.36))
        return (Int(Double(c.w) * 0.6), min(ry * 17 / 10, c.w / 4), ry, g - 7 * s - max(5 * s, g / 12))
    }

    /// The nodes of the Nova Corps' starblaster net, row by row.
    static func xandarNet(_ c: PixelCanvas, _ g: Int) -> [[(x: Int, y: Int)]] {
        let s = unit(g), tall = isTall(c)
        let rows = tall ? 3 : 2, gap = tall ? g / 14 : 5 * s, y0 = tall ? g / 10 : 3 * s, dx = 22 * s
        var out: [[(x: Int, y: Int)]] = []
        for r in 0..<rows {
            var row: [(x: Int, y: Int)] = []
            for x in stride(from: -dx + (r % 2) * dx / 2, to: c.w + dx, by: dx) {
                let sag = Int(sin(Double(x) / Double(c.w) * .pi) * Double(tall ? g / 16 : 2 * s))
                row.append((x, y0 + r * gap + sag))
            }
            out.append(row)
        }
        return out
    }

    /// One Nova Corps starblaster, gold and white, `dir` 1 flying right and -1 left.
    static func xandarShip(_ c: PixelCanvas, _ x: Int, _ y: Int, dir: Int, s: Int, engine: Bool) {
        var rows = [
            "..yy.......",
            ".wwyyy.....",
            "ywwwwwwwbb.",
            ".gwwwwwwwwk",
            "..yy.......",
        ]
        if dir < 0 { rows = rows.map { String($0.reversed()) } }
        scenes6Stamp(c, x, y, rows, ["y": C(0xF2C230), "w": C(0xF4F4F0), "g": C(0xB8BCC6), "b": C(0x6ABEF0),
                                     "k": C(0xD8A020)], s: s)
        if engine {
            let ex = dir > 0 ? x - 2 * s : x + 11 * s
            c.rect(ex, y + 2 * s, 2 * s, s, C(0xFFE27A, 0.8)); c.rect(dir > 0 ? ex - s : ex + 2 * s, y + 2 * s, s, s, C(0xFFE27A, 0.35))
        }
    }

    /// Xandar on a bright day: the gleaming white-and-gold Nova capital, rounded towers, saucer-topped spires and the
    /// great star-crowned dome of the Nova Corps headquarters, under a sky criss-crossed by the golden net of linked
    /// starblasters, with a white plaza, gold inlays and topiary planters underfoot.
    static func xandar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x3F78CC), C(0xF4E4BC), bands: 8)
        let sx = Int(Double(c.w) * 0.16), sy = Int(Double(g) * (tall ? 0.3 : 0.4))
        c.circle(sx, sy, max(8, g / 5), C(0xFFF4D0, 0.10)); c.circle(sx, sy, max(5, g / 9), C(0xFFF4D0, 0.18))
        c.circle(sx, sy, max(3, g / 22), C(0xFFFBEA))
        if tall {
            for i in 0..<6 {
                cloud(c, Int(noise(i * 5 + 610) * Double(c.w)), g / 5 + Int(noise(i * 5 + 611) * Double(g / 4)),
                      (3 + Int(noise(i * 5 + 612) * 4)) * s, seed: i + 60)
            }
        }
        // the net: thin gold beams between the starblasters holding station
        let net = xandarNet(c, g)
        for (r, row) in net.enumerated() {
            for k in 0..<(row.count - 1) {
                let a = row[k], b = row[k + 1]
                c.glowLine(Double(a.x), Double(a.y), Double(b.x), Double(b.y), core: C(0xFFE07A, 0.55), glow: C(0xFFD050, 0.2),
                           coreR: 0.4, glowR: 1.2)
                if r + 1 < net.count {
                    let d = net[r + 1][min(k + (r % 2), net[r + 1].count - 1)]
                    c.glowLine(Double(a.x), Double(a.y), Double(d.x), Double(d.y), core: C(0xFFE07A, 0.4),
                               glow: C(0xFFD050, 0.15), coreR: 0.4, glowR: 1.2)
                }
            }
        }
        for row in net { for p in row { c.rect(p.x - s, p.y - s / 2, 3 * s, max(1, s), C(0xF6F2E0)); c.px(p.x, p.y, C(0xFFD050)) } }
        // far towers in the haze
        var x = -4 * s, i = 0
        while x < c.w {
            let bw = (5 + Int(noise(i * 7 + 601) * 8)) * s
            let bh = Int(Double(g) * (0.3 + noise(i * 7 + 602) * 0.32))
            let col = C(0xCAD8EA)
            c.rect(x, g - bh, bw, bh, col)
            c.ellipse(x + bw / 2, g - bh, bw / 2, max(1, bw / 3), col)
            if noise(i * 7 + 603) > 0.6 { c.rect(x + bw / 2, g - bh - bw, max(1, s), bw, col) }
            x += bw + Int(noise(i * 7 + 604) * 7) * s
            i += 1
        }
        c.rect(0, g - g * 2 / 5, c.w, g * 2 / 5, C(0xF6E8C4, 0.3))
        // near towers, leaving room around the headquarters
        let hq = xandarHQ(c, g)
        x = 2 * s; i = 0
        while x < c.w {
            let bw = (9 + Int(noise(i * 9 + 631) * 9)) * s
            if x + bw > hq.x - hq.rx - 6 * s && x < hq.x + hq.rx + 6 * s { x = hq.x + hq.rx + 8 * s; continue }
            xandarTower(c, g, x: x, w: bw, h: Int(Double(g) * (0.32 + noise(i * 9 + 632) * 0.34)), kind: i % 3, seed: i)
            x += bw + (6 + Int(noise(i * 9 + 633) * 16)) * s
            i += 1
        }
        xandarHQDraw(c, g)
        // the plaza's balustrade, planters and the white paving
        let rail = g - 5 * s
        c.rect(0, rail, c.w, 5 * s, C(0xE6E8EC, 0.55))
        c.rect(0, rail, c.w, s, C(0xD9A93A))
        for px in stride(from: 3 * s, to: c.w, by: 6 * s) { c.rect(px, rail + s, 2 * s, 4 * s, C(0xF4F5F7)) }
        for px in stride(from: 30 * s, to: c.w, by: 70 * s) {
            c.rect(px - 4 * s, g - 6 * s, 8 * s, 6 * s, C(0xF2F3F5)); c.rect(px - 4 * s, g - 6 * s, 8 * s, s, C(0xD9A93A))
            c.rect(px + 2 * s, g - 5 * s, 2 * s, 5 * s, C(0xCDD2DA))
            c.rect(px - s / 2, g - 10 * s, max(1, s), 4 * s, C(0x6A5A3A))
            c.circle(px, g - 12 * s, 4 * s, C(0x3E8A4A)); c.circle(px - s, g - 13 * s, 3 * s, C(0x5AAE5E))
        }
        c.ground(g, C(0xDCDEE2), edge: C(0xD9A93A), speck: C(0xC9CDD4), seed: 61)
        for px in stride(from: 0, to: c.w, by: 24 * s) { c.rect(px, g + 2 * s, s, c.h - g - 2 * s, C(0xD9B85A, 0.6)) }
        c.rect(0, g + (c.h - g) / 2, c.w, max(1, s), C(0xD9B85A, 0.5))
    }

    /// One white Xandarian tower: a capsule shaft, a saucer-topped spire or a stepped fin, trimmed in gold.
    static func xandarTower(_ c: PixelCanvas, _ g: Int, x: Int, w: Int, h: Int, kind: Int, seed: Int) {
        let s = unit(g), white = C(0xF2F4F6), shade = C(0xC8D0DC), gold = C(0xD9A93A), glass = C(0x7FA8D8)
        let y = g - h
        switch kind {
        case 0:                                               // a rounded capsule tower
            c.rect(x, y + w / 2, w, h - w / 2, white)
            c.ellipse(x + w / 2, y + w / 2, w / 2, w / 2, white)
            c.rect(x + w * 2 / 3, y + w / 2, w - w * 2 / 3, h - w / 2, shade)
            c.rect(x + w / 2 - s, y + w / 2, 2 * s, h - w / 2, glass)
        case 1:                                               // a slim spire with a saucer near the top
            let sw = max(3 * s, w / 3), sx = x + (w - sw) / 2
            c.rect(sx, y, sw, h, white); c.rect(sx + sw - s, y, s, h, shade)
            c.ellipse(x + w / 2, y + h / 6, w, max(2 * s, w / 4), white)
            c.rect(x + w / 2 - w, y + h / 6, w * 2, s, gold)
            c.rect(x + w / 2 - w + 2 * s, y + h / 6 + s, w * 2 - 4 * s, s, shade)
            c.rect(x + w / 2, y - h / 5, max(1, s), h / 5, white)
        default:                                              // stepped fins
            for k in 0..<3 {
                let iw = w - k * w / 4, ih = h - k * h / 4
                c.rect(x + (w - iw) / 2, g - ih, iw, ih, k % 2 == 0 ? white : C(0xE6EAF0))
                c.rect(x + (w - iw) / 2 + iw - s, g - ih, s, ih, shade)
                c.rect(x + (w - iw) / 2, g - ih, iw, s, gold)
            }
        }
        for yy in stride(from: y + w, to: g - 4 * s, by: 7 * s) where noise(seed * 13 + yy) > 0.3 {
            c.rect(x + s, yy, w - 2 * s, s, kind == 1 ? glass.alpha(0.5) : gold.alpha(0.8))
        }
    }

    /// The Nova Corps headquarters: a tiered podium under a great white dome ribbed in gold, crowned with the
    /// Corps' star.
    static func xandarHQDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), hq = xandarHQ(c, g), gold = C(0xD9A93A)
        // the dome, lit from the left
        c.ellipse(hq.x, hq.base, hq.rx, hq.ry, C(0xD2D8E2))
        c.ellipse(hq.x - hq.rx / 8, hq.base - hq.ry / 12, hq.rx * 7 / 8, hq.ry * 9 / 10, C(0xEEF1F5))
        c.ellipse(hq.x - hq.rx / 3, hq.base - hq.ry / 2, hq.rx / 4, hq.ry / 4, C(0xFFFFFF, 0.6))
        for k in -3...3 {                                     // gold ribs following the curve
            for y in (hq.base - hq.ry)..<hq.base {
                let dy = Double(hq.base - y) / Double(hq.ry)
                let half = Double(hq.rx) * (1 - dy * dy).squareRoot()
                c.px(hq.x + Int(half * Double(k) / 4), y, gold.alpha(0.8))
            }
        }
        for f in [0.35, 0.7] {                                // and rings around it
            let y = hq.base - Int(Double(hq.ry) * f)
            let half = Int(Double(hq.rx) * (1 - f * f).squareRoot())
            c.rect(hq.x - half, y, half * 2, max(1, s), gold)
        }
        // the glass band at the dome's foot
        c.rect(hq.x - hq.rx, hq.base - 4 * s, hq.rx * 2, 4 * s, C(0x5A86C0))
        for x in stride(from: hq.x - hq.rx, to: hq.x + hq.rx, by: 4 * s) { c.rect(x, hq.base - 4 * s, s, 4 * s, C(0xE8ECF2)) }
        // the podium tiers
        let pod = g - 7 * s - hq.base
        c.rect(hq.x - hq.rx - 6 * s, hq.base, hq.rx * 2 + 12 * s, pod, C(0xE8EBEF))
        c.rect(hq.x - hq.rx - 6 * s, hq.base, hq.rx * 2 + 12 * s, s, gold)
        for x in stride(from: hq.x - hq.rx - 4 * s, to: hq.x + hq.rx + 5 * s, by: 5 * s) {
            c.rect(x, hq.base + 2 * s, 2 * s, pod - 2 * s, C(0xC6CDD8))
        }
        c.rect(hq.x - hq.rx - 12 * s, g - 7 * s, hq.rx * 2 + 24 * s, 2 * s, C(0xF4F5F7))
        c.rect(hq.x - hq.rx - 12 * s, g - 7 * s, hq.rx * 2 + 24 * s, s, gold)
        // the Nova star on top: a gold starburst in a ring, on a short mast
        let top = hq.base - hq.ry, r = max(4 * s, hq.ry / 4), cy = top - r - 2 * s
        c.rect(hq.x - s / 2, cy, max(1, s), top - cy, gold)
        c.circle(hq.x, cy, r + 2 * s, C(0xFFE07A, 0.16))
        let u = Double(r)
        for k in 0..<8 {
            let a = Double(k) * .pi / 4 - .pi / 2, len = k % 2 == 0 ? u * 1.25 : u * 0.7
            c.glowLine(Double(hq.x), Double(cy), Double(hq.x) + cos(a) * len, Double(cy) + sin(a) * len, core: C(0xFFD34A),
                       glow: C(0xFFE07A, 0.5), coreR: Double(s) * 0.7, glowR: Double(s) * 1.4)
        }
        c.circle(hq.x, cy, max(1, r / 3), C(0xFFF6D0))
        for k in 0..<36 {
            let a = Double(k) / 36 * 2 * .pi
            c.px(hq.x + Int(cos(a) * u * 0.95), cy + Int(sin(a) * u * 0.95), C(0xD9A93A))
        }
    }

    /// Nova Corps starblasters patrolling across the sky, and the net's nodes twinkling.
    static func xandarLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        for (r, row) in xandarNet(c, g).enumerated() {
            for (k, p) in row.enumerated() where sin(t * 2.2 + Double(k) * 0.9 + Double(r) * 1.7) > 0.75 {
                c.circle(p.x, p.y, 2 * s, C(0xFFE07A, 0.35)); c.px(p.x, p.y, C(0xFFFBE0))
            }
        }
        let flights: [(y: Double, speed: Double, dir: Int, n: Int, off: Double)] = [
            (tall ? 0.36 : 0.30, 30, 1, 3, 0), (tall ? 0.5 : 0.44, 22, -1, 2, 5), (tall ? 0.24 : 0.22, 40, 1, 1, 11),
        ]
        for f in flights {
            let speed = f.speed * Double(s), travel = Double(c.w + 80 * s), cycle = travel / speed + 4
            let ph = (t + f.off).truncatingRemainder(dividingBy: cycle) * speed
            for k in 0..<f.n {
                let along = Int(ph) - k * 16 * s - 20 * s
                let x = f.dir > 0 ? along : c.w - along
                let y = Int(Double(g) * f.y) + k * 3 * s + Int(sin(t * 1.3 + Double(k)) * Double(s))
                xandarShip(c, x, y, dir: f.dir, s: s, engine: true)
            }
        }
    }
}

// MARK: - Clawdvengers Compound

extension Scenes {
    /// The compound's frame: left edge, width, roof row of the long block and of the tall centre block.
    static func compoundFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, roof: Int, tower: Int) {
        let s = unit(g), base = g - 8 * s
        let bh = isTall(c) ? Int(Double(g) * 0.2) : Int(Double(g) * 0.3)
        let w = max(150 * s, Int(Double(c.w) * 0.46))
        return (Int(Double(c.w) * 0.3), w, base - bh, base - bh * 2)
    }

    /// The helipad's centre, with the Quinjet parked on it.
    static func compoundPad(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int) {
        let s = unit(g), f = compoundFrame(c, g)
        return (min(c.w - 30 * s, f.x + f.w + 44 * s), g - 3 * s)
    }

    /// The Clawdvengers Compound upstate on a summer afternoon: wooded hills and the lake on the left, the long white
    /// building with its ribbon glazing and the dark glass centre block bearing the claw emblem, the helipad with a
    /// Quinjet parked on it and the windsock, and a striped mown lawn underfoot.
    static func avengersCompound(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x4F86CC), C(0xDDEBF2), bands: 7)
        for i in 0..<(tall ? 7 : 3) {
            cloud(c, Int(noise(i * 5 + 700) * Double(c.w)), Int(Double(g) * (tall ? 0.12 + noise(i * 5 + 701) * 0.35 : 0.12)),
                  (3 + Int(noise(i * 5 + 702) * 3)) * s, seed: i + 70)
        }
        // far hills and the treeline
        c.dunes(base: g - Int(Double(g) * 0.3), amp: Double(g) * 0.06, freq: 0.012, phase: 2, bottom: g, C(0x7E9CA8))
        c.dunes(base: g - Int(Double(g) * 0.22), amp: Double(g) * 0.05, freq: 0.02, phase: 0.5, bottom: g, C(0x5A7A6A))
        let tree = g - Int(Double(g) * 0.14)
        for x in stride(from: -2 * s, to: c.w, by: 3 * s) {
            let h = (4 + Int(noise(x * 3 + 711) * 6)) * s
            c.ellipse(x, tree - h / 2, 3 * s, h / 2 + s, noise(x + 712) > 0.5 ? C(0x2E5A36) : C(0x3A6A3E))
        }
        c.rect(0, tree, c.w, g - tree, C(0x2E5A36))
        // the lake on the left, mirroring the trees
        let lx1 = Int(Double(c.w) * 0.27), ly0 = tree + s, ly1 = g - 5 * s
        if ly1 > ly0 {
            for x in 0..<lx1 {
                let shore = lx1 - Int(noise(x / 4 + 720) * 6.0) * s - (x > lx1 - 12 * s ? (x - lx1 + 12 * s) : 0)
                guard x < shore else { continue }
                c.rect(x, ly0, 1, ly1 - ly0, C(0x4F82B4))
            }
            c.rect(0, ly0, lx1 - 8 * s, max(1, (ly1 - ly0) / 3), C(0x2E5A46, 0.6))
            for k in 0..<(lx1 / 6) {
                let x = Int(noise(k * 3 + 730) * Double(lx1 - 14 * s)), y = ly0 + 2 * s + Int(noise(k * 3 + 731) * Double(max(1, ly1 - ly0 - 3 * s)))
                c.rect(x, y, (2 + Int(noise(k * 3 + 732) * 5)) * s, max(1, s), C(0xB8D8F0, 0.7))
            }
            c.rect(0, ly1, lx1, s, C(0xC8B888))
            // a little dock
            c.rect(lx1 / 2, ly0 + (ly1 - ly0) / 2, 16 * s, s, C(0x8A6A4A))
            c.rect(lx1 / 2 + 15 * s, ly0 + (ly1 - ly0) / 2, s, (ly1 - ly0) / 2, C(0x6A4E36))
        }
        c.rect(lx1, ly1 - 2 * s, c.w - lx1, g - ly1 + 2 * s, C(0x5A8A3E))
        c.rect(0, ly1 + s, c.w, g - ly1 - s, C(0x5A8A3E))
        compoundBuilding(c, g)
        compoundPadDraw(c, g)
        // the lawn, mown in stripes
        c.ground(g, C(0x5E9440), edge: C(0x88B860), speck: C(0x528636), seed: 71)
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + s, 12 * s, c.h - g - s, C(0x6AA04A, 0.7)) }
        c.rect(Int(Double(c.w) * 0.52), g + s, 10 * s, c.h - g - s, C(0xC8C4B4))   // the path to the door
    }

    /// The long white building, its wings and the dark glass centre block with the claw emblem.
    static func compoundBuilding(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = compoundFrame(c, g), base = g - 8 * s, bh = base - f.roof
        let white = C(0xEDEFEF), shade = C(0xC4CACE), glass = C(0x2C3E54), sky = C(0x7FA4C8)
        // the low left wing, then the long main block
        let wx = f.x - 40 * s
        c.rect(wx, base - bh * 3 / 5, 42 * s, bh * 3 / 5, white)
        c.rect(wx, base - bh * 3 / 5, 42 * s, s, shade)
        c.rect(wx + 2 * s, base - bh * 2 / 5, 38 * s, bh / 5 + s, glass)
        c.rect(f.x, f.roof, f.w, bh, white)
        c.rect(f.x - 2 * s, f.roof - s, f.w + 4 * s, 2 * s, C(0xA8B0B8))
        for (k, y) in [f.roof + bh / 5, f.roof + bh * 3 / 5].enumerated() {
            let gh = max(2 * s, bh / 4)
            c.rect(f.x + 3 * s, y, f.w - 6 * s, gh, glass)
            c.rect(f.x + 3 * s, y, f.w - 6 * s, max(1, gh / 3), sky.alpha(0.5))
            for x in stride(from: f.x + 3 * s + k * 3 * s, to: f.x + f.w - 3 * s, by: 7 * s) { c.rect(x, y, s, gh, white) }
        }
        c.rect(f.x + f.w - 6 * s, f.roof, 6 * s, bh, shade)
        // the centre block: dark glass between white fins, the claw emblem up top
        let cw = max(34 * s, bh * 3 / 2), cx = f.x + f.w * 2 / 5 - cw / 2
        c.rect(cx - 3 * s, f.tower - 2 * s, cw + 6 * s, base - f.tower + 2 * s, white)
        c.rect(cx, f.tower, cw, base - f.tower, C(0x22344A))
        for x in stride(from: cx + 4 * s, to: cx + cw, by: 5 * s) { c.rect(x, f.tower, s, base - f.tower, C(0x3A5272)) }
        c.rect(cx, f.tower, cw / 3, base - f.tower, sky.alpha(0.18))
        c.rect(cx - 6 * s, f.tower - 3 * s, cw + 12 * s, 2 * s, C(0xF6F7F7))
        let r = min(cw / 3, (f.roof - f.tower) / 2 + 2 * s)
        compoundEmblem(c, cx + cw / 2, f.tower + r + 3 * s, r, s: s)
        // the entrance canopy and doors
        let dx = Int(Double(c.w) * 0.52) - 4 * s
        c.rect(dx - 6 * s, base - 9 * s, 30 * s, 2 * s, C(0xD8DCDE))
        c.rect(dx, base - 7 * s, 18 * s, 7 * s, C(0x3A5272)); c.rect(dx + 9 * s, base - 7 * s, s, 7 * s, white)
        // a flagpole by the door
        let fx = dx + 30 * s, fy = base - bh - 6 * s
        c.rect(fx, fy, max(1, s), bh + 6 * s, C(0xC8CCD0))
        c.rect(fx + s, fy, 8 * s, 5 * s, C(0xF4F4F0))
        for k in 0..<3 { c.rect(fx + s, fy + k * 2 * s, 8 * s, s, C(0xC83A3A)) }
        c.rect(fx + s, fy, 4 * s, 3 * s, C(0x2A3A7A))
        // the drive in front
        c.rect(f.x - 40 * s, base, f.w + 40 * s, 3 * s, C(0xB8B8B0)); c.rect(f.x - 40 * s, base, f.w + 40 * s, s, C(0xD8D8D0))
    }

    /// The Clawdvengers emblem: a ring with a C (for Clawd) inside it, open to the right.
    static func compoundEmblem(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, s: Int) {
        let u = Double(r) / 7, lx = Double(x), ly = Double(y), col = C(0xF4F6F8)
        for k in 0..<Int(Double(r) * 7) {
            let a = Double(k) / (Double(r) * 7) * 2 * .pi
            let rr = Double(r) - u * 0.5
            c.rect(x + Int(cos(a) * rr), y + Int(sin(a) * rr), max(1, Int(u)), max(1, Int(u)), col)
        }
        let stroke = { (x0: Double, y0: Double, x1: Double, y1: Double) in
            c.glowLine(lx + x0 * u, ly + y0 * u, lx + x1 * u, ly + y1 * u, core: col, glow: C(0xBFE4FF, 0.3),
                       coreR: 0.8 * u, glowR: 1.1 * u)
        }
        let arc: [(Double, Double)] = stride(from: 45.0, through: 315.0, by: 30.0).map { (deg: Double) -> (Double, Double) in
            let r: Double = deg * .pi / 180
            return (3.6 * cos(r), 3.6 * sin(r))
        }
        for (a, b) in zip(arc, arc.dropFirst()) { stroke(a.0, a.1, b.0, b.1) }
        stroke(-1, 0, 9, 0); stroke(9, 0, 7, -2); stroke(9, 0, 7, 2)   // the bar out through the ring, an arrow
    }

    /// The helipad and the parked Quinjet; the windsock's pole.
    static func compoundPadDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = compoundPad(c, g), q = max(s, g / 100)
        c.ellipse(p.x, p.y, 34 * s, 4 * s, C(0x6A6E72))
        c.ellipse(p.x, p.y, 32 * s, 3 * s, C(0x8A8E92))
        c.ellipse(p.x, p.y, 24 * s, 2 * s, C(0xE8C83A)); c.ellipse(p.x, p.y, 22 * s, 2 * s, C(0x8A8E92))
        // the Quinjet, nose to the left, gear down
        let qx = p.x - 17 * q, qy = p.y - 13 * q
        scenes6Stamp(c, qx, qy, [
            "........................ff.",
            ".......................fff.",
            "......................ffff.",
            "....ccdddddddddddddddddddd.",
            "..ccddddddddddddddddddddddd",
            "kdddddddddddddddddddddddddd",
            ".mmmmmmmwwwwwwwwwwwwwwmmmmm",
            "....mmmmmmmmmmmmmmmmmmmm...",
            ".......mmm.......mmm.......",
            "........l.........l........",
            "........l.........l........",
            ".......lll.......lll.......",
        ], ["d": C(0x4A525E), "m": C(0x363C46), "c": C(0x8AD8FF), "k": C(0x2A2E36), "w": C(0x6A7482),
            "f": C(0x3E4652), "l": C(0x222630)], s: q)
        c.ellipse(p.x - 3 * q, p.y, 15 * q, max(1, q), C(0x000000, 0.2))
        // the windsock's pole
        let wx = p.x + 34 * s
        if wx < c.w - 2 * s {
            c.rect(wx, p.y - 22 * s, max(1, s), 22 * s, C(0xC8CCD0))
            c.rect(wx - s, p.y - s, 3 * s, s, C(0x8A8E92))
        }
    }

    /// The windsock fluttering, the Quinjet's navigation lights and birds crossing over the lake.
    static func compoundLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), p = compoundPad(c, g), q = max(s, g / 100)
        let wx = p.x + 34 * s
        if wx < c.w - 2 * s {
            let y = p.y - 22 * s
            for k in 0..<5 {
                let droop = Int((sin(t * 3 + Double(k) * 0.8) * 0.6 + Double(k) * 0.35) * Double(s))
                c.rect(wx + s + k * 2 * s, y + droop, 2 * s, max(1, 2 * s - k * s / 3), k % 2 == 0 ? C(0xF07830) : C(0xF4F4F0))
            }
        }
        let qx = p.x - 17 * q, qy = p.y - 13 * q
        if scenes6Phase(t, 1.2) < 0.5 { c.rect(qx + 26 * q, qy + 5 * q, q, q, C(0xFF4040)) }
        if scenes6Phase(t, 1.2, offset: 0.6) < 0.5 { c.rect(qx + 24 * q, qy, q, q, C(0x40FF70)) }
        // birds
        for b in 0..<4 {
            let speed = 14.0 * Double(s), cycle = Double(c.w + 40 * s) / speed + 6
            let ph = (t + Double(b) * 0.6).truncatingRemainder(dividingBy: cycle) * speed
            let x = Int(ph) - 20 * s + (b % 2) * 6 * s, y = Int(Double(g) * 0.28) + b * 3 * s - (b / 2) * 5 * s
            let up = sin(t * 9 + Double(b)) > 0
            c.rect(x, y, s, s, C(0x2A2E36))
            c.rect(x - 2 * s, y + (up ? -s : s), 2 * s, s, C(0x2A2E36)); c.rect(x + s, y + (up ? -s : s), 2 * s, s, C(0x2A2E36))
        }
    }
}

// MARK: - Time Variance Authority

extension Scenes {
    /// The big clock: centre and radius.
    static func tvaClock(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let s = unit(g)
        let r = isTall(c) ? Int(Double(g) * 0.16) : max(10, Int(Double(g) * 0.23))
        return (c.w / 2, isTall(c) ? Int(Double(g) * 0.3) : 6 * s + r, r)
    }

    /// The windows onto the end-of-time city, as column ranges, and their top and bottom rows.
    static func tvaWindows(_ c: PixelCanvas, _ g: Int) -> (cols: [(Int, Int)], y0: Int, y1: Int) {
        let s = unit(g), cl = tvaClock(c, g), ww = isTall(c) ? Int(Double(g) * 0.26) : 46 * s, gap = 34 * s
        var cols: [(Int, Int)] = []
        var x = cl.x + cl.r + 22 * s
        while x < c.w { cols.append((x, x + ww)); x += ww + gap }
        x = cl.x - cl.r - 22 * s
        while x > 0 { cols.append((x - ww, x)); x -= ww + gap }
        let y0 = isTall(c) ? g / 9 : 7 * s
        return (cols, y0, isTall(c) ? g - Int(Double(g) * 0.24) : g - 22 * s)
    }

    /// The pneumatic tube's row and the drop-tubes' columns.
    static func tvaTube(_ c: PixelCanvas, _ g: Int) -> (y: Int, drops: [Int]) {
        let s = unit(g), win = tvaWindows(c, g)
        return (win.y0 - 4 * s, win.cols.map { $0.0 - 14 * s })
    }

    /// The Time Variance Authority: a 1970s bureaucracy at the end of time, brown panelled walls, beige filing
    /// cabinets, desks with chunky CRT terminals, brass-and-glass pneumatic tubes, the big orange Miss Seconds clock
    /// over the TVA logo, and tall windows onto the golden city where the Time-Keepers' statues loom.
    static func tva(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), win = tvaWindows(c, g)
        // the city outside, across the whole width, the wall goes over it with the windows left open
        c.gradient(0, win.y1, C(0xC8603A), C(0xF6CC84), bands: 6)
        c.ellipse(c.w / 3, win.y0 + (win.y1 - win.y0) / 3, c.w / 3, (win.y1 - win.y0) / 6, C(0xFFE0A0, 0.18))
        var x = 0, i = 0
        while x < c.w {
            let bw = (4 + Int(noise(i * 5 + 801) * 8)) * s
            let bh = Int(Double(win.y1 - win.y0) * (0.25 + noise(i * 5 + 802) * 0.5))
            c.rect(x, win.y1 - bh, bw, bh, C(0xA0603E))
            c.rect(x + bw / 2, win.y1 - bh - bw, max(1, s), bw, C(0xA0603E))
            x += bw + Int(noise(i * 5 + 803) * 4) * s
            i += 1
        }
        x = 0; i = 0
        while x < c.w {
            let bw = (6 + Int(noise(i * 5 + 811) * 8)) * s
            let bh = Int(Double(win.y1 - win.y0) * (0.15 + noise(i * 5 + 812) * 0.3))
            c.rect(x, win.y1 - bh, bw, bh, C(0x6E3E28))
            for yy in stride(from: win.y1 - bh + 2 * s, to: win.y1, by: 3 * s) where noise(yy + i * 7) > 0.5 {
                c.rect(x + s, yy, bw - 2 * s, max(1, s), C(0xFFD27A, 0.6))
            }
            x += bw + s
            i += 1
        }
        for (k, col) in win.cols.enumerated() { tvaStatue(c, g, x: (col.0 + col.1) / 2, top: win.y0, base: win.y1, seed: k) }
        // the wall around the windows
        let wall = C(0x5A3A24), panel = C(0x4A2E1C)
        c.rect(0, 0, c.w, win.y0, wall)
        c.rect(0, win.y1, c.w, g - win.y1, wall)
        let sorted = win.cols.sorted { $0.0 < $1.0 }
        var left = 0
        for col in sorted { c.rect(left, win.y0, col.0 - left, win.y1 - win.y0, wall); left = col.1 }
        c.rect(left, win.y0, c.w - left, win.y1 - win.y0, wall)
        for col in sorted {                                   // window frames and mullions
            let w = col.1 - col.0
            c.rect(col.0 - 2 * s, win.y0 - 2 * s, w + 4 * s, 2 * s, C(0x2E1C10))
            c.rect(col.0 - 2 * s, win.y1, w + 4 * s, 2 * s, C(0xC8803A))
            c.rect(col.0 - 2 * s, win.y0, 2 * s, win.y1 - win.y0, C(0x2E1C10)); c.rect(col.1, win.y0, 2 * s, win.y1 - win.y0, C(0x2E1C10))
            for k in 1..<3 { c.rect(col.0 + w * k / 3, win.y0, s, win.y1 - win.y0, C(0x2E1C10, 0.8)) }
            c.rect(col.0, win.y0 + (win.y1 - win.y0) / 3, w, s, C(0x2E1C10, 0.8))
        }
        // ceiling with light panels
        c.rect(0, 0, c.w, 3 * s, C(0x2A1A10))
        if tall {
            for x in stride(from: 8 * s, to: c.w, by: 40 * s) { c.rect(x, 0, 24 * s, 2 * s, C(0xFFE8B0, 0.8)) }
            c.rect(0, 3 * s, c.w, g / 40, C(0x3E2616))
        }
        // the wainscot with orange stripes, the 70s touch
        let wain = g - 14 * s
        c.rect(0, wain, c.w, g - wain, panel)
        c.rect(0, wain, c.w, s, C(0xE08A3A)); c.rect(0, wain + 2 * s, c.w, s, C(0xC8602A)); c.rect(0, wain + 4 * s, c.w, s, C(0x8A3E1E))
        tvaTubes(c, g)
        tvaClockDraw(c, g)
        tvaFurniture(c, g)
        c.ground(g, C(0x6A4428), edge: C(0xD8843A), speck: C(0x5A3820), seed: 81)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + s, s, c.h - g - s, C(0x52341E)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0x52341E))
    }

    /// One Time-Keeper statue far off in the city: a towering robed figure on a plinth, its hands folded, bronze
    /// catching the golden light on one side and hazed by distance.
    static func tvaStatue(_ c: PixelCanvas, _ g: Int, x: Int, top: Int, base: Int, seed: Int) {
        let s = unit(g), h = Int(Double(base - top) * (0.72 + noise(seed + 830) * 0.12)), y = base - h
        let body = C(0x7A5638), lit = C(0xE8B470), dark = C(0x5A3E28)
        let hw = max(2 * s, h / 12)
        c.rect(x - hw * 2, base - hw * 2, hw * 4, hw * 2, dark)                    // plinth
        c.rect(x - hw * 2, base - hw * 2, hw * 4, max(1, s), lit.alpha(0.7))
        let robeTop = y + hw * 2, robeBottom = base - hw * 2
        for yy in robeTop..<robeBottom {                                           // the robe: broad shoulders, flaring hem
            let u = Double(yy - robeTop) / Double(max(1, robeBottom - robeTop))
            let half = Int(Double(hw) * (u < 0.15 ? 1.2 + u * 3 : 1.65 + max(0, u - 0.7) * 1.6))
            c.rect(x - half, yy, half * 2, 1, body)
            c.rect(x - half, yy, max(1, half / 3), 1, lit)
            c.rect(x + half - max(1, half / 4), yy, max(1, half / 4), 1, dark)
        }
        for k in 1..<4 { c.rect(x - k * hw / 3, robeTop + hw * 3, max(1, s), robeBottom - robeTop - hw * 3, dark.alpha(0.6)) }
        c.rect(x - hw * 3 / 2, robeTop + hw * 2, hw * 3, max(1, hw / 2), lit.alpha(0.8))     // folded hands
        c.ellipse(x, y + hw, hw * 3 / 4, hw, body)                                 // the head
        c.rect(x - hw * 3 / 4, y + hw / 2, max(1, hw / 3), hw, lit)
        c.rect(x - hw / 3, y - hw / 3, hw * 2 / 3, hw / 2, lit)                    // crown
    }

    /// The brass-banded glass tubes along the ceiling and down to the desks.
    static func tvaTubes(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tb = tvaTube(c, g), r = 3 * s
        c.rect(0, tb.y - r / 2, c.w, r, C(0xE8DCC0, 0.35))
        c.rect(0, tb.y - r / 2, c.w, s, C(0xFFF4E0, 0.6)); c.rect(0, tb.y + r / 2, c.w, s, C(0x8A6A3A))
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.rect(x, tb.y - r / 2 - s, 2 * s, r + 2 * s, C(0xC89A4A)) }
        for x in tb.drops where x > 4 * s && x < c.w - 4 * s {
            let bottom = g - 22 * s
            c.rect(x - r / 2, tb.y, r, bottom - tb.y, C(0xE8DCC0, 0.35))
            c.rect(x - r / 2, tb.y, s, bottom - tb.y, C(0xFFF4E0, 0.5))
            c.rect(x - r / 2 - s, bottom - 3 * s, r + 2 * s, 4 * s, C(0xC89A4A))
            c.rect(x - r / 2 - s, bottom + s, r + 2 * s, s, C(0x6A4A2A))
            for y in stride(from: tb.y + 10 * s, to: bottom - 4 * s, by: 14 * s) { c.rect(x - r / 2 - s, y, r + 2 * s, s, C(0xC89A4A)) }
        }
    }

    /// The big Miss Seconds clock on its orange roundel, and the TVA sign under it.
    static func tvaClockDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), k = tvaClock(c, g), r = k.r
        c.rect(k.x - r - 10 * s, 3 * s, (r + 10 * s) * 2, g - 17 * s, C(0x4A2E1C))
        c.rect(k.x - r - 10 * s, 3 * s, s, g - 17 * s, C(0x2E1C10)); c.rect(k.x + r + 10 * s - s, 3 * s, s, g - 17 * s, C(0x2E1C10))
        c.circle(k.x, k.y, r + 4 * s, C(0xC8602A))
        c.circle(k.x, k.y, r + 2 * s, C(0xF08A30))
        c.circle(k.x, k.y, r, C(0xF6E2B4))
        for h in 0..<12 {
            let a = Double(h) / 12 * 2 * .pi, big = h % 3 == 0
            let r0 = Double(r) * (big ? 0.78 : 0.86)
            for d in stride(from: r0, to: Double(r) * 0.95, by: 0.5) {
                c.rect(k.x + Int(sin(a) * d), k.y - Int(cos(a) * d), big ? max(1, s) : 1, big ? max(1, s) : 1, C(0x5A3420))
            }
        }
        // Miss Seconds: a thin red second hand sweeping up to two o'clock behind her face, then big cartoon eyes
        // and a grin
        let sa = 2.0 / 12 * 2 * .pi
        c.glowLine(Double(k.x), Double(k.y), Double(k.x) + sin(sa) * Double(r) * 0.8, Double(k.y) - cos(sa) * Double(r) * 0.8,
                   core: C(0xD8302A), glow: C(0xD8302A, 0), coreR: max(0.5, Double(s) * 0.5), glowR: max(0.6, Double(s) * 0.55))
        c.circle(k.x, k.y, max(1, r / 12), C(0xD8302A))
        let e = max(2, r / 5)
        for side in [-1, 1] {
            c.ellipse(k.x + side * r * 3 / 10, k.y - r / 4, max(1, e * 2 / 3), e, C(0xFFFFFF))
            c.ellipse(k.x + side * r * 3 / 10, k.y - r / 4 + e / 3, max(1, e / 3), max(1, e / 2), C(0x2A1A10))
            c.rect(k.x + side * r * 3 / 10 - e / 2, k.y - r / 4 - e - max(1, e / 3), e, max(1, e / 3), C(0x8A4A1E))
        }
        for dx in -(r * 2 / 5)...(r * 2 / 5) {
            let u = Double(dx) / Double(r * 2 / 5)
            c.px(k.x + dx, k.y + r * 3 / 10 + Int((1 - u * u) * Double(r) * 0.15), C(0x8A3A1E))
            c.px(k.x + dx, k.y + r * 3 / 10 + Int((1 - u * u) * Double(r) * 0.15) + 1, C(0x8A3A1E))
        }
        c.circle(k.x - r * 3 / 5, k.y + r / 6, max(1, r / 9), C(0xF0A070, 0.6)); c.circle(k.x + r * 3 / 5, k.y + r / 6, max(1, r / 9), C(0xF0A070, 0.6))
        // the TVA sign
        let ts = isTall(c) ? max(s, r / 7) : s, tw = 11 * ts, ty = k.y + r + 4 * s + 2 * ts
        if ty + 7 * ts <= g - 14 * s || isTall(c) {
            c.rect(k.x - tw / 2 - 3 * ts, ty - 2 * ts, tw + 6 * ts, 9 * ts, C(0xC8602A))
            c.rect(k.x - tw / 2 - 2 * ts, ty - ts, tw + 4 * ts, 7 * ts, C(0xF08A30))
            scenes6Text(c, k.x - tw / 2, ty, "TVA", C(0x3A2010), s: ts)
        }
    }

    /// Filing cabinets and desks with CRT terminals along the wainscot.
    static func tvaFurniture(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), k = tvaClock(c, g), cab = C(0xCDBB8E), cabS = C(0xA8946A)
        var x = 4 * s, i = 0
        while x < c.w - 10 * s {
            if abs(x + 10 * s - k.x) < k.r + 22 * s { x += 12 * s; continue }
            if i % 3 == 1 {                                   // a desk and its terminal
                c.rect(x, g - 9 * s, 26 * s, 2 * s, C(0x8A5A30)); c.rect(x, g - 7 * s, 2 * s, 7 * s, C(0x5A3A20))
                c.rect(x + 18 * s, g - 7 * s, 8 * s, 7 * s, C(0x6A4426)); c.rect(x + 19 * s, g - 5 * s, 6 * s, s, C(0xC89A4A))
                c.rect(x + 3 * s, g - 18 * s, 12 * s, 9 * s, C(0xD8CCA8)); c.rect(x + 14 * s, g - 18 * s, s, 9 * s, C(0xA89A78))
                c.rect(x + 5 * s, g - 16 * s, 8 * s, 6 * s, C(0x14281A))
                c.rect(x + 4 * s, g - 10 * s, 10 * s, s, C(0xB8AC88))
                c.rect(x + 2 * s, g - 10 * s, 14 * s, s, C(0xA89A78))
                x += 32 * s
            } else {                                          // a pair of filing cabinets
                for n in 0..<2 {
                    let cx = x + n * 9 * s, hh = (i % 2 == 0 ? 20 : 15) * s
                    c.rect(cx, g - hh, 8 * s, hh, cab); c.rect(cx + 7 * s, g - hh, s, hh, cabS)
                    for y in stride(from: g - hh + s, to: g - s, by: 5 * s) {
                        c.rect(cx + s, y, 6 * s, s, cabS); c.rect(cx + 3 * s, y + 2 * s, 2 * s, s, C(0x6A5A3A))
                    }
                }
                x += 24 * s
            }
            i += 1
        }
    }

    /// Where the terminals' screens are (shared with the blinking).
    static func tvaScreens(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g), k = tvaClock(c, g)
        var out: [(x: Int, y: Int)] = []
        var x = 4 * s, i = 0
        while x < c.w - 10 * s {
            if abs(x + 10 * s - k.x) < k.r + 22 * s { x += 12 * s; continue }
            if i % 3 == 1 { out.append((x + 5 * s, g - 16 * s)); x += 32 * s } else { x += 24 * s }
            i += 1
        }
        return out
    }

    /// The clock's hands going round, capsules whooshing along the tubes and the terminals' green text.
    static func tvaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), k = tvaClock(c, g), r = Double(k.r)
        let hand = { (a: Double, len: Double, w: Double, col: Px) in
            c.glowLine(Double(k.x), Double(k.y), Double(k.x) + sin(a) * len, Double(k.y) - cos(a) * len, core: col,
                       glow: col.alpha(0.3), coreR: w, glowR: w + 0.6)
        }
        hand(t * 0.05 + 2.2, r * 0.45, Double(s) * 0.9, C(0x3A2010))
        hand(t * 0.6 + 0.4, r * 0.7, Double(s) * 0.7, C(0x3A2010))
        hand(Double(Int(t)) / 60 * 2 * .pi, r * 0.82, Double(s) * 0.4, C(0xC8302A))
        c.circle(k.x, k.y, max(1, k.r / 10), C(0x3A2010))
        // capsules: along the ceiling tube, then down a drop
        let tb = tvaTube(c, g)
        for n in 0..<3 {
            let speed = 70.0 * Double(s), cycle = Double(c.w) / speed + 1.5
            let ph = (t + Double(n) * cycle / 3).truncatingRemainder(dividingBy: cycle) * speed
            let x = n % 2 == 0 ? Int(ph) : c.w - Int(ph)
            c.rect(x - 3 * s, tb.y - s, 6 * s, 2 * s, C(0xC89A4A)); c.rect(x - 2 * s, tb.y - s, 4 * s, s, C(0xF2D080))
        }
        for (n, x) in tb.drops.enumerated() where x > 4 * s && x < c.w - 4 * s {
            let len = Double(g - 22 * s - tb.y), ph = scenes6Phase(t, 3.0, offset: Double(n) * 0.9)
            guard ph < 0.5 else { continue }
            let y = tb.y + Int(ph * 2 * len)
            c.rect(x - s, y, 2 * s, 4 * s, C(0xC89A4A)); c.rect(x - s, y, 2 * s, s, C(0xF2D080))
        }
        for (n, p) in tvaScreens(c, g).enumerated() {
            for line in 0..<3 where noise(Int(t * 2) * 7 + n * 3 + line) > 0.25 {
                let len = 2 + Int(noise(n * 9 + line + Int(t * 2)) * 5)
                c.rect(p.x + s, p.y + s + line * 2 * s, len * s, max(1, s), C(0x5AF07A, 0.85))
            }
            if scenes6Phase(t, 1, offset: Double(n) * 0.3) < 0.5 { c.rect(p.x + s, p.y + 4 * s, s, s, C(0xC8FFC8)) }
            c.rect(p.x, p.y, 8 * s, 6 * s, C(0x5AF07A, 0.06))
        }
    }
}

// MARK: - Krakoa

extension Scenes {
    /// The island's face-rock: centre, half-width and height.
    static func krakoaRock(_ c: PixelCanvas, _ g: Int) -> (x: Int, hw: Int, h: Int) {
        let h = Int(Double(g) * (isTall(c) ? 0.62 : 0.84))
        return (Int(Double(c.w) * 0.56), min(Int(Double(h) * 1.3), c.w / 4), h)
    }

    /// The great flowers by the floor: centre, stem top and size.
    static func krakoaFlowers(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, r: Int)] {
        let s = unit(g)
        var out: [(x: Int, y: Int, r: Int)] = []
        for (i, x) in stride(from: 18 * s, to: c.w, by: 58 * s).enumerated() {
            let r = (3 + Int(noise(i * 3 + 901) * 3)) * s * (isTall(c) ? 2 : 1)
            out.append((x + Int(noise(i * 3 + 902) * 16.0) * s, g - (12 + Int(noise(i * 3 + 903) * 8)) * s * (isTall(c) ? 2 : 1), r))
        }
        return out
    }

    /// The Krakoan gate: centre and size.
    static func krakoaGate(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let s = unit(g), r = isTall(c) ? Int(Double(g) * 0.08) : 9 * s
        return (Int(Double(c.w) * 0.15), g - r - 2 * s, r)
    }

    /// Krakoa, the living mutant island: a bright tropical sky and sea, the island's great rock with its face, eyes,
    /// brow and mouth, rising out of flowering jungle, peach habitat pods among the trees, the glowing flower-arch of
    /// a Krakoan gate and huge blossoms nodding over a mossy floor.
    static func krakoa(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let horizon = g - Int(Double(g) * (tall ? 0.3 : 0.42))
        c.gradient(0, horizon, C(0x3A7AC8), C(0xC8E8E0), bands: 7)
        for i in 0..<(tall ? 6 : 3) {
            cloud(c, Int(noise(i * 5 + 920) * Double(c.w)), Int(Double(horizon) * (0.15 + noise(i * 5 + 921) * 0.5)),
                  (3 + Int(noise(i * 5 + 922) * 4)) * s, seed: i + 90)
        }
        // the sea, with far islets and glints
        c.gradient(horizon, g, C(0x2A8AB0), C(0x46C0C0), bands: 4)
        for k in 0..<(c.w / 5) {
            let x = Int(noise(k * 3 + 930) * Double(c.w)), y = horizon + 2 + Int(noise(k * 3 + 931) * Double(g - horizon - 2))
            c.rect(x, y, (2 + Int(noise(k * 3 + 932) * 4)) * s, max(1, s), C(0xE0F8F8, 0.5))
        }
        scenes6Ridge(c, x0: Int(Double(c.w) * 0.02), x1: Int(Double(c.w) * 0.12), base: horizon + s, h: 5 * s, C(0x4A7A6A), top: C(0x6A9A7A), seed: 3)
        scenes6Ridge(c, x0: Int(Double(c.w) * 0.86), x1: Int(Double(c.w) * 0.97), base: horizon + s, h: 4 * s, C(0x4A7A6A), top: C(0x6A9A7A), seed: 7)
        krakoaRockDraw(c, g)
        // the jungle: a band of canopy across the island, rising in front of the rock's foot
        let jb = g - Int(Double(g) * (tall ? 0.14 : 0.24))
        for x in stride(from: -4 * s, to: c.w + 4 * s, by: 4 * s) {
            let near = abs(x - krakoaRock(c, g).x) < krakoaRock(c, g).hw
            let h = (near ? 10 : 6) * s + Int(noise(x * 7 + 940) * 6) * s
            let col = noise(x + 941) > 0.5 ? C(0x2E7A3A) : C(0x3A8E3E)
            c.ellipse(x, jb - h / 2, 4 * s, h / 2 + s, col)
            if noise(x + 942) > 0.7 { c.rect(x, jb - h - s, s, s, C(0xF060A0)) }
        }
        c.rect(0, jb, c.w, g - jb, C(0x2E6E34))
        krakoaPods(c, g, jb: jb)
        for x in stride(from: 0, to: c.w, by: 3 * s) {          // the nearer, darker undergrowth
            let h = (3 + Int(noise(x * 5 + 950) * 5)) * s
            c.ellipse(x, g - h / 2, 3 * s, h / 2, noise(x + 951) > 0.5 ? C(0x24582C) : C(0x2E6630))
            if noise(x + 952) > 0.85 { c.rect(x, g - h, s, s, C(0xFFC83A)) }
        }
        krakoaGateDraw(c, g)
        // the great flowers on their stems
        for f in krakoaFlowers(c, g) {
            c.rect(f.x - s / 2, f.y, max(1, s), g - f.y, C(0x2E6A2A))
            c.ellipse(f.x - 3 * s, f.y + (g - f.y) / 2, 3 * s, s, C(0x3E8A36)); c.ellipse(f.x + 3 * s, f.y + (g - f.y) * 2 / 3, 3 * s, s, C(0x3E8A36))
            for p in 0..<5 {
                let a = Double(p) / 5 * 2 * .pi - .pi / 2
                c.ellipse(f.x + Int(cos(a) * Double(f.r)), f.y + Int(sin(a) * Double(f.r) * 0.7), max(1, f.r * 2 / 3), max(1, f.r / 2),
                          p % 2 == 0 ? C(0xE04A8A) : C(0xC83A7A))
            }
            c.circle(f.x, f.y, max(1, f.r / 3), C(0xFFC83A))
        }
        c.ground(g, C(0x3A6A2A), edge: C(0x6AA048), speck: C(0x2E5A22), seed: 91)
        for x in stride(from: 5 * s, to: c.w, by: 13 * s) where noise(x + 960) > 0.6 {
            c.rect(x, g + 2 * s + Int(noise(x + 961) * Double(max(1, c.h - g - 4 * s))), s, s, C(0xF070B0, 0.8))
        }
    }

    /// The face-rock: a mossy dome with a heavy brow, two deep eye-caves and a long mouth.
    static func krakoaRockDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), r = krakoaRock(c, g), base = g - Int(Double(g) * 0.12)
        for x in (r.x - r.hw)..<(r.x + r.hw) {
            let u = Double(x - r.x) / Double(r.hw)
            let prof = pow(max(0, 1 - u * u), 0.6) + (noise(x / 3 + 970) - 0.5) * 0.06
            let top = base - Int(Double(r.h) * prof)
            guard top < base else { continue }
            let k = max(0, min(1, 0.5 + u * 0.6))
            c.rect(x, top, 1, base - top, lerp(C(0x5E7E56), C(0x3E5A40), (k * 3).rounded() / 3))
            c.px(x, top, C(0x7AA060))
            for y in stride(from: top + 3, to: base, by: 7) where noise(x * 5 + y) > 0.9 { c.px(x, y, C(0x34503A)) }
            for y in stride(from: top + 6 * s, to: base, by: 11 * s) where noise(x / 6 + y * 3) > 0.35 { c.px(x, y + Int(u * 3), C(0x4A6A46)) }
        }
        // moss and vines hanging down the dome
        for x in stride(from: r.x - r.hw + 4 * s, to: r.x + r.hw - 4 * s, by: 5 * s) {
            let u = Double(x - r.x) / Double(r.hw), top = base - Int(Double(r.h) * pow(max(0, 1 - u * u), 0.6))
            let len = (3 + Int(noise(x + 975) * 10)) * s
            c.rect(x, top, max(1, s), len, C(0x3E8A3A, 0.8))
            c.ellipse(x, top + s, 3 * s, s, C(0x4E9A44))
        }
        // the face
        let fy = base - r.h * 6 / 10, ew = max(3, r.hw / 6), eh = max(2, r.hw / 10)
        for k in 0..<(r.hw / 2) {                                                             // the heavy brow, a shallow V
            let d = r.hw / 2 - k
            c.rect(r.x - d, fy - eh - 2 * s + k / 6, 1, 2 * s, C(0x34503A)); c.rect(r.x + d, fy - eh - 2 * s + k / 6, 1, 2 * s, C(0x34503A))
        }
        for side in [-1, 1] {
            let ex = r.x + side * r.hw / 4
            for k in -ew...ew {                                                       // an almond eye, slanting down to the nose
                let u = Double(k) / Double(ew), half = Int(Double(eh) * (1 - u * u).squareRoot() * 0.8)
                let yc = fy + Int(Double(side * k) * -0.25 * Double(eh) / Double(max(1, ew)))
                if half > 0 { c.rect(ex + k, yc - half, 1, half * 2, C(0x16261A)) }
                c.px(ex + k, yc - half - s, C(0x2A3E2C))
                c.px(ex + k, yc - half - 2 * s, C(0x7AA060))
            }
        }
        c.rect(r.x - s, fy, 2 * s, r.h / 6, C(0x4A6A48))                                      // the nose ridge
        let my = fy + r.h / 4
        c.ellipse(r.x, my, r.hw * 2 / 5, max(1, eh / 3), C(0x16261A))
        c.rect(r.x - r.hw * 2 / 5, my, r.hw * 4 / 5, max(1, s), C(0x0A140E))
        c.rect(r.x - r.hw / 3, my - s, r.hw * 2 / 3, s, C(0x34503A))
    }

    /// The habitat pods: peach-and-pink bulbs grown among the trees, with round windows.
    static func krakoaPods(_ c: PixelCanvas, _ g: Int, jb: Int) {
        let s = unit(g), rock = krakoaRock(c, g), q = isTall(c) ? 2 : 1
        for (i, x) in stride(from: 40 * s, to: c.w, by: 90 * s).enumerated() {
            let px = x + Int(noise(i + 980) * 30.0) * s
            guard abs(px - rock.x) > rock.hw / 2, abs(px - krakoaGate(c, g).x) > krakoaGate(c, g).r * 3 else { continue }
            let rx = (8 + Int(noise(i + 981) * 6)) * s * q, ry = rx * 3 / 4
            c.ellipse(px, jb, rx, ry, C(0xE8A890))
            c.ellipse(px - rx / 4, jb - ry / 4, rx * 2 / 3, ry * 2 / 3, C(0xF6C8A8))
            c.ellipse(px + rx / 2, jb - ry - s, rx / 3, ry / 3, C(0xE8A890))
            let dw = max(1, rx / 5), dh = ry / 2
            c.ellipse(px + rx / 4, jb - dh, dw, dw, C(0x6A3A4A))                              // an arched doorway
            c.rect(px + rx / 4 - dw, jb - dh, dw * 2 + 1, dh, C(0x6A3A4A))
            c.circle(px - rx / 3, jb - ry / 2, max(1, s * q), C(0x8A4A5A)); c.px(px - rx / 3, jb - ry / 2, C(0xFFE08A))
            c.ellipse(px, jb - ry, max(1, rx / 4), max(1, s), C(0xFFE6D0))
        }
    }

    /// A Krakoan gate: an arch of petals around a shimmering opening.
    static func krakoaGateDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), gt = krakoaGate(c, g)
        c.ellipse(gt.x, gt.y, gt.r, gt.r + 2 * s, C(0x2E6A2A))
        c.ellipse(gt.x, gt.y, gt.r - 2 * s, gt.r, C(0xC8F07A, 0.35))
        for k in 0..<10 {
            let a = Double(k) / 10 * 2 * .pi
            c.ellipse(gt.x + Int(cos(a) * Double(gt.r)), gt.y + Int(sin(a) * Double(gt.r + 2 * s)), 2 * s, 2 * s,
                      k % 2 == 0 ? C(0xF2C83A) : C(0xE86A9A))
        }
    }

    /// The flowers' hearts and the gate pulsing with light, sparkles drifting off them, glints on the sea.
    static func krakoaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        for (i, f) in krakoaFlowers(c, g).enumerated() {
            let p = 0.5 + 0.5 * sin(t * 2 + Double(i) * 1.3)
            c.circle(f.x, f.y, f.r + 2 * s, C(0xFFE07A, 0.08 + p * 0.14))
            c.circle(f.x, f.y, max(1, f.r / 3), C(0xFFF2A0, 0.4 + p * 0.5))
            let rise = scenes6Phase(t, 2.5, offset: Double(i) * 0.7)
            c.rect(f.x + Int(sin(t * 3 + Double(i)) * 2.0) * s, f.y - Int(rise * Double(10 * s)), s, s, C(0xFFF2A0, 1 - rise))
        }
        let gt = krakoaGate(c, g), p = 0.5 + 0.5 * sin(t * 1.6)
        c.ellipse(gt.x, gt.y, gt.r - 2 * s, gt.r, C(0xE8FF9A, 0.15 + p * 0.3))
        c.ellipse(gt.x, gt.y, gt.r / 2, gt.r * 2 / 3, C(0xFFFFE0, 0.1 + p * 0.25))
        // the rock's eyes glow faintly now and then
        let r = krakoaRock(c, g), base = g - Int(Double(g) * 0.12), fy = base - r.h * 6 / 10
        let e = max(0, sin(t * 0.7))
        for side in [-1, 1] {
            let ew = max(3, r.hw / 6)
            c.rect(r.x + side * r.hw / 4 - ew / 2, fy - s / 2, ew, max(1, s), C(0xC8FF6A, e * 0.5))
            c.rect(r.x + side * r.hw / 4 - ew / 4, fy - s / 2, ew / 2, max(1, s), C(0xF0FFB0, e * 0.6))
        }
        let horizon = g - Int(Double(g) * (isTall(c) ? 0.3 : 0.42))
        for k in 0..<max(4, c.w / 60) where sin(t * 3 + Double(k) * 2.1) > 0.6 {
            let x = Int(noise(k * 5 + 990) * Double(c.w)), y = horizon + 1 + Int(noise(k * 5 + 991) * Double(max(1, g / 6)))
            c.rect(x, y, 2 * s, max(1, s), C(0xFFFFFF, 0.8))
        }
    }
}

// MARK: - Morlock Tunnels

extension Scenes {
    /// The arched openings in the back wall: centre, half-width and the crown's row.
    static func morlockArches(_ c: PixelCanvas, _ g: Int) -> [(x: Int, hw: Int, top: Int)] {
        let s = unit(g), hw = isTall(c) ? Int(Double(g) * 0.16) : 18 * s
        let top = isTall(c) ? Int(Double(g) * 0.42) : 14 * s, step = hw * 2 + 110 * s
        return stride(from: hw + 30 * s, to: c.w + hw, by: step).map { ($0, hw, top) }
    }

    /// The water pipes' row, and where they drip.
    static func morlockPipes(_ c: PixelCanvas, _ g: Int) -> (y: Int, drips: [Int]) {
        let s = unit(g), y = isTall(c) ? Int(Double(g) * 0.3) : 6 * s
        return (y, stride(from: 23 * s, to: c.w, by: 47 * s).map { $0 })
    }

    /// Candle flames: on crates by the shelters.
    static func morlockCandles(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g)
        return stride(from: 60 * s, to: c.w - 6 * s, by: 96 * s).flatMap { x -> [(x: Int, y: Int)] in
            [(x, g - 8 * s), (x + 4 * s, g - 7 * s)]
        }
    }

    /// The Morlock Tunnels under New York: an old brick vault with dark arched passages, one opening onto a lit subway
    /// car, rusted pipes along the wall, spray-painted graffiti, makeshift shelters of tarps and crates lit by candles,
    /// and a wet concrete floor with puddles.
    static func morlockTunnels(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        // brick everywhere, darkening upward
        c.gradient(0, g, C(0x1A120E), C(0x4A3024), bands: 6)
        for (j, y) in stride(from: 0, to: g, by: 3 * s).enumerated() {
            c.rect(0, y, c.w, max(1, s / 2), C(0x120C08, 0.5))
            for x in stride(from: (j % 2) * 4 * s, to: c.w, by: 8 * s) {
                c.rect(x, y, max(1, s / 2), 3 * s, C(0x120C08, 0.45))
                if noise(x * 3 + j * 101) > 0.85 { c.rect(x + s, y + s, 6 * s, 2 * s, C(0x6A3E2A, 0.35)) }
            }
        }
        if tall {                                              // the vaulted ceiling's ribs
            for x in stride(from: 0, to: c.w, by: 80 * s) {
                for k in 0..<(g / 5) {
                    let u = Double(k) / Double(g / 5)
                    c.rect(x + Int(u * Double(40 * s)) - 2 * s, Int(u * u * Double(g / 6)), 4 * s, s, C(0x2A1A12))
                    c.rect(x - Int(u * Double(40 * s)) - 2 * s, Int(u * u * Double(g / 6)), 4 * s, s, C(0x2A1A12))
                }
            }
            c.rect(0, 0, c.w, g / 14, C(0x0E0A08))
        }
        for (i, a) in morlockArches(c, g).enumerated() { morlockArch(c, g, a, subway: i == 1 || (i == 0 && morlockArches(c, g).count == 1)) }
        morlockGraffiti(c, g)
        morlockPipesDraw(c, g)
        if tall { morlockHigh(c, g) }
        morlockShelters(c, g)
        // candle glow on the wall
        for p in morlockCandles(c, g) { c.circle(p.x, p.y - 2 * s, 10 * s, C(0xFFA040, 0.05)); c.circle(p.x, p.y - 2 * s, 5 * s, C(0xFFB050, 0.08)) }
        c.ground(g, C(0x2A2620), edge: C(0x5A5240), speck: C(0x1E1A16), seed: 101)
        for x in stride(from: 10 * s, to: c.w, by: 47 * s) {   // puddles under the drips
            c.ellipse(x + 13 * s, g + (c.h - g) / 2, (6 + Int(noise(x + 1010) * 6)) * s, max(1, s), C(0x4A5A6A, 0.6))
            c.rect(x + 9 * s, g + (c.h - g) / 2, 4 * s, max(1, s / 2), C(0x8A9AA8, 0.4))
        }
    }

    /// One arched passage leading off into the dark (or onto the subway tracks).
    static func morlockArch(_ c: PixelCanvas, _ g: Int, _ a: (x: Int, hw: Int, top: Int), subway: Bool) {
        let s = unit(g), bottom = g
        c.rect(a.x - a.hw - 3 * s, a.top + a.hw, a.hw * 2 + 6 * s, bottom - a.top - a.hw, C(0x5A3828))
        c.ellipse(a.x, a.top + a.hw, a.hw + 3 * s, a.hw + 3 * s, C(0x5A3828))
        for k in 0..<14 {                                      // the brick voussoirs
            let ang = Double(k) / 13 * .pi
            c.rect(a.x - Int(cos(ang) * Double(a.hw + s)) - s, a.top + a.hw - Int(sin(ang) * Double(a.hw + s)) - s, 2 * s, 2 * s, C(0x3A2216))
        }
        // the dark inside, getting blacker further in
        c.rect(a.x - a.hw, a.top + a.hw, a.hw * 2, bottom - a.top - a.hw, C(0x0E0B09))
        c.ellipse(a.x, a.top + a.hw, a.hw, a.hw, C(0x0E0B09))
        c.ellipse(a.x, a.top + a.hw + a.hw / 3, a.hw * 2 / 3, a.hw * 2 / 3, C(0x070605))
        c.rect(a.x - a.hw * 2 / 3, a.top + a.hw + a.hw / 3, a.hw * 4 / 3, bottom - a.top - a.hw - a.hw / 3, C(0x070605))
        if subway {                                            // a subway car glimpsed down the tracks
            let q = max(1, a.hw / (18 * s)) * s, ch = 8 * q
            let cy = bottom - ch - 2 * s - max(0, (bottom - a.top) / 8), cw = a.hw * 2 - 4 * s
            c.rect(a.x - cw / 2, cy, cw, ch, C(0x5A6068))
            c.rect(a.x - cw / 2, cy, cw, q, C(0x8A9098))
            for x in stride(from: a.x - cw / 2 + 2 * q, to: a.x + cw / 2 - 3 * q, by: 5 * q) { c.rect(x, cy + 2 * q, 3 * q, 3 * q, C(0xFFE08A)) }
            c.rect(a.x - cw / 2, cy + 6 * q, cw, q, C(0x7A3A2A))
            if q > s { c.rect(a.x - cw / 2 + 3 * q, cy - 2 * q, 6 * q, 2 * q, C(0x3A3E44)) }
            c.rect(a.x - cw / 2, bottom - 2 * s, cw, s, C(0x6A6A6A))
            c.ellipse(a.x, cy + 3 * s, cw / 2 + 4 * s, 6 * s, C(0xFFE08A, 0.06))
        }
    }

    /// Up in the vault on the screen saver: a street grate letting a shaft of daylight in, a second run of
    /// conduit, and bare bulbs hanging on their cables.
    static func morlockHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = morlockPipes(c, g), top = g / 14
        let gx = Int(Double(c.w) * 0.42), gw = 22 * s
        c.rect(gx, top, gw, 3 * s, C(0x9AA0A0))
        for x in stride(from: gx + s, to: gx + gw - s, by: 3 * s) { c.rect(x, top, s, 3 * s, C(0x2A2A28)) }
        for y in (top + 3 * s)..<g {                                          // the light shaft, slanting down
            let k = Double(y - top) / Double(g - top), off = Int(k * Double(g) * 0.25)
            c.rect(gx + off - Int(k * 6) * s, y, gw + Int(k * 12) * s, 1, C(0xF0E6C0, 0.07 * (1 - k * 0.6)))
        }
        c.ellipse(gx + Int(Double(g) * 0.25) + gw / 2, g, gw, 2 * s, C(0xF0E6C0, 0.12))
        let cy = p.y - 14 * s
        c.rect(0, cy, c.w, 2 * s, C(0x2A2A2A)); c.rect(0, cy + 3 * s, c.w, 2 * s, C(0x3A2E26))
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, cy - s, 2 * s, 7 * s, C(0x5A5A50)) }
        for x in morlockBulbs(c, g) {
            c.rect(x, cy + 5 * s, max(1, s / 2), 24 * s, C(0x1A1A18))
            c.rect(x - s, cy + 29 * s, 2 * s, 2 * s, C(0x6A6A5A))
        }
    }

    /// Where the hanging bulbs are (screen saver only).
    static func morlockBulbs(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = unit(g)
        return stride(from: 50 * s, to: c.w, by: 120 * s).map { $0 }
    }

    /// Spray paint: a big "MORLOCKS" tag and smaller scribbles.
    static func morlockGraffiti(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), q = isTall(c) ? 2 * s : s, arches = morlockArches(c, g)
        let gx = (arches.first.map { $0.x + $0.hw } ?? 0) + 18 * s, gy = g - 30 * s - (isTall(c) ? 20 * s : 0)
        c.rect(gx - q, gy - q, 33 * q, 7 * q, C(0x2A6A8A, 0.25))
        scenes6Text(c, gx + q / 2, gy + q / 2, "MORLOCKS", C(0x101010, 0.6), s: q)
        scenes6Text(c, gx, gy, "MORLOCKS", C(0xE04A3A, 0.85), s: q)
        for (i, x) in stride(from: 150 * s, to: c.w, by: 130 * s).enumerated() {
            let y = g - 26 * s + Int(noise(i + 1020) * 6) * s
            let col = [C(0x4AC8C8, 0.7), C(0xE8D83A, 0.7), C(0xC85AE0, 0.7)][i % 3]
            for k in 0..<12 {
                let dy = Int(sin(Double(k) * 1.4 + Double(i)) * 3.0) * s
                c.rect(x + k * 2 * s, y + dy, 2 * s, s, col)
            }
            if i % 2 == 0 { scenes6Text(c, x + 2 * s, y + 5 * s, "X", col, s: s) }
        }
    }

    /// Rusted pipes along the wall with valves, and drop pipes here and there.
    static func morlockPipesDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = morlockPipes(c, g)
        c.rect(0, p.y, c.w, 3 * s, C(0x4A5A4A)); c.rect(0, p.y, c.w, s, C(0x7A8A6A)); c.rect(0, p.y + 2 * s, c.w, s, C(0x2A342A))
        c.rect(0, p.y + 5 * s, c.w, 2 * s, C(0x5A3A2A)); c.rect(0, p.y + 5 * s, c.w, max(1, s / 2), C(0x8A5A3A))
        for x in p.drips {
            c.rect(x - s, p.y - s, 3 * s, 5 * s, C(0x6A6A5A))      // a joint, where it leaks
            c.rect(x - s, p.y + 3 * s, 3 * s, s, C(0x6A4A2A, 0.8))
            c.rect(x, p.y + 4 * s, s, 4 * s, C(0x2A3A3A, 0.5))      // water stain
        }
        for (i, x) in stride(from: 80 * s, to: c.w, by: 160 * s).enumerated() {
            c.rect(x, p.y + 3 * s, 2 * s, g - p.y - 3 * s, C(0x4A5A4A)); c.rect(x, p.y + 3 * s, s, g - p.y - 3 * s, C(0x6A7A5A))
            c.circle(x + s, p.y + 12 * s + (i % 2) * 6 * s, 2 * s, C(0xA83A2A)); c.px(x + s, p.y + 12 * s + (i % 2) * 6 * s, C(0xD86A4A))
        }
    }

    /// The camp: tarp lean-tos, mattresses, crates with candles and an oil drum.
    static func morlockShelters(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), arches = morlockArches(c, g)
        for (i, x) in stride(from: 30 * s, to: c.w - 10 * s, by: 96 * s).enumerated() {
            if arches.contains(where: { abs($0.x - x - 12 * s) < $0.hw + 10 * s }) && i % 2 == 0 { continue }
            let tarp = [C(0x3A5A8A), C(0x7A5A3A), C(0x5A6A3A)][i % 3]
            // a lean-to: a tarp sloping from the wall over a mattress
            for k in 0..<22 {
                let h = 14 * s - k * s * 13 / 22
                c.rect(x - 4 * s + k * s, g - h, s, h, tarp)
            }
            c.rect(x - 4 * s, g - 14 * s, 22 * s, s, tarp.alpha(0.6))
            c.rect(x - 2 * s, g - 3 * s, 14 * s, 3 * s, C(0x8A8070)); c.rect(x - 2 * s, g - 3 * s, 14 * s, s, C(0xB8AC98))
            c.rect(x - 4 * s, g - 14 * s, s, 14 * s, C(0x5A4A3A))
            // a crate with candles on it
            c.rect(x + 22 * s, g - 6 * s, 8 * s, 6 * s, C(0x7A5A36)); c.rect(x + 22 * s, g - 6 * s, 8 * s, s, C(0x9A7A4A))
            c.rect(x + 22 * s, g - 3 * s, 8 * s, s, C(0x5A3E22))
            for dx in [0, 4] { c.rect(x + 38 * s + dx * s - 8 * s, g - 8 * s, s, 2 * s, C(0xF0E6C8)) }
            if i % 2 == 1 {                                     // an oil drum
                c.rect(x + 46 * s, g - 10 * s, 7 * s, 10 * s, C(0x4A3A2E)); c.rect(x + 46 * s, g - 7 * s, 7 * s, s, C(0x6A4A2E))
                c.rect(x + 46 * s, g - 3 * s, 7 * s, s, C(0x6A4A2E)); c.rect(x + 51 * s, g - 10 * s, s, 10 * s, C(0x2E2420))
            }
        }
    }

    /// Water dripping from the pipe joints, rings on the puddles, candles flickering.
    static func morlockLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), p = morlockPipes(c, g)
        for (i, x) in p.drips.enumerated() {
            let ph = scenes6Phase(t, 1.6 + noise(i + 1030) * 1.2, offset: noise(i + 1031) * 3)
            let fall = Double(g + (c.h - g) / 2 - p.y - 4 * s)
            let y = p.y + 4 * s + Int(ph * ph * fall)
            if ph < 0.92 { c.rect(x, y, s, 2 * s, C(0x9ABAD0, 0.85)) } else {
                let r = Int((ph - 0.92) / 0.08 * 6) * s + s
                c.ellipse(x, g + (c.h - g) / 2, r, max(1, s / 2), C(0xB8D0E0, 0.5))
            }
            if ph < 0.2 { c.rect(x, p.y + 4 * s, s, s, C(0x9ABAD0, 0.6)) }
        }
        if isTall(c) {
            let by = p.y - 14 * s + 31 * s
            for (i, x) in morlockBulbs(c, g).enumerated() {
                let on = noise(Int(t * 8) + i * 17) > 0.08
                c.rect(x - s, by, 2 * s, 3 * s, on ? C(0xFFE6A0) : C(0x6A5A3A))
                if on { c.circle(x, by + s, 12 * s, C(0xFFD080, 0.06)); c.circle(x, by + s, 5 * s, C(0xFFD080, 0.12)) }
            }
        }
        for (i, f) in morlockCandles(c, g).enumerated() {
            let k = Int(t * 10) + i * 5
            let tall = noise(k) > 0.4 ? 2 : 1
            c.circle(f.x, f.y - 2 * s, 4 * s, C(0xFFB050, 0.1 + noise(k + 1) * 0.12))
            c.rect(f.x, f.y - (tall + 1) * s, s, tall * s, C(0xFFE08A))
            c.rect(f.x, f.y - s, s, s, C(0xFF8A2A))
            if noise(k + 2) > 0.7 { c.px(f.x + (noise(k + 3) > 0.5 ? s : -s), f.y - (tall + 1) * s, C(0xFFD060, 0.7)) }
        }
    }
}

// MARK: - Asteroid M

extension Scenes {
    /// The citadel's centre and the top of its main spire.
    static func asteroidCitadel(_ c: PixelCanvas, _ g: Int) -> (x: Int, top: Int, w: Int) {
        let s = unit(g), h = Int(Double(g) * (isTall(c) ? 0.62 : 0.86))
        return (Int(Double(c.w) * 0.66), g - h, max(70 * s, isTall(c) ? h : h * 3 / 2))
    }

    /// Asteroid M: Magnetto's fortress adrift in orbit, black space and stars, Earth's blue limb curving below, the
    /// rugged asteroid the crew stands on, and the steel citadel grown out of its crags: spires, ribbed walls glowing
    /// red-violet, a dish, and the helmet emblem.
    static func asteroidM(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x05040E), C(0x1E1636), bands: 6)
        c.stars(0, g, density: tall ? 70 : 40, seed: 31)
        // Earth below, its atmosphere glowing on the limb
        let er = max(Int(Double(g) * 0.95), c.w * 7 / 20), ex = Int(Double(c.w) * 0.24), ey = g + (tall ? er / 3 : er * 3 / 4)
        c.circle(ex, ey, er + 6 * s, C(0x5AA0FF, 0.10)); c.circle(ex, ey, er + 3 * s, C(0x6AB8FF, 0.18))
        c.circle(ex, ey, er, C(0x2A5AA8))
        let onEarth = { (x: Int, y: Int) -> Bool in (x - ex) * (x - ex) + (y - ey) * (y - ey) < (er - 2) * (er - 2) }
        for k in 0..<7 {                                       // continents: clusters of lumps, green going to tan
            let a = -Double.pi * (0.1 + noise(k * 7 + 1100) * 0.8), d = Double(er) * (0.7 + noise(k * 7 + 1101) * 0.25)
            let cx = ex + Int(cos(a) * d), cy = ey + Int(sin(a) * d), size = Double(er) * (0.03 + noise(k * 7 + 1102) * 0.04)
            for n in 0..<9 {
                let ox = Int((noise(k * 31 + n * 3) - 0.5) * size * 3), oy = Int((noise(k * 31 + n * 3 + 1) - 0.5) * size * 1.6)
                let rr = Int(size * (0.4 + noise(k * 31 + n * 3 + 2) * 0.6))
                let col = n % 6 == 0 ? C(0x9A8A5A) : (n % 2 == 0 ? C(0x4A7A44) : C(0x3E6E40))
                for dy in -rr...rr {
                    let half = Int((Double(rr * rr - dy * dy)).squareRoot() * 1.4)
                    for dx in -half...half where onEarth(cx + ox + dx, cy + oy + dy) { c.px(cx + ox + dx, cy + oy + dy, col) }
                }
            }
        }
        for k in 0..<14 {                                      // cloud streaks
            let a = -Double.pi * noise(k * 5 + 1110), d = Double(er) * (0.65 + noise(k * 5 + 1111) * 0.32)
            let cx = ex + Int(cos(a) * d), cy = ey + Int(sin(a) * d), len = (8 + Int(noise(k * 5 + 1112) * 24)) * s
            for dx in stride(from: -len / 2, to: len / 2, by: 1) where onEarth(cx + dx, cy) { c.px(cx + dx, cy, C(0xF0F4F8, 0.7)) }
            for dx in stride(from: -len / 3, to: len / 4, by: 1) where onEarth(cx + dx + 3 * s, cy + s) { c.px(cx + dx + 3 * s, cy + s, C(0xF0F4F8, 0.45)) }
        }
        // the dark side: shade the right of the globe
        for y in max(0, ey - er)..<min(g, ey + er) {
            let half = Int((Double(er * er - (y - ey) * (y - ey))).squareRoot())
            c.rect(ex + half / 5, y, half - half / 5, 1, C(0x05040E, 0.25))
            c.rect(ex + half / 2, y, half - half / 2, 1, C(0x05040E, 0.35))
            c.px(ex - half, y, C(0xA8D8FF, 0.7))
        }
        // far rocks, then the asteroid's crags
        scenes6Ridge(c, x0: -10 * s, x1: c.w / 2, base: g, h: Int(Double(g) * 0.22), C(0x3A3040), top: C(0x6A5A70), seed: 4)
        scenes6Ridge(c, x0: c.w / 3, x1: c.w + 20 * s, base: g, h: Int(Double(g) * 0.4), C(0x2E2634), top: C(0x5A4A62), seed: 9)
        asteroidCitadelDraw(c, g)
        scenes6Ridge(c, x0: -20 * s, x1: c.w / 4, base: g, h: Int(Double(g) * 0.14), C(0x463A48), top: C(0x8A7488), seed: 2)
        c.ground(g, C(0x4A3E4C), edge: C(0x8A7488), speck: C(0x3A303C), seed: 111)
        for k in 0..<(c.w / 30) {                               // craters
            let x = Int(noise(k + 1120) * Double(c.w)), y = g + 2 * s + Int(noise(k + 1121) * Double(max(1, c.h - g - 4 * s)))
            c.ellipse(x, y, (2 + Int(noise(k + 1122) * 3)) * s, max(1, s), C(0x2E2632))
        }
    }

    /// The steel citadel: a ribbed curtain wall, a ring of spires around the tall central one, a dish and the helmet.
    static func asteroidCitadelDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), cd = asteroidCitadel(c, g), steel = C(0x7A7E8C), dark = C(0x3A3C4A), lit = C(0xB8BCC8)
        let red = C(0xC02838), wall = g - (g - cd.top) * 2 / 5
        // the rock it sits in
        scenes6Ridge(c, x0: cd.x - cd.w * 3 / 4, x1: cd.x + cd.w * 3 / 4, base: g, h: (g - wall) + 4 * s, C(0x3A3040), top: C(0x6A5A70), seed: 12)
        // curtain wall with buttresses and lit slits
        c.rect(cd.x - cd.w / 2, wall, cd.w, g - wall, dark)
        for x in stride(from: cd.x - cd.w / 2, to: cd.x + cd.w / 2, by: 8 * s) {
            c.rect(x, wall - 2 * s, 3 * s, g - wall + 2 * s, steel); c.rect(x, wall - 2 * s, s, g - wall + 2 * s, lit)
            c.rect(x + 5 * s, wall + 3 * s, s, max(s, (g - wall) / 3), red.alpha(0.8))
        }
        // spires: the central one and lower ones either side
        let spires: [(dx: Int, h: Int, w: Int)] = [(0, g - cd.top, 10 * s), (-cd.w / 3, (g - cd.top) * 3 / 4, 7 * s),
                                                   (cd.w / 3, (g - cd.top) * 2 / 3, 7 * s), (-cd.w / 6, (g - cd.top) * 3 / 5, 5 * s),
                                                   (cd.w / 6, (g - cd.top) * 7 / 10, 6 * s)]
        for sp in spires.reversed() {
            let x = cd.x + sp.dx, top = g - sp.h
            for y in top..<wall {                             // tapering to a point
                let k = Double(y - top) / Double(max(1, sp.h / 3))
                let half = max(1, Int(Double(sp.w / 2) * min(1, k)))
                c.rect(x - half, y, half * 2, 1, steel)
                c.rect(x - half, y, max(1, half / 2), 1, lit)
                c.rect(x + half - max(1, half / 2), y, max(1, half / 2), 1, dark)
            }
            for y in stride(from: top + sp.h / 3, to: wall, by: 6 * s) { c.rect(x - s / 2, y, max(1, s), 2 * s, red) }
            c.rect(x - sp.w / 2 - s, top + sp.h / 3, sp.w + 2 * s, s, C(0x8A2A4A))
        }
        // the dish on the right
        let dx = cd.x + cd.w / 2 - 6 * s, dy = wall - 6 * s
        c.rect(dx, dy, s, 6 * s, steel)
        c.ellipse(dx + 3 * s, dy - 3 * s, 6 * s, 2 * s, lit); c.ellipse(dx + 3 * s, dy - 2 * s, 5 * s, s, steel)
        // Magnetto's helmet on the gate: a fin crest down the middle and one visor band
        let hx = cd.x - 6 * s, hy = g - 15 * s, q = s
        c.rect(cd.x - 9 * s, hy - 2 * s, 18 * s, g - hy + 2 * s, C(0x2A2236))
        scenes6Stamp(c, hx, hy, [
            "....rkkr....",
            "..rrrkkrrr..",
            ".rrrrrrrrrr.",
            "rr.kkkkkk.rr",
            "rr........rr",
            "rr........rr",
            ".rr......rr.",
            "..r......r..",
        ], ["r": C(0xB02838), "k": C(0x5A1428)], s: q)
        c.rect(cd.x - 9 * s, g - 2 * s, 18 * s, 2 * s, C(0x6A5A70))
    }

    /// Rocks and debris orbiting the asteroid, the beacon on the spire blinking and running lights along the wall.
    static func asteroidMLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), cd = asteroidCitadel(c, g)
        let rx = Double(c.w) * 0.55, ry = Double(g) * 0.12, cy = Double(g) * 0.42
        for k in 0..<9 {
            let a = t * 0.12 + Double(k) / 9 * 2 * .pi + noise(k + 1130) * 0.5
            let x = Double(c.w) / 2 + cos(a) * rx, y = cy + sin(a) * ry + (noise(k + 1131) - 0.5) * Double(g) * 0.2
            let front = sin(a) > 0, size = (1 + Int(noise(k + 1132) * 3)) * s * (front ? 2 : 1)
            let col = front ? C(0x7A6A7A) : C(0x4A4054)
            c.rect(Int(x), Int(y), size, size, col)
            if size > s { c.rect(Int(x), Int(y), size, s, front ? C(0xA898A8) : C(0x5A5066)) }
        }
        if scenes6Phase(t, 1.4) < 0.3 {
            c.circle(cd.x, cd.top - s, 4 * s, C(0xFF3A5A, 0.3))
            c.rect(cd.x - s, cd.top - 2 * s, 2 * s, 2 * s, C(0xFF6A7A))
        }
        let wall = g - (g - cd.top) * 2 / 5, n = cd.w / (8 * s)
        let lead = Int(t * 6) % max(1, n)
        c.rect(cd.x - cd.w / 2 + lead * 8 * s + 5 * s, wall + 3 * s, s, max(s, (g - wall) / 3), C(0xFF7A9A, 0.8))
    }
}
