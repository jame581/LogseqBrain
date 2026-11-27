# An --also page whose name holds sed syntax (#, &) is over cap: the refusal must name it.
save_fixture
f='pages/Projects___C#&x.md'
{ sed -n '1,/^next:: /p' pages/Projects___Dig.md; pad_line 'open:: ' 900; sed '1,/^next:: /d' pages/Projects___Dig.md; } > "$f"
sf_begin Projects/Dig --also "$f"
