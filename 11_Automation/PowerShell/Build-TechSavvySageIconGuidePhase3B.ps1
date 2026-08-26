# ============================================================================
# Build-TechSavvySageIconGuidePhase3B.ps1
# Phase 3B - Read-Only Lesson Catalog UI
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 3B Builder'
$Script:UtilityVersion = '0.3.0'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:UpdatedFiles = 0
$Script:UnchangedFiles = 0
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
    $Script:UpdatedFiles++
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
        throw "The expected Phase 3B marker was not found for '$Description' in: $Path"
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
        $Script:UnchangedFiles++
        Write-Status -Level 'INFO' -Message "Update already present: $Description"
        return
    }

    if (-not $Content.Contains($OldText)) {
        throw "The expected Phase 3B marker disappeared before '$Description' could be applied."
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
        throw "Required Phase 3B file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 3B marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-LessonReferences {
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

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 3B builder directory.'
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
    $Phase3APath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase3Data.ps1'

    Write-Section -Text 'Phase 3B - Preflight Validation'

    foreach ($RequiredPath in @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $IconDataPath,
        $LessonDataPath,
        $ServiceWorkerPath,
        $Phase3APath
    )) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 3A baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    Test-Marker `
        -Path $AppPath `
        -Marker 'registration.update()' `
        -Description 'Deployment-hardened service-worker registration'

    $ServiceWorkerBaseline = Get-Content -LiteralPath $ServiceWorkerPath -Raw

    if (
        -not $ServiceWorkerBaseline.Contains('techsavvysage-icon-guide-v0.2.1') -and
        -not $ServiceWorkerBaseline.Contains('techsavvysage-icon-guide-v0.3.0')
    ) {
        throw 'The expected deployment-hardened service-worker baseline was not found.'
    }

    Write-Status `
        -Level 'PASS' `
        -Message 'Deployment-hardened service-worker baseline is present.'

    $LessonMetrics = Test-LessonReferences `
        -IconDataPath $IconDataPath `
        -LessonDataPath $LessonDataPath

    $OldModeNavigation = @'
            <button id="learn-mode" class="mode-button active" type="button" aria-pressed="true">Learn</button>
            <button id="practice-mode" class="mode-button" type="button" aria-pressed="false">Practice</button>
            <button id="review-mode" class="mode-button" type="button" aria-pressed="false">Saved for review</button>
'@
    $NewModeNavigation = @'
            <button id="learn-mode" class="mode-button active" type="button" aria-pressed="true">Learn</button>
            <button id="lessons-mode" class="mode-button" type="button" aria-pressed="false">Lessons</button>
            <button id="practice-mode" class="mode-button" type="button" aria-pressed="false">Practice</button>
            <button id="review-mode" class="mode-button" type="button" aria-pressed="false">Saved for review</button>
'@

    $OldLessonPanelMarker = @'
        <section id="learn-detail" class="detail-panel" aria-labelledby="detail-name">
'@
    $NewLessonPanelMarker = @'
        <section id="lessons-panel" class="lessons-panel" aria-labelledby="lessons-heading" hidden>
            <div class="section-heading-row">
                <div>
                    <p class="detail-category">Guided learning</p>
                    <h2 id="lessons-heading">Choose a lesson</h2>
                </div>
                <span id="lesson-count">4 lessons</span>
            </div>
            <p>Preview a short lesson before beginning. Lesson progress will be added in the next Phase 3 increment.</p>
            <div id="lesson-grid" class="lesson-grid"></div>
            <p id="lessons-empty" class="empty-state" hidden>No lessons are available.</p>
            <section id="lesson-preview" class="lesson-preview" aria-labelledby="lesson-preview-title" hidden>
                <p id="lesson-preview-number" class="detail-category"></p>
                <h3 id="lesson-preview-title"></h3>
                <p id="lesson-preview-summary"></p>
                <p id="lesson-preview-meta" class="lesson-meta"></p>
                <p class="detail-secondary">This preview is read-only. Guided step controls will be added in the next increment.</p>
            </section>
        </section>

        <section id="learn-detail" class="detail-panel" aria-labelledby="detail-name">
'@

    $Phase3BStyles = @'

/* Phase 3B: read-only lesson catalog */
.lessons-panel {
    margin: 1rem 0 1.5rem;
}

.lesson-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(15rem, 1fr));
    gap: 1rem;
    margin-top: 1rem;
}

.lesson-card {
    display: grid;
    align-content: start;
    gap: 0.55rem;
    min-height: 12rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.7rem;
    padding: 1rem;
    background: var(--surface);
    color: var(--ink);
    text-align: left;
}

.lesson-card:hover,
.lesson-card:focus-visible,
.lesson-card.selected {
    border-color: var(--sage-dark);
    background: var(--sage-soft);
}

.lesson-card-title {
    font-size: 1.15rem;
    font-weight: 700;
}

.lesson-card-summary {
    color: var(--muted-ink);
    font-weight: 400;
}

.lesson-meta {
    color: var(--muted-ink);
    font-weight: 700;
}

.lesson-preview {
    margin-top: 1.25rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.7rem;
    padding: 1.1rem;
    background: var(--surface);
}

@media (max-width: 700px) {
    .lesson-grid {
        grid-template-columns: 1fr;
    }
}
'@

    $OldStateMarker = @'
        icons: [],
        filteredIcons: [],
'@
    $NewStateMarker = @'
        icons: [],
        lessons: [],
        selectedLessonId: null,
        filteredIcons: [],
'@

    $OldLessonFunctionMarker = @'
    function showIconDetail(icon) {
'@
    $NewLessonFunctionMarker = @'
    function findLesson(id) {
        return state.lessons.find(function (lesson) {
            return lesson.id === id;
        });
    }

    function createLessonCard(lesson) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'lesson-card';
        button.dataset.lessonId = lesson.id;
        button.setAttribute('aria-label', 'Lesson ' + lesson.order + '. ' + lesson.title + '. ' + lesson.estimated_minutes + ' minutes.');
        button.innerHTML =
            '<span class="detail-category">Lesson ' + lesson.order + '</span>' +
            '<span class="lesson-card-title">' + escapeHtml(lesson.title) + '</span>' +
            '<span class="lesson-card-summary">' + escapeHtml(lesson.summary) + '</span>' +
            '<span class="lesson-meta">' + lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps</span>';

        if (state.selectedLessonId === lesson.id) {
            button.classList.add('selected');
            button.setAttribute('aria-current', 'true');
        }

        return button;
    }

    function renderLessonCatalog() {
        elements.lessonGrid.innerHTML = '';

        state.lessons.forEach(function (lesson) {
            elements.lessonGrid.appendChild(createLessonCard(lesson));
        });

        elements.lessonCount.textContent = state.lessons.length + ' lessons';
        elements.lessonsEmpty.hidden = state.lessons.length !== 0;
    }

    function showLessonPreview(lesson) {
        if (!lesson) {
            elements.lessonPreview.hidden = true;
            return;
        }

        state.selectedLessonId = lesson.id;
        renderLessonCatalog();
        elements.lessonPreviewNumber.textContent = 'Lesson ' + lesson.order;
        elements.lessonPreviewTitle.textContent = lesson.title;
        elements.lessonPreviewSummary.textContent = lesson.summary;
        elements.lessonPreviewMeta.textContent = lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps';
        elements.lessonPreview.hidden = false;
        setStatus(lesson.title + ' lesson preview selected.');
    }

    function showIconDetail(icon) {
'@

    $OldModeList = "        ['learn', 'practice', 'review'].forEach(function (mode) {"
    $NewModeList = "        ['learn', 'lessons', 'practice', 'review'].forEach(function (mode) {"

    $OldSetModeMarker = @'
        elements.practiceDetail.hidden = mode !== 'practice';

        if (mode === 'practice') {
'@
    $NewSetModeMarker = @'
        elements.practiceDetail.hidden = mode !== 'practice';
        elements.lessonsPanel.hidden = mode !== 'lessons';

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

        if (mode === 'practice') {
'@

    $OldLessonModeEvent = @'
        elements.reviewMode.addEventListener('click', function () { setMode('review'); });
'@
    $NewLessonModeEvent = @'
        elements.reviewMode.addEventListener('click', function () { setMode('review'); });
        elements.lessonsMode.addEventListener('click', function () { setMode('lessons'); });
'@

    $OldLessonGridEvent = @'
        elements.iconGrid.addEventListener('click', function (event) {
'@
    $NewLessonGridEvent = @'
        elements.lessonGrid.addEventListener('click', function (event) {
            const button = event.target.closest('[data-lesson-id]');

            if (!button) {
                return;
            }

            showLessonPreview(findLesson(button.dataset.lessonId));
        });
        elements.iconGrid.addEventListener('click', function (event) {
'@

    $OldCaptureModeIds = @'
            'learn-mode', 'practice-mode', 'review-mode', 'text-size', 'high-contrast',
'@
    $NewCaptureModeIds = @'
            'learn-mode', 'lessons-mode', 'practice-mode', 'review-mode', 'text-size', 'high-contrast',
'@

    $OldCaptureLessonIds = @'
            'result-status', 'learn-detail', 'detail-icon', 'detail-category',
'@
    $NewCaptureLessonIds = @'
            'result-status', 'lessons-panel', 'lesson-count', 'lesson-grid',
            'lessons-empty', 'lesson-preview', 'lesson-preview-number',
            'lesson-preview-title', 'lesson-preview-summary', 'lesson-preview-meta',
            'learn-detail', 'detail-icon', 'detail-category',
'@

    $OldDataLoad = @'
            const response = await fetch('04_Application/data/icons.json', { cache: 'no-store' });

            if (!response.ok) {
                throw new Error('Icon data could not be loaded.');
            }

            const data = await response.json();
            state.icons = data.icons;
            state.filteredIcons = data.icons.slice();
            buildCategoryOptions();
'@
    $NewDataLoad = @'
            const responses = await Promise.all([
                fetch('04_Application/data/icons.json', { cache: 'no-store' }),
                fetch('04_Application/data/lessons.json', { cache: 'no-store' })
            ]);

            if (!responses[0].ok || !responses[1].ok) {
                throw new Error('Icon or lesson data could not be loaded.');
            }

            const data = await Promise.all(responses.map(function (response) {
                return response.json();
            }));
            state.icons = data[0].icons;
            state.lessons = data[1].lessons;
            state.filteredIcons = data[0].icons.slice();
            buildCategoryOptions();
            renderLessonCatalog();
'@

    $OldServiceWorkerCache = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.2.1';"
    $NewServiceWorkerCache = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.3.0';"
    $OldServiceWorkerData = "    './04_Application/data/icons.json',"
    $NewServiceWorkerData = @'
    './04_Application/data/icons.json',
    './04_Application/data/lessons.json',
'@

    $Updates = @(
        @{ Path = $IndexPath; Old = $OldModeNavigation; New = $NewModeNavigation; Description = 'Lessons mode navigation' },
        @{ Path = $IndexPath; Old = $OldLessonPanelMarker; New = $NewLessonPanelMarker; Description = 'Read-only lesson catalog panel' },
        @{ Path = $AppPath; Old = $OldStateMarker; New = $NewStateMarker; Description = 'Lesson application state' },
        @{ Path = $AppPath; Old = $OldLessonFunctionMarker; New = $NewLessonFunctionMarker; Description = 'Lesson catalog rendering functions' },
        @{ Path = $AppPath; Old = $OldModeList; New = $NewModeList; Description = 'Lessons mode button state' },
        @{ Path = $AppPath; Old = $OldSetModeMarker; New = $NewSetModeMarker; Description = 'Lessons mode display behavior' },
        @{ Path = $AppPath; Old = $OldLessonModeEvent; New = $NewLessonModeEvent; Description = 'Lessons navigation event' },
        @{ Path = $AppPath; Old = $OldLessonGridEvent; New = $NewLessonGridEvent; Description = 'Lesson selection event' },
        @{ Path = $AppPath; Old = $OldCaptureModeIds; New = $NewCaptureModeIds; Description = 'Lessons mode element capture' },
        @{ Path = $AppPath; Old = $OldCaptureLessonIds; New = $NewCaptureLessonIds; Description = 'Lesson panel element capture' },
        @{ Path = $AppPath; Old = $OldDataLoad; New = $NewDataLoad; Description = 'Icon and lesson data loading' },
        @{ Path = $ServiceWorkerPath; Old = $OldServiceWorkerCache; New = $NewServiceWorkerCache; Description = 'Phase 3 cache version' },
        @{ Path = $ServiceWorkerPath; Old = $OldServiceWorkerData; New = $NewServiceWorkerData; Description = 'Offline lesson data asset' }
    )

    Write-Section -Text 'Phase 3B - Controlled Update Plan'

    foreach ($Update in $Updates) {
        Test-TextUpdatePlan `
            -Path $Update.Path `
            -OldText $Update.Old `
            -NewText $Update.New `
            -Description $Update.Description
    }

    $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

    if ($ExistingStyles.Contains('/* Phase 3B: read-only lesson catalog */')) {
        Write-Status -Level 'INFO' -Message 'Phase 3B lesson styles are already present.'
    }
    elseif (-not $ExistingStyles.Contains('/* Phase 2: guided practice and personalization */')) {
        throw 'The Phase 2 style baseline marker was not found.'
    }
    else {
        Write-Status -Level 'PASS' -Message 'Lesson styles are ready to append.'
    }

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 3B updates controlled application files. Run Build mode with -Force after confirming Phase 3A is committed.'
        }

        Write-Section -Text 'Phase 3B - Read-Only Lesson Catalog Build'

        foreach ($Update in $Updates) {
            Invoke-TextUpdate `
                -Path $Update.Path `
                -OldText $Update.Old `
                -NewText $Update.New `
                -Description $Update.Description
        }

        $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

        if ($ExistingStyles.Contains('/* Phase 3B: read-only lesson catalog */')) {
            $Script:UnchangedFiles++
            Write-Status -Level 'INFO' -Message 'Lesson styles already present.'
        }
        else {
            Write-Utf8File `
                -Path $StylesPath `
                -Content ($ExistingStyles.TrimEnd([char[]]@("`r", "`n")) + $Phase3BStyles)
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 3B - Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="lessons-mode"'; Description = 'Lessons navigation button' },
        @{ Path = $IndexPath; Marker = 'id="lessons-panel"'; Description = 'Lessons panel' },
        @{ Path = $IndexPath; Marker = 'id="lesson-grid"'; Description = 'Lesson catalog grid' },
        @{ Path = $IndexPath; Marker = 'id="lesson-preview"'; Description = 'Read-only lesson preview' },
        @{ Path = $StylesPath; Marker = '/* Phase 3B: read-only lesson catalog */'; Description = 'Phase 3B lesson styles' },
        @{ Path = $AppPath; Marker = 'function renderLessonCatalog()'; Description = 'Lesson catalog renderer' },
        @{ Path = $AppPath; Marker = 'function showLessonPreview(lesson)'; Description = 'Lesson preview behavior' },
        @{ Path = $AppPath; Marker = "setMode('lessons')"; Description = 'Lessons mode event binding' },
        @{ Path = $AppPath; Marker = "fetch('04_Application/data/lessons.json'"; Description = 'Lesson data loading' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check preserved' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior preserved' },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.3.0"; Description = 'Phase 3 cache version' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/lessons.json'"; Description = 'Offline lesson data' },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(asset, { cache: 'reload' })"; Description = 'Fresh install caching preserved' },
        @{ Path = $ServiceWorkerPath; Marker = 'fetch(event.request)'; Description = 'Network-first loading preserved' }
    )

    foreach ($Rule in $ValidationRules) {
        Test-Marker `
            -Path $Rule.Path `
            -Marker $Rule.Marker `
            -Description $Rule.Description
    }

    Write-Section -Text 'Phase 3B Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $LessonMetrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $LessonMetrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $LessonMetrics.StepCount
    Write-Metric -Name 'Updated file operations' -Value $Script:UpdatedFiles
    Write-Metric -Name 'Existing updates' -Value $Script:UnchangedFiles
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 3B COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 3B ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
