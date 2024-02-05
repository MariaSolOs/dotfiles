import App from 'resource:///com/github/Aylur/ags/app.js';
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { execAsync, timeout } from 'resource:///com/github/Aylur/ags/utils.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

// Used for accounting for mouse movement when closing windows.
const MOUSE_DELAY = 300;

/**
 * Removes the double quotes from a string.
 *
 * @param {string} str
 */
const unquoteString = (str) => str.replace(/"/g, '');

// Whether the cursor is hovering the date box.
let hoveringDate = false;

// Whether the cursor is hovering the calendar.
let hoveringCalendar = false;

export const Statusbar = Widget.Window({
    name: 'statusbar',
    anchor: ['top', 'left', 'right'],
    margins: [2, 2, 1, 2],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
        // Battery status. The pill's color depends on the level.
        start_widget: Widget.Box({
            hpack: 'start',
            class_name: Battery.bind('percent').transform((p) => {
                if (p < 20) {
                    return 'pink-status-box';
                }
                if (p < 40) {
                    return 'yellow-status-box';
                }

                return 'green-status-box';
            }),
            children: [
                Widget.Icon({ icon: Battery.bind('icon_name') }),
                Widget.Label({
                    label: Battery.bind('percent').transform((p) => ` ${p.toFixed(0)}%`),
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
                        self.hook(Hyprland.active.workspace, () => {
                            self.label = ` ${Hyprland.active.workspace.name || Hyprland.active.workspace.id}`;
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
                                execAsync(['date', '+"%I:%M %p"'])
                                    .then((date) => self.label = `󰅐 ${unquoteString(date)}`)),
                }),
                // Date box. When hovering over it, the calendar is shown.
                Widget.EventBox({
                    child: Widget.Label({
                        class_name: 'lilac-status-box',
                        setup: (self) =>
                            self
                                .poll(1000, (self) =>
                                    execAsync(['date', '+"%A, %B %d / %Y"']).then((date) =>
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

                                timeout(MOUSE_DELAY, () => {
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

                        timeout(MOUSE_DELAY, () => {
                            if (!hoveringDate) {
                                App.closeWindow('calendar');
                            }
                        });
                    }),
        }),
    }),
});
