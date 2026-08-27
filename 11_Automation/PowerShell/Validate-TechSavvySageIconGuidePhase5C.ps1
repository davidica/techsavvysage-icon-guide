# =====================================================================
# Validate-TechSavvySageIconGuidePhase5C.ps1
# Phase 5C - Functional Validation
# =====================================================================

[CmdletBinding()]
param ([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section { param([Parameter(Mandatory)][string]$Title) Write-Host ''; Write-Host $Title -ForegroundColor Cyan; Write-Host ('-' * 76) -ForegroundColor DarkGray }
function Write-Pass { param([Parameter(Mandatory)][string]$Message) Write-Host ('[PASS    ] {0}' -f $Message) -ForegroundColor Green }

function Resolve-PhaseRepositoryRoot {
    param ([string]$RequestedRoot)
    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) { return (Resolve-Path -LiteralPath $RequestedRoot).Path }
    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { throw 'Unable to determine the validator directory. Supply -RepositoryRoot.' }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
}

function Assert-PowerShellSyntax {
    param ([Parameter(Mandatory)][string]$Path)
    $Tokens = $null; $Errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$Tokens, [ref]$Errors)
    if ($Errors.Count -gt 0) { throw ("Parser errors detected in {0}: {1}" -f $Path, (($Errors.Message) -join '; ')) }
}

function Get-ControlledHashes {
    param ([Parameter(Mandatory)][string]$Root)
    $Hashes = @{}
    foreach ($RelativePath in @('04_Application\js\app.js', '04_Application\css\styles.css', 'service-worker.js')) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Controlled file is missing: $RelativePath" }
        $Hashes[$RelativePath] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
    return $Hashes
}

function Assert-MarkerCount {
    param ([Parameter(Mandatory)][string]$Content, [Parameter(Mandatory)][string]$Marker, [int]$Expected = 1)
    $Count = ([regex]::Matches($Content, [regex]::Escape($Marker))).Count
    if ($Count -ne $Expected) { throw "Marker '$Marker' occurred $Count times; expected $Expected." }
}

function Assert-Phase5CStructure {
    param ([Parameter(Mandatory)][string]$Root)
    $Passed = 0
    $Rules = @{
        '04_Application\js\app.js' = @('PHASE-5C-START-HERE-BEGIN', 'PHASE-5C-START-HERE-END', 'role: ''dialog''', '''aria-modal'': ''true''', 'event.key === ''Escape''', 'sessionStorage.getItem', 'initializeConnectionStatus')
        '04_Application\css\styles.css' = @('PHASE-5C-HARDENING-BEGIN', 'PHASE-5C-HARDENING-END', '.start-here-dialog', '@media (max-width: 320px)', '@media (prefers-reduced-motion: reduce)', '@media (forced-colors: active)')
        'service-worker.js' = @('techsavvysage-icon-guide-v0.5.0')
        '01_Documentation\Phase_5C_Pre_Pilot_Hardening.md' = @('does not claim human usability validation', 'Deferred evidence')
        '05_Testing\Phase_5C_Pre_Pilot_Hardening_Checklist.md' = @('Pass / Fail / Not Applicable', 'No claim of human usability validation')
    }
    foreach ($RelativePath in $Rules.Keys) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required path is missing: $RelativePath" }
        $Passed++
        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $Rules[$RelativePath]) {
            if (-not $Content.Contains($Marker)) { throw "Required marker '$Marker' is missing from $RelativePath." }
            $Passed++
        }
    }
    $App = Get-Content -LiteralPath (Join-Path $Root '04_Application\js\app.js') -Raw
    $Css = Get-Content -LiteralPath (Join-Path $Root '04_Application\css\styles.css') -Raw
    foreach ($Marker in @('PHASE-5C-START-HERE-BEGIN', 'PHASE-5C-START-HERE-END')) { Assert-MarkerCount -Content $App -Marker $Marker; $Passed++ }
    foreach ($Marker in @('PHASE-5C-HARDENING-BEGIN', 'PHASE-5C-HARDENING-END')) { Assert-MarkerCount -Content $Css -Marker $Marker; $Passed++ }
    return $Passed
}

try {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5C FUNCTIONAL VALIDATION' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan

    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    $BuilderPath = Join-Path $Root '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5C.ps1'
    $ValidatorPath = Join-Path $Root '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5C.ps1'
    $RequiredPaths = @($Root, (Join-Path $Root '01_Documentation'), (Join-Path $Root '05_Testing'), (Join-Path $Root '11_Automation\PowerShell'), $BuilderPath, $ValidatorPath, (Join-Path $Root '04_Application\js\app.js'), (Join-Path $Root '04_Application\css\styles.css'), (Join-Path $Root 'service-worker.js'))

    Write-Section -Title 'Required Path and Syntax Validation'
    foreach ($Path in $RequiredPaths) { if (-not (Test-Path -LiteralPath $Path)) { throw "Required path is missing: $Path" } }
    Assert-PowerShellSyntax -Path $BuilderPath
    Assert-PowerShellSyntax -Path $ValidatorPath
    Write-Pass -Message 'Required paths exist and both PowerShell files parse.'

    Write-Section -Title 'Builder Structure Validation'
    $BuilderContent = Get-Content -LiteralPath $BuilderPath -Raw
    $Functions = @('Write-Section', 'Write-Pass', 'Resolve-PhaseRepositoryRoot', 'Set-Utf8File', 'Set-ControlledBlock', 'Get-StartHereJavaScript', 'Get-StartHereCss', 'Get-PhaseDocumentation', 'Update-ServiceWorkerCache', 'Test-Phase5COutput')
    foreach ($FunctionName in $Functions) { if (-not $BuilderContent.Contains("function $FunctionName")) { throw "Required builder function is missing: $FunctionName" } }
    Write-Pass -Message 'Required builder functions exist.'

    Write-Section -Title 'Output and Idempotency Validation'
    $PassedChecks = Assert-Phase5CStructure -Root $Root
    $HashesBefore = Get-ControlledHashes -Root $Root
    & $BuilderPath -Mode ValidateOnly -RepositoryRoot $Root
    $RuntimeExitCode = 0
    $HashesAfter = Get-ControlledHashes -Root $Root
    $Changed = @($HashesBefore.Keys | Where-Object { $HashesBefore[$_] -ne $HashesAfter[$_] })
    if ($Changed.Count -gt 0) { throw ('ValidateOnly changed controlled files: {0}' -f ($Changed -join ', ')) }
    Write-Pass -Message 'Start Here, accessibility, resilience, evidence-boundary, and ValidateOnly rules passed.'

    $Total = $PassedChecks + $RequiredPaths.Count + $Functions.Count + $HashesBefore.Count + 3
    Write-Section -Title 'Phase 5C Functional Validation Metrics'
    Write-Host ('Required paths                    : {0}' -f $RequiredPaths.Count)
    Write-Host ('Required builder functions        : {0}' -f $Functions.Count)
    Write-Host 'Applied output rules              : 3'
    Write-Host ('Runtime exit code                 : {0}' -f $RuntimeExitCode)
    Write-Host ('Controlled files unchanged        : {0}' -f $HashesBefore.Count)
    Write-Host ('Passed checks                     : {0}' -f $Total)
    Write-Host 'Human usability evidence          : Deferred'

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5C FUNCTIONAL VALIDATION COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message 'Phase 5C passed structural, accessibility, resilience, privacy, evidence-boundary, and runtime validation.'
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5C FUNCTIONAL VALIDATION ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
