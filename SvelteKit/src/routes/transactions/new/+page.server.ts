import type { Actions, PageServerLoad } from './$types';
import type { Account, Category, Merchant } from '$lib';
import { ApiLoader } from '$lib';
import { fail, redirect } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ fetch }) => {
    const api = new ApiLoader(fetch);
    const [accounts, categories, merchants] = await Promise.all([
        api.getJson<Account[]>("/accounts"),
        api.getJson<Category[]>("/categories"),
        api.getJson<Merchant[]>("/merchants"),
    ]);

    return { accounts, categories, merchants };
}

export const actions = {
    default: async ({ request, fetch }) => {
        const form = await request.formData();
        const api = new ApiLoader(fetch);

        const userDate = form.get("userDate");
        if (!userDate) return fail(422, {
            message: "Please choose a date.",
            values: Object.fromEntries(form)
        });

        const cashBack = form.get("cashBack");
        const notes = form.get("notes");
        const transaction = {
            accountId: Number(form.get("accountId")),
            merchantId: Number(form.get("merchantId")),
            categoryId: Number(form.get("categoryId")),
            amount: Number(form.get("amount")),
            cashBack: cashBack ? Number(cashBack) : null,
            userDate: userDate,
            notes: notes || null
        };

        const response = await api.sendJson("/transactions", "POST", transaction);
        
        if (response.ok) {
            redirect(303, "/transactions");
        }
        else {
            return fail(response.status, {
                message: await response.text(),
                values: Object.fromEntries(form)
            });
        }
    }
} satisfies Actions;
