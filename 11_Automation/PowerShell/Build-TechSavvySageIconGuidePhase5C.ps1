# =====================================================================
# Build-TechSavvySageIconGuidePhase5C.ps1
# Phase 5C - Pre-Pilot Accessibility and Usability Hardening
# =====================================================================

[CmdletBinding()]
param (
    [ValidateSet('Build', 'ValidateOnly')]
    [string]$Mode = 'Build',
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
        throw 'Unable to determine the script directory. Supply -RepositoryRoot.'
    }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
}

function Set-Utf8File {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )
    $Directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }
    $Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, ($Content.TrimEnd() + [Environment]::NewLine), $Utf8WithoutBom)
}

function Set-ControlledBlock {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$StartMarker,
        [Parameter(Mandatory)][string]$EndMarker,
        [Parameter(Mandatory)][string]$Block
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Controlled file is missing: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw
    $ControlledBlock = $StartMarker + [Environment]::NewLine + $Block.Trim() + [Environment]::NewLine + $EndMarker

    if ($Content.Contains($StartMarker) -and $Content.Contains($EndMarker)) {
        $Pattern = '(?s)' + [regex]::Escape($StartMarker) + '.*?' + [regex]::Escape($EndMarker)
        $Updated = [regex]::Replace($Content, $Pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($Match) $ControlledBlock }, 1)
    }
    elseif (-not $Content.Contains($StartMarker) -and -not $Content.Contains($EndMarker)) {
        $Updated = $Content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $ControlledBlock + [Environment]::NewLine
    }
    else {
        throw "An incomplete controlled marker pair exists in $Path."
    }

    Set-Utf8File -Path $Path -Content $Updated
}

function Get-StartHereJavaScript {
    return @'
(() => {
    'use strict';

    const phase5cId = 'phase-5c-start-here';
    const sessionKey = 'techsavvysage-start-here-seen';

    function createElement(tagName, properties = {}) {
        const element = document.createElement(tagName);
        Object.entries(properties).forEach(([name, value]) => {
            if (name === 'textContent') {
                element.textContent = value;
            } else if (name === 'className') {
                element.className = value;
            } else {
                element.setAttribute(name, value);
            }
        });
        return element;
    }

    function initializeStartHere() {
        if (document.getElementById(phase5cId)) {
            return;
        }

        const learningNavigation = document.querySelector('[aria-label="Learning mode"]');
        if (!learningNavigation) {
            return;
        }

        const startButton = createElement('button', {
            type: 'button',
            id: 'start-here-button',
            textContent: 'Start Here',
            'aria-haspopup': 'dialog',
            'aria-expanded': 'false'
        });
        learningNavigation.insertBefore(startButton, learningNavigation.firstChild);

        const overlay = createElement('div', {
            id: phase5cId,
            className: 'start-here-overlay',
            hidden: ''
        });
        const dialog = createElement('section', {
            className: 'start-here-dialog',
            role: 'dialog',
            'aria-modal': 'true',
            'aria-labelledby': 'start-here-heading',
            'aria-describedby': 'start-here-description'
        });
        const eyebrow = createElement('p', {
            className: 'start-here-eyebrow',
            textContent: 'A calm place to begin'
        });
        const heading = createElement('h2', {
            id: 'start-here-heading',
            tabindex: '-1',
            textContent: 'Start Here'
        });
        const description = createElement('p', {
            id: 'start-here-description',
            textContent: 'Choose the kind of learning that feels right today. There is no timer and no penalty for trying.'
        });
        const list = createElement('ol', { className: 'start-here-list' });
        [
            ['Learn', 'Explore any of the 40 icons and hear a plain-language explanation.'],
            ['Lessons', 'Follow a guided set of icon steps, then try a short knowledge check.'],
            ['Practice', 'Choose the icon that matches a meaning and receive supportive feedback.'],
            ['Saved for review', 'Return to icons you chose to keep for later.']
        ].forEach(([title, explanation]) => {
            const item = createElement('li');
            const strong = createElement('strong', { textContent: `${title}: ` });
            item.append(strong, document.createTextNode(explanation));
            list.appendChild(item);
        });

        const actions = createElement('div', { className: 'start-here-actions' });
        const lessonButton = createElement('button', {
            type: 'button',
            className: 'primary-button',
            textContent: 'Start with a lesson'
        });
        const learnButton = createElement('button', {
            type: 'button',
            className: 'secondary-button',
            textContent: 'Explore icons'
        });
        const closeButton = createElement('button', {
            type: 'button',
            className: 'text-button',
            textContent: 'Close'
        });
        actions.append(lessonButton, learnButton, closeButton);
        dialog.append(eyebrow, heading, description, list, actions);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);

        const pageRegions = Array.from(document.querySelectorAll('header, main, footer'));
        let priorFocus = null;

        function openDialog() {
            priorFocus = document.activeElement;
            overlay.hidden = false;
            document.body.classList.add('start-here-open');
            startButton.setAttribute('aria-expanded', 'true');
            pageRegions.forEach((region) => { region.inert = true; });
            heading.focus();
        }

        function closeDialog() {
            overlay.hidden = true;
            document.body.classList.remove('start-here-open');
            startButton.setAttribute('aria-expanded', 'false');
            pageRegions.forEach((region) => { region.inert = false; });
            const returnTarget = priorFocus && document.contains(priorFocus)
                ? priorFocus
                : startButton;
            returnTarget.focus();
        }

        function activateMode(label) {
            closeDialog();
            const modeButton = Array.from(learningNavigation.querySelectorAll('button'))
                .find((button) => button.textContent.trim() === label);
            if (modeButton) {
                modeButton.click();
            }
        }

        startButton.addEventListener('click', openDialog);
        closeButton.addEventListener('click', closeDialog);
        lessonButton.addEventListener('click', () => activateMode('Lessons'));
        learnButton.addEventListener('click', () => activateMode('Learn'));
        overlay.addEventListener('click', (event) => {
            if (event.target === overlay) {
                closeDialog();
            }
        });
        dialog.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                event.preventDefault();
                closeDialog();
                return;
            }
            if (event.key !== 'Tab') {
                return;
            }
            const focusable = Array.from(dialog.querySelectorAll('button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'));
            if (focusable.length === 0) {
                return;
            }
            const first = focusable[0];
            const last = focusable[focusable.length - 1];
            if (event.shiftKey && document.activeElement === first) {
                event.preventDefault();
                last.focus();
            } else if (!event.shiftKey && document.activeElement === last) {
                event.preventDefault();
                first.focus();
            }
        });

        let showAutomatically = true;
        try {
            showAutomatically = sessionStorage.getItem(sessionKey) !== 'true';
            if (showAutomatically) {
                sessionStorage.setItem(sessionKey, 'true');
            }
        } catch (error) {
            showAutomatically = false;
        }
        if (showAutomatically) {
            window.setTimeout(openDialog, 0);
        }
    }

    function initializeConnectionStatus() {
        if (document.getElementById('connection-status')) {
            return;
        }
        const status = createElement('p', {
            id: 'connection-status',
            className: 'connection-status',
            role: 'status',
            'aria-live': 'polite'
        });
        status.hidden = true;
        const main = document.querySelector('main');
        if (main) {
            main.insertBefore(status, main.firstChild);
        }
        function showStatus(message) {
            status.textContent = message;
            status.hidden = false;
        }
        window.addEventListener('offline', () => {
            showStatus('You are offline. Previously loaded learning content remains available.');
        });
        window.addEventListener('online', () => {
            showStatus('Connection restored.');
            window.setTimeout(() => { status.hidden = true; }, 5000);
        });
        if (!navigator.onLine) {
            showStatus('You are offline. Previously loaded learning content remains available.');
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            initializeStartHere();
            initializeConnectionStatus();
        }, { once: true });
    } else {
        initializeStartHere();
        initializeConnectionStatus();
    }
})();
'@
}

function Get-StartHereCss {
    return @'
.start-here-open {
    overflow: hidden;
}

.start-here-overlay {
    position: fixed;
    inset: 0;
    z-index: 1000;
    display: grid;
    place-items: center;
    padding: 1rem;
    background: rgb(15 23 42 / 72%);
}

.start-here-overlay[hidden] {
    display: none;
}

.start-here-dialog {
    width: min(42rem, 100%);
    max-height: calc(100vh - 2rem);
    overflow: auto;
    padding: clamp(1.25rem, 3vw, 2rem);
    border: 2px solid var(--border-color, #64748b);
    border-radius: 1rem;
    background: var(--surface-color, #ffffff);
    color: var(--text-color, #172033);
    box-shadow: 0 1.5rem 4rem rgb(15 23 42 / 35%);
}

.start-here-eyebrow {
    margin: 0 0 0.35rem;
    font-weight: 700;
}

.start-here-dialog h2 {
    margin-top: 0;
}

.start-here-list {
    display: grid;
    gap: 0.75rem;
    padding-left: 1.5rem;
}

.start-here-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-top: 1.5rem;
}

.connection-status {
    margin: 0 auto 1rem;
    padding: 0.75rem 1rem;
    border: 2px solid currentColor;
    border-radius: 0.75rem;
    font-weight: 700;
    text-align: center;
}

@media (max-width: 320px) {
    .start-here-overlay {
        align-items: start;
        padding: 0.5rem;
    }

    .start-here-dialog {
        max-height: calc(100vh - 1rem);
        padding: 1rem;
        border-radius: 0.75rem;
    }

    .start-here-actions,
    .start-here-actions button {
        width: 100%;
    }
}

@media (prefers-reduced-motion: reduce) {
    .start-here-overlay,
    .start-here-dialog {
        scroll-behavior: auto;
        transition: none !important;
        animation: none !important;
    }
}

@media (forced-colors: active) {
    .start-here-overlay {
        background: Canvas;
    }

    .start-here-dialog,
    .connection-status {
        border-color: CanvasText;
    }
}
'@
}

function Get-PhaseDocumentation {
    return @{
        '01_Documentation\Phase_5C_Pre_Pilot_Hardening.md' = @'
# Phase 5C Pre-Pilot Accessibility and Usability Hardening

## Purpose

Phase 5C improves objective accessibility, navigation, and resilience before human pilot participants are available. It does not claim human usability validation and does not replace the Phase 5A/5B rolling-cohort pilot.

## Implemented changes

- Adds a visible **Start Here** entry to the Learning mode navigation.
- Opens the orientation once per browser-tab session using session storage only.
- Explains Learn, Lessons, Practice, and Saved for review in plain language.
- Provides direct actions to start a lesson or explore icons.
- Traps keyboard focus inside the open dialog and supports Escape to close.
- Restores focus to the invoking control after the dialog closes.
- Adds online/offline status announcements without transmitting data.
- Adds layouts for 320 CSS pixels, 200% zoom, reduced motion, and forced colors.
- Updates the service-worker cache baseline to `v0.5.0`.

## Preserved constraints

No account, PII, telemetry, assessment-score persistence, missed-icon persistence, or external transmission is introduced. Existing Learn, Lessons, Practice, Saved for review, knowledge checks, missed-icon review, targeted practice, browser-local progress, and offline behavior remain controlled requirements.

## Deferred evidence

Statements about learner comprehension, comfort, independence, or preference remain pending actual pilot sessions. Phase 5B findings checkpoints remain the authority for human-usability decisions.
'@
        '05_Testing\Phase_5C_Pre_Pilot_Hardening_Checklist.md' = @'
# Phase 5C Pre-Pilot Hardening Checklist

Record Pass / Fail / Not Applicable and retain non-identifying evidence.

## Start Here

- [ ] Start Here appears in Learning mode navigation.
- [ ] Orientation opens once per browser-tab session.
- [ ] Heading receives focus when opened.
- [ ] Tab and Shift+Tab remain inside the dialog.
- [ ] Escape closes the dialog.
- [ ] Focus returns to the invoking control.
- [ ] Start with a lesson opens Lessons.
- [ ] Explore icons opens Learn.

## Accessibility and resilience

- [ ] Keyboard-only operation succeeds.
- [ ] Screen-reader name, role, and state are available.
- [ ] Online and offline changes use a polite status announcement.
- [ ] Layout remains usable at 200% zoom.
- [ ] Layout remains usable at 320 CSS pixels.
- [ ] Standard, Large, and Extra Large text remain usable.
- [ ] Reduced-motion preference is respected.
- [ ] Forced-colors mode preserves boundaries and controls.
- [ ] Previously loaded content remains available offline.

## Regression and privacy

- [ ] Learn, Lessons, Practice, and Saved for review remain operational.
- [ ] Knowledge checks still use five questions and four choices.
- [ ] Missed-icon review and targeted practice remain session-only.
- [ ] No PII, telemetry, score persistence, or external result transmission is introduced.
- [ ] Controlled markers occur exactly once.
- [ ] Build and ValidateOnly are idempotent.

## Evidence boundary

- [ ] Results are labeled technical pre-pilot validation.
- [ ] No claim of human usability validation is made.
'@
    }
}

function Update-ServiceWorkerCache {
    param ([Parameter(Mandatory)][string]$Path)
    $Content = Get-Content -LiteralPath $Path -Raw
    if (-not $Content.Contains('techsavvysage-icon-guide-v')) {
        throw 'The supported service-worker cache baseline was not found.'
    }
    $Updated = [regex]::Replace(
        $Content,
        'techsavvysage-icon-guide-v[0-9]+(?:\.[0-9]+){1,2}',
        'techsavvysage-icon-guide-v0.5.0',
        1
    )
    Set-Utf8File -Path $Path -Content $Updated
}

function Test-Phase5COutput {
    param ([Parameter(Mandatory)][string]$Root)
    $Checks = 0
    $Rules = @{
        '04_Application\js\app.js' = @('PHASE-5C-START-HERE-BEGIN', 'initializeStartHere', 'sessionStorage.getItem', 'initializeConnectionStatus', 'PHASE-5C-START-HERE-END')
        '04_Application\css\styles.css' = @('PHASE-5C-HARDENING-BEGIN', '.start-here-dialog', 'max-width: 320px', 'prefers-reduced-motion', 'forced-colors: active', 'PHASE-5C-HARDENING-END')
        'service-worker.js' = @('techsavvysage-icon-guide-v0.5.0')
        '01_Documentation\Phase_5C_Pre_Pilot_Hardening.md' = @('# Phase 5C Pre-Pilot Accessibility and Usability Hardening', 'does not claim human usability validation')
        '05_Testing\Phase_5C_Pre_Pilot_Hardening_Checklist.md' = @('# Phase 5C Pre-Pilot Hardening Checklist', 'Pass / Fail / Not Applicable')
    }
    foreach ($RelativePath in $Rules.Keys) {
        $Path = Join-Path $Root $RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required Phase 5C output is missing: $RelativePath" }
        $Checks++
        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $Rules[$RelativePath]) {
            if (-not $Content.Contains($Marker)) { throw "Required marker '$Marker' is missing from $RelativePath." }
            $Checks++
        }
    }
    return $Checks
}

try {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5C' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan

    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    $AppPath = Join-Path $Root '04_Application\js\app.js'
    $CssPath = Join-Path $Root '04_Application\css\styles.css'
    $ServiceWorkerPath = Join-Path $Root 'service-worker.js'

    Write-Section -Title 'Execution Configuration'
    Write-Host ('Operating mode                    : {0}' -f $Mode)
    Write-Host ('Repository root                   : {0}' -f $Root)
    Write-Host 'Hardening scope                   : Accessibility + Start Here'
    Write-Host 'Human usability evidence          : Deferred to rolling cohort'
    Write-Host 'Assessment result storage         : Session only'

    if ($Mode -eq 'Build') {
        Write-Section -Title 'Applying Controlled Phase 5C Updates'
        Set-ControlledBlock -Path $AppPath -StartMarker '// PHASE-5C-START-HERE-BEGIN' -EndMarker '// PHASE-5C-START-HERE-END' -Block (Get-StartHereJavaScript)
        Write-Pass -Message 'Applied accessible Start Here and connection-status behavior.'
        Set-ControlledBlock -Path $CssPath -StartMarker '/* PHASE-5C-HARDENING-BEGIN */' -EndMarker '/* PHASE-5C-HARDENING-END */' -Block (Get-StartHereCss)
        Write-Pass -Message 'Applied zoom, narrow-screen, reduced-motion, and forced-colors styling.'
        Update-ServiceWorkerCache -Path $ServiceWorkerPath
        Write-Pass -Message 'Updated the service-worker cache baseline to v0.5.0.'
        foreach ($Entry in (Get-PhaseDocumentation).GetEnumerator()) {
            Set-Utf8File -Path (Join-Path $Root $Entry.Key) -Content $Entry.Value
            Write-Pass -Message ("Wrote {0}" -f $Entry.Key)
        }
    }

    Write-Section -Title 'Validating Phase 5C Output'
    $PassedChecks = Test-Phase5COutput -Root $Root
    Write-Pass -Message 'Controlled runtime markers and documentation validated.'

    Write-Section -Title 'Phase 5C Execution Metrics'
    Write-Host 'Controlled update rules           : 3'
    Write-Host 'Runtime files in scope            : 3'
    Write-Host 'Documentation files               : 2'
    Write-Host ('Validated output checks           : {0}' -f $PassedChecks)
    Write-Host 'Start Here storage                : Browser session only'
    Write-Host 'Assessment result storage         : Session only'
    Write-Host 'Human usability evidence          : Deferred'

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5C COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message ("Operating mode {0} completed successfully." -f $Mode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5C ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    throw
}
