import { capitalize, unquoteString } from '../utils.js';

const battery = await Service.import('battery');
const hyprland = await Service.import('hyprland');
const network = await Service.import('network');
const powerProfiles = await Service.import('powerprofiles');

// Used for accounting for mouse movement when closing windows.
const MOUSE_DELAY = 300;

// Whether the cursor is hovering over the date box.
let hoveringDate = false;

// Whether the cursor is hovering over the calendar.
let hoveringCalendar = false;

export const Statusbar = Widget.Window({
    name: 'statusbar',
    anchor: ['top', 'left', 'right'],
    margins: [2, 5, 1, 5],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
        start_widget: Widget.Box({
            spacing: 2,
            children: [
                // Battery status. The pill's color depends on the level.
                Widget.Box({
                    hpack: 'start',
                    class_name: battery.bind('percent').as((p) => {
                        let color = 'green';
                        if (p < 20) {
                            color = 'pink';
                        } else if (p < 40) {
                            color = 'yellow';
                        }

                        return `${color}-status-box`;
                    }),
                    children: [
                        Widget.Icon({ icon: battery.bind('icon_name') }),
                        Widget.Label({
                            label: battery.bind('percent').as((p) => ` ${p.toFixed(0)}%`),
                        }),
                    ],
                }),
                Widget.Box({
                    class_name: network.wifi.bind('enabled').as((enabled) => `${enabled ? 'green' : 'red'}-status-box`),
                    child: Widget.Icon({
                        icon: network.wifi.bind('icon_name'),
                        size: 13,
                        tooltip_text: network.wifi.bind('ssid').as((ssid) => `SSID: ${ssid || 'unknown'}`),
                    }),
                }),
                Widget.Box({
                    class_name: 'green-status-box',
                    children: [
                        Widget.Icon('power-statistics-symbolic'),
                        Widget.Label({
                            label: powerProfiles.bind('active_profile').as((profile) => ` ${capitalize(profile)}`),
                        }),
                    ],
                }),
            ],
        }),
        // Name/number of the current Hyprland workspace.
        center_widget: Widget.Box({
            class_name: 'lilac-status-box',
            children: [
                Widget.Icon('laptop-symbolic'),
                Widget.Label({
                    setup: (self) =>
                        self.hook(hyprland.active.workspace, () => {
                            self.label = ` ${hyprland.active.workspace.name || hyprland.active.workspace.id}`;
                        }),
                }),
            ],
        }),
        end_widget: Widget.Box({
            spacing: 2,
            hpack: 'end',
            children: [
                // Time box.
                Widget.Label({
                    class_name: 'lilac-status-box',
                    setup: (self) =>
                        self
                            .poll(1000, (self) =>
                                Utils.execAsync(['date', '+"%I:%M %p"'])
                                    .then((date) => self.label = `󰅐 ${unquoteString(date)}`)),
                }),
                // Date box. When hovering over it, the calendar is shown.
                Widget.EventBox({
                    child: Widget.Label({
                        class_name: 'lilac-status-box',
                        setup: (self) =>
                            self
                                .poll(1000, (self) =>
                                    Utils.execAsync(['date', '+"%A, %B %d / %Y"']).then((date) =>
                                        self.label = ` ${unquoteString(date)}`
                                    )),
                    }),
                    setup: (self) =>
                        self
                            .on('enter-notify-event', () => {
                                if (!hoveringCalendar) {
                                    App.openWindow('calendar');
                                }

                                hoveringDate = true;
                            })
                            .on('leave-notify-event', () => {
                                hoveringDate = false;

                                Utils.timeout(MOUSE_DELAY, () => {
                                    if (!hoveringCalendar) {
                                        App.closeWindow('calendar');
                                    }
                                });
                            }),
                }),
            ],
        }),
    }),
});

export const Calendar = Widget.Window({
    name: 'calendar',
    anchor: ['top', 'right'],
    margins: [2, 2, 0, 0],
    visible: false,
    child: Widget.Box({
        class_name: 'lilac-status-box',
        child: Widget.Calendar({
            setup: (self) =>
                self.on('enter-notify-event', () => hoveringCalendar = true)
                    .on('leave-notify-event', () => {
                        hoveringCalendar = false;

                        Utils.timeout(MOUSE_DELAY, () => {
                            if (!hoveringDate) {
                                App.closeWindow('calendar');
                            }
                        });
                    }),
        }),
    }),
});
