import type { Actions, PageServerLoad } from './$types';
import type { Account, Category, Merchant, TransactionDto } from '$lib';
import { ApiLoader } from '$lib';
import { handleTransactionResponse, validateTransaction } from '$lib/server/transactions';

export const load: PageServerLoad = async ({ fetch, params }) => {
	const api = new ApiLoader(fetch);
	const [accounts, categories, merchants, transaction] = await Promise.all([
		api.getJson<Account[]>('/accounts'),
		api.getJson<Category[]>('/categories'),
		api.getJson<Merchant[]>('/merchants'),
		api.getJson<TransactionDto>(`/transactions/${params.id}`)
	]);

	return { accounts, categories, merchants, transaction };
};

export const actions = {
	update: async ({ request, fetch, params }) => {
		const form = await request.formData();
		const validation = validateTransaction(form);

		if (!validation.ok) return validation.failure;

		const api = new ApiLoader(fetch);
		const response = await api.sendJson(`/transactions/${params.id}`, 'PUT', validation.body);

		const handled = await handleTransactionResponse(response, form);
		if (handled) return handled;
	},
	delete: async ({ fetch, params }) => {
		const api = new ApiLoader(fetch);
		const response = await api.sendJson(`/transactions/${params.id}`, 'DELETE');

		const handled = await handleTransactionResponse(response);
		if (handled) return handled;
	}
} satisfies Actions;
