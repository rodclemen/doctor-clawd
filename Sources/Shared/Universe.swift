import Foundation

/// The universes Clawd Clash can show. One at a time: a scene never mixes characters from two of them.
///
/// Cast ids are stored in the status file and the screen-saver feed: `universe.base + local`, where local ids are
/// villains `0..<100` and heroes `100…`. Star Wars keeps Clawd Wars' ids (base 0), so its saved state carries over.
enum Universe: Int, CaseIterable, Codable {
    case starWars = 0
    case marvel = 1
    case dc = 2
    case doctor = 3

    var key: String {
        switch self { case .starWars: return "starWars"; case .marvel: return "marvel"; case .dc: return "dc"; case .doctor: return "doctor" }
    }
    init?(key: String) { self.init(rawValue: Universe.allCases.first { $0.key == key }?.rawValue ?? -1) }

    var title: String {
        switch self { case .starWars: return "Star Clawds"; case .marvel: return "Marvelous Clawds"; case .dc: return "Detective Clawds"; case .doctor: return "Doctor Clawd" }
    }
    var base: Int { rawValue * 1000 }

    var villainCount: Int {
        switch self { case .starWars: return 46; case .marvel: return 88; case .dc: return 97; case .doctor: return 42 }
    }
    var heroCount: Int {
        switch self { case .starWars: return 36; case .marvel: return 106; case .dc: return 111; case .doctor: return 56 }
    }

    /// HEM: the same rare face in every universe, last of the heroes. He's never in the regular pools (`lightCast`);
    /// a new session or agent turns out to be him now and then (`hemOdds`), and he stays himself across universes.
    var hem: Int { base + StatusStore.heroBase + heroCount - 1 }
    func isHem(_ id: Int) -> Bool { id % 1000 == StatusStore.heroBase + heroCount - 1 }
    /// The chance a new session's character, or a new agent's, is HEM.
    static let hemOdds = (session: 1.0 / 50, agent: 1.0 / 150)

    /// Small fry that only ever turn up as agents, never leading a session (global ids).
    var agentOnly: Set<Int> {
        switch self {
        case .starWars: return [23, 26]                                           // MSE-6, ID9 seeker droid
        case .marvel: return Set([11, 33, 190, 202, 203, 204].map { base + $0 })  // Ultron Sentry, Doombot, Jeff, Zabu, Morris, Dum-E
        // Joker Goon, Dex-Starr, Mister Mind, Krypto, Ch'p, Ace the Bat-Hound, Streaky, Gleek, Beppo
        case .dc: return Set([22, 49, 77, 131, 139, 206, 207, 208, 209].map { base + $0 })
        case .doctor: return Set([39, 40, 41].map { base + $0 })                // Adipoze, Cybermite, Toclafayne
        }
    }

    /// With another AI running, Claude Code's side: false = heroes, true = villains, nil = whoever came first keeps
    /// the side it mostly has (Star Wars, as Clawd Wars always did).
    var claudeSide: Bool? { self == .starWars ? nil : false }

    /// Characters that never lead two sessions back to back (Vader and Kylo), as global ids.
    var rivals: Set<Int> { self == .starWars ? [0, 1] : [] }

    var darkCast: [Int] { (0..<villainCount).map { base + $0 } }
    var lightCast: [Int] { (0..<heroCount - 1).map { base + StatusStore.heroBase + $0 } }   // all but HEM

    /// Which universe a cast id belongs to.
    static func of(_ id: Int) -> Universe { Universe(rawValue: id / 1000) ?? .starWars }
    static func isDark(_ id: Int) -> Bool { id % 1000 < StatusStore.heroBase }

    /// `id` as a member of this universe: itself if it already is one, otherwise the character in the same place on
    /// the same side here (the screen saver showing another universe, or the universe switched with sessions open).
    func adopt(_ id: Int) -> Int {
        guard Universe.of(id) != self else { return id }
        if Universe.of(id).isHem(id) { return hem }
        let local = id % 1000
        return Universe.isDark(id) ? base + local % villainCount
                                   : base + StatusStore.heroBase + (local - StatusStore.heroBase) % (heroCount - 1)
    }
}
