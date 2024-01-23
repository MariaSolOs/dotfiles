import Service from 'resource:///com/github/Aylur/ags/service.js';
import { exec, execAsync } from 'resource:///com/github/Aylur/ags/utils.js';

class BacklightService extends Service {
    static {
        Service.register(
            this,
            { 'brightness-changed': ['float'] },
            { 'brightness': ['float', 'rw'] },
        );
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

    emitChange() {
        this.emit('brightness-changed', this.#brightness);
    }

    constructor() {
        super();

        this.#brightness = Number(exec('brightnessctl g')) / Number(exec('brightnessctl m'));
    }
}

export default new BacklightService();
