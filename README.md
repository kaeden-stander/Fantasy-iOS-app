# Fantasy AI

An iOS app that connects to your ESPN Fantasy leagues (football, basketball, baseball,
hockey) and uses Claude to give you start/sit and trade advice based on your actual
roster, projections, and matchups.

## What's here

This is a working Xcode project scaffold, not a finished product. It covers one full
path end to end — log in to ESPN, pick a league and team, view your roster, get AI
advice — plus the pieces (models, trade evaluation logic) needed to build the rest.

```
FantasyAI/
  App/            App entry point, root navigation, shared app state
  Auth/           ESPN login via WKWebView, cookie capture, credential storage
  Models/         Sport, League, Team, Roster, Player, Matchup, Recommendation, TradeProposal
  Networking/     ESPN's unofficial fantasy API client + Claude (Anthropic) API client
  Persistence/     Keychain wrapper, saved-league list, secure config
  Recommendations/ Builds prompts from live data and turns Claude's reply into Recommendation values
  Features/       SwiftUI screens: league setup, roster, advice, settings
FantasyAITests/   Unit tests for ESPN JSON decoding and the recommendation engine
```

## Requirements

- Xcode 15 or later
- iOS 17+ deployment target (already set in the project)
- An ESPN account that's a member of the league you want to connect
- An Anthropic API key (from console.anthropic.com) for the AI advice feature

## Getting started

1. Open `FantasyAI.xcodeproj` in Xcode.
2. Select the `FantasyAI` scheme and run it on a simulator or device.
3. In the app, tap **Log in to ESPN** — this opens ESPN's real login page in a web
   view and captures your session cookies once you sign in. Your ESPN password
   never passes through this app's code, only ESPN's own page.
4. Add a league: pick the sport, enter the league ID (the number in the URL when
   you view your league on espn.com or the ESPN app), and pick which team is yours.
5. In **Settings**, paste in an Anthropic API key so the **Advice** tab can call Claude.

## Important things to know before you build on this

**ESPN's fantasy API is unofficial.** There's no public, documented, or supported API
for ESPN Fantasy — everything here is built against the same undocumented endpoints
that community projects (like the `espn-api` Python library) have reverse-engineered.
ESPN can change the response shape or block this style of access at any time, without
notice. Treat this as a "works today" integration, not a stable foundation.

**Football is the only sport with real position/team mappings filled in.**
`ESPNPositionMap.swift` and `ESPNProTeamMap.swift` have verified, correct ID tables for
NFL positions, roster slots, and team abbreviations. The basketball, baseball, and hockey
tables in those files are explicitly marked as placeholders — before trusting player
positions or pro teams for those sports, fetch one real league response per sport and
check the `defaultPositionId` / `proTeamId` values against player names ESPN returns,
then update the tables.

**This container can't compile or run the app.** It's a Linux environment without
Xcode, so none of this has been built or run in a simulator. I generated the
`.xcodeproj` project file programmatically and verified every file reference resolves
to a real file on disk, and I traced through the Swift by hand for type errors, but the
first build in Xcode may still surface small issues (a typo, a missing case) that only
a real compiler catches. Budget time for that first build.

**No backend, by design.** The app calls the Anthropic API directly from the device
using the key you enter in Settings. That key lives in the Keychain. For anything beyond
your own personal use, you'd want a small backend to hold that key server-side instead
of shipping it inside a distributed app.

**Trade evaluation has logic but no screen yet.** `RecommendationEngine.evaluateTrade`
and the `TradeProposal` model are in place, but there's no UI for building a trade
proposal from two rosters — the **Advice** tab currently only wires up start/sit advice.

## Running the tests

Use Xcode's Test navigator (⌘6) on the `FantasyAITests` target, or:

```
xcodebuild test -project FantasyAI.xcodeproj -scheme FantasyAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

The tests cover ESPN JSON decoding (`ESPNMapperTests`) and the recommendation engine's
prompt building and response parsing (`RecommendationEngineTests`) — no network or
Xcode-specific APIs, so they run fast and don't need a live ESPN login or API key.
