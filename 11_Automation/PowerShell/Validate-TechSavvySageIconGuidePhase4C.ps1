# ============================================================================
# Validate-TechSavvySageIconGuidePhase4C.ps1
# Phase 4C - Structural and Functional Validation
# ============================================================================
[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [string]$BuilderScriptPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 4C Functional Validator'
$Script:UtilityVersion = '0.4.1'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:PassedChecks = 0

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
        [ValidateSet('INFO', 'VALIDATE', 'PASS', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'VALIDATE' { 'Cyan' }
        'PASS'     { 'Green' }
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

function Resolve-RepositoryRoot {
    param (
        [string]$ExplicitRepositoryRoot,
        [Parameter(Mandatory)][string]$ScriptRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepositoryRoot)) {
        return [System.IO.Path]::GetFullPath($ExplicitRepositoryRoot)
    }

    $CurrentPath = [System.IO.Path]::GetFullPath($ScriptRoot)

    while (-not [string]::IsNullOrWhiteSpace($CurrentPath)) {
        if ((Split-Path -Path $CurrentPath -Leaf) -ieq $Script:ExpectedRepositoryName) {
            return $CurrentPath
        }

        $ParentPath = Split-Path -Path $CurrentPath -Parent

        if ($ParentPath -eq $CurrentPath) {
            break
        }

        $CurrentPath = $ParentPath
    }

    throw @'
Unable to determine the repository root automatically.

Place this validator inside the techsavvysage-icon-guide repository or provide
-RepositoryRoot explicitly.
'@
}

function Confirm-Condition {
    param (
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Description
    )

    Write-Status -Level 'VALIDATE' -Message $Description

    if (-not $Condition) {
        throw "Functional validation failed: $Description"
    }

    $Script:PassedChecks++
    Write-Status -Level 'PASS' -Message $Description
}

function Get-FileFingerprintMap {
    param ([Parameter(Mandatory)][string[]]$Paths)

    $Fingerprints = @{}

    foreach ($Path in $Paths) {
        $Fingerprints[$Path] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }

    return $Fingerprints
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 4C functional validator directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $ResolvedRepositoryRoot"
    }

    if ([string]::IsNullOrWhiteSpace($BuilderScriptPath)) {
        $BuilderScriptPath = Join-Path `
            -Path $ResolvedRepositoryRoot `
            -ChildPath '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4C.ps1'
    }
    else {
        $BuilderScriptPath = [System.IO.Path]::GetFullPath($BuilderScriptPath)
    }

    Write-Section -Text 'Phase 4C - Required Path Validation'

    $RequiredPaths = @(
        $BuilderScriptPath,
        (Join-Path $ResolvedRepositoryRoot 'index.html'),
        (Join-Path $ResolvedRepositoryRoot '04_Application\css\styles.css'),
        (Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'),
        (Join-Path $ResolvedRepositoryRoot '04_Application\data\icons.json'),
        (Join-Path $ResolvedRepositoryRoot '04_Application\data\lessons.json'),
        (Join-Path $ResolvedRepositoryRoot '04_Application\data\assessments.json'),
        (Join-Path $ResolvedRepositoryRoot 'service-worker.js'),
        (Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase4B.ps1')
    )

    foreach ($RequiredPath in $RequiredPaths) {
        Confirm-Condition `
            -Condition (Test-Path -LiteralPath $RequiredPath -PathType Leaf) `
            -Description "Required file exists: $RequiredPath"
    }

    Write-Section -Text 'Phase 4C - Builder Structure Validation'

    $Tokens = $null
    $ParseErrors = $null
    $BuilderAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $BuilderScriptPath,
        [ref]$Tokens,
        [ref]$ParseErrors
    )

    Confirm-Condition `
        -Condition (@($ParseErrors).Count -eq 0) `
        -Description 'Builder contains no parser errors'

    $ParameterNames = @(
        $BuilderAst.ParamBlock.Parameters |
            ForEach-Object { $_.Name.VariablePath.UserPath }
    )

    foreach ($RequiredParameter in @('RepositoryRoot', 'OperatingMode', 'Force')) {
        Confirm-Condition `
            -Condition ($ParameterNames -ccontains $RequiredParameter) `
            -Description "Required parameter is declared: $RequiredParameter"
    }

    $FunctionNames = @(
        $BuilderAst.FindAll(
            {
                param ($Node)
                $Node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            },
            $true
        ) | ForEach-Object { $_.Name }
    )

    $RequiredFunctions = @(
        'Write-Banner',
        'Write-Section',
        'Write-Status',
        'Write-Metric',
        'Get-NormalizedPath',
        'Resolve-RepositoryRoot',
        'Test-AssessmentData',
        'Test-ReviewPrivacyAndCsp'
    )

    foreach ($RequiredFunction in $RequiredFunctions) {
        Confirm-Condition `
            -Condition ($FunctionNames -ccontains $RequiredFunction) `
            -Description "Required function is declared: $RequiredFunction"
    }

    $BuilderContent = Get-Content -LiteralPath $BuilderScriptPath -Raw
    $RequiredBuilderMarkers = @(
        '$Script:UtilityName',
        '$Script:UtilityVersion = ''0.4.1''',
        '$Script:ExpectedRepositoryName = ''techsavvysage-icon-guide''',
        '$Script:UpdatedFileOperations',
        '$Script:ExistingUpdates',
        '$Script:ValidatedMarkers',
        "[ValidateSet('Build', 'ValidateOnly')]",
        'Missed icons only',
        'Assessment result storage',
        "'Operating mode {0} completed successfully.'"
    )

    foreach ($RequiredMarker in $RequiredBuilderMarkers) {
        Confirm-Condition `
            -Condition ($BuilderContent.Contains($RequiredMarker)) `
            -Description "Required builder marker is present: $RequiredMarker"
    }

    Write-Section -Text 'Phase 4C - Applied Output Validation'

    $IndexPath = Join-Path $ResolvedRepositoryRoot 'index.html'
    $StylesPath = Join-Path $ResolvedRepositoryRoot '04_Application\css\styles.css'
    $AppPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'
    $AssessmentDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\assessments.json'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'

    $OutputRules = @(
        @{ Path = $IndexPath; Marker = 'id="assessment-review"'; Description = 'Missed-icon review region' },
        @{ Path = $IndexPath; Marker = 'id="assessment-review-heading"'; Description = 'Accessible review heading' },
        @{ Path = $IndexPath; Marker = 'id="assessment-review-list"'; Description = 'Missed-icon review list' },
        @{ Path = $StylesPath; Marker = '/* Phase 4C: missed icon review */'; Description = 'Missed-icon review styles' },
        @{ Path = $StylesPath; Marker = '.assessment-review-card'; Description = 'Responsive review cards' },
        @{ Path = $AppPath; Marker = 'assessmentMissedIconIds: []'; Description = 'Session-only missed-icon state' },
        @{ Path = $AppPath; Marker = 'function renderAssessmentReview()'; Description = 'Review renderer' },
        @{ Path = $AppPath; Marker = 'state.assessmentMissedIconIds.push(correctIcon.id)'; Description = 'Incorrect-answer capture' },
        @{ Path = $AppPath; Marker = "example.textContent = 'Example: ' + icon.example"; Description = 'Plain-language example' },
        @{ Path = $AppPath; Marker = 'elements.assessmentReview.hidden = false'; Description = 'Review display behavior' },
        @{ Path = $AppPath; Marker = 'renderAssessmentReview();'; Description = 'Completion review invocation' },
        @{ Path = $ServiceWorkerPath; Marker = 'techsavvysage-icon-guide-v0.4.1'; Description = 'Phase 4C cache version' },
        @{ Path = $ServiceWorkerPath; Marker = "'./04_Application/data/assessments.json'"; Description = 'Offline assessment data' }
    )

    foreach ($Rule in $OutputRules) {
        $OutputContent = Get-Content -LiteralPath $Rule.Path -Raw
        Confirm-Condition `
            -Condition ($OutputContent.Contains($Rule.Marker)) `
            -Description $Rule.Description
    }

    $AppContent = Get-Content -LiteralPath $AppPath -Raw
    $ReviewStart = $AppContent.IndexOf('    function renderAssessmentReview() {')
    $ReviewEnd = $AppContent.IndexOf('    function showIconDetail(icon) {')

    Confirm-Condition `
        -Condition ($ReviewStart -ge 0 -and $ReviewEnd -gt $ReviewStart) `
        -Description 'Review behavior can be isolated for privacy validation'

    $ReviewContent = $AppContent.Substring($ReviewStart, $ReviewEnd - $ReviewStart)

    foreach ($ForbiddenMarker in @(
        'localStorage',
        'sessionStorage',
        'fetch(',
        'XMLHttpRequest',
        'sendBeacon'
    )) {
        Confirm-Condition `
            -Condition (-not $ReviewContent.Contains($ForbiddenMarker)) `
            -Description "Review behavior excludes persistent or external marker: $ForbiddenMarker"
    }

    $AssessmentData = Get-Content -LiteralPath $AssessmentDataPath -Raw | ConvertFrom-Json
    $Assessments = @($AssessmentData.assessments)
    $Questions = @($Assessments | ForEach-Object { @($_.questions) })

    Confirm-Condition `
        -Condition ($Assessments.Count -eq 4) `
        -Description 'Assessment data contains four lesson assessments'
    Confirm-Condition `
        -Condition ($Questions.Count -eq 40) `
        -Description 'Assessment data contains 40 question-bank records'

    Write-Section -Text 'Phase 4C - ValidateOnly Runtime Test'

    $ControlledPaths = @($IndexPath, $StylesPath, $AppPath, $AssessmentDataPath, $ServiceWorkerPath)
    $BeforeFingerprints = Get-FileFingerprintMap -Paths $ControlledPaths
    $HostExecutable = (Get-Process -Id $PID).Path

    Write-Status -Level 'INFO' -Message 'Invoking the Phase 4C builder in ValidateOnly mode.'

    $InvocationOutput = @(
        & $HostExecutable `
            -NoLogo `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $BuilderScriptPath `
            -RepositoryRoot $ResolvedRepositoryRoot `
            -OperatingMode ValidateOnly 2>&1
    )
    $InvocationExitCode = $LASTEXITCODE
    $InvocationText = $InvocationOutput | Out-String

    Confirm-Condition `
        -Condition ($InvocationExitCode -eq 0) `
        -Description 'Builder ValidateOnly invocation exits successfully'
    Confirm-Condition `
        -Condition ($InvocationText.Contains('ValidateOnly mode selected. No files were changed.')) `
        -Description 'Builder confirms non-mutating validation mode'
    Confirm-Condition `
        -Condition ($InvocationText.Contains('TECHSAVVYSAGE ICON GUIDE PHASE 4C COMPLETE')) `
        -Description 'Builder reaches its Phase 4C completion path'
    Confirm-Condition `
        -Condition ($InvocationText.Contains('Operating mode ValidateOnly completed successfully.')) `
        -Description 'Builder reports successful ValidateOnly completion'

    $AfterFingerprints = Get-FileFingerprintMap -Paths $ControlledPaths

    foreach ($ControlledPath in $ControlledPaths) {
        Confirm-Condition `
            -Condition ($BeforeFingerprints[$ControlledPath] -ceq $AfterFingerprints[$ControlledPath]) `
            -Description "ValidateOnly preserved file content: $ControlledPath"
    }

    Write-Section -Text 'Phase 4C Functional Validation Metrics'
    Write-Metric -Name 'Required paths' -Value $RequiredPaths.Count
    Write-Metric -Name 'Required builder functions' -Value $RequiredFunctions.Count
    Write-Metric -Name 'Applied output rules' -Value $OutputRules.Count
    Write-Metric -Name 'Runtime exit code' -Value $InvocationExitCode
    Write-Metric -Name 'Controlled files unchanged' -Value $ControlledPaths.Count
    Write-Metric -Name 'Passed checks' -Value $Script:PassedChecks

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 4C FUNCTIONAL VALIDATION COMPLETE'
    Write-Status -Level 'PASS' -Message 'Phase 4C passed structural, output, privacy, and runtime validation.'
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 4C FUNCTIONAL VALIDATION ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
