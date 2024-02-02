import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import Audio from '../services/audio.js';
import Backlight from '../services/backlight.js';

/**
 * @typedef {Array<[number, string]>} Intensities
 */

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

                    /** @type {Intensities} */
                    const intensities = [
                        [80, 'high'],
                        [34, 'medium'],
                        [1, 'low'],
                    ];
                    const intensity = intensities.find(([threshold]) => threshold <= brightness * 100)?.[1];

                    updateUI(brightness, `display-brightness-${intensity}-symbolic`);
                }, 'brightness-changed');

                self.hook(Audio, (_, volume) => {
                    if (!volume) {
                        return;
                    }

                    let intensity = '';

                    if (Audio.muted) {
                        intensity = 'muted';
                        volume = 0;
                    } else {
                        /** @type {Intensities} */
                        const intensities = [
                            [101, 'overamplified'],
                            [67, 'high'],
                            [34, 'medium'],
                            [1, 'low'],
                            [0, 'muted'],
                        ];
                        intensity = intensities.find(([threshold]) => threshold <= volume * 100)?.[1]
                            || intensity;
                    }

                    updateUI(volume, `audio-volume-${intensity}-symbolic`);
                }, 'audio-changed');
            },
        }),
    }),
});
