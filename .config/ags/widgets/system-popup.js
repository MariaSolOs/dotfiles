import Audio from '../services/audio.js';
import Backlight from '../services/backlight.js';

// For debouncing the popup's auto-closing.
let closeTimeoutId = null;

// The current icon of the popup.
const icon = Variable('');

// The value of the progress circle.
const value = Variable(0);

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

/**
 * @param {Array<[number, string]>} intensities
 * @param {number} value
 */
const getIntensity = (intensities, value) => {
    value *= 100;
    return intensities.find(([threshold]) => threshold <= value)?.[1] || '';
};

export const SystemPopup = Widget.Window({
    name: 'system-popup',
    layer: 'overlay',
    child: Widget.Box({
        css: 'padding: 1px;', // HACK: See https://aylur.github.io/ags-docs/config/common-issues/#window-doesnt-show-up.
        child: Widget.Revealer({
            reveal_child: icon.bind().as((icon) => !!icon),
            transition: 'crossfade',
            child: Widget.CircularProgress({
                class_name: 'system-popup',
                value: value.bind(),
                rounded: value.bind().as((value) => value > 0),
                child: Widget.Icon({
                    icon: icon.bind(),
                    size: 58,
                }),
            }),
            setup: (self) => {
                // Listen to changes in the screen brightness and volume.
                self.hook(Backlight, (_, brightness, userTriggered) => {
                    if (!brightness || !userTriggered) {
                        return;
                    }

                    const intensity = getIntensity([[80, 'high'], [34, 'medium'], [1, 'low']], brightness);
                    updateUI(brightness, `display-brightness-${intensity}-symbolic`);
                }, 'brightness-changed');

                self.hook(Audio, (_, volume, userTriggered) => {
                    if (!volume || !userTriggered) {
                        return;
                    }

                    let intensity = '';

                    if (Audio.muted) {
                        intensity = 'muted-blocking';
                        volume = 0;
                    } else {
                        intensity = getIntensity(
                            [[101, 'overamplified'], [67, 'high'], [34, 'medium'], [1, 'low'], [0, 'muted']],
                            volume,
                        );
                    }

                    updateUI(volume, `audio-volume-${intensity}-symbolic`);
                }, 'audio-changed');
            },
        }),
    }),
});
