printf '%s\n' 'type:: project' 'status:: active' 'last-updated:: 2026-09-10' 'focus:: ship it' 'next:: test' 'digest-updated:: 2026-08-01' '- ## Digest' '  - x' > pages/Projects___A.md
printf '%s\n' 'type:: task-index' 'status:: active' '- ## CRMGM Tasks' '  - x' > pages/Projects___A___Tasks.md
printf '%s\n' 'type:: session-archive' '- ## Archived Session Log' > pages/Projects___A___SessionArchive.md
printf '%s\n' 'status:: done' 'last-updated:: 2026-05-01' '- ## Notes' > pages/Tasks___T1.md
printf 'status:: blocked\nlast-updated:: 2026-08-01\nopen:: waiting\ton infra\n- ## Notes\n' > pages/Tasks___T2.md
printf '%s\n' '- ## Notes' '  - no props' > pages/Tasks___T3.md
