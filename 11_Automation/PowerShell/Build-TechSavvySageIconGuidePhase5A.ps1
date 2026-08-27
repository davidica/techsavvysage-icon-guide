# =====================================================================
# Build-TechSavvySageIconGuidePhase5A.ps1
# Phase 5A - Hybrid Pilot Framework
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

function Get-PilotFileDefinitions {
    return @(
        [pscustomobject]@{
            RelativePath = '01_Documentation\Phase_5A_Pilot_Framework.md'
            Markers = @('# Phase 5A Pilot Framework', 'Hybrid delivery model', 'No personally identifiable information', 'Session-only')
        }
        [pscustomobject]@{
            RelativePath = '01_Documentation\Phase_5A_Facilitator_Guide.md'
            Markers = @('# Phase 5A Facilitator Guide', 'Facilitated path', 'Self-guided path', 'Do not record assessment scores')
        }
        [pscustomobject]@{
            RelativePath = '05_Testing\Phase_5A_Pilot_Observation_Form.md'
            Markers = @('# Phase 5A Pilot Observation Form', 'Participant code', 'Do not enter a participant name', 'Pass / Fail / Not Applicable')
        }
        [pscustomobject]@{
            RelativePath = '05_Testing\Phase_5A_Pilot_Validation_Checklist.md'
            Markers = @('# Phase 5A Pilot Validation Checklist', 'Keyboard-only operation', '200% zoom', '320 CSS pixels')
        }
    )
}

function Get-PilotFileContent {
    param ([Parameter(Mandatory)][string]$RelativePath)

    switch ($RelativePath) {
        '01_Documentation\Phase_5A_Pilot_Framework.md' {
            return @'
# Phase 5A Pilot Framework

## Purpose

Phase 5A establishes a controlled pilot framework for the TechSavvySage Icon Guide. The pilot tests whether adults 50+ and people with varied learning needs can use the Phase 4 learning cycle: guided lesson, knowledge check, missed-icon review, and targeted practice.

## Hybrid delivery model

The same pilot package supports two paths:

1. **Facilitated path** — a facilitator introduces the activity, observes without leading answers, and provides assistance only when requested or when a participant cannot continue.
2. **Self-guided path** — a participant follows the written session script independently and records non-identifying feedback at the end.

Results from both paths may be compared only at an aggregate, non-identifying level.

## Pilot objectives

- Confirm that participants can find and start a lesson.
- Confirm that lesson instructions are understandable and appropriately paced.
- Confirm that participants can complete a five-question knowledge check.
- Confirm that supportive feedback is understood after correct and incorrect answers.
- Confirm that missed-icon review explains only the icons missed during the current attempt.
- Confirm that targeted practice uses the missed icons from the current session.
- Identify navigation, readability, accessibility, or cognitive-load barriers.

## Scope

The pilot covers the deployed Phase 4 release (`v0.4.2`) and its four lessons. A pilot session may use one lesson rather than all four. There is no time limit and no performance threshold for participants.

## Privacy boundaries

- No account is required.
- No personally identifiable information is collected.
- Use an optional participant code such as `P-001`; never use a name, email address, phone number, or library-card number.
- Do not record assessment scores or missed-icon lists in the observation form.
- Assessment and targeted-practice results remain Session-only.
- Do not transmit assessment results to an external service.
- Participation is voluntary, and a participant may stop at any time.

## Accessibility baseline

The pilot must preserve untimed use, plain language, keyboard operation, visible focus, programmatic heading focus, supportive status announcements, Standard/Large/Extra Large text settings, 200% zoom, reduced motion, and operation at 320 CSS pixels.

## Standard session sequence

1. Provide the purpose and privacy notice.
2. Confirm the participant wants the facilitated or self-guided path.
3. Open the live Icon Guide and select **Lessons**.
4. Complete one guided lesson.
5. Start the lesson knowledge check.
6. Open the results summary.
7. If applicable, review missed icons and start targeted practice.
8. Return to lesson choices.
9. Collect non-identifying usability feedback.
10. Record defects and observations using Pass / Fail / Not Applicable.

## Success criteria

Phase 5A is successful when the pilot materials are complete, privacy and accessibility safeguards are explicit, the hybrid paths use one consistent workflow, the builder and validator pass, and no runtime application file is changed.

## Exit criteria

- Pilot framework approved.
- Facilitator and self-guided instructions validated.
- Observation and validation forms ready for use.
- No PII fields present.
- No assessment score or missed-icon storage introduced.
- Runtime files unchanged.
'@
        }
        '01_Documentation\Phase_5A_Facilitator_Guide.md' {
            return @'
# Phase 5A Facilitator Guide

## Facilitator role

Create a calm, judgment-free environment. Explain the activity, observe how the participant uses the Icon Guide, and help only when needed. Do not teach the correct answer during a knowledge-check question.

## Opening script

“We are testing whether this learning tool is clear and comfortable to use. We are testing the tool, not you. There is no timer, no penalty for a wrong answer, and you may stop at any time. We will not collect your name or your knowledge-check score.”

## Facilitated path

1. Ask the participant to open **Lessons**.
2. Ask the participant to choose one lesson.
3. Allow the participant to control the mouse, keyboard, or touch screen.
4. Observe where the participant pauses, rereads, asks for help, or selects an unexpected control.
5. After the lesson, ask the participant to start the knowledge check.
6. Do not confirm an answer before the application provides feedback.
7. Ask the participant to open results and, when available, review missed icons.
8. Ask the participant to start **Practice missed icons** when it appears.
9. Finish with the feedback questions below.

## Self-guided path

Provide the participant with the standard session sequence and privacy notice. Remain available for accessibility or technical assistance, but allow independent completion. The participant may skip any feedback question.

## Permitted assistance

- Explain how to enlarge text or zoom the browser.
- Explain how to use Tab, Shift+Tab, Enter, or Space.
- Read instructions aloud when requested.
- Resolve a device, browser, network, or audio problem.
- Remind the participant that there is no timer or penalty.

## Assistance to avoid

- Do not identify the correct icon or answer.
- Do not select an answer for the participant.
- Do not rush a participant or impose a time limit.
- Do not compare one participant with another.
- Do not record assessment scores or missed-icon lists.

## Non-identifying feedback questions

1. What part felt easiest?
2. What part felt confusing?
3. Was the text comfortable to read?
4. Did the buttons and next steps make sense?
5. Was the feedback after an answer helpful?
6. Would you use this tool again?
7. What is one change that would make the tool easier to use?

## Escalation rules

Record a defect when a participant cannot continue because a control fails, content is missing, focus is lost, feedback is not announced, layout prevents use, or the application reports an error. Do not enter personal information in a defect note. Stop the pilot if continuing could expose personal data or cause distress.
'@
        }
        '05_Testing\Phase_5A_Pilot_Observation_Form.md' {
            return @'
# Phase 5A Pilot Observation Form

> Do not enter a participant name or other personally identifiable information.

## Session information

| Field | Entry |
| --- | --- |
| Participant code | P-___ |
| Session date | |
| Delivery path | Facilitated / Self-guided |
| Device type | Computer / Tablet / Phone |
| Input method | Mouse / Keyboard / Touch / Assistive technology |
| Browser | |
| Lesson selected | |
| Text setting | Standard / Large / Extra Large |

## Observation scale

Use **Pass / Fail / Not Applicable**. Record observable behavior and application evidence, not assumptions about the participant.

| Check | Result | Non-identifying notes |
| --- | --- | --- |
| Opened Lessons | | |
| Selected a lesson | | |
| Understood step navigation | | |
| Completed the lesson | | |
| Started the knowledge check | | |
| Understood answer choices | | |
| Understood supportive feedback | | |
| Opened the results summary | | |
| Understood missed-icon review, when shown | | |
| Started targeted practice, when shown | | |
| Returned to lesson choices | | |
| Completed the selected path without a blocking defect | | |

## Accessibility observations

| Check | Result | Non-identifying notes |
| --- | --- | --- |
| Keyboard operation | | |
| Visible focus | | |
| Text readability | | |
| Zoom or narrow-screen usability | | |
| Status/feedback announcement | | |
| Touch-target usability | | |
| Motion comfort | | |

## Assistance log

Record only the type of assistance, such as “explained browser zoom” or “restored network connection.” Do not record the participant’s answer, score, diagnosis, age, or contact information.

| Step | Assistance provided | Could the participant continue? |
| --- | --- | --- |
| | | Yes / No |

## Feedback summary

- Easiest part:
- Most confusing part:
- Readability feedback:
- Navigation feedback:
- Answer-feedback usefulness:
- Would use again: Yes / No / Prefer not to answer
- Suggested improvement:

## Defect record

| Defect ID | Severity | Reproduction summary | Expected behavior | Actual behavior |
| --- | --- | --- | --- | --- |
| P5A-___ | Low / Medium / High / Blocking | | | |

## Session disposition

- [ ] Completed
- [ ] Completed with assistance
- [ ] Stopped by participant
- [ ] Stopped because of a technical problem
- [ ] Follow-up defect review required
'@
        }
        '05_Testing\Phase_5A_Pilot_Validation_Checklist.md' {
            return @'
# Phase 5A Pilot Validation Checklist

## Instructions

Record each item as **Pass / Fail / Not Applicable** and attach non-identifying evidence or notes when needed.

## Package validation

- [ ] Pilot framework exists and identifies the Hybrid delivery model.
- [ ] Facilitator Guide includes facilitated and self-guided paths.
- [ ] Observation Form contains no required PII field.
- [ ] Validation Checklist uses Pass / Fail / Not Applicable.
- [ ] Builder completes in Build mode.
- [ ] Builder completes in ValidateOnly mode.
- [ ] Functional validator completes with exit code 0.
- [ ] Runtime application files remain unchanged.

## Functional workflow

- [ ] Lessons displays four guided lessons.
- [ ] A participant can start and complete a lesson.
- [ ] A completed lesson exposes Start knowledge check.
- [ ] A knowledge-check attempt contains exactly five questions.
- [ ] Each question contains four unique answer choices.
- [ ] Correct and incorrect answers provide supportive feedback.
- [ ] Next question advances exactly once.
- [ ] See results opens the summary.
- [ ] Missed-icon review contains only missed icons.
- [ ] A perfect attempt hides missed-icon review.
- [ ] Practice missed icons appears only when applicable.
- [ ] Targeted practice uses the current attempt’s missed icons.
- [ ] Return navigation restores lesson choices.

## Accessibility validation

- [ ] Keyboard-only operation completes the selected workflow.
- [ ] Visible focus identifies the active control.
- [ ] Programmatic heading focus follows major view changes.
- [ ] Supportive feedback is announced through an appropriate live region.
- [ ] Standard, Large, and Extra Large text settings remain usable.
- [ ] Content remains usable at 200% zoom.
- [ ] Content remains usable at 320 CSS pixels without two-dimensional scrolling for primary tasks.
- [ ] Reduced-motion preferences are respected.
- [ ] Touch targets are usable without precise movement.
- [ ] Instructions remain plain, concise, and untimed.

## Privacy and safety validation

- [ ] No account is required.
- [ ] No participant name, email, phone number, or library-card number is requested.
- [ ] Assessment scores are not written to browser storage.
- [ ] Missed-icon lists are not written to browser storage.
- [ ] Assessment and targeted-practice results are not transmitted externally.
- [ ] Observation notes exclude personal, medical, or diagnostic information.
- [ ] Participants may stop or skip feedback without penalty.

## Release decision

- [ ] All blocking defects are resolved.
- [ ] Remaining defects have an owner and disposition.
- [ ] Pilot lead authorizes Phase 5B usability validation.

Decision: **Pass / Fail / Not Applicable**

Authorized by: ____________________  Date: ____________________
'@
        }
        default {
            throw "No content definition exists for $RelativePath."
        }
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

function Test-PilotPackage {
    param ([Parameter(Mandatory)][string]$Root)

    $CheckCount = 0
    foreach ($Definition in Get-PilotFileDefinitions) {
        $Path = Join-Path $Root $Definition.RelativePath
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Required Phase 5A file is missing: $($Definition.RelativePath)"
        }
        $CheckCount++

        $Content = Get-Content -LiteralPath $Path -Raw
        foreach ($Marker in $Definition.Markers) {
            if (-not $Content.Contains($Marker)) {
                throw "Required marker '$Marker' is missing from $($Definition.RelativePath)."
            }
            $CheckCount++
        }
    }

    $AllContent = (Get-PilotFileDefinitions | ForEach-Object {
        Get-Content -LiteralPath (Join-Path $Root $_.RelativePath) -Raw
    }) -join [Environment]::NewLine

    foreach ($ForbiddenLabel in @('Participant name |', 'Email address |', 'Phone number |', 'Library card number |')) {
        if ($AllContent.Contains($ForbiddenLabel)) {
            throw "A prohibited PII collection field was detected: $ForbiddenLabel"
        }
        $CheckCount++
    }

    return $CheckCount
}

try {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5A' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan

    $Root = Resolve-PhaseRepositoryRoot -RequestedRoot $RepositoryRoot
    Write-Section -Title 'Execution Configuration'
    Write-Host ('Operating mode                    : {0}' -f $Mode)
    Write-Host ('Repository root                   : {0}' -f $Root)
    Write-Host 'Pilot delivery model              : Hybrid'
    Write-Host 'Assessment result storage         : Session only'

    $RuntimeHashesBefore = Get-ControlledRuntimeHashes -Root $Root

    if ($Mode -eq 'Build') {
        Write-Section -Title 'Writing Phase 5A Pilot Package'
        foreach ($Definition in Get-PilotFileDefinitions) {
            $TargetPath = Join-Path $Root $Definition.RelativePath
            $Content = Get-PilotFileContent -RelativePath $Definition.RelativePath
            Set-Utf8File -Path $TargetPath -Content $Content
            Write-Pass -Message ("Wrote {0}" -f $Definition.RelativePath)
        }
    }

    Write-Section -Title 'Validating Phase 5A Pilot Package'
    $ValidatedChecks = Test-PilotPackage -Root $Root
    $RuntimeHashesAfter = Get-ControlledRuntimeHashes -Root $Root
    $ChangedRuntimeFiles = @($RuntimeHashesBefore.Keys | Where-Object {
        $RuntimeHashesBefore[$_] -ne $RuntimeHashesAfter[$_]
    })

    if ($ChangedRuntimeFiles.Count -gt 0) {
        throw ('Runtime files changed unexpectedly: {0}' -f ($ChangedRuntimeFiles -join ', '))
    }

    Write-Pass -Message 'Pilot package structure and privacy markers validated.'
    Write-Pass -Message 'Controlled runtime files remained unchanged.'

    Write-Section -Title 'Phase 5A Execution Metrics'
    Write-Host ('Pilot documents                   : {0}' -f (Get-PilotFileDefinitions).Count)
    Write-Host ('Pilot delivery model              : Hybrid')
    Write-Host ('Validated package checks          : {0}' -f $ValidatedChecks)
    Write-Host ('Runtime files checked             : {0}' -f $RuntimeHashesBefore.Count)
    Write-Host ('Runtime file changes              : {0}' -f $ChangedRuntimeFiles.Count)
    Write-Host ('PII collection fields             : 0')
    Write-Host ('Assessment result storage         : Session only')

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5A COMPLETE' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Pass -Message ("Operating mode {0} completed successfully." -f $Mode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 5A ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('[FAIL    ] {0}' -f $_.Exception.Message) -ForegroundColor Red
    throw
}
