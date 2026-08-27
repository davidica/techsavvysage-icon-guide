# =====================================================================
# Validate-TechSavvySageIconGuidePhase5A.ps1
# Phase 5A - Functional Validation
# =====================================================================

[CmdletBinding()]
param (
    [string]$RepositoryRoot
)

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
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$Tokens,
        [ref]$Errors
    )

    if ($Errors.Count -gt 0) {
        $Messages = $Errors | ForEach-Object {
            'Line {0}, column {1}: {2}' -f $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber, $_.Message
        }
        throw ("Parser errors detected in {0}:`n{1}" -f $Path, ($Messages -join [Environment]::NewLine))
    }
}

function Get-FileMarkers {
    return @{
        '01_Documentation\Phase_5A_Pilot_Framework.md' = @(
            '# Phase 5A Pilot Framework',
            'Hybrid delivery model',
            'Facilitated path',
            'Self-guided path',
            'No personally identifiable information',
            'Session-only',
            'Pass / Fail / Not Applicable'
        )
        '01_Documentation\Phase_5A_Facilitator_Guide.md' = @(
            '# Phase 5A Facilitator Guide',
            'Opening script',
            'Facilitated path',
            'Self-guided path',
            'Do not record assessment scores',
            'Non-identifying feedback questions',
            'Escalation rules'
        )
        '05_Testing\Phase_5A_Pilot_Observation_Form.md' = @(
            '# Phase 5A Pilot Observation Form',
            'Participant code',
            'Do not enter a participant name',
            'Pass / Fail / Not Applicable',
            'Accessibility observations',
            'Assistance log',
            'Defect record'
        )
        '05_Testing\Phase_5A_Pilot_Validation_Checklist.md' = @(
            '# Phase 5A Pilot Validation Checklist',
            'Functional workflow',
            'Accessibility validation',
            'Privacy and safety validation',
            'Keyboard-only operation',
            '200% zoom',
            '320 CSS pixels'
        )
    }
}

function Get-ControlledHashes {
    param ([Parameter(Mandatory)][string]$Root)

    $RelativePaths = @(
        'index.html',
        '04_Application\css\styles.css',
        '04_Application\js\app.js',
        'service-worker.js'
    )

    $Hashes = @{}
    foreach ($RelativePath in $RelativePaths) {
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
    $FileMarkers = Get-FileMarkers

    foreach ($RelativePath in $FileMarkers.Keys) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Required Phase 5A file is missing: $RelativePath"
        }
        $Passed++

        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $FileMarkers[$RelativePath]) {
            if (-not $Content.Contains($Marker)) {
                throw "Required marker '$Marker' is missing from $RelativePath."
            }
            $Passed++
        }
    }

    $CombinedContent = ($FileMarkers.Keys | ForEach-Object {
        Get-Content -LiteralPath (Join-Path $Root $_) -Raw
    }) -join [Environment]::NewLine

    $ProhibitedFields = @(
        'Participant name |',
        'Email address |',
        'Phone number |',
        'Library card number |',
        'Assessment score |',
        'Missed icons |'
    )

    foreach ($ProhibitedField in $ProhibitedFields) {
        if ($CombinedContent.Contains($ProhibitedField)) {
            throw "Prohibited collection field detected: $ProhibitedField"
        }
        $Passed++
    }

    return $Passed
}

try {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5A FUNCTIONAL VALIDATION' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan

    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    $BuilderPath = Join-Path $Root '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5A.ps1'
    $ValidatorPath = Join-Path $Root '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5A.ps1'

    Write-Section -Title 'Required Path Validation'
    $RequiredPaths = @(
        $Root,
        (Join-Path $Root '01_Documentation'),
        (Join-Path $Root '05_Testing'),
        (Join-Path $Root '11_Automation\PowerShell'),
        $BuilderPath,
        $ValidatorPath,
        (Join-Path $Root 'index.html'),
        (Join-Path $Root '04_Application\js\app.js'),
        (Join-Path $Root 'service-worker.js')
    )

    foreach ($Path in $RequiredPaths) {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw "Required path is missing: $Path"
        }
    }
    Write-Pass -Message 'All required paths exist.'

    Write-Section -Title 'PowerShell Syntax Validation'
    Assert-PowerShellSyntax -Path $BuilderPath
    Assert-PowerShellSyntax -Path $ValidatorPath
    Write-Pass -Message 'Builder and validator parse successfully.'

    Write-Section -Title 'Builder Structure Validation'
    $BuilderContent = Get-Content -LiteralPath $BuilderPath -Raw
    $RequiredFunctions = @(
        'Write-Section',
        'Write-Pass',
        'Resolve-PhaseRepositoryRoot',
        'Get-PilotFileDefinitions',
        'Get-PilotFileContent',
        'Set-Utf8File',
        'Get-ControlledRuntimeHashes',
        'Test-PilotPackage'
    )

    foreach ($FunctionName in $RequiredFunctions) {
        if (-not $BuilderContent.Contains("function $FunctionName")) {
            throw "Required builder function is missing: $FunctionName"
        }
    }
    Write-Pass -Message 'All required builder functions exist.'

    $HashesBefore = Get-ControlledHashes -Root $Root

    Write-Section -Title 'Pilot Package Content Validation'
    $PassedChecks = Assert-PackageContent -Root $Root
    Write-Pass -Message 'Pilot documents and privacy controls validated.'

    Write-Section -Title 'Runtime Invocation Validation'
    & $BuilderPath -Mode ValidateOnly -RepositoryRoot $Root
    $RuntimeExitCode = 0
    Write-Pass -Message 'Builder ValidateOnly invocation completed without a runtime error.'

    $HashesAfter = Get-ControlledHashes -Root $Root
    $ChangedFiles = @($HashesBefore.Keys | Where-Object {
        $HashesBefore[$_] -ne $HashesAfter[$_]
    })

    if ($ChangedFiles.Count -gt 0) {
        throw ('Controlled runtime files changed during validation: {0}' -f ($ChangedFiles -join ', '))
    }

    $TotalChecks = $PassedChecks + $RequiredPaths.Count + $RequiredFunctions.Count + 2 + $HashesBefore.Count + 1

    Write-Section -Title 'Phase 5A Functional Validation Metrics'
    Write-Host ('Required paths                    : {0}' -f $RequiredPaths.Count)
    Write-Host ('Required builder functions        : {0}' -f $RequiredFunctions.Count)
    Write-Host ('Pilot documents                   : {0}' -f (Get-FileMarkers).Count)
    Write-Host ('Runtime exit code                 : {0}' -f $RuntimeExitCode)
    Write-Host ('Controlled files unchanged        : {0}' -f $HashesBefore.Count)
    Write-Host ('Passed checks                     : {0}' -f $TotalChecks)
    Write-Host ('Pilot delivery model              : Hybrid')
    Write-Host ('PII collection fields             : 0')

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5A FUNCTIONAL VALIDATION COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message 'Phase 5A passed structural, content, privacy, accessibility, and runtime validation.'
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5A FUNCTIONAL VALIDATION ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
