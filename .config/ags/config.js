import App from 'resource:///com/github/Aylur/ags/app.js';
import { exec } from 'resource:///com/github/Aylur/ags/utils.js';

import { Popups } from './notifications.js';
import { Calendar, Statusbar } from './statusbar.js';

// Global variables for use in `ags -r`.
(async () => {
    globalThis.backlight = (await import('./services/backlight.js')).default;
})();

// Compile the CSS.
const scss = `${App.configDir}/style.scss`;
const css = `${App.configDir}/style.css`;
exec(`sass ${scss} ${css}`);

export default {
    style: css,
    windows: [
        Calendar,
        Popups,
        Statusbar,
    ],
};
