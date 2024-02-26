import Service from 'resource:///com/github/Aylur/ags/service.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';

class AudioService extends Service {
    static {
        Service.register(
            this,
            { 'audio-changed': ['float'] },
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
        Audio.speaker.is_muted = this.#muted = muted;
    }

    set volume(percent) {
        if (percent < 0) {
            percent = 0;
        }
        if (percent > 1) {
            percent = 1;
        }

        this.muted = false;
        Audio.speaker.volume = this.#volume = percent;
    }

    emitChange() {
        this.emit('audio-changed', this.#volume);
    }

    constructor() {
        super();

        this.#muted = Audio.speaker.is_muted;
        this.#volume = Audio.speaker.volume;
    }
}

export default new AudioService();
