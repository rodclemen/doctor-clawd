import Foundation

// The Star Wars universe (Clawd Wars' cast): 46 villains, 35 heroes and 22 places. Any character can lead a session
// (drawn large) or be an agent (small). Each is a `Persona` registered in one of the Art/*.swift files next to its
// drawing code; who lives where, Han and Greedo, and the Falcon are decided here, in `starWarsTheme`.
//
// Ids are Clawd Wars' own (`Universe.starWars.base` is 0): villains `SWVillain.rawValue`, heroes 100 + `SWHero.rawValue`.
// Only ever append cases, so running sessions keep their characters across an update.

enum SWVillain: Int, CaseIterable {
    case vader, kylo, maul, boba, trooper, emperor, rogr, dooku, gamorrean, jabba, ig88, atst, atat, rancor, greedo, royalGuard
    case sebulba, salacious, grievous, tusken, cadBane, thrawn, hammerhead, mse6, baylan, shinHati, id9, grandInquisitor, secondSister, bantha, bibFortuna
    case watto, moffGideon, deathTrooper, scoutTrooper, ventress, savageOpress, jangoFett, bossk, dengar, droideka, phasma, krennic, tarkin, fifthBrother, reva

    var persona: Persona { starWarsVillainPersonas[self] ?? Persona.missing(String(describing: self)) }
}

enum SWHero: Int, CaseIterable {
    case luke, han, leia, obiwan, r2d2, c3po, quigon, mace, yoda, jawa, chewie, rey, ahsoka, ewok, tauntaun
    case jarjar, lando, zorii, boKatan, maz, wedge, l337, monMothma, padme, ackbar
    case grogu, babuFrik, mando, k2so, gonk, cassian, bix, cobbVanth, pitDroid, kuiil
    case hem   // always last (`Universe.hem`)

    var persona: Persona { starWarsHeroPersonas[self] ?? Persona.missing(String(describing: self)) }
}

let starWarsVillainPersonas: [SWVillain: Persona] = starWarsVillains1.merging(starWarsVillains2) { a, _ in a }
    .merging(starWarsVillains3) { a, _ in a }
let starWarsHeroPersonas: [SWHero: Persona] = starWarsHeroes1.merging(starWarsHeroes2) { a, _ in a }
    .merging(starWarsHeroes3) { a, _ in a }.merging([.hem: hemPersona(.starWars)]) { a, _ in a }

// MARK: - Homes

extension Location {
    static func starWarsHome(of leader: SWVillain) -> Location {
        switch leader {
        case .vader, .mse6, .deathTrooper, .krennic, .tarkin: return .deathStar
        case .boba: return .sarlaccPit
        case .jabba, .gamorrean, .salacious, .bibFortuna: return .jabbasPalace
        case .trooper, .greedo, .cadBane, .hammerhead: return .cantina
        case .kylo, .phasma: return .supremacy
        case .maul, .savageOpress, .droideka: return .theed
        case .emperor, .royalGuard: return .emperorThrone
        case .dooku, .grievous, .ventress, .jangoFett: return .geonosis
        case .rogr: return .naboo
        case .ig88, .thrawn, .secondSister, .moffGideon, .bossk, .dengar: return .executor
        case .atst, .scoutTrooper: return .endor
        case .atat: return .hoth
        case .rancor: return .rancorPit
        case .sebulba, .tusken, .grandInquisitor, .bantha, .watto, .fifthBrother: return .tuskenDesert
        case .baylan, .shinHati: return .jakku
        case .id9: return .obiWanHut
        case .reva: return .larsFarm
        }
    }

    static func starWarsHome(of hero: SWHero) -> Location {
        switch hero {
        case .luke: return .larsFarm
        case .obiwan: return .obiWanHut
        case .jawa, .r2d2, .babuFrik, .gonk, .bix, .pitDroid: return .sandcrawler
        case .yoda, .grogu: return .dagobah
        case .han, .chewie, .lando, .l337: return .falcon
        case .leia, .c3po, .monMothma, .hem: return .tantive
        case .quigon, .mando, .cobbVanth: return .tuskenDesert
        case .rey, .zorii, .kuiil: return .jakku
        case .mace, .ahsoka: return .jediCouncil
        case .ewok, .ackbar: return .endor
        case .tauntaun, .wedge: return .hoth
        case .jarjar: return .naboo
        case .padme: return .theed
        case .boKatan: return .geonosis
        case .maz: return .cantina
        case .k2so, .cassian: return .executor
        }
    }
}

// MARK: - The theme

extension Cast {
    static func hero(_ h: SWHero) -> Cast { Cast(universe: .starWars, isDark: false, index: h.rawValue) }
    static func villain(_ v: SWVillain) -> Cast { Cast(universe: .starWars, isDark: true, index: v.rawValue) }

    /// Han Solo and Greedo: they face off first, and now and then Han shoots first (`ShootsFirst`).
    var isHan: Bool { self == .hero(SWHero.han) }
    var isGreedo: Bool { self == .villain(SWVillain.greedo) }
}

let starWarsTheme = Theme(
    universe: .starWars,
    villains: SWVillain.allCases.map(\.persona),
    heroes: SWHero.allCases.map(\.persona),
    places: [.cantina, .deathStar, .sarlaccPit, .jabbasPalace, .supremacy, .theed, .emperorThrone, .geonosis, .naboo, .executor, .larsFarm, .obiWanHut, .sandcrawler, .dagobah, .falcon, .tantive, .tuskenDesert, .jakku, .jediCouncil, .endor, .hoth, .rancorPit],
    home: { c in
        c.isDark ? .starWarsHome(of: SWVillain(rawValue: c.index) ?? .vader) : .starWarsHome(of: SWHero(rawValue: c.index) ?? .luke)
    },
    nemeses: [(.hero(SWHero.han), .villain(SWVillain.greedo))],
    ride: { c in c.isHan ? .falcon : nil },
    menuIcon: drawVaderHelmetIcon,
    legend: .villain(SWVillain.vader))

/// Vader's helmet for the menu bar, cut from his sprite (28×26 at (14, 13)). In colour it gets a white outline (the
/// black helmet would vanish on a dark menu bar); monochrome keeps only its dark pixels, so the face under the helmet
/// is cut out with its eyes left in, and macOS tints what's left to match the menu bar.
func drawVaderHelmetIcon(_ icon: PixelCanvas, mono: Bool) {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    Cast.villain(SWVillain.vader).draw(c, t: 0, mode: .idle, walking: false, role: .none, asSession: true)
    let b = c.buf
    for y in 0..<icon.h {
        for x in 0..<icon.w {
            let i = ((y + 13) * c.w + (x + 14)) * 4
            guard b[i + 3] > 0 else { continue }
            if mono {
                let luma = (Int(b[i]) * 3 + Int(b[i + 1]) * 6 + Int(b[i + 2])) / 10
                if luma < 60 { icon.px(x, y, Px(r: 0, g: 0, b: 0, a: b[i + 3])) }
            } else {
                icon.px(x, y, Px(r: b[i], g: b[i + 1], b: b[i + 2], a: b[i + 3]))
            }
        }
    }
}

// MARK: - Places

extension Location {
    static let cantina = Location("cantina")
    static let deathStar = Location("deathStar")
    static let sarlaccPit = Location("sarlaccPit")
    static let jabbasPalace = Location("jabbasPalace")
    static let supremacy = Location("supremacy")
    static let theed = Location("theed")
    static let emperorThrone = Location("emperorThrone")
    static let geonosis = Location("geonosis")
    static let naboo = Location("naboo")
    static let executor = Location("executor")
    static let larsFarm = Location("larsFarm")
    static let obiWanHut = Location("obiWanHut")
    static let sandcrawler = Location("sandcrawler")
    static let dagobah = Location("dagobah")
    static let falcon = Location("falcon")
    static let tantive = Location("tantive")
    static let tuskenDesert = Location("tuskenDesert")
    static let jakku = Location("jakku")
    static let jediCouncil = Location("jediCouncil")
    static let endor = Location("endor")
    static let hoth = Location("hoth")
    static let rancorPit = Location("rancorPit")
}
