import AppKit
import AVFoundation
import CoreText

// Renders Clawd Clash's promo videos with the app's own sprites, places and transitions: the promo (one universe at a
// time, as in the app), the blooper reel (where the universes get mixed up), or both back to back. Each comes with
// its own synthesized soundtrack. Build it, then run it from the repo root (it reads Resources/AppIcon.png):
//   swiftc -O -swift-version 5 Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          Sources/App/Universes/**/*.swift Sources/Shared/*.swift Tools/RenderPromo/main.swift -o build/renderpromo
//   build/renderpromo storyboard promo           → promo/storyboard-promo.png (REEL=bloopers: storyboard-bloopers.png)
//   build/renderpromo video promo                → promo/clawd-clash-promo.mp4 (H.264 + AAC)
//   REEL=bloopers build/renderpromo video promo  → promo/clawd-clash-bloopers.mp4
//   REEL=full build/renderpromo video promo      → promo/clawd-clash-full.mp4: the promo, then the bloopers
//   REEL=starclawds build/renderpromo video promo → promo/star-clawds-promo.mp4: the Star Clawds trailer
//   REEL=marvelous build/renderpromo video promo  → promo/marvelous-clawds-promo.mp4: the Marvelous Clawds trailer
//   REEL=detective build/renderpromo video promo  → promo/detective-clawds-promo.mp4: the Detective Clawds trailer
//   build/renderpromo audio promo                → the soundtrack alone, as a .wav
//   build/renderpromo frame promo 9.5            → a single frame at 9.5 s
//   REEL=full build/renderpromo check            → renders every frame once (prints how far it got)
//   REEL=full build/renderpromo 720p promo       → promo/720p/Clawd-Clash.mp4: the copy under 10 MB for GitHub
// See promo-video-idea.md for the whole routine (reels, where each upload goes, building beside another session).

let W = 1920, H = 1080, fps = 30.0

// The stage the crew stands on. The whole frame by default; window mode narrows it to the scene strip.
var S = 6.0                      // screen pixels per sprite pixel for a session; agents are 2/3 of that
var groundY = 150.0              // fx-row of the floor line (the fx canvas is stageW/S × stageH/S, y down)
var stageW = Double(W), stageH = Double(H)

/// Runs `body` with the stage moved into `rect` (screen coordinates, y up), at `scale`, floor on fx-row `ground`.
func onStage(_ ctx: CGContext, _ rect: CGRect, scale: Double, ground: Double, _ body: () -> Void) {
    let saved = (S, groundY, stageW, stageH)
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.clip(to: CGRect(origin: .zero, size: rect.size))
    (S, groundY, stageW, stageH) = (scale, ground, Double(rect.width), Double(rect.height))
    body()
    (S, groundY, stageW, stageH) = saved
    ctx.restoreGState()
}

// MARK: Palette

let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)
let claudeOrange = CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)
func hexColor(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

/// Every AI Clawd Wars supports, with its outline colour from `AIStyle`.
enum AI: CaseIterable { case claude, desktop, codex, qwen, gemini, copilot
    var hex: UInt32 {
        switch self {
        case .claude: return 0xFFFFFF; case .desktop: return 0xFF9E7A; case .codex: return 0x6FD3FF
        case .qwen: return 0xC08CFF; case .gemini: return 0xFFD166; case .copilot: return 0x7CF5A4
        }
    }
    var ns: NSColor { hexColor(hex) }
    var name: String {
        switch self {
        case .claude: return "Claude Code"; case .desktop: return "Claude Desktop"; case .codex: return "OpenAI Codex"
        case .qwen: return "Qwen Code"; case .gemini: return "Gemini CLI"; case .copilot: return "GitHub Copilot CLI"
        }
    }
    var tag: String {
        switch self {
        case .claude: return "CLAUDE"; case .desktop: return "DESKTOP"; case .codex: return "CODEX"
        case .qwen: return "QWEN"; case .gemini: return "GEMINI"; case .copilot: return "GITHUB\nCOPILOT CLI"
        }
    }
}

// MARK: Easing

func clamp(_ v: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(max(v, a), b) }
func easeOut(_ v: Double) -> Double { let x = clamp(v); return 1 - pow(1 - x, 3) }
func easeIn(_ v: Double) -> Double { let x = clamp(v); return x * x * x }
func backOut(_ v: Double) -> Double { let x = clamp(v), c = 1.9; return 1 + (c + 1) * pow(x - 1, 3) + c * pow(x - 1, 2) }
func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double { a + (b - a) * f }

// MARK: Actors

struct Actor {
    var cast: Cast
    var x: Double                         // body centre, fx units
    var facing: Double = 1                // +1 right, -1 left
    var session = true                    // sessions are drawn large, agents at 2/3
    var mode: VaderMode = .working
    var role: FightRole = .none
    var walking = false
    var urgent = false
    var bubble: BubbleKind? = nil
    var label: String? = nil
    var labelSize: CGFloat? = nil
    var ai: AI = .claude
    var lift = 0.0                        // fx units off the floor (jumps, drop-ins)
    var alpha = 1.0
    var grow = 1.0                        // extra size (Claude stands a head taller in the line-up)
    var sitting = false
    var airborne = false                  // a flyer in the air
    var k: Double { (session ? 1 : 2.0 / 3) * grow }
    var top: Double { groundY - 44 * k - lift }
    var fighter: Fighter {
        Fighter(weapon: cast.weapon, x: x, k: k, top: top, side: facing, muzzle: cast.muzzle, armoured: cast.armoured,
                pivot: cast.weaponPivot).dressed(as: cast)
    }
}

/// A character's sprite with its AI's outline, for portraits.
func portrait(_ who: Cast, ai: AI, t: Double = 0.4) -> CGImage? {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: .working, walking: false, role: .none, asSession: true)
    c.addOutline(C(ai.hex, 0.92))
    guard let b = c.opaqueBounds() else { return nil }
    return c.makeImage()?.cropping(to: b)
}

/// Draws one actor (sprite, speech bubble, label) into a CG context whose units are screen pixels, y up.
func draw(_ a: Actor, _ ctx: CGContext, t: Double) {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    a.cast.draw(c, t: t, mode: a.mode, walking: a.walking, role: a.role, urgent: a.urgent, sitting: a.sitting,
                asSession: a.session, airborne: a.airborne)
    if a.facing < 0 { c.flipHorizontally() }
    c.addOutline(C(a.ai.hex, 0.92))
    guard let img = c.makeImage() else { return }
    let px = S * a.k
    let x0 = (a.facing > 0 ? a.x - Sprite.bodyCenterX * a.k : a.x - (Double(Sprite.width) - Sprite.bodyCenterX) * a.k) * S
    let yTop = a.top * S
    ctx.saveGState(); ctx.setAlpha(CGFloat(a.alpha))
    ctx.draw(img, in: CGRect(x: x0, y: stageH - yTop - Double(Sprite.height) * px,
                             width: Double(Sprite.width) * px, height: Double(Sprite.height) * px))
    // Speech bubble beside the head, tail pointing back at it.
    if let kind = a.bubble {
        let bc = PixelCanvas(Bubble.width, Bubble.height)
        drawBubble(bc, kind: kind, t: t, urgent: a.urgent, tailRight: a.facing < 0)
        if let bi = bc.makeImage() {
            let headRow = a.top + Double(a.cast.headTop) * a.k
            let bx = a.facing > 0 ? a.x + 7 * a.k : a.x - 7 * a.k - Double(Bubble.width)
            let by = headRow - Double(Bubble.height) + 2
            ctx.draw(bi, in: CGRect(x: bx * S, y: stageH - (by + Double(Bubble.height)) * S,
                                    width: Double(Bubble.width) * S, height: Double(Bubble.height) * S))
        }
    }
    if let l = a.label {
        let headRow = a.top + Double(a.cast.headTop) * a.k
        let z = S / 6
        chip(l, ctx, centerX: a.x * S, bottomY: stageH - headRow * S + (a.session ? 22 : 16) * z,
             size: a.labelSize ?? max(15, (a.session ? 30 : 23) * z), agent: !a.session, accent: a.ai)
    }
    ctx.restoreGState()
}

/// The overlay's label: monospaced white text in a dark rounded box (agents: navy box, blue border).
func chip(_ s: String, _ ctx: CGContext, centerX: Double, bottomY: Double, size: CGFloat, agent: Bool, accent: AI = .claude) {
    let font = NSFont.monospacedSystemFont(ofSize: size, weight: agent ? .semibold : .bold)
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let text = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.white, .paragraphStyle: p])
    let ts = text.size()
    let r = CGRect(x: centerX - ts.width / 2 - size * 0.5, y: bottomY, width: ts.width + size, height: ts.height + size * 0.4)
    let path = CGPath(roundedRect: r, cornerWidth: size * 0.3, cornerHeight: size * 0.3, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(agent ? CGColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 0.92) : CGColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 0.88))
    ctx.fillPath()
    ctx.addPath(path); ctx.setLineWidth(size * 0.1)
    let border = agent ? CGColor(red: 0.30, green: 0.48, blue: 0.85, alpha: 1)
                       : (accent == .claude ? CGColor(gray: 0.55, alpha: 1) : accent.ns.cgColor)
    ctx.setStrokeColor(border); ctx.strokePath()
    text.draw(in: CGRect(x: r.minX, y: r.minY + size * 0.2, width: r.width, height: ts.height))
}

/// Bolts, sparks and lightning between pairs, drawn on one fx-resolution pixel canvas over the whole stage.
func drawFX(_ pairs: [(Actor, Actor)], _ ctx: CGContext, t: Double) {
    guard !pairs.isEmpty else { return }
    let c = PixelCanvas(Int(stageW / S) + 1, Int(stageH / S) + 1)
    for (l, r) in pairs where fightFXVisible(t: t, l.cast.weapon, r.cast.weapon) { drawFightFX(c, t: t, left: l.fighter, right: r.fighter) }
    if let img = c.makeImage() {
        ctx.draw(img, in: CGRect(x: 0, y: stageH - Double(c.h) * S, width: Double(c.w) * S, height: Double(c.h) * S))
    }
}

// MARK: Text

func attributed(_ s: String, size: CGFloat, weight: NSFont.Weight = .heavy, color: NSColor = .white, alpha: Double = 1,
                font: NSFont? = nil, kern: CGFloat = 0) -> NSAttributedString {
    let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.6 * alpha)
    shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0, height: -3)
    return NSAttributedString(string: s, attributes: [.font: font ?? NSFont.systemFont(ofSize: size, weight: weight),
                                                      .foregroundColor: color.withAlphaComponent(alpha), .kern: kern, .shadow: shadow])
}

func text(_ s: String, _ ctx: CGContext, x: Double? = nil, y: Double, size: CGFloat, weight: NSFont.Weight = .heavy,
          color: NSColor = .white, alpha: Double = 1, font: NSFont? = nil, kern: CGFloat = 0) {
    let a = attributed(s, size: size, weight: weight, color: color, alpha: alpha, font: font, kern: kern)
    a.draw(at: NSPoint(x: x ?? (Double(W) - a.size().width) / 2, y: y))
}

/// A caption that slides up and fades in at `start` (shot-local seconds).
func caption(_ s: String, _ ctx: CGContext, local: Double, start: Double = 0.1, y: Double = 900, size: CGFloat = 64,
             color: NSColor = .white, weight: NSFont.Weight = .heavy) {
    let f = easeOut((local - start) / 0.35)
    guard f > 0 else { return }
    text(s, ctx, y: y - 30 * (1 - f), size: size, weight: weight, color: color, alpha: f)
}

/// A small pill naming the mode on show ("DESKTOP MODE", "WINDOW MODE"), top-left.
func modeBadge(_ s: String, _ ctx: CGContext, local: Double) {
    let f = easeOut((local - 0.2) / 0.3)
    guard f > 0 else { return }
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 26, weight: .heavy),
                                                       .foregroundColor: NSColor.black, .kern: 3])
    let sz = a.size()
    let r = CGRect(x: 60 - 40 * (1 - f), y: 980, width: sz.width + 36, height: sz.height + 16)
    ctx.saveGState(); ctx.setAlpha(CGFloat(f))
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: r.height / 2, cornerHeight: r.height / 2, transform: nil))
    ctx.setFillColor(yellow.cgColor); ctx.fillPath()
    a.draw(at: NSPoint(x: r.minX + 18, y: r.minY + 8))
    ctx.restoreGState()
}

// MARK: Backgrounds

/// The user's desktop: a dusky wallpaper with three terminal windows (dimmed once the battle starts).
func desktop(_ ctx: CGContext, dim: Double, floor: Bool = true) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.20, green: 0.21, blue: 0.29, alpha: 1),
                                CGColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    // menu bar
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.35)); ctx.fill(CGRect(x: 0, y: H - 34, width: W, height: 34))
    let lines = [["claude ▸ refactor the hook installer", "● Reading HookInstaller.swift", "● Editing 3 files…", "✻ Thinking…"],
                 ["codex ▸ write the changelog", "● Bash(git log --oneline)", "", "Allow this command?  ❯ Yes   No"],
                 [reel == "starclawds" ? "gemini ▸ add a \(Cast.hero(SWHero.tauntaun).name.lowercased())" : reel == "marvelous" ? "gemini ▸ polish the shield" : "gemini ▸ fix the clawdarang", "✓ Done in 4m 12s", "", "> _"]]
    for i in 0..<3 {
        let r = CGRect(x: 110 + Double(i) * 580, y: 330 + Double(i % 2) * 70, width: 540, height: 360)
        ctx.saveGState(); ctx.setAlpha(CGFloat(1 - dim * 0.75))
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: CGColor(gray: 0, alpha: 0.5))
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 14, cornerHeight: 14, transform: nil))
        ctx.setFillColor(CGColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0)
        trafficLights(ctx, x: r.minX + 18, y: r.maxY - 30)
        for (j, l) in lines[i].enumerated() {
            let col: NSColor = j > 0 ? NSColor(white: 0.8, alpha: 1) : (i == 0 ? NSColor(cgColor: claudeOrange)! : [AI.codex, .gemini][i - 1].ns)
            NSAttributedString(string: l, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 21, weight: .medium),
                                                       .foregroundColor: col])
                .draw(at: NSPoint(x: r.minX + 24, y: r.maxY - 90 - Double(j) * 44))
        }
        ctx.restoreGState()
    }
    // the dark floor band the battle stands on
    if floor {
        ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.14, alpha: dim * 0.55))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: Int(Double(H) - groundY * S + 6)))
    }
}

func trafficLights(_ ctx: CGContext, x: Double, y: Double, d: Double = 14) {
    for (j, col) in [CGColor(red: 1, green: 0.37, blue: 0.34, alpha: 1), CGColor(red: 1, green: 0.74, blue: 0.18, alpha: 1),
                     CGColor(red: 0.16, green: 0.79, blue: 0.25, alpha: 1)].enumerated() {
        ctx.setFillColor(col); ctx.fillEllipse(in: CGRect(x: x + Double(j) * d * 1.7, y: y, width: d, height: d))
    }
}

func space(_ ctx: CGContext, t: Double) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    for i in 0..<220 {
        let big = noise(i * 3 + 2) > 0.85
        let tw = 0.6 + 0.4 * sin(t * 3 + Double(i))
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: (big ? 0.9 : 0.45) * tw))
        let s = big ? 6.0 : 3.0
        let x = (noise(i * 3) * Double(W) - t * (big ? 40 : 20)).truncatingRemainder(dividingBy: Double(W))
        ctx.fill(CGRect(x: x < 0 ? x + Double(W) : x, y: 250 + noise(i * 3 + 1) * Double(H - 250), width: s, height: s))
    }
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 240))
    ctx.setFillColor(claudeOrange); ctx.fill(CGRect(x: 0, y: 236, width: W, height: 6))
}

let appIcon: CGImage? = NSImage(contentsOfFile: "Resources/AppIcon.png")?.cgImage(forProposedRect: nil, context: nil, hints: nil)


// MARK: Window mode

struct Card {
    var who: Cast; var ai: AI; var name: String; var project: String
    var status: String; var statusColor: NSColor
    var lines: [(String, NSColor)]
    var agents: [(Cast, String, String, String)] = []   // portrait, name, task, detail
}

let dimText = NSColor(white: 0.62, alpha: 1), bodyText = NSColor(white: 0.9, alpha: 1)

/// Draws a card with its top-left at (x, top); returns its height. `z` scales the app's point sizes.
@discardableResult
func drawCard(_ c: Card, _ ctx: CGContext, x: Double, top: Double, width: Double, panel: NSColor, z: Double) -> Double {
    let pad = 14 * z, lineH = 19 * z, agentH = 36 * z
    let h = pad * 2 + 22 * z + Double(c.lines.count) * lineH + (c.agents.isEmpty ? 0 : 6 * z + Double(c.agents.count) * agentH)
    let r = CGRect(x: x, y: top - h, width: width, height: h)
    let box = CGPath(roundedRect: r, cornerWidth: 8 * z, cornerHeight: 8 * z, transform: nil)
    ctx.addPath(box); ctx.setFillColor((panel.blended(withFraction: 0.35, of: .black) ?? panel).withAlphaComponent(0.94).cgColor); ctx.fillPath()
    ctx.addPath(box); ctx.setStrokeColor(c.ai.ns.withAlphaComponent(0.55).cgColor); ctx.setLineWidth(1.5 * z); ctx.strokePath()

    func put(_ s: NSAttributedString, _ px: Double, _ py: Double) { s.draw(at: NSPoint(x: px, y: py)) }
    func str(_ s: String, _ size: Double, _ w: NSFont.Weight, _ col: NSColor, mono: Bool = false) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [.font: mono ? NSFont.monospacedSystemFont(ofSize: size * z, weight: w)
                                                                : NSFont.systemFont(ofSize: size * z, weight: w), .foregroundColor: col])
    }
    // portrait, pixel-crisp, bottom-centred in a 96×80 (app points) box
    if let img = portrait(c.who, ai: c.ai) {
        let k = (min(96 * z / Double(img.width), 80 * z / Double(img.height), 2 * z)).rounded(.down)
        let w = Double(img.width) * k, ih = Double(img.height) * k
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.draw(img, in: CGRect(x: r.minX + 10 * z + (96 * z - w) / 2, y: r.maxY - pad - 80 * z, width: w, height: ih))
        ctx.restoreGState()
    }
    let tx = r.minX + 26 * z + 96 * z
    var ty = r.maxY - pad - 18 * z
    let status = str(c.status, 11, .bold, c.statusColor, mono: true)
    let sw = status.size().width
    let pill = CGRect(x: r.maxX - 12 * z - sw - 14 * z, y: ty - 3 * z, width: sw + 14 * z, height: 19 * z)
    ctx.addPath(CGPath(roundedRect: pill, cornerWidth: 9.5 * z, cornerHeight: 9.5 * z, transform: nil))
    ctx.setFillColor(c.statusColor.withAlphaComponent(0.16).cgColor); ctx.fillPath()
    put(status, pill.minX + 7 * z, pill.minY + 2 * z)
    let header = NSMutableAttributedString(attributedString: str(c.name, 14, .bold, .white))
    header.append(str("  ·  " + c.project, 13, .semibold, c.ai.ns))
    put(header, tx, ty)
    ty -= 22 * z
    for (l, col) in c.lines { put(str(l, 11.5, .regular, col), tx, ty); ty -= lineH }
    if !c.agents.isEmpty {
        ty -= 6 * z
        for (who, name, task, detail) in c.agents {
            if let img = portrait(who, ai: c.ai) {
                let k = (min(36 * z / Double(img.width), 30 * z / Double(img.height))).rounded(.down)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: tx - 4 * z, y: ty - 14 * z, width: Double(img.width) * k, height: Double(img.height) * k))
                ctx.restoreGState()
            }
            let title = NSMutableAttributedString(attributedString: str(name, 11.5, .semibold, .white))
            title.append(str("  ·  " + task, 11.5, .regular, c.ai.ns))
            put(title, tx + 40 * z, ty)
            put(str(detail, 10.5, .regular, dimText), tx + 40 * z, ty - 16 * z)
            ty -= agentH
        }
    }
    return h
}


// MARK: Window mode, in any universe

/// What one window shows: its place, the crew in the scene strip, and the cards below.
struct WindowSpec {
    let place: Location
    let crew: (_ local: Double, _ t: Double) -> (actors: [Actor], fights: [(Actor, Actor)])
    let cards: (_ local: Double) -> [(group: AI?, card: Card)]
}

/// The "Show in Window" window: themed title bar, the place with the crew in it, a card per session.
func windowMode(_ ctx: CGContext, frame r: CGRect, local: Double, t: Double, spec: WindowSpec) {
    let loc = spec.place
    let panel = loc.panel
    let z = 2.0, cz = 1.3                         // app points → screen pixels (window chrome, cards)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 60, color: CGColor(gray: 0, alpha: 0.6))
    let outline = CGPath(roundedRect: r, cornerWidth: 22, cornerHeight: 22, transform: nil)
    ctx.addPath(outline); ctx.setFillColor((panel.blended(withFraction: 0.45, of: .black) ?? panel).cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(outline); ctx.clip()
    let barH = 30 * z
    trafficLights(ctx, x: r.minX + 20, y: r.maxY - barH / 2 - 7, d: 15)
    let where_ = NSAttributedString(string: loc.name.uppercased(), attributes: [
        .font: NSFont.systemFont(ofSize: 10.5 * z, weight: .semibold), .foregroundColor: NSColor(white: 0.78, alpha: 1), .kern: 1.2 * z])
    where_.draw(at: NSPoint(x: r.maxX - where_.size().width - 28, y: r.maxY - barH / 2 - where_.size().height / 2))
    // the scene strip: the place at 2 px per pixel in the app, so 4 here
    let px = Double(Scenes.pixel) * z
    let stripH = 150.0 * z                        // the app's strip: 75 rows of art at 2 pt a row
    let strip = CGRect(x: r.minX, y: r.maxY - barH - stripH, width: r.width, height: stripH)
    let cw = Int((strip.width / px).rounded(.up)), ch = Int(stripH / px)
    let floorRows = Int(20 / Double(Scenes.pixel))
    let room = PixelCanvas(cw, ch); loc.drawStatic(room, floorRows: floorRows)
    let live = PixelCanvas(cw, ch); loc.drawAnimated(live, floorRows: floorRows, t: t)
    ctx.saveGState(); ctx.interpolationQuality = .none
    for c in [room, live] { if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: strip.minX, y: strip.minY, width: Double(cw) * px, height: Double(ch) * px)) } }
    ctx.restoreGState()
    onStage(ctx, strip, scale: px, ground: Double(ch) - Double(floorRows) * 0.45) {
        let crew = spec.crew(local, t)
        for a in crew.actors { draw(a, ctx, t: t) }
        drawFX(crew.fights, ctx, t: t)
    }
    // the cards, grouped by AI
    var top = strip.minY - 10 * cz
    let x = r.minX + 10 * cz, w = r.width - 20 * cz
    for (group, card) in spec.cards(local) {
        if let g = group {
            let label = NSAttributedString(string: g.name.uppercased(), attributes: [.font: NSFont.systemFont(ofSize: 10.5 * cz, weight: .heavy),
                                                                                      .kern: 1.2 * cz, .foregroundColor: g.ns])
            let gs = label.size()
            label.draw(at: NSPoint(x: x + 2 * cz, y: top - gs.height - 2 * cz))
            ctx.setFillColor(g.ns.withAlphaComponent(0.35).cgColor)
            ctx.fill(CGRect(x: x + gs.width + 10 * cz, y: top - gs.height / 2 - 2 * cz, width: w - gs.width - 12 * cz, height: cz))
            top -= 22 * cz
        }
        top -= drawCard(card, ctx, x: x, top: top, width: w, panel: panel, z: cz) + 10 * cz
    }
    ctx.restoreGState()
}

let green = NSColor(srgbRed: 0.45, green: 0.85, blue: 0.45, alpha: 1), red = NSColor(srgbRed: 1, green: 0.42, blue: 0.42, alpha: 1)

/// A window in `u`: a Claude session fighting another AI's, two Claude agents cheering, and its cards. After `needsAt`
/// the other AI's session stops and asks for you.
func windowSpec(_ u: Universe, needsAt: Double = 99, at override: Location? = nil) -> WindowSpec {
    let (place, claude, other, agentA, agentB, extra, prompt, otherPrompt): (Location, Cast, Cast, Cast, Cast, Cast, String, String) = {
        switch u {
        case .starWars: return (.cantina, .villain(SWVillain.vader), .hero(SWHero.luke), .hero(SWHero.han), .hero(SWHero.chewie),
                                .hero(SWHero.r2d2), "You: “make the cape swish more”", "You: “make the hero section pop”")
        case .marvel: return (.avengersTower, .hero(MarvelHero.captainAmerica), .villain(MarvelVillain.redSkull),
                              .hero(MarvelHero.spiderMan), .hero(MarvelHero.blackWidow), .villain(MarvelVillain.hydraAgent),
                              "You: “make the shield bounce twice”", "You: “make the hero section pop”")
        case .dc: return (.gotham, .hero(DCHero.batman), .villain(DCVillain.joker), .hero(DCHero.robin), .hero(DCHero.nightwing),
                          .villain(DCVillain.jokerGoon), "You: “make the clawdarang come back”", "You: “put a smile on that error page”")
        case .doctor: return (.consoleRoom, .hero(DoctorHero.doctorTen), .villain(DoctorVillain.dalick), .hero(DoctorHero.doctorTen),
                              .hero(DoctorHero.doctorTen), .villain(DoctorVillain.dalick), "You: “make the rotor pump faster”",
                              "You: “exterminate the dead code”")
        }
    }()
    let duel = fightIsCloseQuarters(claude.weapon, other.weapon)
    return WindowSpec(place: override ?? place, crew: { local, t in
        let needs = local > needsAt
        let roles = fightRoles(claude.weapon, other.weapon)
        var c = Actor(cast: claude, x: 140, role: needs ? .none : roles.0)
        var o = Actor(cast: other, x: duel ? 197 : 214, facing: -1, role: roles.1, ai: .codex)
        if needs { o.role = .none; o.mode = .waiting; o.bubble = .waiting; o.urgent = true; o.lift = abs(sin(t * 2 * .pi * 1.6)) * 4; c.mode = .working }
        let a = Actor(cast: agentA, x: 72, session: false, role: .cheer, label: "Run the tests")
        let b = Actor(cast: agentB, x: 30, session: false, role: .cheer, label: "Check git history")
        let e = Actor(cast: extra, x: 290, facing: -1, session: false, ai: .codex)
        return ([b, a, c, o, e], needs ? [] : [(c, o)])
    }, cards: { local in
        let ticks = max(0, Int(local))
        let now = ["Now: Read Overlay.swift", "Now: Edit WindowMode.swift", "Now: Bash: swift build"][min(2, max(0, Int(local / 0.9)))]
        let needs = local > needsAt
        return [(nil, Card(who: claude, ai: .claude, name: claude.name, project: "idle-claude", status: "WORKING · \(24 + ticks)s",
                           statusColor: green, lines: [("claude-opus-5-5", dimText), (now, bodyText), (prompt, bodyText)],
                           agents: [(agentA, agentA.name, "Run the tests", "Bash: swift test · \(34 + ticks)s · 9 tool calls"),
                                    (agentB, agentB.name, "Check git history", "Bash: git log · 1m \(21 + ticks)s · 25 tool calls")])),
                (.codex, Card(who: other, ai: .codex, name: other.name, project: "website",
                              status: needs ? "NEEDS YOU · \(max(1, Int(local - needsAt) + 1))s" : "THINKING",
                              statusColor: needs ? red : NSColor(white: 0.85, alpha: 1),
                              lines: [("gpt-5-codex", dimText), (needs ? "Wants to run: npm run deploy" : "Now: Thinking…", bodyText),
                                      (otherPrompt, bodyText)]))]
    })
}

/// The window, where every promo shot puts it.
let windowRect = CGRect(x: 300, y: 20, width: 1320, height: 800)

// MARK: Pixel places and helpers

let fxW = W / 6, fxH = H / 6

/// A pixel canvas onto the screen, crisp, `scale` screen pixels a pixel, `dy` lifting it.
func blit(_ c: PixelCanvas, _ ctx: CGContext, scale: Double = 6, dx: Double = 0, dy: Double = 0) {
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.draw(img, in: CGRect(x: dx, y: Double(H) - Double(c.h) * scale - dy, width: Double(c.w) * scale, height: Double(c.h) * scale))
    ctx.restoreGState()
}

/// One of the app's places at frame size, still art plus what moves (`frozen` stops the moving layer at that time).
func place(_ l: Location, floorRows: Int, t: Double, w: Int = fxW, h: Int = fxH) -> PixelCanvas {
    let c = PixelCanvas(w, h)
    l.drawStatic(c, floorRows: floorRows)
    l.drawAnimated(c, floorRows: floorRows, t: t)
    return c
}

/// `s` in `color`; in "DETECTIVE CLAWDS" only the D and the C at full strength, the rest faded, so it reads DC.
func inked(_ s: String, _ attrs: [NSAttributedString.Key: Any], color: NSColor, alpha: Double) -> NSAttributedString {
    var a = attrs; a[.foregroundColor] = color.withAlphaComponent(alpha)
    let out = NSMutableAttributedString(string: s, attributes: a)
    if s.uppercased() == Universe.dc.title.uppercased() {
        out.addAttribute(.foregroundColor, value: color.withAlphaComponent(alpha * 0.32), range: NSRange(location: 0, length: out.length))
        for i in [0, (s as NSString).range(of: " ").location + 1] {
            out.addAttribute(.foregroundColor, value: color.withAlphaComponent(alpha), range: NSRange(location: i, length: 1))
        }
    }
    return out
}

/// A comic caption box: yellow, a thick black border, black italic capitals.
func captionBox(_ s: String, _ ctx: CGContext, center: CGPoint, size: CGFloat, alpha: Double = 1) {
    let font = NSFontManager.shared.convert(NSFont.systemFont(ofSize: size, weight: .black), toHaveTrait: .italicFontMask)
    let a = inked(s, [.font: font], color: .black, alpha: alpha)
    let sz = a.size()
    let r = CGRect(x: center.x - sz.width / 2 - size * 0.7, y: center.y - sz.height / 2 - size * 0.45,
                   width: sz.width + size * 1.4, height: sz.height + size * 0.9)
    ctx.saveGState(); ctx.setAlpha(CGFloat(alpha))
    ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(r.offsetBy(dx: 10, dy: -10))
    ctx.setFillColor(CGColor(red: 1, green: 0.88, blue: 0.29, alpha: 1)); ctx.fill(r)
    ctx.setStrokeColor(CGColor(gray: 0, alpha: 1)); ctx.setLineWidth(6); ctx.stroke(r)
    ctx.restoreGState()
    a.draw(at: NSPoint(x: r.minX + size * 0.7, y: r.minY + size * 0.45))
}

/// A comic speech balloon around `s`, centred on `c`, its tail pointing at `tail` (screen pixels, y up).
func balloon(_ s: String, _ ctx: CGContext, center c: CGPoint, tail: CGPoint, size: CGFloat = 40, width: CGFloat = 640,
             color: NSColor = .black, alpha: Double = 1) {
    guard alpha > 0 else { return }
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .heavy),
                                                       .foregroundColor: color.withAlphaComponent(alpha), .paragraphStyle: p])
    let box = a.boundingRect(with: NSSize(width: width, height: 800), options: [.usesLineFragmentOrigin])
    let rx = box.width / 2 + size * 1.0, ry = box.height / 2 + size * 0.7
    let oval = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
    // the tail: a wedge from under the balloon to the speaker
    let ang = atan2(tail.y - c.y, tail.x - c.x), spread = 0.22
    let base1 = CGPoint(x: c.x + cos(ang - spread) * rx * 0.7, y: c.y + sin(ang - spread) * ry * 0.7)
    let base2 = CGPoint(x: c.x + cos(ang + spread) * rx * 0.7, y: c.y + sin(ang + spread) * ry * 0.7)
    let tailPath = CGMutablePath(); tailPath.addLines(between: [base1, tail, base2]); tailPath.closeSubpath()
    ctx.saveGState(); ctx.setAlpha(CGFloat(alpha))
    ctx.setLineWidth(7); ctx.setLineJoin(.round); ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))
    ctx.addPath(tailPath); ctx.strokePath()
    ctx.addEllipse(in: oval); ctx.strokePath()
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.addPath(tailPath); ctx.fillPath()
    ctx.fillEllipse(in: oval)
    ctx.restoreGState()
    a.draw(with: NSRect(x: c.x - box.width / 2, y: c.y - box.height / 2, width: box.width, height: box.height), options: [.usesLineFragmentOrigin])
}

/// Where a character's head is on screen (for balloon tails), at the frame's own stage.
func headPoint(_ a: Actor) -> CGPoint { CGPoint(x: a.x * S, y: stageH - (a.top + Double(a.cast.headTop) * a.k) * S) }

// MARK: The cover: three slanted panels and CLAWD CLASH, as on the icon

/// Panel `i` (0 Star Clawds, 1 Marvelous Clawds, 2 Detective Clawds) at frame size.
func coverPanel(_ i: Int) -> CGPath {
    let cuts: [CGFloat] = [-400, 700, 1240, 2400], tilt: CGFloat = 110
    let p = CGMutablePath()
    p.addLines(between: [CGPoint(x: cuts[i] - tilt, y: 0), CGPoint(x: cuts[i + 1] - tilt, y: 0),
                         CGPoint(x: cuts[i + 1] + tilt, y: CGFloat(H)), CGPoint(x: cuts[i] + tilt, y: CGFloat(H))])
    p.closeSubpath()
    return p
}

let inkColor = CGColor(red: 0.067, green: 0.063, blue: 0.094, alpha: 1)

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

func hexCG(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(h >> 16 & 0xFF) / 255, green: CGFloat(h >> 8 & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: a)
}

/// A word of the name, block-extruded and ink-outlined, its face coloured by whichever panel each part is in.
func coverWord(_ ctx: CGContext, _ s: String, at c: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, depth: Int, scale: CGFloat) {
    let faces: [(UInt32, UInt32)] = [(0xFFFFFF, 0xFF8A8A), (0xFFFFFF, 0x8FB8FF), (0xFFF3B0, 0xFFC21A)]
    var path = letters(s)
    let k = min(width / path.boundingBox.width, height / path.boundingBox.height) * scale
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
        ctx.addPath(coverPanel(i)); ctx.clip()
        ctx.addPath(path); ctx.clip()
        let face = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hexCG(faces[i].0), hexCG(faces[i].1)] as CFArray, locations: [0.2, 1])!
        ctx.drawLinearGradient(face, start: CGPoint(x: 0, y: b.maxY), end: CGPoint(x: 0, y: b.minY), options: [])
        ctx.setFillColor(hexCG(0xFFFFFF, 0.3)); ctx.fill(CGRect(x: b.minX, y: b.midY + b.height * 0.1, width: b.width, height: b.height * 0.09))
        ctx.restoreGState()
    }
    ctx.restoreGState()
}

/// The gutters between the panels, white on ink.
func coverGutters(_ ctx: CGContext) {
    for x in [700.0, 1240.0] as [CGFloat] {
        ctx.move(to: CGPoint(x: x - 110, y: 0)); ctx.addLine(to: CGPoint(x: x + 110, y: CGFloat(H)))
        ctx.setStrokeColor(inkColor); ctx.setLineWidth(30); ctx.strokePath()
        ctx.move(to: CGPoint(x: x - 110, y: 0)); ctx.addLine(to: CGPoint(x: x + 110, y: CGFloat(H)))
        ctx.setStrokeColor(hexCG(0xFFFFFF)); ctx.setLineWidth(16); ctx.strokePath()
    }
}

/// The three worlds side by side: each panel its universe's place, tinted like the icon, with its arch-enemies
/// fighting in it.
func coverPanels(_ ctx: CGContext, t: Double, fighters: Bool = true, dim: Double = 0) {
    let worlds: [(Location, UInt32, UInt32)] = [(.deathStar, 0x6E0C1A, 0x1A0610), (.titan, 0xB81A2A, 0x0E2A6E), (.gotham, 0x2B3F7A, 0x0A1028)]
    for (i, (loc, top, bottom)) in worlds.enumerated() {
        ctx.saveGState()
        ctx.addPath(coverPanel(i)); ctx.clip()
        blit(place(loc, floorRows: 30, t: t), ctx)
        let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hexCG(top, 0.45), hexCG(bottom, 0.25)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
        if fighters {
            let pairs: [(Actor, Actor)] = [
                (Actor(cast: .hero(SWHero.luke), x: 30, role: .duel), Actor(cast: .villain(SWVillain.vader), x: 87, facing: -1, role: .duel)),
                (Actor(cast: .hero(MarvelHero.captainAmerica), x: 132, role: .block), Actor(cast: .villain(MarvelVillain.thanos), x: 196, facing: -1, role: .zap)),
                (Actor(cast: .hero(DCHero.batman), x: 236, role: .deflect), Actor(cast: .villain(DCVillain.joker), x: 296, facing: -1, role: .shoot(offset: 0))),
            ]
            let (a, b) = pairs[i]
            draw(a, ctx, t: t); draw(b, ctx, t: t)
            drawFX([(a, b)], ctx, t: t)
        }
        ctx.restoreGState()
    }
    if dim > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: dim)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
    coverGutters(ctx)
}

// MARK: The clapperboard

/// A film slate, `w` wide, centred on `c`: the board with its writing, and the striped clapper, `open` 0…1.
func clapper(_ ctx: CGContext, center c: CGPoint, width w: CGFloat, open: Double, take: String, title: String = "CLAWD CLASH") {
    let h = w * 0.62, arm = w * 0.17
    let board = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h - arm)
    ctx.saveGState()
    ctx.setFillColor(inkColor); ctx.fill(board)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.9)); ctx.setLineWidth(w * 0.006)
    ctx.stroke(board.insetBy(dx: w * 0.03, dy: w * 0.03))
    for y in [0.36, 0.62] as [CGFloat] { ctx.move(to: CGPoint(x: board.minX + w * 0.03, y: board.minY + board.height * y)); ctx.addLine(to: CGPoint(x: board.maxX - w * 0.03, y: board.minY + board.height * y)) }
    ctx.strokePath()
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: w * 0.15) ?? .systemFont(ofSize: w * 0.15, weight: .black)
    let big = NSAttributedString(string: title, attributes: [.font: tf, .foregroundColor: NSColor.white, .kern: w * 0.01])
    big.draw(at: NSPoint(x: c.x - big.size().width / 2, y: board.minY + board.height * 0.64))
    let small = NSFont.monospacedSystemFont(ofSize: w * 0.05, weight: .bold)
    for (i, s) in ["SCENE  CLASH", "TAKE  \(take)", "ROLL  3"].enumerated() {
        NSAttributedString(string: s, attributes: [.font: small, .foregroundColor: NSColor.white])
            .draw(at: NSPoint(x: board.minX + w * [0.06, 0.45, 0.74][i], y: board.minY + board.height * 0.43))
    }
    NSAttributedString(string: "DIRECTOR  CLAWD", attributes: [.font: small, .foregroundColor: NSColor(white: 0.75, alpha: 1)])
        .draw(at: NSPoint(x: board.minX + w * 0.06, y: board.minY + board.height * 0.12))
    // the clapper: a striped bar hinged at the top left, swinging up to `open`
    func stripes(_ r: CGRect) {
        ctx.setFillColor(CGColor(gray: 0.97, alpha: 1)); ctx.fill(r)
        ctx.saveGState(); ctx.clip(to: r)
        ctx.setFillColor(inkColor)
        var x = r.minX - r.height
        while x < r.maxX { let p = CGMutablePath(); p.addLines(between: [CGPoint(x: x, y: r.minY), CGPoint(x: x + r.height * 0.9, y: r.minY), CGPoint(x: x + r.height * 1.9, y: r.maxY), CGPoint(x: x + r.height, y: r.maxY)]); ctx.addPath(p); ctx.fillPath(); x += r.height * 2 }
        ctx.restoreGState()
        ctx.setStrokeColor(inkColor); ctx.setLineWidth(w * 0.008); ctx.stroke(r)
    }
    stripes(CGRect(x: board.minX, y: board.maxY, width: w, height: arm * 0.55))           // the fixed bar
    ctx.translateBy(x: board.minX, y: board.maxY + arm * 0.55)
    ctx.rotate(by: CGFloat(open) * 0.45)
    stripes(CGRect(x: 0, y: 0, width: w, height: arm * 0.55))                               // the clapstick
    ctx.restoreGState()
}

/// A take ending: "CUT!" shouted from off screen at the right, then a small slate snapping shut with the take number.
func cutAndSlate(_ ctx: CGContext, local l: Double, at: Double, take: String, wrap: Bool = false) {
    let u = l - at
    guard u > 0 else { return }
    let pop = backOut(u / 0.25)
    if wrap {
        balloon("CUT! THAT'S A WRAP!", ctx, center: CGPoint(x: Double(W) / 2, y: 900), tail: CGPoint(x: Double(W) / 2 + 300, y: Double(H) + 40),
                size: 70 * pop, width: 1500, color: NSColor(srgbRed: 0.85, green: 0.1, blue: 0.1, alpha: 1))
    } else {
        balloon("CUT!", ctx, center: CGPoint(x: Double(W) - 260, y: 820), tail: CGPoint(x: Double(W) + 60, y: 900), size: 90 * pop,
                width: 500, color: NSColor(srgbRed: 0.85, green: 0.1, blue: 0.1, alpha: 1))
    }
    if u > 0.45 {
        let s = u - 0.45
        let slide = easeOut(s / 0.2)
        clapper(ctx, center: CGPoint(x: 250 - 300 * (1 - slide), y: 860), width: 380, open: max(0, 1 - s / 0.25), take: take)
    }
}

// MARK: Shots and their transitions

/// How a shot comes in: a hard cut, the soft promo wipe, or one of the app's own universe transitions (over the whole
/// frame, or inside the window, `inWindow`).
enum Into {
    case cut
    case wipe
    case starWars(clock: Bool)
    case marvel(ComicTrip)
    case dc(DCComicTrip)

    var duration: Double {
        switch self {
        case .cut: return 0
        case .wipe: return softWipe
        case .starWars: return Wipe.duration * 1.6
        case .marvel(let t): return t.duration * 1.25
        case .dc(let t): return t.duration * 1.25
        }
    }
}

struct Shot {
    let name: String; var start: Double; var end: Double
    var into: Into = .wipe
    var inWindow = false
    let render: (CGContext, Double, Double) -> Void

    func shifted(_ by: Double) -> Shot { var s = self; s.start += by; s.end += by; return s }
}

/// Something drawn over the cut, unaffected by transitions (a caption that runs across several shots).
struct Overlay { let start: Double; let end: Double; let draw: (CGContext, Double) -> Void }


// MARK: The promo

/// The desktop brawl in one universe: Claude's session against another AI's, and two agents trading shots.
func brawl(_ ctx: CGContext, _ u: Universe, local: Double, t: Double, drop: Bool, chrome: Bool = true) {
    desktop(ctx, dim: drop ? easeOut(local / 0.4) : 1)
    let fall = { (d: Double) -> Double in drop ? max(0, 40 * (1 - easeIn((local - d) / 0.3))) : 0 }
    let (a, b, c, d): (Cast, Cast, Cast, Cast) = {
        switch u {
        case .starWars: return (.villain(SWVillain.vader), .hero(SWHero.luke), .hero(SWHero.han), .villain(SWVillain.trooper))
        case .marvel: return (.hero(MarvelHero.captainAmerica), .villain(MarvelVillain.redSkull), .hero(MarvelHero.spiderMan), .villain(MarvelVillain.greenGoblin))
        case .dc: return (.hero(DCHero.batman), .villain(DCVillain.joker), .hero(DCHero.greenArrow), .villain(DCVillain.captainCold))
        case .doctor: return (.hero(DoctorHero.doctorTen), .villain(DoctorVillain.dalick), .hero(DoctorHero.doctorTen), .villain(DoctorVillain.dalick))
        }
    }()
    let (ra, rb) = fightRoles(a.weapon, b.weapon), close = fightIsCloseQuarters(a.weapon, b.weapon)
    var s1 = Actor(cast: a, x: 58, role: ra, label: "idle-claude")
    var s2 = Actor(cast: b, x: close ? 115 : 130, facing: -1, role: rb, label: "website", ai: .codex)
    let (rc, rd) = fightRoles(c.weapon, d.weapon)
    var g1 = Actor(cast: c, x: 196, session: false, role: rc, label: "Run the test suite")
    var g2 = Actor(cast: d, x: 258, facing: -1, session: false, role: rd, label: "Review Overlay.swift", ai: .codex)
    if case .shoot = rd, case .shoot = rc { g2.role = .shoot(offset: blasterPeriod / 2) }
    s1.lift = fall(0); s2.lift = fall(0.12); g1.lift = fall(0.24); g2.lift = fall(0.32)
    for x in [s1, s2, g1, g2] where x.lift < 40 { draw(x, ctx, t: t) }
    if !drop || local > 0.45 { drawFX([(s1, s2), (g1, g2)], ctx, t: t) }
    guard chrome else { return }
    badge(u.title.uppercased(), ctx, alpha: 1)
    // each universe its own caption
    let (line, sub): (String, String) = {
        switch u {
        case .starWars: return ("One app. Three universes.", "Star Clawds: laser swords, blasters, 81 characters in 22 places.")
        case .marvel: return ("Switch to Marvelous Clawds in Settings.", "Shields, hammers and webs: 193 characters in 43 places.")
        case .dc: return ("Or pick Detective Clawds.", "Capes, power rings and one very serious bat: 207 characters in 43 places.")
        case .doctor: return ("Or step into Doctor Clawd.", "Sonic screwdrivers, a blue box and a lot of shouting about extermination.")
        }
    }()
    caption(line, ctx, local: local, start: drop ? 0.3 : 0.15, y: 900)
    caption(sub, ctx, local: local, start: drop ? 0.6 : 0.4, y: 830, size: 40, color: yellow, weight: .bold)
}

/// The universe on show, top left, in a yellow pill.
func badge(_ s: String, _ ctx: CGContext, alpha: Double) {
    let a = inked(s, [.font: NSFont.monospacedSystemFont(ofSize: 26, weight: .heavy), .kern: 3], color: .black, alpha: 1)
    let sz = a.size()
    let r = CGRect(x: 60, y: 980, width: sz.width + 36, height: sz.height + 16)
    ctx.saveGState(); ctx.setAlpha(CGFloat(alpha))
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: r.height / 2, cornerHeight: r.height / 2, transform: nil))
    ctx.setFillColor(yellow.cgColor); ctx.fillPath()
    a.draw(at: NSPoint(x: r.minX + 18, y: r.minY + 8))
    ctx.restoreGState()
}

/// The status line-up in one universe: working, thinking, needs you, napping.
func statusLineup(_ ctx: CGContext, local: Double, t: Double) {
    desktop(ctx, dim: 1)
    let cast: [(Cast, AI, VaderMode, BubbleKind?, String, NSColor, Bool)] = [
        (.hero(MarvelHero.thor), .claude, .working, nil, "WORKING", green, false),
        (.villain(MarvelVillain.loki), .qwen, .thinking, .thinking, "THINKING…", NSColor(white: 0.9, alpha: 1), false),
        (.villain(MarvelVillain.ultron), .gemini, .waiting, .waiting, "NEEDS YOU!", red, false),
        (.villain(MarvelVillain.thanos), .copilot, .idle, .sleeping, "NAPPING", NSColor(srgbRed: 0.6, green: 0.55, blue: 1, alpha: 1), true),
    ]
    for (i, (who, ai, mode, bubble, word, col, sits)) in cast.enumerated() {
        let d = 0.1 + Double(i) * 0.22
        let f = backOut((local - d) / 0.35)
        guard local > d else { continue }
        var a = Actor(cast: who, x: 48 + Double(i) * 75, mode: mode, bubble: bubble, ai: ai)
        a.sitting = sits
        a.urgent = mode == .waiting
        if a.urgent { a.lift = abs(sin(t * 2 * .pi * 1.6)) * 6 }
        a.lift += (1 - f) * -8
        a.alpha = clamp(f)
        draw(a, ctx, t: t)
        let w = NSAttributedString(string: word, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .black), .kern: 2]).size().width
        text(word, ctx, x: a.x * S - w / 2, y: 70, size: 40, weight: .black, color: col, alpha: clamp(f), kern: 2)
    }
    badge(Universe.marvel.title.uppercased(), ctx, alpha: 1)
    caption("All fun and games, and you still see everything.", ctx, local: local, start: 0.05, y: 900, size: 58)
    caption("(Thanoz sits down when the job's done. Relatable.)", ctx, local: local, start: 0.9, y: 835, size: 36, color: yellow, weight: .bold)
}

/// Subagents arriving with their jobs on their labels.
func agentsArrive(_ ctx: CGContext, local: Double, t: Double) {
    desktop(ctx, dim: 1)
    draw(Actor(cast: .hero(DCHero.wonderWoman), x: 262, facing: -1, mode: .standGuard, label: "idle-claude"), ctx, t: t)
    let crew: [(DCHero, String, Double)] = [(.robin, "Find hook events", 190), (.nightwing, "Write changelog", 140),
                                            (.cyborg, "Check git history", 90), (.krypto, "Plan the refactor", 40)]
    for (i, (who, task, stop)) in crew.enumerated() {
        let f = easeOut((local - Double(i) * 0.18) / 0.75)
        draw(Actor(cast: .hero(who), x: lerp(-30, stop, f), session: false, walking: f < 0.98, label: task), ctx, t: t)
    }
    badge(Universe.dc.title.uppercased(), ctx, alpha: 1)
    caption("Every subagent reports for duty.", ctx, local: local, start: 0.1, y: 900)
    caption("Its job is right there on its label. No more guessing.", ctx, local: local, start: 0.45, y: 835, size: 40, color: yellow, weight: .bold)
}

/// The app window over a dimmed desktop.
func windowShot(_ ctx: CGContext, _ u: Universe, local: Double, t: Double, rise: Bool, needsAt: Double = 99, at place: Location? = nil) {
    desktop(ctx, dim: 1, floor: false)
    let f = rise ? easeOut(local / 0.6) : 1, s = 0.94 + 0.06 * f
    let b = windowRect
    let r = CGRect(x: b.midX - b.width * s / 2, y: b.minY + 20 * (1 - f), width: b.width * s, height: b.height * s)
    windowMode(ctx, frame: r, local: local, t: t, spec: windowSpec(u, needsAt: needsAt, at: place))
}

// MARK: The three showcases (from the single-universe promos)

/// Deep-space starfield; `shift` moves it up (the camera tilting down).
func starfield(_ c: PixelCanvas, shift: Double = 0, t: Double) {
    for i in 0..<260 {
        let x = Int(noise(i * 5) * Double(c.w))
        let y = Int((noise(i * 5 + 1) * Double(c.h + 120) - shift).rounded()) - 0
        guard y >= 0, y < c.h else { continue }
        let b = noise(i * 5 + 2)
        let tw = 0.75 + 0.25 * sin(t * 4 + Double(i))
        if b > 0.93 {                                   // a few bright ones with a little cross
            c.px(x, y, C(0xFFFFFF, tw)); c.px(x - 1, y, C(0xBFD8FF, 0.5 * tw)); c.px(x + 1, y, C(0xBFD8FF, 0.5 * tw))
            c.px(x, y - 1, C(0xBFD8FF, 0.5 * tw)); c.px(x, y + 1, C(0xBFD8FF, 0.5 * tw))
        } else {
            c.px(x, y, C(0xFFFFFF, (0.25 + b * 0.5) * tw))
        }
    }
}

/// Tatooine rising from the bottom of the frame, with its two moons. `rise` 0…1 brings it into view.
func tatooine(_ c: PixelCanvas, rise: Double) {
    let r = 330.0, cx = 205.0, cy = Double(c.h) + r - 34 - (1 - rise) * 70
    let bands = [C(0xE2B77A), C(0xD8A465), C(0xC98F52), C(0xDDAE70), C(0xB97C44), C(0xD39C5E)]
    for y in min(c.h, max(0, Int(cy - r)))..<c.h {
        let dy = Double(y) - cy
        let half = max(0, r * r - dy * dy).squareRoot()
        let x0 = max(0, Int(cx - half)), x1 = min(c.w - 1, Int(cx + half))
        guard x0 <= x1 else { continue }
        for x in x0...x1 {
            let dx = Double(x) - cx
            let lat = Int((dy + r) / 9 + noise(x / 7 + y * 3) * 1.2) % bands.count
            var col = bands[lat]
            // the night side to the left, dithered at the terminator
            let shade = (dx + r * 0.35) / (r * 0.6)
            if shade < 0 || (shade < 0.1 && (x + y) % 2 == 0) { col = C(0x3A2416) }
            else if shade < 0.2 && (x + y) % 3 == 0 { col = C(0x7A4E2C) }
            // thin bright atmosphere at the limb
            if hypot(dx, dy) > r - 1.5 && shade > 0 { col = C(0xF6E2B8) }
            c.px(x, y, col)
        }
    }
    // the two moons, up and to the left of the planet
    for (mx, my, mr) in [(70.0, cy - r - 40 + 30 * rise, 9.0), (98.0, cy - r - 18 + 30 * rise, 5.0)] {
        for y in Int(my - mr)...Int(my + mr) {
            for x in Int(mx - mr)...Int(mx + mr) where hypot(Double(x) - mx, Double(y) - my) <= mr && y >= 0 && y < c.h {
                let lit = Double(x) - mx > -mr * 0.2
                c.px(x, y, lit ? C(0xD9D2C4) : C(0x4A4640))
            }
        }
    }
}

/// The Tantive IV seen from behind as it flees: engine bank at the top, hammerhead nose at the bottom.
let tantiveRows = [
    "..EEEEEEEEE..",
    ".EEEEEEEEEEE.",
    ".HHHHHHHHHHH.",
    "HHHHHHHHHHHHH",
    "HHDHHDHHDHHDH",
    ".HHHHHHHHHHH.",
    "...HHHHHHH...",
    "....HHHHH....",
    "....HLHLH....",
    "....HHHHH....",
    "....HLHLH....",
    "....HHHHH....",
    "...HHHHHHH...",
    "..HHHHHHHHH..",
    "..HLLHHHLLH..",
    "..HHHHHHHHH..",
    "...HHHHHHH...",
    "....HHHHH....",
    ".....HWH.....",
    "......H......",
]

func tantive(t: Double) -> PixelCanvas {
    let c = PixelCanvas(15, tantiveRows.count + 2)
    c.pattern(1, 1, tantiveRows, ["H": C(0xD6D4CC), "D": C(0x8A8880), "L": C(0x6FA0D0), "W": C(0xFFFFFF),
                                  "E": C(0xFFC8D0, 0.75 + 0.25 * sin(t * 30))])
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// The Star Destroyer seen from below, nose pointing the way it flies (down the frame). `tipY` is the row of
/// its nose; the hull reaches `length` rows back up to the engine block.
let sdLength = 300.0, sdHalf = 190.0, sdX = 165.0

func starDestroyer(_ c: PixelCanvas, tipY: Double, t: Double) {
    let base = tipY - sdLength
    let lit = [C(0xA9ABB0), C(0x9A9CA2), C(0xB9BBC0)], shade = [C(0x8F9197), C(0x82848A), C(0x9C9EA4)]
    for y in min(c.h, max(0, Int(base) - 18))..<max(min(c.h, max(0, Int(base) - 18)), min(c.h, Int(tipY) + 1)) {
        let back = tipY - Double(y)                       // rows behind the nose
        if back > sdLength {                              // the engine block behind the hull
            let hw = sdHalf * 0.8
            let x0 = max(0, Int(sdX - hw)), x1 = min(c.w - 1, Int(sdX + hw))
            guard x0 <= x1 else { continue }
            for x in x0...x1 {
                let g = noise(y * 211 + x * 13)
                c.px(x, y, g > 0.9 ? C(0x6A6C72) : (x % 7 == 0 ? C(0x45474C) : C(0x55575D)))
            }
            continue
        }
        let hw = back * sdHalf / sdLength
        guard hw >= 0.5 else { c.px(Int(sdX), y, C(0xC9CBD0)); continue }
        let row = Int(back), band = row / 10
        let segW = 5 + Int(noise(band * 17) * 8)
        let x0 = max(0, Int(sdX - hw)), x1 = min(c.w - 1, Int(sdX + hw))
        guard x0 <= x1 else { continue }
        for x in x0...x1 {
            let dx = Double(x) - sdX, edge = hw - abs(dx)
            let seg = (x + 400) / segW
            let tone = noise(band * 131 + seg)
            let pal = dx < 0 ? lit : shade                                 // lit from the left
            var col = tone < 0.15 ? pal[1] : (tone > 0.85 ? pal[2] : pal[0])
            if (x + 400) % segW == 0 && edge > 3 { col = C(0x74767C) }      // plate seams
            if row % 10 == 0 && edge > 3 { col = C(0x6A6C72) }
            let g = noise(row * 313 + x * 7)
            if edge > 8 && g > 0.996 { col = C(0x55575D) } else if edge > 8 && g > 0.992 { col = C(0xD4D6DA) }   // greebles
            if edge >= 6 && edge < 7 { col = C(0x5E6066) }                 // trench along each edge
            if edge < 2.5 { col = dx < 0 ? C(0xD0D2D6) : C(0x6E7076) }     // bevelled rims
            if abs(dx) < 1.5 { col = C(0x6E7076) }                         // keel line
            if row > 118 && row < 150 && abs(dx) < 16 {                     // the docking bay
                col = (row == 119 || row == 149 || abs(dx) > 14.5) ? C(0x8A8C92) : C(0x24262A)
            }
            c.px(x, y, col)
        }
        // running lights along the edges
        if row % 18 == 7 {
            let on = sin(t * 6 + Double(row)) > 0
            c.px(Int(sdX - hw) + 3, y, on ? C(0xFFFFFF) : C(0x9FA3AA)); c.px(Int(sdX + hw) - 3, y, on ? C(0xFFFFFF) : C(0x9FA3AA))
        }
    }
    // three big engines glowing at the back, flickering
    let ey = Int(base) - 18
    for (k, ex) in [sdX - 80, sdX, sdX + 80].enumerated() {
        let r = (k == 1 ? 13.0 : 10.0) + sin(t * 25 + Double(k)) * 0.6
        for y in (ey - Int(r))...(ey + Int(r)) where y >= 0 && y < c.h {
            for x in Int(ex - r)...Int(ex + r) where x >= 0 && x < c.w {
                let d = hypot(Double(x) - ex, Double(y - ey))
                if d <= r { c.px(x, y, d < r * 0.45 ? C(0xFFFFFF) : (d < r * 0.75 ? C(0xBFE0FF) : C(0x6FB8FF))) }
            }
        }
    }
}

/// The chase: where the Tantive IV is at shot-local time `l` (fx units) and how big.
func tantivePos(_ l: Double) -> (x: Double, y: Double, k: Double) {
    let f = easeOut((l - 1.6) / 3.0)
    return (lerp(186, 150, f) + sin(l * 2.3) * 3, lerp(-28, 118, f) + (l > 4.6 ? (l - 4.6) * 3 : 0), lerp(1.4, 0.7, clamp((l - 1.6) / 6)))
}

func destroyerTip(_ l: Double) -> Double { -4 + (l - 3.0) * 85 }

func starClawsShowcase(_ ctx: CGContext, local l: Double, t: Double) {
    let tilt = easeOut((l - 0.2) / 1.6)
    let sky = PixelCanvas(fxW, fxH)
    sky.rect(0, 0, fxW, fxH, C(0x000000))
    starfield(sky, shift: 60 * tilt, t: t)
    tatooine(sky, rise: tilt)
    blit(sky, ctx)
    // the blockade runner, behind the destroyer
    let p = tantivePos(l)
    if l > 1.4 && l < 6.5 {                    // swallowed by the destroyer after that
        let tc = tantive(t: t)
        if let img = tc.makeImage() {
            let s = 6 * p.k
            ctx.saveGState(); ctx.interpolationQuality = .none
            ctx.draw(img, in: CGRect(x: p.x * 6 - Double(tc.w) * s / 2, y: Double(H) - (p.y * 6 + Double(tc.h) * s / 2),
                                     width: Double(tc.w) * s, height: Double(tc.h) * s))
            ctx.restoreGState()
        }
    }
    // the destroyer, closest to us
    let tip = destroyerTip(min(l, 7.05))      // it comes to rest with its engines at the top
    let fx = PixelCanvas(fxW, fxH)
    if tip > -2 {
        starDestroyer(fx, tipY: tip, t: t)
        fx.addOutline(C(0xFFFFFF, 0.92))
    }
    // red turbolaser bolts chasing the runner: from off the top at first, then from the destroyer's nose
    for i in 0..<40 {
        let born = 1.3 + Double(i) * 0.17
        let age = l - born
        guard age > 0, age < 0.55 else { continue }
        let tipAt = destroyerTip(born)
        let from = tipAt > 4 ? (sdX + (noise(i * 7) - 0.5) * 30, tipAt - noise(i * 7 + 1) * 20) : (150 + noise(i * 7) * 70, -4.0)
        let aim = tantivePos(born + 0.45)
        let miss = (noise(i * 7 + 2) - 0.5) * 34
        let to = (aim.x + miss, aim.y + abs(miss) * 0.3)
        let g = age / 0.55
        let x = lerp(from.0, to.0, g), y = lerp(from.1, to.1, g)
        let len = hypot(to.0 - from.0, to.1 - from.1)
        let ux = (to.0 - from.0) / max(len, 0.01), uy = (to.1 - from.1) / max(len, 0.01)
        fx.glowLine(x - ux * 7, y - uy * 7, x, y, core: C(0xFFE0E0), glow: C(0xFF2A2A), coreR: 0.6, glowR: 1.8)
        if g > 0.92 && abs(miss) < 8 { drawSparks(fx, x: to.0, y: to.1, t: t, size: 3) }
    }
    blit(fx, ctx)
}

/// The Battle of New York backdrop from the app, at frame size: the portal over Stark Tower, smoke, the Leviathans.
func newYork(_ t: Double, floorRows: Int = 14) -> PixelCanvas {
    let c = PixelCanvas(fxW, fxH)
    Location("battleOfNewYork").drawStatic(c, floorRows: floorRows)
    Location("battleOfNewYork").drawAnimated(c, floorRows: floorRows, t: t)
    return c
}

/// A burst behind the title: a jagged star.
func starburst(_ ctx: CGContext, center c: CGPoint, inner: Double, outer: Double, spikes: Int, color: CGColor, spin: Double) {
    let path = CGMutablePath()
    for i in 0..<(spikes * 2) {
        let a = Double(i) / Double(spikes * 2) * 2 * .pi + spin
        let r = i % 2 == 0 ? outer * (0.85 + 0.15 * noise(i)) : inner
        let p = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        i == 0 ? path.move(to: p) : path.addLine(to: p)
    }
    path.closeSubpath()
    ctx.addPath(path); ctx.setFillColor(color); ctx.fillPath()
    ctx.addPath(path); ctx.setStrokeColor(CGColor(gray: 0, alpha: 1)); ctx.setLineWidth(8); ctx.strokePath()
}

/// Where the giant Leviathan's tail is (fx units) and how big it is, at shot-local time `l`: it noses out of the
/// portal small, then swells and dives toward us until it fills the frame.
func leviathan(_ l: Double) -> (x: Double, y: Double, k: Double) {
    let f = clamp((l - 2.6) / 5.0)
    let e = f * f
    return (lerp(150, -120, e), lerp(14, 70, e), lerp(1, 9, e))
}

func clawvelShowcase(_ ctx: CGContext, local l: Double, t: Double) {
    // the city, slowly pushing in
    let zoom = 1 + 0.06 * clamp(l / 8)
    ctx.saveGState()
    ctx.translateBy(x: Double(W) / 2, y: Double(H) * 0.7); ctx.scaleBy(x: zoom, y: zoom)
    ctx.translateBy(x: -Double(W) / 2, y: -Double(H) * 0.7)
    blit(newYork(t), ctx)
    ctx.restoreGState()
    // the giant Leviathan, out of the portal and at us
    if l > 2.6 {
        let p = leviathan(l)
        let k = max(1, Int(p.k.rounded()))
        // its body arches about 16 units above and below its line, so leave that much room on both sides
        let c = PixelCanvas(60 * k + 40, 32 * k + 38)
        Scenes.battleOfNewYorkLeviathan(c, x: 20, y: 18 + 16 * k, k: k, flip: false)
        c.addOutline(C(0xFFFFFF, 0.92))
        let s = 6 * p.k / Double(k)
        blit(c, ctx, scale: s, dx: p.x * 6 - 20 * s, dy: p.y * 6 - (Double(c.h) - 18 - 16 * Double(k)) * s)
    }
    // Iron Man rockets up from the street to meet it, firing repulsors
    if l > 4.2 {
        let f = easeOut((l - 4.2) / 1.6)
        onStage(ctx, CGRect(x: 0, y: 0, width: W, height: H), scale: 6, ground: Double(fxH) + 10) {
            var im = Actor(cast: .hero(MarvelHero.ironMan), x: lerp(300, 236, f), facing: -1, role: .shoot(offset: 0))
            im.airborne = true
            im.lift = lerp(0, 110, f)
            draw(im, ctx, t: t)
            // repulsor blasts streaking up-left toward the beast
            let c = PixelCanvas(fxW, fxH + 10)
            for i in 0..<10 {
                let born = 4.9 + Double(i) * 0.3, age = l - born
                guard age > 0, age < 0.35 else { continue }
                let from = (im.x - 10, im.top + 30), to = (leviathan(born).x + 120, leviathan(born).y + 20)
                let g = age / 0.35
                let x = lerp(from.0, to.0, g), y = lerp(from.1, to.1, g)
                c.glowLine(x - (to.0 - from.0) * 0.04, y - (to.1 - from.1) * 0.04, x, y,
                           core: C(0xF4FCFF), glow: C(0x6FD8FF), coreR: 0.7, glowR: 2)
            }
            if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6)) }
        }
    }
}

/// A kaiju over Metropolis: a colossal horned beast stomps into the city, roars, and Superman flies up to meet it with
/// heat vision.

/// Fills a polygon on a pixel canvas (scanline, even-odd).
func fillPoly(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
    guard let y0 = pts.map({ $0.1 }).min(), let y1 = pts.map({ $0.1 }).max() else { return }
    for y in Int(y0.rounded(.down))...Int(y1.rounded(.up)) {             // rows off the canvas are clipped by rect
        let yy = Double(y) + 0.5
        var xs: [Double] = []
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            if (a.1 <= yy && b.1 > yy) || (b.1 <= yy && a.1 > yy) { xs.append(a.0 + (yy - a.1) / (b.1 - a.1) * (b.0 - a.0)) }
        }
        xs.sort()
        var i = 0
        while i + 1 < xs.count { c.rect(Int(xs[i].rounded()), y, max(1, Int(xs[i + 1].rounded()) - Int(xs[i].rounded())), 1, col); i += 2 }
    }
}

/// A filled ellipse (centre, radii) that tolerates any size.
func blob(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px) {
    guard rx > 0, ry > 0 else { return }
    for y in Int((cy - ry).rounded(.down))...Int((cy + ry).rounded(.up)) {
        let d = (Double(y) + 0.5 - cy) / ry
        guard abs(d) <= 1 else { continue }
        let half = rx * (1 - d * d).squareRoot()
        c.rect(Int((cx - half).rounded()), y, max(1, Int((half * 2).rounded())), 1, col)
    }
}

/// A horn: a chain of shrinking circles along a curve from the root to the tip, lit along one side.
func horn(_ c: PixelCanvas, from a: (Double, Double), bend b: (Double, Double), to e: (Double, Double), r: Double) {
    for i in 0...24 {
        let u = Double(i) / 24
        let x = (1 - u) * (1 - u) * a.0 + 2 * (1 - u) * u * b.0 + u * u * e.0
        let y = (1 - u) * (1 - u) * a.1 + 2 * (1 - u) * u * b.1 + u * u * e.1
        let rr = max(0.6, r * (1 - u * 0.9))
        blob(c, x, y, rr, rr, C(0xB8AE94))
        blob(c, x - rr * 0.3, y - rr * 0.3, rr * 0.55, rr * 0.55, C(0xECE4CC))
    }
}

/// The kaiju, facing left, on a 120×128 canvas: hulking and upright, slate-green hide with a pale plated belly, a row of
/// bone spines down its back, two great curved horns, burning orange eyes, a jaw that drops open to roar.
let kaijuW = 120, kaijuH = 128                // 18 rows of headroom over the 110-row body for the horns
func drawKaiju(_ c: PixelCanvas, t: Double, roar: Double, step: Double) {
    let hide = C(0x3E4A44), dark = C(0x232B28), lite = C(0x5E6E64), belly = C(0x8C8E70), bellyDark = C(0x6A6C54)
    c.oy = 18; defer { c.oy = 0 }
    let breathe = sin(t * 2.2) * 1.2, lift = -abs(sin(step * .pi)) * 2
    // the tail sweeping out behind, then the far leg
    for i in 0..<10 {
        let u = Double(i) / 9
        blob(c, 86 + u * 28, 92 - u * 16 + sin(t * 1.5 + u * 3) * 2, 11 - u * 8, 9 - u * 6, i % 2 == 0 ? hide : dark)
    }
    blob(c, 74, 90 + lift, 11, 15, dark)
    // the spines down the back
    for i in 0..<8 {
        let u = Double(i) / 7, x = 62 + u * 26, y = 26 + u * 46
        fillPoly(c, [(x - 4, y + 2), (x + 9 - u * 3, y - 10 + u * 3), (x + 4, y + 5)], C(0xD8D0B8))
        fillPoly(c, [(x - 1, y + 3), (x + 6 - u * 3, y - 6 + u * 3), (x + 4, y + 5)], C(0x9A927C))
    }
    // the body, the belly plates
    blob(c, 62, 60 + breathe * 0.5, 28, 32 + breathe, hide)
    blob(c, 70, 58, 18, 26, lite.alpha(0.35))
    blob(c, 54, 64 + breathe * 0.5, 15, 24, belly)
    for k in 0..<7 { c.rect(42, 46 + k * 6 + Int(breathe * 0.5), 26, 1, bellyDark) }
    // the near leg and its claws
    blob(c, 48, 92 + lift, 13, 15, hide)
    blob(c, 44, 104 + lift, 14, 5, dark)
    for k in 0..<3 { fillPoly(c, [(32 + Double(k) * 7, 103 + lift), (29 + Double(k) * 7, 108 + lift), (36 + Double(k) * 7, 106 + lift)], C(0xE8E0C8)) }
    // the arms reaching forward, claws out
    let sway = sin(t * 1.8) * 2
    for (k, (sx, sy)) in [(44.0, 46.0), (52.0, 50.0)].enumerated() {
        let hx = 18.0 + Double(k) * 6, hy = 56 + sway * (k == 0 ? 1 : -1)
        for i in 0...6 { let u = Double(i) / 6; blob(c, sx + (hx - sx) * u, sy + (hy - sy) * u, 7 - u * 2, 6 - u * 2, k == 0 ? hide : dark) }
        for j in 0..<3 { fillPoly(c, [(hx - 2, hy - 3 + Double(j) * 3), (hx - 9, hy - 2 + Double(j) * 3.5), (hx - 2, hy + Double(j) * 3)], C(0xE8E0C8)) }
    }
    // the head: heavy brow, long snout, a jaw that drops open
    let jaw = roar * 9
    let hx = 36.0, hy = 26.0 + breathe * 0.3
    blob(c, hx + 8, hy + 4, 16, 13, hide)                                         // skull
    fillPoly(c, [(hx - 2, hy - 6), (hx - 20, hy + 1), (hx - 18, hy + 6), (hx + 2, hy + 6)], hide)   // snout
    fillPoly(c, [(hx + 2, hy + 6 + jaw * 0.2), (hx - 18, hy + 8 + jaw), (hx - 14, hy + 13 + jaw), (hx + 12, hy + 14)], dark)   // lower jaw
    if roar > 0.1 {                                                               // the open mouth and its teeth
        fillPoly(c, [(hx - 17, hy + 6), (hx + 4, hy + 6), (hx + 4, hy + 7 + jaw * 0.8), (hx - 16, hy + 8 + jaw)], C(0x5A1A14))
        for k in 0..<5 {
            let x = hx - 15 + Double(k) * 4
            fillPoly(c, [(x, hy + 6), (x + 2, hy + 6), (x + 1, hy + 9)], C(0xF0E8D4))
            fillPoly(c, [(x, hy + 8 + jaw * (1 - Double(k) * 0.15)), (x + 2, hy + 8 + jaw * (1 - Double(k) * 0.15)), (x + 1, hy + 5 + jaw * (1 - Double(k) * 0.15))], C(0xF0E8D4))
        }
    }
    c.rect(Int(hx - 12), Int(hy - 6), 22, 3, dark)                                 // the brow ridge
    let glow = 0.75 + 0.25 * sin(t * 7)
    for ex in [hx - 4, hx + 6] {                                                   // burning eyes
        blob(c, ex, hy - 2, 3.2, 2.2, C(0xFF8A1E, 0.5 * glow))
        blob(c, ex, hy - 2, 2, 1.3, C(0xFFE08A, glow))
    }
    // the horns, sweeping up and back from the brow
    horn(c, from: (hx + 4, hy - 8), bend: (hx + 2, hy - 30), to: (hx + 26, hy - 34), r: 4.5)
    horn(c, from: (hx - 6, hy - 8), bend: (hx - 16, hy - 26), to: (hx - 4, hy - 38), r: 4)
}

/// Where the kaiju is (fx units, its feet), how big, and how far through a step, at shot-local time `l`.
func kaijuAt(_ l: Double) -> (x: Double, y: Double, k: Double, step: Double) {
    let f = clamp((l - 0.8) / 5.6), e = f * f * (3 - 2 * f)
    return (lerp(330, 210, e), lerp(150, 190, e), lerp(0.5, 1.45, e), (l - 0.8) / 0.9)
}

func kaijuRoar(_ l: Double) -> Double {
    func pulse(_ at: Double, _ len: Double) -> Double { let u = (l - at) / len; return u > 0 && u < 1 ? sin(u * .pi) : 0 }
    return max(pulse(2.8, 1.6), pulse(6.0, 1.8))
}

func detectiveShowcase(_ ctx: CGContext, local l: Double, t: Double) {
    // every footfall shakes the frame, harder as it gets closer
    let k = kaijuAt(l)
    let fall = frac(max(0, k.step)), shake = l > 0.8 && l < 6.6 ? max(0, 1 - fall * 4) * 10 * k.k : 0
    ctx.saveGState()
    ctx.translateBy(x: sin(t * 90) * shake, y: cos(t * 77) * shake * 0.6)
    blit(place(.metropolis, floorRows: 14, t: t), ctx)
    // the kaiju, its feet on the street, growing as it comes
    let kc = PixelCanvas(kaijuW, kaijuH)
    drawKaiju(kc, t: t, roar: kaijuRoar(l), step: k.step)
    kc.addOutline(C(AI.codex.hex, 0.92))
    if let img = kc.makeImage() {
        let s = 6 * k.k
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.draw(img, in: CGRect(x: k.x * 6 - Double(kaijuW) * s * 0.45, y: Double(H) - k.y * 6, width: Double(kaijuW) * s, height: Double(kaijuH) * s))
        ctx.restoreGState()
    }
    ctx.restoreGState()
    // Superman rockets up from the street and hits it with heat vision
    if l > 3.8 {
        let f = easeOut((l - 3.8) / 1.4)
        onStage(ctx, CGRect(x: 0, y: 0, width: W, height: H), scale: 6, ground: Double(fxH) + 10) {
            var sup = Actor(cast: .hero(DCHero.superman), x: lerp(-20, 70, f), facing: 1)
            sup.airborne = true
            sup.lift = lerp(10, 96, f)
            draw(sup, ctx, t: t)
            if l > 5.0 {
                let eyes = sup.fighter.point(sup.cast.muzzle.x, sup.cast.muzzle.y)
                let target = (k.x - 4 * k.k + sin(t * 9) * 2, k.y - 58 * k.k)       // its chest
                let beams = PixelCanvas(fxW, fxH + 10)
                beams.glowLine(eyes.x, eyes.y, target.0, target.1, core: C(0xFFF4D0), glow: C(0xFF3A1E), coreR: 0.8, glowR: 2.4)
                drawSparks(beams, x: target.0, y: target.1, t: t, size: 5)
                if let img = beams.makeImage() {
                    ctx.saveGState(); ctx.interpolationQuality = .none
                    ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(beams.h) * 6, width: Double(beams.w) * 6, height: Double(beams.h) * 6))
                    ctx.restoreGState()
                }
            }
        }
    }
}

// MARK: Pick your universe: one comic page

/// The page's three panels (screen rects): Star Clawds across the top, Marvelous Clawds and Detective Clawds below.
let pickPanels: [CGRect] = [CGRect(x: 40, y: 590, width: 1840, height: 330), CGRect(x: 40, y: 240, width: 905, height: 330),
                            CGRect(x: 975, y: 240, width: 905, height: 330)]
let pickWords = ["VWOOM!", "KAPOW!", "KRAK!"]

/// A brawl, framed into a comic panel: the part of the frame where the crew stands, filling the panel.
func panelImage(_ u: Universe, _ r: CGRect, local: Double, t: Double) -> CGImage? {
    guard let full = shotImage({ brawl($0, u, local: local, t: t, drop: false, chrome: false) }) else { return nil }
    let h = Double(W) * Double(r.height) / Double(r.width), centre = 300.0       // the crew's band, from the bottom
    let crop = CGRect(x: 0, y: Double(H) - centre - h / 2, width: Double(W), height: h)
    return full.cropping(to: crop)
}

/// The Settings choice under the page, `selected` 0…3 (Star Clawds, Marvelous Clawds, Detective Clawds, Random).
func universePicker(_ ctx: CGContext, selected: Int, alpha: Double) {
    let names = ["Star Clawds", "Marvelous Clawds", "Detective Clawds", "Random"]
    let r = CGRect(x: 360, y: 70, width: 1200, height: 120)
    ctx.saveGState(); ctx.setAlpha(CGFloat(alpha))
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: CGColor(gray: 0, alpha: 0.6))
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 22, cornerHeight: 22, transform: nil))
    ctx.setFillColor(CGColor(red: 0.13, green: 0.13, blue: 0.17, alpha: 0.97)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0)
    NSAttributedString(string: "Settings… → Universe", attributes: [.font: NSFont.systemFont(ofSize: 24, weight: .semibold),
                                                                    .foregroundColor: NSColor(white: 0.7, alpha: 1)])
        .draw(at: NSPoint(x: r.minX + 28, y: r.maxY - 42))
    let seg = CGRect(x: r.minX + 24, y: r.minY + 16, width: r.width - 48, height: 50)
    ctx.addPath(CGPath(roundedRect: seg, cornerWidth: 12, cornerHeight: 12, transform: nil))
    ctx.setFillColor(CGColor(gray: 0.24, alpha: 1)); ctx.fillPath()
    let w = seg.width / CGFloat(names.count)
    for (i, n) in names.enumerated() {
        let cell = CGRect(x: seg.minX + CGFloat(i) * w + 3, y: seg.minY + 3, width: w - 6, height: seg.height - 6)
        if i == selected {
            ctx.addPath(CGPath(roundedRect: cell, cornerWidth: 10, cornerHeight: 10, transform: nil))
            ctx.setFillColor(CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)); ctx.fillPath()
        }
        let a = NSAttributedString(string: n, attributes: [.font: NSFont.systemFont(ofSize: 24, weight: i == selected ? .bold : .medium),
                                                           .foregroundColor: NSColor.white])
        a.draw(at: NSPoint(x: cell.midX - a.size().width / 2, y: cell.midY - a.size().height / 2))
    }
    ctx.restoreGState()
}

func pickYourUniverse(_ ctx: CGContext, local l: Double, t: Double) {
    halftone(ctx, fullRect, base: CGColor(red: 0.1, green: 0.1, blue: 0.14, alpha: 1), dot: CGColor(red: 0.2, green: 0.2, blue: 0.28, alpha: 1), step: 22)
    let lands = [0.3, 1.2, 2.1]
    var selected = 0
    for (i, u) in Universe.allCases.enumerated() {
        let at = lands[i]
        guard l > at else { continue }
        selected = i
        let f = backOut((l - at) / 0.35), r = pickPanels[i]
        ctx.saveGState()
        ctx.translateBy(x: r.midX, y: r.midY)
        ctx.rotate(by: CGFloat((1 - f) * (i == 1 ? -0.12 : 0.12)))
        ctx.scaleBy(x: CGFloat(1.5 - 0.5 * f), y: CGFloat(1.5 - 0.5 * f))
        ctx.translateBy(x: -r.midX, y: -r.midY)
        ctx.setAlpha(CGFloat(clamp((l - at) / 0.12)))
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(r.offsetBy(dx: 12, dy: -12))
        if let img = panelImage(u, r, local: l + 3, t: t) { ctx.interpolationQuality = .high; ctx.draw(img, in: r) }
        ctx.setStrokeColor(inkColor); ctx.setLineWidth(12); ctx.stroke(r)
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 1)); ctx.setLineWidth(4); ctx.stroke(r.insetBy(dx: -8, dy: -8))
        captionBox(u.title.uppercased(), ctx, center: CGPoint(x: r.minX + 40 + Double(u.title.count) * 13, y: r.maxY - 36), size: 30)
        ctx.restoreGState()
        // the panel's sound word, popping and fading
        let w = l - at
        if w < 0.9 {
            let p = backOut(w / 0.2), fade = 1 - clamp((w - 0.6) / 0.3)
            let c = CGPoint(x: r.maxX - 160, y: r.maxY - 30)
            ctx.saveGState(); ctx.setAlpha(CGFloat(fade))
            starburst(ctx, center: c, inner: 70 * p, outer: 120 * p, spikes: 12, color: CGColor(red: 1, green: 0.88, blue: 0.29, alpha: 1), spin: Double(i))
            let tf = NSFont(name: "Futura-CondensedExtraBold", size: 52 * p) ?? .systemFont(ofSize: 50, weight: .black)
            let a = NSAttributedString(string: pickWords[i], attributes: [.font: tf, .foregroundColor: NSColor(srgbRed: 0.85, green: 0.12, blue: 0.12, alpha: 1)])
            a.draw(at: NSPoint(x: c.x - a.size().width / 2, y: c.y - a.size().height / 2))
            ctx.restoreGState()
        }
    }
    if l > 3.1 { selected = 3 }
    if l > 0.3 { universePicker(ctx, selected: selected, alpha: clamp((l - 0.3) / 0.3)) }
    caption("One app. Three universes. Pick yours.", ctx, local: l, start: 0.05, y: 960, size: 60)
}

/// A showcase's title card: the universe's name in a caption box and a line about it.
func showcaseTitle(_ ctx: CGContext, _ u: Universe, _ line: String, local l: Double) {
    let f = backOut((l - 0.4) / 0.35), fade = 1 - clamp((l - 4.2) / 0.5)
    guard l > 0.4, fade > 0 else { return }
    ctx.saveGState(); ctx.setAlpha(CGFloat(fade))
    ctx.translateBy(x: 960, y: 990); ctx.scaleBy(x: CGFloat(f), y: CGFloat(f)); ctx.translateBy(x: -960, y: -990)
    captionBox(u.title.uppercased(), ctx, center: CGPoint(x: 960, y: 990), size: 54)
    ctx.restoreGState()
    let sub = attributed(line, size: 40, weight: .bold, color: .white, alpha: fade * clamp((l - 0.7) / 0.3))
    sub.draw(at: NSPoint(x: (Double(W) - sub.size().width) / 2, y: 885))
}

let promoShots: [Shot] = [
    Shot(name: "meanwhile", start: 0, end: 3.5, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let line = "MEANWHILE, IN A TERMINAL NEAR YOU..."
        let n = Int(clamp((local - 0.3) / 1.6) * Double(line.count))
        let a = 1 - clamp((local - 3.0) / 0.4)
        if n > 0 { captionBox(String(line.prefix(n)), ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), size: 54, alpha: a) }
    },
    Shot(name: "worlds", start: 3.5, end: 9.5, into: .cut) { ctx, local, t in
        let slam = clamp((local - 1.6) / 0.3), shake = local > 1.9 && local < 2.2 ? (2.2 - local) * 60 : 0
        ctx.saveGState(); ctx.translateBy(x: sin(t * 80) * shake, y: cos(t * 70) * shake)
        coverPanels(ctx, t: t, dim: 0.15 * slam)
        if local > 1.6 {
            let s = CGFloat(1 + 1.6 * pow(1 - backOut(slam), 1))
            // high in the sky, clear of the fighters on the ground
            coverWord(ctx, "CLAWD", at: CGPoint(x: 960, y: 900), width: 1560, height: 270, angle: 0.05, depth: 14, scale: s)
            coverWord(ctx, "CLASH", at: CGPoint(x: 960, y: 640), width: 1680, height: 290, angle: 0.05, depth: 16, scale: s)
            coverGutters(ctx)
        }
        ctx.restoreGState()
    },
    Shot(name: "hook", start: 9.5, end: 13.5) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom)
        ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "pick", start: 13.5, end: 20.5) { ctx, local, t in pickYourUniverse(ctx, local: local, t: t) },
    // A showcase for each universe: its big moment, from the single-universe promos, shorter.
    Shot(name: "showStarClaws", start: 20.5, end: 27.5, into: .starWars(clock: false)) { ctx, local, t in
        starClawsShowcase(ctx, local: 1.4 + local, t: t)
        showcaseTitle(ctx, .starWars, "Laser swords, blasters and one very, very big ship.", local: local)
    },
    Shot(name: "showMarvelous Clawds", start: 27.5, end: 34.5, into: .marvel(ComicTrip(kind: .burst, sound: .kapow))) { ctx, local, t in
        clawvelShowcase(ctx, local: 2.2 + local, t: t)
        showcaseTitle(ctx, .marvel, "Shields, hammers, webs and a giant space whale.", local: local)
    },
    Shot(name: "showDetective", start: 34.5, end: 41.5, into: .dc(DCComicTrip(kind: .batSignal, caption: "MEANWHILE, IN MEGALOPOLIS…"))) { ctx, local, t in
        detectiveShowcase(ctx, local: 0.4 + local, t: t)
        showcaseTitle(ctx, .dc, "Capes, power rings and a horned kaiju to deal with.", local: local)
    },
    // The features, one universe each.
    Shot(name: "status", start: 41.5, end: 46.0, into: .marvel(ComicTrip(kind: .halftone))) { ctx, local, t in statusLineup(ctx, local: local, t: t) },
    Shot(name: "agents", start: 46.0, end: 50.5, into: .dc(DCComicTrip(kind: .grapple))) { ctx, local, t in agentsArrive(ctx, local: local, t: t) },
    Shot(name: "window", start: 50.5, end: 56.0, into: .starWars(clock: true)) { ctx, local, t in
        windowShot(ctx, .starWars, local: local, t: t, rise: true, needsAt: 2.6)
        badge(Universe.starWars.title.uppercased(), ctx, alpha: 1)
        caption("Prefer a window? Grab the popcorn.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890, size: 32, color: yellow, weight: .bold)
    },
    // Random: the whole window changes universe on its own, each time with that universe's transition.
    Shot(name: "random1", start: 56.0, end: 58.3) { ctx, local, t in windowShot(ctx, .marvel, local: local + 3, t: t, rise: false) },
    Shot(name: "random2", start: 58.3, end: 61.0, into: .dc(DCComicTrip(kind: .jokerCard)), inWindow: true) { ctx, local, t in
        windowShot(ctx, .dc, local: local + 3, t: t, rise: false)
    },
    Shot(name: "random3", start: 61.0, end: 63.1, into: .starWars(clock: false), inWindow: true) { ctx, local, t in
        windowShot(ctx, .starWars, local: local + 3, t: t, rise: false)
    },
    Shot(name: "random4", start: 63.1, end: 65.5, into: .marvel(ComicTrip(kind: .speedLines)), inWindow: true) { ctx, local, t in
        windowShot(ctx, .marvel, local: local + 3, t: t, rise: false)
    },
    Shot(name: "endcard", start: 65.5, end: 70.5) { ctx, local, t in
        coverPanels(ctx, t: t, fighters: false, dim: 0.45)
        let f = backOut((local - 0.2) / 0.5)
        if let icon = appIcon, local > 0.2 {
            let s = 500 * f
            ctx.saveGState(); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 960 - s / 2, y: 660 - s / 2, width: s, height: s))
            ctx.restoreGState()
        }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.8, y: 190, size: 64)
        caption("Free for macOS · github.com/rodclemen/clawd-clash", ctx, local: local, start: 1.1, y: 120, size: 36,
                color: NSColor(white: 0.88, alpha: 1), weight: .bold)
    },
]

let promoOverlays: [Overlay] = [
    Overlay(start: 56.0, end: 65.5) { ctx, l in
        badge("RANDOM · EVERY 5 MIN", ctx, alpha: 1)
        caption("Can't decide? Random switches the whole window", ctx, local: l, start: 0.2, y: 950, size: 50)
        caption("to a new universe every few minutes.", ctx, local: l, start: 0.4, y: 885, size: 40, color: yellow, weight: .bold)
    },
]

// MARK: The blooper reel

let groundRow = 150.0

/// A take's backdrop: a place at frame size, its floor where the cast stands.
func set(_ ctx: CGContext, _ l: Location, t: Double, frozen: Double? = nil) {
    blit(place(l, floorRows: Int(Double(fxH) - groundRow + 4), t: frozen ?? t), ctx)
}

/// Thorr's hammer, on its own, `k` sprite pixels a pixel: a stone head and a wrapped handle.
func hammer(_ ctx: CGContext, x: Double, y: Double, k: Double, tilt: Double) {
    let c = PixelCanvas(16, 18)
    c.rect(1, 1, 14, 7, C(0x8A8C92)); c.rect(1, 1, 14, 2, C(0xB8BAC0)); c.rect(1, 7, 14, 1, C(0x5A5C62))
    c.rect(7, 8, 3, 9, C(0x6A4428)); for y in stride(from: 9, to: 17, by: 2) { c.rect(7, y, 3, 1, C(0x8A6038)) }
    c.addOutline(C(0xFFFFFF, 0.92))
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.translateBy(x: x * 6, y: Double(H) - y * 6); ctx.rotate(by: CGFloat(tilt))
    ctx.draw(img, in: CGRect(x: -8 * k * 6, y: -9 * k * 6, width: 16 * k * 6, height: 18 * k * 6))
    ctx.restoreGState()
}

let blooperShots: [Shot] = [
    // The clapperboard slams in: BLOOPERS.
    Shot(name: "clapper", start: 0, end: 3.0, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(red: 0.08, green: 0.07, blue: 0.1, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        halftone(ctx, CGRect(x: 0, y: 0, width: W, height: H), base: CGColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1),
                 dot: CGColor(red: 1, green: 0.4, blue: 0.3, alpha: 1), step: 28)
        let drop = easeOut(local / 0.35)
        let open = local < 1.0 ? 1.0 : max(0, 1 - (local - 1.0) / 0.12)
        clapper(ctx, center: CGPoint(x: 960, y: 540 + 700 * (1 - drop)), width: 1100, open: open, take: "1", title: "BLOOPERS")
    },
    // Take 3: the Bulk wanders into the cantina; the band stops.
    Shot(name: "take3", start: 3.0, end: 8.2, into: .cut) { ctx, l, t in
        set(ctx, .cantina, t: t, frozen: l > 1.3 ? 1.3 + 3.0 : nil)
        let f = easeOut(l / 1.2)
        let bulk = Actor(cast: .hero(MarvelHero.hulk), x: lerp(-40, 130, f), mode: .idle, walking: f < 0.99)
        draw(bulk, ctx, t: t)
        if l > 1.6 { balloon("…wrong set?", ctx, center: CGPoint(x: 1000, y: 760), tail: headPoint(bulk), size: 48, alpha: clamp((l - 1.6) / 0.15)) }
        cutAndSlate(ctx, local: l, at: 3.9, take: "3")
    },
    // Take 7: Darth Vapor's big reveal, to the wrong kid.
    Shot(name: "take7", start: 8.2, end: 15.2, into: .cut) { ctx, l, t in
        set(ctx, .deathStar, t: t)
        let turn = l > 0.6
        let vapor = Actor(cast: .villain(SWVillain.vader), x: 90, facing: turn ? 1 : -1, mode: .idle)
        let spidey = Actor(cast: .hero(MarvelHero.spiderMan), x: 220, facing: -1, mode: .idle)
        draw(vapor, ctx, t: t); draw(spidey, ctx, t: t)
        if l > 0.9 && l < 4.1 { balloon("Spider-Clawd… I am your… landlord.", ctx, center: CGPoint(x: 820, y: 860), tail: headPoint(vapor), size: 44, width: 900) }
        if l > 3.6 { balloon("Pretty sure it's an aunt thing.", ctx, center: CGPoint(x: 1260, y: 640), tail: headPoint(spidey), size: 42, width: 700) }
        cutAndSlate(ctx, local: l, at: 5.8, take: "7")
    },
    // Take 12: the Night Beacon over the Doom Moon; the Stormtroupers open fire and miss every shot.
    Shot(name: "take12", start: 15.2, end: 20.4, into: .cut) { ctx, l, t in
        set(ctx, .deathStar, t: t)
        let on = clamp(l / 0.25)
        let sig = CGPoint(x: 1300, y: 860)
        ctx.setFillColor(CGColor(red: 1, green: 0.89, blue: 0.42, alpha: 0.2 * on)); ctx.fillEllipse(in: CGRect(x: sig.x - 260, y: sig.y - 170, width: 520, height: 340))
        ctx.setFillColor(CGColor(red: 1, green: 0.89, blue: 0.42, alpha: 0.9 * on)); ctx.fillEllipse(in: CGRect(x: sig.x - 200, y: sig.y - 130, width: 400, height: 260))
        ctx.addPath(cowlMaskPath(sig, width: 330))                 // the cowl mask in the beacon, as on the icon
        ctx.setFillColor(inkColor.copy(alpha: on) ?? inkColor); ctx.fillPath(using: .evenOdd)
        let bat = Actor(cast: .hero(DCHero.batman), x: 40, mode: .idle)
        draw(bat, ctx, t: t)
        let troopers = [Actor(cast: .villain(SWVillain.trooper), x: 150, mode: .idle, role: .none), Actor(cast: .villain(SWVillain.trooper), x: 200, mode: .idle, role: .none)]
        for tr in troopers { draw(tr, ctx, t: t) }
        let fx = PixelCanvas(fxW, fxH)
        for i in 0..<12 {                                           // wild shots, all wide of the mark
            let born = 0.5 + Double(i) * 0.22, age = l - born
            guard age > 0, age < 0.6 else { continue }
            let from = (troopers[i % 2].x + 18, groundRow - 22), miss = (noise(i * 5) > 0.5 ? 1.0 : -1.0) * (40 + noise(i * 5 + 1) * 40)
            let to = (Double(sig.x) / 6 + miss, -10.0)
            let g = age / 0.6, x = lerp(from.0, to.0, g), y = lerp(from.1, to.1, g)
            fx.glowLine(x - (to.0 - from.0) * 0.05, y - (to.1 - from.1) * 0.05, x, y, core: C(0xFFE0E0), glow: C(0xFF2A2A), coreR: 0.6, glowR: 1.8)
        }
        blit(fx, ctx)
        if l > 2.2 { balloon("You know it's a light, right?", ctx, center: CGPoint(x: 600, y: 640), tail: headPoint(bat), size: 40, width: 700) }
        cutAndSlate(ctx, local: l, at: 4.0, take: "12")
    },
    // Take 15: the Jester Card flips over and Thanoz is on the back.
    Shot(name: "take15", start: 20.4, end: 24.6, into: .cut) { ctx, l, t in
        let jester = Actor(cast: .villain(DCVillain.joker), x: 150, mode: .idle)
        func front() -> CGImage? { shotImage { c in set(c, .gotham, t: t); draw(jester, c, t: t) } }
        func back() -> CGImage? {
            shotImage { c in
                set(c, .titan, t: t)
                draw(Actor(cast: .villain(MarvelVillain.thanos), x: 160, facing: -1, mode: .idle), c, t: t)
                var j = Actor(cast: .villain(DCVillain.joker), x: 50, mode: .idle, bubble: .unknown); j.grow = 0.9
                if l > 2.6 { draw(j, c, t: t) }
            }
        }
        let k = clamp((l - 0.3) / (DCComicWipe.jokerCard.duration * 1.2))
        if let a = front(), let b = back() {
            if k <= 0 { ctx.draw(a, in: CGRect(x: 0, y: 0, width: W, height: H)) }
            else if k >= 1 { ctx.draw(b, in: CGRect(x: 0, y: 0, width: W, height: H)) }
            else { DCComicTrip(kind: .jokerCard).draw(ctx, old: a, new: b, k: k, in: CGRect(x: 0, y: 0, width: W, height: H)) }
        }
        cutAndSlate(ctx, local: l, at: 3.4, take: "15")
    },
    // Take 21: Yodle lifts Thorr's hammer. Thorr stares.
    Shot(name: "take21", start: 24.6, end: 30.8, into: .cut) { ctx, l, t in
        set(ctx, .asgard, t: t)
        let yodle = Actor(cast: .hero(SWHero.yoda), x: 90, mode: .idle)
        let thorr = Actor(cast: .hero(MarvelHero.thor), x: 220, facing: -1, mode: .idle)
        draw(yodle, ctx, t: t); draw(thorr, ctx, t: t)
        let rise = easeOut((l - 0.5) / 1.4)
        hammer(ctx, x: 128, y: groundRow - 4 - rise * 34 + sin(t * 4) * rise * 1.5, k: 1.6, tilt: sin(t * 2) * 0.1 * rise)
        if l > 0.5 {                                                // the Force, twinkling round it
            let sp = PixelCanvas(fxW, fxH), hy = groundRow - 4 - rise * 34
            for i in 0..<8 where sin(t * 5 + Double(i) * 1.7) > 0 {
                sp.px(128 + Int((noise(i * 3) - 0.5) * 30), Int(hy) + Int((noise(i * 3 + 1) - 0.5) * 24), C(0xBFF0FF))
            }
            blit(sp, ctx)
        }
        if l > 1.9 { balloon("…", ctx, center: CGPoint(x: 1500, y: 700), tail: headPoint(thorr), size: 60, width: 200) }
        if l > 3.0 { balloon("Worthy, hmm. Heavy, it is not.", ctx, center: CGPoint(x: 520, y: 760), tail: headPoint(yodle), size: 40, width: 700) }
        cutAndSlate(ctx, local: l, at: 5.4, take: "21")
    },
    // Take 22: Superb-Man tries to keep up with the jump to hyperspace.
    Shot(name: "take22", start: 30.8, end: 35.8, into: .cut) { ctx, l, t in
        ctx.setFillColor(CGColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let jump = clamp((l - 0.8) / 0.6), centre = CGPoint(x: 1300, y: 600)
        for i in 0..<160 {                                           // stars, stretching into streaks
            let a = noise(i * 3) * 2 * .pi, r0 = 40 + noise(i * 3 + 1) * 1100
            let r = r0 * (1 + jump * 0.25), len = 2 + jump * jump * (60 + r0 * 0.4)
            let p = CGPoint(x: centre.x + cos(a) * r, y: centre.y + sin(a) * r * 0.6)
            ctx.move(to: p); ctx.addLine(to: CGPoint(x: p.x + cos(a) * len, y: p.y + sin(a) * len * 0.6))
            ctx.setStrokeColor(CGColor(red: 0.85, green: 0.92, blue: 1, alpha: 0.4 + 0.6 * noise(i * 3 + 2))); ctx.setLineWidth(3); ctx.strokePath()
        }
        let go = clamp((l - 0.9) / 0.4)
        if go < 1 {                                                 // the Millennial Falcon, gone in a blink
            let fc = PixelCanvas(Ride.width, Ride.height)
            drawRide(fc, .falcon, ramp: 0, engines: true, gear: false); fc.addOutline(C(0xFFFFFF, 0.92))
            if let img = fc.makeImage() {
                let s = 7 * (1 - go * 0.95)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: lerp(900, centre.x, go) - Double(Ride.width) * s / 2, y: lerp(560, centre.y, go) - Double(Ride.height) * s / 2,
                                         width: Double(Ride.width) * s, height: Double(Ride.height) * s))
                ctx.restoreGState()
            }
        }
        var sup = Actor(cast: .hero(DCHero.superman), x: lerp(-20, 70, easeOut(l / 1.0)) - max(0, l - 1.6) * 6, mode: .idle)
        sup.airborne = true; sup.lift = 70
        draw(sup, ctx, t: t)
        if l > 1.8 { balloon("Hey! Wait up!", ctx, center: CGPoint(x: 700, y: 780), tail: headPoint(sup), size: 46, width: 600) }
        cutAndSlate(ctx, local: l, at: 4.0, take: "22")
    },
    // The final take: everyone in one frame, Deadpond in front, and a wrap.
    Shot(name: "wrap", start: 35.8, end: 43.5, into: .cut) { ctx, l, t in
        set(ctx, .avengersTower, t: t)
        let wave = l > 4.4
        let back: [(Cast, Double)] = [(.villain(SWVillain.vader), 22), (.hero(SWHero.luke), 58), (.villain(MarvelVillain.thanos), 100),
                                      (.hero(MarvelHero.thor), 146), (.hero(DCHero.superman), 190), (.villain(DCVillain.joker), 232),
                                      (.hero(SWHero.han), 270), (.hero(MarvelHero.hulk), 306)]
        for (i, (who, x)) in back.enumerated() {
            var a = Actor(cast: who, x: x, facing: i % 2 == 0 ? 1 : -1, mode: .idle, role: wave ? .cheer : .none)
            a.grow = 0.85; a.lift = 18
            draw(a, ctx, t: t + Double(i) * 0.3)
        }
        let front: [(Cast, Double)] = [(.hero(SWHero.yoda), 40), (.hero(MarvelHero.spiderMan), 92), (.hero(DCHero.batman), 236), (.villain(MarvelVillain.loki), 284)]
        for (i, (who, x)) in front.enumerated() {
            var a = Actor(cast: who, x: x, facing: x < 160 ? 1 : -1, mode: .idle, role: wave ? .cheer : .none)
            a.grow = 1.05
            draw(a, ctx, t: t + Double(i) * 0.5)
        }
        var dp = Actor(cast: .hero(MarvelHero.deadpool), x: 162, mode: .idle, role: wave ? .cheer : .none)
        dp.grow = 1.7; dp.lift = -18
        draw(dp, ctx, t: t)
        if l > 0.6 && l < 4.4 {
            balloon("Separate universes, they said. Totally under control.", ctx, center: CGPoint(x: 960, y: 880), tail: headPoint(dp), size: 44, width: 1100)
        }
        cutAndSlate(ctx, local: l, at: 4.4, take: "99", wrap: true)
        let fade = clamp((l - 6.9) / 0.6)
        if fade > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: fade)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
    },
]

/// Renders `draw` into its own full-frame image (for transitions played inside a shot).
func shotImage(_ draw: (CGContext) -> Void) -> CGImage? {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let saved = NSGraphicsContext.current
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    gc.cgContext.interpolationQuality = .none
    draw(gc.cgContext)
    NSGraphicsContext.current = saved
    return rep.cgImage
}

/// A comic-panel backdrop: flat colour under halftone dots.
func halftone(_ ctx: CGContext, _ r: CGRect, base: CGColor, dot: CGColor, step: Double = 18) {
    ctx.setFillColor(base); ctx.fill(r)
    ctx.setFillColor(dot)
    var y = r.minY, row = 0
    while y < r.maxY {
        var x = r.minX + (row % 2 == 0 ? 0 : step / 2)
        while x < r.maxX {
            let d = step * 0.42 * (0.4 + 0.6 * (y - r.minY) / r.height)
            ctx.fillEllipse(in: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d))
            x += step
        }
        y += step * 0.87; row += 1
    }
}


// MARK: The Star Clawds trailer (the old Clawd Wars trailer, rebuilt on Clawd Clash)

/// Every AI it supports in one line-up, Claude's character a head taller, duelling Codex's; the names above, Claude
/// Code biggest. `cast` is one character per AI, in `AI.allCases` order.
func everyAI(_ ctx: CGContext, local: Double, t: Double, cast: [Cast], line: String) {
    desktop(ctx, dim: 1)
    let xs: [Double] = [36, 104, 165, 216, 258, 298], facing: [Double] = [-1, 1, -1, -1, -1, -1]
    var actors: [Actor] = []
    let (ra, rb) = fightRoles(cast[0].weapon, cast[2].weapon)
    for (i, ai) in AI.allCases.enumerated() {
        let d = 0.15 + Double(i) * 0.1
        guard local > d else { continue }
        let f = backOut((local - d) / 0.3)
        let order = [1, 0, 2, 3, 4, 5][i]                               // Claude Desktop stands on the far left
        var a = Actor(cast: cast[i], x: xs[order], facing: facing[order], role: i == 0 ? ra : (i == 2 ? rb : .cheer), label: ai.tag, ai: ai)
        if ai == .claude { a.grow = 1.25; a.labelSize = 36 } else { a.labelSize = 22 }
        a.lift = (1 - f) * -10; a.alpha = clamp(f)
        actors.append(a)
        draw(a, ctx, t: t)
    }
    if let c = actors.first(where: { $0.ai == .claude }), let x = actors.first(where: { $0.ai == .codex }) { drawFX([(c, x)], ctx, t: t) }
    let fc = easeOut((local - 0.05) / 0.35)
    if fc > 0 {
        let tf = NSFont(name: "Futura-CondensedExtraBold", size: 140) ?? .systemFont(ofSize: 130, weight: .black)
        text("CLAUDE CODE", ctx, y: 790 - 30 * (1 - fc), size: 140, alpha: fc, font: tf, kern: 8)
    }
    let fr = easeOut((local - 0.35) / 0.35)
    if fr > 0 {
        let row = NSMutableAttributedString(attributedString: attributed("+  ", size: 40, weight: .heavy, color: dimText, alpha: fr))
        for (i, ai) in AI.allCases.dropFirst().enumerated() {
            if i > 0 { row.append(attributed("  ·  ", size: 40, weight: .heavy, color: dimText, alpha: fr)) }
            row.append(attributed(ai.name, size: 40, weight: .heavy, color: ai.ns, alpha: fr))
        }
        row.draw(at: NSPoint(x: (Double(W) - row.size().width) / 2, y: 720 - 20 * (1 - fr)))
    }
    caption(line, ctx, local: local, start: 0.7, y: 640, size: 40, color: yellow, weight: .bold)
}

/// A line-up of four sessions, one per state, with the state named under each.
func statusOf(_ ctx: CGContext, local: Double, t: Double, cast: [Cast], badgeText: String, aside: String) {
    desktop(ctx, dim: 1)
    let states: [(AI, VaderMode, BubbleKind?, String, NSColor, Bool)] = [
        (.claude, .working, nil, "WORKING", green, false), (.qwen, .thinking, .thinking, "THINKING…", NSColor(white: 0.9, alpha: 1), false),
        (.gemini, .waiting, .waiting, "NEEDS YOU!", red, false), (.copilot, .idle, .sleeping, "NAPPING", NSColor(srgbRed: 0.6, green: 0.55, blue: 1, alpha: 1), true),
    ]
    for (i, (ai, mode, bubble, word, col, sits)) in states.enumerated() {
        let d = 0.1 + Double(i) * 0.22
        guard local > d else { continue }
        let f = backOut((local - d) / 0.35)
        var a = Actor(cast: cast[i], x: 48 + Double(i) * 75, mode: mode, bubble: bubble, ai: ai)
        a.sitting = sits && cast[i].persona.canSit
        a.urgent = mode == .waiting
        if a.urgent { a.lift = abs(sin(t * 2 * .pi * 1.6)) * 6 }
        a.lift += (1 - f) * -8
        a.alpha = clamp(f)
        draw(a, ctx, t: t)
        let w = NSAttributedString(string: word, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .black), .kern: 2]).size().width
        text(word, ctx, x: a.x * S - w / 2, y: 70, size: 40, weight: .black, color: col, alpha: clamp(f), kern: 2)
    }
    badge(badgeText, ctx, alpha: 1)
    caption("All fun and games, and you still see everything.", ctx, local: local, start: 0.05, y: 900, size: 58)
    caption(aside, ctx, local: local, start: 0.9, y: 835, size: 36, color: yellow, weight: .bold)
}

/// Subagents walking in with their jobs on their labels, while their session stands guard.
func agentsOf(_ ctx: CGContext, local: Double, t: Double, guardCast: Cast, crew: [Cast], line: String, badgeText: String) {
    desktop(ctx, dim: 1)
    draw(Actor(cast: guardCast, x: 262, facing: -1, mode: .standGuard, label: "idle-claude"), ctx, t: t)
    let jobs = ["Find hook events", "Write changelog", "Check git history", "Plan the refactor"], stops: [Double] = [190, 140, 90, 40]
    for (i, who) in crew.enumerated() {
        let f = easeOut((local - Double(i) * 0.18) / 0.75)
        draw(Actor(cast: who, x: lerp(-30, stops[i], f), session: false, walking: f < 0.98, label: jobs[i]), ctx, t: t)
    }
    badge(badgeText, ctx, alpha: 1)
    caption(line, ctx, local: local, start: 0.1, y: 900)
    caption("Its job is right there on its label. No more guessing.", ctx, local: local, start: 0.45, y: 835, size: 40, color: yellow, weight: .bold)
}

// MARK: The boarding (Star Clawds): the door blows, Stormtroupers pour in, Darth Vapor steps through the smoke

let doorX = 268.0, doorW = 46.0, doorTop = 62.0       // the blast door at the end of the corridor (fx units)
let blowAt = 1.6

func boarding(_ ctx: CGContext, local l: Double, t: Double) {
    let since = l - blowAt
    if since > 0 && since < 0.5 { let sh = (0.5 - since) * 40; ctx.translateBy(x: sin(t * 90) * sh, y: cos(t * 80) * sh) }   // the blast shakes the frame
    set(ctx, .tantive, t: t)
    let fx = PixelCanvas(fxW, fxH)
    let floorRow = Int(groundRow) - 4
    // the door and its frame; before it blows, its seams glow hotter and hotter
    fx.rect(Int(doorX) - 4, Int(doorTop) - 4, Int(doorW) + 8, floorRow - Int(doorTop) + 4, C(0x7A808C))
    if l < blowAt {
        fx.rect(Int(doorX), Int(doorTop), Int(doorW), floorRow - Int(doorTop), C(0x9AA0AA))
        for y in stride(from: Int(doorTop) + 8, to: floorRow, by: 14) { fx.rect(Int(doorX) + 3, y, Int(doorW) - 6, 2, C(0x80868F)) }
        let heat = clamp((l - 0.5) / (blowAt - 0.5))
        if heat > 0 {
            let glow = C(0xFF8A2A, 0.35 + 0.6 * heat * (0.75 + 0.25 * sin(t * 30)))
            fx.rect(Int(doorX), Int(doorTop), Int(doorW), 2, glow); fx.rect(Int(doorX), floorRow - 2, Int(doorW), 2, glow)
            fx.rect(Int(doorX), Int(doorTop), 2, floorRow - Int(doorTop), glow); fx.rect(Int(doorX + doorW) - 2, Int(doorTop), 2, floorRow - Int(doorTop), glow)
            fx.rect(Int(doorX + doorW / 2) - 1, Int(doorTop), 2, floorRow - Int(doorTop), glow)
        }
    } else {
        fx.rect(Int(doorX), Int(doorTop), Int(doorW), floorRow - Int(doorTop), C(0x23262C))   // the hole, dark beyond
        for i in 0..<5 { fx.rect(Int(doorX) + 2 + i * 9, floorRow - 4 - Int(noise(i) * 6), 6, 4 + Int(noise(i) * 6), C(0x6A707A)) }   // wreckage
    }
    blit(fx, ctx)
    // the crew: the rebels hold the corridor, the droids and the princess behind them
    let fire = l > blowAt + 0.6, retreat = clamp((l - 4.6) / 1.4)
    var wedge = Actor(cast: .hero(SWHero.wedge), x: lerp(118, -40, retreat), mode: .idle, role: fire && retreat == 0 ? .shoot(offset: 0) : .none)
    var cassius = Actor(cast: .hero(SWHero.cassian), x: lerp(150, -20, retreat), mode: .idle, role: fire && retreat == 0 ? .shoot(offset: blasterPeriod / 2) : .none)
    wedge.walking = retreat > 0 && retreat < 1; cassius.walking = wedge.walking
    let away = clamp((l - 3.6) / 1.6)
    var laya = Actor(cast: .hero(SWHero.leia), x: lerp(70, -30, away), facing: away > 0 ? -1 : 1, mode: .idle); laya.walking = away > 0 && away < 1
    var r2 = Actor(cast: .hero(SWHero.r2d2), x: lerp(36, -50, away), facing: away > 0 ? -1 : 1, session: false, mode: .idle); r2.walking = laya.walking
    var c3 = Actor(cast: .hero(SWHero.c3po), x: lerp(16, -60, clamp((l - 6.6) / 0.9)), facing: l > 6.6 ? -1 : 1, mode: .idle); c3.walking = l > 6.6 && l < 7.5
    // the Stormtroupers, through the smoke one after another, firing as they come
    var troopers: [Actor] = []
    for i in 0..<5 {
        let at = blowAt + 0.35 + Double(i) * 0.32
        guard l > at else { continue }
        let f = easeOut((l - at) / 0.8), stop = [250.0, 218, 282, 190, 236][i]
        var tr = Actor(cast: .villain(SWVillain.trooper), x: lerp(doorX + 22, stop, f), facing: -1, mode: .idle,
                       role: f > 0.95 && retreat < 1 ? .shoot(offset: Double(i) * 0.17) : .none)
        tr.walking = f < 0.95
        troopers.append(tr)
    }
    // Darth Vapor, last through, slow
    let vf = clamp((l - 4.2) / 1.8)
    var vapor = Actor(cast: .villain(SWVillain.vader), x: lerp(doorX + 22, 148, easeOut(vf)), facing: -1, mode: .idle)
    vapor.walking = vf > 0 && vf < 1
    for a in [c3, r2, laya] { draw(a, ctx, t: t) }
    for a in troopers.reversed() { draw(a, ctx, t: t) }
    if l > 4.2 { draw(vapor, ctx, t: t) }
    for a in [cassius, wedge] { draw(a, ctx, t: t) }
    // the firefight: each rebel against a trouper
    var pairs: [(Actor, Actor)] = []
    if troopers.count > 1 && retreat == 0 { pairs = [(wedge, troopers[0]), (cassius, troopers[1])] }
    if troopers.count > 3 && retreat == 0 { pairs += [(wedge, troopers[3])] }
    drawFX(pairs, ctx, t: t)
    // the blast: a white flash, flying debris, then smoke rolling out of the doorway and thinning
    if since > 0 {
        let smoke = PixelCanvas(fxW, fxH)
        for i in 0..<18 {
            let a = noise(i * 3) * .pi - .pi / 2, sp = 16 + noise(i * 3 + 1) * 40
            let r = 6 + since * (6 + noise(i) * 8), fade = max(0, 0.75 - since * 0.18)
            let x = doorX + doorW / 2 - cos(a) * since * sp * 0.6, y = (doorTop + Double(floorRow)) / 2 + sin(a) * since * sp * 0.3
            smoke.circle(Int(x), Int(y), Int(r), C(noise(i + 7) > 0.5 ? 0xC8CCD2 : 0x9AA0AA, fade))
        }
        if since < 0.7 {
            for i in 0..<30 {
                let a = noise(i * 5) * 2 * .pi, d = since * (60 + noise(i * 5 + 1) * 90)
                smoke.rect(Int(doorX + doorW / 2 - abs(cos(a)) * d), Int(doorTop + 40 + sin(a) * d * 0.6 + since * since * 40), 2, 2, C(0x5A606A))
            }
        }
        blit(smoke, ctx)
        if since < 0.3 { ctx.setFillColor(CGColor(gray: 1, alpha: 0.8 * (1 - since / 0.3))); ctx.fill(fullRect) }
    }
    if l > 5.0 && l < 6.9 { balloon("I'd like to formally object to all of this.", ctx, center: CGPoint(x: 520, y: 760), tail: headPoint(c3), size: 38, width: 640) }
}

let starClawdsShots: [Shot] = [
    // The film's opening line, reworded for terminals, in that blue, on black.
    Shot(name: "longago", start: 0, end: 3.5, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let a = clamp(local / 0.6) * (1 - clamp((local - 2.7) / 0.6))
        let blue = NSColor(srgbRed: 0.29, green: 0.84, blue: 0.93, alpha: a)
        for (i, line) in ["A long time ago, in a terminal", "far, far away...."].enumerated() {
            NSAttributedString(string: line, attributes: [.font: NSFont.systemFont(ofSize: 60, weight: .regular), .foregroundColor: blue])
                .draw(at: NSPoint(x: 520, y: 580 - Double(i) * 84))
        }
    },
    // STAR CLAWDS, outlined in yellow, falling away into the stars.
    Shot(name: "logo", start: 3.5, end: 7.0, into: .cut) { ctx, local, t in
        let sky = PixelCanvas(fxW, fxH)
        sky.rect(0, 0, fxW, fxH, C(0x000000)); starfield(sky, t: t); blit(sky, ctx)
        let p = clamp(local / 3.5), s = 2.4 * exp(-3.4 * p), a = 1 - clamp((p - 0.8) / 0.2)
        let tf = NSFont(name: "Futura-CondensedExtraBold", size: 260) ?? .systemFont(ofSize: 240, weight: .black)
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: s, y: s)
        for (i, word) in ["STAR", "CLAWDS"].enumerated() {
            let w = NSAttributedString(string: word, attributes: [.font: tf, .kern: 20, .strokeWidth: 3, .strokeColor: yellow.withAlphaComponent(a)])
            let sz = w.size()
            w.draw(at: NSPoint(x: -sz.width / 2, y: i == 0 ? 0 : -sz.height * 0.82))
        }
        ctx.restoreGState()
    },
    // Tilt down to the desert planet: the blockade runner flees, the giant ship slides in overhead.
    Shot(name: "destroyer", start: 7.0, end: 15.5, into: .cut) { ctx, local, t in starClawsShowcase(ctx, local: local, t: t) },
    // Aboard the blockade runner: the door blows, the Stormtroupers pour in, Darth Vapor steps through.
    Shot(name: "boarding", start: 15.5, end: 23.0, into: .starWars(clock: false)) { ctx, local, t in boarding(ctx, local: local, t: t) },
    Shot(name: "hook", start: 23.0, end: 27.0) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "desktop", start: 27.0, end: 31.6) { ctx, local, t in
        brawl(ctx, .starWars, local: local, t: t, drop: true, chrome: false)
        badge("DESKTOP MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Now they're a pixel-art Star Clawds brawl", ctx, local: local, start: 0.35, y: 900)
        caption("along the bottom of your screen. They fight while they work.", ctx, local: local, start: 0.6, y: 830, size: 40, color: yellow, weight: .bold)
    },
    Shot(name: "status", start: 31.6, end: 35.8) { ctx, local, t in
        let cast: [Cast] = [.villain(SWVillain.vader), .villain(SWVillain.emperor), .villain(SWVillain.boba), .villain(SWVillain.jabba)]
        statusOf(ctx, local: local, t: t, cast: cast, badgeText: "STAR CLAWDS", aside: "(Leave \(cast[2].name) waiting and he starts jumping.)")
    },
    Shot(name: "agents", start: 35.8, end: 39.8) { ctx, local, t in
        agentsOf(ctx, local: local, t: t, guardCast: .villain(SWVillain.vader),
                 crew: [.hero(SWHero.luke), .hero(SWHero.leia), .hero(SWHero.chewie), .hero(SWHero.r2d2)],
                 line: "Every subagent reports for duty.", badgeText: "STAR CLAWDS")
    },
    Shot(name: "window", start: 39.8, end: 44.6) { ctx, local, t in
        windowShot(ctx, .starWars, local: local, t: t, rise: true, needsAt: 2.5)
        badge("WINDOW MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Prefer a window? Grab the popcorn.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890, size: 32, color: yellow, weight: .bold)
    },
    Shot(name: "ais", start: 44.6, end: 49.0) { ctx, local, t in
        everyAI(ctx, local: local, t: t, cast: [.villain(SWVillain.vader), .villain(SWVillain.kylo), .hero(SWHero.luke), .hero(SWHero.yoda),
                                                .hero(SWHero.leia), .hero(SWHero.r2d2)],
                line: "Everyone picks a side. Nobody plays nice.")
    },
    // The end card: the Millennial Falcon flies through, the crew on the horizon, the title lands.
    Shot(name: "endcard", start: 49.0, end: 53.2) { ctx, local, t in
        space(ctx, t: local)
        let fp = local / 1.1
        if fp > 0 && fp < 1 {
            let fc = PixelCanvas(Ride.width, Ride.height)
            drawRide(fc, .falcon, ramp: 0, engines: true, gear: false); fc.addOutline(C(0xFFFFFF, 0.92))
            if let img = fc.makeImage() {
                let x = lerp(-500, Double(W) + 100, easeIn(fp) * 0.6 + fp * 0.4)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: x, y: 560 + 200 * fp, width: Double(Ride.width) * 6, height: Double(Ride.height) * 6))
                ctx.restoreGState()
            }
        }
        let crew: [(Cast, FightRole, AI)] = [(.villain(SWVillain.kylo), .cheer, .desktop), (.villain(SWVillain.vader), .duel, .claude),
                                             (.hero(SWHero.luke), .duel, .codex), (.hero(SWHero.r2d2), .none, .copilot),
                                             (.hero(SWHero.yoda), .cheer, .qwen), (.hero(SWHero.leia), .none, .gemini)]
        var placed: [Actor] = []
        for (i, (who, role, ai)) in crew.enumerated() {
            var a = Actor(cast: who, x: [28.0, 80, 137, 190, 240, 290][i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
            a.lift = groundY - (Double(H) - 242) / S
            a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
            draw(a, ctx, t: t)
            placed.append(a)
        }
        if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
        if local > 0.35 {
            let f = backOut((local - 0.35) / 0.4)
            let tf = NSFont(name: "Futura-CondensedExtraBold", size: 190) ?? .systemFont(ofSize: 170, weight: .black)
            ctx.saveGState()
            ctx.translateBy(x: Double(W) / 2, y: 700); ctx.scaleBy(x: f, y: f); ctx.translateBy(x: -Double(W) / 2, y: -700)
            text("STAR CLAWDS", ctx, y: 620, size: 190, color: yellow, font: tf, kern: 14)
            ctx.restoreGState()
        }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 540, size: 56)
        caption("One of three universes in Clawd Clash · free for macOS", ctx, local: local, start: 0.8, y: 480, size: 34,
                color: NSColor(white: 0.8, alpha: 1), weight: .bold)
        let ff = easeOut((local - 0.9) / 0.3)
        if ff > 0, let icon = appIcon {
            ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 600, y: 50, width: 140, height: 140))
            ctx.restoreGState()
            text("github.com/rodclemen/clawd-clash", ctx, x: 770, y: 92, size: 44, weight: .bold, alpha: ff)
        }
    },
]

let starClawdsBeats: [(key: Double, beat: Beat)] = [
    (1.8, ("A LONG TIME AGO", "Black screen. The film's blue opening line, reworded for terminals, fades in and out.", "“A long time ago, in a terminal far, far away....”", "silence")),
    (4.4, ("THE LOGO", "Hard cut to stars. STAR CLAWDS, outlined in yellow, starts bigger than the screen and falls away into the starfield.", "STAR CLAWDS", "big hit, then an original fanfare")),
    (11.2, ("THE BIG SHIP", "The camera tilts down to the desert planet; a blockade runner flees under laser fire; the giant wedge ship slides in overhead until its engines fill the top of the frame.", "no text", "a dark pulse, a turbolaser per bolt, the rumble")),
    (19.8, ("THE BOARDING", "An edge wipe into the blockade runner's white corridor. Wedge Antlers and Cassius Andoor hold it, Princess Laya, Ahh2-De2 and C-3P-Uh-Oh behind them. The blast door's seams glow, it blows in a white flash and a cloud of smoke, Stormtroupers pour through firing, the rebels fall back, and Darth Vapor steps slowly through the smoke.", "C-3P-Uh-Oh: “I'd like to formally object to all of this.”", "sizzling seams, the blast, a firefight, heavy breathing and footsteps")),
    (25.0, ("THE HOOK", "Three busy terminals, slow push-in.", "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "keyboard clicks")),
    (29.5, ("DESKTOP MODE", "Darth Vapor and Luke Skyclawder drop onto the bottom edge and duel; Han Yolo and a Stormtrouper trade shots.", "DESKTOP MODE  ·  “Now they're a pixel-art Star Clawds brawl along the bottom of your screen. They fight while they work.”", "laser swords, blasters")),
    (33.9, ("AT A GLANCE", "Four sessions pop in, each in its AI's outline: Darth Vapor working, the Emperor thinking, Boba Feta's jumping NEEDS YOU, Jabbo the Glutt napping.", "“All fun and games, and you still see everything.”  ·  “(Leave Boba Feta waiting and he starts jumping.)”", "blips, alert beeps")),
    (38.0, ("SUBAGENTS", "Darth Vapor stands guard; Luke, Princess Laya, Chewbarka and Ahh2-De2 march in with their jobs on their labels.", "“Every subagent reports for duty.”", "footsteps, a droid chirp")),
    (42.6, ("WINDOW MODE", "The window in the Mos Easy Cantina; live cards tick, then Luke's Codex card flips to NEEDS YOU.", "WINDOW MODE  ·  “Prefer a window? Grab the popcorn.”", "a ping")),
    (47.0, ("EVERY AI", "Six sessions, one per AI outline; Claude's Darth Vapor a head taller, duelling Codex's Luke.", "CLAUDE CODE  ·  + the other five  ·  “Everyone picks a side. Nobody plays nice.”", "laser-sword clashes")),
    (52.0, ("END CARD", "Space: the Millennial Falcon flies through, the crew lines up on the horizon, STAR CLAWDS lands.", "STAR CLAWDS  ·  “Have fun. Keep track.”  ·  “One of three universes in Clawd Clash · free for macOS”  ·  github.com/rodclemen/clawd-clash", "a flyby, the final sting")),
]

/// The Star Clawds trailer's score and effects.
func starClawdsSound(_ m: Mix) {
    // the logo: a big hit and a fanfare
    let lg = start("logo")
    m.boom(lg, vol: 0.55); m.noise(lg, 1.6, vol: 0.12, cutoff: 0.9, decay: 0.5, highpass: true, seed: 3)
    for n in [48, 55, 60, 64, 67] { m.tone(lg, 1.1, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.7) }
    for (s, d, n) in [(0.3, 0.28, 64), (0.6, 0.28, 67), (0.9, 0.85, 72), (1.8, 0.28, 71), (2.1, 0.28, 69), (2.4, 1.05, 74)] as [(Double, Double, Int)] {
        m.tone(lg + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(lg + s, d, midi(n), wave: .saw, vol: 0.05, release: 0.08)
    }
    // the big ship: a dark pulse, turbolasers, the rumble
    let sd = start("destroyer"), sde = end("destroyer") + 1.3
    for i in 0..<Int((sde - sd) / 0.25) { m.tone(sd + Double(i) * 0.25, 0.22, midi(i % 8 == 7 ? 37 : 36), wave: .square(0.25), vol: 0.05 + 0.06 * min(1, Double(i) / 30), release: 0.04) }
    for (s, chord) in [(0.0, [48, 51, 55]), (2.0, [44, 48, 51]), (4.0, [46, 50, 53]), (6.0, [48, 51, 55]), (7.0, [43, 47, 50])] {
        for n in chord { m.tone(sd + s, 1.8, midi(n), wave: .saw, vol: 0.04, attack: 0.05, release: 0.6) }
    }
    m.boom(sd + 3.0, vol: 0.4)
    m.noise(sd + 2.6, 6.5, vol: 0.32, cutoff: 0.004, cutoffTo: 0.03, attack: 3.0, release: 2.0, seed: 5)
    m.tone(sd + 2.6, 6.5, 41, wave: .sine, vol: 0.18, attack: 3.0, release: 2.0)
    for i in 0..<40 { let b = sd + 1.3 + Double(i) * 0.17; if b < sde { m.turbolaser(b, pitch: noise(i * 7) > 0.5 ? 1 : 0.8, vol: 0.07) } }
    // the boarding: the seams sizzle, the door blows, a firefight, then the breathing and the footsteps
    let bd = start("boarding")
    m.noise(bd + 0.5, blowAt - 0.5, vol: 0.06, cutoff: 0.7, attack: 0.8, release: 0.05, highpass: true, seed: 61)
    m.tone(bd + 0.5, blowAt - 0.5, 180, to: 420, wave: .saw, vol: 0.03, attack: 0.8, release: 0.05)
    m.boom(bd + blowAt, vol: 0.6); m.noise(bd + blowAt, 1.2, vol: 0.2, cutoff: 0.5, cutoffTo: 0.05, decay: 0.4, seed: 62)
    for t in shotTimes(bd + blowAt + 0.6, bd + 4.6, offset: 0) { m.pew(t, vol: 0.09) }
    for t in shotTimes(bd + blowAt + 0.6, bd + 4.6, offset: blasterPeriod / 2) { m.pew(t, vol: 0.08) }
    for i in 0..<5 { for t in shotTimes(bd + blowAt + 1.2 + Double(i) * 0.32, bd + 6.0, offset: Double(i) * 0.17) { m.pew(t, vol: 0.05) } }
    for (s, chord) in [(blowAt, [43, 46, 50]), (4.2, [41, 44, 48]), (6.0, [43, 46, 50])] {
        for n in chord { m.tone(bd + s, 1.4, midi(n), wave: .saw, vol: 0.05, attack: 0.02, release: 0.6) }
    }
    var b = 4.4
    while b < 7.6 {                                            // in and out, in and out, under a mask
        m.noise(bd + b, 0.9, vol: 0.07, cutoff: 0.08, attack: 0.3, release: 0.4, seed: Int(b * 10))
        m.noise(bd + b + 1.0, 0.9, vol: 0.05, cutoff: 0.04, attack: 0.3, release: 0.4, seed: Int(b * 10) + 1)
        b += 2.0
    }
    for k in 0..<4 { m.step(bd + 4.4 + Double(k) * 0.45, vol: 0.16) }
    for k in 0..<4 { m.step(bd + 6.6 + Double(k) * 0.12, vol: 0.05) }
    // the groove, from the hook to the end card, faded in under the wipe from the big ship
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }
    let desk = start("desktop"), deskEnd = end("desktop") + 1.3
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    m.ignite(desk + 0.45); m.hum(desk + 0.45, deskEnd - desk - 0.45)
    for t in clashTimes(desk + 0.45, deskEnd) { m.clash(t) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: 0) { m.pew(t) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: blasterPeriod / 2) { m.pew(t, vol: 0.12) }
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    m.r2(ag + 1.4)
    let wi = start("window")
    m.hum(wi, 2.5, vol: 0.02)
    for t in clashTimes(wi, wi + 2.5) { m.clash(t, vol: 0.09) }
    for k in [0.9, 1.8] { m.click(wi + k, vol: 0.06) }
    m.ping(wi + 2.5)
    let ais = start("ais")
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    m.ignite(ais + 0.3, vol: 0.12); m.hum(ais + 0.35, end("ais") - ais)
    for t in clashTimes(ais + 0.35, end("ais") + 1.3) { m.clash(t) }
    for s in shots { transitionSound(m, s) }
    let ec = start("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 2.8, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(ec + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.6 : 0.1) }
        m.tone(ec + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.6 : 0.1, vibrato: 0.006)
        m.tone(ec + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.6 : 0.1)
    }
    m.boom(ec + 0.35, vol: 0.45)
    m.whoosh(ec + 0.55, 1.1, vol: 0.22); m.tone(ec, 1.1, 300, to: 900, wave: .saw, vol: 0.025, attack: 0.4, release: 0.5)
    for t in clashTimes(ec + 0.5, duration) { m.clash(t, vol: 0.12) }
}

/// The chiptune groove (Am F C G), on its own track and faded in from `from` over `fadeIn` seconds.
func groove(_ m: Mix, from g0: Double, to g1: Double, fadeIn: Double) {
    let gm = Mix(seconds: duration), beat = 0.5, bar = 2.0
    let roots = [45, 41, 48, 43], triads = [[69, 72, 76], [65, 69, 72], [67, 72, 76], [67, 71, 74]]
    let melodyA: [[(Int, Double)]] = [[(76, 1), (81, 1), (84, 0.5), (83, 0.5), (81, 1)], [(84, 1), (81, 1), (77, 0.5), (79, 0.5), (81, 1)],
                                      [(79, 1), (76, 0.5), (79, 0.5), (84, 1), (83, 1)], [(86, 1), (83, 1), (79, 2)]]
    let melodyB: [[(Int, Double)]] = [[(81, 0.5), (84, 0.5), (88, 1), (86, 0.5), (84, 0.5), (83, 1)], [(81, 1.5), (84, 0.5), (81, 1), (77, 1)],
                                      [(79, 0.5), (81, 0.5), (79, 0.5), (76, 0.5), (79, 1), (84, 1)], [(83, 1), (86, 1), (91, 2)]]
    let bars = Int(((g1 - g0) / bar).rounded())
    for b in 0..<bars {
        let t0 = g0 + Double(b) * bar, c = b % 4, full = b >= 2
        for e in 0..<8 {
            gm.tone(t0 + Double(e) * beat / 2, beat / 2 * 0.9, midi(roots[c] - 12 + (e % 2) * 12), wave: .square(0.25), vol: full ? 0.075 : 0.05, release: 0.02)
            gm.hat(t0 + Double(e) * beat / 2, vol: e % 2 == 1 ? 0.04 : 0.025)
        }
        gm.kick(t0)
        if full {
            gm.kick(t0 + 2 * beat); gm.kick(t0 + 2.5 * beat, vol: 0.18); gm.snare(t0 + beat); gm.snare(t0 + 3 * beat)
            for s in 0..<16 { gm.tone(t0 + Double(s) * beat / 4, beat / 4 * 0.8, midi(triads[c][s % 3] - 12 + (s / 3 % 2) * 12), wave: .triangle, vol: 0.03, release: 0.02) }
            var tt = t0
            for (n, d) in ((b - 2) / 4 % 2 == 0 ? melodyA : melodyB)[c] { gm.tone(tt, d * beat * 0.92, midi(n), wave: .square(0.5), vol: 0.055, release: 0.04, vibrato: 0.004); tt += d * beat }
        }
        if b == bars - 1 { for k in 0..<8 { gm.snare(t0 + 2 * beat + Double(k) * beat / 4, vol: 0.06 + Double(k) * 0.01) } }
    }
    for i in gm.buf.indices where gm.buf[i] != 0 {
        let t = Double(i) / sampleRate
        m.buf[i] += gm.buf[i] * Float(clamp((t - g0 + fadeIn * 0.5) / fadeIn))
    }
}

// MARK: The Marvelous Clawds trailer (the old Avengers trailer, rebuilt on Clawd Clash)

/// MARVELOUS over CLAWDS: comic lettering with a heavy round black outline.
func marvelousTitle(_ ctx: CGContext, center: CGPoint, scale s: Double, alpha: Double = 1) {
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: 200) ?? .systemFont(ofSize: 190, weight: .black)
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y); ctx.scaleBy(x: s, y: s)
    for (i, (word, col, size)) in [("MARVELOUS", NSColor(srgbRed: 0.93, green: 0.16, blue: 0.16, alpha: alpha), 0.62),
                                   ("CLAWDS", yellow.withAlphaComponent(alpha), 1.0)].enumerated() {
        let f = NSFont(descriptor: tf.fontDescriptor, size: 200 * size) ?? tf
        let base: [NSAttributedString.Key: Any] = [.font: f, .kern: 10 * size]
        var outlined = base; outlined[.foregroundColor] = NSColor.black.withAlphaComponent(alpha)
        var filled = base; filled[.foregroundColor] = col
        let sz = NSAttributedString(string: word, attributes: base).size()
        let p = NSPoint(x: -sz.width / 2, y: i == 0 ? 40 : -sz.height + 40)
        let ink = NSAttributedString(string: word, attributes: outlined), r = 12 * size
        for k in 0..<16 { let a = Double(k) / 16 * 2 * .pi; ink.draw(at: NSPoint(x: p.x + cos(a) * r, y: p.y + sin(a) * r)) }
        NSAttributedString(string: word, attributes: filled).draw(at: p)
    }
    ctx.restoreGState()
}

/// The heroes' ring: six of them back to back on the street of the Battle of New York, the camera circling round them.
func heroesRing(_ ctx: CGContext, local l: Double, t: Double) {
    blit(newYork(t, floorRows: 26), ctx)
    let heroes: [MarvelHero] = [.captainAmerica, .ironMan, .thor, .hulk, .blackWidow, .hawkeye]
    let spin = -l * 0.55
    var ring: [(Actor, Double)] = []
    for (i, h) in heroes.enumerated() {
        let a = spin + Double(i) / Double(heroes.count) * 2 * .pi
        let depth = sin(a)                                   // +1 nearest us, -1 furthest
        var who = Actor(cast: .hero(h), x: 160 + cos(a) * 92, facing: cos(a) >= 0 ? 1 : -1, mode: .idle)
        who.grow = 1.05 + 0.3 * depth
        who.lift = -12 * depth - 14                          // nearer is lower on screen
        ring.append((who, depth))
    }
    for (a, _) in ring.sorted(by: { $0.1 < $1.1 }) { draw(a, ctx, t: t) }
}

let marvelousShots: [Shot] = [
    Shot(name: "meanwhile", start: 0, end: 3.5, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let line = "MEANWHILE, IN A TERMINAL NEAR YOU..."
        let n = Int(clamp((local - 0.3) / 1.6) * Double(line.count))
        let a = 1 - clamp((local - 3.0) / 0.4)
        if n > 0 { captionBox(String(line.prefix(n)), ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), size: 54, alpha: a) }
    },
    // Comic panels of the cast flip past, then MARVELOUS CLAWDS slams in on a burst.
    Shot(name: "panels", start: 3.5, end: 7.0, into: .cut) { ctx, local, t in
        let cast: [Cast] = [.hero(MarvelHero.ironMan), .villain(MarvelVillain.thanos), .hero(MarvelHero.captainAmerica), .villain(MarvelVillain.loki),
                            .hero(MarvelHero.thor), .villain(MarvelVillain.ultron), .hero(MarvelHero.hulk), .villain(MarvelVillain.redSkull),
                            .hero(MarvelHero.spiderMan), .villain(MarvelVillain.greenGoblin), .hero(MarvelHero.blackPanther),
                            .villain(MarvelVillain.doctorDoom), .hero(MarvelHero.doctorStrange), .villain(MarvelVillain.venom), .hero(MarvelHero.groot)]
        let colours: [(CGColor, CGColor)] = [(CGColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1), CGColor(red: 1, green: 0.4, blue: 0.3, alpha: 1)),
                                             (CGColor(red: 0.15, green: 0.35, blue: 0.85, alpha: 1), CGColor(red: 0.4, green: 0.6, blue: 1, alpha: 1)),
                                             (CGColor(red: 1, green: 0.8, blue: 0.1, alpha: 1), CGColor(red: 1, green: 0.95, blue: 0.5, alpha: 1)),
                                             (CGColor(red: 0.45, green: 0.2, blue: 0.7, alpha: 1), CGColor(red: 0.7, green: 0.45, blue: 0.95, alpha: 1))]
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let flip = Int(local / 0.11), settle = clamp((local - 1.7) / 0.4)
        for i in 0..<6 {
            let r = CGRect(x: 40 + Double(i % 3) * 620, y: 40 + Double(i / 3) * 510, width: 600, height: 490)
            let pick = (flip * 6 + i) % cast.count, tone = colours[(flip + i) % colours.count]
            ctx.saveGState(); ctx.setAlpha(CGFloat(1 - settle * 0.7))
            halftone(ctx, r, base: tone.0, dot: tone.1)
            if let img = portrait(cast[pick], ai: .claude, t: local) {
                let k = (min(r.width * 0.7 / Double(img.width), r.height * 0.75 / Double(img.height))).rounded(.down)
                ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: r.midX - Double(img.width) * k / 2, y: r.minY + 30, width: Double(img.width) * k, height: Double(img.height) * k))
            }
            ctx.setStrokeColor(CGColor(gray: 0, alpha: 1)); ctx.setLineWidth(10); ctx.stroke(r)
            ctx.restoreGState()
        }
        if local > 1.7 {
            let f = backOut((local - 1.7) / 0.35)
            starburst(ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), inner: 330 * f, outer: 560 * f, spikes: 16,
                      color: CGColor(red: 1, green: 0.88, blue: 0.29, alpha: 1), spin: local * 0.15)
            starburst(ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), inner: 250 * f, outer: 420 * f, spikes: 12,
                      color: CGColor(red: 0.93, green: 0.2, blue: 0.16, alpha: 1), spin: -local * 0.2)
            marvelousTitle(ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2 - 20), scale: f * 0.95)
        }
    },
    // The Battle of New York: the portal, the space whale diving at us, Iron Clawd rocketing up to meet it.
    Shot(name: "invasion", start: 7.0, end: 15.5, into: .cut) { ctx, local, t in clawvelShowcase(ctx, local: local, t: t) },
    Shot(name: "ring", start: 15.5, end: 20.0, into: .cut) { ctx, local, t in heroesRing(ctx, local: local, t: t) },
    Shot(name: "hook", start: 20.0, end: 24.0) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "desktop", start: 24.0, end: 28.6) { ctx, local, t in
        brawl(ctx, .marvel, local: local, t: t, drop: true, chrome: false)
        badge("DESKTOP MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Now they're a pixel-art Marvelous Clawds brawl", ctx, local: local, start: 0.35, y: 900)
        caption("along the bottom of your screen. They fight while they work.", ctx, local: local, start: 0.6, y: 830, size: 40, color: yellow, weight: .bold)
    },
    Shot(name: "status", start: 28.6, end: 32.8) { ctx, local, t in
        let cast: [Cast] = [.hero(MarvelHero.thor), .villain(MarvelVillain.loki), .villain(MarvelVillain.ultron), .villain(MarvelVillain.thanos)]
        statusOf(ctx, local: local, t: t, cast: cast, badgeText: "MARVELOUS CLAWDS", aside: "(\(cast[3].name) sits down when the job's done. Relatable.)")
    },
    Shot(name: "agents", start: 32.8, end: 36.8) { ctx, local, t in
        agentsOf(ctx, local: local, t: t, guardCast: .hero(MarvelHero.ironMan),
                 crew: [.hero(MarvelHero.spiderMan), .hero(MarvelHero.blackWidow), .hero(MarvelHero.groot), .hero(MarvelHero.rocket)],
                 line: "Every subagent suits up.", badgeText: "MARVELOUS CLAWDS")
    },
    Shot(name: "window", start: 36.8, end: 41.6) { ctx, local, t in
        windowShot(ctx, .marvel, local: local, t: t, rise: true, needsAt: 2.5)
        badge("WINDOW MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Prefer a window? Grab some shawarma.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890, size: 32, color: yellow, weight: .bold)
    },
    Shot(name: "ais", start: 41.6, end: 46.0) { ctx, local, t in
        everyAI(ctx, local: local, t: t, cast: [.hero(MarvelHero.captainAmerica), .hero(MarvelHero.ironMan), .villain(MarvelVillain.thanos),
                                                .villain(MarvelVillain.loki), .villain(MarvelVillain.ultron), .villain(MarvelVillain.greenGoblin)],
                line: "Claude plays the heroes. Everyone else gets to be the villain.")
    },
    // The end card: Clawdvengers Tower at night, the Clawdjet flies through, the title lands.
    Shot(name: "endcard", start: 46.0, end: 50.2) { ctx, local, t in
        blit(place(.avengersTower, floorRows: 34, t: t), ctx)
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.35)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let fp = local / 1.2
        if fp > 0 && fp < 1 {
            let qc = PixelCanvas(Ride.width, Ride.height)
            drawRide(qc, .quinjet, ramp: 0, engines: true, gear: false); qc.addOutline(C(0xFFFFFF, 0.92))
            if let img = qc.makeImage() {
                let x = lerp(-600, Double(W) + 100, easeIn(fp) * 0.6 + fp * 0.4)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: x, y: 600 + 200 * fp, width: Double(Ride.width) * 6, height: Double(Ride.height) * 6))
                ctx.restoreGState()
            }
        }
        let crew: [(Cast, FightRole, AI)] = [(.hero(MarvelHero.ironMan), .cheer, .desktop), (.hero(MarvelHero.captainAmerica), .block, .claude),
                                             (.villain(MarvelVillain.thanos), .zap, .codex), (.villain(MarvelVillain.greenGoblin), .none, .copilot),
                                             (.villain(MarvelVillain.loki), .cheer, .qwen), (.villain(MarvelVillain.ultron), .none, .gemini)]
        var placed: [Actor] = []
        for (i, (who, role, ai)) in crew.enumerated() {
            var a = Actor(cast: who, x: [28.0, 84, 156, 206, 252, 296][i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
            a.lift = 8
            a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
            draw(a, ctx, t: t)
            placed.append(a)
        }
        if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
        if local > 0.35 { marvelousTitle(ctx, center: CGPoint(x: Double(W) / 2, y: 760), scale: backOut((local - 0.35) / 0.4) * 0.8) }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 520, size: 56)
        caption("One of three universes in Clawd Clash · free for macOS", ctx, local: local, start: 0.8, y: 462, size: 34,
                color: NSColor(white: 0.85, alpha: 1), weight: .bold)
        let ff = easeOut((local - 0.9) / 0.3)
        if ff > 0, let icon = appIcon {
            ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 0.8 * ff)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 170))
            ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 580, y: 20, width: 130, height: 130))
            ctx.restoreGState()
            text("github.com/rodclemen/clawd-clash", ctx, x: 740, y: 60, size: 44, weight: .bold, alpha: ff)
        }
    },
]

let marvelousBeats: [(key: Double, beat: Beat)] = [
    (2.4, ("MEANWHILE...", "Black screen. A yellow comic caption types itself out.", "“MEANWHILE, IN A TERMINAL NEAR YOU...”", "typewriter keys, a bell")),
    (5.6, ("THE PANELS", "Six comic panels flip through the cast every beat (Iron Clawd, Thanoz, Captain Americlawd, Lokee, Thorr, Ultraton...), then fade back as MARVELOUS CLAWDS slams in on a yellow and red burst.", "MARVELOUS / CLAWDS", "page flips, then a big hit and a fanfare")),
    (13.0, ("THE INVASION", "The Battle of New York: the portal over the tower, a space whale noses out and dives at us until it fills the frame, Iron Clawd rockets up from the street firing repulsors.", "no text", "the portal hum, roars, repulsors, the rumble")),
    (18.0, ("THE RING", "On the street below, Captain Americlawd, Iron Clawd, Thorr, the Bulk, Black Window and Hawk-I stand back to back while the camera circles them.", "no text", "a heroic swell")),
    (21.4, ("THE HOOK", "Three busy terminals, slow push-in.", "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "keyboard clicks")),
    (26.3, ("DESKTOP MODE", "Captain Americlawd and Red Skulk drop onto the bottom edge: Red Skulk fires, the shield knocks every shot aside. Spider-Clawd's webs against the Green Gobbler's bombs.", "DESKTOP MODE  ·  “Now they're a pixel-art Marvelous Clawds brawl along the bottom of your screen. They fight while they work.”", "shield clangs, web thwips, bombs")),
    (30.9, ("AT A GLANCE", "Thorr working, Lokee thinking, Ultraton's jumping NEEDS YOU, Thanoz sat down napping.", "“All fun and games, and you still see everything.”  ·  “(Thanoz sits down when the job's done. Relatable.)”", "blips, alert beeps")),
    (35.0, ("SUBAGENTS", "Iron Clawd stands guard; Spider-Clawd, Black Window, Grout and Racket march in with their jobs on their labels.", "“Every subagent suits up.”", "footsteps, a Grout rumble")),
    (39.6, ("WINDOW MODE", "The window at Clawdvengers Tower: the shield blocks Red Skulk, live cards tick, then his Codex card flips to NEEDS YOU.", "WINDOW MODE  ·  “Prefer a window? Grab some shawarma.”", "a ping")),
    (44.0, ("EVERY AI", "Six sessions, one per AI outline; Claude's Captain Americlawd a head taller, holding his shield into Thanoz' gauntlet.", "CLAUDE CODE  ·  + the other five  ·  “Claude plays the heroes. Everyone else gets to be the villain.”", "the beam on the shield")),
    (49.0, ("END CARD", "Clawdvengers Tower at night: the Clawdjet streaks across, the crew lines up, MARVELOUS CLAWDS lands.", "MARVELOUS CLAWDS  ·  “Have fun. Keep track.”  ·  “One of three universes in Clawd Clash · free for macOS”  ·  github.com/rodclemen/clawd-clash", "a flyby, the final sting")),
]

/// The Marvelous Clawds trailer's score and effects.
func marvelousSound(_ m: Mix) {
    let mw = start("meanwhile")
    for i in 0..<35 { m.type(mw + 0.3 + Double(i) / 35 * 1.6 + noise(i) * 0.02, vol: 0.18 + noise(i + 50) * 0.08) }
    m.ding(mw + 2.0)
    m.tone(mw + 0.2, 3.0, midi(33), wave: .sine, vol: 0.05, attack: 1.0, release: 0.8)
    let pn = start("panels")
    for i in 0..<16 { m.flip(pn + Double(i) * 0.11, vol: 0.04 + Double(i) * 0.003) }
    let hit = pn + 1.7
    m.boom(hit, vol: 0.55); m.noise(hit, 1.6, vol: 0.12, cutoff: 0.9, decay: 0.5, highpass: true, seed: 3)
    for n in [48, 55, 60, 64, 67] { m.tone(hit, 1.0, midi(n), wave: .saw, vol: 0.05, release: 0.5, decay: 0.6) }
    for (s, d, n) in [(0.25, 0.22, 67), (0.5, 0.22, 72), (0.75, 0.5, 76), (1.3, 0.5, 74)] as [(Double, Double, Int)] {
        m.tone(hit + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(hit + s, d, midi(n), wave: .saw, vol: 0.045, release: 0.08)
    }
    let inv = start("invasion")
    m.tone(inv, 8.5 + 1.0, 110, wave: .sine, vol: 0.05, attack: 1, release: 1.5, vibrato: 0.03)
    for i in 0..<Int(9.5 / 0.25) { m.tone(inv + Double(i) * 0.25, 0.22, midi(i % 8 == 7 ? 37 : 36), wave: .square(0.25), vol: 0.04 + 0.06 * min(1, Double(i) / 30), release: 0.04) }
    for (s, chord) in [(0.0, [48, 51, 55]), (2.0, [44, 48, 51]), (4.0, [46, 50, 53]), (6.0, [48, 51, 55]), (7.0, [43, 47, 50])] {
        for n in chord { m.tone(inv + s, 1.8, midi(n), wave: .saw, vol: 0.035, attack: 0.05, release: 0.6) }
    }
    m.roar(inv + 2.6, 1.6, vol: 0.22); m.roar(inv + 5.6, 2.2, vol: 0.3)
    m.noise(inv + 3.0, 6.5, vol: 0.3, cutoff: 0.004, cutoffTo: 0.03, attack: 3.0, release: 1.5, seed: 5)
    m.tone(inv + 3.0, 6.5, 41, wave: .sine, vol: 0.16, attack: 3.0, release: 1.5)
    m.noise(inv + 4.2, 4.0, vol: 0.1, cutoff: 0.05, cutoffTo: 0.2, attack: 0.6, release: 1.2, seed: 12)
    for i in 0..<10 { m.repulsor(inv + 4.9 + Double(i) * 0.3, vol: 0.08) }
    let ring = start("ring")
    for k in 0..<10 { m.tone(ring - 0.5 + Double(k) * 0.05, 0.08, 70, to: 55, wave: .sine, vol: 0.05 + Double(k) * 0.012, decay: 0.05) }
    for (s, d, chord) in [(0.0, 1.1, [48, 52, 55, 60]), (1.1, 1.1, [41, 45, 48, 53]), (2.2, 1.1, [43, 47, 50, 55]), (3.3, 1.6, [48, 52, 55, 60])] {
        for n in chord { m.tone(ring + s, d, midi(n), wave: .saw, vol: 0.035, attack: 0.15, release: 0.4) }
        m.tone(ring + s, d, midi(chord[0] - 12), wave: .sine, vol: 0.16, attack: 0.05, release: 0.4)
    }
    for (s, d, n) in [(0.2, 0.4, 67), (0.6, 0.5, 72), (1.1, 0.9, 74), (2.2, 0.4, 71), (2.6, 0.5, 74), (3.3, 1.4, 79)] as [(Double, Double, Int)] {
        m.tone(ring + s, d, midi(n), wave: .square(0.5), vol: 0.06, attack: 0.02, release: 0.12, vibrato: 0.006)
    }
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }
    let desk = start("desktop"), deskEnd = end("desktop") + 1.3
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: 0) { m.pew(t, vol: 0.1); m.clang(t + boltArrival * blasterPeriod); m.thwip(t + 0.02, vol: 0.07) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: blasterPeriod / 2) { m.bomb(t, vol: 0.08) }
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    m.groot(ag + 1.4)
    let wi = start("window")
    for t in shotTimes(wi, wi + 2.5, offset: 0) { m.pew(t, vol: 0.05); m.clang(t + boltArrival * blasterPeriod, vol: 0.05) }
    for k in [0.9, 1.8] { m.click(wi + k, vol: 0.06) }
    m.ping(wi + 2.5)
    let ais = start("ais")
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    m.crackle(ais + 0.4, end("ais") + 1.3 - ais - 0.4, vol: 0.045)
    for s in shots { transitionSound(m, s) }
    let ec = start("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 2.8, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(ec + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.6 : 0.1) }
        m.tone(ec + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.6 : 0.1, vibrato: 0.006)
        m.tone(ec + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.6 : 0.1)
    }
    m.boom(ec + 0.35, vol: 0.45)
    m.noise(ec + 1.4, 2.5, vol: 0.08, cutoff: 0.9, decay: 0.8, highpass: true, seed: 8)
    m.jet(ec, 1.2, vol: 0.08)
    m.crackle(ec + 0.5, duration - ec - 0.5, vol: 0.025)
}

// MARK: The Detective Clawds openers (from the old Justice League trailer)

/// The title: DETECTIVE over CLAWDS, the D and the C at full strength and the rest faded, so it reads DC. `ink` draws it
/// as a plain silhouette (as the Night Beacon shows it).
func detectiveTitle(_ ctx: CGContext, center: CGPoint, scale s: Double, alpha: Double = 1, ink: NSColor? = nil) {
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: 200) ?? .systemFont(ofSize: 190, weight: .black)
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y); ctx.scaleBy(x: s, y: s)
    for (i, (word, col, size)) in [("DETECTIVE", NSColor(srgbRed: 0.22, green: 0.48, blue: 0.95, alpha: alpha), 0.7),
                                   ("CLAWDS", yellow.withAlphaComponent(alpha), 1.0)].enumerated() {
        let f = NSFont(descriptor: tf.fontDescriptor, size: 200 * size) ?? tf
        let base: [NSAttributedString.Key: Any] = [.font: f, .kern: 10 * size]
        let sz = NSAttributedString(string: word, attributes: base).size()
        let p = NSPoint(x: -sz.width / 2, y: i == 0 ? 40 : -sz.height + 40)
        // the word, its first letter full strength and the rest faded
        func lettered(_ col: NSColor, faded: Double) -> NSAttributedString {
            var a = base; a[.foregroundColor] = col.withAlphaComponent(alpha * faded)
            let w = NSMutableAttributedString(string: word, attributes: a)
            w.addAttribute(.foregroundColor, value: col.withAlphaComponent(alpha), range: NSRange(location: 0, length: 1))
            return w
        }
        if let ink { lettered(ink, faded: 0.45).draw(at: p); continue }
        var outlined = base; outlined[.foregroundColor] = NSColor.black.withAlphaComponent(alpha)
        var filled = base; filled[.foregroundColor] = col
        let stamp = NSAttributedString(string: word, attributes: outlined), r = 12 * size
        for k in 0..<16 {                                   // a thick, round outline
            let a = Double(k) / 16 * 2 * .pi
            stamp.draw(at: NSPoint(x: p.x + cos(a) * r, y: p.y + sin(a) * r))
        }
        _ = filled
        lettered(col, faded: 0.45).draw(at: p)
    }
    ctx.restoreGState()
}

/// Gothamburg at night, two screens tall: the camera tilts up the searchlight's beam to the Night Beacon on the clouds,
/// pushes in, and the beacon switches from the cowl mask to the title.
func detectiveSignal(_ ctx: CGContext, local l: Double, t: Double) {
    let tallH = 300
    let city = place(.gotham, floorRows: 22, t: t, h: tallH)
    let sig = Scenes.gothamSignal(city, tallH - 22)               // the signal's centre, canvas pixels
    let tilt = clamp(l / 2.2), te = tilt * tilt * (3 - 2 * tilt)
    let off = Double(tallH - fxH) * (1 - te)                     // canvas rows above the top of the frame
    let push = clamp((l - 2.0) / 1.2), pe = push * push * (3 - 2 * push)
    let z = 1 + 2.2 * pe
    // where the signal sits on screen, and the push that brings it to the centre (y up, as CG has it)
    let sx = Double(sig.x) * 6 + 18, sy = Double(H) + off * 6 - Double(sig.y) * 6
    let cx = Double(W) / 2, cy = Double(H) / 2 + 60
    let s = 1 - pe + pe * z
    ctx.saveGState()
    ctx.translateBy(x: pe * (cx - sx * z), y: pe * (cy - sy * z))
    ctx.scaleBy(x: s, y: s)
    blit(city, ctx, dy: -off * 6)
    ctx.restoreGState()
    // the signal clicks over from the bat to the title
    if l > 3.0 {
        let on = clamp((l - 3.0) / 0.25) * (sin(l * 60) > -0.6 || l > 3.5 ? 1 : 0.4)
        ctx.saveGState()
        for (rx, ry, a) in [(760.0, 430.0, 0.10), (640.0, 360.0, 0.16), (560.0, 315.0, 0.95)] {
            ctx.setFillColor(CGColor(red: 0.96, green: 0.93, blue: 0.72, alpha: a * on))
            ctx.fillEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        }
        ctx.restoreGState()
        detectiveTitle(ctx, center: CGPoint(x: cx, y: cy - 20), scale: 0.66, alpha: on, ink: NSColor(srgbRed: 0.08, green: 0.08, blue: 0.11, alpha: 1))
    }
}

/// The Lookout: the Justice Clawds arrive one by one and line up in front of the Earth.
func detectiveLineup(_ ctx: CGContext, local l: Double, t: Double) {
    blit(place(.watchtower, floorRows: 30, t: t), ctx)
    let league: [(DCHero, Double, String)] = [(.aquaman, 32, "walk"), (.greenLantern, 74, "fly"), (.wonderWoman, 116, "fly"),
                                                 (.superman, 160, "fly"), (.batman, 204, "rope"), (.flash, 246, "zip"),
                                                 (.cyborg, 288, "walk")]
    onStage(ctx, CGRect(x: 0, y: 0, width: W, height: H), scale: 6, ground: 158) {
        for (i, (who, x, how)) in league.enumerated() {
            let order = [3, 4, 2, 0, 1, 5, 6][i]                       // Superman first, then Batman, Wonder Woman…
            let d = 0.2 + Double(order) * 0.38, f = clamp((l - d) / 0.55)
            guard l > d else { continue }
            var a = Actor(cast: .hero(who), x: x, facing: x < 160 ? 1 : -1, mode: .idle)
            a.grow = 1.15
            switch how {
            case "fly": a.lift = 140 * (1 - easeOut(f)); a.airborne = f < 1
            case "rope": a.lift = 150 * (1 - easeOut(f))
            case "zip": a.x = lerp(-60, x, easeOut(f * 1.6))
            default: a.x = lerp(x < 160 ? -30 : 350, x, easeOut(f)); a.walking = f < 1
            }
            if how == "rope" && f < 1 {                                   // Batman's grapnel line
                let c = PixelCanvas(fxW, fxH + 20)
                c.rect(Int(a.x) + 4, 0, 1, Int(a.top) + 22, C(0x9AA0AE))
                if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6)) }
            }
            if how == "zip" && f < 0.62 {                                  // the Flash's streak
                let c = PixelCanvas(fxW, fxH + 20)
                c.glowLine(0, a.top + 30, a.x - 8, a.top + 30, core: C(0xFFF0A0), glow: C(0xE02A1E), coreR: 1, glowR: 3)
                if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6)) }
            }
            draw(a, ctx, t: t)
        }
    }
}

// MARK: The Detective Clawds trailer (the old Justice League trailer, rebuilt on Clawd Clash)

let detectiveShots: [Shot] = [
    Shot(name: "meanwhile", start: 0, end: 3.5, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let line = "MEANWHILE, AT THE \(Location("hallOfJustice").name.uppercased())..."
        let n = Int(clamp((local - 0.3) / 1.6) * Double(line.count))
        let a = 1 - clamp((local - 3.0) / 0.4)
        if n > 0 { captionBox(String(line.prefix(n)), ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), size: 54, alpha: a) }
    },
    // Up the searchlight's beam to the Night Beacon, which clicks over to the title.
    Shot(name: "signal", start: 3.5, end: 8.0, into: .cut) { ctx, local, t in detectiveSignal(ctx, local: local, t: t) },
    // Megalopolis: the horned kaiju stomps in and roars; Superb-Man meets it with heat vision.
    Shot(name: "invasion", start: 8.0, end: 16.5, into: .cut) { ctx, local, t in detectiveShowcase(ctx, local: local, t: t) },
    // The Lookout: the Justice Clawds arrive and line up.
    Shot(name: "league", start: 16.5, end: 21.0, into: .cut) { ctx, local, t in detectiveLineup(ctx, local: local, t: t) },
    Shot(name: "hook", start: 21.0, end: 25.0) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "desktop", start: 25.0, end: 29.6) { ctx, local, t in
        brawl(ctx, .dc, local: local, t: t, drop: true, chrome: false)
        badge("DESKTOP MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Now they're a pixel-art Detective Clawds brawl", ctx, local: local, start: 0.35, y: 900)
        caption("along the bottom of your screen. They fight while they work.", ctx, local: local, start: 0.6, y: 830, size: 40, color: yellow, weight: .bold)
    },
    Shot(name: "status", start: 29.6, end: 33.8) { ctx, local, t in
        let cast: [Cast] = [.hero(DCHero.superman), .villain(DCVillain.riddler), .villain(DCVillain.harleyQuinn), .villain(DCVillain.solomonGrundy)]
        statusOf(ctx, local: local, t: t, cast: cast, badgeText: "DETECTIVE CLAWDS", aside: "(\(cast[3].name): born on a Monday, napping by Thursday.)")
    },
    Shot(name: "agents", start: 33.8, end: 37.8) { ctx, local, t in
        agentsOf(ctx, local: local, t: t, guardCast: .hero(DCHero.wonderWoman),
                 crew: [.hero(DCHero.robin), .hero(DCHero.nightwing), .hero(DCHero.cyborg), .hero(DCHero.krypto)],
                 line: "Every subagent answers the beacon.", badgeText: "DETECTIVE CLAWDS")
    },
    Shot(name: "window", start: 37.8, end: 42.6) { ctx, local, t in
        windowShot(ctx, .dc, local: local, t: t, rise: true, needsAt: 2.5, at: .batcave)
        badge("WINDOW MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Prefer a window? Step into \(Location.batcave.name).", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890, size: 32, color: yellow, weight: .bold)
    },
    Shot(name: "ais", start: 42.6, end: 47.0) { ctx, local, t in
        everyAI(ctx, local: local, t: t, cast: [.hero(DCHero.superman), .hero(DCHero.wonderWoman), .villain(DCVillain.lexLuthor),
                                                .villain(DCVillain.sinestro), .villain(DCVillain.cheetah), .villain(DCVillain.blackManta)],
                line: "Claude plays the heroes. Everyone else gets to be the villain.")
    },
    // The end card: Gothamburg's rooftop under the beacon, the Clawdwing flies through, the title lands.
    Shot(name: "endcard", start: 47.0, end: 51.2) { ctx, local, t in
        blit(place(.gotham, floorRows: 34, t: t), ctx)
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.3)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let fp = local / 1.2
        if fp > 0 && fp < 1 {
            let bc = PixelCanvas(Ride.width, Ride.height)
            drawRide(bc, .batwing, ramp: 0, engines: true, gear: false); bc.addOutline(C(0xFFFFFF, 0.92))
            if let img = bc.makeImage() {
                let x = lerp(-600, Double(W) + 100, easeIn(fp) * 0.6 + fp * 0.4)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: x, y: 600 + 200 * fp, width: Double(Ride.width) * 6, height: Double(Ride.height) * 6))
                ctx.restoreGState()
            }
        }
        let crew: [(Cast, FightRole, AI)] = [(.hero(DCHero.wonderWoman), .cheer, .desktop), (.hero(DCHero.superman), .shoot(offset: 0), .claude),
                                             (.villain(DCVillain.lexLuthor), .shoot(offset: blasterPeriod / 2), .codex), (.villain(DCVillain.blackManta), .none, .copilot),
                                             (.villain(DCVillain.sinestro), .cheer, .qwen), (.villain(DCVillain.cheetah), .none, .gemini)]
        var placed: [Actor] = []
        for (i, (who, role, ai)) in crew.enumerated() {
            var a = Actor(cast: who, x: [28.0, 84, 156, 206, 252, 296][i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
            a.lift = 8
            a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
            draw(a, ctx, t: t)
            placed.append(a)
        }
        if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
        if local > 0.35 { detectiveTitle(ctx, center: CGPoint(x: Double(W) / 2, y: 760), scale: backOut((local - 0.35) / 0.4) * 0.8) }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 520, size: 56)
        caption("One of three universes in Clawd Clash · free for macOS", ctx, local: local, start: 0.8, y: 462, size: 34,
                color: NSColor(white: 0.85, alpha: 1), weight: .bold)
        let ff = easeOut((local - 0.9) / 0.3)
        if ff > 0, let icon = appIcon {
            ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 0.8 * ff)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 170))
            ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 580, y: 20, width: 130, height: 130))
            ctx.restoreGState()
            text("github.com/rodclemen/clawd-clash", ctx, x: 740, y: 60, size: 44, weight: .bold, alpha: ff)
        }
    },
]

let detectiveBeats: [(key: Double, beat: Beat)] = [
    (2.4, ("MEANWHILE...", "Black screen. A yellow comic caption types itself out, in the spirit of the old cartoons' narrator.", "“MEANWHILE, AT THE HALL OF CLAWDS...”", "typewriter keys, a bell")),
    (7.0, ("THE BEACON", "Gothamburg at night, rain falling. The camera climbs the searchlight's beam to the Night Beacon and pushes in; with a clunk the cowl mask switches to the title, its D and C at full strength.", "DETECTIVE / CLAWDS, as the beacon", "rain, far thunder, a rising line, the clunk and the big hit")),
    (14.5, ("THE KAIJU", "Megalopolis by day: a colossal horned kaiju stomps in, every step shaking the frame, and roars; Superb-Man rockets up and hits it with heat vision.", "no text", "stomps, two roars, heat vision")),
    (19.0, ("THE LINE-UP", "The Lookout over the Earth: Superb-Man flies down, Batclawd drops on his grapnel line, Wondrous Woman and the Green Lamplighter land, the Flare zips in, Aquamarine and Cyb-Org walk up.", "no text", "a heroic swell, whooshes, a zip")),
    (22.4, ("THE HOOK", "Three busy terminals, slow push-in.", "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "keyboard clicks")),
    (27.3, ("DESKTOP MODE", "Batclawd knocks away the Jester's shots; the Emerald Archer trades arrows for Captain Chill's ice.", "DESKTOP MODE  ·  “Now they're a pixel-art Detective Clawds brawl along the bottom of your screen. They fight while they work.”", "shots, whacks, arrows, ice")),
    (31.9, ("AT A GLANCE", "Superb-Man working, the Puzzler thinking, Harlee Quinn's jumping NEEDS YOU, Solomon Grundy sat down napping.", "“All fun and games, and you still see everything.”  ·  “(Solomon Grundy: born on a Monday, napping by Thursday.)”", "blips, alert beeps")),
    (36.0, ("SUBAGENTS", "Wondrous Woman stands guard; Wren, Nightglider, Cyb-Org and Kryptro arrive with their jobs on their labels.", "“Every subagent answers the beacon.”", "footsteps, a bark")),
    (40.6, ("WINDOW MODE", "The window in the Night Grotto: Batclawd against the Jester, live cards tick, then the Jester's Codex card flips to NEEDS YOU.", "WINDOW MODE  ·  “Prefer a window? Step into The Night Grotto.”", "a ping")),
    (45.0, ("EVERY AI", "Six sessions, one per AI outline; Claude's Superb-Man a head taller, trading heat vision with Codex's Lex Lugar.", "CLAUDE CODE  ·  + the other five  ·  “Claude plays the heroes. Everyone else gets to be the villain.”", "heat vision crackle")),
    (50.0, ("END CARD", "Gothamburg's rooftop under the beacon: the Clawdwing streaks across, the crew lines up, DETECTIVE CLAWDS lands.", "DETECTIVE CLAWDS  ·  “Have fun. Keep track.”  ·  “One of three universes in Clawd Clash · free for macOS”  ·  github.com/rodclemen/clawd-clash", "a flyby, the final sting")),
]

/// The Detective Clawds trailer's score and effects.
func detectiveSound(_ m: Mix) {
    let mw = start("meanwhile")
    for i in 0..<38 { m.type(mw + 0.3 + Double(i) / 38 * 1.6 + noise(i) * 0.02, vol: 0.18 + noise(i + 50) * 0.08) }
    m.ding(mw + 2.0)
    m.tone(mw + 0.2, 3.0, midi(33), wave: .sine, vol: 0.05, attack: 1.0, release: 0.8)
    let sg = start("signal")
    m.rain(sg, 4.5 + 1.0); m.boom(sg + 0.4, vol: 0.12)
    for (k, n) in [45, 48, 52, 55, 57].enumerated() { m.tone(sg + 0.3 + Double(k) * 0.5, 0.9, midi(n), wave: .triangle, vol: 0.05, attack: 0.1, release: 0.4) }
    let hit = sg + 3.0
    m.clunk(hit - 0.12); m.boom(hit, vol: 0.55); m.noise(hit, 1.6, vol: 0.12, cutoff: 0.9, decay: 0.5, highpass: true, seed: 3)
    for n in [45, 52, 57, 60, 64] { m.tone(hit, 1.2, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.7) }
    for (s, d, n) in [(0.25, 0.22, 64), (0.5, 0.22, 69), (0.75, 0.5, 72), (1.3, 0.6, 71)] as [(Double, Double, Int)] {
        m.tone(hit + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(hit + s, d, midi(n), wave: .saw, vol: 0.045, release: 0.08)
    }
    let inv = start("invasion")
    for i in 0..<Int(9.5 / 0.25) { m.tone(inv + Double(i) * 0.25, 0.22, midi(i % 8 == 7 ? 37 : 36), wave: .square(0.25), vol: 0.04 + 0.06 * min(1, Double(i) / 30), release: 0.04) }
    for (s, chord) in [(0.0, [48, 51, 55]), (2.0, [44, 48, 51]), (4.0, [46, 50, 53]), (6.0, [48, 51, 55]), (7.0, [43, 47, 50])] {
        for n in chord { m.tone(inv + s, 1.8, midi(n), wave: .saw, vol: 0.035, attack: 0.05, release: 0.6) }
    }
    var step = 0.8
    while step < 6.6 { m.boom(inv + step, vol: 0.14 + (step / 6.6) * 0.22); step += 0.9 }
    m.roar(inv + 2.8, 1.6, vol: 0.26); m.roar(inv + 6.0, 1.8, vol: 0.32)
    m.noise(inv + 3.0, 6.5, vol: 0.28, cutoff: 0.004, cutoffTo: 0.03, attack: 3.0, release: 1.5, seed: 5)
    m.tone(inv + 3.0, 6.5, 41, wave: .sine, vol: 0.16, attack: 3.0, release: 1.5)
    m.whoosh(inv + 4.4, 1.4, vol: 0.18); m.crackle(inv + 5.0, 3.5 + 1.0, vol: 0.06)
    let lg = start("league")
    for k in 0..<10 { m.tone(lg - 0.5 + Double(k) * 0.05, 0.08, 70, to: 55, wave: .sine, vol: 0.05 + Double(k) * 0.012, decay: 0.05) }
    for (s, d, chord) in [(0.0, 1.1, [48, 52, 55, 60]), (1.1, 1.1, [41, 45, 48, 53]), (2.2, 1.1, [43, 47, 50, 55]), (3.3, 1.6, [48, 52, 55, 60])] {
        for n in chord { m.tone(lg + s, d, midi(n), wave: .saw, vol: 0.035, attack: 0.15, release: 0.4) }
        m.tone(lg + s, d, midi(chord[0] - 12), wave: .sine, vol: 0.16, attack: 0.05, release: 0.4)
    }
    for (s, d, n) in [(0.2, 0.4, 67), (0.6, 0.5, 72), (1.1, 0.9, 74), (2.2, 0.4, 71), (2.6, 0.5, 74), (3.3, 1.4, 79)] as [(Double, Double, Int)] {
        m.tone(lg + s, d, midi(n), wave: .square(0.5), vol: 0.06, attack: 0.02, release: 0.12, vibrato: 0.006)
    }
    for order in 0..<7 { m.whoosh(lg + 0.2 + Double(order) * 0.38 + 0.3, 0.5, vol: 0.08) }
    m.tone(lg + 0.2 + 5 * 0.38, 0.3, 300, to: 2400, wave: .saw, vol: 0.05, release: 0.1)
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }
    let desk = start("desktop"), deskEnd = end("desktop") + 1.3
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: 0) { m.pew(t, vol: 0.1); m.clang(t + boltArrival * blasterPeriod, vol: 0.08); m.thwip(t + 0.02, vol: 0.06) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: blasterPeriod / 2) { m.ice(t, vol: 0.07) }
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    m.bark(ag + 1.4)
    let wi = start("window")
    for t in shotTimes(wi, wi + 2.5, offset: 0) { m.pew(t, vol: 0.05); m.clang(t + boltArrival * blasterPeriod, vol: 0.05) }
    for k in [0.9, 1.8] { m.click(wi + k, vol: 0.06) }
    m.ping(wi + 2.5)
    let ais = start("ais")
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    m.crackle(ais + 0.4, end("ais") + 1.3 - ais - 0.4, vol: 0.045)
    for s in shots { transitionSound(m, s) }
    let ec = start("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 2.8, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(ec + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.6 : 0.1) }
        m.tone(ec + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.6 : 0.1, vibrato: 0.006)
        m.tone(ec + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.6 : 0.1)
    }
    m.boom(ec + 0.35, vol: 0.45)
    m.noise(ec + 1.4, 2.5, vol: 0.08, cutoff: 0.9, decay: 0.8, highpass: true, seed: 8)
    m.jet(ec, 1.2, vol: 0.08)
    m.crackle(ec + 0.5, duration - ec - 0.5, vol: 0.025)
}

// MARK: Which video

/// promo, bloopers, or full (the promo, then the bloopers, as one).
let reel = ProcessInfo.processInfo.environment["REEL"] ?? "promo"
let promoLength = promoShots.last!.end
let shots: [Shot] = {
    switch reel {
    case "bloopers": return blooperShots
    case "full": return promoShots + blooperShots.map { $0.shifted(promoLength) }
    case "starclawds": return starClawdsShots
    case "marvelous": return marvelousShots
    case "detective": return detectiveShots
    default: return promoShots
    }
}()
let overlays: [Overlay] = reel == "promo" || reel == "full" ? promoOverlays : []
var duration: Double { shots.last!.end }
/// The soft promo wipe's length: the single-universe trailers keep their slower one.
var softWipe: Double { ["starclawds", "marvelous", "detective"].contains(reel) ? 2.7 : 2.0 }

// MARK: Frame

let feather = 220.0

/// Greyscale mask that is white (keep the outgoing shot) to the right of `edge`, ramping softly across `feather`.
func wipeMask(edge: Double) -> CGImage {
    var row = [UInt8](repeating: 0, count: W)
    for x in 0..<W { row[x] = UInt8(clamp((Double(x) - edge) / feather + 0.5) * 255) }
    let provider = CGDataProvider(data: Data(row) as CFData)!
    return CGImage(width: W, height: 1, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: W,
                   space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                   provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
}

func renderShot(_ s: Shot, at t: Double, into ctx: CGContext) {
    ctx.saveGState(); s.render(ctx, t - s.start, t); ctx.restoreGState()
}

let fullRect = CGRect(x: 0, y: 0, width: W, height: H)

/// The shot whose incoming transition is running at `t`, and how far through it (0…1).
func transition(at t: Double) -> (index: Int, k: Double)? {
    for j in shots.indices.dropFirst() {
        let d = shots[j].into.duration
        guard d > 0 else { continue }
        let k = (t - shots[j].start + d / 2) / d
        if k > 0 && k < 1 { return (j, k) }
    }
    return nil
}

func frame(_ t: Double) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.interpolationQuality = .none
    if t < 0.5 / fps {                                   // the very first frame is the poster GitHub shows before play
        let poster = reel == "bloopers" ? (shots[0], 2.0)
            : ["starclawds", "marvelous", "detective"].contains(reel) ? (shots.first { $0.name == "endcard" }!, 2.5)
            : (shots.first { $0.name == "worlds" }!, 4.0)
        renderShot(poster.0, at: poster.0.start + poster.1, into: ctx)
        NSGraphicsContext.current = nil
        return rep
    }
    if let (j, k) = transition(at: t) {
        let cur = shots[j], prev = shots[j - 1]
        switch cur.into {
        case .wipe:
            renderShot(cur, at: t, into: ctx)
            ctx.saveGState()
            ctx.clip(to: fullRect, mask: wipeMask(edge: lerp(-feather / 2, Double(W) + feather / 2, k)))
            ctx.interpolationQuality = .none
            renderShot(prev, at: t, into: ctx)
            ctx.restoreGState()
        case .starWars(let clock):
            let r = cur.inWindow ? windowRect : fullRect
            renderShot(cur, at: t, into: ctx)
            ctx.saveGState()
            ctx.addPath(Wipe.remaining(k, clock: clock, in: r)); ctx.clip()
            renderShot(prev, at: t, into: ctx)
            ctx.restoreGState()
        case .marvel, .dc:
            let old = shotImage { renderShot(prev, at: t, into: $0) }, new = shotImage { renderShot(cur, at: t, into: $0) }
            let r = cur.inWindow ? windowRect : fullRect
            if cur.inWindow { renderShot(cur, at: t, into: ctx) }
            if var o = old, var n = new {
                if cur.inWindow {                                    // just the window, as the app does it
                    let crop = CGRect(x: r.minX, y: CGFloat(H) - r.maxY, width: r.width, height: r.height)
                    o = o.cropping(to: crop) ?? o; n = n.cropping(to: crop) ?? n
                    ctx.saveGState()
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 22, cornerHeight: 22, transform: nil)); ctx.clip()
                }
                if case .marvel(let trip) = cur.into { trip.draw(ctx, old: o, new: n, k: k, in: r) }
                if case .dc(let trip) = cur.into { trip.draw(ctx, old: o, new: n, k: k, in: r) }
                if cur.inWindow { ctx.restoreGState() }
            }
        case .cut:
            renderShot(cur, at: t, into: ctx)
        }
    } else {
        renderShot(shots[shots.lastIndex(where: { t >= $0.start }) ?? 0], at: t, into: ctx)
    }
    for o in overlays where t >= o.start && t < o.end {
        ctx.saveGState(); o.draw(ctx, t - o.start); ctx.restoreGState()
    }
    // fade in from and out to black
    let black = max(1 - t / 0.2, (t - (duration - 0.3)) / 0.3, 0)
    if black > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: black)); ctx.fill(fullRect) }
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ path: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// MARK: Storyboard sheets

typealias Beat = (title: String, action: String, onScreen: String, sound: String)

let promoBeats: [(key: Double, beat: Beat)] = [
    (2.4, ("COLD OPEN", "Black screen. A yellow comic caption types itself out.", "“MEANWHILE, IN A TERMINAL NEAR YOU...”", "typewriter keys, a bell")),
    (7.0, ("THREE WORLDS", "Hard cut to the icon's three slanted panels, each its universe's place and arch-enemies. CLAWD CLASH slams in across all three, coloured by each panel and cut by the gutters, like the icon.", "CLAWD CLASH", "three fights at once, then the big hit")),
    (11.5, ("THE HOOK", "Three busy terminals (Claude, Codex, Gemini), slow push-in.", "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "keyboard clicks")),
    (17.5, ("PICK YOUR UNIVERSE", "One comic page: three panels slam in one after another, each a desktop brawl in its universe with its name in a caption box and a sound word (VWOOM!, KAPOW!, KRAK!). Under them, the app's Settings → Universe choice clicks along: Star Clawds, Marvelous Clawds, Detective Clawds, then Random.", "“One app. Three universes. Pick yours.”", "three panel slams, clicks")),
    (24.0, ("STAR CLAWDS", "An edge wipe into space: the camera tilts down to the desert planet, a blockade runner flees under laser fire, and the giant wedge ship slides in overhead until its engines fill the top of the frame.", "STAR CLAWDS caption  ·  “Laser swords, blasters and one very, very big ship.”", "a dark pulse, turbolasers, the rumble")),
    (31.2, ("MARVELOUS CLAWDS", "A KAPOW! burst into the Battle of New York: a space whale noses out of the portal and dives at us, Iron Clawd rockets up firing repulsors.", "MARVELOUS CLAWDS caption  ·  “Shields, hammers, webs and a giant space whale.”", "the portal hum, roars, repulsors")),
    (38.2, ("DETECTIVE CLAWDS", "The Night Beacon transition into Megalopolis: a horned kaiju stomps in, roars, and Superb-Man hits it with heat vision.", "DETECTIVE CLAWDS caption  ·  “Capes, power rings and a horned kaiju to deal with.”", "stomps, two roars, heat vision")),
    (44.5, ("AT A GLANCE (MARVELOUS CLAWDS)", "A halftone print-in brings the status line-up: Thorr working, Lokee thinking, Ultraton's jumping NEEDS YOU, Thanoz sat down napping.", "“All fun and games, and you still see everything.”  ·  “(Thanoz sits down when the job's done. Relatable.)”", "blips, alert beeps")),
    (49.0, ("SUBAGENTS (DETECTIVE CLAWDS)", "A grapnel yanks the panel away: agents arrive with their jobs on their labels.", "“Every subagent reports for duty.”  ·  “Its job is right there on its label. No more guessing.”", "footsteps, a bark")),
    (54.5, ("WINDOW (STAR CLAWDS)", "A clock wipe opens on the window in the Mos Easy Cantina; live cards tick, then Luke's Codex card flips to NEEDS YOU.", "“Prefer a window? Grab the popcorn.”", "a ping")),
    (59.6, ("RANDOM", "The window changes universe on its own, three times in a row, each with that universe's transition, inside the window only.", "RANDOM · EVERY 5 MIN  ·  “Can't decide? Random switches the whole window to a new universe every few minutes.”", "the transitions' own sounds")),
    (68.5, ("END CARD", "The app icon pops up over the three panels.", "“Have fun. Keep track.”  ·  “Free for macOS · github.com/rodclemen/clawd-clash”", "final sting")),
]

let blooperBeats: [(key: Double, beat: Beat)] = [
    (1.8, ("BLOOPERS", "A record scratch; a clapperboard slams down over red halftone: BLOOPERS, take 1, and snaps.", "BLOOPERS", "record scratch, slate clack, a goofier tune starts")),
    (5.0, ("TAKE 3", "The Bulk wanders into the Mos Easy Cantina. The band freezes mid-note. Then CUT! from off screen and the slate snaps: TAKE 3.", "“…wrong set?”", "the band stops dead")),
    (12.2, ("TAKE 7", "Darth Vapor turns dramatically to Spider-Clawd on the Doom Moon.", "“Spider-Clawd… I am your… landlord.”  ·  “Pretty sure it's an aunt thing.”", "a dramatic sting, then CUT!")),
    (17.6, ("TAKE 12", "Batclawd lights the Night Beacon over the Doom Moon. Two Stormtroupers open fire on it and miss every shot.", "“You know it's a light, right?”", "blasters, all missing")),
    (23.4, ("TAKE 15", "The Jester Card transition spins in and flips: Thanoz is on the back, on Titan. The Jester peeks into the shot with a ?.", "no text", "the card flip, a slide whistle")),
    (28.4, ("TAKE 21", "Yodle calmly floats Thorr's hammer up off the floor. Thorr stares.", "“…”  ·  “Worthy, hmm. Heavy, it is not.”", "a shimmer, then CUT!")),
    (33.2, ("TAKE 22", "The Millennial Falcon jumps to hyperspace in a blink; Superb-Man is left behind in the star streaks.", "“Hey! Wait up!”", "the jump, a whoosh")),
    (38.3, ("THAT'S A WRAP", "Everyone crammed into one frame at Clawdvengers Tower, Deadpond leaning into the camera. Then the whole cast waves.", "“Separate universes, they said. Totally under control.”  ·  “CUT! THAT'S A WRAP!”", "a final sting and applause")),
]

func storyboard(_ title: String, _ beats: [(key: Double, beat: Beat)], shift: Double = 0) -> NSBitmapImageRep {
    let frames = beats.map { frame($0.key + shift) }
    let cols = 2, pw = 900.0, ph = pw * 9 / 16, textH = 270.0, gap = 60.0, margin = 70.0, headH = 200.0
    let rows = (frames.count + cols - 1) / cols
    let sw = Int(margin * 2 + pw * Double(cols) + gap * Double(cols - 1))
    let sh = Int(headH + Double(rows) * (ph + textH) + Double(rows - 1) * gap * 0.5 + margin)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: sw, pixelsHigh: sh, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(CGColor(red: 0.07, green: 0.075, blue: 0.11, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: sw, height: sh))
    func put(_ s: String, _ x: Double, _ y: Double, _ size: CGFloat, _ weight: NSFont.Weight, _ col: NSColor, width: Double = 0) {
        let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: col])
        if width > 0 { a.draw(with: NSRect(x: x, y: y - 200, width: width, height: 200), options: [.usesLineFragmentOrigin]) }
        else { a.draw(at: NSPoint(x: x, y: y)) }
    }
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: 64) ?? .systemFont(ofSize: 60, weight: .black)
    NSAttributedString(string: title, attributes: [.font: tf, .foregroundColor: yellow, .kern: 5]).draw(at: NSPoint(x: margin, y: Double(sh) - 110))
    put(String(format: "%.0f seconds · storyboard · 1920×1080 · 30 fps · every sprite, place and transition drawn by the app's own code", duration),
        margin, Double(sh) - 150, 26, .medium, NSColor(white: 0.75, alpha: 1))
    let dim = NSColor(white: 0.62, alpha: 1), body = NSColor(white: 0.92, alpha: 1)
    for (i, f) in frames.enumerated() {
        let b = beats[i].beat
        let x = margin + Double(i % cols) * (pw + gap)
        let top = Double(sh) - headH - Double(i / cols) * (ph + textH + gap * 0.5)
        let r = CGRect(x: x, y: top - ph, width: pw, height: ph)
        ctx.saveGState(); ctx.interpolationQuality = .high; ctx.draw(f.cgImage!, in: r); ctx.restoreGState()
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.25)); ctx.setLineWidth(2); ctx.stroke(r)
        let ty = top - ph - 44
        put("\(i + 1)  \(b.title)", x, ty, 30, .heavy, yellow)
        put(String(format: "%.1f s", beats[i].key), x + pw - 110, ty + 2, 26, .semibold, dim)
        put(b.action, x, ty - 14, 21, .regular, body, width: pw)
        put("ON SCREEN  " + b.onScreen, x, ty - 110, 20, .semibold, NSColor(srgbRed: 0.75, green: 0.85, blue: 1, alpha: 1), width: pw)
        put("SOUND  " + b.sound, x, ty - 190, 20, .semibold, dim, width: pw)
    }
    NSGraphicsContext.current = nil
    return rep
}


// MARK: Soundtrack (all synthesized here: an original chiptune score and retro sound effects)

let sampleRate = 44100.0
func hashNoise(_ i: Int) -> Double { noise(i) }   // the sprites' noise, reachable from inside Mix

/// A mono mix bus the whole soundtrack is written into.
final class Mix {
    var buf: [Float]
    init(seconds: Double) { buf = [Float](repeating: 0, count: Int(seconds * sampleRate) + 1) }

    enum Wave { case square(Double), saw, triangle, sine }

    /// One note or sweep: `freq` slides to `to`, with an attack/release envelope and optional vibrato.
    func tone(_ start: Double, _ dur: Double, _ freq: Double, to: Double? = nil, wave: Wave = .square(0.5), vol: Double,
              attack: Double = 0.005, release: Double = 0.05, decay: Double = 0, vibrato: Double = 0) {
        guard start < Double(buf.count) / sampleRate, dur > 0 else { return }
        let n = Int(dur * sampleRate), s0 = Int(max(0, start) * sampleRate)
        var phase = 0.0
        for i in 0..<n {
            let idx = s0 + i
            guard idx < buf.count else { break }
            let tt = Double(i) / sampleRate, p = tt / dur
            var f = to.map { freq * pow($0 / freq, p) } ?? freq
            if vibrato > 0 { f *= 1 + vibrato * sin(tt * 2 * .pi * 5.5) }
            phase += f / sampleRate
            let ph = phase - floor(phase)
            let v: Double
            switch wave {
            case .square(let duty): v = ph < duty ? 1 : -1
            case .saw: v = 2 * ph - 1
            case .triangle: v = ph < 0.5 ? 4 * ph - 1 : 3 - 4 * ph
            case .sine: v = sin(2 * .pi * ph)
            }
            var env = min(1, tt / attack) * min(1, (dur - tt) / release)
            if decay > 0 { env *= exp(-tt / decay) }
            buf[idx] += Float(v * env * vol)
        }
    }

    /// Filtered noise: `cutoff` (0…1, one-pole low-pass amount) slides to `cutoffTo`; `highpass` keeps only the hiss.
    func noise(_ start: Double, _ dur: Double, vol: Double, cutoff: Double = 1, cutoffTo: Double? = nil,
               attack: Double = 0.002, release: Double = 0.05, decay: Double = 0, highpass: Bool = false, seed: Int = 1) {
        let n = Int(dur * sampleRate), s0 = Int(max(0, start) * sampleRate)
        var lp = 0.0, rng = UInt64(seed &* 2654435761 &+ 12345)
        for i in 0..<n {
            let idx = s0 + i
            guard idx < buf.count else { break }
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            let white = Double(Int64(bitPattern: rng >> 11) % 2_000_000) / 1_000_000 - 1
            let tt = Double(i) / sampleRate, p = tt / dur
            let a = cutoffTo.map { cutoff + ($0 - cutoff) * p } ?? cutoff
            lp += (white - lp) * a
            let v = highpass ? white - lp : lp
            var env = min(1, tt / attack) * min(1, max(0, dur - tt) / release)
            if decay > 0 { env *= exp(-tt / decay) }
            buf[idx] += Float(v * env * vol)
        }
    }

    // Sound effects
    func pew(_ t: Double, vol: Double = 0.16) {                       // hand blaster
        tone(t, 0.2, 1900, to: 220, wave: .square(0.5), vol: vol, release: 0.08, decay: 0.09)
        noise(t, 0.05, vol: vol * 0.5, cutoff: 0.6, decay: 0.02)
    }
    func turbolaser(_ t: Double, pitch: Double, vol: Double = 0.1) {
        tone(t, 0.32, 900 * pitch, to: 110 * pitch, wave: .saw, vol: vol, release: 0.1, decay: 0.14)
        noise(t, 0.12, vol: vol * 0.6, cutoff: 0.25, decay: 0.05, seed: Int(t * 100))
    }
    func clash(_ t: Double, vol: Double = 0.2) {                      // sabers meeting
        noise(t, 0.22, vol: vol, cutoff: 0.9, decay: 0.06, highpass: true, seed: Int(t * 77))
        tone(t, 0.18, 1400, to: 500, wave: .square(0.3), vol: vol * 0.35, decay: 0.05)
        tone(t, 0.25, 180, to: 120, wave: .saw, vol: vol * 0.4, decay: 0.1)
    }
    func ignite(_ t: Double, vol: Double = 0.14) {
        tone(t, 0.5, 70, to: 120, wave: .saw, vol: vol, attack: 0.02, release: 0.2)
        noise(t, 0.3, vol: vol * 0.5, cutoff: 0.05, cutoffTo: 0.4, decay: 0.15, seed: 9)
    }
    func hum(_ t: Double, _ dur: Double, vol: Double = 0.035) {        // saber hum while blades are out
        tone(t, dur, 92, wave: .saw, vol: vol, attack: 0.3, release: 0.4, vibrato: 0.01)
        tone(t, dur, 94.5, wave: .saw, vol: vol, attack: 0.3, release: 0.4)
    }
    func boom(_ t: Double, vol: Double = 0.45) {
        tone(t, 1.2, 90, to: 32, wave: .sine, vol: vol, release: 0.4, decay: 0.45)
        noise(t, 0.8, vol: vol * 0.5, cutoff: 0.08, cutoffTo: 0.01, decay: 0.3, seed: Int(t * 13))
    }
    func whoosh(_ center: Double, _ dur: Double, vol: Double = 0.12) {
        noise(center - dur / 2, dur, vol: vol, cutoff: 0.01, cutoffTo: 0.25, attack: dur * 0.5, release: dur * 0.5, seed: Int(center * 31))
    }
    func pop(_ t: Double, step: Int, vol: Double = 0.1) {
        let f = 520 * pow(2, Double(step) * 4 / 12)
        tone(t, 0.09, f, to: f * 1.6, wave: .square(0.25), vol: vol, release: 0.03)
    }
    func ping(_ t: Double, vol: Double = 0.16) {                      // notification
        tone(t, 0.25, 1318.5, wave: .sine, vol: vol, release: 0.2, decay: 0.15)
        tone(t + 0.12, 0.45, 1760, wave: .sine, vol: vol, release: 0.35, decay: 0.2)
    }
    func step(_ t: Double, vol: Double = 0.05) { noise(t, 0.04, vol: vol, cutoff: 0.15, decay: 0.012, seed: Int(t * 997)) }
    func click(_ t: Double, vol: Double = 0.1) {                      // a laptop key
        noise(t, 0.025, vol: vol, cutoff: 0.3, decay: 0.008, highpass: true, seed: Int(t * 541))
        noise(t, 0.03, vol: vol * 0.5, cutoff: 0.15, decay: 0.01, seed: Int(t * 613))
    }
    func r2(_ t: Double, vol: Double = 0.07) {                       // a little droid chirp
        for k in 0..<10 {
            let f = 1100 + hashNoise(Int(t * 10) + k * 3) * 1700
            tone(t + Double(k) * 0.045, 0.05, f, to: f * (hashNoise(k + 4) > 0.5 ? 1.3 : 0.8), wave: .sine, vol: vol, release: 0.01)
        }
    }
    // Drums
    func kick(_ t: Double, vol: Double = 0.3) { tone(t, 0.16, 150, to: 45, wave: .sine, vol: vol, release: 0.05, decay: 0.08) }
    func snare(_ t: Double, vol: Double = 0.12) {
        noise(t, 0.14, vol: vol, cutoff: 0.7, decay: 0.05, seed: Int(t * 61))
        tone(t, 0.08, 220, to: 160, wave: .triangle, vol: vol * 0.5, decay: 0.04)
    }
    func hat(_ t: Double, vol: Double = 0.035) { noise(t, 0.04, vol: vol, cutoff: 0.95, decay: 0.012, highpass: true, seed: Int(t * 173)) }
}

func midi(_ n: Int) -> Double { 440 * pow(2, Double(n - 69) / 12) }

/// Writes 16-bit mono PCM as a WAV file.
func writeWAV(_ samples: [Float], to path: String) {
    var d = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
    d.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + samples.count * 2)); d.append("WAVEfmt ".data(using: .ascii)!)
    u32(16); u16(1); u16(1); u32(UInt32(sampleRate)); u32(UInt32(sampleRate) * 2); u16(2); u16(16)
    d.append("data".data(using: .ascii)!); u32(UInt32(samples.count * 2))
    var pcm = [Int16](repeating: 0, count: samples.count)
    for i in samples.indices { pcm[i] = Int16(max(-1, min(1, samples[i])) * 32000) }
    pcm.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
    try! d.write(to: URL(fileURLWithPath: path))
}

func shotStart(_ name: String) -> Double { shots.first { $0.name == name }!.start }

/// Every time the duelling blades meet (the same clock the sparks use) between `a` and `b`.
func clashTimes(_ a: Double, _ b: Double) -> [Double] {
    var out: [Double] = [], was = false
    var t = a
    while t < b {
        let c = duelPose(t).clash
        if c && !was { out.append(t) }
        was = c; t += 1 / 120
    }
    return out
}

/// When a blaster with `offset` fires between `a` and `b` (a bolt leaves at each whole period).
func shotTimes(_ a: Double, _ b: Double, offset: Double) -> [Double] {
    var out: [Double] = []
    var k = ceil((a + offset) / blasterPeriod)
    while k * blasterPeriod - offset < b { out.append(k * blasterPeriod - offset); k += 1 }
    return out
}

// Marvel sound effects
extension Mix {
    func type(_ t: Double, vol: Double = 0.22) {                     // a typewriter key: the strike, then the thunk
        noise(t, 0.04, vol: vol, cutoff: 0.25, decay: 0.012, highpass: true, seed: Int(t * 733))
        noise(t, 0.06, vol: vol * 0.8, cutoff: 0.12, decay: 0.02, seed: Int(t * 977))
        tone(t, 0.05, 150, to: 90, wave: .triangle, vol: vol * 0.7, decay: 0.018)
    }
    func ding(_ t: Double, vol: Double = 0.12) {                     // the bell at the end of the line
        tone(t, 0.9, 2093, wave: .sine, vol: vol, release: 0.6, decay: 0.35)
        tone(t, 0.6, 4186, wave: .sine, vol: vol * 0.3, release: 0.4, decay: 0.2)
    }
    func flip(_ t: Double, vol: Double = 0.06) {                     // a comic page turning
        noise(t, 0.09, vol: vol, cutoff: 0.05, cutoffTo: 0.5, attack: 0.03, release: 0.04, seed: Int(t * 389))
    }
    func clang(_ t: Double, vol: Double = 0.12) {                    // a shot off Cap's shield
        for (f, d) in [(1250.0, 0.35), (1870.0, 0.25), (2930.0, 0.18)] { tone(t, d, f, wave: .sine, vol: vol / 2, release: 0.1, decay: d / 3) }
        noise(t, 0.03, vol: vol * 0.7, cutoff: 0.9, decay: 0.01, highpass: true, seed: Int(t * 91))
    }
    func repulsor(_ t: Double, vol: Double = 0.1) {                  // Iron Man's palm blast
        tone(t, 0.28, 2400, to: 700, wave: .sine, vol: vol, release: 0.1, decay: 0.12)
        noise(t, 0.2, vol: vol * 0.7, cutoff: 0.5, cutoffTo: 0.05, decay: 0.08, seed: Int(t * 57))
    }
    func thwip(_ t: Double, vol: Double = 0.1) {                     // a web shot
        noise(t, 0.12, vol: vol, cutoff: 0.1, cutoffTo: 0.9, attack: 0.01, release: 0.05, seed: Int(t * 211))
        tone(t, 0.1, 600, to: 1600, wave: .triangle, vol: vol * 0.4, release: 0.04)
    }
    func bomb(_ t: Double, vol: Double = 0.1) {                      // a pumpkin bomb: lobbed, then a pop
        tone(t, 0.18, 400, to: 900, wave: .square(0.3), vol: vol * 0.4, release: 0.05)
        noise(t + 0.36, 0.25, vol: vol, cutoff: 0.3, cutoffTo: 0.03, decay: 0.09, seed: Int(t * 17))
    }
    func roar(_ t: Double, _ dur: Double, vol: Double = 0.2) {       // a Leviathan bellowing
        tone(t, dur, 75, to: 48, wave: .saw, vol: vol, attack: 0.15, release: dur * 0.4, vibrato: 0.06)
        tone(t, dur, 112, to: 70, wave: .saw, vol: vol * 0.6, attack: 0.2, release: dur * 0.4, vibrato: 0.08)
        noise(t, dur, vol: vol * 0.7, cutoff: 0.04, cutoffTo: 0.015, attack: 0.15, release: dur * 0.4, seed: Int(t * 3))
    }
    func crackle(_ t: Double, _ dur: Double, vol: Double = 0.05) {   // a magic beam, Thanos' gauntlet
        tone(t, dur, 160, wave: .saw, vol: vol, attack: 0.1, release: 0.2, vibrato: 0.04)
        noise(t, dur, vol: vol * 0.8, cutoff: 0.6, attack: 0.1, release: 0.2, highpass: true, seed: Int(t * 29))
    }
    func groot(_ t: Double, vol: Double = 0.08) {                    // a low, friendly rumble, three notes
        for (k, n) in [43, 45, 40].enumerated() {
            tone(t + Double(k) * 0.22, 0.24, midi(n), wave: .triangle, vol: vol, attack: 0.03, release: 0.08, vibrato: 0.02)
        }
    }
    func jet(_ t: Double, _ dur: Double, vol: Double = 0.06) {       // the Quinjet going by
        tone(t, dur, 700, to: 1100, wave: .saw, vol: vol * 0.4, attack: dur * 0.4, release: dur * 0.5)
        noise(t, dur, vol: vol * 2, cutoff: 0.02, cutoffTo: 0.3, attack: dur * 0.45, release: dur * 0.5, seed: 77)
    }
}

/// When a ranged fighter with `offset` lets a shot go between `a` and `b`.
func fireTimes(_ a: Double, _ b: Double, offset: Double) -> [Double] { shotTimes(a, b, offset: offset) }


// DC sound effects
extension Mix {
    func rain(_ t: Double, _ dur: Double, vol: Double = 0.05) {      // a Gotham downpour
        noise(t, dur, vol: vol, cutoff: 0.5, attack: 0.6, release: 0.8, highpass: true, seed: 404)
    }
    func clunk(_ t: Double, vol: Double = 0.25) {                    // the searchlight's shutter thrown open
        tone(t, 0.12, 90, to: 50, wave: .square(0.4), vol: vol, decay: 0.05)
        noise(t, 0.08, vol: vol * 0.6, cutoff: 0.3, decay: 0.03, seed: 41)
    }
    func boomTube(_ t: Double, vol: Double = 0.3) {                  // space torn open
        boom(t, vol: vol)
        noise(t, 0.9, vol: vol * 0.5, cutoff: 0.9, decay: 0.3, highpass: true, seed: 66)
        tone(t, 0.8, 1800, to: 120, wave: .saw, vol: vol * 0.25, release: 0.3)
    }
    func buzz(_ t: Double, vol: Double = 0.03) {                     // a Parademon's wings
        tone(t, 0.35, 160 + hashNoise(Int(t * 10)) * 60, wave: .square(0.2), vol: vol, attack: 0.05, release: 0.15, vibrato: 0.1)
    }
    func ice(_ t: Double, vol: Double = 0.08) {                      // Captain Cold's cold gun
        noise(t, 0.3, vol: vol, cutoff: 0.6, attack: 0.02, release: 0.15, highpass: true, seed: Int(t * 97))
        tone(t, 0.3, 3200, to: 2600, wave: .sine, vol: vol * 0.3, release: 0.15)
    }
    func bark(_ t: Double, vol: Double = 0.1) {                      // Krypto, twice
        for k in 0..<2 {
            tone(t + Double(k) * 0.22, 0.12, 520, to: 300, wave: .square(0.35), vol: vol, release: 0.05, decay: 0.06)
            noise(t + Double(k) * 0.22, 0.08, vol: vol * 0.5, cutoff: 0.2, decay: 0.03, seed: k + 12)
        }
    }
}


// Clawd Clash sound effects
extension Mix {
    func scratch(_ t: Double, vol: Double = 0.2) {                   // a record scratch
        tone(t, 0.14, 900, to: 180, wave: .saw, vol: vol, release: 0.03)
        tone(t + 0.14, 0.16, 220, to: 700, wave: .saw, vol: vol * 0.8, release: 0.05)
        noise(t, 0.3, vol: vol * 0.6, cutoff: 0.5, highpass: true, seed: 71)
    }
    func clack(_ t: Double, vol: Double = 0.3) {                     // the slate snapping shut
        noise(t, 0.05, vol: vol, cutoff: 0.95, decay: 0.012, highpass: true, seed: Int(t * 37))
        tone(t, 0.06, 380, to: 160, wave: .square(0.5), vol: vol * 0.5, decay: 0.02)
    }
    func recordStop(_ t: Double, vol: Double = 0.12) { tone(t, 0.6, 500, to: 40, wave: .saw, vol: vol, release: 0.2) }
    func slideWhistle(_ t: Double, up: Bool, vol: Double = 0.07) {
        tone(t, 0.5, up ? 500 : 1500, to: up ? 1500 : 500, wave: .sine, vol: vol, attack: 0.03, release: 0.08, vibrato: 0.01)
    }
    func wahWah(_ t: Double, vol: Double = 0.07) {                   // the sad trombone, four notes down
        for (k, n) in [58, 57, 56, 55].enumerated() {
            let d = k == 3 ? 0.9 : 0.28
            tone(t + Double(k) * 0.3, d, midi(n), to: midi(n) * 0.97, wave: .saw, vol: vol, attack: 0.03, release: 0.1, vibrato: k == 3 ? 0.03 : 0.01)
        }
    }
    func shimmer(_ t: Double, _ dur: Double, vol: Double = 0.03) {   // something magic floating up
        var s = 0.0, k = 0
        while s < dur { tone(t + s, 0.25, midi([84, 88, 91, 96][k % 4]), wave: .sine, vol: vol, release: 0.2, decay: 0.12); s += 0.12; k += 1 }
    }
    func applause(_ t: Double, _ dur: Double, vol: Double = 0.06) {
        for i in 0..<Int(dur * 40) { noise(t + Double(i) / 40 + hashNoise(i) * 0.02, 0.03, vol: vol, cutoff: 0.7, decay: 0.01, highpass: true, seed: i + 900) }
    }
}

/// Sounds of the transition that brings in shot `s`.
func transitionSound(_ m: Mix, _ s: Shot) {
    let d = s.into.duration, t0 = s.start - d / 2
    switch s.into {
    case .cut: break
    case .wipe, .starWars: m.whoosh(s.start, d, vol: 0.08)
    case .marvel(let trip):
        switch trip.kind {
        case .burst: m.boom(t0 + d * 0.3, vol: 0.25); m.snare(t0 + d * 0.3, vol: 0.12)
        case .speedLines: m.whoosh(s.start, d, vol: 0.14)
        default: m.whoosh(s.start, d, vol: 0.08)
        }
    case .dc(let trip):
        switch trip.kind {
        case .batSignal: m.clunk(t0 + d * 0.35); m.boom(t0 + d * 0.5, vol: 0.2)
        case .grapple: m.thwip(t0 + d * 0.15, vol: 0.12); m.whoosh(t0 + d * 0.5, d * 0.5, vol: 0.1)
        case .jokerCard: m.flip(t0 + d * 0.2, vol: 0.1); m.slideWhistle(t0 + d * 0.45, up: true)
        default: m.whoosh(s.start, d, vol: 0.08)
        }
    }
}

func start(_ name: String) -> Double { shots.first { $0.name == name }!.start }
func end(_ name: String) -> Double { shots.first { $0.name == name }!.end }

/// The promo's score and effects, `o` seconds in.
func promoSound(_ m: Mix) {
    // cold open: a key for every letter, a bell, a low drone
    let mw = start("meanwhile")
    for i in 0..<35 { m.type(mw + 0.3 + Double(i) / 35 * 1.6 + noise(i) * 0.02, vol: 0.18 + noise(i + 50) * 0.08) }
    m.ding(mw + 2.0)
    m.tone(mw + 0.2, 3.0, midi(33), wave: .sine, vol: 0.05, attack: 1.0, release: 0.8)

    // three worlds: all three fights at once, then CLAWD CLASH hits with an original fanfare
    let w = start("worlds"), we = end("worlds")
    m.hum(w, we - w, vol: 0.025)
    for t in clashTimes(w, we) { m.clash(t, vol: 0.12) }
    for t in shotTimes(w, we, offset: 0) { m.pew(t, vol: 0.07); m.clang(t + boltArrival * blasterPeriod, vol: 0.06) }
    m.crackle(w, we - w, vol: 0.03)
    let hit = w + 1.6
    m.boom(hit, vol: 0.6); m.noise(hit, 1.8, vol: 0.13, cutoff: 0.9, decay: 0.55, highpass: true, seed: 3)
    for n in [48, 55, 60, 64, 67] { m.tone(hit, 1.4, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.8) }
    for (s, d, n) in [(0.3, 0.25, 67), (0.6, 0.25, 72), (0.9, 0.6, 76), (1.6, 0.25, 74), (1.9, 0.25, 72), (2.2, 1.2, 79)] as [(Double, Double, Int)] {
        m.tone(hit + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(hit + s, d, midi(n), wave: .saw, vol: 0.045, release: 0.08)
    }

    // the groove: under the hook and the comic page, then again from the features to the end card
    let g0 = start("hook"), beat = 0.5, bar = 2.0
    let roots = [45, 41, 48, 43], triads = [[69, 72, 76], [65, 69, 72], [67, 72, 76], [67, 71, 74]]
    let melodyA: [[(Int, Double)]] = [[(76, 1), (81, 1), (84, 0.5), (83, 0.5), (81, 1)], [(84, 1), (81, 1), (77, 0.5), (79, 0.5), (81, 1)],
                                      [(79, 1), (76, 0.5), (79, 0.5), (84, 1), (83, 1)], [(86, 1), (83, 1), (79, 2)]]
    let melodyB: [[(Int, Double)]] = [[(81, 0.5), (84, 0.5), (88, 1), (86, 0.5), (84, 0.5), (83, 1)], [(81, 1.5), (84, 0.5), (81, 1), (77, 1)],
                                      [(79, 0.5), (81, 0.5), (79, 0.5), (76, 0.5), (79, 1), (84, 1)], [(83, 1), (86, 1), (91, 2)]]
    let quiet = (start("showStarClaws"), start("status"))
    let outer = m, gm = Mix(seconds: duration)
    do {
    let m = gm                                         // the groove goes on its own track, faded round the showcases
    let bars = Int(((start("endcard") - g0) / bar).rounded())
    for b in 0..<bars {
        let t0 = g0 + Double(b) * bar, c = b % 4, full = b >= 2
        if t0 > quiet.0 + 1.5 && t0 + bar < quiet.1 - 1.0 { continue }
        for e in 0..<8 {
            m.tone(t0 + Double(e) * beat / 2, beat / 2 * 0.9, midi(roots[c] - 12 + (e % 2) * 12), wave: .square(0.25), vol: full ? 0.075 : 0.05, release: 0.02)
            m.hat(t0 + Double(e) * beat / 2, vol: e % 2 == 1 ? 0.04 : 0.025)
        }
        m.kick(t0)
        if full {
            m.kick(t0 + 2 * beat); m.kick(t0 + 2.5 * beat, vol: 0.18); m.snare(t0 + beat); m.snare(t0 + 3 * beat)
            for s in 0..<16 { m.tone(t0 + Double(s) * beat / 4, beat / 4 * 0.8, midi(triads[c][s % 3] - 12 + (s / 3 % 2) * 12), wave: .triangle, vol: 0.03, release: 0.02) }
            var tt = t0
            for (n, d) in ((b - 2) / 4 % 2 == 0 ? melodyA : melodyB)[c] { m.tone(tt, d * beat * 0.92, midi(n), wave: .square(0.5), vol: 0.055, release: 0.04, vibrato: 0.004); tt += d * beat }
        }
        if b == bars - 1 { for k in 0..<8 { m.snare(t0 + 2 * beat + Double(k) * beat / 4, vol: 0.06 + Double(k) * 0.01) } }
    }
    }
    for i in gm.buf.indices {                           // out over the wipe into Star Clawds, back in under the halftone print
        let t = Double(i) / sampleRate
        let g = t < quiet.0 ? clamp((quiet.0 + 0.9 - t) / 1.6) : clamp((t - (quiet.1 - 1.0)) / 1.2)
        if g > 0 { outer.buf[i] += gm.buf[i] * Float(g) }
    }
    outer.noise(quiet.0 - 0.2, 2.2, vol: 0.12, cutoff: 0.9, decay: 0.7, highpass: true, seed: 33)   // a crash on the way in
    outer.boom(quiet.0 - 0.2, vol: 0.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }

    // the comic page: three panel slams and the picker's clicks
    let pk = start("pick")
    for (i, at) in [0.3, 1.2, 2.1].enumerated() { m.boom(pk + at, vol: 0.22); m.snare(pk + at, vol: 0.1); m.pop(pk + at + 0.05, step: i) }
    for at in [0.3, 1.2, 2.1, 3.1] { m.click(pk + at + 0.15, vol: 0.12) }

    // Star Clawds: a dark pulse, the turbolasers and the rumble as the big ship passes (its scene runs 1.4 s in)
    let sw = start("showStarClaws"), swe = end("showStarClaws") + 0.6, so = sw - 1.4
    for i in 0..<Int((swe - sw + 1.0) / 0.25) { m.tone(sw - 1.0 + Double(i) * 0.25, 0.22, midi(i % 8 == 7 ? 37 : 36), wave: .square(0.25), vol: 0.05 + 0.05 * min(1, Double(i) / 20), release: 0.04) }
    for (at, chord) in [(0.0, [48, 51, 55]), (2.0, [44, 48, 51]), (4.0, [46, 50, 53]), (6.0, [48, 51, 55])] {
        for n in chord { m.tone(sw + at, 1.8, midi(n), wave: .saw, vol: 0.035, attack: 0.05, release: 0.6) }
    }
    for i in 0..<40 { let b = so + 1.3 + Double(i) * 0.17; if b > sw && b < swe { m.turbolaser(b, pitch: noise(i * 7) > 0.5 ? 1 : 0.8, vol: 0.06) } }
    m.boom(so + 3.0, vol: 0.35)
    m.noise(so + 2.6, 5.0, vol: 0.28, cutoff: 0.004, cutoffTo: 0.03, attack: 2.4, release: 1.5, seed: 5)
    m.tone(so + 2.6, 5.0, 41, wave: .sine, vol: 0.16, attack: 2.4, release: 1.5)

    // Marvelous Clawds: the portal humming, the space whale's roars, Iron Clawd's thrusters and repulsors (2.2 s in)
    let mv = start("showMarvelous Clawds"), mo = mv - 2.2
    m.tone(mv, 7.6, 110, wave: .sine, vol: 0.05, attack: 0.6, release: 1.2, vibrato: 0.03)
    m.roar(mo + 2.6, 1.6, vol: 0.22); m.roar(mo + 5.6, 2.2, vol: 0.3)
    m.noise(mo + 3.0, 6.0, vol: 0.28, cutoff: 0.004, cutoffTo: 0.03, attack: 2.5, release: 1.5, seed: 5)
    m.noise(mo + 4.2, 4.0, vol: 0.1, cutoff: 0.05, cutoffTo: 0.2, attack: 0.6, release: 1.2, seed: 12)
    for i in 0..<10 { m.repulsor(mo + 4.9 + Double(i) * 0.3, vol: 0.08) }

    // Detective Clawds: the kaiju's footfalls, two roars, Superb-Man's take-off and heat vision (0.4 s in)
    let dc = start("showDetective"), dco = dc - 0.4
    var step = 0.8
    while step < 6.6 { if dco + step > dc { m.boom(dco + step, vol: 0.14 + (step / 6.6) * 0.22) }; step += 0.9 }
    m.roar(dco + 2.8, 1.6, vol: 0.26); m.roar(dco + 6.0, 1.8, vol: 0.32)
    m.whoosh(dco + 4.4, 1.4, vol: 0.18)
    m.crackle(dco + 5.0, 3.0, vol: 0.06)

    // the features
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    m.bark(ag + 1.4)
    let wi = start("window")
    m.hum(wi, 2.6, vol: 0.02)
    for t in clashTimes(wi, wi + 2.6) { m.clash(t, vol: 0.08) }
    for k in [0.9, 1.8] { m.click(wi + k, vol: 0.06) }
    m.ping(wi + 2.6)
    for s in shots { transitionSound(m, s) }

    // end card: a heroic cadence and the icon landing
    let ec = start("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 3.4, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(ec + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.8 : 0.1) }
        m.tone(ec + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.8 : 0.1, vibrato: 0.006)
        m.tone(ec + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.8 : 0.1)
    }
    m.boom(ec + 0.3, vol: 0.45)
}

/// The blooper reel's goofy tune and gags.
func bloopersSound(_ m: Mix) {
    let cl = start("clapper")
    m.scratch(cl + 0.05)
    m.clack(cl + 1.0, vol: 0.4)
    // an oom-pah tune in F, kazoo lead: from the slate to the end, quiet under the takes, stopping dead in take 3
    let beat = 60.0 / 140, t0 = cl + 1.1, stopA = start("take3") + 1.3, stopB = start("take3") + 4.3
    let roots = [41, 46, 48, 41], chords = [[65, 69, 72], [65, 70, 74], [64, 67, 72], [65, 69, 72]]
    let tune: [(Int, Double)] = [(72, 1), (74, 0.5), (76, 0.5), (77, 1), (72, 1), (74, 0.5), (72, 0.5), (70, 1), (69, 2),
                                 (69, 1), (70, 0.5), (72, 0.5), (74, 1), (70, 1), (72, 0.5), (70, 0.5), (69, 1), (65, 2)]
    var b = 0
    var bt = t0
    while bt < end("wrap") - 1.2 {
        let c = (b / 4) % 4
        if !(bt > stopA && bt < stopB) {
            m.tone(bt, beat * 0.5, midi(roots[c] - 12 + (b % 2 == 0 ? 0 : 7)), wave: .square(0.5), vol: 0.06, release: 0.03)   // oom
            for n in chords[c] { m.tone(bt + beat * 0.5, beat * 0.35, midi(n - 12), wave: .square(0.125), vol: 0.022, release: 0.02) }   // pah
        }
        b += 1; bt += beat
    }
    var lt = t0, i = 0
    while lt < end("wrap") - 1.4 {
        let (n, d) = tune[i % tune.count]
        if !(lt > stopA && lt < stopB) { m.tone(lt, d * beat * 0.9, midi(n), wave: .saw, vol: 0.035, attack: 0.02, release: 0.05, vibrato: 0.02) }
        lt += d * beat; i += 1
    }
    m.recordStop(stopA)
    // every take ends on CUT! and a slate
    for (name, at) in [("take3", 3.9), ("take7", 5.8), ("take12", 4.0), ("take15", 3.4), ("take21", 5.4), ("take22", 4.0)] {
        let s = start(name)
        m.tone(s + at, 0.18, 300, to: 220, wave: .square(0.5), vol: 0.08, release: 0.05)   // a honk for the CUT!
        m.clack(s + at + 0.7)
    }
    m.step(start("take3") + 0.3, vol: 0.12); m.step(start("take3") + 0.7, vol: 0.12); m.step(start("take3") + 1.1, vol: 0.12)
    let t7 = start("take7")
    for n in [43, 46, 50] { m.tone(t7 + 0.6, 0.9, midi(n), wave: .saw, vol: 0.05, release: 0.4) }               // the dramatic turn
    m.wahWah(t7 + 3.7)
    let t12 = start("take12")
    m.clunk(t12)
    for i in 0..<12 { m.pew(t12 + 0.5 + Double(i) * 0.22, vol: 0.07) }
    let t15 = start("take15")
    m.flip(t15 + 0.5, vol: 0.1); m.slideWhistle(t15 + 1.4, up: false)
    m.shimmer(start("take21") + 0.5, 1.5)
    let t22 = start("take22")
    m.tone(t22 + 0.6, 0.4, 200, to: 2400, wave: .saw, vol: 0.06, release: 0.1); m.boom(t22 + 0.95, vol: 0.3); m.whoosh(t22 + 1.6, 1.2, vol: 0.12)
    let wr = start("wrap")
    for n in [53, 57, 60, 65, 69] { m.tone(wr + 4.4, 1.8, midi(n), wave: .saw, vol: 0.045, release: 1.0) }
    m.boom(wr + 4.4, vol: 0.35)
    m.applause(wr + 4.5, 2.6)
}

func soundtrack() -> [Float] {
    let m = Mix(seconds: duration)
    switch reel {
    case "starclawds": starClawdsSound(m)
    case "marvelous": marvelousSound(m)
    case "detective": detectiveSound(m)
    default:
        if reel != "bloopers" { promoSound(m) }
        if reel != "promo" { bloopersSound(m) }
    }
    var peak: Float = 0
    for i in m.buf.indices { m.buf[i] = Float(tanh(Double(m.buf[i]) * 1.2)); peak = max(peak, abs(m.buf[i])) }
    let gain = peak > 0 ? 0.89 / peak : 1
    let fadeFrom = Int((duration - 1.2) * sampleRate)
    for i in m.buf.indices {
        m.buf[i] *= gain
        if i > fadeFrom { m.buf[i] *= Float(max(0, 1 - Double(i - fadeFrom) / (1.2 * sampleRate))) }
    }
    return m.buf
}


/// The small copy GitHub plays inline (it takes uploads up to 10 MB): 1280×720 H.264 at a bitrate that brings the whole
/// video, with its 128 kb/s sound, to about 9.5 MB, capped at 1.6 Mb/s for short ones.
func write720p(from input: String, to output: String) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: input))
    let out = URL(fileURLWithPath: output); try? FileManager.default.removeItem(at: out)
    try? FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
    let seconds = asset.duration.seconds
    let bitrate = Int(min(1_600_000, 9_500_000 * 8 / seconds - 128_000))
    let reader = try! AVAssetReader(asset: asset)
    let vt = asset.tracks(withMediaType: .video)[0], at = asset.tracks(withMediaType: .audio)[0]
    let vOut = AVAssetReaderTrackOutput(track: vt, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
    let aOut = AVAssetReaderTrackOutput(track: at, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
    reader.add(vOut); reader.add(aOut)
    let writer = try! AVAssetWriter(outputURL: out, fileType: .mp4)
    let vIn = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1280, AVVideoHeightKey: 720,
        AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitrate, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel, AVVideoMaxKeyFrameIntervalKey: 90]])
    let aIn = AVAssetWriterInput(mediaType: .audio, outputSettings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 128000])
    writer.add(vIn); writer.add(aIn)
    reader.startReading(); writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let group = DispatchGroup()
    for (input, output, q) in [(vIn, vOut, DispatchQueue(label: "video")), (aIn, aOut, DispatchQueue(label: "audio"))] {
        group.enter()
        input.requestMediaDataWhenReady(on: q) {
            while input.isReadyForMoreMediaData {
                if let sample = output.copyNextSampleBuffer() { input.append(sample) } else { input.markAsFinished(); group.leave(); return }
            }
        }
    }
    group.wait()
    let done = DispatchSemaphore(value: 0); writer.finishWriting { done.signal() }; done.wait()
    if writer.status != .completed { print("720p failed: \(String(describing: writer.error))"); exit(1) }
    let size = (try? FileManager.default.attributesOfItem(atPath: output)[.size] as? Int) ?? 0
    print(String(format: "wrote %@ (%.1f MB at %d kb/s)", output, Double(size) / 1_000_000, bitrate / 1000))
}

/// Puts the soundtrack under the silent video: WAV → AAC with afconvert, then a passthrough export.
func mux(video: String, audio: String, to out: String) {
    let m4a = audio.replacingOccurrences(of: ".wav", with: ".m4a")
    try? FileManager.default.removeItem(atPath: m4a)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
    p.arguments = ["-f", "m4af", "-d", "aac", "-b", "192000", audio, m4a]
    try! p.run(); p.waitUntilExit()

    let comp = AVMutableComposition()
    let v = AVURLAsset(url: URL(fileURLWithPath: video)), a = AVURLAsset(url: URL(fileURLWithPath: m4a))
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))
    let vt = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
    try! vt.insertTimeRange(range, of: v.tracks(withMediaType: .video)[0], at: .zero)
    let at = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
    let aRange = CMTimeRange(start: .zero, duration: min(range.duration, a.duration))
    try! at.insertTimeRange(aRange, of: a.tracks(withMediaType: .audio)[0], at: .zero)
    try? FileManager.default.removeItem(atPath: out)
    let ex = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough)!
    ex.outputURL = URL(fileURLWithPath: out); ex.outputFileType = .mp4
    let done = DispatchSemaphore(value: 0)
    ex.exportAsynchronously { done.signal() }
    done.wait()
    if ex.status != .completed { print("mux failed: \(String(describing: ex.error))"); exit(1) }
    print("wrote \(out)")
}


/// Encodes every frame straight into an H.264 MP4 with AVAssetWriter (no ffmpeg needed).
func writeVideo(to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)
    let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 16_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
    ])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: W,
        kCVPixelBufferHeightKey as String: H,
    ])
    writer.add(input)
    writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let n = Int(duration * fps)
    for f in 0..<n {
        autoreleasepool {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
            var pb: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
            let buf = pb!
            CVPixelBufferLockBaseAddress(buf, [])
            let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: W, height: H, bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buf), space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
            ctx.draw(frame(Double(f) / fps).cgImage!, in: CGRect(x: 0, y: 0, width: W, height: H))
            CVPixelBufferUnlockBaseAddress(buf, [])
            adaptor.append(buf, withPresentationTime: CMTime(value: CMTimeValue(f), timescale: CMTimeScale(fps)))
        }
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    if writer.status != .completed { print("video failed: \(String(describing: writer.error))"); exit(1) }
    print("wrote \(path)")
}


// MARK: Main

let args = CommandLine.arguments
let cmd = args.count > 1 ? args[1] : "storyboard"
let out = args.count > 2 ? args[2] : "promo"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
let base = ["promo": "clawd-clash-promo", "bloopers": "clawd-clash-bloopers", "full": "clawd-clash-full", "starclawds": "star-clawds-promo", "marvelous": "marvelous-clawds-promo", "detective": "detective-clawds-promo"][reel] ?? "clawd-clash-promo"

switch cmd {
case "video":
    let tmp = NSTemporaryDirectory()
    writeVideo(to: tmp + "\(base)-silent.mp4")
    writeWAV(soundtrack(), to: tmp + "\(base).wav")
    mux(video: tmp + "\(base)-silent.mp4", audio: tmp + "\(base).wav", to: "\(out)/\(base).mp4")
case "check":                                                   // render every frame once, saying where it got to
    for f in 0..<Int(duration * fps) {
        let t = Double(f) / fps
        FileHandle.standardError.write("\(t)\n".data(using: .utf8)!)
        autoreleasepool { _ = frame(t) }
    }
    print("all \(Int(duration * fps)) frames render")
case "720p":                                                    // the GitHub-sized copy of a reel already rendered
    let small = ["promo": "Trailer", "bloopers": "Bloopers", "full": "Clawd-Clash", "starclawds": "Star-Clawds",
                 "marvelous": "Marvelous-Clawds", "detective": "Detective-Clawds"][reel] ?? "Trailer"
    write720p(from: "\(out)/\(base).mp4", to: "\(out)/720p/\(small).mp4")
case "audio":
    writeWAV(soundtrack(), to: "\(out)/\(base).wav"); print("wrote \(out)/\(base).wav")
case "frame":
    let t = Double(args[3]) ?? 0
    save(frame(t), "\(out)/t\(args[3]).png"); print("wrote \(out)/t\(args[3]).png")
default:
    if reel == "bloopers" { save(storyboard("CLAWD CLASH: BLOOPERS", blooperBeats), "\(out)/storyboard-bloopers.png") }
    else if reel == "starclawds" { save(storyboard("STAR CLAWDS", starClawdsBeats), "\(out)/storyboard-star-clawds.png") }
    else if reel == "marvelous" { save(storyboard("MARVELOUS CLAWDS", marvelousBeats), "\(out)/storyboard-marvelous-clawds.png") }
    else if reel == "detective" { save(storyboard("DETECTIVE CLAWDS", detectiveBeats), "\(out)/storyboard-detective-clawds.png") }
    else { save(storyboard("CLAWD CLASH", promoBeats), "\(out)/storyboard-promo.png") }
    print("wrote the \(reel) storyboard to \(out)")
}
