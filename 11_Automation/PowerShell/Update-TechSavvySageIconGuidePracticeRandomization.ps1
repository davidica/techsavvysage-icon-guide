# ============================================================================
# Update-TechSavvySageIconGuidePracticeRandomization.ps1
# ============================================================================

[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [ValidateSet('Update', 'ValidateOnly')]
    [string]$OperatingMode = 'Update',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:UpdatedFiles = 0
$Script:UnchangedFiles = 0
$Script:ValidatedFiles = 0

function Write-Banner {
    param ([Parameter(Mandatory)][string]$Text)

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
}

function Write-Status {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'UPDATE', 'EXISTS', 'VALIDATE', 'PASS', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'UPDATE'   { 'Yellow' }
        'VALIDATE' { 'Cyan' }
        'PASS'     { 'Green' }
        'FAIL'     { 'Red' }
        default    { 'Gray' }
    }

    Write-Host ('[{0,-8}] {1}' -f $Level, $Message) -ForegroundColor $Color
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

    throw 'Place this update script in the repository root or 11_Automation\PowerShell, or provide -RepositoryRoot.'
}

function Update-RequiredText {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText
    )

    $Content = Get-Content -LiteralPath $Path -Raw

    if ($Content.Contains($NewText)) {
        return $false
    }

    if (-not $Content.Contains($OldText)) {
        throw "The expected update marker was not found in: $Path"
    }

    $UpdatedContent = $Content.Replace($OldText, $NewText)
    Set-Content -LiteralPath $Path -Value $UpdatedContent -Encoding UTF8 -Force
    return $true
}

function Invoke-TextUpdate {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText
    )

    if (Update-RequiredText -Path $Path -OldText $OldText -NewText $NewText) {
        $Script:UpdatedFiles++
        Write-Status -Level 'UPDATE' -Message $Path
    }
    else {
        $Script:UnchangedFiles++
        Write-Status -Level 'EXISTS' -Message "Update already present: $Path"
    }
}

try {
    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PRACTICE RANDOMIZATION UPDATE'

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the update script directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    $AppScriptPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $BuilderPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase1.ps1'

    foreach ($RequiredPath in @($AppScriptPath, $ServiceWorkerPath, $BuilderPath)) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "Required Phase 1 file is missing: $RequiredPath"
        }
    }

    $OldFindIconBlock = @'
    function findIcon(id) {
        return state.icons.find(function (icon) {
            return icon.id === id;
        });
    }
'@

    $NewFindIconBlock = @'
    function findIcon(id) {
        return state.icons.find(function (icon) {
            return icon.id === id;
        });
    }

    function shufflePracticeOrder(iconIds) {
        const shuffledIds = iconIds.slice();

        for (let currentIndex = shuffledIds.length - 1; currentIndex > 0; currentIndex -= 1) {
            const randomIndex = Math.floor(Math.random() * (currentIndex + 1));
            const currentValue = shuffledIds[currentIndex];
            shuffledIds[currentIndex] = shuffledIds[randomIndex];
            shuffledIds[randomIndex] = currentValue;
        }

        return shuffledIds;
    }
'@

    $OldPracticeOrderBlock = @'
            state.practiceOrder = state.icons.map(function (icon) {
                return icon.id;
            });
'@

    $NewPracticeOrderBlock = @'
            state.practiceOrder = shufflePracticeOrder(state.icons.map(function (icon) {
                return icon.id;
            }));
'@

    if ($OperatingMode -eq 'Update') {
        if (-not $Force) {
            throw 'Run Update mode with -Force after confirming the Phase 1 build completed successfully.'
        }

        Invoke-TextUpdate -Path $AppScriptPath -OldText $OldFindIconBlock -NewText $NewFindIconBlock
        Invoke-TextUpdate -Path $AppScriptPath -OldText $OldPracticeOrderBlock -NewText $NewPracticeOrderBlock
        Invoke-TextUpdate `
            -Path $ServiceWorkerPath `
            -OldText "const CACHE_NAME = 'techsavvysage-icon-guide-v0.1.0';" `
            -NewText "const CACHE_NAME = 'techsavvysage-icon-guide-v0.1.1';"

        Invoke-TextUpdate -Path $BuilderPath -OldText $OldFindIconBlock -NewText $NewFindIconBlock
        Invoke-TextUpdate -Path $BuilderPath -OldText $OldPracticeOrderBlock -NewText $NewPracticeOrderBlock
        Invoke-TextUpdate `
            -Path $BuilderPath `
            -OldText "`$Script:UtilityVersion = '0.1.0'" `
            -NewText "`$Script:UtilityVersion = '0.1.1'"
        Invoke-TextUpdate `
            -Path $BuilderPath `
            -OldText "const CACHE_NAME = 'techsavvysage-icon-guide-v0.1.0';" `
            -NewText "const CACHE_NAME = 'techsavvysage-icon-guide-v0.1.1';"

        $CanonicalUpdatePath = Join-Path `
            $ResolvedRepositoryRoot `
            '11_Automation\PowerShell\Update-TechSavvySageIconGuidePracticeRandomization.ps1'

        $CurrentScriptPath = Get-NormalizedPath -Path $MyInvocation.MyCommand.Path

        if ($CurrentScriptPath -ne (Get-NormalizedPath -Path $CanonicalUpdatePath)) {
            Copy-Item -LiteralPath $CurrentScriptPath -Destination $CanonicalUpdatePath -Force
            Write-Status -Level 'UPDATE' -Message $CanonicalUpdatePath
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    $ValidationRules = @(
        @{ Path = $AppScriptPath; Marker = 'function shufflePracticeOrder(iconIds)' },
        @{ Path = $AppScriptPath; Marker = 'state.practiceOrder = shufflePracticeOrder' },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.1.1" },
        @{ Path = $BuilderPath; Marker = "`$Script:UtilityVersion = '0.1.1'" },
        @{ Path = $BuilderPath; Marker = 'function shufflePracticeOrder(iconIds)' },
        @{ Path = $BuilderPath; Marker = 'state.practiceOrder = shufflePracticeOrder' }
    )

    foreach ($Rule in $ValidationRules) {
        Write-Status -Level 'VALIDATE' -Message ("{0} :: {1}" -f $Rule.Path, $Rule.Marker)
        $Content = Get-Content -LiteralPath $Rule.Path -Raw

        if (-not $Content.Contains($Rule.Marker)) {
            Write-Status -Level 'FAIL' -Message 'Required randomization marker was not detected.'
            throw 'Practice randomization validation failed.'
        }

        $Script:ValidatedFiles++
        Write-Status -Level 'PASS' -Message 'Required randomization marker detected.'
    }

    Write-Host ''
    Write-Host 'Execution Metrics' -ForegroundColor Cyan
    Write-Host ('-' * 76) -ForegroundColor DarkGray
    Write-Host ('{0,-28}: {1}' -f 'Updated file operations', $Script:UpdatedFiles)
    Write-Host ('{0,-28}: {1}' -f 'Existing updates', $Script:UnchangedFiles)
    Write-Host ('{0,-28}: {1}' -f 'Validated markers', $Script:ValidatedFiles)

    Write-Banner -Text 'PRACTICE RANDOMIZATION UPDATE COMPLETE'
    Write-Status -Level 'PASS' -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE PRACTICE RANDOMIZATION UPDATE ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
