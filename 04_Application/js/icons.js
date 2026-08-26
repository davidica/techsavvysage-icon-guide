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
