import App from 'resource:///com/github/Aylur/ags/app.js';
import { exec } from 'resource:///com/github/Aylur/ags/utils.js';
import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import { Widget } from 'resource:///com/github/Aylur/ags/widget.js';

// Compile the CSS.
const scss = `${App.configDir}/style.scss`;
const css = `${App.configDir}/style.css`;
exec(`sass ${scss} ${css}`);

// Current time.
const time = new Variable('', {
    poll: [1000, 'date +"%I:%M %p"', out => `󰅐 ${out}`],
});

// Current date.
const date = new Variable('', {
    poll: [1000, 'date +"%A, %B %d / %Y"', out => ` ${out}`],
});

// Whether the cursor is hovering the date box.
const hoveringDate = new Variable(false);

export default {
    style: css,
    windows: [
        Widget.Window({
            name: 'statusbar',
            anchor: ['top', 'left', 'right'],
            height_request: 16,
            margins: [2, 2, 1, 2],
            exclusivity: 'exclusive',
            child: Widget.Box({
                spacing: 2,
                hpack: 'end',
                children: [
                    // Time box.
                    Widget.Label({
                        class_name: 'box',
                        label: time.bind(),
                    }),
                    // Date box.
                    Widget.EventBox({
                        child: Widget.Label({
                            class_name: 'box',
                            label: date.bind(),
                        }),
                        setup: self =>
                            self
                                .on('enter-notify-event', () => hoveringDate.setValue(true))
                                .on('leave-notify-event', () => hoveringDate.setValue(false)),
                    }),
                ],
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
                        class_name: 'box',
                        child: Widget.Calendar({}),
                    }),
                }),
            }),
        }),
    ],
};
