# added.awk — line numbers of NEW that BASE does not account for (multiset difference, so
# moved lines are not "added" but a duplicated line is).   awk -f added.awk BASE NEW
FILENAME == ARGV[1] { C[$0]++; next }
{ if (C[$0] > 0) C[$0]--; else print FNR }
