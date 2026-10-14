import Foundation

let scenes5: [Location: Place] = [
    .madripoor: Place(name: "Madripur", panel: 0x1E1418, still: Scenes.madripoor, moving: Scenes.madripoorMoving),
    .sokovia: Place(name: "Sokovina", panel: 0x1A1A1E, still: Scenes.sokovia, moving: Scenes.sokoviaMoving),
    .worldship: Place(name: "Galacticus' Worldship", panel: 0x1A1028, still: Scenes.worldship, moving: Scenes.worldshipMoving),
    .harlem: Place(name: "Harlem", panel: 0x1E1814, still: Scenes.harlem, moving: Scenes.harlemMoving),
    .kunLun: Place(name: "K'un-Lune", panel: 0x1A2018, still: Scenes.kunLun, moving: Scenes.kunLunMoving),
]

/// 3×5 capitals for the signs in these places (M, N and W are wider), drawn as pixel letters.
private let scenes5Glyphs: [Character: [String]] = [
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "'": ["#", "#", ".", ".", "."],
    " ": ["..", "..", "..", "..", ".."],
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// Width in pixels of `text` drawn by `scenes5Text` at `s` pixels per dot.
    static func scenes5TextWidth(_ text: String, s: Int = 1) -> Int {
        let cols = text.reduce(0) { $0 + (scenes5Glyphs[$1]?.first?.count ?? 2) + 1 }
        return max(0, cols - 1) * s
    }

    /// Pixel lettering: `text` in 3×5 capitals, one dot between letters, each dot `s`×`s` pixels, top-left at (x, y).
    static func scenes5Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, s: Int = 1) {
        var cx = x
        for ch in text {
            let rows = scenes5Glyphs[ch] ?? scenes5Glyphs[" "]!
            for (r, row) in rows.enumerated() {
                for (k, dot) in row.enumerated() where dot == "#" { c.rect(cx + k * s, y + r * s, s, s, col) }
            }
            cx += (rows[0].count + 1) * s
        }
    }

    /// The same lettering centred on `cx`.
    static func scenes5TextCentred(_ c: PixelCanvas, _ cx: Int, _ y: Int, _ text: String, _ col: Px, s: Int = 1) {
        scenes5Text(c, cx - scenes5TextWidth(text, s: s) / 2, y, text, col, s: s)
    }

    /// String art drawn with every character `s` pixels square.
    static func scenes5Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// A solid triangle with its apex at (cx, top), `half` pixels either side at its base `h` rows down.
    static func scenes5Peak(_ c: PixelCanvas, _ cx: Int, _ top: Int, half: Int, h: Int, _ col: Px) {
        guard h > 0 else { return }
        for k in 0..<h {
            let hw = half * (k + 1) / h
            c.rect(cx - hw, top + k, hw * 2 + 1, 1, col)
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes5Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t / period + offset).truncatingRemainder(dividingBy: 1)
        return v < 0 ? v + 1 : v
    }
}

// MARK: - Madripoor

extension Scenes {
    /// One Lowtown shophouse: left edge, width, height and its index (the last one is the Duchess Bar).
    struct MadripoorShop { let x, w, h, i: Int; let bar: Bool }

    /// Lowtown's row of shophouses along the left of the quay, ending with the Duchess Bar.
    static func madripoorShops(_ c: PixelCanvas, _ g: Int) -> [MadripoorShop] {
        let s = unit(g), end = min(c.w * 34 / 100, 170 * s)
        let extra = isTall(c) ? g * 3 / 10 : 0
        var out: [MadripoorShop] = [], x = -6 * s, i = 0
        while x < end - 44 * s {
            let bw = (26 + Int(noise(i * 5 + 601) * 10)) * s
            out.append(MadripoorShop(x: x, w: bw, h: (44 + Int(noise(i * 5 + 602) * 16)) * s + extra, i: i, bar: false))
            x += bw; i += 1
        }
        out.append(MadripoorShop(x: x, w: 44 * s, h: 40 * s + extra, i: i, bar: true))
        return out
    }

    /// Where the junks ride at anchor: centre, waterline and scale.
    static func madripoorJunks(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, k: Int)] {
        let s = unit(g), k = isTall(c) ? 2 * s : s
        return [(c.w * 52 / 100, g - 6 * s, k), (c.w * 83 / 100, g - 7 * s, k)]
    }

    /// Madripoor, Lowtown at night: a row of crowded shophouses with vertical neon signs and red lanterns under
    /// their arcades, the Duchess Bar's sign on the last of them, junks with battened red sails riding in the harbour,
    /// and Hightown's glittering towers on the hill across the bay under a moon.
    static func madripoor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x070618), C(0x56184A), bands: 8)
        c.stars(0, g / 2, density: 110, seed: 51)
        let mx = c.w * 7 / 10, my = max(8 * s, g / 7)
        c.circle(mx, my, 7 * s, C(0xF0D8E0, 0.1)); c.circle(mx, my, 4 * s, C(0xF4E6D8))
        c.circle(mx + s, my - s, s, C(0xD8C8C0))
        if tall { madripoorHigh(c, g) }
        let sea = g - 15 * s
        madripoorHightown(c, g, sea: sea)
        // the harbour, glittering with Hightown's lights
        c.rect(0, sea, c.w, g - sea, C(0x120C26))
        c.rect(0, sea, c.w, s, C(0x2A1E48))
        for i in 0..<(c.w / 5) {
            let x = Int(noise(i * 3 + 701) * Double(c.w)), y = sea + 2 * s + Int(noise(i * 3 + 702) * Double(g - sea - 5 * s))
            let warm = noise(i * 3 + 703) > 0.6
            c.rect(x, y, (2 + Int(noise(i + 704) * 4)) * s, max(1, s), warm ? C(0xFFC880, 0.35) : C(0x8AB8FF, 0.3))
        }
        for j in madripoorJunks(c, g) { madripoorJunk(c, j.x, j.y, j.k) }
        // the quay's stone edge
        c.rect(0, g - 3 * s, c.w, 3 * s, C(0x2A2234)); c.rect(0, g - 3 * s, c.w, s, C(0x4A3A58))
        for x in stride(from: c.w * 40 / 100, to: c.w, by: 46 * s) {
            c.rect(x, g - 5 * s, 3 * s, 3 * s, C(0x1A1424)); c.rect(x, g - 5 * s, 3 * s, s, C(0x3A2E4A))
        }
        // a mooring post with its own lantern, out on the quay
        let px = c.w * 66 / 100
        c.rect(px, g - 22 * s, 2 * s, 20 * s, C(0x1A1020)); c.rect(px - 4 * s, g - 22 * s, 10 * s, s, C(0x1A1020))
        for shop in madripoorShops(c, g) { madripoorShop(c, shop, g) }
        c.ground(g, C(0x1A1624), edge: C(0x3A2E48), speck: C(0x262036), seed: 51)
    }

    /// Hightown on the hill across the bay: towers in cool glass, a few with spires and red lights on top.
    static func madripoorHightown(_ c: PixelCanvas, _ g: Int, sea: Int) {
        let s = unit(g)
        let maxH = isTall(c) ? Double(sea) * 0.62 : Double(sea - 6 * s)
        c.dunes(base: sea - 4 * s, amp: Double(3 * s), freq: 0.02, phase: 1, bottom: sea, C(0x161030))
        var x = c.w * 26 / 100, i = 0
        while x < c.w + 10 * s {
            let bw = (7 + Int(noise(i * 7 + 501) * 9)) * s
            let h = Int(Double(10 * s) + noise(i * 7 + 502) * (maxH - Double(10 * s)))
            let base = sea - 3 * s, top = base - h
            let col = noise(i * 7 + 503) > 0.5 ? C(0x221A48) : C(0x1A1440)
            c.rect(x, top, bw, h, col)
            c.rect(x, top, s, h, C(0x3A3070))
            let crown = noise(i * 7 + 504)
            if crown > 0.62 {
                scenes5Peak(c, x + bw / 2, top - 6 * s, half: bw / 3, h: 6 * s, col)
                c.rect(x + bw / 2, top - 9 * s, s, 3 * s, col); c.rect(x + bw / 2, top - 9 * s, s, s, C(0xFF4A5A))
            } else if crown > 0.35 {
                c.rect(x + 2 * s, top - 2 * s, bw - 4 * s, 2 * s, col)
                c.rect(x + 2 * s, top - 2 * s, bw - 4 * s, s, C(0x8AE0FF, 0.45))
            }
            for v in stride(from: top + 2 * s, to: base - s, by: 3 * s) {
                for u in stride(from: x + 2 * s, to: x + bw - s, by: 2 * s) where noise(u * 13 + v * 7 + i) > 0.55 {
                    c.rect(u, v, s, s, noise(u + v * 3) > 0.75 ? C(0xFFD890, 0.75) : C(0x8AC8FF, 0.55))
                }
            }
            x += bw + (noise(i * 7 + 505) > 0.6 ? 3 * s : 0); i += 1
        }
    }

    /// A junk at anchor: a long hull rising to a high stern, and two battened lug sails fanning back from their
    /// masts, the after one taller; `y` is its waterline.
    static func madripoorJunk(_ c: PixelCanvas, _ x: Int, _ y: Int, _ k: Int) {
        let hull = [
            "........................hh.",
            "hh.....................hhh.",
            "hhhhhhhhhhhhhhhhhhhhhhhhhh",
            "dhwhhwhhwhhwhhhhhhhwhhhhhd",
            ".dddddddddddddddddddddddd.",
        ]
        let pal: [Character: Px] = ["h": C(0x2E1A1A), "d": C(0x1A0E12), "w": C(0xF0A050)]
        scenes5Stamp(c, x - 13 * k, y - 4 * k, hull, pal, s: k)
        madripoorSail(c, mast: x - 9 * k, foot: y - 3 * k, h: 12, w: 7, k: k)
        madripoorSail(c, mast: x + k, foot: y - 3 * k, h: 16, w: 10, k: k)
        // its reflection, broken by ripples
        for v in 0..<4 { c.rect(x - 13 * k + (v % 2) * k, y + k + v * k, 26 * k, max(1, k / 2), C(0x8A2E28, 0.18)) }
    }

    /// One junk sail: its mast, and the sail fanning back from it, its top edge rising aft, crossed by battens.
    static func madripoorSail(_ c: PixelCanvas, mast: Int, foot: Int, h: Int, w: Int, k: Int) {
        c.rect(mast, foot - (h + 2) * k, k, (h + 2) * k, C(0x2A1418))
        for u in 0..<w {
            let f = Double(u) / Double(w)
            let top = Int(Double(h) * 0.22 * (1 - f)), bottom = h - 1 - Int(Double(h) * 0.35 * f * f)
            guard bottom > top else { continue }
            for r in top...bottom {
                let batten = (r - h + 1) % 3 == 0 || r == top
                c.rect(mast + (u + 1) * k, foot - (h + 1) * k + r * k, k, k, batten ? C(0x4A1418) : (u < 2 ? C(0x9A3A2E) : C(0x8A2E28)))
            }
        }
    }

    /// One Lowtown shophouse: shuttered windows, air-conditioners and laundry above an arcade lit from inside.
    static func madripoorShop(_ c: PixelCanvas, _ b: MadripoorShop, _ g: Int) {
        let s = unit(g)
        let walls = [C(0x3A2438), C(0x2C2840), C(0x40282C), C(0x30303A)]
        let wall = b.bar ? C(0x2A1A2A) : walls[b.i % walls.count]
        let top = g - b.h
        c.rect(b.x, top, b.w, b.h, wall)
        c.rect(b.x - s, top, b.w + 2 * s, 2 * s, C(0x1A1220))
        c.rect(b.x + b.w - s, top, s, b.h, C(0x140E1A))
        if b.bar {
            // the Duchess Bar: its sign's dark board (the neon is in the moving layer), shuttered windows above
            let (sx, sy, sw, sh) = madripoorBarSign(b, g)
            for v in stride(from: top + 5 * s, to: sy - 8 * s, by: 10 * s) {
                for u in stride(from: b.x + 6 * s, to: b.x + b.w - 8 * s, by: 12 * s) {
                    c.rect(u, v, 6 * s, 6 * s, C(0x140C18)); c.rect(u + s, v + s, 4 * s, 4 * s, C(0xC85A8A, 0.5))
                }
            }
            c.rect(sx - s, sy - s, sw + 2 * s, sh + 2 * s, C(0x3A2440))
            c.rect(sx, sy, sw, sh, C(0x120812))
            scenes5TextCentred(c, sx + sw / 2, sy + 2 * s, "DUCHESS", C(0x5A2048), s: s)
            scenes5TextCentred(c, sx + sw / 2, sy + 8 * s, "BAR", C(0x204A58), s: s)
        } else {
            for v in stride(from: top + 5 * s, to: g - 24 * s, by: 10 * s) {
                for u in stride(from: b.x + 4 * s, to: b.x + b.w - 10 * s, by: 9 * s) {
                    let lit = noise(u * 3 + v * 5 + 7) > 0.45
                    c.rect(u, v, 5 * s, 6 * s, C(0x140C18))
                    if lit { c.rect(u + s, v + s, 3 * s, 4 * s, C(0xF0A860, 0.85)); c.rect(u + s, v + s, s, 4 * s, C(0xC06A3A)) }
                    c.rect(u - s, v + 6 * s, 7 * s, s, C(0x4A3A50))
                    if noise(u + v * 3) > 0.68 { c.rect(u, v + 7 * s, 4 * s, 2 * s, C(0x6A6A78)); c.rect(u + s, v + 8 * s, s, s, C(0x3A3A48)) }
                }
            }
            if b.i % 3 == 1 {          // a laundry pole across the facade
                let v = top + 13 * s
                c.rect(b.x + 2 * s, v, b.w - 6 * s, max(1, s / 2), C(0x6A5A50))
                for (k, col) in [C(0xD8D0C0), C(0x4A7AB0), C(0xC85A4A), C(0xE8C860)].enumerated() {
                    c.rect(b.x + (5 + k * 5) * s, v + s, 3 * s, (3 + k % 2) * s, col.alpha(0.8))
                }
            }
            // the backing of the vertical neon sign (it lights up in the moving layer)
            let n = madripoorNeonSpot(b, g)
            c.rect(n.x - s, n.y - s, 7 * s, n.h + 2 * s, C(0x0E0810))
            c.rect(n.x + 2 * s, n.y - 3 * s, s, 2 * s, C(0x0E0810))
        }
        // the arcade at street level, lit from inside
        c.rect(b.x, g - 16 * s, b.w, 2 * s, C(0x5A3A40))
        c.rect(b.x, g - 14 * s, b.w, 14 * s, C(0x120A16))
        c.rect(b.x + 3 * s, g - 12 * s, b.w - 6 * s, 12 * s, C(0xE89A50, b.bar ? 0.18 : 0.28))
        if b.bar { c.rect(b.x + b.w / 2 - 4 * s, g - 11 * s, 8 * s, 11 * s, C(0xFF5AA0, 0.35)) }
        else {
            c.rect(b.x + 5 * s, g - 5 * s, b.w - 12 * s, 5 * s, C(0x3A2018))       // a stall's counter
            c.rect(b.x + 5 * s, g - 5 * s, b.w - 12 * s, s, C(0x7A4A2A))
        }
        c.rect(b.x, g - 14 * s, 2 * s, 14 * s, C(0x2A1A26)); c.rect(b.x + b.w - 2 * s, g - 14 * s, 2 * s, 14 * s, C(0x2A1A26))
    }

    /// The Duchess Bar's sign board on its building: x, y, width, height.
    static func madripoorBarSign(_ b: MadripoorShop, _ g: Int) -> (Int, Int, Int, Int) {
        let s = unit(g)
        return (b.x + b.w / 2 - 18 * s, g - 32 * s, 36 * s, 14 * s)
    }

    /// Where a shophouse's vertical neon sign hangs: left, top and height.
    static func madripoorNeonSpot(_ b: MadripoorShop, _ g: Int) -> (x: Int, y: Int, h: Int) {
        let s = unit(g)
        return (b.x + b.w - 9 * s, g - 42 * s, 22 * s)
    }

    /// Full screen: low cloud lit magenta by the city, and more stars.
    static func madripoorHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<7 {
            let y = Int(Double(g) * (0.12 + 0.07 * Double(i))), x = Int(noise(i + 520) * Double(c.w))
            c.ellipse(x, y, (50 + Int(noise(i + 521) * 70)) * s, 3 * s, C(0x8A2A6A, 0.1 + 0.03 * Double(i)))
        }
    }

    /// The neon signs buzzing (one flickering now and then), the Duchess Bar's sign, lanterns swaying under the
    /// arcades and the neon's colours smeared across the wet street.
    static func madripoorMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let neon = [C(0xFF4AB0), C(0x4AF0FF), C(0x7AFF7A), C(0xFFD24A), C(0xFF6A4A)]
        for b in madripoorShops(c, g) {
            if b.bar {
                let (sx, sy, sw, sh) = madripoorBarSign(b, g)
                let barOn = noise(Int(t * 9) + 97) < 0.1 ? 0.45 : 1.0
                c.rect(sx - 3 * s, sy - 3 * s, sw + 6 * s, sh + 6 * s, C(0xFF4AB0, 0.08))
                c.rect(sx, sy, sw, s, C(0x4AF0FF, 0.8)); c.rect(sx, sy + sh - s, sw, s, C(0x4AF0FF, 0.8))
                scenes5TextCentred(c, sx + sw / 2, sy + 2 * s, "DUCHESS", C(0xFF6AC0), s: s)
                scenes5TextCentred(c, sx + sw / 2, sy + 8 * s, "BAR", C(0x7AF8FF, barOn), s: s)
                c.rect(sx, g + 2 * s, sw, max(1, (c.h - g) / 2), C(0xFF4AB0, 0.14))
            } else {
                let n = madripoorNeonSpot(b, g), col = neon[b.i % neon.count]
                let flick = noise(Int(t * 11) + b.i * 41) < 0.07 ? 0.15 : 1.0
                c.rect(n.x - 2 * s, n.y - 2 * s, 9 * s, n.h + 4 * s, col.alpha(0.1 * flick))
                c.rect(n.x, n.y, 5 * s, s, col.alpha(flick)); c.rect(n.x, n.y + n.h - s, 5 * s, s, col.alpha(flick))
                c.rect(n.x, n.y, s, n.h, col.alpha(flick)); c.rect(n.x + 4 * s, n.y, s, n.h, col.alpha(flick))
                for k in 0..<4 {                        // four characters' worth of strokes
                    let y = n.y + 2 * s + k * 5 * s, seed = b.i * 17 + k * 3
                    c.rect(n.x + s, y + Int(noise(seed) * 3) * s, 3 * s, s, col.alpha(flick))
                    c.rect(n.x + s + Int(noise(seed + 1) * 3) * s, y, s, 4 * s, col.alpha(flick))
                }
                c.rect(n.x, g + 2 * s, 5 * s, max(1, (c.h - g) / 2), col.alpha(0.16 * flick))
            }
            // lanterns under the arcade's eave, swaying
            for (k, u) in stride(from: b.x + 6 * s, to: b.x + b.w - 4 * s, by: 11 * s).enumerated() {
                let sway = Int((sin(t * 1.7 + Double(b.i * 3 + k)) * 1.3 * Double(s)).rounded())
                let ly = g - 14 * s
                c.rect(u, ly, max(1, s / 2), 2 * s, C(0x2A1A1A))
                c.rect(u + sway - s, ly + 2 * s, 3 * s, 4 * s, C(0xE0302A))
                c.rect(u + sway - 2 * s, ly + 3 * s, 5 * s, 2 * s, C(0xE0302A))
                c.rect(u + sway, ly + 3 * s, s, 2 * s, C(0xFFD27A))
                c.rect(u + sway - s, ly + 2 * s, 3 * s, max(1, s / 2), C(0x2A1414))
                c.rect(u + sway - 4 * s, ly, 9 * s, 9 * s, C(0xFF6A3A, 0.06))
            }
        }
        // the lantern on the mooring post, and the harbour's lights winking
        let px = c.w * 66 / 100, sway = Int((sin(t * 1.4) * 1.5 * Double(s)).rounded())
        c.rect(px + 5 * s, g - 21 * s, max(1, s / 2), 2 * s, C(0x2A1A1A))
        c.rect(px + 4 * s + sway, g - 19 * s, 3 * s, 4 * s, C(0xE0302A)); c.rect(px + 5 * s + sway, g - 18 * s, s, 2 * s, C(0xFFD27A))
        let sea = g - 15 * s
        for i in 0..<(c.w / 30) where noise(Int(t * 4) * 13 + i) > 0.5 {
            let x = Int(noise(i * 5 + 731) * Double(c.w)), y = sea + 2 * s + Int(noise(i * 5 + 732) * Double(g - sea - 6 * s))
            c.rect(x, y, 3 * s, max(1, s), C(0xFFE0B0, 0.45))
        }
    }
}

// MARK: - Sokovia

extension Scenes {
    /// The floating chunk of Novi Grad: its centre, the row its streets stand on, and its scale.
    static func sokoviaChunk(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, k: Int) {
        let s = unit(g)
        if isTall(c) { return (c.w * 58 / 100, g * 36 / 100, 2 * s) }
        return (c.w * 58 / 100, 26 * s, s)
    }

    /// How far the chunk's rocky underside hangs below its streets, `u` units from its centre (in units).
    static func sokoviaDepth(_ u: Int) -> Int {
        let e = min(1, Double(abs(u)) / 36)
        return Int(17 * (1 - pow(e, 1.6)) + 2 + noise(u * 3 + 811) * 3)
    }

    /// Sokovia, the Battle of Sokovia: the heart of Novi Grad torn out of the ground and hanging in the sky, its
    /// church's bell tower standing among the old town's red roofs on top and raw rock dangling underneath; on the
    /// ground, the rest of the old town around the smoking crater it came from, with rubble and a shattered wall
    /// in front.
    static func sokovia(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x46607A), C(0xCCC8BC), bands: 7)
        if tall { sokoviaHigh(c, g) }
        c.dunes(base: g - 17 * s, amp: Double(4 * s), freq: 0.015, phase: 0.4, bottom: g, C(0x9AA0A2))
        c.dunes(base: g - 12 * s, amp: Double(3 * s), freq: 0.03, phase: 2, bottom: g, C(0x7E8888))
        let f = sokoviaChunk(c, g)
        // smoke rising from the crater it left
        for k in 0..<9 {
            let y = g - 9 * s - k * 5 * s, x = f.x - 8 * s + k * 3 * s + Int((noise(k + 855) - 0.5) * 10) * s
            c.ellipse(x, y, (5 + k * 2) * s, (3 + k) * s, C(0x5E5E62, 0.24 - 0.02 * Double(k)))
        }
        sokoviaTown(c, g, gap: f.x, far: true)
        sokoviaTown(c, g, gap: f.x, far: false)
        sokoviaCrater(c, g, x: f.x)
        sokoviaChunkDraw(c, f.x, f.y, f.k)
        // a few rocks hanging in the air beside it
        for i in 0..<8 {
            let side = i % 2 == 0 ? -1 : 1
            let x = f.x + side * (38 + Int(noise(i + 840) * 16)) * f.k, y = f.y + Int((noise(i + 841) - 0.3) * 20) * f.k
            let r = (1 + Int(noise(i + 842) * 2)) * f.k
            c.rect(x, y, r * 2, r + f.k, C(0x5A524A)); c.rect(x, y, r * 2, f.k, C(0x8A8070))
        }
        sokoviaForeground(c, g)
        c.ground(g, C(0x5A564E), edge: C(0x7A766C), speck: C(0x4A463E), seed: 52)
        for y in stride(from: g + 2 * s, to: c.h, by: 3 * s) {
            for x in stride(from: (y / (3 * s)) % 2 * 3 * s, to: c.w, by: 6 * s) { c.rect(x, y, s, s, C(0x4E4A44)) }
        }
    }

    /// A row of the old town's houses: pastel walls under steep red roofs, broken off around the crater at `gap`.
    static func sokoviaTown(_ c: PixelCanvas, _ g: Int, gap: Int, far: Bool) {
        let s = unit(g), base = far ? g - 9 * s : g - 4 * s, seed = far ? 860 : 880
        let walls = [C(0xD8CCB0), C(0xC4B49A), C(0xB8A48A), C(0xCAB8A0), C(0xA89880)]
        let haze = C(0xA8B0B4)
        var x = -Int(noise(seed) * 10) * s, i = 0
        while x < c.w {
            let bw = (10 + Int(noise(seed + i * 3) * 7)) * s
            let h = (far ? 12 : 8) * s + Int(noise(seed + i * 3 + 1) * 7) * s
            let mid = x + bw / 2
            if abs(mid - gap) < (far ? 30 : 24) * s { x += bw; i += 1; continue }
            var wall = walls[(i + (far ? 2 : 0)) % walls.count], roof = noise(seed + i * 3 + 2) > 0.3 ? C(0x9A3E2A) : C(0x6A4A3A)
            if far { wall = lerp(wall, haze, 0.5); roof = lerp(roof, haze, 0.5) }
            c.rect(x, base - h, bw - s, h, wall)
            c.rect(x + bw - 2 * s, base - h, s, h, lerp(wall, C(0x000000), 0.2))
            scenes5Peak(c, x + bw / 2 - s, base - h - 6 * s, half: bw / 2, h: 6 * s, roof)
            if noise(seed + i * 7) > 0.6 { c.rect(x + bw / 4, base - h - 6 * s, 2 * s, 4 * s, roof) }    // a chimney
            for v in stride(from: base - h + 2 * s, to: base - 2 * s, by: 5 * s) {
                for u in stride(from: x + 2 * s, to: x + bw - 3 * s, by: 4 * s) {
                    c.rect(u, v, 2 * s, 3 * s, far ? lerp(C(0x3A3A40), haze, 0.5) : C(0x3A3A40))
                }
            }
            x += bw; i += 1
        }
    }

    /// The crater where Novi Grad's heart was torn out: a ragged dark hole, half-houses broken at its rim.
    static func sokoviaCrater(_ c: PixelCanvas, _ g: Int, x: Int) {
        let s = unit(g), half = 26 * s
        for u in -half...half {
            let e = Double(abs(u)) / Double(half)
            let far = g - 7 * s - Int(noise(u * 3 + 871) * 2) * s
            c.rect(x + u, far, 1, g - far, C(0x2E2826))                                // the pit beyond the near rim
            let rim = Int((1 - e * e) * Double(3 * s)) + Int(noise(u + 870) * 2) * s   // rubble heaped on the near rim
            c.rect(x + u, g - rim - s, 1, rim + s, noise(u * 7 + 872) > 0.5 ? C(0x6A6056) : C(0x564E46))
        }
        // broken houses at its edges, with jagged tops
        for side in [-1, 1] {
            let hx = x + side * (half + 2 * s) - (side < 0 ? 10 * s : 0)
            for k in 0..<(10 * s) {
                let h = 6 * s + Int(noise(k + side * 50 + 875) * 6) * s
                c.rect(hx + k, g - 4 * s - h, 1, h, C(0xB0A08A))
            }
            c.rect(hx + 3 * s, g - 9 * s, 2 * s, 3 * s, C(0x3A3A40))
        }
    }

    /// The torn-out city in the sky: rock hanging underneath, the old town's houses and the church on top.
    static func sokoviaChunkDraw(_ c: PixelCanvas, _ x: Int, _ y: Int, _ k: Int) {
        let half = 36
        for u in -half...half {
            let d = sokoviaDepth(u)
            let col = u < -half / 3 ? C(0x6E645A) : (u < half / 3 ? C(0x5A5048) : C(0x4A423C))
            c.rect(x + u * k, y + k, k, d * k, col)
            for band in [4, 9, 13] where band < d - 1 {
                c.rect(x + u * k, y + band * k + Int(noise(u + band) * 2) * k, k, k, C(0x3E3632))
            }
            c.rect(x + u * k, y + d * k, k, k, C(0x2E2824))
            if noise(u * 5 + 820) > 0.82 {           // a torn pipe or root dangling
                c.rect(x + u * k, y + (d + 1) * k, max(1, k / 2), (2 + Int(noise(u + 821) * 4)) * k, C(0x3A322C))
            }
        }
        c.rect(x - half * k, y - k, (2 * half + 1) * k, 2 * k, C(0x7A6E5E))
        c.rect(x - half * k, y - k, (2 * half + 1) * k, k, C(0x9A8E78))
        // houses either side of the church
        let walls = [C(0xD8CCB0), C(0xC4B49A), C(0xCAB8A0)]
        for (i, u) in stride(from: -34, to: 30, by: 8).enumerated() where u < -14 || u > 8 {
            let h = 5 + Int(noise(i + 830) * 4), wall = walls[i % walls.count]
            c.rect(x + u * k, y - (h + 1) * k, 7 * k, h * k, wall)
            scenes5Peak(c, x + u * k + 3 * k, y - (h + 5) * k, half: 4 * k, h: 4 * k, C(0x9A3E2A))
            c.rect(x + (u + 2) * k, y - (h - 1) * k, k, 2 * k, C(0x3A3A40)); c.rect(x + (u + 4) * k, y - (h - 1) * k, k, 2 * k, C(0x3A3A40))
        }
        // the church: its nave, and the bell tower with its spire and cross
        let stone = C(0xC2B8A4), shade = C(0x8E8474)
        c.rect(x - 12 * k, y - 10 * k, 18 * k, 9 * k, stone)
        scenes5Peak(c, x - 3 * k, y - 15 * k, half: 10 * k, h: 5 * k, C(0x5A4E48))
        for u in [-10, -6, -2] {
            c.rect(x + u * k, y - 8 * k, 2 * k, 4 * k, C(0x3A3640)); c.rect(x + u * k, y - 9 * k, 2 * k, k, shade)
        }
        c.rect(x + 4 * k, y - 17 * k, 7 * k, 16 * k, stone)
        c.rect(x + 9 * k, y - 17 * k, 2 * k, 16 * k, shade)
        c.rect(x + 3 * k, y - 17 * k, 9 * k, k, shade)
        c.rect(x + 6 * k, y - 15 * k, 2 * k, 3 * k, C(0x2A2630))               // the belfry
        c.rect(x + 6 * k, y - 8 * k, 2 * k, 2 * k, C(0x2A2630))
        scenes5Peak(c, x + 7 * k, y - 23 * k, half: 3 * k, h: 6 * k, C(0x4E5A58))
        c.rect(x + 7 * k, y - 26 * k, k, 3 * k, C(0x3A3A3A)); c.rect(x + 6 * k, y - 25 * k, 3 * k, k, C(0x3A3A3A))
        // the lit side of the rock
        for u in -half...(-half / 2) { c.px(x + u * k, y + k, C(0xB0A48E)) }
    }

    /// In front: a shattered wall with an empty window, heaps of rubble and an overturned car.
    static func sokoviaForeground(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let wx = 4 * s
        for k in 0..<(22 * s) {
            let h = 14 * s + Int(sin(Double(k) / Double(4 * s)) * 4 * Double(s)) + Int(noise(k + 890) * 3) * s - k / 3
            c.rect(wx + k, g - h, 1, h, C(0x8A7A6A))
        }
        c.rect(wx + 6 * s, g - 11 * s, 5 * s, 6 * s, C(0x3A3438)); c.rect(wx + 6 * s, g - 5 * s, 5 * s, s, C(0x6A5E52))
        for v in stride(from: g - 14 * s, to: g, by: 3 * s) { c.rect(wx, v, 16 * s, max(1, s / 2), C(0x7A6A5C)) }
        for (cx, r) in [(c.w * 30 / 100, 6), (c.w * 74 / 100, 8), (wx + 26 * s, 5)] {
            for i in 0..<(r * 3) {
                let x = cx + Int((noise(i + cx) - 0.5) * Double(r * 3)) * s
                let sz = (1 + Int(noise(i + cx + 1) * 3)) * s
                let lift = Int(Double(r) * (1 - abs(Double(x - cx)) / Double(r * 2 * s))) * s / 2
                c.rect(x, g - sz - max(0, lift), sz + s, sz + max(0, lift), noise(i + cx + 2) > 0.5 ? C(0x7A7064) : C(0x5E564C))
            }
        }
        // the overturned car
        let ox = c.w * 88 / 100
        c.rect(ox - 10 * s, g - 7 * s, 20 * s, 4 * s, C(0x6A2E2A)); c.rect(ox - 7 * s, g - 3 * s, 14 * s, 3 * s, C(0x4A1E1C))
        c.rect(ox - 6 * s, g - 2 * s, 4 * s, 2 * s, C(0x5A7A8A, 0.6)); c.rect(ox + 2 * s, g - 2 * s, 4 * s, 2 * s, C(0x5A7A8A, 0.6))
        for u in [-7, 5] { c.rect(ox + u * s, g - 10 * s, 3 * s, 3 * s, C(0x1A1A1E)); c.rect(ox + (u + 1) * s, g - 9 * s, s, s, C(0x5A5A60)) }
    }

    /// Full screen: grey cloud and smoke higher up, and the far mountains.
    static func sokoviaHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.dunes(base: g - g / 6, amp: Double(g / 14), freq: 0.011, phase: 0.8, bottom: g, C(0xA2AAB0), shade: C(0xB8BEC2))
        c.dunes(base: g - g / 9, amp: Double(g / 18), freq: 0.019, phase: 2.6, bottom: g, C(0x949EA4))
        for i in 0..<9 {
            let y = Int(Double(g) * (0.06 + 0.06 * Double(i))), x = Int(noise(i + 850) * Double(c.w))
            Scenes.cloud(c, x, y, (4 + Int(noise(i + 851) * 4)) * s, seed: i + 852, top: C(0xB8BCBE, 0.6), base: C(0x8A9098, 0.5))
        }
    }

    /// Debris crumbling off the chunk's underside and falling, rocks bobbing beside it, and Ultron's drones
    /// darting around the sky, eyes red, thrusters burning.
    static func sokoviaMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = sokoviaChunk(c, g)
        for i in 0..<18 {
            let u = Int((noise(i * 3 + 900) - 0.5) * 56)
            let p = scenes5Phase(t, 1.4 + noise(i * 3 + 901), offset: noise(i * 3 + 902))
            let y0 = f.y + (sokoviaDepth(u) + 1) * f.k
            let fall = Double(g - y0) * 0.9
            let y = y0 + Int(p * p * fall), x = f.x + u * f.k + Int(p * 6 * (noise(i + 903) - 0.5)) * s
            let sz = (noise(i + 904) > 0.7 ? 2 : 1) * f.k
            c.rect(x, y, sz, sz, C(0x4A423A, 1 - p * 0.7))
            if i % 3 == 0 { c.rect(x - s, y - 3 * s, sz, 2 * s, C(0x9A9488, 0.3 * (1 - p))) }
        }
        let rows = [".sss.", ".rsr.", "..s..", "sssss", "s.s.s", "..s..", ".s.s."]
        let pal: [Character: Px] = ["s": C(0xC8CCD4), "r": C(0xFF2A2A)]
        for i in 0..<6 {
            let period = 1.3 + noise(i + 910) * 0.8
            let q = t / period + noise(i + 911) * 7
            let seg = Int(floor(q)), fr = q - floor(q)
            let e = min(1, fr * 3), ease = e * e * (3 - 2 * e)
            func way(_ n: Int) -> (Double, Double) {
                (Double(c.w) * (0.04 + 0.92 * noise(n * 7 + i * 131 + 920)),
                 Double(4 * s) + Double(g - 30 * s) * noise(n * 7 + i * 131 + 921))
            }
            let a = way(seg), b = way(seg + 1)
            let x = Int(a.0 + (b.0 - a.0) * ease), y = Int(a.1 + (b.1 - a.1) * ease)
            if e < 1 {                               // a streak behind it while it darts
                c.glowLine(a.0 + (b.0 - a.0) * max(0, ease - 0.25), a.1 + (b.1 - a.1) * max(0, ease - 0.25) + Double(3 * s),
                           Double(x + 2 * s), Double(y + 3 * s), core: C(0xC8E0FF, 0.25), glow: C(0x8AB8FF, 0.15), coreR: 0.5, glowR: 1.5)
            }
            scenes5Stamp(c, x, y, rows, pal, s: s)
            let flame = noise(Int(t * 20) + i) > 0.5 ? 2 : 1
            c.rect(x + s, y + 7 * s, s, flame * s, C(0x8AD8FF)); c.rect(x + 3 * s, y + 7 * s, s, flame * s, C(0x8AD8FF))
        }
    }
}

// MARK: - Galactus' Worldship

extension Scenes {
    /// One of the worldship's energy conduits: where it starts, how long it runs, which way, and how thick.
    struct WorldshipPipe { let x, y, len, thick: Int; let down: Bool }

    /// The viewport: its centre and its oval's radii.
    struct WorldshipPort { let x, y, rx, ry: Int }

    /// The great viewport, a wide oval in the window's strip and nearly round full screen: centre and radii.
    static func worldshipPort(_ c: PixelCanvas, _ g: Int) -> WorldshipPort {
        let tall = isTall(c)
        let ry = Int(Double(g) * (tall ? 0.36 : 0.39))
        let rx = min(c.w * 30 / 100, tall ? ry * 5 / 4 : ry * 13 / 5)
        return WorldshipPort(x: c.w / 2, y: Int(Double(g) * 0.42), rx: rx, ry: ry)
    }

    /// Where a point `a` radians round the viewport's oval lies, pushed `out` pixels beyond its edge.
    static func worldshipRim(_ v: WorldshipPort, _ a: Double, out: Int = 0) -> (x: Int, y: Int) {
        (v.x + Int(cos(a) * Double(v.rx + out)), v.y + Int(sin(a) * Double(v.ry + out)))
    }

    /// The conduits: one running along under the viewport, two climbing either side of it (and more full screen).
    static func worldshipPipes(_ c: PixelCanvas, _ g: Int) -> [WorldshipPipe] {
        let s = unit(g), v = worldshipPort(c, g), th = 5 * s
        var out = [WorldshipPipe(x: 0, y: g - 10 * s, len: c.w, thick: th, down: false)]
        for side in [-1, 1] {
            out.append(WorldshipPipe(x: v.x + side * (v.rx + 22 * s) - th / 2, y: 0, len: g - 10 * s, thick: th, down: true))
        }
        if isTall(c) {
            out.append(WorldshipPipe(x: 0, y: v.y + v.ry + 18 * s, len: c.w, thick: th + 2 * s, down: false))
            for side in [-1, 1] {
                out.append(WorldshipPipe(x: v.x + side * (v.rx + 70 * s) - th / 2, y: 0, len: g - 10 * s, thick: th, down: true))
            }
        }
        return out
    }

    /// Galactus' Worldship, inside the devourer's vessel: walls of vast purple machinery, ribbed and studded with
    /// Kirby-style discs and vents, glowing conduits running along them, and a great round viewport looking out on
    /// a blue-green world being torn apart and drawn up into the ship along beams of cosmic energy.
    static func worldship(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        worldshipWalls(c, g)
        let v = worldshipPort(c, g)
        worldshipView(c, g, v)
        worldshipFrame(c, g, v)
        for p in worldshipPipes(c, g) { worldshipPipe(c, p, s) }
        // pylons standing at the deck's edges, their tops glowing
        for x in [c.w * 9 / 100, c.w * 91 / 100] {
            c.rect(x - 4 * s, g - 12 * s, 8 * s, 12 * s, C(0x2A1648)); c.rect(x - 4 * s, g - 12 * s, s, 12 * s, C(0x5A3A90))
            c.rect(x - 6 * s, g - 14 * s, 12 * s, 2 * s, C(0x3E2470))
            c.rect(x - 2 * s, g - 9 * s, 4 * s, 2 * s, C(0xD87AFF, 0.6))
        }
        c.ground(g, C(0x1C1030), edge: C(0x7A4AC8), speck: C(0x2A1A44), seed: 53)
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + s, s, c.h - g, C(0x140A26)) }
    }

    /// The machinery wall: tall ribs and between them panels with discs, vents and banks of little lights.
    static func worldshipWalls(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x1E0E3A), C(0x34195C), bands: 6)
        let seam = C(0x160A2C), rib = C(0x3E2470), ribLit = C(0x6A48A6), ribDark = C(0x1E0C3A)
        for y in stride(from: 6 * s, to: g, by: 12 * s) { c.rect(0, y, c.w, s, seam) }
        for (i, x) in stride(from: -4 * s, to: c.w, by: 32 * s).enumerated() {
            c.rect(x, 0, 9 * s, g, rib); c.rect(x, 0, s, g, ribLit); c.rect(x + 8 * s, 0, s, g, ribDark)
            for y in stride(from: 3 * s, to: g, by: 7 * s) { c.rect(x + 3 * s, y, 3 * s, 2 * s, ribDark) }
            for (k, y) in stride(from: 9 * s, to: g - 16 * s, by: 18 * s).enumerated() {
                let gx = x + 13 * s + Int(noise(i * 13 + k) * 6) * s
                switch Int(noise(i * 13 + k + 50) * 3) {
                case 0:
                    c.circle(gx + 5 * s, y + 5 * s, 5 * s, ribDark); c.circle(gx + 5 * s, y + 5 * s, 3 * s, C(0x5A3494))
                    c.circle(gx + 5 * s, y + 5 * s, s, C(0xE08AFF))
                case 1:
                    c.rect(gx, y, 12 * s, 8 * s, ribDark)
                    for u in 0..<4 { c.rect(gx + (1 + u * 3) * s, y + 2 * s, s, s, u % 2 == 0 ? C(0xFF6AD0) : C(0x6AE0FF)) }
                    c.rect(gx + s, y + 5 * s, 10 * s, s, C(0x6A3AA0))
                default:
                    for u in 0..<5 { c.rect(gx + u * 2 * s, y, s, 10 * s, seam) }
                }
            }
        }
        // the ceiling's shadow
        c.rect(0, 0, c.w, 2 * s, C(0x0E0620, 0.6))
    }

    /// Out of the viewport: deep space and a world being devoured, torn open and pulled up along the beam.
    static func worldshipView(_ c: PixelCanvas, _ g: Int, _ v: WorldshipPort) {
        func reach(_ x: Int, _ y: Int) -> Double {
            let dx = Double(x - v.x) / Double(v.rx), dy = Double(y - v.y) / Double(v.ry)
            return (dx * dx + dy * dy).squareRoot()
        }
        func inside(_ x: Int, _ y: Int) -> Bool { reach(x, y) <= 1 }
        for y in (v.y - v.ry)...(v.y + v.ry) {
            for x in (v.x - v.rx)...(v.x + v.rx) {
                let d = reach(x, y)
                guard d <= 1 else { continue }
                c.px(x, y, lerp(C(0x06030E), C(0x2A1250), d > 0.7 ? (d - 0.7) * 3 : 0))
            }
        }
        // a faint nebula, and the stars
        for i in 0..<6 {
            let x = v.x - v.rx / 2 + Int(noise(i + 940) * Double(v.rx)), y = v.y - v.ry / 2 + Int(noise(i + 941) * Double(v.ry) * 0.6)
            let rx = v.rx / 4 + Int(noise(i + 942) * Double(v.rx) / 4), ry = max(1, rx / 3)
            for yy in (y - ry)...(y + ry) {
                for xx in (x - rx)...(x + rx) where inside(xx, yy) {
                    let ex = Double(xx - x) / Double(rx), ey = Double(yy - y) / Double(ry)
                    if ex * ex + ey * ey <= 1 { c.px(xx, yy, C(0x6A2A8A, 0.08)) }
                }
            }
        }
        c.stars(v.y - v.ry, v.y + v.ry, density: 26, seed: 53, x0: v.x - v.rx, x1: v.x + v.rx, inside: inside)
        // the world: oceans and land, its night side in shadow, an atmosphere on its lit limb
        let p = worldshipPlanet(v)
        let cell = max(1, p.r / 7)
        for y in (p.y - p.r)...(p.y + p.r) {
            for x in (p.x - p.r)...(p.x + p.r) where inside(x, y) {
                let dx = x - p.x, dy = y - p.y, d2 = dx * dx + dy * dy
                guard d2 <= p.r * p.r else { continue }
                let n1 = noise((x / cell) * 31 + (y / cell) * 57 + 950), n2 = noise((x / cell / 2) * 13 + (y / cell / 2) * 29 + 951)
                let land = n1 + n2 > 1.15
                var col = land ? C(0x4A9A4A) : C(0x2A6AB8)
                if land && noise(x * 7 + y * 3) > 0.85 { col = C(0x6AB05A) }
                let lightK = Double(dx + dy) / Double(p.r * 2)
                if lightK > 0.15 { col = lerp(col, C(0x0A0820), min(0.85, (lightK - 0.15) * 2.2)) }
                let rim = p.r - max(1, p.r / 9)
                if d2 > rim * rim && lightK < 0 { col = lerp(col, C(0xA8E0FF), 0.5) }
                c.px(x, y, col)
            }
        }
        // the crust broken open where the beam strikes, chunks lifting away
        let b = worldshipBeam(v)
        c.circle(Int(b.x1), Int(b.y1), max(2, p.r / 3), C(0x5A1A10))
        c.circle(Int(b.x1), Int(b.y1), max(1, p.r / 4), C(0xE8642A))
        for i in 0..<14 {
            let a = Double(i) / 14 * 2 * .pi
            let rr = Double(p.r) * (0.3 + noise(i + 960) * 0.45)
            c.glowLine(b.x1, b.y1, b.x1 + cos(a) * rr, b.y1 + sin(a) * rr, core: C(0xFFC86A, 0.8), glow: C(0xFF6A2A, 0.45), coreR: 0.4, glowR: 1.2)
        }
        let beamR = Double(max(2, v.ry / 9))
        c.glowLine(b.x0, b.y0, b.x1, b.y1, core: C(0xF8E8FF), glow: C(0xB060FF), coreR: beamR / 3, glowR: beamR, strength: 0.75)
        for i in 0..<8 {                                         // rubble already rising
            let q = 0.15 + 0.8 * noise(i + 965)
            let x = b.x1 + (b.x0 - b.x1) * q + (noise(i + 966) - 0.5) * beamR * 3
            let y = b.y1 + (b.y0 - b.y1) * q + (noise(i + 967) - 0.5) * beamR * 3
            let sz = max(1, Int(Double(p.r) / 10 * (1.2 - q)))
            c.rect(Int(x), Int(y), sz + 1, sz, C(0x3A5A3A)); c.px(Int(x), Int(y), C(0x8AC07A))
        }
        c.circle(Int(b.x1), Int(b.y1), max(1, p.r / 7), C(0xFFF4D8))
    }

    /// The world in the viewport: centre and radius.
    static func worldshipPlanet(_ v: WorldshipPort) -> (x: Int, y: Int, r: Int) {
        (v.x + v.rx * 3 / 10, v.y + v.ry * 25 / 100, v.ry * 55 / 100)
    }

    /// The devouring beam: from the viewport's upper-left edge to where it strikes the world.
    static func worldshipBeam(_ v: WorldshipPort) -> (x0: Double, y0: Double, x1: Double, y1: Double) {
        let p = worldshipPlanet(v)
        let a = -2.35
        let x0 = Double(v.x) + cos(a) * Double(v.rx) * 0.97, y0 = Double(v.y) + sin(a) * Double(v.ry) * 0.97
        let dx = x0 - Double(p.x), dy = y0 - Double(p.y), d = (dx * dx + dy * dy).squareRoot()
        let hit = Double(p.r) * 0.72
        return (x0, y0, Double(p.x) + dx / d * hit, Double(p.y) + dy / d * hit)
    }

    /// The viewport's heavy rim: bands of purple metal, lit from above, with blocks bolted round it.
    static func worldshipFrame(_ c: PixelCanvas, _ g: Int, _ v: WorldshipPort) {
        let s = unit(g), thick = 6 * s
        for y in (v.y - v.ry - thick)...(v.y + v.ry + thick) {
            for x in (v.x - v.rx - thick)...(v.x + v.rx + thick) {
                let dx = Double(x - v.x), dy = Double(y - v.y)
                let a = atan2(dy / Double(v.ry), dx / Double(v.rx))
                let ex = cos(a) * Double(v.rx), ey = sin(a) * Double(v.ry)
                let inner = (ex * ex + ey * ey).squareRoot(), d = (dx * dx + dy * dy).squareRoot()
                guard d > inner, d <= inner + Double(thick) else { continue }
                let band = Int(d - inner) / max(1, 2 * s)
                let up = -sin(a)
                var col = band == 1 ? C(0x2A1450) : C(0x4E2C88)
                if up > 0.3 { col = lerp(col, C(0x8A64C8), up - 0.3) } else if up < -0.3 { col = lerp(col, C(0x120828), -up - 0.3) }
                c.px(x, y, col)
            }
        }
        for i in 0..<worldshipBolts {
            let r = worldshipRim(v, Double(i) / Double(worldshipBolts) * 2 * .pi, out: 3 * s)
            c.rect(r.x - 2 * s, r.y - 2 * s, 4 * s, 4 * s, C(0x1E0C3A)); c.rect(r.x - s, r.y - s, 2 * s, 2 * s, C(0x6A3AA0))
        }
    }

    /// How many blocks are bolted round the viewport.
    static let worldshipBolts = 16

    /// One conduit: a thick tube with a lit edge, a dim channel of energy down its middle and collars along it.
    static func worldshipPipe(_ c: PixelCanvas, _ p: WorldshipPipe, _ s: Int) {
        let base = C(0x4A2A7A), lit = C(0x8A64C0), dark = C(0x1E0E36), chan = C(0x7A3AC0)
        if p.down {
            c.rect(p.x, p.y, p.thick, p.len, base); c.rect(p.x, p.y, s, p.len, lit); c.rect(p.x + p.thick - s, p.y, s, p.len, dark)
            c.rect(p.x + p.thick / 2, p.y, s, p.len, chan)
            for y in stride(from: p.y + 6 * s, to: p.y + p.len, by: 16 * s) { c.rect(p.x - s, y, p.thick + 2 * s, 3 * s, C(0x2E1856)); c.rect(p.x - s, y, p.thick + 2 * s, s, lit) }
        } else {
            c.rect(p.x, p.y, p.len, p.thick, base); c.rect(p.x, p.y, p.len, s, lit); c.rect(p.x, p.y + p.thick - s, p.len, s, dark)
            c.rect(p.x, p.y + p.thick / 2, p.len, s, chan)
            for x in stride(from: p.x + 6 * s, to: p.x + p.len, by: 20 * s) { c.rect(x, p.y - s, 3 * s, p.thick + 2 * s, C(0x2E1856)); c.rect(x, p.y - s, s, p.thick + 2 * s, lit) }
        }
    }

    /// Pulses of energy racing along the conduits, the world's matter streaming up the beam ringed by Kirby
    /// crackle, and the lights round the viewport chasing.
    static func worldshipMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        for (n, p) in worldshipPipes(c, g).enumerated() {
            for k in 0..<3 {
                let q = scenes5Phase(t, Double(p.len) / Double(70 * s), offset: Double(k) / 3 + noise(n + 970))
                let at = Int(q * Double(p.len + 8 * s)) - 4 * s
                if p.down {
                    let y = p.y + p.len - at
                    c.rect(p.x - s, y - 2 * s, p.thick + 2 * s, 8 * s, C(0xD87AFF, 0.25))
                    c.rect(p.x + p.thick / 2 - s, y, 3 * s, 4 * s, C(0xF8D8FF))
                } else {
                    let x = n % 2 == 0 ? p.x + at : p.x + p.len - at
                    c.rect(x - 2 * s, p.y - s, 8 * s, p.thick + 2 * s, C(0xD87AFF, 0.25))
                    c.rect(x, p.y + p.thick / 2 - s, 4 * s, 3 * s, C(0xF8D8FF))
                }
            }
        }
        let v = worldshipPort(c, g), b = worldshipBeam(v)
        for i in 0..<10 {
            let q = scenes5Phase(t, 1.6, offset: Double(i) / 10)
            let x = b.x1 + (b.x0 - b.x1) * q + (noise(i + 980) - 0.5) * Double(v.ry) * 0.12
            let y = b.y1 + (b.y0 - b.y1) * q + (noise(i + 981) - 0.5) * Double(v.ry) * 0.12
            let sz = max(1, Int(Double(v.ry) / 16 * (1 - q * 0.6)))
            c.rect(Int(x), Int(y), sz, sz, C(0x6A8A5A))
            c.px(Int(x), Int(y), C(0xFFE0A0, 0.8))
        }
        for i in 0..<5 where noise(Int(t * 6) * 7 + i) > 0.4 {         // Kirby crackle along the beam
            let q = noise(Int(t * 6) * 11 + i)
            let x = b.x1 + (b.x0 - b.x1) * q, y = b.y1 + (b.y0 - b.y1) * q
            c.circle(Int(x) + (i % 3 - 1) * 2 * s, Int(y) + (i % 2) * 2 * s, max(1, v.ry / 40), C(0x0A0414))
        }
        let n = worldshipBolts, lead = Int(t * 8) % n
        for i in 0..<n where i == lead || (i + n / 2) % n == lead {
            let (x, y) = worldshipRim(v, Double(i) / Double(n) * 2 * .pi, out: 3 * s)
            c.rect(x - s, y - s, 2 * s, 2 * s, C(0xFFB0FF)); c.rect(x - 3 * s, y - 3 * s, 6 * s, 6 * s, C(0xD87AFF, 0.25))
        }
    }
}

// MARK: - Harlem

extension Scenes {
    /// Where Pop's Barber Shop and the Apolla stand along the block: their left edges.
    static func harlemSpots(_ c: PixelCanvas, _ g: Int) -> (pops: Int, apollo: Int) {
        (c.w * 15 / 100, c.w * 60 / 100)
    }

    /// The Apolla's vertical sign: left, top, width, height.
    static func harlemApolloSign(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, w: Int, h: Int) {
        let s = unit(g), a = harlemSpots(c, g).apollo
        return (a + 28 * s, g - 61 * s, 9 * s, 40 * s)
    }

    /// The Apolla's marquee: left, top, width, height.
    static func harlemMarquee(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, w: Int, h: Int) {
        let s = unit(g), a = harlemSpots(c, g).apollo
        return (a - 4 * s, g - 21 * s, 72 * s, 10 * s)
    }

    /// Harlem, a block at sunset: a row of brownstones and brick tenements with stoops, cornices and fire
    /// escapes, Pop's Barber Shop with its striped awning and pole, and the Apolla Theater's tall red sign and
    /// marquee, under an orange and pink sky with pigeons on the cornices.
    static func harlem(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g / 2, C(0x2C3A78), C(0xD8788A), bands: 6)
        c.gradient(g / 2, g, C(0xD8788A), C(0xFFBE70), bands: 6)
        let sunX = c.w * 42 / 100, sunY = isTall(c) ? g * 36 / 100 : g * 62 / 100
        c.circle(sunX, sunY, 12 * s, C(0xFFE0A0, 0.3)); c.circle(sunX, sunY, 7 * s, C(0xFFE8B8))
        for i in 0..<6 {
            let x = Int(noise(i + 1000) * Double(c.w)), y = Int(Double(g) * (0.1 + 0.4 * noise(i + 1001)))
            Scenes.wisp(c, x, y, (30 + Int(noise(i + 1002) * 50)) * s, C(0xFFB89A, 0.55), s: s)
        }
        if isTall(c) { harlemHigh(c, g) }
        let spot = harlemSpots(c, g)
        harlemRow(c, g, from: -3 * s, to: spot.pops, seed: 1)
        harlemRow(c, g, from: spot.pops + 56 * s, to: spot.apollo, seed: 2)
        harlemRow(c, g, from: spot.apollo + 64 * s, to: c.w + 3 * s, seed: 3)
        harlemPops(c, g, spot.pops)
        harlemApollo(c, g, spot.apollo)
        // the sidewalk, the curb and a slice of street, a hydrant and a lamp
        c.ground(g, C(0x7A706A), edge: C(0x9A9088), speck: C(0x6E6660), seed: 54)
        for x in stride(from: 0, to: c.w, by: 14 * s) { c.rect(x, g + s, max(1, s / 2), (c.h - g) * 2 / 3, C(0x6A625C)) }
        let curb = g + (c.h - g) * 2 / 3
        c.rect(0, curb, c.w, c.h - curb, C(0x3A3638)); c.rect(0, curb, c.w, s, C(0xA89E94))
        let hx = c.w * 47 / 100
        c.rect(hx, g - 5 * s, 3 * s, 5 * s, C(0xC8302A)); c.rect(hx - s, g - 6 * s, 5 * s, s, C(0xA8241E))
        c.rect(hx - s, g - 3 * s, 5 * s, s, C(0xA8241E)); c.rect(hx + s, g - 7 * s, s, s, C(0xC8302A))
        for lx in [c.w * 9 / 100, c.w * 92 / 100] {
            c.rect(lx, g - 30 * s, s, 30 * s, C(0x1E1E24)); c.rect(lx, g - 30 * s, 5 * s, s, C(0x1E1E24))
            c.rect(lx + 3 * s, g - 29 * s, 3 * s, 2 * s, C(0x2A2A30)); c.rect(lx + 3 * s, g - 27 * s, 3 * s, s, C(0xFFE0A0))
        }
    }

    /// Brownstones and tenements filling the block from `x0` to `x1`.
    static func harlemRow(_ c: PixelCanvas, _ g: Int, from x0: Int, to x1: Int, seed: Int) {
        let s = unit(g)
        var x = x0, i = 0
        while x < x1 {
            var bw = (26 + Int(noise(seed * 40 + i) * 8)) * s
            if x1 - (x + bw) < 16 * s { bw = x1 - x }
            harlemHouse(c, g, x: x, w: bw, seed: seed * 40 + i)
            x += bw; i += 1
        }
    }

    /// One house on the block: a brownstone with its stoop, or a brick tenement with a fire escape and a shop.
    static func harlemHouse(_ c: PixelCanvas, _ g: Int, x: Int, w: Int, seed: Int) {
        let s = unit(g), tenement = noise(seed + 7) > 0.55
        let browns = [C(0x6A3C2A), C(0x5E3424), C(0x74442E)], bricks = [C(0x8A4434), C(0x9A5440)]
        let wall = tenement ? bricks[seed % 2] : browns[seed % 3]
        let h = (tenement ? 48 : 38) * s + Int(noise(seed + 8) * 8) * s
        let top = g - h, dark = lerp(wall, C(0x000000), 0.45), stone = C(0xC09A7E)
        c.rect(x, top, w, h, wall)
        c.rect(x, top, s, h, dark)
        c.rect(x - s, top, w + s, 2 * s, dark)
        for u in stride(from: x, to: x + w, by: 2 * s) { c.rect(u, top + 2 * s, s, s, dark) }
        let cols = w >= 30 * s ? 3 : 2
        let gapW = (w - cols * 4 * s) / (cols + 1)
        let floorsEnd = g - 16 * s
        for v in stride(from: top + 6 * s, to: floorsEnd - 5 * s, by: 10 * s) {
            for k in 0..<cols {
                let u = x + gapW + k * (4 * s + gapW)
                let r = noise(u * 7 + v * 3 + seed)
                let glass = r > 0.8 ? C(0xFFD27A) : (r > 0.45 ? C(0xE8907A) : C(0x2E2230))
                c.rect(u, v, 4 * s, 6 * s, glass)
                c.rect(u, v + 3 * s, 4 * s, max(1, s / 2), dark)
                c.rect(u - s, v - s, 6 * s, s, stone); c.rect(u - s, v + 6 * s, 6 * s, s, stone)
            }
            if tenement {                                     // the fire escape across the middle
                let fx = x + w / 2 - 7 * s, fy = v + 7 * s, iron = C(0x1A1418)
                c.rect(fx, fy, 14 * s, s, iron); c.rect(fx, fy - 4 * s, 14 * s, max(1, s / 2), iron)
                for u in stride(from: fx, to: fx + 14 * s, by: 2 * s) { c.rect(u, fy - 4 * s, max(1, s / 2), 4 * s, iron) }
                if v + 10 * s < floorsEnd - 5 * s {
                    for j in 0..<(9 * s) { c.rect(fx + 2 * s + j, fy + j + s, max(1, s), max(1, s), iron) }
                }
            }
        }
        if tenement {                                         // a shop on the ground floor
            let awn = [C(0x2A6A4A), C(0x2A4A8A), C(0xA83A2A)][seed % 3]
            c.rect(x + 2 * s, g - 13 * s, w - 4 * s, 13 * s, C(0x2A2026))
            c.rect(x + 4 * s, g - 10 * s, w - 12 * s, 8 * s, C(0xFFD08A, 0.45))
            c.rect(x + w - 7 * s, g - 10 * s, 4 * s, 10 * s, C(0x1A1418))
            c.rect(x + s, g - 15 * s, w - 2 * s, 2 * s, awn); c.rect(x + s, g - 13 * s, w - 2 * s, max(1, s / 2), dark)
        } else {                                              // the stoop up to the parlour floor
            let dx = x + w - 10 * s
            c.rect(dx - s, g - 16 * s, 7 * s, 11 * s, stone)
            c.rect(dx, g - 15 * s, 5 * s, 10 * s, C(0x2A1810)); c.rect(dx + 2 * s, g - 15 * s, s, 10 * s, C(0x1A0E08))
            for k in 0..<5 { c.rect(dx - 2 * s - k * 2 * s, g - 5 * s + k * s, 9 * s + k * 2 * s, s, k % 2 == 0 ? C(0x8A6A54) : C(0x7A5A46)) }
            for j in 0..<(10 * s) { c.px(dx - 2 * s - j, g - 8 * s + j / 2, C(0x1A1418)) }
            c.rect(x + 3 * s, g - 5 * s, 6 * s, 4 * s, C(0x2A1E24))
        }
        // pigeons roosting on the cornice
        if noise(seed + 9) > 0.5 {
            for k in 0..<2 {
                let px = x + (6 + k * 5 + Int(noise(seed + 10 + k) * 6)) * s
                c.rect(px, top - 2 * s, 3 * s, 2 * s, C(0x7A7A88)); c.rect(px + 2 * s, top - 3 * s, s, s, C(0x5A5A68))
            }
        }
        // a water tank on some roofs
        if noise(seed + 11) > 0.7 {
            let tx = x + w / 2
            c.rect(tx - 3 * s, top - 4 * s, s, 4 * s, C(0x2A1A18)); c.rect(tx + 2 * s, top - 4 * s, s, 4 * s, C(0x2A1A18))
            c.rect(tx - 4 * s, top - 11 * s, 8 * s, 7 * s, C(0x5A3A2C))
            scenes5Peak(c, tx, top - 14 * s, half: 5 * s, h: 3 * s, C(0x3A2420))
        }
    }

    /// Pop's Barber Shop: a two-storey brick front with the big sign, a striped awning, the shop window and the pole.
    static func harlemPops(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g), w = 56 * s, top = g - 44 * s
        let wall = C(0x7A4636), dark = C(0x3A2018)
        c.rect(x, top, w, 44 * s, wall); c.rect(x - s, top, w + 2 * s, 2 * s, dark)
        for u in stride(from: x + 6 * s, to: x + w - 6 * s, by: 12 * s) {
            c.rect(u, top + 4 * s, 6 * s, 5 * s, C(0xE8907A)); c.rect(u - s, top + 9 * s, 8 * s, s, C(0xC09A7E))
        }
        // the sign board
        let bx = x + 4 * s, by = g - 38 * s, bw = w - 8 * s
        c.rect(bx - s, by - s, bw + 2 * s, 19 * s, dark)
        c.rect(bx, by, bw, 17 * s, C(0xF2E6CA))
        scenes5TextCentred(c, x + w / 2, by + 2 * s, "POP'S", C(0xC0302A), s: 2 * s)
        scenes5TextCentred(c, x + w / 2, by + 12 * s, "BARBER SHOP", C(0x1E2A5A), s: s)
        // the awning, striped red and white
        for (k, u) in stride(from: x + 2 * s, to: x + w - 2 * s, by: 3 * s).enumerated() {
            c.rect(u, g - 19 * s, 3 * s, 3 * s, k % 2 == 0 ? C(0xC8302A) : C(0xF0E8E0))
        }
        c.rect(x + 2 * s, g - 16 * s, w - 4 * s, s, C(0x5A1A14, 0.6))
        // the shop window: warm light, a barber chair and the mirror
        c.rect(x + 3 * s, g - 15 * s, w - 18 * s, 13 * s, C(0x2A1A16))
        c.rect(x + 4 * s, g - 14 * s, w - 20 * s, 11 * s, C(0xFFD8A0, 0.55))
        c.rect(x + 8 * s, g - 13 * s, 10 * s, 4 * s, C(0xC8E0E8, 0.5))
        c.rect(x + 22 * s, g - 9 * s, 6 * s, 3 * s, C(0x8A1E1A)); c.rect(x + 22 * s, g - 12 * s, 2 * s, 3 * s, C(0x8A1E1A))
        c.rect(x + 24 * s, g - 6 * s, 2 * s, 3 * s, C(0x5A5A60))
        c.rect(x + 3 * s, g - 3 * s, w - 18 * s, 3 * s, C(0x4A2A22))
        // the door, and the pole's caps (its stripes turn in the moving layer)
        c.rect(x + w - 13 * s, g - 15 * s, 7 * s, 15 * s, C(0x1E120E)); c.rect(x + w - 12 * s, g - 14 * s, 5 * s, 6 * s, C(0xFFD8A0, 0.4))
        let pole = harlemPole(c, g, x)
        c.rect(pole.x - s, pole.y - 2 * s, 4 * s, 2 * s, C(0xC8C8D0)); c.rect(pole.x - s, pole.y + pole.h, 4 * s, 2 * s, C(0xC8C8D0))
        c.rect(pole.x, pole.y, 2 * s, pole.h, C(0xF0F0F0))
    }

    /// The barber's pole beside Pop's door: left, top, height.
    static func harlemPole(_ c: PixelCanvas, _ g: Int, _ x: Int) -> (x: Int, y: Int, h: Int) {
        let s = unit(g)
        return (x + 56 * s - 4 * s, g - 14 * s, 10 * s)
    }

    /// The Apolla Theater: its brick front, the tall red APOLLA sign and the marquee over the doors.
    static func harlemApollo(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g), w = 64 * s, top = g - 50 * s
        let wall = C(0x9A6248), dark = C(0x4A2A1E)
        c.rect(x, top, w, 50 * s, wall); c.rect(x - s, top, w + 2 * s, 3 * s, dark)
        c.rect(x, top + 3 * s, w, s, C(0xC89A7A))
        for v in stride(from: top + 7 * s, to: g - 24 * s, by: 9 * s) {
            for u in stride(from: x + 4 * s, to: x + w - 4 * s, by: 8 * s) where abs(u + 2 * s - (x + 32 * s)) > 7 * s {
                c.rect(u, v, 4 * s, 6 * s, C(0x3A2228)); c.rect(u, v, 4 * s, 2 * s, C(0xE8907A, 0.7))
            }
        }
        // the vertical sign
        let sg = harlemApolloSign(c, g)
        c.rect(sg.x - s, sg.y - s, sg.w + 2 * s, sg.h + 2 * s, C(0x5A0E0E))
        c.rect(sg.x, sg.y, sg.w, sg.h, C(0xB81E1E))
        for (k, ch) in "APOLLA".enumerated() {
            scenes5Text(c, sg.x + 3 * s, sg.y + 3 * s + k * 6 * s, String(ch), C(0xE8C890), s: s)
        }
        c.rect(sg.x + 3 * s, sg.y + sg.h + s, 3 * s, g - 21 * s - (sg.y + sg.h + s), C(0x3A1A14))
        // the marquee
        let m = harlemMarquee(c, g)
        c.rect(m.x, m.y, m.w, m.h, C(0xB81E1E))
        c.rect(m.x + 2 * s, m.y + 2 * s, m.w - 4 * s, m.h - 4 * s, C(0xF4ECD8))
        scenes5TextCentred(c, m.x + m.w / 2, m.y + 3 * s - s / 2, "AMATEUR NIGHT", C(0x1A1418), s: s)
        c.rect(m.x, m.y + m.h, m.w, s, C(0x3A1A14))
        // the doors, lit inside
        c.rect(x + 6 * s, g - 10 * s, w - 12 * s, 10 * s, C(0x2A1414))
        for u in stride(from: x + 8 * s, to: x + w - 8 * s, by: 8 * s) { c.rect(u, g - 9 * s, 6 * s, 9 * s, C(0xFFD08A, 0.6)) }
    }

    /// Full screen: Harlem's taller blocks off behind the street, and more of the burning sky.
    static func harlemHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        var x = -10 * s, i = 0
        while x < c.w {
            let bw = (24 + Int(noise(i + 1050) * 30)) * s, h = Int(Double(g) * (0.3 + 0.3 * noise(i + 1051)))
            c.rect(x, g - h, bw, h, C(0xB8687E))
            for v in stride(from: g - h + 4 * s, to: g - 4 * s, by: 6 * s) {
                for u in stride(from: x + 3 * s, to: x + bw - 3 * s, by: 5 * s) where noise(u + v * 7) > 0.7 {
                    c.rect(u, v, 2 * s, 3 * s, C(0xFFD8A0, 0.4))
                }
            }
            x += bw + (2 + Int(noise(i + 1052) * 10)) * s; i += 1
        }
        for i in 0..<8 {
            let y = Int(Double(g) * (0.08 + 0.06 * Double(i))), x = Int(noise(i + 1060) * Double(c.w))
            Scenes.cloud(c, x, y, (4 + Int(noise(i + 1061) * 5)) * s, seed: i + 1062, top: C(0xFFC0A8, 0.7), base: C(0xC0708A, 0.6))
        }
    }

    /// The Apolla's bulbs chasing round its sign and marquee, Pop's pole turning, and pigeons: a few pecking on the
    /// sidewalk, a small flock wheeling over the rooftops.
    static func harlemMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), step = Int(t * 8)
        let m = harlemMarquee(c, g)
        c.rect(m.x - 2 * s, m.y - 2 * s, m.w + 4 * s, m.h + 4 * s, C(0xFFD27A, 0.1))
        for (i, u) in stride(from: m.x + s, to: m.x + m.w - s, by: 3 * s).enumerated() {
            let on = (i + step) % 3 == 0
            c.rect(u, m.y, s, s, on ? C(0xFFF0B0) : C(0x8A5A2A)); c.rect(m.x + m.w - s - (u - m.x), m.y + m.h - s, s, s, on ? C(0xFFF0B0) : C(0x8A5A2A))
        }
        let sg = harlemApolloSign(c, g)
        var ring: [(Int, Int)] = []
        for v in stride(from: sg.y + s, to: sg.y + sg.h - s, by: 3 * s) { ring.append((sg.x + s, v)) }
        for v in stride(from: sg.y + sg.h - 2 * s, to: sg.y, by: -3 * s) { ring.append((sg.x + sg.w - 2 * s, v)) }
        for (i, p) in ring.enumerated() { c.rect(p.0, p.1, s, s, (i + step) % 4 == 0 ? C(0xFFF0B0) : C(0xE89A5A, 0.6)) }
        for (k, ch) in "APOLLA".enumerated() {
            scenes5Text(c, sg.x + 3 * s, sg.y + 3 * s + k * 6 * s, String(ch), C(0xFFF4C8), s: s)
        }
        // the barber's pole
        let pole = harlemPole(c, g, harlemSpots(c, g).pops)
        let stripes = [C(0xD8302A), C(0xF0F0F0), C(0x2A4AB0), C(0xF0F0F0)]
        for v in 0..<pole.h {
            for u in 0..<(2 * s) {
                let k = ((v + u + Int(t * 10.0 * Double(s))) / max(1, 2 * s)) % stripes.count
                c.px(pole.x + u, pole.y + v, stripes[k])
            }
        }
        // pigeons on the sidewalk, pecking
        for (i, fx) in [c.w * 33 / 100, c.w * 36 / 100, c.w * 82 / 100].enumerated() {
            let peck = noise(Int(t * 3) * 5 + i) > 0.6
            let x = fx + Int(sin(t * 0.7 + Double(i)) * 3 * Double(s))
            c.rect(x, g - 2 * s, 3 * s, 2 * s, C(0x7A7A88)); c.rect(x + 3 * s, g - (peck ? 1 : 3) * s, s, s, C(0x4A5A60))
            c.px(x + s, g, C(0xC86A4A))
        }
        // the flock wheeling over the roofs
        let up = ["w...w", ".wgw."], down = [".....", "wwgww", "..w.."]
        let pal: [Character: Px] = ["w": C(0x6A6A7A), "g": C(0x9A9AA8)]
        let fx = scenes5Phase(t, 14) * Double(c.w + 80 * s) - Double(40 * s)
        for i in 0..<5 {
            let x = Int(fx) - i * 9 * s + Int(noise(i + 1080) * 6) * s
            let y = g / 5 + Int(sin(t * 1.3 + Double(i)) * 3 * Double(s)) + Int(noise(i + 1081) * 10) * s
            scenes5Stamp(c, x, y, (Int(t * 8) + i) % 2 == 0 ? up : down, pal, s: s)
        }
    }
}

// MARK: - K'un-Lun

extension Scenes {
    /// The mountain that holds Shou-Lao's cave: centre, top and half-width, and the cave mouth's centre and size.
    static func kunLunCave(_ c: PixelCanvas, _ g: Int) -> (x: Int, top: Int, half: Int, cx: Int, cy: Int, r: Int) {
        let s = unit(g), x = c.w * 57 / 100, top = Int(Double(g) * 0.1)
        let half = (g - top) * 28 / 100
        return (x, top, half, x + half / 6, top + (g - top) * 42 / 100, max(3 * s, half / 5))
    }

    /// K'un-Lun, the hidden city in the mountains: sheer karst peaks fading back into the mist, red pagodas perched
    /// on their summits among pines and on a cliff to the left, the cave of the dragon Shou-Lao glowing orange high
    /// in the tallest peak, a red gate standing in the courtyard and a cherry tree in blossom.
    static func kunLun(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), k = tall ? 2 * s : s
        c.gradient(0, g, C(0x6A9AC0), C(0xF8DCC0), bands: 8)
        let sunX = c.w * 76 / 100, sunY = g * 26 / 100
        c.circle(sunX, sunY, 11 * s, C(0xFFF2DC, 0.3)); c.circle(sunX, sunY, 6 * s, C(0xFFF6E6))
        if tall { kunLunHigh(c, g) }
        // the far peaks, pale with distance
        let nFar = max(4, c.w / 40)
        for i in 0..<nFar {
            let x = Int((Double(i) + 0.2 + noise(i + 1100) * 0.6) * Double(c.w) / Double(nFar))
            let top = Int(Double(g) * (0.2 + 0.28 * noise(i + 1101)))
            kunLunPeak(c, x, top: top, base: g, half: (g - top) * 20 / 100, C(0xBCC8D2), lit: C(0xD8E2EA), seed: i + 1102)
        }
        kunLunMist(c, g, y: Int(Double(g) * 0.6), alpha: 0.6, seed: 1)
        // the nearer peaks, wooded on top, some crowned with pagodas
        let cave = kunLunCave(c, g)
        let nMid = max(3, c.w / 80)
        for i in 0..<nMid {
            let x = Int((Double(i) + 0.25 + noise(i + 1110) * 0.5) * Double(c.w) / Double(nMid))
            if abs(x - cave.x) < cave.half * 3 / 2 || x < 30 * k { continue }
            let top = Int(Double(g) * (0.34 + 0.2 * noise(i + 1111))), half = (g - top) * 22 / 100
            kunLunPeak(c, x, top: top, base: g, half: half, C(0x8294A0), lit: C(0xA6B6C0), seed: i + 1112)
            kunLunTufts(c, x, top: top, half: half, base: g, s, seed: i + 1113)
            if noise(i + 1114) > 0.3 {
                kunLunPagoda(c, x, top + s, tiers: 1 + Int(noise(i + 1115) * 2), s, roof: C(0x34444A), wall: C(0xA8483A))
            }
        }
        // the dragon's mountain, its cave mouth burning orange
        kunLunPeak(c, cave.x, top: cave.top, base: g, half: cave.half, C(0x6A7E8A), lit: C(0x8EA2AE), seed: 1120)
        kunLunTufts(c, cave.x, top: cave.top, half: cave.half, base: g, s, seed: 1121)
        kunLunPagoda(c, cave.x, cave.top + s, tiers: 2, s, roof: C(0x2E3E44), wall: C(0xA8483A))
        kunLunCaveMouth(c, g, cave)
        kunLunMist(c, g, y: Int(Double(g) * 0.82), alpha: 0.65, seed: 2)
        // the cliff on the left with the great pagoda
        let cliffTop = g - 32 * k
        kunLunPeak(c, 14 * k, top: cliffTop, base: g, half: 26 * k, C(0x4E5E56), lit: C(0x6E7E6C), seed: 1130)
        kunLunTufts(c, 14 * k, top: cliffTop, half: 26 * k, base: g, k, seed: 1131)
        kunLunPagoda(c, 14 * k, cliffTop + k, tiers: 3, k, roof: C(0x263434), wall: C(0xB04A36))
        kunLunGate(c, g, c.w * 40 / 100, k)
        kunLunTree(c, g, c.w * 85 / 100, k)
        // the stone courtyard, petals lying on it
        c.ground(g, C(0xA89880), edge: C(0xC8B8A0), speck: C(0x988870), seed: 55)
        for x in stride(from: 0, to: c.w, by: 12 * s) { c.rect(x, g + s, max(1, s / 2), c.h - g, C(0x988870)) }
        for i in 0..<(c.w / 8) {
            c.px(Int(noise(i + 1140) * Double(c.w)), g + 1 + Int(noise(i + 1141) * Double(max(1, c.h - g - 1))), C(0xF4A8C4))
        }
    }

    /// A sheer karst peak: narrow, rounded at the top and widening to its foot, lit on the left, with streaks.
    static func kunLunPeak(_ c: PixelCanvas, _ cx: Int, top: Int, base: Int, half: Int, _ col: Px, lit: Px, seed: Int) {
        let h = max(1, base - top), shade = lerp(col, C(0x2A3440), 0.25)
        for y in top..<base {
            let k = Double(y - top) / Double(h)
            var hw = Double(half) * (0.42 + 0.58 * pow(k, 1.6))
            if y - top < 3 { hw *= 0.6 + 0.13 * Double(y - top) }
            let l = cx - Int(hw + noise(y / 2 * 7 + seed) * 2), r = cx + Int(hw + noise(y / 2 * 5 + seed + 3) * 2)
            c.rect(l, y, r - l, 1, col)
            c.rect(l, y, max(1, (r - l) / 4), 1, lit)
            c.rect(r - max(1, (r - l) / 6), y, max(1, (r - l) / 6), 1, shade)
        }
        for n in 0..<3 {
            let x = cx + Int((noise(seed + n * 9) - 0.5) * Double(half))
            let y0 = top + Int(noise(seed + n * 9 + 1) * Double(h) * 0.5)
            c.rect(x, y0, 1, h / 4, lerp(col, C(0x2A3440), 0.15))
        }
    }

    /// Pines and scrub clinging to a peak's summit and to a few ledges down its sides.
    static func kunLunTufts(_ c: PixelCanvas, _ cx: Int, top: Int, half: Int, base: Int, _ k: Int, seed: Int) {
        let green = C(0x4A6A4E), dark = C(0x34503C)
        let crown = max(2 * k, half * 4 / 10)
        for i in 0..<4 {
            let x = cx - crown + Int(noise(seed * 3 + i) * Double(crown * 2))
            c.ellipse(x, top + k, 2 * k + Int(noise(seed * 3 + i + 7) * 2) * k, k, green)
        }
        for side in [-1, 1] {
            let x = cx + side * (crown - k)
            scenes5Peak(c, x, top - 5 * k, half: 2 * k, h: 5 * k, dark)
            c.rect(x, top, max(1, k / 2), k, C(0x3A2A24))
        }
        for i in 0..<3 {
            let f = 0.2 + 0.5 * noise(seed * 5 + i)
            let y = top + Int(Double(base - top) * f)
            let hw = Double(half) * (0.42 + 0.58 * pow(f, 1.6))
            let x = cx + (i % 2 == 0 ? -1 : 1) * Int(hw * 0.8)
            c.ellipse(x, y, 2 * k, k, green.alpha(0.8))
        }
    }

    /// Shou-Lao's cave: a dark arched mouth with a terrace before it, the dragon's fire glowing inside.
    static func kunLunCaveMouth(_ c: PixelCanvas, _ g: Int, _ cave: (x: Int, top: Int, half: Int, cx: Int, cy: Int, r: Int)) {
        let s = unit(g), r = cave.r
        for j in 0..<3 { c.ellipse(cave.cx, cave.cy, r * (4 - j) / 2 + s, r * (4 - j) / 2, C(0xFF9A4A, 0.1)) }
        c.ellipse(cave.cx, cave.cy, r, r * 4 / 5, C(0x24140E))
        c.rect(cave.cx - r, cave.cy, 2 * r + 1, r, C(0x24140E))
        c.ellipse(cave.cx, cave.cy + r / 3, r * 7 / 10, r * 3 / 5, C(0xD8541E))
        c.rect(cave.cx - r * 7 / 10, cave.cy + r / 3, r * 7 / 5 + 1, r * 2 / 3, C(0xD8541E))
        c.ellipse(cave.cx, cave.cy + r * 2 / 3, max(1, r * 2 / 5), max(1, r / 3), C(0xFFB04A))
        c.rect(cave.cx - r * 8 / 5, cave.cy + r, r * 16 / 5, max(1, s), C(0xB8A890))
        for side in [-1, 1] {
            c.rect(cave.cx + side * (r + s) - (side < 0 ? s : 0), cave.cy - r / 3, max(1, s), r * 4 / 3, C(0xA8382A))
        }
        for j in 0..<(r * 2) { c.px(cave.cx - r * 8 / 5 - j, cave.cy + r + j / 2 + 1, C(0x5E707C)) }
    }

    /// A pagoda of `tiers` storeys standing on row `b`: red walls under dark, upswept roofs, a gold finial.
    static func kunLunPagoda(_ c: PixelCanvas, _ x: Int, _ b: Int, tiers: Int, _ s: Int, roof: Px, wall: Px) {
        var y = b
        for k in 0..<tiers {
            let ww = (6 + (tiers - k) * 3) * s
            c.rect(x - ww / 2, y - 4 * s, ww, 4 * s, wall)
            for u in stride(from: x - ww / 2 + s, to: x + ww / 2 - s, by: 2 * s) { c.rect(u, y - 3 * s, s, 2 * s, C(0x5A1E18)) }
            c.rect(x - ww / 2 - 2 * s, y - 5 * s, ww + 4 * s, s, roof)
            c.rect(x - ww / 2 - s, y - 6 * s, ww + 2 * s, s, roof)
            c.rect(x - ww / 2 + s, y - 7 * s, ww - 2 * s, s, roof)
            c.rect(x - ww / 2 - 3 * s, y - 6 * s, s, s, roof); c.rect(x + ww / 2 + 2 * s, y - 6 * s, s, s, roof)
            c.rect(x - ww / 2 - 3 * s, y - 7 * s, s, s, C(0xE0B04A)); c.rect(x + ww / 2 + 2 * s, y - 7 * s, s, s, C(0xE0B04A))
            y -= 7 * s
        }
        c.rect(x, y - 3 * s, s, 3 * s, C(0xE0B04A)); c.rect(x - s, y - s, 3 * s, s, C(0xE0B04A))
    }

    /// A soft bank of mist lying at row `y`.
    static func kunLunMist(_ c: PixelCanvas, _ g: Int, y: Int, alpha: Double, seed: Int) {
        let s = unit(g)
        for i in 0..<max(6, c.w / 28) {
            let x = Int(noise(i + seed * 50 + 1150) * Double(c.w)), dy = Int(noise(i + seed * 50 + 1152) * 5) * s
            let rx = (16 + Int(noise(i + seed * 50 + 1151) * 34)) * s
            c.ellipse(x, y + dy, rx, (2 + Int(noise(i + seed * 50 + 1153) * 3)) * s, C(0xFAF4EE, alpha * 0.45))
        }
        c.rect(0, y + 3 * s, c.w, 4 * s, C(0xFAF4EE, alpha * 0.3))
    }

    /// The gate into the city: two red pillars, a lintel with a gold plaque, and a dark upswept roof.
    static func kunLunGate(_ c: PixelCanvas, _ g: Int, _ x: Int, _ s: Int) {
        let red = C(0xB03A2A), roof = C(0x2A3436)
        for u in [-12, 10] {
            c.rect(x + u * s, g - 22 * s, 2 * s, 22 * s, red); c.rect(x + u * s, g - 22 * s, max(1, s / 2), 22 * s, C(0xD05A40))
            c.rect(x + (u - 1) * s, g - 2 * s, 4 * s, 2 * s, C(0x6A6058))
        }
        c.rect(x - 14 * s, g - 20 * s, 28 * s, 2 * s, red)
        c.rect(x - 3 * s, g - 18 * s, 6 * s, 4 * s, C(0xE0B04A)); c.rect(x - 2 * s, g - 17 * s, 4 * s, 2 * s, C(0x8A5A2A))
        c.rect(x - 17 * s, g - 24 * s, 34 * s, 2 * s, roof); c.rect(x - 14 * s, g - 26 * s, 28 * s, 2 * s, roof)
        c.rect(x - 19 * s, g - 25 * s, 2 * s, s, roof); c.rect(x + 17 * s, g - 25 * s, 2 * s, s, roof)
        c.rect(x - 20 * s, g - 26 * s, s, s, roof); c.rect(x + 19 * s, g - 26 * s, s, s, roof)
    }

    /// A cherry tree in full blossom on the courtyard's edge: a crooked trunk forking into limbs under clouds of pink.
    static func kunLunTree(_ c: PixelCanvas, _ g: Int, _ x: Int, _ k: Int) {
        let bark = C(0x3A2428)
        func limb(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ w: Int) {
            let n = max(1, max(abs(x1 - x0), abs(y1 - y0)))
            for j in 0...n { c.rect(x0 + (x1 - x0) * j / n - w / 2, y0 + (y1 - y0) * j / n, w, max(1, k), bark) }
        }
        let fx = x - 2 * k, fy = g - 14 * k
        limb(x, g - k, fx, fy, 3 * k)
        let ends = [(x - 15 * k, g - 22 * k), (x + 12 * k, g - 24 * k), (x - 3 * k, g - 29 * k), (x + 5 * k, g - 19 * k)]
        for e in ends { limb(fx, fy, e.0, e.1, 2 * k) }
        let pinks = [C(0xD86A94), C(0xEE98B8), C(0xF8BCD2)]
        for layer in 0..<3 {
            for (i, e) in ends.enumerated() {
                for j in 0..<3 {
                    let n = i * 9 + j * 3 + layer
                    let dx = Int((noise(n + 1160) - 0.5) * 12) * k - layer * k, dy = Int((noise(n + 1161) - 0.5) * 6) * k - layer * k
                    let r = (4 + Int(noise(n + 1162) * 3) - layer) * k
                    c.ellipse(e.0 + dx, e.1 + dy, r + k, max(k, r * 3 / 4), pinks[layer])
                }
            }
        }
        for i in 0..<24 {
            let e = ends[i % ends.count]
            c.rect(e.0 + Int((noise(i + 1170) - 0.5) * 18) * k, e.1 + Int((noise(i + 1171) - 0.5) * 9) * k, k, k, C(0xFFE6F0))
        }
    }

    /// Full screen: still higher, paler peaks behind, cloud drifting between them.
    static func kunLunHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<max(3, c.w / 90) {
            let x = Int((Double(i) + noise(i + 1180)) * Double(c.w) / Double(max(3, c.w / 90)))
            let top = Int(Double(g) * (0.05 + 0.1 * noise(i + 1181)))
            kunLunPeak(c, x, top: top, base: g, half: (g - top) * 15 / 100, C(0xCAD6E0), lit: C(0xE0E8EE), seed: i + 1182)
        }
        kunLunMist(c, g, y: Int(Double(g) * 0.42), alpha: 0.6, seed: 3)
        for i in 0..<5 {
            let x = Int(noise(i + 1190) * Double(c.w)), y = Int(Double(g) * (0.08 + 0.07 * Double(i)))
            Scenes.wisp(c, x, y, (40 + Int(noise(i + 1191) * 40)) * s, C(0xFFF8F0, 0.5), s: s)
        }
    }

    /// Cherry petals drifting down, mist rolling slowly past the peaks, and the dragon's cave glowing.
    static func kunLunMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let cave = kunLunCave(c, g)
        let pulse = 0.5 + 0.5 * sin(t * 1.6)
        c.ellipse(cave.cx, cave.cy, cave.r * 2 + s, cave.r * 2, C(0xFF8A3A, 0.05 + 0.08 * pulse))
        c.ellipse(cave.cx, cave.cy + cave.r * 2 / 3, max(1, cave.r * 2 / 5), max(1, cave.r / 3), C(0xFFE8A0, 0.25 + 0.45 * pulse))
        for i in 0..<7 {
            let y = Int(Double(g) * (0.5 + 0.06 * Double(i))), rx = (24 + Int(noise(i + 1200) * 30)) * s
            let span = Double(c.w + rx * 2)
            let x = Int((noise(i + 1201) * span + t * Double((3 + i) * s)).truncatingRemainder(dividingBy: span)) - rx
            c.ellipse(x, y, rx, 2 * s, C(0xFFFFFF, 0.2))
        }
        let pinks = [C(0xF4A8C4), C(0xFAC8DA), C(0xE07AA0)]
        for i in 0..<max(24, c.w * c.h / 500) {
            let speed = (10 + noise(i * 3 + 1210) * 10) * Double(s)
            let y = (noise(i * 3 + 1211) * Double(c.h) + t * speed).truncatingRemainder(dividingBy: Double(c.h + 6)) - 3
            let span = Double(c.w + 20)
            let x0 = noise(i * 3 + 1212) * span + t * 9 * Double(s) + sin(t * 2 + Double(i)) * 3 * Double(s)
            let x = Int(x0.truncatingRemainder(dividingBy: span)) - 10
            let flip = (Int(t * 4) + i) % 2 == 0
            c.rect(x, Int(y), flip ? 2 * s : s, s, pinks[i % 3])
        }
    }
}
