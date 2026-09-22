import type { PageLoad } from './$types';
import type { Account } from '$lib';
import { ApiLoader } from '$lib';

export const load: PageLoad = async ({ fetch }) => {
	const api = new ApiLoader(fetch);
	const data = await api.getJson<Account[]>('/accounts');
	return { accounts: data };
};
