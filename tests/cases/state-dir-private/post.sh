for d in "$TMPDIR"/logseq-brain-*; do
  case $(ls -ld "$d") in drwx------*) ;; *) echo "state dir not private: $(ls -ld "$d")"; exit 1 ;; esac
done
[ -d "$TMPDIR/logseq-brain" ] && { echo "shared state dir still used"; exit 1; }
exit 0
