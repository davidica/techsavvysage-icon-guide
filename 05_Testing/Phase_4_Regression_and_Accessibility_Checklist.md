# TechSavvySage Icon Guide Phase 4 Regression and Accessibility Checklist

**Release:** v0.4.2

**Review date:** ____________________

**Reviewer:** ____________________

Use `Pass`, `Fail`, or `Not Applicable` for each item. Record defects and evidence in the notes column.

## Automated baseline

| Check | Result | Notes |
| --- | --- | --- |
| PowerShell parser validation passes for Phase 4A–4E scripts |  |  |
| Phase 4B functional validator passes |  |  |
| Phase 4C functional validator passes |  |  |
| Phase 4D functional validator passes |  |  |
| Icon data contains 40 records |  |  |
| Lesson data contains 4 lessons and 40 steps |  |  |
| Assessment data contains 4 assessments and 40 questions |  |  |
| Service-worker cache is `v0.4.2` |  |  |
| Runtime hashes remain unchanged during closeout |  |  |

## Knowledge-check regression

| Check | Result | Notes |
| --- | --- | --- |
| Each completed lesson exposes **Start knowledge check** |  |  |
| Each attempt presents exactly five questions |  |  |
| Questions remain within the active lesson |  |  |
| Each question presents four unique answer choices |  |  |
| Correct answers receive supportive confirmation |  |  |
| Incorrect answers identify the correct icon meaning |  |  |
| **Next question** advances once per answered question |  |  |
| **See results** opens the completion summary |  |  |
| Retry starts a new randomized five-question attempt |  |  |

## Missed-icon review and reinforcement

| Check | Result | Notes |
| --- | --- | --- |
| Review contains only icons missed in the completed attempt |  |  |
| Each review card shows icon, name, meaning, and example |  |  |
| Perfect attempts hide the missed-icon review |  |  |
| **Practice missed icons** appears only when icons were missed |  |  |
| Targeted Practice questions use only missed icons as targets |  |  |
| Targeted Practice reuses existing answer and results behavior |  |  |
| Lessons navigation returns to lesson choices |  |  |

## Accessibility

| Check | Result | Notes |
| --- | --- | --- |
| All Phase 4 controls are reachable and operable by keyboard |  |  |
| Visible focus remains clear in standard and high contrast |  |  |
| Question and completion headings receive programmatic focus |  |  |
| Feedback is announced without moving focus unexpectedly |  |  |
| Review heading and cards follow a logical reading order |  |  |
| Controls remain usable at 200% browser zoom |  |  |
| Standard, Large, and Extra Large text do not hide controls |  |  |
| Reduced-motion preference introduces no required animation |  |  |
| Mobile layout remains usable at 320 CSS pixels |  |  |

## Privacy and security

| Check | Result | Notes |
| --- | --- | --- |
| No account or PII is requested |  |  |
| Assessment score is not written to local or session storage |  |  |
| Missed-icon assessment list is not persisted |  |  |
| Assessment and targeted-practice results are not transmitted |  |  |
| No inline event handler or dynamic code execution is introduced |  |  |
| Existing Content Security Policy produces no new violation |  |  |

## Offline and deployment

| Check | Result | Notes |
| --- | --- | --- |
| First online visit caches assessment data |  |  |
| Knowledge checks work after reconnecting in offline mode |  |  |
| Missed-icon review works offline |  |  |
| Targeted Practice works offline |  |  |
| New deployment replaces the prior service-worker cache |  |  |
| Page reload occurs no more than once during controller change |  |  |

## Release decision

**Decision:** Approve / Approve with conditions / Reject

**Approver:** ____________________

**Approval date:** ____________________

**Open defects or conditions:**
