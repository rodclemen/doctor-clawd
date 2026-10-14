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
    case hem   // always last (`Universe.hem`)

    var persona: Persona { doctorHeroPersonas[self] ?? Persona.missing(String(describing: self)) }
}

enum DoctorVillain: Int, CaseIterable {
    // The monsters
    case dalick

    var persona: Persona { doctorVillainPersonas[self] ?? Persona.missing(String(describing: self)) }
}

let doctorHeroPersonas: [DoctorHero: Persona] = doctorHeroes1.merging([.hem: hemPersona(.doctor)]) { a, _ in a }
let doctorVillainPersonas: [DoctorVillain: Persona] = doctorVillains1

// MARK: - Homes

extension Location {
    static func doctorHome(of leader: DoctorVillain) -> Location {
        switch leader {
        case .dalick: return .consoleRoom
        }
    }

    static func doctorHome(of hero: DoctorHero) -> Location {
        switch hero {
        case .doctorTen, .hem: return .consoleRoom
        }
    }
}

// MARK: - The theme

extension Cast {
    static func hero(_ h: DoctorHero) -> Cast { Cast(universe: .doctor, isDark: false, index: h.rawValue) }
    static func villain(_ v: DoctorVillain) -> Cast { Cast(universe: .doctor, isDark: true, index: v.rawValue) }
}

/// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line.
private let doctorNemeses: [(DoctorHero, DoctorVillain)] = []

let doctorTheme = Theme(
    universe: .doctor,
    villains: DoctorVillain.allCases.map(\.persona),
    heroes: DoctorHero.allCases.map(\.persona),
    places: [.consoleRoom],
    home: { c in
        c.isDark ? .doctorHome(of: DoctorVillain(rawValue: c.index) ?? .dalick)
                 : .doctorHome(of: DoctorHero(rawValue: c.index) ?? .doctorTen)
    },
    nemeses: doctorNemeses.map { (.hero($0.0), .villain($0.1)) },
    ride: { _ in nil },
    menuIcon: drawPoliceBoxIcon,
    legend: .hero(.doctorTen))

// MARK: - Places

extension Location {
    static let consoleRoom = Location("consoleRoom")
}

/// Every Doctor Clawd place, from the Places/DoctorScenes*.swift files.
let doctorPlaces: [Location: Place] = doctorScenes1
