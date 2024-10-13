const audio = await Service.import('audio');

class AudioService extends Service {
    static {
        Service.register(
            this,
            { 'audio-changed': ['float', 'boolean'] },
            {
                'muted': ['boolean', 'rw'],
                'volume': ['float', 'rw'],
            },
        );
    }

    #muted = false;
    #volume = 0;

    get muted() {
        return this.#muted;
    }

    get volume() {
        return this.#volume;
    }

    set muted(muted) {
        audio.speaker.is_muted = this.#muted = muted;
    }

    set volume(percent) {
        if (percent < 0) {
            percent = 0;
        }
        if (percent > 1) {
            percent = 1;
        }

        this.muted = false;
        audio.speaker.volume = this.#volume = percent;
    }

    emitChange(userTriggered = true) {
        this.emit('audio-changed', this.#volume, userTriggered);
    }

    constructor() {
        super();

        this.#muted = !!audio.speaker.is_muted;

        // Emit change after half a second.
        Utils.timeout(500, () => {
            this.#volume = audio.speaker.volume;
            this.emitChange(false);
        });
    }
}

export default new AudioService();
