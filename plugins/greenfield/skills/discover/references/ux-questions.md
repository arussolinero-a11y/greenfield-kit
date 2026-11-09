# Mandatory UX/UI questions (Phase 0C)

Ask every question. If one doesn't apply, record `N/A — <reason>`. Default accessibility target: **WCAG 2.1 AA**.

| Topic | Questions | Conversational variant (chat, WhatsApp, voice) |
|---|---|---|
| User and context | Who uses it, on what device, in what situation (in a hurry, on the street, at a desk)? Digital literacy? Language and register (formal/informal)? | Same, plus: which channel and what time of day? |
| Key tasks | What are the 3 tasks the user **must** accomplish? What's the "aha moment"? | Which 3 conversations must succeed end to end? |
| Platform | Web, mobile, desktop, chat or voice? Responsive? Offline? | Channel limits (e.g., WhatsApp: max 3 buttons per message, 24-hour window) |
| Brand | Existing brand (logo, colors, typography)? 3 personality adjectives? References they like and **anti-references**? | Bot persona: name, personality, what it never says |
| Content and tone | Brand voice? Who writes the copy? Microcopy for errors and empty states? | Message length, emoji policy, greeting and sign-off |
| Flows | Onboarding? Happy path for each key task? What happens when something fails? | Fallback when the bot doesn't understand; handoff to a human |
| States | Empty, loading, error, success, no permission? | Waiting, misunderstanding, out-of-hours, escalated |
| Accessibility | Contrast, keyboard, screen readers, reduced motion | Plain language, no information only in images, voice alternatives |
| Design system | Existing component library (e.g., shadcn/ui)? Tokens (colors, spacing, typography)? Dark mode? | Reusable message templates and quick replies |
| Measurement | Which UX metric shows it works (completion rate, time on task, drop-off)? | Conversation completion, handoff rate, drop-off point |
| Constraints | Technical, legal or platform limits? | Consent and data-retention rules for chat transcripts |
