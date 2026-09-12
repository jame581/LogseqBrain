# map.awk — digest Map computation and checks (skills/_shared/digest.md contract).
#   -v rel=REL -v nonl=0|1 -v today=yyyy-MM-dd -v archive="[[Projects/X/SessionArchive]]"|"" -v mode=report|lint|apply
BEGIN { SEP = " · " }
{ L[++N] = $0 }

function cnt(k) {
  if (SD[k] > 0 && SD[k] >= SC[k]) {
    if (SH[k] == "Session Log") return " (" SD[k] " entries)"
    if (SH[k] == "Decisions") return " (" SD[k] ")"
  }
  return ""
}

# CK[1..C]: sections >= 1 KiB, largest first (ties keep file order). NN/NB: the rest.
# WID[k]: label width, widened pairwise until no two candidate labels collide.
function candidates(   k, i, j, t, a, b, changed) {
  C = 0; NN = 0; NB = 0
  for (k = 1; k <= NS; k++) {
    if (k == KD) continue
    if (SB[k] >= 1024) CK[++C] = k
    else { NN++; NB += SB[k] }
  }
  for (i = 2; i <= C; i++) {
    t = CK[i]
    for (j = i - 1; j >= 1 && SB[CK[j]] < SB[t]; j--) CK[j + 1] = CK[j]
    CK[j + 1] = t
  }
  for (i = 1; i <= C; i++) WID[CK[i]] = 40
  changed = 1
  while (changed) {
    changed = 0
    for (i = 1; i <= C; i++) for (j = i + 1; j <= C; j++) {
      a = CK[i]; b = CK[j]
      if (label(SH[a], WID[a]) == label(SH[b], WID[b]) && (WID[a] < length(SH[a]) || WID[b] < length(SH[b]))) {
        WID[a]++; WID[b]++; changed = 1
      }
    }
  }
}

function clause(k) { return label(SH[k], WID[k]) " | " fig(SB[k]) cnt(k) }

# Map text for page total T. Reserves the fixed tail and the worst-case "+N more" up front
# (digest.md "Fitting the 800-byte cap"), then keeps candidates largest-first; never fewer than one.
function map_text(T,   tail, budget, run, i, cost, kept, out) {
  tail = ""
  if (NN >= 1) tail = "+" NN " smaller sections, " fig(NB)
  if (archive != "") tail = tail (tail != "" ? SEP : "") "Archive | " archive
  tail = tail (tail != "" ? SEP : "") "page | " fig(T)
  budget = 800 - OTHER - length(PREFIX) - length("Map: ") - 1 - length(CRSUF) - length(tail)
  if (C > 1) budget -= length("+" (C - 1) " more") + length(SEP)
  run = 0; kept = 0; out = ""
  for (i = 1; i <= C; i++) {
    cost = length(clause(CK[i])) + length(SEP)
    if (kept > 0 && run + cost > budget) break
    out = out clause(CK[i]) SEP; run += cost; kept++
  }
  if (kept < C) out = out "+" (C - kept) " more" SEP
  return out tail
}

# The page figure measures the file the new Map line is part of: iterate until it is stable.
# Within ~2 bytes of a KiB boundary there is no stable value — "1023 B" is 2 bytes longer than
# "1 KB", so the total flips between the two and the iteration enters a 2-cycle (base=1019:
# 1021 → 1025 → 1023 → 1025 → …). CONV records whether the figure finally used is the one the
# finished file would actually measure; a figure that is known-wrong is never written (§5, §8).
function compute(   T, T2, txt, n, base, ins) {
  base = TOTAL - (ML ? length(L[ML]) : 0); ins = ML ? 0 : 1
  T = TOTAL; CONV = 0
  for (n = 0; n < 10; n++) {
    txt = map_text(T)
    T2 = base + length(PREFIX "Map: " txt CRSUF) + ins
    if (fig(T2) == fig(T)) { CONV = 1; break }
    T = T2
  }
  return txt
}

function setup_digest(   i, t, fb) {
  ML = 0; NMAP = 0; fb = 0; IP = SL[KD]
  for (i = SL[KD] + 1; i <= SE[KD]; i++) {
    if (FENCE[i]) continue
    t = cr(L[i])
    if (!fb && t ~ /^[ \t]*- /) fb = i
    # Count them, don't just bind the first: a duplicated block is a realistic Logseq Sync conflict
    # artifact, and emit_file() would rewrite the first Map line and leave the second one stale.
    if (t ~ /^[ \t]*- Map:/) { NMAP++; if (!ML) ML = i }
    if (t != "") IP = i
  }
  PREFIX = "  - "
  if (ML) { match(L[ML], /^[ \t]*- /); PREFIX = substr(L[ML], 1, RLENGTH) }
  else if (fb) { match(L[fb], /^[ \t]*- /); PREFIX = substr(L[fb], 1, RLENGTH) }
  CRSUF = ""
  if ((ML && L[ML] ~ /\r$/) || (!ML && fb && L[fb] ~ /\r$/)) CRSUF = "\r"
  OTHER = SB[KD] - (ML ? lbytes(ML) : 0)
  candidates()
  MAPTXT = compute()
  OLDTXT = ""
  if (ML) { OLDTXT = cr(L[ML]); sub(/^[ \t]*- Map:[ ]?/, "", OLDTXT) }
}

function find_label(lab,   k, p, n, hit) {
  for (k = 1; k <= NS; k++) if (k != KD && SH[k] == lab) return k
  for (k = 1; k <= NS; k++) if (k != KD && (k in WID) && label(SH[k], WID[k]) == lab) return k
  p = lab; sub(/…$/, "", p); n = 0
  if (p != lab) for (k = 1; k <= NS; k++) if (k != KD && index(SH[k], p) == 1) { n++; hit = k }
  return (n == 1) ? hit : 0
}

# Clause-by-clause comparison of the existing Map against measurement. Sets NLB/LB[] (unknown labels).
function stale_details(   n, parts, i, c, lab, fc, k, want, out, pos) {
  out = ""; NLB = 0
  if (index(OLDTXT, SEP)) n = split(OLDTXT, parts, SEP)
  else if (index(OLDTXT, ", ")) { n = split(OLDTXT, parts, ", "); out = " · separator \",\" (expected \" · \")" }
  else { n = 1; parts[1] = OLDTXT }
  for (i = 1; i <= n; i++) {
    c = parts[i]; pos = index(c, " | ")
    if (!pos) continue
    lab = substr(c, 1, pos - 1); fc = substr(c, pos + 3)
    if (lab == "Archive" || lab ~ /^\+/) continue
    if (lab == "page") want = fig(TOTAL)
    else {
      k = find_label(lab)
      if (!k) { LB[++NLB] = lab; out = out " · \"" lab "\" matches no heading"; continue }
      want = fig(SB[k]) cnt(k)
    }
    if (fc != want) out = out " · " lab " | " fc " → " want
  }
  if (out == "") out = " · format differs from computed"
  return out
}

function propbytes(   i, b) { b = 0; for (i = 1; i <= PROP_END; i++) b += lbytes(i); return b }

function report(   i, k, bad, d1, d2, dr, p, pk) {
  bad = 0
  for (i = 1; i <= PROP_END; i++) print cr(L[i])
  if (!ISB) {
    print "--"; print "digest: not applicable (not a digest-bearing page)"
    printf "coverage: read properties (%s of %s)\n", hb(propbytes()), hb(TOTAL)
    return 0
  }
  if (!KD) {
    print "--"; print "digest: missing"
    print "line\tend\tbytes\tentries\theading"
    for (k = 1; k <= NS; k++) printf "%d\t%d\t%d\t%s\t%s\n", SL[k], SE[k], SB[k], (SD[k] ? SD[k] : "-"), SH[k]
    print "staleness: " staleness(PROP["last-updated"], PROP["status"], PROP["type"], rel ~ /^pages\/Tasks___/)
    printf "coverage: read properties + section table (%s of %s)\n", hb(propbytes()), hb(TOTAL)
    return 1
  }
  for (i = SL[KD]; i <= SE[KD]; i++) print cr(L[i])
  print "--"
  if (NMAP > 1) {
    printf "map: duplicated — ## Digest has %d \"- Map:\" lines; delete all but one with Edit, then rerun\n", NMAP
    bad = 1
  }
  else if (!CONV) {
    print "map: page figure does not converge — the page total sits within 2 bytes of a 1 KB boundary, where no figure measures the file it is part of; --apply refuses until a byte is added or removed"
    bad = 1
  }
  else if (!ML) { print "map: missing"; print "computed: " MAPTXT; bad = 1 }
  else if (OLDTXT == MAPTXT) print "map: ok"
  else { print "map: stale" stale_details(); print "computed: " MAPTXT; bad = 1 }
  printf "digest: %d B of 800 B cap\n", SB[KD]
  if (SB[KD] > 800) { printf "over: digest prose over cap by %d B (digest %d B > 800 B cap)\n", SB[KD] - 800, SB[KD]; bad = 1 }
  split("focus next open", pk, " ")
  for (p = 1; p <= 3; p++) if ((pk[p] in PROP) && length(PROP[pk[p]]) > 120) {
    printf "over: %s:: %d B > 120 B\n", pk[p], length(PROP[pk[p]]); bad = 1
  }
  d1 = days(PROP["digest-updated"]); d2 = days(PROP["last-updated"])
  if (d1 >= 0 && d2 >= 0) {
    dr = d2 - d1
    printf "drift: %s (digest-updated %s, last-updated %s)%s\n", dd(dr), PROP["digest-updated"], \
      PROP["last-updated"], (dr > 30 ? " — over 30: suggest a rebuild" : "")
  } else print "drift: unknown (missing digest-updated:: or last-updated::)"
  print "staleness: " staleness(PROP["last-updated"], PROP["status"], PROP["type"], rel ~ /^pages\/Tasks___/)
  printf "coverage: read properties + ## Digest (%s of %s)\n", hb(propbytes() + lbytes(SL[KD]) + SB[KD]), hb(TOTAL)
  return bad
}

# Apply: the file with only the Map line replaced (or inserted after IP), final-newline status preserved.
function emit_file(   i, M, nl) {
  nl = PREFIX "Map: " MAPTXT CRSUF
  M = 0
  for (i = 1; i <= N; i++) {
    if (i == ML) { O[++M] = nl; continue }
    O[++M] = L[i]
    if (!ML && i == IP) O[++M] = nl
  }
  for (i = 1; i <= M; i++) { printf "%s", O[i]; if (i < M || !NONL) printf "\n" }
}

function lint_findings(   errs, pk, p, d1, d2, i, det) {
  errs = 0
  if (!ISB) return 0
  if (!KD) { printf "%s:%d\tmissing-digest\twarn\tno ## Digest section\n", rel, 1; return 0 }
  if (!ML) { printf "%s:%d\tmissing-digest\terror\t## Digest has no Map line — run brain digest --apply\n", rel, SL[KD]; errs++ }
  else if (!CONV) {
    printf "%s:%d\tnonconvergent-map\terror\tpage figure does not converge — the total sits within 2 bytes of a 1 KB boundary; add or remove a byte\n", rel, ML; errs++
  }
  else if (OLDTXT != MAPTXT) {
    det = stale_details(); sub(/^ · /, "", det)
    printf "%s:%d\tstale-map\terror\t%s\n", rel, ML, det; errs++
    for (i = 1; i <= NLB; i++) { printf "%s:%d\tmap-label\terror\t\"%s\" matches no heading\n", rel, ML, LB[i]; errs++ }
  }
  if (NMAP > 1) { printf "%s:%d\tduplicate-map\terror\t## Digest has %d \"- Map:\" lines — delete all but one\n", rel, ML, NMAP; errs++ }
  if (SB[KD] > 800) { printf "%s:%d\toversized-digest\terror\tdigest %d B > 800 B — digest prose over cap by %d B\n", rel, SL[KD], SB[KD], SB[KD] - 800; errs++ }
  split("focus next open", pk, " ")
  for (p = 1; p <= 3; p++) if ((pk[p] in PROP) && length(PROP[pk[p]]) > 120) {
    printf "%s:%d\toversized-digest\terror\t%s:: %d B > 120 B\n", rel, PROPLINE[pk[p]], pk[p], length(PROP[pk[p]]); errs++
  }
  d1 = days(PROP["digest-updated"]); d2 = days(PROP["last-updated"])
  if (d1 >= 0 && d2 >= 0 && d2 - d1 > 30)
    printf "%s:%d\tstale-digest\twarn\tdigest-updated %s is %d days behind last-updated %s\n", rel, \
      PROPLINE["digest-updated"], PROP["digest-updated"], d2 - d1, PROP["last-updated"]
  return errs > 0
}

END {
  NONL = nonl; scan(); scan_props()
  ISB = bearing(rel)
  KD = 0
  for (k = 1; k <= NS; k++) if (SH[k] == "Digest") { KD = k; break }
  if (mode == "apply") {
    if (!ISB) { print "brain: not a digest-bearing page: " rel > "/dev/stderr"; exit 2 }
    if (!KD) { print "brain: no ## Digest section in " rel " — write the prose slots with Edit first" > "/dev/stderr"; exit 2 }
  }
  if (KD) setup_digest()
  if (mode == "apply") {
    if (NMAP > 1) {
      printf("brain: %s — ## Digest has %d \"- Map:\" lines; delete all but one with Edit, then rerun\n", rel, NMAP) > "/dev/stderr"
      exit 2
    }
    if (!CONV) {
      printf("brain: %s — the page figure does not converge: the total sits within 2 bytes of a 1 KB boundary, where no Map line measures the file it is part of. Add or remove a byte of digest prose and rerun.\n", rel) > "/dev/stderr"
      exit 2
    }
    emit_file(); exit 0
  }
  if (mode == "lint") exit lint_findings()
  exit report()
}
