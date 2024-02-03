import { exec } from 'resource:///com/github/Aylur/ags/utils.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

export const Dashboard = Widget.Window({
    name: 'dashboard',
    visible: false,
    keymode: 'on-demand',
    popup: true,
    child: Widget.Overlay({
        child: Widget.Box({
            class_name: 'dashboard-overlay',
        }),
        overlays: [
            Widget.Box({
                hpack: 'center',
                children: [
                    // Turning off, rebooting, etc.
                    Widget.Box({
                        vertical: true,
                        spacing: 10,
                        vpack: 'center',
                        class_name: 'power-box',
                        children: [
                            Widget.Icon({
                                icon: 'system-shutdown-symbolic',
                                size: 32,
                            }),
                            Widget.Box({
                                vertical: true,
                                spacing: 4,
                                children: [
                                    { label: 'Power Off', command: 'poweroff' },
                                    { label: 'Reboot', command: 'reboot' },
                                ].map(({ label, command }) =>
                                    Widget.Button({
                                        label,
                                        on_clicked: () => exec(command),
                                    })
                                ),
                            }),
                        ],
                    }),
                ],
            }),
        ],
    }),
});
