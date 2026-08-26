# ============================================================================
# Build-TechSavvySageIconGuidePhase1.ps1
# ============================================================================

[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [ValidateSet(
        'Build',
        'ValidateOnly'
    )]
    [string]$OperatingMode = 'Build',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 1 Builder'
$Script:UtilityVersion = '0.1.1'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:LogFile = $null
$Script:CreatedFiles = 0
$Script:ReplacedFiles = 0
$Script:ExistingFiles = 0
$Script:ValidatedFiles = 0
$Script:MissingFiles = 0

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
        [ValidateSet('INFO', 'CREATE', 'EXISTS', 'REPLACE', 'VALIDATE', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $Color = 'Gray'

    switch ($Level) {
        'CREATE'   { $Color = 'Green' }
        'REPLACE'  { $Color = 'Yellow' }
        'VALIDATE' { $Color = 'Cyan' }
        'PASS'     { $Color = 'Green' }
        'WARN'     { $Color = 'Yellow' }
        'FAIL'     { $Color = 'Red' }
        default    { $Color = 'Gray' }
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
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value
    )

    Write-Host ('{0,-28}: {1}' -f $Name, $Value)
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
    $ScriptRootName = Split-Path -Path $NormalizedScriptRoot -Leaf

    if ($ScriptRootName -ieq $Script:ExpectedRepositoryName) {
        return $NormalizedScriptRoot
    }

    if ($ScriptRootName -ieq 'PowerShell') {
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

function Initialize-LogFile {
    param ([Parameter(Mandatory)][string]$LogRoot)

    if (-not (Test-Path -LiteralPath $LogRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
    }

    $Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $Script:LogFile = Join-Path `
        -Path $LogRoot `
        -ChildPath ('Build-TechSavvySageIconGuidePhase1_{0}.log' -f $Timestamp)

    New-Item -ItemType File -Path $Script:LogFile -Force | Out-Null
}

function Write-ControlledFile {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        [switch]$Replace
    )

    $ParentPath = Split-Path -Path $Path -Parent

    if (-not (Test-Path -LiteralPath $ParentPath -PathType Container)) {
        throw "Required parent directory is missing: $ParentPath"
    }

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        if (-not $Replace) {
            $Script:ExistingFiles++
            Write-Status -Level 'EXISTS' -Message $Path
            return
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8 -Force
        $Script:ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
        return
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    $Script:CreatedFiles++
    Write-Status -Level 'CREATE' -Message $Path
}

function Test-RequiredFile {
    param ([Parameter(Mandatory)][string]$Path)

    Write-Status -Level 'VALIDATE' -Message $Path

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $Script:ValidatedFiles++
        Write-Status -Level 'PASS' -Message $Path
        return $true
    }

    $Script:MissingFiles++
    Write-Status -Level 'FAIL' -Message $Path
    return $false
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 1 builder directory.'
    }

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    $ScriptRoot = Get-NormalizedPath -Path $PSScriptRoot
    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $ScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $ResolvedRepositoryRoot"
    }

    $RequiredDirectories = @(
        '04_Application\css',
        '04_Application\data',
        '04_Application\js',
        '01_Documentation',
        '05_Testing',
        '11_Automation\Logs',
        '11_Automation\PowerShell'
    )

    foreach ($RelativeDirectory in $RequiredDirectories) {
        $DirectoryPath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath $RelativeDirectory

        if (-not (Test-Path -LiteralPath $DirectoryPath -PathType Container)) {
            throw "Repository baseline directory is missing: $DirectoryPath"
        }
    }

    $LogRoot = Join-Path -Path $ResolvedRepositoryRoot -ChildPath '11_Automation\Logs'

    if ($OperatingMode -eq 'Build') {
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

    if (-not [string]::IsNullOrWhiteSpace($Script:LogFile)) {
        Write-Metric -Name 'Log file' -Value $Script:LogFile
    }

    $Phase1Files = [ordered]@{
        'index.html' = @'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Learn the meanings of commonly used computer and phone icons through accessible, untimed practice.">
    <meta name="theme-color" content="#607D68">
    <title>TechSavvySage Icon Guide</title>
    <link rel="manifest" href="manifest.webmanifest">
    <link rel="stylesheet" href="04_Application/css/styles.css">
</head>
<body>
    <a class="skip-link" href="#main-content">Skip to the icon guide</a>

    <header class="site-header">
        <div class="header-inner">
            <div>
                <p class="eyebrow">TechSavvySage</p>
                <h1>Icon Guide</h1>
                <p class="tagline">A DapThatApp Learning Utility</p>
            </div>
            <p class="confidence-message">You’re not behind. You’re building.</p>
        </div>
    </header>

    <main id="main-content">
        <section class="introduction" aria-labelledby="intro-heading">
            <h2 id="intro-heading">Common icons, explained clearly</h2>
            <p>Select an icon to learn what it means, where you may see it, and when to pause before using it. There’s no rush.</p>
        </section>

        <nav class="mode-selector" aria-label="Learning mode">
            <button id="learn-mode" class="mode-button active" type="button" aria-pressed="true">Learn</button>
            <button id="practice-mode" class="mode-button" type="button" aria-pressed="false">Practice</button>
        </nav>

        <section id="learn-controls" class="controls" aria-label="Find icons">
            <label for="icon-search">
                Find an icon
                <input id="icon-search" type="search" autocomplete="off" placeholder="Try delete, sound, Wi-Fi…">
            </label>

            <label for="category-filter">
                Category
                <select id="category-filter">
                    <option value="all">All categories</option>
                </select>
            </label>
        </section>

        <section class="progress-area" aria-label="Learning progress">
            <div class="progress-label">
                <span id="progress-text">0 of 20 icons explored</span>
                <button id="clear-progress" class="text-button" type="button">Clear progress</button>
            </div>
            <progress id="learning-progress" value="0" max="20">0 of 20</progress>
        </section>

        <p id="result-status" class="status-message" role="status" aria-live="polite"></p>

        <section id="learn-detail" class="detail-panel" aria-labelledby="detail-name">
            <div id="detail-icon" class="large-icon" aria-hidden="true"></div>
            <div class="detail-copy">
                <p id="detail-category" class="detail-category"></p>
                <h2 id="detail-name">Select an icon</h2>
                <p id="detail-meaning">Its meaning and a practical example will appear here.</p>
                <p id="detail-example" class="detail-secondary"></p>
                <p id="detail-caution" class="caution" hidden></p>
                <button id="read-aloud" class="secondary-button" type="button">Read explanation aloud</button>
            </div>
        </section>

        <section id="practice-detail" class="detail-panel" aria-labelledby="practice-heading" hidden>
            <div class="large-icon question-icon" aria-hidden="true">?</div>
            <div class="detail-copy">
                <p id="practice-number" class="detail-category">Practice question 1</p>
                <h2 id="practice-heading">Which icon means this?</h2>
                <p id="practice-prompt"></p>
                <p id="practice-feedback" class="practice-feedback" role="status" aria-live="polite"></p>
                <button id="next-question" class="secondary-button" type="button" hidden>Next question</button>
            </div>
        </section>

        <section aria-labelledby="icon-grid-heading">
            <div class="section-heading-row">
                <h2 id="icon-grid-heading">Icon choices</h2>
                <span id="visible-count"></span>
            </div>
            <div id="icon-grid" class="icon-grid"></div>
            <p id="empty-state" class="empty-state" hidden>No icons match that search. Try another word.</p>
        </section>
    </main>

    <footer>
        <p>Designed for calm, accessible learning. Progress stays only in this browser.</p>
    </footer>

    <script src="04_Application/js/icons.js"></script>
    <script src="04_Application/js/app.js"></script>
</body>
</html>
'@

        '04_Application\css\styles.css' = @'
:root {
    color-scheme: light;
    --sage: #607D68;
    --sage-dark: #314A39;
    --sage-soft: #E5EEE7;
    --warm-gray: #F4F1EC;
    --surface: #FFFFFF;
    --ink: #17201A;
    --muted-ink: #4B584F;
    --border: #B7C2BA;
    --focus: #174F7A;
    --caution: #6B4B00;
    --caution-bg: #FFF2C7;
    --success: #1E6438;
    --error: #9B1C1C;
    font-size: 18px;
}

* {
    box-sizing: border-box;
}

html {
    scroll-behavior: smooth;
}

body {
    margin: 0;
    background: var(--warm-gray);
    color: var(--ink);
    font-family: Arial, Helvetica, sans-serif;
    line-height: 1.6;
}

button,
input,
select {
    font: inherit;
}

button,
input,
select {
    min-height: 3rem;
}

button {
    cursor: pointer;
}

button:disabled {
    cursor: not-allowed;
    opacity: 0.65;
}

:focus-visible {
    outline: 0.2rem solid var(--focus);
    outline-offset: 0.2rem;
}

.skip-link {
    position: absolute;
    left: 1rem;
    top: -5rem;
    z-index: 10;
    background: var(--surface);
    color: var(--ink);
    padding: 0.75rem 1rem;
}

.skip-link:focus {
    top: 1rem;
}

.site-header {
    background: var(--sage-dark);
    color: #FFFFFF;
}

.header-inner,
main,
footer {
    width: min(74rem, 100%);
    margin: 0 auto;
    padding-left: 1.25rem;
    padding-right: 1.25rem;
}

.header-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 2rem;
    padding-top: 1.35rem;
    padding-bottom: 1.35rem;
}

.eyebrow,
.tagline,
.confidence-message {
    margin: 0;
}

.eyebrow {
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
}

.site-header h1 {
    margin: 0.1rem 0;
    font-size: clamp(2rem, 5vw, 3.25rem);
    line-height: 1.1;
}

.confidence-message {
    max-width: 22rem;
    font-weight: 700;
    text-align: right;
}

main {
    padding-top: 2rem;
    padding-bottom: 2.5rem;
}

h2 {
    line-height: 1.25;
}

.introduction {
    max-width: 52rem;
}

.introduction h2,
.introduction p {
    margin-top: 0;
}

.mode-selector {
    display: flex;
    gap: 0.75rem;
    margin: 1.5rem 0;
}

.mode-button,
.secondary-button,
.text-button {
    border: 0.12rem solid var(--sage-dark);
    border-radius: 0.55rem;
    padding: 0.65rem 1.15rem;
    background: var(--surface);
    color: var(--sage-dark);
    font-weight: 700;
}

.mode-button.active,
.secondary-button:hover,
.secondary-button:focus-visible {
    background: var(--sage-dark);
    color: #FFFFFF;
}

.text-button {
    min-height: auto;
    border: 0;
    padding: 0.35rem;
    text-decoration: underline;
}

.controls {
    display: grid;
    grid-template-columns: minmax(0, 2fr) minmax(13rem, 1fr);
    gap: 1rem;
    margin-bottom: 1rem;
}

.controls label {
    display: grid;
    gap: 0.35rem;
    font-weight: 700;
}

.controls input,
.controls select {
    width: 100%;
    border: 0.1rem solid var(--border);
    border-radius: 0.45rem;
    padding: 0.65rem 0.8rem;
    background: var(--surface);
    color: var(--ink);
}

.progress-area {
    margin: 1.1rem 0;
}

.progress-label,
.section-heading-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
}

progress {
    width: 100%;
    height: 1rem;
    accent-color: var(--sage);
}

.status-message {
    min-height: 1.75rem;
    color: var(--muted-ink);
}

.detail-panel {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    gap: 1.5rem;
    align-items: center;
    margin: 1.2rem 0 2rem;
    padding: 1.4rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.8rem;
    background: var(--surface);
}

.large-icon {
    display: grid;
    place-items: center;
    width: 7rem;
    height: 7rem;
    color: var(--sage-dark);
}

.large-icon svg {
    width: 5.5rem;
    height: 5.5rem;
    stroke-width: 1.7;
}

.question-icon {
    border-radius: 50%;
    background: var(--sage-soft);
    font-size: 4rem;
    font-weight: 700;
}

.detail-category {
    margin: 0;
    color: var(--muted-ink);
    font-weight: 700;
}

.detail-copy h2 {
    margin: 0.2rem 0 0.6rem;
    font-size: clamp(1.55rem, 4vw, 2.25rem);
}

.detail-copy p {
    margin-top: 0.5rem;
    margin-bottom: 0.5rem;
}

.detail-secondary {
    color: var(--muted-ink);
}

.caution {
    padding: 0.8rem 1rem;
    border-left: 0.3rem solid var(--caution);
    background: var(--caution-bg);
    color: #352500;
}

.practice-feedback {
    min-height: 2rem;
    font-weight: 700;
}

.practice-feedback.correct {
    color: var(--success);
}

.practice-feedback.try-again {
    color: var(--error);
}

.section-heading-row h2 {
    margin-bottom: 0.75rem;
}

.icon-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(9rem, 1fr));
    gap: 0.85rem;
}

.icon-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.65rem;
    min-height: 8.5rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.7rem;
    padding: 1rem 0.75rem;
    background: var(--surface);
    color: var(--ink);
    font-weight: 700;
    text-align: center;
}

.icon-card:hover,
.icon-card:focus-visible,
.icon-card.selected {
    border-color: var(--sage-dark);
    background: var(--sage-soft);
}

.icon-card.viewed::after {
    content: "Explored";
    color: var(--muted-ink);
    font-size: 0.8rem;
    font-weight: 400;
}

.icon-card svg {
    width: 2.75rem;
    height: 2.75rem;
    stroke-width: 1.8;
}

.empty-state {
    padding: 1.5rem;
    background: var(--surface);
}

footer {
    padding-top: 1rem;
    padding-bottom: 2rem;
    color: var(--muted-ink);
}

[hidden] {
    display: none !important;
}

@media (max-width: 700px) {
    .header-inner {
        display: block;
    }

    .confidence-message {
        margin-top: 1rem;
        text-align: left;
    }

    .controls {
        grid-template-columns: 1fr;
    }

    .detail-panel {
        grid-template-columns: 1fr;
    }

    .large-icon {
        width: 5.5rem;
        height: 5.5rem;
    }

    .large-icon svg {
        width: 4.5rem;
        height: 4.5rem;
    }
}

@media (prefers-reduced-motion: reduce) {
    html {
        scroll-behavior: auto;
    }

    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
}

@media (prefers-contrast: more) {
    :root {
        --border: #29342D;
    }

    .icon-card,
    .detail-panel,
    .controls input,
    .controls select {
        border-width: 0.16rem;
    }
}
'@

        '04_Application\js\icons.js' = @'
'use strict';

window.IconGuideIcons = (function () {
    const paths = {
        home: '<path d="m3 11 9-8 9 8"></path><path d="M5 10v10h14V10"></path><path d="M9 20v-6h6v6"></path>',
        back: '<path d="M19 12H5"></path><path d="m12 19-7-7 7-7"></path>',
        menu: '<path d="M4 6h16"></path><path d="M4 12h16"></path><path d="M4 18h16"></path>',
        search: '<circle cx="11" cy="11" r="7"></circle><path d="m20 20-4-4"></path>',
        more: '<circle cx="5" cy="12" r="1.3"></circle><circle cx="12" cy="12" r="1.3"></circle><circle cx="19" cy="12" r="1.3"></circle>',
        add: '<path d="M12 5v14"></path><path d="M5 12h14"></path>',
        edit: '<path d="M12 20h9"></path><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"></path>',
        delete: '<path d="M3 6h18"></path><path d="M8 6V4h8v2"></path><path d="m19 6-1 14H6L5 6"></path><path d="M10 11v5"></path><path d="M14 11v5"></path>',
        share: '<circle cx="18" cy="5" r="3"></circle><circle cx="6" cy="12" r="3"></circle><circle cx="18" cy="19" r="3"></circle><path d="m8.6 10.5 6.8-4"></path><path d="m8.6 13.5 6.8 4"></path>',
        download: '<path d="M12 3v12"></path><path d="m7 10 5 5 5-5"></path><path d="M5 21h14"></path>',
        upload: '<path d="M12 21V9"></path><path d="m7 14 5-5 5 5"></path><path d="M5 3h14"></path>',
        attach: '<path d="m21.4 11.1-9.2 9.2a6 6 0 0 1-8.5-8.5l9.2-9.2a4 4 0 0 1 5.7 5.7l-9.2 9.2a2 2 0 1 1-2.8-2.8l8.5-8.5"></path>',
        settings: '<circle cx="12" cy="12" r="3"></circle><path d="M12 2v3"></path><path d="M12 19v3"></path><path d="m4.9 4.9 2.1 2.1"></path><path d="m17 17 2.1 2.1"></path><path d="M2 12h3"></path><path d="M19 12h3"></path><path d="m4.9 19.1 2.1-2.1"></path><path d="m17 7 2.1-2.1"></path>',
        notifications: '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"></path><path d="M10 21h4"></path>',
        wifi: '<path d="M5 12.6a11 11 0 0 1 14 0"></path><path d="M8.5 16a6 6 0 0 1 7 0"></path><circle cx="12" cy="20" r="1"></circle><path d="M2 9a16 16 0 0 1 20 0"></path>',
        lock: '<rect x="5" y="10" width="14" height="11" rx="2"></rect><path d="M8 10V7a4 4 0 0 1 8 0v3"></path>',
        view: '<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12"></path><circle cx="12" cy="12" r="3"></circle>',
        camera: '<path d="M4 7h3l2-3h6l2 3h3a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2"></path><circle cx="12" cy="14" r="4"></circle>',
        microphone: '<rect x="9" y="2" width="6" height="12" rx="3"></rect><path d="M5 11a7 7 0 0 0 14 0"></path><path d="M12 18v4"></path><path d="M8 22h8"></path>',
        volume: '<path d="M11 5 6 9H2v6h4l5 4Z"></path><path d="M15.5 8.5a5 5 0 0 1 0 7"></path><path d="M18 6a8.5 8.5 0 0 1 0 12"></path>'
    };

    function render(name, label) {
        const content = paths[name] || paths.more;
        const accessibleLabel = label ? ' aria-label="' + label + '" role="img"' : ' aria-hidden="true"';

        return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"' + accessibleLabel + '>' + content + '</svg>';
    }

    return {
        render: render
    };
}());
'@

        '04_Application\js\app.js' = @'
'use strict';

(function () {
    const STORAGE_KEY = 'techsavvysage-icon-guide-progress-v1';
    const state = {
        icons: [],
        filteredIcons: [],
        viewed: new Set(),
        selectedId: null,
        mode: 'learn',
        practiceOrder: [],
        practiceIndex: 0,
        practiceAnswered: false
    };

    const elements = {};

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function loadProgress() {
        try {
            const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));

            if (saved && Array.isArray(saved.viewed)) {
                state.viewed = new Set(saved.viewed);
            }

            if (saved && typeof saved.selectedId === 'string') {
                state.selectedId = saved.selectedId;
            }
        }
        catch (error) {
            state.viewed = new Set();
        }
    }

    function saveProgress() {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify({
                viewed: Array.from(state.viewed),
                selectedId: state.selectedId
            }));
        }
        catch (error) {
            // The utility remains usable if local browser storage is unavailable.
        }
    }

    function setStatus(message) {
        elements.resultStatus.textContent = message;
    }

    function updateProgress() {
        const count = state.viewed.size;
        const total = state.icons.length;
        elements.progressText.textContent = count + ' of ' + total + ' icons explored';
        elements.learningProgress.max = total || 1;
        elements.learningProgress.value = count;
        elements.learningProgress.textContent = count + ' of ' + total;
    }

    function buildCategoryOptions() {
        const categories = Array.from(new Set(state.icons.map(function (icon) {
            return icon.category;
        }))).sort();

        categories.forEach(function (category) {
            const option = document.createElement('option');
            option.value = category;
            option.textContent = category;
            elements.categoryFilter.appendChild(option);
        });
    }

    function matchesSearch(icon, query) {
        if (!query) {
            return true;
        }

        const searchableText = [
            icon.name,
            icon.category,
            icon.meaning,
            icon.example,
            icon.caution || '',
            icon.search_terms.join(' ')
        ].join(' ').toLowerCase();

        return searchableText.includes(query);
    }

    function applyFilters() {
        const query = elements.iconSearch.value.trim().toLowerCase();
        const category = elements.categoryFilter.value;

        state.filteredIcons = state.icons.filter(function (icon) {
            const categoryMatches = category === 'all' || icon.category === category;
            return categoryMatches && matchesSearch(icon, query);
        });

        renderGrid();
        setStatus(state.filteredIcons.length + ' icon choices shown.');
    }

    function createIconButton(icon) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'icon-card';
        button.dataset.iconId = icon.id;
        button.setAttribute('aria-label', icon.name + '. ' + icon.meaning);
        button.innerHTML = window.IconGuideIcons.render(icon.icon) + '<span>' + escapeHtml(icon.name) + '</span>';

        if (state.viewed.has(icon.id)) {
            button.classList.add('viewed');
        }

        if (state.mode === 'learn' && state.selectedId === icon.id) {
            button.classList.add('selected');
            button.setAttribute('aria-current', 'true');
        }

        return button;
    }

    function renderGrid() {
        elements.iconGrid.innerHTML = '';
        const iconsToRender = state.mode === 'practice' ? state.icons : state.filteredIcons;

        iconsToRender.forEach(function (icon) {
            elements.iconGrid.appendChild(createIconButton(icon));
        });

        elements.visibleCount.textContent = iconsToRender.length + ' icons';
        elements.emptyState.hidden = iconsToRender.length !== 0;
    }

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

    function showIconDetail(icon) {
        if (!icon) {
            return;
        }

        state.selectedId = icon.id;
        state.viewed.add(icon.id);
        saveProgress();

        elements.detailIcon.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
        elements.detailCategory.textContent = icon.category + ' · ' + icon.devices.join(', ');
        elements.detailName.textContent = icon.name;
        elements.detailMeaning.textContent = icon.meaning;
        elements.detailExample.textContent = icon.example;

        if (icon.caution) {
            elements.detailCaution.textContent = 'Pause and notice: ' + icon.caution;
            elements.detailCaution.hidden = false;
        }
        else {
            elements.detailCaution.hidden = true;
            elements.detailCaution.textContent = '';
        }

        elements.readAloud.dataset.iconId = icon.id;
        updateProgress();
        renderGrid();
        setStatus(icon.name + ' selected.');
    }

    function setMode(mode) {
        state.mode = mode;
        const learning = mode === 'learn';

        elements.learnMode.classList.toggle('active', learning);
        elements.practiceMode.classList.toggle('active', !learning);
        elements.learnMode.setAttribute('aria-pressed', String(learning));
        elements.practiceMode.setAttribute('aria-pressed', String(!learning));
        elements.learnControls.hidden = !learning;
        elements.learnDetail.hidden = !learning;
        elements.practiceDetail.hidden = learning;
        elements.clearProgress.hidden = !learning;

        if (learning) {
            applyFilters();
            const selected = findIcon(state.selectedId) || state.icons[0];
            showIconDetail(selected);
        }
        else {
            state.practiceIndex = 0;
            state.practiceOrder = shufflePracticeOrder(state.icons.map(function (icon) {
                return icon.id;
            }));
            showPracticeQuestion();
        }
    }

    function currentPracticeIcon() {
        const id = state.practiceOrder[state.practiceIndex % state.practiceOrder.length];
        return findIcon(id);
    }

    function showPracticeQuestion() {
        const target = currentPracticeIcon();
        state.practiceAnswered = false;
        elements.practiceNumber.textContent = 'Practice question ' + (state.practiceIndex + 1);
        elements.practicePrompt.textContent = target.meaning;
        elements.practiceFeedback.textContent = '';
        elements.practiceFeedback.className = 'practice-feedback';
        elements.nextQuestion.hidden = true;
        renderGrid();
        setStatus('Choose the icon that matches the meaning.');
    }

    function answerPractice(icon) {
        if (state.practiceAnswered) {
            return;
        }

        const target = currentPracticeIcon();
        const correct = icon.id === target.id;
        state.practiceAnswered = true;

        elements.practiceFeedback.textContent = correct
            ? 'That’s right. This is the ' + target.name + ' icon.'
            : 'Good try. The correct answer is ' + target.name + '.';
        elements.practiceFeedback.classList.add(correct ? 'correct' : 'try-again');
        elements.nextQuestion.hidden = false;
        setStatus(correct ? 'Correct answer.' : 'Answer reviewed.');
    }

    function readSelectedAloud() {
        const icon = findIcon(elements.readAloud.dataset.iconId);

        if (!icon || !('speechSynthesis' in window)) {
            setStatus('Read-aloud is not available in this browser.');
            return;
        }

        window.speechSynthesis.cancel();
        const message = new SpeechSynthesisUtterance(icon.audio_text);
        message.rate = 0.9;
        window.speechSynthesis.speak(message);
        setStatus('Reading the ' + icon.name + ' explanation aloud.');
    }

    function clearProgress() {
        const confirmed = window.confirm('Clear the explored-icon progress stored in this browser?');

        if (!confirmed) {
            return;
        }

        state.viewed.clear();
        saveProgress();
        updateProgress();
        renderGrid();
        setStatus('Learning progress cleared.');
    }

    function bindEvents() {
        elements.learnMode.addEventListener('click', function () {
            setMode('learn');
        });
        elements.practiceMode.addEventListener('click', function () {
            setMode('practice');
        });
        elements.iconSearch.addEventListener('input', applyFilters);
        elements.categoryFilter.addEventListener('change', applyFilters);
        elements.readAloud.addEventListener('click', readSelectedAloud);
        elements.clearProgress.addEventListener('click', clearProgress);
        elements.nextQuestion.addEventListener('click', function () {
            state.practiceIndex = (state.practiceIndex + 1) % state.practiceOrder.length;
            showPracticeQuestion();
        });
        elements.iconGrid.addEventListener('click', function (event) {
            const button = event.target.closest('[data-icon-id]');

            if (!button) {
                return;
            }

            const icon = findIcon(button.dataset.iconId);

            if (state.mode === 'learn') {
                showIconDetail(icon);
            }
            else {
                answerPractice(icon);
            }
        });
    }

    function captureElements() {
        elements.learnMode = document.getElementById('learn-mode');
        elements.practiceMode = document.getElementById('practice-mode');
        elements.learnControls = document.getElementById('learn-controls');
        elements.iconSearch = document.getElementById('icon-search');
        elements.categoryFilter = document.getElementById('category-filter');
        elements.progressText = document.getElementById('progress-text');
        elements.learningProgress = document.getElementById('learning-progress');
        elements.clearProgress = document.getElementById('clear-progress');
        elements.resultStatus = document.getElementById('result-status');
        elements.learnDetail = document.getElementById('learn-detail');
        elements.practiceDetail = document.getElementById('practice-detail');
        elements.detailIcon = document.getElementById('detail-icon');
        elements.detailCategory = document.getElementById('detail-category');
        elements.detailName = document.getElementById('detail-name');
        elements.detailMeaning = document.getElementById('detail-meaning');
        elements.detailExample = document.getElementById('detail-example');
        elements.detailCaution = document.getElementById('detail-caution');
        elements.readAloud = document.getElementById('read-aloud');
        elements.practiceNumber = document.getElementById('practice-number');
        elements.practicePrompt = document.getElementById('practice-prompt');
        elements.practiceFeedback = document.getElementById('practice-feedback');
        elements.nextQuestion = document.getElementById('next-question');
        elements.iconGrid = document.getElementById('icon-grid');
        elements.visibleCount = document.getElementById('visible-count');
        elements.emptyState = document.getElementById('empty-state');
    }

    async function initialize() {
        captureElements();
        loadProgress();

        try {
            const response = await fetch('04_Application/data/icons.json', { cache: 'no-store' });

            if (!response.ok) {
                throw new Error('Icon data could not be loaded.');
            }

            const data = await response.json();
            state.icons = data.icons;
            state.filteredIcons = data.icons.slice();
            buildCategoryOptions();
            bindEvents();
            updateProgress();
            showIconDetail(findIcon(state.selectedId) || state.icons[0]);
            applyFilters();

            if (!('speechSynthesis' in window)) {
                elements.readAloud.disabled = true;
                elements.readAloud.textContent = 'Read-aloud unavailable';
            }

            if ('serviceWorker' in navigator) {
                navigator.serviceWorker.register('service-worker.js').catch(function () {
                    // The utility remains functional if offline support is unavailable.
                });
            }
        }
        catch (error) {
            elements.resultStatus.textContent = 'The icon guide could not load. Please refresh the page.';
            elements.resultStatus.classList.add('practice-feedback', 'try-again');
        }
    }

    document.addEventListener('DOMContentLoaded', initialize);
}());
'@

        '04_Application\data\icons.json' = @'
{
  "schema_version": "1.0.0",
  "utility": "TechSavvySage Icon Guide",
  "icons": [
    {
      "id": "home",
      "name": "Home",
      "icon": "home",
      "category": "Navigation",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Returns you to the app’s or website’s starting screen.",
      "example": "Use Home when you want to return to the main page without closing the app.",
      "caution": "Home does not usually sign you out or close the app.",
      "search_terms": ["start", "main", "house", "homepage"],
      "audio_text": "The Home icon returns you to the app’s or website’s starting screen."
    },
    {
      "id": "back",
      "name": "Back",
      "icon": "back",
      "category": "Navigation",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Returns to the screen or page you just left.",
      "example": "Use Back if you opened the wrong page and want to return to the previous one.",
      "caution": "In a form, going back may remove information that has not been saved.",
      "search_terms": ["previous", "return", "left arrow"],
      "audio_text": "The Back icon returns to the screen or page you just left."
    },
    {
      "id": "menu",
      "name": "Menu",
      "icon": "menu",
      "category": "Navigation",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Opens a list of sections, pages, or choices.",
      "example": "Select Menu to find items such as Profile, Help, Settings, or Sign Out.",
      "caution": "The menu may close when you select outside it; nothing has been deleted.",
      "search_terms": ["hamburger", "three lines", "choices", "navigation"],
      "audio_text": "The Menu icon opens a list of sections, pages, or choices."
    },
    {
      "id": "search",
      "name": "Search",
      "icon": "search",
      "category": "Navigation",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Helps you find a person, file, setting, message, or topic.",
      "example": "Select Search, type a word, and review the matching results.",
      "caution": "Search results may include advertisements or unfamiliar websites.",
      "search_terms": ["find", "magnifying glass", "look up"],
      "audio_text": "The Search icon helps you find a person, file, setting, message, or topic."
    },
    {
      "id": "more",
      "name": "More",
      "icon": "more",
      "category": "Navigation",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Opens additional choices that are not currently shown.",
      "example": "Select the three dots to find actions such as Print, Share, Move, or Delete.",
      "caution": "Review the choices before selecting; important actions may be inside this menu.",
      "search_terms": ["three dots", "ellipsis", "options", "additional"],
      "audio_text": "The More icon opens additional choices that are not currently shown."
    },
    {
      "id": "add",
      "name": "Add",
      "icon": "add",
      "category": "Actions",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Creates or adds something new.",
      "example": "Use Add for a new contact, message, calendar event, file, or browser tab.",
      "caution": "Add does not always save the new item; look for Save or Done afterward.",
      "search_terms": ["plus", "new", "create"],
      "audio_text": "The Add icon creates or adds something new."
    },
    {
      "id": "edit",
      "name": "Edit",
      "icon": "edit",
      "category": "Actions",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Lets you change information that already exists.",
      "example": "Use Edit to revise a contact, note, photograph, or document.",
      "caution": "Look for Save, Apply, or Done so your changes are not lost.",
      "search_terms": ["pencil", "change", "revise", "modify"],
      "audio_text": "The Edit icon lets you change information that already exists."
    },
    {
      "id": "delete",
      "name": "Delete",
      "icon": "delete",
      "category": "Actions",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Removes the selected item.",
      "example": "Use Delete to remove a message, photograph, contact, or file.",
      "caution": "Pause before selecting Delete. Some items can be restored, while others cannot.",
      "search_terms": ["trash", "remove", "erase", "bin"],
      "audio_text": "The Delete icon removes the selected item. Pause first because some items cannot be restored."
    },
    {
      "id": "share",
      "name": "Share",
      "icon": "share",
      "category": "Actions",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Sends a copy or link to another person or app.",
      "example": "Use Share to send a photo, webpage, document, or contact information.",
      "caution": "Confirm the recipient and the information before sending it.",
      "search_terms": ["send", "forward", "link", "recipient"],
      "audio_text": "The Share icon sends a copy or link to another person or app. Confirm the recipient before sending."
    },
    {
      "id": "download",
      "name": "Download",
      "icon": "download",
      "category": "Files",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Saves a file or item onto your device.",
      "example": "Use Download to save a statement, photograph, document, or application file.",
      "caution": "Download files only from people and websites you trust.",
      "search_terms": ["save", "down arrow", "file", "device"],
      "audio_text": "The Download icon saves a file or item onto your device. Download only from sources you trust."
    },
    {
      "id": "upload",
      "name": "Upload",
      "icon": "upload",
      "category": "Files",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Sends a file from your device into an app, website, or cloud service.",
      "example": "Use Upload to add a résumé, photograph, receipt, or supporting document to a website.",
      "caution": "Check that the selected file does not contain information you did not intend to share.",
      "search_terms": ["send file", "up arrow", "cloud", "website"],
      "audio_text": "The Upload icon sends a file from your device into an app, website, or cloud service."
    },
    {
      "id": "attach",
      "name": "Attach",
      "icon": "attach",
      "category": "Files",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Adds a file, photograph, or document to a message or form.",
      "example": "Use the paperclip when an email or form asks you to include a document.",
      "caution": "Open the attachment name before sending to confirm you selected the correct file.",
      "search_terms": ["paperclip", "email", "file", "include"],
      "audio_text": "The Attach icon adds a file, photograph, or document to a message or form."
    },
    {
      "id": "settings",
      "name": "Settings",
      "icon": "settings",
      "category": "Device",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Opens controls for how an app or device works.",
      "example": "Use Settings to change text size, privacy, sound, display, notifications, or account options.",
      "caution": "Change one setting at a time so it is easier to reverse if needed.",
      "search_terms": ["gear", "preferences", "controls", "options"],
      "audio_text": "The Settings icon opens controls for how an app or device works. Change one setting at a time."
    },
    {
      "id": "notifications",
      "name": "Notifications",
      "icon": "notifications",
      "category": "Device",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Shows alerts, reminders, and recent activity.",
      "example": "A dot or number near the bell may mean that an alert is waiting for you.",
      "caution": "An alert is not always urgent. Read it before taking action.",
      "search_terms": ["bell", "alert", "reminder", "badge"],
      "audio_text": "The Notifications icon shows alerts, reminders, and recent activity. An alert is not always urgent."
    },
    {
      "id": "wifi",
      "name": "Wi-Fi",
      "icon": "wifi",
      "category": "Connections",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Shows or manages a wireless internet connection.",
      "example": "More filled curves usually indicate a stronger Wi-Fi connection.",
      "caution": "Public Wi-Fi may not be private. Avoid sensitive activity unless the connection is trusted.",
      "search_terms": ["internet", "wireless", "network", "connection"],
      "audio_text": "The Wi-Fi icon shows or manages a wireless internet connection. Public Wi-Fi may not be private."
    },
    {
      "id": "lock",
      "name": "Lock",
      "icon": "lock",
      "category": "Safety",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Indicates security, privacy, or protected access.",
      "example": "A lock near a website address means the connection between your browser and the website is encrypted.",
      "caution": "A lock does not prove that the website itself is honest or safe.",
      "search_terms": ["secure", "privacy", "password", "encrypted"],
      "audio_text": "The Lock icon indicates security, privacy, or protected access. It does not prove that a website is trustworthy."
    },
    {
      "id": "view",
      "name": "View",
      "icon": "view",
      "category": "Safety",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Shows hidden content or opens a preview.",
      "example": "Near a password field, the eye may temporarily reveal the characters you typed.",
      "caution": "Hide a revealed password before someone else can see the screen.",
      "search_terms": ["eye", "show", "preview", "password", "reveal"],
      "audio_text": "The View icon shows hidden content or opens a preview. Hide a revealed password when others can see your screen."
    },
    {
      "id": "camera",
      "name": "Camera",
      "icon": "camera",
      "category": "Communication",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Opens the camera or lets you add a photograph or video.",
      "example": "Use Camera for a video call, profile photo, document scan, or picture message.",
      "caution": "An app may ask for camera permission. Allow it only when the feature needs the camera.",
      "search_terms": ["photo", "picture", "video", "scan"],
      "audio_text": "The Camera icon opens the camera or lets you add a photograph or video. Review camera permission requests."
    },
    {
      "id": "microphone",
      "name": "Microphone",
      "icon": "microphone",
      "category": "Communication",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Starts voice input, recording, or speech-to-text.",
      "example": "Use Microphone to dictate a message, speak a search, record audio, or join a call.",
      "caution": "An app may ask for microphone permission. Allow it only when the feature needs to listen.",
      "search_terms": ["mic", "voice", "record", "dictate", "speech"],
      "audio_text": "The Microphone icon starts voice input, recording, or speech-to-text. Review microphone permission requests."
    },
    {
      "id": "volume",
      "name": "Volume",
      "icon": "volume",
      "category": "Device",
      "devices": ["Computer", "iPhone", "Android"],
      "meaning": "Controls or indicates sound level.",
      "example": "Use Volume to make videos, calls, alerts, or spoken directions louder or quieter.",
      "caution": "A slash through the speaker usually means the sound is muted.",
      "search_terms": ["sound", "speaker", "mute", "audio", "loud"],
      "audio_text": "The Volume icon controls or indicates sound level. A slash through the speaker usually means muted."
    }
  ]
}
'@

        'manifest.webmanifest' = @'
{
  "name": "TechSavvySage Icon Guide",
  "short_name": "Icon Guide",
  "description": "Accessible, untimed learning utility for commonly used computer and mobile icons.",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "background_color": "#F4F1EC",
  "theme_color": "#607D68",
  "lang": "en-US",
  "icons": []
}
'@

        'service-worker.js' = @'
'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v0.1.1';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/icons.js',
    './04_Application/js/app.js',
    './04_Application/data/icons.json'
];

self.addEventListener('install', function (event) {
    event.waitUntil(
        caches.open(CACHE_NAME).then(function (cache) {
            return cache.addAll(CORE_ASSETS);
        })
    );
    self.skipWaiting();
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
    self.clients.claim();
});

self.addEventListener('fetch', function (event) {
    if (event.request.method !== 'GET') {
        return;
    }

    event.respondWith(
        caches.match(event.request).then(function (cachedResponse) {
            return cachedResponse || fetch(event.request).then(function (networkResponse) {
                return networkResponse;
            });
        })
    );
});
'@

        '01_Documentation\Phase_1_MVP_User_Guide.md' = @'
# Phase 1 MVP User Guide

## Purpose

The TechSavvySage Icon Guide helps adults 50+ and people with varied learning needs understand commonly used computer and phone icons.

## Learn mode

1. Search or choose a category if desired.
2. Select an icon.
3. Review its meaning, example, device context, and safety note.
4. Select **Read explanation aloud** when audio support is helpful.

## Practice mode

1. Select **Practice**.
2. Read the meaning shown in the question.
3. Choose the icon that matches.
4. Review the answer and continue when ready.

Practice is untimed. There is no penalty for an incorrect answer.

## Privacy

The utility does not require an account and does not collect personally identifiable information. Explored-icon progress is stored only in the current browser and can be cleared by the learner.
'@

        '05_Testing\Phase_1_MVP_Validation_Checklist.md' = @'
# Phase 1 MVP Validation Checklist

## Functional

- [ ] All 20 icons display.
- [ ] Search returns expected icons and safety terms.
- [ ] Category filtering works.
- [ ] Learn mode displays meaning, example, device context, and caution.
- [ ] Practice mode accepts an answer and provides supportive feedback.
- [ ] Read-aloud works when browser speech support is available.
- [ ] Explored-icon progress persists after refresh.
- [ ] Clear progress requires confirmation.

## Accessibility

- [ ] Complete the utility using only a keyboard.
- [ ] Focus remains visible.
- [ ] Screen-reader labels identify icon buttons.
- [ ] Text remains readable at 200 percent browser zoom.
- [ ] Controls remain usable at a 320-pixel viewport.
- [ ] Color is not the only way feedback is communicated.
- [ ] Reduced-motion preference is honored.
- [ ] Practice has no timer.

## Browsers and devices

- [ ] Microsoft Edge on Windows.
- [ ] Chrome on Windows.
- [ ] Safari on iPhone or iPad.
- [ ] Chrome on Android.
'@
    }

    Write-Section -Text 'Phase 1A - Preflight Validation'

    $GitRoot = Join-Path -Path $ResolvedRepositoryRoot -ChildPath '.git'

    if (Test-Path -LiteralPath $GitRoot) {
        Write-Status -Level 'PASS' -Message 'Git repository metadata detected.'
    }
    else {
        Write-Status -Level 'WARN' -Message 'Git repository metadata was not detected.'
    }

    Write-Section -Text 'Phase 1B - MVP Application Build'

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 1 replaces the controlled repository baseline. Run Build mode with -Force after confirming the baseline is committed.'
        }

        foreach ($RelativeFilePath in $Phase1Files.Keys) {
            $FilePath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath $RelativeFilePath

            Write-ControlledFile `
                -Path $FilePath `
                -Content $Phase1Files[$RelativeFilePath] `
                -Replace
        }

        $CanonicalBuilderPath = Join-Path `
            -Path $ResolvedRepositoryRoot `
            -ChildPath '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase1.ps1'

        $CurrentScriptPath = Get-NormalizedPath -Path $MyInvocation.MyCommand.Path

        if ($CurrentScriptPath -ne (Get-NormalizedPath -Path $CanonicalBuilderPath)) {
            Copy-Item -LiteralPath $CurrentScriptPath -Destination $CanonicalBuilderPath -Force
            Write-Status -Level 'REPLACE' -Message $CanonicalBuilderPath
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. File generation was skipped.'
    }

    Write-Section -Text 'Phase 1C - MVP Validation'

    $ValidationSucceeded = $true
    $RequiredFiles = @(
        $Phase1Files.Keys
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase1.ps1'
    )

    foreach ($RelativeFilePath in $RequiredFiles) {
        $FilePath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath $RelativeFilePath

        if (-not (Test-RequiredFile -Path $FilePath)) {
            $ValidationSucceeded = $false
        }
    }

    $IconsDataPath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath '04_Application\data\icons.json'
    $ManifestPath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath 'manifest.webmanifest'
    $IndexPath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath 'index.html'
    $AppScriptPath = Join-Path -Path $ResolvedRepositoryRoot -ChildPath '04_Application\js\app.js'

    if (Test-Path -LiteralPath $IconsDataPath -PathType Leaf) {
        $IconData = Get-Content -LiteralPath $IconsDataPath -Raw | ConvertFrom-Json
        $IconCount = @($IconData.icons).Count

        if ($IconCount -ne 20) {
            Write-Status -Level 'FAIL' -Message "Expected 20 icon records; found $IconCount."
            $ValidationSucceeded = $false
        }
        else {
            Write-Status -Level 'PASS' -Message 'Icon data contains 20 records.'
        }

        $DuplicateIds = @(
            $IconData.icons |
                Group-Object -Property id |
                Where-Object { $_.Count -gt 1 }
        )

        if ($DuplicateIds.Count -gt 0) {
            Write-Status -Level 'FAIL' -Message 'Duplicate icon identifiers were detected.'
            $ValidationSucceeded = $false
        }
        else {
            Write-Status -Level 'PASS' -Message 'Icon identifiers are unique.'
        }
    }

    if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
        Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json | Out-Null
        Write-Status -Level 'PASS' -Message 'Web application manifest is valid JSON.'
    }

    if (Test-Path -LiteralPath $IndexPath -PathType Leaf) {
        $IndexContent = Get-Content -LiteralPath $IndexPath -Raw
        $RequiredElementIds = @(
            'learn-mode',
            'practice-mode',
            'icon-search',
            'category-filter',
            'learn-detail',
            'practice-detail',
            'icon-grid',
            'read-aloud'
        )

        foreach ($RequiredElementId in $RequiredElementIds) {
            if ($IndexContent -notmatch ('id="{0}"' -f [regex]::Escape($RequiredElementId))) {
                Write-Status -Level 'FAIL' -Message "Required interface element is missing: $RequiredElementId"
                $ValidationSucceeded = $false
            }
        }

        if ($ValidationSucceeded) {
            Write-Status -Level 'PASS' -Message 'Required interface elements were detected.'
        }
    }

    if (Test-Path -LiteralPath $AppScriptPath -PathType Leaf) {
        $AppScriptContent = Get-Content -LiteralPath $AppScriptPath -Raw

        foreach ($RequiredCapability in @('speechSynthesis', 'localStorage', 'serviceWorker', 'practice')) {
            if ($AppScriptContent -notmatch [regex]::Escape($RequiredCapability)) {
                Write-Status -Level 'FAIL' -Message "Required capability marker is missing: $RequiredCapability"
                $ValidationSucceeded = $false
            }
        }

        Write-Status -Level 'PASS' -Message 'Phase 1 capability markers were evaluated.'
    }

    Write-Section -Text 'Phase 1 Execution Metrics'
    Write-Metric -Name 'Created files' -Value $Script:CreatedFiles
    Write-Metric -Name 'Replaced files' -Value $Script:ReplacedFiles
    Write-Metric -Name 'Existing files' -Value $Script:ExistingFiles
    Write-Metric -Name 'Validated files' -Value $Script:ValidatedFiles
    Write-Metric -Name 'Missing files' -Value $Script:MissingFiles

    if (-not $ValidationSucceeded) {
        throw 'Phase 1 validation failed.'
    }

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 1 MVP COMPLETE'
    Write-Status -Level 'PASS' -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    $ErrorCommand = $_.InvocationInfo.Line

    if ([string]::IsNullOrWhiteSpace($ErrorCommand)) {
        $ErrorCommand = $_.InvocationInfo.MyCommand.Name
    }

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 1 ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ''
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ('Command     : {0}' -f $ErrorCommand.Trim()) -ForegroundColor Red
    Write-Host ''

    exit 1
}




