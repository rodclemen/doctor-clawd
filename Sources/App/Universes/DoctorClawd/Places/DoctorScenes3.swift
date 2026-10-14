import Foundation

let doctorScenes3: [Location: Place] = [
    .trenzalore: Place(name: "Trenzalore", panel: 0x12161C, still: Scenes.trenzalore, moving: Scenes.trenzaloreLife),
    .theLibrary: Place(name: "The Library", panel: 0x1A120C, still: Scenes.theLibrary, moving: Scenes.theLibraryLife),
    .satelliteFive: Place(name: "Satellite Five", panel: 0x0E141E, still: Scenes.satelliteFive, moving: Scenes.satelliteFiveLife),
    .newEarth: Place(name: "New Earth", panel: 0x142030, still: Scenes.newEarth, moving: Scenes.newEarthLife),
    .starshipUK: Place(name: "Starship UK", panel: 0x10121C, still: Scenes.starshipUK, moving: Scenes.starshipUKLife),
    .pompeii: Place(name: "Pompeii", panel: 0x22140E, still: Scenes.pompeii, moving: Scenes.pompeiiLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// `v` wrapped into 0..<span, for things that drift off one side and come back on the other.
    static func doctorScenes3Wrap(_ v: Double, _ span: Double) -> Double {
        guard span > 0 else { return 0 }
        let r = v.truncatingRemainder(dividingBy: span)
        return r < 0 ? r + span : r
    }
}

// MARK: - Trenzalore

extension Scenes {
    /// The giant police box on the hill: its left edge, width, roof top (the lamp sits above) and the row it stands on.
    static func trenzaloreBox(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int, base: Int) {
        let tall = isTall(c)
        let base = tall ? g - g / 7 : g - 4 * unit(g)
        let h = tall ? g * 11 / 20 : base - 5
        let w = h * 54 / 100
        return (Int(Double(c.w) * 0.62) - w / 2, w, base - h, base)
    }

    /// The row the graveyard hill's crest runs along.
    static func trenzaloreHill(_ c: PixelCanvas, _ g: Int) -> Int {
        isTall(c) ? trenzaloreBox(c, g).base + 3 * unit(g) : g - 14 * unit(g)
    }

    /// Trenzalore: a misty night hillside of crooked headstones and crosses under a pale moon, with a bare tree
    /// clawing at the sky. Behind it all looms the police box grown to the size of a tower, its blue gone grey in
    /// the mist, its windows dark, ivy climbing its panels and moss on its roof. On the screen saver it towers.
    static func trenzalore(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), b = trenzaloreBox(c, g), hill = trenzaloreHill(c, g)
        c.gradient(0, g, C(0x0A0E16), C(0x323C46), bands: 8)
        c.stars(0, g / 2, density: tall ? 70 : 50, seed: 3)
        // the moon behind a veil of cloud
        let mx = c.w / 5, my = tall ? g / 6 : 12 * s, mr = tall ? 14 * s : 5 * s
        c.circle(mx, my, mr * 3, C(0xC8D4DC, 0.05))
        c.circle(mx, my, mr * 2, C(0xC8D4DC, 0.07))
        c.circle(mx, my, mr, C(0xD8DCD0))
        c.circle(mx - mr / 3, my - mr / 4, max(1, mr / 4), C(0xB8BCB0))
        c.circle(mx + mr / 3, my + mr / 3, max(1, mr / 5), C(0xB8BCB0))
        wisp(c, mx + 4 * s, my + mr / 2, mr * 4, C(0x3A4450, 0.8), s: s)
        if tall {
            for i in 0..<6 {
                let x = Int(noise(i * 5 + 300) * Double(c.w)), y = Int(noise(i * 5 + 301) * Double(g) * 0.45)
                wisp(c, x, y, (30 + Int(noise(i * 5 + 302) * 40)) * s, C(0x404A56, 0.55), s: s)
            }
        }
        // far hills, then the box on its hill
        c.dunes(base: hill - (b.base - b.top) / 7, amp: Double(3 * s), freq: 0.02 / Double(s), phase: 1, bottom: g, C(0x1E2630))
        trenzaloreDrawBox(c, b, s)
        // the mist that greys out everything far away
        let m0 = b.top + (hill - b.top) / 3
        for y in m0..<g { c.rect(0, y, c.w, 1, C(0x8090A0, 0.28 * Double(y - m0) / Double(max(1, g - m0)))) }
        // the graveyard hill
        c.dunes(base: hill, amp: Double(2 * s), freq: 0.03 / Double(s), phase: 4, bottom: g,
                C(0x1C2620), shade: C(0x34423A))
        trenzaloreTree(c, c.w / 12, hill + 2 * s, tall ? g / 3 : 34 * s, s)
        var row = 0
        for y in stride(from: hill + 4 * s, through: g, by: 5 * s) {
            let k = Double(y - hill) / Double(max(1, g - hill))
            let sw = Int((3 + k * 3).rounded()) * s, sh = Int((4 + k * 5).rounded()) * s
            let fade = 0.55 + k * 0.45
            var x = Int(noise(row * 17 + 310) * 20) * s
            var i = 0
            while x < c.w {
                let n = row * 101 + i
                let lean = Int((noise(n * 3 + 320) - 0.5) * 4) * s
                let kind = Int(noise(n * 3 + 321) * 4)
                trenzaloreStone(c, x, y, sw, sh, lean: lean, kind: kind, fade: fade, s: s)
                x += (12 + Int(noise(n * 3 + 322) * 14) + Int(k * 10)) * s
                i += 1
            }
            row += 1
        }
        c.ground(g, C(0x1A2420), edge: C(0x34443A), speck: C(0x121A16), seed: 31)
        for i in 0..<(c.w / (5 * s)) {                     // tufts of long grass along the edge
            let x = Int(noise(i * 7 + 330) * Double(c.w))
            c.rect(x, g - s, s, s, C(0x2E3E30))
            if noise(i * 7 + 331) > 0.5 { c.rect(x + s, g - 2 * s, s, 2 * s, C(0x26342A)) }
        }
    }

    /// The overgrown police box at `b`, drawn on its own grid of units so it keeps its shape at any size.
    static func trenzaloreDrawBox(_ c: PixelCanvas, _ b: (x: Int, w: Int, top: Int, base: Int), _ s: Int) {
        let u = max(1, b.w / 22), x = b.x, top = b.top, h = b.base - b.top + 8 * s
        let blue = C(0x22364E), dark = C(0x162438), lit = C(0x304A66), glass = C(0x4E6274)
        let r = { (a: Int, v: Int, w: Int, hh: Int, col: Px) in c.rect(x + a * u, top + v * u, w * u, hh * u, col) }
        // the lamp and the stepped roof
        r(10, -3, 2, 1, dark); r(10, -2, 2, 2, C(0x8A9EAC)); r(9, 0, 4, 1, dark)
        r(2, 1, 18, 2, blue); r(2, 1, 18, 1, lit)
        r(1, 3, 20, 2, blue); r(1, 3, 20, 1, lit)
        // the sign band, its letters long since faded
        r(1, 5, 20, 3, C(0x0E1622))
        for k in stride(from: 3, to: 19, by: 2) where noise(k + b.w) > 0.3 { r(k, 6, 1, 1, C(0x5A6A78, 0.7)) }
        // the corner posts and the doors
        c.rect(x, top + 8 * u, b.w, h - 8 * u, blue)
        r(0, 8, 2, (h / u) - 8, lit); r(20, 8, 2, (h / u) - 8, dark)
        r(10, 8, 2, (h / u) - 8, dark)
        let ph = max(2, (h / u - 11) / 4)
        for (d, dx) in [3, 13].enumerated() {
            for row in 0..<4 {
                let py = 9 + row * ph
                if row == 0 {                              // the windows, black and lifeless
                    r(dx, py, 6, ph - 1, glass)
                    r(dx + 2, py, 1, ph - 1, dark); r(dx + 4, py, 1, ph - 1, dark)
                    r(dx, py + (ph - 1) / 2, 6, 1, dark)
                } else {
                    r(dx, py, 6, ph - 1, dark)
                    r(dx, py, 6, 1, C(0x1A2A3E))
                    r(dx + 5, py, 1, ph - 1, lit.alpha(0.6))
                }
                if d == 0, row == 1, ph > 3 { r(dx + 1, py + 1, 4, 2, C(0x6A7A88, 0.6)) }   // the notice panel
            }
        }
        // a crack down one door
        var cx = x + 15 * u, cy = top + 12 * u
        while cy < b.base - 4 * u {
            c.rect(cx, cy, s, 2 * s, C(0x0A121C))
            cx += noise(cx * 7 + cy) > 0.5 ? s : -s
            cy += 2 * s
        }
        // moss on the roof and ivy climbing the panels
        c.ellipse(x + 6 * u, top + 2 * u, 4 * u, u, C(0x3A5232))
        c.ellipse(x + 16 * u, top + 4 * u, 3 * u, u, C(0x34502E))
        for i in 0..<max(6, b.w / (2 * s)) {
            var vx = x + Int(noise(i * 7 + 340) * Double(b.w)), vy = top + 3 * u + Int(noise(i * 7 + 341) * Double(h) * 0.6)
            let vine = noise(i * 7 + 342) > 0.5 ? C(0x2A4628) : C(0x22381F)
            while vy < b.base + 6 * s {
                c.rect(vx, vy, s, s, vine)
                if noise(vx * 13 + vy * 3) > 0.8 { c.rect(vx - s, vy, 2 * s, 2 * s, C(0x3A5E34)) }
                vx += noise(vx * 3 + vy * 11 + i) > 0.5 ? s : -s
                vx = max(x - s, min(x + b.w, vx))
                vy += s
            }
        }
    }

    /// A headstone `w`×`h` standing on row `base`, leaning `lean` pixels at the top: a rounded slab, a cross, a
    /// pointed obelisk or a broken stump. `fade` dims the far ones into the mist.
    static func trenzaloreStone(_ c: PixelCanvas, _ x: Int, _ base: Int, _ w: Int, _ h: Int, lean: Int, kind: Int,
                                fade: Double, s: Int) {
        let stone = lerp(C(0x56606A), C(0x7A848A), fade), lit = lerp(C(0x6A747C), C(0xA4ACB0), fade)
        let shade = lerp(C(0x3A424A), C(0x4A5258), fade)
        let hh = kind == 3 ? h * 3 / 5 : h
        for r in stride(from: 0, to: hh, by: s) {
            let y = base - hh + r, off = lean * (hh - r) / max(1, hh)
            var x0 = x + off, ww = w
            switch kind {
            case 1:                                        // a cross
                let arm = r >= hh / 5 && r < hh / 5 + max(s, w / 3)
                if !arm { x0 += w / 3; ww = max(s, w / 3) }
            case 2:                                        // an obelisk, pointed
                let k = min(1, Double(r) / Double(max(1, hh / 3)))
                let half = Int(Double(w) / 2 * k)
                x0 += w / 2 - half; ww = max(s, half * 2)
            case 3:                                        // a broken stump, jagged on top
                if r == 0 { ww = w / 2 }
            default:                                       // a slab with a rounded top
                if r == 0, w > 2 * s { x0 += s; ww -= 2 * s }
            }
            c.rect(x0, y, ww, s, stone)
            c.rect(x0, y, s, s, lit)
            c.rect(x0 + ww - s, y, s, s, shade)
        }
        c.rect(x - s, base - s, w + 2 * s, s, C(0x22302A))   // grass round its foot
    }

    /// A bare, crooked tree `h` tall with its roots at (x, base).
    static func trenzaloreTree(_ c: PixelCanvas, _ x: Int, _ base: Int, _ h: Int, _ s: Int) {
        let bark = C(0x161C1E)
        var tx = x
        for y in stride(from: base, to: base - h, by: -s) {
            let k = Double(base - y) / Double(h)
            c.rect(tx, y, max(s, Int((1 - k) * 4) * s), s, bark)
            if noise(y * 3 + x) > 0.75 { tx += s }
        }
        for i in 0..<6 {                                   // branches, reaching out and up
            var bx = x + s, by = base - h / 3 - Int(noise(i * 5 + 350) * Double(h) * 0.6)
            let dir = i % 2 == 0 ? 1 : -1
            for _ in 0..<(h / (4 * s) + Int(noise(i * 5 + 351) * Double(h / (4 * s)))) {
                c.rect(bx, by, s, s, bark)
                bx += dir * s
                if noise(bx * 7 + by) > 0.45 { by -= s }
            }
        }
    }

    /// What moves on Trenzalore: banks of mist drifting along the hillside, and the box's lamp glowing faintly.
    static func trenzaloreLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), b = trenzaloreBox(c, g)
        let n = max(5, c.w / 60) * (tall ? 2 : 1)
        let lo = b.top + (trenzaloreHill(c, g) - b.top) / 2
        for i in 0..<n {
            let rx = Double((26 + Int(noise(i * 5 + 400) * 34)) * s)
            let speed = (2 + noise(i * 5 + 401) * 5) * Double(s) * (i % 3 == 0 ? -0.7 : 1)
            let span = Double(c.w) + rx * 2
            let x = Int(doctorScenes3Wrap(noise(i * 5 + 402) * span + t * speed, span) - rx)
            let y = lo + Int(noise(i * 5 + 403) * Double(c.h - lo))
            let ry = (2 + Int(noise(i * 5 + 404) * 3)) * s
            c.ellipse(x, y, Int(rx), ry, C(0xA8B6C0, 0.10 + noise(i * 5 + 405) * 0.08))
            c.ellipse(x + Int(rx) / 3, y - ry / 2, Int(rx) / 2, max(1, ry / 2), C(0xC8D2D8, 0.08))
        }
        let u = max(1, b.w / 22), pulse = 0.5 + 0.5 * sin(t * 1.4)
        c.circle(b.x + b.w / 2, b.top - 2 * u, 3 * u, C(0xB8D8F0, 0.06 + 0.10 * pulse))
        c.rect(b.x + 10 * u, b.top - 2 * u, 2 * u, 2 * u, C(0xD8ECF8, 0.25 * pulse))
    }
}

// MARK: - The Library

extension Scenes {
    /// The reading tables along the stacks: the centre of each.
    static func theLibraryTables(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = unit(g)
        return Array(stride(from: 56 * s, to: c.w - 10 * s, by: 132 * s))
    }

    /// The Library: a library the size of a planet. Bookshelves crammed with spines of every colour run along the
    /// wall and on up into the dark for ever, split into bays by carved uprights. Reading tables with green-shaded
    /// lamps throw warm pools of light on a polished wooden floor. On the screen saver the stacks climb past a
    /// gallery hung with glowing globes.
    static func theLibrary(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.rect(0, 0, c.w, g, C(0x120A06))
        let shelfH = 10 * s, bayW = 46 * s
        let books = [C(0x7A2A22), C(0x2A4A32), C(0x24345A), C(0x8A6A2A), C(0x5A3A2A), C(0xB8A880), C(0x4A2A4A), C(0x6A4A1E)]
        var row = 0
        for base in stride(from: g - 3 * s, to: -shelfH, by: -shelfH) {
            c.rect(0, base - shelfH + s, c.w, shelfH - s, C(0x1E120A))      // the dark back of the shelf
            var x = 0, i = row * 997
            while x < c.w {
                let bw = (1 + Int(noise(i * 3) * 3)) * s
                if noise(i * 3 + 1) > 0.93 { x += 3 * s; i += 1; continue }    // a gap where a book's been taken
                let bh = (5 + Int(noise(i * 3 + 2) * 4)) * s
                let col = books[Int(noise(i * 3 + 5) * Double(books.count))]
                c.rect(x, base - bh, bw, bh, col)
                c.rect(x + bw - s, base - bh, s, bh, C(0x000000, 0.25))
                if bw >= 2 * s { c.rect(x, base - bh + 2 * s, bw - s, s, C(0xD8B45A, 0.55)) }  // gilt band
                x += bw
                i += 1
            }
            c.rect(0, base, c.w, s, C(0x7A5030))
            c.rect(0, base + s, c.w, s, C(0x3A2414))
            row += 1
        }
        for x in stride(from: 0, to: c.w, by: bayW) {      // the carved uprights between the bays
            c.rect(x, 0, 4 * s, g, C(0x4A2E1A))
            c.rect(x, 0, s, g, C(0x7A5232))
            c.rect(x + 3 * s, 0, s, g, C(0x2A180C))
            for y in stride(from: g - 3 * s, to: 0, by: -shelfH) { c.rect(x - s, y - s, 6 * s, s, C(0x8A6038)) }
        }
        if tall {
            // the gallery: a walkway with a balustrade halfway up, and globe lamps hanging from it
            let gy = g / 2
            c.rect(0, gy, c.w, 4 * s, C(0x3A2214)); c.rect(0, gy, c.w, s, C(0x8A6038))
            c.rect(0, gy - 9 * s, c.w, 2 * s, C(0x6A4428))
            for x in stride(from: 0, to: c.w, by: 5 * s) {
                c.rect(x + s, gy - 7 * s, 2 * s, 7 * s, C(0x5A3A22))
                c.rect(x + s, gy - 5 * s, 3 * s, 2 * s, C(0x5A3A22))
            }
            for x in stride(from: 30 * s, to: c.w, by: 90 * s) {
                c.rect(x, gy + 4 * s, s, 14 * s, C(0x2A1A10))
                c.circle(x, gy + 21 * s, 16 * s, C(0xFFD27A, 0.06))
                c.circle(x, gy + 21 * s, 4 * s, C(0xFFE8B0))
                c.circle(x - s, gy + 20 * s, s, white)
            }
        }
        // the stacks fade into the dark the higher they go
        for y in 0..<g {
            let k = 1 - Double(y) / Double(g)
            c.rect(0, y, c.w, 1, C(0x080402, (tall ? 0.7 : 0.45) * k * k))
        }
        // the floor
        c.ground(g, C(0x3A2416), edge: C(0x7A5232), speck: C(0x2A180E), seed: 41)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x22140A, 0.6)) }
        // the reading tables and their lamps
        for cx in theLibraryTables(c, g) {
            c.ellipse(cx, g + 3 * s, 20 * s, 2 * s, C(0xFFD27A, 0.10))       // the shine on the floor
            c.circle(cx, g - 15 * s, 22 * s, C(0xFFD27A, 0.06))
            c.circle(cx, g - 15 * s, 12 * s, C(0xFFD27A, 0.08))
            c.rect(cx - 14 * s, g - 11 * s, 28 * s, 2 * s, C(0x6A3E22))
            c.rect(cx - 14 * s, g - 11 * s, 28 * s, s, C(0x9A6A3A))
            c.rect(cx - 13 * s, g - 9 * s, 26 * s, 2 * s, C(0x4A2A16))
            c.rect(cx - 13 * s, g - 9 * s, 2 * s, 9 * s, C(0x4A2A16)); c.rect(cx + 11 * s, g - 9 * s, 2 * s, 9 * s, C(0x4A2A16))
            // a stack of books and an open one
            c.rect(cx + 6 * s, g - 13 * s, 6 * s, 2 * s, C(0x7A2A22)); c.rect(cx + 7 * s, g - 15 * s, 5 * s, 2 * s, C(0x24345A))
            c.rect(cx - 11 * s, g - 12 * s, 7 * s, s, C(0xE8DCC0)); c.rect(cx - 8 * s, g - 12 * s, s, s, C(0xA89A80))
            // the lamp: brass base and stem, green glass shade, warm light beneath
            c.rect(cx - 2 * s, g - 12 * s, 4 * s, s, C(0xB8902A))
            c.rect(cx, g - 16 * s, s, 4 * s, C(0xB8902A))
            c.rect(cx - 4 * s, g - 18 * s, 9 * s, 2 * s, C(0x2A7A44))
            c.rect(cx - 3 * s, g - 19 * s, 7 * s, s, C(0x4AAA6A))
            c.rect(cx - 3 * s, g - 16 * s, 7 * s, s, C(0xFFE8A0))
        }
    }

    /// What moves in the Library: shadows that creep along the floor and up the foot of the shelves, reaching ahead
    /// with long fingers, and the lamps that dim as they pass.
    static func theLibraryLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        let n = max(2, c.w / 170)
        var xs: [Int] = []
        for i in 0..<n {
            let span = Double(c.w + 90 * s)
            let speed = (4 + noise(i * 7 + 600) * 4) * Double(s)
            let dir = i % 2 == 0 ? 1 : -1
            let x = Int(doctorScenes3Wrap(noise(i * 7 + 601) * span + Double(dir) * t * speed, span)) - 45 * s
            xs.append(x)
            let fy = g + 3 * s
            c.ellipse(x, fy, 24 * s, 3 * s, C(0x000000, 0.45))
            for k in 0..<5 {
                let lx = x + (k - 2) * 9 * s + Int(sin(t * 1.3 + Double(k + i)) * 2 * Double(s))
                c.ellipse(lx, fy - s, 6 * s, 2 * s + Int((sin(t * 2 + Double(k)) * 0.5 + 0.5) * Double(s)), C(0x000000, 0.3))
            }
            // up the shelves behind it
            let up = tall ? 12 * s : 5 * s
            c.ellipse(x - dir * 4 * s, g - up / 2, 12 * s, up, C(0x000000, 0.28))
            c.ellipse(x - dir * 2 * s, g - up / 2, 7 * s, up * 3 / 4, C(0x000000, 0.2))
            // fingers reaching ahead
            for k in 0..<4 {
                let len = (6 + Int((sin(t * 1.7 + Double(k * 3 + i)) * 0.5 + 0.5) * 10)) * s
                let x0 = dir > 0 ? x + 20 * s : x - 20 * s - len
                c.rect(x0, fy - 2 * s + k * 2 * s, len, s, C(0x000000, 0.32))
            }
        }
        // a lamp a shadow is passing goes dim
        for cx in theLibraryTables(c, g) {
            let d = xs.map { abs($0 - cx) }.min() ?? Int.max
            guard d < 34 * s else { continue }
            let k = 1 - Double(d) / Double(34 * s)
            c.circle(cx, g - 15 * s, 20 * s, C(0x000000, 0.28 * k))
            c.rect(cx - 3 * s, g - 16 * s, 7 * s, s, C(0x3A2A1A, k))
        }
    }
}

// MARK: - Satellite Five

extension Scenes {
    /// The great window looking down on Earth: its inner box.
    static func satelliteFiveWindow(_ c: PixelCanvas, _ g: Int) -> (x0: Int, y0: Int, x1: Int, y1: Int) {
        let s = unit(g), tall = isTall(c)
        let ww = tall ? c.w * 2 / 5 : c.w / 4
        return (c.w / 2 - ww / 2, tall ? g / 7 : 5 * s, c.w / 2 + ww / 2, g - (tall ? g / 5 : 19 * s))
    }

    /// The top of the consoles along the walls.
    static func satelliteFiveDesk(_ c: PixelCanvas, _ g: Int) -> Int {
        isTall(c) ? g - 16 * unit(g) : satelliteFiveWindow(c, g).y1 + 4 * unit(g)
    }

    /// The monitors on the walls either side of the window: each screen's box, in order.
    static func satelliteFiveScreens(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = unit(g), tall = isTall(c), win = satelliteFiveWindow(c, g)
        let mw = 16 * s, mh = 11 * s, gx = 5 * s, gy = 4 * s
        let top = tall ? g / 9 : 5 * s
        var out: [(x: Int, y: Int, w: Int, h: Int)] = []
        var y = satelliteFiveDesk(c, g) - 4 * s - mh
        while y >= top {
            var x = win.x0 - 12 * s - mw
            while x >= 2 * s { out.append((x, y, mw, mh)); x -= mw + gx }
            x = win.x1 + 12 * s
            while x + mw <= c.w - 2 * s { out.append((x, y, mw, mh)); x += mw + gx }
            y -= mh + gy
        }
        return out
    }

    /// Satellite Five: a news station orbiting high over Earth. Riveted steel walls are lined with banks of monitors
    /// and consoles, the floor is a grating edged with cyan light, and in the middle a great window looks down on
    /// the blue curve of the planet with its continents and clouds. On the screen saver the whole globe hangs in the
    /// window and the screens climb to the ceiling.
    static func satelliteFive(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), win = satelliteFiveWindow(c, g)
        c.gradient(0, g, C(0x0C121C), C(0x1E2838), bands: 8)
        for x in stride(from: 0, to: c.w, by: 24 * s) {    // the wall's panel seams and rivets
            c.rect(x, 0, s, g, C(0x0A0E16))
            c.rect(x + s, 0, s, g, C(0x2A3446, 0.6))
            for y in stride(from: 4 * s, to: g, by: 12 * s) { c.rect(x + 3 * s, y, s, s, C(0x3A4658)) }
        }
        for y in stride(from: g - 6 * s, to: 0, by: -30 * s) { c.rect(0, y, c.w, s, C(0x2A3446)) }
        // the ceiling: a beam with strip lights, and on the screen saver pipes and ducts too
        c.rect(0, 0, c.w, 3 * s, C(0x2A3444)); c.rect(0, 3 * s, c.w, s, C(0x0A0E16))
        for x in stride(from: 10 * s, to: c.w, by: 40 * s) { c.rect(x, s, 12 * s, s, C(0xC8ECFF, 0.8)) }
        if tall {
            for k in 0..<3 {
                let y = 6 * s + k * 5 * s
                c.rect(0, y, c.w, 3 * s, C(0x222C3C)); c.rect(0, y, c.w, s, C(0x3A4658))
                for x in stride(from: k * 17 * s, to: c.w, by: 60 * s) { c.rect(x, y - s, 3 * s, 5 * s, C(0x1A2230)) }
            }
        }
        satelliteFiveEarth(c, g, win, s, tall)
        // the window's frame and mullions
        let fr = C(0x3A4658), frLit = C(0x6A7A90)
        c.rect(win.x0 - 4 * s, win.y0 - 4 * s, win.x1 - win.x0 + 8 * s, 4 * s, fr)
        c.rect(win.x0 - 4 * s, win.y1, win.x1 - win.x0 + 8 * s, 4 * s, fr)
        c.rect(win.x0 - 4 * s, win.y0, 4 * s, win.y1 - win.y0, fr)
        c.rect(win.x1, win.y0, 4 * s, win.y1 - win.y0, fr)
        c.rect(win.x0 - 4 * s, win.y0 - 4 * s, win.x1 - win.x0 + 8 * s, s, frLit)
        for k in 1...2 {
            let mx = win.x0 + (win.x1 - win.x0) * k / 3
            c.rect(mx - s, win.y0, 2 * s, win.y1 - win.y0, fr); c.rect(mx - s, win.y0, s, win.y1 - win.y0, frLit)
        }
        for k in 0..<3 {                                   // reflections on the glass
            let x = win.x0 + (win.x1 - win.x0) * (k * 2 + 1) / 7
            for y in stride(from: win.y0, to: win.y1, by: s) {
                c.rect(x + (y - win.y0) / 3, y, 2 * s, s, C(0xFFFFFF, 0.05))
            }
        }
        // the screens' bezels, dark until they're switched on
        for m in satelliteFiveScreens(c, g) {
            c.rect(m.x - s, m.y - s, m.w + 2 * s, m.h + 2 * s, C(0x3A4454))
            c.rect(m.x - s, m.y - s, m.w + 2 * s, s, C(0x5A6A7C))
            c.rect(m.x, m.y, m.w, m.h, C(0x080C12))
            c.rect(m.x + m.w / 2 - s, m.y + m.h + s, 2 * s, s, C(0x2A3444))
        }
        // the consoles under the screens
        let cy = satelliteFiveDesk(c, g)
        if tall {                                          // a bulkhead and a hatch under the window
            c.rect(win.x0 - 4 * s, win.y1 + 4 * s, win.x1 - win.x0 + 8 * s, cy - win.y1 - 4 * s, C(0x222C3C))
            for x in stride(from: win.x0, to: win.x1, by: 12 * s) { c.rect(x, win.y1 + 8 * s, 8 * s, cy - win.y1 - 14 * s, C(0x2A3648)) }
            for x in stride(from: win.x0 + 4 * s, to: win.x1 - 4 * s, by: 6 * s) { c.rect(x, cy - 4 * s, 3 * s, s, C(0xFFB03A, 0.7)) }
        }
        for (x0, x1) in [(0, win.x0 - 8 * s), (win.x1 + 8 * s, c.w)] where x1 > x0 {
            c.rect(x0, cy, x1 - x0, g - cy, C(0x2A3444))
            c.rect(x0, cy, x1 - x0, s, C(0x6A7A90))
            c.rect(x0, cy + 2 * s, x1 - x0, 2 * s, C(0x1A2230))
        }
        c.rect(win.x0 - 8 * s, cy + 2 * s, win.x1 - win.x0 + 16 * s, s, C(0x5A6A7C))   // a rail under the window
        // the grating
        c.ground(g, C(0x1A2230), edge: C(0x4AC8FF), speck: C(0x121822), seed: 52)
        for x in stride(from: 0, to: c.w, by: 5 * s) { c.rect(x, g + 2 * s, s, c.h - g - 2 * s, C(0x0E141C)) }
        c.rect(0, g + s, c.w, s, C(0x4AC8FF, 0.3))
    }

    /// Space and the Earth seen through the window: the top of the globe in the window, the whole of it on the
    /// screen saver, lit from the upper left.
    static func satelliteFiveEarth(_ c: PixelCanvas, _ g: Int, _ win: (x0: Int, y0: Int, x1: Int, y1: Int), _ s: Int, _ tall: Bool) {
        let ww = win.x1 - win.x0, wh = win.y1 - win.y0
        c.rect(win.x0, win.y0, ww, wh, C(0x02040A))
        c.stars(win.y0, win.y1, density: 30, seed: 5, x0: win.x0, x1: win.x1)
        let r = tall ? Double(min(ww, wh)) * 0.4 : Double(ww) * 0.72
        let ex = Double(win.x0 + ww / 2), ey = tall ? Double(win.y0 + wh / 2) : Double(win.y0) + Double(wh) * 0.42 + r
        for y in stride(from: win.y0, to: win.y1, by: s) {
            for x in stride(from: win.x0, to: win.x1, by: s) {
                let u = (Double(x) - ex) / r, v = (Double(y) - ey) / r
                let d2 = u * u + v * v
                if d2 > 1.1 { continue }
                if d2 > 1 { c.rect(x, y, s, s, C(0x6AB8FF, 0.25)); continue }    // the glow of the air
                let z = (1 - d2).squareRoot()
                let light = max(0.15, min(1, 0.35 - u * 0.45 - v * 0.35 + z * 0.55))
                let land = sin(u * 7 + v * 3) + sin(v * 9 - u * 2 + 1) + sin((u + v) * 5 + 2)
                let cloud = sin(u * 13 + v * 4 + 3) + sin(v * 15 - u * 6) + sin((u - v) * 9 + 1)
                var col = land > 1.1 ? (land > 2 ? C(0x8A7A4A) : C(0x3A7A3A)) : C(0x1E4A9A)
                if cloud > 1.5 { col = C(0xE8F0F8) }
                if d2 > 0.9 { col = lerp(col, C(0x8AC8FF), 0.5) }
                c.rect(x, y, s, s, lerp(C(0x02040A), col, light))
            }
        }
    }

    /// One screen's picture: static, colour bars, the news, a game show, a stock chart or the weather.
    static func satelliteFiveChannel(_ c: PixelCanvas, _ m: (x: Int, y: Int, w: Int, h: Int), _ ch: Int, _ i: Int,
                                     _ t: Double, _ s: Int) {
        switch ch {
        case 1:                                            // colour bars
            let bars = [0xC8C8C8, 0xC8C83A, 0x3AC8C8, 0x3AC83A, 0xC83AC8, 0xC83A3A, 0x3A3AC8] as [UInt32]
            for (k, col) in bars.enumerated() {
                let x0 = m.x + m.w * k / bars.count, x1 = m.x + m.w * (k + 1) / bars.count
                c.rect(x0, m.y, x1 - x0, m.h * 3 / 4, C(col))
            }
            c.rect(m.x, m.y + m.h * 3 / 4, m.w, m.h - m.h * 3 / 4, C(0x1A1A2A))
        case 2:                                            // the news: a presenter and a ticker
            c.rect(m.x, m.y, m.w, m.h, C(0x1A3A7A))
            c.rect(m.x + m.w / 2, m.y + s, m.w / 2 - s, m.h / 2, C(0x3A6AB8))
            c.circle(m.x + m.w / 3, m.y + m.h / 2 - 2 * s, 2 * s, C(0xD8A880))
            c.rect(m.x + m.w / 3 - 3 * s, m.y + m.h / 2 + s, 7 * s, m.h / 2 - s, C(0x2A2A3A))
            c.rect(m.x, m.y + m.h - 2 * s, m.w, 2 * s, C(0xC82020))
            let off = Int(t * 8) * s % (4 * s)
            for x in stride(from: m.x - off, to: m.x + m.w - s, by: 4 * s) where x >= m.x {
                c.rect(x, m.y + m.h - 2 * s + s / 2, 2 * s, max(1, s), white)
            }
        case 3:                                            // a game show: the lit ring and the light chasing round it
            c.rect(m.x, m.y, m.w, m.h, C(0x10082A))
            let r = min(m.w, m.h) / 3, cx = m.x + m.w / 2, cy = m.y + m.h / 2
            c.circle(cx, cy, r, C(0x4A9AFF)); c.circle(cx, cy, max(1, r - s), C(0x10082A))
            let a = t * 3 + Double(i)
            c.rect(cx + Int(cos(a) * Double(r)) - s / 2, cy + Int(sin(a) * Double(r)) - s / 2, max(1, s), max(1, s), C(0xFFE08A))
        case 4:                                            // the markets
            c.rect(m.x, m.y, m.w, m.h, C(0x061A10))
            let bars = max(1, m.w / (2 * s))
            for k in 0..<bars {
                let bh = max(s, Int(noise(i * 53 + k + Int(t * 2) * 7) * Double(m.h - 2 * s)))
                c.rect(m.x + k * 2 * s, m.y + m.h - bh, s, bh, C(0x4AE07A))
            }
        case 5:                                            // the weather
            c.rect(m.x, m.y, m.w, m.h, C(0x2A6AB8))
            c.ellipse(m.x + m.w / 2, m.y + m.h / 2 + s, m.w / 4, m.h / 3, C(0x4AA04A))
            c.circle(m.x + m.w - 4 * s, m.y + 3 * s, 2 * s, C(0xFFD24A))
            c.ellipse(m.x + 5 * s, m.y + 3 * s, 3 * s, s, white)
        default:                                           // static
            let frame = Int(t * 12)
            for y in stride(from: m.y, to: m.y + m.h, by: s) {
                for x in stride(from: m.x, to: m.x + m.w, by: s) {
                    c.rect(x, y, s, s, lerp(C(0x101418), C(0xC8D0D8), noise(i * 1000 + frame * 37 + x * 7 + y * 131)))
                }
            }
        }
        for y in stride(from: m.y + s, to: m.y + m.h, by: 2 * s) { c.rect(m.x, y, m.w, s, C(0x000000, 0.18)) }
    }

    /// What moves on Satellite Five: every screen flicking between channels with a burst of static in between, and
    /// the consoles' lights blinking.
    static func satelliteFiveLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), win = satelliteFiveWindow(c, g)
        for (i, m) in satelliteFiveScreens(c, g).enumerated() {
            let period = 1.8 + noise(i * 7 + 700) * 2.6
            let phase = (t + noise(i * 7 + 701) * 10) / period
            let idx = Int(floor(phase)), frac = phase - floor(phase)
            let ch = frac < 0.08 ? 0 : 1 + Int(noise(i * 31 + idx * 7 + 702) * 5)
            satelliteFiveChannel(c, m, ch, i, t, s)
        }
        let cy = satelliteFiveDesk(c, g)
        for x in stride(from: 3 * s, to: c.w, by: 4 * s) {
            if x > win.x0 - 8 * s && x < win.x1 + 8 * s { continue }
            let k = x / s
            guard noise(k * 13 + Int(t * (1 + noise(k) * 2))) > 0.55 else { continue }
            let col = [C(0xFF6A4A), C(0x6AFF8A), C(0xFFD24A), C(0x4AC8FF)][k % 4]
            c.rect(x, cy + 2 * s + (k % 2) * s, s, s, col)
        }
    }
}

// MARK: - New Earth

extension Scenes {
    /// The rows the skyway's lanes of flying cars run along.
    static func newEarthLanes(_ c: PixelCanvas, _ g: Int) -> [Int] {
        if isTall(c) { return stride(from: g * 22 / 100, to: g * 80 / 100, by: g * 11 / 100).map { $0 } }
        return [g * 16 / 100, g * 34 / 100, g * 52 / 100]
    }

    /// New Earth: the city of New New York across a meadow of apple grass. Slender towers of lilac and steel with
    /// domed tops, needle spires and ringed discs rise in a warm hazy sky, and between them the skyway's lanes are
    /// marked out with lights. On the screen saver the sky opens up with a great pale sun and more lanes stack up
    /// among the tower tops.
    static func newEarth(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let hz = g - 8 * s
        c.gradient(0, hz, C(0x3A8AC8), C(0xF4DCB4), bands: 8)
        let sx = c.w * 4 / 5, sy = tall ? g / 8 : 9 * s, sr = tall ? 16 * s : 5 * s
        c.circle(sx, sy, sr * 3, C(0xFFF4D0, 0.10)); c.circle(sx, sy, sr * 2, C(0xFFF4D0, 0.15))
        c.circle(sx, sy, sr, C(0xFFF8E4))
        c.circle(c.w / 6, tall ? g / 5 : 6 * s, tall ? 6 * s : 2 * s, C(0xE8E4F4, 0.8))     // a pale moon by day
        for i in 0..<(tall ? 7 : 3) {
            let x = Int(noise(i * 5 + 800) * Double(c.w)), y = Int((0.06 + noise(i * 5 + 801) * (tall ? 0.4 : 0.15)) * Double(g))
            cloud(c, x, y, (3 + Int(noise(i * 5 + 802) * 4)) * s, seed: i + 80, top: C(0xFFF4EC), base: C(0xF0C8C0))
        }
        // the far towers, hazy lilac
        newEarthSkyline(c, g, hz: hz, lo: tall ? 0.22 : 0.40, hi: tall ? 0.55 : 0.80, body: C(0xB8BCDC), lit: C(0xCCD0EC),
                        win: C(0xFFFFFF, 0.25), seed: 1)
        // the skyway's lanes
        for y in newEarthLanes(c, g) {
            c.rect(0, y + 4 * s, c.w, s, C(0xFFFFFF, 0.18))
            for x in stride(from: (y / s % 3) * 6 * s, to: c.w, by: 18 * s) { c.rect(x, y + 4 * s, s, s, C(0xFFE08A, 0.8)) }
        }
        // the near towers, steel blue with glinting windows
        newEarthSkyline(c, g, hz: hz, lo: tall ? 0.32 : 0.55, hi: tall ? 0.70 : 1.05, body: C(0x6A78A8), lit: C(0x8E9CCC),
                        win: C(0xE8F0FF, 0.55), seed: 2)
        // the apple-grass meadow
        c.dunes(base: hz, amp: Double(2 * s), freq: 0.025 / Double(s), phase: 2, bottom: g, C(0x5A9A3A), shade: C(0x8AC85A))
        c.ground(g, C(0x4A8A32), edge: C(0x7AC04A), speck: C(0x3A7028), seed: 61)
        for i in 0..<(c.w / (3 * s)) {                     // the little red apples in the grass
            let x = Int(noise(i * 7 + 810) * Double(c.w)), y = hz + Int(noise(i * 7 + 811) * Double(c.h - hz))
            c.rect(x, y, s, s, C(0xC83A2A))
        }
    }

    /// A row of New New York towers: domes, needles with rings, stepped towers, with a lit side and windows.
    static func newEarthSkyline(_ c: PixelCanvas, _ g: Int, hz: Int, lo: Double, hi: Double, body: Px, lit: Px, win: Px, seed: Int) {
        let s = unit(g)
        var x = -4 * s, i = 0
        while x < c.w {
            let n = i * 7 + seed * 211
            let bw = (6 + Int(noise(n) * 10)) * s
            let top = hz - Int(Double(hz) * (lo + noise(n + 1) * (hi - lo)))
            let kind = Int(noise(n + 2) * 5)
            let tint = noise(n + 4) > 0.7 ? lerp(body, C(0xE8D8B0), 0.45) : body
            c.rect(x, top, bw, hz - top, tint)
            c.rect(x, top, s, hz - top, lit)
            c.rect(x + bw - s, top, s, hz - top, lerp(tint, C(0x000000), 0.15))
            if noise(n + 5) > 0.5 {                        // a glowing band round the middle
                let by = top + (hz - top) / 3
                c.rect(x - s, by, bw + 2 * s, 2 * s, lit); c.rect(x - s, by + 2 * s, bw + 2 * s, s, C(0x7AE8FF, 0.6))
            }
            switch kind {
            case 0, 4:                                     // a domed top
                c.ellipse(x + bw / 2, top, bw / 2, bw / 3, tint)
                c.ellipse(x + bw / 2 - bw / 6, top - bw / 6, max(1, bw / 6), max(1, bw / 8), lit)
                c.rect(x + bw / 2 - s / 2, top - bw / 3 - 3 * s, max(1, s), 3 * s, lit)
            case 1:                                        // a needle spire threaded with discs
                c.rect(x + bw / 2 - s, top - 14 * s, 2 * s, 14 * s, body)
                c.ellipse(x + bw / 2, top - 5 * s, bw * 3 / 4, s, lit)
                c.ellipse(x + bw / 2, top - 10 * s, bw / 2, s, lit)
            case 2:                                        // stepped
                c.rect(x + bw / 5, top - 5 * s, bw * 3 / 5, 5 * s, body)
                c.rect(x + bw * 2 / 5, top - 9 * s, bw / 5 + s, 4 * s, body)
            default:                                       // a flat roof with a saucer platform
                c.ellipse(x + bw / 2, top, bw * 2 / 3, s, lit)
            }
            for wy in stride(from: top + 3 * s, to: hz - s, by: 4 * s) {
                for wx in stride(from: x + 2 * s, to: x + bw - 2 * s, by: 3 * s) where noise(wx * 3 + wy * 7 + seed) > 0.4 {
                    c.rect(wx, wy, s, 2 * s, win)
                }
            }
            x += bw + (2 + Int(noise(n + 3) * 16)) * s
            i += 1
        }
    }

    /// A little flying car facing `dir`: a rounded body, a glass bubble, lights at both ends and a glow underneath.
    static func newEarthCar(_ c: PixelCanvas, _ x: Int, _ y: Int, dir: Int, _ col: Px, _ s: Int) {
        let back = dir > 0 ? x - 6 * s : x + 9 * s
        c.rect(back, y + s, 5 * s, s, C(0xFFFFFF, 0.25))
        c.rect(x, y, 9 * s, 3 * s, col)
        c.rect(x, y, 9 * s, s, lerp(col, white, 0.4))
        c.rect(x + 2 * s, y - 2 * s, 5 * s, 2 * s, C(0x9AD8F0))
        c.rect(x + 3 * s, y - 2 * s, s, s, white)
        c.rect(dir > 0 ? x + 8 * s : x, y + s, s, s, C(0xFFF0A0))
        c.rect(dir > 0 ? x : x + 8 * s, y + s, s, s, C(0xFF3A2A))
        c.rect(x + s, y + 3 * s, 7 * s, s, C(0x7AE8FF, 0.6))
    }

    /// What moves in New New York: flying cars streaming along the skyway, lanes going each way, bobbing as they go.
    static func newEarthLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let cols = [C(0xC83A3A), C(0xE8C83A), C(0x3A8AE8), C(0xE8E8F0), C(0x9A4AC8), C(0x3AB87A), C(0xE87A3A)]
        for (li, ly) in newEarthLanes(c, g).enumerated() {
            let dir = li % 2 == 0 ? 1 : -1
            let speed = (24 + noise(li * 50 + 820) * 18) * Double(s)
            let n = max(3, c.w / (40 * s))
            let span = Double(c.w + 30 * s)
            for k in 0..<n where noise(li * 50 + k * 3 + 821) > 0.3 {
                let x0 = Double(k) * span / Double(n) + noise(li * 50 + k * 3 + 822) * Double(12 * s)
                let x = Int(doctorScenes3Wrap(x0 + Double(dir) * t * speed, span)) - 15 * s
                let bob = Int(sin(t * 2 + Double(k * 3 + li)) * 0.8 * Double(s))
                newEarthCar(c, x, ly + bob, dir: dir, cols[(k * 3 + li) % cols.count], s)
            }
        }
    }
}

// MARK: - Starship UK

extension Scenes {
    /// The Smiler booths along the street: the centre of each.
    static func starshipUKBooths(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = unit(g)
        return Array(stride(from: 74 * s, to: c.w - 8 * s, by: 156 * s))
    }

    /// Where the terraces' roofs line up.
    static func starshipUKHouseTop(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? g - 48 * unit(g) : g * 30 / 100 }

    /// Starship UK: a whole British street riding through space. Brick terraces and shopfronts with sash windows,
    /// chimney pots and striped awnings, iron street lamps strung with red, white and blue bunting, a red pillar box,
    /// and the carved wooden booths where the Smilers sit and watch. Above the rooftops a girder-framed glass roof
    /// shows the stars outside. On the screen saver the ship's tower blocks crowd up behind the terraces.
    static func starshipUK(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), top = starshipUKHouseTop(c, g)
        c.gradient(0, top + 10 * s, C(0x04050C), C(0x141A30), bands: 6)
        c.stars(0, top + 6 * s, density: 22, seed: 8)
        if tall {
            c.ellipse(c.w / 3, g / 6, 70 * s, 14 * s, C(0x6A3A8A, 0.10))      // a nebula drifting by
            c.ellipse(c.w / 3 + 30 * s, g / 6 + 4 * s, 40 * s, 8 * s, C(0xC85A8A, 0.08))
            c.circle(c.w * 4 / 5, g / 8, 9 * s, C(0x8A6A4A)); c.circle(c.w * 4 / 5 - 2 * s, g / 8 - 2 * s, 6 * s, C(0xB8946A))
        }
        // the glass roof's girders
        let beam = C(0x2A2E3E), beamLit = C(0x4A5068)
        let roofStep = tall ? 34 * s : 9 * s
        for y in stride(from: 2 * s, to: top - 2 * s, by: roofStep) {
            c.rect(0, y, c.w, 2 * s, beam); c.rect(0, y, c.w, s, beamLit)
        }
        for x in stride(from: 0, to: c.w, by: 44 * s) {
            c.rect(x, 0, 2 * s, top, beam); c.rect(x, 0, s, top, beamLit)
            for y in stride(from: 2 * s, to: top - roofStep, by: roofStep) {      // cross-bracing
                for k in stride(from: 0, to: roofStep, by: s) {
                    c.rect(x + k * 44 * s / roofStep, y + k, s, s, beam.alpha(0.7))
                }
            }
        }
        if tall {
            // the ship's tower blocks behind the terraces
            var x = -6 * s, i = 0
            while x < c.w {
                let bw = (30 + Int(noise(i * 5 + 900) * 26)) * s
                let bt = g * 22 / 100 + Int(noise(i * 5 + 901) * Double(g) * 0.25)
                c.rect(x, bt, bw, top - bt + 4 * s, C(0x343844))
                c.rect(x, bt, s, top - bt, C(0x4A4E5C))
                c.rect(x - s, bt, bw + 2 * s, 2 * s, C(0x24262E))
                for wy in stride(from: bt + 4 * s, to: top, by: 5 * s) {
                    for wx in stride(from: x + 3 * s, to: x + bw - 3 * s, by: 5 * s) {
                        let lit = noise(wx * 7 + wy * 3) > 0.55
                        c.rect(wx, wy, 3 * s, 3 * s, lit ? C(0xFFD890, 0.8) : C(0x1A1C24))
                    }
                }
                x += bw + Int(noise(i * 5 + 902) * 8) * s
                i += 1
            }
        }
        starshipUKTerrace(c, g, top: top, s: s)
        // the pavement, the lamps with their bunting, the pillar box
        c.rect(0, g - 4 * s, c.w, 4 * s, C(0x6A6A72)); c.rect(0, g - 4 * s, c.w, s, C(0x8A8A92))
        for x in stride(from: 0, to: c.w, by: 8 * s) { c.rect(x, g - 3 * s, s, 3 * s, C(0x55555C)) }
        let lamps = Array(stride(from: 20 * s, to: c.w, by: 78 * s))
        for (k, lx) in lamps.enumerated() {
            if k + 1 < lamps.count {
                let nx = lamps[k + 1]
                for x in stride(from: lx, to: nx, by: 3 * s) {
                    let u = Double(x - lx) / Double(nx - lx)
                    let y = g - 27 * s + Int(sin(u * .pi) * 6 * Double(s))
                    c.rect(x, y, 3 * s, s, C(0x2A2A2A, 0.6))
                    if (x - lx) / (3 * s) % 2 == 1 {
                        let col = [C(0xC82A2A), C(0xE8E8E8), C(0x2A4AA8)][((x - lx) / (6 * s)) % 3]
                        c.rect(x, y + s, 2 * s, s, col); c.rect(x, y + 2 * s, s, s, col)
                    }
                }
            }
            c.circle(lx, g - 30 * s, 9 * s, C(0xFFD890, 0.10))
            c.rect(lx, g - 28 * s, s, 28 * s, C(0x1E2A22)); c.rect(lx - s, g - 4 * s, 3 * s, 4 * s, C(0x1E2A22))
            c.rect(lx - 2 * s, g - 32 * s, 5 * s, 4 * s, C(0xFFE8A0)); c.rect(lx - 2 * s, g - 33 * s, 5 * s, s, C(0x1E2A22))
            c.rect(lx - s, g - 34 * s, 3 * s, s, C(0x1E2A22))
        }
        let pb = c.w / 2 + 40 * s
        c.rect(pb, g - 10 * s, 5 * s, 10 * s, C(0xC82A22)); c.rect(pb, g - 11 * s, 5 * s, s, C(0x8A1A16))
        c.rect(pb + s, g - 8 * s, 3 * s, s, C(0x1A0A08)); c.rect(pb, g - 10 * s, s, 10 * s, C(0xE84A3A))
        for bx in starshipUKBooths(c, g) { starshipUKBooth(c, bx, g, s) }
        c.ground(g, C(0x2A2A30), edge: C(0x8A8A92), speck: C(0x222226), seed: 71)
    }

    /// The terraced houses and shops from `top` down to the pavement.
    static func starshipUKTerrace(_ c: PixelCanvas, _ g: Int, top: Int, s: Int) {
        let walls = [C(0x6A2E22), C(0x5A3A2A), C(0xA89A80), C(0x7A4430), C(0x5A5A62)]
        var x = -8 * s, i = 0
        while x < c.w {
            let n = i * 11 + 950
            let hw = (36 + Int(noise(n) * 14)) * s
            let ht = top + Int(noise(n + 1) * 5) * s
            let wall = walls[Int(noise(n + 2) * Double(walls.count))]
            c.rect(x, ht, hw, g - ht, wall)
            for k in 0..<(hw * (g - ht) / (12 * s * s)) {      // brickwork
                c.rect(x + Int(noise(n * 7 + k * 2) * Double(hw)), ht + Int(noise(n * 7 + k * 2 + 1) * Double(g - ht)), 2 * s, s, C(0x000000, 0.12))
            }
            c.rect(x, ht - 3 * s, hw, 3 * s, C(0x2E3038)); c.rect(x, ht - 3 * s, hw, s, C(0x4A4C56))   // slate roof
            c.rect(x + hw - s, ht, s, g - ht, C(0x000000, 0.3))
            for cx in [x + 5 * s, x + hw - 10 * s] where noise(cx + n) > 0.3 {                         // chimneys
                c.rect(cx, ht - 8 * s, 5 * s, 5 * s, lerp(wall, C(0x000000), 0.2))
                c.rect(cx + s, ht - 10 * s, s, 2 * s, C(0xB8552A)); c.rect(cx + 3 * s, ht - 10 * s, s, 2 * s, C(0xB8552A))
            }
            // the upper sash windows
            let fl = ht + (g - ht) / 2 - 2 * s
            for wx in stride(from: x + 5 * s, to: x + hw - 7 * s, by: 12 * s) {
                for wy in stride(from: ht + 3 * s, to: fl - 8 * s, by: 11 * s) {
                    c.rect(wx - s, wy - s, 8 * s, 9 * s, C(0xD8D0C0))
                    let glow = noise(wx * 3 + wy) > 0.45
                    c.rect(wx, wy, 6 * s, 7 * s, glow ? C(0xFFD890) : C(0x1A2030))
                    c.rect(wx, wy + 3 * s, 6 * s, s, C(0xD8D0C0)); c.rect(wx + 3 * s - s / 2, wy, max(1, s), 7 * s, C(0xD8D0C0, 0.8))
                }
            }
            // the ground floor: a shop with an awning, or a front door and a bay window
            let gy = g - 4 * s
            if noise(n + 3) > 0.5 {
                let aw = hw - 6 * s
                c.rect(x + 3 * s, fl + 5 * s, aw, gy - fl - 5 * s, C(0x1A1A22))
                c.rect(x + 4 * s, fl + 6 * s, aw - 2 * s, gy - fl - 9 * s, C(0xFFE0A0, 0.7))
                for k in stride(from: 4 * s, to: aw - 2 * s, by: 8 * s) { c.rect(x + 4 * s + k, fl + 6 * s, s, gy - fl - 9 * s, C(0x1A1A22)) }
                for k in stride(from: 2 * s, to: aw - 4 * s, by: 5 * s) where noise(x + k) > 0.4 {    // goods in the window
                    c.rect(x + 4 * s + k, gy - 6 * s, 3 * s, 3 * s, [C(0xC83A2A), C(0x3A6AB8), C(0x4A8A3A)][(k / s) % 3])
                }
                for k in stride(from: 0, to: aw, by: 3 * s) {
                    let col = (k / (3 * s)) % 2 == 0 ? C(0xC82A2A) : C(0xE8E0D0)
                    c.rect(x + 3 * s + k, fl, 3 * s, 4 * s, col)
                }
                c.rect(x + 2 * s, fl + 4 * s, aw + 2 * s, s, C(0x6A1A16))
            } else {
                let dc = [C(0x1A2A5A), C(0x6A1A1A), C(0x1A4A2A)][Int(noise(n + 4) * 3)]
                let dx = x + hw - 13 * s
                c.rect(dx - s, gy - 13 * s, 7 * s, 13 * s, C(0xD8D0C0))
                c.rect(dx, gy - 10 * s, 5 * s, 10 * s, dc)
                c.rect(dx, gy - 12 * s, 5 * s, s, C(0xFFD890, 0.8))
                c.rect(dx + 4 * s, gy - 5 * s, s, s, C(0xD8B45A))
                c.rect(x + 5 * s, fl + 4 * s, 14 * s, gy - fl - 7 * s, C(0xD8D0C0))
                c.rect(x + 6 * s, fl + 5 * s, 12 * s, gy - fl - 9 * s, noise(n + 5) > 0.4 ? C(0xFFD890, 0.85) : C(0x1A2030))
            }
            x += hw
            i += 1
        }
    }

    /// A carved wooden Smiler booth centred on `x`, its window empty until the moving layer puts a face in it.
    static func starshipUKBooth(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let wood = C(0x5A3422), lit = C(0x8A5A34), dark = C(0x341C12), gold = C(0xC8A04A)
        c.rect(x - 7 * s, g - 26 * s, 14 * s, 26 * s, wood)
        c.rect(x - 7 * s, g - 26 * s, s, 26 * s, lit); c.rect(x + 6 * s, g - 26 * s, s, 26 * s, dark)
        c.rect(x - 9 * s, g - 29 * s, 18 * s, 3 * s, lit); c.rect(x - 9 * s, g - 27 * s, 18 * s, s, dark)
        c.rect(x - 4 * s, g - 31 * s, 8 * s, 2 * s, wood); c.rect(x - s, g - 33 * s, 2 * s, 2 * s, gold)
        c.rect(x - 5 * s, g - 24 * s, 10 * s, 11 * s, gold)                          // the window and its gilt frame
        c.rect(x - 4 * s, g - 23 * s, 8 * s, 9 * s, C(0x14100C))
        c.rect(x - 5 * s, g - 10 * s, 10 * s, 6 * s, dark)                           // the panel below, with its slot
        c.rect(x - 2 * s, g - 8 * s, 4 * s, s, C(0x0A0604))
        c.rect(x - 8 * s, g - 2 * s, 16 * s, 2 * s, dark)
    }

    /// A Smiler's face `squash` of its full width (it narrows as the head turns), centred on `cx` with its top at
    /// `y`: 0 smiling, 1 frowning, 2 angry with red eyes and a mouth full of teeth.
    static func starshipUKSmiler(_ c: PixelCanvas, _ cx: Int, _ y: Int, mood: Int, squash: Double, _ s: Int) {
        let fw = max(s, Int(Double(6 * s) * squash) / s * s), x = cx - fw / 2
        let face = mood == 2 ? C(0xD8CCB8) : C(0xEAE4D6), shade = C(0xA8A090)
        c.rect(x + s, y, max(s, fw - 2 * s), s, face)
        c.rect(x, y + s, fw, 6 * s, face)
        c.rect(x + s, y + 7 * s, max(s, fw - 2 * s), s, shade)
        c.rect(x + fw - s, y + s, s, 6 * s, shade.alpha(0.7))
        guard squash > 0.7 else { return }
        let p = { (u: Int, v: Int, col: Px) in c.rect(cx - 3 * s + u * s, y + v * s, s, s, col) }
        let eye = mood == 2 ? C(0xFF3A1A) : C(0x1A1418), paint = C(0xA82A2A), brow = C(0x3A2A24)
        p(1, 3, eye); p(4, 3, eye)
        switch mood {
        case 0:
            p(1, 5, paint); p(4, 5, paint); p(2, 6, paint); p(3, 6, paint)
            p(1, 2, C(0xE8A0A0, 0.5)); p(4, 2, C(0xE8A0A0, 0.5))
        case 1:
            p(2, 5, paint); p(3, 5, paint); p(1, 6, paint); p(4, 6, paint)
            p(0, 2, brow); p(1, 2, brow); p(4, 2, brow); p(5, 2, brow)
        default:
            p(1, 2, brow); p(2, 2, brow); p(3, 2, brow); p(4, 2, brow); p(0, 1, brow); p(5, 1, brow)
            for u in 1...4 { p(u, 5, C(0x1A0A0A)); p(u, 6, C(0x1A0A0A)) }
            p(1, 5, white); p(4, 5, white); p(2, 6, white); p(3, 6, white)
        }
    }

    /// What moves on Starship UK: in every booth the Smiler's head turns, from its painted smile to a frown and round
    /// again to its snarling face, and then back to smiling; and a few stars twinkle through the roof.
    static func starshipUKLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), top = starshipUKHouseTop(c, g)
        for (i, bx) in starshipUKBooths(c, g).enumerated() {
            let p = doctorScenes3Wrap(t / 7 + noise(i * 7 + 960), 1)
            // the stages: (from, to, mood before, mood after); a turn squashes the face to nothing and back
            let stages: [(Double, Double, Int, Int)] = [(0, 0.45, 0, 0), (0.45, 0.52, 0, 1), (0.52, 0.74, 1, 1),
                                                        (0.74, 0.80, 1, 2), (0.80, 0.94, 2, 2), (0.94, 1.0, 2, 0)]
            for (a, b, m0, m1) in stages where p >= a && p < b {
                let k = (p - a) / (b - a)
                let turning = m0 != m1
                let mood = turning && k >= 0.5 ? m1 : m0
                let squash = turning ? abs(cos(k * .pi)) : 1
                starshipUKSmiler(c, bx, g - 23 * s + s, mood: mood, squash: max(0.15, squash), s)
                if mood == 2 && !turning { c.circle(bx, g - 19 * s, 6 * s, C(0xFF3A1A, 0.08)) }
            }
        }
        for i in 0..<(c.w / 30) {
            let x = Int(noise(i * 5 + 970) * Double(c.w)), y = Int(noise(i * 5 + 971) * Double(top))
            let tw = 0.5 + 0.5 * sin(t * (1.5 + noise(i * 5 + 972) * 3) + Double(i))
            if tw > 0.7 { c.rect(x, y, s, s, C(0xFFFFFF, tw)) }
        }
    }
}

// MARK: - Pompeii

extension Scenes {
    /// Vesuvius: the centre of its crater, its peak row, the row its foot stands on and its half-width there.
    static func pompeiiVolcano(_ c: PixelCanvas, _ g: Int) -> (cx: Int, peak: Int, foot: Int, half: Int, crater: Int) {
        let s = unit(g), tall = isTall(c)
        let cx = Int(Double(c.w) * 0.66)
        let half = Int(Double(c.w) * (tall ? 0.34 : 0.26))
        return (cx, tall ? g * 42 / 100 : g * 15 / 100, tall ? g - 30 * s : g * 56 / 100, half, (tall ? 12 : 8) * s)
    }

    /// Pompeii, on its last day: a street of red and ochre houses with terracotta roofs, a temple portico of white
    /// fluted columns under a pediment, a forum colonnade with one column already broken, cobbles underfoot. Behind
    /// it Vesuvius is erupting, lava running down its flanks and a black column of smoke lit orange from beneath. On
    /// the screen saver the smoke climbs the whole sky and spreads out like a pine tree's crown.
    static func pompeii(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), v = pompeiiVolcano(c, g)
        c.gradient(0, v.foot + 4 * s, C(0x1E1418), C(0xC8602A), bands: 8)
        // the plume: a column of smoke from the crater, spreading out at the top on the screen saver
        let plumeTop = tall ? g / 12 : -10 * s
        var y = v.peak - 2 * s, k = 0
        while y > plumeTop {
            let up = Double(v.peak - y) / Double(max(1, v.peak - plumeTop))
            let rx = v.crater + Int(up * Double(tall ? 60 : 30) * Double(s)) + Int(noise(k * 3 + 1000) * 6) * s
            let dx = Int(sin(up * 3) * Double(8 * s)) + Int(up * Double(20 * s))
            for j in 0..<3 {                               // a cluster of billows at each height
                let ox = Int((noise(k * 7 + j + 1003) - 0.5) * Double(rx)), oy = Int((noise(k * 7 + j + 1006) - 0.5) * Double(rx) / 2)
                let r = max(s, rx * (2 + j) / 6)
                c.circle(v.cx + dx + ox, y + oy, r, C(0x2A2024, 0.9))
                c.circle(v.cx + dx + ox - r / 3, y + oy - r / 3, max(1, r / 2), C(0x3E3236, 0.8))
            }
            y -= max(2 * s, rx / 3)
            k += 1
        }
        if tall {
            for i in 0..<9 {                               // the pine-tree crown
                let px = v.cx + 20 * s + Int((noise(i * 3 + 1010) - 0.5) * Double(c.w) * 0.7)
                let py = plumeTop + Int(noise(i * 3 + 1011) * Double(g) * 0.08)
                let rx = (30 + Int(noise(i * 3 + 1012) * 30)) * s
                c.ellipse(px, py, rx, rx / 3, C(0x2A2024, 0.8))
            }
        }
        c.circle(v.cx, v.peak, v.crater * 3, C(0xFF7A2A, 0.18))
        c.ellipse(v.cx, v.peak - 3 * s, v.crater * 2, v.crater, C(0xFF8A3A, 0.25))
        // the mountain
        for x in (v.cx - v.half)...(v.cx + v.half) {
            let dx = abs(x - v.cx)
            var top: Int
            if dx < v.crater { top = v.peak + (dx < v.crater * 2 / 3 ? 2 * s : 0) }
            else { top = v.peak + (dx - v.crater) * (v.foot - v.peak) / max(1, v.half - v.crater) }
            top += Int(noise(x / s + 1020) * 2) * s
            guard top < v.foot + 4 * s else { continue }
            c.rect(x, top, 1, v.foot + 4 * s - top, x < v.cx ? C(0x4A2E2A) : C(0x2E1E1E))
            c.rect(x, top, 1, s, x < v.cx ? C(0x8A4A30) : C(0x5A3026))
        }
        for i in 0..<4 {                                   // the lava running down the flanks
            var lx = v.cx + Int((noise(i * 3 + 1030) - 0.5) * Double(v.crater) * 1.6), ly = v.peak + s
            let dir = lx < v.cx ? -1 : 1
            let len = Int(Double(v.foot - v.peak) * (0.4 + noise(i * 3 + 1031) * 0.4))
            for _ in stride(from: 0, to: len, by: s) {
                c.rect(lx, ly, 2 * s, s, C(0xFF6A1A)); c.rect(lx, ly, s, s, C(0xFFC060))
                ly += s
                if noise(lx * 3 + ly) > 0.4 { lx += dir * s * (1 + Int(noise(ly) * 2)) }
            }
        }
        // the houses
        let backTop = g - 38 * s
        let walls = [C(0xC8903A), C(0x9A3222), C(0xD8C8A0), C(0xB86A3A)]
        var x = -6 * s, i = 0
        while x < c.w {
            let n = i * 9 + 1040
            let hw = (28 + Int(noise(n) * 22)) * s
            let ht = backTop + Int(noise(n + 1) * 8) * s
            let wall = walls[Int(noise(n + 2) * Double(walls.count))]
            c.rect(x, ht, hw, g - ht, wall)
            c.rect(x + hw - s, ht, s, g - ht, C(0x000000, 0.25))
            c.rect(x, ht + 4 * s, hw, s, C(0x000000, 0.15))
            c.rect(x, g - 8 * s, hw, 3 * s, lerp(wall, C(0x2A1A14), 0.35))         // a painted dado
            for r in 0..<(4 * s) {                                                 // the tiled roof
                c.rect(x - s + r, ht - 4 * s + r, hw + 2 * s - 2 * r, 1, r < s ? C(0xD8703A) : C(0xB8552A))
            }
            for wx in stride(from: x + 5 * s, to: x + hw - 6 * s, by: 11 * s) where noise(wx + n) > 0.35 {
                c.rect(wx, ht + 7 * s, 3 * s, 4 * s, C(0x2A1A14))
            }
            c.rect(x + hw / 2 - 3 * s, g - 12 * s, 6 * s, 12 * s, C(0x2A1A14))       // the doorway
            x += hw
            i += 1
        }
        // the temple portico on the left, the forum colonnade on the right
        let pw = 72 * s, px0 = c.w / 10
        let colTop = g - 46 * s
        c.rect(px0 - 2 * s, g - 3 * s, pw + 4 * s, 3 * s, C(0xC8BCA0)); c.rect(px0 - 2 * s, g - 3 * s, pw + 4 * s, s, C(0xE8DCC0))
        for cx in stride(from: px0 + 3 * s, to: px0 + pw, by: 13 * s) { pompeiiColumn(c, cx, colTop + 4 * s, g - 3 * s, s) }
        c.rect(px0 - 2 * s, colTop, pw + 4 * s, 4 * s, C(0xD8CCB0)); c.rect(px0 - 2 * s, colTop + 3 * s, pw + 4 * s, s, C(0xA89A80))
        let ph = 10 * s
        for r in 0..<ph {
            let half = (pw / 2 + 2 * s) * r / ph
            c.rect(px0 + pw / 2 - half, colTop - ph + r, half * 2, 1, C(0xD8CCB0))
            c.px(px0 + pw / 2 - half, colTop - ph + r, C(0xF0E6D0))
        }
        c.rect(px0 + pw / 2 - 2 * s, colTop - 5 * s, 4 * s, 3 * s, C(0xA89A80))
        let fx0 = c.w * 3 / 4, fTop = colTop + 6 * s
        for (k, cx) in stride(from: fx0, to: c.w - 2 * s, by: 15 * s).enumerated() {
            pompeiiColumn(c, cx, k == 2 ? fTop + 14 * s : fTop, g, s, broken: k == 2)
        }
        // the cobbled street
        c.ground(g, C(0x4A4038), edge: C(0x8A7A62), speck: C(0x2A241E), seed: 81)
        for (r, yy) in stride(from: g + 2 * s, to: c.h, by: 3 * s).enumerated() {
            for xx in stride(from: (r % 2) * 3 * s, to: c.w, by: 6 * s) { c.rect(xx, yy, s, 2 * s, C(0x2E2620)) }
        }
        c.rect(0, g + s, c.w, s, C(0x9A9088, 0.3))                                 // ash settling on the stones
    }

    /// A fluted white column from `top` down to `base`, centred on `x`; a broken one ends in a jagged stump.
    static func pompeiiColumn(_ c: PixelCanvas, _ x: Int, _ top: Int, _ base: Int, _ s: Int, broken: Bool = false) {
        let shaft = C(0xE0D4B8), lit = C(0xF4ECD8), shade = C(0xA89A80)
        c.rect(x - 2 * s, top, 5 * s, base - top, shaft)
        c.rect(x - 2 * s, top, s, base - top, lit)
        c.rect(x, top, s, base - top, C(0xC8BCA0))
        c.rect(x + 2 * s, top, s, base - top, shade)
        c.rect(x - 3 * s, base - s, 7 * s, s, shade)
        if broken {
            for k in 0..<5 { c.rect(x - 2 * s + k * s, top - Int(noise(k + x) * 3) * s, s, 3 * s, shaft) }
        } else {
            c.rect(x - 3 * s, top, 7 * s, 2 * s, C(0xD8CCB0)); c.rect(x - 3 * s, top + s, 7 * s, s, shade)
        }
    }

    /// What moves at Pompeii: smoke billowing up out of the crater and spreading, glowing rocks flung out of it, the
    /// crater's fire pulsing, and ash and embers drifting down over the town.
    static func pompeiiLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), v = pompeiiVolcano(c, g)
        let pulse = 0.5 + 0.5 * sin(t * 3.1)
        c.circle(v.cx, v.peak, v.crater * 2, C(0xFF8A3A, 0.10 + 0.12 * pulse))
        c.ellipse(v.cx, v.peak, v.crater, max(s, v.crater / 3), C(0xFFD27A, 0.5 + 0.4 * pulse))
        // billows rising and swelling
        let rise = Double(v.peak + (tall ? 0 : 20 * s) - (tall ? g / 10 : 0))
        let puffs = 9
        for i in 0..<puffs {
            let p = doctorScenes3Wrap(t / 7 + Double(i) / Double(puffs), 1)
            let y = v.peak - Int(p * rise)
            let rx = v.crater + Int(p * Double(tall ? 56 : 24) * Double(s))
            let dx = Int(sin(p * 3 + Double(i)) * p * Double(8 * s)) + Int(p * Double(20 * s))
            let fade = 1 - p
            for j in 0..<3 {
                let ox = Int((noise(i * 7 + j + 1090) - 0.5) * Double(rx)), r = max(s, rx * (2 + j) / 7)
                c.circle(v.cx + dx + ox, y - j * r / 3, r, C(0x3A2E30, 0.15 + fade * 0.3))
            }
            c.circle(v.cx + dx, y + rx / 4, max(s, rx / 2), C(0xE0602A, fade * fade * 0.3))
        }
        // lava bombs
        for i in 0..<5 {
            let p = doctorScenes3Wrap(t / 2.2 + noise(i * 3 + 1100), 1)
            let vx = (noise(i * 3 + 1101) - 0.5) * 70 * Double(s)
            let up = (24 + noise(i * 3 + 1102) * 20) * Double(s)
            let bx = v.cx + Int(vx * p), by = v.peak - Int(up * 4 * p * (1 - p) * 1.2) + Int(p * p * 10 * Double(s))
            c.rect(bx, by, s, s, C(0xFFD27A)); c.rect(bx - (vx > 0 ? s : -s), by + s, s, s, C(0xFF6A1A, 0.6))
        }
        // ash and embers falling
        let n = c.w * c.h / 500
        let hh = Double(c.h + 4 * s)
        for i in 0..<n {
            let speed = (8 + noise(i * 4 + 1110) * 10) * Double(s)
            let x = Int(doctorScenes3Wrap(noise(i * 4 + 1111) * Double(c.w) + t * 5 * Double(s) + sin(t + Double(i)) * 2 * Double(s), Double(c.w)))
            let y = Int(doctorScenes3Wrap(noise(i * 4 + 1112) * hh + t * speed, hh)) - 2 * s
            if noise(i * 4 + 1113) > 0.94 {
                c.rect(x, y, s, s, C(0xFF8A3A, 0.6 + 0.4 * pulse))
            } else {
                c.rect(x, y, s, s, C(0xA8A09C, 0.55))
            }
        }
    }
}
