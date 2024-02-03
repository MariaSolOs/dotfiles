import App from 'resource:///com/github/Aylur/ags/app.js';
import { exec, monitorFile } from 'resource:///com/github/Aylur/ags/utils.js';

import { AppLauncher } from './widgets/applauncher.js';
import { Dashboard } from './widgets/dashboard.js';
import { Popups } from './widgets/popups.js';
import { Calendar, Statusbar } from './widgets/statusbar.js';
import { SystemPopup } from './widgets/system-popup.js';

// Global variables for use in `ags -r`.
(async () => {
    globalThis.backlight = (await import('./services/backlight.js')).default;
    globalThis.audio = (await import('./services/audio.js')).default;
})();

// Compile the CSS and watch for changes.
const scss = `${App.configDir}/style.scss`;
const css = `${App.configDir}/style.css`;
exec(`sass ${scss} ${css}`);
monitorFile(
    `${App.configDir}/style.scss`,
    () => {
        exec(`sass ${scss} ${css}`);
        App.resetCss();
        App.applyCss(css);
    },
);

export default {
    style: css,
    windows: [
        AppLauncher(),
        Calendar,
        Dashboard,
        Popups,
        Statusbar,
        SystemPopup,
    ],
};
