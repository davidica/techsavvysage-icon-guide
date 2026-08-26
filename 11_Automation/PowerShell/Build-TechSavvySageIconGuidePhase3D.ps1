# ============================================================================
# Build-TechSavvySageIconGuidePhase3D.ps1
# Phase 3D - Persistent Lesson Progress and Resume
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 3D Builder'
$Script:UtilityVersion = '0.3.2'
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
        throw "The expected Phase 3D marker was not found for '$Description' in: $Path"
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
        throw "Required Phase 3D file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 3D marker is missing: $Description"
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

function Test-LessonStorageScope {
    param ([Parameter(Mandatory)][string]$AppPath)

    $Content = Get-Content -LiteralPath $AppPath -Raw

    foreach ($RequiredMarker in @(
        'lessons: state.lessonProgress',
        'localStorage.setItem(STORAGE_KEY',
        'function resetLessonProgress()',
        'state.lessonProgress = {}'
    )) {
        if (-not $Content.Contains($RequiredMarker)) {
            throw "Required browser-only lesson storage marker is missing: $RequiredMarker"
        }
    }

    foreach ($ForbiddenMarker in @(
        'fetch("http',
        "fetch('http",
        'XMLHttpRequest',
        'navigator.sendBeacon'
    )) {
        if ($Content.Contains($ForbiddenMarker)) {
            throw "Unexpected external lesson storage marker detected: $ForbiddenMarker"
        }
    }

    Write-Status -Level 'PASS' -Message 'Lesson progress remains in existing browser storage only.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 3D builder directory.'
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
    $Phase3CPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3C.ps1'

    Write-Section -Text 'Phase 3D - Preflight Validation'

    foreach ($RequiredPath in @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $IconDataPath,
        $LessonDataPath,
        $ServiceWorkerPath,
        $Phase3CPath
    )) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 3C baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    Test-Marker `
        -Path $AppPath `
        -Marker 'function startLesson(id)' `
        -Description 'Phase 3C lesson runner baseline'
    Test-Marker `
        -Path $AppPath `
        -Marker 'registration.update()' `
        -Description 'Deployment update behavior preserved'

    $ServiceWorkerBaseline = Get-Content -LiteralPath $ServiceWorkerPath -Raw

    if (
        -not $ServiceWorkerBaseline.Contains('techsavvysage-icon-guide-v0.3.1') -and
        -not $ServiceWorkerBaseline.Contains('techsavvysage-icon-guide-v0.3.2')
    ) {
        throw 'The expected Phase 3C or Phase 3D service-worker baseline was not found.'
    }

    Write-Status -Level 'PASS' -Message 'Deployment-hardened service-worker baseline is present.'

    $LessonMetrics = Test-LessonData `
        -IconDataPath $IconDataPath `
        -LessonDataPath $LessonDataPath

    $OldResetControl = @'
            <p id="lesson-catalog-intro">Preview a short lesson, then begin when you are ready. Progress in Phase 3C remains in the current session only.</p>
            <div id="lesson-grid" class="lesson-grid"></div>
'@
    $NewResetControl = @'
            <p id="lesson-catalog-intro">Preview a short lesson, then begin when you are ready. Lesson progress stays only in this browser.</p>
            <div class="lesson-catalog-tools">
                <button id="reset-lessons" class="text-button" type="button">Reset lesson progress</button>
            </div>
            <div id="lesson-grid" class="lesson-grid"></div>
'@

    $Phase3DStyles = @'

/* Phase 3D: persistent lesson progress */
.lesson-catalog-tools {
    display: flex;
    justify-content: flex-end;
    margin-top: 0.5rem;
}

.lesson-status {
    display: inline-flex;
    width: fit-content;
    border: 0.08rem solid var(--border);
    border-radius: 999px;
    padding: 0.25rem 0.55rem;
    background: var(--warm-gray);
    color: var(--muted-ink);
    font-size: 0.82rem;
    font-weight: 700;
}

.lesson-status.completed {
    border-color: var(--success);
    color: var(--success);
}

.lesson-card.completed {
    border-color: var(--success);
}

@media (max-width: 700px) {
    .lesson-catalog-tools {
        justify-content: flex-start;
    }
}
'@

    $OldPersistentState = @'
        lessonStepIndex: 0,
        lessonSessionComplete: false,
        filteredIcons: [],
'@
    $NewPersistentState = @'
        lessonStepIndex: 0,
        lessonSessionComplete: false,
        lessonProgress: {},
        reviewingCompletedLesson: false,
        filteredIcons: [],
'@

    $OldLoadProgress = @'
                state.review = new Set(uniqueIds(saved.review));
                state.settings.textSize = saved.settings && saved.settings.textSize
'@
    $NewLoadProgress = @'
                state.review = new Set(uniqueIds(saved.review));
                state.lessonProgress = saved.lessons && typeof saved.lessons === 'object' && !Array.isArray(saved.lessons)
                    ? saved.lessons
                    : {};
                state.settings.textSize = saved.settings && saved.settings.textSize
'@

    $OldSaveProgress = @'
                review: Array.from(state.review),
                settings: state.settings
'@
    $NewSaveProgress = @'
                review: Array.from(state.review),
                settings: state.settings,
                lessons: state.lessonProgress
'@

    $OldCardStatus = @'
            '<span class="lesson-card-summary">' + escapeHtml(lesson.summary) + '</span>' +
            '<span class="lesson-meta">' + lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps</span>';

        if (state.selectedLessonId === lesson.id) {
'@
    $NewCardStatus = @'
            '<span class="lesson-card-summary">' + escapeHtml(lesson.summary) + '</span>' +
            '<span class="lesson-meta">' + lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps</span>';

        const savedProgress = getLessonProgress(lesson.id);

        if (savedProgress) {
            const status = document.createElement('span');
            status.className = 'lesson-status';

            if (savedProgress.completed) {
                status.classList.add('completed');
                status.textContent = 'Completed';
                button.classList.add('completed');
            }
            else {
                status.textContent = 'In progress · Step ' + (savedProgress.stepIndex + 1);
            }

            button.appendChild(status);
        }

        if (state.selectedLessonId === lesson.id) {
'@

    $OldPreviewProgress = @'
        elements.startLesson.dataset.lessonId = lesson.id;
        elements.lessonPreview.hidden = false;
'@
    $NewPreviewProgress = @'
        elements.startLesson.dataset.lessonId = lesson.id;
        const savedProgress = getLessonProgress(lesson.id);

        if (savedProgress && savedProgress.completed) {
            elements.startLesson.textContent = 'Review lesson';
            elements.lessonPreviewMeta.textContent += ' · Completed';
        }
        else if (savedProgress) {
            elements.startLesson.textContent = 'Resume lesson';
            elements.lessonPreviewMeta.textContent += ' · Resume at step ' + (savedProgress.stepIndex + 1);
        }
        else {
            elements.startLesson.textContent = 'Start lesson';
        }

        elements.lessonPreview.hidden = false;
'@

    $OldProgressFunctionMarker = @'
    function currentLesson() {
'@
    $NewProgressFunctionMarker = @'
    function getLessonProgress(id) {
        return state.lessonProgress[id] || null;
    }

    function normalizeLessonProgress() {
        const normalized = {};

        state.lessons.forEach(function (lesson) {
            const saved = state.lessonProgress[lesson.id];

            if (!saved || typeof saved !== 'object') {
                return;
            }

            const numericStep = Number(saved.stepIndex);
            const stepIndex = Number.isInteger(numericStep)
                ? Math.max(0, Math.min(numericStep, lesson.steps.length - 1))
                : 0;
            normalized[lesson.id] = {
                stepIndex: stepIndex,
                completed: Boolean(saved.completed)
            };
        });

        state.lessonProgress = normalized;
    }

    function updateLessonProgress(id, stepIndex, completed) {
        state.lessonProgress[id] = {
            stepIndex: stepIndex,
            completed: Boolean(completed)
        };
        saveProgress();
    }

    function resetLessonProgress() {
        if (!window.confirm('Reset progress for all four guided lessons in this browser?')) {
            return;
        }

        state.lessonProgress = {};
        state.reviewingCompletedLesson = false;
        saveProgress();
        renderLessonCatalog();

        if (state.selectedLessonId) {
            showLessonPreview(findLesson(state.selectedLessonId));
        }

        setStatus('Lesson progress reset. Other learning data and display settings were kept.');
    }

    function currentLesson() {
'@

    $OldCatalogReviewState = @'
        state.activeLessonId = null;
        state.lessonSessionComplete = false;
        elements.lessonCatalogHeader.hidden = false;
'@
    $NewCatalogReviewState = @'
        state.activeLessonId = null;
        state.lessonSessionComplete = false;
        state.reviewingCompletedLesson = false;
        elements.lessonCatalogHeader.hidden = false;
'@

    $OldStepPersistence = @'
        state.lessonSessionComplete = false;
        elements.lessonStepIcon.hidden = false;
'@
    $NewStepPersistence = @'
        state.lessonSessionComplete = false;

        if (!state.reviewingCompletedLesson) {
            updateLessonProgress(lesson.id, state.lessonStepIndex, false);
        }

        elements.lessonStepIcon.hidden = false;
'@

    $OldStartResume = @'
        state.selectedLessonId = lesson.id;
        state.activeLessonId = lesson.id;
        state.lessonStepIndex = 0;
        state.lessonSessionComplete = false;
        elements.lessonCatalogHeader.hidden = true;
'@
    $NewStartResume = @'
        const savedProgress = getLessonProgress(lesson.id);
        state.selectedLessonId = lesson.id;
        state.activeLessonId = lesson.id;
        state.reviewingCompletedLesson = Boolean(savedProgress && savedProgress.completed);
        state.lessonStepIndex = savedProgress && !savedProgress.completed
            ? savedProgress.stepIndex
            : 0;
        state.lessonSessionComplete = false;
        elements.lessonCatalogHeader.hidden = true;
'@

    $OldCompletionPersistence = @'
        state.lessonSessionComplete = true;
        elements.lessonStepIcon.innerHTML = '';
'@
    $NewCompletionPersistence = @'
        state.lessonSessionComplete = true;
        state.reviewingCompletedLesson = false;
        updateLessonProgress(lesson.id, lesson.steps.length - 1, true);
        elements.lessonStepIcon.innerHTML = '';
'@

    $OldResetEvent = @'
        elements.startLesson.addEventListener('click', function () {
'@
    $NewResetEvent = @'
        elements.resetLessons.addEventListener('click', resetLessonProgress);
        elements.startLesson.addEventListener('click', function () {
'@

    $OldResetCapture = @'
            'lesson-catalog-intro', 'lesson-count', 'lesson-grid', 'lessons-empty',
'@
    $NewResetCapture = @'
            'lesson-catalog-intro', 'reset-lessons', 'lesson-count', 'lesson-grid', 'lessons-empty',
'@

    $OldNormalizeLoad = @'
            state.lessons = data[1].lessons;
            state.filteredIcons = data[0].icons.slice();
'@
    $NewNormalizeLoad = @'
            state.lessons = data[1].lessons;
            normalizeLessonProgress();
            state.filteredIcons = data[0].icons.slice();
'@

    $OldCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.3.1';"
    $NewCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.3.2';"

    $Updates = @(
        @{ Path = $IndexPath; Old = $OldResetControl; New = $NewResetControl; Description = 'Controlled lesson-progress reset' },
        @{ Path = $AppPath; Old = $OldPersistentState; New = $NewPersistentState; Description = 'Persistent lesson state' },
        @{ Path = $AppPath; Old = $OldLoadProgress; New = $NewLoadProgress; Description = 'Lesson progress loading' },
        @{ Path = $AppPath; Old = $OldSaveProgress; New = $NewSaveProgress; Description = 'Lesson progress saving' },
        @{ Path = $AppPath; Old = $OldCardStatus; New = $NewCardStatus; Description = 'Lesson completion indicators' },
        @{ Path = $AppPath; Old = $OldPreviewProgress; New = $NewPreviewProgress; Description = 'Start and resume labels' },
        @{ Path = $AppPath; Old = $OldProgressFunctionMarker; New = $NewProgressFunctionMarker; Description = 'Lesson storage and reset functions' },
        @{ Path = $AppPath; Old = $OldCatalogReviewState; New = $NewCatalogReviewState; Description = 'Completed lesson review state' },
        @{ Path = $AppPath; Old = $OldStepPersistence; New = $NewStepPersistence; Description = 'Last-step persistence' },
        @{ Path = $AppPath; Old = $OldStartResume; New = $NewStartResume; Description = 'Resume behavior' },
        @{ Path = $AppPath; Old = $OldCompletionPersistence; New = $NewCompletionPersistence; Description = 'Completion persistence' },
        @{ Path = $AppPath; Old = $OldResetEvent; New = $NewResetEvent; Description = 'Reset event binding' },
        @{ Path = $AppPath; Old = $OldResetCapture; New = $NewResetCapture; Description = 'Reset element capture' },
        @{ Path = $AppPath; Old = $OldNormalizeLoad; New = $NewNormalizeLoad; Description = 'Stored progress normalization' },
        @{ Path = $ServiceWorkerPath; Old = $OldCacheName; New = $NewCacheName; Description = 'Phase 3D cache version' }
    )

    Write-Section -Text 'Phase 3D - Controlled Update Plan'

    foreach ($Update in $Updates) {
        Test-TextUpdatePlan `
            -Path $Update.Path `
            -OldText $Update.Old `
            -NewText $Update.New `
            -Description $Update.Description
    }

    $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

    if ($ExistingStyles.Contains('/* Phase 3D: persistent lesson progress */')) {
        Write-Status -Level 'INFO' -Message 'Phase 3D lesson-progress styles are already present.'
    }
    elseif (-not $ExistingStyles.Contains('/* Phase 3C: guided lesson progression */')) {
        throw 'The Phase 3C lesson style marker was not found.'
    }
    else {
        Write-Status -Level 'PASS' -Message 'Lesson-progress styles are ready to append.'
    }

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 3D updates controlled application files. Run Build mode with -Force after confirming Phase 3C is committed.'
        }

        Write-Section -Text 'Phase 3D - Persistent Lesson Progress Build'

        foreach ($Update in $Updates) {
            Invoke-TextUpdate `
                -Path $Update.Path `
                -OldText $Update.Old `
                -NewText $Update.New `
                -Description $Update.Description
        }

        $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

        if ($ExistingStyles.Contains('/* Phase 3D: persistent lesson progress */')) {
            $Script:ExistingUpdates++
            Write-Status -Level 'INFO' -Message 'Lesson-progress styles already present.'
        }
        else {
            Write-Utf8File `
                -Path $StylesPath `
                -Content ($ExistingStyles.TrimEnd([char[]]@("`r", "`n")) + $Phase3DStyles)
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 3D - Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="reset-lessons"'; Description = 'Controlled lesson reset' },
        @{ Path = $IndexPath; Marker = 'Lesson progress stays only in this browser.'; Description = 'Browser-only privacy notice' },
        @{ Path = $StylesPath; Marker = '/* Phase 3D: persistent lesson progress */'; Description = 'Phase 3D progress styles' },
        @{ Path = $AppPath; Marker = 'lessonProgress: {}'; Description = 'Lesson progress state' },
        @{ Path = $AppPath; Marker = 'lessons: state.lessonProgress'; Description = 'Lesson progress saved with existing data' },
        @{ Path = $AppPath; Marker = 'function normalizeLessonProgress()'; Description = 'Stored progress normalization' },
        @{ Path = $AppPath; Marker = 'function updateLessonProgress(id, stepIndex, completed)'; Description = 'Last-step and completion persistence' },
        @{ Path = $AppPath; Marker = 'function resetLessonProgress()'; Description = 'Controlled reset behavior' },
        @{ Path = $AppPath; Marker = "elements.startLesson.textContent = 'Resume lesson'"; Description = 'Resume lesson label' },
        @{ Path = $AppPath; Marker = "status.textContent = 'Completed'"; Description = 'Completed lesson indicator' },
        @{ Path = $AppPath; Marker = "window.confirm('Reset progress for all four guided lessons in this browser?')"; Description = 'Reset confirmation' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check preserved' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior preserved' },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.3.2"; Description = 'Phase 3D cache version' },
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

    Test-LessonStorageScope -AppPath $AppPath

    Write-Section -Text 'Phase 3D Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $LessonMetrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $LessonMetrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $LessonMetrics.StepCount
    Write-Metric -Name 'Updated file operations' -Value $Script:UpdatedFileOperations
    Write-Metric -Name 'Existing updates' -Value $Script:ExistingUpdates
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Lesson progress storage' -Value 'Browser only'

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 3D COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 3D ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
