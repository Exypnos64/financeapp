import type { PageLoad } from './$types';
import type { Transaction } from '$lib';
import { ApiLoader } from '$lib';

export const load: PageLoad = async ({ fetch }) => {
    const api = new ApiLoader(fetch);
    const data = await api.getJson<Transaction[]>("/transactions");
    return { transactions: data };
}
