# Auto-Suggest Save

When the user has NOT explicitly said "save", Claude may suggest saving — but never auto-save.

## When to suggest

Suggest only if ALL are true:

- The session involved substantial work on a tracked project (not just a quick question).
- Significant decisions, progress, or plans were discussed.
- The user hasn't already triggered a save during this session.
- The conversation seems to be wrapping up: user says "thanks", "that's it", "done for now", "wrap up", "before I quit", or similar closure cues.

## How to suggest

> "We covered a lot today on [project]. Want me to save this to the brain before we wrap up?"

If the user says yes, run the standard save flow. If no or no answer, don't bring it up again unless the conversation truly wraps up later.

## Why this is a suggestion only

Auto-save without explicit confirmation violates the project's "explicit-trigger only" invariant — see `CLAUDE.md`. The cost of suggesting is one short prompt; the cost of auto-saving the wrong thing is silent persistence of misleading context.
