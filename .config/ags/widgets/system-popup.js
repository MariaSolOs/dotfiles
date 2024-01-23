import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import Backlight from '../services/backlight.js';

// For debouncing the popup's auto-closing.
let closeTimeoutId = null;

// The current icon of the system popup.
const icon = new Variable('');

// The value of the progress circle.
const value = new Variable(0);

export const SystemPopup = Widget.Window({
    name: 'system-popup',
    child: Widget.Box({
        css: 'padding: 1px;', // HACK: See https://aylur.github.io/ags-docs/config/common-issues/#window-doesnt-show-up.
        child: Widget.Revealer({
            reveal_child: icon.bind().transform((icon) => !!icon),
            transition: 'crossfade',
            child: Widget.CircularProgress({
                class_name: 'system-popup',
                value: value.bind(),
                rounded: true,
                child: Widget.Icon({
                    icon: icon.bind(),
                    size: 32,
                }),
            }),
            setup: (self) =>
                // Display the brightness value when changing it.
                self.hook(Backlight, (_, brightness) => {
                    if (!brightness) {
                        return;
                    }

                    value.setValue(brightness);
                    icon.setValue('display-brightness-medium-symbolic');

                    // Hide the popup after a second, unless the brightness is changed again.
                    if (closeTimeoutId) {
                        clearTimeout(closeTimeoutId);
                    }
                    closeTimeoutId = setTimeout(() => icon.setValue(''), 1000);
                }, 'brightness-changed'),
        }),
    }),
});
