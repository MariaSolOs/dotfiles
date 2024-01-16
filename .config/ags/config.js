import App from 'resource:///com/github/Aylur/ags/app.js';
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import { exec, execAsync } from 'resource:///com/github/Aylur/ags/utils.js';
import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import { Widget } from 'resource:///com/github/Aylur/ags/widget.js';

// Compile the CSS.
const scss = `${App.configDir}/style.scss`;
const css = `${App.configDir}/style.css`;
exec(`sass ${scss} ${css}`);

/**
 * Removes the double quotes from a string.
 *
 * @param {string} str
 * @returns {string}
 */
const unquoteString = str => str.replace(/"/g, '');

// Whether the cursor is hovering the date box.
const hoveringDate = new Variable(false);

export default {
    style: css,
    windows: [
        Widget.Window({
            name: 'statusbar',
            anchor: ['top', 'left', 'right'],
            margins: [2, 2, 1, 2],
            exclusivity: 'exclusive',
            child: Widget.CenterBox({
                // Battery status.
                start_widget: Widget.Box({
                    class_name: Battery.bind('percent').transform(/** @return {string} */ p => {
                        if (p < 20) return 'pink-box';
                        if (p < 40) return 'yellow-box';
                        return 'green-box';
                    }),
                    hpack: 'start',
                    children: [
                        Widget.Icon({
                            icon: Battery.bind('percent').transform(p =>
                                `battery-level-${Math.floor(p / 10) * 10}-symbolic`
                            ),
                        }),
                        Widget.Label({
                            label: Battery.bind('percent').transform(p => ` ${p.toFixed(0)}%`),
                        }),
                    ],
                }),
                end_widget: Widget.Box({
                    spacing: 2,
                    hpack: 'end',
                    children: [
                        // Time box.
                        Widget.Label({
                            class_name: 'lilac-box',
                            setup: self =>
                                self
                                    .poll(1000, self =>
                                        execAsync(['date', '+"%I:%M %p"'])
                                            .then(date => self.label = `󰅐 ${unquoteString(date)}`)),
                        }),
                        // Date box. When hovering over it, the calendar is shown.
                        Widget.EventBox({
                            child: Widget.Label({
                                class_name: 'lilac-box',
                                setup: self =>
                                    self
                                        .poll(1000, self =>
                                            execAsync(['date', '+"%A, %B %d / %Y"']).then(date =>
                                                self.label = ` ${unquoteString(date)}`
                                            )),
                            }),
                            setup: self =>
                                self
                                    .on('enter-notify-event', () => hoveringDate.setValue(true))
                                    .on('leave-notify-event', () => hoveringDate.setValue(false)),
                        }),
                    ],
                }),
            }),
        }),
        // Calendar window.
        Widget.Window({
            name: 'calendar',
            anchor: ['top', 'right'],
            margins: [2, 2, 0, 0],
            child: Widget.Box({
                css: 'padding: 1px;', // HACK: For the animation to work an initial space allocation is needed.
                child: Widget.Revealer({
                    reveal_child: hoveringDate.bind(),
                    transition: 'slide_down',
                    transition_duration: 300,
                    child: Widget.Box({
                        class_name: 'lilac-box',
                        child: Widget.Calendar({}),
                    }),
                }),
            }),
        }),
    ],
};
