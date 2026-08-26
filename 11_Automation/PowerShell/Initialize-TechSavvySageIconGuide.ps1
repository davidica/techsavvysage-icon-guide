# ============================================================================
# Initialize-TechSavvySageIconGuide.ps1
# ============================================================================

[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [ValidateSet(
        'Initialize',
        'ValidateOnly'
    )]
    [string]$OperatingMode = 'Initialize',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:UtilityName = 'TechSavvySage Icon Guide Repository Initializer'
$Script:UtilityVersion = '1.0.0'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:LogFile = $null

$Script:Metrics = [ordered]@{
    CreatedFolders = 0
    ExistingFolders = 0
    CreatedFiles   = 0
    ReplacedFiles  = 0
    ExistingFiles  = 0
    ValidatedPaths = 0
    MissingPaths   = 0
}

function Write-Banner {
    param (
        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
}

function Write-Section {
    param (
        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('-' * 76) -ForegroundColor DarkGray
}

function Write-Status {
    param (
        [Parameter(Mandatory)]
        [ValidateSet(
            'INFO',
            'CREATE',
            'EXISTS',
            'REPLACE',
            'VALIDATE',
            'PASS',
            'WARN',
            'FAIL'
        )]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $Color = 'Gray'

    switch ($Level) {
        'INFO'     { $Color = 'Gray' }
        'CREATE'   { $Color = 'Green' }
        'EXISTS'   { $Color = 'DarkGray' }
        'REPLACE'  { $Color = 'Yellow' }
        'VALIDATE' { $Color = 'Cyan' }
        'PASS'     { $Color = 'Green' }
        'WARN'     { $Color = 'Yellow' }
        'FAIL'     { $Color = 'Red' }
    }

    $Line = '[{0,-8}] {1}' -f $Level, $Message
    Write-Host $Line -ForegroundColor $Color

    if (-not [string]::IsNullOrWhiteSpace($Script:LogFile)) {
        Add-Content `
            -LiteralPath $Script:LogFile `
            -Value ('{0:u} {1}' -f (Get-Date), $Line) `
            -Encoding UTF8
    }
}

function Write-Metric {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Value
    )

    Write-Host ('{0,-28}: {1}' -f $Name, $Value)
}

function Get-NormalizedPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-RepositoryRoot {
    param (
        [string]$ExplicitRepositoryRoot,

        [Parameter(Mandatory)]
        [string]$ScriptRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepositoryRoot)) {
        return Get-NormalizedPath -Path $ExplicitRepositoryRoot
    }

    $NormalizedScriptRoot = Get-NormalizedPath -Path $ScriptRoot
    $ScriptRootName = Split-Path -Path $NormalizedScriptRoot -Leaf

    if ($ScriptRootName -ieq $Script:ExpectedRepositoryName) {
        return $NormalizedScriptRoot
    }

    if ($ScriptRootName -ieq 'PowerShell') {
        $AutomationRoot = Split-Path -Path $NormalizedScriptRoot -Parent
        $AutomationRootName = Split-Path -Path $AutomationRoot -Leaf

        if ($AutomationRootName -ieq '11_Automation') {
            return Split-Path -Path $AutomationRoot -Parent
        }
    }

    $CurrentPath = $NormalizedScriptRoot

    while (-not [string]::IsNullOrWhiteSpace($CurrentPath)) {
        $CurrentName = Split-Path -Path $CurrentPath -Leaf
        $GitPath = Join-Path -Path $CurrentPath -ChildPath '.git'

        if (
            ($CurrentName -ieq $Script:ExpectedRepositoryName) -and
            (Test-Path -LiteralPath $GitPath)
        ) {
            return $CurrentPath
        }

        $ParentPath = Split-Path -Path $CurrentPath -Parent

        if (
            [string]::IsNullOrWhiteSpace($ParentPath) -or
            ($ParentPath -eq $CurrentPath)
        ) {
            break
        }

        $CurrentPath = $ParentPath
    }

    throw @'
Unable to determine the repository root automatically.

Place this initializer in either:
  1. The techsavvysage-icon-guide repository root; or
  2. 11_Automation\PowerShell inside the repository.

You may also provide -RepositoryRoot with the full repository path.
'@
}

function Initialize-LogFile {
    param (
        [Parameter(Mandatory)]
        [string]$LogRoot
    )

    if (-not (Test-Path -LiteralPath $LogRoot)) {
        New-Item `
            -ItemType Directory `
            -Path $LogRoot `
            -Force | Out-Null

        $Script:Metrics.CreatedFolders++
    }

    $Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $Script:LogFile = Join-Path `
        -Path $LogRoot `
        -ChildPath ('Initialize-TechSavvySageIconGuide_{0}.log' -f $Timestamp)

    New-Item `
        -ItemType File `
        -Path $Script:LogFile `
        -Force | Out-Null
}

function Ensure-Directory {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        $Script:Metrics.ExistingFolders++
        Write-Status -Level 'EXISTS' -Message $Path
        return
    }

    New-Item `
        -ItemType Directory `
        -Path $Path `
        -Force | Out-Null

    $Script:Metrics.CreatedFolders++
    Write-Status -Level 'CREATE' -Message $Path
}

function Write-ControlledFile {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content,

        [switch]$Replace
    )

    $ParentPath = Split-Path -Path $Path -Parent

    if (-not (Test-Path -LiteralPath $ParentPath -PathType Container)) {
        throw "The parent directory does not exist: $ParentPath"
    }

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        if (-not $Replace) {
            $Script:Metrics.ExistingFiles++
            Write-Status -Level 'EXISTS' -Message $Path
            return
        }

        Set-Content `
            -LiteralPath $Path `
            -Value $Content `
            -Encoding UTF8 `
            -Force

        $Script:Metrics.ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
        return
    }

    Set-Content `
        -LiteralPath $Path `
        -Value $Content `
        -Encoding UTF8

    $Script:Metrics.CreatedFiles++
    Write-Status -Level 'CREATE' -Message $Path
}

function Test-RequiredPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Container',
            'Leaf'
        )]
        [string]$PathType
    )

    Write-Status -Level 'VALIDATE' -Message $Path

    if (Test-Path -LiteralPath $Path -PathType $PathType) {
        $Script:Metrics.ValidatedPaths++
        Write-Status -Level 'PASS' -Message $Path
        return $true
    }

    $Script:Metrics.MissingPaths++
    Write-Status -Level 'FAIL' -Message $Path
    return $false
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the initializer script directory.'
    }

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    $ScriptRoot = Get-NormalizedPath -Path $PSScriptRoot
    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $ScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "The repository root does not exist: $ResolvedRepositoryRoot"
    }

    $AutomationRoot = Join-Path `
        -Path $ResolvedRepositoryRoot `
        -ChildPath '11_Automation'

    $PowerShellRoot = Join-Path `
        -Path $AutomationRoot `
        -ChildPath 'PowerShell'

    $LogRoot = Join-Path `
        -Path $AutomationRoot `
        -ChildPath 'Logs'

    if ($OperatingMode -eq 'Initialize') {
        Initialize-LogFile -LogRoot $LogRoot
    }

    Write-Section -Text 'Execution Configuration'
    Write-Metric -Name 'Utility' -Value $Script:UtilityName
    Write-Metric -Name 'Version' -Value $Script:UtilityVersion
    Write-Metric -Name 'PowerShell version' -Value $PSVersionTable.PSVersion
    Write-Metric -Name 'Operating mode' -Value $OperatingMode
    Write-Metric -Name 'Force enabled' -Value ([bool]$Force)
    Write-Metric -Name 'Script root' -Value $ScriptRoot
    Write-Metric -Name 'Repository root' -Value $ResolvedRepositoryRoot
    Write-Metric -Name 'Automation root' -Value $AutomationRoot
    Write-Metric -Name 'PowerShell root' -Value $PowerShellRoot
    Write-Metric -Name 'Log root' -Value $LogRoot

    if (-not [string]::IsNullOrWhiteSpace($Script:LogFile)) {
        Write-Metric -Name 'Log file' -Value $Script:LogFile
    }

    $RelativeDirectories = @(
        '00_Project_Management',
        '01_Documentation',
        '02_Product_Management',
        '03_Architecture',
        '04_Application',
        '04_Application\assets',
        '04_Application\assets\branding',
        '04_Application\assets\icons',
        '04_Application\css',
        '04_Application\data',
        '04_Application\js',
        '05_Testing',
        '06_Deployment',
        '11_Automation',
        '11_Automation\Documentation',
        '11_Automation\Logs',
        '11_Automation\PowerShell',
        '12_Audit_and_History',
        '12_Audit_and_History\01_Execution_Logs',
        '12_Audit_and_History\02_Run_History',
        '12_Audit_and_History\03_Change_History',
        '12_Audit_and_History\04_Generated_Reports'
    )

    $ApplicationFiles = [ordered]@{
        'index.html' = @'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Accessible learning utility for understanding commonly used computer and mobile icons.">
    <meta name="theme-color" content="#6E8B74">
    <title>TechSavvySage Icon Guide</title>
    <link rel="manifest" href="manifest.webmanifest">
    <link rel="stylesheet" href="04_Application/css/styles.css">
</head>
<body>
    <main id="app" tabindex="-1">
        <h1>TechSavvySage Icon Guide</h1>
        <p>A DapThatApp Learning Utility</p>
        <p>The accessible learning experience will be initialized here.</p>
    </main>

    <script src="04_Application/js/app.js"></script>
</body>
</html>
'@

        '04_Application\css\styles.css' = @'
:root {
    color-scheme: light;
    --sage: #6E8B74;
    --warm-gray: #F3F1ED;
    --ink: #1F2923;
    --surface: #FFFFFF;
    --focus: #1F5A85;
}

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    background: var(--warm-gray);
    color: var(--ink);
    font-family: Arial, Helvetica, sans-serif;
    font-size: 1.125rem;
    line-height: 1.6;
}

main {
    width: min(72rem, 100%);
    margin: 0 auto;
    padding: 2rem 1.25rem;
}

a,
button,
input,
select {
    font: inherit;
}

:focus-visible {
    outline: 0.2rem solid var(--focus);
    outline-offset: 0.2rem;
}

@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        scroll-behavior: auto !important;
        transition-duration: 0.01ms !important;
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
    }
}
'@

        '04_Application\js\app.js' = @'
'use strict';

document.addEventListener('DOMContentLoaded', function () {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('service-worker.js').catch(function () {
            // The utility remains functional if offline support is unavailable.
        });
    }
});
'@

        '04_Application\data\icons.json' = @'
{
    "schema_version": "1.0.0",
    "utility": "TechSavvySage Icon Guide",
    "icons": []
}
'@

        'manifest.webmanifest' = @'
{
    "name": "TechSavvySage Icon Guide",
    "short_name": "Icon Guide",
    "description": "Accessible learning utility for understanding commonly used computer and mobile icons.",
    "start_url": "./",
    "scope": "./",
    "display": "standalone",
    "background_color": "#F3F1ED",
    "theme_color": "#6E8B74",
    "lang": "en-US",
    "icons": []
}
'@

        'service-worker.js' = @'
'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v1';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/app.js',
    './04_Application/data/icons.json'
];

self.addEventListener('install', function (event) {
    event.waitUntil(
        caches.open(CACHE_NAME).then(function (cache) {
            return cache.addAll(CORE_ASSETS);
        })
    );
});

self.addEventListener('activate', function (event) {
    event.waitUntil(
        caches.keys().then(function (cacheNames) {
            return Promise.all(
                cacheNames
                    .filter(function (cacheName) {
                        return cacheName !== CACHE_NAME;
                    })
                    .map(function (cacheName) {
                        return caches.delete(cacheName);
                    })
            );
        })
    );
});

self.addEventListener('fetch', function (event) {
    if (event.request.method !== 'GET') {
        return;
    }

    event.respondWith(
        caches.match(event.request).then(function (cachedResponse) {
            return cachedResponse || fetch(event.request);
        })
    );
});
'@
    }

    $GovernanceFiles = [ordered]@{
        'README.md' = @'
# TechSavvySage Icon Guide

An accessible learning utility for understanding commonly used computer and mobile icons.

## Product identity

- Parent organization: TechSavvySage
- Product line: DapThatApp
- Utility: TechSavvySage Icon Guide
- Audience: adults 50+ and people with varied learning needs

## Design principles

- Large, readable text
- High contrast
- Plain language
- Keyboard and screen-reader support
- Touch-friendly controls
- Untimed, judgment-free practice
- Reduced motion support
- No personally identifiable information

## Repository initialization

Initialize the repository:

```powershell
.\Initialize-TechSavvySageIconGuide.ps1 `
    -OperatingMode Initialize
```

Validate an existing repository:

```powershell
.\11_Automation\PowerShell\Initialize-TechSavvySageIconGuide.ps1 `
    -OperatingMode ValidateOnly
```

Use `-Force` only when the controlled starter files should be replaced.
'@

        '.gitignore' = @'
# Operating-system files
.DS_Store
Thumbs.db

# Editor settings
.vscode/
.idea/

# Local logs and temporary files
*.tmp
*.bak
11_Automation/Logs/*.log

# Local dependency folders
node_modules/
'@

        '00_Project_Management\README.md' = @'
# Project Management

Project charter, roadmap, sprint plans, status reports, risks, decisions, and lessons learned.
'@

        '01_Documentation\README.md' = @'
# Documentation

User guides, facilitator guides, content standards, accessibility guidance, and release notes.
'@

        '02_Product_Management\README.md' = @'
# Product Management

Product vision, audience needs, feature backlog, learning outcomes, and acceptance criteria.
'@

        '03_Architecture\README.md' = @'
# Architecture

Solution architecture, data model, component design, privacy decisions, and integration guidance.
'@

        '05_Testing\README.md' = @'
# Testing

Functional, accessibility, usability, browser, device, and workshop-pilot test materials.
'@

        '06_Deployment\README.md' = @'
# Deployment

GitHub Pages, domain, release, rollback, cache, and production verification procedures.
'@

        '11_Automation\Documentation\README.md' = @'
# Automation Documentation

Instructions and operating notes for repository automation and validation utilities.
'@

        '12_Audit_and_History\README.md' = @'
# Audit and History

Execution logs, run history, change history, and generated validation reports.
'@
    }

    Write-Section -Text 'Phase 1 - Repository Directories'

    if ($OperatingMode -eq 'Initialize') {
        foreach ($RelativeDirectory in $RelativeDirectories) {
            $DirectoryPath = Join-Path `
                -Path $ResolvedRepositoryRoot `
                -ChildPath $RelativeDirectory

            Ensure-Directory -Path $DirectoryPath
        }
    }
    else {
        Write-Status `
            -Level 'INFO' `
            -Message 'ValidateOnly mode selected. Directory creation was skipped.'
    }

    Write-Section -Text 'Phase 2 - Accessible Application Baseline'

    if ($OperatingMode -eq 'Initialize') {
        foreach ($RelativeFilePath in $ApplicationFiles.Keys) {
            $FilePath = Join-Path `
                -Path $ResolvedRepositoryRoot `
                -ChildPath $RelativeFilePath

            Write-ControlledFile `
                -Path $FilePath `
                -Content $ApplicationFiles[$RelativeFilePath] `
                -Replace:$Force
        }
    }
    else {
        Write-Status `
            -Level 'INFO' `
            -Message 'ValidateOnly mode selected. Application file generation was skipped.'
    }

    Write-Section -Text 'Phase 3 - Governance and Documentation Baseline'

    if ($OperatingMode -eq 'Initialize') {
        foreach ($RelativeFilePath in $GovernanceFiles.Keys) {
            $FilePath = Join-Path `
                -Path $ResolvedRepositoryRoot `
                -ChildPath $RelativeFilePath

            Write-ControlledFile `
                -Path $FilePath `
                -Content $GovernanceFiles[$RelativeFilePath] `
                -Replace:$Force
        }

        $CanonicalInitializerPath = Join-Path `
            -Path $PowerShellRoot `
            -ChildPath 'Initialize-TechSavvySageIconGuide.ps1'

        $CurrentScriptPath = $MyInvocation.MyCommand.Path

        if (
            -not [string]::IsNullOrWhiteSpace($CurrentScriptPath) -and
            ((Get-NormalizedPath -Path $CurrentScriptPath) -ne
                (Get-NormalizedPath -Path $CanonicalInitializerPath))
        ) {
            $CanonicalInitializerExists = Test-Path `
                -LiteralPath $CanonicalInitializerPath `
                -PathType Leaf

            if (
                (-not $CanonicalInitializerExists) -or
                $Force
            ) {
                Copy-Item `
                    -LiteralPath $CurrentScriptPath `
                    -Destination $CanonicalInitializerPath `
                    -Force:$Force

                if ($CanonicalInitializerExists) {
                    $Script:Metrics.ReplacedFiles++
                    Write-Status `
                        -Level 'REPLACE' `
                        -Message $CanonicalInitializerPath
                }
                else {
                    $Script:Metrics.CreatedFiles++
                    Write-Status `
                        -Level 'CREATE' `
                        -Message $CanonicalInitializerPath
                }
            }
            else {
                $Script:Metrics.ExistingFiles++
                Write-Status `
                    -Level 'EXISTS' `
                    -Message $CanonicalInitializerPath
            }
        }
    }
    else {
        Write-Status `
            -Level 'INFO' `
            -Message 'ValidateOnly mode selected. Governance file generation was skipped.'
    }

    Write-Section -Text 'Phase 4 - Repository Validation'

    $ValidationSucceeded = $true

    foreach ($RelativeDirectory in $RelativeDirectories) {
        $DirectoryPath = Join-Path `
            -Path $ResolvedRepositoryRoot `
            -ChildPath $RelativeDirectory

        if (-not (Test-RequiredPath -Path $DirectoryPath -PathType 'Container')) {
            $ValidationSucceeded = $false
        }
    }

    $RequiredFiles = @(
        $ApplicationFiles.Keys
        $GovernanceFiles.Keys
        '11_Automation\PowerShell\Initialize-TechSavvySageIconGuide.ps1'
    )

    foreach ($RelativeFilePath in $RequiredFiles) {
        $FilePath = Join-Path `
            -Path $ResolvedRepositoryRoot `
            -ChildPath $RelativeFilePath

        if (-not (Test-RequiredPath -Path $FilePath -PathType 'Leaf')) {
            $ValidationSucceeded = $false
        }
    }

    $IconsDataPath = Join-Path `
        -Path $ResolvedRepositoryRoot `
        -ChildPath '04_Application\data\icons.json'

    $ManifestPath = Join-Path `
        -Path $ResolvedRepositoryRoot `
        -ChildPath 'manifest.webmanifest'

    if (Test-Path -LiteralPath $IconsDataPath -PathType Leaf) {
        Get-Content `
            -LiteralPath $IconsDataPath `
            -Raw | ConvertFrom-Json | Out-Null

        Write-Status `
            -Level 'PASS' `
            -Message 'Icon data JSON is syntactically valid.'
    }

    if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
        Get-Content `
            -LiteralPath $ManifestPath `
            -Raw | ConvertFrom-Json | Out-Null

        Write-Status `
            -Level 'PASS' `
            -Message 'Web application manifest is syntactically valid.'
    }

    $GitRoot = Join-Path `
        -Path $ResolvedRepositoryRoot `
        -ChildPath '.git'

    if (Test-Path -LiteralPath $GitRoot) {
        Write-Status `
            -Level 'PASS' `
            -Message 'Git repository metadata was detected.'
    }
    else {
        Write-Status `
            -Level 'WARN' `
            -Message 'Git repository metadata was not detected. Clone or initialize the repository before publishing.'
    }

    Write-Section -Text 'Execution Metrics'
    Write-Metric -Name 'Created folders' -Value $Script:Metrics.CreatedFolders
    Write-Metric -Name 'Existing folders' -Value $Script:Metrics.ExistingFolders
    Write-Metric -Name 'Created files' -Value $Script:Metrics.CreatedFiles
    Write-Metric -Name 'Replaced files' -Value $Script:Metrics.ReplacedFiles
    Write-Metric -Name 'Existing files' -Value $Script:Metrics.ExistingFiles
    Write-Metric -Name 'Validated paths' -Value $Script:Metrics.ValidatedPaths
    Write-Metric -Name 'Missing paths' -Value $Script:Metrics.MissingPaths

    if (-not $ValidationSucceeded) {
        throw 'Repository validation failed. One or more required paths are missing.'
    }

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE INITIALIZATION COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    $ErrorCommand = $_.InvocationInfo.Line

    if ([string]::IsNullOrWhiteSpace($ErrorCommand)) {
        $ErrorCommand = $_.InvocationInfo.MyCommand.Name
    }

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE INITIALIZER ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ''
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ('Command     : {0}' -f $ErrorCommand.Trim()) -ForegroundColor Red
    Write-Host ''

    exit 1
}
