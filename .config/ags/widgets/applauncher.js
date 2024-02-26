import App from 'resource:///com/github/Aylur/ags/app.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { execAsync } from 'resource:///com/github/Aylur/ags/utils.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

const WINDOW_NAME = 'applauncher';

/**
 * @typedef {import('resource:///com/github/Aylur/ags/service/applications.js').Application} App
 */

/**
 * @param {App} app
 */
const launchApp = (app) => {
    App.closeWindow(WINDOW_NAME);

    // If the app is already open, focus its window.
    const appClass = app.wm_class?.toLowerCase() || app.name.toLowerCase();
    for (const client of Hyprland.clients) {
        if (client.initialClass.toLowerCase().includes(appClass)) {
            Hyprland.sendMessage(`dispatch focuswindow address:${client.address}`);
            return;
        }
    }

    app.frequency += 1;

    let executable = app.executable
        .split(/\s+/)
        .filter((str) => !str.startsWith('%') && !str.startsWith('@'))
        .join(' ');

    // Use Wezterm for opening terminal apps.
    if (app.app.get_boolean('Terminal')) {
        executable = `wezterm -e ${executable}`;
    }

    execAsync(executable);
};

/**
 * @param {App} app
 */
const AppItem = (app) =>
    Widget.Button({
        on_clicked: () => launchApp(app),
        attribute: { app },
        child: Widget.Box({
            spacing: 8,
            children: [
                Widget.Icon({
                    icon: app.icon_name || '',
                    size: 32,
                }),
                Widget.Box({
                    vertical: true,
                    children: [
                        Widget.Label({
                            label: app.name,
                            justification: 'left',
                            hexpand: true,
                            xalign: 0,
                        }),
                        Widget.Label({
                            label: app.description,
                            justification: 'left',
                            hexpand: true,
                            xalign: 0,
                            truncate: 'end',
                            max_width_chars: 40,
                            class_name: 'app-description',
                        }),
                    ],
                }),
            ],
        }),
    });

export const AppLauncher = () => {
    let apps = Applications.query('').map(AppItem);

    const appList = Widget.Box({
        vertical: true,
        children: apps,
        spacing: 8,
    });

    // Repopulates the box, so the most frequent apps are on top of the list.
    const repopulateApps = () => {
        apps = Applications.query('').map(AppItem);
        appList.children = apps;
    };

    const entry = Widget.Entry({
        hexpand: true,
        // Launch the first visible item on Enter.
        on_accept: () => {
            const app = apps.find((app) => app.visible);
            if (app) {
                launchApp(app.attribute.app);
            }
        },
        // Filter out the list.
        on_change: ({ text }) =>
            apps.forEach((item) => {
                item.visible = text ? item.attribute.app.match(text) : true;
            }),
    });

    return Widget.Window({
        name: WINDOW_NAME,
        popup: true,
        visible: false,
        keymode: 'on-demand',
        child: Widget.Box({
            vertical: true,
            class_name: 'launcher-scrollable',
            children: [
                entry,
                Widget.Scrollable({
                    hscroll: 'never',
                    child: appList,
                }),
            ],
            setup: (self) =>
                self.hook(App, (_, windowName, visible) => {
                    if (windowName !== WINDOW_NAME) {
                        return;
                    }

                    if (visible) {
                        repopulateApps();
                        entry.text = '';
                        entry.grab_focus();
                    }
                }),
        }),
    });
};
