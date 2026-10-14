import Foundation

// Doctor Clawd: the time-travel universe. Doctors and their companions against the Master, the Dalicks and the rest. Any
// character can lead a session (drawn large) or be an agent (small). Who they are, how they fight and how they move is
// a `Persona`, registered in one of the Art/*.swift files next to its drawing code; who lives where, who fights whom
// first and who gets picked up is decided here, in `doctorTheme`.
//
// Ids are stored in the status file: `Universe.doctor.base` plus `DoctorVillain.rawValue` (< 100) or
// 100 + `DoctorHero.rawValue`. Only ever append cases (HEM stays last), so running sessions keep their characters
// across an update.

enum DoctorHero: Int, CaseIterable {
    // The Doctors
    case doctorTen
    case doctorOne, doctorTwo, doctorThree, doctorFour, doctorFive, doctorSix, doctorSeven, doctorEight, doctorNine
    case doctorEleven, doctorTwelve, doctorThirteen, doctorFourteen, doctorFifteen
    case warDoctor, fugitiveDoctor
    // Companions and allies
    case susan, ian, barbara, jamie, zoe, brigadier, jo, sarahJane, leelah, kCanine
    case romanah, nyssa, tegan, pery, mel, ace
    case rose, jack, martha, donna, wilf
    case amy, rory, river, clara, vasta, jenny, stracks
    case bill, nardoll, yaz, graham, ryan, dan
    case ruby, belinda, kate, osgoode
    case hem   // always last (`Universe.hem`)

    var persona: Persona { doctorHeroPersonas[self] ?? Persona.missing(String(describing: self)) }

    /// The Doctors themselves (the sonic screwdriver's owners, and who a regeneration moves between), in order.
    static let doctors: [DoctorHero] = [.doctorOne, .doctorTwo, .doctorThree, .doctorFour, .doctorFive, .doctorSix,
                                        .doctorSeven, .doctorEight, .doctorNine, .doctorTen, .doctorEleven,
                                        .doctorTwelve, .doctorThirteen, .doctorFourteen, .doctorFifteen]
    var isDoctor: Bool { DoctorHero.doctors.contains(self) || self == .warDoctor || self == .fugitiveDoctor }
}

enum DoctorVillain: Int, CaseIterable {
    case dalick
    // Time Lords and named villains
    case master, burntMaster, velvetMaster, snakeskinMaster, sexton, missy, spyMaster
    case davross, ranee, omegah, rascilon, toyfaker, sootekh, grateIntelligence, valeyarn
    // The monsters
    case supremeDalick, dalickEmperor, mondasianCyberperson, cyberperson, cyberController, sontaron
    case weepingAngle, silents, odd, zygone, silurean, seaDevvil, iceWarior, autom, judoom, slitheem, sycorex
    case vashtaNerado, emptyKid, clockworkDroid, candyman, cassandro, maestro
    // Agent-only small fry
    case adipoze, cybermite, toclafayne

    var persona: Persona { doctorVillainPersonas[self] ?? Persona.missing(String(describing: self)) }

    var isDalick: Bool { [.dalick, .supremeDalick, .dalickEmperor].contains(self) }
}

let doctorHeroPersonas: [DoctorHero: Persona] = [doctorHeroes1, doctorHeroes2, doctorHeroes3, doctorHeroes4, doctorHeroes5,
                                                 doctorHeroes6, doctorHeroes7]
    .reduce([.hem: hemPersona(.doctor)]) { $0.merging($1) { a, _ in a } }
let doctorVillainPersonas: [DoctorVillain: Persona] = [doctorVillains1, doctorVillains2, doctorVillains3, doctorVillains4,
                                                       doctorVillains5]
    .reduce([:]) { $0.merging($1) { a, _ in a } }

// MARK: - Homes

extension Location {
    static func doctorHome(of leader: DoctorVillain) -> Location {
        switch leader {
        case .dalick, .davross: return .skarro
        case .supremeDalick: return .dalickAsylum
        case .dalickEmperor: return .satelliteFive
        case .master, .missy, .spyMaster: return .unitHQ
        case .burntMaster, .velvetMaster, .snakeskinMaster, .rascilon, .omegah, .ranee: return .gallifray
        case .sexton, .toclafayne: return .powellEstate
        case .toyfaker, .maestro: return .christmasLondon
        case .sootekh, .valeyarn: return .trenzalore
        case .grateIntelligence: return .paternosterRow
        case .mondasianCyberperson, .cyberperson, .cyberController, .cybermite: return .telos
        case .sontaron, .judoom: return .unitHQ
        case .weepingAngle, .vashtaNerado: return .theLibrary
        case .silents: return .tottersYard
        case .odd: return .sanctuaryBase
        case .zygone, .autom: return .unitHQ
        case .silurean, .seaDevvil, .iceWarior: return .telos
        case .slitheem, .sycorex: return .christmasLondon
        case .emptyKid, .clockworkDroid: return .pompeii
        case .candyman: return .starshipUK
        case .cassandro, .adipoze: return .newEarth
        }
    }

    static func doctorHome(of hero: DoctorHero) -> Location {
        switch hero {
        case .doctorTen, .doctorFourteen, .hem: return .consoleRoom
        case .doctorOne, .doctorTwo, .susan, .ian, .barbara: return .tottersYard
        case .doctorThree, .brigadier, .jo, .kate, .osgoode: return .unitHQ
        case .doctorFour, .leelah, .kCanine, .romanah, .doctorEight, .doctorSix, .doctorFive, .nyssa, .tegan, .pery,
             .warDoctor, .fugitiveDoctor:
            return .gallifray
        case .doctorSeven, .mel, .ace, .jamie, .zoe: return .skarro
        case .martha, .wilf, .sarahJane: return .powellEstate
        case .doctorNine: return .satelliteFive
        case .rose: return .badWolfBay
        case .jack: return .roaldDollPlass
        case .doctorEleven, .river: return .trenzalore
        case .amy, .rory: return .starshipUK
        case .doctorTwelve, .bill, .nardoll: return .cafeArles
        case .clara: return .dalickAsylum
        case .vasta, .jenny, .stracks: return .paternosterRow
        case .doctorThirteen, .yaz, .graham, .ryan, .dan: return .sanctuaryBase
        case .donna: return .pompeii
        case .doctorFifteen, .ruby, .belinda: return .christmasLondon
        }
    }
}

// MARK: - The theme

extension Cast {
    static func hero(_ h: DoctorHero) -> Cast { Cast(universe: .doctor, isDark: false, index: h.rawValue) }
    static func villain(_ v: DoctorVillain) -> Cast { Cast(universe: .doctor, isDark: true, index: v.rawValue) }
}

/// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line.
private let doctorNemeses: [(DoctorHero, DoctorVillain)] = [
    (.doctorOne, .toyfaker), (.doctorTwo, .cyberController), (.doctorThree, .master), (.doctorFour, .davross),
    (.doctorFive, .burntMaster), (.doctorSix, .valeyarn), (.doctorSeven, .candyman), (.doctorEight, .snakeskinMaster),
    (.doctorNine, .autom), (.doctorTen, .sexton), (.doctorEleven, .silents), (.doctorTwelve, .missy),
    (.doctorThirteen, .spyMaster), (.doctorFourteen, .supremeDalick), (.doctorFifteen, .maestro),
    (.warDoctor, .dalickEmperor), (.rose, .dalickEmperor), (.amy, .weepingAngle), (.clara, .grateIntelligence),
    (.stracks, .sontaron), (.river, .vashtaNerado), (.martha, .sexton), (.brigadier, .cyberperson), (.kate, .zygone),
    (.ruby, .maestro), (.jack, .emptyKid),
]

let doctorTheme = Theme(
    universe: .doctor,
    villains: DoctorVillain.allCases.map(\.persona),
    heroes: DoctorHero.allCases.map(\.persona),
    places: [.consoleRoom, .gallifray, .skarro, .tottersYard, .powellEstate, .roaldDollPlass, .unitHQ, .paternosterRow,
             .trenzalore, .theLibrary, .satelliteFive, .newEarth, .starshipUK, .pompeii, .cafeArles, .badWolfBay,
             .telos, .dalickAsylum, .sanctuaryBase, .christmasLondon],
    home: { c in
        c.isDark ? .doctorHome(of: DoctorVillain(rawValue: c.index) ?? .dalick)
                 : .doctorHome(of: DoctorHero(rawValue: c.index) ?? .doctorTen)
    },
    nemeses: doctorNemeses.map { (.hero($0.0), .villain($0.1)) },
    ride: { c in
        // The TARDIS materialises for the Doctors and their companions (all the heroes but HEM).
        guard c.universe == .doctor, !c.isDark, let h = DoctorHero(rawValue: c.index), h != .hem else { return nil }
        return .tardis
    },
    menuIcon: drawPoliceBoxIcon,
    legend: .hero(.doctorTen))

// MARK: - Places

extension Location {
    static let consoleRoom = Location("consoleRoom")
    static let gallifray = Location("gallifray")
    static let skarro = Location("skarro")
    static let tottersYard = Location("tottersYard")
    static let powellEstate = Location("powellEstate")
    static let roaldDollPlass = Location("roaldDollPlass")
    static let unitHQ = Location("unitHQ")
    static let paternosterRow = Location("paternosterRow")
    static let trenzalore = Location("trenzalore")
    static let theLibrary = Location("theLibrary")
    static let satelliteFive = Location("satelliteFive")
    static let newEarth = Location("newEarth")
    static let starshipUK = Location("starshipUK")
    static let pompeii = Location("pompeii")
    static let cafeArles = Location("cafeArles")
    static let badWolfBay = Location("badWolfBay")
    static let telos = Location("telos")
    static let dalickAsylum = Location("dalickAsylum")
    static let sanctuaryBase = Location("sanctuaryBase")
    static let christmasLondon = Location("christmasLondon")
}

/// Every Doctor Clawd place, from the Places/DoctorScenes*.swift files.
let doctorPlaces: [Location: Place] = [doctorScenes1, doctorScenes2, doctorScenes3, doctorScenes4]
    .reduce([:]) { $0.merging($1) { a, _ in a } }
