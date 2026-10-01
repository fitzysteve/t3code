<#
.SYNOPSIS
  Upgrade the core from upstream and merge it into the `custom` branch.

.DESCRIPTION
  Branch model (see CUSTOMISATIONS.md):
    main   - pure mirror of upstream. Fast-forward only. Never commit here.
    custom - all local customisations. Upstream is merged in, never rebased.

  Steps:
    1. Refuse to run with uncommitted changes.
    2. Fetch upstream and fast-forward `main`. Stops if `main` has diverged,
       which means someone committed to it.
    3. Merge `main` into `custom`. Stops on conflicts so they can be resolved
       by hand (git rerere remembers the resolutions for next time).
    4. Reinstall dependencies with `vp i`.
    5. Report which core (upstream) files `custom` modifies.

  Nothing is pushed. Push manually when satisfied:
    git push origin main custom

.PARAMETER ReportOnly
  Skip steps 1-4 and only print the core-files report.

.PARAMETER SkipInstall
  Skip `vp i` after merging.

.EXAMPLE
  .\scripts\custom\upgrade.ps1
.EXAMPLE
  .\scripts\custom\upgrade.ps1 -ReportOnly
#>
param(
  [switch]$ReportOnly,
  [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$UpstreamRemote = 'upstream'
$UpstreamBranch = 'main'
$MirrorBranch = 'main'
$CustomBranch = 'custom'

# Paths owned by the customisation layer. Anything else in the diff is a core file.
$CustomPathPattern = '(^|/)custom(/|$)|^CUSTOMISATIONS\.md$'

function Invoke-Git {
  & git @args
  if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed (exit $LASTEXITCODE)" }
}

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

if (-not $ReportOnly) {
  Write-Step 'Checking working tree'
  $dirty = & git status --porcelain
  if ($dirty) {
    Write-Host $($dirty -join "`n")
    throw 'Working tree has uncommitted changes. Commit or stash them first.'
  }
  $startBranch = (& git branch --show-current).Trim()

  Write-Step "Fetching $UpstreamRemote"
  Invoke-Git fetch $UpstreamRemote --prune

  Write-Step "Fast-forwarding $MirrorBranch to $UpstreamRemote/$UpstreamBranch"
  Invoke-Git switch $MirrorBranch
  & git merge --ff-only "$UpstreamRemote/$UpstreamBranch"
  if ($LASTEXITCODE -ne 0) {
    Invoke-Git switch $startBranch
    throw "$MirrorBranch has diverged from $UpstreamRemote/$UpstreamBranch. It must stay a pure mirror; move any local commits to $CustomBranch, then reset $MirrorBranch."
  }

  Write-Step "Merging $MirrorBranch into $CustomBranch"
  Invoke-Git switch $CustomBranch
  & git merge $MirrorBranch --no-edit
  if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Merge conflicts in:' -ForegroundColor Yellow
    & git diff --name-only --diff-filter=U
    Write-Host ''
    Write-Host 'Resolve them, then: git add <files>; git commit --no-edit; and re-run with -ReportOnly.' -ForegroundColor Yellow
    exit 1
  }

  if (-not $SkipInstall) {
    Write-Step 'Installing dependencies (vp i)'
    $vpEnv = Join-Path $env:APPDATA 'vite-plus\env.ps1'
    if (Test-Path $vpEnv) { . $vpEnv }
    & vp i
    if ($LASTEXITCODE -ne 0) { throw "vp i failed (exit $LASTEXITCODE)" }
  }
}

Write-Step "Core files modified by $CustomBranch (vs $MirrorBranch)"
$changed = & git diff --name-only "$MirrorBranch...$CustomBranch"
$core = @($changed | Where-Object { $_ -and ($_ -notmatch $CustomPathPattern) })
$owned = @($changed | Where-Object { $_ -and ($_ -match $CustomPathPattern) })
Write-Host "Customisation files: $($owned.Count)"
if ($core.Count -eq 0) {
  Write-Host 'Core files touched:  0 (upgrades cannot conflict)' -ForegroundColor Green
} else {
  Write-Host "Core files touched:  $($core.Count) (these can conflict on upgrade; list them in CUSTOMISATIONS.md)" -ForegroundColor Yellow
  $core | ForEach-Object { Write-Host "  $_" }
}

if (-not $ReportOnly) {
  Write-Host ''
  Write-Host 'Next: run checks for your customisations, build, then push:' -ForegroundColor Cyan
  Write-Host '  vp run typecheck'
  Write-Host '  vp test run <your test files>'
  Write-Host '  vp run dist:desktop:win:x64'
  Write-Host "  git push origin $MirrorBranch $CustomBranch"
}
