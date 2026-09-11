# map.awk — digest Map computation and checks (skills/_shared/digest.md contract).
#   -v rel=REL -v nonl=0|1 -v today=yyyy-MM-dd -v archive="[[Projects/X/SessionArchive]]"|"" -v mode=report|lint
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
  budget = 800 - OTHER - length(PREFIX) - length("Map: ") - 1 - length(tail)
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
function compute(   T, T2, txt, n, base, ins) {
  base = TOTAL - (ML ? length(L[ML]) : 0); ins = ML ? 0 : 1
  T = TOTAL
  for (n = 0; n < 10; n++) {
    txt = map_text(T)
    T2 = base + length(PREFIX "Map: " txt CRSUF) + ins
    if (fig(T2) == fig(T)) break
    T = T2
  }
  NEWTOTAL = T2
  return txt
}

function setup_digest(   i, t, fb) {
  ML = 0; fb = 0; IP = SL[KD]
  for (i = SL[KD] + 1; i <= SE[KD]; i++) {
    if (FENCE[i]) continue
    t = cr(L[i])
    if (!fb && t ~ /^[ \t]*- /) fb = i
    if (!ML && t ~ /^[ \t]*- Map:/) ML = i
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
  else { n = split(OLDTXT, parts, ", "); out = " · separator \",\" (expected \" · \")" }
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
  if (!ML) { print "map: missing"; print "computed: " MAPTXT; bad = 1 }
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

function lint_findings(   errs, pk, p, d1, d2, i, det) {
  errs = 0
  if (!ISB) return 0
  if (!KD) { printf "%s:%d\tmissing-digest\twarn\tno ## Digest section\n", rel, 1; return 0 }
  if (!ML) { printf "%s:%d\tmissing-digest\terror\t## Digest has no Map line — run brain digest --apply\n", rel, SL[KD]; errs++ }
  else if (OLDTXT != MAPTXT) {
    det = stale_details(); sub(/^ · /, "", det)
    printf "%s:%d\tstale-map\terror\t%s\n", rel, ML, det; errs++
    for (i = 1; i <= NLB; i++) { printf "%s:%d\tmap-label\terror\t\"%s\" matches no heading\n", rel, ML, LB[i]; errs++ }
  }
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
  if (KD) setup_digest()
  if (mode == "lint") exit lint_findings()
  exit report()
}
