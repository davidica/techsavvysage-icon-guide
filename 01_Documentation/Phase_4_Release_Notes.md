# TechSavvySage Icon Guide v0.4.2 Release Notes

**Release date:** August 26, 2026

**Release status:** Stable Release Candidate

## Summary

Phase 4 adds a complete lesson knowledge-check and reinforcement workflow without adding accounts, external telemetry, stored assessment scores, or time pressure.

## Delivered by increment

### Phase 4A — Assessment data foundation

- Added four lesson-linked assessments.
- Added 40 validated question-bank records.
- Standardized five questions per attempt and four answer options per question.
- Preserved complete icon and lesson relationships.

### Phase 4B — Lesson knowledge-check interface

- Added the accessible five-question knowledge-check runner.
- Added randomized questions and answer choices.
- Added immediate supportive feedback, retry, and completion results.
- Added offline assessment-data caching.

### Phase 4C — Missed-icon review

- Added a results review containing only missed icons.
- Added icon names, meanings, and plain-language examples.
- Kept review state session-only and CSP-safe.

### Phase 4D — Targeted reinforcement

- Added **Practice missed icons** when an attempt contains missed targets.
- Reused the established Practice engine through `startPractice(specificIds)`.
- Randomized missed targets without creating a second practice implementation.
- Preserved session-only assessment state.

## Preserved capabilities

- Forty-icon Learn and Practice experiences
- Four guided lessons with browser-local progress and reset
- Saved for Review
- Text-size, contrast, reduced-motion, and read-aloud support
- Installable and offline-capable application behavior
- Network-first deployment refresh handling

## Security and privacy

- No account or personally identifiable information is required.
- No assessment score or missed-icon list is written to browser storage.
- No assessment or targeted-practice result is transmitted externally.
- Knowledge-check and review functions remain compatible with the existing Content Security Policy.

## Release validation

- Icon records: 40
- Lesson records: 4
- Lesson steps: 40
- Assessment records: 4
- Question-bank records: 40
- Questions per attempt: 5
- Phase scripts and functional validators: 7
- Runtime files modified by closeout: 0

## Deployment note

Deploy the committed release through the existing GitHub Pages workflow. The service worker uses cache `techsavvysage-icon-guide-v0.4.2` and retains assessment data for offline use.

## Release decision

Phase 4 is ready for final regression, accessibility review, deployment verification, and release authorization.
