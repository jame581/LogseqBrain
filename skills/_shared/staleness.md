# Stale-Project Rules

Detect when a project page hasn't been touched recently and surface it to the user.

## Inputs

- `last-updated::` property from the project page (a `yyyy-MM-dd` string)
- `status::` property from the project page (one of `active`, `paused`, `completed`, `archived`)
- Today's date (`yyyy-MM-dd`)

## Output

One of four staleness levels, with suggested phrasing for each:

| Days since `last-updated::` | Status filter      | Level        | Phrasing                                                                         |
|-----------------------------|--------------------|--------------|----------------------------------------------------------------------------------|
| 0–7                         | any                | fresh        | (no message)                                                                     |
| 8–14                        | any                | aging        | "Note: last updated [N] days ago."                                               |
| 15–29                       | any                | stale        | "⚠ This project hasn't been updated in [N] days. Context may be outdated — verify before acting on it." |
| 30+                         | `status:: active`  | abandoned    | "This project is marked active but hasn't been touched in [N] days. Want to update it or mark it paused?" |
| 30+                         | not `active`       | stale        | (use the stale phrasing above)                                                   |

## When to use

- `brain-load` calls staleness on the loaded project's `last-updated::`. Surfaces the message before presenting the load summary.
- `brain-status` calls staleness on every project's `last-updated::`. Annotates the dashboard line.

## Computation

`days_since = (today - last-updated)` in calendar days. Use straightforward date subtraction; no timezone gymnastics needed since dates are date-only.

If `last-updated::` is missing or malformed, treat as `aging` and log: "Project [name] has no valid `last-updated::` property — consider running brain-save to set one."
