import CoreGraphics

/// Doctor Clawd's trips between places, a different one each time, built on the show's own ways of getting somewhere:
/// the TARDIS dematerialising, and the title sequences of each era, from the 1963 howlaround to today's neon vortex.
/// Each era's comes up more often with its Doctors and companions on screen (and at its home turf). Blink and the
/// Dalick's eyestalk aren't the show's way of travelling, so they only come up when an Angle or a Dalick is about.
enum DoctorWipe: Int, CaseIterable {
    case dematerialise   // the police box wheezes out of the old place, and into the new one
    case howlaround      // 1963: the picture goes black and white and falls into its own TV feedback, out of which the new place rises
    case slitScan        // the 1970s: the old place stretches into a tunnel of coloured light rushing at you; the new one comes out of it
    case starfield       // the 1980s: the old place breaks up into stars; the new one comes out of deep space
    case vortex          // 2005: down the blue and orange time vortex, the TARDIS tumbling through it
    case explosive       // the 2010s: the old place shatters into spiralling shards round a cosmic blaze, and the new one reassembles
    case neon            // 2018 on: ribbons of rainbow light swirl the old place away and the new one in
    case regeneration    // golden fire pours out of the middle until it fills the screen, and dies down on the new place
    case blink           // the screen blinks, and an Angle stands closer each time; the last blink opens on the new place
    case eyestalk        // the view through a Dalick's eye: its lens closes on the old place and opens on the new one

    var duration: Double {
        switch self {
        case .dematerialise: return 2.4
        case .howlaround: return 2.4
        case .slitScan: return 2.0
        case .starfield: return 2.2
        case .vortex: return 2.2
        case .explosive: return 2.0
        case .neon: return 2.1
        case .regeneration: return 2.0
        case .blink: return 2.4
        case .eyestalk: return 1.9
        }
    }

    /// Only with one of its owners on screen (or at its turf): Blink and the eyestalk.
    var needsOwner: Bool { self == .blink || self == .eyestalk }

    /// Whose it is: with one of them on screen it comes up more often.
    func isOwned(by c: Cast) -> Bool {
        guard c.universe == .doctor else { return false }
        if c.isDark {
            guard let v = DoctorVillain(rawValue: c.index) else { return false }
            switch self {
            case .blink: return v == .weepingAngle
            case .eyestalk: return v.isDalick || v == .davross
            default: return false
            }
        }
        guard let h = DoctorHero(rawValue: c.index) else { return false }
        switch self {
        case .dematerialise: return h.isDoctor || h == .hem
        case .regeneration: return h.isDoctor
        case .howlaround: return [.doctorOne, .doctorTwo, .susan, .ian, .barbara, .jamie, .zoe].contains(h)
        case .slitScan: return [.doctorThree, .doctorFour, .brigadier, .jo, .sarahJane, .leelah, .kCanine, .romanah].contains(h)
        case .starfield: return [.doctorFive, .doctorSix, .doctorSeven, .doctorEight, .nyssa, .tegan, .pery, .mel, .ace].contains(h)
        case .vortex: return [.doctorNine, .doctorTen, .warDoctor, .rose, .jack, .martha, .donna, .wilf].contains(h)
        case .explosive: return [.doctorEleven, .doctorTwelve, .amy, .rory, .river, .clara, .vasta, .jenny, .stracks,
                                 .bill, .nardoll].contains(h)
        case .neon: return [.doctorThirteen, .doctorFourteen, .doctorFifteen, .fugitiveDoctor, .yaz, .graham, .ryan, .dan,
                            .ruby, .belinda, .kate, .osgoode].contains(h)
        case .blink, .eyestalk: return false
        }
    }

    /// Its home turf: a trip there brings it up more often too.
    var turf: [Location] {
        switch self {
        case .howlaround: return [.tottersYard]
        case .slitScan: return [.unitHQ, .gallifray]
        case .vortex: return [.powellEstate, .satelliteFive, .badWolfBay]
        case .eyestalk: return [.skarro, .dalickAsylum]
        default: return []
        }
    }
}

/// One trip's transition. Shared by the window and the screen saver, which hand over the old picture (frozen), the new
/// one (as it is right now) and how far through it is; a frame is drawn over the whole of `r`. Sizes are against an
/// 800-pixel-tall frame.
struct DoctorTrip {
    let kind: DoctorWipe
    var duration: Double { kind.duration }

    /// Any transition but the last one, those of whoever's on screen and of the place it's going to weighted up.
    static func pick(after last: DoctorWipe?, cast: [Cast], to place: Location) -> DoctorTrip {
        var kinds: [DoctorWipe] = []
        for kind in DoctorWipe.allCases where kind != last {
            let owned = cast.contains(where: kind.isOwned), home = kind.turf.contains(place)
            if kind.needsOwner && !owned && !home { continue }
            kinds.append(kind)
            if owned { kinds += [kind, kind, kind] }
            if home { kinds += [kind, kind] }
        }
        return DoctorTrip(kind: kinds.randomElement() ?? .dematerialise)
    }

    // MARK: Drawing

    private static func ease(_ k: Double) -> Double { k * k * (3 - 2 * k) }
    private static func clamp(_ k: Double) -> Double { min(1, max(0, k)) }
    /// How far `k` is through `a…b`: 0 before, 1 after.
    private static func span(_ k: Double, _ a: Double, _ b: Double) -> Double { clamp((k - a) / (b - a)) }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        switch kind {
        case .dematerialise: drawDematerialise(ctx, old: old, new: new, k: k, in: r)
        case .howlaround: drawHowlaround(ctx, old: old, new: new, k: k, in: r)
        case .slitScan: drawSlitScan(ctx, old: old, new: new, k: k, in: r)
        case .starfield: drawStarfield(ctx, old: old, new: new, k: k, in: r)
        case .vortex: drawVortex(ctx, old: old, new: new, k: k, in: r, neon: false)
        case .explosive: drawExplosive(ctx, old: old, new: new, k: k, in: r)
        case .neon: drawVortex(ctx, old: old, new: new, k: k, in: r, neon: true)
        case .regeneration: drawRegeneration(ctx, old: old, new: new, k: k, in: r)
        case .blink: drawBlink(ctx, old: old, new: new, k: k, in: r)
        case .eyestalk: drawEyestalk(ctx, old: old, new: new, k: k, in: r)
        }
    }

    /// `img` drawn centred on `c`, turned `turn` radians and scaled `scale`, over a frame the size of `r`.
    private static func picture(_ ctx: CGContext, _ img: CGImage, in r: CGRect, at c: CGPoint, scale: CGFloat, turn: CGFloat = 0,
                                alpha: CGFloat = 1) {
        guard scale > 0.003, alpha > 0.01 else { return }
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: turn); ctx.scaleBy(x: scale, y: scale)
        ctx.setAlpha(alpha)
        ctx.draw(img, in: CGRect(x: -r.width / 2, y: -r.height / 2, width: r.width, height: r.height))
        ctx.restoreGState()
    }

    /// The police box on its own, `height` tall, its lamp lit or not, outlined, for flying through tunnels.
    private static func policeBox(lamp: Bool) -> CGImage? {
        let c = PixelCanvas(28, 26)
        drawPoliceBoxIcon(c)
        if !lamp { c.rect(12, 2, 4, 2, C(0x8A94A8)) }
        c.addOutline(C(0xFFFFFF, 0.85))
        return c.makeImage()
    }

    // MARK: The howlaround (1963)

    /// The picture drains to black and white and starts to feed back on itself: copies of it nested ever smaller and
    /// turning, rippling like a camera pointed at its own monitor, the tunnel deepening until the old place is lost in
    /// it. The new place rises out of the same feedback, still in black and white, and its colour comes back last.
    private func drawHowlaround(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let c = CGPoint(x: r.midX, y: r.midY)
        let grey = Self.span(k, 0, 0.15) * (1 - Self.span(k, 0.85, 1))
        let depth = sin(.pi * Self.span(k, 0.1, 0.9))
        let img = k < 0.5 ? old : new
        ctx.setFillColor(rgb(0x050505)); ctx.fill(r)
        // The feedback: the picture, then smaller copies of itself inside it, each turned and drifting a little further.
        let layers = 9
        for i in 0..<layers {
            let f = Double(i) / Double(layers)
            let scale = CGFloat(1 - depth * f * 0.92)
            let wob = sin(k * 9 + Double(i) * 0.9) * depth
            let turn = CGFloat(depth * f * 1.4 + wob * 0.05)
            let off = CGPoint(x: c.x + CGFloat(wob * 14 * f) * r.height / 800, y: c.y + CGFloat(cos(k * 7 + Double(i)) * depth * 10 * f) * r.height / 800)
            let a = CGFloat(i == 0 ? 1 : depth * (0.85 - f * 0.4))
            Self.picture(ctx, img, in: r, at: off, scale: scale, turn: turn, alpha: a)
            // Each copy's edge glows, like the bright rim of a monitor.
            if i > 0 && depth > 0.05 {
                ctx.saveGState()
                ctx.translateBy(x: off.x, y: off.y); ctx.rotate(by: turn); ctx.scaleBy(x: scale, y: scale)
                ctx.setStrokeColor(rgb(0xFFFFFF, 0.35 * depth * (1 - f))); ctx.setLineWidth(10)
                ctx.stroke(CGRect(x: -r.width / 2, y: -r.height / 2, width: r.width, height: r.height))
                ctx.restoreGState()
            }
        }
        // Black and white, with the glow of an old tube.
        ctx.saveGState()
        ctx.setBlendMode(.saturation); ctx.setFillColor(rgb(0x808080, CGFloat(grey))); ctx.fill(r)
        ctx.restoreGState()
        ctx.setFillColor(rgb(0xFFFFFF, 0.08 * depth)); ctx.fill(r)
        // Scan lines and the odd rolling bar.
        let s = r.height / 800
        for y in stride(from: r.minY, to: r.maxY, by: 4 * s) {
            ctx.setFillColor(rgb(0x000000, 0.22 * grey)); ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 1.5 * s))
        }
        let bar = r.minY + r.height * CGFloat(1 - (k * 1.7).truncatingRemainder(dividingBy: 1))
        ctx.setFillColor(rgb(0xFFFFFF, 0.1 * depth)); ctx.fill(CGRect(x: r.minX, y: bar, width: r.width, height: 40 * s))
    }

    // MARK: The slit-scan tunnel (1970s)

    /// The old place rushes at you and smears into streaks of coloured light, a tunnel of them pouring out of a point
    /// in the middle (orange, magenta, violet, blue, in bands); at the far end of it the new place appears and comes on
    /// until it fills the screen.
    private func drawSlitScan(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height) / 2
        let tunnel = sin(.pi * Self.span(k, 0.08, 0.92))
        ctx.setFillColor(rgb(0x0A0618)); ctx.fill(r)
        // The old place, zooming at you, smeared by copies of itself.
        let go = Self.span(k, 0, 0.45)
        for i in stride(from: 5, through: 0, by: -1) {
            let z = CGFloat(1 + go * 2.2 + Double(i) * go * 0.18)
            Self.picture(ctx, old, in: r, at: c, scale: z, alpha: CGFloat((1 - go) * (i == 0 ? 1 : 0.25)))
        }
        // The streaks: thin wedges from the middle out, in moving bands of colour.
        let colours: [UInt32] = [0xFF8A2A, 0xFF3A8A, 0x9A4AFF, 0x3A8AFF, 0x3AE8C8, 0xFFD23A]
        for i in 0..<90 {
            let a = Double(i) / 90 * 2 * .pi + noise(i) * 0.05
            let d = (noise(i * 3) + k * 3.2).truncatingRemainder(dividingBy: 1)
            let r0 = CGFloat(d * d) * far, r1 = r0 + CGFloat(0.12 + d * 0.5) * far
            let w = 0.004 + 0.012 * d
            ctx.move(to: CGPoint(x: c.x + cos(a - w) * r0, y: c.y + sin(a - w) * r0))
            ctx.addLine(to: CGPoint(x: c.x + cos(a - w * 2) * r1, y: c.y + sin(a - w * 2) * r1))
            ctx.addLine(to: CGPoint(x: c.x + cos(a + w * 2) * r1, y: c.y + sin(a + w * 2) * r1))
            ctx.addLine(to: CGPoint(x: c.x + cos(a + w) * r0, y: c.y + sin(a + w) * r0))
            ctx.closePath()
            let band = colours[(i / 3 + Int(k * 12)) % colours.count]
            ctx.setFillColor(rgb(band, CGFloat(tunnel * (0.35 + 0.65 * d)))); ctx.fillPath()
        }
        // The glow at the far end, and the new place coming out of it.
        let core = CGFloat(tunnel) * r.height * 0.18
        ctx.saveGState(); ctx.setShadow(offset: .zero, blur: core, color: rgb(0xFFF2D8, tunnel))
        ctx.setFillColor(rgb(0xFFF8EE, tunnel)); ctx.fillEllipse(in: CGRect(x: c.x - core / 4, y: c.y - core / 4, width: core / 2, height: core / 2))
        ctx.restoreGState()
        let come = Self.ease(Self.span(k, 0.55, 0.92))
        Self.picture(ctx, new, in: r, at: c, scale: CGFloat(come), alpha: CGFloat(Self.span(k, 0.55, 0.65)))
    }

    // MARK: The starfield (1980s)

    /// The old place breaks up into tiles that fly outwards, shrink and turn into stars; for a moment there's nothing
    /// but deep space streaming past, until the new place comes out of it, from a point of light in the middle.
    private func drawStarfield(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let c = CGPoint(x: r.midX, y: r.midY), s = r.height / 800
        let space = sin(.pi * Self.span(k, 0.05, 0.95))
        ctx.setFillColor(rgb(0x02030A)); ctx.fill(r)
        // Stars streaming out from the middle.
        for i in 0..<160 {
            let a = noise(i * 5) * 2 * .pi, d = (noise(i * 5 + 1) + k * 1.4).truncatingRemainder(dividingBy: 1)
            let rad = CGFloat(d * d) * hypot(r.width, r.height) * 0.6
            let size = (1 + CGFloat(d) * 4) * s
            ctx.setFillColor(rgb(i % 7 == 0 ? 0xFFD8A8 : (i % 5 == 0 ? 0xA8C8FF : 0xFFFFFF), CGFloat(space * (0.3 + d))))
            ctx.fill(CGRect(x: c.x + cos(a) * rad - size / 2, y: c.y + sin(a) * rad - size / 2, width: size, height: size))
        }
        // The old place in tiles, flying apart.
        let burst = Self.span(k, 0.05, 0.5)
        if burst < 1 {
            let cols = 12, rows = 8
            let tw = r.width / CGFloat(cols), th = r.height / CGFloat(rows)
            let iw = CGFloat(old.width) / CGFloat(cols), ih = CGFloat(old.height) / CGFloat(rows)
            for j in 0..<rows {
                for i in 0..<cols {
                    let seed = j * cols + i
                    let start = noise(seed * 3) * 0.35
                    let f = Self.ease(Self.clamp((burst - start) / (1 - start)))
                    let cx = r.minX + (CGFloat(i) + 0.5) * tw, cy = r.minY + (CGFloat(j) + 0.5) * th
                    let dx = cx - c.x, dy = cy - c.y
                    let x = cx + dx * CGFloat(f) * 1.6, y = cy + dy * CGFloat(f) * 1.6
                    let scale = CGFloat(1 - f * 0.92)
                    // Image rows run top down; the tile at row j from the bottom is image row rows - 1 - j.
                    guard let tile = old.cropping(to: CGRect(x: CGFloat(i) * iw, y: CGFloat(rows - 1 - j) * ih, width: iw, height: ih)) else { continue }
                    ctx.saveGState()
                    ctx.translateBy(x: x, y: y); ctx.rotate(by: CGFloat((noise(seed) - 0.5) * 3 * f)); ctx.scaleBy(x: scale, y: scale)
                    ctx.setAlpha(CGFloat(1 - f * f))
                    ctx.draw(tile, in: CGRect(x: -tw / 2, y: -th / 2, width: tw + 1, height: th + 1))
                    ctx.restoreGState()
                }
            }
        }
        // The new place, out of a point of light.
        let come = Self.ease(Self.span(k, 0.5, 0.92))
        if k > 0.45 {
            let glow = CGFloat(sin(.pi * Self.span(k, 0.45, 0.8))) * 120 * s
            ctx.saveGState(); ctx.setShadow(offset: .zero, blur: glow, color: rgb(0xD8E8FF))
            ctx.setFillColor(rgb(0xFFFFFF, 0.9)); ctx.fillEllipse(in: CGRect(x: c.x - glow / 6, y: c.y - glow / 6, width: glow / 3, height: glow / 3))
            ctx.restoreGState()
        }
        Self.picture(ctx, new, in: r, at: c, scale: CGFloat(come), alpha: CGFloat(Self.span(k, 0.5, 0.62)))
    }

    // MARK: The explosive vortex (2010s)

    /// The old place cracks into shards round the middle, which spiral outwards as a cosmic blaze of orange and blue
    /// cloud bursts out behind them; then shards of the new place spiral back in and lock together.
    private func drawExplosive(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height) / 2, s = r.height / 800
        let blaze = sin(.pi * Self.span(k, 0.1, 0.9))
        ctx.setFillColor(rgb(0x060814)); ctx.fill(r)
        // The clouds: soft blobs of orange and blue, turning, and a white-hot core.
        for i in 0..<14 {
            let a = Double(i) / 14 * 2 * .pi + k * 2.4
            let d = CGFloat(0.15 + 0.55 * noise(i * 7)) * far * CGFloat(0.4 + blaze * 0.8)
            let rad = (90 + 140 * CGFloat(noise(i * 7 + 1))) * s * CGFloat(0.5 + blaze)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: rad, color: rgb(i % 2 == 0 ? 0xFF7A2A : 0x3A6AFF, blaze * 0.9))
            ctx.setFillColor(rgb(i % 2 == 0 ? 0xFFB06A : 0x6A9AFF, blaze * 0.35))
            ctx.fillEllipse(in: CGRect(x: c.x + cos(a) * d - rad / 2, y: c.y + sin(a) * d - rad / 2, width: rad, height: rad))
            ctx.restoreGState()
        }
        let core = CGFloat(blaze) * 160 * s
        ctx.saveGState(); ctx.setShadow(offset: .zero, blur: core, color: rgb(0xFFF0C8))
        ctx.setFillColor(rgb(0xFFFFFF, blaze)); ctx.fillEllipse(in: CGRect(x: c.x - core / 3, y: c.y - core / 3, width: core / 1.5, height: core / 1.5))
        ctx.restoreGState()
        // The shards: wedges of the picture in three rings, spiralling out (the old place) or in (the new one).
        let out = k < 0.5
        let f = out ? Self.ease(Self.span(k, 0.08, 0.5)) : 1 - Self.ease(Self.span(k, 0.5, 0.88))
        let img = out ? old : new
        // Whole, before it cracks and once it's back together (no seams between the shards).
        if f < 0.005 { ctx.draw(img, in: r); return }
        let whole = CGFloat(max(0, 1 - f * 5))   // the picture under the shards while they're still close, hiding the cracks
        if whole > 0 { ctx.setAlpha(whole); ctx.draw(img, in: r); ctx.setAlpha(1) }
        let sectors = 10, rings = 3
        for ring in 0..<rings {
            for sec in 0..<sectors {
                let seed = ring * sectors + sec
                let a0 = Double(sec) / Double(sectors) * 2 * .pi + Double(ring) * 0.3
                let a1 = a0 + 2 * .pi / Double(sectors)
                let r0 = CGFloat(ring) / CGFloat(rings) * far * 1.05, r1 = CGFloat(ring + 1) / CGFloat(rings) * far * 1.05
                let wedge = CGMutablePath()
                wedge.move(to: CGPoint(x: c.x + cos(a0) * r0, y: c.y + sin(a0) * r0))
                wedge.addArc(center: c, radius: r1, startAngle: CGFloat(a0), endAngle: CGFloat(a1), clockwise: false)
                wedge.addArc(center: c, radius: max(r0, 0.5), startAngle: CGFloat(a1), endAngle: CGFloat(a0), clockwise: true)
                wedge.closeSubpath()
                let mid = (a0 + a1) / 2
                let push = CGFloat(f) * far * CGFloat(0.5 + noise(seed) * 0.8)
                let spin = CGFloat(f * (1.2 + noise(seed * 3)) * (out ? 1 : -1))
                ctx.saveGState()
                // Out along its own direction, turning about the middle as it goes.
                ctx.translateBy(x: c.x + cos(mid) * push, y: c.y + sin(mid) * push)
                ctx.rotate(by: spin)
                ctx.translateBy(x: -c.x, y: -c.y)
                ctx.addPath(wedge); ctx.clip()
                ctx.setAlpha(CGFloat(1 - f * f))
                ctx.draw(img, in: r)
                ctx.restoreGState()
                if f > 0.02 {
                    ctx.saveGState()
                    ctx.translateBy(x: c.x + cos(mid) * push, y: c.y + sin(mid) * push); ctx.rotate(by: spin); ctx.translateBy(x: -c.x, y: -c.y)
                    ctx.addPath(wedge); ctx.setStrokeColor(rgb(0xFFE8B0, 0.7 * (1 - f))); ctx.setLineWidth(3 * s); ctx.strokePath()
                    ctx.restoreGState()
                }
            }
        }
    }

    // MARK: The time vortex

    /// The old place shrinks and turns as it falls away into a tunnel of blue and orange cloud spiralling round the
    /// middle, the TARDIS tumbling past through it; at the bottom of it the new place rushes up, turning the other way,
    /// and fills the screen. `neon`: today's version, the tunnel in ribbons of rainbow light.
    private func drawVortex(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect, neon: Bool) {
        let c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height) / 2
        let tunnel = sin(.pi * Self.span(k, 0.05, 0.95))
        ctx.setFillColor(rgb(0x060A1E)); ctx.fill(r)
        // The rings of the tunnel, smallest last, each turned a little further and drifting outwards.
        for i in stride(from: 26, through: 0, by: -1) {
            let d = (Double(i) / 26 + k * 1.6).truncatingRemainder(dividingBy: 1)
            let rad = CGFloat(pow(d, 1.8)) * far * 1.15
            guard rad > 2 else { continue }
            let warm = i % 3 == 0
            let rainbow: [UInt32] = [0xFF3A5A, 0xFF9A2A, 0xFFE83A, 0x3AE87A, 0x3AB8FF, 0xA85AFF]
            let col = neon ? rgb(rainbow[i % rainbow.count], 0.75 * tunnel * (0.3 + d * 0.7))
                : warm ? rgb(0xF08A3A, 0.55 * tunnel * d) : rgb(0x3A6AE8, 0.6 * tunnel * (0.3 + d * 0.7))
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: CGFloat(d * 5 + k * 7))
            ctx.addEllipse(in: CGRect(x: -rad, y: -rad * 0.82, width: rad * 2, height: rad * 1.64))
            ctx.setStrokeColor(col); ctx.setLineWidth(max(2, rad * 0.16)); ctx.strokePath()
            ctx.restoreGState()
        }
        // Streaks of light flying out of the middle.
        for i in 0..<36 {
            let a = noise(i * 7) * 2 * .pi + k * 3, d = (noise(i * 7 + 1) + k * 2.2).truncatingRemainder(dividingBy: 1)
            let r0 = CGFloat(d) * far, r1 = r0 + CGFloat(d) * far * 0.25
            ctx.move(to: CGPoint(x: c.x + cos(a) * r0, y: c.y + sin(a) * r0))
            ctx.addLine(to: CGPoint(x: c.x + cos(a) * r1, y: c.y + sin(a) * r1))
            ctx.setStrokeColor(rgb(0xE8F0FF, 0.5 * tunnel * d)); ctx.setLineWidth(2 + CGFloat(d) * 3); ctx.strokePath()
        }
        // The old place falling away, the new one coming up.
        func picture(_ img: CGImage, scale: CGFloat, turn: CGFloat, alpha: CGFloat) {
            guard scale > 0.005, alpha > 0.01 else { return }
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: turn); ctx.scaleBy(x: scale, y: scale)
            ctx.setAlpha(alpha)
            ctx.draw(img, in: CGRect(x: -r.width / 2, y: -r.height / 2, width: r.width, height: r.height))
            ctx.restoreGState()
        }
        let out = Self.ease(Self.span(k, 0, 0.45)), back = Self.ease(Self.span(k, 0.55, 1))
        picture(old, scale: CGFloat(1 - out), turn: CGFloat(out * 2.2), alpha: CGFloat(1 - Self.span(k, 0.35, 0.45)))
        // The TARDIS, tumbling out of the depths and past (in the classic vortex).
        if !neon, k > 0.25, k < 0.8, let box = Self.policeBox(lamp: Int(k * 16) % 2 == 0) {
            let f = Self.span(k, 0.25, 0.8), size = CGFloat(pow(f, 2.2)) * r.height * 0.9 + 6
            let drift = CGPoint(x: c.x + CGFloat(f * f) * r.width * 0.32, y: c.y + CGFloat(f * f) * r.height * 0.12)
            ctx.saveGState()
            ctx.translateBy(x: drift.x, y: drift.y); ctx.rotate(by: CGFloat(f * 5))
            ctx.setAlpha(CGFloat(min(1, f * 6)))
            ctx.draw(box, in: CGRect(x: -size * 14 / 26 / 2 * 2, y: -size / 2, width: size * 28 / 26, height: size))
            ctx.restoreGState()
        }
        picture(new, scale: CGFloat(back), turn: CGFloat((back - 1) * 2.2), alpha: CGFloat(Self.span(k, 0.55, 0.65)))
    }

    // MARK: The TARDIS

    /// The police box stands in the old place; the place dissolves round it into the dark between, and the box wheezes
    /// away after it, its lamp flashing. Then, in the dark, the box wheezes back into view, and the new place
    /// materialises round it.
    private func drawDematerialise(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        /// A wheeze: up to 1 over `a…b`, rising and falling three times on the way.
        func wheeze(_ a: Double, _ b: Double) -> CGFloat {
            let u = Self.span(k, a, b)
            return CGFloat(Self.clamp(u * (0.7 + 0.3 * cos(u * 6 * .pi))))
        }
        ctx.setFillColor(rgb(0x060A1E)); ctx.fill(r)
        for i in 0..<70 {   // the dark between, a few stars
            let x = r.minX + r.width * CGFloat(noise(i * 3)), y = r.minY + r.height * CGFloat(noise(i * 3 + 1))
            ctx.setFillColor(rgb(0xFFFFFF, 0.25 + 0.4 * CGFloat(noise(i * 3 + 2)))); ctx.fill(CGRect(x: x, y: y, width: 2 * s, height: 2 * s))
        }
        ctx.setAlpha(1 - wheeze(0.05, 0.35)); ctx.draw(old, in: r)
        ctx.setAlpha(wheeze(0.68, 0.95)); ctx.draw(new, in: r); ctx.setAlpha(1)
        let box = k < 0.5 ? 1 - wheeze(0.3, 0.48) : wheeze(0.52, 0.7) * CGFloat(1 - Self.span(k, 0.9, 1))   // gone as the trip ends
        guard box > 0.01 else { return }
        let lampOn = Int(k * 18) % 2 == 0
        let c = PixelCanvas(28, 26)
        drawPoliceBoxIcon(c)
        if !lampOn { c.rect(12, 2, 4, 2, C(0x8A94A8)) }
        c.addOutline(C(0xFFFFFF, 0.85))
        guard let img = c.makeImage() else { return }
        let unit = 8 * s, w = 28 * unit, h = 26 * unit
        let rect = CGRect(x: r.midX - w / 2, y: r.minY + r.height * 0.14, width: w, height: h)
        if lampOn {
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 60 * s, color: rgb(0xFFF2B0, box))
            ctx.setFillColor(rgb(0xFFF2B0, 0.6 * box))
            ctx.fillEllipse(in: CGRect(x: r.midX - 3 * unit, y: rect.maxY - 4 * unit, width: 6 * unit, height: 4 * unit))
            ctx.restoreGState()
        }
        ctx.setAlpha(box); ctx.draw(img, in: rect)
    }

    // MARK: Regeneration

    /// Golden fire pours out of the middle in shafts that turn and grow, until the screen is all gold and white; it
    /// dies down on the new place.
    private func drawRegeneration(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let c = CGPoint(x: r.midX, y: r.minY + r.height * 0.42), far = hypot(r.width, r.height)
        let flare = Self.ease(Self.span(k, 0, 0.5)) * (1 - Self.ease(Self.span(k, 0.55, 1)))
        ctx.draw(k < 0.5 ? old : new, in: r)
        ctx.setFillColor(rgb(0xFFB040, 0.35 * flare)); ctx.fill(r)
        // The shafts of fire.
        let n = 14
        for i in 0..<n {
            let a = Double(i) / Double(n) * 2 * .pi + k * 1.5 + noise(i) * 0.3
            let len = CGFloat(flare) * far * CGFloat(0.4 + 0.6 * noise(i * 3 + Int(k * 10)))
            let width = 0.08 + 0.06 * noise(i * 5)
            ctx.move(to: c)
            ctx.addLine(to: CGPoint(x: c.x + cos(a - width) * len, y: c.y + sin(a - width) * len))
            ctx.addLine(to: CGPoint(x: c.x + cos(a + width) * len, y: c.y + sin(a + width) * len))
            ctx.closePath()
            ctx.setFillColor(i % 2 == 0 ? rgb(0xFFD25A, 0.75 * flare) : rgb(0xFF9A2A, 0.6 * flare)); ctx.fillPath()
        }
        // The blaze in the middle, and the whiteout at its height.
        let core = CGFloat(flare) * r.height * 0.5
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: core, color: rgb(0xFFE08A, flare))
        ctx.setFillColor(rgb(0xFFF6D8, flare)); ctx.fillEllipse(in: CGRect(x: c.x - core / 2, y: c.y - core / 2, width: core, height: core))
        ctx.restoreGState()
        let white = CGFloat(Self.span(k, 0.38, 0.5) * (1 - Self.span(k, 0.5, 0.68)))
        ctx.setFillColor(rgb(0xFFF8E8, white)); ctx.fill(r)
    }

    // MARK: Blink

    /// Don't blink. The screen blinks four times; each time it opens, a Weeping Angle stands closer, covering its face
    /// at first, then reaching out. The last blink opens on the new place, the Angle gone.
    private func drawBlink(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let blinks = 4.0, u = k * blinks, i = min(Int(u), 3), f = u - Double(i)
        // How shut the eyes are, 0 open … 1 shut: a blink in the middle of each quarter.
        let shut = CGFloat(max(0, 1 - abs(f - 0.5) / 0.22))
        let opensOnNew = Double(i) + (f > 0.5 ? 1 : 0) >= blinks - 0.5
        ctx.draw(opensOnNew ? new : old, in: r)
        // The Angle, closer after each blink, gone on the new place.
        let seen = i + (f > 0.5 ? 1 : 0)
        if !opensOnNew && seen > 0 {
            let size = r.height / 800 * CGFloat([0, 4.0, 6.5, 9.5][min(seen, 3)])
            let who = Cast.villain(.weepingAngle)
            let canvas = PixelCanvas(Sprite.width, Sprite.height)
            who.draw(canvas, t: 0, mode: seen >= 3 ? .working : .idle, walking: false, role: seen >= 3 ? .hit : .none,
                     asSession: false)
            canvas.addOutline(C(0x0A0A0A))
            if let img = canvas.makeImage() {
                let feet = r.minY + r.height * 0.1
                ctx.draw(img, in: CGRect(x: r.midX - CGFloat(Sprite.bodyCenterX) * size, y: feet - 8 * size,
                                         width: CGFloat(Sprite.width) * size, height: CGFloat(Sprite.height) * size))
            }
        }
        // The eyelids.
        guard shut > 0.001 else { return }
        let lid = r.height / 2 * shut
        ctx.setFillColor(rgb(0x050505))
        ctx.fill(CGRect(x: r.minX, y: r.maxY - lid, width: r.width, height: lid))
        ctx.fill(CGRect(x: r.minX, y: r.minY, width: r.width, height: lid))
    }

    // MARK: The Dalick's eye

    /// Seen through a Dalick's eyestalk: the picture goes blue, the lens's rings close in like an iris until it's shut,
    /// then open again on the new place, and the blue drains away.
    private func drawEyestalk(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, far = hypot(r.width, r.height) / 2
        let c = CGPoint(x: r.midX, y: r.midY)
        let close = Self.ease(Self.span(k, 0.08, 0.48)), open = Self.ease(Self.span(k, 0.52, 0.92))
        let aperture = CGFloat(1 - close + open) * far * 1.05
        let tint = CGFloat(sin(.pi * Self.span(k, 0, 1)))
        ctx.setFillColor(rgb(0x0A0E16)); ctx.fill(r)
        // The view through the lens.
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: c.x - aperture, y: c.y - aperture, width: aperture * 2, height: aperture * 2)); ctx.clip()
        ctx.draw(k < 0.5 ? old : new, in: r)
        ctx.setFillColor(rgb(0x2A7ADA, 0.45 * tint)); ctx.fill(r)
        // The scan lines.
        for y in stride(from: r.minY, to: r.maxY, by: 6 * s) {
            ctx.setFillColor(rgb(0x000000, 0.18 * tint)); ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 2 * s))
        }
        ctx.restoreGState()
        // The lens's rings round the aperture.
        for i in 0..<5 {
            let rad = aperture + CGFloat(i) * 22 * s
            ctx.addEllipse(in: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2))
            ctx.setStrokeColor(i == 0 ? rgb(0x6AC8FF, 0.9 * tint + 0.1) : rgb(0x3A3A42, 0.95)); ctx.setLineWidth((i == 0 ? 6 : 12) * s)
            ctx.strokePath()
        }
        // The crosshair, while it's watching.
        if tint > 0.05, aperture > 40 * s {
            ctx.setStrokeColor(rgb(0x9AE0FF, 0.5 * tint)); ctx.setLineWidth(2 * s)
            ctx.move(to: CGPoint(x: c.x - aperture * 0.3, y: c.y)); ctx.addLine(to: CGPoint(x: c.x + aperture * 0.3, y: c.y))
            ctx.move(to: CGPoint(x: c.x, y: c.y - aperture * 0.3)); ctx.addLine(to: CGPoint(x: c.x, y: c.y + aperture * 0.3))
            ctx.strokePath()
        }
    }
}

/// A colour from 0xRRGGBB.
private func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
