import type { PageLoad } from './$types';
import type { Transaction } from '$lib';
import { PUBLIC_API_BASE } from '$env/static/public';

export const load: PageLoad = async ({ fetch }) => {
    const response = await fetch(`${PUBLIC_API_BASE}/transactions`);
    const data: Transaction[] = await response.json();
    return { transactions: data };
}
