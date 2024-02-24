import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
import { lookUpIcon, timeout } from 'resource:///com/github/Aylur/ags/utils.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

export const NotificationPopups = Widget.Window({
    name: 'notifications',
    anchor: ['bottom', 'right'],
    margins: [0, 2, 2, 0],
    layer: 'overlay',
    child: Widget.Box({
        css: 'padding: 1px;', // HACK: See https://aylur.github.io/ags-docs/config/common-issues/#window-doesnt-show-up.
        vertical: true,
        spacing: 2,
        children: Notifications.bind('notifications').as((notifs) =>
            notifs.slice(0, 15).map((notif) => {
                let icon;

                // If present, use the image as the icon.
                if (notif.image) {
                    icon = Widget.Box({
                        class_name: 'notif-image',
                        css: ` background-image:url("${notif.image}");`,
                    });
                } else {
                    // Else use the application's icon, or a fallback !.
                    if (notif.app_entry && lookUpIcon(notif.app_entry)) {
                        icon = notif.app_entry;
                    } else if (lookUpIcon(notif.app_icon)) {
                        icon = notif.app_icon;
                    } else {
                        icon = 'emblem-important-symbolic';
                    }

                    icon = Widget.Icon({ icon, size: 18 });
                }

                return Widget.Button({
                    // Close the notification after 5 seconds.
                    setup: () => timeout(5000, () => notif.close()),
                    on_clicked: () => notif.close(),
                    child: Widget.Box({
                        class_name: 'notif',
                        spacing: 8,
                        children: [
                            icon,
                            Widget.Box({
                                vertical: true,
                                spacing: 2,
                                children: [[notif.app_name, 'notif-title'], [notif.summary, '']].map((
                                    [label, class_name],
                                ) => Widget.Label({
                                    label,
                                    class_name,
                                    hexpand: true,
                                    xalign: 0,
                                    justification: 'left',
                                })),
                            }),
                        ],
                    }),
                });
            })
        ),
    }),
});
