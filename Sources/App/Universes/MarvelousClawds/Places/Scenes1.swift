import Foundation

let scenes1: [Location: Place] = [
    .avengersTower: Place(name: "Clawdvengers Tower", panel: 0x141A2C, still: Scenes.avengersTower, moving: Scenes.towerLife),
    .sanctum: Place(name: "Sanctum Sanctorum", panel: 0x221510, still: Scenes.sanctum, moving: Scenes.sanctumLife),
    .wakanda: Place(name: "Wakandu", panel: 0x2A1620, still: Scenes.wakanda, moving: Scenes.wakandaLife),
    .asgard: Place(name: "Asgaard", panel: 0x16142E, still: Scenes.asgard, moving: Scenes.asgardLife),
    .sakaar: Place(name: "Sakkar", panel: 0x2A1A1E, still: Scenes.sakaar, moving: Scenes.sakaarLife),
    .knowhere: Place(name: "Nowhere", panel: 0x170F1E, still: Scenes.knowhere, moving: Scenes.knowhereLife),
    .titan: Place(name: "Titan", panel: 0x2E1610, still: Scenes.titan, moving: Scenes.titanLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes1Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes1Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }
}

// MARK: - Clawdvengers Tower

extension Scenes {
    /// One building of the Manhattan skyline behind the tower.
    struct TowerBlock { let x, y, w, h: Int; let near: Bool }

    /// The tower's place on the canvas: left edge, width and top row.
    static func towerFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int) {
        let s = unit(g)
        return (Int(Double(c.w) * 0.72), 30 * s, isTall(c) ? g / 6 : 3)
    }

    /// Clawdvengers Tower at night: the crew is out on the tower's top-floor terrace behind its glass rail. Behind them the
    /// Manhattan skyline glitters (the Empire State and the Chrysler stand out), a moon hangs over the East River, and
    /// the tower itself rises at the right, slanted glass crown, landing pad jutting out and the glowing claw emblem up top,
    /// with the warm glass lounge at its foot.
    static func avengersTower(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x070B1E), C(0x2C3466), bands: 7)
        c.stars(0, g * 3 / 5, density: tall ? 90 : 60, seed: 4)
        let mx = Int(Double(c.w) * 0.12), my = g / 5, mr = max(4, g / 18)
        c.circle(mx, my, mr + 3 * s, C(0xC8D4F0, 0.10)); c.circle(mx, my, mr + s, C(0xC8D4F0, 0.12))
        c.circle(mx, my, mr, C(0xE6EBF5))
        c.circle(mx - mr / 3, my - mr / 4, max(1, mr / 4), C(0xC6CEDE)); c.circle(mx + mr / 3, my + mr / 3, max(1, mr / 5), C(0xCDD4E2))
        if tall {
            for i in 0..<5 {
                wisp(c, Int(noise(i * 5 + 300) * Double(c.w)), g / 8 + Int(noise(i * 5 + 301) * Double(g / 3)),
                     (30 + Int(noise(i * 5 + 302) * 40)) * s, C(0x3A4478, 0.5), s: s)
            }
        }
        // the city glow along the horizon
        for k in 0..<4 { c.rect(0, g - 14 * s - k * 6 * s, c.w, 6 * s, C(0x6A4A7A, 0.10)) }
        let blocks = towerBlocks(c, g)
        for b in blocks where !b.near { towerBuilding(c, b, C(0x1C2448), lit: 0.42, seed: 1) }
        towerLandmarks(c, g)
        for b in blocks where b.near { towerBuilding(c, b, C(0x10152E), lit: 0.7, seed: 2) }
        towerTower(c, g)
        // the terrace's glass rail
        let rail = 6 * s
        c.rect(0, g - rail, c.w, rail, C(0x8ABCE8, 0.12))
        c.rect(0, g - rail, c.w, s, C(0xB8D4F0, 0.55))
        for x in stride(from: 6, to: c.w, by: 36 * s) { c.rect(x, g - rail, s, rail, C(0x8A9AB8, 0.6)) }
        c.ground(g, C(0x262C3E), edge: C(0x6A7A98), speck: C(0x20263A), seed: 21)
        for x in stride(from: 0, to: c.w, by: 18 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x30384E)) }
        c.rect(0, g + 1, c.w, s, C(0x1C2232))
    }

    /// The skyline: a far row of hazy buildings and a nearer, darker one.
    static func towerBlocks(_ c: PixelCanvas, _ g: Int) -> [TowerBlock] {
        let s = unit(g)
        var out: [TowerBlock] = []
        for (layer, spec) in [(lo: 0.22, hi: 0.55, seed: 3), (lo: 0.10, hi: 0.34, seed: 9)].enumerated() {
            var x = -4 * s, i = 0
            while x < c.w {
                let bw = (6 + Int(noise(i * 7 + spec.seed * 131) * 11)) * s
                var bh = Int(Double(g) * (spec.lo + noise(i * 7 + 1 + spec.seed * 131) * (spec.hi - spec.lo)))
                if noise(i * 7 + 3 + spec.seed * 131) > 0.85 { bh = bh * 13 / 10 }
                out.append(TowerBlock(x: x, y: g - bh, w: bw, h: bh, near: layer == 1))
                x += bw + (layer == 0 ? 0 : Int(noise(i * 7 + 2 + spec.seed * 131) * 5) * s)
                i += 1
            }
        }
        return out
    }

    /// One skyline building with a scatter of lit windows and a lighter rooftop edge.
    static func towerBuilding(_ c: PixelCanvas, _ b: TowerBlock, _ col: Px, lit: Double, seed: Int) {
        c.rect(b.x, b.y, b.w, b.h, col)
        c.rect(b.x, b.y, b.w, 1, lerp(col, C(0x6A78A8), 0.35))
        let step = max(2, b.w / 6)
        for (j, wy) in stride(from: b.y + 2, to: b.y + b.h - 1, by: 3).enumerated() {
            for (k, wx) in stride(from: b.x + 1, to: b.x + b.w - 1, by: step).enumerated()
            where noise(b.x * 31 + j * 7 + k * 13 + seed * 977) > 0.7 {
                c.px(wx, wy, noise(j + k * 3 + b.x) > 0.8 ? C(0xBFE0FF, lit) : C(0xFFD98A, lit))
            }
        }
    }

    /// The Empire State and the Chrysler Building, so it's unmistakably Manhattan.
    static func towerLandmarks(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), col = C(0x262E5C), edge = C(0x8A9ACA)
        // Empire State: stepped setbacks and a mast
        let ex = Int(Double(c.w) * 0.3), eh = Int(Double(g) * 0.66), et = g - eh
        c.rect(ex - 9 * s, et + 14 * s, 18 * s, eh - 14 * s, col)
        c.rect(ex - 7 * s, et + 8 * s, 14 * s, 6 * s, col)
        c.rect(ex - 5 * s, et + 4 * s, 10 * s, 4 * s, col)
        c.rect(ex - 3 * s, et, 6 * s, 4 * s, col)
        c.rect(ex - s, et - 4 * s, 2 * s, 4 * s, col)
        c.rect(ex, et - 10 * s, s, 6 * s, edge)
        for (j, y) in stride(from: et + 16 * s, to: g, by: 3 * s).enumerated() {
            for (k, x) in stride(from: ex - 7 * s, to: ex + 8 * s, by: 3 * s).enumerated() where noise(j * 5 + k + 77) > 0.5 {
                c.rect(x, y, s, s, C(0xFFE6B0, 0.55))
            }
        }
        c.rect(ex - 7 * s, et + 8 * s, 14 * s, s, C(0xBFD8FF, 0.7))          // the floodlit crown
        c.rect(ex - 5 * s, et + 4 * s, 10 * s, 4 * s, C(0x9AB8F0, 0.45))
        c.rect(ex - 3 * s, et, 6 * s, 4 * s, C(0xBFD8FF, 0.6))
        c.rect(ex - s, et - 4 * s, 2 * s, 4 * s, C(0xE0ECFF, 0.7))
        // Chrysler: the stacked arches of its crown and the needle
        let cx = Int(Double(c.w) * 0.53), ch = Int(Double(g) * 0.6), ct = g - ch
        c.rect(cx - 6 * s, ct + 14 * s, 12 * s, ch - 14 * s, col)
        for k in 0..<5 {
            let hw = (5 - k) * s, y = ct + 14 * s - (k + 1) * 3 * s
            c.rect(cx - hw, y, hw * 2, 3 * s, col)
            c.rect(cx - hw, y, hw * 2, s, C(0xB8C4DC, 0.75))
            for wx in stride(from: cx - hw + s, to: cx + hw - s, by: 2 * s) { c.rect(wx, y + s, s, s, C(0xFFE6B0, 0.6)) }
        }
        c.rect(cx, ct - 8 * s, s, 9 * s, C(0xB8C4DC))
    }

    /// The tower: glass shaft, the slanted crown, the landing pad, the claw emblem and the lounge at its foot.
    static func towerTower(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = towerFrame(c, g), tx = f.x, tw = f.w, top = f.top
        let glass = C(0x22304E), mull = C(0x16203A), sheen = C(0x3A5078)
        let crown = 12 * s
        // a broader lower block on the left, then the shaft
        c.rect(tx - 8 * s, top + 44 * s, 8 * s, g - top - 44 * s, C(0x1A2440))
        for y in stride(from: top + 46 * s, to: g, by: 3 * s) { c.rect(tx - 7 * s, y, 6 * s, s, C(0x9ACBFF, 0.18)) }
        for k in 0..<tw {
            let y = top + crown - k * crown / tw
            c.rect(tx + k, y, 1, g - y, glass)
            c.px(tx + k, y, C(0x9AC4F0))
        }
        c.rect(tx + 3 * s, top + crown, 4 * s, g - top - crown, sheen)
        c.rect(tx + 4 * s, top + crown, s, g - top - crown, C(0x5A78A8))
        for x in stride(from: tx + 10 * s, to: tx + tw, by: 5 * s) { c.rect(x, top + crown, s, g - top - crown, mull) }
        for (j, y) in stride(from: top + crown + 2 * s, to: g, by: 3 * s).enumerated() {
            c.rect(tx, y, tw, 1, C(0x2C3C60))
            for k in 0..<4 where noise(j * 11 + k * 5 + 600) > 0.55 {
                c.rect(tx + 10 * s + k * 5 * s + s, y + 1, 3 * s, max(1, s), C(0xBFE4FF, 0.45))
            }
        }
        c.rect(tx + tw - s, top, s, g - top, C(0x6A8AB8))
        // the landing pad jutting out to the right, with its rim lights
        let py = top + 30 * s
        c.rect(tx + tw, py, 16 * s, 2 * s, C(0x3A4866))
        c.rect(tx + tw, py, 16 * s, s, C(0x8AA8D0))
        for k in 0..<6 { c.rect(tx + tw + k * 2 * s, py + 2 * s + k * s, 2 * s, s, C(0x2A3654)) }
        for x in stride(from: tx + tw + 2 * s, to: tx + tw + 16 * s, by: 4 * s) { c.rect(x, py - s, s, s, C(0x9AE0FF)) }
        // the Clawdvengers emblem: a C (for Clawd) in the ring
        let ax = tx + tw / 2 - 7 * s, ay = top + crown + 3 * s
        c.circle(ax + 7 * s, ay + 7 * s, 11 * s, C(0x9ACBFF, 0.10))
        c.circle(ax + 7 * s, ay + 7 * s, 9 * s, C(0x9ACBFF, 0.12))
        let lx0 = Double(ax + 7 * s), ly0 = Double(ay + 7 * s), u = Double(s)
        c.circle(Int(lx0), Int(ly0), 7 * s, C(0xDCEEFF)); c.circle(Int(lx0), Int(ly0), 5 * s, glass)
        let stroke = { (x0: Double, y0: Double, x1: Double, y1: Double) in
            c.glowLine(lx0 + x0 * u, ly0 + y0 * u, lx0 + x1 * u, ly0 + y1 * u, core: white, glow: C(0xBFE4FF), coreR: 0.8 * u, glowR: 1.2 * u, strength: 1)
        }
        let arc: [(Double, Double)] = stride(from: 45.0, through: 315.0, by: 30.0).map { (deg: Double) -> (Double, Double) in
            let r: Double = deg * .pi / 180
            return (3.6 * cos(r), 3.6 * sin(r))
        }
        for (a, b) in zip(arc, arc.dropFirst()) { stroke(a.0, a.1, b.0, b.1) }
        stroke(-1, 0, 9, 0); stroke(9, 0, 7, -2); stroke(9, 0, 7, 2)   // the bar out through the ring, an arrow   // the C, open to the right
        // the glass lounge at the tower's foot
        let lx = tx - 14 * s, lw = tw + 26 * s, lh = 18 * s, ly = g - lh
        c.rect(lx, ly, lw, lh, C(0x1A2034))
        for k in 0..<lh - s { c.rect(lx + s, ly + s + k, lw - 2 * s, 1, lerp(C(0x2A2636), C(0x5A4232), Double(k) / Double(lh))) }
        c.rect(lx + s, ly + s, lw - 2 * s, s, C(0xFFE0A8, 0.45))
        for k in 0..<5 {                                                   // pendant lamps
            c.rect(lx + 6 * s + k * 9 * s, ly + s, max(1, s / 2), 3 * s, C(0x8A7A6A))
            c.rect(lx + 5 * s + k * 9 * s, ly + 4 * s, 3 * s, s, C(0xFFE6B0)); c.circle(lx + 6 * s + k * 9 * s, ly + 5 * s, 3 * s, C(0xFFD890, 0.12))
        }
        c.rect(lx + 4 * s, ly + lh - 7 * s, 14 * s, 7 * s, C(0x2A1E1A))     // the bar
        c.rect(lx + 4 * s, ly + lh - 7 * s, 14 * s, s, C(0xC8A070))
        for k in 0..<4 { c.rect(lx + 6 * s + k * 3 * s, ly + lh - 10 * s, s, 3 * s, [C(0x7AC8A0), C(0xC87A4A), C(0xE8D8A0), C(0x8A6AC0)][k]) }
        c.rect(lx + 24 * s, ly + lh - 5 * s, 14 * s, 3 * s, C(0x3A3040))  // couch
        c.rect(lx + 24 * s, ly + lh - 8 * s, 2 * s, 6 * s, C(0x3A3040))
        for x in stride(from: lx, to: lx + lw, by: 14 * s) { c.rect(x, ly, s, lh, C(0x6A8AB8, 0.7)) }
        c.rect(lx + lw - s, ly, s, lh, C(0x6A8AB8, 0.7))
        c.rect(lx + 2 * s, ly + 2 * s, 2 * s, lh - 4 * s, C(0xBFE0FF, 0.08))
        c.rect(lx, ly, lw, s, C(0x8AA8D0))
    }

    /// Windows going on and off across the city, the tower's beacon and now and then a Quinjet crossing the sky.
    static func towerLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = towerFrame(c, g)
        let near = towerBlocks(c, g).filter { $0.near && $0.h > 8 && ($0.x + $0.w < f.x - 16 * s || $0.x > f.x + f.w + 14 * s) }
        if !near.isEmpty {
            for i in 0..<max(8, c.w / 30) {
                let b = near[Int(noise(i * 13 + 5) * Double(near.count)) % near.count]
                let wx = b.x + 1 + Int(noise(i * 13 + 6) * Double(max(1, b.w - 2)))
                let wy = b.y + 3 + Int(noise(i * 13 + 7) * Double(max(1, b.h - 5))) / 3 * 3
                if noise(Int(t * 0.6 + noise(i) * 7) * 31 + i) > 0.45 { c.px(wx, wy, C(0xFFD98A, 0.8)) }
            }
        }
        if scenes1Phase(t, 1.6) < 0.18 {                     // the aircraft beacon on the crown
            c.rect(f.x + f.w - 2 * s, f.top - s, 2 * s, s, C(0xFF4A4A))
            c.circle(f.x + f.w - s, f.top - s, 2 * s, C(0xFF4A4A, 0.25))
        }
        // the Quinjet: across the sky, then a pause
        let speed = 38.0 * Double(s), travel = Double(c.w + 60 * s), dur = travel / speed, cycle = dur + 9
        let ph = (t + 4).truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let x = Int(-30.0 * Double(s) + ph * speed), y = g / 5 + Int(sin(ph * 0.8) * 2 * Double(s))
        scenes1Stamp(c, x, y, [
            "..d...........",
            "..dd..........",
            "eddddddddcc...",
            ".ddddddddddddd",
            "...dddddd.....",
        ], ["d": C(0x5A6474), "c": C(0x9AD8FF), "e": C(0x8AE0FF)], s: s)
        c.rect(x + 2 * s, y + 3 * s, 12 * s, s, C(0x8A94A4))
        c.rect(x - 4 * s, y + 2 * s, 4 * s, s, C(0x8AE0FF, 0.4))
        if scenes1Phase(t, 0.8) < 0.5 { c.rect(x + 13 * s, y + 3 * s, s, s, C(0xFF5A5A)) }
    }
}

// MARK: - Sanctum Sanctorum

extension Scenes {
    /// The round window's centre and radius.
    static func sanctumWindow(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let r = max(14, min(Int(Double(g) * (isTall(c) ? 0.27 : 0.36)), c.w / 6))
        return (c.w / 2, isTall(c) ? Int(Double(g) * 0.36) : r + 3, r)
    }

    /// Where the candle flames are, shared by the still picture and the flicker.
    static func sanctumCandles(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g), w = sanctumWindow(c, g), off = w.r + 34 * s
        var out: [(x: Int, y: Int)] = []
        for side in [-1, 1] {
            var x = w.x + side * off
            while x > 4 && x < c.w - 4 {
                out.append((x, g - 22 * s))
                x += side * 76 * s
            }
        }
        return out
    }

    /// The Sanctum Sanctorum, 177A Bleecker Street: dark wood panelling, the great round skylight window with the
    /// Seal of the Vishanti in its lattice, a moonlit beam falling through it, the grand staircase climbing to the
    /// landing beneath it, tall candle stands, bookshelves and relics on their pedestals, and the Cloak of Levitation
    /// drifting about on its own.
    static func sanctum(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), win = sanctumWindow(c, g)
        c.rect(0, 0, c.w, g, C(0x2A1A12))
        // panelled walls: pilasters, framed panels and the wainscot
        let wain = g - 14 * s
        for x in stride(from: 0, to: c.w, by: 40 * s) {
            c.rect(x + 6 * s, 6 * s, 28 * s, wain - 10 * s, C(0x33211A))
            c.rect(x + 6 * s, 6 * s, 28 * s, s, C(0x1E120C)); c.rect(x + 6 * s, wain - 5 * s, 28 * s, s, C(0x45301F))
            c.rect(x, 0, 4 * s, g, C(0x3E2A1C)); c.rect(x + s, 0, s, g, C(0x56402A))
        }
        c.rect(0, wain, c.w, g - wain, C(0x24160F))
        c.rect(0, wain, c.w, 2 * s, C(0x5A3E26)); c.rect(0, wain, c.w, s, C(0x7A5634))
        for x in stride(from: 3 * s, to: c.w, by: 14 * s) { c.rect(x, wain + 4 * s, 10 * s, g - wain - 6 * s, C(0x2C1C13)) }
        if tall { sanctumHigh(c, g) }
        sanctumWindowDraw(c, g)
        // the staircase up to the landing under the window
        let land = win.y + win.r + 6 * s, lw = win.r + 14 * s
        c.rect(win.x - lw, land, lw * 2, 3 * s, C(0x4A2E1C)); c.rect(win.x - lw, land, lw * 2, s, C(0x8A6038))
        c.rect(win.x - lw, land + 3 * s, lw * 2, g - land - 3 * s, C(0x2E1C12))
        sanctumUnderLanding(c, g, x0: win.x - lw, x1: win.x + lw, y0: land + 3 * s)
        for side in [-1, 1] {
            let steps = max(2, (g - land) / (3 * s))
            for k in 0..<steps {
                let y = land + k * 3 * s, x0 = side < 0 ? win.x - lw - (k + 1) * 4 * s : win.x + lw + k * 4 * s
                c.rect(x0, y + 3 * s, 4 * s, g - y - 3 * s, C(0x3A2416))
                c.rect(x0, y + 3 * s, 4 * s, s, C(0x6E4A2C))
            }
            // the banister following the flight down
            let bx = side < 0 ? win.x - lw : win.x + lw
            for k in 0...steps {
                let x = bx + side * k * 4 * s, y = land + k * 3 * s - 6 * s
                c.rect(x, y, s, 6 * s, C(0x5A3A22))
                c.rect(x - (side < 0 ? 4 * s : 0), y, 4 * s, s, C(0x8A5A30))
            }
            c.rect(bx - s, land - 8 * s, 3 * s, 8 * s, C(0x6A4428)); c.rect(bx - s, land - 9 * s, 3 * s, s, C(0xC89A50))
        }
        for x in stride(from: win.x - lw + 3 * s, to: win.x + lw - 2 * s, by: 3 * s) { c.rect(x, land - 6 * s, s, 6 * s, C(0x5A3A22)) }
        c.rect(win.x - lw, land - 6 * s, lw * 2, s, C(0x8A5A30))
        sanctumFurniture(c, g)
        // the moonbeam from the window across the floor
        for y in (win.y + win.r / 2)..<g {
            let k = Double(y - win.y) / Double(max(1, g - win.y))
            let half = Int(Double(win.r) * (0.45 + k * 0.5))
            c.rect(win.x - half + Int(k * Double(win.r) * 0.3), y, half * 2, 1, C(0xB8D0F0, 0.05))
        }
        c.ground(g, C(0x3A2416), edge: C(0x7A5232), speck: C(0x2E1C10), seed: 31)
        for x in stride(from: 0, to: c.w, by: 12 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x2E1C10)) }
        // the carpet runner at the foot of the stairs
        c.rect(win.x - 22 * s, g + 2 * s, 44 * s, c.h - g - 3 * s, C(0x6A1A1E))
        c.rect(win.x - 22 * s, g + 2 * s, 44 * s, s, C(0xC8963A)); c.rect(win.x - 22 * s, c.h - 2 * s, 44 * s, s, C(0xC8963A))
        c.ellipse(win.x + win.r / 3, g + (c.h - g) / 2, win.r, max(2, (c.h - g) / 3), C(0xC8DCF8, 0.08))
    }

    /// The round window: night sky behind the Seal of the Vishanti, rings and four sweeping arms.
    static func sanctumWindowDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), w = sanctumWindow(c, g), r = w.r
        c.circle(w.x, w.y, r + 5 * s, C(0x1A0F09))
        c.circle(w.x, w.y, r + 3 * s, C(0x6A4626))
        c.circle(w.x, w.y, r + 2 * s, C(0x2A1A10))
        for k in stride(from: r, to: 0, by: -max(1, r / 6)) {
            c.circle(w.x, w.y, k, lerp(C(0x3E5A7E), C(0x1C2A48), Double(k) / Double(r)))
        }
        c.stars(w.y - r, w.y + r, density: 26, seed: 8, x0: w.x - r, x1: w.x + r) { x, y in
            (x - w.x) * (x - w.x) + (y - w.y) * (y - w.y) < (r - 2) * (r - 2)
        }
        let lat = C(0xE6D6AE), th = max(1, r / 18)
        let dot = { (x: Double, y: Double) in c.rect(Int(x) - th / 2, Int(y) - th / 2, th, th, lat) }
        for ring in [Double(r) - Double(th) / 2, Double(r) * 0.36] {
            let n = Int(ring * 8)
            for i in 0..<max(8, n) {
                let a = Double(i) / Double(max(8, n)) * 2 * .pi
                dot(Double(w.x) + cos(a) * ring, Double(w.y) + sin(a) * ring)
            }
        }
        for arm in 0..<4 {                                  // the four swirling arms of the seal
            for i in 0...Int(Double(r) * 3) {
                let u = Double(i) / (Double(r) * 3)
                let a = Double(arm) * .pi / 2 - .pi / 4 + u * 1.9
                let rad = Double(r) * (0.36 + u * 0.62)
                dot(Double(w.x) + cos(a) * rad, Double(w.y) + sin(a) * rad)
                if u > 0.15, u < 0.6 {                      // and the inner loop each arm throws off
                    let b = a - 0.9, rr = Double(r) * (0.36 + (u - 0.15) * 0.5)
                    dot(Double(w.x) + cos(b) * rr, Double(w.y) + sin(b) * rr)
                }
            }
        }
        c.circle(w.x, w.y, max(1, r / 9), lat)
        c.circle(w.x, w.y, max(1, r / 14), C(0x8AB4E0))
    }

    /// Bookshelves, relics on pedestals and candle stands, spread along the walls either side of the stairs.
    static func sanctumFurniture(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), win = sanctumWindow(c, g)
        let books = [C(0x6A2A22), C(0x2A4A3A), C(0x7A5A2A), C(0x3A2A4A), C(0x8A6A4A), C(0x2A3A5A)]
        for side in [-1, 1] {
            var x = win.x + side * (win.r + 58 * s), i = 0
            while (side < 0 && x > -20 * s) || (side > 0 && x < c.w + 20 * s) {
                if i % 2 == 0 {                              // a tall bookshelf
                    let hgt = min(g - 6 * s, 40 * s + (isTall(c) ? g / 4 : 0)), y0 = g - hgt
                    c.rect(x - 11 * s, y0, 22 * s, hgt, C(0x1E120B))
                    c.rect(x - 12 * s, y0 - s, 24 * s, 2 * s, C(0x5A3A22))
                    for (j, sy) in stride(from: y0 + 2 * s, to: g - 4 * s, by: 7 * s).enumerated() {
                        var bx = x - 10 * s, n = 0
                        while bx < x + 9 * s {
                            let bw = (1 + Int(noise(j * 17 + n + x) * 2.0)) * s, bh = (4 + Int(noise(j * 13 + n * 3 + x) * 2.0)) * s
                            c.rect(bx, sy + 6 * s - bh, bw, bh, books[(j + n + i) % books.count])
                            bx += bw; n += 1
                        }
                        c.rect(x - 11 * s, sy + 6 * s, 22 * s, s, C(0x4A3020))
                    }
                } else {                                    // a relic on its pedestal under a glass dome
                    c.rect(x - 4 * s, g - 12 * s, 8 * s, 12 * s, C(0x3A2618)); c.rect(x - 5 * s, g - 12 * s, 10 * s, 2 * s, C(0x6A4A2C))
                    c.ellipse(x, g - 17 * s, 4 * s, 5 * s, C(0xB8D8E8, 0.16))
                    switch i % 6 {
                    case 1: c.circle(x, g - 16 * s, 2 * s, C(0x3AE07A)); c.rect(x - s, g - 19 * s, 2 * s, s, C(0xC8963A))   // an eye-like gem
                    case 3: c.rect(x - s, g - 21 * s, 2 * s, 8 * s, C(0xA8A8B0)); c.rect(x - 3 * s, g - 15 * s, 6 * s, s, C(0xC8963A))   // a blade
                    default: c.rect(x - 2 * s, g - 18 * s, 4 * s, 5 * s, C(0x8A5A2A)); c.rect(x - s, g - 20 * s, 2 * s, 2 * s, C(0xD8B060))   // an urn
                    }
                }
                i += 1
                x += side * 38 * s
            }
        }
        for p in sanctumCandles(c, g) {                      // candle stands
            c.rect(p.x - s / 2, p.y + 3 * s, max(1, s), g - p.y - 3 * s, C(0x8A6A3A))
            c.rect(p.x - 3 * s, g - s, 7 * s, s, C(0x8A6A3A))
            c.rect(p.x - 4 * s, p.y + 3 * s, 9 * s, s, C(0xA8844A))
            for dx in [-4, 0, 4] { c.rect(p.x + dx * s - s / 2, p.y, max(1, s), 3 * s, C(0xEDE2C8)) }
        }
    }

    /// The front of the landing: panelling, with an arched doorway in the middle when there's room.
    static func sanctumUnderLanding(_ c: PixelCanvas, _ g: Int, x0: Int, x1: Int, y0: Int) {
        let s = unit(g), hgt = g - y0
        guard hgt > 4 * s else { return }
        for x in stride(from: x0 + 3 * s, to: x1 - 8 * s, by: 12 * s) {
            c.rect(x, y0 + 2 * s, 9 * s, hgt - 4 * s, C(0x24160E)); c.rect(x, y0 + 2 * s, 9 * s, s, C(0x1A0F09))
            c.rect(x, y0 + hgt - 3 * s, 9 * s, s, C(0x4A3020))
        }
        guard hgt > 30 * s else { return }
        let cx = (x0 + x1) / 2, dw = 16 * s, dh = min(hgt - 2 * s, 40 * s)
        c.rect(cx - dw - 2 * s, g - dh, dw * 2 + 4 * s, dh, C(0x5A3A22))
        c.ellipse(cx, g - dh, dw + 2 * s, dw / 2 + 2 * s, C(0x5A3A22))
        c.rect(cx - dw, g - dh, dw * 2, dh, C(0x3A1E12))
        c.ellipse(cx, g - dh, dw, dw / 2, C(0x3A1E12))
        c.rect(cx - s / 2, g - dh - dw / 2, max(1, s), dh + dw / 2, C(0x1A0F09))
        for side in [-1, 1] {
            c.rect(cx + side * dw / 2 - s, g - dh / 2, 2 * s, 2 * s, C(0xC89A50))
            c.rect(cx + side * (dw + 8 * s) - s, g - dh - 2 * s, 3 * s, 4 * s, C(0xC89A50))      // sconces
            c.rect(cx + side * (dw + 8 * s) - s / 2, g - dh - 5 * s, max(1, s), 3 * s, C(0xFFE08A))
            c.circle(cx + side * (dw + 8 * s), g - dh - 4 * s, 6 * s, C(0xFFC870, 0.1))
        }
    }

    /// Up high: the cornice, a gallery with its balustrade either side of the window, and hanging lamps.
    static func sanctumHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), win = sanctumWindow(c, g)
        c.rect(0, 0, c.w, g / 16, C(0x1E120C)); c.rect(0, g / 16, c.w, 2 * s, C(0x6A4628))
        for x in stride(from: 0, to: c.w, by: 8 * s) { c.rect(x, g / 16 + 2 * s, 4 * s, 2 * s, C(0x4A3020)) }
        let gy = g / 2
        for side in [-1, 1] {
            let x0 = side < 0 ? 0 : win.x + win.r + 12 * s, x1 = side < 0 ? win.x - win.r - 12 * s : c.w
            guard x1 > x0 else { continue }
            c.rect(x0, gy, x1 - x0, 4 * s, C(0x3A2416)); c.rect(x0, gy, x1 - x0, s, C(0x7A5232))
            c.rect(x0, gy + 4 * s, x1 - x0, 2 * s, C(0x1A0F09))
            c.rect(x0, gy - 8 * s, x1 - x0, s, C(0x8A5A30))
            for x in stride(from: x0 + 2 * s, to: x1, by: 4 * s) { c.rect(x, gy - 7 * s, s, 7 * s, C(0x5A3A22)) }
            for x in stride(from: x0 + 20 * s, to: x1 - 10 * s, by: 60 * s) {      // hanging lamps
                c.rect(x, g / 16 + 2 * s, s, gy - g / 16 - 40 * s, C(0x3A2416))
                c.rect(x - 3 * s, gy - 38 * s, 7 * s, 4 * s, C(0xC8963A)); c.rect(x - 2 * s, gy - 34 * s, 5 * s, 2 * s, C(0xFFD88A))
                c.circle(x, gy - 33 * s, 8 * s, C(0xFFC870, 0.08))
            }
        }
    }

    /// Candle flames flickering and the Cloak of Levitation bobbing in the air beside the stairs.
    static func sanctumLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        var s = unit(g)
        let win = sanctumWindow(c, g)
        for (i, p) in sanctumCandles(c, g).enumerated() {
            for (j, dx) in [-4, 0, 4].enumerated() {
                let k = Int(t * 9) + i * 7 + j * 3
                let x = p.x + dx * s, tall = noise(k) > 0.5 ? 2 : 1
                c.circle(x, p.y - 2 * s, 3 * s, C(0xFFB050, 0.12 + noise(k + 1) * 0.08))
                c.rect(x - s / 2, p.y - (tall + 1) * s, max(1, s), tall * s, C(0xFFE08A))
                c.rect(x - s / 2, p.y - s, max(1, s), s, C(0xFF8A2A))
                if noise(k + 2) > 0.7 { c.px(x + (noise(k + 3) > 0.5 ? s : -s), p.y - (tall + 1) * s, C(0xFFD060, 0.7)) }
            }
        }
        // the cloak, a little to the right of the stairs (a touch bigger on the screen saver)
        s = max(s, g / 110)
        let bob = Int((sin(t * 1.4) * 2.5).rounded()) * s
        let x = win.x + win.r + 30 * s, y = g - 44 * s + bob
        let sway = sin(t * 1.4 + 1) > 0 ? 1 : 0
        let hem = sway == 1 ? "rrdrrdrrdr." : ".rdrrdrrdrr"
        scenes1Stamp(c, x, y, [
            "gg.....gg..",
            "grr...rrg..",
            ".grrrrrg...",
            ".rrryrrr...",
            ".rrrrrrrr..",
            "rrrrdrrrr..",
            "rrrrdrrrrr.",
            "rrrrdrrrrr.",
            "rrrrrdrrrr.",
            "rrrrrdrrrrr",
            "rrrrrdrrrrr",
            hem,
            sway == 1 ? "r.d.r..d.r." : ".r.d..r.d.r",
        ], ["r": C(0xB0222A), "d": C(0x7A1018), "g": C(0xD8A84A), "y": C(0xF0C85A)], s: s)
        c.ellipse(x + 5 * s, g + 2 * s, 5 * s, max(1, s), C(0x000000, 0.18))
    }
}

// MARK: - Wakanda

extension Scenes {
    /// Wakanda at sunset: a purple-to-gold sky, Mount Bashenga's great dark bulk behind the Golden City, whose towers
    /// (rounded vibranium spires, thatch-crowned towers and slender needles) catch the last light, with a maglev line
    /// on stilts running in front, acacias, and red earth with a woven pattern underfoot. Talon fighters drift by and
    /// a maglev train glides along its rail.
    static func wakanda(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let mid = Int(Double(g) * 0.55)
        c.gradient(0, mid, C(0x2A1440), C(0xC85A5A), bands: 6)
        c.gradient(mid, g, C(0xD8705A), C(0xFFC478), bands: 5)
        if tall { c.stars(0, g / 4, density: 120, seed: 12) }
        let sx = Int(Double(c.w) * 0.64), sy = Int(Double(g) * 0.58), sr = max(5, g / 9)
        c.circle(sx, sy, sr * 2, C(0xFFD08A, 0.12)); c.circle(sx, sy, sr * 3 / 2, C(0xFFD890, 0.15))
        c.circle(sx, sy, sr, C(0xFFEAB0))
        for (i, fy) in [0.2, 0.32, 0.45].enumerated() {      // streaks of cloud lit from below
            for k in 0..<max(2, c.w / 160) {
                let x = Int((Double(k) + noise(i * 9 + k)) * 160.0 * Double(s))
                wisp(c, x, Int(Double(g) * fy), (40 + Int(noise(i * 9 + k + 4) * 50)) * s, C(0xF09A7A, 0.45), s: s)
            }
        }
        wakandaMountain(c, g)
        c.dunes(base: g - 18 * s, amp: 3, freq: 0.04, phase: 1, bottom: g, C(0x8A4A52))
        wakandaCity(c, g, far: true)
        wakandaCity(c, g, far: false)
        // the maglev line on its stilts
        let ry = g - 13 * s
        c.rect(0, ry, c.w, 2 * s, C(0x2A1828)); c.rect(0, ry, c.w, s, C(0xC89A6A))
        for x in stride(from: 10 * s, to: c.w, by: 34 * s) { c.rect(x, ry + 2 * s, 2 * s, g - ry - 2 * s, C(0x2A1828)) }
        for x in stride(from: 6, to: c.w, by: 23 * s) {       // acacias and scrub
            let n = noise(x + 77)
            guard n > 0.35 else { continue }
            let h = (5 + Int(n * 6)) * s
            c.rect(x, g - h, s, h, C(0x2A1A16))
            c.ellipse(x, g - h, (5 + Int(n * 4)) * s, max(1, 2 * s), C(0x2A3A22))
            c.ellipse(x - s, g - h - s, (3 + Int(n * 3)) * s, max(1, s), C(0x3A5A2E))
        }
        c.ground(g, C(0x7A3A26), edge: C(0xC8784A), speck: C(0x6A2E1E), seed: 41)
        for x in stride(from: 0, to: c.w, by: 8 * s) {         // a woven chevron border
            c.rect(x, g + 2 * s, 4 * s, s, C(0x8A4630)); c.rect(x + 2 * s, g + 3 * s, 4 * s, s, C(0x6A2C1C))
            c.rect(x, g + 4 * s, 4 * s, s, C(0x8A4630))
        }
    }

    /// Mount Bashenga: a broad, round-shouldered mountain, darker where it turns from the sun.
    static func wakandaMountain(_ c: PixelCanvas, _ g: Int) {
        let pk = Double(c.w) * 0.3, H = Double(g) * 0.62, sig = Double(min(c.w, g * 6)) * 0.17
        let height = { (x: Double) -> Double in
            let d = (x - pk) / sig
            return H * exp(-pow(abs(d), 2.4)) + H * 0.42 * exp(-pow((x - pk - sig * 1.6) / (sig * 0.7), 2))
                + H * 0.3 * exp(-pow((x - pk + sig * 1.5) / (sig * 0.8), 2))
        }
        for x in 0..<c.w {
            let hgt = height(Double(x)), slope = height(Double(x) + 3) - hgt
            let top = g - Int(hgt) + Int(noise(x / 3 + 900) * 2)
            guard top < g else { continue }
            let k = max(0, min(1, 0.5 + (Double(x) - pk) / sig * 0.45 - slope * 0.15))
            let k4 = ((k * 3 + (noise(x * 13) - 0.5) * 0.5).rounded() / 3)
            c.rect(x, top, 1, g - top, lerp(C(0x4A2238), C(0x7A3A4C), k4))
            c.px(x, top, lerp(C(0x6A3448), C(0xD87A5E), k4))
            for y in stride(from: top + 6, to: g, by: 9) where noise(x * 7 + y) > 0.93 { c.px(x, y, C(0x3A1A2E)) }   // rock seams
        }
        // the mound's vibranium glow, faint at its foot
        c.ellipse(Int(pk), g - Int(H * 0.15), Int(sig * 0.6), max(2, Int(H * 0.08)), C(0x9A6AE0, 0.12))
    }

    /// The Golden City: a band of towers across the whole width.
    static func wakandaCity(_ c: PixelCanvas, _ g: Int, far: Bool) {
        let s = max(unit(g), g / 110), seed = far ? 700 : 500
        var x = (far ? -14 : -6) * s, i = 0
        let body = far ? [C(0x6A3448), C(0x74384C), C(0x60304A)] : [C(0x3A1E30), C(0x4A2638), C(0x2E1828)]
        let rim = far ? C(0xE88A62) : C(0xFFB46A), thatch = far ? C(0x8A5040) : C(0x7A5232)
        let lit = C(0xFFD27A, far ? 0.5 : 0.85), base = g - 14 * s
        while x < c.w {
            let n = noise(i * 11 + seed), kind = n < 0.08 ? 3 : Int(n * 4.4) % 3
            let bw = ((far ? 5 : 7) + Int(noise(i * 11 + seed + 1) * (far ? 7 : 10))) * s
            var bh = Int(Double(g) * ((far ? 0.14 : 0.1) + noise(i * 11 + seed + 2) * (far ? 0.22 : 0.24)))
            if kind == 3 { bh = Int(Double(bh) * 1.5) }
            let col = body[i % 3], y = base - bh
            switch kind {
            case 0:                                             // a bullet-nosed vibranium tower
                c.rect(x, y + bw / 2, bw, bh - bw / 2 + 14 * s, col)
                c.ellipse(x + bw / 2, y + bw / 2, bw / 2, bw / 2, col)
                c.rect(x + bw - s, y + bw / 2, s, bh, rim.alpha(0.6))
                c.rect(x + bw / 2, y - s, s, s, C(0xC89AFF))
            case 1:                                             // a thatch-crowned tower
                c.rect(x, y + 3 * s, bw, bh + 11 * s, col)
                for k in 0..<(bw / 2 + 2 * s) {
                    c.rect(x - 2 * s + k, y + 3 * s - k / 2, bw + 4 * s - 2 * k, 1, thatch)
                }
                c.rect(x - 2 * s, y + 3 * s, bw + 4 * s, s, rim.alpha(0.8))
            case 2:                                             // a tower tapering as it climbs, a garden on top
                for k in 0..<bh {
                    let inset = k * bw / (bh * 4)
                    c.rect(x + inset, y + bh - k, bw - inset * 2, 1, col)
                    c.px(x + bw - inset - 1, y + bh - k, rim.alpha(0.55))
                }
                c.rect(x, y + bh, bw, 14 * s, col)
                c.rect(x + bw / 4, y - s, bw / 2, 2 * s, far ? lerp(C(0x4A6A3A), C(0x8A4A5A), 0.5) : C(0x3A6A34))
            default:                                            // a slender needle with a disc
                let nx = x + bw / 2 - s
                c.rect(nx, y, 2 * s, bh + 14 * s, col)
                c.rect(nx - 4 * s, y + bh / 4, 10 * s, 2 * s, col); c.rect(nx - 4 * s, y + bh / 4, 10 * s, s, rim)
                c.rect(nx, y - s, s, s, C(0xC89AFF))
            }
            if kind != 3 {
                for wy in stride(from: y + 6 * s, to: base, by: 4 * s) where noise(i * 7 + wy + seed) > (far ? 0.65 : 0.45) {
                    c.rect(x + s + Int(noise(wy + i) * Double(max(1, bw - 3 * s))), wy, s, s, lit)
                }
            }
            x += bw + Int(noise(i * 11 + seed + 3) * (far ? 7 : 9)) * s + s
            i += 1
        }
    }

    /// Talon fighters drifting over the city and a maglev train gliding along its rail.
    static func wakandaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        var s = max(unit(g), g / 110)
        for k in 0..<max(2, c.w / 200) {
            let speed = (5.0 + noise(k * 3) * 5) * Double(s) * (k % 2 == 0 ? 1 : -1)
            let span = Double(c.w + 40 * s)
            var x = (noise(k * 3 + 1) * span + t * speed).truncatingRemainder(dividingBy: span)
            if x < 0 { x += span }
            let px = Int(x) - 20 * s
            let y = Int(Double(g) * (0.18 + noise(k * 3 + 2) * 0.25)) + Int((sin(t * 0.9 + Double(k)) * 1.5).rounded()) * s
            let rows = speed > 0
                ? ["...dd.....", "dddddddc..", ".ddddddddd", "..p....p.."]
                : [".....dd...", "..cddddddd", "ddddddddd.", "..p....p.."]
            scenes1Stamp(c, px, y, rows, ["d": C(0x2A1A2E), "c": C(0xB08AE8), "p": C(0xB070FF, 0.7)], s: s)
        }
        // the train: across, then gone for a while
        s = unit(g)
        let speed = 70.0 * Double(s), len = 46 * s, dur = Double(c.w + len) / speed, cycle = dur + 6
        let ph = t.truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let x = c.w - Int(ph * speed), y = g - 17 * s
        for car in 0..<3 {
            let cx = x + car * 16 * s
            c.rect(cx + s, y, 14 * s, 4 * s, C(0xD8C8E0))
            c.rect(cx + s, y + 3 * s, 14 * s, s, C(0x6A4A8A))
            for wx in stride(from: cx + 3 * s, to: cx + 14 * s, by: 3 * s) { c.rect(wx, y + s, 2 * s, s, C(0x3A2A5A)) }
            c.rect(cx + s, y + 4 * s, 14 * s, s, C(0xB070FF, 0.5))
        }
        c.rect(x, y + s, s, 2 * s, C(0xFFF0C0))
    }
}

// MARK: - Asgard

extension Scenes {
    static let asgardBands = [C(0xE0505A), C(0xF09A40), C(0xF0E070), C(0x5AD07A), C(0x4AA8F0), C(0x8A64E0)]

    /// Asgard: the crew stands on the Bifrost, the rainbow bridge, glowing in its colours over the sea. Across the
    /// water the golden spires of the city climb to Odin's palace, a great organ of gold pipes in the middle, under a
    /// cosmic sky of nebulae, stars and a ringed world.
    static func asgard(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x0A0A26), C(0x7A68B8), bands: 7)
        // nebulae
        for i in 0..<max(3, c.w / 90) {
            let x = Int(noise(i * 5 + 40) * Double(c.w)), y = Int(noise(i * 5 + 41) * Double(g) * 0.5)
            let col = [C(0xE070C0), C(0x50C8E0), C(0x8A70F0)][i % 3]
            let r = (14 + Int(noise(i * 5 + 42) * 24)) * s
            c.ellipse(x, y, r * 2, r, col.alpha(0.07)); c.ellipse(x + r / 3, y, r, r / 2, col.alpha(0.08))
        }
        c.stars(0, g * 2 / 3, density: tall ? 70 : 34, seed: 14)
        if tall { asgardHigh(c, g) }
        let pr = max(5, g / (tall ? 8 : 9)), px0 = Int(Double(c.w) * 0.84), py0 = g / 5      // a ringed world
        let ringAt = { (front: Bool) in
            for k in 0..<360 {
                let a = Double(k) * .pi / 180
                guard (sin(a) > 0) == front else { continue }
                let x = px0 + Int(cos(a) * Double(pr) * 1.9), y = py0 + Int(sin(a) * Double(pr) * 0.42 - cos(a) * Double(pr) * 0.25)
                c.rect(x, y, max(1, pr / 8), max(1, pr / 10), C(0xE8D8B0, front ? 0.9 : 0.55))
            }
        }
        ringAt(false)
        c.circle(px0, py0, pr, C(0x5A86C0)); c.circle(px0 - pr / 4, py0 - pr / 4, pr * 2 / 3, C(0x7AA8E0))
        c.rect(px0 - pr + 2, py0 + pr / 3, pr * 2 - 4, max(1, pr / 7), C(0x4A70A8))
        ringAt(true)
        // distant mountains and the sea
        let shore = g - (tall ? g / 8 : 16 * s)
        c.dunes(base: shore - 4 * s, amp: 3, freq: 0.03, phase: 0.6, bottom: shore + 1, C(0x5A5290))
        asgardCity(c, g, shore: shore)
        c.rect(0, shore, c.w, g - shore, C(0x1E2A5A))
        for y in stride(from: shore + 2 * s, to: g, by: 3 * s) {
            for x in stride(from: Int(noise(y) * 9), to: c.w, by: 13 * s) where noise(x * 7 + y) > 0.4 {
                c.rect(x, y, (2 + Int(noise(x + y) * 4)) * s, s, noise(x * 3 + y) > 0.7 ? C(0xF0C860, 0.6) : C(0x4A5A9A))
            }
        }
        // the Bifrost running out across the sea to the palace
        let bx0 = Double(c.w) * 0.08, bx1 = Double(c.w / 2 - 30 * s)
        for x in Int(bx0)..<Int(bx1) {
            let u = max(0, (Double(x) - bx0) / (bx1 - bx0))
            let y = Int(Double(g) + (Double(shore + 2 * s) - Double(g)) * pow(u, 0.8))
            let th = max(1, Int(Double(7 * s) * (1 - u * 0.8)))
            c.rect(x, y - th - s, 1, th + 2 * s, C(0xFFFFFF, 0.10))
            for k in 0..<th { c.px(x, y - th + k, asgardBands[min(asgardBands.count - 1, k * asgardBands.count / th)].alpha(0.85)) }
        }
        // the Bifrost: rainbow light in a crystal deck
        let rows = c.h - g, bands = asgardBands
        for y in g..<c.h {
            let k = Double(y - g) / Double(max(1, rows)) * Double(bands.count)
            c.rect(0, y, c.w, 1, lerp(bands[min(bands.count - 1, Int(k))], C(0x1A1638), 0.38))
        }
        c.rect(0, g - 3 * s, c.w, 3 * s, C(0xFFF4E0, 0.08))
        c.rect(0, g, c.w, s, C(0xFFF4E0, 0.85))
        for x in stride(from: 0, to: c.w, by: 22 * s) { c.rect(x, g + s, s, rows - s, C(0xFFFFFF, 0.08)) }
    }

    /// The city: clusters of golden spires along the shore, the palace towering in the middle.
    static func asgardCity(_ c: PixelCanvas, _ g: Int, shore: Int) {
        let s = unit(g)
        let gold = C(0xC8902E), hi = C(0xF6D884), lo = C(0x8A5A1E)
        let spire = { (x: Int, w: Int, h: Int, far: Bool) in
            let y = shore - h
            let body = far ? lerp(gold, C(0x7A68B8), 0.45) : gold
            c.rect(x, y + w, w, h - w, body)
            for k in 0..<w { c.rect(x + k, y + abs(k - w / 2) * 2, 1, w, body) }      // pointed tip
            c.rect(x, y + w, max(1, w / 3), h - w, far ? lerp(hi, C(0x7A68B8), 0.45) : hi)
            c.rect(x + w - max(1, w / 4), y + w, max(1, w / 4), h - w, far ? lerp(lo, C(0x7A68B8), 0.45) : lo)
            if !far { for wy in stride(from: y + w + 3 * s, to: shore - 2, by: 5 * s) { c.rect(x + w / 2, wy, max(1, s), max(1, s), C(0xFFF6D0)) } }
        }
        // a far range of lesser spires, halls and domes across the whole shore
        let haze = lerp(C(0xA8802E), C(0x7A68B8), 0.5)
        for (i, x) in stride(from: 0, to: c.w, by: 6 * s).enumerated() {
            let n = noise(i * 3 + 70), h = Int(Double(g) * (0.06 + n * 0.14))
            if noise(i * 3 + 71) > 0.8 {
                c.rect(x - 4 * s, shore - h / 2, 12 * s, h / 2, haze); c.ellipse(x + 2 * s, shore - h / 2, 6 * s, 4 * s, haze)
            } else {
                spire(x, 3 * s, h, true)
            }
        }
        // clusters, the palace in the middle
        let palace = c.w / 2
        var centres = [palace]
        for k in 1...max(1, c.w / 260 + 1) { centres.append(palace - k * 130 * s); centres.append(palace + k * 130 * s) }
        for cx in centres {
            let big = cx == palace, peak = Double(g) * (big ? (isTall(c) ? 0.8 : 0.84) : 0.42)
            let half = (big ? 34 : 18) * s
            for (j, x) in stride(from: cx - half, through: cx + half, by: 4 * s).enumerated() {
                let d = Double(abs(x - cx)) / Double(half)
                let h = Int(peak * (0.12 + 0.88 * pow(1 - d, 1.6)) * (0.75 + noise(j + cx) * 0.25))
                spire(x, 4 * s, max(6 * s, h), false)
            }
            if big {                                          // the palace's broad base and its glowing hall
                c.rect(cx - half - 6 * s, shore - 12 * s, half * 2 + 16 * s, 12 * s, lo)
                c.rect(cx - half - 6 * s, shore - 12 * s, half * 2 + 16 * s, s, hi)
                for x in stride(from: cx - half - 4 * s, to: cx + half + 10 * s, by: 4 * s) { c.rect(x, shore - 9 * s, 2 * s, 6 * s, C(0xFFE6A0, 0.8)) }
            }
        }
    }

    /// Up high: a wide band of the galaxy and a second, paler moon.
    static func asgardHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for x in 0..<c.w {
            let y = g / 6 + Int(Double(x) * 0.18) - c.w / 16
            c.rect(x, y - 8 * s, 1, 16 * s, C(0xC8B8F0, 0.05))
            c.rect(x, y - 3 * s, 1, 6 * s, C(0xE8D8FF, 0.07))
        }
        c.stars(g / 8, g / 3, density: 45, seed: 15)
        c.circle(Int(Double(c.w) * 0.14), g / 7, max(4, g / 24), C(0xD8D0F0))
        c.circle(Int(Double(c.w) * 0.14) + 2 * s, g / 7 - s, max(3, g / 24) - s, C(0xEAE4FA))
    }

    /// The Bifrost shimmering: bright glints racing along the bridge, and the stars twinkling.
    static func asgardLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), rows = c.h - g, bands = asgardBands
        for i in 0..<max(6, c.w / 50) {
            let row = 1 + Int(noise(i * 7 + 1) * Double(max(1, rows - 2)))
            let speed = (40.0 + noise(i * 7 + 2) * 60) * Double(s)
            let span = Double(c.w + 60 * s)
            let x = Int((noise(i * 7 + 3) * span + t * speed).truncatingRemainder(dividingBy: span)) - 30 * s
            let col = bands[min(bands.count - 1, row * bands.count / max(1, rows))]
            let len = (8 + Int(noise(i * 7 + 4) * 16)) * s
            c.rect(x, g + row, len, 1, col.alpha(0.55))
            c.rect(x + len / 3, g + row, len / 3, 1, C(0xFFFFFF, 0.6))
        }
        for i in 0..<max(6, c.w / 40) {
            let k = Int(t * 2) + i * 19
            if noise(k) > 0.6 {
                let x = Int(noise(i * 3 + 900) * Double(c.w)), y = Int(noise(i * 3 + 901) * Double(g) * 0.5)
                c.px(x, y, white); c.px(x - 1, y, C(0xFFFFFF, 0.4)); c.px(x + 1, y, C(0xFFFFFF, 0.4))
                c.px(x, y - 1, C(0xFFFFFF, 0.4)); c.px(x, y + 1, C(0xFFFFFF, 0.4))
            }
        }
    }
}

// MARK: - Sakaar

extension Scenes {
    /// The arena's tiers of seats: top row of the stands and the height of one tier.
    static func sakaarStands(_ c: PixelCanvas, _ g: Int) -> (top: Int, tier: Int, wall: Int) {
        let s = unit(g)
        let wall = g - 12 * s
        return (isTall(c) ? wall - max(40 * s, g / 5) : wall - 18 * s, 4 * s, wall)
    }

    /// Sakaar, the Grandmaster's arena: a sand floor ringed by a wall striped in Sakaaran colours, tiers of a
    /// cheering crowd, the Grandmaster's gilded box, and beyond the rim the garbage planet's mountains of junk under a
    /// teal sky torn open by wormholes, the biggest, the Devil's Anus, swirling red and orange.
    static func sakaar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), st = sakaarStands(c, g)
        c.gradient(0, st.top, C(0x1E3A5A), C(0xD8A88A), bands: 6)
        c.stars(0, st.top / 2, density: 90, seed: 16)
        sakaarWormholeRim(c, Int(Double(c.w) * 0.7), st.top / 3, max(6, st.top / 4), C(0xFF5A2A))
        sakaarWormholeRim(c, Int(Double(c.w) * 0.18), st.top / 4, max(3, st.top / 9), C(0x5AE0C8))
        if c.w > 600 { sakaarWormholeRim(c, Int(Double(c.w) * 0.42), st.top / 5, max(3, st.top / 10), C(0xE05AE0)) }
        // junk mountains: a hazy far range and a rustier near one
        sakaarJunk(c, base: st.top + 2, hi: Double(st.top) * 0.55, seed: 3, C(0x7A6A80), bits: 0.04)
        sakaarWrecks(c, g, top: st.top)
        sakaarJunk(c, base: st.top + 2, hi: Double(st.top) * 0.32, seed: 7, C(0x4A3436), bits: 0.12)
        // the stands
        let stripe = [C(0xE04A8A), C(0x3AC8C0), C(0xF0C83A)]
        c.rect(0, st.top, c.w, st.wall - st.top, C(0x2A1E2A))
        for (j, y) in stride(from: st.top, to: st.wall, by: st.tier).enumerated() {
            c.rect(0, y + st.tier - s, c.w, s, lerp(C(0x4A3A4A), C(0x2A1E2A), Double(j) * 0.08))
            c.rect(0, y, c.w, st.tier - s, C(0x1E1620))
        }
        c.rect(0, st.top - 2 * s, c.w, 2 * s, C(0x5A4A5A)); c.rect(0, st.top - 2 * s, c.w, s, stripe[0])
        for x in stride(from: 0, to: c.w, by: 90 * s) {           // aisles
            c.rect(x + 40 * s, st.top, 4 * s, st.wall - st.top, C(0x3A2E3A))
        }
        if isTall(c) { sakaarHigh(c, g) }
        // the Grandmaster's box, jutting over the top tiers
        let bx = c.w / 2, by = st.top - 8 * s
        c.rect(bx - 16 * s, by, 32 * s, 18 * s, C(0x2A2240))
        c.rect(bx - 16 * s, by, 32 * s, 2 * s, C(0xE8B83A)); c.rect(bx - 16 * s, by + 16 * s, 32 * s, 2 * s, C(0xE8B83A))
        c.rect(bx - 14 * s, by + 3 * s, 28 * s, 12 * s, C(0x6A5AC8, 0.55))
        for x in stride(from: bx - 12 * s, to: bx + 12 * s, by: 6 * s) { c.rect(x, by + 3 * s, s, 12 * s, C(0xE8B83A, 0.6)) }
        c.rect(bx - 3 * s, by + 6 * s, 6 * s, 9 * s, C(0xE8B83A))            // his throne
        c.rect(bx - 2 * s, by + 8 * s, 4 * s, 3 * s, C(0x3A8AE0))
        c.rect(bx - 6 * s, by + 18 * s, 12 * s, st.wall - by - 18 * s, C(0x2A2240))
        // the arena wall, striped, with banners
        c.rect(0, st.wall, c.w, g - st.wall, C(0x3A2A36))
        for x in stride(from: 0, to: c.w, by: 12 * s) {
            for k in 0..<(g - st.wall) {
                let col = stripe[(x / (12 * s)) % 3]
                c.rect(x + k / 2, st.wall + k, 3 * s, 1, col.alpha(0.55))
            }
        }
        c.rect(0, st.wall, c.w, s, C(0xE8D8C0)); c.rect(0, g - 2 * s, c.w, 2 * s, C(0x241A22))
        for x in stride(from: 30 * s, to: c.w, by: 70 * s) {
            let col = stripe[(x / (70 * s)) % 3]
            c.rect(x, st.wall, 8 * s, 9 * s, col); c.rect(x + 3 * s, st.wall + 2 * s, 2 * s, 4 * s, C(0xFFFFFF, 0.8))
            c.rect(x, st.wall + 9 * s, 3 * s, s, col); c.rect(x + 5 * s, st.wall + 9 * s, 3 * s, s, col)
        }
        c.ground(g, C(0xB08A62), edge: C(0xD8B080), speck: C(0x9A7452), seed: 51)
        for i in 0..<max(3, c.w / 120) {                            // scraps in the sand
            let x = Int(noise(i * 3 + 200) * Double(c.w)), y = g + 3 * s + Int(noise(i * 3 + 201) * Double(max(1, c.h - g - 5 * s)))
            c.rect(x, y, 3 * s, s, C(0x6A5A5A)); c.px(x + s, y - 1, C(0x8A7A7A))
        }
    }

    /// Wrecks half-buried in the near heaps: a ship's hull, a great ring and girders.
    static func sakaarWrecks(_ c: PixelCanvas, _ g: Int, top: Int) {
        let s = unit(g), k = max(1, top / 40)
        for (i, x) in stride(from: 40 * s, to: c.w, by: 150 * s).enumerated() {
            let y = top - Int(Double(top) * 0.12)
            switch i % 3 {
            case 0:                                             // a ship's hull, nose up
                for d in 0..<(14 * k) { c.rect(x + d, y - d / 2, 6 * k, 3 * k, C(0x5A4A50)) }
                c.rect(x + 2 * k, y - 2 * k, 10 * k, k, C(0x9A8A8A))
                c.rect(x + 14 * k, y - 8 * k, 3 * k, 2 * k, C(0x6AC0D0))
            case 1:                                             // a great ring
                for a in stride(from: 0.0, to: 2 * .pi, by: 0.05) {
                    c.rect(x + Int(cos(a) * Double(9 * k)), y - 6 * k + Int(sin(a) * Double(9 * k)), 2 * k, 2 * k, C(0x6A5458))
                }
            default:                                            // girders
                for d in 0..<(16 * k) { c.rect(x + d / 3, y - d, 2 * k, k, C(0x5A4448)); c.rect(x + 8 * k - d / 4, y - d * 3 / 4, k, k, C(0x7A6064)) }
            }
        }
    }

    /// Up high: the arena's upper facade, banded in Sakaaran colours, with pylons carrying lamps and pennants.
    static func sakaarHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), st = sakaarStands(c, g), stripe = [C(0xE04A8A), C(0x3AC8C0), C(0xF0C83A)]
        let y0 = st.top - 22 * s
        c.rect(0, y0, c.w, 20 * s, C(0x2E2238))
        for x in stride(from: 0, to: c.w, by: 16 * s) {
            c.rect(x, y0 + 4 * s, 10 * s, 10 * s, stripe[(x / (16 * s)) % 3].alpha(0.35))
            c.rect(x + 2 * s, y0 + 6 * s, 6 * s, 6 * s, C(0x2E2238))
        }
        c.rect(0, y0, c.w, s, C(0xE8D8C0)); c.rect(0, y0 + 18 * s, c.w, 2 * s, C(0x1E1620))
        for (i, x) in stride(from: 60 * s, to: c.w, by: 160 * s).enumerated() {
            let ph = Int(Double(g) * 0.28)
            c.rect(x, y0 - ph, 6 * s, ph, C(0x3A2A44)); c.rect(x, y0 - ph, 2 * s, ph, C(0x5A4A64))
            c.rect(x - 4 * s, y0 - ph - 3 * s, 14 * s, 3 * s, C(0xE8B83A))
            c.circle(x + 3 * s, y0 - ph - 6 * s, 3 * s, C(0xFFF0C0)); c.circle(x + 3 * s, y0 - ph - 6 * s, 9 * s, C(0xFFE0A0, 0.12))
            let col = stripe[i % 3]
            c.rect(x + 6 * s, y0 - ph + 4 * s, 12 * s, 30 * s, col.alpha(0.85))
            c.rect(x + 9 * s, y0 - ph + 12 * s, 6 * s, 10 * s, C(0xFFFFFF, 0.5))
        }
    }

    /// The jagged profile of a junk heap range, with flecks of colourful scrap.
    static func sakaarJunk(_ c: PixelCanvas, base: Int, hi: Double, seed: Int, _ col: Px, bits: Double) {
        var x = 0, i = 0, prev = Double(base) - hi * noise(seed * 50)
        while x < c.w {
            let step = 6 + Int(noise(i * 3 + seed * 50) * 18)
            let next = Double(base) - hi * (0.25 + noise(i * 3 + 1 + seed * 50) * 0.75)
            for k in 0..<step {
                let top = Int(prev + (next - prev) * Double(k) / Double(step)) + Int(noise(x + k + seed) * 2)
                c.rect(x + k, top, 1, base - top, col)
                for y in stride(from: top + 2, to: base, by: 3) where noise((x + k) * 37 + y + seed) < bits {
                    c.px(x + k, y, [C(0xC86A3A), C(0x6AA0B0), C(0xD8C86A), C(0xB05A8A)][(x + y) % 4])
                }
            }
            prev = next; x += step; i += 1
        }
    }

    /// The still glow round a wormhole (its swirl turns in the animated layer).
    static func sakaarWormholeRim(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ col: Px) {
        c.circle(x, y, r * 3 / 2, col.alpha(0.08)); c.circle(x, y, r, col.alpha(0.14))
        c.circle(x, y, r * 2 / 3, col.alpha(0.2)); c.circle(x, y, max(1, r / 4), C(0x1A0A10))
    }

    /// A wormhole's arms, turned by `a`.
    static func sakaarSwirl(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ col: Px, _ a: Double) {
        for arm in 0..<3 {
            for i in 0..<(r * 4) {
                let u = Double(i) / Double(r * 4)
                let ang = a + Double(arm) * 2 * .pi / 3 + u * 4
                let rad = Double(r) * (0.2 + u * 0.95)
                let d = max(1, r / 14)
                c.rect(x + Int(cos(ang) * rad), y + Int(sin(ang) * rad * 0.8), d, d, lerp(C(0xFFF0C0), col, u).alpha(1 - u * 0.6))
            }
        }
    }

    /// The crowd bobbing and waving, and the wormholes turning.
    static func sakaarLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), st = sakaarStands(c, g)
        sakaarSwirl(c, Int(Double(c.w) * 0.7), st.top / 3, max(6, st.top / 4), C(0xFF5A2A), t * 0.6)
        sakaarSwirl(c, Int(Double(c.w) * 0.18), st.top / 4, max(3, st.top / 9), C(0x5AE0C8), -t * 0.9)
        if c.w > 600 { sakaarSwirl(c, Int(Double(c.w) * 0.42), st.top / 5, max(3, st.top / 10), C(0xE05AE0), t * 0.8) }
        let skins = [C(0xD89A7A), C(0x7AB06A), C(0x9A7AD0), C(0xE0C860), C(0x6A9AD0), C(0xC86A6A), C(0xE8E0D0), C(0x5AC8B0)]
        let bx = c.w / 2
        for (j, y) in stride(from: st.top, to: st.wall, by: st.tier).enumerated() {
            for (i, x) in stride(from: (j % 2) * s, to: c.w, by: 3 * s).enumerated() {
                if (abs(x - bx) < 17 * s && y < st.top + 10 * s) || abs(x - bx) < 7 * s || (x + 50 * s) % (90 * s) < 5 * s { continue }   // the box and the aisles
                let n = noise(i * 13 + j * 101)
                guard n > 0.12 else { continue }
                let up = sin(t * (5 + n * 4) + n * 20) > 0.55 ? s : 0
                let col = lerp(skins[Int(n * 97) % skins.count], C(0x2A1E2A), 0.25 + Double(j) * 0.02)
                c.rect(x, y + st.tier - 3 * s - up, 2 * s, s, col)
                c.rect(x, y + st.tier - 2 * s - up, 2 * s, s + up, col.alpha(0.55))
                if up > 0, n > 0.8 { c.rect(x + (n > 0.9 ? 2 * s : -s), y + st.tier - 5 * s, s, 2 * s, col) }
            }
        }
    }
}

// MARK: - Knowhere

extension Scenes {
    /// A neon sign: where it is, its size and its colour.
    struct KnowhereSign { let x, y, w, h: Int; let col: Px; let seed: Int }

    static func knowhereSigns(_ c: PixelCanvas, _ g: Int) -> [KnowhereSign] {
        let s = unit(g), cols = [C(0xFF4AA8), C(0x3AE8F0), C(0xFFB43A), C(0xA86AFF), C(0x6AF07A)]
        var out: [KnowhereSign] = []
        for (i, x) in stride(from: 14 * s, to: c.w - 12 * s, by: 52 * s).enumerated() {
            let w = (12 + Int(noise(i * 5 + 1) * 10)) * s, h = (5 + Int(noise(i * 5 + 2) * 3)) * s
            let y = g - 32 * s + Int(noise(i * 5 + 3) * 8.0) * s
            out.append(KnowhereSign(x: x + Int(noise(i * 5 + 4) * 14.0) * s, y: y, w: w, h: h, col: cols[i % cols.count], seed: i))
        }
        return out
    }

    /// Knowhere, the mining colony inside a dead Celestial's severed head: under the skull's bony vault, shanty
    /// dwellings pile up the cavern walls in ramshackle heaps of lit windows, an orange haze rises from the street
    /// below, and the grimy shopfronts the crew walks past are lit by flickering neon signs in alien script, with a
    /// mining pod crawling along its cable overhead.
    static func knowhere(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x0A0612), C(0x8A3A3A), bands: 8)
        if tall { knowhereHigh(c, g) }
        // the far heaps, the haze, the nearer heaps, more haze
        let far = Double(g) * (tall ? 0.5 : 0.78), near = Double(g) * (tall ? 0.32 : 0.6)
        knowhereHeap(c, g, base: g, hi: far, col: C(0x3A1E3A), win: C(0xFFA04A, 0.75), seed: 1, s: s)
        for k in 0..<4 { c.rect(0, g - Int(far * 0.5) + k * 5 * s, c.w, 5 * s, C(0xFF8A4A, 0.06)) }
        knowhereHeap(c, g, base: g, hi: near, col: C(0x22101E), win: C(0xFFB860, 0.9), seed: 2, s: s)
        for k in 0..<7 { c.rect(0, g - (k + 1) * 6 * s, c.w, 6 * s, C(0xFF7A3A, 0.05 + Double(6 - k) * 0.018)) }
        // pipes and the mining gantries
        let py = g - 46 * s
        if py > 8 * s {
            c.rect(0, py - 6 * s, c.w, 2 * s, C(0x3A2A34)); c.rect(0, py - 6 * s, c.w, s, C(0x7A5060))
            for x in stride(from: 30 * s, to: c.w, by: 140 * s) {
                c.rect(x, 0, 3 * s, py + 2 * s, C(0x2A1C28))
                c.rect(x - 8 * s, py, 20 * s, 3 * s, C(0x3A2A34)); c.rect(x - 8 * s, py, 20 * s, s, C(0x7A5060))
                c.rect(x + s, py + 3 * s, s, 6 * s, C(0x5A4A50))
                c.rect(x - s, py + 9 * s, 5 * s, 3 * s, C(0xC8A03A)); c.rect(x, py + 12 * s, 3 * s, s, C(0xFFE08A))
                c.circle(x + s, py + 13 * s, 7 * s, C(0xFFB050, 0.08))
            }
        }
        // street-level shopfronts, almost black against the glow
        var x = -4 * s, i = 0
        while x < c.w {
            let bw = (22 + Int(noise(i * 9 + 300) * 20)) * s, bh = (19 + Int(noise(i * 9 + 301) * 10)) * s
            let col = [C(0x1A0E18), C(0x201220), C(0x170C16)][i % 3]
            c.rect(x, g - bh, bw, bh, col)
            c.rect(x, g - bh, bw, s, C(0x4A2A3A))
            if noise(i * 9 + 302) > 0.5 { c.rect(x + 2 * s, g - bh - 3 * s, 3 * s, 3 * s, col); c.rect(x + 3 * s, g - bh - 6 * s, s, 3 * s, C(0x3A2A34)) }  // a chimney
            c.rect(x + 3 * s, g - 10 * s, 6 * s, 10 * s, C(0x0A050A))                // door
            c.rect(x + 3 * s, g - 10 * s, 6 * s, s, C(0xFF8A3A, 0.7))
            if bw > 30 * s {
                c.rect(x + 13 * s, g - 12 * s, 10 * s, 5 * s, C(0xFFA050, 0.6)); c.rect(x + 13 * s, g - 12 * s, 10 * s, s, C(0x0A050A))
                c.rect(x + 17 * s, g - 12 * s, s, 5 * s, C(0x0A050A))
            }
            for k in 0..<3 { c.rect(x + bw - 4 * s, g - bh + (2 + k * 4) * s, 2 * s, 2 * s, C(0x3A2A34)) }     // vents
            x += bw + 2 * s; i += 1
        }
        // cables sagging between the fronts
        for (k, x0) in stride(from: 0, to: c.w, by: 60 * s).enumerated() {
            let y0 = g - 30 * s + Int(noise(k + 40) * 4.0) * s
            for dx in 0..<(60 * s) { c.px(x0 + dx, y0 + Int(sin(Double(dx) / Double(60 * s) * .pi) * 5.0 * Double(s)), C(0x0A050A)) }
        }
        for sign in knowhereSigns(c, g) {                            // unlit sign boxes (the neon is in the animated layer)
            c.rect(sign.x - s, sign.y - s, sign.w + 2 * s, sign.h + 2 * s, C(0x0A050A))
            c.rect(sign.x + sign.w / 2, sign.y - 4 * s, s, 3 * s, C(0x3A2A34))
            knowhereGlyphs(c, sign, sign.col.alpha(0.25))
        }
        c.ground(g, C(0x2E2228), edge: C(0x8A5048), speck: C(0x22181C), seed: 61)
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x + Int(noise(x) * 10), g + 3 * s, 10 * s, s, C(0x261C20)) }   // grime
        for i in 0..<max(3, c.w / 80) {                              // puddles
            let x = Int(noise(i * 7 + 410) * Double(c.w)), y = g + 4 * s + Int(noise(i * 7 + 411) * Double(max(1, c.h - g - 6 * s)))
            c.ellipse(x, y, (5 + Int(noise(i) * 5)) * s, max(1, s), C(0x6A3A5A, 0.6))
        }
    }

    /// Ramshackle heaps of dwellings: columns of stacked boxes, piled higher here and lower there, with lit windows.
    static func knowhereHeap(_ c: PixelCanvas, _ g: Int, base: Int, hi: Double, col: Px, win: Px, seed: Int, s: Int) {
        var x = -3 * s, i = 0
        while x < c.w {
            let bw = (5 + Int(noise(i * 7 + seed * 300) * 7)) * s
            let env = 0.55 + 0.45 * sin(Double(x) / Double(70 * s) + Double(seed) * 2.1) * sin(Double(x) / Double(31 * s) + Double(seed))
            let h = Int(hi * (0.35 + env * 0.65) * (0.8 + noise(i * 7 + 1 + seed * 300) * 0.2))
            var y = base, k = 0
            while y > base - h {
                let bh = (4 + Int(noise(i * 13 + k * 3 + seed * 77) * 5)) * s
                let jog = Int((noise(i * 13 + k * 3 + 1 + seed * 77) - 0.5) * 3.0) * s
                c.rect(x + jog, y - bh, bw, bh, col)
                c.rect(x + jog, y - bh, bw, s, lerp(col, C(0xC86A5A), 0.25))
                if noise(i * 13 + k * 3 + 2 + seed * 77) > 0.45 {
                    c.rect(x + jog + s + Int(noise(i + k * 5 + seed) * Double(max(1, bw - 3 * s))), y - bh + 2 * s, max(1, s), max(1, s), win)
                }
                y -= bh; k += 1
            }
            if noise(i * 7 + 2 + seed * 300) > 0.8 { c.rect(x + bw / 2, y - 5 * s, s, 5 * s, col) }      // an antenna
            x += bw; i += 1
        }
    }

    /// A sign's alien lettering: blocky strokes and its tube border.
    static func knowhereGlyphs(_ c: PixelCanvas, _ sign: KnowhereSign, _ col: Px) {
        let s = max(1, sign.h / 6)
        c.rect(sign.x, sign.y, sign.w, 1, col); c.rect(sign.x, sign.y + sign.h - 1, sign.w, 1, col)
        c.rect(sign.x, sign.y, 1, sign.h, col); c.rect(sign.x + sign.w - 1, sign.y, 1, sign.h, col)
        for (k, gx) in stride(from: sign.x + 2 * s, to: sign.x + sign.w - 3 * s, by: 3 * s).enumerated() {
            let n = noise(sign.seed * 31 + k)
            c.rect(gx, sign.y + 2 * s, s, sign.h - 4 * s, col)
            c.rect(gx, n > 0.5 ? sign.y + 2 * s : sign.y + sign.h - 3 * s, 2 * s, s, col)
        }
    }

    /// Up high: the skull's vault (great ribs of bone arching across) and a rent in it open on to the stars, with
    /// light falling through.
    static func knowhereHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), vault = Int(Double(g) * 0.3)
        let hx = Int(Double(c.w) * 0.62), hy = Int(Double(g) * 0.13), hr = max(12, g / 10)
        // the vault itself, ragged along its lower edge
        for x in 0..<c.w {
            let bottom = vault + Int((sin(Double(x) * 0.07) * 0.5 + noise(x / 4 + 800) * 0.5) * Double(g) * 0.06)
            c.rect(x, 0, 1, bottom, C(0x170C18))
            c.px(x, bottom - 1, C(0x3A2030))
        }
        for (i, x) in stride(from: -20 * s, to: c.w + 40 * s, by: 90 * s).enumerated() {   // ribs
            let rw = (70 + Int(noise(i + 600) * 30)) * s, rh = vault + Int(noise(i + 601) * Double(g) * 0.1)
            for a in stride(from: 0.0, to: Double.pi, by: 0.004) {
                let px = x + Int(cos(a) * Double(rw) / 2) + rw / 2, py = Int(Double(rh) * (1 - sin(a)) * 0.9) + rh / 10
                c.rect(px, py, 4 * s, 4 * s, C(0x2A1828))
                c.px(px, py, C(0x4A2A3A))
            }
        }
        // the rent, with starlight
        c.ellipse(hx, hy, hr * 2, hr, C(0x05030C))
        for k in 0..<12 {
            let a = Double(k) / 12 * 2 * .pi
            c.circle(hx + Int(cos(a) * Double(hr) * 1.9), hy + Int(sin(a) * Double(hr) * 0.9), max(2, hr / 4), C(0x05030C))
        }
        c.stars(hy - hr, hy + hr, density: 10, seed: 17, x0: hx - hr * 2, x1: hx + hr * 2) { x, y in
            let dx = Double(x - hx) / Double(hr * 2), dy = Double(y - hy) / Double(hr)
            return dx * dx + dy * dy < 0.85
        }
        c.ellipse(hx - hr / 2, hy + hr / 3, hr / 2, hr / 4, C(0x8A4AD0, 0.3))
        for y in (hy + hr / 2)..<(g * 3 / 4) {                                        // a shaft of starlight
            let k = Double(y - hy) / Double(g)
            let half = hr + Int(k * Double(hr) * 2)
            c.rect(hx - half, y, half * 2, 1, C(0xB8A0FF, 0.035))
        }
    }

    /// The neon flickering and a mining pod crawling along its cable.
    static func knowhereLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        for sign in knowhereSigns(c, g) {
            let k = Int(t * 8) + sign.seed * 37
            let on = noise(k) > (sign.seed % 3 == 0 ? 0.25 : 0.06)
            guard on else { continue }
            c.rect(sign.x - 2 * s, sign.y - 2 * s, sign.w + 4 * s, sign.h + 4 * s, sign.col.alpha(0.12))
            c.rect(sign.x - 4 * s, sign.y - 4 * s, sign.w + 8 * s, sign.h + 8 * s, sign.col.alpha(0.06))
            knowhereGlyphs(c, sign, sign.col)
            c.ellipse(sign.x + sign.w / 2, g + 2 * s, sign.w / 2, max(1, s), sign.col.alpha(0.2))   // its glow on the street
        }
        let py = g - 54 * s
        guard py > 4 else { return }
        let span = Double(c.w + 40 * s), x = Int((t * 12 * Double(s)).truncatingRemainder(dividingBy: span)) - 20 * s
        c.rect(0, py, c.w, max(1, s / 2), C(0x0A050A))
        c.rect(x + 3 * s, py, s, 3 * s, C(0x3A2C38))
        c.rect(x, py + 3 * s, 8 * s, 5 * s, C(0x5A4A50)); c.rect(x, py + 3 * s, 8 * s, s, C(0x9A8A8A))
        c.rect(x + 2 * s, py + 5 * s, 2 * s, s, C(0xFFC86A))
        if scenes1Phase(t, 1.2) < 0.5 { c.rect(x + 7 * s, py + 7 * s, s, s, C(0xFF4A4A)) }
    }
}

// MARK: - Titan

extension Scenes {
    /// The ring of debris overhead: centre and radii of its ellipse, and how thick the band is.
    static func titanRing(_ c: PixelCanvas, _ g: Int) -> (x: Double, y: Double, rx: Double, ry: Double, band: Double) {
        isTall(c) ? (Double(c.w) * 0.55, Double(g) * 0.0, Double(c.w) * 0.8, Double(g) * 0.42, Double(g) * 0.12)
            : (Double(c.w) * 0.55, -Double(g) * 0.5, Double(c.w) * 0.8, Double(g) * 0.85, Double(g) * 0.16)
    }

    /// Titan, Thanos' ruined homeworld: a dusty orange sky with a cracked moon, a great band of debris arcing overhead,
    /// a hazy dead city and a broken ring-structure on the horizon, and huge tilted spires, snapped off, collared,
    /// leaning on one another, over a cracked plain strewn with rubble.
    static func titan(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x7A2C18), C(0xF4A852), bands: 7)
        c.ellipse(Int(Double(c.w) * 0.62), g, c.w / 3, g / 2, C(0xFFD08A, 0.10))
        // the cracked moon, a chunk breaking away
        let mx = Int(Double(c.w) * 0.16), my = Int(Double(g) * (tall ? 0.3 : 0.32)), mr = max(6, g / 7)
        c.circle(mx, my, mr + 2 * s, C(0xF0B070, 0.15))
        c.circle(mx, my, mr, C(0xC07448))
        c.circle(mx - mr / 4, my - mr / 4, mr * 2 / 3, C(0xD08858))
        c.circle(mx + mr / 3, my + mr / 3, max(1, mr / 5), C(0xA8603A))
        var cx = Double(mx + mr / 4)
        for y in (my - mr)...(my + mr) {                         // the crack
            cx += (noise(y + 333) - 0.5) * 1.6
            let dx = Int(cx) - mx, dy = y - my
            if dx * dx + dy * dy <= mr * mr { c.rect(Int(cx), y, max(1, mr / 8), 1, C(0x6A2A18)) }
        }
        for k in 0..<4 {
            c.circle(mx + mr + (k * 5 + 4) * s, my - (k * 2 + 2) * s, max(1, (4 - k) * s / 2 + s / 2), C(0xB06A40))
        }
        titanDebris(c, g, n: c.w * (tall ? 4 : 2), seed: 0, col: C(0x5A2216, 0.85), lit: C(0xD88A5A, 0.85))
        if tall { titanHigh(c, g) }
        // the dead city in the haze, and a broken ring-structure standing on the horizon
        let hz = C(0xC8703F)
        for (i, x) in stride(from: 0, to: c.w, by: 9 * s).enumerated() {
            let h = Int(Double(g) * (0.08 + noise(i * 4 + 80) * 0.14) * (noise(i * 4 + 85) > 0.85 ? 2.2 : 1))
            titanSpire(c, x: x, base: g - 6 * s, h: h, w: (5 + Int(noise(i * 4 + 82) * 4)) * s,
                       tilt: (noise(i * 4 + 83) - 0.5) * 0.3, curve: 0, hz, edge: C(0xE08A52), seed: i)
        }
        let rx = Int(Double(c.w) * 0.78), rr = max(10, Int(Double(g) * 0.3))
        for k in 0..<360 where !(k > 200 && k < 250) {
            let a = Double(k) * .pi / 180
            let x = rx + Int(cos(a) * Double(rr) * 0.55), y = g - 6 * s - rr + Int(sin(a) * Double(rr))
            let px = x + Int(Double(y - (g - rr)) * 0.25)
            let th = max(3 * s, rr / 12)
            c.rect(px, y, th, th, C(0xB0603A)); c.rect(px, y, th, max(1, th / 3), C(0xE0904F))
        }
        c.dunes(base: g - 7 * s, amp: 3, freq: 0.03, phase: 0.4, bottom: g, C(0xA85432))
        // the great near spires
        for (i, x) in stride(from: 24 * s, to: c.w, by: 96 * s).enumerated() {
            let h = Int(Double(g) * (tall ? 0.45 + noise(i * 4 + 90) * 0.4 : 0.7 + noise(i * 4 + 90) * 0.45))
            let dir = noise(i * 4 + 91) > 0.5 ? 1.0 : -1.0
            titanSpire(c, x: x + Int(noise(i * 4 + 93) * 40.0) * s, base: g, h: h, w: max(10, g / 14) + Int(noise(i * 4 + 94) * 6) * s,
                       tilt: dir * (0.12 + noise(i * 4 + 92) * 0.2), curve: dir * 0.15, C(0x42180F), edge: C(0xC06A3C), seed: i + 50)
        }
        c.dunes(base: g - 3 * s, amp: 2, freq: 0.06, phase: 2, bottom: g, C(0x8A3A22))
        // a fallen ring half buried, and rubble
        let fx = Int(Double(c.w) * 0.42)
        c.ellipse(fx, g - 3 * s, 16 * s, 9 * s, C(0x4A1C12))
        c.ellipse(fx, g - 3 * s, 12 * s, 6 * s, C(0xD08850))
        c.ellipse(fx, g - 3 * s, 11 * s, 5 * s, C(0xB8683C))
        c.rect(fx - 18 * s, g - 2 * s, 36 * s, 2 * s, C(0x8A3A22))
        for i in 0..<max(4, c.w / 50) {
            let x = Int(noise(i * 5 + 150) * Double(c.w)), r = (1 + Int(noise(i * 5 + 151) * 3)) * s
            c.ellipse(x, g - r / 2, r + s, r, C(0x4A1C12)); c.px(x - r / 2, g - r, C(0xB0603A))
        }
        c.ground(g, C(0x7A3420), edge: C(0xB8603A), speck: C(0x5E2618), seed: 71)
        for i in 0..<max(3, c.w / 70) {                       // cracks in the plain
            var x = Int(noise(i * 7 + 160) * Double(c.w)), y = g + 2 * s
            while y < c.h - s { c.px(x, y, C(0x4A1A10)); x += noise(x + y * 3) > 0.5 ? 1 : -1; y += 1; c.px(x, y, C(0x4A1A10)); x += 1 }
        }
    }

    /// Rocks scattered through the band of the debris ring.
    static func titanDebris(_ c: PixelCanvas, _ g: Int, n: Int, seed: Int, col: Px, lit: Px) {
        let s = unit(g), ring = titanRing(c, g)
        for i in 0..<n {
            let a = noise(i * 3 + seed * 1000 + 1) * 2 * .pi
            let off = (noise(i * 3 + seed * 1000 + 2) - 0.5) * ring.band * (0.5 + noise(i * 7) * 0.8)
            let x = Int(ring.x + cos(a) * (ring.rx + off * 2)), y = Int(ring.y + sin(a) * (ring.ry + off))
            guard y > 0, y < g - 26 * s, x > -6, x < c.w + 6 else { continue }
            let r = (noise(i * 3 + seed * 1000 + 3) > 0.9 ? 3 : noise(i * 5 + seed) > 0.6 ? 2 : 1) * s
            c.rect(x, y, r, r, col)
            c.rect(x, y, r, max(1, r / 2), lit)
        }
    }

    /// One ruined spire: a leaning, bending shaft, tapering, with collars and window slots, snapped off jaggedly.
    static func titanSpire(_ c: PixelCanvas, x: Int, base: Int, h: Int, w: Int, tilt: Double, curve: Double, _ col: Px,
                           edge: Px, seed: Int) {
        guard h > 4 else { return }
        let off = { (dy: Int) -> Int in Int(Double(dy) * tilt + curve * Double(dy * dy) / Double(h)) }
        let wid = { (dy: Int) -> Int in max(2, w - dy * w * 3 / (h * 5)) }
        let snap = max(4, h / 10)
        for dy in 0..<h {
            let wdt = wid(dy)
            var l = 0, r = wdt
            if dy > h - snap {                                                  // the broken top
                let cut = Double(dy - (h - snap)) / Double(snap)
                if noise(seed * 13 + 1) > 0.5 { l = Int(cut * Double(wdt)) } else { r = wdt - Int(cut * Double(wdt)) }
                l += Int(noise(seed * 17 + dy) * 2); if r <= l { continue }
            }
            let y = base - dy, x0 = x + off(dy)
            c.rect(x0 + l, y, r - l, 1, col)
            let litSide = tilt > 0 ? x0 + r - 1 : x0 + l
            c.px(litSide, y, edge)
            if r - l > 5, dy % 9 < 4, (dy / 9) % 2 == 1 { c.px(x0 + wdt / 2, y, lerp(col, C(0x000000), 0.4)) }   // window slots
        }
        for k in [h / 4, h / 2] where k < h - snap {                            // collars
            let wdt = wid(k), x0 = x + off(k)
            c.rect(x0 - 2, base - k - 1, wdt + 4, 3, col)
            c.rect(x0 - 2, base - k - 1, wdt + 4, 1, edge)
        }
    }

    /// Up high: dust banks and a nearer arc of bigger debris.
    static func titanHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<6 {
            wisp(c, Int(noise(i * 5 + 170) * Double(c.w)), Int(Double(g) * (0.4 + noise(i * 5 + 171) * 0.25)),
                 (50 + Int(noise(i * 5 + 172) * 70)) * s, C(0xF8B878, 0.22), s: 2 * s)
        }
        titanDebris(c, g, n: c.w, seed: 4, col: C(0x4A1A10), lit: C(0xE89A62))
        let n = max(3, c.w / 140)
        for i in 0..<n {                                                         // great boulders adrift up high
            let x = c.w * i / n + Int(noise(i * 5 + 180) * Double(c.w / n))
            let y = Int(Double(g) * (0.05 + noise(i * 5 + 181) * 0.14))
            let r = (6 + Int(noise(i * 5 + 182) * 10)) * s
            c.ellipse(x - s, y - s, r, r * 2 / 3, C(0xD8844E))                  // sunlit edge, then the rock
            c.ellipse(x + r / 2 - s, y + r / 4 - s, r / 2, r / 3, C(0xD8844E))
            c.ellipse(x, y, r, r * 2 / 3, C(0x4A1A10))
            c.ellipse(x + r / 2, y + r / 4, r / 2, r / 3, C(0x4A1A10))
            c.ellipse(x - r / 4, y - r / 5, r / 2, r / 4, C(0x5E2416))
        }
    }

    /// Chunks of the debris ring drifting slowly round, and dust blowing across the plain.
    static func titanLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), ring = titanRing(c, g)
        for i in 0..<max(12, c.w / 12) {
            let a = noise(i * 3 + 300) * 2 * .pi + t * (0.004 + noise(i * 3 + 301) * 0.006)
            let off = (noise(i * 3 + 302) - 0.5) * ring.band
            let x = Int(ring.x + cos(a) * (ring.rx + off * 2)), y = Int(ring.y + sin(a) * (ring.ry + off))
            guard y > 0, y < g - 26 * s else { continue }
            let r = (2 + Int(noise(i * 5 + 303) * 3)) * s
            c.rect(x - r / 2, y - r / 2, r, max(1, r * 2 / 3), C(0x4A1A10))
            c.rect(x - r / 2, y - r / 2, r, max(1, s), C(0xE89A62))
        }
        for i in 0..<max(6, c.w / 40) {
            let span = Double(c.w + 20)
            let x = Int((noise(i * 7 + 310) * span + t * (14 + noise(i * 7 + 311) * 10) * Double(s)).truncatingRemainder(dividingBy: span)) - 10
            let y = g - Int(noise(i * 7 + 312) * 14.0) * s - Int(sin(t * 2 + Double(i)) * 1.5)
            c.rect(x, y, 2 * s, max(1, s), C(0xF0B070, 0.35))
        }
    }
}
