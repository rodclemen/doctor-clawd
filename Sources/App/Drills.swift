import Foundation

// Solo practice: a Claude that's working with nobody to fight doesn't just fire straight ahead (at whoever happens to be
// standing there, asleep). It works through sets of 7–10 s each, picked at random from what it can do: its kata or a
// flourish, shots and spells into the sky, fiddling with its gun, a portal that sometimes fizzles, stretches, squats,
// hovering cross-legged in meditation, or its own signature move. Stateless (picked from the clock), so the screen
// saver plays the same sets.

enum Drill: CaseIterable {
    case kata          // melee: its practice kata (Characters.swift)
    case flourish      // melee: the weapon swung up, round and back down, again and again
    case checkWeapon   // a gun in the hand: raised, looked over, smoke blown off
    case skyShots      // ranged: shots up into the sky
    case crackle       // magic: flickering between the fingers
    case skyCast       // magic: a stream up into the sky that now and then sputters out
    case portal        // sorcery: a ring of sparks opened in the air, which sometimes fizzles
    case meditate      // Jedi, Sith and mystics: sat cross-legged, floating off the ground
    case squats        // down onto its haunches and back up
    case stretch       // leaning slowly over to one side, then the other
    case hops          // those that can't sit: hopping on the spot
    case signature     // its own move, over and over
    case bespoke       // something only it does (`Cast.bespokeDrills`)

    /// Feet on the ground: a flyer doesn't take off on a sortie in the middle of it.
    var grounded: Bool {
        switch self { case .meditate, .squats, .stretch, .hops, .bespoke: return true; default: return false }
    }
}

/// The set being played right now, `e` seconds into it.
struct DrillPlay {
    let kind: Drill
    let e: Double
    let length: Double
    /// Which set this is, so each one can play out its own way (which portals fizzle…).
    let seed: Int
}

/// Set while a solo character is drawn, like `idleHabit`.
var soloDrill: DrillPlay?

/// Set while a drill draws its character: changes to the pose (a hammer held up, legs running…), made after the
/// usual ones.
var drillPose: ((inout Pose) -> Void)?

/// Previews: practise this instead of the scheduled set.
var forcedDrill: DrillPlay?

extension Cast {
    /// Force users in Star Wars (Jedi and Sith alike), sorcerers and other mystics elsewhere.
    private var meditates: Bool {
        guard persona.canSit else { return false }
        return weapon == .lightning || (universe == .starWars && weapon == .saber)
    }

    /// What this character practises, with its favourites in more than once.
    var drills: [Drill] {
        let p = persona
        var list: [Drill] = []
        switch weapon {
        case .saber: list += [.kata, .kata, .flourish]
        case .blaster: list += [.skyShots, .skyShots] + (p.handGun ? [.checkWeapon] : [])
        case .lightning: list += [.skyCast, .crackle] + (p.magic.jagged ? [] : [.portal, .portal])
        case .none: break
        }
        if hasSignature { list += [.signature, .signature] }
        if p.fidgets {
            list += p.canSit ? [.squats, .stretch] : [.hops, .stretch]
        }
        if meditates { list += [.meditate, .meditate] }
        if Self.bespokeDrills[self] != nil { list += [.bespoke, .bespoke, .bespoke] }
        return list
    }

    /// The set playing at `t`: back to back while it works, a different one from the last each time.
    func drill(at t: Double) -> DrillPlay? {
        if let forced = forcedDrill { return forced }
        let list = drills
        guard !list.isEmpty else { return nil }
        let lt = t + Double(id) * 4.3
        let period = 7 + 3 * noise(id * 13 + 5)
        let cycle = Int(floor(lt / period))
        func pick(_ n: Int) -> Drill { list[min(list.count - 1, Int(noise(n * 37 + id * 11) * Double(list.count)))] }
        var kind = pick(cycle)
        if list.count > 1, Set(list).count > 1, kind == pick(cycle - 1) {
            kind = list.first { $0 != kind } ?? kind
        }
        return DrillPlay(kind: kind, e: lt - Double(cycle) * period, length: period, seed: cycle &* 7919 &+ id)
    }

    /// Draw it practising `d`. Idle habits it already has (a flourish, its signature) play on a loop as if it were
    /// idle; the rest are drawn here.
    func drawDrill(_ c: PixelCanvas, _ d: DrillPlay, t: Double) {
        soloDrill = d
        defer { soloDrill = nil; idleHabit = nil }
        let ramp = min(1, d.e / 0.8, (d.length - d.e) / 0.8)   // easing in and out of a set
        switch d.kind {
        case .bespoke:
            Self.bespokeDrills[self]?(c, self, d, t)
        case .kata, .skyShots, .skyCast, .portal:
            drawPersona(c, self, t: t, mode: .working, walking: false, role: .none)
        case .flourish, .checkWeapon, .crackle, .signature:
            let kind: IdleHabit = d.kind == .flourish ? .flourish : d.kind == .checkWeapon ? .checkWeapon
                : d.kind == .crackle ? .crackle : .signature
            let length = kind == .signature ? signatureLength ?? kind.length : kind.length
            let e = d.e.truncatingRemainder(dividingBy: length + 0.7)
            let play = e < length ? HabitPlay(kind: kind, e: e, length: length) : nil
            idleHabit = play
            drawPersona(c, self, t: t, mode: .idle, walking: false, role: .none)
            if let play { applyHabitTransform(c, play) }
        case .squats:
            let down = d.e > 0.4 && d.e < d.length - 0.4 && frac(d.e / 1.3) > 0.5
            drawPersona(c, self, t: t, mode: .idle, walking: false, role: .none, sitting: down)
        case .hops:
            drawPersona(c, self, t: t, mode: .idle, walking: false, role: .none)
            c.shift(dx: 0, dy: -Int((3 * abs(sin(d.e * .pi / 0.55)) * ramp).rounded()))
        case .meditate:
            let rise = 6 * (0.5 - 0.5 * cos(.pi * max(0, ramp)))
            let lift = Int((rise + (ramp >= 1 ? sin(d.e * 1.8) : 0)).rounded())
            c.baseY = -lift
            drawPersona(c, self, t: t, mode: .idle, walking: false, role: .none, sitting: true)
            if ramp > 0.3 { drawMeditationMotes(c, t: t, lift: lift) }
        case .stretch:
            // Drawn standing, then everything above the hips leant over, forward then back; the feet stay put.
            let body = PixelCanvas(c.w, c.h)
            drawPersona(body, self, t: t, mode: .idle, walking: false, role: .none)
            let hips = 37
            c.paste(body.onlyRows(hips..<c.h))
            let upper = body.onlyRows(0..<hips)
            let lean = sin(d.e * 2 * .pi / 3.2)
            let angle = 11 * (abs(lean) > 0.8 ? (lean > 0 ? 1 : -1) : lean / 0.8) * max(0, ramp)
            let waist = (Sprite.bodyCenterX, Double(hips))
            c.paste(upper.rotated(angle, about: waist, into: c.w, c.h, at: waist))
        }
    }

    /// Bits of rock (Star Wars) or motes of its magic floating round someone meditating, `lift` pixels up.
    private func drawMeditationMotes(_ c: PixelCanvas, t: Double, lift: Int) {
        let (ox, oy, by) = (c.ox, c.oy, c.baseY)
        c.ox = 0; c.oy = 0; c.baseY = 0
        defer { c.ox = ox; c.oy = oy; c.baseY = by }
        let rock = universe == .starWars
        for k in 0..<3 {
            let a = t * 0.9 + Double(k) * 2.1
            let x = Sprite.bodyCenterX + cos(a) * 17, y = 36 - Double(lift) + sin(a * 1.3) * 4 - Double(k)
            if rock {
                c.rect(Int(x), Int(y), k == 1 ? 2 : 1, 2, C(0x8A7E6E))
                c.px(Int(x), Int(y), C(0xB0A490))
            } else {
                let m = persona.magic
                c.px(Int(x), Int(y), (Int(t * 6) + k) % 3 == 0 ? m.core : m.glow.alpha(0.8))
            }
        }
    }
}

// MARK: - Effects for `drawPersona`

/// A shot fired up and away into the sky from the muzzle, every `period` on clock `t`.
func drawSkyShot(_ c: PixelCanvas, t: Double, period: Double, muzzle: (x: Double, y: Double), style: ShotStyle) {
    let f = frac(t / period)
    guard f < 0.4 else { return }
    let k = f / 0.4
    let from = (muzzle.x + 1, muzzle.y - 1)
    let head = (from.0 + k * 24, from.1 - k * 46)
    drawProjectile(c, style, from: from, head: head, t: t, alpha: k > 0.75 ? (1 - k) / 0.25 : 1)
}

/// Magic sent up into the sky from `hand` in bursts; one burst in three or so sputters out halfway with a pop of sparks.
func drawSkyCast(_ c: PixelCanvas, _ m: Magic, hand: (Double, Double), t: Double, seed: Int) -> Bool {
    let period = 1.7, burst = Int(floor(t / period)), f = frac(t / period)
    guard f < 0.6 else { return false }
    let fizzles = noise(seed &+ burst * 17) < 0.35
    let top = (hand.0 + 16, hand.1 - 30)
    if fizzles && f > 0.25 {
        // Sputtering: a short broken stub, then a few sparks.
        if f < 0.4, noise(Int(t * 30)) > 0.4 {
            drawMagic(c, m, from: hand, to: (hand.0 + 5, hand.1 - 9), t: t)
        }
        let s = (f - 0.25) / 0.35
        for i in 0..<4 {
            let a = -2.4 + Double(i) * 0.6 + noise(burst * 5 + i) * 0.4
            let r = 3 + s * 7
            c.px(Int(hand.0 + 5 + cos(a) * r), Int(hand.1 - 9 + sin(a) * r + s * 4), (i % 2 == 0 ? m.core : m.glow).alpha(1 - s))
        }
        return true
    }
    drawMagic(c, m, from: hand, to: top, t: t)
    return true
}

/// A sling-ring portal opened in the air in front: sparks spinning round a growing ring, held a moment and closed.
/// Some fizzle: the ring wobbles, breaks up and the sparks fall away.
func drawPortal(_ c: PixelCanvas, _ m: Magic, t: Double, seed: Int) -> Bool {
    let period = 3.6, n = Int(floor(t / period)), f = frac(t / period)
    guard f < 0.85 else { return false }
    let fizzles = noise(seed &+ n * 23) < 0.4
    let centre = (59.0, 29.0)
    let grow = min(1, f / 0.3)
    var r = 11 * (0.5 - 0.5 * cos(.pi * grow))
    var scatter = 0.0
    if fizzles, f > 0.45 {
        scatter = (f - 0.45) / 0.4
        r *= 1 + 0.2 * sin(t * 40) * (1 - scatter)
    } else if f > 0.7 {
        r *= 1 - (f - 0.7) / 0.15                  // closing
    }
    guard r > 0.5 else { return true }
    let sparks = 22
    for i in 0..<sparks {
        let a = Double(i) / Double(sparks) * 2 * .pi + t * 5
        var x = centre.0 + cos(a) * r * 0.55, y = centre.1 + sin(a) * r   // seen edge on: taller than it is wide
        if scatter > 0 {
            x += (noise(n * 31 + i) - 0.5) * 10 * scatter
            y += scatter * scatter * 14 + (noise(n * 13 + i) - 0.5) * 4 * scatter
        }
        let lit = noise(Int(t * 25) + i * 3) > 0.25
        guard lit || scatter > 0 else { continue }
        c.px(Int(x.rounded()), Int(y.rounded()), (i % 3 == 0 ? m.core : m.glow).alpha(scatter > 0 ? 1 - scatter : 1))
    }
    if scatter == 0, grow >= 1 {
        // The flicker of somewhere else inside.
        for i in 0..<3 {
            let y = centre.1 - r * 0.6 + noise(Int(t * 8) + i * 7) * r * 1.2
            c.px(Int(centre.0 + (noise(Int(t * 8) + i) - 0.5) * r * 0.5), Int(y), m.glow.alpha(0.45))
        }
    }
    return true
}

// MARK: - Bespoke drills

/// Draws one character's own drill: the canvas, who, the set, and the clock.
typealias BespokeDrill = (PixelCanvas, Cast, DrillPlay, Double) -> Void

/// Drawn standing about as it would idle, with `pose` changes on top.
private func standing(_ c: PixelCanvas, _ who: Cast, t: Double, pose: ((inout Pose) -> Void)? = nil) {
    drillPose = pose
    drawPersona(c, who, t: t, mode: .idle, walking: false, role: .none)
    drillPose = nil
}

/// A smooth 0→1 over the first `rise` seconds of a set and back to 0 over its last ones.
private func setRamp(_ d: DrillPlay, rise: Double = 0.8) -> Double {
    let k = max(0, min(1, d.e / rise, (d.length - d.e) / rise))
    return 0.5 - 0.5 * cos(k * .pi)
}

extension Cast {
    /// A few characters' own drills, where one says something about them better than the general ones.
    static let bespokeDrills: [Cast: BespokeDrill] = [
        // Yodle: a little cairn of stones lifted off the ground with the Force, turning slowly.
        .hero(SWHero.yoda): { c, who, d, t in
            standing(c, who, t: t)
            drawLiftedStones(c, d: d, t: t)
        },
        // Darth Vapor: an Imperial crate held up in the air, shaking with the strain.
        .villain(SWVillain.vader): { c, who, d, t in
            standing(c, who, t: t)
            let lift = 11 * setRamp(d, rise: 1.2)
            let shake = lift > 8 ? (noise(Int(t * 24)) > 0.5 ? 1 : 0) : 0
            let x = 53 + shake, y = Int((38 - lift).rounded())
            c.rect(x, y, 9, 7, C(0x4A4E58))
            c.rect(x, y, 9, 1, C(0x7A808C)); c.rect(x, y + 3, 9, 1, C(0x30333A))
            c.rect(x + 1, y + 1, 2, 2, C(0xC8A030)); c.rect(x + 6, y + 4, 2, 2, C(0x9AA0AC))
            if lift < 3 { c.rect(x - 1, 44, 11, 1, C(0x8A7E6E, 0.6)) }
        },
        // Spider-Clawd: a web yo-yo, down to the ground and back up into the hand.
        .hero(MarvelHero.spiderMan): { c, who, d, t in
            standing(c, who, t: t)
            let hand = (who.muzzle.x + 1, who.muzzle.y)
            let k = 0.5 - 0.5 * cos(d.e * 2 * .pi / 1.2)
            let end = (hand.0 + 4, hand.1 + 2 + 7 * k * setRamp(d))
            c.glowLine(hand.0, hand.1, end.0, end.1, core: C(0xF4F4F8, 0.9), glow: C(0xFFFFFF, 0), coreR: 0.35, glowR: 0.4)
            c.rect(Int(end.0) - 1, Int(end.1), 3, 3, C(0xF4F4F8))
            c.px(Int(end.0), Int(end.1) + 1, C(0xB8BCC8))
        },
        // Hawk-I: target practice at a straw boss on a stand, the arrows staying in it.
        .hero(MarvelHero.hawkeye): { c, who, d, t in
            let period = 1.6
            standing(c, who, t: t) { $0.fire = (d.e, false); $0.firePeriod = period }
            let tx = 64
            c.rect(tx + 2, 36, 1, 8, C(0x6A4A2A)); c.rect(tx + 4, 36, 1, 8, C(0x6A4A2A))      // the stand
            c.rect(tx, 25, 7, 13, C(0xE8DCC0))
            c.rect(tx + 1, 27, 5, 9, C(0xD83A2A)); c.rect(tx + 2, 29, 3, 5, C(0xE8DCC0)); c.rect(tx + 3, 30, 1, 3, C(0xD83A2A))
            let shots = Int(d.e / period), f = frac(d.e / period)
            for n in 0..<min(4, shots) {
                let y = 28 + Int(noise(d.seed &+ n * 7) * 7)
                for k in 1...4 { c.px(tx - k, y, k == 4 ? C(0xC83A2A) : C(0x6A4A2A)) }
            }
            if f < 0.3, shots < 4 {
                let y = 28 + noise(d.seed &+ shots * 7) * 7
                let from = (who.muzzle.x + 2, who.muzzle.y)
                let k = f / 0.3
                drawProjectile(c, .arrow, from: from, head: (from.0 + k * (Double(tx) - from.0), from.1 + k * (y - from.1)), t: t)
            }
        },
        // The Flare: running on the spot, very, very fast.
        .hero(DCHero.flash): { c, who, d, t in
            let r = setRamp(d)
            standing(c, who, t: t) { p in
                if r > 0.2 { p.step = Int(t * 16) % 2; p.breathe = 0; p.dx = Int(t * 16) % 2 }
            }
            guard r > 0.5 else { return }
            for i in 0..<4 {
                let y = 24 + Int(noise(Int(t * 12) + i * 5) * 18), len = 4 + Int(noise(Int(t * 12) + i) * 7)
                c.rect(15 - len - Int(noise(i * 3 + Int(t * 12)) * 4), y, len, 1, (i % 2 == 0 ? C(0xFFD21E) : C(0xFF3A2A)).alpha(0.8))
            }
            if noise(Int(t * 20)) > 0.6 {
                let x = 18 + Int(noise(Int(t * 20) + 3) * 20), y = 22 + Int(noise(Int(t * 20) + 5) * 20)
                c.px(x, y, C(0xFFF4A0)); c.px(x + 1, y - 1, C(0xFFD21E)); c.px(x + 2, y, C(0xFFF4A0))
            }
        },
        // Wondrous Woman: the golden lasso twirled in a loop over her head.
        .hero(DCHero.wonderWoman): { c, who, d, t in
            standing(c, who, t: t)
            let r = setRamp(d)
            guard r > 0.1 else { return }
            let hand = Sprite.hand, centre = (Sprite.bodyCenterX + 4, 13.0), spin = t * 10
            let near = (centre.0 + cos(spin) * 11 * r, centre.1 + sin(spin) * 3 * r)
            c.glowLine(hand.x, hand.y - 1, near.0, near.1, core: C(0xFFD24A), glow: C(0xFFB000, 0.3), coreR: 0.4, glowR: 1)
            for i in 0..<18 {
                let a = Double(i) / 18 * 2 * .pi + spin
                c.px(Int((centre.0 + cos(a) * 11 * r).rounded()), Int((centre.1 + sin(a) * 3 * r).rounded()),
                     i % 3 == 0 ? C(0xFFF0A0) : C(0xFFC21E))
            }
        },
        // Green Lamplighter: willpower made solid, a glowing box, then a spring, then gone.
        .hero(DCHero.greenLantern): { c, who, d, t in
            standing(c, who, t: t) { $0.armRaise = 3 }
            let period = 2.8, n = Int(d.e / period), f = frac(d.e / period)
            guard f < 0.8 else { return }
            let grow = min(1, f / 0.25), fade = f > 0.65 ? (0.8 - f) / 0.15 : 1
            let core = C(0xB8FFB0).alpha(fade), glow = C(0x3AE84A).alpha(0.8 * fade)
            let hand = (Sprite.hand.x, Sprite.hand.y - 3)
            c.glowLine(hand.0, hand.1, hand.0 + 8 * grow, hand.1, core: core, glow: glow, coreR: 0.3, glowR: 1)
            if n % 2 == 0 {
                let s = Int(10 * grow), x = 52, y = 44 - s
                c.rect(x, y, s, 1, core); c.rect(x, 43, s, 1, core); c.rect(x, y, 1, s, core); c.rect(x + s - 1, y, 1, s, core)
                if s > 2 { c.rect(x + 1, y + 1, s - 2, s - 2, glow.alpha(0.25 * fade)) }
            } else {
                for i in 0..<5 {
                    let y = 43 - Double(i) * 3 * grow
                    c.glowLine(52, y, 60, y - 1.5 * grow, core: core, glow: glow, coreR: 0.4, glowR: 1)
                }
                c.rect(51, Int(43 - 15 * grow), 10, 2, core)
            }
        },
        // Thanoz: the gems glowing one by one round the gauntlet, then the snap.
        .villain(MarvelVillain.thanos): { c, who, d, t in
            standing(c, who, t: t) { $0.armRaise = 3 }
            let period = 3.2, f = frac(d.e / period)
            let hand = (who.weaponPivot.x, who.weaponPivot.y - 3)
            let gems = [C(0xFFE04A), C(0xFF3A3A), C(0x4A8AFF), C(0xB04AFF), C(0x3AE87A), C(0xFF9A2A)]
            if f < 0.7 {
                for (i, g) in gems.enumerated() where f > Double(i) * 0.1 {
                    let a = Double(i) / 6 * 2 * .pi + t * 2
                    c.rect(Int((hand.0 + cos(a) * 6).rounded()), Int((hand.1 + sin(a) * 6).rounded()), 2, 2, g)
                }
            } else if f < 0.78 {
                let r = (f - 0.7) / 0.08 * 10
                for i in 0..<16 {
                    let a = Double(i) / 16 * 2 * .pi
                    c.px(Int(hand.0 + cos(a) * r), Int(hand.1 + sin(a) * r), white)
                    c.px(Int(hand.0 + cos(a) * r * 0.6), Int(hand.1 + sin(a) * r * 0.6), C(0xF4E0FF, 0.7))
                }
            } else {
                let k = (f - 0.78) / 0.22
                for i in 0..<8 {
                    let x = hand.0 + 2 + k * 14 + noise(i * 3) * 4, y = hand.1 - 2 - k * 6 + noise(i * 5) * 6
                    c.px(Int(x), Int(y), C(0x8A7A6A).alpha(1 - k))
                }
            }
        },
        // Lokee: an illusion of himself beside him, flickering in and out.
        .villain(MarvelVillain.loki): { c, who, d, t in
            let period = 2.6, f = frac(d.e / period)
            if f > 0.15, f < 0.85, setRamp(d) > 0.9, noise(Int(t * 14)) > 0.12 {
                let ghost = PixelCanvas(c.w, c.h)
                standing(ghost, who, t: t + 0.9)
                c.paste(ghost, x: 17, alpha: 0.4)
                for i in 0..<3 {
                    let y = 20 + Int(noise(Int(t * 10) + i) * 24)
                    c.px(17 + 20 + Int(noise(Int(t * 10) + i * 4) * 20), y, C(0x3AD06A, 0.7))
                }
            }
            standing(c, who, t: t)
        },
        // The Bulk: leaps a little and smashes the ground, dust and cracks flying.
        .hero(MarvelHero.hulk): { c, who, d, t in
            let period = 2.2, f = frac(d.e / period)
            standing(c, who, t: t) { p in if f > 0.45, f < 0.6 { p.melee = 40 } }
            guard setRamp(d) > 0.9 else { return }
            if f > 0.2, f < 0.45 { c.shift(dx: 0, dy: -Int((sin((f - 0.2) / 0.25 * .pi) * 5).rounded())) }
            if f > 0.45, f < 0.55 { c.shift(dx: noise(Int(t * 30)) > 0.5 ? 1 : -1, dy: 0) }
            if f > 0.45 {
                let k = (f - 0.45) / 0.55
                for i in 0..<6 {
                    let side = i % 2 == 0 ? 1.0 : -1.0
                    let x = Sprite.bodyCenterX + side * (12 + k * 14 + Double(i) * 1.5), y = 43 - k * 5 - Double(i % 3)
                    c.rect(Int(x), Int(y), 3, 2, C(0xA89880).alpha(0.8 * (1 - k)))
                }
                let crack = C(0x2A2420).alpha(1 - k)
                c.px(44, 44, crack); c.px(45, 45, crack); c.px(47, 45, crack); c.px(48, 44, crack); c.px(12, 45, crack); c.px(14, 44, crack)
            }
        },
        // Iron Clawd: testing the boot thrusters, wobbling a few pixels off the ground.
        .hero(MarvelHero.ironMan): { c, who, d, t in
            standing(c, who, t: t)
            let r = setRamp(d)
            let lift = Int((r * (4 + 2 * sin(d.e * 2.3))).rounded())
            let wobble = r > 0.8 && sin(d.e * 5.3) > 0.85 ? (sin(d.e * 11) > 0 ? 1 : -1) : 0
            c.shift(dx: wobble, dy: -lift)
            guard r > 0.15 else { return }
            for x in [20, 33] {
                let len = 2 + Int(noise(Int(t * 30) + x) * 3) + lift / 2
                let top = 44 - lift
                c.rect(x + wobble, top, 3, len, C(0x6FD8FF, 0.7))
                c.rect(x + 1 + wobble, top, 1, max(1, len - 1), C(0xF4FCFF))
            }
        },
        // Ahh2-De2: playing a hologram message, a little flickering blue figure in a beam of light.
        .hero(SWHero.r2d2): { c, who, d, t in
            standing(c, who, t: t)
            let r = setRamp(d, rise: 0.5)
            guard r > 0.5, noise(Int(t * 16)) > 0.1 else { return }
            let beam = C(0x7FC8FF, 0.18), fig = C(0x8AD0FF, 0.55), lit = C(0xCFEFFF, 0.7)
            let proj = (38.0, 21.0)
            c.glowLine(proj.0, proj.1, 51, 41, core: beam, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
            c.glowLine(proj.0, proj.1, 59, 41, core: beam, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
            // A small robed figure, every other row missing.
            let jitter = noise(Int(t * 8)) > 0.85 ? 1 : 0
            for y in stride(from: 26 + Int(t * 10) % 2, through: 41, by: 2) {
                let w = y < 30 ? 3 : (y < 33 ? 5 : 4 + (y - 33) / 3)
                c.rect(55 - w / 2 + jitter, y, w, 1, y < 30 ? lit : fig)
            }
            c.px(53 + jitter, 27, fig); c.px(57 + jitter, 27, fig)           // the buns
        },
    ]
}

/// Three stones, biggest at the bottom, lifted together and turning, for Yodle.
private func drawLiftedStones(_ c: PixelCanvas, d: DrillPlay, t: Double) {
    let lift = 12 * setRamp(d, rise: 1.4)
    let stones: [(w: Int, h: Int, off: Double)] = [(7, 4, 0), (5, 3, 1.2), (3, 3, 2.1)]
    var y = 44 - lift
    for (i, s) in stones.enumerated() {
        let bob = lift > 6 ? sin(t * 2.2 + s.off) * 1.2 : 0
        let x = 55 + Int((sin(t * 1.4 + s.off) * Double(i) * 0.8).rounded()) - s.w / 2
        let top = Int((y - Double(s.h) + bob).rounded())
        c.rect(x, top, s.w, s.h, C(0x7A6E5E))
        c.rect(x, top, s.w, 1, C(0xA89A84)); c.rect(x + s.w - 1, top, 1, s.h, C(0x5A5044))
        y -= Double(s.h) + (lift > 6 ? 1.5 : 0)
    }
    if lift > 2 {
        for k in 0..<2 { c.px(52 + k * 6 + Int(noise(Int(t * 6) + k) * 2), 43 - Int(noise(Int(t * 6) + k + 4) * 3), C(0xA89A84, 0.6)) }
    }
}
