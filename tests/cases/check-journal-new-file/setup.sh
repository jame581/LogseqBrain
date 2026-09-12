printf '%s\n' 'status:: active' '- ## Digest' '  - Id' > pages/Tasks___Chk.md
sh "$BRAIN" --graph "$G" sections Tasks/Chk --baseline journals/2026_09_11.md > /dev/null
printf '%s\n' '- ## Sessions' '  - [[Tasks/Nope]]: looked at it' > journals/2026_09_11.md
