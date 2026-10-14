import Foundation

let doctorScenes2: [Location: Place] = [
    .gallifray: Place(name: "Gallifray, the Citadel", panel: 0x2A140C, still: Scenes.gallifray, moving: Scenes.gallifrayLife),
    .skarro: Place(name: "Skarro", panel: 0x0E1612, still: Scenes.skarro, moving: Scenes.skarroLife),
    .tottersYard: Place(name: "Totter's Yard, 1963", panel: 0x0C0E16, still: Scenes.tottersYard, moving: Scenes.tottersYardLife),
    .powellEstate: Place(name: "Powell Estate", panel: 0x1C1E24, still: Scenes.powellEstate, moving: Scenes.powellEstateLife),
    .roaldDollPlass: Place(name: "Roald Doll Plass", panel: 0x141A2E, still: Scenes.roaldDollPlass, moving: Scenes.roaldDollPlassLife),
    .unitHQ: Place(name: "UNIT HQ", panel: 0x121216, still: Scenes.unitHQ, moving: Scenes.unitHQLife),
    .paternosterRow: Place(name: "Paternoster Row", panel: 0x10141E, still: Scenes.paternosterRow, moving: Scenes.paternosterRowLife),
]

// MARK: - Shared bits for these scenes

/// Draws in units of `s` pixels from an origin, with `s` chosen by the caller (landmarks grow on the screen saver).
fileprivate struct D2Pen {
    let c: PixelCanvas, x: Int, y: Int, s: Int
    func rect(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
    func ellipse(_ u: Int, _ v: Int, _ rx: Int, _ ry: Int, _ col: Px) { c.ellipse(x + u * s, y + v * s, rx * s, ry * s, col) }
    func circle(_ u: Int, _ v: Int, _ r: Int, _ col: Px) { c.circle(x + u * s, y + v * s, r * s, col) }
    /// A pointed roof centred on unit column `u`: apex at row `v`, `half` units wide each side at its foot, `h` tall.
    func roof(_ u: Int, _ v: Int, half: Int, h: Int, _ col: Px) {
        let rows = max(1, h * s)
        for r in 0..<rows {
            let hw = half * s * (r + 1) / rows
            c.rect(x + u * s + s / 2 - hw, y + v * s + r, 2 * hw + s % 2, 1, col)
        }
    }
    /// A trapezoid `w` units wide at the bottom, narrowing by `inset` units each side at the top, `h` units tall.
    func trap(_ u: Int, _ v: Int, _ w: Int, _ h: Int, inset: Int, _ col: Px) {
        let rows = max(1, h * s)
        for r in 0..<rows {
            let ins = inset * s * (rows - 1 - r) / rows
            c.rect(x + u * s + ins, y + v * s + r, w * s - 2 * ins, 1, col)
        }
    }
}

/// A 3×5 pixel alphabet, for painted signs and screens.
fileprivate let d2Font: [Character: [String]] = [
    "A": [".#.", "#.#", "###", "#.#", "#.#"], "C": [".##", "#..", "#..", "#..", ".##"],
    "E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"], "I": ["###", ".#.", ".#.", ".#.", "###"],
    "M": ["#.#", "###", "###", "#.#", "#.#"], "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."], "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"], "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    ".": ["...", "...", "...", "...", ".#."],
]

extension Scenes {
    /// How big landmarks are drawn: 1 in the window's strip, 2 or more on the screen saver.
    fileprivate static func d2Big(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(2, g / 120) : 1 }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    fileprivate static func d2Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// Smooth one-dimensional value noise in 0…1.
    fileprivate static func d2Smooth(_ x: Double, seed: Int) -> Double {
        let i = Int(floor(x)), f = x - floor(x)
        let u = f * f * (3 - 2 * f)
        let a = noise(i * 131 + seed * 7919), b = noise((i + 1) * 131 + seed * 7919)
        return a + (b - a) * u
    }

    /// Capital letters in the 3×5 alphabet, centred on `cx`, each pixel `s` square.
    fileprivate static func d2Text(_ c: PixelCanvas, cx: Int, y: Int, _ text: String, _ col: Px, s: Int) {
        var x = cx - (text.count * 4 - 1) * s / 2
        for ch in text {
            if let rows = d2Font[ch] {
                for (r, row) in rows.enumerated() {
                    for (k, p) in row.enumerated() where p == "#" { c.rect(x + k * s, y + r * s, s, s, col) }
                }
            }
            x += 4 * s
        }
    }

    /// A soft round glow: rings of `col` fading out to radius `r`.
    fileprivate static func d2Glow(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ col: Px, _ strength: Double) {
        for k in 0..<4 {
            c.circle(x, y, max(1, r * (4 - k) / 4), col.alpha(strength * 0.3))
        }
    }

    /// A ragged ridge of hills or mountains standing on `base`, up to `amp` pixels high, with snow above `snow` (0…1).
    fileprivate static func d2Ridge(_ c: PixelCanvas, base: Int, amp: Int, scale: Double, seed: Int, _ col: Px,
                                    snow: Double? = nil, snowCol: Px = C(0xF4E6DA)) {
        for x in 0..<c.w {
            let v = d2Smooth(Double(x) / scale, seed: seed) * 0.72 + d2Smooth(Double(x) / (scale / 3), seed: seed + 1) * 0.28
            let top = base - Int(v * Double(amp))
            if top < base { c.rect(x, top, 1, base - top, col) }
            if let snow, v > snow { c.rect(x, top, 1, 1 + Int((v - snow) * Double(amp) * 0.9), snowCol) }
        }
    }

    /// A blue police box with its lamp, standing on `foot`, centred on `x`, in units of `b` (32 units tall).
    fileprivate static func d2PoliceBox(_ c: PixelCanvas, x: Int, foot: Int, b: Int) {
        let p = D2Pen(c: c, x: x, y: foot, s: b)
        let blue = C(0x1E4A8C), dark = C(0x14336A), light = C(0x3A6AB0), sign = C(0x0E1218)
        p.rect(-7, -2, 14, 2, dark)                                      // the plinth
        p.rect(-6, -26, 12, 24, blue)                                   // the body
        p.rect(-6, -26, 2, 24, light); p.rect(4, -26, 2, 24, dark)      // corner posts
        p.rect(-5, -26, 10, 2, sign)                                    // POLICE BOX
        for u in stride(from: -4, through: 3, by: 2) { p.rect(u, -25, 1, 1, C(0xE8EEF4)) }
        p.rect(-7, -28, 14, 2, dark); p.rect(-6, -29, 12, 1, blue); p.rect(-4, -30, 8, 1, dark)   // the stepped roof
        p.rect(-1, -33, 2, 3, C(0xE8F0FF)); p.rect(-2, -34, 4, 1, dark)                            // the lamp
        p.rect(0, -23, 1, 21, dark)                                     // the doors' seam
        for side in [-4, 1] {
            p.rect(side, -23, 3, 3, C(0xD8E4F0))                       // windows
            p.rect(side + 1, -23, 1, 3, dark); p.rect(side, -22, 3, 1, dark)
            for k in 0..<3 { p.rect(side, -18 + k * 5, 3, 4, dark.alpha(0.8)); p.rect(side, -18 + k * 5, 3, 1, light.alpha(0.5)) }
        }
        p.rect(-4, -18, 3, 2, C(0xD8D8C8, 0.85))                         // the notice on the door
    }

    /// A Dalick in silhouette, gliding: its foot at `foot`, centred on `x`, facing `dir` (1 right, -1 left), 15 units tall.
    fileprivate static func d2Dalick(_ c: PixelCanvas, x: Int, foot: Int, b: Int, dir: Int, eye: Double, lights: Bool) {
        let body = C(0x1C2226), rim = C(0x46545C), bump = C(0x323C42)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) {
            let uu = dir > 0 ? u : -(u + w)
            c.rect(x + uu * b, foot + v * b, w * b, h * b, col)
        }
        for k in 0..<7 {                                                 // the skirt, narrowing upward
            let ins = (6 - k) / 3
            r(-5 + ins, -1 - k, 10 - 2 * ins, 1, body)
        }
        r(-5, -1, 10, 1, rim)
        for v in [-6, -4, -2] { for u in [-3, -1, 1, 3] { r(u, v, 1, 1, bump) } }
        r(-3, -9, 6, 2, body); r(-3, -9, 6, 1, rim)                      // the shoulders
        r(3, -9, 3, 1, rim); r(6, -10, 1, 3, body)                       // the plunger
        r(3, -8, 4, 1, C(0x2A3236))                                      // the gun
        r(-2, -12, 5, 3, body); r(-2, -11, 5, 1, rim)                    // the neck rings
        r(-2, -14, 4, 2, body); r(-1, -15, 2, 1, body)                   // the dome
        r(2, -13, 3, 1, rim)                                             // the eyestalk
        r(5, -13, 1, 1, C(0x6AD0FF).alpha(0.5 + 0.5 * eye))
        if lights { r(-2, -15, 1, 1, C(0xFFB84A)); r(1, -15, 1, 1, C(0xFFB84A)) }
    }
}

// MARK: - Gallifray, the Citadel

extension Scenes {
    /// The citadel's centre, the row its dome stands on, the dome's radii and the size of one unit.
    static func gallifrayFrame(_ c: PixelCanvas, _ g: Int) -> (cx: Int, base: Int, rx: Int, ry: Int, b: Int) {
        let b = d2Big(c, g)
        return (Int(Double(c.w) * 0.64), g - (isTall(c) ? 10 : 6) * b, 50 * b, 46 * b, b)
    }

    /// The citadel's spires, as (unit column, height, width).
    static let gallifraySpires: [(u: Int, h: Int, w: Int)] = [
        (-41, 8, 5), (41, 9, 5), (-34, 13, 3), (34, 15, 3), (-27, 18, 5), (27, 20, 5), (-20, 30, 3), (20, 22, 3),
        (-13, 24, 5), (13, 26, 5), (-7, 31, 3), (7, 33, 3), (0, 40, 5),
    ]

    /// Gallifray, the Citadel: an orange sky with two suns, one big and one small, snow-capped mountains in the haze
    /// and rolling plains of red grass. On the right stands the citadel, a crowd of slender silver spires on a rock
    /// under a great glass dome ringed in metal, its glass catching the light along its rim. On the screen saver
    /// high streaks of cloud cross the sky.
    static func gallifray(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = gallifrayFrame(c, g), b = f.b
        c.gradient(0, g, C(0xB4441C), C(0xF6BC64), bands: 8)
        // The two suns.
        let sx = Int(Double(c.w) * 0.2), sy = tall ? g * 3 / 10 : 17
        d2Glow(c, sx, sy, 22 * b, C(0xFFE8A8), 0.5)
        c.circle(sx, sy, 8 * b, C(0xFFF4CC)); c.circle(sx - 2 * b, sy - 2 * b, 4 * b, C(0xFFFCEC))
        let tx = sx + 26 * b, ty = sy - (tall ? 22 : 9) * b
        d2Glow(c, tx, ty, 9 * b, C(0xFFE0A0), 0.4)
        c.circle(tx, ty, 3 * b, C(0xFFEAC0))
        if tall {
            for i in 0..<7 {
                let x = Int(noise(i * 5 + 40) * Double(c.w)), y = Int(noise(i * 5 + 41) * Double(f.base - f.ry - 20 * b))
                wisp(c, x, max(4, y), (30 + Int(noise(i * 5 + 42) * 60)) * b, C(0xFFD8A0, 0.45), s: b)
            }
        }
        // Mountains in the haze, the plains in front.
        d2Ridge(c, base: g - 7 * b, amp: (tall ? 34 : 26) * b, scale: Double(30 * b), seed: 3, C(0xC07858), snow: 0.62,
                snowCol: C(0xFBE8D8))
        d2Ridge(c, base: g - 5 * b, amp: (tall ? 18 : 12) * b, scale: Double(20 * b), seed: 7, C(0xA45A44), snow: 0.75,
                snowCol: C(0xF0D8C8))
        c.dunes(base: g - (tall ? 16 : 6) * b, amp: Double(2 * b), freq: 0.02 / Double(b), phase: 1, bottom: g, C(0x9A2E1E),
                shade: C(0xC4442C))
        if tall {
            c.dunes(base: g - 10 * b, amp: Double(2 * b), freq: 0.03 / Double(b), phase: 2, bottom: g, C(0x922A1C), shade: C(0xB83C28))
        }
        gallifrayCitadel(c, g)
        c.dunes(base: g - 2 * b, amp: Double(b) * 1.5, freq: 0.035 / Double(b), phase: 3, bottom: g, C(0x8A2418), shade: C(0xD04A30))
        c.ground(g, C(0x701E16), edge: C(0xC8462E), speck: C(0x501410), seed: 5)
    }

    /// The citadel: rock, spires, the metal ring and the glass dome.
    static func gallifrayCitadel(_ c: PixelCanvas, _ g: Int) {
        let f = gallifrayFrame(c, g), b = f.b, cx = f.cx, base = f.base
        let p = D2Pen(c: c, x: cx, y: base, s: b)
        for k in 0..<(4 * b) {                                           // the rock it stands on
            let half = 46 * b - k * k / max(1, b)
            c.rect(cx - half, base + 2 * b + k, 2 * half, 1, k < b ? C(0x8A5A44) : C(0x5A3A30))
        }
        let body = C(0xE6DCC4), lit = C(0xFFF6E2), shade = C(0xA89A84)
        for sp in gallifraySpires {
            let u0 = sp.u - sp.w / 2
            p.rect(u0, -sp.h - 2, sp.w, sp.h + 2, body)
            p.rect(u0, -sp.h - 2, 1, sp.h + 2, lit); p.rect(u0 + sp.w - 1, -sp.h - 2, 1, sp.h + 2, shade)
            p.roof(sp.u, -sp.h - 6, half: sp.w / 2 + 1, h: 4, body)
            p.rect(sp.u, -sp.h - 8, 1, 2, C(0xFFE8B0))
            for k in stride(from: -sp.h + 2, to: -3, by: 5) { p.rect(u0, k, sp.w, 1, shade.alpha(0.7)) }
            p.rect(u0 - 1, -sp.h / 2, sp.w + 2, 1, C(0xC8A870))         // a gold collar
        }
        // Shell-like petals sweeping round the spires' feet.
        p.ellipse(0, -4, 30, 3, C(0xD4C4A4)); p.ellipse(0, -5, 28, 2, C(0xEADCC0))
        // The metal ring and the glass.
        let rx = f.rx, ry = f.ry
        for dy in 0...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int(Double(rx) * k.squareRoot())
            c.rect(cx - half, base - dy, 2 * half, 1, C(0xFFEACC, 0.1))
        }
        for lat in [0.45, 0.95] {
            let y = base - Int(sin(lat) * Double(ry)), half = Int(cos(lat) * Double(rx))
            c.rect(cx - half, y, 2 * half, max(1, b / 2), C(0xFFF4E0, 0.16))
        }
        for lon in [-0.9, -0.45, 0.45, 0.9] {
            for i in 0..<ry {
                let lat = Double(i) / Double(ry) * .pi / 2
                c.rect(cx + Int(sin(lon) * cos(lat) * Double(rx)), base - Int(sin(lat) * Double(ry)), max(1, b / 2), 1, C(0xFFF4E0, 0.16))
            }
        }
        let n = rx * 4
        for i in 0...n {
            let th = Double(i) / Double(n) * .pi
            let x = cx + Int(cos(th) * Double(rx)), y = base - Int(sin(th) * Double(ry))
            c.rect(x, y, b, b, C(0xFFF2DC, 0.7))
            if th > .pi * 0.55 && th < .pi * 0.85 {
                c.rect(x + b, y + b, b, b, C(0xFFFFFF, 0.45))
                let x2 = cx + Int(cos(th) * Double(rx) * 0.84), y2 = base - Int(sin(th) * Double(ry) * 0.84)
                c.rect(x2, y2, b, b, C(0xFFFFFF, 0.3))
            }
        }
        c.rect(cx - rx - 3 * b, base - b, 2 * rx + 6 * b, 3 * b, C(0x8A7E78))
        c.rect(cx - rx - 3 * b, base - b, 2 * rx + 6 * b, b, C(0xD8CCC0))
        for u in stride(from: -rx, through: rx, by: 10 * b) { c.rect(cx + u, base, b, b, C(0xFFD080)) }
    }

    /// Red grass rippling in waves across the plain, a glint running round the dome, windows twinkling in the spires.
    static func gallifrayLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = gallifrayFrame(c, g), b = f.b
        for i in 0..<(c.w / (2 * b) + 1) {
            let x = i * 2 * b + Int(noise(i * 3 + 7) * Double(b))
            let wave = sin(Double(x) * 0.035 / Double(b) - t * 1.6)
            let lean = sin(Double(x) * 0.08 / Double(b) - t * 2.4) * 0.6 + wave * 0.8
            let len = 2 + Int(noise(i * 3 + 8) * 3)
            let col = lerp(C(0xA82C1C), C(0xF2683E), (wave + 1) / 2)
            for k in 0..<len {
                let dx = Int(lean * Double(k * b) / Double(len) * 1.4)
                c.rect(x + dx, g - (k + 1) * b, b, b, col)
            }
        }
        // The glint on the dome.
        let ph = d2Phase(t, 8)
        if ph < 0.5 {
            let th = .pi * (1 - ph * 2)
            let x = f.cx + Int(cos(th) * Double(f.rx)), y = f.base - Int(sin(th) * Double(f.ry))
            c.rect(x - 2 * b, y, 5 * b, b, C(0xFFFFFF, 0.6)); c.rect(x, y - 2 * b, b, 5 * b, C(0xFFFFFF, 0.6))
            c.rect(x, y, b, b, C(0xFFFFFF))
        }
        for i in 0..<8 {
            let sp = gallifraySpires[Int(noise(i * 7 + Int(t / 2.5) * 17) * Double(gallifraySpires.count)) % gallifraySpires.count]
            let v = -3 - Int(noise(i * 7 + 1) * Double(max(1, sp.h - 4)))
            if noise(i * 11 + Int(t * 3)) > 0.4 {
                c.rect(f.cx + sp.u * b, f.base + v * b, b, b, C(0xFFC860))
            }
        }
    }
}

// MARK: - Skarro, the Dalick City

extension Scenes {
    /// The raised walkway the patrol glides along, and the size of one unit.
    static func skarroFrame(_ c: PixelCanvas, _ g: Int) -> (wy: Int, b: Int) {
        let b = d2Big(c, g)
        return (g - (isTall(c) ? 24 : 14) * b, b)
    }

    /// The city's pylons, as (fraction across, height in units).
    static func skarroPylons(_ c: PixelCanvas) -> [(f: Double, h: Int)] {
        isTall(c) ? [(0.07, 70), (0.33, 96), (0.66, 84), (0.93, 62)] : [(0.07, 40), (0.33, 46), (0.66, 44), (0.93, 38)]
    }

    /// Skarro: the Dalick City on a dead planet. A sickly green sky with a pale moon low in the haze, a far skyline of
    /// domes, and in front the city itself: great ribbed metal domes, tapering pylons with bulbs at their tips, tubes
    /// strung between, and a raised walkway across the whole width for the patrol. Petrified trees stand in the ash
    /// below. On the screen saver the pylons climb high into a sky with a few faint stars.
    static func skarro(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = skarroFrame(c, g), b = f.b, wy = f.wy
        c.gradient(0, g, C(0x0A1410), C(0x56704A), bands: 7)
        if tall { c.stars(0, g / 3, density: 160, seed: 21) }
        let mx = Int(Double(c.w) * 0.8), my = tall ? g / 4 : 16
        d2Glow(c, mx, my, 26 * b, C(0xC8D8A0), 0.25)
        c.circle(mx, my, 13 * b, C(0xA8B888)); c.circle(mx - 3 * b, my - 2 * b, 3 * b, C(0x94A474))
        c.circle(mx + 5 * b, my + 4 * b, 2 * b, C(0x94A474)); c.circle(mx + 4 * b, my - 6 * b, b, C(0x94A474))
        c.rect(mx - 16 * b, my + 3 * b, 32 * b, b, C(0x56704A, 0.6))      // haze across the moon
        // The far skyline of domes and towers.
        var x = -4 * b, i = 0
        while x < c.w {
            let w = (10 + Int(noise(i * 5 + 300) * 18)) * b
            let h = (6 + Int(noise(i * 5 + 301) * (tall ? 30 : 16))) * b
            c.rect(x, wy - h, w, h, C(0x22302A))
            if noise(i * 5 + 302) > 0.45 { c.ellipse(x + w / 2, wy - h, w / 2, w / 3, C(0x22302A)) }
            else { c.rect(x + w / 2 - b, wy - h - 6 * b, 2 * b, 6 * b, C(0x22302A)) }
            if noise(i * 5 + 304) > 0.5 { c.rect(x + w / 3, wy - h + 3 * b, max(1, b), max(1, b), C(0x9ACA6A, 0.6)) }
            x += w + Int(noise(i * 5 + 303) * Double(8 * b)); i += 1
        }
        c.rect(0, wy - 3 * b, c.w, 3 * b, C(0x56704A, 0.35))
        // The city.
        let metal = C(0x56626A), light = C(0x8E9CA4), dark = C(0x343E44)
        let domes: [(f: Double, rx: Int, ry: Int)] = tall
            ? [(0.2, 36, 22), (0.5, 56, 34), (0.84, 42, 26)] : [(0.2, 18, 11), (0.5, 30, 18), (0.84, 22, 13)]
        for d in domes {
            let cx = Int(Double(c.w) * d.f), rx = d.rx * b, ry = d.ry * b
            for dy in 0...ry {
                let k = 1 - Double(dy * dy) / Double(ry * ry)
                let half = Int(Double(rx) * k.squareRoot())
                let band = (dy / (3 * b)) % 2 == 0
                c.rect(cx - half, wy - dy, 2 * half, 1, band ? metal : C(0x4C5860))
                c.rect(cx - half, wy - dy, max(1, half / 3), 1, light.alpha(0.5))
                c.rect(cx + half - max(1, half / 4), wy - dy, max(1, half / 4), 1, dark)
            }
            c.rect(cx - b, wy - ry - 8 * b, 2 * b, 8 * b, dark); c.circle(cx, wy - ry - 9 * b, 2 * b, metal)
            for k in stride(from: -rx * 2 / 3, through: rx * 2 / 3, by: 5 * b) {
                c.rect(cx + k, wy - ry / 3, 2 * b, b, C(0xFFB84A, 0.8))
            }
        }
        for py in skarroPylons(c) {
            let px = Int(Double(c.w) * py.f), h = py.h * b
            for r in 0..<h {
                let half = 3 * b - (2 * b * r) / h
                c.rect(px - half, wy - r, 2 * half, 1, metal)
                c.rect(px - half, wy - r, max(1, b), 1, light)
                c.rect(px + half - b, wy - r, b, 1, dark)
            }
            for k in stride(from: 6 * b, to: h - 4 * b, by: 7 * b) { c.rect(px - 3 * b, wy - k, 6 * b, b, dark) }
            c.circle(px, wy - h, 3 * b, metal); c.circle(px - b, wy - h - b, b, light)
            c.rect(px - b / 2, wy - h - 7 * b, max(1, b), 4 * b, dark)
        }
        // Tubes strung between the pylons.
        let pyl = skarroPylons(c)
        for k in 0..<(pyl.count - 1) {
            let x0 = Int(Double(c.w) * pyl[k].f), x1 = Int(Double(c.w) * pyl[k + 1].f)
            let y = wy - min(pyl[k].h, pyl[k + 1].h) * b / 2
            for xx in x0..<x1 {
                let fr = Double(xx - x0) / Double(max(1, x1 - x0))
                let sag = Int(4 * fr * (1 - fr) * Double(4 * b))
                c.rect(xx, y + sag, 1, 2 * b, dark); c.px(xx, y + sag, light)
            }
        }
        // The under-city below the walkway: ash slopes, hatches, a few lit ports.
        c.gradient(wy + 3 * b, g, C(0x1E2620), C(0x2E342A), bands: 3)
        for i in 0..<(c.w / (30 * b) + 1) {
            let hx = i * 30 * b + Int(noise(i + 640) * Double(10 * b)), hy = wy + 6 * b + Int(noise(i + 641) * Double(max(1, g - wy - 12 * b)))
            c.rect(hx, hy, 8 * b, 4 * b, C(0x161C18)); c.rect(hx + b, hy + b, 6 * b, b, C(0xFFB84A, noise(i + 642) > 0.5 ? 0.6 : 0.15))
        }
        // The walkway and its supports.
        for sx in stride(from: 10 * b, to: c.w, by: 40 * b) {
            c.rect(sx, wy + 3 * b, 4 * b, g - wy - 3 * b, C(0x262E32)); c.rect(sx, wy + 3 * b, b, g - wy - 3 * b, C(0x3E4A50))
        }
        c.rect(0, wy, c.w, 3 * b, C(0x3A464C)); c.rect(0, wy, c.w, b, C(0x8A9AA2)); c.rect(0, wy + 3 * b, c.w, b, C(0x1A2024))
        for sx in stride(from: 4 * b, to: c.w, by: 12 * b) { c.rect(sx, wy + b, 2 * b, b, C(0xFFB84A, 0.5)) }
        // Petrified trees in the ash.
        for (k, fx) in [0.02, 0.14, 0.45, 0.76, 0.98].enumerated() {
            let tx = Int(Double(c.w) * fx), th = (8 + Int(noise(k + 600) * 6)) * b
            c.rect(tx, g - th, 2 * b, th, C(0x0E120E))
            for j in 0..<3 {
                let dir = j % 2 == 0 ? -1 : 1, by = g - th + (j + 1) * th / 4, len = (3 + j) * b
                for q in 0..<len { c.rect(tx + b + dir * q, by - q / 2, b, b, C(0x0E120E)) }
            }
        }
        c.ground(g, C(0x34382E), edge: C(0x6A705A), speck: C(0x24281E), seed: 12)
    }

    /// The Dalick patrol gliding along the walkway, lights pulsing on the pylon tips; on the screen saver a saucer
    /// drifts across the sky.
    static func skarroLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = skarroFrame(c, g), b = f.b
        let span = Double(c.w + 60 * b)
        for i in 0..<3 {
            let x = Int((t * 10 * Double(b) + Double(i * 22 * b)).truncatingRemainder(dividingBy: span)) - 30 * b
            d2Dalick(c, x: x, foot: f.wy, b: b, dir: 1, eye: 0.5 + 0.5 * sin(t * 3 + Double(i)),
                     lights: d2Phase(t, 1.2, offset: Double(i) * 0.4) < 0.5)
        }
        for (k, py) in skarroPylons(c).enumerated() {
            let px = Int(Double(c.w) * py.f), y = f.wy - py.h * b - 7 * b
            let pulse = 0.5 + 0.5 * sin(t * 2.2 + Double(k) * 1.3)
            c.circle(px, y, 2 * b, C(0xFF5A3A, 0.25 + 0.5 * pulse)); c.rect(px - b / 2, y, max(1, b), max(1, b), C(0xFFB89A))
        }
        guard isTall(c) else { return }
        let sx = Int(d2Phase(t, 40) * Double(c.w + 80 * b)) - 40 * b, sy = g / 5 + Int(sin(t * 0.8) * Double(3 * b))
        let p = D2Pen(c: c, x: sx, y: sy, s: b)
        p.ellipse(0, 0, 16, 3, C(0x3A464C)); p.ellipse(0, -2, 8, 3, C(0x56626A)); p.rect(-16, 0, 32, 1, C(0x8A9AA2))
        for u in stride(from: -12, through: 12, by: 4) where d2Phase(t, 0.8, offset: Double(u) * 0.05) < 0.5 {
            p.rect(u, 1, 1, 1, C(0xFFB84A))
        }
    }
}

// MARK: - Totter's Yard, 1963

extension Scenes {
    /// The yard gate's centre, the top of the wall, where the police box stands, and the size of one unit.
    static func tottersFrame(_ c: PixelCanvas, _ g: Int) -> (gx: Int, wt: Int, boxX: Int, boxFoot: Int, lampX: Int, b: Int) {
        let b = d2Big(c, g), gx = Int(Double(c.w) * 0.44)
        return (gx, g - 22 * b, gx + 2 * b, g - 2 * b, Int(Double(c.w) * 0.1), b)
    }

    /// Totter's Yard on a foggy night in 1963: a brick wall along a cobbled lane, I.M. FOREMAN SCRAP MERCHANT painted
    /// on it, junk heaped up behind, a lamp-post throwing a pool of light. The yard's gates stand open, and inside,
    /// among the junk, waits a blue police box with its lamp on top. A hazy moon hangs over it all; on the screen
    /// saver the roofs and chimneys of the terrace rise behind the yard.
    static func tottersYard(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = tottersFrame(c, g), b = f.b, gx = f.gx, wt = f.wt
        c.gradient(0, g, C(0x070A14), C(0x222A3C), bands: 6)
        c.stars(0, wt - 20 * b, density: 260, seed: 41)
        let mx = Int(Double(c.w) * 0.8), my = tall ? g / 5 : 13
        d2Glow(c, mx, my, 24 * b, C(0xC8D0E0), 0.35)
        c.circle(mx, my, 7 * b, C(0xE4E6EC)); c.circle(mx + 2 * b, my - b, 2 * b, C(0xCCD0D8))
        if tall {
            // The terrace behind: roofs, chimney stacks, a few lit windows.
            var x = -6 * b, i = 0
            let ty = wt - 26 * b
            while x < c.w {
                let w = (28 + Int(noise(i * 3 + 500) * 20)) * b, h = (Int(noise(i * 3 + 501) * 14)) * b
                c.rect(x, ty - h, w, wt - ty + h, C(0x0C0F18))
                D2Pen(c: c, x: x + w / 2, y: ty - h, s: b).roof(0, -12, half: w / (2 * b), h: 12, C(0x0C0F18))
                c.rect(x, ty - h - b, w, max(1, b / 2), C(0x2A3248))
                c.rect(x + 4 * b, ty - h - 16 * b, 4 * b, 8 * b, C(0x0C0F18)); c.rect(x + 4 * b, ty - h - 18 * b, b, 2 * b, C(0x0C0F18))
                c.rect(x + 6 * b, ty - h - 18 * b, b, 2 * b, C(0x0C0F18))
                for k in 0..<3 where noise(i * 9 + k + 520) > 0.6 {
                    c.rect(x + (6 + k * 8) * b, ty - h + 6 * b, 3 * b, 4 * b, C(0xE8C070, 0.7))
                }
                x += w; i += 1
            }
        }
        // Junk heaped over the wall: piles, a cart wheel, a ladder, a bedstead.
        d2Ridge(c, base: wt, amp: 12 * b, scale: Double(14 * b), seed: 44, C(0x0A0C12))
        let junk = C(0x0A0C12)
        for (k, fx) in [0.25, 0.62, 0.86].enumerated() {
            let jx = Int(Double(c.w) * fx), jy = wt - (8 + k * 2) * b
            c.circle(jx, jy, 6 * b, junk); c.circle(jx, jy, 5 * b, C(0x2A3246)); c.circle(jx, jy, 4 * b, C(0x1A2030)); c.circle(jx, jy, b, junk)
            for a in 0..<6 {
                let th = Double(a) * .pi / 3
                c.rect(jx + Int(cos(th) * Double(4 * b)), jy + Int(sin(th) * Double(4 * b)), b, b, junk)
            }
        }
        let lx = Int(Double(c.w) * 0.72)
        for k in 0..<(16 * b) { c.rect(lx + k / 3, wt - k, b, 1, junk); c.rect(lx + 4 * b + k / 3, wt - k, b, 1, junk) }
        for k in stride(from: 2 * b, to: 16 * b, by: 3 * b) { c.rect(lx + k / 3, wt - k, 5 * b, b, junk) }
        // The wall, brick by brick.
        c.rect(0, wt, c.w, g - wt, C(0x3E2A24))
        for (r, y) in stride(from: wt + 2 * b, to: g, by: 3 * b).enumerated() {
            c.rect(0, y, c.w, max(1, b / 2), C(0x2A1C18))
            for x in stride(from: (r % 2) * 3 * b, to: c.w, by: 6 * b) { c.rect(x, y - 3 * b + max(1, b / 2), max(1, b / 2), 3 * b, C(0x2A1C18)) }
        }
        for i in 0..<(c.w / (5 * b)) {
            let x = Int(noise(i * 3 + 560) * Double(c.w)), y = wt + Int(noise(i * 3 + 561) * Double(g - wt))
            c.rect(x, y, 2 * b, b, C(0x4E342C, 0.7))
        }
        c.rect(0, wt - b, c.w, 2 * b, C(0x4E3C36)); c.rect(0, wt - b, c.w, max(1, b / 2), C(0x6A5650))
        // The painted name.
        let sx = gx - 52 * b
        d2Text(c, cx: sx, y: wt + 5 * b, "I.M. FOREMAN", C(0xD0CCBC, 0.85), s: b)
        d2Text(c, cx: sx, y: wt + 12 * b, "SCRAP MERCHANT", C(0xD0CCBC, 0.75), s: b)
        // The yard through the open gates.
        let ox = gx - 15 * b, ow = 30 * b
        c.rect(ox, wt - b, ow, g - wt + b, C(0x1A1E28))
        c.rect(ox, g - 4 * b, ow, 4 * b, C(0x22242C))
        for (k, u) in [-12, 9].enumerated() {
            let p = D2Pen(c: c, x: gx, y: g - 2 * b, s: b)
            p.trap(u - 2, -9 - k * 2, 7, 9 + k * 2, inset: 2, C(0x11141C))
            p.rect(u, -12 - k, 1, 4, C(0x11141C))
        }
        d2PoliceBox(c, x: f.boxX, foot: f.boxFoot, b: b)
        // Gate doors swung in, and the brick posts.
        for side in [-1, 1] {
            let dx = side < 0 ? gx - 14 * b : gx + 11 * b
            c.rect(dx, wt - 4 * b, 3 * b, g - wt + 3 * b, C(0x3A3020))
            c.rect(dx, wt - 4 * b, b, g - wt + 3 * b, C(0x4E4230))
            for k in stride(from: wt, to: g, by: 6 * b) { c.rect(dx, k, 3 * b, max(1, b / 2), C(0x2A2216)) }
            let px = side < 0 ? gx - 18 * b : gx + 15 * b
            c.rect(px, g - 28 * b, 3 * b, 28 * b, C(0x4A322A)); c.rect(px, g - 28 * b, b, 28 * b, C(0x5E443A))
            c.rect(px - b, g - 30 * b, 5 * b, 2 * b, C(0x5A4A44)); c.rect(px, g - 31 * b, 3 * b, b, C(0x5A4A44))
        }
        // The lamp-post and its pool of light.
        let lp = f.lampX
        c.rect(lp, g - 32 * b, max(1, b), 32 * b, C(0x1A1C22)); c.rect(lp - b, g - 3 * b, 3 * b, 3 * b, C(0x1A1C22))
        c.rect(lp - 2 * b, g - 36 * b, 5 * b, 4 * b, C(0xF2D48A)); c.rect(lp - 2 * b, g - 37 * b, 5 * b, b, C(0x1A1C22))
        c.rect(lp, g - 36 * b, max(1, b), 4 * b, C(0x1A1C22, 0.6))
        d2Glow(c, lp, g - 34 * b, 20 * b, C(0xF2D48A), 0.35)
        c.ground(g, C(0x1C1E24), edge: C(0x50545E), speck: C(0x2A2C34), seed: 43)
        c.ellipse(lp, g + 2, 18 * b, 2 * b, C(0xF2D48A, 0.14))
    }

    /// Fog drifting along the lane in slow banks, and the police box's lamp glowing softly.
    static func tottersYardLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = tottersFrame(c, g), b = f.b, tall = isTall(c)
        let lampY = f.boxFoot - 32 * b
        c.circle(f.boxX, lampY, 3 * b, C(0xE8F0FF, 0.06 + 0.1 * (0.5 + 0.5 * sin(t * 1.4))))
        let banks: [(y: Int, h: Int, speed: Double, a: Double)] = tall
            ? [(g - 3 * b, 6 * b, 5, 0.3), (g - 13 * b, 7 * b, -3, 0.24), (f.wt - 4 * b, 8 * b, 4, 0.2),
               (f.wt - 40 * b, 10 * b, -2, 0.14), (g / 3, 12 * b, 2.5, 0.1)]
            : [(g - 3 * b, 5 * b, 5, 0.3), (g - 13 * b, 5 * b, -3, 0.24), (f.wt - 6 * b, 6 * b, 4, 0.18)]
        for (k, bank) in banks.enumerated() {
            let step = 2 * b
            for x in stride(from: 0, to: c.w, by: step) {
                let v = d2Smooth((Double(x) + t * bank.speed * Double(b)) / Double(36 * b), seed: 70 + k)
                let a = bank.a * max(0, v * 1.4 - 0.25)
                guard a > 0.01 else { continue }
                let bob = Int(sin(Double(x) * 0.02 / Double(b) + t * 0.3 + Double(k)) * Double(b))
                let y = bank.y + bob
                c.rect(x, y - bank.h / 2, step, bank.h, C(0xA8B0C4, a))
                c.rect(x, y - bank.h / 2 - 2 * b, step, 2 * b, C(0xA8B0C4, a * 0.5))
                c.rect(x, y + bank.h / 2, step, 2 * b, C(0xA8B0C4, a * 0.5))
            }
        }
    }
}

// MARK: - Powell Estate

extension Scenes {
    /// The block's foot, how many storeys it has and how tall each is, where the washing line runs, and one unit.
    static func powellFrame(_ c: PixelCanvas, _ g: Int) -> (base: Int, floors: Int, sh: Int, p1: Int, p2: Int, lineY: Int, b: Int) {
        let b = d2Big(c, g)
        return (g - 4 * b, isTall(c) ? 6 : 4, 11 * b, Int(Double(c.w) * 0.58), Int(Double(c.w) * 0.88), g - 21 * b, b)
    }

    /// Where the little washing lines hang on the balconies, as (x, y, length).
    static func powellBalconyLines(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, len: Int)] {
        let f = powellFrame(c, g), b = f.b
        return [(0.17, 2), (0.47, 1), (0.74, 3), (0.9, 2)].compactMap { (fx: Double, j: Int) in
            guard j < f.floors else { return nil }
            return (Int(Double(c.w) * fx), f.base - j * f.sh - 7 * b, 14 * b)
        }
    }

    /// The Powell Estate: a London council block under a grey-blue sky, brick with long concrete deck walkways, rows
    /// of front doors in every colour, a concrete stairwell tower, a grass verge in front and a tarmac courtyard
    /// where a washing line hangs between two poles. On the screen saver the block grows taller, with tower blocks
    /// behind it.
    static func powellEstate(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = powellFrame(c, g), b = f.b, base = f.base, sh = f.sh
        let top = base - f.floors * sh
        c.gradient(0, g, C(0x7E98B6), C(0xD6DCE2), bands: 6)
        let nc = tall ? 7 : 3
        for i in 0..<nc {
            let x = Int(noise(i * 5 + 100) * Double(c.w)), y = 6 * b + Int(noise(i * 5 + 101) * Double(max(4, top - 14 * b)))
            cloud(c, x, y, (3 + Int(noise(i * 5 + 102) * 3)) * b, seed: i + 30, top: C(0xEEF1F4), base: C(0xC2CAD4))
        }
        if tall {
            for (k, fx) in [0.12, 0.78].enumerated() {
                let tx = Int(Double(c.w) * fx), tw = (34 + k * 8) * b, ty = top - (60 + k * 30) * b
                c.rect(tx, ty, tw, base - ty, C(0x8A929C)); c.rect(tx, ty, b, base - ty, C(0xA8B0B8))
                for y in stride(from: ty + 4 * b, to: base, by: 6 * b) {
                    c.rect(tx, y + 3 * b, tw, b, C(0x9EA6AE))
                    for x in stride(from: tx + 3 * b, to: tx + tw - 3 * b, by: 6 * b) {
                        c.rect(x, y, 3 * b, 2 * b, noise(x * 7 + y) > 0.85 ? C(0xE8D8A0) : C(0x5A6470))
                    }
                }
            }
        }
        // The block.
        let x0 = Int(Double(c.w) * 0.03), x1 = Int(Double(c.w) * 0.97)
        c.rect(x0, top, x1 - x0, base - top, C(0x8E5E46))
        for y in stride(from: top + b, to: base, by: 2 * b) { c.rect(x0, y, x1 - x0, max(1, b / 2), C(0x7E5240, 0.5)) }
        c.rect(x0, top - 2 * b, x1 - x0, 2 * b, C(0xB0A898)); c.rect(x0, top - 2 * b, x1 - x0, max(1, b / 2), C(0xD0C8BA))
        c.rect(x1 - 2 * b, top, 2 * b, base - top, C(0x6A4434))
        let doors: [UInt32] = [0x2A4A8A, 0xA82A2A, 0x2A6A3A, 0xD8B040, 0x1E1E2A, 0xE8E4D8, 0x6A3A7A]
        let stairX = Int(Double(c.w) * 0.34)
        for j in 0..<f.floors {
            let fl = base - j * sh                                         // the floor of this storey
            var k = 0
            for u in stride(from: x0 + 4 * b, to: x1 - 24 * b, by: 26 * b) {
                k += 1
                if abs(u + 12 * b - stairX) < 22 * b { continue }
                let dc = C(doors[Int(noise(j * 31 + k * 7 + 3) * Double(doors.count)) % doors.count])
                c.rect(u + 3 * b, fl - 8 * b, 5 * b, 8 * b, dc); c.rect(u + 3 * b, fl - 8 * b, 5 * b, max(1, b / 2), C(0xE8E8E0))
                c.rect(u + 7 * b, fl - 4 * b, max(1, b / 2), max(1, b / 2), C(0xE8D070))
                let lit = noise(j * 17 + k * 3 + 9) > 0.7
                c.rect(u + 11 * b, fl - 8 * b, 11 * b, 5 * b, C(0xE8E8E0))
                c.rect(u + 12 * b, fl - 7 * b, 9 * b, 3 * b, lit ? C(0xF0D890) : C(0x8AA0B8))
                c.rect(u + 16 * b, fl - 7 * b, max(1, b / 2), 3 * b, C(0xE8E8E0))
                if !lit { c.rect(u + 12 * b, fl - 7 * b, 3 * b, b, C(0xC8D8E8, 0.6)) }
            }
            if j > 0 {
                // The deck walkway along the storey, with its railing.
                c.rect(x0, fl, x1 - x0, 2 * b, C(0xC8C0B0)); c.rect(x0, fl + 2 * b, x1 - x0, b, C(0x4A3A30, 0.7))
                c.rect(x0, fl - 5 * b, x1 - x0, b, C(0xD8D2C4))
                for x in stride(from: x0, to: x1, by: 3 * b) { c.rect(x, fl - 4 * b, max(1, b / 2), 4 * b, C(0x6A6A70, 0.8)) }
            }
        }
        // The stairwell tower.
        c.rect(stairX - 8 * b, top - 6 * b, 16 * b, base - top + 6 * b, C(0xB0A898))
        c.rect(stairX - 8 * b, top - 6 * b, b, base - top + 6 * b, C(0xCCC4B4)); c.rect(stairX + 7 * b, top - 6 * b, b, base - top + 6 * b, C(0x8A8274))
        for y in stride(from: top - 2 * b, to: base - 10 * b, by: 6 * b) { c.rect(stairX - b, y, 2 * b, 4 * b, C(0x3A3A40)) }
        c.rect(stairX - 4 * b, base - 9 * b, 8 * b, 9 * b, C(0x26262C))
        // The verge, the courtyard and the washing poles.
        c.rect(0, base, c.w, g - base, C(0x5A7A3A)); c.rect(0, base, c.w, max(1, b / 2), C(0x7A9A4E))
        c.ground(g, C(0x55575C), edge: C(0x8A8C90), speck: C(0x46484C), seed: 61)
        for px in [f.p1, f.p2] {
            c.rect(px, f.lineY, max(1, b), g - f.lineY, C(0x5A5E66)); c.rect(px - 3 * b, f.lineY, 7 * b, b, C(0x5A5E66))
        }
        for (k, off) in [-3, 3].enumerated() {
            for x in (f.p1 + off * b)..<(f.p2 + off * b) {
                c.px(x, powellLine(f.p1 + off * b, f.p2 + off * b, x, f.lineY + b, sag: (3 + k) * b), C(0xE0E0E0, 0.8))
            }
        }
        for l in powellBalconyLines(c, g) { c.rect(l.x, l.y, l.len, max(1, b / 2), C(0xE0E0E0, 0.7)) }
    }

    /// The row a sagging washing line is at, `x` along a line from `x0` to `x1` hung at row `y`.
    static func powellLine(_ x0: Int, _ x1: Int, _ x: Int, _ y: Int, sag: Int) -> Int {
        let fr = Double(x - x0) / Double(max(1, x1 - x0))
        return y + Int(4 * fr * (1 - fr) * Double(sag))
    }

    /// Washing flapping on the lines: shirts, sheets, towels and socks blown sideways by the wind.
    static func powellEstateLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = powellFrame(c, g), b = f.b
        let cols: [UInt32] = [0xF2F2EE, 0xE84A5A, 0x4A7AD8, 0xF2D04A, 0x7AC86A, 0xF29AC8, 0x8A6AD0]
        func item(_ x: Int, _ y: Int, w: Int, h: Int, kind: Int, col: Px, i: Int) {
            let gust = sin(t * 2.6 + Double(i) * 0.9) * 0.6 + sin(t * 5.1 + Double(i) * 2.3) * 0.25 + 0.6
            for r in 0..<h {
                let fr = Double(r) / Double(max(1, h))
                let dx = Int(gust * fr * Double(w) * 0.5)
                var ww = w, xx = x + dx
                if kind == 1 && r < h / 3 { ww = w + 2 * b; xx -= b }                       // a shirt's sleeves
                if kind == 2 && r > h / 2 { c.rect(xx, y + r, w / 3, 1, col); c.rect(xx + w - w / 3, y + r, w / 3, 1, col); continue }
                c.rect(xx, y + r, ww, 1, col)
                if r == 0 { c.rect(xx, y, ww, 1, col.alpha(0.8)) }
            }
            c.rect(x + b, y - b, max(1, b / 2), b, C(0xC8A070)); c.rect(x + w - 2 * b, y - b, max(1, b / 2), b, C(0xC8A070))
        }
        // The big line in the courtyard (the front one).
        let x0 = f.p1 + 3 * b, x1 = f.p2 + 3 * b
        var x = x0 + 3 * b, i = 0
        while x < x1 - 6 * b {
            let kind = Int(noise(i * 7 + 200) * 4)
            let w = [10, 7, 6, 3][kind] * b, h = [8, 7, 9, 4][kind] * b
            guard x + w < x1 - 2 * b else { break }
            let y = powellLine(x0, x1, x + w / 2, f.lineY + b, sag: 4 * b)
            item(x, y + b, w: w, h: h, kind: kind == 0 ? 0 : kind, col: C(cols[Int(noise(i * 7 + 201) * Double(cols.count)) % cols.count]), i: i)
            x += w + (2 + Int(noise(i * 7 + 202) * 3)) * b; i += 1
        }
        // The little lines on the balconies.
        for (k, l) in powellBalconyLines(c, g).enumerated() {
            for q in 0..<3 {
                let kind = (k + q) % 3
                item(l.x + b + q * 5 * b, l.y + b, w: 3 * b, h: (kind == 0 ? 4 : 3) * b, kind: kind == 2 ? 0 : kind,
                     col: C(cols[(k * 3 + q) % cols.count]), i: 20 + k * 3 + q)
            }
        }
    }
}

// MARK: - Roald Doll Plass

extension Scenes {
    /// The horizon, the plaza's back edge, the water tower's centre and height (in units), and one unit.
    static func plassFrame(_ c: PixelCanvas, _ g: Int) -> (hz: Int, pe: Int, fx: Int, fh: Int, b: Int) {
        let b = d2Big(c, g), tall = isTall(c)
        return (g - (tall ? 40 : 24) * b, g - (tall ? 9 : 6) * b, Int(Double(c.w) * 0.6), tall ? 54 : 40, b)
    }

    /// Roald Doll Plass on a Cardiff evening: a sunset sky over the bay, the sun sinking into the far shore, the
    /// bronze shell of the arts centre on the left and the red-brick pierhead with its clock tower on the right. The
    /// plaza's back rail runs along the water, and on the plaza stands the tall silver water tower, water sheeting
    /// down its sides into a pool at its foot, with that one paving slab in front of it that is really a lift.
    static func roaldDollPlass(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = plassFrame(c, g), b = f.b, hz = f.hz, pe = f.pe
        c.gradient(0, hz, C(0x1C2858), C(0xF2A270), bands: 8)
        if tall { c.stars(0, hz / 4, density: 200, seed: 51) }
        let nw = tall ? 8 : 4
        for i in 0..<nw {
            let x = Int(noise(i * 5 + 150) * Double(c.w)), y = 4 * b + Int(noise(i * 5 + 151) * Double(max(4, hz - 14 * b)))
            wisp(c, x, y, (24 + Int(noise(i * 5 + 152) * 40)) * b, C(0xF08A9A, 0.55), s: b)
        }
        let sunX = Int(Double(c.w) * 0.32)
        d2Glow(c, sunX, hz, 24 * b, C(0xFFD890), 0.5)
        c.circle(sunX, hz, 7 * b, C(0xFFE4A0))
        d2Ridge(c, base: hz + b, amp: 6 * b, scale: Double(26 * b), seed: 53, C(0x2A2C4A))
        for i in 0..<(c.w / (12 * b)) where noise(i + 540) > 0.5 { c.rect(i * 12 * b, hz - b, max(1, b / 2), max(1, b / 2), C(0xFFD27A)) }
        // The bay.
        c.gradient(hz + b, pe, C(0x8A6A8A), C(0x1E2A4A), bands: 5)
        for k in 0..<((pe - hz) / (2 * b)) {
            let y = hz + 2 * b + k * 2 * b, w = (14 - k) * b
            if w > 0 { c.rect(sunX - w / 2, y, w, max(1, b / 2), C(0xFFD890, 0.5)) }
        }
        // The arts centre: a bronze shell with lit lettering cut through its front.
        let mx = Int(Double(c.w) * 0.16), mrx = (tall ? 54 : 38) * b, mry = (tall ? 30 : 17) * b
        for dy in 0...mry {
            let k = 1 - Double(dy * dy) / Double(mry * mry)
            let half = Int(Double(mrx) * k.squareRoot())
            let band = (dy / (3 * b)) % 2 == 0
            c.rect(mx - half, pe - dy, 2 * half, 1, band ? C(0x9A6A30) : C(0x84582A))
            c.rect(mx + half - max(1, half / 5), pe - dy, max(1, half / 5), 1, C(0x5A3C1E))
        }
        for k in 0..<10 {
            let u = mx - mrx * 2 / 3 + k * (mrx * 4 / 30)
            c.rect(u, pe - mry / 2, 2 * b, 3 * b, C(0xFFD27A, 0.85))
        }
        c.rect(mx - mrx * 3 / 4, pe - 4 * b, mrx * 3 / 2, 4 * b, C(0x3A4A6A)); c.rect(mx - mrx * 3 / 4, pe - 4 * b, mrx * 3 / 2, max(1, b / 2), C(0xFFD8A0, 0.7))
        // The pierhead: red brick, arched windows, a clock tower.
        let ph = Int(Double(c.w) * 0.88), p = D2Pen(c: c, x: ph, y: pe, s: b)
        let brick = C(0x9A3A2A), dk = C(0x6A2418)
        p.rect(-16, -16, 32, 16, brick); p.rect(-16, -16, 32, 1, C(0xC85A44))
        p.roof(-10, -21, half: 5, h: 5, dk); p.roof(10, -21, half: 5, h: 5, dk)
        p.rect(-4, -34, 8, 18, brick); p.rect(-4, -34, 1, 18, C(0xC85A44)); p.rect(3, -34, 1, 18, dk)
        p.roof(0, -40, half: 5, h: 6, dk); p.rect(0, -42, 1, 2, dk)
        p.circle(0, -30, 2, C(0xF2ECD8)); p.rect(0, -31, 1, 1, dk); p.rect(0, -30, 1, 1, dk)
        for u in stride(from: -13, through: 11, by: 4) { p.rect(u, -12, 2, 4, C(0xFFD27A, 0.8)); p.rect(u, -6, 2, 4, C(0x2A1A20)) }
        // The plaza's back rail.
        c.rect(0, pe, c.w, g - pe, C(0x7A7E88))
        for y in stride(from: pe + 3 * b, to: g, by: 3 * b) { c.rect(0, y, c.w, max(1, b / 2), C(0x6A6E78)) }
        c.rect(0, pe - 3 * b, c.w, max(1, b / 2), C(0xB8BCC4))
        for x in stride(from: 0, to: c.w, by: 8 * b) { c.rect(x, pe - 3 * b, max(1, b / 2), 3 * b, C(0x9AA0AA)) }
        c.rect(0, pe, c.w, b, C(0xA8ACB4))
        // The water tower and its pool.
        plassTower(c, g)
        // The paving, with the lift slab.
        c.ground(g, C(0x6E727C), edge: C(0xA8ACB4), speck: C(0x5E626A), seed: 57)
        for x in stride(from: 0, to: c.w, by: 10 * b) { c.rect(x, g + 1, max(1, b / 2), c.h - g - 1, C(0x5A5E68)) }
        for y in stride(from: g + 4 * b, to: c.h, by: 4 * b) { c.rect(0, y, c.w, max(1, b / 2), C(0x5A5E68)) }
        let sh = min(5 * b, c.h - g - 3)
        if sh > 1 {
            c.rect(f.fx - 8 * b, g + 2, 16 * b, sh, C(0x9EA4AE))
            c.rect(f.fx - 8 * b, g + 2, 16 * b, 1, C(0xD0D4DA)); c.rect(f.fx - 8 * b, g + 1 + sh, 16 * b, 1, C(0x3E424A))
            c.rect(f.fx - 8 * b, g + 2, 1, sh, C(0x3E424A)); c.rect(f.fx + 8 * b - 1, g + 2, 1, sh, C(0x3E424A))
        }
    }

    /// The silver water tower: a tall shaded cylinder with a rim, its pool and kerb at the foot.
    static func plassTower(_ c: PixelCanvas, _ g: Int) {
        let f = plassFrame(c, g), b = f.b, fx = f.fx, foot = g - 2 * b, top = foot - f.fh * b
        c.ellipse(fx, foot, 13 * b, 2 * b, C(0x9AA0A8)); c.ellipse(fx, foot, 11 * b, b + b / 2, C(0x3A4E78))
        let shades: [UInt32] = [0x5E6872, 0x8A949E, 0xBCC6D0, 0xE8F0F8, 0xD4DCE6, 0xAEB8C2, 0x8A949E, 0x66707A]
        let h = foot - top
        for r in 0..<h {
            let half = 6 * b - (b * r) / max(1, h)                       // a slight taper, wider at the foot
            let w = 2 * half
            for k in 0..<w {
                let idx = k * shades.count / max(1, w)
                c.px(fx - half + k, foot - r, C(shades[idx]))
            }
        }
        c.rect(fx - 5 * b, top - b, 10 * b, b, C(0xF4FAFF)); c.rect(fx - 4 * b, top - 2 * b, 8 * b, b, C(0xA8B4C0))
        c.rect(fx - 5 * b, top, 10 * b, h, C(0x8AC8F0, 0.12))
    }

    /// Water running down the tower and rippling in its pool, the bay glittering, a gull or two wheeling over.
    static func roaldDollPlassLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = plassFrame(c, g), b = f.b, foot = g - 2 * b, top = foot - f.fh * b
        for i in 0..<9 {
            let col = f.fx - 5 * b + Int(noise(i * 3 + 400) * Double(9 * b))
            let ph = d2Phase(t, 1.6 + noise(i * 3 + 401), offset: noise(i * 3 + 402) * 3)
            let y = top + Int(ph * Double(foot - top)), len = 5 * b
            c.rect(col, y, max(1, b / 2 + b % 2), min(len, foot - y), C(0xFFFFFF, 0.6))
        }
        let ring = d2Phase(t, 1.4)
        c.rect(f.fx - Int(ring * Double(11 * b)), foot - b / 2, max(1, b), max(1, b / 2), C(0xE8F4FF, 0.7 * (1 - ring)))
        c.rect(f.fx + Int(ring * Double(11 * b)), foot - b / 2, max(1, b), max(1, b / 2), C(0xE8F4FF, 0.7 * (1 - ring)))
        // The bay glittering.
        let rows = max(1, (f.pe - f.hz) / b)
        let centre = Int(Double(c.w) * 0.16) + (isTall(c) ? 54 : 38) * b, pier = Int(Double(c.w) * 0.88)
        for i in 0..<(c.w * rows / (60 * b) + 4) {
            let y = f.hz + 2 * b + Int(noise(i * 5 + 410) * Double(max(1, f.pe - f.hz - 3 * b)))
            let speed = 2 + noise(i * 5 + 411) * 4
            let span = Double(c.w + 20 * b)
            let x = Int((noise(i * 5 + 412) * span + t * speed * Double(b)).truncatingRemainder(dividingBy: span)) - 10 * b
            let a = 0.25 + 0.35 * (0.5 + 0.5 * sin(t * 2 + Double(i)))
            let len = (2 + Int(noise(i * 5 + 413) * 4)) * b
            if x < centre || (x + len > pier - 17 * b && x < pier + 17 * b) { continue }
            c.rect(x, y, len, max(1, b / 2), C(0xF8D8C0, a))
        }
        // Gulls.
        for k in 0..<2 {
            let gx = Int(d2Phase(t, 26 + Double(k) * 9, offset: Double(k) * 11) * Double(c.w + 40 * b)) - 20 * b
            let gy = (isTall(c) ? f.hz / 2 : 8 * b) + k * 6 * b + Int(sin(t * 0.7 + Double(k)) * Double(2 * b))
            let flap = sin(t * 6 + Double(k)) > 0 ? 1 : 0
            c.rect(gx - 3 * b, gy - flap * b, 2 * b, b, C(0x1A1A28)); c.rect(gx + b, gy - flap * b, 2 * b, b, C(0x1A1A28))
            c.rect(gx - b, gy, 2 * b, b, C(0x1A1A28))
        }
    }
}

// MARK: - UNIT HQ

extension Scenes {
    /// The arcade of the vault: the arch spacing, where the arches spring and the size of one unit.
    static func unitFrame(_ c: PixelCanvas, _ g: Int) -> (a: Int, sy: Int, r: Int, off: Int, b: Int) {
        let b = d2Big(c, g), a = 64 * b
        let r = (a - 8 * b) / 2, off = (c.w / 2 - a / 2) % a - a      // an opening centred on the middle
        return (a, g - (isTall(c) ? 40 : 34) * b, r, off, b)
    }

    /// What fills each opening of the arcade, centred on `ox`: 0 a desk of monitors, 1 the archive's shelves,
    /// 2 the big screen.
    static func unitOpenings(_ c: PixelCanvas, _ g: Int) -> [(ox: Int, kind: Int)] {
        let f = unitFrame(c, g)
        return stride(from: f.off, to: c.w + f.a, by: f.a).map { px in
            let ox = px + 8 * f.b + f.r
            let d = Int((Double(abs(ox - c.w / 2)) / Double(f.a)).rounded())
            return (ox, d == 0 ? 2 : (d % 2 == 1 ? 0 : 1))
        }
    }

    /// Every screen in the vault, as a box and whether it glows green (or blue).
    static func unitScreens(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int, green: Bool)] {
        let f = unitFrame(c, g), b = f.b
        var out: [(x: Int, y: Int, w: Int, h: Int, green: Bool)] = []
        for (i, o) in unitOpenings(c, g).enumerated() where o.kind == 0 {
            for k in 0..<3 { out.append((o.ox - 20 * b + k * 14 * b, g - 22 * b, 12 * b, 8 * b, (i + k) % 2 == 0)) }
            for k in 0..<2 { out.append((o.ox - 16 * b + k * 20 * b, f.sy - 8 * b, 12 * b, 9 * b, (i + k) % 2 == 1)) }
        }
        return out
    }

    /// UNIT HQ: the vault under the Tower, the black archive. An arcade of heavy stone arches on squat pillars, each
    /// opening lit by a caged lamp. One holds a desk of monitors with more screens on the wall above, the next the
    /// archive's shelves of crates and a glass case holding something that glows, and in the middle a big screen
    /// with UNIT on it over a map of the world. Flagstones underfoot. On the screen saver the vaulted ceiling with
    /// its ribs rises over the arcade.
    static func unitHQ(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = unitFrame(c, g), b = f.b, sy = f.sy, r = f.r
        c.rect(0, 0, c.w, g, C(0x24242A))
        for (row, y) in stride(from: 0, to: g, by: 4 * b).enumerated() {
            c.rect(0, y, c.w, max(1, b / 2), C(0x1A1A20))
            for x in stride(from: (row % 2) * 6 * b, to: c.w, by: 12 * b) { c.rect(x, y, max(1, b / 2), 4 * b, C(0x1A1A20)) }
        }
        if tall {
            // The vault's ribs, rising from the pillars and crossing overhead.
            for px in stride(from: f.off, to: c.w + f.a, by: f.a) {
                let cx = px + 4 * b
                let foot = sy - 3 * b
                for y in 0..<foot {
                    let k = Double(foot - y) / Double(max(1, foot))
                    let dx = Int(k * k * Double(f.a) * 0.5)
                    c.rect(cx - dx - b, y, 3 * b, 1, C(0x3A3A42)); c.rect(cx + dx - b, y, 3 * b, 1, C(0x3A3A42))
                    c.rect(cx - dx - b, y, b, 1, C(0x4E4E58)); c.rect(cx + dx - b, y, b, 1, C(0x4E4E58))
                }
            }
            c.rect(0, sy - r - 10 * b, c.w, 2 * b, C(0x1E1E24))           // a cable run
            for x in stride(from: 0, to: c.w, by: 30 * b) { c.rect(x, sy - r - 10 * b, b, 4 * b, C(0x2E2E36)) }
        }
        for o in unitOpenings(c, g) {
            let ox = o.ox
            // The deep space beyond the arch.
            for dy in 0...r {
                let half = Int((Double(r * r - dy * dy)).squareRoot())
                c.rect(ox - half, sy - dy, 2 * half, 1, C(0x101014))
            }
            c.rect(ox - r, sy, 2 * r, g - sy, C(0x101014))
            c.rect(ox - r, g - 3 * b, 2 * r, 3 * b, C(0x18181E))
            // A smaller arch further back.
            let r2 = r / 2
            for dy in 0...r2 {
                let half = Int((Double(r2 * r2 - dy * dy)).squareRoot())
                c.rect(ox - half, sy + 6 * b - dy, 2 * half, 1, C(0x16161C))
            }
            switch o.kind {
            case 2:
                c.rect(ox - 22 * b, sy - 16 * b, 44 * b, 28 * b, C(0x2A2A30))
                c.rect(ox - 20 * b, sy - 14 * b, 40 * b, 24 * b, C(0x0A1626))
                c.circle(ox, sy - 2 * b, 9 * b, C(0x123050)); c.circle(ox, sy - 2 * b, 8 * b, C(0x0A1626))
                for k in [-6, -3, 0, 3, 6] { c.rect(ox - 8 * b, sy - 2 * b + k * b, 16 * b, max(1, b / 2), C(0x1E4A70)) }
                c.rect(ox, sy - 10 * b, max(1, b / 2), 16 * b, C(0x1E4A70))
                c.ellipse(ox - 3 * b, sy - 4 * b, 3 * b, 2 * b, C(0x2E7A5A)); c.ellipse(ox + 4 * b, sy, 2 * b, 3 * b, C(0x2E7A5A))
                d2Text(c, cx: ox, y: sy - 12 * b, "UNIT", C(0xE8F0FF), s: b)
                c.rect(ox - 26 * b, g - 12 * b, 52 * b, 12 * b, C(0x30343A)); c.rect(ox - 26 * b, g - 12 * b, 52 * b, b, C(0x5A606A))
            case 1:
                for (k, y) in stride(from: g - 2 * b, to: sy - 6 * b, by: -10 * b).enumerated() {
                    c.rect(ox - 22 * b, y, 44 * b, b, C(0x3A3A40))
                    var x = ox - 21 * b, q = 0
                    while x < ox + 18 * b {
                        let cw = (5 + Int(noise(k * 13 + q * 3 + 700) * 6)) * b, ch = (4 + Int(noise(k * 13 + q * 3 + 701) * 4)) * b
                        let wood = noise(k * 13 + q * 3 + 702) > 0.3
                        c.rect(x, y - ch, cw, ch, wood ? C(0x5A4630) : C(0x3E4A44))
                        c.rect(x, y - ch, cw, max(1, b / 2), wood ? C(0x7A6040) : C(0x56645C))
                        c.rect(x + cw / 3, y - ch / 2 - b, cw / 3, max(1, b), C(0xC8C0A0, 0.6))      // a label
                        x += cw + b; q += 1
                    }
                }
                c.rect(ox + 12 * b, g - 16 * b, 8 * b, 14 * b, C(0x8AC8D0, 0.18))      // the glass case
                c.rect(ox + 12 * b, g - 16 * b, 8 * b, max(1, b / 2), C(0xC8F0F4, 0.6))
                c.rect(ox + 11 * b, g - 3 * b, 10 * b, 3 * b, C(0x2E2E34))
            default:
                c.rect(ox - 24 * b, g - 12 * b, 48 * b, 12 * b, C(0x30343A)); c.rect(ox - 24 * b, g - 12 * b, 48 * b, b, C(0x5A606A))
                for k in 0..<3 { c.rect(ox - 15 * b + k * 14 * b, g - 14 * b, 2 * b, 2 * b, C(0x26282C)) }
            }
            // The lamp hanging from the crown.
            let ly = sy - r + 10 * b
            c.rect(ox, sy - r, max(1, b / 2), 10 * b, C(0x3A3A40))
            D2Pen(c: c, x: ox, y: ly, s: b).trap(-3, 0, 7, 3, inset: 2, C(0x4A4A3A))
            d2Glow(c, ox, ly + 4 * b, 14 * b, C(0xF0D890), 0.3)
            c.rect(ox - b, ly + 3 * b, 3 * b, b, C(0xFFF0C0))
        }
        // The screens' frames and dark glass (what's on them moves).
        for s in unitScreens(c, g) {
            c.rect(s.x - b, s.y - b, s.w + 2 * b, s.h + 2 * b, C(0x3A3E44))
            c.rect(s.x, s.y, s.w, s.h, s.green ? C(0x06180E) : C(0x06101E))
        }
        // The pillars, the arch stones, the capitals.
        for px in stride(from: f.off, to: c.w + f.a, by: f.a) {
            c.rect(px, sy - 2 * b, 8 * b, g - sy + 2 * b, C(0x3A3A42))
            c.rect(px, sy - 2 * b, 2 * b, g - sy + 2 * b, C(0x56565F)); c.rect(px + 7 * b, sy - 2 * b, b, g - sy + 2 * b, C(0x2A2A30))
            c.rect(px - b, sy - 3 * b, 10 * b, 2 * b, C(0x5E5E68)); c.rect(px - b, g - 3 * b, 10 * b, 3 * b, C(0x4A4A52))
            let ox = px + 8 * b + r
            let n = r * 3
            for i in 0...n {
                let th = Double(i) / Double(n) * .pi
                let x = ox + Int(cos(th) * Double(r + b)), y = sy - Int(sin(th) * Double(r + b))
                let stone = (i * 9 / max(1, n)) % 2 == 0 ? C(0x4A4A52) : C(0x55555E)
                c.rect(x - b, y - b, 3 * b, 3 * b, stone)
            }
            c.rect(ox - 2 * b, sy - r - 3 * b, 4 * b, 4 * b, C(0x66666F))
        }
        c.ground(g, C(0x2E2E34), edge: C(0x5A5A62), speck: C(0x26262C), seed: 81)
        for x in stride(from: 0, to: c.w, by: 14 * b) { c.rect(x, g + 1, max(1, b / 2), c.h - g - 1, C(0x222228)) }
    }

    /// The monitors alive: radar sweeps, scrolling waveforms and readouts, bar graphs; a dot blinking on the big
    /// map and status lights winking along the desks.
    static func unitHQLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = unitFrame(c, g), b = f.b
        for (i, s) in unitScreens(c, g).enumerated() {
            let ink = s.green ? C(0x5AF08A) : C(0x6AB8FF)
            switch i % 4 {
            case 0:
                let cx = s.x + s.w / 2, cy = s.y + s.h / 2, rr = min(s.w, s.h) / 2 - b
                let a = t * 2.2 + Double(i)
                for k in 0..<rr { c.px(cx + Int(cos(a) * Double(k)), cy + Int(sin(a) * Double(k)), ink) }
                for k in 0..<rr { c.px(cx + Int(cos(a - 0.25) * Double(k)), cy + Int(sin(a - 0.25) * Double(k)), ink.alpha(0.4)) }
                if noise(Int(t * 2) + i) > 0.5 { c.rect(cx + rr / 2, cy - rr / 3, b, b, C(0xFF6A4A)) }
            case 1:
                for x in 0..<s.w {
                    let y = s.y + s.h / 2 + Int(sin(Double(x) * 0.7 / Double(b) - t * 6 + Double(i)) * Double(s.h / 3))
                    c.px(s.x + x, y, ink)
                }
            case 2:
                let scroll = Int(t * 3)
                for k in 0..<max(1, (s.h - b) / (2 * b)) {
                    let len = Int(noise((k + scroll) * 7 + i) * Double(s.w - 2 * b))
                    c.rect(s.x + b, s.y + b + k * 2 * b, max(b, len), max(1, b / 2 + b % 2), ink.alpha(0.8))
                }
            default:
                for k in 0..<(s.w / (2 * b)) {
                    let hh = Int((0.3 + 0.7 * (0.5 + 0.5 * sin(t * 3 + Double(k) * 1.3 + Double(i)))) * Double(s.h - 2 * b))
                    c.rect(s.x + k * 2 * b + b / 2, s.y + s.h - b - hh, b, hh, ink.alpha(0.85))
                }
            }
            c.rect(s.x, s.y + Int(d2Phase(t, 2.5, offset: Double(i)) * Double(s.h)), s.w, max(1, b / 2), C(0xFFFFFF, 0.12))
        }
        for o in unitOpenings(c, g) {
            if o.kind == 2 {
                if d2Phase(t, 1) < 0.6 { c.rect(o.ox + 3 * b, f.sy - 5 * b, 2 * b, 2 * b, C(0xFF4A3A)) }
                if d2Phase(t, 3) < 0.7 { c.rect(o.ox - 18 * b, f.sy + 7 * b, 3 * b, b, C(0x5AF08A)) }
            }
            if o.kind == 1 {
                c.circle(o.ox + 16 * b, g - 8 * b, 2 * b, C(0xB88AFF, 0.4 + 0.3 * sin(t * 1.7)))
                c.rect(o.ox + 16 * b, g - 8 * b, max(1, b / 2), max(1, b / 2), C(0xF0E0FF))
            }
            if o.kind != 1 {
                for k in 0..<8 where noise(k * 11 + o.ox + Int(t * 2.5)) > 0.45 {
                    let col = [C(0xFF5A4A), C(0x5AF08A), C(0xFFD24A), C(0x6AB8FF)][k % 4]
                    c.rect(o.ox - 22 * b + k * 6 * b, g - 9 * b, b, b, col)
                }
            }
        }
    }
}

// MARK: - Paternoster Row

extension Scenes {
    /// The houses' foot (at the kerb), the gaslamps' columns, and one unit.
    static func paternosterFrame(_ c: PixelCanvas, _ g: Int) -> (base: Int, lamps: [Int], b: Int) {
        let b = d2Big(c, g)
        return (g - 3 * b, [0.1, 0.37, 0.64, 0.91].map { Int(Double(c.w) * $0) }, b)
    }

    /// Paternoster Row on a winter night: the great dome of the cathedral looming over the rooftops against a
    /// midnight sky, a terrace of Victorian houses in brick and stone with snow on their slates and sills, warm
    /// shop windows under painted signboards, chimneys with their pots, gaslamps along the kerb and the cobbles white
    /// with snow. On the screen saver the dome rises whole, drum, lantern and cross.
    static func paternosterRow(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = paternosterFrame(c, g), b = f.b, base = f.base
        c.gradient(0, g, C(0x0C1226), C(0x34405E), bands: 7)
        c.stars(0, g / 2, density: 140, seed: 61)
        let roofY = base - 36 * b
        // The cathedral dome.
        let dx = Int(Double(c.w) * 0.47), dk = C(0x2C3450), dl = C(0x46506E), rib = C(0x232A42), snow = C(0xDCE4F0)
        let ds = tall ? 2 : 1
        let dome = D2Pen(c: c, x: dx, y: roofY - (tall ? 2 : 8) * b * ds, s: b * ds)
        let top = tall ? -18 : 0
        dome.ellipse(0, top, 18, 16, dk); dome.rect(-19, top, 38, 2, dk)
        if tall {
            // The drum, a colonnade under a gallery, hiding the dome's lower half.
            dome.rect(-22, -16, 44, 18, rib)
            for u in stride(from: -21, through: 19, by: 3) { dome.rect(u, -14, 1, 12, dk) }
            dome.rect(-24, -17, 48, 2, dk); dome.rect(-24, -17, 48, 1, snow.alpha(0.7))
            dome.rect(-24, -3, 48, 2, dk)
        }
        for u in [-12, -6, 0, 6, 12] {                                   // the ribs, curving with the dome
            for v in 0..<16 {
                let k = 1 - Double(v * v) / 256
                dome.rect(Int(Double(u) * k.squareRoot()), top - v, 1, 1, rib)
            }
        }
        for v in 2..<14 { let k = 1 - Double(v * v) / 256; dome.rect(-Int(15 * k.squareRoot()), top - v, 2, 1, dl) }
        dome.rect(-5, top - 16, 10, 1, snow.alpha(0.8)); dome.rect(-9, top - 15, 18, 1, snow.alpha(0.5))
        dome.rect(-3, top - 24, 6, 8, dk); dome.rect(-2, top - 26, 4, 2, dl); dome.rect(0, top - 30, 1, 4, C(0xC8A860))
        dome.rect(-1, top - 29, 3, 1, C(0xC8A860))
        for k in [-2, 0, 2] { dome.rect(k, top - 22, 1, 2, C(0xF0C870, 0.7)) }
        // The terrace.
        let bricks: [UInt32] = [0x5A3A30, 0x4E3A36, 0x6A5E54, 0x48302A, 0x5E4A3E]
        var x = -6 * b, i = 0
        while x < c.w {
            let w = [40, 48, 36, 52, 44][i % 5] * b, wall = C(bricks[i % bricks.count])
            let h = (34 + (i % 3) * 2) * b, ty = base - h
            c.rect(x, ty, w, h, wall)
            c.rect(x, ty, b, h, C(0x000000, 0.25)); c.rect(x + w - b, ty, b, h, C(0xFFFFFF, 0.05))
            // Cornices between the floors, with snow on top.
            for k in [12, 24] { c.rect(x, base - k * b, w, b, C(0x8A8070)); c.rect(x, base - k * b - max(1, b / 2), w, max(1, b / 2), snow.alpha(0.8)) }
            // Upper sash windows.
            for (fl, wy) in [base - 22 * b, base - 33 * b + (i % 3) * b].enumerated() {
                for u in stride(from: x + 4 * b, to: x + w - 7 * b, by: 10 * b) {
                    let lit = noise(i * 23 + fl * 7 + u) > 0.55
                    c.rect(u, wy, 6 * b, 8 * b, lit ? C(0xF0C070) : C(0x182032))
                    c.rect(u, wy + 4 * b, 6 * b, max(1, b / 2), C(0x2A2420)); c.rect(u + 3 * b, wy, max(1, b / 2), 8 * b, C(0x2A2420))
                    c.rect(u - b / 2, wy + 8 * b, 7 * b, b, snow)
                }
            }
            // The shopfront: a lit window, a door, a signboard.
            c.rect(x + 3 * b, base - 11 * b, w - 6 * b, 3 * b, i % 2 == 0 ? C(0x1E3A2A) : C(0x3A1E24))
            for k in stride(from: x + 6 * b, to: x + w - 8 * b, by: 3 * b) { c.rect(k, base - 10 * b, 2 * b, max(1, b / 2), C(0xD8B060)) }
            c.rect(x + 4 * b, base - 7 * b, w - 18 * b, 7 * b, C(0xF2C474))
            for k in stride(from: x + 4 * b, to: x + w - 14 * b, by: 5 * b) { c.rect(k, base - 7 * b, max(1, b / 2), 7 * b, C(0x3A2A20)) }
            c.rect(x + 4 * b, base - 4 * b, w - 18 * b, max(1, b / 2), C(0x3A2A20))
            c.rect(x + w - 11 * b, base - 9 * b, 6 * b, 9 * b, i == 2 ? C(0x1E3A6A) : C(0x2A1E1A))
            c.rect(x + w - 7 * b, base - 5 * b, max(1, b / 2), max(1, b / 2), C(0xD8B060))
            // The roof: slates under snow, a chimney stack with pots.
            D2Pen(c: c, x: x, y: ty, s: b).trap(0, -6, w / b, 6, inset: 4, C(0x262A38))
            D2Pen(c: c, x: x, y: ty, s: b).trap(0, -6, w / b, 3, inset: 4, snow)
            let cx = x + w * 2 / 3
            c.rect(cx, ty - 12 * b, 8 * b, 8 * b, wall); c.rect(cx - b, ty - 12 * b, 10 * b, b, C(0x8A8070))
            c.rect(cx - b, ty - 13 * b, 10 * b, b, snow)
            c.rect(cx + b, ty - 15 * b, 2 * b, 2 * b, C(0x8A5A3A)); c.rect(cx + 5 * b, ty - 15 * b, 2 * b, 2 * b, C(0x8A5A3A))
            x += w; i += 1
        }
        // The kerb and the snowy cobbles.
        c.rect(0, base, c.w, g - base, C(0x9AA2B0)); c.rect(0, base, c.w, b, C(0xE8EEF6))
        c.ground(g, C(0xC4CCD8), edge: C(0xF0F4FA), speck: C(0x9AA2B0), seed: 67)
        let fr = c.h - g
        if fr > 4 { c.rect(0, g + fr / 3, c.w, max(1, b / 2), C(0x8A92A0)); c.rect(0, g + fr * 2 / 3, c.w, max(1, b / 2), C(0x8A92A0)) }
        // The gaslamps.
        for lx in f.lamps {
            c.rect(lx, g - 26 * b, max(1, b), 26 * b, C(0x15181E)); c.rect(lx - b, g - 3 * b, 3 * b, 3 * b, C(0x15181E))
            c.rect(lx - 3 * b, g - 26 * b, 7 * b, max(1, b / 2), C(0x15181E))
            c.rect(lx - 2 * b, g - 32 * b, 5 * b, 6 * b, C(0xFFD890)); c.rect(lx - 2 * b, g - 32 * b, max(1, b / 2), 6 * b, C(0x15181E))
            c.rect(lx + 2 * b, g - 32 * b, max(1, b / 2), 6 * b, C(0x15181E))
            c.rect(lx - 3 * b, g - 33 * b, 7 * b, b, C(0x15181E)); c.rect(lx - b, g - 34 * b, 3 * b, b, C(0x15181E))
            c.rect(lx - 3 * b, g - 34 * b, 7 * b, max(1, b / 2), snow)
            d2Glow(c, lx, g - 29 * b, 16 * b, C(0xFFD890), 0.28)
            c.ellipse(lx, g + 2, 14 * b, 2 * b, C(0xFFD890, 0.16))
        }
    }

    /// Snow falling and drifting, and the gas flames flickering in their lamps.
    static func paternosterRowLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = paternosterFrame(c, g), b = f.b
        for (k, lx) in f.lamps.enumerated() {
            let fl = 0.5 + 0.5 * noise(Int(t * 9) + k * 17)
            c.circle(lx, g - 29 * b, 6 * b, C(0xFFE0A0, 0.1 + 0.15 * fl))
            c.rect(lx - b / 2, g - 30 * b + Int(fl * Double(b)), max(1, b), 2 * b, C(0xFFFFF0, 0.6 + 0.4 * fl))
        }
        let n = c.w * g / (isTall(c) ? 260 : 200)
        let fall = Double(g + 8)
        for i in 0..<n {
            let near = noise(i * 7 + 900) > 0.8
            let speed = (near ? 14 : 7 + noise(i * 7 + 901) * 4) * Double(b)
            let y = Int((noise(i * 7 + 902) * fall + t * speed).truncatingRemainder(dividingBy: fall)) - 4
            let sway = sin(t * (0.8 + noise(i * 7 + 903)) + Double(i)) * Double(3 * b)
            let span = Double(c.w)
            var xd = (noise(i * 7 + 904) * span + sway + t * 2 * Double(b)).truncatingRemainder(dividingBy: span)
            if xd < 0 { xd += span }
            let sz = near ? 2 * b : b
            c.rect(Int(xd), y, sz, sz, C(0xF4F8FF, near ? 0.95 : 0.7))
        }
    }
}
