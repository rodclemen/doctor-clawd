import AppKit

let args = CommandLine.arguments

if args.contains("--install-hooks") || args.contains("--update-hooks") || args.contains("--uninstall-hooks") {
    // Each AI on its own: one that fails doesn't stop the others, and every failure is reported.
    let errors: [String]
    if args.contains("--install-hooks") || args.contains("--update-hooks") {
        // --install-hooks connects every AI on this Mac; --update-hooks (build.sh) only refreshes the ones already
        // connected, so a rebuild never adds hooks to an AI you haven't chosen to connect.
        let update = args.contains("--update-hooks")
        let names = update ? HookInstaller.connected() : nil
        if update && names?.isEmpty == true { print("No AI is connected yet: connect them from the app") }
        let result = names?.isEmpty == true ? (installed: [], errors: []) : HookInstaller.installAll(names)
        for name in result.installed {
            let file = HookInstaller.other(name)?.file.path ?? HookInstaller.settingsURL.path
            print("Installed \(HookInstaller.displayName(name)) hooks → \(file)"
                  + (name == "codex" ? " (trust them once: run /hooks in Codex and approve)" : ""))
        }
        if !update && !HookInstaller.claudeAvailable { print("Claude Code isn't installed: skipped it") }
        errors = result.errors
    } else {
        let result = HookInstaller.uninstallAll()
        // `brew upgrade` runs this too: the next launch puts back exactly what was removed here.
        HookInstaller.rememberRemoved(result.removed)
        print(result.removed.isEmpty ? "No Clawd Clash hooks were installed"
              : "Removed the Clawd Clash hooks from " + result.removed.map(HookInstaller.displayName).joined(separator: ", "))
        errors = result.errors
    }
    for e in errors { FileHandle.standardError.write("Error: \(e)\n".data(using: .utf8)!) }
    exit(errors.isEmpty ? 0 : 1)
}

if let arg = args.first(where: { $0.hasPrefix("--jump=") }), let pid = Int32(arg.dropFirst(7)) {
    var lines: [String] = []
    Jump.log = { lines.append($0) }
    Jump.toSession(pid: pid)
    RunLoop.main.run(until: Date().addingTimeInterval(2.5))
    lines.append("frontmost after: \(NSWorkspace.shared.frontmostApplication?.localizedName ?? "?")")
    try? lines.joined(separator: "\n").write(toFile: args.last!, atomically: true, encoding: .utf8)
    exit(0)
}

if let arg = args.first(where: { $0.hasPrefix("--ax-dump=") }), let pid = Int32(arg.dropFirst(10)) {
    let report = Jump.dump(pid: pid)
    if let out = args.last, out != arg { try? report.write(toFile: out, atomically: true, encoding: .utf8) } else { print(report) }
    exit(0)
}

// Only one Clawd Clash at a time.
if let id = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
    exit(0)
}

// Hooks taken out by a Homebrew upgrade (see `HookInstaller.rememberRemoved`) go back in, quietly. Only on a
// normal launch: test and screenshot runs (--playground, --chaos…) may be a dev copy that shouldn't take the hooks.
if !args.dropFirst().contains(where: { $0.hasPrefix("--") }), ProcessInfo.processInfo.environment["CLAWD_SHOT"] == nil {
    let restored = HookInstaller.restoreRemoved()
    if !restored.installed.isEmpty { NSLog("Clawd Clash: reconnected \(restored.installed.joined(separator: ", ")) after an upgrade") }
    for e in restored.errors { NSLog("Clawd Clash: couldn't reconnect hooks: \(e)") }
    // Coming from Clawd Wars, Avengers: Clawd Wars or Justice League: Clawd Wars: take over the AIs they had connected. Not from a build/ copy
    // (a dev build never takes over hooks that point at a working app; it shows the banner instead).
    if !Bundle.main.bundlePath.contains("/build/") {
        let taken = HookInstaller.takeOverReplacedApps()
        if !taken.installed.isEmpty {
            NSLog("Clawd Clash: took over \(taken.installed.joined(separator: ", ")) from the app it replaces")
            // The old app, if it's running, would only complain that its hooks are gone: it's replaced, so it goes.
            for id in ["com.rodclemen.vaderclaude", "com.rodclemen.avengersclawdwars", "com.rodclemen.justiceleagueclawdwars"] {
                NSRunningApplication.runningApplications(withBundleIdentifier: id).forEach { $0.terminate() }
            }
        }
        for e in taken.errors { NSLog("Clawd Clash: couldn't take over hooks: \(e)") }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = OverlayController()
app.delegate = controller
app.run()
