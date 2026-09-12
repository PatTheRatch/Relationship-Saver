# Platform Feasibility

The north star lists a set of platform-dependent capabilities and says they
should be investigated before being treated as architecture assumptions. This
is that investigation. It was done late, after the first build, which is why
the first build has a channel assumption in it that does not survive contact
with how the user actually communicates.

Checked September 2026, iOS. Anything here can change with an OS release, so
re-check before building on it.

---

## Verdicts

| Capability | Verdict | Notes |
| --- | --- | --- |
| Read unread or unanswered iMessages | **No** | No API exists for third-party apps. |
| Read iMessage content | **No** | Same. |
| Read WhatsApp conversations or unread state | **No** | No API, no share-sheet route, nothing. |
| Detect interaction history across apps | **No** | Follows from the two above. |
| Open the iMessage composer, prefilled | **Yes** | `MFMessageComposeViewController`. |
| Know whether an iMessage was actually sent | **Yes** | The compose delegate reports the result. |
| Open a WhatsApp chat, prefilled | **Yes** | `whatsapp://send?phone=<intl number>&text=<encoded>`. |
| Know whether a WhatsApp message was sent | **No** | It is a hand-off. No callback, no result. |
| Auto-send anything without a user tap | **No** | Not iMessage, not WhatsApp, not via Shortcuts. |
| Truly scheduled background send | **No** | Confirmed still true in 2026. |
| Local notifications on a daily schedule | **Yes** | No account or entitlement needed. |
| Widgets and lock-screen quick capture | **Yes** | WidgetKit and App Intents. |
| Contact picker without address-book permission | **Yes** | Single-contact picker needs no permission. |
| Read the Messages database | **Mac only** | A separate macOS app with Full Disk Access. Not the iPhone. |

Sources: [WhatsApp deep links](https://www.appsflyer.com/blog/deep-linking/whatsapp-deep-link/),
[prefilled message format](https://app.urlgeni.us/blog/how-to-create-a-whatsapp-deep-link-with-a-pre-populated-message),
[scheduling limits on iOS](https://blueticks.co/blog/schedule-whatsapp-messages-iphone),
[Shortcuts automation limits](https://blog.routinehub.co/how-to-schedule-whatsapp-messages-with-shortcuts-and-automation-on-ios/).

---

## What this means for the product

**Resurfacing survives intact.** Everything the core loop depends on is
available: local notifications, local storage, capture, and the ability to open
the right conversation in one tap. The product thesis was never dependent on
message access, and it still is not.

**The Reply Queue stays manual, permanently.** Not as a stopgap until some
integration lands. There is no integration. "I owe someone a reply" being a
capture type is the design, and the app should stop describing it as a
fallback.

**The app is a launcher, not a messenger.** For every channel, the best
achievable interaction is: open the right conversation with the right text
already in the box, and let the user hit send. That is genuinely good. It is
the difference between four app switches and one tap.

**Channel matters, and the first build got it wrong.** The Message action was
built on `MFMessageComposeViewController`, which reaches iMessage and SMS only.
For a user whose communication is mostly WhatsApp, that button opens the wrong
app for most of their relationships. A person needs a preferred channel, and
the action needs to route on it.

**Send confirmation is channel-dependent, so optimistic recording comes back.**
The iMessage path can know whether the user sent. The WhatsApp path cannot,
because it is a hand-off with no return trip. The original scope decision to
record the interaction optimistically was therefore right, and should be
restored for every channel that cannot report a result. The undo affordance
it called for becomes necessary again rather than optional.

**"Write now, send later" cannot be fire-and-forget on iOS.** No channel
permits a background send. The honest version of the feature is: the user
writes the message while they have the motivation, the app holds it, and at the
scheduled time a notification opens the conversation with the draft already in
the box. That still delivers the thing the north star actually wanted, which is
emotional distance from the immediate reply. It does not deliver a message that
leaves without the user. Any future outbox should be designed as scheduled
drafts, not as a send queue.

---

## Not worth pursuing

**WhatsApp Business Cloud API.** It can send programmatically, but it sends
from a business number under template and opt-in rules meant for companies
messaging customers. Messages would not come from the user's own account and
would not land in the existing conversation. Wrong tool.

**Desktop automation for scheduled WhatsApp sends.** Browser extensions driving
a linked WhatsApp Web session can genuinely auto-send. It requires a computer
to be awake and logged in, it is against the spirit of the account rules, and
it moves the product off the phone where the whole loop lives.
