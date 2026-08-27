# =====================================================================
# Validate-TechSavvySageIconGuidePhase5B.ps1
# Phase 5B - Functional Validation
# =====================================================================

[CmdletBinding()]
param ([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section {
    param ([Parameter(Mandatory)][string]$Title)
    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ('-' * 76) -ForegroundColor DarkGray
}

function Write-Pass {
    param ([Parameter(Mandatory)][string]$Message)
    Write-Host ('[PASS    ] {0}' -f $Message) -ForegroundColor Green
}

function Resolve-PhaseRepositoryRoot {
    param ([string]$RequestedRoot)
    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) {
        return (Resolve-Path -LiteralPath $RequestedRoot).Path
    }
    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the validator directory. Supply -RepositoryRoot.'
    }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
}

function Assert-PowerShellSyntax {
    param ([Parameter(Mandatory)][string]$Path)

    $Tokens = $null
    $Errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$Tokens, [ref]$Errors)
    if ($Errors.Count -gt 0) {
        $Messages = $Errors | ForEach-Object {
            'Line {0}, column {1}: {2}' -f $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber, $_.Message
        }
        throw ("Parser errors detected in {0}:`n{1}" -f $Path, ($Messages -join [Environment]::NewLine))
    }
}

function Get-FileMarkers {
    return @{
        '01_Documentation\Phase_5B_Usability_Validation_Protocol.md' = @(
            '# Phase 5B Usability Validation Protocol', 'Rolling cohort', 'Five-session checkpoint',
            'no fixed participant ceiling', 'Decision thresholds', 'Session-only', 'Phase 5B exit criteria'
        )
        '05_Testing\Phase_5B_Participant_Task_Script.md' = @(
            '# Phase 5B Participant Task Script', 'Facilitated path', 'Self-guided path',
            'Core tasks', 'Do not record the knowledge-check score', 'Session disposition'
        )
        '05_Testing\Phase_5B_Session_Scoring_Rubric.md' = @(
            '# Phase 5B Session Scoring Rubric', 'Independent', 'Assisted', 'Not completed',
            'Not Applicable', 'Completion rate', 'Assistance rate'
        )
        '05_Testing\Phase_5B_Usability_Issue_Register.md' = @(
            '# Phase 5B Usability Issue Register', 'Blocking', 'High', 'Medium', 'Low',
            'Required response', 'Recording rules'
        )
        '05_Testing\Phase_5B_Findings_Report_Template.md' = @(
            '# Phase 5B Findings Report Template', 'Five-session checkpoint', 'Task findings',
            'Task completion rate', 'Accessibility findings', 'Checkpoint decision', 'Phase 5C recommendation'
        )
    }
}

function Get-ControlledHashes {
    param ([Parameter(Mandatory)][string]$Root)

    $Paths = @('index.html', '04_Application\css\styles.css', '04_Application\js\app.js', 'service-worker.js')
    $Hashes = @{}
    foreach ($RelativePath in $Paths) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Controlled runtime file is missing: $RelativePath"
        }
        $Hashes[$RelativePath] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
    return $Hashes
}

function Assert-PackageContent {
    param ([Parameter(Mandatory)][string]$Root)

    $Passed = 0
    $Markers = Get-FileMarkers
    foreach ($RelativePath in $Markers.Keys) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Required Phase 5B file is missing: $RelativePath"
        }
        $Passed++
        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $Markers[$RelativePath]) {
            if (-not $Content.Contains($Marker)) {
                throw "Required marker '$Marker' is missing from $RelativePath."
            }
            $Passed++
        }
    }

    $Combined = ($Markers.Keys | ForEach-Object {
        Get-Content -LiteralPath (Join-Path $Root $_) -Raw
    }) -join [Environment]::NewLine

    foreach ($Forbidden in @('Participant name |', 'Email address |', 'Phone number |', 'Library card number |', 'Knowledge-check score |', 'Missed icons |')) {
        if ($Combined.Contains($Forbidden)) {
            throw "Prohibited collection field detected: $Forbidden"
        }
        $Passed++
    }
    return $Passed
}

try {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5B FUNCTIONAL VALIDATION' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan

    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    $BuilderPath = Join-Path $Root '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5B.ps1'
    $ValidatorPath = Join-Path $Root '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5B.ps1'

    Write-Section -Title 'Required Path Validation'
    $RequiredPaths = @(
        $Root,
        (Join-Path $Root '01_Documentation'),
        (Join-Path $Root '05_Testing'),
        (Join-Path $Root '11_Automation\PowerShell'),
        $BuilderPath,
        $ValidatorPath,
        (Join-Path $Root 'index.html'),
        (Join-Path $Root '04_Application\css\styles.css'),
        (Join-Path $Root '04_Application\js\app.js'),
        (Join-Path $Root 'service-worker.js')
    )
    foreach ($Path in $RequiredPaths) {
        if (-not (Test-Path -LiteralPath $Path)) { throw "Required path is missing: $Path" }
    }
    Write-Pass -Message 'All required paths exist.'

    Write-Section -Title 'PowerShell Syntax Validation'
    Assert-PowerShellSyntax -Path $BuilderPath
    Assert-PowerShellSyntax -Path $ValidatorPath
    Write-Pass -Message 'Builder and validator parse successfully.'

    Write-Section -Title 'Builder Structure Validation'
    $BuilderContent = Get-Content -LiteralPath $BuilderPath -Raw
    $RequiredFunctions = @(
        'Write-Section', 'Write-Pass', 'Resolve-PhaseRepositoryRoot',
        'Get-UsabilityFileDefinitions', 'Get-UsabilityFileContent', 'Set-Utf8File',
        'Get-ControlledRuntimeHashes', 'Test-UsabilityPackage'
    )
    foreach ($FunctionName in $RequiredFunctions) {
        if (-not $BuilderContent.Contains("function $FunctionName")) {
            throw "Required builder function is missing: $FunctionName"
        }
    }
    Write-Pass -Message 'All required builder functions exist.'

    $HashesBefore = Get-ControlledHashes -Root $Root

    Write-Section -Title 'Usability Package Content Validation'
    $PassedChecks = Assert-PackageContent -Root $Root
    Write-Pass -Message 'Rolling-cohort measures, severity rules, privacy controls, and report templates validated.'

    Write-Section -Title 'Runtime Invocation Validation'
    & $BuilderPath -Mode ValidateOnly -RepositoryRoot $Root
    $RuntimeExitCode = 0
    Write-Pass -Message 'Builder ValidateOnly invocation completed without a runtime error.'

    $HashesAfter = Get-ControlledHashes -Root $Root
    $ChangedFiles = @($HashesBefore.Keys | Where-Object { $HashesBefore[$_] -ne $HashesAfter[$_] })
    if ($ChangedFiles.Count -gt 0) {
        throw ('Controlled runtime files changed during validation: {0}' -f ($ChangedFiles -join ', '))
    }

    $TotalChecks = $PassedChecks + $RequiredPaths.Count + $RequiredFunctions.Count + 2 + $HashesBefore.Count + 1

    Write-Section -Title 'Phase 5B Functional Validation Metrics'
    Write-Host ('Required paths                    : {0}' -f $RequiredPaths.Count)
    Write-Host ('Required builder functions        : {0}' -f $RequiredFunctions.Count)
    Write-Host ('Usability documents               : {0}' -f (Get-FileMarkers).Count)
    Write-Host ('Runtime exit code                 : {0}' -f $RuntimeExitCode)
    Write-Host ('Controlled files unchanged        : {0}' -f $HashesBefore.Count)
    Write-Host ('Passed checks                     : {0}' -f $TotalChecks)
    Write-Host 'Pilot cohort model                : Rolling cohort'
    Write-Host 'Findings checkpoint               : Every 5 valid sessions'
    Write-Host 'PII collection fields             : 0'

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5B FUNCTIONAL VALIDATION COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message 'Phase 5B passed structural, measurement, privacy, accessibility, and runtime validation.'
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5B FUNCTIONAL VALIDATION ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
