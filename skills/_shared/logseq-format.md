# Logseq Format & Normalization

When Logseq parses pages and journals that a brain skill wrote, it **normalizes** the markdown. Skills must edit against the normalized form, not against what they originally wrote. This reference documents the normalizations and the rules that survive them.

## What Logseq normalizes on parse

- **Heading bullets lose the `- ` marker.** A line we wrote as `- ## Activity` is re-serialized by Logseq as `## Activity` (no leading bullet) once the file is opened and synced.
- **Leading-space indents become tabs.** Two-space child indents (`  - foo`) are converted to a tab-indented bullet — a literal tab character before `- foo`.
- **Empty section headings are stripped.** An empty `## Sessions` heading with no children may be removed entirely.
- **Trailing whitespace and blank-line runs are collapsed.**

## Survival rules (always follow before an Edit)

1. **Read immediately before Edit.** Never build an `old_string` from remembered or previously-written content. Read the target region in the same turn as the Edit so it reflects Logseq's current normalized form.
2. **Anchor on heading text, not the bullet prefix.** Match on `## Activity` / `## Session Log` / `## Current Plan` — never assume a leading `- `. The same heading may appear as `- ## Activity` (freshly written by us) or `## Activity` (after Logseq round-trip); your anchor must tolerate both, so anchor on the `## <Name>` substring.
3. **Don't assume the indent character.** When matching child bullets, prefer the heading + first/last child you actually read rather than hardcoding two spaces vs. a tab.
4. **A missing expected heading means Logseq removed it, not corruption.** If you expected an empty `## Sessions` and it's gone, recreate it as part of the Edit rather than aborting.

## Why this matters

The plugin's whole value is cross-device continuity via Logseq Sync. Files we write get opened, normalized, and synced by Logseq on other devices before we touch them again. Surgical Read-before-Edit (rules above) is what keeps our writes correct and conflict-safe across that round-trip.
