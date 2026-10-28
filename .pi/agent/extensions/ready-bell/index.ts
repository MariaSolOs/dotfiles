import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
    // agent_settled (not agent_end) fires once no retry, compaction, or queued run remains,
    // so the bell rings only when Pi is actually waiting for input.
    pi.on("agent_settled", async () => {
        // Emit BEL so Ghostty can apply its configured bell behavior when Pi is ready.
        process.stdout.write("\x07");
    });
}
