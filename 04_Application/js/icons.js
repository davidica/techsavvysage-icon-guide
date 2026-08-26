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
        volume: '<path d="M11 5 6 9H2v6h4l5 4Z"></path><path d="M15.5 8.5a5 5 0 0 1 0 7"></path><path d="M18 6a8.5 8.5 0 0 1 0 12"></path>'
    };

    function render(name, label) {
        const content = paths[name] || paths.more;
        const accessibleLabel = label ? ' aria-label="' + label + '" role="img"' : ' aria-hidden="true"';

        return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"' + accessibleLabel + '>' + content + '</svg>';
    }

    return {
        render: render
    };
}());
