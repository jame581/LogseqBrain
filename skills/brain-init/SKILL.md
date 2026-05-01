---
name: brain-init
description: >
  Set up the Claude Brain Logseq graph (first-time) or add a new project page.
  Triggers: "init brain", "setup brain", "init brain project <name>", "add
  project to brain". Don't fire for loads, saves, or status checks — those are
  handled by brain-load, brain-save, and brain-status.
---

# Brain Init

Initialize the Claude Brain Logseq graph or add a new project page to an existing graph.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`. If the resolved folder is empty or missing core files, this skill performs first-time setup (below). Otherwise it adds a new project to the existing graph.

## First-Time Graph Setup

If the graph folder is empty or missing core files, initialize it:

1. Create `logseq/config.edn` with minimal Logseq config:

```clojure
{:meta/version 1
 :preferred-format "Markdown"
 :journal/page-title-format "yyyy-MM-dd"
 :journal/file-name-format "yyyy_MM_dd"}
```

2. Create `pages/Index.md` — the master index page:

```markdown
type:: index
description:: Master index of Claude's brain — all projects and key pages

- ## Projects
  - _No projects yet. Use "init brain project [name]" to add one._
- ## Quick Links
  - [[Meta]] — preferences, working style, conventions
  - [[Decisions]] — cross-project decision log
```

3. Create `pages/Meta.md` — for storing user preferences and conventions:

```markdown
type:: meta
last-updated:: {{today}}

- ## User Preferences
  - _Add preferences as they emerge from working sessions._
- ## Conventions
  - _Add naming conventions, coding style preferences, etc._
- ## Tools & Stack
  - _Add commonly used tools, languages, frameworks._
```

4. Create `pages/Decisions.md` — cross-project decision log:

```markdown
type:: decisions
last-updated:: {{today}}

- ## Decision Log
  - _Decisions that span multiple projects or are general in nature._
```

5. Create the `journals/` directory with a `.gitkeep` file to ensure it persists in version control. Use `mkdir -p` via Bash or create `journals/.gitkeep` with the Write tool. This directory must exist before brain-save can write journal entries — do not skip this step.

Replace `{{today}}` with the current date in `yyyy-MM-dd` format.

Confirm to the user that the graph is ready and they can open it in Logseq.

After confirmation, write a journey-log entry per `skills/_shared/journey-log.md` with the activity line: `initialized graph at <graphPath>`.

## Adding a New Project

When the user wants to add a project (e.g., "add MyProject to brain", "init brain project GameDev"):

1. Determine the project name from the user's request.

2. Create the project page at `pages/Projects___<ProjectName>.md` using the template from `references/templates.md`. The triple underscore `___` is how Logseq represents the `/` namespace separator in filenames — so this page will appear as `Projects/ProjectName` in the Logseq sidebar.

3. Update `pages/Index.md` — add a link to the new project under the Projects section:
   - `[[Projects/<ProjectName>]] — <brief description>`

4. Ask the user for a brief description and any initial context for the project (tech stack, repo location, key info). Populate the Overview section.

Confirm the project page was created and remind the user they can now use "save to brain" during work sessions and "load [project]" to restore context.

After confirmation, write a journey-log entry per `skills/_shared/journey-log.md` with the activity line: `created project [[Projects/<ProjectName>]]`.

## Date Format

Always use `yyyy-MM-dd` format for dates (e.g., `2026-04-12`). This matches Logseq's journal format and sorts correctly.

## Important Notes

- All page filenames use triple underscore `___` for namespace separators (Logseq convention)
- Properties use Logseq's `key:: value` format on bullet points
- All content must be in bullet point (outliner) format — this is how Logseq works
- Links between pages use `[[Page Name]]` or `[[Namespace/Page Name]]` syntax
- When creating the `journals/` directory, use Bash (`mkdir -p`) or Write tool to ensure it exists — do not skip this step