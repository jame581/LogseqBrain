# hints.awk — one "fix <rule>: <hint>" line per rule name read (one per line), first-seen order.
# Hints are the catalog's remediation (skills/_shared/hygiene-rules.md) cut to one line each, so a
# save can act on a finding without reading the catalog. Names not listed print nothing.
BEGIN {
  H["code-in-braces"]     = "replace {{X}} with backticks `X` (double backticks if X holds a backtick)"
  H["bare-hash-tag"]      = "backtick the token (`#44`, `C#`) or rephrase; never # directly before non-space text"
  H["unnamespaced-link"]  = "namespace the link: [[CRMGM-1234]] -> [[Tasks/CRMGM-1234]]"
  H["file-link"]          = "use a markdown link [name](file:///path) or backticks, never [[file:...]]"
  H["relative-link"]      = "keep the label and backtick the path, or use a file:/// markdown link"
  H["jira-markup"]        = "put the Jira draft verbatim in a fenced code block under a one-line pointer bullet"
  H["malformed-property"] = "key: -> key:: in the page-top property block only; inline, ask the user"
  H["broken-link"]        = "the target page does not exist: fix a typo, or keep it as a deliberate forward link"
  H["new-property-key"]   = "reuse an existing key (next-action::, open-questions::) or write it as prose"
  H["missing-digest"]     = "a Map-less digest: brain digest <page> --apply; no digest: offer a rebuild (digest.md)"
  H["stale-digest"]       = "suggest a rebuild from source (digest.md); never rebuild unconfirmed"
  H["stale-map"]          = "brain digest <page> --apply; never hand-edit the Map"
  H["map-label"]          = "brain digest <page> --apply"
  H["duplicate-map"]      = "delete all but one - Map: line with Edit, then brain digest <page> --apply"
  H["nonconvergent-map"]  = "add or remove a byte of digest prose, then brain digest <page> --apply"
  H["oversized-digest"]   = "shorten: drop the free slot, then Binding and Hazard; properties <= 120 B; never the Map"
}
$0 in H && !($0 in SEEN) { SEEN[$0] = 1; printf "fix %s: %s\n", $0, H[$0] }
