// revisar Pi loader (managed by scripts/setup-pi.mjs).
// Keep this file path-independent in Pi config. Implementation and tests live
// in the registered checkout; this JSON file is machine-local, not review state.
import { readFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default async function loadRevisar(pi: ExtensionAPI) {
    const stateHome = path.isAbsolute(process.env.XDG_STATE_HOME ?? "")
        ? process.env.XDG_STATE_HOME!
        : path.join(os.homedir(), ".local", "state");
    const registration = path.join(stateHome, "revisar", "checkout.json");
    let factory: (pi: ExtensionAPI) => void | Promise<void>;
    try {
        const config = JSON.parse(await readFile(registration, "utf8"));
        if (
            typeof config?.checkout !== "string" ||
            !path.isAbsolute(config.checkout)
        ) {
            throw new Error("checkout must be an absolute path");
        }
        // Pi loads this through jiti with module caching disabled. Keep the
        // dynamic import inside the factory so /reload rereads the registration.
        const entry = path.join(
            config.checkout,
            "integrations",
            "pi",
            "index.ts",
        );
        const module = await import(pathToFileURL(entry).href);
        if (typeof module.default !== "function") {
            throw new Error("registered extension has no default factory");
        }
        factory = module.default;
    } catch (error) {
        // Synced Pi config should remain usable on a new computer before this
        // checkout is registered, or after it has moved/disappeared.
        pi.registerCommand("revisar", {
            description:
                "Register the local revisar checkout to enable reviews",
            handler: async (_args, ctx) => {
                ctx.ui.notify(
                    `revisar is not configured: ${(error as Error).message}. Run node scripts/setup-pi.mjs from your revisar checkout, then /reload. Registration: ${registration}`,
                    "error",
                );
            },
        });
        return;
    }
    await factory(pi);
}
