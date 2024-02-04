import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
import { lookUpIcon } from 'resource:///com/github/Aylur/ags/utils.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

export const Popups = Widget.Window({
    name: 'notifications',
    anchor: ['bottom', 'right'],
    margins: [0, 2, 2, 0],
    child: Widget.Box({
        css: 'padding: 1px;', // HACK: See https://aylur.github.io/ags-docs/config/common-issues/#window-doesnt-show-up.
        vertical: true,
        spacing: 2,
        children: Notifications.bind('popups').transform((popups) =>
            popups.slice(0, 15).map((popup) => {
                let icon;

                // If present, use the image as the icon.
                if (popup.image) {
                    icon = Widget.Box({
                        css: `
                            background-image: url("${popup.image}");
                            background-size: contain;
                            background-repeat: no-repeat;
                            background-position: center;
                        `,
                    });
                } else {
                    // Else use the application's icon, or a fallback !.
                    if (popup.app_entry && lookUpIcon(popup.app_entry)) {
                        icon = popup.app_entry;
                    } else if (lookUpIcon(popup.app_icon)) {
                        icon = popup.app_icon;
                    } else {
                        icon = 'emblem-important-symbolic';
                    }

                    icon = Widget.Icon({ icon, size: 16 });
                }

                return Widget.Button({
                    on_clicked: () => popup.close(),
                    child: Widget.Box({
                        class_name: 'popup',
                        spacing: 8,
                        children: [
                            icon,
                            Widget.Box({
                                vertical: true,
                                spacing: 2,
                                children: [[popup.app_name, 'popup-title'], [popup.summary, '']].map((
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
