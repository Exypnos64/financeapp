import type { PageLoad } from './$types';
import type { Account } from '$lib';
const API_BASE = "http://localhost:5046";

export const load: PageLoad = async ({ fetch }) => {
    const response = await fetch(`${API_BASE}/accounts`);
    const data: Account[] = await response.json();
    return { accounts: data };
}
