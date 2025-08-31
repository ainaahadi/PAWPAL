param(
  [Parameter(Mandatory=$true)][string]$PatchPath,       # e.g. codex.patch
  [string]$Branch = $(Get-Date -Format "'autogen/'yyyyMMdd"),
  [string]$CommitMsg = "auto: codex update",
  [switch]$OpenPR                                         # add -OpenPR to auto-open a PR
)

$ErrorActionPreference = "Stop"

# Move to repo root
$repoRoot = (git rev-parse --show-toplevel) 2>$null
if (-not $repoRoot) { throw "Not inside a Git repository. Run this from your repo or cd into it." }
Set-Location $repoRoot

if (-not (Test-Path $PatchPath)) { throw "Patch not found: $PatchPath" }

# Ensure clean working tree (avoid mixing unrelated edits)
if ((git status --porcelain).Trim().Length -ne 0) {
  throw "Working tree not clean. Commit/stash your changes first."
}

# Fetch & create/checkout target branch
git fetch origin --prune
if (git rev-parse --verify $Branch 2>$null) {
  git checkout $Branch
} else {
  # start from main if exists, else current
  $base = (git rev-parse --verify origin/main 2>$null) ? "origin/main" : (git rev-parse --abbrev-ref HEAD)
  git checkout -b $Branch $base
}

Write-Host "✔ Using branch $Branch"

# Dry-run check
git apply --check "$PatchPath"

# Apply (prefer 3-way merge if context is slightly off)
try {
  git apply --3way "$PatchPath"
} catch {
  Write-Host "3-way apply failed, trying regular apply…"
  git apply "$PatchPath"
}

# Stage & commit (skip if nothing actually changed)
if ((git status --porcelain).Trim().Length -eq 0) {
  Write-Host "No changes after applying patch. Nothing to commit."
  exit 0
}

git add -A

# If the patch contains a subject line, try to extract it
try {
  $subject = (Select-String -Path $PatchPath -Pattern '^Subject:\s*(.+)$' -SimpleMatch:$false -CaseSensitive:$false | Select-Object -First 1).Matches.Groups[1].Value
  if ($subject) { $CommitMsg = $subject }
} catch {}

git commit -m $CommitMsg

# Push
git push -u origin $Branch
Write-Host "✅ Pushed $Branch to origin"

# Optional PR
if ($OpenPR) {
  try {
    # Requires: gh auth login (once)
    gh pr create --fill --base main --head $Branch
    Write-Host "✅ Pull request opened."
  } catch {
    Write-Host "⚠️ Could not open PR automatically. Error: $($_.Exception.Message)"
    Write-Host "Tip: run 'gh auth login' once to enable PR creation."
  }
}
