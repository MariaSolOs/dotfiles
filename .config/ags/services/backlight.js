import Service from 'resource:///com/github/Aylur/ags/service.js';
import { exec, execAsync } from 'resource:///com/github/Aylur/ags/utils.js';

class BacklightService extends Service {
    static {
        Service.register(this, {}, {
            'brightness': ['float', 'rw'],
        });
    }

    #brightness = 0;

    get brightness() {
        return this.#brightness;
    }

    set brightness(percent) {
        if (percent < 0) {
            percent = 0;
        }
        if (percent > 1) {
            percent = 1;
        }

        execAsync(`brightnessctl s ${percent * 100}% -q`)
            .then(() => {
                this.#brightness = percent;
                this.changed('brightness');
            })
            .catch(console.error);
    }

    notify() {
        // Send a notification with the current brightness value.
        execAsync([
            'notify-send',
            '-a',
            'Backlight',
            '-i',
            'display-brightness-medium-symbolic',
            '-r',
            '1',
            '-t',
            '2000',
            `${(this.#brightness * 100).toFixed(0)}%`,
        ]).catch(console.error);
    }

    constructor() {
        super();

        this.#brightness = Number(exec('brightnessctl g')) / Number(exec('brightnessctl m'));
    }
}

export default new BacklightService();
