# ============================================================================
# Build-TechSavvySageIconGuidePhase4A.ps1
# Phase 4A - Guided Mastery Assessment Data Foundation
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 4A Assessment Data Builder'
$Script:UtilityVersion = '0.4.0'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:CreatedFiles = 0
$Script:ReplacedFiles = 0
$Script:ExistingFiles = 0

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
        [ValidateSet('INFO', 'CREATE', 'REPLACE', 'EXISTS', 'VALIDATE', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'CREATE'   { 'Green' }
        'REPLACE'  { 'Yellow' }
        'EXISTS'   { 'DarkGray' }
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

    Write-Host ('{0,-36}: {1}' -f $Name, $Value)
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

function Get-NormalizedContent {
    param ([Parameter(Mandatory)][AllowEmptyString()][string]$Content)

    return (($Content -replace "`r`n", "`n").TrimEnd([char[]]@("`r", "`n")) + "`n")
}

function Write-GeneratedFile {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        [Parameter(Mandatory)][bool]$AllowReplacement
    )

    $NormalizedContent = Get-NormalizedContent -Content $Content

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $ExistingContent = Get-Content -LiteralPath $Path -Raw

        if ((Get-NormalizedContent -Content $ExistingContent) -ceq $NormalizedContent) {
            $Script:ExistingFiles++
            Write-Status -Level 'EXISTS' -Message $Path
            return
        }

        if (-not $AllowReplacement) {
            throw "The existing assessment data differs from the Phase 4A definition. Review it or rerun Build with -Force: $Path"
        }

        $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)
        $Script:ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
        return
    }

    $ParentPath = Split-Path -Path $Path -Parent

    if (-not (Test-Path -LiteralPath $ParentPath -PathType Container)) {
        throw "The assessment data directory does not exist: $ParentPath"
    }

    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)
    $Script:CreatedFiles++
    Write-Status -Level 'CREATE' -Message $Path
}

function Get-FileHashMap {
    param ([Parameter(Mandatory)][string[]]$Paths)

    $Map = @{}

    foreach ($Path in $Paths) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Cannot hash missing Phase 3 runtime file: $Path"
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
            throw "Phase 4A unexpectedly changed a Phase 3 runtime file: $Path"
        }
    }

    Write-Status -Level 'PASS' -Message 'All Phase 3 runtime file hashes remained unchanged.'
}

function Get-LessonTitle {
    param ([Parameter(Mandatory)][object]$Lesson)

    $TitleProperty = $Lesson.PSObject.Properties['title']

    if ($null -ne $TitleProperty -and -not [string]::IsNullOrWhiteSpace([string]$TitleProperty.Value)) {
        return [string]$TitleProperty.Value
    }

    return [string]$Lesson.id
}

function Test-Phase3SourceData {
    param (
        [Parameter(Mandatory)][object[]]$Icons,
        [Parameter(Mandatory)][object[]]$Lessons
    )

    $IconIds = @($Icons | ForEach-Object { [string]$_.id })
    $LessonIds = @($Lessons | ForEach-Object { [string]$_.id })
    $Steps = @($Lessons | ForEach-Object { @($_.steps) })
    $ReferencedIconIds = @($Steps | ForEach-Object { [string]$_.icon_id })

    if ($Icons.Count -ne 40) {
        throw "Expected 40 icon records but found $($Icons.Count)."
    }

    if (@($IconIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
        throw 'The icon library contains duplicate identifiers.'
    }

    if ($Lessons.Count -ne 4) {
        throw "Expected four lesson records but found $($Lessons.Count)."
    }

    if (@($LessonIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
        throw 'The lesson library contains duplicate identifiers.'
    }

    if (@($LessonIds | Where-Object { $_ -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' }).Count -gt 0) {
        throw 'Lesson identifiers must use lowercase kebab-case for stable assessment identifiers.'
    }

    if ($Steps.Count -ne 40) {
        throw "Expected 40 lesson steps but found $($Steps.Count)."
    }

    foreach ($Lesson in $Lessons) {
        $LessonSteps = @($Lesson.steps)

        if ($LessonSteps.Count -lt 5) {
            throw "Lesson '$($Lesson.id)' must contain at least five steps for a five-question attempt."
        }

        $LessonIconIds = @($LessonSteps | ForEach-Object { [string]$_.icon_id })

        if (@($LessonIconIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
            throw "Lesson '$($Lesson.id)' contains a duplicate icon reference."
        }
    }

    $UnknownReferences = @($ReferencedIconIds | Where-Object { $IconIds -cnotcontains $_ })

    if ($UnknownReferences.Count -gt 0) {
        throw "Lesson data references unknown icons: $($UnknownReferences -join ', ')"
    }

    if (@($ReferencedIconIds | Sort-Object -Unique).Count -ne 40) {
        throw 'The lessons must collectively represent all 40 icons exactly once.'
    }

    Write-Status -Level 'PASS' -Message 'The Phase 3 source data is a valid foundation for Phase 4A.'
}

function New-AssessmentData {
    param ([Parameter(Mandatory)][object[]]$Lessons)

    $AssessmentRecords = @()

    foreach ($Lesson in $Lessons) {
        $LessonId = [string]$Lesson.id
        $LessonTitle = Get-LessonTitle -Lesson $Lesson
        $LessonSteps = @($Lesson.steps)
        $LessonIconIds = @($LessonSteps | ForEach-Object { [string]$_.icon_id })
        $Questions = @()

        for ($QuestionIndex = 0; $QuestionIndex -lt $LessonIconIds.Count; $QuestionIndex++) {
            $CorrectIconId = $LessonIconIds[$QuestionIndex]
            $DistractorIconIds = @(
                $LessonIconIds[($QuestionIndex + 1) % $LessonIconIds.Count]
                $LessonIconIds[($QuestionIndex + 2) % $LessonIconIds.Count]
                $LessonIconIds[($QuestionIndex + 3) % $LessonIconIds.Count]
            )

            $Questions += [ordered]@{
                id = ('{0}-question-{1:D2}' -f $LessonId, ($QuestionIndex + 1))
                type = 'icon-to-meaning'
                prompt = 'What does this icon mean?'
                icon_id = $CorrectIconId
                correct_answer_icon_id = $CorrectIconId
                distractor_icon_ids = $DistractorIconIds
            }
        }

        $AssessmentRecords += [ordered]@{
            id = ('{0}-assessment' -f $LessonId)
            lesson_id = $LessonId
            title = ('{0} Knowledge Check' -f $LessonTitle)
            instructions = 'Choose the meaning that best matches the displayed icon. There is no timer or penalty.'
            questions_per_attempt = 5
            questions = $Questions
        }
    }

    return [ordered]@{
        schema_version = '1.0'
        release_version = '0.4.0'
        assessments = $AssessmentRecords
    }
}

function Test-AssessmentData {
    param (
        [Parameter(Mandatory)][object]$AssessmentData,
        [Parameter(Mandatory)][object[]]$Icons,
        [Parameter(Mandatory)][object[]]$Lessons
    )

    if ([string]$AssessmentData.schema_version -ne '1.0') {
        throw 'Assessment schema_version must be 1.0.'
    }

    if ([string]$AssessmentData.release_version -ne '0.4.0') {
        throw 'Assessment release_version must be 0.4.0.'
    }

    $Assessments = @($AssessmentData.assessments)
    $IconIds = @($Icons | ForEach-Object { [string]$_.id })
    $LessonIds = @($Lessons | ForEach-Object { [string]$_.id })
    $AssessmentIds = @($Assessments | ForEach-Object { [string]$_.id })
    $AssessmentLessonIds = @($Assessments | ForEach-Object { [string]$_.lesson_id })
    $Questions = @($Assessments | ForEach-Object { @($_.questions) })
    $QuestionIds = @($Questions | ForEach-Object { [string]$_.id })
    $CorrectIconIds = @($Questions | ForEach-Object { [string]$_.correct_answer_icon_id })
    $AllReferencedIconIds = @()
    $InvalidReferenceCount = 0
    $CrossLessonDistractorCount = 0

    if ($Assessments.Count -ne 4) {
        throw "Expected four assessment records but found $($Assessments.Count)."
    }

    if (@($AssessmentIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
        throw 'Assessment identifiers must be unique.'
    }

    if (@($AssessmentLessonIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
        throw 'Each lesson may have only one assessment record.'
    }

    if (@($AssessmentLessonIds | Where-Object { $LessonIds -cnotcontains $_ }).Count -gt 0) {
        throw 'Every assessment must reference an existing lesson.'
    }

    if (@($LessonIds | Where-Object { $AssessmentLessonIds -cnotcontains $_ }).Count -gt 0) {
        throw 'Every lesson must have an assessment record.'
    }

    if ($Questions.Count -ne 40) {
        throw "Expected 40 question-bank records but found $($Questions.Count)."
    }

    if (@($QuestionIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
        throw 'Question identifiers must be unique.'
    }

    foreach ($Assessment in $Assessments) {
        $LessonId = [string]$Assessment.lesson_id
        $MatchingLessons = @($Lessons | Where-Object { [string]$_.id -ceq $LessonId })
        $LessonIconIds = @($MatchingLessons[0].steps | ForEach-Object { [string]$_.icon_id })
        $AssessmentQuestions = @($Assessment.questions)

        if ([int]$Assessment.questions_per_attempt -ne 5) {
            throw "Assessment '$($Assessment.id)' must present five questions per attempt."
        }

        if ($AssessmentQuestions.Count -ne $LessonIconIds.Count) {
            throw "Assessment '$($Assessment.id)' question bank must match its lesson step count."
        }

        if ([string]::IsNullOrWhiteSpace([string]$Assessment.title) -or
            [string]::IsNullOrWhiteSpace([string]$Assessment.instructions)) {
            throw "Assessment '$($Assessment.id)' requires a title and instructions."
        }

        foreach ($Question in $AssessmentQuestions) {
            $QuestionIconId = [string]$Question.icon_id
            $CorrectIconId = [string]$Question.correct_answer_icon_id
            $DistractorIds = @($Question.distractor_icon_ids | ForEach-Object { [string]$_ })
            $AllQuestionReferences = @($QuestionIconId, $CorrectIconId) + $DistractorIds
            $AllReferencedIconIds += $AllQuestionReferences

            if ([string]$Question.type -cne 'icon-to-meaning') {
                throw "Question '$($Question.id)' has an unsupported question type."
            }

            if ([string]::IsNullOrWhiteSpace([string]$Question.prompt)) {
                throw "Question '$($Question.id)' requires a prompt."
            }

            if ($QuestionIconId -cne $CorrectIconId) {
                throw "Question '$($Question.id)' must use the displayed icon as its correct answer reference."
            }

            if ($LessonIconIds -cnotcontains $CorrectIconId) {
                throw "Question '$($Question.id)' correct answer does not belong to its lesson."
            }

            if ($DistractorIds.Count -ne 3 -or
                @($DistractorIds | Sort-Object -Unique).Count -ne 3) {
                throw "Question '$($Question.id)' must contain three unique distractors."
            }

            if ($DistractorIds -ccontains $CorrectIconId) {
                throw "Question '$($Question.id)' includes its correct answer as a distractor."
            }

            $InvalidReferenceCount += @($AllQuestionReferences | Where-Object { $IconIds -cnotcontains $_ }).Count
            $CrossLessonDistractorCount += @($DistractorIds | Where-Object { $LessonIconIds -cnotcontains $_ }).Count
        }
    }

    if ($InvalidReferenceCount -ne 0) {
        throw "Assessment data contains $InvalidReferenceCount invalid icon references."
    }

    if ($CrossLessonDistractorCount -ne 0) {
        throw "Assessment data contains $CrossLessonDistractorCount cross-lesson distractors."
    }

    if (@($CorrectIconIds | Sort-Object -Unique).Count -ne 40) {
        throw 'Every icon must appear exactly once as a correct answer across the four question banks.'
    }

    if (@($CorrectIconIds | Group-Object | Where-Object { $_.Count -ne 1 }).Count -gt 0) {
        throw 'Correct-answer icon references must not be duplicated.'
    }

    Write-Status -Level 'PASS' -Message 'All Phase 4A assessment records and icon references are valid.'

    return [pscustomobject]@{
        AssessmentCount = $Assessments.Count
        QuestionCount = $Questions.Count
        QuestionsPerAttempt = 5
        AnswerOptionsPerQuestion = 4
        UniqueCorrectIconCount = @($CorrectIconIds | Sort-Object -Unique).Count
        UniqueReferencedIconCount = @($AllReferencedIconIds | Sort-Object -Unique).Count
        InvalidReferenceCount = $InvalidReferenceCount
        CrossLessonDistractorCount = $CrossLessonDistractorCount
    }
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 4A builder directory.'
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

    Write-Section -Text 'Phase 4A - Preflight Validation'

    foreach ($RequiredPath in $RuntimePaths) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 3 baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    $RuntimeHashesBefore = Get-FileHashMap -Paths $RuntimePaths
    $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
    $LessonData = Get-Content -LiteralPath $LessonDataPath -Raw | ConvertFrom-Json
    $Icons = @($IconData.icons)
    $Lessons = @($LessonData.lessons)

    Test-Phase3SourceData -Icons $Icons -Lessons $Lessons

    $ExpectedAssessmentData = New-AssessmentData -Lessons $Lessons
    $ExpectedAssessmentContent = $ExpectedAssessmentData | ConvertTo-Json -Depth 12

    Write-Section -Text ('Phase 4A - {0}' -f $OperatingMode)

    if ($OperatingMode -eq 'Build') {
        Write-GeneratedFile `
            -Path $AssessmentDataPath `
            -Content $ExpectedAssessmentContent `
            -AllowReplacement ([bool]$Force)
    }
    elseif (-not (Test-Path -LiteralPath $AssessmentDataPath -PathType Leaf)) {
        throw "ValidateOnly requires the Phase 4A assessment data file: $AssessmentDataPath"
    }

    if (-not (Test-Path -LiteralPath $AssessmentDataPath -PathType Leaf)) {
        throw "Phase 4A assessment data was not created: $AssessmentDataPath"
    }

    $ActualAssessmentContent = Get-Content -LiteralPath $AssessmentDataPath -Raw

    if ((Get-NormalizedContent -Content $ActualAssessmentContent) -cne
        (Get-NormalizedContent -Content $ExpectedAssessmentContent)) {
        throw 'The assessment data file does not match the deterministic Phase 4A definition.'
    }

    Write-Status -Level 'PASS' -Message 'Assessment data matches the deterministic Phase 4A definition.'

    $ActualAssessmentData = $ActualAssessmentContent | ConvertFrom-Json
    $AssessmentMetrics = Test-AssessmentData `
        -AssessmentData $ActualAssessmentData `
        -Icons $Icons `
        -Lessons $Lessons

    $RuntimeHashesAfter = Get-FileHashMap -Paths $RuntimePaths
    Test-HashMapsMatch -Before $RuntimeHashesBefore -After $RuntimeHashesAfter

    $LessonSteps = @($Lessons | ForEach-Object { @($_.steps) })

    Write-Section -Text 'Phase 4A Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $Icons.Count
    Write-Metric -Name 'Lesson records' -Value $Lessons.Count
    Write-Metric -Name 'Lesson steps' -Value $LessonSteps.Count
    Write-Metric -Name 'Assessment records' -Value $AssessmentMetrics.AssessmentCount
    Write-Metric -Name 'Question-bank records' -Value $AssessmentMetrics.QuestionCount
    Write-Metric -Name 'Questions per attempt' -Value $AssessmentMetrics.QuestionsPerAttempt
    Write-Metric -Name 'Answer options per question' -Value $AssessmentMetrics.AnswerOptionsPerQuestion
    Write-Metric -Name 'Unique correct icon references' -Value $AssessmentMetrics.UniqueCorrectIconCount
    Write-Metric -Name 'Unique referenced icons' -Value $AssessmentMetrics.UniqueReferencedIconCount
    Write-Metric -Name 'Invalid icon references' -Value $AssessmentMetrics.InvalidReferenceCount
    Write-Metric -Name 'Cross-lesson distractors' -Value $AssessmentMetrics.CrossLessonDistractorCount
    Write-Metric -Name 'Created files' -Value $Script:CreatedFiles
    Write-Metric -Name 'Replaced files' -Value $Script:ReplacedFiles
    Write-Metric -Name 'Existing files' -Value $Script:ExistingFiles
    Write-Metric -Name 'Runtime files changed' -Value 0

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4A COMPLETE'
    Write-Status -Level 'PASS' -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Status -Level 'FAIL' -Message $_.Exception.Message

    if ($_.InvocationInfo.ScriptLineNumber -gt 0) {
        Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
        Write-Host ('Command     : {0}' -f $_.InvocationInfo.Line.Trim()) -ForegroundColor Red
    }

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4A FAILED'
    exit 1
}
