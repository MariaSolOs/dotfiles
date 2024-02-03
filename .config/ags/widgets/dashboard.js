import { exec, fetch, interval } from 'resource:///com/github/Aylur/ags/utils.js';
import { Variable } from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import secret from '../secret.js';

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
 * @param {number} time
 */
const timeToDateString = (time) =>
    new Date(time * 1000).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

export const Dashboard = Widget.Window({
    name: 'dashboard',
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
                    // The current weather in Seattle.
                    Widget.Box({
                        setup: () => {
                            // Update the weather every hour.
                            interval(60 * 60 * 1000, getWeatherData);
                        },
                        vertical: true,
                        spacing: 10,
                        class_name: 'weather-dashboard-box',
                        children: [
                            Widget.Icon({
                                icon: weather.bind().transform(({ icon }) => `weather-${icon}-symbolic`),
                                size: 58,
                            }),
                            Widget.Label({
                                useMarkup: true,
                                label: weather.bind().transform(({ description }) =>
                                    `<i>In Seattle:</i> ${description.charAt(0).toUpperCase()}${description.slice(1)}`
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
                                                label: weather.bind().transform(({ temperature }) =>
                                                    `${temperature.toFixed(0)}°C`
                                                ),
                                            }),
                                            Widget.Label({
                                                xalign: 0,
                                                label: weather.bind().transform(({ feelsLike }) =>
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
                                                label: weather.bind().transform(({ sunrise }) =>
                                                    `Sunrise: ${timeToDateString(sunrise)}`
                                                ),
                                            }),
                                            Widget.Label({
                                                xalign: 0,
                                                label: weather.bind().transform(({ sunset }) =>
                                                    `Sunset: ${timeToDateString(sunset)}`
                                                ),
                                            }),
                                        ],
                                    }),
                                ],
                            }),
                        ],
                    }),
                    // Turning off, rebooting, etc.
                    Widget.Box({
                        vertical: true,
                        vpack: 'center',
                        spacing: 10,
                        class_name: 'power-dashboard-box',
                        children: [
                            Widget.Icon({
                                icon: 'system-shutdown-symbolic',
                                size: 32,
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
                                        on_clicked: () => exec(command),
                                    })
                                ),
                            }),
                        ],
                    }),
                ],
            }),
        ],
    }),
});
