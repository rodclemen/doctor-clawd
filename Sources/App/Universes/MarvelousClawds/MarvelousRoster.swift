import Foundation

// The Marvel universe: 105 heroes, 88 villains and 43 places. Any character can lead a session (drawn large) or be an
// agent (small). Who they are, how they fight and how they move is a `Persona`, registered in one of the Art/*.swift
// files next to its drawing code; who lives where, who fights whom first and who gets picked up is decided here, in
// `marvelTheme`.
//
// Ids are stored in the status file: `Universe.marvel.base` plus `MarvelVillain.rawValue` (< 100) or
// 100 + `MarvelHero.rawValue`. Only ever append cases, so running sessions keep their characters across an update.

enum MarvelHero: Int, CaseIterable {
    // Avengers
    case ironMan, captainAmerica, thor, hulk, blackWidow, hawkeye, spiderMan, blackPanther, doctorStrange, scarletWitch
    case vision, captainMarvel
    // More Avengers and the Guardians of the Galaxy
    case antMan, wasp, falcon, winterSoldier, starLord, gamora, drax, rocket, groot, mantis, nickFury, sheHulk
    // X-Men
    case wolverine, cyclops, storm, jeanGrey, professorX, beast, nightcrawler, gambit, rogue, iceman, colossus
    // Fantastic Four, the street and the rest
    case humanTorch, thing, mrFantastic, invisibleWoman, silverSurfer, daredevil, deadpool, shangChi, msMarvel
    case moonKnight, ghostRider
    // War Machine, the Maximoff kids, Wakanda and Sakaar.
    case warMachine, wiccan, speed, quicksilver, kateBishop, yelena, okoye, shuri, valkyrie, korg
    // Kamar-Taj, the cosmos and the younger X-Men.
    case wong, hercules, sentry, cosmo, kraglin, adamWarlock, nova, kittyPryde, jubilee, psylocke
    // more X-Men and the Spider-heroes.
    case bishop, cable, havok, emmaFrost, banshee, angel, domino, x23, milesMorales, spiderGwen
    // the street, Defenders, Punisher, Blade and friends.
    case spiderWoman, blackCat, lukeCage, ironFist, jessicaJones, punisher, elektra, blade, blackKnight
    // mystics, cosmic and the funny ones.
    case monicaRambeau, clea, doctorVoodoo, howardTheDuck, squirrelGirl, jeffTheLandShark, throg, lockjaw, forbushMan
    // The TVA, the Red Room, the Savage Land, Stark's workshop and Ta Lo
    case mobius, sylvie, kidLoki, alligatorLoki, hunterB15, redGuardian, kaZar, rescue, zabu, morris, dumE
    case hem   // always last (`Universe.hem`)

    var persona: Persona { heroPersonas[self] ?? Persona.missing(String(describing: self)) }
}

enum MarvelVillain: Int, CaseIterable {
    // Cosmic and Avengers foes
    case thanos, loki, ultron, redSkull, doctorDoom, hela, ronan, nebula, ebonyMaw, chitauri, grandmaster, ultronSentry
    // Spider-Man's rogues
    case greenGoblin, venom, carnage, docOck, mysterio, electro, vulture, rhino, sandman, lizard, kraven
    // Mutants, monsters and machines
    case magneto, juggernaut, sabretooth, mystique, apocalypse, sentinel, abomination, finFangFoom, modok, dormammu
    case doombot
    // The street, spies and soldiers
    case kingpin, bullseye, handNinja, hydraAgent, aimAgent, skrull, taskmaster, zemo, whiplash, mandarin, killmonger
    case batroc
    // cosmic powers and more of Spider-Man's rogues.
    case galactus, kang, mephisto, knull, annihilus, highEvolutionary, morganLeFay, scorpion, shocker, hobgoblin
    // the street and the mutant foes.
    case morbius, misterNegative, chameleon, tombstone, misterSinister, omegaRed, toad, pyro, blob
    // aliens, Avengers foes and sorcerers.
    case brood, cassandraNova, graviton, absorbingMan, crimsonDynamo, wrecker, baronMordo, enchantress, arnimZola
    // gamma, Asgard's enemies and foot soldiers.
    case countNefaria, theLeader, maestro, malekith, surtur, kurse, frostGiant, hydraSuperSoldier, kreeSoldier
    // The TVA, the Morlock Tunnels, Asteroid M, Ta Lo and the Red Room
    case missMinutes, callisto, exodus, soulEater, redRoomWidow

    var persona: Persona { villainPersonas[self] ?? Persona.missing(String(describing: self)) }

}

let heroPersonas: [MarvelHero: Persona] = heroes1.merging(heroes2) { a, _ in a }.merging(heroes3) { a, _ in a }
    .merging(heroes4) { a, _ in a }
    .merging(heroes5) { a, _ in a }.merging(heroes6) { a, _ in a }.merging(heroes7) { a, _ in a }
    .merging(heroes8) { a, _ in a }.merging(heroes9) { a, _ in a }
    .merging(heroes10) { a, _ in a }.merging([.hem: hemPersona(.marvel)]) { a, _ in a }
let villainPersonas: [MarvelVillain: Persona] = villains1.merging(villains2) { a, _ in a }.merging(villains3) { a, _ in a }
    .merging(villains4) { a, _ in a }
    .merging(villains5) { a, _ in a }.merging(villains6) { a, _ in a }.merging(villains7) { a, _ in a }
    .merging(villains8) { a, _ in a }.merging(villains9) { a, _ in a }

// MARK: - Homes

extension Location {
    static func marvelHome(of leader: MarvelVillain) -> Location {
        switch leader {
        case .thanos, .nebula, .ebonyMaw: return .titan
        case .loki, .hela: return .asgard
        case .ultron, .ultronSentry, .whiplash: return .avengersTower
        case .redSkull: return .vormir
        case .doctorDoom, .doombot: return .latveria
        case .ronan: return .knowhere
        case .chitauri, .vulture: return .battleOfNewYork
        case .grandmaster, .abomination, .finFangFoom: return .sakaar
        case .greenGoblin, .venom, .docOck, .mysterio: return .dailyBugle
        case .carnage, .electro, .rhino, .sandman, .taskmaster: return .raft
        case .lizard, .kraven, .sabretooth: return .savageLand
        case .magneto: return .asteroidM
        case .juggernaut, .mystique, .sentinel: return .xMansion
        case .apocalypse: return .krakoa
        case .modok, .hydraAgent, .aimAgent, .zemo: return .hydraBase
        case .dormammu: return .darkDimension
        case .kingpin, .bullseye, .handNinja: return .hellsKitchen
        case .skrull, .batroc: return .helicarrier
        case .mandarin: return .kamarTaj
        case .killmonger: return .wakanda
        case .galactus: return .worldship
        case .kang: return .quantumRealm
        case .mephisto, .knull: return .darkDimension
        case .annihilus: return .baxterBuilding
        case .highEvolutionary: return .knowhere
        case .morganLeFay: return .latveria
        case .scorpion, .chameleon, .absorbingMan, .theLeader: return .raft
        case .shocker, .hobgoblin: return .dailyBugle
        case .morbius, .omegaRed, .countNefaria: return .madripoor
        case .misterNegative, .tombstone: return .harlem
        case .misterSinister, .toad, .pyro, .cassandraNova: return .genosha
        case .blob: return .xMansion
        case .brood, .kreeSoldier: return .hala
        case .graviton: return .helicarrier
        case .crimsonDynamo, .hydraSuperSoldier: return .sokovia
        case .wrecker: return .battleOfNewYork
        case .baronMordo: return .kamarTaj
        case .enchantress: return .asgard
        case .arnimZola: return .hydraBase
        case .maestro: return .sakaar
        case .malekith, .frostGiant: return .jotunheim
        case .surtur, .kurse: return .muspelheim
        case .missMinutes: return .tva
        case .callisto: return .morlockTunnels
        case .exodus: return .asteroidM
        case .soulEater: return .taLo
        case .redRoomWidow: return .redRoom
        }
    }

    static func marvelHome(of hero: MarvelHero) -> Location {
        switch hero {
        case .vision, .hem: return .avengersTower
        case .ironMan: return .starkWorkshop
        case .captainAmerica, .blackWidow, .falcon, .nickFury: return .helicarrier
        case .thor: return .asgard
        case .hulk: return .sakaar
        case .hawkeye: return .battleOfNewYork
        case .spiderMan: return .newYorkStreets
        case .blackPanther: return .wakanda
        case .doctorStrange: return .sanctum
        case .scarletWitch, .winterSoldier: return .hydraBase
        case .captainMarvel, .starLord, .drax, .rocket, .groot: return .knowhere
        case .antMan, .wasp: return .quantumRealm
        case .gamora, .silverSurfer: return .titan
        case .mantis: return .egosPlanet
        case .sheHulk, .colossus: return .raft
        case .wolverine, .gambit, .rogue: return .savageLand
        case .cyclops, .storm, .jeanGrey, .professorX, .beast, .nightcrawler, .iceman: return .xMansion
        case .humanTorch, .mrFantastic, .invisibleWoman, .thing: return .baxterBuilding
        case .daredevil, .deadpool, .moonKnight: return .hellsKitchen
        case .shangChi: return .taLo
        case .msMarvel: return .attilan
        case .ghostRider: return .darkDimension
        case .sentry, .blackKnight: return .avengersTower
        case .warMachine: return .avengersCompound
        case .wiccan, .speed, .quicksilver: return .sokovia
        case .kateBishop, .spiderGwen: return .dailyBugle
        case .psylocke, .domino, .x23, .blade: return .madripoor
        case .yelena: return .redRoom
        case .okoye, .shuri: return .wakanda
        case .valkyrie, .korg: return .sakaar
        case .wong: return .kamarTaj
        case .hercules, .throg: return .asgard
        case .cosmo, .kraglin, .adamWarlock, .howardTheDuck: return .knowhere
        case .monicaRambeau: return .hala
        case .nova: return .xandar
        case .kittyPryde, .jubilee, .banshee, .angel: return .xMansion
        case .bishop, .cable, .havok: return .genosha
        case .emmaFrost: return .krakoa
        case .milesMorales, .lukeCage: return .harlem
        case .spiderWoman: return .helicarrier
        case .blackCat, .jessicaJones, .punisher: return .hellsKitchen
        case .ironFist, .elektra: return .kunLun
        case .clea: return .darkDimension
        case .doctorVoodoo: return .sanctum
        case .squirrelGirl, .jeffTheLandShark, .forbushMan: return .baxterBuilding
        case .lockjaw: return .attilan
        case .mobius, .sylvie, .kidLoki, .alligatorLoki, .hunterB15: return .tva
        case .redGuardian: return .redRoom
        case .kaZar, .zabu: return .savageLandCitadel
        case .rescue: return .avengersCompound
        case .morris: return .taLo
        case .dumE: return .starkWorkshop
        }
    }
}

// MARK: - The theme

extension Cast {
    static func hero(_ h: MarvelHero) -> Cast { Cast(universe: .marvel, isDark: false, index: h.rawValue) }
    static func villain(_ v: MarvelVillain) -> Cast { Cast(universe: .marvel, isDark: true, index: v.rawValue) }
}

/// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line.
private let marvelNemeses: [(MarvelHero, MarvelVillain)] = [
    (.captainAmerica, .redSkull), (.thor, .loki), (.spiderMan, .greenGoblin), (.spiderMan, .venom),
    (.wolverine, .sabretooth), (.blackPanther, .killmonger), (.doctorStrange, .dormammu), (.hulk, .abomination),
    (.vision, .ultron), (.ironMan, .ultron), (.daredevil, .kingpin), (.daredevil, .bullseye), (.gamora, .nebula),
    (.starLord, .ronan), (.thor, .hela), (.shangChi, .mandarin), (.mrFantastic, .doctorDoom),
    (.blackWidow, .taskmaster), (.ironMan, .whiplash), (.captainMarvel, .skrull), (.cyclops, .magneto),
    (.storm, .apocalypse), (.captainAmerica, .zemo),
    (.silverSurfer, .galactus), (.antMan, .kang), (.ghostRider, .mephisto), (.doctorStrange, .baronMordo),
    (.thor, .malekith), (.thor, .surtur), (.valkyrie, .hela), (.punisher, .kingpin), (.wolverine, .omegaRed),
    (.cyclops, .misterSinister), (.hulk, .theLeader), (.hulk, .maestro), (.blade, .morbius), (.elektra, .bullseye),
    (.spiderMan, .scorpion), (.milesMorales, .hobgoblin), (.rocket, .highEvolutionary), (.captainMarvel, .kreeSoldier),
    (.lukeCage, .tombstone), (.ironFist, .handNinja), (.thor, .absorbingMan), (.mrFantastic, .annihilus),
    (.ironMan, .crimsonDynamo), (.thor, .frostGiant), (.spiderGwen, .lizard),
    (.sylvie, .missMinutes), (.blackWidow, .redRoomWidow), (.shangChi, .soulEater), (.storm, .callisto), (.cyclops, .exodus),
]

/// When these agents are done, their ship comes to pick them up instead of them just fading out.
private let quinjetCrew: [MarvelHero] = [.captainAmerica, .blackWidow, .hawkeye, .nickFury, .hulk, .kateBishop, .yelena]
private let milanoCrew: [MarvelHero] = [.starLord, .gamora, .drax, .rocket, .groot, .mantis, .kraglin, .cosmo]

let marvelTheme = Theme(
    universe: .marvel,
    villains: MarvelVillain.allCases.map(\.persona),
    heroes: MarvelHero.allCases.map(\.persona),
    places: [.avengersTower, .sanctum, .wakanda, .asgard, .sakaar, .knowhere, .titan, .helicarrier, .xMansion, .hellsKitchen,
             .vormir, .quantumRealm, .latveria, .hydraBase, .dailyBugle, .egosPlanet, .kamarTaj, .raft, .battleOfNewYork,
             .darkDimension, .attilan, .savageLand, .baxterBuilding, .jotunheim, .muspelheim, .hala, .genosha, .madripoor,
             .sokovia, .worldship, .harlem, .kunLun, .xandar, .avengersCompound, .tva, .krakoa, .morlockTunnels, .asteroidM,
             .newYorkStreets, .savageLandCitadel, .starkWorkshop, .redRoom, .taLo],
    home: { c in
        c.isDark ? .marvelHome(of: MarvelVillain(rawValue: c.index) ?? .thanos) : .marvelHome(of: MarvelHero(rawValue: c.index) ?? .ironMan)
    },
    nemeses: marvelNemeses.map { (.hero($0.0), .villain($0.1)) },
    ride: { c in
        guard c.universe == .marvel, !c.isDark, let h = MarvelHero(rawValue: c.index) else { return nil }
        return quinjetCrew.contains(h) ? .quinjet : milanoCrew.contains(h) ? .milano : nil
    },
    menuIcon: drawMenuBarShield,
    legend: .hero(.ironMan))

// MARK: - Places

extension Location {
    static let avengersTower = Location("avengersTower"), sanctum = Location("sanctum"), wakanda = Location("wakanda")
    static let asgard = Location("asgard"), sakaar = Location("sakaar"), knowhere = Location("knowhere"), titan = Location("titan")
    static let helicarrier = Location("helicarrier"), xMansion = Location("xMansion"), hellsKitchen = Location("hellsKitchen")
    static let vormir = Location("vormir"), quantumRealm = Location("quantumRealm"), latveria = Location("latveria")
    static let hydraBase = Location("hydraBase"), dailyBugle = Location("dailyBugle"), egosPlanet = Location("egosPlanet")
    static let kamarTaj = Location("kamarTaj"), raft = Location("raft"), battleOfNewYork = Location("battleOfNewYork")
    static let darkDimension = Location("darkDimension"), attilan = Location("attilan"), savageLand = Location("savageLand")
    static let baxterBuilding = Location("baxterBuilding"), jotunheim = Location("jotunheim"), muspelheim = Location("muspelheim")
    static let hala = Location("hala"), genosha = Location("genosha"), madripoor = Location("madripoor"), sokovia = Location("sokovia")
    static let worldship = Location("worldship"), harlem = Location("harlem"), kunLun = Location("kunLun"), xandar = Location("xandar")
    static let avengersCompound = Location("avengersCompound"), tva = Location("tva"), krakoa = Location("krakoa")
    static let morlockTunnels = Location("morlockTunnels"), asteroidM = Location("asteroidM")
    static let newYorkStreets = Location("newYorkStreets"), savageLandCitadel = Location("savageLandCitadel")
    static let starkWorkshop = Location("starkWorkshop"), redRoom = Location("redRoom"), taLo = Location("taLo")
}

/// Every Marvel place, from the Places/Scenes*.swift files.
let marvelPlaces: [Location: Place] = scenes1.merging(scenes2) { a, _ in a }.merging(scenes3) { a, _ in a }
    .merging(scenes4) { a, _ in a }.merging(scenes5) { a, _ in a }.merging(scenes6) { a, _ in a }.merging(scenes7) { a, _ in a }
