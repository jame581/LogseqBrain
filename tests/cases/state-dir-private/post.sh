for d in "$TMPDIR"/logseq-brain-*; do
  # Git Bash's chmod cannot set NTFS ACLs; there %TEMP% is already per-user, so only the name is checked.
  case $(uname -s) in MINGW*|MSYS*|CYGWIN*) continue ;; esac
  case $(ls -ld "$d") in drwx------*) ;; *) echo "state dir not private: $(ls -ld "$d")"; exit 1 ;; esac
done
[ -d "$TMPDIR/logseq-brain" ] && { echo "shared state dir still used"; exit 1; }
exit 0
