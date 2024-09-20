const notifications = await Service.import('notifications');

/**
 * @param {string} label
 */
const notifLabel = (label) =>
    Widget.Label({
        label,
        use_markup: true,
        hexpand: true,
        xalign: 0,
        justification: 'left',
        truncate: 'end',
        width_chars: 35,
    });

export const NotificationPopups = Widget.Window({
    name: 'notifications',
    anchor: ['bottom', 'right'],
    margins: [0, 2, 2, 0],
    layer: 'overlay',
    child: Widget.Box({
        css: 'padding: 1px;', // HACK: See https://aylur.github.io/ags-docs/config/common-issues/#window-doesnt-show-up.
        vertical: true,
        spacing: 2,
        children: notifications.bind('notifications').as((notifs) =>
            notifs.slice(0, 5).map((notif) => {
                let icon;

                // If present, use the image as the icon.
                if (notif.image) {
                    icon = Widget.Box({
                        class_name: 'notif-image',
                        css: ` background-image:url("${notif.image}");`,
                    });
                } else {
                    // Else use the application's icon, or a fallback !.
                    if (notif.app_entry && Utils.lookUpIcon(notif.app_entry)) {
                        icon = notif.app_entry;
                    } else if (Utils.lookUpIcon(notif.app_icon)) {
                        icon = notif.app_icon;
                    } else {
                        icon = 'emblem-important-symbolic';
                    }

                    icon = Widget.Icon({ icon, size: 18 });
                }

                const labels = [`<b><i>${notif.app_name}</i></b>`, `<i>${notif.summary}</i>`];
                if (notif.body) {
                    labels.push(notif.body);
                }

                return Widget.Button({
                    // Autoclose the notification after 5 seconds.
                    setup: () => Utils.timeout(5000, () => notif.close()),
                    on_clicked: () => notif.close(),
                    child: Widget.Box({
                        class_name: 'notif',
                        spacing: 8,
                        children: [
                            icon,
                            Widget.Box({
                                vertical: true,
                                children: labels.map(notifLabel),
                            }),
                        ],
                    }),
                });
            })
        ),
    }),
});
