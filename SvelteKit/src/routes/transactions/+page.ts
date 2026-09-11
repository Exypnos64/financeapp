import type { PageLoad } from './$types';
import type { Transaction } from '$lib';
const API_BASE = "http://localhost:5046";

export const load: PageLoad = async ({ fetch }) => {
    const response = await fetch(`${API_BASE}/transactions`);
    const data: Transaction[] = await response.json();
    return { transactions: data };
}
