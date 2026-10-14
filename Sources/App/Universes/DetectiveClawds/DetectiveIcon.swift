import Foundation

/// The C-shield (C for Clawd) on a 28×26 canvas, for the menu bar: the five-sided shield with a red C on yellow
/// inside a red border. `mono`: one colour with the yellow parts left out, for a template image macOS tints, so the C
/// reads as the shape and the yellow as holes in it.
func drawCShieldIcon(_ c: PixelCanvas, mono: Bool = false) {
    let red = mono ? C(0x000000) : C(0xD01C24), yellow = mono ? nil : C(0xFFD21E)
    // The C's top bar and stem join the border on the left, so the mono shape stays in one piece and the yellow
    // falls out as holes.
    let rows: [String] = [
        ".....RRRRRRRRRRRRRRRRRR.....",
        "....RRRRRRRRRRRRRRRRRRRR....",
        "...RRRYYYYYYYYYYYYYYYYRRR...",
        "..RRRYYYYYYYYYYYYYYYYYYRRR..",
        ".RRRRRRRRRRRRRRRRRRRRYYYRRR.",
        "RRRRRRRRRRRRRRRRRRRRRYYYYRRR",
        "RRRRRRRRRRRRRRRRRRRRRYYYYRRR",
        ".RRRRRRRRYYYYYYYYYYYYYYYRRR.",
        ".RRRRRRRRYYYYYYYYYYYYYYYRRR.",
        "..RRRRRRRRRRRRRRRRRRYYYRRR..",
        "...RRRRRRRRRRRRRRRRRYYRRR...",
        "....RRRRRRRRRRRRRRRRYRRR....",
        "....RRRYYYYYYYYYYYYYYRRR....",
        ".....RRRRRRRRRRRRRRRRRR.....",
        "......RRRRRRRRRRRRRRRR......",
        "......RRRYYYYYYYYYYRRR......",
        ".......RRRYYYYYYYYRRR.......",
        "........RRRYYYYYYRRR........",
        "........RRRYYYYYYRRR........",
        ".........RRRYYYYRRR.........",
        "..........RRRYYRRR..........",
        "...........RRRRRR...........",
        "...........RRRRRR...........",
        "............RRRR............",
        ".............RR.............",
    ]
    var palette: [Character: Px] = ["R": red]
    if let yellow { palette["Y"] = yellow }
    c.pattern(0, 0, rows, palette)
}
