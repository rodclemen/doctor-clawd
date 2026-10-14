import Foundation

let scenes2: [Location: Place] = [
    .helicarrier: Place(name: "S.H.E.L.L. Skycarrier", panel: 0x16181D, still: Scenes.helicarrier, moving: Scenes.helicarrierMoving),
    .xMansion: Place(name: "Professor Why's School", panel: 0x14231A, still: Scenes.xMansion, moving: Scenes.xMansionMoving),
    .hellsKitchen: Place(name: "Hell's Kitchen", panel: 0x1A1418, still: Scenes.hellsKitchen, moving: Scenes.hellsKitchenMoving),
    .vormir: Place(name: "Vormyr", panel: 0x161A22, still: Scenes.vormir, moving: Scenes.vormirMoving),
    .quantumRealm: Place(name: "Quantum Rim", panel: 0x1E1028, still: Scenes.quantumRealm, moving: Scenes.quantumRealmMoving),
    .latveria: Place(name: "Gloomveria", panel: 0x1A1E1A, still: Scenes.latveria, moving: Scenes.latveriaMoving),
    .hydraBase: Place(name: "Hydrax Base", panel: 0x1A1414, still: Scenes.hydraBase, moving: Scenes.hydraBaseMoving),
    .dailyBugle: Place(name: "Daily Bungle", panel: 0x1A1E2A, still: Scenes.dailyBugle, moving: Scenes.dailyBugleMoving),
]

/// 5×7 capitals for the signs in these places (I and the apostrophe are narrower), drawn as pixel letters.
private let scenes2Glyphs: [Character: [String]] = [
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "'": ["#", "#", ".", ".", ".", ".", "."],
    " ": ["...", "...", "...", "...", "...", "...", "..."],
]

extension Scenes {
    // MARK: - Lettering shared by these places

    /// Width in pixels of `text` drawn by `scenes2Text` at `s` pixels per dot.
    static func scenes2TextWidth(_ text: String, s: Int = 1) -> Int {
        let cols = text.reduce(0) { $0 + (scenes2Glyphs[$1]?.first?.count ?? 3) + 1 }
        return max(0, cols - 1) * s
    }

    /// Pixel lettering: `text` in 5×7 capitals, one dot between letters, each dot `s`×`s` pixels, top-left at (x, y).
    static func scenes2Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, s: Int = 1) {
        var cx = x
        for ch in text {
            let rows = scenes2Glyphs[ch] ?? scenes2Glyphs[" "]!
            for (r, row) in rows.enumerated() {
                for (k, dot) in row.enumerated() where dot == "#" { c.rect(cx + k * s, y + r * s, s, s, col) }
            }
            cx += (rows[0].count + 1) * s
        }
    }

    /// The same lettering stacked one letter under the next (a hotel's upright sign).
    static func scenes2TextDown(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, s: Int = 1) {
        for (i, ch) in text.enumerated() {
            let w = scenes2Glyphs[ch]?.first?.count ?? 3
            scenes2Text(c, x + (5 - w) * s / 2, y + i * 9 * s, String(ch), col, s: s)
        }
    }

    /// A solid triangle with its apex at (cx, top), `half` pixels either side at its base `h` rows down.
    static func scenes2Peak(_ c: PixelCanvas, _ cx: Int, _ top: Int, half: Int, h: Int, _ col: Px) {
        guard h > 0 else { return }
        for k in 0..<h {
            let hw = half * (k + 1) / h
            c.rect(cx - hw, top + k, hw * 2 + 1, 1, col)
        }
    }

    /// Where something sliding across a canvas `w` wide is, `t` seconds in: it loops every `period` seconds, entering
    /// at the left (or the right when `leftward`) with `margin` pixels to spare either side.
    static func scenes2Slide(_ t: Double, period: Double, phase: Double = 0, w: Int, margin: Int, leftward: Bool = false) -> Int {
        let p = (t / period + phase).truncatingRemainder(dividingBy: 1)
        let x = -Double(margin) + p * Double(w + margin * 2)
        return leftward ? w - Int(x) : Int(x)
    }

    // MARK: - S.H.E.L.L. Helicarrier

    /// S.H.E.L.L. Helicarrier, out on the flight deck high above the clouds: a bright sky over a sea of cloud tops,
    /// a lift rotor turning in its housing at the deck's edge, a Quinjet parked on its gear and the grey bridge
    /// tower with its slanted windows, radar mast and the S.H.E.L.L. crab; the deck is painted with runway lines.
    static func helicarrier(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x2A60B2), C(0xC6E3F6), bands: 7)
        if isTall(c) { helicarrierHigh(c, g) }
        // The cloud sea far below, its tops just showing beyond the deck.
        c.rect(0, g - 8 * s, c.w, 8 * s, C(0xDDEAF5))
        for (i, x) in stride(from: -20, to: c.w + 40, by: 34 * s).enumerated() {
            cloud(c, x + Int(noise(i * 3 + 40) * 14) * s, g - 9 * s, (3 + Int(noise(i * 3 + 41) * 3)) * s, seed: i + 20)
        }
        let r = helicarrierRotorSpot(c, g)
        c.ellipse(r.x, r.y + s, r.rx + 4 * s, r.ry + 3 * s, C(0x3A4049))                 // the housing
        c.ellipse(r.x, r.y, r.rx + 3 * s, r.ry + 2 * s, C(0x8A939F))                     // its lit rim
        c.ellipse(r.x, r.y, r.rx + 2 * s, r.ry + s, C(0x5E6672))
        c.ellipse(r.x, r.y, r.rx, r.ry, C(0x2E343C))                                     // the inner wall, far side
        c.ellipse(r.x, r.y + s, r.rx - s, r.ry - s, C(0xBCD6EC))                // the sky far below, through the fan
        for k in 0..<5 {
            let u = r.x - r.rx / 2 + Int(noise(k + 70) * Double(r.rx)), v = r.y + Int((noise(k + 71) - 0.3) * Double(r.ry))
            c.rect(u, v, (6 + k * 3) * s, s, C(0xF2F7FB, 0.8))
        }
        for k in 0..<3 {                                                                  // the struts holding the hub
            let a = Double(k) * 2 * .pi / 3 + 0.5
            c.glowLine(Double(r.x), Double(r.y), Double(r.x) + cos(a) * Double(r.rx - s), Double(r.y) + sin(a) * Double(r.ry - s),
                       core: C(0x4A515B), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        }
        c.ellipse(r.x, r.y, 4 * s, 2 * s, C(0x3A4049)); c.ellipse(r.x, r.y - s, 3 * s, max(1, s), C(0x6E7884))   // the hub
        // The far side of the deck, with landing lights along its edge.
        c.rect(0, g - 4 * s, c.w, 4 * s, C(0x515862)); c.rect(0, g - 4 * s, c.w, s, C(0x8A939F))
        for x in stride(from: 6, to: c.w, by: 22 * s) { c.rect(x, g - 4 * s, s, s, C(0xFFC83A)) }
        helicarrierQuinjet(c, c.w / 7, g - 2 * s, s)
        helicarrierTower(c, c.w * 3 / 4, g - 3 * s, s)
        // The deck: dark non-slip plating, yellow taxi lines and the white runway dashes.
        c.ground(g, C(0x454B54), edge: C(0x6E7682), speck: C(0x3A4048), seed: 30)
        let f = c.h - g
        c.rect(0, g + 2, c.w, 1, C(0xE8B830, 0.75))
        for x in stride(from: 4, to: c.w, by: 26) { c.rect(x, g + f / 2 + 1, 13, max(1, f / 8), C(0xEEF2F6, 0.75)) }
        for x in stride(from: 0, to: c.w, by: 64) { c.rect(x, g + 3, 1, max(1, f - 4), C(0x353A42)) }   // plate seams
    }

    /// The lift rotor's housing at the deck's edge: centre and radii.
    static func helicarrierRotorSpot(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, rx: Int, ry: Int) {
        let s = unit(g)
        return (c.w * 2 / 5, g - 11 * s, 40 * s, 10 * s)
    }

    /// A Quinjet parked on the deck, nose to the left, its gear standing on row `b`.
    static func helicarrierQuinjet(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let body = C(0x2E333C), mid = C(0x454C57), lit = C(0x66707E), dark = C(0x1C2026)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, h * s, col) }
        // the far wing, swept back and canted down
        for k in 0..<8 { r(16 + k, -8 + k / 3, 12, 1, dark) }
        // the fuselage: a long wedge from the pointed nose to the blunt tail
        r(-10, -8, 4, 2, body); r(-6, -10, 6, 5, body); r(0, -11, 34, 6, body)
        r(-13, -7, 3, 1, body)
        r(0, -11, 34, 1, lit); r(-6, -10, 6, 1, lit)
        r(2, -7, 32, 2, dark)                                         // the belly in shadow
        r(-6, -12, 9, 2, C(0x7FB8DE)); r(-4, -12, 3, 1, C(0xD8F0FF))  // the canopy
        r(10, -9, 14, 1, mid)                                         // the side door's seam
        // the near wing, and the twin tails canted outwards
        for k in 0..<10 { r(13 + k, -6 + k / 3, 13, 1, k == 0 ? lit : mid) }
        for k in 0..<7 { r(27 + k / 2, -12 - k, 5, 1, k == 6 ? lit : mid) }
        for k in 0..<5 { r(23 + k / 2, -12 - k, 3, 1, body) }
        r(33, -10, 2, 3, C(0x5A9ADA, 0.8))                            // the engine glow, idling
        // the gear
        r(-3, -5, 1, 4, dark); r(25, -5, 1, 4, dark); r(-4, -1, 3, 1, C(0x15181D)); r(24, -1, 3, 1, C(0x15181D))
    }

    /// The bridge tower standing on row `b`, its left edge at `x`.
    static func helicarrierTower(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let hull = C(0x5E6672), lit = C(0x808A97), dark = C(0x3C424B), glass = C(0x1A2C42), glint = C(0x86BCE6)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, h * s, col) }
        // the base block, with a hangar hatch and rows of portholes
        r(0, -20, 48, 20, hull); r(0, -20, 48, 1, lit); r(0, -20, 2, 20, lit); r(46, -20, 2, 20, dark)
        r(28, -12, 14, 12, dark); for k in 0..<4 { r(29, -11 + k * 3, 12, 1, C(0x4A5059)) }
        for k in 0..<5 { r(5 + k * 4, -16, 2, 1, C(0xE8EEF4, 0.8)) }
        // the S.H.E.L.L. crab in its white ring
        c.circle(x + 13 * s, b - 8 * s, 4 * s, C(0xE6EAEE)); c.circle(x + 13 * s, b - 8 * s, 3 * s, C(0x22262E))
        for (v, row) in ["#...#", ".#.#.", ".###.", "#####", "#.#.#"].enumerated() {
            for (u, ch) in row.enumerated() where ch == "#" { r(11 + u, -10 + v, 1, 1, C(0xE6EAEE)) }
        }
        // the upper decks, stepping back
        r(5, -30, 39, 10, hull); r(5, -30, 39, 1, lit); r(5, -30, 2, 10, lit); r(42, -30, 2, 10, dark)
        for k in 0..<6 { r(9 + k * 5, -26, 3, 2, glass) }
        // the bridge: a slanted band of glass wrapping the front, wider at the top
        for k in 0..<6 { r(3 - k / 3, -37 + k, 42 + k / 3 * 2, 1, k < 1 ? lit : glass) }
        r(8, -36, 3, 1, glint); r(20, -35, 5, 1, glint.alpha(0.6)); r(34, -36, 2, 1, glint)
        r(9, -42, 28, 5, hull); r(9, -42, 28, 1, lit); r(35, -42, 2, 5, dark)
        // the mast: radar dish, crossbar and whip aerials
        r(22, -58, 2, 16, dark); r(16, -52, 14, 1, dark); r(16, -54, 1, 2, dark); r(29, -54, 1, 2, dark)
        r(13, -47, 8, 2, lit); r(12, -48, 2, 1, lit); r(20, -46, 1, 1, dark)
        r(28, -50, 5, 3, hull); r(28, -50, 5, 1, lit)
        r(23, -63, 1, 5, dark); r(23, -59, 1, 1, C(0x8A2A2A))
    }

    /// Full screen: a high sun, streaks of cirrus, cumulus heaped at several heights and a second Helicarrier on
    /// station far off, its four rotors under it.
    static func helicarrierHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.circle(c.w / 8, g / 7, 14 * s, C(0xFFFFFF, 0.12)); c.circle(c.w / 8, g / 7, 9 * s, C(0xFFFFFF, 0.25))
        c.circle(c.w / 8, g / 7, 5 * s, C(0xFFFBEA))
        for (i, (fx, fy, l)) in [(0.4, 0.08, 60), (0.75, 0.14, 80), (0.22, 0.26, 50), (0.9, 0.34, 40)].enumerated() {
            wisp(c, Int(Double(c.w) * fx), Int(Double(g) * fy), l * s, C(0xFFFFFF, 0.35 + Double(i % 2) * 0.1), s: s)
        }
        for (i, (fx, fy, r)) in [(0.58, 0.38, 9), (0.12, 0.5, 7), (0.86, 0.58, 8), (0.36, 0.66, 6), (0.68, 0.76, 5),
                                 (0.05, 0.8, 5), (0.94, 0.86, 4)].enumerated() {
            cloud(c, Int(Double(c.w) * fx), Int(Double(g) * fy), r * s, seed: i + 3)
        }
        // the cloud sea heaped up towards the horizon
        for i in 0..<(c.w / (24 * s) + 2) {
            let x = i * 24 * s + Int(noise(i + 150) * 12) * s, y = g - g / 7 + Int(noise(i + 151) * Double(g / 12))
            cloud(c, x, y, (5 + Int(noise(i + 152) * 5)) * s, seed: i + 150, top: C(0xEEF4FA), base: C(0xD2E2F0))
        }
        c.rect(0, g - g / 9, c.w, g / 9, C(0xD8E7F3))
        // the other Helicarrier, small with distance, hanging over the clouds
        let hx = c.w * 3 / 10, hy = Int(Double(g) * 0.56), col = C(0x7D93AE), dk = C(0x6A7F99), k = 2 * s
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ p: Px) { c.rect(hx + u * k, hy + v * k, w * k, h * k, p) }
        r(-28, 0, 56, 3, col); r(-24, 3, 48, 3, dk); r(-30, 0, 3, 2, col); r(10, -5, 5, 5, col); r(12, -8, 1, 3, dk)
        for u in [-22, -10, 8, 20] { r(u - 3, 5, 7, 1, dk); r(u - 5, 6, 11, 1, C(0x8FA4BC, 0.6)) }
    }

    /// Cloud wisps sliding past, the lift rotor spinning in its housing and the mast's beacon blinking.
    static func helicarrierMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let wisps = isTall(c) ? 6 : 3
        for i in 0..<wisps {
            let x = scenes2Slide(t, period: 70 + Double(i) * 17, phase: noise(i * 7 + 90), w: c.w, margin: 60 * s, leftward: true)
            let y = isTall(c) ? Int(Double(g) * (0.15 + 0.13 * Double(i))) : 6 + i * 10
            wisp(c, x, y, (36 + i * 8) * s, C(0xFFFFFF, 0.3), s: s)
        }
        // the rotor: four blades turning fast, with a faint blur disc
        let r = helicarrierRotorSpot(c, g), clip = g - 4 * s
        for y in (r.y - r.ry + 2 * s)..<min(clip, r.y + r.ry + 1) {
            let dy = Double(y - r.y) / Double(r.ry), half = Int(Double(r.rx - 2 * s) * max(0, 1 - dy * dy).squareRoot())
            c.rect(r.x - half, y, half * 2, 1, C(0x2E343C, 0.12))
        }
        for k in 0..<4 {
            let a = t * 6 + Double(k) * .pi / 2
            for j in stride(from: 3 * s, to: r.rx - 2 * s, by: 1) {
                let x = r.x + Int(cos(a) * Double(j)), y = r.y + Int(sin(a) * Double(j) * Double(r.ry) / Double(r.rx))
                if y < clip { c.rect(x, y, s, max(1, s), C(0x2A3038, 0.85)) }
                let a2 = a - 0.18                                            // a faint trail behind each blade
                let x2 = r.x + Int(cos(a2) * Double(j)), y2 = r.y + Int(sin(a2) * Double(j) * Double(r.ry) / Double(r.rx))
                if y2 < clip { c.rect(x2, y2, s, max(1, s), C(0x2A3038, 0.3)) }
            }
        }
        c.ellipse(r.x, r.y, 4 * s, 2 * s, C(0x3A4049)); c.ellipse(r.x, r.y - s, 3 * s, max(1, s), C(0x6E7884))
        // the beacon at the top of the mast
        if (t * 1.2).truncatingRemainder(dividingBy: 1) < 0.3 {
            let bx = c.w * 3 / 4 + 23 * s, by = g - 3 * s - 64 * s
            c.rect(bx, by, s, s, C(0xFF3A3A)); c.circle(bx, by, 2 * s, C(0xFF3A3A, 0.3))
        }
    }

    // MARK: - Xavier's School

    /// Xavier's School for Gifted Youngsters, the mansion in Westchester on a fine afternoon: the grey stone house
    /// with its slate gables, chimneys and copper-domed tower, a fountain before the door, hedges and old oaks on the
    /// lawn, and the wrought-iron gates with the X in their crest.
    static func xMansion(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x4C88CC), C(0xCFE6F2), bands: 6)
        if isTall(c) { xMansionHigh(c, g) }
        for (i, x) in stride(from: 30, to: c.w, by: 110).enumerated() {
            cloud(c, x + Int(noise(i + 60) * 30), 8 + Int(noise(i + 61) * 8), 3, seed: i + 60)
        }
        // the woods behind the grounds
        c.dunes(base: g - 14 * s, amp: 3, freq: 0.09, phase: 1, bottom: g, C(0x3E6A3A), shade: C(0x527E46))
        c.dunes(base: g - 9 * s, amp: 2, freq: 0.13, phase: 2.5, bottom: g, C(0x335C30))
        let mx = c.w * 3 / 5
        xMansionHouse(c, mx, g - 2 * s, s)
        for (x, r) in [(mx - 128 * s, 13), (mx + 124 * s, 15), (c.w - 22 * s, 11), (6 * s, 12)] where x > -20 && x < c.w + 20 {
            xMansionTree(c, x, g - s, r * s, seed: x)
        }
        xMansionGate(c, c.w / 9, g, s)
        // clipped hedges along the drive, open in front of the door
        for x in stride(from: 0, to: c.w, by: 1) where abs(x - mx) > 16 * s {
            let top = g - 3 * s - (x / (3 * s) % 2 == 0 ? 0 : s)
            c.rect(x, top, 1, g - top, x % 7 == 0 ? C(0x3A6A30) : C(0x2E5A28))
        }
        // the fountain before the door
        c.ellipse(mx, g - s, 13 * s, 2 * s, C(0xB4AEA2)); c.ellipse(mx, g - 2 * s, 11 * s, max(1, s), C(0x6FA6CC))
        c.rect(mx - s, g - 7 * s, 2 * s, 5 * s, C(0xB4AEA2)); c.ellipse(mx, g - 7 * s, 4 * s, max(1, s), C(0xC8C2B6))
        // the lawn, striped by the mower, and the gravel drive
        c.ground(g, C(0x4E8C3C), edge: C(0x6CAA52), speck: C(0x3F7632), seed: 31)
        for x in stride(from: 0, to: c.w, by: 40) { c.rect(x, g + 1, 20, c.h - g - 1, C(0x5E9C48, 0.35)) }
    }

    /// The mansion, centred on `x` and standing on row `b`.
    static func xMansionHouse(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let stone = C(0x9E988C), lit = C(0xBAB4A6), shade = C(0x7A756C), slate = C(0x3B4350), slateLit = C(0x58626F)
        let win = C(0x26303C), glow = C(0xF0D89A), trim = C(0xDAD4C6)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, h * s, col) }
        func peak(_ u: Int, _ v: Int, _ half: Int, _ h: Int, _ col: Px) { scenes2Peak(c, x + u * s, b + v * s, half: half * s, h: h * s, col) }
        func windows(_ u0: Int, _ u1: Int, _ v: Int, step: Int = 8) {
            for u in stride(from: u0, through: u1, by: step) {
                r(u - 1, v - 1, 5, 7, trim); r(u, v, 3, 5, win); r(u, v + 2, 3, 1, trim)
                if noise(u * 3 + v) > 0.7 { r(u, v, 3, 2, glow) } else { r(u, v, 1, 1, C(0x9CC4E0)) }
            }
        }
        // chimneys behind the roofs
        for u in [-84, -46, 44, 82] { r(u, -42, 5, 12, shade); r(u - 1, -43, 7, 2, stone) }
        // the wings: two storeys under slate roofs, each with a pair of gables
        for side in [-1, 1] {
            let u0 = side < 0 ? -96 : 32
            r(u0, -26, 64, 26, stone); r(u0, -26, 64, 1, lit)
            r(u0 - 2, -32, 68, 6, slate); r(u0 - 2, -32, 68, 1, slateLit)
            for gu in [u0 + 14, u0 + 48] {
                peak(gu, -42, 9, 11, slate); peak(gu, -39, 6, 8, stone); r(gu - 1, -36, 3, 4, win)
            }
            windows(u0 + 4, u0 + 58, -22); windows(u0 + 4, u0 + 58, -12)
            r(u0, -17, 64, 1, shade)                              // the string course between the floors
        }
        // the central block, a storey taller
        r(-32, -36, 64, 36, stone); r(-32, -36, 64, 1, lit); r(30, -36, 2, 36, shade)
        r(-34, -40, 68, 4, slate); r(-34, -40, 68, 1, slateLit)
        windows(-28, -14, -32, step: 7); windows(16, 28, -32, step: 6)
        windows(-28, -14, -22, step: 7); windows(16, 28, -22, step: 6)
        windows(-28, -14, -12, step: 7); windows(16, 28, -12, step: 6)
        // the tower over the door, with its copper dome and lantern
        r(-10, -52, 20, 52, lit); r(-10, -52, 2, 52, trim); r(8, -52, 2, 52, stone)
        c.ellipse(x, b - 52 * s, 10 * s, 9 * s, C(0x5E9A86)); c.ellipse(x - 3 * s, b - 55 * s, 4 * s, 4 * s, C(0x86BEA8))
        r(-11, -52, 22, 2, shade)
        r(-2, -64, 4, 4, trim); r(-1, -67, 2, 3, C(0x5E9A86)); r(0, -70, 1, 3, shade)
        c.circle(x, b - 44 * s, 3 * s, trim); c.circle(x, b - 44 * s, 2 * s, win)
        r(-6, -36, 4, 8, win); r(2, -36, 4, 8, win); r(-6, -36, 4, 1, trim); r(2, -36, 4, 1, trim)
        r(-6, -24, 12, 1, trim)
        // the arched front door and its steps
        r(-5, -12, 10, 12, C(0x4A3022)); c.ellipse(x, b - 12 * s, 5 * s, 3 * s, C(0x4A3022)); r(0, -12, 1, 12, C(0x2E1E14))
        r(-7, -13, 14, 1, trim)
        r(-12, -2, 24, 2, trim); r(-10, -3, 20, 1, lit)
    }

    /// An old oak: a trunk under a heap of leafy clumps, lit from the upper left.
    static func xMansionTree(_ c: PixelCanvas, _ x: Int, _ b: Int, _ r: Int, seed: Int) {
        c.rect(x - r / 6, b - r * 2, max(2, r / 3), r * 2, C(0x4A3826))
        for k in 0..<7 {
            let dx = Int((noise(seed + k * 3) - 0.5) * Double(r) * 1.6), dy = Int((noise(seed + k * 3 + 1) - 0.5) * Double(r))
            c.circle(x + dx, b - r * 2 - r / 3 + dy, r * 2 / 3, C(0x2C5226))
        }
        for k in 0..<5 {
            let dx = Int((noise(seed + k * 5 + 40) - 0.6) * Double(r)), dy = Int((noise(seed + k * 5 + 41) - 0.7) * Double(r))
            c.circle(x + dx, b - r * 2 - r / 3 + dy, r / 2, C(0x3C6A30))
        }
        for k in 0..<3 {
            let dx = Int((noise(seed + k * 7 + 80) - 0.8) * Double(r)), dy = Int((noise(seed + k * 7 + 81) - 0.9) * Double(r))
            c.circle(x + dx, b - r * 2 - r / 3 + dy, max(1, r / 4), C(0x5A8A40))
        }
    }

    /// The wrought-iron gates on their stone piers, the X in a ring at the top of the arch.
    static func xMansionGate(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let iron = C(0x1E2226), stone = C(0xA8A296), cap = C(0xC4BEB0)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, g + v * s, w * s, h * s, col) }
        for u in [-22, 17] { r(u, -26, 5, 26, stone); r(u - 1, -28, 7, 2, cap); r(u + 1, -30, 3, 2, cap); r(u + 4, -26, 1, 26, C(0x847E72)) }
        for u in stride(from: -16, through: 15, by: 3) {
            let arch = Int(6 - Double(u * u) / 42)
            r(u, -20 - arch, 1, 20 + arch, iron); r(u, -21 - arch, 1, 1, C(0x8A8070))
        }
        r(-17, -8, 34, 1, iron); r(-17, -17, 34, 1, iron)
        quantumRing(c, x, g - 30 * s, 5 * s, 5 * s, iron); quantumRing(c, x, g - 30 * s, 5 * s - 1, 5 * s - 1, iron)
        for k in -3...3 { r(k, -30 + k, 1, 1, iron); r(k, -30 - k, 1, 1, iron) }
        r(-1, -25, 2, 2, iron)
    }

    /// Full screen: summer cumulus, the wooded hills of Westchester rolling away, and the lake beyond the lawn.
    static func xMansionHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for (i, (fx, fy, r)) in [(0.2, 0.12, 8), (0.62, 0.08, 10), (0.88, 0.22, 7), (0.4, 0.3, 6), (0.08, 0.38, 5)].enumerated() {
            cloud(c, Int(Double(c.w) * fx), Int(Double(g) * fy), r * s, seed: i + 70)
        }
        c.dunes(base: g - g / 4, amp: Double(g) / 30, freq: 0.012, phase: 0.6, bottom: g, C(0x8AAEC0), shade: C(0x9ABCCC))
        c.dunes(base: g - g / 6, amp: Double(g) / 40, freq: 0.02, phase: 2, bottom: g, C(0x5E8A62), shade: C(0x6E9A6E))
        c.rect(0, g - g / 9, c.w, g / 9, C(0x5A8A58))
        c.ellipse(c.w / 5, g - g / 10, c.w / 6, g / 40 + 2, C(0x7AAAD0)); c.ellipse(c.w / 5, g - g / 10 - 1, c.w / 7, g / 60 + 1, C(0xA8CCE6))
        for i in 0..<(c.w / 10) {
            let x = Int(noise(i * 5 + 300) * Double(c.w)), y = g - g / 6 + Int(noise(i * 5 + 301) * Double(g / 14))
            c.circle(x, y, (2 + Int(noise(i * 5 + 302) * 3)) * s, i % 3 == 0 ? C(0x4A7A48) : C(0x3E6A3E))
        }
    }

    /// The fountain playing, and (full screen) the X-Jet passing over now and then.
    static func xMansionMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), mx = c.w * 3 / 5
        for i in 0..<10 {
            let p = (t * 0.9 + Double(i) / 10).truncatingRemainder(dividingBy: 1)
            let side = i % 2 == 0 ? -1.0 : 1.0, spread = Double(2 + i % 3)
            let x = Double(mx) + side * p * spread * 3 * Double(s), y = Double(g - 8 * s) - (sin(p * .pi) * 5 - p * 6) * Double(s)
            c.rect(Int(x), Int(y), s, s, C(0xDDF0FF, 0.75 * (1 - p * 0.5)))
        }
        c.rect(mx, g - 11 * s, s, 3 * s, C(0xDDF0FF, 0.6))
        if isTall(c) {
            let p = (t / 45).truncatingRemainder(dividingBy: 1)
            if p < 0.4 { xMansionJet(c, c.w + 40 * s - Int(p / 0.4 * Double(c.w + 80 * s)), g / 5, s) }
        }
    }

    /// The X-Jet, nose to the left: the long black Blackbird with its delta wing and twin tails.
    static func xMansionJet(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let body = C(0x1E2028), lit = C(0x4A505C)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
        r(-14, 0, 6, 1, body); r(-8, -1, 30, 3, body); r(-8, -1, 30, 1, lit); r(-6, -2, 6, 1, C(0x6A8AA8))
        for k in 0..<6 { r(4 + k, 2 + k / 2, 16 - k, 1, body) }
        for k in 0..<5 { r(16 + k / 2, -2 - k, 4, 1, body) }
        r(22, -1, 2, 3, C(0xFFB050, 0.8)); r(24, 0, 3, 1, C(0xFFB050, 0.4))
    }

    // MARK: - Hell's Kitchen

    /// Hell's Kitchen, a rooftop at night in the rain: the city's glow turning the low sky red, the Empire State far
    /// off and a church steeple among the tenements, a brick wall with zigzag fire escapes, a hotel's upright neon
    /// sign and a bar's sign across the street, and a wooden water tower on its stilts.
    static func hellsKitchen(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x0E0710), C(0x8E2C38), bands: 7)
        if isTall(c) { hellsKitchenHigh(c, g) }
        // the Empire State, far off, its mast lit red
        let ex = c.w * 9 / 20
        func es(_ u: Int, _ v: Int, _ w: Int, _ h: Int) { c.rect(ex + u * s, g + v * s, w * s, h * s, C(0x4A1A2A)) }
        es(-10, -38, 20, 38); es(-7, -46, 14, 8); es(-4, -52, 8, 6); es(-2, -56, 4, 4); es(0, -64, 1, 8)
        c.rect(ex, g - 64 * s, s, s, C(0xFF4A4A))
        for v in stride(from: -50, to: -4, by: 3) { for u in stride(from: -8, to: 9, by: 3) where noise(u * 7 + v * 13) > 0.6 && v > -46 || (v <= -46 && abs(u) < 4 && noise(u + v) > 0.5) {
            c.rect(ex + u * s, g + v * s, s, s, C(0xE8B060, 0.5))
        } }
        // the far skyline, then nearer tenements
        hellsKitchenRow(c, g, top: 20 * s, depth: 26 * s, col: C(0x3E1626), lamp: C(0xE8A050, 0.4), seed: 1, s: s)
        hellsKitchenSteeple(c, c.w * 3 / 5 + 16 * s, g, s)
        hellsKitchenRow(c, g, top: 10 * s, depth: 16 * s, col: C(0x1E0C16), lamp: C(0xF0B060, 0.65), seed: 2, s: s)
        // the bar across the street, its sign on the roof
        let bx = c.w * 7 / 10
        c.rect(bx - 30 * s, g - 22 * s, 60 * s, 22 * s, C(0x241018))
        for u in stride(from: -26, to: 26, by: 8) { for v in [-16, -8] { c.rect(bx + u * s, g + v * s, 3 * s, 4 * s, noise(u + v * 3) > 0.4 ? C(0xF0B060, 0.7) : C(0x120810)) } }
        c.rect(bx - 16 * s, g - 33 * s, 32 * s, 11 * s, C(0x120A10)); c.rect(bx - 16 * s, g - 33 * s, 32 * s, s, C(0x2A1A22))
        for u in [-12, 12] { c.rect(bx + u * s, g - 22 * s, s, 2 * s, C(0x120A10)) }
        scenes2Text(c, bx - scenes2TextWidth("JOSY'S", s: s) / 2, g - 31 * s, "JOSY'S", C(0x5A2A30), s: s)
        // the brick wall on the left, with its fire escapes
        hellsKitchenWall(c, g, s)
        // the water tower on our roof
        hellsKitchenTower(c, c.w - 56 * s, g - 3 * s, s)
        // the parapet and the wet tar roof
        c.rect(0, g - 3 * s, c.w, 3 * s, C(0x3A2026)); c.rect(0, g - 3 * s, c.w, s, C(0x6A3A40))
        for x in stride(from: 0, to: c.w, by: 9 * s) { c.rect(x, g - 2 * s, s, 2 * s, C(0x2A161C)) }
        c.ground(g, C(0x221C22), edge: C(0x3A2E36), speck: C(0x2E262E), seed: 32)
        for (i, x) in stride(from: 40, to: c.w, by: 130).enumerated() {
            c.ellipse(x + Int(noise(i + 5) * 40), g + (c.h - g) / 2, 14 * s, max(1, (c.h - g) / 5), C(0x3A2A36))
        }
    }

    /// A row of rooftops `top`…`top + depth` pixels above the ground, with lit windows.
    static func hellsKitchenRow(_ c: PixelCanvas, _ g: Int, top: Int, depth: Int, col: Px, lamp: Px, seed: Int, s: Int) {
        var x = -Int(noise(seed) * 20)
        var i = 0
        while x < c.w {
            let bw = (10 + Int(noise(seed * 50 + i) * 18)) * s
            let h = top + Int(noise(seed * 50 + i + 100) * Double(depth))
            c.rect(x, g - h, bw - s, h, col)
            if noise(seed * 50 + i + 200) > 0.6 { c.rect(x + bw / 3, g - h - 3 * s, 2 * s, 3 * s, col) }   // a stair hut
            for v in stride(from: g - h + 3 * s, to: g - 3 * s, by: 4 * s) {
                for u in stride(from: x + 2 * s, to: x + bw - 3 * s, by: 4 * s) where noise(u * 3 + v * 7 + seed) > 0.72 {
                    c.rect(u, v, s, 2 * s, lamp)
                }
            }
            x += bw; i += 1
        }
    }

    /// A church's steeple among the tenements, with its cross.
    static func hellsKitchenSteeple(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let col = C(0x281019)
        c.rect(x - 5 * s, g - 34 * s, 10 * s, 34 * s, col)
        scenes2Peak(c, x, g - 50 * s, half: 6 * s, h: 16 * s, col)
        c.rect(x, g - 56 * s, s, 6 * s, col); c.rect(x - 2 * s, g - 54 * s, 5 * s, s, col)
        c.ellipse(x, g - 28 * s, 2 * s, 3 * s, C(0xC85A3A, 0.6))
    }

    /// The near tenement's brick end wall, its windows and fire escapes zigzagging down.
    static func hellsKitchenWall(_ c: PixelCanvas, _ g: Int, _ s: Int) {
        let ww = 96 * s, brick = C(0x4A2224), mortar = C(0x3A1A1E), iron = C(0x140A0E)
        c.rect(0, 0, ww, g, brick)
        for y in stride(from: 0, to: g, by: 3 * s) {
            c.rect(0, y, ww, max(1, s / 2), mortar)
            for x in stride(from: (y / (3 * s)) % 2 == 0 ? 0 : 4 * s, to: ww, by: 8 * s) { c.rect(x, y, max(1, s / 2), 3 * s, mortar) }
        }
        c.rect(ww - 2 * s, 0, 2 * s, g, C(0x2A1216))
        c.rect(ww - 4 * s, 0, 2 * s, g, C(0x5A2C2C))
        for (col, u) in [(0, 10), (1, 44), (2, 76)] {
            for v in stride(from: g - 14 * s, to: -14 * s, by: -15 * s) {
                let lit = noise(col * 31 + v) > 0.55
                c.rect(u * s, v, 12 * s, 9 * s, C(0x2A1418)); c.rect(u * s + s, v + s, 10 * s, 7 * s, lit ? C(0xE8A84A) : C(0x1A0C12))
                if lit { c.rect(u * s + s, v + s, 4 * s, 7 * s, C(0xC8803A)) }                      // a curtain
                c.rect(u * s, v + 9 * s, 12 * s, s, C(0x6A3A36))                                    // the sill
            }
        }
        // the fire escapes: landings under the windows, ladders between them
        for (n, u) in [(0, 7), (1, 73)] {
            var v = g - 4 * s
            var k = 0
            while v > -10 * s {
                c.rect(u * s, v, 18 * s, s, iron)
                for x in stride(from: u * s, to: (u + 18) * s, by: 2 * s) { c.rect(x, v - 4 * s, max(1, s / 2), 4 * s, iron) }
                c.rect(u * s, v - 4 * s, 18 * s, max(1, s / 2), iron)
                let fromL = (k + n) % 2 == 0
                for j in 0..<(11 * s) {                       // the stair up to the next landing
                    let x = fromL ? (u + 2) * s + j * 14 / 11 : (u + 16) * s - j * 14 / 11
                    c.rect(x, v - j * 15 / 11, max(1, s), max(1, s), iron)
                }
                v -= 15 * s; k += 1
            }
        }
    }

    /// The rooftop water tower: a wooden tank with iron hoops under a conical cap, on steel legs.
    static func hellsKitchenTower(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let wood = C(0x4A2C22), lit = C(0x6A4030), hoop = C(0x1E1014), leg = C(0x1A0E12)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, h * s, col) }
        for u in [-11, -4, 3, 10] { r(u, -20, 1, 20, leg) }
        r(-12, -10, 24, 1, leg); for k in 0..<9 { r(-11 + k * 2 + 1, -19 + k, 1, 1, leg); r(10 - k * 2, -19 + k, 1, 1, leg) }
        r(-13, -21, 26, 2, leg)
        r(-12, -40, 24, 19, wood); r(-12, -40, 3, 19, lit)
        for u in stride(from: -9, to: 12, by: 3) { r(u, -40, 1, 19, C(0x3A2018)) }
        for v in [-37, -31, -25] { r(-12, v, 24, 1, hoop) }
        scenes2Peak(c, x, b - 49 * s, half: 14 * s, h: 9 * s, C(0x2A161A)); r(0, -51, 1, 2, leg)
        r(-12, -36, 1, 13, C(0x7A4A36, 0.6))
    }

    /// Full screen: low cloud lit red from below, more of the skyline marching off to the horizon.
    static func hellsKitchenHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<8 {
            let y = Int(Double(g) * (0.08 + 0.07 * Double(i))), x = Int(noise(i + 400) * Double(c.w))
            c.ellipse(x, y, (60 + Int(noise(i + 401) * 60)) * s, 4 * s, C(0x6A2232, 0.18 + 0.03 * Double(i)))
        }
        hellsKitchenRow(c, g, top: g / 4, depth: g / 5, col: C(0x3A1626), lamp: C(0xE8A050, 0.3), seed: 7, s: s)
    }

    /// Rain slanting down, the neon signs buzzing on (and the hotel's flickering), their glow in the puddles.
    static func hellsKitchenMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        // the hotel's upright sign on the brick wall, flickering now and then
        let hx = 96 * s + 2 * s, hy = 6 * s
        let flick = noise(Int(t * 12)) < 0.08 ? 0.25 : 1.0
        let red = C(0xFF3A5A, flick), halo = C(0xFF3A5A, 0.12 * flick)
        c.rect(hx - 2 * s, hy - 2 * s, 13 * s, 52 * s, halo)
        c.rect(hx, hy, 9 * s, 48 * s, C(0x1A0A10)); c.rect(hx, hy, 9 * s, s, red); c.rect(hx, hy + 47 * s, 9 * s, s, red)
        scenes2TextDown(c, hx + 2 * s, hy + 2 * s, "HOTEL", red, s: s)
        // the bar's sign, steady
        let bx = c.w * 7 / 10
        c.rect(bx - 18 * s, g - 35 * s, 36 * s, 15 * s, C(0x40E8FF, 0.08))
        scenes2Text(c, bx - scenes2TextWidth("JOSY'S", s: s) / 2, g - 31 * s, "JOSY'S", C(0x7AF0FF), s: s)
        // their reflections on the wet roof
        c.rect(hx, g + 2 * s, 9 * s, max(1, (c.h - g) / 2), C(0xFF3A5A, 0.18 * flick))
        c.rect(bx - 14 * s, g + 2 * s, 28 * s, max(1, (c.h - g) / 3), C(0x40E8FF, 0.12))
        // the rain
        let n = c.w * c.h / 150
        for i in 0..<n {
            let speed = 140.0 + noise(i * 3 + 7) * 60
            let y = (noise(i * 3 + 8) * Double(c.h) + t * speed).truncatingRemainder(dividingBy: Double(c.h + 10)) - 5
            let x = Int(noise(i * 3 + 9) * Double(c.w + 40)) - Int(y / 4)
            c.rect(x, Int(y), max(1, s / 2), 3 * s, C(0xC8B8D0, 0.28))
        }
        for i in 0..<(c.w / 25) where noise(Int(t * 10) * 31 + i) > 0.5 {
            let x = Int(noise(Int(t * 10) * 17 + i) * Double(c.w)), y = g + 1 + Int(noise(Int(t * 10) * 13 + i) * Double(c.h - g - 1))
            c.rect(x - s, y, 3 * s, max(1, s / 2), C(0xD8C8E0, 0.4))
        }
    }

    // MARK: - Vormir

    /// Vormir, the summit where the Soul Stone waits: a deep violet night with a huge ringed planet hanging overhead,
    /// black rock spires standing out of a sea of cloud, and the two carved monoliths at the cliff's edge with the
    /// altar stone between them.
    static func vormir(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x080A18), C(0x3A3E5C), bands: 7)
        c.stars(0, g * 2 / 3, density: 70, seed: 40)
        let tall = isTall(c)
        let p = tall ? (x: c.w * 7 / 10, y: g * 3 / 10, r: g / 4) : (x: c.w * 3 / 4, y: 19, r: 22)
        vormirPlanet(c, p.x, p.y, p.r)
        if tall { vormirHigh(c, g) }
        // far spires standing out of the cloud sea
        for i in 0..<(c.w / (44 * s) + 2) {
            let x = i * 44 * s + Int(noise(i + 500) * 24) * s - 10, h = (12 + Int(noise(i + 502) * 26)) * s
            vormirSpire(c, x, g - 12 * s, h * (8 + Int(noise(i + 501) * 6)) / 10, h, C(0x1E2232), edge: C(0x3E4462), seed: i)
        }
        // the cloud sea
        c.rect(0, g - 12 * s, c.w, 12 * s, C(0x5C6488))
        c.dunes(base: g - 12 * s, amp: Double(2 * s), freq: 0.09, phase: 0.4, bottom: g, C(0x6A7296), shade: C(0x8A92B2))
        c.dunes(base: g - 7 * s, amp: Double(s), freq: 0.15, phase: 1.4, bottom: g, C(0x545C80))
        // nearer spires on either side
        vormirSpire(c, 24 * s, g, 40 * s, 52 * s, C(0x111320), edge: C(0x333852), seed: 7)
        vormirSpire(c, 62 * s, g, 22 * s, 26 * s, C(0x161828), edge: C(0x383D58), seed: 10)
        vormirSpire(c, c.w - 28 * s, g, 44 * s, 60 * s, C(0x111320), edge: C(0x333852), seed: 8)
        vormirSpire(c, c.w - 70 * s, g, 24 * s, 32 * s, C(0x161828), edge: C(0x383D58), seed: 9)
        // the monoliths and the altar between them
        let mx = c.w * 3 / 5
        for (k, u) in [-26, 18].enumerated() { vormirMonolith(c, mx + u * s, g, s, seed: k) }
        c.rect(mx - 8 * s, g - 4 * s, 16 * s, 4 * s, C(0x24263A)); c.rect(mx - 8 * s, g - 4 * s, 16 * s, s, C(0x4A4E6A))
        c.rect(mx - 6 * s, g - 3 * s, 12 * s, s, C(0x1A1C2C))
        // the summit's black rock
        c.ground(g, C(0x1C1E2A), edge: C(0x484C66), speck: C(0x2A2C3C), seed: 33)
        for i in 0..<(c.w / 40) {
            let x = Int(noise(i * 3 + 600) * Double(c.w)), y = g + 2 + Int(noise(i * 3 + 601) * Double(max(1, c.h - g - 4)))
            c.rect(x, y, (3 + Int(noise(i * 3 + 602) * 5)) * s, s, C(0x30334A))
        }
    }

    /// The giant ringed planet: banded and shaded, the ring passing behind it at the top and in front below.
    static func vormirPlanet(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int) {
        let rx = r * 9 / 5, ry = max(3, r / 4)
        func ring(front: Bool) {
            for dy in -ry...ry {
                guard front == (dy >= 0) else { continue }
                let k = 1 - Double(dy * dy) / Double(ry * ry)
                let outer = Int(Double(rx) * k.squareRoot()), inner = Int(Double(rx * 3 / 4) * max(0, 1 - Double(dy * dy) / Double((ry * 3 / 4) * (ry * 3 / 4))).squareRoot())
                for xx in (x - outer)...(x + outer) where abs(xx - x) >= inner || abs(dy) > ry * 3 / 4 {
                    let d = Double(abs(xx - x)) / Double(max(1, rx))
                    c.px(xx, y + dy - (xx - x) / 7, C(d > 0.88 ? 0xA8B0CC : 0xC6CCE0, 0.55))
                }
            }
        }
        ring(front: false)
        c.circle(x, y, r + 2, C(0x8A94B8, 0.12))
        for dy in -r...r {
            let half = Int((Double(r * r - dy * dy)).squareRoot())
            for dx in -half...half {
                let band = ((dy + r) * 7 / max(1, r)) % 3
                var col = band == 0 ? C(0x8A92B4) : (band == 1 ? C(0x9AA2C2) : C(0x7C84A8))
                let shade = Double(dx + dy) / Double(r)                      // lit from the upper left
                if shade > 0.55 { col = lerp(col, C(0x2A2E48), min(1, (shade - 0.55) * 1.4)) }
                c.px(x + dx, y + dy, col)
            }
        }
        ring(front: true)
    }

    /// A pillar of black rock, `w` wide at its foot on row `b` and `h` tall: steep sides, a broken top, cracks
    /// running down it and its left edge catching the light.
    static func vormirSpire(_ c: PixelCanvas, _ x: Int, _ b: Int, _ w: Int, _ h: Int, _ col: Px, edge: Px, seed: Int) {
        guard h > 0, w > 1 else { return }
        let half = w / 2, crack = lerp(col, C(0x000000), 0.35)
        for dx in -half...half {
            let u = Double(abs(dx)) / Double(max(1, half))
            let jag = Int(noise(seed * 97 + (dx + half) / 3) * Double(h) / 5)
            let slope = dx < 0 ? 0.55 + noise(seed * 5) * 0.3 : 0.75 + noise(seed * 5 + 1) * 0.25
            let top = b - h + Int(pow(u, 1.4) * Double(h) * slope) + jag
            guard top < b else { continue }
            let shade = dx == -half || (dx == -half + 1 && w > 8) ? edge : ((dx + half + seed) % 5 == 0 ? crack : col)
            c.rect(x + dx, top, 1, b - top, shade)
            c.px(x + dx, top, edge)
        }
    }

    /// One of the two carved monoliths at the cliff's edge.
    static func vormirMonolith(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int, seed: Int) {
        let h = (52 + seed * 5) * s, w = 11 * s
        for k in 0..<h {
            let taper = k < 6 * s ? (6 * s - k) / 2 : 0
            c.rect(x + taper, g - h + k, w - taper * 2, 1, C(0x0E0F18))
            c.px(x + taper, g - h + k, C(0x5A6080)); c.px(x + w - taper - 1, g - h + k, C(0x262838))
        }
        for v in stride(from: 10, to: 46, by: 9) { c.rect(x + 2 * s, g - h + v * s, w - 4 * s, s, C(0x1E2030)) }   // carved bands
        c.rect(x + 3 * s, g - h + 14 * s, 3 * s, 4 * s, C(0x1A1C2A))
    }

    /// Full screen: the spires of the far peaks, thin high mist and a dusting of brighter stars.
    static func vormirHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<5 {
            wisp(c, Int(noise(i + 700) * Double(c.w)), Int(Double(g) * (0.35 + Double(i) * 0.08)), (80 + i * 20) * s, C(0x6A7096, 0.25), s: s)
        }
        for i in 0..<(c.w / (70 * s) + 2) {
            let x = i * 70 * s + Int(noise(i + 720) * 40) * s - 20, h = 30 * s + Int(noise(i + 722) * Double(g / 4))
            vormirSpire(c, x, g - 10 * s, h * (7 + Int(noise(i + 721) * 5)) / 10, h, C(0x2A2E44), edge: C(0x464C6C), seed: i + 40)
        }
    }

    /// Mist drifting over the cloud sea and across the summit, and the Soul Stone's glimmer far below the altar.
    static func vormirMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        for i in 0..<(isTall(c) ? 7 : 4) {
            let x = scenes2Slide(t, period: 50 + Double(i) * 13, phase: noise(i + 800), w: c.w, margin: 90 * s)
            let y = g - (6 + i * 5) * s - (isTall(c) ? Int(noise(i + 801) * Double(g / 3)) : 0)
            c.ellipse(x, y, (60 + i * 10) * s, 2 * s, C(0x9AA2C4, 0.14))
            c.ellipse(x + 20 * s, y + s, (34 + i * 6) * s, s, C(0xB8C0DA, 0.12))
        }
        let mx = c.w * 3 / 5, pulse = 0.5 + 0.5 * sin(t * 1.6)
        c.circle(mx - 4 * s, g - 9 * s, 4 * s, C(0xFF9A3A, 0.10 * pulse))
        c.rect(mx - 4 * s, g - 9 * s, s, s, C(0xFFC060, 0.5 + 0.4 * pulse))
    }

    // MARK: - Quantum Realm

    /// The Quantum Realm, the strange world beneath the subatomic: a violet void ringed with fractal halos,
    /// iridescent bubbles drifting in clusters, and bulbous organic towers with glowing tips growing from a dark,
    /// dotted floor.
    static func quantumRealm(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x0C0420), C(0x6E1E7C), bands: 8)
        // fractal halos
        let fx = c.w * 2 / 5, fy = isTall(c) ? g / 3 : g / 3
        for k in stride(from: 6, to: max(c.w, g) / 2, by: 7 * s) {
            let col = (k / (7 * s)) % 3 == 0 ? C(0x5AE0FF, 0.07) : ((k / (7 * s)) % 3 == 1 ? C(0xFF6AD8, 0.06) : C(0xFFB84A, 0.05))
            quantumRing(c, fx, fy, k, k * 2 / 3, col)
        }
        if isTall(c) { quantumHigh(c, g) }
        // far towers, then near ones
        for i in 0..<(c.w / 40 + 1) {
            quantumTower(c, i * 40 + Int(noise(i + 900) * 20), g - 2 * s, (16 + Int(noise(i + 901) * 22)) * s, s, far: true, seed: i)
        }
        for (i, f) in [0.06, 0.3, 0.83, 0.95].enumerated() {
            quantumTower(c, Int(Double(c.w) * f), g, (34 + Int(noise(i + 950) * 22)) * s, s, far: false, seed: i + 30)
        }
        // bubbles
        for (i, (fx, fy, r)) in [(0.18, 0.3, 9), (0.24, 0.55, 4), (0.52, 0.22, 6), (0.58, 0.6, 3), (0.7, 0.28, 11),
                                 (0.78, 0.66, 4), (0.42, 0.68, 3), (0.9, 0.2, 5)].enumerated() {
            let y = Int(Double(g) * fy)
            quantumBubble(c, Int(Double(c.w) * fx), y, r * s, seed: i)
            for k in 0..<3 { quantumBubble(c, Int(Double(c.w) * fx) + Int((noise(i * 5 + k) - 0.5) * Double(r * 4 * s)),
                                           y + Int((noise(i * 5 + k + 2) - 0.5) * Double(r * 3 * s)), max(1, r * s / 4 + k), seed: i * 3 + k) }
        }
        c.ground(g, C(0x220E36), edge: C(0xA25AE8), speck: C(0x5AE0F0, 0.2), seed: 34)
        for x in stride(from: 0, to: c.w, by: 4) {                                   // a sheen on the floor
            if noise(x + 990) > 0.6 { c.rect(x, g + 1, 3, 1, C(0xFF6AD8, 0.25)) }
        }
    }

    /// An ellipse outline (one pixel thick).
    static func quantumRing(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rx: Int, _ ry: Int, _ col: Px) {
        guard rx > 0, ry > 0 else { return }
        let n = max(24, (rx + ry) * 3)
        var last = (Int.min, Int.min)
        for i in 0..<n {
            let a = Double(i) / Double(n) * 2 * .pi
            let p = (x + Int(cos(a) * Double(rx)), y + Int(sin(a) * Double(ry)))
            if p != last { c.px(p.0, p.1, col); last = p }
        }
    }

    /// A drifting bubble: a faint tinted fill, a bright rim and a glint.
    static func quantumBubble(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, seed: Int) {
        let tint = [C(0x5AE0FF), C(0xFF6AD8), C(0xFFC85A), C(0x8AFFB8)][seed % 4]
        c.circle(x, y, r, tint.alpha(0.12))
        quantumRing(c, x, y, r, r, tint.alpha(0.75))
        if r >= 3 {
            c.px(x - r / 2, y - r / 2, C(0xFFFFFF, 0.9)); c.px(x - r / 2 + 1, y - r / 2, C(0xFFFFFF, 0.5))
            quantumRing(c, x, y, r * 2 / 3, r * 2 / 3, tint.alpha(0.2))
        }
    }

    /// Where a tower `h` tall standing at `x` on row `b` leans its cap to, and the radii of that cap.
    static func quantumTowerCap(_ x: Int, _ b: Int, _ h: Int, _ s: Int, seed: Int) -> (x: Int, y: Int, rx: Int, ry: Int) {
        (x + Int(sin(Double(seed) * 1.7) * Double(h) * 0.15), b - h, h * 3 / 10 + Int(noise(seed + 960) * 4) * s, max(2 * s, h / 7))
    }

    /// An organic tower: a curving translucent stalk with pods along it, under a wide jellyfish cap trailing glowing
    /// tendrils, a bud of light on its crown.
    static func quantumTower(_ c: PixelCanvas, _ x: Int, _ b: Int, _ h: Int, _ s: Int, far: Bool, seed: Int) {
        let body = far ? C(0x3E1A5C) : C(0x2A1242), rim = far ? C(0x8A4AB8) : C(0xD070F4), inner = far ? C(0x52266E) : C(0x3E1A5A)
        let bud = [C(0xFFB84A), C(0x5AE0FF), C(0xFF6AD8)][seed % 3]
        let cap = quantumTowerCap(x, b, h, s, seed: seed), base = max(2 * s, h / 9)
        func centre(_ f: Double) -> Int { x + Int(Double(cap.x - x) * f * f + sin(f * 5 + Double(seed)) * 2 * Double(s)) }
        for y in cap.y..<b {
            let f = Double(b - y) / Double(h), half = Int(Double(base) * (1 - 0.55 * f)), cx = centre(f)
            c.rect(cx - half, y, half * 2 + 1, 1, body)
            c.px(cx - half, y, rim.alpha(0.8)); if half > 2 { c.px(cx - half + 2, y, inner) }
        }
        for k in 0..<3 {                                            // pods budding off the stalk
            let f = 0.22 + 0.2 * Double(k), side = (k + seed) % 2 == 0 ? -1 : 1, r = max(2 * s, h / 13)
            let px = centre(f) + side * (Int(Double(base) * (1 - 0.55 * f)) + r - s), py = b - Int(f * Double(h))
            c.circle(px, py, r, body); quantumRing(c, px, py, r, r, rim.alpha(0.7)); c.rect(px - s / 2, py - s / 2, max(1, s), max(1, s), bud.alpha(0.8))
        }
        // the cap: a dome, lit along its crown, and tendrils hanging from its rim
        for u in stride(from: -cap.rx + 2 * s, to: cap.rx - s, by: 3 * s) {
            let len = cap.ry / 2 + Int(noise(seed * 31 + u) * Double(cap.ry + 3 * s))
            c.rect(cap.x + u, cap.y, max(1, s), len, rim.alpha(0.45)); c.rect(cap.x + u, cap.y + len, max(1, s), max(1, s), bud.alpha(0.9))
        }
        for dy in -cap.ry...0 {
            let k = 1 - Double(dy * dy) / Double(cap.ry * cap.ry), half = Int(Double(cap.rx) * k.squareRoot())
            c.rect(cap.x - half, cap.y + dy, half * 2 + 1, 1, dy == 0 ? rim.alpha(0.7) : body)
            c.px(cap.x - half, cap.y + dy, rim); c.px(cap.x + half, cap.y + dy, rim.alpha(0.6))
        }
        quantumRing(c, cap.x, cap.y, cap.rx * 2 / 3, cap.ry * 2 / 3, inner)
        for dx in -cap.rx / 2...cap.rx / 3 { c.px(cap.x + dx, cap.y - cap.ry + abs(dx) * cap.ry / max(1, cap.rx) / 2 + s, rim.alpha(0.7)) }
        c.circle(cap.x, cap.y - cap.ry - s, (far ? 1 : 2) * s, bud.alpha(far ? 0.7 : 0.95))
        c.circle(cap.x, cap.y - cap.ry - s, (far ? 3 : 5) * s, bud.alpha(0.15))
    }

    /// Full screen: more bubbles, big and small, hanging in the upper void, and a far cluster of cells.
    static func quantumHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<14 {
            let x = Int(noise(i * 3 + 1100) * Double(c.w)), y = Int(noise(i * 3 + 1101) * Double(g / 2))
            quantumBubble(c, x, y, (3 + Int(noise(i * 3 + 1102) * 14)) * s, seed: i)
        }
        for i in 0..<3 {                                                    // giant towers, hazy with distance
            quantumTower(c, c.w * (2 + i * 3) / 10 + Int(noise(i + 1150) * 30) * s, g - 6 * s,
                         g / 3 + Int(noise(i + 1151) * Double(g / 4)), s, far: true, seed: i + 60)
        }
        let cx = c.w * 4 / 5, cy = g / 5
        for k in 0..<9 {
            let a = Double(k) * 0.7, d = Double(k) * 4
            c.circle(cx + Int(cos(a) * d) * s, cy + Int(sin(a) * d) * s, (6 - k / 2) * s, C(0xFF6AD8, 0.12))
        }
    }

    /// Particles swirling round a few slow vortices, and the towers' buds pulsing.
    static func quantumRealmMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let centres = [(c.w / 5, g / 2), (c.w / 2, g / 3), (c.w * 4 / 5, g / 2)]
        let n = isTall(c) ? 40 : 18
        for (j, ctr) in centres.enumerated() {
            for i in 0..<n {
                let r = (4 + noise(j * 100 + i) * Double(isTall(c) ? g / 3 : 24)) * Double(s)
                let a = t * (0.4 + 6 / r) * (j % 2 == 0 ? 1 : -1) + noise(j * 100 + i + 50) * 2 * .pi
                let x = ctr.0 + Int(cos(a) * r * 1.4), y = ctr.1 + Int(sin(a) * r * 0.6)
                guard y < g - s else { continue }
                let col = [C(0x8AF0FF), C(0xFF8AE0), C(0xFFD27A)][(i + j) % 3]
                c.rect(x, y, s, s, col.alpha(0.8))
                c.px(x - Int(sin(a) * 2), y + Int(cos(a) * 1), col.alpha(0.3))
            }
        }
        for (i, f) in [0.06, 0.3, 0.83, 0.95].enumerated() {
            let a = 0.15 * (0.5 + 0.5 * sin(t * 2 + Double(i)))
            let cap = quantumTowerCap(Int(Double(c.w) * f), g, (34 + Int(noise(i + 950) * 22)) * s, s, seed: i + 30)
            c.circle(cap.x, cap.y - cap.ry - s, 7 * s, C(0xFFFFFF, a))
        }
    }

    // MARK: - Latveria

    /// Latveria, Castle Doom under a storm: brooding green-grey cloud, dark mountains, the castle's walls and pointed
    /// towers on a black crag hung with green banners bearing Doom's mask, and the half-timbered village huddled
    /// below with its church and lit windows, cobbles underfoot.
    static func latveria(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x161E20), C(0x5E6A62), bands: 7)
        if isTall(c) { latveriaHigh(c, g) }
        for i in 0..<(c.w / 30 + 2) {                                       // storm cloud
            let x = i * 30 + Int(noise(i + 1200) * 20)
            c.ellipse(x, 4 + Int(noise(i + 1201) * 8), (22 + Int(noise(i + 1202) * 16)) * s, 4 * s, C(0x0E1416, 0.55))
            c.ellipse(x + 8, 10 + Int(noise(i + 1203) * 8), 18 * s, 2 * s, C(0x2A3634, 0.5))
        }
        c.dunes(base: g - 26 * s, amp: Double(6 * s), freq: 0.035, phase: 2.2, bottom: g, C(0x2A3436), shade: C(0x3C4A4A))
        c.dunes(base: g - 16 * s, amp: Double(4 * s), freq: 0.05, phase: 0.3, bottom: g, C(0x1E2828))
        let spot = latveriaSpot(c, g)
        latveriaVillage(c, g, s, avoid: spot.x, half: 60 * spot.k, back: true)
        latveriaCrag(c, spot.x, spot.b, g, spot.k)
        latveriaCastle(c, spot.x, spot.b, spot.k)
        latveriaVillage(c, g, s, avoid: spot.x, half: 66 * spot.k, back: false)
        c.ground(g, C(0x3E403C), edge: C(0x6A6C64), speck: C(0x2E302C), seed: 35)
        for y in stride(from: g + 2, to: c.h, by: 3) {                     // cobbles
            for x in stride(from: (y / 3) % 2 == 0 ? 0 : 3, to: c.w, by: 6) { c.rect(x, y, 4, 1, C(0x4A4C46, 0.6)) }
        }
    }

    /// Where Castle Doom stands: centred on `x`, its walls on row `b`, `k` pixels per unit (bigger full screen).
    static func latveriaSpot(_ c: PixelCanvas, _ g: Int) -> (x: Int, b: Int, k: Int) {
        let k = isTall(c) ? 2 * unit(g) : unit(g)
        return (c.w * 3 / 5, g - (isTall(c) ? 26 : 14) * k, k)
    }

    /// Doom's banners on the castle: where each hangs (units from the castle's centre and wall line) and its length.
    static let latveriaBanners = [(-22, -19, 10), (17, -19, 10), (-2, -27, 12)]

    /// The black crag the castle stands on, its top on row `top`, a road zigzagging up its face.
    static func latveriaCrag(_ c: PixelCanvas, _ x: Int, _ top: Int, _ g: Int, _ k: Int) {
        let half = 46 * k
        for dx in -(half + 26 * k)...(half + 26 * k) {
            let edge = max(0, abs(dx) - half + 6 * k)
            let y = top + edge * (g - top) / (32 * k) + Int(noise(dx / max(1, k) + x + 1300) * 3) * k
            if y < g { c.rect(x + dx, y, 1, g - y, noise(dx / max(1, 3 * k) + 1320) > 0.75 ? C(0x262A28) : C(0x1C201E)) }
            if y < g, dx < 0, noise(dx + 1350) > 0.5 { c.px(x + dx, y, C(0x4A5450)) }
        }
        for i in 0..<(half / (4 * k)) {                                         // ledges catching the light
            let u = Int((noise(i * 3 + 1360) - 0.5) * Double(half * 2)), v = top + Int(noise(i * 3 + 1361) * Double(g - top))
            c.rect(x + u, v, (3 + Int(noise(i * 3 + 1362) * 6)) * k, max(1, k / 2), C(0x343A36))
        }
        let rows = max(1, (g - top) / k), seg = max(3, rows / 3)
        for j in 0..<rows {                                                    // the road zigzagging up to the gate
            let p = j % (2 * seg), u = p < seg ? p : 2 * seg - p
            c.rect(x - 22 * k + u * 30 * k / seg, g - (j + 1) * k, 4 * k, k, C(0x3E403A))
        }
    }

    /// Castle Doom on its crag, centred on `x` with its walls standing on row `b`.
    static func latveriaCastle(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let stone = C(0x4C5452), lit = C(0x66706C), shade = C(0x343A3A), roof = C(0x1C2A26), win = C(0xE8D27A)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, h * s, col) }
        func spire(_ u: Int, _ v: Int, _ half: Int, _ h: Int) { scenes2Peak(c, x + u * s, b + (v - h) * s, half: half * s, h: h * s, roof) }
        // the curtain wall with its battlements
        r(-44, -8, 88, 8, stone); r(-44, -8, 88, 1, lit)
        for u in stride(from: -44, to: 44, by: 4) { r(u, -10, 2, 2, stone) }
        // corner towers
        for u in [-48, 40] {
            r(u, -18, 9, 18, stone); r(u, -18, 2, 18, lit); r(u + 7, -18, 2, 18, shade)
            spire(u + 4, -18, 6, 8); r(u + 4, -28, 1, 2, roof)
            r(u + 3, -14, 2, 3, win)
        }
        // the hall and its inner towers
        r(-30, -20, 60, 12, stone); r(-30, -20, 60, 1, lit)
        for u in stride(from: -27, to: 28, by: 5) { r(u, -17, 2, 3, noise(u + 1400) > 0.4 ? win : shade) }
        for u in [-32, 24] { r(u, -28, 8, 20, stone); r(u, -28, 2, 20, lit); spire(u + 4, -28, 5, 7); r(u + 3, -25, 2, 3, win) }
        // the great keep, tallest, Doom's flag on its spire
        r(-8, -34, 16, 26, stone); r(-8, -34, 3, 26, lit); r(6, -34, 2, 26, shade)
        for u in stride(from: -8, to: 8, by: 3) { r(u, -36, 2, 2, stone) }
        spire(0, -36, 7, 9); r(0, -49, 1, 4, roof); r(1, -49, 4, 2, C(0x1E7A3A))
        r(-1, -32, 3, 3, win)
        r(-4, -7, 8, 7, C(0x141818)); c.ellipse(x, b - 7 * s, 4 * s, 2 * s, C(0x141818))   // the gate
        for (u, v, h) in latveriaBanners { latveriaBanner(c, x + u * s, b + v * s, h, s) }
    }

    /// One of Doom's banners: green cloth with a swallowtail, a grey mask on it.
    static func latveriaBanner(_ c: PixelCanvas, _ x: Int, _ y: Int, _ h: Int, _ s: Int) {
        let green = C(0x1E7A3A), dark = C(0x135428)
        c.rect(x - s, y, 7 * s, s, C(0x2A2A22))
        c.rect(x, y + s, 5 * s, (h - 2) * s, green); c.rect(x + 4 * s, y + s, s, (h - 2) * s, dark)
        c.rect(x, y + (h - 1) * s, 2 * s, s, green); c.rect(x + 3 * s, y + (h - 1) * s, 2 * s, s, dark)
        // the mask: a grey face with dark eye slits and mouth grille
        c.rect(x + s, y + 3 * s, 3 * s, 4 * s, C(0xA8B0AC)); c.px(x + s, y + 4 * s, C(0x101410)); c.px(x + 3 * s, y + 4 * s, C(0x101410))
        c.rect(x + s, y + 4 * s, s, max(1, s), C(0x101410)); c.rect(x + 3 * s, y + 4 * s, s, max(1, s), C(0x101410))
        c.rect(x + 2 * s, y + 6 * s, s, s, C(0x5A605C))
    }

    /// The village under the crag: steep red roofs, timbered walls, a church tower and warm windows.
    static func latveriaVillage(_ c: PixelCanvas, _ g: Int, _ s: Int, avoid: Int, half: Int, back: Bool) {
        var x = (back ? -14 : -6) * s, i = back ? 40 : 0
        while x < c.w {
            let w = (14 + Int(noise(i + 1500) * 10)) * s, h = (8 + Int(noise(i + 1501) * 6)) * s
            if x + w > avoid - half && x < avoid + half { x += w + s; i += 1; continue }   // the crag rises here
            let base = g - (back ? 4 * s : 0)
            let wall = back ? C(0x8A7E62) : C(0xA89A78), beam = C(0x2E241C), roof = back ? C(0x5A2C24) : C(0x6E3428)
            c.rect(x, base - h, w, h, wall)
            c.rect(x, base - h, w, s, beam); c.rect(x, base - h / 2, w, s, beam)
            for u in stride(from: x, to: x + w, by: 5 * s) { c.rect(u, base - h, s, h, beam) }
            for u in stride(from: x + 2 * s, to: x + w - 2 * s, by: 5 * s) where noise(u + i * 7) > 0.45 {
                c.rect(u + s, base - h + 2 * s, 2 * s, 2 * s, C(0xF0C860))
            }
            scenes2Peak(c, x + w / 2, base - h - w / 2, half: w / 2 + s, h: w / 2, roof)
            if noise(i + 1503) > 0.6 { c.rect(x + w * 3 / 4, base - h - w / 3 - 3 * s, 2 * s, 4 * s, C(0x3A2A24)) }
            x += w + (noise(i + 1504) > 0.7 ? 6 * s : s); i += 1
            if !back && i == 3 && (x + 12 * s < avoid - half || x > avoid + half) {   // the church
                c.rect(x, g - 30 * s, 9 * s, 30 * s, C(0x8C8670)); c.rect(x, g - 30 * s, 2 * s, 30 * s, C(0xA8A28A))
                scenes2Peak(c, x + 4 * s, g - 42 * s, half: 5 * s, h: 12 * s, C(0x2A3230))
                c.rect(x + 4 * s, g - 45 * s, s, 3 * s, C(0x2A2A22))
                c.ellipse(x + 4 * s, g - 22 * s, 2 * s, 3 * s, C(0xF0C860, 0.8))
                x += 12 * s
            }
        }
    }

    /// Full screen: towering storm cloud, the far ranges of the Latverian mountains.
    static func latveriaHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<16 {
            let x = Int(noise(i * 3 + 1600) * Double(c.w)), y = Int(noise(i * 3 + 1601) * Double(g / 2))
            c.ellipse(x, y, (40 + Int(noise(i * 3 + 1602) * 70)) * s, (6 + Int(noise(i + 1603) * 8)) * s, C(0x0E1416, 0.35))
            c.ellipse(x + 10 * s, y + 6 * s, (30 + Int(noise(i * 3 + 1604) * 40)) * s, 2 * s, C(0x3A4644, 0.3))
        }
        c.dunes(base: g - g / 4, amp: Double(g) / 14, freq: 0.02, phase: 1, bottom: g, C(0x3A4646), shade: C(0x4E5C5A))
        c.dunes(base: g - g / 6, amp: Double(g) / 22, freq: 0.03, phase: 3, bottom: g, C(0x2E3A3A))
    }

    /// Lightning forking down every few seconds with a flash across the sky, the banners stirring in the wind.
    static func latveriaMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let cycle = 5.0, n = Int(t / cycle), p = t - Double(n) * cycle
        if p < 0.35, !(p > 0.1 && p < 0.18) {
            c.rect(0, 0, c.w, g, C(0xD8F0E8, 0.10))
            var x = Double(c.w) * (0.15 + noise(n * 7) * 0.7), y = 0.0
            let ground = Double(g - 30 * s)
            var k = 0
            while y < ground {
                let nx = x + (noise(n * 31 + k) - 0.5) * 10 * Double(s), ny = y + (4 + noise(n * 31 + k + 9) * 6) * Double(s)
                c.glowLine(x, y, nx, ny, core: C(0xF4FFF8), glow: C(0x9AE0C8), coreR: 0.5, glowR: 1.8)
                if k % 3 == 1 { c.glowLine(nx, ny, nx + 8 * Double(s) * (noise(k + n) > 0.5 ? 1 : -1), ny + 6 * Double(s),
                                           core: C(0xC8F0E0, 0.7), glow: C(0, 0), coreR: 0.4, glowR: 0.5) }
                x = nx; y = ny; k += 1
            }
        }
        // the banners' tails flicking in the wind
        let spot = latveriaSpot(c, g), k = spot.k
        for (i, (u, v, h)) in latveriaBanners.enumerated() where sin(t * 3 + Double(i) * 1.7) > 0.3 {
            c.rect(spot.x + (u + 5) * k, spot.b + (v + h - 5) * k, k, 3 * k, C(0x1E7A3A))
            c.rect(spot.x + (u + 4) * k, spot.b + (v + h - 1) * k, k, k, C(0x135428))
        }
    }

    // MARK: - Hydrax Base

    /// A Hydrax base at night, a grim concrete bunker dug into a pine-dark mountainside: the steel blast door under red
    /// lamps and the painted Hydrax skull, the red skull banners hanging either side, searchlight towers at the
    /// corners, a Hydrax tank, crates and fuel drums on the oil-stained apron.
    static func hydraBase(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x07080C), C(0x2A2C34), bands: 7)
        c.stars(0, g / 2, density: 150, seed: 50)
        if isTall(c) { hydraHigh(c, g) }
        // the mountainside and its pines
        c.dunes(base: g - 30 * s, amp: Double(5 * s), freq: 0.03, phase: 1.5, bottom: g, C(0x1A1C22), shade: C(0x2A2E36))
        for i in 0..<(c.w / 6) {
            let x = i * 6 + Int(noise(i + 1700) * 4), h = (8 + Int(noise(i + 1701) * 8)) * s
            scenes2Peak(c, x, g - 14 * s - h, half: 3 * s, h: h, C(0x0E1014))
        }
        c.rect(0, g - 14 * s, c.w, 14 * s, C(0x0E1014))
        // the bunker
        let bx = c.w / 2, half = 92 * s
        hydraBunker(c, bx, g, half, s)
        for u in [c.w / 2 - half - 28 * s, c.w / 2 + half + 20 * s] { hydraTower(c, u, g, s) }
        // the tank on the left, crates and drums on the right
        hydraTank(c, 40 * s, g, s)
        hydraCrates(c, c.w - 70 * s, g, s)
        c.ground(g, C(0x3A3A3C), edge: C(0x5E5E5C), speck: C(0x2C2C2E), seed: 36)
        c.rect(0, g + 3, c.w, 1, C(0xC8A030, 0.55))
        for (i, x) in stride(from: 60, to: c.w, by: 140).enumerated() {
            c.ellipse(x + Int(noise(i + 1750) * 40), g + (c.h - g) * 2 / 3, 10 * s, max(1, (c.h - g) / 6), C(0x1E1E22, 0.6))
        }
    }

    /// The bunker's concrete face centred on `x`, `half` pixels either side, with its door, lamps, emblem and banners.
    static func hydraBunker(_ c: PixelCanvas, _ x: Int, _ g: Int, _ half: Int, _ s: Int) {
        let conc = C(0x56585A), lit = C(0x6E706E), dark = C(0x3A3C3E), stain = C(0x2E3032, 0.5)
        let top = g - 34 * s
        // a sloped earth-covered roof, then the face
        for k in 0..<(6 * s) { c.rect(x - half - k * 2, top - 6 * s + k, (half + k * 2) * 2, 1, C(0x2A2C2E)) }
        c.rect(x - half, top, half * 2, 34 * s, conc); c.rect(x - half, top, half * 2, s, lit)
        c.rect(x - half, top + 3 * s, half * 2, s, dark)
        for u in stride(from: x - half + 24 * s, to: x + half, by: 24 * s) { c.rect(u, top + 4 * s, max(1, s / 2), 30 * s, dark) }
        for i in 0..<(half / (6 * s)) {                                            // rust and water stains
            let u = x - half + Int(noise(i + 1800) * Double(half * 2)), l = (4 + Int(noise(i + 1801) * 14)) * s
            c.rect(u, top + 4 * s, s, l, stain)
        }
        // the blast door: steel leaves in a hazard-striped frame
        let dw = 20 * s
        c.rect(x - dw - 3 * s, g - 25 * s, (dw + 3 * s) * 2, 25 * s, C(0x1A1A1C))
        for k in 0..<((dw + 3 * s) * 2 / (2 * s)) {
            c.rect(x - dw - 3 * s + k * 2 * s, g - 25 * s, 2 * s, 2 * s, k % 2 == 0 ? C(0xD8A824) : C(0x1A1A1C))
        }
        c.rect(x - dw, g - 23 * s, dw * 2, 23 * s, C(0x4C5258)); c.rect(x - s / 2, g - 23 * s, max(1, s), 23 * s, C(0x22262A))
        for v in stride(from: g - 20 * s, to: g, by: 5 * s) { c.rect(x - dw, v, dw * 2, max(1, s / 2), C(0x3A3E44)) }
        c.rect(x - dw, g - 23 * s, dw * 2, s, C(0x6A7076))
        // the Hydrax emblem painted above the door, and the lamps either side
        hydraEmblem(c, x, top + 6 * s, s, C(0x9A1A1A))
        for u in [-dw - 8 * s, dw + 6 * s] { c.rect(x + u, g - 30 * s, 3 * s, 2 * s, C(0x3A0A0A)) }
        // the banners
        for u in [-74, -50, 38, 62] { hydraBanner(c, x + u * s, top + 6 * s, s) }
        // slit windows
        for u in [-84, -30, 22, 76] { c.rect(x + u * s, top + 6 * s, 8 * s, 2 * s, C(0x8A2A1A, 0.7)) }
    }

    /// The Hydrax skull with three serpent necks rising from it, centred on `x` with its top at `y`.
    static func hydraEmblem(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int, _ col: Px) {
        let art = ["###..###..###",
                   ".#....#....#.",
                   "..#...#...#..",
                   "...#######...",
                   "..##.###.##..",
                   "..#########..",
                   "...#.#.#.#...",
                   "....#####...."]
        for (v, row) in art.enumerated() {
            for (u, ch) in row.enumerated() where ch == "#" { c.rect(x + (u - 6) * s, y + v * s, s, s, col) }
        }
    }

    /// A red Hydrax banner hanging from a rod, its tail cut in a swallowtail.
    static func hydraBanner(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let red = C(0xA8161A), dark = C(0x7A0E12)
        c.rect(x - s, y, 16 * s, s, C(0x1A1A1C))
        c.rect(x, y + s, 14 * s, 22 * s, red); c.rect(x + 12 * s, y + s, 2 * s, 22 * s, dark); c.rect(x, y + s, 14 * s, s, dark)
        scenes2Peak(c, x + 7 * s, y + 19 * s, half: 3 * s, h: 4 * s, C(0x56585A))
        hydraEmblem(c, x + 7 * s, y + 6 * s, s, C(0x141416))
    }

    /// A searchlight tower: a steel lattice with a lamp on its platform.
    static func hydraTower(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let steel = C(0x2A2C30), lit = C(0x4A4E54)
        let top = g - 46 * s
        c.rect(x, top, s, 46 * s, steel); c.rect(x + 9 * s, top, s, 46 * s, steel)
        for v in stride(from: top, to: g, by: 8 * s) {
            for k in 0..<(8 * s) { c.px(x + k * 9 / 8, v + k, steel); c.px(x + 9 * s - k * 9 / 8, v + k, steel) }
        }
        c.rect(x - 3 * s, top - s, 16 * s, 2 * s, lit); c.rect(x - 3 * s, top - 4 * s, s, 3 * s, steel); c.rect(x + 12 * s, top - 4 * s, s, 3 * s, steel)
        c.rect(x + 2 * s, top - 6 * s, 6 * s, 5 * s, C(0x3A3E44)); c.rect(x + 2 * s, top - 6 * s, 6 * s, s, lit)
        c.rect(x + 3 * s, top - 5 * s, 4 * s, 3 * s, C(0xF4ECC8))
    }

    /// A Hydrax tank: a squat hull on long tracks under a wide turret, its gun pointing left.
    static func hydraTank(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let hull = C(0x3A3E38), lit = C(0x585E54), dark = C(0x1E201C)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, g + v * s, w * s, h * s, col) }
        r(-2, -6, 44, 6, dark); for u in stride(from: 0, to: 42, by: 5) { c.circle(x + (u + 2) * s, g - 3 * s, 2 * s, C(0x2E302A)) }
        r(0, -12, 40, 6, hull); r(0, -12, 40, 1, lit); r(-3, -10, 3, 3, hull)
        r(8, -18, 24, 6, hull); r(8, -18, 24, 1, lit); r(30, -17, 2, 5, dark)
        r(-14, -16, 22, 2, hull); r(-16, -17, 3, 4, dark)
        r(14, -21, 6, 3, dark); hydraEmblem(c, x + 22 * s, g - 11 * s, max(1, s / 2), C(0x8A1414))
    }

    /// Supply crates (wooden and olive drab) stacked by fuel drums.
    static func hydraCrates(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        func crate(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px, _ edge: Px) {
            c.rect(x + u * s, g + v * s, w * s, h * s, col); c.rect(x + u * s, g + v * s, w * s, s, edge)
            c.rect(x + u * s, g + v * s, s, h * s, edge); c.rect(x + (u + w - 1) * s, g + v * s, s, h * s, edge)
            for k in 0..<min(w, h) { c.rect(x + (u + k * w / h) * s, g + (v + k) * s, s, s, edge.alpha(0.6)) }
        }
        crate(0, -10, 12, 10, C(0x6A5034), C(0x4A3622)); crate(12, -9, 14, 9, C(0x4A5032), C(0x343A22))
        crate(3, -19, 11, 9, C(0x4A5032), C(0x343A22))
        for u in [30, 36] { c.rect(x + u * s, g - 9 * s, 5 * s, 9 * s, C(0x7A1A16)); c.rect(x + u * s, g - 7 * s, 5 * s, s, C(0x4A0E0C)); c.rect(x + u * s, g - 3 * s, 5 * s, s, C(0x4A0E0C)) }
        c.rect(x + 13 * s, g - 6 * s, 4 * s, s, C(0xC8A030, 0.6))
    }

    /// Full screen: the snowy peaks above the base and a cold, hazy moon.
    static func hydraHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.circle(c.w * 4 / 5, g / 6, 9 * s, C(0xD0D4DC, 0.15)); c.circle(c.w * 4 / 5, g / 6, 6 * s, C(0xC8CCD4))
        c.circle(c.w * 4 / 5 + 2 * s, g / 6 - s, 2 * s, C(0xB0B4BC))
        for i in 0..<5 {
            let x = Int(noise(i * 3 + 1900) * Double(c.w)), h = g / 3 + Int(noise(i * 3 + 1901) * Double(g / 4)), w = (60 + Int(noise(i * 3 + 1902) * 60)) * s
            let base = g - 20 * s, half = w / 2
            for dx in -half...half {                                       // a jagged peak, its cap under snow
                let jag = Int(noise(i * 211 + (dx + half) / (3 * s)) * Double(h) / 10)
                let top = base - h + abs(dx) * h / max(1, half) * (dx < 0 ? 9 : 11) / 10 + jag
                guard top < base else { continue }
                let snow = base - h * 3 / 4 + Int(noise(i * 37 + dx / (2 * s)) * Double(h) / 8)
                c.rect(x + dx, top, 1, base - top, dx < 0 ? C(0x2C3038) : C(0x22262E))
                if top < snow { c.rect(x + dx, top, 1, snow - top, dx < 0 ? C(0x9AA0AC) : C(0x707684)) }
            }
        }
    }

    /// The searchlights sweeping the sky, and the red lamps over the door blinking.
    static func hydraBaseMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), half = 92 * s
        for (i, lx) in [c.w / 2 - half - 28 * s + 5 * s, c.w / 2 + half + 20 * s + 5 * s].enumerated() {
            let ly = g - 51 * s, a = sin(t * 0.45 + Double(i) * 2.1) * 0.6 + (i == 0 ? 0.25 : -0.25)
            for y in stride(from: ly, to: -1, by: -1) {
                let d = Double(ly - y), cx = Double(lx) + tan(a) * d, hw = 1 + d * 0.07
                let fade = max(0, 1 - d / Double(max(g, 80) * 3 / 2))
                c.rect(Int(cx - hw), y, Int(hw * 2) + 1, 1, C(0xF4ECC8, 0.10 * fade))
                c.rect(Int(cx - hw / 3), y, Int(hw * 2 / 3) + 1, 1, C(0xFFF8E0, 0.06 * fade))
            }
            c.circle(lx, ly, 3 * s, C(0xFFF4D0, 0.35))
        }
        let on = (t * 1.5).truncatingRemainder(dividingBy: 1) < 0.5, dw = 20 * s
        for u in [-dw - 8 * s, dw + 6 * s] where on {
            c.rect(c.w / 2 + u, g - 30 * s, 3 * s, 2 * s, C(0xFF2A2A)); c.circle(c.w / 2 + u + s, g - 29 * s, 5 * s, C(0xFF2A2A, 0.18))
        }
    }

    // MARK: - Daily Bungle

    /// The Daily Bungle, up on the Bungle's roof on a bright day: the paper's big DAILY BUNGLE letters on their steel
    /// frame, a wooden water tower and the stair hut, pigeons along the parapet, and Midtown behind, the Empire State
    /// and the Chrysler Building over rows of towers with water tanks on their roofs.
    static func dailyBugle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.gradient(0, g, C(0x3C80D2), C(0xCDE6F6), bands: 6)
        if isTall(c) { bugleHigh(c, g) }
        for (i, x) in stride(from: 50, to: c.w, by: 140).enumerated() { cloud(c, x + Int(noise(i + 2000) * 40), 8 + i % 2 * 5, 3, seed: i + 2000) }
        // far Midtown, with the Empire State and the Chrysler
        bugleRow(c, g, top: 26 * s, depth: 18 * s, col: C(0x9CB2CC), win: C(0xB8CCE0), seed: 1, s: s)
        bugleEmpire(c, c.w * 3 / 10, g, s)
        bugleChrysler(c, c.w * 17 / 20, g, s)
        bugleRow(c, g, top: 12 * s, depth: 14 * s, col: C(0x7A8CA8), win: C(0x95A8C2), seed: 2, s: s)
        // our roof: the water tower, the stair hut, the sign on its frame
        bugleWaterTower(c, 26 * s, g - 3 * s, s)
        let hx = c.w - 50 * s
        c.rect(hx, g - 18 * s, 26 * s, 15 * s, C(0x9A7A62)); c.rect(hx, g - 18 * s, 26 * s, s, C(0xB8987C))
        c.rect(hx - s, g - 20 * s, 28 * s, 2 * s, C(0x5A5048))
        c.rect(hx + 16 * s, g - 14 * s, 6 * s, 11 * s, C(0x3A4250)); c.px(hx + 17 * s, g - 9 * s, C(0xC8C0A0))
        bugleSign(c, c.w / 2 + 10 * s, g - 3 * s, s)
        // the parapet with pigeons on it, and the gravel roof
        c.rect(0, g - 3 * s, c.w, 3 * s, C(0xA4927C)); c.rect(0, g - 3 * s, c.w, s, C(0xC8B8A0))
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g - 2 * s, max(1, s / 2), 2 * s, C(0x8A7A66)) }
        for (i, f) in [0.08, 0.22, 0.24, 0.66, 0.9].enumerated() { buglePigeon(c, Int(Double(c.w) * f), g - 3 * s, s, flip: i % 2 == 0) }
        c.ground(g, C(0x6E6862), edge: C(0x8A847C), speck: C(0x5A5650), seed: 37)
    }

    /// A row of towers `top`…`top + depth` pixels tall, with window grids and water tanks on some roofs.
    static func bugleRow(_ c: PixelCanvas, _ g: Int, top: Int, depth: Int, col: Px, win: Px, seed: Int, s: Int) {
        var x = -Int(noise(seed + 2100) * 20), i = 0
        while x < c.w {
            let bw = (12 + Int(noise(seed * 60 + i + 2100) * 20)) * s, h = top + Int(noise(seed * 60 + i + 2200) * Double(depth))
            c.rect(x, g - h, bw - s, h, col)
            for v in stride(from: g - h + 2 * s, to: g, by: 3 * s) {
                for u in stride(from: x + s, to: x + bw - 2 * s, by: 3 * s) { c.rect(u, v, s, s, win) }
            }
            c.rect(x, g - h, s, h, lerp(col, C(0xFFFFFF), 0.25))
            if seed == 2, noise(seed * 60 + i + 2300) > 0.6 {               // a water tank on the nearer roofs
                let tx = x + bw / 2
                c.rect(tx - 3 * s, g - h - 6 * s, 6 * s, 4 * s, lerp(col, C(0x8A5E40), 0.45))
                c.rect(tx - 3 * s, g - h - 7 * s, 6 * s, s, lerp(col, C(0x4A3A34), 0.5))
                c.rect(tx - 2 * s, g - h - 2 * s, s, 2 * s, lerp(col, C(0x2A2A30), 0.5)); c.rect(tx + 2 * s, g - h - 2 * s, s, 2 * s, lerp(col, C(0x2A2A30), 0.5))
            }
            x += bw; i += 1
        }
    }

    /// The Empire State Building: stepped setbacks, the tower and its mast.
    static func bugleEmpire(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let col = C(0x8EA4C0), lit = C(0xA8BCD4)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ p: Px) { c.rect(x + u * s, g + v * s, w * s, h * s, p) }
        r(-12, -36, 24, 36, col); r(-9, -46, 18, 10, col); r(-6, -54, 12, 8, col); r(-3, -58, 6, 4, col); r(-1, -62, 2, 4, col); r(0, -70, 1, 8, col)
        r(-12, -36, 3, 36, lit); r(-9, -46, 2, 10, lit); r(-6, -54, 2, 8, lit)
        for u in stride(from: -8, to: 10, by: 3) { r(u, -52, 1, 50, C(0x7E94B0)) }
    }

    /// The Chrysler Building: its stacked art-deco arches and needle spire.
    static func bugleChrysler(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
        let col = C(0x92A8C4), steel = C(0xD8E2EE)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ p: Px) { c.rect(x + u * s, g + v * s, w * s, h * s, p) }
        r(-10, -34, 20, 34, col); r(-7, -42, 14, 8, col)
        for k in 0..<5 {
            let w = 6 - k
            c.ellipse(x, g - (42 + k * 3) * s, w * s, 3 * s, steel); c.ellipse(x, g - (42 + k * 3) * s + s, w * s - s, 2 * s, col)
            for u in stride(from: -w + 1, to: w, by: 2) { r(u, -42 - k * 3, 1, 1, C(0x5A6E8A)) }
        }
        r(0, -64, 1, 8, steel)
    }

    /// The wooden water tower on the Bugle's roof.
    static func bugleWaterTower(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let wood = C(0x8A5E40), lit = C(0xA87656), hoop = C(0x3A3436), leg = C(0x3A3A40)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, h * s, col) }
        for u in [-9, -3, 3, 8] { r(u, -14, 1, 14, leg) }
        for k in 0..<7 { r(-8 + k * 2, -13 + k * 2, 1, 1, leg); r(7 - k * 2, -13 + k * 2, 1, 1, leg) }
        r(-11, -15, 22, 2, leg)
        r(-10, -31, 20, 16, wood); r(-10, -31, 3, 16, lit)
        for u in stride(from: -7, to: 10, by: 3) { r(u, -31, 1, 16, C(0x744C32)) }
        for v in [-28, -23, -18] { r(-10, v, 20, 1, hoop) }
        scenes2Peak(c, x, b - 38 * s, half: 12 * s, h: 7 * s, C(0x5A4A44)); r(0, -40, 1, 2, leg)
    }

    /// The DAILY BUNGLE letters on their steel frame, centred on `x`, the frame's feet on row `b`.
    static func bugleSign(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let k = 2 * s, text = "DAILY BUNGLE", w = scenes2TextWidth(text, s: k)
        let left = x - w / 2, top = b - 34 * s, steel = C(0x3A3E48)
        // the frame: posts, braces and a catwalk under the letters
        for u in stride(from: left, through: left + w, by: 16 * s) {
            c.rect(u, top + 10 * s, s, b - top - 10 * s, steel)
        }
        for u in stride(from: left, to: left + w - 8 * s, by: 16 * s) {
            for j in 0..<(16 * s) {
                c.px(u + j, top + 16 * s + j * 14 / 16, steel); c.px(u + 16 * s - j, top + 16 * s + j * 14 / 16, steel)
            }
        }
        c.rect(left - 2 * s, top + 15 * s, w + 4 * s, s, steel)
        c.rect(left - 2 * s, b - s, w + 4 * s, s, steel)
        // the letters, with a dark edge so they stand out against the sky
        scenes2Text(c, left + s, top + s, text, C(0x23262E), s: k)
        scenes2Text(c, left, top, text, C(0xF6F0E0), s: k)
        for u in stride(from: left, to: left + w, by: 4 * s) { c.rect(u, top + 13 * s, s, s, C(0xFFE8A0, 0.6)) }   // the lamps
    }

    /// A pigeon perched on row `b`.
    static func buglePigeon(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int, flip: Bool) {
        let d = flip ? -1 : 1
        c.rect(x - 2 * s, b - 3 * s, 4 * s, 3 * s, C(0x6E7484)); c.rect(x - s, b - 3 * s, 2 * s, s, C(0x8A90A0))
        c.rect(x + (flip ? -3 : 2) * s, b - 4 * s, s * 2, 2 * s, C(0x4E5464)); c.px(x + (flip ? -3 : 3) * s, b - 4 * s, C(0x101014))
        c.rect(x + (flip ? -2 : 1) * s, b - 2 * s, s, s, C(0x5A9A7A)); c.rect(x - d * 3 * s, b - 2 * s, s, s, C(0x3A4050))
    }

    /// Full screen: fair-weather cumulus over the city, the far towers of Midtown and a blimp on the way downtown.
    static func bugleHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for (i, (fx, fy, r)) in [(0.15, 0.1, 9), (0.55, 0.06, 7), (0.85, 0.18, 8), (0.35, 0.28, 6), (0.7, 0.36, 5)].enumerated() {
            cloud(c, Int(Double(c.w) * fx), Int(Double(g) * fy), r * s, seed: i + 2400)
        }
        bugleRow(c, g, top: g / 4, depth: g / 4, col: C(0xB4C6DA), win: C(0xC4D4E4), seed: 5, s: s)
        bugleRow(c, g, top: g / 7, depth: g / 6, col: C(0xA6BAD2), win: C(0xB6C8DC), seed: 6, s: s)
    }

    /// Pigeons flapping across, and (now and then) Spider-Man swinging by on a web line.
    static func dailyBugleMoving(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        for i in 0..<(isTall(c) ? 5 : 3) {
            let x = scenes2Slide(t, period: 14 + Double(i) * 5, phase: noise(i + 2500), w: c.w, margin: 20, leftward: i % 2 == 1)
            let y = (isTall(c) ? Int(Double(g) * (0.2 + 0.12 * Double(i))) : 10 + i * 9) + Int(sin(t * 2 + Double(i)) * 2) * s
            let up = Int(t * 8 + Double(i)) % 2 == 0
            c.rect(x - s, y, 3 * s, s, C(0x5A6070)); c.px(x + (i % 2 == 1 ? -2 : 2) * s, y, C(0x4A5060))
            c.rect(x - 2 * s, y + (up ? -s : s), 2 * s, s, C(0x7A8090)); c.rect(x + s, y + (up ? -s : s), 2 * s, s, C(0x7A8090))
        }
        // Spider-Man swinging past, once every half minute
        let p = (t / 30).truncatingRemainder(dividingBy: 1) / 0.12
        guard p < 1 else { return }
        let ax = Double(c.w) * (0.2 + p * 0.6), ay = isTall(c) ? Double(g) * 0.05 : -10
        let len = isTall(c) ? Double(g) * 0.45 : 52, ang = (p - 0.5) * 1.6
        let hx = ax + sin(ang) * len, hy = ay + cos(ang) * len
        c.glowLine(ax, ay, hx, hy, core: C(0xF0F4F8, 0.8), glow: C(0, 0), coreR: 0.4, glowR: 0.5)
        let x = Int(hx), y = Int(hy)
        c.rect(x - s, y, 3 * s, 3 * s, C(0xD0202A)); c.rect(x - s, y + 3 * s, 3 * s, 2 * s, C(0x2A4AC0))
        c.rect(x, y - 2 * s, 2 * s, 2 * s, C(0xD0202A)); c.rect(x - 2 * s, y + 5 * s, 2 * s, s, C(0x2A4AC0)); c.rect(x + 2 * s, y + 4 * s, 2 * s, s, C(0x2A4AC0))
    }
}
