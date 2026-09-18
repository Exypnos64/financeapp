import type { PageLoad } from './$types';
import type { Account } from '$lib';
import { PUBLIC_API_BASE } from '$env/static/public';

export const load: PageLoad = async ({ fetch }) => {
    const response = await fetch(`${PUBLIC_API_BASE}/accounts`);
    const data: Account[] = await response.json();
    return { accounts: data };
}
