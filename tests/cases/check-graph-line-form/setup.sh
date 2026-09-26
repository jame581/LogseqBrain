printf '%s\n' '- ## Notes' '  - n' > pages/Notes.md
sh "$BRAIN" --graph "$G" sections pages/Notes.md > /dev/null
