const WINDOW_NAME = 'applauncher';

/**
 * @typedef {import('types/service/applications').Application} App
 */

/**
 * @param {App} app
 */
const launchApp = async (app) => {
    App.closeWindow(WINDOW_NAME);

    // If the app is already open, focus its window.
    const hyprland = await Service.import('hyprland');

    const appClass = app.wm_class?.toLowerCase() || app.name.toLowerCase();
    for (const client of hyprland.clients) {
        if (client.initialClass.toLowerCase().includes(appClass)) {
            return hyprland.messageAsync(`dispatch focuswindow address:${client.address}`);
        }
    }

    app.frequency += 1;

    let executable = app.executable
        .split(/\s+/)
        .filter((str) => !str.startsWith('%') && !str.startsWith('@'))
        .join(' ');

    // Use kitty for opening terminal apps.
    if (app.app.get_boolean('Terminal')) {
        executable = `kitty -e ${executable}`;
    }

    // Turn off fullscreen mode before launching new apps.
    const fullscreen = await Utils.execAsync('bash -c "hyprctl activewindow -j | jq .fullscreen"');
    if (fullscreen === 'true') {
        await hyprland.messageAsync('dispatch fullscreen 0');
    }

    return Utils.execAsync(executable);
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

export const AppLauncher = async () => {
    const applications = await Service.import('applications');
    let apps = applications.query('').map(AppItem);

    const appList = Widget.Box({
        vertical: true,
        children: apps,
        spacing: 8,
    });

    // Repopulates the box, so the most frequent apps are on top of the list.
    const repopulateApps = () => {
        apps = applications.query('').map(AppItem);
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
        setup: (self) => self.keybind('Escape', () => App.closeWindow(WINDOW_NAME)),
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
