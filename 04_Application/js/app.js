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
