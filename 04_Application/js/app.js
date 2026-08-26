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
