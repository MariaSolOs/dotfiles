import App from 'resource:///com/github/Aylur/ags/app.js';
import { exec } from 'resource:///com/github/Aylur/ags/utils.js';

import { CalendarWindow, StatusbarWindow } from './statusbar.js';

// Compile the CSS.
const scss = `${App.configDir}/style.scss`;
const css = `${App.configDir}/style.css`;
exec(`sass ${scss} ${css}`);

export default {
    style: css,
    windows: [
        CalendarWindow,
        StatusbarWindow,
    ],
};
