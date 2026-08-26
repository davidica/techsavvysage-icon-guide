# ============================================================================
# Build-TechSavvySageIconGuidePhase4C.ps1
# Phase 4C - Missed Icon Review
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 4C Missed Icon Review Builder'
$Script:UtilityVersion = '0.4.1'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:UpdatedFileOperations = 0
$Script:ExistingUpdates = 0
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
        [ValidateSet('INFO', 'UPDATE', 'VALIDATE', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'UPDATE'   { 'Yellow' }
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
    $Script:UpdatedFileOperations++
    Write-Status -Level 'UPDATE' -Message $Path
}

function Test-TextUpdatePlan {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText,
        [Parameter(Mandatory)][string]$Description
    )

    $Content = Get-Content -LiteralPath $Path -Raw

    if ($Content.Contains($NewText)) {
        Write-Status -Level 'INFO' -Message "Already present: $Description"
        return
    }

    if (-not $Content.Contains($OldText)) {
        throw "The expected Phase 4C marker was not found for '$Description' in: $Path"
    }

    Write-Status -Level 'PASS' -Message "Ready to update: $Description"
}

function Invoke-TextUpdate {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText,
        [Parameter(Mandatory)][string]$Description
    )

    $Content = Get-Content -LiteralPath $Path -Raw

    if ($Content.Contains($NewText)) {
        $Script:ExistingUpdates++
        Write-Status -Level 'INFO' -Message "Update already present: $Description"
        return
    }

    if (-not $Content.Contains($OldText)) {
        throw "The expected marker disappeared before '$Description' could be applied."
    }

    Write-Utf8File -Path $Path -Content $Content.Replace($OldText, $NewText)
}

function Test-Marker {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$Description
    )

    Write-Status -Level 'VALIDATE' -Message ("{0} :: {1}" -f $Path, $Description)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required Phase 4C file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 4C marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-AnyMarker {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string[]]$Markers,
        [Parameter(Mandatory)][string]$Description
    )

    $Content = Get-Content -LiteralPath $Path -Raw
    $Matched = $false

    foreach ($Marker in $Markers) {
        if ($Content.Contains($Marker)) {
            $Matched = $true
            break
        }
    }

    if (-not $Matched) {
        throw "Required Phase 4C baseline marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-AssessmentData {
    param ([Parameter(Mandatory)][string]$AssessmentDataPath)

    $AssessmentData = Get-Content -LiteralPath $AssessmentDataPath -Raw | ConvertFrom-Json
    $Assessments = @($AssessmentData.assessments)
    $Questions = @($Assessments | ForEach-Object { @($_.questions) })

    if ($Assessments.Count -ne 4) {
        throw 'Phase 4C requires the four-assessment Phase 4A data baseline.'
    }

    if ($Questions.Count -ne 40) {
        throw 'Phase 4C requires the 40-question Phase 4A data baseline.'
    }

    return [pscustomobject]@{
        AssessmentCount = $Assessments.Count
        QuestionCount = $Questions.Count
    }
}

function Test-ReviewPrivacyAndCsp {
    param ([Parameter(Mandatory)][string]$AppPath)

    $Content = Get-Content -LiteralPath $AppPath -Raw
    $StartMarker = '    function findAssessmentByLesson(lessonId) {'
    $EndMarker = '    function showIconDetail(icon) {'
    $StartIndex = $Content.IndexOf($StartMarker)
    $EndIndex = $Content.IndexOf($EndMarker)

    if ($StartIndex -lt 0 -or $EndIndex -le $StartIndex) {
        throw 'Unable to isolate the Phase 4C knowledge-check functions.'
    }

    $ReviewContent = $Content.Substring($StartIndex, $EndIndex - $StartIndex)

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
        if ($ReviewContent.Contains($ForbiddenMarker)) {
            throw "Phase 4C missed-icon review contains a forbidden marker: $ForbiddenMarker"
        }
    }

    Write-Status -Level 'PASS' -Message 'Missed-icon review remains session-only and CSP-safe.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 4C builder directory.'
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
    $AssessmentDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\assessments.json'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $Phase4BPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4B.ps1'

    Write-Section -Text 'Phase 4C - Preflight Validation'

    foreach ($RequiredPath in @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $AssessmentDataPath,
        $ServiceWorkerPath,
        $Phase4BPath
    )) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The committed Phase 4B baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    Test-Marker `
        -Path $AppPath `
        -Marker 'function completeAssessment()' `
        -Description 'Phase 4B assessment completion baseline'
    Test-Marker `
        -Path $IndexPath `
        -Marker 'id="assessment-feedback"' `
        -Description 'Phase 4B accessible feedback baseline'
    Test-AnyMarker `
        -Path $ServiceWorkerPath `
        -Markers @(
            'techsavvysage-icon-guide-v0.4.0',
            'techsavvysage-icon-guide-v0.4.1'
        ) `
        -Description 'Supported Phase 4 release cache baseline'

    $DataMetrics = Test-AssessmentData -AssessmentDataPath $AssessmentDataPath

    $OldReviewRegion = @'
                            <p id="assessment-feedback" class="assessment-feedback" role="status" aria-live="polite" hidden></p>
                            <div class="assessment-navigation">
'@
    $NewReviewRegion = @'
                            <p id="assessment-feedback" class="assessment-feedback" role="status" aria-live="polite" hidden></p>
                            <section id="assessment-review" class="assessment-review" aria-labelledby="assessment-review-heading" hidden>
                                <h4 id="assessment-review-heading" tabindex="-1">Review missed icons</h4>
                                <p>Take another look at the icons that need more practice.</p>
                                <div id="assessment-review-list" class="assessment-review-list"></div>
                            </section>
                            <div class="assessment-navigation">
'@

    $OldReviewState = @'
        assessmentAnswered: false,
        assessmentComplete: false,
        filteredIcons: [],
'@
    $NewReviewState = @'
        assessmentAnswered: false,
        assessmentComplete: false,
        assessmentMissedIconIds: [],
        filteredIcons: [],
'@

    $OldCatalogReviewReset = @'
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        renderLessonCatalog();
'@
    $NewCatalogReviewReset = @'
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        state.assessmentMissedIconIds = [];
        renderLessonCatalog();
'@

    $OldAttemptReviewReset = @'
        state.assessmentScore = 0;
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        elements.exitLesson.hidden = true;
'@
    $NewAttemptReviewReset = @'
        state.assessmentScore = 0;
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        state.assessmentMissedIconIds = [];
        elements.exitLesson.hidden = true;
'@

    $OldQuestionReviewReset = @'
        elements.assessmentRetry.hidden = true;
        elements.assessmentReturn.hidden = true;
        setStatus('Knowledge check question ' + questionNumber + ' of ' + totalQuestions + '. Choose one answer.');
'@
    $NewQuestionReviewReset = @'
        elements.assessmentRetry.hidden = true;
        elements.assessmentReturn.hidden = true;
        elements.assessmentReview.hidden = true;
        elements.assessmentReviewList.innerHTML = '';
        setStatus('Knowledge check question ' + questionNumber + ' of ' + totalQuestions + '. Choose one answer.');
'@

    $OldMissedAnswerCapture = @'
        else {
            elements.assessmentFeedback.className = 'assessment-feedback';
            elements.assessmentFeedback.textContent = 'Good try. The ' + correctIcon.name + ' icon ' + correctIcon.meaning;
        }
'@
    $NewMissedAnswerCapture = @'
        else {
            if (state.assessmentMissedIconIds.indexOf(correctIcon.id) === -1) {
                state.assessmentMissedIconIds.push(correctIcon.id);
            }

            elements.assessmentFeedback.className = 'assessment-feedback';
            elements.assessmentFeedback.textContent = 'Good try. The ' + correctIcon.name + ' icon ' + correctIcon.meaning;
        }
'@

    $OldReviewFunction = @'
    function completeAssessment() {
'@
    $NewReviewFunction = @'
    function renderAssessmentReview() {
        elements.assessmentReviewList.innerHTML = '';

        if (state.assessmentMissedIconIds.length === 0) {
            elements.assessmentReview.hidden = true;
            return;
        }

        state.assessmentMissedIconIds.forEach(function (iconId) {
            const icon = findIcon(iconId);

            if (!icon) {
                return;
            }

            const card = document.createElement('article');
            const visual = document.createElement('div');
            const copy = document.createElement('div');
            const heading = document.createElement('h5');
            const meaning = document.createElement('p');
            const example = document.createElement('p');

            card.className = 'assessment-review-card';
            visual.className = 'assessment-review-icon';
            visual.setAttribute('aria-hidden', 'true');
            visual.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
            heading.textContent = icon.name;
            meaning.textContent = icon.meaning;
            example.className = 'detail-secondary';
            example.textContent = 'Example: ' + icon.example;
            copy.appendChild(heading);
            copy.appendChild(meaning);
            copy.appendChild(example);
            card.appendChild(visual);
            card.appendChild(copy);
            elements.assessmentReviewList.appendChild(card);
        });

        elements.assessmentReview.hidden = false;
    }

    function completeAssessment() {
'@

    $OldReviewDisplay = @'
        elements.assessmentFeedback.hidden = false;
        elements.assessmentProgress.max = totalQuestions;
'@
    $NewReviewDisplay = @'
        elements.assessmentFeedback.hidden = false;
        renderAssessmentReview();
        elements.assessmentProgress.max = totalQuestions;
'@

    $OldReviewCapture = @'
            'assessment-feedback', 'assessment-next', 'assessment-retry',
            'assessment-return',
'@
    $NewReviewCapture = @'
            'assessment-feedback', 'assessment-review', 'assessment-review-heading',
            'assessment-review-list', 'assessment-next', 'assessment-retry',
            'assessment-return',
'@

    $OldCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.4.0';"
    $NewCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.4.1';"

    $Updates = @(
        @{ Path = $IndexPath; Old = $OldReviewRegion; New = $NewReviewRegion; Description = 'Accessible missed-icon review region' },
        @{ Path = $AppPath; Old = $OldReviewState; New = $NewReviewState; Description = 'Session-only missed-icon state' },
        @{ Path = $AppPath; Old = $OldCatalogReviewReset; New = $NewCatalogReviewReset; Description = 'Catalog review-state reset' },
        @{ Path = $AppPath; Old = $OldAttemptReviewReset; New = $NewAttemptReviewReset; Description = 'New-attempt review-state reset' },
        @{ Path = $AppPath; Old = $OldQuestionReviewReset; New = $NewQuestionReviewReset; Description = 'Question review-region reset' },
        @{ Path = $AppPath; Old = $OldMissedAnswerCapture; New = $NewMissedAnswerCapture; Description = 'Incorrect-answer capture' },
        @{ Path = $AppPath; Old = $OldReviewFunction; New = $NewReviewFunction; Description = 'Missed-icon explanation renderer' },
        @{ Path = $AppPath; Old = $OldReviewDisplay; New = $NewReviewDisplay; Description = 'Completion review display' },
        @{ Path = $AppPath; Old = $OldReviewCapture; New = $NewReviewCapture; Description = 'Missed-icon review element capture' },
        @{ Path = $ServiceWorkerPath; Old = $OldCacheName; New = $NewCacheName; Description = 'Phase 4C cache version' }
    )

    $Phase4CStyles = @'

/* Phase 4C: missed icon review */
.assessment-review {
    margin-top: 1.25rem;
    border-top: 0.1rem solid var(--border);
    padding-top: 1rem;
}

.assessment-review h4 {
    margin: 0 0 0.35rem;
    font-size: 1.2rem;
}

.assessment-review-list {
    display: grid;
    gap: 0.85rem;
    margin-top: 1rem;
}

.assessment-review-card {
    display: grid;
    grid-template-columns: 4.5rem 1fr;
    gap: 1rem;
    align-items: start;
    border: 0.1rem solid var(--border);
    border-radius: 0.55rem;
    padding: 0.9rem;
    background: var(--warm-gray);
}

.assessment-review-card h5 {
    margin: 0 0 0.25rem;
    font-size: 1.05rem;
}

.assessment-review-card p {
    margin: 0.25rem 0 0;
}

.assessment-review-icon {
    display: grid;
    place-items: center;
    min-height: 4rem;
}

.assessment-review-icon svg {
    width: 3.25rem;
    height: 3.25rem;
}

@media (max-width: 520px) {
    .assessment-review-card {
        grid-template-columns: 1fr;
    }

    .assessment-review-icon {
        justify-content: start;
    }
}
'@

    Write-Section -Text 'Phase 4C - Controlled Update Plan'

    foreach ($Update in $Updates) {
        Test-TextUpdatePlan `
            -Path $Update.Path `
            -OldText $Update.Old `
            -NewText $Update.New `
            -Description $Update.Description
    }

    $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

    if ($ExistingStyles.Contains('/* Phase 4C: missed icon review */')) {
        Write-Status -Level 'INFO' -Message 'Phase 4C missed-icon review styles are already present.'
    }
    elseif (-not $ExistingStyles.Contains('/* Phase 4B: lesson knowledge checks */')) {
        throw 'The Phase 4B knowledge-check style marker was not found.'
    }
    else {
        Write-Status -Level 'PASS' -Message 'Missed-icon review styles are ready to append.'
    }

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 4C updates controlled application files. Run Build mode with -Force after confirming Phase 4B is committed.'
        }

        Write-Section -Text 'Phase 4C - Missed Icon Review Build'

        foreach ($Update in $Updates) {
            Invoke-TextUpdate `
                -Path $Update.Path `
                -OldText $Update.Old `
                -NewText $Update.New `
                -Description $Update.Description
        }

        $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

        if ($ExistingStyles.Contains('/* Phase 4C: missed icon review */')) {
            $Script:ExistingUpdates++
            Write-Status -Level 'INFO' -Message 'Missed-icon review styles already present.'
        }
        else {
            Write-Utf8File `
                -Path $StylesPath `
                -Content ($ExistingStyles.TrimEnd([char[]]@("`r", "`n")) + $Phase4CStyles)
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 4C - Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="assessment-review"'; Description = 'Missed-icon review region' },
        @{ Path = $IndexPath; Marker = 'id="assessment-review-heading"'; Description = 'Accessible review heading' },
        @{ Path = $IndexPath; Marker = 'id="assessment-review-list"'; Description = 'Missed-icon review list' },
        @{ Path = $StylesPath; Marker = '/* Phase 4C: missed icon review */'; Description = 'Missed-icon review styles' },
        @{ Path = $StylesPath; Marker = '.assessment-review-card'; Description = 'Responsive review cards' },
        @{ Path = $AppPath; Marker = 'assessmentMissedIconIds: []'; Description = 'Session-only missed-icon state' },
        @{ Path = $AppPath; Marker = 'function renderAssessmentReview()'; Description = 'Missed-icon review renderer' },
        @{ Path = $AppPath; Marker = "state.assessmentMissedIconIds.push(correctIcon.id)"; Description = 'Incorrect-answer capture' },
        @{ Path = $AppPath; Marker = "example.textContent = 'Example: ' + icon.example"; Description = 'Plain-language icon example' },
        @{ Path = $AppPath; Marker = 'elements.assessmentReview.hidden = false'; Description = 'Review display after completion' },
        @{ Path = $AppPath; Marker = 'renderAssessmentReview();'; Description = 'Completion review invocation' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check preserved' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior preserved' },
        @{ Path = $ServiceWorkerPath; Marker = 'techsavvysage-icon-guide-v0.4.1'; Description = 'Phase 4C cache version' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/assessments.json'"; Description = 'Offline assessment data preserved' },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(asset, { cache: 'reload' })"; Description = 'Fresh install caching preserved' },
        @{ Path = $ServiceWorkerPath; Marker = 'fetch(event.request)'; Description = 'Network-first loading preserved' }
    )

    foreach ($Rule in $ValidationRules) {
        Test-Marker `
            -Path $Rule.Path `
            -Marker $Rule.Marker `
            -Description $Rule.Description
    }

    Test-ReviewPrivacyAndCsp -AppPath $AppPath

    Write-Section -Text 'Phase 4C Execution Metrics'
    Write-Metric -Name 'Assessment records' -Value $DataMetrics.AssessmentCount
    Write-Metric -Name 'Question-bank records' -Value $DataMetrics.QuestionCount
    Write-Metric -Name 'Controlled update rules' -Value $Updates.Count
    Write-Metric -Name 'Updated file operations' -Value $Script:UpdatedFileOperations
    Write-Metric -Name 'Existing updates' -Value $Script:ExistingUpdates
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Review scope' -Value 'Missed icons only'
    Write-Metric -Name 'Assessment result storage' -Value 'Session only'

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4C COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 4C ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
