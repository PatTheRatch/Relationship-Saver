# Relationship Saver

A lightweight relationship-maintenance app for people who genuinely care about others but struggle to consistently reply, initiate, and follow up at the right time.

> **Remember the people for me. Bring them back at the right time. Make acting easy.**

Native iOS, SwiftUI, iOS 17+. No third-party dependencies.

## Getting started

Open `RelationshipSaver.xcodeproj` in Xcode 16 or later and run. Set your own
signing team, and change the bundle identifier to a namespace you own.

The Swift here has never been compiled. See the note in
[Architecture](docs/ARCHITECTURE.md#what-has-not-been-verified).

## Docs

- [Product North Star](docs/NORTH_STAR.md) — the problem, core loop, product surfaces, principles, and success metric.
- [V1 Scope](docs/V1_SCOPE.md) — what the first build includes, what is deferred, and the resurfacing rules.
- [Architecture](docs/ARCHITECTURE.md) — how it is put together and why.

## Layout

```
RelationshipSaver/
  Models/     Person, Capture, Interaction, Event
  Engine/     ResurfaceEngine and the session rules
  Services/   Store, EventLog, notifications, message composer
  Views/      SwiftUI surfaces
RelationshipSaverTests/
  ResurfaceEngineTests.swift   the executable spec for the session rules
```
