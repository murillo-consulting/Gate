# DLP test fixtures

Every credential-, card-, IBAN-, and token-like value in this directory is
synthetic test data. The AWS values use the public `EXAMPLE` pattern, and the
other values exist only to trigger deterministic DLP rules.

Never replace these fixtures with live credentials, production payloads, or
personal data. Add new fixtures using clearly synthetic values and keep them
scoped to the smallest rule under test.
