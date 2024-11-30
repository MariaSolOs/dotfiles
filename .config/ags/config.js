import { AppLauncher } from './widgets/applauncher.js';
// import { Dock } from './widgets/dock.js';
import { NotificationPopups } from './widgets/notification-popups.js';
// import { Calendar, Statusbar } from './widgets/statusbar.js';
import { SystemPopup } from './widgets/system-popup.js';

// Global variables for use in `ags -r`.
(async () => {
    globalThis.backlight = (await import('./services/backlight.js')).default;
    globalThis.audio = (await import('./services/audio.js')).default;
})();

// Compile the CSS and watch for changes.
const scss = `${App.configDir}/style.scss`;
const css = `${App.configDir}/style.css`;
Utils.exec(`sass ${scss} ${css}`);
Utils.monitorFile(
    `${App.configDir}/style.scss`,
    () => {
        Utils.exec(`sass ${scss} ${css}`);
        App.resetCss();
        App.applyCss(css);
    },
);

App.config({
    style: css,
    windows: [
        await AppLauncher(),
        // Calendar,
        // Dock,
        NotificationPopups,
        // Statusbar,
        SystemPopup,
    ],
});
