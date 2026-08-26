# ============================================================================
# Build-TechSavvySageIconGuidePhase4D.ps1
# Phase 4D - Targeted Reinforcement
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 4D Targeted Reinforcement Builder'
$Script:UtilityVersion = '0.4.2'
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
        throw "The expected Phase 4D marker was not found for '$Description' in: $Path"
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
        throw "Required Phase 4D file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if (-not $Content.Contains($Marker)) {
        throw "Required Phase 4D marker is missing: $Description"
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
        throw "Required Phase 4D baseline marker is missing: $Description"
    }

    $Script:ValidatedMarkers++
    Write-Status -Level 'PASS' -Message $Description
}

function Test-TargetedPracticePrivacyAndCsp {
    param ([Parameter(Mandatory)][string]$AppPath)

    $Content = Get-Content -LiteralPath $AppPath -Raw
    $StartMarker = "        elements.assessmentPracticeMissed.addEventListener('click', function () {"
    $EndMarker = "        elements.assessmentReturn.addEventListener('click', function () {"
    $StartIndex = $Content.IndexOf($StartMarker)
    $EndIndex = $Content.IndexOf($EndMarker)

    if ($StartIndex -lt 0 -or $EndIndex -le $StartIndex) {
        throw 'Unable to isolate the Phase 4D targeted-practice event.'
    }

    $TargetedPracticeContent = $Content.Substring($StartIndex, $EndIndex - $StartIndex)

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
        if ($TargetedPracticeContent.Contains($ForbiddenMarker)) {
            throw "Phase 4D targeted practice contains a forbidden marker: $ForbiddenMarker"
        }
    }

    Write-Status -Level 'PASS' -Message 'Targeted reinforcement remains session-only and CSP-safe.'
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 4D builder directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $ResolvedRepositoryRoot"
    }

    $IndexPath = Join-Path $ResolvedRepositoryRoot 'index.html'
    $AppPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'
    $AssessmentDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\assessments.json'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $Phase4CPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4C.ps1'
    $Phase4CValidatorPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase4C.ps1'

    Write-Section -Text 'Phase 4D - Preflight Validation'

    foreach ($RequiredPath in @(
        $IndexPath,
        $AppPath,
        $AssessmentDataPath,
        $ServiceWorkerPath,
        $Phase4CPath,
        $Phase4CValidatorPath
    )) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The committed Phase 4C baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    Test-Marker `
        -Path $AppPath `
        -Marker 'function startPractice(specificIds)' `
        -Description 'Existing targeted-practice engine'
    Test-Marker `
        -Path $AppPath `
        -Marker 'function renderAssessmentReview()' `
        -Description 'Phase 4C missed-icon review baseline'
    Test-Marker `
        -Path $AppPath `
        -Marker 'assessmentMissedIconIds: []' `
        -Description 'Session-only missed-icon state'
    Test-AnyMarker `
        -Path $ServiceWorkerPath `
        -Markers @(
            'techsavvysage-icon-guide-v0.4.1',
            'techsavvysage-icon-guide-v0.4.2'
        ) `
        -Description 'Supported Phase 4 release cache baseline'

    $AssessmentData = Get-Content -LiteralPath $AssessmentDataPath -Raw | ConvertFrom-Json
    $Assessments = @($AssessmentData.assessments)
    $Questions = @($Assessments | ForEach-Object { @($_.questions) })

    if ($Assessments.Count -ne 4 -or $Questions.Count -ne 40) {
        throw 'Phase 4D requires four assessments and 40 question-bank records.'
    }

    $OldPracticeButton = @'
                                <button id="assessment-retry" class="secondary-button" type="button" hidden>Try five more questions</button>
                                <button id="assessment-return" class="primary-button" type="button" hidden>Return to lesson choices</button>
'@
    $NewPracticeButton = @'
                                <button id="assessment-retry" class="secondary-button" type="button" hidden>Try five more questions</button>
                                <button id="assessment-practice-missed" class="secondary-button" type="button" hidden>Practice missed icons</button>
                                <button id="assessment-return" class="primary-button" type="button" hidden>Return to lesson choices</button>
'@

    $OldQuestionPracticeReset = @'
        elements.assessmentRetry.hidden = true;
        elements.assessmentReturn.hidden = true;
        elements.assessmentReview.hidden = true;
'@
    $NewQuestionPracticeReset = @'
        elements.assessmentRetry.hidden = true;
        elements.assessmentPracticeMissed.hidden = true;
        elements.assessmentReturn.hidden = true;
        elements.assessmentReview.hidden = true;
'@

    $OldPracticeCompletion = @'
        elements.assessmentNext.hidden = true;
        elements.assessmentRetry.hidden = false;
        elements.assessmentReturn.hidden = false;
'@
    $NewPracticeCompletion = @'
        elements.assessmentNext.hidden = true;
        elements.assessmentRetry.hidden = false;
        elements.assessmentPracticeMissed.hidden = state.assessmentMissedIconIds.length === 0;
        elements.assessmentReturn.hidden = false;
'@

    $OldTargetedPracticeEvent = @'
        elements.assessmentReturn.addEventListener('click', function () {
'@
    $NewTargetedPracticeEvent = @'
        elements.assessmentPracticeMissed.addEventListener('click', function () {
            if (state.assessmentMissedIconIds.length === 0) {
                return;
            }

            const missedIconIds = shuffledCopy(state.assessmentMissedIconIds);
            setMode('practice');
            startPractice(missedIconIds);
            setStatus('Practicing ' + missedIconIds.length + ' missed icon' + (missedIconIds.length === 1 ? '.' : 's.'));
        });
        elements.assessmentReturn.addEventListener('click', function () {
'@

    $OldPracticeCapture = @'
            'assessment-review-list', 'assessment-next', 'assessment-retry',
            'assessment-return',
'@
    $NewPracticeCapture = @'
            'assessment-review-list', 'assessment-next', 'assessment-retry',
            'assessment-practice-missed', 'assessment-return',
'@

    $OldCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.4.1';"
    $NewCacheName = "const CACHE_NAME = 'techsavvysage-icon-guide-v0.4.2';"

    $Updates = @(
        @{ Path = $IndexPath; Old = $OldPracticeButton; New = $NewPracticeButton; Description = 'Practice missed icons control' },
        @{ Path = $AppPath; Old = $OldQuestionPracticeReset; New = $NewQuestionPracticeReset; Description = 'Targeted-practice control reset' },
        @{ Path = $AppPath; Old = $OldPracticeCompletion; New = $NewPracticeCompletion; Description = 'Conditional targeted-practice control' },
        @{ Path = $AppPath; Old = $OldTargetedPracticeEvent; New = $NewTargetedPracticeEvent; Description = 'Missed-icon practice handoff' },
        @{ Path = $AppPath; Old = $OldPracticeCapture; New = $NewPracticeCapture; Description = 'Targeted-practice element capture' },
        @{ Path = $ServiceWorkerPath; Old = $OldCacheName; New = $NewCacheName; Description = 'Phase 4D cache version' }
    )

    Write-Section -Text 'Phase 4D - Controlled Update Plan'

    foreach ($Update in $Updates) {
        Test-TextUpdatePlan `
            -Path $Update.Path `
            -OldText $Update.Old `
            -NewText $Update.New `
            -Description $Update.Description
    }

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 4D updates controlled application files. Run Build mode with -Force after confirming Phase 4C is committed.'
        }

        Write-Section -Text 'Phase 4D - Targeted Reinforcement Build'

        foreach ($Update in $Updates) {
            Invoke-TextUpdate `
                -Path $Update.Path `
                -OldText $Update.Old `
                -NewText $Update.New `
                -Description $Update.Description
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    Write-Section -Text 'Phase 4D - Release Validation'

    $ValidationRules = @(
        @{ Path = $IndexPath; Marker = 'id="assessment-practice-missed"'; Description = 'Practice missed icons control' },
        @{ Path = $IndexPath; Marker = '>Practice missed icons</button>'; Description = 'Plain-language targeted-practice label' },
        @{ Path = $AppPath; Marker = 'function startPractice(specificIds)'; Description = 'Existing practice engine reused' },
        @{ Path = $AppPath; Marker = 'elements.assessmentPracticeMissed.hidden = true'; Description = 'Control hidden during questions' },
        @{ Path = $AppPath; Marker = 'elements.assessmentPracticeMissed.hidden = state.assessmentMissedIconIds.length === 0'; Description = 'Control shown only for missed icons' },
        @{ Path = $AppPath; Marker = "elements.assessmentPracticeMissed.addEventListener('click'"; Description = 'Targeted-practice event binding' },
        @{ Path = $AppPath; Marker = 'const missedIconIds = shuffledCopy(state.assessmentMissedIconIds)'; Description = 'Session-only missed list reused' },
        @{ Path = $AppPath; Marker = "setMode('practice')"; Description = 'Existing Practice mode selected' },
        @{ Path = $AppPath; Marker = 'startPractice(missedIconIds)'; Description = 'Missed icons passed to practice engine' },
        @{ Path = $AppPath; Marker = "setStatus('Practicing ' + missedIconIds.length"; Description = 'Accessible practice status' },
        @{ Path = $AppPath; Marker = "'assessment-practice-missed', 'assessment-return'"; Description = 'Targeted-practice element captured' },
        @{ Path = $AppPath; Marker = 'registration.update()'; Description = 'Deployment update check preserved' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'"; Description = 'Deployment reload behavior preserved' },
        @{ Path = $ServiceWorkerPath; Marker = 'techsavvysage-icon-guide-v0.4.2'; Description = 'Phase 4D cache version' },
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

    Test-TargetedPracticePrivacyAndCsp -AppPath $AppPath

    Write-Section -Text 'Phase 4D Execution Metrics'
    Write-Metric -Name 'Assessment records' -Value $Assessments.Count
    Write-Metric -Name 'Question-bank records' -Value $Questions.Count
    Write-Metric -Name 'Controlled update rules' -Value $Updates.Count
    Write-Metric -Name 'Updated file operations' -Value $Script:UpdatedFileOperations
    Write-Metric -Name 'Existing updates' -Value $Script:ExistingUpdates
    Write-Metric -Name 'Validated markers' -Value $Script:ValidatedMarkers
    Write-Metric -Name 'Reinforcement scope' -Value 'Missed icons only'
    Write-Metric -Name 'Practice engine' -Value 'Existing Practice mode'
    Write-Metric -Name 'Assessment result storage' -Value 'Session only'

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4D COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 4D ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
