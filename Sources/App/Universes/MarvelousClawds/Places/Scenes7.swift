import Foundation

let scenes7: [Location: Place] = [
    .newYorkStreets: Place(name: "New York City", panel: 0x1A1E2A, still: Scenes.newYorkStreets, moving: Scenes.newYorkStreetsLife),
    .savageLandCitadel: Place(name: "Savage Lands Citadel", panel: 0x1A1E1A, still: Scenes.savageLandCitadel,
                              moving: Scenes.savageLandCitadelLife),
    .starkWorkshop: Place(name: "Tony Stork's Workshop", panel: 0x14181E, still: Scenes.starkWorkshop, moving: Scenes.starkWorkshopLife),
    .redRoom: Place(name: "The Red Room", panel: 0x1E1414, still: Scenes.redRoom, moving: Scenes.redRoomLife),
    .taLo: Place(name: "Ta Loh", panel: 0x14201A, still: Scenes.taLo, moving: Scenes.taLoLife),
]

// MARK: - Shared shapes for this file

/// Fills a polygon given in canvas pixels (scanline, even-odd).
fileprivate func s7Poly(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
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

/// String art drawn `k` pixels a cell, mirrored left to right when `flip` is set.
fileprivate func s7Sprite(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], k: Int = 1,
                          flip: Bool = false) {
    for (r, row) in rows.enumerated() {
        let chars = Array(row)
        for (i, ch) in chars.enumerated() {
            guard let col = pal[ch] else { continue }
            let cx = flip ? chars.count - 1 - i : i
            c.rect(x + cx * k, y + r * k, k, k, col)
        }
    }
}

/// A 3×5 pixel alphabet, just the letters the signs here need.
fileprivate let s7Glyphs: [Character: [String]] = [
    "A": ["###", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "D": ["##.", "#.#", "#.#", "#.#", "##."], "E": ["###", "#..", "##.", "#..", "###"],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "L": ["#..", "#..", "#..", "#..", "###"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "M": ["#.#", "###", "###", "#.#", "#.#"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "W": ["#.#", "#.#", "###", "###", "#.#"], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "'": [".#.", ".#.", "...", "...", "..."], " ": ["...", "...", "...", "...", "..."],
]

/// Writes `text` in the pixel alphabet, `k` pixels a dot; returns the width it took.
@discardableResult
fileprivate func s7Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, k: Int = 1) -> Int {
    var cx = x
    for ch in text {
        if let rows = s7Glyphs[ch] { s7Sprite(c, cx, y, rows, ["#": col], k: k) }
        cx += 4 * k
    }
    return cx - x - k
}

/// The outline of an ellipse, `n` points round, as single pixels.
fileprivate func s7Ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px, n: Int = 48) {
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        c.px(Int((cx + cos(a) * rx).rounded()), Int((cy + sin(a) * ry).rounded()), col)
    }
}

extension Scenes {

    // MARK: - New York City

    /// New York City at street level (Spider-Man's neighbourhood): a sunny Queens block of brownstones, red-brick
    /// walk-ups with fire escapes and corner stores, Delmont's Deli-Grocery among them, wooden water towers on the roofs;
    /// a subway entrance with its green globe lamps, a traffic light over a crosswalk, and the Midtown skyline beyond,
    /// the Empire State and Chrysler buildings standing out of the haze. Cabs drive by, people walk, pigeons peck and
    /// the light changes in `newYorkStreetsLife`.
    static func newYorkStreets(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x4C8ED8), C(0xDDECF6), bands: 7)
        for i in 0..<(tall ? 7 : 3) {
            let x = Int(noise(i * 5 + 7100) * Double(c.w))
            let y = Int(Double(g) * (tall ? 0.05 + noise(i * 5 + 7101) * 0.3 : 0.08 + noise(i * 5 + 7101) * 0.1))
            let r = (tall ? 4 + Int(noise(i * 5 + 7102) * 4) : 2 + Int(noise(i * 5 + 7102) * 2)) * s
            cloud(c, x, y, r, seed: i + 710)
        }
        newYorkSkyline(c, g)
        let r = newYorkRows(g)
        for b in newYorkBuildings(c, g) { newYorkBuilding(c, b, base: r.walk, g: g) }
        // The far sidewalk, its curb, and the road with a dashed centre line.
        c.rect(0, r.walk, c.w, r.road - r.walk, C(0xA8A49C))
        c.rect(0, r.walk, c.w, s, C(0x8E8A84))
        c.rect(0, r.road - s, c.w, s, C(0xCCC8C0))
        c.rect(0, r.road, c.w, g - r.road, C(0x4A4A52))
        c.rect(0, r.road, c.w, s, C(0x3A3A40))
        let mid = r.road + (g - r.road) / 2
        for x in stride(from: 0, to: c.w, by: 14 * s) { c.rect(x, mid, 7 * s, s, C(0xE8D060, 0.8)) }
        for i in 0..<(c.w / 3) {                                             // patched asphalt
            c.px(Int(noise(i * 2 + 7110) * Double(c.w)), r.road + 1 + Int(noise(i * 2 + 7111) * Double(g - r.road - 1)), C(0x3E3E46))
        }
        // The crosswalk under the traffic light.
        let sig = newYorkSignal(c, g)
        for y in stride(from: r.road + s, to: g, by: 2 * s) { c.rect(sig.x - 10 * s, y, 22 * s, s, C(0xE8E8E0, 0.85)) }
        newYorkSubway(c, x: c.w * 52 / 100, walk: r.walk, s: s)
        // Street furniture: a lamppost, a hydrant, a wire trash can, the traffic light's pole.
        let lx = c.w * 37 / 100
        c.rect(lx, r.walk - 26 * s, s, 28 * s, C(0x3A4A44))
        c.rect(lx, r.walk - 26 * s, 5 * s, s, C(0x3A4A44)); c.rect(lx + 4 * s, r.walk - 25 * s, 3 * s, s, C(0x2A3430))
        c.rect(lx + 4 * s, r.walk - 24 * s, 3 * s, s, C(0xF4EAC0))
        let hx = c.w * 67 / 100
        c.rect(hx, r.walk - 3 * s, 3 * s, 5 * s, C(0xC03028)); c.rect(hx - s, r.walk - 2 * s, 5 * s, s, C(0xC03028))
        c.rect(hx, r.walk - 4 * s, 3 * s, s, C(0x8A1C18)); c.rect(hx + 2 * s, r.walk - 3 * s, s, 4 * s, C(0x8A1C18))
        let tx = c.w * 12 / 100
        c.rect(tx, r.walk - 5 * s, 4 * s, 7 * s, C(0x3A6A44)); c.rect(tx, r.walk - 5 * s, 4 * s, s, C(0x4E8A5A))
        for k in 0..<2 { c.rect(tx + s + k * 2 * s, r.walk - 4 * s, s, 6 * s, C(0x2A5034)) }
        c.rect(sig.x + s, sig.y + 11 * s, s, r.road - sig.y - 11 * s, C(0x2E3236))
        c.rect(sig.x - 3 * s, sig.y + 16 * s, 6 * s, 2 * s, C(0x2E7A44))                  // street sign
        c.rect(sig.x - 2 * s, sig.y + 16 * s + s / 2, 4 * s, max(1, s / 2), C(0xE8F0E8, 0.7))
        c.rect(sig.x - s, sig.y - s, 5 * s, 13 * s, C(0x2E3236))                          // the signal head
        for k in 0..<3 {
            let dim = [C(0x5A1A18), C(0x5A4A18), C(0x1A4A2A)][k]
            c.rect(sig.x, sig.y + k * 4 * s, 3 * s, 3 * s, dim)
            c.rect(sig.x - s, sig.y + k * 4 * s - s, 5 * s, s, C(0x1E2226))               // visor
        }
        // The near sidewalk: pale concrete slabs.
        c.ground(g, C(0xB4B0A8), edge: C(0xDAD6CE), speck: C(0x9E9A92), seed: 71)
        c.rect(0, g + 1, c.w, s, C(0x8E8A84))
        for x in stride(from: 9 * s, to: c.w, by: 22 * s) { c.rect(x, g + 2, max(1, s / 2 + 1) / 1, c.h - g - 2, C(0x9A968E)) }
        for i in 0..<(c.w / 30) {                                            // gum spots
            c.px(Int(noise(i * 2 + 7120) * Double(c.w)), g + 3 + Int(noise(i * 2 + 7121) * Double(max(1, c.h - g - 4))), C(0x7A7670))
        }
    }

    /// The rows of the street: where the far sidewalk (and the buildings' feet) starts, and where the road starts.
    static func newYorkRows(_ g: Int) -> (walk: Int, road: Int) {
        let s = unit(g)
        return (g - 12 * s, g - 9 * s)
    }

    /// Where the traffic light's head hangs: its top-left corner.
    static func newYorkSignal(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int) {
        let s = unit(g)
        return (c.w * 81 / 100, newYorkRows(g).walk - 26 * s)
    }

    /// The block's buildings left to right: where each stands, its width, its kind (brownstone, red brick, tan brick,
    /// grey stone), how many storeys sit over the ground floor, and its shop (0 none, 1 Delmont's, else an awning colour).
    static func newYorkBuildings(_ c: PixelCanvas, _ g: Int) -> [(x: Int, w: Int, kind: Int, floors: Int, store: Int)] {
        let s = unit(g), tall = isTall(c)
        var out: [(x: Int, w: Int, kind: Int, floors: Int, store: Int)] = []
        var x = -Int(noise(7200) * 20) * s, i = 0, delmars = false
        let delX = c.w * 22 / 100
        while x < c.w {
            var w = (30 + Int(noise(i * 7 + 7201) * 20)) * s
            var kind = Int(noise(i * 7 + 7202) * 4)
            var store = kind == 0 ? 0 : 2 + Int(noise(i * 7 + 7203) * 4)
            if !delmars && x + w > delX { w = max(w, 46 * s); kind = 2; store = 1; delmars = true }
            if let last = out.last, last.kind == kind { kind = (kind + 1) % 4; if store == 0 { store = 2 + i % 4 } }
            if kind == 0 { store = 0 }
            let floors = tall ? 5 + Int(noise(i * 7 + 7204) * 6) : 2 + (noise(i * 7 + 7204) > 0.6 ? 1 : 0)
            out.append((x, w, kind, floors, store))
            x += w; i += 1
        }
        return out
    }

    /// One building of the block: cornice and dentils, rows of windows with lintels and sills, a fire escape on the
    /// red-brick walk-ups, a shop or a brownstone stoop on the ground floor, and sometimes a water tower on the roof.
    static func newYorkBuilding(_ c: PixelCanvas, _ b: (x: Int, w: Int, kind: Int, floors: Int, store: Int), base: Int, g: Int) {
        let s = unit(g)
        let pal: [(Px, Px, Px)] = [(C(0x7A4636), C(0x54301F), C(0xB08A6A)), (C(0x9A4636), C(0x6E2E22), C(0xE0D4C0)),
                                   (C(0xC2A07A), C(0x96785A), C(0xEEE4D0)), (C(0x8E8C88), C(0x66645E), C(0xCCC8BE))]
        let (wall, dark, trim) = pal[b.kind]
        let fh = 7 * s, gh = 10 * s, top = base - gh - b.floors * fh
        c.rect(b.x, top, b.w, base - top, wall)
        if b.kind == 1 || b.kind == 2 {                                    // brick courses
            for (row, y) in stride(from: top + s, to: base - gh, by: 2 * s).enumerated() {
                for x in stride(from: b.x + (row % 2) * 2 * s, to: b.x + b.w, by: 4 * s) { c.rect(x, y, s, s, dark.alpha(0.18)) }
            }
        }
        c.rect(b.x, top - 3 * s, s, base - top + 3 * s, dark.alpha(0.7))   // party wall
        c.rect(b.x - s, top - 3 * s, b.w + 2 * s, 2 * s, dark)             // cornice and dentils
        c.rect(b.x - s, top - s, b.w + 2 * s, s, trim)
        for x in stride(from: b.x, to: b.x + b.w, by: 3 * s) { c.rect(x, top - 2 * s, s, s, trim.alpha(0.6)) }
        // Water tower, or a chimney and a vent.
        if noise(b.x / max(1, s) + 7210) > 0.7 && b.w >= 34 * s {
            newYorkWaterTower(c, x: b.x + b.w / 3, roof: top - 3 * s, s: s)
        } else {
            c.rect(b.x + b.w - 8 * s, top - 7 * s, 4 * s, 4 * s, dark); c.rect(b.x + b.w - 9 * s, top - 8 * s, 6 * s, s, trim.alpha(0.7))
        }
        // Windows.
        let n = max(2, (b.w - 4 * s) / (8 * s)), gap = b.w / n
        for f in 0..<b.floors {
            let fy = top + s + f * fh
            for k in 0..<n {
                let wx = b.x + gap * k + gap / 2 - 2 * s
                c.rect(wx - s / 2, fy - s, 5 * s, s, b.kind == 1 || b.kind == 2 ? dark : trim)    // lintel
                c.rect(wx, fy, 4 * s, 5 * s, C(0x34465E))
                c.rect(wx, fy, 4 * s, s, C(0x86A4C6))
                c.rect(wx, fy + 2 * s, 4 * s, max(1, s / 2), trim.alpha(0.8))                 // sash
                if noise(f * 31 + k * 7 + b.x + 7220) > 0.7 { c.rect(wx, fy + s, 2 * s, 4 * s, C(0xD8C49A)) }  // a curtain
                c.rect(wx - s / 2, fy + 5 * s, 5 * s, s, trim)                                  // sill
            }
        }
        if b.kind == 1 { newYorkFireEscape(c, x: b.x + b.w / 2, top: top, floors: b.floors, fh: fh, s: s) }
        // Ground floor.
        let gy = base - gh
        if b.store == 0 {
            c.rect(b.x + s, gy, b.w - s, gh, dark.alpha(0.45))                                 // rusticated base
            for y in stride(from: gy + 2 * s, to: base, by: 2 * s) { c.rect(b.x + s, y, b.w - s, max(1, s / 2), dark.alpha(0.4)) }
            let dx = b.x + b.w * 2 / 3
            c.rect(dx - s, gy, 6 * s, 7 * s, trim)                                             // doorway, door, stoop
            c.rect(dx, gy + s, 4 * s, 6 * s, C(0x3A2418)); c.rect(dx + 2 * s, gy + s, max(1, s / 2), 6 * s, C(0x24160E))
            for k in 0..<3 {
                c.rect(dx - s - k * s, gy + 7 * s + k * s, 6 * s + 2 * k * s, s, C(0x8A6A54))
                c.rect(dx - s - k * s, gy + 7 * s + k * s, 6 * s + 2 * k * s, max(1, s / 2), C(0xA88A70))
            }
            for k in 0..<4 { c.rect(dx - 2 * s - k * s, gy + 6 * s + k * s, s, s, C(0x1E1E22)); c.rect(dx + 5 * s + k * s, gy + 6 * s + k * s, s, s, C(0x1E1E22)) }
            c.rect(b.x + 4 * s, gy + 2 * s, 6 * s, 4 * s, C(0x34465E))                       // parlour window
            c.rect(b.x + 4 * s, gy + 2 * s, 6 * s, s, C(0x86A4C6))
            c.rect(b.x + 4 * s, base - 3 * s, 6 * s, 2 * s, C(0x222630))                      // basement window, barred
            for k in 0..<3 { c.rect(b.x + 5 * s + k * 2 * s, base - 3 * s, max(1, s / 2), 2 * s, C(0x101214)) }
        } else {
            c.rect(b.x + s, gy, b.w - s, gh, C(0x2C2C32))
            let glassY = gy + 5 * s
            c.rect(b.x + 3 * s, glassY, b.w - 5 * s, gh - 5 * s, C(0x5A7290))
            for k in 0..<3 {                                                                 // reflections
                let rx = b.x + 5 * s + k * b.w / 4
                for j in 0..<(gh - 5 * s) { c.px(rx + j / 2, glassY + gh - 5 * s - 1 - j, C(0xB8D0E4, 0.5)) }
            }
            let doorX = b.x + b.w * 2 / 3
            c.rect(doorX, glassY, 4 * s, gh - 5 * s, C(0x26303C)); c.rect(doorX + 3 * s, glassY + 2 * s, max(1, s / 2), s, C(0xD8C060))
            let awnings: [(Px, Px)] = [(C(0x2E7A44), white), (C(0xB82A2A), white), (C(0x2A4A8A), C(0xE8E4D8)), (C(0xD8A030), C(0x8A3A1A))]
            let (a1, a2) = b.store == 1 ? (C(0x2E7A44), C(0xF0EEE4)) : awnings[(b.store - 2) % awnings.count]
            for x in (b.x + s)..<(b.x + b.w) {                                               // striped awning
                let stripe = ((x - b.x) / (2 * s)) % 2 == 0
                c.rect(x, gy + 3 * s, 1, 2 * s, stripe ? a1 : a2)
                if ((x - b.x) / (2 * s)) % 2 == 0 { c.px(x, gy + 5 * s, a1) }
            }
            if b.store == 1 {
                // Delmont's: a red sign board over the awning, and DELI in the window.
                let sw = 39 * s, sx = b.x + (b.w - sw) / 2
                c.rect(sx, gy - 4 * s, sw, 7 * s, C(0xB82424)); c.rect(sx, gy - 4 * s, sw, s, C(0xD84A3A))
                c.rect(sx, gy + 2 * s, sw, s, C(0x7A1414))
                s7Text(c, sx + 2 * s, gy - 3 * s, "DELMONT'S", C(0xFFF4D8), k: s)
                s7Text(c, b.x + 5 * s, glassY, "DELI", C(0xFFD040), k: s)
            } else {
                c.rect(b.x + s, gy, b.w - s, 3 * s, C(0x1E1E24))
                for x in stride(from: b.x + 4 * s, to: b.x + b.w - 4 * s, by: 2 * s) where noise(x + 7230) > 0.3 {
                    c.rect(x, gy + s, s, s, a2.alpha(0.85))                                    // the shop's lettering
                }
            }
        }
    }

    /// A rooftop water tower: a wooden tank with iron hoops on a frame of legs, under a pointed roof.
    static func newYorkWaterTower(_ c: PixelCanvas, x: Int, roof: Int, s: Int) {
        let wood = C(0x8A5E3E), shade = C(0x6A4630), iron = C(0x2E2A28)
        for k in [0, 7] { c.rect(x + k * s, roof - 5 * s, s, 5 * s, iron) }
        for k in 0..<5 { c.px(x + s + k * s * 6 / 5, roof - 5 * s + k * s, iron); c.px(x + 7 * s - k * s * 6 / 5, roof - 5 * s + k * s, iron) }
        c.rect(x - s, roof - 6 * s, 10 * s, s, iron)
        let ty = roof - 14 * s
        c.rect(x - s, ty, 10 * s, 8 * s, wood)
        c.rect(x + 6 * s, ty, 3 * s, 8 * s, shade)
        for k in 0..<4 { c.rect(x + k * 2 * s, ty, max(1, s / 2), 8 * s, shade.alpha(0.5)) }
        for y in stride(from: ty + s, to: ty + 8 * s, by: 3 * s) { c.rect(x - s, y, 10 * s, max(1, s / 2), iron) }
        for k in 0..<4 { c.rect(x - s + k * s * 5 / 4, ty - 1 - k * s, 10 * s - k * s * 5 / 2, s, k % 2 == 0 ? C(0x5A4636) : C(0x4A3A2E)) }
        c.rect(x + 4 * s, ty - 6 * s, max(1, s / 2), 2 * s, iron)
    }

    /// A black iron fire escape down the middle of a walk-up: a railed platform at each floor, ladders between.
    static func newYorkFireEscape(_ c: PixelCanvas, x: Int, top: Int, floors: Int, fh: Int, s: Int) {
        let iron = C(0x1E1E22), x0 = x - 9 * s, w = 18 * s
        for f in 0..<floors {
            let py = top + s + f * fh + 6 * s
            c.rect(x0, py - s, w, s, iron)
            c.rect(x0, py - 4 * s, w, max(1, s / 2), iron)
            for k in stride(from: 0, through: w, by: 3 * s) { c.rect(x0 + k, py - 4 * s, max(1, s / 2), 3 * s, iron.alpha(0.8)) }
            if f + 1 < floors {
                let left = f % 2 == 0
                for k in 0..<fh { c.px(left ? x0 + 3 * s + k : x0 + w - 3 * s - k, py + k, iron) }
            }
        }
    }

    /// A subway entrance: a railed stairwell, two green globe lamps, and the SUBWAY sign between them.
    static func newYorkSubway(_ c: PixelCanvas, x: Int, walk: Int, s: Int) {
        let iron = C(0x26302A)
        c.rect(x - 11 * s, walk, 22 * s, 2 * s, C(0x3A3A3E))                     // the stair well going down
        c.rect(x - 11 * s, walk - 4 * s, 22 * s, s, iron)
        for k in stride(from: 0, through: 22 * s, by: 2 * s) { c.rect(x - 11 * s + k, walk - 4 * s, max(1, s / 2), 4 * s, iron) }
        c.rect(x - 11 * s, walk - 2 * s, 22 * s, max(1, s / 2), iron)
        for side in [-1, 1] {
            let px = x + side * 13 * s
            c.rect(px, walk - 13 * s, s, 13 * s, iron)
            c.circle(px, walk - 15 * s, 2 * s, C(0x2E9A4E)); c.rect(px - s, walk - 16 * s, s, s, C(0x9AE8A8))
        }
        c.rect(x - 12 * s, walk - 12 * s, 24 * s, 7 * s, C(0x161618))
        c.rect(x - 12 * s, walk - 12 * s, 24 * s, s, C(0x3A3A3E))
        s7Text(c, x - 11 * s, walk - 11 * s, "SUBWAY", white, k: s)
    }

    /// The Midtown skyline in the haze: far towers, the Empire State and Chrysler buildings, then a nearer row.
    static func newYorkSkyline(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        func towers(seed: Int, lo: Double, span: Double, body: Px, lit: Px, win: Px) {
            var x = -Int(noise(seed) * 10) * s, i = 0
            while x < c.w {
                let w = (8 + Int(noise(i * 3 + seed + 1) * 14)) * s
                let top = Int(Double(g) * (lo + noise(i * 3 + seed + 2) * span))
                c.rect(x, top, w, g - top, body)
                c.rect(x, top, max(1, w / 3), g - top, lit)
                for y in stride(from: top + 2 * s, to: g, by: 3 * s) {
                    for wx in stride(from: x + s, to: x + w - s, by: 2 * s) { c.rect(wx, y, s, s, win) }
                }
                if noise(i * 3 + seed + 3) > 0.75 { c.rect(x + w / 2, top - 4 * s, max(1, s / 2), 4 * s, body) }
                x += w + Int(noise(i * 3 + seed + 4) * 5) * s; i += 1
            }
        }
        towers(seed: 7300, lo: tall ? 0.32 : 0.08, span: tall ? 0.3 : 0.24, body: C(0xA8BCD4), lit: C(0xBACCE0), win: C(0x98AECA))
        let eTop = tall ? g * 12 / 100 : 2 * s, cTop = tall ? g * 19 / 100 : 6 * s
        newYorkEmpireState(c, x: c.w * 38 / 100, top: eTop, base: g)
        newYorkChrysler(c, x: c.w * 64 / 100, top: cTop, base: g)
        towers(seed: 7350, lo: tall ? 0.45 : 0.2, span: tall ? 0.22 : 0.16, body: C(0x92A6C0), lit: C(0xA2B6CE), win: C(0x8296B2))
    }

    /// The Empire State Building: stepped setbacks up to the mast and antenna, its piers catching the light.
    static func newYorkEmpireState(_ c: PixelCanvas, x: Int, top: Int, base: Int) {
        let H = Double(base - top), bw = max(12, Int(H / 4.5))
        let body = C(0x8A9CB6), lit = C(0xAABCD2), dark = C(0x72849E)
        func tier(_ y0: Double, _ y1: Double, _ hw: Int) {
            let a = top + Int(H * y0), b = top + Int(H * y1)
            c.rect(x - hw, a, hw * 2 + 1, b - a, body)
            c.rect(x - hw, a, max(1, hw * 2 / 3), b - a, lit)
            c.rect(x + hw, a, 1, b - a, dark)
        }
        c.rect(x, top, 1, Int(H * 0.1), dark)
        tier(0.08, 0.16, max(1, bw / 12))
        tier(0.15, 0.21, max(1, bw / 6))
        tier(0.2, 0.25, bw / 4)
        tier(0.24, 0.3, bw * 3 / 8)
        tier(0.29, 0.75, bw / 2)
        tier(0.74, 1, bw * 3 / 4)
        let y0 = top + Int(H * 0.3)
        for px in stride(from: x - bw / 2 + 2, to: x + bw / 2 - 1, by: 3) { c.rect(px, y0, 1, base - y0, dark.alpha(0.5)) }
    }

    /// The Chrysler Building: its needle and stacked steel arches with their triangular windows, over a slim shaft.
    static func newYorkChrysler(_ c: PixelCanvas, x: Int, top: Int, base: Int) {
        let H = Double(base - top), bw = max(8, Int(H / 6))
        let steel = C(0xDCE2EA), steelDk = C(0xA4AEBE), win = C(0x4A5468), body = C(0x8C9EB8), lit = C(0xA6B8CE)
        let needleEnd = top + Int(H * 0.14)
        c.rect(x, top, 1, needleEnd - top, steelDk)
        c.rect(x - 1, top + Int(H * 0.09), 3, needleEnd - top - Int(H * 0.09), steel)
        for k in 0..<5 {                                                   // five stacked arches, each a little wider
            let hw = max(2, bw / 2 - (4 - k) * bw / 10), ay = needleEnd + Int(H * 0.034 * Double(k)), ry = hw * 3 / 2
            c.ellipse(x, ay + ry, hw, ry, steel)
            c.ellipse(x + hw / 2 + 1, ay + ry, max(1, hw / 2), ry - 1, steelDk)
            s7Ring(c, Double(x), Double(ay + ry), Double(hw), Double(ry), steelDk, n: 24 + hw * 4)
            if hw >= 3 {                                                    // the triangular windows round the arch
                for a in stride(from: 0.35, to: 2.9, by: 0.5) {
                    let wx = x - Int(cos(a) * Double(hw - 1)), wy = ay + ry - Int(sin(a) * Double(ry - 1))
                    c.px(wx, wy, win); c.px(wx, wy + 1, win.alpha(0.6))
                }
            }
        }
        let sy = needleEnd + Int(H * 0.17)
        c.rect(x - bw / 2, sy, bw + 1, base - sy, body)
        c.rect(x - bw / 2, sy, max(1, bw / 3), base - sy, lit)
        let wy = top + Int(H * 0.52)
        c.rect(x - bw * 3 / 4, wy, bw * 3 / 2 + 1, base - wy, body)
        c.rect(x - bw * 3 / 4, wy, max(1, bw / 2), base - wy, lit)
        for y in stride(from: sy + 2, to: base, by: 3) { c.rect(x - bw / 2 + 1, y, bw - 1, 1, steelDk.alpha(0.35)) }
    }

    /// Cabs driving both ways, people walking the far sidewalk, pigeons pecking, and the traffic light cycling.
    static func newYorkStreetsLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g), r = newYorkRows(g)
        // The traffic light.
        let cyc = t.truncatingRemainder(dividingBy: 10)
        let lamp = cyc < 4.5 ? 2 : (cyc < 5.6 ? 1 : 0)
        let sig = newYorkSignal(c, g)
        let lit = [C(0xFF4A3A), C(0xFFC040), C(0x4AF08A)][lamp]
        c.circle(sig.x + s + s / 2, sig.y + lamp * 4 * s + s, 3 * s, lit.alpha(0.25))
        c.rect(sig.x, sig.y + lamp * 4 * s, 3 * s, 3 * s, lit)
        c.rect(sig.x, sig.y + lamp * 4 * s, s, s, white.alpha(0.7))
        // People on the far sidewalk.
        let coats = [C(0x2A3A6A), C(0x8A2A2A), C(0x3A5A3A), C(0x6A5A4A), C(0xC8A040), C(0x2A2A2E)]
        let skins = [C(0xE8C0A0), C(0xA87050), C(0x6A4430), C(0xD8A884)]
        for i in 0..<max(3, c.w / (70 * s)) {
            let dir = noise(i * 5 + 7500) > 0.5 ? 1.0 : -1.0
            let speed = (5 + noise(i * 5 + 7501) * 5) * Double(s), span = Double(c.w + 20 * s)
            let p = (t * speed + noise(i * 5 + 7502) * span).truncatingRemainder(dividingBy: span)
            let x = dir > 0 ? Int(p) - 10 * s : c.w + 10 * s - Int(p)
            let foot = r.walk + 2 * s, step = Int(t * speed / Double(2 * s)) % 2
            c.rect(x, foot - 7 * s, 2 * s, 2 * s, skins[i % skins.count])
            c.rect(x, foot - 8 * s, 2 * s, s, C(0x2A2018))
            c.rect(x - s / 2, foot - 5 * s, 3 * s, 3 * s, coats[i % coats.count])
            c.rect(x + (step == 0 ? -s / 2 : 0), foot - 2 * s, s, 2 * s, C(0x24242A))
            c.rect(x + s + (step == 0 ? s / 2 : 0), foot - 2 * s, s, 2 * s, C(0x24242A))
        }
        // Cabs: the far lane heads left, the near lane right.
        for i in 0..<(c.w > 700 ? 5 : 3) {
            let right = i % 2 == 1
            let speed = (26 + noise(i * 5 + 7400) * 22) * Double(s), span = Double(c.w + 50 * s)
            let p = (t * speed + noise(i * 5 + 7401) * span).truncatingRemainder(dividingBy: span)
            let x = right ? Int(p) - 25 * s : c.w + 25 * s - Int(p)
            newYorkCab(c, x: x, y: right ? g - 8 * s : g - 10 * s, k: s, right: right)
        }
        // Pigeons pecking at the kerb, and one crossing the sky now and then.
        for (i, fx) in [0.06, 0.09, 0.93].enumerated() {
            let x = Int(fx * Double(c.w)), peck = sin(t * 5 + Double(i) * 2) > 0.4
            let y = g + 3 * s
            c.rect(x, y, 3 * s, 2 * s, C(0x7A7C88)); c.rect(x + 2 * s, y - s, s, s, C(0x5A6070))
            if peck { c.rect(x + 3 * s, y + s, s, s, C(0x5A6070)) } else { c.rect(x + 3 * s, y - s, s, s, C(0x5A6070)) }
            c.rect(x, y, s, s, C(0x9A9CA8))
        }
        let q = (t * 0.06).truncatingRemainder(dividingBy: 1), flap = sin(t * 14) > 0
        let bx = Int(q * Double(c.w + 40)) - 20, by = Int(Double(g) * 0.3) + Int(sin(t) * 3)
        c.rect(bx, by, 3 * s, s, C(0x5A5E6A)); c.rect(bx + s, by + (flap ? -s : s), s, s, C(0x5A5E6A))
    }

    /// A yellow cab, `k` pixels a unit, heading right or left: roof light, windows, chequered stripe, wheels.
    static func newYorkCab(_ c: PixelCanvas, x: Int, y: Int, k: Int, right: Bool) {
        let cab = ["........mmm.........",
                   ".....yyyyyyyy.......",
                   "....ygggyggggy......",
                   "...yggggyggggyy.....",
                   ".yyyyyyyyyyyyyyyyyy.",
                   "ryyyyyyykyyyyyyyyyyh",
                   "yycwcwcwcwcwcwcwyyyy",
                   ".yykkkyyyyyyyykkkyy.",
                   "...kak........kak...", ]
        s7Sprite(c, x, y, cab, ["m": C(0xFFF0B0), "y": C(0xF2C02A), "g": C(0x2E3A4A), "k": C(0x1A1A1E), "r": C(0xD02A2A),
                                "h": C(0xFFF8E0), "c": C(0x1A1A1E), "w": C(0xF8F0D0), "a": C(0x9A9AA0)], k: k, flip: !right)
    }

    // MARK: - Savage Land Citadel

    /// Magneto's citadel in the Savage Land: a jagged fortress of steel shards raised on a crag, crimson M sigil on its
    /// great spire, under a violet-and-amber sky. Smoking volcanoes and the glacier rim stand behind, the jungle laps
    /// round its feet, and steaming vents crack the black soil. Pterodactyls wheel, the vents and volcanoes steam and
    /// the sigil's field pulses in `savageLandCitadelLife`.
    static func savageLandCitadel(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x3A2E5C), C(0xF2A866), bands: 7)
        if tall {
            for i in 0..<7 {
                let x = Int(noise(i * 5 + 7600) * Double(c.w)), y = Int(Double(g) * (0.08 + noise(i * 5 + 7601) * 0.4))
                wisp(c, x, y, (50 + Int(noise(i * 5 + 7602) * 90)) * s, C(0xF8B8A0, 0.4), s: s)
            }
        }
        let sun = (x: c.w * 22 / 100, y: Int(Double(g) * (tall ? 0.62 : 0.5)))
        c.circle(sun.x, sun.y, max(6, g / 9), C(0xFFD49A, 0.3))
        c.circle(sun.x, sun.y, max(4, g / 14), C(0xFFE6B8))
        // The glacier rim, far off.
        for x in 0..<c.w {
            let fx = Double(x)
            let h = Double(g) * 0.1 + sin(fx * 0.05) * 3 + sin(fx * 0.17) * 1.5
            let top = g - 18 * s - Int(h)
            c.rect(x, top, 1, g - top, sin(fx * 0.12) > 0.3 ? C(0xC4B4CC) : C(0xDACCD8))
            c.px(x, top, C(0xF4E8F0))
        }
        for v in savageLandCitadelVolcanoes(c, g) { savageLandCitadelVolcano(c, v) }
        c.gradient(g - 26 * s, g - 14 * s, C(0xF2A866, 0), C(0xF2A866, 0.5), bands: 4)        // haze
        savageLandCitadelCanopy(c, base: g - 10 * s, top: g - 19 * s, k: s, col: C(0x3E5E4A), lite: C(0x56785A), seed: 3)
        savageLandCitadelCrag(c, g)
        savageLandCitadelFortress(c, g)
        savageLandCitadelCanopy(c, base: g - 3 * s, top: g - 11 * s, k: s, col: C(0x24442E), lite: C(0x3A6040), seed: 4)
        savageLandCitadelPalm(c, x: c.w * 4 / 100, base: g, h: 30 * s + (tall ? g / 4 : 0), lean: 4, k: s)
        savageLandCitadelPalm(c, x: c.w * 97 / 100, base: g, h: 24 * s + (tall ? g / 5 : 0), lean: -3, k: s)
        for v in savageLandCitadelVents(c, g) {                                              // steam vents
            c.ellipse(v.x, g - s, 7 * s, 3 * s, C(0x3A3230))
            c.ellipse(v.x - s, g - 2 * s, 5 * s, 2 * s, C(0x54484A))
            c.rect(v.x - s, g - 3 * s, 3 * s, s, C(0xFF8A3A))
            c.rect(v.x, g - 3 * s, s, s, C(0xFFD080))
        }
        // Black volcanic soil, ferns at the edge.
        c.ground(g, C(0x2E2624), edge: C(0x4E5A30), speck: C(0x3E3430), seed: 76)
        for (i, x) in stride(from: 5, to: c.w, by: 11).enumerated() where noise(i * 3 + 7610) > 0.45 {
            let fh = 3 + Int(noise(i * 3 + 7611) * 4)
            let col = i % 2 == 0 ? C(0x2E5A2A) : C(0x467A34)
            for k in 0..<fh { c.px(x - k / 2, g - k, col); c.px(x + k / 2, g - k, col) }
        }
        for i in 0..<(c.w / 12) {                                                            // glints of ore
            c.px(Int(noise(i * 2 + 7615) * Double(c.w)), g + 2 + Int(noise(i * 2 + 7616) * Double(max(1, c.h - g - 3))), C(0x8A8A98))
        }
    }

    /// The volcanoes behind the citadel: crater centre, crater row, half-width at the foot.
    static func savageLandCitadelVolcanoes(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int)] {
        let tall = isTall(c), s = unit(g)
        let h1 = tall ? g * 34 / 100 : g * 50 / 100, h2 = tall ? g * 22 / 100 : g * 34 / 100
        return [(c.w * 12 / 100, g - 16 * s - h1, h1 * 3 / 2), (c.w * 88 / 100, g - 16 * s - h2, h2 * 3 / 2)]
    }

    /// The steam vents along the floor's edge.
    static func savageLandCitadelVents(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        [(c.w * 16 / 100, g), (c.w * 83 / 100, g)]
    }

    /// A volcano: dark concave flanks, lava runs from a glowing crater, a column of ash.
    static func savageLandCitadelVolcano(_ c: PixelCanvas, _ v: (x: Int, y: Int, w: Int)) {
        let base = c.h
        let h = max(1, base - v.y)
        for y in v.y..<base {
            let u = Double(y - v.y) / Double(h)
            let half = v.w / 7 + Int(Double(v.w - v.w / 7) * pow(u, 1.6))
            c.rect(v.x - half, y, half, 1, C(0x5A3E4E))
            c.rect(v.x, y, half, 1, C(0x40283A))
        }
        for k in 0..<2 {
            var lx = Double(v.x - v.w / 14 + k * v.w / 7)
            for y in v.y..<(v.y + h * (1 + k) / 4) {
                lx += (noise(y * 3 + k * 50 + 7620) - 0.5) * 1.2 + Double(k * 2 - 1) * 0.3
                c.px(Int(lx), y, C(0xFF7A30, 0.9))
            }
        }
        c.rect(v.x - v.w / 7, v.y, v.w * 2 / 7, 1, C(0xFFB050))
        for k in 0..<7 {
            let r = 2 + k * 2
            c.circle(v.x - k * k / 2, v.y - 3 - k * 4, r, C(0x4A3A4A).alpha(0.5 - Double(k) * 0.05))
        }
    }

    /// A band of rounded jungle treetops from `top` down to `base`.
    static func savageLandCitadelCanopy(_ c: PixelCanvas, base: Int, top: Int, k: Int, col: Px, lite: Px, seed: Int) {
        c.rect(0, (base + top) / 2, c.w, base - (base + top) / 2 + 1, col)
        let dark = lerp(col, C(0x081008), 0.35)
        var x = 0, i = 0
        while x < c.w + 10 {
            let r = (2 + Int(noise(seed * 50 + i + 7630) * 5)) * k
            let y = top + Int(noise(seed * 50 + i + 7650) * Double(max(1, base - top - r)))
            c.circle(x + k, y + r + k, r, dark)
            c.circle(x, y + r, r, col); c.circle(x - r / 3, y + r - r / 3, max(1, r / 2), lite)
            x += r + k + Int(noise(seed * 50 + i + 7670) * 3) * k; i += 1
        }
    }

    /// The black crag the fortress stands on, with ledges and fissures.
    static func savageLandCitadelCrag(_ c: PixelCanvas, _ g: Int) {
        let f = savageLandCitadelFrame(c, g)
        let hw = Double(f.H) * 0.62 * savageLandCitadelSpread(c), cx = Double(f.x), base = Double(g - 6 * unit(g)), top = Double(f.base)
        s7Poly(c, [(cx - hw * 1.25, base), (cx - hw, top + 6), (cx - hw * 0.7, top - 1), (cx + hw * 0.75, top - 1),
                   (cx + hw * 1.05, top + 5), (cx + hw * 1.3, base)], C(0x3A3038))
        s7Poly(c, [(cx + hw * 0.2, top), (cx + hw * 0.75, top - 1), (cx + hw * 1.05, top + 5), (cx + hw * 1.3, base),
                   (cx + hw * 0.5, base)], C(0x2C2430))
        for i in 0..<6 {
            let x0 = cx - hw + noise(i * 3 + 7680) * hw * 2
            var x = x0
            for y in Int(top + 2)..<Int(base) where noise(y + i * 40 + 7690) > 0.2 {
                x += (noise(y * 2 + i + 7700) - 0.5) * 1.5
                c.px(Int(x), y, C(0x1E1820))
            }
        }
    }

    /// The fortress's footprint: centre column, the row its shards stand on, and its height.
    static func savageLandCitadelFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, base: Int, H: Int) {
        let s = unit(g), tall = isTall(c)
        let base = g - (tall ? 22 : 13) * s
        let top = tall ? g * 16 / 100 : 2
        return (c.w * 56 / 100, base, base - top)
    }

    /// How much wider than tall the citadel is drawn: the window's strip is short, so it spreads out there.
    static func savageLandCitadelSpread(_ c: PixelCanvas) -> Double { isTall(c) ? 1 : 1.6 }

    /// The citadel: a curtain wall with jagged teeth, steel shards leaning out from a great central spire, lit on
    /// their left faces, glowing window slits, and the crimson M sigil on the spire.
    static func savageLandCitadelFortress(_ c: PixelCanvas, _ g: Int) {
        let f = savageLandCitadelFrame(c, g), H = Double(f.H), cx = Double(f.x), base = Double(f.base)
        let steel = C(0x7E8698), lit = C(0xB4BCCA), shade = C(0x4E5466), edge = C(0xE4E8F0), slit = C(0xA8E4F4)
        // dx, height, half-width, lean (all fractions of H)
        let sp = savageLandCitadelSpread(c)
        let shards: [(Double, Double, Double, Double)] = [
            (-0.5, 0.26, 0.07, -0.12), (0.52, 0.3, 0.07, 0.13), (-0.36, 0.46, 0.08, -0.13), (0.38, 0.5, 0.08, 0.14),
            (-0.21, 0.68, 0.075, -0.08), (0.22, 0.74, 0.075, 0.09), (-0.1, 0.54, 0.05, -0.03), (0.1, 0.6, 0.05, 0.04),
            (0, 1.0, 0.11, 0),
        ]
        for (dx, hf, wf, lean) in shards {
            let x = cx + dx * H * sp, hw = max(2, wf * H * sp), h = hf * H, top = base - h, tip = x + lean * H
            let sl = top + h * 0.3, sr = top + h * 0.22
            s7Poly(c, [(x - hw, base), (x + hw, base), (x + hw * 0.8, sr), (tip, top), (x - hw * 0.9, sl)], steel)
            s7Poly(c, [(x + hw * 0.1, base), (x + hw, base), (x + hw * 0.8, sr), (tip, top)], shade)
            s7Poly(c, [(x - hw, base), (x - hw * 0.55, base), (tip - hw * 0.1, top + 2), (x - hw * 0.9, sl)], lit)
            let n = 12
            for k in 0...n {                                                   // bright edge up the left ridge
                let u = Double(k) / Double(n)
                c.px(Int(x - hw * 0.9 + (tip - (x - hw * 0.9)) * u), Int(sl + (top - sl) * u), edge)
            }
            for y in stride(from: Int(top + h * 0.35), to: Int(base) - 3, by: max(5, Int(h / 7))) {     // slits
                c.rect(Int(x), y, max(1, Int(hw / 4)), max(2, Int(H / 40)), slit)
            }
        }
        // The curtain wall with its jagged crest.
        let wh = H * 0.13, ww = H * 0.6 * sp
        s7Poly(c, [(cx - ww, base + 2), (cx + ww, base + 2), (cx + ww * 0.92, base - wh), (cx - ww * 0.92, base - wh)], C(0x666E80))
        for k in 0..<14 {
            let x = cx - ww * 0.92 + Double(k) * ww * 1.84 / 13, th = wh * (0.4 + noise(k + 7710) * 0.6)
            s7Poly(c, [(x - 3, base - wh + 1), (x + 3, base - wh + 1), (x + (noise(k + 7711) - 0.5) * 3, base - wh - th)],
                   k % 2 == 0 ? C(0x8C94A4) : C(0x5A6274))
        }
        c.rect(Int(cx - ww * 0.92), Int(base - wh), Int(ww * 1.84), 1, edge.alpha(0.6))
        c.rect(Int(cx - ww), Int(base), Int(ww * 2), 2, C(0x3E4454))
        let gateH = max(4, Int(wh * 0.8)), gateW = max(3, Int(H * 0.05))
        s7Poly(c, [(cx - Double(gateW), base + 2), (cx + Double(gateW), base + 2), (cx, base + 2 - Double(gateH) * 1.3)], C(0x1E1A28))
        // The M sigil on the great spire.
        let k = max(1, Int(H * sp / 40)), mw = 9 * k, my = Int(base - H * 0.62)
        let mx = Int(cx) - mw / 2
        s7Poly(c, [(Double(mx - k), Double(my - k)), (Double(mx + mw + k), Double(my - k)), (Double(mx + mw + k), Double(my + 7 * k)),
                   (cx, Double(my + 10 * k)), (Double(mx - k), Double(my + 7 * k))], C(0x5A2470))
        s7Sprite(c, mx, my, ["rr.....rr", "rrr...rrr", "rrrr.rrrr", "rr.rrr.rr", "rr..r..rr", "rr.....rr", "rr.....rr"],
                 ["r": C(0xD02838)], k: k)
        c.rect(mx - k, my - k, mw + 2 * k, max(1, k / 2), C(0xB070D0))
    }

    /// A palm: a ringed, leaning trunk under drooping fronds.
    static func savageLandCitadelPalm(_ c: PixelCanvas, x: Int, base: Int, h: Int, lean: Int, k: Int) {
        for y in 0..<h {
            let u = Double(y) / Double(h)
            c.rect(x + Int(u * u * Double(lean * k * 3)) - k, base - y, 2 * k + 1, 1, (y / (2 * k)) % 2 == 0 ? C(0x5A4230) : C(0x40301E))
        }
        let tx = x + lean * k * 3, ty = base - h
        for (i, dir) in [-1.0, -0.65, -0.3, 0.3, 0.65, 1.0].enumerated() {
            let len = Double((13 + i % 2 * 4) * k)
            for j in 0..<Int(len) {
                let u = Double(j) / len
                let fx = tx + Int(dir * Double(j))
                let fy = ty - Int(sin(u * .pi * 0.7) * len * 0.3 * (1.2 - abs(dir) * 0.5)) + Int(u * u * len * 0.45)
                c.rect(fx, fy, k, k, C(0x24502A))
                if j % 2 == 0 { c.rect(fx, fy + k, k, k, C(0x1A3E20)) }
            }
        }
    }

    /// Pterodactyls wheeling, steam rising from the vents and ash from the volcanoes, and a magnetic pulse round the M.
    static func savageLandCitadelLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g)
        for (j, v) in savageLandCitadelVents(c, g).enumerated() {
            for i in 0..<7 {
                let p = (t * 0.35 + Double(i) / 7 + Double(j) * 0.37).truncatingRemainder(dividingBy: 1)
                let x = v.x + Int(sin(t * 0.8 + Double(i) * 1.7) * 3 * p * Double(s)) + Int(p * 6 * Double(s))
                let y = g - 3 * s - Int(p * 30 * Double(s))
                c.circle(x, y, Int((1.5 + p * 4) * Double(s)), C(0xF0E8E8, 0.45 * (1 - p)))
            }
        }
        for v in savageLandCitadelVolcanoes(c, g) {
            c.rect(v.x - v.w / 7, v.y, v.w * 2 / 7, 1, C(0xFFE080, 0.4 + 0.4 * noise(Int(t * 5) + v.x)))
            for i in 0..<5 {
                let p = (t * 0.12 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                c.circle(v.x - Int(p * p * 30), v.y - 4 - Int(p * 40), 2 + Int(p * 10), C(0x5A4656, 0.3 * (1 - p)))
            }
        }
        // The sigil's field: rings swelling out from the M.
        let f = savageLandCitadelFrame(c, g), H = Double(f.H)
        let sp = savageLandCitadelSpread(c), mk = max(1, Int(H * sp / 40))
        let my = Double(Int(Double(f.base) - H * 0.62) + 7 * mk / 2)
        for i in 0..<2 {
            let p = (t * 0.4 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
            let r = H * sp * (0.08 + p * 0.3)
            s7Ring(c, Double(f.x), my, r * 1.3, r * 0.7, C(0xC070FF, 0.45 * (1 - p)), n: 40 + Int(r))
        }
        let n = isTall(c) ? 5 : 3
        for i in 0..<n {
            let speed = 0.03 + noise(i * 5 + 7720) * 0.03
            let q = (t * speed + noise(i * 5 + 7721)).truncatingRemainder(dividingBy: 1)
            let dir = i % 2 == 0 ? -1 : 1, span = Double(c.w + 60)
            let x = dir > 0 ? Int(q * span) - 30 : c.w + 30 - Int(q * span)
            let y = Int(Double(g) * (0.1 + noise(i * 5 + 7722) * 0.3)) + Int(sin(t * 0.7 + Double(i)) * 4)
            savageLandCitadelPterodactyl(c, x: x, y: y, k: s * (i == 0 && isTall(c) ? 2 : 1), dir: dir, flap: sin(t * 2.2 + Double(i) * 2))
        }
    }

    /// A pterodactyl in silhouette against the sunset: swept wings flexing with `flap`, long beak, back-swept crest.
    static func savageLandCitadelPterodactyl(_ c: PixelCanvas, x: Int, y: Int, k: Int, dir: Int, flap: Double) {
        let body = C(0x2A1E2A), wing = C(0x3E2A38), kk = Double(k), fx = Double(x), fy = Double(y), f = flap * 2 * kk
        for side in [-1.0, 1.0] {
            s7Poly(c, [(fx - kk, fy), (fx + side * 6 * kk, fy - 2 * kk + f * 0.5), (fx + side * 12 * kk, fy + f),
                       (fx + side * 4 * kk, fy + 1.5 * kk)], wing)
        }
        c.rect(x - 2 * k, y, 4 * k, k + 1, body)
        c.rect(x + dir * 2 * k - (dir < 0 ? 2 * k : 0), y - k, 2 * k, k + 1, body)
        c.rect(x + dir * 4 * k - (dir < 0 ? 3 * k : 0), y - k / 2, 3 * k, max(1, k / 2 + 1), body)
        c.rect(x + dir * k - (dir < 0 ? 2 * k : 0) - dir * k, y - 2 * k, 2 * k, k, body)
    }

    // MARK: - Tony Stark's Workshop

    /// Tony Stark's Malibu basement workshop: polished concrete under strip lights, his hot rod and a silver roadster on
    /// lit turntables, the Hall of Armour behind glass (red-and-gold, silver and War Machine suits in lit alcoves),
    /// a pegboard of tools over the workbench, holographic blue displays, and Dum-E in his corner wearing the dunce
    /// cap. The holograms rotate and scan, and the screens glow in `starkWorkshopLife`.
    static func starkWorkshop(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x141920), C(0x2E3640), bands: 5)
        let ceil = tall ? g / 12 : 4 * s
        c.rect(0, 0, c.w, ceil, C(0x0A0C10))
        for x in stride(from: 8 * s, to: c.w, by: 44 * s) {                       // recessed light strips and their wash
            c.rect(x, ceil - s, 24 * s, s, C(0xD8ECF8))
            for k in 0..<(14 * s) { c.rect(x - k / 2, ceil + k, 24 * s + k, 1, C(0xA8C8E0, 0.1 * (1 - Double(k) / Double(14 * s)))) }
        }
        for x in stride(from: 0, to: c.w, by: 34 * s) {                           // wall panel seams
            c.rect(x, ceil, s, g - ceil, C(0x0C0F14)); c.rect(x + s, ceil, s, g - ceil, C(0x2E3640, 0.6))
        }
        if tall { starkWorkshopUpper(c, g) }
        starkWorkshopGallery(c, g)
        // The cars, each on a lit turntable.
        let cy = g - s, k = starkWorkshopK(c, g)
        for (fx, w) in [(0.025, 30), (0.16, 28)] {
            let x = Int(fx * Double(c.w))
            c.ellipse(x + w * k / 2, cy, w * k / 2 + 3 * k, 2 * k, C(0x1A1E24))
            c.ellipse(x + w * k / 2, cy, w * k / 2 + 3 * k, max(1, k), C(0x4AC8F0, 0.35))
        }
        starkWorkshopHotRod(c, x: Int(0.025 * Double(c.w)) + k, base: cy - s, k: k)
        starkWorkshopRoadster(c, x: Int(0.16 * Double(c.w)) + k, base: cy - s, k: k)
        starkWorkshopBench(c, g)
        starkWorkshopDumE(c, x: c.w * 95 / 100, base: g, k: k)
        let hs = starkWorkshopHoloSuit(c, g)                                   // the suit hologram's projector pad
        c.ellipse(hs.x, g - s, 7 * s, 2 * s, C(0x2A3038)); c.ellipse(hs.x, g - s, 5 * s, max(1, s), C(0x6AD8FF, 0.6))
        c.rect(0, g - 2 * s, c.w, max(1, s / 2), C(0x6AD8FF, 0.25))            // LED strip along the wall's foot
        // Still parts of the holograms: the panels' frames.
        for p in starkWorkshopHoloPanels(c, g) {
            c.rect(p.x, p.y, p.w, p.h, C(0x3AB8F0, 0.1))
            c.rect(p.x, p.y, p.w, max(1, s / 2), C(0x6AD8FF, 0.6)); c.rect(p.x, p.y + p.h - 1, p.w, 1, C(0x6AD8FF, 0.35))
            for y in stride(from: p.y + 3 * s, to: p.y + p.h - 2 * s, by: 2 * s) {
                c.rect(p.x + 2 * s, y, Int(Double(p.w - 4 * s) * (0.3 + noise(y + p.x + 7800) * 0.7)), max(1, s / 2), C(0x8AE4FF, 0.4))
            }
        }
        // Polished floor, catching the lights.
        c.ground(g, C(0x262A30), edge: C(0x56626E), speck: C(0x2E333A), seed: 78)
        for x in stride(from: 8 * s, to: c.w, by: 44 * s) { c.rect(x, g + 2, 24 * s, max(1, s), C(0xD8ECF8, 0.08)) }
        let gal = starkWorkshopGalleryBox(c, g)
        c.rect(gal.x0, g + 1, gal.x1 - gal.x0, max(1, s), C(0x6AD8FF, 0.12))
        for x in stride(from: 0, to: c.w, by: 40 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x1E2228)) }
    }

    /// Pixels a unit for the workshop's furniture: bigger full screen, so the cars and bench keep their size.
    static func starkWorkshopK(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(unit(g), g / 120) : unit(g) }

    /// Where the Hall of Armour runs, and how many rows of alcoves it has.
    static func starkWorkshopGalleryBox(_ c: PixelCanvas, _ g: Int) -> (x0: Int, x1: Int, rows: Int) {
        (c.w * 30 / 100, c.w * 71 / 100, isTall(c) ? 2 : 1)
    }

    /// The Hall of Armour: lit alcoves, each holding a suit on a plinth, behind a long glass wall with reflections.
    static func starkWorkshopGallery(_ c: PixelCanvas, _ g: Int) {
        let s = isTall(c) ? max(unit(g), g / 120) : unit(g), b = starkWorkshopGalleryBox(c, g)   // bigger suits full screen
        let aw = 16 * s, rowH = 27 * s, n = max(1, (b.x1 - b.x0) / aw)
        let x0 = b.x0 + (b.x1 - b.x0 - n * aw) / 2
        let top = g - 3 * s - rowH * b.rows
        c.rect(x0 - 2 * s, top - 3 * s, n * aw + 4 * s, g - top + 3 * s, C(0x0C0E12))
        let suits: [(Px, Px)] = [(C(0xB82028), C(0xE8B030)), (C(0xA8B0BC), C(0xD8DEE6)), (C(0xB82028), C(0xE8B030)),
                                 (C(0x4A4E56), C(0x7A808A)), (C(0xC8A030), C(0xB82028)), (C(0xB82028), C(0xE8B030)),
                                 (C(0x3A4A8A), C(0xD8DEE6))]
        for row in 0..<b.rows {
            let ry = top + row * rowH
            for i in 0..<n {
                let ax = x0 + i * aw
                c.rect(ax + s, ry, aw - 2 * s, rowH - 3 * s, C(0x161A22))
                for k in 0..<(rowH / 2) {                                          // light falling from the top
                    c.rect(ax + 3 * s - k / 6, ry + k, aw - 6 * s + k / 3, 1, C(0xC8E4F8, 0.12 * (1 - Double(k) / Double(rowH / 2))))
                }
                c.rect(ax + 4 * s, ry, aw - 8 * s, s, C(0xE8F6FF))
                c.rect(ax + 2 * s, ry + rowH - 5 * s, aw - 4 * s, 2 * s, C(0x5A626E))
                c.rect(ax + 2 * s, ry + rowH - 5 * s, aw - 4 * s, max(1, s / 2), C(0x6AD8FF))
                let (r, gold) = suits[(i + row * 3) % suits.count]
                starkWorkshopSuit(c, x: ax + aw / 2 - 4 * s - s / 2, y: ry + rowH - 5 * s - 18 * s, k: s, red: r, gold: gold)
                c.rect(ax, ry, s, rowH - 3 * s, C(0x3A4250))
            }
            c.rect(x0 - 2 * s, ry + rowH - 3 * s, n * aw + 4 * s, 3 * s, C(0x2A3038))
        }
        // The glass: a faint sheen and diagonal reflections.
        c.rect(x0 - 2 * s, top - 3 * s, n * aw + 4 * s, g - top + 3 * s, C(0x8AC8E8, 0.05))
        for i in 0..<(n * aw / (26 * s) + 1) {
            let rx = x0 + i * 26 * s + Int(noise(i + 7810) * 10) * s
            for j in 0..<(g - top) where rx + j / 3 < x0 + n * aw {
                c.rect(rx + j / 3, g - j, 2 * s, 1, white.alpha(0.07))
            }
        }
        c.rect(x0 - 2 * s, top - 3 * s, n * aw + 4 * s, s, C(0x5A6672))
    }

    /// One armour, as string art: `r` main plate, `g` faceplate and trim, `w` eyes, `c` arc reactor.
    static let starkWorkshopSuitArt = ["...rrr...",
        "..rgggr..",
        "..gwgwg..",
        "..rgggr..",
        "...rgr...",
        ".rrrrrrr.",
        "rrrrcrrrr",
        "rr.rrr.rr",
        "rg.ggg.gr",
        "rg.rrr.gr",
        "g..rrr..g",
        "...rgr...",
        "..rr.rr..",
        "..rg.gr..",
        "..rr.rr..",
        "..rr.rr..",
        "..gr.rg..",
        ".rrr.rrr.", ]

    /// An armour on its stand, `k` pixels a unit: `red` the main plate, `gold` the faceplate and trim.
    static func starkWorkshopSuit(_ c: PixelCanvas, x: Int, y: Int, k: Int, red: Px, gold: Px) {
        s7Sprite(c, x, y, starkWorkshopSuitArt, ["r": red, "g": gold, "w": C(0xE8FAFF), "c": C(0xA8F0FF)], k: k)
    }

    /// Tony's hot rod (the '32 roadster): a deep red tub, chrome engine and grille, big rear wheel, small front one.
    static func starkWorkshopHotRod(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let rod = ["..............h..............",
                   ".............hh..............",
                   "....rrrrrrrrrhh..............",
                   "..rrrrrrrrrrrrr.cccccc.......",
                   ".rrrrrrrrrrrrrrrcCcCcCgg.....",
                   ".rrrrrrrrrrrrrrrrrrrrrrgg....",
                   ".dddddddddddddddddddddddgk...",
                   "...........aaaaaaaaaaaaaaa...", ]
        s7Sprite(c, x, base - 13 * k, rod, ["r": C(0x9A1A1E), "d": C(0x6A1014), "h": C(0xB8C4D0), "c": C(0xC8D0DA),
                                           "C": C(0x7A828E), "g": C(0xDCE4EC), "k": C(0x2A2A2E), "a": C(0x3A3A40)], k: k)
        c.circle(x + 6 * k, base - 4 * k, 4 * k, C(0x18181C)); c.circle(x + 6 * k, base - 4 * k, k + k / 2, C(0xC8D0DA))
        c.circle(x + 24 * k, base - 3 * k, 3 * k, C(0x18181C)); c.circle(x + 24 * k, base - 3 * k, k, C(0xC8D0DA))
        c.rect(x + 3 * k, base - 10 * k, 8 * k, max(1, k / 2), C(0xE04030))                 // a flash of flame paint
    }

    /// A silver roadster with blue racing stripes, low and curvy.
    static func starkWorkshopRoadster(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let car = ["...........ww...............",
                   ".......sssswws..............",
                   "...sssssbbsssssssssss.......",
                   ".ssssssbbssssssssssssssss...",
                   "sssssssbbssssssssssssssssss.",
                   "SSSSSSSSSSSSSSSSSSSSSSSSSSSl",
                   ".SSSS......SSSSSS......SSS..", ]
        s7Sprite(c, x, base - 8 * k, car, ["s": C(0xC4CCD6), "S": C(0x8A94A2), "b": C(0x2A5AC8), "w": C(0x5A6A7E),
                                          "l": C(0xFFF4D0)], k: k)
        for wx in [6, 20] {
            c.circle(x + wx * k, base - 2 * k, 2 * k + k / 2, C(0x18181C)); c.circle(x + wx * k, base - 2 * k, k, C(0xA8B0BC))
        }
    }

    /// The workbench corner: a pegboard of tools, a bench with a vise, a gauntlet in pieces and a pair of monitors.
    static func starkWorkshopBench(_ c: PixelCanvas, _ g: Int) {
        let s = starkWorkshopK(c, g)
        let x0 = c.w * 73 / 100, x1 = c.w * 91 / 100, top = g - 10 * s
        let pb = (x: x0 + 2 * s, y: g - 33 * s, w: (x1 - x0) / 2, h: 18 * s)
        c.rect(pb.x, pb.y, pb.w, pb.h, C(0x3A3630))
        for y in stride(from: pb.y + s, to: pb.y + pb.h, by: 2 * s) {
            for x in stride(from: pb.x + s, to: pb.x + pb.w, by: 2 * s) { c.px(x, y, C(0x24221E)) }
        }
        let tool = C(0xB4BCC6), handle = C(0xC83A2A)
        var tx = pb.x + 2 * s, i = 0
        while tx < pb.x + pb.w - 3 * s {                                          // wrenches, hammers, screwdrivers
            switch i % 4 {
            case 0: c.rect(tx, pb.y + 3 * s, s, 9 * s, tool); c.rect(tx - s, pb.y + 2 * s, 3 * s, 2 * s, tool); c.px(tx, pb.y + 2 * s, C(0x3A3630))
            case 1: c.rect(tx, pb.y + 5 * s, s, 8 * s, C(0x8A5A3A)); c.rect(tx - s, pb.y + 3 * s, 4 * s, 2 * s, C(0x5A5E66))
            case 2: c.rect(tx, pb.y + 3 * s, s, 5 * s, handle); c.rect(tx, pb.y + 8 * s, max(1, s / 2), 6 * s, tool)
            default: c.rect(tx, pb.y + 3 * s, s, 7 * s, tool); c.rect(tx, pb.y + 3 * s, 2 * s, s, tool)
            }
            tx += 4 * s; i += 1
        }
        // The monitors on an arm.
        let mx = pb.x + pb.w + 3 * s
        for k in 0..<2 {
            let sx = mx + k * 13 * s
            c.rect(sx, g - 30 * s, 12 * s, 8 * s, C(0x0E1218)); c.rect(sx + s, g - 29 * s, 10 * s, 6 * s, C(0x1A4A6A))
            for y in stride(from: g - 28 * s, to: g - 23 * s, by: 2 * s) { c.rect(sx + 2 * s, y, 4 * s + k * 3 * s, max(1, s / 2), C(0x7AD8FF, 0.7)) }
        }
        c.rect(mx + 11 * s, g - 22 * s, s, 12 * s, C(0x3A3E46))
        // The bench.
        c.rect(x0, top, x1 - x0, 2 * s, C(0x5A606A)); c.rect(x0, top, x1 - x0, max(1, s / 2), C(0x8A929E))
        c.rect(x0 + s, top + 2 * s, 2 * s, g - top - 2 * s, C(0x2E3238)); c.rect(x1 - 3 * s, top + 2 * s, 2 * s, g - top - 2 * s, C(0x2E3238))
        c.rect(x0 + s, g - 3 * s, x1 - x0 - 2 * s, s, C(0x2E3238))
        c.rect(x0 + 4 * s, top - 3 * s, 5 * s, 3 * s, C(0x3A5A8A)); c.rect(x0 + 3 * s, top - 4 * s, 7 * s, s, C(0x2A3A5A))   // vise
        c.rect(x0 + 14 * s, top - 2 * s, 5 * s, 2 * s, C(0xB82028)); c.rect(x0 + 15 * s, top - 3 * s, 3 * s, s, C(0xE8B030))  // gauntlet
        c.rect(x0 + 21 * s, top - s, 3 * s, s, C(0xE8B030)); c.rect(x0 + 25 * s, top - 2 * s, 2 * s, 2 * s, C(0xA8F0FF))      // parts, a reactor
        let hx = (x0 + x1) / 2 + 12 * s                                             // the hologram projector
        c.rect(hx - 3 * s, top - s, 6 * s, s, C(0x3A4250)); c.rect(hx - s, top - s, 2 * s, max(1, s / 2), C(0x8AE4FF))
    }

    /// Where the floating hologram panels hang.
    static func starkWorkshopHoloPanels(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = starkWorkshopK(c, g), tall = isTall(c)
        var out = [(c.w * 73 / 100 + 2 * s, g - 50 * s, 16 * s, 11 * s), (c.w * 86 / 100, g - 46 * s, 14 * s, 9 * s)]
        if tall { out.append((c.w * 70 / 100, g * 20 / 100, c.w * 26 / 100, g * 26 / 100)) }
        return out
    }

    /// The turning suit hologram: its centre column, the row its feet float at, and its scale.
    static func starkWorkshopHoloSuit(_ c: PixelCanvas, _ g: Int) -> (x: Int, bottom: Int, k: Int) {
        let s = starkWorkshopK(c, g)
        return isTall(c) ? (c.w * 13 / 100, g - 40 * s, max(2, g / 40)) : (c.w * 255 / 1000, g - 8 * s, 2 * s)
    }

    /// The rotating wireframe hologram over the bench: its centre and radius.
    static func starkWorkshopGlobe(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let s = starkWorkshopK(c, g)
        return (c.w * 82 / 100 + 9 * s, g - 22 * s, 7 * s)
    }

    /// Dum-E: a heavy base, a jointed arm reaching up and over, a two-fingered claw, and the dunce cap.
    static func starkWorkshopDumE(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let grey = C(0x5A606A), dark = C(0x2E3238), lite = C(0x8A929E), hz = C(0xE8C030)
        c.rect(x - 5 * k, base - 4 * k, 10 * k, 4 * k, dark)
        for i in 0..<5 { c.rect(x - 5 * k + i * 2 * k, base - 4 * k, k, k, hz) }
        c.rect(x - 2 * k, base - 9 * k, 4 * k, 5 * k, grey); c.rect(x - 2 * k, base - 9 * k, k, 5 * k, lite)
        c.circle(x, base - 10 * k, 2 * k, dark)
        for i in 0..<12 { c.rect(x - i * k * 2 / 3, base - 10 * k - i * k, 3 * k, 2 * k, grey) }        // upper arm, up and left
        let ex = x - 8 * k, ey = base - 22 * k
        c.circle(ex, ey, 2 * k, dark)
        for i in 0..<8 { c.rect(ex - i * k, ey + i * k / 2, 2 * k, 2 * k, grey) }                   // forearm, down and left
        let hx = ex - 8 * k, hy = ey + 4 * k
        c.rect(hx - k, hy - k, 2 * k, 3 * k, dark)
        c.rect(hx - 3 * k, hy - 2 * k, 2 * k, k, lite); c.rect(hx - 3 * k, hy + 2 * k, 2 * k, k, lite)   // the claw
        for i in 0..<5 { c.rect(ex - 2 * k + i * k / 2, ey - 2 * k - i * k, max(1, 4 * k - i * k), k, white) }   // dunce cap
    }

    /// Full screen: Tony's upper workshop, a run of exposed ductwork and cable trays, and a big holo wall.
    static func starkWorkshopUpper(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), y = g / 12
        c.rect(0, y + 4 * s, c.w, 8 * s, C(0x2A3038)); c.rect(0, y + 4 * s, c.w, s, C(0x4A5462))
        for x in stride(from: 0, to: c.w, by: 18 * s) { c.rect(x, y + 4 * s, s, 8 * s, C(0x1A1E24)) }
        c.rect(0, y + 16 * s, c.w, 2 * s, C(0x1E242C))
        for x in stride(from: 10 * s, to: c.w, by: 60 * s) { c.rect(x, y + 12 * s, s, 4 * s, C(0x1E242C)) }
    }

    /// Holograms: the wireframe globe turning, scan lines sweeping the panels, readouts flickering, the screens glowing.
    static func starkWorkshopLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g), tall = isTall(c)
        // The suit schematic turning on its pad, a beam rising to it.
        let hs = starkWorkshopHoloSuit(c, g)
        let top = hs.bottom - 18 * hs.k
        for y in hs.bottom..<(g - s) { c.rect(hs.x - 3 * s, y, 7 * s, 1, C(0x6AD8FF, 0.08)) }
        let turn = cos(t * 0.8)
        for (r, row) in starkWorkshopSuitArt.enumerated() {
            for (i, ch) in row.enumerated() where ch != "." {
                let u = (Double(i) - 4) * Double(hs.k) * turn
                let x = hs.x + Int(u.rounded(.down)), w = max(1, Int((Double(hs.k) * abs(turn)).rounded(.up)))
                let edge = r == 0 || i == 0 || i == 8 || row[row.index(row.startIndex, offsetBy: max(0, i - 1))] == "."
                c.rect(x, top + r * hs.k, w, hs.k, C(0x6AD8FF, edge ? 0.55 : (ch == "c" || ch == "w" ? 0.8 : 0.2)))
            }
        }
        let sy = (t * 0.6).truncatingRemainder(dividingBy: 1)
        c.rect(hs.x - 6 * hs.k, top + Int(sy * Double(18 * hs.k)), 12 * hs.k, max(1, s), C(0xC8F4FF, 0.35))
        var globes = [starkWorkshopGlobe(c, g)]
        if tall { let p = starkWorkshopHoloPanels(c, g)[2]; globes.append((p.x + p.w / 2, p.y + p.h / 2, p.h * 2 / 5)) }
        for (gi, gl) in globes.enumerated() {
            let R = Double(gl.r), cx = Double(gl.x), cy = Double(gl.y), spin = t * 0.9 + Double(gi)
            c.circle(gl.x, gl.y, gl.r + s, C(0x3AB8F0, 0.08))
            for lat in [-0.66, -0.33, 0, 0.33, 0.66] {
                s7Ring(c, cx, cy + R * lat, R * (1 - lat * lat).squareRoot(), max(1, R * 0.18), C(0x6AD8FF, 0.55), n: 30 + gl.r * 3)
            }
            for k in 0..<4 {
                let phi = spin + Double(k) * .pi / 4
                s7Ring(c, cx, cy, abs(R * cos(phi)), R, C(0x8AE8FF, 0.35 + 0.3 * abs(sin(phi))), n: 30 + gl.r * 3)
            }
            c.glowLine(cx, cy + R + 2, cx, cy + R + 2 + Double(5 * s), core: C(0x8AE4FF, 0.5), glow: C(0x3AB8F0, 0.2), coreR: 0.4, glowR: 1.6)
        }
        for (i, p) in starkWorkshopHoloPanels(c, g).enumerated() {
            let q = (t * 0.5 + Double(i) * 0.3).truncatingRemainder(dividingBy: 1)
            c.rect(p.x, p.y + Int(q * Double(p.h - 1)), p.w, max(1, s), C(0xA8F0FF, 0.5))
            let blink = Int(t * 3 + Double(i)) % 4
            c.rect(p.x + p.w - 4 * s, p.y + 2 * s + blink * s, 2 * s, max(1, s / 2) + 0, C(0xFFFFFF, 0.8))
        }
        let pulse = 0.5 + 0.5 * sin(t * 2), u = starkWorkshopK(c, g)
        let mx = c.w * 73 / 100 + 2 * u + (c.w * 91 / 100 - c.w * 73 / 100) / 2 + 3 * u
        for k in 0..<2 { c.rect(mx + k * 13 * u + u, g - 29 * u, 10 * u, 6 * u, C(0x6AD8FF, 0.08 + 0.1 * pulse)) }
    }

    // MARK: - The Red Room

    /// The Red Room: the Soviet academy where Black Widows are made. Bare board-marked concrete under a pipe-run
    /// ceiling, barred high windows onto a snowstorm, a hammer-and-sickle banner hung down the middle, a ballet barre in
    /// front of a long mirror, heavy training bags on chains, and caged red lamps over it all. The lamps swing on their
    /// cords and the snow falls past the windows in `redRoomLife`.
    static func redRoom(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x1E1616), C(0x4C3C3A), bands: 6)
        let ceil = redRoomCeiling(c, g)
        for y in stride(from: ceil + 3 * s, to: g, by: 6 * s) { c.rect(0, y, c.w, max(1, s / 2), C(0x000000, 0.14)) }   // form-board marks
        for (i, x) in stride(from: 13 * s, to: c.w, by: 26 * s).enumerated() {
            c.rect(x, ceil, max(1, s / 2), g - ceil, C(0x000000, i % 2 == 0 ? 0.2 : 0.08))
            for y in stride(from: ceil + 6 * s, to: g - 4 * s, by: 18 * s) { c.rect(x + 6 * s, y, s, s, C(0x140C0C, 0.6)) }   // tie holes
        }
        for i in 0..<(c.w / 30) {                                                 // damp streaks
            let x = Int(noise(i * 3 + 7900) * Double(c.w)), len = Int(noise(i * 3 + 7901) * Double(g - ceil) * 0.5)
            c.rect(x, ceil, s, len, C(0x0A0606, 0.18))
        }
        // Red glow from the lamps, pooled on the wall.
        for l in redRoomLamps(c, g) {
            c.ellipse(l.x, l.y + l.len + 8 * s, 34 * s, 26 * s, C(0xE02020, 0.07))
            c.ellipse(l.x, l.y + l.len + 6 * s, 18 * s, 14 * s, C(0xFF3030, 0.08))
        }
        c.rect(0, 0, c.w, ceil, C(0x140E0E))
        c.rect(0, ceil, c.w, s, C(0x2A2020))
        c.rect(0, ceil + 2 * s, c.w, 2 * s, C(0x3A3030)); c.rect(0, ceil + 2 * s, c.w, max(1, s / 2), C(0x5A4A48))   // the pipe run
        for x in stride(from: 20 * s, to: c.w, by: 50 * s) { c.rect(x, ceil, s, 4 * s, C(0x1E1616)) }
        for w in redRoomWindows(c, g) { redRoomWindow(c, w, s: s) }
        if tall { redRoomBooth(c, g) }
        redRoomMirror(c, g)
        redRoomBanner(c, g)
        redRoomBags(c, g)
        // Floor: worn boards under the barre, cold concrete elsewhere.
        c.ground(g, C(0x3A3030), edge: C(0x6A5452), speck: C(0x2C2424), seed: 79)
        let m = redRoomMirrorBox(c, g)
        c.rect(m.x0 - 6 * s, g + 1, m.x1 - m.x0 + 12 * s, c.h - g - 1, C(0x5A3E2E))
        for y in stride(from: g + 1, to: c.h, by: 3 * s) { c.rect(m.x0 - 6 * s, y, m.x1 - m.x0 + 12 * s, max(1, s / 2), C(0x3E2A1E)) }
        for (row, y) in stride(from: g + 1, to: c.h, by: 3 * s).enumerated() {
            for x in stride(from: m.x0 - 6 * s + (row % 3) * 9 * s, to: m.x1 + 6 * s, by: 26 * s) { c.rect(x, y, max(1, s / 2), 3 * s, C(0x3E2A1E)) }
        }
        c.rect(0, g, c.w, s, C(0x6A5452))
        for l in redRoomLamps(c, g) { c.ellipse(l.x, g + 3 * s, 16 * s, 2 * s, C(0xFF3030, 0.1)) }
        let dx = c.w * 62 / 100                                                    // a drain
        c.rect(dx, g + 4 * s, 6 * s, 2 * s, C(0x1E1818))
        for k in 0..<3 { c.rect(dx + s + k * 2 * s, g + 4 * s, max(1, s / 2), 2 * s, C(0x4A3E3C)) }
    }

    /// The ceiling's depth.
    static func redRoomCeiling(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? g / 14 : 3 * unit(g) }

    /// The high barred windows.
    static func redRoomWindows(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = unit(g), tall = isTall(c), y = redRoomCeiling(c, g) + (tall ? g / 10 : 6 * s)
        let w = 22 * s, h = tall ? 26 * s : 10 * s
        return [0.07, 0.27, 0.67, 0.86].map { (Int($0 * Double(c.w)), y, w, h) }
    }

    /// The hanging lamps: where each cord hangs from and how long it is.
    static func redRoomLamps(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, len: Int)] {
        let s = unit(g), y = redRoomCeiling(c, g), len = isTall(c) ? g * 30 / 100 : 12 * s
        return [(0.19, 0), (0.39, 3), (0.6, 1), (0.79, 4)].map { (Int($0.0 * Double(c.w)), y, len + $0.1 * s) }
    }

    /// A high window: deep concrete reveal, night-blue storm outside, iron bars, snow banked on the sill.
    static func redRoomWindow(_ c: PixelCanvas, _ w: (x: Int, y: Int, w: Int, h: Int), s: Int) {
        c.rect(w.x - 2 * s, w.y - 2 * s, w.w + 4 * s, w.h + 4 * s, C(0x241A1A))
        for y in w.y..<(w.y + w.h) {
            let u = Double(y - w.y) / Double(max(1, w.h))
            c.rect(w.x, y, w.w, 1, lerp(C(0x141C30), C(0x3A4A66), (u * 4).rounded(.down) / 4))
        }
        for i in 0..<(w.w * w.h / 10) {
            c.px(w.x + Int(noise(i * 2 + 7910 + w.x) * Double(w.w)), w.y + Int(noise(i * 2 + 7911 + w.x) * Double(w.h)), white.alpha(0.5))
        }
        c.rect(w.x, w.y + w.h - 2 * s, w.w, 2 * s, C(0xD8E0EC))
        for x in stride(from: w.x + 3 * s, to: w.x + w.w, by: 4 * s) { c.rect(x, w.y, s, w.h, C(0x1A1414)) }
        c.rect(w.x, w.y + w.h / 2, w.w, s, C(0x1A1414))
        c.rect(w.x - 3 * s, w.y + w.h + 2 * s, w.w + 6 * s, s, C(0x5A4846))
        c.rect(w.x - 2 * s, w.y + w.h + s, w.w + 4 * s, s, C(0xE8EEF4, 0.8))
    }

    /// Where the mirror wall stands.
    static func redRoomMirrorBox(_ c: PixelCanvas, _ g: Int) -> (x0: Int, x1: Int, top: Int) {
        let s = unit(g)
        return (c.w * 4 / 100, c.w * 36 / 100, isTall(c) ? g * 64 / 100 : g - 30 * s)
    }

    /// The long mirror in its frame, with the red room dimly in it, and the wooden barre on brackets in front.
    static func redRoomMirror(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), m = redRoomMirrorBox(c, g), bottom = g - 3 * s
        c.rect(m.x0 - 2 * s, m.top - 2 * s, m.x1 - m.x0 + 4 * s, bottom - m.top + 2 * s, C(0x2A2020))
        for y in m.top..<bottom {
            let u = Double(y - m.top) / Double(max(1, bottom - m.top))
            c.rect(m.x0, y, m.x1 - m.x0, 1, lerp(C(0x5A5458), C(0x6E5A5C), u))
        }
        for x in stride(from: m.x0 + 30 * s, to: m.x1, by: 30 * s) { c.rect(x, m.top, s, bottom - m.top, C(0x2A2020)) }  // panel joins
        for i in 0..<4 {                                                           // sheen streaks
            let rx = m.x0 + 6 * s + i * (m.x1 - m.x0) / 4
            for j in 0..<(bottom - m.top) where rx + j / 2 < m.x1 { c.rect(rx + j / 2, bottom - 1 - j, 2 * s, 1, white.alpha(0.08)) }
        }
        for l in redRoomLamps(c, g) where l.x > m.x0 && l.x < m.x1 {               // a lamp's reflection
            c.circle(l.x + 4 * s, m.top + 4 * s, 3 * s, C(0xFF4040, 0.25))
        }
        let by = g - 14 * s
        for x in stride(from: m.x0 + 6 * s, to: m.x1 - 2 * s, by: 24 * s) {
            c.rect(x, by - s, s, 4 * s, C(0x2A2424)); c.rect(x, by + 2 * s, 3 * s, s, C(0x2A2424))
        }
        c.rect(m.x0 - s, by, m.x1 - m.x0 + 2 * s, 2 * s, C(0x9A6E44))
        c.rect(m.x0 - s, by, m.x1 - m.x0 + 2 * s, max(1, s / 2), C(0xC89A64))
        c.rect(m.x0 - s, by + 2 * s, m.x1 - m.x0 + 2 * s, s, C(0x000000, 0.3))
    }

    /// The banner down the middle: red cloth with folds, the gold star and hammer and sickle, a fringed hem.
    static func redRoomBanner(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let k = tall ? max(2, g / 90) : s
        let w = 20 * k, x = c.w / 2 - w / 2, top = redRoomCeiling(c, g) + 4 * s, bottom = tall ? g * 70 / 100 : g - 22 * s
        c.rect(x - 2 * k, top - k, w + 4 * k, k, C(0x2A2020))
        c.rect(x, top, w, bottom - top, C(0xA81C1C))
        for f in stride(from: x + 3 * k, to: x + w, by: 5 * k) { c.rect(f, top, k, bottom - top, C(0x7A1010, 0.6)) }
        c.rect(x, top, k, bottom - top, C(0xC83A30))
        for i in 0..<(w / k) {                                                   // the hem, cut in a swallowtail
            let d = abs(i - w / k / 2) * k / 2
            c.rect(x + i * k, bottom, k, w / 4 - d, C(0xA81C1C))
            c.rect(x + i * k, bottom + w / 4 - d, k, k, C(0xE0B040))
        }
        let gold = C(0xF0C040)
        let sx = x + w / 2 - 5 * k / 2
        s7Sprite(c, sx - k, top + 2 * k, ["...y...", "..yyy..", "yyyyyyy", ".yyyyy.", "..yyy..", ".yy.yy.", "y.....y"], ["y": gold], k: k)
        s7Sprite(c, x + w / 2 - 6 * k, top + 10 * k, [
            "....yyy.....",
            "......yy....",
            ".yy.....y...",
            "yyyy....yy..",
            ".yyyy....y..",
            "...yyy..yy..",
            "....yyyyy...",
            "...y.yyy....",
            "..y.yy.yyy..",
            ".yyy....yyy.",
            "yy.......yy.", ], ["y": gold], k: k)
    }

    /// The heavy bags hanging on chains from the beam.
    static func redRoomBags(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), ceil = redRoomCeiling(c, g)
        for (i, fx) in [0.72, 0.8, 0.88].enumerated() {
            let x = Int(fx * Double(c.w)), bottom = g - (6 + i % 2 * 3) * s, h = tall ? g * 22 / 100 : 20 * s
            let top = bottom - h, b = tall ? max(2 * s, g / 120) : s                // b: the bag's width unit
            for y in stride(from: ceil + 4 * s, to: top - s, by: 2 * s) { c.rect(x, y, s, s, C(0x5A5250)); c.px(x + s, y + s, C(0x3A3434)) }
            c.rect(x - 3 * b, top - s, 7 * b, s, C(0x2A2424))
            c.rect(x - 4 * b, top, 9 * b, h, C(0x3A2622))
            c.rect(x - 3 * b, bottom, 7 * b, s, C(0x3A2622))
            c.rect(x - 4 * b, top, 2 * b, h, C(0x5A3A30))
            c.rect(x + 3 * b, top, 2 * b, h, C(0x24160E))
            for band in [0.18, 0.5, 0.82] { c.rect(x - 4 * b, top + Int(Double(h) * band), 9 * b, s, C(0x8A8070)) }
            c.rect(x - 4 * b, top, 9 * b, h, C(0xFF2020, 0.06))
        }
    }

    /// Full screen: the observation gallery over the mirror, where the instructors watch: dark glass and a railing.
    static func redRoomBooth(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), y = g * 38 / 100
        let x0 = c.w * 6 / 100, x1 = c.w * 34 / 100
        c.rect(x0 - 3 * s, y, x1 - x0 + 6 * s, 20 * s, C(0x2A2020))
        c.rect(x0, y + 3 * s, x1 - x0, 12 * s, C(0x101418))
        c.rect(x0, y + 3 * s, x1 - x0, 2 * s, C(0x4A2020, 0.6))
        for x in stride(from: x0, to: x1, by: 14 * s) { c.rect(x, y + 3 * s, s, 12 * s, C(0x2A2020)) }
        c.rect(x0 - 6 * s, y + 20 * s, x1 - x0 + 12 * s, 2 * s, C(0x3A3030))
        for x in stride(from: x0 - 6 * s, through: x1 + 6 * s, by: 5 * s) { c.rect(x, y + 22 * s, s, 6 * s, C(0x2A2020)) }
        c.rect(x0 - 6 * s, y + 27 * s, x1 - x0 + 12 * s, s, C(0x2A2020))
    }

    /// Lamps swinging on their cords, their red light following, and snow falling past the windows.
    static func redRoomLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g)
        for w in redRoomWindows(c, g) {
            let n = max(6, w.w * w.h / (14 * s * s))
            for i in 0..<n {
                let speed = (3 + noise(i * 3 + 7950) * 4) * Double(s)
                let y = (t * speed + noise(i * 3 + 7951) * Double(w.h)).truncatingRemainder(dividingBy: Double(w.h - 2 * s))
                let x = (noise(i * 3 + 7952 + w.x) * Double(w.w) + t * 2 * Double(s)).truncatingRemainder(dividingBy: Double(w.w))
                c.rect(w.x + Int(x), w.y + Int(y), s, s, white.alpha(0.85))
            }
        }
        for (i, l) in redRoomLamps(c, g).enumerated() {
            let a = sin(t * 1.1 + Double(i) * 1.3) * 0.12
            let ex = Double(l.x) + sin(a) * Double(l.len), ey = Double(l.y) + cos(a) * Double(l.len)
            let n = max(2, l.len)
            for k in 0..<n {
                let u = Double(k) / Double(n)
                c.px(Int(Double(l.x) + (ex - Double(l.x)) * u), Int(Double(l.y) + (ey - Double(l.y)) * u), C(0x140C0C))
            }
            let x = Int(ex), y = Int(ey)
            c.ellipse(x, y + 10 * s, 20 * s, 14 * s, C(0xFF2020, 0.06))
            c.rect(x - 3 * s, y, 7 * s, 2 * s, C(0x2A2020))
            c.rect(x - 2 * s, y + 2 * s, 5 * s, 4 * s, C(0xFF3A2A))
            c.rect(x - s, y + 2 * s, 2 * s, 2 * s, C(0xFFB0A0))
            for k in 0..<3 { c.rect(x - 2 * s + k * 2 * s, y + 2 * s, max(1, s / 2), 4 * s, C(0x2A2020)) }
            c.rect(x - 2 * s, y + 4 * s, 5 * s, max(1, s / 2), C(0x2A2020))
            c.glowLine(Double(x) + 0.5, Double(y + 6 * s), Double(x) + 0.5, Double(y + 6 * s + 1), core: C(0xFF5040, 0.3),
                       glow: C(0xFF2020, 0.25), coreR: 1, glowR: Double(5 * s))
        }
    }

    // MARK: - Ta Lo

    /// Ta Lo, the hidden village (Shang-Chi): a twilight valley of misty karst peaks round a still lake, the Great
    /// Protector's long shape coiled in the mist over the water. A gate with dragon-scale panels opens onto the lake
    /// between two stone guardian lions; village halls with sweeping roofs and red lanterns sit either side under
    /// giant trees hung with lanterns; a nine-tailed fox stands on the far shore and Morris, the faceless dijiang,
    /// hovers by the path. Lanterns glow, seeds of light drift, the mist moves and Morris flaps in `taLoLife`.
    static func taLo(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), s = unit(g)
        c.gradient(0, g, C(0x3C6A7E), C(0xF2D6AE), bands: 7)
        if tall {
            c.circle(c.w * 70 / 100, g / 8, max(6, g / 22), C(0xFFF4DC, 0.9))
            for i in 0..<6 {
                let x = Int(noise(i * 5 + 8000) * Double(c.w)), y = Int(Double(g) * (0.06 + noise(i * 5 + 8001) * 0.3))
                wisp(c, x, y, (50 + Int(noise(i * 5 + 8002) * 80)) * s, C(0xFFF0E0, 0.35), s: s)
            }
        }
        let lake = taLoLake(c, g)
        // Karst peaks in three misty layers.
        let layers: [(Double, Double, Px, Px, Int)] = [(0.75, 0.25, C(0x8AA8A8), C(0x9EBAB4), 8010),
                                                       (0.55, 0.2, C(0x6A8E86), C(0x82A69A), 8030),
                                                       (0.35, 0.16, C(0x4A6E62), C(0x5E8474), 8050)]
        for (li, (hf, hv, col, lite, seed)) in layers.enumerated() {
            let span = Double(lake.top) * (tall ? 0.8 : 1.0)
            var x = -Int(noise(seed) * 30), i = 0
            while x < c.w + 30 {
                let h = span * (hf * 0.6 + noise(seed + i * 3 + 1) * hv * 2.2), w = (10 + noise(seed + i * 3 + 2) * 14) * Double(s)
                let bx = Double(x), bb = Double(lake.top)
                s7Poly(c, [(bx - w, bb), (bx - w * 0.62, bb - h * 0.55), (bx - w * 0.42, bb - h * 0.92), (bx - w * 0.1, bb - h),
                           (bx + w * 0.3, bb - h * 0.95), (bx + w * 0.55, bb - h * 0.6), (bx + w, bb)], col)
                s7Poly(c, [(bx - w, bb), (bx - w * 0.62, bb - h * 0.55), (bx - w * 0.42, bb - h * 0.92), (bx - w * 0.2, bb - h * 0.98),
                           (bx - w * 0.3, bb)], lite)
                if li == 2, noise(seed + i * 3 + 5) > 0.4 {                         // a little tree on top
                    c.circle(Int(bx - w * 0.1), Int(bb - h) - s, 2 * s, C(0x3A5E4E))
                }
                x += Int(w * (1.0 + noise(seed + i * 3 + 4) * 0.9)); i += 1
            }
            c.gradient(lake.top - Int(Double(lake.top) * 0.18), lake.top, C(0xF2E0C0, 0), C(0xF2E0C0, 0.55), bands: 4)
        }
        // The lake.
        c.gradient(lake.top, lake.bottom, C(0xC8D6C8), C(0x7EA6A2), bands: 4)
        for i in 0..<(c.w / 6) {
            let x = Int(noise(i * 2 + 8070) * Double(c.w)), y = lake.top + 1 + Int(noise(i * 2 + 8071) * Double(lake.bottom - lake.top - 1))
            c.rect(x, y, 3 * s + Int(noise(i + 8072) * 4) * s, 1, white.alpha(0.35))
        }
        taLoProtector(c, g)
        // Mist lying on the water.
        c.gradient(lake.top - 4 * s, lake.top + 3 * s, C(0xF4F0E4, 0), C(0xF4F0E4, 0.6), bands: 3)
        taLoFox(c, x: c.w * 42 / 100, base: lake.top + 2 * s, k: s)
        // The near shore: a grassy bank with reeds and low shrubs at the water's edge.
        c.rect(0, lake.bottom, c.w, g - lake.bottom, C(0x5E8A50))
        c.rect(0, lake.bottom, c.w, s, C(0x8AB070))
        for i in 0..<(c.w / 10) {
            let x = Int(noise(i * 3 + 8080) * Double(c.w)), r = (1 + Int(noise(i * 3 + 8081) * 3)) * s
            c.circle(x, lake.bottom + r / 2, r, i % 2 == 0 ? C(0x3E6A44) : C(0x4E7A4E))
            c.px(x + r + s, lake.bottom - 2 * s, C(0x6A8A50)); c.px(x + r + s, lake.bottom - s, C(0x6A8A50))
        }
        c.gradient(lake.bottom + s, g, C(0x4E7A44, 0), C(0x4E7A44, 0.6), bands: 3)
        let pathMid = Double(c.w) / 2, nearHalf = Double(c.w) * 0.14, farHalf = Double(c.w) * 0.035
        s7Poly(c, [(pathMid - farHalf, Double(lake.bottom)), (pathMid + farHalf, Double(lake.bottom)),
                   (pathMid + nearHalf, Double(g)), (pathMid - nearHalf, Double(g))], C(0xB4A890))      // the path to the water
        for y in stride(from: lake.bottom + 2 * s, to: g, by: max(2 * s, (g - lake.bottom) / 8)) {
            let u = Double(y - lake.bottom) / Double(max(1, g - lake.bottom)), hw = farHalf + (nearHalf - farHalf) * u
            c.rect(Int(pathMid - hw), y, Int(hw * 2), max(1, s / 2), C(0x9A8E78))
        }
        // The village either side, the giant trees framing it.
        taLoHall(c, x: c.w * 10 / 100, w: 66 * s, base: g, h: 18 * s, g: g)
        taLoHall(c, x: c.w * 72 / 100, w: 60 * s, base: g, h: 16 * s, g: g)
        if tall {
            taLoHall(c, x: c.w * 17 / 100, w: 54 * s, base: lake.bottom + 12 * s, h: 14 * s, g: g)
            taLoHall(c, x: c.w * 76 / 100, w: 50 * s, base: lake.bottom + 14 * s, h: 14 * s, g: g)
        }
        taLoTree(c, x: c.w * 4 / 100, g: g, flip: false)
        taLoTree(c, x: c.w * 96 / 100, g: g, flip: true)
        taLoGate(c, g)
        let lk = tall ? max(2 * s, g / 110) : s
        taLoLion(c, x: c.w * 33 / 100 - 11 * lk, base: g, k: lk, flip: false)
        taLoLion(c, x: c.w * 67 / 100 + lk, base: g, k: lk, flip: true)
        for l in taLoLanterns(c, g) { taLoLantern(c, l.x, l.y, s: s) }
        // Floor: grass with a flagstone path down the middle, petals fallen on it.
        c.ground(g, C(0x4E7A44), edge: C(0x7AA45E), speck: C(0x426A3A), seed: 80)
        let p0 = c.w * 36 / 100, p1 = c.w * 64 / 100
        c.rect(p0, g, p1 - p0, c.h - g, C(0xC0B49C))
        c.rect(p0, g, p1 - p0, s, C(0xDCD2BC))
        for (row, y) in stride(from: g + 3 * s, to: c.h, by: 3 * s).enumerated() {
            c.rect(p0, y, p1 - p0, max(1, s / 2), C(0x9E927C))
            for x in stride(from: p0 + (row % 2) * 6 * s, to: p1, by: 12 * s) { c.rect(x, y - 3 * s, max(1, s / 2), 3 * s, C(0x9E927C)) }
        }
        for i in 0..<(c.w / 7) {
            let x = Int(noise(i * 3 + 8090) * Double(c.w)), y = g + 1 + Int(noise(i * 3 + 8091) * Double(max(1, c.h - g - 2)))
            c.px(x, y, i % 3 == 0 ? C(0xF0A8B8) : (i % 3 == 1 ? C(0xF8E0A0) : C(0x9AC870)))
        }
    }

    /// The lake's band of rows.
    static func taLoLake(_ c: PixelCanvas, _ g: Int) -> (top: Int, bottom: Int) {
        let s = unit(g)
        return isTall(c) ? (g * 56 / 100, g * 76 / 100) : (g - 22 * s, g - 12 * s)
    }

    /// The Great Protector in the mist: a long serpentine body rising and dipping over the lake, a fringed mane along
    /// its back, and its horned, whiskered head raised at the left, all pale and half-there.
    static func taLoProtector(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), lake = taLoLake(c, g)
        let x0 = c.w * 32 / 100, x1 = c.w * 80 / 100
        let mid = Double(lake.top) * (tall ? 0.42 : 0.34)
        let amp = Double(lake.top) * (tall ? 0.12 : 0.18), thick = max(2.0, Double(lake.top) * (tall ? 0.04 : 0.06))
        let body = C(0xF0F6F0, 0.5), belly = C(0xC8E0D8, 0.45), mane = C(0xFFFFFF, 0.6)
        func centre(_ x: Int) -> Double {
            let u = Double(x - x0) / Double(x1 - x0)
            return mid + sin(u * .pi * 2.6 + 0.6) * amp * (0.5 + u * 0.6) + u * amp * 0.6
        }
        for x in x0..<x1 {
            let u = Double(x - x0) / Double(x1 - x0)
            let cy = centre(x), th = thick * (1.0 - u * 0.75)
            if cy > mid + amp * 0.75 { c.rect(x, Int(mid + amp * 0.75) - 1, 1, 3, C(0xFFFFFF, 0.25)); continue }   // dipped into the mist
            c.rect(x, Int(cy - th), 1, Int(th), body)
            c.rect(x, Int(cy), 1, max(1, Int(th * 0.7)), belly)
            if x % 3 == 0 {
                let mh = max(1, Int(th * 0.8 * (0.6 + noise(x + 8100) * 0.6)))
                c.rect(x - 1, Int(cy - th) - mh, 1, mh, mane)
            }
            if x % 4 == 2 { c.px(x, Int(cy - th * 0.3), C(0x9ACCC0, 0.4)) }        // scales
        }
        // The head, raised at the front: horns swept back, a mane, whiskers trailing from the snout.
        let k = max(1, Int(thick / 2.2))
        let head = ["........hh.hh.....",
                    ".........hh.hh....",
                    "..........hh.hm...",
                    ".....bbbbbbbbmmm..",
                    "...bbbbebbbbbbmmm.",
                    "bbbbbbbbbbbbbbbmm.",
                    "bbbbbbbbbbbbbbbm..",
                    ".wbbbbbbbbbbbb....",
                    "ww..wwwbbbbb......",
                    "w.....ww..........", ]
        let hx = x0 - 15 * k, hy = Int(centre(x0) - thick) - 7 * k
        for j in 0..<(3 * k) { c.rect(x0 - 3 * k, hy + 6 * k + j, 4 * k, 1, body) }                               // neck
        s7Sprite(c, hx, hy, head, ["b": body, "h": mane, "m": mane, "e": C(0x4A7A7A, 0.8), "w": C(0xFFFFFF, 0.4)], k: k)
    }

    /// A nine-tailed fox on the far shore, pale against the water.
    static func taLoFox(_ c: PixelCanvas, x: Int, base: Int, k: Int) {
        let fox = [".......t.t.t",
                   "w.w...tttttt",
                   "www..tt.t.t.",
                   "wwwwwwwt....",
                   ".wwwwww.....",
                   ".w.w..w.w...", ]
        s7Sprite(c, x, base - 6 * k, fox, ["w": C(0xFFF8F0), "t": C(0xFFE8D0, 0.85)], k: k)
    }

    /// A village hall: plaster walls with a dragon-scale panel between red pillars, a sweeping curved roof with
    /// upturned eaves, a round doorway.
    static func taLoHall(_ c: PixelCanvas, x: Int, w: Int, base: Int, h: Int, g: Int) {
        let s = unit(g), top = base - h
        c.rect(x, top, w, h, C(0xE4D8C0))
        taLoScales(c, x: x + 4 * s, y: top + 3 * s, w: w - 8 * s, h: h - 6 * s, base: C(0x7A9A8A), line: C(0x4E6E62), lite: C(0xA8C4B4))
        for px in stride(from: x, to: x + w, by: max(8 * s, w / 5)) { c.rect(px, top, 2 * s, h, C(0xA82E24)); c.rect(px, top, max(1, s / 2), h, C(0xC84838)) }
        c.rect(x + w - 2 * s, top, 2 * s, h, C(0xA82E24))
        c.circle(x + w / 2, base - h / 3, h / 3, C(0x3A2A20)); c.rect(x + w / 2 - h / 3, base - h / 3, h * 2 / 3 + 1, h / 3, C(0x3A2A20))
        c.rect(x, top, w, s, C(0x6A2A1E))
        taLoRoof(c, cx: x + w / 2, half: w / 2 + 8 * s, y: top - 8 * s, h: 8 * s, s: s)
    }

    /// A sweeping roof: a concave slope from a short ridge out to eaves that curl up at the tips, tiled.
    static func taLoRoof(_ c: PixelCanvas, cx: Int, half: Int, y: Int, h: Int, s: Int) {
        let tile = C(0x34404A), dark = C(0x222A32), lite = C(0x4A5864)
        for dx in -half...half {
            let u = Double(abs(dx)) / Double(max(1, half))
            let top = y + Int(pow(u, 1.8) * Double(h) * 0.85)
            let bot = y + h + 2 * s - Int(pow(u, 6) * Double(4 * s))
            guard bot > top else { continue }
            c.rect(cx + dx, top, 1, bot - top, (abs(dx) / max(1, 2 * s)) % 2 == 0 ? tile : lite)
            c.px(cx + dx, bot - 1, dark)
        }
        c.rect(cx - half / 3, y - s, half * 2 / 3, 2 * s, dark)
        c.rect(cx - half / 3 - 2 * s, y - 2 * s, 2 * s, s, C(0xC8A040)); c.rect(cx + half / 3, y - 2 * s, 2 * s, s, C(0xC8A040))
        c.rect(cx - half, y + h - 3 * s, s, 2 * s, C(0xC8A040)); c.rect(cx + half, y + h - 3 * s, s, 2 * s, C(0xC8A040))
    }

    /// Fills a box with overlapping dragon scales.
    static func taLoScales(_ c: PixelCanvas, x: Int, y: Int, w: Int, h: Int, base: Px, line: Px, lite: Px) {
        guard w > 0, h > 0 else { return }
        c.rect(x, y, w, h, base)
        let s = max(1, h / 12), sw = 6 * s, sh = 3 * s
        for (row, yy) in stride(from: y, to: y + h, by: sh).enumerated() {
            let off = row % 2 == 0 ? 0 : sw / 2
            for xx in stride(from: x - off, to: x + w, by: sw) {
                for dx in 0..<sw {
                    let u = Double(dx) / Double(sw) * 2 - 1
                    let dy = Int((1 - u * u).squareRoot() * Double(sh))
                    let px = xx + dx, py = yy + dy
                    if px >= x, px < x + w, py < y + h { c.px(px, py, line) }
                    if px >= x, px < x + w, py - s >= y, abs(u) < 0.5 { c.px(px, py - s, lite) }
                }
            }
        }
    }

    /// A giant tree framing the village: a broad flared trunk under a towering canopy.
    static func taLoTree(_ c: PixelCanvas, x: Int, g: Int, flip: Bool) {
        let s = unit(g), tall = isTall(c)
        let tw = tall ? 14 * s + g / 40 : 8 * s, top = tall ? g * 18 / 100 : 10 * s
        for y in top..<g {
            let u = Double(y - top) / Double(g - top)
            let flare = Int(pow(u, 6) * Double(tw))
            c.rect(x - tw / 2 - flare, y, tw + flare * 2, 1, C(0x5A4232))
            c.rect(x - tw / 2 - flare, y, max(1, tw / 4), 1, C(0x7A5E46))
            c.rect(x + tw / 2 + flare - tw / 4, y, tw / 4, 1, C(0x3E2C22))
        }
        for k in 0..<3 { c.rect(x - tw / 4 + k * tw / 4, top, max(1, s / 2), g - top, C(0x3E2C22, 0.5)) }
        let cr = tall ? g / 5 : 22 * s
        let dir = flip ? -1 : 1
        let blobs: [(Double, Double, Double)] = [(0, -0.2, 1), (0.9, 0.1, 0.8), (1.6, 0.35, 0.6), (-0.7, 0.2, 0.75), (0.4, -0.6, 0.7)]
        for (i, (bx, by, br)) in blobs.enumerated() {
            let cx = x + dir * Int(bx * Double(cr)), cy = top + Int(by * Double(cr)), r = Int(br * Double(cr))
            c.circle(cx + s, cy + 2 * s, r, C(0x1E3A2C))
            c.circle(cx, cy, r, i % 2 == 0 ? C(0x2E5640) : C(0x2A4E3A))
            c.circle(cx - r / 4, cy - r / 4, r / 2, C(0x3E6A4C))
            c.circle(cx - r / 3, cy - r / 3, r / 5, C(0x5A8A5E))
        }
    }

    /// The village gate: two red posts, a lintel with a dragon-scale panel, and a curved roof on top.
    static func taLoGate(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let x0 = c.w * 33 / 100, x1 = c.w * 67 / 100, top = tall ? g * 58 / 100 : g - 30 * s
        for px in [x0, x1 - 4 * s] {
            c.rect(px, top, 4 * s, g - top, C(0xA82E24)); c.rect(px, top, s, g - top, C(0xD04A3A))
            c.rect(px + 3 * s, top, s, g - top, C(0x6A1A14))
            c.rect(px - s, g - 3 * s, 6 * s, 3 * s, C(0x8A8478))
        }
        let lh = 7 * s
        c.rect(x0 - 4 * s, top, x1 - x0 + 8 * s, 2 * s, C(0x6A1A14))
        taLoScales(c, x: x0 + 4 * s, y: top + 2 * s, w: x1 - x0 - 8 * s, h: lh, base: C(0xC89A3A), line: C(0x8A5A1E), lite: C(0xF0CC70))
        c.rect(x0, top + 2 * s + lh, x1 - x0, 2 * s, C(0x6A1A14))
        taLoRoof(c, cx: (x0 + x1) / 2, half: (x1 - x0) / 2 + 10 * s, y: top - 8 * s, h: 8 * s, s: s)
    }

    /// A stone guardian lion on its plinth, curly-maned, one paw on a ball.
    static func taLoLion(_ c: PixelCanvas, x: Int, base: Int, k: Int, flip: Bool) {
        let lion = ["..mmmm....",
                    ".mmhhmm...",
                    "mmhehhmm..",
                    "mhhhhhhm..",
                    ".mhnnhm...",
                    "..mbbbbm..",
                    ".bbbbbbbb.",
                    "bbbbbbbbbb",
                    "obbpbbbbbp",
                    "oo.pp.bbpp",
                    "ssssssssss",
                    "SSSSSSSSSS",
                    "ssssssssss", ]
        s7Sprite(c, x, base - 13 * k, lion, ["m": C(0x7A8278), "h": C(0xA8B0A4), "e": C(0x3A4038), "n": C(0x5A6258),
                                            "b": C(0x9AA296), "p": C(0x7A8278), "o": C(0xB8BEB0), "s": C(0x8A8478),
                                            "S": C(0x6A665E)], k: k, flip: flip)
        c.rect(x + (flip ? 0 : 0), base - 13 * k, 10 * k, k, C(0x6A9A5A, 0.3))                    // moss
    }

    /// Where the lanterns hang.
    static func taLoLanterns(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g), tall = isTall(c)
        let gateTop = tall ? g * 58 / 100 : g - 30 * s
        var out = [(c.w * 33 / 100 + 6 * s, gateTop + 12 * s), (c.w * 67 / 100 - 8 * s, gateTop + 12 * s),
                   (c.w * 10 / 100 + 2 * s, g - 16 * s), (c.w * 10 / 100 + 62 * s, g - 16 * s),
                   (c.w * 72 / 100 + 2 * s, g - 14 * s), (c.w * 72 / 100 + 56 * s, g - 14 * s)]
        let cr = tall ? g / 5 : 22 * s, ty = tall ? g * 18 / 100 : 10 * s
        for (fx, dir) in [(0.04, 1), (0.96, -1)] {
            for k in 0..<3 { out.append((Int(fx * Double(c.w)) + dir * (cr / 3 + k * cr / 3), ty + cr * 2 / 3 + k * 3 * s + (tall ? cr / 4 : 0))) }
        }
        return out
    }

    /// A red silk lantern with gold caps and a tassel.
    static func taLoLantern(_ c: PixelCanvas, _ x: Int, _ y: Int, s: Int) {
        c.rect(x, y - 3 * s, max(1, s / 2), 3 * s, C(0x2A1E18))
        c.circle(x, y + 2 * s, 4 * s, C(0xFF9A40, 0.12))
        c.ellipse(x, y + 2 * s, 2 * s, 2 * s, C(0xD83A2A))
        c.rect(x - s, y + s, s, 2 * s, C(0xFFB060))
        c.rect(x - s, y - s / 2, 3 * s, max(1, s / 2) + (s > 1 ? 0 : 0), C(0xE0B040))
        c.rect(x - s, y + 4 * s, 3 * s, max(1, s / 2), C(0xE0B040))
        c.rect(x, y + 5 * s, max(1, s / 2), 2 * s, C(0xE0B040))
    }

    /// Lanterns flickering, seeds of light drifting up, mist sliding over the lake, and Morris hovering and flapping.
    static func taLoLife(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g), lake = taLoLake(c, g)
        for (i, l) in taLoLanterns(c, g).enumerated() {
            let f = 0.5 + 0.5 * sin(t * 3.1 + Double(i) * 1.7) * noise(Int(t * 4) + i)
            c.circle(l.x, l.y + 2 * s, 5 * s, C(0xFFB050, 0.06 + 0.1 * f))
            c.rect(l.x - s, l.y + s, s, s, C(0xFFE0A0, 0.4 + 0.5 * f))
        }
        for i in 0..<4 {                                                           // mist banks drifting over the water
            let w = (60 + Int(noise(i * 3 + 8200) * 80)) * s, span = Double(c.w + w)
            let p = (t * (2 + noise(i * 3 + 8201) * 3) * Double(s) + noise(i * 3 + 8202) * span).truncatingRemainder(dividingBy: span)
            let y = lake.top - 3 * s + Int(noise(i * 3 + 8203) * 6) * s
            c.ellipse(Int(p) - w / 2, y, w / 2, 2 * s, C(0xFFFFF4, 0.22))
        }
        for i in 0..<max(18, c.w * g / (800 * s * s)) {                            // floating seeds of light
            let speed = (1.5 + noise(i * 5 + 8210) * 3) * Double(s)
            let y = Double(g) - (t * speed + noise(i * 5 + 8211) * Double(g)).truncatingRemainder(dividingBy: Double(g))
            let x = noise(i * 5 + 8212) * Double(c.w) + sin(t * 0.6 + Double(i)) * 5 + t * 1.5
            let glow = 0.5 + 0.5 * sin(t * 2.4 + Double(i) * 1.3)
            let col = i % 3 == 0 ? C(0xFFE8A0) : C(0xF0FFF0)
            c.rect(Int(x.truncatingRemainder(dividingBy: Double(c.w))), Int(y), s, s, col.alpha(0.35 + 0.5 * glow))
        }
        do { let s = isTall(c) ? max(2 * unit(g), g / 110) : unit(g); taLoMorris(c, g, t: t, s: s) }
    }

    /// Morris, the dijiang: a round, faceless ball of fur with four wings, hovering by the path.
    static func taLoMorris(_ c: PixelCanvas, _ g: Int, t: Double, s: Int) {
        let mx = c.w * 58 / 100, my = g - 12 * s + Int(sin(t * 2.2) * 2 * Double(s))
        let flap = sin(t * 12) > 0
        for side in [-1, 1] {
            c.rect(mx + side * 4 * s - (side < 0 ? 3 * s : 0), my - (flap ? 3 : 1) * s, 4 * s, 2 * s, C(0xC8D8E8, 0.9))
            c.rect(mx + side * 3 * s - (side < 0 ? 2 * s : 0), my + (flap ? 0 : 1) * s, 3 * s, s, C(0xB0C4D8, 0.85))
        }
        c.ellipse(mx, my, 4 * s, 3 * s, C(0xD8B888))
        c.ellipse(mx - s, my - s, 2 * s, s, C(0xF0D8A8))
        c.rect(mx - 3 * s, my + 2 * s, 7 * s, s, C(0xA8865A))
        for k in 0..<3 { c.rect(mx - 2 * s + k * 2 * s, my + 3 * s, max(1, s / 2) + 0, s, C(0x6A5034)) }
        c.ellipse(mx, g + 2 * s, 3 * s, max(1, s / 2), C(0x000000, 0.15))
    }
}
