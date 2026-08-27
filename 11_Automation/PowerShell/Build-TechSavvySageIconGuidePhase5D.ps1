# =====================================================================
# Build-TechSavvySageIconGuidePhase5D.ps1
# Phase 5D - Pre-Pilot Release Closeout
# =====================================================================

[CmdletBinding()]
param (
    [ValidateSet('Build', 'ValidateOnly')]
    [string]$Mode = 'Build',
    [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section { param([Parameter(Mandatory)][string]$Title) Write-Host ''; Write-Host $Title -ForegroundColor Cyan; Write-Host ('-' * 76) -ForegroundColor DarkGray }
function Write-Pass { param([Parameter(Mandatory)][string]$Message) Write-Host ('[PASS    ] {0}' -f $Message) -ForegroundColor Green }

function Resolve-PhaseRepositoryRoot {
    param ([string]$RequestedRoot)
    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) { return (Resolve-Path -LiteralPath $RequestedRoot).Path }
    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { throw 'Unable to determine the script directory. Supply -RepositoryRoot.' }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
}

function Set-Utf8File {
    param ([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    $Directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { New-Item -ItemType Directory -Path $Directory -Force | Out-Null }
    $Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, ($Content.TrimEnd() + [Environment]::NewLine), $Utf8WithoutBom)
}

function Get-RuntimeFilePaths {
    return @(
        'index.html',
        '04_Application\css\styles.css',
        '04_Application\js\app.js',
        '04_Application\js\icons.js',
        '04_Application\data\icons.json',
        '04_Application\data\lessons.json',
        '04_Application\data\assessments.json',
        'manifest.webmanifest',
        'service-worker.js'
    )
}

function Get-RuntimeHashes {
    param ([Parameter(Mandatory)][string]$Root)
    $Hashes = @{}
    foreach ($RelativePath in Get-RuntimeFilePaths) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required runtime file is missing: $RelativePath" }
        $Hashes[$RelativePath] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
    return $Hashes
}

function Get-PhaseScriptPaths {
    return @(
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5A.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5A.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5B.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5B.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5C.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5C.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5D.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5D.ps1'
    )
}

function Get-CloseoutDefinitions {
    return @(
        [pscustomobject]@{ RelativePath = '01_Documentation\Phase_5_Release_Notes.md'; Markers = @('# Phase 5 Release Notes', 'v0.5.0', 'Pre-Pilot Technical Candidate', 'Human usability validation remains pending') }
        [pscustomobject]@{ RelativePath = '01_Documentation\Phase_5_Pre_Pilot_User_Guide.md'; Markers = @('# Phase 5 Pre-Pilot User Guide', 'Start Here', 'Rolling-cohort pilot', 'No account is required') }
        [pscustomobject]@{ RelativePath = '05_Testing\Phase_5_Regression_and_Accessibility_Checklist.md'; Markers = @('# Phase 5 Regression and Accessibility Checklist', '200% zoom', '320 CSS pixels', 'Human pilot status') }
        [pscustomobject]@{ RelativePath = '05_Testing\Phase_5_Pre_Pilot_Release_Authorization.md'; Markers = @('# Phase 5 Pre-Pilot Release Authorization', 'Technical release decision', 'Human pilot pending', 'v0.5.0') }
    )
}

function Get-CloseoutContent {
    param ([Parameter(Mandatory)][string]$RelativePath)
    switch ($RelativePath) {
        '01_Documentation\Phase_5_Release_Notes.md' { return @'
# Phase 5 Release Notes

## Release identification

- Version: **v0.5.0**
- Status: **Pre-Pilot Technical Candidate**
- Product: TechSavvySage Icon Guide
- Deployment: GitHub Pages
- Human pilot status: Pending

## Phase 5 summary

Phase 5 prepares the Icon Guide for controlled learner testing without claiming results that have not yet been observed.

- **Phase 5A:** Established a Hybrid pilot framework with facilitated and self-guided paths.
- **Phase 5B:** Established a Rolling cohort, five-session findings checkpoints, task scoring, issue severity, and findings reporting.
- **Phase 5C:** Added accessible Start Here orientation, session-first display, dialog focus management, Escape recovery, connection announcements, responsive hardening, reduced-motion and forced-colors support, and service-worker cache `v0.5.0`.
- **Phase 5D:** Consolidates the technical release baseline, regression evidence, user guidance, and authorization record.

## Preserved learning baseline

- 40 icons
- 4 guided lessons and 40 lesson steps
- 4 lesson-linked assessments and 40 question-bank records
- 5 randomized questions per attempt with 4 choices each
- Missed-icon review and targeted practice
- Learn, Lessons, Practice, and Saved for review
- Standard, Large, and Extra Large text settings
- Browser-local progress and offline support

## Privacy and evidence boundary

No account or PII is required. Assessment scores and missed-icon lists are not persisted. Assessment and targeted-practice results are not transmitted externally. Start Here state lasts only for the browser-tab session.

Automated, structural, accessibility, deployment, and live smoke checks support the technical candidate decision. **Human usability validation remains pending** and will use the Phase 5A/5B rolling-cohort materials when participants are available.
'@ }
        '01_Documentation\Phase_5_Pre_Pilot_User_Guide.md' { return @'
# Phase 5 Pre-Pilot User Guide

## Begin with Start Here

Start Here explains the four learning choices. It opens once in a new browser-tab session and remains available from the Learning mode navigation.

- **Learn:** Explore any of the 40 icons.
- **Lessons:** Complete one of four guided lessons and its knowledge check.
- **Practice:** Match an icon with its meaning.
- **Saved for review:** Return to icons saved for later.

Use **Start with a lesson** or **Explore icons** to move directly into the selected activity. Press Escape or choose Close to leave Start Here.

## Accessibility options

Choose Standard, Large, or Extra Large text. The application supports keyboard navigation, visible focus, screen-reader status announcements, browser zoom, narrow screens, reduced motion, forced colors, read-aloud explanations, and touch interaction.

## Privacy

No account is required. Learning progress and display preferences stay in the browser. Knowledge-check scores and missed-icon lists are not saved. Assessment results are not transmitted externally.

## Offline use

Previously loaded learning content remains available when the device loses its connection. A status message reports when the application is offline and when the connection returns.

## Rolling-cohort pilot

When participants are available, use the Phase 5A facilitator/observation materials and Phase 5B participant task, scoring, issue-register, and findings templates. Review findings after every five valid sessions. Do not record names, answers, scores, diagnoses, or missed-icon lists.
'@ }
        '05_Testing\Phase_5_Regression_and_Accessibility_Checklist.md' { return @'
# Phase 5 Regression and Accessibility Checklist

Record Pass / Fail / Not Applicable and retain non-identifying evidence.

## Release baseline

- [ ] 40 icons load.
- [ ] Four lessons contain 40 total steps.
- [ ] Four assessments contain 40 question-bank records.
- [ ] Each attempt uses five questions and four unique choices.
- [ ] Service-worker cache is `techsavvysage-icon-guide-v0.5.0`.

## Start Here

- [ ] Start Here opens once per browser-tab session.
- [ ] Dialog name, role, state, and description are programmatically available.
- [ ] Heading receives focus.
- [ ] Tab and Shift+Tab remain within the dialog.
- [ ] Escape closes and restores focus.
- [ ] Start with a lesson opens Lessons.
- [ ] Explore icons opens Learn.

## Learning regression

- [ ] Learn, Lessons, Practice, and Saved for review operate.
- [ ] Lesson navigation and completion operate.
- [ ] Knowledge-check feedback and Next question operate.
- [ ] Results, missed-icon review, retry, and targeted practice operate.
- [ ] Perfect attempts hide missed-icon review.

## Accessibility and resilience

- [ ] Keyboard-only operation completes primary tasks.
- [ ] Visible focus remains clear.
- [ ] Feedback uses appropriate live regions.
- [ ] Standard, Large, and Extra Large text remain usable.
- [ ] Layout remains usable at 200% zoom.
- [ ] Layout remains usable at 320 CSS pixels.
- [ ] Reduced-motion and forced-colors preferences are respected.
- [ ] Online/offline status is announced politely.
- [ ] Previously loaded content remains available offline.

## Privacy and evidence boundary

- [ ] No account or PII is required.
- [ ] Scores and missed-icon lists are not persisted.
- [ ] Assessment results are not transmitted externally.
- [ ] Human pilot status is Pending.
- [ ] No human-usability claim appears without pilot evidence.
'@ }
        '05_Testing\Phase_5_Pre_Pilot_Release_Authorization.md' { return @'
# Phase 5 Pre-Pilot Release Authorization

## Candidate

- Version: **v0.5.0**
- Candidate type: **Pre-Pilot Technical Candidate**
- Runtime cache: `techsavvysage-icon-guide-v0.5.0`
- Human pilot pending: **Yes**

## Technical release decision

Authorize tagging only after builder Build and ValidateOnly pass, the Phase 5D functional validator exits with code 0, the controlled change set is committed and pushed, GitHub Pages deploys, and the live smoke test reports no application-generated errors.

Technical authorization confirms that the application is sufficiently stable to begin controlled pilot sessions. It does not assert that target learners have validated comprehension, comfort, independence, or preference.

## Required evidence

- [ ] Phase 5A Hybrid pilot framework committed.
- [ ] Phase 5B Rolling-cohort validation package committed.
- [ ] Phase 5C pre-pilot hardening committed.
- [ ] Phase 5D closeout files validated.
- [ ] Runtime files unchanged by closeout.
- [ ] Live Start Here and Phase 4 regression smoke test passed.
- [ ] Privacy and accessibility constraints preserved.
- [ ] Human pilot remains marked Pending.

## Authorization

Decision: Approve / Approve with conditions / Do not approve

Authorized by: ____________________  Date: ____________________

Conditions or notes:
'@ }
        default { throw "No closeout content exists for $RelativePath." }
    }
}

function Test-ReleaseBaseline {
    param ([Parameter(Mandatory)][string]$Root)
    $Checks = 0
    foreach ($RelativePath in Get-PhaseScriptPaths) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $RelativePath) -PathType Leaf)) { throw "Required Phase 5 script is missing: $RelativePath" }
        $Checks++
    }
    $ServiceWorker = Get-Content -LiteralPath (Join-Path $Root 'service-worker.js') -Raw
    if (-not $ServiceWorker.Contains('techsavvysage-icon-guide-v0.5.0')) { throw 'The v0.5.0 cache baseline is missing.' }
    $Checks++
    $App = Get-Content -LiteralPath (Join-Path $Root '04_Application\js\app.js') -Raw
    foreach ($Marker in @('PHASE-5C-START-HERE-BEGIN', 'initializeStartHere', 'initializeConnectionStatus', 'PHASE-5C-START-HERE-END')) {
        if (-not $App.Contains($Marker)) { throw "Required Phase 5C app marker is missing: $Marker" }
        $Checks++
    }
    return $Checks
}

function Test-CloseoutFiles {
    param ([Parameter(Mandatory)][string]$Root)
    $Checks = 0
    foreach ($Definition in Get-CloseoutDefinitions) {
        $Path = Join-Path $Root $Definition.RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required closeout file is missing: $($Definition.RelativePath)" }
        $Checks++
        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $Definition.Markers) {
            if (-not $Content.Contains($Marker)) { throw "Required marker '$Marker' is missing from $($Definition.RelativePath)." }
            $Checks++
        }
    }
    return $Checks
}

try {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5D' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    Write-Section -Title 'Execution Configuration'
    Write-Host ('Operating mode                    : {0}' -f $Mode)
    Write-Host ('Repository root                   : {0}' -f $Root)
    Write-Host 'Release version                   : v0.5.0'
    Write-Host 'Candidate status                  : Pre-Pilot Technical Candidate'
    Write-Host 'Human pilot status                : Pending'

    $HashesBefore = Get-RuntimeHashes -Root $Root
    $BaselineChecks = Test-ReleaseBaseline -Root $Root
    $Written = 0
    if ($Mode -eq 'Build') {
        Write-Section -Title 'Writing Phase 5D Closeout Files'
        foreach ($Definition in Get-CloseoutDefinitions) {
            Set-Utf8File -Path (Join-Path $Root $Definition.RelativePath) -Content (Get-CloseoutContent -RelativePath $Definition.RelativePath)
            $Written++
            Write-Pass -Message ("Wrote {0}" -f $Definition.RelativePath)
        }
    }
    Write-Section -Title 'Validating Phase 5D Closeout'
    $CloseoutChecks = Test-CloseoutFiles -Root $Root
    $HashesAfter = Get-RuntimeHashes -Root $Root
    $Changed = @($HashesBefore.Keys | Where-Object { $HashesBefore[$_] -ne $HashesAfter[$_] })
    if ($Changed.Count -gt 0) { throw ('Closeout changed runtime files: {0}' -f ($Changed -join ', ')) }
    Write-Pass -Message 'Release baseline, closeout content, and evidence boundary validated.'
    Write-Pass -Message 'Runtime files remained unchanged during closeout.'

    Write-Section -Title 'Phase 5D Execution Metrics'
    Write-Host 'Release version                   : v0.5.0'
    Write-Host 'Phase increments                  : 4'
    Write-Host ('Phase scripts and validators      : {0}' -f (Get-PhaseScriptPaths).Count)
    Write-Host ('Closeout files written            : {0}' -f $Written)
    Write-Host ('Validated checks                  : {0}' -f ($BaselineChecks + $CloseoutChecks))
    Write-Host ('Runtime files checked             : {0}' -f $HashesBefore.Count)
    Write-Host ('Runtime file changes              : {0}' -f $Changed.Count)
    Write-Host 'Human pilot status                : Pending'
    Write-Host 'Assessment result storage         : Session only'

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5D COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message ("Operating mode {0} completed successfully." -f $Mode)
}
catch {
    Write-Host ''; Write-Host ('=' * 76) -ForegroundColor Red; Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5D ERROR' -ForegroundColor Red; Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    throw
}
