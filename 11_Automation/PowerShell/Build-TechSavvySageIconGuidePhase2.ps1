# ============================================================================
# Build-TechSavvySageIconGuidePhase2.ps1
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

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 2 Builder'
$Script:UtilityVersion = '0.2.0'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:CreatedFolders = 0
$Script:ExistingFolders = 0
$Script:CreatedFiles = 0
$Script:ReplacedFiles = 0
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

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'CREATE'   { 'Green' }
        'REPLACE'  { 'Yellow' }
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

function Ensure-Directory {
    param ([Parameter(Mandatory)][string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Container) {
        $Script:ExistingFolders++
        Write-Status -Level 'EXISTS' -Message $Path
        return
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    $Script:CreatedFolders++
    Write-Status -Level 'CREATE' -Message $Path
}

function Write-Utf8File {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $NormalizedContent = $Content.TrimEnd([char[]]@("`r", "`n")) + "`n"
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf
    [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)

    if ($Exists) {
        $Script:ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
    }
    else {
        $Script:CreatedFiles++
        Write-Status -Level 'CREATE' -Message $Path
    }
}

function Write-AppIcon {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][int]$Size
    )

    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-Type -AssemblyName System.Drawing
    $Bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $WhitePen = $null
    $GoldPen = $null
    $GoldBrush = $null

    try {
        $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $Graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#314A39'))

        $StrokeWidth = [Math]::Max(4, [int]($Size / 32))
        $WhitePen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, $StrokeWidth)
        $GoldColor = [System.Drawing.ColorTranslator]::FromHtml('#FFF2C7')
        $GoldPen = [System.Drawing.Pen]::new($GoldColor, $StrokeWidth)
        $GoldBrush = [System.Drawing.SolidBrush]::new($GoldColor)

        $Graphics.DrawRectangle($WhitePen, [int]($Size * 0.16), [int]($Size * 0.22), [int]($Size * 0.52), [int]($Size * 0.42))
        $Graphics.DrawLine($WhitePen, [int]($Size * 0.42), [int]($Size * 0.64), [int]($Size * 0.42), [int]($Size * 0.75))
        $Graphics.DrawLine($WhitePen, [int]($Size * 0.28), [int]($Size * 0.75), [int]($Size * 0.56), [int]($Size * 0.75))
        $Graphics.DrawRectangle($GoldPen, [int]($Size * 0.62), [int]($Size * 0.34), [int]($Size * 0.22), [int]($Size * 0.44))
        $Graphics.FillEllipse($GoldBrush, [int]($Size * 0.715), [int]($Size * 0.715), [int]($Size * 0.03), [int]($Size * 0.03))
        $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        if ($null -ne $GoldBrush) { $GoldBrush.Dispose() }
        if ($null -ne $GoldPen) { $GoldPen.Dispose() }
        if ($null -ne $WhitePen) { $WhitePen.Dispose() }
        $Graphics.Dispose()
        $Bitmap.Dispose()
    }

    if ($Exists) {
        $Script:ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
    }
    else {
        $Script:CreatedFiles++
        Write-Status -Level 'CREATE' -Message $Path
    }
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

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 2 builder directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $ResolvedRepositoryRoot"
    }

    $Phase1RequiredFiles = @(
        'index.html',
        '04_Application\css\styles.css',
        '04_Application\data\icons.json',
        '04_Application\js\app.js',
        '04_Application\js\icons.js',
        'manifest.webmanifest',
        'service-worker.js',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase1.ps1'
    )

    Write-Section -Text 'Phase 2A - Preflight Validation'

    foreach ($RelativePath in $Phase1RequiredFiles) {
        $FullPath = Join-Path $ResolvedRepositoryRoot $RelativePath

        if (-not (Test-Path -LiteralPath $FullPath -PathType Leaf)) {
            throw "The validated Phase 1 baseline is incomplete: $FullPath"
        }
    }

    Write-Status -Level 'PASS' -Message 'The Phase 1 application baseline is present.'

    $AssetRoot = Join-Path $ResolvedRepositoryRoot '04_Application\assets\app-icons'

    if ($OperatingMode -eq 'Build') {
        if (-not $Force) {
            throw 'Phase 2 updates controlled application files. Run Build mode with -Force after confirming Phase 1 is committed.'
        }

        Write-Section -Text 'Phase 2B - Guided Learning Application Build'
        Ensure-Directory -Path (Join-Path $ResolvedRepositoryRoot '04_Application\assets')
        Ensure-Directory -Path $AssetRoot

        $IndexContent = @'
<!doctype html>
<html lang="en" data-text-size="standard">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Learn and practice 40 common computer and phone icons through accessible, untimed lessons.">
    <meta name="theme-color" content="#607D68">
    <title>TechSavvySage Icon Guide</title>
    <link rel="manifest" href="manifest.webmanifest">
    <link rel="apple-touch-icon" href="04_Application/assets/app-icons/icon-guide-192.png">
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
            <p>Learn at your pace, save icons for review, or choose a short practice session. There’s no timer and no penalty for trying.</p>
        </section>

        <nav class="mode-selector" aria-label="Learning mode">
            <button id="learn-mode" class="mode-button active" type="button" aria-pressed="true">Learn</button>
            <button id="practice-mode" class="mode-button" type="button" aria-pressed="false">Practice</button>
            <button id="review-mode" class="mode-button" type="button" aria-pressed="false">Saved for review</button>
        </nav>

        <details class="settings-panel">
            <summary>Display settings</summary>
            <div class="settings-controls">
                <label for="text-size">
                    Text size
                    <select id="text-size">
                        <option value="standard">Standard</option>
                        <option value="large">Large</option>
                        <option value="extra-large">Extra Large</option>
                    </select>
                </label>
                <label class="checkbox-label" for="high-contrast">
                    <input id="high-contrast" type="checkbox">
                    Use high contrast
                </label>
                <button id="reset-display" class="secondary-button" type="button">Reset display settings</button>
            </div>
        </details>

        <section id="learn-controls" class="controls" aria-label="Find icons">
            <label for="icon-search">
                Find an icon
                <input id="icon-search" type="search" autocomplete="off" placeholder="Try message, warning, Bluetooth…">
            </label>
            <label for="category-filter">
                Category
                <select id="category-filter">
                    <option value="all">All categories</option>
                </select>
            </label>
        </section>

        <section id="progress-area" class="progress-area" aria-label="Learning progress">
            <div class="progress-label">
                <span id="progress-text">0 of 40 icons explored</span>
                <button id="clear-progress" class="text-button" type="button">Clear learning data</button>
            </div>
            <progress id="learning-progress" value="0" max="40">0 of 40</progress>
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
                <div class="button-row">
                    <button id="read-aloud" class="secondary-button" type="button">Read explanation aloud</button>
                    <button id="save-review" class="secondary-button" type="button">Save for review</button>
                    <button id="practice-icon" class="secondary-button" type="button">Practice this icon</button>
                </div>
            </div>
        </section>

        <section id="practice-detail" class="practice-panel" aria-labelledby="practice-heading" hidden>
            <div id="practice-setup">
                <h2 id="practice-heading">Choose a practice session</h2>
                <p>Questions are shuffled. Each question shows four icon choices and there is no timer.</p>
                <label for="session-length">
                    Number of questions
                    <select id="session-length">
                        <option value="5">5 questions</option>
                        <option value="10" selected>10 questions</option>
                        <option value="20">20 questions</option>
                        <option value="all">All 40 icons</option>
                    </select>
                </label>
                <button id="start-practice" class="primary-button" type="button">Start practice</button>
            </div>

            <div id="practice-question" hidden>
                <p id="practice-number" class="detail-category">Question 1 of 10</p>
                <h2>Which icon means this?</h2>
                <p id="practice-prompt" class="practice-prompt"></p>
                <p id="practice-feedback" class="practice-feedback" role="status" aria-live="polite"></p>
                <button id="next-question" class="secondary-button" type="button" hidden>Next question</button>
            </div>

            <div id="practice-results" hidden>
                <h2>Practice complete</h2>
                <p id="results-summary" class="results-summary"></p>
                <div id="missed-summary"></div>
                <div class="button-row">
                    <button id="review-missed" class="secondary-button" type="button" hidden>Review missed icons</button>
                    <button id="practice-again" class="primary-button" type="button">Practice again</button>
                </div>
            </div>
        </section>

        <section id="icon-choice-section" aria-labelledby="icon-grid-heading">
            <div class="section-heading-row">
                <h2 id="icon-grid-heading">Icon choices</h2>
                <span id="visible-count"></span>
            </div>
            <div id="icon-grid" class="icon-grid"></div>
            <p id="empty-state" class="empty-state" hidden>No icons are available here yet. Try another search or save an icon for review.</p>
        </section>
    </main>

    <footer>
        <p>Designed for calm, accessible learning. Learning data and display settings stay only in this browser.</p>
    </footer>

    <script src="04_Application/js/icons.js"></script>
    <script src="04_Application/js/app.js"></script>
</body>
</html>
'@

        $StylesPath = Join-Path $ResolvedRepositoryRoot '04_Application\css\styles.css'
        $ExistingStyles = Get-Content -LiteralPath $StylesPath -Raw
        $Phase2Styles = @'

/* Phase 2: guided practice and personalization */
:root[data-text-size="large"] {
    font-size: 21px;
}

:root[data-text-size="extra-large"] {
    font-size: 24px;
}

body.high-contrast {
    --sage: #285534;
    --sage-dark: #102D1A;
    --sage-soft: #E3F4E8;
    --warm-gray: #FFFFFF;
    --surface: #FFFFFF;
    --ink: #000000;
    --muted-ink: #202020;
    --border: #000000;
    --focus: #0047AB;
    --caution: #5A3500;
    --caution-bg: #FFF0A8;
    --success: #005A1C;
    --error: #8B0000;
}

.settings-panel,
.practice-panel {
    margin: 1rem 0 1.5rem;
    padding: 1rem 1.2rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.8rem;
    background: var(--surface);
}

.settings-panel summary {
    cursor: pointer;
    font-weight: 700;
}

.settings-controls {
    display: flex;
    flex-wrap: wrap;
    align-items: end;
    gap: 1rem;
    margin-top: 1rem;
}

.settings-controls label,
.practice-panel label {
    display: grid;
    gap: 0.35rem;
    font-weight: 700;
}

.settings-controls select,
.practice-panel select {
    min-width: 12rem;
    border: 0.1rem solid var(--border);
    border-radius: 0.45rem;
    padding: 0.6rem;
    background: var(--surface);
    color: var(--ink);
}

.settings-controls .checkbox-label {
    display: flex;
    align-items: center;
    min-height: 3rem;
}

.checkbox-label input {
    width: 1.35rem;
    height: 1.35rem;
    margin-right: 0.5rem;
}

.button-row {
    display: flex;
    flex-wrap: wrap;
    gap: 0.7rem;
    margin-top: 1rem;
}

.primary-button {
    margin-top: 1rem;
    border: 0.12rem solid var(--sage-dark);
    border-radius: 0.55rem;
    padding: 0.65rem 1.15rem;
    background: var(--sage-dark);
    color: #FFFFFF;
    font-weight: 700;
}

.practice-prompt {
    max-width: 46rem;
    font-size: 1.15rem;
    font-weight: 700;
}

.results-summary {
    font-size: 1.2rem;
    font-weight: 700;
}

.missed-list {
    margin: 0.5rem 0;
}

.icon-grid.practice-choices {
    grid-template-columns: repeat(2, minmax(9rem, 18rem));
    justify-content: start;
}

.icon-card.correct-answer {
    border-color: var(--success);
    border-width: 0.2rem;
    background: #E6F4EA;
}

.icon-card.incorrect-answer {
    border-color: var(--error);
    border-width: 0.2rem;
    background: #FCE8E8;
}

.icon-card.saved::after {
    content: "Saved for review";
    color: var(--muted-ink);
    font-size: 0.8rem;
    font-weight: 400;
}

@media (max-width: 460px) {
    .mode-selector,
    .settings-controls,
    .button-row {
        align-items: stretch;
        flex-direction: column;
    }

    .mode-button,
    .secondary-button,
    .primary-button {
        width: 100%;
    }

    .icon-grid.practice-choices {
        grid-template-columns: 1fr 1fr;
    }
}
'@

        if ($ExistingStyles -notmatch 'Phase 2: guided practice and personalization') {
            $ExistingStyles = $ExistingStyles.TrimEnd([char[]]@("`r", "`n")) + $Phase2Styles
        }

        $IconsScriptContent = @'
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
        volume: '<path d="M11 5 6 9H2v6h4l5 4Z"></path><path d="M15.5 8.5a5 5 0 0 1 0 7"></path><path d="M18 6a8.5 8.5 0 0 1 0 12"></path>',
        close: '<path d="M18 6 6 18"></path><path d="m6 6 12 12"></path>',
        forward: '<path d="M5 12h14"></path><path d="m12 5 7 7-7 7"></path>',
        refresh: '<path d="M20 7v5h-5"></path><path d="M4 17v-5h5"></path><path d="M6.1 9a7 7 0 0 1 11.7-2L20 12"></path><path d="M4 12l2.2 5a7 7 0 0 0 11.7-2"></path>',
        save: '<path d="M5 3h12l2 2v16H5Z"></path><path d="M8 3v6h8V3"></path><path d="M8 21v-7h8v7"></path>',
        print: '<path d="M6 9V3h12v6"></path><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><path d="M6 14h12v7H6Z"></path>',
        folder: '<path d="M3 5h7l2 2h9v12H3Z"></path>',
        document: '<path d="M6 2h8l4 4v16H6Z"></path><path d="M14 2v5h5"></path><path d="M9 13h6"></path><path d="M9 17h6"></path>',
        play: '<path d="m8 5 11 7-11 7Z"></path>',
        pause: '<path d="M8 5v14"></path><path d="M16 5v14"></path>',
        stop: '<rect x="5" y="5" width="14" height="14" rx="1"></rect>',
        phone: '<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.4 19.4 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.9a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.2-1.2a2 2 0 0 1 2.1-.5c.9.3 1.9.6 2.9.7a2 2 0 0 1 1.7 2Z"></path>',
        message: '<path d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4Z"></path>',
        send: '<path d="m22 2-7 20-4-9-9-4Z"></path><path d="M22 2 11 13"></path>',
        contacts: '<circle cx="9" cy="8" r="4"></circle><path d="M2 21a7 7 0 0 1 14 0"></path><path d="M17 7h5"></path><path d="M19.5 4.5v5"></path>',
        calendar: '<rect x="3" y="5" width="18" height="16" rx="2"></rect><path d="M16 3v4"></path><path d="M8 3v4"></path><path d="M3 11h18"></path>',
        help: '<circle cx="12" cy="12" r="10"></circle><path d="M9.5 9a3 3 0 1 1 4.2 2.8c-1.2.5-1.7 1.2-1.7 2.2"></path><circle cx="12" cy="18" r=".7" fill="currentColor"></circle>',
        information: '<circle cx="12" cy="12" r="10"></circle><path d="M12 11v6"></path><circle cx="12" cy="7" r=".7" fill="currentColor"></circle>',
        warning: '<path d="M12 3 2 21h20Z"></path><path d="M12 9v5"></path><circle cx="12" cy="18" r=".7" fill="currentColor"></circle>',
        location: '<path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="3"></circle>',
        bluetooth: '<path d="m7 7 10 10-5 4V3l5 4L7 17"></path>'
    };

    function render(name, label) {
        const content = paths[name] || paths.more;
        const accessibleLabel = label ? ' aria-label="' + label + '" role="img"' : ' aria-hidden="true"';
        return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"' + accessibleLabel + '>' + content + '</svg>';
    }

    return { render: render };
}());
'@

        $AppScriptContent = @'
'use strict';

(function () {
    const STORAGE_KEY = 'techsavvysage-icon-guide-progress-v2';
    const LEGACY_STORAGE_KEY = 'techsavvysage-icon-guide-progress-v1';
    const state = {
        icons: [],
        filteredIcons: [],
        viewed: new Set(),
        practiced: new Set(),
        review: new Set(),
        selectedId: null,
        mode: 'learn',
        reviewOverride: [],
        settings: { textSize: 'standard', highContrast: false },
        practiceOrder: [],
        practiceChoices: [],
        practiceIndex: 0,
        practiceAnswered: false,
        selectedAnswerId: null,
        correctCount: 0,
        missedIds: []
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

    function uniqueIds(values) {
        return Array.from(new Set(Array.isArray(values) ? values : []));
    }

    function loadProgress() {
        try {
            const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));

            if (saved) {
                state.viewed = new Set(uniqueIds(saved.viewed));
                state.practiced = new Set(uniqueIds(saved.practiced));
                state.review = new Set(uniqueIds(saved.review));
                state.settings.textSize = saved.settings && saved.settings.textSize
                    ? saved.settings.textSize
                    : 'standard';
                state.settings.highContrast = Boolean(saved.settings && saved.settings.highContrast);
                return;
            }

            const legacy = JSON.parse(localStorage.getItem(LEGACY_STORAGE_KEY));

            if (legacy) {
                state.viewed = new Set(uniqueIds(legacy.viewed));
            }
        }
        catch (error) {
            // The utility remains usable if browser storage is unavailable.
        }
    }

    function saveProgress() {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify({
                viewed: Array.from(state.viewed),
                practiced: Array.from(state.practiced),
                review: Array.from(state.review),
                settings: state.settings
            }));
        }
        catch (error) {
            // The utility remains usable if browser storage is unavailable.
        }
    }

    function setStatus(message) {
        elements.resultStatus.textContent = message;
    }

    function applyDisplaySettings() {
        document.documentElement.dataset.textSize = state.settings.textSize;
        document.body.classList.toggle('high-contrast', state.settings.highContrast);
        elements.textSize.value = state.settings.textSize;
        elements.highContrast.checked = state.settings.highContrast;
    }

    function updateProgress() {
        const count = state.viewed.size;
        const total = state.icons.length;
        elements.progressText.textContent = count + ' of ' + total + ' icons explored · ' + state.practiced.size + ' practiced · ' + state.review.size + ' saved';
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

        return [
            icon.name,
            icon.category,
            icon.meaning,
            icon.example,
            icon.caution || '',
            icon.search_terms.join(' ')
        ].join(' ').toLowerCase().includes(query);
    }

    function applyFilters() {
        const query = elements.iconSearch.value.trim().toLowerCase();
        const category = elements.categoryFilter.value;
        let sourceIcons = state.icons;

        if (state.mode === 'review') {
            const reviewIds = state.reviewOverride.length ? state.reviewOverride : Array.from(state.review);
            sourceIcons = state.icons.filter(function (icon) {
                return reviewIds.includes(icon.id);
            });
        }

        state.filteredIcons = sourceIcons.filter(function (icon) {
            const categoryMatches = category === 'all' || icon.category === category;
            return categoryMatches && matchesSearch(icon, query);
        });

        renderGrid();
        setStatus(state.filteredIcons.length + ' icon choices shown.');
    }

    function findIcon(id) {
        return state.icons.find(function (icon) {
            return icon.id === id;
        });
    }

    function shuffle(values) {
        const shuffled = values.slice();

        for (let index = shuffled.length - 1; index > 0; index -= 1) {
            const randomIndex = Math.floor(Math.random() * (index + 1));
            const currentValue = shuffled[index];
            shuffled[index] = shuffled[randomIndex];
            shuffled[randomIndex] = currentValue;
        }

        return shuffled;
    }

    function currentPracticeIcon() {
        return findIcon(state.practiceOrder[state.practiceIndex]);
    }

    function buildPracticeChoices(target) {
        const distractors = shuffle(state.icons.filter(function (icon) {
            return icon.id !== target.id;
        })).slice(0, 3);

        return shuffle([target].concat(distractors));
    }

    function createIconButton(icon) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'icon-card';
        button.dataset.iconId = icon.id;
        button.setAttribute('aria-label', icon.name + '. ' + icon.meaning);
        button.innerHTML = window.IconGuideIcons.render(icon.icon) + '<span>' + escapeHtml(icon.name) + '</span>';

        if (state.mode !== 'practice' && state.viewed.has(icon.id)) {
            button.classList.add('viewed');
        }

        if (state.mode !== 'practice' && state.review.has(icon.id)) {
            button.classList.remove('viewed');
            button.classList.add('saved');
        }

        if (state.mode !== 'practice' && state.selectedId === icon.id) {
            button.classList.add('selected');
            button.setAttribute('aria-current', 'true');
        }

        if (state.mode === 'practice' && state.practiceAnswered) {
            const target = currentPracticeIcon();
            button.disabled = true;

            if (icon.id === target.id) {
                button.classList.add('correct-answer');
                button.setAttribute('aria-label', icon.name + '. Correct answer.');
            }
            else if (icon.id === state.selectedAnswerId) {
                button.classList.add('incorrect-answer');
                button.setAttribute('aria-label', icon.name + '. Your answer.');
            }
        }

        return button;
    }

    function renderGrid() {
        elements.iconGrid.innerHTML = '';
        const practiceActive = state.mode === 'practice' && !elements.practiceQuestion.hidden;
        const iconsToRender = practiceActive ? state.practiceChoices : state.filteredIcons;

        elements.iconGrid.classList.toggle('practice-choices', practiceActive);
        elements.iconChoiceSection.hidden = state.mode === 'practice' && !practiceActive;

        iconsToRender.forEach(function (icon) {
            elements.iconGrid.appendChild(createIconButton(icon));
        });

        elements.visibleCount.textContent = iconsToRender.length + (practiceActive ? ' choices' : ' icons');
        elements.emptyState.hidden = iconsToRender.length !== 0;
    }

    function showIconDetail(icon) {
        if (!icon) {
            elements.learnDetail.hidden = true;
            return;
        }

        elements.learnDetail.hidden = false;
        state.selectedId = icon.id;
        state.viewed.add(icon.id);
        saveProgress();

        elements.detailIcon.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
        elements.detailCategory.textContent = icon.category + ' · ' + icon.devices.join(', ');
        elements.detailName.textContent = icon.name;
        elements.detailMeaning.textContent = icon.meaning;
        elements.detailExample.textContent = icon.example;
        elements.detailCaution.hidden = !icon.caution;
        elements.detailCaution.textContent = icon.caution ? 'Pause and notice: ' + icon.caution : '';
        elements.readAloud.dataset.iconId = icon.id;
        elements.practiceIcon.dataset.iconId = icon.id;
        elements.saveReview.dataset.iconId = icon.id;
        elements.saveReview.textContent = state.review.has(icon.id) ? 'Remove from review' : 'Save for review';
        updateProgress();
        renderGrid();
        setStatus(icon.name + ' selected.');
    }

    function updateModeButtons() {
        ['learn', 'practice', 'review'].forEach(function (mode) {
            const button = elements[mode + 'Mode'];
            const active = state.mode === mode;
            button.classList.toggle('active', active);
            button.setAttribute('aria-pressed', String(active));
        });
    }

    function setMode(mode) {
        state.mode = mode;
        updateModeButtons();
        const learning = mode === 'learn' || mode === 'review';
        elements.learnControls.hidden = !learning;
        elements.progressArea.hidden = !learning;
        elements.practiceDetail.hidden = mode !== 'practice';

        if (mode === 'practice') {
            elements.learnDetail.hidden = true;
            elements.practiceSetup.hidden = false;
            elements.practiceQuestion.hidden = true;
            elements.practiceResults.hidden = true;
            elements.iconChoiceSection.hidden = true;
            setStatus('Choose the number of practice questions when you are ready.');
            return;
        }

        if (mode === 'learn') {
            state.reviewOverride = [];
        }

        applyFilters();
        const firstAvailable = state.filteredIcons[0];
        const selected = state.filteredIcons.find(function (icon) {
            return icon.id === state.selectedId;
        }) || firstAvailable;
        showIconDetail(selected);
    }

    function startPractice(specificIds) {
        const sourceIds = Array.isArray(specificIds) && specificIds.length
            ? specificIds.slice()
            : shuffle(state.icons.map(function (icon) { return icon.id; }));
        const requested = elements.sessionLength.value === 'all'
            ? sourceIds.length
            : Number(elements.sessionLength.value);

        state.practiceOrder = sourceIds.slice(0, Math.min(requested, sourceIds.length));
        state.practiceIndex = 0;
        state.correctCount = 0;
        state.missedIds = [];
        elements.practiceSetup.hidden = true;
        elements.practiceResults.hidden = true;
        elements.practiceQuestion.hidden = false;
        showPracticeQuestion();
    }

    function showPracticeQuestion() {
        const target = currentPracticeIcon();
        state.practiceAnswered = false;
        state.selectedAnswerId = null;
        state.practiceChoices = buildPracticeChoices(target);
        elements.practiceNumber.textContent = 'Question ' + (state.practiceIndex + 1) + ' of ' + state.practiceOrder.length;
        elements.practicePrompt.textContent = target.meaning;
        elements.practiceFeedback.textContent = '';
        elements.practiceFeedback.className = 'practice-feedback';
        elements.nextQuestion.hidden = true;
        elements.nextQuestion.textContent = state.practiceIndex === state.practiceOrder.length - 1
            ? 'See results'
            : 'Next question';
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
        state.selectedAnswerId = icon.id;
        state.practiced.add(target.id);

        if (correct) {
            state.correctCount += 1;
        }
        else if (!state.missedIds.includes(target.id)) {
            state.missedIds.push(target.id);
        }

        saveProgress();
        updateProgress();
        elements.practiceFeedback.textContent = correct
            ? 'That’s right. This is the ' + target.name + ' icon.'
            : 'Good try. The correct answer is ' + target.name + '.';
        elements.practiceFeedback.classList.add(correct ? 'correct' : 'try-again');
        elements.nextQuestion.hidden = false;
        renderGrid();
        elements.nextQuestion.focus();
    }

    function showPracticeResults() {
        elements.practiceQuestion.hidden = true;
        elements.practiceResults.hidden = false;
        elements.iconChoiceSection.hidden = true;
        elements.resultsSummary.textContent = 'You completed ' + state.practiceOrder.length + ' questions and matched ' + state.correctCount + ' correctly.';
        elements.reviewMissed.hidden = state.missedIds.length === 0;

        if (state.missedIds.length === 0) {
            elements.missedSummary.innerHTML = '<p>You recognized every icon in this session. Nicely done.</p>';
        }
        else {
            const missedNames = state.missedIds.map(function (id) {
                return escapeHtml(findIcon(id).name);
            });
            elements.missedSummary.innerHTML = '<p>Ready to review: ' + missedNames.join(', ') + '.</p>';
        }

        setStatus('Practice session complete.');
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

    function toggleReview() {
        const id = elements.saveReview.dataset.iconId;

        if (state.review.has(id)) {
            state.review.delete(id);
            setStatus('Icon removed from the review list.');
        }
        else {
            state.review.add(id);
            setStatus('Icon saved for review.');
        }

        saveProgress();
        updateProgress();
        showIconDetail(findIcon(id));
    }

    function clearProgress() {
        if (!window.confirm('Clear explored icons, practiced icons, and the saved review list from this browser?')) {
            return;
        }

        state.viewed.clear();
        state.practiced.clear();
        state.review.clear();
        state.reviewOverride = [];
        saveProgress();
        updateProgress();
        applyFilters();
        setStatus('Learning data cleared. Display settings were kept.');
    }

    function resetDisplaySettings() {
        state.settings = { textSize: 'standard', highContrast: false };
        applyDisplaySettings();
        saveProgress();
        setStatus('Display settings reset.');
    }

    function bindEvents() {
        elements.learnMode.addEventListener('click', function () { setMode('learn'); });
        elements.practiceMode.addEventListener('click', function () { setMode('practice'); });
        elements.reviewMode.addEventListener('click', function () { setMode('review'); });
        elements.iconSearch.addEventListener('input', applyFilters);
        elements.categoryFilter.addEventListener('change', applyFilters);
        elements.readAloud.addEventListener('click', readSelectedAloud);
        elements.saveReview.addEventListener('click', toggleReview);
        elements.practiceIcon.addEventListener('click', function () {
            const id = elements.practiceIcon.dataset.iconId;
            setMode('practice');
            startPractice([id]);
        });
        elements.clearProgress.addEventListener('click', clearProgress);
        elements.startPractice.addEventListener('click', function () { startPractice(); });
        elements.practiceAgain.addEventListener('click', function () {
            elements.practiceResults.hidden = true;
            elements.practiceSetup.hidden = false;
            elements.iconChoiceSection.hidden = true;
            elements.startPractice.focus();
        });
        elements.reviewMissed.addEventListener('click', function () {
            state.reviewOverride = state.missedIds.slice();
            setMode('review');
        });
        elements.nextQuestion.addEventListener('click', function () {
            if (state.practiceIndex >= state.practiceOrder.length - 1) {
                showPracticeResults();
                return;
            }

            state.practiceIndex += 1;
            showPracticeQuestion();
        });
        elements.textSize.addEventListener('change', function (event) {
            state.settings.textSize = event.target.value;
            applyDisplaySettings();
            saveProgress();
            setStatus('Text size updated.');
        });
        elements.highContrast.addEventListener('change', function (event) {
            state.settings.highContrast = event.target.checked;
            applyDisplaySettings();
            saveProgress();
            setStatus('Contrast setting updated.');
        });
        elements.resetDisplay.addEventListener('click', resetDisplaySettings);
        elements.iconGrid.addEventListener('click', function (event) {
            const button = event.target.closest('[data-icon-id]');

            if (!button) {
                return;
            }

            const icon = findIcon(button.dataset.iconId);

            if (state.mode === 'practice') {
                answerPractice(icon);
            }
            else {
                showIconDetail(icon);
            }
        });
    }

    function captureElements() {
        const ids = [
            'learn-mode', 'practice-mode', 'review-mode', 'text-size', 'high-contrast',
            'reset-display', 'learn-controls', 'icon-search', 'category-filter',
            'progress-area', 'progress-text', 'learning-progress', 'clear-progress',
            'result-status', 'learn-detail', 'detail-icon', 'detail-category',
            'detail-name', 'detail-meaning', 'detail-example', 'detail-caution',
            'read-aloud', 'save-review', 'practice-icon', 'practice-detail',
            'practice-setup', 'session-length', 'start-practice', 'practice-question',
            'practice-number', 'practice-prompt', 'practice-feedback', 'next-question',
            'practice-results', 'results-summary', 'missed-summary', 'review-missed',
            'practice-again', 'icon-choice-section', 'icon-grid', 'visible-count',
            'empty-state'
        ];

        ids.forEach(function (id) {
            const propertyName = id.replace(/-([a-z])/g, function (match, letter) {
                return letter.toUpperCase();
            });
            elements[propertyName] = document.getElementById(id);
        });
    }

    async function initialize() {
        captureElements();
        loadProgress();
        applyDisplaySettings();

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
            applyFilters();
            showIconDetail(state.icons[0]);

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

        $ManifestContent = @'
{
  "name": "TechSavvySage Icon Guide",
  "short_name": "Icon Guide",
  "description": "Accessible, untimed learning and guided practice for 40 common computer and mobile icons.",
  "id": "./",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "background_color": "#F4F1EC",
  "theme_color": "#607D68",
  "lang": "en-US",
  "icons": [
    {
      "src": "04_Application/assets/app-icons/icon-guide-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "04_Application/assets/app-icons/icon-guide-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
'@

        $ServiceWorkerContent = @'
'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v0.2.0';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/icons.js',
    './04_Application/js/app.js',
    './04_Application/data/icons.json',
    './04_Application/assets/app-icons/icon-guide-192.png',
    './04_Application/assets/app-icons/icon-guide-512.png'
];

self.addEventListener('install', function (event) {
    event.waitUntil(caches.open(CACHE_NAME).then(function (cache) {
        return cache.addAll(CORE_ASSETS);
    }));
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    event.waitUntil(caches.keys().then(function (cacheNames) {
        return Promise.all(cacheNames.filter(function (cacheName) {
            return cacheName !== CACHE_NAME;
        }).map(function (cacheName) {
            return caches.delete(cacheName);
        }));
    }));
    self.clients.claim();
});

self.addEventListener('fetch', function (event) {
    if (event.request.method !== 'GET') {
        return;
    }

    event.respondWith(caches.match(event.request).then(function (cachedResponse) {
        return cachedResponse || fetch(event.request);
    }));
});
'@

        $Phase2UserGuide = @'
# Phase 2 Guided Practice User Guide

## Learn

Use search or category filters to explore any of the 40 icons. Select **Read explanation aloud**, **Save for review**, or **Practice this icon** when helpful.

## Practice

Choose a session of 5, 10, 20, or all 40 icons. Each question and its four answer choices are randomized. Questions do not repeat within a session. At the end, review the supportive summary and select **Review missed icons** when needed.

## Saved for review

Select **Save for review** from an icon explanation. Open **Saved for review** to create a personal study list. Saved items stay only in the current browser.

## Display settings

Choose Standard, Large, or Extra Large text and optionally enable high contrast. These settings remain in the current browser until reset.

## Privacy

The utility requires no account and collects no personally identifiable information. Learning data and preferences remain in local browser storage and can be cleared by the learner.
'@

        $Phase2Checklist = @'
# Phase 2 Validation Checklist

## Content and practice

- [ ] All 40 unique icons display with meanings, examples, and safety notes where appropriate.
- [ ] Practice offers 5, 10, 20, and all-icon sessions.
- [ ] Every question displays exactly four answer choices.
- [ ] Questions and answer choices are randomized.
- [ ] Questions do not repeat within a session.
- [ ] Results report questions completed and correct matches.
- [ ] Missed icons can be opened for review.
- [ ] Practice remains untimed and uses supportive feedback.

## Personalization and privacy

- [ ] Icons can be saved and removed from the review list.
- [ ] Explored, practiced, and saved counts persist after refresh.
- [ ] Standard, Large, and Extra Large text settings work and persist.
- [ ] High contrast works and persists.
- [ ] Reset display settings works.
- [ ] Clear learning data requires confirmation.
- [ ] No account or personally identifiable information is requested.

## Accessibility and delivery

- [ ] Complete Learn, Practice, and Saved for review using only a keyboard.
- [ ] Screen-reader labels identify choices and answer state.
- [ ] Controls remain usable at 200 percent zoom and a 320-pixel viewport.
- [ ] Reduced-motion preference is honored.
- [ ] The installable manifest includes 192-pixel and 512-pixel icons.
- [ ] The utility loads offline after one successful online visit.
- [ ] Edge, Chrome, Safari, and mobile browsers complete smoke testing.
'@

        $ReleaseNotes = @'
# TechSavvySage Icon Guide v0.2.0 Release Notes

Phase 2 expands the guide from 20 to 40 icons and introduces guided practice and personalization.

## Added

- Four-choice practice sessions containing 5, 10, 20, or all icons.
- Randomized questions and choices without repetition inside a session.
- Supportive results and missed-icon review.
- Saved-for-review learning lists.
- Practiced-icon progress tracking.
- Standard, Large, and Extra Large text settings.
- Optional high-contrast display.
- Installable 192-pixel and 512-pixel application icons.

## Privacy

All progress and display preferences remain in the learner’s browser. Phase 2 adds no accounts, cloud synchronization, analytics, or personally identifiable information collection.
'@

        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot 'index.html') -Content $IndexContent
        Write-Utf8File -Path $StylesPath -Content $ExistingStyles
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot '04_Application\js\icons.js') -Content $IconsScriptContent
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js') -Content $AppScriptContent

        $IconDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\icons.json'
        $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
        $ExistingIds = @($IconData.icons | ForEach-Object { $_.id })
        $AdditionalIconsJson = @'
[
  {"id":"close","name":"Close","icon":"close","category":"Navigation","devices":["Computer","iPhone","Android"],"meaning":"Closes a window, message, menu, or screen.","example":"Use Close when you are finished with a pop-up or want to dismiss a screen.","caution":"Closing a document may prompt you to save changes first.","search_terms":["x","exit","dismiss","window"],"audio_text":"The Close icon closes a window, message, menu, or screen. Save important changes before closing a document."},
  {"id":"forward","name":"Forward","icon":"forward","category":"Navigation","devices":["Computer","iPhone","Android"],"meaning":"Moves to the next page or returns to a page after using Back.","example":"Use Forward in a browser after going back to the previous page.","caution":"In messages, a similar arrow may send content to another person.","search_terms":["next","right","browser","arrow"],"audio_text":"The Forward icon moves to the next page or returns to a page after using Back."},
  {"id":"refresh","name":"Refresh","icon":"refresh","category":"Navigation","devices":["Computer","iPhone","Android"],"meaning":"Loads the current page or information again.","example":"Use Refresh when a webpage looks outdated or did not finish loading.","caution":"Refreshing a form may clear information you have entered.","search_terms":["reload","update","again","circle"],"audio_text":"The Refresh icon loads the current page or information again. A form may clear when refreshed."},
  {"id":"save","name":"Save","icon":"save","category":"Files","devices":["Computer"],"meaning":"Stores your current work so you can use it later.","example":"Use Save after editing a document, spreadsheet, or picture.","caution":"Check the folder and filename so you can find the saved item later.","search_terms":["disk","store","keep","document"],"audio_text":"The Save icon stores your current work. Check the folder and filename so you can find it later."},
  {"id":"print","name":"Print","icon":"print","category":"Files","devices":["Computer","iPhone","Android"],"meaning":"Sends a document or picture to a printer.","example":"Use Print when you need a paper copy of a document or confirmation.","caution":"Review the printer, page count, and number of copies before confirming.","search_terms":["paper","printer","copy"],"audio_text":"The Print icon sends a document or picture to a printer. Review the page count and number of copies."},
  {"id":"folder","name":"Folder","icon":"folder","category":"Files","devices":["Computer","iPhone","Android"],"meaning":"Contains files or other folders.","example":"Open a Folder to find saved documents, photographs, or downloads.","caution":"Moving or deleting a folder may affect everything stored inside it.","search_terms":["directory","files","organize","documents"],"audio_text":"The Folder icon contains files or other folders. Moving or deleting it may affect everything inside."},
  {"id":"document","name":"Document","icon":"document","category":"Files","devices":["Computer","iPhone","Android"],"meaning":"Represents a file containing text or other information.","example":"Select Document to open, edit, share, or review a file.","caution":"Open unexpected documents carefully, especially when received from an unknown sender.","search_terms":["file","page","paper","text"],"audio_text":"The Document icon represents a file containing text or other information. Be careful with unexpected files."},
  {"id":"play","name":"Play","icon":"play","category":"Media","devices":["Computer","iPhone","Android"],"meaning":"Starts a video, recording, song, or animation.","example":"Use Play to begin watching or listening.","caution":"Check your volume before starting media in a shared space.","search_terms":["start","video","music","triangle"],"audio_text":"The Play icon starts a video, recording, song, or animation. Check the volume first."},
  {"id":"pause","name":"Pause","icon":"pause","category":"Media","devices":["Computer","iPhone","Android"],"meaning":"Temporarily stops media while keeping your place.","example":"Use Pause when you want to stop briefly and continue later.","caution":"Pause does not always stop a live call or microphone.","search_terms":["wait","hold","video","music"],"audio_text":"The Pause icon temporarily stops media while keeping your place."},
  {"id":"stop","name":"Stop","icon":"stop","category":"Media","devices":["Computer","iPhone","Android"],"meaning":"Ends playback, recording, or another active process.","example":"Use Stop to finish an audio recording or end media playback.","caution":"Stopping a recording may finish the file and require you to start a new one.","search_terms":["end","square","recording","media"],"audio_text":"The Stop icon ends playback, recording, or another active process."},
  {"id":"phone","name":"Phone","icon":"phone","category":"Communication","devices":["Computer","iPhone","Android"],"meaning":"Starts or represents a telephone or internet call.","example":"Use Phone to call a contact or join an audio meeting.","caution":"Confirm the contact before calling or returning an unfamiliar number.","search_terms":["call","telephone","handset","dial"],"audio_text":"The Phone icon starts or represents a call. Confirm the contact before calling an unfamiliar number."},
  {"id":"message","name":"Message","icon":"message","category":"Communication","devices":["Computer","iPhone","Android"],"meaning":"Opens text messages, chat, or a conversation.","example":"Use Message to read or send a text or chat response.","caution":"Do not send passwords, verification codes, or sensitive information to unverified contacts.","search_terms":["chat","text","bubble","conversation"],"audio_text":"The Message icon opens text messages or chat. Do not send passwords or verification codes to unverified contacts."},
  {"id":"send","name":"Send","icon":"send","category":"Communication","devices":["Computer","iPhone","Android"],"meaning":"Delivers a message, email, form, or file.","example":"Use Send after reviewing a message and its recipients.","caution":"Sending may be difficult to undo. Review the recipient and attachments first.","search_terms":["paper plane","email","submit","deliver"],"audio_text":"The Send icon delivers a message, email, form, or file. Review recipients and attachments first."},
  {"id":"contacts","name":"Contacts","icon":"contacts","category":"Communication","devices":["Computer","iPhone","Android"],"meaning":"Opens saved names, phone numbers, and contact details.","example":"Use Contacts to find a person before calling or messaging them.","caution":"Apps may request access to your contacts. Allow it only when needed.","search_terms":["people","address book","person","phonebook"],"audio_text":"The Contacts icon opens saved names and contact details. Review requests for contact access."},
  {"id":"calendar","name":"Calendar","icon":"calendar","category":"Productivity","devices":["Computer","iPhone","Android"],"meaning":"Shows dates, appointments, reminders, and scheduled events.","example":"Use Calendar to check an appointment or create an event.","caution":"Review the date, time, time zone, and guests before saving an event.","search_terms":["date","schedule","appointment","event"],"audio_text":"The Calendar icon shows dates and scheduled events. Review the date, time, time zone, and guests."},
  {"id":"help","name":"Help","icon":"help","category":"Safety","devices":["Computer","iPhone","Android"],"meaning":"Opens instructions, support information, or answers to common questions.","example":"Use Help when you need guidance about an app or website.","caution":"Use support links inside the official app or website rather than unexpected pop-ups.","search_terms":["question","support","instructions","faq"],"audio_text":"The Help icon opens instructions or support information. Prefer support links inside the official app or website."},
  {"id":"information","name":"Information","icon":"information","category":"Safety","devices":["Computer","iPhone","Android"],"meaning":"Shows additional details about an item, setting, or situation.","example":"Use Information to learn why a notice appeared or view details about a file.","caution":"Information explains something but does not always mean it is approved or safe.","search_terms":["info","details","about","notice"],"audio_text":"The Information icon shows additional details about an item, setting, or situation."},
  {"id":"warning","name":"Warning","icon":"warning","category":"Safety","devices":["Computer","iPhone","Android"],"meaning":"Signals that something needs attention before you continue.","example":"Pause at a Warning icon and read the complete message before choosing an action.","caution":"Do not let urgent wording pressure you. Close suspicious messages and verify through a trusted source.","search_terms":["alert","danger","caution","triangle","risk"],"audio_text":"The Warning icon signals that something needs attention. Pause, read the message, and verify suspicious requests."},
  {"id":"location","name":"Location","icon":"location","category":"Device","devices":["Computer","iPhone","Android"],"meaning":"Shows a place or indicates that an app may use your location.","example":"Use Location for maps, directions, weather, or nearby services.","caution":"Allow location access only when needed and choose approximate location when sufficient.","search_terms":["map","pin","gps","place","directions"],"audio_text":"The Location icon shows a place or location access. Allow location only when needed."},
  {"id":"bluetooth","name":"Bluetooth","icon":"bluetooth","category":"Device","devices":["Computer","iPhone","Android"],"meaning":"Connects nearby wireless devices such as headphones, keyboards, or cars.","example":"Use Bluetooth settings to pair a trusted nearby device.","caution":"Confirm the device name before pairing and reject unexpected pairing requests.","search_terms":["wireless","pair","headphones","device","car"],"audio_text":"The Bluetooth icon connects nearby wireless devices. Confirm the device name before pairing."}
]
'@

        $AdditionalIcons = $AdditionalIconsJson | ConvertFrom-Json

        foreach ($AdditionalIcon in $AdditionalIcons) {
            if ($ExistingIds -notcontains $AdditionalIcon.id) {
                $IconData.icons += $AdditionalIcon
            }
        }

        $IconData.schema_version = '2.0.0'
        Write-Utf8File -Path $IconDataPath -Content ($IconData | ConvertTo-Json -Depth 10)
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot 'manifest.webmanifest') -Content $ManifestContent
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot 'service-worker.js') -Content $ServiceWorkerContent
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_2_Guided_Practice_User_Guide.md') -Content $Phase2UserGuide
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot '05_Testing\Phase_2_Validation_Checklist.md') -Content $Phase2Checklist
        Write-Utf8File -Path (Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_2_Release_Notes.md') -Content $ReleaseNotes

        Write-AppIcon -Path (Join-Path $AssetRoot 'icon-guide-192.png') -Size 192
        Write-AppIcon -Path (Join-Path $AssetRoot 'icon-guide-512.png') -Size 512

        $CanonicalBuilderPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase2.ps1'
        $CurrentScriptPath = Get-NormalizedPath -Path $MyInvocation.MyCommand.Path

        if ($CurrentScriptPath -ne (Get-NormalizedPath -Path $CanonicalBuilderPath)) {
            Copy-Item -LiteralPath $CurrentScriptPath -Destination $CanonicalBuilderPath -Force
            Write-Status -Level 'REPLACE' -Message $CanonicalBuilderPath
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. File generation was skipped.'
    }

    Write-Section -Text 'Phase 2C - Release Validation'

    $ValidationSucceeded = $true
    $RequiredFiles = @(
        'index.html',
        '04_Application\css\styles.css',
        '04_Application\data\icons.json',
        '04_Application\js\app.js',
        '04_Application\js\icons.js',
        '04_Application\assets\app-icons\icon-guide-192.png',
        '04_Application\assets\app-icons\icon-guide-512.png',
        'manifest.webmanifest',
        'service-worker.js',
        '01_Documentation\Phase_2_Guided_Practice_User_Guide.md',
        '01_Documentation\Phase_2_Release_Notes.md',
        '05_Testing\Phase_2_Validation_Checklist.md',
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase2.ps1'
    )

    foreach ($RelativePath in $RequiredFiles) {
        if (-not (Test-RequiredFile -Path (Join-Path $ResolvedRepositoryRoot $RelativePath))) {
            $ValidationSucceeded = $false
        }
    }

    $IconDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\icons.json'

    if (Test-Path -LiteralPath $IconDataPath -PathType Leaf) {
        $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
        $IconCount = @($IconData.icons).Count
        $DuplicateIds = @($IconData.icons | Group-Object id | Where-Object { $_.Count -gt 1 })

        if ($IconCount -ne 40) {
            Write-Status -Level 'FAIL' -Message "Expected 40 icons; found $IconCount."
            $ValidationSucceeded = $false
        }
        elseif ($DuplicateIds.Count -gt 0) {
            Write-Status -Level 'FAIL' -Message 'Duplicate icon identifiers were detected.'
            $ValidationSucceeded = $false
        }
        else {
            Write-Status -Level 'PASS' -Message 'Icon data contains 40 unique records.'
        }
    }

    $IndexPath = Join-Path $ResolvedRepositoryRoot 'index.html'
    $AppPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'
    $ManifestPath = Join-Path $ResolvedRepositoryRoot 'manifest.webmanifest'

    if (Test-Path -LiteralPath $IndexPath -PathType Leaf) {
        $IndexContent = Get-Content -LiteralPath $IndexPath -Raw

        foreach ($Id in @('review-mode', 'text-size', 'high-contrast', 'save-review', 'practice-icon', 'session-length', 'practice-results', 'review-missed')) {
            if ($IndexContent -notmatch ('id="{0}"' -f [regex]::Escape($Id))) {
                Write-Status -Level 'FAIL' -Message "Required Phase 2 element is missing: $Id"
                $ValidationSucceeded = $false
            }
        }
    }

    if (Test-Path -LiteralPath $AppPath -PathType Leaf) {
        $AppContent = Get-Content -LiteralPath $AppPath -Raw

        foreach ($Capability in @('buildPracticeChoices', 'showPracticeResults', 'reviewOverride', 'applyDisplaySettings', 'practiceChoices')) {
            if ($AppContent -notmatch [regex]::Escape($Capability)) {
                Write-Status -Level 'FAIL' -Message "Required Phase 2 capability is missing: $Capability"
                $ValidationSucceeded = $false
            }
        }
    }

    if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
        $Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

        if (@($Manifest.icons).Count -lt 2) {
            Write-Status -Level 'FAIL' -Message 'The installable manifest requires two application icons.'
            $ValidationSucceeded = $false
        }
        else {
            Write-Status -Level 'PASS' -Message 'Installable manifest contains application icons.'
        }
    }

    Write-Section -Text 'Phase 2 Execution Metrics'
    Write-Metric -Name 'Created folders' -Value $Script:CreatedFolders
    Write-Metric -Name 'Existing folders' -Value $Script:ExistingFolders
    Write-Metric -Name 'Created files' -Value $Script:CreatedFiles
    Write-Metric -Name 'Replaced files' -Value $Script:ReplacedFiles
    Write-Metric -Name 'Validated files' -Value $Script:ValidatedFiles
    Write-Metric -Name 'Missing files' -Value $Script:MissingFiles

    if (-not $ValidationSucceeded) {
        throw 'Phase 2 validation failed.'
    }

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 2 COMPLETE'
    Write-Status -Level 'PASS' -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 2 ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
