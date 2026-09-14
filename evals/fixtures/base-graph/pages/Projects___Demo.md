type:: project
status:: active
created:: @TODAY-40@
last-updated:: @TODAY-02@
focus:: Polish the CSV export feature for the v1.2 release
next:: Add column selection to the export dialog
digest-updated:: @TODAY-02@

- ## Digest
  - Demo is a small web app for tracking reading lists; v1.2 adds a CSV export feature.
  - Now: export works end to end; column selection is the remaining piece.
  - Hazard: exports over 10 MB time out when built in the browser, so rows stream from the server.
  - Map: Session Log | 1 KB (5 entries) · +4 smaller sections, 684 B · page | 2 KB
- ## Overview
  - Demo is a small web app for tracking reading lists.
  - Stack: TypeScript, Node and Vitest, deployed as a single container.
  - Release v1.2 adds a CSV export feature for the whole reading list.
- ## Current Plan
  - [[Tasks/DEMO-1]]: CSV export column selection
    - status:: active
    - summary:: Let users choose which columns the export includes.
- ## Implementation
  - The export is built in `src/export/csv.ts`; rows stream through a transform.
  - The export endpoint is `GET /api/export.csv`.
- ## Decisions
  - @TODAY-10@: Export files use UTF-8 CSV
    - context:: Readers open exports in spreadsheets.
    - alternatives:: XLSX, or TSV.
    - rationale:: CSV opens everywhere and diffs cleanly.
    - status:: accepted
- ## Session Log
  - @TODAY-12@: Scaffolded the export module
    - Added `src/export/csv.ts` with a header row and RFC 4180 quoting.
    - Wrote unit tests for commas, quotes and newlines inside fields.
  - @TODAY-09@: Wired the export endpoint
    - `GET /api/export.csv` streams rows instead of buffering the whole list.
    - Manual test: a 2,000-row list downloads in under a second.
  - @TODAY-05@: Spiked streaming for large exports
    - Exports over 10 MB time out in the browser when the file is built client-side.
    - Moved row generation to the server; the browser only downloads the stream.
  - @TODAY-03@: Reviewed the export dialog with the design team
    - Agreed the dialog opens from the list toolbar, not from the settings page.
    - The downloaded file is named after the list, followed by the export date.
    - Column selection stays out of v1.2 unless it lands before the freeze.
  - @TODAY-02@: Export works end to end
    - The export button in the list view now calls the endpoint and saves the file.
    - Column selection is split out as [[Tasks/DEMO-1]].
    - Checked the file in LibreOffice and Excel: accents and quotes survive.
