# V1 Scope

This document defines the **first build**, which is deliberately narrower than
the MVP described in the [North Star](NORTH_STAR.md).

The north star describes where the product is going. This describes the
smallest thing that tests whether it should go there.

---

## What V1 Has To Prove

> Does being shown one person at a time, unprompted, actually cause contact
> that would not otherwise have happened?

Everything in this build serves that question. Everything that does not serve
it waits, however good an idea it is.

If the answer is yes, the deferred features are worth building. If the answer
is no, none of them would have saved it.

---

## In Scope

- **Add a person manually** — name, relationship intent, contact cadence.
  Everything else optional.
- **Resurface stack** — one person per card, capped session (see
  [Session Shape](#session-shape)).
- **Replies and initiations as separate concepts** — replies always sort first.
- **One-tap "we connected"** — resets the relationship clock, no categorization.
- **Snooze** — including a longer "not for a while" option.
- **Archive** — keep history, leave active rotation.
- **Quick capture** — text, with a small set of categories.
- **Follow-ups** — a capture with a due date, surfaced when due.
- **Birthdays and important dates** — surfaced ahead of the date.
- **Notes on a person** — free text, visible on the card behind a tap.
- **The daily nudge** — one notification per day at a user-chosen time.
- **Event log** — see [Instrumentation](#instrumentation). No UI.

---

## Deferred To V2

Not cut. Deferred, with the reason.

| Feature | Why it waits |
| --- | --- |
| AI drafting, two variations | A subsystem of its own: key management, style representation, prompt design. It makes acting easier; it does not test whether resurfacing works. |
| Stats UI | There is one user, and he will know whether it worked. The *data* is collected from day one — only the screens wait. |
| Outbox as a surface | "Write now, send later" ships as a draft plus a send-reminder on the person. It becomes a surface once there is evidence of enough queued messages to need one. |
| Pause as distinct from snooze | Conceptually different, but one state field with a duration covers both. Split it when snooze-with-a-long-duration proves insufficient. |
| Search | Needed at a few hundred people. Not at five to thirty. |
| Pinned people | Pinning matters when the stack is crowded. Revisit after real use. |
| Contact import | Optional convenience, never a requirement. |

---

## Not V1 At All

Beyond deferral — these should not be built until the core loop is proven and
there is real data to learn from:

- **Learned or suggested cadence.** Requires history that does not exist yet,
  and risks the rigid scoring the north star warns against.
- **Per-person tone learning.** Same problem, plus it silently changes the
  user's voice.

---

## Decisions The Engine Needs

The north star left these open. They are settled here because the resurfacing
engine cannot be written without them.

### Session Shape

A session is **at most five cards.**

Ordering, highest priority first:

1. **Replies owed** — oldest first.
2. **Follow-ups due** — due today or overdue, oldest first.
3. **Dates approaching** — birthdays and important dates within seven days.
4. **Past cadence** — most overdue first.
5. **Serendipity** — one dormant or random pick, only if slots remain.

Rules:

- People who are snoozed, paused, or archived are excluded entirely.
- A person appears at most once per session, at their highest-priority reason.
- **Soft pre-overdue**: someone at roughly 80% of their cadence is eligible for
  tier 4, but only after everyone genuinely overdue has been placed. They
  surface early only when the stack is otherwise quiet.
- A session ends when the cards run out. There is no "load more." If the user
  wants another session, the app can offer one, but it does not refill
  automatically. Small surfaces beat giant backlogs.

### What "Message" Means

The app cannot confirm that a message was actually sent. Tapping **Message**
therefore:

1. opens the native composer, prefilled where possible,
2. **optimistically** records the interaction and resets the relationship clock,
3. shows a brief undo affordance on return,
4. removes the card from the session.

Optimistic is the right default. The cost of a false positive is one slightly
early resurface. The cost of asking "did you send it?" every time is friction
in exactly the place where friction kills the product.

### The Manual Reply Queue

The north star calls unanswered replies the highest-priority failure mode, then
leaves the detection platform-dependent. The fallback is not optional and is
not a downgrade — it is the baseline:

> **"I owe someone a reply" is a capture type.**

It is one tap from quick capture, takes a person and nothing else, and always
sorts into tier 1. If a platform later supplies real unread detection, it feeds
the same queue. The product works without it.

### Snooze Durations

Fixed, small set. No date picker in the primary flow:

- a few days,
- next week,
- next month,
- not for a while (the pause case).

If a person is snoozed repeatedly, the card may mention it quietly. It does not
scold, and it does not block snoozing again.

---

## Instrumentation

An **append-only event log**, written from the first day, with no UI in V1.

This is cheap now and impossible to reconstruct later. Without it the north
star metric cannot be measured retroactively.

Every event records: id, timestamp, type, person, session, and a small payload.

Event types:

- `person_added`
- `capture_created`
- `person_surfaced` (with the tier that surfaced them)
- `action_taken` (message, schedule, snooze, connected)
- `session_started` / `session_completed`
- `notification_sent` / `notification_opened`

The metric this answers:

> **Did the app cause a relationship interaction that probably would not have
> happened otherwise?**

Concretely: the share of surfaced people acted on, and the count of
interactions whose chain begins at a `person_surfaced` or `capture_created`
event.

Events are never deleted, including when a person is archived.

---

## Things Not To Let Slip

Small, cheap, and easy to drop under deadline pressure — and they are most of
what separates this from a reminders app:

- **The serendipity pick.** One slot. It is the only mechanism that reaches
  dormant relationships, which is where the biggest wins are.
- **The soft pre-overdue window.** Contact should feel spontaneous, not
  triggered by a deadline.
- **The no-guilt tone.** No red counters, no overdue badges, no failure
  language. This is a hard constraint, not a polish item.
- **Completion feel.** The small animation at the end of a session is the
  reward that makes the next session happen.
- **Contact picker over typing.** On iOS a single-contact picker needs no
  address-book permission, so "manual entry" can mean tapping a name. Lower
  friction at onboarding, no privacy cost.
