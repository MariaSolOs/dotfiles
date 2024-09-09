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

        Utils.execAsync(`brightnessctl s ${percent * 100}% -q`)
            .then(() => {
                this.#brightness = percent;
            })
            .catch(console.error);
    }

    emitChange() {
        this.emit('brightness-changed', this.#brightness);
    }

    constructor() {
        super();

        this.#brightness = Number(Utils.exec('brightnessctl g')) / Number(Utils.exec('brightnessctl m'));
    }
}

export default new BacklightService();
