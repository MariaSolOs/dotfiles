import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
    pi.on("agent_end", async () => {
        // Emit BEL so Ghostty can apply its configured bell behavior when Pi is ready.
        process.stdout.write("\x07");
    });
}
