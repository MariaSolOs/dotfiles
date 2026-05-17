// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/ai/provider.ts
/**
 * Provider registry — manages AI provider instances.
 *
 * Supports multiple instances of the same provider type (e.g., two Claude
 * Agent SDK providers with different configs) keyed by instance ID.
 *
 * Each server (plan review, code review, annotate) should create its own
 * ProviderRegistry or share one — no module-level global state.
 */

import type { AIProvider, AIProviderConfig } from "./types.ts";

// ---------------------------------------------------------------------------
// Factory registry (global — factories are stateless type→constructor maps)
// ---------------------------------------------------------------------------

type ProviderFactory = (config: AIProviderConfig) => Promise<AIProvider>;
const factories = new Map<string, ProviderFactory>();

/** Register a factory function for a provider type. */
export function registerProviderFactory(
    type: string,
    factory: ProviderFactory,
): void {
    factories.set(type, factory);
}

/** Create a provider from config using a registered factory. Does NOT auto-register. */
export async function createProvider(
    config: AIProviderConfig,
): Promise<AIProvider> {
    const factory = factories.get(config.type);
    if (!factory) {
        throw new Error(
            `No AI provider factory registered for type "${config.type}". ` +
                `Available: ${[...factories.keys()].join(", ") || "(none)"}`,
        );
    }
    return factory(config);
}

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

export class ProviderRegistry {
    private instances = new Map<string, AIProvider>();

    /**
     * Register a provider instance under an ID.
     * If no instanceId is provided, uses `provider.name`.
     * Returns the instanceId used.
     */
    register(provider: AIProvider, instanceId?: string): string {
        const id = instanceId ?? provider.name;
        this.instances.set(id, provider);
        return id;
    }

    /** Get a provider by instance ID. */
    get(instanceId: string): AIProvider | undefined {
        return this.instances.get(instanceId);
    }

    /** Get the first registered provider (convenience for single-provider setups). */
    getDefault(): { id: string; provider: AIProvider } | undefined {
        const first = this.instances.entries().next();
        if (first.done) return undefined;
        return { id: first.value[0], provider: first.value[1] };
    }

    /** Get all instances of a given provider type (by provider.name). */
    getByType(typeName: string): AIProvider[] {
        return [...this.instances.values()].filter((p) => p.name === typeName);
    }

    /** List all instance IDs. */
    list(): string[] {
        return [...this.instances.keys()];
    }

    /** Dispose and remove a single instance. No-op if not found. */
    dispose(instanceId: string): void {
        const provider = this.instances.get(instanceId);
        if (provider) {
            provider.dispose();
            this.instances.delete(instanceId);
        }
    }

    /** Dispose all providers and clear the registry. */
    disposeAll(): void {
        for (const provider of this.instances.values()) {
            provider.dispose();
        }
        this.instances.clear();
    }

    /** Number of registered instances. */
    get size(): number {
        return this.instances.size;
    }
}
