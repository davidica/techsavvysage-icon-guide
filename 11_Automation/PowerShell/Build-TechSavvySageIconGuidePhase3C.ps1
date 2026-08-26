# ============================================================================
# Build-TechSavvySageIconGuidePhase3C.ps1
# Phase 3C - Guided Lesson Progression
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 3C Builder'
$Script:UtilityVersion = '0.3.1'
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

    Write-Host ('{0,-32}: {1}' -f $Name, $Value)
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
        throw "The expected Phase 3C marker was not found for '$Description' in: $Path"
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
        throw "Required Phase 3C file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 3C marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-LessonData {
    param (
        [Parameter(Mandatory)][string]$IconDataPath,
        [Parameter(Mandatory)][string]$LessonDataPath
    )

    $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
    $LessonData = Get-Content -LiteralPath $LessonDataPath -Raw | ConvertFrom-Json
    $IconIds = @($IconData.icons | ForEach-Object { [string]$_.id })
    $Lessons = @($LessonData.lessons)
    $Steps = @($Lessons | ForEach-Object { @($_.steps) })

    if ($IconIds.Count -ne 40) {
        throw "Expected 40 icon records; found $($IconIds.Count)."
    }

    if ($Lessons.Count -ne 4) {
        throw "Expected four lesson records; found $($Lessons.Count)."
    }

    if ($Steps.Count -ne 40) {
        throw "Expected 40 lesson steps; found $($Steps.Count)."
    }

    $UnknownReferences = @(
        $Steps |
        Where-Object { $IconIds -cnotcontains [string]$_.icon_id }
    )

    if ($UnknownReferences.Count -gt 0) {
        throw 'One or more lesson steps reference an unknown icon identifier.'
    }

    Write-Status -Level 'PASS' -Message 'Four lessons and 40 icon references remain valid.'

    return [pscustomobject]@{
        IconCount = $IconIds.Count
        LessonCount = $Lessons.Count
        StepCount = $Steps.Count
    }
}

function Test-NoPersistentLessonTracking {
    param ([Parameter(Mandatory)][string]$AppPath)

    $Content = Get-Content -LiteralPath $AppPath -Raw
    $StartMarker = '    function currentLesson() {'
    $EndMarker = '    function showIconDetail(icon) {'
    $StartIndex = $Content.IndexOf($StartMarker)
    $EndIndex = $Content.IndexOf($EndMarker)

    if ($StartIndex -lt 0 -or $EndIndex -le $StartIndex) {
        throw 'Unable to isolate the Phase 3C lesson-runner functions.'
    }

    $RunnerContent = $Content.Substring($StartIndex, $EndIndex - $StartIndex)

    if ($RunnerContent.Contains('saveProgress(')) {
        throw 'Phase 3C lesson-runner functions must not persist completion data.'
    }

    Write-Status -Level 'PASS' -Message 'Lesson progression remains session-only.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 3C builder directory.'
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
    $IconDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\icons.json'
    $LessonDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\lessons.json'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $Phase3BPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3B.ps1'

    Write-Section -Text 'Phase 3C - Preflight Validation'

    foreach ($RequiredPath in @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $IconDataPath,
        $LessonDataPath,
        $ServiceWorkerPath,
        $Phase3BPath
    )) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 3B baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    Test-Marker `
        -Path $AppPath `
        -Marker 'function renderLessonCatalog()' `
        -Description 'Phase 3B lesson catalog baseline'
    Test-Marker `
        -Path $AppPath `
        -Marker 'registration.update()' `
        -Description 'Deployment update behavior preserved'

    $ServiceWorkerBaseline = Get-Content -LiteralPath $ServiceWorkerPath -Raw

    if (
        -not $ServiceWorkerBaseline.Contains('techsavvysage-icon-guide-v0.3.0') -and
        -not $ServiceWorkerBaseline.Contains('techsavvysage-icon-guide-v0.3.1')
    ) {
        throw 'The expected Phase 3B or Phase 3C service-worker baseline was not found.'
    }

    Write-Status -Level 'PASS' -Message 'Deployment-hardened service-worker baseline is present.'

    $LessonMetrics = Test-LessonData `
        -IconDataPath $IconDataPath `
        -LessonDataPath $LessonDataPath

    $OldCatalogHeader = @'
        <section id="lessons-panel" class="lessons-panel" aria-labelledby="lessons-heading" hidden>
            <div class="section-heading-row">
'@
    $NewCatalogHeader = @'
        <section id="lessons-panel" class="lessons-panel" aria-labelledby="lessons-heading" hidden>
            <div id="lesson-catalog-header" class="section-heading-row">
'@

    $OldCatalogIntro = @'
            <p>Preview a short lesson before beginning. Lesson progress will be added in the next Phase 3 increment.</p>
'@
    $NewCatalogIntro = @'
            <p id="lesson-catalog-intro">Preview a short lesson, then begin when you are ready. Progress in Phase 3C remains in the current session only.</p>
'@

    $OldLessonPreview = @'
            <section id="lesson-preview" class="lesson-preview" aria-labelledby="lesson-preview-title" hidden>
                <p id="lesson-preview-number" class="detail-category"></p>
                <h3 id="lesson-preview-title"></h3>
                <p id="lesson-preview-summary"></p>
                <p id="lesson-preview-meta" class="lesson-meta"></p>
                <p class="detail-secondary">This preview is read-only. Guided step controls will be added in the next increment.</p>
            </section>
'@
    $NewLessonPreview = @'
            <section id="lesson-preview" class="lesson-preview" aria-labelledby="lesson-preview-title" hidden>
                <p id="lesson-preview-number" class="detail-category"></p>
                <h3 id="lesson-preview-title"></h3>
                <p id="lesson-preview-summary"></p>
                <p id="lesson-preview-meta" class="lesson-meta"></p>
                <button id="start-lesson" class="primary-button" type="button">Start lesson</button>
            </section>

            <section id="lesson-runner" class="lesson-runner" aria-labelledby="lesson-step-heading" hidden>
                <button id="exit-lesson" class="text-button" type="button">Back to lesson choices</button>
                <div class="lesson-progress-row">
                    <span id="lesson-progress-text">Step 1 of 1</span>
                    <progress id="lesson-progress" value="1" max="1">Step 1 of 1</progress>
                </div>
                <div class="lesson-step-card">
                    <div id="lesson-step-icon" class="large-icon lesson-step-icon" aria-hidden="true"></div>
                    <div class="lesson-step-copy">
                        <p id="lesson-step-label" class="detail-category"></p>
                        <h3 id="lesson-step-heading" tabindex="-1"></h3>
                        <p id="lesson-step-instruction"></p>
                        <p id="lesson-step-practice" class="detail-secondary">
                            <strong>Try this:</strong>
                            <span id="lesson-step-prompt"></span>
                        </p>
                        <div class="lesson-navigation">
                            <button id="lesson-previous" class="secondary-button" type="button">Previous step</button>
                            <button id="lesson-next" class="primary-button" type="button">Next step</button>
                        </div>
                    </div>
                </div>
            </section>
'@

    $Phase3CStyles = @'

/* Phase 3C: guided lesson progression */
.lesson-runner {
    margin-top: 1rem;
}

.lesson-progress-row {
    display: grid;
    gap: 0.4rem;
    margin: 1rem 0;
    font-weight: 700;
}

.lesson-progress-row progress {
    width: 100%;
    min-height: 1rem;
}

.lesson-step-card {
    display: grid;
    grid-template-columns: minmax(7rem, 10rem) 1fr;
    gap: 1.25rem;
    align-items: start;
    border: 0.1rem solid var(--border);
    border-radius: 0.7rem;
    padding: 1.25rem;
    background: var(--surface);
}

.lesson-step-icon {
    margin: 0 auto;
}

.lesson-step-copy h3 {
    margin-top: 0.25rem;
    font-size: 1.35rem;
}

.lesson-navigation {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-top: 1.1rem;
}

.lesson-navigation .primary-button,
.lesson-preview .primary-button {
    margin-top: 0;
}

@media (max-width: 700px) {
    .lesson-step-card {
        grid-template-columns: 1fr;
    }

    .lesson-navigation button {
        width: 100%;
    }
}
'@

    $OldLessonState = @'
        lessons: [],
        selectedLessonId: null,
        filteredIcons: [],
'@
    $NewLessonState = @'
        lessons: [],
        selectedLessonId: null,
        activeLessonId: null,
        lessonStepIndex: 0,
        lessonSessionComplete: false,
        filteredIcons: [],
'@

    $OldPreviewSelection = @'
        elements.lessonPreviewMeta.textContent = lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps';
        elements.lessonPreview.hidden = false;
'@
    $NewPreviewSelection = @'
        elements.lessonPreviewMeta.textContent = lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps';
        elements.startLesson.dataset.lessonId = lesson.id;
        elements.lessonPreview.hidden = false;
'@

    $OldRunnerFunctionMarker = @'
    function showIconDetail(icon) {
'@
    $NewRunnerFunctionMarker = @'
    function currentLesson() {
        return findLesson(state.activeLessonId);
    }

    function showLessonCatalog() {
        state.activeLessonId = null;
        state.lessonSessionComplete = false;
        elements.lessonCatalogHeader.hidden = false;
        elements.lessonCatalogIntro.hidden = false;
        elements.lessonGrid.hidden = false;
        elements.lessonRunner.hidden = true;
        renderLessonCatalog();

        if (state.selectedLessonId) {
            showLessonPreview(findLesson(state.selectedLessonId));
        }
        else {
            elements.lessonPreview.hidden = true;
        }
    }

    function showLessonStep() {
        const lesson = currentLesson();

        if (!lesson) {
            showLessonCatalog();
            return;
        }

        const step = lesson.steps[state.lessonStepIndex];
        const icon = findIcon(step.icon_id);
        const stepNumber = state.lessonStepIndex + 1;
        const totalSteps = lesson.steps.length;

        state.lessonSessionComplete = false;
        elements.lessonStepIcon.hidden = false;
        elements.lessonStepIcon.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
        elements.lessonStepLabel.textContent = 'Lesson ' + lesson.order + ' · Step ' + stepNumber + ' of ' + totalSteps + ' · ' + icon.name;
        elements.lessonStepHeading.textContent = step.heading;
        elements.lessonStepInstruction.textContent = step.instruction;
        elements.lessonStepPrompt.textContent = step.practice_prompt;
        elements.lessonStepPractice.hidden = false;
        elements.lessonProgress.max = totalSteps;
        elements.lessonProgress.value = stepNumber;
        elements.lessonProgress.textContent = 'Step ' + stepNumber + ' of ' + totalSteps;
        elements.lessonProgressText.textContent = 'Step ' + stepNumber + ' of ' + totalSteps;
        elements.lessonPrevious.hidden = false;
        elements.lessonPrevious.disabled = state.lessonStepIndex === 0;
        elements.lessonNext.dataset.action = 'advance';
        elements.lessonNext.textContent = state.lessonStepIndex === totalSteps - 1
            ? 'Finish lesson'
            : 'Next step';
        setStatus(lesson.title + '. Step ' + stepNumber + ' of ' + totalSteps + '.');
        elements.lessonStepHeading.focus();
    }

    function startLesson(id) {
        const lesson = findLesson(id);

        if (!lesson) {
            setStatus('The selected lesson is unavailable.');
            return;
        }

        state.selectedLessonId = lesson.id;
        state.activeLessonId = lesson.id;
        state.lessonStepIndex = 0;
        state.lessonSessionComplete = false;
        elements.lessonCatalogHeader.hidden = true;
        elements.lessonCatalogIntro.hidden = true;
        elements.lessonGrid.hidden = true;
        elements.lessonsEmpty.hidden = true;
        elements.lessonPreview.hidden = true;
        elements.lessonRunner.hidden = false;
        showLessonStep();
    }

    function completeLessonSession() {
        const lesson = currentLesson();

        if (!lesson) {
            showLessonCatalog();
            return;
        }

        state.lessonSessionComplete = true;
        elements.lessonStepIcon.innerHTML = '';
        elements.lessonStepIcon.hidden = true;
        elements.lessonStepLabel.textContent = 'Lesson complete';
        elements.lessonStepHeading.textContent = lesson.title;
        elements.lessonStepInstruction.textContent = lesson.completion_message;
        elements.lessonStepPractice.hidden = true;
        elements.lessonProgress.value = lesson.steps.length;
        elements.lessonProgressText.textContent = lesson.steps.length + ' of ' + lesson.steps.length + ' steps complete';
        elements.lessonPrevious.hidden = true;
        elements.lessonNext.dataset.action = 'return';
        elements.lessonNext.textContent = 'Return to lesson choices';
        setStatus(lesson.title + ' completed for this session.');
        elements.lessonStepHeading.focus();
    }

    function moveLessonStep(direction) {
        const lesson = currentLesson();

        if (!lesson) {
            showLessonCatalog();
            return;
        }

        const nextIndex = state.lessonStepIndex + direction;

        if (nextIndex < 0 || nextIndex >= lesson.steps.length) {
            return;
        }

        state.lessonStepIndex = nextIndex;
        showLessonStep();
    }

    function showIconDetail(icon) {
'@

    $OldLessonsModeBlock = @'
        if (mode === 'lessons') {
            elements.learnDetail.hidden = true;
            elements.iconChoiceSection.hidden = true;
            renderLessonCatalog();

            if (state.selectedLessonId) {
                showLessonPreview(findLesson(state.selectedLessonId));
            }
            else {
                elements.lessonPreview.hidden = true;
            }

            setStatus('Four guided lessons are available. Choose one to preview.');
            return;
        }
'@
    $NewLessonsModeBlock = @'
        if (mode === 'lessons') {
            elements.learnDetail.hidden = true;
            elements.iconChoiceSection.hidden = true;
            showLessonCatalog();
            setStatus('Four guided lessons are available. Choose one to preview.');
            return;
        }
'@

    $OldRunnerEvents = @'
        elements.lessonGrid.addEventListener('click', function (event) {
'@
    $NewRunnerEvents = @'
        elements.startLesson.addEventListener('click', function () {
            startLesson(elements.startLesson.dataset.lessonId);
        });
        elements.exitLesson.addEventListener('click', function () {
            showLessonCatalog();
            setStatus('Returned to the lesson choices.');
        });
        elements.lessonPrevious.addEventListener('click', function () {
            moveLessonStep(-1);
        });
        elements.lessonNext.addEventListener('click', function () {
            if (elements.lessonNext.dataset.action === 'return') {
                showLessonCatalog();
                setStatus('Returned to the lesson choices.');
                return;
            }

            const lesson = currentLesson();

            if (lesson && state.lessonStepIndex === lesson.steps.length - 1) {
                completeLessonSession();
                return;
            }

            moveLessonStep(1);
        });
        elements.lessonGrid.addEventListener('click', function (event) {
'@

    $OldLessonCapture = @'
            'result-status', 'lessons-panel', 'lesson-count', 'lesson-grid',
            'lessons-empty', 'lesson-preview', 'lesson-preview-number',
            'lesson-preview-title', 'lesson-preview-summary', 'lesson-preview-meta',
            'learn-detail', 'detail-icon', 'detail-category',
'@
    $NewLessonCapture = @'
            'result-status', 'lessons-panel', 'lesson-catalog-header',
            'lesson-catalog-intro', 'lesson-count', 'lesson-grid', 'lessons-empty',
            'lesson-preview', 'lesson-preview-number', 'lesson-preview-title',
            'lesson-preview-summary', 'lesson-preview-meta', 'start-lesson',
            'lesson-runner', 'exit-lesson', 'lesson-progress-text',
            'lesson-progress', 'lesson-step-icon', 'lesson-step-label',
            'lesson-step-heading', 'lesson-step-instruction', 'lesson-step-practice',
            'lesson-step-prompt', 'lesson-previous', 'lesson-next',
            'learn-detail', 'detail-icon', 'detail-category',
'@

    $OldCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.3.0';"
    $NewCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.3.1';"

    $Updates = @(
        @{ Path = $IndexPath; Old = $OldCatalogHeader; New = $NewCatalogHeader; Description = 'Lesson catalog header control' },
        @{ Path = $IndexPath; Old = $OldCatalogIntro; New = $NewCatalogIntro; Description = 'Session-only lesson guidance' },
        @{ Path = $IndexPath; Old = $OldLessonPreview; New = $NewLessonPreview; Description = 'Start control and lesson runner' },
        @{ Path = $AppPath; Old = $OldLessonState; New = $NewLessonState; Description = 'Session lesson state' },
        @{ Path = $AppPath; Old = $OldPreviewSelection; New = $NewPreviewSelection; Description = 'Start lesson selection' },
        @{ Path = $AppPath; Old = $OldRunnerFunctionMarker; New = $NewRunnerFunctionMarker; Description = 'Guided lesson functions' },
        @{ Path = $AppPath; Old = $OldLessonsModeBlock; New = $NewLessonsModeBlock; Description = 'Lesson catalog entry behavior' },
        @{ Path = $AppPath; Old = $OldRunnerEvents; New = $NewRunnerEvents; Description = 'Lesson progression events' },
        @{ Path = $AppPath; Old = $OldLessonCapture; New = $NewLessonCapture; Description = 'Lesson runner element capture' },
        @{ Path = $ServiceWorkerPath; Old = $OldCacheName; New = $NewCacheName; Description = 'Phase 3C cache version' }
    )

    Write-Section -Text 'Phase 3C - Controlled Update Plan'

    foreach ($Update in $Updates) {
        Test-TextUpdatePlan `
            -Path $Update.Path `
            -OldText $Update.Old `
            -NewText $Update.New `
            -Description $Update.Description
    }

    $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

    if ($ExistingStyles.Contains('/* Phase 3C: guided lesson progression */')) {
        Write-Status -Level 'INFO' -Message 'Phase 3C lesson-runner styles are already present.'
    }
    elseif (-not $ExistingStyles.Contains('/* Phase 3B: read-only lesson catalog */')) {
        throw 'The Phase 3B lesson style marker was not found.'
    }
    else {
        Write-Status -Level 'PASS' -Message 'Lesson-runner styles are ready to append.'
    }

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 3C updates controlled application files. Run Build mode with -Force after confirming Phase 3B is committed.'
        }

        Write-Section -Text 'Phase 3C - Guided Lesson Progression Build'

        foreach ($Update in $Updates) {
            Invoke-TextUpdate `
                -Path $Update.Path `
                -OldText $Update.Old `
                -NewText $Update.New `
                -Description $Update.Description
        }

        $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

        if ($ExistingStyles.Contains('/* Phase 3C: guided lesson progression */')) {
            $Script:ExistingUpdates++
            Write-Status -Level 'INFO' -Message 'Lesson-runner styles already present.'
        }
        else {
            Write-Utf8File `
                -Path $StylesPath `
                -Content ($ExistingStyles.TrimEnd([char[]]@("`r", "`n")) + $Phase3CStyles)
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 3C - Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="start-lesson"'; Description = 'Start lesson control' },
        @{ Path = $IndexPath; Marker = 'id="lesson-runner"'; Description = 'Lesson runner region' },
        @{ Path = $IndexPath; Marker = 'id="lesson-progress"'; Description = 'Lesson progress indicator' },
        @{ Path = $IndexPath; Marker = 'id="lesson-previous"'; Description = 'Previous step control' },
        @{ Path = $IndexPath; Marker = 'id="lesson-next"'; Description = 'Next step control' },
        @{ Path = $StylesPath; Marker = '/* Phase 3C: guided lesson progression */'; Description = 'Phase 3C lesson styles' },
        @{ Path = $AppPath; Marker = 'function startLesson(id)'; Description = 'Start lesson behavior' },
        @{ Path = $AppPath; Marker = 'function showLessonStep()'; Description = 'Lesson step renderer' },
        @{ Path = $AppPath; Marker = 'function moveLessonStep(direction)'; Description = 'Previous and next behavior' },
        @{ Path = $AppPath; Marker = 'function completeLessonSession()'; Description = 'Session completion behavior' },
        @{ Path = $AppPath; Marker = "window.IconGuideIcons.render(icon.icon"; Description = 'Existing icon rendering reused' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check preserved' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior preserved' },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.3.1"; Description = 'Phase 3C cache version' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/lessons.json'"; Description = 'Offline lesson data preserved' },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(asset, { cache: 'reload' })"; Description = 'Fresh install caching preserved' },
        @{ Path = $ServiceWorkerPath; Marker = 'fetch(event.request)'; Description = 'Network-first loading preserved' }
    )

    foreach ($Rule in $ValidationRules) {
        Test-Marker `
            -Path $Rule.Path `
            -Marker $Rule.Marker `
            -Description $Rule.Description
    }

    Test-NoPersistentLessonTracking -AppPath $AppPath

    Write-Section -Text 'Phase 3C Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $LessonMetrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $LessonMetrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $LessonMetrics.StepCount
    Write-Metric -Name 'Updated file operations' -Value $Script:UpdatedFileOperations
    Write-Metric -Name 'Existing updates' -Value $Script:ExistingUpdates
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Persistent lesson tracking' -Value 'Disabled'

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 3C COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 3C ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
