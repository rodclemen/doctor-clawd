import CoreGraphics
import Foundation

// The Detective Clawds chest marks, shared by the heroes, the villains and the places: the C-shield (for Clawd) in
// place of the S-shield, the cowl mask (pointed ears over a domino mask) in place of the bat, a lamp in place of the lantern symbol and a flame in place
// of the Flash's bolt. Each keeps the size, place and colours of the mark it replaces.

/// How big an emblem is, in canvas pixels.
enum DCEmblemSize {
    case small    // C-shield 7×5, lamp 5×4, flame 4×4
    case medium   // C-shield 7×6, lamp 6×5, flame 6×4
    case large    // C-shield 9×6, lamp 7×6, flame 5×6
}

/// The C-shield, its top-left at (`x`, `y`): the five-sided shield with a C in `letter` on a `field` ground (nil:
/// just the C). The C's top bar runs along the shield's top edge and its stem down the left, open to the right.
func drawCShield(_ c: PixelCanvas, x: Int, y: Int, size: DCEmblemSize, letter: Px, field: Px?) {
    let rows: [String]
    switch size {
    case .small: rows = ["FCCCCCF", "CCFFFFF", ".CFFFF.", "..CCC..", "...C..."]
    case .medium: rows = ["CCCCCCC", "CCFFFFF", ".CFFFF.", ".CCCCF.", "..FFF..", "...C..."]
    case .large: rows = ["CCCCCCCCC", "CCFFFFFFF", ".CFFFFFF.", "..CCCCC..", "...FFF...", "....C...."]
    }
    var palette: [Character: Px] = ["C": letter]
    if let field { palette["F"] = field }
    c.pattern(x, y, rows, palette)
}

/// The cowl mask, `width` pixels wide (7, 11, 13, 14, 15, 16 or 21; others take the nearest): two pointed ears over
/// a domino mask with its eyes cut out, as rows of `#`.
func cowlMaskRows(_ width: Int) -> [String] {
    let all: [Int: [String]] = [
        7: [".#...#.", "##.#.##", ".#####."],
        11: [".#.......#.", ".##.....##.", "###########", "##..###..##", ".#########."],
        13: ["..#.......#..", "..##.....##..", ".###########.", "###..###..###", ".###########."],
        14: ["..#........#..", ".############.", "###..####..###", ".############."],
        15: ["..#.........#..", "..##.......##..", ".#############.", "###..#####..###", "###..#####..###", ".#############."],
        16: ["..##........##..", ".##############.", "###...####...###"],
        21: ["...#.............#...", "...##...........##...", "...###.........###...", "..#################..",
             ".###################.", ".####....###....####.", ".####....###....####.", "..#################..",
             "....####.....####...."],
    ]
    let w = all.keys.min { abs($0 - width) < abs($1 - width) }!
    return all[w]!
}

/// The cowl mask in `color`, its top-left at (`x`, `y`), `width` pixels wide (see `cowlMaskRows`).
func drawCowlMask(_ c: PixelCanvas, x: Int, y: Int, width: Int, color: Px) {
    c.pattern(x, y, cowlMaskRows(width), ["#": color])
}

/// The cowl mask as a smooth shape, `w` wide, centred on `c`, ears up (y grows upwards). Fill it even-odd, so the
/// eyes stay open.
func cowlMaskPath(_ c: CGPoint, width w: CGFloat) -> CGPath {
    let outer: [(CGFloat, CGFloat)] = [(-0.5, 0.02), (-0.44, 0.16), (-0.40, 0.42), (-0.26, 0.20), (0.26, 0.20), (0.40, 0.42),
                                       (0.44, 0.16), (0.5, 0.02), (0.42, -0.14), (0.14, -0.18), (0, -0.10), (-0.14, -0.18),
                                       (-0.42, -0.14)]
    let eye: [(CGFloat, CGFloat)] = [(-0.34, 0.03), (-0.22, 0.09), (-0.08, 0.04), (-0.20, -0.04)]
    let p = CGMutablePath()
    for shape in [outer, eye, eye.reversed().map { (-$0.0, $0.1) }] {
        p.addLines(between: shape.map { CGPoint(x: c.x + $0.0 * w, y: c.y + $0.1 * w) })
        p.closeSubpath()
    }
    return p
}

/// The lamp emblem, its top-left at (`x`, `y`): an oil lamp's flame over its bowl in `lamp`, on a `field` disc
/// (nil: the lamp straight on the suit). `rim` rings the disc where the emblem had one.
func drawLampEmblem(_ c: PixelCanvas, x: Int, y: Int, size: DCEmblemSize, lamp: Px, field: Px?, rim: Px? = nil) {
    let rows: [String]
    switch size {
    case .small: rows = [".RRR.", "RFLFR", "RLLLR", ".RRR."]
    case .medium: rows = [".FFFF.", "FFLFFF", "FFLLFF", "FLLLLF", ".FFFF."]
    case .large: rows = ["...L...", "..LLL..", "..LLL..", "...L...", ".LLLLL.", "..LLL.."]
    }
    var palette: [Character: Px] = ["L": lamp]
    if let field { palette["F"] = field }
    palette["R"] = rim ?? field
    c.pattern(x, y, rows, palette)
}

/// The flame emblem, its top-left at (`x`, `y`): a small flame in `flame`, on a `field` disc where the bolt had one.
func drawFlameEmblem(_ c: PixelCanvas, x: Int, y: Int, size: DCEmblemSize, flame: Px, field: Px?) {
    let rows: [String]
    switch size {
    case .small: rows = ["..L.", ".LL.", "LLLL", ".LL."]
    case .medium: rows = [".FFFF.", "FFLFFF", "FLLLFF", ".FFFF."]
    case .large: rows = ["...L.", "..LL.", ".LLL.", ".LLLL", ".LLL.", "..L.."]
    }
    var palette: [Character: Px] = ["L": flame]
    if let field { palette["F"] = field }
    c.pattern(x, y, rows, palette)
}
