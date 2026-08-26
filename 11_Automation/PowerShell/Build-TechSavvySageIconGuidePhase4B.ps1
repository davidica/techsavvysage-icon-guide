# ============================================================================
# Build-TechSavvySageIconGuidePhase4B.ps1
# Phase 4B - Lesson Knowledge Check UI
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 4B Knowledge Check Builder'
$Script:UtilityVersion = '0.4.0'
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
        throw "The expected Phase 4B marker was not found for '$Description' in: $Path"
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
        throw "Required Phase 4B file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 4B marker is missing: $Description"
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

    Write-Status -Level 'VALIDATE' -Message ("{0} :: {1}" -f $Path, $Description)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required Phase 4B file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw
    $Matched = $false

    foreach ($Marker in $Markers) {
        if ($Content.Contains($Marker)) {
            $Matched = $true
            break
        }
    }

    if (-not $Matched) {
        throw "Required Phase 4B marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-AssessmentData {
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
    $Assessments = @($AssessmentData.assessments)
    $IconIds = @($Icons | ForEach-Object { [string]$_.id })
    $LessonIds = @($Lessons | ForEach-Object { [string]$_.id })
    $Steps = @($Lessons | ForEach-Object { @($_.steps) })
    $Questions = @($Assessments | ForEach-Object { @($_.questions) })
    $CorrectIconIds = @($Questions | ForEach-Object { [string]$_.correct_answer_icon_id })
    $InvalidReferences = @()
    $CrossLessonDistractors = @()

    if ($Icons.Count -ne 40 -or @($IconIds | Sort-Object -Unique).Count -ne 40) {
        throw 'The icon library must contain exactly 40 unique records.'
    }

    if ($Lessons.Count -ne 4 -or $Steps.Count -ne 40) {
        throw 'The lesson library must contain four lessons and 40 total steps.'
    }

    if ($Assessments.Count -ne 4 -or $Questions.Count -ne 40) {
        throw 'The assessment library must contain four assessments and 40 question-bank records.'
    }

    $AssessmentLessonIds = @($Assessments | ForEach-Object { [string]$_.lesson_id })

    if (@($LessonIds | Where-Object { $AssessmentLessonIds -cnotcontains $_ }).Count -gt 0 -or
        @($AssessmentLessonIds | Where-Object { $LessonIds -cnotcontains $_ }).Count -gt 0) {
        throw 'Assessment and lesson records must have a complete one-to-one relationship.'
    }

    foreach ($Assessment in $Assessments) {
        $LessonId = [string]$Assessment.lesson_id
        $Lesson = @($Lessons | Where-Object { [string]$_.id -ceq $LessonId })[0]
        $LessonIconIds = @($Lesson.steps | ForEach-Object { [string]$_.icon_id })
        $AssessmentQuestions = @($Assessment.questions)

        if ([int]$Assessment.questions_per_attempt -ne 5) {
            throw "Assessment '$($Assessment.id)' must present five questions per attempt."
        }

        if ($AssessmentQuestions.Count -ne $LessonIconIds.Count) {
            throw "Assessment '$($Assessment.id)' must contain one question for every lesson icon."
        }

        foreach ($Question in $AssessmentQuestions) {
            $QuestionIconId = [string]$Question.icon_id
            $CorrectIconId = [string]$Question.correct_answer_icon_id
            $DistractorIds = @($Question.distractor_icon_ids | ForEach-Object { [string]$_ })
            $References = @($QuestionIconId, $CorrectIconId) + $DistractorIds

            if ([string]$Question.type -cne 'icon-to-meaning' -or
                $QuestionIconId -cne $CorrectIconId) {
                throw "Question '$($Question.id)' has an invalid knowledge-check definition."
            }

            if ($DistractorIds.Count -ne 3 -or
                @($DistractorIds | Sort-Object -Unique).Count -ne 3 -or
                $DistractorIds -ccontains $CorrectIconId) {
                throw "Question '$($Question.id)' must contain three unique distractors."
            }

            $InvalidReferences += @($References | Where-Object { $IconIds -cnotcontains $_ })
            $CrossLessonDistractors += @($DistractorIds | Where-Object { $LessonIconIds -cnotcontains $_ })
        }
    }

    if ($InvalidReferences.Count -gt 0) {
        throw 'One or more knowledge-check questions reference an unknown icon.'
    }

    if ($CrossLessonDistractors.Count -gt 0) {
        throw 'One or more knowledge-check distractors are outside their lesson.'
    }

    if (@($CorrectIconIds | Sort-Object -Unique).Count -ne 40) {
        throw 'All 40 icons must appear as unique correct answers.'
    }

    Write-Status -Level 'PASS' -Message 'Four assessments and 40 validated questions are ready for the knowledge-check UI.'

    return [pscustomobject]@{
        IconCount = $Icons.Count
        LessonCount = $Lessons.Count
        StepCount = $Steps.Count
        AssessmentCount = $Assessments.Count
        QuestionCount = $Questions.Count
        QuestionsPerAttempt = 5
        AnswerOptionsPerQuestion = 4
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
        throw 'Unable to isolate the Phase 4B knowledge-check functions.'
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
            throw "Phase 4B knowledge-check functions contain a forbidden marker: $ForbiddenMarker"
        }
    }

    Write-Status -Level 'PASS' -Message 'Knowledge-check results remain session-only and CSP-safe.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 4B builder directory.'
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
    $AssessmentDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\assessments.json'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $Phase4APath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4A.ps1'

    Write-Section -Text 'Phase 4B - Preflight Validation'

    foreach ($RequiredPath in @(
        $IndexPath,
        $StylesPath,
        $AppPath,
        $IconDataPath,
        $LessonDataPath,
        $AssessmentDataPath,
        $ServiceWorkerPath,
        $Phase4APath
    )) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The committed Phase 4A baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    Test-Marker `
        -Path $AppPath `
        -Marker 'function resetLessonProgress()' `
        -Description 'Phase 3D persistent lesson baseline'
    Test-AnyMarker `
        -Path $ServiceWorkerPath `
        -Markers @(
            "techsavvysage-icon-guide-v0.3.2",
            "techsavvysage-icon-guide-v0.4.0"
        ) `
        -Description 'Supported release cache baseline'

    $DataMetrics = Test-AssessmentData `
        -IconDataPath $IconDataPath `
        -LessonDataPath $LessonDataPath `
        -AssessmentDataPath $AssessmentDataPath

    $OldLessonRunner = @'
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
    $NewLessonRunner = @'
            <section id="lesson-runner" class="lesson-runner" aria-labelledby="lesson-step-heading" hidden>
                <button id="exit-lesson" class="text-button" type="button">Back to lesson choices</button>
                <div id="lesson-progress-row" class="lesson-progress-row">
                    <span id="lesson-progress-text">Step 1 of 1</span>
                    <progress id="lesson-progress" value="1" max="1">Step 1 of 1</progress>
                </div>
                <div id="lesson-step-card" class="lesson-step-card">
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
                            <button id="start-assessment" class="primary-button" type="button" hidden>Start knowledge check</button>
                            <button id="lesson-next" class="primary-button" type="button">Next step</button>
                        </div>
                    </div>
                </div>

                <section id="assessment-runner" class="assessment-runner" aria-labelledby="assessment-heading" hidden>
                    <button id="exit-assessment" class="text-button" type="button">Back to lesson choices</button>
                    <div class="assessment-progress-row">
                        <span id="assessment-progress-text">Question 1 of 5</span>
                        <progress id="assessment-progress" value="1" max="5">Question 1 of 5</progress>
                    </div>
                    <div class="assessment-card">
                        <div id="assessment-icon" class="large-icon assessment-icon" aria-hidden="true"></div>
                        <div class="assessment-copy">
                            <p id="assessment-label" class="detail-category">Knowledge check</p>
                            <h3 id="assessment-heading" tabindex="-1">Knowledge check</h3>
                            <p id="assessment-question"></p>
                            <div id="assessment-options" class="assessment-options" role="group" aria-labelledby="assessment-question"></div>
                            <p id="assessment-feedback" class="assessment-feedback" role="status" aria-live="polite" hidden></p>
                            <div class="assessment-navigation">
                                <button id="assessment-next" class="primary-button" type="button" hidden>Next question</button>
                                <button id="assessment-retry" class="secondary-button" type="button" hidden>Try five more questions</button>
                                <button id="assessment-return" class="primary-button" type="button" hidden>Return to lesson choices</button>
                            </div>
                        </div>
                    </div>
                </section>
            </section>
'@

    $Phase4BStyles = @'

/* Phase 4B: lesson knowledge checks */
.assessment-runner {
    margin-top: 1rem;
}

.assessment-progress-row {
    display: grid;
    gap: 0.4rem;
    margin: 1rem 0;
    font-weight: 700;
}

.assessment-progress-row progress {
    width: 100%;
    min-height: 1rem;
}

.assessment-card {
    display: grid;
    grid-template-columns: minmax(7rem, 10rem) 1fr;
    gap: 1.25rem;
    align-items: start;
    border: 0.1rem solid var(--border);
    border-radius: 0.7rem;
    padding: 1.25rem;
    background: var(--surface);
}

.assessment-icon {
    margin: 0 auto;
}

.assessment-copy h3 {
    margin-top: 0.25rem;
    font-size: 1.35rem;
}

.assessment-options {
    display: grid;
    gap: 0.7rem;
    margin-top: 1rem;
}

.assessment-option {
    min-height: 3rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.55rem;
    padding: 0.75rem;
    background: var(--surface);
    color: var(--ink);
    text-align: left;
    font: inherit;
    font-weight: 700;
    cursor: pointer;
}

.assessment-option:hover,
.assessment-option:focus-visible {
    border-color: var(--sage-dark);
    background: var(--sage-soft);
}

.assessment-option.correct {
    border-color: var(--success);
    background: var(--sage-soft);
}

.assessment-option.incorrect {
    border-color: var(--sage-dark);
    background: var(--warm-gray);
}

.assessment-option:disabled {
    color: var(--ink);
    cursor: default;
    opacity: 1;
}

.assessment-feedback {
    margin-top: 1rem;
    border-left: 0.3rem solid var(--sage-dark);
    padding: 0.75rem;
    background: var(--warm-gray);
}

.assessment-feedback.correct {
    border-left-color: var(--success);
}

.assessment-navigation {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-top: 1rem;
}

@media (max-width: 700px) {
    .assessment-card {
        grid-template-columns: 1fr;
    }

    .assessment-navigation button {
        width: 100%;
    }
}
'@

    $OldAssessmentState = @'
        lessonProgress: {},
        reviewingCompletedLesson: false,
        filteredIcons: [],
'@
    $NewAssessmentState = @'
        lessonProgress: {},
        reviewingCompletedLesson: false,
        assessments: [],
        activeAssessment: null,
        assessmentQuestions: [],
        assessmentQuestionIndex: 0,
        assessmentScore: 0,
        assessmentAnswered: false,
        assessmentComplete: false,
        filteredIcons: [],
'@

    $OldCatalogReset = @'
        elements.lessonGrid.hidden = false;
        elements.lessonRunner.hidden = true;
        renderLessonCatalog();
'@
    $NewCatalogReset = @'
        elements.lessonGrid.hidden = false;
        elements.lessonRunner.hidden = true;
        elements.assessmentRunner.hidden = true;
        elements.lessonProgressRow.hidden = false;
        elements.lessonStepCard.hidden = false;
        elements.exitLesson.hidden = false;
        state.activeAssessment = null;
        state.assessmentQuestions = [];
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        renderLessonCatalog();
'@

    $OldStepAssessmentControl = @'
        elements.lessonPrevious.hidden = false;
        elements.lessonPrevious.disabled = state.lessonStepIndex === 0;
'@
    $NewStepAssessmentControl = @'
        elements.lessonPrevious.hidden = false;
        elements.lessonPrevious.disabled = state.lessonStepIndex === 0;
        elements.startAssessment.hidden = true;
'@

    $OldCompletionAssessmentControl = @'
        elements.lessonPrevious.hidden = true;
        elements.lessonNext.dataset.action = 'return';
'@
    $NewCompletionAssessmentControl = @'
        elements.lessonPrevious.hidden = true;
        elements.startAssessment.hidden = false;
        elements.lessonNext.dataset.action = 'return';
'@

    $OldAssessmentFunctions = @'
    function showIconDetail(icon) {
'@
    $NewAssessmentFunctions = @'
    function findAssessmentByLesson(lessonId) {
        return state.assessments.find(function (assessment) {
            return assessment.lesson_id === lessonId;
        });
    }

    function shuffledCopy(items) {
        const copy = items.slice();

        for (let index = copy.length - 1; index > 0; index -= 1) {
            const replacementIndex = Math.floor(Math.random() * (index + 1));
            const temporaryItem = copy[index];
            copy[index] = copy[replacementIndex];
            copy[replacementIndex] = temporaryItem;
        }

        return copy;
    }

    function startAssessment(lessonId) {
        const assessment = findAssessmentByLesson(lessonId);

        if (!assessment) {
            setStatus('The knowledge check for this lesson is unavailable.');
            return;
        }

        state.activeAssessment = assessment;
        state.assessmentQuestions = shuffledCopy(assessment.questions).slice(0, assessment.questions_per_attempt);
        state.assessmentQuestionIndex = 0;
        state.assessmentScore = 0;
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        elements.exitLesson.hidden = true;
        elements.lessonProgressRow.hidden = true;
        elements.lessonStepCard.hidden = true;
        elements.assessmentRunner.hidden = false;
        showAssessmentQuestion();
    }

    function showAssessmentQuestion() {
        const assessment = state.activeAssessment;
        const question = state.assessmentQuestions[state.assessmentQuestionIndex];

        if (!assessment || !question) {
            showLessonCatalog();
            return;
        }

        const icon = findIcon(question.icon_id);
        const optionIds = shuffledCopy([
            question.correct_answer_icon_id
        ].concat(question.distractor_icon_ids));
        const questionNumber = state.assessmentQuestionIndex + 1;
        const totalQuestions = state.assessmentQuestions.length;

        if (!icon) {
            setStatus('An icon needed for this knowledge check is unavailable.');
            showLessonCatalog();
            return;
        }

        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        elements.assessmentIcon.hidden = false;
        elements.assessmentIcon.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
        elements.assessmentLabel.textContent = 'Knowledge check · Question ' + questionNumber + ' of ' + totalQuestions;
        elements.assessmentHeading.textContent = assessment.title;
        elements.assessmentQuestion.textContent = question.prompt;
        elements.assessmentOptions.innerHTML = '';

        optionIds.forEach(function (iconId) {
            const answerIcon = findIcon(iconId);

            if (!answerIcon) {
                return;
            }

            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'assessment-option';
            button.dataset.answerIconId = answerIcon.id;
            button.textContent = answerIcon.meaning;
            elements.assessmentOptions.appendChild(button);
        });

        elements.assessmentFeedback.hidden = true;
        elements.assessmentFeedback.textContent = '';
        elements.assessmentFeedback.className = 'assessment-feedback';
        elements.assessmentProgress.max = totalQuestions;
        elements.assessmentProgress.value = questionNumber;
        elements.assessmentProgress.textContent = 'Question ' + questionNumber + ' of ' + totalQuestions;
        elements.assessmentProgressText.textContent = 'Question ' + questionNumber + ' of ' + totalQuestions;
        elements.assessmentNext.hidden = true;
        elements.assessmentRetry.hidden = true;
        elements.assessmentReturn.hidden = true;
        setStatus('Knowledge check question ' + questionNumber + ' of ' + totalQuestions + '. Choose one answer.');
        elements.assessmentHeading.focus();
    }

    function answerAssessment(answerIconId) {
        if (state.assessmentAnswered) {
            return;
        }

        const question = state.assessmentQuestions[state.assessmentQuestionIndex];
        const correctIcon = question ? findIcon(question.correct_answer_icon_id) : null;

        if (!question || !correctIcon) {
            setStatus('This knowledge-check question is unavailable.');
            return;
        }

        state.assessmentAnswered = true;
        const isCorrect = answerIconId === question.correct_answer_icon_id;
        const optionButtons = elements.assessmentOptions.querySelectorAll('[data-answer-icon-id]');

        optionButtons.forEach(function (button) {
            button.disabled = true;

            if (button.dataset.answerIconId === question.correct_answer_icon_id) {
                button.classList.add('correct');
            }
            else if (button.dataset.answerIconId === answerIconId) {
                button.classList.add('incorrect');
            }
        });

        if (isCorrect) {
            state.assessmentScore += 1;
            elements.assessmentFeedback.className = 'assessment-feedback correct';
            elements.assessmentFeedback.textContent = 'That is right. The ' + correctIcon.name + ' icon ' + correctIcon.meaning;
        }
        else {
            elements.assessmentFeedback.className = 'assessment-feedback';
            elements.assessmentFeedback.textContent = 'Good try. The ' + correctIcon.name + ' icon ' + correctIcon.meaning;
        }

        elements.assessmentFeedback.hidden = false;
        elements.assessmentNext.textContent = state.assessmentQuestionIndex === state.assessmentQuestions.length - 1
            ? 'See results'
            : 'Next question';
        elements.assessmentNext.hidden = false;
        setStatus(elements.assessmentFeedback.textContent);
        elements.assessmentNext.focus();
    }

    function completeAssessment() {
        const assessment = state.activeAssessment;
        const totalQuestions = state.assessmentQuestions.length;

        if (!assessment) {
            showLessonCatalog();
            return;
        }

        state.assessmentComplete = true;
        elements.assessmentIcon.innerHTML = '';
        elements.assessmentIcon.hidden = true;
        elements.assessmentLabel.textContent = 'Knowledge check complete';
        elements.assessmentHeading.textContent = assessment.title;
        elements.assessmentQuestion.textContent = 'You answered ' + state.assessmentScore + ' of ' + totalQuestions + ' correctly.';
        elements.assessmentOptions.innerHTML = '';
        elements.assessmentFeedback.className = 'assessment-feedback correct';
        elements.assessmentFeedback.textContent = state.assessmentScore === totalQuestions
            ? 'Excellent work. You can retry whenever you want more practice.'
            : 'Nice work. Retry when you are ready; there is no penalty.';
        elements.assessmentFeedback.hidden = false;
        elements.assessmentProgress.max = totalQuestions;
        elements.assessmentProgress.value = totalQuestions;
        elements.assessmentProgress.textContent = totalQuestions + ' of ' + totalQuestions + ' questions complete';
        elements.assessmentProgressText.textContent = totalQuestions + ' of ' + totalQuestions + ' questions complete';
        elements.assessmentNext.hidden = true;
        elements.assessmentRetry.hidden = false;
        elements.assessmentReturn.hidden = false;
        setStatus('Knowledge check complete. ' + state.assessmentScore + ' of ' + totalQuestions + ' correct.');
        elements.assessmentHeading.focus();
    }

    function showIconDetail(icon) {
'@

    $OldAssessmentEvents = @'
        elements.resetLessons.addEventListener('click', resetLessonProgress);
'@
    $NewAssessmentEvents = @'
        elements.startAssessment.addEventListener('click', function () {
            const lesson = currentLesson();

            if (lesson) {
                startAssessment(lesson.id);
            }
        });
        elements.exitAssessment.addEventListener('click', function () {
            showLessonCatalog();
            setStatus('Returned to the lesson choices.');
        });
        elements.assessmentOptions.addEventListener('click', function (event) {
            const button = event.target.closest('[data-answer-icon-id]');

            if (!button) {
                return;
            }

            answerAssessment(button.dataset.answerIconId);
        });
        elements.assessmentNext.addEventListener('click', function () {
            if (!state.assessmentAnswered) {
                return;
            }

            if (state.assessmentQuestionIndex === state.assessmentQuestions.length - 1) {
                completeAssessment();
                return;
            }

            state.assessmentQuestionIndex += 1;
            showAssessmentQuestion();
        });
        elements.assessmentRetry.addEventListener('click', function () {
            if (state.activeAssessment) {
                startAssessment(state.activeAssessment.lesson_id);
            }
        });
        elements.assessmentReturn.addEventListener('click', function () {
            showLessonCatalog();
            setStatus('Returned to the lesson choices.');
        });
        elements.resetLessons.addEventListener('click', resetLessonProgress);
'@

    $OldAssessmentCapture = @'
            'lesson-runner', 'exit-lesson', 'lesson-progress-text',
            'lesson-progress', 'lesson-step-icon', 'lesson-step-label',
            'lesson-step-heading', 'lesson-step-instruction', 'lesson-step-practice',
            'lesson-step-prompt', 'lesson-previous', 'lesson-next',
'@
    $NewAssessmentCapture = @'
            'lesson-runner', 'exit-lesson', 'lesson-progress-row', 'lesson-progress-text',
            'lesson-progress', 'lesson-step-card', 'lesson-step-icon', 'lesson-step-label',
            'lesson-step-heading', 'lesson-step-instruction', 'lesson-step-practice',
            'lesson-step-prompt', 'lesson-previous', 'start-assessment', 'lesson-next',
            'assessment-runner', 'exit-assessment', 'assessment-progress-text',
            'assessment-progress', 'assessment-icon', 'assessment-label',
            'assessment-heading', 'assessment-question', 'assessment-options',
            'assessment-feedback', 'assessment-next', 'assessment-retry',
            'assessment-return',
'@

    $OldAssessmentLoad = @'
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
            normalizeLessonProgress();
'@
    $NewAssessmentLoad = @'
            const responses = await Promise.all([
                fetch('04_Application/data/icons.json', { cache: 'no-store' }),
                fetch('04_Application/data/lessons.json', { cache: 'no-store' }),
                fetch('04_Application/data/assessments.json', { cache: 'no-store' })
            ]);

            if (!responses[0].ok || !responses[1].ok || !responses[2].ok) {
                throw new Error('Icon, lesson, or assessment data could not be loaded.');
            }

            const data = await Promise.all(responses.map(function (response) {
                return response.json();
            }));
            state.icons = data[0].icons;
            state.lessons = data[1].lessons;
            state.assessments = data[2].assessments;
            normalizeLessonProgress();
'@

    $OldCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.3.2';"
    $NewCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.4.0';"
    $OldOfflineAssessment = "    './04_Application/data/lessons.json',"
    $NewOfflineAssessment = @'
    './04_Application/data/lessons.json',
    './04_Application/data/assessments.json',
'@

    $Updates = @(
        @{ Path = $IndexPath; Old = $OldLessonRunner; New = $NewLessonRunner; Description = 'Knowledge-check interface' },
        @{ Path = $AppPath; Old = $OldAssessmentState; New = $NewAssessmentState; Description = 'Session-only assessment state' },
        @{ Path = $AppPath; Old = $OldCatalogReset; New = $NewCatalogReset; Description = 'Assessment catalog reset behavior' },
        @{ Path = $AppPath; Old = $OldStepAssessmentControl; New = $NewStepAssessmentControl; Description = 'Knowledge-check control reset' },
        @{ Path = $AppPath; Old = $OldCompletionAssessmentControl; New = $NewCompletionAssessmentControl; Description = 'Post-lesson knowledge-check control' },
        @{ Path = $AppPath; Old = $OldAssessmentFunctions; New = $NewAssessmentFunctions; Description = 'Knowledge-check behavior' },
        @{ Path = $AppPath; Old = $OldAssessmentEvents; New = $NewAssessmentEvents; Description = 'Knowledge-check event bindings' },
        @{ Path = $AppPath; Old = $OldAssessmentCapture; New = $NewAssessmentCapture; Description = 'Knowledge-check element capture' },
        @{ Path = $AppPath; Old = $OldAssessmentLoad; New = $NewAssessmentLoad; Description = 'Assessment data loading' },
        @{ Path = $ServiceWorkerPath; Old = $OldCacheName; New = $NewCacheName; Description = 'Phase 4B cache version' },
        @{ Path = $ServiceWorkerPath; Old = $OldOfflineAssessment; New = $NewOfflineAssessment; Description = 'Offline assessment data' }
    )

    Write-Section -Text 'Phase 4B - Controlled Update Plan'

    foreach ($Update in $Updates) {
        Test-TextUpdatePlan `
            -Path $Update.Path `
            -OldText $Update.Old `
            -NewText $Update.New `
            -Description $Update.Description
    }

    $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

    if ($ExistingStyles.Contains('/* Phase 4B: lesson knowledge checks */')) {
        Write-Status -Level 'INFO' -Message 'Phase 4B knowledge-check styles are already present.'
    }
    elseif (-not $ExistingStyles.Contains('/* Phase 3D: persistent lesson progress */')) {
        throw 'The Phase 3D lesson-progress style marker was not found.'
    }
    else {
        Write-Status -Level 'PASS' -Message 'Knowledge-check styles are ready to append.'
    }

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 4B updates controlled application files. Run Build mode with -Force after confirming Phase 4A is committed.'
        }

        Write-Section -Text 'Phase 4B - Lesson Knowledge Check Build'

        foreach ($Update in $Updates) {
            Invoke-TextUpdate `
                -Path $Update.Path `
                -OldText $Update.Old `
                -NewText $Update.New `
                -Description $Update.Description
        }

        $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw

        if ($ExistingStyles.Contains('/* Phase 4B: lesson knowledge checks */')) {
            $Script:ExistingUpdates++
            Write-Status -Level 'INFO' -Message 'Knowledge-check styles already present.'
        }
        else {
            Write-Utf8File `
                -Path $StylesPath `
                -Content ($ExistingStyles.TrimEnd([char[]]@("`r", "`n")) + $Phase4BStyles)
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 4B - Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="start-assessment"'; Description = 'Post-lesson knowledge-check control' },
        @{ Path = $IndexPath; Marker = 'id="assessment-runner"'; Description = 'Knowledge-check region' },
        @{ Path = $IndexPath; Marker = 'id="assessment-progress"'; Description = 'Question progress indicator' },
        @{ Path = $IndexPath; Marker = 'id="assessment-options"'; Description = 'Accessible answer group' },
        @{ Path = $IndexPath; Marker = 'aria-live="polite"'; Description = 'Polite answer feedback' },
        @{ Path = $IndexPath; Marker = 'id="assessment-retry"'; Description = 'Penalty-free retry control' },
        @{ Path = $StylesPath; Marker = '/* Phase 4B: lesson knowledge checks */'; Description = 'Knowledge-check styles' },
        @{ Path = $StylesPath; Marker = '.assessment-option:focus-visible'; Description = 'Keyboard focus styling' },
        @{ Path = $AppPath; Marker = 'assessments: []'; Description = 'Assessment application state' },
        @{ Path = $AppPath; Marker = 'function startAssessment(lessonId)'; Description = 'Knowledge-check start behavior' },
        @{ Path = $AppPath; Marker = 'function showAssessmentQuestion()'; Description = 'Question renderer' },
        @{ Path = $AppPath; Marker = 'function answerAssessment(answerIconId)'; Description = 'Supportive answer feedback' },
        @{ Path = $AppPath; Marker = 'function completeAssessment()'; Description = 'Knowledge-check completion summary' },
        @{ Path = $AppPath; Marker = "slice(0, assessment.questions_per_attempt)"; Description = 'Five-question random selection' },
        @{ Path = $AppPath; Marker = "fetch('04_Application/data/assessments.json'"; Description = 'Assessment data loading' },
        @{ Path = $AppPath; Marker = "elements.assessmentFeedback.textContent = 'Good try."; Description = 'Calm incorrect-answer language' },
        @{ Path = $AppPath; Marker = "window.IconGuideIcons.render(icon.icon"; Description = 'Existing icon renderer reused' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check preserved' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior preserved' },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.4.0"; Description = 'Phase 4B cache version' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/assessments.json'"; Description = 'Offline assessment data' },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(asset, { cache: 'reload' })"; Description = 'Fresh install caching preserved' },
        @{ Path = $ServiceWorkerPath; Marker = 'fetch(event.request)'; Description = 'Network-first loading preserved' }
    )

    foreach ($Rule in $ValidationRules) {
        Test-Marker `
            -Path $Rule.Path `
            -Marker $Rule.Marker `
            -Description $Rule.Description
    }

    Test-AssessmentPrivacyAndCsp -AppPath $AppPath

    Write-Section -Text 'Phase 4B Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $DataMetrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $DataMetrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $DataMetrics.StepCount
    Write-Metric -Name 'Assessment records' -Value $DataMetrics.AssessmentCount
    Write-Metric -Name 'Question-bank records' -Value $DataMetrics.QuestionCount
    Write-Metric -Name 'Questions per attempt' -Value $DataMetrics.QuestionsPerAttempt
    Write-Metric -Name 'Answer options per question' -Value $DataMetrics.AnswerOptionsPerQuestion
    Write-Metric -Name 'Updated file operations' -Value $Script:UpdatedFileOperations
    Write-Metric -Name 'Existing updates' -Value $Script:ExistingUpdates
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Assessment result storage' -Value 'Session only'

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4B COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 4B ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
