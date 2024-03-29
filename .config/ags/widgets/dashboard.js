import App from 'resource:///com/github/Aylur/ags/app.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { execAsync, fetch, interval } from 'resource:///com/github/Aylur/ags/utils.js';
import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import secret from '../secret.js';
import { unquoteString } from '../utils.js';

const WINDOW_NAME = 'dashboard';

const weather = new Variable({
    description: '',
    feelsLike: 0,
    icon: 'fog',
    sunrise: 0,
    sunset: 0,
    temperature: 0,
});

const getWeatherData = async () => {
    try {
        /**
         * Data format documented in https://openweathermap.org/current.
         * @type {{
         *  weather: { main: string, description: string }[],
         *  main: { temp: number,  feels_like: number },
         *  sys: { sunrise: number, sunset: number },
         * }}
         */
        const data = await fetch(
            `https://api.openweathermap.org/data/2.5/weather?lat=${secret.WEATHER_LAT}&lon=${secret.WEATHER_LON}&units=metric&appid=${secret.OPEN_WEATHER_API_KEY}`,
        ).then((res) => res.json());

        // Get the icon for the current weather.
        let icon = 'fog';
        switch (data.weather[0].main) {
            case 'Clear':
                icon = 'clear';
                break;
            case 'Clouds':
                icon = 'overcast';
                break;
            case 'Drizzle':
                icon = 'showers-scattered';
                break;
            case 'Rain':
                icon = 'showers';
                break;
            case 'Snow':
                icon = 'snow';
                break;
            case 'Thunderstorm':
                icon = 'storm';
                break;
        }

        weather.setValue({
            icon,
            description: data.weather[0].description,
            feelsLike: data.main.feels_like,
            sunrise: data.sys.sunrise,
            sunset: data.sys.sunset,
            temperature: data.main.temp,
        });
    } catch (error) {
        console.error(error);
    }
};

/**
 * @param {import('resource:///com/github/Aylur/ags/widget.js').Button} button
 */
const updateKeyboardLayout = (button) => {
    execAsync(
        'bash -c "hyprctl devices -j | jq -r \'.keyboards[] | select(.main) | .active_keymap\'"',
    ).then((layout) => {
        button.label = layout.includes('intl') ? 'US (intl) -> US' : 'US -> US (intl)';
    });
};

/**
 * @param {number} time
 */
const timeToDateString = (time) =>
    new Date(time * 1000).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

const DateBox = () => {
    const weekdayLabel = Widget.Label({ class_name: 'dashboard-date' });
    const dayLabel = Widget.Label({ class_name: 'dashboard-weekday' });
    const dateLabel = Widget.Label({ class_name: 'dashboard-date' });

    return Widget.Box({
        class_name: 'date-dashboard',
        hpack: 'end',
        vertical: true,
        setup: (self) =>
            self
                .poll(1000, () =>
                    execAsync(['date', '+"%A %b %d %Y"']).then((date) => {
                        const [weekday, month, day, year] = unquoteString(date).split(
                            ' ',
                        );

                        weekdayLabel.label = weekday;
                        dayLabel.label = day;
                        dateLabel.label = `${month} ${year}`;
                    })),
        children: [weekdayLabel, dayLabel, dateLabel],
    });
};

export const Dashboard = Widget.Window({
    name: WINDOW_NAME,
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
                vpack: 'center',
                spacing: 8,
                children: [
                    Widget.Box({
                        vertical: true,
                        vpack: 'center',
                        spacing: 8,
                        children: [
                            // Simple date box.
                            DateBox(),
                            // The current weather in Seattle.
                            Widget.Box({
                                setup: () => {
                                    // Update the weather every hour.
                                    interval(60 * 60 * 1000, getWeatherData);
                                },
                                vertical: true,
                                vpack: 'center',
                                spacing: 10,
                                class_name: 'weather-dashboard',
                                children: [
                                    Widget.Icon({
                                        icon: weather.bind().as(({ icon }) => `weather-${icon}-symbolic`),
                                        size: 58,
                                    }),
                                    Widget.Label({
                                        use_markup: true,
                                        label: weather.bind().as(({ description }) =>
                                            `<i>In Seattle:</i> ${description.charAt(0).toUpperCase()}${description.slice(1)
                                            }`
                                        ),
                                    }),
                                    Widget.Box({
                                        spacing: 16,
                                        children: [
                                            Widget.Box({
                                                vertical: true,
                                                spacing: 4,
                                                children: [
                                                    Widget.Label({
                                                        xalign: 0,
                                                        label: weather.bind().as(({ temperature }) =>
                                                            `${temperature.toFixed(0)}°C`
                                                        ),
                                                    }),
                                                    Widget.Label({
                                                        xalign: 0,
                                                        label: weather.bind().as(({ feelsLike }) =>
                                                            `Feels like: ${feelsLike.toFixed(0)}°C`
                                                        ),
                                                    }),
                                                ],
                                            }),
                                            Widget.Box({
                                                vertical: true,
                                                spacing: 4,
                                                children: [
                                                    Widget.Label({
                                                        xalign: 0,
                                                        label: weather.bind().as(({ sunrise }) =>
                                                            `Sunrise: ${timeToDateString(sunrise)}`
                                                        ),
                                                    }),
                                                    Widget.Label({
                                                        xalign: 0,
                                                        label: weather.bind().as(({ sunset }) =>
                                                            `Sunset: ${timeToDateString(sunset)}`
                                                        ),
                                                    }),
                                                ],
                                            }),
                                        ],
                                    }),
                                ],
                            }),
                        ],
                    }),
                    Widget.Box({
                        vertical: true,
                        spacing: 8,
                        vpack: 'center',
                        children: [
                            // Keyboard button, used to toggle the keyboard layout.
                            Widget.Box({
                                class_name: 'keyboard-dashboard',
                                vertical: true,
                                spacing: 4,
                                children: [
                                    Widget.Icon({
                                        icon: 'preferences-desktop-keyboard-shortcuts-symbolic',
                                        size: 48,
                                    }),
                                    Widget.Button({
                                        setup: (self) => {
                                            updateKeyboardLayout(self);
                                            Hyprland.connect('keyboard-layout', () => updateKeyboardLayout(self));
                                        },
                                        on_clicked: () =>
                                            Hyprland.messageAsync('switchxkblayout keyd-virtual-keyboard next'),
                                    }),
                                ],
                            }),
                            // Email button.
                            Widget.Box({
                                class_name: 'mail-dashboard',
                                vertical: true,
                                spacing: 4,
                                children: [
                                    Widget.Icon({
                                        icon: 'folder-mail-symbolic',
                                        size: 48,
                                    }),
                                    Widget.Button({
                                        label: 'Email',
                                        on_clicked: () => {
                                            App.closeWindow(WINDOW_NAME);
                                            Hyprland.messageAsync('dispatch workspace name:email');
                                        },
                                    }),
                                ],
                            }),
                            // Turning off, rebooting, etc.
                            Widget.Box({
                                vertical: true,
                                spacing: 4,
                                class_name: 'power-dashboard',
                                children: [
                                    Widget.Icon({
                                        icon: 'system-shutdown-symbolic',
                                        size: 48,
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
                                                on_clicked: () => execAsync(command),
                                            })
                                        ),
                                    }),
                                ],
                            }),
                        ],
                    }),
                ],
            }),
        ],
    }),
});
