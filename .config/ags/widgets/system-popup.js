import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import Audio from '../services/audio.js';
import Backlight from '../services/backlight.js';

// For debouncing the popup's auto-closing.
let closeTimeoutId = null;

// The current icon of the system popup.
const icon = new Variable('');

// The value of the progress circle.
const value = new Variable(0);

/**
 * @param {number} newValue
 * @param {string} newIcon
 */
const updateUI = (newValue, newIcon) => {
    value.setValue(newValue);
    icon.setValue(newIcon);

    // Hide the popup after a second, unless the value is changed again.
    if (closeTimeoutId) {
        clearTimeout(closeTimeoutId);
    }
    closeTimeoutId = setTimeout(() => icon.setValue(''), 1000);
};

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
            setup: (self) => {
                // Listen to changes in the screen brightness and volume.
                self.hook(Backlight, (_, brightness) => {
                    if (!brightness) {
                        return;
                    }

                    updateUI(brightness, 'display-brightness-medium-symbolic');
                }, 'brightness-changed');

                self.hook(Audio, (_, volume) => {
                    if (!volume) {
                        return;
                    }

                    let icon = '';

                    if (Audio.muted) {
                        icon = 'muted';
                        volume = 0;
                    } else {
                        /**
                         * @type {Array<[number, string]>}
                         */
                        const icons = [
                            [101, 'overamplified'],
                            [67, 'high'],
                            [34, 'medium'],
                            [1, 'low'],
                            [0, 'muted'],
                        ];
                        icon = icons.find(([threshold]) => threshold <= volume * 100)?.[1]
                            || icon;
                    }

                    updateUI(volume, `audio-volume-${icon}-symbolic`);
                }, 'audio-changed');
            },
        }),
    }),
});
