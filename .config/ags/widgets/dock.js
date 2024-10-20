import Audio from '../services/audio.js';
import Backlight from '../services/backlight.js';

import Gdk from 'gi://Gdk';

const hyprland = await Service.import('hyprland');

const BacklightInfo = Widget.Box({
    spacing: 4,
    class_name: 'system-info',
    children: [
        Widget.Icon({ icon: 'display-brightness-medium-symbolic', size: 32, tooltip_text: 'Screen backlight' }),
        Widget.Label({
            setup: (self) => {
                self.hook(Backlight, (_, value) => {
                    if (value === undefined) {
                        return;
                    }
                    self.label = `${(value * 100).toFixed()}%`;
                }, 'brightness-changed');
            },
        }),
    ],
});

const VolumeInfo = Widget.Box({
    spacing: 4,
    class_name: 'system-info',
    children: [
        Widget.Icon({ icon: 'audio-volume-high-symbolic', size: 32, tooltip_text: 'Volume' }),
        Widget.Label({
            setup: (self) => {
                self.hook(Audio, (_, value) => {
                    if (value === undefined) {
                        return;
                    }
                    self.label = Audio.muted ? 'Muted' : `${(value * 100).toFixed()}%`;
                }, 'audio-changed');
            },
        }),
    ],
});

const KeyboardButton = Widget.Button({
    class_name: 'dock-box',
    child: Widget.Icon({
        icon: 'preferences-desktop-keyboard-symbolic',
        size: 32,
        tooltip_text: 'Switch xkblayout',
    }),
    on_clicked: async () => {
        const keyboard = await Utils.execAsync(
            'bash -c "hyprctl devices -j | jq -r \'.keyboards[] | select(.main) | .name\'"',
        );
        await hyprland.messageAsync(`switchxkblayout ${keyboard} next`);
        const layout = await Utils.execAsync(
            'bash -c "hyprctl devices -j | jq -r \'.keyboards[] | select(.main) | .active_keymap\'"',
        );
        await Utils.notify({
            appName: 'system',
            summary: 'xkblayout',
            iconName: 'preferences-desktop-keyboard-symbolic',
            body: `Active layout: ${layout.includes('intl') ? 'US (intl)' : 'US'}`,
        });
    },
});

const ShutdownButton = () => {
    const menu = Widget.Menu({
        class_name: 'dock-menu',
        children: [
            { icon: 'system-shutdown-symbolic', label: 'Power Off', command: 'poweroff' },
            { icon: 'system-reboot-symbolic', label: 'Reboot', command: 'reboot' },
        ].map(({ icon, label, command }) =>
            Widget.MenuItem({
                child: Widget.Box({
                    children: [
                        Widget.Icon({ icon, size: 14 }),
                        Widget.Label(` ${label}`),
                    ],
                }),
                on_activate: () => Utils.execAsync(command),
            })
        ),
    });

    return Widget.Button({
        class_name: 'dock-box',
        child: Widget.Icon({
            icon: 'system-shutdown-symbolic',
            size: 32,
            tooltip_text: 'Shutdown',
        }),
        on_clicked: (self) => menu.popup_at_widget(self, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null),
    });
};

export const Dock = Widget.Window({
    name: 'dock',
    layer: 'bottom',
    anchor: ['bottom', 'left', 'right'],
    margins: [1, 2],
    child: Widget.CenterBox({
        class_name: 'center_box',
        start_widget: Widget.Box({ children: [BacklightInfo, VolumeInfo] }),
        end_widget: Widget.Box({
            hpack: 'end',
            children: [KeyboardButton, ShutdownButton()],
        }),
    }),
});
