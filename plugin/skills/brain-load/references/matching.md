# Project-Name Fuzzy Matching

When the user says "load X", `brain-load` must find the project page that best matches X.

## Algorithm

1. **List all candidates.** Glob for `pages/Projects___*.md` in the graph folder. Extract each project name by stripping the `Projects___` prefix and `.md` suffix.

2. **Match in order; stop at the first hit:**

   1. **Exact match:** user input equals a project name exactly.
   2. **Case-insensitive:** lowercased user input equals lowercased project name.
   3. **Normalized fuzzy:** strip all spaces, hyphens, and underscores from BOTH the user input and each project name, then compare lowercased versions. Example: `chivalric quest` → `chivalricquest` matches `ChivalricQuest` → `chivalricquest`.
   4. **Substring (normalized):** the lowercased, normalized user input is contained within a lowercased, normalized project name. Example: `quest` matches `ChivalricQuest`.

3. **No match:** list all available project names and ask the user to pick.

4. **Multiple matches at the substring step:** list the candidates and ask the user to pick.

5. **No projects exist at all:** tell the user "No projects in the brain yet. Use 'init brain project [name]' to create one."

## Notes

- Don't try Levenshtein distance or other expensive fuzzy strategies. The four-step ladder above handles the common cases (different casing, hyphens, partial names) without surprise.
- The substring step intentionally allows ambiguity — that's why the disambiguation prompt is part of the algorithm, not an error.
