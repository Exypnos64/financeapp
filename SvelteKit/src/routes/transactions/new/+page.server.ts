import type { Actions, PageServerLoad } from './$types';
import type { Account, Category, Merchant } from '$lib';
import { fail, redirect } from '@sveltejs/kit';
const API_BASE = "http://localhost:5046";

export const load: PageServerLoad = async ({ fetch }) => {
    const getJson = async <T>(url: string): Promise<T> => {
        const response = await fetch(url);
        if (response.ok) return await response.json();
        else throw new Error('bad response');
    };

    const [accounts, categories, merchants] = await Promise.all([
        getJson<Account[]>(`${API_BASE}/accounts`),
        getJson<Category[]>(`${API_BASE}/categories`),
        getJson<Merchant[]>(`${API_BASE}/merchants`),
    ]);

    return { accounts, categories, merchants };
}

export const actions = {
    default: async ({ request, fetch }) => {
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

        const response = await fetch(`${API_BASE}/transactions`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(transaction),
        });
        
        if (response.ok) {
            redirect(303, "/transactions")
        }
        else {
            return fail(response.status, {
                message: await response.text(),
                values: Object.fromEntries(form)
            });
        }
    }
} satisfies Actions;
