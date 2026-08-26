# ============================================================================
# Build-TechSavvySageIconGuidePhase4E.ps1
# Phase 4E - Release Closeout and Validation
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 4E Release Closeout Builder'
$Script:UtilityVersion = '0.4.2'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:WrittenFiles = 0
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
        [ValidateSet('INFO', 'CREATE', 'VALIDATE', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'CREATE'   { 'Yellow' }
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

    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $NormalizedContent = $Content.TrimEnd([char[]]@("`r", "`n")) + "`n"
    [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)
    $Script:WrittenFiles++
    Write-Status -Level 'CREATE' -Message $Path
}

function Get-FileHashMap {
    param ([Parameter(Mandatory)][string[]]$Paths)

    $Hashes = @{}

    foreach ($Path in $Paths) {
        $Hashes[$Path] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }

    return $Hashes
}

function Test-HashMapsEqual {
    param (
        [Parameter(Mandatory)][hashtable]$Before,
        [Parameter(Mandatory)][hashtable]$After
    )

    foreach ($Path in $Before.Keys) {
        if (-not $After.ContainsKey($Path) -or $Before[$Path] -cne $After[$Path]) {
            return $false
        }
    }

    return $Before.Count -eq $After.Count
}

function Test-Marker {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$Description
    )

    Write-Status -Level 'VALIDATE' -Message ("{0} :: {1}" -f $Path, $Description)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required Phase 4E file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 4E marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-Phase4Data {
    param (
        [Parameter(Mandatory)][string]$IconDataPath,
        [Parameter(Mandatory)][string]$LessonDataPath,
        [Parameter(Mandatory)][string]$AssessmentDataPath
    )

    $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
    $LessonData = Get-Content -LiteralPath $LessonDataPath -Raw | ConvertFrom-Json
    $AssessmentData = Get-Content -LiteralPath $AssessmentDataPath -Raw | ConvertFrom-Json
    $Icons = @($IconData.icons)
    $Lessons = @($LessonData.lessons)
    $Steps = @($Lessons | ForEach-Object { @($_.steps) })
    $Assessments = @($AssessmentData.assessments)
    $Questions = @($Assessments | ForEach-Object { @($_.questions) })

    if ($Icons.Count -ne 40) {
        throw 'Phase 4 requires exactly 40 icon records.'
    }

    if ($Lessons.Count -ne 4 -or $Steps.Count -ne 40) {
        throw 'Phase 4 requires four lessons and 40 lesson steps.'
    }

    if ($Assessments.Count -ne 4 -or $Questions.Count -ne 40) {
        throw 'Phase 4 requires four assessments and 40 question-bank records.'
    }

    foreach ($Assessment in $Assessments) {
        if ([int]$Assessment.questions_per_attempt -ne 5) {
            throw "Assessment '$($Assessment.id)' must present five questions per attempt."
        }
    }

    return [pscustomobject]@{
        IconCount = $Icons.Count
        LessonCount = $Lessons.Count
        StepCount = $Steps.Count
        AssessmentCount = $Assessments.Count
        QuestionCount = $Questions.Count
        QuestionsPerAttempt = 5
    }
}

function Test-AssessmentPrivacyAndCsp {
    param ([Parameter(Mandatory)][string]$AppPath)

    $Content = Get-Content -LiteralPath $AppPath -Raw
    $StartMarker = '    function findAssessmentByLesson(lessonId) {'
    $EndMarker = '    function showIconDetail(icon) {'
    $StartIndex = $Content.IndexOf($StartMarker)
    $EndIndex = $Content.IndexOf($EndMarker)

    if ($StartIndex -lt 0 -or $EndIndex -le $StartIndex) {
        throw 'Unable to isolate the Phase 4 assessment functions.'
    }

    $AssessmentContent = $Content.Substring($StartIndex, $EndIndex - $StartIndex)

    foreach ($ForbiddenMarker in @(
        'localStorage',
        'sessionStorage',
        'saveProgress(',
        'fetch(',
        'XMLHttpRequest',
        'sendBeacon',
        'eval(',
        'new Function(',
        'setTimeout("',
        "setTimeout('",
        'setInterval("',
        "setInterval('"
    )) {
        if ($AssessmentContent.Contains($ForbiddenMarker)) {
            throw "Phase 4 assessment behavior contains a forbidden marker: $ForbiddenMarker"
        }
    }

    Write-Status -Level 'PASS' -Message 'Assessment results remain session-only and CSP-safe.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 4E builder directory.'
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
    $AssessmentDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\assessments.json'
    $ManifestPath = Join-Path $ResolvedRepositoryRoot 'manifest.webmanifest'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $UserGuidePath = Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_4_User_Guide.md'
    $ReleaseNotesPath = Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_4_Release_Notes.md'
    $ChecklistPath = Join-Path $ResolvedRepositoryRoot '05_Testing\Phase_4_Regression_and_Accessibility_Checklist.md'

    $PhaseScripts = @(
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4A.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4B.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase4B.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4C.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase4C.ps1',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4D.ps1',
        '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase4D.ps1'
    ) | ForEach-Object { Join-Path $ResolvedRepositoryRoot $_ }

    $RuntimePaths = @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $IconsScriptPath,
        $IconDataPath,
        $LessonDataPath,
        $AssessmentDataPath,
        $ManifestPath,
        $ServiceWorkerPath
    )

    Write-Section -Text 'Phase 4E - Preflight Validation'

    foreach ($RequiredPath in @($RuntimePaths + $PhaseScripts)) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 4 baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    foreach ($RequiredDirectory in @(
        (Join-Path $ResolvedRepositoryRoot '01_Documentation'),
        (Join-Path $ResolvedRepositoryRoot '05_Testing')
    )) {
        if (-not (Test-Path -LiteralPath $RequiredDirectory -PathType Container)) {
            throw "Required closeout directory is missing: $RequiredDirectory"
        }
    }

    $RuntimeHashesBefore = Get-FileHashMap -Paths $RuntimePaths
    $DataMetrics = Test-Phase4Data `
        -IconDataPath $IconDataPath `
        -LessonDataPath $LessonDataPath `
        -AssessmentDataPath $AssessmentDataPath

    $Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

    if (@($Manifest.icons).Count -lt 2) {
        throw 'The installable application manifest must retain its 192px and 512px icons.'
    }

    $UserGuide = @'
# TechSavvySage Icon Guide Phase 4 User Guide

**Release:** v0.4.2

**Status:** Stable Release Candidate

**Release date:** August 26, 2026

## Purpose

The TechSavvySage Icon Guide is an accessible, untimed learning utility for 40 common computer and mobile icons. Phase 4 adds lesson knowledge checks, supportive missed-icon explanations, and targeted reinforcement while preserving Learn, Lessons, Practice, Saved for Review, display personalization, read-aloud support, offline use, and browser-only privacy.

## Lesson knowledge checks

Complete a guided lesson and select **Start knowledge check**. Each attempt presents five questions selected from that lesson's ten-question bank. Choose the meaning that matches the displayed icon. Each question provides immediate, supportive feedback and identifies the correct meaning when another answer is selected.

Knowledge checks are untimed. There is no penalty for retrying, and scores are not stored after the current page session.

## Review missed icons

After the fifth question, the results screen shows the number answered correctly. When one or more icons were missed, **Review missed icons** displays only those icons with their names, meanings, and plain-language examples. A perfect attempt does not display an unnecessary review list.

## Practice missed icons

Select **Practice missed icons** to move directly into the existing Practice mode using only the icons missed during the completed knowledge check as question targets. The missed targets are randomized. Existing Practice-mode answer choices, supportive feedback, and results remain in effect.

The targeted list exists only for the current session. Select **Lessons** at any time to return to the lesson choices.

## Other learning modes

- **Learn:** Search or filter all 40 icons and open detailed explanations.
- **Lessons:** Work through four guided lessons with browser-only resume and completion status.
- **Practice:** Choose 5, 10, 20, or all 40 questions for general practice.
- **Saved for Review:** Maintain a browser-local list of icons selected for later study.

## Accessibility

- No lesson, knowledge check, or practice activity is timed.
- Primary actions support keyboard operation.
- Question and completion headings receive focus as content changes.
- Feedback is announced through status and polite live regions.
- Controls use plain language and touch-friendly sizing.
- Standard, Large, and Extra Large text remain supported.
- High contrast and reduced-motion preferences remain supported.

## Offline use and updates

After one successful online visit, the application retains its core files, lesson data, and assessment data for offline use. Network-first loading and the `v0.4.2` service-worker cache allow a newly deployed version to replace older cached content.

## Privacy

The application requires no account and sends no learning, lesson, assessment, or practice result to an external service. Knowledge-check scores and missed-icon lists remain in memory for the current session only. Existing browser-local lesson progress and display preferences remain under the learner's control.

## Troubleshooting

- If **Start knowledge check** is not visible, finish or review the last step of a lesson.
- If **Practice missed icons** is not visible, the knowledge check contained no missed icons.
- If updated controls do not appear after deployment, reload once and allow the service worker to refresh.
- If icon or lesson content does not load, reconnect once so the offline cache can be established.
'@

    $ReleaseNotes = @'
# TechSavvySage Icon Guide v0.4.2 Release Notes

**Release date:** August 26, 2026

**Release status:** Stable Release Candidate

## Summary

Phase 4 adds a complete lesson knowledge-check and reinforcement workflow without adding accounts, external telemetry, stored assessment scores, or time pressure.

## Delivered by increment

### Phase 4A — Assessment data foundation

- Added four lesson-linked assessments.
- Added 40 validated question-bank records.
- Standardized five questions per attempt and four answer options per question.
- Preserved complete icon and lesson relationships.

### Phase 4B — Lesson knowledge-check interface

- Added the accessible five-question knowledge-check runner.
- Added randomized questions and answer choices.
- Added immediate supportive feedback, retry, and completion results.
- Added offline assessment-data caching.

### Phase 4C — Missed-icon review

- Added a results review containing only missed icons.
- Added icon names, meanings, and plain-language examples.
- Kept review state session-only and CSP-safe.

### Phase 4D — Targeted reinforcement

- Added **Practice missed icons** when an attempt contains missed targets.
- Reused the established Practice engine through `startPractice(specificIds)`.
- Randomized missed targets without creating a second practice implementation.
- Preserved session-only assessment state.

## Preserved capabilities

- Forty-icon Learn and Practice experiences
- Four guided lessons with browser-local progress and reset
- Saved for Review
- Text-size, contrast, reduced-motion, and read-aloud support
- Installable and offline-capable application behavior
- Network-first deployment refresh handling

## Security and privacy

- No account or personally identifiable information is required.
- No assessment score or missed-icon list is written to browser storage.
- No assessment or targeted-practice result is transmitted externally.
- Knowledge-check and review functions remain compatible with the existing Content Security Policy.

## Release validation

- Icon records: 40
- Lesson records: 4
- Lesson steps: 40
- Assessment records: 4
- Question-bank records: 40
- Questions per attempt: 5
- Phase scripts and functional validators: 7
- Runtime files modified by closeout: 0

## Deployment note

Deploy the committed release through the existing GitHub Pages workflow. The service worker uses cache `techsavvysage-icon-guide-v0.4.2` and retains assessment data for offline use.

## Release decision

Phase 4 is ready for final regression, accessibility review, deployment verification, and release authorization.
'@

    $Checklist = @'
# TechSavvySage Icon Guide Phase 4 Regression and Accessibility Checklist

**Release:** v0.4.2

**Review date:** ____________________

**Reviewer:** ____________________

Use `Pass`, `Fail`, or `Not Applicable` for each item. Record defects and evidence in the notes column.

## Automated baseline

| Check | Result | Notes |
| --- | --- | --- |
| PowerShell parser validation passes for Phase 4A–4E scripts |  |  |
| Phase 4B functional validator passes |  |  |
| Phase 4C functional validator passes |  |  |
| Phase 4D functional validator passes |  |  |
| Icon data contains 40 records |  |  |
| Lesson data contains 4 lessons and 40 steps |  |  |
| Assessment data contains 4 assessments and 40 questions |  |  |
| Service-worker cache is `v0.4.2` |  |  |
| Runtime hashes remain unchanged during closeout |  |  |

## Knowledge-check regression

| Check | Result | Notes |
| --- | --- | --- |
| Each completed lesson exposes **Start knowledge check** |  |  |
| Each attempt presents exactly five questions |  |  |
| Questions remain within the active lesson |  |  |
| Each question presents four unique answer choices |  |  |
| Correct answers receive supportive confirmation |  |  |
| Incorrect answers identify the correct icon meaning |  |  |
| **Next question** advances once per answered question |  |  |
| **See results** opens the completion summary |  |  |
| Retry starts a new randomized five-question attempt |  |  |

## Missed-icon review and reinforcement

| Check | Result | Notes |
| --- | --- | --- |
| Review contains only icons missed in the completed attempt |  |  |
| Each review card shows icon, name, meaning, and example |  |  |
| Perfect attempts hide the missed-icon review |  |  |
| **Practice missed icons** appears only when icons were missed |  |  |
| Targeted Practice questions use only missed icons as targets |  |  |
| Targeted Practice reuses existing answer and results behavior |  |  |
| Lessons navigation returns to lesson choices |  |  |

## Accessibility

| Check | Result | Notes |
| --- | --- | --- |
| All Phase 4 controls are reachable and operable by keyboard |  |  |
| Visible focus remains clear in standard and high contrast |  |  |
| Question and completion headings receive programmatic focus |  |  |
| Feedback is announced without moving focus unexpectedly |  |  |
| Review heading and cards follow a logical reading order |  |  |
| Controls remain usable at 200% browser zoom |  |  |
| Standard, Large, and Extra Large text do not hide controls |  |  |
| Reduced-motion preference introduces no required animation |  |  |
| Mobile layout remains usable at 320 CSS pixels |  |  |

## Privacy and security

| Check | Result | Notes |
| --- | --- | --- |
| No account or PII is requested |  |  |
| Assessment score is not written to local or session storage |  |  |
| Missed-icon assessment list is not persisted |  |  |
| Assessment and targeted-practice results are not transmitted |  |  |
| No inline event handler or dynamic code execution is introduced |  |  |
| Existing Content Security Policy produces no new violation |  |  |

## Offline and deployment

| Check | Result | Notes |
| --- | --- | --- |
| First online visit caches assessment data |  |  |
| Knowledge checks work after reconnecting in offline mode |  |  |
| Missed-icon review works offline |  |  |
| Targeted Practice works offline |  |  |
| New deployment replaces the prior service-worker cache |  |  |
| Page reload occurs no more than once during controller change |  |  |

## Release decision

**Decision:** Approve / Approve with conditions / Reject

**Approver:** ____________________

**Approval date:** ____________________

**Open defects or conditions:**
'@

    if ($OperatingMode -eq 'Build') {
        $ExistingCloseoutFiles = @(
            @($UserGuidePath, $ReleaseNotesPath, $ChecklistPath) |
                Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
        )

        if ($ExistingCloseoutFiles.Count -gt 0 -and -not $Force) {
            throw 'One or more Phase 4 closeout files already exist. Review them before rerunning Build mode with -Force.'
        }

        Write-Section -Text 'Phase 4E - Create Release Closeout Artifacts'
        Write-Utf8File -Path $UserGuidePath -Content $UserGuide
        Write-Utf8File -Path $ReleaseNotesPath -Content $ReleaseNotes
        Write-Utf8File -Path $ChecklistPath -Content $Checklist
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 4E - Automated Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="assessment-runner"'; Description = 'Knowledge-check region' },
        @{ Path = $IndexPath; Marker = 'id="assessment-review"'; Description = 'Missed-icon review region' },
        @{ Path = $IndexPath; Marker = 'id="assessment-practice-missed"'; Description = 'Targeted-practice control' },
        @{ Path = $IndexPath; Marker = 'aria-live="polite"'; Description = 'Accessible feedback region' },
        @{ Path = $StylesPath; Marker = '/* Phase 4B: lesson knowledge checks */'; Description = 'Knowledge-check styles' },
        @{ Path = $StylesPath; Marker = '/* Phase 4C: missed icon review */'; Description = 'Missed-icon review styles' },
        @{ Path = $StylesPath; Marker = ':focus-visible'; Description = 'Visible keyboard focus' },
        @{ Path = $AppPath; Marker = 'function startAssessment(lessonId)'; Description = 'Knowledge-check start behavior' },
        @{ Path = $AppPath; Marker = 'function showAssessmentQuestion()'; Description = 'Question rendering behavior' },
        @{ Path = $AppPath; Marker = 'function answerAssessment(answerIconId)'; Description = 'Supportive answer feedback' },
        @{ Path = $AppPath; Marker = 'function completeAssessment()'; Description = 'Completion summary' },
        @{ Path = $AppPath; Marker = 'function renderAssessmentReview()'; Description = 'Missed-icon explanation renderer' },
        @{ Path = $AppPath; Marker = 'function startPractice(specificIds)'; Description = 'Existing targeted-practice engine' },
        @{ Path = $AppPath; Marker = 'startPractice(missedIconIds)'; Description = 'Missed-icon practice handoff' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Controlled deployment reload' },
        @{ Path = $IconsScriptPath; Marker = 'window.IconGuideIcons'; Description = 'SVG icon renderer' },
        @{ Path = $ServiceWorkerPath; Marker = 'techsavvysage-icon-guide-v0.4.2'; Description = 'Phase 4 release cache' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/assessments.json'"; Description = 'Offline assessment data' },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(asset, { cache: 'reload' })"; Description = 'Fresh install caching' },
        @{ Path = $ServiceWorkerPath; Marker = 'fetch(event.request)'; Description = 'Network-first loading' },
        @{ Path = $UserGuidePath; Marker = '# TechSavvySage Icon Guide Phase 4 User Guide'; Description = 'Phase 4 user guide' },
        @{ Path = $UserGuidePath; Marker = '## Practice missed icons'; Description = 'Targeted reinforcement guidance' },
        @{ Path = $ReleaseNotesPath; Marker = '# TechSavvySage Icon Guide v0.4.2 Release Notes'; Description = 'Phase 4 release notes' },
        @{ Path = $ReleaseNotesPath; Marker = '## Release decision'; Description = 'Release decision guidance' },
        @{ Path = $ChecklistPath; Marker = '# TechSavvySage Icon Guide Phase 4 Regression and Accessibility Checklist'; Description = 'Phase 4 checklist' },
        @{ Path = $ChecklistPath; Marker = '## Privacy and security'; Description = 'Privacy validation checklist' },
        @{ Path = $ChecklistPath; Marker = '## Release decision'; Description = 'Release authorization checklist' }
    )

    foreach ($Rule in $ValidationRules) {
        Test-Marker `
            -Path $Rule.Path `
            -Marker $Rule.Marker `
            -Description $Rule.Description
    }

    Test-AssessmentPrivacyAndCsp -AppPath $AppPath

    $RuntimeHashesAfter = Get-FileHashMap -Paths $RuntimePaths
    $RuntimeUnchanged = Test-HashMapsEqual `
        -Before $RuntimeHashesBefore `
        -After $RuntimeHashesAfter

    if (-not $RuntimeUnchanged) {
        throw 'Phase 4E closeout changed one or more runtime files.'
    }

    Write-Status -Level 'PASS' -Message 'Phase 4E closeout made zero runtime changes.'

    Write-Section -Text 'Phase 4E Execution Metrics'
    Write-Metric -Name 'Icon records' -Value $DataMetrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $DataMetrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $DataMetrics.StepCount
    Write-Metric -Name 'Assessment records' -Value $DataMetrics.AssessmentCount
    Write-Metric -Name 'Question-bank records' -Value $DataMetrics.QuestionCount
    Write-Metric -Name 'Questions per attempt' -Value $DataMetrics.QuestionsPerAttempt
    Write-Metric -Name 'Phase scripts and validators' -Value $PhaseScripts.Count
    Write-Metric -Name 'Closeout files written' -Value $Script:WrittenFiles
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Runtime files checked' -Value $RuntimePaths.Count
    Write-Metric -Name 'Runtime file changes' -Value 0
    Write-Metric -Name 'Assessment result storage' -Value 'Session only'

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4E COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 4E ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
