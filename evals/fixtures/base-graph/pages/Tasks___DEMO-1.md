type:: task
status:: active
created:: @TODAY-02@
last-updated:: @TODAY-02@
project:: [[Projects/Demo]]
focus:: Column selection for the CSV export
next:: Pass the picker's selection to the export endpoint
digest-updated:: @TODAY-02@

- ## Digest
  - Let users choose which columns the CSV export of [[Projects/Demo]] includes.
  - Now: the column picker exists in the dialog; the endpoint still ignores it.
  - Map: +2 smaller sections, 169 B · page | 649 B
- ## Plan
  - Add a `columns` query parameter to `GET /api/export.csv`.
  - Pass the picker's selection through from the export dialog.
- ## Notes
  - The default export keeps every column.
