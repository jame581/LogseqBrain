printf '%s\n' 'status:: active' '- ## Notes' '  - x' > pages/Tasks___CRMGM-1234.md
cat > journals/2026_09_10.md <<'EOF'
- ## Sessions
  - uses {{IMProxy}} and {{query (todo now)}} fine
  - see [[CRMGM-1234]] and [[Tasks/CRMGM-1234]] and [[file:///C:/x.md]]
  - spec at [design](docs/specs/x.md) and [web](https://example.com) and [a](assets/p.png)
  - h3. Shrnutí
  - [~jan.m] please check {code}x{code}
  - ```
    h3. inside a fence is fine {{x}}
    ```
  - new-key:: once
  - status:: twice
EOF
