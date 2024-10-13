class BacklightService extends Service {
    static {
        Service.register(
            this,
            { 'brightness-changed': ['float', 'boolean'] },
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

    emitChange(userTriggered = true) {
        this.emit('brightness-changed', this.#brightness, userTriggered);
    }

    constructor() {
        super();

        // Emit change after half a second.
        Utils.timeout(500, () => {
            this.#brightness = Number(Utils.exec('brightnessctl g')) / Number(Utils.exec('brightnessctl m'));
            this.emitChange(false);
        });
    }
}

export default new BacklightService();
