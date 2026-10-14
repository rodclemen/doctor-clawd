import AppKit

// Renders the README's roster and locations images with the app's own sprite code.
// Sessions are labelled with their character's name (as the app does with no project), agents with their task.
//   swiftc -swift-version 5 Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          Sources/App/Universes/**/*.swift Sources/Shared/*.swift \
//          Tools/RenderDocs/main.swift -o build/renderdocs && build/renderdocs docs

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
let bg = CGColor(red: 0.07, green: 0.075, blue: 0.11, alpha: 1)

func canvas(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(bg); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.interpolationQuality = .none
    draw(ctx)
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}

func label(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 13, color: NSColor = .white, width: CGFloat = 0) {
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .semibold), .foregroundColor: color])
    let w = a.size().width
    a.draw(at: NSPoint(x: width > 0 ? x + (width - w) / 2 : x, y: y))
}

/// A character cropped to its outline, drawn at `scale` with its feet on `ground`, centred in a cell.
func put(_ c: PixelCanvas, in ctx: CGContext, cellX: CGFloat, cellW: CGFloat, ground: CGFloat, scale: CGFloat) {
    c.addOutline(C(0xFFFFFF, 0.92))
    guard let b = c.opaqueBounds(), let img = c.makeImage()?.cropping(to: b) else { return }
    let feet = CGFloat(Sprite.height - 44) // canvas rows under the feet
    let bottomGap = CGFloat(Sprite.height) - b.maxY
    ctx.draw(img, in: CGRect(x: cellX + (cellW - b.width * scale) / 2, y: ground + (bottomGap - feet) * scale,
                             width: b.width * scale, height: b.height * scale))
}

extension Universe {
    /// File names go by the universe's name: "star-clawds".
    var slug: String { title.lowercased().replacingOccurrences(of: " ", with: "-") }
}

// MARK: Roster (one sheet per universe)

let scale: CGFloat = 3, cellW: CGFloat = 190, rowH: CGFloat = 190, cols = 5
let titleH: CGFloat = 54
func roster(_ u: Universe) {
    let theme = Theme.of(u)
    let villains = theme.cast.filter(\.isDark), heroes = theme.cast.filter { !$0.isDark && !u.isHem($0.id) }
    let vRows = (villains.count + cols - 1) / cols, hRows = (heroes.count + cols - 1) / cols
    let rosterH = Int(titleH * 2 + CGFloat(vRows + hRows) * rowH + 20)
    let sheet = canvas(Int(cellW) * cols, rosterH) { ctx in
        var top = CGFloat(rosterH)
        func section(_ title: String, _ who: [Cast], rows: Int, t: Double) {
            top -= titleH
            label(title, 20, top + 16, size: 20, color: NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1))
            for (i, w) in who.enumerated() {
                let c = PixelCanvas(Sprite.width, Sprite.height)
                w.draw(c, t: t, mode: .working, walking: false, role: .none, asSession: false)
                let x = CGFloat(i % cols) * cellW, rowTop = top - CGFloat(i / cols + 1) * rowH
                put(c, in: ctx, cellX: x, cellW: cellW, ground: rowTop + 34, scale: scale)
                label(w.name, x, rowTop + 10, width: cellW)
            }
            top -= CGFloat(rows) * rowH
        }
        section("THE HEROES", heroes, rows: hRows, t: 0.4)
        section("THE VILLAINS", villains, rows: vRows, t: 0.62)
    }
    save(sheet, "roster-\(u.slug).png")
}
for u in Universe.allCases { roster(u) }

// MARK: Desktop

// What it looks like along the bottom of your screen: sessions (name tags) and their agents (task labels) fighting,
// heroes against villains, Iron Man fighting from the air. The app's own sizes: a session is drawn 3 points per sprite
// pixel, an agent 2; this sheet is twice that, as on a Retina screen.
struct Extra { let who: Cast; let leader: Bool; let label: String; let x: Double; let facing: Double; let role: FightRole
               var up = 0.0 }
let S: CGFloat = 6, gy: CGFloat = 46, momentT = 0.25
let ak = 2.0 / 3
let marvelLineup: [[Extra]] = [
    [Extra(who: .villain(.thanos), leader: true, label: "Thanos", x: 30, facing: 1, role: .zap),
     Extra(who: .hero(.ironMan), leader: true, label: "Iron Man", x: 98, facing: -1, role: .hit, up: 10)],
    [Extra(who: .hero(.spiderMan), leader: false, label: "Check git history", x: 132, facing: 1, role: .shoot(offset: 0)),
     Extra(who: .villain(.greenGoblin), leader: false, label: "Write changelog", x: 182, facing: -1, role: .shoot(offset: blasterPeriod / 2))],
    [Extra(who: .hero(.wolverine), leader: false, label: "Plan the refactor", x: 214, facing: 1, role: .duel),
     Extra(who: .villain(.sabretooth), leader: false, label: "Review Overlay.swift", x: 244, facing: -1, role: .duel)],
    [Extra(who: .hero(.captainAmerica), leader: true, label: "Captain America", x: 282, facing: 1, role: .deflect),
     Extra(who: .villain(.redSkull), leader: true, label: "Red Skull", x: 352, facing: -1, role: .shoot(offset: 0))],
    [Extra(who: .hero(.groot), leader: false, label: "Run the test suite", x: 388, facing: 1, role: .cheer)],
]
let starWarsLineup: [[Extra]] = [
    [Extra(who: .villain(SWVillain.boba), leader: true, label: "", x: 30, facing: 1, role: .shoot(offset: 0)),
     Extra(who: .hero(SWHero.han), leader: false, label: "Review Overlay.swift", x: 92, facing: -1, role: .shoot(offset: blasterPeriod / 2))],
    [Extra(who: .hero(SWHero.leia), leader: false, label: "Run the test suite", x: 132, facing: 1, role: .shoot(offset: 0)),
     Extra(who: .villain(SWVillain.trooper), leader: false, label: "Write changelog", x: 182, facing: -1, role: .shoot(offset: blasterPeriod / 2))],
    [Extra(who: .hero(SWHero.luke), leader: false, label: "Find hook events", x: 214, facing: 1, role: .duel),
     Extra(who: .villain(SWVillain.maul), leader: false, label: "Audit permissions", x: 244, facing: -1, role: .duel)],
    [Extra(who: .hero(SWHero.obiwan), leader: true, label: "", x: 290, facing: 1, role: .duel),
     Extra(who: .villain(SWVillain.vader), leader: true, label: "", x: 347, facing: -1, role: .duel)],
    [Extra(who: .hero(SWHero.r2d2), leader: false, label: "Plan the refactor", x: 388, facing: 1, role: .cheer)],
]
let dcLineup: [[Extra]] = [
    [Extra(who: .villain(DCVillain.darkseid), leader: true, label: "Darkseid", x: 30, facing: 1, role: .zap),
     Extra(who: .hero(DCHero.superman), leader: true, label: "Superman", x: 98, facing: -1, role: .hit, up: 10)],
    [Extra(who: .hero(DCHero.greenArrow), leader: false, label: "Check git history", x: 132, facing: 1, role: .shoot(offset: 0)),
     Extra(who: .villain(DCVillain.deadshot), leader: false, label: "Write changelog", x: 182, facing: -1, role: .shoot(offset: blasterPeriod / 2))],
    [Extra(who: .hero(DCHero.batman), leader: false, label: "Plan the refactor", x: 214, facing: 1, role: .duel),
     Extra(who: .villain(DCVillain.bane), leader: false, label: "Review Overlay.swift", x: 244, facing: -1, role: .duel)],
    [Extra(who: .hero(DCHero.wonderWoman), leader: true, label: "Wonder Woman", x: 282, facing: 1, role: .deflect),
     Extra(who: .villain(DCVillain.joker), leader: true, label: "The Joker", x: 352, facing: -1, role: .shoot(offset: 0))],
    [Extra(who: .hero(DCHero.flash), leader: false, label: "Run the test suite", x: 388, facing: 1, role: .cheer)],
]
func desktop(_ lineup: [[Extra]], file: String) {
let desktop = canvas(2600, 400) { ctx in
    var tags: [CGRect] = []   // labels already placed: one that would overlap moves up a row, as in the app
    func sprite(_ e: Extra) {
        let c = PixelCanvas(Sprite.width, Sprite.height)
        e.who.draw(c, t: momentT, mode: .working, walking: false, role: e.role, asSession: e.leader, aloft: e.up > 4)
        if e.facing < 0 { c.flipHorizontally() }
        c.addOutline(C(0xFFFFFF, 0.92))
        let k: CGFloat = e.leader ? 1 : CGFloat(ak)
        let bodyX = (e.facing < 0 ? CGFloat(Sprite.width) - CGFloat(Sprite.bodyCenterX) : CGFloat(Sprite.bodyCenterX)) * S * k
        let y = gy + (e.leader ? 0 : 8 * S * (1 - k)) + CGFloat(e.up) * S * k
        ctx.draw(c.makeImage()!, in: CGRect(x: CGFloat(e.x) * S - bodyX, y: y, width: CGFloat(Sprite.width) * S * k,
                                           height: CGFloat(Sprite.height) * S * k))
        // Its label above the head, as the app boxes it: sessions dark grey, agents dark blue.
        let font = e.leader ? NSFont.monospacedSystemFont(ofSize: 20, weight: .bold) : NSFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        let text = NSAttributedString(string: e.leader ? e.who.name : e.label, attributes: [.font: font, .foregroundColor: NSColor.white])
        let ts = text.size()
        let top = y + CGFloat(Sprite.height - e.who.drawnTop()) * S * k + (e.leader ? 16 : 10)
        var box = CGRect(x: CGFloat(e.x) * S - ts.width / 2 - 10, y: top, width: ts.width + 20, height: ts.height + 8)
        while tags.contains(where: { $0.insetBy(dx: -4, dy: -2).intersects(box) }) { box.origin.y += box.height + 4 }
        tags.append(box)
        let path = CGPath(roundedRect: box, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(e.leader ? CGColor(gray: 0.08, alpha: 0.85) : CGColor(red: 0.05, green: 0.10, blue: 0.24, alpha: 0.85))
        ctx.fillPath()
        ctx.addPath(path)
        ctx.setStrokeColor(e.leader ? CGColor(gray: 1, alpha: 0.35) : CGColor(red: 0.45, green: 0.65, blue: 1, alpha: 0.5))
        ctx.setLineWidth(2); ctx.strokePath()
        text.draw(at: NSPoint(x: box.minX + 10, y: box.minY + 4))
    }
    for group in lineup {
        for e in group where !e.leader { sprite(e) }   // agents first, sessions on top
        for e in group where e.leader { sprite(e) }
        guard group.count == 2 else { continue }
        // The fight between them, from the app's effects code.
        let l = group[0], r = group[1], margin = 24.0, headroom = 24
        let left = l.x - margin, width = Int(r.x - l.x + margin * 2)
        func fighter(_ e: Extra, side: Double) -> Fighter {
            let k = e.leader ? 1 : ak
            return Fighter(weapon: e.who.weapon, x: e.x - left, k: k, top: 44 * (1 - k) - e.up * k + Double(headroom), side: side,
                           muzzle: e.who.muzzle, armoured: e.who.armoured, pivot: e.who.weaponPivot).dressed(as: e.who)
        }
        let fx = PixelCanvas(width, Sprite.height + headroom)
        drawFightFX(fx, t: momentT, left: fighter(l, side: 1), right: fighter(r, side: -1))
        ctx.draw(fx.makeImage()!, in: CGRect(x: CGFloat(left) * S, y: gy, width: CGFloat(width) * S,
                                            height: CGFloat(Sprite.height + headroom) * S))
    }
}
save(desktop, file)
print("wrote \(out)/\(file)")
}
desktop(starWarsLineup, file: "desktop-star-clawds.png")
desktop(marvelLineup, file: "desktop-marvelous-clawds.png")
desktop(dcLineup, file: "desktop-detective-clawds.png")

// MARK: Locations (one sheet per universe)

let lw = 250, lh = 70, lscale: CGFloat = 2, lcols = 3
let cellLW = CGFloat(lw) * lscale, cellLH = CGFloat(lh) * lscale + 26
func locationSheet(_ u: Universe) {
    let locs = Location.all(in: u)
    let lRows = (locs.count + lcols - 1) / lcols
    let sheet = canvas(Int(cellLW) * lcols + (lcols - 1) * 8, Int(cellLH) * lRows) { ctx in
        for (i, l) in locs.enumerated() {
            let c = PixelCanvas(lw, lh); l.drawStatic(c, floorRows: 10)
            let a = PixelCanvas(lw, lh); l.drawAnimated(a, floorRows: 10, t: 1.3)
            let x = CGFloat(i % lcols) * (cellLW + 8), y = CGFloat(lRows - 1 - i / lcols) * cellLH
            ctx.draw(c.makeImage()!, in: CGRect(x: x, y: y + 22, width: cellLW, height: CGFloat(lh) * lscale))
            ctx.draw(a.makeImage()!, in: CGRect(x: x, y: y + 22, width: cellLW, height: CGFloat(lh) * lscale))
            label(l.name, x, y + 4, size: 12, color: NSColor(white: 0.85, alpha: 1), width: cellLW)
        }
    }
    save(sheet, "locations-\(u.slug).png")
}
for u in Universe.allCases { locationSheet(u) }
print("wrote the roster and location sheets to \(out)")

// MARK: Social preview (1280×640, for GitHub → Settings → Social preview)

/// A 1280×640 preview: a title, a line under it, and face-offs on the horizon. Each group's first half faces right,
/// its second half left; groups (one per universe) stand apart.
func socialPreview(title: String, subtitle: String, groups: [[Cast]], file: String) {
let social = canvas(1280, 640) { ctx in
    let space = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                    CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(space, start: CGPoint(x: 0, y: 640), end: CGPoint(x: 0, y: 0), options: [])
    for i in 0..<160 {
        let big = noise(i * 3 + 2) > 0.85
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: big ? 0.9 : 0.45))
        let s: CGFloat = big ? 4 : 2
        ctx.fill(CGRect(x: CGFloat(noise(i * 3)) * 1280, y: 200 + CGFloat(noise(i * 3 + 1)) * 440, width: s, height: s))
    }
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: 1280, height: 150))
    ctx.setFillColor(CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)); ctx.fill(CGRect(x: 0, y: 147, width: 1280, height: 4))
    // title
    let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)
    func titleText(_ size: CGFloat) -> NSAttributedString {
        let font = NSFont(name: "Futura-CondensedExtraBold", size: size) ?? .systemFont(ofSize: size * 1.05, weight: .black)
        return NSAttributedString(string: title, attributes: [.font: font, .foregroundColor: yellow, .kern: size / 10])
    }
    let fit = min(80, 80 * 1180 / titleText(80).size().width)   // a long name shrinks to fit the width
    let title = titleText(fit)
    title.draw(at: NSPoint(x: (1280 - title.size().width) / 2, y: 470 + (80 - fit) / 2))
    let sub = NSAttributedString(string: subtitle,
                                 attributes: [.font: NSFont.systemFont(ofSize: 26, weight: .semibold), .foregroundColor: NSColor(white: 0.9, alpha: 1)])
    sub.draw(at: NSPoint(x: (1280 - sub.size().width) / 2, y: 418))
    // the crew, standing on the horizon
    // Heroes on the left facing right, villains on the right facing them, the whole line centred.
    // Waiting poses: weapons held up, nothing streaming off across the picture.
    func pose(_ who: Cast) -> (PixelCanvas) -> Void {
        { who.draw($0, t: 0.3, mode: .waiting, walking: false, role: .none, asSession: true) }
    }
    var s: CGFloat = 4, gap: CGFloat = 26, middle: CGFloat = 90
    var sprites: [(img: CGImage, w: CGFloat, h: CGFloat, bottomGap: CGFloat)] = []
    var breaks: Set<Int> = []                       // sprite indexes after which a wider gap comes
    var flat: [(Cast, Bool)] = []
    for g in groups {
        for (k, who) in g.enumerated() { flat.append((who, k >= g.count / 2)) }
        breaks.insert(flat.count - 1 - g.count / 2); breaks.insert(flat.count - 1)
    }
    for (who, facingLeft) in flat {
        let c = PixelCanvas(Sprite.width, Sprite.height); pose(who)(c)
        if facingLeft { c.flipHorizontally() }
        c.addOutline(C(0xFFFFFF, 0.92))
        guard let b = c.opaqueBounds(), let img = c.makeImage()?.cropping(to: b) else { continue }
        sprites.append((img, b.width * s, b.height * s, CGFloat(Sprite.height) - b.maxY))
    }
    let gaps = (0..<(sprites.count - 1)).map { breaks.contains($0) ? middle : gap }
    var total = sprites.reduce(0) { $0 + $1.w } + gaps.reduce(0, +)
    var k: CGFloat = 1
    if total > 1200 {                       // too wide: shrink everyone (and the spacing) to fit with margins
        k = 1200 / total
        s *= k; total = 1200
        sprites = sprites.map { ($0.img, $0.w * k, $0.h * k, $0.bottomGap) }
    }
    var x = (1280 - total) / 2
    for (i, sp) in sprites.enumerated() {
        ctx.draw(sp.img, in: CGRect(x: x, y: 150 + (sp.bottomGap - 8) * s, width: sp.w, height: sp.h))
        if i < gaps.count { x += sp.w + gaps[i] * k }
    }
}
save(social, file)
}
// Clawd Clash's own (social-preview.png) is a comic cover of its own: Tools/MakeSocial.
socialPreview(title: "CLAWD WARS", subtitle: "Your Claude Code sessions as a pixel-art Star Clawds battle on your desktop",
              groups: [[.hero(SWHero.luke), .hero(SWHero.han), .hero(SWHero.leia), .hero(SWHero.yoda),
                        .villain(SWVillain.vader), .villain(SWVillain.boba), .villain(SWVillain.kylo), .villain(SWVillain.trooper)]],
              file: "social-preview-star-clawds.png")
socialPreview(title: "CLAWDVENGERS: CLAWD WARS", subtitle: "Your Claude Code sessions as a pixel-art Marvelous Clawds battle on your desktop",
              groups: [[.hero(MarvelHero.thor), .hero(MarvelHero.spiderMan), .hero(MarvelHero.captainAmerica), .hero(MarvelHero.ironMan),
                        .villain(MarvelVillain.thanos), .villain(MarvelVillain.loki), .villain(MarvelVillain.greenGoblin), .villain(MarvelVillain.venom)]],
              file: "social-preview-marvelous-clawds.png")
socialPreview(title: "JUSTICE CLAWDS: CLAWD WARS", subtitle: "Your Claude Code sessions as a pixel-art Detective Clawds battle on your desktop",
              groups: [[.hero(DCHero.superman), .hero(DCHero.batman), .hero(DCHero.wonderWoman), .hero(DCHero.flash),
                        .villain(DCVillain.joker), .villain(DCVillain.lexLuthor), .villain(DCVillain.darkseid), .villain(DCVillain.harleyQuinn)]],
              file: "social-preview-detective-clawds.png")
print("wrote the social previews to \(out)")
