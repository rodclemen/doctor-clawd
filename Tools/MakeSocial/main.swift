import AppKit
import CoreText

// Renders docs/social-preview.png (1280×640, GitHub → Settings → Social preview): a comic cover in three slanted
// panels, one per universe, each with a fight in full swing, drawn with the app's own sprite and fight-effect code:
// Luke and Vader's sabers locked under the stars, Thor and Loki trading lightning and magic, Batman against the
// Joker under the Night Beacon. CLAWD CLASH runs across all three, coloured by the panel each part is in, with a sound
// effect in each panel and the tagline in a caption box.
//   swiftc Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          Sources/App/Universes/**/*.swift Sources/Shared/*.swift Tools/MakeSocial/main.swift -o build/makesocial \
//          && build/makesocial docs/social-preview.png

let W: CGFloat = 1280, H: CGFloat = 640
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let gc = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gc
let ctx = gc.cgContext
ctx.interpolationQuality = .none

func hex(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(h >> 16 & 0xFF) / 255, green: CGFloat(h >> 8 & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: a)
}
func rnd(_ i: Int) -> CGFloat { CGFloat(noise(i)) }
let inkColor = hex(0x111018)

// MARK: The panels

/// Where the gutters cross the bottom and top edges, and how far they lean.
let cuts: [CGFloat] = [-200, 440, 860, 1500], tilt: CGFloat = 60
/// Panel `i` (0 Star Wars, 1 Marvel, 2 DC).
func panel(_ i: Int) -> CGPath {
    let p = CGMutablePath()
    p.addLines(between: [CGPoint(x: cuts[i] - tilt, y: 0), CGPoint(x: cuts[i + 1] - tilt, y: 0),
                         CGPoint(x: cuts[i + 1] + tilt, y: H), CGPoint(x: cuts[i] + tilt, y: H)])
    p.closeSubpath()
    return p
}
/// Each panel's middle, along the ground.
let centres: [CGFloat] = [205, 645, 1065]

func halftone(_ r: CGRect, color: CGColor, cell: CGFloat, dot: (CGPoint) -> CGFloat) {
    var y = r.minY, row = 0
    while y < r.maxY + cell {
        var x = r.minX + (row % 2 == 0 ? 0 : cell / 2)
        while x < r.maxX + cell {
            let d = dot(CGPoint(x: x, y: y)) * cell
            if d > 0.5 { ctx.addEllipse(in: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)) }
            x += cell
        }
        y += cell; row += 1
    }
    ctx.setFillColor(color); ctx.fillPath()
}

let ground: CGFloat = 108          // where the fighters stand
let skies: [(UInt32, UInt32)] = [(0x7A0E1E, 0x14050C), (0xC21E2E, 0x0E2A6E), (0x2E4482, 0x0A1028)]
let floors: [UInt32] = [0x22141C, 0x16203E, 0x121A30]
for i in 0..<3 {
    ctx.saveGState()
    ctx.addPath(panel(i)); ctx.clip()
    let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hex(skies[i].0), hex(skies[i].1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    // Speed rays bursting from where the fight is.
    let focus = CGPoint(x: centres[i], y: ground + 110)
    for r in 0..<36 {
        let a = CGFloat(r) / 36 * 2 * .pi, w = 0.035 + 0.03 * rnd(r + i * 50)
        ctx.move(to: focus)
        ctx.addLine(to: CGPoint(x: focus.x + cos(a - w) * 1500, y: focus.y + sin(a - w) * 1500))
        ctx.addLine(to: CGPoint(x: focus.x + cos(a + w) * 1500, y: focus.y + sin(a + w) * 1500))
        ctx.closePath()
    }
    ctx.setFillColor(hex(0xFFFFFF, 0.06)); ctx.fillPath()
    halftone(CGRect(x: 0, y: 0, width: W, height: H), color: hex(0x000000, 0.2), cell: 14) { p in 0.15 + 0.45 * (1 - p.y / H) }
    if i == 0 {
        for s in 0..<60 {   // pixel stars
            let big = rnd(7 + s * 3 + 2) > 0.85, d: CGFloat = big ? 6 : 3
            let x = rnd(7 + s * 3) * W * 0.45, y = 250 + rnd(7 + s * 3 + 1) * (H - 250)
            ctx.setFillColor(hex(0xFFFFFF, big ? 0.95 : 0.55))
            ctx.fill(CGRect(x: (x / d).rounded() * d, y: (y / d).rounded() * d, width: d, height: d))
        }
    }
    if i == 2 {
        let signal = CGPoint(x: 1192, y: 392)   // under the name, over the fight
        ctx.setFillColor(hex(0xFFE36B, 0.18))
        ctx.move(to: CGPoint(x: 1240, y: 0)); ctx.addLine(to: CGPoint(x: signal.x - 58, y: signal.y)); ctx.addLine(to: CGPoint(x: signal.x + 58, y: signal.y))
        ctx.closePath(); ctx.fillPath()
        ctx.setFillColor(hex(0xFFE36B, 0.92)); ctx.fillEllipse(in: CGRect(x: signal.x - 58, y: signal.y - 40, width: 116, height: 80))
        ctx.addPath(cowlMaskPath(signal, width: 92)); ctx.setFillColor(inkColor); ctx.fillPath(using: .evenOdd)
    }
    // The ground each fight stands on.
    ctx.setFillColor(hex(floors[i])); ctx.fill(CGRect(x: 0, y: 0, width: W, height: ground))
    ctx.setFillColor(hex(0xD97757)); ctx.fill(CGRect(x: 0, y: ground - 4, width: W, height: 4))   // Claude-orange horizon
    ctx.restoreGState()
}

// MARK: The fights

/// A face-off: `left` facing right, `right` facing left, `dist` sprite pixels apart, `p` image pixels a sprite pixel,
/// at moment `t`, with the fight effects between them, as the app draws them.
func fight(_ left: Cast, _ right: Cast, centre: CGFloat, dist: Double, p: CGFloat, t: Double) {
    let (lr, rr) = fightRoles(left.weapon, right.weapon)
    let headroom = 30.0, margin = 30.0
    func sprite(_ who: Cast, role: FightRole, x: CGFloat, mirrored: Bool) {
        let c = PixelCanvas(72, 52)
        who.draw(c, t: t, mode: .working, walking: false, role: role, asSession: true)
        if mirrored { c.flipHorizontally() }
        c.addOutline(C(0xFFFFFF, 0.92))
        let bodyX = (mirrored ? CGFloat(c.w) - 28 : 28) * p
        ctx.draw(c.makeImage()!, in: CGRect(x: x - bodyX, y: ground - 8 * p, width: CGFloat(c.w) * p, height: CGFloat(c.h) * p))
    }
    let lx = centre - CGFloat(dist) / 2 * p, rx = centre + CGFloat(dist) / 2 * p
    sprite(left, role: lr, x: lx, mirrored: false)
    sprite(right, role: rr, x: rx, mirrored: true)
    func fighter(_ who: Cast, x: Double, side: Double) -> Fighter {
        Fighter(weapon: who.weapon, x: x, k: 1, top: headroom, side: side, muzzle: who.muzzle, armoured: who.armoured,
                pivot: who.weaponPivot).dressed(as: who)
    }
    let fx = PixelCanvas(Int(dist + margin * 2), 52 + Int(headroom))
    drawFightFX(fx, t: t, left: fighter(left, x: margin, side: 1), right: fighter(right, x: margin + dist, side: -1))
    ctx.draw(fx.makeImage()!, in: CGRect(x: lx - CGFloat(margin) * p, y: ground - 8 * p, width: CGFloat(fx.w) * p, height: CGFloat(fx.h) * p))
}

let p: CGFloat = 4.4
fight(.hero(SWHero.luke), .villain(SWVillain.vader), centre: centres[0], dist: 46, p: p, t: 0.55)
fight(.hero(MarvelHero.thor), .villain(MarvelVillain.loki), centre: centres[1], dist: 56, p: p, t: 0.35)
fight(.hero(DCHero.batman), .villain(DCVillain.joker), centre: centres[2], dist: 56, p: p, t: 0.3)

// MARK: Lettering

/// The outline of `s` in Futura Condensed ExtraBold, centred on the origin.
func letters(_ s: String) -> CGPath {
    let font = CTFontCreateWithName("Futura-CondensedExtraBold" as CFString, 200, nil)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [.font: font]))
    let path = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let count = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: count), at = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
        CTRunGetPositions(run, CFRange(location: 0, length: count), &at)
        for i in 0..<count {
            if let g = CTFontCreatePathForGlyph(font, glyphs[i], nil) { path.addPath(g, transform: CGAffineTransform(translationX: at[i].x, y: at[i].y)) }
        }
    }
    let b = path.boundingBox
    var t = CGAffineTransform(translationX: -b.midX, y: -b.midY)
    return path.copy(using: &t)!
}

/// `s` as big as fits `width`×`height`, centred on `c` and tilted by `angle`: a block extrusion, a thick inkColor outline
/// and a face in `faces` (top colour, bottom colour), one per panel, or the same everywhere if there's one.
func word(_ s: String, at c: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, depth: Int, faces: [(UInt32, UInt32)]) {
    var path = letters(s)
    let k = min(width / path.boundingBox.width, height / path.boundingBox.height)
    var t = CGAffineTransform(scaleX: k, y: k).concatenating(CGAffineTransform(rotationAngle: angle))
        .concatenating(CGAffineTransform(translationX: c.x, y: c.y))
    path = path.copy(using: &t)!
    let b = path.boundingBox, step = b.height / 70, line = max(4, b.height * 0.14)
    ctx.saveGState()
    ctx.setLineJoin(.round)
    for i in stride(from: depth, through: 1, by: -1) {
        ctx.saveGState()
        ctx.translateBy(x: CGFloat(i) * step * 0.6, y: -CGFloat(i) * step)
        ctx.addPath(path); ctx.setStrokeColor(inkColor); ctx.setLineWidth(line); ctx.strokePath()
        ctx.addPath(path); ctx.setFillColor(inkColor); ctx.fillPath()
        ctx.restoreGState()
    }
    ctx.addPath(path); ctx.setStrokeColor(inkColor); ctx.setLineWidth(line); ctx.strokePath()
    for i in 0..<3 {
        let f = faces[min(i, faces.count - 1)]
        ctx.saveGState()
        if faces.count > 1 { ctx.addPath(panel(i)); ctx.clip() }
        ctx.addPath(path); ctx.clip()
        let face = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hex(f.0), hex(f.1)] as CFArray, locations: [0.2, 1])!
        ctx.drawLinearGradient(face, start: CGPoint(x: 0, y: b.maxY), end: CGPoint(x: 0, y: b.minY), options: [])
        ctx.setFillColor(hex(0xFFFFFF, 0.3)); ctx.fill(CGRect(x: b.minX, y: b.midY + b.height * 0.1, width: b.width, height: b.height * 0.09))
        ctx.restoreGState()
        if faces.count == 1 { break }
    }
    ctx.restoreGState()
}

/// A jagged starburst behind a sound effect.
func burst(_ c: CGPoint, r: CGFloat, color: UInt32, seed: Int) {
    let path = CGMutablePath(), n = 14
    for k in 0..<(n * 2) {
        let a = CGFloat(k) / CGFloat(n * 2) * 2 * .pi
        let rr = k % 2 == 0 ? r * (0.9 + 0.25 * rnd(seed + k)) : r * 0.6
        let pt = CGPoint(x: c.x + cos(a) * rr * 1.25, y: c.y + sin(a) * rr * 0.8)
        if k == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    ctx.saveGState()
    ctx.addPath(path); ctx.setFillColor(hex(color)); ctx.fillPath()
    ctx.addPath(path); ctx.setStrokeColor(inkColor); ctx.setLineWidth(5); ctx.setLineJoin(.round); ctx.strokePath()
    ctx.restoreGState()
}

// A sound effect in each panel, over the fight.
burst(CGPoint(x: 205, y: 352), r: 50, color: 0xFFE14D, seed: 11)
word("VWOOM!", at: CGPoint(x: 205, y: 352), width: 100, height: 42, angle: 0.12, depth: 4, faces: [(0xFFFFFF, 0xFF6A5A)])
burst(CGPoint(x: 640, y: 358), r: 54, color: 0x7FD0FF, seed: 31)
word("KRAKOOM!", at: CGPoint(x: 640, y: 358), width: 120, height: 42, angle: -0.1, depth: 4, faces: [(0xFFF6B0, 0xFFC21A)])
burst(CGPoint(x: 1040, y: 352), r: 48, color: 0xFF5A8A, seed: 51)
word("BLAM!", at: CGPoint(x: 1040, y: 352), width: 92, height: 42, angle: 0.1, depth: 4, faces: [(0xFFFFFF, 0xC8F06A)])

// The name, across all three panels.
word("CLAWD CLASH", at: CGPoint(x: 640, y: 522), width: 1060, height: 138, angle: 0.035, depth: 12,
     faces: [(0xFFFFFF, 0xFF8A8A), (0xFFFFFF, 0x8FB8FF), (0xFFF3B0, 0xFFC21A)])

// The gutters, over everything, cutting through the name too.
for i in 1...2 {
    ctx.move(to: CGPoint(x: cuts[i] - tilt, y: 0)); ctx.addLine(to: CGPoint(x: cuts[i] + tilt, y: H))
    ctx.setStrokeColor(inkColor); ctx.setLineWidth(18); ctx.strokePath()
    ctx.move(to: CGPoint(x: cuts[i] - tilt, y: 0)); ctx.addLine(to: CGPoint(x: cuts[i] + tilt, y: H))
    ctx.setStrokeColor(hex(0xFFFFFF)); ctx.setLineWidth(9); ctx.strokePath()
}

// The tagline in a caption box, along the bottom.
let tagline = "Your AI coding sessions as a pixel-art Star Clawds, Marvelous Clawds or Detective Clawds battle"
/// The tagline at the largest size (up to 25 pt) that fits the cover with a margin.
func taglineText(_ size: CGFloat) -> NSAttributedString {
    let font = NSFont(name: "Futura-Bold", size: size) ?? .boldSystemFont(ofSize: size)
    return NSAttributedString(string: tagline.uppercased(), attributes: [.font: font, .foregroundColor: NSColor(cgColor: inkColor)!, .kern: 1])
}
var tagSize: CGFloat = 25
while tagSize > 12 && taglineText(tagSize).size().width > W - 140 { tagSize -= 1 }
let text = taglineText(tagSize)
let ts = text.size()
let box = CGRect(x: (W - ts.width) / 2 - 22, y: 26, width: ts.width + 44, height: ts.height + 18)
ctx.saveGState()
ctx.setFillColor(inkColor); ctx.fill(box.offsetBy(dx: 6, dy: -6))
ctx.setFillColor(hex(0xFFE96B)); ctx.fill(box)
ctx.setStrokeColor(inkColor); ctx.setLineWidth(5); ctx.stroke(box)
ctx.restoreGState()
text.draw(at: NSPoint(x: box.minX + 22, y: box.minY + 9))

// A frame round the whole cover.
ctx.setStrokeColor(inkColor); ctx.setLineWidth(14); ctx.stroke(CGRect(x: 0, y: 0, width: W, height: H))

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
