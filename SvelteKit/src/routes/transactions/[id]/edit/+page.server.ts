import type { Actions, PageServerLoad } from './$types';
import type { Account, Category, Merchant, TransactionDto } from '$lib';
import { fail, redirect } from '@sveltejs/kit';
const API_BASE = "http://localhost:5046";

export const load: PageServerLoad = async({ fetch, params }) => {
    const getJson = async <T>(url: string): Promise<T> => {
        const response = await fetch(url);
        if (response.ok) return await response.json();
        else throw new Error('bad response');
    };

    const [accounts, categories, merchants, transaction] = await Promise.all([
            getJson<Account[]>(`${API_BASE}/accounts`),
            getJson<Category[]>(`${API_BASE}/categories`),
            getJson<Merchant[]>(`${API_BASE}/merchants`),
            getJson<TransactionDto>(`${API_BASE}/transactions/${params.id}`),
        ]);

    return { accounts, categories, merchants, transaction };
}

export const actions = {
    update: async ({ request, fetch, params }) => {
        const form = await request.formData();

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

        const response = await fetch(`${API_BASE}/transactions/${params.id}`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(transaction),
        });

        if (response.ok) {
            redirect(303, "/transactions");
        }
        else {
            return fail(response.status, {
                message: await response.text(),
                values: Object.fromEntries(form)
            });
        }
    },
    delete: async ({ request, fetch, params }) => {
        const response = await fetch(`${API_BASE}/transactions/${params.id}`, {
            method: "DELETE",
            headers: { "Accept": "application/json" },
        });

        if (response.ok) {
            redirect(303, "/transactions");
        }
        else {
            return fail(response.status, {
                message: await response.text(),
                values: Object.fromEntries(await request.formData())
            });
        }
    }
} satisfies Actions;