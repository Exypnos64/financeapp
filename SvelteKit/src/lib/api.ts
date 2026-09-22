import { error } from '@sveltejs/kit';
import { PUBLIC_API_BASE } from '$env/static/public';

export class ApiLoader {
    private readonly _fetch: typeof globalThis.fetch;

    constructor(fetch: typeof globalThis.fetch) {
        this._fetch = fetch
    }

    async fetch(path: string, init?: RequestInit): Promise<Response> {
        return await this._fetch(`${PUBLIC_API_BASE}${path}`, init);
    }

    async getJson<T>(path: string): Promise<T> {
        const response = await this.fetch(path);
        if (response.ok) return await response.json();
        else throw error(response.status, await response.text());
    }

    async sendJson(path: string, method: string, bodyObject?: unknown): Promise<Response> {
        const body = JSON.stringify(bodyObject);
        return await this.fetch(path, {
            method,
            headers: {
                "Accept": "application/json",
                ...(bodyObject !== undefined && { "Content-Type": "application/json" }),
            },
            body
        });
    }
}
