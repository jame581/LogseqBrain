# Analytics (brain stats)

Read for "brain stats", "graph analytics" or "graph activity over time" only; the dashboard never needs it.

Read-only. Exclude template stubs (`_…_` placeholder bullets) from every count.

1. **Projects and tasks:** from `brain status`. Active = `fresh` + `aging`; stale = `stale` + `abandoned` — derive both from each row's `staleness` column, never from the counts line's `(N active)` figure, which counts `status:: active` and means something else entirely.
2. **Decisions:** (a) cross-project, the entries in `pages/Decisions.md` (`brain sections Decisions`); (b) on project pages, each project's `Decisions` entry count from `brain sections <page>`. Never sum (a) and (b): cross-project decisions are deliberately duplicated. Break both down by `status::` (use `brain search "status:: superseded"` to count superseded ones).
3. **Sessions:** the sum of each project's `Session Log` entry count from `brain sections`.
4. **Activity:** bullets under `## Activity` in journals dated within the last 30 days. No helper command counts this; use a read-only shell pass over `journals/` (journal filenames sort as `yyyy_MM_dd`, so a string compare against the cutoff selects the files). `date -d` is GNU-only and `date -v` is BSD-only, so try both and fail closed — an empty cutoff would pass every journal and print an **all-time** count under a "last 30 days" label. If it prints `cutoff-unavailable`, report the activity figure as unavailable instead of the number. Match both `- ## Activity` and `## Activity`: Logseq may normalize a heading bullet to a bare heading, and a pattern matching only one form both misses its own bullets and fails to *close* the section, so other sections' bullets leak into the count. The helper's own `heading_text()` accepts both forms:
   ```
   CUTOFF=$(date -d '-30 days' +%Y_%m_%d 2>/dev/null || date -v-30d +%Y_%m_%d 2>/dev/null)
   [ -n "$CUTOFF" ] || echo cutoff-unavailable
   for f in journals/*.md; do [ "$(basename "$f" .md)" '>' "${CUTOFF:-9999_99_99}" ] && cat "$f"; done \
     | awk '/^[ \t]*(- )?## Activity/{f=1; next} /^[ \t]*(- )?## /{f=0} f && /^[ \t]*- /{n++} END{print n+0}'
   ```
5. **Present:**
   ```
   Brain stats:

   Projects: <N> (<active> active, <stale> stale)
   Tasks: <N> (<a> active, <b> blocked, <d> done, <l> legacy)
   Decisions: <P> on project pages, <X> cross-project (by status: <accepted> accepted, <superseded> superseded)
   Sessions logged: <S>
   Activity (last 30 days): <A> entries
   ```
6. **`brain activity "viewed brain stats"`**.
