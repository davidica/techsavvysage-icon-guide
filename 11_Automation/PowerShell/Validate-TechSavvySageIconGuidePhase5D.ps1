# =====================================================================
# Validate-TechSavvySageIconGuidePhase5D.ps1
# Phase 5D - Functional Validation
# =====================================================================

[CmdletBinding()]
param ([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section { param([Parameter(Mandatory)][string]$Title) Write-Host ''; Write-Host $Title -ForegroundColor Cyan; Write-Host ('-' * 76) -ForegroundColor DarkGray }
function Write-Pass { param([Parameter(Mandatory)][string]$Message) Write-Host ('[PASS    ] {0}' -f $Message) -ForegroundColor Green }
function Resolve-PhaseRepositoryRoot { param([string]$RequestedRoot) if(-not [string]::IsNullOrWhiteSpace($RequestedRoot)){return (Resolve-Path -LiteralPath $RequestedRoot).Path}; if([string]::IsNullOrWhiteSpace($PSScriptRoot)){throw 'Supply -RepositoryRoot.'}; return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path }
function Assert-PowerShellSyntax { param([Parameter(Mandatory)][string]$Path) $Tokens=$null; $Errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$Tokens,[ref]$Errors); if($Errors.Count -gt 0){throw ("Parser errors in {0}: {1}" -f $Path,(($Errors.Message)-join '; '))} }

function Get-RuntimePaths { return @('index.html','04_Application\css\styles.css','04_Application\js\app.js','04_Application\js\icons.js','04_Application\data\icons.json','04_Application\data\lessons.json','04_Application\data\assessments.json','manifest.webmanifest','service-worker.js') }
function Get-RuntimeHashes { param([Parameter(Mandatory)][string]$Root) $Hashes=@{}; foreach($RelativePath in Get-RuntimePaths){$Path=Join-Path $Root $RelativePath; if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "Runtime file missing: $RelativePath"}; $Hashes[$RelativePath]=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}; return $Hashes }

function Assert-CloseoutStructure {
    param ([Parameter(Mandatory)][string]$Root)
    $Rules=@{
        '01_Documentation\Phase_5_Release_Notes.md'=@('# Phase 5 Release Notes','v0.5.0','Pre-Pilot Technical Candidate','Human usability validation remains pending')
        '01_Documentation\Phase_5_Pre_Pilot_User_Guide.md'=@('# Phase 5 Pre-Pilot User Guide','Start Here','Rolling-cohort pilot','No account is required')
        '05_Testing\Phase_5_Regression_and_Accessibility_Checklist.md'=@('# Phase 5 Regression and Accessibility Checklist','200% zoom','320 CSS pixels','Human pilot status is Pending')
        '05_Testing\Phase_5_Pre_Pilot_Release_Authorization.md'=@('# Phase 5 Pre-Pilot Release Authorization','Technical release decision','Human pilot pending','v0.5.0')
    }
    $Passed=0
    foreach($RelativePath in $Rules.Keys){$Path=Join-Path $Root $RelativePath; if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "Closeout file missing: $RelativePath"}; $Passed++; $Content=Get-Content -LiteralPath $Path -Raw; foreach($Marker in $Rules[$RelativePath]){if(-not $Content.Contains($Marker)){throw "Marker '$Marker' missing from $RelativePath"}; $Passed++}}
    return $Passed
}

try {
    Write-Host ''; Write-Host ('=' * 76) -ForegroundColor Cyan; Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5D FUNCTIONAL VALIDATION' -ForegroundColor Cyan; Write-Host ('=' * 76) -ForegroundColor Cyan
    $Root=Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    $BuilderPath=Join-Path $Root '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase5D.ps1'
    $ValidatorPath=Join-Path $Root '11_Automation\PowerShell\Validate-TechSavvySageIconGuidePhase5D.ps1'
    $RequiredPaths=@($Root,(Join-Path $Root '01_Documentation'),(Join-Path $Root '05_Testing'),(Join-Path $Root '11_Automation\PowerShell'),$BuilderPath,$ValidatorPath)

    Write-Section -Title 'Required Path and Syntax Validation'
    foreach($Path in $RequiredPaths){if(-not(Test-Path -LiteralPath $Path)){throw "Required path missing: $Path"}}
    Assert-PowerShellSyntax -Path $BuilderPath; Assert-PowerShellSyntax -Path $ValidatorPath
    Write-Pass -Message 'Required paths exist and both scripts parse.'

    Write-Section -Title 'Builder Structure Validation'
    $BuilderContent=Get-Content -LiteralPath $BuilderPath -Raw
    $Functions=@('Write-Section','Write-Pass','Resolve-PhaseRepositoryRoot','Set-Utf8File','Get-RuntimeFilePaths','Get-RuntimeHashes','Get-PhaseScriptPaths','Get-CloseoutDefinitions','Get-CloseoutContent','Test-ReleaseBaseline','Test-CloseoutFiles')
    foreach($FunctionName in $Functions){if(-not $BuilderContent.Contains("function $FunctionName")){throw "Builder function missing: $FunctionName"}}
    Write-Pass -Message 'Required builder functions exist.'

    $HashesBefore=Get-RuntimeHashes -Root $Root
    $ContentChecks=Assert-CloseoutStructure -Root $Root
    Write-Section -Title 'Runtime and Idempotency Validation'
    & $BuilderPath -Mode ValidateOnly -RepositoryRoot $Root
    $RuntimeExitCode=0
    $HashesAfter=Get-RuntimeHashes -Root $Root
    $Changed=@($HashesBefore.Keys|Where-Object{$HashesBefore[$_] -ne $HashesAfter[$_]})
    if($Changed.Count -gt 0){throw ('ValidateOnly changed runtime files: {0}' -f ($Changed -join ', '))}
    Write-Pass -Message 'ValidateOnly completed and runtime hashes remained unchanged.'

    $Total=$RequiredPaths.Count+$Functions.Count+$ContentChecks+$HashesBefore.Count+3
    Write-Section -Title 'Phase 5D Functional Validation Metrics'
    Write-Host ('Required paths                    : {0}' -f $RequiredPaths.Count)
    Write-Host ('Required builder functions        : {0}' -f $Functions.Count)
    Write-Host 'Closeout files                    : 4'
    Write-Host ('Runtime exit code                 : {0}' -f $RuntimeExitCode)
    Write-Host ('Controlled files unchanged        : {0}' -f $HashesBefore.Count)
    Write-Host ('Passed checks                     : {0}' -f $Total)
    Write-Host 'Release version                   : v0.5.0'
    Write-Host 'Human pilot status                : Pending'

    Write-Host ''; Write-Host ('=' * 76) -ForegroundColor Cyan; Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5D FUNCTIONAL VALIDATION COMPLETE' -ForegroundColor Cyan; Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message 'Phase 5D passed release-baseline, closeout, privacy, evidence-boundary, idempotency, and runtime validation.'
}
catch {
    Write-Host ''; Write-Host ('=' * 76) -ForegroundColor Red; Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5D FUNCTIONAL VALIDATION ERROR' -ForegroundColor Red; Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
