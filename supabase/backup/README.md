# Supabase SQL Backups

This directory stores ad-hoc dumps captured from production before audits (e.g. `backup-INITIAL.sql`, `backup-pre-repair.sql`). Keep files here instead of the repo root so they are easy to find and can be pruned when no longer needed.

Guidelines:

1. **Never edit** the dump contents directly; capture a fresh snapshot via `supabase db dump`.
2. If a dump is temporary, delete it after the related migration or audit merges.
3. Avoid committing very large dumps to git history; prefer storing them outside the repo if possible.

