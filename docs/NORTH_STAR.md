# Relationship Resurfacing App — Product North Star

## Working Concept

A lightweight relationship-maintenance app for people who genuinely care about others but struggle to consistently reply, initiate, and follow up at the right time.

The app exists to close the gap between how much someone cares about people and how consistently that care is visible to them.

---

## The Problem

The core problem is not a lack of caring.

It is a breakdown between:

- thinking of someone,
- remembering to reply,
- having the bandwidth to engage right now,
- following up on something important later,
- and noticing when a relationship has quietly gone dormant.

A common failure loop looks like this:

1. A message arrives.
2. The user thinks, "I'll answer later."
3. The message disappears from active attention.
4. More unread messages accumulate.
5. The unread pile starts to feel like a project.
6. Guilt and avoidance grow.
7. The user eventually wants to contact that person about something new.
8. They reopen the thread, see the old unanswered message, feel worse, and sometimes avoid reaching out again.

The same pattern affects initiation:

1. The user cares about someone.
2. Nothing prompts that person back into active attention.
3. Weeks or months pass.
4. The other person may interpret the silence as indifference.
5. The relationship gradually weakens.

The product should interrupt those loops before they become relationship damage.

---

## Primary User

The first user is the creator.

Someone who:

- cares deeply about friends and family,
- is prone to "I'll reply later" behavior,
- benefits from external memory cues,
- often remembers people at inconvenient times,
- dislikes feeling forced into a conversation immediately,
- enjoys systems, progress, and lightweight gamification,
- wants to become more proactive in relationships,
- and wants technology to carry more of the remembering burden.

The initial product should optimize ruthlessly for this user rather than trying to serve every possible relationship-management use case.

---

## Product Promise

> Help me show people that I care at the moments when my brain would otherwise let the relationship disappear.

A simpler internal framing:

> **Remember the people for me. Bring them back at the right time. Make acting easy.**

---

## Core Loop

**Capture → Resurface → Act → Forget About It Again**

### 1. Capture

When the user thinks of someone or learns something worth remembering, capture it before the thought disappears.

Examples:

- "Marcus has an interview Thursday. Ask him how it went."
- "I should text Chris sometime."
- "Sarah is moving next month."
- "Dad's birthday is coming up."
- "I've been thinking about Andre."

Capture should support:

- text,
- voice,
- quick-access widget/shortcut,
- lightweight manual categories when needed.

The ideal interaction should take seconds.

### 2. Resurface

The system brings people back into attention when appropriate.

A person may resurface because:

- the user owes them a reply,
- they are approaching or beyond their desired contact cadence,
- a future follow-up is due,
- a birthday or important date is approaching,
- the relationship has been dormant for a long time,
- the user explicitly snoozed them,
- or the system occasionally selects an older/random connection worth rekindling.

Replies take priority over initiation.

### 3. Act

The user deals with one person at a time.

Primary actions:

- Message
- Schedule for later
- Snooze
- Mark connected

Secondary controls may include:

- pause,
- archive,
- pin,
- context,
- AI draft.

### 4. Forget About It Again

Once the user acts, the system should carry the relationship memory forward.

The user should not need to maintain a mental backlog.

---

## How the User Gets Pulled In

Resurfacing only works if the app reaches the user. A stack the user has to
remember to open is a to-do list, and the product exists because the user does
not reliably remember.

The commitment is therefore:

> **One calm notification per day, at a time the user chooses.**

Not one per person. Not one per overdue relationship. Not a badge count that
grows.

The notification should describe the session, not the backlog. "A few people to
catch up on" rather than "7 overdue." If the user ignores it, the next day's
notification is identical in tone. The app does not escalate.

Time-critical items (a birthday today, a follow-up the user asked to be
reminded about at a specific time) may justify a second notification. Nothing
else does.

---

## Core Product Insight

The app must separate:

> "I am thinking about this person"

from

> "I am available to have a conversation right now."

These are not the same state.

A central behavior is therefore:

> **Write now, send later.**

Scheduled sending is not just a convenience feature. It provides emotional distance from the anticipation of an immediate reply.

The user should be able to write a message while they have the motivation and clarity, schedule it hours or days later, and move on.

---

## Core Product Surfaces

### 1. Resurface Stack

The primary experience.

One person at a time.

The interaction should feel lightweight and satisfying, with enough momentum that the user naturally thinks:

> "Okay, one more."

Then suddenly the short session is complete.

Each card should remain visually simple.

Primary actions:

- Message
- Schedule later
- Snooze
- Mark connected

Optional context should be available without cluttering the default card.

A small completion animation and visible session progress can provide a rewarding feedback loop.

### 2. Reply Queue

This is the highest-priority relationship failure mode.

Replies should be surfaced before initiation opportunities.

Desired behavior:

- oldest unanswered message first,
- show the actual unanswered content when technically possible,
- user can draft a response in-app when possible,
- AI drafting is available only when requested,
- response may be sent immediately or scheduled for later.

The app should not label old replies as failures or create a special guilt-heavy "rescue" mode.

### 3. Quick Capture

Accessible with minimal friction from:

- the app,
- a home-screen widget,
- a lock-screen shortcut where supported,
- text input,
- voice input.

Natural-language capture is the ideal experience.

Example:

> "Ask Marcus how the interview went Thursday night."

The app should infer, where possible:

- person,
- type of note,
- due date,
- follow-up timing.

If automatic classification is uncertain, the user can manually choose a lightweight category.

Initial categories:

- Follow-up
- Birthday / important date
- Note about person
- Reach out later
- Relationship cadence

### 4. Outbox

All scheduled future messages live here.

The user should be able to:

- see queued messages,
- edit them,
- cancel them,
- see when they are expected to send.

Once scheduled, messages should require as little additional intervention as platform limitations allow.

---

## Relationship Memory

Each tracked person should have a lightweight profile.

Minimum fields:

- name,
- relationship intent,
- desired contact cadence.

Optional fields:

- birthday,
- timezone,
- notes,
- important dates,
- follow-ups,
- pinned status,
- pause/archive state.

The system may distinguish between relationship intents such as:

- Invest
- Maintain
- Keep warm

These should influence resurfacing frequency but should not become rigid scoring systems.

---

## Contact Cadence

Cadence should be person-specific.

The user should retain the ability to choose the cadence manually.

The app may later suggest or learn cadence, but that is not required for the first useful version.

People should begin resurfacing softly before they become fully overdue.

The system should also occasionally resurface older or random connections even when no cadence was explicitly set.

This serendipity is important because it can convert a fading relationship into a rekindled one.

---

## Manual Interaction Reset

Automatic interaction detection may not always be possible.

The app therefore needs a one-tap:

> **We connected**

action.

It resets the relationship clock regardless of whether the interaction happened through:

- iMessage,
- WhatsApp,
- Instagram,
- phone,
- in person,
- or another channel.

Do not require the user to categorize the interaction.

---

## Snooze, Pause, Archive

These are different concepts.

### Snooze

"Not now. Bring this person back later."

Minimal friction. The app chooses when to reintroduce them.

If repeatedly snoozed, the app may gently indicate that they have been snoozed before.

### Pause

"Do not resurface this person for a longer period."

### Archive

"Keep the history, but remove this person from active rotation."

---

## Messaging Philosophy

The app should minimize the number of decisions between intention and sending.

Desired behavior:

- compose now,
- schedule for later,
- auto-send when technically possible,
- retain an editable outbox,
- support fuzzy timing such as:
  - later today,
  - tomorrow,
  - this weekend,
  - sometime next week.

The system should avoid obviously bad send times.

Timezone should be stored per person where relevant.

Longer-term, the app may learn preferred send windows.

---

## AI Role

AI should assist, not dominate.

AI is explicitly user-invoked.

### Useful AI behaviors

- parse natural-language captures,
- draft a message from a follow-up,
- provide two natural message variations,
- use a global representation of the user's texting style,
- optionally draw from anonymized example conversations supplied by the user.

### AI should not

- constantly suggest replies,
- over-explain why someone should be contacted,
- autonomously judge relationship quality,
- silently adapt messaging style based on every edit,
- create unnecessary complexity.

---

## Tone and Emotional Design

The app must reduce guilt rather than amplify it.

Avoid:

- red overdue counters,
- shame-based notifications,
- relationship "grades,"
- language implying failure,
- giant backlogs,
- accusatory reminders.

Prefer:

- calm resurfacing,
- small batches,
- one person at a time,
- forgiving language,
- easy snooze,
- visible progress,
- satisfying completion.

The product should feel like a memory assistant, not a relationship manager.

---

## Gamification

Gamification should remain subtle.

Useful:

- visible session progress,
- small completion animation,
- lightweight stats,
- satisfying "session complete" moment.

Avoid:

- excessive badges,
- competitive scores,
- friendship points,
- manipulative streak pressure.

The goal is to make the maintenance loop pleasant enough that the user wants to handle one more person.

---

## Stats

Stats are secondary to the relationship loop, but useful.

First-pass metrics:

- people contacted,
- initiations vs replies,
- average time between contacts,
- overdue replies cleared,
- scheduled messages sent,
- relationships kept within desired cadence,
- dormant relationships rekindled.

Stats should be descriptive, not judgmental.

---

## Onboarding

Do not ask the user to set up their entire social universe.

Initial onboarding:

1. Add first 5 people.
2. For each, enter:
   - name,
   - relationship intent,
   - rough contact cadence.
3. Everything else is optional.

Manual entry is the default.

Contact import may be offered as an optional convenience.

---

## MVP

A useful first version should prove that resurfacing itself changes behavior.

That test is narrower than the full feature set below. The first build is
specified separately in [V1 Scope](V1_SCOPE.md); this section describes the
complete MVP the product is aiming at, not the first thing to be built.

### Required

- manually add people,
- relationship cadence,
- relationship intent,
- resurface stack,
- reply and initiate as separate concepts,
- one-tap "we connected,"
- snooze,
- pause,
- archive,
- quick capture,
- follow-up reminders,
- birthdays / important dates,
- scheduled-message outbox,
- basic notes/context,
- basic stats,
- AI drafting on demand,
- two natural draft options.

### Strongly Desired

- fuzzy send scheduling,
- timezone-aware send windows,
- home/lock-screen quick capture,
- random dormant-contact resurfacing,
- pinned people,
- search by name and notes.

---

## Platform-Dependent Capabilities

These should be investigated before being treated as architecture assumptions.

- detecting unread or unanswered iMessage conversations,
- reading message content,
- detecting WhatsApp conversations,
- sending iMessages automatically,
- scheduling iMessages programmatically,
- sending WhatsApp messages automatically,
- detecting interaction history across apps,
- extracting relationship data from messages,
- background automation and notification limits,
- App Intents / Shortcuts integration.

The product must still be useful if many of these are unavailable.

---

## Non-Goals for V1

Do not build:

- group-chat management,
- a full CRM,
- a social network,
- relationship scoring,
- "relationship health" judgment,
- automatic advice about whether someone is worth keeping,
- complex AI relationship analysis,
- automatic tone learning per person,
- learned or suggested contact cadence,
- deep contact import as a requirement,
- huge dashboards,
- exhaustive communication-channel tracking.

---

## Product Principles

1. **Capture before the thought disappears.**
   The user should never have to trust themselves to remember later.

2. **Separate intention from availability.**
   Thinking of someone does not mean the user wants a conversation right now.

3. **Make replying easier than postponing.**
   Every extra step gives the message another chance to disappear.

4. **Small surfaces beat giant backlogs.**
   One person at a time.

5. **Resurfacing is the product.**
   Messaging integrations improve the experience, but the core value is bringing people back into attention.

6. **Do not manufacture guilt.**
   The system exists because guilt already makes the problem worse.

7. **Let technology remember. Let the user care.**
   The user should spend their energy on the relationship, not on maintaining the system.

---

## North Star Outcome

If the product works, after one year the user should be able to say:

> "The people I care about hear from me more often. I reply before messages disappear into a pile. I initiate more relationships instead of waiting for other people to contact me. I follow up on things people tell me. Fewer friendships quietly fade because I forgot to reach out."

The product succeeds when the user's outward behavior more accurately reflects how much they actually care about the people in their life.

---

## North Star Metric

A useful initial candidate:

> **Meaningful relationship touchpoints completed because the app resurfaced or captured the opportunity.**

Supporting measures can include:

- percentage of surfaced people acted on,
- reply backlog age,
- number of proactive initiations,
- scheduled messages completed,
- dormant relationships reactivated.

The metric should ultimately answer one question:

> **Did the app cause a relationship interaction that probably would not have happened otherwise?**
