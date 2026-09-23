import type { Actions, PageServerLoad } from './$types';
import type { Account, Category, Merchant } from '$lib';
import { ApiLoader } from '$lib';
import { handleTransactionResponse, validateTransaction } from '$lib/server/transactions';

export const load: PageServerLoad = async ({ fetch }) => {
	const api = new ApiLoader(fetch);
	const [accounts, categories, merchants] = await Promise.all([
		api.getJson<Account[]>('/accounts'),
		api.getJson<Category[]>('/categories'),
		api.getJson<Merchant[]>('/merchants')
	]);
	const uuid = crypto.randomUUID();

	return { accounts, categories, merchants, uuid };
};

export const actions = {
	default: async ({ request, fetch }) => {
		const form = await request.formData();
		const validation = validateTransaction(form);

		if (!validation.ok) return validation.failure;
		const api = new ApiLoader(fetch);
		const response = await api.sendJson('/transactions', 'POST', validation.body);

		const handled = await handleTransactionResponse(response, form);
		if (handled) return handled;
	}
} satisfies Actions;
