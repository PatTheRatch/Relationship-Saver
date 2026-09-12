# Architecture

Native iOS, SwiftUI, iOS 17 and later. No third party dependencies.

The platform choice is argued in the session that produced it and comes down to
one thing: the daily nudge is the mechanism the whole product depends on, and
local notifications are reliable in a way iOS web push is not.

---

## Layers

```
Views  (SwiftUI)          what the user touches
  |
Store  (@Observable)      state, persistence, event logging
  |
Engine (pure functions)   which people come back, and in what order
  |
Models (value types)      Person, Capture, Interaction, Event
```

The rule is that dependencies only point downward. The engine knows nothing
about storage, SwiftUI, or the clock. Everything it needs is passed in,
including `now` and the random number generator, which is what makes every
resurfacing rule directly testable.

`ResurfaceEngine.buildSession` is the only place session ordering is decided.
If a rule is not expressed there, it is not a rule.

---

## Why JSON on disk rather than SwiftData

The store is a `Codable` snapshot written to Application Support as pretty
printed JSON, with an append only JSON Lines file beside it for events.

For tens of people this is entirely adequate, and it buys three things worth
more than scale here:

- **No migrations.** Every model decodes tolerantly with `decodeIfPresent`, so
  adding a field next week does not make last week's data unreadable.
- **No macro behaviour to debug.** The data layer is ordinary Swift.
- **A readable data file.** You can open it in any text editor and see exactly
  what the app believes about your relationships.

If the person list ever reaches the thousands, this is the piece to replace.
The engine above it will not have to change.

---

## Two places the implementation improved on the scope doc

**The serendipity slot needed a dormancy floor.** As first specified, the slot
surfaced whoever was left over once the rules had run. In practice that meant
surfacing people contacted yesterday whenever the stack was quiet, which is
noise rather than serendipity and quickly teaches the user to distrust the
stack. The slot now requires a person to be genuinely out of touch, defaulting
to thirty days. The consequence is that a session can be empty, which is the
right answer when nothing needs doing.

**The Message action does not have to guess.** The scope doc assumed the app
could not know whether a message was actually sent, and settled on recording
the interaction optimistically with an undo. Using `MFMessageComposeViewController`
rather than an `sms:` URL, the delegate reports the real result, so the
relationship clock resets on a confirmed send and not before. Optimistic
recording survives only as the fallback when the device cannot send text or no
number is on file.

---

## The event log

`events.jsonl`, one JSON object per line, never rewritten and never deleted,
including when a person is archived.

There is no UI for it in V1 and that is deliberate: the data is impossible to
reconstruct after the fact, and the screens are easy to add later. It exists to
answer one question.

> Did the app cause a relationship interaction that probably would not have
> happened otherwise?

Every `actionTaken` event carries the tier that surfaced the person and whether
it was a reply, so the answer is a query rather than a guess.

---

## Building it

Open `RelationshipSaver.xcodeproj` in Xcode 16 or later and run. The project
uses file system synchronized groups, so new files added to the folders are
picked up without touching the project file.

From the command line:

```
xcodebuild test -scheme RelationshipSaver -destination 'platform=iOS Simulator,name=iPhone 16'
```

Set your own team under Signing and Capabilities before running on a device,
and change `PRODUCT_BUNDLE_IDENTIFIER` from `com.relationshipsaver.app` to
something in a namespace you own.

### What has not been verified

The Swift in this repository has never been compiled. It was written in an
environment with no Swift toolchain, so expect to fix whatever the first build
surfaces. The resurfacing rules themselves were validated separately against
the scenarios in `RelationshipSaverTests/ResurfaceEngineTests.swift` before
those expectations were committed, so the logic should be sound even where the
syntax needs a nudge.

---

## Deliberately absent

No AI, no outbox, no stats screens, no search, no widgets. Each is argued in
[V1 Scope](V1_SCOPE.md). The first build exists to answer whether resurfacing
changes behaviour, and every one of those features would make that question
slower to answer without making it easier.
