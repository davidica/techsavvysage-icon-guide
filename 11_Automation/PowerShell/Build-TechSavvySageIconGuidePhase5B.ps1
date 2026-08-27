# =====================================================================
# Build-TechSavvySageIconGuidePhase5B.ps1
# Phase 5B - Rolling-Cohort Usability Validation
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

function Get-UsabilityFileDefinitions {
    return @(
        [pscustomobject]@{
            RelativePath = '01_Documentation\Phase_5B_Usability_Validation_Protocol.md'
            Markers = @('# Phase 5B Usability Validation Protocol', 'Rolling cohort', 'Five-session checkpoint', 'no fixed participant ceiling', 'Session-only')
        }
        [pscustomobject]@{
            RelativePath = '05_Testing\Phase_5B_Participant_Task_Script.md'
            Markers = @('# Phase 5B Participant Task Script', 'Facilitated path', 'Self-guided path', 'Do not record the knowledge-check score')
        }
        [pscustomobject]@{
            RelativePath = '05_Testing\Phase_5B_Session_Scoring_Rubric.md'
            Markers = @('# Phase 5B Session Scoring Rubric', 'Independent', 'Assisted', 'Not completed', 'Not Applicable')
        }
        [pscustomobject]@{
            RelativePath = '05_Testing\Phase_5B_Usability_Issue_Register.md'
            Markers = @('# Phase 5B Usability Issue Register', 'Blocking', 'High', 'Medium', 'Low')
        }
        [pscustomobject]@{
            RelativePath = '05_Testing\Phase_5B_Findings_Report_Template.md'
            Markers = @('# Phase 5B Findings Report Template', 'Five-session checkpoint', 'Task completion rate', 'Phase 5C recommendation')
        }
    )
}

function Get-UsabilityFileContent {
    param ([Parameter(Mandatory)][string]$RelativePath)

    switch ($RelativePath) {
        '01_Documentation\Phase_5B_Usability_Validation_Protocol.md' {
            return @'
# Phase 5B Usability Validation Protocol

## Purpose

Phase 5B validates whether adults 50+ and people with varied learning needs can use the TechSavvySage Icon Guide Phase 4 learning cycle: select a lesson, complete its steps, take a knowledge check, understand feedback, review missed icons, and enter targeted practice.

## Rolling cohort

Phase 5B uses a **Rolling cohort** with no fixed participant ceiling. Sessions may be facilitated or self-guided under the Phase 5A Hybrid delivery model. Findings are reviewed at every **Five-session checkpoint** rather than waiting for a final sample size.

Each checkpoint includes the next five valid completed or participant-stopped sessions. Record the delivery path for each session so facilitated and self-guided findings remain distinguishable. Do not delay a blocking issue until a checkpoint.

## Participants and privacy

- Participation is voluntary and untimed.
- Use only a non-identifying participant code.
- Do not collect names, contact information, library-card numbers, ages, diagnoses, or account identifiers.
- Do not record knowledge-check scores or missed-icon lists.
- Assessment and targeted-practice state remains Session-only.
- Do not transmit learning results to an external service.
- Participants may stop or skip feedback without penalty.

## Valid session

A session is valid when the Phase 5A privacy notice is given, a participant selects a delivery path, at least one scripted task is attempted, the observer records only non-identifying evidence, and the disposition is documented. A participant-stopped session remains valid when the reason is recorded without personal information.

## Core usability measures

1. **Task outcome:** Independent, Assisted, Not completed, or Not Applicable.
2. **Assistance point:** the task and type of help required, without recording an answer.
3. **Observed barrier:** navigation, readability, instruction, feedback, accessibility, technical, or other.
4. **Participant feedback:** clear, unclear, or prefer not to answer, plus optional non-identifying comments.
5. **Defect severity:** Blocking, High, Medium, or Low.

There is no participant performance score and no time-on-task target.

## Five-session checkpoint rules

After each five valid sessions:

- Calculate the completion rate for each core task using Independent plus Assisted outcomes.
- Calculate the independent-completion rate separately.
- Summarize findings by facilitated and self-guided path.
- Identify barriers observed in two or more sessions.
- Review all accessibility observations, even when seen once.
- Assign each confirmed issue a severity, owner, and disposition.
- Recommend continue, continue with monitoring, remediate before more sessions, or stop.

## Decision thresholds

- **Continue:** no Blocking defect; at least 80% completion for each core task; no unresolved repeated High issue.
- **Continue with monitoring:** no Blocking defect; an isolated High issue or repeated Medium issue has a documented owner and workaround.
- **Remediate before more sessions:** any core task falls below 80% completion, a High accessibility barrier repeats, or a privacy safeguard is unclear.
- **Stop immediately:** a Blocking defect prevents the learning cycle, exposes personal information, transmits prohibited results, or creates an unsafe or distressing condition.

Thresholds evaluate the product workflow, not participant ability.

## Accessibility coverage

Across the rolling cohort, deliberately include keyboard-only use, browser zoom to 200%, Standard/Large/Extra Large text, narrow presentation at 320 CSS pixels, reduced motion, visible focus, live-region feedback, read-aloud, and touch interaction when available.

## Phase 5B exit criteria

- At least one five-session checkpoint completed.
- No unresolved Blocking defect.
- All High issues have an owner and disposition.
- Findings separate facilitated and self-guided observations.
- No PII, knowledge-check scores, or missed-icon lists collected.
- A Phase 5C recommendation is documented.
'@
        }
        '05_Testing\Phase_5B_Participant_Task_Script.md' {
            return @'
# Phase 5B Participant Task Script

## Opening statement

“We are evaluating the learning tool, not you. There is no timer and no penalty for a wrong answer. We will not collect your name or knowledge-check score. You may ask for help, skip a feedback question, or stop at any time.”

## Session setup

| Field | Entry |
| --- | --- |
| Participant code | P-___ |
| Delivery path | Facilitated / Self-guided |
| Device | Computer / Tablet / Phone |
| Input method | Mouse / Keyboard / Touch / Assistive technology |
| Text setting | Standard / Large / Extra Large |

Do not enter a participant name, age, diagnosis, contact detail, or account identifier.

## Facilitated path

Read each task exactly as written. Allow the participant to decide how to complete it. Provide accessibility or technical assistance when requested, but do not identify an icon or answer.

## Self-guided path

Provide the tasks in order. The participant may complete them independently and request accessibility or technical assistance at any point.

## Core tasks

1. Open **Lessons** and choose a lesson that interests you.
2. Start the lesson and move through all of its steps.
3. Finish the lesson and start its knowledge check.
4. Answer all five questions using the choices provided.
5. Open the results summary.
6. If missed-icon review appears, examine the explanations.
7. If **Practice missed icons** appears, start it and answer one practice question.
8. Return to the lesson choices.
9. Change the text setting and confirm whether the page remains comfortable to use.

Do not record the knowledge-check score, selected answers, or missed-icon names.

## Feedback questions

- Were the next steps clear?
- Was the text comfortable to read?
- Did the feedback after each answer make sense?
- Did you know what to do on the results screen?
- What part was most confusing?
- What one change would make the tool easier to use?
- Would you use this tool again? Yes / No / Prefer not to answer

## Session disposition

- [ ] Completed independently
- [ ] Completed with assistance
- [ ] Participant stopped
- [ ] Technical problem prevented completion
- [ ] Blocking issue requires escalation
'@
        }
        '05_Testing\Phase_5B_Session_Scoring_Rubric.md' {
            return @'
# Phase 5B Session Scoring Rubric

## Outcome definitions

| Outcome | Definition |
| --- | --- |
| Independent | Participant completes the task without facilitator guidance beyond reading the task. |
| Assisted | Participant completes the task after accessibility, navigation, or technical assistance. |
| Not completed | Participant attempts but cannot complete the task, or a product defect blocks completion. |
| Not Applicable | The task is not presented by the workflow, such as missed-icon review after a perfect attempt. |

Assistance is not a participant failure. The rubric measures where the product requires support.

## Session scoring table

| Task | Independent | Assisted | Not completed | Not Applicable | Assistance/barrier category |
| --- | --- | --- | --- | --- | --- |
| Open Lessons | | | | | |
| Choose a lesson | | | | | |
| Start the lesson | | | | | |
| Navigate lesson steps | | | | | |
| Finish the lesson | | | | | |
| Start knowledge check | | | | | |
| Answer five questions | | | | | |
| Open results | | | | | |
| Understand missed review | | | | | |
| Start targeted practice | | | | | |
| Return to lesson choices | | | | | |
| Change text setting | | | | | |

## Barrier categories

- Navigation
- Readability
- Instruction clarity
- Knowledge-check interaction
- Feedback comprehension
- Accessibility
- Device/browser/network
- Other non-identifying observation

## Checkpoint calculations

For each task, exclude Not Applicable outcomes:

- Completion rate = (Independent + Assisted) / applicable sessions.
- Independent-completion rate = Independent / applicable sessions.
- Assistance rate = Assisted / applicable sessions.

Round only for reporting. Retain the session counts supporting every percentage. Do not calculate or report a participant knowledge score.
'@
        }
        '05_Testing\Phase_5B_Usability_Issue_Register.md' {
            return @'
# Phase 5B Usability Issue Register

## Severity definitions

| Severity | Definition | Required response |
| --- | --- | --- |
| Blocking | Prevents the learning cycle, compromises privacy, transmits prohibited results, or creates an unsafe condition. | Stop affected testing and escalate immediately. |
| High | Prevents a core task for one session or creates a material accessibility barrier. | Assign owner and disposition before the next checkpoint; stop if repeated. |
| Medium | Causes confusion, avoidable assistance, or a recoverable workflow problem. | Track frequency and prioritize when repeated. |
| Low | Cosmetic, wording, or minor consistency issue that does not block completion. | Record for backlog review. |

## Issue register

| Issue ID | First observed checkpoint | Delivery path | Category | Severity | Non-identifying evidence | Reproduction steps | Expected behavior | Actual behavior | Frequency | Owner | Disposition | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P5B-___ | CP-___ | Facilitated / Self-guided / Both | | Blocking / High / Medium / Low | | | | | | | Fix / Monitor / Accept / Duplicate | Open / Resolved |

## Recording rules

- Do not include participant names, ages, diagnoses, contact details, answers, scores, or missed-icon lists.
- Use participant codes only when needed to correlate a session record.
- Combine repeated observations under one issue and update frequency.
- Record browser/device facts only when relevant to reproduction.
- A privacy or safety concern is never deferred to the next five-session checkpoint.
'@
        }
        '05_Testing\Phase_5B_Findings_Report_Template.md' {
            return @'
# Phase 5B Findings Report Template

## Checkpoint identification

| Field | Entry |
| --- | --- |
| Five-session checkpoint | CP-___ |
| Session range | |
| Facilitated sessions | |
| Self-guided sessions | |
| Participant-stopped sessions | |
| Report date | |

## Privacy confirmation

- [ ] No PII collected.
- [ ] No knowledge-check scores recorded.
- [ ] No missed-icon lists recorded.
- [ ] No assessment or targeted-practice results transmitted externally.

## Task findings

| Core task | Applicable sessions | Independent | Assisted | Not completed | Task completion rate | Independent-completion rate |
| --- | --- | --- | --- | --- | --- | --- |
| Open and choose a lesson | | | | | | |
| Complete lesson steps | | | | | | |
| Complete knowledge check | | | | | | |
| Open and understand results | | | | | | |
| Use missed review when applicable | | | | | | |
| Start targeted practice when applicable | | | | | | |
| Return to lesson choices | | | | | | |
| Change text setting | | | | | | |

## Path comparison

Summarize differences between Facilitated and Self-guided sessions without ranking participants.

## Accessibility findings

| Coverage area | Sessions observed | Findings | Issue IDs |
| --- | --- | --- | --- |
| Keyboard-only operation | | | |
| Visible focus | | | |
| 200% zoom | | | |
| 320 CSS pixels | | | |
| Text-size settings | | | |
| Reduced motion | | | |
| Live-region feedback | | | |
| Read-aloud | | | |
| Touch interaction | | | |

## Repeated barriers

List barriers observed in two or more sessions and reference the issue register.

## Severity summary

| Blocking | High | Medium | Low |
| --- | --- | --- | --- |
| | | | |

## Checkpoint decision

- [ ] Continue
- [ ] Continue with monitoring
- [ ] Remediate before more sessions
- [ ] Stop immediately

Rationale:

## Phase 5C recommendation

Identify the evidence-supported accessibility or usability improvements recommended for Phase 5C. Do not recommend a change solely from a participant’s assessment performance.

Approved by: ____________________  Date: ____________________
'@
        }
        default { throw "No content definition exists for $RelativePath." }
    }
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

function Get-ControlledRuntimeHashes {
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
            throw "Required runtime file is missing: $RelativePath"
        }
        $Hashes[$RelativePath] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
    return $Hashes
}

function Test-UsabilityPackage {
    param ([Parameter(Mandatory)][string]$Root)

    $Passed = 0
    foreach ($Definition in Get-UsabilityFileDefinitions) {
        $Path = Join-Path $Root $Definition.RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Required Phase 5B file is missing: $($Definition.RelativePath)"
        }
        $Passed++
        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $Definition.Markers) {
            if (-not $Content.Contains($Marker)) {
                throw "Required marker '$Marker' is missing from $($Definition.RelativePath)."
            }
            $Passed++
        }
    }

    $Combined = (Get-UsabilityFileDefinitions | ForEach-Object {
        Get-Content -LiteralPath (Join-Path $Root $_.RelativePath) -Raw
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
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5B' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan

    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    Write-Section -Title 'Execution Configuration'
    Write-Host ('Operating mode                    : {0}' -f $Mode)
    Write-Host ('Repository root                   : {0}' -f $Root)
    Write-Host 'Pilot cohort model                : Rolling cohort'
    Write-Host 'Findings checkpoint               : Every 5 valid sessions'
    Write-Host 'Assessment result storage         : Session only'

    $HashesBefore = Get-ControlledRuntimeHashes -Root $Root

    if ($Mode -eq 'Build') {
        Write-Section -Title 'Writing Phase 5B Usability Package'
        foreach ($Definition in Get-UsabilityFileDefinitions) {
            $Path = Join-Path $Root $Definition.RelativePath
            Set-Utf8File -Path $Path -Content (Get-UsabilityFileContent -RelativePath $Definition.RelativePath)
            Write-Pass -Message ("Wrote {0}" -f $Definition.RelativePath)
        }
    }

    Write-Section -Title 'Validating Phase 5B Usability Package'
    $PassedChecks = Test-UsabilityPackage -Root $Root
    $HashesAfter = Get-ControlledRuntimeHashes -Root $Root
    $ChangedFiles = @($HashesBefore.Keys | Where-Object { $HashesBefore[$_] -ne $HashesAfter[$_] })
    if ($ChangedFiles.Count -gt 0) {
        throw ('Runtime files changed unexpectedly: {0}' -f ($ChangedFiles -join ', '))
    }
    Write-Pass -Message 'Usability package structure, measures, and privacy markers validated.'
    Write-Pass -Message 'Controlled runtime files remained unchanged.'

    Write-Section -Title 'Phase 5B Execution Metrics'
    Write-Host ('Usability documents               : {0}' -f (Get-UsabilityFileDefinitions).Count)
    Write-Host 'Pilot cohort model                : Rolling cohort'
    Write-Host 'Findings checkpoint               : Every 5 valid sessions'
    Write-Host ('Validated package checks          : {0}' -f $PassedChecks)
    Write-Host ('Runtime files checked             : {0}' -f $HashesBefore.Count)
    Write-Host ('Runtime file changes              : {0}' -f $ChangedFiles.Count)
    Write-Host 'PII collection fields             : 0'
    Write-Host 'Assessment result storage         : Session only'

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5B COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message ("Operating mode {0} completed successfully." -f $Mode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5B ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    throw
}
