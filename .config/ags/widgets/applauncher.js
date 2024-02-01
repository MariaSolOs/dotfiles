import App from 'resource:///com/github/Aylur/ags/app.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
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

    // Use Wezterm for opening terminal apps.
    const launchCommand = app.app.get_boolean('Terminal') ? 'wezterm -e' : 'sh -c';

    // Use the first word of the executable to handle cases like "nvim %F".
    const executable = app.executable.split(' ')[0];

    execAsync(['hyprctl', 'dispatch', 'exec', `${launchCommand} ${executable}`]);
    app.frequency += 1;
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
        // Launch the first item on Enter.
        on_accept: () => {
            if (apps[0]) {
                launchApp(apps[0].attribute.app);
            }
        },
        // Filter out the list.
        on_change: ({ text }) =>
            apps.forEach((item) => {
                item.visible = item.attribute.app.match(text);
            }),
    });

    return Widget.Window({
        name: WINDOW_NAME,
        popup: true,
        visible: false,
        focusable: true,
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
