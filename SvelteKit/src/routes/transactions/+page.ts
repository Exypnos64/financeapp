import type { PageLoad } from './$types';
import type { Transaction } from '$lib';

export const load: PageLoad = async ({ fetch }) => {
    const response = await fetch("http://localhost:5046/transactions");
    const data: Transaction[] = await response.json();
    return { transactions: data };
}
