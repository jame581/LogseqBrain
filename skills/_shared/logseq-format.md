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

## Content-generation invariants (compose-time)

The survival rules above are about *editing* existing content. These rules are about *composing* the text in the first place. Each one prevents Logseq from silently turning ordinary prose into a **phantom page** (an empty auto-created page) or a **broken macro**. Apply them whenever a brain skill writes a session log, decision, plan entry, or journal line.

1. **Inline code uses backticks — NEVER `{{ }}`.** In Logseq `{{ }}` is *macro* syntax (`{{query …}}`, `{{embed …}}`). A graph with no custom macros (`:macros {}`, the default) renders `{{anything}}` as a broken/empty macro. Wrap identifiers, code, file:line refs, CSS rules, and DB queries in backticks: write `` `priceCheckerHasPicture` ``, `` `db.Rebate.countDocuments({ flowState: 2 })` ``, `` `Content/Products.css:225-229` `` — never `{{priceCheckerHasPicture}}`. If the snippet itself contains a backtick, fence it with double backticks: `` `` Expression`1.Compile `` ``.
2. **Escape `#` before a number or hex color.** A bare `#44`, `#6`, or `#0066CC` becomes a tag → an empty page named `44` / `6` / `0066CC`. When `#` is literal text (PR/issue numbers, hex colors, "step #3"), wrap it in backticks: `PR `#44``, `` `#0066CC` ``. A *real* tag is written `#[[Page Name]]` (the `tags::` property form), not a bare `#word`.
3. **Page links to tasks/projects must be namespaced.** Write `[[Tasks/CRMGM-1234]]` and `[[Projects/Name]]` — never bare `[[CRMGM-1234]]`. A bare link points at a *different*, non-existent page (`CRMGM-1234`) than the real file (`Tasks/CRMGM-1234`), creating a phantom duplicate. Match the namespace to the `___` in the target filename.
4. **Local file paths are markdown links or code — never `[[file:// ]]`.** `[[file:///C:/…/design.md]]` makes a phantom page titled with the whole path. Use a markdown link `[design.md](file:///C:/…/design.md)` or backtick the path.
5. **Don't link a description or a memory slug.** `[[2026-04-16: Fixed 5.7h half-life]]` or `[[feedback_user_builds_locally]]` create junk pages. Reference decisions in prose; never bracket a sentence-like string or an internal slug.

These are detected and repaired by `brain-doctor` (see `skills/brain-doctor/SKILL.md`); following them at compose-time is what keeps a graph from needing the doctor.

## Why this matters

The plugin's whole value is cross-device continuity via Logseq Sync. Files we write get opened, normalized, and synced by Logseq on other devices before we touch them again. Surgical Read-before-Edit (rules above) is what keeps our writes correct and conflict-safe across that round-trip. Compose-time invariants keep the graph itself clean — free of the phantom pages and broken macros that accumulate invisibly until you open the graph in Logseq.
