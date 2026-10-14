import Foundation

let scenes4: [Location: Place] = [
    .baxterBuilding: Place(name: "Bexter Building", panel: 0x1A1E2A, still: Scenes.baxterBuilding, moving: Scenes.baxterLife),
    .jotunheim: Place(name: "Jotunheim", panel: 0x161C24, still: Scenes.jotunheim, moving: Scenes.jotunheimLife),
    .muspelheim: Place(name: "Muspelheim", panel: 0x2A1410, still: Scenes.muspelheim, moving: Scenes.muspelheimLife),
    .hala: Place(name: "Halla", panel: 0x12222A, still: Scenes.hala, moving: Scenes.halaLife),
    .genosha: Place(name: "Genoshia", panel: 0x261C26, still: Scenes.genosha, moving: Scenes.genoshaLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// String art drawn with every character `s` pixels square, skipping any pixel `clip` rejects.
    static func scenes4Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int,
                             clip: ((Int, Int) -> Bool)? = nil) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() {
                guard let col = pal[ch] else { continue }
                for yy in 0..<s {
                    for xx in 0..<s {
                        let px = x + k * s + xx, py = y + r * s + yy
                        if let clip, !clip(px, py) { continue }
                        c.px(px, py, col)
                    }
                }
            }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes4Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// `v` wrapped into 0..<m.
    static func scenes4Wrap(_ v: Double, _ m: Double) -> Double {
        let r = v.truncatingRemainder(dividingBy: m)
        return r < 0 ? r + m : r
    }

    /// Size of the big landmarks: 1 in the window's strip, growing with the screen saver's height.
    static func scenes4Scale(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(2, g / 145) : 1 }
}

// MARK: - Baxter Building

extension Scenes {
    /// The lab's window wall: first and last rows of glass.
    static func baxterWindow(_ c: PixelCanvas, _ g: Int) -> (top: Int, bottom: Int) {
        let s = unit(g)
        return (isTall(c) ? g / 8 : 3 * s, g - 14 * s)
    }

    /// The "4" emblem on the glass (centre and radius) and the spacing of the window's mullions around it.
    static func baxterEmblem(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int, step: Int) {
        let s = unit(g), win = baxterWindow(c, g), hgt = win.bottom - win.top
        let r = max(8, hgt / 6)
        return (c.w / 2, win.top + hgt * 8 / 25, r, max(46 * s, 2 * r + 20 * s))
    }

    /// Left edges of the window's mullions, a pane centred on the emblem.
    static func baxterMullions(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let e = baxterEmblem(c, g), s = unit(g)
        var x = c.w / 2 - e.step / 2 - s
        while x > 0 { x -= e.step }
        return Array(stride(from: x, to: c.w, by: e.step))
    }

    /// The Negative Zone portal: centre and inner radius.
    static func baxterPortal(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let s = unit(g)
        let r = isTall(c) ? max(26, g / 4) : max(16, g * 7 / 20)
        return (Int(Double(c.w) * 0.8), g - r - 7 * s * scenes4Scale(c, g), r)
    }

    /// The computer banks along the left wall.
    static func baxterBanks(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = unit(g), bw = 16 * s
        let bh = isTall(c) ? g * 11 / 20 : g - 5 * s
        let end = max(bw + 2 * s, Int(Double(c.w) * 0.2))
        return stride(from: 2 * s, through: end - bw, by: bw + 2 * s).map { (x: $0, y: g - bh, w: bw, h: bh) }
    }

    /// One bank's panels from top to bottom: 0 a grid of lights, 1 tape reels, 2 a screen.
    static func baxterSections(_ b: (x: Int, y: Int, w: Int, h: Int), s: Int) -> [(kind: Int, y: Int)] {
        let heights = [10 * s, 12 * s, 11 * s]
        var out: [(kind: Int, y: Int)] = [], y = b.y + 4 * s, k = 0
        while y + heights[k % 3] <= b.y + b.h - 5 * s {
            out.append((k % 3, y)); y += heights[k % 3]; k += 1
        }
        return out
    }

    /// The Baxter Building's top-floor lab at dusk: a window wall over Manhattan (the Chrysler Building glinting in
    /// the sunset) with the Fanclawdstic Four's blue "4" emblem on the glass, Reed's giant computer banks of blinking
    /// lights, tape reels and scopes down the left, and the ringed Negative Zone portal on its platform at the right,
    /// cabled to the computers.
    static func baxterBuilding(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), win = baxterWindow(c, g), hgt = win.bottom - win.top
        // ceiling
        c.rect(0, 0, c.w, win.top, C(0x1C2230))
        if tall {
            for x in stride(from: 0, to: c.w, by: 32 * s) {                              // ceiling panels and lights
                c.rect(x, 0, s, win.top, C(0x141924))
                c.rect(x + 10 * s, win.top / 2 - 2 * s, 12 * s, 4 * s, C(0x2A3244))
                c.rect(x + 11 * s, win.top / 2 - s, 10 * s, 2 * s, C(0xE0ECFF, 0.85))
            }
            c.rect(0, win.top - 3 * s, c.w, 2 * s, C(0x262E40))
        }
        // the dusk sky and Manhattan through the glass
        c.gradient(win.top, win.bottom, C(0x2A3470), C(0xF4A868), bands: 8)
        if tall { c.stars(win.top, win.top + hgt / 3, density: 140, seed: 41) }
        let sx = Int(Double(c.w) * 0.6), sy = win.bottom - hgt / 5, sr = max(4, hgt / 9)
        c.circle(sx, sy, sr * 3, C(0xFFD8A0, 0.12)); c.circle(sx, sy, sr * 2, C(0xFFD8A0, 0.15))
        c.circle(sx, sy, sr, C(0xFFE8C0))
        for i in 0..<(tall ? 6 : 3) {
            wisp(c, Int(noise(i * 5 + 410) * Double(c.w)), win.top + hgt / 6 + Int(noise(i * 5 + 411) * Double(hgt / 3)),
                 (24 + Int(noise(i * 5 + 412) * 30)) * s, C(0xE8907A, 0.45), s: s)
        }
        baxterSkyline(c, g)
        c.rect(0, win.top, c.w, hgt, C(0x9AC8F0, 0.06))                               // the glass's tint
        for (k, x) in stride(from: c.w / 7, to: c.w, by: c.w / 3).enumerated() {        // sheen streaks
            for y in stride(from: win.top, to: win.bottom, by: 1) {
                let dx = (y - win.top) / 2
                c.rect(x + dx - (k % 2 == 0 ? 6 : 3) * s, y, (k % 2 == 0 ? 4 : 2) * s, 1, C(0xFFFFFF, 0.05))
            }
        }
        baxterEmblemDraw(c, g)
        for x in baxterMullions(c, g) {
            c.rect(x, win.top, 3 * s, hgt, C(0x343C52)); c.rect(x + s, win.top, s, hgt, C(0x5A6884))
        }
        c.rect(0, win.top, c.w, s, C(0x5A6884))
        // the wall under the glass: a sill, a blue band and vents
        c.rect(0, win.bottom, c.w, g - win.bottom, C(0x2E3648))
        c.rect(0, win.bottom, c.w, 2 * s, C(0x5A6680)); c.rect(0, win.bottom, c.w, s, C(0x9AA8C4))
        c.rect(0, win.bottom + 6 * s, c.w, s, C(0x2A6AD0))
        for x in stride(from: 8 * s, to: c.w, by: 30 * s) {
            for k in 0..<3 { c.rect(x, win.bottom + 9 * s + k * s, 8 * s, max(1, s / 2), C(0x1E2432)) }
        }
        // cables from the computers to the portal, slung along the wall
        let banks = baxterBanks(c, g), p = baxterPortal(c, g)
        let cx0 = (banks.last.map { $0.x + $0.w } ?? 0), cx1 = p.x - p.r - 4 * s
        if cx1 > cx0 {
            for (k, col) in [C(0x14181F), C(0x2A2230), C(0x1A2A3A)].enumerated() {
                let y0 = win.bottom + (3 + k * 2) * s, sag = Double((4 + k * 2) * s)
                for x in cx0..<cx1 {
                    let f = Double(x - cx0) / Double(cx1 - cx0)
                    c.rect(x, y0 + Int(sin(f * .pi) * sag), 1, s, col)
                }
            }
        }
        for b in banks { baxterBank(c, b, s: s) }
        baxterPortalDraw(c, g)
        // the lab floor
        c.ground(g, C(0x4A5468), edge: C(0x9AA8C0), speck: C(0x424A5C), seed: 41)
        for x in stride(from: 0, to: c.w, by: 22 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x3E4658)) }
        c.ellipse(p.x, g + (c.h - g) / 2, p.r + 6 * s, max(2, (c.h - g) / 3), C(0x9A7AF0, 0.14))
    }

    /// Manhattan at sunset, seen through the window: hazy far blocks, the Chrysler Building, nearer dark blocks.
    static func baxterSkyline(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), win = baxterWindow(c, g), hgt = win.bottom - win.top
        let layers: [(lo: Double, hi: Double, col: Px, seed: Int)] = [
            (0.28, 0.55, C(0xA87A8A), 5), (0.10, 0.36, C(0x3A3452), 11),
        ]
        for (layer, spec) in layers.enumerated() {
            var x = -3 * s, i = 0
            while x < c.w {
                let bw = (7 + Int(noise(i * 5 + spec.seed * 97) * 10)) * s
                let bh = Int(Double(hgt) * (spec.lo + noise(i * 5 + 1 + spec.seed * 97) * (spec.hi - spec.lo)))
                let top = win.bottom - bh
                c.rect(x, top, bw, bh, spec.col)
                c.rect(x + bw - s, top, s, bh, lerp(spec.col, C(0xFFC890), 0.25))       // sunset on the west faces
                c.rect(x, top, bw, s, lerp(spec.col, C(0xFFC890), 0.4))
                if layer == 1 {
                    for (j, wy) in stride(from: top + 2 * s, to: win.bottom - s, by: 3 * s).enumerated() {
                        for (k, wx) in stride(from: x + s, to: x + bw - s, by: 2 * s).enumerated()
                        where noise(i * 131 + j * 7 + k * 13 + 5) > 0.72 {
                            c.rect(wx, wy, s, s, C(0xFFD890, 0.7))
                        }
                    }
                }
                x += bw + (layer == 1 ? Int(noise(i * 5 + 2 + spec.seed * 97) * 4) * s : 0)
                i += 1
            }
            if layer == 0 { baxterChrysler(c, g, x: Int(Double(c.w) * 0.31), height: Int(Double(hgt) * 0.74)) }
        }
        c.rect(0, win.bottom - hgt / 6, c.w, hgt / 6, C(0xF4A868, 0.14))                // haze along the streets
    }

    /// The Chrysler Building: shaft, the stacked arches of its crown catching the sun, and the needle.
    static func baxterChrysler(_ c: PixelCanvas, _ g: Int, x: Int, height: Int) {
        let s = unit(g), bottom = baxterWindow(c, g).bottom, top = bottom - height
        let col = C(0x6A4E6A)
        c.rect(x - 6 * s, top + 16 * s, 12 * s, height - 16 * s, col)
        c.rect(x + 5 * s, top + 16 * s, s, height - 16 * s, C(0xC89080))
        for k in 0..<5 {
            let hw = (5 - k) * s, y = top + 16 * s - (k + 1) * 3 * s
            c.rect(x - hw, y, hw * 2, 3 * s, col)
            c.rect(x - hw, y, hw * 2, s, C(0xF8D8B0))
            for wx in stride(from: x - hw + s, to: x + hw - s, by: 2 * s) { c.rect(wx, y + s, s, s, C(0xFFE0A0, 0.8)) }
        }
        c.rect(x, top - 6 * s, s, 7 * s, C(0xF0D8C0))
    }

    /// The Fanclawdstic Four's emblem on the glass: a blue disc in a white ring, the "4" breaking out of it, a claw
    /// notch raked across the top of its stem.
    static func baxterEmblemDraw(_ c: PixelCanvas, _ g: Int) {
        let e = baxterEmblem(c, g), r = e.r, rd = Double(r)
        c.circle(e.x, e.y, r + max(2, r / 4), C(0x9AC8F0, 0.12))
        c.circle(e.x, e.y, r, C(0xF4F8FF))
        c.circle(e.x, e.y, r * 4 / 5, C(0x2A5AC8))
        c.circle(e.x - r / 6, e.y - r / 6, r / 2, C(0x3A6ED8))
        let w = max(1, r / 5), cx = Double(e.x), cy = Double(e.y)
        let ink = C(0xF4F8FF)
        c.rect(e.x + r / 8, e.y - r * 7 / 8, w, r * 7 / 4, ink)                         // the stem
        c.rect(e.x - r * 6 / 10, e.y + r / 6, r * 11 / 10 + w, w, ink)                  // the bar
        c.glowLine(cx + rd * 0.12 + Double(w) / 2, cy - rd * 0.85, cx - rd * 0.58, cy + rd * 0.22,
                   core: ink, glow: ink, coreR: Double(w) / 2, glowR: Double(w) / 2 + 0.6)
        // the claw notch: three short slashes in the disc's blue, cutting across the top of the stem
        let notch = C(0x2A5AC8), sx = cx + rd * 0.12 + Double(w) / 2
        for k in 0..<3 {
            let y0 = cy - rd * 0.72 + Double(k) * rd * 0.17
            c.glowLine(sx - Double(w) * 1.2, y0 + Double(w) * 0.8, sx + Double(w) * 1.2, y0 - Double(w) * 0.4,
                       core: notch, glow: notch, coreR: max(0.5, Double(w) * 0.22), glowR: max(0.6, Double(w) * 0.25))
        }
    }

    /// One computer bank: lights, tape reels and a scope screen, stacked to its height.
    static func baxterBank(_ c: PixelCanvas, _ b: (x: Int, y: Int, w: Int, h: Int), s: Int) {
        c.rect(b.x, b.y, b.w, b.h, C(0x3A4660))
        c.rect(b.x, b.y, b.w, 3 * s, C(0x262E40)); c.rect(b.x, b.y + 3 * s, b.w, s, C(0x6A7A98))
        c.rect(b.x, b.y, s, b.h, C(0x5A6A88)); c.rect(b.x + b.w - s, b.y, s, b.h, C(0x262E40))
        c.rect(b.x + s, b.y + b.h - 4 * s, b.w - 2 * s, 4 * s, C(0x1E2432))
        for sec in baxterSections(b, s: s) {
            switch sec.kind {
            case 0:
                c.rect(b.x + s, sec.y, b.w - 2 * s, 9 * s, C(0x1A2030))
                for r in 0..<3 { for j in 0..<6 { c.rect(b.x + 2 * s + j * 2 * s, sec.y + 2 * s + r * 2 * s, s, s, C(0x34405A)) } }
            case 1:
                for dx in [5, 11] {
                    c.circle(b.x + dx * s, sec.y + 5 * s, 4 * s, C(0x1A2030))
                    c.circle(b.x + dx * s, sec.y + 5 * s, 3 * s, C(0xA8B4C8))
                    c.circle(b.x + dx * s, sec.y + 5 * s, 2 * s, C(0x4A5468))
                    c.rect(b.x + dx * s, sec.y + 5 * s, s, s, C(0xE8F0FF))
                }
                c.rect(b.x + 3 * s, sec.y + 10 * s, b.w - 6 * s, s, C(0x1A2030))
            default:
                c.rect(b.x + 2 * s, sec.y + s, b.w - 4 * s, 8 * s, C(0x7A88A4))
                c.rect(b.x + 3 * s, sec.y + 2 * s, b.w - 6 * s, 6 * s, C(0x0C1C16))
                c.rect(b.x + 3 * s, sec.y + 5 * s, b.w - 6 * s, max(1, s / 2), C(0x2AF08A, 0.25))
            }
        }
    }

    /// The portal: a heavy ring of machinery with lamps round it on a platform, the dark of the Negative Zone inside.
    static func baxterPortalDraw(_ c: PixelCanvas, _ g: Int) {
        let p = baxterPortal(c, g), s = unit(g) * scenes4Scale(c, g)
        c.circle(p.x, p.y, p.r + 8 * s, C(0x9A7AF0, 0.08))
        // supports and platform
        c.rect(p.x - p.r - 2 * s, p.y, 4 * s, g - p.y, C(0x2A3244))
        c.rect(p.x + p.r - 2 * s, p.y, 4 * s, g - p.y, C(0x2A3244))
        c.rect(p.x - p.r - 8 * s, g - 5 * s, (p.r + 8 * s) * 2, 5 * s, C(0x3A4458))
        c.rect(p.x - p.r - 8 * s, g - 5 * s, (p.r + 8 * s) * 2, s, C(0x8A98B4))
        for x in stride(from: p.x - p.r - 6 * s, to: p.x + p.r + 6 * s, by: 4 * s) {
            c.rect(x, g - 3 * s, 2 * s, 2 * s, C(0xE8C040))                              // hazard stripes
        }
        // the ring
        c.circle(p.x, p.y, p.r + 5 * s, C(0x1A1F2C))
        c.circle(p.x, p.y, p.r + 4 * s, C(0x6A7890))
        c.circle(p.x, p.y, p.r + 2 * s, C(0x3A4458))
        c.circle(p.x, p.y, p.r + s, C(0x20263A))
        for k in 0..<12 {
            let a = Double(k) * .pi / 6, rr = Double(p.r + 3 * s)
            c.rect(p.x + Int(cos(a) * rr) - s, p.y + Int(sin(a) * rr) - s, 2 * s, 2 * s, C(0x2A3448))
        }
        // the Negative Zone: a deep violet void with a scatter of green-white sparks
        for k in stride(from: p.r, to: 0, by: -max(1, p.r / 6)) {
            c.circle(p.x, p.y, k, lerp(C(0x3A1A5A), C(0x0A0614), Double(k) / Double(p.r)))
        }
        c.stars(p.y - p.r, p.y + p.r, density: 22, seed: 43, x0: p.x - p.r, x1: p.x + p.r) { x, y in
            (x - p.x) * (x - p.x) + (y - p.y) * (y - p.y) < (p.r - 2) * (p.r - 2)
        }
    }

    /// The portal swirls, the computers blink and scope lines wobble, and now and then the Fantasticar flies past.
    static func baxterLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), p = baxterPortal(c, g)
        // the swirl: four arms winding into a bright core
        let rr0 = Double(p.r - 2 * s), ps = s * scenes4Scale(c, g)
        for k in 0..<4 {
            let n = Int(rr0 * 4.5)
            for i in 0..<n {
                let f = Double(i) / Double(n), rr = rr0 * f
                let a = -t * 1.3 + Double(k) * .pi / 2 + f * 5.2
                let col = lerp(C(0xE8FFF0), k % 2 == 0 ? C(0x5AE08A) : C(0xA866F0), f * 1.3)
                c.rect(p.x + Int(cos(a) * rr), p.y + Int(sin(a) * rr), ps, ps, col.alpha(0.9 - f * 0.45))
            }
        }
        let core = max(2, Int(rr0 * (0.16 + 0.04 * sin(t * 4))))
        c.circle(p.x, p.y, core + 2 * s, C(0x9AF0C0, 0.25)); c.circle(p.x, p.y, core, C(0xE8FFF0, 0.75))
        for i in 0..<10 {                                                                 // sparks falling inward
            let f = 1 - scenes4Phase(t, 2.2, offset: noise(i + 70) * 2.2), a = noise(i + 80) * 6.3 + t * 0.6
            c.rect(p.x + Int(cos(a) * rr0 * f), p.y + Int(sin(a) * rr0 * f), ps, ps, C(0xE8FFF0, 0.8))
        }
        let chase = Int(t * 6)
        for k in 0..<12 where (k + chase) % 12 < 3 {                                      // chasing lamps on the ring
            let a = Double(k) * .pi / 6, rr = Double(p.r + 3 * ps)
            c.rect(p.x + Int(cos(a) * rr) - ps, p.y + Int(sin(a) * rr) - ps, 2 * ps, 2 * ps, C(0x9AE8FF))
        }
        // the computers
        let lamps = [C(0xFF5A4A), C(0x5AF08A), C(0xFFC84A), C(0x6AB8FF)]
        for (bi, b) in baxterBanks(c, g).enumerated() {
            for (si, sec) in baxterSections(b, s: s).enumerated() {
                if sec.kind == 0 {
                    for r in 0..<3 {
                        for j in 0..<6 {
                            let key = bi * 131 + si * 37 + r * 7 + j
                            let tick = Int(t * (1.5 + noise(key) * 2.5) + noise(key + 9) * 5)
                            guard noise(key * 17 + tick * 1009) > 0.5 else { continue }
                            c.rect(b.x + 2 * s + j * 2 * s, sec.y + 2 * s + r * 2 * s, s, s, lamps[Int(noise(key + 3) * 4) % 4])
                        }
                    }
                } else if sec.kind == 2 {
                    let x0 = b.x + 3 * s, wid = b.w - 6 * s, mid = sec.y + 5 * s
                    for x in stride(from: 0, to: wid, by: s) {
                        let v = sin(Double(x) / Double(s) * 0.9 + t * 5 + Double(bi)) * 2.2
                        c.rect(x0 + x, mid + Int(v) * s / 1 - s, s, s, C(0x5AFFA0))
                    }
                }
            }
        }
        // the Fantasticar, behind the glass
        let win = baxterWindow(c, g), e = baxterEmblem(c, g), mull = baxterMullions(c, g)
        let banksEnd = baxterBanks(c, g).last.map { $0.x + $0.w } ?? 0
        let speed = 46.0 * Double(s), travel = Double(c.w + 40 * s), dur = travel / speed, cycle = dur + 7
        let ph = scenes4Wrap(t + 2.5, cycle)
        guard ph < dur else { return }
        let x = Int(-20.0 * Double(s) + ph * speed)
        let y = win.top + (win.bottom - win.top) / 6 + Int(sin(ph * 1.1) * 2 * Double(s))
        let pr = p.r + 6 * ps
        let clip = { (px: Int, py: Int) -> Bool in
            guard px >= banksEnd, py > win.top, py < win.bottom else { return false }
            if (px - p.x) * (px - p.x) + (py - p.y) * (py - p.y) < pr * pr { return false }
            if (px - e.x) * (px - e.x) + (py - e.y) * (py - e.y) < e.r * e.r { return false }
            return !mull.contains { px >= $0 && px < $0 + 3 * s }
        }
        scenes4Stamp(c, x, y, [
            ".......w.....",
            "...bbbbbbbb..",
            "fbbbbbwwbbbbw",
            "..ggg...ggg..",
            "...y.....y...",
        ], ["b": C(0x2A5AC8), "w": C(0xE8EEF8), "g": C(0x8A94A8), "f": C(0xFFB04A),
            "y": C(0xFFD060, scenes4Phase(t, 0.2) < 0.5 ? 0.9 : 0.5)], s: s, clip: clip)
    }
}

// MARK: - Jotunheim

extension Scenes {
    /// The row where the far glacier mountains stand.
    static func jotunheimHorizon(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? g * 63 / 100 : g * 66 / 100 }

    /// Top row of the far mountain range at column `x`: sharp peaks from two folded sine waves.
    static func jotunheimRidge(_ c: PixelCanvas, _ g: Int, _ x: Int, amp k: Double = 0.4, shift: Double = 0) -> Int {
        let hz = jotunheimHorizon(c, g), fx = Double(x) / Double(unit(g))
        let v = jotunheimFold(fx, shift) + noise(Int(fx) / 3 + 7) * 0.06
        return hz - Int(Double(hz) * k * (0.25 + 0.75 * v))
    }

    /// The smooth shape of a mountain range (0…0.94) at unit column `fx`, without the rough edge.
    static func jotunheimFold(_ fx: Double, _ shift: Double) -> Double {
        (1 - abs(sin(fx * 0.017 + 0.6 + shift))) * 0.62 + (1 - abs(sin(fx * 0.043 + 2.1 + shift * 2))) * 0.32
    }

    /// Whether the mountain range's face at column `x` turns away from the light (it falls towards the right).
    static func jotunheimShaded(_ g: Int, _ x: Int, _ shift: Double) -> Bool {
        let fx = Double(x) / Double(unit(g))
        return jotunheimFold(fx + 1, shift) < jotunheimFold(fx - 1, shift)
    }

    /// The ruined ice palace's spires: left edge, width, top row, and whether the tip has broken off.
    static func jotunheimSpires(_ c: PixelCanvas, _ g: Int) -> [(x: Int, w: Int, top: Int, broken: Bool)] {
        let m = scenes4Scale(c, g), hz = jotunheimHorizon(c, g), cx = Int(Double(c.w) * 0.56)
        let specs: [(dx: Int, w: Int, h: Double, broken: Bool)] = [
            (-34, 6, 0.50, false), (-24, 8, 0.74, true), (-12, 7, 0.62, false), (-3, 10, 0.94, false),
            (10, 8, 0.70, true), (21, 6, 0.55, false), (30, 5, 0.38, true), (38, 4, 0.28, false),
        ]
        return specs.map { (x: cx + $0.dx * m, w: $0.w * m, top: hz - Int(Double(hz) * $0.h), broken: $0.broken) }
    }

    /// Top row of the black ice crags framing the scene at column `x`, or nil where there's none.
    static func jotunheimCrag(_ c: PixelCanvas, _ g: Int, _ x: Int) -> Int? {
        let s = unit(g), tall = isTall(c)
        let lw = Int(Double(c.w) * (tall ? 0.16 : 0.12)), rw = Int(Double(c.w) * (tall ? 0.13 : 0.10))
        let (f, seed): (Double, Int)
        if x < 0 || x >= c.w { return nil }
        if x < lw { (f, seed) = (Double(x) / Double(lw), 3) }
        else if x >= c.w - rw { (f, seed) = (Double(c.w - 1 - x) / Double(rw), 9) }
        else { return nil }
        let u = x / s
        let jag = abs(sin(Double(u) * 0.45 + Double(seed))) * Double(5 * s) + noise(u + seed * 50) * Double(2 * s)
        return Int(Double(g) * ((tall ? 0.10 : 0.06) + 0.8 * pow(f, 1.7))) + Int(jag)
    }

    /// Top row of a palace spire's column `k`: a sharp point, or a jagged slanting break.
    static func jotunheimSpireTip(_ p: (x: Int, w: Int, top: Int, broken: Bool), _ k: Int, m: Int) -> Int {
        p.broken ? p.top + p.w + (k * 3 / 2) + Int(noise(p.x + k) * Double(2 * m)) : p.top + abs(k * 2 - p.w) * 3 / 2
    }

    /// Highest thing standing at column `x` (the aurora stays behind it).
    static func jotunheimSkyTop(_ c: PixelCanvas, _ g: Int, _ x: Int, spires: [(x: Int, w: Int, top: Int, broken: Bool)]) -> Int {
        var top = jotunheimRidge(c, g, x, amp: isTall(c) ? 0.4 : 0.5)
        if let cr = jotunheimCrag(c, g, x) { top = min(top, cr) }
        let m = scenes4Scale(c, g)
        for sp in spires where x >= sp.x && x < sp.x + sp.w { top = min(top, jotunheimSpireTip(sp, x - sp.x, m: m)) }
        return top
    }

    /// Jotunheim, the frozen realm of the Frost Giants: a pale twilight sky (the aurora ripples across it), sharp
    /// glacier peaks, the blue face of a glacier, the broken spires and walls of the ruined ice palace, and jagged
    /// black ice crags framing a field of snow.
    static func jotunheim(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = jotunheimHorizon(c, g)
        c.gradient(0, hz, C(0x1A2644), C(0xCCD8E4), bands: 8)
        c.stars(0, hz / 3, density: tall ? 160 : 90, seed: 51)
        c.ellipse(Int(Double(c.w) * 0.8), hz - 2 * s, c.w / 5, max(3, hz / 8), C(0xF4F8FC, 0.18))
        // far glacier peaks, lit from the left
        for x in 0..<c.w {
            let top = jotunheimRidge(c, g, x, amp: isTall(c) ? 0.4 : 0.5), shade = jotunheimShaded(g, x, 0)
            c.rect(x, top, 1, hz - top, shade ? C(0x6884A8) : C(0xA8C2DA))
            if top < hz - hz / 4 { c.rect(x, top, 1, 2 * s, shade ? C(0xC8D8E8) : C(0xF2F8FC)) }
        }
        c.rect(0, hz - hz / 10, c.w, hz / 10, C(0xD8E4EE, 0.25))                     // mist in the valleys
        // nearer, darker range
        for x in 0..<c.w {
            let top = jotunheimRidge(c, g, x, amp: 0.2, shift: 1.7) + hz / 10
            let shade = jotunheimShaded(g, x, 1.7)
            c.rect(x, top, 1, hz - top + 2 * s, shade ? C(0x4A6A8E) : C(0x6A8CB0))
            c.px(x, top, C(0xD8E8F4))
        }
        jotunheimPalace(c, g)
        // the glacier's face: turquoise ice with crevasses
        let gy = hz, gh = max(3 * s, (g - hz) / 5)
        c.rect(0, gy, c.w, gh, C(0x5AA6D0))
        c.rect(0, gy, c.w, s, C(0xE0F2FA))
        for x in stride(from: 0, to: c.w, by: 3 * s) {
            let n = noise(x / s + 600)
            if n > 0.55 { c.rect(x, gy + s, s, gh - s, C(0x8AD4F0)) }
            else if n < 0.2 { c.rect(x, gy + s + Int(noise(x + 1) * Double(gh / 3)), s, gh, C(0x2A5A84)) }
        }
        // the snowfield
        c.rect(0, gy + gh, c.w, g - gy - gh, C(0xC4D6E6))
        c.dunes(base: gy + gh + (g - gy - gh) / 2, amp: Double(2 * s), freq: 0.03 / Double(s), phase: 1, bottom: g, C(0xD6E4F0),
                shade: C(0xEEF6FA))
        // the black ice crags
        for x in 0..<c.w {
            guard let top = jotunheimCrag(c, g, x) else { continue }
            c.rect(x, top, 1, g - top, C(0x121A26))
            c.rect(x, top, 1, s, C(0x6A8CB4))
        }
        for i in 0..<max(6, c.w * g / (900 * s)) {                                          // facets catching the light
            var x = Int(noise(i * 4 + 960) * Double(c.w)), y = Int(noise(i * 4 + 961) * Double(g))
            let dir = noise(i * 4 + 962) > 0.5 ? 1 : -1, len = (6 + Int(noise(i * 4 + 963) * 18)) * s
            for _ in 0..<len {
                guard let top = jotunheimCrag(c, g, x), y > top + s, y < g else { break }
                c.rect(x, y, 1, 1, C(0x2E4664)); c.px(x + dir, y, C(0x1A2636))
                y += 1; if y % 2 == 0 { x += dir }
            }
        }
        jotunheimDebris(c, g, from: gy + gh)
        // the snow floor, with blue shadows
        c.ground(g, C(0xD4E2EE), edge: C(0xF4FAFC), speck: C(0xB0C6DA), seed: 51)
        for i in 0..<max(3, c.w / 90) {
            c.ellipse(Int(noise(i + 900) * Double(c.w)), g + 2 + Int(noise(i + 901) * Double(max(1, c.h - g - 4))),
                      (8 + Int(noise(i + 902) * 16)) * s, max(1, s), C(0x9AB4D0, 0.35))
        }
    }

    /// Chunks of ice and broken pillars from the palace scattered over the snowfield, smaller further back.
    static func jotunheimDebris(_ c: PixelCanvas, _ g: Int, from y0: Int) {
        let s = unit(g), depth = g - y0 - 3 * s
        guard depth > 4 * s else { return }
        let n = max(4, c.w / (isTall(c) ? 50 : 70) / s)
        var items: [(x: Int, y: Int, r: Int, pillar: Bool)] = []
        for i in 0..<n {
            let f = noise(i * 5 + 1000), y = y0 + 2 * s + Int(f * Double(depth))
            let r = max(2, Int(Double(2 * s) + f * Double(depth) * 0.18))
            items.append((Int(noise(i * 5 + 1001) * Double(c.w)), y, r, noise(i * 5 + 1002) > 0.6))
        }
        for it in items.sorted(by: { $0.y < $1.y }) where jotunheimCrag(c, g, it.x) == nil {
            c.ellipse(it.x + it.r / 2, it.y, it.r * 2, max(1, it.r / 3), C(0x8AA6C4, 0.5))
            if it.pillar {
                let pw = max(2, it.r), ph = it.r * 2
                c.rect(it.x - pw / 2, it.y - ph, pw, ph, C(0x2C4668))
                c.rect(it.x - pw / 2, it.y - ph, max(1, pw / 3), ph, C(0x9ACCEA))
                for k in 0..<pw { c.rect(it.x - pw / 2 + k, it.y - ph - Int(noise(it.x + k) * Double(it.r)), 1, it.r, C(0x2C4668)) }
            } else {
                for k in 0..<(it.r * 2) {
                    let h = it.r * 2 - abs(k - it.r * 2 / 3) * 3 / 2 + Int(noise(it.x + k) * 2)
                    guard h > 0 else { continue }
                    c.rect(it.x - it.r + k, it.y - h, 1, h, k < it.r * 2 / 3 ? C(0xC8E4F4) : C(0x6A98C0))
                }
            }
        }
    }

    /// The ruined palace: a broken curtain wall and tall tapering spires of dark ice, their lit edges and slit windows.
    static func jotunheimPalace(_ c: PixelCanvas, _ g: Int) {
        let m = scenes4Scale(c, g), hz = jotunheimHorizon(c, g), sp = jotunheimSpires(c, g)
        guard let first = sp.first, let last = sp.last else { return }
        // the wall between the spires, crenellations knocked out in places
        let wy = hz - hz / 5
        c.rect(first.x - 4 * m, wy, last.x + last.w - first.x + 8 * m, hz - wy + 2 * m, C(0x22385A))
        c.rect(first.x - 4 * m, wy, last.x + last.w - first.x + 8 * m, m, C(0x7AA8D0))
        for x in stride(from: first.x - 4 * m, to: last.x + last.w + 4 * m, by: 4 * m) where noise(x / m + 300) > 0.35 {
            c.rect(x, wy - 2 * m, 2 * m, 2 * m, C(0x22385A))
        }
        for (i, x) in stride(from: first.x, to: last.x + last.w, by: 7 * m).enumerated() where i % 2 == 1 {
            c.rect(x, wy + 3 * m, 3 * m, 4 * m, C(0x0E1828)); c.rect(x + m, wy + 3 * m, m, m, C(0x7ADCF0, 0.5))
        }
        for p in sp {
            for k in 0..<p.w {
                let tip = jotunheimSpireTip(p, k, m: m)
                let col = k < m ? C(0x9ACCEA) : (k >= p.w - m ? C(0x182A44) : C(0x2C4668))
                c.rect(p.x + k, tip, 1, hz - tip + 2 * m, col)
            }
            for y in stride(from: p.top + p.w * 2, to: hz - 4 * m, by: 9 * m) where p.w >= 5 * m {
                c.rect(p.x + p.w / 2 - m / 2, y, max(1, m), 3 * m, C(0x7ADCF0, 0.6))
            }
        }
        // a fallen spire lying across the wall
        c.glowLine(Double(last.x + 6 * m), Double(hz - 2 * m), Double(last.x + 20 * m), Double(hz - 8 * m),
                   core: C(0x2C4668), glow: C(0x9ACCEA), coreR: Double(m) * 1.2, glowR: Double(m) * 1.8)
    }

    /// The aurora rippling behind the peaks, and snow drifting down.
    static func jotunheimLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), sp = jotunheimSpires(c, g)
        let top = tall ? g / 14 : 1, depth = g / 4
        for x in stride(from: 0, to: c.w, by: s) {
            let fx = Double(x) / Double(s)
            let wave = sin(fx * 0.02 + t * 0.35) * 0.5 + sin(fx * 0.053 - t * 0.6) * 0.3
            let base = top + depth / 2 + Int(wave * Double(depth) / 2.5)
            let len = Int(Double(depth) * (0.55 + 0.35 * sin(fx * 0.011 + t * 0.2)))
            let bright = 0.5 + 0.5 * sin(fx * 0.13 + t * 1.3 + sin(fx * 0.031) * 2)
            let a = 0.08 + 0.22 * bright
            let clip = jotunheimSkyTop(c, g, x, spires: sp)
            for k in 0..<4 {
                let y0 = base - len * (k + 1) / 4, y1 = min(base - len * k / 4, clip)
                if y1 > y0 {
                    c.rect(x, y0, s, y1 - y0, lerp(C(0x7AF0B8), C(0xB07AE8), Double(k) / 3).alpha(a * (1 - Double(k) * 0.22)))
                }
            }
            if base < clip { c.rect(x, base - s, s, s, C(0xC8FFE0, min(1, a * 1.8))) }
        }
        // snow
        let n = max(30, c.w * g / (260 * s * s))
        for i in 0..<n {
            let near = noise(i * 5 + 4) > 0.85
            let speed = (near ? 14 : 6) + noise(i * 5) * 6
            let y = Int(scenes4Wrap(noise(i * 5 + 1) * Double(c.h) + t * speed * Double(s), Double(c.h)))
            let x = Int(scenes4Wrap(noise(i * 5 + 2) * Double(c.w) + t * 4 * Double(s) + sin(t * 0.8 + Double(i)) * 3 * Double(s),
                                    Double(c.w)))
            c.rect(x, y, near ? 2 * s : s, near ? 2 * s : s, C(0xFFFFFF, near ? 0.9 : 0.6))
        }
    }
}

// MARK: - Muspelheim

extension Scenes {
    /// The row where the far mountains stand.
    static func muspelheimHorizon(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? g * 58 / 100 : g * 60 / 100 }

    /// Top row of the jagged far mountains at column `x`.
    static func muspelheimRidge(_ c: PixelCanvas, _ g: Int, _ x: Int) -> Int {
        let hz = muspelheimHorizon(c, g), fx = Double(x) / Double(unit(g))
        let a = pow(1 - abs(sin(fx * 0.023 + 0.3)), 1.6), b = pow(1 - abs(sin(fx * 0.061 + 1.2)), 2)
        let v = a * 0.6 + b * 0.32 + noise(Int(fx) / 2 + 70) * 0.08
        return hz - Int(Double(hz) * 0.36 * (0.2 + 0.8 * v))
    }

    /// Centre row of the lava river at column `x`, and its half-thickness.
    static func muspelheimRiver(_ c: PixelCanvas, _ g: Int, _ x: Int) -> (y: Int, th: Int) {
        let s = unit(g), hz = muspelheimHorizon(c, g), fx = Double(x) / Double(s)
        let y = hz + (g - hz) * 2 / 5 + Int(sin(fx * 0.018 + 0.7) * Double(max(2, (g - hz) / 10)))
        return (y, max(s + 1, (g - hz) / 14))
    }

    /// Where the lavafalls pour down the far mountains.
    static func muspelheimFalls(_ c: PixelCanvas, _ g: Int) -> [Int] {
        [0.17, 0.46, 0.61, 0.9].map { Int(Double(c.w) * $0) }
    }

    /// The Eternal Flame's cage: its centre, the row its base stands on and its scale.
    static func muspelheimCage(_ c: PixelCanvas, _ g: Int) -> (x: Int, base: Int, m: Int) {
        let m = scenes4Scale(c, g)
        return (Int(Double(c.w) * 0.74), g - 6 * m, m)
    }

    /// Muspelheim, Surtur's realm of fire: a burning sky thick with smoke where the fire demon's horned head looms,
    /// jagged black mountains with lava pouring down them, a river of lava winding through the black rock, a tall
    /// basalt spire, and the Eternal Flame burning inside its iron cage on a pedestal.
    static func muspelheim(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = muspelheimHorizon(c, g)
        c.gradient(0, hz, C(0x1A0806), C(0xE0561A), bands: 8)
        for i in 0..<(tall ? 14 : 7) {                                                   // banks of smoke
            let x = Int(noise(i * 7 + 500) * Double(c.w)), y = Int(Double(hz) * (0.08 + noise(i * 7 + 501) * 0.5))
            let rx = (20 + Int(noise(i * 7 + 502) * 40)) * s, ry = max(2, (3 + Int(noise(i * 7 + 503) * 4)) * s)
            c.ellipse(x, y + ry / 2, rx, ry, C(0xFF7A2A, 0.12))
            c.ellipse(x, y, rx, ry, C(0x2A0E0A, 0.4))
            c.ellipse(x - rx / 3, y - ry / 2, rx / 2, ry, C(0x2A0E0A, 0.25))
        }
        muspelheimSurtur(c, g)
        // far mountains, rimmed by the glow below
        for x in 0..<c.w {
            let top = muspelheimRidge(c, g, x)
            c.rect(x, top, 1, hz - top + s, C(0x2A1210))
            c.px(x, top, C(0xFF8A3A, 0.6))
        }
        c.rect(0, hz - hz / 8, c.w, hz / 8, C(0xFF6A1A, 0.12))
        for x in muspelheimFalls(c, g) {
            let top = muspelheimRidge(c, g, x) + 2 * s
            c.rect(x - 3 * s, top, 7 * s, hz - top, C(0xFF6A1A, 0.18))
            let fw = 2 * s * scenes4Scale(c, g)
            c.rect(x - fw / 2, top, fw, hz - top, C(0xFF7A1A)); c.rect(x, top, max(1, fw / 4), hz - top, C(0xFFC850))
            c.ellipse(x, hz, 6 * s, 2 * s, C(0xFFA040, 0.4))
        }
        // the black rock plain and the lava river through it
        c.rect(0, hz, c.w, g - hz, C(0x1E0E0C))
        c.dunes(base: hz + (g - hz) / 5, amp: Double(2 * s), freq: 0.04 / Double(s), phase: 2, bottom: g, C(0x170A08),
                shade: C(0x3A1A10))
        if tall {
            for i in 0..<5 {                                                              // pools of lava on the plain
                let x = Int(noise(i * 3 + 720) * Double(c.w)), y = hz + (g - hz) / 6 + Int(noise(i * 3 + 721) * Double((g - hz) / 6))
                let r = (6 + Int(noise(i * 3 + 722) * 10)) * s
                c.ellipse(x, y, r + 2 * s, max(1, r / 4 + s), C(0xFF5A1A, 0.25)); c.ellipse(x, y, r, max(1, r / 4), C(0xF0601A))
                c.ellipse(x - r / 4, y, r / 2, max(1, r / 8), C(0xFFB040))
            }
        }
        for x in 0..<c.w {
            let r = muspelheimRiver(c, g, x)
            c.rect(x, r.y - r.th - 2 * s, 1, r.th * 2 + 4 * s, C(0xFF4A10, 0.22))
            c.rect(x, r.y - r.th, 1, r.th * 2, C(0xF0601A))
            c.rect(x, r.y - r.th / 3, 1, max(1, r.th * 2 / 3), C(0xFFB040))
        }
        muspelheimRocks(c, g, count: tall ? 9 : 6, seed: 740, base: { x in
            let r = muspelheimRiver(c, g, x); return r.y - r.th - s
        }, size: tall ? 1.6 : 0.8)
        c.dunes(base: g - (g - hz) / 4, amp: Double(2 * s), freq: 0.05 / Double(s), phase: 4, bottom: g, C(0x120806),
                shade: C(0x4A1E10))
        muspelheimSpire(c, g, x: Int(Double(c.w) * 0.07), width: 16 * s, top: tall ? g / 4 : g / 6)
        muspelheimSpire(c, g, x: Int(Double(c.w) * 0.96), width: 12 * s, top: tall ? g * 2 / 5 : g / 3)
        muspelheimCageBase(c, g)
        muspelheimCageBars(c, g)
        // the floor: cracked basalt, glowing in the cracks
        c.ground(g, C(0x1E1412), edge: C(0x5A2A1A), speck: C(0x140C0A), seed: 61)
        for i in 0..<max(3, c.w / 70) {
            var x = Int(noise(i * 9 + 700) * Double(c.w)), y = g + 1 + Int(noise(i * 9 + 701) * Double(max(1, c.h - g - 3)))
            for k in 0..<(4 + Int(noise(i * 9 + 702) * 6)) {
                c.rect(x, y, s, s, C(0xFF6A1A, 0.7))
                x += s; if noise(i * 9 + k + 703) > 0.6 { y += noise(i + k) > 0.5 ? s : -s }
            }
        }
    }

    /// Surtur's head looming in the smoke: the vast horned crown and two burning eyes. Drawn solid on a scratch
    /// canvas first, so the overlapping shapes lay down one even veil of shadow.
    static func muspelheimSurtur(_ c: PixelCanvas, _ g: Int) {
        let hz = muspelheimHorizon(c, g), u = Double(hz) * 0.06, cx = Double(c.w) * 0.3, cy = Double(hz) - 6 * u
        let t = PixelCanvas(c.w, c.h), ink = C(0x000000)
        t.ellipse(Int(cx), Int(Double(hz) + u * 2), Int(u * 12), Int(u * 6), ink)          // shoulders
        t.ellipse(Int(cx), Int(cy), Int(u * 4.4), Int(u * 6), ink)                         // head
        t.ellipse(Int(cx), Int(cy + 4 * u), Int(u * 3.2), Int(u * 4), ink)                 // jaw
        t.rect(Int(cx - 5 * u), Int(cy - 3 * u), Int(10 * u), Int(2 * u), ink)             // the crown's band
        for side in [-1.0, 1.0] {
            let pts: [(Double, Double)] = [(3.5, -2.5), (6.5, -5), (8.2, -9), (8, -13), (6.2, -16.5), (4.4, -18)]
            for (k, p) in pts.dropFirst().enumerated() {
                let q = pts[k], steps = 10
                for j in 0..<steps {
                    let f = Double(j) / Double(steps), x = q.0 + (p.0 - q.0) * f, y = q.1 + (p.1 - q.1) * f
                    let r = max(0.35, 1.5 - (Double(k) + f) * 0.26) * u
                    t.circle(Int(cx + side * x * u), Int(cy + y * u), Int(r), ink)
                }
            }
        }
        for y in 0..<min(c.h, hz + Int(u * 8)) {
            for x in 0..<c.w where t.isDrawn(x, y) { c.px(x, y, C(0x2A0A06, 0.72)) }
        }
        for side in [-1.0, 1.0] {                                                          // the eyes, slanting
            let ex = Int(cx + side * 1.8 * u), ey = Int(cy - 0.2 * u), ew = max(2, Int(u * 1.6))
            c.ellipse(ex, ey, ew, max(1, ew / 2), C(0xFF8A2A, 0.2))
            for k in 0..<ew {
                let y = ey + (side < 0 ? k : ew - 1 - k) / 3
                c.rect(ex - ew / 2 + k, y, 1, max(1, Int(u * 0.5)), C(0xFFD060))
            }
        }
    }

    /// Jagged black rocks standing on row `base` along the river's banks, rimmed by the lava's glow.
    static func muspelheimRocks(_ c: PixelCanvas, _ g: Int, count: Int, seed: Int, base: (Int) -> Int, size: Double) {
        let s = unit(g)
        for i in 0..<count {
            let x0 = Int(noise(i * 5 + seed) * Double(c.w)), w = Int((8 + noise(i * 5 + seed + 1) * 14) * size) * s
            let h = Int((4 + noise(i * 5 + seed + 2) * 9) * size) * s
            for k in 0..<w {
                let f = Double(k) / Double(max(1, w)), b = base(x0 + k)
                let top = b - Int(Double(h) * (1 - pow(abs(f * 2 - 1), 1.3))) + Int(noise(k / s + i * 13 + seed) * Double(2 * s))
                guard top < b else { continue }
                c.rect(x0 + k, top, 1, b - top, C(0x120806))
                c.px(x0 + k, top, f < 0.5 ? C(0xFF7A2A, 0.6) : C(0x5A2414))
                c.rect(x0 + k, b - s, 1, s, C(0xFF5A1A, 0.5))
            }
        }
    }

    /// A tall spire of black rock with glowing veins.
    static func muspelheimSpire(_ c: PixelCanvas, _ g: Int, x: Int, width: Int, top: Int) {
        let s = unit(g)
        for k in 0..<width {
            let f = Double(k) / Double(width), edge = abs(f - 0.5) * 2
            let y = top + Int(pow(edge, 1.5) * Double(g - top) * 0.55) + Int(noise(k / s + x) * Double(3 * s))
            c.rect(x - width / 2 + k, y, 1, g - y, k < s ? C(0x5A2414) : C(0x140A08))
        }
        var vx = x, vy = top + 6 * s
        while vy < g - 2 * s {
            c.rect(vx, vy, s, 2 * s, C(0xFF6A1A, 0.75))
            vy += 2 * s; vx += Int(noise(vy + x) * 3) - 1
        }
    }

    /// The pedestal the cage stands on.
    static func muspelheimCageBase(_ c: PixelCanvas, _ g: Int) {
        let k = muspelheimCage(c, g), m = k.m
        c.circle(k.x, k.base - 12 * m, 18 * m, C(0xFF8A2A, 0.1))
        c.rect(k.x - 14 * m, g - 3 * m, 28 * m, 3 * m, C(0x2A1A16)); c.rect(k.x - 14 * m, g - 3 * m, 28 * m, m, C(0x6A3A22))
        c.rect(k.x - 11 * m, k.base, 22 * m, 3 * m, C(0x2A1A16)); c.rect(k.x - 11 * m, k.base, 22 * m, m, C(0x8A4A26))
        c.rect(k.x - 6 * m, k.base + m, 2 * m, m, C(0xFF6A1A, 0.8)); c.rect(k.x + 4 * m, k.base + 2 * m, 3 * m, m, C(0xFF6A1A, 0.6))
    }

    /// The cage's iron bars: a dome of curved bars and bands with a spiked crown (drawn again over the flame).
    static func muspelheimCageBars(_ c: PixelCanvas, _ g: Int) {
        let k = muspelheimCage(c, g), m = k.m, hw = 9 * m, hgt = 26 * m
        for bx in stride(from: -hw, through: hw, by: 3 * m) {
            let f = Double(bx) / Double(hw)
            let top = k.base - hgt + Int(f * f * Double(hgt) * 0.45)
            c.rect(k.x + bx, top, m, k.base - top, C(0x3A2420))
            c.rect(k.x + bx, top, m, k.base - top, (bx < 0 ? C(0xE08A3A) : C(0x6A3A26)).alpha(0.5))
        }
        for y in [k.base - m, k.base - hgt / 2] {
            let f = Double(k.base - y) / Double(hgt), half = Int(Double(hw) * (f > 0.6 ? 0.8 : 1)) + m
            c.rect(k.x - half, y, half * 2 + m, m, C(0x5A3424)); c.rect(k.x - half, y, half * 2 + m, max(1, m / 2), C(0xC87A3A))
        }
        c.rect(k.x - 2 * m, k.base - hgt - m, 5 * m, 2 * m, C(0x3A2420))
        c.rect(k.x, k.base - hgt - 5 * m, m, 4 * m, C(0x3A2420))
        c.rect(k.x - 3 * m, k.base - hgt - 3 * m, m, 2 * m, C(0x3A2420)); c.rect(k.x + 3 * m, k.base - hgt - 3 * m, m, 2 * m, C(0x3A2420))
    }

    /// Lava running down the river and the falls, embers rising, and the Eternal Flame flickering in its cage.
    static func muspelheimLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), hz = muspelheimHorizon(c, g)
        for x in stride(from: 0, to: c.w, by: s) {                                       // the river's flow
            let r = muspelheimRiver(c, g, x), fx = Double(x) / Double(s)
            let lane = Int(noise(x / s / 9 + 33) * 3) - 1
            if scenes4Wrap(fx - t * 9 + noise(x / s / 7) * 5, 19) < 3 {
                c.rect(x, r.y + lane * max(1, r.th / 2), s, s, C(0xFFE890, 0.9))
            }
            if scenes4Wrap(fx * 1.3 - t * 6, 31) < 2 { c.rect(x, r.y - r.th, s, s, C(0x6A1A0A, 0.6)) }   // crust
        }
        for (i, x) in muspelheimFalls(c, g).enumerated() {                                // the falls
            let top = muspelheimRidge(c, g, x) + 2 * s, len = hz - top
            guard len > 4 * s else { continue }
            for k in 0..<3 {
                let y = top + Int(scenes4Wrap(t * 14 * Double(s) + Double(k * len / 3 + i * 7), Double(len)))
                c.rect(x - s / 2, y, max(1, s), 2 * s, C(0xFFF0A0, 0.9))
            }
        }
        // embers
        let n = max(24, c.w * g / (500 * s * s))
        for i in 0..<n {
            let speed = (8 + noise(i * 3) * 14) * Double(s)
            let y = g - Int(scenes4Wrap(noise(i * 3 + 1) * Double(g) + t * speed, Double(g)))
            let x = Int(noise(i * 3 + 2) * Double(c.w) + sin(t * 1.3 + Double(i)) * 4 * Double(s))
            let flick = noise(i * 7 + Int(t * 8)) > 0.5
            c.rect(x, y, s, s, flick ? C(0xFFD060, 0.9) : C(0xFF6A1A, 0.8))
        }
        // the Eternal Flame
        let k = muspelheimCage(c, g), m = k.m, fy = k.base - 3 * m
        let sway = sin(t * 5) * Double(m), lick = Int(sin(t * 7.3) * 2 * Double(m))
        c.circle(k.x, fy - 8 * m, 12 * m, C(0xFFA040, 0.1 + 0.04 * sin(t * 9)))
        c.ellipse(k.x, fy - 6 * m, 6 * m, 9 * m + lick, C(0xF0501A))
        c.ellipse(k.x + Int(sway), fy - 12 * m - lick, 3 * m, 7 * m, C(0xF0501A))
        c.ellipse(k.x, fy - 5 * m, 4 * m, 6 * m, C(0xFFA030))
        c.ellipse(k.x - Int(sway), fy - 9 * m, 2 * m, 5 * m + lick / 2, C(0xFFA030))
        c.ellipse(k.x, fy - 3 * m, 2 * m, 4 * m, C(0xFFF0B0))
        for j in 0..<3 {                                                                   // licks breaking off the top
            let f = scenes4Phase(t, 0.7, offset: Double(j) * 0.23)
            let y = fy - 14 * m - Int(f * Double(10 * m)), x = k.x + Int(sin(t * 3 + Double(j) * 2) * Double(3 * m))
            c.rect(x, y, max(1, 2 * m * Int(1.5 - f)), 2 * m, C(0xFFC040, 0.9 * (1 - f)))
        }
        muspelheimCageBars(c, g)
    }
}

// MARK: - Hala

extension Scenes {
    /// The central tower that houses the Supreme Intelligence: centre column and the top of its dome.
    static func halaChamber(_ c: PixelCanvas, _ g: Int) -> (x: Int, top: Int) {
        (c.w / 2, isTall(c) ? g * 45 / 100 : g * 36 / 100)
    }

    /// Hala, the Kreek homeworld: a clean blue-green city of needle spires with ringed platforms and sky bridges under
    /// a teal sky and a great ringed planet, the stepped tower of the Supreme Intelligence's chamber at the centre with
    /// its green core glowing (the Intelligence's face hangs over it as a hologram), and a white plaza with Kreek banners.
    static func hala(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), m = scenes4Scale(c, g)
        c.gradient(0, g, C(0x0A1A38), C(0x6ACCC4), bands: 8)
        if tall { c.stars(0, g / 3, density: 150, seed: 71) }
        // the ringed planet and a small moon
        let pr = max(10, Int(Double(g) * (tall ? 0.15 : 0.22))), px = Int(Double(c.w) * 0.84), py = Int(Double(g) * (tall ? 0.2 : 0.24))
        let ring = { (front: Bool) in                                                     // the ring, tilted
            for k in 0..<(pr * 12) {
                let a = Double(k) / Double(pr * 12) * 2 * .pi
                guard (sin(a) > 0) == front else { continue }
                let rx = cos(a) * Double(pr) * 1.8, ry = sin(a) * Double(pr) * 0.32
                c.rect(px + Int(rx), py + Int(ry + rx * 0.22), max(1, s), max(1, s), C(0xE0F8F8, 0.75))
            }
        }
        c.circle(px, py, pr + 2 * s, C(0xA8F0F0, 0.08))
        ring(false)
        c.circle(px, py, pr, C(0x7ABCD0)); c.circle(px - pr / 4, py - pr / 4, pr * 3 / 4, C(0x9AD8E0))
        c.circle(px + pr / 3, py + pr / 4, pr * 3 / 4, C(0x2A5A7A, 0.35))
        ring(true)
        c.circle(Int(Double(c.w) * 0.1), g / 6, max(3, pr / 4), C(0xD8F0F0, 0.8))
        // far hazy towers
        var x = -2 * s, i = 0
        while x < c.w {
            let bw = (3 + Int(noise(i * 5 + 800) * 5)) * s, bh = Int(Double(g) * (0.22 + noise(i * 5 + 801) * 0.42))
            c.rect(x, g - bh, bw, bh, C(0x3E8C9C))
            c.rect(x + bw / 2, g - bh - 4 * s, max(1, s), 4 * s, C(0x3E8C9C))
            if noise(i * 5 + 802) > 0.5 { c.rect(x, g - bh + bh / 3, bw, s, C(0x9AF0E8, 0.5)) }
            x += bw + Int(noise(i * 5 + 803) * 6) * s; i += 1
        }
        c.rect(0, g * 3 / 4, c.w, g / 4, C(0x8ADCD4, 0.15))
        // the great spires, with bridges between neighbours
        let spires: [(f: Double, w: Int, h: Double)] = [
            (0.08, 7, 0.82), (0.2, 5, 0.6), (0.31, 8, 0.92), (0.4, 5, 0.55), (0.62, 6, 0.7), (0.7, 8, 0.96), (0.9, 6, 0.66),
        ]
        let pts = spires.map { (x: Int(Double(c.w) * $0.f), w: $0.w * m, top: g - Int(Double(g) * $0.h)) }
        for (a, b) in zip(pts, pts.dropFirst()) where b.x - a.x < c.w / 5 {
            let y = max(a.top, b.top) + (g - max(a.top, b.top)) / 3
            c.rect(a.x, y, b.x - a.x, 2 * s, C(0x24586A)); c.rect(a.x, y, b.x - a.x, max(1, s / 2), C(0xA8F0F0, 0.7))
        }
        for p in pts { halaSpire(c, g, x: p.x, w: p.w, top: p.top) }
        halaChamberDraw(c, g)
        // the plaza's parapet and the banners
        let py0 = g - 9 * s
        c.rect(0, py0, c.w, g - py0, C(0xC8DCE0)); c.rect(0, py0, c.w, s, C(0xF4FCFC))
        c.rect(0, py0 + 3 * s, c.w, s, C(0x5AE8D8, 0.8))
        for x in stride(from: 6 * s, to: c.w, by: 24 * s) { c.rect(x, py0 + 5 * s, 10 * s, 3 * s, C(0xA8C4CC)) }
        for bx in [12 * s, c.w - 16 * s] { halaBanner(c, g, x: bx, top: tall ? g / 2 : g / 4) }
        c.ground(g, C(0x9AB4BC), edge: C(0xE8F8F8), speck: C(0x8AA4AC), seed: 71)
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x6AE8D8, 0.35)) }
    }

    /// A needle spire: a white-edged teal shaft with lit bands, a ring platform two thirds up, tapering to a point.
    static func halaSpire(_ c: PixelCanvas, _ g: Int, x: Int, w: Int, top: Int) {
        let s = unit(g), taper = w * 3
        for k in 0..<w {
            let tip = top + abs(k * 2 - w) * taper / max(1, w)
            let col = k < max(1, w / 4) ? C(0xD8F8F8) : (k >= w - max(1, w / 4) ? C(0x163E50) : C(0x2A6478))
            c.rect(x - w / 2 + k, tip, 1, g - tip, col)
        }
        c.rect(x, top - 6 * s, max(1, s), 6 * s, C(0xD8F8F8))
        for y in stride(from: top + taper + 4 * s, to: g, by: 7 * s) { c.rect(x - w / 2 + s, y, w - 2 * s, s, C(0x7AF8E8, 0.75)) }
        let ry = top + (g - top) / 3
        c.ellipse(x, ry, w + 3 * s, max(1, s * 3 / 2), C(0x1E4E60)); c.rect(x - w - 3 * s, ry - s, (w + 3 * s) * 2, s, C(0xD8F8F8, 0.8))
    }

    /// The Supreme Intelligence's chamber: a stepped tower crowned by a dome with a glowing green core and an emitter.
    static func halaChamberDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), m = scenes4Scale(c, g), ch = halaChamber(c, g), x = ch.x
        let dome = 12 * m, steps = 4, base = g - 9 * s
        let stepH = max(2 * s, (base - ch.top - dome) / (steps + 1))
        for k in 0..<steps {
            let hw = dome + (k + 1) * 7 * m, y = ch.top + dome + k * stepH
            c.rect(x - hw, y, hw * 2, base - y, C(0x1E5064))
            c.rect(x - hw, y, hw * 2, s, C(0xD8F8F8)); c.rect(x - hw, y, s, base - y, C(0xA8E8EC))
            c.rect(x + hw - 2 * s, y, 2 * s, base - y, C(0x123848))
            for wx in stride(from: x - hw + 4 * s, to: x + hw - 3 * s, by: 5 * s) { c.rect(wx, y + stepH / 2, 2 * s, s, C(0x7AF8C8, 0.6)) }
        }
        c.ellipse(x, ch.top + dome, dome, dome, C(0x2A6A7A))
        c.ellipse(x - dome / 3, ch.top + dome * 2 / 3, dome / 3, dome / 3, C(0x8ADCE0, 0.6))
        c.circle(x, ch.top + dome + 2 * m, dome / 2 + 2 * m, C(0x5AF0A0, 0.25))
        c.circle(x, ch.top + dome + 2 * m, dome / 2, C(0x3ACC80)); c.circle(x, ch.top + dome + 2 * m, dome / 4, C(0xC8FFE0))
        c.rect(x - max(1, s / 2), ch.top - 4 * m, max(1, s), 4 * m, C(0xD8F8F8))
        c.rect(x - 2 * m, ch.top - 5 * m, 4 * m + 1, m, C(0x7AF8C8))
    }

    /// A pylon flying a Kreek banner: green and white with a diamond star.
    static func halaBanner(_ c: PixelCanvas, _ g: Int, x: Int, top: Int) {
        let s = unit(g) * scenes4Scale(c, g), bw = 8 * s, bh = min(26 * s, (g - top) * 2 / 3)
        c.rect(x, top - 3 * s, 2 * s, g - top + 3 * s, C(0xE0F0F0)); c.rect(x + s, top - 3 * s, s, g - top + 3 * s, C(0x9AB4BC))
        c.rect(x - bw / 2 + s, top, bw, bh, C(0x1E7A5A))
        c.rect(x - bw / 2 + s, top, s, bh, C(0xE8F8F0)); c.rect(x + bw / 2, top, s, bh, C(0xE8F8F0))
        c.rect(x - bw / 2 + s, top + bh, bw / 2, 2 * s, C(0x1E7A5A)); c.rect(x + s, top + bh, bw / 2, s, C(0x1E7A5A))
        let cy = top + bh / 3
        scenes4Stamp(c, x - 2 * s + s, cy - 2 * s, [
            "..w..",
            ".www.",
            "wwwww",
            ".www.",
            "..w..",
        ], ["w": C(0xE8F8F0)], s: s)
    }

    /// Air traffic gliding between the spires, and the Supreme Intelligence's hologram flickering over its chamber.
    static func halaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), ch = halaChamber(c, g)
        let lanes = tall ? 6 : 3
        for k in 0..<lanes {
            let y = Int(Double(g) * ((tall ? 0.16 : 0.18) + Double(k) * (tall ? 0.1 : 0.17)))
            let dir = k % 2 == 0 ? 1.0 : -1.0, speed = Double(14 + 7 * k) * Double(s)
            let span = Double(c.w + 20 * s)
            for j in 0..<max(2, c.w / (110 * s)) {
                let x = Int(scenes4Wrap(noise(k * 31 + j) * span + t * speed * dir, span)) - 10 * s
                let yy = y + Int(noise(k * 31 + j + 5) * 4) * s
                c.rect(x, yy, 6 * s, 2 * s, C(0xD8E8F0)); c.rect(x + s, yy + 2 * s, 4 * s, max(1, s / 2), C(0x6A8A98))
                c.rect(dir > 0 ? x + 5 * s : x, yy, s, s, C(0x6AF0E0))
                c.rect(dir > 0 ? x - 2 * s : x + 6 * s, yy + s, 2 * s, s, C(0x6AE0FF, 0.7))
                if scenes4Phase(t, 1, offset: noise(k + j * 3)) < 0.2 { c.rect(x + 3 * s, yy - s, s, s, C(0xFF6A6A)) }
            }
        }
        // the hologram: a projection beam and the Supreme Intelligence's tendrilled face
        let f = tall ? max(4, g * 4 / 290) : 1
        let rows = [
            "....gggggggg....",
            "..gggggggggggg..",
            ".gggGGGGGGGGggg.",
            "gggGGGGGGGGGGggg",
            "ggGGGGGGGGGGGGgg",
            "gGGeeeGGGGeeeGGg",
            "gGGGEGGGGGGEGGGg",
            "gGGGGGGGGGGGGGGg",
            "gGGGGGGnnGGGGGGg",
            ".GGGGGGnnGGGGGG.",
            ".gGGGGGGGGGGGGg.",
            "..GGGmmmmmmGGG..",
            "..gGGGGGGGGGGg..",
            "...gGGGGGGGGg...",
            "..g.gGGGGGGg.g..",
            ".g..g.gGGg.g..g.",
            "g..g..g..g..g..g",
            "...g.....g......",
        ]
        let fw = 16 * f, fx = ch.x - fw / 2, fy = tall ? g / 10 : 2
        let flick = 0.55 + 0.12 * sin(t * 7) - (noise(Int(t * 12)) > 0.88 ? 0.3 : 0)
        let beamTop = fy + 18 * f, beamBot = ch.top - 4 * scenes4Scale(c, g)
        if beamBot > beamTop {
            for y in beamTop..<beamBot {
                let k = Double(y - beamTop) / Double(beamBot - beamTop), half = Int(Double(fw / 2) * (1 - k))
                c.rect(ch.x - half, y, half * 2 + 1, 1, C(0x5AF0A0, 0.08 * flick))
            }
        }
        let scan = Int(t * 10)
        for (r, row) in rows.enumerated() {
            let glitch = noise(r + Int(t * 9) * 31) > 0.93 ? (noise(r + 7) > 0.5 ? 2 : -2) * f : 0
            let dim = (r + scan) % 4 == 0 ? 0.45 : 1
            let pal: [Character: Px] = [
                "g": C(0x2AB878, flick * dim * 0.8), "G": C(0x5AF0A0, flick * dim),
                "e": C(0xE8FFF0, min(1, flick * 1.4)), "E": C(0x0A3A24, flick), "n": C(0x2AB878, flick * dim),
                "m": C(0x1A6A48, flick),
            ]
            scenes4Stamp(c, fx + glitch, fy + r * f, [row], pal, s: f)
        }
    }
}

// MARK: - Genosha

extension Scenes {
    /// The sea's horizon row.
    static func genoshaHorizon(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? g * 3 / 5 : g * 52 / 100 }

    /// The headland the city stands on: where its plateau ends, where the cliff meets the sea, and its top row.
    static func genoshaCliff(_ c: PixelCanvas, _ g: Int) -> (plateauEnd: Int, foot: Int, top: Int) {
        let hz = genoshaHorizon(c, g)
        return (Int(Double(c.w) * 0.36), Int(Double(c.w) * 0.43), hz - max(3, hz / 9))
    }

    /// Genosha at sunset, the mutant nation: the sun going down into a calm sea, Hammer Bay's white towers crowding a
    /// headland, Magneto's statue in his helmet and cape on the cliff's edge, palms leaning over a stone terrace.
    static func genosha(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = genoshaHorizon(c, g)
        c.gradient(0, hz, C(0x2A2A66), C(0xFFB070), bands: 9)
        if tall { c.stars(0, hz / 5, density: 200, seed: 81) }
        let sr = max(7, hz / 4), sx = Int(Double(c.w) * 0.64), sy = hz - sr / 3
        c.circle(sx, sy, sr * 3, C(0xFFC890, 0.10)); c.circle(sx, sy, sr * 2, C(0xFFD8A0, 0.14))
        c.circle(sx, sy, sr, C(0xFFE8A8)); c.circle(sx, sy + sr / 2, sr - 1, C(0xFFD080))
        for i in 0..<(tall ? 9 : 5) {
            let y = Int(Double(hz) * (0.15 + noise(i * 4 + 850) * 0.7))
            wisp(c, Int(noise(i * 4 + 851) * Double(c.w)), y, (30 + Int(noise(i * 4 + 852) * 50)) * s,
                 lerp(C(0x8A5A9A), C(0xFF9A7A), Double(y) / Double(hz)).alpha(0.75), s: s)
        }
        // the sea, the sun's path across it
        c.gradient(hz, g, C(0xC08890), C(0x283A72), bands: 6)
        c.rect(0, hz, c.w, s, C(0xFFD8A8, 0.6))
        for (j, y) in stride(from: hz + s, to: g, by: 2 * s).enumerated() {
            let k = Double(y - hz) / Double(max(1, g - hz))
            let half = Int(Double(sr) * (0.6 + k * 1.2) * (0.6 + noise(j + 860) * 0.6))
            c.rect(sx - half, y, half * 2, s, C(0xFFD890, 0.7 - k * 0.4))
        }
        for i in 0..<(c.w * (g - hz) / (60 * s * s)) {
            let y = hz + 2 * s + Int(noise(i * 3 + 870) * Double(g - hz)), x = Int(noise(i * 3 + 871) * Double(c.w))
            c.rect(x, y, (2 + Int(noise(i * 3 + 872) * 4)) * s, max(1, s / 2), C(0x1A2A5A, 0.5))
        }
        genoshaHeadland(c, g)
        // the terrace: a low wall with posts, palms leaning over it
        let wy = g - 6 * s
        c.rect(0, wy, c.w, g - wy, C(0xC8A07A)); c.rect(0, wy, c.w, 2 * s, C(0xF0D4A8)); c.rect(0, wy + 2 * s, c.w, s, C(0x9A7458))
        for x in stride(from: 10 * s, to: c.w, by: 40 * s) {
            c.rect(x, wy - 2 * s, 5 * s, g - wy + 2 * s, C(0xD8B488)); c.rect(x, wy - 2 * s, 5 * s, s, C(0xF8E0B8))
            c.rect(x + 4 * s, wy - s, s, g - wy + s, C(0xA07A5A))
        }
        let ph = tall ? g / 2 : g * 3 / 5
        genoshaPalm(c, g, x: Int(Double(c.w) * 0.9), height: ph, lean: -1, seed: 1)
        genoshaPalm(c, g, x: Int(Double(c.w) * 0.97), height: ph * 4 / 5, lean: -1, seed: 2)
        genoshaPalm(c, g, x: Int(Double(c.w) * 0.5), height: ph * 3 / 5, lean: 1, seed: 3)
        c.ground(g, C(0xD8B890), edge: C(0xF4DCB4), speck: C(0xC4A27C), seed: 81)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0xC09C78)) }
    }

    /// The headland: a sunlit cliff, Hammer Bay's towers on top and Magneto's statue at its edge.
    static func genoshaHeadland(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), m = scenes4Scale(c, g), cl = genoshaCliff(c, g)
        // a far row of hazy towers, then the white towers themselves
        for i in 0..<Int(0.34 / 0.024) {
            let x = Int(Double(c.w) * (0.012 + Double(i) * 0.024)), w = (4 + Int(noise(i + 940) * 4)) * m
            let top = cl.top - Int(Double(cl.top) * (0.3 + noise(i + 941) * 0.4))
            c.rect(x - w / 2, top, w, cl.top - top, C(0xC4AEC4)); c.rect(x + w / 2 - m, top, m, cl.top - top, C(0xF0D4D0))
            c.ellipse(x, top, w / 2, max(1, w / 3), C(0xC4AEC4))
        }
        let specs: [(f: Double, w: Int, h: Double, kind: Int)] = [
            (0.025, 9, 0.5, 1), (0.06, 7, 0.86, 0), (0.1, 10, 0.62, 1), (0.142, 6, 1.0, 2), (0.18, 9, 0.74, 0),
            (0.222, 11, 0.48, 1), (0.258, 7, 0.82, 0), (0.29, 8, 0.58, 2), (0.322, 6, 0.4, 0),
        ]
        for sp in specs {
            let x = Int(Double(c.w) * sp.f), w = sp.w * m, top = cl.top - Int(Double(cl.top) * sp.h * 0.9)
            genoshaTower(c, g, x: x, w: w, top: top, base: cl.top + 2 * s, kind: sp.kind)
        }
        // low white houses along the cliff top
        var hx = 0, hi = 0
        while hx < cl.plateauEnd - 14 * m {
            let hw = (4 + Int(noise(hi + 960) * 4)) * m, hh = (2 + Int(noise(hi + 961) * 3)) * m
            c.rect(hx, cl.top - hh, hw, hh, C(0xF2E6DC)); c.rect(hx, cl.top - hh, max(1, m), hh, C(0xB8A4B8))
            c.rect(hx, cl.top - hh, hw, max(1, m / 2), C(0xFFF6EC))
            if noise(hi + 962) > 0.4 { c.rect(hx + hw / 2, cl.top - hh + m, max(1, m), max(1, m), C(0xFFD890)) }
            hx += hw + Int(noise(hi + 963) * 3) * m; hi += 1
        }
        // the cliff: scrub on top, warm rock darkening downward, lit on its sea-facing slope
        for x in 0..<cl.foot {
            let u = x / s
            let top = x < cl.plateauEnd ? cl.top + Int(abs(sin(Double(u) * 0.11)) * Double(s))
                : cl.top + (x - cl.plateauEnd) * (g - cl.top) / max(1, cl.foot - cl.plateauEnd) + Int(noise(u / 2 + 970) * Double(3 * s))
            let lit = x >= cl.plateauEnd - 2 * s
            for k in 0..<4 {
                let y0 = top + (g - top) * k / 4, y1 = top + (g - top) * (k + 1) / 4
                let col = lit ? lerp(C(0xF0B88A), C(0xA86A62), Double(k) / 3) : lerp(C(0xC88A78), C(0x5E3E52), Double(k) / 3)
                c.rect(x, y0, 1, y1 - y0, col)
            }
            if noise(u / 3 + 975) > 0.8 {
                let cy = top + 3 * s + Int(noise(u / 3 + 976) * Double(max(1, g - top - 6 * s)))
                c.rect(x, cy, 1, (4 + Int(noise(u / 3 + 977) * 8)) * s, C(0x4A2E44, 0.5))
            }
            if x < cl.plateauEnd {
                c.rect(x, top, 1, s, C(0x6A8A4A))
                if noise(u + 980) > 0.55 { c.rect(x, top - s, 1, 2 * s, C(0x3E5E3A)) }
            } else {
                c.px(x, top, C(0xFFE0B0))
            }
        }
        // terraces stepping down the cliff, with houses and gardens on each
        let step = 14 * m
        for k in 1..<64 {
            let y = cl.top + k * step, x1 = cl.plateauEnd - k * 12 * m
            guard y < g - 12 * s, x1 > 20 * m else { break }
            c.rect(0, y - 2 * m, x1, 2 * m, C(0x8A5A5E)); c.rect(0, y - 2 * m, x1, max(1, m / 2), C(0xF4D4B0))
            var hx = Int(noise(k + 990) * 6) * m, hi = k * 40
            while hx < x1 - 6 * m {
                let hw = (4 + Int(noise(hi + 991) * 5)) * m, hh = (3 + Int(noise(hi + 992) * 4)) * m
                if noise(hi + 993) > 0.3 {
                    c.rect(hx, y - 2 * m - hh, hw, hh, C(0xF0E2D8)); c.rect(hx, y - 2 * m - hh, max(1, m), hh, C(0xB8A0B4))
                    c.rect(hx, y - 2 * m - hh, hw, max(1, m / 2), C(0xFFF4E8))
                    if noise(hi + 994) > 0.4 { c.rect(hx + hw / 2, y - hh, max(1, m), max(1, m), C(0xFFD890)) }
                } else {
                    c.circle(hx + hw / 2, y - 4 * m, 2 * m, C(0x3A5A3A))
                    c.circle(hx + hw / 2 - m, y - 5 * m, m, C(0x5A7A4A))
                }
                hx += hw + Int(noise(hi + 995) * 3) * m; hi += 1
            }
        }
        // Magneto's statue near the edge
        let sx = cl.plateauEnd - 10 * m, pb = cl.top
        c.rect(sx - m, pb - 4 * m, 13 * m, 4 * m, C(0xE8DCD0)); c.rect(sx - m, pb - 4 * m, 13 * m, m, C(0xFFF4E4))
        c.rect(sx + 9 * m, pb - 4 * m, 3 * m, 4 * m, C(0xB8A8B0))
        scenes4Stamp(c, sx, pb - 4 * m - 17 * m, [
            "........a..",
            ".......ar..",
            "....hh.a...",
            "...hhhrr...",
            "...hffr....",
            "..cbbbbr...",
            ".ccbbbbrc..",
            ".ccbbbbcc..",
            "cccbbbbccc.",
            "ccc.bb.ccc.",
            "ccc.bb.ccr.",
            "cc..bb..cc.",
            "cc..bb..cr.",
            "cc..b.b.cc.",
            "c...b.b..c.",
            "c...b.b..c.",
            "...bb.bb...",
        ], ["a": C(0x4A3A48), "h": C(0x5A3A4A), "f": C(0x6A5058), "b": C(0x4A3A48), "c": C(0x6A2A3A),
            "r": C(0xFFB880)], s: m)
    }

    /// One of Hammer Bay's white towers: kind 0 a domed tower, 1 a stepped block, 2 a needle.
    static func genoshaTower(_ c: PixelCanvas, _ g: Int, x: Int, w: Int, top: Int, base: Int, kind: Int) {
        let s = unit(g), shade = C(0xB0A0BC), lit = C(0xFFF0E2), mid = C(0xE8DCDC)
        let body = { (bx: Int, bw: Int, by: Int) in
            c.rect(bx, by, bw, base - by, mid)
            c.rect(bx, by, max(1, bw / 3), base - by, shade)
            c.rect(bx + bw - max(1, bw / 4), by, max(1, bw / 4), base - by, lit)
            for (j, y) in stride(from: by + 3 * s, to: base - s, by: 3 * s).enumerated() {
                for (k, wx) in stride(from: bx + s, to: bx + bw - s, by: 2 * s).enumerated() where noise(bx * 7 + j * 13 + k) > 0.55 {
                    c.rect(wx, y, s, s, noise(bx + j + k * 5) > 0.5 ? C(0xFFD890) : C(0x8A7A9A))
                }
            }
        }
        switch kind {
        case 0:
            body(x - w / 2, w, top + w / 2)
            c.ellipse(x, top + w / 2, w / 2, w / 2, mid)
            c.ellipse(x - w / 6, top + w / 2, w / 3, w / 2 - s, shade.alpha(0.6))
            c.ellipse(x + w / 4, top + w / 3, max(1, w / 6), max(1, w / 6), lit)
            c.rect(x, top - 3 * s, max(1, s), 3 * s, mid)
        case 1:
            body(x - w / 2, w, top + (base - top) / 3)
            body(x - w / 3, w * 2 / 3, top + (base - top) / 6)
            body(x - w / 6, max(2 * s, w / 3), top)
        default:
            body(x - w / 4, max(2 * s, w / 2), top + w)
            for k in 0..<max(1, w / 2) {
                let tipTop = top + abs(k * 2 - w / 2) * 2
                c.rect(x - w / 4 + k, tipTop, 1, top + w - tipTop, k < w / 6 ? shade : lit)
            }
        }
    }

    /// A palm: a curving ringed trunk and drooping fronds, dark against the sunset with a warm rim.
    static func genoshaPalm(_ c: PixelCanvas, _ g: Int, x: Int, height: Int, lean: Int, seed: Int) {
        let s = unit(g), bend = Double(height) * 0.22 * Double(lean)
        var topX = x, topY = g - height
        for k in 0..<height {
            let f = Double(k) / Double(height), px = x + Int(sin(f * 1.3) * bend), py = g - k
            let tw = max(2 * s, Int(Double(3 * s) * (1 - f * 0.4)))
            c.rect(px - tw / 2, py, tw, 1, (k / (2 * s)) % 2 == 0 ? C(0x4A3028) : C(0x3A2420))
            c.px(px + tw / 2 - 1, py, C(0xC88A5A))
            topX = px; topY = py
        }
        for j in 0..<7 {
            let a = Double(j) / 6 * .pi * 1.1 - .pi * 1.05 + (noise(seed * 9 + j) - 0.5) * 0.4
            let len = Double(height) * (0.32 + noise(seed * 9 + j + 3) * 0.12)
            let n = Int(len)
            for i in 0..<n {
                let f = Double(i) / Double(n)
                let fx = Double(topX) + cos(a) * len * f, fy = Double(topY) + sin(a) * len * f * 0.6 + f * f * len * 0.55
                let th = max(1, Int(Double(2 * s) * (1 - f)) + s / 2)
                c.rect(Int(fx), Int(fy), max(1, s), th, C(0x1E3428))
                if i % (2 * s) == 0 { c.rect(Int(fx), Int(fy) + th, max(1, s), max(1, s * 2), C(0x1E3428, 0.7)) }
                if cos(a) > 0 { c.px(Int(fx), Int(fy), C(0xA8A050)) }
            }
        }
        c.circle(topX, topY + s, max(1, s * 3 / 2), C(0x5A3A20))
    }

    /// Waves glinting and curling at the cliff's foot, the sun's path shimmering, and gulls wheeling.
    static func genoshaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), hz = genoshaHorizon(c, g), cl = genoshaCliff(c, g)
        let wy = g - 6 * s
        let n = max(20, c.w * (wy - hz) / (90 * s * s))
        for i in 0..<n {                                                                   // glints drifting on the swell
            let k = noise(i * 4 + 1), y = hz + 2 * s + Int(k * Double(wy - hz - 2 * s))
            let x = Int(scenes4Wrap(noise(i * 4) * Double(c.w) - t * (3 + k * 6) * Double(s), Double(c.w)))
            guard x > cl.plateauEnd + (y - cl.top) * (cl.foot - cl.plateauEnd) / max(1, g - cl.top) else { continue }
            let a = 0.25 + 0.3 * sin(t * 2 + Double(i))
            c.rect(x, y, (2 + Int(k * 6)) * s, max(1, s / 2 + Int(k * 1.5)), C(0xFFE8D0, max(0, a)))
        }
        let sr = max(7, hz / 4), sx = Int(Double(c.w) * 0.64)
        for (j, y) in stride(from: hz + s, to: wy, by: 2 * s).enumerated() where noise(j + Int(t * 3) * 17) > 0.6 {
            let half = Int(Double(sr) * (0.4 + noise(j * 3 + Int(t * 3)) * 0.8))
            c.rect(sx - half, y, half * 2, s, C(0xFFF0C0, 0.6))
        }
        // surf at the cliff's foot
        for k in 0..<6 {
            let f = scenes4Phase(t, 3, offset: Double(k) * 0.5)
            let x = cl.plateauEnd + (cl.foot - cl.plateauEnd) * (k + 4) / 10 + Int(f * Double(4 * s))
            let y = cl.top + (x - cl.plateauEnd) * (g - cl.top) / max(1, cl.foot - cl.plateauEnd)
            guard y < wy else { continue }
            c.rect(x - 2 * s, y - Int(sin(f * .pi) * Double(3 * s)), 4 * s, s, C(0xFFF4E8, 0.8 * (1 - f)))
        }
        // gulls
        for i in 0..<(isTall(c) ? 6 : 3) {
            let speed = (10 + noise(i + 890) * 8) * Double(s), span = Double(c.w + 40 * s)
            let x = Int(scenes4Wrap(noise(i + 891) * span + t * speed, span)) - 20 * s
            let y = Int(Double(hz) * (0.25 + noise(i + 892) * 0.5) + sin(t * 0.7 + Double(i)) * 3 * Double(s))
            let up = sin(t * 7 + Double(i) * 2) > 0
            scenes4Stamp(c, x, y, up ? ["w...w", ".w.w.", "..w.."] : [".....", "wwbww", "w...w"],
                         ["w": C(0x2A2034), "b": C(0x2A2034)], s: s)
        }
    }
}
