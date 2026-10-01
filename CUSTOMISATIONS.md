# Customisations

This fork keeps upstream ([pingdotgg/t3code](https://github.com/pingdotgg/t3code)) upgradeable by
never editing it in place. This file exists only on the `custom` branch.

## Branches

| Branch   | Rule                                                                  |
| -------- | --------------------------------------------------------------------- |
| `main`   | Pure mirror of `upstream/main`. Fast-forward only. Never commit here. |
| `custom` | All local changes. Merge `main` in to upgrade; do not rebase.         |
| `feat/*` | Optional short-lived branches off `custom`, merged back when done.    |

Remotes: `origin` = fitzysteve/t3code, `upstream` = pingdotgg/t3code. `git rerere` is enabled so
conflict resolutions are reused on later upgrades.

## Upgrading

```powershell
.\scripts\custom\upgrade.ps1          # fetch, fast-forward main, merge into custom, vp i, report
.\scripts\custom\upgrade.ps1 -ReportOnly   # just list core files custom has modified
```

Then run checks for the customisations, build (`vp run dist:desktop:win:x64`), and push
(`git push origin main custom`). Upstream's full test suite does not pass on Windows yet, so
compare failures against a run on `main` rather than expecting zero.

## Where customisations go

Prefer the lowest tier that works.

| Tier | Approach                                                                                                      | Upgrade risk |
| ---- | ------------------------------------------------------------------------------------------------------------- | ------------ |
| 0    | Configuration only (T3 settings, provider instances, `.env`)                                                  | None         |
| 1    | New files under a `custom/` folder, e.g. `apps/server/src/custom/`, `apps/web/src/custom/`, `scripts/custom/` | Near zero    |
| 2    | One-line hook in a core file (import or registration) pointing at tier 1                                      | Small        |
| 3    | Edits to core logic                                                                                           | High; avoid  |

Paths matching `custom/` and this file are treated as customisation-owned by the upgrade report.
Everything else in `git diff main...custom` is a core file and must be listed below.

## Core files touched

| File       | Why | Tier |
| ---------- | --- | ---- |
| _none yet_ |     |      |

## Customisation log

| #   | Customisation                | Location                               | Source / credit | Status |
| --- | ---------------------------- | -------------------------------------- | --------------- | ------ |
| 1   | Upgrade script and this file | `scripts/custom/`, `CUSTOMISATIONS.md` | -               | Done   |
