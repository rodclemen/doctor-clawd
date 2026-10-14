import AppKit

/// Marvel's trips between places, in place of Star Wars' wipes: comic-book transitions, a different one each time.
enum ComicWipe: Int, CaseIterable {
    case halftone       // the new place prints in as halftone dots, sweeping left to right
    case burst          // a sound effect (`ComicSound`) covers the screen and clears away on the new place
    case panels         // the new place drops in as three comic panels
    case speedLines     // action lines rush in, a white flash, and the new place zooms out of it
    case meanwhile      // an iris closes, "MEANWHILE, IN …", and opens on the new place
    case fourthWall     // Deadpool only: he peels the old place off the screen like a page, talking to you
    case chimichanga    // Deadpool only: he surfs across on a giant chimichanga, the new place in his wake

    var duration: Double {
        switch self {
        case .halftone: return 1.4
        case .burst: return 1.6
        case .panels: return 1.5
        case .speedLines: return 1.3
        case .meanwhile: return 2.4
        case .fourthWall: return 3.2
        case .chimichanga: return 2.6
        }
    }
}

/// The sound effect a `.burst` makes, each in its own look: a sound of someone on screen, or KAPOW!.
enum ComicSound: CaseIterable {
    case kapow          // the classic yellow and red starburst
    case snikt          // Wolverine, X-23: three claw slashes tear the old place open
    case bamf           // Nightcrawler: a puff of purple smoke
    case krakatoom      // Thor: lightning
    case thoom          // Thor: lightning
    case thwip          // the Spider-People: a red web spreads out
    case baroom         // Hulk, the Thing: a green and orange blast with flying rubble

    var word: String {
        switch self {
        case .kapow: return "KAPOW!"
        case .snikt: return "SNIKT!"
        case .bamf: return "PHOOMF!"
        case .krakatoom: return "KRA-KA-BOOM!"
        case .thoom: return "THOOM!"
        case .thwip: return "FWIP!"
        case .baroom: return "BAROOM!"
        }
    }
}

/// One trip's transition, picked for who's on screen and where it's going. Shared by the window and the screen saver,
/// which hand over the old picture (frozen), the new one (as it is right now) and how far through it is; a frame is
/// drawn over the whole of `r`. Sizes are against an 800-pixel-tall frame.
struct ComicTrip {
    let kind: ComicWipe
    var sound = ComicSound.kapow
    var caption = ""
    var quip = ""
    var duration: Double { kind.duration }

    /// Any transition but the last one. A sound effect belongs to someone on screen if it can; Deadpool on screen
    /// brings his own two transitions (often: he hogs the spotlight) and sometimes his own caption.
    static func pick(after last: ComicWipe?, cast: [Cast], to place: Location) -> ComicTrip {
        let heroes = Set(cast.filter { $0.universe == .marvel && !$0.isDark }.compactMap { MarvelHero(rawValue: $0.index) })
        let deadpool = heroes.contains(.deadpool)
        var kinds: [ComicWipe] = [.halftone, .burst, .panels, .speedLines, .meanwhile]
        if deadpool { kinds += [.fourthWall, .fourthWall, .chimichanga, .chimichanga] }
        var trip = ComicTrip(kind: kinds.filter { $0 != last }.randomElement() ?? .halftone)
        trip.sound = heroes.flatMap { sounds[$0] ?? [] }.randomElement() ?? .kapow
        let name = place.name.uppercased()
        trip.caption = deadpool && Bool.random() ? deadpoolCaptions.randomElement()!(name) : "MEANWHILE, IN \(name)…"
        trip.quip = quips.randomElement()!
        return trip
    }

    private static let sounds: [MarvelHero: [ComicSound]] = [
        .wolverine: [.snikt], .x23: [.snikt],
        .nightcrawler: [.bamf],
        .thor: [.krakatoom, .thoom],
        .spiderMan: [.thwip], .milesMorales: [.thwip], .spiderGwen: [.thwip],
        .hulk: [.baroom], .thing: [.baroom],
    ]

    private static let deadpoolCaptions: [(String) -> String] = [
        { _ in "MEANWHILE, ON A SMALLER BUDGET…" },
        { "MEANWHILE, IN \($0) (THE WRITERS GOT BORED)…" },
        { _ in "MEANWHILE, AT THE CHIMICHANGA STAND…" },
        { "MEANWHILE, IN \($0). YES, AGAIN." },
    ]

    /// What Deadpool says to you while he changes the set.
    private static let quips = [
        "Psst. Yes, you. Hold on, I'll change the set.",
        "Budget cuts. I do the scene changes now.",
        "Ugh, this place again? Gimme a sec.",
        "Shouldn't you be coding instead of watching me?",
        "Don't mind me. Union-mandated scene change.",
        "Hi! Breaking the fourth wall. Again.",
        "Is this a screen saver? Am I a screen saver?!",
    ]

    // MARK: Drawing

    private static let ink = CGColor(red: 0.07, green: 0.06, blue: 0.08, alpha: 1)
    private static let yellow = CGColor(red: 1, green: 0.86, blue: 0.16, alpha: 1)
    private static let red = CGColor(red: 0.86, green: 0.12, blue: 0.14, alpha: 1)

    private static func ease(_ k: Double) -> Double { k * k * (3 - 2 * k) }
    private static func clamp(_ k: Double) -> Double { min(1, max(0, k)) }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, c = CGPoint(x: r.midX, y: r.midY)
        let ease = Self.ease, clamp = Self.clamp
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        switch kind {
        case .halftone:
            ctx.draw(old, in: r)
            let cell = 26 * s
            let path = CGMutablePath()
            let cols = Int(r.width / cell) + 2, rows = Int(r.height / cell) + 2
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = r.minX + CGFloat(col) * cell + (row % 2 == 0 ? 0 : cell / 2), y = r.minY + CGFloat(row) * cell
                    // Dots start on the left and sweep right, each growing from nothing to covering its cell.
                    let local = clamp(k * 1.6 - Double((x - r.minX) / r.width) * 0.6)
                    let d = cell * 0.75 * CGFloat(ease(local))
                    if d > 0.5 { path.addEllipse(in: CGRect(x: x - d, y: y - d, width: d * 2, height: d * 2)) }
                }
            }
            // Clipping to an empty path clips nothing, which flashed the whole new place up on the first frame.
            guard !path.isEmpty else { return }
            ctx.addPath(path); ctx.clip()
            ctx.draw(new, in: r)

        case .burst:
            drawSound(ctx, old: old, new: new, k: k, in: r)

        case .panels:
            ctx.draw(old, in: r)
            let gutter = 14 * s, w = r.width / 3
            for i in 0..<3 {
                let local = clamp((k - Double(i) * 0.18) / 0.46)
                guard local > 0 else { continue }
                let drop = CGFloat(1 - ease(local)) * r.height * 1.1 * (i % 2 == 0 ? 1 : -1)
                let tilt = CGFloat(1 - ease(local)) * (i == 1 ? -0.08 : 0.06)
                ctx.saveGState()
                ctx.translateBy(x: r.minX + w * CGFloat(i) + w / 2, y: r.midY + drop)
                ctx.rotate(by: tilt)
                let panel = CGRect(x: -w / 2, y: -r.height / 2, width: w, height: r.height)
                ctx.setFillColor(Self.ink); ctx.fill(panel)
                ctx.clip(to: panel.insetBy(dx: gutter / 2, dy: gutter / 2))
                ctx.draw(new, in: CGRect(x: -w / 2 - w * CGFloat(i), y: -r.height / 2, width: r.width, height: r.height))
                ctx.restoreGState()
            }
            // Once all three are down, the gutters close up.
            if k > 0.86 { ctx.setAlpha(CGFloat((k - 0.86) / 0.14)); ctx.draw(new, in: r); ctx.setAlpha(1) }

        case .speedLines:
            let zoom: CGFloat = k < 0.5 ? 1 + CGFloat(ease(k / 0.5)) * 0.35 : 1.35 - CGFloat(ease((k - 0.5) / 0.5)) * 0.35
            ctx.saveGState()
            ctx.clip(to: r)
            ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -c.x, y: -c.y)
            ctx.draw(k < 0.5 ? old : new, in: r)
            ctx.restoreGState()
            let strength = k < 0.5 ? ease(k / 0.5) : 1 - ease((k - 0.5) / 0.5)
            let far = hypot(r.width, r.height), inner = far * 0.53 * CGFloat(1 - strength)
            for i in 0..<90 {
                let a = CGFloat(noise(i * 3)) * 2 * .pi, wdt = 0.012 + 0.02 * CGFloat(noise(i * 3 + 1))
                let p = CGMutablePath()
                p.move(to: CGPoint(x: c.x + cos(a) * far, y: c.y + sin(a) * far))
                p.addLine(to: CGPoint(x: c.x + cos(a - wdt) * inner, y: c.y + sin(a - wdt) * inner))
                p.addLine(to: CGPoint(x: c.x + cos(a + wdt) * far, y: c.y + sin(a + wdt) * far))
                p.closeSubpath()
                ctx.addPath(p)
            }
            ctx.setFillColor(CGColor(gray: 0.05, alpha: 0.85)); ctx.fillPath()
            if strength > 0.85 { ctx.setFillColor(CGColor(gray: 1, alpha: CGFloat((strength - 0.85) / 0.15))); ctx.fill(r) }

        case .meanwhile:
            let maxR = hypot(r.width, r.height) / 2 + 10
            ctx.setFillColor(Self.ink); ctx.fill(r)
            let closing = k < 0.32, opening = k > 0.68
            let rad: CGFloat = closing ? maxR * CGFloat(1 - ease(k / 0.32)) : opening ? maxR * CGFloat(ease((k - 0.68) / 0.32)) : 0
            if rad > 1 {
                let iris = CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)
                ctx.saveGState()
                ctx.addEllipse(in: iris); ctx.clip()
                ctx.draw(closing ? old : new, in: r)
                ctx.restoreGState()
                ctx.addEllipse(in: iris)
                ctx.setStrokeColor(Self.ink); ctx.setLineWidth(10 * s); ctx.strokePath()
            }
            if k > 0.22 && k < 0.82 {
                var size = 38 * s
                func font() -> NSFont { NSFont(name: "AvenirNext-HeavyItalic", size: size) ?? .boldSystemFont(ofSize: size) }
                // Long captions (or a short window) get smaller type, so the box always fits.
                let room = r.width * 0.9 - 48 * s
                let width = NSAttributedString(string: caption, attributes: [.font: font()]).size().width
                if width > room { size *= room / width }
                let whole = NSAttributedString(string: caption, attributes: [.font: font()]).size()
                let shown = String(caption.prefix(Int(Double(caption.count) * clamp((k - 0.26) / 0.3))))
                let text = NSAttributedString(string: shown, attributes: [.font: font(), .foregroundColor: NSColor.black])
                let pad = 24 * s
                let box = CGRect(x: c.x - whole.width / 2 - pad, y: c.y - whole.height / 2 - pad / 2,
                                 width: whole.width + pad * 2, height: whole.height + pad)
                ctx.setFillColor(Self.yellow); ctx.fill(box)
                ctx.setStrokeColor(Self.ink); ctx.setLineWidth(5 * s); ctx.stroke(box)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
                text.draw(at: NSPoint(x: box.minX + pad, y: box.minY + pad / 2))
                NSGraphicsContext.restoreGraphicsState()
            }

        case .fourthWall:
            drawFourthWall(ctx, old: old, new: new, k: k, in: r)

        case .chimichanga:
            drawChimichanga(ctx, old: old, new: new, k: k, in: r)
        }
    }

    // MARK: Sound effects

    /// Each sound grows over the old place until it covers the screen, then clears away on the new one; SNIKT! tears
    /// the old place open instead.
    private func drawSound(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height)
        let ease = Self.ease, clamp = Self.clamp
        let grow = CGFloat(k < 0.5 ? ease(k / 0.5) : 1 - ease((k - 0.5) / 0.5))
        let word = sound.word
        func say(_ fill: CGColor, _ outline: CGColor, angle: CGFloat = -0.12) {
            Self.letters(ctx, word, at: c, size: (40 + 150 * grow) * s, maxWidth: r.width * 0.9, angle: angle,
                         fill: fill, outline: outline)
        }
        if sound != .snikt { ctx.draw(k < 0.5 ? old : new, in: r) }
        guard grow > 0.01 || sound == .snikt else { return }

        switch sound {
        case .kapow:
            let rad = grow * far * 0.62
            ctx.addPath(Self.starburst(c, r: rad * 1.04, seed: 3)); ctx.setFillColor(Self.ink); ctx.fillPath()
            ctx.addPath(Self.starburst(c, r: rad, seed: 3)); ctx.setFillColor(Self.yellow); ctx.fillPath()
            ctx.addPath(Self.starburst(c, r: rad * 0.7, seed: 5)); ctx.setFillColor(Self.red); ctx.fillPath()
            say(.white, Self.ink)

        case .snikt:
            // Three claw slashes rip across the old place, showing the new one through the tears, then open up.
            ctx.draw(old, in: r)
            let angle: CGFloat = -0.5, dir = CGPoint(x: cos(angle), y: sin(angle)), n = CGPoint(x: -dir.y, y: dir.x)
            let gap = r.height * 0.26
            let rip = CGFloat(ease(clamp(k / 0.3)))                           // how far along each slash has torn
            let open = CGFloat(ease(clamp((k - 0.55) / 0.45)))                // and how wide they gape at the end
            let half = r.height * 0.035 + open * far * 0.6
            var slashes: [CGPath] = []
            for i in -1...1 {
                let mid = CGPoint(x: c.x + n.x * gap * CGFloat(i), y: c.y + n.y * gap * CGFloat(i))
                let len = far * 0.62, from = -len, to = -len + 2 * len * rip
                let p = CGMutablePath(), steps = 24
                for j in 0...steps {
                    let d = from + (to - from) * CGFloat(j) / CGFloat(steps), u = (d + len) / (2 * len)
                    let w = half * sin(.pi * min(1, max(0, u)))
                    let pt = CGPoint(x: mid.x + dir.x * d + n.x * w, y: mid.y + dir.y * d + n.y * w)
                    j == 0 ? p.move(to: pt) : p.addLine(to: pt)
                }
                for j in stride(from: steps, through: 0, by: -1) {
                    let d = from + (to - from) * CGFloat(j) / CGFloat(steps), u = (d + len) / (2 * len)
                    let w = half * sin(.pi * min(1, max(0, u)))
                    p.addLine(to: CGPoint(x: mid.x + dir.x * d - n.x * w, y: mid.y + dir.y * d - n.y * w))
                }
                p.closeSubpath()
                slashes.append(p)
            }
            ctx.saveGState()
            for p in slashes { ctx.addPath(p) }
            ctx.clip()
            ctx.draw(new, in: r)
            ctx.restoreGState()
            // Adamantium gleam along the torn edges.
            for p in slashes {
                ctx.addPath(p); ctx.setStrokeColor(rgb(0x1B2A4A)); ctx.setLineWidth(9 * s); ctx.strokePath()
                ctx.addPath(p); ctx.setStrokeColor(rgb(0xDCE6F2)); ctx.setLineWidth(3.5 * s); ctx.strokePath()
            }
            let pop = CGFloat(k < 0.15 ? 0 : k < 0.3 ? ease((k - 0.15) / 0.15) : k < 0.7 ? 1 : 1 - ease((k - 0.7) / 0.2))
            if pop > 0.01 {
                Self.letters(ctx, word, at: CGPoint(x: c.x, y: c.y + r.height * 0.05), size: (60 + 120 * pop) * s,
                             maxWidth: r.width * 0.9, angle: 0.08, fill: rgb(0xFFD21F), outline: rgb(0x1E3A8A))
            }

        case .bamf:
            // A puff of brimstone smoke, rolling as it swells.
            let rad = grow * far * 0.55, spin = CGFloat(k) * 0.8
            let layers: [(UInt32, CGFloat, CGPoint)] = [(0x1E1236, 1.0, .zero), (0x3D2668, 0.82, CGPoint(x: -0.05, y: 0.05)),
                                                        (0x6A4BA3, 0.55, CGPoint(x: -0.1, y: 0.1))]
            for (hex, scale, off) in layers {
                let p = CGMutablePath(), base = rad * scale
                let o = CGPoint(x: c.x + off.x * rad, y: c.y + off.y * rad)
                p.addEllipse(in: CGRect(x: o.x - base * 0.75, y: o.y - base * 0.75, width: base * 1.5, height: base * 1.5))
                for i in 0..<14 {
                    let a = CGFloat(i) / 14 * 2 * .pi + spin, d = base * (0.55 + 0.2 * CGFloat(noise(i * 5 + 1)))
                    let pr = base * (0.3 + 0.18 * CGFloat(noise(i * 5 + 2)))
                    p.addEllipse(in: CGRect(x: o.x + cos(a) * d - pr, y: o.y + sin(a) * d - pr, width: pr * 2, height: pr * 2))
                }
                ctx.addPath(p); ctx.setFillColor(rgb(hex)); ctx.fillPath()
            }
            // Wisps trailing off the edge.
            for i in 0..<10 {
                let a = CGFloat(noise(i * 9)) * 2 * .pi - spin, d = rad * (0.95 + 0.25 * CGFloat(noise(i * 9 + 1)))
                let pr = rad * 0.07 * (1 + CGFloat(noise(i * 9 + 2)))
                ctx.setFillColor(rgb(0x2B1A4C, 0.85))
                ctx.fillEllipse(in: CGRect(x: c.x + cos(a) * d - pr, y: c.y + sin(a) * d - pr, width: pr * 2, height: pr * 2))
            }
            say(rgb(0xF3E9FF), rgb(0x12081F), angle: 0.1)

        case .krakatoom, .thoom:
            // A storm-blue flash with lightning forking out of it.
            let rad = grow * far * 0.62
            ctx.addPath(Self.starburst(c, r: rad * 1.05, n: 30, seed: 11, inner: 0.45)); ctx.setFillColor(rgb(0x0B1A4D)); ctx.fillPath()
            ctx.addPath(Self.starburst(c, r: rad, n: 30, seed: 11, inner: 0.45)); ctx.setFillColor(rgb(0x2F6BFF)); ctx.fillPath()
            ctx.addPath(Self.starburst(c, r: rad * 0.62, n: 30, seed: 13, inner: 0.55)); ctx.setFillColor(rgb(0xBFE3FF)); ctx.fillPath()
            let flicker = Int(k * 30)
            for i in 0..<7 where noise(i * 13 + flicker) > 0.25 {
                let a = CGFloat(noise(i * 13 + 7)) * 2 * .pi
                let bolt = CGMutablePath()
                var pt = c
                bolt.move(to: pt)
                for j in 1...7 {
                    let d = far * 0.75 * grow * CGFloat(j) / 7
                    let jag = (CGFloat(noise(i * 31 + j + flicker * 7)) - 0.5) * 0.5
                    pt = CGPoint(x: c.x + cos(a + jag) * d, y: c.y + sin(a + jag) * d)
                    bolt.addLine(to: pt)
                }
                ctx.addPath(bolt); ctx.setStrokeColor(rgb(0x5FA8FF, 0.8)); ctx.setLineWidth(14 * s); ctx.setLineJoin(.miter); ctx.strokePath()
                ctx.addPath(bolt); ctx.setStrokeColor(.white); ctx.setLineWidth(5 * s); ctx.strokePath()
            }
            if k > 0.44 && k < 0.56 { ctx.setFillColor(CGColor(gray: 1, alpha: CGFloat(1 - abs(k - 0.5) / 0.06) * 0.8)); ctx.fill(r) }
            say(.white, rgb(0x0B1A4D), angle: -0.06)

        case .thwip:
            // A red web, like the suit's, spinning out from the middle.
            let rad = grow * far * 0.6, spokes = 12, rings = 6, twist = CGFloat(k) * 0.5
            func spoke(_ i: Int, _ d: CGFloat) -> CGPoint {
                let a = CGFloat(i) / CGFloat(spokes) * 2 * .pi + twist
                return CGPoint(x: c.x + cos(a) * d, y: c.y + sin(a) * d)
            }
            func ring(_ d: CGFloat) -> CGPath {
                let p = CGMutablePath()
                p.move(to: spoke(0, d))
                for i in 1...spokes {     // each thread sags in towards the middle between spokes
                    let a = (CGFloat(i) - 0.5) / CGFloat(spokes) * 2 * .pi + twist
                    p.addQuadCurve(to: spoke(i, d), control: CGPoint(x: c.x + cos(a) * d * 0.82, y: c.y + sin(a) * d * 0.82))
                }
                p.closeSubpath()
                return p
            }
            ctx.addPath(ring(rad * 1.04)); ctx.setFillColor(rgb(0x1F3E9A)); ctx.fillPath()
            ctx.addPath(ring(rad)); ctx.setFillColor(rgb(0xD0202A)); ctx.fillPath()
            ctx.setStrokeColor(Self.ink); ctx.setLineWidth(3.5 * s)
            for i in 1...rings { ctx.addPath(ring(rad * CGFloat(i) / CGFloat(rings))) }
            for i in 0..<spokes { ctx.move(to: c); ctx.addLine(to: spoke(i, rad)) }
            ctx.strokePath()
            say(.white, rgb(0x1F3E9A), angle: -0.1)

        case .baroom:
            // A gamma blast: smoke, green, orange, a white-hot core, and rubble flying out.
            let rad = grow * far * 0.6
            let layers: [(UInt32, CGFloat)] = [(0x2E3A22, 1.0), (0x4FA83A, 0.84), (0xF08A24, 0.62), (0xFFE36A, 0.38)]
            for (n, (hex, scale)) in layers.enumerated() {
                let p = CGMutablePath(), base = rad * scale
                p.addEllipse(in: CGRect(x: c.x - base * 0.7, y: c.y - base * 0.7, width: base * 1.4, height: base * 1.4))
                for i in 0..<16 {
                    let a = CGFloat(i) / 16 * 2 * .pi + CGFloat(n) * 0.4, d = base * 0.62
                    let pr = base * (0.26 + 0.16 * CGFloat(noise(i * 7 + n * 50)))
                    p.addEllipse(in: CGRect(x: c.x + cos(a) * d - pr, y: c.y + sin(a) * d - pr, width: pr * 2, height: pr * 2))
                }
                ctx.addPath(p); ctx.setFillColor(rgb(hex)); ctx.fillPath()
            }
            for i in 0..<22 {
                let a = CGFloat(noise(i * 17)) * 2 * .pi, d = rad * (0.95 + 0.4 * CGFloat(noise(i * 17 + 1)))
                let size = rad * 0.05 * (0.6 + CGFloat(noise(i * 17 + 2)))
                ctx.saveGState()
                ctx.translateBy(x: c.x + cos(a) * d, y: c.y + sin(a) * d); ctx.rotate(by: CGFloat(k) * 6 + CGFloat(i))
                ctx.setFillColor(rgb(0x3B3530)); ctx.fill(CGRect(x: -size, y: -size * 0.7, width: size * 2, height: size * 1.4))
                ctx.restoreGState()
            }
            say(rgb(0x7BD14A), rgb(0x3A1A5E), angle: -0.14)
        }
    }

    // MARK: Deadpool

    /// Deadpool, `size` pixels a sprite pixel, his body's centre at `x` and his feet at `y`.
    private static func deadpool(_ ctx: CGContext, x: CGFloat, feet y: CGFloat, size: CGFloat, facingLeft: Bool, t: Double,
                                 walking: Bool) {
        let canvas = PixelCanvas(Sprite.width, Sprite.height)
        Cast.hero(.deadpool).draw(canvas, t: t, mode: .working, walking: walking, role: .none, asSession: false)
        canvas.addOutline(C(0x0A0A0A))
        guard let img = canvas.makeImage() else { return }
        ctx.saveGState()
        ctx.interpolationQuality = .none
        ctx.translateBy(x: x, y: y)
        if facingLeft { ctx.scaleBy(x: -1, y: 1) }
        // The body's centre is `Sprite.bodyCenterX` from the left, the feet 8 rows up from the bottom.
        ctx.draw(img, in: CGRect(x: -CGFloat(Sprite.bodyCenterX) * size, y: -8 * size,
                                 width: CGFloat(Sprite.width) * size, height: CGFloat(Sprite.height) * size))
        ctx.restoreGState()
    }

    /// A speech balloon (Deadpool's are yellow) with its tail pointing at `to`, kept on screen.
    private static func balloon(_ ctx: CGContext, _ text: String, to: CGPoint, in r: CGRect, s: CGFloat, alpha: CGFloat = 1) {
        guard alpha > 0.01 else { return }
        let size = 30 * s
        let font = NSFont(name: "AvenirNext-HeavyItalic", size: size) ?? .boldSystemFont(ofSize: size)
        let para = NSMutableParagraphStyle(); para.alignment = .center
        let str = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor.black, .paragraphStyle: para])
        let maxW = min(420 * s, r.width * 0.6)
        let fit = str.boundingRect(with: NSSize(width: maxW, height: 1000 * s), options: [.usesLineFragmentOrigin]).size
        let pad = 18 * s
        var box = CGRect(x: to.x - fit.width / 2 - pad, y: to.y + 46 * s, width: fit.width + pad * 2, height: fit.height + pad * 2)
        box.origin.x = min(max(box.minX, r.minX + 10 * s), r.maxX - box.width - 10 * s)
        box.origin.y = min(max(box.minY, r.minY + 10 * s), r.maxY - box.height - 10 * s)
        ctx.saveGState()
        ctx.setAlpha(alpha)
        let shape = CGMutablePath()
        shape.addRoundedRect(in: box, cornerWidth: box.height * 0.45, cornerHeight: box.height * 0.45)
        let base = CGPoint(x: min(max(to.x, box.minX + box.height * 0.5), box.maxX - box.height * 0.5), y: box.minY + 2)
        if to.y < box.minY {
            shape.move(to: CGPoint(x: base.x - 16 * s, y: base.y)); shape.addLine(to: to); shape.addLine(to: CGPoint(x: base.x + 16 * s, y: base.y))
        }
        ctx.addPath(shape); ctx.setFillColor(rgb(0xFFE45C)); ctx.fillPath()
        ctx.addPath(shape); ctx.setStrokeColor(ink); ctx.setLineWidth(4 * s); ctx.strokePath()
        ctx.setFillColor(rgb(0xFFE45C))
        ctx.fill(CGRect(x: base.x - 13 * s, y: base.y - 1, width: 26 * s, height: 5 * s))   // join the tail to the balloon
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        str.draw(with: CGRect(x: box.minX + pad, y: box.minY + pad, width: fit.width, height: fit.height), options: [.usesLineFragmentOrigin])
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }

    /// Deadpool climbs into the bottom-right corner, has a word with you, grabs the corner of the picture and peels the
    /// old place off the screen like a comic page, the new place underneath.
    private func drawFourthWall(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, ease = Self.ease, clamp = Self.clamp
        let corner = CGPoint(x: r.maxX, y: r.minY)
        let u = CGPoint(x: -0.7071, y: 0.7071)                            // from the corner towards the top left
        let reach = r.width * 0.7071 + r.height * 0.7071                  // the far corner's distance along `u`
        let fold = CGFloat(ease(clamp((k - 0.4) / 0.55))) * reach * 1.02   // how far the page has been peeled back
        func along(_ p: CGPoint) -> CGFloat { (p.x - corner.x) * u.x + (p.y - corner.y) * u.y }
        func flip(_ p: CGPoint) -> CGPoint { let d = 2 * (fold - along(p)); return CGPoint(x: p.x + u.x * d, y: p.y + u.y * d) }

        ctx.draw(new, in: r)
        let page = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
        let left = Self.cut(page) { along($0) - fold }                      // what's still stuck down
        let peeled = Self.cut(page) { fold - along($0) }                    // what's been lifted, folded back over
        if left.count > 2 {
            ctx.saveGState(); ctx.addPath(Self.polygon(left)); ctx.clip(); ctx.draw(old, in: r); ctx.restoreGState()
        }
        let tip = flip(corner)
        if peeled.count > 2 {
            let flap = peeled.map(flip)
            ctx.saveGState()
            ctx.clip(to: r)
            ctx.addPath(Self.polygon(flap.map { CGPoint(x: $0.x + 10 * s, y: $0.y - 10 * s) }))
            ctx.setFillColor(CGColor(gray: 0, alpha: 0.35)); ctx.fillPath()
            // The back of the page: the old place printed through the paper, mirrored and faint, shaded from the
            // fold (where it curls) to the corner Deadpool's holding.
            ctx.addPath(Self.polygon(flap)); ctx.clip()
            ctx.setFillColor(rgb(0xF3EEDD)); ctx.fill(r)
            ctx.saveGState()
            ctx.concatenate(CGAffineTransform(a: 1 - 2 * u.x * u.x, b: -2 * u.x * u.y, c: -2 * u.x * u.y, d: 1 - 2 * u.y * u.y,
                                              tx: 2 * u.x * (fold + corner.x * u.x + corner.y * u.y),
                                              ty: 2 * u.y * (fold + corner.x * u.x + corner.y * u.y)))
            ctx.setAlpha(0.18); ctx.draw(old, in: r)
            ctx.restoreGState()
            let foldAt = CGPoint(x: corner.x + u.x * fold, y: corner.y + u.y * fold)
            let shade = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: [rgb(0x8A7F66, 0.55), rgb(0xFFFFFF, 0.0), rgb(0xFFFFFF, 0.25)] as CFArray,
                                   locations: [0, 0.35, 1])!
            ctx.drawLinearGradient(shade, start: foldAt, end: tip, options: [])
            ctx.restoreGState()
            ctx.addPath(Self.polygon(flap)); ctx.setStrokeColor(Self.ink); ctx.setLineWidth(3 * s); ctx.strokePath()
        }

        // Deadpool: climbs up into the corner, talks, then hangs on to the corner of the page as he drags it.
        let size = r.height * 0.42 / CGFloat(Sprite.height)
        let climb = CGFloat(ease(clamp(k / 0.12)))
        let home = CGPoint(x: r.maxX - 34 * size, y: r.minY + 2 * size - (1 - climb) * 50 * size)
        let peeling = k > 0.4
        let at = peeling ? CGPoint(x: tip.x + 4 * size, y: tip.y - 30 * size) : home
        Self.deadpool(ctx, x: at.x, feet: at.y, size: size, facingLeft: true, t: k * kind.duration, walking: peeling)
        let talk = k < 0.08 ? 0 : k < 0.12 ? (k - 0.08) / 0.04 : k < 0.5 ? 1 : 1 - clamp((k - 0.5) / 0.08)
        Self.balloon(ctx, quip, to: CGPoint(x: at.x - 6 * size, y: at.y + 38 * size), in: r, s: s, alpha: CGFloat(talk))
    }

    /// Deadpool surfs across the screen on a giant chimichanga, yelling, the new place in his wake.
    private func drawChimichanga(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let len = r.height * 0.8, thick = len * 0.3
        let x = r.minX - len + (r.width + len * 2) * CGFloat(k)
        let y = r.minY + r.height * 0.3 + sin(CGFloat(k) * .pi * 3) * r.height * 0.07
        let tilt = sin(CGFloat(k) * .pi * 6) * 0.1 + 0.06

        // The wake: the new place behind the chimichanga's tail, with a crumbly edge.
        ctx.draw(old, in: r)
        let edge = x - len * 0.35
        let wake = CGMutablePath()
        wake.move(to: CGPoint(x: r.minX - 10, y: r.minY - 10))
        let steps = 40
        for i in 0...steps {
            let yy = r.minY + r.height * CGFloat(i) / CGFloat(steps)
            wake.addLine(to: CGPoint(x: edge + (CGFloat(noise(i * 3)) - 0.5) * 30 * s, y: yy))
        }
        wake.addLine(to: CGPoint(x: r.minX - 10, y: r.maxY + 10))
        wake.closeSubpath()
        ctx.saveGState(); ctx.addPath(wake); ctx.clip(); ctx.draw(new, in: r); ctx.restoreGState()

        // Crumbs and salsa flung off behind him, falling.
        for i in 0..<36 {
            let born = CGFloat(noise(i * 5))                                     // where along the run it came off
            let age = CGFloat(k) - born
            guard age > 0, age < 0.35 else { continue }
            let bx = r.minX - len + (r.width + len * 2) * born - age * r.width * 0.15
            let by = r.minY + r.height * 0.3 + thick * 0.4 + r.height * (0.25 * age - 3.2 * age * age) * CGFloat(1 + noise(i * 5 + 1))
            let sz = (5 + 9 * CGFloat(noise(i * 5 + 2))) * s
            ctx.setFillColor(i % 4 == 0 ? rgb(0xD62A1E) : rgb(0xE0A24E))
            ctx.fill(CGRect(x: bx, y: by, width: sz, height: sz))
        }
        // Speed streaks.
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.8)); ctx.setLineWidth(5 * s); ctx.setLineCap(.round)
        for i in 0..<4 {
            let yy = y + thick * (CGFloat(i) / 3 - 0.3)
            ctx.move(to: CGPoint(x: x - len * 0.6 - CGFloat(noise(i)) * 60 * s, y: yy))
            ctx.addLine(to: CGPoint(x: x - len * 1.1 - CGFloat(noise(i + 9)) * 140 * s, y: yy))
        }
        ctx.strokePath()

        // The chimichanga: deep-fried, blistered, a drizzle of sour cream and salsa on top.
        ctx.saveGState()
        ctx.translateBy(x: x, y: y); ctx.rotate(by: tilt)
        let body = CGRect(x: -len / 2, y: -thick / 2, width: len, height: thick)
        let shell = CGPath(roundedRect: body, cornerWidth: thick * 0.5, cornerHeight: thick * 0.5, transform: nil)
        ctx.addPath(shell); ctx.setFillColor(rgb(0xC9802F)); ctx.fillPath()
        ctx.saveGState(); ctx.addPath(shell); ctx.clip()
        ctx.setFillColor(rgb(0x9A5520)); ctx.fill(CGRect(x: body.minX, y: body.minY, width: len, height: thick * 0.3))
        ctx.setFillColor(rgb(0xE9AE5C)); ctx.fill(CGRect(x: body.minX, y: body.maxY - thick * 0.2, width: len, height: thick * 0.12))
        // The tortilla's wrap: a folded-over flap at each end, and the seam running along it.
        for end in [-1.0, 1.0] as [CGFloat] {
            let fx = end * (len / 2 - thick * 0.55)
            let flapPath = CGMutablePath()
            flapPath.move(to: CGPoint(x: fx - end * thick * 0.15, y: body.maxY))
            flapPath.addQuadCurve(to: CGPoint(x: fx + end * thick * 0.2, y: body.minY),
                                  control: CGPoint(x: fx + end * thick * 0.35, y: 0))
            ctx.addPath(flapPath); ctx.setStrokeColor(rgb(0x7A4016)); ctx.setLineWidth(5 * s); ctx.strokePath()
        }
        ctx.move(to: CGPoint(x: body.minX + thick * 0.6, y: body.minY + thick * 0.38))
        ctx.addCurve(to: CGPoint(x: body.maxX - thick * 0.6, y: body.minY + thick * 0.42),
                     control1: CGPoint(x: -len * 0.15, y: body.minY + thick * 0.3), control2: CGPoint(x: len * 0.15, y: body.minY + thick * 0.5))
        ctx.setStrokeColor(rgb(0x8A4A1A, 0.8)); ctx.setLineWidth(4 * s); ctx.strokePath()
        for i in 0..<26 {   // fried blisters
            let bx = body.minX + len * CGFloat(noise(i * 7 + 40)), by = body.minY + thick * CGFloat(noise(i * 7 + 41))
            let br = thick * (0.04 + 0.05 * CGFloat(noise(i * 7 + 42)))
            ctx.setFillColor(rgb(i % 3 == 0 ? 0xF0BC6C : 0xB97433))
            ctx.fillEllipse(in: CGRect(x: bx - br, y: by - br * 0.7, width: br * 2, height: br * 1.4))
        }
        ctx.restoreGState()
        ctx.addPath(shell); ctx.setStrokeColor(rgb(0x5A3212)); ctx.setLineWidth(4 * s); ctx.strokePath()
        let drizzle = CGMutablePath()
        drizzle.move(to: CGPoint(x: body.minX + thick * 0.4, y: body.maxY - thick * 0.12))
        for i in 1...9 {
            drizzle.addLine(to: CGPoint(x: body.minX + thick * 0.4 + (len - thick * 0.8) * CGFloat(i) / 9,
                                        y: body.maxY - thick * (i % 2 == 0 ? 0.12 : 0.3)))
        }
        ctx.addPath(drizzle); ctx.setStrokeColor(rgb(0xFFF8EC)); ctx.setLineWidth(7 * s); ctx.setLineJoin(.round); ctx.strokePath()
        for i in 0..<7 {
            ctx.setFillColor(rgb(0xD62A1E))
            let dx = body.minX + thick * 0.5 + (len - thick) * CGFloat(i) / 6
            ctx.fillEllipse(in: CGRect(x: dx - 6 * s, y: body.maxY - thick * 0.2, width: 12 * s, height: 9 * s))
        }

        // And Deadpool riding it, surfer stance.
        let size = r.height * 0.46 / CGFloat(Sprite.height)
        Self.deadpool(ctx, x: -len * 0.04, feet: body.maxY + 3 * size, size: size, facingLeft: false, t: k * kind.duration, walking: false)
        ctx.restoreGState()

        let head = CGPoint(x: x + cos(tilt + .pi / 2) * (thick / 2 + 40 * size), y: y + sin(tilt + .pi / 2) * (thick / 2 + 40 * size))
        let shout = k < 0.12 ? 0 : k < 0.18 ? (k - 0.12) / 0.06 : k < 0.85 ? 1 : 1 - Self.clamp((k - 0.85) / 0.08)
        Self.balloon(ctx, "CHIMICHANGAAAAA!", to: head, in: r, s: s, alpha: CGFloat(shout))
    }

    // MARK: Helpers

    /// The part of polygon `poly` where `side` is zero or more (one cut of Sutherland and Hodgman's clipping).
    private static func cut(_ poly: [CGPoint], keep side: (CGPoint) -> CGFloat) -> [CGPoint] {
        var out: [CGPoint] = []
        for (i, a) in poly.enumerated() {
            let b = poly[(i + 1) % poly.count], sa = side(a), sb = side(b)
            if sa >= 0 { out.append(a) }
            if (sa >= 0) != (sb >= 0) {
                let t = sa / (sa - sb)
                out.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
            }
        }
        return out
    }

    private static func polygon(_ pts: [CGPoint]) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: pts)
        p.closeSubpath()
        return p
    }

    /// Comic lettering, centred at `c`, tilted by `angle` radians, with a thick outline; never wider than `maxWidth`.
    private static func letters(_ ctx: CGContext, _ text: String, at c: CGPoint, size: CGFloat, maxWidth: CGFloat, angle: CGFloat,
                                fill: CGColor = .white, outline: CGColor = CGColor(gray: 0, alpha: 1)) {
        let fillColor = NSColor(cgColor: fill) ?? .white, lineColor = NSColor(cgColor: outline) ?? .black
        func strings(_ size: CGFloat) -> (NSAttributedString, NSAttributedString) {
            let font = NSFont(name: "Futura-CondensedExtraBold", size: size) ?? .systemFont(ofSize: size, weight: .black)
            return (NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: lineColor,
                                                                  .strokeColor: lineColor, .strokeWidth: 12]),
                    NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: fillColor]))
        }
        var (back, face) = strings(size)
        if face.size().width > maxWidth { (back, face) = strings(size * maxWidth / face.size().width) }
        let sz = face.size()
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: angle)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        back.draw(at: NSPoint(x: -sz.width / 2, y: -sz.height / 2))
        face.draw(at: NSPoint(x: -sz.width / 2, y: -sz.height / 2))
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }

    /// A jagged comic starburst round `c`, radius `r`, with `n` points dipping to `inner` of the way in.
    private static func starburst(_ c: CGPoint, r: CGFloat, n: Int = 18, seed: Int = 0, inner: CGFloat = 0.62) -> CGPath {
        let p = CGMutablePath()
        for i in 0..<(n * 2) {
            let a = CGFloat(i) / CGFloat(n * 2) * 2 * .pi + 0.1
            let k = i % 2 == 0 ? 1 : inner + 0.12 * CGFloat(noise(i + seed * 31))
            let rr = r * k * (0.9 + 0.2 * CGFloat(noise(i * 7 + seed)))
            let pt = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

/// A colour from 0xRRGGBB.
private func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
