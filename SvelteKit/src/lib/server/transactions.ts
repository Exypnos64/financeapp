import { fail, redirect, type ActionFailure } from '@sveltejs/kit';
import type { TransactionFormFailure, TransactionValidation } from '../types';

export function validateTransaction(form: FormData): TransactionValidation {
	const userDate = form.get('userDate');
	if (!userDate || typeof userDate !== 'string')
		return {
			ok: false,
			failure: fail(422, {
				message: 'Please choose a date.',
				values: Object.fromEntries(form)
			})
		};

	const cashBack = form.get('cashBack');
	const notes = form.get('notes');
	return {
		ok: true,
		body: {
			accountId: Number(form.get('accountId')),
			merchantId: Number(form.get('merchantId')),
			categoryId: Number(form.get('categoryId')),
			amount: Number(form.get('amount')),
			cashBack: cashBack && typeof cashBack === 'string' ? Number(cashBack) : null,
			userDate: userDate,
			notes: notes && typeof notes === 'string' ? notes : null
		}
	};
}

export async function handleTransactionResponse(
	response: Response,
	form?: FormData
): Promise<ActionFailure<TransactionFormFailure> | undefined> {
	if (response.ok) {
		redirect(303, '/transactions');
	} else {
		return fail(response.status, {
			message: await response.text(),
			...(form !== undefined && { values: Object.fromEntries(form) })
		});
	}
}
