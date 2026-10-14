import CoreGraphics

/// Doctor Clawd's trips between places, a different one each time. Some belong to someone and come up more often with
/// them on screen: the regeneration with a Doctor about, the blink with an Angle, the eyestalk with a Dalick.
enum DoctorWipe: Int, CaseIterable {
    case vortex          // the old place spins away down the time vortex; the new one rushes up out of it
    case dematerialise   // the police box wheezes in, the old place fades round it in pulses, and the new one fades in
    case regeneration    // golden fire pours out of the middle until it fills the screen, and dies down on the new place
    case blink           // the screen blinks, and an Angle stands closer each time; the last blink opens on the new place
    case eyestalk        // the view through a Dalick's eye: its lens closes on the old place and opens on the new one

    var duration: Double {
        switch self {
        case .vortex: return 2.2
        case .dematerialise: return 2.4
        case .regeneration: return 2.0
        case .blink: return 2.4
        case .eyestalk: return 1.9
        }
    }

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
        case .regeneration: return h.isDoctor
        case .dematerialise: return h.isDoctor || h == .hem
        default: return false
        }
    }
}

/// One trip's transition. Shared by the window and the screen saver, which hand over the old picture (frozen), the new
/// one (as it is right now) and how far through it is; a frame is drawn over the whole of `r`. Sizes are against an
/// 800-pixel-tall frame.
struct DoctorTrip {
    let kind: DoctorWipe
    var duration: Double { kind.duration }

    /// Any transition but the last one, those of whoever's on screen weighted up.
    static func pick(after last: DoctorWipe?, cast: [Cast], to place: Location) -> DoctorTrip {
        var kinds: [DoctorWipe] = []
        for kind in DoctorWipe.allCases where kind != last {
            kinds.append(kind)
            if cast.contains(where: kind.isOwned) { kinds += [kind, kind, kind] }
        }
        if place == .skarro || place == .dalickAsylum, last != .eyestalk { kinds += [.eyestalk, .eyestalk] }
        return DoctorTrip(kind: kinds.randomElement() ?? .vortex)
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
        case .vortex: drawVortex(ctx, old: old, new: new, k: k, in: r)
        case .dematerialise: drawDematerialise(ctx, old: old, new: new, k: k, in: r)
        case .regeneration: drawRegeneration(ctx, old: old, new: new, k: k, in: r)
        case .blink: drawBlink(ctx, old: old, new: new, k: k, in: r)
        case .eyestalk: drawEyestalk(ctx, old: old, new: new, k: k, in: r)
        }
    }

    // MARK: The time vortex

    /// The old place shrinks and turns as it falls away into a tunnel of blue and orange cloud spiralling round the
    /// middle; at the bottom of it the new place rushes up, turning the other way, and fills the screen.
    private func drawVortex(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height) / 2
        let tunnel = sin(.pi * Self.span(k, 0.05, 0.95))
        ctx.setFillColor(rgb(0x060A1E)); ctx.fill(r)
        // The rings of the tunnel, smallest last, each turned a little further and drifting outwards.
        for i in stride(from: 26, through: 0, by: -1) {
            let d = (Double(i) / 26 + k * 1.6).truncatingRemainder(dividingBy: 1)
            let rad = CGFloat(pow(d, 1.8)) * far * 1.15
            guard rad > 2 else { continue }
            let warm = i % 3 == 0
            let col = warm ? rgb(0xF08A3A, 0.55 * tunnel * d) : rgb(0x3A6AE8, 0.6 * tunnel * (0.3 + d * 0.7))
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
        picture(new, scale: CGFloat(back), turn: CGFloat((back - 1) * 2.2), alpha: CGFloat(Self.span(k, 0.55, 0.65)))
    }

    // MARK: The TARDIS

    /// The police box wheezes into the middle of the old place, its lamp flashing; the old place fades round it in
    /// pulses, then the new one pulses in, and the box fades away last.
    private func drawDematerialise(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        /// A wheeze: up to 1 over `a…b`, rising and falling three times on the way.
        func wheeze(_ a: Double, _ b: Double) -> CGFloat {
            let u = Self.span(k, a, b)
            return CGFloat(Self.clamp(u * (0.7 + 0.3 * cos(u * 6 * .pi))))
        }
        let swap = wheeze(0.25, 0.75)
        ctx.draw(old, in: r)
        ctx.setAlpha(swap); ctx.draw(new, in: r); ctx.setAlpha(1)
        let box = wheeze(0, 0.25) * (1 - wheeze(0.72, 1))
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
            let size = r.height / 800 * CGFloat([0, 4.0, 7.5, 13.0][min(seen, 3)])
            let who = Cast.villain(.weepingAngle)
            let canvas = PixelCanvas(Sprite.width, Sprite.height)
            who.draw(canvas, t: 0, mode: seen >= 3 ? .working : .idle, walking: false, role: seen >= 3 ? .hit : .none,
                     asSession: false)
            canvas.addOutline(C(0x0A0A0A))
            if let img = canvas.makeImage() {
                let feet = r.minY + r.height * 0.12 - CGFloat(seen >= 3 ? 10 : 0) * size
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
