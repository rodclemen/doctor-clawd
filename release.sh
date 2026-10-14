#!/bin/zsh
# Publishes a release: universal build → (optional) notarization → zip → GitHub release → Homebrew cask.
# Only the newest two GitHub releases are kept; older ones are deleted (their tags stay).
#   ./release.sh 2.14.0            refuses if tag v2.14.0 or its GitHub release already exists
#   ./release.sh 2.14.0 --force    replaces an existing tag and GitHub release
# HEAD must be pushed: it has to equal origin/main.
# Notarization runs when a notarytool keychain profile named "clawd-clash" (or Clawd Wars' "clawd-wars") exists:
#   xcrun notarytool store-credentials clawd-clash --apple-id <you@example.com> --team-id <TEAMID>
# Without it the cask clears the quarantine flag on install instead (like many open-source casks).
set -euo pipefail
cd "${0:A:h}"

VERSION="${1:?usage: ./release.sh <version> [--force]}"
FORCE=0
case "${2:-}" in
    "") ;;
    --force) FORCE=1 ;;
    *) echo "unknown option: $2 (usage: ./release.sh <version> [--force])" >&2; exit 2 ;;
esac
TAG="v$VERSION"
ZIP="build/Clawd-Clash-$VERSION.zip"
TAP_REPO="rodclemen/homebrew-tap"
KEEP_RELEASES=2   # this one and the one before it

[[ -z "$(git status --porcelain)" ]] || { echo "commit your changes first" >&2; exit 1; }
grep -q "^## $VERSION " CHANGELOG.md || { echo "add a '## $VERSION' entry to CHANGELOG.md first" >&2; exit 1; }
git fetch -q origin
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] \
    || { echo "HEAD isn't origin/main: push (or pull) first" >&2; exit 1; }
if [[ $FORCE == 0 ]]; then
    if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null; then
        echo "tag $TAG already exists (pass --force to replace it)" >&2; exit 1
    fi
    if gh release view "$TAG" >/dev/null 2>&1; then
        echo "GitHub release $TAG already exists (pass --force to replace it)" >&2; exit 1
    fi
fi

./build.sh --release "$VERSION"
APP="build/Clawd Clash.app"

# The notarytool profile: "clawd-clash", or Clawd Wars' "clawd-wars" (same Apple ID, already set up).
PROFILE=""
for p in clawd-clash clawd-wars; do
    if xcrun notarytool history --keychain-profile $p >/dev/null 2>&1; then PROFILE=$p; break; fi
done
if [[ -n $PROFILE ]]; then
    echo "→ notarizing (profile $PROFILE)"
    ditto -c -k --keepParent "$APP" build/notarize.zip
    xcrun notarytool submit build/notarize.zip --keychain-profile $PROFILE --wait
    xcrun stapler staple "$APP"
    NOTARIZED=1
else
    echo "→ no notarytool profile 'clawd-clash' or 'clawd-wars': skipping notarization"
    NOTARIZED=0
fi

echo "→ packaging $ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)

echo "→ GitHub release $TAG"
NOTES=$(awk "/^## $VERSION /{f=1;next} /^## /{f=0} f" CHANGELOG.md)
if [[ $FORCE == 1 ]]; then
    git tag -f "$TAG" && git push -f origin "$TAG"
    gh release delete "$TAG" --yes >/dev/null 2>&1 || true
else
    git tag "$TAG" && git push origin "$TAG"
fi
gh release create "$TAG" "$ZIP" --title "Clawd Clash $VERSION" --notes "$NOTES

**Install:** \`brew tap rodclemen/tap && brew trust rodclemen/tap && brew install --cask clawd-clash\` (\`brew trust\` only on newer Homebrew), or download the zip, unzip, and move *Clawd Clash.app* to Applications. (\`star-clawds\`, \`marvelous-clawds\` and \`detective-clawds\` install the same app, starting in Star Clawds, Marvelous Clawds or Detective Clawds.)"

# Keep the newest $KEEP_RELEASES releases: older zips are never used (the cask names only the latest), and the one
# before the latest stays as a quick rollback. Tags are kept, so every version's code is still marked in git.
for old in $(gh release list --limit 200 --exclude-drafts --json tagName,createdAt \
                 --jq "sort_by(.createdAt) | reverse | .[$KEEP_RELEASES:] | .[].tagName"); do
    gh release delete "$old" --yes && echo "→ removed old release $old (tag kept)"
done

echo "→ Homebrew cask ($TAP_REPO)"
gh repo view "$TAP_REPO" >/dev/null 2>&1 || gh repo create "$TAP_REPO" --public \
    --description "Homebrew tap for Clawd Clash and friends" >/dev/null
TAP=$(mktemp -d)
gh repo clone "$TAP_REPO" "$TAP" -- -q 2>/dev/null || git -C "$TAP" init -q -b main
mkdir -p "$TAP/Casks"
QUARANTINE=""
if [[ $NOTARIZED == 0 ]]; then
    QUARANTINE='
  # Not notarized yet: clear the download quarantine so macOS lets it open.
  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "{{appdir}}/Clawd Clash.app"],
        writable_paths: ["Clawd Clash.app"],
        writable_base:  :appdir
  end
'
fi
# Four casks, one app: clawd-clash, and one per universe, which starts it there (only if no universe has been chosen
# yet, so an upgrade never undoes your choice).
write_cask() {   # write_cask <cask name> <universe key or empty> <description>
    local name=$1 universe=$2 desc=$3 others preset=""
    others=$(printf '"%s", ' clawd-clash star-clawds marvelous-clawds detective-clawds | sed "s/\"$name\", //; s/, $//")
    if [[ -n $universe ]]; then
        preset="
  # Start in $universe, unless a universe was already picked.
  preflight do
    system_command \"/bin/sh\", args: [\"-c\", \"defaults read com.rodclemen.clawdclash universe >/dev/null 2>&1 || defaults write com.rodclemen.clawdclash universe -string $universe\"]
  end
"
    fi
    cat > "$TAP/Casks/$name.rb" <<CASK
cask "$name" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/rodclemen/clawd-clash/releases/download/v#{version}/Clawd-Clash-#{version}.zip"
  name "Clawd Clash"
  desc "$desc"
  homepage "https://github.com/rodclemen/clawd-clash"

  depends_on macos: :ventura
  conflicts_with cask: [$others]

  app "Clawd Clash.app"
$preset$QUARANTINE
  # brew runs this on upgrade too (uninstall, then install): the hooks come out, and the new app puts
  # them back on its next launch.
  uninstall quit:   "com.rodclemen.clawdclash",
            script: {
              executable: "#{appdir}/Clawd Clash.app/Contents/MacOS/ClawdClash",
              args:       ["--uninstall-hooks"],
            }

  zap trash: [
    "~/.claude/clawd-clash",
    "~/Library/Application Support/Clawd Clash",
    "~/Library/Screen Savers/Clawd Clash.saver",
    "~/Library/Preferences/com.rodclemen.clawdclash.plist",
  ]
end
CASK
}
write_cask clawd-clash "" "Claude Code sessions as a pixel-art Star Clawds, Marvelous Clawds or Detective Clawds battle on your desktop"
write_cask star-clawds starWars "Claude Code sessions as a pixel-art Star Clawds battle on your desktop"
write_cask marvelous-clawds marvel "Claude Code sessions as a pixel-art Marvelous Clawds battle on your desktop"
write_cask detective-clawds dc "Claude Code sessions as a pixel-art Detective Clawds battle on your desktop"
# The universe casks used to be named after the old apps: Homebrew moves installs of those over (cask_renames.json).
rm -f "$TAP/Casks/clawd-wars.rb" "$TAP/Casks/clawdvengers-clawd-wars.rb" "$TAP/Casks/justice-clawds-clawd-wars.rb"
cat > "$TAP/cask_renames.json" <<'RENAMES'
{
  "clawd-wars": "star-clawds",
  "clawdvengers-clawd-wars": "marvelous-clawds",
  "justice-clawds-clawd-wars": "detective-clawds"
}
RENAMES
[[ -f "$TAP/README.md" ]] || printf '# Homebrew tap\n\n```sh\nbrew tap rodclemen/tap\nbrew trust rodclemen/tap      # newer Homebrew asks you to trust a third-party tap once\nbrew install --cask clawd-clash\n```\n' > "$TAP/README.md"
git -C "$TAP" add -A
git -C "$TAP" commit -q -m "clawd-clash $VERSION (also star-clawds, marvelous-clawds, detective-clawds)"
git -C "$TAP" remote get-url origin >/dev/null 2>&1 || git -C "$TAP" remote add origin "https://github.com/$TAP_REPO.git"
git -C "$TAP" push -q -u origin main
rm -rf "$TAP"

echo "✓ released $TAG: brew tap rodclemen/tap && brew trust rodclemen/tap && brew install --cask clawd-clash"
