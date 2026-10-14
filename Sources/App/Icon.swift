import Foundation

/// Captain America's shield on a 28×26 canvas, for the menu bar: red and white rings round a blue disc with a white
/// star. `mono`: one colour with the white parts left out, for a template image macOS tints.
func drawMenuBarShield(_ c: PixelCanvas, mono: Bool = false) {
    let red = mono ? C(0x000000) : C(0xD0202A), silver = mono ? nil : C(0xF2F2F6)
    let blue = mono ? C(0x000000) : C(0x2A4FB0), star = mono ? nil : C(0xFFFFFF)
    let cx = 13.5, cy = 12.5
    // The star's ten corners, alternating tips and notches.
    let pts = (0..<10).map { i -> (x: Double, y: Double) in
        let r = i % 2 == 0 ? 4.6 : 1.9, a = -Double.pi / 2 + Double(i) * .pi / 5
        return (cx + cos(a) * r, cy + sin(a) * r)
    }
    func inStar(_ x: Double, _ y: Double) -> Bool {
        var inside = false
        var j = pts.count - 1
        for i in 0..<pts.count {
            let a = pts[i], b = pts[j]
            if (a.y > y) != (b.y > y), x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
            j = i
        }
        return inside
    }
    for y in 0..<c.h {
        for x in 0..<c.w {
            let d = hypot(Double(x) - cx, Double(y) - cy)
            let col: Px?
            switch d {
            case ...5: col = inStar(Double(x), Double(y)) ? star : blue
            case ...7.4: col = red
            case ...9.8: col = silver
            case ...12.4: col = red
            default: col = nil
            }
            if let col { c.px(x, y, col) }
        }
    }
}
