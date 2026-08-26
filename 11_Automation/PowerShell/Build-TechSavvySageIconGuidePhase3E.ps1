# ============================================================================
# Build-TechSavvySageIconGuidePhase3E.ps1
# Phase 3E - Release Documentation and Validation Closeout
# ============================================================================
[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [ValidateSet('Build', 'ValidateOnly')]
    [string]$OperatingMode = 'Build',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 3E Closeout Builder'
$Script:UtilityVersion = '0.3.2'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:CreatedFiles = 0
$Script:ReplacedFiles = 0
$Script:ValidatedMarkers = 0

function Write-Banner {
    param ([Parameter(Mandatory)][string]$Text)

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
}

function Write-Section {
    param ([Parameter(Mandatory)][string]$Text)

    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('-' * 76) -ForegroundColor DarkGray
}

function Write-Status {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'CREATE', 'REPLACE', 'VALIDATE', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'CREATE'   { 'Green' }
        'REPLACE'  { 'Yellow' }
        'VALIDATE' { 'Cyan' }
        'PASS'     { 'Green' }
        'WARN'     { 'Yellow' }
        'FAIL'     { 'Red' }
        default    { 'Gray' }
    }

    Write-Host ('[{0,-8}] {1}' -f $Level, $Message) -ForegroundColor $Color
}

function Write-Metric {
    param (
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value
    )

    Write-Host ('{0,-34}: {1}' -f $Name, $Value)
}

function Get-NormalizedPath {
    param ([Parameter(Mandatory)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-RepositoryRoot {
    param (
        [string]$ExplicitRepositoryRoot,
        [Parameter(Mandatory)][string]$ScriptRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepositoryRoot)) {
        return Get-NormalizedPath -Path $ExplicitRepositoryRoot
    }

    $NormalizedScriptRoot = Get-NormalizedPath -Path $ScriptRoot

    if ((Split-Path -Path $NormalizedScriptRoot -Leaf) -ieq $Script:ExpectedRepositoryName) {
        return $NormalizedScriptRoot
    }

    if ((Split-Path -Path $NormalizedScriptRoot -Leaf) -ieq 'PowerShell') {
        $AutomationRoot = Split-Path -Path $NormalizedScriptRoot -Parent

        if ((Split-Path -Path $AutomationRoot -Leaf) -ieq '11_Automation') {
            return Split-Path -Path $AutomationRoot -Parent
        }
    }

    throw @'
Unable to determine the repository root automatically.

Place this builder in either the techsavvysage-icon-guide repository root or
11_Automation\PowerShell. You may also provide -RepositoryRoot explicitly.
'@
}

function Write-Utf8File {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $NormalizedContent = $Content.TrimEnd([char[]]@("`r", "`n")) + "`n"
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf
    [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)

    if ($Exists) {
        $Script:ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
    }
    else {
        $Script:CreatedFiles++
        Write-Status -Level 'CREATE' -Message $Path
    }
}

function Test-Marker {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$Description
    )

    Write-Status -Level 'VALIDATE' -Message ("{0} :: {1}" -f $Path, $Description)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required Phase 3E file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 3E marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Get-FileHashMap {
    param ([Parameter(Mandatory)][string[]]$Paths)

    $Map = @{}

    foreach ($Path in $Paths) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Cannot hash missing runtime file: $Path"
        }

        $Map[$Path] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }

    return $Map
}

function Test-HashMapsMatch {
    param (
        [Parameter(Mandatory)][hashtable]$Before,
        [Parameter(Mandatory)][hashtable]$After
    )

    foreach ($Path in $Before.Keys) {
        if (-not $After.ContainsKey($Path) -or $Before[$Path] -ne $After[$Path]) {
            throw "Phase 3E unexpectedly changed a runtime file: $Path"
        }
    }

    Write-Status -Level 'PASS' -Message 'All runtime file hashes remained unchanged.'
}

function Test-Phase3Data {
    param (
        [Parameter(Mandatory)][string]$IconDataPath,
        [Parameter(Mandatory)][string]$LessonDataPath
    )

    $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
    $LessonData = Get-Content -LiteralPath $LessonDataPath -Raw | ConvertFrom-Json
    $Icons = @($IconData.icons)
    $Lessons = @($LessonData.lessons)
    $Steps = @($Lessons | ForEach-Object { @($_.steps) })
    $IconIds = @($Icons | ForEach-Object { [string]$_.id })
    $DuplicateIconIds = @($IconIds | Group-Object | Where-Object { $_.Count -gt 1 })
    $DuplicateLessonIds = @($Lessons | Group-Object id | Where-Object { $_.Count -gt 1 })
    $UnknownReferences = @($Steps | Where-Object { $IconIds -cnotcontains [string]$_.icon_id })
    $ReferencedIds = @($Steps | ForEach-Object { [string]$_.icon_id } | Sort-Object -Unique)

    if ($Icons.Count -ne 40 -or $DuplicateIconIds.Count -gt 0) {
        throw 'The icon library must contain exactly 40 unique records.'
    }

    if ($Lessons.Count -ne 4 -or $DuplicateLessonIds.Count -gt 0) {
        throw 'The lesson library must contain exactly four unique records.'
    }

    if ($Steps.Count -ne 40 -or $UnknownReferences.Count -gt 0) {
        throw 'The lesson library must contain 40 steps with valid icon references.'
    }

    if ($ReferencedIds.Count -ne 40) {
        throw 'The four lessons must collectively represent all 40 icon identifiers.'
    }

    Write-Status -Level 'PASS' -Message 'Phase 3 data contains 40 icons, four lessons, and 40 valid references.'

    return [pscustomobject]@{
        IconCount = $Icons.Count
        LessonCount = $Lessons.Count
        StepCount = $Steps.Count
        ReferencedIconCount = $ReferencedIds.Count
    }
}

function Test-NoExternalProgressTransmission {
    param ([Parameter(Mandatory)][string]$AppPath)

    $Content = Get-Content -LiteralPath $AppPath -Raw

    foreach ($ForbiddenMarker in @(
        'fetch("http',
        "fetch('http",
        'XMLHttpRequest',
        'navigator.sendBeacon'
    )) {
        if ($Content.Contains($ForbiddenMarker)) {
            throw "Unexpected external progress-transmission marker detected: $ForbiddenMarker"
        }
    }

    foreach ($RequiredMarker in @(
        'localStorage.setItem(STORAGE_KEY',
        'lessons: state.lessonProgress',
        'function resetLessonProgress()'
    )) {
        if (-not $Content.Contains($RequiredMarker)) {
            throw "Required browser-only progress marker is missing: $RequiredMarker"
        }
    }

    Write-Status -Level 'PASS' -Message 'Learning and lesson progress remain browser-only.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 3E builder directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $ResolvedRepositoryRoot"
    }

    $IndexPath = Join-Path $ResolvedRepositoryRoot 'index.html'
    $StylesPath = Join-Path $ResolvedRepositoryRoot '04_Application\css\styles.css'
    $AppPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'
    $IconsScriptPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\icons.js'
    $IconDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\icons.json'
    $LessonDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\lessons.json'
    $ManifestPath = Join-Path $ResolvedRepositoryRoot 'manifest.webmanifest'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $UserGuidePath = Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_3_User_Guide.md'
    $ReleaseNotesPath = Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_3_Release_Notes.md'
    $ChecklistPath = Join-Path $ResolvedRepositoryRoot '05_Testing\Phase_3_Regression_and_Accessibility_Checklist.md'

    $PhaseScripts = @(
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3Data.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3B.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3C.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3D.ps1'
    ) | ForEach-Object { Join-Path $ResolvedRepositoryRoot $_ }

    $RuntimePaths = @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $IconsScriptPath,
        $IconDataPath,
        $LessonDataPath,
        $ManifestPath,
        $ServiceWorkerPath
    )

    Write-Section -Text 'Phase 3E - Preflight Validation'

    foreach ($RequiredPath in @($RuntimePaths + $PhaseScripts)) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 3 baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    $RuntimeHashesBefore = Get-FileHashMap -Paths $RuntimePaths
    $DataMetrics = Test-Phase3Data -IconDataPath $IconDataPath -LessonDataPath $LessonDataPath

    $UserGuide = @'
# TechSavvySage Icon Guide Phase 3 User Guide

**Release:** v0.3.2
**Status:** Stable Release Candidate
**Release date:** August 26, 2026

## Purpose

The TechSavvySage Icon Guide is an accessible, untimed learning utility for 40 common computer and mobile icons. Phase 3 adds four guided lessons while preserving Learn, Practice, Saved for Review, display personalization, read-aloud support, offline use, and browser-only privacy.

## Learning modes

### Learn

Search all 40 icons or filter by category. Select an icon to review its meaning, example, device context, and safety note. Search and category filters work together. For example, Bluetooth appears under Device rather than Communication.

### Lessons

Choose one of four guided lessons:

1. Find Your Way
2. Work With Files
3. Communicate and Use Media
4. Stay Safe and Connected

Preview the lesson, select **Start lesson**, and move through one icon step at a time. Use **Previous step**, **Next step**, **Finish lesson**, or **Back to lesson choices**. The progress bar shows the current step.

### Practice

Choose 5, 10, 20, or all 40 questions. Questions and four answer choices are randomized without repetition inside the session. Results identify missed icons for optional review.

### Saved for Review

Save an icon from Learn mode, then open Saved for Review to study that personal list. If the screen says `0 saved`, return to Learn and save at least one icon. Search in Saved for Review searches only the saved list, not all 40 icons.

## Lesson progress and resume

The application stores the last displayed step for an unfinished lesson in the current browser. An unfinished card shows **In progress** and its resume step. A completed card shows **Completed**. Select **Resume lesson** to continue or **Review lesson** to revisit a completed lesson without erasing completion.

Select **Reset lesson progress** to clear only guided-lesson status. Confirmation is required. This reset does not clear explored icons, practiced icons, the Saved for Review list, or display settings.

## Other controls

- **Clear learning data** clears explored, practiced, and saved-icon data after confirmation. It does not reset lesson progress or display settings.
- **Reset display settings** restores standard text and normal contrast.
- **Read explanation aloud** uses browser speech support when available.

## Accessibility

- No activity is timed.
- All primary controls support keyboard operation.
- Focus moves to each lesson-step heading as the step changes.
- Standard, Large, and Extra Large text are supported.
- High contrast and reduced-motion preferences are supported.
- Status changes are communicated through the page status region.

## Offline and updates

After one successful online visit, the application retains its core files for offline use. When online, it uses network-first loading so a newly deployed version replaces older cached content. A page may reload once when an updated service worker takes control.

## Privacy

The utility requires no account and sends no learning or lesson progress to an external service. Explored icons, practice status, saved icons, lesson progress, and display preferences stay in the current browser. Clearing browser site data removes this information.

## Troubleshooting

- If zero icons appear, confirm the active mode. Learn searches all icons; Saved for Review searches only saved icons.
- Clear the search field and select **All categories** to display all 40 icons.
- If a search and category conflict, zero matches is expected.
- If an update appears delayed, reload once and allow the service worker to refresh.
'@

    $ReleaseNotes = @'
# TechSavvySage Icon Guide v0.3.2 Release Notes

**Release date:** August 26, 2026
**Release status:** Stable Release Candidate

## Summary

Phase 3 introduces structured, accessible guided lessons across the existing 40-icon library. The release was built incrementally and validated after each checkpoint.

## Phase 3 checkpoints

- `8d8ff83` — Added four lesson data records and validated 40 unique icon references.
- `648094d` — Added the read-only four-lesson catalog and previews.
- `55b8203` — Added one-step-at-a-time guided progression and session completion.
- `57c44fa` — Added browser-only completion, last-step resume, completed indicators, and protected reset.

## Added

- Four guided lessons containing 40 total icon steps.
- Lesson previews with duration and step counts.
- Start, Previous, Next, Finish, and return-to-catalog controls.
- Step progress text and progress bar.
- Session completion messages.
- Browser-only last-step resume.
- Persistent Completed and In progress indicators.
- Review mode for completed lessons without clearing completion.
- Confirmation-protected lesson-progress reset.

## Preserved

- Learn, Practice, and Saved for Review modes.
- All 40 icon definitions and SVG renderings.
- Untimed randomized practice.
- Read-aloud support.
- Standard, Large, and Extra Large text.
- High contrast and reduced-motion behavior.
- Installable and offline-capable delivery.
- Network-first deployment hardening.

## Data and privacy

Phase 3 adds no account, analytics, cloud synchronization, or personally identifiable information collection. Lesson progress is added to the existing browser storage record. Resetting lesson progress does not clear other learning data or display preferences.

## Release boundaries

- Progress is specific to the current browser and device.
- Clearing browser site data removes local progress.
- Cross-device synchronization is not included.
- Phase 3 does not add scored lesson assessments; Practice remains the assessment mode.

## Release control

Complete the Phase 3 regression and accessibility checklist, verify the live GitHub Pages deployment, commit and push the closeout artifacts, then create tag `v0.3.2`.
'@

    $Checklist = @'
# Phase 3 Regression and Accessibility Checklist

**Release:** v0.3.2
**Date:** August 26, 2026
**Tester:** ____________________
**Browser and version:** ____________________
**Device:** ____________________

## Automated release gate

- [x] Icon data contains 40 unique records.
- [x] Lesson data contains four unique records.
- [x] Lesson data contains 40 valid icon references.
- [x] All 40 icon identifiers are represented by the lessons.
- [x] Phase 3A through Phase 3D builders are present.
- [x] Lesson catalog, runner, persistence, resume, completion, and reset markers are present.
- [x] Deployment update and reload markers are preserved.
- [x] Service-worker cache is v0.3.2.
- [x] Lesson data is included in offline assets.
- [x] No external progress-transmission mechanism was detected.
- [x] Phase 3E did not change runtime file hashes.

## Learn regression

- [ ] Learn opens as the default mode.
- [ ] Clearing search and selecting All categories displays 40 icons.
- [ ] Search finds icons by name, meaning, example, caution, and search terms.
- [ ] Category filtering works alone.
- [ ] Search and category filtering work together.
- [ ] Selecting an icon displays its SVG, name, meaning, example, devices, and caution.
- [ ] Read aloud works or reports that browser speech is unavailable.
- [ ] Save for Review adds and removes the selected icon.
- [ ] Practice this icon opens a one-icon practice session.

## Lessons catalog

- [ ] Lessons displays four cards in the defined order.
- [ ] Each card displays title, summary, duration, and step count.
- [ ] Selecting a card displays the correct preview.
- [ ] Start lesson opens Step 1 for a new lesson.
- [ ] Each displayed step uses the referenced icon from the 40-icon library.

## Guided progression

- [ ] The progress text and progress bar match the current step.
- [ ] Previous is disabled on Step 1.
- [ ] Next advances exactly one step.
- [ ] Previous returns exactly one step.
- [ ] Focus moves to the new step heading.
- [ ] Back to lesson choices exits without losing the current step.
- [ ] The final step displays Finish lesson.
- [ ] Finish lesson displays the defined completion message.
- [ ] Return to lesson choices works after completion.

## Persistence and reset

- [ ] Exiting an unfinished lesson displays In progress and the correct step.
- [ ] Reloading preserves the unfinished lesson step.
- [ ] Resume lesson opens the stored step.
- [ ] Completion displays a Completed indicator.
- [ ] Reloading preserves completion.
- [ ] Review lesson starts a completed lesson without clearing completion.
- [ ] Canceling Reset lesson progress preserves lesson data.
- [ ] Confirming Reset lesson progress clears all lesson indicators.
- [ ] Lesson reset does not clear explored, practiced, or saved-icon data.
- [ ] Lesson reset does not change text size or high contrast.

## Practice regression

- [ ] Practice offers 5, 10, 20, and all-icon sessions.
- [ ] Each question displays four choices.
- [ ] Questions and choices are randomized.
- [ ] Questions do not repeat within a session.
- [ ] Correct and supportive retry feedback display correctly.
- [ ] Results report completed and correct counts.
- [ ] Missed icons can be opened in review.

## Saved for Review regression

- [ ] Saved for Review displays only saved icons.
- [ ] An empty saved list explains that no icons are available.
- [ ] Search filters the saved list rather than all icons.
- [ ] Returning to Learn restores the complete library search scope.

## Accessibility

- [ ] All four modes can be completed using only a keyboard.
- [ ] Focus indicators remain visible.
- [ ] Lesson cards and icon choices have meaningful accessible names.
- [ ] Status and feedback updates are announced appropriately.
- [ ] Standard, Large, and Extra Large text remain usable.
- [ ] High contrast remains usable in every mode.
- [ ] Content remains usable at 200 percent zoom.
- [ ] Content remains usable at a 320-pixel viewport.
- [ ] Reduced-motion preference is honored.
- [ ] No activity imposes a timer.

## Offline, deployment, and browser coverage

- [ ] The online application loads the latest v0.3.2 release.
- [ ] A service-worker update may reload only once.
- [ ] The application loads offline after one successful online visit.
- [ ] Icons and lesson data remain available offline.
- [ ] Edge smoke test passes.
- [ ] Chrome smoke test passes.
- [ ] Safari or iOS smoke test passes when available.
- [ ] Android browser smoke test passes when available.
- [ ] Browser Console contains no red application errors.

## Privacy and release control

- [ ] No account or personally identifiable information is requested.
- [ ] Browser storage contains learning preferences and progress only.
- [ ] No learning or lesson progress is transmitted externally.
- [ ] Git working tree is clean before tagging.
- [ ] Local main and origin/main reference the same closeout commit.
- [ ] Live GitHub Pages smoke test passes after deployment.
- [ ] Release tag v0.3.2 is created only after all required checks pass.

## Release decision

- [ ] Approved for v0.3.2 release.

**Approver:** ____________________
**Approval date:** ____________________
**Notes:**
'@

    if ($OperatingMode -eq 'Build') {
        $ExistingCloseoutFiles = @(
            @(
                $UserGuidePath,
                $ReleaseNotesPath,
                $ChecklistPath
            ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
        )

        if ($ExistingCloseoutFiles.Count -gt 0 -and -not $Force) {
            throw 'One or more Phase 3 closeout files already exist. Review them before rerunning Build mode with -Force.'
        }

        Write-Section -Text 'Phase 3E - Create Release Closeout Artifacts'
        Write-Utf8File -Path $UserGuidePath -Content $UserGuide
        Write-Utf8File -Path $ReleaseNotesPath -Content $ReleaseNotes
        Write-Utf8File -Path $ChecklistPath -Content $Checklist
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 3E - Automated Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="lessons-mode"'; Description = 'Lessons navigation' },
        @{ Path = $IndexPath; Marker = 'id="lesson-runner"'; Description = 'Guided lesson runner' },
        @{ Path = $IndexPath; Marker = 'id="reset-lessons"'; Description = 'Controlled lesson reset' },
        @{ Path = $AppPath; Marker = 'function renderLessonCatalog()'; Description = 'Lesson catalog behavior' },
        @{ Path = $AppPath; Marker = 'function startLesson(id)'; Description = 'Lesson start behavior' },
        @{ Path = $AppPath; Marker = 'function moveLessonStep(direction)'; Description = 'Lesson navigation behavior' },
        @{ Path = $AppPath; Marker = 'function normalizeLessonProgress()'; Description = 'Stored progress normalization' },
        @{ Path = $AppPath; Marker = 'function resetLessonProgress()'; Description = 'Lesson reset behavior' },
        @{ Path = $AppPath; Marker = 'lessons: state.lessonProgress'; Description = 'Browser lesson persistence' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior' },
        @{ Path = $IconsScriptPath; Marker = 'window.IconGuideIcons'; Description = 'SVG icon renderer' },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.3.2"; Description = 'v0.3.2 cache' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/lessons.json'"; Description = 'Offline lesson data' },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(asset, { cache: 'reload' })"; Description = 'Fresh install caching' },
        @{ Path = $ServiceWorkerPath; Marker = 'fetch(event.request)'; Description = 'Network-first loading' },
        @{ Path = $UserGuidePath; Marker = '# TechSavvySage Icon Guide Phase 3 User Guide'; Description = 'Phase 3 user guide' },
        @{ Path = $UserGuidePath; Marker = '## Lesson progress and resume'; Description = 'Resume guidance' },
        @{ Path = $ReleaseNotesPath; Marker = '# TechSavvySage Icon Guide v0.3.2 Release Notes'; Description = 'v0.3.2 release notes' },
        @{ Path = $ReleaseNotesPath; Marker = '57c44fa'; Description = 'Phase 3D checkpoint record' },
        @{ Path = $ChecklistPath; Marker = '# Phase 3 Regression and Accessibility Checklist'; Description = 'Release checklist' },
        @{ Path = $ChecklistPath; Marker = '## Release decision'; Description = 'Release approval control' }
    )

    foreach ($Rule in $ValidationRules) {
        Test-Marker `
            -Path $Rule.Path `
            -Marker $Rule.Marker `
            -Description $Rule.Description
    }

    $Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

    if (@($Manifest.icons).Count -lt 2) {
        throw 'The installable manifest must retain at least two application icons.'
    }

    Write-Status -Level 'PASS' -Message 'Installable manifest retains application icons.'
    Test-NoExternalProgressTransmission -AppPath $AppPath

    $RuntimeHashesAfter = Get-FileHashMap -Paths $RuntimePaths
    Test-HashMapsMatch -Before $RuntimeHashesBefore -After $RuntimeHashesAfter

    $ChecklistContent = Get-Content -LiteralPath $ChecklistPath -Raw
    $ManualCheckCount = ([regex]::Matches($ChecklistContent, '(?m)^- \[ \]')).Count

    Write-Section -Text 'Phase 3E Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $DataMetrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $DataMetrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $DataMetrics.StepCount
    Write-Metric -Name 'Unique referenced icons' -Value $DataMetrics.ReferencedIconCount
    Write-Metric -Name 'Closeout documents' -Value 3
    Write-Metric -Name 'Manual checklist items' -Value $ManualCheckCount
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Created files' -Value $Script:CreatedFiles
    Write-Metric -Name 'Replaced files' -Value $Script:ReplacedFiles
    Write-Metric -Name 'Runtime files changed' -Value 0

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 3E COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 3E ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
