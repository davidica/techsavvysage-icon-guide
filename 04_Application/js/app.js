'use strict';

(function () {
    const STORAGE_KEY = 'techsavvysage-icon-guide-progress-v2';
    const LEGACY_STORAGE_KEY = 'techsavvysage-icon-guide-progress-v1';
    const state = {
        icons: [],
        lessons: [],
        selectedLessonId: null,
        activeLessonId: null,
        lessonStepIndex: 0,
        lessonSessionComplete: false,
        lessonProgress: {},
        reviewingCompletedLesson: false,
        assessments: [],
        activeAssessment: null,
        assessmentQuestions: [],
        assessmentQuestionIndex: 0,
        assessmentScore: 0,
        assessmentAnswered: false,
        assessmentComplete: false,
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
                state.lessonProgress = saved.lessons && typeof saved.lessons === 'object' && !Array.isArray(saved.lessons)
                    ? saved.lessons
                    : {};
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
                settings: state.settings,
                lessons: state.lessonProgress
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

    function findLesson(id) {
        return state.lessons.find(function (lesson) {
            return lesson.id === id;
        });
    }

    function createLessonCard(lesson) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'lesson-card';
        button.dataset.lessonId = lesson.id;
        button.setAttribute('aria-label', 'Lesson ' + lesson.order + '. ' + lesson.title + '. ' + lesson.estimated_minutes + ' minutes.');
        button.innerHTML =
            '<span class="detail-category">Lesson ' + lesson.order + '</span>' +
            '<span class="lesson-card-title">' + escapeHtml(lesson.title) + '</span>' +
            '<span class="lesson-card-summary">' + escapeHtml(lesson.summary) + '</span>' +
            '<span class="lesson-meta">' + lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps</span>';

        const savedProgress = getLessonProgress(lesson.id);

        if (savedProgress) {
            const status = document.createElement('span');
            status.className = 'lesson-status';

            if (savedProgress.completed) {
                status.classList.add('completed');
                status.textContent = 'Completed';
                button.classList.add('completed');
            }
            else {
                status.textContent = 'In progress · Step ' + (savedProgress.stepIndex + 1);
            }

            button.appendChild(status);
        }

        if (state.selectedLessonId === lesson.id) {
            button.classList.add('selected');
            button.setAttribute('aria-current', 'true');
        }

        return button;
    }

    function renderLessonCatalog() {
        elements.lessonGrid.innerHTML = '';

        state.lessons.forEach(function (lesson) {
            elements.lessonGrid.appendChild(createLessonCard(lesson));
        });

        elements.lessonCount.textContent = state.lessons.length + ' lessons';
        elements.lessonsEmpty.hidden = state.lessons.length !== 0;
    }

    function showLessonPreview(lesson) {
        if (!lesson) {
            elements.lessonPreview.hidden = true;
            return;
        }

        state.selectedLessonId = lesson.id;
        renderLessonCatalog();
        elements.lessonPreviewNumber.textContent = 'Lesson ' + lesson.order;
        elements.lessonPreviewTitle.textContent = lesson.title;
        elements.lessonPreviewSummary.textContent = lesson.summary;
        elements.lessonPreviewMeta.textContent = lesson.estimated_minutes + ' minutes · ' + lesson.steps.length + ' icon steps';
        elements.startLesson.dataset.lessonId = lesson.id;
        const savedProgress = getLessonProgress(lesson.id);

        if (savedProgress && savedProgress.completed) {
            elements.startLesson.textContent = 'Review lesson';
            elements.lessonPreviewMeta.textContent += ' · Completed';
        }
        else if (savedProgress) {
            elements.startLesson.textContent = 'Resume lesson';
            elements.lessonPreviewMeta.textContent += ' · Resume at step ' + (savedProgress.stepIndex + 1);
        }
        else {
            elements.startLesson.textContent = 'Start lesson';
        }

        elements.lessonPreview.hidden = false;
        setStatus(lesson.title + ' lesson preview selected.');
    }

    function getLessonProgress(id) {
        return state.lessonProgress[id] || null;
    }

    function normalizeLessonProgress() {
        const normalized = {};

        state.lessons.forEach(function (lesson) {
            const saved = state.lessonProgress[lesson.id];

            if (!saved || typeof saved !== 'object') {
                return;
            }

            const numericStep = Number(saved.stepIndex);
            const stepIndex = Number.isInteger(numericStep)
                ? Math.max(0, Math.min(numericStep, lesson.steps.length - 1))
                : 0;
            normalized[lesson.id] = {
                stepIndex: stepIndex,
                completed: Boolean(saved.completed)
            };
        });

        state.lessonProgress = normalized;
    }

    function updateLessonProgress(id, stepIndex, completed) {
        state.lessonProgress[id] = {
            stepIndex: stepIndex,
            completed: Boolean(completed)
        };
        saveProgress();
    }

    function resetLessonProgress() {
        if (!window.confirm('Reset progress for all four guided lessons in this browser?')) {
            return;
        }

        state.lessonProgress = {};
        state.reviewingCompletedLesson = false;
        saveProgress();
        renderLessonCatalog();

        if (state.selectedLessonId) {
            showLessonPreview(findLesson(state.selectedLessonId));
        }

        setStatus('Lesson progress reset. Other learning data and display settings were kept.');
    }

    function currentLesson() {
        return findLesson(state.activeLessonId);
    }

    function showLessonCatalog() {
        state.activeLessonId = null;
        state.lessonSessionComplete = false;
        state.reviewingCompletedLesson = false;
        elements.lessonCatalogHeader.hidden = false;
        elements.lessonCatalogIntro.hidden = false;
        elements.lessonGrid.hidden = false;
        elements.lessonRunner.hidden = true;
        elements.assessmentRunner.hidden = true;
        elements.lessonProgressRow.hidden = false;
        elements.lessonStepCard.hidden = false;
        elements.exitLesson.hidden = false;
        state.activeAssessment = null;
        state.assessmentQuestions = [];
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        renderLessonCatalog();

        if (state.selectedLessonId) {
            showLessonPreview(findLesson(state.selectedLessonId));
        }
        else {
            elements.lessonPreview.hidden = true;
        }
    }

    function showLessonStep() {
        const lesson = currentLesson();

        if (!lesson) {
            showLessonCatalog();
            return;
        }

        const step = lesson.steps[state.lessonStepIndex];
        const icon = findIcon(step.icon_id);
        const stepNumber = state.lessonStepIndex + 1;
        const totalSteps = lesson.steps.length;

        state.lessonSessionComplete = false;

        if (!state.reviewingCompletedLesson) {
            updateLessonProgress(lesson.id, state.lessonStepIndex, false);
        }

        elements.lessonStepIcon.hidden = false;
        elements.lessonStepIcon.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
        elements.lessonStepLabel.textContent = 'Lesson ' + lesson.order + ' · Step ' + stepNumber + ' of ' + totalSteps + ' · ' + icon.name;
        elements.lessonStepHeading.textContent = step.heading;
        elements.lessonStepInstruction.textContent = step.instruction;
        elements.lessonStepPrompt.textContent = step.practice_prompt;
        elements.lessonStepPractice.hidden = false;
        elements.lessonProgress.max = totalSteps;
        elements.lessonProgress.value = stepNumber;
        elements.lessonProgress.textContent = 'Step ' + stepNumber + ' of ' + totalSteps;
        elements.lessonProgressText.textContent = 'Step ' + stepNumber + ' of ' + totalSteps;
        elements.lessonPrevious.hidden = false;
        elements.lessonPrevious.disabled = state.lessonStepIndex === 0;
        elements.startAssessment.hidden = true;
        elements.lessonNext.dataset.action = 'advance';
        elements.lessonNext.textContent = state.lessonStepIndex === totalSteps - 1
            ? 'Finish lesson'
            : 'Next step';
        setStatus(lesson.title + '. Step ' + stepNumber + ' of ' + totalSteps + '.');
        elements.lessonStepHeading.focus();
    }

    function startLesson(id) {
        const lesson = findLesson(id);

        if (!lesson) {
            setStatus('The selected lesson is unavailable.');
            return;
        }

        const savedProgress = getLessonProgress(lesson.id);
        state.selectedLessonId = lesson.id;
        state.activeLessonId = lesson.id;
        state.reviewingCompletedLesson = Boolean(savedProgress && savedProgress.completed);
        state.lessonStepIndex = savedProgress && !savedProgress.completed
            ? savedProgress.stepIndex
            : 0;
        state.lessonSessionComplete = false;
        elements.lessonCatalogHeader.hidden = true;
        elements.lessonCatalogIntro.hidden = true;
        elements.lessonGrid.hidden = true;
        elements.lessonsEmpty.hidden = true;
        elements.lessonPreview.hidden = true;
        elements.lessonRunner.hidden = false;
        showLessonStep();
    }

    function completeLessonSession() {
        const lesson = currentLesson();

        if (!lesson) {
            showLessonCatalog();
            return;
        }

        state.lessonSessionComplete = true;
        state.reviewingCompletedLesson = false;
        updateLessonProgress(lesson.id, lesson.steps.length - 1, true);
        elements.lessonStepIcon.innerHTML = '';
        elements.lessonStepIcon.hidden = true;
        elements.lessonStepLabel.textContent = 'Lesson complete';
        elements.lessonStepHeading.textContent = lesson.title;
        elements.lessonStepInstruction.textContent = lesson.completion_message;
        elements.lessonStepPractice.hidden = true;
        elements.lessonProgress.value = lesson.steps.length;
        elements.lessonProgressText.textContent = lesson.steps.length + ' of ' + lesson.steps.length + ' steps complete';
        elements.lessonPrevious.hidden = true;
        elements.startAssessment.hidden = false;
        elements.lessonNext.dataset.action = 'return';
        elements.lessonNext.textContent = 'Return to lesson choices';
        setStatus(lesson.title + ' completed for this session.');
        elements.lessonStepHeading.focus();
    }

    function moveLessonStep(direction) {
        const lesson = currentLesson();

        if (!lesson) {
            showLessonCatalog();
            return;
        }

        const nextIndex = state.lessonStepIndex + direction;

        if (nextIndex < 0 || nextIndex >= lesson.steps.length) {
            return;
        }

        state.lessonStepIndex = nextIndex;
        showLessonStep();
    }

    function findAssessmentByLesson(lessonId) {
        return state.assessments.find(function (assessment) {
            return assessment.lesson_id === lessonId;
        });
    }

    function shuffledCopy(items) {
        const copy = items.slice();

        for (let index = copy.length - 1; index > 0; index -= 1) {
            const replacementIndex = Math.floor(Math.random() * (index + 1));
            const temporaryItem = copy[index];
            copy[index] = copy[replacementIndex];
            copy[replacementIndex] = temporaryItem;
        }

        return copy;
    }

    function startAssessment(lessonId) {
        const assessment = findAssessmentByLesson(lessonId);

        if (!assessment) {
            setStatus('The knowledge check for this lesson is unavailable.');
            return;
        }

        state.activeAssessment = assessment;
        state.assessmentQuestions = shuffledCopy(assessment.questions).slice(0, assessment.questions_per_attempt);
        state.assessmentQuestionIndex = 0;
        state.assessmentScore = 0;
        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        elements.exitLesson.hidden = true;
        elements.lessonProgressRow.hidden = true;
        elements.lessonStepCard.hidden = true;
        elements.assessmentRunner.hidden = false;
        showAssessmentQuestion();
    }

    function showAssessmentQuestion() {
        const assessment = state.activeAssessment;
        const question = state.assessmentQuestions[state.assessmentQuestionIndex];

        if (!assessment || !question) {
            showLessonCatalog();
            return;
        }

        const icon = findIcon(question.icon_id);
        const optionIds = shuffledCopy([
            question.correct_answer_icon_id
        ].concat(question.distractor_icon_ids));
        const questionNumber = state.assessmentQuestionIndex + 1;
        const totalQuestions = state.assessmentQuestions.length;

        if (!icon) {
            setStatus('An icon needed for this knowledge check is unavailable.');
            showLessonCatalog();
            return;
        }

        state.assessmentAnswered = false;
        state.assessmentComplete = false;
        elements.assessmentIcon.hidden = false;
        elements.assessmentIcon.innerHTML = window.IconGuideIcons.render(icon.icon, icon.name + ' icon');
        elements.assessmentLabel.textContent = 'Knowledge check · Question ' + questionNumber + ' of ' + totalQuestions;
        elements.assessmentHeading.textContent = assessment.title;
        elements.assessmentQuestion.textContent = question.prompt;
        elements.assessmentOptions.innerHTML = '';

        optionIds.forEach(function (iconId) {
            const answerIcon = findIcon(iconId);

            if (!answerIcon) {
                return;
            }

            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'assessment-option';
            button.dataset.answerIconId = answerIcon.id;
            button.textContent = answerIcon.meaning;
            elements.assessmentOptions.appendChild(button);
        });

        elements.assessmentFeedback.hidden = true;
        elements.assessmentFeedback.textContent = '';
        elements.assessmentFeedback.className = 'assessment-feedback';
        elements.assessmentProgress.max = totalQuestions;
        elements.assessmentProgress.value = questionNumber;
        elements.assessmentProgress.textContent = 'Question ' + questionNumber + ' of ' + totalQuestions;
        elements.assessmentProgressText.textContent = 'Question ' + questionNumber + ' of ' + totalQuestions;
        elements.assessmentNext.hidden = true;
        elements.assessmentRetry.hidden = true;
        elements.assessmentReturn.hidden = true;
        setStatus('Knowledge check question ' + questionNumber + ' of ' + totalQuestions + '. Choose one answer.');
        elements.assessmentHeading.focus();
    }

    function answerAssessment(answerIconId) {
        if (state.assessmentAnswered) {
            return;
        }

        const question = state.assessmentQuestions[state.assessmentQuestionIndex];
        const correctIcon = question ? findIcon(question.correct_answer_icon_id) : null;

        if (!question || !correctIcon) {
            setStatus('This knowledge-check question is unavailable.');
            return;
        }

        state.assessmentAnswered = true;
        const isCorrect = answerIconId === question.correct_answer_icon_id;
        const optionButtons = elements.assessmentOptions.querySelectorAll('[data-answer-icon-id]');

        optionButtons.forEach(function (button) {
            button.disabled = true;

            if (button.dataset.answerIconId === question.correct_answer_icon_id) {
                button.classList.add('correct');
            }
            else if (button.dataset.answerIconId === answerIconId) {
                button.classList.add('incorrect');
            }
        });

        if (isCorrect) {
            state.assessmentScore += 1;
            elements.assessmentFeedback.className = 'assessment-feedback correct';
            elements.assessmentFeedback.textContent = 'That is right. The ' + correctIcon.name + ' icon ' + correctIcon.meaning;
        }
        else {
            elements.assessmentFeedback.className = 'assessment-feedback';
            elements.assessmentFeedback.textContent = 'Good try. The ' + correctIcon.name + ' icon ' + correctIcon.meaning;
        }

        elements.assessmentFeedback.hidden = false;
        elements.assessmentNext.textContent = state.assessmentQuestionIndex === state.assessmentQuestions.length - 1
            ? 'See results'
            : 'Next question';
        elements.assessmentNext.hidden = false;
        setStatus(elements.assessmentFeedback.textContent);
        elements.assessmentNext.focus();
    }

    function completeAssessment() {
        const assessment = state.activeAssessment;
        const totalQuestions = state.assessmentQuestions.length;

        if (!assessment) {
            showLessonCatalog();
            return;
        }

        state.assessmentComplete = true;
        elements.assessmentIcon.innerHTML = '';
        elements.assessmentIcon.hidden = true;
        elements.assessmentLabel.textContent = 'Knowledge check complete';
        elements.assessmentHeading.textContent = assessment.title;
        elements.assessmentQuestion.textContent = 'You answered ' + state.assessmentScore + ' of ' + totalQuestions + ' correctly.';
        elements.assessmentOptions.innerHTML = '';
        elements.assessmentFeedback.className = 'assessment-feedback correct';
        elements.assessmentFeedback.textContent = state.assessmentScore === totalQuestions
            ? 'Excellent work. You can retry whenever you want more practice.'
            : 'Nice work. Retry when you are ready; there is no penalty.';
        elements.assessmentFeedback.hidden = false;
        elements.assessmentProgress.max = totalQuestions;
        elements.assessmentProgress.value = totalQuestions;
        elements.assessmentProgress.textContent = totalQuestions + ' of ' + totalQuestions + ' questions complete';
        elements.assessmentProgressText.textContent = totalQuestions + ' of ' + totalQuestions + ' questions complete';
        elements.assessmentNext.hidden = true;
        elements.assessmentRetry.hidden = false;
        elements.assessmentReturn.hidden = false;
        setStatus('Knowledge check complete. ' + state.assessmentScore + ' of ' + totalQuestions + ' correct.');
        elements.assessmentHeading.focus();
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
        ['learn', 'lessons', 'practice', 'review'].forEach(function (mode) {
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
        elements.lessonsPanel.hidden = mode !== 'lessons';

        if (mode === 'lessons') {
            elements.learnDetail.hidden = true;
            elements.iconChoiceSection.hidden = true;
            showLessonCatalog();
            setStatus('Four guided lessons are available. Choose one to preview.');
            return;
        }

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
        elements.lessonsMode.addEventListener('click', function () { setMode('lessons'); });
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
        elements.startAssessment.addEventListener('click', function () {
            const lesson = currentLesson();

            if (lesson) {
                startAssessment(lesson.id);
            }
        });
        elements.exitAssessment.addEventListener('click', function () {
            showLessonCatalog();
            setStatus('Returned to the lesson choices.');
        });
        elements.assessmentOptions.addEventListener('click', function (event) {
            const button = event.target.closest('[data-answer-icon-id]');

            if (!button) {
                return;
            }

            answerAssessment(button.dataset.answerIconId);
        });
        elements.assessmentNext.addEventListener('click', function () {
            if (!state.assessmentAnswered) {
                return;
            }

            if (state.assessmentQuestionIndex === state.assessmentQuestions.length - 1) {
                completeAssessment();
                return;
            }

            state.assessmentQuestionIndex += 1;
            showAssessmentQuestion();
        });
        elements.assessmentRetry.addEventListener('click', function () {
            if (state.activeAssessment) {
                startAssessment(state.activeAssessment.lesson_id);
            }
        });
        elements.assessmentReturn.addEventListener('click', function () {
            showLessonCatalog();
            setStatus('Returned to the lesson choices.');
        });
        elements.resetLessons.addEventListener('click', resetLessonProgress);
        elements.startLesson.addEventListener('click', function () {
            startLesson(elements.startLesson.dataset.lessonId);
        });
        elements.exitLesson.addEventListener('click', function () {
            showLessonCatalog();
            setStatus('Returned to the lesson choices.');
        });
        elements.lessonPrevious.addEventListener('click', function () {
            moveLessonStep(-1);
        });
        elements.lessonNext.addEventListener('click', function () {
            if (elements.lessonNext.dataset.action === 'return') {
                showLessonCatalog();
                setStatus('Returned to the lesson choices.');
                return;
            }

            const lesson = currentLesson();

            if (lesson && state.lessonStepIndex === lesson.steps.length - 1) {
                completeLessonSession();
                return;
            }

            moveLessonStep(1);
        });
        elements.lessonGrid.addEventListener('click', function (event) {
            const button = event.target.closest('[data-lesson-id]');

            if (!button) {
                return;
            }

            showLessonPreview(findLesson(button.dataset.lessonId));
        });
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
            'learn-mode', 'lessons-mode', 'practice-mode', 'review-mode', 'text-size', 'high-contrast',
            'reset-display', 'learn-controls', 'icon-search', 'category-filter',
            'progress-area', 'progress-text', 'learning-progress', 'clear-progress',
            'result-status', 'lessons-panel', 'lesson-catalog-header',
            'lesson-catalog-intro', 'reset-lessons', 'lesson-count', 'lesson-grid', 'lessons-empty',
            'lesson-preview', 'lesson-preview-number', 'lesson-preview-title',
            'lesson-preview-summary', 'lesson-preview-meta', 'start-lesson',
            'lesson-runner', 'exit-lesson', 'lesson-progress-row', 'lesson-progress-text',
            'lesson-progress', 'lesson-step-card', 'lesson-step-icon', 'lesson-step-label',
            'lesson-step-heading', 'lesson-step-instruction', 'lesson-step-practice',
            'lesson-step-prompt', 'lesson-previous', 'start-assessment', 'lesson-next',
            'assessment-runner', 'exit-assessment', 'assessment-progress-text',
            'assessment-progress', 'assessment-icon', 'assessment-label',
            'assessment-heading', 'assessment-question', 'assessment-options',
            'assessment-feedback', 'assessment-next', 'assessment-retry',
            'assessment-return',
            'learn-detail', 'detail-icon', 'detail-category',
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
            const responses = await Promise.all([
                fetch('04_Application/data/icons.json', { cache: 'no-store' }),
                fetch('04_Application/data/lessons.json', { cache: 'no-store' }),
                fetch('04_Application/data/assessments.json', { cache: 'no-store' })
            ]);

            if (!responses[0].ok || !responses[1].ok || !responses[2].ok) {
                throw new Error('Icon, lesson, or assessment data could not be loaded.');
            }

            const data = await Promise.all(responses.map(function (response) {
                return response.json();
            }));
            state.icons = data[0].icons;
            state.lessons = data[1].lessons;
            state.assessments = data[2].assessments;
            normalizeLessonProgress();
            state.filteredIcons = data[0].icons.slice();
            buildCategoryOptions();
            renderLessonCatalog();
            bindEvents();
            updateProgress();
            applyFilters();
            showIconDetail(state.icons[0]);

            if (!('speechSynthesis' in window)) {
                elements.readAloud.disabled = true;
                elements.readAloud.textContent = 'Read-aloud unavailable';
            }

            if ('serviceWorker' in navigator) {
                let refreshingForUpdate = false;

                navigator.serviceWorker.addEventListener('controllerchange', function () {
                    if (refreshingForUpdate) {
                        return;
                    }

                    refreshingForUpdate = true;
                    window.location.reload();
                });

                navigator.serviceWorker.register('service-worker.js').then(function (registration) {
                    registration.update();
                }).catch(function () {
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
