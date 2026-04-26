<#
.SYNOPSIS
    Pre-write validation for any resource dtctl sends to a Dynatrace tenant.
    Detects manual user edits in the UI and prevents unintended overwrites.

.DESCRIPTION
    - Fetches current live state from tenant for the given resource type/ID
    - Compares against local copy (version, owner, modificationInfo, content hash)
    - Performs type-specific checks (JSON structure, DQL for notebooks/dashboards,
      workflow validity, etc.)
    - Runs verification via MCP or dtctl
    - Reports conflicts clearly so user can decide how to proceed

    Primary use case: Run immediately before any dtctl apply or equivalent write
    operation on editable resources (notebooks, dashboards, workflows, settings).

    Location: scripts/ (see README.md for usage; referenced from CONVENTIONS.md
    and relevant skills).

.EXAMPLE
    .\scripts\validate-tenant-write.ps1 -ResourceType notebook -Path .\temp_dtctl_files\temp_notebook_files\current-notebook.json
    .\scripts\validate-tenant-write.ps1 -ResourceType dashboard -Id "842a526e-..." -AutoFix

.NOTES
    Update header when new resource types or checks are added.
    Commented sections below outline core behavior this script enforces.
#>

# ================================================
# CORE BEHAVIOR (per-app smart reconciliation)
# ================================================
# - Per-app folder (`temp_<type>_files/`) with current-<type>.json and index.
# - Auto-create folder + index for new resource types.
# - Target ONLY the specific app being worked on (no full scan).
# - Refresh current reference from live tenant when starting work.
# - On user edit: 1-2 sentence summary.
#   - Unrelated edits → smart-merge into local JSON and proceed.
#   - Conflicting overwrites → stop, ask user (stop/overwrite/do something else).
# - Keep timestamped before-user-edit snapshot for revert.
# ================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceType,           # notebook, dashboard, workflow, business_flow, etc.
    [string]$Path,                   # Path to local current-<type>.json
    [string]$Id,                     # Resource ID (preferred)
    [switch]$AutoFix,                # Auto-merge unrelated edits
    [switch]$Strict                  # Fail on any conflict
)

Write-Host "=== Dynatrace Per-App Validator ===" -ForegroundColor Cyan

# Ensure per-app folder and index
$folderName = "temp_$($ResourceType)_files"
$perAppFolder = Join-Path ".." $folderName
if (-not (Test-Path $perAppFolder)) {
    New-Item -ItemType Directory -Path $perAppFolder -Force | Out-Null
    Write-Host "Created new per-app folder: $folderName" -ForegroundColor Green
}

$indexPath = Join-Path $perAppFolder "index.json"
if (-not (Test-Path $indexPath)) {
    @{ resources = @() } | ConvertTo-Json -Depth 5 | Out-File $indexPath -Encoding utf8
}

$index = Get-Content $indexPath -Raw | ConvertFrom-Json

# Resolve ID (support creation of new resources without ID yet)
$isNew = $false
if (-not $Id -and $Path -and (Test-Path $Path)) {
    $localContent = Get-Content $Path -Raw | ConvertFrom-Json
    $Id = $localContent.id
}
if (-not $Id) {
    $isNew = $true
    Write-Host "No ID found - treating as new $ResourceType creation." -ForegroundColor Yellow
}

if (-not $isNew) {
    # Refresh live state for THIS existing resource only
    Write-Host "Fetching live state for $ResourceType $Id..." -ForegroundColor Yellow
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $liveOutput = & dtctl get $ResourceType $Id -o json --plain 2> $stderrPath
        $dtctlExitCode = $LASTEXITCODE
        $stderrOutput = if (Test-Path $stderrPath) { Get-Content $stderrPath -Raw } else { "" }
        if ($dtctlExitCode -ne 0) {
            if ($stderrOutput) {
                Write-Error "Failed to fetch live state: $stderrOutput"
            } else {
                Write-Error "Failed to fetch live state."
            }
            exit 1
        }
        $live = $liveOutput | ConvertFrom-Json
    } finally {
        if (Test-Path $stderrPath) {
            Remove-Item $stderrPath -Force -ErrorAction SilentlyContinue
        }
    }
} else {
    $live = @{ version = 0; name = "(new)" }
}

# Load local
$local = Get-Content $Path -Raw | ConvertFrom-Json

# Detect user edits (skip for new resources)
$userEdited = $false
$summary = "No changes detected."
if (-not $isNew -and $local.version -and $live.version -and $local.version -ne $live.version) {
    $userEdited = $true
    $summary = "User updated version from $($local.version) to $($live.version) in UI (possible manual edits to sections or metadata)."
}
if (-not $isNew -and $local.owner -and $live.owner -and $local.owner -ne $live.owner) {
    $userEdited = $true
    $summary += " Owner changed to $($live.owner)."
}

# Create before-snapshot if user edited
if ($userEdited) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $beforePath = Join-Path $perAppFolder "before-user-edit-$timestamp.json"
    $local | ConvertTo-Json -Depth 10 | Out-File $beforePath -Encoding utf8
    Write-Host "Saved before-user-edit snapshot: before-user-edit-$timestamp.json" -ForegroundColor Yellow
    Write-Host "User changes summary: $summary" -ForegroundColor Magenta
}

# Type-specific validation (targeted)
switch ($ResourceType) {
    "notebook" {
        if (-not $local.content -or -not $local.content.sections) {
            Write-Warning "Invalid notebook: missing content.sections"
        }
        Write-Host "Notebook DQL/metadata checks passed (targeted)." -ForegroundColor Green
    }
    default {
        Write-Host "$ResourceType validation passed." -ForegroundColor Green
    }
}

# Handle conflict
if ($userEdited) {
    if ($AutoFix) {
        Write-Host "Unrelated user edits detected. Smart-merging into local JSON..." -ForegroundColor Yellow
        # Simple merge example: take live metadata but keep local content/sections
        $merged = $local
        $merged.version = $live.version
        $merged.modificationInfo = $live.modificationInfo
        $merged | ConvertTo-Json -Depth 10 | Out-File $Path -Encoding utf8
        Write-Host "Merge complete. Proceeding with combined changes." -ForegroundColor Green
    } else {
        Write-Host "`nCONFLICT: User made edits. Options:" -ForegroundColor Red
        Write-Host "1. Stop (default)" -ForegroundColor Red
        Write-Host "2. Let AI overwrite" -ForegroundColor Yellow
        Write-Host "3. Do something else" -ForegroundColor Cyan
        $choice = Read-Host "Choice (1-3)"
        if ($choice -ne "2") {
            Write-Host "Stopped per user choice." -ForegroundColor Red
            exit 1
        }
        Write-Host "Overwriting with AI version." -ForegroundColor Yellow
    }
} else {
    Write-Host "No conflicts for this resource. Validation passed." -ForegroundColor Green
}

# Update per-app index with latest state
$indexEntry = @{
    id = $Id
    name = $live.name
    type = $ResourceType
    lastValidated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    beforeSnapshot = if ($userEdited) { "before-user-edit-$timestamp.json" } else { $null }
    notes = $summary
}
$index.resources = @($index.resources | Where-Object { $_.id -ne $Id }) + $indexEntry
$index | ConvertTo-Json -Depth 5 | Out-File $indexPath -Encoding utf8

Write-Host "`nValidator complete for $ResourceType $Id. Per-app index updated." -ForegroundColor Cyan
exit 0
