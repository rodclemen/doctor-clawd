import Foundation

// A universe's content: its cast, its places, who lives where, who fights whom first, who gets picked up, and the
// little things that dress the app in it (the menu bar icon, the Status Symbols character). Each universe defines one
// in its folder (Universes/<Name>/); the engine only ever asks the current `Theme`.

struct Theme {
    let universe: Universe
    /// Villains by local index (0…), then heroes by local index (0…).
    let villains: [Persona]
    let heroes: [Persona]
    /// Every place, in menu order. The first is where the crew stands when nobody's home is known.
    let places: [Location]
    /// Where a character belongs.
    let home: (Cast) -> Location
    /// Arch-enemies, paired first whenever both are fighting.
    let nemeses: [(Cast, Cast)]
    /// Who gets picked up by a ship when its agent is done.
    let ride: (Cast) -> Ride?
    /// The menu bar icon, on a 28×26 canvas; `mono`: one colour, for a template image.
    let menuIcon: (PixelCanvas, _ mono: Bool) -> Void
    /// Who stands in for a session in Status Symbols.
    let legend: Cast

    func persona(_ c: Cast) -> Persona {
        let list = c.isDark ? villains : heroes
        return list.indices.contains(c.index) ? list[c.index] : Persona.missing("\(universe.key) \(c.id)")
    }

    var cast: [Cast] {
        villains.indices.map { Cast(universe: universe, isDark: true, index: $0) }
            + heroes.indices.map { Cast(universe: universe, isDark: false, index: $0) }
    }

    func isNemesis(_ a: Cast, _ b: Cast) -> Bool { nemeses.contains { ($0.0 == a && $0.1 == b) || ($0.0 == b && $0.1 == a) } }

    static func of(_ u: Universe) -> Theme {
        switch u {
        case .starWars: return starWarsTheme
        case .marvel: return marvelTheme
        case .dc: return dcTheme
        case .doctor: return doctorTheme
        }
    }
}

extension Universe {
    /// The universe on show in this process: the app's choice, or the screen saver's for the trip it's on.
    static var shown: Universe = .starWars
}

extension Cast {
    func isNemesis(of other: Cast) -> Bool { universe == other.universe && Theme.of(universe).isNemesis(self, other) }
    var ride: Ride? { Theme.of(universe).ride(self) }
}

/// The ships that come to pick someone up (`Theme.ride`).
enum Ride { case falcon, quinjet, milano, javelin, batwing }
