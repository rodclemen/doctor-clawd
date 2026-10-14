import Foundation

/// The police box on a 28×26 canvas, for the menu bar: the lamp on top, the POLICE BOX sign, the windows and the panelled
/// doors. `mono`: one colour with the sign and the windows left out, for a template image macOS tints, so they read as
/// holes in the box.
func drawPoliceBoxIcon(_ c: PixelCanvas, mono: Bool = false) {
    let rows: [String] = [
        ".............LL.............",
        "............LLLL............",
        "........BBBBBBBBBBBB........",
        ".......BBBBBBBBBBBBBB.......",
        ".......BWWWWWWWWWWWWB.......",
        ".......BBBBBBBBBBBBBB.......",
        ".......BWWBWWBBWWBWWB.......",
        ".......BWWBWWBBWWBWWB.......",
        ".......BBBBBBBBBBBBBB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BBBBBBBBBBBBBB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BBBBBBBBBBBBBB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BBBBBBBBBBBBBB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BbbbbbBBbbbbbB.......",
        ".......BBBBBBBBBBBBBB.......",
        "......BBBBBBBBBBBBBBBB......",
        "......BBBBBBBBBBBBBBBB......",
    ]
    let palette: [Character: Px] = mono
        ? ["B": C(0x000000), "b": C(0x000000), "L": C(0x000000)]
        : ["B": C(0x1C3F94), "b": C(0x15306E), "W": C(0xF0F4FF), "L": C(0xFFF2B0)]
    c.pattern(0, 2, rows, palette)
}
