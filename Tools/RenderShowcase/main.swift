import AppKit

// Renders the Doctor Clawd README's own pictures with the app's sprite code: the icon, and the strips showing the
// TARDIS picking someone up, the Weeping Angle moving while nobody looks, and a regeneration. (The roster, locations,
// desktop and social preview come from Tools/RenderDocs; the window, screen saver and hover shots are CLAWD_SHOT
// captures of a Playground run.)
//   swiftc -swift-version 5 Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          Sources/App/Universes/**/*.swift Sources/Shared/*.swift Tools/RenderShowcase/main.swift -o build/rendershowcase
//   build/rendershowcase docs

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
Universe.shown = .doctor

func hexRGB(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func canvas(_ w: Int, _ h: Int, bg: UInt32?, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    if let bg { ctx.setFillColor(hexRGB(bg)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h)) }
    ctx.interpolationQuality = .none
    draw(ctx)
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
    print("wrote \(out)/\(name)")
}

/// One character drawn on its own canvas, outlined, facing right (or left).
func sprite(_ who: Cast, t: Double = 0.3, mode: VaderMode = .idle, walking: Bool = false, role: FightRole = .rest,
            left: Bool = false, flare: Double? = nil) -> PixelCanvas {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: mode, walking: walking, role: role, asSession: false)
    if let flare { drawRegeneration(c, k: flare, t: t) }
    if left { c.flipHorizontally() }
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// A pixel canvas drawn into `ctx` with its top-left at pixel (`x`, `y`) of a frame `unit` screen pixels per pixel,
/// `frameH` pixels tall (CoreGraphics is y-up).
func put(_ c: PixelCanvas, _ ctx: CGContext, x: Double, y: Double, unit: CGFloat, frameH: Int, origin: CGPoint, alpha: CGFloat = 1) {
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.setAlpha(alpha)
    ctx.draw(img, in: CGRect(x: origin.x + CGFloat(x) * unit, y: origin.y + CGFloat(Double(frameH) - y - Double(c.h)) * unit,
                             width: CGFloat(c.w) * unit, height: CGFloat(c.h) * unit))
    ctx.restoreGState()
}

/// A label box over a character, as the app draws an agent's.
func tag(_ s: String, _ ctx: CGContext, centerX: CGFloat, bottom: CGFloat, leader: Bool = false) {
    let font = leader ? NSFont.monospacedSystemFont(ofSize: 15, weight: .bold) : NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
    let text = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.white])
    let ts = text.size()
    let box = CGRect(x: centerX - ts.width / 2 - 8, y: bottom, width: ts.width + 16, height: ts.height + 6)
    let path = CGPath(roundedRect: box, cornerWidth: 6, cornerHeight: 6, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(leader ? CGColor(gray: 0.08, alpha: 0.85) : CGColor(red: 0.05, green: 0.10, blue: 0.24, alpha: 0.85)); ctx.fillPath()
    ctx.addPath(path)
    ctx.setStrokeColor(leader ? CGColor(gray: 1, alpha: 0.35) : CGColor(red: 0.45, green: 0.65, blue: 1, alpha: 0.5))
    ctx.setLineWidth(1.5); ctx.strokePath()
    NSGraphicsContext.saveGraphicsState()
    text.draw(at: NSPoint(x: box.minX + 8, y: box.minY + 3))
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: Strips

/// A strip of panels in one place, each with its caption above it, the way the Star Clawds page shows the shoot-out.
let pw = 150, ph = 66, unit: CGFloat = 3.2, gap: CGFloat = 10, capH: CGFloat = 34
struct Panel { let caption: String; let draw: (CGContext, CGPoint, (Double) -> CGFloat) -> Void }

func strip(_ place: Location, _ panels: [Panel], file: String) {
    let W = CGFloat(pw) * unit, H = CGFloat(ph) * unit
    let total = CGFloat(panels.count) * W + CGFloat(panels.count + 1) * gap
    let rep = canvas(Int(total), Int(H + capH + gap), bg: 0x121219) { ctx in
        for (i, p) in panels.enumerated() {
            let o = CGPoint(x: gap + CGFloat(i) * (W + gap), y: gap / 2)
            let bg = PixelCanvas(pw, ph); place.drawStatic(bg, floorRows: 8)
            let mv = PixelCanvas(pw, ph); place.drawAnimated(mv, floorRows: 8, t: 1.3 + Double(i) * 0.7)
            for img in [bg.makeImage(), mv.makeImage()].compactMap({ $0 }) { ctx.draw(img, in: CGRect(x: o.x, y: o.y, width: W, height: H)) }
            ctx.saveGState(); ctx.clip(to: CGRect(x: o.x, y: o.y, width: W, height: H))
            p.draw(ctx, o) { y in o.y + CGFloat(Double(ph) - y) * unit }   // pixel row → screen y
            ctx.restoreGState()
            let text = NSAttributedString(string: p.caption, attributes: [
                .font: NSFont.systemFont(ofSize: 17, weight: .bold), .foregroundColor: NSColor(srgbRed: 1, green: 0.91, blue: 0.3, alpha: 1)])
            NSGraphicsContext.saveGraphicsState()
            text.draw(at: NSPoint(x: o.x + (W - text.size().width) / 2, y: o.y + H + 8))
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    save(rep, file)
}

/// Feet on the ground row: a sprite's canvas top for a panel whose floor is 8 rows tall.
let spriteTop = Double(ph - 8 - 44)
func at(_ c: PixelCanvas, _ ctx: CGContext, _ o: CGPoint, bodyX: Double, left: Bool = false, alpha: CGFloat = 1, lift: Double = 0) {
    let x = left ? bodyX - (Double(Sprite.width) - Sprite.bodyCenterX) : bodyX - Sprite.bodyCenterX
    put(c, ctx, x: x, y: spriteTop - lift, unit: unit, frameH: ph, origin: o, alpha: alpha)
}

// The TARDIS: it wheezes in beside Rose, the door opens, she steps in, and it fades away. A Dalick looks on.
func tardisBox(_ ctx: CGContext, _ o: CGPoint, x: Double, door: Double, lamp: Bool, alpha: CGFloat) {
    let c = PixelCanvas(Ride.width, Ride.height)
    drawRide(c, .tardis, ramp: door, engines: lamp, gear: true)
    c.addOutline(C(0xFFFFFF, 0.92))
    put(c, ctx, x: x - Double(Ride.width) / 2, y: Double(ph - 8 - 28), unit: unit, frameH: ph, origin: o, alpha: alpha)
}
let rose = Cast.hero(DoctorHero.rose), dalick = Cast.villain(DoctorVillain.dalick)
let roseX = 22.0, boxX = 66.0
strip(.powellEstate, [
    Panel(caption: "1 · the TARDIS wheezes in") { ctx, o, sy in
        tardisBox(ctx, o, x: boxX, door: 0, lamp: true, alpha: 0.55)
        at(sprite(rose), ctx, o, bodyX: roseX)
        at(sprite(dalick, left: true), ctx, o, bodyX: 124, left: true)
        tag("Verify the fix", ctx, centerX: o.x + CGFloat(roseX) * unit, bottom: sy(spriteTop + 18))
    },
    Panel(caption: "2 · the door swings open") { ctx, o, sy in
        tardisBox(ctx, o, x: boxX, door: 1, lamp: false, alpha: 1)
        at(sprite(rose), ctx, o, bodyX: roseX)
        at(sprite(dalick, left: true), ctx, o, bodyX: 124, left: true)
        tag("Verify the fix", ctx, centerX: o.x + CGFloat(roseX) * unit, bottom: sy(spriteTop + 18))
    },
    Panel(caption: "3 · Rose Tiler steps inside") { ctx, o, sy in
        tardisBox(ctx, o, x: boxX, door: 1, lamp: false, alpha: 1)
        at(sprite(rose, t: 0.06, walking: true), ctx, o, bodyX: 50, alpha: 0.75)
        at(sprite(dalick, left: true), ctx, o, bodyX: 124, left: true)
    },
    Panel(caption: "4 · and it's gone") { ctx, o, _ in
        tardisBox(ctx, o, x: boxX, door: 0, lamp: true, alpha: 0.3)
        at(sprite(dalick, left: true), ctx, o, bodyX: 124, left: true)
    },
], file: "tardis.png")

// The Weeping Angle: still while the Doctor looks at it, closer every time he looks away.
let angle = Cast.villain(DoctorVillain.weepingAngle), ten = Cast.hero(DoctorHero.doctorTen)
strip(.theLibrary, [
    Panel(caption: "Doctor Ten keeps an eye on it") { ctx, o, _ in
        at(sprite(ten), ctx, o, bodyX: 30)
        at(sprite(angle, left: true), ctx, o, bodyX: 128, left: true)
    },
    Panel(caption: "he looks away…") { ctx, o, _ in
        at(sprite(ten, left: true), ctx, o, bodyX: 30, left: true)
        at(sprite(angle, mode: .working, walking: true, role: .none, left: true), ctx, o, bodyX: 98, left: true, alpha: 0.85)
    },
    Panel(caption: "…and back. It's closer.") { ctx, o, _ in
        at(sprite(ten), ctx, o, bodyX: 30)
        at(sprite(angle, mode: .working, role: .none, left: true), ctx, o, bodyX: 80, left: true)
    },
    Panel(caption: "Don't blink.") { ctx, o, _ in
        at(sprite(ten, mode: .waiting, role: .hit), ctx, o, bodyX: 30)
        at(sprite(angle, mode: .working, role: .hit, left: true), ctx, o, bodyX: 56, left: true)
    },
], file: "angle.png")

// Regeneration: /compact, and the session's Doctor goes up in golden fire and comes out as the next one.
let eleven = Cast.hero(DoctorHero.doctorEleven)
strip(.consoleRoom, [
    Panel(caption: "you type /compact") { ctx, o, sy in
        at(sprite(ten), ctx, o, bodyX: 75)
        tag("Doctor Ten", ctx, centerX: o.x + 75 * unit, bottom: sy(spriteTop + 16), leader: true)
    },
    Panel(caption: "the context goes…") { ctx, o, sy in
        at(sprite(ten, t: 0.4, flare: 0.1), ctx, o, bodyX: 75)
        tag("Doctor Ten", ctx, centerX: o.x + 75 * unit, bottom: sy(spriteTop + 16), leader: true)
    },
    Panel(caption: "…and so does the face") { ctx, o, sy in
        at(sprite(eleven, t: 0.7, flare: 0.3), ctx, o, bodyX: 75)
        tag("Doctor Eleven", ctx, centerX: o.x + 75 * unit, bottom: sy(spriteTop + 16), leader: true)
    },
    Panel(caption: "same session, new Doctor") { ctx, o, sy in
        at(sprite(eleven), ctx, o, bodyX: 75)
        tag("Doctor Eleven", ctx, centerX: o.x + 75 * unit, bottom: sy(spriteTop + 16), leader: true)
    },
], file: "regeneration.png")

// MARK: Icon

/// The icon: Doctor Ten's sonic screwdriver against a Dalick's gunstick, their rays meeting in the middle, in front of
/// the time vortex, on a rounded square like the other universes' icons.
let iconRep = canvas(1024, 1024, bg: nil) { ctx in
    let box = CGRect(x: 100, y: 100, width: 824, height: 824)
    let path = CGPath(roundedRect: box, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState(); ctx.addPath(path); ctx.clip()
    // The vortex: a deep blue sky with rings of blue and orange cloud round a bright eye, drawn chunky.
    let px = 12, n = 824 / px + 1
    let eye = (x: 0.5, y: 0.66)
    for j in 0..<n {
        for i in 0..<n {
            let u = (Double(i) + 0.5) / Double(n), v = (Double(j) + 0.5) / Double(n)
            let dx = u - eye.x, dy = (v - eye.y) * 1.25
            let r = (dx * dx + dy * dy).squareRoot(), a = atan2(dy, dx)
            let band = sin(r * 34 - a * 2 + 1.2), warm = sin(r * 21 + a * 3)
            var col: UInt32 = r < 0.05 ? 0xE8F2FF : r < 0.09 ? 0x8AB8FF : 0x0C1440
            if r >= 0.09 {
                if band > 0.55 { col = 0x2A4AB8 } else if band > 0.2 { col = 0x1A2A78 }
                if warm > 0.86 && r > 0.18 { col = 0xC86A2A } else if warm > 0.72 && r > 0.18 { col = 0x7A3A3A }
            }
            ctx.setFillColor(hexRGB(col))
            ctx.fill(CGRect(x: box.minX + CGFloat(i * px), y: box.minY + CGFloat(j * px), width: CGFloat(px), height: CGFloat(px)))
        }
    }
    // The floor.
    ctx.setFillColor(hexRGB(0x1A1F33)); ctx.fill(CGRect(x: box.minX, y: box.minY, width: box.width, height: 228))
    ctx.setFillColor(hexRGB(0x6A9AA4)); ctx.fill(CGRect(x: box.minX, y: box.minY + 222, width: box.width, height: 6))
    ctx.restoreGState()

    // The fighters and the fight between them, at 13 screen pixels per sprite pixel.
    let s: CGFloat = 10.5, floorY: CGFloat = box.minY + 222, headroom = 20.0
    let lx = 24.0, rx = 58.0                 // body centres, in sprite pixels from the box's left edge
    let left = Fighter(weapon: dalick.weapon, x: lx, k: 1, top: headroom, side: 1, muzzle: dalick.muzzle,
                       armoured: dalick.armoured, pivot: dalick.weaponPivot).dressed(as: dalick)
    let right = Fighter(weapon: ten.weapon, x: rx, k: 1, top: headroom, side: -1, muzzle: ten.muzzle,
                        armoured: ten.armoured, pivot: ten.weaponPivot).dressed(as: ten)
    let fxW = 80, fxH = Sprite.height + Int(headroom)
    let fx = PixelCanvas(fxW, fxH)
    drawFightFX(fx, t: 0.42, left: left, right: right)
    func body(_ c: PixelCanvas, _ bodyX: Double, flipped: Bool) {
        let x = flipped ? bodyX - (Double(Sprite.width) - Sprite.bodyCenterX) : bodyX - Sprite.bodyCenterX
        ctx.draw(c.makeImage()!, in: CGRect(x: box.minX + 10 + CGFloat(x) * s, y: floorY - 8 * s,
                                           width: CGFloat(Sprite.width) * s, height: CGFloat(Sprite.height) * s))
    }
    body(sprite(dalick, t: 0.42, mode: .working, role: .hit), lx, flipped: false)
    body(sprite(ten, t: 0.42, mode: .working, role: .zap, left: true), rx, flipped: true)
    ctx.draw(fx.makeImage()!, in: CGRect(x: box.minX + 10, y: floorY - 8 * s, width: CGFloat(fxW) * s, height: CGFloat(fxH) * s))
    // A thin edge round the square.
    ctx.addPath(path); ctx.setStrokeColor(hexRGB(0xFFFFFF, 0.12)); ctx.setLineWidth(3); ctx.strokePath()
}
save(iconRep, "icon.png")
