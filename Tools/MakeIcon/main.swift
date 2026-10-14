import AppKit
import CoreText

// Renders Resources/AppIcon.png (1024²): a comic cover in three slanted panels, one per universe (Star Wars, Marvel,
// DC), with CLAWD CLASH across all three, each panel colouring its part of the name and the gutters cutting through
// the letters. Spider-Man hangs on his web over the name, Darth Vader raises his saber and Batman squares up under the
// Bat-Signal, all drawn with the app's own sprite code. build.sh turns it into AppIcon.icns.
//   swiftc Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          Sources/App/Universes/**/*.swift Sources/Shared/*.swift Tools/MakeIcon/main.swift -o build/makeicon \
//          && build/makeicon Resources/AppIcon.png

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
ctx.interpolationQuality = .none

func hex(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(h >> 16 & 0xFF) / 255, green: CGFloat(h >> 8 & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: a)
}
func rnd(_ i: Int) -> CGFloat { CGFloat(noise(i)) }
let inkColor = hex(0x111018)

// macOS icon grid: 824² rounded square, centred.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(shape); ctx.clip()

// MARK: The panels

/// Panel `i` (0 Star Wars, 1 Marvel, 2 DC): slanted, reaching past the tile.
func panel(_ i: Int) -> CGPath {
    let cuts: [CGFloat] = [-200, 380, 650, 1300], tilt: CGFloat = 70
    let p = CGMutablePath()
    p.addLines(between: [CGPoint(x: cuts[i] - tilt, y: 0), CGPoint(x: cuts[i + 1] - tilt, y: 0),
                         CGPoint(x: cuts[i + 1] + tilt, y: size), CGPoint(x: cuts[i] + tilt, y: size)])
    p.closeSubpath()
    return p
}

/// Halftone dots over `r`, `cell` apart, each `dot(at)` of its cell across.
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

// Each panel's sky: Sith red with stars, Marvel red into blue, Gotham's night blue under the Night Beacon; rays from the
// middle and halftone dots, heavier towards the bottom.
let skies: [(UInt32, UInt32)] = [(0x6E0C1A, 0x1A0610), (0xB81A2A, 0x0E2A6E), (0x2B3F7A, 0x0A1028)]
let middle = CGPoint(x: 512, y: 520)
for i in 0..<3 {
    ctx.saveGState()
    ctx.addPath(panel(i)); ctx.clip()
    let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hex(skies[i].0), hex(skies[i].1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
    for r in 0..<30 {
        let a = CGFloat(r) / 30 * 2 * .pi, w = 0.045 + 0.03 * rnd(r)
        ctx.move(to: middle)
        ctx.addLine(to: CGPoint(x: middle.x + cos(a - w) * 1400, y: middle.y + sin(a - w) * 1400))
        ctx.addLine(to: CGPoint(x: middle.x + cos(a + w) * 1400, y: middle.y + sin(a + w) * 1400))
        ctx.closePath()
    }
    ctx.setFillColor(hex(0xFFFFFF, 0.05)); ctx.fillPath()
    halftone(tile, color: hex(0x000000, 0.22), cell: 18) { p in 0.2 + 0.45 * (1 - (p.y - 100) / 824) }
    if i == 0 {
        for s in 0..<34 {   // pixel stars
            let big = rnd(9 + s * 3 + 2) > 0.85, d: CGFloat = big ? 8 : 4
            let x = 100 + rnd(9 + s * 3) * 824, y = 100 + rnd(9 + s * 3 + 1) * 824
            ctx.setFillColor(hex(0xFFFFFF, big ? 0.95 : 0.55))
            ctx.fill(CGRect(x: (x / d).rounded() * d, y: (y / d).rounded() * d, width: d, height: d))
        }
    }
    if i == 2 {
        let signal = CGPoint(x: 800, y: 800)
        ctx.setFillColor(hex(0xFFE36B, 0.9)); ctx.fillEllipse(in: CGRect(x: signal.x - 85, y: signal.y - 60, width: 170, height: 120))
        ctx.addPath(cowlMaskPath(signal, width: 140)); ctx.setFillColor(inkColor); ctx.fillPath(using: .evenOdd)
    }
    ctx.restoreGState()
}

// Spider-Man's web line, from above the frame down to where he hangs.
ctx.move(to: CGPoint(x: 520, y: 1024)); ctx.addLine(to: CGPoint(x: 520, y: 880))
ctx.setStrokeColor(hex(0xFFFFFF, 0.95)); ctx.setLineWidth(6); ctx.strokePath()

// MARK: The name

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

/// Faces of the name, top to bottom, per panel: rose-white for Star Wars, ice blue for Marvel, Bat-Signal yellow for DC.
let faces: [(UInt32, UInt32)] = [(0xFFFFFF, 0xFF8A8A), (0xFFFFFF, 0x8FB8FF), (0xFFF3B0, 0xFFC21A)]

/// A word of the name centred on `c`, as big as fits `width`×`height`, tilted by `angle`: a deep block extrusion, a
/// thick inkColor outline, and a face coloured by whichever panel each part of it is in, with a shine.
func word(_ s: String, at c: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, depth: Int) {
    var path = letters(s)
    let k = min(width / path.boundingBox.width, height / path.boundingBox.height)
    var t = CGAffineTransform(scaleX: k, y: k).concatenating(CGAffineTransform(rotationAngle: angle))
        .concatenating(CGAffineTransform(translationX: c.x, y: c.y))
    path = path.copy(using: &t)!
    let b = path.boundingBox, step = b.height / 80, line = b.height * 0.15
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
        ctx.saveGState()
        ctx.addPath(panel(i)); ctx.clip()
        ctx.addPath(path); ctx.clip()
        let face = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hex(faces[i].0), hex(faces[i].1)] as CFArray, locations: [0.2, 1])!
        ctx.drawLinearGradient(face, start: CGPoint(x: 0, y: b.maxY), end: CGPoint(x: 0, y: b.minY), options: [])
        ctx.setFillColor(hex(0xFFFFFF, 0.3)); ctx.fill(CGRect(x: b.minX, y: b.midY + b.height * 0.1, width: b.width, height: b.height * 0.09))
        ctx.restoreGState()
    }
    ctx.restoreGState()
}
word("CLAWD", at: CGPoint(x: 512, y: 640), width: 700, height: 175, angle: 0.05, depth: 12)
word("CLASH", at: CGPoint(x: 512, y: 440), width: 760, height: 190, angle: 0.05, depth: 14)

// The gutters, over the name, so they cut through it too.
for x in [380.0, 650.0] as [CGFloat] {
    ctx.move(to: CGPoint(x: x - 70, y: 0)); ctx.addLine(to: CGPoint(x: x + 70, y: size))
    ctx.setStrokeColor(inkColor); ctx.setLineWidth(22); ctx.strokePath()
    ctx.move(to: CGPoint(x: x - 70, y: 0)); ctx.addLine(to: CGPoint(x: x + 70, y: size))
    ctx.setStrokeColor(hex(0xFFFFFF)); ctx.setLineWidth(12); ctx.strokePath()
}

// MARK: The cast

/// `who` with its body's centre at `x` and feet at `feet`, `p` icon pixels a sprite pixel, white-outlined as in the app.
func put(_ who: Cast, t: Double, role: FightRole = .none, x: CGFloat, feet: CGFloat, p: CGFloat, mirrored: Bool = false, angle: CGFloat = 0) {
    let c = PixelCanvas(72, 52)
    who.draw(c, t: t, mode: .working, walking: false, role: role, asSession: true)
    c.addOutline(C(0xFFFFFF, 0.92))
    ctx.saveGState()
    ctx.translateBy(x: x, y: feet); ctx.rotate(by: angle)
    if mirrored { ctx.scaleBy(x: -1, y: 1) }
    // The body's centre is 28 columns in, the feet 8 rows up from the bottom.
    ctx.draw(c.makeImage()!, in: CGRect(x: -28 * p, y: -8 * p, width: 72 * p, height: 52 * p))
    ctx.restoreGState()
}

// Spider-Man hanging upside down on his web, over the name.
put(.hero(MarvelHero.spiderMan), t: 0.2, x: 505, feet: 885, p: 6.2, angle: .pi)

// Vader, his red saber raised along the hilt he holds.
let vx: CGFloat = 230, vy: CGFloat = 150, vp: CGFloat = 7.5
put(.villain(SWVillain.vader), t: 0.4, x: vx, feet: vy, p: vp)
let saber = CGMutablePath()
saber.move(to: CGPoint(x: vx + 13.5 * vp, y: vy + 9.5 * vp)); saber.addLine(to: CGPoint(x: vx + 0.5 * vp, y: vy + 30 * vp))
ctx.saveGState()
ctx.setLineCap(.round)
ctx.setShadow(offset: .zero, blur: 35, color: hex(0xFF2A2A))
ctx.addPath(saber); ctx.setStrokeColor(hex(0xFF2A2A)); ctx.setLineWidth(22); ctx.strokePath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)
ctx.addPath(saber); ctx.setStrokeColor(hex(0xFFFFFF)); ctx.setLineWidth(9); ctx.strokePath()
ctx.restoreGState()

// Batman squaring up, facing them.
put(.hero(DCHero.batman), t: 0.6, role: .duel, x: 790, feet: 130, p: 7.5, mirrored: true)
ctx.restoreGState()

// Subtle rim
ctx.addPath(shape)
ctx.setStrokeColor(hex(0xFFFFFF, 0.14)); ctx.setLineWidth(4); ctx.strokePath()

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
