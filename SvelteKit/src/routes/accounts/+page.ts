import type { PageLoad } from './$types';
import type { Account } from '$lib';

export const load: PageLoad = async ({ fetch }) => {
    const response = await fetch("http://localhost:5046/accounts");
    const data: Account[] = await response.json();
    return { accounts: data };
}
